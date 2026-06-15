// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

// =============================================================================
// AArch64 BITMASK IMMEDIATE encoder
// =============================================================================
//
// The AArch64 logical-immediate encoding (AND/ORR/EOR/ANDS imm) packs a
// repeating bitmask pattern into a 13-bit N:immr:imms field:
//
//   N (1 bit)    at bit 22
//   immr (6 bit) at bits 21:16 -- right rotation amount within the element
//   imms (6 bit) at bits 15:10 -- element size encoding + ones count
//
// imms[5:0] encodes element size by leading-ones from MSB:
//
//   N=1, imms = SSSSSS         -> element size 64, S = ones - 1 (1..62)
//   N=0, imms = 0SSSSS         -> element size 32, S = ones - 1 (1..30)
//   N=0, imms = 10SSSS         -> element size 16, S = ones - 1 (1..14)
//   N=0, imms = 110SSS         -> element size  8, S = ones - 1 (1..6)
//   N=0, imms = 1110SS         -> element size  4, S = ones - 1 (1..2)
//   N=0, imms = 11110S         -> element size  2, S = ones - 1 (1..1 = always 0)
//
// The encoder API:
//
//   encode_bitmask_imm(value, is_64) -> (n, immr, imms, ok)
//     Returns the three fields packed as a 13-bit value via
//     `pack_bitmask_fields(n, immr, imms)` if you want the form used by
//     the table-driven BITMASK_FIELD packer. The full mnemonic builders
//     (`inst_and_imm` etc.) do the pre-encoding for you.
//
// Algorithm:
//   1. Reject 0 and all-ones (within the target width).
//   2. Find the smallest power-of-2 element size such that the value
//      is a repetition of an `e`-bit pattern (`e` in {2,4,8,16,32,64}).
//   3. Within the element, the ones must be a contiguous run after some
//      right-rotation. Find that rotation `r` and the ones count.
//   4. Compose N:immr:imms.

@(private="file")
S_BITS :: [7]u8{0, 0, 1, 0, 2, 0, 3}  // dummy; replaced by inline switch

@(private="file")
rotate_right_u64 :: #force_inline proc "contextless" (v: u64, r: u32, width: u32) -> u64 {
	if r == 0 { return v }
	mask: u64 = width == 64 ? ~u64(0) : (u64(1) << width) - 1
	vw := v & mask
	return ((vw >> r) | (vw << (width - r))) & mask
}

// is_valid_bitmask_imm returns true if `value` is a valid AArch64 logical-
// immediate when interpreted at the given width.
is_valid_bitmask_imm :: proc "contextless" (value: u64, is_64: bool) -> bool {
	_, _, _, ok := encode_bitmask_imm(value, is_64)
	return ok
}

// encode_bitmask_imm runs the bitmask-immediate algorithm and returns the
// three component fields (N, immr, imms) along with a success flag.
encode_bitmask_imm :: proc "contextless" (value: u64, is_64: bool) -> (n: u8, immr: u8, imms: u8, ok: bool) {
	width: u32 = is_64 ? 64 : 32
	v := value
	if !is_64 { v &= 0xFFFFFFFF }

	// Reject all-zero or all-ones for the target width.
	if v == 0 { return 0, 0, 0, false }
	all_ones: u64 = width == 64 ? ~u64(0) : (u64(1) << width) - 1
	if v == all_ones { return 0, 0, 0, false }

	// Find element size: smallest power-of-2 element size in {2..width}
	// for which v repeats. We start at 2 and double; the value is a valid
	// repetition for size `e` if every `e`-bit chunk is equal to the first.
	elem_size: u32 = 2
	for elem_size < width {
		emask: u64 = (u64(1) << elem_size) - 1
		first := v & emask
		is_repetition := true
		for shift: u32 = elem_size; shift < width; shift += elem_size {
			if ((v >> shift) & emask) != first {
				is_repetition = false
				break
			}
		}
		if is_repetition { break }
		elem_size *= 2
	}
	// elem_size now equals the smallest valid element size (could be width).

	elem_mask: u64 = elem_size == 64 ? ~u64(0) : (u64(1) << elem_size) - 1
	elem := v & elem_mask

	// The pattern must be a contiguous run of ones after some right-rotation.
	// Try every rotation 0..elem_size-1; check if result is (2^k - 1).
	ones:     u32 = 0
	rotation: u32 = 0
	found := false
	for r: u32 = 0; r < elem_size; r += 1 {
		rotated := rotate_right_u64(elem, r, elem_size)
		// count trailing ones
		k: u32 = 0
		x := rotated
		for k < elem_size && (x & 1) == 1 {
			k += 1
			x >>= 1
		}
		// The rest of the rotated word must be zero, and k must be in [1, elem_size-1].
		if k > 0 && k < elem_size && x == 0 {
			ones = k
			rotation = r
			found = true
			break
		}
	}
	if !found { return 0, 0, 0, false }

	// 32-bit operations require N = 0 (an N=1 form encodes a 64-bit-only
	// pattern). Since elem_size <= width <= 32 in 32-bit mode, this is
	// already implied (only the elem=64 branch sets N=1).
	n_bit: u8 = 0
	imms_top: u8 = 0
	s_mask: u8 = 0
	switch elem_size {
	case 2:  imms_top = 0b111100; s_mask = 0b000001
	case 4:  imms_top = 0b111000; s_mask = 0b000011
	case 8:  imms_top = 0b110000; s_mask = 0b000111
	case 16: imms_top = 0b100000; s_mask = 0b001111
	case 32: imms_top = 0b000000; s_mask = 0b011111
	case 64: imms_top = 0b000000; s_mask = 0b111111; n_bit = 1
	case:
		return 0, 0, 0, false
	}
	s_val := u8(ones - 1) & s_mask
	imms_field := imms_top | s_val
	immr_field := u8(rotation) & 0x3F

	return n_bit, immr_field, imms_field, true
}

