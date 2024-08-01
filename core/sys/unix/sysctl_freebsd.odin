//+build freebsd
package unix

import "base:intrinsics"

sysctl :: proc(mib: []i32, val: ^$T) -> (ok: bool) {
	mib := mib
	result_size := u64(size_of(T))

	res: uintptr
	res, ok = intrinsics.syscall_bsd(SYS_sysctl,
		uintptr(raw_data(mib)), uintptr(len(mib)),
		uintptr(val), uintptr(&result_size),
		uintptr(0), uintptr(0),
	)
	return
}

// See /usr/include/sys/sysctl.h for details
CTL_SYSCTL :: 0
CTL_KERN   :: 1
	KERN_OSTYPE    :: 1
	KERN_OSRELEASE :: 2
	KERN_OSREV     :: 3
	KERN_VERSION   :: 4
	KERN_PROC      :: 14
		KERN_PROC_PATHNAME :: 12
CTL_VM     :: 2
CTL_VFS    :: 3
CTL_NET    :: 4
CTL_DEBUG  :: 5
CTL_HW     :: 6
	HW_MACHINE      ::  1
	HW_MODEL        ::  2
	HW_NCPU         ::  3
	HW_BYTEORDER    ::  4
	HW_PHYSMEM      ::  5
	HW_USERMEM      ::  6
	HW_PAGESIZE     ::  7
	HW_DISKNAMES    ::  8
	HW_DISKSTATS    ::  9
	HW_FLOATINGPT   :: 10
	HW_MACHINE_ARCH :: 11
	HW_REALMEM      :: 12
CTL_MACHDEP  :: 7
CTL_USER     :: 8
CTL_P1003_1B :: 9
