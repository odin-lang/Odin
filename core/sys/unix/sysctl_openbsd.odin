#+build openbsd
package unix

import "core:c"
foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	@(link_name="sysctl")	_unix_sysctl    :: proc(name: [^]i32, namelen: u32, oldp: rawptr, oldlenp: ^c.size_t, newp: rawptr, newlen: c.size_t) -> i32 ---
}

sysctl :: proc(mib: []i32, val: ^$T) -> (ok: bool) {
	mib := mib
	result_size := c.size_t(size_of(T))
	res := _unix_sysctl(raw_data(mib), u32(len(mib)), val, &result_size, nil, 0)
	return res == 0
}

// See /usr/include/sys/sysctl.h for details
CTL_SYSCTL :: 0
CTL_KERN   :: 1
	KERN_OSTYPE    :: 1
	KERN_OSRELEASE :: 2
	KERN_OSREV     :: 3
	KERN_VERSION   :: 4
CTL_VM     :: 2
CTL_FS     :: 3
CTL_NET    :: 4
CTL_DEBUG  :: 5
CTL_HW     :: 6
	HW_MACHINE   ::  1
	HW_MODEL     ::  2
	HW_NCPU      ::  3
	HW_BYTEORDER ::  4
	HW_PHYSMEM   ::  5
	HW_USERMEM   ::  6
	HW_PAGESIZE  ::  7
	HW_DISKNAMES ::  8
	HW_DISKSTATS ::  9
	HW_DISKCOUNT :: 10
	HW_SENSORS   :: 11
	HW_CPUSPEED  :: 12
	HW_SETPERF   :: 13
	HW_VENDOR    :: 14
	HW_PRODUCT   :: 15
	HW_VERSION   :: 16
	HW_SERIALNO  :: 17
	HW_UUID      :: 18
	HW_PHYSMEM64 :: 19