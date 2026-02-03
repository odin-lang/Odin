package field_scalarp384r1

import subtle "core:crypto/_subtle"
import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

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
		defer mem.zero_explicit(&tmp, size_of(tmp))
		defer mem.zero_explicit(&reduced, size_of(reduced))

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
		defer mem.zero_explicit(&src_512, size_of(src_512))

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
	defer mem.zero_explicit(&arg1_384, size_of(arg1_384))
	copy(arg1_384[48-len(arg1):], arg1)

	tmp: Non_Montgomery_Domain_Field_Element = ---
	fe_unchecked_set_saturated(&tmp, arg1_384[:])
	defer mem.zero_explicit(&tmp, size_of(tmp))

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

	mem.zero_explicit(&tmp, size_of(tmp))
}

fe_equal :: proc "contextless" (arg1, arg2: ^Montgomery_Domain_Field_Element) -> int {
	tmp: Montgomery_Domain_Field_Element = ---
	fe_sub(&tmp, arg1, arg2)

	is_eq := subtle.u64_is_zero(fe_non_zero(&tmp))

	fe_clear(&tmp)

	return int(is_eq)
}

fe_is_odd :: proc "contextless" (arg1: ^Montgomery_Domain_Field_Element) -> int {
	tmp: Non_Montgomery_Domain_Field_Element = ---
	defer mem.zero_explicit(&tmp, size_of(tmp))

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
