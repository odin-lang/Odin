//+build linux
//+private
package sync

import "core:sys/unix"
import "core:time"

_current_thread_id :: proc "contextless" () -> int {
	return unix.sys_gettid()
}
