package aes_hw

@(require) import "core:sys/info"

// is_supported returns true if and only if (⟺) hardware accelerated AES
// is supported.
is_supported :: proc "contextless" () -> bool {
	when ODIN_ARCH == .amd64 {
		// Note: Everything with AES-NI has support for
		// the required SSE extxtensions.
		req_features :: info.CPU_Features{
			.sse2,
			.ssse3,
			.sse41,
			.aes,
		}
		return info.cpu_features() >= req_features
	} else when ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32 {
		req_features :: info.CPU_Features{
			.asimd,
			.aes,
		}
		return info.cpu_features() >= req_features
	} else {
		return false
	}
}

// is_ghash_supported returns true if and only if (⟺) hardware accelerated
// GHASH is supported.
is_ghash_supported :: proc "contextless" () -> bool {
	// Just having hardware GHASH is silly.
	if !is_supported() {
		return false
	}

	when ODIN_ARCH == .amd64 {
		return info.cpu_features() >= info.CPU_Features{
			.pclmulqdq,
		}
	} else when ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32{
		// Once we can actually use this, we can re-enable this.
		//
		// return info.cpu_features() >= info.CPU_Features{
		// 	.pmull,
		// }
		return false
	} else {
		return false
	}
}

// Context is a keyed AES (ECB) instance.
Context :: struct {
	// Note: The ideal thing to do is for the expanded round keys to be
	// arrays of `u8x16`, however that implies alignment (or using AVX).
	//
	// All the people using e-waste processors that don't support an
	// instruction set that has been around for over 10 years are why
	// we can't have nice things.
	_sk_exp_enc: [15][16]byte,
	_sk_exp_dec: [15][16]byte,
	_num_rounds: int,
}

// init initializes a context for AES with the provided key.
init :: proc(ctx: ^Context, key: []byte) {
	keysched(ctx, key)
}
