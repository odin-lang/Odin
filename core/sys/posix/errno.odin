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
} else {
	#panic("posix is unimplemented for the current target")
}

