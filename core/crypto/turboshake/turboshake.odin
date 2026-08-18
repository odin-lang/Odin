/*
`TurboSHAKE` XOF algorithm family.

The SHA3 hash algorithm can be found in the crypto/sha3.

See:
- [[ https://www.rfc-editor.org/rfc/rfc9861 ]]
*/
package turboshake

import "../_sha3"

// Context is a TurboSHAKE128 or TurboSHAKE256 instance.
Context :: distinct _sha3.Context

// init_128 initializes a Context for TurboSHAKE128.
// Uses the default domain separation byte of 0x1f, unless one is supplied.
init_128 :: proc(ctx: ^Context, d: byte = _sha3.DS_TURBOSHAKE_DEFAULT) {
	_sha3.init_turboshake((^_sha3.Context)(ctx), d, 128)
}

// init_256 initializes a Context for TurboSHAKE256.
// Uses the default domain separation byte of 0x1f, unless one is supplied.
init_256 :: proc(ctx: ^Context, d: byte = _sha3.DS_TURBOSHAKE_DEFAULT) {
	_sha3.init_turboshake((^_sha3.Context)(ctx), d, 256)
}

// write writes more data into the TurboSHAKE instance. This MUST not be
// called after any reads have been done, and attempts to do so will panic.
write :: proc(ctx: ^Context, data: []byte) {
	_sha3.update((^_sha3.Context)(ctx), data)
}

// read reads output from the TurboSHAKE instance. There is no practical
// upper limit to the amount of data that can be read from TurboSHAKE.
// After read has been called one or more times, further calls to write
// will panic.
read :: proc(ctx: ^Context, dst: []byte) {
	ctx_ := (^_sha3.Context)(ctx)

	if !ctx.is_finalized {
		_sha3.shake_xof(ctx_)
	}

	_sha3.shake_out(ctx_, dst)
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	_sha3.clone((^_sha3.Context)(ctx), (^_sha3.Context)(other))
}

// reset sanitizes the Context. The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	_sha3.reset((^_sha3.Context)(ctx))
}