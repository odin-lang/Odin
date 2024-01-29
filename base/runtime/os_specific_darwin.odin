//+build darwin
//+private
package runtime

foreign import libc "system:System.framework"

@(default_calling_convention="c")
foreign libc {
	@(link_name="__stderrp")
	_stderr: rawptr

	@(link_name="fwrite")
	_fwrite :: proc(ptr: rawptr, size: uint, nmemb: uint, stream: rawptr) -> uint ---

	@(link_name="__error")
	_get_errno :: proc() -> ^i32 ---
}

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	ret := _fwrite(raw_data(data), 1, len(data), _stderr)
	if ret < len(data) {
		err := _get_errno()
		return int(ret), _OS_Errno(err^ if err != nil else 0)
	}
	return int(ret), 0
}
