#+build freebsd, openbsd, netbsd
package crypto

foreign import libc "system:c"

HAS_RAND_BYTES :: true

foreign libc {
	arc4random_buf :: proc(buf: [^]byte, nbytes: uint) ---
}

@(private)
_rand_bytes :: proc(dst: []byte) {
	arc4random_buf(raw_data(dst), len(dst))
}
