// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

// =============================================================================
// ADVANCED SIMD FIELDS READ FROM THE WHOLE WORD
// =============================================================================
//
// Some Advanced SIMD fields mean different things depending on the rest of the
// word -- which class the instruction is in, how many elements it moves, its
// element size. Each form pins all of that, so the meaning follows from the
// form's bits; the decoder reads it off the word and the encoder off the form.
// These are shared by both.

// The element and structure loads and stores, by bit 23 and the size field:
// several structures to or from whole registers, one to or from a lane, or one
// loaded into every lane.
Structure_Class :: enum u8 { MULTIPLE, ONE_LANE, ALL_LANES }

@(require_results)
structure_class :: #force_inline proc "contextless" (word: u32) -> Structure_Class {
	if word & (1 << 23) == 0 {
		return .MULTIPLE
	}
	if (word >> 10) & 0x3 == 0x3 {
		return .ALL_LANES
	}
	return .ONE_LANE
}

// The register list of an element or structure load or store.
Structure_List :: struct {
	count:  u8,     // registers in the list
	stride: u8,     // 1 for {d0, d1}, 2 for {d0, d2}
	lane:   u8,     // for ONE_LANE
}

@(require_results)
structure_list :: proc "contextless" (word: u32) -> (list: Structure_List) {
	list.stride = 1
	switch structure_class(word) {
	case .MULTIPLE:
		// The type field, bits 11-8, is the count and the spacing at once.
		switch (word >> 8) & 0xF {
		case 0x7:      list.count = 1
		case 0xA, 0x8: list.count = 2
		case 0x6, 0x4: list.count = 3
		case 0x2, 0x3: list.count = 4
		case 0x0:      list.count = 4
		case 0x9:      list.count, list.stride = 2, 2
		case 0x5:      list.count, list.stride = 3, 2
		case 0x1:      list.count, list.stride = 4, 2
		}
	case .ONE_LANE:
		list.count = u8((word >> 8) & 0x3) + 1
		index_align := (word >> 4) & 0xF
		switch (word >> 10) & 0x3 {
		case 0:
			list.lane = u8(index_align >> 1)
		case 1:
			list.lane = u8(index_align >> 2)
			if list.count > 1 { list.stride = u8((index_align >> 1) & 1) + 1 }
		case 2:
			list.lane = u8(index_align >> 3)
			if list.count > 1 { list.stride = u8((index_align >> 2) & 1) + 1 }
		}
	case .ALL_LANES:
		// T is a second register for VLD1, and the spacing for the rest.
		elements := u8((word >> 8) & 0x3) + 1
		t := u8((word >> 5) & 1)
		if elements == 1 {
			list.count = t + 1
		} else {
			list.count = elements
			list.stride = t + 1
		}
	}
	return
}

// The alignment an element or structure address names, as Memory.align holds
// it: 0 for none, else log2 of the bits less 3.
@(require_results)
structure_alignment :: proc "contextless" (word: u32) -> u8 {
	elements := (word >> 8) & 0x3 + 1
	switch structure_class(word) {
	case .MULTIPLE:
		// aa at bits 5-4: none, 64, 128, 256.
		aa := u8((word >> 4) & 0x3)
		return aa == 0 ? 0 : aa + 2
	case .ONE_LANE:
		size := u8((word >> 10) & 0x3)
		index_align := (word >> 4) & 0xF
		switch elements {
		case 1:
			// .16 aligns to 16 by bit 0; .32 to 32 by bits 1-0 = 11.
			if size == 1 && index_align & 1 != 0 { return 1 }
			if size == 2 && index_align & 3 == 3 { return 2 }
			return 0
		case 2:
			// Twice the element.
			return index_align & 1 != 0 ? size + 1 : 0
		case 3:
			return 0
		case 4:
			// .32 to 64 or 128 by bits 1-0; the rest to four elements by bit 0.
			if size == 2 {
				aa := u8(index_align & 3)
				return aa == 0 ? 0 : aa + 2
			}
			return index_align & 1 != 0 ? size + 2 : 0
		}
	case .ALL_LANES:
		if word & 0x10 == 0 {
			return 0
		}
		size := u8((word >> 6) & 0x3)
		switch elements {
		case 1: return size
		case 2: return size + 1
		case 3: return 0
		case 4:
			// Four elements' worth, except that .32 stops at 64, and size 11 is
			// a .32 aligned to 128.
			if size == 3 { return 4 }
			if size == 2 { return 3 }
			return size + 2
		}
	}
	return 0
}

// The element size a shift-by-immediate word's L:imm6 names: its leading one.
@(require_results)
shift_element_bits :: #force_inline proc "contextless" (word: u32) -> u32 {
	if word & (1 << 7) != 0  { return 64 }
	if word & (1 << 21) != 0 { return 32 }
	if word & (1 << 20) != 0 { return 16 }
	return 8
}

// L:imm6 as one seven-bit number.
@(require_results)
shift_field :: #force_inline proc "contextless" (word: u32) -> u32 {
	return ((word >> 7) & 1) << 6 | (word >> 16) & 0x3F
}
