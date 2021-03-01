// The path/filepath package uses either forward slashes or backslashes depending on the operating system
// To process paths usch as URLs that depend on forward slashes regardless of the OS, use the path package
package filepath

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
	if ODIN_OS == "windows" {
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

		// URL: https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx
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
	}
	return 0;
}

base :: proc(path: string) -> string {
	if path == "" {
		return ".";
	}

	path := path;
	for len(path) > 0 && is_separator(path[len(path)-1]) {
		path = path[:len(path)-1];
	}

	path = path[volume_name_len(path):];

	i := len(path)-1;
	for i >= 0 && !is_separator(path[i]) {
		i -= 1;
	}
	if i >= 0 {
		path = path[i+1:];
	}
	if path == "" {
		return SEPARATOR_STRING;
	}
	return path;
}


clean :: proc(path: string, allocator := context.allocator) -> string {
	context.allocator = allocator;

	path := path;
	original_path := path;
	vol_len := volume_name_len(path);
	path = path[vol_len:];

	if path == "" {
		if vol_len > 1 && original_path[1] != ':' {
			s, ok := from_slash(original_path);
			if !ok {
				s = strings.clone(s);
			}
			return s;
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
		lazy_buffer_append(out, SEPARATOR);
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
					lazy_buffer_append(out, SEPARATOR);
				}
				lazy_buffer_append(out, '.');
				lazy_buffer_append(out, '.');
				dot_dot = out.w;
			}
		case:
			if rooted && out.w != 1 || !rooted && out.w != 0 {
				lazy_buffer_append(out, SEPARATOR);
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
	cleaned, new_allocation := from_slash(s);
	if new_allocation {
		delete(s);
	}
	return cleaned;
}

from_slash :: proc(path: string, allocator := context.allocator) -> (new_path: string, new_allocation: bool) {
	if SEPARATOR == '/' {
		return path, false;
	}
	return strings.replace_all(path, "/", SEPARATOR_STRING, allocator);
}

to_slash :: proc(path: string, allocator := context.allocator) -> (new_path: string, new_allocation: bool) {
	if SEPARATOR == '/' {
		return path, false;
	}
	return strings.replace_all(path, SEPARATOR_STRING, "/", allocator);
}

ext :: proc(path: string) -> string {
	for i := len(path)-1; i >= 0 && !is_separator(path[i]); i -= 1 {
		if path[i] == '.' {
			return path[i:];
		}
	}
	return "";
}


Relative_Error :: enum {
	None,

	Cannot_Relate,
}

rel :: proc(base_path, target_path: string, allocator := context.allocator) -> (string, Relative_Error) {
	context.allocator = allocator;
	base_vol, target_vol := volume_name(base_path), volume_name(target_path);
	base, target := clean(base_path), clean(target_path);

	delete_target := true;
	defer {
		if delete_target {
			delete(target);
		}
		delete(base);
	}

	if strings.equal_fold(target, base) {
		return strings.clone("."), .None;
	}

	base = base[len(base_vol):];
	target = target[len(target_vol):];
	if base == "." {
		base = "";
	}

	base_slashed := len(base) > 0 && base[0] == SEPARATOR;
	target_slashed := len(target) > 0 && target[0] == SEPARATOR;
	if base_slashed != target_slashed || !strings.equal_fold(base_vol, target_vol) {
		return "", .Cannot_Relate;
	}

	bl, tl := len(base), len(target);
	b0, bi, t0, ti: int;
	for {
		for bi < bl && base[bi] != SEPARATOR {
			bi += 1;
		}
		for ti < tl && target[ti] != SEPARATOR {
			ti += 1;
		}
		if !strings.equal_fold(target[t0:ti], base[b0:bi]) {
			break;
		}
		if bi < bl {
			bi += 1;
		}
		if ti < tl {
			ti += 1;
		}
		b0, t0 = bi, ti;
	}

	if base[b0:bi] == ".." {
		return "", .Cannot_Relate;
	}

	if b0 != bl {
		seps := strings.count(base[b0:bl], SEPARATOR_STRING);
		size := 2 + seps*3;
		if tl != t0 {
			size += 1 + tl - t0;
		}
		buf := make([]byte, size);
		n := copy(buf, "..");
		for in 0..<seps {
			buf[n] = SEPARATOR;
			copy(buf[n+1:], "..");
			n += 3;
		}
		if t0 != tl {
			buf[n] = SEPARATOR;
			copy(buf[n+1:], target[t0:]);
		}
		return string(buf), .None;
	}

	delete_target = false;
	return target[t0:], .None;
}

dir :: proc(path: string, allocator := context.allocator) -> string {
	vol := volume_name(path);
	i := len(path) - 1;
	for i >= len(vol) && !is_separator(path[i]) {
		i -= 1;
	}
	dir := clean(path[len(vol) : i+1], allocator);
	defer delete(dir, allocator);
	if dir == "." && len(vol) > 2 {
		return strings.clone(vol);
	}
	return strings.concatenate({vol, dir});
}



split_list :: proc(path: string, allocator := context.allocator) -> []string {
	if path == "" {
		return nil;
	}

	start: int;
	quote: bool;

	start, quote = 0, false;
	count := 0;

	for i := 0; i < len(path); i += 1 {
		c := path[i];
		switch {
		case c == '"':
			quote = !quote;
		case c == LIST_SEPARATOR && !quote:
			count += 1;
		}
	}

	start, quote = 0, false;
	list := make([]string, count, allocator);
	index := 0;
	for i := 0; i < len(path); i += 1 {
		c := path[i];
		switch {
		case c == '"':
			quote = !quote;
		case c == LIST_SEPARATOR && !quote:
			list[index] = path[start:i];
			index += 1;
			start = i + 1;
		}
	}
	assert(index == count);

	for s0, i in list {
		s, new := strings.replace_all(s0, `"`, ``, allocator);
		if !new {
			s = strings.clone(s, allocator);
		}
		list[i] = s;
	}

	return list;
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
