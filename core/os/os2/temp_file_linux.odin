//+private
package os2

import "base:runtime"

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	TEMP_ALLOCATOR_GUARD()
	tmpdir := get_env("TMPDIR", temp_allocator())
	if tmpdir == "" {
		tmpdir = "/tmp"
	}
	return clone_string(tmpdir, allocator)
}
