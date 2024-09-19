#+build windows
package sys_windows

foreign import "system:Dbghelp.lib"

RVA :: DWORD

MINIDUMP_LOCATION_DESCRIPTOR :: struct {
	DataSize: ULONG32,
	Rva:      RVA,
}

MINIDUMP_DIRECTORY :: struct {
	StreamType: ULONG32,
	Location:   MINIDUMP_LOCATION_DESCRIPTOR,
}

MINIDUMP_EXCEPTION_INFORMATION :: struct {
	ThreadId:          DWORD,
	ExceptionPointers: ^EXCEPTION_POINTERS,
	ClientPointers:    BOOL,
}

MINIDUMP_MEMORY_INFO :: struct {
	BaseAddress:       ULONG64,
	AllocationBase:    ULONG64,
	AllocationProtect: ULONG32,
	__alignment1:      ULONG32,
	RegionSize:        ULONG64,
	State:             ULONG32,
	Protect:           ULONG32,
	Type:              ULONG32,
	__alignment2:      ULONG32,
}

MINIDUMP_USER_STREAM :: struct {
	Type:       ULONG32,
	BufferSize: ULONG,
	Buffer:     PVOID,
}

MINIDUMP_USER_STREAM_INFORMATION :: struct {
	UserStreamCount: ULONG,
	UserStreamArray: ^MINIDUMP_USER_STREAM,
}

MINIDUMP_CALLBACK_ROUTINE :: #type proc "system" (
	CallbackParam: PVOID,
	CallbackInput: ^MINIDUMP_CALLBACK_INPUT,
	CallbackOutpu: ^MINIDUMP_CALLBACK_OUTPUT,
) -> BOOL

MINIDUMP_CALLBACK_INFORMATION :: struct {
	CallbackRoutine: MINIDUMP_CALLBACK_ROUTINE,
	CallbackParam:   PVOID,
}

MINIDUMP_CALLBACK_INPUT :: struct {
	ProcessId:     ULONG,
	ProcessHandle: HANDLE,
	CallbackType:  ULONG,
	using _: struct #raw_union {
		Status:            HRESULT,
		Thread:            MINIDUMP_THREAD_CALLBACK,
		ThreadEx:          MINIDUMP_THREAD_EX_CALLBACK,
		Module:            MINIDUMP_MODULE_CALLBACK,
		IncludeThread:     MINIDUMP_INCLUDE_THREAD_CALLBACK,
		IncludeModule:     MINIDUMP_INCLUDE_MODULE_CALLBACK,
		Io:                MINIDUMP_IO_CALLBACK,
		ReadMemoryFailure: MINIDUMP_READ_MEMORY_FAILURE_CALLBACK,
		SecondaryFlags:    ULONG,
		VmQuery:           MINIDUMP_VM_QUERY_CALLBACK,
		VmPreRead:         MINIDUMP_VM_PRE_READ_CALLBACK,
		VmPostRead:        MINIDUMP_VM_POST_READ_CALLBACK,
	},
}

_MINIDUMP_ARM64_PAD :: ULONG when ODIN_ARCH == .arm64 else struct {}

MINIDUMP_THREAD_CALLBACK :: struct {
	ThreadId:      ULONG,
	ThreadHandle:  HANDLE,
	Pad:           _MINIDUMP_ARM64_PAD,
	Context:       CONTEXT,
	SizeOfContext: ULONG,
	StackBase:     ULONG64,
	StackEnd:      ULONG64,
}

MINIDUMP_THREAD_EX_CALLBACK :: struct {
	ThreadId:         ULONG,
	ThreadHandle:     HANDLE,
	Pad:              _MINIDUMP_ARM64_PAD,
	Context:          CONTEXT,
	SizeOfContext:    ULONG,
	StackBase:        ULONG64,
	StackEnd:         ULONG64,
	BackingStoreBase: ULONG64,
	BackingStoreEnd:  ULONG64,
}

