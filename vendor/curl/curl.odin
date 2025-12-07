package vendor_curl

import c "core:c/libc"

when ODIN_OS == .Windows {
	@(export, extra_linker_flags="/NODEFAULTLIB:msvcrt")
	foreign import lib {
		"lib/libcurl.lib",
		"system:Advapi32.lib",
		"system:Crypt32.lib",
		"system:Normaliz.lib",
		"system:Secur32.lib",
		"system:Wldap32.lib",
		"system:Ws2_32.lib",
		"system:iphlpapi.lib",
	}
} else when ODIN_OS == .Linux {
	@(export)
	foreign import lib {
		"system:curl",
		"system:mbedtls",
		"system:mbedx509",
		"system:mbedcrypto",
		"system:z",
	}
} else when ODIN_OS == .Darwin {
	@(export)
	foreign import lib {
		"system:curl",
		"system:mbedx509",
		"system:mbedcrypto",
		"system:z",
		"system:SystemConfiguration.framework",
	}
}

off_t :: i64
socklen_t :: c.int

/* This is the global package copyright */
COPYRIGHT :: "Daniel Stenberg, <daniel@haxx.se>."

/* This is the version number of the libcurl package from which this header file origins: */
VERSION :: "8.17.0"

/* The numeric version number is also available "in parts" by using these defines: */
VERSION_MAJOR :: 8
VERSION_MINOR :: 17
VERSION_PATCH :: 0

/*
	This is the numeric version of the libcurl version number, meant for easier
	parsing and comparisons by programs. The LIBCURL_VERSION_NUM define will
	always follow this syntax:

		0xXXYYZZ

	Where XX, YY and ZZ are the main version, release and patch numbers in
	hexadecimal (using 8 bits each). All three numbers are always represented
	using two digits. 1.2 would appear as "0x010200" while version 9.11.7
	appears as "0x090b07".

	This 6-digit (24 bits) hexadecimal number does not show pre-release number,
	and it is always a greater number in a more recent release. It makes
	comparisons with greater than and less than work.

	Note: This define is the full hex number and _does not_ use the
	CURL_VERSION_BITS() macro since curl's own configure script greps for it
	and needs it to contain the full number.
*/
VERSION_NUM :: 0x081100

/*
 * This is the date and time when the full source package was created. The
 * timestamp is not stored in git, as the timestamp is properly set in the
 * tarballs by the maketgz script.
 *
 * The format of the date follows this template:
 *
 * "2007-11-23"
 */
TIMESTAMP :: "2025-11-05"


/* linked-list structure for the CURLOPT_QUOTE option (and other) */
slist :: struct {
	data: [^]byte,
	next: ^slist,
}


CURL   :: struct {}
CURLSH :: struct {}

socket_t :: distinct c.int
SOCKET_BAD :: socket_t(-1)

sslbackend :: enum c.int {
	NONE            = 0,
	OPENSSL         = 1,
	GNUTLS          = 2,
	NSS             = 3,  /* CURL_DEPRECATED(8.3.0, "") */
	OBSOLETE4       = 4,  /* Was QSOSSL. */
	GSKIT           = 5,  /* CURL_DEPRECATED(8.3.0, "") */
	POLARSSL        = 6,  /* CURL_DEPRECATED(7.69.0, "") */
	WOLFSSL         = 7,
	SCHANNEL        = 8,
	SECURETRANSPORT = 9,  /* CURL_DEPRECATED(8.15.0, "") */
	AXTLS           = 10, /* CURL_DEPRECATED(7.61.0, "") */
	MBEDTLS         = 11,
	MESALINK        = 12, /* CURL_DEPRECATED(7.82.0, "") */
	BEARSSL         = 13, /* CURL_DEPRECATED(8.15.0, "") */
	RUSTLS          = 14,


	AWSLC     = OPENSSL,
	BORINGSSL = OPENSSL,
	LIBRESSL  = OPENSSL,
}

/* bits for the CURLOPT_FOLLOWLOCATION option */
FOLLOW_ALL       :: 1 /* generic follow redirects */

/*
	Do not use the custom method in the follow-up request if the HTTP code
	instructs so (301, 302, 303).
*/
FOLLOW_OBEYCODE  :: 2

/* Only use the custom method in the first request, always reset in the next */
FOLLOW_FIRSTONLY :: 3

httppost_flags :: distinct bit_set[httppost_flag; c.long]
httppost_flag :: enum c.long {
	/* specified content is a filename */
	FILENAME    = 0,
	/* specified content is a filename */
	READFILE    = 1,
	/* name is only stored pointer do not free in formfree */
	PTRNAME     = 2,
	/* contents is only stored pointer do not free in formfree */
	PTRCONTENTS = 3,
	/* upload file from buffer */
	BUFFER      = 4,
	/* upload file from pointer contents */
	PTRBUFFER   = 5,
	/* upload file contents by using the regular read callback to get the data and
	   pass the given pointer as custom pointer */
	CALLBACK    = 6,
	/* use size in 'contentlen', added in 7.46.0 */
	LARGE       = 7,
}

HTTPPOST_FILENAME    :: httppost_flags{.FILENAME}
HTTPPOST_READFILE    :: httppost_flags{.READFILE}
HTTPPOST_PTRNAME     :: httppost_flags{.PTRNAME}
HTTPPOST_PTRCONTENTS :: httppost_flags{.PTRCONTENTS}
HTTPPOST_BUFFER      :: httppost_flags{.BUFFER}
HTTPPOST_PTRBUFFER   :: httppost_flags{.PTRBUFFER}
HTTPPOST_CALLBACK    :: httppost_flags{.CALLBACK}
HTTPPOST_LARGE       :: httppost_flags{.LARGE}

httppost :: struct {
	next:           ^httppost,                   /* next entry in the list */
	name:           cstring `fmt:"v,name"`,      /* pointer to allocated name */
	namelength:     c.long,                      /* length of name length */
	contents:       cstring,                     /* pointer to allocated data contents */
	contentslength: c.long,                      /* length of contents field, see also
	                                                CURL_HTTPPOST_LARGE */
	buffer:        [^]byte,                      /* pointer to allocated buffer contents */
	bufferlength:  c.long,                       /* length of buffer field */
	contenttype:   cstring,                      /* Content-Type */
	contentheader: ^slist,                       /* list of extra headers for this form */
	more:          ^httppost,                    /* if one field name has more than one
	                                                file, this link should link to following
	                                                files */
	flags: httppost_flags,                       /* as defined below */



	showfilename: cstring,  /* The filename to show. If not set, the
	                           actual filename will be used (if this
	                           is a file part) */
	userp: rawptr,          /* custom pointer used for
                                   HTTPPOST_CALLBACK posts */
	contentlen: off_t,      /* alternative length of contents
                                   field. Used if CURL_HTTPPOST_LARGE is
                                   set. Added in 7.46.0 */
}

/*
	This is a return code for the progress callback that, when returned, will
	signal libcurl to continue executing the default progress function
*/
PROGRESSFUNC_CONTINUE :: 0x10000001

/*
	This is the CURLOPT_PROGRESSFUNCTION callback prototype. It is now
	considered deprecated but was the only choice up until 7.31.0
*/
progress_callback :: #type proc "c" (clientp: rawptr,
                                     dltotal: f64,
                                     dlnow:   f64,
                                     ultotal: f64,
                                     ulnow:   f64) -> c.int

/*
	This is the CURLOPT_XFERINFOFUNCTION callback prototype. It was introduced
	in 7.32.0, avoids the use of floating point numbers and provides more
	detailed information.
*/
xferinfo_callback :: #type proc "c" (clientp:  rawptr,
                                      dltotal: off_t,
                                      dlnow:   off_t,
                                      ultotal: off_t,
                                      ulnow:   off_t) -> c.int


/* The maximum receive buffer size. */
MAX_READ_SIZE :: 10*1024*1024

/*
	Tests have proven that 20K is a bad buffer size for uploads on Windows,
	while 16K for some odd reason performed a lot better. We do the ifndef
	check to allow this value to easier be changed at build time for those
	who feel adventurous. The practical minimum is about 400 bytes since
	libcurl uses a buffer of this size as a scratch area (unrelated to
	network send operations).
*/
MAX_WRITE_SIZE :: 16384

/*
	The only reason to have a max limit for this is to avoid the risk of a bad
	server feeding libcurl with a never-ending header that will cause reallocs
	infinitely
*/
MAX_HTTP_HEADER :: 100*1024

/*
	This is a magic return code for the write callback that, when returned,
	will signal libcurl to pause receiving on the current transfer.
*/
WRITEFUNC_PAUSE :: 0x10000001

/*
	This is a magic return code for the write callback that, when returned,
	will signal an error from the callback.
*/
WRITEFUNC_ERROR :: 0xFFFFFFFF

write_callback :: #type proc "c" (buffer: [^]byte,
                                  size:   c.size_t,
                                  nitems: c.size_t,
                                  outstream: rawptr) -> c.size_t

/* This callback will be called when a new resolver request is made */
resolver_start_callback :: #type proc "c" (resolver_state: rawptr,
                                           reserved: rawptr, userdata: rawptr) -> c.int


/* enumeration of file types */
filetype :: enum c.int {
	FILE = 0,
	DIRECTORY,
	SYMLINK,
	DEVICE_BLOCK,
	DEVICE_CHAR,
	NAMEDPIPE,
	SOCKET,
	DOOR, /* is possible only on Sun Solaris now */

	UNKNOWN, /* should never occur */
}

finfoflags :: distinct bit_set[finfoflag; c.uint]
finfoflag :: enum c.uint {
	KNOWN_FILENAME   = 0,
	KNOWN_FILETYPE   = 1,
	KNOWN_TIME       = 2,
	KNOWN_PERM       = 3,
	KNOWN_UID        = 4,
	KNOWN_GID        = 5,
	KNOWN_SIZE       = 6,
	KNOWN_HLINKCOUNT = 7,
}

FINFOFLAG_KNOWN_FILENAME   :: finfoflags{.KNOWN_FILENAME}
FINFOFLAG_KNOWN_FILETYPE   :: finfoflags{.KNOWN_FILETYPE}
FINFOFLAG_KNOWN_TIME       :: finfoflags{.KNOWN_TIME}
FINFOFLAG_KNOWN_PERM       :: finfoflags{.KNOWN_PERM}
FINFOFLAG_KNOWN_UID        :: finfoflags{.KNOWN_UID}
FINFOFLAG_KNOWN_GID        :: finfoflags{.KNOWN_GID}
FINFOFLAG_KNOWN_SIZE       :: finfoflags{.KNOWN_SIZE}
FINFOFLAG_KNOWN_HLINKCOUNT :: finfoflags{.KNOWN_HLINKCOUNT}

/* Information about a single file, used when doing FTP wildcard matching */
fileinfo :: struct {
	filename:  cstring,
	filetype:  filetype,
	time:      c.time_t, /* always zero! */
	perm:      c.uint,
	uid:       c.int,
	gid:       c.int,
	size:      off_t,
	hardlinks: c.long,

	strings: struct {
		/* If some of these fields is not NULL, it is a pointer to b_data. */
		time:   cstring,
		perm:   cstring,
		user:   cstring,
		group:  cstring,
		target: cstring, /* pointer to the target filename of a symlink */
	},

	flags: finfoflags,

	/* These are libcurl private struct fields. Previously used by libcurl, so
	they must never be interfered with. */
	b_data: [^]byte,
	b_size: c.size_t,
	b_used: c.size_t,
}

/* return codes for CURLOPT_CHUNK_BGN_FUNCTION */
CHUNK_BGN_FUNC_OK   :: 0
CHUNK_BGN_FUNC_FAIL :: 1 /* tell the lib to end the task */
CHUNK_BGN_FUNC_SKIP :: 2 /* skip this chunk over */

/*
	if splitting of data transfer is enabled, this callback is called before
	download of an individual chunk started. Note that parameter "remains" works
	only for FTP wildcard downloading (for now), otherwise is not used
*/
chunk_bgn_callback :: #type proc "c" (transfer_info: rawptr,
                                      ptr: rawptr,
                                      remains: c.int) -> c.long


/* return codes for CURLOPT_CHUNK_END_FUNCTION */
CHUNK_END_FUNC_OK   :: 0
CHUNK_END_FUNC_FAIL :: 1 /* tell the lib to end the task */



/*
	If splitting of data transfer is enabled this callback is called after
	download of an individual chunk finished.
	Note! After this callback was set then it have to be called FOR ALL chunks.
	Even if downloading of this chunk was skipped in CHUNK_BGN_FUNC.
	This is the reason why we do not need "transfer_info" parameter in this
	callback and we are not interested in "remains" parameter too.
*/
chunk_end_callback :: #type proc "c" (ptr: rawptr) -> c.long

/* return codes for FNMATCHFUNCTION */
FNMATCHFUNC_MATCH   :: 0 /* string corresponds to the pattern */
FNMATCHFUNC_NOMATCH :: 1 /* pattern does not match the string */
FNMATCHFUNC_FAIL    :: 2 /* an error occurred */

/*
	callback type for wildcard downloading pattern matching. If the
	string matches the pattern, return CURL_FNMATCHFUNC_MATCH value, etc.
*/
fnmatch_callback :: #type proc "c" (ptr: rawptr,
                                    pattern: cstring,
                                    string:  cstring) -> c.int

/* These are the return codes for the seek callbacks */
SEEKFUNC_OK       :: 0
SEEKFUNC_FAIL     :: 1 /* fail the entire transfer */
SEEKFUNC_CANTSEEK :: 2 /* tell libcurl seeking cannot be done, so
                          libcurl might try other means instead */

seek_callback :: #type proc "c" (instream: rawptr,
                                 offset:   off_t,
                                 origin:   c.int) -> c.int /* 'whence' */

/*
	This is a return code for the read callback that, when returned, will
	signal libcurl to immediately abort the current transfer.
*/
READFUNC_ABORT :: 0x10000000
/*
	This is a return code for the read callback that, when returned, will
	signal libcurl to pause sending data on the current transfer.
*/
READFUNC_PAUSE :: 0x10000001

/*  Return code for when the trailing headers' callback has terminated without any errors */
TRAILERFUNC_OK :: 0
/*
	Return code for when was an error in the trailing header's list and we
	want to abort the request
*/
TRAILERFUNC_ABORT :: 1

read_callback :: #type proc "c" (buffer:   [^]byte,
                           size:     c.size_t,
                           nitems:   c.size_t,
                           instream: rawptr) -> c.size_t

trailer_callback :: #type proc "c" (list: ^^slist,
                                    userdata: rawptr) -> c.int

socktype :: enum c.int {
	IPCXN,  /* socket created for a specific IP connection */
	ACCEPT, /* socket created by accept() call */
	LAST,   /* never use */
}

/*
	The return code from the sockopt_callback can signal information back
	to libcurl:
*/
SOCKOPT_OK    :: 0
SOCKOPT_ERROR :: 1 /* causes libcurl to abort and return
                      CURLE_ABORTED_BY_CALLBACK */
SOCKOPT_ALREADY_CONNECTED :: 2

sockopt_callback :: #type proc "c" (clientp: rawptr,
                                    curlfd:  socket_t,
                                    purpose: socktype) -> c.int

sockaddr :: struct {
	family:   c.int,
	socktype: c.int,
	protocol: c.int,
	addrlen: c.uint, /* addrlen was a socklen_t type before 7.18.0 but it
                           turned really ugly and painful on the systems that
                           lack this type */
	addr: platform_sockaddr,
}


