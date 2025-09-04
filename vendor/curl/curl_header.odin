package vendor_curl

import c "core:c/libc"


header :: struct {
	name:   cstring,  /* this might not use the same case */
	value:  cstring,
	amount: c.size_t, /* number of headers using this name  */
	index:  c.size_t, /* ... of this instance, 0 or higher */
	origin: c.uint,   /* see bits below */
	anchor: rawptr,   /* handle privately used by libcurl */
}

/* 'origin' bits */
H_HEADER  :: 1<<0 /* plain server header */
H_TRAILER :: 1<<1 /* trailers */
H_CONNECT :: 1<<2 /* CONNECT headers */
H_1XX     :: 1<<3 /* 1xx headers */
H_PSEUDO  :: 1<<4 /* pseudo headers */

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