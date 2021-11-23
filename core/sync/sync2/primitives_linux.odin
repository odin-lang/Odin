//+build linux
//+private
package sync2

import "core:sys/unix"

_current_thread_id :: proc "contextless" () -> int {
	return unix.sys_gettid()
}
