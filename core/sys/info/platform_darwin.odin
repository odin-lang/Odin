package sysinfo

import    "core:strconv"
import    "core:strings"
import    "core:sys/unix"
import NS "core:sys/darwin/Foundation"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_platform :: proc() {
	ws :: strings.write_string
	wi :: strings.write_int

	b := strings.builder_from_bytes(version_string_buf[:])

	version: NS.OperatingSystemVersion
	{
		NS.scoped_autoreleasepool() 

		info    := NS.ProcessInfo.processInfo()
		version  = info->operatingSystemVersion()
		mem     := info->physicalMemory()

		ram.total_ram = int(mem)
	}

	macos_version = {int(version.majorVersion), int(version.minorVersion), int(version.patchVersion)}

	when ODIN_PLATFORM_SUBTARGET == .iOS {
		os_version.platform = .iOS
		ws(&b, "iOS")
	} else {
		os_version.platform = .MacOS
		switch version.majorVersion {
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
		ok := unix.sysctl(mib, &build_buf)
		build := string(cstring(raw_data(build_buf[:]))) if ok else "Unknown"

		ws(&b, " (build ")

		build_start := len(b.buf)
		ws(&b, build)
		os_version.version = string(b.buf[build_start:][:len(build)])
	}

	{
		// Match on XNU kernel version
		version_bits: [12]u8 // enough for 999.999.999\x00
		mib := []i32{unix.CTL_KERN, unix.KERN_OSRELEASE}
		ok := unix.sysctl(mib, &version_bits)
		kernel := string(cstring(raw_data(version_bits[:]))) if ok else "Unknown"

		major, _, tail  := strings.partition(kernel, ".")
		minor, _, patch := strings.partition(tail, ".")

		os_version.major, _ = strconv.parse_int(major, 10)
		os_version.minor, _ = strconv.parse_int(minor, 10)
		os_version.patch, _ = strconv.parse_int(patch, 10)

		ws(&b, ", kernel ")
		ws(&b, kernel)
		ws(&b, ")")
	}

	os_version.as_string = string(b.buf[:])
}
