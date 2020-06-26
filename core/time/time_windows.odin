package time

import win32 "core:sys/windows"

IS_SUPPORTED :: true;

now :: proc() -> Time {
	file_time: win32.FILETIME;

	win32.GetSystemTimeAsFileTime(&file_time);

	ft := i64(u64(file_time.dwLowDateTime) | u64(file_time.dwHighDateTime) << 32);

	ns := (ft - 0x019db1ded53e8000) * 100;
	return Time{_nsec=ns};
}

sleep :: proc(d: Duration) {
	win32.Sleep(win32.DWORD(d/Millisecond));
}
