package unix

import "core:c"
foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
	@(link_name="sysctl") _unix_sysctl :: proc(name: [^]i32, namelen: u32, oldp: rawptr, oldlenp: ^c.size_t, newp: rawptr, newlen: c.size_t) -> i32 ---
}

sysctl :: proc(mib: []i32, val: ^$T) -> (ok: bool) {
	mib := mib
	result_size := c.size_t(size_of(T))
	res := _unix_sysctl(raw_data(mib), u32(len(mib)), val, &result_size, nil, 0)
	return res == 0
}

// See /usr/include/sys/sysctl.h for details
CTL_KERN   :: 1
	KERN_OSTYPE     :: 1
	KERN_OSRELEASE  :: 2
	KERN_OSREV      :: 3
	KERN_VERSION    :: 4
CTL_VM     :: 2
CTL_FS     :: 3
CTL_NET    :: 4
CTL_DEBUG  :: 5
CTL_HW     :: 6
	HW_MACHINE      :: 1
	HW_MODEL        :: 2
	HW_NCPU         :: 3
	HW_BYTEORDER    :: 4
	HW_PHYSMEM	    :: 5
	HW_USERMEM      :: 6
	HW_PAGESIZE     :: 7
	HW_DISKNAMES    :: 8
	HW_IOSTATS      :: 9
	HW_MACHINE_ARCH :: 10
	HW_ALIGNBYTES   :: 11
	HW_CNMAGIC      :: 12
	HW_PHYSMEM64    :: 13
	HW_USERMEM64    :: 14
	HW_IOSTATNAMES  :: 15
	HW_NCPUONLINE   :: 16
