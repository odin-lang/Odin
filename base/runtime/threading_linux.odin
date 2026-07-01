#+private
package runtime

import "base:intrinsics"

when ODIN_ARCH == .amd64 {
	SYS_gettid :: uintptr(186)
} else when ODIN_ARCH == .arm32 {
	SYS_gettid :: uintptr(224)
} else when ODIN_ARCH == .arm64 {
	SYS_gettid :: uintptr(178)
} else when ODIN_ARCH == .i386 {
	SYS_gettid :: uintptr(224)
} else when ODIN_ARCH == .riscv64 {
	SYS_gettid :: uintptr(178)
} else {
	#panic("Syscall numbers related to threading are missing for this Linux architecture.")
}

_get_current_thread_id :: proc "contextless" () -> int {
	return int(intrinsics.syscall(SYS_gettid))
}
