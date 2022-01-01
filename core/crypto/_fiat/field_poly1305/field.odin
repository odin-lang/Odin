package field_poly1305

import "core:crypto/util"
import "core:mem"

fe_relax_cast :: #force_inline proc "contextless" (arg1: ^Tight_Field_Element) -> ^Loose_Field_Element {
	return transmute(^Loose_Field_Element)(arg1)
}

fe_tighten_cast :: #force_inline proc "contextless" (arg1: ^Loose_Field_Element) -> ^Tight_Field_Element {
	return transmute(^Tight_Field_Element)(arg1)
}

fe_from_bytes :: #force_inline proc (out1: ^Tight_Field_Element, arg1: []byte, arg2: byte, sanitize: bool = true) {
	// fiat-crypto's deserialization routine effectively processes a
	// single byte at a time, and wants 256-bits of input for a value
	// that will be 128-bits or 129-bits.
	//
	// This is somewhat cumbersome to use, so at a minimum a wrapper
	// makes implementing the actual MAC block processing considerably
	// neater.

	assert(len(arg1) == 16)

	when ODIN_ARCH == "386" || ODIN_ARCH == "amd64" {
		// While it may be unwise to do deserialization here on our
		// own when fiat-crypto provides equivalent functionality,
		// doing it this way provides a little under 3x performance
		// improvement when optimization is enabled.
		src_p := transmute(^[2]u64)(&arg1[0])
		lo := src_p[0]
		hi := src_p[1]

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
	} else {
		tmp: [32]byte
		copy_slice(tmp[0:16], arg1[:])
		tmp[16] = arg2

		_fe_from_bytes(out1, &tmp)
		if sanitize {
			// This is used to deserialize `s` which is confidential.
			mem.zero_explicit(&tmp, size_of(tmp))
		}
	}
}

fe_from_u64s :: proc "contextless" (out1: ^Tight_Field_Element, lo, hi: u64) {
	tmp: [32]byte
	util.PUT_U64_LE(tmp[0:8], lo)
	util.PUT_U64_LE(tmp[8:16], hi)

	_fe_from_bytes(out1, &tmp)

	// This routine is only used to deserialize `r` which is confidential.
	mem.zero_explicit(&tmp, size_of(tmp))
}
