package sysinfo

import    "base:runtime"
import    "core:strings"
import    "core:sys/unix"
import NS "core:sys/darwin/Foundation"

@(private)
_os_version :: proc (allocator: runtime.Allocator, loc := #caller_location) -> (res: OS_Version, ok: bool) {
	ws :: strings.write_string
	wi :: strings.write_int

	b := strings.builder_make_none(allocator = allocator, loc = loc)

	version: NS.OperatingSystemVersion
	{
		NS.scoped_autoreleasepool() 

		info    := NS.ProcessInfo.processInfo()
		version  = info->operatingSystemVersion()
	}

	res.os = {int(version.majorVersion), int(version.minorVersion), int(version.patchVersion)}

	when ODIN_PLATFORM_SUBTARGET_IOS {
		res.platform = .iOS
		ws(&b, "iOS")
	} else {
		res.platform = .MacOS
		switch version.majorVersion {
		case 26: ws(&b, "macOS Tahoe")
		case 15: ws(&b, "macOS Sequoia")
		case 14: ws(&b, "macOS Sonoma")
		case 13: ws(&b, "macOS Ventura")
		case 12: ws(&b, "macOS Monterey")
		case 11: ws(&b, "macOS Big Sur")
		case 10:
			switch version.minorVersion {
			case 15: ws(&b, "macOS Catalina")
			case 14: ws(&b, "macOS Mojave")
			case 13: ws(&b, "macOS High Sierra")
			case 12: ws(&b, "macOS Sierra")
			case 11: ws(&b, "OS X El Capitan")
			case 10: ws(&b, "OS X Yosemite")
			case:
				// `ProcessInfo.operatingSystemVersion` is 10.10 and up.
				unreachable()
			}
		case:
			// New version not yet added here.
			assert(version.majorVersion > 15)
			ws(&b, "macOS Unknown")
		}
	}

	ws(&b, " ")
	wi(&b, int(version.majorVersion))
	ws(&b, ".")
	wi(&b, int(version.minorVersion))
	ws(&b, ".")
	wi(&b, int(version.patchVersion))

	{
		build_buf: [12]u8
		mib := []i32{unix.CTL_KERN, unix.KERN_OSVERSION}
		build := "Unknown"
		if unix.sysctl(mib, &build_buf) {
			build = string(cstring(raw_data(build_buf[:])))
		}
		ws(&b, " (build ")
		build_start := len(b.buf)
		ws(&b, build)
		res.release = string(b.buf[build_start:][:len(build)])
	}

	{
		// Match on XNU kernel version
		version_bits: [12]u8 // enough for 999.999.999\x00
		mib := []i32{unix.CTL_KERN, unix.KERN_OSRELEASE}
		kernel := "Unknown"
		if unix.sysctl(mib, &version_bits) {
			kernel = string(cstring(raw_data(version_bits[:])))
			res.kernel = _parse_version(kernel)
		}
		ws(&b, ", kernel ")
		ws(&b, kernel)
		ws(&b, ")")
	}

	res.full = strings.to_string(b)
	return res, true
}

@(private)
_ram_stats :: proc "contextless" () -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
	NS.scoped_autoreleasepool()
	info := NS.ProcessInfo.processInfo()
	return i64(info->physicalMemory()), 0, 0, 0, true
}