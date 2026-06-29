package field_scalarp256r1

import "core:crypto"
import subtle "core:crypto/_subtle"
import "core:encoding/endian"
import "core:math/bits"

@(private, rodata)
TWO_192 := Montgomery_Domain_Field_Element{
	2482910415990817935,
	2879494685571067143,
	8732918506673730078,
	85565669603516024,
}
@(private, rodata)
TWO_384 := Montgomery_Domain_Field_Element{
	2127524300190691059,
	17014302137236182484,
	16604910261202196099,
	3621421107472562910,
}
// 2^384 % p (From sage)
// 0x431905529c0166ce652e96b7ccca0a99679b73e19ad16947f01cf013fc632551

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
	ensure_contextless(len(out1) <= 64, "p256r1: invalid scalar input buffer")

	is_canonical := false
	s_len := len(arg1)
	switch {
	case s_len < 32:
		// No way this can be greater than the order.
		fe_unchecked_set(out1, arg1)
		is_canonical = true
	case s_len == 32:
		// It is quite likely that a reduction mod p is required,
		// as the order of the curve is sufficiently smaller than
		// 2^256-1, so just check if we actually needed to reduced
		// and do the reduction anyway, so that things that require
		// canonical scalars can reject non-canonical encodings.
		is_canonical = fe_is_canonical(arg1)
		fallthrough
	case:
		// Use Frank Denis' trick, as documented by Filippo Valsorda
		// at https://words.filippo.io/dispatches/wide-reduction/
		//
		// "I represent the value as a+b*2^192+c*2^384"
		//
		// Note: Omitting the `c` computation is fine as, reduction
		// being length dependent provides no useful timing information.

		// Zero extend to 512-bits.
		src_512: [64]byte
		copy(src_512[64-s_len:], arg1)
		defer crypto.zero_explicit(&src_512, size_of(src_512))

		fe_unchecked_set(out1, src_512[40:]) // a
		b: Montgomery_Domain_Field_Element
		fe_unchecked_set(&b, src_512[16:40]) // b

		fe_mul(&b, &b, &TWO_192)
		fe_add(out1, out1, &b)
		if s_len >= 48 {
			c: Montgomery_Domain_Field_Element
			fe_unchecked_set(&c, src_512[:16]) // c
			fe_mul(&c, &c, &TWO_384)
			fe_add(out1, out1, &c)

			fe_clear(&c)
		}

		fe_clear(&b)
	}

	return !is_canonical
}

@(private)
fe_is_canonical :: proc "contextless" (arg1: []byte) -> bool {
	_, borrow := bits.sub_u64(ELL[0] - 1, endian.unchecked_get_u64be(arg1[24:]), 0)
	_, borrow = bits.sub_u64(ELL[1], endian.unchecked_get_u64be(arg1[16:]), borrow)
	_, borrow = bits.sub_u64(ELL[2], endian.unchecked_get_u64be(arg1[8:]), borrow)
	_, borrow = bits.sub_u64(ELL[3], endian.unchecked_get_u64be(arg1[0:]), borrow)
	return borrow == 0
}

@(private)
fe_unchecked_set :: proc "contextless" (out1: ^Montgomery_Domain_Field_Element, arg1: []byte) {
	arg1_256: [32]byte
	defer crypto.zero_explicit(&arg1_256, size_of(arg1_256))
	copy(arg1_256[32-len(arg1):], arg1)

	tmp := Non_Montgomery_Domain_Field_Element {
		endian.unchecked_get_u64be(arg1_256[24:]),
		endian.unchecked_get_u64be(arg1_256[16:]),
		endian.unchecked_get_u64be(arg1_256[8:]),
		endian.unchecked_get_u64be(arg1_256[0:]),
	}
	defer crypto.zero_explicit(&tmp, size_of(tmp))

	fe_to_montgomery(out1, &tmp)
}

