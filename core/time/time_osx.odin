package time

import "core:os";

IS_SUPPORTED :: true;

now :: proc() -> Time {

    time_spec_now := os.clock_gettime(os.CLOCK_SYSTEM);
    ns := time_spec_now.tv_sec * 1e9 + time_spec_now.tv_nsec;
    return Time{_nsec=ns};
}

seconds_since_boot :: proc() -> f64 {

    ts_boottime := os.clock_gettime(os.CLOCK_SYSTEM);
    return f64(ts_boottime.tv_sec) + f64(ts_boottime.tv_nsec) / 1e9;
}

sleep :: proc(d: Duration) {

    ds := duration_seconds(d);
    seconds := u64(ds);
    nanoseconds := i64((ds - f64(seconds)) * 1e9);

    if seconds > 0 do os.sleep(seconds);
    if nanoseconds > 0 do os.nanosleep(nanoseconds);
}

nanosleep :: proc(d: Duration) {
    // NOTE(Jeroen): os.nanosleep returns -1 on failure, 0 on success
    // duration needs to be [0, 999999999] nanoseconds.
    os.nanosleep(i64(d));
}
