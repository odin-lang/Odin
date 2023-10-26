package rand

foreign import "odin_env"
foreign odin_env {
	@(link_name = "rand")
	rand_f64 :: proc "contextless" () -> f64 ---
}

@(require_results)
_system_random :: proc() -> u64 {
	return u64(rand_f64() * 0x1fffffffffffff)
}
