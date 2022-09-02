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

// See sysctl.h for xnu/dwrwin for details
CTL_KERN    :: 1
	KERN_OSTYPE    :: 1  /* string: system version */
	KERN_OSRELEASE :: 2  /* string: system release */
	KERN_OSREV     :: 3  /* int: system revision */
	KERN_VERSION   :: 4  /* string: compile time info */
	KERN_OSRELDATE :: 26 /* int: OS release date */
	KERN_OSVERSION :: 65 /* for build number i.e. 9A127 */
CTL_VM      :: 2
CTL_VFS     :: 3
CTL_NET     :: 4
CTL_DEBUG   :: 5
CTL_HW      :: 6
	HW_MACHINE      :: 1  /* string: machine class */
	HW_MODEL        :: 2  /* string: specific machine model */
	HW_NCPU         :: 3  /* int: number of cpus */
	HW_BYTEORDER    :: 4  /* int: machine byte order */
	HW_MACHINE_ARCH :: 12 /* string: machine architecture */
	HW_VECTORUNIT   :: 13 /* int: has HW vector unit? */
	HW_MEMSIZE      :: 24 /* uint64_t: physical ram size */
	HW_AVAILCPU     :: 25 /* int: number of available CPUs */

CTL_MACHDEP :: 7
CTL_USER    :: 8

