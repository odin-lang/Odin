// +build darwin
package sysinfo

import sys "core:sys/darwin"
import "core:intrinsics"
import "core:strconv"
import "core:strings"
import "core:fmt"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	os_version.platform = .MacOS

	// Start building display version
	b := strings.builder_from_bytes(version_string_buf[:])

	mib := []i32{CTL_KERN, KERN_OSVERSION}
	build_buf: [12]u8

	ok := sysctl(mib, &build_buf)
	if !ok {
		strings.write_string(&b, "macOS Unknown")
		os_version.as_string = strings.to_string(b)
		return
	}

	build := string(cstring(&build_buf[0]))

	// Do we have an exact match?
	match: Darwin_Match
	rel, exact := macos_release_map[build]

	if exact {
		match = .Exact
	} else {
		// Match on XNU kernel version
		mib = []i32{CTL_KERN, KERN_OSRELEASE}
		version_bits: [12]u8 // enough for 999.999.999\x00
		have_kernel_version := sysctl(mib, &version_bits)

		major_ok, minor_ok, patch_ok: bool

		triplet := strings.split(string(cstring(&version_bits[0])), ".", context.temp_allocator)
		if len(triplet) != 3 {
			have_kernel_version = false
		} else {
			rel.darwin.x, major_ok = strconv.parse_int(triplet[0])
			rel.darwin.y, minor_ok = strconv.parse_int(triplet[1])
			rel.darwin.z, patch_ok = strconv.parse_int(triplet[2])

			if !(major_ok && minor_ok && patch_ok) {
				have_kernel_version = false
			}
		}

		if !have_kernel_version {
			// We don't know the kernel version, but we do know the build
			strings.write_string(&b, "macOS Unknown (build ")
			l := strings.builder_len(b)
			strings.write_string(&b, build)
			os_version.version = strings.to_string(b)[l:]
			strings.write_rune(&b, ')')
			os_version.as_string = strings.to_string(b)
			return
		}
		rel, match = map_darwin_kernel_version_to_macos_release(build, rel.darwin)
	}

	os_version.major = rel.darwin.x
	os_version.minor = rel.darwin.y
	os_version.patch = rel.darwin.z

	strings.write_string(&b, rel.os_name)
	if match == .Exact || match == .Nearest {
		strings.write_rune(&b, ' ')
		strings.write_string(&b, rel.release.name)
		strings.write_rune(&b, ' ')
		strings.write_int(&b, rel.release.version.x)
		if rel.release.version.y > 0 || rel.release.version.z > 0 {
			strings.write_rune(&b, '.')
			strings.write_int(&b, rel.release.version.y)
		}
		if rel.release.version.z > 0 {
			strings.write_rune(&b, '.')
			strings.write_int(&b, rel.release.version.z)
		}
		if match == .Nearest {
			strings.write_rune(&b, '?')
		}
	} else {
		strings.write_string(&b, " Unknown")
	}

	strings.write_string(&b, " (build ")
	l := strings.builder_len(b)
	strings.write_string(&b, build)
	os_version.version = strings.to_string(b)[l:]

	strings.write_string(&b, ", kernel ")
	strings.write_int(&b, rel.darwin.x)
	strings.write_rune(&b, '.')
	strings.write_int(&b, rel.darwin.y)
	strings.write_rune(&b, '.')
	strings.write_int(&b, rel.darwin.z)
	strings.write_rune(&b, ')')

	os_version.as_string = strings.to_string(b)
}

@(init)
init_ram :: proc() {
	// Retrieve RAM info using `sysinfo`

	mib := []i32{CTL_HW, HW_MEMSIZE}
	mem_size: u64
	ok := sysctl(mib, &mem_size)
	ram.total_ram = int(mem_size)
}

@(private)
sysctl :: proc(mib: []i32, val: ^$T) -> (ok: bool) {
	mib := mib
	result_size := i64(size_of(T))

	res := intrinsics.syscall(
		sys.unix_offset_syscall(.sysctl),
		uintptr(raw_data(mib)), uintptr(len(mib)),
		uintptr(val), uintptr(&result_size),
		uintptr(0), uintptr(0),
	)
	return res == 0
}

