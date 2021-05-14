package os2

_lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	return "", false;
}

_set_env :: proc(key, value: string) -> bool {
	return false;
}

_unset_env :: proc(key: string) -> bool {
	return false;
}

_clear_env :: proc() {
	
}

_environ :: proc(allocator := context.allocator) -> []string {
	return nil;
}


