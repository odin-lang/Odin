package time

TimeSpec :: struct {
    tv_sec  : i64,  /* seconds */
    tv_nsec : i64,  /* nanoseconds */
};

CLOCK_SYSTEM          :: 0;
CLOCK_CALENDAR        :: 1;

IS_SUPPORTED :: true;

foreign libc {
    @(link_name="clock_gettime")    _clock_gettime :: proc(clock_id: u64, timespec: ^TimeSpec) ---;
    @(link_name="nanosleep")        _nanosleep     :: proc(requested: ^TimeSpec, remaining: ^TimeSpec) -> int ---;
    @(link_name="sleep")            _sleep         :: proc(seconds: u64) -> int ---;
}

clock_gettime :: proc(clock_id: u64) -> TimeSpec {
    ts : TimeSpec;
    _clock_gettime(clock_id, &ts);
    return ts;
}

now :: proc() -> Time {

    time_spec_now := clock_gettime(CLOCK_SYSTEM);
    ns := time_spec_now.tv_sec * 1e9 + time_spec_now.tv_nsec;
    return Time{_nsec=ns};
}

seconds_since_boot :: proc() -> f64 {

    ts_boottime := clock_gettime(CLOCK_SYSTEM);
    return f64(ts_boottime.tv_sec) + f64(ts_boottime.tv_nsec) / 1e9;
}

sleep :: proc(d: Duration) {

    ds := duration_seconds(d);
    seconds := u64(ds);
    nanoseconds := i64((ds - f64(seconds)) * 1e9);

    if seconds > 0 do _sleep(seconds);
    if nanoseconds > 0 do nanosleep(nanoseconds);
}

nanosleep :: proc(nanoseconds: i64) -> int {
    assert(nanoseconds <= 999999999);
    requested, remaining : TimeSpec;
    requested = TimeSpec{tv_nsec = nanoseconds};

    return _nanosleep(&requested, &remaining);
}