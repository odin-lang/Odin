package os2

import "base:runtime"

import "core:sys/darwin"
import "core:sys/posix"

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	size: u32

	ret := darwin._NSGetExecutablePath(nil, &size)
	assert(ret == -1)
	assert(size > 0)

	TEMP_ALLOCATOR_GUARD()

	buf := make([]byte, size, temp_allocator()) or_return
	assert(u32(len(buf)) == size)

	ret = darwin._NSGetExecutablePath(raw_data(buf), &size)
	assert(ret == 0)

	real := posix.realpath(cstring(raw_data(buf)))
	if real == nil {
		err = _get_platform_error()
		return
	}
	defer posix.free(real)

	return clone_string(string(real), allocator)
}
