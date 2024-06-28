//+private
package os2

import "base:runtime"
import "base:intrinsics"

import "core:sync"
import "core:slice"
import "core:strings"

// TODO: IF NO_CRT:
//         Override the libc environment functions' weak linkage to
//         allow us to interact with 3rd party code that DOES link
//         to libc. Otherwise, our environment can be out of sync.
//       ELSE:
//         Just use the libc.

NOT_FOUND :: -1

// the environment is a 0 delimited list of <key>=<value> strings
_env: [dynamic]string

_env_mutex: sync.Mutex

// We need to be able to figure out if the environment variable
// is contained in the original environment or not. This also
// serves as a flag to determine if we have built _env.
_org_env_begin: uintptr
_org_env_end:   uintptr

// Returns value + index location into _env
// or -1 if not found
_lookup :: proc(key: string) -> (value: string, idx: int) {
	sync.mutex_lock(&_env_mutex)
	defer sync.mutex_unlock(&_env_mutex)

	for entry, i in _env {
		if k, v := _kv_from_entry(entry); k == key {
			return v, i
		}
	}
	return "", -1
}

_lookup_env :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	if _org_env_begin == 0 {
		_build_env()
	}

	if v, idx := _lookup(key); idx != -1 {
		found = true
		value, _ = clone_string(v, allocator)
	}
	return
}

_set_env :: proc(key, v_new: string) -> bool {
	if _org_env_begin == 0 {
		_build_env()
	}

	// all key values are stored as "key=value\x00"
	kv_size := len(key) + len(v_new) + 2
	if v_curr, idx := _lookup(key); idx != NOT_FOUND {
		if v_curr == v_new {
			return true
		}
		sync.mutex_lock(&_env_mutex)
		defer sync.mutex_unlock(&_env_mutex)

		unordered_remove(&_env, idx)

		if !_is_in_org_env(v_curr) {
			// We allocated this key-value. Possibly resize and
			// overwrite the value only. Otherwise, treat as if it
			// wasn't in the environment in the first place.
			k_addr, v_addr := _kv_addr_from_val(v_curr, key)
			if len(v_new) > len(v_curr) {
				k_addr = ([^]u8)(heap_resize(k_addr, kv_size))
				if k_addr == nil {
					return false
				}
				v_addr = &k_addr[len(key) + 1]
			}
			intrinsics.mem_copy_non_overlapping(v_addr, raw_data(v_new), len(v_new))
			v_addr[len(v_new)] = 0

			append(&_env, string(k_addr[:kv_size]))
			return true
		}
	}

	k_addr := ([^]u8)(heap_alloc(kv_size))
	if k_addr == nil {
		return false
	}
	intrinsics.mem_copy_non_overlapping(k_addr, raw_data(key), len(key))
	k_addr[len(key)] = '='

	val_slice := k_addr[len(key) + 1:]
	intrinsics.mem_copy_non_overlapping(&val_slice[0], raw_data(v_new), len(v_new))
	val_slice[len(v_new)] = 0

	sync.mutex_lock(&_env_mutex)
	append(&_env, string(k_addr[:kv_size - 1]))
	sync.mutex_unlock(&_env_mutex)
	return true
}

_unset_env :: proc(key: string) -> bool {
	if _org_env_begin == 0 {
		_build_env()
	}

	v: string
	i: int
	if v, i = _lookup(key); i == -1 {
		return false
	}

	sync.mutex_lock(&_env_mutex)
	unordered_remove(&_env, i)
	sync.mutex_unlock(&_env_mutex)

	if _is_in_org_env(v) {
		return true
	}

	// if we got this far, the envrionment variable
	// existed AND was allocated by us.
	k_addr, _ := _kv_addr_from_val(v, key)
	heap_free(k_addr)
	return true
}

_clear_env :: proc() {
	sync.mutex_lock(&_env_mutex)
	defer sync.mutex_unlock(&_env_mutex)

	for kv in _env {
		if !_is_in_org_env(kv) {
			heap_free(raw_data(kv))
		}
	}
	clear(&_env)

	// nothing resides in the original environment either
	_org_env_begin = ~uintptr(0)
	_org_env_end = ~uintptr(0)
}

_environ :: proc(allocator: runtime.Allocator) -> []string {
	if _org_env_begin == 0 {
		_build_env()
	}
	env := make([]string, len(_env), allocator)

	sync.mutex_lock(&_env_mutex)
	defer sync.mutex_unlock(&_env_mutex)
	for entry, i in _env {
		env[i], _ = clone_string(entry, allocator)
	}
	return env
}

// The entire environment is stored as 0 terminated strings,
// so there is no need to clone/free individual variables
export_cstring_environment :: proc(allocator: runtime.Allocator) -> []cstring {
	if _org_env_begin == 0 {
		// The environment has not been modified, so we can just
		// send the original environment
		org_env := _get_original_env()
		n: int
		for ; org_env[n] != nil; n += 1 {}
		return slice.clone(org_env[:n + 1], allocator)
	}

	// NOTE: already terminated by nil pointer via + 1
	env := make([]cstring, len(_env) + 1, allocator)

	sync.mutex_lock(&_env_mutex)
	defer sync.mutex_unlock(&_env_mutex)
	for entry, i in _env {
		env[i] = cstring(raw_data(entry))
	}
	return env
}

_build_env :: proc() {
	sync.mutex_lock(&_env_mutex)
	defer sync.mutex_unlock(&_env_mutex)
	if _org_env_begin != 0 {
		return
	}

	_env = make(type_of(_env), heap_allocator())
	cstring_env := _get_original_env()
	_org_env_begin = uintptr(rawptr(cstring_env[0]))
	for i := 0; cstring_env[i] != nil; i += 1 {
		bytes := ([^]u8)(cstring_env[i])
		n := len(cstring_env[i])
		_org_env_end = uintptr(&bytes[n])
		append(&_env, string(bytes[:n]))
	}
}

_get_original_env :: #force_inline proc() -> [^]cstring {
	// essentially &argv[argc] which should be a nil pointer!
	#no_bounds_check env: [^]cstring = &runtime.args__[len(runtime.args__)]
	assert(env[0] == nil)
	return &env[1]
}

_kv_from_entry :: #force_inline proc(entry: string) -> (k, v: string) {
	eq_idx := strings.index_byte(entry, '=')
	if eq_idx == -1 {
		return entry, ""
	}
	return entry[:eq_idx], entry[eq_idx + 1:]
}

_kv_addr_from_val :: #force_inline proc(val: string, key: string) -> ([^]u8, [^]u8) {
	v_addr := raw_data(val)
	k_addr := ([^]u8)(&v_addr[-(len(key) + 1)])
	return k_addr, v_addr
}

_is_in_org_env :: #force_inline proc(env_data: string) -> bool {
	addr := uintptr(raw_data(env_data))
	return addr >= _org_env_begin && addr < _org_env_end
}
