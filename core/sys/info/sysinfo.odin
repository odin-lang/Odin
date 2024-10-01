package sysinfo

when !(ODIN_ARCH == .amd64 || ODIN_ARCH == .i386 || ODIN_ARCH == .arm32 || ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64) {
	#assert(false, "This package is unsupported on this architecture.")
}

os_version: OS_Version
ram:        RAM
gpus:       []GPU

// Only on MacOS, contains the actual MacOS version, while the `os_version` contains the kernel version.
macos_version: Version

OS_Version_Platform :: enum {
	Unknown,
	Windows,
	Linux,
	MacOS,
	iOS,
	FreeBSD,
	OpenBSD,
	NetBSD,
}

Version :: struct {
	major, minor, patch: int,
}

OS_Version :: struct {
	platform: OS_Version_Platform,

	using _:   Version,
	build:     [2]int,
	version:   string,

	as_string: string,
}

RAM :: struct {
	total_ram:  int,
	free_ram:   int,
	total_swap: int,
	free_swap:  int,
}

GPU :: struct {
	vendor_name: string,
	model_name:  string,
	total_ram:   int,
}
