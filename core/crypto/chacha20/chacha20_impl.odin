package chacha20

import "base:intrinsics"
import "core:crypto/_chacha20/ref"
import "core:crypto/_chacha20/simd128"
import "core:crypto/_chacha20/simd256"

// DEFAULT_IMPLEMENTATION is the implementation that will be used by
// default if possible.
DEFAULT_IMPLEMENTATION :: Implementation.Simd256

// Implementation is a ChaCha20 implementation.  Most callers will not need
// to use this as the package will automatically select the most performant
// implementation available.
Implementation :: enum {
	Portable,
	Simd128,
	Simd256,
}

@(private)
init_impl :: proc(ctx: ^Context, impl: Implementation) {
	impl := impl
	if impl == .Simd256 && !simd256.is_performant() {
			impl = .Simd128
	}
	if impl == .Simd128 && !simd128.is_performant() {
		impl = .Portable
	}

	ctx._impl = impl
}

@(private)
stream_blocks :: proc(ctx: ^Context, dst, src: []byte, nr_blocks: int) {
	// The implementations increment the counter as a 64-bit value.
	// With the IETF flavor, the counter is 32 bits, and the increment
	// after the final block carries into the first word of the IV.
	iv_0 := ctx._state._s[13]

	switch ctx._impl {
	case .Simd256:
		simd256.stream_blocks(&ctx._state, dst, src, nr_blocks)
	case .Simd128:
		simd128.stream_blocks(&ctx._state, dst, src, nr_blocks)
	case .Portable:
		ref.stream_blocks(&ctx._state, dst, src, nr_blocks)
	}

	if ctx._state._is_ietf_flavor {
		ctx._state._s[13] = iv_0
	}
}

@(private)
hchacha20 :: proc "contextless" (dst, key, iv: []byte, impl: Implementation) {
	switch impl {
	case .Simd256:
		simd256.hchacha20(dst, key, iv)
	case .Simd128:
		simd128.hchacha20(dst, key, iv)
	case .Portable:
		ref.hchacha20(dst, key, iv)
	}
}
