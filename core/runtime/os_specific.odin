//+build !freestanding
package runtime

import "core:os"

_OS_Errno  :: distinct int;
_OS_Handle :: os.Handle;

os_stderr :: proc "contextless" () -> _OS_Handle {
	return os.stderr;
}

// TODO(bill): reimplement `os.write`
os_write :: proc(fd: _OS_Handle, data: []byte) -> (int, _OS_Errno) {
	n, err := os.write(fd, data);
	return int(n), _OS_Errno(err);
}

current_thread_id :: proc "contextless" () -> int {
	return os.current_thread_id();
}
