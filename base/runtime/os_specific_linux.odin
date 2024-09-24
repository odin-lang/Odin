#+private
package runtime

import "base:intrinsics"

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	when ODIN_ARCH == .amd64 {
		SYS_write :: uintptr(1)
	} else when ODIN_ARCH == .arm64 {
		SYS_write :: uintptr(64)
	} else when ODIN_ARCH == .i386 {
		SYS_write :: uintptr(4)
	} else when ODIN_ARCH == .arm32 {
		SYS_write :: uintptr(4)
	} else when ODIN_ARCH == .riscv64 {
		SYS_write :: uintptr(64)
	}

	stderr :: 2

	ret := int(intrinsics.syscall(SYS_write, uintptr(stderr), uintptr(raw_data(data)), uintptr(len(data))))
	if ret < 0 && ret > -4096 {
		return 0, _OS_Errno(-ret)
	}
	return ret, 0
}
