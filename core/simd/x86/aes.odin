#+build i386, amd64
package simd_x86

// Perform one round of an AES decryption flow on data (state) in `a`
// using the round key in `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_aesdec_si128)
@(require_results, enable_target_feature="aes")
_mm_aesdec_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return llvm_aesdec(a, b)
}

// Perform the last round of an AES decryption flow on data (state) in `a`
// using the round key in `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_aesdeclast_si128)
@(require_results, enable_target_feature="aes")
_mm_aesdeclast_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return llvm_aesdeclast(a, b)
}

// Perform one round of an AES encryption flow on data (state) in `a`
// using the round key in `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_aesenc_si128)
@(require_results, enable_target_feature="aes")
_mm_aesenc_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return llvm_aesenc(a, b)
}

// Perform the last round of an AES encryption flow on data (state) in `a`
// using the round key in `b`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_aesenclast_si128)
@(require_results, enable_target_feature="aes")
_mm_aesenclast_si128 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return llvm_aesenclast(a, b)
}

// Perform the InvMixColumns transformation on `a` and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_aesimc_si128)
@(require_results, enable_target_feature="aes")
_mm_aesimc_si128 :: #force_inline proc "c" (a: __m128i) -> __m128i {
	return llvm_aesimc(a)
}

// Assist in expanding the AES cipher key by computing steps towards generating a round key for encryption cipher
// using data from `a` and an 8-bit round constant specified in `imm8`, and store the result in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm_aeskeygenassist_si128)
@(require_results, enable_target_feature="aes")
_mm_aeskeygenassist_si128 :: #force_inline proc "c" (a: __m128i, $IMM8: i32) -> __m128i where 0 <= IMM8, IMM8 < 256 {
	return llvm_aeskeygenassist(a, cast(u8)IMM8)
}

// Perform one round of an AES encryption flow on data (state) in `a`
// using the round key in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_aesenc_epi128)
@(require_results, enable_target_feature="vaes")
_mm256_aesenc_epi128 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return llvm_aesenc_256(a, b)
}

// Perform the last round of an AES encryption flow on data (state) in `a`
// using the round key in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_aesenclast_epi128)
@(require_results, enable_target_feature="vaes")
_mm256_aesenclast_epi128 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return llvm_aesenclast_256(a, b)
}

// Perform one round of an AES decryption flow on data (state) in `a`
// using the round key in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_aesdec_epi128)
@(require_results, enable_target_feature="vaes")
_mm256_aesdec_epi128 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return llvm_aesdec_256(a, b)
}

// Perform the last round of an AES decryption flow on data (state) in `a`
// using the round key in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm256_aesdeclast_epi128)
@(require_results, enable_target_feature="vaes")
_mm256_aesdeclast_epi128 :: #force_inline proc "c" (a, b: __m256i) -> __m256i {
	return llvm_aesdeclast_256(a, b)
}

// Perform one round of an AES encryption flow on data (state) in `a`
// using the round key in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_aesenc_epi128)
@(require_results, enable_target_feature="vaes,avx512f")
_mm512_aesenc_epi128 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return llvm_aesenc_512(a, b)
}

// Perform the last round of an AES encryption flow on data (state) in `a`
// using the round key in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_aesenclast_epi128)
@(require_results, enable_target_feature="vaes,avx512f")
_mm512_aesenclast_epi128 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return llvm_aesenclast_512(a, b)
}

// Perform one round of an AES decryption flow on data (state) in `a`
// using the round key in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_aesdec_epi128)
@(require_results, enable_target_feature="vaes,avx512f")
_mm512_aesdec_epi128 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return llvm_aesdec_512(a, b)
}

// Perform the last round of an AES decryption flow on data (state) in `a`
// using the round key in `b`, and store the results in `dst`.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_mm512_aesdeclast_epi128)
@(require_results, enable_target_feature="vaes,avx512f")
_mm512_aesdeclast_epi128 :: #force_inline proc "c" (a, b: __m512i) -> __m512i {
	return llvm_aesdeclast_512(a, b)
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.aesni.aesdec")          llvm_aesdec          :: proc(a, b: __m128i) -> __m128i ---
	@(link_name="llvm.x86.aesni.aesdeclast")      llvm_aesdeclast      :: proc(a, b: __m128i) -> __m128i ---
	@(link_name="llvm.x86.aesni.aesenc")          llvm_aesenc          :: proc(a, b: __m128i) -> __m128i ---
	@(link_name="llvm.x86.aesni.aesenclast")      llvm_aesenclast      :: proc(a, b: __m128i) -> __m128i ---
	@(link_name="llvm.x86.aesni.aesimc")          llvm_aesimc          :: proc(a: __m128i) -> __m128i ---
	@(link_name="llvm.x86.aesni.aeskeygenassist") llvm_aeskeygenassist :: proc(a: __m128i, imm8: u8) -> __m128i ---
	@(link_name="llvm.x86.aesni.aesenc.256")      llvm_aesenc_256      :: proc(a, b: __m256i) -> __m256i ---
	@(link_name="llvm.x86.aesni.aesenclast.256")  llvm_aesenclast_256  :: proc(a, b: __m256i) -> __m256i ---
	@(link_name="llvm.x86.aesni.aesdec.256")      llvm_aesdec_256      :: proc(a, b: __m256i) -> __m256i ---
	@(link_name="llvm.x86.aesni.aesdeclast.256")  llvm_aesdeclast_256  :: proc(a, b: __m256i) -> __m256i ---
	@(link_name="llvm.x86.aesni.aesenc.512")      llvm_aesenc_512      :: proc(a, b: __m512i) -> __m512i ---
	@(link_name="llvm.x86.aesni.aesenclast.512")  llvm_aesenclast_512  :: proc(a, b: __m512i) -> __m512i ---
	@(link_name="llvm.x86.aesni.aesdec.512")      llvm_aesdec_512      :: proc(a, b: __m512i) -> __m512i ---
	@(link_name="llvm.x86.aesni.aesdeclast.512")  llvm_aesdeclast_512  :: proc(a, b: __m512i) -> __m512i ---
}
