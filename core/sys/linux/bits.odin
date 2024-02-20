package linux


/*
	Represents an error returned by most of syscalls
*/
Errno :: enum i32 {
	NONE = 0,
	// Errno-base
	EPERM           = 1,
	ENOENT          = 2,
	ESRCH           = 3,
	EINTR           = 4,
	EIO             = 5,
	ENXIO           = 6,
	E2BIG           = 7,
	ENOEXEC         = 8,
	EBADF           = 9,
	ECHILD          = 10,
	EAGAIN          = 11,
	ENOMEM          = 12,
	EACCES          = 13,
	EFAULT          = 14,
	ENOTBLK         = 15,
	EBUSY           = 16,
	EEXIST          = 17,
	EXDEV           = 18,
	ENODEV          = 19,
	ENOTDIR         = 20,
	EISDIR          = 21,
	EINVAL          = 22,
	ENFILE          = 23,
	EMFILE          = 24,
	ENOTTY          = 25,
	ETXTBSY         = 26,
	EFBIG           = 27,
	ENOSPC          = 28,
	ESPIPE          = 29,
	EROFS           = 30,
	EMLINK          = 31,
	EPIPE           = 32,
	EDOM            = 33,
	ERANGE          = 34,
	// Linux
	EDEADLK         = 35,
	ENAMETOOLONG    = 36,
	ENOLCK          = 37,
	ENOSYS          = 38,
	ENOTEMPTY       = 39,
	ELOOP           = 40,
	ENOMSG          = 42,
	EIDRM           = 43,
	ECHRNG          = 44,
	EL2NSYNC        = 45,
	EL3HLT          = 46,
	EL3RST          = 47,
	ELNRNG          = 48,
	EUNATCH         = 49,
	ENOCSI          = 50,
	EL2HLT          = 51,
	EBADE           = 52,
	EBADR           = 53,
	EXFULL          = 54,
	ENOANO          = 55,
	EBADRQC         = 56,
	EBADSLT         = 57,
	EBFONT          = 59,
	ENOSTR          = 60,
	ENODATA         = 61,
	ETIME           = 62,
	ENOSR           = 63,
	ENONET          = 64,
	ENOPKG          = 65,
	EREMOTE         = 66,
	ENOLINK         = 67,
	EADV            = 68,
	ESRMNT          = 69,
	ECOMM           = 70,
	EPROTO          = 71,
	EMULTIHOP       = 72,
	EDOTDOT         = 73,
	EBADMSG         = 74,
	EOVERFLOW       = 75,
	ENOTUNIQ        = 76,
	EBADFD          = 77,
	EREMCHG         = 78,
	ELIBACC         = 79,
	ELIBBAD         = 80,
	ELIBSCN         = 81,
	ELIBMAX         = 82,
	ELIBEXEC        = 83,
	EILSEQ          = 84,
	ERESTART        = 85,
	ESTRPIPE        = 86,
	EUSERS          = 87,
	ENOTSOCK        = 88,
	EDESTADDRREQ    = 89,
	EMSGSIZE        = 90,
	EPROTOTYPE      = 91,
	ENOPROTOOPT     = 92,
	EPROTONOSUPPORT = 93,
	ESOCKTNOSUPPORT = 94,
	EOPNOTSUPP      = 95,
	EPFNOSUPPORT    = 96,
	EAFNOSUPPORT    = 97,
	EADDRINUSE      = 98,
	EADDRNOTAVAIL   = 99,
	ENETDOWN        = 100,
	ENETUNREACH     = 101,
	ENETRESET       = 102,
	ECONNABORTED    = 103,
	ECONNRESET      = 104,
	ENOBUFS         = 105,
	EISCONN         = 106,
	ENOTCONN        = 107,
	ESHUTDOWN       = 108,
	ETOOMANYREFS    = 109,
	ETIMEDOUT       = 110,
	ECONNREFUSED    = 111,
	EHOSTDOWN       = 112,
	EHOSTUNREACH    = 113,
	EALREADY        = 114,
	EINPROGRESS     = 115,
	ESTALE          = 116,
	EUCLEAN         = 117,
	ENOTNAM         = 118,
	ENAVAIL         = 119,
	EISNAM          = 120,
	EREMOTEIO       = 121,
	EDQUOT          = 122,
	ENOMEDIUM       = 123,
	EMEDIUMTYPE     = 124,
	ECANCELED       = 125,
	ENOKEY          = 126,
	EKEYEXPIRED     = 127,
	EKEYREVOKED     = 128,
	EKEYREJECTED    = 129,
	EOWNERDEAD      = 130,
	ENOTRECOVERABLE = 131,
	ERFKILL         = 132,
	EHWPOISON       = 133,
	// Errno aliases
	EWOULDBLOCK     = EAGAIN,
	EDEADLOCK       = EDEADLK,
}

/*
	Bits for Open_Flags
*/
Open_Flags_Bits :: enum {
	RDONLY    = 0,
	WRONLY    = 1,
	RDWR      = 2,
	CREAT     = 6,
	EXCL      = 7,
	NOCTTY    = 8,
	TRUNC     = 9,
	APPEND    = 10,
	NONBLOCK  = 11,
	DSYNC     = 12,
	ASYNC     = 13,
	DIRECT    = 14,
	DIRECTORY = 16,
	NOFOLLOW  = 17,
	NOATIME   = 18,
	CLOEXEC   = 19,
	PATH      = 21,
}

/*
	Bits for FD_Flags bitset
*/
FD_Flags_Bits :: enum {
	SYMLINK_NOFOLLOW   = 8,
	REMOVEDIR          = 9,
	EACCESS            = 9,
	SYMLINK_FOLLOW     = 10,
	NO_AUTOMOUNT       = 11,
	EMPTY_PATH         = 12,
	STATX_FORCE_SYNC   = 13,
	STATX_DONT_SYNC    = 14,
	RECURSIVE          = 15,
}

/*
	The bits for the Mode bitset.
*/
Mode_Bits :: enum {
	IXOTH  = 0,  // 0o0000001
	IWOTH  = 1,  // 0o0000002
	IROTH  = 2,  // 0o0000004
	IXGRP  = 3,  // 0o0000010
	IWGRP  = 4,  // 0o0000020
	IRGRP  = 5,  // 0o0000040
	IXUSR  = 6,  // 0o0000100
	IWUSR  = 7,  // 0o0000200
	IRUSR  = 8,  // 0o0000400
	ISVTX  = 9,  // 0o0001000
	ISGID  = 10, // 0o0002000
	ISUID  = 11, // 0o0004000
	IFFIFO = 12, // 0o0010000
	IFCHR  = 13, // 0o0020000
	IFDIR  = 14, // 0o0040000
	IFREG  = 15, // 0o0100000
}

/*
	The bits used by the Statx_Mask bitset
*/
Statx_Mask_Bits :: enum {
	TYPE         = 0,
	MODE         = 1,
	NLINK        = 2,
	UID          = 3,
	GID          = 4,
	ATIME        = 5,
	MTIME        = 6,
	CTIME        = 7,
	INO          = 8,
	SIZE         = 9,
	BLOCKS       = 10,
	BTIME        = 11,
	MNT_ID       = 12,
	DIOALIGN     = 13,
}

