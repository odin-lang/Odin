#+build windows, darwin, linux, freebsd, openbsd, netbsd, haiku
package posix

import "core:c"
import "core:c/libc"

// errno.h - system error numbers

EDOM   :: libc.EDOM
EILSEQ :: libc.EILSEQ
ERANGE :: libc.ERANGE

@(no_instrumentation)
get_errno :: #force_inline proc "contextless" () -> Errno {
	return (^Errno)(libc.errno())^
}

set_errno :: #force_inline proc "contextless" (err: Errno) {
	libc.errno()^ = i32(err)
}

errno :: proc {
	get_errno,
	set_errno,
}

Errno :: enum c.int {
	NONE            = 0,
	EDOM            = EDOM,
	EILSEQ          = EILSEQ,
	ERANGE          = ERANGE,
	E2BIG           = E2BIG,
	EACCES          = EACCES,
	EADDRINUSE      = EADDRINUSE,
	EADDRNOTAVAIL   = EADDRNOTAVAIL,
	EAFNOSUPPORT    = EAFNOSUPPORT,
	EAGAIN          = EAGAIN,
	EALREADY        = EALREADY,
	EBADF           = EBADF,
	EBADMSG         = EBADMSG,
	EBUSY           = EBUSY,
	ECANCELED       = ECANCELED,
	ECHILD          = ECHILD,
	ECONNABORTED    = ECONNABORTED,
	ECONNREFUSED    = ECONNREFUSED,
	ECONNRESET      = ECONNRESET,
	EDEADLK         = EDEADLK,
	EDESTADDRREQ    = EDESTADDRREQ,
	EDQUOT          = EDQUOT,
	EEXIST          = EEXIST,
	EFAULT          = EFAULT,
	EFBIG           = EFBIG,
	EHOSTUNREACH    = EHOSTUNREACH,
	EIDRM           = EIDRM,
	EINPROGRESS     = EINPROGRESS,
	EINTR           = EINTR,
	EINVAL          = EINVAL,
	EIO             = EIO,
	EISCONN         = EISCONN,
	EISDIR          = EISDIR,
	ELOOP           = ELOOP,
	EMFILE          = EMFILE,
	EMLINK          = EMLINK,
	EMSGSIZE        = EMSGSIZE,
	EMULTIHOP       = EMULTIHOP,
	ENAMETOOLONG    = ENAMETOOLONG,
	ENETDOWN        = ENETDOWN,
	ENETRESET       = ENETRESET,
	ENETUNREACH     = ENETUNREACH,
	ENFILE          = ENFILE,
	ENOBUFS         = ENOBUFS,
	ENODATA         = ENODATA,
	ENODEV          = ENODEV,
	ENOENT          = ENOENT,
	ENOEXEC         = ENOEXEC,
	ENOLCK          = ENOLCK,
	ENOLINK         = ENOLINK,
	ENOMEM          = ENOMEM,
	ENOMSG          = ENOMSG,
	ENOPROTOOPT     = ENOPROTOOPT,
	ENOSPC          = ENOSPC,
	ENOSR           = ENOSR,
	ENOSTR          = ENOSTR,
	ENOSYS          = ENOSYS,
	ENOTCONN        = ENOTCONN,
	ENOTDIR         = ENOTDIR,
	ENOTEMPTY       = ENOTEMPTY,
	ENOTRECOVERABLE = ENOTRECOVERABLE,
	ENOTSOCK        = ENOTSOCK,
	ENOTSUP         = ENOTSUP,
	ENOTTY          = ENOTTY,
	ENXIO           = ENXIO,
	EOPNOTSUPP      = EOPNOTSUPP,
	EOVERFLOW       = EOVERFLOW,
	EOWNERDEAD      = EOWNERDEAD,
	EPERM           = EPERM,
	EPIPE           = EPIPE,
	EPROTO          = EPROTO,
	EPROTONOSUPPORT = EPROTONOSUPPORT,
	EPROTOTYPE      = EPROTOTYPE,
	EROFS           = EROFS,
	ESPIPE          = ESPIPE,
	ESRCH           = ESRCH,
	ESTALE          = ESTALE,
	ETIME           = ETIME,
	ETIMEDOUT       = ETIMEDOUT,
	ETXTBSY         = ETXTBSY,
	EWOULDBLOCK     = EWOULDBLOCK,
	EXDEV           = EXDEV,
}

