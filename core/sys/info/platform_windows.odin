package sysinfo

import sys "core:sys/windows"
import "base:intrinsics"
import "core:strings"
import "core:unicode/utf16"
import "base:runtime"

@(init, private)
init_os_version :: proc "contextless" () {
	// NOTE(Jeroen): Only needed for the string builder.
	context = runtime.default_context()

	/*
		NOTE(Jeroen):
			`GetVersionEx`  will return 6.2 for Windows 10 unless the program is manifested for Windows 10.
			`RtlGetVersion` will return the true version.

			Rather than include the WinDDK, we ask the kernel directly.
			`HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion` is for the minor build version (Update Build Release)

	*/
	os_version.platform = .Windows

	osvi: sys.OSVERSIONINFOEXW
	osvi.dwOSVersionInfoSize = size_of(osvi)
	status := sys.RtlGetVersion(&osvi)

	if status != 0 {
		return
	}

	product_type: sys.Windows_Product_Type
	sys.GetProductInfo(
		osvi.dwMajorVersion,         osvi.dwMinorVersion,
		u32(osvi.wServicePackMajor), u32(osvi.wServicePackMinor),
		&product_type,
	)

	os_version.major    = int(osvi.dwMajorVersion)
	os_version.minor    = int(osvi.dwMinorVersion)
	os_version.build[0] = int(osvi.dwBuildNumber)


	b := strings.builder_from_bytes(version_string_buf[:])
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
	os_version.version = format_display_version(&b)

	// Grab build number and UBR
	os_version.build[1]  = format_build_number(&b, int(osvi.dwBuildNumber))

	// Finish the string
	os_version.as_string = strings.to_string(b)

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
}

@(init, private)
init_ram :: proc "contextless" () {
	state: sys.MEMORYSTATUSEX

	state.dwLength = size_of(state)
	ok := sys.GlobalMemoryStatusEx(&state)
	if !ok {
		return
	}
	ram = RAM{
		total_ram  = int(state.ullTotalPhys),
		free_ram   = int(state.ullAvailPhys),
		total_swap = int(state.ullTotalPageFil),
		free_swap  = int(state.ullAvailPageFil),
	}
}

@(init, private)
init_gpu_info :: proc "contextless" () {
	GPU_ROOT_KEY :: `SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}`

	gpu_key: sys.HKEY
	if status := sys.RegOpenKeyExW(
		sys.HKEY_LOCAL_MACHINE,
		GPU_ROOT_KEY,
		0,
		sys.KEY_ENUMERATE_SUB_KEYS,
		&gpu_key,
	); status != i32(sys.ERROR_SUCCESS) {
		return
	}
	defer sys.RegCloseKey(gpu_key)

	gpu: ^GPU
	gpu_count := 0

	index := sys.DWORD(0)
	gpu_loop: for {
		defer index += 1

		buf_wstring: [100]u16
		buf_len := u32(len(buf_wstring))
		buf_key:     [4 * len(buf_wstring)]u8
		buf_leaf:    [100]u8
		buf_scratch: [100]u8

		if status := sys.RegEnumKeyW(
			gpu_key,
			index,
			&buf_wstring[0],
			&buf_len,
		); status != i32(sys.ERROR_SUCCESS) {
			break
		}

		utf16.decode_to_utf8(buf_leaf[:], buf_wstring[:])
		leaf := string(cstring(&buf_leaf[0]))

		// Skip leafs that are not of the form 000x
		if !is_integer(leaf) {
			continue
		}

		n := copy(buf_key[:], GPU_ROOT_KEY)
		buf_key[n] = '\\'
		copy(buf_key[n+1:], leaf)

		key_len := len(GPU_ROOT_KEY) + len(leaf) + 1

		utf16.encode_string(buf_wstring[:], string(buf_key[:key_len]))
		key := cstring16(&buf_wstring[0])

		if res, ok := read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "ProviderName", buf_scratch[:]); ok {
			if vendor, s_ok := intern_gpu_string(res); s_ok {
				gpu = &_gpus[gpu_count]
				gpu.vendor_name = vendor
			} else {
				break gpu_loop
			}
		} else {
			continue
		}

		if res, ok := read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "DriverDesc", buf_scratch[:]); ok {
			if model_name, s_ok := intern_gpu_string(res); s_ok {
				gpu = &_gpus[gpu_count]
				gpu.model_name = model_name
			} else {
				break gpu_loop
			}
		}

		if vram, ok := read_reg_i64(sys.HKEY_LOCAL_MACHINE, key, "HardwareInformation.qwMemorySize"); ok {
			gpu.total_ram = int(vram)
		}

		gpu_count += 1
		if gpu_count > MAX_GPUS {
			break gpu_loop
		}
	}
	gpus = _gpus[:gpu_count]
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