#+build darwin
#+private
package runtime

import "base:intrinsics"

_HAS_RAND_BYTES :: true

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

foreign import libc "system:System"

_rand_bytes :: proc "contextless" (dst: []byte) {
	// This process used to use Security/RandomCopyBytes, however
	// on every version of MacOS (>= 10.12) that we care about,
	// arc4random is implemented securely.

	@(default_calling_convention="c")
	foreign libc {
		arc4random_buf :: proc(buf: [^]byte, nbytes: uint) ---
	}
	arc4random_buf(raw_data(dst), len(dst))
}

_exit :: proc "contextless" (code: int) -> ! {
	@(default_calling_convention="c")
	foreign libc {
		exit :: proc(status: i32) -> ! ---
	}
	exit(i32(code))
}