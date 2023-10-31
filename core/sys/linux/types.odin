//+build linux
package linux

/// Represents storage device handle
Dev :: distinct int

/// Represents 32-bit user id
Uid :: distinct u32

/// Represents 32-bit group id
Gid :: distinct u32

/// Process id's
Pid :: distinct int

/// Represents pid, pifd, pgid values in general
Id :: distinct uint

/// Represents a file descriptor
Fd  :: distinct i32

/// Represents a PID file descriptor
Pid_FD :: distinct i32

/// Represents 64-bit inode number for files
/// Used pretty much only in struct Stat64 for 32-bit platforms
Inode :: distinct u64

/// Represents time with nanosecond precision
Time_Spec :: struct {
	time_sec:  uint,
	time_nsec: uint,
}

/// Represents time with millisecond precision
Time_Val :: struct {
	seconds:      int,
	microseconds: int,
}

/// open.2 flags
Open_Flags :: bit_set[Open_Flags_Bits; u32]

/// Flags for the file descriptor to be passed in some syscalls
FD_Flags :: bit_set[FD_Flags_Bits; i32]

/// Represents file's permission and status bits
/// Example:
///   When you're passing a value of this type the recommended usage is
///     sys.Mode{.S_IXOTH, .S_IROTH} | sys.S_IRWXU | sys.S_IRWXG
///   This would generate a mode that has full permissions for the
///   file's owner and group, and only "read" and "execute" bits
///   for others.
Mode :: bit_set[Mode_Bits; u32]

when ODIN_ARCH == .amd64 {
	// x86-64 has mode and nlink swapped for some reason
	_Arch_Stat :: struct {
		dev:       Dev,
		ino:       Inode,
		nlink:     uint,
		mode:      Mode,
		uid:       Uid,
		gid:       Gid,
		_:         u32,
		rdev:      Dev,
		size:      uint,
		blksize:   uint,
		blocks:    uint,
		atime:     Time_Spec,
		mtime:     Time_Spec,
		ctime:     Time_Spec,
		_:         [3]uint,
	}
} else when ODIN_ARCH == .arm64 {
	_Arch_Stat :: struct {
		dev:        Dev,
		ino:        Inode,
		mode:       Mode,
		nlink:      u32,
		uid:        Uid,
		gid:        Gid,
		rdev:       Dev,
		_:          u64,
		size:       int,
		blksize:    i32,
		_:          i32,
		blocks:     int,
		atime:      Time_Spec,
		mtime:      Time_Spec,
		ctime:      Time_Spec,
		_:          [3]uint,
	}
} else {
	_Arch_Stat :: struct {
		dev:        Dev,
		_:          [4]u8,
		_ino:       uint, // Old 32-bit inode number, don't use
		mode:       Mode,
		nlink:      u32,
		uid:        Uid,
		gid:        Gid,
		rdev:       Dev,
		size:       i64,
		blksize:    uint,
		blocks:     u64,
		atim:       Time_Spec,
		mtim:       Time_Spec,
		ctim:       Time_Spec,
		ino:        Inode,
	}
}

/// Represents the file state.
/// Mirrors struct stat in glibc/linux kernel.
/// If you're on 32-bit platform, consider using Stat64 instead
Stat :: struct {
	using _impl_stat: _Arch_Stat,
}

/// Timestamp type used for Statx struct
Statx_Timestamp :: struct {
	sec:  i64,
	nsec: u32,
	_:       i32,
}

/// Query params/results for `statx()`
Statx_Mask :: bit_set[Statx_Mask_Bits; u32]

/// File attributes, returned by statx. This bitset is also
/// used to specify which attributes are present, not just
/// their value.
Statx_Attr :: bit_set[Statx_Attr_Bits; u64]

/// The extended Stat struct
Statx :: struct {
	mask:                Statx_Mask,
	blksize:             u32,
	attributes:          Statx_Attr,
	nlink:               u32,
	uid:                 Uid,
	gid:                 Gid,
	// Note(flysand): mode is 16-bit on linux + there's
	// 16-bit padding following it. Since our mode is 32-bits,
	// we're using the padding. This should be fine because
	// the placement of that padding suggests it was going to
	// be used for the Mode bits anyway.
	mode:                Mode,
	ino:                 Inode,
	size:                u64,
	blocks:              u64,
	attributes_mask:     Statx_Attr,
	atime:               Statx_Timestamp,
	btime:               Statx_Timestamp,
	ctime:               Statx_Timestamp,
	mtime:               Statx_Timestamp,
	rdev_major:          u32,
	rdev_minor:          u32,
	dev_major:           u32,
	dev_minor:           u32,
	mnt_id:              u64,
	dio_mem_align:       u32,
	dio_offset_align:    u32,
	_:                   [12]u64,
}

