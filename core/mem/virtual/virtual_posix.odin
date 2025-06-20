#+build darwin, netbsd, freebsd, openbsd
#+private
package mem_virtual

import "core:sys/posix"

_commit :: proc "contextless" (data: rawptr, size: uint) -> Allocator_Error {
	if posix.mprotect(data, size, { .READ, .WRITE }) != .OK {
		#partial switch posix.errno() {
		case .EACCES, .EPERM:   return .Invalid_Pointer
		case .ENOTSUP, .EINVAL: return .Invalid_Argument
		case:                   return .Out_Of_Memory
		}
	}

	return nil
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
