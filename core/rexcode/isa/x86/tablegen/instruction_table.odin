// Single source of truth: one Form (Encoding + Clobber) per instruction shape.

package rexcode_x86_tablegen

import "core:rexcode/isa/x86"

// Form couples one encoding shape with its architectural effects.
// `using encoding` keeps existing field access (form.opcode, form.ops,
// form.flags, ...) working unchanged when code moves from []Encoding to []Form.
Form :: struct {
	using encoding: Encoding,
	clobber:        Clobber,
}

// =============================================================================
// x86 INSTRUCTION_TABLE
// =============================================================================
//
// Type: [Mnemonic][]Form, indexed by Mnemonic. Each entry is a slice of Form,
// one per operand-shape variant. A Form couples an encoding with its
// architectural effects in a single record:
//
//   Form :: struct { using encoding: Encoding, clobber: x86.Clobber }
//
//   encoding: {mnemonic, ops[4], enc[4], opcode, ext, flags} // the bytes.
//   clobber:  {written, read, implicit_wr/rd, flags_wr/undef/rd,
//              writes_mem, reads_mem, side_effects}          // the effects.
//
// This is the single source of truth. Encoding and clobber used to live in two
// separate [Mnemonic][]T tables that had to be kept index-for-index aligned by
// hand; pairing them in one Form makes that alignment structural, so a form's
// bytes and its effects can no longer drift apart.
//
// MATCHING. The matcher walks a mnemonic's slice and selects the first Form
// whose Operand_Type list (encoding.ops) satisfies the user's Instruction
// operands. Only the encoding half is consulted during the scan; the clobber
// half is read after a Form is chosen. (Keep this in mind if the scan is hot:
// clobber data widens the stride but is never touched while matching.)
//
// HOW EACH FORM'S CLOBBER IS SPECIALISED. A mnemonic's effects begin as one
// per-mnemonic "union" and are narrowed to each individual form:
//
//   1. Implicit-operand normalisation. An operand that is an implicit register
//      (AL/AX/EAX/RAX_IMPL -> RAX, CL_IMPL -> RCX, XMM0_IMPL -> XMM0,
//      ST0_IMPL -> FPU_ST) or an implicit constant (ONE_IMPL) is removed from
//      the OP0..3 slot set and, if that slot was written/read, folded into
//      implicit_wr/implicit_rd. Registers that are implicit but NOT tied to an
//      operand (RSP for the stack, RSI/RDI/RCX for strings, RDX for MULX, ...)
//      are inherent and kept on every form.
//   2. Slot trimming. OP slots that are .NONE in a given form are dropped from
//      written/read.
//   3. Per-form memory. writes_mem/reads_mem keep the union's DIRECTION but are
//      asserted on a form only when that form actually carries a memory-capable
//      operand, OR the instruction addresses memory implicitly (stack, string,
//      XLAT table, MASKMOVDQU/[rDI] store, VMCS). Consequently register-only
//      forms of otherwise-memory instructions (e.g. MOV r,imm; FADD ST(0),ST(i);
//      FST ST(i); MOVLHPS; PEXTRW r32,xmm) do not carry the blanket memory flag
//      the union used. Shadow-stack accesses are not implicit: the shadow-stack
//      instructions that touch memory (WRSS/WRUSS/RSTORSSP/CLRSSBSY) all do so
//      through an explicit m64 operand and are covered by the memory-capable-
//      operand branch above.
//   4. Family splits that a single per-mnemonic union could only approximate:
//        IMUL:    1-operand form writes RDX:RAX implicitly (r/m8 -> AX only);
//                 2-operand form is OP0 *= OP1; 3-operand form is OP0 = OP1 * imm
//                 (OP0 not read); neither multi-operand form touches RAX/RDX.
//        MUL/DIV/IDIV: the r/m8 form uses the A-register only and does not
//                 touch (R)DX.
//        SHL/SHR/SAR/ROL/ROR/RCL/RCR/SHLD/SHRD: only the CL form reads RCX;
//                 the 1/imm8 forms do not.
//
// FLAGS AND SIDE EFFECTS are uniform across a mnemonic's forms and carry through
// unchanged, EXCEPT where one mnemonic aliases two distinct instructions: MOVSD
// and CMPSD each name both a string operation and an SSE scalar-double
// operation, so their string form and their SSE form carry different flags and
// side_effects.
//
// INVARIANT. A Form is a freely-eliminable no-op iff every clobber set is empty
// AND side_effects == {} (only .NOP and the .INVALID sentinel qualify). Note
// this is a property of clobber alone; the encoding half never makes a Form
// eliminable.

