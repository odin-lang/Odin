import {
	win32 "sys/windows.odin";
	"fmt.odin";
}


type {
	Handle    uint;
	File_Time u64;
	Error     int;
}

const INVALID_HANDLE Handle = ~(0 as Handle);

const {
	O_RDONLY   = 0x00000;
	O_WRONLY   = 0x00001;
	O_RDWR     = 0x00002;
	O_CREAT    = 0x00040;
	O_EXCL     = 0x00080;
	O_NOCTTY   = 0x00100;
	O_TRUNC    = 0x00200;
	O_NONBLOCK = 0x00800;
	O_APPEND   = 0x00400;
	O_SYNC     = 0x01000;
	O_ASYNC    = 0x02000;
	O_CLOEXEC  = 0x80000;
}

const {
	ERROR_NONE                Error = 0;
	ERROR_FILE_NOT_FOUND      Error = 2;
	ERROR_PATH_NOT_FOUND      Error = 3;
	ERROR_ACCESS_DENIED       Error = 5;
	ERROR_NO_MORE_FILES       Error = 18;
	ERROR_HANDLE_EOF          Error = 38;
	ERROR_NETNAME_DELETED     Error = 64;
	ERROR_FILE_EXISTS         Error = 80;
	ERROR_BROKEN_PIPE         Error = 109;
	ERROR_BUFFER_OVERFLOW     Error = 111;
	ERROR_INSUFFICIENT_BUFFER Error = 122;
	ERROR_MOD_NOT_FOUND       Error = 126;
	ERROR_PROC_NOT_FOUND      Error = 127;
	ERROR_DIR_NOT_EMPTY       Error = 145;
	ERROR_ALREADY_EXISTS      Error = 183;
	ERROR_ENVVAR_NOT_FOUND    Error = 203;
	ERROR_MORE_DATA           Error = 234;
	ERROR_OPERATION_ABORTED   Error = 995;
	ERROR_IO_PENDING          Error = 997;
	ERROR_NOT_FOUND           Error = 1168;
	ERROR_PRIVILEGE_NOT_HELD  Error = 1314;
	WSAEACCES                 Error = 10013;
	WSAECONNRESET             Error = 10054;
}

const { // Windows reserves errors >= 1<<29 for application use
	ERROR_FILE_IS_PIPE Error = 1<<29 + 0;
}




proc open(path string, mode int, perm u32) -> (Handle, Error) {
	using win32;
	if path.count == 0 {
		return INVALID_HANDLE, ERROR_FILE_NOT_FOUND;
	}

	var access u32;
	match mode & (O_RDONLY|O_WRONLY|O_RDWR) {
	case O_RDONLY: access = FILE_GENERIC_READ;
	case O_WRONLY: access = FILE_GENERIC_WRITE;
	case O_RDWR:   access = FILE_GENERIC_READ | FILE_GENERIC_WRITE;
	}

	if mode&O_CREAT != 0 {
		access |= FILE_GENERIC_WRITE;
	}
	if mode&O_APPEND != 0 {
		access &~= FILE_GENERIC_WRITE;
		access |= FILE_APPEND_DATA;
	}

	var share_mode = (FILE_SHARE_READ|FILE_SHARE_WRITE) as u32;
	var sa ^SECURITY_ATTRIBUTES = nil;
	var sa_inherit = SECURITY_ATTRIBUTES{length = size_of(SECURITY_ATTRIBUTES), inherit_handle = 1};
	if mode&O_CLOEXEC == 0 {
		sa = ^sa_inherit;
	}

	var create_mode u32;
	match {
	case mode&(O_CREAT|O_EXCL) == (O_CREAT | O_EXCL):
		create_mode = CREATE_NEW;
	case mode&(O_CREAT|O_TRUNC) == (O_CREAT | O_TRUNC):
		create_mode = CREATE_ALWAYS;
	case mode&O_CREAT == O_CREAT:
		create_mode = OPEN_ALWAYS;
	case mode&O_TRUNC == O_TRUNC:
		create_mode = TRUNCATE_EXISTING;
	default:
		create_mode = OPEN_EXISTING;
	}

	var buf [300]byte;
	copy(buf[:], path as []byte);

	var handle = CreateFileA(^buf[0], access, share_mode, sa, create_mode, FILE_ATTRIBUTE_NORMAL, nil) as Handle;
	if handle == INVALID_HANDLE {
		return handle, ERROR_NONE;
	}
	var err = GetLastError();
	return INVALID_HANDLE, err as Error;
}

