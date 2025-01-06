#+build windows
package sys_windows

foreign import kernel32 "system:Kernel32.lib"
foreign import one_core "system:OneCore.lib"

FOREGROUND_BLUE            :: WORD(0x0001)
FOREGROUND_GREEN           :: WORD(0x0002)
FOREGROUND_RED             :: WORD(0x0004)
FOREGROUND_INTENSITY       :: WORD(0x0008)
BACKGROUND_BLUE            :: WORD(0x0010)
BACKGROUND_GREEN           :: WORD(0x0020)
BACKGROUND_RED             :: WORD(0x0040)
BACKGROUND_INTENSITY       :: WORD(0x0080)
COMMON_LVB_LEADING_BYTE    :: WORD(0x0100)
COMMON_LVB_TRAILING_BYTE   :: WORD(0x0200)
COMMON_LVB_GRID_HORIZONTAL :: WORD(0x0400)
COMMON_LVB_GRID_LVERTICAL  :: WORD(0x0800)
COMMON_LVB_GRID_RVERTICAL  :: WORD(0x1000)
COMMON_LVB_REVERSE_VIDEO   :: WORD(0x4000)
COMMON_LVB_UNDERSCORE      :: WORD(0x8000)
COMMON_LVB_SBCSDBCS        :: WORD(0x0300)
EV_BREAK                   :: DWORD(0x0040)
EV_CTS                     :: DWORD(0x0008)
EV_DSR                     :: DWORD(0x0010)
EV_ERR                     :: DWORD(0x0080)
EV_RING                    :: DWORD(0x0100)
EV_RLSD                    :: DWORD(0x0020)
EV_RXCHAR                  :: DWORD(0x0001)
EV_RXFLAG                  :: DWORD(0x0002)
EV_TXEMPTY                 :: DWORD(0x0004)

