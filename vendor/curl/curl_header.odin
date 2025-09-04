package vendor_curl

import c "core:c/libc"


header :: struct {
	name:   cstring,  /* this might not use the same case */
	value:  cstring,
	amount: c.size_t, /* number of headers using this name  */
	index:  c.size_t, /* ... of this instance, 0 or higher */
	origin: header_origin_bits, /* see bits below */
	anchor: rawptr,   /* handle privately used by libcurl */
}

header_origin_bits :: distinct bit_set[header_origin_bit; c.uint]
/* 'origin' bits */
header_origin_bit :: enum c.uint {
	H_HEADER  = 0, /* plain server header */
	H_TRAILER = 1, /* trailers */
	H_CONNECT = 2, /* CONNECT headers */
	H_1XX     = 3, /* 1xx headers */
	H_PSEUDO  = 4, /* pseudo headers */
}

H_HEADER  :: header_origin_bits{.H_HEADER} /* plain server header */
H_TRAILER :: header_origin_bits{.H_TRAILER} /* trailers */
H_CONNECT :: header_origin_bits{.H_CONNECT} /* CONNECT headers */
H_1XX     :: header_origin_bits{.H_1XX} /* 1xx headers */
H_PSEUDO  :: header_origin_bits{.H_PSEUDO} /* pseudo headers */

Hcode :: enum c.int {
	E_OK,
	E_BADINDEX,      /* header exists but not with this index */
	E_MISSING,       /* no such header exists */
	E_NOHEADERS,     /* no headers at all exist (yet) */
	E_NOREQUEST,     /* no request with this number was used */
	E_OUT_OF_MEMORY, /* out of memory while processing */
	E_BAD_ARGUMENT,  /* a function argument was not okay */
	E_NOT_BUILT_IN,  /* if API was disabled in the build */
}

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	easy_header :: proc(easy:    ^CURL,
	                    name:    cstring,
	                    index:   c.size_t,
	                    origin:  c.uint,
	                    request: c.int,
	                    hout:    ^^header) -> Hcode ---

	easy_nextheader :: proc(easy:    ^CURL,
	                        origin:  c.uint,
	                        request: c.int,
	                        prev:    ^header) -> ^header ---
}