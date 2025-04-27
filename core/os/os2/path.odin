package os2

import "base:runtime"

import "core:strings"

Path_Separator        :: _Path_Separator        // OS-Specific
Path_Separator_String :: _Path_Separator_String // OS-Specific
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

	TEMP_ALLOCATOR_GUARD()

	// The extra byte is to simplify appending path elements by letting the
	// loop to end each with a separator. We'll trim the last one when we're done.
	buffer := make([]u8, len(path) + 1, temp_allocator()) or_return

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
Join all `elems` with the system's path separator and normalize the result.

*Allocates Using Provided Allocator*

For example, `join_path({"/home", "foo", "bar.txt"})` will result in `"/home/foo/bar.txt"`.
*/
@(require_results)
join_path :: proc(elems: []string, allocator: runtime.Allocator) -> (joined: string, err: Error) {
	for e, i in elems {
		if e != "" {
			TEMP_ALLOCATOR_GUARD()
			p := strings.join(elems[i:], Path_Separator_String, temp_allocator()) or_return
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
