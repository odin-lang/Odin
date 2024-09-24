#+build freebsd
#+private
package sync

import "core:c"

foreign import dl "system:dl"

foreign dl {
	pthread_getthreadid_np :: proc "c" () -> c.int ---
}

_current_thread_id :: proc "contextless" () -> int {
	return int(pthread_getthreadid_np())
}
