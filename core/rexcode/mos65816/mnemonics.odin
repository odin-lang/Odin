package rexcode_mos65816

// =============================================================================
// W65C816S mnemonics
// =============================================================================
//
// Carries over the NMOS 6502 base + the universal 65C02 additions (the
// Rockwell bit ops RMB/SMB/BBR/BBS are NOT in the stock WDC 65816), plus
// the ~27 mnemonics that are new to the 65816.

Mnemonic :: enum u16 {
	INVALID = 0,

	// 6502 core
	ADC, AND, ASL,
	BIT, CMP, CPX, CPY,
	DEC, DEX, DEY, EOR,
	INC, INX, INY,
	LSR, ORA,
	ROL, ROR, SBC,
	LDA, LDX, LDY,
	STA, STX, STY,
	TAX, TAY, TSX, TXA, TXS, TYA,
	PHA, PHP, PLA, PLP,
	JMP, JSR, RTI, RTS,
	BRK, NOP,

	// Branches
	BCC, BCS, BEQ, BMI, BNE, BPL, BVC, BVS,

	// Flags
	CLC, CLD, CLI, CLV, SEC, SED, SEI,

	// 65C02 additions (carry over to 65816)
	BRA,
	STZ, TRB, TSB,
	PHX, PHY, PLX, PLY,
	STP, WAI,

	// 65816 new
	BRL,                // 16-bit relative branch
	COP,                // co-processor enable (interrupt)
	JML,                // jump long (24-bit)
	JSL,                // jump-to-subroutine long (24-bit)
	MVN, MVP,           // block move negative / positive
	PEA,                // push effective absolute address
	PEI,                // push effective indirect address
	PER,                // push effective PC-relative
	PHB, PHD, PHK,      // push DBR / D / PBR
	PLB, PLD,           // pull  DBR / D
	REP, SEP,           // reset / set status bits (immediate mask)
	RTL,                // return long
	TCD, TDC,           // A <-> D
	TCS, TSC,           // A <-> S
	TXY, TYX,           // X <-> Y
	WDM,                // reserved (assembles as 2-byte no-op)
	XBA,                // exchange A halves (B <-> A)
	XCE,                // exchange Carry and Emulation flags
}
