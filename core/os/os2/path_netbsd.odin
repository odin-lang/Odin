package os2

import "base:runtime"

import "core:sys/posix"

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	TEMP_ALLOCATOR_GUARD()

	buf := make([dynamic]byte, 1024, temp_allocator()) or_return
	for {
		n := posix.readlink("/proc/curproc/exe", raw_data(buf), len(buf))
		if n < 0 {
			err = _get_platform_error()
			return
		}

		if n < len(buf) {
			return clone_string(string(buf[:n]), allocator)
		}

		resize(&buf, len(buf)*2) or_return
	}
}