/*
	Bits found in Statx_Attr bitset
	You should not use these directly
*/
Statx_Attr_Bits :: enum {
	COMPRESSED = 2,  // 0x00000004
	IMMUTABLE  = 4,  // 0x00000010
	APPEND     = 5,  // 0x00000020
	NODUMP     = 6,  // 0x00000040
	ENCRYPTED  = 11, // 0x00000800
	AUTOMOUNT  = 12, // 0x00001000
	MOUNT_ROOT = 13, // 0x00002000
	VERITY     = 20, // 0x00100000
	DAX        = 21, // 0x00200000
}

/*
	Magic bits for filesystems returned by Stat_FS
*/
FS_Magic :: enum u32 {
	ADFS_SUPER_MAGIC      = 0xadf5,
	AFFS_SUPER_MAGIC      = 0xadff,
	AFS_SUPER_MAGIC       = 0x5346414f,
	ANON_INODE_FS_MAGIC   = 0x09041934,
	AUTOFS_SUPER_MAGIC    = 0x0187,
	BDEVFS_MAGIC          = 0x62646576,
	BEFS_SUPER_MAGIC      = 0x42465331,
	BFS_MAGIC             = 0x1badface,
	BINFMTFS_MAGIC        = 0x42494e4d,
	BPF_FS_MAGIC          = 0xcafe4a11,
	BTRFS_SUPER_MAGIC     = 0x9123683e,
	BTRFS_TEST_MAGIC      = 0x73727279,
	CGROUP_SUPER_MAGIC    = 0x27e0eb,
	CGROUP2_SUPER_MAGIC   = 0x63677270,
	CIFS_MAGIC_NUMBER     = 0xff534d42,
	CODA_SUPER_MAGIC      = 0x73757245,
	COH_SUPER_MAGIC       = 0x012ff7b7,
	CRAMFS_MAGIC          = 0x28cd3d45,
	DEBUGFS_MAGIC         = 0x64626720,
	DEVFS_SUPER_MAGIC     = 0x1373,
	DEVPTS_SUPER_MAGIC    = 0x1cd1,
	ECRYPTFS_SUPER_MAGIC  = 0xf15f,
	EFIVARFS_MAGIC        = 0xde5e81e4,
	EFS_SUPER_MAGIC       = 0x00414a53,
	EXT_SUPER_MAGIC       = 0x137d,
	EXT2_OLD_SUPER_MAGIC  = 0xef51,
	EXT2_SUPER_MAGIC      = 0xef53,
	EXT3_SUPER_MAGIC      = 0xef53,
	EXT4_SUPER_MAGIC      = 0xef53,
	F2FS_SUPER_MAGIC      = 0xf2f52010,
	FUSE_SUPER_MAGIC      = 0x65735546,
	FUTEXFS_SUPER_MAGIC   = 0xbad1dea,
	HFS_SUPER_MAGIC       = 0x4244,
	HOSTFS_SUPER_MAGIC    = 0x00c0ffee,
	HPFS_SUPER_MAGIC      = 0xf995e849,
	HUGETLBFS_MAGIC       = 0x958458f6,
	ISOFS_SUPER_MAGIC     = 0x9660,
	JFFS2_SUPER_MAGIC     = 0x72b6,
	JFS_SUPER_MAGIC       = 0x3153464a,
	MINIX_SUPER_MAGIC     = 0x137f,
	MINIX_SUPER_MAGIC2    = 0x138f,
	MINIX2_SUPER_MAGIC    = 0x2468,
	MINIX2_SUPER_MAGIC2   = 0x2478,
	MINIX3_SUPER_MAGIC    = 0x4d5a,
	MQUEUE_MAGIC          = 0x19800202,
	MSDOS_SUPER_MAGIC     = 0x4d44,
	MTD_INODE_FS_MAGIC    = 0x11307854,
	NCP_SUPER_MAGIC       = 0x564c,
	NFS_SUPER_MAGIC       = 0x6969,
	NILFS_SUPER_MAGIC     = 0x3434,
	NSFS_MAGIC            = 0x6e736673,
	NTFS_SB_MAGIC         = 0x5346544e,
	OCFS2_SUPER_MAGIC     = 0x7461636f,
	OPENPROM_SUPER_MAGIC  = 0x9fa1,
	OVERLAYFS_SUPER_MAGIC = 0x794c7630,
	PIPEFS_MAGIC          = 0x50495045,
	PROC_SUPER_MAGIC      = 0x9fa0,
	PSTOREFS_MAGIC        = 0x6165676c,
	QNX4_SUPER_MAGIC      = 0x002f,
	QNX6_SUPER_MAGIC      = 0x68191122,
	RAMFS_MAGIC           = 0x858458f6,
	REISERFS_SUPER_MAGIC  = 0x52654973,
	ROMFS_MAGIC           = 0x7275,
	SECURITYFS_MAGIC      = 0x73636673,
	SELINUX_MAGIC         = 0xf97cff8c,
	SMACK_MAGIC           = 0x43415d53,
	SMB_SUPER_MAGIC       = 0x517b,
	SMB2_MAGIC_NUMBER     = 0xfe534d42,
	SOCKFS_MAGIC          = 0x534f434b,
	SQUASHFS_MAGIC        = 0x73717368,
	SYSFS_MAGIC           = 0x62656572,
	SYSV2_SUPER_MAGIC     = 0x012ff7b6,
	SYSV4_SUPER_MAGIC     = 0x012ff7b5,
	TMPFS_MAGIC           = 0x01021994,
	TRACEFS_MAGIC         = 0x74726163,
	UDF_SUPER_MAGIC       = 0x15013346,
	UFS_MAGIC             = 0x00011954,
	USBDEVICE_SUPER_MAGIC = 0x9fa2,
	V9FS_MAGIC            = 0x01021997,
	VXFS_SUPER_MAGIC      = 0xa501fcf5,
	XENFS_SUPER_MAGIC     = 0xabba1974,
	XENIX_SUPER_MAGIC     = 0x012ff7b4,
	XFS_SUPER_MAGIC       = 0x58465342,
	_XIAFS_SUPER_MAGIC    = 0x012fd16d,
}

/*
	Bits for FS_Flags bitset
*/
FS_Flags_Bits :: enum {
	RDONLY       = 0,
	NOSUID       = 1,
	NODEV        = 2,
	NOEXEC       = 3,
	SYNCHRONOUS  = 4,
	VALID        = 5,
	MANDLOCK     = 6,
	NOATIME      = 10,
	NODIRATIME   = 11,
	RELATIME     = 12,
	NOSYMFOLLOW  = 13,
}

Seek_Whence :: enum i16 {
	SET  = 0,
	CUR  = 1,
	END  = 2,
	DATA = 3,
	HOLE = 4,
}

/*
	Bits for Close_Range_Flags
*/
Close_Range_Flags_Bits :: enum {
	CLOEXEC = 2,
	UNSHARE = 1,
}

/*
	Bits for Rename_Flags
*/
Rename_Flags_Bits :: enum {
	EXCHANGE  = 1,
	NOREPLACE = 0,
	WHITEOUT  = 2,
}

