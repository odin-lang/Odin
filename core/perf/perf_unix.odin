//+build linux, darwin, freebsd
package perf

import "core:time"

now :: proc() -> Tick {
    using time;

    t := clock_gettime(CLOCK_MONOTONIC_RAW);
    return Tick{ _ns=u64(t.tv_nsec) };
}