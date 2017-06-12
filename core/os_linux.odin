// #import "fmt.odin";
#import "strings.odin";

type Handle   i32;
type FileTime u64;
type Errno    i32;

// INVALID_HANDLE: Handle : -1;

const O_RDONLY   = 0x00000;
const O_WRONLY   = 0x00001;
const O_RDWR     = 0x00002;
const O_CREAT    = 0x00040;
const O_EXCL     = 0x00080;
const O_NOCTTY   = 0x00100;
const O_TRUNC    = 0x00200;
const O_NONBLOCK = 0x00800;
const O_APPEND   = 0x00400;
const O_SYNC     = 0x01000;
const O_ASYNC    = 0x02000;
const O_CLOEXEC  = 0x80000;
const SEEK_SET   = 0;
const SEEK_CUR   = 1;
const SEEK_END   = 2;
const SEEK_DATA  = 3;
const SEEK_HOLE  = 4;
const SEEK_MAX   = SEEK_HOLE;

// NOTE(zangent): These are OS specific!
// Do not mix these up!
const RTLD_LAZY         = 0x001;
const RTLD_NOW          = 0x002;
const RTLD_BINDING_MASK = 0x3;
const RTLD_GLOBAL       = 0x100;

// "Argv" arguments converted to Odin strings
let args = _alloc_command_line_arguments();

type _FileTime struct #ordered {
	seconds:     i64,
	nanoseconds: i32,
	reserved:    i32,
}

// Translated from
//  https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.7-4.6/+/jb-dev/sysroot/usr/include/bits/stat.h
// Validity is not guaranteed.

type Stat struct #ordered {
	device_id:     u64, // ID of device containing file
	serial:        u64, // File serial number
	nlink:         u32, // Number of hard links
	mode:          u32, // Mode of the file
	uid:           u32, // User ID of the file's owner
	gid:           u32, // Group ID of the file's group
	_padding:      i32, // 32 bits of padding
	rdev:          u64, // Device ID, if device
	size:          i64, // Size of the file, in bytes
	block_size:    i64, // Optimal bllocksize for I/O
	blocks:        i64, // Number of 512-byte blocks allocated

	last_access:   _FileTime, // Time of last access
	modified:      _FileTime, // Time of last modification
	status_change: _FileTime, // Time of last status change

	_reserve1,
	_reserve2,
	_reserve3:     i64,
	serial_numbe:  u64, // File serial number...? Maybe.
	_reserve4:     i64,
};

// File type

const S_IFMT   = 0170000; // Type of file mask
const S_IFIFO  = 0010000; // Named pipe (fifo)
const S_IFCHR  = 0020000; // Character special
const S_IFDIR  = 0040000; // Directory
const S_IFBLK  = 0060000; // Block special
const S_IFREG  = 0100000; // Regular
const S_IFLNK  = 0120000; // Symbolic link
const S_IFSOCK = 0140000; // Socket

// File mode
// Read, write, execute/search by owner

const S_IRWXU = 0000700; // RWX mask for owner
const S_IRUSR = 0000400; // R for owner
const S_IWUSR = 0000200; // W for owner
const S_IXUSR = 0000100; // X for owner

// Read, write, execute/search by group

const S_IRWXG = 0000070; // RWX mask for group
const S_IRGRP = 0000040; // R for group
const S_IWGRP = 0000020; // W for group
const S_IXGRP = 0000010; // X for group

// Read, write, execute/search by others

const S_IRWXO = 0000007; // RWX mask for other
const S_IROTH = 0000004; // R for other
const S_IWOTH = 0000002; // W for other
const S_IXOTH = 0000001; // X for other

const S_ISUID = 0004000; // Set user id on execution
const S_ISGID = 0002000; // Set group id on execution
const S_ISVTX = 0001000; // Directory restrcted delete

proc S_ISLNK (m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFLNK; }
proc S_ISREG (m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFREG; }
proc S_ISDIR (m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFDIR; }
proc S_ISCHR (m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFCHR; }
proc S_ISBLK (m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFBLK; }
proc S_ISFIFO(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFIFO; }
proc S_ISSOCK(m: u32) -> bool #inline  {return (m & S_IFMT) == S_IFSOCK;}

const R_OK = 4; // Test for read permission
const W_OK = 2; // Test for write permission
const X_OK = 1; // Test for execute permission
const F_OK = 0; // Test for file existance

#foreign_system_library dl   "dl";
#foreign_system_library libc "c";

proc _unix_open  (path: ^u8, mode: int) -> Handle                               #foreign libc "open";
proc _unix_close (fd: Handle) -> i32                                            #foreign libc "close";
proc _unix_read  (fd: Handle, buf: rawptr, size: int) -> int                    #foreign libc "read";
proc _unix_write (fd: Handle, buf: rawptr, size: int) -> int                    #foreign libc "write";
proc _unix_seek  (fd: Handle, offset: i64, whence: i32) -> i64                  #foreign libc "lseek64";
proc _unix_gettid() -> u64                                                      #foreign libc "gettid";
proc _unix_stat  (path: ^u8, stat: ^Stat) -> i32                                #foreign libc "stat";
proc _unix_access(path: ^u8, mask: int) -> i32                                  #foreign libc "access";

