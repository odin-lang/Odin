#+build !js
package archive

import "core:os"
import "core:strings"

/*
Extracts every regular file and directory into a directory

Other types of member give `General_Error.Skipped_Entry_Type`.

*Allocates Using Provided Allocator*

Inputs:
- a: An open archive
- dir: The destination, created if missing
- options: Overwriting, limits and the password (default: {})
- allocator: (default: context.allocator)

Returns:
- err: The first error; extraction carries on past a failed member
*/
extract_all :: proc(a: ^Archive, dir: string, options := Extract_Options{}, allocator := context.allocator) -> (err: Error) {
	d := extractor_create(dir, options, allocator) or_return
	defer extractor_destroy(&d)
	it := iterator_create(a)
	defer iterator_destroy(&it)
	for fi in iterate(&it) {
		if item_err := extract_current_to_dir(&d, &it, fi, fi.path); item_err != nil && err == nil {
			err = item_err
		}
	}
	if _, last := iterator_error(&it); last != nil && err == nil {
		err = last
	}
	return
}

/*
Creates an extractor, which extracts members into a directory one at a time

*Allocates Using Provided Allocator*

Inputs:
- dir: The destination, created if missing
- options: Overwriting, limits and the password (default: {})
- allocator: (default: context.allocator)

Returns:
- d: The extractor; destroy it with `extractor_destroy`
- err: An error creating `dir`, or `nil`
*/
extractor_create :: proc(dir: string, options := Extract_Options{}, allocator := context.allocator) -> (d: Extractor, err: Error) {
	d.options           = options
	d.allocator         = allocator
	d.path.allocator    = allocator
	d.checked.allocator = allocator
	if !os.is_directory(dir) {
		os.make_directory_all(dir) or_return
	}
	append(&d.path, dir) or_return
	d.root = len(d.path)
	return
}

/*
Destroys an extractor

Inputs:
- d: The extractor
*/
extractor_destroy :: proc(d: ^Extractor) {
	delete(d.path)
	delete(d.checked)
	d^ = {}
}

/*
Extracts the current member below the extractor's directory

Creates missing parent directories, but refuses to write through a symlink. A file that fails
halfway is removed.

Inputs:
- d: The extractor
- it: The iterator, on the member `iterate` returned last
- fi: The member's info, from `iterate`
- path: Where to put it, relative to the directory; usually `fi.path`
- overwrite: Replace an existing file, whatever the extractor's options say (default: false)

Returns:
- err: `General_Error.Skipped_Entry_Type` for anything but a regular file or a directory,
  `General_Error.Unsafe_Path` if `check_member_path` refuses `path`, `General_Error.Exists`,
  `General_Error.Limit_Exceeded`, the member's error, or `nil`
*/
extract_current_to_dir :: proc(d: ^Extractor, it: ^Iterator, fi: File_Info, path: string, overwrite := false) -> (err: Error) {
	if fi.type != .Regular && fi.type != .Directory {
		return General_Error.Skipped_Entry_Type
	}
	check_member_path(path) or_return
	if fi.type == .Regular {
		_check_limits(d.options, d.total, fi) or_return
	}
	if fi.type == .Regular && (!fi.supported || fi.encrypted) {
		if _, probe_err := open_current(it, {password = d.options.password}); probe_err != nil {
			return probe_err
		}
	}
	resize(&d.path, d.root)
	parent := d.root
	rest   := path
	for len(rest) > 0 {
		i := 0
		for i < len(rest) && !_is_separator(rest[i], ODIN_OS == .Windows) {
			i += 1
		}
		part := rest[:i]
		rest  = rest[min(i + 1, len(rest)):]
		if part == "" || part == "." {
			continue
		}
		parent = len(d.path)
		append(&d.path, '/') or_return
		append(&d.path, part) or_return
	}
	if len(d.path) == d.root {
		if fi.type == .Directory {
			return nil
		}
		return General_Error.Unsafe_Path
	}
	_extractor_make_parents(d, parent) or_return
	replace := overwrite || d.options.overwrite
	if fi.type == .Directory {
		_extractor_make_directory(d, len(d.path), true, replace) or_return
		return _extractor_mark_checked(d, len(d.path))
	}
	full := string(d.path[:])
	f, open_err := os.open(full, {.Write, .Create, .Excl}, os.Permissions_Default_File)
	if open_err != nil {
		info, stat_err := os.lstat(full, d.allocator)
		if stat_err != nil {
			return open_err
		}
		type := info.type
		os.file_info_delete(info, d.allocator)
		if type == .Directory || !replace {
			return General_Error.Exists
		}
		os.remove(full) or_return
		f, open_err = os.open(full, {.Write, .Create, .Excl}, os.Permissions_Default_File)
		if open_err == os.General_Error.Exist {
			return General_Error.Exists
		}
		if open_err != nil {
			return open_err
		}
	}
	d.total += fi.size
	err = extract_current(it, os.to_stream(f), {password = d.options.password})
	os.close(f)
	if err != nil {
		os.remove(full)
	}
	return
}

@(private)
_extract_to_path :: proc(it: ^Extract_Iterator, to: string, fi: File_Info, again: bool) -> (err: Error) {
	flags := os.File_Flags{.Write, .Create}
	if it.options.overwrite || again {
		flags += {.Trunc}
	} else {
		flags += {.Excl}
	}
	f, open_err := os.open(to, flags, os.Permissions_Default_File)
	if open_err == os.General_Error.Exist {
		return General_Error.Exists
	}
	if open_err != nil {
		return open_err
	}
	it.total += fi.size
	err = extract_current(&it.it, os.to_stream(f), {password = it.options.password})
	os.close(f)
	if err != nil {
		os.remove(to)
	}
	return
}

@(private="file")
_extractor_make_parents :: proc(d: ^Extractor, end: int) -> (err: Error) {
	rel   := string(d.path[d.root:end])
	done  := string(d.checked[:])
	start := d.root
	if strings.has_prefix(rel, done) && (len(rel) == len(done) || rel[len(done)] == '/') {
		start += len(done)
	}
	for start < end {
		next := start + 1
		for next < end && d.path[next] != '/' {
			next += 1
		}
		_extractor_make_directory(d, next, false, false) or_return
		start = next
	}
	return _extractor_mark_checked(d, end)
}

@(private="file")
_extractor_make_directory :: proc(d: ^Extractor, end: int, final, replace: bool) -> (err: Error) {
	full := string(d.path[:end])
	info, stat_err := os.lstat(full, d.allocator)
	if stat_err == nil {
		type := info.type
		os.file_info_delete(info, d.allocator)
		if type == .Directory {
			return nil
		}
		if !final {
			return General_Error.Unsafe_Path if type == .Symlink else General_Error.Exists
		}
		if !replace {
			return General_Error.Exists
		}
		os.remove(full) or_return
	} else if stat_err != os.General_Error.Not_Exist {
		return stat_err
	}
	make_err := os.make_directory(full)
	if make_err == os.General_Error.Exist {
		return General_Error.Exists
	}
	return make_err
}

@(private="file")
_extractor_mark_checked :: proc(d: ^Extractor, end: int) -> (err: Error) {
	clear(&d.checked)
	append(&d.checked, ..d.path[d.root:end]) or_return
	return nil
}
