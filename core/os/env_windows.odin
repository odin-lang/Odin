package os

import win32 "core:sys/windows"
import "base:runtime"

// lookup_env gets the value of the environment variable named by the key
// If the variable is found in the environment the value (which can be empty) is returned and the boolean is true
// Otherwise the returned value will be empty and the boolean will be false
// NOTE: the value will be allocated with the supplied allocator
@(require_results)
lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	if key == "" {
		return
	}
	wkey := win32.utf8_to_wstring(key)
	n := win32.GetEnvironmentVariableW(wkey, nil, 0)
	if n == 0 && get_last_error() == ERROR_ENVVAR_NOT_FOUND {
		return "", false
	}
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)

	b, _ := make([dynamic]u16, n, context.temp_allocator)
	n = win32.GetEnvironmentVariableW(wkey, raw_data(b), u32(len(b)))
	if n == 0 && get_last_error() == ERROR_ENVVAR_NOT_FOUND {
		return "", false
	}
	value, _ = win32.utf16_to_utf8(b[:n], allocator)
	found = true
	return
}


// get_env retrieves the value of the environment variable named by the key
// It returns the value, which will be empty if the variable is not present
// To distinguish between an empty value and an unset value, use lookup_env
// NOTE: the value will be allocated with the supplied allocator
@(require_results)
get_env :: proc(key: string, allocator := context.allocator) -> (value: string) {
	value, _ = lookup_env(key, allocator)
	return
}

// set_env sets the value of the environment variable named by the key
set_env :: proc(key, value: string) -> Error {
	k := win32.utf8_to_wstring(key)
	v := win32.utf8_to_wstring(value)

	if !win32.SetEnvironmentVariableW(k, v) {
		return get_last_error()
	}
	return nil
}

// unset_env unsets a single environment variable
unset_env :: proc(key: string) -> Error {
	k := win32.utf8_to_wstring(key)
	if !win32.SetEnvironmentVariableW(k, nil) {
		return get_last_error()
	}
	return nil
}

// environ returns a copy of strings representing the environment, in the form "key=value"
// NOTE: the slice of strings and the strings with be allocated using the supplied allocator
@(require_results)
environ :: proc(allocator := context.allocator) -> []string {
	envs := ([^]win32.WCHAR)(win32.GetEnvironmentStringsW())
	if envs == nil {
		return nil
	}
	defer win32.FreeEnvironmentStringsW(envs)

	r, err := make([dynamic]string, 0, 50, allocator)
	if err != nil {
		return nil
	}
	for from, i := 0, 0; true; i += 1 {
		if c := envs[i]; c == 0 {
			if i <= from {
				break
			}
			append(&r, win32.utf16_to_utf8(envs[from:i], allocator) or_else "")
			from = i + 1
		}
	}

	return r[:]
}


// clear_env deletes all environment variables
clear_env :: proc() {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	envs := environ(context.temp_allocator)
	for env in envs {
		for j in 1..<len(env) {
			if env[j] == '=' {
				unset_env(env[0:j])
				break
			}
		}
	}
}
