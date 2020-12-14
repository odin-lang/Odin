package filepath

import "core:strings"
import "core:os"
import win32 "core:sys/windows"

SEPARATOR :: '\\';
SEPARATOR_STRING :: `\`;
LIST_SEPARATOR :: ';';

@(private)
reserved_names := [?]string{
	"CON", "PRN", "AUX", "NUL",
	"COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
	"LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
};

is_reserved_name :: proc(path: string) -> bool {
	if len(path) == 0 {
		return false;
	}
	for reserved in reserved_names {
		if strings.equal_fold(path, reserved) {
			return true;
		}
	}
	return false;
}

is_UNC :: proc(path: string) -> bool {
	return volume_name_len(path) > 2;
}


is_abs :: proc(path: string) -> bool {
	if is_reserved_name(path) {
		return true;
	}
	l := volume_name_len(path);
	if l == 0 {
		return false;
	}

	path := path;
	path = path[l:];
	if path == "" {
		return false;
	}
	return is_slash(path[0]);
}


@(private)
temp_full_path :: proc(name: string) -> (path: string, err: os.Errno) {
	ta := context.temp_allocator;

	name := name;
	if name == "" {
		name = ".";
	}

	p := win32.utf8_to_utf16(name, ta);
	buf := make([dynamic]u16, 100, ta);
	for {
		n := win32.GetFullPathNameW(raw_data(p), u32(len(buf)), raw_data(buf), nil);
		if n == 0 {
			delete(buf);
			return "", os.Errno(win32.GetLastError());
		}
		if n <= u32(len(buf)) {
			return win32.utf16_to_utf8(buf[:n], ta), os.ERROR_NONE;
		}
		resize(&buf, len(buf)*2);
	}

	return;
}



abs :: proc(path: string, allocator := context.allocator) -> (string, bool) {
	full_path, err := temp_full_path(path);
	if err != 0 {
		return "", false;
	}
	p := clean(full_path, allocator);
	return p, true;
}

split_list :: proc(path: string, allocator := context.allocator) -> []string {
	if path == "" {
		return nil;
	}

	start: int;
	quote: bool;

	start, quote = 0, false;
	count := 0;

	for i := 0; i < len(path); i += 1 {
		c := path[i];
		switch {
		case c == '"':
			quote = !quote;
		case c == LIST_SEPARATOR && !quote:
			count += 1;
		}
	}

	start, quote = 0, false;
	list := make([]string, count, allocator);
	index := 0;
	for i := 0; i < len(path); i += 1 {
		c := path[i];
		switch {
		case c == '"':
			quote = !quote;
		case c == LIST_SEPARATOR && !quote:
			list[index] = path[start:i];
			index += 1;
			start = i + 1;
		}
	}
	assert(index == count);

	for s0, i in list {
		s, new := strings.replace_all(s0, `"`, ``, allocator);
		if !new {
			s = strings.clone(s, allocator);
		}
		list[i] = s;
	}

	return list;
}




join :: proc(elems: ..string, allocator := context.allocator) -> string {
	for e, i in elems {
		if e != "" {
			return join_non_empty(elems[i:]);
		}
	}
	return "";
}

join_non_empty :: proc(elems: []string) -> string {
	if len(elems[0]) == 2 && elems[0][1] == ':' {
		i := 1;
		for ; i < len(elems); i += 1 {
			if elems[i] != "" {
				break;
			}
		}
		s := strings.join(elems[i:], SEPARATOR_STRING, context.temp_allocator);
		s = strings.concatenate({elems[0], s}, context.temp_allocator);
		return clean(s);
	}

	s := strings.join(elems, SEPARATOR_STRING, context.temp_allocator);
	p := clean(s);
	if !is_UNC(p) {
		return p;
	}

	head := clean(elems[0], context.temp_allocator);
	if is_UNC(head) {
		return p;
	}
	delete(p); // It is not needed now

	tail := clean(strings.join(elems[1:], SEPARATOR_STRING, context.temp_allocator), context.temp_allocator);
	if head[len(head)-1] == SEPARATOR {
		return strings.concatenate({head, tail});
	}

	return strings.concatenate({head, SEPARATOR_STRING, tail});
}
