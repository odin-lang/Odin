/*
package argon2id implements the Argon2id password hashing algorithm.

See: [[ https://datatracker.ietf.org/doc/rfc9106/ ]]
*/
package argon2id

import "core:crypto/blake2b"
import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

// Implementation based on the RFC, Monocypher (CC0-1.0), and the reference
// code (CC0-1.0).

// MAX_INPUT_SIZE is the mamximum size of the various inputs (password,
// salt, secret, ad) in bytes.
MAX_INPUT_SIZE :: (1 << 32) - 1

// MIN_PARALLELISM is the minimum allowed parallelism.
MIN_PARALLELISM :: 1
// MAX_PARALLELISM is the maximum allowed parallelism.
MAX_PARALLELISM :: (1 << 24) - 1

// MIN_TAG_SIZE is the minimum digest size in bytes.
MIN_TAG_SIZE :: 4
// MAX_TAG_SIZE is the maximum digest size in bytes.
MAX_TAG_SIZE :: (1 << 32) - 1

// RECOMMENDED_TAG_SIZE is the recommended tag size in bytes.
RECOMMENTED_TAG_SIZE :: 32 // 256-bits
// RECOMMENDNED_SALT_SIZE is the recommended salt size in bytes.
RECOMMENDED_SALT_SIZE :: 16 // 128-bits

@(private)
V_RFC9106 :: 0x13
@(private)
Y_ID :: 0x02
@(private)
BLOCK_SIZE_BYTES :: 1024
@(private)
BLOCK_SIZE_U64 :: 128

