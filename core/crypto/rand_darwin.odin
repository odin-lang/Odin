package crypto

import "core:c"

foreign import libc "system:c"
foreign libc {
	arc4random_buf :: proc "c" (buf: rawptr, nbytes: c.size_t) ---
}

_rand_bytes :: proc (dst: []byte) {
	arc4random_buf(raw_data(dst), len(dst))
}
