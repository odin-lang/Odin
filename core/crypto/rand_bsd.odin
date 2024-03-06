//+build freebsd, openbsd
package crypto

foreign import libc "system:c"

foreign libc {
	arc4random_buf :: proc(buf: [^]byte, nbytes: uint) ---
}

_rand_bytes :: proc(dst: []byte) {
	arc4random_buf(raw_data(dst), len(dst))
}
