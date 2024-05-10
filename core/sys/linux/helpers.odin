//+build linux
//+no-instrumentation
package linux

import "base:intrinsics"

// Note(flysand): In the case of syscall let's get rid of extra
// casting. First of all, let these syscalls return int, because
// we'll need to check for Errno anyway. Second of all
// most parameters are going to be trivially-castable to
// uintptr, so we'll have that.

@(private)
syscall0 :: #force_inline proc "contextless" (nr: uintptr) -> int {
	return cast(int) intrinsics.syscall(nr)
}

@(private)
syscall1 :: #force_inline proc "contextless" (nr: uintptr, p1: $T) -> int
where
	size_of(p1) <= size_of(uintptr)
{
	return cast(int) intrinsics.syscall(nr, cast(uintptr) p1)
}

@(private)
syscall2 :: #force_inline proc "contextless" (nr: uintptr,p1: $T1, p2: $T2) -> int
where
	size_of(p1) <= size_of(uintptr),
	size_of(p2) <= size_of(uintptr) 
{
	return cast(int) intrinsics.syscall(nr,
		cast(uintptr) p1, cast(uintptr) p2)
}

@(private)
syscall3 :: #force_inline proc "contextless" (nr: uintptr, p1: $T1, p2: $T2, p3: $T3) -> int
where
	size_of(p1) <= size_of(uintptr),
	size_of(p2) <= size_of(uintptr),
	size_of(p3) <= size_of(uintptr)
{
	return cast(int) intrinsics.syscall(nr,
		cast(uintptr) p1,
		cast(uintptr) p2,
		cast(uintptr) p3)
}

@(private)
syscall4 :: #force_inline proc "contextless" (nr: uintptr, p1: $T1, p2: $T2, p3: $T3, p4: $T4) -> int
where
	size_of(p1) <= size_of(uintptr),
	size_of(p2) <= size_of(uintptr),
	size_of(p3) <= size_of(uintptr),
	size_of(p4) <= size_of(uintptr)
{
	return cast(int) intrinsics.syscall(nr,
		cast(uintptr) p1,
		cast(uintptr) p2,
		cast(uintptr) p3,
		cast(uintptr) p4)
}

@(private)
syscall5 :: #force_inline proc "contextless" (nr: uintptr, p1: $T1, p2: $T2, p3: $T3, p4: $T4, p5: $T5) -> int
where
	size_of(p1) <= size_of(uintptr),
	size_of(p2) <= size_of(uintptr),
	size_of(p3) <= size_of(uintptr),
	size_of(p4) <= size_of(uintptr),
	size_of(p5) <= size_of(uintptr)
{
	return cast(int) intrinsics.syscall(nr,
		cast(uintptr) p1,
		cast(uintptr) p2,
		cast(uintptr) p3,
		cast(uintptr) p4,
		cast(uintptr) p5)
}

@(private)
syscall6 :: #force_inline proc "contextless" (nr: uintptr, p1: $T1, p2: $T2, p3: $T3, p4: $T4, p5: $T5, p6: $T6) -> int
where
	size_of(p1) <= size_of(uintptr),
	size_of(p2) <= size_of(uintptr),
	size_of(p3) <= size_of(uintptr),
	size_of(p4) <= size_of(uintptr),
	size_of(p5) <= size_of(uintptr),
	size_of(p6) <= size_of(uintptr)
{
	return cast(int) intrinsics.syscall(nr,
		cast(uintptr) p1,
		cast(uintptr) p2,
		cast(uintptr) p3,
		cast(uintptr) p4,
		cast(uintptr) p5,
		cast(uintptr) p6)
}

syscall :: proc {syscall0, syscall1, syscall2, syscall3, syscall4, syscall5, syscall6}

// Note(bumbread): This should shrug off a few lines from every syscall.
// Since not any type can be trivially casted to another type, we take two arguments:
// the final type to cast to, and the type to transmute to before casting.
// One transmute + one cast should allow us to get to any type we might want
// to return from a syscall wrapper.
@(private)
errno_unwrap3 :: #force_inline proc "contextless" (ret: $P, $T: typeid, $U: typeid) -> (T, Errno)
where
	intrinsics.type_is_ordered_numeric(P)
{
	if ret < 0 {
		default_value: T
		return default_value, Errno(-ret)
	} else {
		return cast(T) transmute(U) ret, Errno(.NONE)
	}
}

@(private)
errno_unwrap2 :: #force_inline proc "contextless" (ret: $P, $T: typeid) -> (T, Errno) {
	if ret < 0 {
		default_value: T
		return default_value, Errno(-ret)
	} else {
		return cast(T) ret, Errno(.NONE)
	}
}

@(private)
errno_unwrap :: proc {errno_unwrap2, errno_unwrap3}

// Note(flysand): 32-bit architectures sometimes take in a 64-bit argument in a
// register pair. This function should help me avoid typing the same code a few times..
when size_of(int) == 4 {
	// xxx64 system calls take some parameters as pairs of ulongs rather than a single pointer
	@(private)
	compat64_arg_pair :: #force_inline proc "contextless" (a: i64) -> (hi: uint, lo: uint) {
		no_sign := uint(a)
		hi = uint(no_sign >> 32)
		lo = uint(no_sign & 0xffff_ffff)
		return
	}
} else {
	// ... and on 64-bit architectures it's just a long
	@(private)
	compat64_arg_pair :: #force_inline proc "contextless" (a: i64) -> (uint) {
		return uint(a)
	}
}

