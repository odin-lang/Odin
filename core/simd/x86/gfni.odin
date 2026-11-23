#+build i386, amd64
package simd_x86

import "core:simd"

// Multiply the packed 8-bit integers in `a` and `b` in the finite field `GF(2^8)`, and store the results in `dst`.
// The field `GF(2^8)` is represented in polynomial representation with the reduction polynomial `x^8 + x^4 + x^3 + x + 1`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_gf2p8mul_epi8)
@(require_results, enable_target_feature="gfni,avx512f")
_mm512_gf2p8mul_epi8 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return transmute(__m512i)llvm_vgf2p8mulb_512(transmute(simd.i8x64)a, transmute(simd.i8x64)b)
}

// Multiply the packed 8-bit integers in `a` and `b` in the finite field `GF(2^8)`, and store the results in `dst`.
// The field `GF(2^8)` is represented in polynomial representation with the reduction polynomial `x^8 + x^4 + x^3 + x + 1`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_gf2p8mul_epi8)
@(require_results, enable_target_feature="gfni,avx")
_mm256_gf2p8mul_epi8 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_vgf2p8mulb_256(transmute(simd.i8x32)a, transmute(simd.i8x32)b)
}

// Multiply the packed 8-bit integers in `a` and `b` in the finite field `GF(2^8)`, and store the results in `dst`.
// The field `GF(2^8)` is represented in polynomial representation with the reduction polynomial `x^8 + x^4 + x^3 + x + 1`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_gf2p8mul_epi8)
@(require_results, enable_target_feature="gfni")
_mm_gf2p8mul_epi8 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vgf2p8mulb_128(transmute(simd.i8x16)a, transmute(simd.i8x16)b)
}

// Compute an affine transformation in the Galois Field 2^8. An affine transformation is defined by `A * x + b`,
// where `A` represents an 8 by 8 bit matrix, `x` represents an 8-bit vector, and `b` is a constant immediate byte.
// Store the packed 8-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_gf2p8affine_epi64_epi8)
@(require_results, enable_target_feature="gfni,avx512f")
_mm512_gf2p8affine_epi64_epi8 :: #force_inline proc "c" (x, a: __m512i, $B: i32) -> __m512i where 0 <= B, B < 256 {
	return transmute(__m512i)llvm_vgf2p8affineqb_512(
		transmute(simd.i8x64)x,
		transmute(simd.i8x64)a,
		cast(u8)B,
	)
}

// Compute an affine transformation in the Galois Field 2^8. An affine transformation is defined by `A * x + b`,
// where `A` represents an 8 by 8 bit matrix, `x` represents an 8-bit vector, and `b` is a constant immediate byte.
// Store the packed 8-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_gf2p8affine_epi64_epi8)
@(require_results, enable_target_feature="gfni,avx")
_mm256_gf2p8affine_epi64_epi8 :: #force_inline proc "c" (x, a: __m256i, $B: i32) -> __m256i where 0 <= B, B < 256 {
	return transmute(__m256i)llvm_vgf2p8affineqb_256(
		transmute(simd.i8x32)x,
		transmute(simd.i8x32)a,
		cast(u8)B,
	)
}

// Compute an affine transformation in the Galois Field 2^8. An affine transformation is defined by `A * x + b`,
// where `A` represents an 8 by 8 bit matrix, `x` represents an 8-bit vector, and `b` is a constant immediate byte.
// Store the packed 8-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_gf2p8affine_epi64_epi8)
@(require_results, enable_target_feature="gfni")
_mm_gf2p8affine_epi64_epi8 :: #force_inline proc "c" (x, a: __m128i, $B: i32) -> __m128i where 0 <= B, B < 256 {
	return transmute(__m128i)llvm_vgf2p8affineqb_128(
		transmute(simd.i8x16)x,
		transmute(simd.i8x16)a,
		cast(u8)B,
	)
}