/*
	Type of the file in a directory entry
*/
Dirent_Type :: enum u8 {
	UNKNOWN = 0,
	FIFO    = 1,
	CHR     = 2,
	DIR     = 4,
	BLK     = 6,
	REG     = 8,
	LNK     = 10,
	SOCK    = 12,
	WHT     = 14,
}

/*
	Type of a lock for fcntl(2)
*/
FLock_Type :: enum i16 {
	RDLCK = 0,
	WRLCK = 1,
	UNLCK = 2,
}

/*
	Bits for FD_Notifications
*/
FD_Notifications_Bits :: enum {
	ACCESS    = 0,
	MODIFY    = 1,
	CREATE    = 2,
	DELETE    = 3,
	RENAME    = 4,
	ATTRIB    = 5,
	MULTISHOT = 31,
}

/*
	Bits for seal
*/
Seal_Bits :: enum {
	SEAL         = 0,
	SHRINK       = 1,
	GROW         = 2,
	WRITE        = 3,
	FUTURE_WRITE = 4,
}

RW_Hint :: enum u64  {
	WRITE_LIFE_NOT_SET = 0,
	WRITE_LIFE_NONE    = 1,
	WRITE_LIFE_SHORT   = 2,
	WRITE_LIFE_MEDIUM  = 3,
	WRITE_LIFE_LONG    = 4,
	WRITE_LIFE_EXTREME = 5,
}

FD_Lease :: enum {
	RDLCK = 0,
	WRLCK = 1,
	UNLCK = 2,
}

/*
	Kind of owner for FD_Owner
*/
F_Owner_Type :: enum i32 {
	OWNER_TID  = 0,
	OWNER_PID  = 1,
	OWNER_PGRP = 2,
}

/*
	Command for fcntl(2)
*/
FCntl_Command :: enum {
	DUPFD             = 0,
	GETFD             = 1,
	SETFD             = 2,
	GETFL             = 3,
	SETFL             = 4,
	GETLK             = 5,
	SETLK             = 6,
	SETLKW            = 7,
	SETOWN            = 8,
	GETOWN            = 9,
	SETSIG            = 10,
	GETSIG            = 11,
	SETOWN_EX         = 15,
	GETOWN_EX         = 16,
	// OFD_GETLK         = 36,
	// OFD_SETLK         = 37,
	// OFD_SETLKW        = 38,
	SETLEASE          = 1024,
	GETLEASE          = 1025,
	NOTIFY            = 1026,
	DUPFD_CLOEXEC     = 1030,
	SETPIPE_SZ        = 1031,
	GETPIPE_SZ        = 1032,
	ADD_SEALS         = 1033,
	GET_SEALS         = 1034,
	GET_RW_HINT       = 1035,
	SET_RW_HINT       = 1036,
	GET_FILE_RW_HINT  = 1037,
	SET_FILE_RW_HINT  = 1038,
	// F_OK                = 0,
}

Fd_Poll_Events_Bits :: enum {
	IN     = 0,
	PRI    = 1,
	OUT    = 2,
	ERR    = 3,
	HUP    = 4,
	NVAL   = 5,
	RDNORM = 6,
	RDBAND = 7,
	WRNORM = 8,
	WRBAND = 9,
	MSG    = 10,
	REMOVE = 12,
	RDHUP  = 13,
}

/*
	Bits for Mem_Protection bitfield
*/
Mem_Protection_Bits :: enum{
	READ      = 0,
	WRITE     = 1,
	EXEC      = 2,
	SEM       = 3,
	// platform-specific section start
	ARM64_BTI = 4,
	ARM64_MTE = 5,
	// platform-specific section end
	GROWSDOWN = 24,
	GROWSUP   = 25,
}

/*
	Bits for Map_Flags
*/
Map_Flags_Bits :: enum {
	SHARED          = 0,
	PRIVATE         = 1,
	SHARED_VALIDATE = 2,
	FIXED           = 4,
	ANONYMOUS       = 5,
	// platform-dependent section start
	X86_32BIT       = 6,
	X86_ABOVE4G     = 7,
	// platform-dependent section end
	GROWSDOWN       = 8,
	DENYWRITE       = 11,
	EXECUTABLE      = 12,
	LOCKED          = 13,
	NORESERVE       = 14,
	POPULATE        = 15,
	NONBLOCK        = 16,
	STACK           = 17,
	HUGETLB         = 18,
	SYNC            = 19,
	FIXED_NOREPLACE = 20,
	UNINITIALIZED   = 26,
}

/*
	Bits for MLock_Flags
*/
MLock_Flags_Bits :: enum {
	ONFAULT   = 0,
}

/*
	Bits for MSync_Flags
*/
MSync_Flags_Bits :: enum {
	ASYNC      = 0,
	INVALIDATE = 1,
	SYNC       = 2,
}

/*
	Argument for madvice(2)
*/
MAdvice :: enum {
	NORMAL           = 0,
	RANDOM           = 1,
	SEQUENTIAL       = 2,
	WILLNEED         = 3,
	DONTNEED         = 4,
	FREE             = 8,
	REMOVE           = 9,
	DONTFORK         = 10,
	DOFORK           = 11,
	MERGEABLE        = 12,
	UNMERGEABLE      = 13,
	HUGEPAGE         = 14,
	NOHUGEPAGE       = 15,
	DONTDUMP         = 16,
	DODUMP           = 17,
	WIPEONFORK       = 18,
	KEEPONFORK       = 19,
	COLD             = 20,
	PAGEOUT          = 21,
	POPULATE_READ    = 22,
	POPULATE_WRITE   = 23,
	DONTNEED_LOCKED  = 24,
	COLLAPSE         = 25,
	HWPOISON         = 100,
	SOFT_OFFLINE     = 101,
}

/*
	Bits for PKey_Access_Rights
*/
PKey_Access_Bits :: enum {
	DISABLE_ACCESS = 0,
	DISABLE_WRITE  = 2,
}

/*
	Bits for MRemap_Flags
*/
MRemap_Flags_Bits :: enum {
	MAYMOVE   = 0,
	FIXED     = 1,
	DONTUNMAP = 2,
}

/*
	Bits for Get_Random_Flags
*/
Get_Random_Flags_Bits :: enum {
	RANDOM   = 0,
	NONBLOCK = 1,
	INSECURE = 2,
}

/*
	Bits for Perf_Flags
*/
Perf_Flags_Bits :: enum {
	FD_NO_GROUP = 0,
	FD_OUTPUT   = 1,
	PID_CGROUP  = 2,
	FD_CLOEXEC  = 3,
}

/*
	Union tag for Perf_Event_Attr struct
*/
Perf_Event_Type :: enum u32 {
	HARDWARE   = 0,
	SOFTWARE   = 1,
	TRACEPOINT = 2,
	HW_CACHE   = 3,
	RAW        = 4,
	BREAKPOINT = 5,
}

