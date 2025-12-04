package vendor_curl

import c "core:c/libc"

CURLM :: struct {}

Mcode :: enum c.int {
	CALL_MULTI_PERFORM = -1, /* please call curl_multi_perform() or
                                    curl_multi_socket*() soon */
	OK,
	BAD_HANDLE,      /* the passed-in handle is not a valid CURLM handle */
	BAD_EASY_HANDLE, /* an easy handle was not good/valid */
	OUT_OF_MEMORY,   /* if you ever get this, you are in deep sh*t */
	INTERNAL_ERROR,  /* this is a libcurl bug */
	BAD_SOCKET,      /* the passed in socket argument did not match */
	UNKNOWN_OPTION,  /* curl_multi_setopt() with unsupported option */
	ADDED_ALREADY,   /* an easy handle already added to a multi handle was
                            attempted to get added - again */
	RECURSIVE_API_CALL, /* an api function was called from inside a
                               callback */
	WAKEUP_FAILURE,  /* wakeup is unavailable or failed */
	BAD_FUNCTION_ARGUMENT, /* function called with a bad parameter */
	ABORTED_BY_CALLBACK,
	UNRECOVERABLE_POLL,

	CALL_MULTI_SOCKET = CALL_MULTI_PERFORM,
}


/* bitmask bits for CURLMOPT_PIPELINING */
PIPE_NOTHING   :: 0
PIPE_HTTP1     :: 1
PIPE_MULTIPLEX :: 2


MSG :: enum c.int {
	NONE, /* first, not used */
	DONE, /* This easy handle has completed. 'result' contains
	          the CURLcode of the transfer */
}

Msg :: struct {
	msg: MSG,       /* what this message means */
	easy_handle: ^CURL, /* the handle it concerns */
	data: struct #raw_union {
		whatever: rawptr,    /* message-specific data */
		result: code,   /* return code for transfer */
	},
}

/* Based on poll(2) structure and values.
 * We do not use pollfd and POLL* constants explicitly
 * to cover platforms without poll(). */
WAIT_POLLIN  :: 0x0001
WAIT_POLLPRI :: 0x0002
WAIT_POLLOUT :: 0x0004

waitfd :: struct {
	fd: socket_t,
	events:  c.short,
	revents: c.short,
}


