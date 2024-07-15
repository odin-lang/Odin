//+build amd64
package aes_hw_intel

import "core:sys/info"

// is_supporte returns true iff hardware accelerated AES
// is supported.
is_supported :: proc "contextless" () -> bool {
	features, ok := info.cpu_features.?
	if !ok {
		return false
	}

	// Note: Everything with AES-NI and PCLMULQDQ has support for
	// the required SSE extxtensions.
	req_features :: info.CPU_Features{
		.sse2,
		.ssse3,
		.sse41,
		.aes,
		.pclmulqdq,
	}
	return features >= req_features
}

// Context is a keyed AES (ECB) instance.
Context :: struct {
	// Note: The ideal thing to do is for the expanded round keys to be
	// arrays of `__m128i`, however that implies alignment (or using AVX).
	//
	// All the people using e-waste processors that don't support an
	// insturction set that has been around for over 10 years are why
	// we can't have nice things.
	_sk_exp_enc: [15][16]byte,
	_sk_exp_dec: [15][16]byte,
	_num_rounds: int,
}

// init initializes a context for AES with the provided key.
init :: proc(ctx: ^Context, key: []byte) {
	keysched(ctx, key)
}