Perf_Event_Flags_Bits :: enum u64 {
	Disabled       = 0,
	Inherit        = 1,
	Pinned         = 2,
	Exclusive      = 3,
	Exclude_User   = 4,
	Exclude_Kernel = 5,
	Exclude_HV     = 6,
	Exclude_Idle   = 7,
	Mmap           = 8,
	Comm           = 9,
	Freq           = 10,
	Inherit_Stat   = 11,
	Enable_On_Exec = 12,
	Task           = 13,
	Watermark      = 14,
	Precise_IP_0   = 15,
	Precise_IP_1   = 16,
	Mmap_Data      = 17,
	Sample_Id_All  = 18,
	Exclude_Host   = 19,
	Exclude_Guest  = 20,
	Exclude_Callchain_Kernel = 21,
	Exclude_Callchain_User   = 22,
	Mmap2          = 23,
	Comm_Exec      = 24,
	Use_Clockid    = 25,
	Context_Switch = 26,
	Write_Backward = 27,
	Namespaces     = 28,
	KSymbol        = 29,
	BPF_Event      = 30,
	Aux_Output     = 31,
	CGroup         = 32,
	Text_Poke      = 33,
	Build_Id       = 34,
	Inherit_Thread = 35,
	Remove_On_Exec = 36,
	Sigtrap        = 37,
}

Perf_Cap_Flags_Bits :: enum u64 {
	Bit0               = 0,
	Bit0_Is_Deprecated = 1,
	User_Rdpmc         = 2,
	User_Time          = 3,
	User_Time_Zero     = 4,
	User_Time_Short    = 5,
}

/*
	Specifies the type of the hardware event that you want to get info about
*/
Perf_Hardware_Id :: enum u64 {
	CPU_CYCLES              = 0,
	INSTRUCTIONS            = 1,
	CACHE_REFERENCES        = 2,
	CACHE_MISSES            = 3,
	BRANCH_INSTRUCTIONS     = 4,
	BRANCH_MISSES           = 5,
	BUS_CYCLES              = 6,
	STALLED_CYCLES_FRONTEND = 7,
	STALLED_CYCLES_BACKEND  = 8,
	REF_CPU_CYCLES          = 9,
}

/*
	Specifies the cache for the particular cache event that you want to get info about
*/
Perf_Hardware_Cache_Id :: enum u64 {
	L1D      = 0,
	L1I      = 1,
	LL       = 2,
	DTLB     = 3,
	ITLB     = 4,
	BPU      = 5,
	NODE     = 6,
}

/*
	Specifies the cache op that you want to get info about
*/
Perf_Hardware_Cache_Op_Id :: enum u64 {
	READ     = 0,
	WRITE    = 1,
	PREFETCH = 2,
}

/*
	Specifies the cache operation result that you want to get info about
*/
Perf_Hardware_Cache_Result_Id :: enum u64 {
	ACCESS   = 0,
	MISS     = 1,
}

/*
	Specifies the particular software event that you want to get info about
*/
Perf_Software_Id :: enum u64 {
	CPU_CLOCK         = 0,
	TASK_CLOCK        = 1,
	PAGE_FAULTS       = 2,
	CONTEXT_SWITCHES  = 3,
	CPU_MIGRATIONS    = 4,
	PAGE_FAULTS_MIN   = 5,
	PAGE_FAULTS_MAJ   = 6,
	ALIGNMENT_FAULTS  = 7,
	EMULATION_FAULTS  = 8,
	DUMMY             = 9,
	BPF_OUTPUT        = 10,
	CGROUP_SWITCHES   = 11,

}

/*
	Specifies which values to include in the sample
*/
Perf_Event_Sample_Type_Bits :: enum {
	IP              = 0,
	TID             = 1,
	TIME            = 2,
	ADDR            = 3,
	READ            = 4,
	CALLCHAIN       = 5,
	ID              = 6,
	CPU             = 7,
	PERIOD          = 8,
	STREAM_ID       = 9,
	RAW             = 10,
	BRANCH_STACK    = 11,
	REGS_USER       = 12,
	STACK_USER      = 13,
	WEIGHT          = 14,
	DATA_SRC        = 15,
	IDENTIFIER      = 16,
	TRANSACTION     = 17,
	REGS_INTR       = 18,
	PHYS_ADDR       = 19,
	AUX             = 20,
	CGROUP          = 21,
	DATA_PAGE_SIZE  = 22,
	CODE_PAGE_SIZE  = 23,
	WEIGHT_STRUCT   = 24,
}

/// Describes field sets to include in mmaped page
Perf_Read_Format_Bits :: enum {
	TOTAL_TIME_ENABLED = 0,
	TOTAL_TIME_RUNNING = 1,
	ID                 = 2,
	GROUP              = 3,
	LOST               = 4,
}

/*
	Chooses the breakpoint type
*/
Hardware_Breakpoint_Type :: enum u32 {
	EMPTY   = 0,
	R       = 1,
	W       = 2,
	X       = 4,
	RW      = R | W,
	INVALID = RW | X,
}

/*
	Bits for Branch_Sample_Type
*/
Branch_Sample_Type_Bits :: enum {
	USER       = 0,
	KERNEL     = 1,
	HV         = 2,
	ANY        = 3,
	ANY_CALL   = 4,
	ANY_RETURN = 5,
	IND_CALL   = 6,
	ABORT_TX   = 7,
	IN_TX      = 8,
	NO_TX      = 9,
	COND       = 10,
	CALL_STACK = 11,
	IND_JUMP   = 12,
	CALL       = 13,
	NO_FLAGS   = 14,
	NO_CYCLES  = 15,
	TYPE_SAVE  = 16,
	HW_INDEX   = 17,
	PRIV_SAVE  = 18,
}

/*
	Represent the type of Id
*/
Id_Type :: enum uint {
	ALL    = 0,
	PID    = 1,
	PGID   = 2,
	PIDFD  = 3,
}

/*
	Options for wait syscalls
*/
Wait_Option :: enum {
	WNOHANG     = 0,
	WUNTRACED   = 1,
	WSTOPPED    = 1,
	WEXITED     = 2,
	WCONTINUED  = 3,
	WNOWAIT     = 24, 
	// // For processes created using clone
	__WNOTHREAD = 29,
	__WALL      = 30,
	__WCLONE    = 31,
}

/*
	Bits for flags for pidfd
*/
Pid_FD_Flags_Bits :: enum {
	NONBLOCK = 11,
}

/*
	Priority for process, process group, user
*/
Priority_Which :: enum i32 {
	PROCESS = 0,
	PGRP    = 1,
	USER    = 2,
}

