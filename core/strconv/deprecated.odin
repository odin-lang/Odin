package strconv

// (2025-06-05) These procedures are to be removed at a later release.

@(deprecated="Use write_bits instead")
append_bits :: proc(buf: []byte, x: u64, base: int, is_signed: bool, bit_size: int, digits: string, flags: Int_Flags) -> string {
	return write_bits(buf, x, base, is_signed, bit_size, digits, flags)
}

@(deprecated="Use write_bits_128 instead")
append_bits_128 :: proc(buf: []byte, x: u128, base: int, is_signed: bool, bit_size: int, digits: string, flags: Int_Flags) -> string {
	return write_bits_128(buf, x, base, is_signed, bit_size, digits, flags)
}

@(deprecated="Use write_bool instead")
append_bool :: proc(buf: []byte, b: bool) -> string {
	return write_bool(buf, b)
}

@(deprecated="Use write_uint instead")
append_uint :: proc(buf: []byte, u: u64, base: int) -> string {
	return write_uint(buf, u, base)
}

@(deprecated="Use write_int instead")
append_int :: proc(buf: []byte, i: i64, base: int) -> string {
	return write_int(buf, i, base)
}

@(deprecated="Use write_u128 instead")
append_u128 :: proc(buf: []byte, u: u128, base: int) -> string {
	return write_u128(buf, u, base)
}

@(deprecated="Use write_float instead")
append_float :: proc(buf: []byte, f: f64, fmt: byte, prec, bit_size: int) -> string {
	return write_float(buf, f, fmt, prec, bit_size)
}
