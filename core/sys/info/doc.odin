/*
Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
Made available under Odin's BSD-3 license.

Package `core:sys/info` gathers system information on:
Windows, Linux, macOS, FreeBSD & OpenBSD.

Simply import the package and you'll have access to the OS version, RAM amount
and CPU information.

On Windows, GPUs will also be enumerated using the registry.

CPU feature flags can be tested against `cpu_features`, where applicable, e.g.
`if .aes in si.aes { ... }`

Example:

	import "core:fmt"
	import si "core:sys/info"

	main :: proc() {
		fmt.printf("Odin:  %v\n",     ODIN_VERSION)
		fmt.printf("OS:    %v\n",     si.os_version.as_string)
		fmt.printf("OS:    %#v\n",    si.os_version)
		fmt.printf("CPU:   %v\n",     si.cpu_name)
		fmt.printf("RAM:   %v MiB\n", si.ram.total_ram / 1024 / 1024)

		fmt.println()
		for gpu, i in si.gpus {
			fmt.printf("GPU #%v:\n", i)
			fmt.printf("\tVendor: %v\n",     gpu.vendor_name)
			fmt.printf("\tModel:  %v\n",     gpu.model_name)
			fmt.printf("\tVRAM:   %v MiB\n", gpu.total_ram / 1024 / 1024)
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
	RAM:   65469 MiB
	GPU #0:
		Vendor: Advanced Micro Devices, Inc.
		Model:  Radeon RX Vega
		VRAM:   8176 MiB

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
	RAM:  8192 MiB
*/
package sysinfo