// Compute an inverse affine transformation in the Galois Field 2^8. An affine transformation is defined by `A * x + b`,
// where `A` represents an 8 by 8 bit matrix, `x` represents an 8-bit vector, and `b` is a constant immediate byte.
// The inverse of the 8-bit values in `x` is defined with respect to the reduction polynomial `x^8 + x^4 + x^3 + x + 1`.
// Store the packed 8-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_gf2p8affineinv_epi64_epi8)
@(require_results, enable_target_feature="gfni,avx512f")
_mm512_gf2p8affineinv_epi64_epi8 :: #force_inline proc "c" (x, a: __m512i, $B: i32) -> __m512i where 0 <= B, B < 256 {
	return transmute(__m512i)llvm_vgf2p8affineinvqb_512(
		transmute(simd.i8x64)x,
		transmute(simd.i8x64)a,
		cast(u8)B,
	)
}

// Compute an inverse affine transformation in the Galois Field 2^8. An affine transformation is defined by `A * x + b`,
// where `A` represents an 8 by 8 bit matrix, `x` represents an 8-bit vector, and `b` is a constant immediate byte.
// The inverse of the 8-bit values in `x` is defined with respect to the reduction polynomial `x^8 + x^4 + x^3 + x + 1`.
// Store the packed 8-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_gf2p8affineinv_epi64_epi8)
@(require_results, enable_target_feature="gfni,avx")
_mm256_gf2p8affineinv_epi64_epi8 :: #force_inline proc "c" (x, a: __m256i, $B: i32) -> __m256i where 0 <= B, B < 256 {
	return transmute(__m256i)llvm_vgf2p8affineinvqb_256(
		transmute(simd.i8x32)x,
		transmute(simd.i8x32)a,
		cast(u8)B,
	)
}

// Compute an inverse affine transformation in the Galois Field 2^8. An affine transformation is defined by `A * x + b`,
// where `A` represents an 8 by 8 bit matrix, `x` represents an 8-bit vector, and `b` is a constant immediate byte.
// The inverse of the 8-bit values in `x` is defined with respect to the reduction polynomial `x^8 + x^4 + x^3 + x + 1`.
// Store the packed 8-bit results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_gf2p8affineinv_epi64_epi8)
@(require_results, enable_target_feature="gfni")
_mm_gf2p8affineinv_epi64_epi8 :: #force_inline proc "c" (x, a: __m128i, $B: i32) -> __m128i where 0 <= B, B < 256 {
	return transmute(__m128i)llvm_vgf2p8affineinvqb_128(
		transmute(simd.i8x16)x,
		transmute(simd.i8x16)a,
		cast(u8)B,
	)
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.vgf2p8affineinvqb.512") llvm_vgf2p8affineinvqb_512 :: proc(x, a: simd.i8x64, imm8: u8) -> simd.i8x64 ---
	@(link_name="llvm.x86.vgf2p8affineinvqb.256") llvm_vgf2p8affineinvqb_256 :: proc(x, a: simd.i8x32, imm8: u8) -> simd.i8x32 ---
	@(link_name="llvm.x86.vgf2p8affineinvqb.128") llvm_vgf2p8affineinvqb_128 :: proc(x, a: simd.i8x16, imm8: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.vgf2p8affineqb.512")    llvm_vgf2p8affineqb_512    :: proc(x, a: simd.i8x64, imm8: u8) -> simd.i8x64 ---
	@(link_name="llvm.x86.vgf2p8affineqb.256")    llvm_vgf2p8affineqb_256    :: proc(x, a: simd.i8x32, imm8: u8) -> simd.i8x32 ---
	@(link_name="llvm.x86.vgf2p8affineqb.128")    llvm_vgf2p8affineqb_128    :: proc(x, a: simd.i8x16, imm8: u8) -> simd.i8x16 ---
	@(link_name="llvm.x86.vgf2p8mulb.512")        llvm_vgf2p8mulb_512        :: proc(a, b: simd.i8x64) -> simd.i8x64 ---
	@(link_name="llvm.x86.vgf2p8mulb.256")        llvm_vgf2p8mulb_256        :: proc(a, b: simd.i8x32) -> simd.i8x32 ---
	@(link_name="llvm.x86.vgf2p8mulb.128")        llvm_vgf2p8mulb_128        :: proc(a, b: simd.i8x16) -> simd.i8x16 ---
}
