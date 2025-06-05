#+build !windows
package os2

import "base:runtime"

_user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/Library/Caches", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_CACHE_HOME", "HOME", "/.cache", allocator)
	}
}

_user_config_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/.config", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_CONFIG_HOME", "HOME", "/.config", allocator)
	}
}

_user_state_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/.local/state", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_STATE_HOME", "HOME", "/.local/state", allocator)
	}
}

_user_data_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/.local/share", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_DATA_HOME", "HOME", "/.local/share", allocator)
	}
}

_user_music_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/Music", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_MUSIC_DIR", "HOME", "/Music", allocator)
	}
}

_user_desktop_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/Desktop", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_DESKTOP_DIR", "HOME", "/Desktop", allocator)
	}
}

_user_documents_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/Documents", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_DOCUMENTS_DIR", "HOME", "/Documents", allocator)
	}
}

_user_downloads_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/Downloads", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_DOWNLOAD_DIR", "HOME", "/Downloads", allocator)
	}
}

_user_pictures_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/Pictures", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_PICTURES_DIR", "HOME", "/Pictures", allocator)
	}
}

_user_public_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/Public", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_PUBLIC_DIR", "HOME", "/Public", allocator)
	}
}

_user_videos_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "HOME", "/Movies", allocator)
	case: // All other UNIX systems
		return _xdg_lookup("XDG_VIDEOS_DIR", "HOME", "/Videos", allocator)
	}
}

_user_home_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	if v := get_env("HOME", allocator); v != "" {
		return v, nil
	}
	return "", .Invalid_Path
}

_xdg_lookup :: proc(xdg_env, fallback_env: string, fallback_suffix: string, allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator  := TEMP_ALLOCATOR_GUARD({ allocator })

	if xdg_env == "" { // Darwin doesn't have XDG paths.
		dir = get_env(fallback_env, temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		return concatenate({dir, fallback_suffix}, allocator)
	} else {
		dir = get_env(xdg_env, allocator)
		if dir == "" {
			dir = get_env(fallback_env, temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, fallback_suffix}, allocator) or_return
		}
		return
	}
}