when ODIN_OS == .Darwin {
	EPERM           :: 1
	ENOENT          :: 2
	ESRCH           :: 3
	EINTR           :: 4
	EIO             :: 5
	ENXIO           :: 6
	E2BIG           :: 7
	ENOEXEC         :: 8
	EBADF           :: 9
	ECHILD          :: 10
	EDEADLK         :: 11
	ENOMEM          :: 12
	EACCES          :: 13
	EFAULT          :: 14
	EBUSY           :: 16
	EEXIST          :: 17
	EXDEV           :: 18
	ENODEV          :: 19
	ENOTDIR         :: 20
	EISDIR          :: 21
	EINVAL          :: 22
	ENFILE          :: 23
	EMFILE          :: 24
	ENOTTY          :: 25
	ETXTBSY         :: 26
	EFBIG           :: 27
	ENOSPC          :: 28
	ESPIPE          :: 29
	EROFS           :: 30
	EMLINK          :: 31
	EPIPE           :: 32
	EAGAIN          :: 35
	EWOULDBLOCK     :: EAGAIN
	EINPROGRESS     :: 36
	EALREADY        :: 37
	ENOTSOCK        :: 38
	EDESTADDRREQ    :: 39
	EMSGSIZE        :: 40
	EPROTOTYPE      :: 41
	ENOPROTOOPT     :: 42
	EPROTONOSUPPORT :: 43
	ENOTSUP         :: 45
	EOPNOTSUPP      :: ENOTSUP
	EAFNOSUPPORT    :: 47
	EADDRINUSE      :: 48
	EADDRNOTAVAIL   :: 49
	ENETDOWN        :: 50
	ENETUNREACH     :: 51
	ENETRESET       :: 52
	ECONNABORTED    :: 53
	ECONNRESET      :: 54
	ENOBUFS         :: 55
	EISCONN         :: 56
	ENOTCONN        :: 57
	ETIMEDOUT       :: 60
	ECONNREFUSED    :: 61
	ELOOP           :: 62
	ENAMETOOLONG    :: 63
	EHOSTUNREACH    :: 65
	ENOTEMPTY       :: 66
	EDQUOT          :: 69
	ESTALE          :: 70
	ENOLCK          :: 77
	ENOSYS          :: 78
	EOVERFLOW       :: 84
	ECANCELED       :: 89
	EIDRM           :: 90
	ENOMSG          :: 91
	EBADMSG         :: 94
	EMULTIHOP       :: 95
	ENODATA         :: 96
	ENOLINK         :: 97
	ENOSR           :: 98
	ENOSTR          :: 99
	EPROTO          :: 100
	ETIME           :: 101
	ENOTRECOVERABLE :: 104
	EOWNERDEAD      :: 105
} else when ODIN_OS == .FreeBSD {
	EPERM           :: 1
	ENOENT          :: 2
	ESRCH           :: 3
	EINTR           :: 4
	EIO             :: 5
	ENXIO           :: 6
	E2BIG           :: 7
	ENOEXEC         :: 8
	EBADF           :: 9
	ECHILD          :: 10
	EDEADLK         :: 11
	ENOMEM          :: 12
	EACCES          :: 13
	EFAULT          :: 14
	EBUSY           :: 16
	EEXIST          :: 17
	EXDEV           :: 18
	ENODEV          :: 19
	ENOTDIR         :: 20
	EISDIR          :: 21
	EINVAL          :: 22
	ENFILE          :: 23
	EMFILE          :: 24
	ENOTTY          :: 25
	ETXTBSY         :: 26
	EFBIG           :: 27
	ENOSPC          :: 28
	ESPIPE          :: 29
	EROFS           :: 30
	EMLINK          :: 31
	EPIPE           :: 32
	EAGAIN          :: 35
	EWOULDBLOCK     :: EAGAIN
	EINPROGRESS     :: 36
	EALREADY        :: 37
	ENOTSOCK        :: 38
	EDESTADDRREQ    :: 39
	EMSGSIZE        :: 40
	EPROTOTYPE      :: 41
	ENOPROTOOPT     :: 42
	EPROTONOSUPPORT :: 43
	ENOTSUP         :: 45
	EOPNOTSUPP      :: ENOTSUP
	EAFNOSUPPORT    :: 47
	EADDRINUSE      :: 48
	EADDRNOTAVAIL   :: 49
	ENETDOWN        :: 50
	ENETUNREACH     :: 51
	ENETRESET       :: 52
	ECONNABORTED    :: 53
	ECONNRESET      :: 54
	ENOBUFS         :: 55
	EISCONN         :: 56
	ENOTCONN        :: 57
	ETIMEDOUT       :: 60
	ECONNREFUSED    :: 61
	ELOOP           :: 62
	ENAMETOOLONG    :: 63
	EHOSTUNREACH    :: 65
	ENOTEMPTY       :: 66
	EDQUOT          :: 69
	ESTALE          :: 70
	ENOLCK          :: 77
	ENOSYS          :: 78
	EOVERFLOW       :: 84
	EIDRM           :: 82
	ENOMSG          :: 83
	ECANCELED       :: 85
	EBADMSG         :: 89
	EMULTIHOP       :: 90
	ENOLINK         :: 91
	EPROTO          :: 92
	ENOTRECOVERABLE :: 95
	EOWNERDEAD      :: 96

	// NOTE: not defined for freebsd
	ENODATA         :: -1
	ENOSR           :: -1
	ENOSTR          :: -1
	ETIME           :: -1
} else when ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {
	EPERM           :: 1
	ENOENT          :: 2
	ESRCH           :: 3
	EINTR           :: 4
	EIO             :: 5
	ENXIO           :: 6
	E2BIG           :: 7
	ENOEXEC         :: 8
	EBADF           :: 9
	ECHILD          :: 10
	EDEADLK         :: 11
	ENOMEM          :: 12
	EACCES          :: 13
	EFAULT          :: 14
	EBUSY           :: 16
	EEXIST          :: 17
	EXDEV           :: 18
	ENODEV          :: 19
	ENOTDIR         :: 20
	EISDIR          :: 21
	EINVAL          :: 22
	ENFILE          :: 23
	EMFILE          :: 24
	ENOTTY          :: 25
	ETXTBSY         :: 26
	EFBIG           :: 27
	ENOSPC          :: 28
	ESPIPE          :: 29
	EROFS           :: 30
	EMLINK          :: 31
	EPIPE           :: 32
	EAGAIN          :: 35
	EWOULDBLOCK     :: EAGAIN
	EINPROGRESS     :: 36
	EALREADY        :: 37
	ENOTSOCK        :: 38
	EDESTADDRREQ    :: 39
	EMSGSIZE        :: 40
	EPROTOTYPE      :: 41
	ENOPROTOOPT     :: 42
	EPROTONOSUPPORT :: 43
	ENOTSUP         :: 45
	EOPNOTSUPP      :: ENOTSUP
	EAFNOSUPPORT    :: 47
	EADDRINUSE      :: 48
	EADDRNOTAVAIL   :: 49
	ENETDOWN        :: 50
	ENETUNREACH     :: 51
	ENETRESET       :: 52
	ECONNABORTED    :: 53
	ECONNRESET      :: 54
	ENOBUFS         :: 55
	EISCONN         :: 56
	ENOTCONN        :: 57
	ETIMEDOUT       :: 60
	ECONNREFUSED    :: 61
	ELOOP           :: 62
	ENAMETOOLONG    :: 63
	EHOSTUNREACH    :: 65
	ENOTEMPTY       :: 66
	EDQUOT          :: 69
	ESTALE          :: 70
	ENOLCK          :: 77
	ENOSYS          :: 78

	when ODIN_OS == .NetBSD {
		EOVERFLOW       :: 84
		EIDRM           :: 82
		ENOMSG          :: 83
		ECANCELED       :: 87
		EBADMSG         :: 88
		ENODATA         :: 89
		EMULTIHOP       :: 94
		ENOLINK         :: 95
		EPROTO          :: 96
		ENOTRECOVERABLE :: 98
		EOWNERDEAD      :: 97
		ENOSR           :: 90
		ENOSTR          :: 91
		ETIME           :: 92
	} else {
		EOVERFLOW       :: 87
		EIDRM           :: 89
		ENOMSG          :: 90
		ECANCELED       :: 88
		EBADMSG         :: 92
		EPROTO          :: 95
		ENOTRECOVERABLE :: 93
		EOWNERDEAD      :: 94
		// NOTE: not defined for openbsd
		ENODATA         :: -1
		EMULTIHOP       :: -1
		ENOLINK         :: -1
		ENOSR           :: -1
		ENOSTR          :: -1
		ETIME           :: -1
	}

} else when ODIN_OS == .Linux {
	EPERM           :: 1
	ENOENT          :: 2
	ESRCH           :: 3
	EINTR           :: 4
	EIO             :: 5
	ENXIO           :: 6
	E2BIG           :: 7
	ENOEXEC         :: 8
	EBADF           :: 9
	ECHILD          :: 10
	EAGAIN          :: 11
	EWOULDBLOCK     :: EAGAIN
	ENOMEM          :: 12
	EACCES          :: 13
	EFAULT          :: 14
	EBUSY           :: 16
	EEXIST          :: 17
	EXDEV           :: 18
	ENODEV          :: 19
	ENOTDIR         :: 20
	EISDIR          :: 21
	EINVAL          :: 22
	ENFILE          :: 23
	EMFILE          :: 24
	ENOTTY          :: 25
	ETXTBSY         :: 26
	EFBIG           :: 27
	ENOSPC          :: 28
	ESPIPE          :: 29
	EROFS           :: 30
	EMLINK          :: 31
	EPIPE           :: 32

	EDEADLK         :: 35
	ENAMETOOLONG    :: 36
	ENOLCK          :: 37
	ENOSYS          :: 38
	ENOTEMPTY       :: 39
	ELOOP           :: 40
	ENOMSG          :: 42
	EIDRM           :: 43

	ENOSTR          :: 60
	ENODATA         :: 61
	ETIME           :: 62
	ENOSR           :: 63

	ENOLINK         :: 67

	EPROTO          :: 71
	EMULTIHOP       :: 72
	EBADMSG         :: 74
	EOVERFLOW       :: 75

	ENOTSOCK        :: 88
	EDESTADDRREQ    :: 89
	EMSGSIZE        :: 90
	EPROTOTYPE      :: 91
	ENOPROTOOPT     :: 92
	EPROTONOSUPPORT :: 93

	EOPNOTSUPP      :: 95
	ENOTSUP         :: EOPNOTSUPP
	EAFNOSUPPORT    :: 97
	EADDRINUSE      :: 98
	EADDRNOTAVAIL   :: 99
	ENETDOWN        :: 100
	ENETUNREACH     :: 101
	ENETRESET       :: 102
	ECONNABORTED    :: 103
	ECONNRESET      :: 104
	ENOBUFS         :: 105
	EISCONN         :: 106
	ENOTCONN        :: 107

	ETIMEDOUT       :: 110
	ECONNREFUSED    :: 111

	EHOSTUNREACH    :: 113
	EALREADY        :: 114
	EINPROGRESS     :: 115
	ESTALE          :: 116

	EDQUOT          :: 122
	ECANCELED       :: 125

	EOWNERDEAD      :: 130
	ENOTRECOVERABLE :: 131
} else when ODIN_OS == .Windows {
	E2BIG           :: 7
	EACCES          :: 13
	EADDRINUSE      :: 100
	EADDRNOTAVAIL   :: 101
	EAFNOSUPPORT    :: 102
	EAGAIN          :: 11
	EALREADY        :: 103
	EBADF           :: 9
	EBADMSG         :: 104
	EBUSY           :: 16
	ECANCELED       :: 105
	ECHILD          :: 10
	ECONNABORTED    :: 106
	ECONNREFUSED    :: 107
	ECONNRESET      :: 108
	EDEADLK         :: 36
	EDESTADDRREQ    :: 109
	EDQUOT          :: -1 // NOTE: not defined
	EEXIST          :: 17
	EFAULT          :: 14
	EFBIG           :: 27
	EHOSTUNREACH    :: 110
	EIDRM           :: 111
	EINPROGRESS     :: 112
	EINTR           :: 4
	EINVAL          :: 22
	EIO             :: 5
	EISCONN         :: 113
	EISDIR          :: 21
	ELOOP           :: 114
	EMFILE          :: 24
	EMLINK          :: 31
	EMSGSIZE        :: 115
	EMULTIHOP       :: -1 // NOTE: not defined
	ENAMETOOLONG    :: 38
	ENETDOWN        :: 116
	ENETRESET       :: 117
	ENETUNREACH     :: 118
	ENFILE          :: 23
	ENOBUFS         :: 119
	ENODATA         :: 120
	ENODEV          :: 19
	ENOENT          :: 2
	ENOEXEC         :: 8
	ENOLCK          :: 39
	ENOLINK         :: 121
	ENOMEM          :: 12
	ENOMSG          :: 122
	ENOPROTOOPT     :: 123
	ENOSPC          :: 28
	ENOSR           :: 124
	ENOSTR          :: 125
	ENOSYS          :: 40
	ENOTCONN        :: 126
	ENOTDIR         :: 20
	ENOTEMPTY       :: 41
	ENOTRECOVERABLE :: 127
	ENOTSOCK        :: 128
	ENOTSUP         :: 129
	ENOTTY          :: 25
	ENXIO           :: 6
	EOPNOTSUPP      :: 130
	EOVERFLOW       :: 132
	EOWNERDEAD      :: 133
	EPERM           :: 1
	EPIPE           :: 32
	EPROTO          :: 134
	EPROTONOSUPPORT :: 135
	EPROTOTYPE      :: 136
	EROFS           :: 30
	ESPIPE          :: 29
	ESRCH           :: 3
	ESTALE          :: -1 // NOTE: not defined
	ETIME           :: 137
	ETIMEDOUT       :: 138
	ETXTBSY         :: 139
	EWOULDBLOCK     :: 140
	EXDEV           :: 18
} else when ODIN_OS == .Haiku {
	_HAIKU_USE_POSITIVE_POSIX_ERRORS :: libc._HAIKU_USE_POSITIVE_POSIX_ERRORS
	_POSIX_ERROR_FACTOR              :: libc._POSIX_ERROR_FACTOR
	
	_GENERAL_ERROR_BASE :: min(c.int)
	_OS_ERROR_BASE      :: _GENERAL_ERROR_BASE + 0x1000
	_STORAGE_ERROR_BASE :: _GENERAL_ERROR_BASE + 0x6000
	_POSIX_ERROR_BASE   :: _GENERAL_ERROR_BASE + 0x7000

	EIO             :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 1)     // B_IO_ERROR
	EACCES          :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 2)     // B_PERMISSION_DENIED
	EINVAL          :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 5)     // B_BAD_VALUE
	ETIMEDOUT       :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 9)     // B_TIMED_OUT
	EINTR           :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 10)    // B_INTERRUPTED
	EAGAIN          :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 11)    // B_WOULD_BLOCK /* SysV compatibility */
	EWOULDBLOCK     :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 11)    // B_WOULD_BLOCK /* BSD compatibility */
	EBUSY           :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 14)    // B_BUSY
	EPERM           :: _POSIX_ERROR_FACTOR * (_GENERAL_ERROR_BASE + 15)    // B_NOT_ALLOWED
	EFAULT          :: _POSIX_ERROR_FACTOR * (_OS_ERROR_BASE      + 0x301) // B_BAD_ADDRESS
	ENOEXEC         :: _POSIX_ERROR_FACTOR * (_OS_ERROR_BASE      + 0x302) // B_NOT_AN_EXECUTABLE
	EBADF           :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 0)     // B_FILE_ERROR
	EEXIST          :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 2)     // B_FILE_EXISTS
	ENOENT          :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 3)     // B_ENTRY_NOT_FOUND
	ENAMETOOLONG    :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 4)     // B_NAME_TOO_LONG
	ENOTDIR         :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 5)     // B_NOT_A_DIRECTORY
	ENOTEMPTY       :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 6)     // B_DIRECTORY_NOT_EMPTY
	ENOSPC          :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 7)     // B_DEVICE_FULL
	EROFS           :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 8)     // B_READ_ONLY_DEVICE
	EISDIR          :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 9)     // B_IS_A_DIRECTORY
	EMFILE          :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 10)    // B_NO_MORE_FDS
	EXDEV           :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 11)    // B_CROSS_DEVICE_LINK
	ELOOP           :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 12)    // B_LINK_LIMIT
	EPIPE           :: _POSIX_ERROR_FACTOR * (_STORAGE_ERROR_BASE + 13)    // B_BUSTED_PIPE
	ENOMEM          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 0) when _HAIKU_USE_POSITIVE_POSIX_ERRORS else (_GENERAL_ERROR_BASE + 0) // B_NO_MEMORY
	E2BIG           :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 1)
	ECHILD          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 2)
	EDEADLK         :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 3)
	EFBIG           :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 4)
	EMLINK          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 5)
	ENFILE          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 6)
	ENODEV          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 7)
	ENOLCK          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 8)
	ENOSYS          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 9)
	ENOTTY          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 10)
	ENXIO           :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 11)
	ESPIPE          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 12)
	ESRCH           :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 13)
	EPROTOTYPE      :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 18)
	EPROTONOSUPPORT :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 19)
	EAFNOSUPPORT    :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 21)
	EADDRINUSE      :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 22)
	EADDRNOTAVAIL   :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 23)
	ENETDOWN        :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 24)
	ENETUNREACH     :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 25)
	ENETRESET       :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 26)
	ECONNABORTED    :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 27)
	ECONNRESET      :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 28)
	EISCONN         :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 29)
	ENOTCONN        :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 30)
	ECONNREFUSED    :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 32)
	EHOSTUNREACH    :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 33)
	ENOPROTOOPT     :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 34)
	ENOBUFS         :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 35)
	EINPROGRESS     :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 36)
	EALREADY        :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 37)
	ENOMSG          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 39)
	ESTALE          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 40)
	EOVERFLOW       :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 41)
	EMSGSIZE        :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 42)
	EOPNOTSUPP      :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 43)
	ENOTSOCK        :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 44)
	EBADMSG         :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 46)
	ECANCELED       :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 47)
	EDESTADDRREQ    :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 48)
	EDQUOT          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 49)
	EIDRM           :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 50)
	EMULTIHOP       :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 51)
	ENODATA         :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 52)
	ENOLINK         :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 53)
	ENOSR           :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 54)
	ENOSTR          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 55)
	ENOTSUP         :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 56)
	EPROTO          :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 57)
	ETIME           :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 58)
	ETXTBSY         :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 59)
	ENOTRECOVERABLE :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 61)
	EOWNERDEAD      :: _POSIX_ERROR_FACTOR * (_POSIX_ERROR_BASE   + 62)
}

