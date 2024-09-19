#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

import "core:sys/posix"

Read_Directory_Iterator_Impl :: struct {
	dir:      posix.DIR,
	idx:      int,
	fullpath: [dynamic]byte,
}

@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	fimpl := (^File_Impl)(it.f.impl)

	index = it.impl.idx
	it.impl.idx += 1

	for {
		entry := posix.readdir(it.impl.dir)
		if entry == nil {
			// NOTE(laytan): would be good to have an `error` field on the `Read_Directory_Iterator`
			// There isn't a way to now know if it failed or if we are at the end.
			return
		}

		cname := cstring(raw_data(entry.d_name[:]))
		if cname == "." || cname == ".." {
			continue
		}
		sname := string(cname)

		stat: posix.stat_t
		if posix.fstatat(posix.dirfd(it.impl.dir), cname, &stat, { .SYMLINK_NOFOLLOW }) != .OK {
			// NOTE(laytan): would be good to have an `error` field on the `Read_Directory_Iterator`
			// There isn't a way to now know if it failed or if we are at the end.
			return
		}

		n := len(fimpl.name)+1
		non_zero_resize(&it.impl.fullpath, n+len(sname))
		n += copy(it.impl.fullpath[n:], sname)

		fi = internal_stat(stat, string(it.impl.fullpath[:]))
		ok = true
		return
	}
}

@(require_results)
_read_directory_iterator_create :: proc(f: ^File) -> (iter: Read_Directory_Iterator, err: Error) {
	if f == nil || f.impl == nil {
		err = .Invalid_File
		return
	}

	impl := (^File_Impl)(f.impl)

	iter.f = f
	iter.impl.idx = 0

	iter.impl.fullpath.allocator = file_allocator()
	append(&iter.impl.fullpath, impl.name)
	append(&iter.impl.fullpath, "/")
	defer if err != nil { delete(iter.impl.fullpath) }

	// `fdopendir` consumes the file descriptor so we need to `dup` it.
	dupfd := posix.dup(impl.fd)
	if dupfd == -1 {
		err = _get_platform_error()
		return
	}
	defer if err != nil { posix.close(dupfd) }

	iter.impl.dir = posix.fdopendir(dupfd)
	if iter.impl.dir == nil {
		err = _get_platform_error()
		return
	}

	return
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	if it == nil || it.impl.dir == nil {
		return
	}

	posix.closedir(it.impl.dir)
	delete(it.impl.fullpath)
}
