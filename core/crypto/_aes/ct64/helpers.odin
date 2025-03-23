package aes_ct64

import "core:crypto/_aes"
import "core:encoding/endian"

@(require_results)
load_interleaved :: proc "contextless" (src: []byte) -> (u64, u64) #no_bounds_check {
	w0 := endian.unchecked_get_u32le(src[0:])
	w1 := endian.unchecked_get_u32le(src[4:])
	w2 := endian.unchecked_get_u32le(src[8:])
	w3 := endian.unchecked_get_u32le(src[12:])
	return interleave_in(w0, w1, w2, w3)
}

store_interleaved :: proc "contextless" (dst: []byte, a0, a1: u64) #no_bounds_check {
	w0, w1, w2, w3 := interleave_out(a0, a1)
	endian.unchecked_put_u32le(dst[0:], w0)
	endian.unchecked_put_u32le(dst[4:], w1)
	endian.unchecked_put_u32le(dst[8:], w2)
	endian.unchecked_put_u32le(dst[12:], w3)
}

@(require_results)
xor_interleaved :: #force_inline proc "contextless" (a0, a1, b0, b1: u64) -> (u64, u64) {
	return a0 ~ b0, a1 ~ b1
}

@(require_results)
and_interleaved :: #force_inline proc "contextless" (a0, a1, b0, b1: u64) -> (u64, u64) {
	return a0 & b0, a1 & b1
}

load_blockx1 :: proc "contextless" (q: ^[8]u64, src: []byte) {
	ensure_contextless(len(src) == _aes.BLOCK_SIZE, "aes/ct64: invalid block size")

	q[0], q[4] = #force_inline load_interleaved(src)
	orthogonalize(q)
}

store_blockx1 :: proc "contextless" (dst: []byte, q: ^[8]u64) {
	ensure_contextless(len(dst) == _aes.BLOCK_SIZE, "aes/ct64: invalid block size")

	orthogonalize(q)
	#force_inline store_interleaved(dst, q[0], q[4])
}

load_blocks :: proc "contextless" (q: ^[8]u64, src: [][]byte) {
	ensure_contextless(len(src) == 0 || len(src) <= STRIDE, "aes/ct64: invalid block(s) size")

	for s, i in src {
		ensure_contextless(len(s) == _aes.BLOCK_SIZE, "aes/ct64: invalid block size")
		q[i], q[i + 4] = #force_inline load_interleaved(s)
	}
	orthogonalize(q)
}

store_blocks :: proc "contextless" (dst: [][]byte, q: ^[8]u64) {
	ensure_contextless(len(dst) == 0 || len(dst) <= STRIDE, "aes/ct64: invalid block(s) size")

	orthogonalize(q)
	for d, i in dst {
		// Allow storing [0,4] blocks.
		if d == nil {
			break
		}
		ensure_contextless(len(d) == _aes.BLOCK_SIZE, "aes/ct64: invalid block size")
		#force_inline store_interleaved(d, q[i], q[i + 4])
	}
}
