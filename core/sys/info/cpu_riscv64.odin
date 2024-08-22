package sysinfo

CPU_Feature :: enum u64 {
	I = 'I' - 'A', // Base features, don't think this is ever not here.
	M = 'M' - 'A', // Integer multiplication and division, currently required by Odin.
	A = 'A' - 'A', // Atomics.
	F = 'F' - 'A', // Single precision floating point, currently required by Odin.
	D = 'D' - 'A', // Double precision floating point, currently required by Odin.
	C = 'C' - 'A', // Compressed instructions.
	V = 'V' - 'A', // Vector operations.
}

CPU_Features :: distinct bit_set[CPU_Feature; u64]

cpu_features: Maybe(CPU_Features)
cpu_name: Maybe(string)
