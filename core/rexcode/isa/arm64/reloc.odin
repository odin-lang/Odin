// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

// =============================================================================
// AArch64 RELOCATIONS
// =============================================================================
//
// Per the cross-arch design (§2.4): each arch owns its own enum + struct.
// AArch64 has several PC-relative immediate widths plus the unusual
// ADR/ADRP pair where ADRP carries the page-aligned high bits and ADD
// (or LDR/STR) carries the low 12. PAC, GOT, and TLS relocations are
// follow-up work.

Relocation_Type :: enum u8 {
	NONE = 0,

	// PC-relative branches
	B26,           // 26-bit signed offset (×4) -- B / BL
	B_COND19,      // 19-bit signed offset (×4) -- B.cond, CBZ/CBNZ
	TBZ14,         // 14-bit signed offset (×4) -- TBZ / TBNZ

	// PC-relative addressing
	ADR_PCREL21,   // ±1MB signed offset -- ADR
	ADRP_PCREL21,  // ±4GB signed offset on 4K page boundary -- ADRP
	PCREL_LO12_I,  // low 12 of (sym - page_of(ADRP)) -- ADD/LDR/STR after ADRP
	PCREL_LO12_S,  // S-form variant if needed for store-pair-style ops

	// Load-literal (PC-relative 19-bit signed, scaled by 4)
	LDR_LITERAL19,

	// Absolute (filled by linker)
	ABS64,
	ABS32,
	ABS16,
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