@(default_calling_convention="system")
foreign kernel32 {
	OutputDebugStringA :: proc(lpOutputString: LPCSTR) --- // The only A thing that is allowed
	OutputDebugStringW :: proc(lpOutputString: LPCWSTR) ---

	ReadConsoleW :: proc(hConsoleInput: HANDLE,
	                     lpBuffer: LPVOID,
	                     nNumberOfCharsToRead: DWORD,
	                     lpNumberOfCharsRead: LPDWORD,
	                     pInputControl: PCONSOLE_READCONSOLE_CONTROL) -> BOOL ---

	WriteConsoleW :: proc(hConsoleOutput: HANDLE,
	                      lpBuffer: LPCVOID,
	                      nNumberOfCharsToWrite: DWORD,
	                      lpNumberOfCharsWritten: LPDWORD,
	                      lpReserved: LPVOID) -> BOOL ---

	PeekConsoleInputW :: proc(hConsoleInput: HANDLE,
	                          lpBuffer: ^INPUT_RECORD,
	                          nLength: DWORD,
	                          lpNumberOfEventsRead: LPDWORD) -> BOOL ---

	ReadConsoleInputW :: proc(hConsoleInput: HANDLE,
	                          lpBuffer: ^INPUT_RECORD,
	                          nLength: DWORD,
	                          lpNumberOfEventsRead: LPDWORD) -> BOOL ---

	// https://learn.microsoft.com/en-us/windows/console/getnumberofconsoleinputevents
	GetNumberOfConsoleInputEvents :: proc(hConsoleInput: HANDLE, lpcNumberOfEvents: LPDWORD) -> BOOL ---

	GetConsoleMode :: proc(hConsoleHandle: HANDLE, lpMode: LPDWORD) -> BOOL ---
	SetConsoleMode :: proc(hConsoleHandle: HANDLE, dwMode: DWORD) -> BOOL ---
	SetConsoleCursorPosition :: proc(hConsoleHandle: HANDLE, dwCursorPosition: COORD) -> BOOL ---
	SetConsoleTextAttribute :: proc(hConsoleOutput: HANDLE, wAttributes: WORD) -> BOOL ---
	GetConsoleCP :: proc() -> CODEPAGE ---
	SetConsoleCP :: proc(wCodePageID: CODEPAGE) -> BOOL ---
	GetConsoleOutputCP :: proc() -> CODEPAGE ---
	SetConsoleOutputCP :: proc(wCodePageID: CODEPAGE) -> BOOL ---
	FlushConsoleInputBuffer :: proc(hConsoleInput: HANDLE) -> BOOL ---

	GetFileInformationByHandle :: proc(hFile: HANDLE, lpFileInformation: LPBY_HANDLE_FILE_INFORMATION) -> BOOL ---


	SetHandleInformation :: proc(hObject: HANDLE,
	                             dwMask: DWORD,
	                             dwFlags: DWORD) -> BOOL ---
	SetFileInformationByHandle :: proc(hFile:                HANDLE,
	                                   FileInformationClass: FILE_INFO_BY_HANDLE_CLASS,
	                                   lpFileInformation:    LPVOID,
	                                   dwBufferSize:         DWORD) -> BOOL ---


	AddVectoredExceptionHandler :: proc(FirstHandler: ULONG, VectoredHandler: PVECTORED_EXCEPTION_HANDLER) -> LPVOID ---
	AddVectoredContinueHandler  :: proc(FirstHandler: ULONG, VectoredHandler: PVECTORED_EXCEPTION_HANDLER) -> LPVOID ---
	RemoveVectoredExceptionHandler  :: proc(Handle: LPVOID) -> DWORD ---
	RemoveVectoredContinueHandler  :: proc(Handle: LPVOID) -> DWORD ---
	RaiseException :: proc(dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD, lpArguments: ^ULONG_PTR) -> ! ---

	SetUnhandledExceptionFilter :: proc(lpTopLevelExceptionFilter: LPTOP_LEVEL_EXCEPTION_FILTER) -> LPTOP_LEVEL_EXCEPTION_FILTER ---

	CreateHardLinkW :: proc(lpSymlinkFileName: LPCWSTR,
	                        lpTargetFileName: LPCWSTR,
	                        lpSecurityAttributes: LPSECURITY_ATTRIBUTES) -> BOOL ---

	CreateSymbolicLinkW :: proc(lpSymlinkFileName: LPCWSTR,
	                            lpTargetFileName:  LPCWSTR,
	                            dwFlags:           DWORD) -> BOOLEAN ---

	GetFileInformationByHandleEx :: proc(hFile: HANDLE,
	                                     fileInfoClass: FILE_INFO_BY_HANDLE_CLASS,
	                                     lpFileInformation: LPVOID,
	                                     dwBufferSize: DWORD) -> BOOL ---

	InitializeCriticalSection :: proc(CriticalSection: ^CRITICAL_SECTION) ---
	InitializeCriticalSectionAndSpinCount :: proc(CriticalSection: ^CRITICAL_SECTION, dwSpinCount: DWORD) -> BOOL ---
	EnterCriticalSection :: proc(CriticalSection: ^CRITICAL_SECTION) ---
	TryEnterCriticalSection :: proc(CriticalSection: ^CRITICAL_SECTION) -> BOOLEAN ---
	LeaveCriticalSection :: proc(CriticalSection: ^CRITICAL_SECTION) ---
	DeleteCriticalSection :: proc(CriticalSection: ^CRITICAL_SECTION) ---

	RemoveDirectoryW :: proc(lpPathName: LPCWSTR) -> BOOL ---
	SetFileAttributesW :: proc(lpFileName: LPCWSTR, dwFileAttributes: DWORD) -> BOOL ---
	SetLastError :: proc(dwErrCode: DWORD) ---
	GetCommTimeouts :: proc(handle: HANDLE, timeouts: ^COMMTIMEOUTS) -> BOOL ---
	SetCommTimeouts :: proc(handle: HANDLE, timeouts: ^COMMTIMEOUTS) -> BOOL ---
	ClearCommError :: proc(hFile: HANDLE, lpErrors: ^Com_Error, lpStat: ^COMSTAT) -> BOOL ---
	GetCommState :: proc(handle: HANDLE, dcb: ^DCB) -> BOOL ---
	SetCommState :: proc(handle: HANDLE, dcb: ^DCB) -> BOOL ---
	SetCommMask :: proc(handle: HANDLE, dwEvtMap: DWORD) -> BOOL ---
	GetCommMask :: proc(handle: HANDLE, lpEvtMask: LPDWORD) -> BOOL ---
	WaitCommEvent :: proc(handle: HANDLE, lpEvtMask: LPDWORD, lpOverlapped: LPOVERLAPPED) -> BOOL ---
	GetCommandLineW :: proc() -> LPCWSTR ---
	GetTempPathW :: proc(nBufferLength: DWORD, lpBuffer: LPCWSTR) -> DWORD ---
	GetCurrentProcess :: proc() -> HANDLE ---
	GetCurrentProcessId :: proc() -> DWORD ---
	GetCurrentThread :: proc() -> HANDLE ---
	GetCurrentThreadId :: proc() -> DWORD ---
	GetProcessTimes :: proc(
		hProcess: HANDLE,
		lpCreationTime: LPFILETIME,
		lpExitTime: LPFILETIME,
		lpKernelTime: LPFILETIME,
		lpUserTime: LPFILETIME,
	) -> BOOL ---
	GetStdHandle :: proc(which: DWORD) -> HANDLE ---
	ExitProcess :: proc(uExitCode: c_uint) -> ! ---
	DeviceIoControl :: proc(
		hDevice: HANDLE,
		dwIoControlCode: DWORD,
		lpInBuffer: LPVOID,
		nInBufferSize: DWORD,
		lpOutBuffer: LPVOID,
		nOutBufferSize: DWORD,
		lpBytesReturned: LPDWORD,
		lpOverlapped: LPOVERLAPPED,
	) -> BOOL ---
	CreateThread :: proc(
		lpThreadAttributes: LPSECURITY_ATTRIBUTES,
		dwStackSize: SIZE_T,
		lpStartAddress: proc "system" (rawptr) -> DWORD,
		lpParameter: LPVOID,
		dwCreationFlags: DWORD,
		lpThreadId: LPDWORD,
	) -> HANDLE ---
	CreateRemoteThread :: proc(
		hProcess: HANDLE,
		lpThreadAttributes: LPSECURITY_ATTRIBUTES,
		dwStackSize: SIZE_T,
		lpStartAddress: proc "system" (rawptr) -> DWORD,
		lpParameter: LPVOID,
		dwCreationFlags: DWORD,
		lpThreadId: LPDWORD,
	) -> HANDLE ---
	SwitchToThread :: proc() -> BOOL ---
	ResumeThread :: proc(thread: HANDLE) -> DWORD ---
	GetThreadPriority :: proc(thread: HANDLE) -> c_int ---
	SetThreadPriority :: proc(thread: HANDLE, priority: c_int) -> BOOL ---
	SetThreadDescription :: proc(hThread: HANDLE, lpThreadDescription: PCWSTR) -> HRESULT ---
	GetExitCodeThread :: proc(thread: HANDLE, exit_code: ^DWORD) -> BOOL ---
	TerminateThread :: proc(thread: HANDLE, exit_code: DWORD) -> BOOL ---
	SuspendThread :: proc(hThread: HANDLE) -> DWORD ---

	GetProcessAffinityMask :: proc(
		hProcess: HANDLE,
		lpProcessAffinityMask: PDWORD_PTR,
		lpSystemAffinityMask: PDWORD_PTR,
	) -> BOOL ---
	SetProcessAffinityMask :: proc(
		hProcess: HANDLE,
		dwProcessAffinityMask: DWORD_PTR,
	) -> BOOL ---
	SetThreadAffinityMask :: proc(
		hThread: HANDLE,
		dwThreadAffinityMask: DWORD_PTR,
	) -> DWORD_PTR ---

	CreateSemaphoreW :: proc(attributes: LPSECURITY_ATTRIBUTES, initial_count, maximum_count: LONG, name: LPCWSTR) -> HANDLE ---
	ReleaseSemaphore :: proc(semaphore: HANDLE, release_count: LONG, previous_count: ^LONG) -> BOOL ---

	CreateWaitableTimerW :: proc(
		lpTimerAttributes: LPSECURITY_ATTRIBUTES,
		bManualReset: BOOL,
		lpTimerName: LPCWSTR,
	) -> HANDLE ---
	CreateWaitableTimerExW :: proc(
		lpTimerAttributes: LPSECURITY_ATTRIBUTES,
		lpTimerName: LPCWSTR,
		dwFlags: DWORD,
		dwDesiredAccess: DWORD,
	) -> HANDLE ---
	SetWaitableTimerEx :: proc(
		hTimer: HANDLE,
		lpDueTime: ^LARGE_INTEGER,
		lPeriod: LONG,
		pfnCompletionRoutine: PTIMERAPCROUTINE,
		lpArgToCompletionRoutine: LPVOID,
		WakeContext: PREASON_CONTEXT,
		TolerableDelay: ULONG,
	) -> BOOL ---
	WaitForSingleObject :: proc(hHandle: HANDLE, dwMilliseconds: DWORD) -> DWORD ---
	WaitForSingleObjectEx :: proc(hHandle: HANDLE, dwMilliseconds: DWORD, bAlterable: BOOL) -> DWORD ---
	Sleep :: proc(dwMilliseconds: DWORD) ---
	GetProcessId :: proc(handle: HANDLE) -> DWORD ---
	CopyFileW :: proc(
		lpExistingFileName: LPCWSTR,
		lpNewFileName: LPCWSTR,
		bFailIfExists: BOOL,
	) -> BOOL ---
	CopyFileExW :: proc(
		lpExistingFileName: LPCWSTR,
		lpNewFileName: LPCWSTR,
		lpProgressRoutine: LPPROGRESS_ROUTINE,
		lpData: LPVOID,
		pbCancel: LPBOOL,
		dwCopyFlags: DWORD,
	) -> BOOL ---
	FormatMessageW :: proc(
		flags: DWORD,
		lpSrc: LPVOID,
		msgId: DWORD,
		langId: DWORD,
		buf: LPWSTR,
		nsize: DWORD,
		args: rawptr,
	) -> DWORD ---
	TlsAlloc :: proc() -> DWORD ---
	TlsFree :: proc(dwTlsIndex: DWORD) -> BOOL ---
	TlsGetValue :: proc(dwTlsIndex: DWORD) -> LPVOID ---
	TlsSetValue :: proc(dwTlsIndex: DWORD, lpTlsvalue: LPVOID) -> BOOL ---
	GetLastError :: proc() -> DWORD ---
	QueryPerformanceFrequency :: proc(lpFrequency: ^LARGE_INTEGER) -> BOOL ---
	QueryPerformanceCounter :: proc(lpPerformanceCount: ^LARGE_INTEGER) -> BOOL ---
	GetExitCodeProcess :: proc(hProcess: HANDLE, lpExitCode: LPDWORD) -> BOOL ---
	TerminateProcess :: proc(hProcess: HANDLE, uExitCode: UINT) -> BOOL ---
	OpenProcess :: proc(dwDesiredAccess: DWORD, bInheritHandle: BOOL, dwProcessId: DWORD) -> HANDLE ---
	OpenThread :: proc(dwDesiredAccess: DWORD, bInheritHandle: BOOL, dwThreadId: DWORD) -> HANDLE ---
	GetThreadContext :: proc(
		hThread: HANDLE,
		lpContext: LPCONTEXT,
	) -> BOOL ---
	SetThreadContext :: proc(
		hThread: HANDLE,
		lpContext: LPCONTEXT,
	) -> BOOL ---
	CreateProcessW :: proc(
		lpApplicationName: LPCWSTR,
		lpCommandLine: LPWSTR,
		lpProcessAttributes: LPSECURITY_ATTRIBUTES,
		lpThreadAttributes: LPSECURITY_ATTRIBUTES,
		bInheritHandles: BOOL,
		dwCreationFlags: DWORD,
		lpEnvironment: LPVOID,
		lpCurrentDirectory: LPCWSTR,
		lpStartupInfo: LPSTARTUPINFOW,
		lpProcessInformation: LPPROCESS_INFORMATION,
	) -> BOOL ---
	GetStartupInfoW :: proc(lpStartupInfo: LPSTARTUPINFOW) ---
	GetEnvironmentVariableW :: proc(n: LPCWSTR, v: LPWSTR, nsize: DWORD) -> DWORD ---
	SetEnvironmentVariableW :: proc(n: LPCWSTR, v: LPCWSTR) -> BOOL ---
	GetEnvironmentStringsW :: proc() -> LPWCH ---
	FreeEnvironmentStringsW :: proc(env_ptr: LPWCH) -> BOOL ---
	ExpandEnvironmentStringsW :: proc(lpSrc: LPCWSTR, lpDst: LPWSTR, nSize: DWORD) -> DWORD ---
	GetModuleFileNameW :: proc(hModule: HMODULE, lpFilename: LPWSTR, nSize: DWORD) -> DWORD ---
	CreateDirectoryW :: proc(
		lpPathName: LPCWSTR,
		lpSecurityAttributes: LPSECURITY_ATTRIBUTES,
	) -> BOOL ---
	DeleteFileW :: proc(lpPathName: LPCWSTR) -> BOOL ---
	GetCurrentDirectoryW :: proc(nBufferLength: DWORD, lpBuffer: LPWSTR) -> DWORD ---
	SetCurrentDirectoryW :: proc(lpPathName: LPCWSTR) -> BOOL ---
	WideCharToMultiByte :: proc(
		CodePage: UINT,
		dwFlags: DWORD,
		lpWideCharStr: LPCWSTR,
		cchWideChar: c_int,
		lpMultiByteStr: LPSTR,
		cbMultiByte: c_int,
		lpDefaultChar: LPCSTR,
		lpUsedDefaultChar: LPBOOL,
	) -> c_int ---
	MultiByteToWideChar :: proc(
		CodePage: UINT,
		dwFlags: DWORD,
		lpMultiByteStr: LPSTR,
		cbMultiByte: c_int,
		lpWideCharStr: LPWSTR,
		cchWideChar: c_int,
	) -> c_int ---
	DuplicateHandle :: proc(
		hSourceProcessHandle: HANDLE,
		hSourceHandle: HANDLE,
		hTargetProcessHandle: HANDLE,
		lpTargetHandle: LPHANDLE,
		dwDesiredAccess: DWORD,
		bInheritHandle: BOOL,
		dwOptions: DWORD,
	) -> BOOL ---
	ReadFile :: proc(
		hFile: HANDLE,
		lpBuffer: LPVOID,
		nNumberOfBytesToRead: DWORD,
		lpNumberOfBytesRead: LPDWORD,
		lpOverlapped: LPOVERLAPPED,
	) -> BOOL ---
	WriteFile :: proc(
		hFile: HANDLE,
		lpBuffer: LPVOID,
		nNumberOfBytesToWrite: DWORD,
		lpNumberOfBytesWritten: LPDWORD,
		lpOverlapped: LPOVERLAPPED,
	) -> BOOL ---
	CloseHandle :: proc(hObject: HANDLE) -> BOOL ---
	MoveFileExW :: proc(lpExistingFileName: LPCWSTR, lpNewFileName: LPCWSTR, dwFlags: DWORD) -> BOOL ---
	SetFilePointerEx :: proc(
		hFile: HANDLE,
		liDistanceToMove: LARGE_INTEGER,
		lpNewFilePointer: PLARGE_INTEGER,
		dwMoveMethod: DWORD,
	) -> BOOL ---
	FlushFileBuffers :: proc(hFile: HANDLE) -> BOOL ---
	CreateFileW :: proc(
		lpFileName: LPCWSTR,
		dwDesiredAccess: DWORD,
		dwShareMode: DWORD,
		lpSecurityAttributes: LPSECURITY_ATTRIBUTES,
		dwCreationDisposition: DWORD,
		dwFlagsAndAttributes: DWORD,
		hTemplateFile: HANDLE,
	) -> HANDLE ---

	GetFileTime :: proc(
		hFile: HANDLE,
		lpCreationTime: LPFILETIME,
		lpLastAccessTime: LPFILETIME,
		lpLastWriteTime: LPFILETIME,
	) -> BOOL ---
	CompareFileTime :: proc(lpFileTime1: LPFILETIME, lpFileTime2: LPFILETIME) -> LONG ---

	FindFirstFileW :: proc(fileName: LPCWSTR, findFileData: LPWIN32_FIND_DATAW) -> HANDLE ---
	FindNextFileW :: proc(findFile: HANDLE, findFileData: LPWIN32_FIND_DATAW) -> BOOL ---
	FindClose :: proc(findFile: HANDLE) -> BOOL ---
	GetModuleHandleW :: proc(lpModuleName: LPCWSTR) -> HMODULE ---
	GetModuleHandleA :: proc(lpModuleName: LPCSTR) -> HMODULE ---
	GetSystemTimeAsFileTime :: proc(lpSystemTimeAsFileTime: LPFILETIME) ---
	GetSystemTimePreciseAsFileTime :: proc(lpSystemTimeAsFileTime: LPFILETIME) ---
	FileTimeToSystemTime :: proc(lpFileTime: ^FILETIME, lpSystemTime: ^SYSTEMTIME) -> BOOL ---
	SystemTimeToTzSpecificLocalTime :: proc(
		lpTimeZoneInformation: ^TIME_ZONE_INFORMATION,
		lpUniversalTime: ^SYSTEMTIME,
		lpLocalTime: ^SYSTEMTIME,
	) -> BOOL ---
	SystemTimeToFileTime :: proc(
		lpSystemTime: ^SYSTEMTIME,
		lpFileTime: LPFILETIME,
	) -> BOOL ---
	CreateEventW :: proc(
		lpEventAttributes: LPSECURITY_ATTRIBUTES,
		bManualReset: BOOL,
		bInitialState: BOOL,
		lpName: LPCWSTR,
	) -> HANDLE ---
	ResetEvent :: proc(hEvent: HANDLE) -> BOOL ---
	SetEvent :: proc(hEvent: HANDLE) -> BOOL ---
	WaitForMultipleObjects :: proc(
		nCount: DWORD,
		lpHandles: ^HANDLE,
		bWaitAll: BOOL,
		dwMilliseconds: DWORD,
	) -> DWORD ---
	WaitForMultipleObjectsEx :: proc(
		nCount: DWORD,
		lpHandles: ^HANDLE,
		bWaitAll: BOOL,
		dwMilliseconds: DWORD,
		bAlterable: BOOL,
	) -> DWORD ---
	CreateNamedPipeW :: proc(
		lpName: LPCWSTR,
		dwOpenMode: DWORD,
		dwPipeMode: DWORD,
		nMaxInstances: DWORD,
		nOutBufferSize: DWORD,
		nInBufferSize: DWORD,
		nDefaultTimeOut: DWORD,
		lpSecurityAttributes: LPSECURITY_ATTRIBUTES,
	) -> HANDLE ---
	PeekNamedPipe :: proc(
		hNamedPipe: HANDLE,
		lpBuffer: rawptr,
		nBufferSize: u32,
		lpBytesRead: ^u32,
		lpTotalBytesAvail: ^u32,
		lpBytesLeftThisMessage: ^u32,
	) -> BOOL ---
	CancelIo :: proc(handle: HANDLE) -> BOOL ---
	GetOverlappedResult :: proc(
		hFile: HANDLE,
		lpOverlapped: LPOVERLAPPED,
		lpNumberOfBytesTransferred: LPDWORD,
		bWait: BOOL,
	) -> BOOL ---
	GetProcessHeap :: proc() -> HANDLE ---
	HeapAlloc :: proc(hHeap: HANDLE, dwFlags: DWORD, dwBytes: SIZE_T) -> LPVOID ---
	HeapReAlloc :: proc(hHeap: HANDLE, dwFlags: DWORD, lpMem: LPVOID, dwBytes: SIZE_T) -> LPVOID ---
	HeapFree :: proc(hHeap: HANDLE, dwFlags: DWORD, lpMem: LPVOID) -> BOOL ---

	LocalAlloc :: proc(flags: UINT, bytes: SIZE_T) -> LPVOID ---
	LocalReAlloc :: proc(mem: LPVOID, bytes: SIZE_T, flags: UINT) -> LPVOID ---
	LocalFree :: proc(mem: LPVOID) -> LPVOID ---

	GlobalAlloc :: proc(flags: UINT, bytes: SIZE_T) -> LPVOID ---
	GlobalReAlloc :: proc(mem: LPVOID, bytes: SIZE_T, flags: UINT) -> LPVOID ---
	GlobalFree :: proc(mem: LPVOID) -> LPVOID ---
	
	GlobalLock :: proc(hMem: HGLOBAL) -> LPVOID ---
	GlobalUnlock :: proc(hMem: HGLOBAL) -> BOOL ---

	ReadDirectoryChangesW :: proc(
		hDirectory: HANDLE,
		lpBuffer: LPVOID,
		nBufferLength: DWORD,
		bWatchSubtree: BOOL,
		dwNotifyFilter: DWORD,
		lpBytesReturned: LPDWORD,
		lpOverlapped: LPOVERLAPPED,
		lpCompletionRoutine: LPOVERLAPPED_COMPLETION_ROUTINE,
	) -> BOOL ---
	FindFirstChangeNotificationW :: proc(
		lpPathName: LPWSTR,
		bWatchSubtree: BOOL,
		dwNotifyFilter: DWORD,
	) -> HANDLE ---
	FindNextChangeNotification :: proc(hChangeHandle: HANDLE) -> BOOL ---
	FindCloseChangeNotification :: proc(hChangeHandle: HANDLE) -> BOOL ---

	InitializeSRWLock          :: proc(SRWLock: ^SRWLOCK) ---
	AcquireSRWLockExclusive    :: proc(SRWLock: ^SRWLOCK) ---
	TryAcquireSRWLockExclusive :: proc(SRWLock: ^SRWLOCK) -> BOOLEAN ---
	ReleaseSRWLockExclusive    :: proc(SRWLock: ^SRWLOCK) ---
	AcquireSRWLockShared    :: proc(SRWLock: ^SRWLOCK) ---
	TryAcquireSRWLockShared :: proc(SRWLock: ^SRWLOCK) -> BOOLEAN ---
	ReleaseSRWLockShared    :: proc(SRWLock: ^SRWLOCK) ---

	InitializeConditionVariable :: proc(ConditionVariable: ^CONDITION_VARIABLE) ---
	WakeConditionVariable       :: proc(ConditionVariable: ^CONDITION_VARIABLE) ---
	WakeAllConditionVariable    :: proc(ConditionVariable: ^CONDITION_VARIABLE) ---
	SleepConditionVariableCS    :: proc(ConditionVariable: ^CONDITION_VARIABLE, CriticalSection: ^CRITICAL_SECTION, dwMilliseconds: DWORD) -> BOOL ---
	SleepConditionVariableSRW   :: proc(ConditionVariable: ^CONDITION_VARIABLE, SRWLock: ^SRWLOCK, dwMilliseconds: DWORD, Flags: LONG) -> BOOL ---


	GetFileType :: proc(file_handle: HANDLE) -> DWORD ---
	SetFilePointer :: proc(file_handle: HANDLE, distance_to_move: LONG, distance_to_move_high: ^LONG, move_method: DWORD) -> DWORD ---
	GetFileSizeEx :: proc(file_handle: HANDLE, file_size: ^LARGE_INTEGER) -> BOOL ---
	GetFileAttributesW   :: proc(lpFileName: LPCWSTR) -> DWORD ---
	GetFileAttributesExW :: proc(lpFileName: LPCWSTR, fInfoLevelId: GET_FILEEX_INFO_LEVELS, lpFileInformation: LPVOID) -> BOOL ---
	GetSystemInfo :: proc(system_info: ^SYSTEM_INFO) ---
	GetVersionExW :: proc(osvi: ^OSVERSIONINFOEXW) ---
	GetSystemDirectoryW :: proc(lpBuffer: LPWSTR, uSize: UINT) -> UINT ---
	GetWindowsDirectoryW :: proc(lpBuffer: LPWSTR, uSize: UINT) -> UINT ---
	GetSystemDefaultLangID :: proc() -> LANGID ---
	GetSystemDefaultLCID :: proc() -> LCID ---
	GetSystemDefaultLocaleName :: proc(lpLocaleName: LPWSTR, cchLocaleName: INT) -> INT ---
	LCIDToLocaleName :: proc(Locale: LCID, lpName: LPWSTR, cchName: INT, dwFlags: DWORD) -> INT ---
	LocaleNameToLCID :: proc(lpName: LPCWSTR, dwFlags: DWORD) -> LCID ---
	SetDllDirectoryW :: proc(lpPathName: LPCWSTR) -> BOOL ---
	AddDllDirectory :: proc(NewDirectory: PCWSTR) -> rawptr ---
	RemoveDllDirectory :: proc(Cookie: rawptr) -> BOOL ---
	LoadLibraryW :: proc(c_str: LPCWSTR) -> HMODULE ---
	LoadLibraryExW :: proc(c_str: LPCWSTR, hFile: HANDLE, dwFlags: LoadLibraryEx_Flags) -> HMODULE ---
	FreeLibrary :: proc(h: HMODULE) -> BOOL ---
	GetProcAddress :: proc(h: HMODULE, c_str: LPCSTR) -> rawptr ---

	LoadResource :: proc(hModule: HMODULE, hResInfo: HRSRC) -> HGLOBAL ---
	FreeResource :: proc(hResData: HGLOBAL) -> BOOL ---
	LockResource :: proc(hResData: HGLOBAL) -> LPVOID ---
	SizeofResource :: proc(hModule: HMODULE, hResInfo: HRSRC) -> DWORD ---
	FindResourceW :: proc(hModule: HMODULE, lpName: LPCWSTR, lpType: LPCWSTR) -> HRSRC ---
	FindResourceExW :: proc(hModule: HMODULE, lpType: LPCWSTR, lpName: LPCWSTR, wLanguage: LANGID) -> HRSRC ---
	EnumResourceNamesW :: proc(hModule: HMODULE, lpType: LPCWSTR, lpEnumFunc: ENUMRESNAMEPROCW, lParam: LONG_PTR) -> BOOL ---
	EnumResourceNamesExW :: proc(hModule: HMODULE, lpType: LPCWSTR, lpEnumFunc: ENUMRESNAMEPROCW, lParam: LONG_PTR, dwFlags: DWORD, LangId: LANGID) -> BOOL ---
	EnumResourceTypesExW :: proc(hModule: HMODULE, lpEnumFunc: ENUMRESTYPEPROCW, lParam: LONG_PTR, dwFlags: DWORD, LangId: LANGID) -> BOOL ---
	EnumResourceLanguagesExW :: proc(hModule: HMODULE, lpType: LPCWSTR, lpName: LPCWSTR, lpEnumFunc: ENUMRESLANGPROCW, lParam: LONG_PTR, dwFlags: DWORD, LangId: LANGID) -> BOOL ---
	LookupIconIdFromDirectory :: proc(presbits: PBYTE, fIcon: BOOL) -> INT ---
	LookupIconIdFromDirectoryEx :: proc(presbits: PBYTE, fIcon: BOOL, cxDesired: INT, cyDesired: INT, Flags: UINT) -> INT ---
	CreateIconFromResourceEx :: proc(presbits: PBYTE, dwResSize: DWORD, fIcon: BOOL, dwVer: DWORD, cxDesired: INT, cyDesired: INT, Flags: UINT) -> HICON ---

	GetFullPathNameW  :: proc(filename: LPCWSTR, buffer_length: DWORD, buffer: LPCWSTR, file_part: ^LPCWSTR) -> DWORD ---
	GetLongPathNameW  :: proc(short, long: LPCWSTR, len: DWORD) -> DWORD ---
	GetShortPathNameW :: proc(long, short: LPCWSTR, len: DWORD) -> DWORD ---

	GetFinalPathNameByHandleW :: proc(hFile: HANDLE, lpszFilePath: LPCWSTR, cchFilePath: DWORD, dwFlags: DWORD) -> DWORD ---


	SetEndOfFile :: proc(hFile: HANDLE) -> BOOL ---

	CreatePipe :: proc(hReadPipe, hWritePipe: ^HANDLE, lpPipeAttributes: LPSECURITY_ATTRIBUTES, nSize: DWORD) -> BOOL ---

	ConnectNamedPipe :: proc(hNamedPipe: HANDLE, lpOverlapped: LPOVERLAPPED) -> BOOL ---
	DisconnectNamedPipe :: proc(hNamedPipe: HANDLE) -> BOOL ---
	WaitNamedPipeW :: proc(lpNamedPipeName: LPCWSTR, nTimeOut: DWORD) -> BOOL ---

	AllocConsole :: proc() -> BOOL ---
	AttachConsole :: proc(dwProcessId: DWORD) -> BOOL ---
	SetConsoleCtrlHandler :: proc(HandlerRoutine: PHANDLER_ROUTINE, Add: BOOL) -> BOOL ---
	GenerateConsoleCtrlEvent :: proc(dwCtrlEvent: DWORD, dwProcessGroupId: DWORD) -> BOOL ---
	FreeConsole :: proc() -> BOOL ---
	GetConsoleWindow :: proc() -> HWND ---
	GetConsoleScreenBufferInfo :: proc(hConsoleOutput: HANDLE, lpConsoleScreenBufferInfo: PCONSOLE_SCREEN_BUFFER_INFO) -> BOOL ---
	SetConsoleScreenBufferSize :: proc(hConsoleOutput: HANDLE, dwSize: COORD) -> BOOL ---
	SetConsoleWindowInfo :: proc(hConsoleOutput: HANDLE, bAbsolute: BOOL, lpConsoleWindow: ^SMALL_RECT) -> BOOL ---
	GetConsoleCursorInfo :: proc(hConsoleOutput: HANDLE, lpConsoleCursorInfo: PCONSOLE_CURSOR_INFO) -> BOOL ---
	SetConsoleCursorInfo :: proc(hConsoleOutput: HANDLE, lpConsoleCursorInfo: PCONSOLE_CURSOR_INFO) -> BOOL ---

	GetDiskFreeSpaceExW :: proc(
		lpDirectoryName: LPCWSTR,
		lpFreeBytesAvailableToCaller: PULARGE_INTEGER,
		lpTotalNumberOfBytes: PULARGE_INTEGER,
		lpTotalNumberOfFreeBytes: PULARGE_INTEGER,
	) -> BOOL ---

	GetLogicalProcessorInformation :: proc(buffer: ^SYSTEM_LOGICAL_PROCESSOR_INFORMATION, returnedLength: PDWORD) -> BOOL ---

	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setfilecompletionnotificationmodes)
	SetFileCompletionNotificationModes :: proc(FileHandle: HANDLE, Flags: u8) -> BOOL ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/ioapiset/nf-ioapiset-createiocompletionport)
	CreateIoCompletionPort :: proc(FileHandle: HANDLE, ExistingCompletionPort: HANDLE, CompletionKey: ULONG_PTR, NumberOfConcurrentThreads: DWORD) -> HANDLE ---
	//[MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/ioapiset/nf-ioapiset-getqueuedcompletionstatus)
	GetQueuedCompletionStatus :: proc(CompletionPort: HANDLE, lpNumberOfBytesTransferred: ^DWORD, lpCompletionKey: PULONG_PTR, lpOverlapped: ^^OVERLAPPED, dwMilliseconds: DWORD) -> BOOL ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/ioapiset/nf-ioapiset-getqueuedcompletionstatusex)
	GetQueuedCompletionStatusEx :: proc(CompletionPort: HANDLE, lpCompletionPortEntries: ^OVERLAPPED_ENTRY, ulCount: c_ulong, ulNumEntriesRemoved: ^c_ulong, dwMilliseconds: DWORD, fAlertable: BOOL) -> BOOL ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/ioapiset/nf-ioapiset-postqueuedcompletionstatus)
	PostQueuedCompletionStatus :: proc(CompletionPort: HANDLE, dwNumberOfBytesTransferred: DWORD, dwCompletionKey: c_ulong, lpOverlapped: ^OVERLAPPED) -> BOOL ---
	// [MS-Docs](https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-gethandleinformation)
	GetHandleInformation :: proc(hObject: HANDLE, lpdwFlags: ^DWORD) -> BOOL ---

	RtlCaptureStackBackTrace :: proc(FramesToSkip: ULONG, FramesToCapture: ULONG, BackTrace: [^]PVOID, BackTraceHash: PULONG) -> USHORT ---

	GetSystemPowerStatus :: proc(lpSystemPowerStatus: ^SYSTEM_POWER_STATUS) -> BOOL ---
}

