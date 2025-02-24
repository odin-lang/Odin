package os2

import "core:container/queue"

/*
A recursive directory walker.

Note that none of the fields should be accessed directly.
*/
Walker :: struct {
	todo:      queue.Queue(string),
	skip_dir:  bool,
	err: struct {
		path: [dynamic]byte,
		err:  Error,
	},
	iter: Read_Directory_Iterator,
}

walker_init_path :: proc(w: ^Walker, path: string) {
	cloned_path, err := clone_string(path, file_allocator())
	if err != nil {
		walker_set_error(w, path, err)
		return
	}

	walker_clear(w)

	if _, err = queue.push(&w.todo, cloned_path); err != nil {
		walker_set_error(w, cloned_path, err)
		return
	}
}

walker_init_file :: proc(w: ^Walker, f: ^File) {
	handle, err := clone(f)
	if err != nil {
		path, _ := clone_string(name(f), file_allocator())
		walker_set_error(w, path, err)
		return
	}

	walker_clear(w)

	read_directory_iterator_init(&w.iter, handle)
}

/*
Initializes a walker, either using a path or a file pointer to a directory the walker will start at.

You are allowed to repeatedly call this to reuse it for later walks.

For an example on how to use the walker, see `walker_walk`.
*/
walker_init :: proc {
	walker_init_path,
	walker_init_file,
}

@(require_results)
walker_create_path :: proc(path: string) -> (w: Walker) {
	walker_init_path(&w, path)
	return
}

@(require_results)
walker_create_file :: proc(f: ^File) -> (w: Walker) {
	walker_init_file(&w, f)
	return
}

/*
Creates a walker, either using a path or a file pointer to a directory the walker will start at.

For an example on how to use the walker, see `walker_walk`.
*/
walker_create :: proc {
	walker_create_path,
	walker_create_file,
}

/*
Returns the last error that occurred during the walker's operations.

Can be called while iterating, or only at the end to check if anything failed.
*/
@(require_results)
walker_error :: proc(w: ^Walker) -> (path: string, err: Error) {
	return string(w.err.path[:]), w.err.err
}

@(private)
walker_set_error :: proc(w: ^Walker, path: string, err: Error) {
	if err == nil {
		return
	}

	resize(&w.err.path, len(path))
	copy(w.err.path[:], path)

	w.err.err = err
}

@(private)
walker_clear :: proc(w: ^Walker) {
	w.iter.f = nil
	w.skip_dir = false

	w.err.path.allocator = file_allocator()
	clear(&w.err.path)

	w.todo.data.allocator = file_allocator()
	for path in queue.pop_front_safe(&w.todo) {
		delete(path, file_allocator())
	}
}

walker_destroy :: proc(w: ^Walker) {
	walker_clear(w)
	queue.destroy(&w.todo)
	delete(w.err.path)
	read_directory_iterator_destroy(&w.iter)
}

// Marks the current directory to be skipped (not entered into).
walker_skip_dir :: proc(w: ^Walker) {
	w.skip_dir = true
}

/*
Returns the next file info in the iterator, files are iterated in breadth-first order.

If an error occurred opening a directory, you may get zero'd info struct and
`walker_error` will return the error.

Example:
	package main

	import    "core:fmt"
	import    "core:strings"
	import os "core:os/os2"

	main :: proc() {
		w := os.walker_create("core")
		defer os.walker_destroy(&w)

		for info in os.walker_walk(&w) {
			// Optionally break on the first error:
			// _ = walker_error(&w) or_break

			// Or, handle error as we go:
			if path, err := os.walker_error(&w); err != nil {
				fmt.eprintfln("failed walking %s: %s", path, err)
				continue
			}

			// Or, do not handle errors during iteration, and just check the error at the end.



			// Skip a directory:
			if strings.has_suffix(info.fullpath, ".git") {
				os.walker_skip_dir(&w)
				continue
			}

			fmt.printfln("%#v", info)
		}

		// Handle error if one happened during iteration at the end:
		if path, err := os.walker_error(&w); err != nil {
			fmt.eprintfln("failed walking %s: %v", path, err)
		}
	}
*/
@(require_results)
walker_walk :: proc(w: ^Walker) -> (fi: File_Info, ok: bool) {
	if w.skip_dir {
		w.skip_dir = false
		if skip, sok := queue.pop_back_safe(&w.todo); sok {
			delete(skip, file_allocator())
		}
	}

	if w.iter.f == nil {
		if queue.len(w.todo) == 0 {
			return
		}

		next := queue.pop_front(&w.todo)

		handle, err := open(next)
		if err != nil {
			walker_set_error(w, next, err)
			return {}, true
		}

		read_directory_iterator_init(&w.iter, handle)

		delete(next, file_allocator())
	}

	info, _, iter_ok := read_directory_iterator(&w.iter)

	if path, err := read_directory_iterator_error(&w.iter); err != nil {
		walker_set_error(w, path, err)
	}

	if !iter_ok {
		close(w.iter.f)
		w.iter.f = nil
		return walker_walk(w)
	}

	if info.type == .Directory {
		path, err := clone_string(info.fullpath, file_allocator())
		if err != nil {
			walker_set_error(w, "", err)
			return
		}

		_, err = queue.push_back(&w.todo, path)
		if err != nil {
			walker_set_error(w, path, err)
			return
		}
	}

	return info, iter_ok
}
