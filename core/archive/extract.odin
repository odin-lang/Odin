package archive

import "core:io"
import "core:strings"

/*
Creates an iterator that extracts targets in one pass over an archive

*Allocates Using Provided Allocator*

Inputs:
- a: An open archive
- targets: The members to extract and where to; their `found` flags are reset
- options: Overwriting, limits and the password (default: {})
- allocator: (default: context.allocator)

Returns:
- it: The iterator; destroy it with `extract_iterator_destroy`. With `last_wins`, an `io.Writer`
  target makes it stop at once with `General_Error.Incompatible_Options`
*/
extract_iterator_create :: proc(a: ^Archive, targets: []Target, options := Extract_Options{}, allocator := context.allocator) -> (it: Extract_Iterator) {
	it.archive   = a
	it.targets   = targets
	it.options   = options
	it.allocator = allocator
	it.err_path.allocator  = allocator
	it.last_path.allocator = allocator
	for &t in targets {
		t.found = false
		if _, is_writer := t.to.(io.Writer); is_writer && options.last_wins {
			_extract_iterator_set_error(&it, t.path, General_Error.Incompatible_Options)
			it.done = true
			return
		}
	}
	it.it = iterator_create(a)
	return
}

/*
Destroys an extract iterator

Inputs:
- it: The iterator
*/
extract_iterator_destroy :: proc(it: ^Extract_Iterator) {
	iterator_destroy(&it.it)
	delete(it.err_path)
	delete(it.last_path)
}

/*
Extracts the next member that matches a target

Only regular files are extracted; another type of member gives
`General_Error.Skipped_Entry_Type`. On js, a path target gives
`General_Error.Incompatible_Options`.

Inputs:
- it: The iterator

Returns:
- target: The matched target
- index: Its index in `targets`
- ok: `false` once every target is found (unless `last_wins`), at the archive's end, or on an
  error reading the archive; `extract_iterator_error` has this member's error, or the last one
*/
extract_iterate :: proc(it: ^Extract_Iterator) -> (target: ^Target, index: int, ok: bool) {
	it.err = nil
	clear(&it.err_path)
	for !it.done {
		if !it.options.last_wins && it.found == len(it.targets) {
			it.done = true
			break
		}
		fi, _, more := iterate(&it.it)
		if !more {
			if path, err := iterator_error(&it.it); err != nil {
				_extract_iterator_set_error(it, path, err)
			}
			it.done = true
			break
		}
		for &t, i in it.targets {
			if t.found && !it.options.last_wins {
				continue
			}
			if _clean_member_path(t.path) != fi.path {
				continue
			}
			again := t.found
			if !t.found {
				t.found   = true
				it.found += 1
			}
			if err := _extract_target(it, &t, fi, again); err != nil {
				_extract_iterator_set_error(it, fi.path, err)
			}
			return &t, i, true
		}
	}
	it.err = it.last_err
	clear(&it.err_path)
	append(&it.err_path, ..it.last_path[:])
	return nil, -1, false
}

/*
Tells why the last `extract_iterate` failed

Inputs:
- it: The iterator

Returns:
- path: The path of the member the error is about, if any
- err: The error of the member `extract_iterate` just returned; once it returns `false`, the last
  error of the pass, or `nil`
*/
@(require_results)
extract_iterator_error :: proc(it: ^Extract_Iterator) -> (path: string, err: Error) {
	return string(it.err_path[:]), it.err
}

/*
Extracts targets in one pass over an archive

Only regular files are extracted; another type of member gives
`General_Error.Skipped_Entry_Type`. A target that matches no member keeps `found` unset.

*Allocates Using Provided Allocator*

Inputs:
- a: An open archive
- targets: The members to extract and where to; their `found` flags are reset
- options: Overwriting, limits and the password (default: {})
- allocator: (default: context.allocator)

Returns:
- err: The first error; extraction carries on past a failed target
*/
extract_many :: proc(a: ^Archive, targets: []Target, options := Extract_Options{}, allocator := context.allocator) -> (err: Error) {
	it := extract_iterator_create(a, targets, options, allocator)
	defer extract_iterator_destroy(&it)
	for _ in extract_iterate(&it) {
		if _, item_err := extract_iterator_error(&it); item_err != nil && err == nil {
			err = item_err
		}
	}
	if _, last := extract_iterator_error(&it); last != nil && err == nil {
		err = last
	}
	return
}

