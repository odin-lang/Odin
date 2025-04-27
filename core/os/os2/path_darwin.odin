package os2

import "base:runtime"

import "core:sys/darwin"
import "core:sys/posix"

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	buffer: [darwin.PIDPATHINFO_MAXSIZE]byte = ---
	ret := darwin.proc_pidpath(posix.getpid(), raw_data(buffer[:]), len(buffer))
	if ret > 0 {
		return clone_string(string(buffer[:ret]), allocator)
	}

	err = _get_platform_error()
	return
}
