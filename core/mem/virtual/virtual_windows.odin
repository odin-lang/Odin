//+build windows
//+private
package mem_virtual

import "core:mem"

foreign import Kernel32 "system:Kernel32.lib"

LPSYSTEM_INFO :: ^SYSTEM_INFO
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

MEM_COMMIT      :: 0x00001000
MEM_RESERVE     :: 0x00002000
MEM_RESET       :: 0x00080000
MEM_RESET_UNDO  :: 0x01000000
MEM_LARGE_PAGES :: 0x20000000
MEM_PHYSICAL    :: 0x00400000
MEM_TOP_DOWN    :: 0x00100000
MEM_WRITE_WATCH :: 0x00200000

MEM_DECOMMIT :: 0x00004000
MEM_RELEASE  :: 0x00008000

MEM_COALESCE_PLACEHOLDERS :: 0x00000001
MEM_PRESERVE_PLACEHOLDER  :: 0x00000002

PAGE_EXECUTE           :: 0x10
PAGE_EXECUTE_READ      :: 0x20
PAGE_EXECUTE_READWRITE :: 0x40
PAGE_EXECUTE_WRITECOPY :: 0x80
PAGE_NOACCESS          :: 0x01
PAGE_READONLY          :: 0x02
PAGE_READWRITE         :: 0x04
PAGE_WRITECOPY         :: 0x08
PAGE_TARGETS_INVALID   :: 0x40000000
PAGE_TARGETS_NO_UPDATE :: 0x40000000

foreign Kernel32 {
	GetSystemInfo  :: proc(lpSystemInfo: LPSYSTEM_INFO) ---
	VirtualAlloc   :: proc(lpAddress: rawptr, dwSize: uint, flAllocationType: u32, flProtect: u32) -> rawptr ---
	VirtualFree    :: proc(lpAddress: rawptr, dwSize: uint, dwFreeType: u32) -> b32 ---
	VirtualProtect :: proc(lpAddress: rawptr, dwSize: uint, flNewProtect: u32, lpflOldProtect: ^u32) -> b32 ---
}


_platform_memory_init :: proc() {
	sys_info: SYSTEM_INFO
	GetSystemInfo(&sys_info)
	DEFAULT_PAGE_SIZE = max(DEFAULT_PAGE_SIZE, int(sys_info.dwPageSize))
	assert(mem.is_power_of_two(uintptr(DEFAULT_PAGE_SIZE)))
}

_platform_memory_alloc :: proc(total_size: int) -> (pmblock: ^Platform_Memory_Block, err: mem.Allocator_Error) {
	pmblock = (^Platform_Memory_Block)(VirtualAlloc(nil, uint(total_size), MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE))
	if pmblock == nil {
		err = .Out_Of_Memory
	}
	return 
}


_platform_memory_free :: proc(block: ^Platform_Memory_Block) {
	VirtualFree(block, 0, MEM_RELEASE)
}

_platform_memory_protect :: proc(memory: rawptr, size: int) -> bool {
	old_protect: u32
	ok := VirtualProtect(memory, uint(size), PAGE_NOACCESS, &old_protect)
	return bool(ok)
}