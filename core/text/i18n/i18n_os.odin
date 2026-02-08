#+build !freestanding
#+build !js
package i18n
/*
	Internationalization helpers.

	Copyright 2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
import "base:runtime"
import os "core:os/os2"

@(private)
read_file :: proc(filename: string, allocator: runtime.Allocator) -> (data: []u8, err: Error) {
	file_data, file_err := os.read_entire_file(filename, allocator)
	if file_err != nil {
		return {}, .File_Error
	}
	return file_data, nil
}

parse_qt_linguist_file :: proc(filename: string, options := DEFAULT_PARSE_OPTIONS, pluralizer: proc(int) -> int = nil, allocator := context.allocator) -> (translation: ^Translation, err: Error) {
	data := read_file(filename, allocator) or_return
	return parse_qt_linguist_from_bytes(data, options, pluralizer, allocator)
}

parse_qt :: proc { parse_qt_linguist_file, parse_qt_linguist_from_bytes }

parse_mo_file :: proc(filename: string, options := DEFAULT_PARSE_OPTIONS, pluralizer: proc(int) -> int = nil, allocator := context.allocator) -> (translation: ^Translation, err: Error) {
	data := read_file(filename, allocator) or_return
	defer delete(data)
	return parse_mo_from_bytes(data, options, pluralizer, allocator)
}

parse_mo :: proc { parse_mo_file, parse_mo_from_bytes }