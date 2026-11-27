package linux

/*
	Standard input file descriptor
*/
STDIN_FILENO :: Fd(0)

/*
	Standard output file descriptor
*/
STDOUT_FILENO :: Fd(1)

/*
	Standard error file descriptor
*/
STDERR_FILENO :: Fd(2)

/*
	Special file descriptor to pass to `*at` functions to specify
	that relative paths are relative to current directory.
*/
AT_FDCWD :: Fd(-100)

/*
	Special value to put into timespec for utimensat() to set timestamp to the current time.
*/
UTIME_NOW  :: uint((1 << 30) - 1)

/*
	Special value to put into the timespec for utimensat() to leave the corresponding field of the timestamp unchanged.
*/
UTIME_OMIT :: uint((1 << 30) - 2)

/*
	For wait4: Pass this pid to wait for any process.
*/
WAIT_ANY    :: Pid(-1)

/*
	For wait4: Pass this pid to wait for any process in current process group.
*/
WAIT_MYPGRP :: Pid(0)

/*
	Maximum priority (aka nice value) for the process.
*/
PRIO_MAX :: 20

/*
	Minimum priority (aka nice value) for the process.
*/
PRIO_MIN :: -20

SIGRTMIN :: Signal(32)
SIGRTMAX :: Signal(64)

_NSIG :: 65

S_IFMT   :: Mode{.IFREG, .IFDIR, .IFCHR, .IFIFO}
S_IFSOCK :: Mode{.IFREG, .IFDIR}
S_IFLNK  :: Mode{.IFREG, .IFCHR}
S_IFBLK  :: Mode{.IFDIR, .IFCHR}
S_IFIFO  :: Mode{.IFIFO}
S_IFCHR  :: Mode{.IFCHR}
S_IFDIR  :: Mode{.IFDIR}
S_IFREG  :: Mode{.IFREG}

/*
	Checks the Mode bits to see if the file is a named pipe (FIFO).
*/
S_ISFIFO :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFIFO  == (m & S_IFMT))}

/*
	Check the Mode bits to see if the file is a character device.
*/
S_ISCHR  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFCHR  == (m & S_IFMT))}

/*	
	Check the Mode bits to see if the file is a directory.
*/
S_ISDIR  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFDIR  == (m & S_IFMT))}

/*
	Check the Mode bits to see if the file is a register.
*/
S_ISREG  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFREG  == (m & S_IFMT))}

/*
	Check the Mode bits to see if the file is a socket.
*/
S_ISSOCK :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFSOCK == (m & S_IFMT))}

/*
	Check the Mode bits to see if the file is a symlink.
*/
S_ISLNK  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFLNK  == (m & S_IFMT))}

/*
	Check the Mode bits to see if the file is a block device.
*/
S_ISBLK  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFBLK  == (m & S_IFMT))}

/*
	For access.2 syscall family: instruct to check if the file exists.
*/
F_OK :: Mode{}

/*
	For access.2 syscall family: instruct to check if the file is executable.
*/
X_OK :: Mode{.IXOTH}

/*
	For access.2 syscall family: instruct to check if the file is writeable.
*/
W_OK :: Mode{.IWOTH}

/*
	For access.2 syscall family: instruct to check if the file is readable.
*/
R_OK :: Mode{.IROTH}

/*
	The stats you get by calling `stat`.
*/
STATX_BASIC_STATS :: Statx_Mask {
	.TYPE,
	.MODE,
	.NLINK,
	.UID,
	.GID,
	.ATIME,
	.MTIME,
	.CTIME,
	.INO,
	.SIZE,
	.BLOCKS,
}

IN_ALL_EVENTS	:: Inotify_Event_Mask {
	.ACCESS,
	.MODIFY,
	.ATTRIB,
	.CLOSE_WRITE,
	.CLOSE_NOWRITE,
	.OPEN,
	.MOVED_FROM,
	.MOVED_TO,
	.CREATE,
	.DELETE,
	.DELETE_SELF,
	.MOVE_SELF,
}

IN_CLOSE :: Inotify_Event_Mask {
	.CLOSE_WRITE,
	.CLOSE_NOWRITE,
}

IN_MOVE :: Inotify_Event_Mask {
	.MOVED_FROM,
	.MOVED_TO,
}

/*
	Tell `shmget` to create a new key
*/
IPC_PRIVATE :: Key(0)

FCntl_Command_DUPFD            :: distinct FCntl_Command
FCntl_Command_GETFD            :: distinct FCntl_Command
FCntl_Command_SETFD            :: distinct FCntl_Command
FCntl_Command_GETFL            :: distinct FCntl_Command
FCntl_Command_SETFL            :: distinct FCntl_Command
FCntl_Command_GETLK            :: distinct FCntl_Command
FCntl_Command_SETLK            :: distinct FCntl_Command
FCntl_Command_SETLKW           :: distinct FCntl_Command
FCntl_Command_DUPFD_CLOEXEC    :: distinct FCntl_Command
FCntl_Command_SETOWN           :: distinct FCntl_Command
FCntl_Command_GETOWN           :: distinct FCntl_Command
FCntl_Command_SETSIG           :: distinct FCntl_Command
FCntl_Command_GETSIG           :: distinct FCntl_Command
FCntl_Command_SETOWN_EX        :: distinct FCntl_Command
FCntl_Command_GETOWN_EX        :: distinct FCntl_Command
FCntl_Command_SETLEASE         :: distinct FCntl_Command
FCntl_Command_GETLEASE         :: distinct FCntl_Command
FCntl_Command_NOTIFY           :: distinct FCntl_Command
FCntl_Command_SETPIPE_SZ       :: distinct FCntl_Command
FCntl_Command_GETPIPE_SZ       :: distinct FCntl_Command
FCntl_Command_ADD_SEALS        :: distinct FCntl_Command
FCntl_Command_GET_SEALS        :: distinct FCntl_Command
FCntl_Command_GET_RW_HINT      :: distinct FCntl_Command
FCntl_Command_SET_RW_HINT      :: distinct FCntl_Command
FCntl_Command_GET_FILE_RW_HINT :: distinct FCntl_Command
FCntl_Command_SET_FILE_RW_HINT :: distinct FCntl_Command
F_DUPFD            :: FCntl_Command_DUPFD(.DUPFD)
F_GETFD            :: FCntl_Command_GETFD(.GETFD)
F_SETFD            :: FCntl_Command_SETFD(.SETFD)
F_GETFL            :: FCntl_Command_GETFL(.GETFL)
F_SETFL            :: FCntl_Command_SETFL(.SETFL)
// F_GETLK64          :: FCntl_Command_GETLK64(.GETLK64)
// F_SETLK64          :: FCntl_Command_SETLK64(.SETLK64)
// F_SETLKW64         :: FCntl_Command_SETLKW64(.SETLKW64)
F_GETLK            :: FCntl_Command_GETLK(.GETLK)
F_SETLK            :: FCntl_Command_SETLK(.SETLK)
F_SETLKW           :: FCntl_Command_SETLKW(.SETLKW)
F_DUPFD_CLOEXEC    :: FCntl_Command_DUPFD_CLOEXEC(.DUPFD_CLOEXEC)
F_SETOWN           :: FCntl_Command_SETOWN(.SETOWN)
F_GETOWN           :: FCntl_Command_GETOWN(.GETOWN)
F_SETSIG           :: FCntl_Command_SETSIG(.SETSIG)
F_GETSIG           :: FCntl_Command_GETSIG(.GETSIG)
F_SETOWN_EX        :: FCntl_Command_SETOWN_EX(.SETOWN_EX)
F_GETOWN_EX        :: FCntl_Command_GETOWN_EX(.GETOWN_EX)
F_SETLEASE         :: FCntl_Command_SETLEASE(.SETLEASE)
F_GETLEASE         :: FCntl_Command_GETLEASE(.GETLEASE)
F_NOTIFY           :: FCntl_Command_NOTIFY(.NOTIFY)
F_SETPIPE_SZ       :: FCntl_Command_SETPIPE_SZ(.SETPIPE_SZ)
F_GETPIPE_SZ       :: FCntl_Command_GETPIPE_SZ(.GETPIPE_SZ)
F_ADD_SEALS        :: FCntl_Command_ADD_SEALS(.ADD_SEALS)
F_GET_SEALS        :: FCntl_Command_GET_SEALS(.GET_SEALS)
F_GET_RW_HINT      :: FCntl_Command_GET_RW_HINT(.GET_RW_HINT)
F_SET_RW_HINT      :: FCntl_Command_SET_RW_HINT(.SET_RW_HINT)
F_GET_FILE_RW_HINT :: FCntl_Command_GET_FILE_RW_HINT(.GET_FILE_RW_HINT)
F_SET_FILE_RW_HINT :: FCntl_Command_SET_FILE_RW_HINT(.SET_FILE_RW_HINT)

