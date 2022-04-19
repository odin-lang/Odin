// +build windows
package sys_windows

foreign import winmm "system:Winmm.lib"

@(default_calling_convention="stdcall")
foreign winmm {
	timeBeginPeriod :: proc(uPeriod: UINT) -> MMRESULT ---
	timeEndPeriod :: proc(uPeriod: UINT) -> MMRESULT ---
}