/*
Checks that a member path is safe to extract below a directory

Inputs:
- path: The member's path
- windows: Also apply Windows' rules: `\` separates, and control and reserved characters,
  reserved names, and trailing dots and spaces are refused (default: ODIN_OS == .Windows)

Returns:
- err: `General_Error.Unsafe_Path` for an absolute path, a `..` or a NUL, `nil` otherwise
*/
check_member_path :: proc(path: string, windows := ODIN_OS == .Windows) -> (err: Error) {
	if len(path) > 0 && _is_separator(path[0], windows) {
		return General_Error.Unsafe_Path
	}
	rest := path
	for len(rest) > 0 {
		i := 0
		for i < len(rest) && !_is_separator(rest[i], windows) {
			i += 1
		}
		part := rest[:i]
		rest  = rest[min(i + 1, len(rest)):]
		if part == ".." || !_check_component(part, windows) {
			return General_Error.Unsafe_Path
		}
	}
	return nil
}

@(private="file")
_extract_iterator_set_error :: proc(it: ^Extract_Iterator, path: string, err: Error) {
	it.err = err
	clear(&it.err_path)
	append(&it.err_path, path)
	it.last_err = err
	clear(&it.last_path)
	append(&it.last_path, path)
}

@(private="file")
_extract_target :: proc(it: ^Extract_Iterator, t: ^Target, fi: File_Info, again: bool) -> (err: Error) {
	if fi.type != .Regular {
		return General_Error.Skipped_Entry_Type
	}
	_check_limits(it.options, it.total, fi) or_return
	switch to in t.to {
	case string:
		when ODIN_OS != .JS {
			return _extract_to_path(it, to, fi, again)
		}
	case ^[dynamic]u8:
		clear(to)
		defer if err != nil {
			clear(to)
		}
		r := open_current(&it.it, {password = it.options.password}) or_return
		it.total += fi.size
		chunk: [16 * 1024]u8
		stalled := 0
		for {
			n, read_err := io.read(r, chunk[:])
			if n > 0 {
				stalled = 0
				_, append_err := append(to, ..chunk[:n])
				if append_err != nil {
					return append_err
				}
			} else if read_err == nil {
				stalled += 1
				if stalled > 100 {
					return io.Error.No_Progress
				}
			}
			if read_err == .EOF {
				return nil
			}
			if read_err != nil {
				return read_err
			}
		}
	case io.Writer:
		it.total += fi.size
		return extract_current(&it.it, to, {password = it.options.password})
	}
	return General_Error.Incompatible_Options
}

@(private="file")
_check_component :: proc(part: string, windows: bool) -> bool {
	for i in 0..<len(part) {
		c := part[i]
		if c == 0 {
			return false
		}
		if !windows {
			continue
		}
		if c < 0x20 {
			return false
		}
		switch c {
		case '<', '>', ':', '"', '|', '?', '*':
			return false
		}
	}
	if !windows || part == "" || part == "." {
		return true
	}
	last := part[len(part) - 1]
	if last == '.' || last == ' ' {
		return false
	}
	return !_windows_reserved(part)
}

@(private="file")
_windows_reserved :: proc(part: string) -> bool {
	base := part
	if dot := strings.index_byte(base, '.'); dot >= 0 {
		base = base[:dot]
	}
	base = strings.trim_right(base, " ")
	switch len(base) {
	case 3:
		for name in ([?]string{"CON", "PRN", "AUX", "NUL"}) {
			if strings.equal_fold(base, name) {
				return true
			}
		}
	case 4, 5:
		if !strings.equal_fold(base[:3], "COM") && !strings.equal_fold(base[:3], "LPT") {
			return false
		}
		digit := base[3:]
		if len(digit) == 1 {
			return digit[0] >= '0' && digit[0] <= '9'
		}
		return digit == "¹" || digit == "²" || digit == "³"
	case 6, 7:
		return strings.equal_fold(base, "CONIN$") || strings.equal_fold(base, "CONOUT$")
	}
	return false
}
