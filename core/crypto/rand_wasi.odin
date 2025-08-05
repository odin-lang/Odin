package crypto

import "core:fmt"
import "core:sys/wasm/wasi"

HAS_RAND_BYTES :: true

@(private)
_rand_bytes :: proc(dst: []byte) {
	if err := wasi.random_get(dst); err != nil {
		fmt.panicf("crypto: wasi.random_get failed: %v", err)
	}
}