@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	/*
	 * Name:    curl_multi_init()
	 *
	 * Desc:    initialize multi-style curl usage
	 *
	 * Returns: a new CURLM handle to use in all 'curl_multi' functions.
	 */
	multi_init :: proc() -> ^CURLM ---

	/*
	 * Name:    curl_multi_add_handle()
	 *
	 * Desc:    add a standard curl handle to the multi stack
	 *
	 * Returns: CURLMcode type, general multi error code.
	 */
	multi_add_handle :: proc(multi_handle: ^CURLM, curl_handle: ^CURL) -> Mcode ---

	 /*
	  * Name:    curl_multi_remove_handle()
	  *
	  * Desc:    removes a curl handle from the multi stack again
	  *
	  * Returns: CURLMcode type, general multi error code.
	  */
	multi_remove_handle :: proc(multi_handle: ^CURLM, curl_handle: ^CURL) -> Mcode ---

	 /*
	  * Name:    curl_multi_fdset()
	  *
	  * Desc:    Ask curl for its fd_set sets. The app can use these to select() or
	  *          poll() on. We want curl_multi_perform() called as soon as one of
	  *          them are ready.
	  *
	  * Returns: CURLMcode type, general multi error code.
	  */
	multi_fdset :: proc(multi_handle: ^CURLM,
	                    read_fd_set:  ^platform_fd_set,
	                    write_fd_set: ^platform_fd_set,
	                    exc_fd_set:   ^platform_fd_set,
	                    max_fd: ^c.int) -> Mcode ---

	/*
	 * Name:     curl_multi_wait()
	 *
	 * Desc:     Poll on all fds within a CURLM set as well as any
	 *           additional fds passed to the function.
	 *
	 * Returns:  CURLMcode type, general multi error code.
	 */
	multi_wait :: proc(multi_handle: ^CURLM,
	                   extra_fds: [^]waitfd,
	                   extra_nfds: c.uint,
	                   timeout_ms: c.int,
	                   ret: ^c.int) -> Mcode ---

	/*
	 * Name:     curl_multi_poll()
	 *
	 * Desc:     Poll on all fds within a CURLM set as well as any
	 *           additional fds passed to the function.
	 *
	 * Returns:  CURLMcode type, general multi error code.
	 */
	multi_poll :: proc(multi_handle: ^CURLM,
	                   extra_fds: [^]waitfd,
	                   extra_nfds: c.uint,
	                   timeout_ms: c.int,
	                   ret: ^c.int) -> Mcode ---

	/*
	 * Name:     curl_multi_wakeup()
	 *
	 * Desc:     wakes up a sleeping curl_multi_poll call.
	 *
	 * Returns:  CURLMcode type, general multi error code.
	 */
	multi_wakeup :: proc(multi_handle: ^CURLM) -> Mcode ---

	 /*
	  * Name:    curl_multi_perform()
	  *
	  * Desc:    When the app thinks there is data available for curl it calls this
	  *          function to read/write whatever there is right now. This returns
	  *          as soon as the reads and writes are done. This function does not
	  *          require that there actually is data available for reading or that
	  *          data can be written, it can be called just in case. It returns
	  *          the number of handles that still transfer data in the second
	  *          argument's integer-pointer.
	  *
	  * Returns: CURLMcode type, general multi error code. *NOTE* that this only
	  *          returns errors etc regarding the whole multi stack. There might
	  *          still have occurred problems on individual transfers even when
	  *          this returns OK.
	  */
	multi_perform :: proc(multi_handle: ^CURLM, running_handles: ^c.int) -> Mcode ---

	 /*
	  * Name:    curl_multi_cleanup()
	  *
	  * Desc:    Cleans up and removes a whole multi stack. It does not free or
	  *          touch any individual easy handles in any way. We need to define
	  *          in what state those handles will be if this function is called
	  *          in the middle of a transfer.
	  *
	  * Returns: CURLMcode type, general multi error code.
	  */
	multi_cleanup :: proc(multi_handle: ^CURLM) -> Mcode ---

	/*
	 * Name:    curl_multi_info_read()
	 *
	 * Desc:    Ask the multi handle if there is any messages/informationals from
	 *          the individual transfers. Messages include informationals such as
	 *          error code from the transfer or just the fact that a transfer is
	 *          completed. More details on these should be written down as well.
	 *
	 *          Repeated calls to this function will return a new struct each
	 *          time, until a special "end of msgs" struct is returned as a signal
	 *          that there is no more to get at this point.
	 *
	 *          The data the returned pointer points to will not survive calling
	 *          curl_multi_cleanup().
	 *
	 *          The 'CURLMsg' struct is meant to be simple and only contain basic
	 *          information. If more involved information is wanted, we will
	 *          provide the particular "transfer handle" in that struct and that
	 *          should/could/would be used in subsequent curl_easy_getinfo() calls
	 *          (or similar). The point being that we must never expose complex
	 *          structs to applications, as then we will undoubtably get backwards
	 *          compatibility problems in the future.
	 *
	 * Returns: A pointer to a filled-in struct, or NULL if it failed or ran out
	 *          of structs. It also writes the number of messages left in the
	 *          queue (after this read) in the integer the second argument points
	 *          to.
	 */
	multi_info_read :: proc(multi_handle: ^CURLM, msgs_in_queue: ^c.int) -> ^Msg ---

	/*
	 * Name:    curl_multi_strerror()
	 *
	 * Desc:    The curl_multi_strerror function may be used to turn a CURLMcode
	 *          value into the equivalent human readable error string. This is
	 *          useful for printing meaningful error messages.
	 *
	 * Returns: A pointer to a null-terminated error message.
	 */
	multi_strerror :: proc(Mcode) -> cstring ---

}


/*
 * Name:    curl_multi_socket() and
 *          curl_multi_socket_all()
 *
 * Desc:    An alternative version of curl_multi_perform() that allows the
 *          application to pass in one of the file descriptors that have been
 *          detected to have "action" on them and let libcurl perform.
 *          See manpage for details.
 */
POLL_NONE   :: 0
POLL_IN     :: 1
POLL_OUT    :: 2
POLL_INOUT  :: 3
POLL_REMOVE :: 4

SOCKET_TIMEOUT :: SOCKET_BAD

CSELECT_IN   :: 0x01
CSELECT_OUT  :: 0x02
CSELECT_ERR  :: 0x04

socket_callback :: #type proc "c" (
	easy:    ^CURL,    /* easy handle */
	s:       socket_t, /* socket */
	what:    c.int,    /* see above */
	userp:   rawptr,   /* private callback pointer */
	socketp: rawptr,
) -> c.int  /* private socket pointer */

