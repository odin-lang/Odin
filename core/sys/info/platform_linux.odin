package sysinfo

import "base:intrinsics"

import "core:strconv"
import "core:strings"
import "core:sys/linux"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	os_version.platform = .Linux

	b := strings.builder_from_bytes(version_string_buf[:])

	// Try to parse `/etc/os-release` for `PRETTY_NAME="Ubuntu 20.04.3 LTS`
	pretty_parse: {
		fd, errno := linux.open("/etc/os-release", {})
		if errno != .NONE {
			strings.write_string(&b, "Unknown Linux Distro")
			break pretty_parse
		}

		defer {
			cerrno := linux.close(fd)
			assert(cerrno == .NONE, "Failed to close the file descriptor")
		}

		os_release_buf: [2048]u8
		n, read_errno := linux.read(fd, os_release_buf[:])
		if read_errno != .NONE {
			strings.write_string(&b, "Unknown Linux Distro")
			break pretty_parse
		}
		release := string(os_release_buf[:n])

		// Search the line in the file until we find "PRETTY_NAME="
		NEEDLE :: "PRETTY_NAME=\""
		_, _, post := strings.partition(release, NEEDLE)
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

	os_version.as_string = strings.to_string(b)

	// Parse the Linux version out of the release string
	version_loop: {
		version_num, _, version_suffix := strings.partition(release_str, "-")
		os_version.version = version_suffix

		i: int
		for part in strings.split_iterator(&version_num, ".") {
			defer i += 1

			dst: ^int
			switch i {
			case 0: dst = &os_version.major
			case 1: dst = &os_version.minor
			case 2: dst = &os_version.patch
			case:   break version_loop
			}

			num, ok := strconv.parse_int(part)
			if !ok { break version_loop }

			dst^ = num
		}
	}
}

@(init, private)
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
