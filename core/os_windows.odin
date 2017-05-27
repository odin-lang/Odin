#import win32 "sys/windows.odin";

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


// "Argv" arguments converted to Odin strings
immutable args := _alloc_command_line_arguments();


open :: proc(path: string, mode: int, perm: u32) -> (Handle, Errno) {
	if len(path) == 0 {
		return INVALID_HANDLE, ERROR_FILE_NOT_FOUND;
	}

	access: u32;
	match mode & (O_RDONLY|O_WRONLY|O_RDWR) {
	case O_RDONLY: access = win32.FILE_GENERIC_READ;
	case O_WRONLY: access = win32.FILE_GENERIC_WRITE;
	case O_RDWR:   access = win32.FILE_GENERIC_READ | win32.FILE_GENERIC_WRITE;
	}

	if mode&O_CREAT != 0 {
		access |= win32.FILE_GENERIC_WRITE;
	}
	if mode&O_APPEND != 0 {
		access &~= win32.FILE_GENERIC_WRITE;
		access |=  win32.FILE_APPEND_DATA;
	}

	share_mode := u32(win32.FILE_SHARE_READ|win32.FILE_SHARE_WRITE);
	sa: ^win32.Security_Attributes = nil;
	sa_inherit := win32.Security_Attributes{length = size_of(win32.Security_Attributes), inherit_handle = 1};
	if mode&O_CLOEXEC == 0 {
		sa = &sa_inherit;
	}

	create_mode: u32;
	match {
	case mode&(O_CREAT|O_EXCL) == (O_CREAT | O_EXCL):
		create_mode = win32.CREATE_NEW;
	case mode&(O_CREAT|O_TRUNC) == (O_CREAT | O_TRUNC):
		create_mode = win32.CREATE_ALWAYS;
	case mode&O_CREAT == O_CREAT:
		create_mode = win32.OPEN_ALWAYS;
	case mode&O_TRUNC == O_TRUNC:
		create_mode = win32.TRUNCATE_EXISTING;
	case:
		create_mode = win32.OPEN_EXISTING;
	}

	buf: [300]byte;
	copy(buf[..], []byte(path));

	handle := Handle(win32.CreateFileA(&buf[0], access, share_mode, sa, create_mode, win32.FILE_ATTRIBUTE_NORMAL, nil));
	if handle != INVALID_HANDLE {
		return handle, ERROR_NONE;
	}
	err := win32.GetLastError();
	return INVALID_HANDLE, Errno(err);
}

close :: proc(fd: Handle) {
	win32.CloseHandle(win32.Handle(fd));
}


write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE;
	}
	single_write_length: i32;
	total_write: i64;
	length := i64(len(data));

	for total_write < length {
		remaining := length - total_write;
		to_read: i32;
		MAX :: 1<<31-1;
		if remaining <= MAX {
			to_read = i32(remaining);
		} else {
			to_read = MAX;
		}
		e := win32.WriteFile(win32.Handle(fd), &data[total_write], to_read, &single_write_length, nil);
		if single_write_length <= 0 || e == win32.FALSE {
			err := win32.GetLastError();
			return int(total_write), Errno(e);
		}
		total_write += i64(single_write_length);
	}
	return int(total_write), ERROR_NONE;
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE;
	}

	single_read_length: i32;
	total_read: i64;
	length := i64(len(data));

	for total_read < length {
		remaining := length - total_read;
		to_read: u32;
		MAX :: 1<<32-1;
		if remaining <= MAX {
			to_read = u32(remaining);
		} else {
			to_read = MAX;
		}

		e := win32.ReadFile(win32.Handle(fd), &data[total_read], to_read, &single_read_length, nil);
		if single_read_length <= 0 || e == win32.FALSE {
			err := win32.GetLastError();
			return int(total_read), Errno(e);
		}
		total_read += i64(single_read_length);
	}
	return int(total_read), ERROR_NONE;
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	w: u32;
	match whence {
	case 0: w = win32.FILE_BEGIN;
	case 1: w = win32.FILE_CURRENT;
	case 2: w = win32.FILE_END;
	}
	hi := i32(offset>>32);
	lo := i32(offset);
	ft := win32.GetFileType(win32.Handle(fd));
	if ft == win32.FILE_TYPE_PIPE {
		return 0, ERROR_FILE_IS_PIPE;
	}
	dw_ptr := win32.SetFilePointer(win32.Handle(fd), lo, &hi, w);
	if dw_ptr == win32.INVALID_SET_FILE_POINTER {
		err := win32.GetLastError();
		return 0, Errno(err);
	}
	return i64(hi)<<32 + i64(dw_ptr), ERROR_NONE;
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	length: i64;
	err: Errno;
	if win32.GetFileSizeEx(win32.Handle(fd), &length) == 0 {
		err = Errno(win32.GetLastError());
	}
	return length, err;
}



