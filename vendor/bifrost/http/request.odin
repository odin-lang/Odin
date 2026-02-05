package bifrost_http

import base64 "core:encoding/base64"
import "core:bytes"
import "core:strings"

request_write :: proc(out: ^bytes.Buffer, req: ^Request, include_body: bool = true) -> bool {
	if out == nil || req == nil {
		return false
	}
	method := req.Method
	if len(method) == 0 {
		method = "GET"
	}
	target := req.Target
	if len(target) == 0 {
		target = "/"
	}
	proto := req.Proto
	if len(proto) == 0 {
		proto = "HTTP/1.1"
	}

	_, _ = bytes.buffer_write_string(out, method)
	_, _ = bytes.buffer_write_string(out, " ")
	_, _ = bytes.buffer_write_string(out, target)
	_, _ = bytes.buffer_write_string(out, " ")
	_, _ = bytes.buffer_write_string(out, proto)
	_, _ = bytes.buffer_write_string(out, "\r\n")

	if req.Header != nil {
		header_write_subset(out, req.Header, nil)
	}
	_, _ = bytes.buffer_write_string(out, "\r\n")

	if include_body && len(req.Body) > 0 {
		_, _ = bytes.buffer_write(out, req.Body)
	}
	return true
}

parse_http_version :: proc(vers: string) -> (major, minor: int, ok: bool) {
	if len(vers) != 8 {
		return 0, 0, false
	}
	if vers[:5] != "HTTP/" {
		return 0, 0, false
	}
	if vers[6] != '.' {
		return 0, 0, false
	}
	maj := vers[5]
	min := vers[7]
	if maj < '0' || maj > '9' || min < '0' || min > '9' {
		return 0, 0, false
	}
	return int(maj - '0'), int(min - '0'), true
}

request_set_basic_auth :: proc(req: ^Request, username, password: string) -> bool {
	if req == nil {
		return false
	}
	if req.Header == nil {
		req.Header = make(Header)
	}
	raw_len := len(username) + 1 + len(password)
	raw := make([]u8, raw_len)
	copy(raw, transmute([]u8)username)
	raw[len(username)] = ':'
	copy(raw[len(username)+1:], transmute([]u8)password)
	encoded, err := base64.encode(raw[:], base64.ENC_TABLE, allocator=context.temp_allocator)
	delete(raw)
	if err != nil {
		return false
	}
	auth := "Basic " + encoded
	header_set(&req.Header, "authorization", auth)
	delete(encoded)
	return true
}

request_basic_auth :: proc(req: ^Request) -> (username, password: string, ok: bool) {
	if req == nil {
		return "", "", false
	}
	auth, has := header_get(req.Header, "authorization")
	if !has || len(auth) < 6 {
		return "", "", false
	}
	if len(auth) < len("Basic ") || !strings.equal_fold(auth[:5], "basic") || auth[5] != ' ' {
		return "", "", false
	}
	enc := auth[6:]
	if len(enc) == 0 {
		return "", "", false
	}
	decoded, err := base64.decode(enc, base64.DEC_TABLE, allocator=context.temp_allocator)
	if err != nil {
		return "", "", false
	}
	defer delete(decoded)
	dec_str := string(decoded)
	idx := strings.index_byte(dec_str, ':')
	if idx < 0 {
		return "", "", false
	}
	username, _ = strings.clone(dec_str[:idx])
	password, _ = strings.clone(dec_str[idx+1:])
	ok = true
	return
}

request_parse :: proc(raw: string) -> (req: Request, status: int) {
	status = Status_Bad_Request
	if len(raw) == 0 {
		return
	}
	header_end := strings.index(raw, "\r\n\r\n")
	if header_end < 0 {
		return
	}
	head := raw[:header_end]
	body := raw[header_end+4:]

	lines, _ := strings.split(head, "\r\n", context.temp_allocator)
	if len(lines) < 1 {
		return
	}
	parts, _ := strings.split(lines[0], " ", context.temp_allocator)
	if len(parts) != 3 {
		return
	}
	method := parts[0]
	target := parts[1]
	proto := parts[2]

	http10 := false
	if strings.equal_fold(proto, "HTTP/1.0") {
		http10 = true
	} else if strings.equal_fold(proto, "HTTP/1.1") {
		http10 = false
	} else {
		return req, Status_HTTP_Version_Not_Supported
	}

	parsed_target, ok_target := parse_request_target(method, target)
	if !ok_target {
		return
	}

	method, _ = strings.clone(method)
	target, _ = strings.clone(parsed_target)
	proto, _ = strings.clone(proto)
	req = Request{
		Method = method,
		Target = target,
		Proto = proto,
		Header = make(Header),
	}
	ok := false
	defer if !ok {
		header_reset(&req.Header)
		header_free_string(req.Method)
		header_free_string(req.Target)
		header_free_string(req.Proto)
	}

	for i in 1..<len(lines) {
		line := lines[i]
		if len(line) == 0 {
			break
		}
		idx := strings.index_byte(line, ':')
		if idx < 0 {
			continue
		}
		name := line[:idx]
		value := strings.trim_space(line[idx+1:])
		if !header_valid_field_name(name) {
			return
		}
		if !header_valid_field_value(value) {
			return
		}
		header_add(&req.Header, name, value)
	}

	if vals, ok_vals := header_values(req.Header, "content-length"); ok_vals {
		n, ok_cl, _, canonical := parse_content_length_values(vals)
		if !ok_cl {
			return
		}
		if canonical != "" {
			header_set(&req.Header, "content-length", canonical)
		}
		if n > 0 {
			req.Body = make([]u8, n)
			if len(body) >= n {
				copy(req.Body, transmute([]u8)body[:n])
			} else {
				copy(req.Body, transmute([]u8)body)
			}
		}
	}

	if vals, ok_vals := header_values(req.Header, "transfer-encoding"); ok_vals {
		chunked, ok_te, present := parse_transfer_encoding(vals)
		if present && !ok_te {
			return req, Status_Not_Implemented
		}
		if chunked {
			req.Body = nil
		}
	}

	host_vals, has_host := header_values(req.Header, "host")
	if !http10 {
		if !has_host && !strings.equal_fold(req.Method, "CONNECT") {
			return
		}
	}
	if has_host {
		if len(host_vals) != 1 {
			return req, Status_Bad_Request
		}
		if !valid_host_header(host_vals[0]) {
			return req, Status_Bad_Request
		}
	}

	ok = true
	status = 0
	return
}
