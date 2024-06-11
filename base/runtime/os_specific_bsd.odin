//+build freebsd, openbsd, netbsd
//+private
package runtime

foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	@(link_name="write")
	_unix_write :: proc(fd: i32, buf: rawptr, size: int) -> int ---

	when ODIN_OS == .NetBSD {
		@(link_name="__errno") __error :: proc() -> ^i32 ---
	} else {
		__error :: proc() -> ^i32 ---
	}
}

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	ret := _unix_write(2, raw_data(data), len(data))
	if ret < len(data) {
		err := __error()
		return int(ret), _OS_Errno(err^ if err != nil else 0)
	}
	return int(ret), 0
}
