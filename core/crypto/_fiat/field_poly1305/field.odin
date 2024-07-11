package field_poly1305

import "base:intrinsics"
import "core:encoding/endian"
import "core:mem"

fe_relax_cast :: #force_inline proc "contextless" (
	arg1: ^Tight_Field_Element,
) -> ^Loose_Field_Element {
	return (^Loose_Field_Element)(arg1)
}

fe_tighten_cast :: #force_inline proc "contextless" (
	arg1: ^Loose_Field_Element,
) -> ^Tight_Field_Element {
	return (^Tight_Field_Element)(arg1)
}

fe_from_bytes :: #force_inline proc "contextless" (
	out1: ^Tight_Field_Element,
	arg1: []byte,
	arg2: byte,
) {
	// fiat-crypto's deserialization routine effectively processes a
	// single byte at a time, and wants 256-bits of input for a value
	// that will be 128-bits or 129-bits.
	//
	// This is somewhat cumbersome to use, so at a minimum a wrapper
	// makes implementing the actual MAC block processing considerably
	// neater.

	if len(arg1) != 16 {
		intrinsics.trap()
	}

	// While it may be unwise to do deserialization here on our
	// own when fiat-crypto provides equivalent functionality,
	// doing it this way provides a little under 3x performance
	// improvement when optimization is enabled.
	lo := endian.unchecked_get_u64le(arg1[0:])
	hi := endian.unchecked_get_u64le(arg1[8:])

	// This is inspired by poly1305-donna, though adjustments were
	// made since a Tight_Field_Element's limbs are 44-bits, 43-bits,
	// and 43-bits wide.
	//
	// Note: This could be transplated into fe_from_u64s, but that
	// code is called once per MAC, and is non-criticial path.
	hibit := u64(arg2) << 41 // arg2 << 128
	out1[0] = lo & 0xfffffffffff
	out1[1] = ((lo >> 44) | (hi << 20)) & 0x7ffffffffff
	out1[2] = ((hi >> 23) & 0x7ffffffffff) | hibit
}

fe_from_u64s :: proc "contextless" (out1: ^Tight_Field_Element, lo, hi: u64) {
	tmp: [32]byte
	endian.unchecked_put_u64le(tmp[0:], lo)
	endian.unchecked_put_u64le(tmp[8:], hi)

	_fe_from_bytes(out1, &tmp)

	// This routine is only used to deserialize `r` which is confidential.
	mem.zero_explicit(&tmp, size_of(tmp))
}

fe_zero :: proc "contextless" (out1: ^Tight_Field_Element) {
	out1[0] = 0
	out1[1] = 0
	out1[2] = 0
}

fe_set :: #force_inline proc "contextless" (out1, arg1: ^Tight_Field_Element) {
	x1 := arg1[0]
	x2 := arg1[1]
	x3 := arg1[2]
	out1[0] = x1
	out1[1] = x2
	out1[2] = x3
}

@(optimization_mode = "none")
fe_cond_swap :: #force_no_inline proc "contextless" (
	out1, out2: ^Tight_Field_Element,
	arg1: bool,
) {
	mask := (u64(arg1) * 0xffffffffffffffff)
	x := (out1[0] ~ out2[0]) & mask
	x1, y1 := out1[0] ~ x, out2[0] ~ x
	x = (out1[1] ~ out2[1]) & mask
	x2, y2 := out1[1] ~ x, out2[1] ~ x
	x = (out1[2] ~ out2[2]) & mask
	x3, y3 := out1[2] ~ x, out2[2] ~ x
	out1[0], out2[0] = x1, y1
	out1[1], out2[1] = x2, y2
	out1[2], out2[2] = x3, y3
}
