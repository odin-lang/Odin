package runtime

_OS_Errno :: distinct int

HAS_RAND_BYTES :: _HAS_RAND_BYTES

stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	return _stderr_write(data)
}

rand_bytes :: proc "contextless" (dst: []byte) {
	when HAS_RAND_BYTES {
		_rand_bytes(dst)
	} else {
		panic_contextless("base/runtime: no runtime entropy source")
	}
}

exit :: proc "contextless" (code: int) -> ! {
	_exit(code)
}