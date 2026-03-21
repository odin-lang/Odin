package chacha20_ref

import "core:crypto/_chacha20"
import "core:encoding/endian"
import "core:math/bits"

// At least with LLVM21 force_inline produces identical perf to
// manual inlining, yay.
@(private)
quarter_round :: #force_inline proc "contextless" (a, b, c, d: u32) -> (u32, u32, u32, u32) {
	a, b, c, d := a, b, c, d

	a += b
	d ~= a
	d = bits.rotate_left32(d, 16)

	c += d
	b ~= c
	b = bits.rotate_left32(b, 12)

	a += b
	d ~= a
	d = bits.rotate_left32(d, 8)

	c += d
	b ~= c
	b = bits.rotate_left32(b, 7)

	return a, b, c, d
}

stream_blocks :: proc(ctx: ^_chacha20.Context, dst, src: []byte, nr_blocks: int) {
	// Enforce the maximum consumed keystream per IV.
	_chacha20.check_counter_limit(ctx, nr_blocks)

	dst, src := dst, src
	x := &ctx._s


	// Filippo Valsorda made an observation that only one of the column
	// round depends on the counter (s12), so it is worth precomputing
	// and reusing across multiple blocks.  As far as I know, only Go's
	// chacha implementation does this.

	p1, p5, p9, p13 := quarter_round(_chacha20.SIGMA_1, x[5], x[9], x[13])
	p2, p6, p10, p14 := quarter_round(_chacha20.SIGMA_2, x[6], x[10], x[14])
	p3, p7, p11, p15 := quarter_round(_chacha20.SIGMA_3, x[7], x[11], x[15])

	for n := 0; n < nr_blocks; n = n + 1 {
		// First column round that depends on the counter
		p0, p4, p8, p12 := quarter_round(_chacha20.SIGMA_0, x[4], x[8], x[12])

		// First diagonal round
		x0, x5, x10, x15 := quarter_round(p0, p5, p10, p15)
		x1, x6, x11, x12 := quarter_round(p1, p6, p11, p12)
		x2, x7, x8, x13 := quarter_round(p2, p7, p8, p13)
		x3, x4, x9, x14 := quarter_round(p3, p4, p9, p14)

		for i := _chacha20.ROUNDS - 2; i > 0; i = i - 2 {
			x0, x4, x8, x12 = quarter_round(x0, x4, x8, x12)
			x1, x5, x9, x13 = quarter_round(x1, x5, x9, x13)
			x2, x6, x10, x14 = quarter_round(x2, x6, x10, x14)
			x3, x7, x11, x15 = quarter_round(x3, x7, x11, x15)

			x0, x5, x10, x15 = quarter_round(x0, x5, x10, x15)
			x1, x6, x11, x12 = quarter_round(x1, x6, x11, x12)
			x2, x7, x8, x13 = quarter_round(x2, x7, x8, x13)
			x3, x4, x9, x14 = quarter_round(x3, x4, x9, x14)
		}

		x0 += _chacha20.SIGMA_0
		x1 += _chacha20.SIGMA_1
		x2 += _chacha20.SIGMA_2
		x3 += _chacha20.SIGMA_3
		x4 += x[4]
		x5 += x[5]
		x6 += x[6]
		x7 += x[7]
		x8 += x[8]
		x9 += x[9]
		x10 += x[10]
		x11 += x[11]
		x12 += x[12]
		x13 += x[13]
		x14 += x[14]
		x15 += x[15]

		// - The caller(s) ensure that src/dst are valid.
		// - The compiler knows if the target is picky about alignment.

		#no_bounds_check {
			if src != nil {
				endian.unchecked_put_u32le(dst[0:4], endian.unchecked_get_u32le(src[0:4]) ~ x0)
				endian.unchecked_put_u32le(dst[4:8], endian.unchecked_get_u32le(src[4:8]) ~ x1)
				endian.unchecked_put_u32le(dst[8:12], endian.unchecked_get_u32le(src[8:12]) ~ x2)
				endian.unchecked_put_u32le(dst[12:16], endian.unchecked_get_u32le(src[12:16]) ~ x3)
				endian.unchecked_put_u32le(dst[16:20], endian.unchecked_get_u32le(src[16:20]) ~ x4)
				endian.unchecked_put_u32le(dst[20:24], endian.unchecked_get_u32le(src[20:24]) ~ x5)
				endian.unchecked_put_u32le(dst[24:28], endian.unchecked_get_u32le(src[24:28]) ~ x6)
				endian.unchecked_put_u32le(dst[28:32], endian.unchecked_get_u32le(src[28:32]) ~ x7)
				endian.unchecked_put_u32le(dst[32:36], endian.unchecked_get_u32le(src[32:36]) ~ x8)
				endian.unchecked_put_u32le(dst[36:40], endian.unchecked_get_u32le(src[36:40]) ~ x9)
				endian.unchecked_put_u32le(
					dst[40:44],
					endian.unchecked_get_u32le(src[40:44]) ~ x10,
				)
				endian.unchecked_put_u32le(
					dst[44:48],
					endian.unchecked_get_u32le(src[44:48]) ~ x11,
				)
				endian.unchecked_put_u32le(
					dst[48:52],
					endian.unchecked_get_u32le(src[48:52]) ~ x12,
				)
				endian.unchecked_put_u32le(
					dst[52:56],
					endian.unchecked_get_u32le(src[52:56]) ~ x13,
				)
				endian.unchecked_put_u32le(
					dst[56:60],
					endian.unchecked_get_u32le(src[56:60]) ~ x14,
				)
				endian.unchecked_put_u32le(
					dst[60:64],
					endian.unchecked_get_u32le(src[60:64]) ~ x15,
				)
				src = src[_chacha20.BLOCK_SIZE:]
			} else {
				endian.unchecked_put_u32le(dst[0:4], x0)
				endian.unchecked_put_u32le(dst[4:8], x1)
				endian.unchecked_put_u32le(dst[8:12], x2)
				endian.unchecked_put_u32le(dst[12:16], x3)
				endian.unchecked_put_u32le(dst[16:20], x4)
				endian.unchecked_put_u32le(dst[20:24], x5)
				endian.unchecked_put_u32le(dst[24:28], x6)
				endian.unchecked_put_u32le(dst[28:32], x7)
				endian.unchecked_put_u32le(dst[32:36], x8)
				endian.unchecked_put_u32le(dst[36:40], x9)
				endian.unchecked_put_u32le(dst[40:44], x10)
				endian.unchecked_put_u32le(dst[44:48], x11)
				endian.unchecked_put_u32le(dst[48:52], x12)
				endian.unchecked_put_u32le(dst[52:56], x13)
				endian.unchecked_put_u32le(dst[56:60], x14)
				endian.unchecked_put_u32le(dst[60:64], x15)
			}
			dst = dst[_chacha20.BLOCK_SIZE:]
		}

		// Increment the counter.  Overflow checking is done upon
		// entry into the routine, so a 64-bit increment safely
		// covers both cases.
		new_ctr := ((u64(ctx._s[13]) << 32) | u64(ctx._s[12])) + 1
		x[12] = u32(new_ctr)
		x[13] = u32(new_ctr >> 32)
	}
}

