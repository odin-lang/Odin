package filepath

import "core:strings"
import "base:runtime"
import "core:os"
import win32 "core:sys/windows"

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
	if is_reserved_name(path) {
		return true
	}
	l := volume_name_len(path)
	if l == 0 {
		return false
	}

	path := path
	path = path[l:]
	if path == "" {
		return false
	}
	return is_slash(path[0])
}


@(private)
temp_full_path :: proc(name: string) -> (path: string, err: os.Error) {
	ta := context.temp_allocator

	name := name
	if name == "" {
		name = "."
	}

	p := win32.utf8_to_utf16(name, ta)
	n := win32.GetFullPathNameW(raw_data(p), 0, nil, nil)
	if n == 0 {
		return "", os.get_last_error()
	}

	buf := make([]u16, n, ta)
	n = win32.GetFullPathNameW(raw_data(p), u32(len(buf)), raw_data(buf), nil)
	if n == 0 {
		delete(buf)
		return "", os.get_last_error()
	}

	return win32.utf16_to_utf8(buf[:n], ta)
}



abs :: proc(path: string, allocator := context.allocator) -> (string, bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	full_path, err := temp_full_path(path)
	if err != nil {
		return "", false
	}
	p := clean(full_path, allocator)
	return p, true
}


join :: proc(elems: []string, allocator := context.allocator) -> string {
	for e, i in elems {
		if e != "" {
			return join_non_empty(elems[i:], allocator)
		}
	}
	return ""
}

join_non_empty :: proc(elems: []string, allocator := context.allocator) -> string {
	context.allocator = allocator

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	
	if len(elems[0]) == 2 && elems[0][1] == ':' {
		i := 1
		for ; i < len(elems); i += 1 {
			if elems[i] != "" {
				break
			}
		}
		s := strings.join(elems[i:], SEPARATOR_STRING, context.temp_allocator)
		s = strings.concatenate({elems[0], s}, context.temp_allocator)
		return clean(s)
	}

	p := clean(strings.join(elems, SEPARATOR_STRING, context.temp_allocator))
	if !is_UNC(p) {
		return p
	}

	head := clean(elems[0], context.temp_allocator)
	if is_UNC(head) {
		return p
	}
	delete(p) // It is not needed now

	tail := clean(strings.join(elems[1:], SEPARATOR_STRING, context.temp_allocator), context.temp_allocator)
	if head[len(head)-1] == SEPARATOR {
		return strings.concatenate({head, tail})
	}

	return strings.concatenate({head, SEPARATOR_STRING, tail})
}
