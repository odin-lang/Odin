//+private
//+build darwin, freebsd, openbsd, netbsd
package spall

// Only for types.
import "core:os"

import "core:sys/posix"

MAX_RW :: 0x7fffffff

@(no_instrumentation)
_write :: proc "contextless" (fd: os.Handle, data: []byte) -> (n: int, err: os.Error) #no_bounds_check /* bounds check would segfault instrumentation */ {
	if len(data) == 0 {
		return 0, nil
	}

	for n < len(data) {
		chunk := data[:min(len(data), MAX_RW)]
		written := posix.write(posix.FD(fd), raw_data(chunk), len(chunk))
		if written < 0 {
			return n, os.get_last_error()
		}
		n += written
	}

	return n, nil
}

// NOTE(tetra): "RAW" means: Not adjusted by NTP.
when ODIN_OS == .Darwin {
	CLOCK :: posix.Clock(4) // CLOCK_MONOTONIC_RAW
} else {
	// It looks like the BSDs don't have a CLOCK_MONOTONIC_RAW equivalent.
	CLOCK :: posix.Clock.MONOTONIC
}

@(no_instrumentation)
_tick_now :: proc "contextless" () -> (ns: i64) {
	t: posix.timespec
	posix.clock_gettime(CLOCK, &t)
	return i64(t.tv_sec)*1e9 + i64(t.tv_nsec)
}
