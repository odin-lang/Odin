package rexcode_rsp

// =============================================================================
// N64 RSP MNEMONICS
// =============================================================================
//
// Two halves: a strict MIPS I subset for the scalar core (no
// MULT/DIV/HI/LO/SYNC/LWL/LWR/SWL/SWR/64-bit), and the vector unit
// (VMULF.../VLT.../VRCP.../etc. + LBV..LTV loads, SBV..STV stores).

Mnemonic :: enum u16 {
	INVALID = 0,

	// -------------------------------------------------------------------------
	// Scalar core — MIPS I subset
	// -------------------------------------------------------------------------

	// R-type arithmetic / logical / shift
	ADD, ADDU, SUB, SUBU,
	AND, OR, XOR, NOR,
	SLT, SLTU,
	SLL, SRL, SRA,
	SLLV, SRLV, SRAV,

	// I-type
	ADDI, ADDIU,
	SLTI, SLTIU,
	ANDI, ORI, XORI,
	LUI,

	// Branches (with delay slot)
	BEQ, BNE, BLEZ, BGTZ,
	BLTZ, BGEZ, BLTZAL, BGEZAL,

	// Jumps
	J, JAL, JR, JALR,

	// Load / Store (no LWL/LWR/SWL/SWR on the RSP).
	LB, LH, LW, LBU, LHU,
	SB, SH, SW,

	// System
	BREAK, NOP,

	// Coprocessor moves
	MFC0, MTC0,
	MFC2, MTC2, CFC2, CTC2,

	// -------------------------------------------------------------------------
	// Vector ALU (COP2, CO=1; opcode 0x12 with funct selecting)
	// -------------------------------------------------------------------------

	VMULF, VMULU,
	VMUDL, VMUDM, VMUDN, VMUDH,
	VMACF, VMACU,
	VMADL, VMADM, VMADN, VMADH,
	VADD, VSUB, VABS,
	VADDC, VSUBC,
	VSAR,
	VLT, VEQ, VNE, VGE,
	VCL, VCH, VCR, VMRG,
	VAND, VNAND, VOR, VNOR, VXOR, VNXOR,
	VRCP, VRCPL, VRCPH,
	VMOV,
	VRSQ, VRSQL, VRSQH,
	VNOP,

	// -------------------------------------------------------------------------
	// Vector loads (LWC2 = opcode 0x32 with op2 selector)
	// -------------------------------------------------------------------------

	LBV, LSV, LLV, LDV, LQV, LRV,
	LPV, LUV, LHV, LFV, LWV, LTV,

	// -------------------------------------------------------------------------
	// Vector stores (SWC2 = opcode 0x3A with op2 selector)
	// -------------------------------------------------------------------------

	SBV, SSV, SLV, SDV, SQV, SRV,
	SPV, SUV, SHV, SFV, SWV, STV,
}
