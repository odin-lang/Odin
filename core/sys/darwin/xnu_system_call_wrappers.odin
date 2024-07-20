package darwin

import "core:c"
import "base:intrinsics"

// IMPORTANT NOTE: direct syscall usage is not allowed by Apple's review process of apps and should
// be entirely avoided in the builtin Odin collections, these are here for users if they don't
// care about the Apple review process.

/* flock */
LOCK_SH :: 1 /* shared lock */
LOCK_EX :: 2 /* exclusive lock */
LOCK_NB :: 4 /* don't block when locking */
LOCK_UN :: 8 /* unlock */

/* sys/unistd.h for access */
F_OK  :: c.int(0)         /* test for existence of file */
X_OK  :: c.int((1 << 0))  /* test for execute or search permission */
W_OK  :: c.int((1 << 1))  /* test for write permission */
R_OK  :: c.int((1 << 2))  /* test for read permission */

/* copyfile flags */
COPYFILE_ACL   :: (1 << 0)
COPYFILE_STAT  :: (1 << 1)
COPYFILE_XATTR :: (1 << 2)
COPYFILE_DATA  :: (1 << 3)

COPYFILE_SECURITY :: (COPYFILE_STAT | COPYFILE_ACL)
COPYFILE_METADATA :: (COPYFILE_SECURITY | COPYFILE_XATTR)
COPYFILE_ALL	  :: (COPYFILE_METADATA | COPYFILE_DATA)

/* syslimits.h */
PATH_MAX	:: 1024	/* max bytes in pathname */

/* param.h */
MAXPATHLEN :: PATH_MAX

/* proc_info.h */
DARWIN_PROC_PIDPATHINFO_SIZE :: MAXPATHLEN
DARWIN_PROC_PIDPATHINFO :: 11

DARWIN_PROC_ALL_PIDS  :: c.int(1)
DARWIN_PROC_PGRP_ONLY :: c.int(2)
DARWIN_PROC_TTY_ONLY  :: c.int(3)
DARWIN_PROC_UID_ONLY  :: c.int(4)
DARWIN_PROC_RUID_ONLY :: c.int(5)
DARWIN_PROC_PPID_ONLY :: c.int(6)
DARWIN_PROC_KDBG_ONLY :: c.int(7)

DARWIN_PROC_INFO_CALL_LISTPIDS          :: c.int(0x1)
DARWIN_PROC_INFO_CALL_PIDINFO           :: c.int(0x2)
DARWIN_PROC_INFO_CALL_PIDFDINFO         :: c.int(0x3)
DARWIN_PROC_INFO_CALL_KERNMSGBUF        :: c.int(0x4)
DARWIN_PROC_INFO_CALL_SETCONTROL        :: c.int(0x5)
DARWIN_PROC_INFO_CALL_PIDFILEPORTINFO   :: c.int(0x6)
DARWIN_PROC_INFO_CALL_TERMINATE         :: c.int(0x7)
DARWIN_PROC_INFO_CALL_DIRTYCONTROL      :: c.int(0x8)
DARWIN_PROC_INFO_CALL_PIDRUSAGE         :: c.int(0x9)
DARWIN_PROC_INFO_CALL_PIDORIGINATORINFO :: c.int(0xa)
DARWIN_PROC_INFO_CALL_LISTCOALITIONS    :: c.int(0xb)
DARWIN_PROC_INFO_CALL_CANUSEFGHW        :: c.int(0xc)
DARWIN_PROC_INFO_CALL_PIDDYNKQUEUEINFO  :: c.int(0xd)
DARWIN_PROC_INFO_CALL_UDATA_INFO        :: c.int(0xe)

/* mmap flags */
MAP_ANONYMOUS    :: 0x1000 /* allocated from memory, swap space */
MAP_FILE         :: 0x0000 /* map from file (default) */
MAP_FIXED        :: 0x0010 /* [MF|SHM] interpret addr exactly */
MAP_HASSEMAPHORE :: 0x0200 /* region may contain semaphores */
MAP_PRIVATE      :: 0x0002 /* [MF|SHM] changes are private */
MAP_SHARED       :: 0x0001 /* [MF|SHM] share changes */
MAP_NOCACHE      :: 0x0400 /* don't cache pages for this mapping */
MAP_JIT          :: 0x0800 /* Allocate a region that will be used for JIT purposes */
MAP_32BIT        :: 0x8000 /* Return virtual addresses <4G only */

/* mmap prot flags */
PROT_NONE  :: 0x00 /* [MC2] no permissions */
PROT_READ  :: 0x01 /* [MC2] pages can be read */
PROT_WRITE :: 0x02 /* [MC2] pages can be written */
PROT_EXEC  :: 0x04 /* [MC2] pages can be executed */

