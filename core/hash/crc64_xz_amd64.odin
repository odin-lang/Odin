#+build amd64
package hash

import "core:simd/x86"

@(private)
CRC64_XZ_HW_MIN :: 32

@(private)
CRC64_XZ_HW_WIDE_MIN :: 256

@(private)
CRC64_XZ_K512 :: #simd[2]u64{0x6ae3efbb9dd441f3, 0x081f6054a7842df4}

@(private)
CRC64_XZ_K128 :: #simd[2]u64{0xe05dd497ca393ae4, 0xdabe95afc7875f40}

@(private)
crc64_xz_hw_available :: #force_inline proc "contextless" () -> bool {
	return crc32_hw_available()
}

@(private)
crc64_xz_hw :: proc "contextless" (crc: u64, data: [^]byte, length: int) -> (new_crc: u64, consumed: int) #no_bounds_check {
	if length >= CRC64_XZ_HW_WIDE_MIN && crc32_hw_wide_available() {
		return crc64_xz_hw_256(crc, data, length)
	}
	return crc64_xz_hw_128(crc, data, length)
}

@(private, enable_target_feature="sse2,pclmul")
crc64_xz_fold_128 :: #force_inline proc "contextless" (x: x86.__m128i, k: #simd[2]u64) -> x86.__m128i {
	kk := transmute(x86.__m128i)k
	return x86._mm_xor_si128(x86._mm_clmulepi64_si128(x, kk, 0x00), x86._mm_clmulepi64_si128(x, kk, 0x11))
}

@(private, enable_target_feature="sse2,pclmul")
crc64_xz_reduce_128 :: #force_inline proc "contextless" (x0: x86.__m128i, data: [^]byte, length, position: int) -> (new_crc: u64, consumed: int) #no_bounds_check {
	x0 := x0
	p  := position
	for length - p >= 16 {
		x0 = x86._mm_xor_si128(crc64_xz_fold_128(x0, CRC64_XZ_K128), crc32_load_128(data[p:]))
		p += 16
	}

	folded: [16]byte = ---
	x86._mm_storeu_si128((^x86.__m128i)(&folded), x0)
	return crc64_xz_table(0, folded[:]), p
}

@(private, enable_target_feature="sse2,pclmul")
crc64_xz_hw_128 :: proc "contextless" (crc: u64, data: [^]byte, length: int) -> (new_crc: u64, consumed: int) #no_bounds_check {
	x0 := x86._mm_xor_si128(crc32_load_128(data[0:]), x86.__m128i{i64(crc), 0})
	if length < 64 {
		return crc64_xz_reduce_128(x0, data, length, 16)
	}
	x1 := crc32_load_128(data[16:])
	x2 := crc32_load_128(data[32:])
	x3 := crc32_load_128(data[48:])
	p  := 64

	for length - p >= 64 {
		x0 = x86._mm_xor_si128(crc64_xz_fold_128(x0, CRC64_XZ_K512), crc32_load_128(data[p:]))
		x1 = x86._mm_xor_si128(crc64_xz_fold_128(x1, CRC64_XZ_K512), crc32_load_128(data[p + 16:]))
		x2 = x86._mm_xor_si128(crc64_xz_fold_128(x2, CRC64_XZ_K512), crc32_load_128(data[p + 32:]))
		x3 = x86._mm_xor_si128(crc64_xz_fold_128(x3, CRC64_XZ_K512), crc32_load_128(data[p + 48:]))
		p += 64
	}

	x0 = x86._mm_xor_si128(crc64_xz_fold_128(x0, CRC64_XZ_K128), x1)
	x0 = x86._mm_xor_si128(crc64_xz_fold_128(x0, CRC64_XZ_K128), x2)
	x0 = x86._mm_xor_si128(crc64_xz_fold_128(x0, CRC64_XZ_K128), x3)
	return crc64_xz_reduce_128(x0, data, length, p)
}

@(private, enable_target_feature="sse2,pclmul,avx,avx2,vpclmulqdq")
crc64_xz_hw_256 :: proc "contextless" (crc: u64, data: [^]byte, length: int) -> (new_crc: u64, consumed: int) #no_bounds_check {
	K1024 :: #simd[4]u64{0x8757d71d4fcc1000, 0xd7d86b2af73de740, 0x8757d71d4fcc1000, 0xd7d86b2af73de740}
	K256  :: #simd[4]u64{0x60095b008a9efa44, 0x3be653a30fe1af51, 0x60095b008a9efa44, 0x3be653a30fe1af51}

	@(enable_target_feature="avx,avx2,vpclmulqdq")
	fold :: #force_inline proc "contextless" (x: x86.__m256i, k: #simd[4]u64) -> x86.__m256i {
		kk := transmute(x86.__m256i)k
		return x86._mm256_xor_si256(x86._mm256_clmulepi64_epi128(x, kk, 0x00), x86._mm256_clmulepi64_epi128(x, kk, 0x11))
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

	x0 := x86._mm_xor_si128(crc64_xz_fold_128(x86._mm256_castsi256_si128(y0), CRC64_XZ_K128), x86._mm256_extracti128_si256(y0, 1))
	return crc64_xz_reduce_128(x0, data, length, p)
}
