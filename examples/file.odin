#load "win32.odin"

FileHandle :: type HANDLE;

File :: type struct {
	handle: FileHandle,
}

file_open :: proc(name: string) -> (File, bool) {
	buf: [300]byte;
	_ = copy(buf[:], name as []byte);
	handle := CreateFileA(^buf[0], FILE_GENERIC_READ, FILE_SHARE_READ, null, OPEN_EXISTING, 0, null);

	f: File;
	f.handle = handle as FileHandle;
	success := f.handle != INVALID_HANDLE_VALUE as FileHandle;
	return f, success;
}

file_create :: proc(name: string) -> (File, bool) {
	buf: [300]byte;
	_ = copy(buf[:], name as []byte);
	handle := CreateFileA(^buf[0], FILE_GENERIC_WRITE, FILE_SHARE_READ, null, CREATE_ALWAYS, 0, null);

	f: File;
	f.handle = handle as FileHandle;
	success := f.handle != INVALID_HANDLE_VALUE as FileHandle;
	return f, success;
}


file_close :: proc(f: ^File) {
	CloseHandle(f.handle);
}

file_write :: proc(f: ^File, buf: rawptr, len: int) -> bool {
	bytes_written: i32;
	return WriteFile(f.handle, buf, len as i32, ^bytes_written, null) != 0;
}

FileStandardType :: type int;
FILE_STANDARD_INPUT  : FileStandardType : 0;
FILE_STANDARD_OUTPUT : FileStandardType : 1;
FILE_STANDARD_ERROR  : FileStandardType : 2;
FILE_STANDARD__COUNT : FileStandardType : 3;

__std_file_set := false;
__std_files: [FILE_STANDARD__COUNT]File;

file_get_standard :: proc(std: FileStandardType) -> ^File {
	if (!__std_file_set) {
		__std_files[FILE_STANDARD_INPUT] .handle = GetStdHandle(STD_INPUT_HANDLE);
		__std_files[FILE_STANDARD_OUTPUT].handle = GetStdHandle(STD_OUTPUT_HANDLE);
		__std_files[FILE_STANDARD_ERROR] .handle = GetStdHandle(STD_ERROR_HANDLE);
		__std_file_set = true;
	}
	return ^__std_files[std as int];
}


read_entire_file :: proc(name: string) -> (string, bool) {
	buf: [300]byte;
	_ = copy(buf[:], name as []byte);
	c_string := ^buf[0];


	f, file_ok := file_open(name);
	if !file_ok {
		return "", false;
	}
	defer file_close(^f);

	length: i64;
	file_size_ok := GetFileSizeEx(f.handle as HANDLE, ^length) != 0;
	if !file_size_ok {
		return "", false;
	}

	data: ^u8 = alloc(length as int);
	if data == null {
		return "", false;
	}

	single_read_length: i32;
	total_read: i64;

	for total_read < length {
		remaining := length - total_read;
		to_read: u32;
		MAX :: 0x7fffffff;
		if remaining <= MAX {
			to_read = remaining as u32;
		} else {
			to_read = MAX;
		}

		ReadFile(f.handle as HANDLE, ^data[total_read], to_read, ^single_read_length, null);
		if single_read_length <= 0 {
			dealloc(data);
			return "", false;
		}

		total_read += single_read_length as i64;
	}

	return data[:length] as string, true;
}
