#+private
#+build linux, darwin, netbsd, freebsd, openbsd, windows, wasi
package os

import "base:runtime"

_Remove_All_Kind :: enum u8 {
	Other,
	Directory,
}

_Remove_All_Entry :: struct {
	start: int,
	end:   int,
	kind:  _Remove_All_Kind,
}

_Remove_All_Frame :: struct {
	dir:       _Remove_All_Dir,
	parent:    int,
	name:      []u8,
	names:     [dynamic]u8,
	entries:   [dynamic]_Remove_All_Entry,
	next:      int,
	open:      bool,
	scanned:   bool,
	failed:    bool,
	first_err: Error,
}

_REMOVE_ALL_MAX_OPEN :: 32

// Entry names stay in the platform's native encoding throughout: UTF-8 bytes on POSIX and WASI, UTF-16 code units on Windows.
_remove_all :: proc(path: string) -> Error {
	if path == "" {
		return nil
	}

	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	root_parent, root_name := _remove_all_root(path, temp_allocator) or_return

	root, root_is_dir, root_err := _remove_all_open(root_parent, root_name)
	if !root_is_dir {
		return nil if root_err == .Not_Exist else root_err
	}

	stack: [dynamic]_Remove_All_Frame
	stack.allocator = file_allocator()
	defer {
		for &frame in stack {
			_remove_all_close_frame(&frame)
		}
		delete(stack)
	}

	if push_err := _remove_all_push(&stack, root, -1, root_name); push_err != nil {
		_remove_all_close(root)
		return push_err
	}

	result: Error
	for len(stack) > 0 {
		top   := len(stack) - 1
		frame := &stack[top]

		if !frame.open {
			parent_dir, broken, parent_err := _remove_all_parent(stack[:], top, root_parent)
			if broken >= 0 {
				_remove_all_unwind(&stack, &result, broken, parent_err)
				continue
			}
			_remove_all_make_room(stack[:])
			dir, is_dir, open_err := _remove_all_open(parent_dir, frame.name)
			if !is_dir {
				_remove_all_finish(&stack, &result, open_err)
				continue
			}
			frame.dir  = dir
			frame.open = true
		}

		if !frame.scanned {
			frame.scanned   = true
			frame.next      = 0
			frame.failed    = false
			frame.first_err = nil
			clear(&frame.names)
			clear(&frame.entries)
			if read_err := _remove_all_read(frame.dir, &frame.names, &frame.entries); read_err != nil {
				_remove_all_finish(&stack, &result, read_err)
				continue
			}
		}

		if frame.next < len(frame.entries) {
			entry := frame.entries[frame.next]
			frame.next += 1
			name := frame.names[entry.start:entry.end]
			if entry.kind == .Other {
				_remove_all_record(frame, _remove_all_unlink(frame.dir, name, .Other))
				continue
			}
			_remove_all_make_room(stack[:])
			child, child_is_dir, child_err := _remove_all_open(frame.dir, name)
			if !child_is_dir {
				_remove_all_record(frame, child_err)
				continue
			}
			if push_err := _remove_all_push(&stack, child, top, name); push_err != nil {
				_remove_all_close(child)
				_remove_all_record(&stack[top], push_err)
			}
			continue
		}

		if frame.failed {
			_remove_all_finish(&stack, &result, frame.first_err)
			continue
		}

		parent_dir, broken, parent_err := _remove_all_parent(stack[:], top, root_parent)
		if broken >= 0 {
			_remove_all_unwind(&stack, &result, broken, parent_err)
			continue
		}
		_remove_all_close(frame.dir)
		frame.open = false
		remove_err := _remove_all_unlink(parent_dir, frame.name, .Directory)
		if remove_err == nil || remove_err == .Not_Exist || len(frame.entries) == 0 {
			_remove_all_finish(&stack, &result, remove_err)
			continue
		}
		frame.scanned = false
	}
	return result
}

// `name` is opaque native bytes; the trailing 0 makes POSIX names usable as C strings in place.
_remove_all_add :: proc(names: ^[dynamic]u8, entries: ^[dynamic]_Remove_All_Entry, name: []u8, kind: _Remove_All_Kind) -> runtime.Allocator_Error {
	start := len(names)
	append(names, ..name) or_return
	end := len(names)
	append(names, 0) or_return
	append(entries, _Remove_All_Entry{start = start, end = end, kind = kind}) or_return
	return nil
}

@(private="file")
_remove_all_push :: proc(stack: ^[dynamic]_Remove_All_Frame, dir: _Remove_All_Dir, parent: int, name: []u8) -> runtime.Allocator_Error {
	frame := _Remove_All_Frame{
		dir    = dir,
		parent = parent,
		name   = name,
		open   = true,
	}
	frame.names.allocator   = file_allocator()
	frame.entries.allocator = file_allocator()
	_, err := append(stack, frame)
	return err
}

@(private="file")
_remove_all_parent :: proc(stack: []_Remove_All_Frame, top: int, root_parent: _Remove_All_Dir) -> (parent: _Remove_All_Dir, broken: int, err: Error) {
	broken = -1
	first := top
	for first > 0 && !stack[first - 1].open {
		first -= 1
	}
	for i in first..<top {
		_remove_all_make_room(stack)
		dir := root_parent if i == 0 else stack[i - 1].dir
		reopened, is_dir, open_err := _remove_all_open(dir, stack[i].name)
		if !is_dir {
			broken = i
			err    = open_err
			return
		}
		stack[i].dir  = reopened
		stack[i].open = true
	}
	parent = root_parent if top == 0 else stack[top - 1].dir
	return
}

@(private="file")
_remove_all_make_room :: proc(stack: []_Remove_All_Frame) {
	open_count := 0
	shallowest := -1
	for &frame, i in stack {
		if frame.open {
			open_count += 1
			if shallowest < 0 {
				shallowest = i
			}
		}
	}
	if open_count >= _REMOVE_ALL_MAX_OPEN {
		_remove_all_close(stack[shallowest].dir)
		stack[shallowest].open = false
	}
}

@(private="file")
_remove_all_unwind :: proc(stack: ^[dynamic]_Remove_All_Frame, result: ^Error, depth: int, err: Error) {
	for len(stack) > depth {
		_remove_all_finish(stack, result, err)
	}
}

@(private="file")
_remove_all_record :: proc(frame: ^_Remove_All_Frame, err: Error) {
	if err == nil || err == .Not_Exist {
		return
	}
	if !frame.failed {
		frame.failed    = true
		frame.first_err = err
	}
}

@(private="file")
_remove_all_finish :: proc(stack: ^[dynamic]_Remove_All_Frame, result: ^Error, err: Error) {
	frame := pop(stack)
	_remove_all_close_frame(&frame)
	if frame.parent < 0 {
		result^ = nil if err == .Not_Exist else err
	} else {
		_remove_all_record(&stack[frame.parent], err)
	}
}

@(private="file")
_remove_all_close_frame :: proc(frame: ^_Remove_All_Frame) {
	if frame.open {
		_remove_all_close(frame.dir)
		frame.open = false
	}
	delete(frame.names)
	delete(frame.entries)
}
