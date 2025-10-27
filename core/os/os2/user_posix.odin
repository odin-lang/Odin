#+build !windows
package os2

import "base:intrinsics"
import "base:runtime"
import "core:strings"
import "core:strconv"

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

	it := Iterator{
		section = "",
		_src    = string(content),
	}

	for k, v in iterate(&it) {
		if k == xdg_key {
			return replace_environment_placeholders(v, allocator), nil
		}
	}
	return
}

// Vendored + stripped version of `core:encoding/ini` with read-only support to avoid import cycle

@(private)
Iterator :: struct {
	section: string,
	_src:    string,
}

// Returns the raw `key` and `value`. `ok` will be false if no more key=value pairs cannot be found.
// They key and value may be quoted, which may require the use of `strconv.unquote_string`.
@(private)
iterate :: proc(it: ^Iterator) -> (key, value: string, ok: bool) {
	for line_ in strings.split_lines_iterator(&it._src) {
		line := strings.trim_space(line_)

		if len(line) == 0 {
			continue
		}

		if line[0] == '[' {
			end_idx := strings.index_byte(line, ']')
			if end_idx < 0 {
				end_idx = len(line)
			}
			it.section = line[1:end_idx]
			continue
		}

		if strings.has_prefix(line, "#") {
			continue
		}

		equal := strings.index(line, " =") // check for things keys that `ctrl+= = zoom_in`
		quote := strings.index_byte(line, '"')
		if equal < 0 || quote > 0 && quote < equal {
			equal = strings.index_byte(line, '=')
			if equal < 0 {
				continue
			}
		} else {
			equal += 1
		}

		key = strings.trim_space(line[:equal])
		value = strings.trim_space(line[equal+1:])
		ok = true
		return
	}

	it.section = ""
	return
}

@(private)
Map :: distinct map[string]map[string]string

@(private)
load_map_from_string :: proc(src: string, allocator: runtime.Allocator) -> (m: Map, err: runtime.Allocator_Error) {
	unquote :: proc(val: string) -> (string, runtime.Allocator_Error) {
		if len(val) > 0 && (val[0] == '"' || val[0] == '\'') {
			v, allocated, ok := strconv.unquote_string(val)
			if !ok {
				return strings.clone(val)
			}
			if allocated {
				return v, nil
			}
			return strings.clone(v), nil
		}
		return strings.clone(val)
	}

	context.allocator = allocator

	it := Iterator{
		section = "",
		_src = src,
	}

	for key, value in iterate(&it) {
		section := it.section
		if section not_in m {
			section = strings.clone(section) or_return
			m[section] = {}
		}

		// store key-value pair
		pairs         := &m[section]
		new_key       := unquote(key) or_return
		pairs[new_key] = unquote(value) or_return
	}
	return
}

@(private)
load_map_from_path :: proc(path: string, allocator: runtime.Allocator) -> (m: Map, err: runtime.Allocator_Error, ok: bool) {
	data, data_err := read_entire_file(path, allocator)
	defer delete(data, allocator)
	if data_err != nil {
		return
	}
	m, err = load_map_from_string(string(data), allocator)
	ok = err == nil
	defer if !ok {
		delete_map(m)
	}
	return
}

@(private)
delete_map :: proc(m: Map) {
	allocator := m.allocator
	for section, pairs in m {
		for key, value in pairs {
			delete(key, allocator)
			delete(value, allocator)
		}
		delete(section)
		delete(pairs)
	}
	delete(m)
}