Socket_API_Level_Sock :: distinct Socket_API_Level
Socket_API_Level_TCP  :: distinct Socket_API_Level
Socket_API_Level_UDP  :: distinct Socket_API_Level
Socket_API_Level_Raw  :: distinct Socket_API_Level

SOL_SOCKET :: Socket_API_Level_Sock(.SOCKET)
SOL_TCP    :: Socket_API_Level_TCP(.TCP)
SOL_UDP    :: Socket_API_Level_UDP(.UDP)
SOL_RAW    :: Socket_API_Level_Raw(.RAW)

Futex_Wait_Type            :: distinct Futex_Op
Futex_Wake_Type            :: distinct Futex_Op
Futex_Fd_Type              :: distinct Futex_Op
Futex_Requeue_Type         :: distinct Futex_Op
Futex_Cmp_Requeue_Type     :: distinct Futex_Op
Futex_Wake_Op_Type         :: distinct Futex_Op
Futex_Lock_Pi_Type         :: distinct Futex_Op
Futex_Unlock_Pi_Type       :: distinct Futex_Op
Futex_Trylock_Pi_Type      :: distinct Futex_Op
Futex_Wait_Bitset_Type     :: distinct Futex_Op
Futex_Wake_Bitset_Type     :: distinct Futex_Op
Futex_Wait_requeue_Pi_Type :: distinct Futex_Op
Futex_Cmp_requeue_Pi_Type  :: distinct Futex_Op
Futex_Lock_Pi2_Type        :: distinct Futex_Op

/*
	Wait on futex wakeup signal.
*/
FUTEX_WAIT            :: Futex_Wait_Type(.WAIT)

/*
	Wake up other processes waiting on the futex.
*/
FUTEX_WAKE            :: Futex_Wake_Type(.WAKE)

/*
	Not implemented. Basically, since.
*/
FUTEX_FD              :: Futex_Fd_Type(.FD)

/*
	Requeue waiters from one futex to another.
*/
FUTEX_REQUEUE         :: Futex_Requeue_Type(.REQUEUE)

/*
	Requeue waiters from one futex to another if the value at mutex matches.
*/
FUTEX_CMP_REQUEUE     :: Futex_Cmp_Requeue_Type(.CMP_REQUEUE)

/*
	See man pages, I'm not describing it here.
*/
FUTEX_WAKE_OP         :: Futex_Wake_Op_Type(.WAKE_OP)

/*
	Wait on a futex, but the value is a bitset.
*/
FUTEX_WAIT_BITSET     :: Futex_Wait_Bitset_Type(.WAIT_BITSET)

/*
	Wait on a futex, but the value is a bitset.
*/
FUTEX_WAKE_BITSET     :: Futex_Wake_Bitset_Type(.WAKE_BITSET)

// TODO(flysand): Priority inversion futexes
FUTEX_LOCK_PI         :: Futex_Lock_Pi_Type(.LOCK_PI)
FUTEX_UNLOCK_PI       :: Futex_Unlock_Pi_Type(.UNLOCK_PI)
FUTEX_TRYLOCK_PI      :: Futex_Trylock_Pi_Type(.TRYLOCK_PI)
FUTEX_WAIT_REQUEUE_PI :: Futex_Wait_requeue_Pi_Type(.WAIT_REQUEUE_PI)
FUTEX_CMP_REQUEUE_PI  :: Futex_Cmp_requeue_Pi_Type(.CMP_REQUEUE_PI)
FUTEX_LOCK_PI2        :: Futex_Lock_Pi2_Type(.LOCK_PI2)

PTrace_Traceme_Type                :: distinct PTrace_Request
PTrace_Peek_Type                   :: distinct PTrace_Request
PTrace_Poke_Type                   :: distinct PTrace_Request
PTrace_Cont_Type                   :: distinct PTrace_Request
PTrace_Kill_Type                   :: distinct PTrace_Request
PTrace_Singlestep_Type             :: distinct PTrace_Request
PTrace_Getregs_Type                :: distinct PTrace_Request
PTrace_Setregs_Type                :: distinct PTrace_Request
PTrace_Getfpregs_Type              :: distinct PTrace_Request
PTrace_Setfpregs_Type              :: distinct PTrace_Request
PTrace_Attach_Type                 :: distinct PTrace_Request
PTrace_Detach_Type                 :: distinct PTrace_Request
PTrace_Getfpxregs_Type             :: distinct PTrace_Request
PTrace_Setfpxregs_Type             :: distinct PTrace_Request
PTrace_Syscall_Type                :: distinct PTrace_Request
PTrace_Get_Thread_Area_Type        :: distinct PTrace_Request
PTrace_Set_Thread_Area_Type        :: distinct PTrace_Request
PTrace_Arch_Prctl_Type             :: distinct PTrace_Request
PTrace_Sysemu_Type                 :: distinct PTrace_Request
PTrace_Sysemu_Singlestep_Type      :: distinct PTrace_Request
PTrace_Singleblock_Type            :: distinct PTrace_Request
PTrace_Setoptions_Type             :: distinct PTrace_Request
PTrace_Geteventmsg_Type            :: distinct PTrace_Request
PTrace_Getsiginfo_Type             :: distinct PTrace_Request
PTrace_Setsiginfo_Type             :: distinct PTrace_Request
PTrace_Getregset_Type              :: distinct PTrace_Request
PTrace_Setregset_Type              :: distinct PTrace_Request
PTrace_Seize_Type                  :: distinct PTrace_Request
PTrace_Interrupt_Type              :: distinct PTrace_Request
PTrace_Listen_Type                 :: distinct PTrace_Request
PTrace_Peeksiginfo_Type            :: distinct PTrace_Request
PTrace_Getsigmask_Type             :: distinct PTrace_Request
PTrace_Setsigmask_Type             :: distinct PTrace_Request
PTrace_Seccomp_Get_Filter_Type     :: distinct PTrace_Request
PTrace_Seccomp_Get_Metadata_Type   :: distinct PTrace_Request
PTrace_Get_Syscall_Info_Type       :: distinct PTrace_Request
PTrace_Get_RSeq_Configuration_Type :: distinct PTrace_Request

PTRACE_TRACEME                :: PTrace_Traceme_Type(.TRACEME)
PTRACE_PEEKTEXT               :: PTrace_Peek_Type(.PEEKTEXT)
PTRACE_PEEKDATA               :: PTrace_Peek_Type(.PEEKDATA)
PTRACE_PEEKUSER               :: PTrace_Peek_Type(.PEEKUSER)
PTRACE_POKETEXT               :: PTrace_Poke_Type(.POKETEXT)
PTRACE_POKEDATA               :: PTrace_Poke_Type(.POKEDATA)
PTRACE_POKEUSER               :: PTrace_Poke_Type(.POKEUSER)
PTRACE_CONT                   :: PTrace_Cont_Type(.CONT)
PTRACE_KILL                   :: PTrace_Kill_Type(.KILL)
PTRACE_SINGLESTEP             :: PTrace_Singlestep_Type(.SINGLESTEP)
PTRACE_GETREGS                :: PTrace_Getregs_Type(.GETREGS)
PTRACE_SETREGS                :: PTrace_Setregs_Type(.SETREGS)
PTRACE_GETFPREGS              :: PTrace_Getfpregs_Type(.GETFPREGS)
PTRACE_SETFPREGS              :: PTrace_Setfpregs_Type(.SETFPREGS)
PTRACE_ATTACH                 :: PTrace_Attach_Type(.ATTACH)
PTRACE_DETACH                 :: PTrace_Detach_Type(.DETACH)
PTRACE_GETFPXREGS             :: PTrace_Getfpxregs_Type(.GETFPXREGS)
PTRACE_SETFPXREGS             :: PTrace_Setfpxregs_Type(.SETFPXREGS)
PTRACE_SYSCALL                :: PTrace_Syscall_Type(.SYSCALL)
PTRACE_GET_THREAD_AREA        :: PTrace_Get_Thread_Area_Type(.GET_THREAD_AREA)
PTRACE_SET_THREAD_AREA        :: PTrace_Set_Thread_Area_Type(.SET_THREAD_AREA)
PTRACE_ARCH_PRCTL             :: PTrace_Arch_Prctl_Type(.ARCH_PRCTL)
PTRACE_SYSEMU                 :: PTrace_Sysemu_Type(.SYSEMU)
PTRACE_SYSEMU_SINGLESTEP      :: PTrace_Sysemu_Singlestep_Type(.SYSEMU_SINGLESTEP)
PTRACE_SINGLEBLOCK            :: PTrace_Singleblock_Type(.SINGLEBLOCK)
PTRACE_SETOPTIONS             :: PTrace_Setoptions_Type(.SETOPTIONS)
PTRACE_GETEVENTMSG            :: PTrace_Geteventmsg_Type(.GETEVENTMSG)
PTRACE_GETSIGINFO             :: PTrace_Getsiginfo_Type(.GETSIGINFO)
PTRACE_SETSIGINFO             :: PTrace_Setsiginfo_Type(.SETSIGINFO)
PTRACE_GETREGSET              :: PTrace_Getregset_Type(.GETREGSET)
PTRACE_SETREGSET              :: PTrace_Setregset_Type(.SETREGSET)
PTRACE_SEIZE                  :: PTrace_Seize_Type(.SEIZE)
PTRACE_INTERRUPT              :: PTrace_Interrupt_Type(.INTERRUPT)
PTRACE_LISTEN                 :: PTrace_Listen_Type(.LISTEN)
PTRACE_PEEKSIGINFO            :: PTrace_Peeksiginfo_Type(.PEEKSIGINFO)
PTRACE_GETSIGMASK             :: PTrace_Getsigmask_Type(.GETSIGMASK)
PTRACE_SETSIGMASK             :: PTrace_Setsigmask_Type(.SETSIGMASK)
PTRACE_SECCOMP_GET_FILTER     :: PTrace_Seccomp_Get_Filter_Type(.SECCOMP_GET_FILTER)
PTRACE_SECCOMP_GET_METADATA   :: PTrace_Seccomp_Get_Metadata_Type(.SECCOMP_GET_METADATA)
PTRACE_GET_SYSCALL_INFO       :: PTrace_Get_Syscall_Info_Type(.GET_SYSCALL_INFO)
PTRACE_GET_RSEQ_CONFIGURATION :: PTrace_Get_RSeq_Configuration_Type(.GET_RSEQ_CONFIGURATION)

