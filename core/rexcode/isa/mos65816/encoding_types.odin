// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos65816

import "core:rexcode/isa"

// =============================================================================
// W65C816S ENCODING FUNDAMENTALS
// =============================================================================
//
// Variable-length 1..4 byte ISA. The opcode is always byte 0; remaining
// bytes encode operands at fixed positions per form.
//
// Three operand-width-related quirks vs vanilla 6502:
//
//   1. Mode-dependent immediates. With M=0, `LDA #imm` takes a 16-bit
//      immediate (3-byte encoding); with M=1 it's 8-bit (2 bytes). Same
//      opcode, different length. The encoder reads `op.size` to pick the
//      right form (IMM_M8 vs IMM_M16); the decoder uses the caller-
//      supplied `Assumed_State.m` (and `.x` for the X/Y index ops).
//
//   2. Long (24-bit) addressing. LDA/STA/AND/ORA/EOR/ADC/SBC/CMP all add
//      $nnnnnn and $nnnnnn,X forms. JML/JSL take 24-bit targets.
//
//   3. Stack-relative addressing. `$nn,S` and `($nn,S),Y` -- new operand
//      shapes that don't exist on any 6502/65C02 variant.
//
// Emulation mode (E=1) reduces stack to bank-1 page and clamps M=X=1; the
// opcode set is unchanged so we don't carry separate entries -- the caller
// passes `e=true` in Assumed_State so the decoder picks the 8-bit immediate
// forms.

Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map

Encoding_Flags :: bit_field u8 {
	branch:      bool | 1,   // unconditional change of control flow
	cond_branch: bool | 1,   // PC-relative conditional
	page_cross:  bool | 1,   // +1 cycle on page boundary cross
	_:           u8   | 5,
}

// Mode-flag state the caller asserts at decode time.
Assumed_State :: struct {
	m: bool,   // M=1 (8-bit A/memory)         M=0 (16-bit A/memory)
	x: bool,   // X=1 (8-bit X/Y)              X=0 (16-bit X/Y)
	e: bool,   // E=1 (emulation: forces M=X=1)
}

NATIVE_16  :: Assumed_State{m = false, x = false, e = false}
NATIVE_8   :: Assumed_State{m = true,  x = true,  e = false}
EMULATION  :: Assumed_State{m = true,  x = true,  e = true }

Operand_Type :: enum u8 {
	NONE,
	A_IMPL,            // accumulator -- no operand bytes

	// Immediates
	IMM_8,             // always 8-bit (COP, REP, SEP, WDM, BRK signature, ...)
	IMM_M8,            // 8-bit when M=1
	IMM_M16,           // 16-bit when M=0
	IMM_X8,            // 8-bit when X=1
	IMM_X16,           // 16-bit when X=0

	// Branches
	REL,               // signed 8-bit PC-rel
	REL_LONG,          // signed 16-bit PC-rel (BRL, PER)

	// Memory (one per addressing mode)
	MEM_DP, MEM_DP_X, MEM_DP_Y,
	MEM_DP_IND, MEM_DP_IND_X, MEM_DP_IND_Y,
	MEM_DP_IND_LONG, MEM_DP_IND_LONG_Y,
	MEM_ABS, MEM_ABS_X, MEM_ABS_Y,
	MEM_ABS_IND, MEM_ABS_IND_LONG, MEM_ABS_IND_X,
	MEM_LONG, MEM_LONG_X,
	MEM_SR, MEM_SR_IND_Y,

	// Block move: two 8-bit bank operands. Source order in the syntax
	// (MVN src, dst) is the REVERSE of the byte order in the encoding.
	BANK_SRC,
	BANK_DST,
}

// Byte-offset + width within the instruction stream.
Operand_Encoding :: enum u8 {
	NONE,
	IMPL,
	BYTE_1_IMM,        // 8-bit at offset 1
	WORD_1_IMM,        // 16-bit LE at offset 1
	BYTE_1_ADDR,       // 8-bit zero/direct page address at offset 1
	WORD_1_ADDR,       // 16-bit LE absolute at offset 1
	LONG_1_ADDR,       // 24-bit LE long at offset 1
	BYTE_1_REL,        // signed 8-bit PC-rel at offset 1
	WORD_1_REL,        // signed 16-bit PC-rel at offset 1
	BYTE_1_BANK,       // dst bank byte at offset 1 (MVN/MVP)
	BYTE_2_BANK,       // src bank byte at offset 2 (MVN/MVP)
}

Encoding :: struct #packed {
	mnemonic: Mnemonic,             // 2
	ops:      [4]Operand_Type,      // 4
	enc:      [4]Operand_Encoding,  // 4
	opcode:   u8,                   // 1
	length:   u8,                   // 1
	flags:    Encoding_Flags,       // 1
}
#assert(size_of(Encoding) == 13)
