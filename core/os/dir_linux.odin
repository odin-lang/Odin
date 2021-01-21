package os

import "core:strconv"
import "core:strings"
import "core:mem"

read_dir :: proc(fd: Handle, n: int, allocator := context.allocator) -> (fi: []File_Info, err: Errno) {
	dirp: Dir;
	dirp, err = _fdopendir(fd);
	if err != ERROR_NONE {
		return;
	}

	defer _closedir(dirp);

	dirpath: string;
	dirpath, err = absolute_path_from_handle(fd);

	if err != ERROR_NONE {
		return;
	}

	defer delete(dirpath);

	n := n;
	size := n;
	if n <= 0 {
		n = -1;
		size = 100;
	}

	dfi := make([dynamic]File_Info, 0, size);

	for {
		entry: Dirent;
		end_of_stream: bool;
		entry, err, end_of_stream = _readdir(dirp);
		if err != ERROR_NONE {
			for fi_ in dfi {
				file_info_delete(fi_);
			}
			delete(dfi);
			return;
		} else if end_of_stream {
			break;
		}

		fi_: File_Info;
		
		filename := cast(string)(transmute(cstring)mem.Raw_Cstring{ data = &entry.name[0] });
		fullpath := strings.join( []string{ dirpath, filename }, "/" );
		defer delete(fullpath);

		fi_, err = stat(fullpath);
		if err != ERROR_NONE {
			for fi_ in dfi {
				file_info_delete(fi_);
			}
			delete(dfi);
			return;
		}

		append(&dfi, fi_);
	}

	return dfi[:], ERROR_NONE;
}
