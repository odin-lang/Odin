// +build darwin
package sysinfo

import sys "core:sys/darwin"
import "core:intrinsics"

@(init, private)
init_os_version :: proc "c" () {
	os_version = {}
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysinfo`

	CTL_HW     :: 6
	HW_MEMSIZE :: 24

	sysctls := []int{CTL_HW, HW_MEMSIZE}

	mem_size: i64

	if intrinsics.syscall(
		uintptr(sys.System_Call_Number.sysctl),
		uintptr(raw_data(sysctls)), uintptr(len(sysctls)),
		uintptr(&mem_size), uintptr(size_of(mem_size))) == 0 {
		return
	}
	ram.total_ram = int(mem_size)
}

@(private)
sysctl :: proc(leaf: int)