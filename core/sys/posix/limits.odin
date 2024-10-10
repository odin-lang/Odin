package posix

// limits.h - implementation-defined constants

// NOTE: numerical limits are left out because Odin provides `min(T)` and `max(T)`.

// The <limits.h> header shall define the following symbolic constants with the values shown.
// These are the most restrictive values for certain features on an implementation.
// A conforming implementation shall provide values no larger than these values.
// A conforming application must not require a smaller value for correct operation.

_POSIX_CLOCKRES_MIN                  :: 20000000

// The <limits.h> header shall define the following symbolic constants with the values shown.
// These are the most restrictive values for certain features on an implementation conforming to
// this volume of POSIX.1-2017.
// Related symbolic constants are defined elsewhere in this volume of POSIX.1-2017 which reflect
// the actual implementation and which need not be as restrictive. For each of these limits,
// a conforming implementation shall provide a value at least this large or shall have no limit.
// A strictly conforming application must not require a larger value for correct operation.

_POSIX_AIO_LISTIO_MAX                :: 2
_POSIX_AIO_MAX                       :: 1
_POSIX_ARG_MAX                       :: 4096
_POSIX_CHILD_MAX                     :: 25
_POSIX_DELAYTIMER_MAX                :: 32
_POSIX_HOST_NAME_MAX                 :: 255
_POSIX_LINK_MAX                      :: 8
_POSIX_MAX_CANON                     :: 255
_POSIX_MAX_INPUT                     :: 255
_POSIX_MQ_OPEN_MAX                   :: 8
_POSIX_MQ_PRIO_MAX                   :: 32
_POSIX_NAME_MAX                      :: 14
_POSIX_NGROUPS_MAX                   :: 8
_POSIX_OPEN_MAX                      :: 20
_POSIX_PATH_MAX                      :: 256
_POSIX_PIPE_BUF                      :: 512
_POSIX_RE_DUP_MAX                    :: 255
_POSIX_RTSIG_MAX                     :: 8
_POSIX_SEM_NSEMS_MAX                 :: 256
_POSIX_SEM_VALUE_MAX                 :: 32767
_POSIX_SS_REPL_MAX                   :: 4
_POSIX_STREAM_MAX                    :: 8
_POSIX_SYMLINK_MAX                   :: 255
_POSIX_SYMLOOP_MAX                   :: 8
_POSIX_THREAD_DESTRUCTION_ITERATIONS :: 4
_POSIX_THREAD_KEYS_MAX               :: 128
_POSIX_THREADS_THREADS_MAX           :: 64
_POSIX_TIMER_MAX                     :: 32
_POSIX_TRAXE_EVENT_NAME_MAX          :: 30
_POSIX_TRACE_NAME_MAX                :: 8
_POSIX_TRACE_SYS_MAX                 :: 8
_POSIX_TRACE_USER_EVENT_MAX          :: 32
_POSIX_TTY_NAME_MAX                  :: 9
_POSIX_TZNAME_MAX                    :: 6
_POSIX2_BC_BASE_MAX                  :: 99
_POSIX2_BC_DIM_MAX                   :: 2048
_POSIX2_BC_SCALE_MAX                 :: 99
_POSIX2_CHARCLASS_NAME_MAX           :: 14
_POSIX2_COLL_WEIGHTS_MAX             :: 2
_POSIX2_EXPR_NEST_MAX                :: 32
_POSIX2_LINE_MAX                     :: 2048
_POSIX2_RE_DUP_MAX                   :: 255
_XOPEN_IOV_MAX                       :: 16
_XOPEN_NAME_MAX                      :: 255
_XOPEN_PATH_MAX                      :: 1024

/*
NOTE: for full portability, usage should look something like:

	page_size: uint
	when #defined(posix.PAGESIZE) {
		page_size = posix.PAGESIZE	
	} else {
		page_size = posix.sysconf(._PAGESIZE)
	}
*/

