#+build !amd64
#+build !arm64
#+build !arm32
package sha2

// is_hardware_accelerated_256 returns true if and only if (⟺) hardware
// accelerated SHA-224/SHA-256 is supported.
is_hardware_accelerated_256 :: proc "contextless" () -> bool {
	return false
}

@(private)
sha256_transf_hw :: proc "contextless" (ctx: ^Context_256, data: []byte) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}