DEBUG_PROCESS                    :: 0x00000001
DEBUG_ONLY_THIS_PROCESS          :: 0x00000002
CREATE_SUSPENDED                 :: 0x00000004
DETACHED_PROCESS                 :: 0x00000008
CREATE_NEW_CONSOLE               :: 0x00000010
NORMAL_PRIORITY_CLASS            :: 0x00000020
IDLE_PRIORITY_CLASS              :: 0x00000040
HIGH_PRIORITY_CLASS              :: 0x00000080
REALTIME_PRIORITY_CLASS          :: 0x00000100
CREATE_NEW_PROCESS_GROUP         :: 0x00000200
CREATE_UNICODE_ENVIRONMENT       :: 0x00000400
CREATE_SEPARATE_WOW_VDM          :: 0x00000800
CREATE_SHARED_WOW_VDM            :: 0x00001000
CREATE_FORCEDOS                  :: 0x00002000
BELOW_NORMAL_PRIORITY_CLASS      :: 0x00004000
ABOVE_NORMAL_PRIORITY_CLASS      :: 0x00008000
INHERIT_PARENT_AFFINITY          :: 0x00010000
INHERIT_CALLER_PRIORITY          :: 0x00020000    // Deprecated
CREATE_PROTECTED_PROCESS         :: 0x00040000
EXTENDED_STARTUPINFO_PRESENT     :: 0x00080000
PROCESS_MODE_BACKGROUND_BEGIN    :: 0x00100000
PROCESS_MODE_BACKGROUND_END      :: 0x00200000
CREATE_SECURE_PROCESS            :: 0x00400000
CREATE_BREAKAWAY_FROM_JOB        :: 0x01000000
CREATE_PRESERVE_CODE_AUTHZ_LEVEL :: 0x02000000
CREATE_DEFAULT_ERROR_MODE        :: 0x04000000
CREATE_NO_WINDOW                 :: 0x08000000
PROFILE_USER                     :: 0x10000000
PROFILE_KERNEL                   :: 0x20000000
PROFILE_SERVER                   :: 0x40000000
CREATE_IGNORE_SYSTEM_DEFAULT     :: 0x80000000

