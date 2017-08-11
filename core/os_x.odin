foreign_system_library (
	dl   "dl";
	libc "c";
)

import "strings.odin";

Handle      :: i32;
File_Time    :: u64;
Errno       :: int;


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
RTLD_LAZY     :: 0x1;
RTLD_NOW      :: 0x2;
RTLD_LOCAL    :: 0x4;
RTLD_GLOBAL   :: 0x8;
RTLD_NODELETE :: 0x80;
RTLD_NOLOAD   :: 0x10;
RTLD_FIRST    :: 0x100;


args: [dynamic]string;

_File_Time :: struct #ordered {
	seconds: i64;
	nanoseconds: i64;
}

Stat :: struct #ordered {
	device_id:     i32; // ID of device containing file
	mode:          u16; // Mode of the file
	nlink:         u16; // Number of hard links
	serial:        u64; // File serial number
	uid:           u32; // User ID of the file's owner
	gid:           u32; // Group ID of the file's group
	rdev:          i32; // Device ID, if device

	last_access:   File_Time; // Time of last access
	modified:      File_Time; // Time of last modification
	status_change: File_Time; // Time of last status change
	created:       File_Time; // Time of creation

	size:          i64;  // Size of the file, in bytes
	blocks:        i64;  // Number of blocks allocated for the file
	block_size:    i32;  // Optimal blocksize for I/O
	flags:         u32;  // User-defined flags for the file
	gen_num:       u32;  // File generation number ...?
	_spare:        i32;  // RESERVED
	_reserve1,
	_reserve2:     i64;  // RESERVED
};

// File type
S_IFMT   :: 0170000; // Type of file mask
S_IFIFO  :: 0010000; // Named pipe (fifo)
S_IFCHR  :: 0020000; // Character special
S_IFDIR  :: 0040000; // Directory
S_IFBLK  :: 0060000; // Block special
S_IFREG  :: 0100000; // Regular
S_IFLNK  :: 0120000; // Symbolic link
S_IFSOCK :: 0140000; // Socket

// File mode
// Read, write, execute/search by owner
S_IRWXU :: 0000700; // RWX mask for owner
S_IRUSR :: 0000400; // R for owner
S_IWUSR :: 0000200; // W for owner
S_IXUSR :: 0000100; // X for owner

// Read, write, execute/search by group
S_IRWXG :: 0000070; // RWX mask for group
S_IRGRP :: 0000040; // R for group
S_IWGRP :: 0000020; // W for group
S_IXGRP :: 0000010; // X for group

// Read, write, execute/search by others
S_IRWXO :: 0000007; // RWX mask for other
S_IROTH :: 0000004; // R for other
S_IWOTH :: 0000002; // W for other
S_IXOTH :: 0000001; // X for other

S_ISUID :: 0004000; // Set user id on execution
S_ISGID :: 0002000; // Set group id on execution
S_ISVTX :: 0001000; // Directory restrcted delete

S_ISLNK  :: proc(m: u32) -> bool #inline do return (m & S_IFMT) == S_IFLNK;
S_ISREG  :: proc(m: u32) -> bool #inline do return (m & S_IFMT) == S_IFREG;
S_ISDIR  :: proc(m: u32) -> bool #inline do return (m & S_IFMT) == S_IFDIR;
S_ISCHR  :: proc(m: u32) -> bool #inline do return (m & S_IFMT) == S_IFCHR;
S_ISBLK  :: proc(m: u32) -> bool #inline do return (m & S_IFMT) == S_IFBLK;
S_ISFIFO :: proc(m: u32) -> bool #inline do return (m & S_IFMT) == S_IFIFO;
S_ISSOCK :: proc(m: u32) -> bool #inline do return (m & S_IFMT) == S_IFSOCK;

R_OK :: 4; // Test for read permission
W_OK :: 2; // Test for write permission
X_OK :: 1; // Test for execute permission
F_OK :: 0; // Test for file existance

foreign libc {
	unix_open    :: proc(path: ^u8, mode: int) -> Handle                    #link_name "open"    ---;
	unix_close   :: proc(handle: Handle)                                    #link_name "close"   ---;
	unix_read    :: proc(handle: Handle, buffer: rawptr, count: int) -> int #link_name "read"    ---;
	unix_write   :: proc(handle: Handle, buffer: rawptr, count: int) -> int #link_name "write"   ---;
	unix_lseek   :: proc(fs: Handle, offset: int, whence: int) -> int       #link_name "lseek"   ---;
	unix_gettid  :: proc() -> u64                                           #link_name "gettid"  ---;
	unix_stat    :: proc(path: ^u8, stat: ^Stat) -> int                     #link_name "stat"    ---;
	unix_access  :: proc(path: ^u8, mask: int) -> int                       #link_name "access"  ---;

	unix_malloc  :: proc(size: int) -> rawptr                               #link_name "malloc"  ---;
	unix_free    :: proc(ptr: rawptr)                                       #link_name "free"    ---;
	unix_realloc :: proc(ptr: rawptr, size: int) -> rawptr                  #link_name "realloc" ---;
	unix_getenv  :: proc(^u8) -> ^u8                                        #link_name "getenv"  ---;

	unix_exit    :: proc(status: int)                                       #link_name "exit"    ---;
}

