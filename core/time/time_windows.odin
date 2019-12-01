package time

import "core:sys/win32"

IS_SUPPORTED :: true;

now :: proc() -> Time {
	file_time: win32.Filetime;

	win32.get_system_time_as_file_time(&file_time);

	quad := u64(file_time.lo) | u64(file_time.hi) << 32;

	UNIX_TIME_START :: 0x019db1ded53e8000;

	ns := (1e9/1e7)*(i64(quad) - UNIX_TIME_START);
	return Time{_nsec=ns};
}

sleep :: proc(d: Duration) {
	win32.sleep(u32(d/Millisecond));
}