THREAD_BASE_PRIORITY_LOWRT :: 15    // value that gets a thread to LowRealtime-1
THREAD_BASE_PRIORITY_MAX   :: 2     // maximum thread base priority boost
THREAD_BASE_PRIORITY_MIN   :: (-2)  // minimum thread base priority boost
THREAD_BASE_PRIORITY_IDLE  :: (-15) // value that gets a thread to idle

THREAD_PRIORITY_LOWEST        :: THREAD_BASE_PRIORITY_MIN
THREAD_PRIORITY_BELOW_NORMAL  :: (THREAD_PRIORITY_LOWEST+1)
THREAD_PRIORITY_NORMAL        :: 0
THREAD_PRIORITY_HIGHEST       :: THREAD_BASE_PRIORITY_MAX
THREAD_PRIORITY_ABOVE_NORMAL  :: (THREAD_PRIORITY_HIGHEST-1)
THREAD_PRIORITY_ERROR_RETURN  :: (MAXLONG)
THREAD_PRIORITY_TIME_CRITICAL :: THREAD_BASE_PRIORITY_LOWRT
THREAD_PRIORITY_IDLE          :: THREAD_BASE_PRIORITY_IDLE
THREAD_MODE_BACKGROUND_BEGIN  :: 0x00010000
THREAD_MODE_BACKGROUND_END    :: 0x00020000

