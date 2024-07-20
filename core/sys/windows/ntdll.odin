// +build windows
package sys_windows

foreign import ntdll_lib "system:ntdll.lib"

@(default_calling_convention="system")
foreign ntdll_lib {
	RtlGetVersion :: proc(lpVersionInformation: ^OSVERSIONINFOEXW) -> NTSTATUS ---


	NtQueryInformationProcess :: proc(
		ProcessHandle:            HANDLE,
		ProcessInformationClass:  PROCESS_INFO_CLASS,
		ProcessInformation:       rawptr,
		ProcessInformationLength: u32,
		ReturnLength:             ^u32,
	) -> u32 ---
}


PROCESS_INFO_CLASS :: enum i32 {
	ProcessBasicInformation       = 0,
	ProcessDebugPort              = 7,
	ProcessWow64Information       = 26,
	ProcessImageFileName          = 27,
	ProcessBreakOnTermination     = 29,
	ProcessTelemetryIdInformation = 64,
	ProcessSubsystemInformation   = 75,
}



PROCESS_BASIC_INFORMATION :: struct {
	ExitStatus:                   NTSTATUS,
	PebBaseAddress:               ^PEB,
	AffinityMask:                 ULONG_PTR,
	BasePriority:                 KPRIORITY,
	UniqueProcessId:              ULONG_PTR,
	InheritedFromUniqueProcessId: ULONG_PTR,
}

KPRIORITY :: rawptr

PPS_POST_PROCESS_INIT_ROUTINE :: proc "system" ()


PEB :: struct {
	_:                      [2]u8,
	BeingDebugged:          u8,
	_:                      [1]u8,
	_:                      [2]rawptr,
	Ldr:                    ^PEB_LDR_DATA,
	ProcessParameters:      ^RTL_USER_PROCESS_PARAMETERS,
	_:                      [104]u8,
	_:                      [52]rawptr,
	PostProcessInitRoutine: PPS_POST_PROCESS_INIT_ROUTINE,
	_:                      [128]u8,
	_:                      [1]rawptr,
	SessionId:              u32,
}




PEB_LDR_DATA :: struct {
	_: [8]u8,
	_: [3]rawptr,
	InMemoryOrderModuleList: LIST_ENTRY,
}

RTL_USER_PROCESS_PARAMETERS :: struct {
	MaximumLength:          u32,
	Length:                 u32,
	Flags:                  u32,
	DebugFlags:             u32,
	ConsoleHandle:          rawptr,
	ConsoleFlags:           u32,
	StdInputHandle:         rawptr,
	StdOutputHandle:        rawptr,
	StdErrorHandle:         rawptr,
	CurrentDirectoryPath:   UNICODE_STRING,
	CurrentDirectoryHandle: rawptr,
	DllPath:                UNICODE_STRING,
	ImagePathName:          UNICODE_STRING,
	CommandLine:            UNICODE_STRING,
	Environment:            rawptr,
	StartingPositionLeft:   u32,
	StartingPositionTop:    u32,
	Width:                  u32,
	Height:                 u32,
	CharWidth:              u32,
	CharHeight:             u32,
	ConsoleTextAttributes:  u32,
	WindowFlags:            u32,
	ShowWindowFlags:        u32,
	WindowTitle:            UNICODE_STRING,
	DesktopName:            UNICODE_STRING,
	ShellInfo:              UNICODE_STRING,
	RuntimeData:            UNICODE_STRING,
	DLCurrentDirectory:     [32]RTL_DRIVE_LETTER_CURDIR,
	EnvironmentSize:        u32,
}

RTL_DRIVE_LETTER_CURDIR :: struct {
	Flags:     u16,
	Length:    u16,
	TimeStamp: u32,
	DosPath:   UNICODE_STRING,
}


LIST_ENTRY :: struct {
	Flink: ^LIST_ENTRY,
	Blink: ^LIST_ENTRY,
}