/*
package kmac implements the KMAC MAC algorithm.

See:
- https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-185.pdf
*/
package kmac

import "../_sha3"
import "core:crypto"
import "core:crypto/shake"

// MIN_KEY_SIZE_128 is the minimum key size for KMAC128 in bytes.
MIN_KEY_SIZE_128 :: 128 / 8
// MIN_KEY_SIZE_256 is the minimum key size for KMAC256 in bytes.
MIN_KEY_SIZE_256 :: 256 / 8

// MIN_TAG_SIZE is the absolute minimum tag size for KMAC in bytes (8.4.2).
// Most callers SHOULD use at least 128-bits if not 256-bits for the tag
// size.
MIN_TAG_SIZE :: 32 / 8

// sum will compute the KMAC with the specified security strength,
// key, and domain separator over msg, and write the computed digest to
// dst.
sum :: proc(sec_strength: int, dst, msg, key, domain_sep: []byte) {
	ctx: Context

	_init_kmac(&ctx, key, domain_sep, sec_strength)
	update(&ctx, msg)
	final(&ctx, dst)
}

// verify will verify the KMAC tag computed with the specified security
// strength, key and domain separator over msg and return true iff the
// tag is valid.
verify :: proc(sec_strength: int, tag, msg, key, domain_sep: []byte, allocator := context.temp_allocator) -> bool {
	derived_tag := make([]byte, len(tag), allocator)

	sum(sec_strength, derived_tag, msg, key, domain_sep)

	return crypto.compare_constant_time(derived_tag, tag) == 1
}

// Context is a KMAC instance.
Context :: distinct shake.Context

// init_128 initializes a Context for KMAC28.  This routine will panic if
// the key length is less than MIN_KEY_SIZE_128.
init_128 :: proc(ctx: ^Context, key, domain_sep: []byte) {
	_init_kmac(ctx, key, domain_sep, 128)
}

// init_256 initializes a Context for KMAC256.  This routine will panic if
// the key length is less than MIN_KEY_SIZE_256.
init_256 :: proc(ctx: ^Context, key, domain_sep: []byte) {
	_init_kmac(ctx, key, domain_sep, 256)
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	assert(ctx.is_initialized)

	shake.write((^shake.Context)(ctx), data)
}

// final finalizes the Context, writes the tag to dst, and calls reset
// on the Context.  This routine will panic if the dst length is less than
// MIN_TAG_SIZE.
final :: proc(ctx: ^Context, dst: []byte) {
	assert(ctx.is_initialized)
	defer reset(ctx)

	if len(dst) < MIN_TAG_SIZE {
		panic("crypto/kmac: invalid KMAC tag_size, too short")
	}

	_sha3.final_cshake((^_sha3.Context)(ctx), dst)
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	if ctx == other {
		return
	}

	shake.clone((^shake.Context)(ctx), (^shake.Context)(other))
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	if !ctx.is_initialized {
		return
	}

	shake.reset((^shake.Context)(ctx))
}

@(private)
_init_kmac :: proc(ctx: ^Context, key, s: []byte, sec_strength: int) {
	if ctx.is_initialized {
		reset(ctx)
	}

	if len(key) < sec_strength / 8 {
		panic("crypto/kmac: invalid KMAC key, too short")
	}

	ctx_ := (^_sha3.Context)(ctx)
	_sha3.init_cshake(ctx_, N_KMAC, s, sec_strength)
	_sha3.bytepad(ctx_, [][]byte{key}, _sha3.rate_cshake(sec_strength))
}

@(private)
N_KMAC := []byte{'K', 'M', 'A', 'C'}
