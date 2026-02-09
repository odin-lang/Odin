#+private
package os2

import "base:runtime"

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	// NOTE: requires user to add /tmp to their preopen dirs, no standard way exists.
	return clone_string("/tmp", allocator)
}
