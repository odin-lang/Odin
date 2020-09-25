package path

import "core:strings"
import "core:runtime"
import "core:unicode/utf8"

// is_separator_byte checks whether the byte is a valid separator character
is_separator_byte :: proc(c: byte) -> bool {
	switch c {
	case '/':  return true;
	case '\\': return ODIN_OS == "windows";
	}
	return false;
}


// is_abs checks whether the path is absolute
is_abs :: proc(path: string) -> bool {
	if len(path) > 0 && path[0] == '/' {
		return true;
	}
	when ODIN_OS == "windows" {
		if len(path) > 2 {
			switch path[0] {
			case 'A'..'Z', 'a'..'z':
				return path[1] == ':' && is_separator_byte(path[2]);
			}
		}
	}
	return false;
}


// base returns the last element of path
// Trailing slashes are removed
// If the path is empty, it returns ".".
// If the path is all slashes, it returns "/"
base :: proc(path: string, new := false, allocator := context.allocator) -> (last_element: string) {
	defer if new {
		last_element = strings.clone(last_element, allocator);
	}

	if path == "" {
		last_element = ".";
		return;
	}


	path := path;

	for len(path) > 0 && is_separator_byte(path[len(path)-1]) {
		path = path[:len(path)-1];
	}
	if i := strings.last_index_any(path, OS_SEPARATORS); i >= 0 {
		path = path[i+1:];
	}

	if path == "" {
		last_element = "/";
	} else {
		last_element = path;
	}
	return;
}

// dir returns all but the last element of path, typically the path's directory.
// After dropping the final element using it, the path is cleaned and trailing slashes are removed
// If the path is empty, it returns "."
// If the path consists entirely of slashes followed by non-slash bytes, it returns a single slash
// In any other case, the returned path does not end in a slash
dir :: proc(path: string, allocator := context.allocator) -> string {
	directory, _ := split(path);
	return clean(directory, allocator);
}


// split splits path immediately following the last slash,
// separating it into a directory and file name component.
// If there is no slash in path, it returns an empty dir and file set to path
// The returned values have the property that path = dir+file
split :: proc(path: string) -> (dir, file: string) {
	i := strings.last_index_any(path, OS_SEPARATORS);
	return path[:i+1], path[i+1:];
}

// split_elements splits the path elements into slices of the original path string
split_elements :: proc(path: string, allocator := context.allocator) -> []string {
	return strings.split_multi(path, OS_SEPARATORS_ARRAY, true, allocator);
}

