//+build riscv64
//+build linux
package sysinfo

import "base:intrinsics"

import "core:sys/linux"

@(init, private)
init_cpu_features :: proc() {
	fd, err := linux.open("/proc/self/auxv", {})
	if err != .NONE { return }
	defer linux.close(fd)

	// This is probably enough right?
	buf: [4096]byte
	n, rerr := linux.read(fd, buf[:])
	if rerr != .NONE || n == 0 { return }

	ulong     :: u64
	AT_HWCAP  :: 16

	// TODO: using these we could get more information than just the basics.
	// AT_HWCAP2 :: 26
	// AT_HWCAP3 :: 29
	// AT_HWCAP4 :: 30

	auxv := buf[:n]
	for len(auxv) >= size_of(ulong)*2 {
		key := intrinsics.unaligned_load((^ulong)(&auxv[0]))
		val := intrinsics.unaligned_load((^ulong)(&auxv[size_of(ulong)]))
		auxv = auxv[2*size_of(ulong):]

		if key != AT_HWCAP {
			continue
		}

		cpu_features = transmute(CPU_Features)(val)
		break
	}
}

@(init, private)
init_cpu_name :: proc() {
	cpu_name = "RISCV64"
}
