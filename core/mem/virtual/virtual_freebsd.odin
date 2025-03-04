package mem_virtual

import "core:sys/posix"

_reserve :: proc "contextless" (size: uint) -> (data: []byte, err: Allocator_Error) {

	PROT_MAX :: proc "contextless" (flags: posix.Prot_Flags) -> posix.Prot_Flags {
		_PROT_MAX_SHIFT :: 16
		return transmute(posix.Prot_Flags)(transmute(i32)flags << _PROT_MAX_SHIFT)
	}

	result := posix.mmap(nil, size, PROT_MAX({.READ, .WRITE, .EXEC}), {.ANONYMOUS, .PRIVATE})
	if result == posix.MAP_FAILED {
		assert_contextless(posix.errno() == .ENOMEM)
		return nil, .Out_Of_Memory
	}

	return ([^]byte)(uintptr(result))[:size], nil
}

_decommit :: proc "contextless" (data: rawptr, size: uint) {
	MADV_FREE :: 5

	posix.mprotect(data, size, {})
	posix.posix_madvise(data, size, transmute(posix.MAdvice)i32(MADV_FREE))
}
