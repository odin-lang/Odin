#+private
package os2

import "core:sys/linux"

Read_Directory_Iterator_Impl :: struct {
	prev_fi:        File_Info,
	dirent_backing: []u8,
	dirent_buflen:  int,
	dirent_off:     int,
}

@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	scan_entries :: proc(it: ^Read_Directory_Iterator, dfd: linux.Fd, entries: []u8, offset: ^int) -> (fd: linux.Fd, file_name: string) {
		for d in linux.dirent_iterate_buf(entries, offset) {
			file_name = linux.dirent_name(d)
			if file_name == "." || file_name == ".." {
				continue
			}

			file_name_cstr := cstring(raw_data(file_name))
			entry_fd, errno := linux.openat(dfd, file_name_cstr, {.NOFOLLOW, .PATH})
			if errno == .NONE {
				return entry_fd, file_name
			} else {
				read_directory_iterator_set_error(it, file_name, _get_platform_error(errno))
			}
		}

		return -1, ""
	}

	index = it.index
	it.index += 1

	dfd := linux.Fd(_fd(it.f))

	entries := it.impl.dirent_backing[:it.impl.dirent_buflen]
	entry_fd, file_name := scan_entries(it, dfd, entries, &it.impl.dirent_off)

	for entry_fd == -1 {
		if len(it.impl.dirent_backing) == 0 {
			it.impl.dirent_backing = make([]u8, 512, file_allocator())
		}

		loop: for {
			buflen, errno := linux.getdents(linux.Fd(dfd), it.impl.dirent_backing[:])
			#partial switch errno {
			case .EINVAL:
				delete(it.impl.dirent_backing, file_allocator())
				n := len(it.impl.dirent_backing) * 2
				it.impl.dirent_backing = make([]u8, n, file_allocator())
				continue
			case .NONE:
				if buflen == 0 {
					return
				}
				it.impl.dirent_off = 0
				it.impl.dirent_buflen = buflen
				entries = it.impl.dirent_backing[:buflen]
				break loop
			case:
				read_directory_iterator_set_error(it, name(it.f), _get_platform_error(errno))
				return
			}
		}

		entry_fd, file_name = scan_entries(it, dfd, entries, &it.impl.dirent_off)
	}
	defer linux.close(entry_fd)

	// PERF: reuse the fullpath string like on posix and wasi.
	file_info_delete(it.impl.prev_fi, file_allocator())

	err: Error
	fi, err = _fstat_internal(entry_fd, file_allocator())
	it.impl.prev_fi = fi

	if err != nil {
		path, _ := _get_full_path(entry_fd, temp_allocator())
		read_directory_iterator_set_error(it, path, err)
	}

	ok = true
	return
}

_read_directory_iterator_init :: proc(it: ^Read_Directory_Iterator, f: ^File) {
	// NOTE: Allow calling `init` to target a new directory with the same iterator.
	it.impl.dirent_buflen = 0
	it.impl.dirent_off = 0

	if f == nil || f.impl == nil {
		read_directory_iterator_set_error(it, "", .Invalid_File)
		return
	}

	stat: linux.Stat
	errno := linux.fstat(linux.Fd(fd(f)), &stat)
	if errno != .NONE {
		read_directory_iterator_set_error(it, name(f), _get_platform_error(errno))
		return
	}

	if (stat.mode & linux.S_IFMT) != linux.S_IFDIR {
		read_directory_iterator_set_error(it, name(f), .Invalid_Dir)
		return
	}
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	if it == nil {
		return
	}

	delete(it.impl.dirent_backing, file_allocator())
	file_info_delete(it.impl.prev_fi, file_allocator())
}
