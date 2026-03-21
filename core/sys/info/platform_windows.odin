package sysinfo

import     "base:intrinsics"
import     "base:runtime"
import     "core:strings"
import     "core:unicode/utf16"
import sys "core:sys/windows"

@(private)
_os_version :: proc (allocator: runtime.Allocator, loc := #caller_location) -> (res: OS_Version, ok: bool) {
	/*
	NOTE(Jeroen):
		`GetVersionEx`  will return 6.2 for Windows 10 unless the program is manifested for Windows 10.
		`RtlGetVersion` will return the true version.

		Rather than include the WinDDK, we ask the kernel directly.
		`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion` is for the minor build version (Update Build Release)
	*/
	res.platform = .Windows

	osvi: sys.OSVERSIONINFOEXW
	osvi.dwOSVersionInfoSize = size_of(osvi)
	if status := sys.RtlGetVersion(&osvi); status != 0 {
		return res, false
	}

	product_type: sys.Windows_Product_Type
	sys.GetProductInfo(
		osvi.dwMajorVersion,         osvi.dwMinorVersion,
		u32(osvi.wServicePackMajor), u32(osvi.wServicePackMinor),
		&product_type,
	)

	res.os.major     = int(osvi.dwMajorVersion)
	res.os.minor     = int(osvi.dwMinorVersion)
	res.kernel.major = int(osvi.dwMajorVersion)
	res.kernel.minor = int(osvi.dwBuildNumber)

	b := strings.builder_make_none(allocator = allocator, loc = loc)

	strings.write_string(&b, "Windows ")

	switch osvi.dwMajorVersion {
	case 10:
		switch osvi.wProductType {
		case 1: // VER_NT_WORKSTATION:
			if osvi.dwBuildNumber < 22000 {
				strings.write_string(&b, "10 ")
			} else {
				strings.write_string(&b, "11 ")
			}
			format_windows_product_type(&b, product_type)

		case: // Server or Domain Controller
			switch osvi.dwBuildNumber {
			case 14393:
				strings.write_string(&b, "2016 Server")
			case 17763:
				strings.write_string(&b, "2019 Server")
			case 20348:
				strings.write_string(&b, "2022 Server")
			case:
				strings.write_string(&b, "Unknown Server")
			}
		}

	case 6:
		switch osvi.dwMinorVersion {
		case 0:
			switch osvi.wProductType {
			case 1: // VER_NT_WORKSTATION
				strings.write_string(&b, "Windows Vista ")
				format_windows_product_type(&b, product_type)
			case 3:
				strings.write_string(&b, "Windows Server 2008")
			}

		case 1:
			switch osvi.wProductType {
			case 1: // VER_NT_WORKSTATION:
				strings.write_string(&b, "Windows 7 ")
				format_windows_product_type(&b, product_type)
			case 3:
				strings.write_string(&b, "Windows Server 2008 R2")
			}

		case 2:
			switch osvi.wProductType {
			case 1: // VER_NT_WORKSTATION:
				strings.write_string(&b, "Windows 8 ")
				format_windows_product_type(&b, product_type)
			case 3:
				strings.write_string(&b, "Windows Server 2012")
			}

		case 3:
			switch osvi.wProductType {
			case 1: // VER_NT_WORKSTATION:
				strings.write_string(&b, "Windows 8.1 ")
				format_windows_product_type(&b, product_type)
			case 3:
				strings.write_string(&b, "Windows Server 2012 R2")
			}
		}

	case 5:
		switch osvi.dwMinorVersion {
		case 0:
			strings.write_string(&b, "Windows 2000")
		case 1:
			strings.write_string(&b, "Windows XP")
		case 2:
			strings.write_string(&b, "Windows Server 2003")
		}
	}

	// Grab DisplayVersion
	res.release = format_display_version(&b)

	// Grab build number and UBR
	res.kernel.patch = format_build_number(&b, int(osvi.dwBuildNumber))

	// Finish the string
	res.full = strings.to_string(b)

	format_windows_product_type :: proc (b: ^strings.Builder, prod_type: sys.Windows_Product_Type) {
		#partial switch prod_type {
		case .ULTIMATE:
			strings.write_string(b, "Ultimate")

		case .HOME_BASIC:
			strings.write_string(b, "Home Basic")

		case .HOME_PREMIUM:
			strings.write_string(b, "Home Premium")

		case .ENTERPRISE:
			strings.write_string(b, "Enterprise")

		case .CORE:
			strings.write_string(b, "Home Basic")

		case .HOME_BASIC_N:
			strings.write_string(b, "Home Basic N")

		case .EDUCATION:
			strings.write_string(b, "Education")

		case .EDUCATION_N:
			strings.write_string(b, "Education N")

		case .BUSINESS:
			strings.write_string(b, "Business")

		case .STANDARD_SERVER:
			strings.write_string(b, "Standard Server")

		case .DATACENTER_SERVER:
			strings.write_string(b, "Datacenter")

		case .SMALLBUSINESS_SERVER:
			strings.write_string(b, "Windows Small Business Server")

		case .ENTERPRISE_SERVER:
			strings.write_string(b, "Enterprise Server")

		case .STARTER:
			strings.write_string(b, "Starter")

		case .DATACENTER_SERVER_CORE:
			strings.write_string(b, "Datacenter Server Core")

		case .STANDARD_SERVER_CORE:
			strings.write_string(b, "Server Standard Core")

		case .ENTERPRISE_SERVER_CORE:
			strings.write_string(b, "Enterprise Server Core")

		case .BUSINESS_N:
			strings.write_string(b, "Business N")

		case .HOME_SERVER:
			strings.write_string(b, "Home Server")

		case .SERVER_FOR_SMALLBUSINESS:
			strings.write_string(b, "Windows Server 2008 for Windows Essential Server Solutions")

		case .SMALLBUSINESS_SERVER_PREMIUM:
			strings.write_string(b, "Small Business Server Premium")

		case .HOME_PREMIUM_N:
			strings.write_string(b, "Home Premium N")

		case .ENTERPRISE_N:
			strings.write_string(b, "Enterprise N")

		case .ULTIMATE_N:
			strings.write_string(b, "Ultimate N")

		case .HYPERV:
			strings.write_string(b, "HyperV")

		case .STARTER_N:
			strings.write_string(b, "Starter N")

		case .PROFESSIONAL:
			strings.write_string(b, "Professional")

		case .PROFESSIONAL_N:
			strings.write_string(b, "Professional N")

		case:
			strings.write_string(b, "Unknown Edition")
		}
	}

	// Grab Windows DisplayVersion (like 20H02)
	format_display_version :: proc (b: ^strings.Builder) -> (version: string) {
		scratch: [512]u8

		if dv, ok := read_reg_string(
			sys.HKEY_LOCAL_MACHINE,
			"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
			"DisplayVersion",
			scratch[:],
		); ok {
			strings.write_string(b, " (version: ")
			l := strings.builder_len(b^)
			strings.write_string(b, dv)
			version = strings.to_string(b^)[l:][:len(dv)]
			strings.write_rune(b, ')')
		}
		return
	}

	// Grab build number and UBR
	format_build_number :: proc (b: ^strings.Builder, major_build: int) -> (ubr: int) {
		if res, ok := read_reg_i32(
			sys.HKEY_LOCAL_MACHINE,
			"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
			"UBR",
		); ok {
			ubr = int(res)
			strings.write_string(b, ", build: ")
			strings.write_int(b, major_build)
			strings.write_rune(b, '.')
			strings.write_int(b, ubr)
		}
		return
	}

	return res, true
}

