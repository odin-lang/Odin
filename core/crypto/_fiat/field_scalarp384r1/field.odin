package field_scalarp384r1

import "core:crypto"
import subtle "core:crypto/_subtle"
import "core:encoding/endian"
import "core:math/bits"

@(private, rodata)
TWO_256 := Montgomery_Domain_Field_Element{
	17975668497346362272,
	12895982994901192340,
	1913828944324294218,
	902107514168524577,
	1374695839762142861,
	12098342389602539653,
}

fe_clear :: proc "contextless" (arg1: ^Montgomery_Domain_Field_Element) {
	crypto.zero_explicit(arg1, size_of(Montgomery_Domain_Field_Element))
}

fe_clear_vec :: proc "contextless" (
	arg1: []^Montgomery_Domain_Field_Element,
) {
	for fe in arg1 {
		fe_clear(fe)
	}
}

fe_from_bytes :: proc "contextless" (
	out1: ^Montgomery_Domain_Field_Element,
	arg1: []byte,
) -> bool {
	ensure_contextless(len(out1) <= 64, "p384r1: invalid scalar input buffer")

	is_canonical := false
	s_len := len(arg1)
	switch {
	case s_len < 48:
		// No way this can be greater than the order.
		fe_unchecked_set(out1, arg1)
		is_canonical = true
	case s_len == 48:
		// There is no way for any 384-bit value to be >= 2n, so
		// the reduction can be done by `src - n` and a conditional
		// select based on the underflow.
		//
		// It is *extremely* unlikely that the reduction is actually
		// needed.
		tmp: Non_Montgomery_Domain_Field_Element = ---
		fe_unchecked_set_saturated(&tmp, arg1)
		reduced := tmp
		defer crypto.zero_explicit(&tmp, size_of(tmp))
		defer crypto.zero_explicit(&reduced, size_of(reduced))

		borrow: u64
		reduced[0], borrow = bits.sub_u64(tmp[0], ELL[0], borrow)
		reduced[1], borrow = bits.sub_u64(tmp[1], ELL[1], borrow)
		reduced[2], borrow = bits.sub_u64(tmp[2], ELL[2], borrow)
		reduced[3], borrow = bits.sub_u64(tmp[3], ELL[3], borrow)
		reduced[4], borrow = bits.sub_u64(tmp[4], ELL[4], borrow)
		reduced[5], borrow = bits.sub_u64(tmp[5], ELL[5], borrow)
		need_reduced := subtle.u64_is_zero(borrow)

		fe_cond_select(&tmp, &tmp, &reduced, int(need_reduced))
		fe_to_montgomery(out1, &tmp)

		is_canonical = need_reduced == 0
	case:
		// Use Frank Denis' trick, as documented by Filippo Valsorda
		// at https://words.filippo.io/dispatches/wide-reduction/
		//
		// "I represent the value as a+b*2^192+c*2^384"
		//
		// Since digests beyond 512-bits are unrealistic, we do
		// "a+b*2^256"

		// Zero extend to 512-bits.
		src_512: [64]byte
		copy(src_512[64-s_len:], arg1)
		defer crypto.zero_explicit(&src_512, size_of(src_512))

		fe_unchecked_set(out1, src_512[32:]) // a
		b: Montgomery_Domain_Field_Element
		fe_unchecked_set(&b, src_512[:32]) // b

		fe_mul(&b, &b, &TWO_256)
		fe_add(out1, out1, &b)

		fe_clear(&b)
	}

	return !is_canonical
}

@(private)
fe_is_canonical :: proc "contextless" (arg1: []byte) -> bool {
	_, borrow := bits.sub_u64(ELL[0] - 1, endian.unchecked_get_u64be(arg1[40:]), 0)
	_, borrow = bits.sub_u64(ELL[1], endian.unchecked_get_u64be(arg1[32:]), borrow)
	_, borrow = bits.sub_u64(ELL[2], endian.unchecked_get_u64be(arg1[24:]), borrow)
	_, borrow = bits.sub_u64(ELL[3], endian.unchecked_get_u64be(arg1[16:]), borrow)
	_, borrow = bits.sub_u64(ELL[4], endian.unchecked_get_u64be(arg1[8:]), borrow)
	_, borrow = bits.sub_u64(ELL[5], endian.unchecked_get_u64be(arg1[0:]), borrow)
	return borrow == 0
}

