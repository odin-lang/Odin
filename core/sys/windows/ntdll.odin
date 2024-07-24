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

	NtQueryInformationFile :: proc(
		FileHandle:           HANDLE,
		IoStatusBlock:        PIO_STATUS_BLOCK,
		FileInformation:      rawptr,
		Length:               ULONG,
		FileInformationClass: FILE_INFORMATION_CLASS,
	) -> NTSTATUS ---
}

PIO_STATUS_BLOCK :: ^IO_STATUS_BLOCK
IO_STATUS_BLOCK :: struct {
	using _: struct #raw_union {
		Status:  NTSTATUS,
		Pointer: rawptr,
	},
	Information: ULONG_PTR,
}


PROCESS_INFO_CLASS :: enum c_int {
	ProcessBasicInformation       = 0,
	ProcessDebugPort              = 7,
	ProcessWow64Information       = 26,
	ProcessImageFileName          = 27,
	ProcessBreakOnTermination     = 29,
	ProcessTelemetryIdInformation = 64,
	ProcessSubsystemInformation   = 75,
}


PFILE_INFORMATION_CLASS :: ^FILE_INFORMATION_CLASS
FILE_INFORMATION_CLASS :: enum c_int {
	FileDirectoryInformation                     = 1,
	FileFullDirectoryInformation                 = 2,
	FileBothDirectoryInformation                 = 3,
	FileBasicInformation                         = 4,
	FileStandardInformation                      = 5,
	FileInternalInformation                      = 6,
	FileEaInformation                            = 7,
	FileAccessInformation                        = 8,
	FileNameInformation                          = 9,
	FileRenameInformation                        = 10,
	FileLinkInformation                          = 11,
	FileNamesInformation                         = 12,
	FileDispositionInformation                   = 13,
	FilePositionInformation                      = 14,
	FileFullEaInformation                        = 15,
	FileModeInformation                          = 16,
	FileAlignmentInformation                     = 17,
	FileAllInformation                           = 18,
	FileAllocationInformation                    = 19,
	FileEndOfFileInformation                     = 20,
	FileAlternateNameInformation                 = 21,
	FileStreamInformation                        = 22,
	FilePipeInformation                          = 23,
	FilePipeLocalInformation                     = 24,
	FilePipeRemoteInformation                    = 25,
	FileMailslotQueryInformation                 = 26,
	FileMailslotSetInformation                   = 27,
	FileCompressionInformation                   = 28,
	FileObjectIdInformation                      = 29,
	FileCompletionInformation                    = 30,
	FileMoveClusterInformation                   = 31,
	FileQuotaInformation                         = 32,
	FileReparsePointInformation                  = 33,
	FileNetworkOpenInformation                   = 34,
	FileAttributeTagInformation                  = 35,
	FileTrackingInformation                      = 36,
	FileIdBothDirectoryInformation               = 37,
	FileIdFullDirectoryInformation               = 38,
	FileValidDataLengthInformation               = 39,
	FileShortNameInformation                     = 40,
	FileIoCompletionNotificationInformation      = 41,
	FileIoStatusBlockRangeInformation            = 42,
	FileIoPriorityHintInformation                = 43,
	FileSfioReserveInformation                   = 44,
	FileSfioVolumeInformation                    = 45,
	FileHardLinkInformation                      = 46,
	FileProcessIdsUsingFileInformation           = 47,
	FileNormalizedNameInformation                = 48,
	FileNetworkPhysicalNameInformation           = 49,
	FileIdGlobalTxDirectoryInformation           = 50,
	FileIsRemoteDeviceInformation                = 51,
	FileUnusedInformation                        = 52,
	FileNumaNodeInformation                      = 53,
	FileStandardLinkInformation                  = 54,
	FileRemoteProtocolInformation                = 55,
	FileRenameInformationBypassAccessCheck       = 56,
	FileLinkInformationBypassAccessCheck         = 57,
	FileVolumeNameInformation                    = 58,
	FileIdInformation                            = 59,
	FileIdExtdDirectoryInformation               = 60,
	FileReplaceCompletionInformation             = 61,
	FileHardLinkFullIdInformation                = 62,
	FileIdExtdBothDirectoryInformation           = 63,
	FileDispositionInformationEx                 = 64,
	FileRenameInformationEx                      = 65,
	FileRenameInformationExBypassAccessCheck     = 66,
	FileDesiredStorageClassInformation           = 67,
	FileStatInformation                          = 68,
	FileMemoryPartitionInformation               = 69,
	FileStatLxInformation                        = 70,
	FileCaseSensitiveInformation                 = 71,
	FileLinkInformationEx                        = 72,
	FileLinkInformationExBypassAccessCheck       = 73,
	FileStorageReserveIdInformation              = 74,
	FileCaseSensitiveInformationForceAccessCheck = 75,
	FileKnownFolderInformation                   = 76,
	FileStatBasicInformation                     = 77,
	FileId64ExtdDirectoryInformation             = 78,
	FileId64ExtdBothDirectoryInformation         = 79,
	FileIdAllExtdDirectoryInformation            = 80,
	FileIdAllExtdBothDirectoryInformation        = 81,
	FileStreamReservationInformation,
	FileMupProviderInfo,
	FileMaximumInformation,
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