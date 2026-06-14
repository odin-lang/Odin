package rexcode_rsp

// =============================================================================
// N64 RSP ENCODING_TABLE
// =============================================================================
//
// Two encoding families:
//
//   Scalar — reuse standard MIPS I bit layouts.
//   Vector ALU — opcode 0x12 with CO=1 (bit 25); element in bits 24-21;
//     vt/vs/vd at the usual rs/rt/rd-equivalent positions; funct at 5-0.
//   Vector L/S — opcode 0x32 (LWC2) or 0x3A (SWC2) with op2 selector
//     at bits 15-11 and 7-bit signed offset at 6-0.
@(rodata)
ENCODING_TABLE: [Mnemonic][]Encoding = #partial {
	.INVALID = {},

	// =========================================================================
	// Scalar core
	// =========================================================================

	// R-type arithmetic (SPECIAL, op=0)
	.ADD  = { {.ADD,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000020, 0xFC0007FF, .RSP_SCALAR, {}} },
	.ADDU = { {.ADDU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000021, 0xFC0007FF, .RSP_SCALAR, {}} },
	.SUB  = { {.SUB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000022, 0xFC0007FF, .RSP_SCALAR, {}} },
	.SUBU = { {.SUBU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000023, 0xFC0007FF, .RSP_SCALAR, {}} },
	.AND  = { {.AND,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000024, 0xFC0007FF, .RSP_SCALAR, {}} },
	.OR   = { {.OR,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000025, 0xFC0007FF, .RSP_SCALAR, {}} },
	.XOR  = { {.XOR,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000026, 0xFC0007FF, .RSP_SCALAR, {}} },
	.NOR  = { {.NOR,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000027, 0xFC0007FF, .RSP_SCALAR, {}} },
	.SLT  = { {.SLT,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000002A, 0xFC0007FF, .RSP_SCALAR, {}} },
	.SLTU = { {.SLTU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000002B, 0xFC0007FF, .RSP_SCALAR, {}} },

	// Shifts
	.SLL  = { {.SLL,  {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x00000000, 0xFFE0003F, .RSP_SCALAR, {}} },
	.SRL  = { {.SRL,  {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x00000002, 0xFFE0003F, .RSP_SCALAR, {}} },
	.SRA  = { {.SRA,  {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x00000003, 0xFFE0003F, .RSP_SCALAR, {}} },
	.SLLV = { {.SLLV, {.GPR,.GPR,.GPR,.NONE},  {.RD,.RT,.RS,.NONE},    0x00000004, 0xFC0007FF, .RSP_SCALAR, {}} },
	.SRLV = { {.SRLV, {.GPR,.GPR,.GPR,.NONE},  {.RD,.RT,.RS,.NONE},    0x00000006, 0xFC0007FF, .RSP_SCALAR, {}} },
	.SRAV = { {.SRAV, {.GPR,.GPR,.GPR,.NONE},  {.RD,.RT,.RS,.NONE},    0x00000007, 0xFC0007FF, .RSP_SCALAR, {}} },

	// I-type
	.ADDI  = { {.ADDI,  {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x20000000, 0xFC000000, .RSP_SCALAR, {}} },
	.ADDIU = { {.ADDIU, {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x24000000, 0xFC000000, .RSP_SCALAR, {}} },
	.SLTI  = { {.SLTI,  {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x28000000, 0xFC000000, .RSP_SCALAR, {}} },
	.SLTIU = { {.SLTIU, {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x2C000000, 0xFC000000, .RSP_SCALAR, {}} },
	.ANDI  = { {.ANDI,  {.GPR,.GPR,.IMM16U,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x30000000, 0xFC000000, .RSP_SCALAR, {}} },
	.ORI   = { {.ORI,   {.GPR,.GPR,.IMM16U,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x34000000, 0xFC000000, .RSP_SCALAR, {}} },
	.XORI  = { {.XORI,  {.GPR,.GPR,.IMM16U,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x38000000, 0xFC000000, .RSP_SCALAR, {}} },
	.LUI   = { {.LUI,   {.GPR,.IMM16U,.NONE,.NONE}, {.RT,.IMM_16,.NONE,.NONE}, 0x3C000000, 0xFFE00000, .RSP_SCALAR, {}} },

	// Branches
	.BEQ    = { {.BEQ,    {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x10000000, 0xFC000000, .RSP_SCALAR, {delay_slot=true}} },
	.BNE    = { {.BNE,    {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x14000000, 0xFC000000, .RSP_SCALAR, {delay_slot=true}} },
	.BLEZ   = { {.BLEZ,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x18000000, 0xFC1F0000, .RSP_SCALAR, {delay_slot=true}} },
	.BGTZ   = { {.BGTZ,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x1C000000, 0xFC1F0000, .RSP_SCALAR, {delay_slot=true}} },
	.BLTZ   = { {.BLTZ,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04000000, 0xFC1F0000, .RSP_SCALAR, {delay_slot=true}} },
	.BGEZ   = { {.BGEZ,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04010000, 0xFC1F0000, .RSP_SCALAR, {delay_slot=true}} },
	.BLTZAL = { {.BLTZAL, {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04100000, 0xFC1F0000, .RSP_SCALAR, {delay_slot=true}} },
	.BGEZAL = { {.BGEZAL, {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04110000, 0xFC1F0000, .RSP_SCALAR, {delay_slot=true}} },

	// Jumps
	.J    = { {.J,    {.REL_J26,.NONE,.NONE,.NONE}, {.IMM_26,.NONE,.NONE,.NONE}, 0x08000000, 0xFC000000, .RSP_SCALAR, {delay_slot=true}} },
	.JAL  = { {.JAL,  {.REL_J26,.NONE,.NONE,.NONE}, {.IMM_26,.NONE,.NONE,.NONE}, 0x0C000000, 0xFC000000, .RSP_SCALAR, {delay_slot=true}} },
	.JR   = { {.JR,   {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x00000008, 0xFC1FFFFF, .RSP_SCALAR, {delay_slot=true}} },
	.JALR = { {.JALR, {.GPR,.GPR,.NONE,.NONE},  {.RD,.RS,.NONE,.NONE},  0x00000009, 0xFC1F07FF, .RSP_SCALAR, {delay_slot=true}} },

	// Loads / Stores
	.LB  = { {.LB,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x80000000, 0xFC000000, .RSP_SCALAR, {}} },
	.LH  = { {.LH,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x84000000, 0xFC000000, .RSP_SCALAR, {}} },
	.LW  = { {.LW,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x8C000000, 0xFC000000, .RSP_SCALAR, {}} },
	.LBU = { {.LBU, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x90000000, 0xFC000000, .RSP_SCALAR, {}} },
	.LHU = { {.LHU, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x94000000, 0xFC000000, .RSP_SCALAR, {}} },
	.SB  = { {.SB,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xA0000000, 0xFC000000, .RSP_SCALAR, {}} },
	.SH  = { {.SH,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xA4000000, 0xFC000000, .RSP_SCALAR, {}} },
	.SW  = { {.SW,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xAC000000, 0xFC000000, .RSP_SCALAR, {}} },

	// System
	.BREAK = { {.BREAK, {.IMM20,.NONE,.NONE,.NONE}, {.IMM_20,.NONE,.NONE,.NONE}, 0x0000000D, 0xFC00003F, .RSP_SCALAR, {}} },
	.NOP   = { {.NOP,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00000000, 0xFFFFFFFF, .RSP_SCALAR, {}} },

	// CP0 / CP2 moves
	.MFC0 = { {.MFC0, {.GPR,.CP0_REG,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x40000000, 0xFFE007FF, .RSP_SCALAR, {}} },
	.MTC0 = { {.MTC0, {.GPR,.CP0_REG,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x40800000, 0xFFE007FF, .RSP_SCALAR, {}} },
	// MFC2/MTC2/CFC2/CTC2 use the RD slot for vector register number + the
	// element field in bits 10-7 of the standard COP2 layout.
	.MFC2 = { {.MFC2, {.GPR,.VR,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x48000000, 0xFFE0007F, .RSP_SCALAR, {}} },
	.MTC2 = { {.MTC2, {.GPR,.VR,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x48800000, 0xFFE0007F, .RSP_SCALAR, {}} },
	.CFC2 = { {.CFC2, {.GPR,.CP2_CTRL,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x48400000, 0xFFE007FF, .RSP_SCALAR, {}} },
	.CTC2 = { {.CTC2, {.GPR,.CP2_CTRL,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x48C00000, 0xFFE007FF, .RSP_SCALAR, {}} },

	// =========================================================================
	// Vector ALU (COP2 with CO=1; opcode 0x12). Layout:
	//   [op=0x12 6][1=CO][element 4][vt 5][vs 5][vd 5][funct 6]
	// bits = 0x4A000000 | funct;
	// mask = OPCODE | CO | FUNCT = 0xFE00003F
	//   (element/vt/vs/vd are all operand-driven)
	// =========================================================================

	.VMULF = { {.VMULF, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000000, 0xFE00003F, .RSP_VU, {}} },
	.VMULU = { {.VMULU, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000001, 0xFE00003F, .RSP_VU, {}} },
	.VMUDL = { {.VMUDL, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000004, 0xFE00003F, .RSP_VU, {}} },
	.VMUDM = { {.VMUDM, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000005, 0xFE00003F, .RSP_VU, {}} },
	.VMUDN = { {.VMUDN, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000006, 0xFE00003F, .RSP_VU, {}} },
	.VMUDH = { {.VMUDH, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000007, 0xFE00003F, .RSP_VU, {}} },
	.VMACF = { {.VMACF, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000008, 0xFE00003F, .RSP_VU, {}} },
	.VMACU = { {.VMACU, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000009, 0xFE00003F, .RSP_VU, {}} },
	.VMADL = { {.VMADL, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00000C, 0xFE00003F, .RSP_VU, {}} },
	.VMADM = { {.VMADM, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00000D, 0xFE00003F, .RSP_VU, {}} },
	.VMADN = { {.VMADN, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00000E, 0xFE00003F, .RSP_VU, {}} },
	.VMADH = { {.VMADH, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00000F, 0xFE00003F, .RSP_VU, {}} },
	.VADD  = { {.VADD,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000010, 0xFE00003F, .RSP_VU, {}} },
	.VSUB  = { {.VSUB,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000011, 0xFE00003F, .RSP_VU, {}} },
	.VABS  = { {.VABS,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000013, 0xFE00003F, .RSP_VU, {}} },
	.VADDC = { {.VADDC, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000014, 0xFE00003F, .RSP_VU, {}} },
	.VSUBC = { {.VSUBC, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000015, 0xFE00003F, .RSP_VU, {}} },
	.VSAR  = { {.VSAR,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00001D, 0xFE00003F, .RSP_VU, {}} },
	.VLT   = { {.VLT,   {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000020, 0xFE00003F, .RSP_VU, {}} },
	.VEQ   = { {.VEQ,   {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000021, 0xFE00003F, .RSP_VU, {}} },
	.VNE   = { {.VNE,   {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000022, 0xFE00003F, .RSP_VU, {}} },
	.VGE   = { {.VGE,   {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000023, 0xFE00003F, .RSP_VU, {}} },
	.VCL   = { {.VCL,   {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000024, 0xFE00003F, .RSP_VU, {}} },
	.VCH   = { {.VCH,   {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000025, 0xFE00003F, .RSP_VU, {}} },
	.VCR   = { {.VCR,   {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000026, 0xFE00003F, .RSP_VU, {}} },
	.VMRG  = { {.VMRG,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000027, 0xFE00003F, .RSP_VU, {}} },
	.VAND  = { {.VAND,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000028, 0xFE00003F, .RSP_VU, {}} },
	.VNAND = { {.VNAND, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000029, 0xFE00003F, .RSP_VU, {}} },
	.VOR   = { {.VOR,   {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00002A, 0xFE00003F, .RSP_VU, {}} },
	.VNOR  = { {.VNOR,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00002B, 0xFE00003F, .RSP_VU, {}} },
	.VXOR  = { {.VXOR,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00002C, 0xFE00003F, .RSP_VU, {}} },
	.VNXOR = { {.VNXOR, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A00002D, 0xFE00003F, .RSP_VU, {}} },
	.VRCP  = { {.VRCP,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000030, 0xFE00003F, .RSP_VU, {}} },
	.VRCPL = { {.VRCPL, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000031, 0xFE00003F, .RSP_VU, {}} },
	.VRCPH = { {.VRCPH, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000032, 0xFE00003F, .RSP_VU, {}} },
	.VMOV  = { {.VMOV,  {.VR,.VR_ELEM,.NONE,.NONE}, {.VD,.VT,.NONE,.NONE}, 0x4A000033, 0xFE00003F, .RSP_VU, {}} },
	.VRSQ  = { {.VRSQ,  {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000034, 0xFE00003F, .RSP_VU, {}} },
	.VRSQL = { {.VRSQL, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000035, 0xFE00003F, .RSP_VU, {}} },
	.VRSQH = { {.VRSQH, {.VR,.VR,.VR_ELEM,.NONE}, {.VD,.VS,.VT,.NONE}, 0x4A000036, 0xFE00003F, .RSP_VU, {}} },
	.VNOP  = { {.VNOP,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000037, 0xFE00003F, .RSP_VU, {}} },

	// =========================================================================
	// Vector loads (LWC2 = opcode 0x32). Layout:
	//   [op=0x32 6][base 5][vt 5][op2 5][element 4][offset 7]
	// bits = 0xC8000000 | (op2 << 11);
	// mask = OPCODE | (op2 field, bits 15-11) = 0xFC00F800
	//   (vt/base/element/offset are operand-driven)
	// =========================================================================

	.LBV = { {.LBV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8000000, 0xFC00F800, .RSP_VLS, {}} },
	.LSV = { {.LSV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8000800, 0xFC00F800, .RSP_VLS, {}} },
	.LLV = { {.LLV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8001000, 0xFC00F800, .RSP_VLS, {}} },
	.LDV = { {.LDV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8001800, 0xFC00F800, .RSP_VLS, {}} },
	.LQV = { {.LQV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8002000, 0xFC00F800, .RSP_VLS, {}} },
	.LRV = { {.LRV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8002800, 0xFC00F800, .RSP_VLS, {}} },
	.LPV = { {.LPV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8003000, 0xFC00F800, .RSP_VLS, {}} },
	.LUV = { {.LUV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8003800, 0xFC00F800, .RSP_VLS, {}} },
	.LHV = { {.LHV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8004000, 0xFC00F800, .RSP_VLS, {}} },
	.LFV = { {.LFV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8004800, 0xFC00F800, .RSP_VLS, {}} },
	.LWV = { {.LWV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8005000, 0xFC00F800, .RSP_VLS, {}} },
	.LTV = { {.LTV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xC8005800, 0xFC00F800, .RSP_VLS, {}} },

	// =========================================================================
	// Vector stores (SWC2 = opcode 0x3A).  Same layout as loads.
	// =========================================================================

	.SBV = { {.SBV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8000000, 0xFC00F800, .RSP_VLS, {}} },
	.SSV = { {.SSV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8000800, 0xFC00F800, .RSP_VLS, {}} },
	.SLV = { {.SLV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8001000, 0xFC00F800, .RSP_VLS, {}} },
	.SDV = { {.SDV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8001800, 0xFC00F800, .RSP_VLS, {}} },
	.SQV = { {.SQV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8002000, 0xFC00F800, .RSP_VLS, {}} },
	.SRV = { {.SRV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8002800, 0xFC00F800, .RSP_VLS, {}} },
	.SPV = { {.SPV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8003000, 0xFC00F800, .RSP_VLS, {}} },
	.SUV = { {.SUV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8003800, 0xFC00F800, .RSP_VLS, {}} },
	.SHV = { {.SHV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8004000, 0xFC00F800, .RSP_VLS, {}} },
	.SFV = { {.SFV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8004800, 0xFC00F800, .RSP_VLS, {}} },
	.SWV = { {.SWV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8005000, 0xFC00F800, .RSP_VLS, {}} },
	.STV = { {.STV, {.VR,.VMEM,.NONE,.NONE}, {.VT_LS,.VBASE,.NONE,.NONE}, 0xE8005800, 0xFC00F800, .RSP_VLS, {}} },
}