fe_to_bytes :: proc "contextless" (out1: []byte, arg1: ^Montgomery_Domain_Field_Element) {
	ensure_contextless(len(out1) == 32, "p256r1: invalid scalar output buffer")

	tmp: Non_Montgomery_Domain_Field_Element = ---
	fe_from_montgomery(&tmp, arg1)

	// Note: Likewise, output in big-endian.
	endian.unchecked_put_u64be(out1[24:], tmp[0])
	endian.unchecked_put_u64be(out1[16:], tmp[1])
	endian.unchecked_put_u64be(out1[8:], tmp[2])
	endian.unchecked_put_u64be(out1[0:], tmp[3])

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
}

fe_set :: proc "contextless" (out1, arg1: ^Montgomery_Domain_Field_Element) {
	x1 := arg1[0]
	x2 := arg1[1]
	x3 := arg1[2]
	x4 := arg1[3]
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
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
	out1[0], out2[0] = x1, y1
	out1[1], out2[1] = x2, y2
	out1[2], out2[2] = x3, y3
	out1[3], out2[3] = x4, y4
}

@(optimization_mode = "none")
fe_cond_select :: #force_no_inline proc "contextless" (
	out1, arg1, arg2: ^Montgomery_Domain_Field_Element,
	arg3: int,
) {
	mask := (u64(arg3) * 0xffffffffffffffff)
	x1 := ((mask & arg2[0]) | ((~mask) & arg1[0]))
	x2 := ((mask & arg2[1]) | ((~mask) & arg1[1]))
	x3 := ((mask & arg2[2]) | ((~mask) & arg1[2]))
	x4 := ((mask & arg2[3]) | ((~mask) & arg1[3]))
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
	out1[3] = x4
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
	//	_10       = 2*1
	//	_100      = 2*_10
	//	_101      = 1 + _100
	//	_110      = 1 + _101
	//	_1001     = _100 + _101
	//	_1111     = _110 + _1001
	//	_10010    = 2*_1001
	//	_10101    = _110 + _1111
	//	_11000    = _110 + _10010
	//	_11010    = _10 + _11000
	//	_101111   = _10101 + _11010
	//	_111000   = _1001 + _101111
	//	_111101   = _101 + _111000
	//	_111111   = _10 + _111101
	//	_1001111  = _10010 + _111101
	//	_1100001  = _10010 + _1001111
	//	_1100011  = _10 + _1100001
	//	_1110011  = _10010 + _1100001
	//	_1110111  = _100 + _1110011
	//	_1111101  = _110 + _1110111
	//	_10010101 = _11000 + _1111101
	//	_10100111 = _10010 + _10010101
	//	_10101101 = _110 + _10100111
	//	_11100101 = _111000 + _10101101
	//	_11111111 = _11010 + _11100101
	//	x16       = _11111111 << 8 + _11111111
	//	x32       = x16 << 16 + x16
	//	i133      = ((x32 << 48 + x16) << 16 + x16) << 16
	//	i158      = ((x16 + i133) << 16 + x16) << 6 + _101111
	//	i186      = ((i158 << 9 + _1110011) << 8 + _1111101) << 9
	//	i206      = ((_10101101 + i186) << 8 + _10100111) << 9 + _101111
	//	i236      = ((i206 << 8 + _111101) << 11 + _1001111) << 9
	//	i257      = ((_1110111 + i236) << 10 + _11100101) << 8 + _1100001
	//	i286      = ((i257 << 7 + _111111) << 10 + _1100011) << 10
	//	return      (_10010101 + i286) << 6 + _1111
	//
	// Operations: 251 squares 43 multiplies
	//
	// Generated by github.com/mmcloughlin/addchain v0.4.0.

	// Note: Need to stash `arg1` (`xx`) in the case that `out1`/`arg1` alias,
	// as `arg1` is used after `out1` has been altered.
	t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, xx: Montgomery_Domain_Field_Element = ---, ---, ---, ---, ---, ---, ---, ---, ---, ---, ---, ---, ---, ---, ---, arg1^

	// Step 1: t1 = x^0x2
	fe_square(&t1, arg1)

	// Step 2: t5 = x^0x4
	fe_square(&t5, &t1)

	// Step 3: t2 = x^0x5
	fe_mul(&t2, arg1, &t5)

	// Step 4: t10 = x^0x6
	fe_mul(&t10, arg1, &t2)

	// Step 5: t3 = x^0x9
	fe_mul(&t3, &t5, &t2)

	// Step 6: z = x^0xf
	fe_mul(out1, &t10, &t3)

	// Step 7: t9 = x^0x12
	fe_square(&t9, &t3)

	// Step 8: t4 = x^0x15
	fe_mul(&t4, &t10, out1)

	// Step 9: t0 = x^0x18
	fe_mul(&t0, &t10, &t9)

	// Step 10: t13 = x^0x1a
	fe_mul(&t13, &t1, &t0)

	// Step 11: t8 = x^0x2f
	fe_mul(&t8, &t4, &t13)

	// Step 12: t4 = x^0x38
	fe_mul(&t4, &t3, &t8)

	// Step 13: t7 = x^0x3d
	fe_mul(&t7, &t2, &t4)

	// Step 14: t2 = x^0x3f
	fe_mul(&t2, &t1, &t7)

	// Step 15: t6 = x^0x4f
	fe_mul(&t6, &t9, &t7)

	// Step 16: t3 = x^0x61
	fe_mul(&t3, &t9, &t6)

	// Step 17: t1 = x^0x63
	fe_mul(&t1, &t1, &t3)

	// Step 18: t12 = x^0x73
	fe_mul(&t12, &t9, &t3)

	// Step 19: t5 = x^0x77
	fe_mul(&t5, &t5, &t12)

	// Step 20: t11 = x^0x7d
	fe_mul(&t11, &t10, &t5)

	// Step 21: t0 = x^0x95
	fe_mul(&t0, &t0, &t11)

	// Step 22: t9 = x^0xa7
	fe_mul(&t9, &t9, &t0)

	// Step 23: t10 = x^0xad
	fe_mul(&t10, &t10, &t9)

	// Step 24: t4 = x^0xe5
	fe_mul(&t4, &t4, &t10)

	// Step 25: t13 = x^0xff
	fe_mul(&t13, &t13, &t4)

	// Step 33: t14 = x^0xff00
	fe_pow2k(&t14, &t13, 8)

	// Step 34: t13 = x^0xffff
	fe_mul(&t13, &t13, &t14)

	// Step 50: t14 = x^0xffff0000
	fe_pow2k(&t14, &t13, 16)

	// Step 51: t14 = x^0xffffffff
	fe_mul(&t14, &t13, &t14)

	// Step 99: t14 = x^0xffffffff000000000000
	fe_pow2k(&t14, &t14, 48)

	// Step 100: t14 = x^0xffffffff00000000ffff
	fe_mul(&t14, &t13, &t14)

	// Step 116: t14 = x^0xffffffff00000000ffff0000
	fe_pow2k(&t14, &t14, 16)

	// Step 117: t14 = x^0xffffffff00000000ffffffff
	fe_mul(&t14, &t13, &t14)

	// Step 133: t14 = x^0xffffffff00000000ffffffff0000
	fe_pow2k(&t14, &t14, 16)

	// Step 134: t14 = x^0xffffffff00000000ffffffffffff
	fe_mul(&t14, &t13, &t14)

	// Step 150: t14 = x^0xffffffff00000000ffffffffffff0000
	fe_pow2k(&t14, &t14, 16)

	// Step 151: t13 = x^0xffffffff00000000ffffffffffffffff
	fe_mul(&t13, &t13, &t14)

	// Step 157: t13 = x^0x3fffffffc00000003fffffffffffffffc0
	fe_pow2k(&t13, &t13, 6)

	// Step 158: t13 = x^0x3fffffffc00000003fffffffffffffffef
	fe_mul(&t13, &t8, &t13)

	// Step 167: t13 = x^0x7fffffff800000007fffffffffffffffde00
	fe_pow2k(&t13, &t13, 9)

	// Step 168: t12 = x^0x7fffffff800000007fffffffffffffffde73
	fe_mul(&t12, &t12, &t13)

	// Step 176: t12 = x^0x7fffffff800000007fffffffffffffffde7300
	fe_pow2k(&t12, &t12, 8)

	// Step 177: t11 = x^0x7fffffff800000007fffffffffffffffde737d
	fe_mul(&t11, &t11, &t12)

	// Step 186: t11 = x^0xffffffff00000000ffffffffffffffffbce6fa00
	fe_pow2k(&t11, &t11, 9)

	// Step 187: t10 = x^0xffffffff00000000ffffffffffffffffbce6faad
	fe_mul(&t10, &t10, &t11)

	// Step 195: t10 = x^0xffffffff00000000ffffffffffffffffbce6faad00
	fe_pow2k(&t10, &t10, 8)

	// Step 196: t9 = x^0xffffffff00000000ffffffffffffffffbce6faada7
	fe_mul(&t9, &t9, &t10)

	// Step 205: t9 = x^0x1fffffffe00000001ffffffffffffffff79cdf55b4e00
	fe_pow2k(&t9, &t9, 9)

	// Step 206: t8 = x^0x1fffffffe00000001ffffffffffffffff79cdf55b4e2f
	fe_mul(&t8, &t8, &t9)

	// Step 214: t8 = x^0x1fffffffe00000001ffffffffffffffff79cdf55b4e2f00
	fe_pow2k(&t8, &t8, 8)

	// Step 215: t7 = x^0x1fffffffe00000001ffffffffffffffff79cdf55b4e2f3d
	fe_mul(&t7, &t7, &t8)

	// Step 226: t7 = x^0xffffffff00000000ffffffffffffffffbce6faada7179e800
	fe_pow2k(&t7, &t7, 11)

	// Step 227: t6 = x^0xffffffff00000000ffffffffffffffffbce6faada7179e84f
	fe_mul(&t6, &t6, &t7)

	// Step 236: t6 = x^0x1fffffffe00000001ffffffffffffffff79cdf55b4e2f3d09e00
	fe_pow2k(&t6, &t6, 9)

	// Step 237: t5 = x^0x1fffffffe00000001ffffffffffffffff79cdf55b4e2f3d09e77
	fe_mul(&t5, &t5, &t6)

	// Step 247: t5 = x^0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dc00
	fe_pow2k(&t5, &t5, 10)

	// Step 248: t4 = x^0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5
	fe_mul(&t4, &t4, &t5)

	// Step 256: t4 = x^0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dce500
	fe_pow2k(&t4, &t4, 8)

	// Step 257: t3 = x^0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dce561
	fe_mul(&t3, &t3, &t4)

	// Step 264: t3 = x^0x3fffffffc00000003fffffffffffffffef39beab69c5e7a13cee72b080
	fe_pow2k(&t3, &t3, 7)

	// Step 265: t2 = x^0x3fffffffc00000003fffffffffffffffef39beab69c5e7a13cee72b0bf
	fe_mul(&t2, &t2, &t3)

	// Step 275: t2 = x^0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc00
	fe_pow2k(&t2, &t2, 10)

	// Step 276: t1 = x^0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc63
	fe_mul(&t1, &t1, &t2)

	// Step 286: t1 = x^0x3fffffffc00000003fffffffffffffffef39beab69c5e7a13cee72b0bf18c00
	fe_pow2k(&t1, &t1, 10)

	// Step 287: t0 = x^0x3fffffffc00000003fffffffffffffffef39beab69c5e7a13cee72b0bf18c95
	fe_mul(&t0, &t0, &t1)

	// Step 293: t0 = x^0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632540
	fe_pow2k(&t0, &t0, 6)

	// Step 294: z = x^0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc63254f
	fe_mul(out1, out1, &t0)

	fe_clear_vec([]^Montgomery_Domain_Field_Element{&t0, &t1, &t2, &t3, &t4, &t5, &t6, &t7, &t8, &t9, &t10, &t11, &t12, &t13, &t14, &xx})
}