/*
 * Name:    curl_multi_timer_callback
 *
 * Desc:    Called by libcurl whenever the library detects a change in the
 *          maximum number of milliseconds the app is allowed to wait before
 *          curl_multi_socket() or curl_multi_perform() must be called
 *          (to allow libcurl's timed events to take place).
 *
 * Returns: The callback should return zero.
 */
multi_timer_callback :: #type proc "c" (multi: ^CURLM,          /* multi handle */
                                        timeout_ms: c.long,     /* see above */
                                        userp: rawptr) -> c.int /* private callback pointer */


@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	multi_socket_action :: proc(multi_handle:    ^CURLM,
	                            s:               socket_t,
	                            ev_bitmask:      c.int,
	                            running_handles: ^c.int) -> Mcode ---


	/*
	 * Name:    curl_multi_timeout()
	 *
	 * Desc:    Returns the maximum number of milliseconds the app is allowed to
	 *          wait before curl_multi_socket() or curl_multi_perform() must be
	 *          called (to allow libcurl's timed events to take place).
	 *
	 * Returns: CURLM error code.
	 */
	multi_timeout :: proc(multi_handle: ^CURLM, milliseconds: ^c.long) -> Mcode ---
}


Moption :: enum c.int {
	/* This is the socket callback function pointer */
	SOCKETFUNCTION = OPTTYPE_FUNCTIONPOINT + 1,

	/* This is the argument passed to the socket callback */
	SOCKETDATA = OPTTYPE_OBJECTPOINT + 2,

	/* set to 1 to enable pipelining for this multi handle */
	PIPELINING = OPTTYPE_LONG + 3,

	/* This is the timer callback function pointer */
	TIMERFUNCTION = OPTTYPE_FUNCTIONPOINT + 4,

	/* This is the argument passed to the timer callback */
	TIMERDATA = OPTTYPE_OBJECTPOINT + 5,

	/* maximum number of entries in the connection cache */
	MAXCONNECTS = OPTTYPE_LONG + 6,

	/* maximum number of (pipelining) connections to one host */
	MAX_HOST_CONNECTIONS = OPTTYPE_LONG + 7,

	/* maximum number of requests in a pipeline */
	MAX_PIPELINE_LENGTH = OPTTYPE_LONG + 8,

	/* a connection with a content-length longer than this
	will not be considered for pipelining */
	CONTENT_LENGTH_PENALTY_SIZE = OPTTYPE_OFF_T + 9,

	/* a connection with a chunk length longer than this
	will not be considered for pipelining */
	CHUNK_LENGTH_PENALTY_SIZE = OPTTYPE_OFF_T + 10,

	/* a list of site names(+port) that are blocked from pipelining */
	PIPELINING_SITE_BL = OPTTYPE_OBJECTPOINT + 11,

	/* a list of server types that are blocked from pipelining */
	PIPELINING_SERVER_BL = OPTTYPE_OBJECTPOINT + 12,

	/* maximum number of open connections in total */
	MAX_TOTAL_CONNECTIONS = OPTTYPE_LONG + 13,

	/* This is the server push callback function pointer */
	PUSHFUNCTION = OPTTYPE_FUNCTIONPOINT + 14,

	/* This is the argument passed to the server push callback */
	PUSHDATA = OPTTYPE_OBJECTPOINT + 15,

	/* maximum number of concurrent streams to support on a connection */
	MAX_CONCURRENT_STREAMS = OPTTYPE_LONG + 16,

	/* network has changed, adjust caches/connection reuse */
	NETWORK_CHANGED = OPTTYPE_LONG + 17,

	/* This is the notify callback function pointer */
	NOTIFYFUNCTION = OPTTYPE_FUNCTIONPOINT + 18,

	/* This is the argument passed to the notify callback */
	NOTIFYDATA = OPTTYPE_OBJECTPOINT + 19,
}

/* Definition of bits for the CURLMOPT_NETWORK_CHANGED argument: */

/* - CURLMNWC_CLEAR_CONNS tells libcurl to prevent further reuse of existing
     connections. Connections that are idle will be closed. Ongoing transfers
     will continue with the connection they have. */
MNWC_CLEAR_CONNS :: 1 << 0

/* - CURLMNWC_CLEAR_DNS tells libcurl to prevent further reuse of existing
     connections. Connections that are idle will be closed. Ongoing transfers
     will continue with the connection they have. */
MNWC_CLEAR_DNS :: 1 << 0

