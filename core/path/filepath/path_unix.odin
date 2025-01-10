#+build linux, darwin, freebsd, openbsd, netbsd, haiku
package filepath

import "base:runtime"

import "core:strings"
import "core:sys/posix"

SEPARATOR :: '/'
SEPARATOR_STRING :: `/`
LIST_SEPARATOR :: ':'

is_reserved_name :: proc(path: string) -> bool {
	return false
}

is_abs :: proc(path: string) -> bool {
	return strings.has_prefix(path, "/")
}

abs :: proc(path: string, allocator := context.allocator) -> (string, bool) {
	rel := path
	if rel == "" {
		rel = "."
	}
	rel_cstr := strings.clone_to_cstring(rel, context.temp_allocator)
	path_ptr := posix.realpath(rel_cstr, nil)
	if path_ptr == nil {
		return "", posix.errno() == nil
	}
	defer posix.free(path_ptr)

	path_str := strings.clone(string(path_ptr), allocator)
	return path_str, true
}

join :: proc(elems: []string, allocator := context.allocator) -> (joined: string, err: runtime.Allocator_Error) #optional_allocator_error {
	for e, i in elems {
		if e != "" {
			runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)
			p := strings.join(elems[i:], SEPARATOR_STRING, context.temp_allocator) or_return
			return clean(p, allocator)
		}
	}
	return "", nil
}
