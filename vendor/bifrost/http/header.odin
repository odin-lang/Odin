package bifrost_http

import "core:mem"

header_add :: proc(h: ^Header, name, value: string) {
	if h == nil {
		return
	}
	key := header_key(name)
	vals, ok := h[key]
	if !ok {
		h[key] = {value}
		return
	}
	vals = append(vals, value)
	h[key] = vals
}

header_set :: proc(h: ^Header, name, value: string) {
	if h == nil {
		return
	}
	key := header_key(name)
	h[key] = {value}
}

header_get :: proc(h: Header, name: string) -> (value: string, ok: bool) {
	key := header_key(name)
	vals, ok := h[key]
	if !ok || len(vals) == 0 {
		return "", false
	}
	return vals[0], true
}

header_del :: proc(h: ^Header, name: string) {
	if h == nil {
		return
	}
	key := header_key(name)
	delete(h, key)
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
	key := header_key(name)
	vals, ok := h[key]
	if !ok {
		return false
	}
	for v in vals {
		if mem.compare([]u8(v), []u8(value)) == 0 {
			return true
		}
	}
	return false
}