/// Mount flags for filesystem
FS_Flags :: bit_set[FS_Flags_Bits; u32]

when size_of(int) == 8 {
	_Arch_Stat_FS :: struct {
		// Note(flysand): The FS_Magic bits are never above
		// 32-bits, so it should be fine for now...
		type:     FS_Magic,
		_:        u32,
		bsize:    i64,
		blocks:   i64,
		bfree:    i64,
		bavail:   i64,
		files:    i64,
		ffree:    i64,
		fsid :    [2]i32,
		namelen:  i64,
		frsize:   i64,
		// Note(flysand): Same story as type
		flags:    FS_Flags,
		_:        u32,
		spare:    [4]i64,
	}
} else {
	_Arch_Stat_FS :: struct {
		type:     FS_Magic,
		bsize:    u32,
		blocks:   u64,
		bfree:    u64,
		bavail:   u64,
		files:    u64,
		ffree:    u64,
		fsid:     [2]i32,
		namelen:  u32,
		frsize:   u32,
		flags:    FS_Flags,
		spare:    [4]u32,
	}
}

Stat_FS :: struct {
	using _impl_stat_fs: _Arch_Stat_FS,
}

/// Flags for close_range.2
Close_Range_Flags :: bit_set[Close_Range_Flags_Bits; u32]

/// Flags for rename.2
Rename_Flags :: bit_set[Rename_Flags_Bits; u32]

/// Directory entry
/// Recommended to use this with dirent_iterator()
/// and dirent_name()
Dirent :: struct {
	ino:    Inode,
	off:    i64,
	reclen: u16,
	type:   Dirent_Type,
	name:   [0]u8, // See dirent_name
}

/// Lock record for fcntl.2
FLock :: struct {
	type:   FLock_Type,
	whence: Seek_Whence,
	start:  i64,
	len:    i64,
	pid:    Pid,
}

/// Flags for fcntl_notify
FD_Notifications :: bit_set[FD_Notifications_Bits; i32]

/// Seals for fcntl_add_seals
Seal :: bit_set[Seal_Bits; i32]

/// Represents owner that receives events on file updates
F_Owner :: struct {
	type: F_Owner_Type,
	pid:  Pid,
}

/// Events for ppoll
Fd_Poll_Events :: bit_set[Fd_Poll_Events_Bits; u16]

/// Struct for ppoll
Poll_Fd :: struct {
	fd:      Fd,
	events:  Fd_Poll_Events,
	revents: Fd_Poll_Events,
}

/// Specifies protection for memory pages
Mem_Protection :: bit_set[Mem_Protection_Bits; i32]

/// Flags for mmap
Map_Flags :: bit_set[Map_Flags_Bits; i32]

/// Flags for mlock.2
MLock_Flags :: bit_set[MLock_Flags_Bits; u32]

/// Flags for msync.2
MSync_Flags :: bit_set[MSync_Flags_Bits; i32]

/// Access rights for pkey_alloc.2
PKey_Access_Rights :: bit_set[PKey_Access_Bits; u32]

/// Flags for mremap.2
MRemap_Flags :: bit_set[MRemap_Flags_Bits; i32]

/// Flags for getrandom syscall
Get_Random_Flags :: bit_set[Get_Random_Flags_Bits; i32]

/// Flags for perf_event_open syscall
Perf_Flags :: bit_set[Perf_Flags_Bits; uint]

Perf_Event_Flags :: distinct bit_set[Perf_Event_Flags_Bits; u64]

Perf_Cap_Flags :: distinct bit_set[Perf_Cap_Flags_Bits; u64]

Perf_Event_Sample_Type :: bit_set[Perf_Event_Sample_Type_Bits; u64]

/// Specifies which branches to include in branch record
Branch_Sample_Type :: bit_set[Branch_Sample_Type_Bits; u64]

