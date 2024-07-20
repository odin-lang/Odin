/*
package hmac implements the HMAC MAC algorithm.

See:
- https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.198-1.pdf
*/
package hmac

import "core:crypto"
import "core:crypto/hash"
import "core:mem"

// sum will compute the HMAC with the specified algorithm and key
// over msg, and write the computed tag to dst.  It requires that
// the dst buffer is the tag size.
sum :: proc(algorithm: hash.Algorithm, dst, msg, key: []byte) {
	ctx: Context

	init(&ctx, algorithm, key)
	update(&ctx, msg)
	final(&ctx, dst)
}

// verify will verify the HMAC tag computed with the specified algorithm
// and key over msg and return true iff the tag is valid.  It requires
// that the tag is correctly sized.
verify :: proc(algorithm: hash.Algorithm, tag, msg, key: []byte) -> bool {
	tag_buf: [hash.MAX_DIGEST_SIZE]byte

	derived_tag := tag_buf[:hash.DIGEST_SIZES[algorithm]]
	sum(algorithm, derived_tag, msg, key)

	return crypto.compare_constant_time(derived_tag, tag) == 1
}

// Context is a concrete instantiation of HMAC with a specific hash
// algorithm.
Context :: struct {
	_o_hash:         hash.Context, // H(k ^ ipad) (not finalized)
	_i_hash:         hash.Context, // H(k ^ opad) (not finalized)
	_tag_sz:         int,
	_is_initialized: bool,
}

// init initializes a Context with a specific hash Algorithm and key.
init :: proc(ctx: ^Context, algorithm: hash.Algorithm, key: []byte) {
	if ctx._is_initialized {
		reset(ctx)
	}

	_init_hashes(ctx, algorithm, key)

	ctx._tag_sz = hash.DIGEST_SIZES[algorithm]
	ctx._is_initialized = true
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	assert(ctx._is_initialized)

	hash.update(&ctx._i_hash, data)
}

// final finalizes the Context, writes the tag to dst, and calls
// reset on the Context.
final :: proc(ctx: ^Context, dst: []byte) {
	assert(ctx._is_initialized)

	defer (reset(ctx))

	if len(dst) != ctx._tag_sz {
		panic("crypto/hmac: invalid destination tag size")
	}

	hash.final(&ctx._i_hash, dst) // H((k ^ ipad) || text)

	hash.update(&ctx._o_hash, dst) // H((k ^ opad) || H((k ^ ipad) || text))
	hash.final(&ctx._o_hash, dst)
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	if ctx == other {
		return
	}

	hash.clone(&ctx._o_hash, &other._o_hash)
	hash.clone(&ctx._i_hash, &other._i_hash)
	ctx._tag_sz = other._tag_sz
	ctx._is_initialized = other._is_initialized
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	if !ctx._is_initialized {
		return
	}

	hash.reset(&ctx._o_hash)
	hash.reset(&ctx._i_hash)
	ctx._tag_sz = 0
	ctx._is_initialized = false
}

// algorithm returns the Algorithm used by a Context instance.
algorithm :: proc(ctx: ^Context) -> hash.Algorithm {
	assert(ctx._is_initialized)

	return hash.algorithm(&ctx._i_hash)
}

// tag_size returns the tag size of a Context instance in bytes.
tag_size :: proc(ctx: ^Context) -> int {
	assert(ctx._is_initialized)

	return ctx._tag_sz
}

@(private)
_I_PAD :: 0x36
_O_PAD :: 0x5c

@(private)
_init_hashes :: proc(ctx: ^Context, algorithm: hash.Algorithm, key: []byte) {
	K0_buf: [hash.MAX_BLOCK_SIZE]byte
	kPad_buf: [hash.MAX_BLOCK_SIZE]byte

	kLen := len(key)
	B := hash.BLOCK_SIZES[algorithm]
	K0 := K0_buf[:B]
	defer mem.zero_explicit(raw_data(K0), B)

	switch {
	case kLen == B, kLen < B:
		// If the length of K = B: set K0 = K.
		//
		// If the length of K < B: append zeros to the end of K to
		// create a B-byte string K0 (e.g., if K is 20 bytes in
		// length and B = 64, then K will be appended with 44 zero
		// bytes x’00’).
		//
		// K0 is zero-initialized, so the copy handles both cases.
		copy(K0, key)
	case kLen > B:
		// If the length of K > B: hash K to obtain an L byte string,
		// then append (B-L) zeros to create a B-byte string K0
		// (i.e., K0 = H(K) || 00...00).
		tmpCtx := &ctx._o_hash // Saves allocating a hash.Context.
		hash.init(tmpCtx, algorithm)
		hash.update(tmpCtx, key)
		hash.final(tmpCtx, K0)
	}

	// Initialize the hashes, and write the padded keys:
	// - ctx._i_hash -> H(K0 ^ ipad)
	// - ctx._o_hash -> H(K0 ^ opad)

	hash.init(&ctx._o_hash, algorithm)
	hash.init(&ctx._i_hash, algorithm)

	kPad := kPad_buf[:B]
	defer mem.zero_explicit(raw_data(kPad), B)

	for v, i in K0 {
		kPad[i] = v ~ _I_PAD
	}
	hash.update(&ctx._i_hash, kPad)

	for v, i in K0 {
		kPad[i] = v ~ _O_PAD
	}
	hash.update(&ctx._o_hash, kPad)
}
