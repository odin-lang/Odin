// +build windows
package os

import win32 "core:sys/windows"
import "base:runtime"
import "base:intrinsics"

Handle    :: distinct uintptr
File_Time :: distinct u64


INVALID_HANDLE :: ~Handle(0)



O_RDONLY   :: 0x00000
O_WRONLY   :: 0x00001
O_RDWR     :: 0x00002
O_CREATE   :: 0x00040
O_EXCL     :: 0x00080
O_NOCTTY   :: 0x00100
O_TRUNC    :: 0x00200
O_NONBLOCK :: 0x00800
O_APPEND   :: 0x00400
O_SYNC     :: 0x01000
O_ASYNC    :: 0x02000
O_CLOEXEC  :: 0x80000

_Platform_Error :: win32.System_Error

ERROR_FILE_NOT_FOUND      :: _Platform_Error(2)
ERROR_PATH_NOT_FOUND      :: _Platform_Error(3)
ERROR_ACCESS_DENIED       :: _Platform_Error(5)
ERROR_INVALID_HANDLE      :: _Platform_Error(6)
ERROR_NOT_ENOUGH_MEMORY   :: _Platform_Error(8)
ERROR_NO_MORE_FILES       :: _Platform_Error(18)
ERROR_HANDLE_EOF          :: _Platform_Error(38)
ERROR_NETNAME_DELETED     :: _Platform_Error(64)
ERROR_FILE_EXISTS         :: _Platform_Error(80)
ERROR_INVALID_PARAMETER   :: _Platform_Error(87)
ERROR_BROKEN_PIPE         :: _Platform_Error(109)
ERROR_BUFFER_OVERFLOW     :: _Platform_Error(111)
ERROR_INSUFFICIENT_BUFFER :: _Platform_Error(122)
ERROR_MOD_NOT_FOUND       :: _Platform_Error(126)
ERROR_PROC_NOT_FOUND      :: _Platform_Error(127)
ERROR_NEGATIVE_SEEK       :: _Platform_Error(131)
ERROR_DIR_NOT_EMPTY       :: _Platform_Error(145)
ERROR_ALREADY_EXISTS      :: _Platform_Error(183)
ERROR_ENVVAR_NOT_FOUND    :: _Platform_Error(203)
ERROR_MORE_DATA           :: _Platform_Error(234)
ERROR_OPERATION_ABORTED   :: _Platform_Error(995)
ERROR_IO_PENDING          :: _Platform_Error(997)
ERROR_NOT_FOUND           :: _Platform_Error(1168)
ERROR_PRIVILEGE_NOT_HELD  :: _Platform_Error(1314)
WSAEACCES                 :: _Platform_Error(10013)
WSAECONNRESET             :: _Platform_Error(10054)

ERROR_FILE_IS_PIPE        :: General_Error.File_Is_Pipe
ERROR_FILE_IS_NOT_DIR     :: General_Error.Not_Dir

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments()

@(require_results, no_instrumentation)
get_last_error :: proc "contextless" () -> Error {
	err := win32.GetLastError()
	if err == 0 {
		return nil
	}
	switch err {
	case win32.ERROR_ACCESS_DENIED, win32.ERROR_SHARING_VIOLATION:
		return .Permission_Denied

	case win32.ERROR_FILE_EXISTS, win32.ERROR_ALREADY_EXISTS:
		return .Exist

	case win32.ERROR_FILE_NOT_FOUND, win32.ERROR_PATH_NOT_FOUND:
		return .Not_Exist

	case win32.ERROR_NO_DATA:
		return .Closed

	case win32.ERROR_TIMEOUT, win32.WAIT_TIMEOUT:
		return .Timeout

	case win32.ERROR_NOT_SUPPORTED:
		return .Unsupported

	case win32.ERROR_HANDLE_EOF:
		return .EOF

	case win32.ERROR_INVALID_HANDLE:
		return .Invalid_File

	case win32.ERROR_NEGATIVE_SEEK:
		return .Invalid_Offset

	case
		win32.ERROR_BAD_ARGUMENTS,
		win32.ERROR_INVALID_PARAMETER,
		win32.ERROR_NOT_ENOUGH_MEMORY,
		win32.ERROR_NO_MORE_FILES,
		win32.ERROR_LOCK_VIOLATION,
		win32.ERROR_BROKEN_PIPE,
		win32.ERROR_CALL_NOT_IMPLEMENTED,
		win32.ERROR_INSUFFICIENT_BUFFER,
		win32.ERROR_INVALID_NAME,
		win32.ERROR_LOCK_FAILED,
		win32.ERROR_ENVVAR_NOT_FOUND,
		win32.ERROR_OPERATION_ABORTED,
		win32.ERROR_IO_PENDING,
		win32.ERROR_NO_UNICODE_TRANSLATION:
		// fallthrough
	}
	return Platform_Error(err)
}


