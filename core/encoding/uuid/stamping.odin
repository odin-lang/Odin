package uuid

import "base:runtime"

/*
Stamp a 128-bit integer as being a valid version 8 UUID.

Per the specification, all version 8 UUIDs are either for experimental or
vendor-specific purposes. This procedure allows for converting arbitrary data
into custom UUIDs.

Inputs:
- integer: Any integer type.

Returns:
- result: A valid version 8 UUID.
*/
stamp_v8_int :: proc(#any_int integer: u128) -> (result: Identifier) {
	result = transmute(Identifier)cast(u128be)integer

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x80

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Stamp an array of 16 bytes as being a valid version 8 UUID.

Per the specification, all version 8 UUIDs are either for experimental or
vendor-specific purposes. This procedure allows for converting arbitrary data
into custom UUIDs.

Inputs:
- array: An array of 16 bytes.

Returns:
- result: A valid version 8 UUID.
*/
stamp_v8_array :: proc(array: [16]u8) -> (result: Identifier) {
	result = Identifier(array)

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x80

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Stamp a slice of bytes as being a valid version 8 UUID.

If the slice is less than 16 bytes long, the data available will be used.
If it is longer than 16 bytes, only the first 16 will be used.

This procedure does not modify the underlying slice.

Per the specification, all version 8 UUIDs are either for experimental or
vendor-specific purposes. This procedure allows for converting arbitrary data
into custom UUIDs.

Inputs:
- slice: A slice of bytes.

Returns:
- result: A valid version 8 UUID.
*/
stamp_v8_slice :: proc(slice: []u8) -> (result: Identifier) {
	runtime.mem_copy_non_overlapping(&result, &slice[0], min(16, len(slice)))

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x80

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

stamp_v8 :: proc {
	stamp_v8_int,
	stamp_v8_array,
	stamp_v8_slice,
}