PROCESS_ALL_ACCESS :: 0x000F0000 | SYNCHRONIZE | 0xFFFF
PROCESS_CREATE_PROCESS :: 0x0080
PROCESS_CREATE_THREAD :: 0x0002
PROCESS_DUP_HANDLE :: 0x0040
PROCESS_QUERY_INFORMATION :: 0x0400
PROCESS_QUERY_LIMITED_INFORMATION :: 0x1000
PROCESS_SET_INFORMATION :: 0x0200
PROCESS_SET_QUOTA :: 0x0100
PROCESS_SUSPEND_RESUME :: 0x0800
PROCESS_TERMINATE :: 0x0001
PROCESS_VM_OPERATION :: 0x0008
PROCESS_VM_READ :: 0x0010
PROCESS_VM_WRITE :: 0x0020

THREAD_ALL_ACCESS :: \
	THREAD_DIRECT_IMPERSONATION |
	THREAD_GET_CONTEXT |
	THREAD_IMPERSONATE |
	THREAD_QUERY_INFORMATION |
	THREAD_QUERY_LIMITED_INFORMATION |
	THREAD_SET_CONTEXT |
	THREAD_SET_INFORMATION |
	THREAD_SET_LIMITED_INFORMATION |
	THREAD_SET_THREAD_TOKEN |
	THREAD_SUSPEND_RESUME |
	THREAD_TERMINATE |
	SYNCHRONIZE
