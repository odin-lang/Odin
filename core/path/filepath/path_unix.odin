//+build linux, darwin, freebsd
package filepath

import "core:strings"
import "core:os"

SEPARATOR :: '/';
SEPARATOR_STRING :: `/`;
LIST_SEPARATOR :: ':';

abs :: proc(path: string, allocator := context.allocator) -> (string, bool) {
	full_path, err := os.absolute_path_from_relative(path);
	if err != os.ERROR_NONE {
		return "", false;
	}
	return full_path, true;
}

join :: proc(elems: ..string, allocator := context.allocator) -> string {
	s := strings.join(elems, SEPARATOR_STRING);
	return s;
}

is_abs :: proc(path: string) -> bool {
	return (path[0] == '/');
}
