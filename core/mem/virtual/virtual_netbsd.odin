package mem_virtual

import "core:sys/posix"

_reserve :: proc "contextless" (size: uint) -> (data: []byte, err: Allocator_Error) {

	PROT_MPROTECT :: proc "contextless" (flags: posix.Prot_Flags) -> posix.Prot_Flags {
		return transmute(posix.Prot_Flags)(transmute(i32)flags << 3)
	}

	result := posix.mmap(nil, size, PROT_MPROTECT({.READ, .WRITE, .EXEC}), {.ANONYMOUS, .PRIVATE})
	if result == posix.MAP_FAILED {
		assert_contextless(posix.errno() == .ENOMEM)
		return nil, .Out_Of_Memory
	}

	return ([^]byte)(uintptr(result))[:size], nil
}

_decommit :: proc "contextless" (data: rawptr, size: uint) {
	MADV_FREE :: 6

	posix.mprotect(data, size, {})
	posix.posix_madvise(data, size, transmute(posix.MAdvice)i32(MADV_FREE))
}
