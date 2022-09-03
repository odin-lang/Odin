// +build freebsd
package sysinfo

import sys "core:sys/unix"
import "core:intrinsics"
import "core:strings"
import "core:strconv"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	os_version.platform = .FreeBSD

	kernel_version_buf: [129]u8

	b := strings.builder_from_bytes(version_string_buf[:])
	// Retrieve kernel info using `sysctl`, e.g. FreeBSD 13.1-RELEASE-p2 GENERIC
	mib := []i32{CTL_KERN, KERN_VERSION}
	if !sysctl(mib, &kernel_version_buf) {
		return
	}

	pretty_name := string(cstring(raw_data(kernel_version_buf[:])))
	pretty_name  = strings.trim(pretty_name, "\n")
	strings.write_string(&b, pretty_name)

	// l := strings.builder_len(b)

	// Retrieve kernel revision using `sysctl`, e.g. 199506
	mib = []i32{CTL_KERN, KERN_OSREV}
	revision: int
	if !sysctl(mib, &revision) {
		return
	}
	os_version.patch = revision

	strings.write_string(&b, ", revision ")
	strings.write_int(&b, revision)

	// Finalize pretty name.
	os_version.as_string = strings.to_string(b)

	// Retrieve kernel release using `sysctl`, e.g. 13.1-RELEASE-p2
	mib = []i32{CTL_KERN, KERN_OSRELEASE}
	if !sysctl(mib, &kernel_version_buf) {
		return
	}

	// Parse kernel version
	release := string(cstring(raw_data(kernel_version_buf[:])))
	version_bits := strings.split_n(release, "-", 2, context.temp_allocator)
	if len(version_bits) > 1 {
		// Parse major, minor from KERN_OSRELEASE
		triplet := strings.split(version_bits[0], ".", context.temp_allocator)
		if len(triplet) == 2 {
			major, major_ok := strconv.parse_int(triplet[0])
			minor, minor_ok := strconv.parse_int(triplet[1])

			if major_ok && minor_ok {
				os_version.major = major
				os_version.minor = minor
			}
		}
	}
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysctl`
	mib := []i32{CTL_HW, HW_PHYSMEM}
	mem_size: u64
	if sysctl(mib, &mem_size) {
		ram.total_ram = int(mem_size)
	}
}

@(private)
sysctl :: proc(mib: []i32, val: ^$T) -> (ok: bool) {
	mib := mib
	result_size := i64(size_of(T))

	res := intrinsics.syscall(sys.SYS_sysctl,
		uintptr(raw_data(mib)), uintptr(len(mib)),
		uintptr(val), uintptr(&result_size),
		uintptr(0), uintptr(0),
	)
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
