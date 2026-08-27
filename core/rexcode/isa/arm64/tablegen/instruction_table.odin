package rexcode_arm64_tablegen

// =============================================================================
// rexcode  ·  AArch64 INSTRUCTION_TABLE
// =============================================================================
//
// One []Form per Mnemonic, where a Mnemonic is an ASSEMBLER mnemonic -- so a
// run holds every form that spells that name: ADD carries the immediate,
// shifted-register, extended-register, NEON and SVE forms, LDR carries all
// six addressing modes. The encoder scans the run and takes the first form
// whose operand TYPES match, so order is precedence: list forms in the order
// an assembler resolves them (immediate, then shifted-register, then
// extended-register -- `add w0,w1,w2` is the shifted form, and only the
// extended form can encode SP).
//
// A Form fuses an instruction form's Encoding with its
// Clobber, so INSTRUCTION_TABLE[m][i] carries both the bit pattern and the
// read/write + side-effect summary for form i of mnemonic m. This replaces the
// old pair of index-aligned tables (ENCODING_TABLE[m][i] / CLOBBER_TABLE[m][i]);
// co-locating the two in one struct removes the alignment invariant, so a form's
// encoding and clobber can no longer drift out of sync.
//
//
// --- Encoding: (bits, mask) model --------------------------------------------
//
// Same shape as MIPS/RISC-V. `bits` carries the static opcode pattern; `mask`
// covers exactly the bits that are fixed by the form. Operand-driven fields
// (Rd/Rn/Rm/imm*/sh/cond/...) land in zero positions of `bits` and are ORed in
// by the encoder.
//
// Sections (each follows the ARM ARM "C4.1.x Data-processing /" division):
//   §1  Data-processing -- immediate     (Add/Sub imm, Mov-wide, PC-rel)
//   §2  Data-processing -- shifted reg   (Add/Sub/AND/ORR/EOR/BIC/ORN/EON)
//   §3  Data-processing -- extended reg  (Add/Sub extended)
//   §4  Data-processing -- 2-source      (LSLV/LSRV/ASRV/RORV, UDIV/SDIV)
//   §5  Data-processing -- 3-source      (MADD/MSUB/SMADDL/.../UMULH)
//   §6  Data-processing -- 1-source      (CLZ/CLS/RBIT/REV/REV16/REV32)
//   §7  Conditional                      (CSEL/CSINC/CSINV/CSNEG)
//   §8  Branches                         (B/BL/BR/BLR/RET, B.cond, CBZ, TBZ)
//   §9  Loads / stores                   (LDR/STR families, LDP/STP, LDUR)
//   §10 System                           (NOP/HINT/ISB/MSR/MRS/SVC/...)
//   §11 FP scalar                        (FMOV/FADD/FCVT/FCMP/FCSEL/...)
//
// Logical-immediate forms (AND/ORR/EOR/ANDS imm) use the bitmask-immediate
// encoding (N:imms:immr); they're deferred to a follow-up turn that adds the
// bitmask encoder helper.
//
//
// --- Clobber: read/write + side-effect summary -------------------------------
//
// One Clobber per Form -- a read/write + side-effect summary for every form of
// every mnemonic. Derivation (from each form's operand TYPES, operand ROLES,
// and Encoding_Flags):
//
//   written / read  -- operand slots (0..3) whose register / memory base is a
//                      def / use. A slot counts only if its TYPE is register-
//                      or memory-like; immediate slots never appear. Direction
//                      comes from the ROLE, refined by instruction class:
//                        * RD/VD/PD/RT/RT2/ZA_TILE* are destinations, EXCEPT
//                          the data operand of a store (RT/VD on ST*), which is
//                          a source; and the status result of STXR/STXP (RD),
//                          which stays a def while RT/RT2 become sources.
//                        * A pre/post-index base (OFFSET_BASE_PRE/POST) is both
//                          read and written (address write-back).
//                        * A destination register re-listed as a later source
//                          slot (SVE destructive Zdn, accumulate) is read.
//                        * Branches define no GPR operand; targets/modifiers
//                          are reads.
//   implicit_wr/rd  -- LR on BL/BLR/RET, LR+SP on PAC*SP / RETAA, X16/X17 on
//                      PAC*1716, etc.
//   nzcv_wr         -- set for sets_flags forms (ADDS/SUBS/ANDS/CMP/CCMP/FCMP,
//                      SVE compares, WHILE*, PTRUES, ...).
//   nzcv_rd         -- any COND operand (CSEL/FCSEL/B.cond/CCMP), plus the
//                      carry readers ADC/ADCS/SBC/SBCS/NGC/NGCS; CCMP/CCMN both.
//   fpsr_wr/reads_fpcr -- per FP-op family (see notes); saturating integer ops
//                      (SQ*/UQ*/SUQ*/USQ*/SQRDML*) set QC.
//   reads_mem/writes_mem -- loads / stores / RMW atomics / MOPS.
//   side_effects    -- control flow, barriers, atomics, cache/TLB, PAC, BTI,
//                      wait, privileged system access, FFR, etc.
//
// Heuristic / best-effort fields (structurally faithful, semantically approximate):
//   * FPSR exception-bit sets and reads_fpcr are assigned per mnemonic family,
//     not per-corner-case; treat them as "flags this class may raise".
//   * Accumulate detection (destination is read-modified) is name-driven for
//     the families that fold the accumulator into the destination (MLA/MLS/DOT/
//     FMLA/FCMLA/SQRDML*/MOPA, shift-accumulate, bit-insert, AES/SHA/SM3/SM4,
//     PAC in-place). Multiply-adds with a separate Ra/Va operand (MADD/FMADD/...)
//     are correctly NOT dest-reads.
//   * LD1-4/ST1-4 register lists occupy a single operand slot, so max operand
//     count stays at 4 (matches Operand_Set / the encoder's model).
//   * Acquire/release accesses carry the FENCE side effect to model their
//     one-way ordering (distinct from the register/memory read/write sets).
//   * Requires the companion clobber_types.odin (adds X16/X17 to Clobber_Reg
//     and FFR to Side_Effect).
// =============================================================================


Form :: struct {
	using encoding: Encoding,
	clobber: Clobber,
}

