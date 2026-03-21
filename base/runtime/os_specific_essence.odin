#+build essence
#+private
package runtime

_HAS_RAND_BYTES :: false

// TODO(bill): reimplement `os.write`
_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	return 0, -1
}

_exit :: proc "contextless" (code: int) -> ! {
	trap()
}