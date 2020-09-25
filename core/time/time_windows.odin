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