Signal :: enum i32 {
	// POSIX-defined signals
	SIGINT      = 2,       // Interactive attention signal.
	SIGILL      = 4,       // Illegal instruction.
	SIGABRT     = 6,       // Abnormal termination.
	SIGFPE      = 8,       // Erroneous arithmetic operation.
	SIGSEGV     = 11,      // Invalid access to storage.
	SIGTERM     = 15,      // Termination request.
	// Other POSIX signals
	SIGHUP      = 1,       // Hangup.
	SIGQUIT     = 3,       // Quit.
	SIGTRAP     = 5,       // Trace/breakpoint trap.
	SIGKILL     = 9,       // Killed.
	SIGPIPE     = 13,      // Broken pipe.
	SIGALRM     = 14,      // Alarm clock.
	// Adjustments needed for most linux systems
	SIGSTKFLT   = 16,      // Stack fault (obsolete).
	SIGPWR      = 30,      // Power failure imminent.
	// Historical signals specified by POSIX.
	SIGBUS      =  7,      // Bus error.
	SIGSYS      = 31,      // Bad system call.
	// New(er) POSIX signals (1003.1-2008, 1003.1-2013).
	SIGURG      = 23,      // Urgent data is available at a socket.
	SIGSTOP     = 19,      // Stop, unblockable.
	SIGTSTP     = 20,      // Keyboard stop.
	SIGCONT     = 18,      // Continue.
	SIGCHLD     = 17,      // Child terminated or stopped.
	SIGTTIN     = 21,      // Background read from control terminal.
	SIGTTOU     = 22,      // Background write to control terminal.
	SIGPOLL     = 29,      // Pollable event occurred (System V).
	SIGXFSZ     = 25,      // File size limit exceeded.
	SIGXCPU     = 24,      // CPU time limit exceeded.
	SIGVTALRM   = 26,      // Virtual timer expired.
	SIGPROF     = 27,      // Profiling timer expired.
	SIGUSR1     = 10,      // User-defined signal 1.
	SIGUSR2     = 12,      // User-defined signal 2.
	// Nonstandard signals found in all modern POSIX systems (including both BSD and Linux).
	SIGWINCH    = 28,      // Window size change (4.3 BSD, Sun).
	// Archaic names for compatibility.
	SIGIO       = SIGPOLL, // I/O now possible (4.2 BSD).
	SIGIOT      = SIGABRT, // IOT instruction, abort() on a PDP-11.
	SIGCLD      = SIGCHLD, // Old System V name
}

Sig_Mask_Kind :: enum i32 {
	SIG_BLOCK   = 0,
	SIG_UNBLOCK = 1,
	SIG_SETMASK = 2,
}

Sig_Stack_Flag :: enum i32 {
	DISABLE = 0,
	ONSTACK = 1,
	AUTODISARM = 31,
}

/*
	Type of socket to create
    - For TCP you want to use SOCK_STREAM
	- For UDP you want to use SOCK_DGRAM
	Also see `Protocol`
*/
Socket_Type :: enum {
	STREAM    = 1,
	DGRAM     = 2,
	RAW       = 3,
	RDM       = 4,
	SEQPACKET = 5,
	DCCP      = 6,
	PACKET    = 10,
}

/*
	Bits for Socket_FD_Flags
*/
Socket_FD_Flags_Bits :: enum {
	NONBLOCK  = 11,
	CLOEXEC   = 19,
}

/*
	Protocol family
*/
Protocol_Family :: enum u16 {
	UNSPEC       = 0,
	LOCAL        = 1,
	UNIX         = LOCAL,
	FILE         = LOCAL,
	INET         = 2,
	AX25         = 3,
	IPX          = 4,
	APPLETALK    = 5,
	NETROM       = 6,
	BRIDGE       = 7,
	ATMPVC       = 8,
	X25          = 9,
	INET6        = 10,
	ROSE         = 11,
	DECnet       = 12,
	NETBEUI      = 13,
	SECURITY     = 14,
	KEY          = 15,
	NETLINK      = 16,
	ROUTE        = NETLINK,
	PACKET       = 17,
	ASH          = 18,
	ECONET       = 19,
	ATMSVC       = 20,
	RDS          = 21,
	SNA          = 22,
	IRDA         = 23,
	PPPOX        = 24,
	WANPIPE      = 25,
	LLC          = 26,
	IB           = 27,
	MPLS         = 28,
	CAN          = 29,
	TIPC         = 30,
	BLUETOOTH    = 31,
	IUCV         = 32,
	RXRPC        = 33,
	ISDN         = 34,
	PHONET       = 35,
	IEEE802154   = 36,
	CAIF         = 37,
	ALG          = 38,
	NFC          = 39,
	VSOCK        = 40,
	KCM          = 41,
	QIPCRTR      = 42,
	SMC          = 43,
	XDP          = 44,
	MCTP         = 45,
}

/*
	The protocol number according to IANA protocol number list
	Full list of protocol numbers:
	  https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
	Supported by the OS protocols can be queried by reading:
	  /etc/protocols
*/
Protocol :: enum {
	HOPOPT          = 0,
	ICMP            = 1,
	IGMP            = 2,
	GGP             = 3,
	IPv4            = 4,
	ST              = 5,
	TCP             = 6,
	CBT             = 7,
	EGP             = 8,
	IGP             = 9,
	BBN_RCC_MON     = 10,
	NVP_II          = 11,
	PUP             = 12,
	EMCON           = 14,
	XNET            = 15,
	CHAOS           = 16,
	UDP             = 17,
	MUX             = 18,
	DCN_MEAS        = 19,
	HMP             = 20,
	PRM             = 21,
	XNS_IDP         = 22,
	TRUNK_1         = 23,
	TRUNK_2         = 24,
	LEAF_1          = 25,
	LEAF_2          = 26,
	RDP             = 27,
	IRTP            = 28,
	ISO_TP4         = 29,
	NETBLT          = 30,
	MFE_NSP         = 31,
	MERIT_INP       = 32,
	DCCP            = 33,
	THREE_PC        = 34,
	IDPR            = 35,
	XTP             = 36,
	DDP             = 37,
	IDPR_CMTP       = 38,
	TP_PlusPlus     = 39,
	IL              = 40,
	IPv6            = 41,
	SDRP            = 42,
	IPv6_Route      = 43,
	IPv6_Frag       = 44,
	IDRP            = 45,
	RSVP            = 46,
	GRE             = 47,
	DSR             = 48,
	BNA             = 49,
	ESP             = 50,
	AH              = 51,
	I_NLSP          = 52,
	NARP            = 54,
	MOBILE          = 55,
	TLSP            = 56,
	SKIP            = 57,
	IPv6_ICMP       = 58,
	IPv6_NoNxt      = 59,
	IPv6_Opts       = 60,
	CFTP            = 62,
	SAT_EXPAK       = 64,
	KRYPTOLAN       = 65,
	RVD             = 66,
	IPPC            = 67,
	SAT_MON         = 69,
	VISA            = 70,
	IPCV            = 71,
	CPNX            = 72,
	CPHB            = 73,
	WSN             = 74,
	PVP             = 75,
	BR_SAT_MON      = 76,
	SUN_ND          = 77,
	WB_MON          = 78,
	WB_EXPAK        = 79,
	ISO_IP          = 80,
	VMTP            = 81,
	SECURE_VMTP     = 82,
	VINES           = 83,
	IPTM            = 84,
	NSFNET_IGP      = 85,
	DGP             = 86,
	TCF             = 87,
	EIGRP           = 88,
	OSPFIGP         = 89,
	Sprite_RPC      = 90,
	LARP            = 91,
	MTP             = 92,
	AX_25           = 93,
	IPIP            = 94,
	SCC_SP          = 96,
	ETHERIP         = 97,
	ENCAP           = 98,
	GMTP            = 100,
	IFMP            = 101,
	PNNI            = 102,
	PIM             = 103,
	ARIS            = 104,
	SCPS            = 105,
	QNX             = 106,
	A_N             = 107,
	IPComp          = 108,
	SNP             = 109,
	Compaq_Peer     = 110,
	IPX_in_IP       = 111,
	VRRP            = 112,
	PGM             = 113,
	L2TP            = 115,
	DDX             = 116,
	IATP            = 117,
	STP             = 118,
	SRP             = 119,
	UTI             = 120,
	SMP             = 121,
	PTP             = 123,
	FIRE            = 125,
	CRTP            = 126,
	CRUDP           = 127,
	SSCOPMCE        = 128,
	IPLT            = 129,
	SPS             = 130,
	PIPE            = 131,
	SCTP            = 132,
	FC              = 133,
	RSVP_E2E_IGNORE = 134,
	UDPLite         = 136,
	MPLS_in_IP      = 137,
	manet           = 138,
	HIP             = 139,
	Shim6           = 140,
	WESP            = 141,
	ROHC            = 142,
	Ethernet        = 143,
	AGGFRAG         = 144,
	NSH             = 145,
	Reserved        = 255,
}

