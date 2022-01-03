//+build linux
//+private
package mem_virtual

import "core:c"
import "core:intrinsics"
import "core:sys/unix"

PROT_NONE  :: 0x0
PROT_READ  :: 0x1
PROT_WRITE :: 0x2
PROT_EXEC  :: 0x4
PROT_GROWSDOWN :: 0x01000000
PROT_GROWSUP :: 0x02000000

MAP_FIXED     :: 0x1
MAP_PRIVATE   :: 0x2
MAP_SHARED    :: 0x4
MAP_ANONYMOUS :: 0x20

MADV_NORMAL      :: 0
MADV_RANDOM      :: 1
MADV_SEQUENTIAL  :: 2
MADV_WILLNEED    :: 3
MADV_DONTNEED    :: 4
MADV_FREE        :: 8
MADV_REMOVE      :: 9
MADV_DONTFORK    :: 10
MADV_DOFORK      :: 11
MADV_MERGEABLE   :: 12
MADV_UNMERGEABLE :: 13
MADV_HUGEPAGE    :: 14
MADV_NOHUGEPAGE  :: 15
MADV_DONTDUMP    :: 16
MADV_DODUMP      :: 17
MADV_WIPEONFORK  :: 18
MADV_KEEPONFORK  :: 19
MADV_HWPOISON    :: 100

mmap :: proc "contextless" (addr: rawptr, length: uint, prot: c.int, flags: c.int, fd: c.int, offset: uintptr) -> rawptr {
	res := intrinsics.syscall(unix.SYS_mmap, uintptr(addr), uintptr(length), uintptr(prot), uintptr(flags), uintptr(fd), offset)
	return rawptr(res)
}

munmap :: proc "contextless" (addr: rawptr, length: uint) -> c.int {
	res := intrinsics.syscall(unix.SYS_munmap, uintptr(addr), uintptr(length))
	return c.int(res)
}

mprotect :: proc "contextless" (addr: rawptr, length: uint, prot: c.int) -> c.int {
	res := intrinsics.syscall(unix.SYS_mprotect, uintptr(addr), uintptr(length), uint(prot))
	return c.int(res)
}

madvise :: proc "contextless" (addr: rawptr, length: uint, advice: c.int) -> c.int {
	res := intrinsics.syscall(unix.SYS_madvise, uintptr(addr), uintptr(length), uintptr(advice))
	return c.int(res)
}


_reserve :: proc(size: uint) -> (data: []byte, err: Allocator_Error) {
	MAP_FAILED := rawptr(~uintptr(0))
	result := mmap(nil, size, PROT_NONE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)
	if result == MAP_FAILED {
		return nil, .Out_Of_Memory
	}
	return ([^]byte)(result)[:size], nil
}

_commit :: proc(data: rawptr, size: uint) -> Allocator_Error {
	result := mprotect(data, size, PROT_READ|PROT_WRITE)
	if result != 0 {
		// TODO(bill): Handle error value correctly
		return .Out_Of_Memory
	}
	return nil
}
_decommit :: proc(data: rawptr, size: uint) {
	mprotect(data, size, PROT_NONE)
	madvise(data, size, MADV_FREE)
}
_release :: proc(data: rawptr, size: uint) {
	munmap(data, size)
}
_protect :: proc(data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	pflags: c.int
	pflags = PROT_NONE
	if .Read    in flags { pflags |= PROT_READ  }
	if .Write   in flags { pflags |= PROT_WRITE }
	if .Execute in flags { pflags |= PROT_EXEC  }
	err := mprotect(data, size, pflags)
	return err != 0
}



_platform_memory_init :: proc() {
	DEFAULT_PAGE_SIZE = 4096
	
	// is power of two
	assert(DEFAULT_PAGE_SIZE != 0 && (DEFAULT_PAGE_SIZE & (DEFAULT_PAGE_SIZE-1)) == 0)
}
