package vendor_curl

import c "core:c/libc"


ws_frame :: struct {
	age:       c.int,    /* zero */
	flags:     ws_flags, /* See the CURLWS_* defines */
	offset:    off_t,    /* the offset of this data into the frame */
	bytesleft: off_t,    /* number of pending bytes left of the payload */
	len:       c.size_t, /* size of the current data chunk */
}

ws_flags :: distinct bit_set[ws_flag; c.uint]
ws_flag :: enum c.uint {
	/* flag bits */
	TEXT   = 0,
	BINARY = 1,
	CONT   = 2,
	CLOSE  = 3,
	PING   = 4,
	OFFSET = 5,

	/* flags for curl_ws_send() */
	PONG   = 6,
}

WS_TEXT   :: ws_flags{.TEXT}
WS_BINARY :: ws_flags{.BINARY}
WS_CONT   :: ws_flags{.CONT}
WS_CLOSE  :: ws_flags{.CLOSE}
WS_PING   :: ws_flags{.PING}
WS_OFFSET :: ws_flags{.OFFSET}
WS_PONG   :: ws_flags{.PONG}

/* bits for the CURLOPT_WS_OPTIONS bitmask: */
WS_RAW_MODE   :: 1<<0
WS_NOAUTOPONG :: 1<<1

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	/*
	 * NAME curl_ws_recv()
	 *
	 * DESCRIPTION
	 *
	 * Receives data from the websocket connection. Use after successful
	 * curl_easy_perform() with CURLOPT_CONNECT_ONLY option.
	 */
	ws_recv :: proc(curl: ^CURL, buffer: rawptr, buflen: c.size_t, recv: ^c.size_t, metap: ^^ws_frame) -> code ---



	/*
	 * NAME curl_ws_send()
	 *
	 * DESCRIPTION
	 *
	 * Sends data over the websocket connection. Use after successful
	 * curl_easy_perform() with CURLOPT_CONNECT_ONLY option.
	 */
	ws_send :: proc(curl: ^CURL, buffer: rawptr,
	                buflen: c.size_t, sent: ^c.size_t,
	                fragsize: off_t,
	                flags: ws_flags) -> code ---


	/*
	 * NAME curl_ws_start_frame()
	 *
	 * DESCRIPTION
	 *
	 * Buffers a websocket frame header with the given flags and length.
	 * Errors when a previous frame is not complete, e.g. not all its
	 * payload has been added.
	 */
	ws_start_frame :: proc(curl: ^CURL,
	                       flags: c.uint,
	                       frame_len: off_t) -> code ---

	ws_meta :: proc(curl: ^CURL) -> ^ws_frame ---
}