//+build darwin
//+private
package runtime

import "base:intrinsics"

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	STDERR :: 2
	when ODIN_NO_CRT {
		WRITE  :: 0x2000004
		ret := intrinsics.syscall(WRITE, STDERR, uintptr(raw_data(data)), uintptr(len(data)))
		if ret < 0 {
			return 0, _OS_Errno(-ret)
		}
		return int(ret), 0
	} else {
		foreign {
			write   :: proc(handle: i32, buffer: [^]byte, count: uint) -> int ---
			__error :: proc() -> ^i32 ---
		}

		if ret := write(STDERR, raw_data(data), len(data)); ret >= 0 {
			return int(ret), 0
		}

		return 0, _OS_Errno(__error()^)
	}
}
