//+build darwin
package unix

import "core:sys/darwin"
import "core:intrinsics"

_ :: darwin

sysctl :: proc(mib: []i32, val: ^$T) -> (ok: bool) {
	mib := mib
	result_size := i64(size_of(T))

	res := intrinsics.syscall(
		darwin.unix_offset_syscall(.sysctl),
		uintptr(raw_data(mib)), uintptr(len(mib)),
		uintptr(val), uintptr(&result_size),
		uintptr(0), uintptr(0),
	)
	return res == 0
}

// See sysctl.h for darwin for details
CTL_KERN    :: 1
	KERN_OSTYPE    :: 1  // Darwin
	KERN_OSRELEASE :: 2  // 21.5.0 for 12.4 Monterey
	KERN_OSREV     :: 3  // i32: system revision
	KERN_VERSION   :: 4  // Darwin Kernel Version 21.5.0: Tue Apr 26 21:08:22 PDT 2022; root:darwin-8020.121.3~4/RELEASE_X86_64
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