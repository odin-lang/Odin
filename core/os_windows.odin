#import win32 "sys/windows.odin";
#import "fmt.odin";


Handle    :: int;
File_Time :: u64;
Errno     :: int;

INVALID_HANDLE: Handle : -1;


O_RDONLY   :: 0x00000;
O_WRONLY   :: 0x00001;
O_RDWR     :: 0x00002;
O_CREAT    :: 0x00040;
O_EXCL     :: 0x00080;
O_NOCTTY   :: 0x00100;
O_TRUNC    :: 0x00200;
O_NONBLOCK :: 0x00800;
O_APPEND   :: 0x00400;
O_SYNC     :: 0x01000;
O_ASYNC    :: 0x02000;
O_CLOEXEC  :: 0x80000;

ERROR_NONE:                Errno : 0;
ERROR_FILE_NOT_FOUND:      Errno : 2;
ERROR_PATH_NOT_FOUND:      Errno : 3;
ERROR_ACCESS_DENIED:       Errno : 5;
ERROR_NO_MORE_FILES:       Errno : 18;
ERROR_HANDLE_EOF:          Errno : 38;
ERROR_NETNAME_DELETED:     Errno : 64;
ERROR_FILE_EXISTS:         Errno : 80;
ERROR_BROKEN_PIPE:         Errno : 109;
ERROR_BUFFER_OVERFLOW:     Errno : 111;
ERROR_INSUFFICIENT_BUFFER: Errno : 122;
ERROR_MOD_NOT_FOUND:       Errno : 126;
ERROR_PROC_NOT_FOUND:      Errno : 127;
ERROR_DIR_NOT_EMPTY:       Errno : 145;
ERROR_ALREADY_EXISTS:      Errno : 183;
ERROR_ENVVAR_NOT_FOUND:    Errno : 203;
ERROR_MORE_DATA:           Errno : 234;
ERROR_OPERATION_ABORTED:   Errno : 995;
ERROR_IO_PENDING:          Errno : 997;
ERROR_NOT_FOUND:           Errno : 1168;
ERROR_PRIVILEGE_NOT_HELD:  Errno : 1314;
WSAEACCES:                 Errno : 10013;
WSAECONNRESET:             Errno : 10054;

// Windows reserves errors >= 1<<29 for application use
ERROR_FILE_IS_PIPE: Errno : 1<<29 + 0;




open :: proc(path: string, mode: int, perm: u32) -> (Handle, Errno) {
	using win32;
	if path.count == 0 {
		return INVALID_HANDLE, ERROR_FILE_NOT_FOUND;
	}

	access: u32;
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

	share_mode := cast(u32)(FILE_SHARE_READ|FILE_SHARE_WRITE);
	sa: ^SECURITY_ATTRIBUTES = nil;
	sa_inherit := SECURITY_ATTRIBUTES{length = size_of(SECURITY_ATTRIBUTES), inherit_handle = 1};
	if mode&O_CLOEXEC == 0 {
		sa = ^sa_inherit;
	}

	create_mode: u32;
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

	buf: [300]byte;
	copy(buf[:], cast([]byte)path);

	handle := cast(Handle)CreateFileA(^buf[0], access, share_mode, sa, create_mode, FILE_ATTRIBUTE_NORMAL, nil);
	if handle != INVALID_HANDLE {
		return handle, ERROR_NONE;
	}
	err := GetLastError();
	return INVALID_HANDLE, cast(Errno)err;
}

