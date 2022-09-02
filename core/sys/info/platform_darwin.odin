// +build darwin
package sysinfo

import sys "core:sys/darwin"
import "core:intrinsics"
import "core:strconv"
import "core:strings"
import "core:fmt"

@(init, private)
init_os_version :: proc () {
	os_version.platform = .MacOS

	mib := []i32{CTL_KERN, KERN_OSRELEASE}
	version_bits: [12]u8 // enough for 999.999.999\x00
	ok := sysctl(mib, &version_bits)
	if !ok {
		return
	}

	triplet := strings.split(string(cstring(&version_bits[0])), ".", context.temp_allocator)
	if len(triplet) == 3 {
		major, major_ok := strconv.parse_int(triplet[0])
		minor, minor_ok := strconv.parse_int(triplet[1])
		patch, patch_ok := strconv.parse_int(triplet[2])

		if major_ok && minor_ok && patch_ok {
			os_version.major = major
			os_version.minor = minor
			os_version.patch = patch
		}
	}
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysinfo`

	mib := []i32{CTL_HW, HW_MEMSIZE}
	mem_size: u64
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
	KERN_OSTYPE    :: 1  // Darwin
	KERN_OSRELEASE :: 2  // 21.5.0 for 12.4 Monterey 
	KERN_OSREV     :: 3  // i32: system revision
	KERN_VERSION   :: 4  // Darwin Kernel Version 21.5.0: Tue Apr 26 21:08:22 PDT 2022; root:xnu-8020.121.3~4/RELEASE_X86_64
	KERN_OSRELDATE :: 26 // i32: OS release date
	KERN_OSVERSION :: 65 // Build number, e.g. 21F79
CTL_VM      :: 2
CTL_VFS     :: 3
CTL_NET     :: 4
CTL_DEBUG   :: 5
CTL_HW      :: 6
	HW_MACHINE      :: 1  // x86_64
	HW_MODEL        :: 2  // MacbookPro14,1
	HW_NCPU         :: 3  /* int: number of cpus */
	HW_BYTEORDER    :: 4  /* int: machine byte order */
	HW_MACHINE_ARCH :: 12 /* string: machine architecture */
	HW_VECTORUNIT   :: 13 /* int: has HW vector unit? */
	HW_MEMSIZE      :: 24 // u64
	HW_AVAILCPU     :: 25 /* int: number of available CPUs */

CTL_MACHDEP :: 7
CTL_USER    :: 8

