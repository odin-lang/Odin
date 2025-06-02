.set SYS_mmap, 197

.global __netbsd_sys_mmap

// This is a workaround for NetBSD's standard mmap syscall needing seven
// arguments (one of which is useless). The seventh must go on the stack,
// and our syscall intrinsics do not currently handle stack-based arguments.
.section .text
__netbsd_sys_mmap:
	// These are the arguments for SYS_mmap.
	//
	// addr:  void*
	// len:   size_t
	// prot:  int
	// flags: int
	// fd:    int
	// PAD:   long (unused)
	// pos:   off_t

	mov x17, SYS_mmap
	svc #0

	cset x1, cc
