//+build openbsd
//+private
package sync

import "core:os"

_current_thread_id :: proc "contextless" () -> int {
	return os.current_thread_id()
}
