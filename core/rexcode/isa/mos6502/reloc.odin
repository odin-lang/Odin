// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

// =============================================================================
// MOS 6502 RELOCATIONS
// =============================================================================
//
// Per the cross-arch design (§2.4): each arch owns its own Relocation_Type
// enum and Relocation struct. The struct shape mirrors ELF rela so an
// object emitter can consume it unchanged.
//
// 6502 has just two relocation kinds:
//   ABS16  — 16-bit little-endian absolute (JMP $nnnn, JSR $nnnn, LDA $nnnn, ...)
//   REL8   — signed 8-bit PC-relative branch (BEQ/BNE/.../BBR/BBS)

Relocation_Type :: enum u8 {
	NONE = 0,
	ABS16,
	REL8,
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
