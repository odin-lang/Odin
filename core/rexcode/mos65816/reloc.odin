package rexcode_mos65816

// =============================================================================
// 65816 RELOCATIONS
// =============================================================================
//
// Per the cross-arch design (§2.4): each arch owns its own Relocation_Type
// and Relocation struct. The 65816's relocation kinds reflect the four
// address widths it can patch:
//
//   ABS16   2-byte LE absolute, low 16 of (base + target + addend)
//   ABS24   3-byte LE absolute, low 24 of (base + target + addend)
//   REL8    signed 8-bit PC-relative (target - (offset + 1))
//   REL16   signed 16-bit PC-relative (target - (offset + 2)) -- BRL, PER

Relocation_Type :: enum u8 {
	NONE = 0,
	ABS16,
	ABS24,
	REL8,
	REL16,
}

Relocation :: struct #packed {
	offset:   u32,
	label_id: u32,
	addend:   i32,
	type:     Relocation_Type,
	size:     u8,
	inst_idx: u16,
}
#assert(size_of(Relocation) == 16)
