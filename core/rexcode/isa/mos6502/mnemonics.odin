// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

// =============================================================================
// MOS 6502 family mnemonics
// =============================================================================
//
// Covers the four CPU tiers we target:
//   - NMOS official 6502 (56 mnemonics)
//   - NMOS undocumented opcodes (~24, widely used on NES & Apple II)
//   - 65C02 additions (Rockwell/WDC), incl. RMB/SMB/BBR/BBS bit ops
//   - HuC6280 (PC Engine) additions: block xfer, swap regs, MMR ops
//
// The undocumented NMOS SAX (store A&X) collides in mnemonic with the
// HuC6280 SAX (swap A,X). To keep both, the NMOS undocumented form is
// named `SAX_NMOS` (sometimes written as AAX or SAX-undoc elsewhere).

Mnemonic :: enum u16 {
	INVALID = 0,

	// -------------------------------------------------------------------------
	// NMOS official
	// -------------------------------------------------------------------------

	// Arithmetic / logical
	ADC, AND, ASL,
	BIT,
	CMP, CPX, CPY,
	DEC, DEX, DEY,
	EOR,
	INC, INX, INY,
	LSR,
	ORA,
	ROL, ROR,
	SBC,

	// Branches
	BCC, BCS, BEQ, BMI, BNE, BPL, BVC, BVS,

	// Jumps / subroutines / interrupts
	JMP, JSR, RTI, RTS,
	BRK,

	// Flag ops
	CLC, CLD, CLI, CLV,
	SEC, SED, SEI,

	// Loads / stores
	LDA, LDX, LDY,
	STA, STX, STY,

	// Stack / transfer
	PHA, PHP, PLA, PLP,
	TAX, TAY, TSX, TXA, TXS, TYA,

	// NOP
	NOP,

	// -------------------------------------------------------------------------
	// NMOS undocumented (common subset used on NES & Apple II)
	// -------------------------------------------------------------------------

	LAX,        // LDA + LDX (load A and X from memory)
	SAX_NMOS,   // store A AND X to memory (also called AAX / AXS-undoc)
	DCP,        // DEC + CMP (memory)
	ISC,        // INC + SBC (also ISB)
	RLA,        // ROL + AND
	RRA,        // ROR + ADC
	SLO,        // ASL + ORA
	SRE,        // LSR + EOR
	ALR,        // AND #imm + LSR A
	ANC,        // AND #imm with carry from N
	ARR,        // AND #imm + ROR A
	AXS,        // X = (A AND X) - imm  (also SBX)
	LAS,        // LDA / TSX / AND with stack pointer
	ANE,        // A = (A | $EE) AND X AND imm  -- unstable (also XAA)
	LXA,        // A = X = (A | $EE) AND imm    -- unstable
	SHA,        // store A AND X AND high+1
	SHX,        // store X AND high+1
	SHY,        // store Y AND high+1
	TAS,        // S = A AND X; store S AND high+1
	JAM,        // halt the CPU (also KIL / HLT)
	USBC,       // same as SBC #imm but at $EB (an undocumented alias)
	DOP,        // double NOP (skips one operand byte)
	TOP,        // triple NOP (skips two operand bytes)

	// -------------------------------------------------------------------------
	// 65C02 additions (Rockwell + WDC)
	// -------------------------------------------------------------------------

	BRA,              // branch always
	INA,              // INC A
	DEA,              // DEC A
	PHX, PHY,
	PLX, PLY,
	STZ,              // store zero
	TRB, TSB,         // test-and-reset / test-and-set bits
	STP, WAI,         // WDC: stop, wait-for-interrupt

	// 65C02 Rockwell bit ops -- 32 distinct opcodes
	RMB0, RMB1, RMB2, RMB3, RMB4, RMB5, RMB6, RMB7,
	SMB0, SMB1, SMB2, SMB3, SMB4, SMB5, SMB6, SMB7,
	BBR0, BBR1, BBR2, BBR3, BBR4, BBR5, BBR6, BBR7,
	BBS0, BBS1, BBS2, BBS3, BBS4, BBS5, BBS6, BBS7,

	// -------------------------------------------------------------------------
	// HuC6280 (PC Engine / TurboGrafx-16)
	// -------------------------------------------------------------------------

	SXY,              // swap X, Y
	SAX,              // swap A, X   (NB: distinct from undocumented NMOS SAX_NMOS)
	SAY,              // swap A, Y
	CLA, CLX, CLY,    // clear A / X / Y
	CSH, CSL,         // CPU speed high / low (7.16 MHz vs 1.79 MHz)
	SET,              // set T flag (next op uses zp address as accumulator)
	ST0, ST1, ST2,    // store immediate to MMR0/1/2
	TAM, TMA,         // transfer A to/from MMR (immediate-selected)
	TST,              // bit test of immediate against memory
	BSR,              // branch to subroutine (PC-relative)

	// HuC6280 block transfer instructions (7-byte encoding)
	//   src(2) -> dst(2), len(2) bytes
	TII,              // transfer increment-increment   (memcpy ascending)
	TDD,              // transfer decrement-decrement   (memcpy descending)
	TIN,              // transfer increment-no-change   (fill from src)
	TIA,              // transfer increment-alternate   (interleaved)
	TAI,              // transfer alternate-increment   (interleaved)
}
