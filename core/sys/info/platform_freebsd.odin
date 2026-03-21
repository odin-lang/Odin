package sysinfo

import sys "core:sys/unix"
import "core:strings"
import "base:runtime"

@(private)
_os_version :: proc (allocator: runtime.Allocator, loc := #caller_location) -> (res: OS_Version, ok: bool) {
	res.platform = .FreeBSD

	kernel_version_buf: [1024]u8

	b := strings.builder_make_none(allocator = allocator, loc = loc)
	// Retrieve kernel info using `sysctl`, e.g. FreeBSD 13.1-RELEASE-p2 GENERIC
	mib := []i32{sys.CTL_KERN, sys.KERN_VERSION}
	if !sys.sysctl(mib, &kernel_version_buf) {
		return
	}

	pretty_name := string(cstring(raw_data(kernel_version_buf[:])))
	pretty_name  = strings.trim(pretty_name, "\n")
	strings.write_string(&b, pretty_name)

	// Retrieve kernel revision using `sysctl`, e.g. 199506
	mib = []i32{sys.CTL_KERN, sys.KERN_OSREV}
	revision: int
	if !sys.sysctl(mib, &revision) {
		return
	}

	strings.write_string(&b, ", revision ")
	strings.write_int(&b, revision)

	// Finalize pretty name.
	res.full = strings.to_string(b)

	// Retrieve kernel release using `sysctl`, e.g. 13.1-RELEASE-p2
	mib = []i32{sys.CTL_KERN, sys.KERN_OSRELEASE}
	if !sys.sysctl(mib, &kernel_version_buf) {
		return
	}

	// Parse kernel version
	release := string(cstring(raw_data(kernel_version_buf[:])))
	version_bits, _, _ := strings.partition(release, "-")
	res.kernel = _parse_version(version_bits)
	res.kernel.patch = revision

	res.os = res.kernel

	return res, true
}

@(private)
_ram_stats :: proc "contextless" () -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
	// Retrieve RAM info using `sysctl`
	mib := []i32{sys.CTL_HW, sys.HW_PHYSMEM}
	if sys.sysctl(mib, &total_ram) {
		ok = true
	}

	mib = []i32{sys.CTL_HW, sys.HW_USERMEM}
	if sys.sysctl(mib, &free_ram) {
		ok = true
	}
	return
}