opensocket_callback :: #type proc "c" (clientp: rawptr,
                                       purpose: socktype,
                                       address: ^sockaddr) -> socket_t

closesocket_callback :: #type proc "c" (clientp: rawptr, item: socket_t) -> c.int

ioerr :: enum c.int {
	E_OK,            /* I/O operation successful */
	E_UNKNOWNCMD,    /* command was unknown to callback */
	E_FAILRESTART,   /* failed to restart the read */
}

iocmd :: enum c.int {
	NOP,         /* no operation */
	RESTARTREAD, /* restart the read stream from start */
}

ioctl_callback :: #type proc "c" (handle: ^CURL,
                                  cmd: c.int,
                                  clientp: rawptr) -> ioerr

/*
 * The following typedef's are signatures of malloc, free, realloc, strdup and
 * calloc respectively. Function pointers of these types can be passed to the
 * curl_global_init_mem() function to set user defined memory management
 * callback routines.
 */
malloc_callback  :: #type proc "c" (size: c.size_t) -> rawptr
free_callback    :: #type proc "c" (ptr: rawptr)
realloc_callback :: #type proc "c" (ptr: rawptr, size: c.size_t) -> rawptr
strdup_callback  :: #type proc "c" (str: cstring) -> cstring
calloc_callback  :: #type proc "c" (nmemb, size: c.size_t) -> rawptr

/* the kind of data that is passed to information_callback */
infotype :: enum c.int {
	TEXT = 0,
	HEADER_IN,    /* 1 */
	HEADER_OUT,   /* 2 */
	DATA_IN,      /* 3 */
	DATA_OUT,     /* 4 */
	SSL_DATA_IN,  /* 5 */
	SSL_DATA_OUT, /* 6 */
	END,
}

debug_callback :: #type proc "c"(
	handle:  ^CURL,    /* the handle/transfer this concerns */
        type:    infotype, /* what kind of data */
        data:    [^]byte,  /* points to the data */
        size:    c.size_t, /* size of the data pointed to */
        userptr: rawptr,   /* whatever the user please */
) -> c.int

/* This is the CURLOPT_PREREQFUNCTION callback prototype. */
prereq_callback :: #type proc "c" (clientp: rawptr,
                                   conn_primary_ip: cstring,
                                   conn_local_ip:   cstring,
                                   conn_primary_port: c.int,
                                   conn_local_port:   c.int) -> c.int

/*  Return code for when the pre-request callback has terminated without any errors */
PREREQFUNC_OK :: 0
/* Return code for when the pre-request callback wants to abort the request */
PREREQFUNC_ABORT :: 1

/*
	All possible error codes from all sorts of curl functions. Future versions
	may return other values, stay prepared.

	Always add new return codes last. Never *EVER* remove any. The return
	codes must remain the same!
 */
code :: enum c.int {
	E_OK = 0,
	E_UNSUPPORTED_PROTOCOL,    /* 1 */
	E_FAILED_INIT,             /* 2 */
	E_URL_MALFORMAT,           /* 3 */
	E_NOT_BUILT_IN,            /* 4 - [was obsoleted in August 2007 for
                                    7.17.0, reused in April 2011 for 7.21.5] */
	E_COULDNT_RESOLVE_PROXY,   /* 5 */
	E_COULDNT_RESOLVE_HOST,    /* 6 */
	E_COULDNT_CONNECT,         /* 7 */
	E_WEIRD_SERVER_REPLY,      /* 8 */
	E_REMOTE_ACCESS_DENIED,    /* 9 a service was denied by the server
                                    due to lack of access - when login fails
                                    this is not returned. */
	E_FTP_ACCEPT_FAILED,       /* 10 - [was obsoleted in April 2006 for
                                    7.15.4, reused in Dec 2011 for 7.24.0]*/
	E_FTP_WEIRD_PASS_REPLY,    /* 11 */
	E_FTP_ACCEPT_TIMEOUT,      /* 12 - timeout occurred accepting server
                                    [was obsoleted in August 2007 for 7.17.0,
                                    reused in Dec 2011 for 7.24.0]*/
	E_FTP_WEIRD_PASV_REPLY,    /* 13 */
	E_FTP_WEIRD_227_FORMAT,    /* 14 */
	E_FTP_CANT_GET_HOST,       /* 15 */
	E_HTTP2,                   /* 16 - A problem in the http2 framing layer.
                                    [was obsoleted in August 2007 for 7.17.0,
                                    reused in July 2014 for 7.38.0] */
	E_FTP_COULDNT_SET_TYPE,    /* 17 */
	E_PARTIAL_FILE,            /* 18 */
	E_FTP_COULDNT_RETR_FILE,   /* 19 */
	E_OBSOLETE20,              /* 20 - NOT USED */
	E_QUOTE_ERROR,             /* 21 - quote command failure */
	E_HTTP_RETURNED_ERROR,     /* 22 */
	E_WRITE_ERROR,             /* 23 */
	E_OBSOLETE24,              /* 24 - NOT USED */
	E_UPLOAD_FAILED,           /* 25 - failed upload "command" */
	E_READ_ERROR,              /* 26 - could not open/read from file */
	E_OUT_OF_MEMORY,           /* 27 */
	E_OPERATION_TIMEDOUT,      /* 28 - the timeout time was reached */
	E_OBSOLETE29,              /* 29 - NOT USED */
	E_FTP_PORT_FAILED,         /* 30 - FTP PORT operation failed */
	E_FTP_COULDNT_USE_REST,    /* 31 - the REST command failed */
	E_OBSOLETE32,              /* 32 - NOT USED */
	E_RANGE_ERROR,             /* 33 - RANGE "command" did not work */
	E_OBSOLETE34,              /* 34 */
	E_SSL_CONNECT_ERROR,       /* 35 - wrong when connecting with SSL */
	E_BAD_DOWNLOAD_RESUME,     /* 36 - could not resume download */
	E_FILE_COULDNT_READ_FILE,  /* 37 */
	E_LDAP_CANNOT_BIND,        /* 38 */
	E_LDAP_SEARCH_FAILED,      /* 39 */
	E_OBSOLETE40,              /* 40 - NOT USED */
	E_OBSOLETE41,              /* 41 - NOT USED starting with 7.53.0 */
	E_ABORTED_BY_CALLBACK,     /* 42 */
	E_BAD_FUNCTION_ARGUMENT,   /* 43 */
	E_OBSOLETE44,              /* 44 - NOT USED */
	E_INTERFACE_FAILED,        /* 45 - CURLOPT_INTERFACE failed */
	E_OBSOLETE46,              /* 46 - NOT USED */
	E_TOO_MANY_REDIRECTS,      /* 47 - catch endless re-direct loops */
	E_UNKNOWN_OPTION,          /* 48 - User specified an unknown option */
	E_SETOPT_OPTION_SYNTAX,    /* 49 - Malformed setopt option */
	E_OBSOLETE50,              /* 50 - NOT USED */
	E_OBSOLETE51,              /* 51 - NOT USED */
	E_GOT_NOTHING,             /* 52 - when this is a specific error */
	E_SSL_ENGINE_NOTFOUND,     /* 53 - SSL crypto engine not found */
	E_SSL_ENGINE_SETFAILED,    /* 54 - can not set SSL crypto engine as
                                    default */
	E_SEND_ERROR,              /* 55 - failed sending network data */
	E_RECV_ERROR,              /* 56 - failure in receiving network data */
	E_OBSOLETE57,              /* 57 - NOT IN USE */
	E_SSL_CERTPROBLEM,         /* 58 - problem with the local certificate */
	E_SSL_CIPHER,              /* 59 - could not use specified cipher */
	E_PEER_FAILED_VERIFICATION, /* 60 - peer's certificate or fingerprint
                                     was not verified fine */
	E_BAD_CONTENT_ENCODING,    /* 61 - Unrecognized/bad encoding */
	E_OBSOLETE62,              /* 62 - NOT IN USE since 7.82.0 */
	E_FILESIZE_EXCEEDED,       /* 63 - Maximum file size exceeded */
	E_USE_SSL_FAILED,          /* 64 - Requested FTP SSL level failed */
	E_SEND_FAIL_REWIND,        /* 65 - Sending the data requires a rewind
                                    that failed */
	E_SSL_ENGINE_INITFAILED,   /* 66 - failed to initialise ENGINE */
	E_LOGIN_DENIED,            /* 67 - user, password or similar was not
                                    accepted and we failed to login */
	E_TFTP_NOTFOUND,           /* 68 - file not found on server */
	E_TFTP_PERM,               /* 69 - permission problem on server */
	E_REMOTE_DISK_FULL,        /* 70 - out of disk space on server */
	E_TFTP_ILLEGAL,            /* 71 - Illegal TFTP operation */
	E_TFTP_UNKNOWNID,          /* 72 - Unknown transfer ID */
	E_REMOTE_FILE_EXISTS,      /* 73 - File already exists */
	E_TFTP_NOSUCHUSER,         /* 74 - No such user */
	E_OBSOLETE75,              /* 75 - NOT IN USE since 7.82.0 */
	E_OBSOLETE76,              /* 76 - NOT IN USE since 7.82.0 */
	E_SSL_CACERT_BADFILE,      /* 77 - could not load CACERT file, missing
                                    or wrong format */
	E_REMOTE_FILE_NOT_FOUND,   /* 78 - remote file not found */
	E_SSH,                     /* 79 - error from the SSH layer, somewhat
                                    generic so the error message will be of
                                    interest when this has happened */

	E_SSL_SHUTDOWN_FAILED,     /* 80 - Failed to shut down the SSL
                                    connection */
	E_AGAIN,                   /* 81 - socket is not ready for send/recv,
                                    wait till it is ready and try again (Added
                                    in 7.18.2) */
	E_SSL_CRL_BADFILE,         /* 82 - could not load CRL file, missing or
                                    wrong format (Added in 7.19.0) */
	E_SSL_ISSUER_ERROR,        /* 83 - Issuer check failed.  (Added in
                                    7.19.0) */
	E_FTP_PRET_FAILED,         /* 84 - a PRET command failed */
	E_RTSP_CSEQ_ERROR,         /* 85 - mismatch of RTSP CSeq numbers */
	E_RTSP_SESSION_ERROR,      /* 86 - mismatch of RTSP Session Ids */
	E_FTP_BAD_FILE_LIST,       /* 87 - unable to parse FTP file list */
	E_CHUNK_FAILED,            /* 88 - chunk callback reported error */
	E_NO_CONNECTION_AVAILABLE, /* 89 - No connection available, the
                                    session will be queued */
	E_SSL_PINNEDPUBKEYNOTMATCH, /* 90 - specified pinned public key did not
                                     match */
	E_SSL_INVALIDCERTSTATUS,   /* 91 - invalid certificate status */
	E_HTTP2_STREAM,            /* 92 - stream error in HTTP/2 framing layer
                                    */
	E_RECURSIVE_API_CALL,      /* 93 - an api function was called from
                                    inside a callback */
	E_AUTH_ERROR,              /* 94 - an authentication function returned an
                                    error */
	E_HTTP3,                   /* 95 - An HTTP/3 layer problem */
	E_QUIC_CONNECT_ERROR,      /* 96 - QUIC connection error */
	E_PROXY,                   /* 97 - proxy handshake error */
	E_SSL_CLIENTCERT,          /* 98 - client-side certificate required */
	E_UNRECOVERABLE_POLL,      /* 99 - poll/select returned fatal error */
	E_TOO_LARGE,               /* 100 - a value/data met its maximum */
	E_ECH_REQUIRED,            /* 101 - ECH tried but failed */
}

/*
 * Proxy error codes. Returned in CURLINFO_PROXY_ERROR if CURLE_PROXY was
 * return for the transfers.
 */
proxycode :: enum c.int {
	OK,
	BAD_ADDRESS_TYPE,
	BAD_VERSION,
	CLOSED,
	GSSAPI,
	GSSAPI_PERMSG,
	GSSAPI_PROTECTION,
	IDENTD,
	IDENTD_DIFFER,
	LONG_HOSTNAME,
	LONG_PASSWD,
	LONG_USER,
	NO_AUTH,
	RECV_ADDRESS,
	RECV_AUTH,
	RECV_CONNECT,
	RECV_REQACK,
	REPLY_ADDRESS_TYPE_NOT_SUPPORTED,
	REPLY_COMMAND_NOT_SUPPORTED,
	REPLY_CONNECTION_REFUSED,
	REPLY_GENERAL_SERVER_FAILURE,
	REPLY_HOST_UNREACHABLE,
	REPLY_NETWORK_UNREACHABLE,
	REPLY_NOT_ALLOWED,
	REPLY_TTL_EXPIRED,
	REPLY_UNASSIGNED,
	REQUEST_FAILED,
	RESOLVE_HOST,
	SEND_AUTH,
	SEND_CONNECT,
	SEND_REQUEST,
	UNKNOWN_FAIL,
	UNKNOWN_MODE,
	USER_REJECTED,
}

/* This prototype applies to all conversion callbacks */
conv_callback :: #type proc "c"(buffer: [^]byte, length: c.size_t) -> code

ssl_ctx_callback :: #type proc "c" (curl: ^CURL,    /* easy handle */
                                    ssl_ctx: rawptr, /* actually an OpenSSL
                                                        or wolfSSL SSL_CTX,
                                                        or an mbedTLS
                                                        mbedtls_ssl_config */
                                    userptr: rawptr) -> code

proxytype :: enum c.int {
	HTTP = 0,            /* added in 7.10, new in 7.19.4 default is to use
	                        CONNECT HTTP/1.1 */
	HTTP_1_0 = 1,        /* added in 7.19.4, force to use CONNECT
                               HTTP/1.0  */
	HTTPS = 2,           /* HTTPS but stick to HTTP/1 added in 7.52.0 */
	HTTPS2 = 3,          /* HTTPS and attempt HTTP/2 added in 8.2.0 */
	SOCKS4 = 4,          /* support added in 7.15.2, enum existed already
	                        in 7.10 */
	SOCKS5 = 5,          /* added in 7.10 */
	SOCKS4A = 6,         /* added in 7.18.0 */
	SOCKS5_HOSTNAME = 7, /* Use the SOCKS5 protocol but pass along the
	                        hostname rather than the IP address. added
	                        in 7.18.0 */
} /* this enum was added in 7.10 */

/*
 * Bitmasks for CURLOPT_HTTPAUTH and CURLOPT_PROXYAUTH options:
 *
 * CURLAUTH_NONE         - No HTTP authentication
 * CURLAUTH_BASIC        - HTTP Basic authentication (default)
 * CURLAUTH_DIGEST       - HTTP Digest authentication
 * CURLAUTH_NEGOTIATE    - HTTP Negotiate (SPNEGO) authentication
 * CURLAUTH_GSSNEGOTIATE - Alias for CURLAUTH_NEGOTIATE (deprecated)
 * CURLAUTH_NTLM         - HTTP NTLM authentication
 * CURLAUTH_DIGEST_IE    - HTTP Digest authentication with IE flavour
 * CURLAUTH_NTLM_WB      - HTTP NTLM authentication delegated to winbind helper
 * CURLAUTH_BEARER       - HTTP Bearer token authentication
 * CURLAUTH_ONLY         - Use together with a single other type to force no
 *                         authentication or just that single type
 * CURLAUTH_ANY          - All fine types set
 * CURLAUTH_ANYSAFE      - All fine types except Basic
 */