// PARAMS_RFC9106 is the first recommended "uniformly safe" parameter set
// per RFC 9106.
@(rodata)
PARAMS_RFC9106 := Parameters{
	memory_size = 2 * 1024 * 1024, // 2 GiB
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

// PARAMS_OWASP is one of the recommended parameter set from the OWASP
// Password Storage Cheat Sheet (as of 2026/02).  The cheat sheet contains
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

// PARAMS_OWASP_SMALL is equivalent in strength to PARAMS_OWASP, but
// trades off less memory use for more CPU usage.
@(rodata)
PARAMS_OWASP_SMALL := Parameters{
	memory_size = 7 * 1024, // 7 MiB
	passes      = 5,
	parallelism = 1,
}

// Parameters is an Argon2id parameter set.
Parameters :: struct {
	memory_size: u32,  // m (KiB)
	passes:      u32,  // t
	parallelism: u32,  // p
}

@(private)
Block :: [BLOCK_SIZE_U64]u64

// derive invokes Argon2id with the specified parameter set and inputs,
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
		panic("crypto/argon2id: invalid password size")
	}
	if u64(len(salt)) > MAX_INPUT_SIZE {
		panic("crypto/argon2id: invalid salt size")
	}
	if u64(len(secret)) > MAX_INPUT_SIZE {
		panic("crypto/argon2id: invalid secret size")
	}
	if u64(len(ad)) > MAX_INPUT_SIZE {
		panic("crypto/argon2id: invalid ad size")
	}
	if l := u64(len(dst)); l > MAX_TAG_SIZE || l < MIN_TAG_SIZE {
		panic("crypto/argon2id: invalid dst size")
	}

	p, t, m := parameters.parallelism, parameters.passes, u64(parameters.memory_size)
	if p < MIN_PARALLELISM || p > MAX_PARALLELISM {
		panic("crypto/argon2id: invalid parallelism")
	}
	if t < 1 {
		panic("crypto/argon2id: invalid passes")
	}
	if m < 8 * u64(p) {
		panic("crypto/argon2id: insufficient memory size")
	}
	if m * BLOCK_SIZE_BYTES > u64(max(int)) {
		panic("crypto/argon2id: excessive memory size")
	}

	// Allocate the memory as m' 1024-byte blocks, where m' is derived as:
	// m' = 4 * p * floor (m / 4p)
	//
	// For p lanes, the memory is organized in a matrix B[i][j] of
	// blocks with p rows (lanes) and q = m' / p columns.
	m_ := 4 * u64(p) * (m / u64(4 * p))
	b := mem.alloc_bytes_non_zeroed(
		int(m_) * BLOCK_SIZE_BYTES,
		alignment = mem.PAGE_SIZE,
		allocator = allocator,
	) or_return
	defer delete(b, allocator)

	block_buf: [BLOCK_SIZE_BYTES]byte = ---

	blocks := ([^]Block)(raw_data(b))[:m_]
	segment_size := u32(m_ / u64(p) / 4)
	lane_size := segment_size * 4

	// Establish H_0 as the 64-byte value as shown below.  If K, X, or S
	// has zero length, it is just absent, but its length field remains.
	//
	// H_0 = H^(64)(LE32(p) || LE32(T) || LE32(m) || LE32(t) ||
	//     LE32(v) || LE32(y) || LE32(length(P)) || P ||
	//     LE32(length(S)) || S ||  LE32(length(K)) || K ||
	//     LE32(length(X)) || X)
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

		h_0: [blake2b.DIGEST_SIZE+8]byte
		blake2b.final(&ctx, h_0[:blake2b.DIGEST_SIZE])

		// Compute B[i][0] for all i ranging from (and including) 0 to (not
		// including) p.
		//
		// B[i][0] = H'^(1024)(H_0 || LE32(0) || LE32(i))
		//
		// Compute B[i][1] for all i ranging from (and including) 0 to (not
		// including) p.
		//
		// B[i][1] = H'^(1024)(H_0 || LE32(1) || LE32(i))
		for l in u32(0) ..< p {
			for i in u32(0) ..< 2 {
				endian.unchecked_put_u32le(h_0[blake2b.DIGEST_SIZE:], i)   // LE32({0,1})
				endian.unchecked_put_u32le(h_0[blake2b.DIGEST_SIZE+4:], l) // LE32(i)
				h_prime(block_buf[:], h_0[:])
				blk := &blocks[l * lane_size + i]
				for j in 0 ..< BLOCK_SIZE_U64 {
					blk[j] = endian.unchecked_get_u64le(block_buf[j*8:])
				}
			}
		}

		mem.zero_explicit(&h_0, size_of(h_0)) // No longer needed.
	}

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
	constant_time := true // Start with constant time indexing.
	tmp, index_block: Block = ---, ---
	for pass in u32(0) ..< t {
		for slice in u32(0) ..< 4 {
			// The first slice of the first pass has blocks 0 and 1
			// pre-filled.
			pass_offset: u32 = pass == 0 && slice == 0 ? 2 : 0
			slice_offset := slice * segment_size

			// 3.4.1.3.  Argon2id
			//
			//    If the pass number is 0 and the slice number is 0 or 1, then compute
			//    J_1 and J_2 as for Argon2i, else compute J_1 and J_2 as for Argon2d.
			if slice == 2 {
				constant_time = false
			}

			// Each segment can be processed in parallel, as long as
			// each iteration of the loop completes before proceeding
			// to the next.  For simplicity we do this in serial
			// instead of using threads.
			for segment in u32(0) ..< u32(p) {
				index_ctr: u64 = 1
				for block in pass_offset ..< segment_size {
					// Current and previous blocks (indexes, not pointers)
					lane_offset := segment * lane_size
					segment_start := lane_offset + slice_offset
					current := segment_start + block
					previous := segment_start - 1
					switch {
					case block == 0 && slice_offset == 0:
						previous += lane_size
					case:
						previous += block
					}

					index_seed: u64
					if constant_time {
						// 3.4.1.2.  Argon2i
						//
						//    For each segment, we do the following.  First, we compute the value Z
						//    as:
						//
						//    Z= ( LE64(r) || LE64(l) || LE64(sl) || LE64(m') ||
						//         LE64(t) || LE64(y) )
						//
						//                 Figure 11: Input to Compute J1,J2 in Argon2i
						//
						//    where
						//
						//    r:   the pass number
						//    l:   the lane number
						//    sl:  the slice number
						//    m':  the total number of memory blocks
						//    t:   the total number of passes
						//    y:   the Argon2 type (0 for Argon2d, 1 for Argon2i, 2 for Argon2id)
						//
						//    Then we compute:
						//
						//    q/(128*SL) 1024-byte values
						//    G(ZERO(1024),G(ZERO(1024),
						//    Z || LE64(1) || ZERO(968) )),
						//    G(ZERO(1024),G(ZERO(1024),
						//    Z || LE64(2) || ZERO(968) )),... ,
						//    G(ZERO(1024),G(ZERO(1024),
						//    Z || LE64(q/(128*SL)) || ZERO(968) )),
						//
						//    which are partitioned into q/(SL) 8-byte values X, which are viewed
						//    as X1||X2 and converted to J_1=int32(X1) and J_2=int32(X2).
						//
						//    The values r, l, sl, m', t, y, and i are represented as 8 bytes in
						//    little endian.
						if block == pass_offset || (block % 128) == 0 {
							mem.zero(&index_block, size_of(index_block))
							index_block[0] = u64(pass)
							index_block[1] = u64(segment)
							index_block[2] = u64(slice)
							index_block[3] = u64(lane_size * p)
							index_block[4] = u64(t) // passes
							index_block[5] = Y_ID
							index_block[6] = index_ctr
							index_ctr += 1

							copy(tmp[:], index_block[:])
							g_rounds(&index_block)
							xor_block(&index_block, &tmp)
							copy(tmp[:], index_block[:])
							g_rounds(&index_block)
							xor_block(&index_block, &tmp)
						}
						index_seed = index_block[block % 128]
					} else {
						// 3.4.1.1.  Argon2d
						//
						//    J_1 is given by the first 32 bits of block B[i][j-1], while J_2 is
						//    given by the next 32 bits of block B[i][j-1]:
						//
						//    J_1 = int32(extract(B[i][j-1], 0))
						//    J_2 = int32(extract(B[i][j-1], 1))
						//
						//                   Figure 10: Deriving J1,J2 in Argon2d
						index_seed = blocks[previous][0]
					}

					// 3.4.2.  Mapping J_1 and J_2 to Reference Block Index [l][z]
					//
					//    The value of l = J_2 mod p gives the index of the lane from which the
					//    block will be taken.  For the first pass (r=0) and the first slice
					//    (sl=0), the block is taken from the current lane.
					//
					//    The set W contains the indices that are referenced according to the
					//    following rules:
					//
					//    1.  If l is the current lane, then W includes the indices of all
					//        blocks in the last SL - 1 = 3 segments computed and finished, as
					//        well as the blocks computed in the current segment in the current
					//        pass excluding B[i][j-1].
					//
					//    2.  If l is not the current lane, then W includes the indices of all
					//        blocks in the last SL - 1 = 3 segments computed and finished in
					//        lane l.  If B[i][j] is the first block of a segment, then the
					//        very last index from W is excluded.
					//
					//    Then take a block from W with a nonuniform distribution over [0, |W|)
					//    using the following mapping:
					//
					//    J_1 -> |W|(1 - J_1^2 / 2^(64))
					//
					//                           Figure 12: Computing J1
					//
					//    To avoid floating point computation, the following approximation is
					//    used:
					//
					//    x = J_1^2 / 2^(32)
					//    y = (|W| * x) / 2^(32)
					//    zz = |W| - 1 - y
					//
					//                       Figure 13: Computing J1, Part 2
					//
					//    Then take the zz-th index from W; it will be the z value for the
					//    reference block index [l][z].
					next_slice: u32 = ((slice + 1) % 4) * segment_size
					window_start, nb_segments: u32
					lane := u32(index_seed >> 32) % p
					switch {
					case pass == 0:
						nb_segments = slice
						if slice == 0 {
							lane = segment
						}
					case:
						window_start = next_slice
						nb_segments = 3
					}
					window_size := nb_segments * segment_size
					if lane == segment {
						window_size += block - 1
					} else if block == 0 {
						window_size += ~u32(0)
					}

					j1 := index_seed & 0xffffffff
					x := (j1 * j1) >> 32
					y := (u64(window_size) * x) >> 32
					z := (u64(window_size) - 1) - y
					ref := u32((u64(window_start) + z) % u64(lane_size))
					reference: u32 = lane * lane_size + ref

					copy(tmp[:], blocks[previous][:])
					xor_block(&tmp, &blocks[reference])
					if pass == 0 {
						copy(blocks[current][:], tmp[:])
					} else {
						xor_block(&blocks[current], &tmp)
					}
					g_rounds(&tmp)
					xor_block(&blocks[current], &tmp)
				}
			}
		}
	}
	mem.zero_explicit(&tmp, size_of(tmp))
	mem.zero_explicit(&index_block, size_of(index_block))

	// After t steps have been iterated, the final block C is computed
	// as the XOR of the last column:
	//
	// C = B[0][q-1] XOR B[1][q-1] XOR ... XOR B[p-1][q-1]
	idx := lane_size - 1
	last_block := &blocks[idx]
	for _ in 1 ..< p {
		idx += lane_size
		next_block := &blocks[idx]
		xor_block(next_block, last_block)
		last_block = next_block
	}

	for v, i in last_block {
		endian.unchecked_put_u64le(block_buf[i*8:], v)
	}

	// The output tag is computed as H'^T(C).
	h_prime(dst, block_buf[:])
	mem.zero_explicit(&block_buf, size_of(block_buf))

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
xor_block :: #force_inline proc(dst, src: ^Block) {
	for v, i in src {
		dst[i] ~= v
	}
}

