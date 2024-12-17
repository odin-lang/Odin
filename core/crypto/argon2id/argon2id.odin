/*
package argon2id implements the argon2id password hashing algorithm.

See: [[ https://datatracker.ietf.org/doc/rfc9106/ ]]
*/
package argon2

import "core:crypto/blake2b"
import "core:encoding/endian"
import "core:mem"

// MAX_INPUT_SIZE is the mamximum size of the various inputs (password,
// salt, secret, ad) in bytes.
MAX_INPUT_SIZE :: (1 << 32) -1

// MIN_PARALLELISM is the minimum allowed parallelism.
MIN_PARALLELISM :: 1
// MAX_PARALLELISM is the maximum allowed parallelism.
MAX_PARALLELISM :: (1 << 24) - 1

// MIN_TAG_SIZE is the minimum digest size in bytes.
MIN_TAG_SIZE :: 4
// MAX_TAG_SIZE is the maximum digest size in bytes.
MAX_TAG_SIZE :: (1 << 32) -1

// RECOMMENDED_TAG_SIZE is the recommended tag size in bytes.
RECOMMENTED_TAG_SIZE :: 32 // 256-bits
// RECOMMENDNED_SALT_SIZE is the recommended salt size in bytes.
RECOMMENDED_SALT_SIZE :: 16 // 128-bits

@(private)
V_RFC9106 :: 0x13
@(private)
Y_ID :: 0x02
@(private)
BLOCK_SIZE :: 1024

// PARAMS_RFC9106 is the first recommended "uniformly safe" parameter set
// per RFC 9106.
@(rodata)
PARAMS_RFC9106 := Parameters{
	memory_size = 2 * 1024 *1024, // 2 GiB
	passes      = 1,
	parallelism = 4,
}

// PARAMS_RFC9106_SMALL is the second recommended "uniformly safe" parameter
// set per RFC 9106 tailored for memory constrained environments.
@(rodata)
PARAMS_RFC9106_SMALL := Parameters{
	memory_size = 64 * 1024, // 64 MiB
	passes      = 3,
	parallelism = 4,
}

// PARAMS_OWASP is the recommended parameter set from the OWASP Password
// Storage Cheat Sheet (as of 2024/11).  The cheat sheet contains
// additional variations to this parameter set with various trade-offs
// between `memory_size` and `passes` that are intended to provide
// equivalent security.
//
// See: [[ https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html ]]
@(rodata)
PARAMS_OWASP := Parameters{
	memory_size = 19 * 1024, // 19 MiB
	passes      = 2,
	parallelism = 1,
}

// Parameters is an argon2id parameter set.
Parameters :: struct {
	memory_size: u32,  // m (KiB)
	passes:      u32,  // t
	parallelism: int,  // p
}

