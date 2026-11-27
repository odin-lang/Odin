#+private
package archive

import "base:runtime"
import "core:os"

_os_lock_open :: proc(path: string, kind: Lock_Kind, create: bool, allocator: runtime.Allocator) -> (f: ^os.File, err: Error) {
	flags := os.File_Flags{.Read}
	if kind == .Exclusive {
		flags += {.Write}
		if create {
			flags += {.Create}
		}
	}
	open_err: os.Error
	f, open_err = os.open(path, flags, os.Permissions_Default_File)
	if open_err != nil {
		return nil, open_err
	}
	return f, nil
}

_replace :: proc(from, to: string, allocator: runtime.Allocator) -> (err: Error) {
	if rename_err := os.rename(from, to); rename_err != nil {
		return rename_err
	}
	return nil
}
