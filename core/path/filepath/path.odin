package filepath

import "core:os"
import "core:strings"

// is_separator checks whether the byte is a valid separator character
is_separator :: proc(c: byte) -> bool {
	switch c {
	case '/':  return true;
	case '\\': return ODIN_OS == "windows";
	}
	return false;
}

@(private)
is_slash :: proc(c: byte) -> bool {
	return c == '\\' || c == '/';
}

split :: proc(path: string) -> (dir, file: string) {
	vol := volume_name(path);
	i := len(path) - 1;
	for i >= len(vol) && !is_separator(path[i]) {
		i -= 1;
	}
	return path[:i+1], path[i+1:];
}

volume_name :: proc(path: string) -> string {
	return path[:volume_name_len(path)];
}

volume_name_len :: proc(path: string) -> int {
	if len(path) < 2 {
		return 0;
	}
	c := path[0];
	if path[1] == ':' {
		switch c {
		case 'a'..'z', 'A'..'Z':
			return 2;
		}
	}

	if l := len(path); l >= 5 && is_slash(path[0]) && is_slash(path[1]) &&
		!is_slash(path[2]) && path[2] != '.' {
		for n := 3; n < l-1; n += 1 {
			if is_slash(path[n]) {
				n += 1;
				if !is_slash(path[n]) {
					if path[n] == '.' {
						break;
					}
				}
				for ; n < l; n += 1 {
					if is_slash(path[n]) {
						break;
					}
				}
				return n;
			}
			break;
		}
	}
	return 0;
}


clean :: proc(path: string, allocator := context.allocator) -> string {
	context.allocator = allocator;

	path := path;
	original_path := path;
	vol_len := volume_name_len(path);
	path = path[vol_len:];

	if path == "" {
		if vol_len > 1 && original_path[1] != ':' {
			return from_slash(original_path);
		}
		return strings.concatenate({original_path, "."});
	}

	rooted := is_separator(path[0]);

	n := len(path);
	out := &Lazy_Buffer{
		s = path,
		vol_and_path = original_path,
		vol_len = vol_len,
	};

	r, dot_dot := 0, 0;
	if rooted {
		lazy_buffer_append(out, '/');
		r, dot_dot = 1, 1;
	}

	for r < n {
		switch {
		case is_separator(path[r]):
			r += 1;
		case path[r] == '.' && (r+1 == n || is_separator(path[r+1])):
			r += 1;
		case path[r] == '.' && path[r+1] == '.' && (r+2 == n || is_separator(path[r+2])):
			r += 2;
			switch {
			case out.w > dot_dot:
				out.w -= 1;
				for out.w > dot_dot && !is_separator(lazy_buffer_index(out, out.w)) {
					out.w -= 1;
				}
			case !rooted:
				if out.w > 0 {
					lazy_buffer_append(out, '/');
				}
				lazy_buffer_append(out, '.');
				lazy_buffer_append(out, '.');
				dot_dot = out.w;
			}
		case:
			if rooted && out.w != 1 || !rooted && out.w != 0 {
				lazy_buffer_append(out, '/');
			}
			for ; r < n && !is_separator(path[r]); r += 1 {
				lazy_buffer_append(out, path[r]);
			}

		}
	}

	if out.w == 0 {
		lazy_buffer_append(out, '.');
	}

	s := lazy_buffer_string(out);
	cleaned := from_slash(s);
	return cleaned;
}

from_slash :: proc(path: string, allocator := context.allocator) -> string {
	if SEPARATOR == '/' {
		return path;
	}
	s, ok := strings.replace_all(path, "/", SEPARATOR_STRING, allocator);
	if !ok {
		s = strings.clone(s, allocator);
	}
	return s;
}



/*
	Lazy_Buffer is a lazily made path buffer
	When it does allocate, it uses the context.allocator
 */
@(private)
Lazy_Buffer :: struct {
	s: string,
	b: []byte,
	w: int, // write index
	vol_and_path: string,
	vol_len:      int,
}

@(private)
lazy_buffer_index :: proc(lb: ^Lazy_Buffer, i: int) -> byte {
	if lb.b != nil {
		return lb.b[i];
	}
	return lb.s[i];
}
@(private)
lazy_buffer_append :: proc(lb: ^Lazy_Buffer, c: byte) {
	if lb.b == nil {
		if lb.w < len(lb.s) && lb.s[lb.w] == c {
			lb.w += 1;
			return;
		}
		lb.b = make([]byte, len(lb.s));
		copy(lb.b, lb.s[:lb.w]);
	}
	lb.b[lb.w] = c;
	lb.w += 1;
}
@(private)
lazy_buffer_string :: proc(lb: ^Lazy_Buffer) -> string {
	if lb.b == nil {
		return strings.clone(lb.vol_and_path[:lb.vol_len+lb.w]);
	}

	x := lb.vol_and_path[:lb.vol_len];
	y := string(lb.b[:lb.w]);
	z := make([]byte, len(x)+len(y));
	copy(z, x);
	copy(z[len(x):], y);
	return string(z);
}