// derive invokes argon2id with the specified parameter set and inputs,
// and outputs the derived key to dst.
@(require_results)
derive :: proc(
	parameters: ^Parameters,
	password:   []byte, // P
	salt:       []byte, // S
	dst:        []byte,
	secret:     []byte = nil, // K (aka `pepper`)
	ad:         []byte = nil, // X
	sanitize  := true,
	allocator := context.allocator, // Not temp as this can be large.
) -> mem.Allocator_Error #no_bounds_check {
	if u64(len(password)) > MAX_INPUT_SIZE {
		panic("argon2id: invalid password size")
	}
	if u64(len(salt)) > MAX_INPUT_SIZE {
		panic("argon2id: invalid salt size")
	}
	if u64(len(secret)) > MAX_INPUT_SIZE {
		panic("argon2id: invalid secret size")
	}
	if u64(len(ad)) > MAX_INPUT_SIZE {
		panic("argon2id: invalid ad size")
	}
	if l := u64(len(dst)); l > MAX_TAG_SIZE || l < MIN_TAG_SIZE {
		panic("argon2id: invalid dst size")
	}

	p, t, m := parameters.parallelism, parameters.passes, u64(parameters.memory_size)
	if p < MIN_PARALLELISM || p > MAX_PARALLELISM {
		panic("argon2id: invalid parallelism")
	}
	if t < 1 {
		panic("argon2id: invalid passes")
	}
	if m < 8 * u64(p) {
		panic("argon2id: insufficient memory size")
	}
	if m * BLOCK_SIZE > u64(max(int)) {
		panic("argon2id: excessive memory size")
	}

	// Allocate the memory as m' 1024-byte blocks, where m' is derived as:
	// m' = 4 * p * floor (m / 4p)
	//
	// For p lanes, the memory is organized in a matrix B[i][j] of
	// blocks with p rows (lanes) and q = m' / p columns.
	m_ := 4 * p * (int(m) / (4 * p))
	b := mem.alloc_bytes_non_zeroed(
		m_ * BLOCK_SIZE,
		alignment = mem.DEFAULT_PAGE_SIZE,
		allocator = allocator,
	) or_return
	defer delete(b, allocator)

	q := m_ / p
	bytes_per_col := q * BLOCK_SIZE

	// Establish H_0 as the 64-byte value as shown below.  If K, X, or S
	// has zero length, it is just absent, but its length field remains.
	//
	// H_0 = H^(64)(LE32(p) || LE32(T) || LE32(m) || LE32(t) ||
	//     LE32(v) || LE32(y) || LE32(length(P)) || P ||
	//     LE32(length(S)) || S ||  LE32(length(K)) || K ||
	//     LE32(length(X)) || X)
	h_0: [blake2b.DIGEST_SIZE+8]byte
	{
		ctx: blake2b.Context
		blake2b.init(&ctx)

		blake2b_update_u32le(&ctx, u32(p))
		blake2b_update_u32le(&ctx, u32(len(dst)))
		blake2b_update_u32le(&ctx, parameters.memory_size)
		blake2b_update_u32le(&ctx, t)
		blake2b_update_u32le(&ctx, V_RFC9106)
		blake2b_update_u32le(&ctx, Y_ID)
		blake2b_update_u32le(&ctx, u32(len(password)))
		blake2b.update(&ctx, password)
		blake2b_update_u32le(&ctx, u32(len(salt)))
		blake2b.update(&ctx, salt)
		blake2b_update_u32le(&ctx, u32(len(secret)))
		blake2b.update(&ctx, secret)
		blake2b_update_u32le(&ctx, u32(len(ad)))
		blake2b.update(&ctx, ad)

		blake2b.final(&ctx, h_0[:blake2b.DIGEST_SIZE])
	}

	// The RFC separates out these into two distinct steps, but this
	// can be done in a single loop.
	//
	// Compute B[i][0] for all i ranging from (and including) 0 to (not
	// including) p.
	//
	// B[i][0] = H'^(1024)(H_0 || LE32(0) || LE32(i))
	//
	// Compute B[i][1] for all i ranging from (and including) 0 to (not
	// including) p.
	//
	// B[i][1] = H'^(1024)(H_0 || LE32(1) || LE32(i))
	for i in 0 ..< p {
		endian.unchecked_put_u32le(h_0[blake2b.DIGEST_SIZE+4:], u32(i)) // LE32(i)

		b_ := b[i*bytes_per_col:] // B[i][0]
		endian.unchecked_put_u32le(h_0[blake2b.DIGEST_SIZE:], u32(0)) // LE32(0)
		h_prime(b_[:BLOCK_SIZE], h_0[:])

		b_ = b_[BLOCK_SIZE:] // B[i][1]
		endian.unchecked_put_u32le(h_0[blake2b.DIGEST_SIZE:], u32(1)) // LE32(1)
		h_prime(b_[:BLOCK_SIZE], h_0[:])
	}

	mem.zero_explicit(&h_0, size_of(h_0)) // No longer needed.

	// Compute B[i][j] for all i ranging from (and including) 0 to (not
	// including) p and for all j ranging from (and including) 2 to (not
	// including) q.  The computation MUST proceed slicewise
	// (Section 3.4): first, blocks from slice 0 are computed for all
	// lanes (in an arbitrary order of lanes), then blocks from slice 1
	// are computed, etc.  The block indices l and z are determined for
	// each i, j differently for Argon2d, Argon2i, and Argon2id.
	//
	// B[i][j] = G(B[i][j-1], B[l][z])
	//
	// If the number of passes t is larger than 1, we repeat step 5.  We
	// compute B[i][0] and B[i][j] for all i raging from (and including)
	// 0 to (not including) p and for all j ranging from (and including)
	// 1 to (not including) q.  However, blocks are computed differently
	// as the old value is XORed with the new one:
	//
	// B[i][0] = G(B[i][q-1], B[l][z]) XOR B[i][0];
	// B[i][j] = G(B[i][j-1], B[l][z]) XOR B[i][j].

	// After t steps have been iterated, the final block C is computed
	// as the XOR of the last column:
	//
	// C = B[0][q-1] XOR B[1][q-1] XOR ... XOR B[p-1][q-1]
	blk := b[bytes_per_col - BLOCK_SIZE:]
	for _ in 1 ..< q {
		src := b[bytes_per_col:]
		for j in 0 ..< BLOCK_SIZE { // XXX/perf: Can do this faster.
			blk[j] ~= src[j]
		}
	}

	// The output tag is computed as H'^T(C).
	h_prime(dst, blk)

	// Sanitize the working memory.  While the RFC implies that this is
	// optional ("enable the memory-wiping option in the library call"),
	// the reference code defaults to enabling it.
	//
	// An opt-out is provided, as this can get somewhat expensive when
	// m gets large.
	if sanitize {
		mem.zero_explicit(raw_data(b), len(b))
	}

	return nil
}