/* For owner Mode/Permission Flags for Open etc. */
PERMISSION_MASK_IRWXU :: 0o000700 /* RWX mask for owner */
PERMISSION_MASK_IRUSR :: 0o000400 /* R for owner */
PERMISSION_MASK_IWUSR :: 0o000200 /* W for owner */
PERMISSION_MASK_IXUSR :: 0o000100 /* X for owner */

/* For group Mode/Permission Flags for Open etc. */
PERMISSION_MASK_IRWXG :: 0o000070 /* RWX mask for group */
PERMISSION_MASK_IRGRP :: 0o000040 /* R for group */
PERMISSION_MASK_IWGRP :: 0o000020 /* W for group */
PERMISSION_MASK_IXGRP :: 0o000010 /* X for group */

/* For other Mode/Permission Flags for Open etc. */
PERMISSION_MASK_IRWXO :: 0o000007 /* RWX mask for other */
PERMISSION_MASK_IROTH :: 0o000004 /* R for other */
PERMISSION_MASK_IWOTH :: 0o000002 /* W for other */
PERMISSION_MASK_IXOTH :: 0o000001 /* X for other */

/* Special Mode/Permission Flags for Open etc. */
PERMISSION_MASK_ISUID :: 0o004000 /* set user id on execution */
PERMISSION_MASK_ISGID :: 0o002000 /* set group id on execution */
PERMISSION_MASK_ISVTX :: 0o001000 /* save swapped text even after use */

OPEN_FLAG_RDONLY :: 0x0000 /* open for reading only */
OPEN_FLAG_WRONLY :: 0x0001 /* open for writing only */
OPEN_FLAG_RDWR   :: 0x0002 /* open for reading and writing */

/* mask for above rd/wr/rdwr flags */
MASK_ACCMODE      :: 0x0003 

OPEN_FLAG_NONBLOCK     :: 0x00000004 /* no delay */
OPEN_FLAG_APPEND       :: 0x00000008 /* set append mode */
OPEN_FLAG_CREAT        :: 0x00000200 /* create if nonexistant */
OPEN_FLAG_TRUNC        :: 0x00000400 /* truncate to zero length */
OPEN_FLAG_EXCL         :: 0x00000800 /* error if already exists */
OPEN_FLAG_SHLOCK       :: 0x00000010 /* open with shared file lock */
OPEN_FLAG_EXLOCK       :: 0x00000020 /* open with exclusive file lock */
OPEN_FLAG_DIRECTORY    :: 0x00100000 /* restrict open to only directories */
OPEN_FLAG_NOFOLLOW     :: 0x00000100 /* don't follow symlinks */
OPEN_FLAG_SYMLINK      :: 0x00200000 /* allow open of a symlink */
OPEN_FLAG_EVTONLY      :: 0x00008000 /* descriptor requested for event notifications only */
OPEN_FLAG_CLOEXEC      :: 0x01000000 /* causes the descriptor to be closed if you use any of the exec like functions */
OPEN_FLAG_NOFOLLOW_ANY :: 0x20000000 /* no symlinks allowed in path */

/* bsd/sys/param.h */
DARWIN_MAXCOMLEN :: 16

/*--==========================================================================--*/

__darwin_ino64_t :: u64
__darwin_time_t :: c.long
__darwin_dev_t :: i32
__darwin_mode_t :: u16
__darwin_off_t :: i64
__darwin_blkcnt_t :: i64
__darwin_blksize_t :: i32
__darwin_pid_t :: i32
__darwin_suseconds_t :: i32

time_t :: __darwin_time_t
dev_t :: __darwin_dev_t
mode_t :: u16
nlink_t :: u16  
uid_t :: u16
gid_t :: u16
off_t :: __darwin_off_t
blkcnt_t :: __darwin_blkcnt_t
blksize_t :: __darwin_blksize_t
pid_t :: __darwin_pid_t

stat :: __DARWIN_STRUCT_STAT64 
timeval :: _STRUCT_TIMEVAL

/*--==========================================================================--*/

