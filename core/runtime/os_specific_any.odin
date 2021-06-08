//+build !freestanding
//+build !windows
package runtime

import "core:os"

// TODO(bill): reimplement `os.write` so that it does not rely on package os
// NOTE: Use os_specific_linux.odin, os_specific_darwin.odin, etc
_os_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	context = default_context();
	n, err := os.write(os.stderr, data);
	return int(n), _OS_Errno(err);
}

_current_thread_id :: proc "contextless" () -> int {
	return os.current_thread_id();
}