@(private="file")
fe_unchecked_set_saturated :: proc "contextless" (out1: ^Non_Montgomery_Domain_Field_Element, arg1: []byte) {
	out1[0] = endian.unchecked_get_u64be(arg1[40:])
	out1[1] = endian.unchecked_get_u64be(arg1[32:])
	out1[2] = endian.unchecked_get_u64be(arg1[24:])
	out1[3] = endian.unchecked_get_u64be(arg1[16:])
	out1[4] = endian.unchecked_get_u64be(arg1[8:])
	out1[5] = endian.unchecked_get_u64be(arg1[0:])
}

@(private)
fe_unchecked_set :: proc "contextless" (out1: ^Montgomery_Domain_Field_Element, arg1: []byte) {
	arg1_384: [48]byte
	defer crypto.zero_explicit(&arg1_384, size_of(arg1_384))
	copy(arg1_384[48-len(arg1):], arg1)

	tmp: Non_Montgomery_Domain_Field_Element = ---
	fe_unchecked_set_saturated(&tmp, arg1_384[:])
	defer crypto.zero_explicit(&tmp, size_of(tmp))

	fe_to_montgomery(out1, &tmp)
}

fe_to_bytes :: proc "contextless" (out1: []byte, arg1: ^Montgomery_Domain_Field_Element) {
	ensure_contextless(len(out1) == 48, "p384r1: invalid scalar output buffer")

	tmp: Non_Montgomery_Domain_Field_Element = ---
	fe_from_montgomery(&tmp, arg1)

	// Note: Likewise, output in big-endian.
	endian.unchecked_put_u64be(out1[40:], tmp[0])
	endian.unchecked_put_u64be(out1[32:], tmp[1])
	endian.unchecked_put_u64be(out1[24:], tmp[2])
	endian.unchecked_put_u64be(out1[16:], tmp[3])
	endian.unchecked_put_u64be(out1[8:], tmp[4])
	endian.unchecked_put_u64be(out1[0:], tmp[5])

	crypto.zero_explicit(&tmp, size_of(tmp))
}

fe_equal :: proc "contextless" (arg1, arg2: ^Montgomery_Domain_Field_Element) -> int {
	tmp: Montgomery_Domain_Field_Element = ---
	fe_sub(&tmp, arg1, arg2)

	is_eq := subtle.eq(fe_non_zero(&tmp), 0)

	fe_clear(&tmp)

	return int(is_eq)
}

fe_is_odd :: proc "contextless" (arg1: ^Montgomery_Domain_Field_Element) -> int {
	tmp: Non_Montgomery_Domain_Field_Element = ---
	defer crypto.zero_explicit(&tmp, size_of(tmp))

	fe_from_montgomery(&tmp, arg1)
	return int(tmp[0] & 1)
}

fe_zero :: proc "contextless" (out1: ^Montgomery_Domain_Field_Element) {
	out1[0] = 0
	out1[1] = 0
	out1[2] = 0
	out1[3] = 0
	out1[4] = 0
	out1[5] = 0
}

fe_set :: proc "contextless" (out1, arg1: ^Montgomery_Domain_Field_Element) {
	x1 := arg1[0]
	x2 := arg1[1]
	x3 := arg1[2]
	x4 := arg1[3]
	x5 := arg1[4]
	x6 := arg1[5]
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
	out1[5] = x6
}

@(optimization_mode = "none")
fe_cond_swap :: #force_no_inline proc "contextless" (out1, out2: ^Montgomery_Domain_Field_Element, arg1: int) {
	mask := (u64(arg1) * 0xffffffffffffffff)
	x := (out1[0] ~ out2[0]) & mask
	x1, y1 := out1[0] ~ x, out2[0] ~ x
	x = (out1[1] ~ out2[1]) & mask
	x2, y2 := out1[1] ~ x, out2[1] ~ x
	x = (out1[2] ~ out2[2]) & mask
	x3, y3 := out1[2] ~ x, out2[2] ~ x
	x = (out1[3] ~ out2[3]) & mask
	x4, y4 := out1[3] ~ x, out2[3] ~ x
	x = (out1[4] ~ out2[4]) & mask
	x5, y5 := out1[4] ~ x, out2[4] ~ x
	x = (out1[5] ~ out2[5]) & mask
	x6, y6 := out1[5] ~ x, out2[5] ~ x
	out1[0], out2[0] = x1, y1
	out1[1], out2[1] = x2, y2
	out1[2], out2[2] = x3, y3
	out1[3], out2[3] = x4, y4
	out1[4], out2[4] = x5, y5
	out1[5], out2[5] = x6, y6
}

