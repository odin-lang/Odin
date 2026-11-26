// Reader and writer for a variant of the `.ini` file format with `key = value` entries in `[sections]`.
package encoding_ini

import    "base:runtime"
import    "base:intrinsics"
import    "core:strings"
import    "core:strconv"
import    "core:io"
import    "core:fmt"
_ :: fmt

iterator_from_string :: proc(src: string, options := DEFAULT_OPTIONS) -> Iterator {
	return {
		section = "",
		options = options,
		_src = src,
	}
}

// Returns the next `key` and `value` as written, quotes included, with surrounding whitespace
// removed. `ok` is false once no pairs are left. `it.section` holds the current section name,
// trimmed. A quoted key followed by `=` ends at its closing quote, so it may contain `=`.
// `load_map_from_string` unquotes `"..."` with `strconv.unquote_string` and `'...'` literally,
// and keeps a key or value it can't unquote as written.
iterate :: proc(it: ^Iterator) -> (key, value: string, ok: bool) {
	for {
		is_section: bool
		key, value, is_section, ok = _iterate(it)
		if !ok || !is_section {
			return
		}
	}
}

load_map_from_string :: proc(src: string, allocator: runtime.Allocator, options := DEFAULT_OPTIONS) -> (m: Map, err: runtime.Allocator_Error) {
	context.allocator = allocator
	m, err = _load_map(src, options)
	if err != nil {
		delete_map(m)
		return nil, err
	}
	return
}

save_map_to_string :: proc(m: Map, allocator: runtime.Allocator) -> (data: string, err: Error) {
	b := strings.builder_make(allocator) or_return
	_, err = write_map(strings.to_writer(&b), m)
	if err != nil {
		strings.builder_destroy(&b)
		if err == io.Error.Short_Write {
			err = runtime.Allocator_Error.Out_Of_Memory
		}
		return "", err
	}
	return strings.to_string(b), nil
}

delete_map :: proc(m: Map) {
	allocator := m.allocator
	for section, pairs in m {
		for key, value in pairs {
			delete(key, allocator)
			delete(value, allocator)
		}
		delete(section, allocator)
		delete(pairs)
	}
	delete(m)
}

write_section :: proc(w: io.Writer, name: string, n_written: ^int = nil) -> (n: int, err: Error) {
	defer if n_written != nil { n_written^ += n }
	if !_section_name_ok(name) {
		return 0, Write_Error.Invalid_Section_Name
	}
	io.write_byte  (w, '[',  &n) or_return
	io.write_string(w, name, &n) or_return
	io.write_byte  (w, ']',  &n) or_return
	io.write_byte  (w, '\n',  &n) or_return
	return
}

write_pair :: proc(w: io.Writer, key: string, value: $T, n_written: ^int = nil) -> (n: int, err: Error) {
	defer if n_written != nil { n_written^ += n }
	if _key_needs_quotes(key) {
		io.write_quoted_string(w, key, n_written=&n) or_return
	} else {
		io.write_string(w, key, &n) or_return
	}
	io.write_string(w, " = ", &n) or_return
	when intrinsics.type_is_string(T) {
		val := string(value)
		if _value_needs_quotes(val) {
			io.write_quoted_string(w, val, n_written=&n) or_return
		} else {
			io.write_string(w, val, &n) or_return
		}
	} else {
		ew := Error_Writer{w = w}
		n += fmt.wprint(io.Writer{procedure = _error_writer_proc, data = &ew}, value, flush = false)
		if ew.err != nil {
			return n, ew.err
		}
	}
	io.write_byte(w, '\n', &n) or_return
	return
}

write_map :: proc(w: io.Writer, m: Map) -> (n: int, err: Error) {
	for section in m {
		if !_section_name_ok(section) {
			return 0, Write_Error.Invalid_Section_Name
		}
	}
	if pairs, ok := m[""]; ok && len(pairs) == 0 {
		write_section(w, "", &n) or_return
	} else if ok {
		// ignore section
		for key, value in pairs {
			write_pair(w, key, value, &n) or_return
		}
	}
	for section, pairs in m {
		if section == "" {
			continue
		}
		write_section(w, section, &n) or_return
		for key, value in pairs {
			write_pair(w, key, value, &n) or_return
		}
	}
	return
}

