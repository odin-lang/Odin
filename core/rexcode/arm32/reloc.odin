// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

// =============================================================================
// AArch32 RELOCATIONS
// =============================================================================
//
// AArch32 has many PC-relative forms because both A32 and T32 modes encode
// branches with varying displacement widths:
//
//   * A32 B/BL:           24-bit signed << 2 (-32MB..+32MB)
//   * A32 BLX imm:        24-bit signed << 2 + H bit (half-word align for arm->thumb)
//   * T32 unconditional B: 25-bit signed (S/J1/J2/imm10/imm11 scattered, ±16MB)
//   * T32 conditional B:  21-bit signed (cond + S/J1/J2/imm6/imm11 scattered, ±1MB)
//   * T16 unconditional B: 12-bit signed << 1 (±2KB)
//   * T16 conditional B:   9-bit signed << 1 (±256B)
//   * T16 CBZ/CBNZ:        7-bit unsigned << 1 (forward only)
//   * ADR/LDR-literal:    PC-relative literal pool access
//
// PC for arm32 is always (current_inst_addr + 8) in A32 / (+4) in T32.
// The relocation resolver bakes this in.

Relocation_Type :: enum u8 {
	NONE = 0,

	// A32 branches
	BRANCH_A32_24,         // B / BL, 24-bit signed << 2
	BLX_A32,               // BLX imm, 24-bit signed << 2 + H bit at bit 24

	// T32 branches
	BRANCH_T32_25,         // T32 B unconditional (J1/J2 + imm10 + imm11)
	BRANCH_T32_21,         // T32 B<cond> (S + cond + imm6 + J1/J2 + imm11)

	// T16 branches
	BRANCH_T16_11,         // T16 B unconditional (signed 11-bit << 1)
	BRANCH_T16_8,          // T16 B<cond> (signed 8-bit << 1)
	BRANCH_T16_CBZ,        // T16 CBZ/CBNZ (i + imm5 + Rn)

	// T32 low-overhead loops (ARMv8.1-M)
	BRANCH_T32_WLS,        // WLS / WLSTP imm11
	BRANCH_T32_LE,         // LE / LETP imm11

	// Literal load (ADR / LDR PC-rel)
	LDR_LITERAL_A32,       // signed 12-bit (U bit + imm12)
	LDR_LITERAL_T32,       // signed 12-bit (U bit + imm12) Thumb-2
	LDR_LITERAL_T16,       // unsigned 8-bit << 2 (Thumb-1 PC-rel)
	ADR_A32,               // ADR encoded as ADD/SUB to PC
	ADR_T32,
	ADR_T16,               // Thumb-1 ADR (imm8 << 2)

	// Absolute forms via MOVW + MOVT pair
	MOVW_ABS,              // imm16 low half
	MOVT_ABS,              // imm16 high half
}

Relocation :: struct #packed {
	offset:   u32,
	label_id: u32,
	addend:   i32,
	type:     Relocation_Type,
	size:     u8,          // 2 (T16) or 4 (A32/T32)
	inst_idx: u16,
}
#assert(size_of(Relocation) == 16)
