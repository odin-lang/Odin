#+build i386, amd64
package simd_x86

import "core:simd"

// Extracts the bit range specified by `b` from the lower 64 bits of `a`.
//
// The `[13:8]` bits of `b` specify the index of the bit-range to extract. The
// `[5:0]` bits of `b` specify the length of the bit-range to extract. All
// other bits are ignored.
//
// If the length is zero, it is interpreted as `64`. If the length and index
// are zero, the lower 64 bits of `a` are extracted.
//
// If `length == 0 && index > 0` or `length + index > 64` the result is
// undefined.
//
// The extracted bits are saved in the least-significant bit positions of the lower
// quadword of the destination; the remaining bits in the lower quadword of the
// destination register are cleared to 0. The upper quadword of the destination
// register is undefined.
@(require_results, enable_target_feature="sse4a")
_mm_extract_si64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return llvm_extrq(a, transmute(simd.i8x16)b)
}

// Extracts the specified bits from the lower 64 bits of the 128-bit integer vector operand at the
// index `idx` and of the length `len`.
//
// `idx` specifies the index of the LSB. `len` specifies the number of bits to extract. If length
// and index are both zero, bits `[63:0]` of parameter `a` are extracted. It is a compile-time error
// for `len + idx` to be greater than 64 or for `len` to be zero and `idx` to be non-zero.
//
// The extracted bits are saved in the least-significant bit positions of the lower
// quadword of the destination; the remaining bits in the lower quadword of the
// destination register are cleared to 0. The upper quadword of the destination
// register is undefined.
@(require_results, enable_target_feature="sse4a")
_mm_extracti_si64 :: #force_inline proc "c" (a: __m128i, $LEN, $IDX: i32) -> __m128i where 0 <= LEN, LEN < 64, 0 <= IDX, IDX < 64 {
	#assert((LEN == 0 && IDX == 0) || (LEN != 0 && LEN + IDX <= 64), "simd/x86: LLVM mentions that it is UB")
	return llvm_extrqi(a, cast(u8)LEN, cast(u8)IDX)
}

// Inserts the `[length:0]` bits of `b` into `a` at `index`.
//
// The bits of `b`:
//
// - `[69:64]` specify the `length`,
// - `[77:72]` specify the index.
//
// If the `length` is zero it is interpreted as `64`. If `index + length > 64`
// or `index > 0 && length == 0` the result is undefined.
//
// The upper 64 bits of the destination are undefined.
@(require_results, enable_target_feature="sse4a")
_mm_insert_si64 :: #force_inline proc "c" (a, b: __m128i) -> __m128i {
	return llvm_insertq(a, b)
}

// Inserts the `len` least-significant bits from the lower 64 bits of the 128-bit integer vector operand `b` into
// the lower 64 bits of the 128-bit integer vector operand `a` at the index `idx` and of the length `len`.
//
// `idx` specifies the index of the LSB. `len` specifies the number of bits to insert. If length and index
// are both zero, bits `[63:0]` of parameter `a` are replaced with bits `[63:0]` of parameter `b`. It is a
// compile-time error for `len + idx` to be greater than 64 or for `len` to be zero and `idx` to be non-zero.
//
// The upper 64 bits of the destination are undefined.
@(require_results, enable_target_feature="sse4a")
_mm_inserti_si64 :: #force_inline proc "c" (a, b: __m128i, $LEN, $IDX: i32) -> __m128i where 0 <= LEN, LEN < 64, 0 <= IDX, IDX < 64 {
	#assert((LEN == 0 && IDX == 0) || (LEN != 0 && LEN + IDX <= 64), "simd/x86: LLVM mentions that it is UB")
	return llvm_insertqi(a, b, cast(u8)LEN, cast(u8)IDX)
}

when ODIN_ARCH == .amd64 {
	// Non-temporal store of the lower (64-bit) floating-point element from `a` into `mem_addr`.
	// Writes data to a memory location without polluting the caches.
	// @(enable_target_feature="sse4a")
	// _mm_stream_sd :: asm (mem_addr: ^f64, a: __m128d) {
	// 	movntsd [mem_addr], a
	// }

	// Non-temporal store of the lower (32-bit) floating-point element from `a` into `mem_addr`.
	// Writes data to a memory location without polluting the caches.
	// @(enable_target_feature="sse4a")
	// _mm_stream_ss :: asm (mem_addr: ^f32, a: __m128) {
	// 	movntss [mem_addr], a
	// }
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.sse4a.extrq")    llvm_extrq    :: proc(a: simd.i64x2, b: simd.i8x16) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse4a.extrqi")   llvm_extrqi   :: proc(a: simd.i64x2, len: u8, idx: u8) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse4a.insertq")  llvm_insertq  :: proc(a, b: simd.i64x2) -> simd.i64x2 ---
	@(link_name="llvm.x86.sse4a.insertqi") llvm_insertqi :: proc(a, b: simd.i64x2, len: u8, idx: u8) -> simd.i64x2 ---
}
