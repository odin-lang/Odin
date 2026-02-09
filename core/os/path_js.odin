#+build js wasm32, js wasm64p32
#+private
package os

import "base:runtime"

_Path_Separator        :: '/'
_Path_Separator_String :: "/"
_Path_List_Separator   :: ':'

_is_path_separator :: proc(c: byte) -> (ok: bool) {
	return c == _Path_Separator
}

_mkdir :: proc(name: string, perm: int) -> (err: Error) {
	return .Unsupported
}

_mkdir_all :: proc(path: string, perm: int) -> (err: Error) {
	return .Unsupported
}

_remove_all :: proc(path: string) -> (err: Error) {
	return .Unsupported
}

_get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return "", .Unsupported
}

_set_working_directory :: proc(dir: string) -> (err: Error) {
	return .Unsupported
}

_get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	return "", .Unsupported
}

_are_paths_identical :: proc(a, b: string) -> bool {
	return false
}

_clean_path_handle_start :: proc(path: string, buffer: []u8) -> (rooted: bool, start: int) {
	return
}

_is_absolute_path :: proc(path: string) -> bool {
	return false
}

_get_absolute_path :: proc(path: string, allocator: runtime.Allocator) -> (absolute_path: string, err: Error) {
	return "", .Unsupported
}

_get_relative_path_handle_start :: proc(base, target: string) -> bool {
	return false
}

_get_common_path_len :: proc(base, target: string) -> int {
	i := 0
	end := min(len(base), len(target))
	for j in 0..=end {
		if j == end || _is_path_separator(base[j]) {
			if base[i:j] == target[i:j] {
				i = j
			} else {
				break
			}
		}
	}
	return i
}

_split_path :: proc(path: string) -> (dir, file: string) {
	i := len(path) - 1
	for i >= 0 && !_is_path_separator(path[i]) {
		i -= 1
	}
	if i == 0 {
		return path[:i+1], path[i+1:]
	} else if i > 0 {
		return path[:i], path[i+1:]
	}
	return "", path
}