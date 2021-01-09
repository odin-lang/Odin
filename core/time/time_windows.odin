package time

import win32 "core:sys/windows"

IS_SUPPORTED :: true;

now :: proc() -> Time {
	file_time: win32.FILETIME;
	win32.GetSystemTimeAsFileTime(&file_time);
	ns := win32.FILETIME_as_unix_nanoseconds(file_time);
	return Time{_nsec=ns};
}

sleep :: proc(d: Duration) {
	win32.Sleep(win32.DWORD(d/Millisecond));
}



_tick_now :: proc() -> Tick {
	mul_div_u64 :: proc(val, num, den: i64) -> i64 {
		q := val / den;
		r := val % den;
		return q * num + r * num / den;
	}

	@thread_local qpc_frequency: win32.LARGE_INTEGER;

	if qpc_frequency == 0 {
		win32.QueryPerformanceFrequency(&qpc_frequency);
	}
	now: win32.LARGE_INTEGER;
	win32.QueryPerformanceCounter(&now);

	_nsec := i64(mul_div_u64(i64(now), 1e9, i64(qpc_frequency)));
	return Tick{_nsec = _nsec};
}
