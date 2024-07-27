package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// arpa/inet.h - definitions for internet operations

foreign lib {
	// Use Odin's native big endian types `u32be` and `u16be` instead.
	// htonl :: proc(c.uint32_t) -> c.uint32_t ---
	// htons :: proc(c.uint16_t) -> c.uint16_t ---
	// ntohl :: proc(c.uint32_t) -> c.uint32_t ---
	// ntohs :: proc(c.uint16_t) -> c.uint16_t ---

	// Use of this function is problematic because -1 is a valid address (255.255.255.255).
	// Avoid its use in favor of inet_aton(), inet_pton(3), or getaddrinfo(3) which provide a cleaner way to indicate error return.
	// inet_addr :: proc(cstring) -> in_addr_t ---

	// Convert the Internet host address specified by in to a string in the Internet standard dot notation.
	//
	// NOTE: returns a static string overwritten by further calls.
	//
	// [[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/inet_ntoa.html ]]
	inet_ntoa :: proc(in_addr) -> cstring ---

	// Convert a numeric address into a text string suitable for presentation.
	//
	// Returns `nil` and sets `errno` on failure.
	//
	// [[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/inet_ntop.html ]]
	inet_ntop :: proc(
		af:   AF,        // INET or INET6
		src:  rawptr,    // either ^in_addr or ^in_addr6 
		dst:  [^]byte,   // use `INET_ADDRSTRLEN` or `INET6_ADDRSTRLEN` for minimum lengths
		size: socklen_t,
	) -> cstring ---

	// Convert an address in its standard text presentation form into its numeric binary form.
	//
	// [[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/inet_ntop.html ]]
	inet_pton :: proc(
		af:   AF,        // INET or INET6
		src:  cstring,
		dst:  rawptr,    // either ^in_addr or ^in_addr6
		size: socklen_t, // size_of(dst^)
	) -> pton_result ---
}

pton_result :: enum c.int {
	AFNOSUPPORT = -1,
	INVALID     = 0,
	SUCCESS     = 1,
}
