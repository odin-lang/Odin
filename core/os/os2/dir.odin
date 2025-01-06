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

	it := read_directory_iterator_create(f) or_return
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
		append(&dfi, file_info_clone(fi, allocator) or_return)
	}

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
	f:    ^File,
	impl: Read_Directory_Iterator_Impl,
}


@(require_results)
read_directory_iterator_create :: proc(f: ^File) -> (Read_Directory_Iterator, Error) {
	return _read_directory_iterator_create(f)
}

read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	_read_directory_iterator_destroy(it)
}

// NOTE(bill): `File_Info` does not need to deleted on each iteration. Any copies must be manually copied with `file_info_clone`
@(require_results)
read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	return _read_directory_iterator(it)
}
