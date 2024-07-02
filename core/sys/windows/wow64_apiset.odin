//+build windows
package sys_windows

foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention="system")
foreign kernel32 {
	GetSystemWow64Directory2W :: proc (lpBuffer: LPWSTR, uSize: UINT, ImageFileMachineTyp: WORD) -> UINT ---
	GetSystemWow64DirectoryW :: proc (lpBuffer: LPWSTR, uSize: UINT) -> UINT ---
	IsWow64GuestMachineSupported :: proc (WowGuestMachine: USHORT, MachineIsSupported: ^BOOL) -> HRESULT ---
	IsWow64Process :: proc (hProcess: HANDLE, Wow64Process: PBOOL) -> BOOL ---
	IsWow64Process2 :: proc (hProcess: HANDLE, pProcessMachine: ^USHORT, pNativeMachine: ^USHORT) -> BOOL ---
	Wow64EnableWow64FsRedirection :: proc (Wow64FsEnableRedirection: BOOLEAN) -> BOOLEAN ---
	Wow64DisableWow64FsRedirection :: proc (OldValue: ^PVOID) -> BOOL ---
	Wow64RevertWow64FsRedirection :: proc (OlValue: PVOID) -> BOOL ---
	Wow64GetThreadContext :: proc (hThread: HANDLE, lpContext: PWOW64_CONTEXT) -> BOOL ---
	Wow64SetThreadContext :: proc(hThread: HANDLE, lpContext: ^WOW64_CONTEXT) -> BOOL ---
	Wow64SetThreadDefaultGuestMachine :: proc(Machine: USHORT) -> USHORT ---
	Wow64SuspendThread :: proc (hThread: HANDLE) -> DWORD ---
}

WOW64_CONTEXT_i386 :: 0x00010000

WOW64_CONTEXT_CONTROL :: (WOW64_CONTEXT_i386 | 0x00000001)
WOW64_CONTEXT_INTEGER :: (WOW64_CONTEXT_i386 | 0x00000002)
WOW64_CONTEXT_SEGMENTS :: (WOW64_CONTEXT_i386 | 0x00000004)

WOW64_CONTEXT_FLOATING_POINT :: (WOW64_CONTEXT_i386 | 0x00000008)
WOW64_CONTEXT_DEBUG_REGISTERS :: (WOW64_CONTEXT_i386 | 0x00000010)
WOW64_CONTEXT_EXTENDED_REGISTERS :: (WOW64_CONTEXT_i386 | 0x00000020)
WOW64_CONTEXT_FULL :: (WOW64_CONTEXT_CONTROL | WOW64_CONTEXT_INTEGER | WOW64_CONTEXT_SEGMENTS)
WOW64_CONTEXT_ALL :: (
	WOW64_CONTEXT_CONTROL |
	WOW64_CONTEXT_INTEGER |
	WOW64_CONTEXT_SEGMENTS |
	WOW64_CONTEXT_FLOATING_POINT |
	WOW64_CONTEXT_DEBUG_REGISTERS |
	WOW64_CONTEXT_EXTENDED_REGISTERS)

WOW64_SIZE_OF_80387_REGISTERS ::  80
WOW64_MAXIMUM_SUPPORTED_EXTENSION ::  512

WOW64_CONTEXT :: struct {
	ContextFlags: DWORD,
	Dr0: DWORD,
	Dr1: DWORD,
	Dr2: DWORD,
	Dr3: DWORD,
	Dr6: DWORD,
	Dr7: DWORD,
	FloatSave: WOW64_FLOATING_SAVE_AREA,
	SegGs: DWORD,
	SegFs: DWORD,
	SegEs: DWORD,
	SegDs: DWORD,
	Edi: DWORD,
	Esi: DWORD,
	Ebx: DWORD,
	Edx: DWORD,
	Ecx: DWORD,
	Eax: DWORD,
	Ebp: DWORD,
	Eip: DWORD,
	SegCs: DWORD,
	EFlags: DWORD,
	Esp: DWORD,
	SegSs: DWORD,
	ExtendedRegisters: [WOW64_MAXIMUM_SUPPORTED_EXTENSION]BYTE,
}

PWOW64_CONTEXT :: ^WOW64_CONTEXT

WOW64_FLOATING_SAVE_AREA :: struct {
	ControlWord: DWORD,
	StatusWord: DWORD,
	TagWord: DWORD,
	ErrorOffset: DWORD,
	ErrorSelector: DWORD,
	DataOffset: DWORD,
	DataSelector: DWORD,
	RegisterArea: [WOW64_SIZE_OF_80387_REGISTERS]BYTE,
	Cr0NpxState: DWORD,
}

PWOW64_FLOATING_SAVE_AREA :: ^WOW64_FLOATING_SAVE_AREA