AUTH_NONE         :: (c.ulong)(0)
AUTH_BASIC        :: ((c.ulong)(1))<<0
AUTH_DIGEST       :: ((c.ulong)(1))<<1
AUTH_NEGOTIATE    :: ((c.ulong)(1))<<2
/* Deprecated since the advent of CURLAUTH_NEGOTIATE */
AUTH_GSSNEGOTIATE :: AUTH_NEGOTIATE
/* Used for CURLOPT_SOCKS5_AUTH to stay terminologically correct */
AUTH_GSSAPI       :: AUTH_NEGOTIATE
AUTH_NTLM         :: ((c.ulong)(1))<<3
AUTH_DIGEST_IE    :: ((c.ulong)(1))<<4

AUTH_BEARER       :: ((c.ulong)(1))<<6
AUTH_AWS_SIGV4    :: ((c.ulong)(1))<<7
AUTH_ONLY         :: ((c.ulong)(1))<<31
AUTH_ANY          :: ~AUTH_DIGEST_IE
AUTH_ANYSAFE      :: ~(AUTH_BASIC|AUTH_DIGEST_IE)

SSH_AUTH_ANY       :: ~c.int(0)     /* all types supported by the server */
SSH_AUTH_NONE      :: 0      /* none allowed, silly but complete */
SSH_AUTH_PUBLICKEY :: (1<<0) /* public/private key files */
SSH_AUTH_PASSWORD  :: (1<<1) /* password */
SSH_AUTH_HOST      :: (1<<2) /* host key files */
SSH_AUTH_KEYBOARD  :: (1<<3) /* keyboard interactive */
SSH_AUTH_AGENT     :: (1<<4) /* agent (ssh-agent, pageant...) */
SSH_AUTH_GSSAPI    :: (1<<5) /* gssapi (kerberos, ...) */
SSH_AUTH_DEFAULT   :: SSH_AUTH_ANY

GSSAPI_DELEGATION_NONE        :: 0      /* no delegation (default) */
GSSAPI_DELEGATION_POLICY_FLAG :: (1<<0) /* if permitted by policy */
GSSAPI_DELEGATION_FLAG        :: (1<<1) /* delegate always */

ERROR_SIZE :: 256

khtype :: enum c.int {
	UNKNOWN,
	RSA1,
	RSA,
	DSS,
	ECDSA,
	ED25519,
}

khkey :: struct {
	key: cstring, /* points to a null-terminated string encoded with base64
	                 if len is zero, otherwise to the "raw" data */
	len: c.size_t,
	keytype: khtype,
}

/* this is the set of return values expected from the curl_sshkeycallback
   callback */
khstat :: enum c.int {
	FINE_ADD_TO_FILE,
	FINE,
	REJECT, /* reject the connection, return an error */
	DEFER,  /* do not accept it, but we cannot answer right now.
	           Causes a CURLE_PEER_FAILED_VERIFICATION error but the
	           connection will be left intact etc */
	FINE_REPLACE, /* accept and replace the wrong key */
}

/* this is the set of status codes pass in to the callback */
khmatch :: enum c.int {
	OK,       /* match */
	MISMATCH, /* host found, key mismatch! */
	MISSING,  /* no matching host/key found */
}

sshkeycallback :: #type proc "c" (easy: ^CURL,              /* easy handle */
                                  knownkey: ^khkey,         /* known */
                                  foundkey: ^khkey,         /* found */
                                  _: khmatch,               /* libcurl's view on the keys */
                                  clientp: rawptr) -> c.int /* custom pointer passed with */
                                                            /* CURLOPT_SSH_KEYDATA */

sshhostkeycallback :: #type proc "c" (clientp: rawptr,   /* custom pointer passed */
                                                         /* with CURLOPT_SSH_HOSTKEYDATA */
                                      keytype: c.int,    /* CURLKHTYPE */
                                      key:     cstring,  /* hostkey to check */
                                      keylen:  c.size_t, /* length of the key */
                                      ) -> code          /* return CURLE_OK to accept */
                                                         /* or something else to refuse */


/* parameter for the CURLOPT_USE_SSL option */
USESSL_NONE    :: 0 /* do not attempt to use SSL */
USESSL_TRY     :: 1 /* try using SSL, proceed anyway otherwise */
USESSL_CONTROL :: 2 /* SSL for the control connection or fail */
USESSL_ALL     :: 3 /* SSL for all communication or fail */

usessl :: enum c.int {
}

/* Definition of bits for the CURLOPT_SSL_OPTIONS argument: */

/*
	- ALLOW_BEAST tells libcurl to allow the BEAST SSL vulnerability in the
	name of improving interoperability with older servers. Some SSL libraries
	have introduced work-arounds for this flaw but those work-arounds sometimes
	make the SSL communication fail. To regain functionality with those broken
	servers, a user can this way allow the vulnerability back.
*/
SSLOPT_ALLOW_BEAST :: 1<<0

/*
	- NO_REVOKE tells libcurl to disable certificate revocation checks for those
	SSL backends where such behavior is present.
*/
SSLOPT_NO_REVOKE :: 1<<1

/*
	- NO_PARTIALCHAIN tells libcurl to *NOT* accept a partial certificate chain
	if possible. The OpenSSL backend has this ability.
*/
SSLOPT_NO_PARTIALCHAIN :: 1<<2

/*
	- REVOKE_BEST_EFFORT tells libcurl to ignore certificate revocation offline
	checks and ignore missing revocation list for those SSL backends where such
	behavior is present.
*/
SSLOPT_REVOKE_BEST_EFFORT :: 1<<3

/*
	- CURLSSLOPT_NATIVE_CA tells libcurl to use standard certificate store of
	operating system. Currently implemented under MS-Windows.
*/
SSLOPT_NATIVE_CA :: 1<<4

/*
	- CURLSSLOPT_AUTO_CLIENT_CERT tells libcurl to automatically locate and use
	a client certificate for authentication. (Schannel)
*/
SSLOPT_AUTO_CLIENT_CERT :: 1<<5

/* If possible, send data using TLS 1.3 early data */
SSLOPT_EARLYDATA :: 1<<6

/*
	The default connection attempt delay in milliseconds for happy eyeballs.
	CURLOPT_HAPPY_EYEBALLS_TIMEOUT_MS.3 and happy-eyeballs-timeout-ms.d document
	this value, keep them in sync.
*/
HET_DEFAULT :: 200

/* The default connection upkeep interval in milliseconds. */
UPKEEP_INTERVAL_DEFAULT :: 60000

/* parameter for the CURLOPT_FTP_SSL_CCC option */
ftpccc :: enum c.int {
	NONE,    /* do not send CCC */
	PASSIVE, /* Let the server initiate the shutdown */
	ACTIVE,  /* Initiate the shutdown */
}

/* parameter for the CURLOPT_FTPSSLAUTH option */
ftpauth :: enum c.int {
	DEFAULT, /* let libcurl decide */
	SSL,     /* use "AUTH SSL" */
	TLS,     /* use "AUTH TLS" */
}

/* parameter for the CURLOPT_FTP_CREATE_MISSING_DIRS option */
ftpcreatedir :: enum c.int {
	DIR_NONE, /* do NOT create missing dirs! */
	DIR, /* (FTP/SFTP) if CWD fails, try MKD and then CWD
                again if MKD succeeded, for SFTP this does
                similar magic */
	_RETRY, /* (FTP only) if CWD fails, try MKD and then CWD
                   again even if MKD failed! */
}

/* parameter for the CURLOPT_FTP_FILEMETHOD option */
ftpmethod :: enum c.int {
	DEFAULT,   /* let libcurl pick */
	MULTICWD,  /* single CWD operation for each path part */
	NOCWD,     /* no CWD at all */
	SINGLECWD, /* one CWD to full dir, then work on file */
}

/* bitmask defines for CURLOPT_HEADEROPT */
HEADER_UNIFIED  ::  0
HEADER_SEPARATE :: 1<<0

/* CURLALTSVC_* are bits for the CURLOPT_ALTSVC_CTRL option */
ALTSVC_READONLYFILE :: 1<<2
ALTSVC_H1           :: 1<<3
ALTSVC_H2           :: 1<<4
ALTSVC_H3           :: 1<<5

/* bitmask values for CURLOPT_UPLOAD_FLAGS */
ULFLAG_ANSWERED :: 1<<0
ULFLAG_DELETED  :: 1<<1
ULFLAG_DRAFT    :: 1<<2
ULFLAG_FLAGGED  :: 1<<3
ULFLAG_SEEN     :: 1<<4

hstsentry :: struct {
	name: cstring,
	namelen: c.size_t,
	using _: bit_field c.uint {
		includeSubDomains: bool | 1,
	},
	expire: [18]byte, /* YYYYMMDD HH:MM:SS [null-terminated] */
}

index :: struct {
	index: c.size_t, /* the provided entry's "index" or count */
	total: c.size_t, /* total number of entries to save */
}

STScode :: enum c.int {
	OK,
	DONE,
	FAIL,
}

hstsread_callback :: #type proc "c" (easy: ^CURL,
                                     e: ^hstsentry,
                                     userp: rawptr) -> STScode
hstswrite_callback :: #type proc "c" (easy: ^CURL,
                                      e: ^hstsentry,
                                      i: ^index,
                                      userp: rawptr) -> STScode

/* CURLHSTS_* are bits for the CURLOPT_HSTS option */
HSTS_ENABLE       :: (c.long)(1<<0)
HSTS_READONLYFILE :: (c.long)(1<<1)

/* The CURLPROTO_ defines below are for the **deprecated** CURLOPT_*PROTOCOLS options. Do not use. */

PROTO_HTTP    :: (1<<0)
PROTO_HTTPS   :: (1<<1)
PROTO_FTP     :: (1<<2)
PROTO_FTPS    :: (1<<3)
PROTO_SCP     :: (1<<4)
PROTO_SFTP    :: (1<<5)
PROTO_TELNET  :: (1<<6)
PROTO_LDAP    :: (1<<7)
PROTO_LDAPS   :: (1<<8)
PROTO_DICT    :: (1<<9)
PROTO_FILE    :: (1<<10)
PROTO_TFTP    :: (1<<11)
PROTO_IMAP    :: (1<<12)
PROTO_IMAPS   :: (1<<13)
PROTO_POP3    :: (1<<14)
PROTO_POP3S   :: (1<<15)
PROTO_SMTP    :: (1<<16)
PROTO_SMTPS   :: (1<<17)
PROTO_RTSP    :: (1<<18)
PROTO_RTMP    :: (1<<19)
PROTO_RTMPT   :: (1<<20)
PROTO_RTMPE   :: (1<<21)
PROTO_RTMPTE  :: (1<<22)
PROTO_RTMPS   :: (1<<23)
PROTO_RTMPTS  :: (1<<24)
PROTO_GOPHER  :: (1<<25)
PROTO_SMB     :: (1<<26)
PROTO_SMBS    :: (1<<27)
PROTO_MQTT    :: (1<<28)
PROTO_GOPHERS :: (1<<29)
PROTO_ALL     :: (~c.int(0)) /* enable everything */

/* long may be 32 or 64 bits, but we should never depend on anything else but 32 */
OPTTYPE_LONG          :: 0
OPTTYPE_OBJECTPOINT   :: 10000
OPTTYPE_FUNCTIONPOINT :: 20000
OPTTYPE_OFF_T         :: 30000
OPTTYPE_BLOB          :: 40000

/* *OPTTYPE_STRINGPOINT is an alias for OBJECTPOINT to allow tools to extract the string options from the header file */


/* CURLOPT aliases that make no runtime difference */

/* 'char *' argument to a string with a trailing zero */
OPTTYPE_STRINGPOINT :: OPTTYPE_OBJECTPOINT

/* 'struct curl_slist *' argument */
OPTTYPE_SLISTPOINT  :: OPTTYPE_OBJECTPOINT

/* 'void *' argument passed untouched to callback */
OPTTYPE_CBPOINT     :: OPTTYPE_OBJECTPOINT

/* 'long' argument with a set of values/bitmask */
OPTTYPE_VALUES      :: OPTTYPE_LONG

/*
 * All CURLOPT_* values.
 */