foreign dl {
	unix_dlopen  :: proc(filename: ^u8, flags: int) -> rawptr               #link_name "dlopen"  ---;
	unix_dlsym   :: proc(handle: rawptr, symbol: ^u8) ->  (proc() #cc_c)    #link_name "dlsym"   ---;
	unix_dlclose :: proc(handle: rawptr) -> int                             #link_name "dlclose" ---;
	unix_dlerror :: proc() -> ^u8                                           #link_name "dlerror" ---;
}

// TODO(zangent): Change this to just `open` when Bill fixes overloading.
open_simple :: proc(path: string, mode: int) -> (Handle, Errno) {

	cstr := strings.new_c_string(path);
	handle := unix_open(cstr, mode);
	free(cstr);
	if(handle == -1) {
		return 0, 1;
	}
	return handle, 0;
}

// NOTE(zangent): This is here for compatability reasons. Should this be here?
open :: proc(path: string, mode: int = O_RDONLY, perm: u32 = 0) -> (Handle, Errno) {
	return open_simple(path, mode);
}

close :: proc(fd: Handle) {
	unix_close(fd);
}

write :: proc(fd: Handle, data: []u8) -> (int, Errno) {
	assert(fd != -1);

	bytes_written := unix_write(fd, &data[0], len(data));
	if(bytes_written == -1) {
		return 0, 1;
	}
	return bytes_written, 0;
}

read :: proc(fd: Handle, data: []u8) -> (int, Errno) {
	assert(fd != -1);

	bytes_read := unix_read(fd, &data[0], len(data));
	if(bytes_read == -1) {
		return 0, 1;
	}
	return bytes_read, 0;
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	assert(fd != -1);

	final_offset := i64(unix_lseek(fd, int(offset), whence));
	if(final_offset == -1) {
		return 0, 1;
	}
	return final_offset, 0;
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	prev, _   := seek(fd, 0, SEEK_CUR);
	size, err := seek(fd, 0, SEEK_END);
	seek(fd, prev, SEEK_SET);
	return i64(size), err;
}



// NOTE(bill): Uses startup to initialize it
stdin:  Handle = 0; // get_std_handle(win32.STD_INPUT_HANDLE);
stdout: Handle = 1; // get_std_handle(win32.STD_OUTPUT_HANDLE);
stderr: Handle = 2; // get_std_handle(win32.STD_ERROR_HANDLE);

/* TODO(zangent): Implement these!
last_write_time :: proc(fd: Handle) -> File_Time {}
last_write_time_by_name :: proc(name: string) -> File_Time {}
*/

stat :: proc(path: string) -> (Stat, bool) #inline {
	s: Stat;
	cstr := strings.new_c_string(path);
	defer free(cstr);
	ret_int := unix_stat(cstr, &s);
	return s, ret_int==0;
}

access :: proc(path: string, mask: int) -> bool #inline {
	cstr := strings.new_c_string(path);
	defer free(cstr);
	return unix_access(cstr, mask) == 0;
}

heap_alloc :: proc(size: int) -> rawptr #inline {
	assert(size > 0);
	return unix_malloc(size);
}
heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr #inline {
	return unix_realloc(ptr, new_size);
}
heap_free :: proc(ptr: rawptr) #inline {
	unix_free(ptr);
}

getenv :: proc(name: string) -> (string, bool) {
	path_str := strings.new_c_string(name);
	cstr: ^u8 = unix_getenv(path_str);
	free(path_str);
	if(cstr == nil) {
		return "", false;
	}
	return strings.to_odin_string(cstr), true;
}

exit :: proc(code: int) #inline {
	unix_exit(code);
}


current_thread_id :: proc() -> int {
	// return cast(int) unix_gettid();
	return 0;
}

dlopen :: proc(filename: string, flags: int) -> rawptr #inline {
	cstr := strings.new_c_string(filename);
	handle := unix_dlopen(cstr, flags);
	free(cstr);
	return handle;
}
dlsym :: proc(handle: rawptr, symbol: string) -> (proc() #cc_c) #inline {
	assert(handle != nil);
	cstr := strings.new_c_string(symbol);
	proc_handle := unix_dlsym(handle, cstr);
	free(cstr);
	return proc_handle;
}
dlclose :: proc(handle: rawptr) -> bool #inline {
	assert(handle != nil);
	return unix_dlclose(handle) == 0;
}
dlerror :: proc() -> string {
	return strings.to_odin_string(unix_dlerror());
}
