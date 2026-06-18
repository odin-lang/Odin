// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mips

import "../isa"

// =============================================================================
// MIPS ENCODING FUNDAMENTALS
// =============================================================================
//
// All MIPS instructions are exactly 32 bits. The high 6 bits are the primary
// opcode; the remaining 26 bits are laid out per format:
//
//   R-type     [op 6 ][rs 5][rt 5][rd 5][shamt 5][funct 6]     (op=SPECIAL=0)
//   I-type     [op 6 ][rs 5][rt 5][         immediate 16        ]
//   J-type     [op 6 ][              target 26 (<<2)              ]
//   REGIMM     [001b  ][rs 5][rt(funct) 5][      immediate 16    ]   (op=1)
//   FR (COP1)  [010001][fmt 5][ft 5][fs 5][fd 5][funct 6]            (op=0x11)
//   FI (COP1)  [010001][01000][cc 3][nd 1][tf 1][imm 16]
//   COP0       [010000][rs 5][rt 5][rd 5][   0   8][sel 3]           (op=0x10)
//   COP2       [010010][rs 5][rt 5][rd 5][          imm 11      ]    (op=0x12)
//   COP2-CO    [010010][1][         cofun 25            ]            (PS1 GTE)
//
// Sub-major opcodes:
//   SPECIAL  (op=0x00): funct selects (ADD/SUB/AND/OR/JR/SLL/...)
//   REGIMM   (op=0x01): rt is the funct (BLTZ/BGEZ/BLTZAL/...)
//   SPECIAL2 (op=0x1C): funct selects (MUL/CLZ/MADD/...)
//   SPECIAL3 (op=0x1F): funct selects (EXT/INS/BSHFL/...)
//   COP0     (op=0x10): rs selects MFC0/MTC0/MFMC0/TLB*/ERET/...
//   COP1     (op=0x11): rs=fmt selects format, funct selects op
//   COP2     (op=0x12): bit 25 = CO; CO=0 dispatches by rs; CO=1 = GTE cofun
//
// PS2 EE MMI lives in op=0x1C (SPECIAL2) with funct 0x00, then sub-spaces
// MMI0..MMI3 disambiguated by bits 10-6. PSP VFPU claims new majors
// (op=0x18, 0x19, 0x35, 0x37, 0x3F, ...) with their own layouts.

// Re-exports from isa.
Result           :: isa.Result
Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map
// Relocation and Relocation_Type live in reloc.odin (per-arch by design).

// Endianness flag (controls how the encoder serialises 32-bit words to bytes).
// Console targets: PS1, PS2, PSP = LITTLE; N64 = BIG; "MIPS canonical" = BIG.
Endianness :: enum u8 {
	LITTLE = 0,
	BIG    = 1,
}

// ISA version + extension classification. Metadata: the matcher can
// optionally restrict picks to a chosen ISA level, and the printer can
// label disassembly with the introducing extension.
Feature :: enum u8 {
	MIPS_I,
	MIPS_II,
	MIPS_III,
	MIPS_IV,
	MIPS_V,
	MIPS32_R1,
	MIPS32_R2,
	MIPS32_R5,
	MIPS32_R6,
	MIPS64_R1,
	MIPS64_R2,
	MIPS64_R5,
	MIPS64_R6,
	COP0,            // system control coprocessor
	FPU,             // COP1 (any MIPS with FPU)
	DSP_R1,
	DSP_R2,
	MSA,             // MIPS SIMD
	GTE_PS1,         // PS1 R3000A Geometry Transformation Engine (COP2)
	MMI_PS2,         // PS2 R5900 Multimedia Instructions
	VU_PS2,          // PS2 VU0 macro-mode COP2 ops
	VFPU_PSP,        // PSP Allegrex Vector FPU
}

Encoding_Flags :: bit_field u8 {
	delay_slot:  bool | 1,   // branch with a one-instruction delay slot
	likely:      bool | 1,   // *L variants: nullify delay slot if not taken
	only_64:     bool | 1,   // requires 64-bit ISA (MIPS III+ / MIPS64)
	writes_hilo: bool | 1,   // touches HI:LO (mul/div family)
	compact:     bool | 1,   // R6 compact branch (no delay slot)
	_:           u8   | 3,
}

