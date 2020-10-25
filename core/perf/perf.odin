package perf

import "core:time"

Tick :: struct {
    _nsec: i64, // zero is performance counter start
}

Duration :: time.Duration;

ns  :: time.duration_nanoseconds;
us  :: time.duration_microseconds;
ms  :: time.duration_milliseconds;
sec :: time.duration_seconds;

diff :: inline proc(new, old: Tick) -> Duration {
    return time.Duration(new._nsec - old._nsec);
}

since :: inline proc(start: Tick) -> Duration {
    return diff(now(), start);
}

laptime :: proc(last: ^Tick) -> Duration {
    assert(last != nil);
    d : Duration;
    now := now();
    if last._nsec != 0 {
        d = diff(now, last^);
    }
    last^ = now;
    return d;
}

@(deferred_out=_end_scope_duration)
scope_duration :: proc(d: ^Duration) -> (Tick, ^Duration) {
    return now(), d;
}

_end_scope_duration :: proc(t: Tick, d: ^Duration) {
    d^ = since(t);
}