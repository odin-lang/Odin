/*
Gathers system information on `Windows`, `Linux`, `macOS`, `FreeBSD` & `OpenBSD`.

Simply import the package and you'll have access to the OS version, RAM amount
and CPU information.

On Windows, GPUs will also be enumerated using the registry.

CPU feature flags can be tested against `cpu_features`, where applicable, e.g.
`if .aes in info.cpu_features.? { ... }`

Example:
	package main

	import "core:fmt"
	import si "core:sys/info"

	main :: proc() {
		fmt.printfln("Odin:      %v",      ODIN_VERSION)
		fmt.printfln("OS:        %v",      si.os_version.as_string)
		fmt.printfln("OS:        %#v",     si.os_version)
		fmt.printfln("CPU:       %v",      si.cpu.name)
		fmt.printfln("CPU cores: %vc/%vt", si.cpu.physical_cores, si.cpu.logical_cores)
		fmt.printfln("RAM:       %#.1M",   si.ram.total_ram)

		fmt.println()
		for gpu, i in si.gpus {
			fmt.printfln("GPU #%v:", i)
			fmt.printfln("\tVendor: %v",    gpu.vendor_name)
			fmt.printfln("\tModel:  %v",    gpu.model_name)
			fmt.printfln("\tVRAM:   %#.1M", gpu.total_ram)
		}
	}

- Example Windows output:

	Odin:      dev-2025-10
	OS:        Windows 10 Professional (version: 22H2), build: 19045.6396
	OS:        OS_Version{
		platform = "Windows",
		_ = Version{
			major = 10,
			minor = 0,
			patch = 0,
		},
		build = [
			19045,
			6396,
		],
		version = "22H2",
		as_string = "Windows 10 Professional (version: 22H2), build: 19045.6396",
	}
	CPU:       AMD Ryzen 9 5950X 16-Core Processor
	CPU cores: 16c/32t
	RAM:       63.9 GiB

	GPU #0:
		Vendor: Advanced Micro Devices, Inc.
		Model:  AMD Radeon RX 9070
		VRAM:   15.9 GiB

- Example macOS output:

	ODIN: dev-2022-09
	OS:   OS_Version{
			platform = "MacOS",
			major = 21,
			minor = 5,
			patch = 0,
			build = [
					0,
					0,
			],
			version = "21F79",
			as_string = "macOS Monterey 12.4 (build 21F79, kernel 21.5.0)",
	}
	CPU:  Intel(R) Core(TM) i5-7360U CPU @ 2.30GHz
	RAM:  8.0 GiB
*/
package sysinfo

/*
Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
Made available under Odin's BSD-3 license.

List of contributors:
	Jeroen van Rijn: Initial implementation.
	Laytan: ARM and RISC-V CPU feature detection, iOS/macOS platform overhaul.
*/