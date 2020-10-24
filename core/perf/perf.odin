package perf

import "core:time"

/**
 * Time relative to performance counter start
 */
Tick :: struct {
    _ns: u64,
}

/**
 * Prevents 64-bit overflow when converting 
 * 
 * @see https://gist.github.com/jspohr/3dc4f00033d79ec5bdaf67bc46c813e3
 */
int64_safediv :: proc(v: i64, n: i64, d: i64) -> i64 {
    q := v / d;
    r := v % d;
    return q * n + r * n / d;
}

diff :: proc(new: Tick, old: Tick) -> Tick {
    if new._ns > old._ns {
        return Tick{ _ns=new._ns - old._ns };
    }
    return Tick{ _ns=1 };
}

since :: proc(start: Tick) -> Tick {
    return diff(now(), start);
}

laptime :: proc(last: ^Tick) -> Tick {
    assert(last != nil);
    dt : Tick;
    now := now();
    if last._ns != 0 {
        dt = diff(now, last^);
    }
    last^ = now;
    return dt;
}

sec :: inline proc(t: Tick) -> f64 {
    return f64(t._ns) / 1000000000.0;
}

ms :: inline proc(t: Tick) -> f64 {
    return f64(t._ns) / 1000000.0;
}

us :: inline proc(t: Tick) -> f64 {
    return f64(t._ns) / 1000.0;
}

ns :: inline proc(t: Tick) -> f64 {
    return f64(t._ns);
}