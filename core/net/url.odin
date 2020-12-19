package net

import "core:strings"
import "core:strconv"
import "core:unicode/utf8"
import "core:mem"
import "core:encoding/base64"

split_url :: proc(url: string, allocator := context.allocator) -> (scheme, host, path: string, queries: map[string]string) {
	s := url;

	i := strings.last_index(s, "://");
	if i != -1 {
		scheme = s[:i];
		s = s[i+3:];
	}

	i = strings.index(s, "?");
	if i != -1 {
		query_str := s[i+1:];
		s = s[:i];
		if query_str != "" {
			queries_parts := strings.split(query_str, "&");
			queries = make(map[string]string, len(queries_parts), allocator);
			for q in queries_parts {
				parts := strings.split(q, "=");
				switch len(parts) {
				case 1:  queries[parts[0]] = "";
				case 2:  queries[parts[0]] = parts[1];
				case:    break;
				}
			}
		}
	}

	i = strings.last_index(s, "/");
	if i == -1 {
		host = s;
		path = "/";
		return;
	} else {
		host = s[:i];
		path = s[i:];
	}

	return;
}

join_url :: proc(scheme, host, path: string, queries: map[string]string, allocator := context.allocator) -> string {
	using strings;

	b := make_builder(allocator);
	grow_builder(&b, len(scheme) + 3 + len(host) + 1 + len(path));

	write_string(&b, scheme);
	write_string(&b, "://");
	write_string(&b, trim_space(host));

	if path != "" {
		if path[0] != '/' do write_string(&b, "/");
		write_string(&b, trim_space(path));
	}


	if len(queries) > 0 do write_string(&b, "?");
	for query_name, query_value in queries {
		write_string(&b, query_name);
		if query_value != "" {
			write_string(&b, "=");
			write_string(&b, query_value);
		}
	}

	return to_string(b);
}

percent_encode :: proc(s: string, allocator := context.allocator) -> string {
	using strings;

	b := make_builder(allocator);
	grow_builder(&b, len(s) + 16); // NOTE(tetra): A reasonable number to allow for the number of things we need to escape.

	for ch in s {
		switch ch {
		case 'A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~':
			write_rune_builder(&b, ch);
		case:
			bytes, n := utf8.encode_rune(ch);
			for byte in bytes[:n] {
				buf: [2]u8 = ---;
				t := strconv.append_int(buf[:], i64(byte), 16);
				write_rune_builder(&b, '%');
				write_string(&b, t);
			}
		}
	}

	return to_string(b);
}

percent_decode :: proc(encoded_string: string, allocator := context.allocator) -> (decoded_string: string, ok: bool) {
	using strings;

	b := make_builder(allocator);
	grow_builder(&b, len(encoded_string));
	defer if !ok do destroy_builder(&b);

	stack_buf: [4]u8;
	pending := mem.buffer_from_slice(stack_buf[:]);
	s := encoded_string;

	for len(s) > 0 {
		i := index_rune(s, '%');
		if i == -1 {
			write_string(&b, s); // no '%'s; the string is already decoded
			break;
		}

		write_string(&b, s[:i]);
		s = s[i:];

		if len(s) == 0 do return; // percent without anything after it
		s = s[1:];

		if s[0] == '%' {
			write_rune_builder(&b, '%');
			s = s[1:];
			continue;
		}

		if len(s) < 2 do return; // percent without encoded value

		n: int;
		n, _ = strconv.parse_int(s[:2], 16);
		switch n {
		case 0x20:  write_rune_builder(&b, ' ');
		case 0x21:  write_rune_builder(&b, '!');
		case 0x23:  write_rune_builder(&b, '#');
		case 0x24:  write_rune_builder(&b, '$');
		case 0x25:  write_rune_builder(&b, '%');
		case 0x26:  write_rune_builder(&b, '&');
		case 0x27:  write_rune_builder(&b, '\'');
		case 0x28:  write_rune_builder(&b, '(');
		case 0x29:  write_rune_builder(&b, ')');
		case 0x2A:  write_rune_builder(&b, '*');
		case 0x2B:  write_rune_builder(&b, '+');
		case 0x2C:  write_rune_builder(&b, ',');
		case 0x2F:  write_rune_builder(&b, '/');
		case 0x3A:  write_rune_builder(&b, ':');
		case 0x3B:  write_rune_builder(&b, ';');
		case 0x3D:  write_rune_builder(&b, '=');
		case 0x3F:  write_rune_builder(&b, '?');
		case 0x40:  write_rune_builder(&b, '@');
		case 0x5B:  write_rune_builder(&b, '[');
		case 0x5D:  write_rune_builder(&b, ']');
		case:
			// utf-8 bytes
			// TODO(tetra): Audit this - 4 bytes???
			append(&pending, s[0]);
			append(&pending, s[1]);
			if len(pending) == 4 {
				r, _ := utf8.decode_rune(pending[:]);
				write_rune_builder(&b, r);
				clear(&pending);
			}
		}
		s = s[2:];
	}

	ok = true;
	decoded_string = to_string(b);
	return;
}

//
// TODO: encoding/base64 is broken...
//

// // TODO(tetra): The whole "table" stuff in encoding/base64 is too impenetrable for me to
// // make a table for this ... sigh - so this'll do for now.
// base64url_encode :: proc(data: []byte, allocator := context.allocator) -> string {
// 	out := transmute([]byte) base64.encode(data, base64.ENC_TABLE, allocator);
// 	for b, i in out {
// 		switch b {
// 		case '+': out[i] = '-';
// 		case '/': out[i] = '_';
// 		}
// 	}
// 	i := len(out)-1;
// 	for ; i >= 0; i -= 1 {
// 		if out[i] != '=' do break;
// 	}
// 	return string(out[:i+1]);
// }

// base64url_decode :: proc(s: string, allocator := context.allocator) -> []byte {
// 	size := len(s);
// 	padding := 0;
// 	for size % 4 != 0 {
// 		size += 1; // TODO: SPEED
// 		padding += 1;
// 	}

// 	temp := make([]byte, size, context.temp_allocator);
// 	copy(temp, transmute([]byte) s);

// 	for b, i in temp {
// 		switch b {
// 		case '-': temp[i] = '+';
// 		case '_': temp[i] = '/';
// 		}
// 	}

// 	for in 0..padding-1 {
// 		temp[len(temp)-1] = '=';
// 	}

// 	return base64.decode(string(temp), base64.DEC_TABLE, allocator);
// }