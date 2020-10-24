// +build windows
package perf

import "core:sys/win32"

@(private="file")
qpc_freq : i64;

now :: proc() -> Tick {
    if qpc_freq == 0{
        win32.query_performance_frequency(&qpc_freq);
    }

    now : i64;
    win32.query_performance_counter(&now);

    result := int64_safediv(now, 1000000000, qpc_freq);
    return Tick{ _ns=u64(result) };
}