package runtime

_OS_Errno :: distinct int

stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	return _stderr_write(data)
}