MAP_SHARED_VALIDATE :: Map_Flags{.SHARED, .PRIVATE}

MAP_HUGE_SHIFT :: 26
MAP_HUGE_MASK  :: 63

MAP_HUGE_16KB       :: transmute(Map_Flags)(u32(14) << MAP_HUGE_SHIFT)
MAP_HUGE_64KB       :: transmute(Map_Flags)(u32(16) << MAP_HUGE_SHIFT)
MAP_HUGE_512KB      :: transmute(Map_Flags)(u32(19) << MAP_HUGE_SHIFT)
MAP_HUGE_1MB        :: transmute(Map_Flags)(u32(20) << MAP_HUGE_SHIFT)
MAP_HUGE_2MB        :: transmute(Map_Flags)(u32(21) << MAP_HUGE_SHIFT)
MAP_HUGE_8MB        :: transmute(Map_Flags)(u32(23) << MAP_HUGE_SHIFT)
MAP_HUGE_16MB       :: transmute(Map_Flags)(u32(24) << MAP_HUGE_SHIFT)
MAP_HUGE_32MB       :: transmute(Map_Flags)(u32(25) << MAP_HUGE_SHIFT)
MAP_HUGE_256MB      :: transmute(Map_Flags)(u32(28) << MAP_HUGE_SHIFT)
MAP_HUGE_512MB      :: transmute(Map_Flags)(u32(29) << MAP_HUGE_SHIFT)
MAP_HUGE_1GB        :: transmute(Map_Flags)(u32(30) << MAP_HUGE_SHIFT)
MAP_HUGE_2GB        :: transmute(Map_Flags)(u32(31) << MAP_HUGE_SHIFT)
MAP_HUGE_16GB       :: transmute(Map_Flags)(u32(34) << MAP_HUGE_SHIFT)

MFD_HUGE_16KB       :: transmute(Memfd_Create_Flags)(u32(14) << MAP_HUGE_SHIFT)
MFD_HUGE_64KB       :: transmute(Memfd_Create_Flags)(u32(16) << MAP_HUGE_SHIFT)
MFD_HUGE_512KB      :: transmute(Memfd_Create_Flags)(u32(19) << MAP_HUGE_SHIFT)
MFD_HUGE_1MB        :: transmute(Memfd_Create_Flags)(u32(20) << MAP_HUGE_SHIFT)
MFD_HUGE_2MB        :: transmute(Memfd_Create_Flags)(u32(21) << MAP_HUGE_SHIFT)
MFD_HUGE_8MB        :: transmute(Memfd_Create_Flags)(u32(23) << MAP_HUGE_SHIFT)
MFD_HUGE_16MB       :: transmute(Memfd_Create_Flags)(u32(24) << MAP_HUGE_SHIFT)
MFD_HUGE_32MB       :: transmute(Memfd_Create_Flags)(u32(25) << MAP_HUGE_SHIFT)
MFD_HUGE_256MB      :: transmute(Memfd_Create_Flags)(u32(28) << MAP_HUGE_SHIFT)
MFD_HUGE_512MB      :: transmute(Memfd_Create_Flags)(u32(29) << MAP_HUGE_SHIFT)
MFD_HUGE_1GB        :: transmute(Memfd_Create_Flags)(u32(30) << MAP_HUGE_SHIFT)
MFD_HUGE_2GB        :: transmute(Memfd_Create_Flags)(u32(31) << MAP_HUGE_SHIFT)
MFD_HUGE_16GB       :: transmute(Memfd_Create_Flags)(u32(34) << MAP_HUGE_SHIFT)

/* Get window size */
TIOCGWINSZ :: 0x5413

IORING_TIMEOUT_CLOCK_MASK  :: IO_Uring_Timeout_Flags{.BOOTTIME, .REALTIME}
IORING_TIMEOUT_UPDATE_MASK :: IO_Uring_Timeout_Flags{.UPDATE, .LINK_TIMEOUT_UPDATE}

IORING_OFF_SQ_RING    :: 0
IORING_OFF_CQ_RING    :: 0x8000000
IORING_OFF_SQES       :: 0x10000000
IORING_OFF_PBUF_RING  :: 0x80000000
IORING_OFF_PBUF_SHIFT :: 16
IORING_OFF_MMAP_MASK  :: 0xf8000000

SWAP_FLAG_PRIO_SHIFT :: u32(0)
SWAP_FLAG_PRIO_MASK  :: u32(0x7fff)

NLM_F_DUMP :: Netlink_Message_Flags{.ROOT, .MATCH}

/*
* Device properties and quirks
*/
INPUT_PROP_POINTER        :: 0x00 /* needs a pointer */
INPUT_PROP_DIRECT         :: 0x01 /* direct input devices */
INPUT_PROP_BUTTONPAD      :: 0x02 /* has button(s) under pad */
INPUT_PROP_SEMI_MT        :: 0x03 /* touch rectangle only */
INPUT_PROP_TOPBUTTONPAD   :: 0x04 /* softbuttons at top of pad */
INPUT_PROP_POINTING_STICK :: 0x05 /* is a pointing stick */
INPUT_PROP_ACCELEROMETER  :: 0x06 /* has accelerometer */
INPUT_PROP_PRESSUREPAD    :: 0x07 /* pressure triggers clicks */
INPUT_PROP_MAX            :: 0x1f
INPUT_PROP_CNT            :: (INPUT_PROP_MAX+1)

/*
* Event types
*/
EV_SYN       :: 0x00
EV_KEY       :: 0x01
EV_REL       :: 0x02
EV_ABS       :: 0x03
EV_MSC       :: 0x04
EV_SW        :: 0x05
EV_LED       :: 0x11
EV_SND       :: 0x12
EV_REP       :: 0x14
EV_FF        :: 0x15
EV_PWR       :: 0x16
EV_FF_STATUS :: 0x17
EV_MAX       :: 0x1f
EV_CNT       :: (EV_MAX+1)

/*
* Synchronization events.
*/
SYN_REPORT    :: 0
SYN_CONFIG    :: 1
SYN_MT_REPORT :: 2
SYN_DROPPED   :: 3
SYN_MAX       :: 0xf
SYN_CNT       :: (SYN_MAX+1)