option :: enum c.int {
	/* This is the FILE * or void * the regular output should be written to. */
	WRITEDATA = OPTTYPE_CBPOINT + 1,

	/* The full URL to get/put */
	URL = OPTTYPE_STRINGPOINT + 2,

	/* Port number to connect to, if other than default. */
	PORT = OPTTYPE_LONG + 3,

	/* Name of proxy to use. */
	PROXY = OPTTYPE_STRINGPOINT + 4,

	/* "user:password;options" to use when fetching. */
	USERPWD = OPTTYPE_STRINGPOINT + 5,

	/* "user:password" to use with proxy. */
	PROXYUSERPWD = OPTTYPE_STRINGPOINT + 6,

	/* Range to get, specified as an ASCII string. */
	RANGE = OPTTYPE_STRINGPOINT + 7,

	/* not used */

	/* Specified file stream to upload from (use as input): */
	READDATA = OPTTYPE_CBPOINT + 9,

	/* Buffer to receive error messages in, must be at least CURL_ERROR_SIZE
	* bytes big. */
	ERRORBUFFER = OPTTYPE_OBJECTPOINT + 10,

	/* Function that will be called to store the output (instead of fwrite). The
	* parameters will use fwrite() syntax, make sure to follow them. */
	WRITEFUNCTION = OPTTYPE_FUNCTIONPOINT + 11,

	/* Function that will be called to read the input (instead of fread). The
	* parameters will use fread() syntax, make sure to follow them. */
	READFUNCTION = OPTTYPE_FUNCTIONPOINT + 12,

	/* Time-out the read operation after this amount of seconds */
	TIMEOUT = OPTTYPE_LONG + 13,

	/* If CURLOPT_READDATA is used, this can be used to inform libcurl about
	* how large the file being sent really is. That allows better error
	* checking and better verifies that the upload was successful. -1 means
	* unknown size.
	*
	* For large file support, there is also a _LARGE version of the key
	* which takes an off_t type, allowing platforms with larger off_t
	* sizes to handle larger files. See below for INFILESIZE_LARGE.
	*/
	INFILESIZE = OPTTYPE_LONG + 14,

	/* POST static input fields. */
	POSTFIELDS = OPTTYPE_OBJECTPOINT + 15,

	/* Set the referrer page (needed by some CGIs) */
	REFERER = OPTTYPE_STRINGPOINT + 16,

	/* Set the FTP PORT string (interface name, named or numerical IP address)
	Use i.e '-' to use default address. */
	FTPPORT = OPTTYPE_STRINGPOINT + 17,

	/* Set the User-Agent string (examined by some CGIs) */
	USERAGENT = OPTTYPE_STRINGPOINT + 18,

	/* If the download receives less than "low speed limit" bytes/second
	* during "low speed time" seconds, the operations is aborted.
	* You could i.e if you have a pretty high speed connection, abort if
	* it is less than 2000 bytes/sec during 20 seconds.
	*/

	/* Set the "low speed limit" */
	LOW_SPEED_LIMIT = OPTTYPE_LONG + 19,

	/* Set the "low speed time" */
	LOW_SPEED_TIME = OPTTYPE_LONG + 20,

	/* Set the continuation offset.
	*
	* Note there is also a _LARGE version of this key which uses
	* off_t types, allowing for large file offsets on platforms which
	* use larger-than-32-bit off_t's. Look below for RESUME_FROM_LARGE.
	*/
	RESUME_FROM = OPTTYPE_LONG + 21,

	/* Set cookie in request: */
	COOKIE = OPTTYPE_STRINGPOINT + 22,

	/* This points to a linked list of headers, struct curl_slist kind. This
	list is also used for RTSP (in spite of its name) */
	HTTPHEADER = OPTTYPE_SLISTPOINT + 23,

	/* name of the file keeping your private SSL-certificate */
	SSLCERT = OPTTYPE_STRINGPOINT + 25,

	/* password for the SSL or SSH private key */
	KEYPASSWD = OPTTYPE_STRINGPOINT + 26,

	/* send TYPE parameter? */
	CRLF = OPTTYPE_LONG + 27,

	/* send linked-list of QUOTE commands */
	QUOTE = OPTTYPE_SLISTPOINT + 28,

	/* send FILE * or void * to store headers to, if you use a callback it
	is simply passed to the callback unmodified */
	HEADERDATA = OPTTYPE_CBPOINT + 29,

	/* point to a file to read the initial cookies from, also enables
	"cookie awareness" */
	COOKIEFILE = OPTTYPE_STRINGPOINT + 31,

	/* What version to specifically try to use.
	See CURL_SSLVERSION defines below. */
	SSLVERSION = OPTTYPE_VALUES + 32,

	/* What kind of HTTP time condition to use, see defines */
	TIMECONDITION = OPTTYPE_VALUES + 33,

	/* Time to use with the above condition. Specified in number of seconds
	since 1 Jan 1970 */
	TIMEVALUE = OPTTYPE_LONG + 34,

	/* 35 = OBSOLETE */

	/* Custom request, for customizing the get command like
	HTTP: DELETE, TRACE and others
	FTP: to use a different list command
	*/
	CUSTOMREQUEST = OPTTYPE_STRINGPOINT + 36,

	/* FILE handle to use instead of stderr */
	STDERR = OPTTYPE_OBJECTPOINT + 37,

	/* 38 is not used */

	/* send linked-list of post-transfer QUOTE commands */
	POSTQUOTE = OPTTYPE_SLISTPOINT + 39,

	/* 40 is not used */

	/* talk a lot */
	VERBOSE = OPTTYPE_LONG + 41,

	/* throw the header out too */
	HEADER = OPTTYPE_LONG + 42,

	/* shut off the progress meter */
	NOPROGRESS = OPTTYPE_LONG + 43,

	/* use HEAD to get http document */
	NOBODY = OPTTYPE_LONG + 44,

	/* no output on http error codes >= 400 */
	FAILONERROR = OPTTYPE_LONG + 45,

	/* this is an upload */
	UPLOAD = OPTTYPE_LONG + 46,

	/* HTTP POST method */
	POST = OPTTYPE_LONG + 47,

	/* bare names when listing directories */
	DIRLISTONLY = OPTTYPE_LONG + 48,

	/* Append instead of overwrite on upload! */
	APPEND = OPTTYPE_LONG + 50,

	/* Specify whether to read the user+password from the .netrc or the URL.
	* This must be one of the CURL_NETRC_* enums below. */
	NETRC = OPTTYPE_VALUES + 51,

	/* use Location: Luke! */
	FOLLOWLOCATION = OPTTYPE_LONG + 52,

	/* transfer data in text/ASCII format */
	TRANSFERTEXT = OPTTYPE_LONG + 53,

	/* 55 = OBSOLETE */

	/* Data passed to the CURLOPT_PROGRESSFUNCTION and CURLOPT_XFERINFOFUNCTION
	callbacks */
	XFERINFODATA = OPTTYPE_CBPOINT + 57,
	PROGRESSDATA = XFERINFODATA,

	/* We want the referrer field set automatically when following locations */
	AUTOREFERER = OPTTYPE_LONG + 58,

	/* Port of the proxy, can be set in the proxy string as well with:
	"[host]:[port]" */
	PROXYPORT = OPTTYPE_LONG + 59,

	/* size of the POST input data, if strlen() is not good to use */
	POSTFIELDSIZE = OPTTYPE_LONG + 60,

	/* tunnel non-http operations through an HTTP proxy */
	HTTPPROXYTUNNEL = OPTTYPE_LONG + 61,

	/* Set the interface string to use as outgoing network interface */
	INTERFACE = OPTTYPE_STRINGPOINT + 62,

	/* Set the krb4/5 security level, this also enables krb4/5 awareness. This
	* is a string, 'clear', 'safe', 'confidential' or 'private'. If the string
	* is set but does not match one of these, 'private' will be used.  */
	KRBLEVEL = OPTTYPE_STRINGPOINT + 63,

	/* Set if we should verify the peer in ssl handshake, set 1 to verify. */
	SSL_VERIFYPEER = OPTTYPE_LONG + 64,

	/* The CApath or CAfile used to validate the peer certificate
	this option is used only if SSL_VERIFYPEER is true */
	CAINFO = OPTTYPE_STRINGPOINT + 65,

	/* 66 = OBSOLETE */
	/* 67 = OBSOLETE */

	/* Maximum number of http redirects to follow */
	MAXREDIRS = OPTTYPE_LONG + 68,

	/* Pass a long set to 1 to get the date of the requested document (if
	possible)! Pass a zero to shut it off. */
	FILETIME = OPTTYPE_LONG + 69,

	/* This points to a linked list of telnet options */
	TELNETOPTIONS = OPTTYPE_SLISTPOINT + 70,

	/* Max amount of cached alive connections */
	MAXCONNECTS = OPTTYPE_LONG + 71,

	/* 72 = OBSOLETE */
	/* 73 = OBSOLETE */

	/* Set to explicitly use a new connection for the upcoming transfer.
	Do not use this unless you are absolutely sure of this, as it makes the
	operation slower and is less friendly for the network. */
	FRESH_CONNECT = OPTTYPE_LONG + 74,

	/* Set to explicitly forbid the upcoming transfer's connection to be reused
	when done. Do not use this unless you are absolutely sure of this, as it
	makes the operation slower and is less friendly for the network. */
	FORBID_REUSE = OPTTYPE_LONG + 75,

	/* Time-out connect operations after this amount of seconds, if connects are
	OK within this time, then fine... This only aborts the connect phase. */
	CONNECTTIMEOUT = OPTTYPE_LONG + 78,

	/* Function that will be called to store headers (instead of fwrite). The
	* parameters will use fwrite() syntax, make sure to follow them. */
	HEADERFUNCTION = OPTTYPE_FUNCTIONPOINT + 79,

	/* Set this to force the HTTP request to get back to GET. Only really usable
	if POST, PUT or a custom request have been used first.
	*/
	HTTPGET = OPTTYPE_LONG + 80,

	/* Set if we should verify the Common name from the peer certificate in ssl
	* handshake, set 1 to check existence, 2 to ensure that it matches the
	* provided hostname. */
	SSL_VERIFYHOST = OPTTYPE_LONG + 81,

	/* Specify which filename to write all known cookies in after completed
	operation. Set filename to "-" (dash) to make it go to stdout. */
	COOKIEJAR = OPTTYPE_STRINGPOINT + 82,

	/* Specify which TLS 1.2 (1.1, 1.0) ciphers to use */
	SSL_CIPHER_LIST = OPTTYPE_STRINGPOINT + 83,

	/* Specify which HTTP version to use! This must be set to one of the
	CURL_HTTP_VERSION* enums set below. */
	HTTP_VERSION = OPTTYPE_VALUES + 84,

	/* Specifically switch on or off the FTP engine's use of the EPSV command. By
	default, that one will always be attempted before the more traditional
	PASV command. */
	FTP_USE_EPSV = OPTTYPE_LONG + 85,

	/* type of the file keeping your SSL-certificate ("DER", "PEM", "ENG") */
	SSLCERTTYPE = OPTTYPE_STRINGPOINT + 86,

	/* name of the file keeping your private SSL-key */
	SSLKEY = OPTTYPE_STRINGPOINT + 87,

	/* type of the file keeping your private SSL-key ("DER", "PEM", "ENG") */
	SSLKEYTYPE = OPTTYPE_STRINGPOINT + 88,

	/* crypto engine for the SSL-sub system */
	SSLENGINE = OPTTYPE_STRINGPOINT + 89,

	/* set the crypto engine for the SSL-sub system as default
	the param has no meaning...
	*/
	SSLENGINE_DEFAULT = OPTTYPE_LONG + 90,

	/* DNS cache timeout */
	DNS_CACHE_TIMEOUT = OPTTYPE_LONG + 92,

	/* send linked-list of pre-transfer QUOTE commands */
	PREQUOTE = OPTTYPE_SLISTPOINT + 93,

	/* set the debug function */
	DEBUGFUNCTION = OPTTYPE_FUNCTIONPOINT + 94,

	/* set the data for the debug function */
	DEBUGDATA = OPTTYPE_CBPOINT + 95,

	/* mark this as start of a cookie session */
	COOKIESESSION = OPTTYPE_LONG + 96,

	/* The CApath directory used to validate the peer certificate
	this option is used only if SSL_VERIFYPEER is true */
	CAPATH = OPTTYPE_STRINGPOINT + 97,

	/* Instruct libcurl to use a smaller receive buffer */
	BUFFERSIZE = OPTTYPE_LONG + 98,

	/* Instruct libcurl to not use any signal/alarm handlers, even when using
	timeouts. This option is useful for multi-threaded applications.
	See libcurl-the-guide for more background information. */
	NOSIGNAL = OPTTYPE_LONG + 99,

	/* Provide a CURLShare for mutexing non-ts data */
	SHARE = OPTTYPE_OBJECTPOINT + 100,

	/* indicates type of proxy. accepted values are CURLPROXY_HTTP (default),
	CURLPROXY_HTTPS, CURLPROXY_SOCKS4, CURLPROXY_SOCKS4A and
	CURLPROXY_SOCKS5. */
	PROXYTYPE = OPTTYPE_VALUES + 101,

	/* Set the Accept-Encoding string. Use this to tell a server you would like
	the response to be compressed. Before 7.21.6, this was known as
	CURLOPT_ENCODING */
	ACCEPT_ENCODING = OPTTYPE_STRINGPOINT + 102,

	/* Set pointer to private data */
	PRIVATE = OPTTYPE_OBJECTPOINT + 103,

	/* Set aliases for HTTP 200 in the HTTP Response header */
	HTTP200ALIASES = OPTTYPE_SLISTPOINT + 104,

	/* Continue to send authentication (user+password) when following locations,
	even when hostname changed. This can potentially send off the name
	and password to whatever host the server decides. */
	UNRESTRICTED_AUTH = OPTTYPE_LONG + 105,

	/* Specifically switch on or off the FTP engine's use of the EPRT command (
	it also disables the LPRT attempt). By default, those ones will always be
	attempted before the good old traditional PORT command. */
	FTP_USE_EPRT = OPTTYPE_LONG + 106,

	/* Set this to a bitmask value to enable the particular authentications
	methods you like. Use this in combination with CURLOPT_USERPWD.
	Note that setting multiple bits may cause extra network round-trips. */
	HTTPAUTH = OPTTYPE_VALUES + 107,

	/* Set the ssl context callback function, currently only for OpenSSL or
	wolfSSL ssl_ctx, or mbedTLS mbedtls_ssl_config in the second argument.
	The function must match the curl_ssl_ctx_callback prototype. */
	SSL_CTX_FUNCTION = OPTTYPE_FUNCTIONPOINT + 108,

	/* Set the userdata for the ssl context callback function's third
	argument */
	SSL_CTX_DATA = OPTTYPE_CBPOINT + 109,

	/* FTP Option that causes missing dirs to be created on the remote server.
	In 7.19.4 we introduced the convenience enums for this option using the
	CURLFTP_CREATE_DIR prefix.
	*/
	FTP_CREATE_MISSING_DIRS = OPTTYPE_LONG + 110,

	/* Set this to a bitmask value to enable the particular authentications
	methods you like. Use this in combination with CURLOPT_PROXYUSERPWD.
	Note that setting multiple bits may cause extra network round-trips. */
	PROXYAUTH = OPTTYPE_VALUES + 111,

	/* Option that changes the timeout, in seconds, associated with getting a
	response. This is different from transfer timeout time and essentially
	places a demand on the server to acknowledge commands in a timely
	manner. For FTP, SMTP, IMAP and POP3. */
	SERVER_RESPONSE_TIMEOUT = OPTTYPE_LONG + 112,

	/* Set this option to one of the CURL_IPRESOLVE_* defines (see below) to
	tell libcurl to use those IP versions only. This only has effect on
	systems with support for more than one, i.e IPv4 _and_ IPv6. */
	IPRESOLVE = OPTTYPE_VALUES + 113,

	/* Set this option to limit the size of a file that will be downloaded from
	an HTTP or FTP server.

	Note there is also _LARGE version which adds large file support for
	platforms which have larger off_t sizes. See MAXFILESIZE_LARGE below. */
	MAXFILESIZE = OPTTYPE_LONG + 114,

	/* See the comment for INFILESIZE above, but in short, specifies
	* the size of the file being uploaded.  -1 means unknown.
	*/
	INFILESIZE_LARGE = OPTTYPE_OFF_T + 115,

	/* Sets the continuation offset. There is also a CURLOPTTYPE_LONG version
	* of this; look above for RESUME_FROM.
	*/
	RESUME_FROM_LARGE = OPTTYPE_OFF_T + 116,

	/* Sets the maximum size of data that will be downloaded from
	* an HTTP or FTP server. See MAXFILESIZE above for the LONG version.
	*/
	MAXFILESIZE_LARGE = OPTTYPE_OFF_T + 117,

	/* Set this option to the filename of your .netrc file you want libcurl
	to parse (using the CURLOPT_NETRC option). If not set, libcurl will do
	a poor attempt to find the user's home directory and check for a .netrc
	file in there. */
	NETRC_FILE = OPTTYPE_STRINGPOINT + 118,

	/* Enable SSL/TLS for FTP, pick one of:
	CURLUSESSL_TRY     - try using SSL, proceed anyway otherwise
	CURLUSESSL_CONTROL - SSL for the control connection or fail
	CURLUSESSL_ALL     - SSL for all communication or fail
	*/
	USE_SSL = OPTTYPE_VALUES + 119,

	/* The _LARGE version of the standard POSTFIELDSIZE option */
	POSTFIELDSIZE_LARGE = OPTTYPE_OFF_T + 120,

	/* Enable/disable the TCP Nagle algorithm */
	TCP_NODELAY = OPTTYPE_LONG + 121,

	/* 122 OBSOLETE, used in 7.12.3. Gone in 7.13.0 */
	/* 123 OBSOLETE. Gone in 7.16.0 */
	/* 124 OBSOLETE, used in 7.12.3. Gone in 7.13.0 */
	/* 125 OBSOLETE, used in 7.12.3. Gone in 7.13.0 */
	/* 126 OBSOLETE, used in 7.12.3. Gone in 7.13.0 */
	/* 127 OBSOLETE. Gone in 7.16.0 */
	/* 128 OBSOLETE. Gone in 7.16.0 */

	/* When FTP over SSL/TLS is selected (with CURLOPT_USE_SSL), this option
	can be used to change libcurl's default action which is to first try
	"AUTH SSL" and then "AUTH TLS" in this order, and proceed when a OK
	response has been received.

	Available parameters are:
	CURLFTPAUTH_DEFAULT - let libcurl decide
	CURLFTPAUTH_SSL     - try "AUTH SSL" first, then TLS
	CURLFTPAUTH_TLS     - try "AUTH TLS" first, then SSL
	*/
	FTPSSLAUTH = OPTTYPE_VALUES + 129,

	/* 132 OBSOLETE. Gone in 7.16.0 */
	/* 133 OBSOLETE. Gone in 7.16.0 */

	/* null-terminated string for pass on to the FTP server when asked for
	"account" info */
	FTP_ACCOUNT = OPTTYPE_STRINGPOINT + 134,

	/* feed cookie into cookie engine */
	COOKIELIST = OPTTYPE_STRINGPOINT + 135,

	/* ignore Content-Length */
	IGNORE_CONTENT_LENGTH = OPTTYPE_LONG + 136,

	/* Set to non-zero to skip the IP address received in a 227 PASV FTP server
	response. Typically used for FTP-SSL purposes but is not restricted to
	that. libcurl will then instead use the same IP address it used for the
	control connection. */
	FTP_SKIP_PASV_IP = OPTTYPE_LONG + 137,

	/* Select "file method" to use when doing FTP, see the curl_ftpmethod
	above. */
	FTP_FILEMETHOD = OPTTYPE_VALUES + 138,

	/* Local port number to bind the socket to */
	LOCALPORT = OPTTYPE_LONG + 139,

	/* Number of ports to try, including the first one set with LOCALPORT.
	Thus, setting it to 1 will make no additional attempts but the first.
	*/
	LOCALPORTRANGE = OPTTYPE_LONG + 140,

	/* no transfer, set up connection and let application use the socket by
	extracting it with CURLINFO_LASTSOCKET */
	CONNECT_ONLY = OPTTYPE_LONG + 141,

	/* if the connection proceeds too quickly then need to slow it down */
	/* limit-rate: maximum number of bytes per second to send or receive */
	MAX_SEND_SPEED_LARGE = OPTTYPE_OFF_T + 145,
	MAX_RECV_SPEED_LARGE = OPTTYPE_OFF_T + 146,

	/* Pointer to command string to send if USER/PASS fails. */
	FTP_ALTERNATIVE_TO_USER = OPTTYPE_STRINGPOINT + 147,

	/* callback function for setting socket options */
	SOCKOPTFUNCTION = OPTTYPE_FUNCTIONPOINT + 148,
	SOCKOPTDATA = OPTTYPE_CBPOINT + 149,

	/* set to 0 to disable session ID reuse for this transfer, default is
	enabled (== 1) */
	SSL_SESSIONID_CACHE = OPTTYPE_LONG + 150,

	/* allowed SSH authentication methods */
	SSH_AUTH_TYPES = OPTTYPE_VALUES + 151,

	/* Used by scp/sftp to do public/private key authentication */
	SSH_PUBLIC_KEYFILE = OPTTYPE_STRINGPOINT + 152,
	SSH_PRIVATE_KEYFILE = OPTTYPE_STRINGPOINT + 153,

	/* Send CCC (Clear Command Channel) after authentication */
	FTP_SSL_CCC = OPTTYPE_LONG + 154,

	/* Same as TIMEOUT and CONNECTTIMEOUT, but with ms resolution */
	TIMEOUT_MS = OPTTYPE_LONG + 155,
	CONNECTTIMEOUT_MS = OPTTYPE_LONG + 156,

	/* set to zero to disable the libcurl's decoding and thus pass the raw body
	data to the application even when it is encoded/compressed */
	HTTP_TRANSFER_DECODING = OPTTYPE_LONG + 157,
	HTTP_CONTENT_DECODING = OPTTYPE_LONG + 158,

	/* Permission used when creating new files and directories on the remote
	server for protocols that support it, SFTP/SCP/FILE */
	NEW_FILE_PERMS = OPTTYPE_LONG + 159,
	NEW_DIRECTORY_PERMS = OPTTYPE_LONG + 160,

	/* Set the behavior of POST when redirecting. Values must be set to one
	of CURL_REDIR* defines below. This used to be called CURLOPT_POST301 */
	POSTREDIR = OPTTYPE_VALUES + 161,

	/* used by scp/sftp to verify the host's public key */
	SSH_HOST_PUBLIC_KEY_MD5 = OPTTYPE_STRINGPOINT + 162,

	/* Callback function for opening socket (instead of socket(2)). Optionally,
	callback is able change the address or refuse to connect returning
	CURL_SOCKET_BAD. The callback should have type
	curl_opensocket_callback */
	OPENSOCKETFUNCTION = OPTTYPE_FUNCTIONPOINT + 163,
	OPENSOCKETDATA = OPTTYPE_CBPOINT + 164,

	/* POST volatile input fields. */
	COPYPOSTFIELDS = OPTTYPE_OBJECTPOINT + 165,

	/* set transfer mode (;type=<a|i>) when doing FTP via an HTTP proxy */
	PROXY_TRANSFER_MODE = OPTTYPE_LONG + 166,

	/* Callback function for seeking in the input stream */
	SEEKFUNCTION = OPTTYPE_FUNCTIONPOINT + 167,
	SEEKDATA = OPTTYPE_CBPOINT + 168,

	/* CRL file */
	CRLFILE = OPTTYPE_STRINGPOINT + 169,

	/* Issuer certificate */
	ISSUERCERT = OPTTYPE_STRINGPOINT + 170,

	/* (IPv6) Address scope */
	ADDRESS_SCOPE = OPTTYPE_LONG + 171,

	/* Collect certificate chain info and allow it to get retrievable with
	CURLINFO_CERTINFO after the transfer is complete. */
	CERTINFO = OPTTYPE_LONG + 172,

	/* "name" and "pwd" to use when fetching. */
	USERNAME = OPTTYPE_STRINGPOINT + 173,
	PASSWORD = OPTTYPE_STRINGPOINT + 174,

	/* "name" and "pwd" to use with Proxy when fetching. */
	PROXYUSERNAME = OPTTYPE_STRINGPOINT + 175,
	PROXYPASSWORD = OPTTYPE_STRINGPOINT + 176,

	/* Comma separated list of hostnames defining no-proxy zones. These should
	match both hostnames directly, and hostnames within a domain. For
	example, local.com will match local.com and www.local.com, but NOT
	notlocal.com or www.notlocal.com. For compatibility with other
	implementations of this, .local.com will be considered to be the same as
	local.com. A single * is the only valid wildcard, and effectively
	disables the use of proxy. */
	NOPROXY = OPTTYPE_STRINGPOINT + 177,

	/* block size for TFTP transfers */
	TFTP_BLKSIZE = OPTTYPE_LONG + 178,

	/* Socks Service */
	SOCKS5_GSSAPI_NEC = OPTTYPE_LONG + 180,

	/* set the SSH knownhost filename to use */
	SSH_KNOWNHOSTS = OPTTYPE_STRINGPOINT + 183,

	/* set the SSH host key callback, must point to a curl_sshkeycallback
	function */
	SSH_KEYFUNCTION = OPTTYPE_FUNCTIONPOINT + 184,

	/* set the SSH host key callback custom pointer */
	SSH_KEYDATA = OPTTYPE_CBPOINT + 185,

	/* set the SMTP mail originator */
	MAIL_FROM = OPTTYPE_STRINGPOINT + 186,

	/* set the list of SMTP mail receiver(s) */
	MAIL_RCPT = OPTTYPE_SLISTPOINT + 187,

	/* FTP: send PRET before PASV */
	FTP_USE_PRET = OPTTYPE_LONG + 188,

	/* RTSP request method (OPTIONS, SETUP, PLAY, etc...) */
	RTSP_REQUEST = OPTTYPE_VALUES + 189,

	/* The RTSP session identifier */
	RTSP_SESSION_ID = OPTTYPE_STRINGPOINT + 190,

	/* The RTSP stream URI */
	RTSP_STREAM_URI = OPTTYPE_STRINGPOINT + 191,

	/* The Transport: header to use in RTSP requests */
	RTSP_TRANSPORT = OPTTYPE_STRINGPOINT + 192,

	/* Manually initialize the client RTSP CSeq for this handle */
	RTSP_CLIENT_CSEQ = OPTTYPE_LONG + 193,

	/* Manually initialize the server RTSP CSeq for this handle */
	RTSP_SERVER_CSEQ = OPTTYPE_LONG + 194,

	/* The stream to pass to INTERLEAVEFUNCTION. */
	INTERLEAVEDATA = OPTTYPE_CBPOINT + 195,

	/* Let the application define a custom write method for RTP data */
	INTERLEAVEFUNCTION = OPTTYPE_FUNCTIONPOINT + 196,

	/* Turn on wildcard matching */
	WILDCARDMATCH = OPTTYPE_LONG + 197,

	/* Directory matching callback called before downloading of an
	individual file (chunk) started */
	CHUNK_BGN_FUNCTION = OPTTYPE_FUNCTIONPOINT + 198,

	/* Directory matching callback called after the file (chunk)
	was downloaded, or skipped */
	CHUNK_END_FUNCTION = OPTTYPE_FUNCTIONPOINT + 199,

	/* Change match (fnmatch-like) callback for wildcard matching */
	FNMATCH_FUNCTION = OPTTYPE_FUNCTIONPOINT + 200,

	/* Let the application define custom chunk data pointer */
	CHUNK_DATA = OPTTYPE_CBPOINT + 201,

	/* FNMATCH_FUNCTION user pointer */
	FNMATCH_DATA = OPTTYPE_CBPOINT + 202,

	/* send linked-list of name:port:address sets */
	RESOLVE = OPTTYPE_SLISTPOINT + 203,

	/* Set a username for authenticated TLS */
	TLSAUTH_USERNAME = OPTTYPE_STRINGPOINT + 204,

	/* Set a password for authenticated TLS */
	TLSAUTH_PASSWORD = OPTTYPE_STRINGPOINT + 205,

	/* Set authentication type for authenticated TLS */
	TLSAUTH_TYPE = OPTTYPE_STRINGPOINT + 206,

	/* Set to 1 to enable the "TE:" header in HTTP requests to ask for
	compressed transfer-encoded responses. Set to 0 to disable the use of TE:
	in outgoing requests. The current default is 0, but it might change in a
	future libcurl release.

	libcurl will ask for the compressed methods it knows of, and if that
	is not any, it will not ask for transfer-encoding at all even if this
	option is set to 1.

	*/
	TRANSFER_ENCODING = OPTTYPE_LONG + 207,

	/* Callback function for closing socket (instead of close(2)). The callback
	should have type curl_closesocket_callback */
	CLOSESOCKETFUNCTION = OPTTYPE_FUNCTIONPOINT + 208,
	CLOSESOCKETDATA = OPTTYPE_CBPOINT + 209,

	/* allow GSSAPI credential delegation */
	GSSAPI_DELEGATION = OPTTYPE_VALUES + 210,

	/* Set the name servers to use for DNS resolution.
	* Only supported by the c-ares DNS backend */
	DNS_SERVERS = OPTTYPE_STRINGPOINT + 211,

	/* Time-out accept operations (currently for FTP only) after this amount
	of milliseconds. */
	ACCEPTTIMEOUT_MS = OPTTYPE_LONG + 212,

	/* Set TCP keepalive */
	TCP_KEEPALIVE = OPTTYPE_LONG + 213,

	/* non-universal keepalive knobs (Linux, AIX, HP-UX, more) */
	TCP_KEEPIDLE = OPTTYPE_LONG + 214,
	TCP_KEEPINTVL = OPTTYPE_LONG + 215,

	/* Enable/disable specific SSL features with a bitmask, see CURLSSLOPT_* */
	SSL_OPTIONS = OPTTYPE_VALUES + 216,

	/* Set the SMTP auth originator */
	MAIL_AUTH = OPTTYPE_STRINGPOINT + 217,

	/* Enable/disable SASL initial response */
	SASL_IR = OPTTYPE_LONG + 218,

	/* Function that will be called instead of the internal progress display
	* function. This function should be defined as the curl_xferinfo_callback
	* prototype defines. (Deprecates CURLOPT_PROGRESSFUNCTION) */
	XFERINFOFUNCTION = OPTTYPE_FUNCTIONPOINT + 219,

	/* The XOAUTH2 bearer token */
	XOAUTH2_BEARER = OPTTYPE_STRINGPOINT + 220,

	/* Set the interface string to use as outgoing network
	* interface for DNS requests.
	* Only supported by the c-ares DNS backend */
	DNS_INTERFACE = OPTTYPE_STRINGPOINT + 221,

	/* Set the local IPv4 address to use for outgoing DNS requests.
	* Only supported by the c-ares DNS backend */
	DNS_LOCAL_IP4 = OPTTYPE_STRINGPOINT + 222,

	/* Set the local IPv6 address to use for outgoing DNS requests.
	* Only supported by the c-ares DNS backend */
	DNS_LOCAL_IP6 = OPTTYPE_STRINGPOINT + 223,

	/* Set authentication options directly */
	LOGIN_OPTIONS = OPTTYPE_STRINGPOINT + 224,

	/* Enable/disable TLS ALPN extension (http2 over ssl might fail without) */
	SSL_ENABLE_ALPN = OPTTYPE_LONG + 226,

	/* Time to wait for a response to an HTTP request containing an
	* Expect: 100-continue header before sending the data anyway. */
	EXPECT_100_TIMEOUT_MS = OPTTYPE_LONG + 227,

	/* This points to a linked list of headers used for proxy requests only,
	struct curl_slist kind */
	PROXYHEADER = OPTTYPE_SLISTPOINT + 228,

	/* Pass in a bitmask of "header options" */
	HEADEROPT = OPTTYPE_VALUES + 229,

	/* The public key in DER form used to validate the peer public key
	this option is used only if SSL_VERIFYPEER is true */
	PINNEDPUBLICKEY = OPTTYPE_STRINGPOINT + 230,

	/* Path to Unix domain socket */
	UNIX_SOCKET_PATH = OPTTYPE_STRINGPOINT + 231,

	/* Set if we should verify the certificate status. */
	SSL_VERIFYSTATUS = OPTTYPE_LONG + 232,

	/* Do not squash dot-dot sequences */
	PATH_AS_IS = OPTTYPE_LONG + 234,

	/* Proxy Service Name */
	PROXY_SERVICE_NAME = OPTTYPE_STRINGPOINT + 235,

	/* Service Name */
	SERVICE_NAME = OPTTYPE_STRINGPOINT + 236,

	/* Wait/do not wait for pipe/mutex to clarify */
	PIPEWAIT = OPTTYPE_LONG + 237,

	/* Set the protocol used when curl is given a URL without a protocol */
	DEFAULT_PROTOCOL = OPTTYPE_STRINGPOINT + 238,

	/* Set stream weight, 1 - 256 (default is 16) */
	STREAM_WEIGHT = OPTTYPE_LONG + 239,

	/* Set stream dependency on another curl handle */
	STREAM_DEPENDS = OPTTYPE_OBJECTPOINT + 240,

	/* Set E-xclusive stream dependency on another curl handle */
	STREAM_DEPENDS_E = OPTTYPE_OBJECTPOINT + 241,

	/* Do not send any tftp option requests to the server */
	TFTP_NO_OPTIONS = OPTTYPE_LONG + 242,

	/* Linked-list of host:port:connect-to-host:connect-to-port,
	overrides the URL's host:port (only for the network layer) */
	CONNECT_TO = OPTTYPE_SLISTPOINT + 243,

	/* Set TCP Fast Open */
	TCP_FASTOPEN = OPTTYPE_LONG + 244,

	/* Continue to send data if the server responds early with an
	* HTTP status code >= 300 */
	KEEP_SENDING_ON_ERROR = OPTTYPE_LONG + 245,

	/* The CApath or CAfile used to validate the proxy certificate
	this option is used only if PROXY_SSL_VERIFYPEER is true */
	PROXY_CAINFO = OPTTYPE_STRINGPOINT + 246,

	/* The CApath directory used to validate the proxy certificate
	this option is used only if PROXY_SSL_VERIFYPEER is true */
	PROXY_CAPATH = OPTTYPE_STRINGPOINT + 247,

	/* Set if we should verify the proxy in ssl handshake,
	set 1 to verify. */
	PROXY_SSL_VERIFYPEER = OPTTYPE_LONG + 248,

	/* Set if we should verify the Common name from the proxy certificate in ssl
	* handshake, set 1 to check existence, 2 to ensure that it matches
	* the provided hostname. */
	PROXY_SSL_VERIFYHOST = OPTTYPE_LONG + 249,

	/* What version to specifically try to use for proxy.
	See CURL_SSLVERSION defines below. */
	PROXY_SSLVERSION = OPTTYPE_VALUES + 250,

	/* Set a username for authenticated TLS for proxy */
	PROXY_TLSAUTH_USERNAME = OPTTYPE_STRINGPOINT + 251,

	/* Set a password for authenticated TLS for proxy */
	PROXY_TLSAUTH_PASSWORD = OPTTYPE_STRINGPOINT + 252,

	/* Set authentication type for authenticated TLS for proxy */
	PROXY_TLSAUTH_TYPE = OPTTYPE_STRINGPOINT + 253,

	/* name of the file keeping your private SSL-certificate for proxy */
	PROXY_SSLCERT = OPTTYPE_STRINGPOINT + 254,

	/* type of the file keeping your SSL-certificate ("DER", "PEM", "ENG") for
	proxy */
	PROXY_SSLCERTTYPE = OPTTYPE_STRINGPOINT + 255,

	/* name of the file keeping your private SSL-key for proxy */
	PROXY_SSLKEY = OPTTYPE_STRINGPOINT + 256,

	/* type of the file keeping your private SSL-key ("DER", "PEM", "ENG") for
	proxy */
	PROXY_SSLKEYTYPE = OPTTYPE_STRINGPOINT + 257,

	/* password for the SSL private key for proxy */
	PROXY_KEYPASSWD = OPTTYPE_STRINGPOINT + 258,

	/* Specify which TLS 1.2 (1.1, 1.0) ciphers to use for proxy */
	PROXY_SSL_CIPHER_LIST = OPTTYPE_STRINGPOINT + 259,

	/* CRL file for proxy */
	PROXY_CRLFILE = OPTTYPE_STRINGPOINT + 260,

	/* Enable/disable specific SSL features with a bitmask for proxy, see
	CURLSSLOPT_* */
	PROXY_SSL_OPTIONS = OPTTYPE_LONG + 261,

	/* Name of pre proxy to use. */
	PRE_PROXY = OPTTYPE_STRINGPOINT + 262,

	/* The public key in DER form used to validate the proxy public key
	this option is used only if PROXY_SSL_VERIFYPEER is true */
	PROXY_PINNEDPUBLICKEY = OPTTYPE_STRINGPOINT + 263,

	/* Path to an abstract Unix domain socket */
	ABSTRACT_UNIX_SOCKET = OPTTYPE_STRINGPOINT + 264,

	/* Suppress proxy CONNECT response headers from user callbacks */
	SUPPRESS_CONNECT_HEADERS = OPTTYPE_LONG + 265,

	/* The request target, instead of extracted from the URL */
	REQUEST_TARGET = OPTTYPE_STRINGPOINT + 266,

	/* bitmask of allowed auth methods for connections to SOCKS5 proxies */
	SOCKS5_AUTH = OPTTYPE_LONG + 267,

	/* Enable/disable SSH compression */
	SSH_COMPRESSION = OPTTYPE_LONG + 268,

	/* Post MIME data. */
	MIMEPOST = OPTTYPE_OBJECTPOINT + 269,

	/* Time to use with the CURLOPT_TIMECONDITION. Specified in number of
	seconds since 1 Jan 1970. */
	TIMEVALUE_LARGE = OPTTYPE_OFF_T + 270,

	/* Head start in milliseconds to give happy eyeballs. */
	HAPPY_EYEBALLS_TIMEOUT_MS = OPTTYPE_LONG + 271,

	/* Function that will be called before a resolver request is made */
	RESOLVER_START_FUNCTION = OPTTYPE_FUNCTIONPOINT + 272,

	/* User data to pass to the resolver start callback. */
	RESOLVER_START_DATA = OPTTYPE_CBPOINT + 273,

	/* send HAProxy PROXY protocol header? */
	HAPROXYPROTOCOL = OPTTYPE_LONG + 274,

	/* shuffle addresses before use when DNS returns multiple */
	DNS_SHUFFLE_ADDRESSES = OPTTYPE_LONG + 275,

	/* Specify which TLS 1.3 ciphers suites to use */
	TLS13_CIPHERS = OPTTYPE_STRINGPOINT + 276,
	PROXY_TLS13_CIPHERS = OPTTYPE_STRINGPOINT + 277,

	/* Disallow specifying username/login in URL. */
	DISALLOW_USERNAME_IN_URL = OPTTYPE_LONG + 278,

	/* DNS-over-HTTPS URL */
	DOH_URL = OPTTYPE_STRINGPOINT + 279,

	/* Preferred buffer size to use for uploads */
	UPLOAD_BUFFERSIZE = OPTTYPE_LONG + 280,

	/* Time in ms between connection upkeep calls for long-lived connections. */
	UPKEEP_INTERVAL_MS = OPTTYPE_LONG + 281,

	/* Specify URL using CURL URL API. */
	CURLU = OPTTYPE_OBJECTPOINT + 282,

	/* add trailing data just after no more data is available */
	TRAILERFUNCTION = OPTTYPE_FUNCTIONPOINT + 283,

	/* pointer to be passed to HTTP_TRAILER_FUNCTION */
	TRAILERDATA = OPTTYPE_CBPOINT + 284,

	/* set this to 1L to allow HTTP/0.9 responses or 0L to disallow */
	HTTP09_ALLOWED = OPTTYPE_LONG + 285,

	/* alt-svc control bitmask */
	ALTSVC_CTRL = OPTTYPE_LONG + 286,

	/* alt-svc cache filename to possibly read from/write to */
	ALTSVC = OPTTYPE_STRINGPOINT + 287,

	/* maximum age (idle time) of a connection to consider it for reuse
	* (in seconds) */
	MAXAGE_CONN = OPTTYPE_LONG + 288,

	/* SASL authorization identity */
	SASL_AUTHZID = OPTTYPE_STRINGPOINT + 289,

	/* allow RCPT TO command to fail for some recipients */
	MAIL_RCPT_ALLOWFAILS = OPTTYPE_LONG + 290,

	/* the private SSL-certificate as a "blob" */
	SSLCERT_BLOB = OPTTYPE_BLOB + 291,
	SSLKEY_BLOB = OPTTYPE_BLOB + 292,
	PROXY_SSLCERT_BLOB = OPTTYPE_BLOB + 293,
	PROXY_SSLKEY_BLOB = OPTTYPE_BLOB + 294,
	ISSUERCERT_BLOB = OPTTYPE_BLOB + 295,

	/* Issuer certificate for proxy */
	PROXY_ISSUERCERT = OPTTYPE_STRINGPOINT + 296,
	PROXY_ISSUERCERT_BLOB = OPTTYPE_BLOB + 297,

	/* the EC curves requested by the TLS client (RFC 8422, 5.1);
	* OpenSSL support via 'set_groups'/'set_curves':
	* https://docs.openssl.org/master/man3/SSL_CTX_set1_curves/
	*/
	SSL_EC_CURVES = OPTTYPE_STRINGPOINT + 298,

	/* HSTS bitmask */
	HSTS_CTRL = OPTTYPE_LONG + 299,
	/* HSTS filename */
	HSTS = OPTTYPE_STRINGPOINT + 300,

	/* HSTS read callback */
	HSTSREADFUNCTION = OPTTYPE_FUNCTIONPOINT + 301,
	HSTSREADDATA = OPTTYPE_CBPOINT + 302,

	/* HSTS write callback */
	HSTSWRITEFUNCTION = OPTTYPE_FUNCTIONPOINT + 303,
	HSTSWRITEDATA = OPTTYPE_CBPOINT + 304,

	/* Parameters for V4 signature */
	AWS_SIGV4 = OPTTYPE_STRINGPOINT + 305,

	/* Same as CURLOPT_SSL_VERIFYPEER but for DoH (DNS-over-HTTPS) servers. */
	DOH_SSL_VERIFYPEER = OPTTYPE_LONG + 306,

	/* Same as CURLOPT_SSL_VERIFYHOST but for DoH (DNS-over-HTTPS) servers. */
	DOH_SSL_VERIFYHOST = OPTTYPE_LONG + 307,

	/* Same as CURLOPT_SSL_VERIFYSTATUS but for DoH (DNS-over-HTTPS) servers. */
	DOH_SSL_VERIFYSTATUS = OPTTYPE_LONG + 308,

	/* The CA certificates as "blob" used to validate the peer certificate
	this option is used only if SSL_VERIFYPEER is true */
	CAINFO_BLOB = OPTTYPE_BLOB + 309,

	/* The CA certificates as "blob" used to validate the proxy certificate
	this option is used only if PROXY_SSL_VERIFYPEER is true */
	PROXY_CAINFO_BLOB = OPTTYPE_BLOB + 310,

	/* used by scp/sftp to verify the host's public key */
	SSH_HOST_PUBLIC_KEY_SHA256 = OPTTYPE_STRINGPOINT + 311,

	/* Function that will be called immediately before the initial request
	is made on a connection (after any protocol negotiation step).  */
	PREREQFUNCTION = OPTTYPE_FUNCTIONPOINT + 312,

	/* Data passed to the CURLOPT_PREREQFUNCTION callback */
	PREREQDATA = OPTTYPE_CBPOINT + 313,

	/* maximum age (since creation) of a connection to consider it for reuse
	* (in seconds) */
	MAXLIFETIME_CONN = OPTTYPE_LONG + 314,

	/* Set MIME option flags. */
	MIME_OPTIONS = OPTTYPE_LONG + 315,

	/* set the SSH host key callback, must point to a curl_sshkeycallback
	function */
	SSH_HOSTKEYFUNCTION = OPTTYPE_FUNCTIONPOINT + 316,

	/* set the SSH host key callback custom pointer */
	SSH_HOSTKEYDATA = OPTTYPE_CBPOINT + 317,

	/* specify which protocols that are allowed to be used for the transfer,
	which thus helps the app which takes URLs from users or other external
	inputs and want to restrict what protocol(s) to deal with. Defaults to
	all built-in protocols. */
	PROTOCOLS_STR = OPTTYPE_STRINGPOINT + 318,

	/* specify which protocols that libcurl is allowed to follow directs to */
	REDIR_PROTOCOLS_STR = OPTTYPE_STRINGPOINT + 319,

	/* WebSockets options */
	WS_OPTIONS = OPTTYPE_LONG + 320,

	/* CA cache timeout */
	CA_CACHE_TIMEOUT = OPTTYPE_LONG + 321,

	/* Can leak things, gonna exit() soon */
	QUICK_EXIT = OPTTYPE_LONG + 322,

	/* set a specific client IP for HAProxy PROXY protocol header? */
	HAPROXY_CLIENT_IP = OPTTYPE_STRINGPOINT + 323,

	/* millisecond version */
	SERVER_RESPONSE_TIMEOUT_MS = OPTTYPE_LONG + 324,

	/* set ECH configuration */
	ECH = OPTTYPE_STRINGPOINT + 325,

	/* maximum number of keepalive probes (Linux, *BSD, macOS, etc.) */
	TCP_KEEPCNT = OPTTYPE_LONG + 326,

	UPLOAD_FLAGS = OPTTYPE_LONG + 327,

	/* set TLS supported signature algorithms */
	SSL_SIGNATURE_ALGORITHMS = OPTTYPE_STRINGPOINT + 328,
}



 /*
 	Below here follows defines for the CURLOPT_IPRESOLVE option. If a host
 	name resolves addresses using more than one IP protocol version, this
 	option might be handy to force libcurl to use a specific IP version.
 */
