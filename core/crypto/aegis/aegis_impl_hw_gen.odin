#+build !amd64
package aegis

@(private = "file")
ERR_HW_NOT_SUPPORTED :: "crypto/aegis: hardware implementation unsupported"

@(private)
State_HW :: struct {}

// is_hardware_accelerated returns true iff hardware accelerated AEGIS
// is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return false
}

@(private)
init_hw :: proc "contextless" (ctx: ^Context, st: ^State_HW, iv: []byte) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
absorb_hw :: proc "contextless" (st: ^State_HW, aad: []byte) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
enc_hw :: proc "contextless" (st: ^State_HW, dst, src: []byte) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
dec_hw :: proc "contextless" (st: ^State_HW, dst, src: []byte) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
finalize_hw :: proc "contextless" (st: ^State_HW, tag: []byte, ad_len, msg_len: int) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}

@(private)
reset_state_hw :: proc "contextless" (st: ^State_HW) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}
