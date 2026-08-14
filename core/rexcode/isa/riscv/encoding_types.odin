// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_riscv

import "core:rexcode/isa"

// =============================================================================
// RISC-V ENCODING FUNDAMENTALS
// =============================================================================
//
// All non-C base-ISA instructions are exactly 32 bits. The low 7 bits hold
// the primary opcode (bits 6-0, low two bits always 0b11 for non-C).
//
// Six standard formats. The `funct3` field at bits 14-12 sub-divides
// opcode-sharing instructions, and `funct7` at bits 31-25 further refines
// R-type alternatives (e.g. ADD vs SUB share opcode + funct3, differ only
// in funct7 bit 30):
//
//   R-type   funct7 | rs2 | rs1 | funct3 | rd | opcode      ADD, SUB, AND, ...
//   I-type   imm[11:0]    | rs1 | funct3 | rd | opcode      ADDI, LW, JALR
//   S-type   imm[11:5] | rs2 | rs1 | f3 | imm[4:0] | op     SB, SH, SW
//   B-type   imm[12,10:5] | rs2 | rs1 | f3 | imm[4:1,11] | op   BEQ, BNE
//   U-type   imm[31:12]              | rd | opcode             LUI, AUIPC
//   J-type   imm[20,10:1,11,19:12]   | rd | opcode             JAL
//
// Branch (B) and jump (J) immediates are *scattered* across non-contiguous
// bit positions -- the encoder packs them via dedicated Operand_Encoding
// values rather than a flat field write.
//
// Encoding model is (bits, mask) like MIPS: `bits` holds the static field
// pattern, `mask` flags which positions are static. Operand-driven bits
// land in the zero positions of `bits`.

Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map

// Extension this entry belongs to (metadata, not used by the matcher).
Feature :: enum u8 {
	I,           // RV32I / RV64I base integer
	M,           // multiply / divide
	A,           // atomics
	F,           // single-precision FP
	D,           // double-precision FP
	ZICSR,       // CSR access (CSRRW/S/C + immediate forms)
	ZIFENCEI,    // FENCE.I (instruction-fetch fence)
	C,           // 16-bit compressed instructions
}

Encoding_Flags :: bit_field u8 {
	rv32_only: bool | 1,   // RV32 base only
	rv64_only: bool | 1,   // RV64 base only (e.g. LD/SD/ADDIW/...)
	branch:    bool | 1,   // changes PC
	fp_round:  bool | 1,   // funct3 doubles as FP rounding-mode field
	_:         u8   | 4,
}

// What the user passes in.
Operand_Type :: enum u8 {
	NONE,
	GPR,
	FPR,
	IMM12,           // signed 12-bit I-type immediate (ADDI/LOADS/JALR/...)
	IMM12U,          // unsigned 12-bit (CSR address; some pseudo-uses)
	IMM5,            // 5-bit shift amount (RV32 shifts; SLLIW/SRLIW/SRAIW)
	IMM6,            // 6-bit shift amount (RV64 SLLI/SRLI/SRAI)
	IMM20,           // 20-bit U-type immediate (LUI, AUIPC)
	REL13,           // 13-bit branch target (label or signed byte offset)
	REL21,           // 21-bit jump target (label or signed byte offset)
	MEM,             // base + signed 12-bit displacement
	CSR,             // 12-bit CSR address
	FENCE_FLAGS,     // 4-bit pred or succ mask (for FENCE)
	ROUND_MODE,      // 3-bit FP rounding mode
	ZIMM5,           // 5-bit zero-extended immediate (CSRRWI/SI/CI)

	// ---- C extension (compressed) ----
	GPR_C,           // "primed" 3-bit register (x8..x15 only)
	GPR_SP,          // hardwired SP (x2) for C.ADDI16SP / C.LWSP / C.SWSP
	GPR_NONZERO,     // GPR with hw != 0 (C.ADDI/C.LI/C.MV/etc. forbid x0)
	FPR_C,           // primed FP register (f8..f15 only)
	IMM_C6S,         // CI-form signed 6-bit (C.ADDI/C.LI)
	IMM_C6U,         // CI-form unsigned 6-bit (C.SLLI/SRLI/SRAI shamt)
	IMM_C8U,         // CIW-form 8-bit unsigned scaled (C.ADDI4SPN)
	IMM_C10S,        // C.ADDI16SP 10-bit signed scaled by 16
	IMM_C18S,        // C.LUI 18-bit signed scaled by 4096
	REL9,            // 9-bit signed PC-rel branch (C.BEQZ/BNEZ)
	REL12,           // 12-bit signed PC-rel jump (C.J/C.JAL)
	MEM_C_W,         // memory for C.LW/C.SW (rs1' + scaled imm by 4)
	MEM_C_D,         // memory for C.LD/C.SD (rs1' + scaled imm by 8)
	MEM_C_SP_W,      // SP-relative for C.LWSP/C.SWSP (scaled by 4)
	MEM_C_SP_D,      // SP-relative for C.LDSP/C.SDSP (scaled by 8)
}

