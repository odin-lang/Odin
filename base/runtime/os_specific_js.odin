#+build js
#+private
package runtime

foreign import "odin_env"

_HAS_RAND_BYTES :: true

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	foreign odin_env {
		write :: proc "contextless" (fd: u32, p: []byte) ---
	}
	write(1, data)
	return len(data), 0
}

_rand_bytes :: proc "contextless" (dst: []byte) {
	foreign odin_env {
		@(link_name = "rand_bytes")
		env_rand_bytes :: proc "contextless" (buf: []byte) ---
	}

	MAX_PER_CALL_BYTES :: 65536 // 64kiB

	dst := dst
	for len(dst) > 0 {
		to_read := min(len(dst), MAX_PER_CALL_BYTES)
		env_rand_bytes(dst[:to_read])

		dst = dst[to_read:]
	}
}

_exit :: proc "contextless" (code: int) -> ! {
	trap()
}