// +build linux
package sysinfo

import "core:c"
import sys "core:sys/unix"
import "core:intrinsics"
import "core:os"
import "core:strings"
import "core:strconv"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	os_version.platform = .Linux

	// Try to parse `/etc/os-release` for `PRETTY_NAME="Ubuntu 20.04.3 LTS`
	fd, err := os.open("/etc/os-release", os.O_RDONLY, 0)
	if err != 0 {
		return
	}
	defer os.close(fd)

	os_release_buf: [2048]u8
	n, read_err := os.read(fd, os_release_buf[:])
	if read_err != 0 {
		return
	}
	release := string(os_release_buf[:n])

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

	NEW_UTS_LEN :: 64
	UTS_Name :: struct {
		sys_name:    [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		node_name:   [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		release:     [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		version:     [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		machine:     [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		domain_name: [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
	}
	uts: UTS_Name

	// Grab kernel info using `uname()` syscall, https://linux.die.net/man/2/uname
	if intrinsics.syscall(sys.SYS_uname, uintptr(&uts)) != 0 {
		return
	}

	strings.write_string(&b, ", ")
	strings.write_string(&b, string(cstring(&uts.sys_name[0])))
	strings.write_rune(&b, ' ')

	l := strings.builder_len(b)
	strings.write_string(&b, string(cstring(&uts.release[0])))

	// Parse kernel version, as substrings of the version info in `version_string_buf`
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

Sys_Info :: struct {
	uptime:    c.long,     // Seconds since boot
	loads:     [3]c.long,  // 1, 5, 15 minute load averages
	totalram:  c.ulong,    // Total usable main memory size
	freeram:   c.ulong,    // Available memory size
	sharedram: c.ulong,    // Amount of shared memory
	bufferram: c.ulong,    // Memory used by buffers
	totalswap: c.ulong,    // Total swap space size
	freeswap:  c.ulong,    // Swap space still available
	procs:     c.ushort,   // Number of current processes
	totalhigh: c.ulong,    // Total high memory size
	freehigh:  c.ulong,    // Available high memory size
	mem_unit:  c.int,      // Memory unit size in bytes
	_padding:  [20 - (2 * size_of(c.long)) - size_of(c.int)]u8,
}

get_sysinfo :: proc "c" () -> (res: Sys_Info, ok: bool) {
	si: Sys_Info
	err := intrinsics.syscall(sys.SYS_sysinfo, uintptr(rawptr(&si)))
	if err != 0 {
		// Unable to retrieve sysinfo
		return {}, false
	}
	return si, true
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysinfo`
	si, ok := get_sysinfo()
	if !ok {
		return
	}

	ram = RAM{
		total_ram  = int(si.totalram)  * int(si.mem_unit),
		free_ram   = int(si.freeram)   * int(si.mem_unit),
		total_swap = int(si.totalswap) * int(si.mem_unit),
		free_swap  = int(si.freeswap)  * int(si.mem_unit),
	}
}