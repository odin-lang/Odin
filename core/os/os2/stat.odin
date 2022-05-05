package os2

import "core:time"

File_Info :: struct {
	fullpath: string,
	name:     string,
	size:     i64,
	mode:     File_Mode,
	is_dir:   bool,
	creation_time:     time.Time,
	modification_time: time.Time,
	access_time:       time.Time,
}

file_info_slice_delete :: proc(infos: []File_Info, allocator := context.allocator) {
	for i := len(infos)-1; i >= 0; i -= 1 {
		file_info_delete(infos[i], allocator)
	}
	delete(infos, allocator)
}

file_info_delete :: proc(fi: File_Info, allocator := context.allocator) {
	delete(fi.fullpath, allocator)
}

fstat :: proc(f: ^File, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
	return _fstat(f, allocator)
}

stat :: proc(name: string, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
	return _stat(name, allocator)
}

lstat :: proc(name: string, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
	return _lstat(name, allocator)
}


same_file :: proc(fi1, fi2: File_Info) -> bool {
	return _same_file(fi1, fi2)
}
