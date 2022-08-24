//+build i386, amd64
package simd_x86

import "core:intrinsics"

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
	sse2,      // Streaming SIMD extension 2 (always available on amd64)
	sse3,      // Streaming SIMD extension 3
	ssse3,     // Supplemental streaming SIMD extension 3
	sse41,     // Streaming SIMD extension 4 and 4.1
	sse42,     // Streaming SIMD extension 4 and 4.2
}

CPU_Features :: distinct bit_set[CPU_Feature; u64]

cpu_features: Maybe(CPU_Features)

@(init, private)
init_cpu_features :: proc "c" () {
	is_set :: #force_inline proc "c" (hwc: u32, value: u32) -> bool {
		return hwc&value != 0
	}
	try_set :: #force_inline proc "c" (set: ^CPU_Features, feature: CPU_Feature, hwc: u32, value: u32) {
		if is_set(hwc, value) {
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

	os_supports_avx := false
	if .os_xsave in set {
		eax, _ := xgetbv(0)
		os_supports_avx = is_set(1, eax) && is_set(2, eax)
	}
	if os_supports_avx {
		try_set(&set, .avx, 28, ecx1)
	}

	if max_id < 7 {
		return
	}

	_, ebx7, _, _ := cpuid(7, 0)
	try_set(&set, .bmi1, 3, ebx7)
	if os_supports_avx {
		try_set(&set, .avx2, 5, ebx7)
	}
	try_set(&set, .bmi2,    8, ebx7)
	try_set(&set, .erms,    9, ebx7)
	try_set(&set, .rdseed, 18, ebx7)
	try_set(&set, .adx,    19, ebx7)

	cpu_features = set
}
