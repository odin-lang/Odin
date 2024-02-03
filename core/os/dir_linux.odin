package os

import "core:strings"
import "core:mem"
import "base:runtime"

read_dir :: proc(fd: Handle, n: int, allocator := context.allocator) -> (fi: []File_Info, err: Errno) {
	dirp: Dir
	dirp, err = _fdopendir(fd)
	if err != ERROR_NONE {
		return
	}

	defer _closedir(dirp)

	dirpath: string
	dirpath, err = absolute_path_from_handle(fd)

	if err != ERROR_NONE {
		return
	}

	defer delete(dirpath)

	n := n
	size := n
	if n <= 0 {
		n = -1
		size = 100
	}

	dfi := make([dynamic]File_Info, 0, size, allocator)

	for {
		entry: Dirent
		end_of_stream: bool
		entry, err, end_of_stream = _readdir(dirp)
		if err != ERROR_NONE {
			for fi_ in dfi {
				file_info_delete(fi_, allocator)
			}
			delete(dfi)
			return
		} else if end_of_stream {
			break
		}

		fi_: File_Info
		filename := cast(string)(transmute(cstring)mem.Raw_Cstring{ data = &entry.name[0] })

		if filename == "." || filename == ".." {
			continue
		}

		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)
		fullpath := strings.join( []string{ dirpath, filename }, "/", context.temp_allocator)
		defer delete(fullpath, context.temp_allocator)

		fi_, err = stat(fullpath, allocator)
		if err != ERROR_NONE {
			for fi__ in dfi {
				file_info_delete(fi__, allocator)
			}
			delete(dfi)
			return
		}

		append(&dfi, fi_)
	}

	return dfi[:], ERROR_NONE
}
