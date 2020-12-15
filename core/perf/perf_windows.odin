// +build windows
package perf

import "core:sys/win32"

@private
@thread_local
qpc_freq : i64;

/**
 * Prevents 64-bit overflow when converting from sec to ns
 * 
 * @see https://gist.github.com/jspohr/3dc4f00033d79ec5bdaf67bc46c813e3
 */
int64_safediv :: proc(v, n, d: i64) -> i64 {
    q := v / d;
    r := v % d;
    return q * n + r * n / d;
}

now :: proc() -> Tick {
    if qpc_freq == 0{
        win32.query_performance_frequency(&qpc_freq);
    }

    now : i64;
    win32.query_performance_counter(&now);

    result := int64_safediv(now, 1000000000, qpc_freq);
    return Tick{ _nsec=result };
}