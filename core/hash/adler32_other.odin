#+build !amd64
#+build !arm64
package hash

@(private)
ADLER32_SIMD :: false

@(private)
ADLER32_SIMD_MIN :: 0

@(private)
adler32_simd_available :: #force_inline proc "contextless" () -> bool {
	return false
}

@(private)
adler32_simd :: proc "contextless" (a, b: u64, data: []byte) -> (new_a, new_b: u64, consumed: int) {
	return a, b, 0
}
