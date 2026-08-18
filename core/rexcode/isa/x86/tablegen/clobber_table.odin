// clobber_table.odin  --  PER-FORM side-effect table for rexcode_x86_tablegen
//
// Type: [Mnemonic][]x86.Clobber   (parallel to [Mnemonic][]Encoding)
//
// HOW EACH FORM IS SPECIALISED FROM THE UNION:
//   1. Implicit-operand normalisation. An operand that is an implicit register
//      (AL/AX/EAX/RAX_IMPL -> RAX, CL_IMPL -> RCX, XMM0_IMPL -> XMM0,
//      ST0_IMPL -> FPU_ST) or an implicit constant (ONE_IMPL) is removed from the
//      OP0.3 slot set and, if that slot was written/read, folded into
//      implicit_wr/implicit_rd. Registers that are implicit but NOT tied to an
//      operand (RSP for the stack, RSI/RDI/RCX for strings, RDX for MULX, ...)
//      are inherent and kept on every form.
//   2. Slot trimming. OP slots that are .NONE in a given form are dropped from
//      written/read.
//   3. Per-form memory. writes_mem/reads_mem keep the union's DIRECTION but are
//      asserted on a form only when that form actually carries a memory-capable
//      operand, OR the instruction addresses memory implicitly (stack, string,
//      XLAT table, MASKMOVDQU/[rDI] store, VMCS, shadow stack). Consequently
//      register-only forms of otherwise-memory instructions (e.g. MOV r,imm;
//      FADD ST(0),ST(i); FST ST(i); MOVLHPS; PEXTRW r32,xmm) no longer carry the
//      blanket memory flag the union used.
//   4. Family splits that the union could only approximate:
//        IMUL  -- 1-operand form writes RDX:RAX implicitly (r/m8 -> AX only);
//                 2-operand form is OP0 *= OP1; 3-operand form is OP0 = OP1 * imm
//                 (OP0 not read); neither multi-operand form touches RAX/RDX.
//        MUL/DIV/IDIV -- the r/m8 form uses the A-register only and does not
//                 touch (R)DX.
//        SHL/SHR/SAR/ROL/ROR/RCL/RCR/SHLD/SHRD -- only the CL form reads RCX;
//                 the 1/imm8 forms do not.
//   Flags and side_effects are uniform across a mnemonic's forms and are carried
//   through unchanged.
//
// INVARIANT preserved: a form is a freely-eliminable no-op iff every clobber set
// is empty AND side_effects == {} (only .NOP and the .INVALID sentinel qualify).

package rexcode_x86_tablegen

import "core:rexcode/isa/x86"

