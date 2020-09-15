//+build freestanding
package runtime

_OS_Errno  :: distinct int;
_OS_Handle :: distinct uintptr;

os_stdout :: proc "contextless" () -> _OS_Handle {
	return 1;
}
os_stderr :: proc "contextless" () -> _OS_Handle {
	return 2;
}

// TODO(bill): reimplement `os.write`
os_write :: proc(fd: _OS_Handle, data: []byte) -> (int, _OS_Errno) {
	return 0, -1;
}

current_thread_id :: proc "contextless" () -> int {
	return 0;
}
