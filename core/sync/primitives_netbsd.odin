//+private
package sync

import "core:sys/unix"

_current_thread_id :: proc "contextless" () -> int {
	return cast(int) unix.pthread_self()
}
