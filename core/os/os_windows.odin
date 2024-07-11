// +build windows
package os

import win32 "core:sys/windows"
import "base:runtime"
import "base:intrinsics"

Handle    :: distinct uintptr
File_Time :: distinct u64
Errno     :: distinct int


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


ERROR_NONE:                   Errno : 0
ERROR_FILE_NOT_FOUND:         Errno : 2
ERROR_PATH_NOT_FOUND:         Errno : 3
ERROR_ACCESS_DENIED:          Errno : 5
ERROR_INVALID_HANDLE:         Errno : 6
ERROR_NOT_ENOUGH_MEMORY:      Errno : 8
ERROR_NO_MORE_FILES:          Errno : 18
ERROR_HANDLE_EOF:             Errno : 38
ERROR_NETNAME_DELETED:        Errno : 64
ERROR_FILE_EXISTS:            Errno : 80
ERROR_INVALID_PARAMETER:      Errno : 87
ERROR_BROKEN_PIPE:            Errno : 109
ERROR_BUFFER_OVERFLOW:        Errno : 111
ERROR_INSUFFICIENT_BUFFER:    Errno : 122
ERROR_MOD_NOT_FOUND:          Errno : 126
ERROR_PROC_NOT_FOUND:         Errno : 127
ERROR_DIR_NOT_EMPTY:          Errno : 145
ERROR_ALREADY_EXISTS:         Errno : 183
ERROR_ENVVAR_NOT_FOUND:       Errno : 203
ERROR_MORE_DATA:              Errno : 234
ERROR_OPERATION_ABORTED:      Errno : 995
ERROR_IO_PENDING:             Errno : 997
ERROR_NOT_FOUND:              Errno : 1168
ERROR_PRIVILEGE_NOT_HELD:     Errno : 1314
WSAEACCES:                    Errno : 10013
WSAECONNRESET:                Errno : 10054

// Windows reserves errors >= 1<<29 for application use
ERROR_FILE_IS_PIPE:           Errno : 1<<29 + 0
ERROR_FILE_IS_NOT_DIR:        Errno : 1<<29 + 1
ERROR_NEGATIVE_OFFSET:        Errno : 1<<29 + 2

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments()





last_write_time :: proc(fd: Handle) -> (File_Time, Errno) {
	file_info: win32.BY_HANDLE_FILE_INFORMATION
	if !win32.GetFileInformationByHandle(win32.HANDLE(fd), &file_info) {
		return 0, Errno(win32.GetLastError())
	}
	lo := File_Time(file_info.ftLastWriteTime.dwLowDateTime)
	hi := File_Time(file_info.ftLastWriteTime.dwHighDateTime)
	return lo | hi << 32, ERROR_NONE
}

last_write_time_by_name :: proc(name: string) -> (File_Time, Errno) {
	data: win32.WIN32_FILE_ATTRIBUTE_DATA

	wide_path := win32.utf8_to_wstring(name)
	if !win32.GetFileAttributesExW(wide_path, win32.GetFileExInfoStandard, &data) {
		return 0, Errno(win32.GetLastError())
	}

	l := File_Time(data.ftLastWriteTime.dwLowDateTime)
	h := File_Time(data.ftLastWriteTime.dwHighDateTime)
	return l | h << 32, ERROR_NONE
}


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

@(private)
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



current_thread_id :: proc "contextless" () -> int {
	return int(win32.GetCurrentThreadId())
}



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

get_windows_version_w :: proc() -> win32.OSVERSIONINFOEXW {
	osvi : win32.OSVERSIONINFOEXW
	osvi.dwOSVersionInfoSize = size_of(win32.OSVERSIONINFOEXW)
	win32.RtlGetVersion(&osvi)
	return osvi
}

is_windows_xp :: proc() -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 5 && osvi.dwMinorVersion == 1)
}

is_windows_vista :: proc() -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 0)
}

is_windows_7 :: proc() -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 1)
}

is_windows_8 :: proc() -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 2)
}

is_windows_8_1 :: proc() -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 6 && osvi.dwMinorVersion == 3)
}

is_windows_10 :: proc() -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 10 && osvi.dwMinorVersion == 0 && osvi.dwBuildNumber <  WINDOWS_11_BUILD_CUTOFF)
}

is_windows_11 :: proc() -> bool {
	osvi := get_windows_version_w()
	return (osvi.dwMajorVersion == 10 && osvi.dwMinorVersion == 0 && osvi.dwBuildNumber >= WINDOWS_11_BUILD_CUTOFF)
}
