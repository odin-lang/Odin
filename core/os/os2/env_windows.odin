//+private
package os2

import win32 "core:sys/windows"

_lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	if key == "" {
		return
	}
	wkey := win32.utf8_to_wstring(key)

	n := win32.GetEnvironmentVariableW(wkey, nil, 0)
	if n == 0 {
		err := win32.GetLastError()
		if err == win32.ERROR_ENVVAR_NOT_FOUND {
			return "", false
		}
		return "", true
	}
	b := make([]u16, n+1, context.temp_allocator)

	n = win32.GetEnvironmentVariableW(wkey, raw_data(b), u32(len(b)))
	if n == 0 {
		err := win32.GetLastError()
		if err == win32.ERROR_ENVVAR_NOT_FOUND {
			return "", false
		}
	}

	value = win32.utf16_to_utf8(b[:n], allocator)
	found = true
	return
}

_set_env :: proc(key, value: string) -> bool {
	k := win32.utf8_to_wstring(key)
	v := win32.utf8_to_wstring(value)

	return bool(win32.SetEnvironmentVariableW(k, v))
}

_unset_env :: proc(key: string) -> bool {
	k := win32.utf8_to_wstring(key)
	return bool(win32.SetEnvironmentVariableW(k, nil))
}

_clear_env :: proc() {
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

_environ :: proc(allocator := context.allocator) -> []string {
	envs := win32.GetEnvironmentStringsW()
	if envs == nil {
		return nil
	}
	defer win32.FreeEnvironmentStringsW(envs)

	r := make([dynamic]string, 0, 50, allocator)
	for from, i, p := 0, 0, envs; true; i += 1 {
		c := ([^]u16)(p)[i]
		if c == 0 {
			if i <= from {
				break
			}
			w := ([^]u16)(p)[from:i]
			append(&r, win32.utf16_to_utf8(w, allocator))
			from = i + 1
		}
	}

	return r[:]
}