/* sys/stat.h */
__DARWIN_STRUCT_STAT64 :: struct {
	st_dev: dev_t,            /* [XSI] ID of device containing file */
	st_mode: mode_t,          /* [XSI] Mode of file (see below) */
	st_nlink: nlink_t,        /* [XSI] Number of hard links */
	st_ino: __darwin_ino64_t, /* [XSI] File serial number */
	st_uid_t: uid_t,          /* [XSI] User ID of the file */
	st_gid_t: gid_t,          /* [XSI] Group ID of the file */
	st_rdev: dev_t,           /* [XSI] Device ID */

	// __DARWIN_STRUCT_STAT64_TIMES 
	st_atime: time_t,      /* [XSI] Time of last access */ 
	st_atimensec: i32,     /* nsec of last access */ 
	st_mtime: time_t,      /* [XSI] Last data modification time */
	st_mtimensec: i32,     /* last data modification nsec */ 
	st_ctime: time_t,      /* [XSI] Time of last status change */ 
	st_ctimensec: u32,     /* nsec of last status change */ 
	st_birthtime: time_t,  /*  File creation time(birth)  */
	st_birthtimensec: i32, /* nsec of File creation time */
	// end __DARWIN_STRUCT_STAT64_TIMES

	st_size: off_t,        /* [XSI] file size, in bytes */
	st_blocks: blkcnt_t,   /* [XSI] blocks allocated for file */
	st_blksize: blksize_t, /* [XSI] optimal blocksize for I/O */
	st_flags: u32,         /* user defined flags for file */
	st_gen: u32,           /* file generation number */
	st_lspare: i32,        /* RESERVED: DO NOT USE! */
	st_qspare: [2]i64,     /* RESERVED: DO NOT USE! */
}

/* sys/_types/_timeval.h */
_STRUCT_TIMEVAL :: struct {
	tv_sec: __darwin_time_t, /* seconds */
	tv_usec: __darwin_suseconds_t, /* microseconds */
}

/* pwd.h */
_Password_Entry :: struct {
    pw_name: cstring, /* username */
    pw_passwd: cstring, /* user password */
    pw_uid: i32,   /* user ID */
    pw_gid: i32,   /* group ID */
	pw_change: u64,     /* password change time */
	pw_class: cstring, /* user access class */
    pw_gecos: cstring, /* full user name */
    pw_dir: cstring, /* home directory */
    pw_shell: cstring, /* shell program */
	pw_expire: u64,     /* account expiration */
	pw_fields: i32,     /* filled fields */
}

/* processinfo.h */
_Proc_Bsdinfo :: struct {
  pbi_flags: u32, /* if is 64bit; emulated etc */
  pbi_status: u32,
  pbi_xstatus: u32,
  pbi_pid: u32,
  pbi_ppid: u32,
  pbi_uid: u32,
  pbi_gid: u32,
  pbi_ruid: u32,
  pbi_rgid: u32,
  pbi_svuid: u32,
  pbi_svgid: u32,
  res: u32,
  pbi_comm: [DARWIN_MAXCOMLEN]u8,
  pbi_name: [2 * DARWIN_MAXCOMLEN]u8,	/* empty if no name is registered */
  pbi_nfiles: u32,
  pbi_pgid: u32,
  pbi_pjobc: u32,
  e_tdev: u32, /* controlling tty dev */
  e_tpgid: u32,	/* tty process group id */
  pbi_nice: i32,
  pbi_start_tvsec: u64,
  pbi_start_tvusec: u64,
}

/*--==========================================================================--*/

syscall_fsync :: #force_inline proc "contextless" (fildes: c.int) -> bool {
	return !(cast(bool)intrinsics.syscall(unix_offset_syscall(.fsync), uintptr(fildes)))
}

syscall_write :: #force_inline proc "contextless" (fildes: c.int, buf: ^byte, nbyte: u64) -> bool {
	return !(cast(bool)intrinsics.syscall(unix_offset_syscall(.write),  uintptr(fildes), uintptr(buf), uintptr(nbyte)))
}
 
syscall_read :: #force_inline proc "contextless" (fildes: c.int, buf: ^byte, nbyte: u64) -> i64 {
	return cast(i64)intrinsics.syscall(unix_offset_syscall(.read), uintptr(fildes), uintptr(buf), uintptr(nbyte))
}

syscall_open :: #force_inline proc "contextless" (path: cstring, oflag: u32, mode: u32) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.open), transmute(uintptr)path, uintptr(oflag), uintptr(mode))
}

syscall_close :: #force_inline proc "contextless" (fd: c.int) -> bool {
	return !(cast(bool)intrinsics.syscall(unix_offset_syscall(.close), uintptr(fd)))
}

syscall_fchmod :: #force_inline proc "contextless" (fildes: c.int, mode: u32) -> c.int {
	return (cast(c.int)intrinsics.syscall(unix_offset_syscall(.fchmod), uintptr(fildes), uintptr(mode)))
}