IPRESOLVE_WHATEVER :: 0 /* default, uses addresses to all IP
                           versions that your system allows */
IPRESOLVE_V4       :: 1 /* uses only IPv4 addresses/connections */
IPRESOLVE_V6       :: 2 /* uses only IPv6 addresses/connections */

/* Convenient "aliases" */
PT_RTSPHEADER :: option.HTTPHEADER

/* These constants are for use with the CURLOPT_HTTP_VERSION option. */
HTTP_VERSION_NONE  :: 0 /* setting this means we do not care, and
                           that we would like the library to choose
                           the best possible for us! */
HTTP_VERSION_1_0   :: 1 /* please use HTTP 1.0 in the request */
HTTP_VERSION_1_1   :: 2 /* please use HTTP 1.1 in the request */
HTTP_VERSION_2_0   :: 3 /* please use HTTP 2 in the request */
HTTP_VERSION_2TLS  :: 4 /* use version 2 for HTTPS, version 1.1 for
                                      HTTP */
HTTP_VERSION_2_PRIOR_KNOWLEDGE :: 5 /* please use HTTP 2 without
                                                  HTTP/1.1 Upgrade */
HTTP_VERSION_3     :: 30 /* Use HTTP/3, fallback to HTTP/2 or
                            HTTP/1 if needed. For HTTPS only. For
                            HTTP, this option makes libcurl
                            return error. */