/*
	API Level for getsockopt(2)/setsockopt(2)
*/
Socket_API_Level :: enum {
	// Comes from <bits/socket-constants.h>
	SOCKET          = 1,
	// Copy-pasted from protocol numbers
	TCP             = 6,
	UDP             = 17,
	// Comes from <bits/socket.h>
	RAW             = 255,
	DECNET          = 261,
	X25             = 262,
	PACKET          = 263,
	ATM             = 264,
	AAL             = 265,
	IRDA            = 266,
	NETBEUI         = 267,
	LLC             = 268,
	DCCP            = 269,
	NETLINK         = 270,
	TIPC            = 271,
	RXRPC           = 272,
	PPPOL2TP        = 273,
	BLUETOOTH       = 274,
	PNPIPE          = 275,
	RDS             = 276,
	IUCV            = 277,
	CAIF            = 278,
	ALG             = 279,
	NFC             = 280,
	KCM             = 281,
	TLS             = 282,
	XDP             = 283,
	MPTCP           = 284,
	MCTP            = 285,
	SMC             = 286,
}

/*
	If Socket_API_Level == .SOCKET, these are the options
	you can specify in getsockopt(2)/setsockopt(2)
*/
Socket_Option :: enum {
	DEBUG                         = 1,
	REUSEADDR                     = 2,
	TYPE                          = 3,
	ERROR                         = 4,
	DONTROUTE                     = 5,
	BROADCAST                     = 6,
	SNDBUF                        = 7,
	RCVBUF                        = 8,
	SNDBUFFORCE                   = 32,
	RCVBUFFORCE                   = 33,
	KEEPALIVE                     = 9,
	OOBINLINE                     = 10,
	NO_CHECK                      = 11,
	PRIORITY                      = 12,
	LINGER                        = 13,
	BSDCOMPAT                     = 14,
	REUSEPORT                     = 15,
	PASSCRED                      = 16,
	PEERCRED                      = 17,
	RCVLOWAT                      = 18,
	SNDLOWAT                      = 19,
	RCVTIMEO_OLD                  = 20,
	SNDTIMEO_OLD                  = 21,
	SECURITY_AUTHENTICATION       = 22,
	SECURITY_ENCRYPTION_TRANSPORT = 23,
	SECURITY_ENCRYPTION_NETWORK   = 24,
	BINDTODEVICE                  = 25,
	ATTACH_FILTER                 = 26,
	DETACH_FILTER                 = 27,
	GET_FILTER                    = ATTACH_FILTER,
	PEERNAME                      = 28,
	ACCEPTCONN                    = 30,
	PEERSEC                       = 31,
	PASSSEC                       = 34,
	MARK                          = 36,
	PROTOCOL                      = 38,
	DOMAIN                        = 39,
	RXQ_OVFL                      = 40,
	WIFI_STATUS                   = 41,
	PEEK_OFF                      = 42,
	NOFCS                         = 43,
	LOCK_FILTER                   = 44,
	SELECT_ERR_QUEUE              = 45,
	BUSY_POLL                     = 46,
	MAX_PACING_RATE               = 47,
	BPF_EXTENSIONS                = 48,
	INCOMING_CPU                  = 49,
	ATTACH_BPF                    = 50,
	DETACH_BPF                    = DETACH_FILTER,
	ATTACH_REUSEPORT_CBPF         = 51,
	ATTACH_REUSEPORT_EBPF         = 52,
	CNX_ADVICE                    = 53,
	TIMESTAMPING_OPT_STATS        = 54,
	MEMINFO                       = 55,
	INCOMING_NAPI_ID              = 56,
	COOKIE                        = 57,
	TIMESTAMPING_PKTINFO          = 58,
	PEERGROUPS                    = 59,
	ZEROCOPY                      = 60,
	TXTIME                        = 61,
	BINDTOIFINDEX                 = 62,
	TIMESTAMP_OLD                 = 29,
	TIMESTAMPNS_OLD               = 35,
	TIMESTAMPING_OLD              = 37,
	TIMESTAMP_NEW                 = 63,
	TIMESTAMPNS_NEW               = 64,
	TIMESTAMPING_NEW              = 65,
	RCVTIMEO_NEW                  = 66,
	SNDTIMEO_NEW                  = 67,
	DETACH_REUSEPORT_BPF          = 68,
	PREFER_BUSY_POLL              = 69,
	BUSY_POLL_BUDGET              = 70,
	NETNS_COOKIE                  = 71,
	BUF_LOCK                      = 72,
	RESERVE_MEM                   = 73,
	TXREHASH                      = 74,
	RCVMARK                       = 75,
	// Hardcoded 64-bit Time. It's time to move on.
	TIMESTAMP                     = TIMESTAMP_NEW,
	TIMESTAMPNS                   = TIMESTAMPNS_NEW,
	TIMESTAMPING                  = TIMESTAMPING_NEW,
	RCVTIMEO                      = RCVTIMEO_NEW,
	SNDTIMEO                      = SNDTIMEO_NEW,
}

Socket_UDP_Option :: enum {
	CORK                   = 1,
	ENCAP                  = 100,
	NO_CHECK6_TX           = 101,
	NO_CHECK6_RX           = 102,
	SEGMENT                = 103,
	GRO                    = 104,
}

UPD_Encapsulation :: enum {
	ENCAP_ESPINUDP_NON_IKE = 1,
	ENCAP_ESPINUDP         = 2,
	ENCAP_L2TPINUDP        = 3,
	ENCAP_GTP0             = 4,
	ENCAP_GTP1U            = 5,
}

