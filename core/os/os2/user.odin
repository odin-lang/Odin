package os2

import "core:strings"
import "core:runtime"

user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	found: bool
	#partial switch ODIN_OS {
	case .Windows:
		dir, found = get_env("LocalAppData")
		if found {
			dir = strings.clone_safe(dir, allocator) or_return
		}
	case .Darwin:
		dir, found = get_env("HOME")
		if found {
			dir = strings.concatenate_safe({dir, "/Library/Caches"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir, found = get_env("XDG_CACHE_HOME")
		if found {
			dir, found = get_env("HOME")
			if !found {
				return
			}
			dir = strings.concatenate_safe({dir, "/.cache"}, allocator) or_return
		}
	}
	if !found || dir == "" {
		err = .Invalid_Path
	}
	return
}

user_config_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	found: bool
	#partial switch ODIN_OS {
	case .Windows:
		dir, found = get_env("AppData")
		if found {
			dir = strings.clone_safe(dir, allocator) or_return
		}
	case .Darwin:
		dir, found = get_env("HOME")
		if found {
			dir = strings.concatenate_safe({dir, "/Library/Application Support"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir, found = get_env("XDG_CACHE_HOME")
		if !found {
			dir, found = get_env("HOME")
			if !found {
				return
			}
			dir = strings.concatenate_safe({dir, "/.config"}, allocator) or_return
		}
	}
	if !found || dir == "" {
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
	if v, found := get_env(env); found {
		return v, nil
	}
	return "", .Invalid_Path
}

