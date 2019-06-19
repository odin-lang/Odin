package time

import "core:os"

IS_SUPPORTED :: false;

Timebase_Info :: struct {
    numer: u32,
    denom: u32,
}

foreign import libc "system:c"
foreign libc {
    mach_absolute_time :: proc() -> u64 ---;
    mach_timebase_info :: proc(t: ^Timebase_Info) -> i32 ---;
}

_init_timebase_info :: proc() -> (out: Timebase_Info) {
    mach_timebase_info(&out);
    return out;
}

_info := _init_timebase_info();

import "core:fmt"

debug_timebase_info :: proc() {
    fmt.println("info:", _info);
}

now_monotonic :: proc() -> Time {
    t := mach_absolute_time();
    ns := i64(t) * i64(_info.numer) / i64(_info.denom);
    return Time{_nsec=ns};
}