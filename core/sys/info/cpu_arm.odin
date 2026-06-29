#+build arm32, arm64
package sysinfo

import "core:sys/unix"

_ :: unix

CPU_Feature :: enum u64 {
	// Advanced SIMD & floating-point capabilities:
	asimd,         // General support for Advanced SIMD instructions/neon.
	floatingpoint, // General support for floating-point instructions.
	asimdhp,       // Advanced SIMD half-precision conversion instructions.
	bf16,          // Storage and arithmetic instructions of the Brain Floating Point (BFloat16) data type.
	fcma,          // Floating-point complex number instructions.
	fhm,           // Floating-point half-precision multiplication instructions.
	fp16,          // General half-precision floating-point data processing instructions.
	frint,         // Floating-point to integral valued floating-point number rounding instructions.
	i8mm,          // Advanced SIMD int8 matrix multiplication instructions.
	jscvt,         // JavaScript conversion instruction.
	rdm,           // Advanced SIMD rounding double multiply accumulate instructions.

	flagm,  // Condition flag manipulation instructions.
	flagm2, // Enhancements to condition flag manipulation instructions.
	crc32,  // CRC32 instructions.

	lse,    // Atomic instructions to support large systems.
	lse2,   // Changes to single-copy atomicity and alignment requirements for loads and stores for large systems.
	lrcpc,  // Load-acquire Release Consistency processor consistent (RCpc) instructions.
	lrcpc2, // Load-acquire Release Consistency processor consistent (RCpc) instructions version 2.

	aes,
	pmull,
	sha1,
	sha256,
	sha512,
	sha3,

	sb,   // Barrier instruction to control speculation.
	ssbs, // Instructions to control speculation of loads and stores.
}

CPU_Features :: distinct bit_set[CPU_Feature; u64]

// Retrieving CPU features on ARM is even more expensive than on Intel, so we're doing this lookup only once, before `main()`
@(private) _features:    CPU_Features


@(private) _name_buf: [256]u8
@(private) _name:     string

@(private)
_cpu_name :: proc() -> (name: string) {
	return _name
}

@(init, private)
_init_cpu_name :: proc "contextless" () {
	when ODIN_OS == .Darwin {
		if unix.sysctlbyname("machdep.cpu.brand_string", &_name_buf) {
			_name = string(cstring(rawptr(&_name_buf)))
			return
		}
	}

	when ODIN_ARCH == .arm64 {
		copy(_name_buf[:], "ARM64")
		_name = string(_name_buf[:len("ARM64")])
	} else {
		copy(_name_buf[:], "ARM")
		_name = string(_name_buf[:len("ARM")])
	}
}