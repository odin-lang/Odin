#+build windows
package sys_windows

import "base:intrinsics"
import "core:c"

foreign import psapi "system:Psapi.lib"

@(default_calling_convention="system")
foreign psapi {
	EnumProcesses :: proc(lpidProcess: PDWORD, cb: DWORD, lpcbNeeded: LPDWORD) -> BOOL ---
	EnumProcessModules :: proc(hProcess: HANDLE, lphModule: ^HMODULE, cb: DWORD, lpcbNeeded: LPDWORD) -> BOOL ---
	EnumProcessModulesEx :: proc(hProcess: HANDLE, lphModule: ^HMODULE, cb: DWORD, lpcbNeeded: LPDWORD, dwFilterFlag: DWORD) -> BOOL ---

	GetModuleBaseNameW :: proc(hProcess: HANDLE, hModule: HMODULE, lpBaseName: LPWSTR, nSize: DWORD) -> DWORD ---
	GetModuleFileNameExW :: proc(hProcess: HANDLE, hModule: HMODULE, lpFilename: LPWSTR, nSize: DWORD) -> DWORD ---

	GetModuleInformation :: proc(hProcess: HANDLE, hModule: HMODULE,lpmodinfo: LPMODULEINFO, cb: DWORD) -> BOOL ---

	EmptyWorkingSet :: proc(hProcess: HANDLE) -> BOOL ---
	QueryWorkingSet :: proc(hProcess: HANDLE, pv: PVOID, cb: DWORD) -> BOOL ---
	QueryWorkingSetEx :: proc(hProcess: HANDLE, pv: PVOID, cb: DWORD) -> BOOL ---

	InitializeProcessForWsWatch :: proc(hProces: HANDLE) -> BOOL ---
	GetWsChanges :: proc(hProcess: HANDLE, lpWatchInfo: PPSAPI_WS_WATCH_INFORMATION, cb: DWORD) -> BOOL ---
	GetWsChangesEx :: proc(hProcess: HANDLE, lpWatchInfoEx: PPSAPI_WS_WATCH_INFORMATION_EX, cb: PDWORD) -> BOOL ---

	GetMappedFileNameW :: proc (hProcess: HANDLE, lpv: LPVOID, lpFilename: LPWSTR, nSize: DWORD) -> DWORD ---

	EnumDeviceDrivers :: proc (lpImageBase: ^LPVOID, cb: DWORD, lpcbNeeded: LPDWORD) -> BOOL ---
	GetDeviceDriverBaseNameW :: proc (lpImageBase: LPVOID, lpBaseName: LPWSTR, nSize: DWORD) -> DWORD ---
	GetDeviceDriverFileNameW :: proc (lpImageBase: LPVOID, lpFilename: LPWSTR, nSize: DWORD) -> DWORD ---

	GetProcessMemoryInfo :: proc(hProcess: HANDLE, ppsmemCounters: PPROCESS_MEMORY_COUNTERS, cb: DWORD) -> BOOL ---

	GetPerformanceInfo :: proc(pPerformanceInformation: PPERFORMANCE_INFORMATION, cb: DWORD) -> BOOL ---
	EnumPageFilesW :: proc(pCallBackRoutine: Enum_Page_File_Callback, pContext: LPVOID) -> BOOL ---
	GetProcessImageFileNameW :: proc (hProcess: HANDLE, lpImageFileName: LPWSTR, nSize: DWORD) -> DWORD ---
}

GetModuleBaseName :: GetModuleBaseNameW
GetModuleFileNameEx :: GetModuleFileNameExW
GetMappedFileName :: GetMappedFileNameW
GetDeviceDriverBaseName :: GetDeviceDriverBaseNameW
GetDeviceDriverFileName :: GetDeviceDriverFileNameW
EnumPageFiles :: EnumPageFilesW
GetProcessImageFileName :: GetProcessImageFileNameW

MODULEINFO :: struct {
	lpBaseOfDll: LPVOID,
	SizeOfImage: DWORD,
	EntryPoint:  LPVOID,
}
LPMODULEINFO :: ^MODULEINFO

