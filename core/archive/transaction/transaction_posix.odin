#+private
#+build darwin, freebsd, netbsd, openbsd
package archive_transaction

import "base:runtime"
import "core:archive"
import "core:c"
import "core:os"
import "core:sys/posix"

when ODIN_OS == .Darwin {
	foreign import libc "system:System"
} else {
	foreign import libc "system:c"
}

LOCK_SH :: 1
LOCK_EX :: 2
LOCK_NB :: 4

@(default_calling_convention = "c")
foreign libc {
	flock :: proc(fd: c.int, operation: c.int) -> c.int ---
}

_os_lock_open :: proc(path: string, kind: Lock_Kind, create: bool, allocator: runtime.Allocator) -> (f: ^os.File, err: Error) {
	flags := os.File_Flags{.Read}
	op    := c.int(LOCK_SH | LOCK_NB)
	if kind == .Exclusive {
		flags += {.Write}
		op     = LOCK_EX | LOCK_NB
		if create {
			flags += {.Create}
		}
	}
	open_err: os.Error
	f, open_err = os.open(path, flags, os.Permissions_Default_File)
	if open_err != nil {
		return nil, open_err
	}
	result := flock(c.int(os.fd(f)), op)
	errno  := posix.errno()
	for result != 0 && errno == .EINTR {
		result = flock(c.int(os.fd(f)), op)
		errno  = posix.errno()
	}
	if result != 0 {
		os.close(f)
		if errno == .EWOULDBLOCK || errno == .EAGAIN {
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
