//+private
package os2

import "base:runtime"

_lookup_env :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	//TODO
	return
}

_set_env :: proc(key, value: string) -> bool {
	//TODO
	return false
}

_unset_env :: proc(key: string) -> bool {
	//TODO
	return false
}

_clear_env :: proc() {
	//TODO
}

_environ :: proc(allocator: runtime.Allocator) -> []string {
	//TODO
	return nil
}


