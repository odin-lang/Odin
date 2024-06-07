package sysinfo

import sys "core:sys/unix"
import "core:strconv"
import "core:strings"
import "base:runtime"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
	os_version.platform = .MacOS

	// Start building display version
	b := strings.builder_from_bytes(version_string_buf[:])

	mib := []i32{sys.CTL_KERN, sys.KERN_OSVERSION}
	build_buf: [12]u8

	ok := sys.sysctl(mib, &build_buf)
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
		mib = []i32{sys.CTL_KERN, sys.KERN_OSRELEASE}
		version_bits: [12]u8 // enough for 999.999.999\x00
		have_kernel_version := sys.sysctl(mib, &version_bits)

		major_ok, minor_ok, patch_ok: bool

		tmp := runtime.default_temp_allocator_temp_begin()

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

		runtime.default_temp_allocator_temp_end(tmp)

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

	macos_version = transmute(Version)rel.release.version

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

@(init, private)
init_ram :: proc() {
	// Retrieve RAM info using `sysctl`

	mib := []i32{sys.CTL_HW, sys.HW_MEMSIZE}
	mem_size: u64
	if sys.sysctl(mib, &mem_size) {
		ram.total_ram = int(mem_size)
	}
}

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
	// MacOS Tiger
	"8A428"      = {{8, 0, 0},   "macOS", {"Tiger",         {10,  4, 0}}},
	"8A432"      = {{8, 0, 0},   "macOS", {"Tiger",         {10,  4, 0}}},
	"8B15"       = {{8, 1, 0},   "macOS", {"Tiger",         {10,  4, 1}}},
	"8B17"       = {{8, 1, 0},   "macOS", {"Tiger",         {10,  4, 1}}},
	"8C46"       = {{8, 2, 0},   "macOS", {"Tiger",         {10,  4, 2}}},
	"8C47"       = {{8, 2, 0},   "macOS", {"Tiger",         {10,  4, 2}}},
	"8E102"      = {{8, 2, 0},   "macOS", {"Tiger",         {10,  4, 2}}},
	"8E45"       = {{8, 2, 0},   "macOS", {"Tiger",         {10,  4, 2}}},
	"8E90"       = {{8, 2, 0},   "macOS", {"Tiger",         {10,  4, 2}}},
	"8F46"       = {{8, 3, 0},   "macOS", {"Tiger",         {10,  4, 3}}},
	"8G32"       = {{8, 4, 0},   "macOS", {"Tiger",         {10,  4, 4}}},
	"8G1165"     = {{8, 4, 0},   "macOS", {"Tiger",         {10,  4, 4}}},
	"8H14"       = {{8, 5, 0},   "macOS", {"Tiger",         {10,  4, 5}}},
	"8G1454"     = {{8, 5, 0},   "macOS", {"Tiger",         {10,  4, 5}}},
	"8I127"      = {{8, 6, 0},   "macOS", {"Tiger",         {10,  4, 6}}},
	"8I1119"     = {{8, 6, 0},   "macOS", {"Tiger",         {10,  4, 6}}},
	"8J135"      = {{8, 7, 0},   "macOS", {"Tiger",         {10,  4, 7}}},
	"8J2135a"    = {{8, 7, 0},   "macOS", {"Tiger",         {10,  4, 7}}},
	"8K1079"     = {{8, 7, 0},   "macOS", {"Tiger",         {10,  4, 7}}},
	"8N5107"     = {{8, 7, 0},   "macOS", {"Tiger",         {10,  4, 7}}},
	"8L127"      = {{8, 8, 0},   "macOS", {"Tiger",         {10,  4, 8}}},
	"8L2127"     = {{8, 8, 0},   "macOS", {"Tiger",         {10,  4, 8}}},
	"8P135"      = {{8, 9, 0},   "macOS", {"Tiger",         {10,  4, 9}}},
	"8P2137"     = {{8, 9, 0},   "macOS", {"Tiger",         {10,  4, 9}}},
	"8R218"      = {{8, 10, 0},  "macOS", {"Tiger",         {10,  4, 10}}},
	"8R2218"     = {{8, 10, 0},  "macOS", {"Tiger",         {10,  4, 10}}},
	"8R2232"     = {{8, 10, 0},  "macOS", {"Tiger",         {10,  4, 10}}},
	"8S165"      = {{8, 11, 0},  "macOS", {"Tiger",         {10,  4, 11}}},
	"8S2167"     = {{8, 11, 0},  "macOS", {"Tiger",         {10,  4, 11}}},

	// MacOS Leopard
	"9A581"      = {{9, 0, 0},   "macOS", {"Leopard",       {10,  5, 0}}},
	"9B18"       = {{9, 1, 0},   "macOS", {"Leopard",       {10,  5, 1}}},
	"9B2117"     = {{9, 1, 1},   "macOS", {"Leopard",       {10,  5, 1}}},
	"9C31"       = {{9, 2, 0},   "macOS", {"Leopard",       {10,  5, 2}}},
	"9C7010"     = {{9, 2, 0},   "macOS", {"Leopard",       {10,  5, 2}}},
	"9D34"       = {{9, 3, 0},   "macOS", {"Leopard",       {10,  5, 3}}},
	"9E17"       = {{9, 4, 0},   "macOS", {"Leopard",       {10,  5, 4}}},
	"9F33"       = {{9, 5, 0},   "macOS", {"Leopard",       {10,  5, 5}}},
	"9G55"       = {{9, 6, 0},   "macOS", {"Leopard",       {10,  5, 6}}},
	"9G66"       = {{9, 6, 0},   "macOS", {"Leopard",       {10,  5, 6}}},
	"9G71"       = {{9, 6, 0},   "macOS", {"Leopard",       {10,  5, 6}}},
	"9J61"       = {{9, 7, 0},   "macOS", {"Leopard",       {10,  5, 7}}},
	"9L30"       = {{9, 8, 0},   "macOS", {"Leopard",       {10,  5, 8}}},
	"9L34"       = {{9, 8, 0},   "macOS", {"Leopard",       {10,  5, 8}}},

	// MacOS Snow Leopard
	"10A432"     = {{10, 0, 0},  "macOS", {"Snow Leopard",  {10,  6, 0}}},
	"10A433"     = {{10, 0, 0},  "macOS", {"Snow Leopard",  {10,  6, 0}}},
	"10B504"     = {{10, 1, 0},  "macOS", {"Snow Leopard",  {10,  6, 1}}},
	"10C540"     = {{10, 2, 0},  "macOS", {"Snow Leopard",  {10,  6, 2}}},
	"10D573"     = {{10, 3, 0},  "macOS", {"Snow Leopard",  {10,  6, 3}}},
	"10D575"     = {{10, 3, 0},  "macOS", {"Snow Leopard",  {10,  6, 3}}},
	"10D578"     = {{10, 3, 0},  "macOS", {"Snow Leopard",  {10,  6, 3}}},
	"10F569"     = {{10, 4, 0},  "macOS", {"Snow Leopard",  {10,  6, 4}}},
	"10H574"     = {{10, 5, 0},  "macOS", {"Snow Leopard",  {10,  6, 5}}},
	"10J567"     = {{10, 6, 0},  "macOS", {"Snow Leopard",  {10,  6, 6}}},
	"10J869"     = {{10, 7, 0},  "macOS", {"Snow Leopard",  {10,  6, 7}}},
	"10J3250"    = {{10, 7, 0},  "macOS", {"Snow Leopard",  {10,  6, 7}}},
	"10J4138"    = {{10, 7, 0},  "macOS", {"Snow Leopard",  {10,  6, 7}}},
	"10K540"     = {{10, 8, 0},  "macOS", {"Snow Leopard",  {10,  6, 8}}},
	"10K549"     = {{10, 8, 0},  "macOS", {"Snow Leopard",  {10,  6, 8}}},

	// MacOS Lion
	"11A511"     = {{11, 0, 0},  "macOS", {"Lion",          {10,  7, 0}}},
	"11A511s"    = {{11, 0, 0},  "macOS", {"Lion",          {10,  7, 0}}},
	"11A2061"    = {{11, 0, 2},  "macOS", {"Lion",          {10,  7, 0}}},
	"11A2063"    = {{11, 0, 2},  "macOS", {"Lion",          {10,  7, 0}}},
	"11B26"      = {{11, 1, 0},  "macOS", {"Lion",          {10,  7, 1}}},
	"11B2118"    = {{11, 1, 0},  "macOS", {"Lion",          {10,  7, 1}}},
	"11C74"      = {{11, 2, 0},  "macOS", {"Lion",          {10,  7, 2}}},
	"11D50"      = {{11, 3, 0},  "macOS", {"Lion",          {10,  7, 3}}},
	"11E53"      = {{11, 4, 0},  "macOS", {"Lion",          {10,  7, 4}}},
	"11G56"      = {{11, 4, 2},  "macOS", {"Lion",          {10,  7, 5}}},
	"11G63"      = {{11, 4, 2},  "macOS", {"Lion",          {10,  7, 5}}},

	// MacOS Mountain Lion
	"12A269"     = {{12, 0, 0},  "macOS", {"Mountain Lion", {10,  8, 0}}},
	"12B19"      = {{12, 1, 0},  "macOS", {"Mountain Lion", {10,  8, 1}}},
	"12C54"      = {{12, 2, 0},  "macOS", {"Mountain Lion", {10,  8, 2}}},
	"12C60"      = {{12, 2, 0},  "macOS", {"Mountain Lion", {10,  8, 2}}},
	"12C2034"    = {{12, 2, 0},  "macOS", {"Mountain Lion", {10,  8, 2}}},
	"12C3104"    = {{12, 2, 0},  "macOS", {"Mountain Lion", {10,  8, 2}}},
	"12D78"      = {{12, 3, 0},  "macOS", {"Mountain Lion", {10,  8, 3}}},
	"12E55"      = {{12, 4, 0},  "macOS", {"Mountain Lion", {10,  8, 4}}},
	"12E3067"    = {{12, 4, 0},  "macOS", {"Mountain Lion", {10,  8, 4}}},
	"12E4022"    = {{12, 4, 0},  "macOS", {"Mountain Lion", {10,  8, 4}}},
	"12F37"      = {{12, 5, 0},  "macOS", {"Mountain Lion", {10,  8, 5}}},
	"12F45"      = {{12, 5, 0},  "macOS", {"Mountain Lion", {10,  8, 5}}},
	"12F2501"    = {{12, 5, 0},  "macOS", {"Mountain Lion", {10,  8, 5}}},
	"12F2518"    = {{12, 5, 0},  "macOS", {"Mountain Lion", {10,  8, 5}}},
	"12F2542"    = {{12, 5, 0},  "macOS", {"Mountain Lion", {10,  8, 5}}},
	"12F2560"    = {{12, 5, 0},  "macOS", {"Mountain Lion", {10,  8, 5}}},

	// MacOS Mavericks
	"13A603"     = {{13, 0, 0},  "macOS", {"Mavericks",     {10,  9, 0}}},
	"13B42"      = {{13, 0, 0},  "macOS", {"Mavericks",     {10,  9, 1}}},
	"13C64"      = {{13, 1, 0},  "macOS", {"Mavericks",     {10,  9, 2}}},
	"13C1021"    = {{13, 1, 0},  "macOS", {"Mavericks",     {10,  9, 2}}},
	"13D65"      = {{13, 2, 0},  "macOS", {"Mavericks",     {10,  9, 3}}},
	"13E28"      = {{13, 3, 0},  "macOS", {"Mavericks",     {10,  9, 4}}},
	"13F34"      = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1066"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1077"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1096"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1112"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1134"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1507"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1603"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1712"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1808"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},
	"13F1911"    = {{13, 4, 0},  "macOS", {"Mavericks",     {10,  9, 5}}},

	// MacOS Yosemite
	"14A389"     = {{14, 0, 0},  "macOS", {"Yosemite",      {10, 10, 0}}},
	"14B25"      = {{14, 0, 0},  "macOS", {"Yosemite",      {10, 10, 1}}},
	"14C109"     = {{14, 1, 0},  "macOS", {"Yosemite",      {10, 10, 2}}},
	"14C1510"    = {{14, 1, 0},  "macOS", {"Yosemite",      {10, 10, 2}}},
	"14C2043"    = {{14, 1, 0},  "macOS", {"Yosemite",      {10, 10, 2}}},
	"14C1514"    = {{14, 1, 0},  "macOS", {"Yosemite",      {10, 10, 2}}},
	"14C2513"    = {{14, 1, 0},  "macOS", {"Yosemite",      {10, 10, 2}}},
	"14D131"     = {{14, 3, 0},  "macOS", {"Yosemite",      {10, 10, 3}}},
	"14D136"     = {{14, 3, 0},  "macOS", {"Yosemite",      {10, 10, 3}}},
	"14E46"      = {{14, 4, 0},  "macOS", {"Yosemite",      {10, 10, 4}}},
	"14F27"      = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F1021"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F1505"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F1509"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F1605"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F1713"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F1808"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F1909"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F1912"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F2009"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F2109"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F2315"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F2411"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},
	"14F2511"    = {{14, 5, 0},  "macOS", {"Yosemite",      {10, 10, 5}}},

	// MacOS El Capitan
	"15A284"     = {{15, 0, 0}, "macOS", {"El Capitan",     {10, 11, 0}}},
	"15B42"      = {{15, 0, 0}, "macOS", {"El Capitan",     {10, 11, 1}}},
	"15C50"      = {{15, 2, 0}, "macOS", {"El Capitan",     {10, 11, 2}}},
	"15D21"      = {{15, 3, 0}, "macOS", {"El Capitan",     {10, 11, 3}}},
	"15E65"      = {{15, 4, 0}, "macOS", {"El Capitan",     {10, 11, 4}}},
	"15F34"      = {{15, 5, 0}, "macOS", {"El Capitan",     {10, 11, 5}}},
	"15G31"      = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G1004"    = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G1011"    = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G1108"    = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G1212"    = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G1217"    = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G1421"    = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G1510"    = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G1611"    = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G17023"   = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G18013"   = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G19009"   = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G20015"   = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G21013"   = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},
	"15G22010"   = {{15, 6, 0}, "macOS", {"El Capitan",     {10, 11, 6}}},

	// MacOS Sierra
	"16A323"     = {{16, 0, 0}, "macOS", {"Sierra",         {10, 12, 0}}},
	"16B2555"    = {{16, 1, 0}, "macOS", {"Sierra",         {10, 12, 1}}},
	"16B2657"    = {{16, 1, 0}, "macOS", {"Sierra",         {10, 12, 1}}},
	"16C67"      = {{16, 3, 0}, "macOS", {"Sierra",         {10, 12, 2}}},
	"16C68"      = {{16, 3, 0}, "macOS", {"Sierra",         {10, 12, 2}}},
	"16D32"      = {{16, 4, 0}, "macOS", {"Sierra",         {10, 12, 3}}},
	"16E195"     = {{16, 5, 0}, "macOS", {"Sierra",         {10, 12, 4}}},
	"16F73"      = {{16, 6, 0}, "macOS", {"Sierra",         {10, 12, 5}}},
	"16F2073"    = {{16, 6, 0}, "macOS", {"Sierra",         {10, 12, 5}}},
	"16G29"      = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1036"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1114"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1212"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1314"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1408"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1510"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1618"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1710"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1815"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1917"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G1918"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G2016"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G2127"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G2128"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},
	"16G2136"    = {{16, 7, 0}, "macOS", {"Sierra",         {10, 12, 6}}},

	// MacOS High Sierra
	"17A365"     = {{17, 0, 0}, "macOS", {"High Sierra",    {10, 13, 0}}},
	"17A405"     = {{17, 0, 0}, "macOS", {"High Sierra",    {10, 13, 0}}},
	"17B48"      = {{17, 2, 0}, "macOS", {"High Sierra",    {10, 13, 1}}},
	"17B1002"    = {{17, 2, 0}, "macOS", {"High Sierra",    {10, 13, 1}}},
	"17B1003"    = {{17, 2, 0}, "macOS", {"High Sierra",    {10, 13, 1}}},
	"17C88"      = {{17, 3, 0}, "macOS", {"High Sierra",    {10, 13, 2}}},
	"17C89"      = {{17, 3, 0}, "macOS", {"High Sierra",    {10, 13, 2}}},
	"17C205"     = {{17, 3, 0}, "macOS", {"High Sierra",    {10, 13, 2}}},
	"17C2205"    = {{17, 3, 0}, "macOS", {"High Sierra",    {10, 13, 2}}},
	"17D47"      = {{17, 4, 0}, "macOS", {"High Sierra",    {10, 13, 3}}},
	"17D2047"    = {{17, 4, 0}, "macOS", {"High Sierra",    {10, 13, 3}}},
	"17D102"     = {{17, 4, 0}, "macOS", {"High Sierra",    {10, 13, 3}}},
	"17D2102"    = {{17, 4, 0}, "macOS", {"High Sierra",    {10, 13, 3}}},
	"17E199"     = {{17, 5, 0}, "macOS", {"High Sierra",    {10, 13, 4}}},
	"17E202"     = {{17, 5, 0}, "macOS", {"High Sierra",    {10, 13, 4}}},
	"17F77"      = {{17, 6, 0}, "macOS", {"High Sierra",    {10, 13, 5}}},
	"17G65"      = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G2208"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G2307"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G3025"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G4015"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G5019"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G6029"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G6030"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G7024"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G8029"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G8030"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G8037"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G9016"    = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G10021"   = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G11023"   = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G12034"   = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G13033"   = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G13035"   = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G14019"   = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G14033"   = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},
	"17G14042"   = {{17, 7, 0}, "macOS", {"High Sierra",    {10, 13, 6}}},

	// MacOS Mojave
	"18A391"     = {{18, 0, 0}, "macOS", {"Mojave",         {10, 14, 0}}},
	"18B75"      = {{18, 2, 0}, "macOS", {"Mojave",         {10, 14, 1}}},
	"18B2107"    = {{18, 2, 0}, "macOS", {"Mojave",         {10, 14, 1}}},
	"18B3094"    = {{18, 2, 0}, "macOS", {"Mojave",         {10, 14, 1}}},
	"18C54"      = {{18, 2, 0}, "macOS", {"Mojave",         {10, 14, 2}}},
	"18D42"      = {{18, 2, 0}, "macOS", {"Mojave",         {10, 14, 3}}},
	"18D43"      = {{18, 2, 0}, "macOS", {"Mojave",         {10, 14, 3}}},
	"18D109"     = {{18, 2, 0}, "macOS", {"Mojave",         {10, 14, 3}}},
	"18E226"     = {{18, 5, 0}, "macOS", {"Mojave",         {10, 14, 4}}},
	"18E227"     = {{18, 5, 0}, "macOS", {"Mojave",         {10, 14, 4}}},
	"18F132"     = {{18, 6, 0}, "macOS", {"Mojave",         {10, 14, 5}}},
	"18G84"      = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G87"      = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G95"      = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G103"     = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G1012"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G2022"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G3020"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G4032"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G5033"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G6020"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G6032"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G6042"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G7016"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G8012"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G8022"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G9028"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G9216"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},
	"18G9323"    = {{18, 7, 0}, "macOS", {"Mojave",         {10, 14, 6}}},

	// MacOS Catalina
	"19A583"     = {{19, 0, 0}, "macOS", {"Catalina",       {10, 15, 0}}},
	"19A602"     = {{19, 0, 0}, "macOS", {"Catalina",       {10, 15, 0}}},
	"19A603"     = {{19, 0, 0}, "macOS", {"Catalina",       {10, 15, 0}}},
	"19B88"      = {{19, 0, 0}, "macOS", {"Catalina",       {10, 15, 1}}},
	"19C57"      = {{19, 2, 0}, "macOS", {"Catalina",       {10, 15, 2}}},
	"19C58"      = {{19, 2, 0}, "macOS", {"Catalina",       {10, 15, 2}}},
	"19D76"      = {{19, 3, 0}, "macOS", {"Catalina",       {10, 15, 3}}},
	"19E266"     = {{19, 4, 0}, "macOS", {"Catalina",       {10, 15, 4}}},
	"19E287"     = {{19, 4, 0}, "macOS", {"Catalina",       {10, 15, 4}}},
	"19F96"      = {{19, 5, 0}, "macOS", {"Catalina",       {10, 15, 5}}},
	"19F101"     = {{19, 5, 0}, "macOS", {"Catalina",       {10, 15, 5}}},
	"19G73"      = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 6}}},
	"19G2021"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 6}}},
	"19H2"       = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H4"       = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H15"      = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H114"     = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H512"     = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H524"     = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1030"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1217"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1323"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1417"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1419"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1519"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1615"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1713"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1715"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1824"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H1922"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},
	"19H2026"    = {{19, 6, 0}, "macOS", {"Catalina",       {10, 15, 7}}},

	// MacOS Big Sur
	"20A2411"    = {{20, 1, 0}, "macOS", {"Big Sur",        {11, 0, 0}}},
	"20B29"      = {{20, 1, 0}, "macOS", {"Big Sur",        {11, 0, 1}}},
	"20B50"      = {{20, 1, 0}, "macOS", {"Big Sur",        {11, 0, 1}}},
	"20C69"      = {{20, 2, 0}, "macOS", {"Big Sur",        {11, 1, 0}}},
	"20D64"      = {{20, 3, 0}, "macOS", {"Big Sur",        {11, 2, 0}}},
	"20D74"      = {{20, 3, 0}, "macOS", {"Big Sur",        {11, 2, 1}}},
	"20D75"      = {{20, 3, 0}, "macOS", {"Big Sur",        {11, 2, 1}}},
	"20D80"      = {{20, 3, 0}, "macOS", {"Big Sur",        {11, 2, 2}}},
	"20D91"      = {{20, 3, 0}, "macOS", {"Big Sur",        {11, 2, 3}}},
	"20E232"     = {{20, 4, 0}, "macOS", {"Big Sur",        {11, 3, 0}}},
	"20E241"     = {{20, 4, 0}, "macOS", {"Big Sur",        {11, 3, 1}}},
	"20F71"      = {{20, 5, 0}, "macOS", {"Big Sur",        {11, 4, 0}}},
	"20G71"      = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 5, 0}}},
	"20G80"      = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 5, 1}}},
	"20G95"      = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 5, 2}}},
	"20G165"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 0}}},
	"20G224"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 1}}},
	"20G314"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 2}}},
	"20G415"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 3}}},
	"20G417"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 4}}},
	"20G527"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 5}}},
	"20G624"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 6}}},
	"20G630"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 7}}},
	"20G730"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 6, 8}}},
	"20G817"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 0}}},
	"20G918"     = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 1}}},
	"20G1020"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 2}}},
	"20G1116"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 3}}},
	"20G1120"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 4}}},
	"20G1225"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 5}}},
	"20G1231"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 6}}},
	"20G1345"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 7}}},
	"20G1351"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 8}}},
	"20G1426"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 9}}},
	"20G1427"    = {{20, 6, 0}, "macOS", {"Big Sur",        {11, 7, 10}}},

	// MacOS Monterey
	"21A344"     = {{21, 0, 1}, "macOS", {"Monterey",       {12, 0, 0}}},
	"21A559"     = {{21, 1, 0}, "macOS", {"Monterey",       {12, 0, 1}}},
	"21C52"      = {{21, 2, 0}, "macOS", {"Monterey",       {12, 1, 0}}},
	"21D49"      = {{21, 3, 0}, "macOS", {"Monterey",       {12, 2, 0}}},
	"21D62"      = {{21, 3, 0}, "macOS", {"Monterey",       {12, 2, 1}}},
	"21E230"     = {{21, 4, 0}, "macOS", {"Monterey",       {12, 3, 0}}},
	"21E258"     = {{21, 4, 0}, "macOS", {"Monterey",       {12, 3, 1}}},
	"21F79"      = {{21, 5, 0}, "macOS", {"Monterey",       {12, 4, 0}}},
	"21F2081"    = {{21, 5, 0}, "macOS", {"Monterey",       {12, 4, 0}}},
	"21F2092"    = {{21, 5, 0}, "macOS", {"Monterey",       {12, 4, 0}}},
	"21G72"      = {{21, 6, 0}, "macOS", {"Monterey",       {12, 5, 0}}},
	"21G83"      = {{21, 6, 0}, "macOS", {"Monterey",       {12, 5, 1}}},
	"21G115"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 0}}},
	"21G217"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 1}}},
	"21G320"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 2}}},
	"21G419"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 3}}},
	"21G526"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 4}}},
	"21G531"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 5}}},
	"21G646"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 6}}},
	"21G651"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 7}}},
	"21G725"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 8}}},
	"21G726"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 6, 9}}},
	"21G816"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 7, 0}}},
	"21G920"     = {{21, 6, 0}, "macOS", {"Monterey",       {12, 7, 1}}},
	"21G1974"    = {{21, 6, 0}, "macOS", {"Monterey",       {12, 7, 2}}},

	// MacOS Ventura 
	"22A380"     = {{22, 1, 0}, "macOS", {"Ventura",        {13, 0, 0}}},
	"22A400"     = {{22, 1, 0}, "macOS", {"Ventura",        {13, 0, 1}}},
	"22C65"	     = {{22, 2, 0}, "macOS", {"Ventura",        {13, 1, 0}}},
	"22D49"	     = {{22, 3, 0}, "macOS", {"Ventura",        {13, 2, 0}}},
	"22D68"	     = {{22, 3, 0}, "macOS", {"Ventura",        {13, 2, 1}}},
	"22E252"     = {{22, 4, 0}, "macOS", {"Ventura",        {13, 3, 0}}},
	"22E261"     = {{22, 4, 0}, "macOS", {"Ventura",        {13, 3, 1}}},
	"22F66"	     = {{22, 5, 0}, "macOS", {"Ventura",        {13, 4, 0}}},
	"22F82"	     = {{22, 5, 0}, "macOS", {"Ventura",        {13, 4, 1}}},
	"22E772610a" = {{22, 5, 0}, "macOS", {"Ventura",        {13, 4, 1}}},
	"22F770820d" = {{22, 5, 0}, "macOS", {"Ventura",        {13, 4, 1}}},
	"22G74"	     = {{22, 6, 0}, "macOS", {"Ventura",        {13, 5, 0}}},
	"22G90"	     = {{22, 6, 0}, "macOS", {"Ventura",        {13, 5, 1}}},
	"22G91"	     = {{22, 6, 0}, "macOS", {"Ventura",        {13, 5, 2}}},
	"22G120"     = {{22, 6, 0}, "macOS", {"Ventura",        {13, 6, 0}}},
	"22G313"     = {{22, 6, 0}, "macOS", {"Ventura",        {13, 6, 1}}},
	"22G320"     = {{22, 6, 0}, "macOS", {"Ventura",        {13, 6, 2}}},

	// MacOS Sonoma 
	"23A344"     = {{23, 0, 0}, "macOS", {"Sonoma",         {14, 0, 0}}},
	"23B74"      = {{23, 1, 0}, "macOS", {"Sonoma",         {14, 1, 0}}},
	"23B81"      = {{23, 1, 0}, "macOS", {"Sonoma",         {14, 1, 1}}},
	"23B2082"    = {{23, 1, 0}, "macOS", {"Sonoma",         {14, 1, 1}}},
	"23B92"      = {{23, 1, 0}, "macOS", {"Sonoma",         {14, 1, 2}}},
	"23B2091"    = {{23, 1, 0}, "macOS", {"Sonoma",         {14, 1, 2}}},
	"23C64"      = {{23, 2, 0}, "macOS", {"Sonoma",         {14, 2, 0}}},
	"23C71"      = {{23, 2, 0}, "macOS", {"Sonoma",         {14, 2, 1}}},
	"23D56"      = {{23, 3, 0}, "macOS", {"Sonoma",         {14, 3, 0}}},
	"23D60"      = {{23, 3, 0}, "macOS", {"Sonoma",         {14, 3, 1}}},
	"23E214"     = {{23, 4, 0}, "macOS", {"Sonoma",         {14, 4, 0}}},
	"23E224"     = {{23, 4, 0}, "macOS", {"Sonoma",         {14, 4, 1}}},
	"23F79"      = {{23, 5, 0}, "macOS", {"Sonoma",         {14, 5, 0}}},
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