@(private)
blake2b_update_u32le :: #force_inline proc(ctx: ^blake2b.Context, i: u32) {
	tmp: [4]byte = ---
	endian.unchecked_put_u32le(tmp[:], i)
	blake2b.update(ctx, tmp[:])
	mem.zero_explicit(&tmp, size_of(tmp)) // Probably overkill.
}

// 3.3.  Variable-Length Hash Function H'
//
//    Let V_i be a 64-byte block and W_i be its first 32 bytes.  Then we
//    define function H' as follows:
//
//            if T <= 64
//                H'^T(A) = H^T(LE32(T)||A)
//            else
//                r = ceil(T/32)-2
//                V_1 = H^(64)(LE32(T)||A)
//                V_2 = H^(64)(V_1)
//                ...
//                V_r = H^(64)(V_{r-1})
//                V_{r+1} = H^(T-32*r)(V_{r})
//                H'^T(X) = W_1 || W_2 || ... || W_r || V_{r+1}
//
//         Figure 8: Function H' for Tag and Initial Block Computations
@(private)
h_prime :: proc(dst, src: []byte) {
	t := len(dst)
	ctx: blake2b.Context
	blake2b.init(&ctx, min(t, blake2b.DIGEST_SIZE))
	blake2b_update_u32le(&ctx, u32(t))
	blake2b.update(&ctx, src)
	blake2b.final(&ctx, dst)

	if t > 64 {
		r := u32((u64(t) + 31) >> 5) - 2
		i: u32 = 1
		off_in := 0
		off_out := 32
		for i < r {
			blake2b.init(&ctx, blake2b.DIGEST_SIZE)
			blake2b.update(&ctx, dst[off_in:off_in+64])
			blake2b.final(&ctx, dst[off_out:])
			i += 1
			off_in += 32
			off_out += 32
		}
		blake2b.init(&ctx, t - int(32 * r))
		blake2b.update(&ctx, dst[off_in:off_in+64])
		blake2b.final(&ctx, dst[off_out:])
	}
}

