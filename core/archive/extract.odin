package archive

import "core:io"
import "core:os"

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
		return extract_current(&it.it, os.to_stream(f))
	case ^[dynamic]u8:
		clear(to)
		r := open_current(&it.it) or_return
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
		return extract_current(&it.it, to)
	}
	return General_Error.Incompatible_Options
}
