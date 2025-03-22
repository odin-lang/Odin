#+private
#+build linux, darwin, netbsd, freebsd, openbsd, wasi
package os2

// This implementation is for all systems that have POSIX-compliant filesystem paths.

import "base:runtime"
import "core:strings"
import "core:sys/posix"

_are_paths_identical :: proc(a, b: string) -> (identical: bool) {
	return a == b
}

_clean_path_handle_start :: proc(path: string, buffer: []u8) -> (rooted: bool, start: int) {
	// Preserve rooted paths.
	if _is_path_separator(path[0]) {
		rooted = true
		buffer[0] = _Path_Separator
		start = 1
	}
	return
}

_is_absolute_path :: proc(path: string) -> bool {
	return len(path) > 0 && _is_path_separator(path[0])
}

_get_absolute_path :: proc(path: string, allocator: runtime.Allocator) -> (absolute_path: string, err: Error) {
	rel := path
	if rel == "" {
		rel = "."
	}
	TEMP_ALLOCATOR_GUARD()
	rel_cstr := strings.clone_to_cstring(rel, temp_allocator())
	path_ptr := posix.realpath(rel_cstr, nil)
	if path_ptr == nil {
		return "", Platform_Error(posix.errno())
	}
	defer posix.free(path_ptr)

	path_str := strings.clone(string(path_ptr), allocator)
	return path_str, nil
}

_get_relative_path_handle_start :: proc(base, target: string) -> bool {
	base_rooted   := len(base)   > 0 && _is_path_separator(base[0])
	target_rooted := len(target) > 0 && _is_path_separator(target[0])
	return base_rooted == target_rooted
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
