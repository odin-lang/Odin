package bifrost_http

import "core:strconv"
import "core:strings"

parse_int_safe :: proc(s: string, base: int = 10) -> (n: int, ok: bool) {
	if len(s) == 0 {
		return 0, false
	}
	return strconv.parse_int(s, base)
}

parse_content_length :: proc(s: string) -> (n: int, ok: bool) {
	if len(s) == 0 {
		return 0, false
	}
	for i in 0..<len(s) {
		ch := s[i]
		if ch < '0' || ch > '9' {
			return 0, false
		}
	}
	return strconv.parse_int(s, 10)
}

parse_content_length_values :: proc(values: []string) -> (n: int, ok: bool, present: bool) {
	if values == nil || len(values) == 0 {
		return 0, false, false
	}
	first := ""
	for v in values {
		val := strings.trim_space(v)
		if len(val) == 0 {
			return 0, false, true
		}
		if first == "" {
			first = val
		} else if val != first {
			return 0, false, true
		}
	}
	if first == "" {
		return 0, false, true
	}
	n, ok = parse_content_length(first)
	return n, ok, true
}

parse_transfer_encoding :: proc(values: []string) -> (chunked: bool, ok: bool, present: bool) {
	if values == nil || len(values) == 0 {
		return false, true, false
	}
	token := ""
	count := 0
	for v in values {
		parts, _ := strings.split(v, ",", context.temp_allocator)
		for p in parts {
			t := strings.trim_space(p)
			if len(t) == 0 {
				continue
			}
			count += 1
			if count == 1 {
				token = t
			} else {
				return false, false, true
			}
		}
	}
	if count == 0 {
		return false, false, true
	}
	if strings.equal_fold(token, "chunked") {
		return true, true, true
	}
	return false, false, true
}

valid_host_header :: proc(host: string) -> bool {
	if len(host) == 0 {
		return true
	}
	for i in 0..<len(host) {
		ch := host[i]
		if ch >= 'a' && ch <= 'z' {
			continue
		}
		if ch >= 'A' && ch <= 'Z' {
			continue
		}
		if ch >= '0' && ch <= '9' {
			continue
		}
		switch ch {
		case '.', '-', '_', ':', '[', ']', '%':
			continue
		}
		return false
	}
	return true
}

parse_request_target :: proc(method, target: string) -> (new_target: string, ok: bool) {
	if method == "CONNECT" {
		return target, true
	}
	if len(target) > 0 && target[0] == '/' {
		return target, true
	}
	if target == "*" {
		return target, true
	}
	if strings.has_prefix(target, "http://") {
		start := len("http://")
		path_idx := strings.index_byte(target[start:], '/')
		if path_idx < 0 {
			return "/", true
		}
		return target[start+path_idx:], true
	}
	if strings.has_prefix(target, "https://") {
		start := len("https://")
		path_idx := strings.index_byte(target[start:], '/')
		if path_idx < 0 {
			return "/", true
		}
		return target[start+path_idx:], true
	}
	return target, false
}
