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

when ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .Darwin || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD || ODIN_OS == .Haiku || ODIN_OS == .JS  {
	@(default_calling_convention="c")
	foreign libc {
		// 7.27.2 Time manipulation functions
		clock        :: proc() -> clock_t ---
		@(link_name=LDIFFTIME)
		difftime     :: proc(time1, time2: time_t) -> double ---
		@(link_name=LMKTIME)
		mktime       :: proc(timeptr: ^tm) -> time_t ---
		@(link_name=LTIME)
		time         :: proc(timer: ^time_t) -> time_t ---
		timespec_get :: proc(ts: ^timespec, base: int) -> int ---

		// 7.27.3 Time conversion functions
		asctime      :: proc(timeptr: ^tm) -> [^]char ---
		@(link_name=LCTIME)
		ctime        :: proc(timer: ^time_t) -> [^]char ---
		@(link_name=LGMTIME)
		gmtime       :: proc(timer: ^time_t) -> ^tm ---
		@(link_name=LLOCALTIME)
		localtime    :: proc(timer: ^time_t) -> ^tm ---
		strftime     :: proc(s: [^]char, maxsize: size_t, format: cstring, timeptr: ^tm) -> size_t ---
	}

	when ODIN_OS == .NetBSD {
		@(private) LDIFFTIME  :: "__difftime50"
		@(private) LMKTIME    :: "__mktime50"
		@(private) LTIME      :: "__time50"
		@(private) LCTIME     :: "__ctime50"
		@(private) LGMTIME    :: "__gmtime50"
		@(private) LLOCALTIME :: "__localtime50"
	} else {
		@(private) LDIFFTIME  :: "difftime"
		@(private) LMKTIME    :: "mktime"
		@(private) LTIME      :: "time"
		@(private) LCTIME     :: "ctime"
		@(private) LGMTIME    :: "gmtime"
		@(private) LLOCALTIME :: "localtime"
	}

	when ODIN_OS == .OpenBSD {
		CLOCKS_PER_SEC :: 100
	} else {
		CLOCKS_PER_SEC :: 1000000
	}

	TIME_UTC :: 1

	time_t :: distinct i64

	when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .Haiku {
		clock_t :: distinct int32_t
	} else {
		clock_t :: distinct long
	}

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
