//+private
package spall

// Only for types and constants.
import "core:os"

// Package is `//+no-instrumentation`, safe to use.
import "core:sys/linux"

MAX_RW :: 0x7fffffff

@(no_instrumentation)
_write :: proc "contextless" (fd: os.Handle, data: []byte) -> (n: int, err: os.Errno) #no_bounds_check /* bounds check would segfault instrumentation */ {
	if len(data) == 0 {
		return 0, os.ERROR_NONE
	}
	
	for n < len(data) {
		chunk := data[:min(len(data), MAX_RW)]
		written, errno := linux.write(linux.Fd(fd), chunk)
		if errno != .NONE {
			return n, os.Errno(errno)
		}
		n += written
	}

	return n, os.ERROR_NONE
}

CLOCK_MONOTONIC_RAW :: 4 // NOTE(tetra): "RAW" means: Not adjusted by NTP.

@(no_instrumentation)
_tick_now :: proc "contextless" () -> (ns: i64) {
	t, _ := linux.clock_gettime(.MONOTONIC_RAW)
	return i64(t.time_sec)*1e9 + i64(t.time_nsec)
}
