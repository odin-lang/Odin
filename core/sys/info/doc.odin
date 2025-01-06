/*
Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
Made available under Odin's BSD-3 license.

List of contributors:
	Jeroen van Rijn: Initial implementation.
	Laytan: ARM and RISC-V CPU feature detection, iOS/macOS platform overhaul.
*/

/*
Package `core:sys/info` gathers system information on:
Windows, Linux, macOS, FreeBSD & OpenBSD.

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
		fmt.printfln("Odin:  %v",    ODIN_VERSION)
		fmt.printfln("OS:    %v",    si.os_version.as_string)
		fmt.printfln("OS:    %#v",   si.os_version)
		fmt.printfln("CPU:   %v",    si.cpu_name)
		fmt.printfln("RAM:   %#.1M", si.ram.total_ram)

		// fmt.printfln("Features: %v",      si.cpu_features)
		// fmt.printfln("MacOS version: %v", si.macos_version)

		fmt.println()
		for gpu, i in si.gpus {
			fmt.printfln("GPU #%v:", i)
			fmt.printfln("\tVendor: %v",    gpu.vendor_name)
			fmt.printfln("\tModel:  %v",    gpu.model_name)
			fmt.printfln("\tVRAM:   %#.1M", gpu.total_ram)
		}
	}

- Example Windows output:

	Odin:  dev-2022-09
	OS:    Windows 10 Professional (version: 20H2), build: 19042.1466
	OS:    OS_Version{
		platform = "Windows",
		major = 10,
		minor = 0,
		patch = 0,
		build = [
			19042,
			1466,
		],
		version = "20H2",
		as_string = "Windows 10 Professional (version: 20H2), build: 19042.1466",
	}
	CPU:   AMD Ryzen 7 1800X Eight-Core Processor
	RAM:   64.0 GiB
	GPU #0:
		Vendor: Advanced Micro Devices, Inc.
		Model:  Radeon RX Vega
		VRAM:   8.0 GiB

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