// GB(a, b, c, d) is defined as follows:
//
//         a = (a + b + 2 * trunc(a) * trunc(b)) mod 2^(64)
//         d = (d XOR a) >>> 32
//         c = (c + d + 2 * trunc(c) * trunc(d)) mod 2^(64)
//         b = (b XOR c) >>> 24
//
//         a = (a + b + 2 * trunc(a) * trunc(b)) mod 2^(64)
//         d = (d XOR a) >>> 16
//         c = (c + d + 2 * trunc(c) * trunc(d)) mod 2^(64)
//         b = (b XOR c) >>> 63
//
//                        Figure 19: Details of GB
//
// The modular additions in GB are combined with 64-bit multiplications.
// Multiplications are the only difference from the original BLAKE2b
// design.  This choice is done to increase the circuit depth and thus
// the running time of ASIC implementations, while having roughly the
// same running time on CPUs thanks to parallelism and pipelining.
@(private,require_results)
gb :: #force_inline proc(a, b, c, d: u64) -> (u64, u64, u64, u64) {
	a, b, c, d := a, b, c, d

	trunc := #force_inline proc(v: u64) -> u64 {
		return u64(u32(v))
	}

	a += b + ((trunc(a) * trunc(b)) << 1)
	d = bits.rotate_left64(d ~ a, 32) // >>> 32
	c += d + ((trunc(c) * trunc(d)) << 1)
	b = bits.rotate_left64((b ~ c), 40) // >>> 24

	a += b + ((trunc(a) * trunc(b)) << 1)
	d = bits.rotate_left64(d ~ a, 48) // >>> 16
	c += d + ((trunc(c) * trunc(d)) << 1)
	b = bits.rotate_left64((b ~ c), 1) // >>> 63

	return a, b, c, d
}

