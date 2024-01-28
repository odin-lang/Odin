//+build darwin
package runtime

import "core:intrinsics"

_os_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	ret := intrinsics.syscall(0x2000004, 1, uintptr(raw_data(data)), uintptr(len(data)))
	if ret < 0 {
		return 0, _OS_Errno(-ret)
	}
	return int(ret), 0
}
