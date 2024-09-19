#+build darwin, netbsd, freebsd, openbsd
#+private
package mem_virtual

import "core:sys/posix"

// Define non-posix needed flags:
when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD {
	MAP_ANONYMOUS :: 0x1000 /* allocated from memory, swap space */

	MADV_FREE     :: 5      /* pages unneeded, discard contents */
} else when ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
	MAP_ANONYMOUS :: 0x1000

	MADV_FREE     :: 6
}

_reserve :: proc "contextless" (size: uint) -> (data: []byte, err: Allocator_Error) {
	flags  := posix.Map_Flags{ .PRIVATE } + transmute(posix.Map_Flags)i32(MAP_ANONYMOUS)
	result := posix.mmap(nil, size, {}, flags)
	if result == posix.MAP_FAILED {
		return nil, .Out_Of_Memory
	}

	return ([^]byte)(uintptr(result))[:size], nil
}

_commit :: proc "contextless" (data: rawptr, size: uint) -> Allocator_Error {
	if posix.mprotect(data, size, { .READ, .WRITE }) != .OK {
		return .Out_Of_Memory
	}

	return nil
}

_decommit :: proc "contextless" (data: rawptr, size: uint) {
	posix.mprotect(data, size, {})
	posix.posix_madvise(data, size, transmute(posix.MAdvice)i32(MADV_FREE))
}

_release :: proc "contextless" (data: rawptr, size: uint) {
	posix.munmap(data, size)
}

_protect :: proc "contextless" (data: rawptr, size: uint, flags: Protect_Flags) -> bool {
	#assert(i32(posix.Prot_Flag_Bits.READ)  == i32(Protect_Flag.Read))
	#assert(i32(posix.Prot_Flag_Bits.WRITE) == i32(Protect_Flag.Write))
	#assert(i32(posix.Prot_Flag_Bits.EXEC)  == i32(Protect_Flag.Execute))

	return posix.mprotect(data, size, transmute(posix.Prot_Flags)flags) == .OK
}

_platform_memory_init :: proc() {
	// NOTE: `posix.PAGESIZE` due to legacy reasons could be wrong so we use `sysconf`.
	size := posix.sysconf(._PAGESIZE)
	DEFAULT_PAGE_SIZE = uint(max(size, posix.PAGESIZE))

	// is power of two
	assert(DEFAULT_PAGE_SIZE != 0 && (DEFAULT_PAGE_SIZE & (DEFAULT_PAGE_SIZE-1)) == 0)
}

_map_file :: proc "contextless" (fd: uintptr, size: i64, flags: Map_File_Flags) -> (data: []byte, error: Map_File_Error) {
	#assert(i32(posix.Prot_Flag_Bits.READ)  == i32(Map_File_Flag.Read))
	#assert(i32(posix.Prot_Flag_Bits.WRITE) == i32(Map_File_Flag.Write))

	addr := posix.mmap(nil, uint(size), transmute(posix.Prot_Flags)flags, { .SHARED }, posix.FD(fd))
	if addr == posix.MAP_FAILED || addr == nil {
		return nil, .Map_Failure
	}
	return ([^]byte)(addr)[:size], nil
}