// 3.6.  Permutation P
//
//    Permutation P is based on the round function of BLAKE2b.  The eight
//    16-byte inputs S_0, S_1, ... , S_7 are viewed as a 4x4 matrix of
//    64-bit words, where S_i = (v_{2*i+1} || v_{2*i}):
//
//             v_0  v_1  v_2  v_3
//             v_4  v_5  v_6  v_7
//             v_8  v_9 v_10 v_11
//            v_12 v_13 v_14 v_15
//
//                      Figure 17: Matrix Element Labeling
//
//    It works as follows:
//
//            GB(v_0, v_4,  v_8, v_12)
//            GB(v_1, v_5,  v_9, v_13)
//            GB(v_2, v_6, v_10, v_14)
//            GB(v_3, v_7, v_11, v_15)
//
//            GB(v_0, v_5, v_10, v_15)
//            GB(v_1, v_6, v_11, v_12)
//            GB(v_2, v_7,  v_8, v_13)
//            GB(v_3, v_4,  v_9, v_14)
//
//                   Figure 18: Feeding Matrix Elements to GB
@(private,require_results)
perm_p :: #force_inline proc(v_0, v_1, v_2, v_3, v_4, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14, v_15: u64) -> (u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64) {
	v_0, v_1, v_2, v_3, v_4, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14, v_15 := v_0, v_1, v_2, v_3, v_4, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14, v_15

	v_0, v_4, v_8, v_12 = gb(v_0, v_4, v_8, v_12)
	v_1, v_5, v_9, v_13 = gb(v_1, v_5, v_9, v_13)
	v_2, v_6, v_10, v_14 = gb(v_2, v_6, v_10, v_14)
	v_3, v_7, v_11, v_15 = gb(v_3, v_7, v_11, v_15)

	v_0, v_5, v_10, v_15 = gb(v_0, v_5, v_10, v_15)
	v_1, v_6, v_11, v_12 = gb(v_1, v_6, v_11, v_12)
	v_2, v_7, v_8, v_13 = gb(v_2, v_7, v_8, v_13)
	v_3, v_4, v_9, v_14 = gb(v_3, v_4, v_9, v_14)

	return v_0, v_1, v_2, v_3, v_4, v_5, v_6, v_7, v_8, v_9, v_10, v_11, v_12, v_13, v_14, v_15
}

// 3.5.  Compression Function G
//
//    The compression function G is built upon the BLAKE2b-based
//    transformation P.  P operates on the 128-byte input, which can be
//    viewed as eight 16-byte registers:
//
//    P(A_0, A_1, ... ,A_7) = (B_0, B_1, ... ,B_7)
//
//                      Figure 14: Blake Round Function P
//
//    The compression function G(X, Y) operates on two 1024-byte blocks X
//    and Y.  It first computes R = X XOR Y.  Then R is viewed as an 8x8
//    matrix of 16-byte registers R_0, R_1, ... , R_63.  Then P is first
//    applied to each row, and then to each column to get Z:
//
//    ( Q_0,  Q_1,  Q_2, ... ,  Q_7) <- P( R_0,  R_1,  R_2, ... ,  R_7)
//    ( Q_8,  Q_9, Q_10, ... , Q_15) <- P( R_8,  R_9, R_10, ... , R_15)
//                                  ...
//    (Q_56, Q_57, Q_58, ... , Q_63) <- P(R_56, R_57, R_58, ... , R_63)
//    ( Z_0,  Z_8, Z_16, ... , Z_56) <- P( Q_0,  Q_8, Q_16, ... , Q_56)
//    ( Z_1,  Z_9, Z_17, ... , Z_57) <- P( Q_1,  Q_9, Q_17, ... , Q_57)
//                                  ...
//    ( Z_7, Z_15, Z 23, ... , Z_63) <- P( Q_7, Q_15, Q_23, ... , Q_63)
//
//                  Figure 15: Core of Compression Function G
@(private)
g_rounds :: proc(b: ^Block) {
	for i := 0; i < 128; i += 16 {
		b[i], b[i+1], b[i+2], b[i+3], b[i+4], b[i+5], b[i+6], b[i+7], b[i+8], b[i+9], b[i+10], b[i+11], b[i+12], b[i+13], b[i+14], b[i+15] = perm_p(b[i], b[i+1], b[i+2], b[i+3], b[i+4], b[i+5], b[i+6], b[i+7], b[i+8], b[i+9], b[i+10], b[i+11], b[i+12], b[i+13], b[i+14], b[i+15])
	}
	for i := 0; i < 16; i += 2 {
		b[i], b[i+1], b[i+16], b[i+17], b[i+32], b[i+33], b[i+48], b[i+49], b[i+64], b[i+65], b[i+80], b[i+81], b[i+96], b[i+97], b[i+112], b[i+113] = perm_p(b[i], b[i+1], b[i+16], b[i+17], b[i+32], b[i+33], b[i+48], b[i+49], b[i+64], b[i+65], b[i+80], b[i+81], b[i+96], b[i+97], b[i+112], b[i+113])
	}
}
