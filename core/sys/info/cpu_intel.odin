#+build i386, amd64
package sysinfo

import "base:intrinsics"

// cpuid :: proc(ax, cx: u32) -> (eax, ebc, ecx, edx: u32) ---
cpuid :: intrinsics.x86_cpuid

// xgetbv :: proc(cx: u32) -> (eax, edx: u32) ---
xgetbv :: intrinsics.x86_xgetbv

CPU_Feature :: enum u64 {
	aes,       // AES hardware implementation (AES NI)
	adx,       // Multi-precision add-carry instruction extensions
	avx,       // Advanced vector extension
	avx2,      // Advanced vector extension 2
	bmi1,      // Bit manipulation instruction set 1
	bmi2,      // Bit manipulation instruction set 2
	erms,      // Enhanced REP for MOVSB and STOSB
	fma,       // Fused-multiply-add instructions
	os_xsave,  // OS supports XSAVE/XRESTOR for saving/restoring XMM registers.
	pclmulqdq, // PCLMULQDQ instruction - most often used for AES-GCM
	popcnt,    // Hamming weight instruction POPCNT.
	rdrand,    // RDRAND instruction (on-chip random number generator)
	rdseed,    // RDSEED instruction (on-chip random number generator)
	sha,       // SHA Extensions (SHA-1, SHA-224, SHA-256)
	sse2,      // Streaming SIMD extension 2 (always available on amd64)
	sse3,      // Streaming SIMD extension 3
	ssse3,     // Supplemental streaming SIMD extension 3
	sse41,     // Streaming SIMD extension 4 and 4.1
	sse42,     // Streaming SIMD extension 4 and 4.2

	avx512bf16,         // Vector Neural Network Instructions supporting bfloat16
	avx512bitalg,       // Bit Algorithms
	avx512bw,           // Byte and Word instructions
	avx512cd,           // Conflict Detection instructions
	avx512dq,           // Doubleword and Quadword instructions
	avx512er,           // Exponential and Reciprocal instructions
	avx512f,            // Foundation
	avx512fp16,         // Vector 16-bit float instructions
	avx512ifma,         // Integer Fused Multiply Add
	avx512pf,           // Prefetch instructions
	avx512vbmi,         // Vector Byte Manipulation Instructions
	avx512vbmi2,        // Vector Byte Manipulation Instructions 2
	avx512vl,           // Vector Length extensions
	avx512vnni,         // Vector Neural Network Instructions
	avx512vp2intersect, // Vector Pair Intersection to a Pair of Mask Registers
	avx512vpopcntdq,    // Vector Population Count for Doubleword and Quadword
}

CPU_Features :: distinct bit_set[CPU_Feature; u64]

cpu_features: Maybe(CPU_Features)
cpu_name:     Maybe(string)

