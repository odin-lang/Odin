#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

import "core:strings"
import "core:sys/posix"

_lookup_env_alloc :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	if key == "" {
		return
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	ckey := strings.clone_to_cstring(key, temp_allocator)
	cval := posix.getenv(ckey)
	if cval == nil {
		return
	}

	found = true
	value = strings.clone(string(cval), allocator) // NOTE(laytan): what if allocation fails?

	return
}

_lookup_env_buf :: proc(buf: []u8, key: string) -> (value: string, error: Error) {
	if key == "" {
		return
	}

	if len(key) + 1 > len(buf) {
		return "", .Buffer_Full
	} else {
		copy(buf, key)
	}

	cval := posix.getenv(cstring(raw_data(buf)))
	if cval == nil {
		return
	}

	if value = string(cval); value == "" {
		return "", .Env_Var_Not_Found
	} else {
		if len(value) > len(buf) {
			return "", .Buffer_Full
		} else {
			copy(buf, value)
			return string(buf[:len(value)]), nil
		}
	}
}

_lookup_env :: proc{_lookup_env_alloc, _lookup_env_buf}

_set_env :: proc(key, value: string) -> (err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	ckey := strings.clone_to_cstring(key, temp_allocator) or_return
	cval := strings.clone_to_cstring(value, temp_allocator) or_return

	if posix.setenv(ckey, cval, true) != nil {
		err = _get_platform_error_from_errno()
	}
	return
}

_unset_env :: proc(key: string) -> (ok: bool) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	ckey := strings.clone_to_cstring(key, temp_allocator)

	ok = posix.unsetenv(ckey) == .OK
	return
}

// NOTE(laytan): clearing the env is weird, why would you ever do that?

_clear_env :: proc() {
	for i, entry := 0, posix.environ[0]; entry != nil; i, entry = i+1, posix.environ[i] {
		key := strings.truncate_to_byte(string(entry), '=')
		_unset_env(key)
	}
}

_environ :: proc(allocator: runtime.Allocator) -> (environ: []string, err: Error) {
	n := 0
	for entry := posix.environ[0]; entry != nil; n, entry = n+1, posix.environ[n] {}

	r := make([dynamic]string, 0, n, allocator) or_return
	defer if err != nil {
		for e in r {
			delete(e, allocator)
		}
		delete(r)
	}

	for i, entry := 0, posix.environ[0]; entry != nil; i, entry = i+1, posix.environ[i] {
		append(&r, strings.clone(string(entry), allocator) or_return)
	}

	environ = r[:]
	return
}


