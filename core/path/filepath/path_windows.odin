package filepath

import       "base:runtime"
import os    "core:os/os2"

SEPARATOR :: '\\'
SEPARATOR_STRING :: `\`
LIST_SEPARATOR :: ';'

is_UNC :: proc(path: string) -> bool {
	return len(volume_name(path)) > 2
}

is_abs :: proc(path: string) -> bool {
	return os.is_absolute_path(path)
}

abs :: proc(path: string, allocator := context.allocator) -> (string, bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	full_path, err := os.get_absolute_path(path, context.temp_allocator)
	if err != nil {
		return "", false
	}
	p, _ := clean(full_path, allocator)
	return p, true
}