package field_poly1305

import "core:crypto/util"
import "core:mem"

fe_relax_cast :: #force_inline proc "contextless" (arg1: ^Tight_Field_Element) -> ^Loose_Field_Element {
	return transmute(^Loose_Field_Element)(arg1)
}

fe_tighten_cast :: #force_inline proc "contextless" (arg1: ^Loose_Field_Element) -> ^Tight_Field_Element {
	return transmute(^Tight_Field_Element)(arg1)
}

fe_from_bytes :: proc (out1: ^Tight_Field_Element, arg1: []byte, arg2: byte, sanitize: bool = true) {
	// fiat-crypto's deserialization routine wants 256-bits of input, but
	// r/s are 128-bits long, and block processing works on 128-bits plus a
	// final bit.
	//
	// This is more ergonomic, and while the copy is unfortunate, this avoids
	// having to alter the fiat-crypto derived code.

	assert(len(arg1) == 16)

	tmp: [32]byte
	copy_slice(tmp[0:16], arg1[:])
	tmp[16] = arg2

	_fe_from_bytes(out1, &tmp)

	// Need to sanitize the temporary buffer when deserializing `s`.
	if sanitize {
		mem.zero_explicit(&tmp, size_of(tmp))
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
