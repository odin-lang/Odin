//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

@(require)
import "core:sys/posix"

_temp_dir :: proc(allocator: runtime.Allocator) -> (string, runtime.Allocator_Error) {
	if tmp, ok := _lookup_env("TMPDIR", allocator); ok {
		return tmp, nil
	}

	when #defined(posix.P_tmpdir) {
		return clone_string(posix.P_tmpdir, allocator)
	}

	return clone_string("/tmp/", allocator)
}
