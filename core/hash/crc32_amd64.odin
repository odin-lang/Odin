#+build amd64
package hash

import "base:intrinsics"
import "core:simd/x86"

@(private)
CRC32_HW_STATIC :: intrinsics.has_target_feature("pclmul") && intrinsics.has_target_feature("sse4.1")

@(private)
CRC32_HW_WIDE_STATIC :: CRC32_HW_STATIC && intrinsics.has_target_feature("avx2") && intrinsics.has_target_feature("vpclmulqdq")

@(private)
CRC32_HW_MIN :: 16

@(private)
CRC32_HW_WIDE_MIN :: 256

@(private)
crc32_hw_detected := CRC32_HW_STATIC

@(private)
crc32_hw_wide_detected := CRC32_HW_WIDE_STATIC

@(init, private)
crc32_detect :: proc "contextless" () {
	max_id, _, _, _ := intrinsics.x86_cpuid(0, 0)
	_, _, ecx1, _ := intrinsics.x86_cpuid(1, 0)
	crc32_hw_detected = ecx1 & (1 << 1) != 0 && ecx1 & (1 << 19) != 0

	when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD {
		return
	}
	if max_id < 7 || ecx1 & (1 << 26) == 0 || ecx1 & (1 << 27) == 0 || ecx1 & (1 << 28) == 0 {
		return
	}
	xcr0, _ := intrinsics.x86_xgetbv(0)
	if xcr0 & 0b110 != 0b110 {
		return
	}
	_, ebx7, ecx7, _ := intrinsics.x86_cpuid(7, 0)
	crc32_hw_wide_detected = crc32_hw_detected && ebx7 & (1 << 5) != 0 && ecx7 & (1 << 10) != 0
}

@(private)
crc32_hw_available :: #force_inline proc "contextless" () -> bool {
	when CRC32_HW_STATIC {
		return true
	} else {
		return crc32_hw_detected
	}
}

@(private)
crc32_hw_wide_available :: #force_inline proc "contextless" () -> bool {
	when CRC32_HW_WIDE_STATIC {
		return true
	} else {
		return crc32_hw_wide_detected
	}
}

@(private)
crc32_hw :: proc "contextless" (crc: u32, data: [^]byte, length: int) -> (new_crc: u32, consumed: int) #no_bounds_check {
	if length >= CRC32_HW_WIDE_MIN && crc32_hw_wide_available() {
		return crc32_hw_256(crc, data, length)
	}
	return crc32_hw_128(crc, data, length)
}

@(private)
CRC32_K12 :: x86.__m128i{0x154442bd4, 0x1c6e41596}

@(private)
CRC32_K34 :: x86.__m128i{0x1751997d0, 0x0ccaa009e}

@(private, enable_target_feature="sse2,pclmul")
crc32_fold_128 :: #force_inline proc "contextless" (x, k: x86.__m128i) -> x86.__m128i {
	return x86._mm_xor_si128(x86._mm_clmulepi64_si128(x, k, 0x00), x86._mm_clmulepi64_si128(x, k, 0x11))
}

@(private, enable_target_feature="sse2")
crc32_load_128 :: #force_inline proc "contextless" (p: [^]byte) -> x86.__m128i {
	return x86._mm_loadu_si128((^x86.__m128i)(p))
}

@(private, enable_target_feature="sse2,sse4.1,pclmul")
crc32_reduce_128 :: #force_inline proc "contextless" (x0: x86.__m128i, data: [^]byte, length, position: int) -> (new_crc: u32, consumed: int) #no_bounds_check {
	K5     :: x86.__m128i{0x163cd6124, 0}
	KP     :: x86.__m128i{0x1db710641, 0x1f7011641}
	MASK32 :: x86.__m128i{0xffffffff, 0}

	x0 := x0
	p  := position
	for length - p >= 16 {
		x0 = x86._mm_xor_si128(crc32_fold_128(x0, CRC32_K34), crc32_load_128(data[p:]))
		p += 16
	}

	v := x86._mm_xor_si128(x86._mm_clmulepi64_si128(x0, CRC32_K34, 0x10), x86._mm_srli_si128(x0, 8))
	v  = x86._mm_xor_si128(x86._mm_clmulepi64_si128(x86._mm_and_si128(v, MASK32), K5, 0x00), x86._mm_srli_si128(v, 4))
	t := x86._mm_clmulepi64_si128(x86._mm_and_si128(v, MASK32), KP, 0x10)
	t  = x86._mm_clmulepi64_si128(x86._mm_and_si128(t, MASK32), KP, 0x00)
	v  = x86._mm_xor_si128(v, t)
	return u32(x86._mm_extract_epi32(v, 1)), p
}

