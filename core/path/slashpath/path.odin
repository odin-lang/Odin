// The slashpath package is only to be used for paths separated by forward slashes,
// e.g. paths in URLs.
//
// This package does not deal with Windows/NT paths with volume letters or backslashes.
// To manipulate operating system specific paths, use the path/filepath package.
package slashpath

import "core:strings"

// `is_separator` checks whether the byte is a valid separator character.
//
// Valid separator characters are: `/`.
is_separator :: proc(c: byte) -> bool {
	return c == '/'
}


// `is_abs` checks whether the path is absolute.
//
// Examples: <br>
//     `"/usr/bin/hello"` will return `true` <br>
//     `"./bin/hello"` will return `false` <br>
is_abs :: proc(path: string) -> bool {
	return len(path) > 0 && path[0] == '/'
}


// `base` returns the last element of path.
// Trailing slashes are removed.
//
// If `new` is `true`, a new string will be allocated and returned.
// Otherwise, a slice into the original string will be returned.
//
// Examples: <br>
//     `""` will produce `"."` <br>
//     `"//////"` (all slashes) will produce `"/"` <br>
//     `"/path/to/something/"` will produce `"something"` <br>
//     `"/path/to/something.exe"` will produce `"something.exe"` <br>
base :: proc(path: string, new := false, allocator := context.allocator) -> (last_element: string) {
	defer if new {
		last_element = strings.clone(last_element, allocator)
	}

	if path == "" {
		last_element = "."
		return
	}


	path := path

	for len(path) > 0 && is_separator(path[len(path)-1]) {
		path = path[:len(path)-1]
	}
	if i := strings.last_index(path, "/"); i >= 0 {
		path = path[i+1:]
	}

	if path == "" {
		last_element = "/"
	} else {
		last_element = path
	}
	return
}

// `dir` returns all but the last element of the path, typically the path's directory.
// After removing the final element, the path is cleaned and trailing slashes are removed.
//
// Examples: <br>
//     `""` will produce `"."` <br>
//     `"//////"` (all slashes) will produce `"/"` <br>
//     `"/abc"` will produce `"/"` <br>
//     `"/path/to/something/"` will produce `"path/to/something"` <br>
//     `"/path/to/something.exe"` will produce `"path/to"` <br>
dir :: proc(path: string, allocator := context.allocator) -> string {
	directory, _ := split(path)
	return clean(directory, allocator)
}


// `split` splits the path immediately following the last slash,
// separating it into a directory and file name component.
//
// The returned values have the property that `path = dir+file`.
//
// Examples: <br>
//     `""` will produce `dir="", file=""` <br>
//     `"abc"` will produce `dir="", file="abc"` <br>
//     `"abc/"` will produce `dir="abc/", file=""` <br>
//     `"/path/to/something"` will produce `dir="/path/to/", file="something"` <br>
split :: proc(path: string) -> (dir, file: string) {
	i := strings.last_index(path, "/")
	return path[:i+1], path[i+1:]
}

// `split_elements` splits the path elements into slices of the original path string.
//
// Examples: <br>
//     `""` will produce `[""]` <br>
//     `"abc"` will produce `["abc"]` <br>
//     `"/path/to/something"` will produce `["", "path", "to", "something"]` <br>
split_elements :: proc(path: string, allocator := context.allocator) -> []string {
	return strings.split(path, "/", allocator)
}