@(rodata)
CLOBBER_TABLE := [Mnemonic][]x86.Clobber{
	.INVALID = {},


	// 8.1 Data Transfer Encodings
	.MOV = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.MOVABS = {
		{written={0}, read={1}},
		{read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true},
	},
	.MOVZX = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.MOVSX = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.MOVSXD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.XCHG = { // asserts LOCK when a mem operand is used
		{written={1}, read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}},
		{written={1}, read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}},
		{written={1}, read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}},
		{written={0, 1}, read={0, 1}, writes_mem=true, reads_mem=true},
		{written={0, 1}, read={0, 1}, writes_mem=true, reads_mem=true},
		{written={0, 1}, read={0, 1}, writes_mem=true, reads_mem=true},
		{written={0, 1}, read={0, 1}, writes_mem=true, reads_mem=true},
	},
	.PUSH = {
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true},
	},
	.POP = {
		{written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true},
		{written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true},
		{written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true},
		{written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true},
		{written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true},
	},
	.LEA = { // no memory access: computes effective address only
		{written={0}},
		{written={0}},
		{written={0}},
	},

	// 8.2 Arithmetic Encodings
	.ADD = {
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.ADC = {
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
	},
	.SUB = {
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.SBB = {
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
	},
	.MUL = { // RAX/RDX widths follow operand size (r/m8 -> AX only)
		{read={0}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // r/m8 form: A-register only, no (R)DX
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},
	},
	.IMUL = { // union of forms: 1-op writes RDX:RAX (implicit); 2/3-op writes OP0, no implicit
		{read={0}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 1-op r/m8: AX <- AL*r/m8
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 1-operand form: RDX:RAX <- RAX * r/m
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 1-operand form: RDX:RAX <- RAX * r/m
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 1-operand form: RDX:RAX <- RAX * r/m
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 2-operand form: OP0 *= OP1
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 2-operand form: OP0 *= OP1
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 2-operand form: OP0 *= OP1
		{written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 3-operand form: OP0 = OP1 * imm (OP0 not read)
		{written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 3-operand form: OP0 = OP1 * imm (OP0 not read)
		{written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 3-operand form: OP0 = OP1 * imm (OP0 not read)
		{written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 3-operand form: OP0 = OP1 * imm (OP0 not read)
		{written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 3-operand form: OP0 = OP1 * imm (OP0 not read)
		{written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true},  // 3-operand form: OP0 = OP1 * imm (OP0 not read)
	},
	.DIV = { // RDX:RAX = quotient/remainder; r/m8 uses AX only
		{read={0}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},  // r/m8 form: A-register only, no (R)DX
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.IDIV = { // RDX:RAX = quotient/remainder; r/m8 uses AX only
		{read={0}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},  // r/m8 form: A-register only, no (R)DX
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.INC = { // CF deliberately NOT affected
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.DEC = { // CF deliberately NOT affected
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.NEG = {
		{written={0}, read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.CMP = { // no operand written; flags only
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},

	// 8.3 Logical Encodings
	.AND = {
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	},
	.OR = {
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	},
	.XOR = {
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	},
	.NOT = {
		{written={0}, read={0}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, writes_mem=true, reads_mem=true},
	},
	.TEST = { // no operand written; flags only
		{read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true},
		{read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}},
		{read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true},
	},

	// 8.4 Shift/Rotate Encodings
	.SHL = { // OF defined only for 1-bit count; count==0 leaves flags unchanged
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	},
	.SHR = { // OF defined only for 1-bit count; count==0 leaves flags unchanged
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	},
	.SAR = { // OF defined only for 1-bit count; count==0 leaves flags unchanged
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	},
	.ROL = { // only CF/OF affected; count==0 leaves flags unchanged
		{written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
	},
	.ROR = { // only CF/OF affected; count==0 leaves flags unchanged
		{written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},
	},
	.RCL = {
		{written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
	},
	.RCR = {
		{written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
	},
	.SHLD = {
		{written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
	},
	.SHRD = {
		{written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true},
	},

	// 8.5 Bit Operation Encodings
	.BT = { // ZF unaffected
		{read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
	},
	.BTS = { // ZF unaffected
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.BTR = { // ZF unaffected
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.BTC = { // ZF unaffected
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.BSF = { // destination undefined when source == 0
		{written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true},
	},
	.BSR = { // destination undefined when source == 0
		{written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true},
	},
	.POPCNT = { // ZF per source; CF/OF/SF/AF/PF cleared
		{written={0}, read={1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.LZCNT = {
		{written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
	},
	.TZCNT = {
		{written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
	},

	// 8.6 Control Flow Encodings
	.JMP = { // indirect forms read reg/mem; writes RIP
		{read={0}, side_effects={.CONTROL}},
		{read={0}, side_effects={.CONTROL}},
		{read={0}, reads_mem=true, side_effects={.CONTROL}},
		{read={0}, reads_mem=true, side_effects={.CONTROL}},
		{read={0}, reads_mem=true, side_effects={.CONTROL}},
		{read={0}, reads_mem=true, side_effects={.CONTROL}},
	},
	.JA = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF, .ZF}, side_effects={.CONTROL}},
		{flags_rd={.CF, .ZF}, side_effects={.CONTROL}},
	},
	.JAE = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF}, side_effects={.CONTROL}},
		{flags_rd={.CF}, side_effects={.CONTROL}},
	},
	.JB = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF}, side_effects={.CONTROL}},
		{flags_rd={.CF}, side_effects={.CONTROL}},
	},
	.JBE = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF, .ZF}, side_effects={.CONTROL}},
		{flags_rd={.CF, .ZF}, side_effects={.CONTROL}},
	},
	.JC = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF}, side_effects={.CONTROL}},
		{flags_rd={.CF}, side_effects={.CONTROL}},
	},
	.JE = { // reads flags; writes RIP on taken branch
		{flags_rd={.ZF}, side_effects={.CONTROL}},
		{flags_rd={.ZF}, side_effects={.CONTROL}},
	},
	.JZ = { // reads flags; writes RIP on taken branch
		{flags_rd={.ZF}, side_effects={.CONTROL}},
		{flags_rd={.ZF}, side_effects={.CONTROL}},
	},
	.JG = { // reads flags; writes RIP on taken branch
		{flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},
		{flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},
	},
	.JGE = { // reads flags; writes RIP on taken branch
		{flags_rd={.SF, .OF}, side_effects={.CONTROL}},
		{flags_rd={.SF, .OF}, side_effects={.CONTROL}},
	},
	.JL = { // reads flags; writes RIP on taken branch
		{flags_rd={.SF, .OF}, side_effects={.CONTROL}},
		{flags_rd={.SF, .OF}, side_effects={.CONTROL}},
	},
	.JLE = { // reads flags; writes RIP on taken branch
		{flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},
		{flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},
	},
	.JNA = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF, .ZF}, side_effects={.CONTROL}},
		{flags_rd={.CF, .ZF}, side_effects={.CONTROL}},
	},
	.JNAE = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF}, side_effects={.CONTROL}},
		{flags_rd={.CF}, side_effects={.CONTROL}},
	},
	.JNB = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF}, side_effects={.CONTROL}},
		{flags_rd={.CF}, side_effects={.CONTROL}},
	},
	.JNBE = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF, .ZF}, side_effects={.CONTROL}},
		{flags_rd={.CF, .ZF}, side_effects={.CONTROL}},
	},
	.JNC = { // reads flags; writes RIP on taken branch
		{flags_rd={.CF}, side_effects={.CONTROL}},
		{flags_rd={.CF}, side_effects={.CONTROL}},
	},
	.JNE = { // reads flags; writes RIP on taken branch
		{flags_rd={.ZF}, side_effects={.CONTROL}},
		{flags_rd={.ZF}, side_effects={.CONTROL}},
	},
	.JNZ = { // reads flags; writes RIP on taken branch
		{flags_rd={.ZF}, side_effects={.CONTROL}},
		{flags_rd={.ZF}, side_effects={.CONTROL}},
	},
	.JNG = { // reads flags; writes RIP on taken branch
		{flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},
		{flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},
	},
	.JNGE = { // reads flags; writes RIP on taken branch
		{flags_rd={.SF, .OF}, side_effects={.CONTROL}},
		{flags_rd={.SF, .OF}, side_effects={.CONTROL}},
	},
	.JNL = { // reads flags; writes RIP on taken branch
		{flags_rd={.SF, .OF}, side_effects={.CONTROL}},
		{flags_rd={.SF, .OF}, side_effects={.CONTROL}},
	},
	.JNLE = { // reads flags; writes RIP on taken branch
		{flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},
		{flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},
	},
	.JNO = { // reads flags; writes RIP on taken branch
		{flags_rd={.OF}, side_effects={.CONTROL}},
		{flags_rd={.OF}, side_effects={.CONTROL}},
	},
	.JNP = { // reads flags; writes RIP on taken branch
		{flags_rd={.PF}, side_effects={.CONTROL}},
		{flags_rd={.PF}, side_effects={.CONTROL}},
	},
	.JNS = { // reads flags; writes RIP on taken branch
		{flags_rd={.SF}, side_effects={.CONTROL}},
		{flags_rd={.SF}, side_effects={.CONTROL}},
	},
	.JO = { // reads flags; writes RIP on taken branch
		{flags_rd={.OF}, side_effects={.CONTROL}},
		{flags_rd={.OF}, side_effects={.CONTROL}},
	},
	.JP = { // reads flags; writes RIP on taken branch
		{flags_rd={.PF}, side_effects={.CONTROL}},
		{flags_rd={.PF}, side_effects={.CONTROL}},
	},
	.JPE = { // reads flags; writes RIP on taken branch
		{flags_rd={.PF}, side_effects={.CONTROL}},
		{flags_rd={.PF}, side_effects={.CONTROL}},
	},
	.JPO = { // reads flags; writes RIP on taken branch
		{flags_rd={.PF}, side_effects={.CONTROL}},
		{flags_rd={.PF}, side_effects={.CONTROL}},
	},
	.JS = { // reads flags; writes RIP on taken branch
		{flags_rd={.SF}, side_effects={.CONTROL}},
		{flags_rd={.SF}, side_effects={.CONTROL}},
	},
	.JCXZ = { // reads CX
		{implicit_rd={.RCX}, side_effects={.CONTROL}},
	},
	.JECXZ = { // reads ECX
		{implicit_rd={.RCX}, side_effects={.CONTROL}},
	},
	.JRCXZ = { // reads RCX
		{implicit_rd={.RCX}, side_effects={.CONTROL}},
	},
	.LOOP = {
		{implicit_wr={.RCX}, implicit_rd={.RCX}, side_effects={.CONTROL}},
	},
	.LOOPE = {
		{implicit_wr={.RCX}, implicit_rd={.RCX}, flags_rd={.ZF}, side_effects={.CONTROL}},
	},
	.LOOPNE = {
		{implicit_wr={.RCX}, implicit_rd={.RCX}, flags_rd={.ZF}, side_effects={.CONTROL}},
	},
	.CALL = { // pushes return address
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, side_effects={.CONTROL}},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}},
		{read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}},
	},
	.RET = { // pops return address (+imm16 form adjusts RSP)
		{implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true, side_effects={.CONTROL}},
		{implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true, side_effects={.CONTROL}},
	},
	.IRET = { // pops RIP/CS/RFLAGS (privileged bits conditionally)
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}},
	},
	.IRETD = { // pops RIP/CS/RFLAGS (privileged bits conditionally)
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}},
	},
	.IRETQ = { // pops RIP/CS/RFLAGS (privileged bits conditionally)
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}},
	},
	.INT = { // pushes RFLAGS/CS/RIP; clears TF/IF via gate
		{read={0}, implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}},
	},
	.INT3 = { // pushes RFLAGS/CS/RIP; clears TF/IF via gate
		{implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}},
	},
	.INTO = { // #OF only if OF=1
		{implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}},
	},
	.SYSCALL = { // RCX<-RIP, R11<-RFLAGS; RFLAGS masked by IA32_FMASK
		{implicit_wr={.RCX, .R11}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, side_effects={.INTERRUPT, .CONTROL}},
	},
	.SYSRET = { // RIP<-RCX, RFLAGS<-R11
		{implicit_rd={.RCX, .R11}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, side_effects={.SERIALIZING, .INTERRUPT, .PRIVILEGED, .CONTROL}},
	},
	.SYSENTER = { // privileged; RSP/RIP from MSRs
		{implicit_wr={.RSP}, flags_wr={.IF}, side_effects={.INTERRUPT, .CONTROL}},
	},
	.SYSEXIT = { // privileged; RSP<-RDX/RCX, RIP<-RCX/RDX
		{implicit_wr={.RSP}, implicit_rd={.RCX, .RDX}, side_effects={.SERIALIZING, .INTERRUPT, .PRIVILEGED, .CONTROL}},
	},

	// 8.7 Conditional Set/Move Encodings
	.SETA = {
		{written={0}, flags_rd={.CF, .ZF}, writes_mem=true},
	},
	.SETAE = {
		{written={0}, flags_rd={.CF}, writes_mem=true},
	},
	.SETB = {
		{written={0}, flags_rd={.CF}, writes_mem=true},
	},
	.SETBE = {
		{written={0}, flags_rd={.CF, .ZF}, writes_mem=true},
	},
	.SETC = {
		{written={0}, flags_rd={.CF}, writes_mem=true},
	},
	.SETE = {
		{written={0}, flags_rd={.ZF}, writes_mem=true},
	},
	.SETG = {
		{written={0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true},
	},
	.SETGE = {
		{written={0}, flags_rd={.SF, .OF}, writes_mem=true},
	},
	.SETL = {
		{written={0}, flags_rd={.SF, .OF}, writes_mem=true},
	},
	.SETLE = {
		{written={0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true},
	},
	.SETNA = {
		{written={0}, flags_rd={.CF, .ZF}, writes_mem=true},
	},
	.SETNAE = {
		{written={0}, flags_rd={.CF}, writes_mem=true},
	},
	.SETNB = {
		{written={0}, flags_rd={.CF}, writes_mem=true},
	},
	.SETNBE = {
		{written={0}, flags_rd={.CF, .ZF}, writes_mem=true},
	},
	.SETNC = {
		{written={0}, flags_rd={.CF}, writes_mem=true},
	},
	.SETNE = {
		{written={0}, flags_rd={.ZF}, writes_mem=true},
	},
	.SETNG = {
		{written={0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true},
	},
	.SETNGE = {
		{written={0}, flags_rd={.SF, .OF}, writes_mem=true},
	},
	.SETNL = {
		{written={0}, flags_rd={.SF, .OF}, writes_mem=true},
	},
	.SETNLE = {
		{written={0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true},
	},
	.SETNO = {
		{written={0}, flags_rd={.OF}, writes_mem=true},
	},
	.SETNP = {
		{written={0}, flags_rd={.PF}, writes_mem=true},
	},
	.SETNS = {
		{written={0}, flags_rd={.SF}, writes_mem=true},
	},
	.SETNZ = {
		{written={0}, flags_rd={.ZF}, writes_mem=true},
	},
	.SETO = {
		{written={0}, flags_rd={.OF}, writes_mem=true},
	},
	.SETP = {
		{written={0}, flags_rd={.PF}, writes_mem=true},
	},
	.SETPE = {
		{written={0}, flags_rd={.PF}, writes_mem=true},
	},
	.SETPO = {
		{written={0}, flags_rd={.PF}, writes_mem=true},
	},
	.SETS = {
		{written={0}, flags_rd={.SF}, writes_mem=true},
	},
	.SETZ = {
		{written={0}, flags_rd={.ZF}, writes_mem=true},
	},
	.CMOVA = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
	},
	.CMOVAE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
	},
	.CMOVB = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
	},
	.CMOVBE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
	},
	.CMOVC = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
	},
	.CMOVE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
	},
	.CMOVG = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
	},
	.CMOVGE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
	},
	.CMOVL = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
	},
	.CMOVLE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
	},
	.CMOVNA = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
	},
	.CMOVNAE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
	},
	.CMOVNB = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
	},
	.CMOVNBE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true},
	},
	.CMOVNC = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.CF}, reads_mem=true},
	},
	.CMOVNE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
	},
	.CMOVNG = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
	},
	.CMOVNGE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
	},
	.CMOVNL = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true},
	},
	.CMOVNLE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},
	},
	.CMOVNO = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.OF}, reads_mem=true},
	},
	.CMOVNP = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
	},
	.CMOVNS = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.SF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF}, reads_mem=true},
	},
	.CMOVNZ = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
	},
	.CMOVO = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.OF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.OF}, reads_mem=true},
	},
	.CMOVP = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
	},
	.CMOVPE = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
	},
	.CMOVPO = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.PF}, reads_mem=true},
	},
	.CMOVS = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.SF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.SF}, reads_mem=true},
	},
	.CMOVZ = { // conditional write of OP0
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_rd={.ZF}, reads_mem=true},
	},

	// 8.8 String Operation Encodings
	.MOVS = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},
	.MOVSB = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},
	.MOVSW = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},
	.MOVSD = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
		// SSE variants
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVSQ = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},
	.CMPS = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.CMPSB = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.CMPSW = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.CMPSD = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
		// may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CMPSQ = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.SCAS = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.SCASB = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.SCASW = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.SCASD = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.SCASQ = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},
	},
	.LODS = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},
	},
	.LODSB = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},
	},
	.LODSW = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},
	},
	.LODSD = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},
	},
	.LODSQ = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},
	},
	.STOS = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},
	.STOSB = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},
	.STOSW = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},
	.STOSD = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},
	.STOSQ = { // REP/REPZ/REPNZ forms read+write RCX
		{implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true},
	},

	// 8.9 Flag Operation Encodings
	.CLC = {
		{flags_wr={.CF}},
	},
	.STC = {
		{flags_wr={.CF}},
	},
	.CMC = {
		{flags_wr={.CF}, flags_rd={.CF}},
	},
	.CLD = {
		{flags_wr={.DF}},
	},
	.STD = {
		{flags_wr={.DF}},
	},
	.CLI = {
		{flags_wr={.IF}},
	},
	.STI = {
		{flags_wr={.IF}},
	},
	.LAHF = { // AH <- flags
		{implicit_wr={.RAX}, flags_rd={.CF, .PF, .AF, .ZF, .SF}},
	},
	.SAHF = { // flags <- AH
		{implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF}},
	},
	.PUSHF = {
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true},
	},
	.PUSHFD = {
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true},
	},
	.PUSHFQ = {
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true},
	},
	.POPF = {
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true},
	},
	.POPFD = {
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true},
	},
	.POPFQ = {
		{implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true},
	},

	// 8.10 Miscellaneous Encodings
	.NOP = { // no register/flag/memory clobber
		{},
		{},
		{},
		{},
	},
	.HLT = { // no register/flag/memory clobber
		{side_effects={.HALT, .PRIVILEGED}},
	},
	.WAIT = { // waits on pending x87 exception
		{implicit_rd={.FPU_SW}},
	},
	.LOCK = { // no register/flag/memory clobber
		{side_effects={.FENCE}},
	},
	.UD0 = { // no register/flag/memory clobber
		{side_effects={.TRAP}},
	},
	.UD1 = { // no register/flag/memory clobber
		{side_effects={.TRAP}},
	},
	.UD2 = { // no register/flag/memory clobber
		{side_effects={.TRAP}},
	},
	.CPUID = {
		{implicit_wr={.RAX, .RBX, .RCX, .RDX}, implicit_rd={.RAX, .RCX}, side_effects={.SERIALIZING}},
	},
	.RDTSC = {
		{implicit_wr={.RAX, .RDX}},
	},
	.RDTSCP = {
		{implicit_wr={.RAX, .RCX, .RDX}},
	},
	.RDPMC = {
		{implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}},
	},
	.XGETBV = {
		{implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}},
	},
	.XSETBV = { // privileged; writes XCR[ECX]
		{implicit_rd={.RAX, .RCX, .RDX}},
	},
	.CBW = {
		{implicit_wr={.RAX}, implicit_rd={.RAX}},
	},
	.CWDE = {
		{implicit_wr={.RAX}, implicit_rd={.RAX}},
	},
	.CDQE = {
		{implicit_wr={.RAX}, implicit_rd={.RAX}},
	},
	.CWD = {
		{implicit_wr={.RDX}, implicit_rd={.RAX}},
	},
	.CDQ = {
		{implicit_wr={.RDX}, implicit_rd={.RAX}},
	},
	.CQO = {
		{implicit_wr={.RDX}, implicit_rd={.RAX}},
	},

	// 8.11 BMI/ADX Encodings
	.ANDN = {
		{written={0}, read={1, 2}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
		{written={0}, read={1, 2}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
	},
	.BEXTR = {
		{written={0}, read={1, 2}, flags_wr={.CF, .ZF, .OF}, flags_undef={.PF, .AF, .SF}, reads_mem=true},
		{written={0}, read={1, 2}, flags_wr={.CF, .ZF, .OF}, flags_undef={.PF, .AF, .SF}, reads_mem=true},
	},
	.BLSI = {
		{written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
	},
	.BLSMSK = {
		{written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
	},
	.BLSR = {
		{written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
	},
	.BZHI = {
		{written={0}, read={1, 2}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
		{written={0}, read={1, 2}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true},
	},
	.PDEP = { // no flags affected
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PEXT = { // no flags affected
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.RORX = { // no flags affected
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.SARX = { // no flags affected (unlike SAR/SHL/SHR)
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.SHLX = { // no flags affected (unlike SAR/SHL/SHR)
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.SHRX = { // no flags affected (unlike SAR/SHL/SHR)
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.MULX = { // no flags affected; implicit multiplicand in rDX
		{written={0, 1}, read={2}, implicit_rd={.RDX}, reads_mem=true},
		{written={0, 1}, read={2}, implicit_rd={.RDX}, reads_mem=true},
	},
	.ADCX = { // only CF (chains with ADCX)
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_rd={.CF}, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.CF}, flags_rd={.CF}, reads_mem=true},
	},
	.ADOX = { // only OF (chains with ADOX)
		{written={0}, read={0, 1}, flags_wr={.OF}, flags_rd={.OF}, reads_mem=true},
		{written={0}, read={0, 1}, flags_wr={.OF}, flags_rd={.OF}, reads_mem=true},
	},

	// 8.12 SSE Encodings
	.MOVAPS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVUPS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVAPD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVUPD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVSS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVDQA = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVDQU = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVQ = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.MOVD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVLPS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVHPS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVLPD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVHPD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVLHPS = {
		{written={0}, read={1}},
	},
	.MOVHLPS = {
		{written={0}, read={1}},
	},
	.MOVMSKPS = { // destination is a GPR
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.MOVMSKPD = { // destination is a GPR
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.MOVNTPS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVNTPD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVNTDQ = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.MOVNTDQA = {
		{written={0}, read={1}, reads_mem=true},
	},
	.ADDPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.ADDPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.ADDSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.ADDSD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.SUBPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.SUBPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.SUBSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.SUBSD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MULPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MULPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MULSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MULSD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.DIVPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.DIVPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.DIVSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.DIVSD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.SQRTPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.SQRTPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.SQRTSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.SQRTSD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.RCPPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.RCPSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.RSQRTPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.RSQRTSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MAXPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MAXPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MAXSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MAXSD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MINPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MINPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MINSS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MINSD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.ANDPS = {
		{written={0}, read={1}, reads_mem=true},
	},
	.ANDPD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.ANDNPS = {
		{written={0}, read={1}, reads_mem=true},
	},
	.ANDNPD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.ORPS = {
		{written={0}, read={1}, reads_mem=true},
	},
	.ORPD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.XORPS = {
		{written={0}, read={1}, reads_mem=true},
	},
	.XORPD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.CMPPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CMPPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CMPSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.COMISS = { // OF/SF/AF cleared
		{read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true},
	},
	.COMISD = { // OF/SF/AF cleared
		{read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true},
	},
	.UCOMISS = { // OF/SF/AF cleared
		{read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true},
	},
	.UCOMISD = { // OF/SF/AF cleared
		{read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true},
	},
	.SHUFPS = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.SHUFPD = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.UNPCKLPS = {
		{written={0}, read={1}, reads_mem=true},
	},
	.UNPCKHPS = {
		{written={0}, read={1}, reads_mem=true},
	},
	.UNPCKLPD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.UNPCKHPD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.CVTPS2PD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTPD2PS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTSS2SD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTSD2SS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTPS2DQ = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTPD2DQ = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTDQ2PS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTDQ2PD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTSS2SI = { // destination is a GPR
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTSD2SI = { // destination is a GPR
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTSI2SS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTSI2SD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTTPS2DQ = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTTPD2DQ = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTTSS2SI = { // destination is a GPR
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.CVTTSD2SI = { // destination is a GPR
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.PADDB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PADDW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PADDD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PADDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSUBB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSUBW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSUBD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSUBQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PADDSB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PADDSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PADDUSB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PADDUSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSUBSB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSUBSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSUBUSB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSUBUSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMULLW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMULHW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMULHUW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMULUDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMADDWD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PAND = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PANDN = {
		{written={0}, read={1}, reads_mem=true},
	},
	.POR = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PXOR = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSLLW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.PSLLD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.PSLLQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.PSRLW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.PSRLD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.PSRLQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.PSRAW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.PSRAD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.PCMPEQB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PCMPEQW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PCMPEQD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PCMPGTB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PCMPGTW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PCMPGTD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PACKSSWB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PACKSSDW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PACKUSWB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PUNPCKLBW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PUNPCKLWD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PUNPCKLDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PUNPCKLQDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PUNPCKHBW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PUNPCKHWD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PUNPCKHDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PUNPCKHQDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSHUFD = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PSHUFHW = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PSHUFLW = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PSHUFW = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PEXTRW = { // destination may be memory
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.PINSRW = {
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PMOVMSKB = { // destination is a GPR
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.PAVGB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PAVGW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMAXUB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMAXSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMINUB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMINSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSADBW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.MASKMOVDQU = { // byte-masked store to DS:[rDI]
		{read={0, 1}, implicit_rd={.RDI}, flags_rd={.DF}, writes_mem=true},
	},
	.LFENCE = { // ordering/hint; no clobber
		{side_effects={.FENCE, .SERIALIZING}},
	},
	.SFENCE = { // ordering/hint; no clobber
		{side_effects={.FENCE}},
	},
	.MFENCE = { // ordering/hint; no clobber
		{side_effects={.FENCE}},
	},
	.PAUSE = { // ordering/hint; no clobber
		{side_effects={.HINT}},
	},
	.CLFLUSH = { // flushes cache line for the addressed byte
		{read={0}, reads_mem=true, side_effects={.CACHE}},
	},
	.ADDSUBPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.ADDSUBPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.HADDPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.HADDPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.HSUBPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.HSUBPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.MOVDDUP = {
		{written={0}, read={1}, reads_mem=true},
	},
	.MOVSLDUP = {
		{written={0}, read={1}, reads_mem=true},
	},
	.MOVSHDUP = {
		{written={0}, read={1}, reads_mem=true},
	},
	.LDDQU = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSHUFB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PHADDW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PHADDD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PHADDSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PHSUBW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PHSUBD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PHSUBSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMADDUBSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMULHRSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSIGNB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSIGNW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PSIGND = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PABSB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PABSW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PABSD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PALIGNR = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.BLENDPS = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.BLENDPD = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.BLENDVPS = {
		{written={0}, read={1}, implicit_rd={.XMM0}, reads_mem=true},
	},
	.BLENDVPD = {
		{written={0}, read={1}, implicit_rd={.XMM0}, reads_mem=true},
	},
	.PBLENDW = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PBLENDVB = {
		{written={0}, read={1}, implicit_rd={.XMM0}, reads_mem=true},
	},
	.DPPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.DPPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.EXTRACTPS = { // destination may be memory
		{written={0}, read={1}, writes_mem=true},
	},
	.INSERTPS = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.MPSADBW = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PACKUSDW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PEXTRB = { // destination may be memory
		{written={0}, read={1}, writes_mem=true},
	},
	.PEXTRD = { // destination may be memory
		{written={0}, read={1}, writes_mem=true},
	},
	.PEXTRQ = { // destination may be memory
		{written={0}, read={1}, writes_mem=true},
	},
	.PHMINPOSUW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PINSRB = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PINSRD = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PINSRQ = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.PMAXSB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMAXSD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMAXUW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMAXUD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMINSB = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMINSD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMINUW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMINUD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVSXBW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVSXBD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVSXBQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVSXWD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVSXWQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVSXDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVZXBW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVZXBD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVZXBQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVZXWD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVZXWQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMOVZXDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMULDQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PMULLD = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PTEST = { // ZF from AND, CF from ANDN; others cleared
		{read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
	},
	.ROUNDPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.ROUNDPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.ROUNDSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.ROUNDSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.PCMPEQQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.CRC32 = { // accumulates CRC into OP0; no flags
		{written={0}, read={0, 1}, reads_mem=true},
		{written={0}, read={0, 1}, reads_mem=true},
		{written={0}, read={0, 1}, reads_mem=true},
		{written={0}, read={0, 1}, reads_mem=true},
		{written={0}, read={0, 1}, reads_mem=true},
	},
	.PCMPESTRI = { // ECX<-index; CF/ZF/SF/OF set, AF/PF cleared ; reads EAX/EDX lengths
		{implicit_wr={.RCX}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.PCMPESTRM = { // XMM0<-mask; CF/ZF/SF/OF set, AF/PF cleared ; reads EAX/EDX lengths
		{implicit_wr={.XMM0}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.PCMPISTRI = { // ECX<-index; CF/ZF/SF/OF set, AF/PF cleared
		{implicit_wr={.RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.PCMPISTRM = { // XMM0<-mask; CF/ZF/SF/OF set, AF/PF cleared
		{implicit_wr={.XMM0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.PCMPGTQ = {
		{written={0}, read={1}, reads_mem=true},
	},
	.PCLMULQDQ = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.AESDEC = {
		{written={0}, read={1}, reads_mem=true},
	},
	.AESDECLAST = {
		{written={0}, read={1}, reads_mem=true},
	},
	.AESENC = {
		{written={0}, read={1}, reads_mem=true},
	},
	.AESENCLAST = {
		{written={0}, read={1}, reads_mem=true},
	},
	.AESIMC = {
		{written={0}, read={1}, reads_mem=true},
	},
	.AESKEYGENASSIST = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.SHA1MSG1 = {
		{written={0}, read={1}, reads_mem=true},
	},
	.SHA1MSG2 = {
		{written={0}, read={1}, reads_mem=true},
	},
	.SHA1NEXTE = {
		{written={0}, read={1}, reads_mem=true},
	},
	.SHA1RNDS4 = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.SHA256MSG1 = {
		{written={0}, read={1}, reads_mem=true},
	},
	.SHA256MSG2 = {
		{written={0}, read={1}, reads_mem=true},
	},
	.SHA256RNDS2 = {
		{written={0}, read={1}, implicit_rd={.XMM0}, reads_mem=true},
	},

	// 8.13 AVX/AVX2 Encodings
	.VADDPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VADDPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VADDSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VADDSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSUBPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSUBPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSUBSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSUBSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMULPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMULPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMULSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMULSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VDIVPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VDIVPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VDIVSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VDIVSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSQRTPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSQRTPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSQRTSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSQRTSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRCPPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRCPSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRSQRTPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRSQRTSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMAXPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMAXPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMAXSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMAXSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMINPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMINPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMINSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VMINSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VANDPS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VANDPD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VANDNPS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VANDNPD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VORPS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VORPD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VXORPS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VXORPD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VCMPPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCMPPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCMPSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCMPSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCOMISS = { // OF/SF/AF cleared
		{read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true},
	},
	.VCOMISD = { // OF/SF/AF cleared
		{read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true},
	},
	.VUCOMISS = { // OF/SF/AF cleared
		{read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true},
	},
	.VUCOMISD = { // OF/SF/AF cleared
		{read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true},
	},
	.VSHUFPS = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VSHUFPD = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VUNPCKLPS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VUNPCKHPS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VUNPCKLPD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VUNPCKHPD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VBLENDPS = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VBLENDPD = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VBLENDVPS = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VBLENDVPD = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VDPPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VDPPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VROUNDPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VROUNDPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VROUNDSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VROUNDSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VEXTRACTPS = { // destination may be memory
		{written={0}, read={1}, writes_mem=true},
	},
	.VINSERTPS = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VMOVAPS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVUPS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVAPD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVUPD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVSS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VMOVSD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VMOVDQA = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVDQU = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVQ = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VMOVD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVLPS = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVHPS = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVLPD = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVHPD = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVLHPS = {
		{written={0}, read={1, 2}},
	},
	.VMOVHLPS = {
		{written={0}, read={1, 2}},
	},
	.VMOVMSKPS = { // destination is a GPR
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VMOVMSKPD = { // destination is a GPR
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VMOVNTPS = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVNTPD = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVNTDQ = {
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.VMOVNTDQA = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VADDSUBPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VADDSUBPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VHADDPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VHADDPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VHSUBPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VHSUBPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VLDDQU = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VMOVDDUP = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VMOVSLDUP = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VMOVSHDUP = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPCMPESTRI = { // ECX<-index; CF/ZF/SF/OF set, AF/PF cleared ; reads EAX/EDX lengths
		{implicit_wr={.RCX}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.VPCMPESTRM = { // XMM0<-mask; CF/ZF/SF/OF set, AF/PF cleared ; reads EAX/EDX lengths
		{implicit_wr={.XMM0}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.VPCMPISTRI = { // ECX<-index; CF/ZF/SF/OF set, AF/PF cleared
		{implicit_wr={.RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.VPCMPISTRM = { // XMM0<-mask; CF/ZF/SF/OF set, AF/PF cleared
		{implicit_wr={.XMM0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},
	},
	.VPBROADCASTB = {
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPBROADCASTW = {
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPBROADCASTD = {
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPBROADCASTQ = {
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VCVTPS2PD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTPD2PS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTSS2SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTSD2SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTPS2DQ = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTPD2DQ = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTDQ2PS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTDQ2PD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTSS2SI = { // destination is a GPR
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTSD2SI = { // destination is a GPR
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTSI2SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTSI2SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTTPS2DQ = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTTPD2DQ = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTTSS2SI = { // destination is a GPR
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTTSD2SI = { // destination is a GPR
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VPADDB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPADDW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPADDD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPADDQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSUBB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSUBW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSUBD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSUBQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMULLW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMULHW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMULHUW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMULUDQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMADDWD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPAND = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPANDN = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPOR = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPXOR = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSLLW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VPSLLD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VPSLLQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VPSRLW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VPSRLD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VPSRLQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VPSRAW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VPSRAD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}},
	},
	.VPCMPEQB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPEQW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPEQD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPEQQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPGTB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPGTW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPGTD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPGTQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPACKSSWB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPACKSSDW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPACKUSWB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPACKUSDW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPUNPCKLBW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPUNPCKLWD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPUNPCKLDQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPUNPCKLQDQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPUNPCKHBW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPUNPCKHWD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPUNPCKHDQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPUNPCKHQDQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSHUFD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSHUFHW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSHUFLW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPEXTRB = { // destination may be memory
		{written={0}, read={1}, writes_mem=true},
	},
	.VPEXTRW = { // destination may be memory
		{written={0}, read={1}},
		{written={0}, read={1}, writes_mem=true},
	},
	.VPEXTRD = { // destination may be memory
		{written={0}, read={1}, writes_mem=true},
	},
	.VPEXTRQ = { // destination may be memory
		{written={0}, read={1}, writes_mem=true},
	},
	.VPINSRB = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPINSRW = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPINSRD = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPINSRQ = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPMOVMSKB = { // destination is a GPR
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPTEST = { // ZF from AND, CF from ANDN; others cleared
		{read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
	},
	.VPSHUFB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPHADDW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPHADDD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPHADDSW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPHSUBW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPHSUBD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPHSUBSW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMADDUBSW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMULHRSW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSIGNB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSIGNW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSIGND = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPABSB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPABSW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPABSD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPALIGNR = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPBLENDW = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPBLENDVB = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VMPSADBW = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPHMINPOSUW = {
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMAXSB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMAXSD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMAXUW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMAXUD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMINSB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMINSD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMINUW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMINUD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMOVSXBW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSXBD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSXBQ = {
		{written={0}, read={1}},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSXWD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSXWQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSXDQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVZXBW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVZXBD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVZXBQ = {
		{written={0}, read={1}},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVZXWD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVZXWQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVZXDQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMULDQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMULLD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VMASKMOVDQU = { // byte-masked store to DS:[rDI]
		{read={0, 1}, implicit_rd={.RDI}, flags_rd={.DF}, writes_mem=true},
	},
	.VPCLMULQDQ = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VAESDEC = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VAESDECLAST = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VAESENC = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VAESENCLAST = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VAESIMC = {
		{written={0}, read={1}, reads_mem=true},
	},
	.VAESKEYGENASSIST = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VBROADCASTSS = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VBROADCASTSD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}},
	},
	.VBROADCASTF128 = {
		{written={0}, read={1}, reads_mem=true},
	},
	.VEXTRACTF128 = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
	},
	.VINSERTF128 = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPERM2F128 = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VMASKMOVPS = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
	},
	.VMASKMOVPD = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
	},
	.VTESTPS = { // ZF from AND, CF from ANDN; others cleared
		{read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
	},
	.VTESTPD = { // ZF from AND, CF from ANDN; others cleared
		{read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
		{read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true},
	},
	.VZEROALL = { // zeroes the entire vector register file (YMM/ZMM)
		{implicit_wr={.VECTOR}},
	},
	.VZEROUPPER = { // zeroes bits [MAXVL-1:128] of every vector register
		{implicit_wr={.VECTOR}},
	},
	.VBROADCASTI128 = {
		{written={0}, read={1}, reads_mem=true},
	},
	.VEXTRACTI128 = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
	},
	.VINSERTI128 = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPERM2I128 = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPERMD = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMPS = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMQ = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMPD = {
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPBLENDD = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPSLLVD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSLLVQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSRLVD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSRLVQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSRAVD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMASKMOVD = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
	},
	.VPMASKMOVQ = {
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, writes_mem=true, reads_mem=true},
	},
	.VGATHERDPS = { // mask operand (OP2) is zeroed as elements are gathered
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
	},
	.VGATHERDPD = { // mask operand (OP2) is zeroed as elements are gathered
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
	},
	.VGATHERQPS = { // mask operand (OP2) is zeroed as elements are gathered
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
	},
	.VGATHERQPD = { // mask operand (OP2) is zeroed as elements are gathered
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
	},
	.VPGATHERDD = { // mask operand (OP2) is zeroed as elements are gathered
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
	},
	.VPGATHERDQ = { // mask operand (OP2) is zeroed as elements are gathered
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
	},
	.VPGATHERQD = { // mask operand (OP2) is zeroed as elements are gathered
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
	},
	.VPGATHERQQ = { // mask operand (OP2) is zeroed as elements are gathered
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
		{written={0, 2}, read={0, 1, 2}, reads_mem=true},
	},

	// 8.14 FMA Encodings
	.VFMADD132PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD213PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD231PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD132PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD213PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD231PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD132SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD213SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD231SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD132SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD213SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADD231SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB132PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB213PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB231PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB132PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB213PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB231PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB132SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB213SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB231SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB132SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB213SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUB231SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD132PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD213PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD231PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD132PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD213PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD231PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD132SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD213SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD231SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD132SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD213SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMADD231SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB132PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB213PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB231PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB132PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB213PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB231PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB132SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB213SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB231SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB132SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB213SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFNMSUB231SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADDSUB132PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADDSUB213PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADDSUB231PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADDSUB132PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADDSUB213PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMADDSUB231PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUBADD132PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUBADD213PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUBADD231PS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUBADD132PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUBADD213PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFMSUBADD231PD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTPH2PS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VCVTPS2PH = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, writes_mem=true, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, writes_mem=true, reads_mem=true},
	},

	// 8.15 AVX-512 Encodings
	.VMOVDQA32 = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VMOVDQA64 = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VMOVDQU8 = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VMOVDQU16 = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VMOVDQU32 = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VMOVDQU64 = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPBLENDMB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPBLENDMW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPBLENDMD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPBLENDMQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VBLENDMPS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VBLENDMPD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPB = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPUB = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPW = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPUW = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPD = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPUD = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPQ = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCMPUQ = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPTESTMB = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPTESTMW = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPTESTMD = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPTESTMQ = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPTESTNMB = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPTESTNMW = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPTESTNMD = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPTESTNMQ = { // result written to an opmask register (k1), not EFLAGS
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPCOMPRESSD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPCOMPRESSQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VCOMPRESSPS = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VCOMPRESSPD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPEXPANDD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPEXPANDQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VEXPANDPS = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VEXPANDPD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPCONFLICTD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPCONFLICTQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPLZCNTD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPLZCNTQ = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPERMI2B = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMI2W = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMI2D = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMI2Q = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMI2PS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMI2PD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMT2B = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMT2W = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMT2D = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMT2Q = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMT2PS = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMT2PD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPERMW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPMOVB2M = { // sign bits -> opmask register
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPMOVW2M = { // sign bits -> opmask register
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPMOVD2M = { // sign bits -> opmask register
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPMOVQ2M = { // sign bits -> opmask register
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPMOVM2B = {
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPMOVM2W = {
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPMOVM2D = {
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPMOVM2Q = {
		{written={0}, read={1}},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.VPMOVQB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSQB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVUSQB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVQW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSQW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVUSQW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVQD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSQD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVUSQD = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVDB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSDB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVUSDB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVDW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSDW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVUSDW = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVWB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVSWB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPMOVUSWB = {
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VPROLD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPROLQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPROLVD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPROLVQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPRORD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPRORQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPRORVD = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPRORVQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSCATTERDD = { // opmask k1 is consumed and cleared per element
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
	},
	.VPSCATTERDQ = { // opmask k1 is consumed and cleared per element
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
	},
	.VPSCATTERQD = { // opmask k1 is consumed and cleared per element
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
	},
	.VPSCATTERQQ = { // opmask k1 is consumed and cleared per element
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
	},
	.VSCATTERDPS = { // opmask k1 is consumed and cleared per element
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
	},
	.VSCATTERDPD = { // opmask k1 is consumed and cleared per element
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
	},
	.VSCATTERQPS = { // opmask k1 is consumed and cleared per element
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
	},
	.VSCATTERQPD = { // opmask k1 is consumed and cleared per element
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
		{read={0, 1}, writes_mem=true},
	},
	.VPSRAVQ = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSRAVW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSLLVW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VPSRLVW = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.VRANGEPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRANGEPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRANGESS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRANGESD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VREDUCEPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VREDUCEPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VREDUCESS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VREDUCESD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRNDSCALEPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRNDSCALEPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRNDSCALESS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRNDSCALESD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRSQRT14PS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRSQRT14PD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRSQRT14SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRSQRT14SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRCP14PS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRCP14PD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRCP14SS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VRCP14SD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSCALEFPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSCALEFPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSCALEFSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VSCALEFSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VGETEXPPS = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VGETEXPPD = { // may set MXCSR exception/status bits
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VGETEXPSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VGETEXPSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VGETMANTPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VGETMANTPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VGETMANTSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VGETMANTSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFIXUPIMMPS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFIXUPIMMPD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFIXUPIMMSS = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFIXUPIMMSD = { // may set MXCSR exception/status bits
		{written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true},
	},
	.VFPCLASSPS = { // class predicate written to an opmask register
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VFPCLASSPD = { // class predicate written to an opmask register
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
		{written={0}, read={1}, reads_mem=true},
	},
	.VFPCLASSSS = { // class predicate written to an opmask register
		{written={0}, read={1}, reads_mem=true},
	},
	.VFPCLASSSD = { // class predicate written to an opmask register
		{written={0}, read={1}, reads_mem=true},
	},
	.VALIGNQ = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VALIGND = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VDBPSADBW = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPTERNLOGD = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPTERNLOGQ = {
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
		{written={0}, read={1, 2, 3}, reads_mem=true},
	},
	.VPMULTISHIFTQB = {
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
		{written={0}, read={1, 2}, reads_mem=true},
	},
	.KADDW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KADDB = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KADDQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KADDD = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KANDW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KANDB = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KANDQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KANDD = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KANDNW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KANDNB = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KANDNQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KANDND = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KMOVW = { // opmask <-> GPR/mem/opmask
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.KMOVB = { // opmask <-> GPR/mem/opmask
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.KMOVQ = { // opmask <-> GPR/mem/opmask
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.KMOVD = { // opmask <-> GPR/mem/opmask
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}},
		{written={0}, read={1}},
	},
	.KNOTW = { // opmask register operation
		{written={0}, read={1}},
	},
	.KNOTB = { // opmask register operation
		{written={0}, read={1}},
	},
	.KNOTQ = { // opmask register operation
		{written={0}, read={1}},
	},
	.KNOTD = { // opmask register operation
		{written={0}, read={1}},
	},
	.KORW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KORB = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KORQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KORD = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KORTESTW = { // sets ZF/CF from mask test
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.KORTESTB = { // sets ZF/CF from mask test
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.KORTESTQ = { // sets ZF/CF from mask test
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.KORTESTD = { // sets ZF/CF from mask test
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.KSHIFTLW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KSHIFTLB = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KSHIFTLQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KSHIFTLD = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KSHIFTRW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KSHIFTRB = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KSHIFTRQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KSHIFTRD = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KTESTW = { // sets ZF/CF from mask test
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.KTESTB = { // sets ZF/CF from mask test
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.KTESTQ = { // sets ZF/CF from mask test
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.KTESTD = { // sets ZF/CF from mask test
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.KUNPCKBW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KUNPCKWD = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KUNPCKDQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KXNORW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KXNORB = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KXNORQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KXNORD = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KXORW = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KXORB = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KXORQ = { // opmask register operation
		{written={0}, read={1, 2}},
	},
	.KXORD = { // opmask register operation
		{written={0}, read={1, 2}},
	},

	// 8.16 x87 FPU Encodings
	.FADD = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FADDP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FIADD = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
	},
	.FSUB = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FSUBP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FISUB = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
	},
	.FSUBR = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FSUBRP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FISUBR = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
	},
	.FMUL = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FMULP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FIMUL = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
	},
	.FDIV = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FDIVP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FIDIV = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
	},
	.FDIVR = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FDIVRP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FIDIVR = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
	},
	.FSQRT = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FABS = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FCHS = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FPREM = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FPREM1 = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FRNDINT = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FSCALE = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FXTRACT = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FXAM = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FLD = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FILD = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
	},
	.FBLD = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
	},
	.FST = { // store (FSTP/FISTP/FBSTP pop the stack)
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FSTP = { // store (FSTP/FISTP/FBSTP pop the stack)
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FIST = { // store (FSTP/FISTP/FBSTP pop the stack)
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FISTP = { // store (FSTP/FISTP/FBSTP pop the stack)
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FISTTP = { // store (FSTP/FISTP/FBSTP pop the stack)
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FBSTP = { // store (FSTP/FISTP/FBSTP pop the stack)
		{implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FXCH = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FCMOVB = { // conditional x87 move; reads EFLAGS
		{implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF}},
	},
	.FCMOVE = { // conditional x87 move; reads EFLAGS
		{implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.ZF}},
	},
	.FCMOVBE = { // conditional x87 move; reads EFLAGS
		{implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF, .ZF}},
	},
	.FCMOVU = { // conditional x87 move; reads EFLAGS
		{implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.PF}},
	},
	.FCMOVNB = { // conditional x87 move; reads EFLAGS
		{implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF}},
	},
	.FCMOVNE = { // conditional x87 move; reads EFLAGS
		{implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.ZF}},
	},
	.FCMOVNBE = { // conditional x87 move; reads EFLAGS
		{implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF, .ZF}},
	},
	.FCMOVNU = { // conditional x87 move; reads EFLAGS
		{implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.PF}},
	},
	.FCOM = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // m32
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // m64
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},                  // ST(i)
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},                  // no operand (ST(1))
	},
	.FCOMP = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // m32
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // m64
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},                  // ST(i)
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},                  // no operand (ST(1))
	},
	.FCOMPP = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FICOM = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
	},
	.FICOMP = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},
	},
	.FCOMI = { // compares ST(0):ST(i) into EFLAGS
		{implicit_rd={.FPU_ST}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}},
	},
	.FCOMIP = { // compares ST(0):ST(i) into EFLAGS
		{implicit_rd={.FPU_ST}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}},
	},
	.FUCOMI = { // compares ST(0):ST(i) into EFLAGS
		{implicit_rd={.FPU_ST}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}},
	},
	.FUCOMIP = { // compares ST(0):ST(i) into EFLAGS
		{implicit_rd={.FPU_ST}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}},
	},
	.FUCOM = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FUCOMP = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FUCOMPP = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FTST = { // sets x87 condition codes C0-C3 (status word), not EFLAGS
		{implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FLDZ = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FLD1 = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FLDPI = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FLDL2T = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FLDL2E = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FLDLG2 = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FLDLN2 = { // push onto x87 stack
		{implicit_wr={.FPU_ST, .FPU_SW}},
	},
	.FSIN = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FCOS = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FSINCOS = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FPTAN = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FPATAN = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.F2XM1 = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FYL2X = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FYL2XP1 = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FINIT = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FNINIT = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FINCSTP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FDECSTP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FFREE = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FFREEP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FNOP = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FWAIT = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FCLEX = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FNCLEX = { // x87 arithmetic: updates ST(0) and status word C1
		{implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},
	},
	.FSTCW = { // stores x87 (and SSE) state to memory
		{implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FNSTCW = { // stores x87 (and SSE) state to memory
		{implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FLDCW = { // loads x87 (and SSE) state from memory
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
	},
	.FSTENV = { // stores x87 (and SSE) state to memory
		{implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FNSTENV = { // stores x87 (and SSE) state to memory
		{implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FLDENV = { // loads x87 (and SSE) state from memory
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
	},
	.FSAVE = { // stores x87 (and SSE) state to memory
		{implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FNSAVE = { // stores x87 (and SSE) state to memory
		{implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FRSTOR = { // loads x87 (and SSE) state from memory
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
	},
	.FSTSW = { // AX form writes AX; m2byte form writes memory
		{implicit_wr={.RAX, .FPU_SW}, writes_mem=true},
		{implicit_wr={.RAX, .FPU_SW}},
	},
	.FNSTSW = { // AX form writes AX; m2byte form writes memory
		{implicit_wr={.RAX, .FPU_SW}, writes_mem=true},
		{implicit_wr={.RAX, .FPU_SW}},
	},
	.FXSAVE = { // stores x87 (and SSE) state to memory
		{implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FXSAVE64 = { // stores x87 (and SSE) state to memory
		{implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},
	},
	.FXRSTOR = { // loads x87 (and SSE) state from memory
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
	},
	.FXRSTOR64 = { // loads x87 (and SSE) state from memory
		{implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},
	},

	// 8.17 System Instruction Encodings
	.LGDT = { // privileged load
		{read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},
		{read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.SGDT = { // stores descriptor/register to r/m (privileged for some)
		{written={0}, writes_mem=true},
		{written={0}, writes_mem=true},
	},
	.LIDT = { // privileged load
		{read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},
		{read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.SIDT = { // stores descriptor/register to r/m (privileged for some)
		{written={0}, writes_mem=true},
		{written={0}, writes_mem=true},
	},
	.LLDT = { // privileged load
		{read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.SLDT = { // stores descriptor/register to r/m (privileged for some)
		{written={0}, writes_mem=true},
		{written={0}},
		{written={0}},
	},
	.LTR = { // privileged load
		{read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.STR = { // stores descriptor/register to r/m (privileged for some)
		{written={0}, writes_mem=true},
		{written={0}},
		{written={0}},
	},
	.LMSW = { // privileged load
		{read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.SMSW = { // stores descriptor/register to r/m (privileged for some)
		{written={0}, writes_mem=true},
		{written={0}},
		{written={0}},
	},
	.CLTS = { // privileged; no GPR/EFLAGS clobber modeled
		{side_effects={.PRIVILEGED}},
	},
	.ARPL = { // legacy; adjusts RPL, sets ZF
		{written={0}, read={1}, flags_wr={.ZF}, writes_mem=true, reads_mem=true},
	},
	.LAR = { // ZF=1 on success; OP0 undefined on failure
		{written={0}, read={1}, flags_wr={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.ZF}, reads_mem=true},
	},
	.LSL = { // ZF=1 on success; OP0 undefined on failure
		{written={0}, read={1}, flags_wr={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.ZF}, reads_mem=true},
		{written={0}, read={1}, flags_wr={.ZF}, reads_mem=true},
	},
	.VERR = { // ZF=1 if segment is readable/writable
		{read={0}, flags_wr={.ZF}, reads_mem=true},
	},
	.VERW = { // ZF=1 if segment is readable/writable
		{read={0}, flags_wr={.ZF}, reads_mem=true},
	},
	.INVD = { // privileged; no GPR/EFLAGS clobber modeled
		{side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.WBINVD = { // privileged; no GPR/EFLAGS clobber modeled
		{side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.INVLPG = { // privileged; no GPR/EFLAGS clobber modeled
		{read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.INVPCID = { // VMX/INVx status reported in ZF/CF
		{read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
		{read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.RSM = { // privileged; no GPR/EFLAGS clobber modeled
		{side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.RDMSR = { // privileged; EDX:EAX <- MSR[ECX]
		{implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}, side_effects={.PRIVILEGED}},
	},
	.WRMSR = { // privileged; MSR[ECX] <- EDX:EAX
		{implicit_rd={.RAX, .RCX, .RDX}, side_effects={.SERIALIZING, .PRIVILEGED}},
	},
	.VMCALL = { // privileged; no GPR/EFLAGS clobber modeled
		{side_effects={.PRIVILEGED}},
	},
	.VMLAUNCH = { // VMX/INVx status reported in ZF/CF
		{flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.VMRESUME = { // VMX/INVx status reported in ZF/CF
		{flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.VMXOFF = { // privileged; no GPR/EFLAGS clobber modeled
		{side_effects={.PRIVILEGED}},
	},
	.VMXON = { // VMX/INVx status reported in ZF/CF
		{read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.VMCLEAR = { // VMX/INVx status reported in ZF/CF
		{read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.VMPTRLD = { // VMX/INVx status reported in ZF/CF
		{read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.VMPTRST = { // VMX/INVx status reported in ZF/CF
		{read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.VMREAD = { // VMX status in ZF/CF
		{written={0}, read={1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.VMWRITE = { // VMX status in ZF/CF
		{read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.VMFUNC = { // privileged; no GPR/EFLAGS clobber modeled
		{side_effects={.PRIVILEGED}},
	},
	.INVEPT = { // VMX/INVx status reported in ZF/CF
		{read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.INVVPID = { // VMX/INVx status reported in ZF/CF
		{read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},
	},

	// 8.18 Security and Memory Protection Encodings
	.ENCLS = { // SGX enclave leaf; behaviour selected by EAX
		{side_effects={.PRIVILEGED}},
	},
	.ENCLU = { // SGX enclave leaf; behaviour selected by EAX
		{side_effects={.PRIVILEGED}},
	},
	.ENCLV = { // SGX enclave leaf; behaviour selected by EAX
		{side_effects={.PRIVILEGED}},
	},
	.RDPKRU = { // EAX <- PKRU (EDX cleared); reads ECX
		{implicit_wr={.RAX}, implicit_rd={.RCX}},
	},
	.WRPKRU = { // PKRU <- EAX; ECX/EDX must be 0
		{implicit_rd={.RAX, .RCX, .RDX}},
	},
	.INCSSPD = { // advances SSP
		{read={0}, side_effects={.CET}},
	},
	.INCSSPQ = { // advances SSP
		{read={0}, side_effects={.CET}},
	},
	.RDSSPD = { // reads shadow-stack pointer into OP0
		{written={0}, side_effects={.CET}},
	},
	.RDSSPQ = { // reads shadow-stack pointer into OP0
		{written={0}, side_effects={.CET}},
	},
	.SAVEPREVSSP = { // CET shadow-stack management
		{side_effects={.CET}},
	},
	.RSTORSSP = { // CET shadow-stack management
		{read={0}, reads_mem=true, writes_mem=true, side_effects={.CET}},  // reads restore token, writes previous-ssp token
	},
	.WRSSD = { // writes to shadow stack
		{read={0, 1}, writes_mem=true, side_effects={.CET}},
	},
	.WRSSQ = { // writes to shadow stack
		{read={0, 1}, writes_mem=true, side_effects={.CET}},
	},
	.WRUSSD = { // writes to shadow stack
		{read={0, 1}, writes_mem=true, side_effects={.CET}},
	},
	.WRUSSQ = { // writes to shadow stack
		{read={0, 1}, writes_mem=true, side_effects={.CET}},
	},
	.SETSSBSY = { // CET shadow-stack management
		{side_effects={.CET}},
	},
	.CLRSSBSY = { // CET shadow-stack management
		{read={0}, reads_mem=true, writes_mem=true, side_effects={.CET}},  // reads token, clears busy bit
	},
	.ENDBR64 = { // CET landing pad; NOP-like
		{side_effects={.HINT, .CET}},
	},
	.ENDBR32 = { // CET landing pad; NOP-like
		{side_effects={.HINT, .CET}},
	},

	// 8.19 XSAVE/XRSTOR State Management Encodings
	.XSAVE = { // saves state components selected by EDX:EAX
		{implicit_rd={.RAX, .RDX}, writes_mem=true},
	},
	.XSAVE64 = { // saves state components selected by EDX:EAX
		{implicit_rd={.RAX, .RDX}, writes_mem=true},
	},
	.XRSTOR = { // restores state components selected by EDX:EAX
		{implicit_wr={.MXCSR, .FPU_ST, .FPU_SW}, implicit_rd={.RAX, .RDX}, reads_mem=true},
	},
	.XRSTOR64 = { // restores state components selected by EDX:EAX
		{implicit_wr={.MXCSR, .FPU_ST, .FPU_SW}, implicit_rd={.RAX, .RDX}, reads_mem=true},
	},
	.XSAVEOPT = { // saves state components selected by EDX:EAX
		{implicit_rd={.RAX, .RDX}, writes_mem=true},
	},
	.XSAVEOPT64 = { // saves state components selected by EDX:EAX
		{implicit_rd={.RAX, .RDX}, writes_mem=true},
	},
	.XSAVEC = { // saves state components selected by EDX:EAX
		{implicit_rd={.RAX, .RDX}, writes_mem=true},
	},
	.XSAVEC64 = { // saves state components selected by EDX:EAX
		{implicit_rd={.RAX, .RDX}, writes_mem=true},
	},
	.XSAVES = { // saves state components selected by EDX:EAX
		{implicit_rd={.RAX, .RDX}, writes_mem=true, side_effects={.PRIVILEGED}},
	},
	.XSAVES64 = { // saves state components selected by EDX:EAX
		{implicit_rd={.RAX, .RDX}, writes_mem=true, side_effects={.PRIVILEGED}},
	},
	.XRSTORS = { // restores state components selected by EDX:EAX
		{implicit_wr={.MXCSR, .FPU_ST, .FPU_SW}, implicit_rd={.RAX, .RDX}, reads_mem=true, side_effects={.PRIVILEGED}},
	},
	.XRSTORS64 = { // restores state components selected by EDX:EAX
		{implicit_wr={.MXCSR, .FPU_ST, .FPU_SW}, implicit_rd={.RAX, .RDX}, reads_mem=true, side_effects={.PRIVILEGED}},
	},

	// 8.20 Cache and Prefetch Encodings
	.PREFETCHT0 = { // cache hint/maintenance; no register or flag clobber
		{read={0}, reads_mem=true, side_effects={.HINT}},
	},
	.PREFETCHT1 = { // cache hint/maintenance; no register or flag clobber
		{read={0}, reads_mem=true, side_effects={.HINT}},
	},
	.PREFETCHT2 = { // cache hint/maintenance; no register or flag clobber
		{read={0}, reads_mem=true, side_effects={.HINT}},
	},
	.PREFETCHNTA = { // cache hint/maintenance; no register or flag clobber
		{read={0}, reads_mem=true, side_effects={.HINT}},
	},
	.PREFETCHW = { // cache hint/maintenance; no register or flag clobber
		{read={0}, reads_mem=true, side_effects={.HINT}},
	},
	.CLFLUSHOPT = { // cache hint/maintenance; no register or flag clobber
		{read={0}, reads_mem=true, side_effects={.CACHE}},
	},
	.CLWB = { // cache hint/maintenance; no register or flag clobber
		{read={0}, reads_mem=true, side_effects={.CACHE}},
	},
	.CLDEMOTE = { // cache hint/maintenance; no register or flag clobber
		{read={0}, reads_mem=true, side_effects={.HINT}},
	},

	// 8.21 Atomic and Byte Swap Encodings
	.BSWAP = {
		{written={0}, read={0}},
		{written={0}, read={0}},
	},
	.CMPXCHG = { // ZF set on match; on mismatch RAX <- dest
		{written={0}, read={0, 1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0}, read={0, 1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},
	.CMPXCHG8B = { // EDX:EAX (RDX:RAX) compared; ECX:EBX (RCX:RBX) is the new value
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RBX, .RCX, .RDX}, flags_wr={.ZF}, writes_mem=true, reads_mem=true},
	},
	.CMPXCHG16B = { // EDX:EAX (RDX:RAX) compared; ECX:EBX (RCX:RBX) is the new value
		{read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RBX, .RCX, .RDX}, flags_wr={.ZF}, writes_mem=true, reads_mem=true},
	},
	.XADD = {
		{written={0, 1}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0, 1}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0, 1}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
		{written={0, 1}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	},

	// 8.22 Miscellaneous Encodings
	.BOUND = { // #BR if out of bounds
		{read={0, 1}, reads_mem=true, side_effects={.TRAP}},
		{read={0, 1}, reads_mem=true, side_effects={.TRAP}},
	},
	.ENTER = { // builds stack frame
		{implicit_wr={.RSP, .RBP}, implicit_rd={.RSP, .RBP}, writes_mem=true},
	},
	.LEAVE = {
		{implicit_wr={.RSP, .RBP}, implicit_rd={.RBP}, reads_mem=true},
	},
	.XLAT = { // AL <- [rBX + AL]
		{implicit_wr={.RAX}, implicit_rd={.RAX, .RBX}, reads_mem=true},
	},
	.XLATB = { // AL <- [rBX + AL]
		{implicit_wr={.RAX}, implicit_rd={.RAX, .RBX}, reads_mem=true},
	},
	.MOVBE = { // byte-swapping load/store
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
		{written={0}, read={1}, writes_mem=true, reads_mem=true},
	},
	.RDRAND = { // CF=1 if value valid; OF/SF/ZF/AF/PF cleared
		{written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
	.RDSEED = { // CF=1 if value valid; OF/SF/ZF/AF/PF cleared
		{written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
		{written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},
	},
}
