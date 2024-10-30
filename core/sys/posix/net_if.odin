#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// net/if.h - sockets local interfaces

foreign lib {
	/*
	Retrieve an array of name indexes. Where the last one has an index of 0 and name of nil.

	Returns: nil (setting errno) on failure, an array that should be freed with if_freenameindex otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/if_nameindex.html ]]
	*/
	if_nameindex :: proc() -> [^]if_nameindex_t ---

	/*
	Returns the interface index matching the name or zero.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/if_nametoindex.html ]]
	*/
	if_nametoindex :: proc(name: cstring) -> c.uint ---

	/*
	Returns the name corresponding to the index.

	ifname should be at least IF_NAMESIZE bytes in size.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/if_indextoname.html ]]
	*/
	if_indextoname :: proc(ifindex: c.uint, ifname: [^]byte) -> cstring ---

	/*
	Frees memory allocated by if_nameindex.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/if_freenameindex.html ]]
	*/
	if_freenameindex :: proc(ptr: ^if_nameindex_t) ---
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	// NOTE: `_t` suffix added due to name conflict.

	if_nameindex_t :: struct {
		if_index: c.uint,  /* [PSX] 1, 2, ... */
		if_name:  cstring, /* [PSX] null terminated name: "le0", ... */
	}

	IF_NAMESIZE :: 16

}
