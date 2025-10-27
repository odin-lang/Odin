package crypto

import win32 "core:sys/windows"
import "core:fmt"

HAS_RAND_BYTES :: true

@(private)
_rand_bytes :: proc(dst: []byte) {
	// NOTE(Jeroen) We don't actually use anything `core:os`-specific here.
	// So let's just evaluate `win32`'s return values without first wrapping them.
	ret := win32.DWORD(win32.BCryptGenRandom(nil, raw_data(dst), u32(len(dst)), win32.BCRYPT_USE_SYSTEM_PREFERRED_RNG))
	if ret != win32.ERROR_SUCCESS {
		switch ret {
		case win32.ERROR_INVALID_HANDLE:
			// The handle to the first parameter is invalid.
			// This should not happen here, since we explicitly pass nil to it
			panic("crypto: BCryptGenRandom Invalid handle for hAlgorithm")
		case win32.ERROR_INVALID_PARAMETER:
			// One of the parameters was invalid
			panic("crypto: BCryptGenRandom Invalid parameter")
		case:
			// Unknown error
			fmt.panicf("crypto: BCryptGenRandom failed: %d\n", ret)
		}
	}
}
