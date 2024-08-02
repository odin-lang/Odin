//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "core:sys/posix"

Read_Directory_Iterator_Impl :: struct {
	dir:      posix.DIR,
	idx:      int,

	// NOTE: could there be paths bigger than this, maybe, probably, but why does it exist then?
	fullpath: [posix.PATH_MAX]byte,
}

@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	index = it.impl.idx
	it.impl.idx += 1

	entry := posix.readdir(it.impl.dir)
	if entry == nil {
		// NOTE(laytan): would be good to have an `error` field on the `Read_Directory_Iterator`
		// There isn't a way to now know if it failed or if we are at the end.
		return
	}

	cname := cstring(raw_data(entry.d_name[:]))

	// NOTE: these shouldn't be given back, but how?
	// if cname == "." || cname == ".." {
	//     continue
	// }

	stat: posix.stat_t
	if posix.fstatat(posix.dirfd(it.impl.dir), cname, &stat, { .SYMLINK_NOFOLLOW }) != .OK {
		// NOTE(laytan): would be good to have an `error` field on the `Read_Directory_Iterator`
		// There isn't a way to now know if it failed or if we are at the end.
		return
	}

	fimpl := (^File_Impl)(it.f.impl)

	n := copy(it.impl.fullpath[:],  fimpl.name)
	n += copy(it.impl.fullpath[n:], "/")
	n += copy(it.impl.fullpath[n:], string(cname))

	fi = internal_stat(stat, string(it.impl.fullpath[:n]))
	ok = true
	return
}

@(require_results)
_read_directory_iterator_create :: proc(f: ^File) -> (iter: Read_Directory_Iterator, err: Error) {
	if f == nil || f.impl == nil {
		err = .Invalid_File
		return
	}
	iter.f = f
	iter.impl.idx = 0

	impl := (^File_Impl)(f.impl)

	iter.impl.dir = posix.fdopendir(impl.fd)
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
}
