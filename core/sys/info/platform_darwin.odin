// +build darwin
package sysinfo

import sys "core:sys/darwin"
import "core:intrinsics"
import "core:fmt"

@(init, private)
init_os_version :: proc "c" () {
	os_version = {}
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysinfo`

	CTL_HW     :: 6
	HW_MEMSIZE :: 24

	sysctls := []i32{CTL_HW, HW_MEMSIZE}

	result: i64
	result_size := i64(size_of(result))

	res := intrinsics.syscall(
		sys.unix_offset_syscall(.sysctl),
		uintptr(&sysctls[0]), uintptr(2),
		uintptr(&result), uintptr(&result_size),
		uintptr(0), uintptr(0),
	)
	fmt.println(res, result)
	
	ram.total_ram = int(result)
}

@(private)
sysctl :: proc(leaf: int)