//+build linux, darwin, freebsd, openbsd, netbsd, haiku
package unix

when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else  {
	foreign import libc "system:c"
}

import "core:c"

when ODIN_OS == .NetBSD {
	@(default_calling_convention="c")
		foreign libc {
			@(link_name="__clock_gettime50") clock_gettime :: proc(clock_id: u64, timespec: ^timespec) -> c.int ---
			@(link_name="__nanosleep50")     nanosleep     :: proc(requested, remaining: ^timespec) -> c.int ---
			@(link_name="sleep")             sleep         :: proc(seconds: c.uint) -> c.int ---
	}
} else {
	@(default_calling_convention="c")
	foreign libc {
		clock_gettime :: proc(clock_id: u64, timespec: ^timespec) -> c.int ---
		sleep         :: proc(seconds: c.uint) -> c.int ---
		nanosleep     :: proc(requested, remaining: ^timespec) -> c.int ---
	}
}

timespec :: struct {
	tv_sec:  i64, // seconds
	tv_nsec: i64, // nanoseconds
}

when ODIN_OS == .OpenBSD {
	CLOCK_REALTIME           :: 0
	CLOCK_PROCESS_CPUTIME_ID :: 2
	CLOCK_MONOTONIC          :: 3
	CLOCK_THREAD_CPUTIME_ID  :: 4
	CLOCK_UPTIME             :: 5
	CLOCK_BOOTTIME           :: 6

	// CLOCK_MONOTONIC_RAW doesn't exist, use CLOCK_MONOTONIC
	CLOCK_MONOTONIC_RAW :: CLOCK_MONOTONIC
} else {
	CLOCK_REALTIME           :: 0 // NOTE(tetra): May jump in time, when user changes the system time.
	CLOCK_MONOTONIC          :: 1 // NOTE(tetra): May stand still while system is asleep.
	CLOCK_PROCESS_CPUTIME_ID :: 2
	CLOCK_THREAD_CPUTIME_ID  :: 3
	CLOCK_MONOTONIC_RAW      :: 4 // NOTE(tetra): "RAW" means: Not adjusted by NTP.
	CLOCK_REALTIME_COARSE    :: 5 // NOTE(tetra): "COARSE" clocks are apparently much faster, but not "fine-grained."
	CLOCK_MONOTONIC_COARSE   :: 6
	CLOCK_BOOTTIME           :: 7 // NOTE(tetra): Same as MONOTONIC, except also including time system was asleep.
	CLOCK_REALTIME_ALARM     :: 8
	CLOCK_BOOTTIME_ALARM     :: 9
}

// TODO(tetra, 2019-11-05): The original implementation of this package for Darwin used this constants.
// I do not know if Darwin programmers are used to the existance of these constants or not, so
// I'm leaving aliases to them for now.
CLOCK_SYSTEM   :: CLOCK_REALTIME
CLOCK_CALENDAR :: CLOCK_MONOTONIC

boot_time_in_nanoseconds :: proc "c" () -> i64 {
	ts_now, ts_boottime: timespec
	clock_gettime(CLOCK_REALTIME, &ts_now)
	clock_gettime(CLOCK_BOOTTIME, &ts_boottime)

	ns := (ts_now.tv_sec - ts_boottime.tv_sec) * 1e9 + ts_now.tv_nsec - ts_boottime.tv_nsec
	return i64(ns)
}

seconds_since_boot :: proc "c" () -> f64 {
	ts_boottime: timespec
	clock_gettime(CLOCK_BOOTTIME, &ts_boottime)
	return f64(ts_boottime.tv_sec) + f64(ts_boottime.tv_nsec) / 1e9
}

inline_nanosleep :: proc "c" (nanoseconds: i64) -> (remaining: timespec, res: i32) {
	s, ns := nanoseconds / 1e9, nanoseconds % 1e9
	requested := timespec{tv_sec=s, tv_nsec=ns}
	res = nanosleep(&requested, &remaining)
	return
}

