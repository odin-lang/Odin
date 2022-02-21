package os2

import "core:strings"

user_cache_dir :: proc(allocator := context.allocator) -> (dir: string, is_defined: bool) {
	#partial switch ODIN_OS {
	case .Windows:
		dir = get_env("LocalAppData") or_return
		if dir != "" {
			dir = strings.clone(dir, allocator)
		}
	case .Darwin:
		dir = get_env("HOME") or_return
		if dir != "" {
			dir = strings.concatenate({dir, "/Library/Caches"}, allocator)
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME") or_return
		if dir == "" {
			dir = get_env("HOME") or_return
			if dir == "" {
				return
			}
			dir = strings.concatenate({dir, "/.cache"}, allocator)
		}
	}
	is_defined = dir != ""
	return
}

user_config_dir :: proc(allocator := context.allocator) -> (dir: string, is_defined: bool) {
	#partial switch ODIN_OS {
	case .Windows:
		dir = get_env("AppData") or_return
		if dir != "" {
			dir = strings.clone(dir, allocator)
		}
	case .Darwin:
		dir = get_env("HOME") or_return
		if dir != "" {
			dir = strings.concatenate({dir, "/Library/Application Support"}, allocator)
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME") or_return
		if dir == "" {
			dir = get_env("HOME") or_return
			if dir == "" {
				return
			}
			dir = strings.concatenate({dir, "/.config"}, allocator)
		}
	}
	is_defined = dir != ""
	return
}

user_home_dir :: proc() -> (dir: string, is_defined: bool) {
	env := "HOME"
	#partial switch ODIN_OS {
	case .Windows:
		env = "USERPROFILE"
	}
	v := get_env(env) or_return
	return v, true
}