// Where the operand's bits land in the 32-bit instruction word.
Operand_Encoding :: enum u8 {
	NONE,
	RD,              // bits 11-7   (any register, int or FP)
	RS1,             // bits 19-15
	RS2,             // bits 24-20
	RS3,             // bits 31-27  (R4-type, FMADD/FMSUB/FNMADD/FNMSUB)
	SHAMT5,          // bits 24-20  (5-bit shift)
	SHAMT6,          // bits 25-20  (6-bit shift, RV64 long shifts)
	IMM_I,           // bits 31-20  (signed I-type 12-bit)
	IMM_S,           // bits 31-25 || 11-7  (S-type scatter)
	IMM_B,           // B-type scatter: imm[12] @31, [10:5] @30-25, [4:1] @11-8, [11] @7
	IMM_U,           // bits 31-12  (U-type 20-bit upper)
	IMM_J,           // J-type scatter: imm[20] @31, [10:1] @30-21, [11] @20, [19:12] @19-12
	OFFSET_BASE_I,   // memory: rs1 @bits 19-15 + IMM_I disp (loads, JALR, FLW, FLD)
	OFFSET_BASE_S,   // memory: rs1 @bits 19-15 + IMM_S disp (stores, FSW, FSD)
	OFFSET_BASE_A,   // memory: rs1 @bits 19-15 only (atomics; disp must be 0)
	CSR_FIELD,       // bits 31-20  (12-bit CSR address)
	ZIMM_FIELD,      // bits 19-15  (zero-extended 5-bit imm; replaces rs1 in CSRRxI)
	FENCE_PRED,      // bits 27-24
	FENCE_SUCC,      // bits 23-20
	ROUND_FIELD,     // bits 14-12  (funct3 doubles as rm)
	AQRL,            // bits 26-25  (atomic acquire/release)

	// ---- C extension (compressed; bits fit in low 16 of the word) ----
	C_RD_RS1,        // bits 11-7  (CR/CI shared rd/rs1 slot)
	C_RS2,           // bits  6-2  (CR rs2)
	C_RD_PRIMED,     // bits  4-2  (CIW/CL/CB rd' encoded as x8+field)
	C_RS1_PRIMED,    // bits  9-7  (CL/CS/CA/CB rs1' encoded as x8+field)
	C_RS2_PRIMED,    // bits  4-2  (CS/CA rs2' encoded as x8+field)
	C_RD_RS1_PRIMED, // bits  9-7  (CA rd'/rs1' encoded as x8+field)
	C_IMM_CI_S,      // bits 12 || 6-2  (signed 6-bit CI imm)
	C_IMM_CI_U,      // bits 12 || 6-2  (unsigned 6-bit CI imm; SLLI shamt)
	C_IMM_CIW,       // bits 12-5  (C.ADDI4SPN: scrambled to imm[9:2])
	C_IMM_LUI,       // bits 12 || 6-2 (C.LUI: imm[17] || imm[16:12])
	C_IMM_ADDI16SP,  // bits 12,4,3,5,2,6  -> imm[9,4,6,8:7,5]
	C_IMM_CSS_W,     // bits 12-7  -> imm[5:2,7:6] (C.SWSP scaled by 4)
	C_IMM_CSS_D,     // bits 12-7  -> imm[5:3,8:6] (C.SDSP scaled by 8)
	C_IMM_CL_W,      // bits 12-10 || 6-5 -> imm[5:3,2,6] (C.LW/C.SW scaled by 4)
	C_IMM_CL_D,      // bits 12-10 || 6-5 -> imm[5:3,7:6] (C.LD/C.SD scaled by 8)
	C_BRANCH9,       // C.BEQZ/BNEZ: scatter to bits 12 || 10:9,2,7:6,5:4 || 11
	C_BRANCH12,      // C.J/C.JAL: scatter to bits 12 || 8 || 10:9 || 6 || 7 || 2 || 11 || 5:3 -> imm[11,4,9:8,10,6,7,3:1,5]
	C_OFFSET_BASE_W, // memory: rs1' at 9-7 + scaled-by-4 imm at 12-10 || 6-5
	C_OFFSET_BASE_D, // memory: rs1' at 9-7 + scaled-by-8 imm at 12-10 || 6-5
	C_SP_OFFSET_W,   // SP-relative: rd at 11-7 + scaled-by-4 imm at 12 || 6:4 || 3:2 -> imm[5,4:2,7:6]
	C_SP_OFFSET_D,   // SP-relative: rd at 11-7 + scaled-by-8 imm at 12 || 6:5 || 4:2 -> imm[5,4:3,8:6]
}

