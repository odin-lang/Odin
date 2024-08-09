package net
/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code
*/

import "core:strings"
import "core:strconv"
import "core:unicode/utf8"
import "core:encoding/hex"

split_url :: proc(url: string, allocator := context.allocator) -> (scheme, host, path: string, queries: map[string]string, fragment: string) {
	s := url

	i := strings.index(s, "://")
	if i >= 0 {
		scheme = s[:i]
		s = s[i+3:]
	}

	i = strings.index(s, "#")
	if i != -1 {
		fragment = s[i+1:]
		s = s[:i]
	}

	i = strings.index(s, "?")
	if i != -1 {
		query_str := s[i+1:]
		s = s[:i]
		if query_str != "" {
			queries_parts := strings.split(query_str, "&")
			defer delete(queries_parts)
			queries = make(map[string]string, len(queries_parts), allocator)
			for q in queries_parts {
				parts := strings.split(q, "=")
				defer delete(parts)
				switch len(parts) {
				case 1:  queries[parts[0]] = ""        // NOTE(tetra): Query not set to anything, was but present.
				case 2:  queries[parts[0]] = parts[1]  // NOTE(tetra): Query set to something.
				case:    break
				}
			}
		}
	}

	i = strings.index(s, "/")
	if i == -1 {
		host = s
		path = "/"
	} else {
		host = s[:i]
		path = s[i:]
	}

	return
}

join_url :: proc(scheme, host, path: string, queries: map[string]string, fragment: string, allocator := context.allocator) -> string {
	b := strings.builder_make(allocator)
	strings.builder_grow(&b, len(scheme) + 3 + len(host) + 1 + len(path))

	strings.write_string(&b, scheme)
	strings.write_string(&b, "://")
	strings.write_string(&b, strings.trim_space(host))

	if path != "" {
		if path[0] != '/' {
			strings.write_string(&b, "/")
		}
		strings.write_string(&b, strings.trim_space(path))
	}


	query_length := len(queries)
	if query_length > 0 {
		strings.write_string(&b, "?")
	}
	i := 0
	for query_name, query_value in queries {
		strings.write_string(&b, query_name)
		if query_value != "" {
			strings.write_string(&b, "=")
			strings.write_string(&b, query_value)
		}
		if i < query_length - 1 {
			strings.write_string(&b, "&")
		}
		i += 1
	}

	if fragment != "" {
		if fragment[0] != '#' {
			strings.write_string(&b, "#")
		}
		strings.write_string(&b, strings.trim_space(fragment))
	}

	return strings.to_string(b)
}

percent_encode :: proc(s: string, allocator := context.allocator) -> string {
	b := strings.builder_make(allocator)
	strings.builder_grow(&b, len(s) + 16) // NOTE(tetra): A reasonable number to allow for the number of things we need to escape.

	for ch in s {
		switch ch {
		case 'A'..='Z', 'a'..='z', '0'..='9', '-', '_', '.', '~':
			strings.write_rune(&b, ch)
		case:
			bytes, n := utf8.encode_rune(ch)
			for byte in bytes[:n] {
				buf: [2]u8 = ---
				t := strconv.append_int(buf[:], i64(byte), 16)
				strings.write_rune(&b, '%')
				strings.write_string(&b, t)
			}
		}
	}

	return strings.to_string(b)
}

percent_decode :: proc(encoded_string: string, allocator := context.allocator) -> (decoded_string: string, ok: bool) {
	b := strings.builder_make(allocator)
	strings.builder_grow(&b, len(encoded_string))
	defer if !ok {
		strings.builder_destroy(&b)
	}

	s := encoded_string

	for len(s) > 0 {
		i := strings.index_byte(s, '%')
		if i == -1 {
			strings.write_string(&b, s) // no '%'s; the string is already decoded
			break
		}

		strings.write_string(&b, s[:i])
		s = s[i:]

		if len(s) == 0 {
			return // percent without anything after it
		}
		s = s[1:]

		if s[0] == '%' {
			strings.write_byte(&b, '%')
			s = s[1:]
			continue
		}

		if len(s) < 2 {
			return // percent without encoded value
		}

		val := hex.decode_sequence(s[:2]) or_return
		strings.write_byte(&b, val)
		s = s[2:]
	}

	ok = true
	decoded_string = strings.to_string(b)
	return
}

//
// TODO: encoding/base64 is broken...
//

// // TODO(tetra): The whole "table" stuff in encoding/base64 is too impenetrable for me to
// // make a table for this ... sigh - so this'll do for now.
/*
base64url_encode :: proc(data: []byte, allocator := context.allocator) -> string {
	out := transmute([]byte) base64.encode(data, base64.ENC_TABLE, allocator);
	for b, i in out {
		switch b {
		case '+': out[i] = '-';
		case '/': out[i] = '_';
		}
	}
	i := len(out)-1;
	for ; i >= 0; i -= 1 {
		if out[i] != '=' {
			break;
		}
	}
	return string(out[:i+1]);
}

base64url_decode :: proc(s: string, allocator := context.allocator) -> []byte {
	size := len(s);
	padding := 0;
	for size % 4 != 0 {
		size += 1; // TODO: SPEED
		padding += 1;
	}

	temp := make([]byte, size, context.temp_allocator);
	copy(temp, transmute([]byte) s);

	for b, i in temp {
		switch b {
		case '-': temp[i] = '+';
		case '_': temp[i] = '/';
		}
	}

	for in 0..padding-1 {
		temp[len(temp)-1] = '=';
	}

	return base64.decode(string(temp), base64.DEC_TABLE, allocator);
}
*/
