// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

import "../isa"

// =============================================================================
// MOS 6502 ENCODING FUNDAMENTALS
// =============================================================================
//
// Variable-length: 1, 2, 3, 4 (HuC TST # abs), or 7 (HuC6280 block
// transfer) bytes per instruction. The opcode is always the first byte;
// the remaining bytes carry operands in fixed positions per encoding form.
//
// Word-sized operands are encoded little-endian (LSB first).
//
// CPU compatibility:
//   - .NMOS         official MOS 6502 (Apple II, C64, NES, Atari, BBC, ...)
//   - .NMOS_UNDOC   unofficial NMOS opcodes (LAX, SAX, DCP, RLA, ...)
//                   widely used by NES games & demoscene. Not present on
//                   65C02-and-later silicon.
//   - .CMOS_65C02   Rockwell/WDC 65C02 additions (BRA/STZ/INA/DEA/PHX...
//                   plus the bit ops RMB/SMB/BBR/BBS).
//                   Also present on HuC6280 (it's a 65C02 superset).
//   - .HUC6280      PC Engine / TurboGrafx-16 superset of 65C02.
//
// 65C816 (SNES, Apple IIgs) is a separate 16/24-bit ISA and lives in a
// sibling subpackage if/when added.

Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map
// Relocation and Relocation_Type live in reloc.odin (per-arch by design).

CPU :: enum u8 {
	NMOS,
	NMOS_UNDOC,
	CMOS_65C02,
	HUC6280,
}

Encoding_Flags :: bit_field u8 {
	decimal:     bool | 1,  // ADC/SBC: behaves differently in BCD mode (2A03 NES forces this off)
	page_cross:  bool | 1,  // adds 1 cycle if base + index crosses a page boundary
	branch:      bool | 1,  // changes PC unconditionally (BRA, JMP, JSR, RTS, BSR)
	cond_branch: bool | 1,  // PC-relative conditional branch
	_:           u8   | 4,
}

// What the user passes in.
Operand_Type :: enum u8 {
	NONE,
	A_IMPL,            // accumulator (e.g. ROL A) -- no operand bytes encoded
	IMM_8,             // #$nn
	REL,               // signed byte PC-rel branch target
	MEM_ZP,            // $nn
	MEM_ZP_X,          // $nn,X
	MEM_ZP_Y,          // $nn,Y
	MEM_ABS,           // $nnnn
	MEM_ABS_X,         // $nnnn,X
	MEM_ABS_Y,         // $nnnn,Y
	MEM_IND,           // ($nnnn) -- NMOS/65C02 JMP only
	MEM_IND_X,         // ($nn,X)
	MEM_IND_Y,         // ($nn),Y
	MEM_IND_ZP,        // ($nn) -- 65C02
	MEM_IND_ABS_X,     // ($nnnn,X) -- 65C02 JMP only
	IMM_16,            // unsigned 16-bit literal (HuC6280 block xfer operands)
}

// Where the operand's bytes go inside the instruction word stream.
Operand_Encoding :: enum u8 {
	NONE,
	IMPL,              // implicit / accumulator -- no bytes emitted
	BYTE_1_IMM,        // 8-bit immediate at offset 1
	BYTE_1_ADDR,       // 8-bit zero-page address at offset 1
	BYTE_1_REL,        // signed 8-bit PC-rel at offset 1
	WORD_1_ADDR,       // 16-bit little-endian absolute at offset 1
	BYTE_2_REL,        // signed 8-bit PC-rel at offset 2 (BBR/BBS)
	WORD_1,            // 16-bit LE at offset 1 (HuC block xfer src)
	WORD_3,            // 16-bit LE at offset 3 (HuC block xfer dst)
	WORD_5,            // 16-bit LE at offset 5 (HuC block xfer len)
	BYTE_2_ADDR,       // 8-bit zero-page address at offset 2 (HuC TST # zp)
	WORD_2_ADDR,       // 16-bit LE absolute at offset 2 (HuC TST # abs)
}

// A single instruction encoding form. The opcode byte is always at offset 0.
//
// ops/enc are [4] for cross-arch parity even though no real 6502 instruction
// uses more than 3 operands (HuC6280's block-transfer ops).
Encoding :: struct #packed {
	mnemonic: Mnemonic,             // 2
	ops:      [4]Operand_Type,      // 4
	enc:      [4]Operand_Encoding,  // 4
	opcode:   u8,                   // 1
	length:   u8,                   // 1
	cpu:      CPU,                  // 1
	flags:    Encoding_Flags,       // 1
}
#assert(size_of(Encoding) == 14)
