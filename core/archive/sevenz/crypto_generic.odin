#+private
#+build !amd64
#+build !arm64
#+build !arm32
package archive_sevenz

import "core:crypto/_aes/ct64"
import "core:crypto/aes"

_cbc_decrypt :: proc(ctx: ^aes.Context_ECB, iv: ^[aes.BLOCK_SIZE]u8, data: []u8) {
	ensure(ctx._is_initialized)
	_cbc_decrypt_ct64(&ctx._impl.(ct64.Context), iv, data)
}

_cbc_encrypt :: proc(ctx: ^aes.Context_ECB, iv: ^[aes.BLOCK_SIZE]u8, dst, src: []u8) {
	ensure(ctx._is_initialized)
	_cbc_encrypt_ct64(&ctx._impl.(ct64.Context), iv, dst, src)
}
