// The path/filepath package uses either forward slashes or backslashes depending on the operating system
// To process paths such as URLs that depend on forward slashes regardless of the OS, use the path package
package filepath

import "base:runtime"
import "core:strings"

SEPARATOR_CHARS :: `/\`

// is_separator checks whether the byte is a valid separator character
is_separator :: proc(c: byte) -> bool {
	switch c {
	case '/':  return true
	case '\\': return ODIN_OS == .Windows
	}
	return false
}

@(private)
is_slash :: proc(c: byte) -> bool {
	return c == '\\' || c == '/'
}

// Splits path immediate following the last separator; separating the path into a directory and file.
// If no separator is found, `dir` will be empty and `path` set to `path`.
split :: proc(path: string) -> (dir, file: string) {
	vol := volume_name(path)
	i := len(path) - 1
	for i >= len(vol) && !is_separator(path[i]) {
		i -= 1
	}
	return path[:i+1], path[i+1:]
}

/*
	Returns leading volume name.

	e.g.
	  "C:\foo\bar\baz" will return "C:" on Windows.
	  Everything else will be "".
*/
volume_name :: proc(path: string) -> string {
	return path[:volume_name_len(path)]
}

// Returns the length of the volume name in bytes.
volume_name_len :: proc(path: string) -> int {
	if ODIN_OS == .Windows {
		if len(path) < 2 {
			return 0
		}
		c := path[0]
		if path[1] == ':' {
			switch c {
			case 'a'..='z', 'A'..='Z':
				return 2
			}
		}

		// URL: https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247(v=vs.85).aspx
		if l := len(path); l >= 5 && is_slash(path[0]) && is_slash(path[1]) &&
			!is_slash(path[2]) && path[2] != '.' {
			for n := 3; n < l-1; n += 1 {
				if is_slash(path[n]) {
					n += 1
					if !is_slash(path[n]) {
						if path[n] == '.' {
							break
						}
					}
					for ; n < l; n += 1 {
						if is_slash(path[n]) {
							break
						}
					}
					return n
				}
				break
			}
		}
	}
	return 0
}

/*
	Gets the file name and extension from a path.

	e.g.
	  'path/to/name.tar.gz' -> 'name.tar.gz'
	  'path/to/name.txt'    -> 'name.txt'
	  'path/to/name'        -> 'name'

	Returns "." if the path is an empty string.
*/
base :: proc(path: string) -> string {
	if path == "" {
		return "."
	}

	path := path
	for len(path) > 0 && is_separator(path[len(path)-1]) {
		path = path[:len(path)-1]
	}

	path = path[volume_name_len(path):]

	i := len(path)-1
	for i >= 0 && !is_separator(path[i]) {
		i -= 1
	}
	if i >= 0 {
		path = path[i+1:]
	}
	if path == "" {
		return SEPARATOR_STRING
	}
	return path
}

/*
	Gets the name of a file from a path.

	The stem of a file is such that stem(path) + ext(path) = base(path).

	Only the last dot is considered when splitting the file extension.
	See `short_stem`.

	e.g.
	  'name.tar.gz' -> 'name.tar'
	  'name.txt'    -> 'name'

	Returns an empty string if there is no stem. e.g: '.gitignore'.
	Returns an empty string if there's a trailing path separator.
*/
stem :: proc(path: string) -> string {
	if len(path) > 0 && is_separator(path[len(path) - 1]) {
		// NOTE(tetra): Trailing separator
		return ""
	}

	// NOTE(tetra): Get the basename
	path := path
	if i := strings.last_index_any(path, SEPARATOR_CHARS); i != -1 {
		path = path[i+1:]
	}

	if i := strings.last_index_byte(path, '.'); i != -1 {
		return path[:i]
	}

	return path
}

/*
	Gets the name of a file from a path.

	The short stem is such that short_stem(path) + long_ext(path) = base(path).

	The first dot is used to split off the file extension, unlike `stem` which uses the last dot.

	e.g.
	  'name.tar.gz' -> 'name'
	  'name.txt'    -> 'name'

	Returns an empty string if there is no stem. e.g: '.gitignore'.
	Returns an empty string if there's a trailing path separator.
*/
short_stem :: proc(path: string) -> string {
	s := stem(path)
	if i := strings.index_byte(s, '.'); i != -1 {
		return s[:i]
	}
	return s
}

/*
	Gets the file extension from a path, including the dot.

	The file extension is such that stem(path) + ext(path) = base(path).

	Only the last dot is considered when splitting the file extension.
	See `long_ext`.

	e.g.
	  'name.tar.gz' -> '.gz'
	  'name.txt'    -> '.txt'

	Returns an empty string if there is no dot.
	Returns an empty string if there is a trailing path separator.
*/
ext :: proc(path: string) -> string {
	for i := len(path)-1; i >= 0 && !is_separator(path[i]); i -= 1 {
		if path[i] == '.' {
			return path[i:]
		}
	}
	return ""
}

/*
	Gets the file extension from a path, including the dot.

	The long file extension is such that short_stem(path) + long_ext(path) = base(path).

	The first dot is used to split off the file extension, unlike `ext` which uses the last dot.

	e.g.
	  'name.tar.gz' -> '.tar.gz'
	  'name.txt'    -> '.txt'

	Returns an empty string if there is no dot.
	Returns an empty string if there is a trailing path separator.
*/
long_ext :: proc(path: string) -> string {
	if len(path) > 0 && is_separator(path[len(path) - 1]) {
		// NOTE(tetra): Trailing separator
		return ""
	}

	// NOTE(tetra): Get the basename
	path := path
	if i := strings.last_index_any(path, SEPARATOR_CHARS); i != -1 {
		path = path[i+1:]
	}

	if i := strings.index_byte(path, '.'); i != -1 {
		return path[i:]
	}

	return ""
}

/*
	Returns the shortest path name equivalent to `path` through solely lexical processing.
	It applies the folliwng rules until none of them can be applied:

	* Replace multiple separators with a single one
	* Remove each current directory (`.`) path name element
	* Remove each inner parent directory (`..`) path and the preceding paths
	* Remove `..` that begin at the root of a path
	* All possible separators are replaced with the OS specific separator

	The return path ends in a slash only if it represents the root of a directory (`C:\` on Windows and  `/` on *nix systems).

	If the result of the path is an empty string, the returned path with be `"."`.

*/
clean :: proc(path: string, allocator := context.allocator) -> (cleaned: string, err: runtime.Allocator_Error) #optional_allocator_error {
	context.allocator = allocator

	path := path
	original_path := path
	vol_len := volume_name_len(path)
	path = path[vol_len:]

	if path == "" {
		if vol_len > 1 && original_path[1] != ':' {
			s, ok := from_slash(original_path)
			if !ok {
				s = strings.clone(s) or_return
			}
			return s, nil
		}
		return strings.concatenate({original_path, "."})
	}

	rooted := is_separator(path[0])

	n := len(path)
	out := &Lazy_Buffer{
		s = path,
		vol_and_path = original_path,
		vol_len = vol_len,
	}
	defer lazy_buffer_destroy(out)

	r, dot_dot := 0, 0
	if rooted {
		lazy_buffer_append(out, SEPARATOR) or_return
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
					lazy_buffer_append(out, SEPARATOR) or_return
				}
				lazy_buffer_append(out, '.') or_return
				lazy_buffer_append(out, '.') or_return
				dot_dot = out.w
			}
		case:
			if rooted && out.w != 1 || !rooted && out.w != 0 {
				lazy_buffer_append(out, SEPARATOR) or_return
			}
			for ; r < n && !is_separator(path[r]); r += 1 {
				lazy_buffer_append(out, path[r]) or_return
			}

		}
	}

	if out.w == 0 {
		lazy_buffer_append(out, '.') or_return
	}

	s := lazy_buffer_string(out) or_return

	new_allocation: bool
	cleaned, new_allocation = from_slash(s)
	if new_allocation {
		delete(s)
	}
	return
}

// Returns the result of replacing each forward slash `/` character in the path with the separate OS specific character.
from_slash :: proc(path: string, allocator := context.allocator) -> (new_path: string, new_allocation: bool) {
	if SEPARATOR == '/' {
		return path, false
	}
	return strings.replace_all(path, "/", SEPARATOR_STRING, allocator)
}

// Returns the result of replacing each OS specific separator with a forward slash `/` character.
to_slash :: proc(path: string, allocator := context.allocator) -> (new_path: string, new_allocation: bool) {
	if SEPARATOR == '/' {
		return path, false
	}
	return strings.replace_all(path, SEPARATOR_STRING, "/", allocator)
}


Relative_Error :: enum {
	None,

	Cannot_Relate,
}

/*
	Returns a relative path that is lexically equivalent to the `target_path` when joined with the `base_path` with an OS specific separator.

	e.g. `join(base_path, rel(base_path, target_path))` is equivalent to `target_path`

	On failure, the `Relative_Error` will be state it cannot compute the necessary relative path.
*/
rel :: proc(base_path, target_path: string, allocator := context.allocator) -> (string, Relative_Error) {
	context.allocator = allocator
	base_clean   := clean(base_path,   allocator)
	target_clean := clean(target_path, allocator)
	defer delete(base_clean,   allocator)
	defer delete(target_clean, allocator)

	if strings.equal_fold(target_clean, base_clean) {
		return strings.clone(".", allocator), .None
	}

	base_vol   := volume_name(base_path)
	target_vol := volume_name(target_path)
	base   := base_clean  [len(base_vol):]
	target := target_clean[len(target_vol):]
	if base == "." {
		base = ""
	}

	base_slashed   := len(base)   > 0 && base  [0] == SEPARATOR
	target_slashed := len(target) > 0 && target[0] == SEPARATOR
	if base_slashed != target_slashed || !strings.equal_fold(base_vol, target_vol) {
		return "", .Cannot_Relate
	}

	bl, tl := len(base), len(target)
	b0, bi, t0, ti: int
	for {
		for bi < bl && base[bi] != SEPARATOR {
			bi += 1
		}
		for ti < tl && target[ti] != SEPARATOR {
			ti += 1
		}
		strings.equal_fold(target[t0:ti], base[b0:bi]) or_break

		if bi < bl {
			bi += 1
		}
		if ti < tl {
			ti += 1
		}
		b0, t0 = bi, ti
	}

	if base[b0:bi] == ".." {
		return "", .Cannot_Relate
	}

	if b0 != bl {
		seps := strings.count(base[b0:bl], SEPARATOR_STRING)
		size := 2 + seps*3
		if tl != t0 {
			size += 1 + tl - t0
		}
		buf := make([]byte, size, allocator)
		n := copy(buf, "..")
		for _ in 0..<seps {
			buf[n] = SEPARATOR
			copy(buf[n+1:], "..")
			n += 3
		}
		if t0 != tl {
			buf[n] = SEPARATOR
			copy(buf[n+1:], target[t0:])
		}
		return string(buf), .None
	}

	return strings.clone(target[t0:], allocator), .None
}

/*
	Returns all but the last element path, usually the path's directory. Once the final element has been removed,
	`dir` calls `clean` on the path and trailing separators are removed. If the path consists purely of separators,
	then `"."` is returned.
*/
dir :: proc(path: string, allocator := context.allocator) -> string {
	context.allocator = allocator
	vol := volume_name(path)
	i := len(path) - 1
	for i >= len(vol) && !is_separator(path[i]) {
		i -= 1
	}
	dir := clean(path[len(vol) : i+1])
	defer delete(dir)
	if dir == "." && len(vol) > 2 {
		return strings.clone(vol)
	}
	return strings.concatenate({vol, dir})
}



// Splits the PATH-like `path` string, returning an array of its separated components (delete after use).
// For Windows the separator is `;`, for Unix it's  `:`.
// An empty string returns nil. A non-empty string with no separators returns a 1-element array.
// Any empty components will be included, e.g. `a::b` will return a 3-element array, as will `::`.
// Separators within pairs of double-quotes will be ignored and stripped, e.g. `"a:b"c:d` will return []{`a:bc`, `d`}.
split_list :: proc(path: string, allocator := context.allocator) -> (list: []string, err: runtime.Allocator_Error) #optional_allocator_error {
	if path == "" {
		return nil, nil
	}

	start: int
	quote: bool

	start, quote = 0, false
	count := 0

	for i := 0; i < len(path); i += 1 {
		c := path[i]
		switch {
		case c == '"':
			quote = !quote
		case c == LIST_SEPARATOR && !quote:
			count += 1
		}
	}

	start, quote = 0, false
	list = make([]string, count + 1, allocator) or_return
	index := 0
	for i := 0; i < len(path); i += 1 {
		c := path[i]
		switch {
		case c == '"':
			quote = !quote
		case c == LIST_SEPARATOR && !quote:
			list[index] = path[start:i]
			index += 1
			start = i + 1
		}
	}
	assert(index == count)
	list[index] = path[start:]

	for s0, i in list {
		s, new := strings.replace_all(s0, `"`, ``, allocator)
		if !new {
			s = strings.clone(s, allocator) or_return
		}
		list[i] = s
	}

	return list, nil
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
		return lb.b[i]
	}
	return lb.s[i]
}
@(private)
lazy_buffer_append :: proc(lb: ^Lazy_Buffer, c: byte) -> (err: runtime.Allocator_Error) {
	if lb.b == nil {
		if lb.w < len(lb.s) && lb.s[lb.w] == c {
			lb.w += 1
			return
		}
		lb.b = make([]byte, len(lb.s)) or_return
		copy(lb.b, lb.s[:lb.w])
	}
	lb.b[lb.w] = c
	lb.w += 1
	return
}
@(private)
lazy_buffer_string :: proc(lb: ^Lazy_Buffer) -> (s: string, err: runtime.Allocator_Error) {
	if lb.b == nil {
		return strings.clone(lb.vol_and_path[:lb.vol_len+lb.w])
	}

	x := lb.vol_and_path[:lb.vol_len]
	y := string(lb.b[:lb.w])
	z := make([]byte, len(x)+len(y)) or_return
	copy(z, x)
	copy(z[len(x):], y)
	return string(z), nil
}
@(private)
lazy_buffer_destroy :: proc(lb: ^Lazy_Buffer) -> runtime.Allocator_Error {
	err := delete(lb.b)
	lb^ = {}
	return err
}
