package darwin

import "core:c"
import "base:runtime"

// IMPORTANT NOTE: direct syscall usage is not allowed by Apple's review process of apps and should
// be entirely avoided in the builtin Odin collections, these are here for users if they don't
// care about the Apple review process.

// this package uses the sys prefix for the proc names to indicate that these aren't native syscalls but directly call such
sys_write_string ::  proc (fd: c.int, message: string) -> bool {
	return syscall_write(fd, raw_data(message), cast(u64)len(message))
}

Offset_From :: enum c.int {
	SEEK_SET  = 0,  // the offset is set to offset bytes.
	SEEK_CUR  = 1,  // the offset is set to its current location plus offset bytes.
   	SEEK_END  = 2,  // the offset is set to the size of the file plus offset bytes.
   	SEEK_HOLE = 3,  //  the offset is set to the start of the next hole greater than or equal to the supplied offset.
 	SEEK_DATA = 4,  //  the offset is set to the start of the next non-hole file region greater than or equal to the supplied offset.
}

Open_Flags_Enum :: enum u8 {
	RDONLY, /* open for reading only */
	WRONLY, /* open for writing only */
	RDWR, /* open for reading and writing */

	NONBLOCK, /* no delay */
	APPEND, /* set append mode */
	CREAT, /* create if nonexistant */
	TRUNC, /* truncate to zero length */
	EXCL, /* error if already exists */
	SHLOCK, /* open with shared file lock */
	EXLOCK, /* open with exclusive file lock */
	DIRECTORY, /* restrict open to only directories */
	NOFOLLOW, /* don't follow symlinks */
	SYMLINK, /* allow open of a symlink */
	EVTONLY, /* descriptor requested for event notifications only */
	CLOEXEC, /* causes the descriptor to be closed if you use any of the exec like functions */
	NOFOLLOW_ANY, /* no symlinks allowed in path */
}
Open_Flags :: bit_set[Open_Flags_Enum; u16]

Permission_Enum :: enum u8 {
	/* For owner */
	PERMISSION_OWNER_READ, /* R for owner */
	PERMISSION_OWNER_WRITE, /* W for owner */
	PERMISSION_OWNER_EXECUTE, /* X for owner */
	//IRWXU, /* RWX mask for owner */
	
	/* For group */
	PERMISSION_GROUP_READ, /* R for group */
	PERMISSION_GROUP_WRITE, /* W for group */
	PERMISSION_GROUP_EXECUTE, /* X for group */
	//IRWXG, /* RWX mask for group */
	
	/* For other */
	PERMISSION_OTHER_READ, /* R for other */
	PERMISSION_OTHER_WRITE, /* W for other */
	PERMISSION_OTHER_EXECUTE, /* X for other */
	//IRWXO, /* RWX mask for other */
	
	/* Special */
	PERMISSION_SET_USER_ON_EXECUTION, /* set user id on execution */
	PERMISSION_SET_GROUP_ON_EXECUTION, /* set group id on execution */

	/* ?? */
	PERMISSION_ISVTX, /* save swapped text even after use */
}
Permission :: bit_set[Permission_Enum; u16]

PERMISSION_NONE_NONE :: Permission{}
PERMISSION_OWNER_ALL :: Permission{.PERMISSION_OWNER_READ, .PERMISSION_OWNER_WRITE, .PERMISSION_OWNER_EXECUTE}
PERMISSION_GROUP_ALL :: Permission{.PERMISSION_GROUP_READ, .PERMISSION_GROUP_WRITE, .PERMISSION_GROUP_EXECUTE}
PERMISSION_OTHER_ALL :: Permission{.PERMISSION_OTHER_READ, .PERMISSION_OTHER_WRITE, .PERMISSION_OTHER_EXECUTE}
PERMISSION_ALL_ALL   :: PERMISSION_OWNER_ALL | PERMISSION_GROUP_ALL | PERMISSION_OTHER_ALL

_sys_permission_mode :: #force_inline proc (mode: Permission) -> u32 {
	cflags: u32 = 0

	cflags |= PERMISSION_MASK_IRUSR * u32(Permission.PERMISSION_OWNER_READ in mode)
	cflags |= PERMISSION_MASK_IWUSR * u32(Permission.PERMISSION_OWNER_WRITE in mode)
	cflags |= PERMISSION_MASK_IXUSR * u32(Permission.PERMISSION_OWNER_WRITE in mode)
	cflags |= PERMISSION_MASK_IRGRP * u32(Permission.PERMISSION_GROUP_READ in mode)
	cflags |= PERMISSION_MASK_IWGRP * u32(Permission.PERMISSION_GROUP_WRITE in mode)
	cflags |= PERMISSION_MASK_IXGRP * u32(Permission.PERMISSION_GROUP_WRITE in mode)
	cflags |= PERMISSION_MASK_IROTH * u32(Permission.PERMISSION_OTHER_READ in mode)
	cflags |= PERMISSION_MASK_IWOTH * u32(Permission.PERMISSION_OTHER_WRITE in mode)
	cflags |= PERMISSION_MASK_IXOTH * u32(Permission.PERMISSION_OTHER_WRITE in mode)

	return cflags
}

