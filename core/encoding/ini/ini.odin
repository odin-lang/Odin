package encoding_ini

import "base:runtime"
import "base:intrinsics"
import "core:strings"
import "core:strconv"
import "core:io"
import "core:os"
import "core:fmt"
_ :: fmt

Options :: struct {
	comment: string,
	key_lower_case: bool,
}

DEFAULT_OPTIONS :: Options {
	comment = ";",
	key_lower_case = false,
}

Iterator :: struct {
	section: string,
	_src:    string,
	options: Options,
}

iterator_from_string :: proc(src: string, options := DEFAULT_OPTIONS) -> Iterator {
	return {
		section = "",
		options = options,
		_src = src,
	}
}


// Returns the raw `key` and `value`. `ok` will be false if no more key=value pairs cannot be found.
// They key and value may be quoted, which may require the use of `strconv.unquote_string`.
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

		if it.options.comment != "" && strings.has_prefix(line, it.options.comment) {
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

Map :: distinct map[string]map[string]string

load_map_from_string :: proc(src: string, allocator: runtime.Allocator, options := DEFAULT_OPTIONS) -> (m: Map, err: runtime.Allocator_Error) {
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

	it := iterator_from_string(src, options)

	for key, value in iterate(&it) {
		section := it.section
		if section not_in m {
			section = strings.clone(section) or_return
			m[section] = {}
		}

		// store key-value pair
		pairs := &m[section]
		new_key := unquote(key) or_return
		if options.key_lower_case {
			old_key := new_key
			new_key = strings.to_lower(key) or_return
			delete(old_key) or_return
		}
		pairs[new_key] = unquote(value) or_return
	}
	return
}

load_map_from_path :: proc(path: string, allocator: runtime.Allocator, options := DEFAULT_OPTIONS) -> (m: Map, err: runtime.Allocator_Error, ok: bool) {
	data := os.read_entire_file(path, allocator) or_return
	defer delete(data, allocator)
	m, err = load_map_from_string(string(data), allocator, options)
	ok = err == nil
	defer if !ok {
		delete_map(m)
	}
	return
}

save_map_to_string :: proc(m: Map, allocator: runtime.Allocator) -> (data: string) {
	b := strings.builder_make(allocator)
	_, _ = write_map(strings.to_writer(&b), m)
	return strings.to_string(b)
}

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

write_section :: proc(w: io.Writer, name: string, n_written: ^int = nil) -> (n: int, err: io.Error) {
	defer if n_written != nil { n_written^ += n }
	io.write_byte  (w, '[',  &n) or_return
	io.write_string(w, name, &n) or_return
	io.write_byte  (w, ']',  &n) or_return
	io.write_byte  (w, '\n',  &n) or_return
	return
}

write_pair :: proc(w: io.Writer, key: string, value: $T, n_written: ^int = nil) -> (n: int, err: io.Error) {
	defer if n_written != nil { n_written^ += n }
	io.write_string(w, key,   &n) or_return
	io.write_string(w, " = ", &n) or_return
	when intrinsics.type_is_string(T) {
		val := string(value)
		if len(val) > 0 && (val[0] == ' ' || val[len(val)-1] == ' ') {
			io.write_quoted_string(w, val, n_written=&n) or_return
		} else {
			io.write_string(w, val, &n) or_return
		}
	} else {
		n += fmt.wprint(w, value)
	}
	io.write_byte(w, '\n', &n) or_return
	return
}

write_map :: proc(w: io.Writer, m: Map) -> (n: int, err: io.Error) {
	section_index := 0
	for section, pairs in m {
		if section_index == 0 && section == "" {
			// ignore section
		} else {
			write_section(w, section, &n) or_return
		}
		for key, value in pairs {
			write_pair(w, key, value, &n) or_return
		}
		section_index += 1
	}
	return
}
