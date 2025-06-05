#+build !windows
package os2

import "base:runtime"

_user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/Library/Caches"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_CACHE_HOME", allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/.cache"}, allocator) or_return
		}
	}
	return
}

_user_config_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/.config"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_CONFIG_HOME", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/.config"}, allocator) or_return
		}
	}
	return
}

_user_state_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/.local/state"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_STATE_HOME", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/.local/state"}, allocator) or_return
		}
	}
	return
}

_user_data_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/.local/share"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_DATA_HOME", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/.local/share"}, allocator) or_return
		}
	}
	return
}

_user_music_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/Music"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_MUSIC_DIR", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/Music"}, allocator) or_return
		}
	}
	return
}

_user_desktop_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/Desktop"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_DESKTOP_DIR", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/Desktop"}, allocator) or_return
		}
	}
	return
}

_user_documents_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/Documents"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_DOCUMENTS_DIR", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/Documents"}, allocator) or_return
		}
	}
	return
}

_user_downloads_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/Downloads"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_DOWNLOAD_DIR", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/Downloads"}, allocator) or_return
		}
	}
	return
}

_user_pictures_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/Pictures"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_PICTURES_DIR", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/Pictures"}, allocator) or_return
		}
	}
	return
}

_user_public_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/Public"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_PUBLIC_DIR", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/Public"}, allocator) or_return
		}
	}
	return
}

_user_videos_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	#partial switch ODIN_OS {
	case .Darwin:
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			return "", .Invalid_Path
		}
		dir = concatenate({dir, "/Movies"}, allocator) or_return
	case: // All other UNIX systems
		dir = get_env("XDG_VIDEOS_DIR", temp_allocator)
		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				return "", .Invalid_Path
			}
			dir = concatenate({dir, "/Videos"}, allocator) or_return
		}
	}
	return
}

_user_home_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	if v := get_env("HOME", allocator); v != "" {
		return v, nil
	}
	return "", .Invalid_Path
}