@(private)
clone_to_cstring :: proc(s: string, allocator: runtime.Allocator, loc := #caller_location) -> cstring {
	c := make([]byte, len(s)+1, allocator, loc)
	copy(c, s)
	c[len(s)] = 0
	return cstring(&c[0])
}


sys_open :: proc(path: string, oflag: Open_Flags, mode: Permission) -> (c.int, bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	
	cmode: u32 = 0
	cflags: u32 = 0
	cpath: cstring = clone_to_cstring(path, context.temp_allocator)

	cflags = _sys_permission_mode(mode)

	cmode |= OPEN_FLAG_RDONLY       * u32(Open_Flags.RDONLY in oflag)
	cmode |= OPEN_FLAG_WRONLY       * u32(Open_Flags.WRONLY in oflag)
	cmode |= OPEN_FLAG_RDWR         * u32(Open_Flags.RDWR in oflag)
	cmode |= OPEN_FLAG_NONBLOCK     * u32(Open_Flags.NONBLOCK in oflag)
	cmode |= OPEN_FLAG_CREAT        * u32(Open_Flags.CREAT in oflag)
	cmode |= OPEN_FLAG_APPEND       * u32(Open_Flags.APPEND in oflag)
	cmode |= OPEN_FLAG_TRUNC        * u32(Open_Flags.TRUNC in oflag)
	cmode |= OPEN_FLAG_EXCL         * u32(Open_Flags.EXCL in oflag)
	cmode |= OPEN_FLAG_SHLOCK       * u32(Open_Flags.SHLOCK in oflag)
	cmode |= OPEN_FLAG_EXLOCK       * u32(Open_Flags.EXLOCK in oflag)
	cmode |= OPEN_FLAG_DIRECTORY    * u32(Open_Flags.DIRECTORY in oflag)
	cmode |= OPEN_FLAG_NOFOLLOW     * u32(Open_Flags.NOFOLLOW in oflag)
	cmode |= OPEN_FLAG_SYMLINK      * u32(Open_Flags.SYMLINK in oflag)
	cmode |= OPEN_FLAG_EVTONLY      * u32(Open_Flags.EVTONLY in oflag)
	cmode |= OPEN_FLAG_CLOEXEC      * u32(Open_Flags.CLOEXEC in oflag)
	cmode |= OPEN_FLAG_NOFOLLOW_ANY * u32(Open_Flags.NOFOLLOW_ANY in oflag)
	
	result := syscall_open(cpath, cmode, cflags)
	state  := result != -1

	if state && cflags != 0 {
		state = (syscall_fchmod(result, cflags) != -1)
	}

	return result * cast(c.int)state, state
}

sys_mkdir :: proc(path: string, mode: Permission) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath: cstring = clone_to_cstring(path, context.temp_allocator)
	cflags := _sys_permission_mode(mode)
	return syscall_mkdir(cpath, cflags) != -1
}

sys_mkdir_at :: proc(fd: c.int, path: string, mode: Permission) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath: cstring = clone_to_cstring(path, context.temp_allocator)
	cflags := _sys_permission_mode(mode)
	return syscall_mkdir_at(fd, cpath, cflags) != -1
}

sys_rmdir :: proc(path: string, mode: Permission) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath: cstring = clone_to_cstring(path, context.temp_allocator)
	cflags := _sys_permission_mode(mode)
	return syscall_rmdir(cpath, cflags) != -1
}

sys_rename :: proc(path: string, new_path: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath: cstring = clone_to_cstring(path, context.temp_allocator)
	cnpath: cstring = clone_to_cstring(new_path, context.temp_allocator)
	return syscall_rename(cpath, cnpath) != -1
}

sys_rename_at :: proc(fd: c.int, path: string, to_fd: c.int, new_path: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath: cstring = clone_to_cstring(path, context.temp_allocator)
	cnpath: cstring = clone_to_cstring(new_path, context.temp_allocator)
	return syscall_rename_at(fd, cpath, to_fd, cnpath) != -1
}

sys_lseek :: proc(fd: c.int, offset: i64, whence: Offset_From) -> i64 {
	return syscall_lseek(fd, offset, cast(c.int)whence)
}

sys_chmod :: proc(path: string, mode: Permission) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath: cstring = clone_to_cstring(path, context.temp_allocator)
	cmode := _sys_permission_mode(mode)
	return syscall_chmod(cpath, cmode) != -1
}

sys_lstat :: proc(path: string, status: ^stat) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath: cstring = clone_to_cstring(path, context.temp_allocator)
	return syscall_lstat(cpath, status) != -1
}