Encoding :: struct #packed {
	mnemonic: Mnemonic,            // 2
	ops:      [4]Operand_Type,     // 4
	enc:      [4]Operand_Encoding, // 4
	bits:     u32,                 // 4 -- static bit pattern
	mask:     u32,                 // 4 -- which bits are static
	feature: Feature,                 // 1
	flags:    Encoding_Flags,      // 1
}
#assert(size_of(Encoding) == 20)

// inst_size_from_bits returns 2 for compressed (RVC) instructions, 4 for the
// standard 32-bit base ISA. RISC-V uses a length-encoding convention where
// the low 2 bits of the first halfword identify the instruction length:
// 11 = 32-bit (the standard base ISA), anything else = 16-bit (compressed).
inst_size_from_bits :: #force_inline proc "contextless" (bits: u32) -> u8 {
	return (bits & 0x3) == 0x3 ? 4 : 2
}

// Static field masks for handy reference in the table.
MASK_OPCODE :: u32(0x0000007F)   // bits 6-0
MASK_RD     :: u32(0x00000F80)   // bits 11-7
MASK_FUNCT3 :: u32(0x00007000)   // bits 14-12
MASK_RS1    :: u32(0x000F8000)   // bits 19-15
MASK_RS2    :: u32(0x01F00000)   // bits 24-20
MASK_FUNCT7 :: u32(0xFE000000)   // bits 31-25
MASK_IMM_I  :: u32(0xFFF00000)   // bits 31-20
MASK_SHAMT5 :: u32(0x01F00000)   // bits 24-20
MASK_SHAMT6 :: u32(0x03F00000)   // bits 25-20  (RV64)

// Convenience composites
MASK_R       :: MASK_OPCODE | MASK_FUNCT3 | MASK_FUNCT7
MASK_I       :: MASK_OPCODE | MASK_FUNCT3
MASK_I_SHIFT :: MASK_OPCODE | MASK_FUNCT3 | (MASK_FUNCT7 &~ MASK_SHAMT6)   // ignore shamt
MASK_S       :: MASK_OPCODE | MASK_FUNCT3
MASK_B       :: MASK_OPCODE | MASK_FUNCT3
MASK_U       :: MASK_OPCODE
MASK_J       :: MASK_OPCODE
