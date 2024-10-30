#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// pwd.h - password structure

foreign lib {
	/*
	Rewinds the user database so that the next getpwent() returns the first entry.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setpwent.html ]]
	*/
	setpwent :: proc() ---

	/*
	Returns the current entry in the user database.

	Returns: nil (setting errno) on error, nil (not setting errno) on success.

	Example:
		posix.setpwent()
		defer posix.endpwent()
		for e := posix.getpwent(); e != nil; e = posix.getpwent() {
			fmt.println(e)
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setpwent.html ]]
	*/
	@(link_name=LGETPWENT)
	getpwent :: proc() -> ^passwd ---

	/*
	Closes the user database.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setpwent.html ]]
	*/
	endpwent :: proc() ---

	/*
	Searches the database for an entry with a matching name.

	Returns: nil (setting errno) on error, nil (not setting errno) on success.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpwnam.html ]]
	*/
	@(link_name=LGETPWNAM)
	getpwnam :: proc(name: cstring) -> ^passwd ---

	/*
	Searches the database for an entry with a matching name.
	Populating the pwd fields and using the buffer to allocate strings into.
	Setting result to nil on failure and to the address of pwd otherwise.

	ERANGE will be returned if there is not enough space in buffer.
	sysconf(_SC_GETPW_R_SIZE_MAX) can be called for the suggested size of this buffer, note that it could return -1.

	Example:
		length := posix.sysconf(._GETPW_R_SIZE_MAX)
		length  = length == -1 ? 1024 : length

		buffer: [dynamic]byte
		defer delete(buffer)

		result:  posix.passwd
		resultp: ^posix.passwd
		errno:   posix.Errno
		for {
			if err := resize(&buffer, length); err != nil {
				fmt.panicf("allocation failure: %v", err)
			}

			errno = posix.getpwnam_r("root", &result, raw_data(buffer), len(buffer), &resultp)
			if errno != .ERANGE {
				break
			}
		}

		if errno != .NONE {
			panic(string(posix.strerror(errno)))
		}

		fmt.println(result)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpwnam.html ]]
	*/
	@(link_name=LGETPWNAMR)
	getpwnam_r :: proc(name: cstring, pwd: ^passwd, buffer: [^]byte, bufsize: c.size_t, result: ^^passwd) -> Errno ---

	/*
	Searches the database for an entry with a matching uid.

	Returns: nil (setting errno) on error, nil (not setting errno) on success.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpwuid.html ]]
	*/
	@(link_name=LGETPWUID)
	getpwuid :: proc(uid: uid_t) -> ^passwd ---

	/*
	Searches the database for an entry with a matching uid.
	Populating the pwd fields and using the buffer to allocate strings into.
	Setting result to nil on failure and to the address of pwd otherwise.

	ERANGE will be returned if there is not enough space in buffer.
	sysconf(_SC_GETPW_R_SIZE_MAX) can be called for the suggested size of this buffer, note that it could return -1.

	See the example for getpwnam_r.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpwuid_r.html ]]
	*/
	@(link_name=LGETPWUIDR)
	getpwuid_r :: proc(uid: uid_t, pwd: ^passwd, buffer: [^]byte, bufsize: c.size_t, result: ^^passwd) -> Errno ---
}

when ODIN_OS == .NetBSD {
	@(private) LGETPWENT  :: "__getpwent50"
	@(private) LGETPWNAM  :: "__getpwnam50"
	@(private) LGETPWNAMR :: "__getpwnam_r50"
	@(private) LGETPWUID  :: "__getpwuid50"
	@(private) LGETPWUIDR :: "__getpwuid_r50"
} else {
	@(private) LGETPWENT  :: "getpwent"
	@(private) LGETPWNAM  :: "getpwnam"
	@(private) LGETPWNAMR :: "getpwnam_r"
	@(private) LGETPWUID  :: "getpwuid"
	@(private) LGETPWUIDR :: "getpwuid_r"
}

when ODIN_OS == .Darwin || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	passwd :: struct {
		pw_name:   cstring, /* [PSX] user name */
		pw_passwd: cstring, /* encrypted password */
		pw_uid:    uid_t,   /* [PSX] user uid */
		pw_gid:    gid_t,   /* [PSX] user gid */
		pw_change: time_t,  /* password change time */
		pw_class:  cstring, /* user access class */
		pw_gecos:  cstring, /* Honeywell login info */
		pw_dir:    cstring, /* [PSX] home directory */
		pw_shell:  cstring, /* [PSX] default shell */
		pw_expire: time_t,  /* account expiration */
	}

} else when ODIN_OS == .FreeBSD {

	passwd :: struct {
		pw_name:   cstring, /* [PSX] user name */
		pw_passwd: cstring, /* encrypted password */
		pw_uid:    uid_t,   /* [PSX] user uid */
		pw_gid:    gid_t,   /* [PSX] user gid */
		pw_change: time_t,  /* password change time */
		pw_class:  cstring, /* user access class */
		pw_gecos:  cstring, /* Honeywell login info */
		pw_dir:    cstring, /* [PSX] home directory */
		pw_shell:  cstring, /* [PSX] default shell */
		pw_expire: time_t,  /* account expiration */
		pw_fields: c.int,
	}

} else when ODIN_OS == .Linux {

	passwd :: struct {
		pw_name:   cstring, /* [PSX] user name */
		pw_passwd: cstring, /* encrypted password */
		pw_uid:    uid_t,   /* [PSX] user uid */
		pw_gid:    gid_t,   /* [PSX] user gid */
		pw_gecos:  cstring, /* Real name.  */
		pw_dir:    cstring, /* Home directory.  */
		pw_shell:  cstring, /* Shell program.  */
	}

}
