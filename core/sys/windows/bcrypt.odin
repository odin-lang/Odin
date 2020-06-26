package sys_windows

foreign import bcrypt "system:Bcrypt.lib"

BCRYPT_USE_SYSTEM_PREFERRED_RNG: DWORD : 0x00000002;

@(default_calling_convention="stdcall")
foreign bcrypt {
	BCryptGenRandom :: proc(hAlgorithm: LPVOID, pBuffer: ^u8, cbBuffer: ULONG, dwFlags: ULONG) -> LONG ---
}
