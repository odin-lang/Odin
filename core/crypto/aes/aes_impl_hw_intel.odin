//+build amd64
package aes

import "core:crypto/_aes/hw_intel"

// is_hardware_accelerated returns true iff hardware accelerated AES
// is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return hw_intel.is_supported()
}

@(private)
Context_Impl_Hardware :: hw_intel.Context

@(private, enable_target_feature = "sse2,aes")
init_impl_hw :: proc(ctx: ^Context_Impl_Hardware, key: []byte) {
	hw_intel.init(ctx, key)
}
