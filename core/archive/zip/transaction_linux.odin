#+private
package archive_zip

import "base:runtime"
import "core:archive"
import "core:os"
import "core:sys/linux"

_os_lock_open :: proc(path: string, kind: Lock_Kind, create: bool, allocator: runtime.Allocator) -> (f: ^os.File, err: Error) {
	flags := os.File_Flags{.Read}
	op    := linux.FLock_Op{.SH, .NB}
	if kind == .Exclusive {
		flags += {.Write}
		op     = {.EX, .NB}
		if create {
			flags += {.Create}
		}
	}
	open_err: os.Error
	f, open_err = os.open(path, flags, os.Permissions_Default_File)
	if open_err != nil {
		return nil, open_err
	}
	errno := linux.flock(linux.Fd(os.fd(f)), op)
	for errno == .EINTR {
		errno = linux.flock(linux.Fd(os.fd(f)), op)
	}
	if errno != .NONE {
		os.close(f)
		if errno == .EWOULDBLOCK {
			return nil, archive.General_Error.Busy
		}
		return nil, os.Error(os.Platform_Error(errno))
	}
	return f, nil
}

_replace :: proc(from, to: string, allocator: runtime.Allocator) -> (err: Error) {
	if rename_err := os.rename(from, to); rename_err != nil {
		return rename_err
	}
	return nil
}
