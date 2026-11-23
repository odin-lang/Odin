#+build !amd64
#+build !arm64
#+build !arm32
package sha1

// is_hardware_accelerated returns true if and only if (⟺) hardware
// accelerated SHA-1 is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return false
}

@(private)
sha1_transf_hw :: proc "contextless" (ctx: ^Context, data: []byte) {
	panic_contextless(ERR_HW_NOT_SUPPORTED)
}
