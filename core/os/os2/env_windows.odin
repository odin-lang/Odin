#+private
package os2

import win32 "core:sys/windows"
import "base:runtime"

_lookup_env :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	if key == "" {
		return
	}
	TEMP_ALLOCATOR_GUARD()
	wkey, _ := win32_utf8_to_wstring(key, temp_allocator())

	n := win32.GetEnvironmentVariableW(wkey, nil, 0)
	if n == 0 {
		err := win32.GetLastError()
		if err == win32.ERROR_ENVVAR_NOT_FOUND {
			return "", false
		}
		return "", true
	}

	b := make([]u16, n+1, temp_allocator())

	n = win32.GetEnvironmentVariableW(wkey, raw_data(b), u32(len(b)))
	if n == 0 {
		err := win32.GetLastError()
		if err == win32.ERROR_ENVVAR_NOT_FOUND {
			return "", false
		}
		return "", false
	}

	value = win32_utf16_to_utf8(b[:n], allocator) or_else ""
	found = true
	return
}

_set_env :: proc(key, value: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	k, _ := win32_utf8_to_wstring(key,   temp_allocator())
	v, _ := win32_utf8_to_wstring(value, temp_allocator())

	return bool(win32.SetEnvironmentVariableW(k, v))
}

_unset_env :: proc(key: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	k, _ := win32_utf8_to_wstring(key, temp_allocator())
	return bool(win32.SetEnvironmentVariableW(k, nil))
}

_clear_env :: proc() {
	TEMP_ALLOCATOR_GUARD()
	envs := environ(temp_allocator())
	for env in envs {
		for j in 1..<len(env) {
			if env[j] == '=' {
				unset_env(env[0:j])
				break
			}
		}
	}
}

_environ :: proc(allocator: runtime.Allocator) -> []string {
	envs := win32.GetEnvironmentStringsW()
	if envs == nil {
		return nil
	}
	defer win32.FreeEnvironmentStringsW(envs)

	n := 0
	for from, i, p := 0, 0, envs; true; i += 1 {
		c := ([^]u16)(p)[i]
		if c == 0 {
			if i <= from {
				break
			}
			n += 1
			from = i + 1
		}
	}

	r := make([dynamic]string, 0, n, allocator)
	for from, i, p := 0, 0, envs; true; i += 1 {
		c := ([^]u16)(p)[i]
		if c == 0 {
			if i <= from {
				break
			}
			w := ([^]u16)(p)[from:i]
			append(&r, win32_utf16_to_utf8(w, allocator) or_else "")
			from = i + 1
		}
	}

	return r[:]
}


