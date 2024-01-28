//+build freebsd, openbsd
//+private
package runtime

foreign import libc "system:c"

foreign libc {
	@(link_name="write")
	_unix_write :: proc(fd: uintptr, buf: rawptr, size: int) -> int ---

	__error :: proc() -> ^i32 ---
}

_os_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	ret := _unix_write(2, raw_data(data), len(data))
	if ret < len(data) {
		err := __error()
		return int(ret), _OS_Errno(err^ if err != nil else 0)
	}
	return int(ret), 0
}
