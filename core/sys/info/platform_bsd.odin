#+build openbsd, netbsd
package sysinfo

import "base:runtime"
import "core:strings"
import sys "core:sys/unix"

_os_version :: proc (allocator: runtime.Allocator, loc := #caller_location) -> (res: OS_Version, ok: bool) {
	when ODIN_OS == .NetBSD {
		res.platform = .NetBSD
	} else {
		res.platform = .OpenBSD
	}

	kernel_version_buf: [1024]u8

	b := strings.builder_make_none(allocator = allocator, loc = loc)
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

	// Parse kernel version
	res.kernel = _parse_version(version)

	// Retrieve kernel revision using `sysctl`, e.g. 199506
	mib = []i32{sys.CTL_KERN, sys.KERN_OSREV}
	revision: int
	if !sys.sysctl(mib, &revision) {
		return
	}
	res.kernel.patch = revision
	strings.write_string(&b, ", build ")
	strings.write_int(&b, revision)

	// Finalize pretty name.
	res.full = strings.to_string(b)

	return res, true
}

@(private)
_ram_stats :: proc "contextless" () -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
	// Retrieve RAM info using `sysctl`
	mib := []i32{sys.CTL_HW, sys.HW_PHYSMEM64}
	if sys.sysctl(mib, &total_ram) {
		ok = true
	}

	mib = []i32{sys.CTL_HW, sys.HW_USERMEM64}
	if sys.sysctl(mib, &free_ram) {
		ok = true
	}
	return
}