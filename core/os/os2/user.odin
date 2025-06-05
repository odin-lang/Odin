package os2

import "base:runtime"
@(require) import win32 "core:sys/windows"

@(require_results)
user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Windows:
		guid := win32.FOLDERID_LocalAppData
		return _get_known_folder_path(&guid, allocator)
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir != "" {
			dir = concatenate({dir, "/Library/Caches"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME", allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
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
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Windows:
		guid := win32.FOLDERID_RoamingAppData
		return _get_known_folder_path(&guid, allocator)
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir != "" {
			dir = concatenate({dir, "/.config"}, allocator) or_return
		}
	case: // All other UNIX systems
		dir = get_env("XDG_CONFIG_HOME", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
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
	#partial switch ODIN_OS {
	case .Windows:
		guid := win32.FOLDERID_Profile
		return _get_known_folder_path(&guid, allocator)
	case:
		if v := get_env("HOME", allocator); v != "" {
			return v, nil
		}

	}
	return "", .Invalid_Path
}