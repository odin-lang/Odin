import win32 "sys/windows.odin";

type {
	Handle   int;
	FileTime u64;
}

const INVALID_HANDLE: Handle = -1;


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

type Errno int;
const {
	ERROR_NONE:               Errno = 0;
	ERROR_FILE_NOT_FOUND            = 2;
	ERROR_PATH_NOT_FOUND            = 3;
	ERROR_ACCESS_DENIED             = 5;
	ERROR_NO_MORE_FILES             = 18;
	ERROR_HANDLE_EOF                = 38;
	ERROR_NETNAME_DELETED           = 64;
	ERROR_FILE_EXISTS               = 80;
	ERROR_BROKEN_PIPE               = 109;
	ERROR_BUFFER_OVERFLOW           = 111;
	ERROR_INSUFFICIENT_BUFFER       = 122;
	ERROR_MOD_NOT_FOUND             = 126;
	ERROR_PROC_NOT_FOUND            = 127;
	ERROR_DIR_NOT_EMPTY             = 145;
	ERROR_ALREADY_EXISTS            = 183;
	ERROR_ENVVAR_NOT_FOUND          = 203;
	ERROR_MORE_DATA                 = 234;
	ERROR_OPERATION_ABORTED         = 995;
	ERROR_IO_PENDING                = 997;
	ERROR_NOT_FOUND                 = 1168;
	ERROR_PRIVILEGE_NOT_HELD        = 1314;
	WSAEACCES                       = 10013;
	WSAECONNRESET                   = 10054;

	// Windows reserves errors >= 1<<29 for application use
	ERROR_FILE_IS_PIPE              = 1<<29 + 0;
}

// "Argv" arguments converted to Odin strings
let args = _alloc_command_line_arguments();


proc open(path: string, mode: int, perm: u32) -> (Handle, Errno) {
	if len(path) == 0 {
		return INVALID_HANDLE, ERROR_FILE_NOT_FOUND;
	}

	var access: u32;
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

	var share_mode = u32(win32.FILE_SHARE_READ|win32.FILE_SHARE_WRITE);
	var sa: ^win32.Security_Attributes = nil;
	var sa_inherit = win32.Security_Attributes{length = size_of(win32.Security_Attributes), inherit_handle = 1};
	if mode&O_CLOEXEC == 0 {
		sa = &sa_inherit;
	}

	var create_mode: u32;
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

	var buf: [300]u8;
	copy(buf[..], []u8(path));

	var handle = Handle(win32.create_file_a(&buf[0], access, share_mode, sa, create_mode, win32.FILE_ATTRIBUTE_NORMAL, nil));
	if handle != INVALID_HANDLE {
		return handle, ERROR_NONE;
	}
	var err = win32.get_last_error();
	return INVALID_HANDLE, Errno(err);
}

proc close(fd: Handle) {
	win32.close_handle(win32.Handle(fd));
}


proc write(fd: Handle, data: []u8) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE;
	}
	var single_write_length: i32;
	var total_write: i64;
	var length = i64(len(data));

	for total_write < length {
		var remaining = length - total_write;
		var to_read: i32;
		const MAX = 1<<31-1;
		if remaining <= MAX {
			to_read = i32(remaining);
		} else {
			to_read = MAX;
		}
		var e = win32.write_file(win32.Handle(fd), &data[total_write], to_read, &single_write_length, nil);
		if single_write_length <= 0 || e == win32.FALSE {
			var err = win32.get_last_error();
			return int(total_write), Errno(e);
		}
		total_write += i64(single_write_length);
	}
	return int(total_write), ERROR_NONE;
}

proc read(fd: Handle, data: []u8) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE;
	}

	var single_read_length: i32;
	var total_read: i64;
	var length = i64(len(data));

	for total_read < length {
		var remaining = length - total_read;
		var to_read: u32;
		const MAX = 1<<32-1;
		if remaining <= MAX {
			to_read = u32(remaining);
		} else {
			to_read = MAX;
		}

		var e = win32.read_file(win32.Handle(fd), &data[total_read], to_read, &single_read_length, nil);
		if single_read_length <= 0 || e == win32.FALSE {
			var err = win32.get_last_error();
			return int(total_read), Errno(e);
		}
		total_read += i64(single_read_length);
	}
	return int(total_read), ERROR_NONE;
}

proc seek(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	var w: u32;
	match whence {
	case 0: w = win32.FILE_BEGIN;
	case 1: w = win32.FILE_CURRENT;
	case 2: w = win32.FILE_END;
	}
	var hi = i32(offset>>32);
	var lo = i32(offset);
	var ft = win32.get_file_type(win32.Handle(fd));
	if ft == win32.FILE_TYPE_PIPE {
		return 0, ERROR_FILE_IS_PIPE;
	}
	var dw_ptr = win32.set_file_pointer(win32.Handle(fd), lo, &hi, w);
	if dw_ptr == win32.INVALID_SET_FILE_POINTER {
		var err = win32.get_last_error();
		return 0, Errno(err);
	}
	return i64(hi)<<32 + i64(dw_ptr), ERROR_NONE;
}

