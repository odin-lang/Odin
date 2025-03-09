#+private
package runtime

import "base:intrinsics"

foreign import Kernel32 "system:Kernel32.lib"
foreign import OneCore "system:OneCore.lib"

VIRTUAL_MEMORY_SUPPORTED :: true

// NOTE: Windows makes a distinction between page size and allocation
// granularity. Addresses returned from the allocation procedures are rounded
// to allocation granularity boundaries, at a minimum, not page sizes.

@(default_calling_convention="system")
foreign Kernel32 {
	GetLastError  :: proc() -> u32 ---
	GetSystemInfo :: proc(lpSystemInfo: ^SYSTEM_INFO) ---
}

@(default_calling_convention="system")
foreign OneCore {
	VirtualAlloc  :: proc(lpAddress: rawptr, dwSize: uint, flAllocationType: u32, flProtect: u32) -> rawptr ---
	VirtualAlloc2 :: proc(
		Process: rawptr,
		BaseAddress: rawptr,
		Size: uint,
		AllocationType: u32,
		PageProtection: u32,
		ExtendedParameters: [^]MEM_EXTENDED_PARAMETER,
		ParameterCount: u32) -> rawptr ---
	VirtualFree :: proc(lpAddress: rawptr, dwSize: uint, dwFreeType: u32) -> b32 ---
}

SYSTEM_INFO :: struct {
	using DUMMYUNIONNAME: struct #raw_union {
		dwOemId: u32,
		using DUMMYSTRUCTNAME:struct {
			wProcessorArchitecture: u16,
			wReserved: u16,
		},
	},
	dwPageSize:                  u32,
	lpMinimumApplicationAddress: rawptr,
	lpMaximumApplicationAddress: rawptr,
	dwActiveProcessorMask:       uint,
	dwNumberOfProcessors:        u32,
	dwProcessorType:             u32,
	dwAllocationGranularity:     u32,
	wProcessorLevel:             u16,
	wProcessorRevision:          u16,
}

MemExtendedParameterAddressRequirements :: 0x01
MEM_EXTENDED_PARAMETER_TYPE_BITS :: 8

MEM_ADDRESS_REQUIREMENTS :: struct {
	LowestStartingAddress: rawptr,
	HighestEndingAddress: rawptr,
	Alignment: uint,
}

MEM_EXTENDED_PARAMETER :: struct {
	using DUMMYSTRUCTNAME: bit_field u64 {
		Type:     u64 | MEM_EXTENDED_PARAMETER_TYPE_BITS,
		Reserved: u64 | 64 - MEM_EXTENDED_PARAMETER_TYPE_BITS,
	},
	using DUMMYUNIONNAME: struct #raw_union {
		ULong64: u64,
		Pointer: rawptr,
		Size:    uint,
		Handle:  rawptr,
		ULong:   u32,
	},
}


MEM_COMMIT     :: 0x00001000
MEM_RESERVE    :: 0x00002000
MEM_RELEASE    :: 0x00008000

PAGE_READWRITE :: 0x04

_allocate_virtual_memory :: proc "contextless" (size: int) -> rawptr {
	// `Size` must be a multiple of the page size.
	rounded_size := size
	if rounded_size % PAGE_SIZE != 0 {
		rounded_size = (size / PAGE_SIZE + 1) * PAGE_SIZE
	}
	result := VirtualAlloc(nil, uint(rounded_size), MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE)
	if result == nil {
		return nil
	}
	return rawptr(result)
}

_allocate_virtual_memory_superpage :: proc "contextless" () -> rawptr {
	// TODO: Windows has support for Large Pages, but its usage requires privilege escalation.
	return _allocate_virtual_memory_aligned(SUPERPAGE_SIZE, SUPERPAGE_SIZE)
}

_allocate_virtual_memory_aligned :: proc "contextless" (size: int, alignment: int) -> rawptr {
	sys_info: SYSTEM_INFO
	GetSystemInfo(&sys_info)
	if alignment <= int(sys_info.dwAllocationGranularity) {
		// The alignment is less than or equal to the allocation granularity,
		// which means it will automatically be aligned and any request for
		// alignment less than the allocation granularity will result in
		// ERROR_INVALID_PARAMETER.
		return _allocate_virtual_memory(size)
	}
	addr_req := MEM_ADDRESS_REQUIREMENTS{
		LowestStartingAddress = nil,
		HighestEndingAddress = nil,
		Alignment = uint(alignment),
	}
	param := MEM_EXTENDED_PARAMETER{
		Type = MemExtendedParameterAddressRequirements,
		Pointer = &addr_req,
	}
	// `Size` must be a multiple of the page size.
	rounded_size := size
	if rounded_size % PAGE_SIZE != 0 {
		rounded_size = (size / PAGE_SIZE + 1) * PAGE_SIZE
	}
	result := VirtualAlloc2(nil, nil, uint(rounded_size), MEM_COMMIT|MEM_RESERVE, PAGE_READWRITE, &param, 1)
	if result == nil {
		return nil
	}
	return rawptr(result)
}

_free_virtual_memory :: proc "contextless" (ptr: rawptr, size: int) {
	VirtualFree(ptr, 0, MEM_RELEASE)
}

_resize_virtual_memory :: proc "contextless" (ptr: rawptr, old_size: int, new_size: int, alignment: int) -> rawptr {
	// There is no system support for resizing addresses returned by VirtualAlloc.
	// All we can do is request a new address, copy the data, and free the old.
	result: rawptr = ---
	if alignment == 0 {
		result = _allocate_virtual_memory(new_size)
	} else {
		result = _allocate_virtual_memory_aligned(new_size, alignment)
	}
	intrinsics.mem_copy_non_overlapping(result, ptr, min(new_size, old_size))
	VirtualFree(ptr, 0, MEM_RELEASE)
	return result
}
