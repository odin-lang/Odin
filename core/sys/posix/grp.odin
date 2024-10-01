package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// grp.h - group structure

foreign lib {
	/*
	Closes the group database.

	Checking status would be done by setting errno to 0, calling this, and checking errno.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/endgrent.html ]]
	*/
	endgrent :: proc() ---

	/*
	Rewinds the group database so getgrent() returns the first entry again.

	Checking status would be done by setting errno to 0, calling this, and checking errno.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/endgrent.html ]]
	*/
	setgrent :: proc() ---

	/*
	Returns a pointer to an entry of the group database.

	Opens the group database if it isn't.

	Returns: nil on failure (setting errno) or EOF (not setting errno), the entry otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/endgrent.html ]]
	*/
	getgrent :: proc() -> ^group ---

	/*
	Searches for an entry with a matching gid in the group database.

	Returns: nil (setting errno) on failure, a pointer to the entry on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getgrgid.html ]]
	*/
	getgrgid :: proc(gid: gid_t) -> ^group ---

	/*
	Searches for an entry with a matching gid in the group database.

	Updates grp with the matching entry and stores it (or a nil pointer (setting errno)) into result.

	Strings are allocated into the given buffer, you can call `sysconf(._GETGR_R_SIZE_MAX)` for an appropriate size.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getgrgid.html ]]
	*/
	getgrgid_r :: proc(gid: gid_t, grp: ^group, buffer: [^]byte, bufsize: c.size_t, result: ^^group) -> Errno ---

	/*
	Searches for an entry with a matching gid in the group database.

	Returns: nil (setting errno) on failure, a pointer to the entry on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getgrnam.html ]]
	*/
	getgrnam :: proc(name: cstring) -> ^group ---

	/*
	Searches for an entry with a matching gid in the group database.

	Updates grp with the matching entry and stores it (or a nil pointer (setting errno)) into result.

	Strings are allocated into the given buffer, you can call `sysconf(._GETGR_R_SIZE_MAX)` for an appropriate size.

	Example:
		length := posix.sysconf(._GETGR_R_SIZE_MAX)
		if length == -1 {
			length = 1024
		}

		result:  posix.group
		resultp: ^posix.group

		e: posix.Errno

		buffer: [dynamic]byte
		defer delete(buffer)

		for {
			mem_err := resize(&buffer, length)
			assert(mem_err == nil)

			e = posix.getgrnam_r("nobody", &result, raw_data(buffer), len(buffer), &resultp)
			if e != .ERANGE {
				break
			}

			length *= 2
			assert(length > 0)
		}

		if e != .NONE {
			panic(string(posix.strerror(e)))
		}

		fmt.println(result)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getgrnam.html ]]
	*/
	getgrnam_r :: proc(name: cstring, grp: ^group, buffer: [^]byte, bufsize: c.size_t, result: ^^group) -> Errno ---
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	gid_t :: distinct c.uint32_t

	group :: struct {
		gr_name:   cstring,    /* [PSX] group name */
		gr_passwd: cstring,    /* group password */
		gr_gid:    gid_t,      /* [PSX] group id */
		gr_mem:    [^]cstring, /* [PSX] group members */
	}

} else {
	#panic("posix is unimplemented for the current target")
}
