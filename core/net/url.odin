package net

import "core:fmt"
import "core:strings"
import "core:strconv"

split_url :: proc(url: string) -> (scheme, host, path: string, queries: map[string]string) {
	s := url;
	{
		i := strings.last_index(s, "://");
		if i != -1 {
			scheme = s[:i];
			s = s[i+3:];
		}
	}
	{
		i := strings.index(s, "?");
		if i != -1 {
			query_str := s[i+1:];
			s = s[:i];
			if query_str != "" {
				queries_parts := strings.split(query_str, "&");
				queries = make(map[string]string, len(queries_parts));
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
	}
	{
		i := strings.last_index(s, "/");
		if i == -1 {
			host = s;
			path = "/";
			return;
		} else {
			host = s[:i];
			path = s[i:];
		}
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
		case ' ': write_string(&b, "%20");
		case '!': write_string(&b, "%21");
		case '#': write_string(&b, "%23");
		case '$': write_string(&b, "%24");
		case '%': write_string(&b, "%25");
		case '&': write_string(&b, "%26");
		case '\'': write_string(&b, "%27");
		case '(': write_string(&b, "%28");
		case ')': write_string(&b, "%29");
		case '*': write_string(&b, "%2A");
		case '+': write_string(&b, "%2B");
		case ',': write_string(&b, "%2C");
		case '/': write_string(&b, "%2F");
		case ':': write_string(&b, "%3A");
		case ';': write_string(&b, "%3B");
		case '=': write_string(&b, "%3D");
		case '?': write_string(&b, "%3F");
		case '@': write_string(&b, "%40");
		case '[': write_string(&b, "%5B");
		case ']': write_string(&b, "%5D");
		case:     write_rune(&b, ch);
		}
	}

	return to_string(b);
}

percent_decode :: proc(encoded_string: string, allocator := context.allocator) -> (decoded_string: string, ok: bool) {
	using strings;

	b := make_builder(allocator);
	grow_builder(&b, len(encoded_string));
	defer if !ok do destroy_builder(&b);

	s := encoded_string;
	for len(s) > 0 {
		i := index_rune(s, '%');
		if i == -1 {
			write_string(&b, s); // the string is already decoded
			break;
		}

		write_string(&b, s[:i]);
		s = s[i:];
		
		if len(s) == 0 do return; // percent without anything after it
		s = s[1:];

		if s[0] == '%' {
			write_rune(&b, '%');
			s = s[1:];
			continue;
		}

		if len(s) < 2 do return; // percent without encoded value

		n: int;
		n, _ = strconv.parse_int(s[:2], 16);
		// fmt.printf("%q\n", n);
		switch n {
		case 0x20:  write_rune(&b, ' ');
		case 0x21:  write_rune(&b, '!');
		case 0x23:  write_rune(&b, '#');
		case 0x24:  write_rune(&b, '$');
		case 0x25:  write_rune(&b, '%');
		case 0x26:  write_rune(&b, '&');
		case 0x27:  write_rune(&b, '\'');
		case 0x28:  write_rune(&b, '(');
		case 0x29:  write_rune(&b, ')');
		case 0x2A:  write_rune(&b, '*');
		case 0x2B:  write_rune(&b, '+');
		case 0x2C:  write_rune(&b, ',');
		case 0x2F:  write_rune(&b, '/');
		case 0x3A:  write_rune(&b, ':');
		case 0x3B:  write_rune(&b, ';');
		case 0x3D:  write_rune(&b, '=');
		case 0x3F:  write_rune(&b, '?');
		case 0x40:  write_rune(&b, '@');
		case 0x5B:  write_rune(&b, '[');
		case 0x5D:  write_rune(&b, ']');
		case:       return; // invalid encoded value
		}
		s = s[2:];
	}

	ok = true;
	decoded_string = to_string(b);
	return;
}