/// The struct for perf_event_open
Perf_Event_Attr :: struct #packed {
	type:               Perf_Event_Type,
	size:               u32,
	config: struct #raw_union {
		hw: Perf_Hardware_Id,
		sw: Perf_Software_Id,
		cache: u64,
		other: u64,
	},
	sample: struct #raw_union {
		period:    u64,
		frequency: u64,
	},
	sample_type:        Perf_Event_Sample_Type,
	read_format:        Perf_Read_Format,
	flags:              Perf_Event_Flags,
	wakeup: struct #raw_union {
		events:    u32,
		watermark: u32,
	},
	breakpoint_type:    Hardware_Breakpoint_Type,
	using _: struct #raw_union {
		breakpoint_addr: u64,
		kprobe_func:     u64,
		uprobe_path:     u64,
		config1:         u64,
	},
	using _: struct #raw_union {
		breakpoint_len: u64,
		kprobe_addr:    u64,
		uprobe_offset:  u64,
		config2:        u64,
	},
	branch_sample_type: Branch_Sample_Type,
	sample_regs_user:   u64,
	sample_stack_user:  u32,
	clock_id:           i32, // TODO(flysand): clock_id
	sample_regs_intr:   u64,
	aux_watermark:      u32,
	sample_max_stack:   u16,
	_:                  u16,
}

/// The ring buffer structure when mmaping Perf_Event_Attr
Perf_Event_Mmap_Page :: struct #packed {
	version:        u32,
	compat_version: u32,
	lock:           u32,
	index:          u32,
	offset:         i64,
	time_enabled:   u64,
	time_running:   u64,
	cap: struct #raw_union {
		capabilities: u64,
		flags: Perf_Cap_Flags,
	},
	pmc_width:      u16,
	time_shift:     u16,
	time_mult:      u32,
	time_offset:    u64,
	time_zero:      u64,
	size:           u32,
	reserved1:      u32,
	time_cycles:    u64,
	time_mask:      u64,
	reserved2:      [116*8]u8,
	data_head:      u64,
	data_tail:      u64,
	data_offset:    u64,
	data_size:      u64,
	aux_head:       u64,
	aux_tail:       u64,
	aux_offset:     u64,
	aux_size:       u64,
}

// TODO(flysand): Its taking too much effort to bind the other data structures related to perf_event_open

/// Options for wait4() and waitpid()
Wait_Options :: bit_set[Wait_Option; i32]

/// Flags for pidfd_open.2
Pid_FD_Flags :: bit_set[Pid_FD_Flags_Bits; i32]

// Note(flysand): these could, in principle be implemented with bitfields,
// however there are ABI differences between odin's bitfields and linux sigsets.
// Mainly:
//  1. Odin's bitfields start from 0, whereas signals start from 1
//  2. It's unclear how bitfields act in terms of ABI (are they an array of ints or an array of longs?).
//     it makes a difference because ARM is big endian.
@private _SIGSET_NWORDS :: (1024 / (8 * size_of(uint)))
Sig_Set :: [_SIGSET_NWORDS]uint

@private SI_MAX_SIZE       :: 128
@private SI_ARCH_PREAMBLE  :: 3 * size_of(i32)
@private SI_PAD_SIZE       :: (SI_MAX_SIZE - SI_ARCH_PREAMBLE) / size_of(i32)
@private SI_TIMER_PAD_SIZE :: size_of(Uid) - size_of(i32)

Sig_Handler_Fn :: #type proc "c" (sig: Signal)
Sig_Restore_Fn :: #type proc "c" ()

Sig_Info :: struct #packed {
	signo: Signal,
	errno: Errno,
	code: i32,
	_pad0: i32,
	using _union: struct #raw_union {
		_pad1: [SI_PAD_SIZE]u8,
		using _kill: struct {
			pid: Pid, /* sender's pid */
			uid: Uid, /* sender's uid */
		},
		using _timer: struct {
			timerid: i32,       /* timer id */
			overrun: i32,   /* overrun count */
		},
		/* POSIX.1b signals */
		using _rt: struct {
			_pid0: Pid, /* sender's pid */
			_uid0: Uid, /* sender's uid */
		},
		/* SIGCHLD */
		using _sigchld: struct {
			_pid1: Pid,      /* which child */
			_uid1: Uid,      /* sender's uid */
			status: i32, /* exit code */
			utime: uint,
			stime: uint, //clock_t
		},
		/* SIGILL, SIGFPE, SIGSEGV, SIGBUS */
		using _sigfault: struct {
			addr: rawptr, /* faulting insn/memory ref. */
			addr_lsb: i16, /* LSB of the reported address */
		},
		/* SIGPOLL */
		using _sigpoll: struct {
			band: int, /* POLL_IN, POLL_OUT, POLL_MSG */
			fd: Fd,
		},
		/* SIGSYS */
		using _sigsys: struct {
			call_addr: rawptr, /* calling user insn */
			syscall: i32,    /* triggering system call number */
			arch: u32,      /* AUDIT_ARCH_* of syscall */
		},
	},
}

