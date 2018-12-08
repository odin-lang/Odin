package time

import "core:os";
import "core:fmt";

// NOTE(Jeroen): The times returned are in UTC

now :: proc() -> Time {

    time_spec_now := os.clock_gettime(os.CLOCK_REALTIME);
    ns := time_spec_now.tv_sec * 1e9 + time_spec_now.tv_nsec;
    return Time{_nsec=ns};
}

boot_time :: proc() -> Time {

    ts_now := os.clock_gettime(os.CLOCK_REALTIME);
    ts_boottime := os.clock_gettime(os.CLOCK_BOOTTIME);

    ns := (ts_now.tv_sec - ts_boottime.tv_sec) * 1e9 + ts_now.tv_nsec - ts_boottime.tv_nsec;
    return Time{_nsec=ns};
}

seconds_since_boot :: proc() -> f64 {

    ts_boottime := os.clock_gettime(os.CLOCK_BOOTTIME);
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
