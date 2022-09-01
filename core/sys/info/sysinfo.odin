package sysinfo

when !(ODIN_ARCH == .amd64 || ODIN_ARCH == .i386 || ODIN_ARCH == .arm32 || ODIN_ARCH == .arm64) {
	#assert(false, "This package is unsupported on this architecture.")
}

os_version: OS_Version
ram:        RAM
gpus:       []GPU

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

OS_Version :: struct {
	platform: OS_Version_Platform,

	major:     int,
	minor:     int,
	patch:     int,
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