@(private)
_ram_stats :: proc "contextless" () -> (total_ram, free_ram, total_swap, free_swap: i64, ok: bool) {
	state: sys.MEMORYSTATUSEX

	state.dwLength = size_of(state)
	if ok := sys.GlobalMemoryStatusEx(&state); !ok {
		return
	}

	total_ram  = i64(state.ullTotalPhys)
	free_ram   = i64(state.ullAvailPhys)
	total_swap = i64(state.ullTotalPageFil)
	free_swap  = i64(state.ullAvailPageFil)
	ok         = true

	return
}

_iterate_gpus :: proc(it: ^GPU_Iterator, minimum_vram := i64(256 * 1024 * 1024)) -> (gpu: GPU, index: int, ok: bool) {
	GPU_ROOT_KEY :: `SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}`

	defer it.index += 1

	gpu_key: sys.HKEY
	if status := sys.RegOpenKeyExW(
		sys.HKEY_LOCAL_MACHINE,
		GPU_ROOT_KEY,
		0,
		sys.KEY_ENUMERATE_SUB_KEYS,
		&gpu_key,
	); status != i32(sys.ERROR_SUCCESS) {
		return {}, it.index, false
	}
	defer sys.RegCloseKey(gpu_key)

	buf_wstring: [100]u16
	buf_len := u32(len(buf_wstring))
	buf_key:     [4 * len(buf_wstring)]u8
	buf_leaf:    [100]u8
	leaf:        string

	gpu_loop: {
		defer it._index += 1

		if status := sys.RegEnumKeyW(
			gpu_key,
			auto_cast it._index,
			&buf_wstring[0],
			&buf_len,
		); status != i32(sys.ERROR_SUCCESS) {
			return {}, it.index, false
		}

		utf16.decode_to_utf8(buf_leaf[:], buf_wstring[:])
		leaf = string(cstring(&buf_leaf[0]))

		// Skip leaves that are not of the form 000x
		if is_integer(leaf) {
			break gpu_loop
		}
	}

	n := copy(buf_key[:], GPU_ROOT_KEY)
	buf_key[n] = '\\'
	copy(buf_key[n+1:], leaf)

	key_len := len(GPU_ROOT_KEY) + len(leaf) + 1

	utf16.encode_string(buf_wstring[:], string(buf_key[:key_len]))
	key := cstring16(&buf_wstring[0])

	// Determine if this is a real GPU, or perhaps a screen mirroring or RDP driver
	// Real devices tend to have more than 256 MiB of VRAM
	gpu.vram, _ = read_reg_i64   (sys.HKEY_LOCAL_MACHINE, key, "HardwareInformation.qwMemorySize")
	if gpu.vram < minimum_vram {
		return
	}

	// Real devices tend to have a matching PCI device
	matching,   _ := read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "MatchingDeviceId", it._buffer[:100])
	if !strings.has_prefix(matching, "PCI\\VEN") {
		return
	}

	gpu.vendor, _ = read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "ProviderName",  it._buffer[  0:][:100])
	gpu.model,  _ = read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "DriverDesc",    it._buffer[100:][:100])
	gpu.driver, _ = read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "DriverVersion", it._buffer[200:][:100])

	return gpu, it.index, true
}

