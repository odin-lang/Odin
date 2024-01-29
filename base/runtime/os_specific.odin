package runtime

_OS_Errno :: distinct int

os_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	return _os_write(data)
}
