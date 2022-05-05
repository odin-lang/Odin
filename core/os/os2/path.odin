package os2

Path_Separator      :: _Path_Separator      // OS-Specific
Path_List_Separator :: _Path_List_Separator // OS-Specific

is_path_separator :: proc(c: byte) -> bool {
	return _is_path_separator(c)
}

mkdir :: proc(name: string, perm: File_Mode) -> Error {
	return _mkdir(name, perm)
}

mkdir_all :: proc(path: string, perm: File_Mode) -> Error {
	return _mkdir_all(path, perm)
}

remove_all :: proc(path: string) -> Error {
	return _remove_all(path)
}



getwd :: proc(allocator := context.allocator) -> (dir: string, err: Error) {
	return _getwd(allocator)
}
setwd :: proc(dir: string) -> (err: Error) {
	return _setwd(dir)
}
