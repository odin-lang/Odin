//+build darwin
//+private
package runtime

import "base:intrinsics"

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	WRITE  :: 0x2000004
	STDERR :: 2
	ret := intrinsics.syscall(WRITE, STDERR, uintptr(raw_data(data)), uintptr(len(data)))
	if ret < 0 {
		return 0, _OS_Errno(-ret)
	}
	return int(ret), 0
}
