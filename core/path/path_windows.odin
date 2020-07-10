package path

import "core:strings"
import win32 "core:sys/windows"


SEPARATOR        :: '\\';
SEPARATOR_STRING :: "\\";


@(private)
null_term :: proc "contextless" (str: string) -> string {
	for c, i in str {
		if c == '\x00' {
			return str[:i];
		}
	}
	return str;
}


long :: proc(path: string, allocator := context.temp_allocator) -> string {
	c_path := win32.utf8_to_wstring(path, context.temp_allocator);
	length := win32.GetLongPathNameW(c_path, nil, 0);

	if length == 0 do return "";

	buf := make([]u16, length, context.temp_allocator);

	win32.GetLongPathNameW(c_path, win32.LPCWSTR(&buf[0]), length);

	res := win32.utf16_to_utf8(buf[:length], allocator);

	return null_term(res);
}

short :: proc(path: string, allocator := context.temp_allocator) -> string {
	c_path := win32.utf8_to_wstring(path, context.temp_allocator);
	length := win32.GetShortPathNameW(c_path, nil, 0);

	if length == 0 do return "";

	buf := make([]u16, length, context.temp_allocator);

	win32.GetShortPathNameW(c_path, win32.LPCWSTR(&buf[0]), length);

	res := win32.utf16_to_utf8(buf[:length], allocator);

	return null_term(res);
}

full :: proc(path: string, allocator := context.temp_allocator) -> string {
	c_path := win32.utf8_to_wstring(path, context.temp_allocator);
	length := win32.GetFullPathNameW(c_path, 0, nil, nil);

	if length == 0 do return "";

	buf := make([]u16, length, context.temp_allocator);

	win32.GetFullPathNameW(c_path, length, win32.LPCWSTR(&buf[0]), nil);

	res := win32.utf16_to_utf8(buf[:length], allocator);

	return null_term(res);
}

current :: proc(allocator := context.temp_allocator) -> string {
	length := win32.GetCurrentDirectoryW(0, nil);

	if length == 0 do return "";

	buf := make([]u16, length, context.temp_allocator);

	win32.GetCurrentDirectoryW(length, win32.LPCWSTR(&buf[0]));

	res := win32.utf16_to_utf8(buf[:length], allocator);

	return strings.trim_null(res);
}


exists :: proc(path: string) -> bool {
	c_path  := win32.utf8_to_wstring(path, context.temp_allocator);
	attribs := win32.GetFileAttributesW(c_path);

	return i32(attribs) != win32.INVALID_FILE_ATTRIBUTES;
}

is_dir :: proc(path: string) -> bool {
	c_path  := win32.utf8_to_wstring(path, context.temp_allocator);
	attribs := win32.GetFileAttributesW(c_path);

	return (i32(attribs) != win32.INVALID_FILE_ATTRIBUTES) && (attribs & win32.FILE_ATTRIBUTE_DIRECTORY == win32.FILE_ATTRIBUTE_DIRECTORY);
}

is_file :: proc(path: string) -> bool {
	c_path  := win32.utf8_to_wstring(path, context.temp_allocator);
	attribs := win32.GetFileAttributesW(c_path);

	return (i32(attribs) != win32.INVALID_FILE_ATTRIBUTES) && (attribs & win32.FILE_ATTRIBUTE_DIRECTORY != win32.FILE_ATTRIBUTE_DIRECTORY);
}


drive :: proc(path: string, new := false, allocator := context.allocator) -> string {
	if len(path) >= 3 {
		letter := path[:2];

		if path[1] == ':' && (path[2] == '\\' || path[2] == '/') {
			return new ? strings.clone(path[:2], allocator) : path[:2];
		}
	}

	return "";
}
