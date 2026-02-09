#+private
package os2

import win32 "core:sys/windows"
import "base:runtime"

_lookup_env_alloc :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	if key == "" {
		return
	}
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	wkey, _ := win32_utf8_to_wstring(key, temp_allocator)

	n := win32.GetEnvironmentVariableW(wkey, nil, 0)
	if n == 0 {
		err := win32.GetLastError()
		if err == win32.ERROR_ENVVAR_NOT_FOUND {
			return "", false
		}
		return "", true
	}

	b := make([]u16, n+1, temp_allocator)

	n = win32.GetEnvironmentVariableW(wkey, raw_data(b), u32(len(b)))
	if n == 0 {
		err := win32.GetLastError()
		if err == win32.ERROR_ENVVAR_NOT_FOUND {
			return "", false
		}
		return "", false
	}

	value = win32_utf16_to_utf8(string16(b[:n]), allocator) or_else ""
	found = true
	return
}

// This version of `lookup_env` doesn't allocate and instead requires the user to provide a buffer.
// Note that it is limited to environment names and values of 512 utf-16 values each
// due to the necessary utf-8 <> utf-16 conversion.
@(require_results)
_lookup_env_buf :: proc(buf: []u8, key: string) -> (value: string, err: Error) {
	key_buf: [513]u16
	wkey := win32.utf8_to_wstring(key_buf[:], key)
	if wkey == nil {
		return "", .Buffer_Full
	}

	n2 := win32.GetEnvironmentVariableW(wkey, nil, 0)
	if n2 == 0 {
		return "", .Env_Var_Not_Found
	}

	val_buf: [513]u16
	n2 = win32.GetEnvironmentVariableW(wkey, raw_data(val_buf[:]), u32(len(val_buf[:])))
	if n2 == 0 {
		return "", .Env_Var_Not_Found
	} else if int(n2) > len(buf) {
		return "", .Buffer_Full
	}

	value = win32.utf16_to_utf8(buf, val_buf[:n2])

	return value, nil
}
_lookup_env :: proc{_lookup_env_alloc, _lookup_env_buf}

_set_env :: proc(key, value: string) -> Error {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	k := win32_utf8_to_wstring(key,   temp_allocator) or_return
	v := win32_utf8_to_wstring(value, temp_allocator) or_return

	if !win32.SetEnvironmentVariableW(k, v) {
		return _get_platform_error()
	}
	return nil
}

_unset_env :: proc(key: string) -> bool {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	k, _ := win32_utf8_to_wstring(key, temp_allocator)
	return bool(win32.SetEnvironmentVariableW(k, nil))
}

_clear_env :: proc() {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	envs, _ := environ(temp_allocator)
	for env in envs {
		for j in 1..<len(env) {
			if env[j] == '=' {
				unset_env(env[0:j])
				break
			}
		}
	}
}

_environ :: proc(allocator: runtime.Allocator) -> (environ: []string, err: Error) {
	envs := win32.GetEnvironmentStringsW()
	if envs == nil {
		return
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

	r := make([dynamic]string, 0, n, allocator) or_return
	defer if err != nil {
		for e in r {
			delete(e, allocator)
		}
		delete(r)
	}
	for from, i, p := 0, 0, envs; true; i += 1 {
		c := ([^]u16)(p)[i]
		if c == 0 {
			if i <= from {
				break
			}
			w := ([^]u16)(p)[from:i]
			s := win32_utf16_to_utf8(w, allocator) or_return
			append(&r, s)
			from = i + 1
		}
	}

	environ = r[:]
	return
}


