// +build linux
package sysinfo

import "base:intrinsics"
import "base:runtime"
import "core:strings"
import "core:strconv"

import "core:sys/linux"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	os_version.platform = .Linux
	// Try to parse `/etc/os-release` for `PRETTY_NAME="Ubuntu 20.04.3 LTS`
	fd, errno := linux.open("/etc/os-release", {.RDONLY}, {})
	assert(errno == .NONE, "Failed to read /etc/os-release")
	defer {
		cerrno := linux.close(fd)
		assert(cerrno == .NONE, "Failed to close the file descriptor")
	}
	os_release_buf: [2048]u8
	n, read_errno := linux.read(fd, os_release_buf[:])
	assert(read_errno == .NONE, "Failed to read data from /etc/os-release")
	release := string(os_release_buf[:n])
	// Search the line in the file until we find "PRETTY_NAME="
	NEEDLE :: "PRETTY_NAME=\""
	pretty_start := strings.index(release, NEEDLE)
	b := strings.builder_from_bytes(version_string_buf[:])
	if pretty_start > 0 {
		for r, i in release[pretty_start + len(NEEDLE):] {
			if r == '"' {
				strings.write_string(&b, release[pretty_start + len(NEEDLE):][:i])
				break
			} else if r == '\r' || r == '\n' {
				strings.write_string(&b, "Unknown Linux Distro")
				break
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
	l := strings.builder_len(b)
	strings.write_string(&b, string(cstring(&uts.release[0])))
	// Parse kernel version, as substrings of the version info in `version_string_buf`
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	version_bits := strings.split_n(strings.to_string(b)[l:], "-", 2, context.temp_allocator)
	if len(version_bits) > 1 {
		os_version.version = version_bits[1]
	}
	// Parse major, minor, patch from release info
	triplet := strings.split(version_bits[0], ".", context.temp_allocator)
	if len(triplet) == 3 {
		major, major_ok := strconv.parse_int(triplet[0])
		minor, minor_ok := strconv.parse_int(triplet[1])
		patch, patch_ok := strconv.parse_int(triplet[2])
		if major_ok && minor_ok && patch_ok {
			os_version.major = major
			os_version.minor = minor
			os_version.patch = patch
		}
	}
	// Finish the string
	os_version.as_string = strings.to_string(b)
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysinfo`
	sys_info: linux.Sys_Info
	errno := linux.sysinfo(&sys_info)
	assert(errno == .NONE, "Good luck to whoever's debugging this, something's seriously cucked up!")
	ram = RAM{
		total_ram  = int(sys_info.totalram)  * int(sys_info.mem_unit),
		free_ram   = int(sys_info.freeram)   * int(sys_info.mem_unit),
		total_swap = int(sys_info.totalswap) * int(sys_info.mem_unit),
		free_swap  = int(sys_info.freeswap)  * int(sys_info.mem_unit),
	}
}