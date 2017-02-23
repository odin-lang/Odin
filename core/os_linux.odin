#import "fmt.odin";

Handle    :: i32;
File_Time :: u64;
Errno     :: int;

// TODO(zangent): Find out how to make this work on x64 and x32.
AddressSize :: i64;

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
SEEK_SET   :: 0;
SEEK_CUR   :: 1;
SEEK_END   :: 2;
SEEK_DATA  :: 3;
SEEK_HOLE  :: 4;
SEEK_MAX   :: SEEK_HOLE;

// NOTE(zangent): These are OS specific!
// Do not mix these up!
RTLD_LAZY         :: 0x001;
RTLD_NOW          :: 0x002;
RTLD_BINDING_MASK :: 0x3;
RTLD_GLOBAL       :: 0x100;

#foreign_system_library dl   "dl";
#foreign_system_library libc "c";

unix_open   :: proc(path: ^u8, mode: int) -> Handle                               #foreign libc "open";
unix_close  :: proc(handle: Handle)                                               #foreign libc "close";
unix_read   :: proc(handle: Handle, buffer: rawptr, count: int) -> AddressSize    #foreign libc "read";
unix_write  :: proc(handle: Handle, buffer: rawptr, count: int) -> AddressSize    #foreign libc "write";
unix_lseek  :: proc(fs: Handle, offset: AddressSize, whence: int) -> AddressSize  #foreign libc "lseek";
unix_gettid :: proc() -> u64                                                      #foreign libc "gettid";

unix_malloc  :: proc(size: int) -> rawptr                                         #foreign libc "malloc";
unix_free    :: proc(ptr: rawptr)                                                 #foreign libc "free";
unix_realloc :: proc(ptr: rawptr, size: int) -> rawptr                            #foreign libc "realloc";
unix_getenv  :: proc(^u8) -> ^u8                                                  #foreign libc "getenv";

unix_exit :: proc(status: int)                                                    #foreign libc "exit";

unix_dlopen  :: proc(filename: ^u8, flags: int) -> rawptr                         #foreign dl   "dlopen";
unix_dlsym   :: proc(handle: rawptr, symbol: ^u8) ->  (proc() #cc_c)              #foreign dl   "dlsym";
unix_dlclose :: proc(handle: rawptr) -> int                                       #foreign dl   "dlclose";
unix_dlerror :: proc() -> ^u8                                                     #foreign dl   "dlerror";

to_c_str :: proc(str: string) -> ^u8 {
	cstr := new_slice(byte, str.count+1);
	copy(cstr, cast([]byte)str);
	cstr[str.count] = 0;
	return cstr.data;
}

from_c_str :: proc(c_str: ^u8) -> string {
	len := 0;
	for s := c_str; s^ != 0; s += 1 {
		len += 1;
	}
	return cast(string)slice_ptr(c_str, len);
}
// TODO(zangent): Change this to just `open` when Bill fixes overloading.
open_simple :: proc(path: string, mode: int) -> (Handle, Errno) {
	
	handle := unix_open(to_c_str(path), mode);
	if(handle == -1) {
		return 0, 1;
	}
	return handle, 0;
}
// NOTE(zangent): This is here for compatability reasons. Should this be here?
open :: proc(path: string, mode: int, perm: u32) -> (Handle, Errno) {
	return open_simple(path, mode);
}

close :: proc(fd: Handle) {
	unix_close(fd);
}

write :: proc(fd: Handle, data: []byte) -> (AddressSize, Errno) {
	assert(fd != -1);

	bytes_written := unix_write(fd, data.data, data.count);
	if(bytes_written == -1) {
		return 0, 1;
	}
	return bytes_written, 0;
}

read :: proc(fd: Handle, data: []byte) -> (AddressSize, Errno) {
	assert(fd != -1);

	bytes_read := unix_read(fd, data.data, data.count);
	if(bytes_read == -1) {
		return 0, 1;
	}
	return bytes_read, 0;
}

seek :: proc(fd: Handle, offset: AddressSize, whence: int) -> (AddressSize, Errno) {
	assert(fd != -1);

	final_offset := unix_lseek(fd, offset, whence);
	if(final_offset == -1) {
		return 0, 1;
	}
	return final_offset, 0;
}


// NOTE(bill): Uses startup to initialize it
stdin:  Handle = 0; // get_std_handle(win32.STD_INPUT_HANDLE);
stdout: Handle = 1; // get_std_handle(win32.STD_OUTPUT_HANDLE);
stderr: Handle = 2; // get_std_handle(win32.STD_ERROR_HANDLE);

/* TODO(zangent): Implement these!
last_write_time :: proc(fd: Handle) -> File_Time {}
last_write_time_by_name :: proc(name: string) -> File_Time {}
*/

read_entire_file :: proc(name: string) -> ([]byte, bool) {

	handle, err := open_simple(name, O_RDONLY);
	if(err != 0) {
		fmt.println("Failed to open file.");
		return nil, false;
	}
	defer(close(handle));

	// We have a file!

	size: AddressSize;
	size, err = seek(handle, 0, SEEK_END);
	if(err != 0) {
		fmt.println("Failed to seek to end of file.");
		return nil, false;
	}

	_, err = seek(handle, 0, SEEK_SET);
	if(err != 0) {
		fmt.println("Failed to seek to beginning of file.");
		return nil, false;
	}

	// We have a file size!

	data := new_slice(u8, size);
	if data.data == nil {
		fmt.println("Failed to allocate file buffer.");
		return nil, false;
	}

	read(handle, data);

	return data, true;
}

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

getenv :: proc(name: string) -> (string, bool) {
	cstr: ^u8 = unix_getenv(to_c_str(name));
	if(cstr == nil) {
		return "", false;
	}
	return from_c_str(cstr), true;
}

exit :: proc(code: int) {
	unix_exit(code);
}

current_thread_id :: proc() -> int {
	// return cast(int) unix_gettid();
	return 0;
}

dlopen :: proc(filename: string, flags: int) -> rawptr #inline {
	return unix_dlopen(to_c_str(filename), flags);
}
dlsym :: proc(handle: rawptr, symbol: string) -> (proc() #cc_c) #inline {
	assert(handle != nil);
	return unix_dlsym(handle, to_c_str(symbol));
}
dlclose :: proc(handle: rawptr) -> bool #inline {
	assert(handle != nil);
	return unix_dlclose(handle) == 0;
}
dlerror :: proc() -> string {
	return from_c_str(unix_dlerror());
}
