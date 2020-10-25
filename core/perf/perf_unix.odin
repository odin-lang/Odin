//+build linux, darwin, freebsd
package perf

import "core:time"

now :: proc() -> Tick {
    using time;

    t := clock_gettime(CLOCK_MONOTONIC_RAW);
    return Tick{ _nsec=t.tv_sec * 1000000000 + t.tv_nsec };
}