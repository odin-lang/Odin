//+build freestanding
package runtime

// TODO(bill): reimplement `os.write`
_os_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	return 0, -1
}
