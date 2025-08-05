#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

import "core:sys/posix"

Read_Directory_Iterator_Impl :: struct {
	dir:      posix.DIR,
	fullpath: [dynamic]byte,
}

@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	fimpl := (^File_Impl)(it.f.impl)

	index = it.index
	it.index += 1

	for {
		posix.set_errno(nil)
		entry := posix.readdir(it.impl.dir)
		if entry == nil {
			if errno := posix.errno(); errno != nil {
				read_directory_iterator_set_error(it, name(it.f), _get_platform_error(errno))
			}
			return
		}

		cname := cstring(raw_data(entry.d_name[:]))
		if cname == "." || cname == ".." {
			continue
		}
		sname := string(cname)

		n := len(fimpl.name)+1
		if err := non_zero_resize(&it.impl.fullpath, n+len(sname)); err != nil {
			read_directory_iterator_set_error(it, sname, err)
			ok = true
			return
		}
		copy(it.impl.fullpath[n:], sname)

		stat: posix.stat_t
		if posix.fstatat(posix.dirfd(it.impl.dir), cname, &stat, { .SYMLINK_NOFOLLOW }) != .OK {
			read_directory_iterator_set_error(it, string(it.impl.fullpath[:]), _get_platform_error())
			ok = true
			return
		}

		fi = internal_stat(stat, string(it.impl.fullpath[:]))
		ok = true
		return
	}
}

_read_directory_iterator_init :: proc(it: ^Read_Directory_Iterator, f: ^File) {
	if f == nil || f.impl == nil {
		read_directory_iterator_set_error(it, "", .Invalid_File)
		return
	}

	impl := (^File_Impl)(f.impl)

	// NOTE: Allow calling `init` to target a new directory with the same iterator.
	it.impl.fullpath.allocator = file_allocator()
	clear(&it.impl.fullpath)
	if err := reserve(&it.impl.fullpath, len(impl.name)+128); err != nil {
		read_directory_iterator_set_error(it, name(f), err)
		return
	}

	append(&it.impl.fullpath, impl.name)
	append(&it.impl.fullpath, "/")

	// `fdopendir` consumes the file descriptor so we need to `dup` it.
	dupfd := posix.dup(impl.fd)
	if dupfd == -1 {
		read_directory_iterator_set_error(it, name(f), _get_platform_error())
		return
	}
	defer if it.err.err != nil { posix.close(dupfd) }

	// NOTE: Allow calling `init` to target a new directory with the same iterator.
	if it.impl.dir != nil {
		posix.closedir(it.impl.dir)
	}

	it.impl.dir = posix.fdopendir(dupfd)
	if it.impl.dir == nil {
		read_directory_iterator_set_error(it, name(f), _get_platform_error())
		return
	}

	return
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	if it.impl.dir == nil {
		return
	}

	posix.closedir(it.impl.dir)
	delete(it.impl.fullpath)
}
