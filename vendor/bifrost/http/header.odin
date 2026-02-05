package bifrost_http

import "core:bytes"
import "core:mem"
import "core:sort"
import "core:strings"

header_add :: proc(h: ^Header, name, value: string) {
	if h == nil {
		return
	}
	if h^ == nil {
		h^ = make(Header)
	}
	key, ok := header_find_key(h^, name)
	if !ok {
		key = header_key(name)
	}
	val := header_clone_string(value)
	vals, found := h^[key]
	if !found {
		new_vals := make([]string, 1)
		new_vals[0] = val
		h^[key] = new_vals
		return
	}
	new_vals := make([]string, len(vals)+1)
	copy(new_vals, vals)
	new_vals[len(vals)] = val
	delete(vals)
	h^[key] = new_vals
}

header_set :: proc(h: ^Header, name, value: string) {
	if h == nil {
		return
	}
	if h^ == nil {
		h^ = make(Header)
	}
	key, ok := header_find_key(h^, name)
	if !ok {
		key = header_key(name)
	} else {
		if vals, found := h^[key]; found {
			header_free_values(vals)
			delete(vals)
		}
	}
	val := header_clone_string(value)
	new_vals := make([]string, 1)
	new_vals[0] = val
	h^[key] = new_vals
}

header_get :: proc(h: Header, name: string) -> (value: string, ok: bool) {
	key, found := header_find_key(h, name)
	if !found {
		return "", false
	}
	vals := h[key]
	if len(vals) == 0 {
		return "", false
	}
	return vals[0], true
}

header_del :: proc(h: ^Header, name: string) {
	if h == nil {
		return
	}
	key, found := header_find_key(h^, name)
	if !found {
		return
	}
	if vals, ok := h^[key]; ok {
		header_free_values(vals)
		delete(vals)
	}
	header_free_string(key)
	delete_key(h, key)
}

header_key :: proc(name: string) -> string {
	if len(name) == 0 {
		return ""
	}
	buf := make([]u8, len(name))
	valid := true
	for i in 0..<len(name) {
		if !header_is_token_char(name[i]) {
			valid = false
			break
		}
	}
	if !valid {
		copy(buf, transmute([]u8)name)
		return string(buf)
	}
	upper := true
	for i in 0..<len(name) {
		b := name[i]
		if upper && b >= 'a' && b <= 'z' {
			b -= 32
		} else if !upper && b >= 'A' && b <= 'Z' {
			b += 32
		}
		buf[i] = b
		upper = b == '-'
	}
	return string(buf)
}

header_key_lower :: proc(name: string) -> string {
	if len(name) == 0 {
		return ""
	}
	buf := make([]u8, len(name))
	for i in 0..<len(name) {
		b := name[i]
		if b >= 'A' && b <= 'Z' {
			b += 32
		}
		buf[i] = b
	}
	return string(buf)
}

header_is_token_char :: proc(c: u8) -> bool {
	if c >= '0' && c <= '9' {
		return true
	}
	if c >= 'A' && c <= 'Z' {
		return true
	}
	if c >= 'a' && c <= 'z' {
		return true
	}
	switch c {
	case '!', '#', '$', '%', '&', '\'', '*', '+', '-', '.', '^', '_', '`', '|', '~':
		return true
	}
	return false
}

header_valid_field_name :: proc(name: string) -> bool {
	if len(name) == 0 {
		return false
	}
	for i in 0..<len(name) {
		if !header_is_token_char(name[i]) {
			return false
		}
	}
	return true
}

header_valid_field_value :: proc(value: string) -> bool {
	for i in 0..<len(value) {
		b := value[i]
		if b == 0x7f {
			return false
		}
		if b < 0x20 && b != '\t' && b != ' ' {
			return false
		}
	}
	return true
}

header_write_subset :: proc(out: ^bytes.Buffer, h: Header, exclude: map[string]bool = nil) {
	if out == nil || h == nil {
		return
	}
	keys := make([dynamic]string, 0, len(h))
	for k in h {
		if exclude != nil && exclude[k] {
			continue
		}
		append(&keys, k)
	}
	if len(keys) > 1 {
		sort.quick_sort(keys[:])
	}

	for k in keys {
		vals, ok := h[k]
		if !ok || vals == nil || len(vals) == 0 {
			continue
		}
		if !header_valid_field_name(k) {
			continue
		}
		for v in vals {
			if len(v) == 0 {
				_, _ = bytes.buffer_write_string(out, k)
				_, _ = bytes.buffer_write_string(out, ": \r\n")
				continue
			}

			start := 0
			end := len(v)
			for start < end {
				b := v[start]
				if b == ' ' || b == '\t' || b == '\r' || b == '\n' {
					start += 1
				} else {
					break
				}
			}
			for end > start {
				b := v[end-1]
				if b == ' ' || b == '\t' || b == '\r' || b == '\n' {
					end -= 1
				} else {
					break
				}
			}
			view := v[start:end]
			needs_copy := false
			for i in 0..<len(view) {
				if view[i] == '\r' || view[i] == '\n' {
					needs_copy = true
					break
				}
			}
			if needs_copy {
				buf := make([]u8, len(view), allocator=context.temp_allocator)
				for i in 0..<len(view) {
					b := view[i]
					if b == '\r' || b == '\n' {
						b = ' '
					}
					buf[i] = b
				}
				view = string(buf)
			}

			_, _ = bytes.buffer_write_string(out, k)
			_, _ = bytes.buffer_write_string(out, ": ")
			_, _ = bytes.buffer_write_string(out, view)
			_, _ = bytes.buffer_write_string(out, "\r\n")
		}
	}
	delete(keys)
}

header_has_value :: proc(h: Header, name, value: string) -> bool {
	key, found := header_find_key(h, name)
	if !found {
		return false
	}
	vals := h[key]
	for v in vals {
		if mem.compare(transmute([]u8)v, transmute([]u8)value) == 0 {
			return true
		}
	}
	return false
}

header_has_token :: proc(h: Header, name, token: string) -> bool {
	key, found := header_find_key(h, name)
	if !found {
		return false
	}
	vals := h[key]
	for v in vals {
		parts, _ := strings.split(v, ",", context.temp_allocator)
		for p in parts {
			if strings.equal_fold(strings.trim_space(p), token) {
				return true
			}
		}
	}
	return false
}

header_values :: proc(h: Header, name: string) -> (vals: []string, ok: bool) {
	key, found := header_find_key(h, name)
	if !found {
		return nil, false
	}
	return h[key], true
}

header_find_key :: proc(h: Header, name: string) -> (key: string, ok: bool) {
	for k in h {
		if strings.equal_fold(k, name) {
			return k, true
		}
	}
	return "", false
}

header_clone_string :: proc(s: string) -> string {
	if len(s) == 0 {
		return ""
	}
	buf := make([]u8, len(s))
	copy(buf, transmute([]u8)s)
	return string(buf)
}

header_free_string :: proc(s: string) {
	if len(s) == 0 {
		return
	}
	buf := transmute([]u8)s
	delete(buf)
}

header_free_values :: proc(vals: []string) {
	for v in vals {
		header_free_string(v)
	}
}

header_reset :: proc(h: ^Header) {
	if h == nil || h^ == nil {
		return
	}
	for k, vals in h^ {
		header_free_values(vals)
		delete(vals)
		header_free_string(k)
	}
	delete(h^)
	h^ = nil
}

header_clone :: proc(src: Header) -> Header {
	if src == nil {
		return nil
	}
	dst := make(Header)
	for name, vals in src {
		for v in vals {
			header_add(&dst, name, v)
		}
	}
	return dst
}