HTTP_VERSION_3ONLY :: 31 /* Use HTTP/3 without fallback. For
                            HTTPS only. For HTTP, this makes
                            libcurl return error. */
HTTP_VERSION_LAST  :: 32 /* *ILLEGAL* http version */

/*
	Convenience definition simple because the name of the version is HTTP/2 and
	not 2.0. The 2_0 version of the enum name was set while the version was
	still planned to be 2.0 and we stick to it for compatibility. */
HTTP_VERSION_2 :: HTTP_VERSION_2_0

/*
 * Public API enums for RTSP requests
 */

RTSPREQ_NONE          :: 0
RTSPREQ_OPTIONS       :: 1
RTSPREQ_DESCRIBE      :: 2
RTSPREQ_ANNOUNCE      :: 3
RTSPREQ_SETUP         :: 4
RTSPREQ_PLAY          :: 5
RTSPREQ_PAUSE         :: 6
RTSPREQ_TEARDOWN      :: 7
RTSPREQ_GET_PARAMETER :: 8
RTSPREQ_SET_PARAMETER :: 9
RTSPREQ_RECORD        :: 10
RTSPREQ_RECEIVE       :: 11
RTSPREQ_LAST          :: 12 /* not used */

  /* These enums are for use with the CURLOPT_NETRC option. */
