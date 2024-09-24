#+build !amd64
package aes

@(private = "file")
ERR_HW_NOT_SUPPORTED :: "crypto/aes: hardware implementation unsupported"

// is_hardware_accelerated returns true iff hardware accelerated AES
// is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return false
}

@(private)
Context_Impl_Hardware :: struct {}

@(private)
init_impl_hw :: proc(ctx: ^Context_Impl_Hardware, key: []byte) {
	panic(ERR_HW_NOT_SUPPORTED)
}

@(private)
encrypt_block_hw :: proc(ctx: ^Context_Impl_Hardware, dst, src: []byte) {
	panic(ERR_HW_NOT_SUPPORTED)
}

@(private)
decrypt_block_hw :: proc(ctx: ^Context_Impl_Hardware, dst, src: []byte) {
	panic(ERR_HW_NOT_SUPPORTED)
}

@(private)
ctr_blocks_hw :: proc(ctx: ^Context_CTR, dst, src: []byte, nr_blocks: int) {
	panic(ERR_HW_NOT_SUPPORTED)
}

@(private)
gcm_seal_hw :: proc(ctx: ^Context_Impl_Hardware, dst, tag, iv, aad, plaintext: []byte) {
	panic(ERR_HW_NOT_SUPPORTED)
}

@(private)
gcm_open_hw :: proc(ctx: ^Context_Impl_Hardware, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	panic(ERR_HW_NOT_SUPPORTED)
}
