foreign_system_library (
	dl   "dl";
	libc "c";
)
import "strings.odin";

Handle   :: i32;
File_Time :: u64;
Errno    :: i32;


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

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments();

_File_Time :: struct #ordered {
	seconds:     i64;
	nanoseconds: i32;
	reserved:    i32;
}

// Translated from
//  https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.7-4.6/+/jb-dev/sysroot/usr/include/bits/stat.h
// Validity is not guaranteed.

Stat :: struct #ordered {
	device_id:     u64; // ID of device containing file
	serial:        u64; // File serial number
	nlink:         u32; // Number of hard links
	mode:          u32; // Mode of the file
	uid:           u32; // User ID of the file's owner
	gid:           u32; // Group ID of the file's group
	_padding:      i32; // 32 bits of padding
	rdev:          u64; // Device ID, if device
	size:          i64; // Size of the file, in bytes
	block_size:    i64; // Optimal bllocksize for I/O
	blocks:        i64; // Number of 512-byte blocks allocated

	last_access:   _File_Time; // Time of last access
	modified:      _File_Time; // Time of last modification
	status_change: _File_Time; // Time of last status change

	_reserve1,
	_reserve2,
	_reserve3:     i64;
	serial_numbe:  u64; // File serial number...? Maybe.
	_reserve4:     i64;
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


S_ISLNK  :: proc(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFLNK; }
S_ISREG  :: proc(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFREG; }
S_ISDIR  :: proc(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFDIR; }
S_ISCHR  :: proc(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFCHR; }
S_ISBLK  :: proc(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFBLK; }
S_ISFIFO :: proc(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFIFO; }
S_ISSOCK :: proc(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFSOCK;}

F_OK :: 0; // Test for file existance
X_OK :: 1; // Test for execute permission
W_OK :: 2; // Test for write permission
R_OK :: 4; // Test for read permission

foreign libc {
	_unix_open    :: proc(path: ^u8, mode: int) -> Handle              #link_name "open"    ---;
	_unix_close   :: proc(fd: Handle) -> i32                           #link_name "close"   ---;
	_unix_read    :: proc(fd: Handle, buf: rawptr, size: int) -> int   #link_name "read"    ---;
	_unix_write   :: proc(fd: Handle, buf: rawptr, size: int) -> int   #link_name "write"   ---;
	_unix_seek    :: proc(fd: Handle, offset: i64, whence: i32) -> i64 #link_name "lseek64" ---;
	_unix_gettid  :: proc() -> u64                                     #link_name "gettid"  ---;
	_unix_stat    :: proc(path: ^u8, stat: ^Stat) -> i32               #link_name "stat"    ---;
	_unix_access  :: proc(path: ^u8, mask: int) -> i32                 #link_name "access"  ---;

	_unix_malloc  :: proc(size: int) -> rawptr                         #link_name "malloc"  ---;
	_unix_free    :: proc(ptr: rawptr)                                 #link_name "free"    ---;
	_unix_realloc :: proc(ptr: rawptr, size: int) -> rawptr            #link_name "realloc" ---;
	_unix_getenv  :: proc(^u8) -> ^u8                                  #link_name "getenv"  ---;

	_unix_exit    :: proc(status: int)                                 #link_name "exit"    ---;
}
foreign dl {
	_unix_dlopen  :: proc(filename: ^u8, flags: int) -> rawptr            #link_name "dlopen"  ---;
	_unix_dlsym   :: proc(handle: rawptr, symbol: ^u8) ->  (proc() #cc_c) #link_name "dlsym"   ---;
	_unix_dlclose :: proc(handle: rawptr) -> int                          #link_name "dlclose" ---;
	_unix_dlerror :: proc() -> ^u8                                        #link_name "dlerror" ---;
}

// TODO(zangent): Change this to just `open` when Bill fixes overloading.
open_simple :: proc(path: string, mode: int) -> (Handle, Errno) {

	cstr := strings.new_c_string(path);
	handle := _unix_open(cstr, mode);
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
	_unix_close(fd);
}

read :: proc(fd: Handle, data: []u8) -> (int, Errno) {
	sz := _unix_read(fd, &data[0], len(data));
	return sz, 0;
}

write :: proc(fd: Handle, data: []u8) -> (int, Errno) {
	sz := _unix_write(fd, &data[0], len(data));
	return sz, 0;
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	res := _unix_seek(fd, offset, i32(whence));
	return res, 0;
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	prev, _   := seek(fd, 0, SEEK_CUR);
	size, err := seek(fd, 0, SEEK_END);
	seek(fd, prev, SEEK_SET);
	return size, err;
}


// NOTE(bill): Uses startup to initialize it

stdin:  Handle = 0;
stdout: Handle = 1;
stderr: Handle = 2;

/* TODO(zangent): Implement these!
last_write_time :: proc(fd: Handle) -> File_Time {}
last_write_time_by_name :: proc(name: string) -> File_Time {}
*/

stat :: proc(path: string) -> (Stat, int) #inline {
	s: Stat;
	cstr := strings.new_c_string(path);
	defer free(cstr);
	ret_int := _unix_stat(cstr, &s);
	return s, int(ret_int);
}

access :: proc(path: string, mask: int) -> bool #inline {
	cstr := strings.new_c_string(path);
	defer free(cstr);
	return _unix_access(cstr, mask) == 0;
}

heap_alloc :: proc(size: int) -> rawptr {
	assert(size > 0);
	return _unix_malloc(size);
}

heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	return _unix_realloc(ptr, new_size);
}

heap_free :: proc(ptr: rawptr) {
	_unix_free(ptr);
}

getenv :: proc(name: string) -> (string, bool) {
	path_str := strings.new_c_string(name);
	cstr: ^u8 = _unix_getenv(path_str);
	free(path_str);
	if(cstr == nil) {
		return "", false;
	}
	return strings.to_odin_string(cstr), true;
}

exit :: proc(code: int) {
	_unix_exit(code);
}

current_thread_id :: proc() -> int {
	// return int(_unix_gettid());
	return 0;
}

dlopen :: proc(filename: string, flags: int) -> rawptr #inline {
	cstr := strings.new_c_string(filename);
	handle := _unix_dlopen(cstr, flags);
	free(cstr);
	return handle;
}
dlsym :: proc(handle: rawptr, symbol: string) -> (proc() #cc_c) #inline {
	assert(handle != nil);
	cstr := strings.new_c_string(symbol);
	proc_handle := _unix_dlsym(handle, cstr);
	free(cstr);
	return proc_handle;
}
dlclose :: proc(handle: rawptr) -> bool #inline {
	assert(handle != nil);
	return _unix_dlclose(handle) == 0;
}
dlerror :: proc() -> string {
	return strings.to_odin_string(_unix_dlerror());
}


_alloc_command_line_arguments :: proc() -> []string {
	// TODO(bill):
	return nil;
}