// Operand TYPES — what the user passes in.
Operand_Type :: enum u8 {
	NONE,

	// Integer registers
	GPR,
	GPR_ZERO,            // implicit $zero (rare; for disambiguation)

	// FP register, format-tagged
	FPR_S, FPR_D, FPR_W, FPR_L, FPR_PS,
	FCR,                 // FP control reg ($fcr0/$fccr/$fexr/$fenr/$fcsr)

	// Coprocessor registers
	CP0_REG,             // CP0 register (0-31), with optional sel
	CP2_REG,             // COP2 data register (GTE V*/MAC*/SXY*; VU vf*)
	CP2_CTRL,            // COP2 control register

	// VFPU registers (PSP) — single, pair, triple, quad
	VFPU_S, VFPU_P, VFPU_T, VFPU_Q,
	VFPU_M_P, VFPU_M_T, VFPU_M_Q,    // matrix forms

	// MSA vector register (W0..W31). Format suffix (.B/.H/.W/.D) is baked
	// into the mnemonic, so a single operand-type is enough at match time.
	MSA_VEC,

	// Immediates
	IMM5,                // 5-bit shift amount or small literal
	IMM16S,              // signed 16-bit
	IMM16U,              // unsigned (zero-extended) 16-bit
	IMM20,               // 20-bit SYSCALL/BREAK/SDBBP code
	IMM26,               // 26-bit J-type target word
	SEL,                 // CP0 selector (3 bits, R2+)

	// PC-relative branch targets
	REL16,               // 16-bit signed offset (<<2), I-type branches
	REL_J26,             // 26-bit region jump (J / JAL)
	REL21,               // R6 21-bit compact branch (BC1EQZ/NEZ)
	REL26,               // R6 26-bit compact branch (BC/BALC)

	// Memory: base GPR + 16-bit signed displacement
	MEM,

	// Condition codes / cofun selectors
	FCC,                 // FP condition-code field (3 bits)

	// GTE-specific cofun selectors (the few that are user-visible)
	GTE_SF, GTE_MX, GTE_V, GTE_CV, GTE_LM,
}

// Operand ENCODING — where each operand's bits go in the instruction word.
Operand_Encoding :: enum u8 {
	NONE,

	// Standard MIPS field placements (R/I-type)
	RS,            // bits 25-21
	RT,            // bits 20-16
	RD,            // bits 15-11
	SHAMT,         // bits 10-6

	// FP register placements (FR-format; overlap RS/RT/RD/SHAMT positions)
	FT,            // bits 20-16
	FS,            // bits 15-11
	FD,            // bits 10-6

	// Immediates
	IMM_16,        // bits 15-0
	IMM_5,         // bits 10-6 (same slot as SHAMT)
	IMM_20,        // bits 25-6 (SYSCALL/BREAK code)
	IMM_26,        // bits 25-0 (J-type target word)

	// Memory: implicit RS + IMM_16
	OFFSET_BASE,

	// PC-relative
	BRANCH_16,     // bits 15-0 as PC-relative word offset (delay-slot adjusted)
	BRANCH_21,     // R6 compact branch: bits 20-0
	BRANCH_26,     // R6 compact branch: bits 25-0

	// FP condition code
	FCC_BC,        // bits 20-18 (FP branches, MOVF/MOVT)
	FCC_CC,        // bits 10-8 (C.cond compare results)

	// CP0 selector
	SEL,           // bits 2-0

	// Implicit (operand exists in the asm syntax but is not encoded;
	// e.g. $zero in branch-likely synthetic forms).
	IMPL,

	// GTE cofun selectors (bit positions within the 25-bit cofun field)
	GTE_SF_BIT,    // bit 19
	GTE_MX_BITS,   // bits 18-17
	GTE_V_BITS,    // bits 16-15
	GTE_CV_BITS,   // bits 14-13
	GTE_LM_BIT,    // bit 10

	// ---- PSP VFPU register slots ------------------------------------------
	//
	// VFPU registers use 7-bit IDs (0..127). The standard 3-operand layout:
	//   bits 22:16 = vt   (7-bit register ID)
	//   bits 14:8  = vs   (7-bit register ID)
	//   bits  6:0  = vd   (7-bit register ID)
	// The width-modifier bits (bit 15 + bit 7) are NOT operand-driven --
	// they're baked into the form's static `bits` per the .s/.p/.t/.q
	// mnemonic suffix, so:
	//   .s = bit15=0, bit7=0
	//   .p = bit15=0, bit7=1
	//   .t = bit15=1, bit7=0
	//   .q = bit15=1, bit7=1
	VFPU_VD, VFPU_VS, VFPU_VT,

	// VFPU register for memory ops where the 7-bit ID is SPLIT:
	//   bits 20:16 = vt[6:2]   (top 5 bits at the rt position)
	//   bits  1:0  = vt[1:0]   (bottom 2 bits at the very low position)
	// Used by LV.S / SV.S / LV.Q / SV.Q.
	VFPU_VT_MEM,

	// VFPU SP-style memory operand: base GPR at bits 25:21 + signed-16
	// displacement at bits 15:2 (low 2 bits forced 0 = multiple of 4 for S,
	// multiple of 16 for Q -- user responsible for alignment).
	VFPU_OFFSET_BASE,

	// VFPU prefix immediate: 20-bit prefix mask at bits 19:0 (VPFXS/T/D).
	VFPU_PFX,

	// VFPU constant selector / 5-bit immediate at bits 20:16 (VCST, VF2I*).
	VFPU_CONST,

	// VFPU 4-bit condition code at bits 3:0 (VCMP).
	VFPU_COND4,

	// VFPU 3-bit VCC selector at bits 18:16 (BVF / BVT / BVFL / BVTL).
	VFPU_CC3,

	// MSA 3R-format register slots:
	//   wd at bits 10:6 (alias of RD/SHAMT bit positions)
	//   ws at bits 15:11 (alias of RD)
	//   wt at bits 20:16 (alias of RT)
	WD, WS, WT,

	// MSA element-index / immediate fields used by some forms (ELM/I5/BIT)
	MSA_I5,        // 5-bit immediate at bits 20:16 (LDI/I5 forms)
	MSA_S10,       // signed 10-bit displacement at bits 25:16 (MI10 load/store)
	MSA_BIT5,      // bit position (5-bit) at bits 16:11 (BIT form)
	// The shift amount / element index sits at bits 22:16 / 21:16 with the data
	// format encoded by the high (marker) bits; the operand drives the low bits
	// (the marker is fixed in the entry `bits`). Decode infers df from the marker.
	MSA_BIT_SHIFT, // BIT-format shift amount (.B m=0x70|sh, .H 0x60|sh, .W 0x40|sh, .D sh)
	MSA_ELM_IDX,   // ELM-format element index (.B n, .H 0x20|n, .W 0x30|n, .D 0x38|n)
	MSA_I8,        // 8-bit immediate at bits 23:16 (I8 forms: ANDI.B/SHF/...)
	FR,            // FP register at bits 25:21 (COP1X 4-register FMA: fr)
	GPR_AT_6,      // GPR at bits 10:6 (MSA COPY destination)
	GPR_AT_11,     // GPR at bits 15:11 (MSA INSERT source)
	DSP_SA,        // DSP shift amount at bits 24:21 (.PH 4-bit, .QB 3-bit)
	RS_RT,         // same GPR in both rs (25:21) and rt (20:16) (R6 BGEZC/BLTZC)
	AC_NUM,        // DSP accumulator number ac0..ac3 at bits 12:11 (immediate)
	SHILO_IMM,     // DSP SHILO signed 6-bit shift at bits 25:20
	EXT_SIZE,      // DSP EXTPDP extract size, 5-bit immediate at bits 25:21

	// MSA memory operand: base GPR at bits 15:11 + signed 10-bit disp at 25:16,
	// scaled by element size (1/2/4/8 for B/H/W/D).
	MSA_OFFSET_BASE_B,
	MSA_OFFSET_BASE_H,
	MSA_OFFSET_BASE_W,
	MSA_OFFSET_BASE_D,
}

