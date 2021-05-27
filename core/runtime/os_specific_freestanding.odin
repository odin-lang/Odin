//+build freestanding
package runtime

// TODO(bill): reimplement `os.write`
_os_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	return 0, -1;
}

_current_thread_id :: proc "contextless" () -> int {
	return 0;
}
