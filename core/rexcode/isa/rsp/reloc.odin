// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_rsp

// =============================================================================
// RSP RELOCATIONS
// =============================================================================
//
// Per the cross-arch design (§2.4): each arch owns its own Relocation_Type
// enum and Relocation struct. The struct shape mirrors ELF rela so an
// object emitter can consume it unchanged. RSP only emits the two
// relocation kinds it actually needs.

Relocation_Type :: enum u8 {
	NONE = 0,
	REL16,  // 16-bit signed PC-rel branch (BEQ/BNE/BLEZ/BGTZ/...)
	J26,    // 26-bit J-type region target ((target_addr >> 2) & 0x3FFFFFF)
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
