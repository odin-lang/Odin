// #import "fmt.odin";

Handle    :: i32;
File_Time :: u64;
Errno     :: int;

// INVALID_HANDLE: Handle : -1;


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

// NOTE(zangent): These are OS specific!
// Do not mix these up!
RTLD_LAZY         :: 0x001;
RTLD_NOW          :: 0x002;
RTLD_BINDING_MASK :: 0x3;
RTLD_GLOBAL       :: 0x100;

// ERROR_NONE:                Errno : 0;
// ERROR_FILE_NOT_FOUND:      Errno : 2;
// ERROR_PATH_NOT_FOUND:      Errno : 3;
// ERROR_ACCESS_DENIED:       Errno : 5;
// ERROR_NO_MORE_FILES:       Errno : 18;
// ERROR_HANDLE_EOF:          Errno : 38;
// ERROR_NETNAME_DELETED:     Errno : 64;
// ERROR_FILE_EXISTS:         Errno : 80;
// ERROR_BROKEN_PIPE:         Errno : 109;
// ERROR_BUFFER_OVERFLOW:     Errno : 111;
// ERROR_INSUFFICIENT_BUFFER: Errno : 122;
// ERROR_MOD_NOT_FOUND:       Errno : 126;
// ERROR_PROC_NOT_FOUND:      Errno : 127;
// ERROR_DIR_NOT_EMPTY:       Errno : 145;
// ERROR_ALREADY_EXISTS:      Errno : 183;
// ERROR_ENVVAR_NOT_FOUND:    Errno : 203;
// ERROR_MORE_DATA:           Errno : 234;
// ERROR_OPERATION_ABORTED:   Errno : 995;
// ERROR_IO_PENDING:          Errno : 997;
// ERROR_NOT_FOUND:           Errno : 1168;
// ERROR_PRIVILEGE_NOT_HELD:  Errno : 1314;
// WSAEACCES:                 Errno : 10013;
// WSAECONNRESET:             Errno : 10054;

// Windows reserves errors >= 1<<29 for application use
// ERROR_FILE_IS_PIPE: Errno : 1<<29 + 0;

#foreign_system_library libc "c";

unix_open   :: proc(path: ^u8, mode: int, perm: u32) -> Handle           #foreign libc "open";
unix_close  :: proc(handle: Handle)                                      #foreign libc "close";
unix_read   :: proc(handle: Handle, buffer: rawptr, count: int) -> int   #foreign libc "read";
unix_write  :: proc(handle: Handle, buffer: rawptr, count: int) -> int   #foreign libc "write";
//unix_gettid :: proc() -> u64                                             #foreign libc "gettid";

unix_malloc  :: proc(size: int) -> rawptr                                #foreign libc "malloc";
unix_free    :: proc(ptr: rawptr)                                        #foreign libc "free";
unix_realloc :: proc(ptr: rawptr, size: int) -> rawptr                   #foreign libc "realloc";

unix_exit :: proc(status: int)                                           #foreign libc "exit";

unix_dlopen :: proc(filename: ^u8, flags: int) -> rawptr                 #foreign dl   "dlopen";
unix_dlsym :: proc(handle: rawptr, symbol: ^u8) ->  (proc() #cc_c)       #foreign dl   "dlsym";
unix_dlclose :: proc(handle: rawptr) -> int                              #foreign dl   "dlclose";
unix_dlerror :: proc() -> ^u8                                            #foreign dl   "dlerror";




open :: proc(path: string, mode: int, perm: u32) -> (Handle, Errno) {
	return unix_open(path.data, mode, perm), 0;
}

close :: proc(fd: Handle) {
	unix_close(fd);
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	return unix_write(fd, data.data, data.count), 0;
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	return unix_read(fd, data.data, data.count), 0;
}


seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	/*
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

	*/
	return 0, 0;
}


// NOTE(bill): Uses startup to initialize it
stdin:  Handle = 0; // get_std_handle(win32.STD_INPUT_HANDLE);
stdout: Handle = 1; // get_std_handle(win32.STD_OUTPUT_HANDLE);
stderr: Handle = 2; // get_std_handle(win32.STD_ERROR_HANDLE);


/*
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
			free(data);
			return nil, false;
		}

		total_read += cast(i64)single_read_length;
	}

	return data, true;
}


*/

heap_alloc :: proc(size: int) -> rawptr {
	assert(size > 0);
	return unix_malloc(size);
}

heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	return unix_realloc(ptr, new_size);
}

heap_free :: proc(ptr: rawptr) {
	unix_free(ptr);
}

exit :: proc(code: int) {
	unix_exit(code);
}

current_thread_id :: proc() -> int {
	// return cast(int) unix_gettid();
	return 0;
}

dlopen :: proc(filename: string, flags: int) -> rawptr #inline {
	return unix_dlopen(filename.data, flags);
}
dlsym :: proc(handle: rawptr, symbol: string) -> (proc() #cc_c) #inline {
	assert(handle != nil);
	return unix_dlsym(handle, symbol.data);
}
dlclose :: proc(handle: rawptr) -> bool #inline {
	assert(handle != nil);
	return unix_dlclose(handle) == 0;
}
dlerror :: proc() -> string {
	// TODO(zangent): Should this be split out into a from_c_string()?
	c_str := unix_dlerror();
	len := 0;
	for s := c_str; s^ != 0; s += 1 {
		len += 1;
	}
	return cast(string)slice_ptr(c_str, len);
}
