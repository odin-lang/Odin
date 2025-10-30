package filepath

import       "core:strings"
import       "base:runtime"
import os    "core:os/os2"

SEPARATOR :: '\\'
SEPARATOR_STRING :: `\`
LIST_SEPARATOR :: ';'

@(private)
reserved_names := [?]string{
	"CON", "PRN", "AUX", "NUL",
	"COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
	"LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
}

is_reserved_name :: proc(path: string) -> bool {
	if len(path) == 0 {
		return false
	}
	for reserved in reserved_names {
		if strings.equal_fold(path, reserved) {
			return true
		}
	}
	return false
}

is_UNC :: proc(path: string) -> bool {
	return volume_name_len(path) > 2
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

join :: proc(elems: []string, allocator := context.allocator) -> (string, runtime.Allocator_Error) #optional_allocator_error {
	for e, i in elems {
		if e != "" {
			return join_non_empty(elems[i:], allocator)
		}
	}
	return "", nil
}

join_non_empty :: proc(elems: []string, allocator := context.allocator) -> (joined: string, err: runtime.Allocator_Error) {
	context.allocator = allocator

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	
	if len(elems[0]) == 2 && elems[0][1] == ':' {
		i := 1
		for ; i < len(elems); i += 1 {
			if elems[i] != "" {
				break
			}
		}
		s := strings.join(elems[i:], SEPARATOR_STRING, context.temp_allocator) or_return
		s = strings.concatenate({elems[0], s}, context.temp_allocator) or_return
		s, _ = clean(s)
		return
	}

	p := strings.join(elems, SEPARATOR_STRING, context.temp_allocator) or_return
	p = clean(p) or_return
	if !is_UNC(p) {
		return p, nil
	}
	
	head := clean(elems[0], context.temp_allocator) or_return
	if is_UNC(head) {
		return p, nil
	}
	delete(p) // It is not needed now

	tail := strings.join(elems[1:], SEPARATOR_STRING, context.temp_allocator) or_return
	tail = clean(tail, context.temp_allocator) or_return
	if head[len(head)-1] == SEPARATOR {
		return strings.concatenate({head, tail})
	}

	return strings.concatenate({head, SEPARATOR_STRING, tail})
}
