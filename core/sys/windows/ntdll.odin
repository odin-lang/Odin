// +build windows
package sys_windows

foreign import ntdll_lib "system:ntdll.lib"

@(default_calling_convention="stdcall")
foreign ntdll_lib {
	RtlGetVersion :: proc(lpVersionInformation: ^OSVERSIONINFOEXW) -> NTSTATUS ---
	NtQueryTimerResolution :: proc(MinimumResolution, MaximumResolution, CurrentResolution: win32.PULONG) -> win32.NTSTATUS ---
	NtSetTimerResolution   :: proc(DesiredResolution: win32.ULONG, SetResolution: win32.BOOLEAN, CurrentResolution: win32.PULONG) -> win32.NTSTATUS ---
}
