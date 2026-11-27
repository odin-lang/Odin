#+private
package os

import "base:runtime"

import "core:strings"
import "core:sync"
import "core:sys/wasm/wasi"

g_env: map[string]string
g_env_buf: []byte
g_env_mutex: sync.RW_Mutex
g_env_error: Error
g_env_built: bool

build_env :: proc() -> (err: Error) {
	if g_env_built || g_env_error != nil {
		return g_env_error
	}

	sync.guard(&g_env_mutex)

	if g_env_built || g_env_error != nil {
		return g_env_error
	}

	defer if err != nil {
		g_env_error = err
	}

	num_envs, size_of_envs, _err := wasi.environ_sizes_get()
	if _err != nil {
		return _get_platform_error(_err)
	}

	g_env = make(map[string]string, num_envs, file_allocator()) or_return
	defer if err != nil {
		delete(g_env)
		g_env = nil
	}

	g_env_buf = make([]byte, size_of_envs, file_allocator()) or_return
	defer if err != nil {
		delete(g_env_buf, file_allocator())
		g_env_buf = nil
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	envs := make([]cstring, num_envs, temp_allocator) or_return

	_err = wasi.environ_get(raw_data(envs), raw_data(g_env_buf))
	if _err != nil {
		return _get_platform_error(_err)
	}

	for env in envs {
		key, _, value := strings.partition(string(env), "=")
		g_env[key] = value
	}

	g_env_built = true
	return
}

delete_string_if_not_original :: proc(str: string) {
	start := uintptr(raw_data(g_env_buf))
	end   := start + uintptr(len(g_env_buf))
	ptr   := uintptr(raw_data(str))
	if ptr < start || ptr >= end {
		delete(str, file_allocator())
	}
}

@(require_results)
_lookup_env_alloc :: proc(key: string, allocator: runtime.Allocator) -> (value: string, found: bool) {
	if err := build_env(); err != nil {
		return
	}

	sync.shared_guard(&g_env_mutex)

	value = g_env[key] or_return
	value, _ = clone_string(value, allocator)
	return
}

_lookup_env_buf :: proc(buf: []u8, key: string) -> (value: string, error: Error) {
	if key == "" {
		return "", .Env_Var_Not_Found
	}

	if len(key) + 1 > len(buf) {
		return "", .Buffer_Full
	} else {
		copy(buf, key)
		buf[len(key)] = 0
	}

	build_env() or_return

	sync.shared_guard(&g_env_mutex)

	val, ok := g_env[key]

	if !ok {
		return "", .Env_Var_Not_Found
	} else {
		if len(val) > len(buf) {
			return "", .Buffer_Full
		} else {
			copy(buf, val)
			return string(buf[:len(val)]), nil
		}
	}
}
_lookup_env :: proc{_lookup_env_alloc, _lookup_env_buf}

@(require_results)
_set_env :: proc(key, value: string) -> (err: Error) {
	build_env() or_return

	sync.guard(&g_env_mutex)

	cloned_value := clone_string(value, file_allocator()) or_return
	defer if err != nil {
		delete(cloned_value, file_allocator())
	}

	key_ptr, value_ptr, just_inserted := map_entry(&g_env, key) or_return
	if just_inserted {
		cloned_key, key_err := clone_string(key, file_allocator())
		if key_err != nil {
			delete_key(&g_env, key)
			return key_err
		}
		key_ptr^ = cloned_key
	} else {
		delete_string_if_not_original(value_ptr^)
	}
	value_ptr^ = cloned_value
	return
}

@(require_results)
_unset_env :: proc(key: string) -> bool {
	if err := build_env(); err != nil {
		return false
	}

	sync.guard(&g_env_mutex)

	dkey, dval := delete_key(&g_env, key)
	delete_string_if_not_original(dkey)
	delete_string_if_not_original(dval)
	return true
}

_clear_env :: proc() {
	sync.guard(&g_env_mutex)

	for k, v in g_env {
		delete_string_if_not_original(k)
		delete_string_if_not_original(v)
	}

	delete(g_env_buf, file_allocator())
	g_env_buf = {}

	clear(&g_env)

	g_env_built = true
}

@(require_results)
_environ :: proc(allocator: runtime.Allocator) -> (environ: []string, err: Error) {
	build_env() or_return

	sync.shared_guard(&g_env_mutex)

	envs := make([dynamic]string, 0, len(g_env), allocator) or_return
	defer if err != nil {
		for env in envs {
			delete(env, allocator)
		}
		delete(envs)
	}

	for k, v in g_env {
		append(&envs, concatenate({k, "=", v}, allocator) or_return)
	}

	environ = envs[:]
	return
}
