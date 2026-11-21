#+build i386, amd64
package simd_x86

import "core:simd"

// Perform an intermediate calculation for the next four SHA1 message values (unsigned 32-bit integers)
// using previous message values from `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sha1msg1_epu32)
@(require_results, enable_target_feature="sha")
_mm_sha1msg1_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_sha1msg1(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Perform the final calculation for the next four SHA1 message values (unsigned 32-bit integers)
// using the intermediate result in `a` and the previous message values in `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sha1msg2_epu32)
@(require_results, enable_target_feature="sha")
_mm_sha1msg2_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_sha1msg2(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Calculate SHA1 state variable E after four rounds of operation from the current SHA1 state variable `a`,
// add that value to the scheduled values (unsigned 32-bit integers) in `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sha1nexte_epu32)
@(require_results, enable_target_feature="sha")
_mm_sha1nexte_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_sha1nexte(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Perform four rounds of SHA1 operation using an initial SHA1 state (A,B,C,D) from `a`
// and some pre-computed sum of the next 4 round message values (unsigned 32-bit integers),
// and state variable E from `b`, and store the updated SHA1 state (A,B,C,D) in `dst`.
// `func` contains the logic functions and round constants.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sha1rnds4_epu32)
@(require_results, enable_target_feature="sha")
_mm_sha1rnds4_epu32 :: #force_inline proc "c" (a, b: __m128i, $FUNC: i32) -> __m128i where 0 <= FUNC, FUNC < 4 {
	return transmute(__m128i)llvm_sha1rnds4(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		cast(i8)FUNC,
	)
}

// Perform an intermediate calculation for the next four SHA256 message values (unsigned 32-bit integers)
// using previous message values from `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sha256msg1_epu32)
@(require_results, enable_target_feature="sha")
_mm_sha256msg1_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_sha256msg1(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Perform the final calculation for the next four SHA256 message values (unsigned 32-bit integers)
// using previous message values from `a` and `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sha256msg2_epu32)
@(require_results, enable_target_feature="sha")
_mm_sha256msg2_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_sha256msg2(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// Perform 2 rounds of SHA256 operation using an initial SHA256 state (C,D,G,H) from `a`, an initial SHA256 state (A,B,E,F) from `b`,
// and a pre-computed sum of the next 2 round message values (unsigned 32-bit integers) and the corresponding round constants from `k`,
// and store the updated SHA256 state (A,B,E,F) in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sha256rnds2_epu32)
@(require_results, enable_target_feature="sha")
_mm_sha256rnds2_epu32 :: #force_inline proc "c" (a, b, k: __m128i) -> __m128i {
	return transmute(__m128i)llvm_sha256rnds2(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		transmute(simd.i32x4)k,
	)
}

// This intrinisc is one of the two SHA512 message scheduling instructions.
// The intrinsic performs an intermediate calculation for the next four SHA512 message qwords.
// The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sha512msg1_epi64)
@(require_results, enable_target_feature="sha512,avx")
_mm256_sha512msg1_epi64 :: #force_inline proc "c" (a: __m256i, b: __m128i) -> __m256i {
	return llvm_vsha512msg1(a, b)
}

// This intrinisc is one of the two SHA512 message scheduling instructions.
// The intrinsic performs the final calculation for the next four SHA512 message qwords.
// The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sha512msg2_epi64)
@(require_results, enable_target_feature="sha512,avx")
_mm256_sha512msg2_epi64 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return llvm_vsha512msg2(a, b)
}

// This intrinisc performs two rounds of SHA512 operation using initial SHA512 state (C,D,G,H) from `a`,
// an initial SHA512 state (A,B,E,F) from `b`, and a pre-computed sum of the next two round message qwords
// and the corresponding round constants from `k` (only the two lower qwords of the third operand).
// The updated SHA512 state (A,B,E,F) is written to `dst`, and `dst` can be used as the updated state (C,D,G,H) in later rounds.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sha512rnds2_epi64)
@(require_results, enable_target_feature="sha512,avx")
_mm256_sha512rnds2_epi64 :: #force_inline proc "c" (a, b: __m256i, k: __m128i) -> __m256i {
	return llvm_vsha512rnds2(a, b, k)
}

// The VSM3MSG1 intrinsic is one of the two SM3 message scheduling intrinsics.
// The intrinsic performs an initial calculation for the next four SM3 message words.
// The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sm3msg1_epi32)
@(require_results, enable_target_feature="sm3,avx")
_mm_sm3msg1_epi32 :: #force_inline proc "c" (a, b, c: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vsm3msg1(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		transmute(simd.i32x4)c,
	)
}

