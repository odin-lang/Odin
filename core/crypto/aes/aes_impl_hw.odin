#+build amd64,arm64,arm32
package aes

import aes_hw "core:crypto/_aes/hw"

// is_hardware_accelerated returns true if and only if (⟺) hardware accelerated AES
// is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return aes_hw.is_supported()
}

@(private)
Context_Impl_Hardware :: aes_hw.Context

@(private, enable_target_feature = aes_hw.TARGET_FEATURES)
init_impl_hw :: proc(ctx: ^Context_Impl_Hardware, key: []byte) {
	aes_hw.init(ctx, key)
}