THREAD_DIRECT_IMPERSONATION :: 0x0200
THREAD_GET_CONTEXT :: 0x0008
THREAD_IMPERSONATE :: 0x0100
THREAD_QUERY_INFORMATION :: 0x0040
THREAD_QUERY_LIMITED_INFORMATION :: 0x0800
THREAD_SET_CONTEXT :: 0x0010
THREAD_SET_INFORMATION :: 0x0020
THREAD_SET_LIMITED_INFORMATION :: 0x0400
THREAD_SET_THREAD_TOKEN :: 0x0080
THREAD_SUSPEND_RESUME :: 0x0002
THREAD_TERMINATE :: 0x0001

COPY_FILE_FAIL_IF_EXISTS              :: 0x00000001
COPY_FILE_RESTARTABLE                 :: 0x00000002
COPY_FILE_OPEN_SOURCE_FOR_WRITE       :: 0x00000004
COPY_FILE_ALLOW_DECRYPTED_DESTINATION :: 0x00000008
COPY_FILE_COPY_SYMLINK                :: 0x00000800
COPY_FILE_NO_BUFFERING                :: 0x00001000
COPY_FILE_REQUEST_SECURITY_PRIVILEGES :: 0x00002000
COPY_FILE_RESUME_FROM_PAUSE           :: 0x00004000
COPY_FILE_NO_OFFLOAD                  :: 0x00040000
COPY_FILE_IGNORE_EDP_BLOCK            :: 0x00400000
COPY_FILE_IGNORE_SOURCE_ENCRYPTION    :: 0x00800000
COPY_FILE_DONT_REQUEST_DEST_WRITE_DAC :: 0x02000000
COPY_FILE_REQUEST_COMPRESSED_TRAFFIC  :: 0x10000000
COPY_FILE_OPEN_AND_COPY_REPARSE_POINT :: 0x00200000
COPY_FILE_DIRECTORY                   :: 0x00000080
COPY_FILE_SKIP_ALTERNATE_STREAMS      :: 0x00008000
COPY_FILE_DISABLE_PRE_ALLOCATION      :: 0x04000000
COPY_FILE_ENABLE_LOW_FREE_SPACE_MODE  :: 0x08000000

SECTION_QUERY                :: DWORD(0x0001)
SECTION_MAP_WRITE            :: DWORD(0x0002)
SECTION_MAP_READ             :: DWORD(0x0004)
SECTION_MAP_EXECUTE          :: DWORD(0x0008)
SECTION_EXTEND_SIZE          :: DWORD(0x0010)
SECTION_ALL_ACCESS           :: STANDARD_RIGHTS_REQUIRED | SECTION_QUERY | SECTION_MAP_WRITE | SECTION_MAP_READ | SECTION_MAP_EXECUTE | SECTION_EXTEND_SIZE
SECTION_MAP_EXECUTE_EXPLICIT :: DWORD(0x0020)

FILE_MAP_WRITE           :: SECTION_MAP_WRITE
FILE_MAP_READ            :: SECTION_MAP_READ
FILE_MAP_ALL_ACCESS      :: SECTION_ALL_ACCESS
FILE_MAP_EXECUTE         :: SECTION_MAP_EXECUTE_EXPLICIT
FILE_MAP_COPY            :: DWORD(0x00000001)
FILE_MAP_RESERVE         :: DWORD(0x80000000)
FILE_MAP_TARGETS_INVALID :: DWORD(0x40000000)
FILE_MAP_LARGE_PAGES     :: DWORD(0x20000000)

// Flags for `SetFileCompletionNotificationModes`.
FILE_SKIP_COMPLETION_PORT_ON_SUCCESS :: 0x1
FILE_SKIP_SET_EVENT_ON_HANDLE        :: 0x2

PAGE_NOACCESS          :: 0x01
PAGE_READONLY          :: 0x02
PAGE_READWRITE         :: 0x04
PAGE_WRITECOPY         :: 0x08
PAGE_EXECUTE           :: 0x10
PAGE_EXECUTE_READ      :: 0x20
PAGE_EXECUTE_READWRITE :: 0x40
PAGE_EXECUTE_WRITECOPY :: 0x80
PAGE_GUARD             :: 0x100
PAGE_NOCACHE           :: 0x200
PAGE_WRITECOMBINE      :: 0x400

MEMORY_BASIC_INFORMATION :: struct {
	BaseAddress: PVOID,
	AllocationBase: PVOID,
	AllocationProtect: DWORD,
	PartitionId: WORD,
	RegionSize: SIZE_T,
	State: DWORD,
	Protect: DWORD,
	Type: DWORD,
}
PMEMORY_BASIC_INFORMATION :: ^MEMORY_BASIC_INFORMATION
LPMEMORY_BASIC_INFORMATION :: ^MEMORY_BASIC_INFORMATION

MEM_COMMIT      :: 0x1000
MEM_RESERVE     :: 0x2000
MEM_DECOMMIT    :: 0x4000
MEM_RELEASE     :: 0x8000
MEM_FREE        :: 0x10000
MEM_PRIVATE     :: 0x20000
MEM_MAPPED      :: 0x40000
MEM_RESET       :: 0x80000
MEM_TOP_DOWN    :: 0x100000
MEM_LARGE_PAGES :: 0x20000000
MEM_4MB_PAGES   :: 0x80000000

@(default_calling_convention="system")
foreign kernel32 {
	VirtualAlloc :: proc(
		lpAddress: LPVOID,
		dwSize: SIZE_T,
		flAllocationType: DWORD,
		flProtect: DWORD,
	) -> LPVOID ---
	VirtualProtect :: proc(
		lpAddress: LPVOID,
		dwSize: SIZE_T,
		flNewProtect: DWORD,
		lpflOldProtect: PDWORD,
	) -> BOOL ---
	VirtualFree :: proc(
		lpAddress: LPVOID,
		dwSize: SIZE_T,
		dwFreeType: DWORD,
	) -> BOOL ---
	VirtualQuery :: proc(
		lpAddress: LPCVOID,
		lpBuffer: PMEMORY_BASIC_INFORMATION,
		dwLength: SIZE_T,
	) -> SIZE_T ---
	VirtualAllocEx :: proc(
		hProcess: HANDLE,
		lpAddress: LPVOID,
		dwSize: SIZE_T,
		flAllocationType: DWORD,
		flProtect: DWORD,
	) -> LPVOID ---
	VirtualFreeEx :: proc(
		hProcess: HANDLE,
		lpAddress: LPVOID,
		dwSize: SIZE_T,
		dwFreeType: DWORD,
	) -> BOOL ---
	VirtualProtectEx :: proc(
		hProcess: HANDLE,
		lpAddress: LPVOID,
		dwSize: SIZE_T,
		flNewProtect: DWORD,
		lpflOldProtect: PDWORD,
	) -> BOOL ---
	VirtualQueryEx :: proc(
		hProcess: HANDLE,
		lpAddress: LPCVOID,
		lpBuffer: PMEMORY_BASIC_INFORMATION,
		dwLength: SIZE_T,
	) -> SIZE_T ---
	ReadProcessMemory :: proc(
		hProcess: HANDLE,
		lpBaseAddress: LPCVOID,
		lpBuffer: LPVOID,
		nSize: SIZE_T,
		lpNumberOfBytesRead: ^SIZE_T,
	) -> BOOL ---
	WriteProcessMemory :: proc(
		hProcess: HANDLE,
		lpBaseAddress: LPVOID,
		lpBuffer: LPCVOID,
		nSize: SIZE_T,
		lpNumberOfBytesWritten: ^SIZE_T,
	) -> BOOL ---
	CreateFileMappingW :: proc(
		hFile: HANDLE,
		lpFileMappingAttributes: LPSECURITY_ATTRIBUTES,
		flProtect: DWORD,
		dwMaximumSizeHigh: DWORD,
		dwMaximumSizeLow: DWORD,
		lpName: LPCWSTR,
	) -> HANDLE ---
	OpenFileMappingW :: proc(
		dwDesiredAccess: DWORD,
		bInheritHandle: BOOL,
		lpName: LPCWSTR,
	) -> HANDLE ---
	MapViewOfFile :: proc(
		hFileMappingObject: HANDLE,
		dwDesiredAccess: DWORD,
		dwFileOffsetHigh: DWORD,
		dwFileOffsetLow: DWORD,
		dwNumberOfBytesToMap: SIZE_T,
	) -> LPVOID ---
	MapViewOfFileEx :: proc(
		hFileMappingObject: HANDLE,
		dwDesiredAccess: DWORD,
		dwFileOffsetHigh: DWORD,
		dwFileOffsetLow: DWORD,
		dwNumberOfBytesToMap: SIZE_T,
		lpBaseAddress: LPVOID,
	) -> LPVOID ---
	FlushViewOfFile :: proc(
		lpBaseAddress: LPCVOID,
		dwNumberOfBytesToFlush: SIZE_T,
	) -> BOOL ---
	UnmapViewOfFile :: proc(
		lpBaseAddress: LPCVOID,
	) -> BOOL ---
	GetLargePageMinimum :: proc() -> SIZE_T ---
	GetProcessWorkingSetSizeEx :: proc(
		hProcess: HANDLE,
		lpMinimumWorkingSetSize: PSIZE_T,
		lpMaximumWorkingSetSize: PSIZE_T,
		Flags: PDWORD,
	) -> BOOL ---
	SetProcessWorkingSetSizeEx :: proc(
		hProcess: HANDLE,
		dwMinimumWorkingSetSize: SIZE_T,
		dwMaximumWorkingSetSize: SIZE_T,
		Flags: DWORD,
	) -> BOOL ---
	VirtualLock :: proc(
		lpAddress: LPVOID,
		dwSize: SIZE_T,
	) -> BOOL ---
	VirtualUnlock :: proc(
		lpAddress: LPVOID,
		dwSize: SIZE_T,
	) -> BOOL ---
	GetWriteWatch :: proc(
		dwFlags: DWORD,
		lpBaseAddress: PVOID,
		dwRegionSize: SIZE_T,
		lpAddresses: ^PVOID,
		lpdwCount: ^ULONG_PTR,
		lpdwGranularity: LPDWORD,
	) -> UINT ---
	ResetWriteWatch :: proc(
		lpBaseAddress: LPVOID,
		dwRegionSize: SIZE_T,
	) -> UINT ---
}


