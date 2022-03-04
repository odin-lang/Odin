//+private
package os2

EPERM          :: 1
ENOENT         :: 2
ESRCH          :: 3
EINTR          :: 4
EIO            :: 5
ENXIO          :: 6
EBADF          :: 9
EAGAIN         :: 11
ENOMEM         :: 12
EACCES         :: 13
EFAULT         :: 14
EEXIST         :: 17
ENODEV         :: 19
ENOTDIR        :: 20
EISDIR         :: 21
EINVAL         :: 22
ENFILE         :: 23
EMFILE         :: 24
ETXTBSY        :: 26
EFBIG          :: 27
ENOSPC         :: 28
ESPIPE         :: 29
EROFS          :: 30
EPIPE          :: 32
ERANGE         :: 34   /* Result too large */
EDEADLK        :: 35   /* Resource deadlock would occur */
ENAMETOOLONG   :: 36   /* File name too long */
ENOLCK         :: 37   /* No record locks available */
ENOSYS         :: 38   /* Invalid system call number */
ENOTEMPTY      :: 39   /* Directory not empty */
ELOOP          :: 40   /* Too many symbolic links encountered */
EWOULDBLOCK    :: EAGAIN /* Operation would block */
ENOMSG         :: 42   /* No message of desired type */
EIDRM          :: 43   /* Identifier removed */
ECHRNG         :: 44   /* Channel number out of range */
EL2NSYNC       :: 45   /* Level 2 not synchronized */
EL3HLT         :: 46   /* Level 3 halted */
EL3RST         :: 47   /* Level 3 reset */
ELNRNG         :: 48   /* Link number out of range */
EUNATCH        :: 49   /* Protocol driver not attached */
ENOCSI         :: 50   /* No CSI structure available */
EL2HLT         :: 51   /* Level 2 halted */
EBADE          :: 52   /* Invalid exchange */
EBADR          :: 53   /* Invalid request descriptor */
EXFULL         :: 54   /* Exchange full */
ENOANO         :: 55   /* No anode */
EBADRQC        :: 56   /* Invalid request code */
EBADSLT        :: 57   /* Invalid slot */
EDEADLOCK      :: EDEADLK
EBFONT         :: 59   /* Bad font file format */
ENOSTR         :: 60   /* Device not a stream */
ENODATA        :: 61   /* No data available */
ETIME          :: 62   /* Timer expired */
ENOSR          :: 63   /* Out of streams resources */
ENONET         :: 64   /* Machine is not on the network */
ENOPKG         :: 65   /* Package not installed */
EREMOTE        :: 66   /* Object is remote */
ENOLINK        :: 67   /* Link has been severed */
EADV           :: 68   /* Advertise error */
ESRMNT         :: 69   /* Srmount error */
ECOMM          :: 70   /* Communication error on send */
EPROTO         :: 71   /* Protocol error */
EMULTIHOP      :: 72   /* Multihop attempted */
EDOTDOT        :: 73   /* RFS specific error */
EBADMSG        :: 74   /* Not a data message */
EOVERFLOW      :: 75   /* Value too large for defined data type */
ENOTUNIQ       :: 76   /* Name not unique on network */
EBADFD         :: 77   /* File descriptor in bad state */
EREMCHG        :: 78   /* Remote address changed */
ELIBACC        :: 79   /* Can not access a needed shared library */
ELIBBAD        :: 80   /* Accessing a corrupted shared library */
ELIBSCN        :: 81   /* .lib section in a.out corrupted */
ELIBMAX        :: 82   /* Attempting to link in too many shared libraries */
ELIBEXEC       :: 83   /* Cannot exec a shared library directly */
EILSEQ         :: 84   /* Illegal byte sequence */
ERESTART       :: 85   /* Interrupted system call should be restarted */
ESTRPIPE       :: 86   /* Streams pipe error */
EUSERS         :: 87   /* Too many users */
ENOTSOCK       :: 88   /* Socket operation on non-socket */
EDESTADDRREQ   :: 89   /* Destination address required */
EMSGSIZE       :: 90   /* Message too long */
EPROTOTYPE     :: 91   /* Protocol wrong type for socket */
ENOPROTOOPT    :: 92   /* Protocol not available */
EPROTONOSUPPORT:: 93   /* Protocol not supported */
ESOCKTNOSUPPORT:: 94   /* Socket type not supported */
EOPNOTSUPP     :: 95   /* Operation not supported on transport endpoint */
EPFNOSUPPORT   :: 96   /* Protocol family not supported */
EAFNOSUPPORT   :: 97   /* Address family not supported by protocol */
EADDRINUSE     :: 98   /* Address already in use */
EADDRNOTAVAIL  :: 99   /* Cannot assign requested address */
ENETDOWN       :: 100  /* Network is down */
ENETUNREACH    :: 101  /* Network is unreachable */
ENETRESET      :: 102  /* Network dropped connection because of reset */
ECONNABORTED   :: 103  /* Software caused connection abort */
ECONNRESET     :: 104  /* Connection reset by peer */
ENOBUFS        :: 105  /* No buffer space available */
EISCONN        :: 106  /* Transport endpoint is already connected */
ENOTCONN       :: 107  /* Transport endpoint is not connected */
ESHUTDOWN      :: 108  /* Cannot send after transport endpoint shutdown */
ETOOMANYREFS   :: 109  /* Too many references: cannot splice */
ETIMEDOUT      :: 110  /* Connection timed out */
ECONNREFUSED   :: 111  /* Connection refused */
EHOSTDOWN      :: 112  /* Host is down */
EHOSTUNREACH   :: 113  /* No route to host */
EALREADY       :: 114  /* Operation already in progress */
EINPROGRESS    :: 115  /* Operation now in progress */
ESTALE         :: 116  /* Stale file handle */
EUCLEAN        :: 117  /* Structure needs cleaning */
ENOTNAM        :: 118  /* Not a XENIX named type file */
ENAVAIL        :: 119  /* No XENIX semaphores available */
EISNAM         :: 120  /* Is a named type file */
EREMOTEIO      :: 121  /* Remote I/O error */
EDQUOT         :: 122  /* Quota exceeded */
ENOMEDIUM      :: 123  /* No medium found */
EMEDIUMTYPE    :: 124  /* Wrong medium type */
ECANCELED      :: 125  /* Operation Canceled */
ENOKEY         :: 126  /* Required key not available */
EKEYEXPIRED    :: 127  /* Key has expired */
EKEYREVOKED    :: 128  /* Key has been revoked */
EKEYREJECTED   :: 129  /* Key was rejected by service */
EOWNERDEAD     :: 130  /* Owner died */
ENOTRECOVERABLE:: 131  /* State not recoverable */
ERFKILL        :: 132  /* Operation not possible due to RF-kill */
EHWPOISON      :: 133  /* Memory page has hardware error */

_error_string :: proc(errno: i32) -> string {
	if errno == 0 {
		return ""
	}
	return "Error"
}
