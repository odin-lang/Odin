package field_scalarp256r1

import subtle "core:crypto/_subtle"
import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

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
	mem.zero_explicit(arg1, size_of(Montgomery_Domain_Field_Element))
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
		defer mem.zero_explicit(&src_512, size_of(src_512))

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
	defer mem.zero_explicit(&arg1_256, size_of(arg1_256))
	copy(arg1_256[32-len(arg1):], arg1)

	tmp := Non_Montgomery_Domain_Field_Element {
		endian.unchecked_get_u64be(arg1_256[24:]),
		endian.unchecked_get_u64be(arg1_256[16:]),
		endian.unchecked_get_u64be(arg1_256[8:]),
		endian.unchecked_get_u64be(arg1_256[0:]),
	}
	defer mem.zero_explicit(&tmp, size_of(tmp))

	fe_to_montgomery(out1, &tmp)
}

fe_to_bytes :: proc "contextless" (out1: []byte, arg1: ^Montgomery_Domain_Field_Element) {
	ensure_contextless(len(out1) == 32, "p256r1: invalid scalar output buffer")

	tmp: Non_Montgomery_Domain_Field_Element
	fe_from_montgomery(&tmp, arg1)

	// Note: Likewise, output in big-endian.
	endian.unchecked_put_u64be(out1[24:], tmp[0])
	endian.unchecked_put_u64be(out1[16:], tmp[1])
	endian.unchecked_put_u64be(out1[8:], tmp[2])
	endian.unchecked_put_u64be(out1[0:], tmp[3])

	mem.zero_explicit(&tmp, size_of(tmp))
}

fe_equal :: proc "contextless" (arg1, arg2: ^Montgomery_Domain_Field_Element) -> int {
	tmp: Montgomery_Domain_Field_Element
	fe_sub(&tmp, arg1, arg2)

	is_eq := subtle.u64_is_zero(fe_non_zero(&tmp))

	fe_clear(&tmp)

	return int(is_eq)
}

fe_is_odd :: proc "contextless" (arg1: ^Montgomery_Domain_Field_Element) -> int {
	tmp: Non_Montgomery_Domain_Field_Element
	defer mem.zero_explicit(&tmp, size_of(tmp))

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