@(require_results)
last_write_time :: proc(fd: Handle) -> (File_Time, Error) {
	file_info: win32.BY_HANDLE_FILE_INFORMATION
	if !win32.GetFileInformationByHandle(win32.HANDLE(fd), &file_info) {
		return 0, get_last_error()
	}
	lo := File_Time(file_info.ftLastWriteTime.dwLowDateTime)
	hi := File_Time(file_info.ftLastWriteTime.dwHighDateTime)
	return lo | hi << 32, nil
}

@(require_results)
last_write_time_by_name :: proc(name: string) -> (File_Time, Error) {
	data: win32.WIN32_FILE_ATTRIBUTE_DATA

	wide_path := win32.utf8_to_wstring(name)
	if !win32.GetFileAttributesExW(wide_path, win32.GetFileExInfoStandard, &data) {
		return 0, get_last_error()
	}

	l := File_Time(data.ftLastWriteTime.dwLowDateTime)
	h := File_Time(data.ftLastWriteTime.dwHighDateTime)
	return l | h << 32, nil
}


@(require_results)
get_page_size :: proc() -> int {
	// NOTE(tetra): The page size never changes, so why do anything complicated
	// if we don't have to.
	@static page_size := -1
	if page_size != -1 {
		return page_size
	}

	info: win32.SYSTEM_INFO
	win32.GetSystemInfo(&info)
	page_size = int(info.dwPageSize)
	return page_size
}

@(private, require_results)
_processor_core_count :: proc() -> int {
	length : win32.DWORD = 0
	result := win32.GetLogicalProcessorInformation(nil, &length)

	thread_count := 0
	if !result && win32.GetLastError() == 122 && length > 0 {
		runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
		processors := make([]win32.SYSTEM_LOGICAL_PROCESSOR_INFORMATION, length, context.temp_allocator)

		result = win32.GetLogicalProcessorInformation(&processors[0], &length)
		if result {
			for processor in processors {
				if processor.Relationship == .RelationProcessorCore {
					thread := intrinsics.count_ones(processor.ProcessorMask)
					thread_count += int(thread)
				}
			}
		}
	}

	return thread_count
}

exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	win32.ExitProcess(win32.DWORD(code))
}



@(require_results)
current_thread_id :: proc "contextless" () -> int {
	return int(win32.GetCurrentThreadId())
}



@(require_results)
_alloc_command_line_arguments :: proc() -> []string {
	arg_count: i32
	arg_list_ptr := win32.CommandLineToArgvW(win32.GetCommandLineW(), &arg_count)
	arg_list := make([]string, int(arg_count))
	for _, i in arg_list {
		wc_str := (^win32.wstring)(uintptr(arg_list_ptr) + size_of(win32.wstring)*uintptr(i))^
		olen := win32.WideCharToMultiByte(win32.CP_UTF8, 0, wc_str, -1,
		                                  nil, 0, nil, nil)

		buf := make([]byte, int(olen))
		n := win32.WideCharToMultiByte(win32.CP_UTF8, 0, wc_str, -1,
		                               raw_data(buf), olen, nil, nil)
		if n > 0 {
			n -= 1
		}
		arg_list[i] = string(buf[:n])
	}

	return arg_list
}

/*
	Windows 11 (preview) has the same major and minor version numbers
	as Windows 10: 10 and 0 respectively.

	To determine if you're on Windows 10 or 11, we need to look at
	the build number. As far as we can tell right now, the cutoff is build 22_000.

	TODO: Narrow down this range once Win 11 is published and the last Win 10 builds
          become available.
*/
WINDOWS_11_BUILD_CUTOFF :: 22_000

@(require_results)
get_windows_version_w :: proc "contextless" () -> win32.OSVERSIONINFOEXW {
	osvi : win32.OSVERSIONINFOEXW
	osvi.dwOSVersionInfoSize = size_of(win32.OSVERSIONINFOEXW)
	win32.RtlGetVersion(&osvi)
	return osvi
}

@(require_results)
is_windows_xp :: proc "contextless" () -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 5 && osvi.dwMinorVersion == 1)
}

@(require_results)
is_windows_vista :: proc "contextless" () -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 0)
}

@(require_results)
is_windows_7 :: proc "contextless" () -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 1)
}

@(require_results)
is_windows_8 :: proc "contextless" () -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 2)
}

@(require_results)
is_windows_8_1 :: proc "contextless" () -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 3)
}

@(require_results)
is_windows_10 :: proc "contextless" () -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 10 && osvi.dwMinorVersion == 0 && osvi.dwBuildNumber <  WINDOWS_11_BUILD_CUTOFF)
}

@(require_results)
is_windows_11 :: proc "contextless" () -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 10 && osvi.dwMinorVersion == 0 && osvi.dwBuildNumber >= WINDOWS_11_BUILD_CUTOFF)
}