// The VSM3MSG2 intrinsic is one of the two SM3 message scheduling intrinsics.
// The intrinsic performs the final calculation for the next four SM3 message words.
// The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sm3msg2_epi32)
@(require_results, enable_target_feature="sm3,avx")
_mm_sm3msg2_epi32 :: #force_inline proc "c" (a, b, c: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vsm3msg2(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		transmute(simd.i32x4)c,
	)
}

// The intrinsic performs two rounds of SM3 operation using initial SM3 state (C, D, G, H) from `a`,
// an initial SM3 states (A, B, E, F) from `b` and a pre-computed words from the `c`.
// `a` with initial SM3 state of (C, D, G, H) assumes input of non-rotated left variables from previous state.
// The updated SM3 state (A, B, E, F) is written to `a`.
// The `imm8` should contain the even round number for the first of the two rounds computed by this instruction.
// The computation masks the `imm8` value by ANDing it with `0x3E` so that only even round numbers from 0 through 62
// are used for this operation. The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sm3rnds2_epi32)
@(require_results, enable_target_feature="sm3,avx")
_mm_sm3rnds2_epi32 :: #force_inline proc "c" (a, b, c: __m128i, $IMM8: i32) -> __m128i {
	#assert(IMM8 == (IMM8 & 0x3e), "simd/x86: IMM8 must be an even number in the range from 0 to 62")
	return transmute(__m128i)llvm_vsm3rnds2(
		transmute(simd.i32x4)a,
		transmute(simd.i32x4)b,
		transmute(simd.i32x4)c,
		IMM8,
	)
}

// This intrinsic performs four rounds of SM4 key expansion.
// The intrinsic operates on independent 128-bit lanes.
// The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sm4key4_epi32)
@(require_results, enable_target_feature="sm4,avx")
_mm_sm4key4_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vsm4key4128(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// This intrinsic performs four rounds of SM4 key expansion.
// The intrinsic operates on independent 128-bit lanes.
// The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sm4key4_epi32)
@(require_results, enable_target_feature="sm4,avx")
_mm256_sm4key4_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_vsm4key4256(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

// This intrinisc performs four rounds of SM4 encryption.
// The intrinisc operates on independent 128-bit lanes.
// The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_sm4rnds4_epi32)
@(require_results, enable_target_feature="sm4,avx")
_mm_sm4rnds4_epi32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)llvm_vsm4rnds4128(transmute(simd.i32x4)a, transmute(simd.i32x4)b)
}

// This intrinisc performs four rounds of SM4 encryption.
// The intrinisc operates on independent 128-bit lanes.
// The calculated results are stored in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_sm4rnds4_epi32)
@(require_results, enable_target_feature="sm4,avx")
_mm256_sm4rnds4_epi32 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return transmute(__m256i)llvm_vsm4rnds4256(transmute(simd.i32x8)a, transmute(simd.i32x8)b)
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sha1msg1")     llvm_sha1msg1     :: proc(a, b: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sha1msg2")     llvm_sha1msg2     :: proc(a, b: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sha1nexte")    llvm_sha1nexte    :: proc(a, b: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sha1rnds4")    llvm_sha1rnds4    :: proc(a, b: simd.i32x4, c: i8) -> simd.i32x4 ---
	@(link_name="llvm.x86.sha256msg1")   llvm_sha256msg1   :: proc(a, b: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sha256msg2")   llvm_sha256msg2   :: proc(a, b: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.sha256rnds2")  llvm_sha256rnds2  :: proc(a, b, k: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.vsha512msg1")  llvm_vsha512msg1  :: proc(a: simd.i64x4, b: simd.i64x2) -> simd.i64x4 ---
	@(link_name="llvm.x86.vsha512msg2")  llvm_vsha512msg2  :: proc(a, b: simd.i64x4) -> simd.i64x4 ---
	@(link_name="llvm.x86.vsha512rnds2") llvm_vsha512rnds2 :: proc(a, b: simd.i64x4, k: simd.i64x2) -> simd.i64x4 ---
	@(link_name="llvm.x86.vsm3msg1")     llvm_vsm3msg1     :: proc(a, b, c: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.vsm3msg2")     llvm_vsm3msg2     :: proc(a, b, c: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.vsm3rnds2")    llvm_vsm3rnds2    :: proc(a, b, c: simd.i32x4, d: i32) -> simd.i32x4 ---
	@(link_name="llvm.x86.vsm4key4128")  llvm_vsm4key4128  :: proc(a, b: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.vsm4key4256")  llvm_vsm4key4256  :: proc(a, b: simd.i32x8) -> simd.i32x8 ---
	@(link_name="llvm.x86.vsm4rnds4128") llvm_vsm4rnds4128 :: proc(a, b: simd.i32x4) -> simd.i32x4 ---
	@(link_name="llvm.x86.vsm4rnds4256") llvm_vsm4rnds4256 :: proc(a, b: simd.i32x8) -> simd.i32x8 ---
}
