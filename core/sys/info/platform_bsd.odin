#+build openbsd, netbsd
package sysinfo

import sys "core:sys/unix"
import "core:strings"
import "core:strconv"
import "base:runtime"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	when ODIN_OS == .NetBSD {
		os_version.platform = .NetBSD
	} else {
		os_version.platform = .OpenBSD
	}

	kernel_version_buf: [1024]u8

	b := strings.builder_from_bytes(version_string_buf[:])
	// Retrieve kernel info using `sysctl`, e.g. OpenBSD and NetBSD
	mib := []i32{sys.CTL_KERN, sys.KERN_OSTYPE}
	if !sys.sysctl(mib, &kernel_version_buf) {
		return
	}
	os_type := string(cstring(raw_data(kernel_version_buf[:])))
	strings.write_string(&b, os_type)

	mib = []i32{sys.CTL_KERN, sys.KERN_OSRELEASE}
	if !sys.sysctl(mib, &kernel_version_buf) {
		return
	}

	strings.write_rune(&b, ' ')
	version := string(cstring(raw_data(kernel_version_buf[:])))
	strings.write_string(&b, version)

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// Parse kernel version
	triplet := strings.split(version, ".", context.temp_allocator)
	if len(triplet) == 2 {
		major, major_ok := strconv.parse_int(triplet[0])
		minor, minor_ok := strconv.parse_int(triplet[1])

		if major_ok && minor_ok {
			os_version.major = major
			os_version.minor = minor
		}
	}

	// Retrieve kernel revision using `sysctl`, e.g. 199506
	mib = []i32{sys.CTL_KERN, sys.KERN_OSREV}
	revision: int
	if !sys.sysctl(mib, &revision) {
		return
	}
	os_version.patch = revision
	strings.write_string(&b, ", build ")
	strings.write_int(&b, revision)

	// Finalize pretty name.
	os_version.as_string = strings.to_string(b)
}

@(init, private)
init_ram :: proc() {
	// Retrieve RAM info using `sysctl`
	mib := []i32{sys.CTL_HW, sys.HW_PHYSMEM64}
	mem_size: u64
	if sys.sysctl(mib, &mem_size) {
		ram.total_ram = int(mem_size)
	}
}