syscall_chmod :: #force_inline proc "contextless" (path: cstring, mode: u32) -> c.int {
	return (cast(c.int)intrinsics.syscall(unix_offset_syscall(.chmod), transmute(uintptr)path, uintptr(mode)))
}

syscall_mkdir :: #force_inline proc "contextless" (path: cstring, mode: u32) -> c.int {
	return (cast(c.int)intrinsics.syscall(unix_offset_syscall(.mkdir), transmute(uintptr)path, uintptr(mode)))
}

syscall_mkdir_at :: #force_inline proc "contextless" (fd: c.int, path: cstring, mode: u32) -> c.int {
	return (cast(c.int)intrinsics.syscall(unix_offset_syscall(.mkdir), uintptr(fd), transmute(uintptr)path, uintptr(mode)))
}

syscall_rmdir :: #force_inline proc "contextless" (path: cstring, mode: u32) -> c.int {
	return (cast(c.int)intrinsics.syscall(unix_offset_syscall(.rmdir), transmute(uintptr)path, uintptr(mode)))
}

syscall_rename :: #force_inline proc "contextless" (path_old: cstring, path_new: cstring) -> c.int {
	return (cast(c.int)intrinsics.syscall(unix_offset_syscall(.rename), transmute(uintptr)path_old, transmute(uintptr)path_new))
}

syscall_rename_at :: #force_inline proc "contextless" (from_fd: c.int, from: cstring, to_fd: c.int, to: cstring) -> c.int {
	return (cast(c.int)intrinsics.syscall(unix_offset_syscall(.renameat), uintptr(from_fd), transmute(uintptr)from, uintptr(to_fd), transmute(uintptr)to))
}

syscall_lseek :: #force_inline proc "contextless" (fd: c.int, offset: i64, whence: c.int) -> i64 {
	return cast(i64)intrinsics.syscall(unix_offset_syscall(.lseek), uintptr(fd), uintptr(offset), uintptr(whence))
}

syscall_gettid :: #force_inline proc "contextless" () -> u64 {
	return cast(u64)intrinsics.syscall(unix_offset_syscall(.gettid))
}

syscall_fstat :: #force_inline proc "contextless" (fd: c.int, status: ^stat) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.fstat), uintptr(fd), uintptr(status))
}

syscall_lstat :: #force_inline proc "contextless" (path: cstring, status: ^stat) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.lstat), transmute(uintptr)path, uintptr(status))
}

syscall_stat :: #force_inline proc "contextless" (path: cstring, status: ^stat) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.stat), transmute(uintptr)path, uintptr(status))
}

syscall_fstatat :: #force_inline proc "contextless" (fd: c.int, path: cstring, status: ^stat) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.fstatat), uintptr(fd), transmute(uintptr)path, uintptr(status))
}

syscall_link :: #force_inline proc "contextless" (path: cstring, to_link: cstring) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.link), transmute(uintptr)path, transmute(uintptr)to_link)
}

syscall_linkat :: #force_inline proc "contextless" (fd: c.int, path: cstring, fd2: c.int, to_link: cstring) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.linkat), uintptr(fd), transmute(uintptr)path, uintptr(fd2), transmute(uintptr)to_link)
}

syscall_readlink :: #force_inline proc "contextless" (path: cstring, buf: ^u8, buf_size: u64) -> i64 {
	return cast(i64)intrinsics.syscall(unix_offset_syscall(.readlink), transmute(uintptr)path, uintptr(buf), uintptr(buf_size))
}

syscall_readlinkat :: #force_inline proc "contextless" (fd: c.int, path: cstring, buf: ^u8, buf_size: u64) -> i64 {
	return cast(i64)intrinsics.syscall(unix_offset_syscall(.readlinkat), uintptr(fd), transmute(uintptr)path, uintptr(buf), uintptr(buf_size))
}

syscall_access :: #force_inline proc "contextless" (path: cstring, mode: c.int) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.access), transmute(uintptr)path, uintptr(mode))
}

syscall_faccessat :: #force_inline proc "contextless" (fd: c.int, path: cstring, mode: c.int, flag: c.int) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.faccessat), uintptr(fd), transmute(uintptr)path, uintptr(mode), uintptr(flag))
}

syscall_getdirentries :: #force_inline proc "contextless" (fd: c.int, buf: ^u8, nbytes: c.int, base_pointer: ^u32) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.getdirentries), uintptr(fd), uintptr(buf), uintptr(nbytes), uintptr(base_pointer))
}

syscall_truncate :: #force_inline proc "contextless" (path: cstring, length: off_t) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.truncate), transmute(uintptr)path, uintptr(length))
}

syscall_ftruncate :: #force_inline proc "contextless" (fd: c.int, length: off_t) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.ftruncate), uintptr(fd), uintptr(length))
}