MEMORY_RESOURCE_NOTIFICATION_TYPE :: enum c_int {
	LowMemoryResourceNotification,
	HighMemoryResourceNotification,
}
LowMemoryResourceNotification  :: MEMORY_RESOURCE_NOTIFICATION_TYPE.LowMemoryResourceNotification
HighMemoryResourceNotification :: MEMORY_RESOURCE_NOTIFICATION_TYPE.HighMemoryResourceNotification


@(default_calling_convention="system")
foreign kernel32 {
	CreateMemoryResourceNotification :: proc(
		NotificationType: MEMORY_RESOURCE_NOTIFICATION_TYPE,
	) -> HANDLE ---
	QueryMemoryResourceNotification :: proc(
		ResourceNotificationHandle: HANDLE,
		ResourceState: PBOOL,
	) -> BOOL ---
}

FILE_CACHE_MAX_HARD_ENABLE  :: DWORD(0x00000001)
FILE_CACHE_MAX_HARD_DISABLE :: DWORD(0x00000002)
FILE_CACHE_MIN_HARD_ENABLE  :: DWORD(0x00000004)
FILE_CACHE_MIN_HARD_DISABLE :: DWORD(0x00000008)

@(default_calling_convention="system")
foreign kernel32 {
	GetSystemFileCacheSize :: proc(
		lpMinimumFileCacheSize: PSIZE_T,
		lpMaximumFileCacheSize: PSIZE_T,
		lpFlags: PDWORD,
	) -> BOOL ---
	SetSystemFileCacheSize :: proc(
		MinimumFileCacheSize: SIZE_T,
		MaximumFileCacheSize: SIZE_T,
		Flags: DWORD,
	) -> BOOL ---
	CreateFileMappingNumaW :: proc(
		hFile: HANDLE,
		lpFileMappingAttributes: LPSECURITY_ATTRIBUTES,
		flProtect: DWORD,
		dwMaximumSizeHigh: DWORD,
		dwMaximumSizeLow: DWORD,
		lpName: LPCWSTR,
		nndPreferred: DWORD,
	) -> HANDLE ---
}

WIN32_MEMORY_RANGE_ENTRY :: struct {
	VirtualAddress: PVOID,
	NumberOfBytes: SIZE_T,
}

PWIN32_MEMORY_RANGE_ENTRY :: ^WIN32_MEMORY_RANGE_ENTRY

@(default_calling_convention="system")
foreign kernel32 {
	PrefetchVirtualMemory :: proc(
		hProcess: HANDLE,
		NumberOfEntries: ULONG_PTR,
		VirtualAddresses: PWIN32_MEMORY_RANGE_ENTRY,
		Flags: ULONG,
	) -> BOOL ---
	CreateFileMappingFromApp :: proc(
		hFile: HANDLE,
		SecurityAttributes: PSECURITY_ATTRIBUTES,
		PageProtection: ULONG,
		MaximumSize: ULONG64,
		Name: PCWSTR,
	) -> HANDLE ---
	MapViewOfFileFromApp :: proc(
		hFileMappingObject: HANDLE,
		DesiredAccess: ULONG,
		FileOffset: ULONG64,
		NumberOfBytesToMap: SIZE_T,
	) -> PVOID ---
	UnmapViewOfFileEx :: proc(
		BaseAddress: PVOID,
		UnmapFlags: ULONG,
	) -> BOOL ---
	AllocateUserPhysicalPages :: proc(
		hProcess: HANDLE,
		NumberOfPages: PULONG_PTR,
		PageArray: PULONG_PTR,
	) -> BOOL ---
	FreeUserPhysicalPages :: proc(
		hProcess: HANDLE,
		NumberOfPages: PULONG_PTR,
		PageArray: PULONG_PTR,
	) -> BOOL ---
	MapUserPhysicalPages :: proc(
		VirtualAddress: PVOID,
		NumberOfPages: ULONG_PTR,
		PageArray: PULONG_PTR,
	) -> BOOL ---
	AllocateUserPhysicalPagesNuma :: proc(
		hProcess: HANDLE,
		NumberOfPages: PULONG_PTR,
		PageArray: PULONG_PTR,
		nndPreferred: DWORD,
	) -> BOOL ---
	VirtualAllocExNuma :: proc(
		hProcess: HANDLE,
		lpAddress: LPVOID,
		dwSize: SIZE_T,
		flAllocationType: DWORD,
		flProtect: DWORD,
		nndPreferred: DWORD,
	) -> LPVOID ---
}

MEHC_PATROL_SCRUBBER_PRESENT :: ULONG(0x1)

@(default_calling_convention="system")
foreign kernel32 {
	GetMemoryErrorHandlingCapabilities :: proc(
		Capabilities: PULONG,
	) -> BOOL ---
}

@(default_calling_convention="system")
foreign kernel32 {
	GlobalMemoryStatusEx :: proc(
		lpBuffer: ^MEMORYSTATUSEX,
	) -> BOOL ---
}

PBAD_MEMORY_CALLBACK_ROUTINE :: #type proc "system" ()

@(default_calling_convention="system")
foreign kernel32 {
	RegisterBadMemoryNotification :: proc(
		Callback: PBAD_MEMORY_CALLBACK_ROUTINE,
	) -> PVOID ---
	UnregisterBadMemoryNotification :: proc(
		RegistrationHandle: PVOID,
	) -> BOOL ---
}

OFFER_PRIORITY :: enum c_int {
	VmOfferPriorityVeryLow = 1,
	VmOfferPriorityLow,
	VmOfferPriorityBelowNormal,
	VmOfferPriorityNormal,
}
VmOfferPriorityVeryLow     :: OFFER_PRIORITY.VmOfferPriorityVeryLow
VmOfferPriorityLow         :: OFFER_PRIORITY.VmOfferPriorityLow
VmOfferPriorityBelowNormal :: OFFER_PRIORITY.VmOfferPriorityBelowNormal
VmOfferPriorityNormal      :: OFFER_PRIORITY.VmOfferPriorityNormal

