package libc

// 7.27 Date and time

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

// We enforce 64-bit time_t and timespec as there is no reason to use 32-bit as
// we approach the 2038 problem. Windows has defaulted to this since VC8 (2005).
when ODIN_OS == .Windows {
	foreign libc {
		// 7.27.2 Time manipulation functions
		                               clock        :: proc() -> clock_t ---
		@(link_name="_difftime64")     difftime     :: proc(time1, time2: time_t) -> double ---
		                               mktime       :: proc(timeptr: ^tm) -> time_t ---
		@(link_name="_time64")         time         :: proc(timer: ^time_t) -> time_t ---
		@(link_name="_timespec64_get") timespec_get :: proc(ts: ^timespec, base: int) -> int ---

		// 7.27.3 Time conversion functions
		                               asctime      :: proc(timeptr: ^tm) -> [^]char ---
		@(link_name="_ctime64")        ctime        :: proc(timer: ^time_t) -> [^]char ---
		@(link_name="_gmtime64")       gmtime       :: proc(timer: ^time_t) -> ^tm ---
		@(link_name="_localtime64")    localtime    :: proc(timer: ^time_t) -> ^tm ---
		                               strftime     :: proc(s: [^]char, maxsize: size_t, format: cstring, timeptr: ^tm) -> size_t ---
	}

	CLOCKS_PER_SEC :: 1000
	TIME_UTC       :: 1

	clock_t        :: distinct long
	time_t         :: distinct i64

	timespec :: struct #align(8) {
		tv_sec:  time_t,
		tv_nsec: long,
	}

	tm :: struct #align(8) {
		tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year, tm_wday, tm_yday, tm_isdst: int,
	}
}

when ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .Darwin || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD || ODIN_OS == .Haiku {
	@(default_calling_convention="c")
	foreign libc {
		// 7.27.2 Time manipulation functions
		clock        :: proc() -> clock_t ---
		difftime     :: proc(time1, time2: time_t) -> double ---
		mktime       :: proc(timeptr: ^tm) -> time_t ---
		time         :: proc(timer: ^time_t) -> time_t ---
		timespec_get :: proc(ts: ^timespec, base: int) -> int ---

		// 7.27.3 Time conversion functions
		asctime      :: proc(timeptr: ^tm) -> [^]char ---
		ctime        :: proc(timer: ^time_t) -> [^]char ---
		gmtime       :: proc(timer: ^time_t) -> ^tm ---
		localtime    :: proc(timer: ^time_t) -> ^tm ---
		strftime     :: proc(s: [^]char, maxsize: size_t, format: cstring, timeptr: ^tm) -> size_t ---
	}

	when ODIN_OS == .OpenBSD {
		CLOCKS_PER_SEC :: 100
	} else {
		CLOCKS_PER_SEC :: 1000000
	}

	TIME_UTC       :: 1

	time_t         :: distinct i64

	clock_t        :: long

	timespec :: struct {
		tv_sec:  time_t,
		tv_nsec: long,
	}

	tm :: struct {
		tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year, tm_wday, tm_yday, tm_isdst: int,
		tm_gmtoff: long,
		tm_zone: rawptr,
	}
}
