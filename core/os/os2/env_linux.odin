//+private
package os2

_get_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
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

_environ :: proc(allocator := context.allocator) -> []string {
	//TODO
	return nil
}