Sig_Stack_Flags :: bit_set[Sig_Stack_Flag; i32]

Sig_Stack :: struct {
	sp: rawptr,
	flags: Sig_Stack_Flags,
	size: uintptr,
}

Sig_Action :: struct($T: typeid) {
	using _u: struct #raw_union {
		handler: Sig_Handler_Fn,
		sigaction: #type proc "c" (sig: Signal, si: ^Sig_Info, ctx: ^T),
	},
	flags: uint,
	restorer: Sig_Restore_Fn,
	mask: Sig_Set,
}


/// Flags for the socket file descriptor
/// Note, on linux these are technically passed by OR'ing together
/// with Socket_Type, our wrapper does this under the hood.
Socket_FD_Flags :: bit_set[Socket_FD_Flags_Bits; int]

/// Address family for the socket
/// Typically there's one address family for every protocol family
Address_Family :: distinct Protocol_Family

/// Flags for the socket for send/recv calls
Socket_Msg :: bit_set[Socket_Msg_Bits; i32]

/// Struct representing IPv4 socket address
Sock_Addr_In :: struct #packed {
	sin_family: Address_Family,
	sin_port:   u16be,
	sin_addr:   [4]u8,
}

/// Struct representing IPv6 socket address
Sock_Addr_In6 :: struct #packed {
	sin6_family:   Address_Family,
	sin6_port:     u16be,
	sin6_flowinfo: u32,
	sin6_addr:     [16]u8,
	sin6_scope_id: u32,
}

/// Struct representing an arbitrary socket address
Sock_Addr_Any :: struct #raw_union {
	using _: struct {
		family: Address_Family,
		port:   u16be,
	},
	using ipv4: Sock_Addr_In,
	using ipv6: Sock_Addr_In6,
}

/// Just an alias to make futex-values more visible
Futex :: u32

/// Flags for the futex (they are kept separately)
Futex_Flags :: bit_set[Futex_Flags_Bits; u32]

/// Times
Tms :: struct {
	tms_utime:  int,
	tms_stime:  int,
	tms_cutime: int,
	tms_cstime: int,
}

/// "Unix time-sharing system name", allegedly
/// Basically system info
UTS_Name :: struct {
	sysname:    [65]u8 `fmt:"s,0"`,
	nodename:   [65]u8 `fmt:"s,0"`,
	release:    [65]u8 `fmt:"s,0"`,
	version:    [65]u8 `fmt:"s,0"`,
	machine:    [65]u8 `fmt:"s,0"`,
	domainname: [65]u8 `fmt:"s,0"`,
}

/// Return buffer for the sysinfo syscall
Sys_Info :: struct {
	uptime:    int,
	loads:     [3]int,
	totalram:  uint,
	freeram:   uint,
	sharedram: uint,
	bufferram: uint,
	totalswap: uint,
	freeswap:  uint,
	procs:     u16,
	totalhigh: uint,
	freehigh:  uint,
	mem_unit:  i32,
	_padding:  [20 - (2 * size_of(int)) - size_of(i32)]u8,
}

/// Resource limit
RLimit :: struct {
	cur: uint,
	max: uint,
}

/// Structure representing how much of each resource
/// got used.
RUsage :: struct {
	utime:         Time_Val,
	stime:         Time_Val,
	maxrss_word:   int,
	ixrss_word:    int,
	idrss_word:    int,
	isrss_word:    int,
	minflt_word:   int,
	majflt_word:   int,
	nswap_word:    int,
	inblock_word:  int,
	oublock_word:  int,
	msgsnd_word:   int,
	msgrcv_word:   int,
	nsignals_word: int,
	nvcsw_word:    int,
	nivcsw_word:   int,
}
