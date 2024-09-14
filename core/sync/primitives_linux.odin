#+build linux
#+private
package sync

import "core:sys/linux"

_current_thread_id :: proc "contextless" () -> int {
	return cast(int) linux.gettid()
}