when ODIN_ARCH == .amd64 { 
	PSAPI_WORKING_SET_BLOCK :: struct #raw_union {
		Flags: ULONG_PTR,
		using DUMMYNAME : bit_field uintptr {
			Proctection: ULONG_PTR | 5,
			ShareCount:  ULONG_PTR | 3,
			Shared:      ULONG_PTR | 1,
			Reserved:    ULONG_PTR | 3,
			VirtualPage: ULONG_PTR | 52,
		}
	}

	PSAPI_WORKING_SET_EX_BLOCK :: struct #raw_union {
		Flags: ULONG_PTR,
		using DUMMYNAME : bit_field uintptr {
			Valid:           ULONG_PTR | 1,
			ShareCount:      ULONG_PTR | 3,
			Win32Protection: ULONG_PTR | 11,
			Shared:          ULONG_PTR | 1,
			Node:            ULONG_PTR | 6,
			Locked:          ULONG_PTR | 1,
			LargePage:       ULONG_PTR | 1,
			Reserved:        ULONG_PTR | 7,
			Bad:             ULONG_PTR | 1,
			ReservedUlong:   ULONG_PTR | 32,
		},
		Invalid: bit_field uintptr {
			Valid:         ULONG_PTR | 1,
			Reserved0:     ULONG_PTR | 14,
			Shared:        ULONG_PTR | 1,
			Reserved1:     ULONG_PTR | 15,
			Bad:           ULONG_PTR | 1,
			ReservedUlong: ULONG_PTR | 32,
		},
	}
} else when ODIN_ARCH == .i386 {
	PSAPI_WORKING_SET_BLOCK :: struct #raw_union {
		Flags: ULONG_PTR,
		using DUMMYNAME : bit_field uintptr {
			Proctection: ULONG_PTR | 5,
			ShareCount:  ULONG_PTR | 3,
			Shared:      ULONG_PTR | 1,
			Reserved:    ULONG_PTR | 3,
			VirtualPage: ULONG_PTR | 20,
		}
	}

	PSAPI_WORKING_SET_EX_BLOCK :: struct #raw_union {
		Flags: ULONG_PTR,
		using DUMMYNAME : bit_field uintptr {
			Valid:           ULONG_PTR | 1,
			ShareCount:      ULONG_PTR | 3,
			Win32Protection: ULONG_PTR | 11,
			Shared:          ULONG_PTR | 1,
			Node:            ULONG_PTR | 6,
			Locked:          ULONG_PTR | 1,
			LargePage:       ULONG_PTR | 1,
			Reserved:        ULONG_PTR | 7,
			Bad:             ULONG_PTR | 1,
		},
		Invalid: bit_field uintptr {
			Valid:     ULONG_PTR | 1,
			Reserved0: ULONG_PTR | 14,
			Shared:    ULONG_PTR | 1,
			Reserved1: ULONG_PTR | 15,
			Bad:       ULONG_PTR | 1,
		},
	}
}

PPSAPI_WORKING_SET_BLOCK :: ^PSAPI_WORKING_SET_BLOCK
PPSAPI_WORKING_SET_EX_BLOCK :: ^PSAPI_WORKING_SET_EX_BLOCK

PSAPI_WORKING_SET_INFORMATION :: struct{
	NumberOfEntries: ULONG_PTR,
	WorkingSetInfo:  [1]PSAPI_WORKING_SET_BLOCK,
} 

PPSAPI_WORKING_SET_INFORMATION :: ^PSAPI_WORKING_SET_INFORMATION


PSAPI_WORKING_SET_EX_INFORMATION :: struct {
	VirtualAddress:    PVOID,
	VirtualAttributes: PSAPI_WORKING_SET_EX_BLOCK,
} 
PPSAPI_WORKING_SET_EX_INFORMATION :: ^PSAPI_WORKING_SET_EX_INFORMATION


PSAPI_WS_WATCH_INFORMATION :: struct {
	FaultingPc: LPVOID,
	FaultingVa: LPVOID,
}
PPSAPI_WS_WATCH_INFORMATION :: ^PSAPI_WS_WATCH_INFORMATION

PSAPI_WS_WATCH_INFORMATION_EX :: struct {
	BasicInfo:        PSAPI_WS_WATCH_INFORMATION,
	FaultingThreadId: ULONG_PTR,
	Flags:            ULONG_PTR,    // Reserved
} 
PPSAPI_WS_WATCH_INFORMATION_EX :: ^PSAPI_WS_WATCH_INFORMATION_EX


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
	PrivateUsage:  SIZE_T
}

PROCESS_MEMORY_COUNTERS_EX2 :: struct {
	using counter_ex:      PROCESS_MEMORY_COUNTERS_EX,
	PrivateWorkingSetSize: SIZE_T ,
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

ENUM_PAGE_FILE_INFORMATION :: struct {
    cb:         DWORD,
    Reserved:   DWORD,
    TotalSize:  SIZE_T,
    TotalInUse: SIZE_T,
    PeakUsage:  SIZE_T,
} 
PENUM_PAGE_FILE_INFORMATION :: ^ENUM_PAGE_FILE_INFORMATION

Enum_Page_File_Callback :: #type proc "system" (pContext: LPVOID, pPageFileInfo: PENUM_PAGE_FILE_INFORMATION, lpFilename: LPCWSTR) -> BOOL