close :: proc(fd: Handle) {
	win32.CloseHandle(cast(win32.HANDLE)fd);
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	bytes_written: i32;
	e := win32.WriteFile(cast(win32.HANDLE)fd, data.data, cast(i32)data.count, ^bytes_written, nil);
	if e == win32.FALSE {
		err := win32.GetLastError();
		return 0, cast(Errno)err;
	}
	return cast(int)bytes_written, ERROR_NONE;
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	bytes_read: i32;
	e := win32.ReadFile(cast(win32.HANDLE)fd, data.data, cast(u32)data.count, ^bytes_read, nil);
	if e == win32.FALSE {
		err := win32.GetLastError();
		return 0, cast(Errno)err;
	}
	return cast(int)bytes_read, ERROR_NONE;
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	using win32;
	w: u32;
	match whence {
	case 0: w = FILE_BEGIN;
	case 1: w = FILE_CURRENT;
	case 2: w = FILE_END;
	}
	hi := cast(i32)(offset>>32);
	lo := cast(i32)(offset);
	ft := GetFileType(cast(HANDLE)fd);
	if ft == FILE_TYPE_PIPE {
		return 0, ERROR_FILE_IS_PIPE;
	}
	dw_ptr := SetFilePointer(cast(HANDLE)fd, lo, ^hi, w);
	if dw_ptr == INVALID_SET_FILE_POINTER {
		err := GetLastError();
		return 0, cast(Errno)err;
	}
	return cast(i64)hi<<32 + cast(i64)dw_ptr, ERROR_NONE;
}


// NOTE(bill): Uses startup to initialize it
stdin  := get_std_handle(win32.STD_INPUT_HANDLE);
stdout := get_std_handle(win32.STD_OUTPUT_HANDLE);
stderr := get_std_handle(win32.STD_ERROR_HANDLE);


get_std_handle :: proc(h: int) -> Handle {
	fd := win32.GetStdHandle(cast(i32)h);
	win32.SetHandleInformation(fd, win32.HANDLE_FLAG_INHERIT, 0);
	return cast(Handle)fd;
}






last_write_time :: proc(fd: Handle) -> File_Time {
	file_info: win32.BY_HANDLE_FILE_INFORMATION;
	win32.GetFileInformationByHandle(cast(win32.HANDLE)fd, ^file_info);
	lo := cast(File_Time)file_info.last_write_time.lo;
	hi := cast(File_Time)file_info.last_write_time.hi;
	return lo | hi << 32;
}

last_write_time_by_name :: proc(name: string) -> File_Time {
	last_write_time: win32.FILETIME;
	data: win32.FILE_ATTRIBUTE_DATA;
	buf: [1024]byte;

	assert(buf.count > name.count);

	copy(buf[:], cast([]byte)name);

	if win32.GetFileAttributesExA(^buf[0], win32.GetFileExInfoStandard, ^data) != 0 {
		last_write_time = data.last_write_time;
	}

	l := cast(File_Time)last_write_time.lo;
	h := cast(File_Time)last_write_time.hi;
	return l | h << 32;
}





read_entire_file :: proc(name: string) -> ([]byte, bool) {
	buf: [300]byte;
	copy(buf[:], cast([]byte)name);

	fd, err := open(name, O_RDONLY, 0);
	if err != ERROR_NONE {
		return nil, false;
	}
	defer close(fd);

	length: i64;
	file_size_ok := win32.GetFileSizeEx(cast(win32.HANDLE)fd, ^length) != 0;
	if !file_size_ok {
		return nil, false;
	}

	data := new_slice(u8, length);
	if data.data == nil {
		return nil, false;
	}

	single_read_length: i32;
	total_read: i64;

	for total_read < length {
		remaining := length - total_read;
		to_read: u32;
		MAX :: 1<<32-1;
		if remaining <= MAX {
			to_read = cast(u32)remaining;
		} else {
			to_read = MAX;
		}

		win32.ReadFile(cast(win32.HANDLE)fd, ^data[total_read], to_read, ^single_read_length, nil);
		if single_read_length <= 0 {
			free(data.data);
			return nil, false;
		}

		total_read += cast(i64)single_read_length;
	}

	return data, true;
}



heap_alloc :: proc(size: int) -> rawptr {
	return win32.HeapAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, size);
}
heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	return win32.HeapReAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, ptr, new_size);
}
heap_free :: proc(ptr: rawptr) {
	win32.HeapFree(win32.GetProcessHeap(), 0, ptr);
}


exit :: proc(code: int) {
	win32.ExitProcess(cast(u32)code);
}



current_thread_id :: proc() -> int {
	return cast(int)win32.GetCurrentThreadId();
}



