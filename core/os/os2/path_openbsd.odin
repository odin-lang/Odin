package os2

import "base:runtime"

import "core:strings"
import "core:sys/posix"

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	// OpenBSD does not have an API for this, we do our best below.

	if len(runtime.args__) <= 0 {
		err = .Invalid_Path
		return
	}

	real :: proc(path: cstring, allocator: runtime.Allocator) -> (out: string, err: Error) {
		real := posix.realpath(path)
		if real == nil {
			err = _get_platform_error()
			return
		}
		defer posix.free(real)
		return clone_string(string(real), allocator)
	} 

	arg := runtime.args__[0]
	sarg := string(arg)

	if len(sarg) == 0 {
		err = .Invalid_Path
		return
	}

	if sarg[0] == '.' || sarg[0] == '/' {
		return real(arg, allocator)
	}

	TEMP_ALLOCATOR_GUARD()

	buf := strings.builder_make(temp_allocator())

	paths := get_env("PATH", temp_allocator())
	for dir in strings.split_iterator(&paths, ":") {
		strings.builder_reset(&buf)
		strings.write_string(&buf, dir)
		strings.write_string(&buf, "/")
		strings.write_string(&buf, sarg)

		cpath := strings.to_cstring(&buf) or_return
		if posix.access(cpath, {.X_OK}) == .OK {
			return real(cpath, allocator)
		}
	}

	err = .Invalid_Path
	return
}
