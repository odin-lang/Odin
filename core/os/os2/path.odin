package os2

import "base:runtime"
import "core:slice"
import "core:strings"
import "core:unicode/utf8"


Path_Separator        :: _Path_Separator        // OS-Specific
Path_Separator_String :: _Path_Separator_String // OS-Specific
Path_Separator_Chars  :: `/\`
Path_List_Separator   :: _Path_List_Separator   // OS-Specific

#assert(_Path_Separator <= rune(0x7F), "The system-specific path separator rune is expected to be within the 7-bit ASCII character set.")

/*
Return true if `c` is a character used to separate paths into directory and
file hierarchies on the current system.
*/
@(require_results)
is_path_separator :: proc(c: byte) -> bool {
	return _is_path_separator(c)
}

/*
Returns the result of replacing each path separator character in the path
with the `new_sep` rune.

*Allocates Using Provided Allocator*
*/
replace_path_separators :: proc(path: string, new_sep: rune, allocator: runtime.Allocator) -> (new_path: string, err: Error) {
	buf := make([]u8, len(path), allocator) or_return

	i: int
	for r in path {
		replacement := r
		if r == '/' || r == '\\' {
			replacement = new_sep
		}

		if replacement <= rune(0x7F) {
			buf[i] = u8(replacement)
			i += 1
		} else {
			b, w := utf8.encode_rune(r)
			copy(buf[i:], b[:w])
			i += w
		}
	}
	return string(buf), nil
}

mkdir :: make_directory

/*
Make a new directory.

If `path` is relative, it will be relative to the process's current working directory.
*/
make_directory :: proc(name: string, perm: int = 0o755) -> Error {
	return _mkdir(name, perm)
}

mkdir_all :: make_directory_all

/*
Make a new directory, creating new intervening directories when needed.

If `path` is relative, it will be relative to the process's current working directory.
*/
make_directory_all :: proc(path: string, perm: int = 0o755) -> Error {
	return _mkdir_all(path, perm)
}

/*
Delete `path` and all files and directories inside of `path` if it is a directory.

If `path` is relative, it will be relative to the process's current working directory.
*/
remove_all :: proc(path: string) -> Error {
	return _remove_all(path)
}

getwd :: get_working_directory

/*
Get the working directory of the current process.

*Allocates Using Provided Allocator*
*/
@(require_results)
get_working_directory :: proc(allocator: runtime.Allocator) -> (dir: string, err: Error) {
	return _get_working_directory(allocator)
}

setwd :: set_working_directory

/*
Change the working directory of the current process.

*Allocates Using Provided Allocator*
*/
set_working_directory :: proc(dir: string) -> (err: Error) {
	return _set_working_directory(dir)
}

/*
Get the path for the currently running executable.

*Allocates Using Provided Allocator*
*/
@(require_results)
get_executable_path :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	return _get_executable_path(allocator)
}

/*
Get the directory for the currently running executable.

*Allocates Using Provided Allocator*
*/
@(require_results)
get_executable_directory :: proc(allocator: runtime.Allocator) -> (path: string, err: Error) {
	path = _get_executable_path(allocator) or_return
	path, _ = split_path(path)
	return
}

/*
Compare two paths for exactness without normalization.

This procedure takes into account case-sensitivity on differing systems.
*/
@(require_results)
are_paths_identical :: proc(a, b: string) -> (identical: bool) {
	return _are_paths_identical(a, b)
}

/*
Normalize a path.

*Allocates Using Provided Allocator*

This will remove duplicate separators and unneeded references to the current or
parent directory.
*/
@(require_results)
clean_path :: proc(path: string, allocator: runtime.Allocator) -> (cleaned: string, err: Error) {
	if path == "" || path == "." {
		return strings.clone(".", allocator)
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })

	// The extra byte is to simplify appending path elements by letting the
	// loop to end each with a separator. We'll trim the last one when we're done.
	buffer := make([]u8, len(path) + 1, temp_allocator) or_return

	// This is the only point where Windows and POSIX differ, as Windows has
	// alphabet-based volumes for root paths.
	rooted, start := _clean_path_handle_start(path, buffer)

	head, buffer_i := start, start
	for i, j := start, start; i <= len(path); i += 1 {
		if i == len(path) || _is_path_separator(path[i]) {
			elem := path[j:i]
			j = i + 1

			switch elem {
			case "", ".":
				// Skip duplicate path separators and current directory references.
			case "..":
				if !rooted && buffer_i == head {
					// Only allow accessing further parent directories when the path is relative.
					buffer[buffer_i] = '.'
					buffer[buffer_i+1] = '.'
					buffer[buffer_i+2] = _Path_Separator
					buffer_i += 3
					head = buffer_i
				} else {
					// Roll back to the last separator or the head of the buffer.
					back_to := head
					// `buffer_i` will be equal to 1 + the last set byte, so
					// skipping two bytes avoids the final separator we just
					// added.
					for k := buffer_i-2; k >= head; k -= 1 {
						if _is_path_separator(buffer[k]) {
							back_to = k + 1
							break
						}
					}
					buffer_i = back_to
				}
			case:
				// Copy the path element verbatim and add a separator.
				copy(buffer[buffer_i:], elem)
				buffer_i += len(elem)
				buffer[buffer_i] = _Path_Separator
				buffer_i += 1
			}
		}
	}

	// Trim the final separator.
	// NOTE: No need to check if the last byte is a separator, as we always add it.
	if buffer_i > start {
		buffer_i -= 1
	}

	if buffer_i == 0 {
		return strings.clone(".", allocator)
	}

	compact := make([]u8, buffer_i, allocator) or_return
	copy(compact, buffer) // NOTE(bill): buffer[:buffer_i] is redundant here
	return string(compact), nil
}

/*
Return true if `path` is an absolute path as opposed to a relative one.
*/
@(require_results)
is_absolute_path :: proc(path: string) -> bool {
	return _is_absolute_path(path)
}

/*
Get the absolute path to `path` with respect to the process's current directory.

*Allocates Using Provided Allocator*
*/
@(require_results)
get_absolute_path :: proc(path: string, allocator: runtime.Allocator) -> (absolute_path: string, err: Error) {
	return _get_absolute_path(path, allocator)
}

/*
Get the relative path needed to change directories from `base` to `target`.

*Allocates Using Provided Allocator*

The result is such that `join_path(base, get_relative_path(base, target))` is equivalent to `target`.

NOTE: This procedure expects both `base` and `target` to be normalized first,
which can be done by calling `clean_path` on them if needed.

This procedure will return an `Invalid_Path` error if `base` begins with a
reference to the parent directory (`".."`). Use `get_working_directory` with
`join_path` to construct absolute paths for both arguments instead.
*/
@(require_results)
get_relative_path :: proc(base, target: string, allocator: runtime.Allocator) -> (path: string, err: Error) {
	if _are_paths_identical(base, target) {
		return strings.clone(".", allocator)
	}
	if base == "." {
		return strings.clone(target, allocator)
	}

	// This is the first point where Windows and POSIX differ, as Windows has
	// alphabet-based volumes for root paths.
	if !_get_relative_path_handle_start(base, target) {
		return "", .Invalid_Path
	}
	if strings.has_prefix(base, "..") && (len(base) == 2 || _is_path_separator(base[2])) {
		// We could do the work for the user of getting absolute paths for both
		// arguments, but that could make something costly (repeatedly
		// normalizing paths) convenient, when it would be better for the user
		// to store already-finalized paths and operate on those instead.
		return "", .Invalid_Path
	}

	// This is the other point where Windows and POSIX differ, as Windows is
	// case-insensitive.
	common := _get_common_path_len(base, target)

	// Get the result of splitting `base` and `target` on _Path_Separator,
	// comparing them up to their most common elements, then count how many
	// unshared parts are in the split `base`.
	seps := 0
	size := 0
	if len(base)-common > 0 {
		seps = 1
		size = 2
	}
	// This range skips separators on the ends of the string.
	for i in common+1..<len(base)-1 {
		if _is_path_separator(base[i]) {
			seps += 1
			size += 3
		}
	}

	// Handle the rest of the size calculations.
	trailing := target[common:]
	if len(trailing) > 0 {
		// Account for leading separators on the target after cutting the common part.
		// (i.e. base == `/home`, target == `/home/a`)
		if _is_path_separator(trailing[0]) {
			trailing = trailing[1:]
		}
		size += len(trailing)
		if seps > 0 {
			size += 1
		}
	}
	if trailing == "." {
		trailing = ""
		size -= 2
	}

	// Build the string.
	buf := make([]u8, size, allocator) or_return
	n := 0
	if seps > 0 {
		buf[0] = '.'
		buf[1] = '.'
		n = 2
	}
	for _ in 1..<seps {
		buf[n] = _Path_Separator
		buf[n+1] = '.'
		buf[n+2] = '.'
		n += 3
	}
	if len(trailing) > 0 {
		if seps > 0 {
			buf[n] = _Path_Separator
			n += 1
		}
		copy(buf[n:], trailing)
	}

	path = string(buf)

	return
}

/*
Split a path into a directory hierarchy and a filename.

For example, `split_path("/home/foo/bar.tar.gz")` will return `"/home/foo"` and `"bar.tar.gz"`.
*/
@(require_results)
split_path :: proc(path: string) -> (dir, filename: string) {
	return _split_path(path)
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

	_, file := split_path(path)
	return file
}

/*
Gets the name of a file from a path.

The stem of a file is such that `stem(path)` + `ext(path)` = `base(path)`.

Only the last dot is considered when splitting the file extension.
See `short_stem`.

e.g.
	'name.tar.gz' -> 'name.tar'
	'name.txt'    -> 'name'

Returns an empty string if there is no stem. e.g: '.gitignore'.
Returns an empty string if there's a trailing path separator.
*/
stem :: proc(path: string) -> string {
	if len(path) > 0 {
		if is_path_separator(path[len(path) - 1]) {
			// NOTE(tetra): Trailing separator
			return ""
		} else if path[0] == '.' {
			return ""
		}
	}

	// NOTE(tetra): Get the basename
	path := path
	if i := strings.last_index_any(path, Path_Separator_Chars); i != -1 {
		path = path[i+1:]
	}

	if i := strings.last_index_byte(path, '.'); i != -1 {
		return path[:i]
	}
	return path
}

/*
Gets the name of a file from a path.

The short stem is such that `short_stem(path)` + `long_ext(path)` = `base(path)`,
where `long_ext` is the extension returned by `split_filename_all`.

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

The file extension is such that `stem_path(path)` + `ext(path)` = `base(path)`.

Only the last dot is considered when splitting the file extension.
See `long_ext`.

e.g.
	'name.tar.gz' -> '.gz'
	'name.txt'    -> '.txt'

Returns an empty string if there is no dot.
Returns an empty string if there is a trailing path separator.
*/
ext :: proc(path: string) -> string {
	for i := len(path)-1; i >= 0 && !is_path_separator(path[i]); i -= 1 {
		if path[i] == '.' {
			return path[i:]
		}
	}
	return ""
}

/*
Gets the file extension from a path, including the dot.

The long file extension is such that `short_stem(path)` + `long_ext(path)` = `base(path)`.

The first dot is used to split off the file extension, unlike `ext` which uses the last dot.

e.g.
	'name.tar.gz' -> '.tar.gz'
	'name.txt'    -> '.txt'

Returns an empty string if there is no dot.
Returns an empty string if there is a trailing path separator.
*/
long_ext :: proc(path: string) -> string {
	if len(path) > 0 && is_path_separator(path[len(path) - 1]) {
		// NOTE(tetra): Trailing separator
		return ""
	}

	// NOTE(tetra): Get the basename
	path := path
	if i := strings.last_index_any(path, Path_Separator_Chars); i != -1 {
		path = path[i+1:]
	}

	if i := strings.index_byte(path, '.'); i != -1 {
		return path[i:]
	}

	return ""
}

/*
Join all `elems` with the system's path separator and normalize the result.

*Allocates Using Provided Allocator*

For example, `join_path({"/home", "foo", "bar.txt"})` will result in `"/home/foo/bar.txt"`.
*/
@(require_results)
join_path :: proc(elems: []string, allocator: runtime.Allocator) -> (joined: string, err: Error) {
	for e, i in elems {
		if e != "" {
			temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
			p := strings.join(elems[i:], Path_Separator_String, temp_allocator) or_return
			return clean_path(p, allocator)
		}
	}
	return "", nil
}

/*
Split a filename from its extension.

This procedure splits on the last separator.

If the filename begins with a separator, such as `".readme.txt"`, the separator
will be included in the filename, resulting in `".readme"` and `"txt"`.

For example, `split_filename("foo.tar.gz")` will return `"foo.tar"` and `"gz"`.
*/
@(require_results)
split_filename :: proc(filename: string) -> (base, ext: string) {
	i := strings.last_index_byte(filename, '.')
	if i <= 0 {
		return filename, ""
	}
	return filename[:i], filename[i+1:]
}

/*
Split a filename from its extension.

This procedure splits on the first separator.

If the filename begins with a separator, such as `".readme.txt.gz"`, the separator
will be included in the filename, resulting in `".readme"` and `"txt.gz"`.

For example, `split_filename_all("foo.tar.gz")` will return `"foo"` and `"tar.gz"`.
*/
@(require_results)
split_filename_all :: proc(filename: string) -> (base, ext: string) {
	i := strings.index_byte(filename, '.')
	if i == 0 {
		j := strings.index_byte(filename[1:], '.')
		if j != -1 {
			j += 1
		}
		i = j
	}
	if i == -1 {
		return filename, ""
	}
	return filename[:i], filename[i+1:]
}

/*
Join `base` and `ext` with the system's filename extension separator.

*Allocates Using Provided Allocator*

For example, `join_filename("foo", "tar.gz")` will result in `"foo.tar.gz"`.
*/
@(require_results)
join_filename :: proc(base: string, ext: string, allocator: runtime.Allocator) -> (joined: string, err: Error) {
	if len(base) == 0 {
		return strings.clone(ext, allocator)
	} else if len(ext) == 0 {
		return strings.clone(base, allocator)
	}

	buf := make([]u8, len(base) + 1 + len(ext), allocator) or_return
	copy(buf, base)
	buf[len(base)] = '.'
	copy(buf[1+len(base):], ext)

	return string(buf), nil
}

/*
Split a string that is separated by a system-specific separator, typically used
for environment variables specifying multiple directories.

*Allocates Using Provided Allocator*

For example, there is the "PATH" environment variable on POSIX systems which
this procedure can split into separate entries.
*/
@(require_results)
split_path_list :: proc(path: string, allocator: runtime.Allocator) -> (list: []string, err: Error) {
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
		case c == Path_List_Separator && !quote:
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
		case c == Path_List_Separator && !quote:
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
`match` states whether "name" matches the shell pattern

Pattern syntax is:
	pattern:
		{term}
	term:
		'*'	        matches any sequence of non-/ characters
		'?'             matches any single non-/ character
		'[' ['^']  { character-range } ']'
										character classification (cannot be empty)
		c               matches character c (c != '*', '?', '\\', '[')
		'\\' c          matches character c

	character-range
		c               matches character c (c != '\\', '-', ']')
		'\\' c          matches character c
		lo '-' hi       matches character c for lo <= c <= hi

`match` requires that the pattern matches the entirety of the name, not just a substring.
The only possible error returned is `.Syntax_Error` or an allocation error.

NOTE(bill): This is effectively the shell pattern matching system found
*/
match :: proc(pattern, name: string) -> (matched: bool, err: Error) {
	pattern, name := pattern, name
	pattern_loop: for len(pattern) > 0 {
		star: bool
		chunk: string
		star, chunk, pattern = scan_chunk(pattern)
		if star && chunk == "" {
			return !strings.contains(name, _Path_Separator_String), nil
		}

		t, ok := match_chunk(chunk, name) or_return

		if ok && (len(t) == 0 || len(pattern) > 0) {
			name = t
			continue
		}

		if star {
			for i := 0; i < len(name) && name[i] != _Path_Separator; i += 1 {
				t, ok = match_chunk(chunk, name[i+1:]) or_return
				if ok {
					if len(pattern) == 0 && len(t) > 0 {
						continue
					}
					name = t
					continue pattern_loop
				}
			}
		}

		return false, nil
	}

	return len(name) == 0, nil
}

// glob returns the names of all files matching pattern or nil if there are no matching files
// The syntax of patterns is the same as "match".
// The pattern may describe hierarchical names such as /usr/*/bin (assuming '/' is a separator)
//
// glob ignores file system errors
//
glob :: proc(pattern: string, allocator := context.allocator) -> (matches: []string, err: Error) {
	_split :: proc(path: string) -> (dir, file: string) {
		vol := volume_name(path)
		i := len(path) - 1
		for i >= len(vol) && !is_path_separator(path[i]) {
			i -= 1
		}
		return path[:i+1], path[i+1:]
	}

	context.allocator = allocator

	if !has_meta(pattern) {
		// TODO(bill): os.lstat on here to check for error
		m := make([]string, 1)
		m[0] = pattern
		return m[:], nil
	}

	// NOTE(Jeroen): For `glob`, we need this version of `split`, which leaves the trailing `/` on `dir`.
	dir, file := _split(pattern)

	temp_buf: [8]byte
	vol_len:  int
	vol_len, dir = clean_glob_path(dir, temp_buf[:])

	if !has_meta(dir[vol_len:]) {
		m, e := _glob(dir, file, nil)
		return m[:], e
	}

	m := glob(dir) or_return
	defer {
		for s in m {
			delete(s)
		}
		delete(m)
	}

	dmatches := make([dynamic]string, 0, 0)
	for d in m {
		dmatches, err = _glob(d, file, &dmatches)
		if err != nil {
			break
		}
	}
	if len(dmatches) > 0 {
		matches = dmatches[:]
	}
	return
}

/*
	Returns leading volume name.

	e.g.
		"C:\foo\bar\baz" will return "C:" on Windows.
		Everything else will be "".
*/
volume_name :: proc(path: string) -> string {
	when ODIN_OS == .Windows {
		return path[:_volume_name_len(path)]
	} else {
		return ""
	}
}

@(private="file")
scan_chunk :: proc(pattern: string) -> (star: bool, chunk, rest: string) {
	pattern := pattern
	for len(pattern) > 0 && pattern[0] == '*' {
		pattern = pattern[1:]
		star = true
	}

	in_range, i := false, 0

	scan_loop: for i = 0; i < len(pattern); i += 1 {
		switch pattern[i] {
		case '\\':
			when ODIN_OS != .Windows {
				if i+1 < len(pattern) {
					i += 1
				}
			}
		case '[':
			in_range = true
		case ']':
			in_range = false
		case '*':
			in_range or_break scan_loop

		}
	}
	return star, pattern[:i], pattern[i:]
}

@(private="file")
match_chunk :: proc(chunk, s: string) -> (rest: string, ok: bool, err: Error) {
	slash_equal :: proc(a, b: u8) -> bool {
		switch a {
		case '/':  return b == '/' || b == '\\'
		case '\\': return b == '/' || b == '\\'
		case: return a == b
		}
	}

	chunk, s := chunk, s
	for len(chunk) > 0 {
		if len(s) == 0 {
			return
		}
		switch chunk[0] {
		case '[':
			r, w := utf8.decode_rune_in_string(s)
			s = s[w:]
			chunk = chunk[1:]
			is_negated := false
			if len(chunk) > 0 && chunk[0] == '^' {
				is_negated = true
				chunk = chunk[1:]
			}
			match := false
			range_count := 0
			for {
				if len(chunk) > 0 && chunk[0] == ']' && range_count > 0 {
					chunk = chunk[1:]
					break
				}
				lo, hi: rune
				if lo, chunk, err = get_escape(chunk); err != nil {
					return
				}
				hi = lo
				if chunk[0] == '-' {
					if hi, chunk, err = get_escape(chunk[1:]); err != nil {
						return
					}
				}

				if lo <= r && r <= hi {
					match = true
				}
				range_count += 1
			}
			if match == is_negated {
				return
			}

		case '?':
			if s[0] == _Path_Separator {
				return
			}
			_, w := utf8.decode_rune_in_string(s)
			s = s[w:]
			chunk = chunk[1:]

		case '\\':
			when ODIN_OS != .Windows {
				chunk = chunk[1:]
				if len(chunk) == 0 {
					err = .Pattern_Syntax_Error
					return
				}
			}
			fallthrough
		case:
			if !slash_equal(chunk[0], s[0]) {
				return
			}
			s = s[1:]
			chunk = chunk[1:]

		}
	}
	return s, true, nil
}

@(private="file")
get_escape :: proc(chunk: string) -> (r: rune, next_chunk: string, err: Error) {
	if len(chunk) == 0 || chunk[0] == '-' || chunk[0] == ']' {
		err = .Pattern_Syntax_Error
		return
	}
	chunk := chunk
	if chunk[0] == '\\' && ODIN_OS != .Windows {
		chunk = chunk[1:]
		if len(chunk) == 0 {
			err = .Pattern_Syntax_Error
			return
		}
	}

	w: int
	r, w = utf8.decode_rune_in_string(chunk)
	if r == utf8.RUNE_ERROR && w == 1 {
		err = .Pattern_Syntax_Error
	}

	next_chunk = chunk[w:]
	if len(next_chunk) == 0 {
		err = .Pattern_Syntax_Error
	}

	return
}

// Internal implementation of `glob`, not meant to be used by the user. Prefer `glob`.
_glob :: proc(dir, pattern: string, matches: ^[dynamic]string, allocator := context.allocator) -> (m: [dynamic]string, e: Error) {
	context.allocator = allocator

	if matches != nil {
		m = matches^
	} else {
		m = make([dynamic]string, 0, 0)
	}


	d := open(dir, O_RDONLY) or_return
	defer close(d)

	file_info := fstat(d, allocator) or_return
	defer file_info_delete(file_info, allocator)

	if file_info.type != .Directory {
		return
	}

	fis, _ := read_dir(d, -1, allocator)
	slice.sort_by(fis, proc(a, b: File_Info) -> bool {
		return a.name < b.name
	})
	defer file_info_slice_delete(fis, allocator)

	for fi in fis {
		matched := match(pattern, fi.name) or_return
		if matched {
			matched_path := join_path({dir, fi.name}, allocator) or_return
			append(&m, matched_path)
		}
	}
	return
}

@(private)
has_meta :: proc(path: string) -> bool {
	when ODIN_OS == .Windows {
		CHARS :: `*?[`
	} else {
		CHARS :: `*?[\`
	}
	return strings.contains_any(path, CHARS)
}

@(private)
clean_glob_path :: proc(path: string, temp_buf: []byte) -> (int, string) {
	when ODIN_OS == .Windows {
		vol_len := _volume_name_len(path)
		switch {
		case path == "":
			return 0, "."
		case vol_len+1 == len(path) && is_path_separator(path[len(path)-1]): // /, \, C:\, C:/
			return vol_len+1, path
		case vol_len == len(path) && len(path) == 2: // C:
			copy(temp_buf[:], path)
			temp_buf[2] = '.'
			return vol_len, string(temp_buf[:3])
		}

		if vol_len >= len(path) {
			vol_len = len(path) -1
		}
		return vol_len, path[:len(path)-1]
	} else {
		switch path {
		case "":
			return 0, "."
		case Path_Separator_String:
			return 0, path
		}
		return 0, path[:len(path)-1]
	}
}