proc file_size(fd: Handle) -> (i64, Errno) {
	var length: i64;
	var err: Errno;
	if win32.get_file_size_ex(win32.Handle(fd), &length) == 0 {
		err = Errno(win32.get_last_error());
	}
	return length, err;
}



// NOTE(bill): Uses startup to initialize it
var stdin  = get_std_handle(win32.STD_INPUT_HANDLE);
var stdout = get_std_handle(win32.STD_OUTPUT_HANDLE);
var stderr = get_std_handle(win32.STD_ERROR_HANDLE);


proc get_std_handle(h: int) -> Handle {
	var fd = win32.get_std_handle(i32(h));
	win32.set_handle_information(fd, win32.HANDLE_FLAG_INHERIT, 0);
	return Handle(fd);
}






proc last_write_time(fd: Handle) -> FileTime {
	var file_info: win32.ByHandleFileInformation;
	win32.get_file_information_by_handle(win32.Handle(fd), &file_info);
	var lo = FileTime(file_info.last_write_time.lo);
	var hi = FileTime(file_info.last_write_time.hi);
	return lo | hi << 32;
}

proc last_write_time_by_name(name: string) -> FileTime {
	var last_write_time: win32.Filetime;
	var data: win32.FileAttributeData;
	var buf: [1024]u8;

	assert(len(buf) > len(name));

	copy(buf[..], []u8(name));

	if win32.get_file_attributes_ex_a(&buf[0], win32.GetFileExInfoStandard, &data) != 0 {
		last_write_time = data.last_write_time;
	}

	var l = FileTime(last_write_time.lo);
	var h = FileTime(last_write_time.hi);
	return l | h << 32;
}



proc heap_alloc(size: int) -> rawptr {
	return win32.heap_alloc(win32.get_process_heap(), win32.HEAP_ZERO_MEMORY, size);
}
proc heap_resize(ptr: rawptr, new_size: int) -> rawptr {
	if new_size == 0 {
		heap_free(ptr);
		return nil;
	}
	if ptr == nil {
		return heap_alloc(new_size);
	}
	return win32.heap_realloc(win32.get_process_heap(), win32.HEAP_ZERO_MEMORY, ptr, new_size);
}
proc heap_free(ptr: rawptr) {
	if ptr == nil {
		return;
	}
	win32.heap_free(win32.get_process_heap(), 0, ptr);
}


proc exit(code: int) {
	win32.exit_process(u32(code));
}



proc current_thread_id() -> int {
	return int(win32.get_current_thread_id());
}




proc _alloc_command_line_arguments() -> []string {
	proc alloc_ucs2_to_utf8(wstr: ^u16) -> string {
		var wstr_len = 0;
		for (wstr+wstr_len)^ != 0 {
			wstr_len++;
		}
		var len = 2*wstr_len-1;
		var buf = make([]u8, len+1);
		var str = slice_ptr(wstr, wstr_len+1);

		var i, j = 0, 0;
		for str[j] != 0 {
			match {
			case str[j] < 0x80:
				if i+1 > len {
					return "";
				}
				buf[i] = u8(str[j]); i++;
				j++;
			case str[j] < 0x800:
				if i+2 > len {
					return "";
				}
				buf[i] = u8(0xc0 + (str[j]>>6));   i++;
				buf[i] = u8(0x80 + (str[j]&0x3f)); i++;
				j++;
			case 0xd800 <= str[j] && str[j] < 0xdc00:
				if i+4 > len {
					return "";
				}
				var c = rune((str[j] - 0xd800) << 10) + rune((str[j+1]) - 0xdc00) + 0x10000;
				buf[i] = u8(0xf0 +  (c >> 18));         i++;
				buf[i] = u8(0x80 + ((c >> 12) & 0x3f)); i++;
				buf[i] = u8(0x80 + ((c >>  6) & 0x3f)); i++;
				buf[i] = u8(0x80 + ((c      ) & 0x3f)); i++;
				j += 2;
			case 0xdc00 <= str[j] && str[j] < 0xe000:
				return "";
			case:
				if i+3 > len {
					return "";
				}
				buf[i] = 0xe0 + u8 (str[j] >> 12);         i++;
				buf[i] = 0x80 + u8((str[j] >>  6) & 0x3f); i++;
				buf[i] = 0x80 + u8((str[j]      ) & 0x3f); i++;
				j++;
			}
		}

		return string(buf[0..<i]);
	}

	var arg_count: i32;
	var arg_list_ptr = win32.command_line_to_argv_w(win32.get_command_line_w(), &arg_count);
	var arg_list = make([]string, arg_count);
	for _, i in arg_list {
		arg_list[i] = alloc_ucs2_to_utf8((arg_list_ptr+i)^);
	}
	return arg_list;
}


