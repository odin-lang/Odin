// #import "fmt.odin";
#import "strings.odin";

const Handle    = i32;
const FileTime  = u64;
const Errno     = i32;

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
immutable var args = _alloc_command_line_arguments();

const _FileTime = struct #ordered {
	seconds:     i64,
	nanoseconds: i32,
	reserved:    i32,
}

// Translated from
//  https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.7-4.6/+/jb-dev/sysroot/usr/include/bits/stat.h
// Validity is not guaranteed.

const Stat = struct #ordered {
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

const S_ISLNK  = proc(m: u32) -> bool #inline  {return ((m) & S_IFMT) == S_IFLNK; }
const S_ISREG  = proc(m: u32) -> bool #inline  {return ((m) & S_IFMT) == S_IFREG; }
const S_ISDIR  = proc(m: u32) -> bool #inline  {return ((m) & S_IFMT) == S_IFDIR; }
const S_ISCHR  = proc(m: u32) -> bool #inline  {return ((m) & S_IFMT) == S_IFCHR; }
const S_ISBLK  = proc(m: u32) -> bool #inline  {return ((m) & S_IFMT) == S_IFBLK; }
const S_ISFIFO = proc(m: u32) -> bool #inline  {return ((m) & S_IFMT) == S_IFIFO; }
const S_ISSOCK = proc(m: u32) -> bool #inline  {return ((m) & S_IFMT) == S_IFSOCK;}

const R_OK = 4; // Test for read permission
const W_OK = 2; // Test for write permission
const X_OK = 1; // Test for execute permission
const F_OK = 0; // Test for file existance

#foreign_system_library dl   "dl";
#foreign_system_library libc "c";

const _unix_open   = proc(path: ^u8, mode: int) -> Handle                               #foreign libc "open";
const _unix_close  = proc(fd: Handle) -> i32                                            #foreign libc "close";
const _unix_read   = proc(fd: Handle, buf: rawptr, size: int) -> int                    #foreign libc "read";
const _unix_write  = proc(fd: Handle, buf: rawptr, size: int) -> int                    #foreign libc "write";
const _unix_seek   = proc(fd: Handle, offset: i64, whence: i32) -> i64                  #foreign libc "lseek64";
const _unix_gettid = proc() -> u64                                                      #foreign libc "gettid";
const _unix_stat   = proc(path: ^u8, stat: ^Stat) -> i32                                #foreign libc "stat";
const _unix_access = proc(path: ^u8, mask: int) -> i32                                  #foreign libc "access";

const _unix_malloc  = proc(size: int) -> rawptr                                         #foreign libc "malloc";
const _unix_free    = proc(ptr: rawptr)                                                 #foreign libc "free";
const _unix_realloc = proc(ptr: rawptr, size: int) -> rawptr                            #foreign libc "realloc";
const _unix_getenv  = proc(^u8) -> ^u8                                                  #foreign libc "getenv";

const _unix_exit = proc(status: int)                                                    #foreign libc "exit";

const _unix_dlopen  = proc(filename: ^u8, flags: int) -> rawptr                         #foreign dl   "dlopen";
const _unix_dlsym   = proc(handle: rawptr, symbol: ^u8) ->  (proc() #cc_c)              #foreign dl   "dlsym";
const _unix_dlclose = proc(handle: rawptr) -> int                                       #foreign dl   "dlclose";
const _unix_dlerror = proc() -> ^u8                                                     #foreign dl   "dlerror";

// TODO(zangent): Change this to just `open` when Bill fixes overloading.
const open_simple = proc(path: string, mode: int) -> (Handle, Errno) {

	var cstr = strings.new_c_string(path);
	var handle = _unix_open(cstr, mode);
	free(cstr);
	if(handle == -1) {
		return 0, 1;
	}
	return handle, 0;
}
// NOTE(zangent): This is here for compatability reasons. Should this be here?
const open = proc(path: string, mode: int, perm: u32) -> (Handle, Errno) {
	return open_simple(path, mode);
}

const close = proc(fd: Handle) {
	_unix_close(fd);
}

const read = proc(fd: Handle, data: []u8) -> (int, Errno) {
	var sz = _unix_read(fd, &data[0], len(data));
	return sz, 0;
}

const write = proc(fd: Handle, data: []u8) -> (int, Errno) {
	var sz = _unix_write(fd, &data[0], len(data));
	return sz, 0;
}

const seek = proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	var res = _unix_seek(fd, offset, i32(whence));
	return res, 0;
}

const file_size = proc(fd: Handle) -> (i64, Errno) {
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
const last_write_time = proc(fd: Handle) -> FileTime {}
const last_write_time_by_name = proc(name: string) -> FileTime {}
*/

const stat = proc(path: string) -> (Stat, int) #inline {
	var s: Stat;
	var cstr = strings.new_c_string(path);
	defer free(cstr);
	var ret_int = _unix_stat(cstr, &s);
	return s, int(ret_int);
}

const access = proc(path: string, mask: int) -> bool #inline {
	var cstr = strings.new_c_string(path);
	defer free(cstr);
	return _unix_access(cstr, mask) == 0;
}

const heap_alloc = proc(size: int) -> rawptr {
	assert(size > 0);
	return _unix_malloc(size);
}

const heap_resize = proc(ptr: rawptr, new_size: int) -> rawptr {
	return _unix_realloc(ptr, new_size);
}

const heap_free = proc(ptr: rawptr) {
	_unix_free(ptr);
}

const getenv = proc(name: string) -> (string, bool) {
	var path_str = strings.new_c_string(name);
	var cstr: ^u8 = _unix_getenv(path_str);
	free(path_str);
	if(cstr == nil) {
		return "", false;
	}
	return strings.to_odin_string(cstr), true;
}

const exit = proc(code: int) {
	_unix_exit(code);
}

const current_thread_id = proc() -> int {
	// return int(_unix_gettid());
	return 0;
}

const dlopen = proc(filename: string, flags: int) -> rawptr #inline {
	var cstr = strings.new_c_string(filename);
	var handle = _unix_dlopen(cstr, flags);
	free(cstr);
	return handle;
}
const dlsym = proc(handle: rawptr, symbol: string) -> (proc() #cc_c) #inline {
	assert(handle != nil);
	var cstr = strings.new_c_string(symbol);
	var proc_handle = _unix_dlsym(handle, cstr);
	free(cstr);
	return proc_handle;
}
const dlclose = proc(handle: rawptr) -> bool #inline {
	assert(handle != nil);
	return _unix_dlclose(handle) == 0;
}
const dlerror = proc() -> string {
	return strings.to_odin_string(_unix_dlerror());
}


const _alloc_command_line_arguments = proc() -> []string {
	// TODO(bill):
	return nil;
}