@(optimization_mode = "none")
fe_cond_select :: #force_no_inline proc "contextless" (
	out1, arg1, arg2: ^$T,
	arg3: int,
) where T == Montgomery_Domain_Field_Element || T == Non_Montgomery_Domain_Field_Element {
	mask := (u64(arg3) * 0xffffffffffffffff)
	x1 := ((mask & arg2[0]) | ((~mask) & arg1[0]))
	x2 := ((mask & arg2[1]) | ((~mask) & arg1[1]))
	x3 := ((mask & arg2[2]) | ((~mask) & arg1[2]))
	x4 := ((mask & arg2[3]) | ((~mask) & arg1[3]))
	x5 := ((mask & arg2[4]) | ((~mask) & arg1[4]))
	x6 := ((mask & arg2[5]) | ((~mask) & arg1[5]))
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
	out1[4] = x5
	out1[5] = x6
}

fe_cond_negate :: proc "contextless" (out1, arg1: ^Montgomery_Domain_Field_Element, ctrl: int) {
	tmp1: Montgomery_Domain_Field_Element = ---
	fe_opp(&tmp1, arg1)
	fe_cond_select(out1, arg1, &tmp1, ctrl)

	fe_clear(&tmp1)
}

fe_pow2k :: proc "contextless" (
	out1: ^Montgomery_Domain_Field_Element,
	arg1: ^Montgomery_Domain_Field_Element,
	arg2: uint,
) {
	// Special case: `arg1^(2 * 0) = 1`, though this should never happen.
	if arg2 == 0 {
		fe_one(out1)
		return
	}

	fe_square(out1, arg1)
	for _ in 1 ..< arg2 {
		fe_square(out1, out1)
	}
}