/*
* Keys and buttons
*
* Most of the keys/buttons are modeled after USB HUT 1.12
* (see http://www.usb.org/developers/hidpage).
* Abbreviations in the comments:
* AC - Application Control
* AL - Application Launch Button
* SC - System Control
*/
KEY_RESERVED         :: 0
KEY_ESC              :: 1
KEY_1                :: 2
KEY_2                :: 3
KEY_3                :: 4
KEY_4                :: 5
KEY_5                :: 6
KEY_6                :: 7
KEY_7                :: 8
KEY_8                :: 9
KEY_9                :: 10
KEY_0                :: 11
KEY_MINUS            :: 12
KEY_EQUAL            :: 13
KEY_BACKSPACE        :: 14
KEY_TAB              :: 15
KEY_Q                :: 16
KEY_W                :: 17
KEY_E                :: 18
KEY_R                :: 19
KEY_T                :: 20
KEY_Y                :: 21
KEY_U                :: 22
KEY_I                :: 23
KEY_O                :: 24
KEY_P                :: 25
KEY_LEFTBRACE        :: 26
KEY_RIGHTBRACE       :: 27
KEY_ENTER            :: 28
KEY_LEFTCTRL         :: 29
KEY_A                :: 30
KEY_S                :: 31
KEY_D                :: 32
KEY_F                :: 33
KEY_G                :: 34
KEY_H                :: 35
KEY_J                :: 36
KEY_K                :: 37
KEY_L                :: 38
KEY_SEMICOLON        :: 39
KEY_APOSTROPHE       :: 40
KEY_GRAVE            :: 41
KEY_LEFTSHIFT        :: 42
KEY_BACKSLASH        :: 43
KEY_Z                :: 44
KEY_X                :: 45
KEY_C                :: 46
KEY_V                :: 47
KEY_B                :: 48
KEY_N                :: 49
KEY_M                :: 50
KEY_COMMA            :: 51
KEY_DOT              :: 52
KEY_SLASH            :: 53
KEY_RIGHTSHIFT       :: 54
KEY_KPASTERISK       :: 55
KEY_LEFTALT          :: 56
KEY_SPACE            :: 57
KEY_CAPSLOCK         :: 58
KEY_F1               :: 59
KEY_F2               :: 60
KEY_F3               :: 61
KEY_F4               :: 62
KEY_F5               :: 63
KEY_F6               :: 64
KEY_F7               :: 65
KEY_F8               :: 66
KEY_F9               :: 67
KEY_F10              :: 68
KEY_NUMLOCK          :: 69
KEY_SCROLLLOCK       :: 70
KEY_KP7              :: 71
KEY_KP8              :: 72
KEY_KP9              :: 73
KEY_KPMINUS          :: 74
KEY_KP4              :: 75
KEY_KP5              :: 76
KEY_KP6              :: 77
KEY_KPPLUS           :: 78
KEY_KP1              :: 79
KEY_KP2              :: 80
KEY_KP3              :: 81
KEY_KP0              :: 82
KEY_KPDOT            :: 83
KEY_ZENKAKUHANKAKU   :: 85
KEY_102ND            :: 86
KEY_F11              :: 87
KEY_F12              :: 88
KEY_RO               :: 89
KEY_KATAKANA         :: 90
KEY_HIRAGANA         :: 91
KEY_HENKAN           :: 92
KEY_KATAKANAHIRAGANA :: 93
KEY_MUHENKAN         :: 94
KEY_KPJPCOMMA        :: 95
KEY_KPENTER          :: 96
KEY_RIGHTCTRL        :: 97
KEY_KPSLASH          :: 98
KEY_SYSRQ            :: 99
KEY_RIGHTALT         :: 100
KEY_LINEFEED         :: 101
KEY_HOME             :: 102
KEY_UP               :: 103
KEY_PAGEUP           :: 104
KEY_LEFT             :: 105
KEY_RIGHT            :: 106
KEY_END              :: 107
KEY_DOWN             :: 108
KEY_PAGEDOWN         :: 109
KEY_INSERT           :: 110
KEY_DELETE           :: 111
KEY_MACRO            :: 112
KEY_MUTE             :: 113
KEY_VOLUMEDOWN       :: 114
KEY_VOLUMEUP         :: 115
KEY_POWER            :: 116 /* SC System Power Down */
KEY_KPEQUAL          :: 117
KEY_KPPLUSMINUS      :: 118
KEY_PAUSE            :: 119
KEY_SCALE            :: 120 /* AL Compiz Scale (Expose) */
KEY_KPCOMMA          :: 121
KEY_HANGEUL          :: 122
KEY_HANGUEL          :: KEY_HANGEUL
KEY_HANJA            :: 123
KEY_YEN              :: 124
KEY_LEFTMETA         :: 125
KEY_RIGHTMETA        :: 126
KEY_COMPOSE          :: 127
KEY_STOP             :: 128 /* AC Stop */
KEY_AGAIN            :: 129
KEY_PROPS            :: 130 /* AC Properties */
KEY_UNDO             :: 131 /* AC Undo */
KEY_FRONT            :: 132
KEY_COPY             :: 133 /* AC Copy */
KEY_OPEN             :: 134 /* AC Open */
KEY_PASTE            :: 135 /* AC Paste */
KEY_FIND             :: 136 /* AC Search */
KEY_CUT              :: 137 /* AC Cut */
KEY_HELP             :: 138 /* AL Integrated Help Center */
KEY_MENU             :: 139 /* Menu (show menu) */
KEY_CALC             :: 140 /* AL Calculator */
KEY_SETUP            :: 141
KEY_SLEEP            :: 142 /* SC System Sleep */
KEY_WAKEUP           :: 143 /* System Wake Up */
KEY_FILE             :: 144 /* AL Local Machine Browser */
KEY_SENDFILE         :: 145
KEY_DELETEFILE       :: 146
KEY_XFER             :: 147
KEY_PROG1            :: 148
KEY_PROG2            :: 149
KEY_WWW              :: 150 /* AL Internet Browser */
KEY_MSDOS            :: 151
KEY_COFFEE           :: 152 /* AL Terminal Lock/Screensaver */
KEY_SCREENLOCK       :: KEY_COFFEE
KEY_ROTATE_DISPLAY   :: 153 /* Display orientation for e.g. tablets */
KEY_DIRECTION        :: KEY_ROTATE_DISPLAY
KEY_CYCLEWINDOWS     :: 154
KEY_MAIL             :: 155
KEY_BOOKMARKS        :: 156 /* AC Bookmarks */
KEY_COMPUTER         :: 157
KEY_BACK             :: 158 /* AC Back */
KEY_FORWARD          :: 159 /* AC Forward */
KEY_CLOSECD          :: 160
KEY_EJECTCD          :: 161
KEY_EJECTCLOSECD     :: 162
KEY_NEXTSONG         :: 163
KEY_PLAYPAUSE        :: 164
KEY_PREVIOUSSONG     :: 165
KEY_STOPCD           :: 166
KEY_RECORD           :: 167
KEY_REWIND           :: 168
KEY_PHONE            :: 169 /* Media Select Telephone */
KEY_ISO              :: 170
KEY_CONFIG           :: 171 /* AL Consumer Control Configuration */
KEY_HOMEPAGE         :: 172 /* AC Home */
KEY_REFRESH          :: 173 /* AC Refresh */
KEY_EXIT             :: 174 /* AC Exit */
KEY_MOVE             :: 175
KEY_EDIT             :: 176
KEY_SCROLLUP         :: 177
KEY_SCROLLDOWN       :: 178
KEY_KPLEFTPAREN      :: 179
KEY_KPRIGHTPAREN     :: 180
KEY_NEW              :: 181 /* AC New */
KEY_REDO             :: 182 /* AC Redo/Repeat */
KEY_F13              :: 183
KEY_F14              :: 184
KEY_F15              :: 185
KEY_F16              :: 186
KEY_F17              :: 187
KEY_F18              :: 188
KEY_F19              :: 189
KEY_F20              :: 190
KEY_F21              :: 191
KEY_F22              :: 192
KEY_F23              :: 193
KEY_F24              :: 194
KEY_PLAYCD           :: 200
KEY_PAUSECD          :: 201
KEY_PROG3            :: 202
KEY_PROG4            :: 203
KEY_ALL_APPLICATIONS :: 204 /* AC Desktop Show All Applications */
KEY_DASHBOARD        :: KEY_ALL_APPLICATIONS
KEY_SUSPEND          :: 205
KEY_CLOSE            :: 206 /* AC Close */
KEY_PLAY             :: 207
KEY_FASTFORWARD      :: 208
KEY_BASSBOOST        :: 209
KEY_PRINT            :: 210 /* AC Print */
KEY_HP               :: 211
KEY_CAMERA           :: 212
KEY_SOUND            :: 213
KEY_QUESTION         :: 214
KEY_EMAIL            :: 215
KEY_CHAT             :: 216
KEY_SEARCH           :: 217
KEY_CONNECT          :: 218
KEY_FINANCE          :: 219 /* AL Checkbook/Finance */
KEY_SPORT            :: 220
KEY_SHOP             :: 221
KEY_ALTERASE         :: 222
KEY_CANCEL           :: 223 /* AC Cancel */
KEY_BRIGHTNESSDOWN   :: 224
KEY_BRIGHTNESSUP     :: 225
KEY_MEDIA            :: 226
KEY_SWITCHVIDEOMODE  :: 227 /* Cycle between available video outputs (Monitor/LCD/TV-out/etc) */
KEY_KBDILLUMTOGGLE   :: 228
KEY_KBDILLUMDOWN     :: 229
KEY_KBDILLUMUP       :: 230
KEY_SEND             :: 231 /* AC Send */
KEY_REPLY            :: 232 /* AC Reply */
KEY_FORWARDMAIL      :: 233 /* AC Forward Msg */
KEY_SAVE             :: 234 /* AC Save */
KEY_DOCUMENTS        :: 235
KEY_BATTERY          :: 236
KEY_BLUETOOTH        :: 237
KEY_WLAN             :: 238
KEY_UWB              :: 239
KEY_UNKNOWN          :: 240
KEY_VIDEO_NEXT       :: 241 /* drive next video source */
KEY_VIDEO_PREV       :: 242 /* drive previous video source */
KEY_BRIGHTNESS_CYCLE :: 243 /* brightness up, after max is min */
KEY_BRIGHTNESS_AUTO  :: 244 /* Set Auto Brightness: manual brightness control is off, rely on ambient */
KEY_BRIGHTNESS_ZERO  :: KEY_BRIGHTNESS_AUTO
KEY_DISPLAY_OFF      :: 245 /* display device to off state */
KEY_WWAN             :: 246 /* Wireless WAN (LTE, UMTS, GSM, etc.) */
KEY_WIMAX            :: KEY_WWAN
KEY_RFKILL           :: 247 /* Key that controls all radios */
KEY_MICMUTE          :: 248 /* Mute / unmute the microphone */

