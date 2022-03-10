//+private
package os2

//import "core:runtime"
//import "core:mem"
import win32 "core:sys/windows"

_get_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	if key == "" {
		return
	}
	wkey := win32.utf8_to_wstring(key)

	// https://docs.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-getenvironmentvariablew
	buf_len := win32.GetEnvironmentVariableW(wkey, nil, 0)
	if buf_len == 0 {
		return
	}
	buf := make([dynamic]u16, buf_len, context.temp_allocator)
	n := win32.GetEnvironmentVariableW(wkey, raw_data(buf), buf_len)
	if n == 0 {
		if win32.GetLastError() == win32.ERROR_ENVVAR_NOT_FOUND {
			return "", false
		}
		value = ""
		found = true
		return
	}

	value = win32.utf16_to_utf8(buf[:n], allocator)
	found = true
	return
}

_set_env :: proc(key, value: string) -> bool {
	k := win32.utf8_to_wstring(key)
	v := win32.utf8_to_wstring(value)

	// https://docs.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-setenvironmentvariablew
	return bool(win32.SetEnvironmentVariableW(k, v))
}

_unset_env :: proc(key: string) -> bool {
	k := win32.utf8_to_wstring(key)

	// https://docs.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-setenvironmentvariablew
	return bool(win32.SetEnvironmentVariableW(k, nil))
}

_clear_env :: proc() {
	envs := environ(context.temp_allocator)
	for env in envs {
		#no_bounds_check for j in 1..<len(env) {
			if env[j] == '=' {
				unset_env(env[0:j])
				break
			}
		}
	}
}

_environ :: proc(allocator := context.allocator) -> []string {
	envs := ([^]u16)(win32.GetEnvironmentStringsW())
	if envs == nil {
		return nil
	}
	defer win32.FreeEnvironmentStringsW(envs)

	length := 0
	n := 0
	count_loop: for {
		if envs[length] == 0 {
			n += 1
			if envs[length+1] == 0 {
				break count_loop
			}
		}

		length += 1
	}

	r := make([dynamic]string, 0, n, allocator)
	for offset, i := 0, 0; i < length && len(r) < n; i += 1 {
		c := envs[i]
		if c == 0 {
			wstr := envs[offset:i]
			append(&r, win32.utf16_to_utf8(wstr, allocator))
			i += 1
			offset = i
		}
	}

	return r[:]
}


