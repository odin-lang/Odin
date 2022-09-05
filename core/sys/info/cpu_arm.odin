//+build arm32, arm64
package sysinfo

// TODO: Set up an enum with the ARM equivalent of the above.
CPU_Feature :: enum u64 {}

cpu_features: Maybe(CPU_Feature)
cpu_name:     Maybe(string)

@(init, private)
init_cpu_features :: proc "c" () {
}

@(private)
_cpu_name_buf: [72]u8

@(init, private)
init_cpu_name :: proc "c" () {
	when ODIN_ARCH == .arm32 {
		copy(_cpu_name_buf[:], "ARM")
		cpu_name = string(_cpu_name_buf[:3])
	} else {
		copy(_cpu_name_buf[:], "ARM64")
		cpu_name = string(_cpu_name_buf[:5])
	}
}