proc close(fd Handle) {
	win32.CloseHandle(fd as win32.HANDLE);
}

proc write(fd Handle, data []byte) -> (int, Error) {
	var bytes_written i32;
	var e = win32.WriteFile(fd as win32.HANDLE, data.data, data.count as i32, ^bytes_written, nil);
	if e != 0 {
		return 0, e as Error;
	}
	return bytes_written as int, ERROR_NONE;
}

proc read(fd Handle, data []byte) -> (int, Error) {
	var bytes_read i32;
	var e = win32.ReadFile(fd as win32.HANDLE, data.data, data.count as u32, ^bytes_read, nil);
	if e != win32.FALSE {
		var err = win32.GetLastError();
		return 0, err as Error;
	}
	return bytes_read as int, ERROR_NONE;
}

proc seek(fd Handle, offset i64, whence int) -> (i64, Error) {
	using win32;
	var w u32;
	match whence {
	case 0: w = FILE_BEGIN;
	case 1: w = FILE_CURRENT;
	case 2: w = FILE_END;
	}
	var hi = (offset>>32) as i32;
	var lo = offset as i32;
	var ft = GetFileType(fd as HANDLE);
	if ft == FILE_TYPE_PIPE {
		return 0, ERROR_FILE_IS_PIPE;
	}
	var dw_ptr = SetFilePointer(fd as HANDLE, lo, ^hi, w);
	if dw_ptr == INVALID_SET_FILE_POINTER {
		var err = GetLastError();
		return 0, err as Error;
	}
	return (hi as i64)<<32 + (dw_ptr as i64), ERROR_NONE;
}


// NOTE(bill): Uses startup to initialize it
var {
	stdin  = get_std_handle(win32.STD_INPUT_HANDLE);
	stdout = get_std_handle(win32.STD_OUTPUT_HANDLE);
	stderr = get_std_handle(win32.STD_ERROR_HANDLE);
}

proc get_std_handle(h int) -> Handle {
	var fd = win32.GetStdHandle(h as i32);
	win32.SetHandleInformation(fd, win32.HANDLE_FLAG_INHERIT, 0);
	return fd as Handle;
}






proc last_write_time(fd Handle) -> File_Time {
	var file_info win32.BY_HANDLE_FILE_INFORMATION;
	win32.GetFileInformationByHandle(fd as win32.HANDLE, ^file_info);
	var lo = file_info.last_write_time.lo as File_Time;
	var hi = file_info.last_write_time.hi as File_Time;
	return lo | hi << 32;
}

proc last_write_time_by_name(name string) -> File_Time {
	var last_write_time win32.FILETIME;
	var data win32.FILE_ATTRIBUTE_DATA;
	var buf [1024]byte;

	assert(buf.count > name.count);

	copy(buf[:], name as []byte);

	if win32.GetFileAttributesExA(^buf[0], win32.GetFileExInfoStandard, ^data) != 0 {
		last_write_time = data.last_write_time;
	}

	var l = last_write_time.lo as File_Time;
	var h = last_write_time.hi as File_Time;
	return l | h << 32;
}





proc read_entire_file(name string) -> ([]byte, bool) {
	var buf [300]byte;
	copy(buf[:], name as []byte);

	var fd, err = open(name, O_RDONLY, 0);
	if err != ERROR_NONE {
		return nil, false;
	}
	defer close(fd);

	var length i64;
	var file_size_ok = win32.GetFileSizeEx(fd as win32.HANDLE, ^length) != 0;
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

		win32.ReadFile(fd as win32.HANDLE, ^data[total_read], to_read, ^single_read_length, nil);
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



