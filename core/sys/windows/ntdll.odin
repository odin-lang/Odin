// +build windows
package sys_windows

foreign import ntdll_lib "system:ntdll.lib"

@(default_calling_convention="stdcall")
foreign ntdll_lib {
	RtlGetVersion :: proc(lpVersionInformation: ^OSVERSIONINFOEXW) -> NTSTATUS ---
	NtQueryTimerResolution :: proc(MinimumResolution, MaximumResolution, CurrentResolution: PULONG) -> NTSTATUS ---
	NtSetTimerResolution   :: proc(DesiredResolution: ULONG, SetResolution: BOOLEAN, CurrentResolution: PULONG) -> NTSTATUS ---
}
