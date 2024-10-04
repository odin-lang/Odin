package os2

import "base:runtime"

@(require_results)
user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	TEMP_ALLOCATOR_GUARD()

	#partial switch ODIN_OS {
	case .Windows:
		dir = get_env("LocalAppData", temp_allocator())
		if dir != "" {
			dir = clone_string(dir, allocator) or_return
		}
	case .Darwin:
		dir = get_env("HOME", temp_allocator())
		if dir != "" {
			dir = concatenate({dir, "/Library/Caches"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME", allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator())
			if dir == "" {
				return
			}
			dir = concatenate({dir, "/.cache"}, allocator) or_return
		}
	}
	if dir == "" {
		err = .Invalid_Path
	}
	return
}

@(require_results)
user_config_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	TEMP_ALLOCATOR_GUARD()

	#partial switch ODIN_OS {
	case .Windows:
		dir = get_env("AppData", temp_allocator())
		if dir != "" {
			dir = clone_string(dir, allocator) or_return
		}
	case .Darwin:
		dir = get_env("HOME", temp_allocator())
		if dir != "" {
			dir = concatenate({dir, "/.config"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CONFIG_HOME", allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator())
			if dir == "" {
				return
			}
			dir = concatenate({dir, "/.config"}, allocator) or_return
		}
	}
	if dir == "" {
		err = .Invalid_Path
	}
	return
}

@(require_results)
user_home_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	env := "HOME"
	#partial switch ODIN_OS {
	case .Windows:
		env = "USERPROFILE"
	}
	if v := get_env(env, allocator); v != "" {
		return v, nil
	}
	return "", .Invalid_Path
}

