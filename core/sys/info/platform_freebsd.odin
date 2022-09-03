// +build freebsd
package sysinfo

import sys "core:sys/unix"
import "core:intrinsics"
import "core:os"
import "core:strings"
import "core:strconv"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	os_version.platform = .FreeBSD

	// TODO(Jeroen): No need to parse /etc/os-release. Use sysctl                                                                                                                                               
	// kern.ostype: FreeBSD                                                                                                                                                                          
	// kern.osrelease: 13.1-RELEASE-p2                                                                
	// kern.osrevision: 199506                                                                        
	// kern.version: FreeBSD 13.1-RELEASE-p2 GENERIC

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
				strings.write_string(&b, "Unknown FreeBSD Distro")
				break
			}
		}
	}

	// Finish the string
	os_version.as_string = strings.to_string(b)

	NEW_UTS_LEN :: 63
	UTS_Name :: struct {
		sys_name:    [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		node_name:   [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		release:     [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		version:     [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		machine:     [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
		domain_name: [NEW_UTS_LEN + 1]u8 `fmt:"s,0"`,
	}
	uts: UTS_Name

	// Grab kernel info using `uname()` syscall, https://www.freebsd.org/cgi/man.cgi?query=uname&sektion=3&n=1
	if intrinsics.syscall(sys.SYS_uname, uintptr(&uts)) != 0 {
		return
	}

	// Parse kernel version, as substrings of the version info in `version_string_buf`
	version_bits := strings.split_n(string(cstring(&uts.node_name[0])), "-", 2, context.temp_allocator)
	if len(version_bits) > 1 {
		// We finished the display string, but are also using the buffer to intern the version alone.
		strings.write_rune(&b, ' ')
		l := strings.builder_len(b)
		strings.write_string(&b, version_bits[0])
		os_version.version = strings.to_string(b)[l:]

		// Parse major, minor from node_name
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

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysctl`
	mib := []i32{CTL_HW, HW_PHYSMEM}
	mem_size: u64
	if sysctl(mib, &mem_size) {
		ram.total_ram = int(mem_size)
	}
}

@(private)
sysctl :: proc(mib: []i32, val: ^$T) -> (ok: bool) {
	mib := mib
	result_size := i64(size_of(T))

	res := intrinsics.syscall(sys.SYS_sysctl,
		uintptr(raw_data(mib)), uintptr(len(mib)),
		uintptr(val), uintptr(&result_size),
		uintptr(0), uintptr(0),
	)
	return res == 0
}

// See /usr/include/sys/sysctl.h for details
CTL_SYSCTL :: 0
CTL_KERN   :: 1
	KERN_OSTYPE    :: 1
	KERN_OSRELEASE :: 2
	KERN_OSREV     :: 3
	KERN_VERSION   :: 4
CTL_VM     :: 2
CTL_VFS    :: 3
CTL_NET    :: 4
CTL_DEBUG  :: 5
CTL_HW     :: 6
	HW_MACHINE      ::  1
	HW_MODEL        ::  2
	HW_NCPU         ::  3
	HW_BYTEORDER    ::  4
	HW_PHYSMEM      ::  5
	HW_USERMEM      ::  6
	HW_PAGESIZE     ::  7
	HW_DISKNAMES    ::  8
	HW_DISKSTATS    ::  9
	HW_FLOATINGPT   :: 10
	HW_MACHINE_ARCH :: 11
	HW_REALMEM      :: 12
CTL_MACHDEP  :: 7
CTL_USER     :: 8
CTL_P1003_1B :: 9
