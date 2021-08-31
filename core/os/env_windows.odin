package os

import win32 "core:sys/windows"

// lookup_env gets the value of the environment variable named by the key
// If the variable is found in the environment the value (which can be empty) is returned and the boolean is true
// Otherwise the returned value will be empty and the boolean will be false
// NOTE: the value will be allocated with the supplied allocator
lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	if key == "" {
		return
	}
	wkey := win32.utf8_to_wstring(key)
	b := make([dynamic]u16, 100, context.temp_allocator)
	for {
		n := win32.GetEnvironmentVariableW(wkey, raw_data(b), u32(len(b)))
		if n == 0 {
			err := win32.GetLastError()
			if err == u32(ERROR_ENVVAR_NOT_FOUND) {
				return "", false
			}
		}

		if n <= u32(len(b)) {
			value = win32.utf16_to_utf8(b[:n], allocator)
			found = true
			return
		}

		resize(&b, len(b)*2)
	}
}


// get_env retrieves the value of the environment variable named by the key
// It returns the value, which will be empty if the variable is not present
// To distinguish between an empty value and an unset value, use lookup_env
// NOTE: the value will be allocated with the supplied allocator
get_env :: proc(key: string, allocator := context.allocator) -> (value: string) {
	value, _ = lookup_env(key, allocator)
	return
}

// set_env sets the value of the environment variable named by the key
set_env :: proc(key, value: string) -> Errno {
	k := win32.utf8_to_wstring(key)
	v := win32.utf8_to_wstring(value)

	if !win32.SetEnvironmentVariableW(k, v) {
		return Errno(win32.GetLastError())
	}
	return 0
}

// unset_env unsets a single environment variable
unset_env :: proc(key: string) -> Errno {
	k := win32.utf8_to_wstring(key)
	if !win32.SetEnvironmentVariableW(k, nil) {
		return Errno(win32.GetLastError())
	}
	return 0
}

// environ returns a copy of strings representing the environment, in the form "key=value"
// NOTE: the slice of strings and the strings with be allocated using the supplied allocator
environ :: proc(allocator := context.allocator) -> []string {
	envs := cast([^]win32.WCHAR)(win32.GetEnvironmentStringsW())
	if envs == nil {
		return nil
	}
	defer win32.FreeEnvironmentStringsW(envs)

	r := make([dynamic]string, 0, 50, allocator)
	for from, i := 0, 0; true; i += 1 {
		if c := envs[i]; c == 0 {
			if i <= from {
				break
			}
			append(&r, win32.utf16_to_utf8(envs[from:i], allocator))
			from = i + 1
		}
	}

	return r[:]
}


// clear_env deletes all environment variables
clear_env :: proc() {
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
