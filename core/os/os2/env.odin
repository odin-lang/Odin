package os2

// get_env gets the value of the environment variable named by the key
// If the variable is found in the environment the value (which can be empty) is returned and the boolean is true
// Otherwise the returned value will be empty and the boolean will be false
// NOTE: the value will be allocated with the supplied allocator
get_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	return _get_env(key, allocator)
}

// set_env sets the value of the environment variable named by the key
// Returns true on success, false on failure
set_env :: proc(key, value: string) -> bool {
	return _set_env(key, value)
}

// unset_env unsets a single environment variable
// Returns true on success, false on failure
unset_env :: proc(key: string) -> bool {
	return _unset_env(key)
}

clear_env :: proc() {
	_clear_env()
}


// environ returns a copy of strings representing the environment, in the form "key=value"
// NOTE: the slice of strings and the strings with be allocated using the supplied allocator
environ :: proc(allocator := context.allocator) -> []string {
	return _environ(allocator)
}


