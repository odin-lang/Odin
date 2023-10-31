package rand

foreign import "odin_env"
foreign odin_env {
	@(link_name = "rand_bytes")
	env_rand_bytes :: proc "contextless" (buf: []byte) ---
}

@(require_results)
_system_random :: proc() -> u64 {
	buf: [8]u8
	env_rand_bytes(buf[:])
	return transmute(u64)buf
}