MINIDUMP_INCLUDE_THREAD_CALLBACK :: struct {
	ThreadId: ULONG,
}

// NOTE(jakubtomsu): From verrsrc.h
VS_FIXEDFILEINFO :: struct {
	dwSignature:        DWORD, /* e.g. 0xfeef04bd */
	dwStrucVersion:     DWORD, /* e.g. 0x00000042 = "0.42" */
	dwFileVersionMS:    DWORD, /* e.g. 0x00030075 = "3.75" */
	dwFileVersionLS:    DWORD, /* e.g. 0x00000031 = "0.31" */
	dwProductVersionMS: DWORD, /* e.g. 0x00030010 = "3.10" */
	dwProductVersionLS: DWORD, /* e.g. 0x00000031 = "0.31" */
	dwFileFlagsMask:    DWORD, /* = 0x3F for version "0.42" */
	dwFileFlags:        DWORD, /* e.g. VFF_DEBUG | VFF_PRERELEASE */
	dwFileOS:           DWORD, /* e.g. VOS_DOS_WINDOWS16 */
	dwFileType:         DWORD, /* e.g. VFT_DRIVER */
	dwFileSubtype:      DWORD, /* e.g. VFT2_DRV_KEYBOARD */
	dwFileDateMS:       DWORD, /* e.g. 0 */
	dwFileDateLS:       DWORD, /* e.g. 0 */
}

MINIDUMP_MODULE_CALLBACK :: struct {
	FullPath:         ^WCHAR,
	BaseOfImage:      ULONG64,
	SizeOfImage:      ULONG,
	CheckSum:         ULONG,
	TimeDateStamp:    ULONG,
	VersionInfo:      VS_FIXEDFILEINFO,
	CvRecord:         PVOID,
	SizeOfCvRecord:   ULONG,
	MiscRecord:       PVOID,
	SizeOfMiscRecord: ULONG,
}

MINIDUMP_INCLUDE_MODULE_CALLBACK :: struct {
	BaseOfImage: u64,
}

MINIDUMP_IO_CALLBACK :: struct {
	Handle:      HANDLE,
	Offset:      ULONG64,
	Buffer:      PVOID,
	BufferBytes: ULONG,
}

MINIDUMP_READ_MEMORY_FAILURE_CALLBACK :: struct {
	Offset:        ULONG64,
	Bytes:         ULONG,
	FailureStatus: HRESULT,
}

MINIDUMP_VM_QUERY_CALLBACK :: struct {
	Offset: ULONG64,
}

MINIDUMP_VM_PRE_READ_CALLBACK :: struct {
	Offset: ULONG64,
	Buffer: PVOID,
	Size:   ULONG,
}

MINIDUMP_VM_POST_READ_CALLBACK :: struct {
	Offset:    ULONG64,
	Buffer:    PVOID,
	Size:      ULONG,
	Completed: ULONG,
	Status:    HRESULT,
}

MINIDUMP_CALLBACK_OUTPUT :: struct {
	using _: struct #raw_union {
		ModuleWriteFlags: ULONG,
		ThreadWriteFlags: ULONG,
		SecondaryFlags:   ULONG,
		using _: struct {
			MemoryBase: ULONG64,
			MemorySize: ULONG,
		},
		using _: struct {
			CheckCancel: BOOL,
			Cancel:      BOOL,
		},
		Handle: HANDLE,
		using _: struct {
			VmRegion: MINIDUMP_MEMORY_INFO,
			Continue: BOOL,
		},
		using _: struct {
			VmQueryStatus: HRESULT,
			VmQueryResult: MINIDUMP_MEMORY_INFO,
		},
		using _: struct {
			VmReadStatus:         HRESULT,
			VmReadBytesCompleted: ULONG,
		},
		Status: HRESULT,
	},
}

