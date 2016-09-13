#load "win32.odin"

File :: type struct {
	Handle :: type HANDLE
	handle: Handle
}

file_open :: proc(name: string) -> (File, bool) {
	buf: [300]byte
	_ = copy(buf[:], name as []byte)
	f := File{CreateFileA(^buf[0], FILE_GENERIC_READ, FILE_SHARE_READ, null, OPEN_EXISTING, 0, null)}
	success := f.handle != INVALID_HANDLE_VALUE as File.Handle

	return f, success
}

file_create :: proc(name: string) -> (File, bool) {
	buf: [300]byte
	_ = copy(buf[:], name as []byte)
	f := File{
		handle = CreateFileA(^buf[0], FILE_GENERIC_WRITE, FILE_SHARE_READ, null, CREATE_ALWAYS, 0, null),
	}
	success := f.handle != INVALID_HANDLE_VALUE as File.Handle
	return f, success
}


file_close :: proc(f: ^File) {
	CloseHandle(f.handle)
}

file_write :: proc(f: ^File, buf: []byte) -> bool {
	bytes_written: i32
	return WriteFile(f.handle, ^buf[0], buf.count as i32, ^bytes_written, null) != 0
}

File_Standard :: type enum {
	INPUT,
	OUTPUT,
	ERROR,
	COUNT,
}


__std_files := __set_file_standards();

__set_file_standards :: proc() -> [File_Standard.COUNT as int]File {
	return [File_Standard.COUNT as int]File{
		File{handle = GetStdHandle(STD_INPUT_HANDLE)},
		File{handle = GetStdHandle(STD_OUTPUT_HANDLE)},
		File{handle = GetStdHandle(STD_ERROR_HANDLE)},
	}
}

file_get_standard :: proc(std: File_Standard) -> ^File {
	return ^__std_files[std]
}


read_entire_file :: proc(name: string) -> (string, bool) {
	buf: [300]byte
	_ = copy(buf[:], name as []byte)
	c_string := ^buf[0]


	f, file_ok := file_open(name)
	if !file_ok {
		return "", false
	}
	defer file_close(^f)

	length: i64
	file_size_ok := GetFileSizeEx(f.handle as HANDLE, ^length) != 0
	if !file_size_ok {
		return "", false
	}

	data := new_slice(u8, length)
	if ^data[0] == null {
		return "", false
	}

	single_read_length: i32
	total_read: i64

	for total_read < length {
		remaining := length - total_read
		to_read: u32
		MAX :: 0x7fffffff
		if remaining <= MAX {
			to_read = remaining as u32
		} else {
			to_read = MAX
		}

		ReadFile(f.handle as HANDLE, ^data[total_read], to_read, ^single_read_length, null)
		if single_read_length <= 0 {
			free(^data[0])
			return "", false
		}

		total_read += single_read_length as i64
	}

	return data as string, true
}
