#+build !windows
package os2

import "base:runtime"
import "core:strings"
import "core:sys/posix"
import "core:fmt" //remove

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

	config_dir := user_config_dir(temp_allocator) or_return

	user_dirs_path := concatenate({config_dir, "/user-dirs.dirs"}, temp_allocator) or_return
	user_dirs_content_bytes, read_err := read_entire_file(user_dirs_path, temp_allocator)
	if read_err == .Not_Exist {
		return
	} else if read_err != nil {
		err = read_err
		return
	}
	user_dirs_content := string(user_dirs_content_bytes)

	lines := strings.split_lines(user_dirs_content, temp_allocator) or_return

	home_env := get_env("HOME", temp_allocator)
	if home_env == "" {
		err = .No_HOME_Variable
		return
	}

	for line in lines {
		ss := strings.split_n(line, "=", 2, temp_allocator) or_return
		(len(ss) == 2) or_continue
		sl := strings.trim_space(ss[0])
		sr := ss[1]

		(sl == xdg_key) or_continue

		(len(sr) > 2) or_continue

		lq := strings.index_byte(sr, '"')
		(lq != -1) or_continue
		rq := strings.index_byte(sr[lq+1:], '"') + lq+1
		(rq != -1) or_continue

		sr = sr[lq+1:rq]

		we: posix.wordexp_t
		we_err := posix.wordexp(strings.clone_to_cstring(sr, temp_allocator), &we, nil)
		(we_err == nil) or_continue
		defer posix.wordfree(&we)

		(we.we_wordc == 1) or_continue

		dir = strings.clone_from_cstring(we.we_wordv[0], allocator) or_return
		return
	}
	return
}