Socket_TCP_Option :: enum {
	NODELAY              = 1,
	MAXSEG               = 2,
	CORK                 = 3,
	KEEPIDLE             = 4,
	KEEPINTVL            = 5,
	KEEPCNT              = 6,
	SYNCNT               = 7,
	LINGER2              = 8,
	DEFER_ACCEPT         = 9,
	WINDOW_CLAMP         = 10,
	INFO                 = 11,
	QUICKACK             = 12,
	CONGESTION           = 13,
	MD5SIG               = 14,
	COOKIE_TRANSACTIONS  = 15,
	THIN_LINEAR_TIMEOUTS = 16,
	THIN_DUPACK          = 17,
	USER_TIMEOUT         = 18,
	REPAIR               = 19,
	REPAIR_QUEUE         = 20,
	QUEUE_SEQ            = 21,
	REPAIR_OPTIONS       = 22,
	FASTOPEN             = 23,
	TIMESTAMP            = 24,
	NOTSENT_LOWAT        = 25,
	CC_INFO              = 26,
	SAVE_SYN             = 27,
	SAVED_SYN            = 28,
	REPAIR_WINDOW        = 29,
	FASTOPEN_CONNECT     = 30,
	ULP                  = 31,
	MD5SIG_EXT           = 32,
	FASTOPEN_KEY         = 33,
	FASTOPEN_NO_COOKIE   = 34,
	ZEROCOPY_RECEIVE     = 35,
	INQ                  = 36,
	CM_INQ               = INQ,
	TX_DELAY             = 37,
}

/*
	Bits for Socket_Msg
*/
Socket_Msg_Bits :: enum {
	OOB             = 0,
	PEEK            = 1,
	DONTROUTE       = 2,
	TRYHARD         = DONTROUTE,
	CTRUNC          = 3,
	PROXY           = 4,
	TRUNC           = 5,
	DONTWAIT        = 6,
	EOR             = 7,
	WAITALL         = 8,
	FIN             = 9,
	SYN             = 10,
	CONFIRM         = 11,
	RST             = 12,
	ERRQUEUE        = 13,
	NOSIGNAL        = 14,
	MORE            = 15,
	WAITFORONE      = 16,
	BATCH           = 18,
	ZEROCOPY        = 22,
	FASTOPEN        = 29,
	CMSG_CLOEXEC    = 30,
}

/*
	Argument to shutdown(2)
*/
Shutdown_How :: enum i32 {
	RD   = 0,
	WR   = 1,
	RDWR = 2,
}

/*
	Second argument to futex(2) syscall
*/
Futex_Op :: enum u32 {
	WAIT              = 0,
	WAKE              = 1,
	FD                = 2,
	REQUEUE           = 3,
	CMP_REQUEUE       = 4,
	WAKE_OP           = 5,
	LOCK_PI           = 6,
	UNLOCK_PI         = 7,
	TRYLOCK_PI        = 8,
	WAIT_BITSET       = 9,
	WAKE_BITSET       = 10,
	WAIT_REQUEUE_PI   = 11,
	CMP_REQUEUE_PI    = 12,
	LOCK_PI2          = 13,
}

/*
	Bits for Futex_Flags
*/
Futex_Flags_Bits :: enum {
	PRIVATE    = 7,
	REALTIME   = 8,
}

/*
	Kind of operation on futex, see FUTEX_WAKE_OP
*/
Futex_Arg_Op :: enum {
	SET      = 0,  /* uaddr2 =       oparg; */
	ADD      = 1,  /* uaddr2 +=      oparg; */
	OR       = 2,  /* uaddr2 |=      oparg; */
	ANDN     = 3,  /* uaddr2 &=     ~oparg; */
	XOR      = 4,  /* uaddr2 ^=      oparg; */
	PO2_SET  = 0,  /* uaddr2 =    1<<oparg; */
	PO2_ADD  = 1,  /* uaddr2 +=   1<<oparg; */
	PO2_OR   = 2,  /* uaddr2 |=   1<<oparg; */
	PO2_ANDN = 3,  /* uaddr2 &= ~(1<<oparg); */
	PO2_XOR  = 4,  /* uaddr2 ^=   1<<oparg; */
}

/*
	Kind of comparison operation on futex, see FUTEX_WAKE_OP
*/
Futex_Cmp_Op :: enum {
	EQ = 0,  /* if (oldval == cmparg) wake */
	NE = 1,  /* if (oldval != cmparg) wake */
	LT = 2,  /* if (oldval < cmparg) wake */
	LE = 3,  /* if (oldval <= cmparg) wake */
	GT = 4,  /* if (oldval > cmparg) wake */
	GE = 5,  /* if (oldval >= cmparg) wake */
}

/*
	The kind of resource limits
*/
RLimit_Kind :: enum i32 {
	CPU        = 0,
	FSIZE      = 1,
	DATA       = 2,
	STACK      = 3,
	CORE       = 4,
	RSS        = 5,
	NOFILE     = 7,
	AS         = 9,
	NPROC      = 6,
	MEMLOCK    = 8,
	LOCKS      = 10,
	SIGPENDING = 11,
	MSGQUEUE   = 12,
	NICE       = 13,
	RTPRIO     = 14,
	RTTIME     = 15,
	NLIMITS    = 16,
}

/*
	Represents the user of resources
*/
RUsage_Who :: enum i32 {
	CHILDREN = -1,
	SELF     =  0,
	THREAD   =  1,
	LWP      =  THREAD,
}

/*
	Bits for Personality_Flags
*/
UNAME26            :: 17
ADDR_NO_RANDOMIZE  :: 18
FDPIC_FUNCPTRS     :: 19
MMAP_PAGE_ZERO     :: 20
ADDR_COMPAT_LAYOUT :: 21
READ_IMPLIES_EXEC  :: 22
ADDR_LIMIT_32BIT   :: 23
SHORT_INODE        :: 24
WHOLE_SECONDS      :: 25
STICKY_TIMEOUTS    :: 26
ADDR_LIMIT_3GB     :: 27

/*
	Personality type
	These go into the bottom 8 bits of the personality value
*/
PER_LINUX       :: 0x0000
PER_LINUX_32BIT :: 0x0000 | ADDR_LIMIT_32BIT
PER_LINUX_FDPIC :: 0x0000 | FDPIC_FUNCPTRS
PER_SVR4        :: 0x0001 | STICKY_TIMEOUTS | MMAP_PAGE_ZERO
PER_SVR3        :: 0x0002 | STICKY_TIMEOUTS | SHORT_INODE
PER_SCOSVR3     :: 0x0003 | STICKY_TIMEOUTS | WHOLE_SECONDS | SHORT_INODE
PER_OSR5        :: 0x0003 | STICKY_TIMEOUTS | WHOLE_SECONDS
PER_WYSEV386    :: 0x0004 | STICKY_TIMEOUTS | SHORT_INODE
PER_ISCR4       :: 0x0005 | STICKY_TIMEOUTS
PER_BSD         :: 0x0006
PER_SUNOS       :: 0x0006 | STICKY_TIMEOUTS
PER_XENIX       :: 0x0007 | STICKY_TIMEOUTS | SHORT_INODE
PER_LINUX32     :: 0x0008
PER_LINUX32_3GB :: 0x0008 | ADDR_LIMIT_3GB
PER_IRIX32      :: 0x0009 | STICKY_TIMEOUTS
PER_IRIXN32     :: 0x000a | STICKY_TIMEOUTS
PER_IRIX64      :: 0x000b | STICKY_TIMEOUTS
PER_RISCOS      :: 0x000c
PER_SOLARIS     :: 0x000d | STICKY_TIMEOUTS
PER_UW7         :: 0x000e | STICKY_TIMEOUTS | MMAP_PAGE_ZERO
PER_OSF4        :: 0x000f
PER_HPUX        :: 0x0010
PER_MASK        :: 0x00ff

