#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"
import "core:c/libc"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// time.h - time types

foreign lib {
	/*
	Convert the broken down time in the structure to a string form: Sun Sep 16 01:03:52 1973.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/asctime_r.html ]]
	*/
	asctime_r :: proc(tm: ^tm, buf: [^]c.char) -> cstring ---

	/*
	Convert a time value to a date and time string in the same format as asctime().

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ctime_r.html ]]
	*/
	@(link_name=LCTIMER)
	ctime_r :: proc(clock: ^time_t, buf: [^]c.char) -> cstring ---

	/*
	Converts the time in seconds since epoch to a broken-down tm struct.

	Returns: nil (setting errno) on failure, the result pointer on success.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/gmtime_r.html ]]
	*/
	@(link_name=LGMTIMER)
	gmtime_r :: proc(timer: ^time_t, result: ^tm) -> ^tm ---

	/*
	Convert the time in seconds since epoch to a broken-down tm struct in local time.

	Returns: nil (setting errno) on failure, the result pointer on success.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/localtime_r.html ]]
	*/
	@(link_name=LLOCALTIMER)
	localtime_r :: proc(timer: ^time_t, result: ^tm) -> ^tm ---

	/*
	Returns the resolution of any clock.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/clock_getres.html ]]
	*/
	@(link_name=LCLOCKGETRES)
	clock_getres :: proc(clock_id: Clock, res: ^timespec) -> result ---

	/*
	Returns the current value tp for the specified clock, clock_id.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/clock_getres.html ]]
	*/
	@(link_name=LCLOCKGETTIME)
	clock_gettime :: proc(clock_id: Clock, tp: ^timespec) -> result ---

	/*
	Sets the specified clock's time.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/clock_getres.html ]]
	*/
	@(link_name=LCLOCKSETTIME)
	clock_settime :: proc(clock_id: Clock, tp: ^timespec) -> result ---

	/*
	Converts a string representation of a date or time into a broken-down time.

	Returns: nil (setting getdate_err) on failure, the broken-down time otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getdate.html ]]
	*/
	getdate :: proc(string: cstring) -> ^tm ---

	/*
	Causes the current thread to be suspended from execution until either the time interval
	specified by rqtp has elapsed or a signal is delivered.

	Returns: -1 on failure (setting errno), if it was due to a signal, rmtp will be filled with the
	remaining time, 0 if all time has been slept

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/nanosleep.html ]]
	*/
	@(link_name=LNANOSLEEP)
	nanosleep :: proc(rqtp: ^timespec, rmtp: ^timespec) -> result ---

	/*
	Converts the character string to values which are stored in tm, using the specified format.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/strptime.html ]]
	*/
	strptime :: proc(buf: [^]c.char, format: cstring, tm: ^tm) -> cstring ---

	/*
	Uses the value of the environment variable TZ (or default) to set time conversion info.

	`daylight` is set to whether daylight saving time conversion should be done.
	`timezone` is set to the difference, in seconds, between UTC and local standard time.
	`tzname` is set by `tzname[0] = "std"` and `tzname[1] = "dst"`

	Example:
		posix.tzset()
		fmt.println(posix.tzname)
		fmt.println(posix.daylight)
		fmt.println(posix.timezone)

	Possible Output:
		["CET", "CEST"]
		true
		-3600

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tzset.html ]]
	*/
	tzset :: proc() ---

	// Whether daylight saving conversion should be done.
	daylight: b32
	// The time in seconds between UTC and local standard time.
	@(link_name=LTIMEZONE)
	timezone: c.long
	tzname:   [2]cstring
}

time_t  :: libc.time_t
clock_t :: libc.clock_t

tm       :: libc.tm
timespec :: libc.timespec

CLOCKS_PER_SEC :: libc.CLOCKS_PER_SEC

asctime   :: libc.asctime
clock     :: libc.clock
ctime     :: libc.ctime
difftime  :: libc.difftime
gmtime    :: libc.gmtime
localtime :: libc.localtime
mktime    :: libc.mktime
strftime  :: libc.strftime
time      :: libc.time

Clock :: enum clockid_t {
	// system-wide monotonic clock, defined as clock measuring real time,
	// can be set with clock_settime() and cannot have negative clock jumps.
	MONOTONIC          = CLOCK_MONOTONIC,
	// CPU-time clock associated with the process making a clock() function call.
	PROCESS_CPUTIME_ID = CLOCK_PROCESS_CPUTIME_ID,
	// system-wide clock measuring real time.
	REALTIME           = CLOCK_REALTIME,
	// CPU-time clock associated with the thread making a clock() function call.
	THREAD_CPUTIME_ID  = CLOCK_THREAD_CPUTIME_ID,
}

when ODIN_OS == .NetBSD {
	@(private) LCTIMER       :: "__ctime_r50"
	@(private) LGMTIMER      :: "__gmtime_r50"
	@(private) LLOCALTIMER   :: "__localtime_r50"
	@(private) LCLOCKGETRES  :: "__clock_getres50"
	@(private) LCLOCKGETTIME :: "__clock_gettime50"
	@(private) LCLOCKSETTIME :: "__clock_settime50"
	@(private) LNANOSLEEP    :: "__nanosleep50"
	@(private) LTIMEZONE     :: "__timezone13"
} else {
	@(private) LCTIMER       :: "ctime_r"
	@(private) LGMTIMER      :: "gmtime_r"
	@(private) LLOCALTIMER   :: "localtime_r"
	@(private) LCLOCKGETRES  :: "clock_getres"
	@(private) LCLOCKGETTIME :: "clock_gettime"
	@(private) LCLOCKSETTIME :: "clock_settime"
	@(private) LNANOSLEEP    :: "nanosleep"
	@(private) LTIMEZONE     :: "timezone"
}

when ODIN_OS == .Darwin {

	clockid_t :: distinct c.int

	CLOCK_MONOTONIC          :: 6
	CLOCK_PROCESS_CPUTIME_ID :: 12
	CLOCK_REALTIME           :: 0
	CLOCK_THREAD_CPUTIME_ID  :: 16

	foreign lib {
		getdate_err: Errno
	}

} else when ODIN_OS == .FreeBSD {

	clockid_t :: distinct c.int

	CLOCK_MONOTONIC          :: 4
	CLOCK_PROCESS_CPUTIME_ID :: 15
	CLOCK_REALTIME           :: 0
	CLOCK_THREAD_CPUTIME_ID  :: 14

	foreign lib {
		getdate_err: Errno
	}

} else when ODIN_OS == .NetBSD {

	clockid_t :: distinct c.uint

	CLOCK_MONOTONIC          :: 3
	CLOCK_PROCESS_CPUTIME_ID :: 0x40000000
	CLOCK_REALTIME           :: 0
	CLOCK_THREAD_CPUTIME_ID  :: 0x20000000

	foreign lib {
		getdate_err: Errno
	}

} else when ODIN_OS == .OpenBSD {

	clockid_t :: distinct c.uint

	CLOCK_MONOTONIC          :: 3
	CLOCK_PROCESS_CPUTIME_ID :: 2
	CLOCK_REALTIME           :: 0
	CLOCK_THREAD_CPUTIME_ID  :: 4

	getdate_err: Errno = .ENOSYS // NOTE: looks like it's not a thing on OpenBSD.

} else when ODIN_OS == .Linux {

	clockid_t :: distinct c.int

	CLOCK_MONOTONIC          :: 1
	CLOCK_PROCESS_CPUTIME_ID :: 2
	CLOCK_REALTIME           :: 0
	CLOCK_THREAD_CPUTIME_ID  :: 3

	foreign lib {
		getdate_err: Errno
	}
}
