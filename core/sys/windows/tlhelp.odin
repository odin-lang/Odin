//+build windows
package sys_windows

foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention="system")
foreign kernel32 {
	CreateToolhelp32Snapshot :: proc (dwFlags: DWORD, th32ProcessID: DWORD) -> HANDLE ---
	Process32FirstW :: proc (hSnapshot: HANDLE, lppe: LPPROCESSENTRY32W) -> BOOL ---
	Process32NextW :: proc (hSnapshot: HANDLE, lppe: LPPROCESSENTRY32W) -> BOOL ---
	Thread32First :: proc (hSnapshot: HANDLE, lpte: LPTHREADENTRY32) -> BOOL ---
	Thread32Next :: proc (hSnapshot: HANDLE, lpte: LPTHREADENTRY32) -> BOOL ---
	Module32FirstW :: proc (hSnapshot: HANDLE, lpme: LPMODULEENTRY32W) -> BOOL ---
	Module32NextW :: proc (hSnapshot: HANDLE, lpme: LPMODULEENTRY32W) -> BOOL ---
	Heap32ListFirst :: proc (hSnapshot: HANDLE, lphl: LPHEAPLIST32) -> BOOL ---
	Heap32ListNext :: proc (hSnapshot: HANDLE, lphl: LPHEAPLIST32) -> BOOL ---
	Heap32First :: proc (lphe: LPHEAPENTRY32, th32ProcessID: DWORD, th32HeapID: ULONG_PTR) -> BOOL ---
	Heap32Next :: proc (lphe: LPHEAPENTRY32) -> BOOL ---
	Toolhelp32ReadProcessMemory :: proc (
		th32ProcessID: DWORD,
		lpBaseAddress: LPCVOID,
		lpBuffer: LPVOID,
		cbRead: SIZE_T,
		lpNumberOfBytesRead: ^SIZE_T,
	) -> BOOL ---
}

MAX_MODULE_NAME32 :: 255

TH32CS_INHERIT      :: 0x80000000
TH32CS_SNAPHEAPLIST :: 0x00000001
TH32CS_SNAPPROCESS  :: 0x00000002
TH32CS_SNAPTHREAD   :: 0x00000004
TH32CS_SNAPMODULE   :: 0x00000008
TH32CS_SNAPMODULE32 :: 0x00000010
TH32CS_SNAPALL :: TH32CS_SNAPHEAPLIST | TH32CS_SNAPPROCESS | TH32CS_SNAPTHREAD | TH32CS_SNAPMODULE

PROCESSENTRY32W :: struct {
	dwSize: DWORD,
	cntUsage: DWORD,
	th32ProcessID: DWORD,
	th32DefaultHeapID: ULONG_PTR,
	th32ModuleID: DWORD,
	cntThreads: DWORD,
	th32ParentProcessID: DWORD,
	pcPriClassBase: LONG,
	dwFlags: DWORD,
	szExeFile: [MAX_PATH]WCHAR,
}

LPPROCESSENTRY32W :: ^PROCESSENTRY32W

THREADENTRY32 :: struct {
	dwSize: DWORD,
	cntUsage: DWORD,
	th32ThreadID: DWORD,
	th32OwnerProcessID: DWORD,
	tpBasePri: LONG,
	tpDeltaPri: LONG,
	dwFlags: DWORD,
}

LPTHREADENTRY32 :: ^THREADENTRY32

MODULEENTRY32W :: struct {
	dwSize: DWORD,
	th32ModuleID: DWORD,
	th32ProcessID: DWORD,
	GlblcntUsage: DWORD,
	ProccntUsage: DWORD,
	modBaseAddr: ^BYTE,
	modBaseSize: DWORD,
	hModule: HMODULE,
	szModule: [MAX_MODULE_NAME32 + 1]WCHAR,
	szExePath: [MAX_PATH]WCHAR,
}

LPMODULEENTRY32W :: ^MODULEENTRY32W

HEAPLIST32 :: struct {
	dwSize: SIZE_T,
	th32ProcessID: DWORD,
	th32HeapID: ULONG_PTR,
	dwFlags: DWORD,
}

LPHEAPLIST32 :: ^HEAPLIST32

HEAPENTRY32 :: struct {
	dwSize: SIZE_T,
	hHandle: HANDLE,
	dwAddress: ULONG_PTR,
	dwBlockSize: SIZE_T,
	dwFlags: DWORD,
	dwLockCount: DWORD,
	dwResvd: DWORD,
	th32ProcessID: DWORD,
	th32HeapID: ULONG_PTR,
}

LPHEAPENTRY32 :: ^HEAPENTRY32
