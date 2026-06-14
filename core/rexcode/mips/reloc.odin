package rexcode_mips

// =============================================================================
// MIPS RELOCATIONS
// =============================================================================
//
// Per the cross-arch design (§2.4): each arch owns its own Relocation_Type
// enum and Relocation struct. The struct shape mirrors ELF rela so an
// object emitter can consume it unchanged; the resolution semantics for
// each `type` value are MIPS-specific and live in encoder.odin's pass-2
// resolver.

Relocation_Type :: enum u8 {
	NONE = 0,
	REL16,  // 16-bit signed PC-rel branch offset (BEQ/BNE/BLEZ/BGTZ/...)
	REL21,  // 21-bit signed PC-rel compact branch (R6 BEQZC/BNEZC)
	REL26,  // 26-bit signed PC-rel compact branch (R6 BC/BALC)
	J26,    // 26-bit J-type region target ((target_addr >> 2) & 0x3FFFFFF)
	HI16,   // upper 16 of 32-bit absolute (LUI rt, %hi(sym)+0x8000 if LO16 paired)
	LO16,   // lower 16 of 32-bit absolute (ADDIU rt, rt, %lo(sym))
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
