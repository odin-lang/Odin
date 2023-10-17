
package linux

/// Special file descriptor to pass to `*at` functions to specify
/// that relative paths are relative to current directory
AT_FDCWD :: Fd(-100)

/// Special value to put into timespec for utimensat() to set timestamp to the current time
UTIME_NOW  :: uint((1 << 30) - 1)

/// Special value to put into the timespec for utimensat() to leave the corresponding field of the timestamp unchanged
UTIME_OMIT :: uint((1 << 30) - 2)

/// For wait4: Pass this pid to wait for any process
WAIT_ANY    :: Pid(-1)

/// For wait4: Pass this pid to wait for any process in current process group
WAIT_MYPGRP :: Pid(0)

/// Maximum priority (aka nice value) for the process
PRIO_MAX :: 20

/// Minimum priority (aka nice value) for the process
PRIO_MIN :: -20

SIGRTMIN :: Signal(32)
SIGRTMAX :: Signal(64)

S_IFMT   :: Mode{.IFREG, .IFDIR, .IFCHR, .IFFIFO}
S_IFSOCK :: Mode{.IFREG, .IFDIR}
S_IFLNK  :: Mode{.IFREG, .IFCHR}
S_IFBLK  :: Mode{.IFDIR, .IFCHR}
S_IFFIFO :: Mode{.IFFIFO}
S_IFCHR  :: Mode{.IFCHR}
S_IFDIR  :: Mode{.IFDIR}
S_IFREG  :: Mode{.IFREG}

/// Checks the Mode bits to see if the file is a named pipe (FIFO)
S_ISFIFO :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFFIFO  == (m & S_IFMT))}

/// Check the Mode bits to see if the file is a character device
S_ISCHR  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFCHR  == (m & S_IFMT))}
    
/// Check the Mode bits to see if the file is a directory
S_ISDIR  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFDIR  == (m & S_IFMT))}

/// Check the Mode bits to see if the file is a register
S_ISREG  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFREG  == (m & S_IFMT))}

/// Check the Mode bits to see if the file is a socket
S_ISSOCK :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFSOCK == (m & S_IFMT))}

/// Check the Mode bits to see if the file is a symlink
S_ISLNK  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFLNK  == (m & S_IFMT))}

/// Check the Mode bits to see if the file is a block device
S_ISBLK  :: #force_inline proc "contextless" (m: Mode) -> bool {return (S_IFBLK  == (m & S_IFMT))}

/// For access.2 syscall family: instruct to check if the file exists
F_OK :: Mode{}

/// For access.2 syscall family: instruct to check if the file is executable
X_OK :: Mode{.IXOTH}

/// For access.2 syscall family: instruct to check if the file is writeable
W_OK :: Mode{.IWOTH}

/// For access.2 syscall family: instruct to check if the file is readable
R_OK :: Mode{.IROTH}

/// The stats you get by calling `stat`
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

/// Wait on futex wakeup signal
FUTEX_WAIT            :: Futex_Wait_Type(.WAIT)

/// Wake up other processes waiting on the futex
FUTEX_WAKE            :: Futex_Wake_Type(.WAKE)

/// Not implemented. Basically, since
FUTEX_FD              :: Futex_Fd_Type(.FD)

/// Requeue waiters from one futex to another
FUTEX_REQUEUE         :: Futex_Requeue_Type(.REQUEUE)

/// Requeue waiters from one futex to another if the value at mutex matches
FUTEX_CMP_REQUEUE     :: Futex_Cmp_Requeue_Type(.CMP_REQUEUE)

/// See man pages, I'm not describing it here
FUTEX_WAKE_OP         :: Futex_Wake_Op_Type(.WAKE_OP)

/// Wait on a futex, but the value is a bitset
FUTEX_WAIT_BITSET     :: Futex_Wait_Bitset_Type(.WAIT_BITSET)

/// Wait on a futex, but the value is a bitset
FUTEX_WAKE_BITSET     :: Futex_Wake_Bitset_Type(.WAKE_BITSET)

// TODO(flysand): Priority inversion futexes
FUTEX_LOCK_PI         :: Futex_Lock_Pi_Type(.LOCK_PI)
FUTEX_UNLOCK_PI       :: Futex_Unlock_Pi_Type(.UNLOCK_PI)
FUTEX_TRYLOCK_PI      :: Futex_Trylock_Pi_Type(.TRYLOCK_PI)
FUTEX_WAIT_REQUEUE_PI :: Futex_Wait_requeue_Pi_Type(.WAIT_REQUEUE_PI)
FUTEX_CMP_REQUEUE_PI  :: Futex_Cmp_requeue_Pi_Type(.CMP_REQUEUE_PI)
FUTEX_LOCK_PI2        :: Futex_Lock_Pi2_Type(.LOCK_PI2)