Minfo :: enum c.int {
	/* first, never use this */
	NONE = 0,
	/* The number of easy handles currently managed by the multi handle,
	 * e.g. have been added but not yet removed. */
	XFERS_CURRENT = 1,
	/* The number of easy handles running, e.g. not done and not queueing. */
	XFERS_RUNNING = 2,
	/* The number of easy handles waiting to start, e.g. for a connection
	 * to become available due to limits on parallelism, max connections
	 * or other factors. */
	INFO_XFERS_PENDING = 3,
	/* The number of easy handles finished, waiting for their results to
	 * be read via `curl_multi_info_read()`. */
	XFERS_DONE = 4,
	/* The total number of easy handles added to the multi handle, ever. */
	XFERS_ADDED = 5,

	/* the last unused */
	LASTENTRY,
}

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	/*
	 * Name:    curl_multi_setopt()
	 *
	 * Desc:    Sets options for the multi handle.
	 *
	 * Returns: CURLM error code.
	 */
	multi_setopt :: proc(multi_handle: ^CURLM, option: Moption, #c_vararg args: ..any) -> Mcode ---


	/*
	 * Name:    curl_multi_assign()
	 *
	 * Desc:    This function sets an association in the multi handle between the
	 *          given socket and a private pointer of the application. This is
	 *          (only) useful for curl_multi_socket uses.
	 *
	 * Returns: CURLM error code.
	 */
	multi_assign :: proc(multi_handle: ^CURLM, sockfd: socket_t, sockp: rawptr) -> Mcode ---

	/*
	 * Name:    curl_multi_get_handles()
	 *
	 * Desc:    Returns an allocated array holding all handles currently added to
	 *          the multi handle. Marks the final entry with a NULL pointer. If
	 *          there is no easy handle added to the multi handle, this function
	 *          returns an array with the first entry as a NULL pointer.
	 *
	 * Returns: NULL on failure, otherwise a CURL **array pointer
	 */
	multi_get_handles :: proc(multi_handle: ^CURLM) -> ^^CURL ---

	/*
	 * Name:    curl_multi_get_offt()
	 *
	 * Desc:    Retrieves a numeric value for the `CURLMINFO_*` enums.
	 *
	 * Returns: CULRM_OK or error when value could not be obtained.
	*/
	multi_get_offt :: proc(multi_handle: ^CURLM, info: Minfo, value: ^off_t) -> Mcode ---
}


/*
 * Notifications dispatched by a multi handle, when enabled.
 */
MULTI_NOTIFY :: enum c.uint {
	INFO_READ = 0,
	EASY_DONE = 1,
}

/*
 * Callback to install via CURLMOPT_NOTIFYFUNCTION.
 */
curl_notify_function :: #type proc "c" (multi_handle: ^CURLM, notification: MULTI_NOTIFY, easy: ^CURL, user_data: rawptr)

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	multi_notify_disable :: proc(multi: ^CURLM, notification: MULTI_NOTIFY) -> Mcode ---
	multi_notify_enable  :: proc(multi: ^CURLM, notification: MULTI_NOTIFY) -> Mcode ---
}

/*
 * Name: curl_push_callback
 *
 * Desc: This callback gets called when a new stream is being pushed by the
 *       server. It approves or denies the new stream. It can also decide
 *       to completely fail the connection.
 *
 * Returns: CURL_PUSH_OK, CURL_PUSH_DENY or CURL_PUSH_ERROROUT
 */
PUSH_OK       :: 0
PUSH_DENY     :: 1
PUSH_ERROROUT :: 2 /* added in 7.72.0 */


pushheaders :: struct {}

push_callback :: #type proc "c"(parent:      ^CURL,
                                easy:        ^CURL,
                                num_headers: c.size_t,
                                headers:     [^]pushheaders,
                                userp:       rawptr) -> c.int

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	pushheader_bynum  :: proc(h: ^pushheaders, num: c.size_t) -> cstring ---
	pushheader_byname :: proc(h: ^pushheaders, name: cstring) -> cstring ---

	/*
	 * Name:    curl_multi_waitfds()
	 *
	 * Desc:    Ask curl for fds for polling. The app can use these to poll on.
	 *          We want curl_multi_perform() called as soon as one of them are
	 *          ready. Passing zero size allows to get just a number of fds.
	 *
	 * Returns: CURLMcode type, general multi error code.
	 */
	multi_waitfds :: proc(multi: ^CURLM,
	                      ufds: [^]waitfd,
	                      size: c.uint,
	                      fd_count: ^c.uint) -> Mcode ---
}