/* Code 255 is reserved for special needs of AT keyboard driver */
BTN_MISC                  :: 0x100
BTN_0                     :: 0x100
BTN_1                     :: 0x101
BTN_2                     :: 0x102
BTN_3                     :: 0x103
BTN_4                     :: 0x104
BTN_5                     :: 0x105
BTN_6                     :: 0x106
BTN_7                     :: 0x107
BTN_8                     :: 0x108
BTN_9                     :: 0x109
BTN_MOUSE                 :: 0x110
BTN_LEFT                  :: 0x110
BTN_RIGHT                 :: 0x111
BTN_MIDDLE                :: 0x112
BTN_SIDE                  :: 0x113
BTN_EXTRA                 :: 0x114
BTN_FORWARD               :: 0x115
BTN_BACK                  :: 0x116
BTN_TASK                  :: 0x117
BTN_JOYSTICK              :: 0x120
BTN_TRIGGER               :: 0x120
BTN_THUMB                 :: 0x121
BTN_THUMB2                :: 0x122
BTN_TOP                   :: 0x123
BTN_TOP2                  :: 0x124
BTN_PINKIE                :: 0x125
BTN_BASE                  :: 0x126
BTN_BASE2                 :: 0x127
BTN_BASE3                 :: 0x128
BTN_BASE4                 :: 0x129
BTN_BASE5                 :: 0x12a
BTN_BASE6                 :: 0x12b
BTN_DEAD                  :: 0x12f
BTN_GAMEPAD               :: 0x130
BTN_SOUTH                 :: 0x130
BTN_A                     :: BTN_SOUTH
BTN_EAST                  :: 0x131
BTN_B                     :: BTN_EAST
BTN_C                     :: 0x132
BTN_NORTH                 :: 0x133
BTN_X                     :: BTN_NORTH
BTN_WEST                  :: 0x134
BTN_Y                     :: BTN_WEST
BTN_Z                     :: 0x135
BTN_TL                    :: 0x136
BTN_TR                    :: 0x137
BTN_TL2                   :: 0x138
BTN_TR2                   :: 0x139
BTN_SELECT                :: 0x13a
BTN_START                 :: 0x13b
BTN_MODE                  :: 0x13c
BTN_THUMBL                :: 0x13d
BTN_THUMBR                :: 0x13e
BTN_DIGI                  :: 0x140
BTN_TOOL_PEN              :: 0x140
BTN_TOOL_RUBBER           :: 0x141
BTN_TOOL_BRUSH            :: 0x142
BTN_TOOL_PENCIL           :: 0x143
BTN_TOOL_AIRBRUSH         :: 0x144
BTN_TOOL_FINGER           :: 0x145
BTN_TOOL_MOUSE            :: 0x146
BTN_TOOL_LENS             :: 0x147
BTN_TOOL_QUINTTAP         :: 0x148 /* Five fingers on trackpad */
BTN_STYLUS3               :: 0x149
BTN_TOUCH                 :: 0x14a
BTN_STYLUS                :: 0x14b
BTN_STYLUS2               :: 0x14c
BTN_TOOL_DOUBLETAP        :: 0x14d
BTN_TOOL_TRIPLETAP        :: 0x14e
BTN_TOOL_QUADTAP          :: 0x14f /* Four fingers on trackpad */
BTN_WHEEL                 :: 0x150
BTN_GEAR_DOWN             :: 0x150
BTN_GEAR_UP               :: 0x151
KEY_OK                    :: 0x160
KEY_SELECT                :: 0x161
KEY_GOTO                  :: 0x162
KEY_CLEAR                 :: 0x163
KEY_POWER2                :: 0x164
KEY_OPTION                :: 0x165
KEY_INFO                  :: 0x166 /* AL OEM Features/Tips/Tutorial */
KEY_TIME                  :: 0x167
KEY_VENDOR                :: 0x168
KEY_ARCHIVE               :: 0x169
KEY_PROGRAM               :: 0x16a /* Media Select Program Guide */
KEY_CHANNEL               :: 0x16b
KEY_FAVORITES             :: 0x16c
KEY_EPG                   :: 0x16d
KEY_PVR                   :: 0x16e /* Media Select Home */
KEY_MHP                   :: 0x16f
KEY_LANGUAGE              :: 0x170
KEY_TITLE                 :: 0x171
KEY_SUBTITLE              :: 0x172
KEY_ANGLE                 :: 0x173
KEY_FULL_SCREEN           :: 0x174 /* AC View Toggle */
KEY_ZOOM                  :: KEY_FULL_SCREEN
KEY_MODE                  :: 0x175
KEY_KEYBOARD              :: 0x176
KEY_ASPECT_RATIO          :: 0x177 /* HUTRR37: Aspect */
KEY_SCREEN                :: KEY_ASPECT_RATIO
KEY_PC                    :: 0x178 /* Media Select Computer */
KEY_TV                    :: 0x179 /* Media Select TV */
KEY_TV2                   :: 0x17a /* Media Select Cable */
KEY_VCR                   :: 0x17b /* Media Select VCR */
KEY_VCR2                  :: 0x17c /* VCR Plus */
KEY_SAT                   :: 0x17d /* Media Select Satellite */
KEY_SAT2                  :: 0x17e
KEY_CD                    :: 0x17f /* Media Select CD */
KEY_TAPE                  :: 0x180 /* Media Select Tape */
KEY_RADIO                 :: 0x181
KEY_TUNER                 :: 0x182 /* Media Select Tuner */
KEY_PLAYER                :: 0x183
KEY_TEXT                  :: 0x184
KEY_DVD                   :: 0x185 /* Media Select DVD */
KEY_AUX                   :: 0x186
KEY_MP3                   :: 0x187
KEY_AUDIO                 :: 0x188 /* AL Audio Browser */
KEY_VIDEO                 :: 0x189 /* AL Movie Browser */
KEY_DIRECTORY             :: 0x18a
KEY_LIST                  :: 0x18b
KEY_MEMO                  :: 0x18c /* Media Select Messages */
KEY_CALENDAR              :: 0x18d
KEY_RED                   :: 0x18e
KEY_GREEN                 :: 0x18f
KEY_YELLOW                :: 0x190
KEY_BLUE                  :: 0x191
KEY_CHANNELUP             :: 0x192 /* Channel Increment */
KEY_CHANNELDOWN           :: 0x193 /* Channel Decrement */
KEY_FIRST                 :: 0x194
KEY_LAST                  :: 0x195 /* Recall Last */
KEY_AB                    :: 0x196
KEY_NEXT                  :: 0x197
KEY_RESTART               :: 0x198
KEY_SLOW                  :: 0x199
KEY_SHUFFLE               :: 0x19a
KEY_BREAK                 :: 0x19b
KEY_PREVIOUS              :: 0x19c
KEY_DIGITS                :: 0x19d
KEY_TEEN                  :: 0x19e
KEY_TWEN                  :: 0x19f
KEY_VIDEOPHONE            :: 0x1a0 /* Media Select Video Phone */
KEY_GAMES                 :: 0x1a1 /* Media Select Games */
KEY_ZOOMIN                :: 0x1a2 /* AC Zoom In */
KEY_ZOOMOUT               :: 0x1a3 /* AC Zoom Out */
KEY_ZOOMRESET             :: 0x1a4 /* AC Zoom */
KEY_WORDPROCESSOR         :: 0x1a5 /* AL Word Processor */
KEY_EDITOR                :: 0x1a6 /* AL Text Editor */
KEY_SPREADSHEET           :: 0x1a7 /* AL Spreadsheet */
KEY_GRAPHICSEDITOR        :: 0x1a8 /* AL Graphics Editor */
KEY_PRESENTATION          :: 0x1a9 /* AL Presentation App */
KEY_DATABASE              :: 0x1aa /* AL Database App */
KEY_NEWS                  :: 0x1ab /* AL Newsreader */
KEY_VOICEMAIL             :: 0x1ac /* AL Voicemail */
KEY_ADDRESSBOOK           :: 0x1ad /* AL Contacts/Address Book */
KEY_MESSENGER             :: 0x1ae /* AL Instant Messaging */
KEY_DISPLAYTOGGLE         :: 0x1af /* Turn display (LCD) on and off */
KEY_BRIGHTNESS_TOGGLE     :: KEY_DISPLAYTOGGLE
KEY_SPELLCHECK            :: 0x1b0   /* AL Spell Check */
KEY_LOGOFF                :: 0x1b1   /* AL Logoff */
KEY_DOLLAR                :: 0x1b2
KEY_EURO                  :: 0x1b3
KEY_FRAMEBACK             :: 0x1b4 /* Consumer - transport controls */
KEY_FRAMEFORWARD          :: 0x1b5
KEY_CONTEXT_MENU          :: 0x1b6 /* GenDesc - system context menu */
KEY_MEDIA_REPEAT          :: 0x1b7 /* Consumer - transport control */
KEY_10CHANNELSUP          :: 0x1b8 /* 10 channels up (10+) */
KEY_10CHANNELSDOWN        :: 0x1b9 /* 10 channels down (10-) */
KEY_IMAGES                :: 0x1ba /* AL Image Browser */
KEY_NOTIFICATION_CENTER   :: 0x1bc /* Show/hide the notification center */
KEY_PICKUP_PHONE          :: 0x1bd /* Answer incoming call */
KEY_HANGUP_PHONE          :: 0x1be /* Decline incoming call */
KEY_LINK_PHONE            :: 0x1bf   /* AL Phone Syncing */
KEY_DEL_EOL               :: 0x1c0
KEY_DEL_EOS               :: 0x1c1
KEY_INS_LINE              :: 0x1c2
KEY_DEL_LINE              :: 0x1c3
KEY_FN                    :: 0x1d0
KEY_FN_ESC                :: 0x1d1
KEY_FN_F1                 :: 0x1d2
KEY_FN_F2                 :: 0x1d3
KEY_FN_F3                 :: 0x1d4
KEY_FN_F4                 :: 0x1d5
KEY_FN_F5                 :: 0x1d6
KEY_FN_F6                 :: 0x1d7
KEY_FN_F7                 :: 0x1d8
KEY_FN_F8                 :: 0x1d9
KEY_FN_F9                 :: 0x1da
KEY_FN_F10                :: 0x1db
KEY_FN_F11                :: 0x1dc
KEY_FN_F12                :: 0x1dd
KEY_FN_1                  :: 0x1de
KEY_FN_2                  :: 0x1df
KEY_FN_D                  :: 0x1e0
KEY_FN_E                  :: 0x1e1
KEY_FN_F                  :: 0x1e2
KEY_FN_S                  :: 0x1e3
KEY_FN_B                  :: 0x1e4
KEY_FN_RIGHT_SHIFT        :: 0x1e5
KEY_BRL_DOT1              :: 0x1f1
KEY_BRL_DOT2              :: 0x1f2
KEY_BRL_DOT3              :: 0x1f3
KEY_BRL_DOT4              :: 0x1f4
KEY_BRL_DOT5              :: 0x1f5
KEY_BRL_DOT6              :: 0x1f6
KEY_BRL_DOT7              :: 0x1f7
KEY_BRL_DOT8              :: 0x1f8
KEY_BRL_DOT9              :: 0x1f9
KEY_BRL_DOT10             :: 0x1fa
KEY_NUMERIC_0             :: 0x200 /* used by phones, remote controls, */
KEY_NUMERIC_1             :: 0x201 /* and other keypads */
KEY_NUMERIC_2             :: 0x202
KEY_NUMERIC_3             :: 0x203
KEY_NUMERIC_4             :: 0x204
KEY_NUMERIC_5             :: 0x205
KEY_NUMERIC_6             :: 0x206
KEY_NUMERIC_7             :: 0x207
KEY_NUMERIC_8             :: 0x208
KEY_NUMERIC_9             :: 0x209
KEY_NUMERIC_STAR          :: 0x20a
KEY_NUMERIC_POUND         :: 0x20b
KEY_NUMERIC_A             :: 0x20c /* Phone key A - HUT Telephony 0xb9 */
KEY_NUMERIC_B             :: 0x20d
KEY_NUMERIC_C             :: 0x20e
KEY_NUMERIC_D             :: 0x20f
KEY_CAMERA_FOCUS          :: 0x210
KEY_WPS_BUTTON            :: 0x211 /* WiFi Protected Setup key */
KEY_TOUCHPAD_TOGGLE       :: 0x212 /* Request switch touchpad on or off */
KEY_TOUCHPAD_ON           :: 0x213
KEY_TOUCHPAD_OFF          :: 0x214
KEY_CAMERA_ZOOMIN         :: 0x215
KEY_CAMERA_ZOOMOUT        :: 0x216
KEY_CAMERA_UP             :: 0x217
KEY_CAMERA_DOWN           :: 0x218
KEY_CAMERA_LEFT           :: 0x219
KEY_CAMERA_RIGHT          :: 0x21a
KEY_ATTENDANT_ON          :: 0x21b
KEY_ATTENDANT_OFF         :: 0x21c
KEY_ATTENDANT_TOGGLE      :: 0x21d /* Attendant call on or off */
KEY_LIGHTS_TOGGLE         :: 0x21e /* Reading light on or off */
BTN_DPAD_UP               :: 0x220
BTN_DPAD_DOWN             :: 0x221
BTN_DPAD_LEFT             :: 0x222
BTN_DPAD_RIGHT            :: 0x223
BTN_GRIPL                 :: 0x224
BTN_GRIPR                 :: 0x225
BTN_GRIPL2                :: 0x226
BTN_GRIPR2                :: 0x227
KEY_ALS_TOGGLE            :: 0x230 /* Ambient light sensor */
KEY_ROTATE_LOCK_TOGGLE    :: 0x231 /* Display rotation lock */
KEY_REFRESH_RATE_TOGGLE   :: 0x232 /* Display refresh rate toggle */
KEY_BUTTONCONFIG          :: 0x240 /* AL Button Configuration */
KEY_TASKMANAGER           :: 0x241 /* AL Task/Project Manager */
KEY_JOURNAL               :: 0x242 /* AL Log/Journal/Timecard */
KEY_CONTROLPANEL          :: 0x243 /* AL Control Panel */
KEY_APPSELECT             :: 0x244 /* AL Select Task/Application */
KEY_SCREENSAVER           :: 0x245 /* AL Screen Saver */
KEY_VOICECOMMAND          :: 0x246 /* Listening Voice Command */
KEY_ASSISTANT             :: 0x247 /* AL Context-aware desktop assistant */
KEY_KBD_LAYOUT_NEXT       :: 0x248 /* AC Next Keyboard Layout Select */
KEY_EMOJI_PICKER          :: 0x249 /* Show/hide emoji picker (HUTRR101) */
KEY_DICTATE               :: 0x24a /* Start or Stop Voice Dictation Session (HUTRR99) */
KEY_CAMERA_ACCESS_ENABLE  :: 0x24b /* Enables programmatic access to camera devices. (HUTRR72) */
KEY_CAMERA_ACCESS_DISABLE :: 0x24c /* Disables programmatic access to camera devices. (HUTRR72) */
KEY_CAMERA_ACCESS_TOGGLE  :: 0x24d /* Toggles the current state of the camera access control. (HUTRR72) */
KEY_ACCESSIBILITY         :: 0x24e /* Toggles the system bound accessibility UI/command (HUTRR116) */
KEY_DO_NOT_DISTURB        :: 0x24f /* Toggles the system-wide "Do Not Disturb" control (HUTRR94)*/
KEY_BRIGHTNESS_MIN        :: 0x250 /* Set Brightness to Minimum */
KEY_BRIGHTNESS_MAX        :: 0x251 /* Set Brightness to Maximum */

