package sys_windows

foreign import kernel32 "system:Kernel32.lib"



@(default_calling_convention="stdcall")
foreign kernel32 {
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

	GetConsoleMode :: proc(hConsoleHandle: HANDLE,
	                       lpMode: LPDWORD) -> BOOL ---


	GetFileInformationByHandle :: proc(hFile: HANDLE, lpFileInformation: LPBY_HANDLE_FILE_INFORMATION) -> BOOL ---
	SetHandleInformation :: proc(hObject: HANDLE,
	                             dwMask: DWORD,
	                             dwFlags: DWORD) -> BOOL ---

	AddVectoredExceptionHandler :: proc(FirstHandler: ULONG, VectoredHandler: PVECTORED_EXCEPTION_HANDLER) -> LPVOID ---
	AddVectoredContinueHandler  :: proc(FirstHandler: ULONG, VectoredHandler: PVECTORED_EXCEPTION_HANDLER) -> LPVOID ---
	RemoveVectoredExceptionHandler  :: proc(Handle: LPVOID) -> DWORD ---
	RemoveVectoredContinueHandler  :: proc(Handle: LPVOID) -> DWORD ---
	RaiseException :: proc(dwExceptionCode, dwExceptionFlags, nNumberOfArguments: DWORD, lpArguments: ^ULONG_PTR) -> ! ---


	CreateHardLinkW :: proc(lpSymlinkFileName: LPCWSTR,
	                        lpTargetFileName: LPCWSTR,
	                        lpSecurityAttributes: LPSECURITY_ATTRIBUTES) -> BOOL ---

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
	GetCommandLineW :: proc() -> LPCWSTR ---
	GetTempPathW :: proc(nBufferLength: DWORD, lpBuffer: LPCWSTR) -> DWORD ---
	GetCurrentProcess :: proc() -> HANDLE ---
	GetCurrentProcessId :: proc() -> DWORD ---
	GetCurrentThread :: proc() -> HANDLE ---
	GetCurrentThreadId :: proc() -> DWORD ---
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
		lpStartAddress: proc "stdcall" (rawptr) -> DWORD,
		lpParameter: LPVOID,
		dwCreationFlags: DWORD,
		lpThreadId: LPDWORD,
	) -> HANDLE ---
	SwitchToThread :: proc() -> BOOL ---
	ResumeThread :: proc(thread: HANDLE) -> DWORD ---;
	GetThreadPriority :: proc(thread: HANDLE) -> c_int ---;
	SetThreadPriority :: proc(thread: HANDLE, priority: c_int) -> BOOL ---;
	GetExitCodeThread :: proc(thread: HANDLE, exit_code: ^DWORD) -> BOOL ---;
	TerminateThread :: proc(thread: HANDLE, exit_code: DWORD) -> BOOL ---;

	CreateSemaphoreW :: proc(attributes: LPSECURITY_ATTRIBUTES, initial_count, maximum_count: LONG, name: LPCSTR) -> HANDLE ---;
	ReleaseSemaphore :: proc(semaphore: HANDLE, release_count: LONG, previous_count: ^LONG) -> BOOL ---;

	WaitForSingleObject :: proc(hHandle: HANDLE, dwMilliseconds: DWORD) -> DWORD ---
	Sleep :: proc(dwMilliseconds: DWORD) ---
	GetProcessId :: proc(handle: HANDLE) -> DWORD ---
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
	TlsGetValue :: proc(dwTlsIndex: DWORD) -> LPVOID ---
	TlsSetValue :: proc(dwTlsIndex: DWORD, lpTlsvalue: LPVOID) -> BOOL ---
	GetLastError :: proc() -> DWORD ---
	QueryPerformanceFrequency :: proc(lpFrequency: ^LARGE_INTEGER) -> BOOL ---
	QueryPerformanceCounter :: proc(lpPerformanceCount: ^LARGE_INTEGER) -> BOOL ---
	GetExitCodeProcess :: proc(hProcess: HANDLE, lpExitCode: LPDWORD) -> BOOL ---
	TerminateProcess :: proc(hProcess: HANDLE, uExitCode: UINT) -> BOOL ---
	CreateProcessW :: proc(
		lpApplicationName: LPCWSTR,
		lpCommandLine: LPWSTR,
		lpProcessAttributes: LPSECURITY_ATTRIBUTES,
		lpThreadAttributes: LPSECURITY_ATTRIBUTES,
		bInheritHandles: BOOL,
		dwCreationFlags: DWORD,
		lpEnvironment: LPVOID,
		lpCurrentDirectory: LPCWSTR,
		lpStartupInfo: LPSTARTUPINFO,
		lpProcessInformation: LPPROCESS_INFORMATION,
	) -> BOOL ---
	GetEnvironmentVariableW :: proc(n: LPCWSTR, v: LPWSTR, nsize: DWORD) -> DWORD ---
	SetEnvironmentVariableW :: proc(n: LPCWSTR, v: LPCWSTR) -> BOOL ---
	GetEnvironmentStringsW :: proc() -> LPWCH ---
	FreeEnvironmentStringsW :: proc(env_ptr: LPWCH) -> BOOL ---
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
	MoveFileExW :: proc(lpExistingFileName: LPCWSTR, lpNewFileName: LPCWSTR, dwFlags: DWORD)
	-> BOOL ---
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

	FindFirstFileW :: proc(fileName: LPCWSTR, findFileData: LPWIN32_FIND_DATAW) -> HANDLE ---
	FindNextFileW :: proc(findFile: HANDLE, findFileData: LPWIN32_FIND_DATAW) -> BOOL ---
	FindClose :: proc(findFile: HANDLE) -> BOOL ---
	GetModuleHandleW :: proc(lpModuleName: LPCWSTR) -> HMODULE ---
	GetSystemTimeAsFileTime :: proc(lpSystemTimeAsFileTime: LPFILETIME) ---
	CreateEventW :: proc(
		lpEventAttributes: LPSECURITY_ATTRIBUTES,
		bManualReset: BOOL,
		bInitialState: BOOL,
		lpName: LPCWSTR,
	) -> HANDLE ---
	WaitForMultipleObjects :: proc(
		nCount: DWORD,
		lpHandles: ^HANDLE,
		bWaitAll: BOOL,
		dwMilliseconds: DWORD,
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

	InitializeSRWLock          :: proc(SRWLock: ^SRWLOCK) ---
	AcquireSRWLockExclusive    :: proc(SRWLock: ^SRWLOCK) ---
	TryAcquireSRWLockExclusive :: proc(SRWLock: ^SRWLOCK) -> BOOL ---
	ReleaseSRWLockExclusive    :: proc(SRWLock: ^SRWLOCK) ---
	AcquireSRWLockShared    :: proc(SRWLock: ^SRWLOCK) ---
	TryAcquireSRWLockShared :: proc(SRWLock: ^SRWLOCK) -> BOOL ---
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

	LoadLibraryW :: proc(c_str: LPCWSTR) -> HMODULE ---
	FreeLibrary :: proc(h: HMODULE) -> BOOL ---
	GetProcAddress :: proc(h: HMODULE, c_str: LPCSTR) -> rawptr ---


	GetFullPathNameW  :: proc(filename: LPCWSTR, buffer_length: DWORD, buffer: LPCWSTR, file_part: ^LPCWSTR) -> DWORD ---
	GetLongPathNameW  :: proc(short, long: LPCWSTR, len: DWORD) -> DWORD ---
	GetShortPathNameW :: proc(long, short: LPCWSTR, len: DWORD) -> DWORD ---

}
