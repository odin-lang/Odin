package rexcode_riscv

// =============================================================================
// RISC-V RELOCATIONS
// =============================================================================
//
// Per the cross-arch design (§2.4): each arch owns its own Relocation_Type
// and Relocation struct. RISC-V's relocations are unusual because two of
// the most common ones come in *pairs* -- PCREL_HI20 on an AUIPC plus
// PCREL_LO12_I/S on the dependent ADDI / load / store, where the LO part
// references the AUIPC's label-relative target rather than the symbol
// directly. We expose the pair as two related entries; pairing the
// resolution is up to the encoder pass-2.

Relocation_Type :: enum u8 {
	NONE = 0,

	// PC-relative branches and jumps
	BRANCH,       // 13-bit signed PC-rel, B-type scatter (BEQ/BNE/...)
	JAL,          // 21-bit signed PC-rel, J-type scatter (JAL)

	// PC-relative paired (AUIPC + ADDI/load/store)
	PCREL_HI20,   // upper 20 bits of (sym - pc), U-type
	PCREL_LO12_I, // lower 12 bits, I-type form
	PCREL_LO12_S, // lower 12 bits, S-type form

	// Absolute paired (LUI + ADDI/load/store)
	HI20,         // upper 20 of absolute, U-type
	LO12_I,       // lower 12, I-type
	LO12_S,       // lower 12, S-type

	// Helpful aggregate forms (the assembler can expand)
	CALL,         // AUIPC + JALR pair to call a far symbol

	// ---- C extension PC-relative ----
	C_BRANCH,     // 9-bit signed PC-rel for C.BEQZ / C.BNEZ
	C_JUMP,       // 12-bit signed PC-rel for C.J / C.JAL
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