@(private)
blake2b_update_u32le :: #force_inline proc(ctx: ^blake2b.Context, i: u32) {
	tmp: [4]byte = ---
	endian.unchecked_put_u32le(tmp[:], i)
	blake2b.update(ctx, tmp[:])
}

/*
3.3.  Variable-Length Hash Function H'

   Let V_i be a 64-byte block and W_i be its first 32 bytes.  Then we
   define function H' as follows:

           if T <= 64
               H'^T(A) = H^T(LE32(T)||A)
           else
               r = ceil(T/32)-2
               V_1 = H^(64)(LE32(T)||A)
               V_2 = H^(64)(V_1)
               ...
               V_r = H^(64)(V_{r-1})
               V_{r+1} = H^(T-32*r)(V_{r})
               H'^T(X) = W_1 || W_2 || ... || W_r || V_{r+1}

        Figure 8: Function H' for Tag and Initial Block Computations
*/

@(private)
h_prime :: proc(dst, src: []byte) {
	// T = len(dst), A = src

	t := len(dst)
	ctx: blake2b.Context

	// Let V_i be a 64-byte block and W_i be its first 32 bytes.  Then we
	// define function H' as follows:
	switch {
	case t < blake2b.DIGEST_SIZE:
		blake2b.init(&ctx, t)
	case:
		blake2b.init(&ctx)
	}

	// This covers both:
	// T <= 64: H'^T(A) = H^T(LE32(T)||A)
	// T > 64:  V_1 = H^(64)(LE32(T)||A)
	blake2b_update_u32le(&ctx, u32(t))
	blake2b.update(&ctx, src)

	// if T <= 64
	if t <= blake2b.DIGEST_SIZE {
		// H'^T(A) = H^T(LE32(T)||A)
		blake2b.final(&ctx, dst)
		return
	}

	tmp: [blake2b.DIGEST_SIZE]byte = ---
	defer mem.zero_explicit(&tmp, size_of(tmp))
	blake2b.final(&ctx, tmp[:])

	copy(dst, tmp[:32]) // W_1
	d := dst[32:]
	for len(d) >= 32 {
		// V_n = H^(64)(V_{n-1})
		blake2b.init(&ctx)
		blake2b.update(&ctx, tmp[:])
		blake2b.final(&ctx, tmp[:])

		copy(d, tmp[:32]) // W_n
		d = d[32:]
	}

	if tail_len := len(d); tail_len > 0 {
		// r = ceil(T/32)-2
		// V_{r+1} = H^(T-32*r)(V_{r})
		blake2b.init(&ctx, tail_len)
		blake2b.update(&ctx, tmp[:])
		blake2b.final(&ctx, tmp[:])

		copy(d, tmp[:tail_len]) // V_{r+1}
	}
}

@(private)
b_i_j :: #force_inline proc "contextless" (b: []byte, i, j, q, p: int) -> []byte {
	// B[i][j]
	// p columns (i), q rows (j)
	bytes_per_col := q * BLOCK_SIZE
	col_offset := i * (bytes_per_col)
	row_offset := p * BLOCK_SIZE
	return b[col_offset + row_offset:]
}

