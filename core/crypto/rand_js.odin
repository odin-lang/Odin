package crypto

foreign import "odin_env"
foreign odin_env {
	@(link_name = "rand_bytes")
	env_rand_bytes :: proc "contextless" (buf: []byte) ---
}

HAS_RAND_BYTES :: true

@(private)
_MAX_PER_CALL_BYTES :: 65536 // 64kiB

@(private)
_rand_bytes :: proc(dst: []byte) {
	dst := dst

	for len(dst) > 0 {
		to_read := min(len(dst), _MAX_PER_CALL_BYTES)
		env_rand_bytes(dst[:to_read])

		dst = dst[to_read:]
	}
}