@(private, enable_target_feature="sse2,sse4.1,pclmul")
crc32_hw_128 :: proc "contextless" (crc: u32, data: [^]byte, length: int) -> (new_crc: u32, consumed: int) #no_bounds_check {
	x0 := x86._mm_xor_si128(crc32_load_128(data[0:]), x86._mm_cvtsi32_si128(i32(crc)))
	if length < 64 {
		return crc32_reduce_128(x0, data, length, 16)
	}
	x1 := crc32_load_128(data[16:])
	x2 := crc32_load_128(data[32:])
	x3 := crc32_load_128(data[48:])
	p  := 64

	for length - p >= 64 {
		x0 = x86._mm_xor_si128(crc32_fold_128(x0, CRC32_K12), crc32_load_128(data[p:]))
		x1 = x86._mm_xor_si128(crc32_fold_128(x1, CRC32_K12), crc32_load_128(data[p + 16:]))
		x2 = x86._mm_xor_si128(crc32_fold_128(x2, CRC32_K12), crc32_load_128(data[p + 32:]))
		x3 = x86._mm_xor_si128(crc32_fold_128(x3, CRC32_K12), crc32_load_128(data[p + 48:]))
		p += 64
	}

	x0 = x86._mm_xor_si128(crc32_fold_128(x0, CRC32_K34), x1)
	x0 = x86._mm_xor_si128(crc32_fold_128(x0, CRC32_K34), x2)
	x0 = x86._mm_xor_si128(crc32_fold_128(x0, CRC32_K34), x3)
	return crc32_reduce_128(x0, data, length, p)
}

@(private, enable_target_feature="sse2,sse4.1,pclmul,avx,avx2,vpclmulqdq")
crc32_hw_256 :: proc "contextless" (crc: u32, data: [^]byte, length: int) -> (new_crc: u32, consumed: int) #no_bounds_check {
	K1024 :: x86.__m256i{0x1e88ef372, 0x14a7fe880, 0x1e88ef372, 0x14a7fe880}
	K256  :: x86.__m256i{0x0f1da05aa, 0x15a546366, 0x0f1da05aa, 0x15a546366}

	@(enable_target_feature="avx,avx2,vpclmulqdq")
	fold :: #force_inline proc "contextless" (x, k: x86.__m256i) -> x86.__m256i {
		return x86._mm256_xor_si256(x86._mm256_clmulepi64_epi128(x, k, 0x00), x86._mm256_clmulepi64_epi128(x, k, 0x11))
	}
	@(enable_target_feature="avx")
	load :: #force_inline proc "contextless" (p: [^]byte) -> x86.__m256i {
		return x86._mm256_loadu_si256((^x86.__m256i)(p))
	}

	y0 := x86._mm256_xor_si256(load(data[0:]), x86.__m256i{i64(crc), 0, 0, 0})
	y1 := load(data[32:])
	y2 := load(data[64:])
	y3 := load(data[96:])
	p  := 128

	for length - p >= 128 {
		y0 = x86._mm256_xor_si256(fold(y0, K1024), load(data[p:]))
		y1 = x86._mm256_xor_si256(fold(y1, K1024), load(data[p + 32:]))
		y2 = x86._mm256_xor_si256(fold(y2, K1024), load(data[p + 64:]))
		y3 = x86._mm256_xor_si256(fold(y3, K1024), load(data[p + 96:]))
		p += 128
	}

	y0 = x86._mm256_xor_si256(fold(y0, K256), y1)
	y0 = x86._mm256_xor_si256(fold(y0, K256), y2)
	y0 = x86._mm256_xor_si256(fold(y0, K256), y3)
	for length - p >= 32 {
		y0 = x86._mm256_xor_si256(fold(y0, K256), load(data[p:]))
		p += 32
	}

	x0 := x86._mm_xor_si128(crc32_fold_128(x86._mm256_castsi256_si128(y0), CRC32_K34), x86._mm256_extracti128_si256(y0, 1))
	return crc32_reduce_128(x0, data, length, p)
}
