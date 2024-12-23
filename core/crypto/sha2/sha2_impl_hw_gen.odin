#+build !amd64
package sha2

@(private = "file")
ERR_HW_NOT_SUPPORTED :: "crypto/sha2: hardware implementation unsupported"

// is_hardware_accelerated_256 returns true iff hardware accelerated
// SHA-224/SHA-256 is supported.
is_hardware_accelerated_256 :: proc "contextless" () -> bool {
	return false
}

sha256_transf_hw :: proc "contextless" (ctx: ^Context_256, data: []byte) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}
