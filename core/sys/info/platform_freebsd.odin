package sysinfo

import sys "core:sys/unix"
import "core:strings"
import "core:strconv"
import "base:runtime"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	os_version.platform = .FreeBSD

	kernel_version_buf: [1024]u8

	b := strings.builder_from_bytes(version_string_buf[:])
	// Retrieve kernel info using `sysctl`, e.g. FreeBSD 13.1-RELEASE-p2 GENERIC
	mib := []i32{sys.CTL_KERN, sys.KERN_VERSION}
	if !sys.sysctl(mib, &kernel_version_buf) {
		return
	}

	pretty_name := string(cstring(raw_data(kernel_version_buf[:])))
	pretty_name  = strings.trim(pretty_name, "\n")
	strings.write_string(&b, pretty_name)

	// l := strings.builder_len(b)

	// Retrieve kernel revision using `sysctl`, e.g. 199506
	mib = []i32{sys.CTL_KERN, sys.KERN_OSREV}
	revision: int
	if !sys.sysctl(mib, &revision) {
		return
	}
	os_version.patch = revision

	strings.write_string(&b, ", revision ")
	strings.write_int(&b, revision)

	// Finalize pretty name.
	os_version.as_string = strings.to_string(b)

	// Retrieve kernel release using `sysctl`, e.g. 13.1-RELEASE-p2
	mib = []i32{sys.CTL_KERN, sys.KERN_OSRELEASE}
	if !sys.sysctl(mib, &kernel_version_buf) {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

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

@(init, private)
init_ram :: proc() {
	// Retrieve RAM info using `sysctl`
	mib := []i32{sys.CTL_HW, sys.HW_PHYSMEM}
	mem_size: u64
	if sys.sysctl(mib, &mem_size) {
		ram.total_ram = int(mem_size)
	}
}