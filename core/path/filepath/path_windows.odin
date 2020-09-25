package filepath

import "core:strings"

SEPARATOR :: '\\';
SEPARATOR_STRING :: `\`;


reserved_names := []string{
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