proc _unix_malloc (size: int) -> rawptr                                         #foreign libc "malloc";
proc _unix_free   (ptr: rawptr)                                                 #foreign libc "free";
proc _unix_realloc(ptr: rawptr, size: int) -> rawptr                            #foreign libc "realloc";
proc _unix_getenv (^u8) -> ^u8                                                  #foreign libc "getenv";

proc _unix_exit(status: int)                                                    #foreign libc "exit";

proc _unix_dlopen (filename: ^u8, flags: int) -> rawptr                         #foreign dl   "dlopen";
proc _unix_dlsym  (handle: rawptr, symbol: ^u8) ->  (proc() #cc_c)              #foreign dl   "dlsym";
proc _unix_dlclose(handle: rawptr) -> int                                       #foreign dl   "dlclose";
proc _unix_dlerror() -> ^u8                                                     #foreign dl   "dlerror";

// TODO(zangent): Change this to just `open` when Bill fixes overloading.
proc open_simple(path: string, mode: int) -> (Handle, Errno) {

	var cstr = strings.new_c_string(path);
	var handle = _unix_open(cstr, mode);
	free(cstr);
	if(handle == -1) {
		return 0, 1;
	}
	return handle, 0;
}
// NOTE(zangent): This is here for compatability reasons. Should this be here?
proc open(path: string, mode: int, perm: u32) -> (Handle, Errno) {
	return open_simple(path, mode);
}

proc close(fd: Handle) {
	_unix_close(fd);
}

proc read(fd: Handle, data: []u8) -> (int, Errno) {
	var sz = _unix_read(fd, &data[0], len(data));
	return sz, 0;
}

proc write(fd: Handle, data: []u8) -> (int, Errno) {
	var sz = _unix_write(fd, &data[0], len(data));
	return sz, 0;
}

proc seek(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	var res = _unix_seek(fd, offset, i32(whence));
	return res, 0;
}

proc file_size(fd: Handle) -> (i64, Errno) {
	var prev, _ = seek(fd, 0, SEEK_CUR);
	var size, err = seek(fd, 0, SEEK_END);
	seek(fd, prev, SEEK_SET);
	return size, err;
}


// NOTE(bill): Uses startup to initialize it
var stdin:  Handle = 0;
var stdout: Handle = 1;
var stderr: Handle = 2;

/* TODO(zangent): Implement these!
proc last_write_time(fd: Handle) -> FileTime {}
proc last_write_time_by_name(name: string) -> FileTime {}
*/

proc stat(path: string) -> (Stat, int) #inline {
	var s: Stat;
	var cstr = strings.new_c_string(path);
	defer free(cstr);
	var ret_int = _unix_stat(cstr, &s);
	return s, int(ret_int);
}

proc access(path: string, mask: int) -> bool #inline {
	var cstr = strings.new_c_string(path);
	defer free(cstr);
	return _unix_access(cstr, mask) == 0;
}

proc heap_alloc(size: int) -> rawptr {
	assert(size > 0);
	return _unix_malloc(size);
}

proc heap_resize(ptr: rawptr, new_size: int) -> rawptr {
	return _unix_realloc(ptr, new_size);
}

proc heap_free(ptr: rawptr) {
	_unix_free(ptr);
}

proc getenv(name: string) -> (string, bool) {
	var path_str = strings.new_c_string(name);
	var cstr: ^u8 = _unix_getenv(path_str);
	free(path_str);
	if(cstr == nil) {
		return "", false;
	}
	return strings.to_odin_string(cstr), true;
}

proc exit(code: int) {
	_unix_exit(code);
}

proc current_thread_id() -> int {
	// return int(_unix_gettid());
	return 0;
}

proc dlopen(filename: string, flags: int) -> rawptr #inline {
	var cstr = strings.new_c_string(filename);
	var handle = _unix_dlopen(cstr, flags);
	free(cstr);
	return handle;
}
proc dlsym(handle: rawptr, symbol: string) -> (proc() #cc_c) #inline {
	assert(handle != nil);
	var cstr = strings.new_c_string(symbol);
	var proc_handle = _unix_dlsym(handle, cstr);
	free(cstr);
	return proc_handle;
}
proc dlclose(handle: rawptr) -> bool #inline {
	assert(handle != nil);
	return _unix_dlclose(handle) == 0;
}
proc dlerror() -> string {
	return strings.to_odin_string(_unix_dlerror());
}


proc _alloc_command_line_arguments() -> []string {
	// TODO(bill):
	return nil;
}
