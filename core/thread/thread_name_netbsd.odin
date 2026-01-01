#+build netbsd
#+private
package thread

import "core:sys/posix"
import "core:c"

foreign import pthread "system:pthread"

foreign pthread {
	pthread_getname_np :: proc(thread: posix.pthread_t, name: [^]u8, len: c.size_t) -> posix.Errno ---
	pthread_setname_np :: proc(thread: posix.pthread_t, name: cstring, arg: rawptr) -> posix.Errno ---
}
