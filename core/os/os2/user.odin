package os2

import "core:strings"
import "core:runtime"

user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Windows:
		dir = get_env("LocalAppData")
		if dir != "" {
			dir = strings.clone_safe(dir, allocator) or_return
		}
	case .Darwin:
		dir = get_env("HOME")
		if dir != "" {
			dir = strings.concatenate_safe({dir, "/Library/Caches"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME")
		if dir == "" {
			dir = get_env("HOME")
			if dir == "" {
				return
			}
			dir = strings.concatenate_safe({dir, "/.cache"}, allocator) or_return
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
		dir = get_env("AppData")
		if dir != "" {
			dir = strings.clone_safe(dir, allocator) or_return
		}
	case .Darwin:
		dir = get_env("HOME")
		if dir != "" {
			dir = strings.concatenate_safe({dir, "/Library/Application Support"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME")
		if dir == "" {
			dir = get_env("HOME")
			if dir == "" {
				return
			}
			dir = strings.concatenate_safe({dir, "/.config"}, allocator) or_return
		}
	}
	if dir == "" {
		err = .Invalid_Path
	}
	return
}

user_home_dir :: proc() -> (dir: string, err: Error) {
	env := "HOME"
	#partial switch ODIN_OS {
	case .Windows:
		env = "USERPROFILE"
	}
	if v := get_env(env); v != "" {
		return v, nil
	}
	return "", .Invalid_Path
}

