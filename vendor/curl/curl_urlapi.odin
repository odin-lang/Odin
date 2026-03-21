package vendor_curl

import c "core:c/libc"

CURLU :: struct {}

/* the error codes for the URL API */
Ucode :: enum c.int {
	E_OK,
	E_BAD_HANDLE,          /* 1 */
	E_BAD_PARTPOINTER,     /* 2 */
	E_MALFORMED_INPUT,     /* 3 */
	E_BAD_PORT_NUMBER,     /* 4 */
	E_UNSUPPORTED_SCHEME,  /* 5 */
	E_URLDECODE,           /* 6 */
	E_OUT_OF_MEMORY,       /* 7 */
	E_USER_NOT_ALLOWED,    /* 8 */
	E_UNKNOWN_PART,        /* 9 */
	E_NO_SCHEME,           /* 10 */
	E_NO_USER,             /* 11 */
	E_NO_PASSWORD,         /* 12 */
	E_NO_OPTIONS,          /* 13 */
	E_NO_HOST,             /* 14 */
	E_NO_PORT,             /* 15 */
	E_NO_QUERY,            /* 16 */
	E_NO_FRAGMENT,         /* 17 */
	E_NO_ZONEID,           /* 18 */
	E_BAD_FILE_URL,        /* 19 */
	E_BAD_FRAGMENT,        /* 20 */
	E_BAD_HOSTNAME,        /* 21 */
	E_BAD_IPV6,            /* 22 */
	E_BAD_LOGIN,           /* 23 */
	E_BAD_PASSWORD,        /* 24 */
	E_BAD_PATH,            /* 25 */
	E_BAD_QUERY,           /* 26 */
	E_BAD_SCHEME,          /* 27 */
	E_BAD_SLASHES,         /* 28 */
	E_BAD_USER,            /* 29 */
	E_LACKS_IDN,           /* 30 */
	E_TOO_LARGE,           /* 31 */
}

UPart :: enum c.int {
	URL,
	SCHEME,
	USER,
	PASSWORD,
	OPTIONS,
	HOST,
	PORT,
	PATH,
	QUERY,
	FRAGMENT,
	ZONEID, /* added in 7.65.0 */
}

UFlags :: distinct bit_set[UFlag; c.uint]
UFlag :: enum c.uint {
	DEFAULT_PORT       =  0,  /* return default port number */
	NO_DEFAULT_PORT    =  1,  /* act as if no port number was set,
	                             if the port number matches the
	                             default for the scheme */
	DEFAULT_SCHEME     =  2,  /* return default scheme if
	                             missing */
	NON_SUPPORT_SCHEME =  3,  /* allow non-supported scheme */
	PATH_AS_IS         =  4,  /* leave dot sequences */
	DISALLOW_USER      =  5,  /* no user+password allowed */
	URLDECODE          =  6,  /* URL decode on get */
	URLENCODE          =  7,  /* URL encode on set */
	APPENDQUERY        =  8,  /* append a form style part */
	GUESS_SCHEME       =  9,  /* legacy curl-style guessing */
	NO_AUTHORITY       =  10, /* Allow empty authority when the
	                             scheme is unknown. */
	ALLOW_SPACE        =  11, /* Allow spaces in the URL */
	PUNYCODE           =  12, /* get the hostname in punycode */
	PUNY2IDN           =  13, /* punycode => IDN conversion */
	GET_EMPTY          =  14, /* allow empty queries and fragments
	                             when extracting the URL or the
	                             components */
	NO_GUESS_SCHEME    =  15, /* for get, do not accept a guess */
}

U_DEFAULT_PORT       :: UFlags{.DEFAULT_PORT}
U_NO_DEFAULT_PORT    :: UFlags{.NO_DEFAULT_PORT}
U_DEFAULT_SCHEME     :: UFlags{.DEFAULT_SCHEME}
U_NON_SUPPORT_SCHEME :: UFlags{.NON_SUPPORT_SCHEME}
U_PATH_AS_IS         :: UFlags{.PATH_AS_IS}
U_DISALLOW_USER      :: UFlags{.DISALLOW_USER}
U_URLDECODE          :: UFlags{.URLDECODE}
U_URLENCODE          :: UFlags{.URLENCODE}
U_APPENDQUERY        :: UFlags{.APPENDQUERY}
U_GUESS_SCHEME       :: UFlags{.GUESS_SCHEME}
U_NO_AUTHORITY       :: UFlags{.NO_AUTHORITY}
U_ALLOW_SPACE        :: UFlags{.ALLOW_SPACE}
U_PUNYCODE           :: UFlags{.PUNYCODE}
U_PUNY2IDN           :: UFlags{.PUNY2IDN}
U_GET_EMPTY          :: UFlags{.GET_EMPTY}
U_NO_GUESS_SCHEME    :: UFlags{.NO_GUESS_SCHEME}

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	/*
	 * curl_url() creates a new CURLU handle and returns a pointer to it.
	 * Must be freed with curl_url_cleanup().
	 */
	url :: proc() -> ^CURLU ---

	/*
	 * curl_url_cleanup() frees the CURLU handle and related resources used for
	 * the URL parsing. It will not free strings previously returned with the URL
	 * API.
	 */
	url_cleanup :: proc(handle: ^CURLU) ---

	/*
	 * curl_url_dup() duplicates a CURLU handle and returns a new copy. The new
	 * handle must also be freed with curl_url_cleanup().
	 */
	url_dup :: proc(input: ^CURLU) -> ^CURLU ---

	/*
	 * curl_url_get() extracts a specific part of the URL from a CURLU
	 * handle. Returns error code. The returned pointer MUST be freed with
	 * curl_free() afterwards.
	 */
	url_get :: proc(handle: ^CURLU, what: UPart, part: ^[^]byte, flags: UFlags) -> ^Ucode ---

	/*
	 * curl_url_set() sets a specific part of the URL in a CURLU handle. Returns
	 * error code. The passed in string will be copied. Passing a NULL instead of
	 * a part string, clears that part.
	 */
	url_set :: proc(handle: ^CURLU, what: UPart, part: cstring, flags: UFlags) -> Ucode ---

	/*
	 * curl_url_strerror() turns a CURLUcode value into the equivalent human
	 * readable error string. This is useful for printing meaningful error
	 * messages.
	 */
	url_strerror :: proc(Ucode) -> cstring ---
}