/*
* Keycodes for hotkeys toggling the electronic privacy screen found on some
* laptops on/off. Note when the embedded-controller turns on/off the eprivacy
* screen itself then the state should be reported through drm connecter props:
* https://www.kernel.org/doc/html/latest/gpu/drm-kms.html#standard-connector-properties
* Except when implementing the drm connecter properties API is not possible
* because e.g. the firmware does not allow querying the presence and/or status
* of the eprivacy screen at boot.
*/
KEY_EPRIVACY_SCREEN_ON       :: 0x252
KEY_EPRIVACY_SCREEN_OFF      :: 0x253
KEY_ACTION_ON_SELECTION      :: 0x254 /* AL Action on Selection (HUTRR119) */
KEY_CONTEXTUAL_INSERT        :: 0x255 /* AL Contextual Insertion (HUTRR119) */
KEY_CONTEXTUAL_QUERY         :: 0x256 /* AL Contextual Query (HUTRR119) */
KEY_KBDINPUTASSIST_PREV      :: 0x260
KEY_KBDINPUTASSIST_NEXT      :: 0x261
KEY_KBDINPUTASSIST_PREVGROUP :: 0x262
KEY_KBDINPUTASSIST_NEXTGROUP :: 0x263
KEY_KBDINPUTASSIST_ACCEPT    :: 0x264
KEY_KBDINPUTASSIST_CANCEL    :: 0x265

