#+private
package runtime

import "base:intrinsics"

_HAS_RAND_BYTES :: true

_stderr_write :: proc "contextless" (data: []byte) -> (int, _OS_Errno) {
	when ODIN_ARCH == .amd64 {
		SYS_write :: uintptr(1)
	} else when ODIN_ARCH == .arm64 {
		SYS_write :: uintptr(64)
	} else when ODIN_ARCH == .i386 {
		SYS_write :: uintptr(4)
	} else when ODIN_ARCH == .arm32 {
		SYS_write :: uintptr(4)
	} else when ODIN_ARCH == .riscv64 {
		SYS_write :: uintptr(64)
	}

	stderr :: 2

	ret := int(intrinsics.syscall(SYS_write, uintptr(stderr), uintptr(raw_data(data)), uintptr(len(data))))
	if ret < 0 && ret > -4096 {
		return 0, _OS_Errno(-ret)
	}
	return ret, 0
}

_rand_bytes :: proc "contextless" (dst: []byte) {
	when ODIN_ARCH == .amd64 {
		SYS_getrandom :: uintptr(318)
	} else when ODIN_ARCH == .arm64 {
		SYS_getrandom :: uintptr(278)
	} else when ODIN_ARCH == .i386 {
		SYS_getrandom :: uintptr(355)
	} else when ODIN_ARCH == .arm32 {
		SYS_getrandom :: uintptr(384)
	} else when ODIN_ARCH == .riscv64 {
		SYS_getrandom :: uintptr(278)
	} else {
		#panic("base/runtime: no SYS_getrandom definition for target")
	}

	ERR_EINTR :: 4
	ERR_ENOSYS :: 38

	MAX_PER_CALL_BYTES :: 33554431 // 2^25 - 1

	dst := dst
	l := len(dst)

	for l > 0 {
		to_read := min(l, MAX_PER_CALL_BYTES)
		ret := int(intrinsics.syscall(SYS_getrandom, uintptr(raw_data(dst[:to_read])), uintptr(to_read), uintptr(0)))
		switch ret {
		case -ERR_EINTR:
			// Call interupted by a signal handler, just retry the
			// request.
			continue
		case -ERR_ENOSYS:
			// The kernel is apparently prehistoric (< 3.17 circa 2014)
			// and does not support getrandom.
			panic_contextless("base/runtime: getrandom not available in kernel")
		case:
			if ret < 0 {
				// All other failures are things that should NEVER happen
				// unless the kernel interface changes (ie: the Linux
				// developers break userland).
				panic_contextless("base/runtime: getrandom failed")
			}
		}
		l -= ret
		dst = dst[ret:]
	}
}

_exit :: proc "contextless" (code: int) -> ! {
	SYS_exit_group ::
		231 when ODIN_ARCH == .amd64 else
		248 when ODIN_ARCH == .arm32 else
		94  when ODIN_ARCH == .arm64 else
		252 when ODIN_ARCH == .i386  else
		94  when ODIN_ARCH == .riscv64 else
		0

	intrinsics.syscall(uintptr(SYS_exit_group), uintptr(i32(code)))
	unreachable()
}
