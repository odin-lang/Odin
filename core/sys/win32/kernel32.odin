// +build windows
package win32

foreign import "system:kernel32.lib"

@(default_calling_convention = "std")
foreign kernel32 {
	CreateProcessA            :: proc(application_name, command_line: cstring,
	                                  process_attributes, thread_attributes: ^SECURITY_ATTRIBUTES,
	                                  inherit_handle: BOOL, creation_flags: u32, environment: rawptr,
	                                  current_direcotry: cstring, startup_info: ^STARTUPINFO,
	                                  process_information: ^PROCESS_INFORMATION) -> BOOL ---;

	CreateProcessW            :: proc(application_name, command_line: LPCWSTR,
	                                  process_attributes, thread_attributes: ^SECURITY_ATTRIBUTES,
	                                  inherit_handle: BOOL, creation_flags: u32, environment: rawptr,
	                                  current_direcotry: cstring, startup_info: ^STARTUPINFO,
	                                  process_information: ^PROCESS_INFORMATION) -> BOOL ---;

	GetExitCodeProcess        :: proc(process: HANDLE, exit: ^u32) -> BOOL ---;
	ExitProcess               :: proc(exit_code: u32) ---;
	GetModuleHandleA          :: proc(module_name: cstring) -> HMODULE ---;
	GetModuleHandleW          :: proc(module_name: LPCWSTR) -> HMODULE ---;

	GetModuleFileNameA        :: proc(module: HMODULE, filename: cstring, size: u32) -> u32 ---;
	GetModuleFileNameW        :: proc(module: HMODULE, filename: LPCWSTR, size: u32) -> u32 ---;

	Sleep                     :: proc(ms: u32) ---;
	QueryPerformanceFrequency :: proc(result: ^i64) -> i32 ---;
	QueryPerformanceCounter   :: proc(result: ^i64) -> i32 ---;
	OutputDebugStringA        :: proc(c_str: cstring) ---;

	GetCommandLineA           :: proc() -> cstring ---;
	GetCommandLineW           :: proc() -> LPCWSTR ---;
	GetSystemMetrics          :: proc(index: i32) -> i32 ---;
	GetSystemInfo             :: proc(info: ^SYSTEM_INFO) ---;
	GetVersionExA             :: proc(osvi: ^OSVERSIONINFOEXA) ---;
	GetCurrentThreadId        :: proc() -> u32 ---;

	// NOTE(tetra): Not thread safe with SetCurrentDirectory and GetFullPathName;
	// The current directory is stored as a global variable in the process.
	GetCurrentDirectoryW      :: proc(len: u32, buf: LPCWSTR) -> u32 ---;
	SetCurrentDirectoryW      :: proc(buf: LPCWSTR) -> u32 ---;

	GetSystemTimeAsFileTime   :: proc(system_time_as_file_time: ^FILETIME) ---;
	FileTimeToLocalFileTime   :: proc(file_time: ^FILETIME, local_file_time: ^FILETIME) -> BOOL ---;
	FileTimeToSystemTime      :: proc(file_time: ^FILETIME, system_time: ^SYSTEMTIME) -> BOOL ---;
	SystemTimeToFileTime      :: proc(system_time: ^SYSTEMTIME, file_time: ^FILETIME) -> BOOL ---;

	GetStdHandle :: proc(h: i32) -> HANDLE ---;

	CreateFileA :: proc(filename: cstring, desired_access, share_module: u32,
	                      security: rawptr,
	                      creation, flags_and_attribs: u32, template_file: HANDLE) -> HANDLE ---;

	CreateFileW :: proc(filename: LPCWSTR, desired_access, share_module: u32,
	                      security: rawptr,
	                      creation, flags_and_attribs: u32, template_file: HANDLE) -> HANDLE ---;


	ReadFile  :: proc(h: HANDLE, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> BOOL ---;
	WriteFile :: proc(h: HANDLE, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> BOOL ---;

	GetFileSizeEx              :: proc(file_handle: HANDLE, file_size: ^i64) -> BOOL ---;
	GetFileInformationByHandle :: proc(file_handle: HANDLE, file_info: ^BY_HANDLE_FILE_INFORMATION) -> BOOL ---;

	CreateDirectoryA :: proc(path: cstring, security_attributes: ^SECURITY_ATTRIBUTES) -> BOOL ---;
	CreateDirectoryW :: proc(path: LPCWSTR, security_attributes: ^SECURITY_ATTRIBUTES) -> BOOL ---;

	GetFileType    :: proc(file_handle: HANDLE) -> u32 ---;
	SetFilePointer :: proc(file_handle: HANDLE, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 ---;

	SetHandleInformation :: proc(obj: HANDLE, mask, flags: u32) -> BOOL ---;

	FindFirstFileA :: proc(file_name: cstring, data: ^WIN32_FIND_DATAA) -> HANDLE ---;
	FindNextFileA  :: proc(file: HANDLE, data: ^WIN32_FIND_DATAA) -> BOOL ---;
	FindFirstFileW :: proc(file_name: LPCWSTR, data: ^WIN32_FIND_DATAW) -> HANDLE ---;
	FindNextFileW  :: proc(file: HANDLE, data: ^WIN32_FIND_DATAW) -> BOOL ---;
	FindClose      :: proc(file: HANDLE) -> BOOL ---;

	MoveFileExA :: proc(existing, new: cstring, flags: u32) -> BOOL ---;
	DeleteFileA :: proc(file_name: cstring) -> BOOL ---;
	CopyFileA   :: proc(existing, new: cstring, fail_if_exists: BOOL) -> BOOL ---;

	MoveFileExW :: proc(existing, new: LPCWSTR, flags: u32) -> BOOL ---;
	DeleteFileW :: proc(file_name: LPCWSTR) -> BOOL ---;
	CopyFileW   :: proc(existing, new: LPCWSTR, fail_if_exists: BOOL) -> BOOL ---;

	HeapAlloc      :: proc(h: HANDLE, flags: u32, bytes: int) -> rawptr ---;
	HeapReAlloc    :: proc(h: HANDLE, flags: u32, memory: rawptr, bytes: int) -> rawptr ---;
	HeapFree       :: proc(h: HANDLE, flags: u32, memory: rawptr) -> BOOL ---;
	GetProcessHeap :: proc() -> HANDLE ---;

	LocalAlloc   :: proc(flags: u32, bytes: int) -> rawptr ---;
	LocalReAlloc :: proc(mem: rawptr, bytes: int, flags: uint) -> rawptr ---;
	LocalFree    :: proc(mem: rawptr) -> rawptr ---;

	FindFirstChangeNotificationA :: proc(path: cstring, watch_subtree: BOOL, filter: u32) -> HANDLE ---;
	FindNextChangeNotification   :: proc(h: HANDLE) -> BOOL ---;
	FindCloseChangeNotification  :: proc(h: HANDLE) -> BOOL ---;

	ReadDirectoryChangesW :: proc(dir: HANDLE, buf: rawptr, buf_length: u32,
	                                                                      watch_subtree: BOOL, notify_filter: u32,
	                                                                      bytes_returned: ^u32, overlapped: ^OVERLAPPED,
	                                                                      completion: rawptr) -> BOOL ---;

	WideCharToMultiByte :: proc(code_page: u32, flags: u32,
	                            wchar_str: LPCWSTR, wchar: i32,
	                            multi_str: cstring, multi: i32,
	                            default_char: cstring, used_default_char: ^BOOL) -> i32 ---;

	MultiByteToWideChar :: proc(code_page: u32, flags: u32,
	                            mb_str: cstring, mb: i32,
	                            wc_str: LPCWSTR, wc: i32) -> i32 ---;

	CreateSemaphoreA    :: proc(attributes: ^SECURITY_ATTRIBUTES, initial_count, maximum_count: i32, name: cstring) -> HANDLE ---;
	CreateSemaphoreW    :: proc(attributes: ^SECURITY_ATTRIBUTES, initial_count, maximum_count: i32, name: cstring) -> HANDLE ---;
	ReleaseSemaphore    :: proc(semaphore: HANDLE, release_count: i32, previous_count: ^i32) -> BOOL ---;
	WaitForSingleObject :: proc(handle: HANDLE, milliseconds: u32) -> u32 ---;
}

create_process_a                  :: CreateProcessA;
create_process_w                  :: CreateProcessW;
get_exit_code_process             :: GetExitCodeProcess;
exit_process                      :: ExitProcess;
get_module_handle_a               :: GetModuleHandleA;
get_module_handle_w               :: GetModuleHandleW;
get_module_file_name_a            :: GetModuleFileNameA;
get_module_file_name_w            :: GetModuleFileNameW;
sleep                             :: Sleep;
query_performance_frequency       :: QueryPerformanceFrequency;
query_performance_counter         :: QueryPerformanceCounter;
output_debug_string_a             :: OutputDebugStringA;
get_command_line_a                :: GetCommandLineA;
get_command_line_w                :: GetCommandLineW;
get_system_metrics                :: GetSystemMetrics;
get_system_info                   :: GetSystemInfo;
get_version                       :: GetVersionExA;
get_current_thread_id             :: GetCurrentThreadId;
get_current_directory_w           :: GetCurrentDirectoryW;
set_current_directory_w           :: SetCurrentDirectoryW;
get_system_time_as_file_time      :: GetSystemTimeAsFileTime;
file_time_to_local_file_time      :: FileTimeToLocalFileTime;
file_time_to_system_time          :: FileTimeToSystemTime;
system_time_to_file_time          :: SystemTimeToFileTime;
get_std_handle                    :: GetStdHandle;
create_file_a                     :: CreateFileA;
create_file_w                     :: CreateFileW;
read_file                         :: ReadFile;
write_file                        :: WriteFile;
get_file_size_ex                  :: GetFileSizeEx;
get_file_information_by_handle    :: GetFileInformationByHandle;
create_directory_a                :: CreateDirectoryA;
create_directory_w                :: CreateDirectoryW;
get_file_type                     :: GetFileType;
set_file_pointer                  :: SetFilePointer;
set_handle_information            :: SetHandleInformation;
find_first_file_a                 :: FindFirstFileA;
find_next_file_a                  :: FindNextFileA;
find_first_file_w                 :: FindFirstFileW;
find_next_file_w                  :: FindNextFileW;
find_close                        :: FindClose;
move_file_ex_a                    :: MoveFileExA;
delete_file_a                     :: DeleteFileA;
copy_file_a                       :: CopyFileA;
move_file_ex_w                    :: MoveFileExW;
delete_file_w                     :: DeleteFileW;
copy_file_w                       :: CopyFileW;
heap_alloc                        :: HeapAlloc;
heap_realloc                      :: HeapReAlloc;
heap_free                         :: HeapFree;
get_process_heap                  :: GetProcessHeap;
local_alloc                       :: LocalAlloc;
local_realloc                     :: LocalReAlloc;
local_free                        :: LocalFree;
find_first_change_notification_a  :: FindFirstChangeNotificationA;
find_next_change_notification     :: FindNextChangeNotification;
find_close_change_notification    :: FindCloseChangeNotification;
read_directory_changes_w          :: ReadDirectoryChangesW;
wide_char_to_multi_byte           :: WideCharToMultiByte;
multi_byte_to_wide_char           :: MultiByteToWideChar;
create_semaphore_a                :: CreateSemaphoreA;
create_semaphore_w                :: CreateSemaphoreW;
release_semaphore                 :: ReleaseSemaphore;
wait_for_single_object            :: WaitForSingleObject;

// @(default_calling_convention = "c")
foreign kernel32 {
	GetLastError :: proc() -> i32 ---;

	CloseHandle  :: proc(h: HANDLE) -> i32 ---;

	GetFileAttributesA   :: proc(filename: cstring) -> u32 ---;
	GetFileAttributesW   :: proc(filename: LPCWSTR) -> u32 ---;
	GetFileAttributesExA :: proc(filename: cstring, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: ^WIN32_FILE_ATTRIBUTE_DATA) -> BOOL ---;
	GetFileAttributesExW :: proc(filename: LPCWSTR, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: ^WIN32_FILE_ATTRIBUTE_DATA) -> BOOL ---;

	CompareFileTime      :: proc(a, b: ^FILETIME) -> i32 ---;
}

get_last_error           :: GetLastError;
close_handle             :: CloseHandle;
get_file_attributes_a    :: GetFileAttributesA;
get_file_attributes_w    :: GetFileAttributesW;
get_file_attributes_ex_a :: GetFileAttributesExA;
get_file_attributes_ex_w :: GetFileAttributesExW;
compare_file_time        :: CompareFileTime;

@(default_calling_convention = "c")
foreign kernel32 {
	InterlockedCompareExchange :: proc(dst: ^i32, exchange, comparand: i32) -> i32 ---;
	InterlockedExchange        :: proc(dst: ^i32, desired: i32) -> i32 ---;
	InterlockedExchangeAdd     :: proc(dst: ^i32, desired: i32) -> i32 ---;
	InterlockedAnd             :: proc(dst: ^i32, desired: i32) -> i32 ---;
	InterlockedOr              :: proc(dst: ^i32, desired: i32) -> i32 ---;

	InterlockedCompareExchange64 :: proc(dst: ^i64, exchange, comparand: i64) -> i64 ---;
	InterlockedExchange64        :: proc(dst: ^i64, desired: i64) -> i64 ---;
	InterlockedExchangeAdd64     :: proc(dst: ^i64, desired: i64) -> i64 ---;
	InterlockedAnd64             :: proc(dst: ^i64, desired: i64) -> i64 ---;
	InterlockedOr64              :: proc(dst: ^i64, desired: i64) -> i64 ---;
}

interlocked_compare_exchange   :: InterlockedCompareExchange;
interlocked_exchange           :: InterlockedExchange;
interlocked_exchange_add       :: InterlockedExchangeAdd;
interlocked_and                :: InterlockedAnd;
interlocked_or                 :: InterlockedOr;
interlocked_compare_exchange64 :: InterlockedCompareExchange64;
interlocked_exchange64         :: InterlockedExchange64;
interlocked_exchange_add64     :: InterlockedExchangeAdd64;
interlocked_and64              :: InterlockedAnd64;
interlocked_or64               :: InterlockedOr64;

@(default_calling_convention = "std")
foreign kernel32 {
	_mm_pause        :: proc() ---;
	ReadWriteBarrier :: proc() ---;
	WriteBarrier     :: proc() ---;
	ReadBarrier      :: proc() ---;

	CreateThread       :: proc(thread_attributes: ^SECURITY_ATTRIBUTES, stack_size: int, start_routine: rawptr,
	                           parameter: rawptr, creation_flags: u32, thread_id: ^u32) -> HANDLE ---;
	ResumeThread       :: proc(thread: HANDLE) -> u32 ---;
	GetThreadPriority  :: proc(thread: HANDLE) -> i32 ---;
	SetThreadPriority  :: proc(thread: HANDLE, priority: i32) -> BOOL ---;
    GetExitCodeThread  :: proc(thread: HANDLE, exit_code: ^u32) -> BOOL ---;
	TerminateThread    :: proc(thread: HANDLE, exit_code: u32) -> BOOL ---;

	InitializeCriticalSection             :: proc(critical_section: ^CRITICAL_SECTION) ---;
	InitializeCriticalSectionAndSpinCount :: proc(critical_section: ^CRITICAL_SECTION, spin_count: u32) ---;
	DeleteCriticalSection                 :: proc(critical_section: ^CRITICAL_SECTION) ---;
	SetCriticalSectionSpinCount           :: proc(critical_section: ^CRITICAL_SECTION, spin_count: u32) -> u32 ---;
	TryEnterCriticalSection               :: proc(critical_section: ^CRITICAL_SECTION) -> BOOL ---;
	EnterCriticalSection                  :: proc(critical_section: ^CRITICAL_SECTION) ---;
	LeaveCriticalSection                  :: proc(critical_section: ^CRITICAL_SECTION) ---;

	CreateEventA :: proc(event_attributes: ^SECURITY_ATTRIBUTES, manual_reset, initial_state: BOOL, name: cstring) -> HANDLE ---;
	CreateEventW :: proc(event_attributes: ^SECURITY_ATTRIBUTES, manual_reset, initial_state: BOOL, name: LPCWSTR) -> HANDLE ---;
	PulseEvent   :: proc(event: HANDLE) -> BOOL ---;
	SetEvent     :: proc(event: HANDLE) -> BOOL ---;
	ResetEvent   :: proc(event: HANDLE) -> BOOL ---;

	LoadLibraryA   :: proc(c_str: cstring)  -> HMODULE ---;
	LoadLibraryW   :: proc(c_str: LPCWSTR) -> HMODULE ---;
	FreeLibrary    :: proc(h: HMODULE) -> BOOL ---;
	GetProcAddress :: proc(h: HMODULE, c_str: cstring) -> rawptr ---;
}

mm_pause                                   :: _mm_pause;
read_write_barrier                         :: ReadWriteBarrier;
write_barrier                              :: WriteBarrier;
read_barrier                               :: ReadBarrier;
create_thread                              :: CreateThread;
resume_thread                              :: ResumeThread;
get_thread_priority                        :: GetThreadPriority;
set_thread_priority                        :: SetThreadPriority;
get_exit_code_thread                       :: GetExitCodeThread;
terminate_thread                           :: TerminateThread;
initialize_critical_section                :: InitializeCriticalSection;
initialize_critical_section_and_spin_count :: InitializeCriticalSectionAndSpinCount;
delete_critical_section                    :: DeleteCriticalSection;
set_critical_section_spin_count            :: SetCriticalSectionSpinCount;
try_enter_critical_section                 :: TryEnterCriticalSection;
enter_critical_section                     :: EnterCriticalSection;
leave_critical_section                     :: LeaveCriticalSection;
create_event_a                             :: CreateEventA;
create_event_w                             :: CreateEventW;
pulse_event                                :: PulseEvent;
set_event                                  :: SetEvent;
reset_event                                :: ResetEvent;
load_library_a                             :: LoadLibraryA;
load_library_w                             :: LoadLibraryW;
free_library                               :: FreeLibrary;
get_proc_address                           :: GetProcAddress;

MEMORY_BASIC_INFORMATION :: struct {
	base_address:       rawptr,
	allocation_base:    rawptr,
	allocation_protect: u32,
	region_size:        uint,
	state:              u32,
	protect:            u32,
	type:               u32,
}

@(default_calling_convention = "std")
foreign kernel32 {
	VirtualAlloc   :: proc(address: rawptr, size: uint, allocation_type: u32, protect: u32) -> rawptr ---
	VirtualAllocEx :: proc(process: HANDLE, address: rawptr, size: uint, allocation_type: u32, protect: u32) -> rawptr ---
	VirtualFree    :: proc(address: rawptr, size: uint, free_type: u32) -> BOOL ---
	VirtualLock    :: proc(address: rawptr, size: uint) -> BOOL ---
	VirtualProtect :: proc(address: rawptr, size: uint, new_protect: u32, old_protect: ^u32) -> BOOL ---
	VirtualQuery   :: proc(address: rawptr, buffer: ^MEMORY_BASIC_INFORMATION, length: uint) -> uint ---
}

virtual_alloc    :: VirtualAlloc;
virtual_alloc_ex :: VirtualAllocEx;
virtual_free     :: VirtualFree;
virtual_lock     :: VirtualLock;
virtual_protect  :: VirtualProtect;
virtual_query    :: VirtualQuery;

MEM_COMMIT      :: 0x00001000;
MEM_RESERVE     :: 0x00002000;
MEM_DECOMMIT    :: 0x00004000;
MEM_RELEASE     :: 0x00008000;
MEM_RESET       :: 0x00080000;
MEM_RESET_UNDO  :: 0x01000000;

MEM_LARGE_PAGES :: 0x20000000;
MEM_PHYSICAL    :: 0x00400000;
MEM_TOP_DOWN    :: 0x00100000;
MEM_WRITE_WATCH :: 0x00200000;

PAGE_NOACCESS           :: 0x01;
PAGE_READONLY           :: 0x02;
PAGE_READWRITE          :: 0x04;
PAGE_WRITECOPY          :: 0x08;
PAGE_EXECUTE            :: 0x10;
PAGE_EXECUTE_READ       :: 0x20;
PAGE_EXECUTE_READWRITE  :: 0x40;
PAGE_EXECUTE_WRITECOPY  :: 0x80;