NETRC_IGNORED  :: 0 /* The .netrc will never be read.
                       This is the default. */
NETRC_OPTIONAL :: 1 /* A user:password in the URL will be preferred
                       to one in the .netrc. */
NETRC_REQUIRED :: 2 /* A user:password in the URL will be ignored.
                       Unless one is set programmatically, the
                       .netrc will be queried. */
NETRC_OPTION :: enum c.int {
	/* we set a single member here, just to make sure we still provide the enum,
	   but the values to use are defined above with L suffixes */
	LAST = 3,
}

SSLVERSION_DEFAULT :: 0
SSLVERSION_TLSv1   :: 1 /* TLS 1.x */
SSLVERSION_SSLv2   :: 2
SSLVERSION_SSLv3   :: 3
SSLVERSION_TLSv1_0 :: 4
SSLVERSION_TLSv1_1 :: 5
SSLVERSION_TLSv1_2 :: 6
SSLVERSION_TLSv1_3 :: 7

SSLVERSION_LAST :: 8 /* never use, keep last */

SSLVERSION_MAX_NONE    :: 0
SSLVERSION_MAX_DEFAULT :: SSLVERSION_TLSv1   << 16
SSLVERSION_MAX_TLSv1_0 :: SSLVERSION_TLSv1_0 << 16
SSLVERSION_MAX_TLSv1_1 :: SSLVERSION_TLSv1_1 << 16
SSLVERSION_MAX_TLSv1_2 :: SSLVERSION_TLSv1_2 << 16
SSLVERSION_MAX_TLSv1_3 :: SSLVERSION_TLSv1_3 << 16

  /* never use, keep last */
SSLVERSION_MAX_LAST :: SSLVERSION_LAST << 16

TLSAUTH_NONE :: 0
TLSAUTH_SRP  :: 1

TLSAUTH :: enum c.int {
	/*
		we set a single member here, just to make sure we still provide the enum,
		but the values to use are defined above with L suffixes
	*/
	LAST = 2,
}

/*
	symbols to use with CURLOPT_POSTREDIR.
	CURL_REDIR_POST_301, CURL_REDIR_POST_302 and CURL_REDIR_POST_303
	can be bitwise ORed so that CURL_REDIR_POST_301 | CURL_REDIR_POST_302 | CURL_REDIR_POST_303 == CURL_REDIR_POST_ALL
*/

REDIR_GET_ALL  :: 0
REDIR_POST_301 :: 1
REDIR_POST_302 :: 2
REDIR_POST_303 :: 4
REDIR_POST_ALL :: REDIR_POST_301|REDIR_POST_302|REDIR_POST_303

TIMECOND_NONE         :: 0
TIMECOND_IFMODSINCE   :: 1
TIMECOND_IFUNMODSINCE :: 2
TIMECOND_LASTMOD      :: 3

TimeCond :: enum c.int {
	/*
		we set a single member here, just to make sure we still provide
		the enum typedef, but the values to use are defined above with L
		suffixes
	*/
	LAST = 4,
}

/* Special size_t value signaling a null-terminated string. */
ZERO_TERMINATED :: ~c.size_t(0)


/* Mime/form handling support. */
mime     :: struct {} /* Mime context. */
mimepart :: struct {} /* Mime part context. */


/* CURLMIMEOPT_ defines are for the CURLOPT_MIME_OPTIONS option. */
MIMEOPT_FORMESCAPE :: 1<<0 /* Use backslash-escaping for forms. */


@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	/* curl_strequal() and curl_strnequal() are subject for removal in a future release */
	strequal  :: proc(s1, s2: cstring) -> c.int ---
	strnequal :: proc(s1, s2: cstring, n: c.size_t) -> c.int ---


	/*
	 * NAME curl_mime_init()
	 *
	 * DESCRIPTION
	 *
	 * Create a mime context and return its handle. The easy parameter is the
	 * target handle.
	 */
	mime_init :: proc(easy: ^CURL) -> ^mime ---

	/*
	 * NAME curl_mime_free()
	 *
	 * DESCRIPTION
	 *
	 * release a mime handle and its substructures.
	 */
	mime_free :: proc(mime: ^mime) ---

	/*
	 * NAME curl_mime_addpart()
	 *
	 * DESCRIPTION
	 *
	 * Append a new empty part to the given mime context and return a handle to
	 * the created part.
	 */
	mime_addpart :: proc(mime: ^mime) -> ^mimepart ---

	/*
	 * NAME curl_mime_name()
	 *
	 * DESCRIPTION
	 *
	 * Set mime/form part name.
	 */
	mime_name :: proc(part: ^mimepart, name: cstring) -> code ---

	/*
	 * NAME curl_mime_filename()
	 *
	 * DESCRIPTION
	 *
	 * Set mime part remote filename.
	 */
	mime_filename :: proc(part: ^mimepart, filename: cstring) -> code ---

	/*
	 * NAME curl_mime_type()
	 *
	 * DESCRIPTION
	 *
	 * Set mime part type.
	 */
	mime_type :: proc(part: ^mimepart, mimetype: cstring) -> code ---

	/*
	 * NAME curl_mime_encoder()
	 *
	 * DESCRIPTION
	 *
	 * Set mime data transfer encoder.
	 */
	mime_encoder :: proc(part: ^mimepart, encoding: cstring) -> code ---

	/*
	 * NAME curl_mime_data()
	 *
	 * DESCRIPTION
	 *
	 * Set mime part data source from memory data,
	 */
	mime_data :: proc(part: ^mimepart, data: [^]byte, datasize: c.size_t) -> code ---

	/*
	 * NAME curl_mime_filedata()
	 *
	 * DESCRIPTION
	 *
	 * Set mime part data source from named file.
	 */
	mime_filedata :: proc(part: ^mimepart, filename: rawptr) -> code ---

	/*
	 * NAME curl_mime_data_cb()
	 *
	 * DESCRIPTION
	 *
	 * Set mime part data source from callback function.
	 */
	mime_data_cb :: proc(part: ^mimepart, datasize: off_t,
	                     readfunc: read_callback,
	                     seekfunc: seek_callback,
	                     freefunc: free_callback,
	                     arg: rawptr) -> code ---

	/*
	 * NAME curl_mime_subparts()
	 *
	 * DESCRIPTION
	 *
	 * Set mime part data source from subparts.
	 */
	mime_subparts :: proc(part: ^mimepart, subparts: ^mime) -> code ---
	/*
	 * NAME curl_mime_headers()
	 *
	 * DESCRIPTION
	 *
	 * Set mime part headers.
	 */
	mime_headers :: proc(part: ^mimepart, headers: ^slist, take_ownership: c.int) -> code ---
}


/*
 * callback function for curl_formget()
 * The void *arg pointer will be the one passed as second argument to
 *   curl_formget().
 * The character buffer passed to it must not be freed.
 * Should return the buffer length passed to it as the argument "len" on
 *   success.
 */
formget_callback :: #type proc "c" (arg: rawptr, buf: [^]byte, len: c.size_t) -> c.size_t

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	/*
	 * NAME curl_getenv()
	 *
	 * DESCRIPTION
	 *
	 * Returns a malloc()'ed string that MUST be curl_free()ed after usage is
	 * complete. DEPRECATED - see lib/README.curlx
	 */
	getenv :: proc(variable: cstring) -> cstring ---

	/*
	 * NAME curl_version()
	 *
	 * DESCRIPTION
	 *
	 * Returns a static ASCII string of the libcurl version.
	 */
	version :: proc() -> cstring ---

	/*
	 * NAME curl_easy_escape()
	 *
	 * DESCRIPTION
	 *
	 * Escapes URL strings (converts all letters consider illegal in URLs to their
	 * %XX versions). This function returns a new allocated string or NULL if an
	 * error occurred.
	 */
	easy_escape :: proc(handle: ^CURL, string: cstring, length: c.int) -> cstring ---

	/* the previous version: */
	escape :: proc(string: cstring, length: c.int) -> cstring ---


	/*
	 * NAME curl_easy_unescape()
	 *
	 * DESCRIPTION
	 *
	 * Unescapes URL encoding in strings (converts all %XX codes to their 8bit
	 * versions). This function returns a new allocated string or NULL if an error
	 * occurred.
	 * Conversion Note: On non-ASCII platforms the ASCII %XX codes are
	 * converted into the host encoding.
	 */
	easy_unescape :: proc(handle:    ^CURL,
	                      string:    cstring,
	                      length:    c.int,
	                      outlength: ^c.int) -> cstring ---

	/* the previous version */
	unescape :: proc(string: cstring, length: c.int) -> cstring ---

	/*
	 * NAME curl_free()
	 *
	 * DESCRIPTION
	 *
	 * Provided for de-allocation in the same translation unit that did the
	 * allocation. Added in libcurl 7.10
	 */
	free :: proc(p: rawptr) ---

	/*
	 * NAME curl_global_init()
	 *
	 * DESCRIPTION
	 *
	 * curl_global_init() should be invoked exactly once for each application that
	 * uses libcurl and before any call of other libcurl functions.

	 * This function is thread-safe if CURL_VERSION_THREADSAFE is set in the
	 * curl_version_info_data.features flag (fetch by curl_version_info()).

	 */
	global_init :: proc(flags: c.long) -> code ---

	/*
	 * NAME curl_global_init_mem()
	 *
	 * DESCRIPTION
	 *
	 * curl_global_init() or curl_global_init_mem() should be invoked exactly once
	 * for each application that uses libcurl. This function can be used to
	 * initialize libcurl and set user defined memory management callback
	 * functions. Users can implement memory management routines to check for
	 * memory leaks, check for mis-use of the curl library etc. User registered
	 * callback routines will be invoked by this library instead of the system
	 * memory management routines like malloc, free etc.
	 */
	global_init_mem :: proc(flags: c.long,
	                        m: malloc_callback,
	                        f: free_callback,
	                        r: realloc_callback,
	                        s: strdup_callback,
	                        c: calloc_callback) -> code ---

	/*
	 * NAME curl_global_cleanup()
	 *
	 * DESCRIPTION
	 *
	 * curl_global_cleanup() should be invoked exactly once for each application
	 * that uses libcurl
	 */
	global_cleanup :: proc() ---

	/*
	 * NAME curl_global_trace()
	 *
	 * DESCRIPTION
	 *
	 * curl_global_trace() can be invoked at application start to
	 * configure which components in curl should participate in tracing.

	 * This function is thread-safe if CURL_VERSION_THREADSAFE is set in the
	 * curl_version_info_data.features flag (fetch by curl_version_info()).

	 */
	global_trace :: proc(config: cstring) -> code ---
}

/*
 * NAME curl_global_sslset()
 *
 * DESCRIPTION
 *
 * When built with multiple SSL backends, curl_global_sslset() allows to
 * choose one. This function can only be called once, and it must be called
 * *before* curl_global_init().
 *
 * The backend can be identified by the id (e.g. CURLSSLBACKEND_OPENSSL). The
 * backend can also be specified via the name parameter (passing -1 as id). If
 * both id and name are specified, the name will be ignored. If neither id nor
 * name are specified, the function will fail with CURLSSLSET_UNKNOWN_BACKEND
 * and set the "avail" pointer to the NULL-terminated list of available
 * backends.
 *
 * Upon success, the function returns CURLSSLSET_OK.
 *
 * If the specified SSL backend is not available, the function returns
 * CURLSSLSET_UNKNOWN_BACKEND and sets the "avail" pointer to a
 * NULL-terminated list of available SSL backends.
 *
 * The SSL backend can be set only once. If it has already been set, a
 * subsequent attempt to change it will result in a CURLSSLSET_TOO_LATE.
 */
ssl_backend :: struct {
	id: sslbackend,
	name: cstring,
}

sslset :: enum c.int {
	OK = 0,
	UNKNOWN_BACKEND,
	TOO_LATE,
	NO_BACKENDS, /* libcurl was built without any SSL support */
}

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	global_sslset :: proc(id: sslbackend, name: cstring, avail: ^^^ssl_backend) -> sslset ---

	/*
	 * NAME curl_slist_append()
	 *
	 * DESCRIPTION
	 *
	 * Appends a string to a linked list. If no list exists, it will be created
	 * first. Returns the new list, after appending.
	 */
	slist_append :: proc(list: ^slist, data: [^]byte) -> ^slist ---

	/*
	 * NAME curl_slist_free_all()
	 *
	 * DESCRIPTION
	 *
	 * free a previously built curl_slist.
	 */
	slist_free_all :: proc(list: ^slist) ---

	/*
	 * NAME curl_getdate()
	 *
	 * DESCRIPTION
	 *
	 * Returns the time, in seconds since 1 Jan 1970 of the time string given in
	 * the first argument. The time argument in the second parameter is unused
	 * and should be set to NULL.
	 */
	getdate :: proc(p: cstring, unused: ^c.time_t) -> c.time_t ---
}

/*
	info about the certificate chain, for SSL backends that support it. Asked
	for with CURLOPT_CERTINFO / CURLINFO_CERTINFO
*/
certinfo :: struct {
	num_of_certs: c.int,  /* number of certificates with information */
	certinfo: ^^slist,    /* for each index in this array, there is a
	                         linked list with textual information for a
	                         certificate in the format "name:content".
	                         eg "Subject:foo", "Issuer:bar", etc. */
}

/*
	Information about the SSL library used and the respective internal SSL
	handle, which can be used to obtain further information regarding the
	connection. Asked for with CURLINFO_TLS_SSL_PTR or CURLINFO_TLS_SESSION.
*/
tlssessioninfo :: struct {
	backend:   sslbackend,
	internals: rawptr,
}


INFO_STRING   :: 0x100000
INFO_LONG     :: 0x200000
INFO_DOUBLE   :: 0x300000
INFO_SLIST    :: 0x400000
INFO_PTR      :: 0x400000 /* same as SLIST */
INFO_SOCKET   :: 0x500000
INFO_OFF_T    :: 0x600000
INFO_MASK     :: 0x0fffff
INFO_TYPEMASK :: 0xf00000

