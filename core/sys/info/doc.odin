/*
Gathers system information on `Windows`, `Linux`, `macOS`, `FreeBSD` & `OpenBSD`.

Simply import the package and you'll have access to the OS version, RAM amount
and CPU information.

On Windows, GPUs will also be enumerated using the registry.

CPU feature flags can be tested against `cpu_features`, where applicable, e.g.:
`if .aes in info.cpu_features() { ... }`

Example:
	package main

	import "core:fmt"
	import si "core:sys/info"

	main :: proc() {
		fmt.printfln("Odin:      %v",  ODIN_VERSION)
		if version, version_ok := si.os_version(context.allocator); version_ok {
			defer si.destroy_os_version(version, context.allocator)
			fmt.printfln("OS (full): %v", version.full)
			fmt.printfln("OS (rel):  %v", version.release)
			fmt.printfln("OS:        %v", version.os)
			fmt.printfln("Kernel:    %v", version.kernel)
		}
		fmt.printfln("CPU:       %v", si.cpu_name())
		fmt.printfln("           %v", si.cpu_features())
		if physical, logical, cores_ok := si.cpu_core_count(); cores_ok {
			fmt.printfln("CPU cores: %vc/%vt", physical, logical)
		}

		if total_ram, free_ram, total_swap, free_swap, ram_ok := si.ram_stats(); ram_ok {
			fmt.printfln("RAM:       %#.1M/%#.1M", free_ram,  total_ram)
			fmt.printfln("SWAP:      %#.1M/%#.1M", free_swap, total_swap)
		}

		it: si.GPU_Iterator
		for gpu, i in si.iterate_gpus(&it) {
			fmt.printfln("%d:", i)
			fmt.printfln("\tVendor: %v",    gpu.vendor)
			fmt.printfln("\tModel:  %v",    gpu.model)
			fmt.printfln("\tVRAM:   %#.1M", gpu.vram)
			fmt.printfln("\tDriver: %v",    gpu.driver)
		}
	}

	/*
	Example Windows output:

		Odin:      dev-2026-02
		OS (full): Windows 10 Professional (version: 22H2), build: 19045.6575
		OS (rel):  22H2
		OS:        Version{major = 10, minor = 0, patch = 0}
		Kernel:    Version{major = 10, minor = 19045, patch = 6575}
		CPU:       AMD Ryzen 9 5950X 16-Core Processor
		           CPU_Features{aes, adx, avx, avx2, bmi1, bmi2, erms, fma, os_xsave, pclmulqdq, popcnt, rdrand, rdseed, sha, sse2, sse3, ssse3, sse41, sse42}
		CPU cores: 16c/32t
		RAM:       32.1 GiB/63.9 GiB
		SWAP:      21.6 GiB/73.4 GiB

		GPU #0:
			Vendor: Advanced Micro Devices, Inc.
			Model:  AMD Radeon RX 9070
			VRAM:   15.9 GiB
			Driver: 32.0.22029.1019

	Example Linux output:

		Odin:      dev-2026-02
		OS (full): Ubuntu 24.04.3 LTS, Linux 6.6.87.2-microsoft-standard-WSL2
		OS (rel):  microsoft-standard-WSL2
		OS:        Version{major = 24, minor = 4, patch = 3}
		Kernel:    Version{major = 6, minor = 6, patch = 87}
		CPU:       AMD Ryzen 9 5950X 16-Core Processor
		           CPU_Features{aes, adx, avx, avx2, bmi1, bmi2, erms, fma, os_xsave, pclmulqdq, popcnt, rdrand, rdseed, sha, sse2, sse3, ssse3, sse41, sse42}
		CPU cores: 16c/32t
		RAM:       29.2 GiB/31.3 GiB
		SWAP:      8.0 GiB/8.0 GiB

	Example macOS output:

		Odin:      dev-2026-02
		OS (full): macOS Tahoe 26.3.0 (build 25D125, kernel 25.3.0)
		OS (rel):  25D125
		OS:        Version{major = 26, minor = 3, patch = 0}
		Kernel:    Version{major = 25, minor = 3, patch = 0}
		CPU:       Apple M4 Pro
		           CPU_Features{asimd, floatingpoint, asimdhp, bf16, fcma, fhm, fp16, frint, i8mm, jscvt, rdm, flagm, flagm2, crc32, lse, lrcpc, lrcpc2, aes, pmull, sha1, sha256, sha512, sha3, sb}
		CPU cores: 12c/12t
		RAM:       0.0 B/24.0 GiB
		SWAP:      0.0 B/0.0 B

	Example FreeBSD output:

		Odin:      dev-2026-02
		OS (full): FreeBSD 15.0-RELEASE-p2 releng/15.0-n281005-5fb0f8e9e61d GENERIC, revision 199506
		OS (rel):
		OS:        Version{major = 15, minor = 0, patch = 199506}
		Kernel:    Version{major = 15, minor = 0, patch = 199506}
		CPU:       AMD Ryzen 9 5950X 16-Core Processor
		           CPU_Features{aes, fma, os_xsave, pclmulqdq, popcnt, rdrand, sse2, sse3, ssse3, sse41, sse42}
		RAM:       7.6 GiB/7.9 GiB
		SWAP:      0.0 B/0.0 B
	*/
*/
package sysinfo

/*
Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
Made available under Odin's license.

List of contributors:
	Jeroen van Rijn: Initial implementation.
	Laytan: ARM and RISC-V CPU feature detection, iOS/macOS platform overhaul.
*/