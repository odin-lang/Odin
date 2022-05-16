package rand

import win32 "core:sys/windows"

_system_random :: proc() -> u32 {
	value: u32
	status := win32.BCryptGenRandom(nil, ([^]u8)(&value), 4, win32.BCRYPT_USE_SYSTEM_PREFERRED_RNG)
	if status < 0 {
		panic("BCryptGenRandom failed")
	}
	return value
}