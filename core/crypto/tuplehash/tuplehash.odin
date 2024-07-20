/*
package tuplehash implements the TupleHash and TupleHashXOF algorithms.

See:
- https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-185.pdf
*/
package tuplehash

import "../_sha3"

// Context is a TupleHash or TupleHashXOF instance.
Context :: distinct _sha3.Context

// init_128 initializes a Context for TupleHash128 or TupleHashXOF128.
init_128 :: proc(ctx: ^Context, domain_sep: []byte) {
	_sha3.init_cshake((^_sha3.Context)(ctx), N_TUPLEHASH, domain_sep, 128)
}

// init_256 initializes a Context for TupleHash256 or TupleHashXOF256.
init_256 :: proc(ctx: ^Context, domain_sep: []byte) {
	_sha3.init_cshake((^_sha3.Context)(ctx), N_TUPLEHASH, domain_sep, 256)
}

// write_element writes a tuple element into the TupleHash or TupleHashXOF
// instance.  This MUST not be called after any reads have been done, and
// any attempts to do so will panic.
write_element :: proc(ctx: ^Context, data: []byte) {
	_, _ = _sha3.encode_string((^_sha3.Context)(ctx), data)
}

// final finalizes the Context, writes the digest to hash, and calls
// reset on the Context.
//
// Iff finalize_clone is set, final will work on a copy of the Context,
// which is useful for for calculating rolling digests.
final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	_sha3.final_cshake((^_sha3.Context)(ctx), hash, finalize_clone)
}

// read reads output from the TupleHashXOF instance.  There is no practical
// upper limit to the amount of data that can be read from TupleHashXOF.
// After read has been called one or more times, further calls to
// write_element will panic.
read :: proc(ctx: ^Context, dst: []byte) {
	ctx_ := (^_sha3.Context)(ctx)
	if !ctx.is_finalized {
		_sha3.encode_byte_len(ctx_, 0, false) // right_encode
		_sha3.shake_xof(ctx_)
	}

	_sha3.shake_out(ctx_, dst)
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	_sha3.clone((^_sha3.Context)(ctx), (^_sha3.Context)(other))
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	_sha3.reset((^_sha3.Context)(ctx))
}

@(private)
N_TUPLEHASH := []byte{'T', 'u', 'p', 'l', 'e', 'H', 'a', 's', 'h'}
