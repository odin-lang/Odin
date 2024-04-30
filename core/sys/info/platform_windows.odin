package sysinfo

import sys "core:sys/windows"
import "base:intrinsics"
import "core:strings"
import "core:unicode/utf16"

import "core:fmt"
import "base:runtime"

@(private)
version_string_buf: [1024]u8

@(init, private)
init_os_version :: proc () {
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
		dv, ok := read_reg_string(
			sys.HKEY_LOCAL_MACHINE,
			"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
			"DisplayVersion",
		)
		defer delete(dv) // It'll be interned into `version_string_buf`

		if ok {
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
		res, ok := read_reg_i32(
			sys.HKEY_LOCAL_MACHINE,
			"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion",
			"UBR",
		)

		if ok {
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
init_ram :: proc() {
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
init_gpu_info :: proc() {

	GPU_INFO_BASE :: "SYSTEM\\ControlSet001\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\"

	gpu_list: [dynamic]GPU
	gpu_index: int

	for {
		key := fmt.tprintf("%v\\%04d", GPU_INFO_BASE, gpu_index)

		if vendor, ok := read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "ProviderName"); ok {
			append(&gpu_list, GPU{vendor_name = vendor})
		} else {
			break
		}

		if desc, ok := read_reg_string(sys.HKEY_LOCAL_MACHINE, key, "DriverDesc"); ok {
			gpu_list[gpu_index].model_name = desc
		}

		if vram, ok := read_reg_i64(sys.HKEY_LOCAL_MACHINE, key, "HardwareInformation.qwMemorySize"); ok {
			gpu_list[gpu_index].total_ram = int(vram)
		}
		gpu_index += 1
	}
	gpus = gpu_list[:]
}

@(private)
read_reg_string :: proc(hkey: sys.HKEY, subkey, val: string) -> (res: string, ok: bool) {
	if len(subkey) == 0 || len(val) == 0 {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	BUF_SIZE :: 1024
	key_name_wide := make([]u16, BUF_SIZE, context.temp_allocator)
	val_name_wide := make([]u16, BUF_SIZE, context.temp_allocator)

	utf16.encode_string(key_name_wide, subkey)
	utf16.encode_string(val_name_wide, val)

	result_wide := make([]u16, BUF_SIZE, context.temp_allocator)
	result_size := sys.DWORD(BUF_SIZE * size_of(u16))

	status := sys.RegGetValueW(
		hkey,
		&key_name_wide[0],
		&val_name_wide[0],
		sys.RRF_RT_REG_SZ,
		nil,
		raw_data(result_wide[:]),
		&result_size,
	)
	if status != 0 {
		// Couldn't retrieve string
		return
	}

	// Result string will be allocated for the caller.
	result_utf8 := make([]u8, BUF_SIZE * 4, context.temp_allocator)
	utf16.decode_to_utf8(result_utf8, result_wide[:result_size])
	return strings.clone_from_cstring(cstring(raw_data(result_utf8))), true
}
@(private)
read_reg_i32 :: proc(hkey: sys.HKEY, subkey, val: string) -> (res: i32, ok: bool) {
	if len(subkey) == 0 || len(val) == 0 {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	BUF_SIZE :: 1024
	key_name_wide := make([]u16, BUF_SIZE, context.temp_allocator)
	val_name_wide := make([]u16, BUF_SIZE, context.temp_allocator)

	utf16.encode_string(key_name_wide, subkey)
	utf16.encode_string(val_name_wide, val)

	result_size := sys.DWORD(size_of(i32))
	status := sys.RegGetValueW(
		hkey,
		&key_name_wide[0],
		&val_name_wide[0],
		sys.RRF_RT_REG_DWORD,
		nil,
		&res,
		&result_size,
	)
	return res, status == 0
}
@(private)
read_reg_i64 :: proc(hkey: sys.HKEY, subkey, val: string) -> (res: i64, ok: bool) {
	if len(subkey) == 0 || len(val) == 0 {
		return
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	BUF_SIZE :: 1024
	key_name_wide := make([]u16, BUF_SIZE, context.temp_allocator)
	val_name_wide := make([]u16, BUF_SIZE, context.temp_allocator)

	utf16.encode_string(key_name_wide, subkey)
	utf16.encode_string(val_name_wide, val)

	result_size := sys.DWORD(size_of(i64))
	status := sys.RegGetValueW(
		hkey,
		&key_name_wide[0],
		&val_name_wide[0],
		sys.RRF_RT_REG_QWORD,
		nil,
		&res,
		&result_size,
	)
	return res, status == 0
}
