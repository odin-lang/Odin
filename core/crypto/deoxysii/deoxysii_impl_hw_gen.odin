#+build !amd64
package deoxysii

@(private = "file")
ERR_HW_NOT_SUPPORTED :: "crypto/deoxysii: hardware implementation unsupported"

// is_hardware_accelerated returns true iff hardware accelerated Deoxys-II
// is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return false
}

@(private)
e_hw :: proc "contextless" (ctx: ^Context, dst, tag, iv, aad, plaintext: []byte) #no_bounds_check {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private, require_results)
d_hw :: proc "contextless" (ctx: ^Context, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}