// pack_bitmask_fields packs N:immr:imms into the 13-bit BITMASK_FIELD
// operand-immediate format consumed by the encoder packer.
pack_bitmask_fields :: #force_inline proc "contextless" (n, immr, imms: u8) -> i64 {
	return i64((u32(n & 1) << 12) | (u32(immr & 0x3F) << 6) | u32(imms & 0x3F))
}

// unpack_bitmask_fields inverts pack_bitmask_fields.
unpack_bitmask_fields :: #force_inline proc "contextless" (v: i64) -> (n, immr, imms: u8) {
	u := u32(v)
	return u8((u >> 12) & 1), u8((u >> 6) & 0x3F), u8(u & 0x3F)
}

// decode_bitmask_imm reconstructs the logical bitmask value from N:immr:imms,
// at the given width (32 or 64). Returns ok=false if the encoding is invalid.
decode_bitmask_imm :: proc "contextless" (n, immr, imms: u8, is_64: bool) -> (value: u64, ok: bool) {
	// Determine element size from N:imms[5:0] leading-ones pattern.
	s := imms & 0x3F
	elem_size: u32 = 0
	s_field: u8 = 0
	if n == 1 {
		if !is_64 { return 0, false }    // N=1 only valid for 64-bit ops
		elem_size = 64
		s_field = s
	} else {
		// N == 0: scan for top zero in imms.
		switch {
		case (s & 0b100000) == 0:        // 0xxxxx
			elem_size = 32
			s_field = s & 0b011111
		case (s & 0b110000) == 0b100000: // 10xxxx
			elem_size = 16
			s_field = s & 0b001111
		case (s & 0b111000) == 0b110000: // 110xxx
			elem_size = 8
			s_field = s & 0b000111
		case (s & 0b111100) == 0b111000: // 1110xx
			elem_size = 4
			s_field = s & 0b000011
		case (s & 0b111110) == 0b111100: // 11110x
			elem_size = 2
			s_field = s & 0b000001
		case:
			return 0, false
		}
	}

	width: u32 = is_64 ? 64 : 32
	if elem_size > width { return 0, false }

	ones := u32(s_field) + 1
	if ones == 0 || ones >= elem_size { return 0, false }

	rotation := u32(immr) & (elem_size - 1)

	// Build pattern: low `ones` bits set, then LEFT-rotate by `rotation`
	// (inverse of the encoder, which right-rotated to canonicalize).
	pattern: u64 = (u64(1) << ones) - 1
	elem_mask: u64 = elem_size == 64 ? ~u64(0) : (u64(1) << elem_size) - 1
	inv_rot: u32 = (elem_size - rotation) & (elem_size - 1)
	rotated := rotate_right_u64(pattern, inv_rot, elem_size) & elem_mask

	// Replicate to fill width.
	out: u64 = rotated
	for size: u32 = elem_size; size < width; size *= 2 {
		out |= out << size
	}
	if width == 32 { out &= 0xFFFFFFFF }
	return out, true
}