@(private)
read_reg_string :: proc "contextless" (hkey: sys.HKEY, subkey, val: cstring16, res_buf: []u8) -> (res: string, ok: bool) {
	if len(subkey) == 0 || len(val) == 0 {
		return
	}

	buf_utf16: [1024]u16

	result_size := sys.DWORD(size_of(buf_utf16))
	status := sys.RegGetValueW(
		hkey,
		subkey,
		val,
		sys.RRF_RT_REG_SZ,
		nil,
		raw_data(buf_utf16[:]),
		&result_size,
	)
	if status != 0 {
		// Couldn't retrieve string
		return
	}

	utf16.decode_to_utf8(res_buf[:result_size], buf_utf16[:])
	res = string(cstring(&res_buf[0]))
	return res, true
}

@(private)
read_reg_i32 :: proc "contextless" (hkey: sys.HKEY, subkey, val: cstring16) -> (res: i32, ok: bool) {
	if len(subkey) == 0 || len(val) == 0 {
		return
	}

	result_size := sys.DWORD(size_of(i32))
	status := sys.RegGetValueW(
		hkey,
		subkey,
		val,
		sys.RRF_RT_REG_DWORD,
		nil,
		&res,
		&result_size,
	)
	return res, status == 0
}

@(private)
read_reg_i64 :: proc "contextless" (hkey: sys.HKEY, subkey, val: cstring16) -> (res: i64, ok: bool) {
	if len(subkey) == 0 || len(val) == 0 {
		return
	}

	result_size := sys.DWORD(size_of(i64))
	status := sys.RegGetValueW(
		hkey,
		subkey,
		val,
		sys.RRF_RT_REG_QWORD,
		nil,
		&res,
		&result_size,
	)
	return res, status == 0
}

@(private)
is_integer :: proc "contextless" (s: string) -> (ok: bool) {
	if s == "" {
		return
	}

	ok = true

	for r in s {
		switch r {
		case '0'..='9': continue
		case: return false
		}
	}
	return
}