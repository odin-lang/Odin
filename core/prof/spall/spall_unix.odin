//+private
//+build darwin, freebsd, openbsd, netbsd
package spall

// Only for types.
import "core:os"

when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

timespec :: struct {
	tv_sec:  i64, // seconds
	tv_nsec: i64, // nanoseconds
}

foreign libc {
	__error :: proc() -> ^i32 ---
	@(link_name="write")         _unix_write         :: proc(handle: os.Handle, buffer: rawptr, count: uint) -> int ---
	@(link_name="clock_gettime") _unix_clock_gettime :: proc(clock_id: u64, timespec: ^timespec) -> i32 ---
}

MAX_RW :: 0x7fffffff

@(no_instrumentation)
_write :: proc "contextless" (fd: os.Handle, data: []byte) -> (n: int, err: os.Error) #no_bounds_check /* bounds check would segfault instrumentation */ {
	if len(data) == 0 {
		return 0, nil
	}

	for n < len(data) {
		chunk := data[:min(len(data), MAX_RW)]
		written := _unix_write(fd, raw_data(chunk), len(chunk))
		if written < 0 {
			return n, os.get_last_error()
		}
		n += written
	}

	return n, nil
}

CLOCK_MONOTONIC_RAW :: 4 // NOTE(tetra): "RAW" means: Not adjusted by NTP.

@(no_instrumentation)
_tick_now :: proc "contextless" () -> (ns: i64) {
	t: timespec
	_unix_clock_gettime(CLOCK_MONOTONIC_RAW, &t)
	return t.tv_sec*1e9 + t.tv_nsec
}
