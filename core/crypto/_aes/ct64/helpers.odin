package aes_ct64

import "base:intrinsics"
import "core:crypto/_aes"
import "core:encoding/endian"

load_blockx1 :: proc "contextless" (q: ^[8]u64, src: []byte) {
	if len(src) != _aes.BLOCK_SIZE {
		intrinsics.trap()
	}

	w: [4]u32 = ---
	w[0] = endian.unchecked_get_u32le(src[0:])
	w[1] = endian.unchecked_get_u32le(src[4:])
	w[2] = endian.unchecked_get_u32le(src[8:])
	w[3] = endian.unchecked_get_u32le(src[12:])
	q[0], q[4] = interleave_in(w[:])
	orthogonalize(q)
}

store_blockx1 :: proc "contextless" (dst: []byte, q: ^[8]u64) {
	if len(dst) != _aes.BLOCK_SIZE {
		intrinsics.trap()
	}

	orthogonalize(q)
	w0, w1, w2, w3 := interleave_out(q[0], q[4])
	endian.unchecked_put_u32le(dst[0:], w0)
	endian.unchecked_put_u32le(dst[4:], w1)
	endian.unchecked_put_u32le(dst[8:], w2)
	endian.unchecked_put_u32le(dst[12:], w3)
}

load_blocks :: proc "contextless" (q: ^[8]u64, src: [][]byte) {
	if n := len(src); n > STRIDE || n == 0 {
		intrinsics.trap()
	}

	w: [4]u32 = ---
	for s, i in src {
		if len(s) != _aes.BLOCK_SIZE {
			intrinsics.trap()
		}

		w[0] = endian.unchecked_get_u32le(s[0:])
		w[1] = endian.unchecked_get_u32le(s[4:])
		w[2] = endian.unchecked_get_u32le(s[8:])
		w[3] = endian.unchecked_get_u32le(s[12:])
		q[i], q[i + 4] = interleave_in(w[:])
	}
	orthogonalize(q)
}

store_blocks :: proc "contextless" (dst: [][]byte, q: ^[8]u64) {
	if n := len(dst); n > STRIDE || n == 0 {
		intrinsics.trap()
	}

	orthogonalize(q)
	for d, i in dst {
		// Allow storing [0,4] blocks.
		if d == nil {
			break
		}
		if len(d) != _aes.BLOCK_SIZE {
			intrinsics.trap()
		}

		w0, w1, w2, w3 := interleave_out(q[i], q[i + 4])
		endian.unchecked_put_u32le(d[0:], w0)
		endian.unchecked_put_u32le(d[4:], w1)
		endian.unchecked_put_u32le(d[8:], w2)
		endian.unchecked_put_u32le(d[12:], w3)
	}
}
