//+build linux
package runtime

import "core:sys/linux"

_os_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	ret, errno := linux.write(1, data)
	return ret, cast(_OS_Errno) errno
}
