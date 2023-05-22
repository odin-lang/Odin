//+private
package os2

import "core:runtime"
import "core:strings"
import "core:sys/unix"
import "core:intrinsics"

// the environment is a 0 delimited list of <key>=<value> strings

_env_map: map[string]string

// Need to be able to figure out if the environment variable
// is contained in the original environment or not. This also
// serves as a flag to determine if we have built _env_map.
_org_env_begin: uintptr
_org_env_end: uintptr

_lookup_env :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	if _org_env_begin == 0 {
		_build_env_map()
	}

	v: string
	if v, found = _env_map[key]; found {
		value = strings.clone(v, allocator)
	}
	return
}

_set_env :: proc(key, value: string) -> bool {
	if _org_env_begin == 0 {
		_build_env_map()
	}

	// all key values are stored as "key=value\x00"
	kv_size := len(key) + len(value) + 2
	if mapped_val, found := _env_map[key]; found {
		// nothing to do
		if mapped_val == value {
			return true
		}
		delete_key(&_env_map, key)

		// We allocated this key-value. Possibly resize and
		// overwrite the value only. Otherwise, treat as if it
		// wasn't in the environment in the first place.
		if !_is_in_org_env(mapped_val) {
			key_addr, val_addr := _kv_addr_from_mapped_val(mapped_val, key)
			if len(value) > len(mapped_val) {
				key_addr = ([^]u8)(heap_resize(key_addr, kv_size))
				if key_addr == nil {
					return false
				}
				val_addr = &key_addr[len(key) + 1]
			}
			intrinsics.mem_copy_non_overlapping(val_addr, raw_data(value), len(value))
			val_addr[len(value)] = 0

			k := string(key_addr[:len(key)])
			v := string(val_addr[:len(value)])
			_env_map[k] = v
			return true
		}
	}

	key_addr := ([^]u8)(heap_alloc(kv_size));
	if key_addr == nil {
		return false
	}
	intrinsics.mem_copy_non_overlapping(key_addr, raw_data(key), len(key))
	key_addr[len(key)] = '='

	val_slice := key_addr[len(key) + 1:]
	intrinsics.mem_copy_non_overlapping(&val_slice[0], raw_data(value), len(value))
	val_slice[len(value)] = 0

	k := string(key_addr[:len(key)])
	v := string(val_slice[:len(value)])
	_env_map[k] = v

	return true
}

_unset_env :: proc(key: string) -> bool {
	if _org_env_begin == 0 {
		_build_env_map()
	}

	v: string
	found: bool
	if v, found = _env_map[key]; !found {
		return false
	}

	delete_key(&_env_map, key)
	if _is_in_org_env(v) {
		return true
	}

	// if we got this far, the envrionment variable
	// existed and was allocated by us.
	key_addr, _ := _kv_addr_from_mapped_val(v, key)
	heap_free(key_addr)

	return true
}

_clear_env :: proc() {
	for k, _ in _env_map {
		if !_is_in_org_env(k) {
			heap_free(raw_data(k))
		}
	}
	clear(&_env_map)

	// nothing resides in the original environment either
	_org_env_begin = ~uintptr(0)
	_org_env_end = ~uintptr(0)
}

_environ :: proc(allocator: runtime.Allocator) -> []string {
	if _org_env_begin == 0 {
		_build_env_map()
	}
	env := make([]string, len(_env_map), allocator)

	i: int
	for k, v in _env_map {
		env[i] = strings.clone_from(raw_data(k), len(k) + len(v) + 1)
		i += 1
	}

	return env
}

_build_env_map :: proc() {
	// Use heap allocator since context.allocator isn't safe here
	_env_map = make(type_of(_env_map), 64, heap_allocator())
	env := _get_original_env()
	_org_env_begin = uintptr(rawptr(env[0]))
	for i := 0; env[i] != nil; i += 1 {
		// basically strlen
		bytes := ([^]u8)(env[i])
		n: int
		for ; bytes[n] != 0; n += 1 {}
		_org_env_end = uintptr(&bytes[n])
		kv := string(bytes[:n])

		// parse key=value
		k := kv
		switch n = strings.index_byte(k, '='); n {
		case 0: case -1:
			// no value
			_env_map[k] = ""
			continue
		}
		k = k[:n]
		v := kv[len(k) + 1:]
		_env_map[k] = v
	}
}

_get_original_env :: proc() -> [^]cstring {
	// essentially &argv[argc] which should be a nil pointer!
	#no_bounds_check env: [^]cstring = &runtime.args__[len(runtime.args__)]
	assert(env[0] == nil)
	return &env[1]
}

_kv_addr_from_mapped_val :: #force_inline proc(mapped_val: string, key: string) -> ([^]u8, [^]u8) {
	val_addr := raw_data(mapped_val)
	key_addr := ([^]u8)(&val_addr[-(len(key) + 1)])
	return key_addr, val_addr
}

_is_in_org_env :: #force_inline proc(env_data: string) -> bool {
	addr := uintptr(raw_data(env_data))
	return addr >= _org_env_begin && addr < _org_env_end
}