/*
3.4.  Indexing

   To enable parallel block computation, we further partition the memory
   matrix into SL = 4 vertical slices.  The intersection of a slice and
   a lane is called a segment, which has a length of q/SL.  Segments of
   the same slice can be computed in parallel and do not reference
   blocks from each other.  All other blocks can be referenced.

       slice 0    slice 1    slice 2    slice 3
       ___/\___   ___/\___   ___/\___   ___/\___
      /        \ /        \ /        \ /        \
     +----------+----------+----------+----------+
     |          |          |          |          | > lane 0
     +----------+----------+----------+----------+
     |          |          |          |          | > lane 1
     +----------+----------+----------+----------+
     |          |          |          |          | > lane 2
     +----------+----------+----------+----------+
     |         ...        ...        ...         | ...
     +----------+----------+----------+----------+
     |          |          |          |          | > lane p - 1
     +----------+----------+----------+----------+

           Figure 9: Single-Pass Argon2 with p Lanes and 4 Slices

3.4.1.  Computing the 32-Bit Values J_1 and J_2

3.4.1.1.  Argon2d

   J_1 is given by the first 32 bits of block B[i][j-1], while J_2 is
   given by the next 32 bits of block B[i][j-1]:

   J_1 = int32(extract(B[i][j-1], 0))
   J_2 = int32(extract(B[i][j-1], 1))

                    Figure 10: Deriving J1,J2 in Argon2d

3.4.1.2.  Argon2i

   For each segment, we do the following.  First, we compute the value Z
   as:

   Z= ( LE64(r) || LE64(l) || LE64(sl) || LE64(m') ||
        LE64(t) || LE64(y) )

                Figure 11: Input to Compute J1,J2 in Argon2i

   where

   r:   the pass number
   l:   the lane number
   sl:  the slice number
   m':  the total number of memory blocks
   t:   the total number of passes
   y:   the Argon2 type (0 for Argon2d, 1 for Argon2i, 2 for Argon2id)

   Then we compute:

   q/(128*SL) 1024-byte values
   G(ZERO(1024),G(ZERO(1024),
   Z || LE64(1) || ZERO(968) )),
   G(ZERO(1024),G(ZERO(1024),
   Z || LE64(2) || ZERO(968) )),... ,
   G(ZERO(1024),G(ZERO(1024),
   Z || LE64(q/(128*SL)) || ZERO(968) )),

   which are partitioned into q/(SL) 8-byte values X, which are viewed
   as X1||X2 and converted to J_1=int32(X1) and J_2=int32(X2).

   The values r, l, sl, m', t, y, and i are represented as 8 bytes in
   little endian.

3.4.1.3.  Argon2id

   If the pass number is 0 and the slice number is 0 or 1, then compute
   J_1 and J_2 as for Argon2i, else compute J_1 and J_2 as for Argon2d.

3.4.2.  Mapping J_1 and J_2 to Reference Block Index [l][z]

   The value of l = J_2 mod p gives the index of the lane from which the
   block will be taken.  For the first pass (r=0) and the first slice
   (sl=0), the block is taken from the current lane.

   The set W contains the indices that are referenced according to the
   following rules:

   1.  If l is the current lane, then W includes the indices of all
       blocks in the last SL - 1 = 3 segments computed and finished, as
       well as the blocks computed in the current segment in the current
       pass excluding B[i][j-1].

   2.  If l is not the current lane, then W includes the indices of all
       blocks in the last SL - 1 = 3 segments computed and finished in
       lane l.  If B[i][j] is the first block of a segment, then the
       very last index from W is excluded.

   Then take a block from W with a nonuniform distribution over [0, |W|)
   using the following mapping:

   J_1 -> |W|(1 - J_1^2 / 2^(64))

                          Figure 12: Computing J1

   To avoid floating point computation, the following approximation is
   used:

   x = J_1^2 / 2^(32)
   y = (|W| * x) / 2^(32)
   zz = |W| - 1 - y

                      Figure 13: Computing J1, Part 2

   Then take the zz-th index from W; it will be the z value for the
   reference block index [l][z].

*/

