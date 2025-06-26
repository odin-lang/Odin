#+build !windows
package os2

import "base:runtime"
import "core:encoding/ini"
import "core:strings"

_user_cache_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Library/Caches", allocator)
	case: // Unix
		return _xdg_lookup("XDG_CACHE_HOME", "/.cache", allocator)
	}
}

_user_config_dir :: proc(allocator: runtime.Allocator, _roaming: bool) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Library/Application Support", allocator)
	case: // Unix
		return _xdg_lookup("XDG_CONFIG_HOME", "/.config", allocator)
	}
}

_user_state_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Library/Application Support", allocator)
	case: // Unix
		return _xdg_lookup("XDG_STATE_HOME", "/.local/state", allocator)
	}
}

_user_log_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Library/Logs", allocator)
	case: // Unix
		return _xdg_lookup("XDG_STATE_HOME", "/.local/state", allocator)
	}
}

_user_data_dir :: proc(allocator: runtime.Allocator, _roaming: bool) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Library/Application Support", allocator)
	case: // Unix
		return _xdg_lookup("XDG_DATA_HOME", "/.local/share", allocator)
	}
}

_user_music_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Music", allocator)
	case: // Unix
		return _xdg_lookup("XDG_MUSIC_DIR", "/Music", allocator)
	}
}

_user_desktop_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Desktop", allocator)
	case: // Unix
		return _xdg_lookup("XDG_DESKTOP_DIR", "/Desktop", allocator)
	}
}

_user_documents_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Documents", allocator)
	case: // Unix
		return _xdg_lookup("XDG_DOCUMENTS_DIR", "/Documents", allocator)
	}
}

_user_downloads_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Downloads", allocator)
	case: // Unix
		return _xdg_lookup("XDG_DOWNLOAD_DIR", "/Downloads", allocator)
	}
}

_user_pictures_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Pictures", allocator)
	case: // Unix
		return _xdg_lookup("XDG_PICTURES_DIR", "/Pictures", allocator)
	}
}

_user_public_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Public", allocator)
	case: // Unix
		return _xdg_lookup("XDG_PUBLICSHARE_DIR", "/Public", allocator)
	}
}

_user_videos_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	#partial switch ODIN_OS {
	case .Darwin:
		return _xdg_lookup("", "/Movies", allocator)
	case: // Unix
		return _xdg_lookup("XDG_VIDEOS_DIR", "/Videos", allocator)
	}
}

_user_home_dir :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	if v := get_env("HOME", allocator); v != "" {
		return v, nil
	}
	err = .No_HOME_Variable
	return
}

_xdg_lookup :: proc(xdg_key: string, fallback_suffix: string, allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator  := TEMP_ALLOCATOR_GUARD({ allocator })

	if xdg_key == "" { // Darwin doesn't have XDG paths.
		dir = get_env("HOME", temp_allocator)
		if dir == "" {
			err = .No_HOME_Variable
			return
		}
		return concatenate({dir, fallback_suffix}, allocator)
	} else {
		if strings.ends_with(xdg_key, "_DIR") {
			dir = _xdg_user_dirs_lookup(xdg_key, allocator) or_return
		} else {
			dir = get_env(xdg_key, allocator)
		}

		if dir == "" {
			dir = get_env("HOME", temp_allocator)
			if dir == "" {
				err = .No_HOME_Variable
				return
			}
			dir = concatenate({dir, fallback_suffix}, allocator) or_return
		}
		return
	}
}

// If `<config-dir>/user-dirs.dirs` doesn't exist, or `xdg_key` can't be found there: returns `""`
_xdg_user_dirs_lookup :: proc(xdg_key: string, allocator: runtime.Allocator) -> (dir: string, err: Error) {
	temp_allocator  := TEMP_ALLOCATOR_GUARD({ allocator })
	config_dir      := user_config_dir(temp_allocator) or_return
	user_dirs_path  := concatenate({config_dir, "/user-dirs.dirs"}, temp_allocator) or_return
	content         := read_entire_file(user_dirs_path, temp_allocator) or_return

	it := ini.Iterator{
		section = "",
		_src    = string(content),
		options = ini.Options{
			comment        = "#",
			key_lower_case = false,
		},
	}

	for k, v in ini.iterate(&it) {
		if k == xdg_key {
			return replace_environment_placeholders(v, allocator), nil
		}
	}
	return
}