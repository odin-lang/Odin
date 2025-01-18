package field_scalar25519

import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

@(private, rodata)
_TWO_168 := Montgomery_Domain_Field_Element {
	0x5b8ab432eac74798,
	0x38afddd6de59d5d7,
	0xa2c131b399411b7c,
	0x6329a7ed9ce5a30,
}
@(private, rodata)
_TWO_336 := Montgomery_Domain_Field_Element {
	0xbd3d108e2b35ecc5,
	0x5c3a3718bdf9c90b,
	0x63aa97a331b4f2ee,
	0x3d217f5be65cb5c,
}

fe_clear :: proc "contextless" (arg1: ^Montgomery_Domain_Field_Element) {
	mem.zero_explicit(arg1, size_of(Montgomery_Domain_Field_Element))
}

fe_from_bytes :: proc "contextless" (
	out1: ^Montgomery_Domain_Field_Element,
	arg1: ^[32]byte,
	unsafe_assume_canonical := false,
) -> bool {
	tmp := Non_Montgomery_Domain_Field_Element {
		endian.unchecked_get_u64le(arg1[0:]),
		endian.unchecked_get_u64le(arg1[8:]),
		endian.unchecked_get_u64le(arg1[16:]),
		endian.unchecked_get_u64le(arg1[24:]),
	}
	defer mem.zero_explicit(&tmp, size_of(tmp))

	// Check that tmp is in the the range [0, ELL).
	if !unsafe_assume_canonical {
		_, borrow := bits.sub_u64(ELL[0] - 1, tmp[0], 0)
		_, borrow = bits.sub_u64(ELL[1], tmp[1], borrow)
		_, borrow = bits.sub_u64(ELL[2], tmp[2], borrow)
		_, borrow = bits.sub_u64(ELL[3], tmp[3], borrow)
		if borrow != 0 {
			return false
		}
	}

	fe_to_montgomery(out1, &tmp)

	return true
}

fe_from_bytes_rfc8032 :: proc "contextless" (
	out1: ^Montgomery_Domain_Field_Element,
	arg1: ^[32]byte,
) {
	tmp: [64]byte
	copy(tmp[:], arg1[:])

	// Apply "clamping" as in RFC 8032.
	tmp[0] &= 248
	tmp[31] &= 127
	tmp[31] |= 64 // Sets the 254th bit, so the encoding is non-canonical.

	fe_from_bytes_wide(out1, &tmp)

	mem.zero_explicit(&tmp, size_of(tmp))
}

fe_from_bytes_wide :: proc "contextless" (
	out1: ^Montgomery_Domain_Field_Element,
	arg1: ^[64]byte,
) {
	tmp: Montgomery_Domain_Field_Element
	// Use Frank Denis' trick, as documented by Filippo Valsorda
	// at https://words.filippo.io/dispatches/wide-reduction/
	//
	// x = c * 2^336 + b * 2^168 + a  mod l
	_fe_from_bytes_short(out1, arg1[:21]) // a

	_fe_from_bytes_short(&tmp, arg1[21:42]) // b
	fe_mul(&tmp, &tmp, &_TWO_168) // b * 2^168
	fe_add(out1, out1, &tmp) // a + b * 2^168

	_fe_from_bytes_short(&tmp, arg1[42:]) // c
	fe_mul(&tmp, &tmp, &_TWO_336) // c * 2^336
	fe_add(out1, out1, &tmp) // a + b * 2^168 + c * 2^336

	fe_clear(&tmp)
}

@(private)
_fe_from_bytes_short :: proc "contextless" (out1: ^Montgomery_Domain_Field_Element, arg1: []byte) {
	// INVARIANT: len(arg1) < 32.
	ensure_contextless(len(arg1) < 32, "edwards25519: oversized short scalar")

	tmp: [32]byte
	copy(tmp[:], arg1)

	_ = fe_from_bytes(out1, &tmp, true)
	mem.zero_explicit(&tmp, size_of(tmp))
}

fe_to_bytes :: proc "contextless" (out1: []byte, arg1: ^Montgomery_Domain_Field_Element) {
	ensure_contextless(len(out1) == 32, "edwards25519: oversized scalar output buffer")

	tmp: Non_Montgomery_Domain_Field_Element
	fe_from_montgomery(&tmp, arg1)

	endian.unchecked_put_u64le(out1[0:], tmp[0])
	endian.unchecked_put_u64le(out1[8:], tmp[1])
	endian.unchecked_put_u64le(out1[16:], tmp[2])
	endian.unchecked_put_u64le(out1[24:], tmp[3])

	mem.zero_explicit(&tmp, size_of(tmp))
}

fe_equal :: proc "contextless" (arg1, arg2: ^Montgomery_Domain_Field_Element) -> int {
	tmp: Montgomery_Domain_Field_Element
	fe_sub(&tmp, arg1, arg2)

	// This will only underflow iff arg1 == arg2, and we return the borrow,
	// which will be 1.
	_, borrow := bits.sub_u64(fe_non_zero(&tmp), 1, 0)

	fe_clear(&tmp)

	return int(borrow)
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