/*
	Bits for access modes for shared memory
*/
IPC_Mode_Bits :: enum {
	WROTH  = 1,
	RDOTH  = 2,
	WRGRP  = 4,
	RDGRP  = 5,
	WRUSR  = 7,
	RDUSR  = 8,
	DEST   = 9,
	LOCKED = 10,
}

/*
	Shared memory flags bits
*/
IPC_Flags_Bits :: enum {
	IPC_CREAT     = 9,
	IPC_EXCL      = 10,
	IPC_NOWAIT    = 11,
	// Semaphore
	SEM_UNDO      = 9,
	// Shared memory
	SHM_HUGETLB   = 11,
	SHM_NORESERVE = 12,
	SHM_RDONLY    = 12,
	SHM_RND       = 13,
	SHM_REMAP     = 14,
	SHM_EXEC      = 15,
	// Message queue
	MSG_NOERROR   = 12,
	MSG_EXCEPT    = 13,
	MSG_COPY      = 14,
}

/*
	IPC memory commands
*/
IPC_Cmd :: enum i16 {
	// IPC common
	IPC_RMID     = 0,
	IPC_SET      = 1,
	IPC_STAT     = 2,
	// Shared memory
	SHM_LOCK     = 11,
	SHM_UNLOCK   = 12,
	SHM_STAT     = 13,
	SHM_INFO     = 14,
	SHM_STAT_ANY = 15,
	// Semaphore
	GETPID       = 11,
	GETVAL       = 12,
	GETALL       = 13,
	GETNCNT      = 14,
	GETZCNT      = 15,
	SETVAL       = 16,
	SETALL       = 17,
	SEM_STAT     = 18,
	SEM_INFO     = 19,
	SEM_STAT_ANY = 20,
	// Message queue
	MSG_STAT     = 11,
	MSG_INFO     = 12,
	MSG_STAT_ANY = 13,
}

/*
	File locking operation bits
*/
FLock_Op_Bits :: enum {
	SH = 1,
	EX = 2,
	NB = 4,
	UN = 8,
}

/*
	ptrace requests
*/
PTrace_Request :: enum {
	TRACEME                = 0,
	PEEKTEXT               = 1,
	PEEKDATA               = 2,
	PEEKUSER               = 3,
	POKETEXT               = 4,
	POKEDATA               = 5,
	POKEUSER               = 6,
	CONT                   = 7,
	KILL                   = 8,
	SINGLESTEP             = 9,
	GETREGS                = 12,
	SETREGS                = 13,
	GETFPREGS              = 14,
	SETFPREGS              = 15,
	ATTACH                 = 16,
	DETACH                 = 17,
	GETFPXREGS             = 18,
	SETFPXREGS             = 19,
	SYSCALL                = 24,
	GET_THREAD_AREA        = 25,
	SET_THREAD_AREA        = 26,
	ARCH_PRCTL             = 30,
	SYSEMU                 = 31,
	SYSEMU_SINGLESTEP      = 32,
	SINGLEBLOCK            = 33,
	SETOPTIONS             = 0x4200,
	GETEVENTMSG            = 0x4201,
	GETSIGINFO             = 0x4202,
	SETSIGINFO             = 0x4203,
	GETREGSET              = 0x4204,
	SETREGSET              = 0x4205,
	SEIZE                  = 0x4206,
	INTERRUPT              = 0x4207,
	LISTEN                 = 0x4208,
	PEEKSIGINFO            = 0x4209,
	GETSIGMASK             = 0x420a,
	SETSIGMASK             = 0x420b,
	SECCOMP_GET_FILTER     = 0x420c,
	SECCOMP_GET_METADATA   = 0x420d,
	GET_SYSCALL_INFO       = 0x420e,
	GET_RSEQ_CONFIGURATION = 0x420f,
}

/*
	ptrace options
*/
PTrace_Options_Bits :: enum {
	TRACESYSGOOD    = 0,
	TRACEFORK       = 1,
	TRACEVFORK      = 2,
	TRACECLONE      = 3,
	TRACEEXEC       = 4,
	TRACEVFORKDONE  = 5,
	TRACEEXIT       = 6,
	TRACESECCOMP    = 7,
	EXITKILL        = 20,
	SUSPEND_SECCOMP = 21,
}

/*
	ptrace event codes.
*/
PTrace_Event_Code :: enum {
	EVENT_FORK       = 1,
	EVENT_VFORK      = 2,
	EVENT_CLONE      = 3,
	EVENT_EXEC       = 4,
	EVENT_VFORK_DONE = 5,
	EVENT_EXIT       = 6,
	EVENT_SECCOMP    = 7,
	EVENT_STOP       = 128,
}

/*
	ptrace's get syscall info operation.
*/
PTrace_Get_Syscall_Info_Op :: enum u8 {
	NONE    = 0,
	ENTRY   = 1,
	EXIT    = 2,
	SECCOMP = 3,
}

/*
	ptrace's PEEKSIGINFO flags bits
*/
PTrace_Peek_Sig_Info_Flags_Bits :: enum {
	SHARED = 0,
}

/*
	Syslog actions.
*/
Syslog_Action :: enum i32 {
	CLOSE         = 0,
	OPEN          = 1,
	READ          = 2,
	READ_ALL      = 3,
	READ_CLEAR    = 4,
	CLEAR         = 5,
	CONSOLE_OFF   = 6,
	CONSOLE_ON    = 7,
	CONSOLE_LEVEL = 8,
	SIZE_UNREAD   = 9,
	SIZE_BUFFER   = 10,
}

/*
	Bits for splice flags.
*/
Splice_Flags_Bits :: enum {
	MOVE     = 0x01,
	NONBLOCK = 0x02,
	MORE     = 0x04,
	GIFT     = 0x08,
}

/*
	Clock IDs for various system clocks.
*/
Clock_Id :: enum {
	REALTIME           = 0,
	MONOTONIC          = 1,
	PROCESS_CPUTIME_ID = 2,
	THREAD_CPUTIME_ID  = 3,
	MONOTONIC_RAW      = 4,
	REALTIME_COARSE    = 5,
	MONOTONIC_COARSE   = 6,
	BOOTTIME           = 7,
	REALTIME_ALARM     = 8,
	BOOTTIME_ALARM     = 9,
}

/*
	Bits for POSIX interval timer flags.
*/
ITimer_Flags_Bits :: enum {
	ABSTIME = 1,
}

/*
	Bits for epoll_create(2) flags.
*/
EPoll_Flags_Bits :: enum {
	FDCLOEXEC = 19,
}

EPoll_Event_Kind :: enum u32 {
	IN        = 0x001,
	PRI       = 0x002,
	OUT       = 0x004,
	RDNORM    = 0x040,
	RDBAND    = 0x080,
	WRNORM    = 0x100,
	WRBAND    = 0x200,
	MSG       = 0x400,
	ERR       = 0x008,
	HUP       = 0x010,
	RDHUP     = 0x2000,
	EXCLUSIVE = 1<<28,
	WAKEUP    = 1<<29,
	ONESHOT   = 1<<30,
	ET        = 1<<31,
}

EPoll_Ctl_Opcode :: enum i32 {
	ADD = 1,
	DEL = 2,
	MOD = 3,
}
