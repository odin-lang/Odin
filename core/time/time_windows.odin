package time

import "core:sys/win32"

IS_SUPPORTED :: true;

now :: proc() -> Time {
	file_time: win32.FILETIME;

	win32.GetSystemTimeAsFileTime(&file_time);

	ft := i64(u64(file_time.lo) | u64(file_time.hi) << 32);

	ns := (ft - 0x019db1ded53e8000) * 100;
	return Time{_nsec=ns};
}

sleep :: proc(d: Duration) {
	win32.Sleep(u32(d/Millisecond));
}