INFO :: enum c.int {
	NONE, /* first, never use this */
	EFFECTIVE_URL             = INFO_STRING + 1,
	RESPONSE_CODE             = INFO_LONG   + 2,
	TOTAL_TIME                = INFO_DOUBLE + 3,
	NAMELOOKUP_TIME           = INFO_DOUBLE + 4,
	CONNECT_TIME              = INFO_DOUBLE + 5,
	PRETRANSFER_TIME          = INFO_DOUBLE + 6,
	SIZE_UPLOAD_T             = INFO_OFF_T  + 7,
	SIZE_DOWNLOAD_T           = INFO_OFF_T  + 8,
	SPEED_DOWNLOAD_T          = INFO_OFF_T  + 9,
	SPEED_UPLOAD_T            = INFO_OFF_T  + 10,
	HEADER_SIZE               = INFO_LONG   + 11,
	REQUEST_SIZE              = INFO_LONG   + 12,
	SSL_VERIFYRESULT          = INFO_LONG   + 13,
	FILETIME                  = INFO_LONG   + 14,
	FILETIME_T                = INFO_OFF_T  + 14,
	CONTENT_LENGTH_DOWNLOAD_T = INFO_OFF_T  + 15,
	CONTENT_LENGTH_UPLOAD_T   = INFO_OFF_T  + 16,
	STARTTRANSFER_TIME        = INFO_DOUBLE + 17,
	CONTENT_TYPE              = INFO_STRING + 18,
	REDIRECT_TIME             = INFO_DOUBLE + 19,
	REDIRECT_COUNT            = INFO_LONG   + 20,
	PRIVATE                   = INFO_STRING + 21,
	HTTP_CONNECTCODE          = INFO_LONG   + 22,
	HTTPAUTH_AVAIL            = INFO_LONG   + 23,
	PROXYAUTH_AVAIL           = INFO_LONG   + 24,
	OS_ERRNO                  = INFO_LONG   + 25,
	NUM_CONNECTS              = INFO_LONG   + 26,
	SSL_ENGINES               = INFO_SLIST  + 27,
	COOKIELIST                = INFO_SLIST  + 28,
	FTP_ENTRY_PATH            = INFO_STRING + 30,
	REDIRECT_URL              = INFO_STRING + 31,
	PRIMARY_IP                = INFO_STRING + 32,
	APPCONNECT_TIME           = INFO_DOUBLE + 33,
	CERTINFO                  = INFO_PTR    + 34,
	CONDITION_UNMET           = INFO_LONG   + 35,
	RTSP_SESSION_ID           = INFO_STRING + 36,
	RTSP_CLIENT_CSEQ          = INFO_LONG   + 37,
	RTSP_SERVER_CSEQ          = INFO_LONG   + 38,
	RTSP_CSEQ_RECV            = INFO_LONG   + 39,
	PRIMARY_PORT              = INFO_LONG   + 40,
	LOCAL_IP                  = INFO_STRING + 41,
	LOCAL_PORT                = INFO_LONG   + 42,
	ACTIVESOCKET              = INFO_SOCKET + 44,
	TLS_SSL_PTR               = INFO_PTR    + 45,
	HTTP_VERSION              = INFO_LONG   + 46,
	PROXY_SSL_VERIFYRESULT    = INFO_LONG + 47,
	SCHEME                    = INFO_STRING + 49,
	TOTAL_TIME_T              = INFO_OFF_T + 50,
	NAMELOOKUP_TIME_T         = INFO_OFF_T + 51,
	CONNECT_TIME_T            = INFO_OFF_T + 52,
	PRETRANSFER_TIME_T        = INFO_OFF_T + 53,
	STARTTRANSFER_TIME_T      = INFO_OFF_T + 54,
	REDIRECT_TIME_T           = INFO_OFF_T + 55,
	APPCONNECT_TIME_T         = INFO_OFF_T + 56,
	RETRY_AFTER               = INFO_OFF_T + 57,
	EFFECTIVE_METHOD          = INFO_STRING + 58,
	PROXY_ERROR               = INFO_LONG + 59,
	REFERER                   = INFO_STRING + 60,
	CAINFO                    = INFO_STRING + 61,
	CAPATH                    = INFO_STRING + 62,
	XFER_ID                   = INFO_OFF_T + 63,
	CONN_ID                   = INFO_OFF_T + 64,
	QUEUE_TIME_T              = INFO_OFF_T + 65,
	USED_PROXY                = INFO_LONG + 66,
	POSTTRANSFER_TIME_T       = INFO_OFF_T + 67,
	EARLYDATA_SENT_T          = INFO_OFF_T + 68,
	HTTPAUTH_USED             = INFO_LONG + 69,
	PROXYAUTH_USED            = INFO_LONG + 70,

	/* CURLINFO_RESPONSE_CODE is the new name for the option previously known as
	   CURLINFO_HTTP_CODE */
	HTTP_CODE = RESPONSE_CODE,
}



closepolicy :: enum c.int {
	NONE, /* first, never use this */

	CURLCLOSEPOLICY_OLDEST,
	CURLCLOSEPOLICY_LEAST_RECENTLY_USED,
	CURLCLOSEPOLICY_LEAST_TRAFFIC,
	CURLCLOSEPOLICY_SLOWEST,
	CURLCLOSEPOLICY_CALLBACK,
}

GLOBAL_SSL       :: 1<<0 /* no purpose since 7.57.0 */
GLOBAL_WIN32     :: 1<<1
GLOBAL_ALL       :: (GLOBAL_SSL|GLOBAL_WIN32)
GLOBAL_NOTHING   :: 0
GLOBAL_DEFAULT   :: GLOBAL_ALL
GLOBAL_ACK_EINTR :: 1<<2



/* Different data locks for a single share */
lock_data :: enum c.int {
	NONE = 0,
	/*  CURL_LOCK_DATA_SHARE is used internally to say that
	*  the locking is just made to change the internal state of the share
	*  itself.
	*/
	SHARE,
	COOKIE,
	DNS,
	SSL_SESSION,
	CONNECT,
	PSL,
	HSTS,
}

/* Different lock access types */
lock_access :: enum c.int {
	NONE = 0,   /* unspecified action */
	SHARED = 1, /* for read perhaps */
	SINGLE = 2, /* for write perhaps */
}

lock_function :: #type proc "c" (handle:   ^CURL,
                                 data:     lock_data,
                                 locktype: lock_access,
                                 userptr:  rawptr)
unlock_function :: #type proc "c" (handle:  ^CURL,
                                   data:    lock_data,
                                   userptr: rawptr)


SHcode :: enum c.int {
	OK,  /* all is fine */
	BAD_OPTION, /* 1 */
	IN_USE,     /* 2 */
	INVALID,    /* 3 */
	NOMEM,      /* 4 out of memory */
	NOT_BUILT_IN, /* 5 feature not present in lib */
}

SHoption :: enum c.int {
	NONE,  /* do not use */
	CURLSHOPT_SHARE,   /* specify a data type to share */
	CURLSHOPT_UNSHARE, /* specify which data type to stop sharing */
	CURLSHOPT_LOCKFUNC,   /* pass in a 'curl_lock_function' pointer */
	CURLSHOPT_UNLOCKFUNC, /* pass in a 'curl_unlock_function' pointer */
	CURLSHOPT_USERDATA,   /* pass in a user data pointer used in the lock/unlock
	                         callback functions */
}


@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	share_init :: proc() -> ^CURLSH ---
	share_setopt  :: proc(share:  ^CURLSH, option: SHoption, #c_vararg args: ..any) -> SHcode ---
	share_cleanup :: proc(share:  ^CURLSH) -> SHcode ---
}


version_enum :: enum c.int {
	FIRST,    /* 7.10 */
	SECOND,   /* 7.11.1 */
	THIRD,    /* 7.12.0 */
	FOURTH,   /* 7.16.1 */
	FIFTH,    /* 7.57.0 */
	SIXTH,    /* 7.66.0 */
	SEVENTH,  /* 7.70.0 */
	EIGHTH,   /* 7.72.0 */
	NINTH,    /* 7.75.0 */
	TENTH,    /* 7.77.0 */
	ELEVENTH, /* 7.87.0 */
	TWELFTH,  /* 8.8.0 */
}

/*
	The 'CURLVERSION_NOW' is the symbolic name meant to be used by
	basically all programs ever that want to get version information. It is
	meant to be a built-in version number for what kind of struct the caller
	expects. If the struct ever changes, we redefine the NOW to another enum
	from above.
*/
VERSION_NOW :: version_enum.TWELFTH

version_info_data :: struct {
	age:             version_enum, /* age of the returned struct */
	version:         cstring, /* LIBCURL_VERSION */
	version_num:     c.uint,  /* LIBCURL_VERSION_NUM */
	host:            cstring, /* OS/host/cpu/machine when configured */
	features:        c.int,   /* bitmask, see defines below */
	ssl_version:     cstring, /* human readable string */
	ssl_version_num: c.long,  /* not used anymore, always 0 */
	libz_version:    cstring, /* human readable string */
	/* protocols is terminated by an entry with a NULL protoname */
	protocols: [^]cstring,

	/* The fields below this were added in CURLVERSION_SECOND */
	ares: cstring,
	ares_num: c.int,

	/* This field was added in CURLVERSION_THIRD */
	libidn: cstring,

	/* These field were added in CURLVERSION_FOURTH */

	/* Same as '_libiconv_version' if built with HAVE_ICONV */
	iconv_ver_num: c.int,

	libssh_version: cstring, /* human readable string */

	/* These fields were added in CURLVERSION_FIFTH */
	brotli_ver_num: c.uint, /* Numeric Brotli version
	                          (MAJOR << 24) | (MINOR << 12) | PATCH */
	brotli_version: cstring, /* human readable string. */

	/* These fields were added in CURLVERSION_SIXTH */
	nghttp2_ver_num: c.uint, /* Numeric nghttp2 version
	                           (MAJOR << 16) | (MINOR << 8) | PATCH */
	nghttp2_version: cstring, /* human readable string. */
	quic_version: cstring,    /* human readable quic (+ HTTP/3) library +
	                             version or NULL */

	/* These fields were added in CURLVERSION_SEVENTH */
	cainfo: cstring,          /* the built-in default CURLOPT_CAINFO, might
	                             be NULL */
	capath: cstring,          /* the built-in default CURLOPT_CAPATH, might
                                     be NULL */

	/* These fields were added in CURLVERSION_EIGHTH */
	zstd_ver_num: c.uint, /* Numeric Zstd version
	                          (MAJOR << 24) | (MINOR << 12) | PATCH */
	zstd_version: cstring, /* human readable string. */

	/* These fields were added in CURLVERSION_NINTH */
	hyper_version: cstring, /* human readable string. */

	/* These fields were added in CURLVERSION_TENTH */
	gsasl_version: cstring, /* human readable string. */

	/* These fields were added in CURLVERSION_ELEVENTH */
	/* feature_names is terminated by an entry with a NULL feature name */
	feature_names: [^]cstring,

	/* These fields were added in CURLVERSION_TWELFTH */
	rtmp_version: cstring, /* human readable string. */
}

VERSION_IPV6         :: 1<<0  /* IPv6-enabled */
VERSION_KERBEROS4    :: 1<<1  /* Kerberos V4 auth is supported (deprecated) */
VERSION_SSL          :: 1<<2  /* SSL options are present */
VERSION_LIBZ         :: 1<<3  /* libz features are present */
VERSION_NTLM         :: 1<<4  /* NTLM auth is supported */
VERSION_GSSNEGOTIATE :: 1<<5  /* Negotiate auth is supported (deprecated) */
VERSION_DEBUG        :: 1<<6  /* Built with debug capabilities */
VERSION_ASYNCHDNS    :: 1<<7  /* Asynchronous DNS resolves */
VERSION_SPNEGO       :: 1<<8  /* SPNEGO auth is supported */
VERSION_LARGEFILE    :: 1<<9  /* Supports files larger than 2GB */
VERSION_IDN          :: 1<<10 /* Internationized Domain Names are supported */
VERSION_SSPI         :: 1<<11 /* Built against Windows SSPI */
VERSION_CONV         :: 1<<12 /* Character conversions supported */
VERSION_CURLDEBUG    :: 1<<13 /* Debug memory tracking supported */
VERSION_TLSAUTH_SRP  :: 1<<14 /* TLS-SRP auth is supported */
VERSION_NTLM_WB      :: 1<<15 /* NTLM delegation to winbind helper is supported */
VERSION_HTTP2        :: 1<<16 /* HTTP2 support built-in */
VERSION_GSSAPI       :: 1<<17 /* Built against a GSS-API library */
VERSION_KERBEROS5    :: 1<<18 /* Kerberos V5 auth is supported */
VERSION_UNIX_SOCKETS :: 1<<19 /* Unix domain sockets support */
VERSION_PSL          :: 1<<20 /* Mozilla's Public Suffix List, used for cookie domain verification */
VERSION_HTTPS_PROXY  :: 1<<21 /* HTTPS-proxy support built-in */
VERSION_MULTI_SSL    :: 1<<22 /* Multiple SSL backends available */
VERSION_BROTLI       :: 1<<23 /* Brotli features are present. */
VERSION_ALTSVC       :: 1<<24 /* Alt-Svc handling built-in */
VERSION_HTTP3        :: 1<<25 /* HTTP3 support built-in */
VERSION_ZSTD         :: 1<<26 /* zstd features are present */
VERSION_UNICODE      :: 1<<27 /* Unicode support on Windows */
VERSION_HSTS         :: 1<<28 /* HSTS is supported */
VERSION_GSASL        :: 1<<29 /* libgsasl is supported */
VERSION_THREADSAFE   :: 1<<30 /* libcurl API is thread-safe */


PAUSE_RECV      :: 1<<0
PAUSE_RECV_CONT :: 0

PAUSE_SEND      :: 1<<2
PAUSE_SEND_CONT :: 0

PAUSE_ALL       :: PAUSE_RECV|PAUSE_SEND
PAUSE_CONT      :: PAUSE_RECV_CONT|PAUSE_SEND_CONT

/* This is the curl_ssls_export_cb callback prototype. It is passed to curl_easy_ssls_export() to extract SSL sessions/tickets. */
ssls_export_cb :: #type proc "c" (handle: ^CURL,
                                  userptr: rawptr,
                                  session_key: cstring,
                                  shmac: [^]u8,
                                  shmac_len: c.size_t,
                                  sdata: [^]u8,
                                  sdata_len: c.size_t,
                                  valid_until: off_t,
                                  ietf_tls_id: c.int,
                                  alpn: cstring,
                                  earlydata_max: c.size_t) -> code

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	/*
	 * NAME curl_version_info()
	 *
	 * DESCRIPTION
	 *
	 * This function returns a pointer to a static copy of the version info
	 * struct. See above.
	 */
	version_info :: proc(version_enum) -> ^version_info_data ---

	/*
	 * NAME curl_easy_strerror()
	 *
	 * DESCRIPTION
	 *
	 * The curl_easy_strerror function may be used to turn a CURLcode value
	 * into the equivalent human readable error string. This is useful
	 * for printing meaningful error messages.
	 */
	easy_strerror :: proc(code) -> cstring ---

	/*
	 * NAME curl_share_strerror()
	 *
	 * DESCRIPTION
	 *
	 * The curl_share_strerror function may be used to turn a CURLSHcode value
	 * into the equivalent human readable error string. This is useful
	 * for printing meaningful error messages.
	 */
	share_strerror :: proc(SHcode) -> cstring ---

	/*
	 * NAME curl_easy_pause()
	 *
	 * DESCRIPTION
	 *
	 * The curl_easy_pause function pauses or unpauses transfers. Select the new
	 * state by setting the bitmask, use the convenience defines below.
	 *
	 */
	easy_pause :: proc(handle: ^CURL, bitmask: c.uint) -> code ---

	/*
	 * NAME curl_easy_ssls_import()
	 *
	 * DESCRIPTION
	 *
	 * The curl_easy_ssls_import function adds a previously exported SSL session
	 * to the SSL session cache of the easy handle (or the underlying share).
	 */
	easy_ssls_import :: proc(handle: ^CURL,
	                         session_key: cstring,
	                         shmac: [^]u8,
	                         shmac_len: c.size_t,
	                         sdata: [^]u8,
	                         sdata_len: c.size_t) -> code ---

	/*
	 * NAME curl_easy_ssls_export()
	 *
	 * DESCRIPTION
	 *
	 * The curl_easy_ssls_export function iterates over all SSL sessions stored
	 * in the easy handle (or underlying share) and invokes the passed
	 * callback.
	 *
	 */
	easy_ssls_export :: proc(handle: ^CURL,
	                         export_fn: ssls_export_cb,
	                         userptr: rawptr) -> code ---


}