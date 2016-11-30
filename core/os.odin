when ODIN_OS == "windows" {
	#import "win32.odin"
}
#import "fmt.odin"

File_Time :: type u64

File :: struct {
	Handle :: raw_union {
		p: rawptr
		i: int
	}
	handle:          Handle
	last_write_time: File_Time
}

open :: proc(name: string) -> (File, bool) {
	using win32
	buf: [300]byte
	copy(buf[:], name as []byte)
	f: File
	f.handle.p = CreateFileA(^buf[0], FILE_GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, nil) as rawptr
	success := f.handle.p != INVALID_HANDLE_VALUE
	f.last_write_time = last_write_time(^f)
	return f, success
}

create :: proc(name: string) -> (File, bool) {
	using win32
	buf: [300]byte
	copy(buf[:], name as []byte)
	f: File
	f.handle.p = CreateFileA(^buf[0], FILE_GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, 0, nil) as rawptr
	success := f.handle.p != INVALID_HANDLE_VALUE
	f.last_write_time = last_write_time(^f)
	return f, success
}

close :: proc(using f: ^File) {
	win32.CloseHandle(handle.p as win32.HANDLE)
}

write :: proc(using f: ^File, buf: []byte) -> bool {
	bytes_written: i32
	return win32.WriteFile(handle.p as win32.HANDLE, buf.data, buf.count as i32, ^bytes_written, nil) != 0
}

file_has_changed :: proc(f: ^File) -> bool {
	last_write_time := last_write_time(f)
	if f.last_write_time != last_write_time {
		f.last_write_time = last_write_time
		return true
	}
	return false
}



last_write_time :: proc(f: ^File) -> File_Time {
	file_info: win32.BY_HANDLE_FILE_INFORMATION
	win32.GetFileInformationByHandle(f.handle.p as win32.HANDLE, ^file_info)
	l := file_info.last_write_time.low_date_time as File_Time
	h := file_info.last_write_time.high_date_time as File_Time
	return l | h << 32
}

last_write_time_by_name :: proc(name: string) -> File_Time {
	last_write_time: win32.FILETIME
	data: win32.WIN32_FILE_ATTRIBUTE_DATA

	buf: [1024]byte
	path := buf[:0]
	fmt.bprint(^path, name, "\x00")

	if win32.GetFileAttributesExA(path.data, win32.GetFileExInfoStandard, ^data) != 0 {
		last_write_time = data.last_write_time
	}

	l := last_write_time.low_date_time as File_Time
	h := last_write_time.high_date_time as File_Time
	return l | h << 32
}




File_Standard :: type enum {
	INPUT,
	OUTPUT,
	ERROR,
}

// NOTE(bill): Uses startup to initialize it
__std_files := [File_Standard.count]File{
	{handle = win32.GetStdHandle(win32.STD_INPUT_HANDLE)  transmute File.Handle },
	{handle = win32.GetStdHandle(win32.STD_OUTPUT_HANDLE) transmute File.Handle },
	{handle = win32.GetStdHandle(win32.STD_ERROR_HANDLE)  transmute File.Handle },
}

stdin  := ^__std_files[File_Standard.INPUT]
stdout := ^__std_files[File_Standard.OUTPUT]
stderr := ^__std_files[File_Standard.ERROR]



read_entire_file :: proc(name: string) -> ([]byte, bool) {
	buf: [300]byte
	copy(buf[:], name as []byte)

	f, file_ok := open(name)
	if !file_ok {
		return nil, false
	}
	defer close(^f)

	length: i64
	file_size_ok := win32.GetFileSizeEx(f.handle.p as win32.HANDLE, ^length) != 0
	if !file_size_ok {
		return nil, false
	}

	data := new_slice(u8, length)
	if data.data == nil {
		return nil, false
	}

	single_read_length: i32
	total_read: i64

	for total_read < length {
		remaining := length - total_read
		to_read: u32
		MAX :: 1<<32-1
		if remaining <= MAX {
			to_read = remaining as u32
		} else {
			to_read = MAX
		}

		win32.ReadFile(f.handle.p as win32.HANDLE, ^data[total_read], to_read, ^single_read_length, nil)
		if single_read_length <= 0 {
			free(data.data)
			return nil, false
		}

		total_read += single_read_length as i64
	}

	return data, true
}



heap_alloc :: proc(size: int) -> rawptr {
	return win32.HeapAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, size)
}
heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	return win32.HeapReAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, ptr, new_size)
}
heap_free :: proc(ptr: rawptr) {
	win32.HeapFree(win32.GetProcessHeap(), 0, ptr)
}


exit :: proc(code: int) {
	win32.ExitProcess(code as u32)
}



current_thread_id :: proc() -> int {
	GetCurrentThreadId :: proc() -> u32 #foreign #dll_import
	return GetCurrentThreadId() as int
}

