// +build windows
package sys_windows

foreign import "system:Ole32.lib"

//objbase.h
COINIT :: enum DWORD {
	APARTMENTTHREADED = 0x2,
	MULTITHREADED,
	DISABLE_OLE1DDE   = 0x4,
	SPEED_OVER_MEMORY = 0x8,
}

@(default_calling_convention="stdcall")
foreign Ole32 {
	CoInitializeEx :: proc(reserved: rawptr, co_init: COINIT) -> HRESULT ---
	CoUninitialize :: proc() ---
}
