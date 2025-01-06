#+build i386, amd64
package simd_x86

@(require_results, enable_target_feature="sha")
_mm_sha1msg1_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)sha1msg1(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sha")
_mm_sha1msg2_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)sha1msg2(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sha")
_mm_sha1nexte_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)sha1nexte(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sha")
_mm_sha1rnds4_epu32 :: #force_inline proc "c" (a, b: __m128i, $FUNC: u32) -> __m128i where 0 <= FUNC, FUNC <= 3 {
	return transmute(__m128i)sha1rnds4(transmute(i32x4)a, transmute(i32x4)b, u8(FUNC & 0xff))
}
@(require_results, enable_target_feature="sha")
_mm_sha256msg1_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)sha256msg1(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sha")
_mm_sha256msg2_epu32 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return transmute(__m128i)sha256msg2(transmute(i32x4)a, transmute(i32x4)b)
}
@(require_results, enable_target_feature="sha")
_mm_sha256rnds2_epu32 :: #force_inline proc "c" (a, b, k: __m128i) -> __m128i {
	return transmute(__m128i)sha256rnds2(transmute(i32x4)a, transmute(i32x4)b, transmute(i32x4)k)
}

@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sha1msg1")
	sha1msg1    :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name="llvm.x86.sha1msg2")
	sha1msg2    :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name="llvm.x86.sha1nexte")
	sha1nexte   :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name="llvm.x86.sha1rnds4")
	sha1rnds4   :: proc(a, b: i32x4, #const c: u8) -> i32x4 ---
	@(link_name="llvm.x86.sha256msg1")
	sha256msg1  :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name="llvm.x86.sha256msg2")
	sha256msg2  :: proc(a, b: i32x4) -> i32x4 ---
	@(link_name="llvm.x86.sha256rnds2")
	sha256rnds2 :: proc(a, b, k: i32x4) -> i32x4 ---
}