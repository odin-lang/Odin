#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

import "core:strings"
import "core:sys/posix"

_lookup_env :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	if key == "" {
		return
	}

	TEMP_ALLOCATOR_GUARD()

	ckey := strings.clone_to_cstring(key, temp_allocator())
	cval := posix.getenv(ckey)
	if cval == nil {
		return
	}

	found = true
	value = strings.clone(string(cval), allocator) // NOTE(laytan): what if allocation fails?

	return
}

_set_env :: proc(key, value: string) -> (ok: bool) {
	TEMP_ALLOCATOR_GUARD()

	ckey := strings.clone_to_cstring(key, temp_allocator())
	cval := strings.clone_to_cstring(key, temp_allocator())

	ok = posix.setenv(ckey, cval, true) == .OK
	return
}

_unset_env :: proc(key: string) -> (ok: bool) {
	TEMP_ALLOCATOR_GUARD()

	ckey := strings.clone_to_cstring(key, temp_allocator())

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

_environ :: proc(allocator: runtime.Allocator) -> (environ: []string) {
	n := 0	
	for entry := posix.environ[0]; entry != nil; n, entry = n+1, posix.environ[n] {}

	err: runtime.Allocator_Error
	if environ, err = make([]string, n, allocator); err != nil {
		// NOTE(laytan): is the environment empty or did allocation fail, how does the user know?
		return
	}

	for i, entry := 0, posix.environ[0]; entry != nil; i, entry = i+1, posix.environ[i] {
		if environ[i], err = strings.clone(string(entry), allocator); err != nil {
			// NOTE(laytan): is the entire environment returned or did allocation fail, how does the user know?
			return
		}
	}

	return
}


