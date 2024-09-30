package deoxysii

import "core:encoding/endian"

@(private = "file")
TWEAK_SIZE :: 16

@(private = "file")
encode_tag_tweak :: #force_inline proc "contextless" (
	dst: ^[TWEAK_SIZE]byte,
	prefix: byte,
	block_nr: int,
) {
	endian.unchecked_put_u64be(dst[8:], u64(block_nr))
	dst[0] = prefix << PREFIX_SHIFT
}

@(private = "file")
encode_enc_tweak :: #force_inline proc "contextless" (
	dst: ^[TWEAK_SIZE]byte,
	tag: ^[TAG_SIZE]byte,
	block_nr: int,
) {
	tmp: [8]byte
	endian.unchecked_put_u64be(dst[:], u64(block_nr))

	copy(dst[:], tag[:])
	dst[0] |= 0x80
	for i in 8 ..< 16 {
		dst[i] ~= tmp[i]
	}
}