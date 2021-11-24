package unix

import "core:intrinsics"

// Linux has inconsistent system call numbering across architectures,
// for largely historical reasons.  This attempts to provide a unified
// Odin-side interface for system calls that are required for the core
// library to work.

// For authorative system call numbers, the following files in the kernel
// source can be used:
//
//  amd64: arch/x86/entry/syscalls/syscall_64.tbl
//  arm64: include/uapi/asm-generic/unistd.h
//  386: arch/x86/entry/syscalls/sycall_32.tbl
//  arm: arch/arm/tools/syscall.tbl

when ODIN_ARCH == "amd64" {
	SYS_mmap : uintptr : 9
	SYS_mprotect : uintptr : 10
	SYS_munmap : uintptr : 11
	SYS_madvise : uintptr : 28
	SYS_futex : uintptr : 202
	SYS_gettid : uintptr : 186
	SYS_getrandom : uintptr : 318
} else when ODIN_ARCH == "arm64" {
	SYS_mmap : uintptr : 222
	SYS_mprotect : uintptr : 226
	SYS_munmap : uintptr : 215
	SYS_madvise : uintptr : 233
	SYS_futex : uintptr : 98
	SYS_gettid : uintptr : 178
	SYS_getrandom : uintptr : 278
} else when ODIN_ARCH == "386" {
	SYS_mmap : uintptr : 192 // 90 is "sys_old_mmap", we want mmap2
	SYS_mprotect : uintptr : 125
	SYS_munmap : uintptr : 91
	SYS_madvise : uintptr : 219
	SYS_futex : uintptr : 240
	SYS_gettid : uintptr : 224
	SYS_getrandom : uintptr : 355
} else when ODIN_ARCH == "arm" {
	SYS_mmap : uintptr : 192 // 90 is "sys_old_mmap", we want mmap2
	SYS_mprotect : uintptr : 125
	SYS_munmap: uintptr : 91
	SYS_madvise: uintptr : 220
	SYS_futex : uintptr : 240
	SYS_gettid : uintptr: 224
	SYS_getrandom : uintptr : 384
} else {
	#panic("Unsupported architecture")
}

sys_gettid :: proc "contextless" () -> int {
	return cast(int)intrinsics.syscall(SYS_gettid)
}

sys_getrandom :: proc "contextless" (buf: ^byte, buflen: int, flags: uint) -> int {
	return cast(int)intrinsics.syscall(SYS_getrandom, buf, cast(uintptr)(buflen), cast(uintptr)(flags))
}