/* Diagonal movement keys */
KEY_RIGHT_UP   :: 0x266
KEY_RIGHT_DOWN :: 0x267
KEY_LEFT_UP    :: 0x268
KEY_LEFT_DOWN  :: 0x269
KEY_ROOT_MENU  :: 0x26a /* Show Device's Root Menu */

/* Show Top Menu of the Media (e.g. DVD) */
KEY_MEDIA_TOP_MENU :: 0x26b
KEY_NUMERIC_11     :: 0x26c
KEY_NUMERIC_12     :: 0x26d

/*
* Toggle Audio Description: refers to an audio service that helps blind and
* visually impaired consumers understand the action in a program. Note: in
* some countries this is referred to as "Video Description".
*/
KEY_AUDIO_DESC    :: 0x26e
KEY_3D_MODE       :: 0x26f
KEY_NEXT_FAVORITE :: 0x270
KEY_STOP_RECORD   :: 0x271
KEY_PAUSE_RECORD  :: 0x272
KEY_VOD           :: 0x273 /* Video on Demand */
KEY_UNMUTE        :: 0x274
KEY_FASTREVERSE   :: 0x275
KEY_SLOWREVERSE   :: 0x276

/*
* Control a data application associated with the currently viewed channel,
* e.g. teletext or data broadcast application (MHEG, MHP, HbbTV, etc.)
*/
KEY_DATA              :: 0x277
KEY_ONSCREEN_KEYBOARD :: 0x278

/* Electronic privacy screen control */
KEY_PRIVACY_SCREEN_TOGGLE :: 0x279

/* Select an area of screen to be copied */
KEY_SELECTIVE_SCREENSHOT :: 0x27a

/* Move the focus to the next or previous user controllable element within a UI container */
KEY_NEXT_ELEMENT     :: 0x27b
KEY_PREVIOUS_ELEMENT :: 0x27c

/* Toggle Autopilot engagement */
KEY_AUTOPILOT_ENGAGE_TOGGLE    :: 0x27d

/* Shortcut Keys */
KEY_MARK_WAYPOINT              :: 0x27e
KEY_SOS                        :: 0x27f
KEY_NAV_CHART                  :: 0x280
KEY_FISHING_CHART              :: 0x281
KEY_SINGLE_RANGE_RADAR         :: 0x282
KEY_DUAL_RANGE_RADAR           :: 0x283
KEY_RADAR_OVERLAY              :: 0x284
KEY_TRADITIONAL_SONAR          :: 0x285
KEY_CLEARVU_SONAR              :: 0x286
KEY_SIDEVU_SONAR               :: 0x287
KEY_NAV_INFO                   :: 0x288
KEY_BRIGHTNESS_MENU            :: 0x289

/*
* Some keyboards have keys which do not have a defined meaning, these keys
* are intended to be programmed / bound to macros by the user. For most
* keyboards with these macro-keys the key-sequence to inject, or action to
* take, is all handled by software on the host side. So from the kernel's
* point of view these are just normal keys.
*
* The KEY_MACRO# codes below are intended for such keys, which may be labeled
* e.g. G1-G18, or S1 - S30. The KEY_MACRO# codes MUST NOT be used for keys
* where the marking on the key does indicate a defined meaning / purpose.
*
* The KEY_MACRO# codes MUST also NOT be used as fallback for when no existing
* KEY_FOO define matches the marking / purpose. In this case a new KEY_FOO
* define MUST be added.
*/
KEY_MACRO1   :: 0x290
KEY_MACRO2   :: 0x291
KEY_MACRO3   :: 0x292
KEY_MACRO4   :: 0x293
KEY_MACRO5   :: 0x294
KEY_MACRO6   :: 0x295
KEY_MACRO7   :: 0x296
KEY_MACRO8   :: 0x297
KEY_MACRO9   :: 0x298
KEY_MACRO10  :: 0x299
KEY_MACRO11  :: 0x29a
KEY_MACRO12  :: 0x29b
KEY_MACRO13  :: 0x29c
KEY_MACRO14  :: 0x29d
KEY_MACRO15  :: 0x29e
KEY_MACRO16  :: 0x29f
KEY_MACRO17  :: 0x2a0
KEY_MACRO18  :: 0x2a1
KEY_MACRO19  :: 0x2a2
KEY_MACRO20  :: 0x2a3
KEY_MACRO21  :: 0x2a4
KEY_MACRO22  :: 0x2a5
KEY_MACRO23  :: 0x2a6
KEY_MACRO24  :: 0x2a7
KEY_MACRO25  :: 0x2a8
KEY_MACRO26  :: 0x2a9
KEY_MACRO27  :: 0x2aa
KEY_MACRO28  :: 0x2ab
KEY_MACRO29  :: 0x2ac
KEY_MACRO30  :: 0x2ad

/*
* Some keyboards with the macro-keys described above have some extra keys
* for controlling the host-side software responsible for the macro handling:
* -A macro recording start/stop key. Note that not all keyboards which emit
*  KEY_MACRO_RECORD_START will also emit KEY_MACRO_RECORD_STOP if
*  KEY_MACRO_RECORD_STOP is not advertised, then KEY_MACRO_RECORD_START
*  should be interpreted as a recording start/stop toggle;
* -Keys for switching between different macro (pre)sets, either a key for
*  cycling through the configured presets or keys to directly select a preset.
*/
KEY_MACRO_RECORD_START :: 0x2b0
KEY_MACRO_RECORD_STOP  :: 0x2b1
KEY_MACRO_PRESET_CYCLE :: 0x2b2
KEY_MACRO_PRESET1      :: 0x2b3
KEY_MACRO_PRESET2      :: 0x2b4
KEY_MACRO_PRESET3      :: 0x2b5

/*
* Some keyboards have a buildin LCD panel where the contents are controlled
* by the host. Often these have a number of keys directly below the LCD
* intended for controlling a menu shown on the LCD. These keys often don't
* have any labeling so we just name them KEY_KBD_LCD_MENU#
*/
KEY_KBD_LCD_MENU1  :: 0x2b8
KEY_KBD_LCD_MENU2  :: 0x2b9
KEY_KBD_LCD_MENU3  :: 0x2ba
KEY_KBD_LCD_MENU4  :: 0x2bb
KEY_KBD_LCD_MENU5  :: 0x2bc

