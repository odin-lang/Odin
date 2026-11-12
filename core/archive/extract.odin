package archive

import "core:io"
import "core:os"
import "core:strings"

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

extract_iterator_destroy :: proc(it: ^Extract_Iterator) {
	iterator_destroy(&it.it)
	delete(it.err_path)
	delete(it.last_path)
}

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
		want := clean_member_path(fi.path)
		for &t, i in it.targets {
			if t.found && !it.options.last_wins {
				continue
			}
			if clean_member_path(t.path) != want {
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

@(require_results)
extract_iterator_error :: proc(it: ^Extract_Iterator) -> (path: string, err: Error) {
	return string(it.err_path[:]), it.err
}

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

extractor_destroy :: proc(d: ^Extractor) {
	delete(d.path)
	delete(d.checked)
	d^ = {}
}

extract_current_to_dir :: proc(d: ^Extractor, it: ^Iterator, fi: File_Info, path: string, overwrite := false) -> (err: Error) {
	if fi.type != .Regular && fi.type != .Directory {
		return General_Error.Skipped_Entry_Type
	}
	check_member_path(path) or_return
	if fi.type == .Regular {
		_check_limits(d.options, d.total, fi) or_return
	}
	if fi.type == .Regular && (!fi.supported || fi.encrypted) {
		if _, probe_err := open_current(it); probe_err != nil {
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
	defer os.close(f)
	d.total += fi.size
	return extract_current(it, os.to_stream(f))
}

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
		defer os.close(f)
		it.total += fi.size
		return extract_current(&it.it, os.to_stream(f))
	case ^[dynamic]u8:
		clear(to)
		r := open_current(&it.it) or_return
		it.total += fi.size
		chunk: [16 * 1024]u8
		for {
			n, read_err := io.read(r, chunk[:])
			if n > 0 {
				_, append_err := append(to, ..chunk[:n])
				if append_err != nil {
					return append_err
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
		return extract_current(&it.it, to)
	}
	return General_Error.Incompatible_Options
}

@(private="file")
_check_limits :: proc(options: Extract_Options, total: i64, fi: File_Info) -> (err: Error) {
	if options.max_total_size <= 0 && options.max_ratio <= 0 {
		return nil
	}
	if fi.size < 0 {
		return General_Error.Limit_Exceeded
	}
	if options.max_ratio > 0 && fi.compressed_size >= 0 && fi.size > 0 && (fi.size - 1) / i64(options.max_ratio) >= fi.compressed_size {
		return General_Error.Limit_Exceeded
	}
	if options.max_total_size > 0 && fi.size > options.max_total_size - total {
		return General_Error.Limit_Exceeded
	}
	return nil
}

@(private="file")
_is_separator :: proc "contextless" (c: u8, windows: bool) -> bool {
	return c == '/' || (windows && c == '\\')
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
		return digit == "\u00b9" || digit == "\u00b2" || digit == "\u00b3"
	case 6, 7:
		return strings.equal_fold(base, "CONIN$") || strings.equal_fold(base, "CONOUT$")
	}
	return false
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