/*
3.5.  Compression Function G

   The compression function G is built upon the BLAKE2b-based
   transformation P.  P operates on the 128-byte input, which can be
   viewed as eight 16-byte registers:

   P(A_0, A_1, ... ,A_7) = (B_0, B_1, ... ,B_7)

                     Figure 14: Blake Round Function P

   The compression function G(X, Y) operates on two 1024-byte blocks X
   and Y.  It first computes R = X XOR Y.  Then R is viewed as an 8x8
   matrix of 16-byte registers R_0, R_1, ... , R_63.  Then P is first
   applied to each row, and then to each column to get Z:

   ( Q_0,  Q_1,  Q_2, ... ,  Q_7) <- P( R_0,  R_1,  R_2, ... ,  R_7)
   ( Q_8,  Q_9, Q_10, ... , Q_15) <- P( R_8,  R_9, R_10, ... , R_15)
                                 ...
   (Q_56, Q_57, Q_58, ... , Q_63) <- P(R_56, R_57, R_58, ... , R_63)
   ( Z_0,  Z_8, Z_16, ... , Z_56) <- P( Q_0,  Q_8, Q_16, ... , Q_56)
   ( Z_1,  Z_9, Z_17, ... , Z_57) <- P( Q_1,  Q_9, Q_17, ... , Q_57)
                                 ...
   ( Z_7, Z_15, Z 23, ... , Z_63) <- P( Q_7, Q_15, Q_23, ... , Q_63)

                 Figure 15: Core of Compression Function G

   Finally, G outputs Z XOR R:

   G: (X, Y) -> R -> Q -> Z -> Z XOR R

                            +---+       +---+
                            | X |       | Y |
                            +---+       +---+
                              |           |
                              ---->XOR<----
                            --------|
                            |      \ /
                            |     +---+
                            |     | R |
                            |     +---+
                            |       |
                            |      \ /
                            |   P rowwise
                            |       |
                            |      \ /
                            |     +---+
                            |     | Q |
                            |     +---+
                            |       |
                            |      \ /
                            |  P columnwise
                            |       |
                            |      \ /
                            |     +---+
                            |     | Z |
                            |     +---+
                            |       |
                            |      \ /
                            ------>XOR
                                    |
                                   \ /

                  Figure 16: Argon2 Compression Function G

3.6.  Permutation P

   Permutation P is based on the round function of BLAKE2b.  The eight
   16-byte inputs S_0, S_1, ... , S_7 are viewed as a 4x4 matrix of
   64-bit words, where S_i = (v_{2*i+1} || v_{2*i}):

            v_0  v_1  v_2  v_3
            v_4  v_5  v_6  v_7
            v_8  v_9 v_10 v_11
           v_12 v_13 v_14 v_15

                     Figure 17: Matrix Element Labeling

   It works as follows:

           GB(v_0, v_4,  v_8, v_12)
           GB(v_1, v_5,  v_9, v_13)
           GB(v_2, v_6, v_10, v_14)
           GB(v_3, v_7, v_11, v_15)

           GB(v_0, v_5, v_10, v_15)
           GB(v_1, v_6, v_11, v_12)
           GB(v_2, v_7,  v_8, v_13)
           GB(v_3, v_4,  v_9, v_14)

                  Figure 18: Feeding Matrix Elements to GB

   GB(a, b, c, d) is defined as follows:

           a = (a + b + 2 * trunc(a) * trunc(b)) mod 2^(64)
           d = (d XOR a) >>> 32
           c = (c + d + 2 * trunc(c) * trunc(d)) mod 2^(64)
           b = (b XOR c) >>> 24

           a = (a + b + 2 * trunc(a) * trunc(b)) mod 2^(64)
           d = (d XOR a) >>> 16
           c = (c + d + 2 * trunc(c) * trunc(d)) mod 2^(64)
           b = (b XOR c) >>> 63

                          Figure 19: Details of GB

   The modular additions in GB are combined with 64-bit multiplications.
   Multiplications are the only difference from the original BLAKE2b
   design.  This choice is done to increase the circuit depth and thus
   the running time of ASIC implementations, while having roughly the
   same running time on CPUs thanks to parallelism and pipelining.
*/

