#+build linux
#+no-instrumentation
package linux

import "base:intrinsics"

/*
	Android's seccomp filter allows i386's socket system calls only through `socketcall`, which bionic makes.
	There, `socketcall_number` gives a socket system call's `socketcall` call, and the `syscall`s below make it.
*/
@(private)
SOCKETCALL :: ODIN_ARCH == .i386 && ODIN_PLATFORM_SUBTARGET == .Android

@(private)
socketcall_number :: #force_inline proc "contextless" (nr: uintptr) -> uintptr {
	when SOCKETCALL {
		switch nr {
		case SYS_socket:      return 1
		case SYS_bind:        return 2
		case SYS_connect:     return 3
		case SYS_listen:      return 4
		case SYS_getsockname: return 6
		case SYS_getpeername: return 7
		case SYS_socketpair:  return 8
		case SYS_sendto:      return 11
		case SYS_recvfrom:    return 12
		case SYS_shutdown:    return 13
		case SYS_setsockopt:  return 14
		case SYS_getsockopt:  return 15
		case SYS_sendmsg:     return 16
		case SYS_recvmsg:     return 17
		case SYS_accept4:     return 18
		case SYS_recvmmsg:    return 19
		case SYS_sendmmsg:    return 20
		}
	}
	return 0
}

// Note(flysand): In the case of syscall let's get rid of extra
// casting. First of all, let these syscalls return int, because
// we'll need to check for Errno anyway. Second of all
// most parameters are going to be trivially-castable to
// uintptr, so we'll have that.

@(private)
syscall0 :: #force_inline proc "contextless" (nr: uintptr) -> int {
	return int(intrinsics.syscall(nr))
}

@(private)
syscall1 :: #force_inline proc "contextless" (nr: uintptr, p1: $T) -> int
where
	size_of(p1) <= size_of(uintptr)
{
	return int(intrinsics.syscall(nr, uintptr(p1)))
}

@(private)
syscall2 :: #force_inline proc "contextless" (nr: uintptr,p1: $T1, p2: $T2) -> int
where
	size_of(p1) <= size_of(uintptr),
	size_of(p2) <= size_of(uintptr) 
{
	when SOCKETCALL {
		if call := socketcall_number(nr); call != 0 {
			args := [2]uintptr{uintptr(p1), uintptr(p2)}
			return int(intrinsics.syscall(SYS_socketcall, call, uintptr(&args)))
		}
	}
	return int(intrinsics.syscall(nr, uintptr(p1), uintptr(p2)))
}

@(private)
syscall3 :: #force_inline proc "contextless" (nr: uintptr, p1: $T1, p2: $T2, p3: $T3) -> int
where
	size_of(p1) <= size_of(uintptr),
	size_of(p2) <= size_of(uintptr),
	size_of(p3) <= size_of(uintptr)
{
	when SOCKETCALL {
		if call := socketcall_number(nr); call != 0 {
			args := [3]uintptr{uintptr(p1), uintptr(p2), uintptr(p3)}
			return int(intrinsics.syscall(SYS_socketcall, call, uintptr(&args)))
		}
	}
	return int(intrinsics.syscall(nr,
		uintptr(p1),
		uintptr(p2),
		uintptr(p3),
	))
}

@(private)
syscall4 :: #force_inline proc "contextless" (nr: uintptr, p1: $T1, p2: $T2, p3: $T3, p4: $T4) -> int
where
	size_of(p1) <= size_of(uintptr),
	size_of(p2) <= size_of(uintptr),
	size_of(p3) <= size_of(uintptr),
	size_of(p4) <= size_of(uintptr)
{
	when SOCKETCALL {
		if call := socketcall_number(nr); call != 0 {
			args := [4]uintptr{uintptr(p1), uintptr(p2), uintptr(p3), uintptr(p4)}
			return int(intrinsics.syscall(SYS_socketcall, call, uintptr(&args)))
		}
	}
	return int(intrinsics.syscall(nr,
		uintptr(p1),
		uintptr(p2),
		uintptr(p3),
		uintptr(p4),
	))
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
	when SOCKETCALL {
		if call := socketcall_number(nr); call != 0 {
			args := [5]uintptr{uintptr(p1), uintptr(p2), uintptr(p3), uintptr(p4), uintptr(p5)}
			return int(intrinsics.syscall(SYS_socketcall, call, uintptr(&args)))
		}
	}
	return int(intrinsics.syscall(nr,
		uintptr(p1),
		uintptr(p2),
		uintptr(p3),
		uintptr(p4),
		uintptr(p5),
	))
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
	when SOCKETCALL {
		if call := socketcall_number(nr); call != 0 {
			args := [6]uintptr{uintptr(p1), uintptr(p2), uintptr(p3), uintptr(p4), uintptr(p5), uintptr(p6)}
			return int(intrinsics.syscall(SYS_socketcall, call, uintptr(&args)))
		}
	}
	return int(intrinsics.syscall(nr,
		uintptr(p1),
		uintptr(p2),
		uintptr(p3),
		uintptr(p4),
		uintptr(p5),
		uintptr(p6),
	))
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
		return T(transmute(U)ret), Errno(.NONE)
	}
}

@(private)
errno_unwrap2 :: #force_inline proc "contextless" (ret: $P, $T: typeid) -> (T, Errno) {
	if ret < 0 {
		default_value: T
		return default_value, Errno(-ret)
	} else {
		return T(ret), Errno(.NONE)
	}
}

@(private)
errno_unwrap :: proc {errno_unwrap2, errno_unwrap3}

// Note(flysand): 32-bit architectures sometimes take in a 64-bit argument in a
// register pair. This function should help me avoid typing the same code a few times..
when size_of(int) == 4 {
	// xxx64 system calls take some parameters as pairs of ulongs rather than a single pointer
	@(private)
	compat64_arg_pair :: #force_inline proc "contextless" (a: i64) -> (lo: uint, hi: uint) {
		no_sign := u64(a)
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