// A single instruction encoding. `bits` holds the static pattern;
// `mask` marks which bits are static (so operand-derived bits OR in
// over zeros). Together they form a complete bit-level description.
Encoding :: struct #packed {
	mnemonic: Mnemonic,            // 2 bytes
	ops:      [4]Operand_Type,     // 4 bytes
	enc:      [4]Operand_Encoding, // 4 bytes
	bits:     u32,                 // 4 bytes — static bit pattern
	mask:     u32,                 // 4 bytes — which bits are static
	feature: Feature,                 // 1 byte  — metadata
	flags:    Encoding_Flags,      // 1 byte
}
#assert(size_of(Encoding) == 20)

// Convenience constructor for a 6-bit primary opcode at bits 31-26.
opcode_bits :: #force_inline proc "contextless" (op: u32) -> u32 {
	return (op & 0x3F) << 26
}

// Field masks (operand-bit positions, kept here so the future encoder
// can use them by name).
MASK_OPCODE :: u32(0xFC000000)   // bits 31-26
MASK_RS     :: u32(0x03E00000)   // bits 25-21
MASK_RT     :: u32(0x001F0000)   // bits 20-16
MASK_RD     :: u32(0x0000F800)   // bits 15-11
MASK_SHAMT  :: u32(0x000007C0)   // bits 10-6
MASK_FUNCT  :: u32(0x0000003F)   // bits  5-0
MASK_IMM16  :: u32(0x0000FFFF)   // bits 15-0
MASK_IMM26  :: u32(0x03FFFFFF)   // bits 25-0
MASK_SEL    :: u32(0x00000007)   // bits  2-0
MASK_FCC_BC :: u32(0x001C0000)   // bits 20-18
MASK_FCC_CC :: u32(0x00000700)   // bits 10-8

// Static masks for common pattern combinations.
//   R-type fixed bits = opcode (6) + funct (6).
MASK_R       :: MASK_OPCODE | MASK_FUNCT
//   R-type with fixed shamt=0 (most ADD/AND/etc.).
MASK_R_NOSH  :: MASK_R | MASK_SHAMT
//   I-type fixed bits = opcode only.
MASK_I       :: MASK_OPCODE
//   J-type fixed bits = opcode only.
MASK_J       :: MASK_OPCODE
//   REGIMM fixed bits = opcode + rt (the funct field for REGIMM).
MASK_REGIMM  :: MASK_OPCODE | MASK_RT
//   COP0/1/2 with fixed rs (rs selects the operation).
MASK_COP_RS  :: MASK_OPCODE | MASK_RS
//   COP1 FR-format: opcode + fmt(rs) + funct.
MASK_FR      :: MASK_OPCODE | MASK_RS | MASK_FUNCT
//   COP1 FI-format (BC1*): opcode + rs(=0x08) + tf/nd fixed bits (17-16).
MASK_FI      :: MASK_OPCODE | MASK_RS | u32(0x00030000)