hchacha20 :: proc "contextless" (dst, key, iv: []byte) {
	x0, x1, x2, x3 := _chacha20.SIGMA_0, _chacha20.SIGMA_1, _chacha20.SIGMA_2, _chacha20.SIGMA_3
	x4 := endian.unchecked_get_u32le(key[0:4])
	x5 := endian.unchecked_get_u32le(key[4:8])
	x6 := endian.unchecked_get_u32le(key[8:12])
	x7 := endian.unchecked_get_u32le(key[12:16])
	x8 := endian.unchecked_get_u32le(key[16:20])
	x9 := endian.unchecked_get_u32le(key[20:24])
	x10 := endian.unchecked_get_u32le(key[24:28])
	x11 := endian.unchecked_get_u32le(key[28:32])
	x12 := endian.unchecked_get_u32le(iv[0:4])
	x13 := endian.unchecked_get_u32le(iv[4:8])
	x14 := endian.unchecked_get_u32le(iv[8:12])
	x15 := endian.unchecked_get_u32le(iv[12:16])

	for i := _chacha20.ROUNDS; i > 0; i = i - 2 {
		x0, x4, x8, x12 = quarter_round(x0, x4, x8, x12)
		x1, x5, x9, x13 = quarter_round(x1, x5, x9, x13)
		x2, x6, x10, x14 = quarter_round(x2, x6, x10, x14)
		x3, x7, x11, x15 = quarter_round(x3, x7, x11, x15)

		x0, x5, x10, x15 = quarter_round(x0, x5, x10, x15)
		x1, x6, x11, x12 = quarter_round(x1, x6, x11, x12)
		x2, x7, x8, x13 = quarter_round(x2, x7, x8, x13)
		x3, x4, x9, x14 = quarter_round(x3, x4, x9, x14)
	}

	endian.unchecked_put_u32le(dst[0:4], x0)
	endian.unchecked_put_u32le(dst[4:8], x1)
	endian.unchecked_put_u32le(dst[8:12], x2)
	endian.unchecked_put_u32le(dst[12:16], x3)
	endian.unchecked_put_u32le(dst[16:20], x12)
	endian.unchecked_put_u32le(dst[20:24], x13)
	endian.unchecked_put_u32le(dst[24:28], x14)
	endian.unchecked_put_u32le(dst[28:32], x15)
}
