//+build openbsd
//+private
package sync2

import "core:os"

_current_thread_id :: proc "contextless" () -> int {
	return os.current_thread_id()
}
