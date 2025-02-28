package os2

import "base:runtime"
import "core:slice"

read_dir :: read_directory

@(require_results)
read_directory :: proc(f: ^File, n: int, allocator: runtime.Allocator) -> (files: []File_Info, err: Error) {
	if f == nil {
		return nil, .Invalid_File
	}

	n := n
	size := n
	if n <= 0 {
		n = -1
		size = 100
	}

	TEMP_ALLOCATOR_GUARD()

	it := read_directory_iterator_create(f)
	defer _read_directory_iterator_destroy(&it)

	dfi := make([dynamic]File_Info, 0, size, temp_allocator())
	defer if err != nil {
		for fi in dfi {
			file_info_delete(fi, allocator)
		}
	}

	for fi, index in read_directory_iterator(&it) {
		if n > 0 && index == n {
			break
		}

		_ = read_directory_iterator_error(&it) or_break

		append(&dfi, file_info_clone(fi, allocator) or_return)
	}

	_ = read_directory_iterator_error(&it) or_return

	return slice.clone(dfi[:], allocator)
}


@(require_results)
read_all_directory :: proc(f: ^File, allocator: runtime.Allocator) -> (fi: []File_Info, err: Error) {
	return read_directory(f, -1, allocator)
}

@(require_results)
read_directory_by_path :: proc(path: string, n: int, allocator: runtime.Allocator) -> (fi: []File_Info, err: Error) {
	f := open(path) or_return
	defer close(f)
	return read_directory(f, n, allocator)
}

@(require_results)
read_all_directory_by_path :: proc(path: string, allocator: runtime.Allocator) -> (fi: []File_Info, err: Error) {
	return read_directory_by_path(path, -1, allocator)
}



Read_Directory_Iterator :: struct {
	f: ^File,
	err: struct {
		err:  Error,
		path: [dynamic]byte,
	},
	index: int,
	impl: Read_Directory_Iterator_Impl,
}

/*
Creates a directory iterator with the given directory.

For an example on how to use the iterator, see `read_directory_iterator`.
*/
read_directory_iterator_create :: proc(f: ^File) -> (it: Read_Directory_Iterator) {
	read_directory_iterator_init(&it, f)
	return
}

/*
Initialize a directory iterator with the given directory.

This procedure may be called on an existing iterator to reuse it for another directory.

For an example on how to use the iterator, see `read_directory_iterator`.
*/
read_directory_iterator_init :: proc(it: ^Read_Directory_Iterator, f: ^File) {
	it.err.err = nil
	it.err.path.allocator = file_allocator()
	clear(&it.err.path)

	it.f = f
	it.index = 0

	_read_directory_iterator_init(it, f)
}

/*
Destroys a directory iterator.
*/
read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	if it == nil {
		return
	}

	delete(it.err.path)

	_read_directory_iterator_destroy(it)
}

/*
Retrieve the last error that happened during iteration.
*/
@(require_results)
read_directory_iterator_error :: proc(it: ^Read_Directory_Iterator) -> (path: string, err: Error) {
	return string(it.err.path[:]), it.err.err
}

@(private)
read_directory_iterator_set_error :: proc(it: ^Read_Directory_Iterator, path: string, err: Error) {
	if err == nil {
		return
	}

	resize(&it.err.path, len(path))
	copy(it.err.path[:], path)

	it.err.err = err
}

/*
Returns the next file info entry for the iterator's directory.

The given `File_Info` is reused in subsequent calls so a copy (`file_info_clone`) has to be made to
extend its lifetime.

Example:
	package main

	import    "core:fmt"
	import os "core:os/os2"

	main :: proc() {
		f, oerr := os.open("core")
		ensure(oerr == nil)
		defer os.close(f)

		it := os.read_directory_iterator_create(f)
		defer os.read_directory_iterator_destroy(&it)

		for info in os.read_directory_iterator(&it) {
			// Optionally break on the first error:
			// Supports not doing this, and keeping it going with remaining items.
			// _ = os.read_directory_iterator_error(&it) or_break

			// Handle error as we go:
			// Again, no need to do this as it will keep going with remaining items.
			if path, err := os.read_directory_iterator_error(&it); err != nil {
				fmt.eprintfln("failed reading %s: %s", path, err)
				continue
			}

			// Or, do not handle errors during iteration, and just check the error at the end.


			fmt.printfln("%#v", info)
		}

		// Handle error if one happened during iteration at the end:
		if path, err := os.read_directory_iterator_error(&it); err != nil {
			fmt.eprintfln("read directory failed at %s: %s", path, err)
		}
	}
*/
@(require_results)
read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	if it.f == nil {
		return
	}

	if it.index == 0 && it.err.err != nil {
		return
	}

	return _read_directory_iterator(it)
}
