package os2

import "base:runtime"

// get_env retrieves the value of the environment variable named by the key
// It returns the value, which will be empty if the variable is not present
// To distinguish between an empty value and an unset value, use lookup_env
// NOTE: the value will be allocated with the supplied allocator
@(require_results)
get_env :: proc(key: string, allocator: runtime.Allocator) -> string {
	value, _ := lookup_env(key, allocator)
	return value
}

// lookup_env gets the value of the environment variable named by the key
// If the variable is found in the environment the value (which can be empty) is returned and the boolean is true
// Otherwise the returned value will be empty and the boolean will be false
// NOTE: the value will be allocated with the supplied allocator
@(require_results)
lookup_env :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	return _lookup_env(key, allocator)
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
@(require_results)
environ :: proc(allocator: runtime.Allocator) -> []string {
	return _environ(allocator)
}