// `clean` returns the shortest path name equivalent to `path` through lexical analysis only.
//
// It applies the following rules iteratively until done: <br>
// 1) replace multiple slashes with one (`"/path//to///something"` becomes `"/path/to/something"`) <br>
// 2) remove each `.` path name element (`"/path/./to/././something"` becomes `"/path/to/something"`) <br>
// 3) remove inner `..` path name element (`"/path/to/../something"` becomes `"/path/something"`) <br>
// 4) remove `..` that begins a rooted path (`"/.."` becomes `"/"`) <br>
//
clean :: proc(path: string, allocator := context.allocator) -> string {
	context.allocator = allocator

	if path == "" {
		return strings.clone(".")
	}

	// NOTE(bill): do not use is_separator because window paths do not follow this convention
	rooted := path[0] == '/'
	n := len(path)

	out := &Lazy_Buffer{s = path}

	// Check for ../../.. prefixes
	r, dot_dot := 0, 0
	if rooted {
		lazy_buffer_append(out, '/')
		r, dot_dot = 1, 1
	}

	for r < n {
		switch {
		case is_separator(path[r]):
			r += 1
		case path[r] == '.' && (r+1 == n || is_separator(path[r+1])):
			r += 1
		case path[r] == '.' && path[r+1] == '.' && (r+2 == n || is_separator(path[r+2])):
			r += 2
			switch {
			case out.w > dot_dot:
				out.w -= 1
				for out.w > dot_dot && !is_separator(lazy_buffer_index(out, out.w)) {
					out.w -= 1
				}

			case !rooted:
				if out.w > 0 {
					lazy_buffer_append(out, '/')
				}
				lazy_buffer_append(out, '.')
				lazy_buffer_append(out, '.')
				dot_dot = out.w
			}
		case:
			if rooted && out.w != 1 || !rooted && out.w != 0 {
				lazy_buffer_append(out, '/')
			}
			for ; r < n && !is_separator(path[r]); r += 1 {
				lazy_buffer_append(out, path[r])
			}
		}
	}

	if out.w == 0 {
		delete(out.b)
		return strings.clone(".")
	}

	return lazy_buffer_string(out)
}

// `join` joins numerous path elements into a single path.
//
// Examples: <br>
//     `["path", "to", "something"]` will produce `"path/to/something"` <br>
//     `["/", "path", "to", "something"]` will produce `"/path/to/something"` <br>
join :: proc(elems: ..string, allocator := context.allocator) -> string {
	context.allocator = allocator
	for elem, i in elems {
		if elem != "" {
			s := strings.join(elems[i:], "/", context.temp_allocator)
			return clean(s)
		}
	}
	return ""
}

// `ext` returns the file name extension used by `path`.
//
// The extension is the suffix beginning at (and including) the dot in the last slash-separated element of `path`.
//
// If `new` is `true`, a new string will be allocated and returned.
// Otherwise, a slice into the original string will be returned.
//
// Examples: <br>
//     `""` will produce `""` <br>
//     `"/path/to/something"` will produce `""` <br>
//     `"/path/to/something.exe"` will produce `".exe"` <br>
ext :: proc(path: string, new := false, allocator := context.allocator) -> string {
	for i := len(path)-1; i >= 0 && !is_separator(path[i]); i -= 1 {
		if path[i] == '.' {
			res := path[i:]
			if new {
				res = strings.clone(res, allocator)
			}
			return res
		}
	}
	return ""
}

// `name` returns the file without the base and without the extension.
//
// If `new` is `true`, a new string will be allocated and returned.
// Otherwise, a slice into the original string will be returned.
//
// Examples: <br>
//     `""` will produce `""` <br>
//     `"/path/to/something"` will produce `"something"` <br>
//     `"/path/to/something.exe"` will produce `"something"` <br>
name :: proc(path: string, new := false, allocator := context.allocator) -> (name: string) {
	_, file := split(path)
	name = file

	defer if new {
		name = strings.clone(name, allocator)
	}

	for i := len(file)-1; i >= 0 && !is_separator(file[i]); i -= 1 {
		if file[i] == '.' {
			name = file[:i]
			return
		}
	}
	return file

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
		return lb.b[i]
	}
	return lb.s[i]
}
@(private)
lazy_buffer_append :: proc(lb: ^Lazy_Buffer, c: byte) {
	if lb.b == nil {
		if lb.w < len(lb.s) && lb.s[lb.w] == c {
			lb.w += 1
			return
		}
		lb.b = make([]byte, len(lb.s))
		copy(lb.b, lb.s[:lb.w])
	}
	lb.b[lb.w] = c
	lb.w += 1
}
@(private)
lazy_buffer_string :: proc(lb: ^Lazy_Buffer) -> string {
	if lb.b == nil {
		return strings.clone(lb.s[:lb.w])
	}
	return string(lb.b[:lb.w])
}