syscall_sysctl :: #force_inline proc "contextless" (name: [^]c.int, namelen: c.size_t, oldp: rawptr, oldlenp: ^c.size_t, newp: rawptr, newlen: c.size_t) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.sysctl), uintptr(name), uintptr(namelen), uintptr(oldp), uintptr(oldlenp), uintptr(newp), uintptr(newlen))
}

syscall_copyfile ::  #force_inline proc "contextless" (from: cstring, to: cstring, state: rawptr, flags: u32) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.copyfile), transmute(uintptr)from, transmute(uintptr)to, uintptr(state), uintptr(flags))
} 

// think about this? last arg should be more than one
syscall_fcntl :: #force_inline proc "contextless" (fd: c.int, cmd: c.int, other: rawptr) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.fsctl), uintptr(fd), uintptr(cmd), uintptr(other))
}

syscall_exit :: #force_inline proc "contextless" (code: c.int) {
	intrinsics.syscall(unix_offset_syscall(.exit), uintptr(code))
}

syscall_kill :: #force_inline proc "contextless" (pid: pid_t, sig: c.int) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.kill), uintptr(pid), uintptr(sig))
}

syscall_dup :: #force_inline proc "contextless" (fd: c.int) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.dup), uintptr(fd))
}

syscall_execve :: #force_inline proc "contextless" (path: cstring, argv: [^]cstring, env: [^]cstring) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.execve), transmute(uintptr)path, transmute(uintptr)argv, transmute(uintptr)env)
}

syscall_munmap :: #force_inline proc "contextless" (addr: rawptr, len: u64) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.munmap), uintptr(addr), uintptr(len))
}

syscall_mmap :: #force_inline proc "contextless" (addr: ^u8, len: u64, port: c.int, flags: c.int, fd: int, offset: off_t) -> ^u8 {
	return cast(^u8)intrinsics.syscall(unix_offset_syscall(.mmap), uintptr(addr), uintptr(len), uintptr(port), uintptr(flags), uintptr(fd), uintptr(offset))
}

syscall_flock :: #force_inline proc "contextless" (fd: c.int, operation: c.int) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.flock), uintptr(fd), uintptr(operation)) 
}

syscall_utimes :: #force_inline proc "contextless" (path: cstring, times: ^timeval) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.utimes), transmute(uintptr)path, uintptr(times))
}

syscall_futimes :: #force_inline proc "contextless" (fd: c.int, times: ^timeval) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.futimes), uintptr(fd), uintptr(times))
}

syscall_adjtime :: #force_inline proc "contextless" (delta: ^timeval, old_delta: ^timeval) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.adjtime), uintptr(delta), uintptr(old_delta))
}

syscall_sysctlbyname :: #force_inline proc "contextless" (name: string, oldp: rawptr, oldlenp: ^c.size_t, newp: rawptr, newlen: c.size_t) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.sysctlbyname), uintptr(raw_data(name)), uintptr(len(name)), uintptr(oldp), uintptr(oldlenp), uintptr(newp), uintptr(newlen))
}

syscall_proc_info :: #force_inline proc "contextless" (num: c.int, pid: u32, flavor: c.int, arg: u64, buffer: rawptr, buffer_size: c.int) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.proc_info), uintptr(num), uintptr(pid), uintptr(flavor), uintptr(arg), uintptr(buffer), uintptr(buffer_size))
}

syscall_openat :: #force_inline proc "contextless" (fd: int, path: cstring, oflag: u32, mode: u32) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.openat), uintptr(fd), transmute(uintptr)path, uintptr(oflag), uintptr(mode))
} 

syscall_getentropy :: #force_inline proc "contextless" (buf: [^]u8, buflen: u64) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.getentropy), uintptr(buf), uintptr(buflen))
}

syscall_pipe :: #force_inline proc "contextless" (fds: [^]c.int) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.getentropy), uintptr(&fds[0]), uintptr(&fds[1]))
}

syscall_chdir :: #force_inline proc "contextless" (path: cstring) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.getentropy), transmute(uintptr)path)
}

syscall_fchdir :: #force_inline proc "contextless" (fd: c.int, path: cstring) -> c.int {
	return cast(c.int)intrinsics.syscall(unix_offset_syscall(.getentropy), uintptr(fd), transmute(uintptr)path)
}

syscall_getrusage :: #force_inline proc "contextless" (who: c.int, rusage: ^RUsage) -> c.int {
	return cast(c.int) intrinsics.syscall(unix_offset_syscall(.getrusage), uintptr(who), uintptr(rusage))
}