// NOTE(bill): Uses startup to initialize it
stdin  := get_std_handle(win32.STD_INPUT_HANDLE);
stdout := get_std_handle(win32.STD_OUTPUT_HANDLE);
stderr := get_std_handle(win32.STD_ERROR_HANDLE);


get_std_handle :: proc(h: int) -> Handle {
	fd := win32.GetStdHandle(i32(h));
	win32.SetHandleInformation(fd, win32.HANDLE_FLAG_INHERIT, 0);
	return Handle(fd);
}






last_write_time :: proc(fd: Handle) -> File_Time {
	file_info: win32.By_Handle_File_Information;
	win32.GetFileInformationByHandle(win32.Handle(fd), &file_info);
	lo := File_Time(file_info.last_write_time.lo);
	hi := File_Time(file_info.last_write_time.hi);
	return lo | hi << 32;
}

last_write_time_by_name :: proc(name: string) -> File_Time {
	last_write_time: win32.Filetime;
	data: win32.File_Attribute_Data;
	buf: [1024]byte;

	assert(len(buf) > len(name));

	copy(buf[..], []byte(name));

	if win32.GetFileAttributesExA(&buf[0], win32.GetFileExInfoStandard, &data) != 0 {
		last_write_time = data.last_write_time;
	}

	l := File_Time(last_write_time.lo);
	h := File_Time(last_write_time.hi);
	return l | h << 32;
}



heap_alloc :: proc(size: int) -> rawptr {
	return win32.HeapAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, size);
}
heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	if new_size == 0 {
		heap_free(ptr);
		return nil;
	}
	if ptr == nil {
		return heap_alloc(new_size);
	}
	return win32.HeapReAlloc(win32.GetProcessHeap(), win32.HEAP_ZERO_MEMORY, ptr, new_size);
}
heap_free :: proc(ptr: rawptr) {
	if ptr == nil {
		return;
	}
	win32.HeapFree(win32.GetProcessHeap(), 0, ptr);
}


exit :: proc(code: int) {
	win32.ExitProcess(u32(code));
}



current_thread_id :: proc() -> int {
	return int(win32.GetCurrentThreadId());
}




_alloc_command_line_arguments :: proc() -> []string {
	alloc_ucs2_to_utf8 :: proc(wstr: ^u16) -> string {
		wstr_len := 0;
		for (wstr+wstr_len)^ != 0 {
			wstr_len++;
		}
		len := 2*wstr_len-1;
		buf := make([]byte, len+1);
		str := slice_ptr(wstr, wstr_len+1);

		i, j := 0, 0;
		for str[j] != 0 {
			match {
			case str[j] < 0x80:
				if i+1 > len {
					return "";
				}
				buf[i] = byte(str[j]); i++;
				j++;
			case str[j] < 0x800:
				if i+2 > len {
					return "";
				}
				buf[i] = byte(0xc0 + (str[j]>>6));   i++;
				buf[i] = byte(0x80 + (str[j]&0x3f)); i++;
				j++;
			case 0xd800 <= str[j] && str[j] < 0xdc00:
				if i+4 > len {
					return "";
				}
				c := rune((str[j] - 0xd800) << 10) + rune((str[j+1]) - 0xdc00) + 0x10000;
				buf[i] = byte(0xf0 +  (c >> 18));         i++;
				buf[i] = byte(0x80 + ((c >> 12) & 0x3f)); i++;
				buf[i] = byte(0x80 + ((c >>  6) & 0x3f)); i++;
				buf[i] = byte(0x80 + ((c      ) & 0x3f)); i++;
				j += 2;
			case 0xdc00 <= str[j] && str[j] < 0xe000:
				return "";
			case:
				if i+3 > len {
					return "";
				}
				buf[i] = 0xe0 + byte (str[j] >> 12);         i++;
				buf[i] = 0x80 + byte((str[j] >>  6) & 0x3f); i++;
				buf[i] = 0x80 + byte((str[j]      ) & 0x3f); i++;
				j++;
			}
		}

		return string(buf[0..<i]);
	}

	arg_count: i32;
	arg_list_ptr := win32.CommandLineToArgvW(win32.GetCommandLineW(), &arg_count);
	arg_list := make([]string, arg_count);
	for _, i in arg_list {
		arg_list[i] = alloc_ucs2_to_utf8((arg_list_ptr+i)^);
	}
	return arg_list;
}