@(init, private)
init_cpu_features :: proc "c" () {
	is_set :: #force_inline proc "c" (bit: u32, value: u32) -> bool {
		return (value>>bit) & 0x1 != 0
	}
	try_set :: #force_inline proc "c" (set: ^CPU_Features, feature: CPU_Feature, bit: u32, value: u32) {
		if is_set(bit, value) {
			set^ += {feature}
		}
	}

	max_id, _, _, _ := cpuid(0, 0)
	if max_id < 1 {
		return
	}

	set: CPU_Features

	_, _, ecx1, edx1 := cpuid(1, 0)

	try_set(&set, .sse2,      26, edx1)
	try_set(&set, .sse3,       0, ecx1)
	try_set(&set, .pclmulqdq,  1, ecx1)
	try_set(&set, .ssse3,      9, ecx1)
	try_set(&set, .fma,       12, ecx1)
	try_set(&set, .sse41,     19, ecx1)
	try_set(&set, .sse42,     20, ecx1)
	try_set(&set, .popcnt,    23, ecx1)
	try_set(&set, .aes,       25, ecx1)
	try_set(&set, .os_xsave,  27, ecx1)
	try_set(&set, .rdrand,    30, ecx1)

	when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
		// xgetbv is an illegal instruction under FreeBSD 13, OpenBSD 7.1 and NetBSD 10
		// return before probing further
		cpu_features = set
		return
	}

	// In certain rare cases (reason unknown), XGETBV generates an
	// illegal instruction, even if OSXSAVE is set per CPUID.
	//
	// When Chrome ran into this problem, the problem went away
	// after they started checking both OSXSAVE and XSAVE.
	//
	// See: crbug.com/375968
	os_supports_avx := false
	os_supports_avx512 := false
	if .os_xsave in set && is_set(26, ecx1) {
		eax, _ := xgetbv(0)
		os_supports_avx = is_set(1, eax) && is_set(2, eax)
		os_supports_avx512 = is_set(5, eax) && is_set(6, eax) && is_set(7, eax)
	}
	if os_supports_avx {
		try_set(&set, .avx, 28, ecx1)
	}

	if max_id < 7 {
		return
	}

	_, ebx7, ecx7, edx7 := cpuid(7, 0)
	try_set(&set, .bmi1, 3, ebx7)
	try_set(&set, .sha, 29, ebx7)
	if os_supports_avx {
		try_set(&set, .avx2, 5, ebx7)
	}
	if os_supports_avx512 {
		try_set(&set, .avx512f,    16, ebx7)
		try_set(&set, .avx512dq,   17, ebx7)
		try_set(&set, .avx512ifma, 21, ebx7)
		try_set(&set, .avx512pf,   26, ebx7)
		try_set(&set, .avx512er,   27, ebx7)
		try_set(&set, .avx512cd,   28, ebx7)
		try_set(&set, .avx512bw,   30, ebx7)

		// XMM/YMM are also required for 128/256-bit instructions
		if os_supports_avx {
			try_set(&set, .avx512vl, 31, ebx7)
		}

		try_set(&set, .avx512vbmi,       1, ecx7)
		try_set(&set, .avx512vbmi2,      6, ecx7)
		try_set(&set, .avx512vnni,      11, ecx7)
		try_set(&set, .avx512bitalg,    12, ecx7)
		try_set(&set, .avx512vpopcntdq, 14, ecx7)

		try_set(&set, .avx512vp2intersect,  8, edx7)
		try_set(&set, .avx512fp16,         23, edx7)

		eax7_1, _, _, _ := cpuid(7, 1)
		try_set(&set, .avx512bf16, 5, eax7_1)
	}
	try_set(&set, .bmi2,    8, ebx7)
	try_set(&set, .erms,    9, ebx7)
	try_set(&set, .rdseed, 18, ebx7)
	try_set(&set, .adx,    19, ebx7)

	cpu_features = set
}

@(private)
_cpu_name_buf: [72]u8

@(init, private)
init_cpu_name :: proc "c" () {
	number_of_extended_ids, _, _, _ := cpuid(0x8000_0000, 0)
	if number_of_extended_ids < 0x8000_0004 {
		return
	}

	_buf := (^[0x12]u32)(&_cpu_name_buf)
	_buf[ 0], _buf[ 1], _buf[ 2], _buf[ 3] = cpuid(0x8000_0002, 0)
	_buf[ 4], _buf[ 5], _buf[ 6], _buf[ 7] = cpuid(0x8000_0003, 0)
	_buf[ 8], _buf[ 9], _buf[10], _buf[11] = cpuid(0x8000_0004, 0)

	// Some CPUs like may include leading or trailing spaces. Trim them.
	// e.g. `      Intel(R) Xeon(R) CPU E5-1650 v2 @ 3.50GHz`

	brand := string(_cpu_name_buf[:])
	for len(brand) > 0 && brand[0] == 0 || brand[0] == ' ' {
		brand = brand[1:]
	}
	for len(brand) > 0 && brand[len(brand) - 1] == 0 || brand[len(brand) - 1] == ' ' {
		brand = brand[:len(brand) - 1]
	}
	cpu_name = brand
}
