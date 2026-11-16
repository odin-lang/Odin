#+build !amd64
#+build !arm64
#+build !arm32
package archive_zip

import "core:crypto/_aes/ct64"
import "core:crypto/aes"

@(private)
_ctr_xor :: proc(ctx: ^aes.Context_ECB, counter: ^u64, data: []u8) {
	ensure(ctx._is_initialized)
	_ctr_xor_ct64(&ctx._impl.(ct64.Context), counter, data)
}