MINIDUMP_TYPE :: enum u32 {
	Normal                         = 0x00000000,
	WithDataSegs                   = 0x00000001,
	WithFullMemory                 = 0x00000002,
	WithHandleData                 = 0x00000004,
	FilterMemory                   = 0x00000008,
	ScanMemory                     = 0x00000010,
	WithUnloadedModules            = 0x00000020,
	WithIndirectlyReferencedMemory = 0x00000040,
	FilterModulePaths              = 0x00000080,
	WithProcessThreadData          = 0x00000100,
	WithPrivateReadWriteMemory     = 0x00000200,
	WithoutOptionalData            = 0x00000400,
	WithFullMemoryInfo             = 0x00000800,
	WithThreadInfo                 = 0x00001000,
	WithCodeSegs                   = 0x00002000,
	WithoutAuxiliaryState          = 0x00004000,
	WithFullAuxiliaryState         = 0x00008000,
	WithPrivateWriteCopyMemory     = 0x00010000,
	IgnoreInaccessibleMemory       = 0x00020000,
	WithTokenInformation           = 0x00040000,
	WithModuleHeaders              = 0x00080000,
	FilterTriage                   = 0x00100000,
	WithAvxXStateContext           = 0x00200000,
	WithIptTrace                   = 0x00400000,
	ScanInaccessiblePartialPages   = 0x00800000,
	FilterWriteCombinedMemory      = 0x01000000,
	ValidTypeFlags                 = 0x01ffffff,
}


SYMBOL_INFOW :: struct {
	SizeOfStruct: ULONG,
	TypeIndex:    ULONG,
	Reserved:     [2]ULONG64,
	Index:        ULONG,
	Size:         ULONG,
	ModBase:      ULONG64,
	Flags:        ULONG,
	Value:        ULONG64,
	Address:      ULONG64,
	Register:     ULONG,
	Scope:        ULONG,
	Tag:          ULONG,
	NameLen:      ULONG,
	MaxNameLen:   ULONG,
	Name:         [1]WCHAR,
}

IMAGEHLP_LINE64 :: struct {
	SizeOfStruct: DWORD,
	Key:          PVOID,
	LineNumber:   DWORD,
	FileName:     PWSTR,
	Address:      DWORD64,
}

PSYMBOL_INFOW     :: ^SYMBOL_INFOW
PIMAGEHLP_LINEW64 :: ^IMAGEHLP_LINE64

SYMOPT_LOAD_LINES :: 0x00000010

@(default_calling_convention = "system")
foreign Dbghelp {
	MiniDumpWriteDump :: proc(
		hProcess:        HANDLE,
		ProcessId:       DWORD,
		hFile:           HANDLE,
		DumpType:        MINIDUMP_TYPE,
		ExceptionParam:  ^MINIDUMP_EXCEPTION_INFORMATION,
		UserStreamParam: ^MINIDUMP_USER_STREAM_INFORMATION,
		CallbackPara:    ^MINIDUMP_CALLBACK_INFORMATION,
	) -> BOOL ---
	
	MiniDumpReadDumpStream :: proc(
		BaseOfDump:    PVOID,
		StreamNumber:  ULONG,
		Dir:           ^^MINIDUMP_DIRECTORY,
		StreamPointer: ^PVOID,
		StreamSize:    ^ULONG,
	) -> BOOL ---

	SymInitialize         :: proc(hProcess: HANDLE, UserSearchPath: PCSTR, fInvadeProcess: BOOL) -> BOOL ---
	SymCleanup            :: proc(hProcess: HANDLE) -> BOOL ---
	SymSetOptions         :: proc(SymOptions: DWORD) -> DWORD ---
	SymFromAddrW          :: proc(hProcess: HANDLE, Address: DWORD64, Displacement: PDWORD64, Symbol: PSYMBOL_INFOW) -> BOOL ---
	SymGetLineFromAddrW64 :: proc(hProcess: HANDLE, dwAddr: DWORD64, pdwDisplacement: PDWORD, Line: PIMAGEHLP_LINEW64) -> BOOL ---
}
