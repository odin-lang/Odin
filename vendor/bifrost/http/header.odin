package bifrost_http

import "core:mem"
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
	for i in 0..<len(name) {
		b := name[i]
		if b >= 'A' && b <= 'Z' {
			b += 32
		}
		buf[i] = b
	}
	return string(buf)
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
