package rand

foreign import "odin_env"
foreign odin_env {
	rand :: proc "contextless" () -> f64 ---
}

@(require_results)
_system_random :: proc() -> u64 {
	return u64(rand() * 0x1fffffffffffff)
}
