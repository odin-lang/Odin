#+build freestanding
#+private
package runtime

// TODO(bill): reimplement `os.write`
_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	return 0, -1
}

_exit :: proc "contextless" (code: int) -> ! {
	trap()
}