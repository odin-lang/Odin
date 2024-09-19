#+private
package time

import win32 "core:sys/windows"

_IS_SUPPORTED :: true

_now :: proc "contextless" () -> Time {
	file_time: win32.FILETIME

	ns: i64

	// monotonic
	win32.GetSystemTimePreciseAsFileTime(&file_time)

	dt := u64(transmute(u64le)file_time) // in 100ns units
	ns = i64((dt - 116444736000000000) * 100) // convert to ns

	return unix(0, ns)
}

_sleep :: proc "contextless" (d: Duration) {
	win32.Sleep(win32.DWORD(d/Millisecond))
}

_tick_now :: proc "contextless" () -> Tick {
	mul_div_u64 :: proc "contextless" (val, num, den: i64) -> i64 {
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

	_nsec := mul_div_u64(i64(now), 1e9, i64(qpc_frequency))
	return Tick{_nsec = _nsec}
}

_yield :: proc "contextless" () {
	win32.SwitchToThread()
}
