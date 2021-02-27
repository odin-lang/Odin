//+build linux, darwin, freebsd
package filepath

import "core:strings"
import "core:os"

SEPARATOR :: '/';
SEPARATOR_STRING :: `/`;
LIST_SEPARATOR :: ':';

is_reserved_name :: proc(path: string) -> bool {
	return false;
}

is_abs :: proc(path: string) -> bool {
	return strings.has_prefix(path, "/");
}

abs :: proc(path: string, allocator := context.allocator) -> (string, bool) {
	full_path, err := os.absolute_path_from_relative(path);
	if err != os.ERROR_NONE {
		return "", false;
	}
	return full_path, true;
}

join :: proc(elems: ..string, allocator := context.allocator) -> string {
	for e, i in elems {
		if e != "" {
			p := strings.join(elems[i:], SEPARATOR_STRING, context.temp_allocator);
			return clean(p, allocator);
		}
	}
	return "";
}