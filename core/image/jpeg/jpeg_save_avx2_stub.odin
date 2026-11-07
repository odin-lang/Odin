#+build !amd64
package jpeg

@(private)
save_avx2_performant :: #force_inline proc "contextless" () -> bool {
	return false
}

@(private)
save_transform_avx2 :: proc(e: ^Encoder, img: ^Image) {
	panic_contextless("jpeg: AVX2 save path called on a target without AVX2 support")
}

@(private)
save_fdct_quantize_avx2 :: #force_inline proc "contextless" (src: []f32, stride: int, block: ^[COEFFICIENT_COUNT]i16, divisors: ^[COEFFICIENT_COUNT]f32, limit: i32) {
	panic_contextless("jpeg: AVX2 save path called on a target without AVX2 support")
}