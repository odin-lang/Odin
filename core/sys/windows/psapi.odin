#+build windows
package sys_windows

foreign import psapi "system:Psapi.lib"

@(default_calling_convention = "system")
foreign psapi {
	EnumProcessModules :: proc(hProcess: HANDLE, lphModule: ^HMODULE, cb: DWORD, lpcbNeeded: LPDWORD) -> BOOL ---

	GetProcessMemoryInfo :: proc(hProcess: HANDLE, ppsmemCounters: PPROCESS_MEMORY_COUNTERS, cb: DWORD) -> BOOL ---
	GetPerformanceInfo :: proc(pPerformanceInformation: PPERFORMANCE_INFORMATION, cb: DWORD) -> BOOL ---
}

PROCESS_MEMORY_COUNTERS :: struct {
	cb:                         DWORD,
	PageFaultCount:             DWORD,
	PeakWorkingSetSize:         SIZE_T,
	WorkingSetSize:             SIZE_T,
	QuotaPeakPagedPoolUsage:    SIZE_T,
	QuotaPagedPoolUsage:        SIZE_T,
	QuotaPeakNonPagedPoolUsage: SIZE_T,
	QuotaNonPagedPoolUsage:     SIZE_T,
	PagefileUsage:              SIZE_T,
	PeakPagefileUsage:          SIZE_T,
}

PROCESS_MEMORY_COUNTERS_EX :: struct {
	using counter: PROCESS_MEMORY_COUNTERS,
	PrivateUsage:  SIZE_T,
}

PROCESS_MEMORY_COUNTERS_EX2 :: struct {
	using counter_ex:      PROCESS_MEMORY_COUNTERS_EX,
	PrivateWorkingSetSize: SIZE_T,
	SharedCommitUsage:     ULONG64,
}

PPROCESS_MEMORY_COUNTERS :: ^PROCESS_MEMORY_COUNTERS

PERFORMANCE_INFORMATION :: struct {
	cb:                DWORD,
	CommitTotal:       SIZE_T,
	CommitLimit:       SIZE_T,
	CommitPeak:        SIZE_T,
	PhysicalTotal:     SIZE_T,
	PhysicalAvailable: SIZE_T,
	SystemCache:       SIZE_T,
	KernelTotal:       SIZE_T,
	KernelPaged:       SIZE_T,
	KernelNonpaged:    SIZE_T,
	PageSize:          SIZE_T,
	HandleCount:       DWORD,
	ProcessCount:      DWORD,
	ThreadCount:       DWORD,
}
PPERFORMANCE_INFORMATION :: ^PERFORMANCE_INFORMATION
