#+build amd64
package jpeg

import "base:intrinsics"
import "core:simd"
import "core:sys/info"

@(private)
save_avx2_performant :: #force_inline proc "contextless" () -> bool {
	req :: info.CPU_Features{.avx, .avx2}
	return info.cpu_features() >= req
}

@(private, enable_target_feature = "sse2,ssse3,sse4.1,avx,avx2")
save_transform_avx2 :: proc(e: ^Encoder, img: ^Image) {
	save_transform_blocks(e, img, true)
}

@(private)
transpose_8 :: #force_inline proc "contextless" (r: ^[BLOCK_SIZE]F8) {
	t0 := simd.shuffle(r[0], r[1], 0,  8, 1,  9, 4, 12, 5, 13)
	t1 := simd.shuffle(r[0], r[1], 2, 10, 3, 11, 6, 14, 7, 15)
	t2 := simd.shuffle(r[2], r[3], 0,  8, 1,  9, 4, 12, 5, 13)
	t3 := simd.shuffle(r[2], r[3], 2, 10, 3, 11, 6, 14, 7, 15)
	t4 := simd.shuffle(r[4], r[5], 0,  8, 1,  9, 4, 12, 5, 13)
	t5 := simd.shuffle(r[4], r[5], 2, 10, 3, 11, 6, 14, 7, 15)
	t6 := simd.shuffle(r[6], r[7], 0,  8, 1,  9, 4, 12, 5, 13)
	t7 := simd.shuffle(r[6], r[7], 2, 10, 3, 11, 6, 14, 7, 15)

	u0 := simd.shuffle(t0, t2, 0, 1,  8,  9, 4, 5, 12, 13)
	u1 := simd.shuffle(t0, t2, 2, 3, 10, 11, 6, 7, 14, 15)
	u2 := simd.shuffle(t1, t3, 0, 1,  8,  9, 4, 5, 12, 13)
	u3 := simd.shuffle(t1, t3, 2, 3, 10, 11, 6, 7, 14, 15)
	u4 := simd.shuffle(t4, t6, 0, 1,  8,  9, 4, 5, 12, 13)
	u5 := simd.shuffle(t4, t6, 2, 3, 10, 11, 6, 7, 14, 15)
	u6 := simd.shuffle(t5, t7, 0, 1,  8,  9, 4, 5, 12, 13)
	u7 := simd.shuffle(t5, t7, 2, 3, 10, 11, 6, 7, 14, 15)

	r[0] = simd.shuffle(u0, u4, 0, 1, 2, 3,  8,  9, 10, 11)
	r[1] = simd.shuffle(u1, u5, 0, 1, 2, 3,  8,  9, 10, 11)
	r[2] = simd.shuffle(u2, u6, 0, 1, 2, 3,  8,  9, 10, 11)
	r[3] = simd.shuffle(u3, u7, 0, 1, 2, 3,  8,  9, 10, 11)
	r[4] = simd.shuffle(u0, u4, 4, 5, 6, 7, 12, 13, 14, 15)
	r[5] = simd.shuffle(u1, u5, 4, 5, 6, 7, 12, 13, 14, 15)
	r[6] = simd.shuffle(u2, u6, 4, 5, 6, 7, 12, 13, 14, 15)
	r[7] = simd.shuffle(u3, u7, 4, 5, 6, 7, 12, 13, 14, 15)
}

@(private)
save_fdct_quantize_avx2 :: #force_inline proc "contextless" (src: []f32, stride: int, block: ^[COEFFICIENT_COUNT]i16, divisors: ^[COEFFICIENT_COUNT]f32, limit: i32) {
	r: [BLOCK_SIZE]F8
	natural: [COEFFICIENT_COUNT]i16
	p := raw_data(src)
	d := raw_data(divisors)
	#no_bounds_check {
		for y in 0..<BLOCK_SIZE {
			r[y] = intrinsics.unaligned_load((^F8)(&p[y * stride]))
		}
		transpose_8(&r)
		fdct_8(&r)
		transpose_8(&r)
		fdct_8(&r)

		for y in 0..<BLOCK_SIZE {
			q := r[y] * intrinsics.unaligned_load((^F8)(&d[y * BLOCK_SIZE]))
			half := transmute(F8)((transmute(#simd[8]u32)q & 0x80000000) | 0x3F000000)
			i := simd.clamp(cast(#simd[8]i32)(q + half), (#simd[8]i32)(-limit), (#simd[8]i32)(limit))
			intrinsics.unaligned_store((^#simd[8]i16)(&natural[y * BLOCK_SIZE]), cast(#simd[8]i16)i)
		}
		v := intrinsics.unaligned_load((^#simd[COEFFICIENT_COUNT]i16)(&natural))
		intrinsics.unaligned_store((^#simd[COEFFICIENT_COUNT]i16)(block), simd.shuffle(v, v,
			 0,  1,  8, 16,  9,  2,  3, 10, 17, 24, 32, 25, 18, 11,  4,  5,
			12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13,  6,  7, 14, 21, 28,
			35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51,
			58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63,
		))
	}
}