// clean returns the shortest path name equivalent to path through lexical analysis only
// It applies the following rules iterative until done:
//
//	1) replace multiple slashes with one
//	2) remove each . path name element
//	3) remove inner .. path name element
//	4) remove .. that  begin a rooted path ("/.." becomes "/")
//
clean :: proc(path: string, allocator := context.allocator) -> string {
	context.allocator = allocator;

	if path == "" {
		return strings.clone(".");
	}

	// NOTE(bill): do not use is_separator_byte because window paths do not follow this convention
	rooted := path[0] == '/';
	n := len(path);

	out := &Lazy_Buffer{s = path};

	// Check for ../../.. prefixes
	r, dot_dot := 0, 0;
	if rooted {
		lazy_buffer_append(out, '/');
		r, dot_dot = 1, 1;
	}

	for r < n {
		switch {
		case is_separator_byte(path[r]):
			r += 1;
		case path[r] == '.' && (r+1 == n || is_separator_byte(path[r+1])):
			r += 1;
		case path[r] == '.' && path[r+1] == '.' && (r+2 == n || is_separator_byte(path[r+2])):
			r += 2;
			switch {
			case out.w > dot_dot:
				out.w -= 1;
				for out.w > dot_dot && !is_separator_byte(lazy_buffer_index(out, out.w)) {
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
			for ; r < n && !is_separator_byte(path[r]); r += 1 {
				lazy_buffer_append(out, path[r]);
			}
		}
	}

	if out.w == 0 {
		delete(out.b);
		return strings.clone(".");
	}

	return lazy_buffer_string(out);
}

// join joins numerous path elements into a single path
join :: proc(elems: ..string, allocator := context.allocator) -> string {
	context.allocator = allocator;
	for elem, i in elems {
		if elem != "" {
			s := strings.join(elems[i:], "/");
			return clean(s);
		}
	}
	return "";
}

// ext returns the file name extension used by "path"
// The extension is the suffix beginning at the file fot in the last slash separated element of "path"
// The path is empty if there is no dot
ext :: proc(path: string, new := false, allocator := context.allocator) -> string {
	for i := len(path)-1; i >= 0 && !is_separator_byte(path[i]); i -= 1 {
		if path[i] == '.' {
			res := path[i:];
			if new {
				res = strings.clone(res, allocator);
			}
			return res;
		}
	}
	return "";
}

// name returns the file without the base and without the extension
name :: proc(path: string, new := false, allocator := context.allocator) -> (name: string) {
	_, file := split(path);
	name = file;

	defer if new {
		name = strings.clone(name, allocator);
	}

	for i := len(file)-1; i >= 0 && !is_separator_byte(file[i]); i -= 1 {
		if file[i] == '.' {
			name = file[:i];
			return;
		}
	}
	return file;

}



rel :: proc{rel_between, rel_current};

// returns the relative path from one path to another
rel_between :: proc(from, to: string, allocator := context.allocator) -> string {
	if from == "" || to == "" {
		return "";
	}

	from, to := from, to;
	from = full(from, context.temp_allocator);
	to   = full(to,   context.temp_allocator);

	from_is_dir := is_dir(from);
	to_is_dir   := is_dir(to);

	index, slash := 0, 0;

	for {
		if index >= len(from) {
			if index >= len(to) || (from_is_dir && index < len(to) && (to[index] == '/' || to[index] == '\\')) {
				slash = index;
			}

			break;
		}
		else if index >= len(to) {
			if index >= len(from) || (to_is_dir && index < len(from) && (from[index] == '/' || from[index] == '\\')) {
				slash = index;
			}

			break;
		}

		lchar, skip := utf8.decode_rune_in_string(from[index:]);
		rchar, _    := utf8.decode_rune_in_string(to[index:]);

		if (lchar == '/' || lchar == '\\') && (rchar == '/' || lchar == '\\') {
			slash = index;
		}
		else if lchar != rchar {
			break;
		}

		index += skip;
	}

	if slash < 1 {
		// there is no common path, use the absolute `to` path
		return strings.clone(to, allocator);
	}

	from_slashes, to_slashes := 0, 0;

	if slash < len(from) {
		from = from[slash+1:];

		if from_is_dir {
			from_slashes += 1;
		}
	}
	else {
		from = "";
	}

	if slash < len(to) {
		to = to[slash+1:];

		if to_is_dir {
			to_slashes += 1;
		}
	}
	else {
		to = "";
	}

	for char in from {
		if char == '/' || char == '\\' {
			from_slashes += 1;
		}
	}

	for char in to {
		if char == '/' || char == '\\' {
			to_slashes += 1;
		}
	}

	if from_slashes == 0 {
		buffer := make([]byte, 2 + len(to), allocator);

		buffer[0] = '.';
		buffer[1] = '/';
		copy(buffer[2:], to);

		return string(buffer);
	}
	else {
		buffer := make([]byte, from_slashes*3 + len(to), allocator);

		for i in 0..<from_slashes {
			buffer[i*3+0] = '.';
			buffer[i*3+1] = '.';
			buffer[i*3+2] = '/';
		}

		copy(buffer[from_slashes*3:], to);

		return string(buffer);
	}

	return "";
}

// returns the relative path from the current directory to another path
rel_current :: proc(to: string, allocator := context.allocator) -> string {
	return rel_between(current(context.allocator), to, allocator);
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
		return strings.clone(lb.s[:lb.w]);
	}
	return string(lb.b[:lb.w]);
}
