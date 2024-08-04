//+private
package spall

// Only for types.
import "core:os"

// Package is `//+no-instrumentation`, safe to use.
import win32 "core:sys/windows"

MAX_RW :: 1<<30

@(no_instrumentation)
_write :: proc "contextless" (fd: os.Handle, data: []byte) -> (int, os.Error) #no_bounds_check /* bounds check would segfault instrumentation */ {
	if len(data) == 0 {
		return 0, nil
	}

	single_write_length: win32.DWORD
	total_write: i64
	length := i64(len(data))

	for total_write < length {
		remaining := length - total_write
		to_write := win32.DWORD(min(i32(remaining), MAX_RW))

		e := win32.WriteFile(win32.HANDLE(fd), &data[total_write], to_write, &single_write_length, nil)
		if single_write_length <= 0 || !e {
			return int(total_write), os.get_last_error()
		}
		total_write += i64(single_write_length)
	}
	return int(total_write), nil
}

@(no_instrumentation)
_tick_now :: proc "contextless" () -> (ns: i64) {
	@(no_instrumentation)
	mul_div_u64 :: #force_inline proc "contextless" (val, num, den: i64) -> i64 {
		q := val / den
		r := val % den
		return q * num + r * num / den
	}

	@thread_local qpc_frequency: win32.LARGE_INTEGER

	if qpc_frequency == 0 {
		win32.QueryPerformanceFrequency(&qpc_frequency)
	}
	now: win32.LARGE_INTEGER
	win32.QueryPerformanceCounter(&now)

	return mul_div_u64(i64(now), 1e9, i64(qpc_frequency))
}
