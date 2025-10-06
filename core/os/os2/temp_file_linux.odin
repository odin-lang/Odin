#+private
package os2

import "base:runtime"

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	tmpdir := get_env("TMPDIR", temp_allocator)
	if tmpdir == "" {
		tmpdir = "/tmp"
	}
	return clone_string(tmpdir, allocator)
}