@(rodata)
INSTRUCTION_TABLE := [Mnemonic][]Form{
	.INVALID = {},
	.MOV = {
		{{.MOV, {.RM8,      .R8,       .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x88, 0, {}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RM16,     .R16,      .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x89, 0, {}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RM32,     .R32,      .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x89, 0, {}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RM64,     .R64,      .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x89, 0, {force_rex_w=true}},                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.R8,       .RM8,      .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8A, 0, {}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.R16,      .RM16,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8B, 0, {}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.R32,      .RM32,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8B, 0, {}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.R64,      .RM64,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8B, 0, {force_rex_w=true}},                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.R8,       .IMM8,     .NONE, .NONE}, {.OP_R, .IB,   .NONE, .NONE}, 0xB0, 0, {}},                                     {written={0}, read={1}}},
		{{.MOV, {.R16,      .IMM16,    .NONE, .NONE}, {.OP_R, .IW,   .NONE, .NONE}, 0xB8, 0, {}},                                     {written={0}, read={1}}},
		{{.MOV, {.R32,      .IMM32,    .NONE, .NONE}, {.OP_R, .ID,   .NONE, .NONE}, 0xB8, 0, {}},                                     {written={0}, read={1}}},
		{{.MOV, {.R64,      .IMM64,    .NONE, .NONE}, {.OP_R, .IQ,   .NONE, .NONE}, 0xB8, 0, {force_rex_w=true}},                     {written={0}, read={1}}},
		{{.MOV, {.RM8,      .IMM8,     .NONE, .NONE}, {.MR,   .IB,   .NONE, .NONE}, 0xC6, 0, {modrm_reg_ext=true}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RM16,     .IMM16,    .NONE, .NONE}, {.MR,   .IW,   .NONE, .NONE}, 0xC7, 0, {modrm_reg_ext=true}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RM32,     .IMM32,    .NONE, .NONE}, {.MR,   .ID,   .NONE, .NONE}, 0xC7, 0, {modrm_reg_ext=true}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RM64,     .IMM32,    .NONE, .NONE}, {.MR,   .ID,   .NONE, .NONE}, 0xC7, 0, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.AL_IMPL,  .MOFFS8,   .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA0, 0, {}},                                     {read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.AX_IMPL,  .MOFFS16,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {}},                                     {read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.EAX_IMPL, .MOFFS32,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {}},                                     {read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RAX_IMPL, .MOFFS64,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {force_rex_w=true}},                     {read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.MOFFS8,   .AL_IMPL,  .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA2, 0, {}},                                     {written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.MOFFS16,  .AX_IMPL,  .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {}},                                     {written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.MOFFS32,  .EAX_IMPL, .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {}},                                     {written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.MOFFS64,  .RAX_IMPL, .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {force_rex_w=true}},                     {written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RM16,     .SREG,     .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x8C, 0, {}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.RM64,     .SREG,     .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x8C, 0, {force_rex_w=true}},                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.SREG,     .RM16,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8E, 0, {}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.SREG,     .RM64,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8E, 0, {force_rex_w=true}},                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOV, {.R64,      .CR,       .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x20, 0, {esc=._0F}},                             {written={0}, read={1}}},
		{{.MOV, {.CR,       .R64,      .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x22, 0, {esc=._0F}},                             {written={0}, read={1}}},
		{{.MOV, {.R64,      .DR,       .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x21, 0, {esc=._0F}},                             {written={0}, read={1}}},
		{{.MOV, {.DR,       .R64,      .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x23, 0, {esc=._0F}},                             {written={0}, read={1}}},
	},
	.MOVABS = {
		{{.MOVABS, {.R64,      .IMM64,    .NONE, .NONE}, {.OP_R, .IQ,   .NONE, .NONE}, 0xB8, 0, {force_rex_w=true}}, {written={0}, read={1}}},
		{{.MOVABS, {.AL_IMPL,  .MOFFS8,   .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA0, 0, {}},                 {read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOVABS, {.AX_IMPL,  .MOFFS16,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {}},                 {read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOVABS, {.EAX_IMPL, .MOFFS32,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {}},                 {read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOVABS, {.RAX_IMPL, .MOFFS64,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {force_rex_w=true}}, {read={1}, implicit_wr={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOVABS, {.MOFFS8,   .AL_IMPL,  .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA2, 0, {}},                 {written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOVABS, {.MOFFS16,  .AX_IMPL,  .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {}},                 {written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOVABS, {.MOFFS32,  .EAX_IMPL, .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {}},                 {written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
		{{.MOVABS, {.MOFFS64,  .RAX_IMPL, .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {force_rex_w=true}}, {written={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
	},
	.MOVZX = {
		{{.MOVZX, {.R16, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB6, 0, {esc=._0F}},                   {written={0}, read={1}, reads_mem=true}},
		{{.MOVZX, {.R32, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB6, 0, {esc=._0F}},                   {written={0}, read={1}, reads_mem=true}},
		{{.MOVZX, {.R64, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB6, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, reads_mem=true}},
		{{.MOVZX, {.R32, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB7, 0, {esc=._0F}},                   {written={0}, read={1}, reads_mem=true}},
		{{.MOVZX, {.R64, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB7, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, reads_mem=true}},
	},
	.MOVSX = {
		{{.MOVSX, {.R16, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBE, 0, {esc=._0F}},                   {written={0}, read={1}, reads_mem=true}},
		{{.MOVSX, {.R32, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBE, 0, {esc=._0F}},                   {written={0}, read={1}, reads_mem=true}},
		{{.MOVSX, {.R64, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBE, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, reads_mem=true}},
		{{.MOVSX, {.R32, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBF, 0, {esc=._0F}},                   {written={0}, read={1}, reads_mem=true}},
		{{.MOVSX, {.R64, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBF, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, reads_mem=true}},
	},
	.MOVSXD = {
		{{.MOVSXD, {.R64, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x63, 0, {force_rex_w=true}}, {written={0}, read={1}, reads_mem=true}},
	},
	.XCHG = {
		{{.XCHG, {.AX_IMPL,  .R16, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0x90, 0, {}},                               {written={1}, read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}}},
		{{.XCHG, {.EAX_IMPL, .R32, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0x90, 0, {}},                               {written={1}, read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}}},
		{{.XCHG, {.RAX_IMPL, .R64, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0x90, 0, {force_rex_w=true}},               {written={1}, read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}}},
		{{.XCHG, {.RM8,      .R8,  .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x86, 0, {lock_ok=true}},                   {written={0, 1}, read={0, 1}, writes_mem=true, reads_mem=true}},
		{{.XCHG, {.RM16,     .R16, .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x87, 0, {lock_ok=true}},                   {written={0, 1}, read={0, 1}, writes_mem=true, reads_mem=true}},
		{{.XCHG, {.RM32,     .R32, .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x87, 0, {lock_ok=true}},                   {written={0, 1}, read={0, 1}, writes_mem=true, reads_mem=true}},
		{{.XCHG, {.RM64,     .R64, .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x87, 0, {force_rex_w=true, lock_ok=true}}, {written={0, 1}, read={0, 1}, writes_mem=true, reads_mem=true}},
	},
	.PUSH = {
		{{.PUSH, {.R16,    .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x50, 0, {}},                                    {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true}},
		{{.PUSH, {.R64,    .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x50, 0, {default_64=true}},                     {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true}},
		{{.PUSH, {.RM16,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 6, {modrm_reg_ext=true}},                  {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true}},
		{{.PUSH, {.RM64,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 6, {default_64=true, modrm_reg_ext=true}}, {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true}},
		{{.PUSH, {.IMM8SX, .NONE, .NONE, .NONE}, {.IB,   .NONE, .NONE, .NONE}, 0x6A, 0, {}},                                    {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true}},
		{{.PUSH, {.IMM16,  .NONE, .NONE, .NONE}, {.IW,   .NONE, .NONE, .NONE}, 0x68, 0, {}},                                    {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true}},
		{{.PUSH, {.IMM32,  .NONE, .NONE, .NONE}, {.ID,   .NONE, .NONE, .NONE}, 0x68, 0, {}},                                    {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true}},
		{{.PUSH, {.SREG,   .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xA0, 0, {esc=._0F}},                            {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true}},
		{{.PUSH, {.SREG,   .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xA8, 0, {esc=._0F}},                            {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true}},
	},
	.POP = {
		{{.POP, {.R16,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x58, 0, {}},                                    {written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true}},
		{{.POP, {.R64,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x58, 0, {default_64=true}},                     {written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true}},
		{{.POP, {.RM16, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x8F, 0, {modrm_reg_ext=true}},                  {written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true}},
		{{.POP, {.RM64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x8F, 0, {default_64=true, modrm_reg_ext=true}}, {written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true}},
		{{.POP, {.SREG, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xA1, 0, {esc=._0F}},                            {written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true}},
		{{.POP, {.SREG, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xA9, 0, {esc=._0F}},                            {written={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true}},
	},
	.LEA = {
		{{.LEA, {.R16, .M, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x8D, 0, {}},                 {written={0}}},
		{{.LEA, {.R32, .M, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x8D, 0, {}},                 {written={0}}},
		{{.LEA, {.R64, .M, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x8D, 0, {force_rex_w=true}}, {written={0}}},
	},
	.ADD = {
		{{.ADD, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x00, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x01, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x01, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x01, 0, {force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x02, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x03, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x03, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x03, 0, {force_rex_w=true}},                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x04, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.ADD, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x05, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.ADD, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x05, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.ADD, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x05, 0, {force_rex_w=true}},                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.ADD, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 0, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 0, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 0, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 0, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 0, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 0, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ADD, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 0, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.ADC = {
		{{.ADC, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x10, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x11, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x11, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x11, 0, {force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x12, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x13, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x13, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x13, 0, {force_rex_w=true}},                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x14, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}}},
		{{.ADC, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x15, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}}},
		{{.ADC, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x15, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}}},
		{{.ADC, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x15, 0, {force_rex_w=true}},                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}}},
		{{.ADC, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 2, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 2, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 2, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 2, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 2, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 2, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.ADC, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 2, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
	},
	.SUB = {
		{{.SUB, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x28, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x29, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x29, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x29, 0, {force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x2A, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x2B, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x2B, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x2B, 0, {force_rex_w=true}},                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x2C, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.SUB, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x2D, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.SUB, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x2D, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.SUB, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x2D, 0, {force_rex_w=true}},                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.SUB, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 5, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 5, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 5, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 5, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 5, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 5, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SUB, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 5, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.SBB = {
		{{.SBB, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x18, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x19, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x19, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x19, 0, {force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x1A, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x1B, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x1B, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x1B, 0, {force_rex_w=true}},                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x1C, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}}},
		{{.SBB, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x1D, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}}},
		{{.SBB, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x1D, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}}},
		{{.SBB, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x1D, 0, {force_rex_w=true}},                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}}},
		{{.SBB, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 3, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 3, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 3, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 3, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 3, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 3, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.SBB, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 3, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
	},
	.MUL = {
		{{.MUL, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 4, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.MUL, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 4, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.MUL, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 4, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.MUL, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 4, {force_rex_w=true, modrm_reg_ext=true}}, {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
	},
	.IMUL = {
		{{.IMUL, {.RM8,  .NONE, .NONE,   .NONE}, {.MR,  .NONE, .NONE, .NONE}, 0xF6, 5, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.RM16, .NONE, .NONE,   .NONE}, {.MR,  .NONE, .NONE, .NONE}, 0xF7, 5, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.RM32, .NONE, .NONE,   .NONE}, {.MR,  .NONE, .NONE, .NONE}, 0xF7, 5, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.RM64, .NONE, .NONE,   .NONE}, {.MR,  .NONE, .NONE, .NONE}, 0xF7, 5, {force_rex_w=true, modrm_reg_ext=true}}, {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R16,  .RM16, .NONE,   .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xAF, 0, {esc=._0F}},                             {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R32,  .RM32, .NONE,   .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xAF, 0, {esc=._0F}},                             {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R64,  .RM64, .NONE,   .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xAF, 0, {esc=._0F, force_rex_w=true}},           {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R16,  .RM16, .IMM8SX, .NONE}, {.REG, .MR,   .IB,   .NONE}, 0x6B, 0, {}},                                     {written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R32,  .RM32, .IMM8SX, .NONE}, {.REG, .MR,   .IB,   .NONE}, 0x6B, 0, {}},                                     {written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R64,  .RM64, .IMM8SX, .NONE}, {.REG, .MR,   .IB,   .NONE}, 0x6B, 0, {force_rex_w=true}},                     {written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R16,  .RM16, .IMM16,  .NONE}, {.REG, .MR,   .IW,   .NONE}, 0x69, 0, {}},                                     {written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R32,  .RM32, .IMM32,  .NONE}, {.REG, .MR,   .ID,   .NONE}, 0x69, 0, {}},                                     {written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
		{{.IMUL, {.R64,  .RM64, .IMM32,  .NONE}, {.REG, .MR,   .ID,   .NONE}, 0x69, 0, {force_rex_w=true}},                     {written={0}, read={1, 2}, flags_wr={.CF, .OF}, flags_undef={.PF, .AF, .ZF, .SF}, reads_mem=true}},
	},
	.DIV = {
		{{.DIV, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 6, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.DIV, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 6, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.DIV, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 6, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.DIV, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 6, {force_rex_w=true, modrm_reg_ext=true}}, {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.IDIV = {
		{{.IDIV, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 7, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.IDIV, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 7, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.IDIV, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 7, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.IDIV, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 7, {force_rex_w=true, modrm_reg_ext=true}}, {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.INC = {
		{{.INC, {.R16,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x40, 0, {mode_32_only=true}},                                  {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}}},
		{{.INC, {.R32,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x40, 0, {mode_32_only=true}},                                  {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}}},
		{{.INC, {.RM8,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFE, 0, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.INC, {.RM16, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 0, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.INC, {.RM32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 0, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.INC, {.RM64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 0, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.DEC = {
		{{.DEC, {.R16,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x48, 0, {mode_32_only=true}},                                  {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}}},
		{{.DEC, {.R32,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x48, 0, {mode_32_only=true}},                                  {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}}},
		{{.DEC, {.RM8,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFE, 1, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.DEC, {.RM16, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 1, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.DEC, {.RM32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 1, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.DEC, {.RM64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 1, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.NEG = {
		{{.NEG, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 3, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.NEG, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 3, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.NEG, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 3, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.NEG, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 3, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.CMP = {
		{{.CMP, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x38, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x39, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x39, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x39, 0, {force_rex_w=true}},                     {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x3A, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x3B, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x3B, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x3B, 0, {force_rex_w=true}},                     {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x3C, 0, {}},                                     {read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.CMP, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x3D, 0, {}},                                     {read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.CMP, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x3D, 0, {}},                                     {read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.CMP, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x3D, 0, {force_rex_w=true}},                     {read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.CMP, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 7, {modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 7, {modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 7, {modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 7, {force_rex_w=true, modrm_reg_ext=true}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 7, {modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 7, {modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.CMP, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 7, {force_rex_w=true, modrm_reg_ext=true}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.AND = {
		{{.AND, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x20, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x21, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x21, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x21, 0, {force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x22, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x23, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x23, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x23, 0, {force_rex_w=true}},                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x24, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.AND, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x25, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.AND, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x25, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.AND, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x25, 0, {force_rex_w=true}},                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.AND, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 4, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 4, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 4, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 4, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 4, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 4, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.AND, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 4, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
	},
	.OR = {
		{{.OR, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x08, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x09, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x09, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x09, 0, {force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x0A, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x0B, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x0B, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x0B, 0, {force_rex_w=true}},                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x0C, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.OR, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x0D, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.OR, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x0D, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.OR, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x0D, 0, {force_rex_w=true}},                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.OR, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 1, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 1, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 1, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 1, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 1, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 1, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.OR, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 1, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
	},
	.XOR = {
		{{.XOR, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x30, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x31, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x31, 0, {lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x31, 0, {force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x32, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x33, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x33, 0, {}},                                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x33, 0, {force_rex_w=true}},                                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x34, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.XOR, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x35, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.XOR, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x35, 0, {}},                                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.XOR, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x35, 0, {force_rex_w=true}},                                   {read={1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.XOR, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 6, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 6, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 6, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 6, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 6, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 6, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.XOR, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 6, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
	},
	.NOT = {
		{{.NOT, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 2, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, writes_mem=true, reads_mem=true}},
		{{.NOT, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 2, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, writes_mem=true, reads_mem=true}},
		{{.NOT, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 2, {lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0}, writes_mem=true, reads_mem=true}},
		{{.NOT, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 2, {force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0}, writes_mem=true, reads_mem=true}},
	},
	.TEST = {
		{{.TEST, {.RM8,      .R8,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x84, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true}},
		{{.TEST, {.RM16,     .R16,   .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x85, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true}},
		{{.TEST, {.RM32,     .R32,   .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x85, 0, {}},                                     {read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true}},
		{{.TEST, {.RM64,     .R64,   .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x85, 0, {force_rex_w=true}},                     {read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true}},
		{{.TEST, {.AL_IMPL,  .IMM8,  .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0xA8, 0, {}},                                     {read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.TEST, {.AX_IMPL,  .IMM16, .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0xA9, 0, {}},                                     {read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.TEST, {.EAX_IMPL, .IMM32, .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0xA9, 0, {}},                                     {read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.TEST, {.RAX_IMPL, .IMM32, .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0xA9, 0, {force_rex_w=true}},                     {read={1}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}}},
		{{.TEST, {.RM8,      .IMM8,  .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0xF6, 0, {modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true}},
		{{.TEST, {.RM16,     .IMM16, .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0xF7, 0, {modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true}},
		{{.TEST, {.RM32,     .IMM32, .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0xF7, 0, {modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true}},
		{{.TEST, {.RM64,     .IMM32, .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0xF7, 0, {force_rex_w=true, modrm_reg_ext=true}}, {read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, reads_mem=true}},
	},
	.SHL = {
		{{.SHL, {.RM8,  .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 4, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM8,  .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 4, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM8,  .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 4, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM16, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 4, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM16, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 4, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM16, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 4, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM32, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 4, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM32, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 4, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM32, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 4, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM64, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 4, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM64, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 4, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHL, {.RM64, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 4, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
	},
	.SHR = {
		{{.SHR, {.RM8,  .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 5, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM8,  .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 5, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM8,  .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 5, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM16, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 5, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM16, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 5, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM16, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 5, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM32, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 5, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM32, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 5, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM32, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 5, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM64, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 5, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM64, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 5, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SHR, {.RM64, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 5, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
	},
	.SAR = {
		{{.SAR, {.RM8,  .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 7, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM8,  .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 7, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM8,  .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 7, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM16, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 7, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM16, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 7, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM16, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 7, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM32, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 7, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM32, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 7, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM32, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 7, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM64, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 7, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM64, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 7, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
		{{.SAR, {.RM64, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 7, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .PF, .ZF, .SF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true}},
	},
	.ROL = {
		{{.ROL, {.RM8,  .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 0, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM8,  .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 0, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM8,  .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 0, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM16, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 0, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM16, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 0, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM16, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 0, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM32, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 0, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM32, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 0, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM32, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 0, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM64, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 0, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM64, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 0, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROL, {.RM64, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 0, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.ROR = {
		{{.ROR, {.RM8,  .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 1, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM8,  .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 1, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM8,  .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 1, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM16, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 1, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM16, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 1, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM16, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 1, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM32, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 1, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM32, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 1, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM32, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 1, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM64, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 1, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM64, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 1, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
		{{.ROR, {.RM64, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 1, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.RCL = {
		{{.RCL, {.RM8,  .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 2, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM8,  .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 2, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM8,  .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 2, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM16, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 2, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM16, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 2, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM16, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 2, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM32, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 2, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM32, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 2, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM32, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 2, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM64, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 2, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM64, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 2, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCL, {.RM64, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 2, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
	},
	.RCR = {
		{{.RCR, {.RM8,  .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 3, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM8,  .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 3, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM8,  .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 3, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM16, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 3, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM16, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 3, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM16, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 3, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM32, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 3, {modrm_reg_ext=true}},                   {written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM32, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 3, {modrm_reg_ext=true}},                   {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM32, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 3, {modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM64, .ONE_IMPL, .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 3, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM64, .CL_IMPL,  .NONE, .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 3, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
		{{.RCR, {.RM64, .IMM8,     .NONE, .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 3, {force_rex_w=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true}},
	},
	.SHLD = {
		{{.SHLD, {.RM16, .R16, .IMM8,    .NONE}, {.MR, .REG, .IB,   .NONE}, 0xA4, 0, {esc=._0F}},                   {written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHLD, {.RM32, .R32, .IMM8,    .NONE}, {.MR, .REG, .IB,   .NONE}, 0xA4, 0, {esc=._0F}},                   {written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHLD, {.RM64, .R64, .IMM8,    .NONE}, {.MR, .REG, .IB,   .NONE}, 0xA4, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHLD, {.RM16, .R16, .CL_IMPL, .NONE}, {.MR, .REG, .IMPL, .NONE}, 0xA5, 0, {esc=._0F}},                   {written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHLD, {.RM32, .R32, .CL_IMPL, .NONE}, {.MR, .REG, .IMPL, .NONE}, 0xA5, 0, {esc=._0F}},                   {written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHLD, {.RM64, .R64, .CL_IMPL, .NONE}, {.MR, .REG, .IMPL, .NONE}, 0xA5, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.SHRD = {
		{{.SHRD, {.RM16, .R16, .IMM8,    .NONE}, {.MR, .REG, .IB,   .NONE}, 0xAC, 0, {esc=._0F}},                   {written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHRD, {.RM32, .R32, .IMM8,    .NONE}, {.MR, .REG, .IB,   .NONE}, 0xAC, 0, {esc=._0F}},                   {written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHRD, {.RM64, .R64, .IMM8,    .NONE}, {.MR, .REG, .IB,   .NONE}, 0xAC, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={0, 1, 2}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHRD, {.RM16, .R16, .CL_IMPL, .NONE}, {.MR, .REG, .IMPL, .NONE}, 0xAD, 0, {esc=._0F}},                   {written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHRD, {.RM32, .R32, .CL_IMPL, .NONE}, {.MR, .REG, .IMPL, .NONE}, 0xAD, 0, {esc=._0F}},                   {written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
		{{.SHRD, {.RM64, .R64, .CL_IMPL, .NONE}, {.MR, .REG, .IMPL, .NONE}, 0xAD, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={0, 1}, implicit_rd={.RCX}, flags_wr={.CF, .PF, .ZF, .SF}, flags_undef={.AF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.BT = {
		{{.BT, {.RM16, .R16,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F}},                                       {read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BT, {.RM32, .R32,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F}},                                       {read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BT, {.RM64, .R64,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F, force_rex_w=true}},                     {read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BT, {.RM16, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 4, {esc=._0F, modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BT, {.RM32, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 4, {esc=._0F, modrm_reg_ext=true}},                   {read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BT, {.RM64, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 4, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.BTS = {
		{{.BTS, {.RM16, .R16,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xAB, 0, {esc=._0F, lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTS, {.RM32, .R32,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xAB, 0, {esc=._0F, lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTS, {.RM64, .R64,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xAB, 0, {esc=._0F, force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTS, {.RM16, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 5, {esc=._0F, lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTS, {.RM32, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 5, {esc=._0F, lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTS, {.RM64, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 5, {esc=._0F, force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.BTR = {
		{{.BTR, {.RM16, .R16,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB3, 0, {esc=._0F, lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTR, {.RM32, .R32,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB3, 0, {esc=._0F, lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTR, {.RM64, .R64,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB3, 0, {esc=._0F, force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTR, {.RM16, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 6, {esc=._0F, lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTR, {.RM32, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 6, {esc=._0F, lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTR, {.RM64, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 6, {esc=._0F, force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.BTC = {
		{{.BTC, {.RM16, .R16,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xBB, 0, {esc=._0F, lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTC, {.RM32, .R32,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xBB, 0, {esc=._0F, lock_ok=true}},                                       {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTC, {.RM64, .R64,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xBB, 0, {esc=._0F, force_rex_w=true, lock_ok=true}},                     {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTC, {.RM16, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 7, {esc=._0F, lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTC, {.RM32, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 7, {esc=._0F, lock_ok=true, modrm_reg_ext=true}},                   {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.BTC, {.RM64, .IMM8, .NONE, .NONE}, {.MR, .IB,  .NONE, .NONE}, 0xBA, 7, {esc=._0F, force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {written={0}, read={0, 1}, flags_wr={.CF}, flags_undef={.PF, .AF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.BSF = {
		{{.BSF, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBC, 0, {esc=._0F}},                   {written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BSF, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBC, 0, {esc=._0F}},                   {written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BSF, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBC, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.BSR = {
		{{.BSR, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBD, 0, {esc=._0F}},                   {written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BSR, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBD, 0, {esc=._0F}},                   {written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.BSR, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBD, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_wr={.ZF}, flags_undef={.CF, .PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.POPCNT = {
		{{.POPCNT, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB8, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.POPCNT, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB8, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
		{{.POPCNT, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB8, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}}, {written={0}, read={1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.LZCNT = {
		{{.LZCNT, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBD, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.LZCNT, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBD, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.LZCNT, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBD, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}}, {written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.TZCNT = {
		{{.TZCNT, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBC, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.TZCNT, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBC, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.TZCNT, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBC, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}}, {written={0}, read={1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.JMP = {
		{{.JMP, {.REL8,   .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xEB, 0, {}},                                     {read={0}, side_effects={.CONTROL}}},
		{{.JMP, {.REL32,  .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0xE9, 0, {}},                                     {read={0}, side_effects={.CONTROL}}},
		{{.JMP, {.RM64,   .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 4, {default_64=true, modrm_reg_ext=true}},  {read={0}, reads_mem=true, side_effects={.CONTROL}}},
		{{.JMP, {.M16_16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 5, {modrm_reg_ext=true}},                   {read={0}, reads_mem=true, side_effects={.CONTROL}}},
		{{.JMP, {.M16_32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 5, {modrm_reg_ext=true}},                   {read={0}, reads_mem=true, side_effects={.CONTROL}}},
		{{.JMP, {.M16_64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 5, {force_rex_w=true, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.CONTROL}}},
	},
	.JA = {
		{{.JA, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x77, 0, {}},         {flags_rd={.CF, .ZF}, side_effects={.CONTROL}}},
		{{.JA, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x87, 0, {esc=._0F}}, {flags_rd={.CF, .ZF}, side_effects={.CONTROL}}},
	},
	.JAE = {
		{{.JAE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x73, 0, {}},         {flags_rd={.CF}, side_effects={.CONTROL}}},
		{{.JAE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x83, 0, {esc=._0F}}, {flags_rd={.CF}, side_effects={.CONTROL}}},
	},
	.JB = {
		{{.JB, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x72, 0, {}},         {flags_rd={.CF}, side_effects={.CONTROL}}},
		{{.JB, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x82, 0, {esc=._0F}}, {flags_rd={.CF}, side_effects={.CONTROL}}},
	},
	.JBE = {
		{{.JBE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x76, 0, {}},         {flags_rd={.CF, .ZF}, side_effects={.CONTROL}}},
		{{.JBE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x86, 0, {esc=._0F}}, {flags_rd={.CF, .ZF}, side_effects={.CONTROL}}},
	},
	.JC = {
		{{.JC, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x72, 0, {}},         {flags_rd={.CF}, side_effects={.CONTROL}}},
		{{.JC, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x82, 0, {esc=._0F}}, {flags_rd={.CF}, side_effects={.CONTROL}}},
	},
	.JE = {
		{{.JE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x74, 0, {}},         {flags_rd={.ZF}, side_effects={.CONTROL}}},
		{{.JE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x84, 0, {esc=._0F}}, {flags_rd={.ZF}, side_effects={.CONTROL}}},
	},
	.JZ = {
		{{.JZ, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x74, 0, {}},         {flags_rd={.ZF}, side_effects={.CONTROL}}},
		{{.JZ, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x84, 0, {esc=._0F}}, {flags_rd={.ZF}, side_effects={.CONTROL}}},
	},
	.JG = {
		{{.JG, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7F, 0, {}},         {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}}},
		{{.JG, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8F, 0, {esc=._0F}}, {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}}},
	},
	.JGE = {
		{{.JGE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7D, 0, {}},         {flags_rd={.SF, .OF}, side_effects={.CONTROL}}},
		{{.JGE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8D, 0, {esc=._0F}}, {flags_rd={.SF, .OF}, side_effects={.CONTROL}}},
	},
	.JL = {
		{{.JL, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7C, 0, {}},         {flags_rd={.SF, .OF}, side_effects={.CONTROL}}},
		{{.JL, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8C, 0, {esc=._0F}}, {flags_rd={.SF, .OF}, side_effects={.CONTROL}}},
	},
	.JLE = {
		{{.JLE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7E, 0, {}},         {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}}},
		{{.JLE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8E, 0, {esc=._0F}}, {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}}},
	},
	.JNA = {
		{{.JNA, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x76, 0, {}},         {flags_rd={.CF, .ZF}, side_effects={.CONTROL}}},
		{{.JNA, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x86, 0, {esc=._0F}}, {flags_rd={.CF, .ZF}, side_effects={.CONTROL}}},
	},
	.JNAE = {
		{{.JNAE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x72, 0, {}},         {flags_rd={.CF}, side_effects={.CONTROL}}},
		{{.JNAE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x82, 0, {esc=._0F}}, {flags_rd={.CF}, side_effects={.CONTROL}}},
	},
	.JNB = {
		{{.JNB, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x73, 0, {}},         {flags_rd={.CF}, side_effects={.CONTROL}}},
		{{.JNB, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x83, 0, {esc=._0F}}, {flags_rd={.CF}, side_effects={.CONTROL}}},
	},
	.JNBE = {
		{{.JNBE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x77, 0, {}},         {flags_rd={.CF, .ZF}, side_effects={.CONTROL}}},
		{{.JNBE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x87, 0, {esc=._0F}}, {flags_rd={.CF, .ZF}, side_effects={.CONTROL}}},
	},
	.JNC = {
		{{.JNC, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x73, 0, {}},         {flags_rd={.CF}, side_effects={.CONTROL}}},
		{{.JNC, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x83, 0, {esc=._0F}}, {flags_rd={.CF}, side_effects={.CONTROL}}},
	},
	.JNE = {
		{{.JNE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x75, 0, {}},         {flags_rd={.ZF}, side_effects={.CONTROL}}},
		{{.JNE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x85, 0, {esc=._0F}}, {flags_rd={.ZF}, side_effects={.CONTROL}}},
	},
	.JNZ = {
		{{.JNZ, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x75, 0, {}},         {flags_rd={.ZF}, side_effects={.CONTROL}}},
		{{.JNZ, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x85, 0, {esc=._0F}}, {flags_rd={.ZF}, side_effects={.CONTROL}}},
	},
	.JNG = {
		{{.JNG, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7E, 0, {}},         {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}}},
		{{.JNG, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8E, 0, {esc=._0F}}, {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}}},
	},
	.JNGE = {
		{{.JNGE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7C, 0, {}},         {flags_rd={.SF, .OF}, side_effects={.CONTROL}}},
		{{.JNGE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8C, 0, {esc=._0F}}, {flags_rd={.SF, .OF}, side_effects={.CONTROL}}},
	},
	.JNL = {
		{{.JNL, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7D, 0, {}},         {flags_rd={.SF, .OF}, side_effects={.CONTROL}}},
		{{.JNL, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8D, 0, {esc=._0F}}, {flags_rd={.SF, .OF}, side_effects={.CONTROL}}},
	},
	.JNLE = {
		{{.JNLE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7F, 0, {}},         {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}}},
		{{.JNLE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8F, 0, {esc=._0F}}, {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}}},
	},
	.JNO = {
		{{.JNO, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x71, 0, {}},         {flags_rd={.OF}, side_effects={.CONTROL}}},
		{{.JNO, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x81, 0, {esc=._0F}}, {flags_rd={.OF}, side_effects={.CONTROL}}},
	},
	.JNP = {
		{{.JNP, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7B, 0, {}},         {flags_rd={.PF}, side_effects={.CONTROL}}},
		{{.JNP, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8B, 0, {esc=._0F}}, {flags_rd={.PF}, side_effects={.CONTROL}}},
	},
	.JNS = {
		{{.JNS, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x79, 0, {}},         {flags_rd={.SF}, side_effects={.CONTROL}}},
		{{.JNS, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x89, 0, {esc=._0F}}, {flags_rd={.SF}, side_effects={.CONTROL}}},
	},
	.JO = {
		{{.JO, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x70, 0, {}},         {flags_rd={.OF}, side_effects={.CONTROL}}},
		{{.JO, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x80, 0, {esc=._0F}}, {flags_rd={.OF}, side_effects={.CONTROL}}},
	},
	.JP = {
		{{.JP, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7A, 0, {}},         {flags_rd={.PF}, side_effects={.CONTROL}}},
		{{.JP, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8A, 0, {esc=._0F}}, {flags_rd={.PF}, side_effects={.CONTROL}}},
	},
	.JPE = {
		{{.JPE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7A, 0, {}},         {flags_rd={.PF}, side_effects={.CONTROL}}},
		{{.JPE, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8A, 0, {esc=._0F}}, {flags_rd={.PF}, side_effects={.CONTROL}}},
	},
	.JPO = {
		{{.JPO, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7B, 0, {}},         {flags_rd={.PF}, side_effects={.CONTROL}}},
		{{.JPO, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8B, 0, {esc=._0F}}, {flags_rd={.PF}, side_effects={.CONTROL}}},
	},
	.JS = {
		{{.JS, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x78, 0, {}},         {flags_rd={.SF}, side_effects={.CONTROL}}},
		{{.JS, {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x88, 0, {esc=._0F}}, {flags_rd={.SF}, side_effects={.CONTROL}}},
	},
	.JCXZ = {
		{{.JCXZ, {.REL8, .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE3, 0, {}}, {implicit_rd={.RCX}, side_effects={.CONTROL}}},
	},
	.JECXZ = {
		{{.JECXZ, {.REL8, .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE3, 0, {}}, {implicit_rd={.RCX}, side_effects={.CONTROL}}},
	},
	.JRCXZ = {
		{{.JRCXZ, {.REL8, .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE3, 0, {force_rex_w=true}}, {implicit_rd={.RCX}, side_effects={.CONTROL}}},
	},
	.LOOP = {
		{{.LOOP, {.REL8, .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE2, 0, {}}, {implicit_wr={.RCX}, implicit_rd={.RCX}, side_effects={.CONTROL}}},
	},
	.LOOPE = {
		{{.LOOPE, {.REL8, .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE1, 0, {}}, {implicit_wr={.RCX}, implicit_rd={.RCX}, flags_rd={.ZF}, side_effects={.CONTROL}}},
	},
	.LOOPNE = {
		{{.LOOPNE, {.REL8, .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE0, 0, {}}, {implicit_wr={.RCX}, implicit_rd={.RCX}, flags_rd={.ZF}, side_effects={.CONTROL}}},
	},
	.CALL = {
		{{.CALL, {.REL32,  .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0xE8, 0, {}},                                     {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, side_effects={.CONTROL}}},
		{{.CALL, {.RM64,   .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 2, {default_64=true, modrm_reg_ext=true}},  {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}}},
		{{.CALL, {.M16_16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 3, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}}},
		{{.CALL, {.M16_32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 3, {modrm_reg_ext=true}},                   {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}}},
		{{.CALL, {.M16_64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 3, {force_rex_w=true, modrm_reg_ext=true}}, {read={0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}}},
	},
	.RET = {
		{{.RET, {.NONE,  .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xC3, 0, {}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true, side_effects={.CONTROL}}},
		{{.RET, {.IMM16, .NONE, .NONE, .NONE}, {.IW,   .NONE, .NONE, .NONE}, 0xC2, 0, {}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true, side_effects={.CONTROL}}},
	},
	.IRET = {
		{{.IRET, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCF, 0, {opsize_16=true}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}}},
	},
	.IRETD = {
		{{.IRETD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCF, 0, {}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}}},
	},
	.IRETQ = {
		{{.IRETQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCF, 0, {force_rex_w=true}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}}},
	},
	.INT = {
		{{.INT, {.IMM8, .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xCD, 0, {}}, {read={0}, implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}}},
	},
	.INT3 = {
		{{.INT3, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCC, 0, {}}, {implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}}},
	},
	.INTO = {
		{{.INTO, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCE, 0, {}}, {implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}}},
	},
	.SYSCALL = {
		{{.SYSCALL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x05, 0, {esc=._0F}}, {implicit_wr={.RCX, .R11}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, side_effects={.INTERRUPT, .CONTROL}}},
	},
	.SYSRET = {
		{{.SYSRET, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x07, 0, {esc=._0F}}, {implicit_rd={.RCX, .R11}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, side_effects={.SERIALIZING, .INTERRUPT, .PRIVILEGED, .CONTROL}}},
	},
	.SYSENTER = {
		{{.SYSENTER, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x34, 0, {esc=._0F}}, {implicit_wr={.RSP}, flags_wr={.IF}, side_effects={.INTERRUPT, .CONTROL}}},
	},
	.SYSEXIT = {
		{{.SYSEXIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x35, 0, {esc=._0F}}, {implicit_wr={.RSP}, implicit_rd={.RCX, .RDX}, side_effects={.SERIALIZING, .INTERRUPT, .PRIVILEGED, .CONTROL}}},
	},
	.SETA = {
		{{.SETA, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x97, 0, {esc=._0F}}, {written={0}, flags_rd={.CF, .ZF}, writes_mem=true}},
	},
	.SETAE = {
		{{.SETAE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x93, 0, {esc=._0F}}, {written={0}, flags_rd={.CF}, writes_mem=true}},
	},
	.SETB = {
		{{.SETB, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x92, 0, {esc=._0F}}, {written={0}, flags_rd={.CF}, writes_mem=true}},
	},
	.SETBE = {
		{{.SETBE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x96, 0, {esc=._0F}}, {written={0}, flags_rd={.CF, .ZF}, writes_mem=true}},
	},
	.SETC = {
		{{.SETC, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x92, 0, {esc=._0F}}, {written={0}, flags_rd={.CF}, writes_mem=true}},
	},
	.SETE = {
		{{.SETE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x94, 0, {esc=._0F}}, {written={0}, flags_rd={.ZF}, writes_mem=true}},
	},
	.SETG = {
		{{.SETG, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9F, 0, {esc=._0F}}, {written={0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true}},
	},
	.SETGE = {
		{{.SETGE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9D, 0, {esc=._0F}}, {written={0}, flags_rd={.SF, .OF}, writes_mem=true}},
	},
	.SETL = {
		{{.SETL, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9C, 0, {esc=._0F}}, {written={0}, flags_rd={.SF, .OF}, writes_mem=true}},
	},
	.SETLE = {
		{{.SETLE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9E, 0, {esc=._0F}}, {written={0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true}},
	},
	.SETNA = {
		{{.SETNA, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x96, 0, {esc=._0F}}, {written={0}, flags_rd={.CF, .ZF}, writes_mem=true}},
	},
	.SETNAE = {
		{{.SETNAE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x92, 0, {esc=._0F}}, {written={0}, flags_rd={.CF}, writes_mem=true}},
	},
	.SETNB = {
		{{.SETNB, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x93, 0, {esc=._0F}}, {written={0}, flags_rd={.CF}, writes_mem=true}},
	},
	.SETNBE = {
		{{.SETNBE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x97, 0, {esc=._0F}}, {written={0}, flags_rd={.CF, .ZF}, writes_mem=true}},
	},
	.SETNC = {
		{{.SETNC, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x93, 0, {esc=._0F}}, {written={0}, flags_rd={.CF}, writes_mem=true}},
	},
	.SETNE = {
		{{.SETNE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x95, 0, {esc=._0F}}, {written={0}, flags_rd={.ZF}, writes_mem=true}},
	},
	.SETNG = {
		{{.SETNG, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9E, 0, {esc=._0F}}, {written={0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true}},
	},
	.SETNGE = {
		{{.SETNGE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9C, 0, {esc=._0F}}, {written={0}, flags_rd={.SF, .OF}, writes_mem=true}},
	},
	.SETNL = {
		{{.SETNL, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9D, 0, {esc=._0F}}, {written={0}, flags_rd={.SF, .OF}, writes_mem=true}},
	},
	.SETNLE = {
		{{.SETNLE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9F, 0, {esc=._0F}}, {written={0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true}},
	},
	.SETNO = {
		{{.SETNO, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x91, 0, {esc=._0F}}, {written={0}, flags_rd={.OF}, writes_mem=true}},
	},
	.SETNP = {
		{{.SETNP, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9B, 0, {esc=._0F}}, {written={0}, flags_rd={.PF}, writes_mem=true}},
	},
	.SETNS = {
		{{.SETNS, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x99, 0, {esc=._0F}}, {written={0}, flags_rd={.SF}, writes_mem=true}},
	},
	.SETNZ = {
		{{.SETNZ, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x95, 0, {esc=._0F}}, {written={0}, flags_rd={.ZF}, writes_mem=true}},
	},
	.SETO = {
		{{.SETO, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x90, 0, {esc=._0F}}, {written={0}, flags_rd={.OF}, writes_mem=true}},
	},
	.SETP = {
		{{.SETP, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9A, 0, {esc=._0F}}, {written={0}, flags_rd={.PF}, writes_mem=true}},
	},
	.SETPE = {
		{{.SETPE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9A, 0, {esc=._0F}}, {written={0}, flags_rd={.PF}, writes_mem=true}},
	},
	.SETPO = {
		{{.SETPO, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9B, 0, {esc=._0F}}, {written={0}, flags_rd={.PF}, writes_mem=true}},
	},
	.SETS = {
		{{.SETS, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x98, 0, {esc=._0F}}, {written={0}, flags_rd={.SF}, writes_mem=true}},
	},
	.SETZ = {
		{{.SETZ, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x94, 0, {esc=._0F}}, {written={0}, flags_rd={.ZF}, writes_mem=true}},
	},
	.CMOVA = {
		{{.CMOVA, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
		{{.CMOVA, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
		{{.CMOVA, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
	},
	.CMOVAE = {
		{{.CMOVAE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVAE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVAE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
	},
	.CMOVB = {
		{{.CMOVB, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVB, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVB, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
	},
	.CMOVBE = {
		{{.CMOVBE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
		{{.CMOVBE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
		{{.CMOVBE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
	},
	.CMOVC = {
		{{.CMOVC, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVC, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVC, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
	},
	.CMOVE = {
		{{.CMOVE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
		{{.CMOVE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
		{{.CMOVE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
	},
	.CMOVG = {
		{{.CMOVG, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
		{{.CMOVG, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
		{{.CMOVG, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
	},
	.CMOVGE = {
		{{.CMOVGE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
		{{.CMOVGE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
		{{.CMOVGE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
	},
	.CMOVL = {
		{{.CMOVL, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
		{{.CMOVL, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
		{{.CMOVL, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
	},
	.CMOVLE = {
		{{.CMOVLE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
		{{.CMOVLE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
		{{.CMOVLE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
	},
	.CMOVNA = {
		{{.CMOVNA, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
		{{.CMOVNA, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
		{{.CMOVNA, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
	},
	.CMOVNAE = {
		{{.CMOVNAE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVNAE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVNAE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
	},
	.CMOVNB = {
		{{.CMOVNB, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVNB, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVNB, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
	},
	.CMOVNBE = {
		{{.CMOVNBE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
		{{.CMOVNBE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
		{{.CMOVNBE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF, .ZF}, reads_mem=true}},
	},
	.CMOVNC = {
		{{.CMOVNC, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVNC, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
		{{.CMOVNC, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.CF}, reads_mem=true}},
	},
	.CMOVNE = {
		{{.CMOVNE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
		{{.CMOVNE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
		{{.CMOVNE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
	},
	.CMOVNG = {
		{{.CMOVNG, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
		{{.CMOVNG, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
		{{.CMOVNG, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
	},
	.CMOVNGE = {
		{{.CMOVNGE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
		{{.CMOVNGE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
		{{.CMOVNGE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
	},
	.CMOVNL = {
		{{.CMOVNL, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
		{{.CMOVNL, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
		{{.CMOVNL, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.SF, .OF}, reads_mem=true}},
	},
	.CMOVNLE = {
		{{.CMOVNLE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
		{{.CMOVNLE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
		{{.CMOVNLE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true}},
	},
	.CMOVNO = {
		{{.CMOVNO, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.OF}, reads_mem=true}},
		{{.CMOVNO, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.OF}, reads_mem=true}},
		{{.CMOVNO, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.OF}, reads_mem=true}},
	},
	.CMOVNP = {
		{{.CMOVNP, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
		{{.CMOVNP, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
		{{.CMOVNP, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
	},
	.CMOVNS = {
		{{.CMOVNS, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x49, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF}, reads_mem=true}},
		{{.CMOVNS, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x49, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF}, reads_mem=true}},
		{{.CMOVNS, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x49, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.SF}, reads_mem=true}},
	},
	.CMOVNZ = {
		{{.CMOVNZ, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
		{{.CMOVNZ, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
		{{.CMOVNZ, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
	},
	.CMOVO = {
		{{.CMOVO, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x40, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.OF}, reads_mem=true}},
		{{.CMOVO, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x40, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.OF}, reads_mem=true}},
		{{.CMOVO, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x40, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.OF}, reads_mem=true}},
	},
	.CMOVP = {
		{{.CMOVP, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
		{{.CMOVP, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
		{{.CMOVP, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
	},
	.CMOVPE = {
		{{.CMOVPE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
		{{.CMOVPE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
		{{.CMOVPE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
	},
	.CMOVPO = {
		{{.CMOVPO, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
		{{.CMOVPO, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
		{{.CMOVPO, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.PF}, reads_mem=true}},
	},
	.CMOVS = {
		{{.CMOVS, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x48, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF}, reads_mem=true}},
		{{.CMOVS, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x48, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.SF}, reads_mem=true}},
		{{.CMOVS, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x48, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.SF}, reads_mem=true}},
	},
	.CMOVZ = {
		{{.CMOVZ, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
		{{.CMOVZ, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F}},                   {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
		{{.CMOVZ, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_rd={.ZF}, reads_mem=true}},
	},
	.MOVS = {
		{{.MOVS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA4, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.MOVSB = {
		{{.MOVSB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA4, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.MOVSW = {
		{{.MOVSW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA5, 0, {opsize_16=true, rep_ok=true}}, {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.MOVSD = {
		{{.MOVSD, {.NONE,    .NONE,    .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA5, 0, {rep_ok=true}},                {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
		{{.MOVSD, {.XMM,     .XMM_M64, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVSD, {.XMM_M64, .XMM,     .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVSQ = {
		{{.MOVSQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA5, 0, {force_rex_w=true, rep_ok=true}}, {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.CMPS = {
		{{.CMPS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA6, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.CMPSB = {
		{{.CMPSB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA6, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.CMPSW = {
		{{.CMPSW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA7, 0, {opsize_16=true, rep_ok=true}}, {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.CMPSD = {
		{{.CMPSD, {.NONE, .NONE,    .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA7, 0, {rep_ok=true}},                {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
		{{.CMPSD, {.XMM,  .XMM_M64, .IMM8, .NONE}, {.REG,  .MR,   .IB,   .NONE}, 0xC2, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CMPSQ = {
		{{.CMPSQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA7, 0, {force_rex_w=true, rep_ok=true}}, {implicit_wr={.RCX, .RSI, .RDI}, implicit_rd={.RCX, .RSI, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.SCAS = {
		{{.SCAS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.SCASB = {
		{{.SCASB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.SCASW = {
		{{.SCASW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAF, 0, {opsize_16=true, rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.SCASD = {
		{{.SCASD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAF, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.SCASQ = {
		{{.SCASQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAF, 0, {force_rex_w=true, rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true}},
	},
	.LODS = {
		{{.LODS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAC, 0, {rep_ok=true}}, {implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true}},
	},
	.LODSB = {
		{{.LODSB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAC, 0, {rep_ok=true}}, {implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true}},
	},
	.LODSW = {
		{{.LODSW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAD, 0, {opsize_16=true, rep_ok=true}}, {implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true}},
	},
	.LODSD = {
		{{.LODSD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAD, 0, {rep_ok=true}}, {implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true}},
	},
	.LODSQ = {
		{{.LODSQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAD, 0, {force_rex_w=true, rep_ok=true}}, {implicit_wr={.RAX, .RSI}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true}},
	},
	.STOS = {
		{{.STOS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAA, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.STOSB = {
		{{.STOSB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAA, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.STOSW = {
		{{.STOSW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAB, 0, {opsize_16=true, rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.STOSD = {
		{{.STOSD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAB, 0, {rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.STOSQ = {
		{{.STOSQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAB, 0, {force_rex_w=true, rep_ok=true}}, {implicit_wr={.RCX, .RDI}, implicit_rd={.RAX, .RCX, .RDI}, flags_rd={.DF}, writes_mem=true, reads_mem=true}},
	},
	.CLC = {
		{{.CLC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF8, 0, {}}, {flags_wr={.CF}}},
	},
	.STC = {
		{{.STC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF9, 0, {}}, {flags_wr={.CF}}},
	},
	.CMC = {
		{{.CMC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF5, 0, {}}, {flags_wr={.CF}, flags_rd={.CF}}},
	},
	.CLD = {
		{{.CLD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFC, 0, {}}, {flags_wr={.DF}}},
	},
	.STD = {
		{{.STD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFD, 0, {}}, {flags_wr={.DF}}},
	},
	.CLI = {
		{{.CLI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFA, 0, {}}, {flags_wr={.IF}}},
	},
	.STI = {
		{{.STI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFB, 0, {}}, {flags_wr={.IF}}},
	},
	.LAHF = {
		{{.LAHF, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9F, 0, {}}, {implicit_wr={.RAX}, flags_rd={.CF, .PF, .AF, .ZF, .SF}}},
	},
	.SAHF = {
		{{.SAHF, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9E, 0, {}}, {implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF}}},
	},
	.PUSHF = {
		{{.PUSHF, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9C, 0, {opsize_16=true}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true}},
	},
	.PUSHFD = {
		{{.PUSHFD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9C, 0, {}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true}},
	},
	.PUSHFQ = {
		{{.PUSHFQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9C, 0, {default_64=true}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true}},
	},
	.POPF = {
		{{.POPF, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9D, 0, {opsize_16=true}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true}},
	},
	.POPFD = {
		{{.POPFD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9D, 0, {}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true}},
	},
	.POPFQ = {
		{{.POPFQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9D, 0, {default_64=true}}, {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true}},
	},
	.NOP = {
		{{.NOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x90, 0, {}},                                               {}},
		{{.NOP, {.RM16, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x1F, 0, {esc=._0F, modrm_reg_ext=true}},                   {}},
		{{.NOP, {.RM32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x1F, 0, {esc=._0F, modrm_reg_ext=true}},                   {}},
		{{.NOP, {.RM64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x1F, 0, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {}},
	},
	.HLT = {
		{{.HLT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF4, 0, {}}, {side_effects={.HALT, .PRIVILEGED}}},
	},
	.WAIT = {
		{{.WAIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9B, 0, {}}, {implicit_rd={.FPU_SW}}},
	},
	.LOCK = {
		{{.LOCK, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF0, 0, {}}, {side_effects={.FENCE}}},
	},
	.UD0 = {
		{{.UD0, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFF, 0, {esc=._0F}}, {side_effects={.TRAP}}},
	},
	.UD1 = {
		{{.UD1, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB9, 0, {esc=._0F}}, {side_effects={.TRAP}}},
	},
	.UD2 = {
		{{.UD2, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0B, 0, {esc=._0F}}, {side_effects={.TRAP}}},
	},
	.CPUID = {
		{{.CPUID, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA2, 0, {esc=._0F}}, {implicit_wr={.RAX, .RBX, .RCX, .RDX}, implicit_rd={.RAX, .RCX}, side_effects={.SERIALIZING}}},
	},
	.RDTSC = {
		{{.RDTSC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x31, 0, {esc=._0F}}, {implicit_wr={.RAX, .RDX}}},
	},
	.RDTSCP = {
		{{.RDTSCP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xF9, {esc=._0F}}, {implicit_wr={.RAX, .RCX, .RDX}}},
	},
	.RDPMC = {
		{{.RDPMC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x33, 0, {esc=._0F}}, {implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}}},
	},
	.XGETBV = {
		{{.XGETBV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD0, {esc=._0F}}, {implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}}},
	},
	.XSETBV = {
		{{.XSETBV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD1, {esc=._0F}}, {implicit_rd={.RAX, .RCX, .RDX}}},
	},
	.CBW = {
		{{.CBW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x98, 0, {opsize_16=true}}, {implicit_wr={.RAX}, implicit_rd={.RAX}}},
	},
	.CWDE = {
		{{.CWDE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x98, 0, {}}, {implicit_wr={.RAX}, implicit_rd={.RAX}}},
	},
	.CDQE = {
		{{.CDQE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x98, 0, {force_rex_w=true}}, {implicit_wr={.RAX}, implicit_rd={.RAX}}},
	},
	.CWD = {
		{{.CWD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x99, 0, {opsize_16=true}}, {implicit_wr={.RDX}, implicit_rd={.RAX}}},
	},
	.CDQ = {
		{{.CDQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x99, 0, {}}, {implicit_wr={.RDX}, implicit_rd={.RAX}}},
	},
	.CQO = {
		{{.CQO, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x99, 0, {force_rex_w=true}}, {implicit_wr={.RDX}, implicit_rd={.RAX}}},
	},
	.ANDN = {
		{{.ANDN, {.R32, .R32, .RM32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF2, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
		{{.ANDN, {.R64, .R64, .RM64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF2, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
	},
	.BEXTR = {
		{{.BEXTR, {.R32, .RM32, .R32, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, flags_wr={.CF, .ZF, .OF}, flags_undef={.PF, .AF, .SF}, reads_mem=true}},
		{{.BEXTR, {.R64, .RM64, .R64, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, flags_wr={.CF, .ZF, .OF}, flags_undef={.PF, .AF, .SF}, reads_mem=true}},
	},
	.BLSI = {
		{{.BLSI, {.R32, .RM32, .NONE, .NONE}, {.VVVV, .MR, .NONE, .NONE}, 0xF3, 3, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
		{{.BLSI, {.R64, .RM64, .NONE, .NONE}, {.VVVV, .MR, .NONE, .NONE}, 0xF3, 3, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
	},
	.BLSMSK = {
		{{.BLSMSK, {.R32, .RM32, .NONE, .NONE}, {.VVVV, .MR, .NONE, .NONE}, 0xF3, 2, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
		{{.BLSMSK, {.R64, .RM64, .NONE, .NONE}, {.VVVV, .MR, .NONE, .NONE}, 0xF3, 2, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
	},
	.BLSR = {
		{{.BLSR, {.R32, .RM32, .NONE, .NONE}, {.VVVV, .MR, .NONE, .NONE}, 0xF3, 1, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
		{{.BLSR, {.R64, .RM64, .NONE, .NONE}, {.VVVV, .MR, .NONE, .NONE}, 0xF3, 1, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
	},
	.BZHI = {
		{{.BZHI, {.R32, .RM32, .R32, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF5, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
		{{.BZHI, {.R64, .RM64, .R64, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF5, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, flags_wr={.CF, .ZF, .SF, .OF}, flags_undef={.PF, .AF}, reads_mem=true}},
	},
	.PDEP = {
		{{.PDEP, {.R32, .R32, .RM32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.PDEP, {.R64, .R64, .RM64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PEXT = {
		{{.PEXT, {.R32, .R32, .RM32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.PEXT, {.R64, .R64, .RM64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.RORX = {
		{{.RORX, {.R32, .RM32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xF0, 0, {esc=._0F3A, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.RORX, {.R64, .RM64, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xF0, 0, {esc=._0F3A, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
	},
	.SARX = {
		{{.SARX, {.R32, .RM32, .R32, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.SARX, {.R64, .RM64, .R64, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.SHLX = {
		{{.SHLX, {.R32, .RM32, .R32, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.SHLX, {.R64, .RM64, .R64, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.SHRX = {
		{{.SHRX, {.R32, .RM32, .R32, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.SHRX, {.R64, .RM64, .R64, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.MULX = {
		{{.MULX, {.R32, .R32, .RM32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0, 1}, read={2}, implicit_rd={.RDX}, reads_mem=true}},
		{{.MULX, {.R64, .R64, .RM64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0, 1}, read={2}, implicit_rd={.RDX}, reads_mem=true}},
	},
	.ADCX = {
		{{.ADCX, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_66}},                   {written={0}, read={0, 1}, flags_wr={.CF}, flags_rd={.CF}, reads_mem=true}},
		{{.ADCX, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_66, force_rex_w=true}}, {written={0}, read={0, 1}, flags_wr={.CF}, flags_rd={.CF}, reads_mem=true}},
	},
	.ADOX = {
		{{.ADOX, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_F3}},                   {written={0}, read={0, 1}, flags_wr={.OF}, flags_rd={.OF}, reads_mem=true}},
		{{.ADOX, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_F3, force_rex_w=true}}, {written={0}, read={0, 1}, flags_wr={.OF}, flags_rd={.OF}, reads_mem=true}},
	},
	.MOVAPS = {
		{{.MOVAPS, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x28, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVAPS, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x29, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVUPS = {
		{{.MOVUPS, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVUPS, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVAPD = {
		{{.MOVAPD, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x28, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVAPD, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x29, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVUPD = {
		{{.MOVUPD, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVUPD, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVSS = {
		{{.MOVSS, {.XMM,     .XMM_M32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVSS, {.XMM_M32, .XMM,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVDQA = {
		{{.MOVDQA, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVDQA, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVDQU = {
		{{.MOVDQU, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVDQU, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVQ = {
		{{.MOVQ, {.XMM,     .XMM_M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVQ, {.XMM_M64, .XMM,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xD6, 0, {esc=._0F, prefix=PREFIX_66}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVQ, {.MM,      .MM_M64,  .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVQ, {.MM_M64,  .MM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F}},                                     {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVQ, {.R64,     .XMM,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}}, {written={0}, read={1}}},
		{{.MOVQ, {.XMM,     .R64,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6E, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}}, {written={0}, read={1}}},
	},
	.MOVD = {
		{{.MOVD, {.XMM,  .RM32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6E, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVD, {.RM32, .XMM,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVD, {.MM,   .RM32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6E, 0, {esc=._0F}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVD, {.RM32, .MM,   .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7E, 0, {esc=._0F}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVLPS = {
		{{.MOVLPS, {.XMM, .M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x12, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVLPS, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVHPS = {
		{{.MOVHPS, {.XMM, .M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x16, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVHPS, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x17, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVLPD = {
		{{.MOVLPD, {.XMM, .M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVLPD, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVHPD = {
		{{.MOVHPD, {.XMM, .M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x16, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVHPD, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x17, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVLHPS = {
		{{.MOVLHPS, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x16, 0, {esc=._0F}}, {written={0}, read={1}}},
	},
	.MOVHLPS = {
		{{.MOVHLPS, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F}}, {written={0}, read={1}}},
	},
	.MOVMSKPS = {
		{{.MOVMSKPS, {.R32, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x50, 0, {esc=._0F}},                   {written={0}, read={1}}},
		{{.MOVMSKPS, {.R64, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x50, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}}},
	},
	.MOVMSKPD = {
		{{.MOVMSKPD, {.R32, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x50, 0, {esc=._0F, prefix=PREFIX_66}},                   {written={0}, read={1}}},
		{{.MOVMSKPD, {.R64, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x50, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}}, {written={0}, read={1}}},
	},
	.MOVNTPS = {
		{{.MOVNTPS, {.M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x2B, 0, {esc=._0F}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVNTPD = {
		{{.MOVNTPD, {.M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x2B, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVNTDQ = {
		{{.MOVNTDQ, {.M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xE7, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.MOVNTDQA = {
		{{.MOVNTDQA, {.XMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.ADDPS = {
		{{.ADDPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.ADDPD = {
		{{.ADDPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.ADDSS = {
		{{.ADDSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.ADDSD = {
		{{.ADDSD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.SUBPS = {
		{{.SUBPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5C, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.SUBPD = {
		{{.SUBPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.SUBSS = {
		{{.SUBSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.SUBSD = {
		{{.SUBSD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MULPS = {
		{{.MULPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MULPD = {
		{{.MULPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MULSS = {
		{{.MULSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MULSD = {
		{{.MULSD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.DIVPS = {
		{{.DIVPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5E, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.DIVPD = {
		{{.DIVPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.DIVSS = {
		{{.DIVSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.DIVSD = {
		{{.DIVSD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.SQRTPS = {
		{{.SQRTPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.SQRTPD = {
		{{.SQRTPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.SQRTSS = {
		{{.SQRTSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.SQRTSD = {
		{{.SQRTSD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.RCPPS = {
		{{.RCPPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x53, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.RCPSS = {
		{{.RCPSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x53, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.RSQRTPS = {
		{{.RSQRTPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x52, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.RSQRTSS = {
		{{.RSQRTSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x52, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MAXPS = {
		{{.MAXPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5F, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MAXPD = {
		{{.MAXPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MAXSS = {
		{{.MAXSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MAXSD = {
		{{.MAXSD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MINPS = {
		{{.MINPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5D, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MINPD = {
		{{.MINPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MINSS = {
		{{.MINSS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MINSD = {
		{{.MINSD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.ANDPS = {
		{{.ANDPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x54, 0, {esc=._0F}}, {written={0}, read={1}, reads_mem=true}},
	},
	.ANDPD = {
		{{.ANDPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x54, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.ANDNPS = {
		{{.ANDNPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x55, 0, {esc=._0F}}, {written={0}, read={1}, reads_mem=true}},
	},
	.ANDNPD = {
		{{.ANDNPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x55, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.ORPS = {
		{{.ORPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x56, 0, {esc=._0F}}, {written={0}, read={1}, reads_mem=true}},
	},
	.ORPD = {
		{{.ORPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x56, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.XORPS = {
		{{.XORPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x57, 0, {esc=._0F}}, {written={0}, read={1}, reads_mem=true}},
	},
	.XORPD = {
		{{.XORPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x57, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.CMPPS = {
		{{.CMPPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC2, 0, {esc=._0F}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CMPPD = {
		{{.CMPPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC2, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CMPSS = {
		{{.CMPSS, {.XMM, .XMM_M32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC2, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.COMISS = {
		{{.COMISS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2F, 0, {esc=._0F}}, {read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true}},
	},
	.COMISD = {
		{{.COMISD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2F, 0, {esc=._0F, prefix=PREFIX_66}}, {read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true}},
	},
	.UCOMISS = {
		{{.UCOMISS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2E, 0, {esc=._0F}}, {read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true}},
	},
	.UCOMISD = {
		{{.UCOMISD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2E, 0, {esc=._0F, prefix=PREFIX_66}}, {read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true}},
	},
	.SHUFPS = {
		{{.SHUFPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC6, 0, {esc=._0F}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.SHUFPD = {
		{{.SHUFPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC6, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.UNPCKLPS = {
		{{.UNPCKLPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x14, 0, {esc=._0F}}, {written={0}, read={1}, reads_mem=true}},
	},
	.UNPCKHPS = {
		{{.UNPCKHPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x15, 0, {esc=._0F}}, {written={0}, read={1}, reads_mem=true}},
	},
	.UNPCKLPD = {
		{{.UNPCKLPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x14, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.UNPCKHPD = {
		{{.UNPCKHPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x15, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.CVTPS2PD = {
		{{.CVTPS2PD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTPD2PS = {
		{{.CVTPD2PS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTSS2SD = {
		{{.CVTSS2SD, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTSD2SS = {
		{{.CVTSD2SS, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTPS2DQ = {
		{{.CVTPS2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTPD2DQ = {
		{{.CVTPD2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTDQ2PS = {
		{{.CVTDQ2PS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTDQ2PD = {
		{{.CVTDQ2PD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTSS2SI = {
		{{.CVTSS2SI, {.R32, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.CVTSS2SI, {.R64, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTSD2SI = {
		{{.CVTSD2SI, {.R32, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F2}},                   {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.CVTSD2SI, {.R64, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F2, force_rex_w=true}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTSI2SS = {
		{{.CVTSI2SS, {.XMM, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.CVTSI2SS, {.XMM, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTSI2SD = {
		{{.CVTSI2SD, {.XMM, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F2}},                   {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.CVTSI2SD, {.XMM, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F2, force_rex_w=true}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTTPS2DQ = {
		{{.CVTTPS2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTTPD2DQ = {
		{{.CVTTPD2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTTSS2SI = {
		{{.CVTTSS2SI, {.R32, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F3}},                   {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.CVTTSS2SI, {.R64, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.CVTTSD2SI = {
		{{.CVTTSD2SI, {.R32, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F2}},                   {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.CVTTSD2SI, {.R64, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F2, force_rex_w=true}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.PADDB = {
		{{.PADDB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFC, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PADDW = {
		{{.PADDW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFD, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PADDD = {
		{{.PADDD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFE, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PADDQ = {
		{{.PADDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD4, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSUBB = {
		{{.PSUBB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF8, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSUBW = {
		{{.PSUBW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF9, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSUBD = {
		{{.PSUBD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFA, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSUBQ = {
		{{.PSUBQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFB, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PADDSB = {
		{{.PADDSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEC, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PADDSW = {
		{{.PADDSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xED, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PADDUSB = {
		{{.PADDUSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDC, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PADDUSW = {
		{{.PADDUSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDD, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSUBSB = {
		{{.PSUBSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE8, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSUBSW = {
		{{.PSUBSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE9, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSUBUSB = {
		{{.PSUBUSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD8, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSUBUSW = {
		{{.PSUBUSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD9, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMULLW = {
		{{.PMULLW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD5, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMULHW = {
		{{.PMULHW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE5, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMULHUW = {
		{{.PMULHUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE4, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMULUDQ = {
		{{.PMULUDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF4, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMADDWD = {
		{{.PMADDWD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF5, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PAND = {
		{{.PAND, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDB, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PANDN = {
		{{.PANDN, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDF, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.POR = {
		{{.POR, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEB, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PXOR = {
		{{.PXOR, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEF, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSLLW = {
		{{.PSLLW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF1, 0, {esc=._0F, prefix=PREFIX_66}},                     {written={0}, read={1}, reads_mem=true}},
		{{.PSLLW, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x71, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {written={0}, read={1}}},
	},
	.PSLLD = {
		{{.PSLLD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF2, 0, {esc=._0F, prefix=PREFIX_66}},                     {written={0}, read={1}, reads_mem=true}},
		{{.PSLLD, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x72, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {written={0}, read={1}}},
	},
	.PSLLQ = {
		{{.PSLLQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF3, 0, {esc=._0F, prefix=PREFIX_66}},                     {written={0}, read={1}, reads_mem=true}},
		{{.PSLLQ, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x73, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {written={0}, read={1}}},
	},
	.PSRLW = {
		{{.PSRLW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD1, 0, {esc=._0F, prefix=PREFIX_66}},                     {written={0}, read={1}, reads_mem=true}},
		{{.PSRLW, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x71, 2, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {written={0}, read={1}}},
	},
	.PSRLD = {
		{{.PSRLD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD2, 0, {esc=._0F, prefix=PREFIX_66}},                     {written={0}, read={1}, reads_mem=true}},
		{{.PSRLD, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x72, 2, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {written={0}, read={1}}},
	},
	.PSRLQ = {
		{{.PSRLQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD3, 0, {esc=._0F, prefix=PREFIX_66}},                     {written={0}, read={1}, reads_mem=true}},
		{{.PSRLQ, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x73, 2, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {written={0}, read={1}}},
	},
	.PSRAW = {
		{{.PSRAW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE1, 0, {esc=._0F, prefix=PREFIX_66}},                     {written={0}, read={1}, reads_mem=true}},
		{{.PSRAW, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x71, 4, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {written={0}, read={1}}},
	},
	.PSRAD = {
		{{.PSRAD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE2, 0, {esc=._0F, prefix=PREFIX_66}},                     {written={0}, read={1}, reads_mem=true}},
		{{.PSRAD, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x72, 4, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {written={0}, read={1}}},
	},
	.PCMPEQB = {
		{{.PCMPEQB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x74, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PCMPEQW = {
		{{.PCMPEQW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x75, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PCMPEQD = {
		{{.PCMPEQD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x76, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PCMPGTB = {
		{{.PCMPGTB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x64, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PCMPGTW = {
		{{.PCMPGTW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x65, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PCMPGTD = {
		{{.PCMPGTD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x66, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PACKSSWB = {
		{{.PACKSSWB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x63, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PACKSSDW = {
		{{.PACKSSDW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x6B, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PACKUSWB = {
		{{.PACKUSWB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x67, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PUNPCKLBW = {
		{{.PUNPCKLBW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x60, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PUNPCKLWD = {
		{{.PUNPCKLWD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x61, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PUNPCKLDQ = {
		{{.PUNPCKLDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x62, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PUNPCKLQDQ = {
		{{.PUNPCKLQDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x6C, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PUNPCKHBW = {
		{{.PUNPCKHBW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x68, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PUNPCKHWD = {
		{{.PUNPCKHWD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x69, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PUNPCKHDQ = {
		{{.PUNPCKHDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x6A, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PUNPCKHQDQ = {
		{{.PUNPCKHQDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x6D, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSHUFD = {
		{{.PSHUFD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PSHUFHW = {
		{{.PSHUFHW, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PSHUFLW = {
		{{.PSHUFLW, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PSHUFW = {
		{{.PSHUFW, {.MM, .MM_M64, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PEXTRW = {
		{{.PEXTRW, {.R32, .XMM, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC5, 0, {esc=._0F, prefix=PREFIX_66}},                   {written={0}, read={1}}},
		{{.PEXTRW, {.R64, .XMM, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC5, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}}, {written={0}, read={1}}},
	},
	.PINSRW = {
		{{.PINSRW, {.XMM, .R32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC4, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1, 2}}},
		{{.PINSRW, {.XMM, .M16, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC4, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PMOVMSKB = {
		{{.PMOVMSKB, {.R32, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD7, 0, {esc=._0F, prefix=PREFIX_66}},                   {written={0}, read={1}}},
		{{.PMOVMSKB, {.R64, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD7, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}}, {written={0}, read={1}}},
	},
	.PAVGB = {
		{{.PAVGB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE0, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PAVGW = {
		{{.PAVGW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE3, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMAXUB = {
		{{.PMAXUB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDE, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMAXSW = {
		{{.PMAXSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEE, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMINUB = {
		{{.PMINUB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDA, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMINSW = {
		{{.PMINSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEA, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSADBW = {
		{{.PSADBW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF6, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.MASKMOVDQU = {
		{{.MASKMOVDQU, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF7, 0, {esc=._0F, prefix=PREFIX_66}}, {read={0, 1}, implicit_rd={.RDI}, flags_rd={.DF}, writes_mem=true}},
	},
	.LFENCE = {
		{{.LFENCE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0xE8, {esc=._0F}}, {side_effects={.FENCE, .SERIALIZING}}},
	},
	.SFENCE = {
		{{.SFENCE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0xF8, {esc=._0F}}, {side_effects={.FENCE}}},
	},
	.MFENCE = {
		{{.MFENCE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0xF0, {esc=._0F}}, {side_effects={.FENCE}}},
	},
	.PAUSE = {
		{{.PAUSE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x90, 0, {prefix=PREFIX_F3}}, {side_effects={.HINT}}},
	},
	.CLFLUSH = {
		{{.CLFLUSH, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 7, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.CACHE}}},
	},
	.ADDSUBPS = {
		{{.ADDSUBPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD0, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.ADDSUBPD = {
		{{.ADDSUBPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD0, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.HADDPS = {
		{{.HADDPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x7C, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.HADDPD = {
		{{.HADDPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x7C, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.HSUBPS = {
		{{.HSUBPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x7D, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.HSUBPD = {
		{{.HSUBPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x7D, 0, {esc=._0F, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.MOVDDUP = {
		{{.MOVDDUP, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.MOVSLDUP = {
		{{.MOVSLDUP, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, reads_mem=true}},
	},
	.MOVSHDUP = {
		{{.MOVSHDUP, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x16, 0, {esc=._0F, prefix=PREFIX_F3}}, {written={0}, read={1}, reads_mem=true}},
	},
	.LDDQU = {
		{{.LDDQU, {.XMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF0, 0, {esc=._0F, prefix=PREFIX_F2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSHUFB = {
		{{.PSHUFB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x00, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PHADDW = {
		{{.PHADDW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x01, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PHADDD = {
		{{.PHADDD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x02, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PHADDSW = {
		{{.PHADDSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x03, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PHSUBW = {
		{{.PHSUBW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x05, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PHSUBD = {
		{{.PHSUBD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x06, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PHSUBSW = {
		{{.PHSUBSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x07, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMADDUBSW = {
		{{.PMADDUBSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x04, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMULHRSW = {
		{{.PMULHRSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0B, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSIGNB = {
		{{.PSIGNB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x08, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSIGNW = {
		{{.PSIGNW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x09, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PSIGND = {
		{{.PSIGND, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0A, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PABSB = {
		{{.PABSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1C, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PABSW = {
		{{.PABSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1D, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PABSD = {
		{{.PABSD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1E, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PALIGNR = {
		{{.PALIGNR, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0F, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.BLENDPS = {
		{{.BLENDPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0C, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.BLENDPD = {
		{{.BLENDPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0D, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.BLENDVPS = {
		{{.BLENDVPS, {.XMM, .XMM_M128, .XMM0_IMPL, .NONE}, {.REG, .MR, .IMPL, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_rd={.XMM0}, reads_mem=true}},
	},
	.BLENDVPD = {
		{{.BLENDVPD, {.XMM, .XMM_M128, .XMM0_IMPL, .NONE}, {.REG, .MR, .IMPL, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_rd={.XMM0}, reads_mem=true}},
	},
	.PBLENDW = {
		{{.PBLENDW, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0E, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PBLENDVB = {
		{{.PBLENDVB, {.XMM, .XMM_M128, .XMM0_IMPL, .NONE}, {.REG, .MR, .IMPL, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, implicit_rd={.XMM0}, reads_mem=true}},
	},
	.DPPS = {
		{{.DPPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x40, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.DPPD = {
		{{.DPPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x41, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.EXTRACTPS = {
		{{.EXTRACTPS, {.RM32, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x17, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true}},
	},
	.INSERTPS = {
		{{.INSERTPS, {.XMM, .XMM_M32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x21, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.MPSADBW = {
		{{.MPSADBW, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PACKUSDW = {
		{{.PACKUSDW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2B, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PEXTRB = {
		{{.PEXTRB, {.RM8, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x14, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true}},
	},
	.PEXTRD = {
		{{.PEXTRD, {.RM32, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x16, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1}, writes_mem=true}},
	},
	.PEXTRQ = {
		{{.PEXTRQ, {.RM64, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x16, 0, {esc=._0F3A, prefix=PREFIX_66, force_rex_w=true}}, {written={0}, read={1}, writes_mem=true}},
	},
	.PHMINPOSUW = {
		{{.PHMINPOSUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PINSRB = {
		{{.PINSRB, {.XMM, .RM8, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x20, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PINSRD = {
		{{.PINSRD, {.XMM, .RM32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x22, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PINSRQ = {
		{{.PINSRQ, {.XMM, .RM64, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x22, 0, {esc=._0F3A, prefix=PREFIX_66, force_rex_w=true}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.PMAXSB = {
		{{.PMAXSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3C, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMAXSD = {
		{{.PMAXSD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3D, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMAXUW = {
		{{.PMAXUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3E, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMAXUD = {
		{{.PMAXUD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3F, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMINSB = {
		{{.PMINSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMINSD = {
		{{.PMINSD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMINUW = {
		{{.PMINUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3A, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMINUD = {
		{{.PMINUD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3B, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVSXBW = {
		{{.PMOVSXBW, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVSXBD = {
		{{.PMOVSXBD, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVSXBQ = {
		{{.PMOVSXBQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVSXWD = {
		{{.PMOVSXWD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVSXWQ = {
		{{.PMOVSXWQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVSXDQ = {
		{{.PMOVSXDQ, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVZXBW = {
		{{.PMOVZXBW, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVZXBD = {
		{{.PMOVZXBD, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVZXBQ = {
		{{.PMOVZXBQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVZXWD = {
		{{.PMOVZXWD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVZXWQ = {
		{{.PMOVZXWQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMOVZXDQ = {
		{{.PMOVZXDQ, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMULDQ = {
		{{.PMULDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PMULLD = {
		{{.PMULLD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x40, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PTEST = {
		{{.PTEST, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x17, 0, {esc=._0F38, prefix=PREFIX_66}}, {read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.ROUNDPS = {
		{{.ROUNDPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.ROUNDPD = {
		{{.ROUNDPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.ROUNDSS = {
		{{.ROUNDSS, {.XMM, .XMM_M32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0A, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.ROUNDSD = {
		{{.ROUNDSD, {.XMM, .XMM_M64, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0B, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.PCMPEQQ = {
		{{.PCMPEQQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.CRC32 = {
		{{.CRC32, {.R32, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF0, 0, {esc=._0F38, prefix=PREFIX_F2}},                   {written={0}, read={0, 1}, reads_mem=true}},
		{{.CRC32, {.R32, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF1, 0, {esc=._0F38, prefix=PREFIX_F2}},                   {written={0}, read={0, 1}, reads_mem=true}},
		{{.CRC32, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF1, 0, {esc=._0F38, prefix=PREFIX_F2}},                   {written={0}, read={0, 1}, reads_mem=true}},
		{{.CRC32, {.R64, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF0, 0, {esc=._0F38, prefix=PREFIX_F2, force_rex_w=true}}, {written={0}, read={0, 1}, reads_mem=true}},
		{{.CRC32, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF1, 0, {esc=._0F38, prefix=PREFIX_F2, force_rex_w=true}}, {written={0}, read={0, 1}, reads_mem=true}},
	},
	.PCMPESTRI = {
		{{.PCMPESTRI, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x61, 0, {esc=._0F3A, prefix=PREFIX_66}}, {implicit_wr={.RCX}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.PCMPESTRM = {
		{{.PCMPESTRM, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x60, 0, {esc=._0F3A, prefix=PREFIX_66}}, {implicit_wr={.XMM0}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.PCMPISTRI = {
		{{.PCMPISTRI, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x63, 0, {esc=._0F3A, prefix=PREFIX_66}}, {implicit_wr={.RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.PCMPISTRM = {
		{{.PCMPISTRM, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x62, 0, {esc=._0F3A, prefix=PREFIX_66}}, {implicit_wr={.XMM0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.PCMPGTQ = {
		{{.PCMPGTQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x37, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.PCLMULQDQ = {
		{{.PCLMULQDQ, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x44, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.AESDEC = {
		{{.AESDEC, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDE, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.AESDECLAST = {
		{{.AESDECLAST, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDF, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.AESENC = {
		{{.AESENC, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDC, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.AESENCLAST = {
		{{.AESENCLAST, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDD, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.AESIMC = {
		{{.AESIMC, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDB, 0, {esc=._0F38, prefix=PREFIX_66}}, {written={0}, read={1}, reads_mem=true}},
	},
	.AESKEYGENASSIST = {
		{{.AESKEYGENASSIST, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xDF, 0, {esc=._0F3A, prefix=PREFIX_66}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.SHA1MSG1 = {
		{{.SHA1MSG1, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC9, 0, {esc=._0F38}}, {written={0}, read={1}, reads_mem=true}},
	},
	.SHA1MSG2 = {
		{{.SHA1MSG2, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xCA, 0, {esc=._0F38}}, {written={0}, read={1}, reads_mem=true}},
	},
	.SHA1NEXTE = {
		{{.SHA1NEXTE, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC8, 0, {esc=._0F38}}, {written={0}, read={1}, reads_mem=true}},
	},
	.SHA1RNDS4 = {
		{{.SHA1RNDS4, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xCC, 0, {esc=._0F3A}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.SHA256MSG1 = {
		{{.SHA256MSG1, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xCC, 0, {esc=._0F38}}, {written={0}, read={1}, reads_mem=true}},
	},
	.SHA256MSG2 = {
		{{.SHA256MSG2, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xCD, 0, {esc=._0F38}}, {written={0}, read={1}, reads_mem=true}},
	},
	.SHA256RNDS2 = {
		{{.SHA256RNDS2, {.XMM, .XMM_M128, .XMM0_IMPL, .NONE}, {.REG, .MR, .IMPL, .NONE}, 0xCB, 0, {esc=._0F38}}, {written={0}, read={1}, implicit_rd={.XMM0}, reads_mem=true}},
	},
	.VADDPS = {
		{{.VADDPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VADDPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VADDPD = {
		{{.VADDPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VADDPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VADDSS = {
		{{.VADDSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VADDSD = {
		{{.VADDSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSUBPS = {
		{{.VSUBPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VSUBPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSUBPD = {
		{{.VSUBPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VSUBPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSUBSS = {
		{{.VSUBSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSUBSD = {
		{{.VSUBSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMULPS = {
		{{.VMULPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VMULPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMULPD = {
		{{.VMULPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VMULPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMULSS = {
		{{.VMULSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMULSD = {
		{{.VMULSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VDIVPS = {
		{{.VDIVPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VDIVPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VDIVPD = {
		{{.VDIVPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VDIVPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VDIVSS = {
		{{.VDIVSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VDIVSD = {
		{{.VDIVSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSQRTPS = {
		{{.VSQRTPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VSQRTPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSQRTPD = {
		{{.VSQRTPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VSQRTPD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSQRTSS = {
		{{.VSQRTSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSQRTSD = {
		{{.VSQRTSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRCPPS = {
		{{.VRCPPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x53, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRCPPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x53, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRCPSS = {
		{{.VRCPSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x53, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRSQRTPS = {
		{{.VRSQRTPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x52, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRSQRTPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x52, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRSQRTSS = {
		{{.VRSQRTSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x52, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMAXPS = {
		{{.VMAXPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VMAXPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMAXPD = {
		{{.VMAXPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VMAXPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMAXSS = {
		{{.VMAXSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMAXSD = {
		{{.VMAXSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMINPS = {
		{{.VMINPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VMINPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMINPD = {
		{{.VMINPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VMINPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMINSS = {
		{{.VMINSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VMINSD = {
		{{.VMINSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VANDPS = {
		{{.VANDPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x54, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VANDPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x54, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VANDPD = {
		{{.VANDPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x54, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VANDPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x54, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VANDNPS = {
		{{.VANDNPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x55, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VANDNPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x55, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VANDNPD = {
		{{.VANDNPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x55, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VANDNPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x55, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VORPS = {
		{{.VORPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x56, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VORPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x56, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VORPD = {
		{{.VORPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x56, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VORPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x56, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VXORPS = {
		{{.VXORPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x57, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VXORPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x57, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VXORPD = {
		{{.VXORPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x57, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VXORPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x57, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VCMPPS = {
		{{.VCMPPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCMPPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCMPPD = {
		{{.VCMPPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCMPPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCMPSS = {
		{{.VCMPSS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCMPSD = {
		{{.VCMPSD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCOMISS = {
		{{.VCOMISS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2F, 0, {esc=._0F, vex_type=.VEX}}, {read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true}},
	},
	.VCOMISD = {
		{{.VCOMISD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX}}, {read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true}},
	},
	.VUCOMISS = {
		{{.VUCOMISS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2E, 0, {esc=._0F, vex_type=.VEX}}, {read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true}},
	},
	.VUCOMISD = {
		{{.VUCOMISD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX}}, {read={0, 1}, implicit_wr={.MXCSR}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}, reads_mem=true}},
	},
	.VSHUFPS = {
		{{.VSHUFPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC6, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VSHUFPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC6, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VSHUFPD = {
		{{.VSHUFPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VSHUFPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VUNPCKLPS = {
		{{.VUNPCKLPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VUNPCKLPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VUNPCKHPS = {
		{{.VUNPCKHPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VUNPCKHPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VUNPCKLPD = {
		{{.VUNPCKLPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VUNPCKLPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VUNPCKHPD = {
		{{.VUNPCKHPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VUNPCKHPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VBLENDPS = {
		{{.VBLENDPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0C, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VBLENDPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0C, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VBLENDPD = {
		{{.VBLENDPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VBLENDPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VBLENDVPS = {
		{{.VBLENDVPS, {.XMM, .XMM, .XMM_M128, .XMM}, {.REG, .VVVV, .MR, .IS4}, 0x4A, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VBLENDVPS, {.YMM, .YMM, .YMM_M256, .YMM}, {.REG, .VVVV, .MR, .IS4}, 0x4A, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VBLENDVPD = {
		{{.VBLENDVPD, {.XMM, .XMM, .XMM_M128, .XMM}, {.REG, .VVVV, .MR, .IS4}, 0x4B, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VBLENDVPD, {.YMM, .YMM, .YMM_M256, .YMM}, {.REG, .VVVV, .MR, .IS4}, 0x4B, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VDPPS = {
		{{.VDPPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x40, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VDPPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x40, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VDPPD = {
		{{.VDPPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x41, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VROUNDPS = {
		{{.VROUNDPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VROUNDPS, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VROUNDPD = {
		{{.VROUNDPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VROUNDPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VROUNDSS = {
		{{.VROUNDSS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0A, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VROUNDSD = {
		{{.VROUNDSD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0B, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VEXTRACTPS = {
		{{.VEXTRACTPS, {.RM32, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x17, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true}},
	},
	.VINSERTPS = {
		{{.VINSERTPS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x21, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VMOVAPS = {
		{{.VMOVAPS, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x28, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVAPS, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x29, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVAPS, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x28, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVAPS, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x29, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVUPS = {
		{{.VMOVUPS, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVUPS, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVUPS, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVUPS, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVAPD = {
		{{.VMOVAPD, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x28, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVAPD, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x29, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVAPD, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x28, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVAPD, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x29, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVUPD = {
		{{.VMOVUPD, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVUPD, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVUPD, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVUPD, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVSS = {
		{{.VMOVSS, {.XMM, .M32, .NONE, .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVSS, {.M32, .XMM, .NONE, .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVSS, {.XMM, .XMM, .XMM,  .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}}},
	},
	.VMOVSD = {
		{{.VMOVSD, {.XMM, .M64, .NONE, .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVSD, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVSD, {.XMM, .XMM, .XMM,  .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}}},
	},
	.VMOVDQA = {
		{{.VMOVDQA, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVDQA, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVDQA, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVDQA, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVDQU = {
		{{.VMOVDQU, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVDQU, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVDQU, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVDQU, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVQ = {
		{{.VMOVQ, {.XMM,     .XMM_M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}},            {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVQ, {.XMM_M64, .XMM,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xD6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},            {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVQ, {.XMM,     .R64,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VMOVQ, {.R64,     .XMM,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.VMOVD = {
		{{.VMOVD, {.XMM,  .RM32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVD, {.RM32, .XMM,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVLPS = {
		{{.VMOVLPS, {.XMM, .XMM, .M64,  .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x12, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMOVLPS, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x13, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVHPS = {
		{{.VMOVHPS, {.XMM, .XMM, .M64,  .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x16, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMOVHPS, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x17, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVLPD = {
		{{.VMOVLPD, {.XMM, .XMM, .M64,  .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMOVLPD, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x13, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVHPD = {
		{{.VMOVHPD, {.XMM, .XMM, .M64,  .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x16, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMOVHPD, {.M64, .XMM, .NONE, .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x17, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVLHPS = {
		{{.VMOVLHPS, {.XMM, .XMM, .XMM, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x16, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.VMOVHLPS = {
		{{.VMOVHLPS, {.XMM, .XMM, .XMM, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x12, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.VMOVMSKPS = {
		{{.VMOVMSKPS, {.R32, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x50, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VMOVMSKPS, {.R32, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x50, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}}},
	},
	.VMOVMSKPD = {
		{{.VMOVMSKPD, {.R32, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x50, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VMOVMSKPD, {.R32, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x50, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}}},
	},
	.VMOVNTPS = {
		{{.VMOVNTPS, {.M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x2B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVNTPS, {.M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x2B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVNTPD = {
		{{.VMOVNTPD, {.M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x2B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVNTPD, {.M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x2B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVNTDQ = {
		{{.VMOVNTDQ, {.M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xE7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.VMOVNTDQ, {.M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xE7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.VMOVNTDQA = {
		{{.VMOVNTDQA, {.XMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVNTDQA, {.YMM, .M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VADDSUBPS = {
		{{.VADDSUBPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xD0, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VADDSUBPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xD0, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VADDSUBPD = {
		{{.VADDSUBPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xD0, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VADDSUBPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xD0, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VHADDPS = {
		{{.VHADDPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7C, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VHADDPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7C, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VHADDPD = {
		{{.VHADDPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VHADDPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VHSUBPS = {
		{{.VHSUBPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VHSUBPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VHSUBPD = {
		{{.VHSUBPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VHSUBPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VLDDQU = {
		{{.VLDDQU, {.XMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF0, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VLDDQU, {.YMM, .M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF0, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VMOVDDUP = {
		{{.VMOVDDUP, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDDUP, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VMOVSLDUP = {
		{{.VMOVSLDUP, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVSLDUP, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VMOVSHDUP = {
		{{.VMOVSHDUP, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x16, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVSHDUP, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x16, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPCMPESTRI = {
		{{.VPCMPESTRI, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x61, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {implicit_wr={.RCX}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.VPCMPESTRM = {
		{{.VPCMPESTRM, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x60, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {implicit_wr={.XMM0}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.VPCMPISTRI = {
		{{.VPCMPISTRI, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x63, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {implicit_wr={.RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.VPCMPISTRM = {
		{{.VPCMPISTRM, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x62, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {implicit_wr={.XMM0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.VPBROADCASTB = {
		{{.VPBROADCASTB, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x78, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPBROADCASTB, {.YMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x78, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPBROADCASTB, {.XMM, .M8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x78, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPBROADCASTB, {.YMM, .M8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x78, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPBROADCASTW = {
		{{.VPBROADCASTW, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x79, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPBROADCASTW, {.YMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x79, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPBROADCASTW, {.XMM, .M16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x79, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPBROADCASTW, {.YMM, .M16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x79, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPBROADCASTD = {
		{{.VPBROADCASTD, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPBROADCASTD, {.YMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPBROADCASTD, {.XMM, .M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPBROADCASTD, {.YMM, .M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPBROADCASTQ = {
		{{.VPBROADCASTQ, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPBROADCASTQ, {.YMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPBROADCASTQ, {.XMM, .M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPBROADCASTQ, {.YMM, .M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VCVTPS2PD = {
		{{.VCVTPS2PD, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTPS2PD, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTPD2PS = {
		{{.VCVTPD2PS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTPD2PS, {.XMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTSS2SD = {
		{{.VCVTSS2SD, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTSD2SS = {
		{{.VCVTSD2SS, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTPS2DQ = {
		{{.VCVTPS2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTPS2DQ, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTPD2DQ = {
		{{.VCVTPD2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTPD2DQ, {.XMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTDQ2PS = {
		{{.VCVTDQ2PS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTDQ2PS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTDQ2PD = {
		{{.VCVTDQ2PD, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTDQ2PD, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTSS2SI = {
		{{.VCVTSS2SI, {.R32, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}},            {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTSS2SI, {.R64, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTSD2SI = {
		{{.VCVTSD2SI, {.R32, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}},            {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTSD2SI, {.R64, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTSI2SS = {
		{{.VCVTSI2SS, {.XMM, .XMM, .RM32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}},            {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTSI2SS, {.XMM, .XMM, .RM64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTSI2SD = {
		{{.VCVTSI2SD, {.XMM, .XMM, .RM32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}},            {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTSI2SD, {.XMM, .XMM, .RM64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTTPS2DQ = {
		{{.VCVTTPS2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTTPS2DQ, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTTPD2DQ = {
		{{.VCVTTPD2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTTPD2DQ, {.XMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTTSS2SI = {
		{{.VCVTTSS2SI, {.R32, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX}},            {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTTSS2SI, {.R64, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTTSD2SI = {
		{{.VCVTTSD2SI, {.R32, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX}},            {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTTSD2SI, {.R64, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VPADDB = {
		{{.VPADDB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFC, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPADDB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFC, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPADDW = {
		{{.VPADDW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFD, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPADDW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFD, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPADDD = {
		{{.VPADDD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFE, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPADDD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFE, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPADDQ = {
		{{.VPADDQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xD4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPADDQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xD4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSUBB = {
		{{.VPSUBB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF8, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSUBB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF8, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSUBW = {
		{{.VPSUBW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF9, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSUBW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF9, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSUBD = {
		{{.VPSUBD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFA, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSUBD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFA, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSUBQ = {
		{{.VPSUBQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSUBQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xFB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMULLW = {
		{{.VPMULLW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xD5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULLW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xD5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMULHW = {
		{{.VPMULHW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xE5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULHW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xE5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMULHUW = {
		{{.VPMULHUW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xE4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULHUW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xE4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMULUDQ = {
		{{.VPMULUDQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULUDQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMADDWD = {
		{{.VPMADDWD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMADDWD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xF5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPAND = {
		{{.VPAND, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xDB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPAND, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xDB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPANDN = {
		{{.VPANDN, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xDF, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPANDN, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xDF, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPOR = {
		{{.VPOR, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xEB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPOR, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xEB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPXOR = {
		{{.VPXOR, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xEF, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPXOR, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xEF, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSLLW = {
		{{.VPSLLW, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLW, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 6, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
		{{.VPSLLW, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLW, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 6, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
	},
	.VPSLLD = {
		{{.VPSLLD, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLD, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 6, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
		{{.VPSLLD, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLD, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 6, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
	},
	.VPSLLQ = {
		{{.VPSLLQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF3, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLQ, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x73, 6, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
		{{.VPSLLQ, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF3, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLQ, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x73, 6, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
	},
	.VPSRLW = {
		{{.VPSRLW, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLW, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 2, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
		{{.VPSRLW, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLW, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 2, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
	},
	.VPSRLD = {
		{{.VPSRLD, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLD, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 2, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
		{{.VPSRLD, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLD, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 2, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
	},
	.VPSRLQ = {
		{{.VPSRLQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD3, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLQ, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x73, 2, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
		{{.VPSRLQ, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD3, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLQ, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x73, 2, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
	},
	.VPSRAW = {
		{{.VPSRAW, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xE1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAW, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 4, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
		{{.VPSRAW, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xE1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAW, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 4, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
	},
	.VPSRAD = {
		{{.VPSRAD, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xE2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAD, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 4, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
		{{.VPSRAD, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xE2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},                     {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAD, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 4, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}}},
	},
	.VPCMPEQB = {
		{{.VPCMPEQB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x74, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPEQB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x74, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPEQW = {
		{{.VPCMPEQW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPEQW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPEQD = {
		{{.VPCMPEQD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPEQD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPEQQ = {
		{{.VPCMPEQQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPEQQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPGTB = {
		{{.VPCMPGTB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPGTB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPGTW = {
		{{.VPCMPGTW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPGTW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPGTD = {
		{{.VPCMPGTD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPGTD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPGTQ = {
		{{.VPCMPGTQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x37, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPGTQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x37, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPACKSSWB = {
		{{.VPACKSSWB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x63, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPACKSSWB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x63, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPACKSSDW = {
		{{.VPACKSSDW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPACKSSDW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPACKUSWB = {
		{{.VPACKUSWB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x67, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPACKUSWB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x67, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPACKUSDW = {
		{{.VPACKUSDW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPACKUSDW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPUNPCKLBW = {
		{{.VPUNPCKLBW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x60, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPUNPCKLBW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x60, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPUNPCKLWD = {
		{{.VPUNPCKLWD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x61, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPUNPCKLWD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x61, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPUNPCKLDQ = {
		{{.VPUNPCKLDQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x62, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPUNPCKLDQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x62, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPUNPCKLQDQ = {
		{{.VPUNPCKLQDQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPUNPCKLQDQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPUNPCKHBW = {
		{{.VPUNPCKHBW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x68, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPUNPCKHBW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x68, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPUNPCKHWD = {
		{{.VPUNPCKHWD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x69, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPUNPCKHWD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x69, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPUNPCKHDQ = {
		{{.VPUNPCKHDQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPUNPCKHDQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPUNPCKHQDQ = {
		{{.VPUNPCKHQDQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPUNPCKHQDQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSHUFD = {
		{{.VPSHUFD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSHUFD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSHUFHW = {
		{{.VPSHUFHW, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSHUFHW, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSHUFLW = {
		{{.VPSHUFLW, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSHUFLW, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPEXTRB = {
		{{.VPEXTRB, {.RM8, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x14, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true}},
	},
	.VPEXTRW = {
		{{.VPEXTRW, {.R32,  .XMM, .IMM8, .NONE}, {.REG, .MR,  .IB, .NONE}, 0xC5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},   {written={0}, read={1}}},
		{{.VPEXTRW, {.RM16, .XMM, .IMM8, .NONE}, {.MR,  .REG, .IB, .NONE}, 0x15, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true}},
	},
	.VPEXTRD = {
		{{.VPEXTRD, {.RM32, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x16, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true}},
	},
	.VPEXTRQ = {
		{{.VPEXTRQ, {.RM64, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x16, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true}},
	},
	.VPINSRB = {
		{{.VPINSRB, {.XMM, .XMM, .RM8, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x20, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPINSRW = {
		{{.VPINSRW, {.XMM, .XMM, .RM16, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPINSRD = {
		{{.VPINSRD, {.XMM, .XMM, .RM32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x22, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPINSRQ = {
		{{.VPINSRQ, {.XMM, .XMM, .RM64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x22, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPMOVMSKB = {
		{{.VPMOVMSKB, {.R32, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVMSKB, {.R32, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}}},
	},
	.VPTEST = {
		{{.VPTEST, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x17, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.VPTEST, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x17, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.VPSHUFB = {
		{{.VPSHUFB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x00, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSHUFB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x00, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPHADDW = {
		{{.VPHADDW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x01, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPHADDW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x01, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPHADDD = {
		{{.VPHADDD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x02, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPHADDD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x02, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPHADDSW = {
		{{.VPHADDSW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x03, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPHADDSW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x03, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPHSUBW = {
		{{.VPHSUBW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x05, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPHSUBW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x05, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPHSUBD = {
		{{.VPHSUBD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x06, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPHSUBD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x06, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPHSUBSW = {
		{{.VPHSUBSW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x07, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPHSUBSW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x07, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMADDUBSW = {
		{{.VPMADDUBSW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x04, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMADDUBSW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x04, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMULHRSW = {
		{{.VPMULHRSW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x0B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULHRSW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x0B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSIGNB = {
		{{.VPSIGNB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x08, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSIGNB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x08, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSIGNW = {
		{{.VPSIGNW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x09, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSIGNW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x09, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSIGND = {
		{{.VPSIGND, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x0A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSIGND, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x0A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPABSB = {
		{{.VPABSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPABSB, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPABSW = {
		{{.VPABSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPABSW, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPABSD = {
		{{.VPABSD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPABSD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPALIGNR = {
		{{.VPALIGNR, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPALIGNR, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPBLENDW = {
		{{.VPBLENDW, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPBLENDW, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPBLENDVB = {
		{{.VPBLENDVB, {.XMM, .XMM, .XMM_M128, .XMM}, {.REG, .VVVV, .MR, .IS4}, 0x4C, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPBLENDVB, {.YMM, .YMM, .YMM_M256, .YMM}, {.REG, .VVVV, .MR, .IS4}, 0x4C, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VMPSADBW = {
		{{.VMPSADBW, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VMPSADBW, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPHMINPOSUW = {
		{{.VPHMINPOSUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMAXSB = {
		{{.VPMAXSB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMAXSB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMAXSD = {
		{{.VPMAXSD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMAXSD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMAXUW = {
		{{.VPMAXUW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMAXUW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMAXUD = {
		{{.VPMAXUD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMAXUD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMINSB = {
		{{.VPMINSB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMINSB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMINSD = {
		{{.VPMINSD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMINSD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMINUW = {
		{{.VPMINUW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMINUW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMINUD = {
		{{.VPMINUD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMINUD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x3B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMOVSXBW = {
		{{.VPMOVSXBW, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSXBW, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSXBD = {
		{{.VPMOVSXBD, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSXBD, {.YMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSXBQ = {
		{{.VPMOVSXBQ, {.XMM, .XMM,     .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVSXBQ, {.YMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSXWD = {
		{{.VPMOVSXWD, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSXWD, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSXWQ = {
		{{.VPMOVSXWQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSXWQ, {.YMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSXDQ = {
		{{.VPMOVSXDQ, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSXDQ, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVZXBW = {
		{{.VPMOVZXBW, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVZXBW, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVZXBD = {
		{{.VPMOVZXBD, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVZXBD, {.YMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVZXBQ = {
		{{.VPMOVZXBQ, {.XMM, .XMM,     .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVZXBQ, {.YMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVZXWD = {
		{{.VPMOVZXWD, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVZXWD, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVZXWQ = {
		{{.VPMOVZXWQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVZXWQ, {.YMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVZXDQ = {
		{{.VPMOVZXDQ, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVZXDQ, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMULDQ = {
		{{.VPMULDQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULDQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMULLD = {
		{{.VPMULLD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x40, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULLD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x40, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VMASKMOVDQU = {
		{{.VMASKMOVDQU, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {read={0, 1}, implicit_rd={.RDI}, flags_rd={.DF}, writes_mem=true}},
	},
	.VPCLMULQDQ = {
		{{.VPCLMULQDQ, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x44, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPCLMULQDQ, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x44, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VAESDEC = {
		{{.VAESDEC, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xDE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VAESDECLAST = {
		{{.VAESDECLAST, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xDF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VAESENC = {
		{{.VAESENC, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xDC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VAESENCLAST = {
		{{.VAESENCLAST, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xDD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VAESIMC = {
		{{.VAESIMC, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VAESKEYGENASSIST = {
		{{.VAESKEYGENASSIST, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xDF, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VBROADCASTSS = {
		{{.VBROADCASTSS, {.XMM, .M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x18, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VBROADCASTSS, {.YMM, .M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x18, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VBROADCASTSS, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x18, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VBROADCASTSS, {.YMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x18, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}}},
	},
	.VBROADCASTSD = {
		{{.VBROADCASTSD, {.YMM, .M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x19, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VBROADCASTSD, {.YMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x19, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}}},
	},
	.VBROADCASTF128 = {
		{{.VBROADCASTF128, {.YMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VEXTRACTF128 = {
		{{.VEXTRACTF128, {.XMM_M128, .YMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x19, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
	},
	.VINSERTF128 = {
		{{.VINSERTF128, {.YMM, .YMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x18, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPERM2F128 = {
		{{.VPERM2F128, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x06, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VMASKMOVPS = {
		{{.VMASKMOVPS, {.XMM,  .XMM, .M128, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMASKMOVPS, {.YMM,  .YMM, .M256, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMASKMOVPS, {.M128, .XMM, .XMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x2E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMASKMOVPS, {.M256, .YMM, .YMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x2E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
	},
	.VMASKMOVPD = {
		{{.VMASKMOVPD, {.XMM,  .XMM, .M128, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x2D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMASKMOVPD, {.YMM,  .YMM, .M256, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x2D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMASKMOVPD, {.M128, .XMM, .XMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x2F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VMASKMOVPD, {.M256, .YMM, .YMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x2F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
	},
	.VTESTPS = {
		{{.VTESTPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.VTESTPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.VTESTPD = {
		{{.VTESTPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
		{{.VTESTPD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {read={0, 1}, flags_wr={.CF, .ZF}, flags_undef={.PF, .AF, .SF, .OF}, reads_mem=true}},
	},
	.VZEROALL = {
		{{.VZEROALL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x77, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}}, {implicit_wr={.VECTOR}}},
	},
	.VZEROUPPER = {
		{{.VZEROUPPER, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x77, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}}, {implicit_wr={.VECTOR}}},
	},
	.VBROADCASTI128 = {
		{{.VBROADCASTI128, {.YMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VEXTRACTI128 = {
		{{.VEXTRACTI128, {.XMM_M128, .YMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x39, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
	},
	.VINSERTI128 = {
		{{.VINSERTI128, {.YMM, .YMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x38, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPERM2I128 = {
		{{.VPERM2I128, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x46, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPERMD = {
		{{.VPERMD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x36, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMPS = {
		{{.VPERMPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x16, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMQ = {
		{{.VPERMQ, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x00, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMPD = {
		{{.VPERMPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x01, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPBLENDD = {
		{{.VPBLENDD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x02, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPBLENDD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x02, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPSLLVD = {
		{{.VPSLLVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSLLVQ = {
		{{.VPSLLVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSRLVD = {
		{{.VPSRLVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSRLVQ = {
		{{.VPSRLVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSRAVD = {
		{{.VPSRAVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMASKMOVD = {
		{{.VPMASKMOVD, {.XMM,  .XMM, .M128, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x8C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VPMASKMOVD, {.YMM,  .YMM, .M256, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x8C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VPMASKMOVD, {.M128, .XMM, .XMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x8E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VPMASKMOVD, {.M256, .YMM, .YMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x8E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
	},
	.VPMASKMOVQ = {
		{{.VPMASKMOVQ, {.XMM,  .XMM, .M128, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x8C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VPMASKMOVQ, {.YMM,  .YMM, .M256, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x8C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VPMASKMOVQ, {.M128, .XMM, .XMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x8E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
		{{.VPMASKMOVQ, {.M256, .YMM, .YMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x8E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, writes_mem=true, reads_mem=true}},
	},
	.VGATHERDPS = {
		{{.VGATHERDPS, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x92, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
		{{.VGATHERDPS, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x92, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
	},
	.VGATHERDPD = {
		{{.VGATHERDPD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x92, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
		{{.VGATHERDPD, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x92, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
	},
	.VGATHERQPS = {
		{{.VGATHERQPS, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x93, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
		{{.VGATHERQPS, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x93, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
	},
	.VGATHERQPD = {
		{{.VGATHERQPD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x93, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
		{{.VGATHERQPD, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x93, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
	},
	.VPGATHERDD = {
		{{.VPGATHERDD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x90, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
		{{.VPGATHERDD, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x90, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
	},
	.VPGATHERDQ = {
		{{.VPGATHERDQ, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x90, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
		{{.VPGATHERDQ, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x90, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
	},
	.VPGATHERQD = {
		{{.VPGATHERQD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x91, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
		{{.VPGATHERQD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x91, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
	},
	.VPGATHERQQ = {
		{{.VPGATHERQQ, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x91, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
		{{.VPGATHERQQ, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x91, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0, 2}, read={0, 1, 2}, reads_mem=true}},
	},
	.VFMADD132PS = {
		{{.VFMADD132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x98, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADD132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x98, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD213PS = {
		{{.VFMADD213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADD213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD231PS = {
		{{.VFMADD231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADD231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD132PD = {
		{{.VFMADD132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x98, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADD132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x98, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD213PD = {
		{{.VFMADD213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADD213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD231PD = {
		{{.VFMADD231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADD231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD132SS = {
		{{.VFMADD132SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x99, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD213SS = {
		{{.VFMADD213SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA9, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD231SS = {
		{{.VFMADD231SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB9, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD132SD = {
		{{.VFMADD132SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x99, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD213SD = {
		{{.VFMADD213SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA9, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADD231SD = {
		{{.VFMADD231SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB9, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB132PS = {
		{{.VFMSUB132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUB132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB213PS = {
		{{.VFMSUB213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUB213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB231PS = {
		{{.VFMSUB231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUB231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB132PD = {
		{{.VFMSUB132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUB132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB213PD = {
		{{.VFMSUB213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUB213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB231PD = {
		{{.VFMSUB231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUB231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB132SS = {
		{{.VFMSUB132SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB213SS = {
		{{.VFMSUB213SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB231SS = {
		{{.VFMSUB231SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB132SD = {
		{{.VFMSUB132SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB213SD = {
		{{.VFMSUB213SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUB231SD = {
		{{.VFMSUB231SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD132PS = {
		{{.VFNMADD132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMADD132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD213PS = {
		{{.VFNMADD213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMADD213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD231PS = {
		{{.VFNMADD231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMADD231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD132PD = {
		{{.VFNMADD132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMADD132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD213PD = {
		{{.VFNMADD213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMADD213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD231PD = {
		{{.VFNMADD231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMADD231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD132SS = {
		{{.VFNMADD132SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD213SS = {
		{{.VFNMADD213SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD231SS = {
		{{.VFNMADD231SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD132SD = {
		{{.VFNMADD132SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD213SD = {
		{{.VFNMADD213SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMADD231SD = {
		{{.VFNMADD231SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB132PS = {
		{{.VFNMSUB132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMSUB132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB213PS = {
		{{.VFNMSUB213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMSUB213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB231PS = {
		{{.VFNMSUB231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMSUB231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB132PD = {
		{{.VFNMSUB132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMSUB132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB213PD = {
		{{.VFNMSUB213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMSUB213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB231PD = {
		{{.VFNMSUB231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFNMSUB231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB132SS = {
		{{.VFNMSUB132SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB213SS = {
		{{.VFNMSUB213SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB231SS = {
		{{.VFNMSUB231SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB132SD = {
		{{.VFNMSUB132SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB213SD = {
		{{.VFNMSUB213SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFNMSUB231SD = {
		{{.VFNMSUB231SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADDSUB132PS = {
		{{.VFMADDSUB132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x96, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADDSUB132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x96, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADDSUB213PS = {
		{{.VFMADDSUB213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADDSUB213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADDSUB231PS = {
		{{.VFMADDSUB231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADDSUB231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADDSUB132PD = {
		{{.VFMADDSUB132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x96, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADDSUB132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x96, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADDSUB213PD = {
		{{.VFMADDSUB213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADDSUB213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMADDSUB231PD = {
		{{.VFMADDSUB231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMADDSUB231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUBADD132PS = {
		{{.VFMSUBADD132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x97, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUBADD132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x97, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUBADD213PS = {
		{{.VFMSUBADD213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUBADD213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUBADD231PS = {
		{{.VFMSUBADD231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUBADD231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUBADD132PD = {
		{{.VFMSUBADD132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x97, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUBADD132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x97, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUBADD213PD = {
		{{.VFMSUBADD213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUBADD213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFMSUBADD231PD = {
		{{.VFMSUBADD231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFMSUBADD231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTPH2PS = {
		{{.VCVTPH2PS, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},  {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTPH2PS, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},  {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VCVTPH2PS, {.ZMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VCVTPS2PH = {
		{{.VCVTPS2PH, {.XMM_M64,  .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x1D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},  {written={0}, read={1, 2}, implicit_wr={.MXCSR}, writes_mem=true, reads_mem=true}},
		{{.VCVTPS2PH, {.XMM_M128, .YMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x1D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},  {written={0}, read={1, 2}, implicit_wr={.MXCSR}, writes_mem=true, reads_mem=true}},
		{{.VCVTPS2PH, {.YMM_M256, .ZMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x1D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, writes_mem=true, reads_mem=true}},
	},
	.VMOVDQA32 = {
		{{.VMOVDQA32, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA32, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA32, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA32, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA32, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA32, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VMOVDQA64 = {
		{{.VMOVDQA64, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA64, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA64, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA64, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA64, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQA64, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VMOVDQU8 = {
		{{.VMOVDQU8, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU8, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU8, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU8, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU8, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU8, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VMOVDQU16 = {
		{{.VMOVDQU16, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU16, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU16, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU16, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU16, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU16, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VMOVDQU32 = {
		{{.VMOVDQU32, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU32, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU32, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU32, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU32, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU32, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VMOVDQU64 = {
		{{.VMOVDQU64, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU64, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU64, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU64, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU64, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
		{{.VMOVDQU64, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPBLENDMB = {
		{{.VPBLENDMB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPBLENDMB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPBLENDMB, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPBLENDMW = {
		{{.VPBLENDMW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPBLENDMW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPBLENDMW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPBLENDMD = {
		{{.VPBLENDMD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPBLENDMD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPBLENDMD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPBLENDMQ = {
		{{.VPBLENDMQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPBLENDMQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPBLENDMQ, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VBLENDMPS = {
		{{.VBLENDMPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VBLENDMPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VBLENDMPS, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VBLENDMPD = {
		{{.VBLENDMPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VBLENDMPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VBLENDMPD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPB = {
		{{.VPCMPB, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPB, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPB, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPUB = {
		{{.VPCMPUB, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPUB, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPUB, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPW = {
		{{.VPCMPW, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPW, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPW, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPUW = {
		{{.VPCMPUW, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPUW, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPUW, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPD = {
		{{.VPCMPD, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPD, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPD, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPUD = {
		{{.VPCMPUD, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPUD, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPUD, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPQ = {
		{{.VPCMPQ, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPQ, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPQ, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCMPUQ = {
		{{.VPCMPUQ, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPUQ, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPCMPUQ, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPTESTMB = {
		{{.VPTESTMB, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTMB, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTMB, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPTESTMW = {
		{{.VPTESTMW, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTMW, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTMW, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPTESTMD = {
		{{.VPTESTMD, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTMD, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTMD, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPTESTMQ = {
		{{.VPTESTMQ, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTMQ, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTMQ, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPTESTNMB = {
		{{.VPTESTNMB, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTNMB, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTNMB, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPTESTNMW = {
		{{.VPTESTNMW, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTNMW, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTNMW, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPTESTNMD = {
		{{.VPTESTNMD, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTNMD, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTNMD, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPTESTNMQ = {
		{{.VPTESTNMQ, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTNMQ, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPTESTNMQ, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPCOMPRESSD = {
		{{.VPCOMPRESSD, {.XMM_M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPCOMPRESSD, {.YMM_M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPCOMPRESSD, {.ZMM_M512, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPCOMPRESSQ = {
		{{.VPCOMPRESSQ, {.XMM_M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPCOMPRESSQ, {.YMM_M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPCOMPRESSQ, {.ZMM_M512, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VCOMPRESSPS = {
		{{.VCOMPRESSPS, {.XMM_M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VCOMPRESSPS, {.YMM_M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VCOMPRESSPS, {.ZMM_M512, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VCOMPRESSPD = {
		{{.VCOMPRESSPD, {.XMM_M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VCOMPRESSPD, {.YMM_M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VCOMPRESSPD, {.ZMM_M512, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPEXPANDD = {
		{{.VPEXPANDD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPEXPANDD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPEXPANDD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPEXPANDQ = {
		{{.VPEXPANDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPEXPANDQ, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPEXPANDQ, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VEXPANDPS = {
		{{.VEXPANDPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VEXPANDPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VEXPANDPS, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VEXPANDPD = {
		{{.VEXPANDPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VEXPANDPD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VEXPANDPD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPCONFLICTD = {
		{{.VPCONFLICTD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPCONFLICTD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPCONFLICTD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPCONFLICTQ = {
		{{.VPCONFLICTQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPCONFLICTQ, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPCONFLICTQ, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPLZCNTD = {
		{{.VPLZCNTD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPLZCNTD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPLZCNTD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPLZCNTQ = {
		{{.VPLZCNTQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPLZCNTQ, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPLZCNTQ, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPERMI2B = {
		{{.VPERMI2B, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2B, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2B, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMI2W = {
		{{.VPERMI2W, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2W, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2W, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMI2D = {
		{{.VPERMI2D, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2D, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2D, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMI2Q = {
		{{.VPERMI2Q, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2Q, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2Q, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMI2PS = {
		{{.VPERMI2PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2PS, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMI2PD = {
		{{.VPERMI2PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMI2PD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMT2B = {
		{{.VPERMT2B, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2B, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2B, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMT2W = {
		{{.VPERMT2W, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2W, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2W, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMT2D = {
		{{.VPERMT2D, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2D, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2D, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMT2Q = {
		{{.VPERMT2Q, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2Q, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2Q, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMT2PS = {
		{{.VPERMT2PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2PS, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMT2PD = {
		{{.VPERMT2PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMT2PD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMB = {
		{{.VPERMB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMB, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPERMW = {
		{{.VPERMW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPERMW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMOVB2M = {
		{{.VPMOVB2M, {.K, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVB2M, {.K, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPMOVB2M, {.K, .ZMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}}},
	},
	.VPMOVW2M = {
		{{.VPMOVW2M, {.K, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVW2M, {.K, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPMOVW2M, {.K, .ZMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}}},
	},
	.VPMOVD2M = {
		{{.VPMOVD2M, {.K, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVD2M, {.K, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPMOVD2M, {.K, .ZMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}}},
	},
	.VPMOVQ2M = {
		{{.VPMOVQ2M, {.K, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVQ2M, {.K, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPMOVQ2M, {.K, .ZMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}}},
	},
	.VPMOVM2B = {
		{{.VPMOVM2B, {.XMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVM2B, {.YMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPMOVM2B, {.ZMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}}},
	},
	.VPMOVM2W = {
		{{.VPMOVM2W, {.XMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVM2W, {.YMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPMOVM2W, {.ZMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}}},
	},
	.VPMOVM2D = {
		{{.VPMOVM2D, {.XMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVM2D, {.YMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPMOVM2D, {.ZMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}}},
	},
	.VPMOVM2Q = {
		{{.VPMOVM2Q, {.XMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
		{{.VPMOVM2Q, {.YMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}}},
		{{.VPMOVM2Q, {.ZMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}}},
	},
	.VPMOVQB = {
		{{.VPMOVQB, {.XMM_M32, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVQB, {.XMM_M32, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVQB, {.XMM_M64, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSQB = {
		{{.VPMOVSQB, {.XMM_M32, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSQB, {.XMM_M32, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSQB, {.XMM_M64, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVUSQB = {
		{{.VPMOVUSQB, {.XMM_M32, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSQB, {.XMM_M32, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSQB, {.XMM_M64, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVQW = {
		{{.VPMOVQW, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVQW, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVQW, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSQW = {
		{{.VPMOVSQW, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSQW, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSQW, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVUSQW = {
		{{.VPMOVUSQW, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSQW, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSQW, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVQD = {
		{{.VPMOVQD, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVQD, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVQD, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSQD = {
		{{.VPMOVSQD, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSQD, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSQD, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVUSQD = {
		{{.VPMOVUSQD, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSQD, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSQD, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVDB = {
		{{.VPMOVDB, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVDB, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVDB, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSDB = {
		{{.VPMOVSDB, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSDB, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSDB, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVUSDB = {
		{{.VPMOVUSDB, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSDB, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSDB, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVDW = {
		{{.VPMOVDW, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVDW, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVDW, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSDW = {
		{{.VPMOVSDW, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSDW, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSDW, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVUSDW = {
		{{.VPMOVUSDW, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSDW, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSDW, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVWB = {
		{{.VPMOVWB, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVWB, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVWB, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVSWB = {
		{{.VPMOVSWB, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSWB, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVSWB, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPMOVUSWB = {
		{{.VPMOVUSWB, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSWB, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VPMOVUSWB, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VPROLD = {
		{{.VPROLD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPROLD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPROLD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2, modrm_reg_ext=true}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPROLQ = {
		{{.VPROLQ, {.XMM, .XMM_M128, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0, modrm_reg_ext=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPROLQ, {.YMM, .YMM_M256, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1, modrm_reg_ext=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPROLQ, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2, modrm_reg_ext=true}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPROLVD = {
		{{.VPROLVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPROLVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPROLVD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPROLVQ = {
		{{.VPROLVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPROLVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPROLVQ, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPRORD = {
		{{.VPRORD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPRORD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPRORD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPRORQ = {
		{{.VPRORQ, {.XMM, .XMM_M128, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPRORQ, {.YMM, .YMM_M256, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPRORQ, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPRORVD = {
		{{.VPRORVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPRORVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPRORVD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPRORVQ = {
		{{.VPRORVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPRORVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPRORVQ, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSCATTERDD = {
		{{.VPSCATTERDD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {read={0, 1}, writes_mem=true}},
		{{.VPSCATTERDD, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {read={0, 1}, writes_mem=true}},
		{{.VPSCATTERDD, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {read={0, 1}, writes_mem=true}},
	},
	.VPSCATTERDQ = {
		{{.VPSCATTERDQ, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {read={0, 1}, writes_mem=true}},
		{{.VPSCATTERDQ, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {read={0, 1}, writes_mem=true}},
		{{.VPSCATTERDQ, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {read={0, 1}, writes_mem=true}},
	},
	.VPSCATTERQD = {
		{{.VPSCATTERQD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {read={0, 1}, writes_mem=true}},
		{{.VPSCATTERQD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {read={0, 1}, writes_mem=true}},
		{{.VPSCATTERQD, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {read={0, 1}, writes_mem=true}},
	},
	.VPSCATTERQQ = {
		{{.VPSCATTERQQ, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {read={0, 1}, writes_mem=true}},
		{{.VPSCATTERQQ, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {read={0, 1}, writes_mem=true}},
		{{.VPSCATTERQQ, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {read={0, 1}, writes_mem=true}},
	},
	.VSCATTERDPS = {
		{{.VSCATTERDPS, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {read={0, 1}, writes_mem=true}},
		{{.VSCATTERDPS, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {read={0, 1}, writes_mem=true}},
		{{.VSCATTERDPS, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {read={0, 1}, writes_mem=true}},
	},
	.VSCATTERDPD = {
		{{.VSCATTERDPD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {read={0, 1}, writes_mem=true}},
		{{.VSCATTERDPD, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {read={0, 1}, writes_mem=true}},
		{{.VSCATTERDPD, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {read={0, 1}, writes_mem=true}},
	},
	.VSCATTERQPS = {
		{{.VSCATTERQPS, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {read={0, 1}, writes_mem=true}},
		{{.VSCATTERQPS, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {read={0, 1}, writes_mem=true}},
		{{.VSCATTERQPS, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {read={0, 1}, writes_mem=true}},
	},
	.VSCATTERQPD = {
		{{.VSCATTERQPD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {read={0, 1}, writes_mem=true}},
		{{.VSCATTERQPD, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {read={0, 1}, writes_mem=true}},
		{{.VSCATTERQPD, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {read={0, 1}, writes_mem=true}},
	},
	.VPSRAVQ = {
		{{.VPSRAVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAVQ, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSRAVW = {
		{{.VPSRAVW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAVW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRAVW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSLLVW = {
		{{.VPSLLVW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLVW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSLLVW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPSRLVW = {
		{{.VPSRLVW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLVW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPSRLVW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VRANGEPS = {
		{{.VRANGEPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRANGEPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRANGEPS, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRANGEPD = {
		{{.VRANGEPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRANGEPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRANGEPD, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRANGESS = {
		{{.VRANGESS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x51, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRANGESD = {
		{{.VRANGESD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x51, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VREDUCEPS = {
		{{.VREDUCEPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VREDUCEPS, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VREDUCEPS, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VREDUCEPD = {
		{{.VREDUCEPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VREDUCEPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VREDUCEPD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VREDUCESS = {
		{{.VREDUCESS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x57, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VREDUCESD = {
		{{.VREDUCESD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x57, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRNDSCALEPS = {
		{{.VRNDSCALEPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRNDSCALEPS, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRNDSCALEPS, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRNDSCALEPD = {
		{{.VRNDSCALEPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRNDSCALEPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRNDSCALEPD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRNDSCALESS = {
		{{.VRNDSCALESS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0A, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRNDSCALESD = {
		{{.VRNDSCALESD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0B, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRSQRT14PS = {
		{{.VRSQRT14PS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRSQRT14PS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRSQRT14PS, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRSQRT14PD = {
		{{.VRSQRT14PD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRSQRT14PD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRSQRT14PD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRSQRT14SS = {
		{{.VRSQRT14SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRSQRT14SD = {
		{{.VRSQRT14SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRCP14PS = {
		{{.VRCP14PS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRCP14PS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRCP14PS, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRCP14PD = {
		{{.VRCP14PD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRCP14PD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VRCP14PD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRCP14SS = {
		{{.VRCP14SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VRCP14SD = {
		{{.VRCP14SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSCALEFPS = {
		{{.VSCALEFPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VSCALEFPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VSCALEFPS, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSCALEFPD = {
		{{.VSCALEFPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VSCALEFPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VSCALEFPD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSCALEFSS = {
		{{.VSCALEFSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VSCALEFSD = {
		{{.VSCALEFSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VGETEXPPS = {
		{{.VGETEXPPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VGETEXPPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VGETEXPPS, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VGETEXPPD = {
		{{.VGETEXPPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VGETEXPPD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VGETEXPPD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VGETEXPSS = {
		{{.VGETEXPSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x43, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VGETEXPSD = {
		{{.VGETEXPSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x43, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VGETMANTPS = {
		{{.VGETMANTPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VGETMANTPS, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VGETMANTPS, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VGETMANTPD = {
		{{.VGETMANTPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VGETMANTPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VGETMANTPD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VGETMANTSS = {
		{{.VGETMANTSS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x27, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VGETMANTSD = {
		{{.VGETMANTSD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x27, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFIXUPIMMPS = {
		{{.VFIXUPIMMPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFIXUPIMMPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFIXUPIMMPS, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFIXUPIMMPD = {
		{{.VFIXUPIMMPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFIXUPIMMPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
		{{.VFIXUPIMMPD, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFIXUPIMMSS = {
		{{.VFIXUPIMMSS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x55, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFIXUPIMMSD = {
		{{.VFIXUPIMMSD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x55, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1, 2, 3}, implicit_wr={.MXCSR}, reads_mem=true}},
	},
	.VFPCLASSPS = {
		{{.VFPCLASSPS, {.K, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VFPCLASSPS, {.K, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VFPCLASSPS, {.K, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VFPCLASSPD = {
		{{.VFPCLASSPD, {.K, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, reads_mem=true}},
		{{.VFPCLASSPD, {.K, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1}, reads_mem=true}},
		{{.VFPCLASSPD, {.K, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VFPCLASSSS = {
		{{.VFPCLASSSS, {.K, .XMM_M32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x67, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VFPCLASSSD = {
		{{.VFPCLASSSD, {.K, .XMM_M64, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x67, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1}}, {written={0}, read={1}, reads_mem=true}},
	},
	.VALIGNQ = {
		{{.VALIGNQ, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VALIGNQ, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VALIGNQ, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VALIGND = {
		{{.VALIGND, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VALIGND, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VALIGND, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VDBPSADBW = {
		{{.VDBPSADBW, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VDBPSADBW, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VDBPSADBW, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPTERNLOGD = {
		{{.VPTERNLOGD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPTERNLOGD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPTERNLOGD, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPTERNLOGQ = {
		{{.VPTERNLOGQ, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPTERNLOGQ, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
		{{.VPTERNLOGQ, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2, 3}, reads_mem=true}},
	},
	.VPDPWSSD = {
		{{.VPDPWSSD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x52, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPDPWSSD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x52, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPDPWSSD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x52, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W0, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.VPMULTISHIFTQB = {
		{{.VPMULTISHIFTQB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x83, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULTISHIFTQB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x83, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.VPMULTISHIFTQB, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x83, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_w=.W1, vex_l=.L2}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.KADDW = {
		{{.KADDW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4A, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KADDB = {
		{{.KADDB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KADDQ = {
		{{.KADDQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4A, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KADDD = {
		{{.KADDD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KANDW = {
		{{.KANDW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x41, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KANDB = {
		{{.KANDB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x41, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KANDQ = {
		{{.KANDQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x41, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KANDD = {
		{{.KANDD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x41, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KANDNW = {
		{{.KANDNW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x42, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KANDNB = {
		{{.KANDNB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x42, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KANDNQ = {
		{{.KANDNQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x42, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KANDND = {
		{{.KANDND, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x42, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KMOVW = {
		{{.KMOVW, {.K,   .K_M16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x90, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.KMOVW, {.M16, .K,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x91, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.KMOVW, {.K,   .R32,   .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x92, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.KMOVW, {.R32, .K,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x93, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.KMOVB = {
		{{.KMOVB, {.K,   .K_M8, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x90, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.KMOVB, {.M8,  .K,    .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x91, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.KMOVB, {.K,   .R32,  .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x92, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.KMOVB, {.R32, .K,    .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x93, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.KMOVQ = {
		{{.KMOVQ, {.K,   .K_M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x90, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.KMOVQ, {.M64, .K,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x91, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.KMOVQ, {.K,   .R64,   .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x92, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
		{{.KMOVQ, {.R64, .K,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x93, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.KMOVD = {
		{{.KMOVD, {.K,   .K_M32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x90, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.KMOVD, {.M32, .K,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x91, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.KMOVD, {.K,   .R32,   .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x92, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
		{{.KMOVD, {.R32, .K,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x93, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.KNOTW = {
		{{.KNOTW, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.KNOTB = {
		{{.KNOTB, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.KNOTQ = {
		{{.KNOTQ, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.KNOTD = {
		{{.KNOTD, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1}}},
	},
	.KORW = {
		{{.KORW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KORB = {
		{{.KORB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KORQ = {
		{{.KORQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KORD = {
		{{.KORD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KORTESTW = {
		{{.KORTESTW, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x98, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.KORTESTB = {
		{{.KORTESTB, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x98, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.KORTESTQ = {
		{{.KORTESTQ, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x98, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.KORTESTD = {
		{{.KORTESTD, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x98, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.KSHIFTLW = {
		{{.KSHIFTLW, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x32, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.KSHIFTLB = {
		{{.KSHIFTLB, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x32, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.KSHIFTLQ = {
		{{.KSHIFTLQ, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x33, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.KSHIFTLD = {
		{{.KSHIFTLD, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x33, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.KSHIFTRW = {
		{{.KSHIFTRW, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x30, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.KSHIFTRB = {
		{{.KSHIFTRB, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x30, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.KSHIFTRQ = {
		{{.KSHIFTRQ, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x31, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.KSHIFTRD = {
		{{.KSHIFTRD, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x31, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {written={0}, read={1, 2}}},
	},
	.KTESTW = {
		{{.KTESTW, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x99, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.KTESTB = {
		{{.KTESTB, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x99, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.KTESTQ = {
		{{.KTESTQ, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x99, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.KTESTD = {
		{{.KTESTD, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x99, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.KUNPCKBW = {
		{{.KUNPCKBW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KUNPCKWD = {
		{{.KUNPCKWD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4B, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KUNPCKDQ = {
		{{.KUNPCKDQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4B, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KXNORW = {
		{{.KXNORW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KXNORB = {
		{{.KXNORB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KXNORQ = {
		{{.KXNORQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KXNORD = {
		{{.KXNORD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KXORW = {
		{{.KXORW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KXORB = {
		{{.KXORB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KXORQ = {
		{{.KXORQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.KXORD = {
		{{.KXORD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L1}}, {written={0}, read={1, 2}}},
	},
	.FADD = {
		{{.FADD, {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 0   , {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FADD, {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 0   , {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FADD, {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xC0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FADD, {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xC0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FADDP = {
		{{.FADDP, {.STI,  .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xC0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FADDP, {.NONE, .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xC1, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FIADD = {
		{{.FIADD, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FIADD, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
	},
	.FSUB = {
		{{.FSUB, {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 4   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FSUB, {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 4   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FSUB, {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xE0, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FSUB, {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xE8, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FSUBP = {
		{{.FSUBP, {.STI,  .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xE8, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FSUBP, {.NONE, .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xE9, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FISUB = {
		{{.FISUB, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 4, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FISUB, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 4, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
	},
	.FSUBR = {
		{{.FSUBR, {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 5   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FSUBR, {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 5   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FSUBR, {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xE8, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FSUBR, {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xE0, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FSUBRP = {
		{{.FSUBRP, {.STI,  .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xE0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FSUBRP, {.NONE, .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xE1, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FISUBR = {
		{{.FISUBR, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 5, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FISUBR, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 5, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
	},
	.FMUL = {
		{{.FMUL, {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 1   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FMUL, {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 1   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FMUL, {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xC8, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FMUL, {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xC8, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FMULP = {
		{{.FMULP, {.STI,  .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xC8, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FMULP, {.NONE, .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xC9, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FIMUL = {
		{{.FIMUL, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 1, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FIMUL, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 1, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
	},
	.FDIV = {
		{{.FDIV, {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 6   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FDIV, {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 6   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FDIV, {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xF0, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FDIV, {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xF8, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FDIVP = {
		{{.FDIVP, {.STI,  .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xF8, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FDIVP, {.NONE, .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xF9, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FIDIV = {
		{{.FIDIV, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 6, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FIDIV, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 6, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
	},
	.FDIVR = {
		{{.FDIVR, {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 7   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FDIVR, {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 7   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FDIVR, {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xF8, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FDIVR, {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xF0, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FDIVRP = {
		{{.FDIVRP, {.STI,  .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xF0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FDIVRP, {.NONE, .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xF1, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FIDIVR = {
		{{.FIDIVR, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 7, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FIDIVR, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 7, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
	},
	.FSQRT = {
		{{.FSQRT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFA, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FABS = {
		{{.FABS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE1, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FCHS = {
		{{.FCHS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FPREM = {
		{{.FPREM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF8, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FPREM1 = {
		{{.FPREM1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF5, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FRNDINT = {
		{{.FRNDINT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFC, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FSCALE = {
		{{.FSCALE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFD, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FXTRACT = {
		{{.FXTRACT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF4, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FXAM = {
		{{.FXAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE5, {}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FLD = {
		{{.FLD, {.M32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD9, 0   , {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
		{{.FLD, {.M64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 0   , {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
		{{.FLD, {.M80, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDB, 5   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
		{{.FLD, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xD9, 0xC0, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FILD = {
		{{.FILD, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 0, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
		{{.FILD, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDB, 0, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
		{{.FILD, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 5, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
	},
	.FBLD = {
		{{.FBLD, {.M80, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 4, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
	},
	.FST = {
		{{.FST, {.M32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD9, 2   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FST, {.M64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 2   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FST, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xD0, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FSTP = {
		{{.FSTP, {.M32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD9, 3   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FSTP, {.M64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 3   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FSTP, {.M80, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDB, 7   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FSTP, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xD8, {}},                   {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FIST = {
		{{.FIST, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 2, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FIST, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDB, 2, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FISTP = {
		{{.FISTP, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 3, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FISTP, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDB, 3, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FISTP, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 7, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FISTTP = {
		{{.FISTTP, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 1, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FISTTP, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDB, 1, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
		{{.FISTTP, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDD, 1, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FBSTP = {
		{{.FBSTP, {.M80, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 6, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FXCH = {
		{{.FXCH, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xD9, 0xC8, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FXCH, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xC9, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FCMOVB = {
		{{.FCMOVB, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDA, 0xC0, {}}, {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF}}},
	},
	.FCMOVE = {
		{{.FCMOVE, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDA, 0xC8, {}}, {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.ZF}}},
	},
	.FCMOVBE = {
		{{.FCMOVBE, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDA, 0xD0, {}}, {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF, .ZF}}},
	},
	.FCMOVU = {
		{{.FCMOVU, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDA, 0xD8, {}}, {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.PF}}},
	},
	.FCMOVNB = {
		{{.FCMOVNB, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xC0, {}}, {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF}}},
	},
	.FCMOVNE = {
		{{.FCMOVNE, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xC8, {}}, {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.ZF}}},
	},
	.FCMOVNBE = {
		{{.FCMOVNBE, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xD0, {}}, {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF, .ZF}}},
	},
	.FCMOVNU = {
		{{.FCMOVNU, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xD8, {}}, {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.PF}}},
	},
	.FCOM = {
		{{.FCOM, {.M32,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 2   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FCOM, {.M64,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 2   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FCOM, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xD8, 0xD0, {}},                   {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FCOM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD8, 0xD1, {}},                   {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FCOMP = {
		{{.FCOMP, {.M32,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 3   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FCOMP, {.M64,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 3   , {modrm_reg_ext=true}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FCOMP, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xD8, 0xD8, {}},                   {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FCOMP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD8, 0xD9, {}},                   {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FCOMPP = {
		{{.FCOMPP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xD9, {}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FICOM = {
		{{.FICOM, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 2, {modrm_reg_ext=true}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FICOM, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 2, {modrm_reg_ext=true}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
	},
	.FICOMP = {
		{{.FICOMP, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 3, {modrm_reg_ext=true}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
		{{.FICOMP, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 3, {modrm_reg_ext=true}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true}},
	},
	.FCOMI = {
		{{.FCOMI, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xF0, {}}, {implicit_rd={.FPU_ST}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}}},
	},
	.FCOMIP = {
		{{.FCOMIP, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDF, 0xF0, {}}, {implicit_rd={.FPU_ST}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}}},
	},
	.FUCOMI = {
		{{.FUCOMI, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xE8, {}}, {implicit_rd={.FPU_ST}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}}},
	},
	.FUCOMIP = {
		{{.FUCOMIP, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDF, 0xE8, {}}, {implicit_rd={.FPU_ST}, flags_wr={.CF, .PF, .ZF}, flags_undef={.AF, .SF, .OF}}},
	},
	.FUCOM = {
		{{.FUCOM, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xE0, {}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FUCOM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDD, 0xE1, {}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FUCOMP = {
		{{.FUCOMP, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xE8, {}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
		{{.FUCOMP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDD, 0xE9, {}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FUCOMPP = {
		{{.FUCOMPP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDA, 0xE9, {}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FTST = {
		{{.FTST, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE4, {}}, {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FLDZ = {
		{{.FLDZ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xEE, {}}, {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FLD1 = {
		{{.FLD1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE8, {}}, {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FLDPI = {
		{{.FLDPI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xEB, {}}, {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FLDL2T = {
		{{.FLDL2T, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE9, {}}, {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FLDL2E = {
		{{.FLDL2E, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xEA, {}}, {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FLDLG2 = {
		{{.FLDLG2, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xEC, {}}, {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FLDLN2 = {
		{{.FLDLN2, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xED, {}}, {implicit_wr={.FPU_ST, .FPU_SW}}},
	},
	.FSIN = {
		{{.FSIN, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFE, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FCOS = {
		{{.FCOS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFF, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FSINCOS = {
		{{.FSINCOS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFB, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FPTAN = {
		{{.FPTAN, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF2, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FPATAN = {
		{{.FPATAN, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF3, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.F2XM1 = {
		{{.F2XM1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FYL2X = {
		{{.FYL2X, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF1, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FYL2XP1 = {
		{{.FYL2XP1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF9, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FINIT = {
		{{.FINIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 0xE3, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FNINIT = {
		{{.FNINIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 0xE3, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FINCSTP = {
		{{.FINCSTP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF7, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FDECSTP = {
		{{.FDECSTP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF6, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FFREE = {
		{{.FFREE, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xC0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FFREEP = {
		{{.FFREEP, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDF, 0xC0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FNOP = {
		{{.FNOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xD0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FWAIT = {
		{{.FWAIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9B, 0, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FCLEX = {
		{{.FCLEX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 0xE2, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FNCLEX = {
		{{.FNCLEX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 0xE2, {}}, {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}}},
	},
	.FSTCW = {
		{{.FSTCW, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 7, {modrm_reg_ext=true}}, {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FNSTCW = {
		{{.FNSTCW, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 7, {modrm_reg_ext=true}}, {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FLDCW = {
		{{.FLDCW, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 5, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
	},
	.FSTENV = {
		{{.FSTENV, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 6, {modrm_reg_ext=true}}, {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FNSTENV = {
		{{.FNSTENV, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 6, {modrm_reg_ext=true}}, {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FLDENV = {
		{{.FLDENV, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 4, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
	},
	.FSAVE = {
		{{.FSAVE, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDD, 6, {modrm_reg_ext=true}}, {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FNSAVE = {
		{{.FNSAVE, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDD, 6, {modrm_reg_ext=true}}, {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FRSTOR = {
		{{.FRSTOR, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDD, 4, {modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
	},
	.FSTSW = {
		{{.FSTSW, {.M16,     .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 7   , {modrm_reg_ext=true}}, {implicit_wr={.RAX, .FPU_SW}, writes_mem=true}},
		{{.FSTSW, {.AX_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xDF, 0xE0, {}},                   {implicit_wr={.RAX, .FPU_SW}}},
	},
	.FNSTSW = {
		{{.FNSTSW, {.M16,     .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 7   , {modrm_reg_ext=true}}, {implicit_wr={.RAX, .FPU_SW}, writes_mem=true}},
		{{.FNSTSW, {.AX_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xDF, 0xE0, {}},                   {implicit_wr={.RAX, .FPU_SW}}},
	},
	.FXSAVE = {
		{{.FXSAVE, {.M512, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 0, {esc=._0F, modrm_reg_ext=true}}, {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FXSAVE64 = {
		{{.FXSAVE64, {.M512, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 0, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true}},
	},
	.FXRSTOR = {
		{{.FXRSTOR, {.M512, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 1, {esc=._0F, modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
	},
	.FXRSTOR64 = {
		{{.FXRSTOR64, {.M512, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 1, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true}},
	},
	.LGDT = {
		{{.LGDT, {.M16_32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 2, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}}},
		{{.LGDT, {.M16_64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 2, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.SGDT = {
		{{.SGDT, {.M16_32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 0, {esc=._0F, modrm_reg_ext=true}}, {written={0}, writes_mem=true}},
		{{.SGDT, {.M16_64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 0, {esc=._0F, modrm_reg_ext=true}}, {written={0}, writes_mem=true}},
	},
	.LIDT = {
		{{.LIDT, {.M16_32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 3, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}}},
		{{.LIDT, {.M16_64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 3, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.SIDT = {
		{{.SIDT, {.M16_32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 1, {esc=._0F, modrm_reg_ext=true}}, {written={0}, writes_mem=true}},
		{{.SIDT, {.M16_64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 1, {esc=._0F, modrm_reg_ext=true}}, {written={0}, writes_mem=true}},
	},
	.LLDT = {
		{{.LLDT, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 2, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.SLDT = {
		{{.SLDT, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 0, {esc=._0F, modrm_reg_ext=true}},                   {written={0}, writes_mem=true}},
		{{.SLDT, {.R32,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 0, {esc=._0F, modrm_reg_ext=true}},                   {written={0}}},
		{{.SLDT, {.R64,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 0, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {written={0}}},
	},
	.LTR = {
		{{.LTR, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 3, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.STR = {
		{{.STR, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 1, {esc=._0F, modrm_reg_ext=true}},                   {written={0}, writes_mem=true}},
		{{.STR, {.R32,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 1, {esc=._0F, modrm_reg_ext=true}},                   {written={0}}},
		{{.STR, {.R64,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 1, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {written={0}}},
	},
	.LMSW = {
		{{.LMSW, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 6, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.SMSW = {
		{{.SMSW, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 4, {esc=._0F, modrm_reg_ext=true}},                   {written={0}, writes_mem=true}},
		{{.SMSW, {.R32,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 4, {esc=._0F, modrm_reg_ext=true}},                   {written={0}}},
		{{.SMSW, {.R64,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 4, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {written={0}}},
	},
	.CLTS = {
		{{.CLTS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x06, 0, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.ARPL = {
		{{.ARPL, {.RM16, .R16, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x63, 0, {}}, {written={0}, read={1}, flags_wr={.ZF}, writes_mem=true, reads_mem=true}},
	},
	.LAR = {
		{{.LAR, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x02, 0, {esc=._0F}},                   {written={0}, read={1}, flags_wr={.ZF}, reads_mem=true}},
		{{.LAR, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x02, 0, {esc=._0F}},                   {written={0}, read={1}, flags_wr={.ZF}, reads_mem=true}},
		{{.LAR, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x02, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_wr={.ZF}, reads_mem=true}},
	},
	.LSL = {
		{{.LSL, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x03, 0, {esc=._0F}},                   {written={0}, read={1}, flags_wr={.ZF}, reads_mem=true}},
		{{.LSL, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x03, 0, {esc=._0F}},                   {written={0}, read={1}, flags_wr={.ZF}, reads_mem=true}},
		{{.LSL, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x03, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={1}, flags_wr={.ZF}, reads_mem=true}},
	},
	.VERR = {
		{{.VERR, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 4, {esc=._0F, modrm_reg_ext=true}}, {read={0}, flags_wr={.ZF}, reads_mem=true}},
	},
	.VERW = {
		{{.VERW, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 5, {esc=._0F, modrm_reg_ext=true}}, {read={0}, flags_wr={.ZF}, reads_mem=true}},
	},
	.INVD = {
		{{.INVD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x08, 0, {esc=._0F}}, {side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.WBINVD = {
		{{.WBINVD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x09, 0, {esc=._0F}}, {side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.INVLPG = {
		{{.INVLPG, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 7, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.INVPCID = {
		{{.INVPCID, {.R32, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x82, 0, {esc=._0F38, prefix=PREFIX_66}}, {read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
		{{.INVPCID, {.R64, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x82, 0, {esc=._0F38, prefix=PREFIX_66}}, {read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.RSM = {
		{{.RSM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAA, 0, {esc=._0F}}, {side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.RDMSR = {
		{{.RDMSR, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x32, 0, {esc=._0F}}, {implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}, side_effects={.PRIVILEGED}}},
	},
	.WRMSR = {
		{{.WRMSR, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x30, 0, {esc=._0F}}, {implicit_rd={.RAX, .RCX, .RDX}, side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.VMCALL = {
		{{.VMCALL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC1, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.VMLAUNCH = {
		{{.VMLAUNCH, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC2, {esc=._0F}}, {flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMRESUME = {
		{{.VMRESUME, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC3, {esc=._0F}}, {flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMXOFF = {
		{{.VMXOFF, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC4, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.VMXON = {
		{{.VMXON, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}}, {read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMCLEAR = {
		{{.VMCLEAR, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMPTRLD = {
		{{.VMPTRLD, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true}}, {read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMPTRST = {
		{{.VMPTRST, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, modrm_reg_ext=true}}, {read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMREAD = {
		{{.VMREAD, {.RM64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x78, 0, {esc=._0F}}, {written={0}, read={1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMWRITE = {
		{{.VMWRITE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x79, 0, {esc=._0F}}, {read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMFUNC = {
		{{.VMFUNC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD4, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.INVEPT = {
		{{.INVEPT, {.R64, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x80, 0, {esc=._0F38, prefix=PREFIX_66}}, {read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.INVVPID = {
		{{.INVVPID, {.R64, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x81, 0, {esc=._0F38, prefix=PREFIX_66}}, {read={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.ENCLS = {
		{{.ENCLS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xCF, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.ENCLU = {
		{{.ENCLU, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD7, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.ENCLV = {
		{{.ENCLV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC0, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.RDPKRU = {
		{{.RDPKRU, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xEE, {esc=._0F}}, {implicit_wr={.RAX}, implicit_rd={.RCX}}},
	},
	.WRPKRU = {
		{{.WRPKRU, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xEF, {esc=._0F}}, {implicit_rd={.RAX, .RCX, .RDX}}},
	},
	.INCSSPD = {
		{{.INCSSPD, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 5, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}}, {read={0}, side_effects={.CET}}},
	},
	.INCSSPQ = {
		{{.INCSSPQ, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 5, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true, modrm_reg_ext=true}}, {read={0}, side_effects={.CET}}},
	},
	.RDSSPD = {
		{{.RDSSPD, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x1E, 1, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}}, {written={0}, side_effects={.CET}}},
	},
	.RDSSPQ = {
		{{.RDSSPQ, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x1E, 1, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true, modrm_reg_ext=true}}, {written={0}, side_effects={.CET}}},
	},
	.SAVEPREVSSP = {
		{{.SAVEPREVSSP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xEA, {esc=._0F, prefix=PREFIX_F3}}, {side_effects={.CET}}},
	},
	.RSTORSSP = {
		{{.RSTORSSP, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 5, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}}, {read={0}, writes_mem=true, reads_mem=true, side_effects={.CET}}},
	},
	.WRSSD = {
		{{.WRSSD, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF6, 0, {esc=._0F38}}, {read={0, 1}, writes_mem=true, side_effects={.CET}}},
	},
	.WRSSQ = {
		{{.WRSSQ, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF6, 0, {esc=._0F38, force_rex_w=true}}, {read={0, 1}, writes_mem=true, side_effects={.CET}}},
	},
	.WRUSSD = {
		{{.WRUSSD, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_66}}, {read={0, 1}, writes_mem=true, side_effects={.CET}}},
	},
	.WRUSSQ = {
		{{.WRUSSQ, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_66, force_rex_w=true}}, {read={0, 1}, writes_mem=true, side_effects={.CET}}},
	},
	.SETSSBSY = {
		{{.SETSSBSY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xE8, {esc=._0F, prefix=PREFIX_F3}}, {side_effects={.CET}}},
	},
	.CLRSSBSY = {
		{{.CLRSSBSY, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}}, {read={0}, writes_mem=true, reads_mem=true, side_effects={.CET}}},
	},
	.ENDBR64 = {
		{{.ENDBR64, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x1E, 0xFA, {esc=._0F, prefix=PREFIX_F3}}, {side_effects={.HINT, .CET}}},
	},
	.ENDBR32 = {
		{{.ENDBR32, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x1E, 0xFB, {esc=._0F, prefix=PREFIX_F3}}, {side_effects={.HINT, .CET}}},
	},
	.XSAVE = {
		{{.XSAVE, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 4, {esc=._0F, modrm_reg_ext=true}}, {implicit_rd={.RAX, .RDX}, writes_mem=true}},
	},
	.XSAVE64 = {
		{{.XSAVE64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 4, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {implicit_rd={.RAX, .RDX}, writes_mem=true}},
	},
	.XRSTOR = {
		{{.XRSTOR, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 5, {esc=._0F, modrm_reg_ext=true}}, {implicit_wr={.MXCSR, .FPU_ST, .FPU_SW}, implicit_rd={.RAX, .RDX}, reads_mem=true}},
	},
	.XRSTOR64 = {
		{{.XRSTOR64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 5, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {implicit_wr={.MXCSR, .FPU_ST, .FPU_SW}, implicit_rd={.RAX, .RDX}, reads_mem=true}},
	},
	.XSAVEOPT = {
		{{.XSAVEOPT, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, modrm_reg_ext=true}}, {implicit_rd={.RAX, .RDX}, writes_mem=true}},
	},
	.XSAVEOPT64 = {
		{{.XSAVEOPT64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {implicit_rd={.RAX, .RDX}, writes_mem=true}},
	},
	.XSAVEC = {
		{{.XSAVEC, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 4, {esc=._0F, modrm_reg_ext=true}}, {implicit_rd={.RAX, .RDX}, writes_mem=true}},
	},
	.XSAVEC64 = {
		{{.XSAVEC64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 4, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {implicit_rd={.RAX, .RDX}, writes_mem=true}},
	},
	.XSAVES = {
		{{.XSAVES, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 5, {esc=._0F, modrm_reg_ext=true}}, {implicit_rd={.RAX, .RDX}, writes_mem=true, side_effects={.PRIVILEGED}}},
	},
	.XSAVES64 = {
		{{.XSAVES64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 5, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {implicit_rd={.RAX, .RDX}, writes_mem=true, side_effects={.PRIVILEGED}}},
	},
	.XRSTORS = {
		{{.XRSTORS, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 3, {esc=._0F, modrm_reg_ext=true}}, {implicit_wr={.MXCSR, .FPU_ST, .FPU_SW}, implicit_rd={.RAX, .RDX}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.XRSTORS64 = {
		{{.XRSTORS64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 3, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {implicit_wr={.MXCSR, .FPU_ST, .FPU_SW}, implicit_rd={.RAX, .RDX}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.PREFETCHT0 = {
		{{.PREFETCHT0, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x18, 1, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.HINT}}},
	},
	.PREFETCHT1 = {
		{{.PREFETCHT1, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x18, 2, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.HINT}}},
	},
	.PREFETCHT2 = {
		{{.PREFETCHT2, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x18, 3, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.HINT}}},
	},
	.PREFETCHNTA = {
		{{.PREFETCHNTA, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x18, 0, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.HINT}}},
	},
	.PREFETCHW = {
		{{.PREFETCHW, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x0D, 1, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.HINT}}},
	},
	.CLFLUSHOPT = {
		{{.CLFLUSHOPT, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 7, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.CACHE}}},
	},
	.CLWB = {
		{{.CLWB, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.CACHE}}},
	},
	.CLDEMOTE = {
		{{.CLDEMOTE, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x1C, 0, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.HINT}}},
	},
	.BSWAP = {
		{{.BSWAP, {.R32, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xC8, 0, {esc=._0F}},                   {written={0}, read={0}}},
		{{.BSWAP, {.R64, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xC8, 0, {esc=._0F, force_rex_w=true}}, {written={0}, read={0}}},
	},
	.CMPXCHG = {
		{{.CMPXCHG, {.RM8,  .R8,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB0, 0, {esc=._0F, lock_ok=true}},                   {written={0}, read={0, 1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.CMPXCHG, {.RM16, .R16, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB1, 0, {esc=._0F, lock_ok=true}},                   {written={0}, read={0, 1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.CMPXCHG, {.RM32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB1, 0, {esc=._0F, lock_ok=true}},                   {written={0}, read={0, 1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.CMPXCHG, {.RM64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB1, 0, {esc=._0F, force_rex_w=true, lock_ok=true}}, {written={0}, read={0, 1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.CMPXCHG8B = {
		{{.CMPXCHG8B, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 1, {esc=._0F, lock_ok=true, modrm_reg_ext=true}}, {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RBX, .RCX, .RDX}, flags_wr={.ZF}, writes_mem=true, reads_mem=true}},
	},
	.CMPXCHG16B = {
		{{.CMPXCHG16B, {.M128, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 1, {esc=._0F, force_rex_w=true, lock_ok=true, modrm_reg_ext=true}}, {read={0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RBX, .RCX, .RDX}, flags_wr={.ZF}, writes_mem=true, reads_mem=true}},
	},
	.XADD = {
		{{.XADD, {.RM8,  .R8,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xC0, 0, {esc=._0F, lock_ok=true}},                   {written={0, 1}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.XADD, {.RM16, .R16, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xC1, 0, {esc=._0F, lock_ok=true}},                   {written={0, 1}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.XADD, {.RM32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xC1, 0, {esc=._0F, lock_ok=true}},                   {written={0, 1}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
		{{.XADD, {.RM64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xC1, 0, {esc=._0F, force_rex_w=true, lock_ok=true}}, {written={0, 1}, read={0, 1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true}},
	},
	.BOUND = {
		{{.BOUND, {.R16, .M16_16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x62, 0, {mode_32_only=true}}, {read={0, 1}, reads_mem=true, side_effects={.TRAP}}},
		{{.BOUND, {.R32, .M32,    .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x62, 0, {mode_32_only=true}}, {read={0, 1}, reads_mem=true, side_effects={.TRAP}}},
	},
	.ENTER = {
		{{.ENTER, {.IMM16, .IMM8, .NONE, .NONE}, {.IW, .IB, .NONE, .NONE}, 0xC8, 0, {}}, {implicit_wr={.RSP, .RBP}, implicit_rd={.RSP, .RBP}, writes_mem=true}},
	},
	.LEAVE = {
		{{.LEAVE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xC9, 0, {}}, {implicit_wr={.RSP, .RBP}, implicit_rd={.RBP}, reads_mem=true}},
	},
	.XLAT = {
		{{.XLAT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD7, 0, {}}, {implicit_wr={.RAX}, implicit_rd={.RAX, .RBX}, reads_mem=true}},
	},
	.XLATB = {
		{{.XLATB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD7, 0, {}}, {implicit_wr={.RAX}, implicit_rd={.RAX, .RBX}, reads_mem=true}},
	},
	.MOVBE = {
		{{.MOVBE, {.R16, .M16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xF0, 0, {esc=._0F38}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVBE, {.R32, .M32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xF0, 0, {esc=._0F38}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVBE, {.R64, .M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xF0, 0, {esc=._0F38, force_rex_w=true}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVBE, {.M16, .R16, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xF1, 0, {esc=._0F38}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVBE, {.M32, .R32, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xF1, 0, {esc=._0F38}},                   {written={0}, read={1}, writes_mem=true, reads_mem=true}},
		{{.MOVBE, {.M64, .R64, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xF1, 0, {esc=._0F38, force_rex_w=true}}, {written={0}, read={1}, writes_mem=true, reads_mem=true}},
	},
	.RDRAND = {
		{{.RDRAND, {.R16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true}},                   {written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.RDRAND, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true}},                   {written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.RDRAND, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.RDSEED = {
		{{.RDSEED, {.R16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, modrm_reg_ext=true}},                   {written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.RDSEED, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, modrm_reg_ext=true}},                   {written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
		{{.RDSEED, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, force_rex_w=true, modrm_reg_ext=true}}, {written={0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}}},
	},
	.SWAPGS = {
		{{.SWAPGS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xF8, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.MONITOR = {
		{{.MONITOR, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC8, {esc=._0F}}, {implicit_rd={.RAX, .RCX, .RDX}, reads_mem=true}},
	},
	.MWAIT = {
		{{.MWAIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC9, {esc=._0F}}, {implicit_rd={.RAX, .RCX}, side_effects={.HALT}}},
	},
	.CLAC = {
		{{.CLAC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xCA, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.STAC = {
		{{.STAC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xCB, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.RDFSBASE = {
		{{.RDFSBASE, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 0, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}},                   {written={0}}},
		{{.RDFSBASE, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true, modrm_reg_ext=true}}, {written={0}}},
	},
	.RDGSBASE = {
		{{.RDGSBASE, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 1, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}},                   {written={0}}},
		{{.RDGSBASE, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 1, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true, modrm_reg_ext=true}}, {written={0}}},
	},
	.WRFSBASE = {
		{{.WRFSBASE, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 2, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}},                   {read={0}}},
		{{.WRFSBASE, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 2, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true, modrm_reg_ext=true}}, {read={0}}},
	},
	.WRGSBASE = {
		{{.WRGSBASE, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 3, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}},                   {read={0}}},
		{{.WRGSBASE, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 3, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true, modrm_reg_ext=true}}, {read={0}}},
	},
	.PTWRITE = {
		{{.PTWRITE, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 4, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}},                   {read={0}, reads_mem=true}},
		{{.PTWRITE, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 4, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true, modrm_reg_ext=true}}, {read={0}, reads_mem=true}},
	},
	.RDPID = {
		{{.RDPID, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}}, {written={0}}},
	},
	.WBNOINVD = {
		{{.WBNOINVD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x09, 0, {esc=._0F, prefix=PREFIX_F3}}, {side_effects={.SERIALIZING, .PRIVILEGED}}},
	},
	.SERIALIZE = {
		{{.SERIALIZE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xE8, {esc=._0F}}, {side_effects={.SERIALIZING}}},
	},
	.PREFETCH = {
		{{.PREFETCH, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x0D, 0, {esc=._0F, modrm_reg_ext=true}}, {read={0}, reads_mem=true, side_effects={.HINT}}},
	},
	.TPAUSE = {
		{{.TPAUSE, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}}, {read={0}, implicit_rd={.RAX, .RDX}, flags_wr={.CF}, side_effects={.HINT}}},
	},
	.UMONITOR = {
		{{.UMONITOR, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, prefix=PREFIX_F3, modrm_reg_ext=true}}, {read={0}, reads_mem=true}},
	},
	.UMWAIT = {
		{{.UMWAIT, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, prefix=PREFIX_F2, modrm_reg_ext=true}}, {read={0}, implicit_rd={.RAX, .RDX}, flags_wr={.CF}, side_effects={.HINT}}},
	},
	.MOVDIRI = {
		{{.MOVDIRI, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF9, 0, {esc=._0F38}},                   {read={0, 1}, writes_mem=true}},
		{{.MOVDIRI, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF9, 0, {esc=._0F38, force_rex_w=true}}, {read={0, 1}, writes_mem=true}},
	},
	.MOVDIR64B = {
		{{.MOVDIR64B, {.R64, .M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF8, 0, {esc=._0F38, prefix=PREFIX_66}}, {read={0}, implicit_rd={.RAX}, writes_mem=true, reads_mem=true}},
	},
	.ENQCMD = {
		{{.ENQCMD, {.R64, .M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF8, 0, {esc=._0F38, prefix=PREFIX_F2}}, {read={0}, flags_wr={.ZF}, writes_mem=true, reads_mem=true}},
	},
	.ENQCMDS = {
		{{.ENQCMDS, {.R64, .M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF8, 0, {esc=._0F38, prefix=PREFIX_F3}}, {read={0}, flags_wr={.ZF}, writes_mem=true, reads_mem=true}},
	},
	.AADD = {
		{{.AADD, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xFC, 0, {esc=._0F38}},                   {read={0, 1}, writes_mem=true, reads_mem=true}},
		{{.AADD, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xFC, 0, {esc=._0F38, force_rex_w=true}}, {read={0, 1}, writes_mem=true, reads_mem=true}},
	},
	.AAND = {
		{{.AAND, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xFC, 0, {esc=._0F38, prefix=PREFIX_66}},                   {read={0, 1}, writes_mem=true, reads_mem=true}},
		{{.AAND, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xFC, 0, {esc=._0F38, prefix=PREFIX_66, force_rex_w=true}}, {read={0, 1}, writes_mem=true, reads_mem=true}},
	},
	.AOR = {
		{{.AOR, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xFC, 0, {esc=._0F38, prefix=PREFIX_F2}},                   {read={0, 1}, writes_mem=true, reads_mem=true}},
		{{.AOR, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xFC, 0, {esc=._0F38, prefix=PREFIX_F2, force_rex_w=true}}, {read={0, 1}, writes_mem=true, reads_mem=true}},
	},
	.AXOR = {
		{{.AXOR, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xFC, 0, {esc=._0F38, prefix=PREFIX_F3}},                   {read={0, 1}, writes_mem=true, reads_mem=true}},
		{{.AXOR, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xFC, 0, {esc=._0F38, prefix=PREFIX_F3, force_rex_w=true}}, {read={0, 1}, writes_mem=true, reads_mem=true}},
	},
	.XEND = {
		{{.XEND, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD5, {esc=._0F}}, {side_effects={.CONTROL}}},
	},
	.XTEST = {
		{{.XTEST, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD6, {esc=._0F}}, {flags_wr={.ZF}}},
	},
	.VMRUN = {
		{{.VMRUN, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD8, {esc=._0F}}, {implicit_rd={.RAX}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMMCALL = {
		{{.VMMCALL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD9, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.VMLOAD = {
		{{.VMLOAD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xDA, {esc=._0F}}, {implicit_rd={.RAX}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.VMSAVE = {
		{{.VMSAVE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xDB, {esc=._0F}}, {implicit_rd={.RAX}, writes_mem=true, side_effects={.PRIVILEGED}}},
	},
	.STGI = {
		{{.STGI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xDC, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.CLGI = {
		{{.CLGI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xDD, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.SKINIT = {
		{{.SKINIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xDE, {esc=._0F}}, {implicit_rd={.RAX}, side_effects={.PRIVILEGED}}},
	},
	.INVLPGA = {
		{{.INVLPGA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xDF, {esc=._0F}}, {implicit_rd={.RAX, .RCX}, side_effects={.PRIVILEGED}}},
	},
	.INVLPGB = {
		{{.INVLPGB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFE, {esc=._0F}}, {implicit_rd={.RAX, .RCX, .RDX}, side_effects={.PRIVILEGED}}},
	},
	.TLBSYNC = {
		{{.TLBSYNC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFF, {esc=._0F}}, {side_effects={.PRIVILEGED}}},
	},
	.PVALIDATE = {
		{{.PVALIDATE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFF, {esc=._0F, prefix=PREFIX_F2}}, {implicit_wr={.RAX}, implicit_rd={.RAX, .RCX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true}},
	},
	.RMPADJUST = {
		{{.RMPADJUST, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFE, {esc=._0F, prefix=PREFIX_F3}}, {implicit_wr={.RAX}, implicit_rd={.RAX, .RCX, .RDX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.RMPUPDATE = {
		{{.RMPUPDATE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFE, {esc=._0F, prefix=PREFIX_F2}}, {implicit_wr={.RAX}, implicit_rd={.RAX, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true, side_effects={.PRIVILEGED}}},
	},
	.PSMASH = {
		{{.PSMASH, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFF, {esc=._0F, prefix=PREFIX_F3}}, {implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, side_effects={.PRIVILEGED}}},
	},
	.CLZERO = {
		{{.CLZERO, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFC, {esc=._0F}}, {implicit_rd={.RAX}, writes_mem=true, side_effects={.CACHE}}},
	},
	.MONITORX = {
		{{.MONITORX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFA, {esc=._0F}}, {implicit_rd={.RAX, .RCX, .RDX}, reads_mem=true}},
	},
	.MWAITX = {
		{{.MWAITX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFB, {esc=._0F}}, {implicit_rd={.RAX, .RBX, .RCX}, side_effects={.HALT}}},
	},
	.RDPRU = {
		{{.RDPRU, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFD, {esc=._0F}}, {implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}}},
	},
	.MCOMMIT = {
		{{.MCOMMIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xFA, {esc=._0F, prefix=PREFIX_F3}}, {flags_wr={.CF}, side_effects={.FENCE}}},
	},
}
