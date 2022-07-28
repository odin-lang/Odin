//+build windows
//+private
package mem_virtual

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

ERROR_INVALID_ADDRESS :: 487

@(default_calling_convention="stdcall")
foreign Kernel32 {
	GetSystemInfo  :: proc(lpSystemInfo: LPSYSTEM_INFO) ---
	VirtualAlloc   :: proc(lpAddress: rawptr, dwSize: uint, flAllocationType: u32, flProtect: u32) -> rawptr ---
	VirtualFree    :: proc(lpAddress: rawptr, dwSize: uint, dwFreeType: u32) -> b32 ---
	VirtualProtect :: proc(lpAddress: rawptr, dwSize: uint, flNewProtect: u32, lpflOldProtect: ^u32) -> b32 ---
	GetLastError   :: proc() -> u32 ---
}


_reserve :: proc "contextless" (size: uint) -> (data: []byte, err: Allocator_Error) {
	result := VirtualAlloc(nil, size, MEM_RESERVE, PAGE_READWRITE)
	if result == nil {
		err = .Out_Of_Memory
		return
	}
	data = ([^]byte)(result)[:size]
	return
}

_commit :: proc "contextless" (data: rawptr, size: uint) -> Allocator_Error {
	result := VirtualAlloc(data, size, MEM_COMMIT, PAGE_READWRITE)
	if result == nil {
		switch err := GetLastError(); err {
		case ERROR_INVALID_ADDRESS:
			return .Out_Of_Memory
		}

		// TODO(bill): Handle errors correctly
		return .Invalid_Argument
	}
	return nil
}
_decommit :: proc "contextless" (data: rawptr, size: uint) {
	VirtualFree(data, size, MEM_DECOMMIT)
}
_release :: proc "contextless" (data: rawptr, size: uint) {
	VirtualFree(data, 0, MEM_RELEASE)
}
_protect :: proc "contextless" (data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	pflags: u32
	pflags = PAGE_NOACCESS
	switch flags {
	case {}:                        pflags = PAGE_NOACCESS
	case {.Read}:                   pflags = PAGE_READONLY
	case {.Read, .Write}:           pflags = PAGE_READWRITE
	case {.Write}:                  pflags = PAGE_WRITECOPY
	case {.Execute}:                pflags = PAGE_EXECUTE
	case {.Execute, .Read}:         pflags = PAGE_EXECUTE_READ
	case {.Execute, .Read, .Write}: pflags = PAGE_EXECUTE_READWRITE
	case {.Execute, .Write}:        pflags = PAGE_EXECUTE_WRITECOPY
	case: 
		return false
	}
	
	
	old_protect: u32
	ok := VirtualProtect(data, size, pflags, &old_protect)
	return bool(ok)
}



_platform_memory_init :: proc() {
	sys_info: SYSTEM_INFO
	GetSystemInfo(&sys_info)
	DEFAULT_PAGE_SIZE = max(DEFAULT_PAGE_SIZE, uint(sys_info.dwPageSize))
	
	// is power of two
	assert(DEFAULT_PAGE_SIZE != 0 && (DEFAULT_PAGE_SIZE & (DEFAULT_PAGE_SIZE-1)) == 0)
}