// See sysctl.h for darwin/dwrwin for details
CTL_KERN    :: 1
	KERN_OSTYPE    :: 1  // Darwin
	KERN_OSRELEASE :: 2  // 21.5.0 for 12.4 Monterey 
	KERN_OSREV     :: 3  // i32: system revision
	KERN_VERSION   :: 4  // Darwin Kernel Version 21.5.0: Tue Apr 26 21:08:22 PDT 2022; root:darwin-8020.121.3~4/RELEASE_X86_64
	KERN_OSRELDATE :: 26 // i32: OS release date
	KERN_OSVERSION :: 65 // Build number, e.g. 21F79
CTL_VM      :: 2
CTL_VFS     :: 3
CTL_NET     :: 4
CTL_DEBUG   :: 5
CTL_HW      :: 6
	HW_MACHINE      :: 1  // x86_64
	HW_MODEL        :: 2  // MacbookPro14,1
	HW_NCPU         :: 3  /* int: number of cpus */
	HW_BYTEORDER    :: 4  /* int: machine byte order */
	HW_MACHINE_ARCH :: 12 /* string: machine architecture */
	HW_VECTORUNIT   :: 13 /* int: has HW vector unit? */
	HW_MEMSIZE      :: 24 // u64
	HW_AVAILCPU     :: 25 /* int: number of available CPUs */

CTL_MACHDEP :: 7
CTL_USER    :: 8

@(private)
Darwin_To_Release :: struct {
	darwin:      [3]int, // Darwin kernel triplet
	os_name:     string, // OS X, MacOS
	release:     struct {
		name:    string, // Monterey, Mojave, etc.
		version: [3]int, // 12.4, etc.
	},
}

