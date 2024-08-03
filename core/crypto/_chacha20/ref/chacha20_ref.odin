package chacha20_ref

import "core:crypto/_chacha20"
import "core:encoding/endian"
import "core:math/bits"

stream_blocks :: proc(ctx: ^_chacha20.Context, dst, src: []byte, nr_blocks: int) {
	// Enforce the maximum consumed keystream per IV.
	_chacha20.check_counter_limit(ctx, nr_blocks)

	dst, src := dst, src
	x := &ctx._s
	for n := 0; n < nr_blocks; n = n + 1 {
		x0, x1, x2, x3 :=
			_chacha20.SIGMA_0, _chacha20.SIGMA_1, _chacha20.SIGMA_2, _chacha20.SIGMA_3
		x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 :=
			x[4], x[5], x[6], x[7], x[8], x[9], x[10], x[11], x[12], x[13], x[14], x[15]

		for i := _chacha20.ROUNDS; i > 0; i = i - 2 {
			// Even when forcing inlining manually inlining all of
			// these is decently faster.

			// quarterround(x, 0, 4, 8, 12)
			x0 += x4
			x12 ~= x0
			x12 = bits.rotate_left32(x12, 16)
			x8 += x12
			x4 ~= x8
			x4 = bits.rotate_left32(x4, 12)
			x0 += x4
			x12 ~= x0
			x12 = bits.rotate_left32(x12, 8)
			x8 += x12
			x4 ~= x8
			x4 = bits.rotate_left32(x4, 7)

			// quarterround(x, 1, 5, 9, 13)
			x1 += x5
			x13 ~= x1
			x13 = bits.rotate_left32(x13, 16)
			x9 += x13
			x5 ~= x9
			x5 = bits.rotate_left32(x5, 12)
			x1 += x5
			x13 ~= x1
			x13 = bits.rotate_left32(x13, 8)
			x9 += x13
			x5 ~= x9
			x5 = bits.rotate_left32(x5, 7)

			// quarterround(x, 2, 6, 10, 14)
			x2 += x6
			x14 ~= x2
			x14 = bits.rotate_left32(x14, 16)
			x10 += x14
			x6 ~= x10
			x6 = bits.rotate_left32(x6, 12)
			x2 += x6
			x14 ~= x2
			x14 = bits.rotate_left32(x14, 8)
			x10 += x14
			x6 ~= x10
			x6 = bits.rotate_left32(x6, 7)

			// quarterround(x, 3, 7, 11, 15)
			x3 += x7
			x15 ~= x3
			x15 = bits.rotate_left32(x15, 16)
			x11 += x15
			x7 ~= x11
			x7 = bits.rotate_left32(x7, 12)
			x3 += x7
			x15 ~= x3
			x15 = bits.rotate_left32(x15, 8)
			x11 += x15
			x7 ~= x11
			x7 = bits.rotate_left32(x7, 7)

			// quarterround(x, 0, 5, 10, 15)
			x0 += x5
			x15 ~= x0
			x15 = bits.rotate_left32(x15, 16)
			x10 += x15
			x5 ~= x10
			x5 = bits.rotate_left32(x5, 12)
			x0 += x5
			x15 ~= x0
			x15 = bits.rotate_left32(x15, 8)
			x10 += x15
			x5 ~= x10
			x5 = bits.rotate_left32(x5, 7)

			// quarterround(x, 1, 6, 11, 12)
			x1 += x6
			x12 ~= x1
			x12 = bits.rotate_left32(x12, 16)
			x11 += x12
			x6 ~= x11
			x6 = bits.rotate_left32(x6, 12)
			x1 += x6
			x12 ~= x1
			x12 = bits.rotate_left32(x12, 8)
			x11 += x12
			x6 ~= x11
			x6 = bits.rotate_left32(x6, 7)

			// quarterround(x, 2, 7, 8, 13)
			x2 += x7
			x13 ~= x2
			x13 = bits.rotate_left32(x13, 16)
			x8 += x13
			x7 ~= x8
			x7 = bits.rotate_left32(x7, 12)
			x2 += x7
			x13 ~= x2
			x13 = bits.rotate_left32(x13, 8)
			x8 += x13
			x7 ~= x8
			x7 = bits.rotate_left32(x7, 7)

			// quarterround(x, 3, 4, 9, 14)
			x3 += x4
			x14 ~= x3
			x14 = bits.rotate_left32(x14, 16)
			x9 += x14
			x4 ~= x9
			x4 = bits.rotate_left32(x4, 12)
			x3 += x4
			x14 ~= x3
			x14 = bits.rotate_left32(x14, 8)
			x9 += x14
			x4 ~= x9
			x4 = bits.rotate_left32(x4, 7)
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
		// quarterround(x, 0, 4, 8, 12)
		x0 += x4
		x12 ~= x0
		x12 = bits.rotate_left32(x12, 16)
		x8 += x12
		x4 ~= x8
		x4 = bits.rotate_left32(x4, 12)
		x0 += x4
		x12 ~= x0
		x12 = bits.rotate_left32(x12, 8)
		x8 += x12
		x4 ~= x8
		x4 = bits.rotate_left32(x4, 7)

		// quarterround(x, 1, 5, 9, 13)
		x1 += x5
		x13 ~= x1
		x13 = bits.rotate_left32(x13, 16)
		x9 += x13
		x5 ~= x9
		x5 = bits.rotate_left32(x5, 12)
		x1 += x5
		x13 ~= x1
		x13 = bits.rotate_left32(x13, 8)
		x9 += x13
		x5 ~= x9
		x5 = bits.rotate_left32(x5, 7)

		// quarterround(x, 2, 6, 10, 14)
		x2 += x6
		x14 ~= x2
		x14 = bits.rotate_left32(x14, 16)
		x10 += x14
		x6 ~= x10
		x6 = bits.rotate_left32(x6, 12)
		x2 += x6
		x14 ~= x2
		x14 = bits.rotate_left32(x14, 8)
		x10 += x14
		x6 ~= x10
		x6 = bits.rotate_left32(x6, 7)

		// quarterround(x, 3, 7, 11, 15)
		x3 += x7
		x15 ~= x3
		x15 = bits.rotate_left32(x15, 16)
		x11 += x15
		x7 ~= x11
		x7 = bits.rotate_left32(x7, 12)
		x3 += x7
		x15 ~= x3
		x15 = bits.rotate_left32(x15, 8)
		x11 += x15
		x7 ~= x11
		x7 = bits.rotate_left32(x7, 7)

		// quarterround(x, 0, 5, 10, 15)
		x0 += x5
		x15 ~= x0
		x15 = bits.rotate_left32(x15, 16)
		x10 += x15
		x5 ~= x10
		x5 = bits.rotate_left32(x5, 12)
		x0 += x5
		x15 ~= x0
		x15 = bits.rotate_left32(x15, 8)
		x10 += x15
		x5 ~= x10
		x5 = bits.rotate_left32(x5, 7)

		// quarterround(x, 1, 6, 11, 12)
		x1 += x6
		x12 ~= x1
		x12 = bits.rotate_left32(x12, 16)
		x11 += x12
		x6 ~= x11
		x6 = bits.rotate_left32(x6, 12)
		x1 += x6
		x12 ~= x1
		x12 = bits.rotate_left32(x12, 8)
		x11 += x12
		x6 ~= x11
		x6 = bits.rotate_left32(x6, 7)

		// quarterround(x, 2, 7, 8, 13)
		x2 += x7
		x13 ~= x2
		x13 = bits.rotate_left32(x13, 16)
		x8 += x13
		x7 ~= x8
		x7 = bits.rotate_left32(x7, 12)
		x2 += x7
		x13 ~= x2
		x13 = bits.rotate_left32(x13, 8)
		x8 += x13
		x7 ~= x8
		x7 = bits.rotate_left32(x7, 7)

		// quarterround(x, 3, 4, 9, 14)
		x3 += x4
		x14 ~= x3
		x14 = bits.rotate_left32(x14, 16)
		x9 += x14
		x4 ~= x9
		x4 = bits.rotate_left32(x4, 12)
		x3 += x4
		x14 ~= x3
		x14 = bits.rotate_left32(x14, 8)
		x9 += x14
		x4 ~= x9
		x4 = bits.rotate_left32(x4, 7)
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
