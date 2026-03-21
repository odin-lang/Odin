#+private
package spall

// Package is `#+no-instrumentation`, safe to use.
import "core:sys/linux"

MAX_RW :: 0x7fffffff

@(no_instrumentation)
_write :: proc "contextless" (fd: uintptr, data: []byte) #no_bounds_check /* bounds check would segfault instrumentation */ {
	n: int
	for n < len(data) {
		chunk := data[:min(len(data), MAX_RW)]
		n += linux.write(linux.Fd(fd), chunk) or_break
	}
	return
}

CLOCK_MONOTONIC_RAW :: 4 // NOTE(tetra): "RAW" means: Not adjusted by NTP.

@(no_instrumentation)
_tick_now :: proc "contextless" () -> (ns: i64) {
	t, _ := linux.clock_gettime(.MONOTONIC_RAW)
	return i64(t.time_sec)*1e9 + i64(t.time_nsec)
}