@(rodata)
INSTRUCTION_TABLE := [Mnemonic][]Form{
	.INVALID = {
	},
	.ADD = {
		{{.ADD,            {.WSP_REG, .WSP_REG,     .IMM_12,     .NONE},    {.RD, .RN, .IMM12, .NONE}, 0x11000000, 0xFF800000, .BASE, {}},                                    {written={0}, read={1}}},
		{{.ADD,            {.XSP_REG, .XSP_REG,     .IMM_12,     .NONE},    {.RD, .RN, .IMM12, .NONE}, 0x91000000, 0xFF800000, .BASE, {is_64=true}},                          {written={0}, read={1}}},
		{{.ADD,            {.W_REG,   .W_REG,       .W_SHIFTED,  .NONE},    {.RD, .RN, .RM,    .NONE}, 0x0B000000, 0xFF200000, .BASE, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.X_REG,   .X_REG,       .X_SHIFTED,  .NONE},    {.RD, .RN, .RM,    .NONE}, 0x8B000000, 0xFF200000, .BASE, {is_64=true}},                          {written={0}, read={1, 2}}},
		{{.ADD,            {.WSP_REG, .WSP_REG,     .W_EXTENDED, .NONE},    {.RD, .RN, .RM,    .NONE}, 0x0B200000, 0xFFE00000, .BASE, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.XSP_REG, .XSP_REG,     .X_EXTENDED, .NONE},    {.RD, .RN, .RM,    .NONE}, 0x8B200000, 0xFFE00000, .BASE, {is_64=true}},                          {written={0}, read={1, 2}}},
		{{.ADD,            {.V_16B,   .V_16B,       .V_16B,      .NONE},    {.VD, .VN, .VM,    .NONE}, 0x4E208400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.V_8H,    .V_8H,        .V_8H,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x4E608400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.V_4S,    .V_4S,        .V_4S,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x4EA08400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.V_2D,    .V_2D,        .V_2D,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x4EE08400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.V_8B,    .V_8B,        .V_8B,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x0E208400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.V_4H,    .V_4H,        .V_4H,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x0E608400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.V_2S,    .V_2S,        .V_2S,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x0EA08400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.Z_REG_B, .Z_REG_B,     .Z_REG_B,    .NONE},    {.VD, .VN, .VM,    .NONE}, 0x04200000, 0xFFE0FC00, .SVE,  {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.Z_REG_H, .Z_REG_H,     .Z_REG_H,    .NONE},    {.VD, .VN, .VM,    .NONE}, 0x04600000, 0xFFE0FC00, .SVE,  {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.Z_REG_S, .Z_REG_S,     .Z_REG_S,    .NONE},    {.VD, .VN, .VM,    .NONE}, 0x04A00000, 0xFFE0FC00, .SVE,  {}},                                    {written={0}, read={1, 2}}},
		{{.ADD,            {.Z_REG_D, .Z_REG_D,     .Z_REG_D,    .NONE},    {.VD, .VN, .VM,    .NONE}, 0x04E00000, 0xFFE0FC00, .SVE,  {is_64=true}},                          {written={0}, read={1, 2}}},
		{{.ADD,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B,    .Z_REG_B}, {.VD, .PG, .VD,    .VM},   0x04000000, 0xFFE0E000, .SVE,  {}},                                    {written={0}, read={1, 2, 3}}},
		{{.ADD,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H,    .Z_REG_H}, {.VD, .PG, .VD,    .VM},   0x04400000, 0xFFE0E000, .SVE,  {}},                                    {written={0}, read={1, 2, 3}}},
		{{.ADD,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S,    .Z_REG_S}, {.VD, .PG, .VD,    .VM},   0x04800000, 0xFFE0E000, .SVE,  {}},                                    {written={0}, read={1, 2, 3}}},
		{{.ADD,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D,    .Z_REG_D}, {.VD, .PG, .VD,    .VM},   0x04C00000, 0xFFE0E000, .SVE,  {is_64=true}},                          {written={0}, read={1, 2, 3}}},
	},
	.ADDS = {
		{{.ADDS,           {.W_REG, .WSP_REG, .IMM_12,     .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x31000000, 0xFF800000, .BASE, {sets_flags=true}},                              {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ADDS,           {.X_REG, .XSP_REG, .IMM_12,     .NONE}, {.RD, .RN, .IMM12, .NONE}, 0xB1000000, 0xFF800000, .BASE, {sets_flags=true, is_64=true}},                  {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ADDS,           {.W_REG, .W_REG,   .W_SHIFTED,  .NONE}, {.RD, .RN, .RM,    .NONE}, 0x2B000000, 0xFF200000, .BASE, {sets_flags=true}},                              {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ADDS,           {.X_REG, .X_REG,   .X_SHIFTED,  .NONE}, {.RD, .RN, .RM,    .NONE}, 0xAB000000, 0xFF200000, .BASE, {sets_flags=true, is_64=true}},                  {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ADDS,           {.W_REG, .WSP_REG, .W_EXTENDED, .NONE}, {.RD, .RN, .RM,    .NONE}, 0x2B200000, 0xFFE00000, .BASE, {sets_flags=true}},                              {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ADDS,           {.X_REG, .XSP_REG, .X_EXTENDED, .NONE}, {.RD, .RN, .RM,    .NONE}, 0xAB200000, 0xFFE00000, .BASE, {sets_flags=true, is_64=true}},                  {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.SUB = {
		{{.SUB,            {.WSP_REG, .WSP_REG,     .IMM_12,     .NONE},    {.RD, .RN, .IMM12, .NONE}, 0x51000000, 0xFF800000, .BASE, {}},                                    {written={0}, read={1}}},
		{{.SUB,            {.XSP_REG, .XSP_REG,     .IMM_12,     .NONE},    {.RD, .RN, .IMM12, .NONE}, 0xD1000000, 0xFF800000, .BASE, {is_64=true}},                          {written={0}, read={1}}},
		{{.SUB,            {.W_REG,   .W_REG,       .W_SHIFTED,  .NONE},    {.RD, .RN, .RM,    .NONE}, 0x4B000000, 0xFF200000, .BASE, {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.X_REG,   .X_REG,       .X_SHIFTED,  .NONE},    {.RD, .RN, .RM,    .NONE}, 0xCB000000, 0xFF200000, .BASE, {is_64=true}},                          {written={0}, read={1, 2}}},
		{{.SUB,            {.WSP_REG, .WSP_REG,     .W_EXTENDED, .NONE},    {.RD, .RN, .RM,    .NONE}, 0x4B200000, 0xFFE00000, .BASE, {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.XSP_REG, .XSP_REG,     .X_EXTENDED, .NONE},    {.RD, .RN, .RM,    .NONE}, 0xCB200000, 0xFFE00000, .BASE, {is_64=true}},                          {written={0}, read={1, 2}}},
		{{.SUB,            {.V_16B,   .V_16B,       .V_16B,      .NONE},    {.VD, .VN, .VM,    .NONE}, 0x6E208400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.V_8H,    .V_8H,        .V_8H,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x6E608400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.V_4S,    .V_4S,        .V_4S,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x6EA08400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.V_2D,    .V_2D,        .V_2D,       .NONE},    {.VD, .VN, .VM,    .NONE}, 0x6EE08400, 0xFFE0FC00, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.Z_REG_B, .Z_REG_B,     .Z_REG_B,    .NONE},    {.VD, .VN, .VM,    .NONE}, 0x04200400, 0xFFE0FC00, .SVE,  {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.Z_REG_H, .Z_REG_H,     .Z_REG_H,    .NONE},    {.VD, .VN, .VM,    .NONE}, 0x04600400, 0xFFE0FC00, .SVE,  {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.Z_REG_S, .Z_REG_S,     .Z_REG_S,    .NONE},    {.VD, .VN, .VM,    .NONE}, 0x04A00400, 0xFFE0FC00, .SVE,  {}},                                    {written={0}, read={1, 2}}},
		{{.SUB,            {.Z_REG_D, .Z_REG_D,     .Z_REG_D,    .NONE},    {.VD, .VN, .VM,    .NONE}, 0x04E00400, 0xFFE0FC00, .SVE,  {is_64=true}},                          {written={0}, read={1, 2}}},
		{{.SUB,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B,    .Z_REG_B}, {.VD, .PG, .VD,    .VM},   0x04010000, 0xFFE0E000, .SVE,  {}},                                    {written={0}, read={1, 2, 3}}},
		{{.SUB,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H,    .Z_REG_H}, {.VD, .PG, .VD,    .VM},   0x04410000, 0xFFE0E000, .SVE,  {}},                                    {written={0}, read={1, 2, 3}}},
		{{.SUB,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S,    .Z_REG_S}, {.VD, .PG, .VD,    .VM},   0x04810000, 0xFFE0E000, .SVE,  {}},                                    {written={0}, read={1, 2, 3}}},
		{{.SUB,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D,    .Z_REG_D}, {.VD, .PG, .VD,    .VM},   0x04C10000, 0xFFE0E000, .SVE,  {is_64=true}},                          {written={0}, read={1, 2, 3}}},
	},
	.SUBS = {
		{{.SUBS,           {.W_REG, .WSP_REG, .IMM_12,     .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x71000000, 0xFF800000, .BASE, {sets_flags=true}},                              {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.SUBS,           {.X_REG, .XSP_REG, .IMM_12,     .NONE}, {.RD, .RN, .IMM12, .NONE}, 0xF1000000, 0xFF800000, .BASE, {sets_flags=true, is_64=true}},                  {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.SUBS,           {.W_REG, .W_REG,   .W_SHIFTED,  .NONE}, {.RD, .RN, .RM,    .NONE}, 0x6B000000, 0xFF200000, .BASE, {sets_flags=true}},                              {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.SUBS,           {.X_REG, .X_REG,   .X_SHIFTED,  .NONE}, {.RD, .RN, .RM,    .NONE}, 0xEB000000, 0xFF200000, .BASE, {sets_flags=true, is_64=true}},                  {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.SUBS,           {.W_REG, .WSP_REG, .W_EXTENDED, .NONE}, {.RD, .RN, .RM,    .NONE}, 0x6B200000, 0xFFE00000, .BASE, {sets_flags=true}},                              {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.SUBS,           {.X_REG, .XSP_REG, .X_EXTENDED, .NONE}, {.RD, .RN, .RM,    .NONE}, 0xEB200000, 0xFFE00000, .BASE, {sets_flags=true, is_64=true}},                  {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.MOVZ = {
		{{.MOVZ,           {.W_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0x52800000, 0xFF800000, .BASE, {}},                                            {written={0}}},
		{{.MOVZ,           {.X_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0xD2800000, 0xFF800000, .BASE, {is_64=true}},                                  {written={0}}},
	},
	.MOVN = {
		{{.MOVN,           {.W_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0x12800000, 0xFF800000, .BASE, {}},                                            {written={0}}},
		{{.MOVN,           {.X_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0x92800000, 0xFF800000, .BASE, {is_64=true}},                                  {written={0}}},
	},
	.MOVK = {
		{{.MOVK,           {.W_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0x72800000, 0xFF800000, .BASE, {}},                                            {written={0}}},
		{{.MOVK,           {.X_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0xF2800000, 0xFF800000, .BASE, {is_64=true}},                                  {written={0}}},
	},
	.ADR = {
		{{.ADR,            {.X_REG, .REL_PG21, .NONE, .NONE}, {.RD, .BRANCH_PG21, .NONE, .NONE}, 0x10000000, 0x9F000000, .BASE, {}},                                          {written={0}}},
	},
	.ADRP = {
		{{.ADRP,           {.X_REG, .REL_PG21, .NONE, .NONE}, {.RD, .BRANCH_PG21, .NONE, .NONE}, 0x90000000, 0x9F000000, .BASE, {}},                                          {written={0}}},
	},
	.AND = {
		{{.AND,            {.W_REG,   .W_REG,       .W_SHIFTED,   .NONE},    {.RD, .RN,  .RM,            .NONE}, 0x0A000000, 0xFF200000, .BASE, {}},                          {written={0}, read={1, 2}}},
		{{.AND,            {.X_REG,   .X_REG,       .X_SHIFTED,   .NONE},    {.RD, .RN,  .RM,            .NONE}, 0x8A000000, 0xFF200000, .BASE, {is_64=true}},                {written={0}, read={1, 2}}},
		{{.AND,            {.WSP_REG, .W_REG,       .BITMASK_IMM, .NONE},    {.RD, .RN,  .BITMASK_FIELD, .NONE}, 0x12000000, 0xFFC00000, .BASE, {}},                          {written={0}, read={1}}},
		{{.AND,            {.XSP_REG, .X_REG,       .BITMASK_IMM, .NONE},    {.RD, .RN,  .BITMASK_FIELD, .NONE}, 0x92000000, 0xFF800000, .BASE, {is_64=true}},                {written={0}, read={1}}},
		{{.AND,            {.V_16B,   .V_16B,       .V_16B,       .NONE},    {.VD, .VN,  .VM,            .NONE}, 0x4E201C00, 0xFFE0FC00, .NEON, {}},                          {written={0}, read={1, 2}}},
		{{.AND,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D,     .Z_REG_D}, {.VD, .PG,  .VD,            .VM},   0x041A0000, 0xFFFFE000, .SVE,  {is_64=true}},                {written={0}, read={1, 2, 3}}},
		{{.AND,            {.P_REG,   .P_REG_ZERO,  .P_REG,       .P_REG},   {.PD, .PG4, .PN,            .PM},   0x25004000, 0xFFE0C210, .SVE,  {}},                          {written={0}, read={1, 2, 3}}},
	},
	.ANDS = {
		{{.ANDS,           {.W_REG, .W_REG,      .W_SHIFTED,   .NONE},  {.RD, .RN,  .RM,            .NONE}, 0x6A000000, 0xFF200000, .BASE, {sets_flags=true}},                {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ANDS,           {.X_REG, .X_REG,      .X_SHIFTED,   .NONE},  {.RD, .RN,  .RM,            .NONE}, 0xEA000000, 0xFF200000, .BASE, {sets_flags=true, is_64=true}},    {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ANDS,           {.W_REG, .W_REG,      .BITMASK_IMM, .NONE},  {.RD, .RN,  .BITMASK_FIELD, .NONE}, 0x72000000, 0xFFC00000, .BASE, {sets_flags=true}},                {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ANDS,           {.X_REG, .X_REG,      .BITMASK_IMM, .NONE},  {.RD, .RN,  .BITMASK_FIELD, .NONE}, 0xF2000000, 0xFF800000, .BASE, {sets_flags=true, is_64=true}},    {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.ANDS,           {.P_REG, .P_REG_ZERO, .P_REG,       .P_REG}, {.PD, .PG4, .PN,            .PM},   0x25404000, 0xFFE0C210, .SVE,  {sets_flags=true}},                {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.ORR = {
		{{.ORR,            {.W_REG,   .W_REG,       .W_SHIFTED,   .NONE},    {.RD, .RN,  .RM,            .NONE}, 0x2A000000, 0xFF200000, .BASE, {}},                          {written={0}, read={1, 2}}},
		{{.ORR,            {.X_REG,   .X_REG,       .X_SHIFTED,   .NONE},    {.RD, .RN,  .RM,            .NONE}, 0xAA000000, 0xFF200000, .BASE, {is_64=true}},                {written={0}, read={1, 2}}},
		{{.ORR,            {.WSP_REG, .W_REG,       .BITMASK_IMM, .NONE},    {.RD, .RN,  .BITMASK_FIELD, .NONE}, 0x32000000, 0xFFC00000, .BASE, {}},                          {written={0}, read={1}}},
		{{.ORR,            {.XSP_REG, .X_REG,       .BITMASK_IMM, .NONE},    {.RD, .RN,  .BITMASK_FIELD, .NONE}, 0xB2000000, 0xFF800000, .BASE, {is_64=true}},                {written={0}, read={1}}},
		{{.ORR,            {.V_16B,   .V_16B,       .V_16B,       .NONE},    {.VD, .VN,  .VM,            .NONE}, 0x4EA01C00, 0xFFE0FC00, .NEON, {}},                          {written={0}, read={1, 2}}},
		{{.ORR,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D,     .Z_REG_D}, {.VD, .PG,  .VD,            .VM},   0x04180000, 0xFFFFE000, .SVE,  {is_64=true}},                {written={0}, read={1, 2, 3}}},
		{{.ORR,            {.P_REG,   .P_REG_ZERO,  .P_REG,       .P_REG},   {.PD, .PG4, .PN,            .PM},   0x25804000, 0xFFE0C210, .SVE,  {}},                          {written={0}, read={1, 2, 3}}},
	},
	.EOR = {
		{{.EOR,            {.W_REG,   .W_REG,       .W_SHIFTED,   .NONE},    {.RD, .RN,  .RM,            .NONE}, 0x4A000000, 0xFF200000, .BASE, {}},                          {written={0}, read={1, 2}}},
		{{.EOR,            {.X_REG,   .X_REG,       .X_SHIFTED,   .NONE},    {.RD, .RN,  .RM,            .NONE}, 0xCA000000, 0xFF200000, .BASE, {is_64=true}},                {written={0}, read={1, 2}}},
		{{.EOR,            {.WSP_REG, .W_REG,       .BITMASK_IMM, .NONE},    {.RD, .RN,  .BITMASK_FIELD, .NONE}, 0x52000000, 0xFFC00000, .BASE, {}},                          {written={0}, read={1}}},
		{{.EOR,            {.XSP_REG, .X_REG,       .BITMASK_IMM, .NONE},    {.RD, .RN,  .BITMASK_FIELD, .NONE}, 0xD2000000, 0xFF800000, .BASE, {is_64=true}},                {written={0}, read={1}}},
		{{.EOR,            {.V_16B,   .V_16B,       .V_16B,       .NONE},    {.VD, .VN,  .VM,            .NONE}, 0x6E201C00, 0xFFE0FC00, .NEON, {}},                          {written={0}, read={1, 2}}},
		{{.EOR,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D,     .Z_REG_D}, {.VD, .PG,  .VD,            .VM},   0x04190000, 0xFFFFE000, .SVE,  {is_64=true}},                {written={0}, read={1, 2, 3}}},
		{{.EOR,            {.P_REG,   .P_REG_ZERO,  .P_REG,       .P_REG},   {.PD, .PG4, .PN,            .PM},   0x25004200, 0xFFE0C210, .SVE,  {}},                          {written={0}, read={1, 2, 3}}},
	},
	.BIC = {
		{{.BIC,            {.W_REG,   .W_REG,       .W_SHIFTED, .NONE},    {.RD, .RN,  .RM, .NONE}, 0x0A200000, 0xFF200000, .BASE, {}},                                       {written={0}, read={1, 2}}},
		{{.BIC,            {.X_REG,   .X_REG,       .X_SHIFTED, .NONE},    {.RD, .RN,  .RM, .NONE}, 0x8A200000, 0xFF200000, .BASE, {is_64=true}},                             {written={0}, read={1, 2}}},
		{{.BIC,            {.V_16B,   .V_16B,       .V_16B,     .NONE},    {.VD, .VN,  .VM, .NONE}, 0x4E601C00, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}}},
		{{.BIC,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D,   .Z_REG_D}, {.VD, .PG,  .VD, .VM},   0x041B0000, 0xFFFFE000, .SVE,  {is_64=true}},                             {written={0}, read={1, 2, 3}}},
		{{.BIC,            {.P_REG,   .P_REG_ZERO,  .P_REG,     .P_REG},   {.PD, .PG4, .PN, .PM},   0x25004010, 0xFFE0C210, .SVE,  {}},                                       {written={0}, read={1, 2, 3}}},
	},
	.BICS = {
		{{.BICS,           {.W_REG, .W_REG,      .W_SHIFTED, .NONE},  {.RD, .RN,  .RM, .NONE}, 0x6A200000, 0xFF200000, .BASE, {sets_flags=true}},                             {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.BICS,           {.X_REG, .X_REG,      .X_SHIFTED, .NONE},  {.RD, .RN,  .RM, .NONE}, 0xEA200000, 0xFF200000, .BASE, {sets_flags=true, is_64=true}},                 {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.BICS,           {.P_REG, .P_REG_ZERO, .P_REG,     .P_REG}, {.PD, .PG4, .PN, .PM},   0x25404010, 0xFFE0C210, .SVE,  {sets_flags=true}},                             {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.ORN = {
		{{.ORN,            {.W_REG, .W_REG,      .W_SHIFTED, .NONE},  {.RD, .RN,  .RM, .NONE}, 0x2A200000, 0xFF200000, .BASE, {}},                                            {written={0}, read={1, 2}}},
		{{.ORN,            {.X_REG, .X_REG,      .X_SHIFTED, .NONE},  {.RD, .RN,  .RM, .NONE}, 0xAA200000, 0xFF200000, .BASE, {is_64=true}},                                  {written={0}, read={1, 2}}},
		{{.ORN,            {.V_16B, .V_16B,      .V_16B,     .NONE},  {.VD, .VN,  .VM, .NONE}, 0x4EE01C00, 0xFFE0FC00, .NEON, {}},                                            {written={0}, read={1, 2}}},
		{{.ORN,            {.P_REG, .P_REG_ZERO, .P_REG,     .P_REG}, {.PD, .PG4, .PN, .PM},   0x25804010, 0xFFE0C210, .SVE,  {}},                                            {written={0}, read={1, 2, 3}}},
	},
	.EON = {
		{{.EON,            {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x4A200000, 0xFF200000, .BASE, {}},                                                   {written={0}, read={1, 2}}},
		{{.EON,            {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xCA200000, 0xFF200000, .BASE, {is_64=true}},                                         {written={0}, read={1, 2}}},
	},
	.LSL = {
		{{.LSL,            {.W_REG,   .W_REG,       .W_REG,   .NONE},    {.RD, .RN, .RM,            .NONE}, 0x1AC02000, 0xFFE0FC00, .BASE, {}},                               {written={0}, read={1, 2}}},
		{{.LSL,            {.X_REG,   .X_REG,       .X_REG,   .NONE},    {.RD, .RN, .RM,            .NONE}, 0x9AC02000, 0xFFE0FC00, .BASE, {is_64=true}},                     {written={0}, read={1, 2}}},
		{{.LSL,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD,            .VM},   0x04138000, 0xFFE0E000, .SVE,  {}},                               {written={0}, read={1, 2, 3}}},
		{{.LSL,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD,            .VM},   0x04538000, 0xFFE0E000, .SVE,  {}},                               {written={0}, read={1, 2, 3}}},
		{{.LSL,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD,            .VM},   0x04938000, 0xFFE0E000, .SVE,  {}},                               {written={0}, read={1, 2, 3}}},
		{{.LSL,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD,            .VM},   0x04D38000, 0xFFE0E000, .SVE,  {is_64=true}},                     {written={0}, read={1, 2, 3}}},
		{{.LSL,            {.W_REG,   .W_REG,       .IMM_5,   .NONE},    {.RD, .RN, .ENC_LSL_IMM_W, .NONE}, 0x53000000, 0xFFC00000, .BASE, {}},                               {written={0}, read={1}}},
		{{.LSL,            {.X_REG,   .X_REG,       .IMM_6,   .NONE},    {.RD, .RN, .ENC_LSL_IMM_X, .NONE}, 0xD3400000, 0xFFC00000, .BASE, {is_64=true}},                     {written={0}, read={1}}},
	},
	.LSR = {
		{{.LSR,            {.W_REG,   .W_REG,       .W_REG,   .NONE},    {.RD, .RN, .RM,             .NONE}, 0x1AC02400, 0xFFE0FC00, .BASE, {}},                              {written={0}, read={1, 2}}},
		{{.LSR,            {.X_REG,   .X_REG,       .X_REG,   .NONE},    {.RD, .RN, .RM,             .NONE}, 0x9AC02400, 0xFFE0FC00, .BASE, {is_64=true}},                    {written={0}, read={1, 2}}},
		{{.LSR,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD,             .VM},   0x04118000, 0xFFE0E000, .SVE,  {}},                              {written={0}, read={1, 2, 3}}},
		{{.LSR,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD,             .VM},   0x04518000, 0xFFE0E000, .SVE,  {}},                              {written={0}, read={1, 2, 3}}},
		{{.LSR,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD,             .VM},   0x04918000, 0xFFE0E000, .SVE,  {}},                              {written={0}, read={1, 2, 3}}},
		{{.LSR,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD,             .VM},   0x04D18000, 0xFFE0E000, .SVE,  {is_64=true}},                    {written={0}, read={1, 2, 3}}},
		{{.LSR,            {.W_REG,   .W_REG,       .IMM_5,   .NONE},    {.RD, .RN, .ENC_SHIFT_IMMR, .NONE}, 0x53007C00, 0xFFC0FC00, .BASE, {}},                              {written={0}, read={1}}},
		{{.LSR,            {.X_REG,   .X_REG,       .IMM_6,   .NONE},    {.RD, .RN, .ENC_SHIFT_IMMR, .NONE}, 0xD340FC00, 0xFFC0FC00, .BASE, {is_64=true}},                    {written={0}, read={1}}},
	},
	.ASR = {
		{{.ASR,            {.W_REG,   .W_REG,       .W_REG,   .NONE},    {.RD, .RN, .RM,             .NONE}, 0x1AC02800, 0xFFE0FC00, .BASE, {}},                              {written={0}, read={1, 2}}},
		{{.ASR,            {.X_REG,   .X_REG,       .X_REG,   .NONE},    {.RD, .RN, .RM,             .NONE}, 0x9AC02800, 0xFFE0FC00, .BASE, {is_64=true}},                    {written={0}, read={1, 2}}},
		{{.ASR,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD,             .VM},   0x04108000, 0xFFE0E000, .SVE,  {}},                              {written={0}, read={1, 2, 3}}},
		{{.ASR,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD,             .VM},   0x04508000, 0xFFE0E000, .SVE,  {}},                              {written={0}, read={1, 2, 3}}},
		{{.ASR,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD,             .VM},   0x04908000, 0xFFE0E000, .SVE,  {}},                              {written={0}, read={1, 2, 3}}},
		{{.ASR,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD,             .VM},   0x04D08000, 0xFFE0E000, .SVE,  {is_64=true}},                    {written={0}, read={1, 2, 3}}},
		{{.ASR,            {.W_REG,   .W_REG,       .IMM_5,   .NONE},    {.RD, .RN, .ENC_SHIFT_IMMR, .NONE}, 0x13007C00, 0xFFC0FC00, .BASE, {}},                              {written={0}, read={1}}},
		{{.ASR,            {.X_REG,   .X_REG,       .IMM_6,   .NONE},    {.RD, .RN, .ENC_SHIFT_IMMR, .NONE}, 0x9340FC00, 0xFFC0FC00, .BASE, {is_64=true}},                    {written={0}, read={1}}},
	},
	.ROR = {
		{{.ROR,            {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN,             .RM,            .NONE}, 0x1AC02C00, 0xFFE0FC00, .BASE, {}},                                {written={0}, read={1, 2}}},
		{{.ROR,            {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN,             .RM,            .NONE}, 0x9AC02C00, 0xFFE0FC00, .BASE, {is_64=true}},                      {written={0}, read={1, 2}}},
		{{.ROR,            {.W_REG, .W_REG, .IMM_5, .NONE}, {.RD, .ENC_DUAL_RN_RM, .ENC_ROR_SHIFT, .NONE}, 0x13800000, 0xFFE00000, .BASE, {}},                                {written={0}, read={1}}},
		{{.ROR,            {.X_REG, .X_REG, .IMM_6, .NONE}, {.RD, .ENC_DUAL_RN_RM, .ENC_ROR_SHIFT, .NONE}, 0x93C00000, 0xFFE00000, .BASE, {is_64=true}},                      {written={0}, read={1}}},
	},
	.UDIV = {
		{{.UDIV,           {.W_REG,   .W_REG,       .W_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1AC00800, 0xFFE0FC00, .BASE, {}},                                          {written={0}, read={1, 2}}},
		{{.UDIV,           {.X_REG,   .X_REG,       .X_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x9AC00800, 0xFFE0FC00, .BASE, {is_64=true}},                                {written={0}, read={1, 2}}},
		{{.UDIV,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x04950000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UDIV,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04D50000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.SDIV = {
		{{.SDIV,           {.W_REG,   .W_REG,       .W_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1AC00C00, 0xFFE0FC00, .BASE, {}},                                          {written={0}, read={1, 2}}},
		{{.SDIV,           {.X_REG,   .X_REG,       .X_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x9AC00C00, 0xFFE0FC00, .BASE, {is_64=true}},                                {written={0}, read={1, 2}}},
		{{.SDIV,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x04940000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SDIV,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04D40000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.MADD = {
		{{.MADD,           {.W_REG, .W_REG, .W_REG, .W_REG}, {.RD, .RN, .RM, .RA}, 0x1B000000, 0xFFE08000, .BASE, {}},                                                        {written={0}, read={1, 2, 3}}},
		{{.MADD,           {.X_REG, .X_REG, .X_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9B000000, 0xFFE08000, .BASE, {is_64=true}},                                              {written={0}, read={1, 2, 3}}},
	},
	.MSUB = {
		{{.MSUB,           {.W_REG, .W_REG, .W_REG, .W_REG}, {.RD, .RN, .RM, .RA}, 0x1B008000, 0xFFE08000, .BASE, {}},                                                        {written={0}, read={1, 2, 3}}},
		{{.MSUB,           {.X_REG, .X_REG, .X_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9B008000, 0xFFE08000, .BASE, {is_64=true}},                                              {written={0}, read={1, 2, 3}}},
	},
	.SMADDL = {
		{{.SMADDL,         {.X_REG, .W_REG, .W_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9B200000, 0xFFE08000, .BASE, {is_64=true}},                                              {written={0}, read={1, 2, 3}}},
	},
	.SMSUBL = {
		{{.SMSUBL,         {.X_REG, .W_REG, .W_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9B208000, 0xFFE08000, .BASE, {is_64=true}},                                              {written={0}, read={1, 2, 3}}},
	},
	.UMADDL = {
		{{.UMADDL,         {.X_REG, .W_REG, .W_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9BA00000, 0xFFE08000, .BASE, {is_64=true}},                                              {written={0}, read={1, 2, 3}}},
	},
	.UMSUBL = {
		{{.UMSUBL,         {.X_REG, .W_REG, .W_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9BA08000, 0xFFE08000, .BASE, {is_64=true}},                                              {written={0}, read={1, 2, 3}}},
	},
	.SMULH = {
		{{.SMULH,          {.X_REG,   .X_REG,       .X_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x9B407C00, 0xFFE0FC00, .BASE, {is_64=true}},                                {written={0}, read={1, 2}}},
		{{.SMULH,          {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x04120000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMULH,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x04520000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMULH,          {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x04920000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMULH,          {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04D20000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.UMULH = {
		{{.UMULH,          {.X_REG,   .X_REG,       .X_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x9BC07C00, 0xFFE0FC00, .BASE, {is_64=true}},                                {written={0}, read={1, 2}}},
		{{.UMULH,          {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x04130000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMULH,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x04530000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMULH,          {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x04930000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMULH,          {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04D30000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.CLZ = {
		{{.CLZ,            {.W_REG,   .W_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC01000, 0xFFFFFC00, .BASE, {}},                                           {written={0}, read={1}}},
		{{.CLZ,            {.X_REG,   .X_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC01000, 0xFFFFFC00, .BASE, {is_64=true}},                                 {written={0}, read={1}}},
		{{.CLZ,            {.V_8B,    .V_8B,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E204800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLZ,            {.V_16B,   .V_16B,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E204800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLZ,            {.V_4H,    .V_4H,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E604800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLZ,            {.V_8H,    .V_8H,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E604800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLZ,            {.V_2S,    .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA04800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLZ,            {.V_4S,    .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA04800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLZ,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0419A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CLZ,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0459A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CLZ,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0499A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CLZ,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x04D9A000, 0xFFE0E000, .SVE,  {is_64=true}},                                 {written={0}, read={1, 2}}},
	},
	.CLS = {
		{{.CLS,            {.W_REG,   .W_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC01400, 0xFFFFFC00, .BASE, {}},                                           {written={0}, read={1}}},
		{{.CLS,            {.X_REG,   .X_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC01400, 0xFFFFFC00, .BASE, {is_64=true}},                                 {written={0}, read={1}}},
		{{.CLS,            {.V_8B,    .V_8B,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E204800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLS,            {.V_16B,   .V_16B,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E204800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLS,            {.V_4H,    .V_4H,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E604800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLS,            {.V_8H,    .V_8H,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E604800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLS,            {.V_2S,    .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA04800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLS,            {.V_4S,    .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA04800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CLS,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0418A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CLS,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0458A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CLS,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0498A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CLS,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x04D8A000, 0xFFE0E000, .SVE,  {is_64=true}},                                 {written={0}, read={1, 2}}},
	},
	.RBIT = {
		{{.RBIT,           {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC00000, 0xFFFFFC00, .BASE, {}},                                                      {written={0}, read={1}}},
		{{.RBIT,           {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC00000, 0xFFFFFC00, .BASE, {is_64=true}},                                            {written={0}, read={1}}},
		{{.RBIT,           {.V_8B,  .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E605800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.RBIT,           {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E605800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.REV = {
		{{.REV,            {.W_REG,   .W_REG,   .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC00800, 0xFFFFFC00, .BASE, {}},                                                  {written={0}, read={1}}},
		{{.REV,            {.X_REG,   .X_REG,   .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC00C00, 0xFFFFFC00, .BASE, {is_64=true}},                                        {written={0}, read={1}}},
		{{.REV,            {.Z_REG_B, .Z_REG_B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05383800, 0xFFFFFC00, .SVE,  {}},                                                  {written={0}, read={1}}},
		{{.REV,            {.Z_REG_H, .Z_REG_H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05783800, 0xFFFFFC00, .SVE,  {}},                                                  {written={0}, read={1}}},
		{{.REV,            {.Z_REG_S, .Z_REG_S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05B83800, 0xFFFFFC00, .SVE,  {}},                                                  {written={0}, read={1}}},
		{{.REV,            {.Z_REG_D, .Z_REG_D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05F83800, 0xFFFFFC00, .SVE,  {is_64=true}},                                        {written={0}, read={1}}},
		{{.REV,            {.P_REG,   .P_REG,   .NONE, .NONE}, {.PD, .PN, .NONE, .NONE}, 0x05344000, 0xFFFFFE10, .SVE,  {}},                                                  {written={0}, read={1}}},
	},
	.REV16 = {
		{{.REV16,          {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC00400, 0xFFFFFC00, .BASE, {}},                                                      {written={0}, read={1}}},
		{{.REV16,          {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC00400, 0xFFFFFC00, .BASE, {is_64=true}},                                            {written={0}, read={1}}},
		{{.REV16,          {.V_8B,  .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E201800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV16,          {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E201800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.REV32 = {
		{{.REV32,          {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC00800, 0xFFFFFC00, .BASE, {is_64=true}},                                            {written={0}, read={1}}},
		{{.REV32,          {.V_8B,  .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E200800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV32,          {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E200800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV32,          {.V_4H,  .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E600800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV32,          {.V_8H,  .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E600800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.CSEL = {
		{{.CSEL,           {.W_REG, .W_REG, .W_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1A800000, 0xFFE00C00, .BASE, {}},                                                    {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CSEL,           {.X_REG, .X_REG, .X_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x9A800000, 0xFFE00C00, .BASE, {is_64=true}},                                          {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
	},
	.CSINC = {
		{{.CSINC,          {.W_REG, .W_REG, .W_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1A800400, 0xFFE00C00, .BASE, {}},                                                    {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CSINC,          {.X_REG, .X_REG, .X_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x9A800400, 0xFFE00C00, .BASE, {is_64=true}},                                          {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
	},
	.CSINV = {
		{{.CSINV,          {.W_REG, .W_REG, .W_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x5A800000, 0xFFE00C00, .BASE, {}},                                                    {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CSINV,          {.X_REG, .X_REG, .X_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0xDA800000, 0xFFE00C00, .BASE, {is_64=true}},                                          {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
	},
	.CSNEG = {
		{{.CSNEG,          {.W_REG, .W_REG, .W_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x5A800400, 0xFFE00C00, .BASE, {}},                                                    {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CSNEG,          {.X_REG, .X_REG, .X_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0xDA800400, 0xFFE00C00, .BASE, {is_64=true}},                                          {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
	},
	.CCMP = {
		{{.CCMP,           {.W_REG, .W_REG, .NZCV_IMM, .COND}, {.RN, .RM,      .NZCV_FIELD, .COND_HI}, 0x7A400000, 0xFFE00C10, .BASE, {sets_flags=true}},                     {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CCMP,           {.X_REG, .X_REG, .NZCV_IMM, .COND}, {.RN, .RM,      .NZCV_FIELD, .COND_HI}, 0xFA400000, 0xFFE00C10, .BASE, {sets_flags=true, is_64=true}},         {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CCMP,           {.W_REG, .IMM_5, .NZCV_IMM, .COND}, {.RN, .IMM5_HI, .NZCV_FIELD, .COND_HI}, 0x7A400800, 0xFFE00C10, .BASE, {sets_flags=true}},                     {read={0}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CCMP,           {.X_REG, .IMM_5, .NZCV_IMM, .COND}, {.RN, .IMM5_HI, .NZCV_FIELD, .COND_HI}, 0xFA400800, 0xFFE00C10, .BASE, {sets_flags=true, is_64=true}},         {read={0}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.N, .Z, .C, .V}}},
	},
	.CCMN = {
		{{.CCMN,           {.W_REG, .W_REG, .NZCV_IMM, .COND}, {.RN, .RM,      .NZCV_FIELD, .COND_HI}, 0x3A400000, 0xFFE00C10, .BASE, {sets_flags=true}},                     {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CCMN,           {.X_REG, .X_REG, .NZCV_IMM, .COND}, {.RN, .RM,      .NZCV_FIELD, .COND_HI}, 0xBA400000, 0xFFE00C10, .BASE, {sets_flags=true, is_64=true}},         {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CCMN,           {.W_REG, .IMM_5, .NZCV_IMM, .COND}, {.RN, .IMM5_HI, .NZCV_FIELD, .COND_HI}, 0x3A400800, 0xFFE00C10, .BASE, {sets_flags=true}},                     {read={0}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.CCMN,           {.X_REG, .IMM_5, .NZCV_IMM, .COND}, {.RN, .IMM5_HI, .NZCV_FIELD, .COND_HI}, 0xBA400800, 0xFFE00C10, .BASE, {sets_flags=true, is_64=true}},         {read={0}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.N, .Z, .C, .V}}},
	},
	.EXTR = {
		{{.EXTR,           {.W_REG, .W_REG, .W_REG, .IMM_6}, {.RD, .RN, .RM, .IMM6}, 0x13800000, 0xFFE08000, .BASE, {}},                                                      {written={0}, read={1, 2}}},
		{{.EXTR,           {.X_REG, .X_REG, .X_REG, .IMM_6}, {.RD, .RN, .RM, .IMM6}, 0x93C00000, 0xFFE08000, .BASE, {is_64=true}},                                            {written={0}, read={1, 2}}},
	},
	.B = {
		{{.B,              {.REL_26, .NONE, .NONE, .NONE}, {.BRANCH_26, .NONE, .NONE, .NONE}, 0x14000000, 0xFC000000, .BASE, {branch=true}},                                  {side_effects={.CONTROL}}},
	},
	.BL = {
		{{.BL,             {.REL_26, .NONE, .NONE, .NONE}, {.BRANCH_26, .NONE, .NONE, .NONE}, 0x94000000, 0xFC000000, .BASE, {branch=true}},                                  {implicit_wr={.LR}, side_effects={.CONTROL}}},
	},
	.BR = {
		{{.BR,             {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD61F0000, 0xFFFFFC1F, .BASE, {branch=true, writes_pc=true}},                          {read={0}, side_effects={.CONTROL}}},
	},
	.BLR = {
		{{.BLR,            {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD63F0000, 0xFFFFFC1F, .BASE, {branch=true, writes_pc=true}},                          {read={0}, implicit_wr={.LR}, side_effects={.CONTROL}}},
	},
	.RET = {
		{{.RET,            {.X_REG, .NONE, .NONE, .NONE}, {.RN,   .NONE, .NONE, .NONE}, 0xD65F0000, 0xFFFFFC1F, .BASE, {branch=true, writes_pc=true}},                        {read={0}, side_effects={.CONTROL}}},
		{{.RET,            {.NONE,  .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD65F03C0, 0xFFFFFFFF, .BASE, {branch=true, writes_pc=true}},                        {implicit_rd={.LR}, side_effects={.CONTROL}}},
	},
	.B_COND = {
		{{.B_COND,         {.COND, .REL_19, .NONE, .NONE}, {.COND_LO, .BRANCH_19, .NONE, .NONE}, 0x54000000, 0xFF000010, .BASE, {cond_branch=true}},                          {nzcv_rd={.N, .Z, .C, .V}, side_effects={.CONTROL}}},
	},
	.CBZ = {
		{{.CBZ,            {.W_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0x34000000, 0xFF000000, .BASE, {cond_branch=true}},                              {read={0}, side_effects={.CONTROL}}},
		{{.CBZ,            {.X_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0xB4000000, 0xFF000000, .BASE, {cond_branch=true, is_64=true}},                  {read={0}, side_effects={.CONTROL}}},
	},
	.CBNZ = {
		{{.CBNZ,           {.W_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0x35000000, 0xFF000000, .BASE, {cond_branch=true}},                              {read={0}, side_effects={.CONTROL}}},
		{{.CBNZ,           {.X_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0xB5000000, 0xFF000000, .BASE, {cond_branch=true, is_64=true}},                  {read={0}, side_effects={.CONTROL}}},
	},
	.TBZ = {
		{{.TBZ,            {.X_REG, .IMM_5, .REL_14, .NONE}, {.RT, .TBZ_BIT, .BRANCH_14, .NONE}, 0x36000000, 0x7F000000, .BASE, {cond_branch=true}},                          {read={0}, side_effects={.CONTROL}}},
	},
	.TBNZ = {
		{{.TBNZ,           {.X_REG, .IMM_5, .REL_14, .NONE}, {.RT, .TBZ_BIT, .BRANCH_14, .NONE}, 0x37000000, 0x7F000000, .BASE, {cond_branch=true}},                          {read={0}, side_effects={.CONTROL}}},
	},
	.LDR = {
		{{.LDR,            {.W_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0xB9400000, 0xFFC00000, .BASE, {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.X_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0xF9400000, 0xFFC00000, .BASE, {is_64=true}},               {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.W_REG,   .REL_19,     .NONE, .NONE}, {.RT,       .BRANCH_19,          .NONE, .NONE}, 0x18000000, 0xFF000000, .BASE, {}},                         {written={0}}},
		{{.LDR,            {.X_REG,   .REL_19,     .NONE, .NONE}, {.RT,       .BRANCH_19,          .NONE, .NONE}, 0x58000000, 0xFF000000, .BASE, {is_64=true}},               {written={0}}},
		{{.LDR,            {.W_REG,   .MEM_PRE,    .NONE, .NONE}, {.RT,       .OFFSET_BASE_PRE,    .NONE, .NONE}, 0xB8400C00, 0xFFE00C00, .BASE, {}},                         {written={0, 1}, read={1}, reads_mem=true}},
		{{.LDR,            {.X_REG,   .MEM_PRE,    .NONE, .NONE}, {.RT,       .OFFSET_BASE_PRE,    .NONE, .NONE}, 0xF8400C00, 0xFFE00C00, .BASE, {is_64=true}},               {written={0, 1}, read={1}, reads_mem=true}},
		{{.LDR,            {.W_REG,   .MEM_POST,   .NONE, .NONE}, {.RT,       .OFFSET_BASE_POST,   .NONE, .NONE}, 0xB8400400, 0xFFE00C00, .BASE, {}},                         {written={0, 1}, read={1}, reads_mem=true}},
		{{.LDR,            {.X_REG,   .MEM_POST,   .NONE, .NONE}, {.RT,       .OFFSET_BASE_POST,   .NONE, .NONE}, 0xF8400400, 0xFFE00C00, .BASE, {is_64=true}},               {written={0, 1}, read={1}, reads_mem=true}},
		{{.LDR,            {.W_REG,   .MEM_REG,    .NONE, .NONE}, {.RT,       .OFFSET_REG,         .NONE, .NONE}, 0xB8600800, 0xFFE00C00, .BASE, {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.X_REG,   .MEM_REG,    .NONE, .NONE}, {.RT,       .OFFSET_REG,         .NONE, .NONE}, 0xF8600800, 0xFFE00C00, .BASE, {is_64=true}},               {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.B_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0x3D400000, 0xFFC00000, .FP,   {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.H_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0x7D400000, 0xFFC00000, .FP,   {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.S_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0xBD400000, 0xFFC00000, .FP,   {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.D_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0xFD400000, 0xFFC00000, .FP,   {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.Q_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0x3DC00000, 0xFFC00000, .FP,   {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.Z_REG_B, .MEM_SVE_SI, .NONE, .NONE}, {.VD,       .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0x85804000, 0xFFE0E000, .SVE,  {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.P_REG,   .MEM_SVE_SI, .NONE, .NONE}, {.PD,       .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0x85800000, 0xFFE0E010, .SVE,  {}},                         {written={0}, read={1}, reads_mem=true}},
		{{.LDR,            {.IMM_5,   .MEM_SVE_SI, .NONE, .NONE}, {.SVE_IMM5, .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0xE1000000, 0xFFE08000, .SME,  {}},                         {read={1}, reads_mem=true}},
	},
	.STR = {
		{{.STR,            {.W_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0xB9000000, 0xFFC00000, .BASE, {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.X_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0xF9000000, 0xFFC00000, .BASE, {is_64=true}},               {read={0, 1}, writes_mem=true}},
		{{.STR,            {.W_REG,   .MEM_PRE,    .NONE, .NONE}, {.RT,       .OFFSET_BASE_PRE,    .NONE, .NONE}, 0xB8000C00, 0xFFE00C00, .BASE, {}},                         {written={1}, read={0, 1}, writes_mem=true}},
		{{.STR,            {.X_REG,   .MEM_PRE,    .NONE, .NONE}, {.RT,       .OFFSET_BASE_PRE,    .NONE, .NONE}, 0xF8000C00, 0xFFE00C00, .BASE, {is_64=true}},               {written={1}, read={0, 1}, writes_mem=true}},
		{{.STR,            {.W_REG,   .MEM_POST,   .NONE, .NONE}, {.RT,       .OFFSET_BASE_POST,   .NONE, .NONE}, 0xB8000400, 0xFFE00C00, .BASE, {}},                         {written={1}, read={0, 1}, writes_mem=true}},
		{{.STR,            {.X_REG,   .MEM_POST,   .NONE, .NONE}, {.RT,       .OFFSET_BASE_POST,   .NONE, .NONE}, 0xF8000400, 0xFFE00C00, .BASE, {is_64=true}},               {written={1}, read={0, 1}, writes_mem=true}},
		{{.STR,            {.W_REG,   .MEM_REG,    .NONE, .NONE}, {.RT,       .OFFSET_REG,         .NONE, .NONE}, 0xB8200800, 0xFFE00C00, .BASE, {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.X_REG,   .MEM_REG,    .NONE, .NONE}, {.RT,       .OFFSET_REG,         .NONE, .NONE}, 0xF8200800, 0xFFE00C00, .BASE, {is_64=true}},               {read={0, 1}, writes_mem=true}},
		{{.STR,            {.B_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0x3D000000, 0xFFC00000, .FP,   {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.H_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0x7D000000, 0xFFC00000, .FP,   {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.S_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0xBD000000, 0xFFC00000, .FP,   {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.D_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0xFD000000, 0xFFC00000, .FP,   {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.Q_REG,   .MEM_OFFSET, .NONE, .NONE}, {.RT,       .OFFSET_BASE_U12,    .NONE, .NONE}, 0x3D800000, 0xFFC00000, .FP,   {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.Z_REG_B, .MEM_SVE_SI, .NONE, .NONE}, {.VD,       .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0xE5804000, 0xFFE0E000, .SVE,  {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.P_REG,   .MEM_SVE_SI, .NONE, .NONE}, {.PD,       .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0xE5800000, 0xFFE0E010, .SVE,  {}},                         {read={0, 1}, writes_mem=true}},
		{{.STR,            {.IMM_5,   .MEM_SVE_SI, .NONE, .NONE}, {.SVE_IMM5, .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0xE1200000, 0xFFE08000, .SME,  {}},                         {read={1}, writes_mem=true}},
	},
	.LDRB = {
		{{.LDRB,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12,  .NONE, .NONE}, 0x39400000, 0xFFC00000, .BASE, {}},                                   {written={0}, read={1}, reads_mem=true}},
		{{.LDRB,           {.W_REG, .MEM_PRE,    .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE,  .NONE, .NONE}, 0x38400C00, 0xFFE00C00, .BASE, {}},                                   {written={0, 1}, read={1}, reads_mem=true}},
		{{.LDRB,           {.W_REG, .MEM_POST,   .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0x38400400, 0xFFE00C00, .BASE, {}},                                   {written={0, 1}, read={1}, reads_mem=true}},
		{{.LDRB,           {.W_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,       .NONE, .NONE}, 0x38600800, 0xFFE00C00, .BASE, {}},                                   {written={0}, read={1}, reads_mem=true}},
	},
	.STRB = {
		{{.STRB,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12,  .NONE, .NONE}, 0x39000000, 0xFFC00000, .BASE, {}},                                   {read={0, 1}, writes_mem=true}},
		{{.STRB,           {.W_REG, .MEM_PRE,    .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE,  .NONE, .NONE}, 0x38000C00, 0xFFE00C00, .BASE, {}},                                   {written={1}, read={0, 1}, writes_mem=true}},
		{{.STRB,           {.W_REG, .MEM_POST,   .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0x38000400, 0xFFE00C00, .BASE, {}},                                   {written={1}, read={0, 1}, writes_mem=true}},
		{{.STRB,           {.W_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,       .NONE, .NONE}, 0x38200800, 0xFFE00C00, .BASE, {}},                                   {read={0, 1}, writes_mem=true}},
	},
	.LDRSB = {
		{{.LDRSB,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x39800000, 0xFFC00000, .BASE, {is_64=true}},                          {written={0}, read={1}, reads_mem=true}},
		{{.LDRSB,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x39C00000, 0xFFC00000, .BASE, {}},                                    {written={0}, read={1}, reads_mem=true}},
		{{.LDRSB,          {.W_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,      .NONE, .NONE}, 0x38E00800, 0xFFE00C00, .BASE, {}},                                    {written={0}, read={1}, reads_mem=true}},
		{{.LDRSB,          {.X_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,      .NONE, .NONE}, 0x38A00800, 0xFFE00C00, .BASE, {is_64=true}},                          {written={0}, read={1}, reads_mem=true}},
	},
	.LDRH = {
		{{.LDRH,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12,  .NONE, .NONE}, 0x79400000, 0xFFC00000, .BASE, {}},                                   {written={0}, read={1}, reads_mem=true}},
		{{.LDRH,           {.W_REG, .MEM_PRE,    .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE,  .NONE, .NONE}, 0x78400C00, 0xFFE00C00, .BASE, {}},                                   {written={0, 1}, read={1}, reads_mem=true}},
		{{.LDRH,           {.W_REG, .MEM_POST,   .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0x78400400, 0xFFE00C00, .BASE, {}},                                   {written={0, 1}, read={1}, reads_mem=true}},
		{{.LDRH,           {.W_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,       .NONE, .NONE}, 0x78600800, 0xFFE00C00, .BASE, {}},                                   {written={0}, read={1}, reads_mem=true}},
	},
	.STRH = {
		{{.STRH,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12,  .NONE, .NONE}, 0x79000000, 0xFFC00000, .BASE, {}},                                   {read={0, 1}, writes_mem=true}},
		{{.STRH,           {.W_REG, .MEM_PRE,    .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE,  .NONE, .NONE}, 0x78000C00, 0xFFE00C00, .BASE, {}},                                   {written={1}, read={0, 1}, writes_mem=true}},
		{{.STRH,           {.W_REG, .MEM_POST,   .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0x78000400, 0xFFE00C00, .BASE, {}},                                   {written={1}, read={0, 1}, writes_mem=true}},
		{{.STRH,           {.W_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,       .NONE, .NONE}, 0x78200800, 0xFFE00C00, .BASE, {}},                                   {read={0, 1}, writes_mem=true}},
	},
	.LDRSH = {
		{{.LDRSH,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x79800000, 0xFFC00000, .BASE, {is_64=true}},                          {written={0}, read={1}, reads_mem=true}},
		{{.LDRSH,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x79C00000, 0xFFC00000, .BASE, {}},                                    {written={0}, read={1}, reads_mem=true}},
		{{.LDRSH,          {.W_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,      .NONE, .NONE}, 0x78E00800, 0xFFE00C00, .BASE, {}},                                    {written={0}, read={1}, reads_mem=true}},
		{{.LDRSH,          {.X_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,      .NONE, .NONE}, 0x78A00800, 0xFFE00C00, .BASE, {is_64=true}},                          {written={0}, read={1}, reads_mem=true}},
	},
	.LDRSW = {
		{{.LDRSW,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xB9800000, 0xFFC00000, .BASE, {is_64=true}},                          {written={0}, read={1}, reads_mem=true}},
		{{.LDRSW,          {.X_REG, .MEM_REG,    .NONE, .NONE}, {.RT, .OFFSET_REG,      .NONE, .NONE}, 0xB8A00800, 0xFFE00C00, .BASE, {is_64=true}},                          {written={0}, read={1}, reads_mem=true}},
	},
	.LDP = {
		{{.LDP,            {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_4,  .NONE}, 0x29400000, 0xFFC00000, .BASE, {}},                                     {written={0, 1}, read={2}, reads_mem=true}},
		{{.LDP,            {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_8,  .NONE}, 0xA9400000, 0xFFC00000, .BASE, {is_64=true}},                           {written={0, 1}, read={2}, reads_mem=true}},
		{{.LDP,            {.W_REG, .W_REG, .MEM_PRE,    .NONE}, {.RT, .RT2, .OFFSET_PAIR_4,  .NONE}, 0x29C00000, 0xFFC00000, .BASE, {}},                                     {written={0, 1, 2}, read={2}, reads_mem=true}},
		{{.LDP,            {.X_REG, .X_REG, .MEM_PRE,    .NONE}, {.RT, .RT2, .OFFSET_PAIR_8,  .NONE}, 0xA9C00000, 0xFFC00000, .BASE, {is_64=true}},                           {written={0, 1, 2}, read={2}, reads_mem=true}},
		{{.LDP,            {.W_REG, .W_REG, .MEM_POST,   .NONE}, {.RT, .RT2, .OFFSET_PAIR_4,  .NONE}, 0x28C00000, 0xFFC00000, .BASE, {}},                                     {written={0, 1, 2}, read={2}, reads_mem=true}},
		{{.LDP,            {.X_REG, .X_REG, .MEM_POST,   .NONE}, {.RT, .RT2, .OFFSET_PAIR_8,  .NONE}, 0xA8C00000, 0xFFC00000, .BASE, {is_64=true}},                           {written={0, 1, 2}, read={2}, reads_mem=true}},
		{{.LDP,            {.S_REG, .S_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_4,  .NONE}, 0x2D400000, 0xFFC00000, .NEON, {}},                                     {written={0, 1}, read={2}, reads_mem=true}},
		{{.LDP,            {.D_REG, .D_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_8,  .NONE}, 0x6D400000, 0xFFC00000, .NEON, {}},                                     {written={0, 1}, read={2}, reads_mem=true}},
		{{.LDP,            {.Q_REG, .Q_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_16, .NONE}, 0xAD400000, 0xFFC00000, .NEON, {}},                                     {written={0, 1}, read={2}, reads_mem=true}},
	},
	.STP = {
		{{.STP,            {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_4,  .NONE}, 0x29000000, 0xFFC00000, .BASE, {}},                                     {read={0, 1, 2}, writes_mem=true}},
		{{.STP,            {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_8,  .NONE}, 0xA9000000, 0xFFC00000, .BASE, {is_64=true}},                           {read={0, 1, 2}, writes_mem=true}},
		{{.STP,            {.W_REG, .W_REG, .MEM_PRE,    .NONE}, {.RT, .RT2, .OFFSET_PAIR_4,  .NONE}, 0x29800000, 0xFFC00000, .BASE, {}},                                     {written={2}, read={0, 1, 2}, writes_mem=true}},
		{{.STP,            {.X_REG, .X_REG, .MEM_PRE,    .NONE}, {.RT, .RT2, .OFFSET_PAIR_8,  .NONE}, 0xA9800000, 0xFFC00000, .BASE, {is_64=true}},                           {written={2}, read={0, 1, 2}, writes_mem=true}},
		{{.STP,            {.W_REG, .W_REG, .MEM_POST,   .NONE}, {.RT, .RT2, .OFFSET_PAIR_4,  .NONE}, 0x28800000, 0xFFC00000, .BASE, {}},                                     {written={2}, read={0, 1, 2}, writes_mem=true}},
		{{.STP,            {.X_REG, .X_REG, .MEM_POST,   .NONE}, {.RT, .RT2, .OFFSET_PAIR_8,  .NONE}, 0xA8800000, 0xFFC00000, .BASE, {is_64=true}},                           {written={2}, read={0, 1, 2}, writes_mem=true}},
		{{.STP,            {.S_REG, .S_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_4,  .NONE}, 0x2D000000, 0xFFC00000, .NEON, {}},                                     {read={0, 1, 2}, writes_mem=true}},
		{{.STP,            {.D_REG, .D_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_8,  .NONE}, 0x6D000000, 0xFFC00000, .NEON, {}},                                     {read={0, 1, 2}, writes_mem=true}},
		{{.STP,            {.Q_REG, .Q_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_16, .NONE}, 0xAD000000, 0xFFC00000, .NEON, {}},                                     {read={0, 1, 2}, writes_mem=true}},
	},
	.LDPSW = {
		{{.LDPSW,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_4, .NONE}, 0x69400000, 0xFFC00000, .BASE, {is_64=true}},                            {written={0, 1}, read={2}, reads_mem=true}},
		{{.LDPSW,          {.X_REG, .X_REG, .MEM_PRE,    .NONE}, {.RT, .RT2, .OFFSET_PAIR_4, .NONE}, 0x69C00000, 0xFFC00000, .BASE, {is_64=true}},                            {written={0, 1, 2}, read={2}, reads_mem=true}},
		{{.LDPSW,          {.X_REG, .X_REG, .MEM_POST,   .NONE}, {.RT, .RT2, .OFFSET_PAIR_4, .NONE}, 0x68C00000, 0xFFC00000, .BASE, {is_64=true}},                            {written={0, 1, 2}, read={2}, reads_mem=true}},
	},
	.LDAR = {
		{{.LDAR,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x88DFFC00, 0xFFFFFC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
		{{.LDAR,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xC8DFFC00, 0xFFFFFC00, .BASE, {is_64=true}},                            {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.STLR = {
		{{.STLR,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x889FFC00, 0xFFFFFC00, .BASE, {}},                                      {read={0, 1}, writes_mem=true, side_effects={.FENCE}}},
		{{.STLR,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xC89FFC00, 0xFFFFFC00, .BASE, {is_64=true}},                            {read={0, 1}, writes_mem=true, side_effects={.FENCE}}},
	},
	.LDARB = {
		{{.LDARB,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x08DFFC00, 0xFFFFFC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.STLRB = {
		{{.STLRB,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x089FFC00, 0xFFFFFC00, .BASE, {}},                                      {read={0, 1}, writes_mem=true, side_effects={.FENCE}}},
	},
	.LDARH = {
		{{.LDARH,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x48DFFC00, 0xFFFFFC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.STLRH = {
		{{.STLRH,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x489FFC00, 0xFFFFFC00, .BASE, {}},                                      {read={0, 1}, writes_mem=true, side_effects={.FENCE}}},
	},
	.LDXR = {
		{{.LDXR,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x885F7C00, 0xFFE0FC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
		{{.LDXR,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xC85F7C00, 0xFFE0FC00, .BASE, {is_64=true}},                            {written={0}, read={1}, reads_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.STXR = {
		{{.STXR,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0x88007C00, 0xFFE0FC00, .BASE, {}},                                       {written={0}, read={1, 2}, writes_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
		{{.STXR,           {.W_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0xC8007C00, 0xFFE0FC00, .BASE, {is_64=true}},                             {written={0}, read={1, 2}, writes_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.LDAXR = {
		{{.LDAXR,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x885FFC00, 0xFFE0FC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
		{{.LDAXR,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xC85FFC00, 0xFFE0FC00, .BASE, {is_64=true}},                            {written={0}, read={1}, reads_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
	},
	.STLXR = {
		{{.STLXR,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0x8800FC00, 0xFFE0FC00, .BASE, {}},                                       {written={0}, read={1, 2}, writes_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
		{{.STLXR,          {.W_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0xC800FC00, 0xFFE0FC00, .BASE, {is_64=true}},                             {written={0}, read={1, 2}, writes_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
	},
	.NOP = {
		{{.NOP,            {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503201F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.HINT}}},
	},
	.YIELD = {
		{{.YIELD,          {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503203F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.HINT}}},
	},
	.WFE = {
		{{.WFE,            {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503205F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.WAIT}}},
	},
	.WFI = {
		{{.WFI,            {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503207F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.WAIT}}},
	},
	.SEV = {
		{{.SEV,            {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503209F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.HINT}}},
	},
	.SEVL = {
		{{.SEVL,           {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50320BF, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.HINT}}},
	},
	.HINT = {
		{{.HINT,           {.IMM_8, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE}, 0xD503201F, 0xFFFFF01F, .BASE, {}},                                             {side_effects={.HINT}}},
	},
	.MRS = {
		{{.MRS,            {.X_REG, .SYS_REG, .NONE, .NONE}, {.RT, .SYS_FIELD, .NONE, .NONE}, 0xD5300000, 0xFFF00000, .BASE, {}},                                             {written={0}, read={1}, side_effects={.PRIVILEGED}}},
	},
	.MSR = {
		{{.MSR,            {.SYS_REG, .IMM_4, .NONE, .NONE}, {.MSR_PSTATE, .BARRIER_FIELD, .NONE, .NONE}, 0xD500401F, 0xFFF8F01F, .BASE, {}},                                 {side_effects={.PRIVILEGED}}},
		{{.MSR,            {.SYS_REG, .X_REG, .NONE, .NONE}, {.SYS_FIELD,  .RT,            .NONE, .NONE}, 0xD5100000, 0xFFF00000, .BASE, {}},                                 {written={0}, read={1}, side_effects={.PRIVILEGED}}},
	},
	.ISB = {
		{{.ISB,            {.IMM_4, .NONE, .NONE, .NONE}, {.BARRIER_FIELD, .NONE, .NONE, .NONE}, 0xD50330DF, 0xFFFFF0FF, .BASE, {}},                                          {side_effects={.ISYNC}}},
	},
	.DSB = {
		{{.DSB,            {.IMM_4, .NONE, .NONE, .NONE}, {.BARRIER_FIELD, .NONE, .NONE, .NONE}, 0xD503309F, 0xFFFFF0FF, .BASE, {}},                                          {side_effects={.FENCE}}},
	},
	.DMB = {
		{{.DMB,            {.IMM_4, .NONE, .NONE, .NONE}, {.BARRIER_FIELD, .NONE, .NONE, .NONE}, 0xD50330BF, 0xFFFFF0FF, .BASE, {}},                                          {side_effects={.FENCE}}},
	},
	.SVC = {
		{{.SVC,            {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4000001, 0xFFE0001F, .BASE, {branch=true}},                                      {side_effects={.CONTROL, .EXCEPTION}}},
	},
	.HVC = {
		{{.HVC,            {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4000002, 0xFFE0001F, .BASE, {branch=true}},                                      {side_effects={.CONTROL, .EXCEPTION, .PRIVILEGED}}},
	},
	.SMC = {
		{{.SMC,            {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4000003, 0xFFE0001F, .BASE, {branch=true}},                                      {side_effects={.CONTROL, .EXCEPTION, .PRIVILEGED}}},
	},
	.BRK = {
		{{.BRK,            {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4200000, 0xFFE0001F, .BASE, {branch=true}},                                      {side_effects={.CONTROL, .TRAP}}},
	},
	.HLT = {
		{{.HLT,            {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4400000, 0xFFE0001F, .BASE, {branch=true}},                                      {side_effects={.CONTROL, .TRAP}}},
	},
	.ERET = {
		{{.ERET,           {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD69F03E0, 0xFFFFFFFF, .BASE, {branch=true, writes_pc=true}},                         {side_effects={.CONTROL, .PRIVILEGED}}},
	},
	.FMOV = {
		{{.FMOV,           {.S_REG,     .S_REG, .NONE, .NONE}, {.RD, .RN,              .NONE, .NONE}, 0x1E204000, 0xFFFFFC00, .FP,   {}},                                     {written={0}, read={1}}},
		{{.FMOV,           {.D_REG,     .D_REG, .NONE, .NONE}, {.RD, .RN,              .NONE, .NONE}, 0x1E604000, 0xFFFFFC00, .FP,   {}},                                     {written={0}, read={1}}},
		{{.FMOV,           {.S_REG,     .IMM_8, .NONE, .NONE}, {.RD, .FMOV_SCALAR_IMM, .NONE, .NONE}, 0x1E201000, 0xFFE01FE0, .FP,   {}},                                     {written={0}}},
		{{.FMOV,           {.D_REG,     .IMM_8, .NONE, .NONE}, {.RD, .FMOV_SCALAR_IMM, .NONE, .NONE}, 0x1E601000, 0xFFE01FE0, .FP,   {}},                                     {written={0}}},
		{{.FMOV,           {.H_REG,     .IMM_8, .NONE, .NONE}, {.RD, .FMOV_SCALAR_IMM, .NONE, .NONE}, 0x1EE01000, 0xFFE01FE0, .FP16, {}},                                     {written={0}}},
		{{.FMOV,           {.W_REG,     .S_REG, .NONE, .NONE}, {.RD, .RN,              .NONE, .NONE}, 0x1E260000, 0xFFFFFC00, .FP,   {}},                                     {written={0}, read={1}}},
		{{.FMOV,           {.S_REG,     .W_REG, .NONE, .NONE}, {.RD, .RN,              .NONE, .NONE}, 0x1E270000, 0xFFFFFC00, .FP,   {}},                                     {written={0}, read={1}}},
		{{.FMOV,           {.X_REG,     .D_REG, .NONE, .NONE}, {.RD, .RN,              .NONE, .NONE}, 0x9E660000, 0xFFFFFC00, .FP,   {is_64=true}},                           {written={0}, read={1}}},
		{{.FMOV,           {.D_REG,     .X_REG, .NONE, .NONE}, {.RD, .RN,              .NONE, .NONE}, 0x9E670000, 0xFFFFFC00, .FP,   {is_64=true}},                           {written={0}, read={1}}},
		{{.FMOV,           {.H_REG,     .H_REG, .NONE, .NONE}, {.RD, .RN,              .NONE, .NONE}, 0x1EE04000, 0xFFFFFC00, .FP16, {}},                                     {written={0}, read={1}}},
		{{.FMOV,           {.V_2S,      .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV,  .NONE, .NONE}, 0x0F00F400, 0xFFF8FC00, .NEON, {}},                                     {written={0}}},
		{{.FMOV,           {.V_4S,      .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV,  .NONE, .NONE}, 0x4F00F400, 0xFFF8FC00, .NEON, {}},                                     {written={0}}},
		{{.FMOV,           {.V_2D,      .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV,  .NONE, .NONE}, 0x6F00F400, 0xFFF8FC00, .NEON, {}},                                     {written={0}}},
		{{.FMOV,           {.V_4H_FP16, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV,  .NONE, .NONE}, 0x0F00FC00, 0xFFF8FC00, .FP16, {}},                                     {written={0}}},
		{{.FMOV,           {.V_8H_FP16, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV,  .NONE, .NONE}, 0x4F00FC00, 0xFFF8FC00, .FP16, {}},                                     {written={0}}},
	},
	.FABS = {
		{{.FABS,           {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E20C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}}},
		{{.FABS,           {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E60C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}}},
		{{.FABS,           {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE0C000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}}},
		{{.FABS,           {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA0F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.FABS,           {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA0F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.FABS,           {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE0F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.FABS,           {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF8F800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}}},
		{{.FABS,           {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF8F800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}}},
		{{.FABS,           {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x045CA000, 0xFFE0E000, .SVE,  {}},                                         {written={0}, read={1, 2}}},
		{{.FABS,           {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x049CA000, 0xFFE0E000, .SVE,  {}},                                         {written={0}, read={1, 2}}},
		{{.FABS,           {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x04DCA000, 0xFFE0E000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}}},
	},
	.FNEG = {
		{{.FNEG,           {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E214000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}}},
		{{.FNEG,           {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E614000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}}},
		{{.FNEG,           {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE14000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}}},
		{{.FNEG,           {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA0F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.FNEG,           {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA0F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.FNEG,           {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE0F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.FNEG,           {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF8F800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}}},
		{{.FNEG,           {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF8F800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}}},
		{{.FNEG,           {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x045DA000, 0xFFE0E000, .SVE,  {}},                                         {written={0}, read={1, 2}}},
		{{.FNEG,           {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x049DA000, 0xFFE0E000, .SVE,  {}},                                         {written={0}, read={1, 2}}},
		{{.FNEG,           {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x04DDA000, 0xFFE0E000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}}},
	},
	.FSQRT = {
		{{.FSQRT,          {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E21C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E61C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE1C000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE1F800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF9F800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF9F800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x654DA000, 0xFFE0E000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x658DA000, 0xFFE0E000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSQRT,          {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65CDA000, 0xFFE0E000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}, fpsr_wr={.IOC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FADD = {
		{{.FADD,           {.S_REG,   .S_REG,       .S_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E202800, 0xFFE0FC00, .FP,   {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.D_REG,   .D_REG,       .D_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E602800, 0xFFE0FC00, .FP,   {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.H_REG,   .H_REG,       .H_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1EE02800, 0xFFE0FC00, .FP16, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E20D400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E20D400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.V_2D,    .V_2D,        .V_2D,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E60D400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.Z_REG_H, .Z_REG_H,     .Z_REG_H, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65400000, 0xFFE0FC00, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.Z_REG_S, .Z_REG_S,     .Z_REG_S, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65800000, 0xFFE0FC00, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.Z_REG_D, .Z_REG_D,     .Z_REG_D, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65C00000, 0xFFE0FC00, .SVE,  {is_64=true}},                                {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65408000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x65808000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADD,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x65C08000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FSUB = {
		{{.FSUB,           {.S_REG,   .S_REG,       .S_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E203800, 0xFFE0FC00, .FP,   {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.D_REG,   .D_REG,       .D_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E603800, 0xFFE0FC00, .FP,   {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.H_REG,   .H_REG,       .H_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1EE03800, 0xFFE0FC00, .FP16, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0EA0D400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EA0D400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.V_2D,    .V_2D,        .V_2D,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EE0D400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.Z_REG_H, .Z_REG_H,     .Z_REG_H, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65400400, 0xFFE0FC00, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.Z_REG_S, .Z_REG_S,     .Z_REG_S, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65800400, 0xFFE0FC00, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.Z_REG_D, .Z_REG_D,     .Z_REG_D, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65C00400, 0xFFE0FC00, .SVE,  {is_64=true}},                                {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65418000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x65818000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUB,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x65C18000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FMUL = {
		{{.FMUL,           {.S_REG,   .S_REG,       .S_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E200800, 0xFFE0FC00, .FP,   {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.D_REG,   .D_REG,       .D_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E600800, 0xFFE0FC00, .FP,   {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.H_REG,   .H_REG,       .H_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1EE00800, 0xFFE0FC00, .FP16, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E20DC00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E20DC00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.V_2D,    .V_2D,        .V_2D,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E60DC00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.Z_REG_H, .Z_REG_H,     .Z_REG_H, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65400800, 0xFFE0FC00, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.Z_REG_S, .Z_REG_S,     .Z_REG_S, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65800800, 0xFFE0FC00, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.Z_REG_D, .Z_REG_D,     .Z_REG_D, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65C00800, 0xFFE0FC00, .SVE,  {is_64=true}},                                {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65428000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x65828000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMUL,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x65C28000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FDIV = {
		{{.FDIV,           {.S_REG,   .S_REG,       .S_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E201800, 0xFFE0FC00, .FP,   {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIV,           {.D_REG,   .D_REG,       .D_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E601800, 0xFFE0FC00, .FP,   {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIV,           {.H_REG,   .H_REG,       .H_REG,   .NONE},    {.RD, .RN, .RM, .NONE}, 0x1EE01800, 0xFFE0FC00, .FP16, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIV,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E20FC00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIV,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E20FC00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIV,           {.V_2D,    .V_2D,        .V_2D,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E60FC00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIV,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x654D8000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIV,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x658D8000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIV,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x65CD8000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FNMUL = {
		{{.FNMUL,          {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E208800, 0xFFE0FC00, .FP,   {}},                                                       {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FNMUL,          {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E608800, 0xFFE0FC00, .FP,   {}},                                                       {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FNMUL,          {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE08800, 0xFFE0FC00, .FP16, {}},                                                       {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FMADD = {
		{{.FMADD,          {.S_REG, .S_REG, .S_REG, .S_REG}, {.RD, .RN, .RM, .RA}, 0x1F000000, 0xFFE08000, .FP,   {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMADD,          {.D_REG, .D_REG, .D_REG, .D_REG}, {.RD, .RN, .RM, .RA}, 0x1F400000, 0xFFE08000, .FP,   {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMADD,          {.H_REG, .H_REG, .H_REG, .H_REG}, {.RD, .RN, .RM, .RA}, 0x1FC00000, 0xFFE08000, .FP16, {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FMSUB = {
		{{.FMSUB,          {.S_REG, .S_REG, .S_REG, .S_REG}, {.RD, .RN, .RM, .RA}, 0x1F008000, 0xFFE08000, .FP,   {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMSUB,          {.D_REG, .D_REG, .D_REG, .D_REG}, {.RD, .RN, .RM, .RA}, 0x1F408000, 0xFFE08000, .FP,   {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMSUB,          {.H_REG, .H_REG, .H_REG, .H_REG}, {.RD, .RN, .RM, .RA}, 0x1FC08000, 0xFFE08000, .FP16, {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FNMADD = {
		{{.FNMADD,         {.S_REG, .S_REG, .S_REG, .S_REG}, {.RD, .RN, .RM, .RA}, 0x1F200000, 0xFFE08000, .FP,   {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FNMADD,         {.D_REG, .D_REG, .D_REG, .D_REG}, {.RD, .RN, .RM, .RA}, 0x1F600000, 0xFFE08000, .FP,   {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FNMADD,         {.H_REG, .H_REG, .H_REG, .H_REG}, {.RD, .RN, .RM, .RA}, 0x1FE00000, 0xFFE08000, .FP16, {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FNMSUB = {
		{{.FNMSUB,         {.S_REG, .S_REG, .S_REG, .S_REG}, {.RD, .RN, .RM, .RA}, 0x1F208000, 0xFFE08000, .FP,   {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FNMSUB,         {.D_REG, .D_REG, .D_REG, .D_REG}, {.RD, .RN, .RM, .RA}, 0x1F608000, 0xFFE08000, .FP,   {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FNMSUB,         {.H_REG, .H_REG, .H_REG, .H_REG}, {.RD, .RN, .RM, .RA}, 0x1FE08000, 0xFFE08000, .FP16, {}},                                                        {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FCMP = {
		{{.FCMP,           {.S_REG, .S_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1E202000, 0xFFE0FC1F, .FP,   {sets_flags=true}},                                       {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, fpsr_wr={.IOC}}},
		{{.FCMP,           {.D_REG, .D_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1E602000, 0xFFE0FC1F, .FP,   {sets_flags=true}},                                       {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, fpsr_wr={.IOC}}},
		{{.FCMP,           {.H_REG, .H_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1EE02000, 0xFFE0FC1F, .FP16, {sets_flags=true}},                                       {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, fpsr_wr={.IOC}}},
	},
	.FCMPE = {
		{{.FCMPE,          {.S_REG, .S_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1E202010, 0xFFE0FC1F, .FP,   {sets_flags=true}},                                       {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, fpsr_wr={.IOC}}},
		{{.FCMPE,          {.D_REG, .D_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1E602010, 0xFFE0FC1F, .FP,   {sets_flags=true}},                                       {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, fpsr_wr={.IOC}}},
		{{.FCMPE,          {.H_REG, .H_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1EE02010, 0xFFE0FC1F, .FP16, {sets_flags=true}},                                       {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}, fpsr_wr={.IOC}}},
	},
	.FCSEL = {
		{{.FCSEL,          {.S_REG, .S_REG, .S_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1E200C00, 0xFFE00C00, .FP,   {}},                                                    {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.FCSEL,          {.D_REG, .D_REG, .D_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1E600C00, 0xFFE00C00, .FP,   {}},                                                    {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
		{{.FCSEL,          {.H_REG, .H_REG, .H_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1EE00C00, 0xFFE00C00, .FP16, {}},                                                    {written={0}, read={1, 2}, nzcv_rd={.N, .Z, .C, .V}}},
	},
	.FMAX = {
		{{.FMAX,           {.S_REG,     .S_REG,       .S_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E204800, 0xFFE0FC00, .FP,   {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.D_REG,     .D_REG,       .D_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E604800, 0xFFE0FC00, .FP,   {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.H_REG,     .H_REG,       .H_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1EE04800, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.V_2S,      .V_2S,        .V_2S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E20F400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.V_4S,      .V_4S,        .V_4S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E20F400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.V_2D,      .V_2D,        .V_2D,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E60F400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.V_4H_FP16, .V_4H_FP16,   .V_4H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E403400, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.V_8H_FP16, .V_8H_FP16,   .V_8H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E403400, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H,   .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65468000, 0xFFE0E000, .SVE,  {}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S,   .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x65868000, 0xFFE0E000, .SVE,  {}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAX,           {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D,   .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x65C68000, 0xFFE0E000, .SVE,  {is_64=true}},                            {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMIN = {
		{{.FMIN,           {.S_REG,     .S_REG,       .S_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E205800, 0xFFE0FC00, .FP,   {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.D_REG,     .D_REG,       .D_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E605800, 0xFFE0FC00, .FP,   {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.H_REG,     .H_REG,       .H_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1EE05800, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.V_2S,      .V_2S,        .V_2S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x0EA0F400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.V_4S,      .V_4S,        .V_4S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EA0F400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.V_2D,      .V_2D,        .V_2D,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EE0F400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.V_4H_FP16, .V_4H_FP16,   .V_4H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x0EC03400, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.V_8H_FP16, .V_8H_FP16,   .V_8H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EC03400, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H,   .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65478000, 0xFFE0E000, .SVE,  {}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S,   .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x65878000, 0xFFE0E000, .SVE,  {}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMIN,           {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D,   .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x65C78000, 0xFFE0E000, .SVE,  {is_64=true}},                            {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMAXNM = {
		{{.FMAXNM,         {.S_REG,     .S_REG,       .S_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E206800, 0xFFE0FC00, .FP,   {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.D_REG,     .D_REG,       .D_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E606800, 0xFFE0FC00, .FP,   {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.H_REG,     .H_REG,       .H_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1EE06800, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.V_2S,      .V_2S,        .V_2S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E20C400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.V_4S,      .V_4S,        .V_4S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E20C400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.V_2D,      .V_2D,        .V_2D,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E60C400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.V_4H_FP16, .V_4H_FP16,   .V_4H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E400400, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.V_8H_FP16, .V_8H_FP16,   .V_8H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E400400, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H,   .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65448000, 0xFFE0E000, .SVE,  {}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S,   .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x65848000, 0xFFE0E000, .SVE,  {}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNM,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D,   .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x65C48000, 0xFFE0E000, .SVE,  {is_64=true}},                            {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMINNM = {
		{{.FMINNM,         {.S_REG,     .S_REG,       .S_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E207800, 0xFFE0FC00, .FP,   {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.D_REG,     .D_REG,       .D_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1E607800, 0xFFE0FC00, .FP,   {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.H_REG,     .H_REG,       .H_REG,     .NONE},    {.RD, .RN, .RM, .NONE}, 0x1EE07800, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.V_2S,      .V_2S,        .V_2S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x0EA0C400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.V_4S,      .V_4S,        .V_4S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EA0C400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.V_2D,      .V_2D,        .V_2D,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EE0C400, 0xFFE0FC00, .NEON, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.V_4H_FP16, .V_4H_FP16,   .V_4H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x0EC00400, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.V_8H_FP16, .V_8H_FP16,   .V_8H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EC00400, 0xFFE0FC00, .FP16, {}},                                      {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H,   .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65458000, 0xFFE0E000, .SVE,  {}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S,   .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x65858000, 0xFFE0E000, .SVE,  {}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNM,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D,   .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x65C58000, 0xFFE0E000, .SVE,  {is_64=true}},                            {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FCVT = {
		{{.FCVT,           {.D_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E22C000, 0xFFFFFC00, .FP,   {}},                                                      {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVT,           {.S_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E624000, 0xFFFFFC00, .FP,   {}},                                                      {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVT,           {.H_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E23C000, 0xFFFFFC00, .FP16, {}},                                                      {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVT,           {.H_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E63C000, 0xFFFFFC00, .FP16, {}},                                                      {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVT,           {.S_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE24000, 0xFFFFFC00, .FP16, {}},                                                      {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVT,           {.D_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE2C000, 0xFFFFFC00, .FP16, {}},                                                      {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.SCVTF = {
		{{.SCVTF,          {.S_REG,     .W_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E220000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.D_REG,     .W_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E620000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.S_REG,     .X_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E220000, 0xFFFFFC00, .FP,   {is_64=true}},                                    {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.D_REG,     .X_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E620000, 0xFFFFFC00, .FP,   {is_64=true}},                                    {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.H_REG,     .W_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE20000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E21D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E21D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E61D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E79D800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.SCVTF,          {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E79D800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
	},
	.UCVTF = {
		{{.UCVTF,          {.S_REG,     .W_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E230000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.D_REG,     .W_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E630000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.S_REG,     .X_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E230000, 0xFFFFFC00, .FP,   {is_64=true}},                                    {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.D_REG,     .X_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E630000, 0xFFFFFC00, .FP,   {is_64=true}},                                    {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.H_REG,     .W_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE30000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E21D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E21D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E61D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E79D800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
		{{.UCVTF,          {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E79D800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IXC}, reads_fpcr=true}},
	},
	.FCVTZS = {
		{{.FCVTZS,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E380000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E780000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E380000, 0xFFFFFC00, .FP,   {is_64=true}},                                    {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E780000, 0xFFFFFC00, .FP,   {is_64=true}},                                    {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EF80000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA1B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA1B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE1B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF9B800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZS,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF9B800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTZU = {
		{{.FCVTZU,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E390000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E790000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E390000, 0xFFFFFC00, .FP,   {is_64=true}},                                    {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E790000, 0xFFFFFC00, .FP,   {is_64=true}},                                    {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EF90000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE1B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF9B800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTZU,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF9B800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTAS = {
		{{.FCVTAS,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E240000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E640000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE40000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E240000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E640000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.X_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE40000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E21C800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E21C800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E61C800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E79C800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAS,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E79C800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTAU = {
		{{.FCVTAU,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E250000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E650000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE50000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E250000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E650000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.X_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE50000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E21C800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E21C800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E61C800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E79C800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTAU,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E79C800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTNS = {
		{{.FCVTNS,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E200000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E600000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE00000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E200000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E600000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.X_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE00000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E21A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E21A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E61A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E79A800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNS,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E79A800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTNU = {
		{{.FCVTNU,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E210000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E610000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE10000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E210000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E610000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.X_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE10000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E21A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E21A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E61A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E79A800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTNU,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E79A800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTPS = {
		{{.FCVTPS,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E280000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E680000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE80000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E280000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E680000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.X_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE80000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA1A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA1A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE1A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF9A800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPS,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF9A800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTPU = {
		{{.FCVTPU,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E290000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E690000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE90000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E290000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E690000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.X_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE90000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE1A800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF9A800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTPU,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF9A800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTMS = {
		{{.FCVTMS,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E300000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E700000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EF00000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E300000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E700000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.X_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EF00000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E21B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E21B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E61B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E79B800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMS,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E79B800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTMU = {
		{{.FCVTMU,         {.W_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E310000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.W_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E710000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.W_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EF10000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.X_REG,     .S_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E310000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.X_REG,     .D_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E710000, 0xFFFFFC00, .FP,   {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.X_REG,     .H_REG,     .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EF10000, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E21B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E21B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E61B800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E79B800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
		{{.FCVTMU,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E79B800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FRINTA = {
		{{.FRINTA,         {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E264000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E664000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE64000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E218800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E218800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E618800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E798800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E798800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6544A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6584A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTA,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65C4A000, 0xFFFFE000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.FRINTI = {
		{{.FRINTI,         {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E27C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E67C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE7C000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA19800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA19800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE19800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF99800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF99800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6547A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6587A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}, reads_fpcr=true}},
		{{.FRINTI,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65C7A000, 0xFFFFE000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}, fpsr_wr={.IOC}, reads_fpcr=true}},
	},
	.FRINTM = {
		{{.FRINTM,         {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E254000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E654000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE54000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E219800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E219800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E619800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E799800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E799800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6542A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6582A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTM,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65C2A000, 0xFFFFE000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.FRINTN = {
		{{.FRINTN,         {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E244000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E644000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE44000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E218800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E218800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E618800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E798800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E798800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6540A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6580A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTN,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65C0A000, 0xFFFFE000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.FRINTP = {
		{{.FRINTP,         {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E24C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E64C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE4C000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA18800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA18800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE18800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF98800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF98800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6541A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6581A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTP,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65C1A000, 0xFFFFE000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.FRINTX = {
		{{.FRINTX,         {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E274000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E674000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE74000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E219800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E219800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E619800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E799800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E799800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6546A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6586A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
		{{.FRINTX,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65C6A000, 0xFFFFE000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}, fpsr_wr={.IOC, .IXC}, reads_fpcr=true}},
	},
	.FRINTZ = {
		{{.FRINTZ,         {.S_REG,     .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E25C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.D_REG,     .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E65C000, 0xFFFFFC00, .FP,   {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.H_REG,     .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE5C000, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.V_2S,      .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA19800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.V_4S,      .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA19800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.V_2D,      .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE19800, 0xFFFFFC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.V_4H_FP16, .V_4H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF99800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.V_8H_FP16, .V_8H_FP16,   .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF99800, 0xFFFFFC00, .FP16, {}},                                         {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.Z_REG_H,   .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6543A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.Z_REG_S,   .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x6583A000, 0xFFFFE000, .SVE,  {}},                                         {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FRINTZ,         {.Z_REG_D,   .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65C3A000, 0xFFFFE000, .SVE,  {is_64=true}},                               {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.TST = {
		{{.TST,            {.W_REG, .BITMASK_IMM, .NONE, .NONE}, {.RN, .BITMASK_FIELD, .NONE, .NONE}, 0x7200001F, 0xFFC0001F, .BASE, {sets_flags=true}},                      {read={0}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.TST,            {.X_REG, .BITMASK_IMM, .NONE, .NONE}, {.RN, .BITMASK_FIELD, .NONE, .NONE}, 0xF200001F, 0xFF80001F, .BASE, {sets_flags=true, is_64=true}},          {read={0}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.TST,            {.W_REG, .W_SHIFTED,   .NONE, .NONE}, {.RN, .RM,            .NONE, .NONE}, 0x6A00001F, 0xFF20001F, .BASE, {sets_flags=true}},                      {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.TST,            {.X_REG, .X_SHIFTED,   .NONE, .NONE}, {.RN, .RM,            .NONE, .NONE}, 0xEA00001F, 0xFF20001F, .BASE, {sets_flags=true, is_64=true}},          {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.LDUR = {
		{{.LDUR,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xB8400000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true}},
		{{.LDUR,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xF8400000, 0xFFE00C00, .BASE, {is_64=true}},                           {written={0}, read={1}, reads_mem=true}},
		{{.LDUR,           {.S_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xBC400000, 0xFFE00C00, .NEON, {}},                                     {written={0}, read={1}, reads_mem=true}},
		{{.LDUR,           {.D_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xFC400000, 0xFFE00C00, .NEON, {}},                                     {written={0}, read={1}, reads_mem=true}},
		{{.LDUR,           {.Q_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x3CC00000, 0xFFE00C00, .NEON, {}},                                     {written={0}, read={1}, reads_mem=true}},
	},
	.STUR = {
		{{.STUR,           {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xB8000000, 0xFFE00C00, .BASE, {}},                                     {read={0, 1}, writes_mem=true}},
		{{.STUR,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xF8000000, 0xFFE00C00, .BASE, {is_64=true}},                           {read={0, 1}, writes_mem=true}},
		{{.STUR,           {.S_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xBC000000, 0xFFE00C00, .NEON, {}},                                     {read={0, 1}, writes_mem=true}},
		{{.STUR,           {.D_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xFC000000, 0xFFE00C00, .NEON, {}},                                     {read={0, 1}, writes_mem=true}},
		{{.STUR,           {.Q_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x3C800000, 0xFFE00C00, .NEON, {}},                                     {read={0, 1}, writes_mem=true}},
	},
	.LDURB = {
		{{.LDURB,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x38400000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true}},
	},
	.STURB = {
		{{.STURB,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x38000000, 0xFFE00C00, .BASE, {}},                                     {read={0, 1}, writes_mem=true}},
	},
	.LDURSB = {
		{{.LDURSB,         {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x38800000, 0xFFE00C00, .BASE, {is_64=true}},                           {written={0}, read={1}, reads_mem=true}},
		{{.LDURSB,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x38C00000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true}},
	},
	.LDURH = {
		{{.LDURH,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x78400000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true}},
	},
	.STURH = {
		{{.STURH,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x78000000, 0xFFE00C00, .BASE, {}},                                     {read={0, 1}, writes_mem=true}},
	},
	.LDURSH = {
		{{.LDURSH,         {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x78800000, 0xFFE00C00, .BASE, {is_64=true}},                           {written={0}, read={1}, reads_mem=true}},
		{{.LDURSH,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x78C00000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true}},
	},
	.LDURSW = {
		{{.LDURSW,         {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xB8800000, 0xFFE00C00, .BASE, {is_64=true}},                           {written={0}, read={1}, reads_mem=true}},
	},
	.LDNP = {
		{{.LDNP,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_4, .NONE}, 0x28400000, 0xFFC00000, .BASE, {}},                                      {written={0, 1}, read={2}, reads_mem=true}},
		{{.LDNP,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_8, .NONE}, 0xA8400000, 0xFFC00000, .BASE, {is_64=true}},                            {written={0, 1}, read={2}, reads_mem=true}},
	},
	.STNP = {
		{{.STNP,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_4, .NONE}, 0x28000000, 0xFFC00000, .BASE, {}},                                      {read={0, 1, 2}, writes_mem=true}},
		{{.STNP,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_8, .NONE}, 0xA8000000, 0xFFC00000, .BASE, {is_64=true}},                            {read={0, 1, 2}, writes_mem=true}},
	},
	.LDXP = {
		{{.LDXP,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_BASE_A, .NONE}, 0x887F0000, 0xFFFF8000, .BASE, {}},                                      {written={0, 1}, read={2}, reads_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
		{{.LDXP,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_BASE_A, .NONE}, 0xC87F0000, 0xFFFF8000, .BASE, {is_64=true}},                            {written={0, 1}, read={2}, reads_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.STXP = {
		{{.STXP,           {.W_REG, .W_REG, .W_REG, .MEM_OFFSET}, {.RD, .RT, .RT2, .OFFSET_BASE_A}, 0x88200000, 0xFFE08000, .BASE, {}},                                       {written={0}, read={1, 2, 3}, writes_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
		{{.STXP,           {.W_REG, .X_REG, .X_REG, .MEM_OFFSET}, {.RD, .RT, .RT2, .OFFSET_BASE_A}, 0xC8200000, 0xFFE08000, .BASE, {is_64=true}},                             {written={0}, read={1, 2, 3}, writes_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.LDAXP = {
		{{.LDAXP,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_BASE_A, .NONE}, 0x887F8000, 0xFFFF8000, .BASE, {}},                                      {written={0, 1}, read={2}, reads_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
		{{.LDAXP,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_BASE_A, .NONE}, 0xC87F8000, 0xFFFF8000, .BASE, {is_64=true}},                            {written={0, 1}, read={2}, reads_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
	},
	.STLXP = {
		{{.STLXP,          {.W_REG, .W_REG, .W_REG, .MEM_OFFSET}, {.RD, .RT, .RT2, .OFFSET_BASE_A}, 0x88208000, 0xFFE08000, .BASE, {}},                                       {written={0}, read={1, 2, 3}, writes_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
		{{.STLXP,          {.W_REG, .X_REG, .X_REG, .MEM_OFFSET}, {.RD, .RT, .RT2, .OFFSET_BASE_A}, 0xC8208000, 0xFFE08000, .BASE, {is_64=true}},                             {written={0}, read={1, 2, 3}, writes_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
	},
	.LDXRB = {
		{{.LDXRB,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x085F7C00, 0xFFE0FC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.STXRB = {
		{{.STXRB,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0x08007C00, 0xFFE0FC00, .BASE, {}},                                       {written={0}, read={1, 2}, writes_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.LDAXRB = {
		{{.LDAXRB,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x085FFC00, 0xFFE0FC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
	},
	.STLXRB = {
		{{.STLXRB,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0x0800FC00, 0xFFE0FC00, .BASE, {}},                                       {written={0}, read={1, 2}, writes_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
	},
	.LDXRH = {
		{{.LDXRH,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x485F7C00, 0xFFE0FC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.STXRH = {
		{{.STXRH,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0x48007C00, 0xFFE0FC00, .BASE, {}},                                       {written={0}, read={1, 2}, writes_mem=true, side_effects={.ATOMIC, .RESERVATION}}},
	},
	.LDAXRH = {
		{{.LDAXRH,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x485FFC00, 0xFFE0FC00, .BASE, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
	},
	.STLXRH = {
		{{.STLXRH,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0x4800FC00, 0xFFE0FC00, .BASE, {}},                                       {written={0}, read={1, 2}, writes_mem=true, side_effects={.FENCE, .ATOMIC, .RESERVATION}}},
	},
	.LDAPR = {
		{{.LDAPR,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xB8BFC000, 0xFFFFFC00, .LSE2, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
		{{.LDAPR,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xF8BFC000, 0xFFFFFC00, .LSE2, {is_64=true}},                            {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.LDAPRB = {
		{{.LDAPRB,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x38BFC000, 0xFFFFFC00, .LSE2, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.LDAPRH = {
		{{.LDAPRH,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x78BFC000, 0xFFFFFC00, .LSE2, {}},                                      {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.LDADD = {
		{{.LDADD,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8200000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.LDADD,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8200000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.LDADDA = {
		{{.LDADDA,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A00000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDADDA,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A00000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDADDL = {
		{{.LDADDL,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8600000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDADDL,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8600000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDADDAL = {
		{{.LDADDAL,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E00000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDADDAL,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E00000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDCLR = {
		{{.LDCLR,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8201000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.LDCLR,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8201000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.LDCLRA = {
		{{.LDCLRA,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A01000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDCLRA,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A01000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDCLRL = {
		{{.LDCLRL,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8601000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDCLRL,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8601000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDCLRAL = {
		{{.LDCLRAL,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E01000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDCLRAL,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E01000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDEOR = {
		{{.LDEOR,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8202000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.LDEOR,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8202000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.LDEORA = {
		{{.LDEORA,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A02000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDEORA,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A02000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDEORL = {
		{{.LDEORL,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8602000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDEORL,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8602000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDEORAL = {
		{{.LDEORAL,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E02000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDEORAL,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E02000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSET = {
		{{.LDSET,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8203000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.LDSET,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8203000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.LDSETA = {
		{{.LDSETA,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A03000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSETA,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A03000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSETL = {
		{{.LDSETL,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8603000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSETL,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8603000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSETAL = {
		{{.LDSETAL,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E03000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSETAL,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E03000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSMAX = {
		{{.LDSMAX,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8204000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.LDSMAX,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8204000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.LDSMAXA = {
		{{.LDSMAXA,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A04000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSMAXA,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A04000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSMAXL = {
		{{.LDSMAXL,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8604000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSMAXL,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8604000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSMAXAL = {
		{{.LDSMAXAL,       {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E04000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSMAXAL,       {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E04000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSMIN = {
		{{.LDSMIN,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8205000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.LDSMIN,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8205000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.LDSMINA = {
		{{.LDSMINA,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A05000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSMINA,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A05000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSMINL = {
		{{.LDSMINL,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8605000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSMINL,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8605000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDSMINAL = {
		{{.LDSMINAL,       {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E05000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDSMINAL,       {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E05000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDUMAX = {
		{{.LDUMAX,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8206000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.LDUMAX,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8206000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.LDUMAXA = {
		{{.LDUMAXA,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A06000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDUMAXA,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A06000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDUMAXL = {
		{{.LDUMAXL,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8606000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDUMAXL,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8606000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDUMAXAL = {
		{{.LDUMAXAL,       {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E06000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDUMAXAL,       {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E06000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDUMIN = {
		{{.LDUMIN,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8207000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.LDUMIN,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8207000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.LDUMINA = {
		{{.LDUMINA,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A07000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDUMINA,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A07000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDUMINL = {
		{{.LDUMINL,        {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8607000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDUMINL,        {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8607000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.LDUMINAL = {
		{{.LDUMINAL,       {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E07000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.LDUMINAL,       {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E07000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.SWP = {
		{{.SWP,            {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8208000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.SWP,            {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8208000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.SWPA = {
		{{.SWPA,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A08000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.SWPA,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A08000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.SWPL = {
		{{.SWPL,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8608000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.SWPL,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8608000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.SWPAL = {
		{{.SWPAL,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E08000, 0xFFE0FC00, .LSE, {}},                              {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.SWPAL,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E08000, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={1}, read={0, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CAS = {
		{{.CAS,            {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x88A07C00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.CAS,            {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xC8A07C00, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.CASA = {
		{{.CASA,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x88E07C00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.CASA,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xC8E07C00, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASL = {
		{{.CASL,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x88A0FC00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.CASL,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xC8A0FC00, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASAL = {
		{{.CASAL,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x88E0FC00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.CASAL,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xC8E0FC00, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASB = {
		{{.CASB,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08A07C00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.CASAB = {
		{{.CASAB,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08E07C00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASLB = {
		{{.CASLB,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08A0FC00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASALB = {
		{{.CASALB,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08E0FC00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASH = {
		{{.CASH,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48A07C00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.CASAH = {
		{{.CASAH,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48E07C00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASLH = {
		{{.CASLH,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48A0FC00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASALH = {
		{{.CASALH,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48E0FC00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASP = {
		{{.CASP,           {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08207C00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
		{{.CASP,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48207C00, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.ATOMIC}}},
	},
	.CASPA = {
		{{.CASPA,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08607C00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.CASPA,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48607C00, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASPL = {
		{{.CASPL,          {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x0820FC00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.CASPL,          {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x4820FC00, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.CASPAL = {
		{{.CASPAL,         {.W_REG, .W_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x0860FC00, 0xFFE0FC00, .LSE, {}},                              {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
		{{.CASPAL,         {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x4860FC00, 0xFFE0FC00, .LSE, {is_64=true}},                    {written={0}, read={0, 1, 2}, writes_mem=true, reads_mem=true, side_effects={.FENCE, .ATOMIC}}},
	},
	.PACIA = {
		{{.PACIA,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC10000, 0xFFFFFC00, .PAC, {is_64=true}},                                           {written={0}, read={0, 1}, side_effects={.PAC}}},
	},
	.PACIB = {
		{{.PACIB,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC10400, 0xFFFFFC00, .PAC, {is_64=true}},                                           {written={0}, read={0, 1}, side_effects={.PAC}}},
	},
	.PACDA = {
		{{.PACDA,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC10800, 0xFFFFFC00, .PAC, {is_64=true}},                                           {written={0}, read={0, 1}, side_effects={.PAC}}},
	},
	.PACDB = {
		{{.PACDB,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC10C00, 0xFFFFFC00, .PAC, {is_64=true}},                                           {written={0}, read={0, 1}, side_effects={.PAC}}},
	},
	.PACIZA = {
		{{.PACIZA,         {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC123E0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.PACIZB = {
		{{.PACIZB,         {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC127E0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.PACDZA = {
		{{.PACDZA,         {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC12BE0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.PACDZB = {
		{{.PACDZB,         {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC12FE0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.AUTIA = {
		{{.AUTIA,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC11000, 0xFFFFFC00, .PAC, {is_64=true}},                                           {written={0}, read={0, 1}, side_effects={.PAC}}},
	},
	.AUTIB = {
		{{.AUTIB,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC11400, 0xFFFFFC00, .PAC, {is_64=true}},                                           {written={0}, read={0, 1}, side_effects={.PAC}}},
	},
	.AUTDA = {
		{{.AUTDA,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC11800, 0xFFFFFC00, .PAC, {is_64=true}},                                           {written={0}, read={0, 1}, side_effects={.PAC}}},
	},
	.AUTDB = {
		{{.AUTDB,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC11C00, 0xFFFFFC00, .PAC, {is_64=true}},                                           {written={0}, read={0, 1}, side_effects={.PAC}}},
	},
	.AUTIZA = {
		{{.AUTIZA,         {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC133E0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.AUTIZB = {
		{{.AUTIZB,         {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC137E0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.AUTDZA = {
		{{.AUTDZA,         {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC13BE0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.AUTDZB = {
		{{.AUTDZB,         {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC13FE0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.PACIASP = {
		{{.PACIASP,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503233F, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.LR}, implicit_rd={.LR, .SP}, side_effects={.PAC}}},
	},
	.PACIBSP = {
		{{.PACIBSP,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503237F, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.LR}, implicit_rd={.LR, .SP}, side_effects={.PAC}}},
	},
	.AUTIASP = {
		{{.AUTIASP,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50323BF, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.LR}, implicit_rd={.LR, .SP}, side_effects={.PAC}}},
	},
	.AUTIBSP = {
		{{.AUTIBSP,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50323FF, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.LR}, implicit_rd={.LR, .SP}, side_effects={.PAC}}},
	},
	.PACIA1716 = {
		{{.PACIA1716,      {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503211F, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.X17}, implicit_rd={.X16, .X17}, side_effects={.PAC}}},
	},
	.PACIB1716 = {
		{{.PACIB1716,      {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503215F, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.X17}, implicit_rd={.X16, .X17}, side_effects={.PAC}}},
	},
	.AUTIA1716 = {
		{{.AUTIA1716,      {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503219F, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.X17}, implicit_rd={.X16, .X17}, side_effects={.PAC}}},
	},
	.AUTIB1716 = {
		{{.AUTIB1716,      {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50321DF, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.X17}, implicit_rd={.X16, .X17}, side_effects={.PAC}}},
	},
	.PACGA = {
		{{.PACGA,          {.X_REG, .X_REG, .XSP_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC03000, 0xFFE0FC00, .PAC, {is_64=true}},                                            {written={0}, read={0, 1, 2}, side_effects={.PAC}}},
	},
	.XPACI = {
		{{.XPACI,          {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC143E0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.XPACD = {
		{{.XPACD,          {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC147E0, 0xFFFFFFE0, .PAC, {is_64=true}},                                            {written={0}, read={0}, side_effects={.PAC}}},
	},
	.XPACLRI = {
		{{.XPACLRI,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50320FF, 0xFFFFFFFF, .PAC, {}},                                                     {implicit_wr={.LR}, implicit_rd={.LR}, side_effects={.PAC}}},
	},
	.RETAA = {
		{{.RETAA,          {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD65F0BFF, 0xFFFFFFFF, .PAC, {branch=true, writes_pc=true}},                          {implicit_rd={.LR, .SP}, side_effects={.CONTROL, .PAC}}},
	},
	.RETAB = {
		{{.RETAB,          {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD65F0FFF, 0xFFFFFFFF, .PAC, {branch=true, writes_pc=true}},                          {implicit_rd={.LR, .SP}, side_effects={.CONTROL, .PAC}}},
	},
	.BRAA = {
		{{.BRAA,           {.X_REG, .XSP_REG, .NONE, .NONE}, {.RN, .RD, .NONE, .NONE}, 0xD71F0800, 0xFFFFFC00, .PAC, {branch=true, writes_pc=true}},                          {read={0, 1}, side_effects={.CONTROL, .PAC}}},
	},
	.BRAB = {
		{{.BRAB,           {.X_REG, .XSP_REG, .NONE, .NONE}, {.RN, .RD, .NONE, .NONE}, 0xD71F0C00, 0xFFFFFC00, .PAC, {branch=true, writes_pc=true}},                          {read={0, 1}, side_effects={.CONTROL, .PAC}}},
	},
	.BRAAZ = {
		{{.BRAAZ,          {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD61F081F, 0xFFFFFC1F, .PAC, {branch=true, writes_pc=true}},                           {read={0}, side_effects={.CONTROL, .PAC}}},
	},
	.BRABZ = {
		{{.BRABZ,          {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD61F0C1F, 0xFFFFFC1F, .PAC, {branch=true, writes_pc=true}},                           {read={0}, side_effects={.CONTROL, .PAC}}},
	},
	.BLRAA = {
		{{.BLRAA,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RN, .RD, .NONE, .NONE}, 0xD73F0800, 0xFFFFFC00, .PAC, {branch=true, writes_pc=true}},                          {read={0, 1}, implicit_wr={.LR}, side_effects={.CONTROL, .PAC}}},
	},
	.BLRAB = {
		{{.BLRAB,          {.X_REG, .XSP_REG, .NONE, .NONE}, {.RN, .RD, .NONE, .NONE}, 0xD73F0C00, 0xFFFFFC00, .PAC, {branch=true, writes_pc=true}},                          {read={0, 1}, implicit_wr={.LR}, side_effects={.CONTROL, .PAC}}},
	},
	.BLRAAZ = {
		{{.BLRAAZ,         {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD63F081F, 0xFFFFFC1F, .PAC, {branch=true, writes_pc=true}},                           {read={0}, implicit_wr={.LR}, side_effects={.CONTROL, .PAC}}},
	},
	.BLRABZ = {
		{{.BLRABZ,         {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD63F0C1F, 0xFFFFFC1F, .PAC, {branch=true, writes_pc=true}},                           {read={0}, implicit_wr={.LR}, side_effects={.CONTROL, .PAC}}},
	},
	.ERETAA = {
		{{.ERETAA,         {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD69F0BFF, 0xFFFFFFFF, .PAC, {branch=true, writes_pc=true}},                          {side_effects={.CONTROL, .PAC, .PRIVILEGED}}},
	},
	.ERETAB = {
		{{.ERETAB,         {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD69F0FFF, 0xFFFFFFFF, .PAC, {branch=true, writes_pc=true}},                          {side_effects={.CONTROL, .PAC, .PRIVILEGED}}},
	},
	.BTI = {
		{{.BTI,            {.IMM_2, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE}, 0xD503241F, 0xFFFFF8FF, .BTI, {}},                                              {side_effects={.BTI}}},
	},
	.IRG = {
		{{.IRG,            {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC01000, 0xFFE0FC00, .MTE, {is_64=true}},                                          {written={0}, read={1, 2}}},
	},
	.ADDG = {
		{{.ADDG,           {.XSP_REG, .XSP_REG, .IMM_6, .IMM_4}, {.RD, .RN, .IMM6, .IMM_HW}, 0x91800000, 0xFFC0C000, .MTE, {is_64=true}},                                     {written={0}, read={1}}},
	},
	.SUBG = {
		{{.SUBG,           {.XSP_REG, .XSP_REG, .IMM_6, .IMM_4}, {.RD, .RN, .IMM6, .IMM_HW}, 0xD1800000, 0xFFC0C000, .MTE, {is_64=true}},                                     {written={0}, read={1}}},
	},
	.GMI = {
		{{.GMI,            {.X_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC01400, 0xFFE0FC00, .MTE, {is_64=true}},                                            {written={0}, read={1, 2}}},
	},
	.SUBP = {
		{{.SUBP,           {.X_REG, .XSP_REG, .XSP_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC00000, 0xFFE0FC00, .MTE, {is_64=true}},                                          {written={0}, read={1, 2}}},
	},
	.SUBPS = {
		{{.SUBPS,          {.X_REG, .XSP_REG, .XSP_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0xBAC00000, 0xFFE0FC00, .MTE, {sets_flags=true, is_64=true}},                         {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.LDG = {
		{{.LDG,            {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9600000, 0xFFE00C00, .MTE, {is_64=true}},                            {written={0}, read={1}, reads_mem=true}},
	},
	.STG = {
		{{.STG,            {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9200800, 0xFFE00C00, .MTE, {is_64=true}},                            {read={0, 1}, writes_mem=true}},
	},
	.ST2G = {
		{{.ST2G,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9A00800, 0xFFE00C00, .MTE, {is_64=true}},                            {read={0, 1}, writes_mem=true}},
	},
	.STZG = {
		{{.STZG,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9600800, 0xFFE00C00, .MTE, {is_64=true}},                            {read={0, 1}, writes_mem=true}},
	},
	.STZ2G = {
		{{.STZ2G,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9E00800, 0xFFE00C00, .MTE, {is_64=true}},                            {read={0, 1}, writes_mem=true}},
	},
	.STGP = {
		{{.STGP,           {.X_REG, .X_REG, .MEM_OFFSET, .NONE}, {.RT, .RT2, .OFFSET_PAIR_16, .NONE}, 0x69000000, 0xFFC00000, .MTE, {is_64=true}},                            {read={0, 1, 2}, writes_mem=true}},
	},
	.LDGM = {
		{{.LDGM,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xD9E00000, 0xFFE00C00, .MTE, {is_64=true}},                             {written={0}, read={1}, reads_mem=true}},
	},
	.STGM = {
		{{.STGM,           {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xD9A00000, 0xFFE00C00, .MTE, {is_64=true}},                             {read={0, 1}, writes_mem=true}},
	},
	.STZGM = {
		{{.STZGM,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xD9200000, 0xFFE00C00, .MTE, {is_64=true}},                             {read={0, 1}, writes_mem=true}},
	},
	.CRC32B = {
		{{.CRC32B,         {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC04000, 0xFFE0FC00, .CRC32, {}},                                                      {written={0}, read={1, 2}}},
	},
	.CRC32H = {
		{{.CRC32H,         {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC04400, 0xFFE0FC00, .CRC32, {}},                                                      {written={0}, read={1, 2}}},
	},
	.CRC32W = {
		{{.CRC32W,         {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC04800, 0xFFE0FC00, .CRC32, {}},                                                      {written={0}, read={1, 2}}},
	},
	.CRC32X = {
		{{.CRC32X,         {.W_REG, .W_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC04C00, 0xFFE0FC00, .CRC32, {is_64=true}},                                            {written={0}, read={1, 2}}},
	},
	.CRC32CB = {
		{{.CRC32CB,        {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC05000, 0xFFE0FC00, .CRC32, {}},                                                      {written={0}, read={1, 2}}},
	},
	.CRC32CH = {
		{{.CRC32CH,        {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC05400, 0xFFE0FC00, .CRC32, {}},                                                      {written={0}, read={1, 2}}},
	},
	.CRC32CW = {
		{{.CRC32CW,        {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC05800, 0xFFE0FC00, .CRC32, {}},                                                      {written={0}, read={1, 2}}},
	},
	.CRC32CX = {
		{{.CRC32CX,        {.W_REG, .W_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC05C00, 0xFFE0FC00, .CRC32, {is_64=true}},                                            {written={0}, read={1, 2}}},
	},
	.AESE = {
		{{.AESE,           {.V_16B,   .V_16B,   .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E284800, 0xFFFFFC00, .CRYPTO, {}},                                                {written={0}, read={0, 1}}},
		{{.AESE,           {.Z_REG_B, .Z_REG_B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4522E000, 0xFFFFFC00, .SVE2,   {}},                                                {written={0}, read={0, 1}}},
	},
	.AESD = {
		{{.AESD,           {.V_16B,   .V_16B,   .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E285800, 0xFFFFFC00, .CRYPTO, {}},                                                {written={0}, read={0, 1}}},
		{{.AESD,           {.Z_REG_B, .Z_REG_B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4522E400, 0xFFFFFC00, .SVE2,   {}},                                                {written={0}, read={0, 1}}},
	},
	.AESMC = {
		{{.AESMC,          {.V_16B,   .V_16B, .NONE, .NONE}, {.VD, .VN,   .NONE, .NONE}, 0x4E286800, 0xFFFFFC00, .CRYPTO, {}},                                                {written={0}, read={0, 1}}},
		{{.AESMC,          {.Z_REG_B, .NONE,  .NONE, .NONE}, {.VD, .NONE, .NONE, .NONE}, 0x4520E000, 0xFFFFFFE0, .SVE2,   {}},                                                {written={0}, read={0}}},
	},
	.AESIMC = {
		{{.AESIMC,         {.V_16B,   .V_16B, .NONE, .NONE}, {.VD, .VN,   .NONE, .NONE}, 0x4E287800, 0xFFFFFC00, .CRYPTO, {}},                                                {written={0}, read={0, 1}}},
		{{.AESIMC,         {.Z_REG_B, .NONE,  .NONE, .NONE}, {.VD, .NONE, .NONE, .NONE}, 0x4520E400, 0xFFFFFFE0, .SVE2,   {}},                                                {written={0}, read={0}}},
	},
	.SHA1H = {
		{{.SHA1H,          {.S_REG, .S_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x5E280800, 0xFFFFFC00, .CRYPTO, {}},                                                    {written={0}, read={1}}},
	},
	.SHA1C = {
		{{.SHA1C,          {.Q_REG, .S_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E000000, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1, 2}}},
	},
	.SHA1P = {
		{{.SHA1P,          {.Q_REG, .S_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E001000, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1, 2}}},
	},
	.SHA1M = {
		{{.SHA1M,          {.Q_REG, .S_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E002000, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1, 2}}},
	},
	.SHA1SU0 = {
		{{.SHA1SU0,        {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E003000, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.SHA1SU1 = {
		{{.SHA1SU1,        {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x5E281800, 0xFFFFFC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1}}},
	},
	.SHA256H = {
		{{.SHA256H,        {.Q_REG, .Q_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E004000, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1, 2}}},
	},
	.SHA256H2 = {
		{{.SHA256H2,       {.Q_REG, .Q_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E005000, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1, 2}}},
	},
	.SHA256SU0 = {
		{{.SHA256SU0,      {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x5E282800, 0xFFFFFC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1}}},
	},
	.SHA256SU1 = {
		{{.SHA256SU1,      {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E006000, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.SHA512H = {
		{{.SHA512H,        {.Q_REG, .Q_REG, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE608000, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1, 2}}},
	},
	.SHA512H2 = {
		{{.SHA512H2,       {.Q_REG, .Q_REG, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE608400, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1, 2}}},
	},
	.SHA512SU0 = {
		{{.SHA512SU0,      {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0xCEC08000, 0xFFFFFC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1}}},
	},
	.SHA512SU1 = {
		{{.SHA512SU1,      {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE608800, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.EOR3 = {
		{{.EOR3,           {.V_16B,   .V_16B,   .V_16B,   .V_16B},   {.VD, .VN, .VM, .VA}, 0xCE000000, 0xFFE08000, .CRYPTO, {}},                                              {written={0}, read={1, 2, 3}}},
		{{.EOR3,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04203800, 0xFFE0FC00, .SVE,    {is_64=true}},                                    {written={0}, read={1, 2, 3}}},
	},
	.BCAX = {
		{{.BCAX,           {.V_16B,   .V_16B,   .V_16B,   .V_16B},   {.VD, .VN, .VM, .VA}, 0xCE200000, 0xFFE08000, .CRYPTO, {}},                                              {written={0}, read={1, 2, 3}}},
		{{.BCAX,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04603800, 0xFFE0FC00, .SVE,    {is_64=true}},                                    {written={0}, read={1, 2, 3}}},
	},
	.RAX1 = {
		{{.RAX1,           {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE608C00, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={1, 2}}},
	},
	.XAR = {
		{{.XAR,            {.V_2D,    .V_2D,    .V_2D,    .IMM_6},     {.VD, .VN, .VM, .IMM6},          0xCE800000, 0xFFE00000, .CRYPTO, {}},                                 {written={0}, read={1, 2}}},
		{{.XAR,            {.Z_REG_B, .Z_REG_B, .Z_REG_B, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_XAR_SHIFT}, 0x04203400, 0xFF20FC00, .SVE2,   {}},                                 {written={0}, read={1, 2}}},
		{{.XAR,            {.Z_REG_H, .Z_REG_H, .Z_REG_H, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_XAR_SHIFT}, 0x04203400, 0xFF20FC00, .SVE2,   {}},                                 {written={0}, read={1, 2}}},
		{{.XAR,            {.Z_REG_S, .Z_REG_S, .Z_REG_S, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_XAR_SHIFT}, 0x04203400, 0xFF20FC00, .SVE2,   {}},                                 {written={0}, read={1, 2}}},
		{{.XAR,            {.Z_REG_D, .Z_REG_D, .Z_REG_D, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_XAR_SHIFT}, 0x04203400, 0xFF20FC00, .SVE2,   {is_64=true}},                       {written={0}, read={1, 2}}},
	},
	.SM3PARTW1 = {
		{{.SM3PARTW1,      {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE60C000, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.SM3PARTW2 = {
		{{.SM3PARTW2,      {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE60C400, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.SM3SS1 = {
		{{.SM3SS1,         {.V_4S, .V_4S, .V_4S, .V_4S}, {.VD, .VN, .VM, .VA}, 0xCE400000, 0xFFE08000, .CRYPTO, {}},                                                          {written={0}, read={1, 2, 3}}},
	},
	.SM3TT1A = {
		{{.SM3TT1A,        {.V_4S, .V_4S, .V_ELEM_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE408000, 0xFFE0CC00, .CRYPTO, {}},                                                    {written={0}, read={0, 1, 2}}},
	},
	.SM3TT1B = {
		{{.SM3TT1B,        {.V_4S, .V_4S, .V_ELEM_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE408400, 0xFFE0CC00, .CRYPTO, {}},                                                    {written={0}, read={0, 1, 2}}},
	},
	.SM3TT2A = {
		{{.SM3TT2A,        {.V_4S, .V_4S, .V_ELEM_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE408800, 0xFFE0CC00, .CRYPTO, {}},                                                    {written={0}, read={0, 1, 2}}},
	},
	.SM3TT2B = {
		{{.SM3TT2B,        {.V_4S, .V_4S, .V_ELEM_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE408C00, 0xFFE0CC00, .CRYPTO, {}},                                                    {written={0}, read={0, 1, 2}}},
	},
	.SM4E = {
		{{.SM4E,           {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0xCEC08400, 0xFFFFFC00, .CRYPTO, {}},                                                      {written={0}, read={0, 1}}},
	},
	.SM4EKEY = {
		{{.SM4EKEY,        {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE60C800, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={1, 2}}},
	},
	.PMULL = {
		{{.PMULL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20E000, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={1, 2}}},
		{{.PMULL,          {.V_2D, .V_1D, .V_1D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EE0E000, 0xFFE0FC00, .CRYPTO, {}},                                                        {written={0}, read={1, 2}}},
	},
	.PMULL2 = {
		{{.PMULL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20E000, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={1, 2}}},
		{{.PMULL2,         {.V_2D, .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0E000, 0xFFE0FC00, .CRYPTO, {}},                                                      {written={0}, read={1, 2}}},
	},
	.BFCVT = {
		{{.BFCVT,          {.H_REG,   .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E634000, 0xFFFFFC00, .BF16, {}},                                           {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.BFCVT,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x658AA000, 0xFFFFE000, .SVE,  {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFDOT = {
		{{.BFDOT,          {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E40FC00, 0xFFE0FC00, .BF16, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFMMLA = {
		{{.BFMMLA,         {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E40EC00, 0xFFE0FC00, .BF16, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFMLALB = {
		{{.BFMLALB,        {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EC0FC00, 0xFFE0FC00, .BF16, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFMLALT = {
		{{.BFMLALT,        {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EC0FC00, 0xFFE0FC00, .BF16, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFCVTN = {
		{{.BFCVTN,         {.V_8H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA16800, 0xFFFFFC00, .BF16, {}},                                                        {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFCVTN2 = {
		{{.BFCVTN2,        {.V_8H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA16800, 0xFFFFFC00, .BF16, {}},                                                        {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.MUL = {
		{{.MUL,            {.V_16B,   .V_16B,       .V_16B,   .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E209C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.MUL,            {.V_8H,    .V_8H,        .V_8H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E609C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.MUL,            {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EA09C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.MUL,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x04100000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.MUL,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x04500000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.MUL,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x04900000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.MUL,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04D00000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.MLA = {
		{{.MLA,            {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E209400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLA,            {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E209400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLA,            {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E609400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLA,            {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E609400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLA,            {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA09400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLA,            {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA09400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
	},
	.MLS = {
		{{.MLS,            {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E209400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLS,            {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E209400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLS,            {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E609400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLS,            {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E609400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLS,            {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA09400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.MLS,            {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA09400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
	},
	.NEG = {
		{{.NEG,            {.V_8B,    .V_8B,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E20B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.NEG,            {.V_16B,   .V_16B,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E20B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.NEG,            {.V_4H,    .V_4H,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E60B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.NEG,            {.V_8H,    .V_8H,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E60B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.NEG,            {.V_2S,    .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA0B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.NEG,            {.V_4S,    .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA0B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.NEG,            {.V_2D,    .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE0B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.NEG,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0417A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.NEG,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0457A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.NEG,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0497A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.NEG,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x04D7A000, 0xFFE0E000, .SVE,  {is_64=true}},                                 {written={0}, read={1, 2}}},
		{{.NEG,            {.W_REG,   .W_SHIFTED,   .NONE,    .NONE}, {.RD, .RM, .NONE, .NONE}, 0x4B0003E0, 0xFF2003E0, .BASE, {}},                                           {written={0}, read={1}}},
		{{.NEG,            {.X_REG,   .X_SHIFTED,   .NONE,    .NONE}, {.RD, .RM, .NONE, .NONE}, 0xCB0003E0, 0xFF2003E0, .BASE, {is_64=true}},                                 {written={0}, read={1}}},
	},
	.ABS = {
		{{.ABS,            {.V_8B,    .V_8B,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E20B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.ABS,            {.V_16B,   .V_16B,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E20B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.ABS,            {.V_4H,    .V_4H,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E60B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.ABS,            {.V_8H,    .V_8H,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E60B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.ABS,            {.V_2S,    .V_2S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA0B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.ABS,            {.V_4S,    .V_4S,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA0B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.ABS,            {.V_2D,    .V_2D,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE0B800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.ABS,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0416A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.ABS,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0456A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.ABS,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x0496A000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.ABS,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x04D6A000, 0xFFE0E000, .SVE,  {is_64=true}},                                 {written={0}, read={1, 2}}},
	},
	.SHADD = {
		{{.SHADD,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E200400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHADD,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E200400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHADD,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E600400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHADD,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E600400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHADD,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA00400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHADD,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA00400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.UHADD = {
		{{.UHADD,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E200400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHADD,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E200400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHADD,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E600400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHADD,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E600400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHADD,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA00400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHADD,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA00400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.SHSUB = {
		{{.SHSUB,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E202400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHSUB,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E202400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHSUB,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E602400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHSUB,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E602400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHSUB,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA02400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SHSUB,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA02400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.UHSUB = {
		{{.UHSUB,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E202400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHSUB,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E202400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHSUB,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E602400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHSUB,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E602400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHSUB,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA02400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UHSUB,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA02400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.SRHADD = {
		{{.SRHADD,         {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E201400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRHADD,         {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E201400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRHADD,         {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E601400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRHADD,         {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E601400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRHADD,         {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA01400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRHADD,         {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA01400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.URHADD = {
		{{.URHADD,         {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E201400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URHADD,         {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E201400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URHADD,         {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E601400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URHADD,         {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E601400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URHADD,         {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA01400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URHADD,         {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA01400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.SQADD = {
		{{.SQADD,          {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E200C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E200C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E600C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E600C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA00C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA00C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE00C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04201000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04601000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A01000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQADD,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E01000, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}, fpsr_wr={.QC}}},
	},
	.UQADD = {
		{{.UQADD,          {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E200C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E200C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E600C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E600C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA00C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA00C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE00C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04201400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04601400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A01400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQADD,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E01400, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}, fpsr_wr={.QC}}},
	},
	.SQSUB = {
		{{.SQSUB,          {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E202C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E202C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E602C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E602C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA02C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA02C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE02C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04201800, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04601800, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A01800, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQSUB,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E01800, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}, fpsr_wr={.QC}}},
	},
	.UQSUB = {
		{{.UQSUB,          {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E202C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E202C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E602C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E602C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA02C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA02C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE02C00, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04201C00, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04601C00, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A01C00, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.UQSUB,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E01C00, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}, fpsr_wr={.QC}}},
	},
	.SMAX = {
		{{.SMAX,           {.V_8B,    .V_8B,        .V_8B,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E206400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMAX,           {.V_16B,   .V_16B,       .V_16B,   .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E206400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMAX,           {.V_4H,    .V_4H,        .V_4H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E606400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMAX,           {.V_8H,    .V_8H,        .V_8H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E606400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMAX,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0EA06400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMAX,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EA06400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMAX,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x04080000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMAX,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x04480000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMAX,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x04880000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMAX,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04C80000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.UMAX = {
		{{.UMAX,           {.V_8B,    .V_8B,        .V_8B,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E206400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMAX,           {.V_16B,   .V_16B,       .V_16B,   .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E206400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMAX,           {.V_4H,    .V_4H,        .V_4H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E606400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMAX,           {.V_8H,    .V_8H,        .V_8H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E606400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMAX,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2EA06400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMAX,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6EA06400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMAX,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x04090000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMAX,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x04490000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMAX,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x04890000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMAX,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04C90000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.SMIN = {
		{{.SMIN,           {.V_8B,    .V_8B,        .V_8B,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E206C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMIN,           {.V_16B,   .V_16B,       .V_16B,   .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E206C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMIN,           {.V_4H,    .V_4H,        .V_4H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E606C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMIN,           {.V_8H,    .V_8H,        .V_8H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E606C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMIN,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0EA06C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMIN,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EA06C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SMIN,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x040A0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMIN,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x044A0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMIN,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x048A0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SMIN,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04CA0000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.UMIN = {
		{{.UMIN,           {.V_8B,    .V_8B,        .V_8B,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E206C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMIN,           {.V_16B,   .V_16B,       .V_16B,   .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E206C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMIN,           {.V_4H,    .V_4H,        .V_4H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E606C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMIN,           {.V_8H,    .V_8H,        .V_8H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E606C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMIN,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2EA06C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMIN,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6EA06C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UMIN,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x040B0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMIN,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x044B0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMIN,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x048B0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UMIN,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04CB0000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.SABD = {
		{{.SABD,           {.V_8B,    .V_8B,        .V_8B,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E207400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SABD,           {.V_16B,   .V_16B,       .V_16B,   .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E207400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SABD,           {.V_4H,    .V_4H,        .V_4H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E607400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SABD,           {.V_8H,    .V_8H,        .V_8H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E607400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SABD,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x0EA07400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SABD,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x4EA07400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.SABD,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x040C0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SABD,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x044C0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SABD,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x048C0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.SABD,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04CC0000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.UABD = {
		{{.UABD,           {.V_8B,    .V_8B,        .V_8B,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E207400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UABD,           {.V_16B,   .V_16B,       .V_16B,   .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E207400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UABD,           {.V_4H,    .V_4H,        .V_4H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E607400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UABD,           {.V_8H,    .V_8H,        .V_8H,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E607400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UABD,           {.V_2S,    .V_2S,        .V_2S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x2EA07400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UABD,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE}, 0x6EA07400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1, 2}}},
		{{.UABD,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM},   0x040D0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UABD,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x044D0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UABD,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM},   0x048D0000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}}},
		{{.UABD,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM},   0x04CD0000, 0xFFE0E000, .SVE,  {is_64=true}},                                {written={0}, read={1, 2, 3}}},
	},
	.SABA = {
		{{.SABA,           {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E207C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.SABA,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E207C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.SABA,           {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E607C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.SABA,           {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E607C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.SABA,           {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA07C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.SABA,           {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA07C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
	},
	.UABA = {
		{{.UABA,           {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E207C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.UABA,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E207C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.UABA,           {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E607C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.UABA,           {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E607C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.UABA,           {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA07C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
		{{.UABA,           {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA07C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
	},
	.ADDP = {
		{{.ADDP,           {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20BC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.ADDP,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20BC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.ADDP,           {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60BC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.ADDP,           {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60BC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.ADDP,           {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0BC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.ADDP,           {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0BC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.ADDP,           {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0BC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.ADDV = {
		{{.ADDV,           {.B_REG, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E31B800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.ADDV,           {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E31B800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.ADDV,           {.H_REG, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E71B800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.ADDV,           {.H_REG, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E71B800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.ADDV,           {.S_REG, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB1B800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.SADDLP = {
		{{.SADDLP,         {.V_4H, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E202800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.SADDLP,         {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E202800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.SADDLP,         {.V_2S, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E602800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.SADDLP,         {.V_4S, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E602800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.SADDLP,         {.V_1D, .V_2S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA02800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.SADDLP,         {.V_2D, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA02800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
	},
	.UADDLP = {
		{{.UADDLP,         {.V_4H, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E202800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.UADDLP,         {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E202800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.UADDLP,         {.V_2S, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E602800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.UADDLP,         {.V_4S, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E602800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.UADDLP,         {.V_1D, .V_2S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA02800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.UADDLP,         {.V_2D, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA02800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
	},
	.SADALP = {
		{{.SADALP,         {.V_4H, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E206800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.SADALP,         {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E206800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.SADALP,         {.V_2S, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E606800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.SADALP,         {.V_4S, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E606800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.SADALP,         {.V_1D, .V_2S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA06800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.SADALP,         {.V_2D, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA06800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
	},
	.UADALP = {
		{{.UADALP,         {.V_4H, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E206800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.UADALP,         {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E206800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.UADALP,         {.V_2S, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E606800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.UADALP,         {.V_4S, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E606800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.UADALP,         {.V_1D, .V_2S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA06800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
		{{.UADALP,         {.V_2D, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA06800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={0, 1}}},
	},
	.SADDLV = {
		{{.SADDLV,         {.H_REG, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E303800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SADDLV,         {.H_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E303800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SADDLV,         {.S_REG, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E703800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SADDLV,         {.S_REG, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E703800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SADDLV,         {.D_REG, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB03800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.UADDLV = {
		{{.UADDLV,         {.H_REG, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E303800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UADDLV,         {.H_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E303800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UADDLV,         {.S_REG, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E703800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UADDLV,         {.S_REG, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E703800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UADDLV,         {.D_REG, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB03800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.SMAXV = {
		{{.SMAXV,          {.B_REG, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E30A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SMAXV,          {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E30A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SMAXV,          {.H_REG, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E70A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SMAXV,          {.H_REG, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E70A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SMAXV,          {.S_REG, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB0A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.UMAXV = {
		{{.UMAXV,          {.B_REG, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E30A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UMAXV,          {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E30A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UMAXV,          {.H_REG, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E70A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UMAXV,          {.H_REG, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E70A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UMAXV,          {.S_REG, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB0A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.SMINV = {
		{{.SMINV,          {.B_REG, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E31A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SMINV,          {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E31A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SMINV,          {.H_REG, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E71A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SMINV,          {.H_REG, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E71A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.SMINV,          {.S_REG, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB1A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.UMINV = {
		{{.UMINV,          {.B_REG, .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E31A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UMINV,          {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E31A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UMINV,          {.H_REG, .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E71A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UMINV,          {.H_REG, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E71A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.UMINV,          {.S_REG, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB1A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.SMAXP = {
		{{.SMAXP,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMAXP,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMAXP,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMAXP,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMAXP,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMAXP,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.UMAXP = {
		{{.UMAXP,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMAXP,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMAXP,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMAXP,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMAXP,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMAXP,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0A400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.SMINP = {
		{{.SMINP,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMINP,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMINP,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMINP,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMINP,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SMINP,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.UMINP = {
		{{.UMINP,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMINP,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMINP,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMINP,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMINP,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.UMINP,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0AC00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.SADDL = {
		{{.SADDL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E200000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SADDL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E600000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SADDL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA00000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.SADDL2 = {
		{{.SADDL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E200000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.SADDL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E600000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.SADDL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA00000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
	},
	.UADDL = {
		{{.UADDL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E200000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.UADDL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E600000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.UADDL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA00000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.UADDL2 = {
		{{.UADDL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E200000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.UADDL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E600000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.UADDL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA00000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
	},
	.SSUBL = {
		{{.SSUBL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E202000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SSUBL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E602000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SSUBL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA02000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.SSUBL2 = {
		{{.SSUBL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E202000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.SSUBL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E602000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.SSUBL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA02000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
	},
	.USUBL = {
		{{.USUBL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E202000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.USUBL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E602000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.USUBL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA02000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.USUBL2 = {
		{{.USUBL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E202000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.USUBL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E602000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.USUBL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA02000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
	},
	.SADDW = {
		{{.SADDW,          {.V_8H, .V_8H, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E201000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SADDW,          {.V_4S, .V_4S, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E601000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SADDW,          {.V_2D, .V_2D, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA01000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.SADDW2 = {
		{{.SADDW2,         {.V_8H, .V_8H, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E201000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.SADDW2,         {.V_4S, .V_4S, .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E601000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.SADDW2,         {.V_2D, .V_2D, .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA01000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
	},
	.UADDW = {
		{{.UADDW,          {.V_8H, .V_8H, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E201000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.UADDW,          {.V_4S, .V_4S, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E601000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.UADDW,          {.V_2D, .V_2D, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA01000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.UADDW2 = {
		{{.UADDW2,         {.V_8H, .V_8H, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E201000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.UADDW2,         {.V_4S, .V_4S, .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E601000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.UADDW2,         {.V_2D, .V_2D, .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA01000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
	},
	.SSUBW = {
		{{.SSUBW,          {.V_8H, .V_8H, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E203000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SSUBW,          {.V_4S, .V_4S, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E603000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SSUBW,          {.V_2D, .V_2D, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA03000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.SSUBW2 = {
		{{.SSUBW2,         {.V_8H, .V_8H, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E203000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.SSUBW2,         {.V_4S, .V_4S, .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E603000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.SSUBW2,         {.V_2D, .V_2D, .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA03000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
	},
	.USUBW = {
		{{.USUBW,          {.V_8H, .V_8H, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E203000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.USUBW,          {.V_4S, .V_4S, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E603000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.USUBW,          {.V_2D, .V_2D, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA03000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.USUBW2 = {
		{{.USUBW2,         {.V_8H, .V_8H, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E203000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.USUBW2,         {.V_4S, .V_4S, .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E603000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.USUBW2,         {.V_2D, .V_2D, .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA03000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
	},
	.RADDHN = {
		{{.RADDHN,         {.V_8B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E204000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.RADDHN,         {.V_4H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E604000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.RADDHN,         {.V_2S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA04000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.RADDHN2 = {
		{{.RADDHN2,        {.V_16B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E204000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.RADDHN2,        {.V_8H,  .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E604000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.RADDHN2,        {.V_4S,  .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA04000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
	},
	.RSUBHN = {
		{{.RSUBHN,         {.V_8B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E206000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.RSUBHN,         {.V_4H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E606000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.RSUBHN,         {.V_2S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA06000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.RSUBHN2 = {
		{{.RSUBHN2,        {.V_16B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E206000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.RSUBHN2,        {.V_8H,  .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E606000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.RSUBHN2,        {.V_4S,  .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA06000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
	},
	.ADDHN = {
		{{.ADDHN,          {.V_8B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E204000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.ADDHN,          {.V_4H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E604000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.ADDHN,          {.V_2S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA04000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.ADDHN2 = {
		{{.ADDHN2,         {.V_16B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E204000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.ADDHN2,         {.V_8H,  .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E604000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.ADDHN2,         {.V_4S,  .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA04000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
	},
	.SUBHN = {
		{{.SUBHN,          {.V_8B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E206000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SUBHN,          {.V_4H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E606000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SUBHN,          {.V_2S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA06000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.SUBHN2 = {
		{{.SUBHN2,         {.V_16B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E206000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.SUBHN2,         {.V_8H,  .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E606000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
		{{.SUBHN2,         {.V_4S,  .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA06000, 0xFFE0FC00, .NEON, {}},                                                         {written={0}, read={1, 2}}},
	},
	.XTN = {
		{{.XTN,            {.V_8B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E212800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
		{{.XTN,            {.V_4H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E612800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
		{{.XTN,            {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA12800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
	},
	.XTN2 = {
		{{.XTN2,           {.V_16B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E212800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.XTN2,           {.V_8H,  .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E612800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.XTN2,           {.V_4S,  .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA12800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
	},
	.SQXTN = {
		{{.SQXTN,          {.V_8B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E214800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQXTN,          {.V_4H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E614800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQXTN,          {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA14800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQXTN2 = {
		{{.SQXTN2,         {.V_16B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E214800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQXTN2,         {.V_8H,  .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E614800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQXTN2,         {.V_4S,  .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA14800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.UQXTN = {
		{{.UQXTN,          {.V_8B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E214800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQXTN,          {.V_4H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E614800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQXTN,          {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA14800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.UQXTN2 = {
		{{.UQXTN2,         {.V_16B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E214800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQXTN2,         {.V_8H,  .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E614800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQXTN2,         {.V_4S,  .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA14800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQXTUN = {
		{{.SQXTUN,         {.V_8B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E212800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQXTUN,         {.V_4H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E612800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQXTUN,         {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA12800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQXTUN2 = {
		{{.SQXTUN2,        {.V_16B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E212800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQXTUN2,        {.V_8H,  .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E612800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQXTUN2,        {.V_4S,  .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA12800, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SMULL = {
		{{.SMULL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20C000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SMULL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60C000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.SMULL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0C000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.SMULL2 = {
		{{.SMULL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20C000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.SMULL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60C000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.SMULL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0C000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
	},
	.UMULL = {
		{{.UMULL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20C000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.UMULL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60C000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
		{{.UMULL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0C000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}}},
	},
	.UMULL2 = {
		{{.UMULL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20C000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.UMULL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60C000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
		{{.UMULL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0C000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={1, 2}}},
	},
	.SMLAL = {
		{{.SMLAL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E208000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
		{{.SMLAL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E608000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
		{{.SMLAL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA08000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
	},
	.SMLAL2 = {
		{{.SMLAL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E208000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
		{{.SMLAL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E608000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
		{{.SMLAL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA08000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.UMLAL = {
		{{.UMLAL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E208000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
		{{.UMLAL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E608000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
		{{.UMLAL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA08000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
	},
	.UMLAL2 = {
		{{.UMLAL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E208000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
		{{.UMLAL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E608000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
		{{.UMLAL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA08000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.SMLSL = {
		{{.SMLSL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20A000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
		{{.SMLSL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60A000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
		{{.SMLSL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0A000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
	},
	.SMLSL2 = {
		{{.SMLSL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20A000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
		{{.SMLSL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60A000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
		{{.SMLSL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0A000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.UMLSL = {
		{{.UMLSL,          {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20A000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
		{{.UMLSL,          {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60A000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
		{{.UMLSL,          {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0A000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}}},
	},
	.UMLSL2 = {
		{{.UMLSL2,         {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20A000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
		{{.UMLSL2,         {.V_4S, .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60A000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
		{{.UMLSL2,         {.V_2D, .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0A000, 0xFFE0FC00, .NEON, {}},                                                        {written={0}, read={0, 1, 2}}},
	},
	.SQDMULL = {
		{{.SQDMULL,        {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60D000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQDMULL,        {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0D000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
	},
	.SQDMULL2 = {
		{{.SQDMULL2,       {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60D000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQDMULL2,       {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0D000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
	},
	.SQDMLAL = {
		{{.SQDMLAL,        {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E609000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQDMLAL,        {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA09000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
	},
	.SQDMLAL2 = {
		{{.SQDMLAL2,       {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E609000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQDMLAL2,       {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA09000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
	},
	.SQDMLSL = {
		{{.SQDMLSL,        {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60B000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQDMLSL,        {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0B000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
	},
	.SQDMLSL2 = {
		{{.SQDMLSL2,       {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60B000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQDMLSL2,       {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0B000, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
	},
	.SQDMULH = {
		{{.SQDMULH,        {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60B400, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQDMULH,        {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60B400, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQDMULH,        {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0B400, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQDMULH,        {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0B400, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
	},
	.SQRDMULH = {
		{{.SQRDMULH,       {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60B400, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMULH,       {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60B400, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMULH,       {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0B400, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMULH,       {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0B400, 0xFFE0FC00, .NEON, {}},                                                          {written={0}, read={1, 2}, fpsr_wr={.QC}}},
	},
	.SDOT = {
		{{.SDOT,           {.V_2S, .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E809400, 0xFFE0FC00, .DOT, {}},                                                         {written={0}, read={0, 1, 2}}},
		{{.SDOT,           {.V_4S, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E809400, 0xFFE0FC00, .DOT, {}},                                                         {written={0}, read={0, 1, 2}}},
	},
	.UDOT = {
		{{.UDOT,           {.V_2S, .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E809400, 0xFFE0FC00, .DOT, {}},                                                         {written={0}, read={0, 1, 2}}},
		{{.UDOT,           {.V_4S, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E809400, 0xFFE0FC00, .DOT, {}},                                                         {written={0}, read={0, 1, 2}}},
	},
	.USDOT = {
		{{.USDOT,          {.V_2S, .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E809C00, 0xFFE0FC00, .DOT, {}},                                                         {written={0}, read={0, 1, 2}}},
		{{.USDOT,          {.V_4S, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E809C00, 0xFFE0FC00, .DOT, {}},                                                         {written={0}, read={0, 1, 2}}},
	},
	.FMLA = {
		{{.FMLA,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE},           0x4E20CC00, 0xFFE0FC00, .NEON, {}},                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLA,           {.V_2D,    .V_2D,        .V_2D,    .NONE},    {.VD, .VN, .VM, .NONE},           0x4E60CC00, 0xFFE0FC00, .NEON, {}},                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLA,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM},             0x65600000, 0xFFE0E000, .SVE,  {}},                                {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLA,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM},             0x65A00000, 0xFFE0E000, .SVE,  {}},                                {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLA,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM},             0x65E00000, 0xFFE0E000, .SVE,  {is_64=true}},                      {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLA,           {.Z_REG_H, .Z_REG_H,     .Z_REG_H, .IMM_3},   {.VD, .VN, .VM, .SVE_FMLA_IDX_H}, 0x64200000, 0xFFA0FC00, .SVE,  {}},                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLA,           {.Z_REG_S, .Z_REG_S,     .Z_REG_S, .IMM_2},   {.VD, .VN, .VM, .SVE_FMLA_IDX_S}, 0x64A00000, 0xFFE0FC00, .SVE,  {}},                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLA,           {.Z_REG_D, .Z_REG_D,     .Z_REG_D, .IMM_2},   {.VD, .VN, .VM, .SVE_FMLA_IDX_D}, 0x64E00000, 0xFFE0FC00, .SVE,  {is_64=true}},                      {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FMLS = {
		{{.FMLS,           {.V_4S,    .V_4S,        .V_4S,    .NONE},    {.VD, .VN, .VM, .NONE},           0x4EA0CC00, 0xFFE0FC00, .NEON, {}},                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLS,           {.V_2D,    .V_2D,        .V_2D,    .NONE},    {.VD, .VN, .VM, .NONE},           0x4EE0CC00, 0xFFE0FC00, .NEON, {}},                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLS,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM},             0x65602000, 0xFFE0E000, .SVE,  {}},                                {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLS,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM},             0x65A02000, 0xFFE0E000, .SVE,  {}},                                {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLS,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM},             0x65E02000, 0xFFE0E000, .SVE,  {is_64=true}},                      {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLS,           {.Z_REG_H, .Z_REG_H,     .Z_REG_H, .IMM_3},   {.VD, .VN, .VM, .SVE_FMLA_IDX_H}, 0x64200400, 0xFFA0FC00, .SVE,  {}},                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLS,           {.Z_REG_S, .Z_REG_S,     .Z_REG_S, .IMM_2},   {.VD, .VN, .VM, .SVE_FMLA_IDX_S}, 0x64A00400, 0xFFE0FC00, .SVE,  {}},                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMLS,           {.Z_REG_D, .Z_REG_D,     .Z_REG_D, .IMM_2},   {.VD, .VN, .VM, .SVE_FMLA_IDX_D}, 0x64E00400, 0xFFE0FC00, .SVE,  {is_64=true}},                      {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FMULX = {
		{{.FMULX,          {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20DC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMULX,          {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20DC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMULX,          {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60DC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMULX,          {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E401C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FMULX,          {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E401C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FMAXP = {
		{{.FMAXP,          {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20F400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXP,          {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20F400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXP,          {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60F400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXP,          {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E403400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXP,          {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E403400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMINP = {
		{{.FMINP,          {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0F400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINP,          {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0F400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINP,          {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE0F400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINP,          {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EC03400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINP,          {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EC03400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMAXNMP = {
		{{.FMAXNMP,        {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20C400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNMP,        {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20C400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNMP,        {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60C400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNMP,        {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E400400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNMP,        {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E400400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMINNMP = {
		{{.FMINNMP,        {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0C400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNMP,        {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0C400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNMP,        {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE0C400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNMP,        {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EC00400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNMP,        {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EC00400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMAXV = {
		{{.FMAXV,          {.S_REG, .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E30F800, 0xFFFFFC00, .NEON, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXV,          {.H_REG, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E30F800, 0xFFFFFC00, .FP16, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXV,          {.H_REG, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E30F800, 0xFFFFFC00, .FP16, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMINV = {
		{{.FMINV,          {.S_REG, .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB0F800, 0xFFFFFC00, .NEON, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINV,          {.H_REG, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EB0F800, 0xFFFFFC00, .FP16, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINV,          {.H_REG, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB0F800, 0xFFFFFC00, .FP16, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMAXNMV = {
		{{.FMAXNMV,        {.S_REG, .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E30C800, 0xFFFFFC00, .NEON, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNMV,        {.H_REG, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E30C800, 0xFFFFFC00, .FP16, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMAXNMV,        {.H_REG, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E30C800, 0xFFFFFC00, .FP16, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FMINNMV = {
		{{.FMINNMV,        {.S_REG, .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB0C800, 0xFFFFFC00, .NEON, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNMV,        {.H_REG, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EB0C800, 0xFFFFFC00, .FP16, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
		{{.FMINNMV,        {.H_REG, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB0C800, 0xFFFFFC00, .FP16, {}},                                                  {written={0}, read={1}, fpsr_wr={.IOC, .IDC}, reads_fpcr=true}},
	},
	.FRECPE = {
		{{.FRECPE,         {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA1D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
		{{.FRECPE,         {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA1D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
		{{.FRECPE,         {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE1D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
		{{.FRECPE,         {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF9D800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
		{{.FRECPE,         {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF9D800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
	},
	.FRSQRTE = {
		{{.FRSQRTE,        {.V_2S,      .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
		{{.FRSQRTE,        {.V_4S,      .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
		{{.FRSQRTE,        {.V_2D,      .V_2D,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE1D800, 0xFFFFFC00, .NEON, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
		{{.FRSQRTE,        {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF9D800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
		{{.FRSQRTE,        {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF9D800, 0xFFFFFC00, .FP16, {}},                                              {written={0}, read={1}, reads_fpcr=true}},
	},
	.FRECPS = {
		{{.FRECPS,         {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20FC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRECPS,         {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20FC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRECPS,         {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60FC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRECPS,         {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E403C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRECPS,         {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E403C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRECPS,         {.Z_REG_H,   .Z_REG_H,   .Z_REG_H,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x65401800, 0xFFE0FC00, .SVE,  {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRECPS,         {.Z_REG_S,   .Z_REG_S,   .Z_REG_S,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x65801800, 0xFFE0FC00, .SVE,  {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRECPS,         {.Z_REG_D,   .Z_REG_D,   .Z_REG_D,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C01800, 0xFFE0FC00, .SVE,  {is_64=true}},                                 {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FRSQRTS = {
		{{.FRSQRTS,        {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0FC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRSQRTS,        {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0FC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRSQRTS,        {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0FC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRSQRTS,        {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EC03C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRSQRTS,        {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC03C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRSQRTS,        {.Z_REG_H,   .Z_REG_H,   .Z_REG_H,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x65401C00, 0xFFE0FC00, .SVE,  {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRSQRTS,        {.Z_REG_S,   .Z_REG_S,   .Z_REG_S,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x65801C00, 0xFFE0FC00, .SVE,  {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FRSQRTS,        {.Z_REG_D,   .Z_REG_D,   .Z_REG_D,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C01C00, 0xFFE0FC00, .SVE,  {is_64=true}},                                 {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FRECPX = {
		{{.FRECPX,         {.S_REG,   .S_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5EA1F800, 0xFFFFFC00, .FP,   {}},                                           {written={0}, read={1}, reads_fpcr=true}},
		{{.FRECPX,         {.D_REG,   .D_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5EE1F800, 0xFFFFFC00, .FP,   {}},                                           {written={0}, read={1}, reads_fpcr=true}},
		{{.FRECPX,         {.H_REG,   .H_REG,       .NONE,    .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5EF9F800, 0xFFFFFC00, .FP16, {}},                                           {written={0}, read={1}, reads_fpcr=true}},
		{{.FRECPX,         {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x654CA000, 0xFFFFE000, .SVE,  {}},                                           {written={0}, read={1, 2}, reads_fpcr=true}},
		{{.FRECPX,         {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x658CA000, 0xFFFFE000, .SVE,  {}},                                           {written={0}, read={1, 2}, reads_fpcr=true}},
		{{.FRECPX,         {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x65CCA000, 0xFFFFE000, .SVE,  {is_64=true}},                                 {written={0}, read={1, 2}, reads_fpcr=true}},
	},
	.FADDP = {
		{{.FADDP,          {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20D400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADDP,          {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20D400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADDP,          {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60D400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADDP,          {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E401400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FADDP,          {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E401400, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FCVTL = {
		{{.FCVTL,          {.V_4S, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E217800, 0xFFFFFC00, .FP16, {}},                                                   {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVTL,          {.V_2D, .V_2S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E617800, 0xFFFFFC00, .NEON, {}},                                                   {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FCVTL2 = {
		{{.FCVTL2,         {.V_4S, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E217800, 0xFFFFFC00, .FP16, {}},                                                   {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVTL2,         {.V_2D, .V_4S,      .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E617800, 0xFFFFFC00, .NEON, {}},                                                   {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FCVTN = {
		{{.FCVTN,          {.V_4H_FP16, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E216800, 0xFFFFFC00, .FP16, {}},                                                   {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVTN,          {.V_2S,      .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E616800, 0xFFFFFC00, .NEON, {}},                                                   {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FCVTN2 = {
		{{.FCVTN2,         {.V_8H_FP16, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E216800, 0xFFFFFC00, .FP16, {}},                                                   {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCVTN2,         {.V_4S,      .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E616800, 0xFFFFFC00, .NEON, {}},                                                   {written={0}, read={1}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FCVTXN = {
		{{.FCVTXN,         {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E616800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCVTXN2 = {
		{{.FCVTXN2,        {.V_4S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E616800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}, fpsr_wr={.IOC, .IXC}}},
	},
	.FCMEQ = {
		{{.FCMEQ,          {.V_2S,      .V_2S,       .V_2S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E20E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMEQ,          {.V_4S,      .V_4S,       .V_4S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E20E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMEQ,          {.V_2D,      .V_2D,       .V_2D,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E60E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMEQ,          {.V_4H_FP16, .V_4H_FP16,  .V_4H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x0E402400, 0xFFE0FC00, .FP16, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMEQ,          {.V_8H_FP16, .V_8H_FP16,  .V_8H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x4E402400, 0xFFE0FC00, .FP16, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMEQ,          {.P_REG,     .P_REG_ZERO, .Z_REG_H,   .Z_REG_H}, {.PD, .PG, .VN, .VM},   0x65406000, 0xFFE0E010, .SVE,  {}},                                       {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMEQ,          {.P_REG,     .P_REG_ZERO, .Z_REG_S,   .Z_REG_S}, {.PD, .PG, .VN, .VM},   0x65806000, 0xFFE0E010, .SVE,  {}},                                       {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMEQ,          {.P_REG,     .P_REG_ZERO, .Z_REG_D,   .Z_REG_D}, {.PD, .PG, .VN, .VM},   0x65C06000, 0xFFE0E010, .SVE,  {is_64=true}},                             {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
	},
	.FCMGE = {
		{{.FCMGE,          {.V_2S,      .V_2S,       .V_2S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E20E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGE,          {.V_4S,      .V_4S,       .V_4S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E20E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGE,          {.V_2D,      .V_2D,       .V_2D,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E60E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGE,          {.V_4H_FP16, .V_4H_FP16,  .V_4H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x2E402400, 0xFFE0FC00, .FP16, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGE,          {.V_8H_FP16, .V_8H_FP16,  .V_8H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E402400, 0xFFE0FC00, .FP16, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGE,          {.P_REG,     .P_REG_ZERO, .Z_REG_H,   .Z_REG_H}, {.PD, .PG, .VN, .VM},   0x65404000, 0xFFE0E010, .SVE,  {}},                                       {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMGE,          {.P_REG,     .P_REG_ZERO, .Z_REG_S,   .Z_REG_S}, {.PD, .PG, .VN, .VM},   0x65804000, 0xFFE0E010, .SVE,  {}},                                       {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMGE,          {.P_REG,     .P_REG_ZERO, .Z_REG_D,   .Z_REG_D}, {.PD, .PG, .VN, .VM},   0x65C04000, 0xFFE0E010, .SVE,  {is_64=true}},                             {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
	},
	.FCMGT = {
		{{.FCMGT,          {.V_2S,      .V_2S,       .V_2S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x2EA0E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGT,          {.V_4S,      .V_4S,       .V_4S,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x6EA0E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGT,          {.V_2D,      .V_2D,       .V_2D,      .NONE},    {.VD, .VN, .VM, .NONE}, 0x6EE0E400, 0xFFE0FC00, .NEON, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGT,          {.V_4H_FP16, .V_4H_FP16,  .V_4H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x2EC02400, 0xFFE0FC00, .FP16, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGT,          {.V_8H_FP16, .V_8H_FP16,  .V_8H_FP16, .NONE},    {.VD, .VN, .VM, .NONE}, 0x6EC02400, 0xFFE0FC00, .FP16, {}},                                       {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMGT,          {.P_REG,     .P_REG_ZERO, .Z_REG_H,   .Z_REG_H}, {.PD, .PG, .VN, .VM},   0x65404010, 0xFFE0E010, .SVE,  {}},                                       {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMGT,          {.P_REG,     .P_REG_ZERO, .Z_REG_S,   .Z_REG_S}, {.PD, .PG, .VN, .VM},   0x65804010, 0xFFE0E010, .SVE,  {}},                                       {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMGT,          {.P_REG,     .P_REG_ZERO, .Z_REG_D,   .Z_REG_D}, {.PD, .PG, .VN, .VM},   0x65C04010, 0xFFE0E010, .SVE,  {is_64=true}},                             {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
	},
	.FCMLE = {
		{{.FCMLE,          {.V_2S,      .V_2S,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA0D800, 0xFFFFFC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLE,          {.V_4S,      .V_4S,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA0D800, 0xFFFFFC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLE,          {.V_2D,      .V_2D,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE0D800, 0xFFFFFC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLE,          {.V_4H_FP16, .V_4H_FP16,  .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF8D800, 0xFFFFFC00, .FP16, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLE,          {.V_8H_FP16, .V_8H_FP16,  .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF8D800, 0xFFFFFC00, .FP16, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLE,          {.P_REG,     .P_REG_ZERO, .Z_REG_H, .NONE}, {.PD, .PG, .VN,   .NONE}, 0x65512010, 0xFFFFE010, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMLE,          {.P_REG,     .P_REG_ZERO, .Z_REG_S, .NONE}, {.PD, .PG, .VN,   .NONE}, 0x65912010, 0xFFFFE010, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMLE,          {.P_REG,     .P_REG_ZERO, .Z_REG_D, .NONE}, {.PD, .PG, .VN,   .NONE}, 0x65D12010, 0xFFFFE010, .SVE,  {is_64=true}},                                {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.FCMLT = {
		{{.FCMLT,          {.V_2S,      .V_2S,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA0E800, 0xFFFFFC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLT,          {.V_4S,      .V_4S,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA0E800, 0xFFFFFC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLT,          {.V_2D,      .V_2D,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE0E800, 0xFFFFFC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLT,          {.V_4H_FP16, .V_4H_FP16,  .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF8E800, 0xFFFFFC00, .FP16, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLT,          {.V_8H_FP16, .V_8H_FP16,  .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF8E800, 0xFFFFFC00, .FP16, {}},                                          {written={0}, read={1}, fpsr_wr={.IOC}}},
		{{.FCMLT,          {.P_REG,     .P_REG_ZERO, .Z_REG_H, .NONE}, {.PD, .PG, .VN,   .NONE}, 0x65512000, 0xFFFFE010, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMLT,          {.P_REG,     .P_REG_ZERO, .Z_REG_S, .NONE}, {.PD, .PG, .VN,   .NONE}, 0x65912000, 0xFFFFE010, .SVE,  {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FCMLT,          {.P_REG,     .P_REG_ZERO, .Z_REG_D, .NONE}, {.PD, .PG, .VN,   .NONE}, 0x65D12000, 0xFFFFE010, .SVE,  {is_64=true}},                                {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.FACGE = {
		{{.FACGE,          {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20EC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FACGE,          {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20EC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FACGE,          {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60EC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FACGE,          {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E402C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FACGE,          {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E402C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.FACGT = {
		{{.FACGT,          {.V_2S,      .V_2S,      .V_2S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0EC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FACGT,          {.V_4S,      .V_4S,      .V_4S,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0EC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FACGT,          {.V_2D,      .V_2D,      .V_2D,      .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE0EC00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FACGT,          {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EC02C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
		{{.FACGT,          {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EC02C00, 0xFFE0FC00, .FP16, {}},                                           {written={0}, read={1, 2}, fpsr_wr={.IOC}}},
	},
	.CMEQ = {
		{{.CMEQ,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E208C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMEQ,           {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E608C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMEQ,           {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA08C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMEQ,           {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE08C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.CMGE = {
		{{.CMGE,           {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E203C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMGE,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E203C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMGE,           {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E603C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMGE,           {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E603C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMGE,           {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA03C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMGE,           {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA03C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMGE,           {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE03C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.CMGT = {
		{{.CMGT,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E203400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMGT,           {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE03400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.CMHI = {
		{{.CMHI,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E203400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMHI,           {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE03400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.CMHS = {
		{{.CMHS,           {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E203C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMHS,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E203C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMHS,           {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E603C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMHS,           {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E603C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMHS,           {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA03C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMHS,           {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA03C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMHS,           {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE03C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.CMLE = {
		{{.CMLE,           {.V_8B,  .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E209800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLE,           {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E209800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLE,           {.V_4H,  .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E609800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLE,           {.V_8H,  .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E609800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLE,           {.V_2S,  .V_2S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA09800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLE,           {.V_4S,  .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA09800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLE,           {.V_2D,  .V_2D,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE09800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.CMLT = {
		{{.CMLT,           {.V_8B,  .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E20A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLT,           {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E20A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLT,           {.V_4H,  .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E60A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLT,           {.V_8H,  .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E60A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLT,           {.V_2S,  .V_2S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA0A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLT,           {.V_4S,  .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA0A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.CMLT,           {.V_2D,  .V_2D,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE0A800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.CMTST = {
		{{.CMTST,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E208C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMTST,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E208C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMTST,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E608C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMTST,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E608C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMTST,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA08C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMTST,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA08C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.CMTST,          {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE08C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.MVN = {
		{{.MVN,            {.V_8B,  .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E205800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.MVN,            {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E205800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.MVN,            {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x2A2003E0, 0xFFE0FFE0, .BASE, {}},                                                      {written={0}, read={1}}},
		{{.MVN,            {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xAA2003E0, 0xFFE0FFE0, .BASE, {is_64=true}},                                            {written={0}, read={1}}},
	},
	.BIT = {
		{{.BIT,            {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA01C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
	},
	.BIF = {
		{{.BIF,            {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE01C00, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={0, 1, 2}}},
	},
	.BSL = {
		{{.BSL,            {.V_16B,   .V_16B,   .V_16B,   .NONE},    {.VD, .VN, .VM, .NONE}, 0x6E601C00, 0xFFE0FC00, .NEON, {}},                                              {written={0}, read={0, 1, 2}}},
		{{.BSL,            {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN},   0x04203C00, 0xFFE0FC00, .SVE2, {is_64=true}},                                    {written={0}, read={0, 1, 2, 3}}},
	},
	.SHL = {
		{{.SHL,            {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F085400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SHL,            {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F085400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SHL,            {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F105400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SHL,            {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F105400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SHL,            {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F205400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SHL,            {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F205400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SHL,            {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F405400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={1}}},
	},
	.SQSHL = {
		{{.SQSHL,          {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F087400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHL,          {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F087400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHL,          {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F107400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHL,          {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F107400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHL,          {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F207400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHL,          {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F207400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHL,          {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F407400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQSHLU = {
		{{.SQSHLU,         {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F086400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHLU,         {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F086400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHLU,         {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F106400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHLU,         {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F106400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHLU,         {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F206400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHLU,         {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F206400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHLU,         {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F406400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SRSHL = {
		{{.SRSHL,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E205400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRSHL,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E205400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRSHL,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E605400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRSHL,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E605400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRSHL,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA05400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRSHL,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA05400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SRSHL,          {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE05400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.URSHL = {
		{{.URSHL,          {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E205400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URSHL,          {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E205400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URSHL,          {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E605400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URSHL,          {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E605400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URSHL,          {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA05400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URSHL,          {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA05400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.URSHL,          {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE05400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.SSHR = {
		{{.SSHR,           {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F080400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SSHR,           {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F080400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SSHR,           {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F100400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SSHR,           {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F100400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SSHR,           {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F200400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SSHR,           {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F200400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SSHR,           {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F400400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={1}}},
	},
	.USHR = {
		{{.USHR,           {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F080400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.USHR,           {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F080400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.USHR,           {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F100400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.USHR,           {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F100400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.USHR,           {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F200400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.USHR,           {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F200400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.USHR,           {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F400400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={1}}},
	},
	.SSRA = {
		{{.SSRA,           {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F081400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SSRA,           {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F081400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SSRA,           {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F101400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SSRA,           {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F101400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SSRA,           {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F201400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SSRA,           {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F201400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SSRA,           {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F401400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
	},
	.USRA = {
		{{.USRA,           {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F081400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.USRA,           {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F081400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.USRA,           {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F101400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.USRA,           {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F101400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.USRA,           {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F201400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.USRA,           {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F201400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.USRA,           {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F401400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
	},
	.SRSHR = {
		{{.SRSHR,          {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F082400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SRSHR,          {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F082400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SRSHR,          {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F102400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SRSHR,          {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F102400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SRSHR,          {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F202400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SRSHR,          {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F202400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.SRSHR,          {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F402400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={1}}},
	},
	.URSHR = {
		{{.URSHR,          {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F082400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.URSHR,          {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F082400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.URSHR,          {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F102400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.URSHR,          {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F102400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.URSHR,          {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F202400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.URSHR,          {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F202400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={1}}},
		{{.URSHR,          {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F402400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={1}}},
	},
	.SRSRA = {
		{{.SRSRA,          {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F083400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRSRA,          {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F083400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRSRA,          {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F103400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRSRA,          {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F103400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRSRA,          {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F203400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRSRA,          {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F203400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRSRA,          {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F403400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
	},
	.URSRA = {
		{{.URSRA,          {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F083400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.URSRA,          {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F083400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.URSRA,          {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F103400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.URSRA,          {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F103400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.URSRA,          {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F203400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.URSRA,          {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F203400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.URSRA,          {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F403400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
	},
	.SSHL = {
		{{.SSHL,           {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E204400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SSHL,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E204400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SSHL,           {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E604400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SSHL,           {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E604400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SSHL,           {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA04400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SSHL,           {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA04400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.SSHL,           {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE04400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.USHL = {
		{{.USHL,           {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E204400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.USHL,           {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E204400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.USHL,           {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E604400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.USHL,           {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E604400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.USHL,           {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA04400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.USHL,           {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA04400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
		{{.USHL,           {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE04400, 0xFFE0FC00, .NEON, {}},                                                       {written={0}, read={1, 2}}},
	},
	.SLI = {
		{{.SLI,            {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F085400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SLI,            {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F085400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SLI,            {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F105400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SLI,            {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F105400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SLI,            {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F205400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SLI,            {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F205400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SLI,            {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F405400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
	},
	.SRI = {
		{{.SRI,            {.V_8B,  .V_8B,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F084400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRI,            {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F084400, 0xFFF8FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRI,            {.V_4H,  .V_4H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F104400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRI,            {.V_8H,  .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F104400, 0xFFF0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRI,            {.V_2S,  .V_2S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F204400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRI,            {.V_4S,  .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F204400, 0xFFE0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
		{{.SRI,            {.V_2D,  .V_2D,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F404400, 0xFFC0FC00, .NEON, {}},                                         {written={0}, read={0, 1}}},
	},
	.SSHLL = {
		{{.SSHLL,          {.V_8H, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F08A400, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.SSHLL,          {.V_4S, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F10A400, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.SSHLL,          {.V_2D, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F20A400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}}},
	},
	.SSHLL2 = {
		{{.SSHLL2,         {.V_8H, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F08A400, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}}},
		{{.SSHLL2,         {.V_4S, .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F10A400, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}}},
		{{.SSHLL2,         {.V_2D, .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F20A400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}}},
	},
	.USHLL = {
		{{.USHLL,          {.V_8H, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F08A400, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.USHLL,          {.V_4S, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F10A400, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.USHLL,          {.V_2D, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F20A400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}}},
	},
	.USHLL2 = {
		{{.USHLL2,         {.V_8H, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F08A400, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}}},
		{{.USHLL2,         {.V_4S, .V_8H,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F10A400, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}}},
		{{.USHLL2,         {.V_2D, .V_4S,  .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F20A400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}}},
	},
	.SXTL = {
		{{.SXTL,           {.V_8H, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0F08A400, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
		{{.SXTL,           {.V_4S, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0F10A400, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
		{{.SXTL,           {.V_2D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0F20A400, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
	},
	.SXTL2 = {
		{{.SXTL2,          {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4F08A400, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.SXTL2,          {.V_4S, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4F10A400, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.SXTL2,          {.V_2D, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4F20A400, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
	},
	.UXTL = {
		{{.UXTL,           {.V_8H, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2F08A400, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
		{{.UXTL,           {.V_4S, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2F10A400, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
		{{.UXTL,           {.V_2D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2F20A400, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
	},
	.UXTL2 = {
		{{.UXTL2,          {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6F08A400, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.UXTL2,          {.V_4S, .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6F10A400, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
		{{.UXTL2,          {.V_2D, .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6F20A400, 0xFFFFFC00, .NEON, {}},                                                       {written={0}, read={1}}},
	},
	.SHRN = {
		{{.SHRN,           {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F088400, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.SHRN,           {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F108400, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.SHRN,           {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F208400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}}},
	},
	.SHRN2 = {
		{{.SHRN2,          {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F088400, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}}},
		{{.SHRN2,          {.V_8H,  .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F108400, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}}},
		{{.SHRN2,          {.V_4S,  .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F208400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}}},
	},
	.RSHRN = {
		{{.RSHRN,          {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F088C00, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.RSHRN,          {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F108C00, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.RSHRN,          {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F208C00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}}},
	},
	.RSHRN2 = {
		{{.RSHRN2,         {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F088C00, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}}},
		{{.RSHRN2,         {.V_8H,  .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F108C00, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}}},
		{{.RSHRN2,         {.V_4S,  .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F208C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}}},
	},
	.SQSHRN = {
		{{.SQSHRN,         {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F089400, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHRN,         {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F109400, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHRN,         {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F209400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQSHRN2 = {
		{{.SQSHRN2,        {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F089400, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHRN2,        {.V_8H,  .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F109400, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHRN2,        {.V_4S,  .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F209400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.UQSHRN = {
		{{.UQSHRN,         {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F089400, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQSHRN,         {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F109400, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQSHRN,         {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F209400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.UQSHRN2 = {
		{{.UQSHRN2,        {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F089400, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQSHRN2,        {.V_8H,  .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F109400, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQSHRN2,        {.V_4S,  .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F209400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQRSHRN = {
		{{.SQRSHRN,        {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F089C00, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQRSHRN,        {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F109C00, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQRSHRN,        {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F209C00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQRSHRN2 = {
		{{.SQRSHRN2,       {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F089C00, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQRSHRN2,       {.V_8H,  .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F109C00, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQRSHRN2,       {.V_4S,  .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F209C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.UQRSHRN = {
		{{.UQRSHRN,        {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F089C00, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQRSHRN,        {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F109C00, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQRSHRN,        {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F209C00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.UQRSHRN2 = {
		{{.UQRSHRN2,       {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F089C00, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQRSHRN2,       {.V_8H,  .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F109C00, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.UQRSHRN2,       {.V_4S,  .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F209C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQSHRUN = {
		{{.SQSHRUN,        {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F088400, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHRUN,        {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F108400, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHRUN,        {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F208400, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQSHRUN2 = {
		{{.SQSHRUN2,       {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F088400, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHRUN2,       {.V_8H,  .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F108400, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQSHRUN2,       {.V_4S,  .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F208400, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQRSHRUN = {
		{{.SQRSHRUN,       {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F088C00, 0xFFF8FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQRSHRUN,       {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F108C00, 0xFFF0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQRSHRUN,       {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F208C00, 0xFFE0FC00, .NEON, {}},                                           {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.SQRSHRUN2 = {
		{{.SQRSHRUN2,      {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F088C00, 0xFFF8FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQRSHRUN2,      {.V_8H,  .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F108C00, 0xFFF0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
		{{.SQRSHRUN2,      {.V_4S,  .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F208C00, 0xFFE0FC00, .NEON, {}},                                          {written={0}, read={1}, fpsr_wr={.QC}}},
	},
	.DUP = {
		{{.DUP,            {.V_8B,    .V_ELEM_B, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x0E010400, 0xFFE1FC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_16B,   .V_ELEM_B, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x4E010400, 0xFFE1FC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_4H,    .V_ELEM_H, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x0E020400, 0xFFE3FC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_8H,    .V_ELEM_H, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x4E020400, 0xFFE3FC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_2S,    .V_ELEM_S, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x0E040400, 0xFFE7FC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_4S,    .V_ELEM_S, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x4E040400, 0xFFE7FC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_2D,    .V_ELEM_D, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x4E080400, 0xFFEFFC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_8B,    .W_REG,    .NONE,      .NONE}, {.VD, .RN, .NONE,      .NONE}, 0x0E010C00, 0xFFFFFC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_16B,   .W_REG,    .NONE,      .NONE}, {.VD, .RN, .NONE,      .NONE}, 0x4E010C00, 0xFFFFFC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_4H,    .W_REG,    .NONE,      .NONE}, {.VD, .RN, .NONE,      .NONE}, 0x0E020C00, 0xFFFFFC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_8H,    .W_REG,    .NONE,      .NONE}, {.VD, .RN, .NONE,      .NONE}, 0x4E020C00, 0xFFFFFC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_2S,    .W_REG,    .NONE,      .NONE}, {.VD, .RN, .NONE,      .NONE}, 0x0E040C00, 0xFFFFFC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_4S,    .W_REG,    .NONE,      .NONE}, {.VD, .RN, .NONE,      .NONE}, 0x4E040C00, 0xFFFFFC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.V_2D,    .X_REG,    .NONE,      .NONE}, {.VD, .RN, .NONE,      .NONE}, 0x4E080C00, 0xFFFFFC00, .NEON, {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.Z_REG_B, .W_REG,    .NONE,      .NONE}, {.VD, .VN, .NONE,      .NONE}, 0x05203800, 0xFFFFFC00, .SVE,  {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.Z_REG_H, .W_REG,    .NONE,      .NONE}, {.VD, .VN, .NONE,      .NONE}, 0x05603800, 0xFFFFFC00, .SVE,  {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.Z_REG_S, .W_REG,    .NONE,      .NONE}, {.VD, .VN, .NONE,      .NONE}, 0x05A03800, 0xFFFFFC00, .SVE,  {}},                                       {written={0}, read={1}}},
		{{.DUP,            {.Z_REG_D, .X_REG,    .NONE,      .NONE}, {.VD, .VN, .NONE,      .NONE}, 0x05E03800, 0xFFFFFC00, .SVE,  {is_64=true}},                             {written={0}, read={1}}},
	},
	.INS = {
		{{.INS,            {.V_ELEM_B, .VEC_INDEX, .V_ELEM_B, .VEC_INDEX}, {.VD, .NEON_IDX5, .VN, .NEON_IDX4}, 0x6E010400, 0xFFE18400, .NEON, {}},                            {written={0}, read={0, 2}}},
		{{.INS,            {.V_ELEM_H, .VEC_INDEX, .V_ELEM_H, .VEC_INDEX}, {.VD, .NEON_IDX5, .VN, .NEON_IDX4}, 0x6E020400, 0xFFE38C00, .NEON, {}},                            {written={0}, read={0, 2}}},
		{{.INS,            {.V_ELEM_S, .VEC_INDEX, .V_ELEM_S, .VEC_INDEX}, {.VD, .NEON_IDX5, .VN, .NEON_IDX4}, 0x6E040400, 0xFFE79C00, .NEON, {}},                            {written={0}, read={0, 2}}},
		{{.INS,            {.V_ELEM_D, .VEC_INDEX, .V_ELEM_D, .VEC_INDEX}, {.VD, .NEON_IDX5, .VN, .NEON_IDX4}, 0x6E080400, 0xFFEFBC00, .NEON, {}},                            {written={0}, read={0, 2}}},
		{{.INS,            {.V_ELEM_B, .VEC_INDEX, .W_REG,    .NONE},      {.VD, .NEON_IDX5, .RN, .NONE},      0x4E011C00, 0xFFE1FC00, .NEON, {}},                            {written={0}, read={0, 2}}},
		{{.INS,            {.V_ELEM_H, .VEC_INDEX, .W_REG,    .NONE},      {.VD, .NEON_IDX5, .RN, .NONE},      0x4E021C00, 0xFFE3FC00, .NEON, {}},                            {written={0}, read={0, 2}}},
		{{.INS,            {.V_ELEM_S, .VEC_INDEX, .W_REG,    .NONE},      {.VD, .NEON_IDX5, .RN, .NONE},      0x4E041C00, 0xFFE7FC00, .NEON, {}},                            {written={0}, read={0, 2}}},
		{{.INS,            {.V_ELEM_D, .VEC_INDEX, .X_REG,    .NONE},      {.VD, .NEON_IDX5, .RN, .NONE},      0x4E081C00, 0xFFEFFC00, .NEON, {}},                            {written={0}, read={0, 2}}},
	},
	.MOV = {
		{{.MOV,            {.V_8B,    .V_8B,        .NONE,    .NONE}, {.VD,        .VN_VM_DUP,     .NONE,      .NONE}, 0x0EA01C00, 0xFFE0FC00, .NEON, {}},                    {written={0}, read={1}}},
		{{.MOV,            {.V_16B,   .V_16B,       .NONE,    .NONE}, {.VD,        .VN_VM_DUP,     .NONE,      .NONE}, 0x4EA01C00, 0xFFE0FC00, .NEON, {}},                    {written={0}, read={1}}},
		{{.MOV,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.ZD_ZM_DUP, .PG,            .VN,        .NONE}, 0x0520C000, 0xFFE0E000, .SVE,  {}},                    {read={0, 1, 2}}},
		{{.MOV,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.ZD_ZM_DUP, .PG,            .VN,        .NONE}, 0x0560C000, 0xFFE0E000, .SVE,  {}},                    {read={0, 1, 2}}},
		{{.MOV,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.ZD_ZM_DUP, .PG,            .VN,        .NONE}, 0x05A0C000, 0xFFE0E000, .SVE,  {}},                    {read={0, 1, 2}}},
		{{.MOV,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.ZD_ZM_DUP, .PG,            .VN,        .NONE}, 0x05E0C000, 0xFFE0E000, .SVE,  {is_64=true}},          {read={0, 1, 2}}},
		{{.MOV,            {.P_REG,   .P_REG_ZERO,  .P_REG,   .NONE}, {.PD,        .PG4,           .PN_PM_DUP, .NONE}, 0x25004000, 0xFFE0C210, .SVE,  {}},                    {written={0}, read={1, 2}}},
		{{.MOV,            {.P_REG,   .P_REG,       .NONE,    .NONE}, {.PD,        .PN_PG_PM_DUP,  .NONE,      .NONE}, 0x25804000, 0xFFE0C210, .SVE,  {}},                    {written={0}, read={1}}},
		{{.MOV,            {.W_REG,   .W_REG,       .NONE,    .NONE}, {.RD,        .RM,            .NONE,      .NONE}, 0x2A0003E0, 0xFFE0FFE0, .BASE, {}},                    {written={0}, read={1}}},
		{{.MOV,            {.X_REG,   .X_REG,       .NONE,    .NONE}, {.RD,        .RM,            .NONE,      .NONE}, 0xAA0003E0, 0xFFE0FFE0, .BASE, {is_64=true}},          {written={0}, read={1}}},
		{{.MOV,            {.W_REG,   .BITMASK_IMM, .NONE,    .NONE}, {.RD,        .BITMASK_FIELD, .NONE,      .NONE}, 0x320003E0, 0xFFC003E0, .BASE, {}},                    {written={0}}},
		{{.MOV,            {.X_REG,   .BITMASK_IMM, .NONE,    .NONE}, {.RD,        .BITMASK_FIELD, .NONE,      .NONE}, 0xB20003E0, 0xFF8003E0, .BASE, {is_64=true}},          {written={0}}},
	},
	.EXT = {
		{{.EXT,            {.V_8B,    .V_8B,    .V_8B,    .VEC_INDEX}, {.VD, .VN, .VM, .NEON_EXT_IDX}, 0x2E000000, 0xFFE0C400, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.EXT,            {.V_16B,   .V_16B,   .V_16B,   .VEC_INDEX}, {.VD, .VN, .VM, .NEON_EXT_IDX}, 0x6E000000, 0xFFE08400, .NEON, {}},                                    {written={0}, read={1, 2}}},
		{{.EXT,            {.Z_REG_B, .Z_REG_B, .Z_REG_B, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_EXT_IMM},  0x05200000, 0xFFE0E000, .SVE,  {}},                                    {written={0}, read={1, 2}}},
		{{.EXT,            {.Z_REG_B, .Z_REG_B, .Z_REG_B, .IMM_8},     {.VD, .VD, .VM, .NONE},         0x05200000, 0xFFE0E000, .SVE,  {}},                                    {written={0}, read={1, 2}}},
	},
	.TBL = {
		{{.TBL,            {.V_8B,    .V_16B,   .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E000000, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TBL,            {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E000000, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TBL,            {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05203000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TBL,            {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05603000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TBL,            {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A03000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TBL,            {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E03000, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}}},
	},
	.TBX = {
		{{.TBX,            {.V_8B,    .V_16B,   .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E001000, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={0, 1, 2}}},
		{{.TBX,            {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E001000, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={0, 1, 2}}},
		{{.TBX,            {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05202C00, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={0, 1, 2}}},
	},
	.ZIP1 = {
		{{.ZIP1,           {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E003800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E003800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E403800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E403800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E803800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E803800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC03800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05206000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05606000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A06000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP1,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E06000, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}}},
		{{.ZIP1,           {.P_REG,   .P_REG,   .P_REG,   .NONE}, {.PD, .PN, .PM, .NONE}, 0x05204000, 0xFFE0FE10, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
	},
	.ZIP2 = {
		{{.ZIP2,           {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E007800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E007800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E407800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E407800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E807800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E807800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC07800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05206400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05606400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A06400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.ZIP2,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E06400, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}}},
		{{.ZIP2,           {.P_REG,   .P_REG,   .P_REG,   .NONE}, {.PD, .PN, .PM, .NONE}, 0x05204400, 0xFFE0FE10, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
	},
	.UZP1 = {
		{{.UZP1,           {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E001800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E001800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E401800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E401800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E801800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E801800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC01800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05206800, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05606800, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A06800, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP1,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E06800, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}}},
		{{.UZP1,           {.P_REG,   .P_REG,   .P_REG,   .NONE}, {.PD, .PN, .PM, .NONE}, 0x05204800, 0xFFE0FE10, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
	},
	.UZP2 = {
		{{.UZP2,           {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E005800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E005800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E405800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E405800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E805800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E805800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC05800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05206C00, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05606C00, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A06C00, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.UZP2,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E06C00, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}}},
		{{.UZP2,           {.P_REG,   .P_REG,   .P_REG,   .NONE}, {.PD, .PN, .PM, .NONE}, 0x05204C00, 0xFFE0FE10, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
	},
	.TRN1 = {
		{{.TRN1,           {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E002800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E002800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E402800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E402800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E802800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E802800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC02800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05207000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05607000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A07000, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN1,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E07000, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}}},
		{{.TRN1,           {.P_REG,   .P_REG,   .P_REG,   .NONE}, {.PD, .PN, .PM, .NONE}, 0x05205000, 0xFFE0FE10, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
	},
	.TRN2 = {
		{{.TRN2,           {.V_8B,    .V_8B,    .V_8B,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E006800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.V_16B,   .V_16B,   .V_16B,   .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E006800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.V_4H,    .V_4H,    .V_4H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E406800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.V_8H,    .V_8H,    .V_8H,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E406800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.V_2S,    .V_2S,    .V_2S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E806800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.V_4S,    .V_4S,    .V_4S,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E806800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.V_2D,    .V_2D,    .V_2D,    .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC06800, 0xFFE0FC00, .NEON, {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05207400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05607400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A07400, 0xFFE0FC00, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
		{{.TRN2,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E07400, 0xFFE0FC00, .SVE,  {is_64=true}},                                       {written={0}, read={1, 2}}},
		{{.TRN2,           {.P_REG,   .P_REG,   .P_REG,   .NONE}, {.PD, .PN, .PM, .NONE}, 0x05205400, 0xFFE0FE10, .SVE,  {}},                                                 {written={0}, read={1, 2}}},
	},
	.NOT = {
		{{.NOT,            {.V_8B,  .V_8B,       .NONE,  .NONE}, {.VD, .VN,         .NONE, .NONE}, 0x2E205800, 0xFFFFFC00, .NEON, {}},                                        {written={0}, read={1}}},
		{{.NOT,            {.V_16B, .V_16B,      .NONE,  .NONE}, {.VD, .VN,         .NONE, .NONE}, 0x6E205800, 0xFFFFFC00, .NEON, {}},                                        {written={0}, read={1}}},
		{{.NOT,            {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4_PM_DUP, .PN,   .NONE}, 0x25004200, 0xFFE0C210, .SVE,  {}},                                        {written={0}, read={1, 2}}},
	},
	.REV64 = {
		{{.REV64,          {.V_8B,  .V_8B,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E200800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV64,          {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E200800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV64,          {.V_4H,  .V_4H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E600800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV64,          {.V_8H,  .V_8H,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E600800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV64,          {.V_2S,  .V_2S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA00800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
		{{.REV64,          {.V_4S,  .V_4S,  .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA00800, 0xFFFFFC00, .NEON, {}},                                                      {written={0}, read={1}}},
	},
	.CNT = {
		{{.CNT,            {.V_8B,    .V_8B,        .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E205800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CNT,            {.V_16B,   .V_16B,       .NONE,    .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E205800, 0xFFFFFC00, .NEON, {}},                                           {written={0}, read={1}}},
		{{.CNT,            {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x041AA000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CNT,            {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x045AA000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CNT,            {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x049AA000, 0xFFE0E000, .SVE,  {}},                                           {written={0}, read={1, 2}}},
		{{.CNT,            {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN,   .NONE}, 0x04DAA000, 0xFFE0E000, .SVE,  {is_64=true}},                                 {written={0}, read={1, 2}}},
	},
	.URECPE = {
		{{.URECPE,         {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA1C800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
		{{.URECPE,         {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA1C800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
	},
	.URSQRTE = {
		{{.URSQRTE,        {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1C800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
		{{.URSQRTE,        {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1C800, 0xFFFFFC00, .NEON, {}},                                                        {written={0}, read={1}}},
	},
	.MOVI = {
		{{.MOVI,           {.V_8B,  .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x0F00E400, 0xFFF8FC00, .NEON, {}},                                          {written={0}}},
		{{.MOVI,           {.V_16B, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x4F00E400, 0xFFF8FC00, .NEON, {}},                                          {written={0}}},
		{{.MOVI,           {.V_4H,  .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x0F008400, 0xFFF8FC00, .NEON, {}},                                          {written={0}}},
		{{.MOVI,           {.V_8H,  .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x4F008400, 0xFFF8FC00, .NEON, {}},                                          {written={0}}},
		{{.MOVI,           {.V_2S,  .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x0F000400, 0xFFF8FC00, .NEON, {}},                                          {written={0}}},
		{{.MOVI,           {.V_4S,  .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x4F000400, 0xFFF8FC00, .NEON, {}},                                          {written={0}}},
		{{.MOVI,           {.V_2D,  .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x6F00E400, 0xFFF8FC00, .NEON, {}},                                          {written={0}}},
	},
	.MVNI = {
		{{.MVNI,           {.V_4H, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x2F008400, 0xFFF8FC00, .NEON, {}},                                           {written={0}}},
		{{.MVNI,           {.V_8H, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x6F008400, 0xFFF8FC00, .NEON, {}},                                           {written={0}}},
		{{.MVNI,           {.V_2S, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x2F000400, 0xFFF8FC00, .NEON, {}},                                           {written={0}}},
		{{.MVNI,           {.V_4S, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x6F000400, 0xFFF8FC00, .NEON, {}},                                           {written={0}}},
	},
	.LD1 = {
		{{.LD1,            {.V_16B,    .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C407000, 0xFFFFF000, .NEON, {}},                    {written={0}, read={1}, reads_mem=true}},
		{{.LD1,            {.V_8H,     .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C407400, 0xFFFFF400, .NEON, {}},                    {written={0}, read={1}, reads_mem=true}},
		{{.LD1,            {.V_4S,     .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C407800, 0xFFFFF800, .NEON, {}},                    {written={0}, read={1}, reads_mem=true}},
		{{.LD1,            {.V_2D,     .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C407C00, 0xFFFFFC00, .NEON, {}},                    {written={0}, read={1}, reads_mem=true}},
		{{.LD1,            {.V_ELEM_B, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_B,   .OFFSET_BASE_A, .NONE}, 0x0D400000, 0xBFFFE000, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD1,            {.V_ELEM_H, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_H,   .OFFSET_BASE_A, .NONE}, 0x0D404000, 0xBFFFE400, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD1,            {.V_ELEM_S, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_S,   .OFFSET_BASE_A, .NONE}, 0x0D408000, 0xBFFFEC00, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD1,            {.V_ELEM_D, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_D,   .OFFSET_BASE_A, .NONE}, 0x0D408400, 0xBFFFFC00, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
	},
	.LD2 = {
		{{.LD2,            {.V_16B,    .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C408000, 0xFFFFFC00, .NEON, {}},                    {written={0}, read={1}, reads_mem=true}},
		{{.LD2,            {.V_ELEM_B, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_B,   .OFFSET_BASE_A, .NONE}, 0x0D600000, 0xBFFFE000, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD2,            {.V_ELEM_H, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_H,   .OFFSET_BASE_A, .NONE}, 0x0D604000, 0xBFFFE400, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD2,            {.V_ELEM_S, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_S,   .OFFSET_BASE_A, .NONE}, 0x0D608000, 0xBFFFEC00, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD2,            {.V_ELEM_D, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_D,   .OFFSET_BASE_A, .NONE}, 0x0D608400, 0xBFFFFC00, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
	},
	.LD3 = {
		{{.LD3,            {.V_16B,    .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C404000, 0xFFFFFC00, .NEON, {}},                    {written={0}, read={1}, reads_mem=true}},
		{{.LD3,            {.V_ELEM_B, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_B,   .OFFSET_BASE_A, .NONE}, 0x0D402000, 0xBFFFE000, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD3,            {.V_ELEM_H, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_H,   .OFFSET_BASE_A, .NONE}, 0x0D406000, 0xBFFFE400, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD3,            {.V_ELEM_S, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_S,   .OFFSET_BASE_A, .NONE}, 0x0D40A000, 0xBFFFEC00, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD3,            {.V_ELEM_D, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_D,   .OFFSET_BASE_A, .NONE}, 0x0D40A400, 0xBFFFFC00, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
	},
	.LD4 = {
		{{.LD4,            {.V_16B,    .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C400000, 0xFFFFFC00, .NEON, {}},                    {written={0}, read={1}, reads_mem=true}},
		{{.LD4,            {.V_ELEM_B, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_B,   .OFFSET_BASE_A, .NONE}, 0x0D602000, 0xBFFFE000, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD4,            {.V_ELEM_H, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_H,   .OFFSET_BASE_A, .NONE}, 0x0D606000, 0xBFFFE400, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD4,            {.V_ELEM_S, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_S,   .OFFSET_BASE_A, .NONE}, 0x0D60A000, 0xBFFFEC00, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
		{{.LD4,            {.V_ELEM_D, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_D,   .OFFSET_BASE_A, .NONE}, 0x0D60A400, 0xBFFFFC00, .NEON, {}},                    {written={0}, read={2}, reads_mem=true}},
	},
	.ST1 = {
		{{.ST1,            {.V_16B,    .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C007000, 0xFFFFF000, .NEON, {}},                    {read={0, 1}, writes_mem=true}},
		{{.ST1,            {.V_8H,     .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C007400, 0xFFFFF400, .NEON, {}},                    {read={0, 1}, writes_mem=true}},
		{{.ST1,            {.V_4S,     .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C007800, 0xFFFFF800, .NEON, {}},                    {read={0, 1}, writes_mem=true}},
		{{.ST1,            {.V_2D,     .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C007C00, 0xFFFFFC00, .NEON, {}},                    {read={0, 1}, writes_mem=true}},
		{{.ST1,            {.V_ELEM_B, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_B,   .OFFSET_BASE_A, .NONE}, 0x0D000000, 0xBFFFE000, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST1,            {.V_ELEM_H, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_H,   .OFFSET_BASE_A, .NONE}, 0x0D004000, 0xBFFFE400, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST1,            {.V_ELEM_S, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_S,   .OFFSET_BASE_A, .NONE}, 0x0D008000, 0xBFFFEC00, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST1,            {.V_ELEM_D, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_D,   .OFFSET_BASE_A, .NONE}, 0x0D008400, 0xBFFFFC00, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
	},
	.ST2 = {
		{{.ST2,            {.V_16B,    .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C008000, 0xFFFFFC00, .NEON, {}},                    {read={0, 1}, writes_mem=true}},
		{{.ST2,            {.V_ELEM_B, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_B,   .OFFSET_BASE_A, .NONE}, 0x0D200000, 0xBFFFE000, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST2,            {.V_ELEM_H, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_H,   .OFFSET_BASE_A, .NONE}, 0x0D204000, 0xBFFFE400, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST2,            {.V_ELEM_S, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_S,   .OFFSET_BASE_A, .NONE}, 0x0D208000, 0xBFFFEC00, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST2,            {.V_ELEM_D, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_D,   .OFFSET_BASE_A, .NONE}, 0x0D208400, 0xBFFFFC00, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
	},
	.ST3 = {
		{{.ST3,            {.V_16B,    .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C004000, 0xFFFFFC00, .NEON, {}},                    {read={0, 1}, writes_mem=true}},
		{{.ST3,            {.V_ELEM_B, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_B,   .OFFSET_BASE_A, .NONE}, 0x0D002000, 0xBFFFE000, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST3,            {.V_ELEM_H, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_H,   .OFFSET_BASE_A, .NONE}, 0x0D006000, 0xBFFFE400, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST3,            {.V_ELEM_S, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_S,   .OFFSET_BASE_A, .NONE}, 0x0D00A000, 0xBFFFEC00, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST3,            {.V_ELEM_D, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_D,   .OFFSET_BASE_A, .NONE}, 0x0D00A400, 0xBFFFFC00, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
	},
	.ST4 = {
		{{.ST4,            {.V_16B,    .MEM_OFFSET, .NONE,       .NONE}, {.VD, .OFFSET_BASE_A, .NONE,          .NONE}, 0x4C000000, 0xFFFFFC00, .NEON, {}},                    {read={0, 1}, writes_mem=true}},
		{{.ST4,            {.V_ELEM_B, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_B,   .OFFSET_BASE_A, .NONE}, 0x0D202000, 0xBFFFE000, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST4,            {.V_ELEM_H, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_H,   .OFFSET_BASE_A, .NONE}, 0x0D206000, 0xBFFFE400, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST4,            {.V_ELEM_S, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_S,   .OFFSET_BASE_A, .NONE}, 0x0D20A000, 0xBFFFEC00, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
		{{.ST4,            {.V_ELEM_D, .VEC_INDEX,  .MEM_OFFSET, .NONE}, {.VD, .NEON_LANE_D,   .OFFSET_BASE_A, .NONE}, 0x0D20A400, 0xBFFFFC00, .NEON, {}},                    {read={0, 2}, writes_mem=true}},
	},
	.LD1R = {
		{{.LD1R,           {.V_16B, .MEM_OFFSET, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4D40C000, 0xFFFFFC00, .NEON, {}},                                      {written={0}, read={1}, reads_mem=true}},
	},
	.LD2R = {
		{{.LD2R,           {.V_16B, .MEM_OFFSET, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4D60C000, 0xFFFFFC00, .NEON, {}},                                      {written={0}, read={1}, reads_mem=true}},
	},
	.LD3R = {
		{{.LD3R,           {.V_16B, .MEM_OFFSET, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4D40E000, 0xFFFFFC00, .NEON, {}},                                      {written={0}, read={1}, reads_mem=true}},
	},
	.LD4R = {
		{{.LD4R,           {.V_16B, .MEM_OFFSET, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4D60E000, 0xFFFFFC00, .NEON, {}},                                      {written={0}, read={1}, reads_mem=true}},
	},
	.SUBR = {
		{{.SUBR,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04030000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.SUBR,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04430000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.SUBR,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04830000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.SUBR,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04C30000, 0xFFE0E000, .SVE, {is_64=true}},                                   {written={0}, read={1, 2, 3}}},
	},
	.ASRR = {
		{{.ASRR,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VN}, 0x04148000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.ASRR,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x04548000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.ASRR,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x04948000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.ASRR,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x04D48000, 0xFFFFE000, .SVE, {is_64=true}},                                   {written={0}, read={1, 2, 3}}},
	},
	.LSLR = {
		{{.LSLR,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VN}, 0x04178000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.LSLR,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x04578000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.LSLR,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x04978000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.LSLR,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x04D78000, 0xFFFFE000, .SVE, {is_64=true}},                                   {written={0}, read={1, 2, 3}}},
	},
	.LSRR = {
		{{.LSRR,           {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VN}, 0x04158000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.LSRR,           {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x04558000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.LSRR,           {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x04958000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.LSRR,           {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x04D58000, 0xFFFFE000, .SVE, {is_64=true}},                                   {written={0}, read={1, 2, 3}}},
	},
	.FTSMUL = {
		{{.FTSMUL,         {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65400C00, 0xFFE0FC00, .SVE, {}},                                                  {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FTSMUL,         {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65800C00, 0xFFE0FC00, .SVE, {}},                                                  {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FTSMUL,         {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C00C00, 0xFFE0FC00, .SVE, {is_64=true}},                                        {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FSUBR = {
		{{.FSUBR,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x65438000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUBR,          {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x65838000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FSUBR,          {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x65C38000, 0xFFFFE000, .SVE, {is_64=true}},                                   {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FDIVR = {
		{{.FDIVR,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x654C8000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIVR,          {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x658C8000, 0xFFFFE000, .SVE, {}},                                             {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FDIVR,          {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x65CC8000, 0xFFFFE000, .SVE, {is_64=true}},                                   {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .DZC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FNMLA = {
		{{.FNMLA,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65604000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={0, 1, 2, 3}}},
		{{.FNMLA,          {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM}, 0x65A04000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={0, 1, 2, 3}}},
		{{.FNMLA,          {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM}, 0x65E04000, 0xFFE0E000, .SVE, {is_64=true}},                                   {written={0}, read={0, 1, 2, 3}}},
	},
	.FNMLS = {
		{{.FNMLS,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65606000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={0, 1, 2, 3}}},
		{{.FNMLS,          {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM}, 0x65A06000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={0, 1, 2, 3}}},
		{{.FNMLS,          {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM}, 0x65E06000, 0xFFE0E000, .SVE, {is_64=true}},                                   {written={0}, read={0, 1, 2, 3}}},
	},
	.NAND = {
		{{.NAND,           {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25804210, 0xFFE0C210, .SVE, {}},                                                   {written={0}, read={1, 2, 3}}},
	},
	.NOR = {
		{{.NOR,            {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25804200, 0xFFE0C210, .SVE, {}},                                                   {written={0}, read={1, 2, 3}}},
	},
	.SEL = {
		{{.SEL,            {.P_REG, .P_REG, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25004210, 0xFFE0C210, .SVE, {}},                                                        {written={0}, read={1, 2, 3}}},
	},
	.ORRS = {
		{{.ORRS,           {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25C04000, 0xFFE0C210, .SVE, {sets_flags=true}},                                    {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.EORS = {
		{{.EORS,           {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25404200, 0xFFE0C210, .SVE, {sets_flags=true}},                                    {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.NANDS = {
		{{.NANDS,          {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25C04210, 0xFFF0C210, .SVE, {sets_flags=true}},                                    {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.NORS = {
		{{.NORS,           {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25C04200, 0xFFF0C210, .SVE, {sets_flags=true}},                                    {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.ORNS = {
		{{.ORNS,           {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25C04010, 0xFFF0C210, .SVE, {sets_flags=true}},                                    {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.MOVS = {
		{{.MOVS,           {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4, .PN_PM_DUP, .NONE}, 0x25404000, 0xFFE0C210, .SVE, {sets_flags=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.PTRUE = {
		{{.PTRUE,          {.P_REG, .SVE_PATTERN, .NONE, .NONE}, {.PD, .SVE_PATTERN, .NONE, .NONE}, 0x2518E000, 0xFFFFFC10, .SVE, {}},                                        {written={0}}},
	},
	.PTRUES = {
		{{.PTRUES,         {.P_REG, .SVE_PATTERN, .NONE, .NONE}, {.PD, .SVE_PATTERN, .NONE, .NONE}, 0x2519E000, 0xFFFFFC10, .SVE, {sets_flags=true}},                         {written={0}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.PFALSE = {
		{{.PFALSE,         {.P_REG, .NONE, .NONE, .NONE}, {.PD, .NONE, .NONE, .NONE}, 0x2518E400, 0xFFFFFFF0, .SVE, {}},                                                      {written={0}}},
	},
	.PFIRST = {
		{{.PFIRST,         {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PD, .NONE}, 0x2558C000, 0xFFFFFE10, .SVE, {}},                                                        {written={0}, read={1, 2}}},
	},
	.PNEXT = {
		{{.PNEXT,          {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PD, .NONE}, 0x2519C400, 0xFFFFFE10, .SVE, {}},                                                        {written={0}, read={1, 2}}},
	},
	.BRKA = {
		{{.BRKA,           {.P_REG, .P_REG_MERGE, .P_REG, .NONE}, {.PD, .PG4, .PN, .NONE}, 0x25104010, 0xFFFFC210, .SVE, {}},                                                 {written={0}, read={1, 2}}},
	},
	.BRKB = {
		{{.BRKB,           {.P_REG, .P_REG_MERGE, .P_REG, .NONE}, {.PD, .PG4, .PN, .NONE}, 0x25904010, 0xFFFFC210, .SVE, {}},                                                 {written={0}, read={1, 2}}},
	},
	.BRKAS = {
		{{.BRKAS,          {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4, .PN, .NONE}, 0x25504000, 0xFFFFC210, .SVE, {sets_flags=true}},                                   {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.BRKBS = {
		{{.BRKBS,          {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4, .PN, .NONE}, 0x25D04000, 0xFFFFC210, .SVE, {sets_flags=true}},                                   {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.BRKPA = {
		{{.BRKPA,          {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x2500C000, 0xFFF0C210, .SVE, {}},                                                   {written={0}, read={1, 2, 3}}},
	},
	.BRKPB = {
		{{.BRKPB,          {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x2500C010, 0xFFF0C210, .SVE, {}},                                                   {written={0}, read={1, 2, 3}}},
	},
	.BRKN = {
		{{.BRKN,           {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PD}, 0x25184000, 0xFFFFC210, .SVE, {}},                                                   {written={0}, read={1, 2, 3}}},
	},
	.RDFFR = {
		{{.RDFFR,          {.P_REG, .NONE, .NONE, .NONE}, {.PD, .NONE, .NONE, .NONE}, 0x2519F000, 0xFFFFFFF0, .SVE, {}},                                                      {written={0}, side_effects={.FFR}}},
	},
	.WRFFR = {
		{{.WRFFR,          {.P_REG, .NONE, .NONE, .NONE}, {.PN, .NONE, .NONE, .NONE}, 0x25289000, 0xFFFFFE1F, .SVE, {}},                                                      {read={0}, side_effects={.FFR}}},
	},
	.SETFFR = {
		{{.SETFFR,         {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x252C9000, 0xFFFFFFFF, .SVE, {}},                                                     {side_effects={.FFR}}},
	},
	.CMPEQ = {
		{{.CMPEQ,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x2400A000, 0xFFE0E000, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPEQ,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x2440A000, 0xFFE0E000, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPEQ,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x2480A000, 0xFFE0E000, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPEQ,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C0A000, 0xFFE0E000, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPNE = {
		{{.CMPNE,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x2400A010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPNE,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x2440A010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPNE,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x2480A010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPNE,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C0A010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPGE = {
		{{.CMPGE,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x24008000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPGE,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x24408000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPGE,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x24808000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPGE,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C08000, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPGT = {
		{{.CMPGT,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x24008010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPGT,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x24408010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPGT,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x24808010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPGT,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C08010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPLE = {
		{{.CMPLE,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VM, .VN}, 0x24008000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLE,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VM, .VN}, 0x24408000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLE,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VM, .VN}, 0x24808000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLE,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VM, .VN}, 0x24C08000, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPLT = {
		{{.CMPLT,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VM, .VN}, 0x24008010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLT,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VM, .VN}, 0x24408010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLT,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VM, .VN}, 0x24808010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLT,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VM, .VN}, 0x24C08010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPHI = {
		{{.CMPHI,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x24000010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPHI,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x24400010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPHI,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x24800010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPHI,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C00010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPHS = {
		{{.CMPHS,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x24000000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPHS,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x24400000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPHS,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x24800000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPHS,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C00000, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPLO = {
		{{.CMPLO,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VM, .VN}, 0x24000010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLO,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VM, .VN}, 0x24400010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLO,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VM, .VN}, 0x24800010, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLO,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VM, .VN}, 0x24C00010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMPLS = {
		{{.CMPLS,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VM, .VN}, 0x24000000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLS,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VM, .VN}, 0x24400000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLS,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VM, .VN}, 0x24800000, 0xFFE0E010, .SVE, {sets_flags=true}},                                 {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMPLS,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VM, .VN}, 0x24C00000, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},                     {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.FCMNE = {
		{{.FCMNE,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x65406010, 0xFFE0E010, .SVE, {}},                                                {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMNE,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x65806010, 0xFFE0E010, .SVE, {}},                                                {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMNE,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x65C06010, 0xFFE0E010, .SVE, {is_64=true}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
	},
	.FCMUO = {
		{{.FCMUO,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x6540C000, 0xFFE0E010, .SVE, {}},                                                {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMUO,          {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x6580C000, 0xFFE0E010, .SVE, {}},                                                {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
		{{.FCMUO,          {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x65C0C000, 0xFFE0E010, .SVE, {is_64=true}},                                      {written={0}, read={1, 2, 3}, fpsr_wr={.IOC}}},
	},
	.INSR = {
		{{.INSR,           {.Z_REG_B, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05243800, 0xFFFFFC00, .SVE, {}},                                                     {written={0}, read={1}}},
		{{.INSR,           {.Z_REG_H, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05643800, 0xFFFFFC00, .SVE, {}},                                                     {written={0}, read={1}}},
		{{.INSR,           {.Z_REG_S, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05A43800, 0xFFFFFC00, .SVE, {}},                                                     {written={0}, read={1}}},
		{{.INSR,           {.Z_REG_D, .X_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05E43800, 0xFFFFFC00, .SVE, {is_64=true}},                                           {written={0}, read={1}}},
	},
	.CPY = {
		{{.CPY,            {.Z_REG_B, .P_REG_MERGE, .W_REG, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0528A000, 0xFFFFE000, .SVE, {}},                                                {written={0}, read={1, 2}}},
		{{.CPY,            {.Z_REG_H, .P_REG_MERGE, .W_REG, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0568A000, 0xFFFFE000, .SVE, {}},                                                {written={0}, read={1, 2}}},
		{{.CPY,            {.Z_REG_S, .P_REG_MERGE, .W_REG, .NONE}, {.VD, .PG, .VN, .NONE}, 0x05A8A000, 0xFFFFE000, .SVE, {}},                                                {written={0}, read={1, 2}}},
		{{.CPY,            {.Z_REG_D, .P_REG_MERGE, .X_REG, .NONE}, {.VD, .PG, .VN, .NONE}, 0x05E8A000, 0xFFFFE000, .SVE, {is_64=true}},                                      {written={0}, read={1, 2}}},
	},
	.COMPACT = {
		{{.COMPACT,        {.Z_REG_S, .P_REG_GOV, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x05A18000, 0xFFFFE000, .SVE, {}},                                                {written={0}, read={1, 2}}},
		{{.COMPACT,        {.Z_REG_D, .P_REG_GOV, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x05E18000, 0xFFFFE000, .SVE, {is_64=true}},                                      {written={0}, read={1, 2}}},
	},
	.LD1B = {
		{{.LD1B,           {.Z_REG_B,     .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA4004000, 0xFFE0E000, .SVE, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1B,           {.Z_REG_S,     .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x84004000, 0xFFA0E000, .SVE, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1B,           {.Z_REG_D,     .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC4004000, 0xFFA0E000, .SVE, {is_64=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1B,           {.SME_SLICE_B, .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.SME_SLICE_B,   .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE0000000, 0xFFE00010, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1B,           {.Z_PAIR,      .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0000000, 0xFFE0E000, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1B,           {.Z_QUAD,      .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0008000, 0xFFE0E000, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LD1H = {
		{{.LD1H,           {.Z_REG_H,     .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA4A04000, 0xFFE0E000, .SVE, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1H,           {.Z_REG_S,     .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x84804000, 0xFFA0E000, .SVE, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1H,           {.Z_REG_D,     .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC4804000, 0xFFA0E000, .SVE, {is_64=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1H,           {.SME_SLICE_H, .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.SME_SLICE_H,   .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE0400000, 0xFFE00010, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1H,           {.Z_PAIR,      .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0002000, 0xFFE0E000, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1H,           {.Z_QUAD,      .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA000A000, 0xFFE0E000, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LD1W = {
		{{.LD1W,           {.Z_REG_S,     .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA5404000, 0xFFE0E000, .SVE, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1W,           {.Z_REG_S,     .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x85004000, 0xFFA0E000, .SVE, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1W,           {.Z_REG_D,     .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC5004000, 0xFFA0E000, .SVE, {is_64=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1W,           {.SME_SLICE_W, .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.SME_SLICE_W,   .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE0800000, 0xFFE00010, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1W,           {.Z_PAIR,      .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0004000, 0xFFE0E000, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1W,           {.Z_QUAD,      .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA000C000, 0xFFE0E000, .SME, {}},           {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LD1D = {
		{{.LD1D,           {.Z_REG_D,     .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA5E04000, 0xFFE0E000, .SVE, {is_64=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1D,           {.Z_REG_D,     .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC5804000, 0xFFA0E000, .SVE, {is_64=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1D,           {.SME_SLICE_D, .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.SME_SLICE_D,   .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE0C00000, 0xFFE00010, .SME, {is_64=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1D,           {.Z_PAIR,      .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0006000, 0xFFE0E000, .SME, {is_64=true}}, {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1D,           {.Z_QUAD,      .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA000E000, 0xFFE0E000, .SME, {is_64=true}}, {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LD1SB = {
		{{.LD1SB,          {.Z_REG_H, .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA5C04000, 0xFFE0E000, .SVE, {}},                          {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1SB,          {.Z_REG_S, .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x84000000, 0xFFA0E000, .SVE, {}},                          {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1SB,          {.Z_REG_D, .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC4000000, 0xFFA0E000, .SVE, {is_64=true}},                {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LD1SH = {
		{{.LD1SH,          {.Z_REG_S, .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA5004000, 0xFFE0E000, .SVE, {}},                          {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1SH,          {.Z_REG_S, .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x84800000, 0xFFA0E000, .SVE, {}},                          {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1SH,          {.Z_REG_D, .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC4800000, 0xFFA0E000, .SVE, {is_64=true}},                {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LD1SW = {
		{{.LD1SW,          {.Z_REG_D, .P_REG_ZERO, .MEM_SVE_SS,  .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA4804000, 0xFFE0E000, .SVE, {is_64=true}},                {written={0}, read={1, 2}, reads_mem=true}},
		{{.LD1SW,          {.Z_REG_D, .P_REG_ZERO, .MEM_SVE_VEC, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC5000000, 0xFFA0E000, .SVE, {is_64=true}},                {written={0}, read={1, 2}, reads_mem=true}},
	},
	.ST1B = {
		{{.ST1B,           {.Z_REG_B,     .P_REG, .MEM_SVE_SS,  .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE4004000, 0xFFE0E000, .SVE, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1B,           {.Z_REG_S,     .P_REG, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE4008000, 0xFFA0E000, .SVE, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1B,           {.Z_REG_D,     .P_REG, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE4008000, 0xFFA0E000, .SVE, {is_64=true}},      {read={0, 1, 2}, writes_mem=true}},
		{{.ST1B,           {.SME_SLICE_B, .P_REG, .MEM_SVE_SS,  .NONE}, {.SME_SLICE_B,   .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE0200000, 0xFFE00010, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1B,           {.Z_PAIR,      .P_REG, .MEM_SVE_SS,  .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0200000, 0xFFE0E000, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1B,           {.Z_QUAD,      .P_REG, .MEM_SVE_SS,  .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0208000, 0xFFE0E000, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
	},
	.ST1H = {
		{{.ST1H,           {.Z_REG_H,     .P_REG, .MEM_SVE_SS,  .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE4A04000, 0xFFE0E000, .SVE, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1H,           {.Z_REG_S,     .P_REG, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE4808000, 0xFFA0E000, .SVE, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1H,           {.Z_REG_D,     .P_REG, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE4808000, 0xFFA0E000, .SVE, {is_64=true}},      {read={0, 1, 2}, writes_mem=true}},
		{{.ST1H,           {.SME_SLICE_H, .P_REG, .MEM_SVE_SS,  .NONE}, {.SME_SLICE_H,   .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE0600000, 0xFFE00010, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1H,           {.Z_PAIR,      .P_REG, .MEM_SVE_SS,  .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0202000, 0xFFE0E000, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1H,           {.Z_QUAD,      .P_REG, .MEM_SVE_SS,  .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA020A000, 0xFFE0E000, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
	},
	.ST1W = {
		{{.ST1W,           {.Z_REG_S,     .P_REG, .MEM_SVE_SS,  .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE5404000, 0xFFE0E000, .SVE, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1W,           {.Z_REG_S,     .P_REG, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE5008000, 0xFFA0E000, .SVE, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1W,           {.Z_REG_D,     .P_REG, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE5008000, 0xFFA0E000, .SVE, {is_64=true}},      {read={0, 1, 2}, writes_mem=true}},
		{{.ST1W,           {.SME_SLICE_W, .P_REG, .MEM_SVE_SS,  .NONE}, {.SME_SLICE_W,   .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE0A00000, 0xFFE00010, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1W,           {.Z_PAIR,      .P_REG, .MEM_SVE_SS,  .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0204000, 0xFFE0E000, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
		{{.ST1W,           {.Z_QUAD,      .P_REG, .MEM_SVE_SS,  .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA020C000, 0xFFE0E000, .SME, {}},                {read={0, 1, 2}, writes_mem=true}},
	},
	.ST1D = {
		{{.ST1D,           {.Z_REG_D,     .P_REG, .MEM_SVE_SS,  .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE5C04000, 0xFFE0E000, .SVE, {is_64=true}},      {read={0, 1, 2}, writes_mem=true}},
		{{.ST1D,           {.Z_REG_D,     .P_REG, .MEM_SVE_VEC, .NONE}, {.VD,            .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE5808000, 0xFFA0E000, .SVE, {is_64=true}},      {read={0, 1, 2}, writes_mem=true}},
		{{.ST1D,           {.SME_SLICE_D, .P_REG, .MEM_SVE_SS,  .NONE}, {.SME_SLICE_D,   .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xE0E00000, 0xFFE00010, .SME, {is_64=true}},      {read={0, 1, 2}, writes_mem=true}},
		{{.ST1D,           {.Z_PAIR,      .P_REG, .MEM_SVE_SS,  .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA0206000, 0xFFE0E000, .SME, {is_64=true}},      {read={0, 1, 2}, writes_mem=true}},
		{{.ST1D,           {.Z_QUAD,      .P_REG, .MEM_SVE_SS,  .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS,  .NONE}, 0xA020E000, 0xFFE0E000, .SME, {is_64=true}},      {read={0, 1, 2}, writes_mem=true}},
	},
	.LDFF1B = {
		{{.LDFF1B,         {.Z_REG_B, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA4006000, 0xFFE0E000, .SVE, {}},                            {written={0}, read={1, 2}, reads_mem=true, side_effects={.FFR}}},
	},
	.LDFF1H = {
		{{.LDFF1H,         {.Z_REG_H, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA4A06000, 0xFFE0E000, .SVE, {}},                            {written={0}, read={1, 2}, reads_mem=true, side_effects={.FFR}}},
	},
	.LDFF1W = {
		{{.LDFF1W,         {.Z_REG_S, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA5406000, 0xFFE0E000, .SVE, {}},                            {written={0}, read={1, 2}, reads_mem=true, side_effects={.FFR}}},
	},
	.LDFF1D = {
		{{.LDFF1D,         {.Z_REG_D, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA5E06000, 0xFFE0E000, .SVE, {is_64=true}},                  {written={0}, read={1, 2}, reads_mem=true, side_effects={.FFR}}},
	},
	.WHILEGE = {
		{{.WHILEGE,        {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201000, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.WHILEGT = {
		{{.WHILEGT,        {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201010, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.WHILELE = {
		{{.WHILELE,        {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201410, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.WHILELT = {
		{{.WHILELT,        {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201400, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.WHILEHI = {
		{{.WHILEHI,        {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201810, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.WHILEHS = {
		{{.WHILEHS,        {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201800, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.WHILELO = {
		{{.WHILELO,        {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201C00, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.WHILELS = {
		{{.WHILELS,        {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201C10, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.SQRDMLAH = {
		{{.SQRDMLAH,       {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44007000, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMLAH,       {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44407000, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMLAH,       {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44807000, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMLAH,       {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44C07000, 0xFFE0FC00, .SVE2, {is_64=true}},                                       {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
	},
	.SQRDMLSH = {
		{{.SQRDMLSH,       {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44007400, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMLSH,       {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44407400, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMLSH,       {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44807400, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
		{{.SQRDMLSH,       {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44C07400, 0xFFE0FC00, .SVE2, {is_64=true}},                                       {written={0}, read={0, 1, 2}, fpsr_wr={.QC}}},
	},
	.ADCLB = {
		{{.ADCLB,          {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4500D000, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={1, 2}}},
		{{.ADCLB,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4540D000, 0xFFE0FC00, .SVE2, {is_64=true}},                                       {written={0}, read={1, 2}}},
	},
	.ADCLT = {
		{{.ADCLT,          {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4500D400, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={1, 2}}},
		{{.ADCLT,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4540D400, 0xFFE0FC00, .SVE2, {is_64=true}},                                       {written={0}, read={1, 2}}},
	},
	.SBCLB = {
		{{.SBCLB,          {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4580D000, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={1, 2}}},
		{{.SBCLB,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x45C0D000, 0xFFE0FC00, .SVE2, {is_64=true}},                                       {written={0}, read={1, 2}}},
	},
	.SBCLT = {
		{{.SBCLT,          {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4580D400, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={1, 2}}},
		{{.SBCLT,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x45C0D400, 0xFFE0FC00, .SVE2, {is_64=true}},                                       {written={0}, read={1, 2}}},
	},
	.TBL2 = {
		{{.TBL2,           {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05202800, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={1, 2}}},
	},
	.MATCH = {
		{{.MATCH,          {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x45208000, 0xFFE0E010, .SVE2, {sets_flags=true}},                                {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.MATCH,          {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x45608000, 0xFFE0E010, .SVE2, {sets_flags=true}},                                {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.NMATCH = {
		{{.NMATCH,         {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x45208010, 0xFFE0E010, .SVE2, {sets_flags=true}},                                {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.NMATCH,         {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x45608010, 0xFFE0E010, .SVE2, {sets_flags=true}},                                {written={0}, read={1, 2, 3}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.HISTCNT = {
		{{.HISTCNT,        {.Z_REG_S, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM}, 0x45A0C000, 0xFFE0E000, .SVE2, {}},                                             {written={0}, read={1, 2, 3}}},
		{{.HISTCNT,        {.Z_REG_D, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM}, 0x45E0C000, 0xFFE0E000, .SVE2, {is_64=true}},                                   {written={0}, read={1, 2, 3}}},
	},
	.HISTSEG = {
		{{.HISTSEG,        {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4520A000, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={1, 2}}},
	},
	.SMSTART = {
		{{.SMSTART,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503477F, 0xFFFFFFFF, .SME, {}},                                                     {}},
	},
	.SMSTOP = {
		{{.SMSTOP,         {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503467F, 0xFFFFFFFF, .SME, {}},                                                     {}},
	},
	.RDSVL = {
		{{.RDSVL,          {.X_REG, .IMM_6, .NONE, .NONE}, {.RD, .ENC_IMM6_LO, .NONE, .NONE}, 0x04BF5800, 0xFFFFF800, .SME, {is_64=true}},                                    {written={0}}},
	},
	.ADDHA = {
		{{.ADDHA,          {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_S}, {.ZA_TILE_LOW, .PG, .PM3, .VN}, 0xC0900000, 0xFFFF001C, .SME, {}},                             {written={0}, read={0, 1, 2, 3}}},
	},
	.ADDVA = {
		{{.ADDVA,          {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_S}, {.ZA_TILE_LOW, .PG, .PM3, .VN}, 0xC0910000, 0xFFFF001C, .SME, {}},                             {written={0}, read={0, 1, 2, 3}}},
	},
	.ZERO = {
		{{.ZERO,           {.SME_PATTERN, .NONE, .NONE, .NONE}, {.SME_PATTERN_FIELD, .NONE, .NONE, .NONE}, 0xC0080000, 0xFFFFFF00, .SME, {}},                                 {}},
	},
	.FMOPA = {
		{{.FMOPA,          {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_S}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0x80800000, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FMOPS = {
		{{.FMOPS,          {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_S}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0x80800010, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFMOPA = {
		{{.BFMOPA,         {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0x81800000, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFMOPS = {
		{{.BFMOPS,         {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0x81800010, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.SMOPA = {
		{{.SMOPA,          {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA0800000, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}}},
		{{.SMOPA,          {.ZA_TILE_D, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_D, .PG, .PM3, .VN}, 0xA0C00000, 0xFFE08010, .SME, {is_64=true}},                 {written={0}, read={0, 1, 2, 3}}},
	},
	.SMOPS = {
		{{.SMOPS,          {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA0800010, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}}},
		{{.SMOPS,          {.ZA_TILE_D, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_D, .PG, .PM3, .VN}, 0xA0C00010, 0xFFE08010, .SME, {is_64=true}},                 {written={0}, read={0, 1, 2, 3}}},
	},
	.UMOPA = {
		{{.UMOPA,          {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA1A00000, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}}},
		{{.UMOPA,          {.ZA_TILE_D, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_D, .PG, .PM3, .VN}, 0xA1E00000, 0xFFE08010, .SME, {is_64=true}},                 {written={0}, read={0, 1, 2, 3}}},
	},
	.UMOPS = {
		{{.UMOPS,          {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA1A00010, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}}},
		{{.UMOPS,          {.ZA_TILE_D, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_D, .PG, .PM3, .VN}, 0xA1E00010, 0xFFE08010, .SME, {is_64=true}},                 {written={0}, read={0, 1, 2, 3}}},
	},
	.USMOPA = {
		{{.USMOPA,         {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA1800000, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}}},
	},
	.SUMOPA = {
		{{.SUMOPA,         {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA0A00000, 0xFFE08010, .SME, {}},                           {written={0}, read={0, 1, 2, 3}}},
	},
	.LD1Q = {
		{{.LD1Q,           {.SME_SLICE_Q, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.SME_SLICE_Q, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE1C00000, 0xFFE00010, .SME, {}},               {written={0}, read={1, 2}, reads_mem=true}},
	},
	.ST1Q = {
		{{.ST1Q,           {.SME_SLICE_Q, .P_REG, .MEM_SVE_SS, .NONE}, {.SME_SLICE_Q, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE1E00000, 0xFFE00010, .SME, {}},                    {read={0, 1, 2}, writes_mem=true}},
	},
	.MOVA = {
		{{.MOVA,           {.Z_REG_B,     .P_REG_MERGE, .SME_SLICE_B, .NONE}, {.VD,          .PG, .SME_SLICE_B, .NONE}, 0xC0020000, 0xFFE08010, .SME, {}},                    {written={0}, read={1, 2}}},
		{{.MOVA,           {.SME_SLICE_B, .P_REG_MERGE, .Z_REG_B,     .NONE}, {.SME_SLICE_B, .PG, .VN,          .NONE}, 0xC0000000, 0xFFE08010, .SME, {}},                    {written={0}, read={1, 2}}},
	},
	.FCMLA = {
		{{.FCMLA,          {.V_4H, .V_4H, .V_4H, .IMM_2}, {.VD, .VN, .VM, .ENC_FCMLA_ROT}, 0x2E40C400, 0xFFE0CC00, .NEON, {}},                                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCMLA,          {.V_8H, .V_8H, .V_8H, .IMM_2}, {.VD, .VN, .VM, .ENC_FCMLA_ROT}, 0x6E40C400, 0xFFE0CC00, .NEON, {}},                                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCMLA,          {.V_4S, .V_4S, .V_4S, .IMM_2}, {.VD, .VN, .VM, .ENC_FCMLA_ROT}, 0x6E80C400, 0xFFE0CC00, .NEON, {}},                                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCMLA,          {.V_2D, .V_2D, .V_2D, .IMM_2}, {.VD, .VN, .VM, .ENC_FCMLA_ROT}, 0x6EC0C400, 0xFFE0CC00, .NEON, {}},                                                {written={0}, read={0, 1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.FCADD = {
		{{.FCADD,          {.V_4H, .V_4H, .V_4H, .IMM_2}, {.VD, .VN, .VM, .ENC_FCADD_ROT}, 0x2E40E400, 0xFFA0EC00, .NEON, {}},                                                {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCADD,          {.V_8H, .V_8H, .V_8H, .IMM_2}, {.VD, .VN, .VM, .ENC_FCADD_ROT}, 0x6E40E400, 0xFFA0EC00, .NEON, {}},                                                {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCADD,          {.V_4S, .V_4S, .V_4S, .IMM_2}, {.VD, .VN, .VM, .ENC_FCADD_ROT}, 0x6E80E400, 0xFFA0EC00, .NEON, {}},                                                {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.FCADD,          {.V_2D, .V_2D, .V_2D, .IMM_2}, {.VD, .VN, .VM, .ENC_FCADD_ROT}, 0x6EC0E400, 0xFFA0EC00, .NEON, {}},                                                {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.PRFB = {
		{{.PRFB,           {.IMM_4, .P_REG_GOV, .MEM_SVE_SS, .NONE}, {.ENC_SVE_PRFOP, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0x8400C000, 0xFFE0E000, .SVE, {}},                    {read={1, 2}, side_effects={.HINT}}},
	},
	.PRFH = {
		{{.PRFH,           {.IMM_4, .P_REG_GOV, .MEM_SVE_SS, .NONE}, {.ENC_SVE_PRFOP, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0x8480C000, 0xFFE0E000, .SVE, {}},                    {read={1, 2}, side_effects={.HINT}}},
	},
	.PRFW = {
		{{.PRFW,           {.IMM_4, .P_REG_GOV, .MEM_SVE_SS, .NONE}, {.ENC_SVE_PRFOP, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0x8500C000, 0xFFE0E000, .SVE, {}},                    {read={1, 2}, side_effects={.HINT}}},
	},
	.PRFD = {
		{{.PRFD,           {.IMM_4, .P_REG_GOV, .MEM_SVE_SS, .NONE}, {.ENC_SVE_PRFOP, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0x8580C000, 0xFFE0E000, .SVE, {}},                    {read={1, 2}, side_effects={.HINT}}},
	},
	.LDNT1B = {
		{{.LDNT1B,         {.Z_REG_B, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA400C000, 0xFFE0E000, .SVE, {}},                            {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LDNT1H = {
		{{.LDNT1H,         {.Z_REG_H, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA480C000, 0xFFE0E000, .SVE, {}},                            {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LDNT1W = {
		{{.LDNT1W,         {.Z_REG_S, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA500C000, 0xFFE0E000, .SVE, {}},                            {written={0}, read={1, 2}, reads_mem=true}},
	},
	.LDNT1D = {
		{{.LDNT1D,         {.Z_REG_D, .P_REG_ZERO, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA580C000, 0xFFE0E000, .SVE, {is_64=true}},                  {written={0}, read={1, 2}, reads_mem=true}},
	},
	.STNT1B = {
		{{.STNT1B,         {.Z_REG_B, .P_REG, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE4006000, 0xFFE0E000, .SVE, {}},                                 {read={0, 1, 2}, writes_mem=true}},
	},
	.STNT1H = {
		{{.STNT1H,         {.Z_REG_H, .P_REG, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE4806000, 0xFFE0E000, .SVE, {}},                                 {read={0, 1, 2}, writes_mem=true}},
	},
	.STNT1W = {
		{{.STNT1W,         {.Z_REG_S, .P_REG, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE5006000, 0xFFE0E000, .SVE, {}},                                 {read={0, 1, 2}, writes_mem=true}},
	},
	.STNT1D = {
		{{.STNT1D,         {.Z_REG_D, .P_REG, .MEM_SVE_SS, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE5806000, 0xFFE0E000, .SVE, {is_64=true}},                       {read={0, 1, 2}, writes_mem=true}},
	},
	.SPLICE = {
		{{.SPLICE,         {.Z_REG_B, .P_REG_GOV, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VN}, 0x052C8000, 0xFFFFE000, .SVE, {}},                                               {written={0}, read={1, 2, 3}}},
	},
	.INDEX = {
		{{.INDEX,          {.Z_REG_B, .IMM_5, .IMM_5, .NONE}, {.VD, .SVE_IMM5, .NONE,     .NONE}, 0x04204000, 0xFFE0FC00, .SVE, {}},                                          {written={0}}},
		{{.INDEX,          {.Z_REG_B, .IMM_5, .X_REG, .NONE}, {.VD, .SVE_IMM5, .RN,       .NONE}, 0x04204800, 0xFFE0FC00, .SVE, {}},                                          {written={0}, read={2}}},
		{{.INDEX,          {.Z_REG_B, .X_REG, .IMM_5, .NONE}, {.VD, .RN,       .SVE_IMM5, .NONE}, 0x04204400, 0xFFE0FC00, .SVE, {}},                                          {written={0}, read={1}}},
		{{.INDEX,          {.Z_REG_B, .X_REG, .X_REG, .NONE}, {.VD, .RN,       .RM,       .NONE}, 0x04204C00, 0xFFE0FC00, .SVE, {}},                                          {written={0}, read={1, 2}}},
	},
	.BSL1N = {
		{{.BSL1N,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04603C00, 0xFFE0FC00, .SVE2, {is_64=true}},                                      {written={0}, read={1, 2, 3}}},
	},
	.BSL2N = {
		{{.BSL2N,          {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04A03C00, 0xFFE0FC00, .SVE2, {is_64=true}},                                      {written={0}, read={1, 2, 3}}},
	},
	.NBSL = {
		{{.NBSL,           {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04E03C00, 0xFFE0FC00, .SVE2, {is_64=true}},                                      {written={0}, read={1, 2, 3}}},
	},
	.PMUL = {
		{{.PMUL,           {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04206400, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={1, 2}}},
	},
	.PMULLB = {
		{{.PMULLB,         {.Z_REG_D, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x45C06800, 0xFFE0FC00, .SVE2, {is_64=true}},                                       {written={0}, read={1, 2}}},
	},
	.PMULLT = {
		{{.PMULLT,         {.Z_REG_D, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x45C06C00, 0xFFE0FC00, .SVE2, {is_64=true}},                                       {written={0}, read={1, 2}}},
	},
	.BFCVTNT = {
		{{.BFCVTNT,        {.Z_REG_H, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x648AA000, 0xFFFFE000, .SVE, {}},                                              {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.LDRAA = {
		{{.LDRAA,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xF8200400, 0xFFA00C00, .PAC, {is_64=true}},                           {written={0}, read={1}, reads_mem=true}},
		{{.LDRAA,          {.X_REG, .MEM_PRE,    .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE, .NONE, .NONE}, 0xF8200C00, 0xFFA00C00, .PAC, {is_64=true}},                           {written={0, 1}, read={1}, reads_mem=true}},
	},
	.LDRAB = {
		{{.LDRAB,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xF8A00400, 0xFFA00C00, .PAC, {is_64=true}},                           {written={0}, read={1}, reads_mem=true}},
		{{.LDRAB,          {.X_REG, .MEM_PRE,    .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE, .NONE, .NONE}, 0xF8A00C00, 0xFFA00C00, .PAC, {is_64=true}},                           {written={0, 1}, read={1}, reads_mem=true}},
	},
	.TSTART = {
		{{.TSTART,         {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5233060, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {written={0}, side_effects={.NONDETERMINISTIC}}},
	},
	.TCOMMIT = {
		{{.TCOMMIT,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503307F, 0xFFFFFFFF, .BASE, {}},                                                    {}},
	},
	.TCANCEL = {
		{{.TCANCEL,        {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4600000, 0xFFE0001F, .BASE, {}},                                                 {side_effects={.CONTROL}}},
	},
	.TTEST = {
		{{.TTEST,          {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5233160, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {written={0}}},
	},
	.WFET = {
		{{.WFET,           {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5031000, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.WAIT}}},
	},
	.WFIT = {
		{{.WFIT,           {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5031020, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.WAIT}}},
	},
	.BC_COND = {
		{{.BC_COND,        {.COND, .REL_19, .NONE, .NONE}, {.COND_LO, .BRANCH_19, .NONE, .NONE}, 0x54000010, 0xFF000010, .BASE, {cond_branch=true}},                          {nzcv_rd={.N, .Z, .C, .V}, side_effects={.CONTROL}}},
	},
	.UXTB = {
		{{.UXTB,           {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x53001C00, 0xFFFFFC00, .BASE, {}},                                                      {written={0}, read={1}}},
	},
	.UXTH = {
		{{.UXTH,           {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x53003C00, 0xFFFFFC00, .BASE, {}},                                                      {written={0}, read={1}}},
	},
	.UXTW = {
		{{.UXTW,           {.X_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xD3407C00, 0xFFFFFC00, .BASE, {is_64=true}},                                            {written={0}, read={1}}},
	},
	.SXTB = {
		{{.SXTB,           {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x13001C00, 0xFFFFFC00, .BASE, {}},                                                      {written={0}, read={1}}},
	},
	.SXTH = {
		{{.SXTH,           {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x13003C00, 0xFFFFFC00, .BASE, {}},                                                      {written={0}, read={1}}},
	},
	.SXTW = {
		{{.SXTW,           {.X_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x93407C00, 0xFFFFFC00, .BASE, {is_64=true}},                                            {written={0}, read={1}}},
	},
	.ADC = {
		{{.ADC,            {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1A000000, 0xFFE0FC00, .BASE, {}},                                                       {written={0}, read={1, 2}, nzcv_rd={.C}}},
		{{.ADC,            {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9A000000, 0xFFE0FC00, .BASE, {is_64=true}},                                             {written={0}, read={1, 2}, nzcv_rd={.C}}},
	},
	.ADCS = {
		{{.ADCS,           {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x3A000000, 0xFFE0FC00, .BASE, {sets_flags=true}},                                        {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.C}}},
		{{.ADCS,           {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0xBA000000, 0xFFE0FC00, .BASE, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.C}}},
	},
	.SBC = {
		{{.SBC,            {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x5A000000, 0xFFE0FC00, .BASE, {}},                                                       {written={0}, read={1, 2}, nzcv_rd={.C}}},
		{{.SBC,            {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0xDA000000, 0xFFE0FC00, .BASE, {is_64=true}},                                             {written={0}, read={1, 2}, nzcv_rd={.C}}},
	},
	.SBCS = {
		{{.SBCS,           {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x7A000000, 0xFFE0FC00, .BASE, {sets_flags=true}},                                        {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.C}}},
		{{.SBCS,           {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0xFA000000, 0xFFE0FC00, .BASE, {sets_flags=true, is_64=true}},                            {written={0}, read={1, 2}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.C}}},
	},
	.NGC = {
		{{.NGC,            {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x5A0003E0, 0xFFE0FFE0, .BASE, {}},                                                      {written={0}, read={1}, nzcv_rd={.C}}},
		{{.NGC,            {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xDA0003E0, 0xFFE0FFE0, .BASE, {is_64=true}},                                            {written={0}, read={1}, nzcv_rd={.C}}},
	},
	.NGCS = {
		{{.NGCS,           {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x7A0003E0, 0xFFE0FFE0, .BASE, {sets_flags=true}},                                       {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.C}}},
		{{.NGCS,           {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xFA0003E0, 0xFFE0FFE0, .BASE, {sets_flags=true, is_64=true}},                           {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}, nzcv_rd={.C}}},
	},
	.LDAPUR = {
		{{.LDAPUR,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x99400000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
		{{.LDAPUR,         {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9400000, 0xFFE00C00, .BASE, {is_64=true}},                           {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.STLUR = {
		{{.STLUR,          {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x99000000, 0xFFE00C00, .BASE, {}},                                     {read={0, 1}, writes_mem=true, side_effects={.FENCE}}},
		{{.STLUR,          {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9000000, 0xFFE00C00, .BASE, {is_64=true}},                           {read={0, 1}, writes_mem=true, side_effects={.FENCE}}},
	},
	.LDAPURB = {
		{{.LDAPURB,        {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x19400000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.STLURB = {
		{{.STLURB,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x19000000, 0xFFE00C00, .BASE, {}},                                     {read={0, 1}, writes_mem=true, side_effects={.FENCE}}},
	},
	.LDAPURH = {
		{{.LDAPURH,        {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x59400000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.STLURH = {
		{{.STLURH,         {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x59000000, 0xFFE00C00, .BASE, {}},                                     {read={0, 1}, writes_mem=true, side_effects={.FENCE}}},
	},
	.LDAPURSB = {
		{{.LDAPURSB,       {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x19800000, 0xFFE00C00, .BASE, {is_64=true}},                           {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
		{{.LDAPURSB,       {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x19C00000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.LDAPURSH = {
		{{.LDAPURSH,       {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x59800000, 0xFFE00C00, .BASE, {is_64=true}},                           {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
		{{.LDAPURSH,       {.W_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x59C00000, 0xFFE00C00, .BASE, {}},                                     {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.LDAPURSW = {
		{{.LDAPURSW,       {.X_REG, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x99800000, 0xFFE00C00, .BASE, {is_64=true}},                           {written={0}, read={1}, reads_mem=true, side_effects={.FENCE}}},
	},
	.BFADD = {
		{{.BFADD,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65008000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.BFADD,          {.Z_REG_H, .Z_REG_H,     .Z_REG_H, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65000000, 0xFFE0FC00, .SVE2, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFSUB = {
		{{.BFSUB,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65018000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.BFSUB,          {.Z_REG_H, .Z_REG_H,     .Z_REG_H, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65000400, 0xFFE0FC00, .SVE2, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFMUL = {
		{{.BFMUL,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM},   0x65028000, 0xFFE0E000, .SVE,  {}},                                          {written={0}, read={1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
		{{.BFMUL,          {.Z_REG_H, .Z_REG_H,     .Z_REG_H, .NONE},    {.VD, .VN, .VM, .NONE}, 0x65000800, 0xFFE0FC00, .SVE2, {}},                                          {written={0}, read={1, 2}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFMLA = {
		{{.BFMLA,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65200000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.BFMLS = {
		{{.BFMLS,          {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65202000, 0xFFE0E000, .SVE, {}},                                             {written={0}, read={0, 1, 2, 3}, fpsr_wr={.IOC, .OFC, .UFC, .IXC, .IDC}, reads_fpcr=true}},
	},
	.SB = {
		{{.SB,             {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50330FF, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.FENCE}}},
	},
	.CSDB = {
		{{.CSDB,           {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503229F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.FENCE}}},
	},
	.DGH = {
		{{.DGH,            {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50320DF, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.HINT}}},
	},
	.PSB_CSYNC = {
		{{.PSB_CSYNC,      {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503223F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.HINT}}},
	},
	.TSB_CSYNC = {
		{{.TSB_CSYNC,      {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503225F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.HINT}}},
	},
	.BTI_J = {
		{{.BTI_J,          {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503249F, 0xFFFFFFFF, .BTI, {}},                                                     {side_effects={.BTI}}},
	},
	.BTI_C = {
		{{.BTI_C,          {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503245F, 0xFFFFFFFF, .BTI, {}},                                                     {side_effects={.BTI}}},
	},
	.BTI_JC = {
		{{.BTI_JC,         {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50324DF, 0xFFFFFFFF, .BTI, {}},                                                     {side_effects={.BTI}}},
	},
	.BFCLAMP = {
		{{.BFCLAMP,        {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x64202400, 0xFFE0FC00, .SVE2, {}},                                                 {written={0}, read={1, 2}}},
	},
	.BFMAXNM = {
		{{.BFMAXNM,        {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65048000, 0xFFE0E000, .SVE2, {}},                                            {written={0}, read={1, 2, 3}}},
	},
	.BFMINNM = {
		{{.BFMINNM,        {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65058000, 0xFFE0E000, .SVE2, {}},                                            {written={0}, read={1, 2, 3}}},
	},
	.LUTI2 = {
		{{.LUTI2,          {.Z_PAIR, .Z_PAIR, .Z_REG_B, .IMM_3}, {.ENC_Z_PAIR_VD, .ENC_Z_PAIR_VN, .VM, .IMM12}, 0xC08C4000, 0xFFE0F000, .SME, {}},                            {written={0}, read={1}}},
	},
	.LUTI4 = {
		{{.LUTI4,          {.Z_PAIR, .Z_PAIR, .Z_REG_B, .IMM_2}, {.ENC_Z_PAIR_VD, .ENC_Z_PAIR_VN, .VM, .IMM12}, 0xC08A4000, 0xFFE0F000, .SME, {}},                            {written={0}, read={1}}},
	},
	.ZIP = {
		{{.ZIP,            {.Z_PAIR, .Z_REG_B, .Z_REG_B, .NONE}, {.ENC_Z_PAIR_VD, .VN,            .VM,   .NONE}, 0xC120D000, 0xFFE0FC00, .SME, {}},                           {written={0}, read={1, 2}}},
		{{.ZIP,            {.Z_QUAD, .Z_QUAD,  .NONE,    .NONE}, {.ENC_Z_QUAD_VD, .ENC_Z_QUAD_VN, .NONE, .NONE}, 0xC136E000, 0xFFFFFC00, .SME, {}},                           {written={0}, read={1, 2}}},
	},
	.UZP = {
		{{.UZP,            {.Z_PAIR, .Z_REG_B, .Z_REG_B, .NONE}, {.ENC_Z_PAIR_VD, .VN,            .VM,   .NONE}, 0xC120D001, 0xFFE0FC00, .SME, {}},                           {written={0}, read={1, 2}}},
		{{.UZP,            {.Z_QUAD, .Z_QUAD,  .NONE,    .NONE}, {.ENC_Z_QUAD_VD, .ENC_Z_QUAD_VN, .NONE, .NONE}, 0xC136E002, 0xFFFFFC00, .SME, {}},                           {written={0}, read={1, 2}}},
	},
	.TLBI_RPALOS = {
		{{.TLBI_RPALOS,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5084EE0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_RPAOS = {
		{{.TLBI_RPAOS,     {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5084EA0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S1E1A = {
		{{.AT_S1E1A,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5079140, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.DC_CIPAPA = {
		{{.DC_CIPAPA,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50E7CE0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE}}},
	},
	.DC_CIGDPAPA = {
		{{.DC_CIGDPAPA,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50E7DE0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE}}},
	},
	.TLBI_PAALL = {
		{{.TLBI_PAALL,     {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50E879F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.TLBI_PAALLOS = {
		{{.TLBI_PAALLOS,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50E819F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.AMX_LDX = {
		{{.AMX_LDX,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201000, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_LDY = {
		{{.AMX_LDY,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201020, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_STX = {
		{{.AMX_STX,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201040, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_STY = {
		{{.AMX_STY,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201060, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_LDZ = {
		{{.AMX_LDZ,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201080, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_STZ = {
		{{.AMX_STZ,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002010A0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_LDZI = {
		{{.AMX_LDZI,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002010C0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_STZI = {
		{{.AMX_STZI,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002010E0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_EXTRX = {
		{{.AMX_EXTRX,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201100, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_EXTRY = {
		{{.AMX_EXTRY,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201120, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_FMA64 = {
		{{.AMX_FMA64,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201140, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_FMS64 = {
		{{.AMX_FMS64,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201160, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_FMA32 = {
		{{.AMX_FMA32,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201180, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_FMS32 = {
		{{.AMX_FMS32,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002011A0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_MAC16 = {
		{{.AMX_MAC16,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002011C0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_FMA16 = {
		{{.AMX_FMA16,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002011E0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_FMS16 = {
		{{.AMX_FMS16,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201200, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_SET = {
		{{.AMX_SET,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x00201220, 0xFFFFFFFF, .AMX, {}},                                                     {}},
	},
	.AMX_CLR = {
		{{.AMX_CLR,        {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x00201240, 0xFFFFFFFF, .AMX, {}},                                                     {}},
	},
	.AMX_VECINT = {
		{{.AMX_VECINT,     {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201260, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_VECFP = {
		{{.AMX_VECFP,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201280, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_MATINT = {
		{{.AMX_MATINT,     {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002012A0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_MATFP = {
		{{.AMX_MATFP,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002012C0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.AMX_GENLUT = {
		{{.AMX_GENLUT,     {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002012E0, 0xFFFFFFE0, .AMX, {is_64=true}},                                            {read={0}}},
	},
	.CPYP = {
		{{.CPYP,           {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1D000400, 0xFFE03C00, .BASE, {is_64=true}},                                         {written={0, 1, 2}, read={0, 1, 2}, writes_mem=true, reads_mem=true}},
	},
	.CPYM = {
		{{.CPYM,           {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1D400400, 0xFFE03C00, .BASE, {is_64=true}},                                         {written={0, 1, 2}, read={0, 1, 2}, writes_mem=true, reads_mem=true}},
	},
	.CPYE = {
		{{.CPYE,           {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1D800400, 0xFFE03C00, .BASE, {is_64=true}},                                         {written={0, 1, 2}, read={0, 1, 2}, writes_mem=true, reads_mem=true}},
	},
	.CPYFP = {
		{{.CPYFP,          {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19000400, 0xFFE03C00, .BASE, {is_64=true}},                                         {written={0, 1, 2}, read={0, 1, 2}, writes_mem=true, reads_mem=true}},
	},
	.CPYFM = {
		{{.CPYFM,          {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19400400, 0xFFE03C00, .BASE, {is_64=true}},                                         {written={0, 1, 2}, read={0, 1, 2}, writes_mem=true, reads_mem=true}},
	},
	.CPYFE = {
		{{.CPYFE,          {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19800400, 0xFFE03C00, .BASE, {is_64=true}},                                         {written={0, 1, 2}, read={0, 1, 2}, writes_mem=true, reads_mem=true}},
	},
	.SETP = {
		{{.SETP,           {.XSP_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19C00400, 0xFFE03C00, .BASE, {is_64=true}},                                           {written={0, 1}, read={0, 1, 2}, writes_mem=true}},
	},
	.SETM = {
		{{.SETM,           {.XSP_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19C04400, 0xFFE03C00, .BASE, {is_64=true}},                                           {written={0, 1}, read={0, 1, 2}, writes_mem=true}},
	},
	.SETE = {
		{{.SETE,           {.XSP_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19C08400, 0xFFE03C00, .BASE, {is_64=true}},                                           {written={0, 1}, read={0, 1, 2}, writes_mem=true}},
	},
	.DC_IVAC = {
		{{.DC_IVAC,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087620, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE, .PRIVILEGED}}},
	},
	.DC_ISW = {
		{{.DC_ISW,         {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087640, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE, .PRIVILEGED}}},
	},
	.DC_CSW = {
		{{.DC_CSW,         {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087A40, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE, .PRIVILEGED}}},
	},
	.DC_CISW = {
		{{.DC_CISW,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087E40, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE, .PRIVILEGED}}},
	},
	.DC_ZVA = {
		{{.DC_ZVA,         {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7420, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, writes_mem=true, side_effects={.CACHE}}},
	},
	.DC_CVAC = {
		{{.DC_CVAC,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7A20, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE}}},
	},
	.DC_CVAU = {
		{{.DC_CVAU,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7B20, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE}}},
	},
	.DC_CIVAC = {
		{{.DC_CIVAC,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7E20, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE}}},
	},
	.IC_IALLUIS = {
		{{.IC_IALLUIS,     {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD508711F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.CACHE, .PRIVILEGED}}},
	},
	.IC_IALLU = {
		{{.IC_IALLU,       {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD508751F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.CACHE, .PRIVILEGED}}},
	},
	.IC_IVAU = {
		{{.IC_IVAU,        {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7520, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.CACHE}}},
	},
	.AT_S1E1R = {
		{{.AT_S1E1R,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087800, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S1E1W = {
		{{.AT_S1E1W,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087820, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S1E0R = {
		{{.AT_S1E0R,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087840, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S1E0W = {
		{{.AT_S1E0W,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087860, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S1E2R = {
		{{.AT_S1E2R,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C7800, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S1E2W = {
		{{.AT_S1E2W,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C7820, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S1E3R = {
		{{.AT_S1E3R,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50E7800, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S1E3W = {
		{{.AT_S1E3W,       {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50E7820, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S12E1R = {
		{{.AT_S12E1R,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C7880, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S12E1W = {
		{{.AT_S12E1W,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C78A0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S12E0R = {
		{{.AT_S12E0R,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C78C0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.AT_S12E0W = {
		{{.AT_S12E0W,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C78E0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_VMALLE1 = {
		{{.TLBI_VMALLE1,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD508871F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.TLBI_VMALLE1IS = {
		{{.TLBI_VMALLE1IS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD508831F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.TLBI_VAE1 = {
		{{.TLBI_VAE1,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5088720, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_VAE1IS = {
		{{.TLBI_VAE1IS,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5088320, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_ASIDE1 = {
		{{.TLBI_ASIDE1,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5088740, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_ASIDE1IS = {
		{{.TLBI_ASIDE1IS,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5088340, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_VAAE1 = {
		{{.TLBI_VAAE1,     {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5088760, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_VAAE1IS = {
		{{.TLBI_VAAE1IS,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5088360, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_VALE1 = {
		{{.TLBI_VALE1,     {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50887A0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_VALE1IS = {
		{{.TLBI_VALE1IS,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50883A0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_VAALE1 = {
		{{.TLBI_VAALE1,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50887E0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_VAALE1IS = {
		{{.TLBI_VAALE1IS,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50883E0, 0xFFFFFFE0, .BASE, {is_64=true}},                                           {read={0}, side_effects={.PRIVILEGED}}},
	},
	.TLBI_ALLE1 = {
		{{.TLBI_ALLE1,     {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD508871F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.TLBI_ALLE1IS = {
		{{.TLBI_ALLE1IS,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD508831F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.TLBI_ALLE2 = {
		{{.TLBI_ALLE2,     {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50C871F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.TLBI_ALLE2IS = {
		{{.TLBI_ALLE2IS,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50C831F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.TLBI_ALLE3 = {
		{{.TLBI_ALLE3,     {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50E871F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.TLBI_ALLE3IS = {
		{{.TLBI_ALLE3IS,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD50E831F, 0xFFFFFFFF, .BASE, {}},                                                    {side_effects={.PRIVILEGED}}},
	},
	.PRFM = {
		{{.PRFM,           {.IMM_5, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xF9800000, 0xFFC00000, .BASE, {is_64=true}},                          {read={1}, side_effects={.HINT}}},
		{{.PRFM,           {.IMM_5, .REL_19,     .NONE, .NONE}, {.RT, .BRANCH_19,       .NONE, .NONE}, 0xD8000000, 0xFF000000, .BASE, {is_64=true}},                          {side_effects={.HINT}}},
	},
	.PRFUM = {
		{{.PRFUM,          {.IMM_5, .MEM_OFFSET, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xF8800000, 0xFFE00C00, .BASE, {is_64=true}},                           {read={1}, side_effects={.HINT}}},
	},
	.NEGS = {
		{{.NEGS,           {.W_REG, .W_SHIFTED, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x6B0003E0, 0xFF2003E0, .BASE, {sets_flags=true}},                                   {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.NEGS,           {.X_REG, .X_SHIFTED, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xEB0003E0, 0xFF2003E0, .BASE, {sets_flags=true, is_64=true}},                       {written={0}, read={1}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMP = {
		{{.CMP,            {.W_REG,   .W_SHIFTED,  .NONE, .NONE}, {.RN, .RM,    .NONE, .NONE}, 0x6B00001F, 0xFF20001F, .BASE, {sets_flags=true}},                             {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMP,            {.X_REG,   .X_SHIFTED,  .NONE, .NONE}, {.RN, .RM,    .NONE, .NONE}, 0xEB00001F, 0xFF20001F, .BASE, {sets_flags=true, is_64=true}},                 {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMP,            {.WSP_REG, .W_EXTENDED, .NONE, .NONE}, {.RN, .RM,    .NONE, .NONE}, 0x6B20001F, 0xFFE0001F, .BASE, {sets_flags=true}},                             {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMP,            {.XSP_REG, .X_EXTENDED, .NONE, .NONE}, {.RN, .RM,    .NONE, .NONE}, 0xEB20001F, 0xFFE0001F, .BASE, {sets_flags=true, is_64=true}},                 {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMP,            {.WSP_REG, .IMM_12,     .NONE, .NONE}, {.RN, .IMM12, .NONE, .NONE}, 0x7100001F, 0xFF80001F, .BASE, {sets_flags=true}},                             {read={0}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMP,            {.XSP_REG, .IMM_12,     .NONE, .NONE}, {.RN, .IMM12, .NONE, .NONE}, 0xF100001F, 0xFF80001F, .BASE, {sets_flags=true, is_64=true}},                 {read={0}, nzcv_wr={.N, .Z, .C, .V}}},
	},
	.CMN = {
		{{.CMN,            {.W_REG,   .W_SHIFTED,  .NONE, .NONE}, {.RN, .RM,    .NONE, .NONE}, 0x2B00001F, 0xFF20001F, .BASE, {sets_flags=true}},                             {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMN,            {.X_REG,   .X_SHIFTED,  .NONE, .NONE}, {.RN, .RM,    .NONE, .NONE}, 0xAB00001F, 0xFF20001F, .BASE, {sets_flags=true, is_64=true}},                 {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMN,            {.WSP_REG, .W_EXTENDED, .NONE, .NONE}, {.RN, .RM,    .NONE, .NONE}, 0x2B20001F, 0xFFE0001F, .BASE, {sets_flags=true}},                             {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMN,            {.XSP_REG, .X_EXTENDED, .NONE, .NONE}, {.RN, .RM,    .NONE, .NONE}, 0xAB20001F, 0xFFE0001F, .BASE, {sets_flags=true, is_64=true}},                 {read={0, 1}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMN,            {.WSP_REG, .IMM_12,     .NONE, .NONE}, {.RN, .IMM12, .NONE, .NONE}, 0x3100001F, 0xFF80001F, .BASE, {sets_flags=true}},                             {read={0}, nzcv_wr={.N, .Z, .C, .V}}},
		{{.CMN,            {.XSP_REG, .IMM_12,     .NONE, .NONE}, {.RN, .IMM12, .NONE, .NONE}, 0xB100001F, 0xFF80001F, .BASE, {sets_flags=true, is_64=true}},                 {read={0}, nzcv_wr={.N, .Z, .C, .V}}},
	},
}
