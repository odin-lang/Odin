#+build linux, darwin, netbsd, openbsd, freebsd
package posix

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/times.h - file access and modification times structure

foreign lib {
	/*
	Get time accounting information.

	Returns: -1 (setting errno) on failure, the elapsed real time, since an arbitrary point in the past
	*/
	@(link_name=LTIMES)
	times :: proc(buffer: ^tms) -> clock_t ---
}

when ODIN_OS == .NetBSD {
	@(private) LTIMES :: "__times13"
} else {
	@(private) LTIMES :: "times"
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD || ODIN_OS == .Linux {

	tms :: struct {
		tms_utime:  clock_t, /* [PSX] user CPU time */
		tms_stime:  clock_t, /* [PSX] system CPU time */
		tms_cutime: clock_t, /* [PSX] terminated children user CPU time */
		tms_cstime: clock_t, /* [PSX] terminated children system CPU time */
	}

}
