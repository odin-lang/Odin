package filepath

import "base:runtime"
import "core:strings"

SEPARATOR :: '/'
SEPARATOR_STRING :: `/`
LIST_SEPARATOR :: ':'

is_abs :: proc(path: string) -> bool {
	return strings.has_prefix(path, "/")
}

abs :: proc(path: string, allocator := context.allocator) -> (string, bool) {
	if is_abs(path) {
		return strings.clone(string(path), allocator), true
	}

	return path, false
}