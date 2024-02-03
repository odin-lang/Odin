package os2

import "core:strings"
import "base:runtime"

user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Windows:
		dir = get_env("LocalAppData", allocator)
		if dir != "" {
			dir = strings.clone(dir, allocator) or_return
		}
	case .Darwin:
		dir = get_env("HOME", allocator)
		if dir != "" {
			dir = strings.concatenate({dir, "/Library/Caches"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME", allocator)
		if dir == "" {
			dir = get_env("HOME", allocator)
			if dir == "" {
				return
			}
			dir = strings.concatenate({dir, "/.cache"}, allocator) or_return
		}
	}
	if dir == "" {
		err = .Invalid_Path
	}
	return
}

user_config_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Windows:
		dir = get_env("AppData", allocator)
		if dir != "" {
			dir = strings.clone(dir, allocator) or_return
		}
	case .Darwin:
		dir = get_env("HOME", allocator)
		if dir != "" {
			dir = strings.concatenate({dir, "/Library/Application Support"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME", allocator)
		if dir == "" {
			dir = get_env("HOME", allocator)
			if dir == "" {
				return
			}
			dir = strings.concatenate({dir, "/.config"}, allocator) or_return
		}
	}
	if dir == "" {
		err = .Invalid_Path
	}
	return
}

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

