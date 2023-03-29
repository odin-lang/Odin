// +build windows
package sys_windows

foreign import winmm "system:Winmm.lib"

@(default_calling_convention="stdcall")
foreign winmm {
	timeGetDevCaps  :: proc(ptc: LPTIMECAPS, cbtc: UINT) -> MMRESULT ---
	timeBeginPeriod :: proc(uPeriod: UINT) -> MMRESULT ---
	timeEndPeriod   :: proc(uPeriod: UINT) -> MMRESULT ---
	timeGetTime     :: proc() -> DWORD ---
}

LPTIMECAPS :: ^TIMECAPS
TIMECAPS :: struct {
	wPeriodMin: UINT,
	wPeriodMax: UINT,
}