// Important: Order from lowest to highest kernel version
@(private)
macos_release_map: map[string]Darwin_To_Release = {
	// MacOS Catalina
	"19A583"  = {{19, 0, 0}, "macOS", {"Catalina", {10, 15, 0}}},
	"19A602"  = {{19, 0, 0}, "macOS", {"Catalina", {10, 15, 0}}},
	"19A603"  = {{19, 0, 0}, "macOS", {"Catalina", {10, 15, 0}}},
	"19B88"   = {{19, 0, 0}, "macOS", {"Catalina", {10, 15, 1}}},
	"19C57"   = {{19, 2, 0}, "macOS", {"Catalina", {10, 15, 2}}},
	"19C58"   = {{19, 2, 0}, "macOS", {"Catalina", {10, 15, 2}}},
	"19D76"   = {{19, 3, 0}, "macOS", {"Catalina", {10, 15, 3}}},
	"19E266"  = {{19, 4, 0}, "macOS", {"Catalina", {10, 15, 4}}},
	"19E287"  = {{19, 4, 0}, "macOS", {"Catalina", {10, 15, 4}}},
	"19F96"   = {{19, 5, 0}, "macOS", {"Catalina", {10, 15, 5}}},
	"19F101"  = {{19, 5, 0}, "macOS", {"Catalina", {10, 15, 5}}},
	"19G73"   = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 6}}},
	"19G2021" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 6}}},
	"19H2"    = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H4"    = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H15"   = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H114"  = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H512"  = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H524"  = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1030" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1217" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1323" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1417" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1419" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1519" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1615" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1713" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1715" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1824" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H1922" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},
	"19H2026" = {{19, 6, 0}, "macOS", {"Catalina", {10, 15, 7}}},

	// MacOS Big Sur
	"20A2411" = {{20, 1, 0}, "macOS", {"Big Sur",  {11, 0, 0}}},
	"20B29"   = {{20, 1, 0}, "macOS", {"Big Sur",  {11, 0, 1}}},
	"20B50"   = {{20, 1, 0}, "macOS", {"Big Sur",  {11, 0, 1}}},
	"20C69"   = {{20, 2, 0}, "macOS", {"Big Sur",  {11, 1, 0}}},
	"20D64"   = {{20, 3, 0}, "macOS", {"Big Sur",  {11, 2, 0}}},
	"20D74"   = {{20, 3, 0}, "macOS", {"Big Sur",  {11, 2, 1}}},
	"20D75"   = {{20, 3, 0}, "macOS", {"Big Sur",  {11, 2, 1}}},
	"20D80"   = {{20, 3, 0}, "macOS", {"Big Sur",  {11, 2, 2}}},
	"20D91"   = {{20, 3, 0}, "macOS", {"Big Sur",  {11, 2, 3}}},
	"20E232"  = {{20, 4, 0}, "macOS", {"Big Sur",  {11, 3, 0}}},
	"20E241"  = {{20, 4, 0}, "macOS", {"Big Sur",  {11, 3, 1}}},
	"20F71"   = {{20, 5, 0}, "macOS", {"Big Sur",  {11, 4, 0}}},
	"20G71"   = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 5, 0}}},
	"20G80"   = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 5, 1}}},
	"20G95"   = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 5, 2}}},
	"20G165"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 0}}},
	"20G224"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 1}}},
	"20G314"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 2}}},
	"20G415"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 3}}},
	"20G417"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 4}}},
	"20G527"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 5}}},
	"20G624"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 6}}},
	"20G630"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 7}}},
	"20G730"  = {{20, 6, 0}, "macOS", {"Big Sur",  {11, 6, 8}}},

	// MacOS Monterey
	"21A344"  = {{21, 0, 1}, "macOS", {"Monterey", {12, 0, 0}}},
	"21A559"  = {{21, 1, 0}, "macOS", {"Monterey", {12, 0, 1}}},
	"21C52"   = {{21, 2, 0}, "macOS", {"Monterey", {12, 1, 0}}},
	"21D49"   = {{21, 3, 0}, "macOS", {"Monterey", {12, 2, 0}}},
	"21D62"   = {{21, 3, 0}, "macOS", {"Monterey", {12, 2, 1}}},
	"21E230"  = {{21, 4, 0}, "macOS", {"Monterey", {12, 3, 0}}},
	"21E258"  = {{21, 4, 0}, "macOS", {"Monterey", {12, 3, 1}}},
	"21F79"   = {{21, 5, 0}, "macOS", {"Monterey", {12, 4, 0}}},
	"21F2081" = {{21, 5, 0}, "macOS", {"Monterey", {12, 4, 0}}},
	"21F2092" = {{21, 5, 0}, "macOS", {"Monterey", {12, 4, 0}}},
	"21G72"   = {{21, 6, 0}, "macOS", {"Monterey", {12, 5, 0}}},
	"21G83"   = {{21, 6, 0}, "macOS", {"Monterey", {12, 5, 1}}},
}

@(private)
Darwin_Match :: enum {
	Unknown,
	Exact,
	Nearest,
}

@(private)
map_darwin_kernel_version_to_macos_release :: proc(build: string, darwin: [3]int) -> (res: Darwin_To_Release, match: Darwin_Match) {
	// Find exact release match if possible.
	if v, v_ok := macos_release_map[build]; v_ok {
		return v, .Exact
	}

	nearest: Darwin_To_Release
	for _, v in macos_release_map {
		// Try an exact match on XNU version first.
		if darwin == v.darwin {
			return v, .Exact
		}

		// Major kernel version needs to match exactly,
		// otherwise the release is considered .Unknown
		if darwin.x == v.darwin.x {
			if nearest == {} {
				nearest = v
			}
			if darwin.y >= v.darwin.y && v.darwin != nearest.darwin {
				nearest = v
				if darwin.z >= v.darwin.z && v.darwin != nearest.darwin {
					nearest = v
				}
			}
		}
	}

	if nearest == {} {
		return {darwin, "macOS", {"Unknown", {}}}, .Unknown
	} else {
		return nearest, .Nearest
	}
}