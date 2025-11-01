// Process paths using either forward slashes or backslashes depending on the operating system.
// To process paths such as URLs that depend on forward slashes regardless of the OS, use the slashpath package.
package filepath

import    "base:runtime"
import os "core:os/os2"
import    "core:strings"

SEPARATOR_CHARS :: `/\`

// is_separator checks whether the byte is a valid separator character
is_separator :: os.is_path_separator

@(private)
is_slash :: proc(c: byte) -> bool {
	return c == '\\' || c == '/'
}

/*
	In Windows, returns `true` if `path` is one of the following:
	"CON", "PRN", "AUX", "NUL",
	"COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
	"LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",

	On other platforms, returns `false`.
*/
is_reserved_name :: os.is_reserved_name

// Splits path immediate following the last separator; separating the path into a directory and file.
// If no separator is found, `dir` will be empty and `path` set to `path`.
split :: os.split_path


/*
Join all `elems` with the system's path separator and normalize the result.

*Allocates Using Provided Allocator*

For example, `join_path({"/home", "foo", "bar.txt"})` will result in `"/home/foo/bar.txt"`.
*/
join :: os.join_path

/*
	Returns leading volume name.

	e.g.
	  "C:\foo\bar\baz" will return "C:" on Windows.
	  Everything else will be "".
*/
volume_name :: os.volume_name

/*
	Gets the file name and extension from a path.

	e.g.
	  'path/to/name.tar.gz' -> 'name.tar.gz'
	  'path/to/name.txt'    -> 'name.txt'
	  'path/to/name'        -> 'name'

	Returns "." if the path is an empty string.
*/
base :: os.base

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
stem :: os.stem

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
short_stem :: os.short_stem

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
ext :: os.ext

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
long_ext :: os.long_ext

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
clean :: os.clean_path

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
	base_clean, base_err     := clean(base_path,   allocator)
	if base_err   != nil { return "", .Cannot_Relate}
	target_clean, target_err := clean(target_path, allocator)
	if target_err != nil { return "", .Cannot_Relate}
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
	dir, dir_err := clean(path[len(vol) : i+1], allocator)
	if dir_err != nil { return "" }
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