package _sha3

import "core:encoding/endian"
import "core:math/bits"

init_cshake :: proc(ctx: ^Context, n, s: []byte, sec_strength: int) {
	ctx.mdlen = sec_strength / 8

	// No domain separator is equivalent to vanilla SHAKE.
	if len(n) == 0 && len(s) == 0 {
		ctx.dsbyte = DS_SHAKE
		init(ctx)
		return
	}

	ctx.dsbyte = DS_CSHAKE
	init(ctx)
	bytepad(ctx, [][]byte{n, s}, rate_cshake(sec_strength))
}

final_cshake :: proc(ctx: ^Context, dst: []byte, finalize_clone: bool = false) {
	ctx := ctx
	if finalize_clone {
		tmp_ctx: Context
		clone(&tmp_ctx, ctx)
		ctx = &tmp_ctx
	}
	defer reset(ctx)

	encode_byte_len(ctx, len(dst), false) // right_encode
	shake_xof(ctx)
	shake_out(ctx, dst)
}

rate_cshake :: #force_inline proc(sec_strength: int) -> int {
	switch sec_strength {
	case 128:
		return RATE_128
	case 256:
		return RATE_256
	}

	panic("crypto/sha3: invalid security strength")
}

// right_encode and left_encode are defined to support 0 <= x < 2^2040
// however, the largest value we will ever need to encode is `max(int) * 8`.
//
// This is unfortunate as the extreme upper edge is larger than
// `max(u64)`.  While such values are impractical at present,
// they are possible (ie: https://arxiv.org/pdf/quant-ph/9908043.pdf).
//
// Thus we support 0 <= x < 2^128.

@(private)
_PAD: [RATE_128]byte // Biggest possible value of w per spec.

bytepad :: proc(ctx: ^Context, x_strings: [][]byte, w: int) {
	// 1. z = left_encode(w) || X.
	z_hi: u64
	z_lo := left_right_encode(ctx, 0, u64(w), true)
	for x in x_strings {
		// All uses of bytepad in SP 800-185 use the output from
		// one or more encode_string values for `X`.
		hi, lo := encode_string(ctx, x)

		carry: u64
		z_lo, carry = bits.add_u64(z_lo, lo, 0)
		z_hi, carry = bits.add_u64(z_hi, hi, carry)

		// This isn't actually possible, at least with the currently
		// defined SP 800-185 routines.
		if carry != 0 {
			panic("crypto/sha3: bytepad input length overflow")
		}
	}

	// We skip this step as we are doing a byte-oriented implementation
	// rather than a bit oriented one.
	//
	// 2. while len(z) mod 8 ≠ 0:
	//    z = z || 0

	// 3. while (len(z)/8) mod w != 0:
	//    z = z || 00000000
	z_len := u128(z_hi) << 64 | u128(z_lo)
	z_rem := int(z_len % u128(w))
	if z_rem != 0 {
		pad := _PAD[:w - z_rem]

		// We just add the padding to the state, instead of returning z.
		//
		// 4. return z.
		update(ctx, pad)
	}
}

encode_string :: #force_inline proc(ctx: ^Context, s: []byte) -> (u64, u64) {
	l := encode_byte_len(ctx, len(s), true) // left_encode
	update(ctx, s)

	lo, hi := bits.add_u64(l, u64(len(s)), 0)

	return hi, lo
}

encode_byte_len :: #force_inline proc(ctx: ^Context, l: int, is_left: bool) -> u64 {
	hi, lo := bits.mul_u64(u64(l), 8)
	return left_right_encode(ctx, hi, lo, is_left)
}

@(private)
left_right_encode :: proc(ctx: ^Context, hi, lo: u64, is_left: bool) -> u64 {
	HI_OFFSET :: 1
	LO_OFFSET :: HI_OFFSET + 8
	RIGHT_OFFSET :: LO_OFFSET + 8
	BUF_LEN :: RIGHT_OFFSET + 1

	buf: [BUF_LEN]byte // prefix + largest uint + postfix

	endian.unchecked_put_u64be(buf[HI_OFFSET:], hi)
	endian.unchecked_put_u64be(buf[LO_OFFSET:], lo)

	// 2. Strip leading `0x00` bytes.
	off: int
	for off = HI_OFFSET; off < RIGHT_OFFSET - 1; off = off + 1 {// Note: Minimum size is 1, not 0.
		if buf[off] != 0 {
			break
		}
	}
	n := byte(RIGHT_OFFSET - off)

	// 3. Prefix (left_encode) or postfix (right_encode) the length in bytes.
	b: []byte
	switch is_left {
	case true:
		buf[off - 1] = n // n | x
		b = buf[off - 1:RIGHT_OFFSET]
	case false:
		buf[RIGHT_OFFSET] = n // x | n
		b = buf[off:]
	}

	update(ctx, b)

	return u64(len(b))
}
