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

	NtQueryDirectoryFileEx :: proc(
		FileHandle:           HANDLE,
		Event:                HANDLE,
		ApcRoutine:           PIO_APC_ROUTINE,
		ApcContext:           PVOID,
		IoStatusBlock:        PIO_STATUS_BLOCK,
		FileInformation:      PVOID,
		Length:               ULONG,
		FileInformationClass: FILE_INFORMATION_CLASS,
		QueryFlags:           ULONG,
		FileName   :          PUNICODE_STRING,
	) -> NTSTATUS ---
}


PIO_APC_ROUTINE :: #type proc "system" (ApcContext: rawptr, IoStatusBlock: PIO_STATUS_BLOCK, Reserved: ULONG)

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

SL_RESTART_SCAN                :: 0x00000001 // The scan will start at the first entry in the directory. If this flag is not set, the scan will resume from where the last query ended.
SL_RETURN_SINGLE_ENTRY         :: 0x00000002 // Normally the return buffer is packed with as many matching directory entries that fit. If this flag is set, the file system will return only one directory entry at a time. This does make the operation less efficient.
SL_INDEX_SPECIFIED             :: 0x00000004 // The scan should start at a specified indexed position in the directory. This flag can only be set if you generate your own IRP_MJ_DIRECTORY_CONTROL IRP; the index is specified in the IRP. How the position is specified varies from file system to file system.
SL_RETURN_ON_DISK_ENTRIES_ONLY :: 0x00000008 // Any file system filters that perform directory virtualization or just-in-time expansion should simply pass the request through to the file system and return entries that are currently on disk. Not all file systems support this flag.
SL_NO_CURSOR_UPDATE_QUERY      :: 0x00000010 // File systems maintain per-FileObject directory cursor information. When multiple threads do queries using the same FileObject, access to the per-FileObject structure is single threaded to prevent corruption of the cursor state. This flag tells the file system to not update per-FileObject cursor state information thus allowing multiple threads to query in parallel using the same handle. It behaves as if SL_RESTART_SCAN is specified on each call. If a wild card pattern is given on the next call, the operation will not pick up where the last query ended. This allows for true asynchronous directory query support. If this flag is used inside a TxF transaction the operation will be failed. Not all file systems support this flag.


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

PFILE_ID_FULL_DIR_INFORMATION :: ^FILE_ID_FULL_DIR_INFORMATION
FILE_ID_FULL_DIR_INFORMATION :: struct {
	NextEntryOffset: ULONG,
	FileIndex:       ULONG,
	CreationTime:    LARGE_INTEGER,
	LastAccessTime:  LARGE_INTEGER,
	LastWriteTime:   LARGE_INTEGER,
	ChangeTime:      LARGE_INTEGER,
	EndOfFile:       LARGE_INTEGER,
	AllocationSize:  LARGE_INTEGER,
	FileAttributes:  ULONG,
	FileNameLength:  ULONG,
	EaSize:          ULONG,
	FileId:          LARGE_INTEGER,
	FileName:        [1]WCHAR,
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