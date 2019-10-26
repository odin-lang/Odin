//+build linux, darwin
package time

IS_SUPPORTED :: true; // NOTE: Times on Darwin are UTC.

foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	@(link_name="clock_gettime") _unix_clock_gettime :: proc(clock_id: u64, timespec: ^TimeSpec) -> i32 ---;
	@(link_name="sleep")         _unix_sleep         :: proc(seconds: u32) -> i32 ---;
	@(link_name="nanosleep")     _unix_nanosleep     :: proc(requested: ^TimeSpec, remaining: ^TimeSpec) -> i32 ---;
}

TimeSpec :: struct {
	tv_sec  : i64,  /* seconds */
	tv_nsec : i64,  /* nanoseconds */
};

CLOCK_REALTIME           :: 0; // NOTE(tetra): May jump in time, when user changes the system time.
CLOCK_MONOTONIC          :: 1; // NOTE(tetra): May stand still while system is asleep.
CLOCK_PROCESS_CPUTIME_ID :: 2;
CLOCK_THREAD_CPUTIME_ID  :: 3;
CLOCK_MONOTONIC_RAW      :: 4; // NOTE(tetra): "RAW" means: Not adjusted by NTP.
CLOCK_REALTIME_COARSE    :: 5; // NOTE(tetra): "COARSE" clocks are apparently much faster, but not "fine-grained."
CLOCK_MONOTONIC_COARSE   :: 6;
CLOCK_BOOTTIME           :: 7; // NOTE(tetra): Same as MONOTONIC, except also including time system was asleep.
CLOCK_REALTIME_ALARM     :: 8;
CLOCK_BOOTTIME_ALARM     :: 9;

// TODO(tetra, 2019-11-05): The original implementation of this package for Darwin used this constants.
// I do not know if Darwin programmers are used to the existance of these constants or not, so
// I'm leaving aliases to them for now.
CLOCK_SYSTEM   :: CLOCK_REALTIME;
CLOCK_CALENDAR :: CLOCK_MONOTONIC;


clock_gettime :: proc(clock_id: u64) -> TimeSpec {
	ts : TimeSpec; // NOTE(tetra): Do we need to initialize this?
	_unix_clock_gettime(clock_id, &ts);
	return ts;
}

now :: proc() -> Time {
	time_spec_now := clock_gettime(CLOCK_REALTIME);
	ns := time_spec_now.tv_sec * 1e9 + time_spec_now.tv_nsec;
	return Time{_nsec=ns};
}

boot_time :: proc() -> Time {
	ts_now := clock_gettime(CLOCK_REALTIME);
	ts_boottime := clock_gettime(CLOCK_BOOTTIME);

	ns := (ts_now.tv_sec - ts_boottime.tv_sec) * 1e9 + ts_now.tv_nsec - ts_boottime.tv_nsec;
	return Time{_nsec=ns};
}

seconds_since_boot :: proc() -> f64 {
	ts_boottime := clock_gettime(CLOCK_BOOTTIME);
	return f64(ts_boottime.tv_sec) + f64(ts_boottime.tv_nsec) / 1e9;
}


sleep :: proc(d: Duration) {
	ds := duration_seconds(d);
	seconds := u32(ds);
	nanoseconds := i64((ds - f64(seconds)) * 1e9);

	if seconds > 0 do _unix_sleep(seconds);
	if nanoseconds > 0 do nanosleep(nanoseconds);
}

nanosleep :: proc(nanoseconds: i64) -> int {
	// NOTE(tetra): Should we remove this assert? We are measuring nanoseconds after all...
	assert(nanoseconds <= 999999999);

	requested := TimeSpec{tv_nsec = nanoseconds};
	remaining: TimeSpec; // NOTE(tetra): Do we need to initialize this?
	return int(_unix_nanosleep(&requested, &remaining));
}