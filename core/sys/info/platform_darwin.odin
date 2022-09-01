// +build darwin
package sysinfo

import sys "core:sys/darwin"
import "core:intrinsics"

@(init, private)
init_os_version :: proc "c" () {
	os_version.platform = .MacOS
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysinfo`

	CTL_HW     :: 6
	HW_MEMSIZE :: 24

	mib := []i32{CTL_HW, HW_MEMSIZE}
	mem_size: i64
	ok := sysctl(mib, &mem_size)
	ram.total_ram = int(mem_size)
}

@(private)
sysctl :: proc(mib: []i32, val: ^$T) -> (ok: bool) {
	mib := mib
	result_size := i64(size_of(T))

	res := intrinsics.syscall(
		sys.unix_offset_syscall(.sysctl),
		uintptr(raw_data(mib)), uintptr(len(mib)),
		uintptr(val), uintptr(&result_size),
		uintptr(0), uintptr(0),
	)
	return res == 0
}