package vendor_curl

import c "core:c/libc"

/* Flag bits in the curl_blob struct: */
BLOB_COPY   :: blob_flags{.COPY} /* tell libcurl to copy the data */
BLOB_NOCOPY :: blob_flags{}      /* tell libcurl to NOT copy the data */

blob_flags :: distinct bit_set[blob_flag; c.uint]
blob_flag :: enum c.uint {
	COPY = 0,
}

blob :: struct {
	data:  rawptr,
	len:   c.size_t,
	flags: blob_flags, /* bit 0 is defined, the rest are reserved and should be
	                      left zeroes */
}

@(default_calling_convention="c", link_prefix="curl_")
foreign lib {
	easy_init    :: proc() -> ^CURL ---
	easy_setopt  :: proc(curl: ^CURL, option: option, #c_vararg args: ..any) -> code ---
	easy_perform :: proc(curl: ^CURL) -> code ---
	easy_cleanup :: proc(curl: ^CURL) ---


	/*
	 * NAME curl_easy_getinfo()
	 *
	 * DESCRIPTION
	 *
	 * Request internal information from the curl session with this function.
	 * The third argument MUST be pointing to the specific type of the used option
	 * which is documented in each manpage of the option. The data pointed to
	 * will be filled in accordingly and can be relied upon only if the function
	 * returns CURLE_OK. This function is intended to get used *AFTER* a performed
	 * transfer, all results from this function are undefined until the transfer
	 * is completed.
	 */
	easy_getinfo :: proc(curl: ^CURL, info: INFO, #c_vararg args: ..any) -> code ---


	/*
	 * NAME curl_easy_duphandle()
	 *
	 * DESCRIPTION
	 *
	 * Creates a new curl session handle with the same options set for the handle
	 * passed in. Duplicating a handle could only be a matter of cloning data and
	 * options, internal state info and things like persistent connections cannot
	 * be transferred. It is useful in multithreaded applications when you can run
	 * curl_easy_duphandle() for each new thread to avoid a series of identical
	 * curl_easy_setopt() invokes in every thread.
	 */
	easy_duphandle :: proc(curl: ^CURL) -> ^CURL ---

	/*
	 * NAME curl_easy_reset()
	 *
	 * DESCRIPTION
	 *
	 * Re-initializes a curl handle to the default values. This puts back the
	 * handle to the same state as it was in when it was just created.
	 *
	 * It does keep: live connections, the Session ID cache, the DNS cache and the
	 * cookies.
	 */
	easy_reset :: proc(curl: ^CURL) ---

	/*
	 * NAME curl_easy_recv()
	 *
	 * DESCRIPTION
	 *
	 * Receives data from the connected socket. Use after successful
	 * curl_easy_perform() with CURLOPT_CONNECT_ONLY option.
	 */
	easy_recv :: proc(curl: ^CURL, buffer: rawptr, buflen: c.size_t, n: ^c.size_t) -> code ---

	/*
	 * NAME curl_easy_send()
	 *
	 * DESCRIPTION
	 *
	 * Sends data over the connected socket. Use after successful
	 * curl_easy_perform() with CURLOPT_CONNECT_ONLY option.
	 */
	easy_send :: proc(curl: ^CURL, buffer: rawptr, buflen: c.size_t, n: ^c.size_t) -> code ---


	/*
	 * NAME curl_easy_upkeep()
	 *
	 * DESCRIPTION
	 *
	 * Performs connection upkeep for the given session handle.
	 */
	easy_upkeep :: proc(curl: ^CURL) -> code ---
}