/* Performance Boost key (Alienware)/G-Mode key (Dell) */
KEY_PERFORMANCE     :: 0x2bd
BTN_TRIGGER_HAPPY   :: 0x2c0
BTN_TRIGGER_HAPPY1  :: 0x2c0
BTN_TRIGGER_HAPPY2  :: 0x2c1
BTN_TRIGGER_HAPPY3  :: 0x2c2
BTN_TRIGGER_HAPPY4  :: 0x2c3
BTN_TRIGGER_HAPPY5  :: 0x2c4
BTN_TRIGGER_HAPPY6  :: 0x2c5
BTN_TRIGGER_HAPPY7  :: 0x2c6
BTN_TRIGGER_HAPPY8  :: 0x2c7
BTN_TRIGGER_HAPPY9  :: 0x2c8
BTN_TRIGGER_HAPPY10 :: 0x2c9
BTN_TRIGGER_HAPPY11 :: 0x2ca
BTN_TRIGGER_HAPPY12 :: 0x2cb
BTN_TRIGGER_HAPPY13 :: 0x2cc
BTN_TRIGGER_HAPPY14 :: 0x2cd
BTN_TRIGGER_HAPPY15 :: 0x2ce
BTN_TRIGGER_HAPPY16 :: 0x2cf
BTN_TRIGGER_HAPPY17 :: 0x2d0
BTN_TRIGGER_HAPPY18 :: 0x2d1
BTN_TRIGGER_HAPPY19 :: 0x2d2
BTN_TRIGGER_HAPPY20 :: 0x2d3
BTN_TRIGGER_HAPPY21 :: 0x2d4
BTN_TRIGGER_HAPPY22 :: 0x2d5
BTN_TRIGGER_HAPPY23 :: 0x2d6
BTN_TRIGGER_HAPPY24 :: 0x2d7
BTN_TRIGGER_HAPPY25 :: 0x2d8
BTN_TRIGGER_HAPPY26 :: 0x2d9
BTN_TRIGGER_HAPPY27 :: 0x2da
BTN_TRIGGER_HAPPY28 :: 0x2db
BTN_TRIGGER_HAPPY29 :: 0x2dc
BTN_TRIGGER_HAPPY30 :: 0x2dd
BTN_TRIGGER_HAPPY31 :: 0x2de
BTN_TRIGGER_HAPPY32 :: 0x2df
BTN_TRIGGER_HAPPY33 :: 0x2e0
BTN_TRIGGER_HAPPY34 :: 0x2e1
BTN_TRIGGER_HAPPY35 :: 0x2e2
BTN_TRIGGER_HAPPY36 :: 0x2e3
BTN_TRIGGER_HAPPY37 :: 0x2e4
BTN_TRIGGER_HAPPY38 :: 0x2e5
BTN_TRIGGER_HAPPY39 :: 0x2e6
BTN_TRIGGER_HAPPY40 :: 0x2e7

/* We avoid low common keys in module aliases so they don't get huge. */
KEY_MIN_INTERESTING :: KEY_MUTE
KEY_MAX             :: 0x2ff
KEY_CNT             :: (KEY_MAX+1)

/*
* Relative axes
*/
REL_X      :: 0x00
REL_Y      :: 0x01
REL_Z      :: 0x02
REL_RX     :: 0x03
REL_RY     :: 0x04
REL_RZ     :: 0x05
REL_HWHEEL :: 0x06
REL_DIAL   :: 0x07
REL_WHEEL  :: 0x08
REL_MISC   :: 0x09

/*
* 0x0a is reserved and should not be used in input drivers.
* It was used by HID as REL_MISC+1 and userspace needs to detect if
* the next REL_* event is correct or is just REL_MISC + n.
* We define here REL_RESERVED so userspace can rely on it and detect
* the situation described above.
*/
REL_RESERVED      :: 0x0a
REL_WHEEL_HI_RES  :: 0x0b
REL_HWHEEL_HI_RES :: 0x0c
REL_MAX           :: 0x0f
REL_CNT           :: (REL_MAX+1)

/*
* Absolute axes
*/
ABS_X           :: 0x00
ABS_Y           :: 0x01
ABS_Z           :: 0x02
ABS_RX          :: 0x03
ABS_RY          :: 0x04
ABS_RZ          :: 0x05
ABS_THROTTLE    :: 0x06
ABS_RUDDER      :: 0x07
ABS_WHEEL       :: 0x08
ABS_GAS         :: 0x09
ABS_BRAKE       :: 0x0a
ABS_HAT0X       :: 0x10
ABS_HAT0Y       :: 0x11
ABS_HAT1X       :: 0x12
ABS_HAT1Y       :: 0x13
ABS_HAT2X       :: 0x14
ABS_HAT2Y       :: 0x15
ABS_HAT3X       :: 0x16
ABS_HAT3Y       :: 0x17
ABS_PRESSURE    :: 0x18
ABS_DISTANCE    :: 0x19
ABS_TILT_X      :: 0x1a
ABS_TILT_Y      :: 0x1b
ABS_TOOL_WIDTH  :: 0x1c
ABS_VOLUME      :: 0x20
ABS_PROFILE     :: 0x21
ABS_SND_PROFILE :: 0x22
ABS_MISC        :: 0x28

/*
* 0x2e is reserved and should not be used in input drivers.
* It was used by HID as ABS_MISC+6 and userspace needs to detect if
* the next ABS_* event is correct or is just ABS_MISC + n.
* We define here ABS_RESERVED so userspace can rely on it and detect
* the situation described above.
*/
ABS_RESERVED       :: 0x2e
ABS_MT_SLOT        :: 0x2f /* MT slot being modified */
ABS_MT_TOUCH_MAJOR :: 0x30 /* Major axis of touching ellipse */
ABS_MT_TOUCH_MINOR :: 0x31 /* Minor axis (omit if circular) */
ABS_MT_WIDTH_MAJOR :: 0x32 /* Major axis of approaching ellipse */
ABS_MT_WIDTH_MINOR :: 0x33 /* Minor axis (omit if circular) */
ABS_MT_ORIENTATION :: 0x34 /* Ellipse orientation */
ABS_MT_POSITION_X  :: 0x35 /* Center X touch position */
ABS_MT_POSITION_Y  :: 0x36 /* Center Y touch position */
ABS_MT_TOOL_TYPE   :: 0x37 /* Type of touching device */
ABS_MT_BLOB_ID     :: 0x38 /* Group a set of packets as a blob */
ABS_MT_TRACKING_ID :: 0x39 /* Unique ID of initiated contact */
ABS_MT_PRESSURE    :: 0x3a /* Pressure on contact area */
ABS_MT_DISTANCE    :: 0x3b /* Contact hover distance */
ABS_MT_TOOL_X      :: 0x3c /* Center X tool position */
ABS_MT_TOOL_Y      :: 0x3d /* Center Y tool position */
ABS_MAX            :: 0x3f
ABS_CNT            :: (ABS_MAX+1)

/*
* Switch events
*/
SW_LID                  :: 0x00          /* set = lid shut */
SW_TABLET_MODE          :: 0x01          /* set = tablet mode */
SW_HEADPHONE_INSERT     :: 0x02          /* set = inserted */
SW_RFKILL_ALL           :: 0x03          /* rfkill master switch, type "any" set = radio enabled */
SW_RADIO                :: SW_RFKILL_ALL /* deprecated */
SW_MICROPHONE_INSERT    :: 0x04          /* set = inserted */
SW_DOCK                 :: 0x05          /* set = plugged into dock */
SW_LINEOUT_INSERT       :: 0x06          /* set = inserted */
SW_JACK_PHYSICAL_INSERT :: 0x07          /* set = mechanical switch set */
SW_VIDEOOUT_INSERT      :: 0x08          /* set = inserted */
SW_CAMERA_LENS_COVER    :: 0x09          /* set = lens covered */
SW_KEYPAD_SLIDE         :: 0x0a          /* set = keypad slide out */
SW_FRONT_PROXIMITY      :: 0x0b          /* set = front proximity sensor active */
SW_ROTATE_LOCK          :: 0x0c          /* set = rotate locked/disabled */
SW_LINEIN_INSERT        :: 0x0d          /* set = inserted */
SW_MUTE_DEVICE          :: 0x0e          /* set = device disabled */
SW_PEN_INSERTED         :: 0x0f          /* set = pen inserted */
SW_MACHINE_COVER        :: 0x10          /* set = cover closed */
SW_USB_INSERT           :: 0x11          /* set = USB audio device connected */
SW_MAX                  :: 0x11
SW_CNT                  :: (SW_MAX+1)

/*
* Misc events
*/
MSC_SERIAL    :: 0x00
MSC_PULSELED  :: 0x01
MSC_GESTURE   :: 0x02
MSC_RAW       :: 0x03
MSC_SCAN      :: 0x04
MSC_TIMESTAMP :: 0x05
MSC_MAX       :: 0x07
MSC_CNT       :: (MSC_MAX+1)

/*
* LEDs
*/
LED_NUML     :: 0x00
LED_CAPSL    :: 0x01
LED_SCROLLL  :: 0x02
LED_COMPOSE  :: 0x03
LED_KANA     :: 0x04
LED_SLEEP    :: 0x05
LED_SUSPEND  :: 0x06
LED_MUTE     :: 0x07
LED_MISC     :: 0x08
LED_MAIL     :: 0x09
LED_CHARGING :: 0x0a
LED_MAX      :: 0x0f
LED_CNT      :: (LED_MAX+1)

/*
* Autorepeat values
*/
REP_DELAY  :: 0x00
REP_PERIOD :: 0x01
REP_MAX    :: 0x01
REP_CNT    :: (REP_MAX+1)

/*
* Sounds
*/
SND_CLICK :: 0x00
SND_BELL  :: 0x01
SND_TONE  :: 0x02
SND_MAX   :: 0x07
SND_CNT   :: (SND_MAX+1)

/*
* ABS_SND_PROFILE values
*/
SND_PROFILE_SILENT  :: 0x00
SND_PROFILE_VIBRATE :: 0x01
SND_PROFILE_RING    :: 0x02