@(private)
_load_map :: proc(src: string, options: Options) -> (m: Map, err: runtime.Allocator_Error) {
	unquote :: proc(val: string) -> (string, runtime.Allocator_Error) {
		if len(val) >= 2 && val[0] == '\'' && val[len(val)-1] == '\'' && strings.index_byte(val[1:len(val)-1], '\'') < 0 {
			return strings.clone(val[1:len(val)-1])
		}
		if len(val) > 0 && val[0] == '"' {
			v, allocated, err := strconv.unquote_string(val)
			if alloc_err, is_alloc_err := err.(runtime.Allocator_Error); is_alloc_err {
				return "", alloc_err
			}
			if err != nil {
				return strings.clone(val)
			}
			if allocated {
				return v, nil
			}
			return strings.clone(v)
		}
		return strings.clone(val)
	}

	it := iterator_from_string(src, options)

	for {
		key, value, is_section, ok := _iterate(&it)
		if !ok {
			break
		}
		if is_section && !options.keep_empty_sections {
			continue
		}
		pairs := _section_entry(&m, it.section) or_return
		if is_section {
			continue
		}

		// store key-value pair
		new_key := unquote(key) or_return
		if options.key_lower_case {
			lower: string
			lower, err = strings.to_lower(new_key)
			delete(new_key)
			if err != nil {
				return
			}
			new_key = lower
		}
		new_value, value_err := unquote(value)
		if value_err != nil {
			delete(new_key)
			err = value_err
			return
		}
		_, value_ptr, just_inserted, entry_err := map_entry(pairs, new_key)
		if entry_err != nil {
			delete(new_key)
			delete(new_value)
			err = entry_err
			return
		}
		if !just_inserted {
			delete(new_key)
			delete(value_ptr^)
		}
		value_ptr^ = new_value
	}
	return
}

@(private)
_iterate :: proc(it: ^Iterator) -> (key, value: string, is_section: bool, ok: bool) {
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
			it.section = strings.trim_space(line[1:end_idx])
			is_section = true
			ok = true
			return
		}

		if it.options.comment != "" && strings.has_prefix(line, it.options.comment) {
			continue
		}

		equal := _quoted_key_end(line)
		if equal < 0 {
			equal = strings.index(line, " =") // check for things keys that `ctrl+= = zoom_in`
			quote := strings.index_any(line, `"'`)
			if equal < 0 || quote >= 0 && quote < equal {
				equal = strings.index_byte(line, '=')
				if equal < 0 {
					continue
				}
			} else {
				equal += 1
			}
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
_quoted_key_end :: proc(line: string) -> int {
	if len(line) == 0 || (line[0] != '"' && line[0] != '\'') {
		return -1
	}
	i := 1
	for i < len(line) && line[i] != line[0] {
		if line[0] == '"' && line[i] == '\\' {
			i += 1
		}
		i += 1
	}
	if i >= len(line) {
		return -1
	}
	rest := strings.trim_left_space(line[i+1:])
	if len(rest) == 0 || rest[0] != '=' {
		return -1
	}
	return len(line) - len(rest)
}

@(private)
_section_entry :: proc(m: ^Map, section: string) -> (pairs: ^map[string]string, err: runtime.Allocator_Error) {
	if section in m^ {
		return &m^[section], nil
	}
	name := strings.clone(section) or_return
	_, value_ptr, _, entry_err := map_entry(m, name)
	if entry_err != nil {
		delete(name)
		return nil, entry_err
	}
	return value_ptr, nil
}

@(private)
_section_name_ok :: proc(name: string) -> bool {
	return strings.index_any(name, "]\r\n") < 0 && strings.trim_space(name) == name
}

@(private)
_key_needs_quotes :: proc(key: string) -> bool {
	switch {
	case len(key) == 0, strings.trim_space(key) != key:
		return true
	case key[0] == '[', key[0] == '"', key[0] == '\'':
		return true
	case strings.index_any(key, "\r\n") >= 0, strings.contains(key, " ="):
		return true
	}
	return strings.index_any(key, `"'`) >= 0 && strings.index_byte(key, '=') >= 0
}

@(private)
_value_needs_quotes :: proc(value: string) -> bool {
	switch {
	case len(value) == 0:
		return false
	case strings.trim_space(value) != value, value[0] == '"', value[0] == '\'':
		return true
	}
	return strings.index_any(value, "\r\n") >= 0
}

@(private)
_error_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	ew := (^Error_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		if ew.err != nil {
			return 0, ew.err
		}
		written: int
		written, err = io.write(ew.w, p)
		ew.err = err
		return i64(written), err
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}