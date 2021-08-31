//+private
//+build windows
package runtime

import "core:intrinsics"

foreign import kernel32 "system:Kernel32.lib"

@(private="file")
@(default_calling_convention="stdcall")
foreign kernel32 {
	// NOTE(bill): The types are not using the standard names (e.g. DWORD and LPVOID) to just minimizing the dependency

	// os_write
	GetStdHandle         :: proc(which: u32) -> rawptr ---
	SetHandleInformation :: proc(hObject: rawptr, dwMask: u32, dwFlags: u32) -> b32 ---
	WriteFile            :: proc(hFile: rawptr, lpBuffer: rawptr, nNumberOfBytesToWrite: u32, lpNumberOfBytesWritten: ^u32, lpOverlapped: rawptr) -> b32 ---
	GetLastError         :: proc() -> u32 ---

	// default_allocator
	GetProcessHeap :: proc() -> rawptr ---
	HeapAlloc      :: proc(hHeap: rawptr, dwFlags: u32, dwBytes: uint) -> rawptr ---
	HeapReAlloc    :: proc(hHeap: rawptr, dwFlags: u32, lpMem: rawptr, dwBytes: uint) -> rawptr ---
	HeapFree       :: proc(hHeap: rawptr, dwFlags: u32, lpMem: rawptr) -> b32 ---
}

_os_write :: proc "contextless" (data: []byte) -> (n: int, err: _OS_Errno) #no_bounds_check {
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

heap_alloc :: proc "contextless" (size: int) -> rawptr {
	HEAP_ZERO_MEMORY :: 0x00000008
	return HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, uint(size))
}
heap_resize :: proc "contextless" (ptr: rawptr, new_size: int) -> rawptr {
	if new_size == 0 {
		heap_free(ptr)
		return nil
	}
	if ptr == nil {
		return heap_alloc(new_size)
	}

	HEAP_ZERO_MEMORY :: 0x00000008
	return HeapReAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, ptr, uint(new_size))
}
heap_free :: proc "contextless" (ptr: rawptr) {
	if ptr == nil {
		return
	}
	HeapFree(GetProcessHeap(), 0, ptr)
}


//
// NOTE(tetra, 2020-01-14): The heap doesn't respect alignment.
// Instead, we overallocate by `alignment + size_of(rawptr) - 1`, and insert
// padding. We also store the original pointer returned by heap_alloc right before
// the pointer we return to the user.
//



_windows_default_alloc_or_resize :: proc "contextless" (size, alignment: int, old_ptr: rawptr = nil) -> ([]byte, Allocator_Error) {
	if size == 0 {
		_windows_default_free(old_ptr)
		return nil, nil
	}

	a := max(alignment, align_of(rawptr))
	space := size + a - 1

	allocated_mem: rawptr
	if old_ptr != nil {
		original_old_ptr := intrinsics.ptr_offset((^rawptr)(old_ptr), -1)^
		allocated_mem = heap_resize(original_old_ptr, space+size_of(rawptr))
	} else {
		allocated_mem = heap_alloc(space+size_of(rawptr))
	}
	aligned_mem := rawptr(intrinsics.ptr_offset((^u8)(allocated_mem), size_of(rawptr)))

	ptr := uintptr(aligned_mem)
	aligned_ptr := (ptr - 1 + uintptr(a)) & -uintptr(a)
	diff := int(aligned_ptr - ptr)
	if (size + diff) > space {
		return nil, .Out_Of_Memory
	}

	aligned_mem = rawptr(aligned_ptr)
	intrinsics.ptr_offset((^rawptr)(aligned_mem), -1)^ = allocated_mem

	return byte_slice(aligned_mem, size), nil
}

_windows_default_alloc :: proc "contextless" (size, alignment: int) -> ([]byte, Allocator_Error) {
	return _windows_default_alloc_or_resize(size, alignment, nil)
}


_windows_default_free :: proc "contextless" (ptr: rawptr) {
	if ptr != nil {
		heap_free(intrinsics.ptr_offset((^rawptr)(ptr), -1)^)
	}
}

_windows_default_resize :: proc "contextless" (p: rawptr, old_size: int, new_size: int, new_alignment: int) -> ([]byte, Allocator_Error) {
	return _windows_default_alloc_or_resize(new_size, new_alignment, p)
}
