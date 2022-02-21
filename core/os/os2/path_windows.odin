//+private
package os2

_Path_Separator      :: '\\'
_Path_List_Separator :: ';'

_is_path_separator :: proc(c: byte) -> bool {
	return c == '\\' || c == '/'
}

_mkdir :: proc(name: string, perm: File_Mode) -> Error {
	return nil
}

_mkdir_all :: proc(path: string, perm: File_Mode) -> Error {
	// TODO(bill): _mkdir_all for windows
	return nil
}

_remove_all :: proc(path: string) -> Error {
	// TODO(bill): _remove_all for windows
	return nil
}

_getwd :: proc(allocator := context.allocator) -> (dir: string, err: Error) {
	return "", nil
}

_setwd :: proc(dir: string) -> (err: Error) {
	return nil
}
