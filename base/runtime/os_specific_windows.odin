#+build windows
#+private
package runtime

foreign import kernel32 "system:Kernel32.lib"

@(private="file")
@(default_calling_convention="system")
foreign kernel32 {
	// NOTE(bill): The types are not using the standard names (e.g. DWORD and LPVOID) to just minimizing the dependency

	// stderr_write
	GetStdHandle         :: proc(which: u32) -> rawptr ---
	SetHandleInformation :: proc(hObject: rawptr, dwMask: u32, dwFlags: u32) -> b32 ---
	WriteFile            :: proc(hFile: rawptr, lpBuffer: rawptr, nNumberOfBytesToWrite: u32, lpNumberOfBytesWritten: ^u32, lpOverlapped: rawptr) -> b32 ---
	GetLastError         :: proc() -> u32 ---
}

_stderr_write :: proc "contextless" (data: []byte) -> (n: int, err: _OS_Errno) #no_bounds_check {
	if len(data) == 0 {
		return 0, 0
	}

	STD_ERROR_HANDLE :: ~u32(0) -12 + 1
	HANDLE_FLAG_INHERIT :: 0x00000001
	MAX_RW :: 1<<30

	h := GetStdHandle(STD_ERROR_HANDLE)
	when size_of(uintptr) == 8 {
		SetHandleInformation(h, HANDLE_FLAG_INHERIT, 0)
	}

	single_write_length: u32
	total_write: i64
	length := i64(len(data))

	for total_write < length {
		remaining := length - total_write
		to_write := u32(min(i32(remaining), MAX_RW))

		e := WriteFile(h, &data[total_write], to_write, &single_write_length, nil)
		if single_write_length <= 0 || !e {
			err = _OS_Errno(GetLastError())
			n = int(total_write)
			return
		}
		total_write += i64(single_write_length)
	}
	n = int(total_write)
	return
}
