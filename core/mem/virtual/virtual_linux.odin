//+build linux
//+private
package mem_virtual

import "core:sys/linux"

_reserve :: proc "contextless" (size: uint) -> (data: []byte, err: Allocator_Error) {
	addr, errno := linux.mmap(0, size, {}, {.PRIVATE, .ANONYMOUS})
	if errno == .ENOMEM {
		return nil, .Out_Of_Memory
	} else if errno == .EINVAL {
		return nil, .Invalid_Argument
	}
	return (cast([^]byte)addr)[:size], nil
}

_commit :: proc "contextless" (data: rawptr, size: uint) -> Allocator_Error {
	errno := linux.mprotect(data, size, {.READ, .WRITE})
	if errno == .EINVAL {
		return .Invalid_Pointer
	} else if errno == .ENOMEM {
		return .Out_Of_Memory
	}
	return nil
}

_decommit :: proc "contextless" (data: rawptr, size: uint) {
	_ = linux.mprotect(data, size, {})
	_ = linux.madvise(data, size, .FREE)
}

_release :: proc "contextless" (data: rawptr, size: uint) {
	_ = linux.munmap(data, size)
}

_protect :: proc "contextless" (data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	pflags: linux.Mem_Protection
	pflags = {}
	if .Read    in flags { pflags += {.READ}  }
	if .Write   in flags { pflags += {.WRITE} }
	if .Execute in flags { pflags += {.EXEC}  }
	errno := linux.mprotect(data, size, pflags)
	return errno == .NONE
}

_platform_memory_init :: proc() {
	DEFAULT_PAGE_SIZE = 4096
	// is power of two
	assert(DEFAULT_PAGE_SIZE != 0 && (DEFAULT_PAGE_SIZE & (DEFAULT_PAGE_SIZE-1)) == 0)
}


_map_file :: proc "contextless" (fd: uintptr, size: i64, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	prot: linux.Mem_Protection
	if .Read in flags {
		prot += {.READ}
	}
	if .Write in flags {
		prot += {.WRITE}
	}

	flags := linux.Map_Flags{.SHARED}
	addr, errno := linux.mmap(0, uint(size), prot, flags, linux.Fd(fd), offset=0)
	if addr == nil || errno != nil {
		return nil, .Map_Failure
	}
	return ([^]byte)(addr)[:size], nil
}
