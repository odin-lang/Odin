#+build darwin, linux, netbsd, freebsd, openbsd, haiku
package os

import "core:strings"

@(require_results)
read_dir :: proc(fd: Handle, n: int, allocator := context.allocator) -> (fi: []File_Info, err: Error) {
	context.allocator = allocator

	dupfd := _dup(fd) or_return
	dirp  := _fdopendir(dupfd) or_return
	defer _closedir(dirp)

	dirpath := absolute_path_from_handle(dupfd) or_return
	defer delete(dirpath)

	n := n
	size := n
	if n <= 0 {
		n = -1
		size = 100
	}

	dfi := make([dynamic]File_Info, 0, size, allocator) or_return
	defer if err != nil {
		for fi_ in dfi {
			file_info_delete(fi_, allocator)
		}
		delete(dfi)
	}

	for {
		entry: Dirent
		end_of_stream: bool
		entry, err, end_of_stream = _readdir(dirp)
		if err != nil {
			return
		} else if end_of_stream {
			break
		}

		fi_: File_Info
		filename := string(cstring(&entry.name[0]))

		if filename == "." || filename == ".." {
			continue
		}

		fullpath := strings.join({ dirpath, filename }, "/", allocator)

		s: OS_Stat
		s, err = _lstat(fullpath)
		if err != nil {
			delete(fullpath, allocator)
			return
		}
		_fill_file_info_from_stat(&fi_, s)
		fi_.fullpath = fullpath
		fi_.name = path_base(fi_.fullpath)

		append(&dfi, fi_)
	}

	return dfi[:], nil
}
