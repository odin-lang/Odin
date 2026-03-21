package sysinfo

import "base:intrinsics"
import "base:runtime"
import "core:strings"
import "core:sys/linux"

@(private)
_os_version :: proc (allocator: runtime.Allocator, loc := #caller_location) -> (res: OS_Version, ok: bool) {
	res.platform = .Linux

	b := strings.builder_make_none(allocator = allocator, loc = loc)

	// Try to parse `/etc/os-release` for `PRETTY_NAME="Ubuntu 20.04.3 LTS`
	pretty_parse: {
		fd, errno := linux.open("/etc/os-release", {})
		if errno != .NONE {
			strings.write_string(&b, "Unknown Linux Distro")
			break pretty_parse
		}

		defer linux.close(fd)

		os_release_buf: [2048]u8
		n, read_errno := linux.read(fd, os_release_buf[:])
		if read_errno != .NONE {
			strings.write_string(&b, "Unknown Linux Distro")
			break pretty_parse
		}
		release := string(os_release_buf[:n])

		{
			// Search the line in the file until we find "PRETTY_NAME="
			_, _, post := strings.partition(release, `PRETTY_NAME="`)
			if len(post) > 0 {
				end := strings.index_any(post, "\"\n")
				if end > -1 && post[end] == '"' {
					strings.write_string(&b, post[:end])
				}
			}
			if strings.builder_len(b) == 0 {
				strings.write_string(&b, "Unknown Linux Distro")
			}
		}

		{
			// Search the line in the file until we find "VERSION="
			_, _, post := strings.partition(release, `VERSION="`)
			if len(post) > 0 {
				pre, _, _ := strings.partition(post, ` `)
				res.os = _parse_version(pre)
			}
		}
	}

	// Grab kernel info using `uname()` syscall, https://linux.die.net/man/2/uname
	uts: linux.UTS_Name
	uname_errno := linux.uname(&uts)
	assert(uname_errno == .NONE, "This should never happen!")
	// Append the system name (typically "Linux") and kernel release (looks like 6.5.2-arch1-1)
	strings.write_string(&b, ", ")
	strings.write_string(&b, string(cstring(&uts.sysname[0])))
	strings.write_rune(&b, ' ')

	release_i := strings.builder_len(b)
	strings.write_string(&b, string(cstring(&uts.release[0])))
	release_str := string(b.buf[release_i:])

	res.full = strings.to_string(b)

	// Parse the Linux version out of the release string
	version_loop: {
		version_num, _, version_suffix := strings.partition(release_str, "-")
		res.release = version_suffix
		res.kernel = _parse_version(version_num)

	}
	return res, true
}

@(private)
_ram_stats :: proc "contextless" () -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
	// Retrieve RAM info using `sysinfo`
	sys_info: linux.Sys_Info
	errno := linux.sysinfo(&sys_info)
	assert_contextless(errno == .NONE, "Good luck to whoever's debugging this, something's seriously cucked up!")

	total_ram  = i64(sys_info.totalram)  * i64(sys_info.mem_unit)
	free_ram   = i64(sys_info.freeram)   * i64(sys_info.mem_unit)
	total_swap = i64(sys_info.totalswap) * i64(sys_info.mem_unit)
	free_swap  = i64(sys_info.freeswap)  * i64(sys_info.mem_unit)
	ok         = true

	return
}