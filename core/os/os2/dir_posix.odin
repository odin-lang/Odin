//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

import "core:sys/posix"

@(private)
_read_directory :: proc(f: ^File, n: int, allocator: runtime.Allocator) -> (files: []File_Info, err: Error) {
	if f == nil || f.impl == nil {
		err = .Invalid_File
		return
	}

	n := n
	if n == 0 {
		return
	}

	impl := (^File_Impl)(f)

	dir := posix.fdopendir(impl.fd)
	if dir == nil {
		err = _get_platform_error()
		return
	}
	defer posix.closedir(dir)

	dfiles: [dynamic]File_Info
	dfiles.allocator = allocator
	defer if err != nil {
		file_info_slice_delete(dfiles[:], allocator)
	}

	for {
		posix.set_errno(.NONE)
		entry := posix.readdir(dir)
		if entry == nil {
			if errno := posix.errno(); errno != .NONE {
				err = _get_platform_error()
				return
			} else {
				break
			}
		}

		cname := cstring(raw_data(entry.d_name[:]))
		if cname == "." || cname == ".." {
			continue
		}

		stat: posix.stat_t
		if posix.fstatat(posix.dirfd(dir), cname, &stat, { .SYMLINK_NOFOLLOW }) != .OK {
			err = _get_platform_error()
			return
		}

		fullpath := concatenate({impl.name, "/", string(cname)}, allocator) or_return
		fi := internal_stat(stat, fullpath)
		append(&dfiles, fi) or_return

		n -= 1
		if n == 0 {
			break
		}
	}

	files = dfiles[:]
	return
}