@(default_calling_convention="system")
foreign kernel32 {
	OfferVirtualMemory :: proc(
		VirtualAddress: PVOID,
		Size: SIZE_T,
		Priority: OFFER_PRIORITY,
	) -> DWORD ---
	ReclaimVirtualMemory :: proc(
		VirtualAddress: PVOID,
		Size: SIZE_T,
	) -> DWORD ---
	DiscardVirtualMemory :: proc(
		VirtualAddress: PVOID,
		Size: SIZE_T,
	) -> DWORD ---
	VirtualAllocFromApp :: proc(
		BaseAddress: PVOID,
		Size: SIZE_T,
		AllocationType: ULONG,
		Protection: ULONG,
	) -> PVOID ---
	VirtualProtectFromApp :: proc(
		Address: PVOID,
		Size: SIZE_T,
		NewProtection: ULONG,
		OldProtection: PULONG,
	) -> BOOL ---
	OpenFileMappingFromApp :: proc(
		DesiredAccess: ULONG,
		InheritHandle: BOOL,
		Name: PCWSTR,
	) -> HANDLE ---
}

WIN32_MEMORY_INFORMATION_CLASS :: enum c_int {
	MemoryRegionInfo,
}
MemoryRegionInfo :: WIN32_MEMORY_INFORMATION_CLASS.MemoryRegionInfo

WIN32_MEMORY_REGION_INFORMATION :: struct {
	AllocationBase: PVOID,
	AllocationProtect: ULONG,
	u: WIN32_MEMORY_REGION_INFORMATION_u,
	RegionSize: SIZE_T,
	CommitSize: SIZE_T,
}
WIN32_MEMORY_REGION_INFORMATION_u :: struct #raw_union {
	u: [1]u32,
	Flags: ULONG,
	s: WIN32_MEMORY_REGION_INFORMATION_u_s,
}
WIN32_MEMORY_REGION_INFORMATION_u_s :: struct {
	Bitfield: ULONG,
}
WIN32_MEMORY_REGION_INFORMATION_u_s_Bitfield :: distinct ULONG
/*bit_field #align(align_of(ULONG)) {
	Private        : 1-0,
	MappedDataFile : 2-1,
	MappedImage    : 3-2,
	MappedPageFile : 4-3,
	MappedPhysical : 5-4,
	DirectMapped   : 6-5,
	Reserved       : 32-6,
}*/

@(default_calling_convention="system")
foreign one_core {
	QueryVirtualMemoryInformation :: proc(
		Process: HANDLE,
		VirtualAddress: PVOID,
		MemoryInformationClass: WIN32_MEMORY_INFORMATION_CLASS,
		MemoryInformation: PVOID,
		MemoryInformationSize: SIZE_T,
		ReturnSize: PSIZE_T,
	) -> BOOL ---
	MapViewOfFileNuma2 :: proc(
		FileMappingHandle: HANDLE,
		ProcessHandle: HANDLE,
		Offset: ULONG64,
		BaseAddress: PVOID,
		ViewSize: SIZE_T,
		AllocationType: ULONG,
		PageProtection: ULONG,
		PreferredNode: ULONG,
	) -> PVOID ---
	GetCommPorts :: proc(
		lpPortNumbers: PULONG,
		uPortNumbersCount: ULONG,
		puPortNumbersFound: PULONG,
	) -> ULONG ---
}


NUMA_NO_PREFERRED_NODE :: 0xffffffff

MapViewOfFile2 :: #force_inline proc "system" (
	FileMappingHandle: HANDLE,
	ProcessHandle: HANDLE,
	Offset: ULONG64,
	BaseAddress: PVOID,
	ViewSize: SIZE_T,
	AllocationType: ULONG,
	PageProtection: ULONG,
) -> PVOID {
	return MapViewOfFileNuma2(
		FileMappingHandle,
		ProcessHandle,
		Offset,
		BaseAddress,
		ViewSize,
		AllocationType,
		PageProtection,
		NUMA_NO_PREFERRED_NODE,
	)
}

@(default_calling_convention="system")
foreign kernel32 {
	UnmapViewOfFile2 :: proc(
		ProcessHandle: HANDLE,
		BaseAddress: PVOID,
		UnmapFlags: ULONG,
	) -> BOOL ---
}

@(default_calling_convention="system")
foreign kernel32 {
	GetProductInfo :: proc(
		OSMajorVersion: DWORD,
		OSMinorVersion: DWORD,
		SpMajorVersion: DWORD,
		SpMinorVersion: DWORD,
		product_type: ^Windows_Product_Type,
	) -> BOOL ---
}

HandlerRoutine :: proc "system" (dwCtrlType: DWORD) -> BOOL
PHANDLER_ROUTINE :: HandlerRoutine

// NOTE(Jeroen, 2024-06-13): As Odin now supports bit_fields, we no longer need
// a helper procedure. `init_dcb_with_config` and `get_dcb_config` have been removed.

LPFIBER_START_ROUTINE :: #type proc "system" (lpFiberParameter: LPVOID)

@(default_calling_convention = "system")
foreign kernel32 {
	CreateFiber :: proc(dwStackSize: SIZE_T, lpStartAddress: LPFIBER_START_ROUTINE, lpParameter: LPVOID) -> LPVOID ---
	DeleteFiber :: proc(lpFiber: LPVOID) ---
	ConvertThreadToFiber :: proc(lpParameter: LPVOID) -> LPVOID ---
	SwitchToFiber :: proc(lpFiber: LPVOID) ---
}

LOGICAL_PROCESSOR_RELATIONSHIP :: enum c_int {
	RelationProcessorCore,
	RelationNumaNode,
	RelationCache,
	RelationProcessorPackage,
	RelationGroup,
	RelationProcessorDie,
	RelationNumaNodeEx,
	RelationProcessorModule,
	RelationAll = 0xffff,
}

PROCESSOR_CACHE_TYPE :: enum c_int {
	CacheUnified,
	CacheInstruction,
	CacheData,
	CacheTrace,
}

CACHE_DESCRIPTOR :: struct {
	Level: BYTE,
	Associativity: BYTE,
	LineSize: WORD,
	Size: DWORD,
	Type: PROCESSOR_CACHE_TYPE,
}

ProcessorCore :: struct {
	Flags: BYTE,
}
NumaNode :: struct {
	NodeNumber: DWORD,
}
DUMMYUNIONNAME_u :: struct #raw_union {
	Core: ProcessorCore,
	Node: NumaNode,
	Cache: CACHE_DESCRIPTOR,
	Reserved: [2]ULONGLONG,
}

SYSTEM_LOGICAL_PROCESSOR_INFORMATION :: struct {
	ProcessorMask: ULONG_PTR,
	Relationship: LOGICAL_PROCESSOR_RELATIONSHIP,
	DummyUnion: DUMMYUNIONNAME_u,
}

SYSTEM_POWER_STATUS :: struct {
	ACLineStatus:        AC_Line_Status,
	BatteryFlag:         Battery_Flags,
	BatteryLifePercent:  BYTE,
	SystemStatusFlag:    BYTE,
	BatteryLifeTime:     DWORD,
	BatteryFullLifeTime: DWORD,
}

AC_Line_Status :: enum BYTE {
	Offline = 0,
	Online  = 1,
	Unknown = 255,
}

Battery_Flag :: enum BYTE {
	High     = 0,
	Low      = 1,
	Critical = 2,
	Charging = 3,
	No_Battery = 7,
}
Battery_Flags :: bit_set[Battery_Flag; BYTE]

/* Global Memory Flags */
GMEM_FIXED          :: 0x0000
GMEM_MOVEABLE       :: 0x0002
GMEM_NOCOMPACT      :: 0x0010
GMEM_NODISCARD      :: 0x0020
GMEM_ZEROINIT       :: 0x0040
GMEM_MODIFY         :: 0x0080
GMEM_DISCARDABLE    :: 0x0100
GMEM_NOT_BANKED     :: 0x1000
GMEM_SHARE          :: 0x2000
GMEM_DDESHARE       :: 0x2000
GMEM_NOTIFY         :: 0x4000
GMEM_LOWER          :: GMEM_NOT_BANKED
GMEM_VALID_FLAGS    :: 0x7F72
GMEM_INVALID_HANDLE :: 0x8000

GHND                :: (GMEM_MOVEABLE | GMEM_ZEROINIT)
GPTR                :: (GMEM_FIXED | GMEM_ZEROINIT)

LPTOP_LEVEL_EXCEPTION_FILTER :: PVECTORED_EXCEPTION_HANDLER
