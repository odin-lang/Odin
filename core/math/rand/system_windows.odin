package rand

import win32 "core:sys/windows"

@(require_results)
_system_random :: proc() -> u64 {
	value: u64
	status := win32.BCryptGenRandom(nil, ([^]u8)(&value), size_of(value), win32.BCRYPT_USE_SYSTEM_PREFERRED_RNG)
	if status < 0 {
		panic("BCryptGenRandom failed")
	}
	return value
}