fe_inv :: proc "contextless" (out1, arg1: ^Montgomery_Domain_Field_Element) {
	// Inversion computation is derived from the addition chain:
	//
	//	_10      = 2*1
	//	_11      = 1 + _10
	//	_101     = _10 + _11
	//	_111     = _10 + _101
	//	_1001    = _10 + _111
	//	_1011    = _10 + _1001
	//	_1101    = _10 + _1011
	//	_1111    = _10 + _1101
	//	_11110   = 2*_1111
	//	_11111   = 1 + _11110
	//	_1111100 = _11111 << 2
	//	i14      = _1111100 << 2
	//	i26      = (i14 << 3 + _1111100) << 7 + i14
	//	i42      = i26 << 15 + i26
	//	x64      = i42 << 30 + i42 + _1111
	//	x128     = x64 << 64 + x64
	//	x192     = x128 << 64 + x64
	//	x194     = x192 << 2 + _11
	//	i225     = ((x194 << 6 + _111) << 3 + _11) << 7
	//	i235     = 2*((_1101 + i225) << 6 + _1101) + 1
	//	i258     = ((i235 << 11 + _11111) << 2 + 1) << 8
	//	i269     = ((_1101 + i258) << 2 + _11) << 6 + _1011
	//	i286     = ((i269 << 4 + _111) << 6 + _11111) << 5
	//	i308     = ((_1011 + i286) << 10 + _1101) << 9 + _1101
	//	i323     = ((i308 << 4 + _1011) << 6 + _1001) << 3
	//	i340     = ((1 + i323) << 7 + _1011) << 7 + _101
	//	i357     = ((i340 << 5 + _111) << 5 + _1111) << 5
	//	i369     = ((_1011 + i357) << 4 + _1011) << 5 + _111
	//	i387     = ((i369 << 3 + _11) << 7 + _11) << 6
	//	i397     = ((_1011 + i387) << 4 + _101) << 3 + _11
	//	i413     = ((i397 << 4 + _11) << 4 + _11) << 6
	//	i427     = ((_101 + i413) << 5 + _101) << 6 + _1011
	//	return     (2*i427 + 1) << 4 + 1
	//
	// Operations: 381 squares 53 multiplies
	//
	// Generated by github.com/mmcloughlin/addchain v0.4.0.

	// Note: Need to stash `arg1` (`xx`) in the case that `out1`/`arg1` alias,
	// as `arg1` is used after `out1` has been altered.
	t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, xx: Montgomery_Domain_Field_Element = ---, ---, ---, ---, ---, ---, ---, ---, ---, ---, arg1^

	// Step 1: t3 = x^0x2
	fe_square(&t3, arg1)

	// Step 2: t1 = x^0x3
	fe_mul(&t1, arg1, &t3)

	// Step 3: t0 = x^0x5
	fe_mul(&t0, &t3, &t1)

	// Step 4: t2 = x^0x7
	fe_mul(&t2, &t3, &t0)

	// Step 5: t4 = x^0x9
	fe_mul(&t4, &t3, &t2)

	// Step 6: z = x^0xb
	fe_mul(out1, &t3, &t4)

	// Step 7: t5 = x^0xd
	fe_mul(&t5, &t3, out1)

	// Step 8: t3 = x^0xf
	fe_mul(&t3, &t3, &t5)

	// Step 9: t6 = x^0x1e
	fe_square(&t6, &t3)

	// Step 10: t6 = x^0x1f
	fe_mul(&t6, &xx, &t6)

	// Step 12: t8 = x^0x7c
	fe_pow2k(&t8, &t6, 2)

	// Step 14: t7 = x^0x1f0
	fe_pow2k(&t7, &t8, 2)

	// Step 17: t9 = x^0xf80
	fe_pow2k(&t9, &t7, 3)

	// Step 18: t8 = x^0xffc
	fe_mul(&t8, &t8, &t9)

	// Step 25: t8 = x^0x7fe00
	fe_pow2k(&t8, &t8, 7)

	// Step 26: t7 = x^0x7fff0
	fe_mul(&t7, &t7, &t8)

	// Step 41: t8 = x^0x3fff80000
	fe_pow2k(&t8, &t7, 15)

	// Step 42: t7 = x^0x3fffffff0
	fe_mul(&t7, &t7, &t8)

	// Step 72: t8 = x^0xfffffffc00000000
	fe_pow2k(&t8, &t7, 30)

	// Step 73: t7 = x^0xfffffffffffffff0
	fe_mul(&t7, &t7, &t8)

	// Step 74: t7 = x^0xffffffffffffffff
	fe_mul(&t7, &t3, &t7)

	// Step 138: t8 = x^0xffffffffffffffff0000000000000000
	fe_pow2k(&t8, &t7, 64)

	// Step 139: t8 = x^0xffffffffffffffffffffffffffffffff
	fe_mul(&t8, &t7, &t8)

	// Step 203: t8 = x^0xffffffffffffffffffffffffffffffff0000000000000000
	fe_pow2k(&t8, &t8, 64)

	// Step 204: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffff
	fe_mul(&t7, &t7, &t8)

	// Step 206: t7 = x^0x3fffffffffffffffffffffffffffffffffffffffffffffffc
	fe_pow2k(&t7, &t7, 2)

	// Step 207: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff
	fe_mul(&t7, &t1, &t7)

	// Step 213: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc0
	fe_pow2k(&t7, &t7, 6)

	// Step 214: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7
	fe_mul(&t7, &t2, &t7)

	// Step 217: t7 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe38
	fe_pow2k(&t7, &t7, 3)

	// Step 218: t7 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b
	fe_mul(&t7, &t1, &t7)

	// Step 225: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d80
	fe_pow2k(&t7, &t7, 7)

	// Step 226: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d
	fe_mul(&t7, &t5, &t7)

	// Step 232: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc76340
	fe_pow2k(&t7, &t7, 6)

	// Step 233: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d
	fe_mul(&t7, &t5, &t7)

	// Step 234: t7 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69a
	fe_square(&t7, &t7)

	// Step 235: t7 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b
	fe_mul(&t7, &xx, &t7)

	// Step 246: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d800
	fe_pow2k(&t7, &t7, 11)

	// Step 247: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f
	fe_mul(&t7, &t6, &t7)

	// Step 249: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607c
	fe_pow2k(&t7, &t7, 2)

	// Step 250: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d
	fe_mul(&t7, &xx, &t7)

	// Step 258: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d00
	fe_pow2k(&t7, &t7, 8)

	// Step 259: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0d
	fe_mul(&t7, &t5, &t7)

	// Step 261: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f434
	fe_pow2k(&t7, &t7, 2)

	// Step 262: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f437
	fe_mul(&t7, &t1, &t7)

	// Step 268: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dc0
	fe_pow2k(&t7, &t7, 6)

	// Step 269: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb
	fe_mul(&t7, out1, &t7)

	// Step 273: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb0
	fe_pow2k(&t7, &t7, 4)

	// Step 274: t7 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb7
	fe_mul(&t7, &t2, &t7)

	// Step 280: t7 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372dc0
	fe_pow2k(&t7, &t7, 6)

	// Step 281: t6 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf
	fe_mul(&t6, &t6, &t7)

	// Step 286: t6 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbe0
	fe_pow2k(&t6, &t6, 5)

	// Step 287: t6 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb
	fe_mul(&t6, out1, &t6)

	// Step 297: t6 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac00
	fe_pow2k(&t6, &t6, 10)

	// Step 298: t6 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d
	fe_mul(&t6, &t5, &t6)

	// Step 307: t6 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a00
	fe_pow2k(&t6, &t6, 9)

	// Step 308: t5 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0d
	fe_mul(&t5, &t5, &t6)

	// Step 312: t5 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0d0
	fe_pow2k(&t5, &t5, 4)

	// Step 313: t5 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db
	fe_mul(&t5, out1, &t5)

	// Step 319: t5 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c0
	fe_pow2k(&t5, &t5, 6)

	// Step 320: t4 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c9
	fe_mul(&t4, &t4, &t5)

	// Step 323: t4 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb0341b648
	fe_pow2k(&t4, &t4, 3)

	// Step 324: t4 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb0341b649
	fe_mul(&t4, &xx, &t4)

	// Step 331: t4 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db2480
	fe_pow2k(&t4, &t4, 7)

	// Step 332: t4 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b
	fe_mul(&t4, out1, &t4)

	// Step 339: t4 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d924580
	fe_pow2k(&t4, &t4, 7)

	// Step 340: t4 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d924585
	fe_mul(&t4, &t0, &t4)

	// Step 345: t4 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a0
	fe_pow2k(&t4, &t4, 5)

	// Step 346: t4 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a7
	fe_mul(&t4, &t2, &t4)

	// Step 351: t4 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb0341b6491614e0
	fe_pow2k(&t4, &t4, 5)

	// Step 352: t3 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb0341b6491614ef
	fe_mul(&t3, &t3, &t4)

	// Step 357: t3 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29de0
	fe_pow2k(&t3, &t3, 5)

	// Step 358: t3 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29deb
	fe_mul(&t3, out1, &t3)

	// Step 362: t3 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29deb0
	fe_pow2k(&t3, &t3, 4)

	// Step 363: t3 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb
	fe_mul(&t3, out1, &t3)

	// Step 368: t3 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd760
	fe_pow2k(&t3, &t3, 5)

	// Step 369: t2 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd767
	fe_mul(&t2, &t2, &t3)

	// Step 372: t2 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb38
	fe_pow2k(&t2, &t2, 3)

	// Step 373: t2 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb3b
	fe_mul(&t2, &t1, &t2)

	// Step 380: t2 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb0341b6491614ef5d9d80
	fe_pow2k(&t2, &t2, 7)

	// Step 381: t2 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb0341b6491614ef5d9d83
	fe_mul(&t2, &t1, &t2)

	// Step 387: t2 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760c0
	fe_pow2k(&t2, &t2, 6)

	// Step 388: t2 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760cb
	fe_mul(&t2, out1, &t2)

	// Step 392: t2 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760cb0
	fe_pow2k(&t2, &t2, 4)

	// Step 393: t2 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760cb5
	fe_mul(&t2, &t0, &t2)

	// Step 396: t2 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb3b065a8
	fe_pow2k(&t2, &t2, 3)

	// Step 397: t2 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb3b065ab
	fe_mul(&t2, &t1, &t2)

	// Step 401: t2 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb3b065ab0
	fe_pow2k(&t2, &t2, 4)

	// Step 402: t2 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb3b065ab3
	fe_mul(&t2, &t1, &t2)

	// Step 406: t2 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb3b065ab30
	fe_pow2k(&t2, &t2, 4)

	// Step 407: t1 = x^0x3ffffffffffffffffffffffffffffffffffffffffffffffff1d8d3607d0dcb77d606836c922c29debb3b065ab33
	fe_mul(&t1, &t1, &t2)

	// Step 413: t1 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc0
	fe_pow2k(&t1, &t1, 6)

	// Step 414: t1 = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc5
	fe_mul(&t1, &t0, &t1)

	// Step 419: t1 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb0341b6491614ef5d9d832d5998a0
	fe_pow2k(&t1, &t1, 5)

	// Step 420: t0 = x^0x1ffffffffffffffffffffffffffffffffffffffffffffffff8ec69b03e86e5bbeb0341b6491614ef5d9d832d5998a5
	fe_mul(&t0, &t0, &t1)

	// Step 426: t0 = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760cb56662940
	fe_pow2k(&t0, &t0, 6)

	// Step 427: z = x^0x7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760cb5666294b
	fe_mul(out1, out1, &t0)

	// Step 428: z = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc5296
	fe_square(out1, out1)

	// Step 429: z = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc5297
	fe_mul(out1, &xx, out1)

	// Step 433: z = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52970
	fe_pow2k(out1, out1, 4)

	// Step 434: z = x^0xffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52971
	fe_mul(out1, &xx, out1)

	fe_clear_vec([]^Montgomery_Domain_Field_Element{&t0, &t1, &t2, &t3, &t4, &t5, &t6, &t7, &t8, &t9, &xx})
}
