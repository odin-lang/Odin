package vendor_curl

import c "core:c/libc"


ws_frame :: struct {
	age:       c.int,    /* zero */
	flags:     c.int,    /* See the CURLWS_* defines */
	offset:    off_t,    /* the offset of this data into the frame */
	bytesleft: off_t,    /* number of pending bytes left of the payload */
	len:       c.size_t, /* size of the current data chunk */
}

/* flag bits */
WS_TEXT   :: 1<<0
WS_BINARY :: 1<<1
WS_CONT   :: 1<<2
WS_CLOSE  :: 1<<3
WS_PING   :: 1<<4
WS_OFFSET :: 1<<5

/* flags for curl_ws_send() */
WS_PONG       :: 1<<6

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
	ws_send :: proc(curl: CURL, buffer: rawptr,
	                buflen: c.size_t, sent: ^c.size_t,
	                fragsize: off_t,
	                flags: c.uint) -> code ---


	ws_meta :: proc(curl: ^CURL) -> ^ws_frame ---
}