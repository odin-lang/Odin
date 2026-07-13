// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

// LEB128 + little-endian primitives (shared by encoder and decoder)
// =============================================================================

// Unsigned LEB128. Advances `*offset`. Caller guarantees buffer space.
write_uleb :: #force_inline proc "contextless" (code: []u8, offset: ^u32, value: u64) {
	v := value
	for {
		b := u8(v & 0x7F)
		v >>= 7
		if v != 0 {
			b |= 0x80
		}
		code[offset^] = b
		offset^ += 1
		if v == 0 {
			break
		}
	}
}

// Signed LEB128. Advances `*offset`.
write_sleb :: #force_inline proc "contextless" (code: []u8, offset: ^u32, value: i64) {
	v := value
	for {
		b := u8(v & 0x7F)
		v >>= 7 // arithmetic shift on signed value sign-extends
		done := (v == 0 && (b & 0x40) == 0) || (v == -1 && (b & 0x40) != 0)
		if !done {
			b |= 0x80
		}
		code[offset^] = b
		offset^ += 1
		if done {
			break
		}
	}
}

// Fixed 5-byte unsigned LEB128 (relocatable placeholder for 32-bit indices).
write_uleb_padded5 :: #force_inline proc "contextless" (code: []u8, offset: ^u32, value: u64) {
	v := value
	for i := 0; i < 5 && offset^ < u32(len(code)); i += 1 {
		b := u8(v & 0x7F)
		v >>= 7
		if i != 4 {
			b |= 0x80
		}
		code[offset^] = b
		offset^ += 1
	}
}

@(require_results)
uleb_size :: #force_inline proc "contextless" (value: u64) -> u32 {
	v := value
	n: u32 = 1
	for /**/; v >= 0x80; n += 1 {
		v >>= 7
	}
	return n
}

@(require_results)
sleb_size :: #force_inline proc "contextless" (value: i64) -> u32 {
	v := value
	n := u32(0)
	for {
		b := u8(v & 0x7F)
		v >>= 7
		n += 1
		if (v == 0 && (b & 0x40) == 0) || (v == -1 && (b & 0x40) != 0) {
			break
		}
	}
	return n
}

// Read unsigned LEB128 starting at `*offset`; advances it. `ok` is false on
// truncation. Reads at most `max` bytes (10 covers u64).
@(require_results)
read_uleb :: #force_inline proc "contextless" (data: []u8, offset: ^u32) -> (value: u64, ok: bool) {
	shift := uint(0)
	for i := 0; i < 10 && offset^ < u32(len(data)); i += 1 {
		b := data[offset^]
		offset^ += 1
		value |= u64(b & 0x7F) << shift
		if b & 0x80 == 0 {
			return value, true
		}
		shift += 7
	}
	return 0, false
}

// Read signed LEB128 starting at `*offset`; advances it.
@(require_results)
read_sleb :: #force_inline proc "contextless" (data: []u8, offset: ^u32) -> (value: i64, ok: bool) {
	shift := uint(0)
	b     := u8(0)
	for i := 0; i < 10 && offset^ < u32(len(data)); i += 1 {
		b = data[offset^]
		offset^ += 1
		value |= i64(b & 0x7F) << shift
		shift += 7
		if b & 0x80 == 0 {
			break
		}
	}
	if shift < 64 && (b & 0x40) != 0 {
		value |= -(i64(1) << shift)
	}
	ok = true
	return
}

write_u32_block :: #force_inline proc(code: []u8, offset: ^u32, v: u32) {
	assert(offset^+4 <= u32(len(code)))
	code[offset^+0] = u8(v)
	code[offset^+1] = u8(v >> 8)
	code[offset^+2] = u8(v >> 16)
	code[offset^+3] = u8(v >> 24)
	offset^ += 4
}

write_u64_block :: #force_inline proc(code: []u8, offset: ^u32, v: u64) {
	assert(offset^+8 <= u32(len(code)))
	for i in u32(0)..<8 {
		code[offset^+i] = u8(v >> (8 * i))
	}
	offset^ += 8
}

@(require_results)
read_u32_block :: #force_inline proc "contextless" (data: []u8, offset: ^u32) -> (u32, bool) {
	if offset^+4 > u32(len(data)) {
		return 0, false
	}
	v := u32(data[offset^+0])     |
	     u32(data[offset^+1])<<8  |
	     u32(data[offset^+2])<<16 |
	     u32(data[offset^+3])<<24
	offset^ += 4
	return v, true
}

@(require_results)
read_u64_block :: #force_inline proc "contextless" (data: []u8, offset: ^u32) -> (u64, bool) {
	if offset^+8 > u32(len(data)) {
		return 0, false
	}
	v := u64(0)
	for i in u32(0)..<8 {
		v |= u64(data[offset^+i]) << (8 * i)
	}
	offset^ += 8
	return v, true
}
