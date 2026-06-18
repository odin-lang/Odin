// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle

import "../isa"

// =============================================================================
// PowerPC VLE Encoding Types
// =============================================================================
//
// VLE is variable-length (16-bit or 32-bit instructions). The Encoding.bits
// field holds either:
//   - 16-bit instruction in the low 16 bits (high 16 bits = 0) when
//     flags.short = true
//   - 32-bit instruction in the full word otherwise
//
// VLE shares the same GPR/SPR register model as standard PowerPC; types are
// duplicated here to keep ppc_vle as a standalone sibling package.

Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map

Mode :: enum u8 {
	PPC32_VLE = 0,
}

Feature :: enum u8 {
	BASE,
	LSP,
	SPE,
}

Encoding_Flags :: bit_field u8 {
	short:       bool | 1,  // 16-bit instruction (occupies low halfword only)
	cond_branch: bool | 1,  // conditional branch
	writes_lr:   bool | 1,  // LK=1
	sets_cr0:    bool | 1,  // Rc=1
	_:           u8   | 4,
}

Operand_Type :: enum u8 {
	NONE = 0,
	GPR,            // standard 32-register GPR (5-bit field, used in 32-bit ops)
	GPR_VLE16,      // 16-register VLE subset (4-bit field) — r0..r7 + r24..r31
	GPR_OR_ZERO,
	IMM,
	SIMM,
	UIMM,
	REL,
	MEM,
	CR_FIELD,
	CR_BIT,
	SPR,
	BO,             // branch-op selector immediate (BO16 = 1-bit, BO32 = 2-bit)
}

Operand_Encoding :: enum u8 {
	NONE = 0,
	IMPL,           // implicit / baked into bits

	// ---- 32-bit instructions (standard PPC slot positions) ----
	RT,             // bits 21..25 (5-bit GPR destination)
	RA,             // bits 16..20
	RB,             // bits 11..15
	RS,             // bits 21..25 (alias of RT used in store/X-form)
	UI16,           // bits 0..15, unsigned 16-bit
	SI16,           // bits 0..15, signed 16-bit
	LI20,           // 20-bit immediate split: imm[19:16] at bits 17..20,
					//                          imm[15:11] at bits 11..15,
					//                          imm[10:0]  at bits  0..10
	SCI8,           // 8-bit signed immediate with split scale + sign

	// ---- 32-bit branches ----
	B15,            // bits 1..15, signed << 1 (15-bit displacement)
	B24,            // bits 1..24, signed << 1 (24-bit displacement)
	BO32,           // bits 20..21 (2-bit BO)
	BI32,           // bits 16..19 (4-bit BI selecting CR bit)

	// ---- 16-bit register fields ----
	RX,             // bits 0..3, 4-bit GPR_VLE16
	RY,             // bits 4..7, 4-bit GPR_VLE16
	RZ,             // alias of RY at bits 4..7

	// ---- 16-bit immediates ----
	UI5,            // bits 4..8 (5-bit, SE_IM5 form)
	UI7,            // bits 4..10 (7-bit, IM7 form — actually IM7 puts UI7 at bits 8..14 and RX at bits 4..7 — see encoder)

	// ---- 16-bit memory (SD4 form) ----
	SE_SD,          // bits 8..11 unscaled (byte)
	SE_SDH,         // bits 8..11 scaled by 2 (halfword)
	SE_SDW,         // bits 8..11 scaled by 4 (word)

	// ---- 16-bit branches ----
	B8,             // bits 0..7, signed << 1 (8-bit displacement)
	BO16,           // bit 10 (1-bit BO in BD8IO form)
	BI16,           // bits 8..9 (2-bit BI)

	// ---- Memory operand composites ----
	OFFSET_BASE_D,  // 32-bit D-form: RA + signed 16-bit D
	OFFSET_BASE_SD4,// 16-bit SD4 byte memory: RX + SE_SD
	OFFSET_BASE_SD4_H, // 16-bit SD4 halfword memory: RX + SE_SDH
	OFFSET_BASE_SD4_W, // 16-bit SD4 word memory: RX + SE_SDW
}

Encoding :: struct #packed {
	mnemonic: Mnemonic,
	ops:      [4]Operand_Type,
	enc:      [4]Operand_Encoding,
	bits:     u32,
	mask:     u32,
	feature:  Feature,
	mode:     Mode,
	flags:    Encoding_Flags,
}
