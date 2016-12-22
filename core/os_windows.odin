import {
	win32 "sys/windows.odin";
	"fmt.odin";
}

type {
	File_Time u64;

	File_Handle raw_union {
		p rawptr;
		i int;
	}

	File struct {
		handle          File_Handle;
		last_write_time File_Time;
	}
}

proc open(name string) -> (File, bool) {
	using win32;
	var buf [300]byte;
	var f File;
	copy(buf[:], name as []byte);
	f.handle.p = CreateFileA(^buf[0], FILE_GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, nil) as rawptr;
	var success = f.handle.p != INVALID_HANDLE_VALUE;
	f.last_write_time = last_write_time(^f);
	return f, success;
}

proc create(name string) -> (File, bool) {
	using win32;
	var buf [300]byte;
	var f File;
	copy(buf[:], name as []byte);
	f.handle.p = CreateFileA(^buf[0], FILE_GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, 0, nil) as rawptr;
	var success = f.handle.p != INVALID_HANDLE_VALUE;
	f.last_write_time = last_write_time(^f);
	return f, success;
}

proc close(using f ^File) {
	win32.CloseHandle(handle.p as win32.HANDLE);
}

proc write(using f ^File, buf []byte) -> bool {
	var bytes_written i32;
	return win32.WriteFile(handle.p as win32.HANDLE, buf.data, buf.count as i32, ^bytes_written, nil) != 0;
}

proc file_has_changed(f ^File) -> bool {
	var last_write_time = last_write_time(f);
	if f.last_write_time != last_write_time {
		f.last_write_time = last_write_time;
		return true;
	}
	return false;
}



proc last_write_time(f ^File) -> File_Time {
	var file_info win32.BY_HANDLE_FILE_INFORMATION;
	win32.GetFileInformationByHandle(f.handle.p as win32.HANDLE, ^file_info);
	var l = file_info.last_write_time.low_date_time as File_Time;
	var h = file_info.last_write_time.high_date_time as File_Time;
	return l | h << 32;
}

proc last_write_time_by_name(name string) -> File_Time {
	var last_write_time win32.FILETIME;
	var data win32.WIN32_FILE_ATTRIBUTE_DATA;
	var buf [1024]byte;

	assert(buf.count > name.count);

	copy(buf[:], name as []byte);

	if win32.GetFileAttributesExA(^buf[0], win32.GetFileExInfoStandard, ^data) != 0 {
		last_write_time = data.last_write_time;
	}

	var l = last_write_time.low_date_time as File_Time;
	var h = last_write_time.high_date_time as File_Time;
	return l | h << 32;
}



const {
	FILE_STANDARD_INPUT = iota;
	FILE_STANDARD_OUTPUT;
	FILE_STANDARD_ERROR;

	FILE_STANDARD_COUNT;
}
// NOTE(bill): Uses startup to initialize it
var {
	__std_files = [FILE_STANDARD_COUNT]File{
		{handle = win32.GetStdHandle(win32.STD_INPUT_HANDLE)  transmute File_Handle },
		{handle = win32.GetStdHandle(win32.STD_OUTPUT_HANDLE) transmute File_Handle },
		{handle = win32.GetStdHandle(win32.STD_ERROR_HANDLE)  transmute File_Handle },
	};

	stdin  = ^__std_files[FILE_STANDARD_INPUT];
	stdout = ^__std_files[FILE_STANDARD_OUTPUT];
	stderr = ^__std_files[FILE_STANDARD_ERROR];
}


proc read_entire_file(name string) -> ([]byte, bool) {
	var buf [300]byte;
	copy(buf[:], name as []byte);

	var f, file_ok = open(name);
	if !file_ok {
		return nil, false;
	}
	defer close(^f);

	var length i64;
	var file_size_ok = win32.GetFileSizeEx(f.handle.p as win32.HANDLE, ^length) != 0;
	if !file_size_ok {
		return nil, false;
	}

	var data = new_slice(u8, length);
	if data.data == nil {
		return nil, false;
	}

	var single_read_length i32;
	var total_read i64;

	for total_read < length {
		var remaining = length - total_read;
		var to_read u32;
		const MAX = 1<<32-1;
		if remaining <= MAX {
			to_read = remaining as u32;
		} else {
			to_read = MAX;
		}

		win32.ReadFile(f.handle.p as win32.HANDLE, ^data[total_read], to_read, ^single_read_length, nil);
		if single_read_length <= 0 {
			free(data.data);
			return nil, false;
		}

		total_read += single_read_length as i64;
	}

	return data, true;
}



proc heap_alloc(size int) -> rawptr {
	return win32.HeapAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, size);
}
proc heap_resize(ptr rawptr, new_size int) -> rawptr {
	return win32.HeapReAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, ptr, new_size);
}
proc heap_free(ptr rawptr) {
	win32.HeapFree(win32.GetProcessHeap(), 0, ptr);
}


proc exit(code int) {
	win32.ExitProcess(code as u32);
}



proc current_thread_id() -> int {
	proc GetCurrentThreadId() -> u32 #foreign #dll_import
	return GetCurrentThreadId() as int;
}

