#+build openbsd
#+private
package thread

import "core:sys/posix"
import "core:c"

foreign import pthread "system:pthread"

foreign pthread {
	pthread_get_name_np :: proc(thread: posix.pthread_t, name: [^]u8, len: c.size_t) ---
	pthread_set_name_np :: proc(thread: posix.pthread_t, name: [^]u8) ---
}
