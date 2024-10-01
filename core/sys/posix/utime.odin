package posix

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// utime.h - access and modification time structure

foreign lib {
	/*
	Set file access and modification times.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/utime.html ]]
	*/
	@(link_name=LUTIME)
	utime :: proc(path: cstring, times: ^utimbuf) -> result ---
}

when ODIN_OS == .NetBSD {
	@(private) LUTIME :: "__utime50"
} else {
	@(private) LUTIME :: "utime"
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD	{

	utimbuf :: struct {
		actime:  time_t, /* [PSX] access time (seconds since epoch) */
		modtime: time_t, /* [PSX] modification time (seconds since epoch) */
	}

} else {
	#panic("posix is unimplemented for the current target")
}