when ODIN_OS == .Darwin {
	// A definition of one of the symbolic constants in the following list shall be omitted from
	// <limits.h> on specific implementations where the corresponding value is equal to or greater
	// than the stated minimum, but is unspecified.
	//
	// This indetermination might depend on the amount of available memory space on a specific
	// instance of a specific implementation. The actual value supported by a specific instance shall
	// be provided by the sysconf() function.

	// AIO_LISTIO_MAX             :: sysconf(._AIO_LISTIO_MAX)
	// AIO_MAX                    :: sysconf(._AIO_MAX)
	// AIO_PRIO_DELTA_MAX         :: sysconf(._AIO_PRIO_DELTA_MAX)
	ARG_MAX                       :: 1024 * 1024
	// ATEXIT_MAX                 :: sysconf(._ATEXIT_MAX)
	CHILD_MAX                     :: 266
	// DELAYTIMER_MAX             :: sysconf(._DELAYTIMER_MAX)
	// HOST_NAME_MAX              :: sysconf(._HOST_NAME_MAX)
	IOV_MAX                       :: 1024
	// LOGIN_NAME_MAX             :: sysconf(._LOGIN_NAME_MAX)
	// MQ_OPEN_MAX                :: sysconf(._MQ_OPEN_MAX)
	// MQ_PRIO_MAX                :: sysconf(._MQ_PRIO_MAX)
	PAGESIZE                      :: PAGE_SIZE
	PAGE_SIZE                     :: 1 << 12
	PTHREAD_DESTRUCTOR_ITERATIONS :: 4
	PTHREAD_KEYS_MAX              :: 512
	PTHREAD_STACK_MIN             :: 16384 when ODIN_ARCH == .arm64 else 8192
	// RTSIG_MAX                  :: sysconf(._RTSIG_MAX)
	// SEM_NSEMS_MAX              :: sysconf(._SEM_NSEMS_MAX)
	// SEM_VALUE_MAX              :: sysconf(._SEM_VALUE_MAX)
	// SIGQUEUE_MAX               :: sysconf(._SIGQUEUE_MAX)
	// SS_REPL_MAX                :: sysconf(._SS_REPL_MAX)
	// STREAM_MAX                 :: sysconf(._STREAM_MAX)
	// SYMLOOP_MAX                :: sysconf(._SYMLOOP_MAX)
	// TIMER_MAX                  :: sysconf(._TIMER_MAX)
	// TRACE_EVENT_NAME_MAX       :: sysconf(._TRACE_EVENT_NAME_MAX)
	// TRACE_NAME_MAX             :: sysconf(._TRACE_NAME_MAX)
	// TRACE_SYS_MAX              :: sysconf(._TRACE_SYS_MAX)
	// TRACE_USER_EVENT_MAX       :: sysconf(._TRACE_USER_EVENT_MAX)
	// TTY_NAME_MAX               :: sysconf(._TTY_NAME_MAX)
	// TZNAME_MAX                 :: sysconf(._TZNAME_MAX)

	// The values in the following list may be constants within an implementation or may vary from
	// one pathname to another.
	// For example, file systems or directories may have different characteristics.
	//
	// A definition of one of the symbolic constants in the following list shall be omitted from the 
	// <limits.h> header on specific implementations where the corresponding value is equal to or
	// greater than the stated minimum, but where the value can vary depending on the file to which
	// it is applied.
	// The actual value supported for a specific pathname shall be provided by the pathconf() function.

	// FILESIZEBITS             :: pathconf(".", ._FILESIZEBITS)
	LINK_MAX                    :: 32767
	MAX_CANON                   :: 1024
	MAX_INPUT                   :: 1024
	NAME_MAX                    :: 255
	PATH_MAX                    :: 1024
	PIPE_BUF                    :: 512
	// POSIX_ALLOC_SIZE_MIN     :: pathconf("foo.txt", ._POSIX_ALLOC_SIZE_MIN)
	// POSIX_REC_INCR_XFER_SIZE :: pathconf("foo.txt", ._POSIX_REC_INCR_XFER_SIZE)
	// POSIX_REC_MAX_XFER_SIZE  :: pathconf("foo.txt", ._POSIX_REC_MAX_XFER_SIZE)
	// POSIX_REC_MIN_XFER_SIZE  :: pathconf("foo.txt", ._POSIX_REC_MIN_XFER_SIZE)
	// POSIX_REC_XFER_ALIGN     :: pathconf("foo.txt", ._POSIX_REC_XFER_ALIGN)
	// SYMLINK_MAX              :: pathconf(".", ._SYMLINK_MAX)


	// The magnitude limitations in the following list shall be fixed by specific implementations.
	// An application should assume that the value of the symbolic constant defined by <limits.h>
	// in a specific implementation is the minimum that pertains whenever the application is run
	// under that implementation.
	// A specific instance of a specific implementation may increase the value relative to that
	// supplied by <limits.h> for that implementation.
	// The actual value supported by a specific instance shall be provided by the sysconf() function.

	BC_BASE_MAX         :: 99
	BC_DIM_MAX          :: 2048
	BC_SCALE_MAX        :: 99
	BC_STRING_MAX       :: 1000
	CHARCLASS_NAME_MAX  :: 14
	COLL_WEIGHTS_MAX    :: 2
	EXPR_NEST_MAX       :: 2
	LINE_MAX            :: 2048
	NGROUPS_MAX         :: 16
	RE_DUP_MAX          :: 255

	// Other limits.
	
	NL_ARGMAX  :: 9
	NL_LANGMAX :: 14
	NL_MSGMAX  :: 32767
	NL_SETMAX  :: 255
	NL_TEXTMAX :: 2048
	NZERO      :: 20

} else when ODIN_OS == .FreeBSD {
	// A definition of one of the symbolic constants in the following list shall be omitted from
	// <limits.h> on specific implementations where the corresponding value is equal to or greater
	// than the stated minimum, but is unspecified.
	//
	// This indetermination might depend on the amount of available memory space on a specific
	// instance of a specific implementation. The actual value supported by a specific instance shall
	// be provided by the sysconf() function.

	// AIO_LISTIO_MAX             :: sysconf(._AIO_LISTIO_MAX)
	// AIO_MAX                    :: sysconf(._AIO_MAX)
	// AIO_PRIO_DELTA_MAX         :: sysconf(._AIO_PRIO_DELTA_MAX)
	ARG_MAX                       :: 2 * 256 * 1024
	// ATEXIT_MAX                 :: sysconf(._ATEXIT_MAX)
	CHILD_MAX                     :: 40
	// DELAYTIMER_MAX             :: sysconf(._DELAYTIMER_MAX)
	// HOST_NAME_MAX              :: sysconf(._HOST_NAME_MAX)
	IOV_MAX                       :: 1024
	// LOGIN_NAME_MAX             :: sysconf(._LOGIN_NAME_MAX)
	// MQ_OPEN_MAX                :: sysconf(._MQ_OPEN_MAX)
	MQ_PRIO_MAX                   :: 64
	PAGESIZE                      :: PAGE_SIZE
	PAGE_SIZE                     :: 1 << 12
	PTHREAD_DESTRUCTOR_ITERATIONS :: 4
	PTHREAD_KEYS_MAX              :: 256
	PTHREAD_STACK_MIN             :: MINSIGSTKSZ
	// RTSIG_MAX                  :: sysconf(._RTSIG_MAX)
	// SEM_NSEMS_MAX              :: sysconf(._SEM_NSEMS_MAX)
	// SEM_VALUE_MAX              :: sysconf(._SEM_VALUE_MAX)
	// SIGQUEUE_MAX               :: sysconf(._SIGQUEUE_MAX)
	// SS_REPL_MAX                :: sysconf(._SS_REPL_MAX)
	// STREAM_MAX                 :: sysconf(._STREAM_MAX)
	// SYMLOOP_MAX                :: sysconf(._SYMLOOP_MAX)
	// TIMER_MAX                  :: sysconf(._TIMER_MAX)
	// TRACE_EVENT_NAME_MAX       :: sysconf(._TRACE_EVENT_NAME_MAX)
	// TRACE_NAME_MAX             :: sysconf(._TRACE_NAME_MAX)
	// TRACE_SYS_MAX              :: sysconf(._TRACE_SYS_MAX)
	// TRACE_USER_EVENT_MAX       :: sysconf(._TRACE_USER_EVENT_MAX)
	// TTY_NAME_MAX               :: sysconf(._TTY_NAME_MAX)
	// TZNAME_MAX                 :: sysconf(._TZNAME_MAX)

	// The values in the following list may be constants within an implementation or may vary from
	// one pathname to another.
	// For example, file systems or directories may have different characteristics.
	//
	// A definition of one of the symbolic constants in the following list shall be omitted from the 
	// <limits.h> header on specific implementations where the corresponding value is equal to or
	// greater than the stated minimum, but where the value can vary depending on the file to which
	// it is applied.
	// The actual value supported for a specific pathname shall be provided by the pathconf() function.

	// FILESIZEBITS             :: pathconf(".", ._FILESIZEBITS)
	// LINK_MAX                 :: pathconf(foo.txt", ._LINK_MAX)
	MAX_CANON                   :: 255
	MAX_INPUT                   :: 255
	NAME_MAX                    :: 255
	PATH_MAX                    :: 1024
	PIPE_BUF                    :: 512
	// POSIX_ALLOC_SIZE_MIN     :: pathconf("foo.txt", ._POSIX_ALLOC_SIZE_MIN)
	// POSIX_REC_INCR_XFER_SIZE :: pathconf("foo.txt", ._POSIX_REC_INCR_XFER_SIZE)
	// POSIX_REC_MAX_XFER_SIZE  :: pathconf("foo.txt", ._POSIX_REC_MAX_XFER_SIZE)
	// POSIX_REC_MIN_XFER_SIZE  :: pathconf("foo.txt", ._POSIX_REC_MIN_XFER_SIZE)
	// POSIX_REC_XFER_ALIGN     :: pathconf("foo.txt", ._POSIX_REC_XFER_ALIGN)
	// SYMLINK_MAX              :: pathconf(".", ._SYMLINK_MAX)


	// The magnitude limitations in the following list shall be fixed by specific implementations.
	// An application should assume that the value of the symbolic constant defined by <limits.h>
	// in a specific implementation is the minimum that pertains whenever the application is run
	// under that implementation.
	// A specific instance of a specific implementation may increase the value relative to that
	// supplied by <limits.h> for that implementation.
	// The actual value supported by a specific instance shall be provided by the sysconf() function.

	BC_BASE_MAX         :: 99
	BC_DIM_MAX          :: 2048
	BC_SCALE_MAX        :: 99
	BC_STRING_MAX       :: 1000
	CHARCLASS_NAME_MAX  :: 14
	COLL_WEIGHTS_MAX    :: 10
	EXPR_NEST_MAX       :: 32
	LINE_MAX            :: 2048
	NGROUPS_MAX         :: 1023
	RE_DUP_MAX          :: 255

	// Other limits.
	
	NL_ARGMAX  :: 4096
	NL_LANGMAX :: 31
	NL_MSGMAX  :: 32767
	NL_SETMAX  :: 255
	NL_TEXTMAX :: 2048
	NZERO      :: 0

} else when ODIN_OS == .NetBSD {

	// A definition of one of the symbolic constants in the following list shall be omitted from
	// <limits.h> on specific implementations where the corresponding value is equal to or greater
	// than the stated minimum, but is unspecified.
	//
	// This indetermination might depend on the amount of available memory space on a specific
	// instance of a specific implementation. The actual value supported by a specific instance shall
	// be provided by the sysconf() function.

	// AIO_LISTIO_MAX             :: sysconf(._AIO_LISTIO_MAX)
	// AIO_MAX                    :: sysconf(._AIO_MAX)
	// AIO_PRIO_DELTA_MAX         :: sysconf(._AIO_PRIO_DELTA_MAX)
	ARG_MAX                       :: 256 * 1024
	// ATEXIT_MAX                 :: sysconf(._ATEXIT_MAX)
	CHILD_MAX                     :: 160
	// DELAYTIMER_MAX             :: sysconf(._DELAYTIMER_MAX)
	// HOST_NAME_MAX              :: sysconf(._HOST_NAME_MAX)
	IOV_MAX                       :: 1024
	LOGIN_NAME_MAX                :: 17
	MQ_OPEN_MAX                   :: 512
	MQ_PRIO_MAX                   :: 32
	PAGESIZE                      :: PAGE_SIZE
	PAGE_SIZE                     :: 1 << 12
	PTHREAD_DESTRUCTOR_ITERATIONS :: 4
	PTHREAD_KEYS_MAX              :: 256
	// PTHREAD_STACK_MIN          :: sysconf(._THREAD_STACK_MIN)
	// RTSIG_MAX                  :: sysconf(._RTSIG_MAX)
	// SEM_NSEMS_MAX              :: sysconf(._SEM_NSEMS_MAX)
	// SEM_VALUE_MAX              :: sysconf(._SEM_VALUE_MAX)
	// SIGQUEUE_MAX               :: sysconf(._SIGQUEUE_MAX)
	// SS_REPL_MAX                :: sysconf(._SS_REPL_MAX)
	// STREAM_MAX                 :: sysconf(._STREAM_MAX)
	// SYMLOOP_MAX                :: sysconf(._SYMLOOP_MAX)
	// TIMER_MAX                  :: sysconf(._TIMER_MAX)
	// TRACE_EVENT_NAME_MAX       :: sysconf(._TRACE_EVENT_NAME_MAX)
	// TRACE_NAME_MAX             :: sysconf(._TRACE_NAME_MAX)
	// TRACE_SYS_MAX              :: sysconf(._TRACE_SYS_MAX)
	// TRACE_USER_EVENT_MAX       :: sysconf(._TRACE_USER_EVENT_MAX)
	// TTY_NAME_MAX               :: sysconf(._TTY_NAME_MAX)
	// TZNAME_MAX                 :: sysconf(._TZNAME_MAX)

	// The values in the following list may be constants within an implementation or may vary from
	// one pathname to another.
	// For example, file systems or directories may have different characteristics.
	//
	// A definition of one of the symbolic constants in the following list shall be omitted from the 
	// <limits.h> header on specific implementations where the corresponding value is equal to or
	// greater than the stated minimum, but where the value can vary depending on the file to which
	// it is applied.
	// The actual value supported for a specific pathname shall be provided by the pathconf() function.

	// FILESIZEBITS             :: pathconf(".", ._FILESIZEBITS)
	LINK_MAX                    :: 32767
	MAX_CANON                   :: 255
	MAX_INPUT                   :: 255
	NAME_MAX                    :: 511
	PATH_MAX                    :: 1024
	PIPE_BUF                    :: 512
	// POSIX_ALLOC_SIZE_MIN     :: pathconf("foo.txt", ._POSIX_ALLOC_SIZE_MIN)
	// POSIX_REC_INCR_XFER_SIZE :: pathconf("foo.txt", ._POSIX_REC_INCR_XFER_SIZE)
	// POSIX_REC_MAX_XFER_SIZE  :: pathconf("foo.txt", ._POSIX_REC_MAX_XFER_SIZE)
	// POSIX_REC_MIN_XFER_SIZE  :: pathconf("foo.txt", ._POSIX_REC_MIN_XFER_SIZE)
	// POSIX_REC_XFER_ALIGN     :: pathconf("foo.txt", ._POSIX_REC_XFER_ALIGN)
	// SYMLINK_MAX              :: pathconf(".", ._SYMLINK_MAX)


	// The magnitude limitations in the following list shall be fixed by specific implementations.
	// An application should assume that the value of the symbolic constant defined by <limits.h>
	// in a specific implementation is the minimum that pertains whenever the application is run
	// under that implementation.
	// A specific instance of a specific implementation may increase the value relative to that
	// supplied by <limits.h> for that implementation.
	// The actual value supported by a specific instance shall be provided by the sysconf() function.

	BC_BASE_MAX         :: max(i32)
	BC_DIM_MAX          :: 65535
	BC_SCALE_MAX        :: max(i32)
	BC_STRING_MAX       :: max(i32)
	CHARCLASS_NAME_MAX  :: 14
	COLL_WEIGHTS_MAX    :: 2
	EXPR_NEST_MAX       :: 32
	LINE_MAX            :: 2048
	NGROUPS_MAX         :: 16
	RE_DUP_MAX          :: 255

	// Other limits.
	
	NL_ARGMAX  :: 9
	NL_LANGMAX :: 14
	NL_MSGMAX  :: 32767
	NL_SETMAX  :: 255
	NL_TEXTMAX :: 2048
	NZERO      :: 20

} else when ODIN_OS == .OpenBSD {

	// A definition of one of the symbolic constants in the following list shall be omitted from
	// <limits.h> on specific implementations where the corresponding value is equal to or greater
	// than the stated minimum, but is unspecified.
	//
	// This indetermination might depend on the amount of available memory space on a specific
	// instance of a specific implementation. The actual value supported by a specific instance shall
	// be provided by the sysconf() function.

	// AIO_LISTIO_MAX             :: sysconf(._AIO_LISTIO_MAX)
	// AIO_MAX                    :: sysconf(._AIO_MAX)
	// AIO_PRIO_DELTA_MAX         :: sysconf(._AIO_PRIO_DELTA_MAX)
	ARG_MAX                       :: 512 * 1024
	// ATEXIT_MAX                 :: sysconf(._ATEXIT_MAX)
	CHILD_MAX                     :: 80
	// DELAYTIMER_MAX             :: sysconf(._DELAYTIMER_MAX)
	// HOST_NAME_MAX              :: sysconf(._HOST_NAME_MAX)
	IOV_MAX                       :: 1024
	LOGIN_NAME_MAX                :: 32
	MQ_OPEN_MAX                   :: 512
	MQ_PRIO_MAX                   :: 32
	PAGESIZE                      :: PAGE_SIZE
	PAGE_SIZE                     :: 1 << 12
	PTHREAD_DESTRUCTOR_ITERATIONS :: 4
	PTHREAD_KEYS_MAX              :: 256
	PTHREAD_STACK_MIN             :: 1 << 12
	// RTSIG_MAX                  :: sysconf(._RTSIG_MAX)
	// SEM_NSEMS_MAX              :: sysconf(._SEM_NSEMS_MAX)
	SEM_VALUE_MAX                 :: max(u32)
	// SIGQUEUE_MAX               :: sysconf(._SIGQUEUE_MAX)
	// SS_REPL_MAX                :: sysconf(._SS_REPL_MAX)
	// STREAM_MAX                 :: sysconf(._STREAM_MAX)
	SYMLOOP_MAX                   :: 32
	// TIMER_MAX                  :: sysconf(._TIMER_MAX)
	// TRACE_EVENT_NAME_MAX       :: sysconf(._TRACE_EVENT_NAME_MAX)
	// TRACE_NAME_MAX             :: sysconf(._TRACE_NAME_MAX)
	// TRACE_SYS_MAX              :: sysconf(._TRACE_SYS_MAX)
	// TRACE_USER_EVENT_MAX       :: sysconf(._TRACE_USER_EVENT_MAX)
	// TTY_NAME_MAX               :: sysconf(._TTY_NAME_MAX)
	// TZNAME_MAX                 :: sysconf(._TZNAME_MAX)

	// The values in the following list may be constants within an implementation or may vary from
	// one pathname to another.
	// For example, file systems or directories may have different characteristics.
	//
	// A definition of one of the symbolic constants in the following list shall be omitted from the 
	// <limits.h> header on specific implementations where the corresponding value is equal to or
	// greater than the stated minimum, but where the value can vary depending on the file to which
	// it is applied.
	// The actual value supported for a specific pathname shall be provided by the pathconf() function.

	// FILESIZEBITS             :: pathconf(".", ._FILESIZEBITS)
	LINK_MAX                    :: 32767
	MAX_CANON                   :: 255
	MAX_INPUT                   :: 255
	NAME_MAX                    :: 255
	PATH_MAX                    :: 1024
	PIPE_BUF                    :: 512
	// POSIX_ALLOC_SIZE_MIN     :: pathconf("foo.txt", ._POSIX_ALLOC_SIZE_MIN)
	// POSIX_REC_INCR_XFER_SIZE :: pathconf("foo.txt", ._POSIX_REC_INCR_XFER_SIZE)
	// POSIX_REC_MAX_XFER_SIZE  :: pathconf("foo.txt", ._POSIX_REC_MAX_XFER_SIZE)
	// POSIX_REC_MIN_XFER_SIZE  :: pathconf("foo.txt", ._POSIX_REC_MIN_XFER_SIZE)
	// POSIX_REC_XFER_ALIGN     :: pathconf("foo.txt", ._POSIX_REC_XFER_ALIGN)
	SYMLINK_MAX                 :: PATH_MAX


	// The magnitude limitations in the following list shall be fixed by specific implementations.
	// An application should assume that the value of the symbolic constant defined by <limits.h>
	// in a specific implementation is the minimum that pertains whenever the application is run
	// under that implementation.
	// A specific instance of a specific implementation may increase the value relative to that
	// supplied by <limits.h> for that implementation.
	// The actual value supported by a specific instance shall be provided by the sysconf() function.

	BC_BASE_MAX         :: max(i32)
	BC_DIM_MAX          :: 65535
	BC_SCALE_MAX        :: max(i32)
	BC_STRING_MAX       :: max(i32)
	CHARCLASS_NAME_MAX  :: 14
	COLL_WEIGHTS_MAX    :: 2
	EXPR_NEST_MAX       :: 32
	LINE_MAX            :: 2048
	NGROUPS_MAX         :: 16
	RE_DUP_MAX          :: 255

	// Other limits.
	
	NL_ARGMAX  :: 9
	NL_LANGMAX :: 14
	NL_MSGMAX  :: 32767
	NL_SETMAX  :: 255
	NL_TEXTMAX :: 255
	NZERO      :: 20

} else when ODIN_OS == .Linux {

	// A definition of one of the symbolic constants in the following list shall be omitted from
	// <limits.h> on specific implementations where the corresponding value is equal to or greater
	// than the stated minimum, but is unspecified.
	//
	// This indetermination might depend on the amount of available memory space on a specific
	// instance of a specific implementation. The actual value supported by a specific instance shall
	// be provided by the sysconf() function.

	// AIO_LISTIO_MAX             :: sysconf(._AIO_LISTIO_MAX)
	// AIO_MAX                    :: sysconf(._AIO_MAX)
	// AIO_PRIO_DELTA_MAX         :: sysconf(._AIO_PRIO_DELTA_MAX)
	ARG_MAX                       :: 131_072
	// ATEXIT_MAX                 :: sysconf(._ATEXIT_MAX)
	// CHILD_MAX                  :: sysconf(._POSIX_ARG_MAX)
	// DELAYTIMER_MAX             :: sysconf(._DELAYTIMER_MAX)
	// HOST_NAME_MAX              :: sysconf(._HOST_NAME_MAX)
	// IOV_MAX                    :: sysconf(._XOPEN_IOV_MAX)
	// LOGIN_NAME_MAX             :: sysconf(._LOGIN_NAME_MAX)
	// MQ_OPEN_MAX                :: sysconf(._MQ_OPEN_MAX)
	// MQ_PRIO_MAX                :: sysconf(._MQ_PRIO_MAX)
	// PAGESIZE                   :: PAGE_SIZE
	// PAGE_SIZE                  :: sysconf(._PAGE_SIZE)
	PTHREAD_DESTRUCTOR_ITERATIONS :: 4
	// PTHREAD_KEYS_MAX           :: sysconf(._PTHREAD_KEYS_MAX)
	// PTHREAD_STACK_MIN          :: sysconf(._PTHREAD_STACK_MIN)
	// RTSIG_MAX                  :: sysconf(._RTSIG_MAX)
	// SEM_NSEMS_MAX              :: sysconf(._SEM_NSEMS_MAX)
	// SEM_VALUE_MAX              :: sysconf(._SEM_VALUE_MAX)
	// SIGQUEUE_MAX               :: sysconf(._SIGQUEUE_MAX)
	// SS_REPL_MAX                :: sysconf(._SS_REPL_MAX)
	// STREAM_MAX                 :: sysconf(._STREAM_MAX)
	// SYMLOOP_MAX                :: sysconf(._SYSLOOP_MAX)
	// TIMER_MAX                  :: sysconf(._TIMER_MAX)
	// TRACE_EVENT_NAME_MAX       :: sysconf(._TRACE_EVENT_NAME_MAX)
	// TRACE_NAME_MAX             :: sysconf(._TRACE_NAME_MAX)
	// TRACE_SYS_MAX              :: sysconf(._TRACE_SYS_MAX)
	// TRACE_USER_EVENT_MAX       :: sysconf(._TRACE_USER_EVENT_MAX)
	// TTY_NAME_MAX               :: sysconf(._TTY_NAME_MAX)
	// TZNAME_MAX                 :: sysconf(._TZNAME_MAX)

	// The values in the following list may be constants within an implementation or may vary from
	// one pathname to another.
	// For example, file systems or directories may have different characteristics.
	//
	// A definition of one of the symbolic constants in the following list shall be omitted from the 
	// <limits.h> header on specific implementations where the corresponding value is equal to or
	// greater than the stated minimum, but where the value can vary depending on the file to which
	// it is applied.
	// The actual value supported for a specific pathname shall be provided by the pathconf() function.

	// FILESIZEBITS             :: pathconf(".", ._FILESIZEBITS)
	LINK_MAX                    :: 127
	MAX_CANON                   :: 255
	MAX_INPUT                   :: 255
	NAME_MAX                    :: 255
	PATH_MAX                    :: 4096
	PIPE_BUF                    :: 4096
	// POSIX_ALLOC_SIZE_MIN     :: sysconf(._POSIX_ALLOC_SIZE_MIN)
	// POSIX_REC_INCR_XFER_SIZE :: sysconf(._POSIX_REC_INCR_XFER_SIZE)
	// POSIX_REC_MAX_XFER_SIZE  :: sysconf(._POSIX_REC_MAX_XFER_SIZE)
	// POSIX_REC_MIN_XFER_SIZE  :: sysconf(._POSIX_REC_MIN_XFER_SIZE)
	// POSIX_REC_XFER_ALIGN     :: sysconf(._POSIX_REC_XFER_ALIGN)
	// SYMLINK_MAX              :: pathconf(".", ._SYMLINK_MAX)


	// The magnitude limitations in the following list shall be fixed by specific implementations.
	// An application should assume that the value of the symbolic constant defined by <limits.h>
	// in a specific implementation is the minimum that pertains whenever the application is run
	// under that implementation.
	// A specific instance of a specific implementation may increase the value relative to that
	// supplied by <limits.h> for that implementation.
	// The actual value supported by a specific instance shall be provided by the sysconf() function.

	BC_BASE_MAX         :: 99
	BC_DIM_MAX          :: 2048
	BC_SCALE_MAX        :: 99
	BC_STRING_MAX       :: 1000
	CHARCLASS_NAME_MAX  :: 14
	COLL_WEIGHTS_MAX    :: 2
	EXPR_NEST_MAX       :: 32
	// LINE_MAX         :: sysconf(._LINE_MAX)
	// NGROUPS_MAX      :: sysconf(._NGROUPS_MAX)
	RE_DUP_MAX          :: 255

	// Other limits.

	NL_ARGMAX  :: 9
	NL_LANGMAX :: 32 // 14 on glibc, 32 on musl
	NL_MSGMAX  :: 32_767
	NL_SETMAX  :: 255
	NL_TEXTMAX :: 2048 // 255 on glibc, 2048 on musl
	NZERO      :: 20

} else {
	#panic("posix is unimplemented for the current target")
}
