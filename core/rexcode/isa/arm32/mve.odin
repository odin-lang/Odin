// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

// =============================================================================
// MVE FIELDS READ FROM THE WHOLE WORD
// =============================================================================
//
// As for Advanced SIMD (simd.odin): fields whose meaning follows from the rest
// of the word. The decoder reads them off the word and the encoder off the
// form's bits; these are shared by both.

// How far a contiguous load or store's 7-bit offset steps: by the element
// size at bits 8-7. Size 11 with bit 12 clear is VLDR and VSTR of a system
// register, which step by words.
@(require_results)
mve_address_scale :: #force_inline proc "contextless" (word: u32) -> i32 {
	size := (word >> 7) & 0x3
	if word & (1 << 12) == 0 && size == 0x3 {
		return 4
	}
	return 1 << size
}

// A widening load or narrowing store steps by the memory element: a byte, or
// a halfword where bit 19 is set.
@(require_results)
mve_wide_scale :: #force_inline proc "contextless" (word: u32) -> i32 {
	return word & (1 << 19) != 0 ? 2 : 1
}

// A gather or scatter from a vector of addresses steps by words, or by
// doublewords where bit 8 is set.
@(require_results)
mve_vector_scale :: #force_inline proc "contextless" (word: u32) -> i32 {
	return word & (1 << 8) != 0 ? 8 : 4
}

// The shift a scaled vector offset takes: log2 of the memory element, which
// bits 6 and 4 hold.
@(require_results)
mve_offset_shift :: #force_inline proc "contextless" (word: u32) -> u8 {
	return u8(((word >> 6) & 1) << 1 | (word >> 4) & 1)
}

// The indexing of an MVE address, by P (bit 24) and W (bit 21).
@(require_results)
mve_index_mode :: #force_inline proc "contextless" (word: u32) -> Index_Mode {
	if word & (1 << 24) == 0 {
		return .POST_INDEX
	}
	return word & (1 << 21) != 0 ? .PRE_INDEX : .OFFSET
}

// The element size a lane move names: bit 22 marks a byte, bit 5 a halfword.
@(require_results)
mve_lane_bits :: #force_inline proc "contextless" (word: u32) -> u32 {
	if word & (1 << 22) != 0 { return 8 }
	if word & (1 << 5) != 0  { return 16 }
	return 32
}

// The lane a lane move names, from the bits its element size uses: 16, then
// 21, then 6 and 5 for the smaller elements.
@(require_results)
mve_lane :: proc "contextless" (word: u32) -> u8 {
	lane := ((word >> 16) & 1) << 1 | (word >> 21) & 1
	switch mve_lane_bits(word) {
	case 8:  lane = lane << 2 | (word >> 5) & 0x3
	case 16: lane = lane << 1 | (word >> 6) & 1
	}
	return u8(lane)
}

// The inverse: the bits that hold `lane` for a lane move of `size` bits.
@(require_results)
mve_lane_field :: proc "contextless" (lane: u32, size: u32) -> u32 {
	switch size {
	case 8:  return (lane >> 3) << 16 | ((lane >> 2) & 1) << 21 | (lane & 0x3) << 5
	case 16: return (lane >> 2) << 16 | ((lane >> 1) & 1) << 21 | (lane & 1) << 6
	}
	return (lane >> 1) << 16 | (lane & 1) << 21
}

// VCMP and VPT's three condition bits, fc, and the conditions they name.
@(rodata)
MVE_CONDITIONS := [8]u8{0, 2, 1, 8, 10, 12, 11, 13}    // eq cs ne hi ge gt lt le

@(require_results)
mve_condition_field :: proc "contextless" (condition: u8) -> (fc: u32, ok: bool) {
	for c, k in MVE_CONDITIONS {
		if c == condition {
			return u32(k), true
		}
	}
	return 0, false
}

// The element size a shift's leading one names: the top set bit of imm6 at
// 21-16 (MVE_SHIFT_RIGHT and MVE_SHIFT_LEFT) or of imm5 at 20-16
// (MVE_SHIFT_LONG).
@(require_results)
mve_shift_element_bits :: #force_inline proc "contextless" (word: u32, long: bool) -> u32 {
	if !long && word & (1 << 21) != 0 { return 32 }
	if word & (1 << 20) != 0 { return 16 }
	return 8
}

// The instructions a VPT mask predicates: as many as it says, the first
// THEN, and below its top bit each bit says whether the next instruction is
// predicated the other way from the one before.
@(private)
VPT_Block :: struct {
	predicates: [4]Vector_Predicate,
	count:      int,
}

@(private)
vpt_block_of :: proc "contextless" (mask: u8) -> (block: VPT_Block) {
	mask := mask & 0xF
	if mask == 0 {
		return
	}
	block.predicates[0] = .THEN
	block.count = 1
	then := true
	for bit := u8(3); bit > 0 && mask & ((1 << bit) - 1) != 0; bit -= 1 {
		if (mask >> bit) & 1 != 0 {
			then = !then
		}
		block.predicates[block.count] = then ? .THEN : .ELSE
		block.count += 1
	}
	return
}
