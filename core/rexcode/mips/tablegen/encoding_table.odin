// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mips_tablegen

// =============================================================================
// MIPS ENCODING_TABLE
// =============================================================================
//
// Indexed by Mnemonic. Each entry is a slice of Encoding forms (most have
// exactly one; a handful have alternate forms across Feature revisions).
//
// Entry shape:
//   {mnemonic, {ops4}, {enc4}, bits, mask, isa, flags}
//
// bits/mask: `bits` holds the static bit pattern of the 32-bit word;
// `mask` marks which bit positions are static. Operand-derived bits OR
// in over the zero positions in `bits`.
//
// Sections (filled incrementally):
//   1. MIPS I  -- core integer (this file)
//   2. MIPS II -- LL/SC, SYNC, traps, branch-likely    [§ MIPS_II]
//   3. MIPS III -- 64-bit core + load/store doublewords  [§ MIPS_III]
//   4. MIPS IV -- MOVN/MOVZ, MOVF/MOVT, PREF, indexed FP [§ MIPS_IV]
//   5. MIPS32 R1/R2 -- CLZ/MUL/MADD/EXT/INS/...        [§ R1_R2]
//   6. MIPS32 R6 -- compact branches, new mul/div      [§ R6]
//   7. FPU (COP1)                                       [§ FPU]
//   8. COP0 (system)                                    [§ COP0]
//   9. PS1 GTE (COP2)                                   [§ GTE]
//  10. PS2 EE MMI                                       [§ MMI]
//  11. PSP Allegrex VFPU                                [§ VFPU]
@(rodata)
ENCODING_TABLE := #partial [Mnemonic][]Encoding{
    .INVALID = {},

    // =========================================================================
    // §1 MIPS I — core integer
    // =========================================================================

    // ---- R-type arithmetic (SPECIAL, op=0) -----------------------------------
    // bits = funct; mask = OPCODE | SHAMT | FUNCT (shamt=0 fixed) = 0xFC0007FF

    .ADD  = { {.ADD,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000020, 0xFC0007FF, .MIPS_I, {}} },
    .ADDU = { {.ADDU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000021, 0xFC0007FF, .MIPS_I, {}} },
    .SUB  = { {.SUB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000022, 0xFC0007FF, .MIPS_I, {}} },
    .SUBU = { {.SUBU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000023, 0xFC0007FF, .MIPS_I, {}} },
    .AND  = { {.AND,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000024, 0xFC0007FF, .MIPS_I, {}} },
    .OR   = { {.OR,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000025, 0xFC0007FF, .MIPS_I, {}} },
    .XOR  = { {.XOR,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000026, 0xFC0007FF, .MIPS_I, {}} },
    .NOR  = { {.NOR,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000027, 0xFC0007FF, .MIPS_I, {}} },
    .SLT  = { {.SLT,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000002A, 0xFC0007FF, .MIPS_I, {}} },
    .SLTU = { {.SLTU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000002B, 0xFC0007FF, .MIPS_I, {}} },

    // ---- Multiply/divide (writes HI:LO) --------------------------------------
    // mask = OPCODE | RD | SHAMT | FUNCT = 0xFC00FFFF
    .MULT  = { {.MULT,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x00000018, 0xFC00FFFF, .MIPS_I, {writes_hilo=true}} },
    .MULTU = { {.MULTU, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x00000019, 0xFC00FFFF, .MIPS_I, {writes_hilo=true}} },
    .DIV   = { {.DIV,   {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x0000001A, 0xFC00FFFF, .MIPS_I, {writes_hilo=true}} },
    .DIVU  = { {.DIVU,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x0000001B, 0xFC00FFFF, .MIPS_I, {writes_hilo=true}} },

    // ---- HI/LO move ----------------------------------------------------------
    // MF*: only rd is operand; mask = OPCODE | RS | RT | SHAMT | FUNCT = 0xFFFF07FF
    // MT*: only rs is operand; mask = OPCODE | RT | RD | SHAMT | FUNCT = 0xFC1FFFFF
    .MFHI = { {.MFHI, {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x00000010, 0xFFFF07FF, .MIPS_I, {}} },
    .MFLO = { {.MFLO, {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x00000012, 0xFFFF07FF, .MIPS_I, {}} },
    .MTHI = { {.MTHI, {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x00000011, 0xFC1FFFFF, .MIPS_I, {}} },
    .MTLO = { {.MTLO, {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x00000013, 0xFC1FFFFF, .MIPS_I, {}} },

    // ---- Shifts by constant --------------------------------------------------
    // mask = OPCODE | RS | FUNCT = 0xFFE0003F (rs=0 fixed; shamt is operand)
    .SLL = { {.SLL, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x00000000, 0xFFE0003F, .MIPS_I, {}} },
    .SRL = { {.SRL, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x00000002, 0xFFE0003F, .MIPS_I, {}} },
    .SRA = { {.SRA, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x00000003, 0xFFE0003F, .MIPS_I, {}} },

    // ---- Variable shifts (shift count from $rs) ------------------------------
    // mask = OPCODE | SHAMT | FUNCT = 0xFC0007FF
    .SLLV = { {.SLLV, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x00000004, 0xFC0007FF, .MIPS_I, {}} },
    .SRLV = { {.SRLV, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x00000006, 0xFC0007FF, .MIPS_I, {}} },
    .SRAV = { {.SRAV, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x00000007, 0xFC0007FF, .MIPS_I, {}} },

    // ---- I-type arithmetic ---------------------------------------------------
    // mask = OPCODE = 0xFC000000
    .ADDI  = { {.ADDI,  {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x20000000, 0xFC000000, .MIPS_I, {}} },
    .ADDIU = { {.ADDIU, {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x24000000, 0xFC000000, .MIPS_I, {}} },
    .SLTI  = { {.SLTI,  {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x28000000, 0xFC000000, .MIPS_I, {}} },
    .SLTIU = { {.SLTIU, {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x2C000000, 0xFC000000, .MIPS_I, {}} },
    .ANDI  = { {.ANDI,  {.GPR,.GPR,.IMM16U,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x30000000, 0xFC000000, .MIPS_I, {}} },
    .ORI   = { {.ORI,   {.GPR,.GPR,.IMM16U,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x34000000, 0xFC000000, .MIPS_I, {}} },
    .XORI  = { {.XORI,  {.GPR,.GPR,.IMM16U,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x38000000, 0xFC000000, .MIPS_I, {}} },

    // LUI: rs=0 fixed.  mask = OPCODE | RS = 0xFFE00000
    .LUI = { {.LUI, {.GPR,.IMM16U,.NONE,.NONE}, {.RT,.IMM_16,.NONE,.NONE}, 0x3C000000, 0xFFE00000, .MIPS_I, {}} },

    // ---- Branches (I-type, with delay slot) ----------------------------------
    .BEQ  = { {.BEQ,  {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x10000000, 0xFC000000, .MIPS_I, {delay_slot=true}} },
    .BNE  = { {.BNE,  {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x14000000, 0xFC000000, .MIPS_I, {delay_slot=true}} },
    // BLEZ/BGTZ have rt=0 fixed.  mask = OPCODE | RT = 0xFC1F0000
    .BLEZ = { {.BLEZ, {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x18000000, 0xFC1F0000, .MIPS_I, {delay_slot=true}} },
    .BGTZ = { {.BGTZ, {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x1C000000, 0xFC1F0000, .MIPS_I, {delay_slot=true}} },

    // ---- REGIMM branches (opcode=1, rt selects op) ---------------------------
    // mask = OPCODE | RT = 0xFC1F0000
    .BLTZ   = { {.BLTZ,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04000000, 0xFC1F0000, .MIPS_I, {delay_slot=true}} },
    .BGEZ   = { {.BGEZ,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04010000, 0xFC1F0000, .MIPS_I, {delay_slot=true}} },
    .BLTZAL = { {.BLTZAL, {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04100000, 0xFC1F0000, .MIPS_I, {delay_slot=true}} },
    .BGEZAL = { {.BGEZAL, {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04110000, 0xFC1F0000, .MIPS_I, {delay_slot=true}} },

    // ---- J-type jumps --------------------------------------------------------
    .J   = { {.J,   {.REL_J26,.NONE,.NONE,.NONE}, {.IMM_26,.NONE,.NONE,.NONE}, 0x08000000, 0xFC000000, .MIPS_I, {delay_slot=true}} },
    .JAL = { {.JAL, {.REL_J26,.NONE,.NONE,.NONE}, {.IMM_26,.NONE,.NONE,.NONE}, 0x0C000000, 0xFC000000, .MIPS_I, {delay_slot=true}} },

    // ---- R-type jumps --------------------------------------------------------
    // JR: only rs operand; rd=rt=shamt=0.  mask = 0xFC1FFFFF
    // JALR: rd defaults to $ra; rs is target.  mask = OPCODE | RT | SHAMT | FUNCT = 0xFC1F07FF
    .JR   = { {.JR,   {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x00000008, 0xFC1FFFFF, .MIPS_I, {delay_slot=true}} },
    .JALR = { {.JALR, {.GPR,.GPR,.NONE,.NONE},  {.RD,.RS,.NONE,.NONE},  0x00000009, 0xFC1F07FF, .MIPS_I, {delay_slot=true}} },

    // ---- Loads (offset(base)) ------------------------------------------------
    .LB  = { {.LB,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x80000000, 0xFC000000, .MIPS_I, {}} },
    .LH  = { {.LH,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x84000000, 0xFC000000, .MIPS_I, {}} },
    .LWL = { {.LWL, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x88000000, 0xFC000000, .MIPS_I, {}} },
    .LW  = { {.LW,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x8C000000, 0xFC000000, .MIPS_I, {}} },
    .LBU = { {.LBU, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x90000000, 0xFC000000, .MIPS_I, {}} },
    .LHU = { {.LHU, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x94000000, 0xFC000000, .MIPS_I, {}} },
    .LWR = { {.LWR, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x98000000, 0xFC000000, .MIPS_I, {}} },

    // ---- Stores --------------------------------------------------------------
    .SB  = { {.SB,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xA0000000, 0xFC000000, .MIPS_I, {}} },
    .SH  = { {.SH,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xA4000000, 0xFC000000, .MIPS_I, {}} },
    .SWL = { {.SWL, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xA8000000, 0xFC000000, .MIPS_I, {}} },
    .SW  = { {.SW,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xAC000000, 0xFC000000, .MIPS_I, {}} },
    .SWR = { {.SWR, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xB8000000, 0xFC000000, .MIPS_I, {}} },

    // ---- System --------------------------------------------------------------
    // mask = OPCODE | FUNCT = 0xFC00003F (code field bits 25-6 are operand)
    .SYSCALL = { {.SYSCALL, {.IMM20,.NONE,.NONE,.NONE}, {.IMM_20,.NONE,.NONE,.NONE}, 0x0000000C, 0xFC00003F, .MIPS_I, {}} },
    .BREAK   = { {.BREAK,   {.IMM20,.NONE,.NONE,.NONE}, {.IMM_20,.NONE,.NONE,.NONE}, 0x0000000D, 0xFC00003F, .MIPS_I, {}} },

    // NOP = SLL $0, $0, 0 -- fully fixed pattern.
    .NOP = { {.NOP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00000000, 0xFFFFFFFF, .MIPS_I, {}} },

    // =========================================================================
    // §2 MIPS II additions
    // =========================================================================

    // Load-Linked / Store-Conditional (atomic, paired use).
    .LL = { {.LL, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xC0000000, 0xFC000000, .MIPS_II, {}} },
    .SC = { {.SC, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xE0000000, 0xFC000000, .MIPS_II, {}} },

    // SYNC: SPECIAL funct 0x0F. The 5-bit "stype" field at bits 10-6 selects
    // a barrier variant; bits=0xF, mask leaves stype as a small operand.
    .SYNC = { {.SYNC, {.IMM5,.NONE,.NONE,.NONE}, {.IMM_5,.NONE,.NONE,.NONE}, 0x0000000F, 0xFFFFF83F, .MIPS_II, {}} },

    // Trap-immediate (REGIMM rt selects).
    .TGEI  = { {.TGEI,  {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x04080000, 0xFC1F0000, .MIPS_II, {}} },
    .TGEIU = { {.TGEIU, {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x04090000, 0xFC1F0000, .MIPS_II, {}} },
    .TLTI  = { {.TLTI,  {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x040A0000, 0xFC1F0000, .MIPS_II, {}} },
    .TLTIU = { {.TLTIU, {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x040B0000, 0xFC1F0000, .MIPS_II, {}} },
    .TEQI  = { {.TEQI,  {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x040C0000, 0xFC1F0000, .MIPS_II, {}} },
    .TNEI  = { {.TNEI,  {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x040E0000, 0xFC1F0000, .MIPS_II, {}} },

    // Trap-register (SPECIAL funct).  The 10-bit code at bits 15-6 is
    // usually 0; we leave it as a hidden zero by including those bits in
    // the mask. Mask = OPCODE | RD | SHAMT | FUNCT = 0xFC00FFFF.
    .TGE  = { {.TGE,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x00000030, 0xFC00FFFF, .MIPS_II, {}} },
    .TGEU = { {.TGEU, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x00000031, 0xFC00FFFF, .MIPS_II, {}} },
    .TLT  = { {.TLT,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x00000032, 0xFC00FFFF, .MIPS_II, {}} },
    .TLTU = { {.TLTU, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x00000033, 0xFC00FFFF, .MIPS_II, {}} },
    .TEQ  = { {.TEQ,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x00000034, 0xFC00FFFF, .MIPS_II, {}} },
    .TNE  = { {.TNE,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x00000036, 0xFC00FFFF, .MIPS_II, {}} },

    // Branch-likely (nullify delay slot if not taken).
    .BEQL    = { {.BEQL,    {.GPR,.GPR,.REL16,.NONE},  {.RS,.RT,.BRANCH_16,.NONE},   0x50000000, 0xFC000000, .MIPS_II, {delay_slot=true, likely=true}} },
    .BNEL    = { {.BNEL,    {.GPR,.GPR,.REL16,.NONE},  {.RS,.RT,.BRANCH_16,.NONE},   0x54000000, 0xFC000000, .MIPS_II, {delay_slot=true, likely=true}} },
    .BLEZL   = { {.BLEZL,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x58000000, 0xFC1F0000, .MIPS_II, {delay_slot=true, likely=true}} },
    .BGTZL   = { {.BGTZL,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x5C000000, 0xFC1F0000, .MIPS_II, {delay_slot=true, likely=true}} },

    // R6 two-register compact branches (no delay slot). Unique major opcodes
    // for the EQ/NE/ordered-unsigned forms; the signed BGEC/BLTC share POP26/
    // POP27 (opcodes 22/23) with the one-register compacts below and with the
    // pre-R6 BLEZL/BGTZL -- the mask sort tries the more-specific rt=0 (BLEZL)
    // and rs=0 (BLEZC) forms first, and decode_one_inline re-disambiguates the
    // POP26/POP27 group by the rs/rt relationship.
    .BEQC    = { {.BEQC,    {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x20000000, 0xFC000000, .MIPS32_R6, {}} },
    .BNEC    = { {.BNEC,    {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x60000000, 0xFC000000, .MIPS32_R6, {}} },
    .BGEUC   = { {.BGEUC,   {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x18000000, 0xFC000000, .MIPS32_R6, {}} },
    .BLTUC   = { {.BLTUC,   {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x1C000000, 0xFC000000, .MIPS32_R6, {}} },
    .BGEC    = { {.BGEC,    {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x58000000, 0xFC000000, .MIPS32_R6, {}} },
    .BLTC    = { {.BLTC,    {.GPR,.GPR,.REL16,.NONE}, {.RS,.RT,.BRANCH_16,.NONE}, 0x5C000000, 0xFC000000, .MIPS32_R6, {}} },
    // One-register compacts: BLEZC/BGTZC set rs=0 (specific mask); BGEZC/BLTZC
    // set rs=rt (encoded via RS_RT, general mask -- decode hook recovers them).
    .BLEZC   = { {.BLEZC,   {.GPR,.REL16,.NONE,.NONE}, {.RT,.BRANCH_16,.NONE,.NONE}, 0x58000000, 0xFFE00000, .MIPS32_R6, {}} },
    .BGTZC   = { {.BGTZC,   {.GPR,.REL16,.NONE,.NONE}, {.RT,.BRANCH_16,.NONE,.NONE}, 0x5C000000, 0xFFE00000, .MIPS32_R6, {}} },
    .BGEZC   = { {.BGEZC,   {.GPR,.REL16,.NONE,.NONE}, {.RS_RT,.BRANCH_16,.NONE,.NONE}, 0x58000000, 0xFC000000, .MIPS32_R6, {}} },
    .BLTZC   = { {.BLTZC,   {.GPR,.REL16,.NONE,.NONE}, {.RS_RT,.BRANCH_16,.NONE,.NONE}, 0x5C000000, 0xFC000000, .MIPS32_R6, {}} },
    .BLTZL   = { {.BLTZL,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04020000, 0xFC1F0000, .MIPS_II, {delay_slot=true, likely=true}} },
    .BGEZL   = { {.BGEZL,   {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04030000, 0xFC1F0000, .MIPS_II, {delay_slot=true, likely=true}} },
    .BLTZALL = { {.BLTZALL, {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04120000, 0xFC1F0000, .MIPS_II, {delay_slot=true, likely=true}} },
    .BGEZALL = { {.BGEZALL, {.GPR,.REL16,.NONE,.NONE}, {.RS,.BRANCH_16,.NONE,.NONE}, 0x04130000, 0xFC1F0000, .MIPS_II, {delay_slot=true, likely=true}} },

    // =========================================================================
    // §3 MIPS III additions (64-bit core)
    // =========================================================================

    // Doubleword arithmetic R-type (SPECIAL funct 0x2C-0x2F).
    .DADD  = { {.DADD,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000002C, 0xFC0007FF, .MIPS_III, {only_64=true}} },
    .DADDU = { {.DADDU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000002D, 0xFC0007FF, .MIPS_III, {only_64=true}} },
    .DSUB  = { {.DSUB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000002E, 0xFC0007FF, .MIPS_III, {only_64=true}} },
    .DSUBU = { {.DSUBU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000002F, 0xFC0007FF, .MIPS_III, {only_64=true}} },

    // Doubleword arithmetic I-type (opcodes 0x18/0x19).
    .DADDI  = { {.DADDI,  {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x60000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .DADDIU = { {.DADDIU, {.GPR,.GPR,.IMM16S,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x64000000, 0xFC000000, .MIPS_III, {only_64=true}} },

    // Doubleword multiply/divide.
    .DMULT  = { {.DMULT,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x0000001C, 0xFC00FFFF, .MIPS_III, {only_64=true, writes_hilo=true}} },
    .DMULTU = { {.DMULTU, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x0000001D, 0xFC00FFFF, .MIPS_III, {only_64=true, writes_hilo=true}} },
    .DDIV   = { {.DDIV,   {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x0000001E, 0xFC00FFFF, .MIPS_III, {only_64=true, writes_hilo=true}} },
    .DDIVU  = { {.DDIVU,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x0000001F, 0xFC00FFFF, .MIPS_III, {only_64=true, writes_hilo=true}} },

    // Doubleword shifts by constant.
    .DSLL   = { {.DSLL,   {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x00000038, 0xFFE0003F, .MIPS_III, {only_64=true}} },
    .DSRL   = { {.DSRL,   {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x0000003A, 0xFFE0003F, .MIPS_III, {only_64=true}} },
    .DSRA   = { {.DSRA,   {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x0000003B, 0xFFE0003F, .MIPS_III, {only_64=true}} },
    .DSLL32 = { {.DSLL32, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x0000003C, 0xFFE0003F, .MIPS_III, {only_64=true}} },
    .DSRL32 = { {.DSRL32, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x0000003E, 0xFFE0003F, .MIPS_III, {only_64=true}} },
    .DSRA32 = { {.DSRA32, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x0000003F, 0xFFE0003F, .MIPS_III, {only_64=true}} },

    // Doubleword variable shifts (count from $rs).
    .DSLLV = { {.DSLLV, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x00000014, 0xFC0007FF, .MIPS_III, {only_64=true}} },
    .DSRLV = { {.DSRLV, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x00000016, 0xFC0007FF, .MIPS_III, {only_64=true}} },
    .DSRAV = { {.DSRAV, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x00000017, 0xFC0007FF, .MIPS_III, {only_64=true}} },

    // Doubleword loads/stores.
    .LD  = { {.LD,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xDC000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .LDL = { {.LDL, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x68000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .LDR = { {.LDR, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x6C000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .LWU = { {.LWU, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x9C000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .SD  = { {.SD,  {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xFC000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .SDL = { {.SDL, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xB0000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .SDR = { {.SDR, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xB4000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .LLD = { {.LLD, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xD0000000, 0xFC000000, .MIPS_III, {only_64=true}} },
    .SCD = { {.SCD, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xF0000000, 0xFC000000, .MIPS_III, {only_64=true}} },

    // =========================================================================
    // §4 MIPS IV additions
    // =========================================================================

    // Conditional move (GPR by GPR).  SPECIAL funct 0x0A/0x0B.
    .MOVZ = { {.MOVZ, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000000A, 0xFC0007FF, .MIPS_IV, {}} },
    .MOVN = { {.MOVN, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000000B, 0xFC0007FF, .MIPS_IV, {}} },

    // GPR move on FPU condition code (SPECIAL funct 0x01; bit 16 = tf; cc at bits 20-18).
    // mask = OPCODE | (bit 17 = 0) | (bit 16 = tf-fixed) | SHAMT | FUNCT = 0xFC03073F
    .MOVF = { {.MOVF, {.GPR,.GPR,.FCC,.NONE}, {.RD,.RS,.FCC_BC,.NONE}, 0x00000001, 0xFC03073F, .MIPS_IV, {}} },
    .MOVT = { {.MOVT, {.GPR,.GPR,.FCC,.NONE}, {.RD,.RS,.FCC_BC,.NONE}, 0x00010001, 0xFC03073F, .MIPS_IV, {}} },

    // Prefetch (opcode 0x33: "PREF hint, off(base)"; hint at rt slot).
    .PREF = { {.PREF, {.IMM5,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xCC000000, 0xFC000000, .MIPS_IV, {}} },

    // Indexed FP load/store (COP1X = opcode 0x13).  R-type with funct selecting
    // op.  Layout: [op 0x13][base][index][0 5][fd 5][funct 6].
    // mask = OPCODE | SHAMT | FUNCT = 0xFC0007FF (bits 10-6 fixed at 0, except in PREFX).
    .LWXC1 = { {.LWXC1, {.FPR_S,.GPR,.GPR,.NONE}, {.FD,.RS,.RT,.NONE}, 0x4C000000, 0xFC0007FF, .MIPS_IV, {}} },
    .LDXC1 = { {.LDXC1, {.FPR_D,.GPR,.GPR,.NONE}, {.FD,.RS,.RT,.NONE}, 0x4C000001, 0xFC0007FF, .MIPS_IV, {}} },
    .SWXC1 = { {.SWXC1, {.FPR_S,.GPR,.GPR,.NONE}, {.FS,.RS,.RT,.NONE}, 0x4C000008, 0xFC0007FF, .MIPS_IV, {}} },
    .SDXC1 = { {.SDXC1, {.FPR_D,.GPR,.GPR,.NONE}, {.FS,.RS,.RT,.NONE}, 0x4C000009, 0xFC0007FF, .MIPS_IV, {}} },
    // PREFX: hint at fs slot, no destination FPR.
    .PREFX = { {.PREFX, {.IMM5,.GPR,.GPR,.NONE}, {.FS,.RS,.RT,.NONE}, 0x4C00000F, 0xFC0007FF, .MIPS_IV, {}} },

    // =========================================================================
    // §5 MIPS32 R1 / R2 — integer additions
    // =========================================================================

    // SPECIAL2 (opcode 0x1C) — common shape: bits = (0x1C<<26) | funct = 0x70000000 | f.
    // mask = OPCODE | SHAMT | FUNCT = 0xFC0007FF (shamt=0 fixed).
    .MADD  = { {.MADD,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x70000000, 0xFC00FFFF, .MIPS32_R1, {writes_hilo=true}} },
    .MADDU = { {.MADDU, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x70000001, 0xFC00FFFF, .MIPS32_R1, {writes_hilo=true}} },
    .MUL   = { {.MUL,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x70000002, 0xFC0007FF, .MIPS32_R1, {}} },
    .MSUB  = { {.MSUB,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x70000004, 0xFC00FFFF, .MIPS32_R1, {writes_hilo=true}} },
    .MSUBU = { {.MSUBU, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x70000005, 0xFC00FFFF, .MIPS32_R1, {writes_hilo=true}} },
    .CLZ   = { {.CLZ,   {.GPR,.GPR,.NONE,.NONE}, {.RD,.RS,.NONE,.NONE}, 0x70000020, 0xFC1F07FF, .MIPS32_R1, {}} },
    .CLO   = { {.CLO,   {.GPR,.GPR,.NONE,.NONE}, {.RD,.RS,.NONE,.NONE}, 0x70000021, 0xFC1F07FF, .MIPS32_R1, {}} },
    .DCLZ  = { {.DCLZ,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RS,.NONE,.NONE}, 0x70000024, 0xFC1F07FF, .MIPS64_R1, {only_64=true}} },
    .DCLO  = { {.DCLO,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RS,.NONE,.NONE}, 0x70000025, 0xFC1F07FF, .MIPS64_R1, {only_64=true}} },
    .SDBBP = { {.SDBBP, {.IMM20,.NONE,.NONE,.NONE}, {.IMM_20,.NONE,.NONE,.NONE}, 0x7000003F, 0xFC00003F, .MIPS32_R1, {}} },

    // Hint NOPs and barriers (SPECIAL funct 0x00 with shamt != 0, rd != 0).
    // SSNOP: SLL $0, $0, 1.  EHB: SLL $0, $0, 3.  PAUSE: SLL $0, $0, 5.
    .SSNOP = { {.SSNOP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00000040, 0xFFFFFFFF, .MIPS32_R1, {}} },
    .EHB   = { {.EHB,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x000000C0, 0xFFFFFFFF, .MIPS32_R2, {}} },
    .PAUSE = { {.PAUSE, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00000140, 0xFFFFFFFF, .MIPS32_R2, {}} },

    // SPECIAL3 (opcode 0x1F): bitfield ops EXT/INS and 64-bit variants.
    // Encoder layout for EXT: rt=dst, rs=src, msbd=size-1 at rd-slot, lsb=pos at shamt.
    // mask = OPCODE | FUNCT = 0xFC00003F.
    .EXT   = { {.EXT,   {.GPR,.GPR,.IMM5,.IMM5}, {.RT,.RS,.SHAMT,.RD}, 0x7C000000, 0xFC00003F, .MIPS32_R2, {}} },
    .DEXTM = { {.DEXTM, {.GPR,.GPR,.IMM5,.IMM5}, {.RT,.RS,.SHAMT,.RD}, 0x7C000001, 0xFC00003F, .MIPS64_R2, {only_64=true}} },
    .DEXTU = { {.DEXTU, {.GPR,.GPR,.IMM5,.IMM5}, {.RT,.RS,.SHAMT,.RD}, 0x7C000002, 0xFC00003F, .MIPS64_R2, {only_64=true}} },
    .DEXT  = { {.DEXT,  {.GPR,.GPR,.IMM5,.IMM5}, {.RT,.RS,.SHAMT,.RD}, 0x7C000003, 0xFC00003F, .MIPS64_R2, {only_64=true}} },
    .INS   = { {.INS,   {.GPR,.GPR,.IMM5,.IMM5}, {.RT,.RS,.SHAMT,.RD}, 0x7C000004, 0xFC00003F, .MIPS32_R2, {}} },
    .DINSM = { {.DINSM, {.GPR,.GPR,.IMM5,.IMM5}, {.RT,.RS,.SHAMT,.RD}, 0x7C000005, 0xFC00003F, .MIPS64_R2, {only_64=true}} },
    .DINSU = { {.DINSU, {.GPR,.GPR,.IMM5,.IMM5}, {.RT,.RS,.SHAMT,.RD}, 0x7C000006, 0xFC00003F, .MIPS64_R2, {only_64=true}} },
    .DINS  = { {.DINS,  {.GPR,.GPR,.IMM5,.IMM5}, {.RT,.RS,.SHAMT,.RD}, 0x7C000007, 0xFC00003F, .MIPS64_R2, {only_64=true}} },

    // BSHFL family (SPECIAL3 funct 0x20, shamt selects op).  No operand
    // bits in shamt -- it's a fixed selector.
    // WSBH (shamt 0x02), SEB (shamt 0x10), SEH (shamt 0x18).
    .WSBH = { {.WSBH, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C0000A0, 0xFFE007FF, .MIPS32_R2, {}} },
    .SEB  = { {.SEB,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000420, 0xFFE007FF, .MIPS32_R2, {}} },
    .SEH  = { {.SEH,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000620, 0xFFE007FF, .MIPS32_R2, {}} },

    // DBSHFL family (SPECIAL3 funct 0x24).
    // DSBH (shamt 0x02), DSHD (shamt 0x05).
    .DSBH = { {.DSBH, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C0000A4, 0xFFE007FF, .MIPS64_R2, {only_64=true}} },
    .DSHD = { {.DSHD, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000164, 0xFFE007FF, .MIPS64_R2, {only_64=true}} },

    // Rotate (SPECIAL rs=1).  ROTR is SRL with rs=1; DROTR is DSRL with rs=1.
    .ROTR    = { {.ROTR,    {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x00200002, 0xFFE0003F, .MIPS32_R2, {}} },
    .DROTR   = { {.DROTR,   {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x0020003A, 0xFFE0003F, .MIPS64_R2, {only_64=true}} },
    .DROTR32 = { {.DROTR32, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x0020003E, 0xFFE0003F, .MIPS64_R2, {only_64=true}} },
    // ROTRV / DROTRV: variable rotate; shamt=1 marks the rotate variant of SRLV/DSRLV.
    .ROTRV  = { {.ROTRV,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x00000046, 0xFC0007FF, .MIPS32_R2, {}} },
    .DROTRV = { {.DROTRV, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x00000056, 0xFC0007FF, .MIPS64_R2, {only_64=true}} },

    // R2 COP0 CO=1 ops (ERET, DERET, WAIT).
    .ERET  = { {.ERET,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x42000018, 0xFFFFFFFF, .MIPS_II, {}} },
    .DERET = { {.DERET, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4200001F, 0xFFFFFFFF, .MIPS32_R1, {}} },
    .WAIT  = { {.WAIT,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x42000020, 0xFE00003F, .MIPS32_R1, {}} },

    // =========================================================================
    // §7 FPU (COP1, opcode 0x11)
    // =========================================================================
    //
    // FR-type layout: [opcode 0x11][fmt 5][ft 5][fs 5][fd 5][funct 6].
    //   fmt: 0x10=S, 0x11=D, 0x14=W, 0x15=L, 0x16=PS.
    //   Base bits per fmt:  S=0x46000000, D=0x46200000, W=0x46800000,
    //                       L=0x46A00000, PS=0x46C00000.
    //   Arithmetic mask: OPCODE | RS | FUNCT = 0xFFE0003F.
    //   Unary (ft=0) mask: OPCODE | RS | RT | FUNCT = 0xFFFF003F.

    // ---- Moves (rs selects op) -----------------------------------------------
    // Mask covers opcode + rs + bits 10-0 (rd reused as fs; sel bits 2-0 = 0).
    .MFC1  = { {.MFC1,  {.GPR,.FPR_S,.NONE,.NONE}, {.RT,.FS,.NONE,.NONE}, 0x44000000, 0xFFE007FF, .FPU, {}} },
    .DMFC1 = { {.DMFC1, {.GPR,.FPR_D,.NONE,.NONE}, {.RT,.FS,.NONE,.NONE}, 0x44200000, 0xFFE007FF, .MIPS_III, {only_64=true}} },
    .CFC1  = { {.CFC1,  {.GPR,.FCR,.NONE,.NONE},   {.RT,.FS,.NONE,.NONE}, 0x44400000, 0xFFE007FF, .FPU, {}} },
    .MFHC1 = { {.MFHC1, {.GPR,.FPR_D,.NONE,.NONE}, {.RT,.FS,.NONE,.NONE}, 0x44600000, 0xFFE007FF, .MIPS32_R2, {}} },
    .MTC1  = { {.MTC1,  {.GPR,.FPR_S,.NONE,.NONE}, {.RT,.FS,.NONE,.NONE}, 0x44800000, 0xFFE007FF, .FPU, {}} },
    .DMTC1 = { {.DMTC1, {.GPR,.FPR_D,.NONE,.NONE}, {.RT,.FS,.NONE,.NONE}, 0x44A00000, 0xFFE007FF, .MIPS_III, {only_64=true}} },
    .CTC1  = { {.CTC1,  {.GPR,.FCR,.NONE,.NONE},   {.RT,.FS,.NONE,.NONE}, 0x44C00000, 0xFFE007FF, .FPU, {}} },
    .MTHC1 = { {.MTHC1, {.GPR,.FPR_D,.NONE,.NONE}, {.RT,.FS,.NONE,.NONE}, 0x44E00000, 0xFFE007FF, .MIPS32_R2, {}} },

    // ---- Load/Store (I-type with FT) -----------------------------------------
    .LWC1 = { {.LWC1, {.FPR_S,.MEM,.NONE,.NONE}, {.FT,.OFFSET_BASE,.NONE,.NONE}, 0xC4000000, 0xFC000000, .FPU, {}} },
    .SWC1 = { {.SWC1, {.FPR_S,.MEM,.NONE,.NONE}, {.FT,.OFFSET_BASE,.NONE,.NONE}, 0xE4000000, 0xFC000000, .FPU, {}} },
    .LDC1 = { {.LDC1, {.FPR_D,.MEM,.NONE,.NONE}, {.FT,.OFFSET_BASE,.NONE,.NONE}, 0xD4000000, 0xFC000000, .MIPS_II, {}} },
    .SDC1 = { {.SDC1, {.FPR_D,.MEM,.NONE,.NONE}, {.FT,.OFFSET_BASE,.NONE,.NONE}, 0xF4000000, 0xFC000000, .MIPS_II, {}} },

    // ---- Arithmetic: ADD / SUB / MUL / DIV  (S, D, PS) ------------------------

    .ADD_S = { {.ADD_S, {.FPR_S,.FPR_S,.FPR_S,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46000000, 0xFFE0003F, .FPU, {}} },
    .ADD_D = { {.ADD_D, {.FPR_D,.FPR_D,.FPR_D,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46200000, 0xFFE0003F, .FPU, {}} },
    .ADD_PS = { {.ADD_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46C00000, 0xFFE0003F, .MIPS_V, {}} },

    .SUB_S = { {.SUB_S, {.FPR_S,.FPR_S,.FPR_S,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46000001, 0xFFE0003F, .FPU, {}} },
    .SUB_D = { {.SUB_D, {.FPR_D,.FPR_D,.FPR_D,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46200001, 0xFFE0003F, .FPU, {}} },
    .SUB_PS = { {.SUB_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46C00001, 0xFFE0003F, .MIPS_V, {}} },

    .MUL_S = { {.MUL_S, {.FPR_S,.FPR_S,.FPR_S,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46000002, 0xFFE0003F, .FPU, {}} },
    .MUL_D = { {.MUL_D, {.FPR_D,.FPR_D,.FPR_D,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46200002, 0xFFE0003F, .FPU, {}} },
    .MUL_PS = { {.MUL_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46C00002, 0xFFE0003F, .MIPS_V, {}} },

    .DIV_S = { {.DIV_S, {.FPR_S,.FPR_S,.FPR_S,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46000003, 0xFFE0003F, .FPU, {}} },
    .DIV_D = { {.DIV_D, {.FPR_D,.FPR_D,.FPR_D,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46200003, 0xFFE0003F, .FPU, {}} },

    // ---- Unary: SQRT/ABS/NEG/MOV/RECIP/RSQRT ---------------------------------
    // ft=0 fixed; mask = OPCODE | RS | RT | FUNCT = 0xFFFF003F.

    .SQRT_S  = { {.SQRT_S,  {.FPR_S,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000004, 0xFFFF003F, .MIPS_II, {}} },
    .SQRT_D  = { {.SQRT_D,  {.FPR_D,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200004, 0xFFFF003F, .MIPS_II, {}} },
    .ABS_S   = { {.ABS_S,   {.FPR_S,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000005, 0xFFFF003F, .FPU, {}} },
    .ABS_D   = { {.ABS_D,   {.FPR_D,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200005, 0xFFFF003F, .FPU, {}} },
    .ABS_PS  = { {.ABS_PS,  {.FPR_PS,.FPR_PS,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46C00005, 0xFFFF003F, .MIPS_V, {}} },
    .MOV_S   = { {.MOV_S,   {.FPR_S,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000006, 0xFFFF003F, .FPU, {}} },
    .MOV_D   = { {.MOV_D,   {.FPR_D,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200006, 0xFFFF003F, .FPU, {}} },
    .MOV_PS  = { {.MOV_PS,  {.FPR_PS,.FPR_PS,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46C00006, 0xFFFF003F, .MIPS_V, {}} },
    .NEG_S   = { {.NEG_S,   {.FPR_S,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000007, 0xFFFF003F, .FPU, {}} },
    .NEG_D   = { {.NEG_D,   {.FPR_D,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200007, 0xFFFF003F, .FPU, {}} },
    .NEG_PS  = { {.NEG_PS,  {.FPR_PS,.FPR_PS,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46C00007, 0xFFFF003F, .MIPS_V, {}} },
    .RECIP_S = { {.RECIP_S, {.FPR_S,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000015, 0xFFFF003F, .MIPS_IV, {}} },
    .RECIP_D = { {.RECIP_D, {.FPR_D,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200015, 0xFFFF003F, .MIPS_IV, {}} },
    .RSQRT_S = { {.RSQRT_S, {.FPR_S,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000016, 0xFFFF003F, .MIPS_IV, {}} },
    .RSQRT_D = { {.RSQRT_D, {.FPR_D,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200016, 0xFFFF003F, .MIPS_IV, {}} },

    // ---- Round-to-fixed (S, D source) ----------------------------------------

    .ROUND_W_S = { {.ROUND_W_S, {.FPR_W,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4600000C, 0xFFFF003F, .MIPS_II, {}} },
    .ROUND_W_D = { {.ROUND_W_D, {.FPR_W,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4620000C, 0xFFFF003F, .MIPS_II, {}} },
    .TRUNC_W_S = { {.TRUNC_W_S, {.FPR_W,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4600000D, 0xFFFF003F, .MIPS_II, {}} },
    .TRUNC_W_D = { {.TRUNC_W_D, {.FPR_W,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4620000D, 0xFFFF003F, .MIPS_II, {}} },
    .CEIL_W_S  = { {.CEIL_W_S,  {.FPR_W,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4600000E, 0xFFFF003F, .MIPS_II, {}} },
    .CEIL_W_D  = { {.CEIL_W_D,  {.FPR_W,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4620000E, 0xFFFF003F, .MIPS_II, {}} },
    .FLOOR_W_S = { {.FLOOR_W_S, {.FPR_W,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4600000F, 0xFFFF003F, .MIPS_II, {}} },
    .FLOOR_W_D = { {.FLOOR_W_D, {.FPR_W,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4620000F, 0xFFFF003F, .MIPS_II, {}} },
    .ROUND_L_S = { {.ROUND_L_S, {.FPR_L,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000008, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .ROUND_L_D = { {.ROUND_L_D, {.FPR_L,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200008, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .TRUNC_L_S = { {.TRUNC_L_S, {.FPR_L,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000009, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .TRUNC_L_D = { {.TRUNC_L_D, {.FPR_L,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200009, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .CEIL_L_S  = { {.CEIL_L_S,  {.FPR_L,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4600000A, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .CEIL_L_D  = { {.CEIL_L_D,  {.FPR_L,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4620000A, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .FLOOR_L_S = { {.FLOOR_L_S, {.FPR_L,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4600000B, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .FLOOR_L_D = { {.FLOOR_L_D, {.FPR_L,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x4620000B, 0xFFFF003F, .MIPS_III, {only_64=true}} },

    // ---- Conversions ---------------------------------------------------------
    // CVT.dst.src — fmt = src, funct = "convert to dst" (0x20=S, 0x21=D, 0x24=W, 0x25=L).

    .CVT_S_D = { {.CVT_S_D, {.FPR_S,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200020, 0xFFFF003F, .FPU, {}} },
    .CVT_S_W = { {.CVT_S_W, {.FPR_S,.FPR_W,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46800020, 0xFFFF003F, .FPU, {}} },
    .CVT_S_L = { {.CVT_S_L, {.FPR_S,.FPR_L,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46A00020, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .CVT_D_S = { {.CVT_D_S, {.FPR_D,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000021, 0xFFFF003F, .FPU, {}} },
    .CVT_D_W = { {.CVT_D_W, {.FPR_D,.FPR_W,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46800021, 0xFFFF003F, .FPU, {}} },
    .CVT_D_L = { {.CVT_D_L, {.FPR_D,.FPR_L,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46A00021, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .CVT_W_S = { {.CVT_W_S, {.FPR_W,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000024, 0xFFFF003F, .FPU, {}} },
    .CVT_W_D = { {.CVT_W_D, {.FPR_W,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200024, 0xFFFF003F, .FPU, {}} },
    .CVT_L_S = { {.CVT_L_S, {.FPR_L,.FPR_S,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46000025, 0xFFFF003F, .MIPS_III, {only_64=true}} },
    .CVT_L_D = { {.CVT_L_D, {.FPR_L,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200025, 0xFFFF003F, .MIPS_III, {only_64=true}} },

    // ---- FP Branches (BC1F/T/FL/TL).  Bits 17-16 select tf:nd. ---------------
    // mask = OPCODE | RS | (bits 17-16) = 0xFFE30000.  CC field is bits 20-18 (operand).

    .BC1F  = { {.BC1F,  {.FCC,.REL16,.NONE,.NONE}, {.FCC_BC,.BRANCH_16,.NONE,.NONE}, 0x45000000, 0xFFE30000, .FPU, {delay_slot=true}} },
    .BC1T  = { {.BC1T,  {.FCC,.REL16,.NONE,.NONE}, {.FCC_BC,.BRANCH_16,.NONE,.NONE}, 0x45010000, 0xFFE30000, .FPU, {delay_slot=true}} },
    .BC1FL = { {.BC1FL, {.FCC,.REL16,.NONE,.NONE}, {.FCC_BC,.BRANCH_16,.NONE,.NONE}, 0x45020000, 0xFFE30000, .MIPS_II, {delay_slot=true, likely=true}} },
    .BC1TL = { {.BC1TL, {.FCC,.REL16,.NONE,.NONE}, {.FCC_BC,.BRANCH_16,.NONE,.NONE}, 0x45030000, 0xFFE30000, .MIPS_II, {delay_slot=true, likely=true}} },

    // ---- FP Compares: 16 conditions × 3 formats (S, D, PS) -------------------
    // Layout: [op 0x11][fmt][ft][fs][cc 3][0 2][FC=11][cond 4]
    // bits = (0x11<<26) | (fmt<<21) | 0x30 | cond. cc operand at bits 10-8.
    // mask = OPCODE | RS | bits 7-6 | FUNCT = 0xFFE000FF.

    .C_F_S    = { {.C_F_S,    {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000030, 0xFFE000FF, .FPU, {}} },
    .C_F_D    = { {.C_F_D,    {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200030, 0xFFE000FF, .FPU, {}} },
    .C_F_PS   = { {.C_F_PS,   {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00030, 0xFFE000FF, .MIPS_V, {}} },
    .C_UN_S   = { {.C_UN_S,   {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000031, 0xFFE000FF, .FPU, {}} },
    .C_UN_D   = { {.C_UN_D,   {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200031, 0xFFE000FF, .FPU, {}} },
    .C_UN_PS  = { {.C_UN_PS,  {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00031, 0xFFE000FF, .MIPS_V, {}} },
    .C_EQ_S   = { {.C_EQ_S,   {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000032, 0xFFE000FF, .FPU, {}} },
    .C_EQ_D   = { {.C_EQ_D,   {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200032, 0xFFE000FF, .FPU, {}} },
    .C_EQ_PS  = { {.C_EQ_PS,  {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00032, 0xFFE000FF, .MIPS_V, {}} },
    .C_UEQ_S  = { {.C_UEQ_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000033, 0xFFE000FF, .FPU, {}} },
    .C_UEQ_D  = { {.C_UEQ_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200033, 0xFFE000FF, .FPU, {}} },
    .C_UEQ_PS = { {.C_UEQ_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00033, 0xFFE000FF, .MIPS_V, {}} },
    .C_OLT_S  = { {.C_OLT_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000034, 0xFFE000FF, .FPU, {}} },
    .C_OLT_D  = { {.C_OLT_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200034, 0xFFE000FF, .FPU, {}} },
    .C_OLT_PS = { {.C_OLT_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00034, 0xFFE000FF, .MIPS_V, {}} },
    .C_ULT_S  = { {.C_ULT_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000035, 0xFFE000FF, .FPU, {}} },
    .C_ULT_D  = { {.C_ULT_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200035, 0xFFE000FF, .FPU, {}} },
    .C_ULT_PS = { {.C_ULT_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00035, 0xFFE000FF, .MIPS_V, {}} },
    .C_OLE_S  = { {.C_OLE_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000036, 0xFFE000FF, .FPU, {}} },
    .C_OLE_D  = { {.C_OLE_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200036, 0xFFE000FF, .FPU, {}} },
    .C_OLE_PS = { {.C_OLE_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00036, 0xFFE000FF, .MIPS_V, {}} },
    .C_ULE_S  = { {.C_ULE_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000037, 0xFFE000FF, .FPU, {}} },
    .C_ULE_D  = { {.C_ULE_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200037, 0xFFE000FF, .FPU, {}} },
    .C_ULE_PS = { {.C_ULE_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00037, 0xFFE000FF, .MIPS_V, {}} },
    .C_SF_S   = { {.C_SF_S,   {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000038, 0xFFE000FF, .FPU, {}} },
    .C_SF_D   = { {.C_SF_D,   {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200038, 0xFFE000FF, .FPU, {}} },
    .C_SF_PS  = { {.C_SF_PS,  {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00038, 0xFFE000FF, .MIPS_V, {}} },
    .C_NGLE_S  = { {.C_NGLE_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46000039, 0xFFE000FF, .FPU, {}} },
    .C_NGLE_D  = { {.C_NGLE_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46200039, 0xFFE000FF, .FPU, {}} },
    .C_NGLE_PS = { {.C_NGLE_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C00039, 0xFFE000FF, .MIPS_V, {}} },
    .C_SEQ_S  = { {.C_SEQ_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4600003A, 0xFFE000FF, .FPU, {}} },
    .C_SEQ_D  = { {.C_SEQ_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4620003A, 0xFFE000FF, .FPU, {}} },
    .C_SEQ_PS = { {.C_SEQ_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C0003A, 0xFFE000FF, .MIPS_V, {}} },
    .C_NGL_S  = { {.C_NGL_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4600003B, 0xFFE000FF, .FPU, {}} },
    .C_NGL_D  = { {.C_NGL_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4620003B, 0xFFE000FF, .FPU, {}} },
    .C_NGL_PS = { {.C_NGL_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C0003B, 0xFFE000FF, .MIPS_V, {}} },
    .C_LT_S   = { {.C_LT_S,   {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4600003C, 0xFFE000FF, .FPU, {}} },
    .C_LT_D   = { {.C_LT_D,   {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4620003C, 0xFFE000FF, .FPU, {}} },
    .C_LT_PS  = { {.C_LT_PS,  {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C0003C, 0xFFE000FF, .MIPS_V, {}} },
    .C_NGE_S  = { {.C_NGE_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4600003D, 0xFFE000FF, .FPU, {}} },
    .C_NGE_D  = { {.C_NGE_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4620003D, 0xFFE000FF, .FPU, {}} },
    .C_NGE_PS = { {.C_NGE_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C0003D, 0xFFE000FF, .MIPS_V, {}} },
    .C_LE_S   = { {.C_LE_S,   {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4600003E, 0xFFE000FF, .FPU, {}} },
    .C_LE_D   = { {.C_LE_D,   {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4620003E, 0xFFE000FF, .FPU, {}} },
    .C_LE_PS  = { {.C_LE_PS,  {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C0003E, 0xFFE000FF, .MIPS_V, {}} },
    .C_NGT_S  = { {.C_NGT_S,  {.FPR_S,.FPR_S,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4600003F, 0xFFE000FF, .FPU, {}} },
    .C_NGT_D  = { {.C_NGT_D,  {.FPR_D,.FPR_D,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x4620003F, 0xFFE000FF, .FPU, {}} },
    .C_NGT_PS = { {.C_NGT_PS, {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FS,.FT,.FCC_CC,.NONE}, 0x46C0003F, 0xFFE000FF, .MIPS_V, {}} },

    // =========================================================================
    // §8 COP0 — system control
    // =========================================================================
    // MFC0/MTC0/etc: [op=0x10][rs=op][rt][rd][0 8][sel 3].
    // mask covers opcode + rs + bits 10-3 (zero), leaving rt/rd/sel as operands.

    .MFC0  = { {.MFC0,  {.GPR,.CP0_REG,.SEL,.NONE}, {.RT,.RD,.SEL,.NONE}, 0x40000000, 0xFFE007F8, .COP0, {}} },
    .DMFC0 = { {.DMFC0, {.GPR,.CP0_REG,.SEL,.NONE}, {.RT,.RD,.SEL,.NONE}, 0x40200000, 0xFFE007F8, .COP0, {only_64=true}} },
    .MTC0  = { {.MTC0,  {.GPR,.CP0_REG,.SEL,.NONE}, {.RT,.RD,.SEL,.NONE}, 0x40800000, 0xFFE007F8, .COP0, {}} },
    .DMTC0 = { {.DMTC0, {.GPR,.CP0_REG,.SEL,.NONE}, {.RT,.RD,.SEL,.NONE}, 0x40A00000, 0xFFE007F8, .COP0, {only_64=true}} },
    .MFHC0 = { {.MFHC0, {.GPR,.CP0_REG,.SEL,.NONE}, {.RT,.RD,.SEL,.NONE}, 0x40400000, 0xFFE007F8, .MIPS32_R5, {}} },
    .MTHC0 = { {.MTHC0, {.GPR,.CP0_REG,.SEL,.NONE}, {.RT,.RD,.SEL,.NONE}, 0x40C00000, 0xFFE007F8, .MIPS32_R5, {}} },

    // TLB ops + CACHE (CO=1).  No user-visible operands for TLB*.
    .TLBR  = { {.TLBR,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x42000001, 0xFFFFFFFF, .COP0, {}} },
    .TLBWI = { {.TLBWI, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x42000002, 0xFFFFFFFF, .COP0, {}} },
    .TLBWR = { {.TLBWR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x42000006, 0xFFFFFFFF, .COP0, {}} },
    .TLBP  = { {.TLBP,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x42000008, 0xFFFFFFFF, .COP0, {}} },

    // CACHE op,off(base): rt slot holds the 5-bit cache op selector.
    .CACHE = { {.CACHE, {.IMM5,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xBC000000, 0xFC000000, .MIPS_II, {}} },

    // =========================================================================
    // §9 PS1 GTE — COP2 Geometry Transformation Engine
    // =========================================================================
    //
    // GTE ops use COP2 with the CO bit (bit 25) set; the 6-bit funct field
    // identifies the operation, and 19 cofun control bits (sf/mx/v/cv/lm
    // plus an unused upper "tag") modulate behaviour. We mask only the
    // canonical fields (opcode+CO+funct) so the encoder emits a clean
    // form and the decoder accepts any cofun-variant.

    // Standard COP2 moves (also used to address GTE data/control regs).
    .MFC2  = { {.MFC2,  {.GPR,.CP2_REG,.NONE,.NONE},  {.RT,.RD,.NONE,.NONE}, 0x48000000, 0xFFE007FF, .GTE_PS1, {}} },
    .CFC2  = { {.CFC2,  {.GPR,.CP2_CTRL,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x48400000, 0xFFE007FF, .GTE_PS1, {}} },
    .MTC2  = { {.MTC2,  {.GPR,.CP2_REG,.NONE,.NONE},  {.RT,.RD,.NONE,.NONE}, 0x48800000, 0xFFE007FF, .GTE_PS1, {}} },
    .CTC2  = { {.CTC2,  {.GPR,.CP2_CTRL,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x48C00000, 0xFFE007FF, .GTE_PS1, {}} },
    .LWC2  = { {.LWC2,  {.CP2_REG,.MEM,.NONE,.NONE},  {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xC8000000, 0xFC000000, .GTE_PS1, {}} },
    .SWC2  = { {.SWC2,  {.CP2_REG,.MEM,.NONE,.NONE},  {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xE8000000, 0xFC000000, .GTE_PS1, {}} },
    // LDC2/SDC2 exist in MIPS II+ but not on PS1 R3000A.
    .LDC2  = { {.LDC2,  {.CP2_REG,.MEM,.NONE,.NONE},  {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xD8000000, 0xFC000000, .MIPS_II, {}} },
    .SDC2  = { {.SDC2,  {.CP2_REG,.MEM,.NONE,.NONE},  {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xF8000000, 0xFC000000, .MIPS_II, {}} },

    // ---- GTE operations (cofun funct field 5-0; no user-visible operands) ----
    // All have mask = 0xFE00003F (opcode + CO + funct); the encoder emits
    // sf=0/lm=0/mx=0/v=0/cv=0/tag=0 as canonical, which is valid.

    .RTPS    = { {.RTPS,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000001, 0xFE00003F, .GTE_PS1, {}} },
    .NCLIP   = { {.NCLIP,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000006, 0xFE00003F, .GTE_PS1, {}} },
    .OP_GTE  = { {.OP_GTE,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00000C, 0xFE00003F, .GTE_PS1, {}} },
    .DPCS    = { {.DPCS,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000010, 0xFE00003F, .GTE_PS1, {}} },
    .INTPL   = { {.INTPL,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000011, 0xFE00003F, .GTE_PS1, {}} },
    .MVMVA   = { {.MVMVA,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000012, 0xFE00003F, .GTE_PS1, {}} },
    .NCDS    = { {.NCDS,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000013, 0xFE00003F, .GTE_PS1, {}} },
    .CDP     = { {.CDP,     {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000014, 0xFE00003F, .GTE_PS1, {}} },
    .NCDT    = { {.NCDT,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000016, 0xFE00003F, .GTE_PS1, {}} },
    .NCCS    = { {.NCCS,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00001B, 0xFE00003F, .GTE_PS1, {}} },
    .CC      = { {.CC,      {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00001C, 0xFE00003F, .GTE_PS1, {}} },
    .NCS     = { {.NCS,     {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00001E, 0xFE00003F, .GTE_PS1, {}} },
    .NCT     = { {.NCT,     {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000020, 0xFE00003F, .GTE_PS1, {}} },
    .SQR_GTE = { {.SQR_GTE, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000028, 0xFE00003F, .GTE_PS1, {}} },
    .DCPL    = { {.DCPL,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000029, 0xFE00003F, .GTE_PS1, {}} },
    .DPCT    = { {.DPCT,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00002A, 0xFE00003F, .GTE_PS1, {}} },
    .AVSZ3   = { {.AVSZ3,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00002D, 0xFE00003F, .GTE_PS1, {}} },
    .AVSZ4   = { {.AVSZ4,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00002E, 0xFE00003F, .GTE_PS1, {}} },
    .RTPT    = { {.RTPT,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A000030, 0xFE00003F, .GTE_PS1, {}} },
    .GPF     = { {.GPF,     {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00003D, 0xFE00003F, .GTE_PS1, {}} },
    .GPL     = { {.GPL,     {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00003E, 0xFE00003F, .GTE_PS1, {}} },
    .NCCT    = { {.NCCT,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4A00003F, 0xFE00003F, .GTE_PS1, {}} },

    // =========================================================================
    // §10 PS2 EE Multimedia Instructions (R5900)
    // =========================================================================
    //
    // PS2's R5900 puts 128-bit packed-SIMD ops in SPECIAL2 (opcode 0x1C)
    // and four sub-spaces MMI0..MMI3 (top-level functs 0x08/0x28/0x09/
    // 0x29) where the 5-bit shamt selects the actual op. Plus LQ/SQ
    // (128-bit GPR load/store at opcodes 0x1E/0x1F) and a second HI/LO
    // pair (HI1/LO1) for the dual-MAC pipeline.
    //
    // NB: opcode 0x1F conflicts with modern MIPS SPECIAL3. PS2 predates
    // SPECIAL3 so on a PS2 target SPECIAL3 doesn't exist and on a
    // modern MIPS target SQ doesn't exist -- the decoder should select
    // based on target Feature. For encoding we list both; the user picks.

    // 128-bit GPR load/store.
    .LQ = { {.LQ, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x78000000, 0xFC000000, .MMI_PS2, {}} },
    .SQ = { {.SQ, {.GPR,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0x7C000000, 0xFC000000, .MMI_PS2, {}} },

    // VU0 macro-mode 128-bit COP2 moves.
    .LQC2 = { {.LQC2, {.CP2_REG,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xD8000000, 0xFC000000, .VU_PS2, {}} },
    .SQC2 = { {.SQC2, {.CP2_REG,.MEM,.NONE,.NONE}, {.RT,.OFFSET_BASE,.NONE,.NONE}, 0xF8000000, 0xFC000000, .VU_PS2, {}} },

    // Second HI/LO pair (R5900 dual-MAC).
    .MFHI1  = { {.MFHI1,  {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x70000010, 0xFFFF07FF, .MMI_PS2, {}} },
    .MTHI1  = { {.MTHI1,  {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x70000011, 0xFC1FFFFF, .MMI_PS2, {}} },
    .MFLO1  = { {.MFLO1,  {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x70000012, 0xFFFF07FF, .MMI_PS2, {}} },
    .MTLO1  = { {.MTLO1,  {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x70000013, 0xFC1FFFFF, .MMI_PS2, {}} },
    .MULT1  = { {.MULT1,  {.GPR,.GPR,.NONE,.NONE},  {.RS,.RT,.NONE,.NONE}, 0x70000018, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },
    .MULTU1 = { {.MULTU1, {.GPR,.GPR,.NONE,.NONE},  {.RS,.RT,.NONE,.NONE}, 0x70000019, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },
    .DIV1   = { {.DIV1,   {.GPR,.GPR,.NONE,.NONE},  {.RS,.RT,.NONE,.NONE}, 0x7000001A, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },
    .DIVU1  = { {.DIVU1,  {.GPR,.GPR,.NONE,.NONE},  {.RS,.RT,.NONE,.NONE}, 0x7000001B, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },
    .MADD1  = { {.MADD1,  {.GPR,.GPR,.NONE,.NONE},  {.RS,.RT,.NONE,.NONE}, 0x70000020, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },
    .MADDU1 = { {.MADDU1, {.GPR,.GPR,.NONE,.NONE},  {.RS,.RT,.NONE,.NONE}, 0x70000021, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },

    // Pack/unpack HI:LO (PMFHL with 5-bit sub-op in sa slot).
    .PMFHL_LW  = { {.PMFHL_LW,  {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x70000030, 0xFFFF07FF, .MMI_PS2, {}} },
    .PMFHL_UW  = { {.PMFHL_UW,  {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x70000070, 0xFFFF07FF, .MMI_PS2, {}} },
    .PMFHL_SLW = { {.PMFHL_SLW, {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x700000B0, 0xFFFF07FF, .MMI_PS2, {}} },
    .PMFHL_LH  = { {.PMFHL_LH,  {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x700000F0, 0xFFFF07FF, .MMI_PS2, {}} },
    .PMFHL_SH  = { {.PMFHL_SH,  {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x70000130, 0xFFFF07FF, .MMI_PS2, {}} },
    .PMTHL_LW  = { {.PMTHL_LW,  {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x70000031, 0xFC1FFFFF, .MMI_PS2, {}} },

    // PLZCW (parallel leading-zero count).
    .PLZCW = { {.PLZCW, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RS,.NONE,.NONE}, 0x70000004, 0xFC1F07FF, .MMI_PS2, {}} },

    // Top-level parallel shifts by immediate (SPECIAL2 funct 0x34/36/37/3C/3E/3F).
    .PSLLH = { {.PSLLH, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x70000034, 0xFFE0003F, .MMI_PS2, {}} },
    .PSRLH = { {.PSRLH, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x70000036, 0xFFE0003F, .MMI_PS2, {}} },
    .PSRAH = { {.PSRAH, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x70000037, 0xFFE0003F, .MMI_PS2, {}} },
    .PSLLW = { {.PSLLW, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7000003C, 0xFFE0003F, .MMI_PS2, {}} },
    .PSRLW = { {.PSRLW, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7000003E, 0xFFE0003F, .MMI_PS2, {}} },
    .PSRAW = { {.PSRAW, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7000003F, 0xFFE0003F, .MMI_PS2, {}} },

    // ---- MMI0 sub-space (funct=0x08, shamt selects) --------------------------
    // bits = 0x70000008 | (shamt<<6); mask = OPCODE | SHAMT | FUNCT = 0xFC0007FF.
    .PADDW  = { {.PADDW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000008, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBW  = { {.PSUBW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000048, 0xFC0007FF, .MMI_PS2, {}} },
    .PCGTW  = { {.PCGTW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000088, 0xFC0007FF, .MMI_PS2, {}} },
    .PMAXW  = { {.PMAXW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700000C8, 0xFC0007FF, .MMI_PS2, {}} },
    .PADDH  = { {.PADDH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000108, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBH  = { {.PSUBH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000148, 0xFC0007FF, .MMI_PS2, {}} },
    .PCGTH  = { {.PCGTH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000188, 0xFC0007FF, .MMI_PS2, {}} },
    .PMAXH  = { {.PMAXH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700001C8, 0xFC0007FF, .MMI_PS2, {}} },
    .PADDB  = { {.PADDB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000208, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBB  = { {.PSUBB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000248, 0xFC0007FF, .MMI_PS2, {}} },
    .PCGTB  = { {.PCGTB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000288, 0xFC0007FF, .MMI_PS2, {}} },
    .PADDSW = { {.PADDSW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000408, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBSW = { {.PSUBSW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000448, 0xFC0007FF, .MMI_PS2, {}} },
    .PEXTLW = { {.PEXTLW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000488, 0xFC0007FF, .MMI_PS2, {}} },
    .PPACW  = { {.PPACW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700004C8, 0xFC0007FF, .MMI_PS2, {}} },
    .PADDSH = { {.PADDSH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000508, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBSH = { {.PSUBSH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000548, 0xFC0007FF, .MMI_PS2, {}} },
    .PEXTLH = { {.PEXTLH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000588, 0xFC0007FF, .MMI_PS2, {}} },
    .PPACH  = { {.PPACH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700005C8, 0xFC0007FF, .MMI_PS2, {}} },
    .PADDSB = { {.PADDSB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000608, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBSB = { {.PSUBSB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000648, 0xFC0007FF, .MMI_PS2, {}} },
    .PEXTLB = { {.PEXTLB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000688, 0xFC0007FF, .MMI_PS2, {}} },
    .PPACB  = { {.PPACB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700006C8, 0xFC0007FF, .MMI_PS2, {}} },
    .PEXT5  = { {.PEXT5,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000788, 0xFC0007FF, .MMI_PS2, {}} },
    .PPAC5  = { {.PPAC5,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700007C8, 0xFC0007FF, .MMI_PS2, {}} },

    // ---- MMI1 sub-space (funct=0x28, shamt selects) --------------------------
    .PABSW  = { {.PABSW,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x70000068, 0xFC1F07FF, .MMI_PS2, {}} },
    .PCEQW  = { {.PCEQW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700000A8, 0xFC0007FF, .MMI_PS2, {}} },
    .PMINW  = { {.PMINW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700000E8, 0xFC0007FF, .MMI_PS2, {}} },
    .PABSH  = { {.PABSH,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x70000168, 0xFC1F07FF, .MMI_PS2, {}} },
    .PCEQH  = { {.PCEQH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700001A8, 0xFC0007FF, .MMI_PS2, {}} },
    .PMINH  = { {.PMINH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700001E8, 0xFC0007FF, .MMI_PS2, {}} },
    .PCEQB  = { {.PCEQB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700002A8, 0xFC0007FF, .MMI_PS2, {}} },
    .PADDUW = { {.PADDUW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x70000428, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBUW = { {.PSUBUW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x70000468, 0xFC0007FF, .MMI_PS2, {}} },
    .PEXTUW = { {.PEXTUW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700004A8, 0xFC0007FF, .MMI_PS2, {}} },
    .PADDUH = { {.PADDUH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x70000528, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBUH = { {.PSUBUH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x70000568, 0xFC0007FF, .MMI_PS2, {}} },
    .PEXTUH = { {.PEXTUH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700005A8, 0xFC0007FF, .MMI_PS2, {}} },
    .PADDUB = { {.PADDUB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x70000628, 0xFC0007FF, .MMI_PS2, {}} },
    .PSUBUB = { {.PSUBUB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x70000668, 0xFC0007FF, .MMI_PS2, {}} },
    .PEXTUB = { {.PEXTUB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700006A8, 0xFC0007FF, .MMI_PS2, {}} },
    .QFSRV  = { {.QFSRV,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE},  0x700006E8, 0xFC0007FF, .MMI_PS2, {}} },

    // ---- MMI2 sub-space (funct=0x09, shamt selects) --------------------------
    .PMADDW = { {.PMADDW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000009, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PSLLVW = { {.PSLLVW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x70000089, 0xFC0007FF, .MMI_PS2, {}} },
    .PSRLVW = { {.PSRLVW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x700000C9, 0xFC0007FF, .MMI_PS2, {}} },
    .PMSUBW = { {.PMSUBW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000109, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PMFHI  = { {.PMFHI,  {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x70000209, 0xFFFF07FF, .MMI_PS2, {}} },
    .PMFLO  = { {.PMFLO,  {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x70000249, 0xFFFF07FF, .MMI_PS2, {}} },
    .PINTH  = { {.PINTH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000289, 0xFC0007FF, .MMI_PS2, {}} },
    .PMULTW = { {.PMULTW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000309, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PDIVW  = { {.PDIVW,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x70000349, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },
    .PCPYLD = { {.PCPYLD, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000389, 0xFC0007FF, .MMI_PS2, {}} },
    .PMADDH = { {.PMADDH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000409, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PHMADH = { {.PHMADH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000449, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PAND   = { {.PAND,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000489, 0xFC0007FF, .MMI_PS2, {}} },
    .PXOR   = { {.PXOR,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700004C9, 0xFC0007FF, .MMI_PS2, {}} },
    .PMSUBH = { {.PMSUBH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000509, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PHMSBH = { {.PHMSBH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000549, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PEXEH  = { {.PEXEH,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x70000689, 0xFC1F07FF, .MMI_PS2, {}} },
    .PMULTH = { {.PMULTH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000709, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PDIVBW = { {.PDIVBW, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x70000749, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },
    .PEXEW  = { {.PEXEW,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x70000789, 0xFC1F07FF, .MMI_PS2, {}} },
    .PROT3W = { {.PROT3W, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x700007C9, 0xFC1F07FF, .MMI_PS2, {}} },

    // ---- MMI3 sub-space (funct=0x29, shamt selects) --------------------------
    .PMADDUW = { {.PMADDUW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000029, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PSRAVW  = { {.PSRAVW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x700000E9, 0xFC0007FF, .MMI_PS2, {}} },
    .PMTHI   = { {.PMTHI,   {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x70000229, 0xFC1FFFFF, .MMI_PS2, {}} },
    .PMTLO   = { {.PMTLO,   {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x70000269, 0xFC1FFFFF, .MMI_PS2, {}} },
    .PINTOH  = { {.PINTOH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700002A9, 0xFC0007FF, .MMI_PS2, {}} },
    .PMULTUW = { {.PMULTUW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000329, 0xFC0007FF, .MMI_PS2, {writes_hilo=true}} },
    .PDIVUW  = { {.PDIVUW,  {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x70000369, 0xFC00FFFF, .MMI_PS2, {writes_hilo=true}} },
    .PCPYUD  = { {.PCPYUD,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700003A9, 0xFC0007FF, .MMI_PS2, {}} },
    .POR     = { {.POR,     {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x70000489 | 0x80, 0xFC0007FF, .MMI_PS2, {}} },
    .PNOR    = { {.PNOR,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x700004C9 | 0x80, 0xFC0007FF, .MMI_PS2, {}} },
    .PEXCH   = { {.PEXCH,   {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x70000689 | 0x80, 0xFC1F07FF, .MMI_PS2, {}} },
    .PCPYH   = { {.PCPYH,   {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x700006C9, 0xFC1F07FF, .MMI_PS2, {}} },
    .PEXCW   = { {.PEXCW,   {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x70000789 | 0x80, 0xFC1F07FF, .MMI_PS2, {}} },

    // Shift-amount register moves (R5900 SHFL helpers, SPECIAL funct 0x28/0x29).
    .MFSA = { {.MFSA, {.GPR,.NONE,.NONE,.NONE}, {.RD,.NONE,.NONE,.NONE}, 0x00000028, 0xFFFF07FF, .MMI_PS2, {}} },
    .MTSA = { {.MTSA, {.GPR,.NONE,.NONE,.NONE}, {.RS,.NONE,.NONE,.NONE}, 0x00000029, 0xFC1FFFFF, .MMI_PS2, {}} },
    .MTSAB = { {.MTSAB, {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x04180000, 0xFC1F0000, .MMI_PS2, {}} },
    .MTSAH = { {.MTSAH, {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x04190000, 0xFC1F0000, .MMI_PS2, {}} },

    // =========================================================================
    // §6 MIPS32 R6 — compact branches, new mul/div, R6-specific ops
    // =========================================================================
    //
    // R6 redesigns several pre-R6 encodings; the entries below cover the
    // genuinely new ones. Conflicting opcodes (BC at 0x32 vs LWC2;
    // BALC at 0x3A vs SWC2; JIC at 0x36 vs LDC2; JIALC at 0x3E vs SDC2;
    // AUI at 0x0F overlaps LUI's slot) must be disambiguated by target
    // Feature -- both forms live in the table, consumer picks.

    // Unconditional compact (26-bit PC-relative, no delay slot).
    .BC   = { {.BC,   {.REL26,.NONE,.NONE,.NONE}, {.IMM_26,.NONE,.NONE,.NONE}, 0xC8000000, 0xFC000000, .MIPS32_R6, {compact=true}} },
    .BALC = { {.BALC, {.REL26,.NONE,.NONE,.NONE}, {.IMM_26,.NONE,.NONE,.NONE}, 0xE8000000, 0xFC000000, .MIPS32_R6, {compact=true}} },

    // JIC/JIALC: indirect jump with explicit GPR target + 16-bit offset.
    // (rs=0; if rs!=0 the encoding becomes BEQZC/BNEZC.)
    .JIC   = { {.JIC,   {.GPR,.IMM16S,.NONE,.NONE}, {.RT,.IMM_16,.NONE,.NONE}, 0xD8000000, 0xFFE00000, .MIPS32_R6, {compact=true}} },
    .JIALC = { {.JIALC, {.GPR,.IMM16S,.NONE,.NONE}, {.RT,.IMM_16,.NONE,.NONE}, 0xF8000000, 0xFFE00000, .MIPS32_R6, {compact=true}} },

    // BEQZC/BNEZC: 21-bit PC-relative compact branch on rs == 0 / != 0.
    // Share opcodes 0x36/0x3E with JIC/JIALC; here rs is operand and
    // mask leaves rs as operand-driven (decoder disambiguates by rs != 0).
    .BEQZC = { {.BEQZC, {.GPR,.REL21,.NONE,.NONE}, {.RS,.BRANCH_21,.NONE,.NONE}, 0xD8000000, 0xFC000000, .MIPS32_R6, {compact=true}} },
    .BNEZC = { {.BNEZC, {.GPR,.REL21,.NONE,.NONE}, {.RS,.BRANCH_21,.NONE,.NONE}, 0xF8000000, 0xFC000000, .MIPS32_R6, {compact=true}} },

    // AUI / DAUI / AUIPC / ALUIPC / DAHI / DATI.
    // AUI takes the LUI slot (opcode 0x0F) but is a 3-operand "add upper
    // immediate" (rs may be != 0). When rs==0 the assembler typically
    // prints it as LUI; the bits are identical, semantics decided by R6
    // vs pre-R6 dispatch.
    .AUI   = { {.AUI,   {.GPR,.GPR,.IMM16U,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x3C000000, 0xFC000000, .MIPS32_R6, {}} },
    .DAUI  = { {.DAUI,  {.GPR,.GPR,.IMM16U,.NONE}, {.RT,.RS,.IMM_16,.NONE}, 0x74000000, 0xFC000000, .MIPS64_R6, {only_64=true}} },
    // AUIPC/ALUIPC live in PCREL sub-space (op=0x3B / REGIMM-like rt selector).
    // PCREL: rt=0x1E = AUIPC, rt=0x1F = ALUIPC.  (op=0x3B selector varies.)
    .AUIPC  = { {.AUIPC,  {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0xEC1E0000, 0xFC1F0000, .MIPS32_R6, {}} },
    .ALUIPC = { {.ALUIPC, {.GPR,.IMM16S,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0xEC1F0000, 0xFC1F0000, .MIPS32_R6, {}} },
    .DAHI   = { {.DAHI,   {.GPR,.IMM16U,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x04060000, 0xFC1F0000, .MIPS64_R6, {only_64=true}} },
    .DATI   = { {.DATI,   {.GPR,.IMM16U,.NONE,.NONE}, {.RS,.IMM_16,.NONE,.NONE}, 0x041E0000, 0xFC1F0000, .MIPS64_R6, {only_64=true}} },

    // R6 mul/div: reuse SPECIAL functs 0x18-0x1F (which were MULT/MULTU/
    // DIV/DIVU in pre-R6) with shamt distinguishing low half (0x02) from
    // high half (0x03). Results land in rd, not HI/LO.
    .MUH   = { {.MUH,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x000000D8, 0xFC0007FF, .MIPS32_R6, {}} },
    .MULU  = { {.MULU,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000099, 0xFC0007FF, .MIPS32_R6, {}} },
    .MUHU  = { {.MUHU,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x000000D9, 0xFC0007FF, .MIPS32_R6, {}} },
    .MOD   = { {.MOD,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x000000DA, 0xFC0007FF, .MIPS32_R6, {}} },
    .MODU  = { {.MODU,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x000000DB, 0xFC0007FF, .MIPS32_R6, {}} },
    // 64-bit R6 mul/div (functs 0x1C-0x1F).
    .DMUL_R6   = { {.DMUL_R6,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000009C, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },
    .DMUH      = { {.DMUH,      {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x000000DC, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },
    .DMULU     = { {.DMULU,     {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000009D, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },
    .DMUHU     = { {.DMUHU,     {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x000000DD, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },
    .DDIV_R6   = { {.DDIV_R6,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000009E, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },
    .DMOD      = { {.DMOD,      {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x000000DE, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },
    .DDIVU_R6  = { {.DDIVU_R6,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x0000009F, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },
    .DMODU     = { {.DMODU,     {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x000000DF, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },

    // LSA / DLSA (load shifted add): SPECIAL funct=0x05/0x15 with sa=imm2.
    // Layout: [op=0][rs][rt][rd][000][sa:2][funct]. sa-1 stored.
    .LSA   = { {.LSA,   {.GPR,.GPR,.GPR,.IMM5}, {.RD,.RS,.RT,.IMM_5}, 0x00000005, 0xFC00071F, .MIPS32_R6, {}} },
    .DLSA  = { {.DLSA,  {.GPR,.GPR,.GPR,.IMM5}, {.RD,.RS,.RT,.IMM_5}, 0x00000015, 0xFC00071F, .MIPS64_R6, {only_64=true}} },

    // SELEQZ / SELNEZ (predicated select).
    .SELEQZ = { {.SELEQZ, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000035, 0xFC0007FF, .MIPS32_R6, {}} },
    .SELNEZ = { {.SELNEZ, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x00000037, 0xFC0007FF, .MIPS32_R6, {}} },

    // BITSWAP / DBITSWAP: SPECIAL3 BSHFL/DBSHFL with shamt selecting.
    .BITSWAP  = { {.BITSWAP,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000020, 0xFFE007FF, .MIPS32_R6, {}} },
    .DBITSWAP = { {.DBITSWAP, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000024, 0xFFE007FF, .MIPS64_R6, {only_64=true}} },

    // ALIGN / DALIGN: SPECIAL3 BSHFL/DBSHFL with shamt = 0b010xx (ALIGN) or
    // 0b010xxx (DALIGN). bp encoded in low bits of shamt.  Mask fixes the
    // high-bits-of-shamt portion that marks "ALIGN op" but leaves bp variable.
    .ALIGN  = { {.ALIGN,  {.GPR,.GPR,.GPR,.IMM5}, {.RD,.RS,.RT,.IMM_5}, 0x7C000220, 0xFC0007FF, .MIPS32_R6, {}} },
    .DALIGN = { {.DALIGN, {.GPR,.GPR,.GPR,.IMM5}, {.RD,.RS,.RT,.IMM_5}, 0x7C000224, 0xFC0007FF, .MIPS64_R6, {only_64=true}} },

    // BC1EQZ / BC1NEZ: COP1 with rs=0x09/0x0D, 16-bit offset, ft as test reg.
    .BC1EQZ = { {.BC1EQZ, {.FPR_S,.REL16,.NONE,.NONE}, {.FT,.BRANCH_16,.NONE,.NONE}, 0x45200000, 0xFFE00000, .MIPS32_R6, {compact=true}} },
    .BC1NEZ = { {.BC1NEZ, {.FPR_S,.REL16,.NONE,.NONE}, {.FT,.BRANCH_16,.NONE,.NONE}, 0x45A00000, 0xFFE00000, .MIPS32_R6, {compact=true}} },
    .BC2EQZ = { {.BC2EQZ, {.CP2_REG,.REL16,.NONE,.NONE}, {.FT,.BRANCH_16,.NONE,.NONE}, 0x49200000, 0xFFE00000, .MIPS32_R6, {compact=true}} },
    .BC2NEZ = { {.BC2NEZ, {.CP2_REG,.REL16,.NONE,.NONE}, {.FT,.BRANCH_16,.NONE,.NONE}, 0x49A00000, 0xFFE00000, .MIPS32_R6, {compact=true}} },

    // CRC32 family: SPECIAL3 funct=0x0F, sz/c sub-fields in bits 10-6.
    // Layout: [op=0x1F][rs(data)][rt(crc)][0:5][sz:3][c:2][funct=0x0F]
    //   sz=0 byte, 1 halfword, 2 word, 3 doubleword;  c=0 CRC32, c=1 CRC32C.
    .CRC32B  = { {.CRC32B,  {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00000F, 0xFC00F8FF, .MIPS32_R6, {}} },
    .CRC32H  = { {.CRC32H,  {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00004F, 0xFC00F8FF, .MIPS32_R6, {}} },
    .CRC32W  = { {.CRC32W,  {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00020F, 0xFC00F8FF, .MIPS32_R6, {}} },
    .CRC32D  = { {.CRC32D,  {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00030F, 0xFC00F8FF, .MIPS64_R6, {only_64=true}} },
    .CRC32CB = { {.CRC32CB, {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00010F, 0xFC00F8FF, .MIPS32_R6, {}} },
    .CRC32CH = { {.CRC32CH, {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00014F, 0xFC00F8FF, .MIPS32_R6, {}} },
    .CRC32CW = { {.CRC32CW, {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00024F, 0xFC00F8FF, .MIPS32_R6, {}} },
    .CRC32CD = { {.CRC32CD, {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00034F, 0xFC00F8FF, .MIPS64_R6, {only_64=true}} },

    // SIGRIE: signal reserved-instruction exception (R6 reserved encoding).
    .SIGRIE = { {.SIGRIE, {.IMM16U,.NONE,.NONE,.NONE}, {.IMM_16,.NONE,.NONE,.NONE}, 0x04170000, 0xFFFF0000, .MIPS32_R6, {}} },

    // =========================================================================
    // §11 MIPS DSP ASE (rev 1 + rev 2) — focused subset
    // =========================================================================
    //
    // DSP lives in SPECIAL3 (op=0x1F) with funct + shamt sub-spaces. Below
    // is the most-used core (saturating add/sub, dot-product-accumulate,
    // extract-from-accumulator, indexed loads, BPOSGE32, BITREV, INSV).
    // Many ops use accumulators ac0-ac3 encoded in the rd slot (low 2 bits);
    // the user passes the accumulator number as an immediate in the rd
    // operand position. Full DSP coverage is a follow-up.

    // ADDU.QB sub-space (funct=0x10, shamt selects)
    .ADDU_QB    = { {.ADDU_QB,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000010, 0xFC0007FF, .DSP_R1, {}} },
    .SUBU_QB    = { {.SUBU_QB,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000050, 0xFC0007FF, .DSP_R1, {}} },
    .ADDU_S_QB  = { {.ADDU_S_QB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000110, 0xFC0007FF, .DSP_R1, {}} },
    .SUBU_S_QB  = { {.SUBU_S_QB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000150, 0xFC0007FF, .DSP_R1, {}} },
    .ADDQ_PH    = { {.ADDQ_PH,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000290, 0xFC0007FF, .DSP_R1, {}} },
    .SUBQ_PH    = { {.SUBQ_PH,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0002D0, 0xFC0007FF, .DSP_R1, {}} },
    .ADDQ_S_PH  = { {.ADDQ_S_PH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000390, 0xFC0007FF, .DSP_R1, {}} },
    .SUBQ_S_PH  = { {.SUBQ_S_PH,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0003D0, 0xFC0007FF, .DSP_R1, {}} },
    .ADDQ_S_W   = { {.ADDQ_S_W,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000590, 0xFC0007FF, .DSP_R1, {}} },
    .SUBQ_S_W   = { {.SUBQ_S_W,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0005D0, 0xFC0007FF, .DSP_R1, {}} },
    .ADDSC      = { {.ADDSC,      {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000410, 0xFC0007FF, .DSP_R1, {}} },
    .ADDWC      = { {.ADDWC,      {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000450, 0xFC0007FF, .DSP_R1, {}} },

    // ABSQ_S.PH sub-space (funct=0x12, shamt selects). Unary RD <- RT.
    .ABSQ_S_PH      = { {.ABSQ_S_PH,      {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000252, 0xFFE007FF, .DSP_R1, {}} },
    .ABSQ_S_W       = { {.ABSQ_S_W,       {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000452, 0xFFE007FF, .DSP_R1, {}} },
    .PRECEQ_W_PHL   = { {.PRECEQ_W_PHL,   {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000312, 0xFFE007FF, .DSP_R1, {}} },
    .PRECEQ_W_PHR   = { {.PRECEQ_W_PHR,   {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000352, 0xFFE007FF, .DSP_R1, {}} },
    .PRECEQU_PH_QBL = { {.PRECEQU_PH_QBL, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000112, 0xFFE007FF, .DSP_R1, {}} },
    .PRECEQU_PH_QBR = { {.PRECEQU_PH_QBR, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000152, 0xFFE007FF, .DSP_R1, {}} },
    .PRECEU_PH_QBL  = { {.PRECEU_PH_QBL,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000712, 0xFFE007FF, .DSP_R1, {}} },
    .PRECEU_PH_QBR  = { {.PRECEU_PH_QBR,  {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000752, 0xFFE007FF, .DSP_R1, {}} },
    .BITREV         = { {.BITREV,         {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C0006D2, 0xFFE007FF, .DSP_R2, {}} },

    // SHLL.QB sub-space (funct=0x13, shamt selects).
    .SHLL_QB   = { {.SHLL_QB,   {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7C000013, 0xFFE0073F, .DSP_R1, {}} },
    .SHRL_QB   = { {.SHRL_QB,   {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7C000053, 0xFFE0073F, .DSP_R1, {}} },
    .SHLLV_QB  = { {.SHLLV_QB,  {.GPR,.GPR,.GPR,.NONE},  {.RD,.RT,.RS,.NONE},    0x7C000093, 0xFC0007FF, .DSP_R1, {}} },
    .SHRLV_QB  = { {.SHRLV_QB,  {.GPR,.GPR,.GPR,.NONE},  {.RD,.RT,.RS,.NONE},    0x7C0000D3, 0xFC0007FF, .DSP_R1, {}} },
    .SHLL_PH   = { {.SHLL_PH,   {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7C000213, 0xFFE0073F, .DSP_R1, {}} },
    .SHRA_PH   = { {.SHRA_PH,   {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7C000253, 0xFFE0073F, .DSP_R1, {}} },
    .SHLL_S_PH = { {.SHLL_S_PH, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7C000313, 0xFFE0073F, .DSP_R1, {}} },
    .SHLL_S_W  = { {.SHLL_S_W,  {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7C000513, 0xFFE0073F, .DSP_R1, {}} },
    .SHRA_R_W  = { {.SHRA_R_W,  {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.IMM_5,.NONE}, 0x7C000553, 0xFFE0073F, .DSP_R1, {}} },

    // Dot-product accumulate sub-space (funct=0x30/0x32). Take ac in rd (2-bit).
    .DPAU_H_QBL = { {.DPAU_H_QBL, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0000F0, 0xFC0007FF, .DSP_R1, {}} },
    .DPAU_H_QBR = { {.DPAU_H_QBR, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0001F0, 0xFC0007FF, .DSP_R1, {}} },
    .DPSU_H_QBL = { {.DPSU_H_QBL, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0002F0, 0xFC0007FF, .DSP_R1, {}} },
    .DPSU_H_QBR = { {.DPSU_H_QBR, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0003F0, 0xFC0007FF, .DSP_R1, {}} },
    .DPAQ_S_W_PH = { {.DPAQ_S_W_PH, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000130, 0xFC0007FF, .DSP_R1, {}} },
    .DPSQ_S_W_PH = { {.DPSQ_S_W_PH, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000170, 0xFC0007FF, .DSP_R1, {}} },
    .MULSAQ_S_W_PH = { {.MULSAQ_S_W_PH, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0001B0, 0xFC0007FF, .DSP_R1, {}} },
    .DPAQ_SA_L_W = { {.DPAQ_SA_L_W, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000330, 0xFC0007FF, .DSP_R1, {}} },
    .DPSQ_SA_L_W = { {.DPSQ_SA_L_W, {.IMM5,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000370, 0xFC0007FF, .DSP_R1, {}} },

    // Extract-from-accumulator sub-space (funct=0x38, shamt selects).
    .EXTR_W    = { {.EXTR_W,    {.GPR,.IMM5,.IMM5,.NONE}, {.RT,.RS,.RD,.NONE}, 0x7C000038, 0xFC00073F, .DSP_R1, {}} },
    .EXTRV_W   = { {.EXTRV_W,   {.GPR,.IMM5,.GPR,.NONE},  {.RT,.RD,.RS,.NONE}, 0x7C000078, 0xFC0007FF, .DSP_R1, {}} },
    .EXTR_R_W  = { {.EXTR_R_W,  {.GPR,.IMM5,.IMM5,.NONE}, {.RT,.RS,.RD,.NONE}, 0x7C000138, 0xFC00073F, .DSP_R1, {}} },
    .EXTR_RS_W = { {.EXTR_RS_W, {.GPR,.IMM5,.IMM5,.NONE}, {.RT,.RS,.RD,.NONE}, 0x7C0001B8, 0xFC00073F, .DSP_R1, {}} },
    .EXTR_S_H  = { {.EXTR_S_H,  {.GPR,.IMM5,.IMM5,.NONE}, {.RT,.RS,.RD,.NONE}, 0x7C0003B8, 0xFC00073F, .DSP_R1, {}} },
    .EXTP      = { {.EXTP,      {.GPR,.IMM5,.IMM5,.NONE}, {.RT,.RS,.RD,.NONE}, 0x7C0000B8, 0xFC00073F, .DSP_R1, {}} },
    .EXTPV     = { {.EXTPV,     {.GPR,.IMM5,.GPR,.NONE},  {.RT,.RD,.RS,.NONE}, 0x7C0000F8, 0xFC0007FF, .DSP_R1, {}} },
    .RDDSP     = { {.RDDSP,     {.GPR,.IMM5,.NONE,.NONE}, {.RD,.RS,.NONE,.NONE}, 0x7C0004B8, 0xFC1F07FF, .DSP_R1, {}} },
    .WRDSP     = { {.WRDSP,     {.GPR,.IMM5,.NONE,.NONE}, {.RS,.RD,.NONE,.NONE}, 0x7C0004F8, 0xFC00FFFF, .DSP_R1, {}} },

    // Indexed loads (SPECIAL3 funct=0x0A).
    .LWX  = { {.LWX,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C00000A, 0xFC0007FF, .DSP_R1, {}} },
    .LHX  = { {.LHX,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C00010A, 0xFC0007FF, .DSP_R1, {}} },
    .LBUX = { {.LBUX, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C00018A, 0xFC0007FF, .DSP_R1, {}} },

    // Insert variable (SPECIAL3 funct=0x0C).
    .INSV = { {.INSV, {.GPR,.GPR,.NONE,.NONE}, {.RT,.RS,.NONE,.NONE}, 0x7C00000C, 0xFC00FFFF, .DSP_R1, {}} },

    // REGIMM branch on DSPControl.pos >= 32.
    .BPOSGE32 = { {.BPOSGE32, {.REL16,.NONE,.NONE,.NONE}, {.BRANCH_16,.NONE,.NONE,.NONE}, 0x041C0000, 0xFFFF0000, .DSP_R1, {delay_slot=true}} },

    // =========================================================================
    // §12 MSA (MIPS SIMD Architecture)
    // =========================================================================
    //
    // 3R-format layout:
    //   bits 31:26 = 0x1E (primary)
    //   bits 25:23 = group   (3 bits, picks a sub-table of 64 ops)
    //   bits 22:21 = df      (00=B, 01=H, 10=W, 11=D)
    //   bits 20:16 = wt      operand
    //   bits 15:11 = ws      operand
    //   bits 10:6  = wd      operand
    //   bits  5:0  = minor   (6 bits, picks op within group)
    //
    // Static mask covers primary+group+df+minor = 0xFFE0003F. With df=00
    // the bits include only the group+minor; df=01 sets bit 21, etc.
    //
    // NOTE: opcode 0x1E conflicts with PS2 LQ (R5900). Consumers select by
    // target Feature flag; both forms can coexist in the dispatch table because
    // the mask of LQ (which is an I-type with no funct field) differs from
    // any MSA 3R-format mask.

    // ---- Group 000: ADDV / SUBV (3R minor 0x0E / 0x0F) ----------------------
    .ADDV_B = { {.ADDV_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7800000E, 0xFFE0003F, .MSA, {}} },
    .ADDV_H = { {.ADDV_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7820000E, 0xFFE0003F, .MSA, {}} },
    .ADDV_W = { {.ADDV_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7840000E, 0xFFE0003F, .MSA, {}} },
    .ADDV_D = { {.ADDV_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7860000E, 0xFFE0003F, .MSA, {}} },
    .SUBV_B = { {.SUBV_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7880000E, 0xFFE0003F, .MSA, {}} },
    .SUBV_H = { {.SUBV_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78A0000E, 0xFFE0003F, .MSA, {}} },
    .SUBV_W = { {.SUBV_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78C0000E, 0xFFE0003F, .MSA, {}} },
    .SUBV_D = { {.SUBV_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78E0000E, 0xFFE0003F, .MSA, {}} },

    // ---- Group 000: signed/unsigned saturated add/sub (3R minor 0x10..0x13) -
    .ADDS_S_B = { {.ADDS_S_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79000010, 0xFFE0003F, .MSA, {}} },
    .ADDS_S_H = { {.ADDS_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79200010, 0xFFE0003F, .MSA, {}} },
    .ADDS_S_W = { {.ADDS_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79400010, 0xFFE0003F, .MSA, {}} },
    .ADDS_S_D = { {.ADDS_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79600010, 0xFFE0003F, .MSA, {}} },
    .ADDS_U_B = { {.ADDS_U_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79800010, 0xFFE0003F, .MSA, {}} },
    .ADDS_U_H = { {.ADDS_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79A00010, 0xFFE0003F, .MSA, {}} },
    .ADDS_U_W = { {.ADDS_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79C00010, 0xFFE0003F, .MSA, {}} },
    .ADDS_U_D = { {.ADDS_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79E00010, 0xFFE0003F, .MSA, {}} },
    .SUBS_S_B = { {.SUBS_S_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78000011, 0xFFE0003F, .MSA, {}} },
    .SUBS_S_H = { {.SUBS_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78200011, 0xFFE0003F, .MSA, {}} },
    .SUBS_S_W = { {.SUBS_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78400011, 0xFFE0003F, .MSA, {}} },
    .SUBS_S_D = { {.SUBS_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78600011, 0xFFE0003F, .MSA, {}} },
    .SUBS_U_B = { {.SUBS_U_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78800011, 0xFFE0003F, .MSA, {}} },
    .SUBS_U_H = { {.SUBS_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78A00011, 0xFFE0003F, .MSA, {}} },
    .SUBS_U_W = { {.SUBS_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78C00011, 0xFFE0003F, .MSA, {}} },
    .SUBS_U_D = { {.SUBS_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78E00011, 0xFFE0003F, .MSA, {}} },

    // ---- Group 001: MULV / MADDV / MSUBV / DIV / MOD (3R minor 0x12..0x16) --
    .MULV_B  = { {.MULV_B,  {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78000012, 0xFFE0003F, .MSA, {}} },
    .MULV_H  = { {.MULV_H,  {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78200012, 0xFFE0003F, .MSA, {}} },
    .MULV_W  = { {.MULV_W,  {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78400012, 0xFFE0003F, .MSA, {}} },
    .MULV_D  = { {.MULV_D,  {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78600012, 0xFFE0003F, .MSA, {}} },
    .MADDV_B = { {.MADDV_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78800012, 0xFFE0003F, .MSA, {}} },
    .MADDV_H = { {.MADDV_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78A00012, 0xFFE0003F, .MSA, {}} },
    .MADDV_W = { {.MADDV_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78C00012, 0xFFE0003F, .MSA, {}} },
    .MADDV_D = { {.MADDV_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78E00012, 0xFFE0003F, .MSA, {}} },
    .MSUBV_B = { {.MSUBV_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79000012, 0xFFE0003F, .MSA, {}} },
    .MSUBV_H = { {.MSUBV_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79200012, 0xFFE0003F, .MSA, {}} },
    .MSUBV_W = { {.MSUBV_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79400012, 0xFFE0003F, .MSA, {}} },
    .MSUBV_D = { {.MSUBV_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79600012, 0xFFE0003F, .MSA, {}} },
    .DIV_S_B = { {.DIV_S_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A000012, 0xFFE0003F, .MSA, {}} },
    .DIV_S_H = { {.DIV_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A200012, 0xFFE0003F, .MSA, {}} },
    .DIV_S_W = { {.DIV_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A400012, 0xFFE0003F, .MSA, {}} },
    .DIV_S_D = { {.DIV_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A600012, 0xFFE0003F, .MSA, {}} },
    .DIV_U_B = { {.DIV_U_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A800012, 0xFFE0003F, .MSA, {}} },
    .DIV_U_H = { {.DIV_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AA00012, 0xFFE0003F, .MSA, {}} },
    .DIV_U_W = { {.DIV_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AC00012, 0xFFE0003F, .MSA, {}} },
    .DIV_U_D = { {.DIV_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AE00012, 0xFFE0003F, .MSA, {}} },
    .MOD_S_B = { {.MOD_S_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7B000012, 0xFFE0003F, .MSA, {}} },
    .MOD_S_H = { {.MOD_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7B200012, 0xFFE0003F, .MSA, {}} },
    .MOD_S_W = { {.MOD_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7B400012, 0xFFE0003F, .MSA, {}} },
    .MOD_S_D = { {.MOD_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7B600012, 0xFFE0003F, .MSA, {}} },
    .MOD_U_B = { {.MOD_U_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7B800012, 0xFFE0003F, .MSA, {}} },
    .MOD_U_H = { {.MOD_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7BA00012, 0xFFE0003F, .MSA, {}} },
    .MOD_U_W = { {.MOD_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7BC00012, 0xFFE0003F, .MSA, {}} },
    .MOD_U_D = { {.MOD_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7BE00012, 0xFFE0003F, .MSA, {}} },

    // ---- Vector logical (VEC-format, df implicit -- always byte-wise) -------
    //   AND.V/OR.V/NOR.V/XOR.V live at minor 0x1E with group bits selecting op:
    //   AND.V = 0x78000020 -- wait actually different format. VEC-form uses
    //   bits 25:21 = 11110/11111 etc. For simplicity we encode them as 3R-shape.
    //   AND.V = 0x7800001E, OR.V = 0x7820001E, NOR.V = 0x7840001E, XOR.V = 0x7860001E
    .AND_V = { {.AND_V, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7800001E, 0xFFE0003F, .MSA, {}} },
    .OR_V  = { {.OR_V,  {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7820001E, 0xFFE0003F, .MSA, {}} },
    .NOR_V = { {.NOR_V, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7840001E, 0xFFE0003F, .MSA, {}} },
    .XOR_V = { {.XOR_V, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7860001E, 0xFFE0003F, .MSA, {}} },

    // ---- Vector compare (3R minor 0x0F for CEQ; 0x07..0x0A for LT/LE) ------
    .CEQ_B   = { {.CEQ_B,   {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7800000F, 0xFFE0003F, .MSA, {}} },
    .CEQ_H   = { {.CEQ_H,   {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7820000F, 0xFFE0003F, .MSA, {}} },
    .CEQ_W   = { {.CEQ_W,   {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7840000F, 0xFFE0003F, .MSA, {}} },
    .CEQ_D   = { {.CEQ_D,   {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7860000F, 0xFFE0003F, .MSA, {}} },
    .CLT_S_B = { {.CLT_S_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7900000F, 0xFFE0003F, .MSA, {}} },
    .CLT_S_H = { {.CLT_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7920000F, 0xFFE0003F, .MSA, {}} },
    .CLT_S_W = { {.CLT_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7940000F, 0xFFE0003F, .MSA, {}} },
    .CLT_S_D = { {.CLT_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7960000F, 0xFFE0003F, .MSA, {}} },
    .CLT_U_B = { {.CLT_U_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7980000F, 0xFFE0003F, .MSA, {}} },
    .CLT_U_H = { {.CLT_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79A0000F, 0xFFE0003F, .MSA, {}} },
    .CLT_U_W = { {.CLT_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79C0000F, 0xFFE0003F, .MSA, {}} },
    .CLT_U_D = { {.CLT_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79E0000F, 0xFFE0003F, .MSA, {}} },
    .CLE_S_B = { {.CLE_S_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A00000F, 0xFFE0003F, .MSA, {}} },
    .CLE_S_H = { {.CLE_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A20000F, 0xFFE0003F, .MSA, {}} },
    .CLE_S_W = { {.CLE_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A40000F, 0xFFE0003F, .MSA, {}} },
    .CLE_S_D = { {.CLE_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A60000F, 0xFFE0003F, .MSA, {}} },
    .CLE_U_B = { {.CLE_U_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A80000F, 0xFFE0003F, .MSA, {}} },
    .CLE_U_H = { {.CLE_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AA0000F, 0xFFE0003F, .MSA, {}} },
    .CLE_U_W = { {.CLE_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AC0000F, 0xFFE0003F, .MSA, {}} },
    .CLE_U_D = { {.CLE_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AE0000F, 0xFFE0003F, .MSA, {}} },

    // ---- Vector min/max (3R minor 0x0E with high opcode group bits 010) ----
    .MIN_S_B = { {.MIN_S_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A00000E, 0xFFE0003F, .MSA, {}} },
    .MIN_S_H = { {.MIN_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A20000E, 0xFFE0003F, .MSA, {}} },
    .MIN_S_W = { {.MIN_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A40000E, 0xFFE0003F, .MSA, {}} },
    .MIN_S_D = { {.MIN_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A60000E, 0xFFE0003F, .MSA, {}} },
    .MIN_U_B = { {.MIN_U_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7A80000E, 0xFFE0003F, .MSA, {}} },
    .MIN_U_H = { {.MIN_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AA0000E, 0xFFE0003F, .MSA, {}} },
    .MIN_U_W = { {.MIN_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AC0000E, 0xFFE0003F, .MSA, {}} },
    .MIN_U_D = { {.MIN_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7AE0000E, 0xFFE0003F, .MSA, {}} },
    .MAX_S_B = { {.MAX_S_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7900000E, 0xFFE0003F, .MSA, {}} },
    .MAX_S_H = { {.MAX_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7920000E, 0xFFE0003F, .MSA, {}} },
    .MAX_S_W = { {.MAX_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7940000E, 0xFFE0003F, .MSA, {}} },
    .MAX_S_D = { {.MAX_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7960000E, 0xFFE0003F, .MSA, {}} },
    .MAX_U_B = { {.MAX_U_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7980000E, 0xFFE0003F, .MSA, {}} },
    .MAX_U_H = { {.MAX_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79A0000E, 0xFFE0003F, .MSA, {}} },
    .MAX_U_W = { {.MAX_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79C0000E, 0xFFE0003F, .MSA, {}} },
    .MAX_U_D = { {.MAX_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79E0000E, 0xFFE0003F, .MSA, {}} },

    // ---- Vector shifts (3R minor 0x0D variable shifts) ---------------------
    .SLL_B = { {.SLL_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7800000D, 0xFFE0003F, .MSA, {}} },
    .SLL_H = { {.SLL_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7820000D, 0xFFE0003F, .MSA, {}} },
    .SLL_W = { {.SLL_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7840000D, 0xFFE0003F, .MSA, {}} },
    .SLL_D = { {.SLL_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7860000D, 0xFFE0003F, .MSA, {}} },
    .SRA_B = { {.SRA_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7880000D, 0xFFE0003F, .MSA, {}} },
    .SRA_H = { {.SRA_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78A0000D, 0xFFE0003F, .MSA, {}} },
    .SRA_W = { {.SRA_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78C0000D, 0xFFE0003F, .MSA, {}} },
    .SRA_D = { {.SRA_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78E0000D, 0xFFE0003F, .MSA, {}} },
    .SRL_B = { {.SRL_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7900000D, 0xFFE0003F, .MSA, {}} },
    .SRL_H = { {.SRL_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7920000D, 0xFFE0003F, .MSA, {}} },
    .SRL_W = { {.SRL_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7940000D, 0xFFE0003F, .MSA, {}} },
    .SRL_D = { {.SRL_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7960000D, 0xFFE0003F, .MSA, {}} },

    // ---- Memory: LD/ST in MI10 format ---------------------------------------
    // MI10 form: opcode 0x1E in primary, bits 25:23 = df group, bits 22:16 = signed-10 disp,
    // bits 15:11 = rs (base), bits 10:6 = wd, bits 5:0 = minor (0x20 = LD, 0x24 = ST)
    //   LD.B: 0x78000020 / ST.B: 0x78000024
    //   LD.H: 0x78000021 / ST.H: 0x78000025
    //   LD.W: 0x78000022 / ST.W: 0x78000026
    //   LD.D: 0x78000023 / ST.D: 0x78000027
    .LD_B = { {.LD_B, {.MSA_VEC, .MEM, .NONE, .NONE}, {.WD, .MSA_OFFSET_BASE_B, .NONE, .NONE}, 0x78000020, 0xFC00003F, .MSA, {}} },
    .LD_H = { {.LD_H, {.MSA_VEC, .MEM, .NONE, .NONE}, {.WD, .MSA_OFFSET_BASE_H, .NONE, .NONE}, 0x78000021, 0xFC00003F, .MSA, {}} },
    .LD_W = { {.LD_W, {.MSA_VEC, .MEM, .NONE, .NONE}, {.WD, .MSA_OFFSET_BASE_W, .NONE, .NONE}, 0x78000022, 0xFC00003F, .MSA, {}} },
    .LD_D = { {.LD_D, {.MSA_VEC, .MEM, .NONE, .NONE}, {.WD, .MSA_OFFSET_BASE_D, .NONE, .NONE}, 0x78000023, 0xFC00003F, .MSA, {}} },
    .ST_B = { {.ST_B, {.MSA_VEC, .MEM, .NONE, .NONE}, {.WD, .MSA_OFFSET_BASE_B, .NONE, .NONE}, 0x78000024, 0xFC00003F, .MSA, {}} },
    .ST_H = { {.ST_H, {.MSA_VEC, .MEM, .NONE, .NONE}, {.WD, .MSA_OFFSET_BASE_H, .NONE, .NONE}, 0x78000025, 0xFC00003F, .MSA, {}} },
    .ST_W = { {.ST_W, {.MSA_VEC, .MEM, .NONE, .NONE}, {.WD, .MSA_OFFSET_BASE_W, .NONE, .NONE}, 0x78000026, 0xFC00003F, .MSA, {}} },
    .ST_D = { {.ST_D, {.MSA_VEC, .MEM, .NONE, .NONE}, {.WD, .MSA_OFFSET_BASE_D, .NONE, .NONE}, 0x78000027, 0xFC00003F, .MSA, {}} },

    // ---- LDI: load immediate -- I5 format with signed 10-bit imm at 20:11 --
    // Use IMM5 here as a representative; production VFPU-style I10 is similar.
    .LDI_B = { {.LDI_B, {.MSA_VEC, .IMM5, .NONE, .NONE}, {.WD, .MSA_I5, .NONE, .NONE}, 0x7B000007, 0xFFE0003F, .MSA, {}} },
    .LDI_H = { {.LDI_H, {.MSA_VEC, .IMM5, .NONE, .NONE}, {.WD, .MSA_I5, .NONE, .NONE}, 0x7B200007, 0xFFE0003F, .MSA, {}} },
    .LDI_W = { {.LDI_W, {.MSA_VEC, .IMM5, .NONE, .NONE}, {.WD, .MSA_I5, .NONE, .NONE}, 0x7B400007, 0xFFE0003F, .MSA, {}} },
    .LDI_D = { {.LDI_D, {.MSA_VEC, .IMM5, .NONE, .NONE}, {.WD, .MSA_I5, .NONE, .NONE}, 0x7B600007, 0xFFE0003F, .MSA, {}} },

    // =========================================================================
    // §13 PSP Allegrex VFPU control / no-operand instructions
    // =========================================================================
    //
    // VFPU lives in primary opcodes 0x18 (cop2-like) and 0x3F (vfpu-specific).
    // The full Feature has ~150 instructions across many encoding flavours --
    // scalar/pair/triple/quad lane (.s/.p/.t/.q), prefix ops (VPFXS/T/D),
    // matrix forms, and lookup-table generators. Operand encoding uses
    // 7-bit register IDs split across the instruction word, with the high
    // bit of each VFPU register byte selecting an orientation hint.
    //
    // Below are the no-operand control ops where the entire 32-bit word is
    // a fixed constant; they're well-known via PPSSPP/JPCSP. The fully
    // operand-bearing VFPU forms (VADD/VSUB/VMUL/VDOT/...) need careful
    // bit-level cross-reference and are intentionally deferred -- see
    // ENCODING_TABLE entry counts and use docs/mips_platforms.md for status.

    .VNOP   = { {.VNOP,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFFFF0000, 0xFFFFFFFF, .VFPU_PSP, {}} },
    .VSYNC  = { {.VSYNC,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFFFF0320, 0xFFFFFFFF, .VFPU_PSP, {}} },
    .VFLUSH = { {.VFLUSH, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFFFF040D, 0xFFFFFFFF, .VFPU_PSP, {}} },

    // ---- VFPU memory: LV.S / SV.S / LV.Q / SV.Q -----------------------------
    //
    //   LV.S vd, off(base):  bits 31:26 = 110010 (0x32) -> word 0xC8000000
    //                        bits 25:21 = base, bits 20:16 = vd[6:2],
    //                        bits 15:2 = disp (mult of 4), bits 1:0 = vd[1:0]
    //   LV.Q vd, off(base):  bits 31:26 = 110110 (0x36) -> 0xD8000000
    //   SV.S rs, off(base):  bits 31:26 = 111010 (0x3A) -> 0xE8000000
    //   SV.Q rs, off(base):  bits 31:26 = 111110 (0x3E) -> 0xF8000000
    //
    // Mask covers only the primary opcode (bits 31:26): operand-driven base,
    // disp, and vd-split bits land in the zero positions.

    .LV_S = { {.LV_S, {.VFPU_S, .MEM, .NONE, .NONE}, {.VFPU_VT_MEM, .VFPU_OFFSET_BASE, .NONE, .NONE}, 0xC8000000, 0xFC000000, .VFPU_PSP, {}} },
    .LV_Q = { {.LV_Q, {.VFPU_Q, .MEM, .NONE, .NONE}, {.VFPU_VT_MEM, .VFPU_OFFSET_BASE, .NONE, .NONE}, 0xD8000000, 0xFC000000, .VFPU_PSP, {}} },
    .SV_S = { {.SV_S, {.VFPU_S, .MEM, .NONE, .NONE}, {.VFPU_VT_MEM, .VFPU_OFFSET_BASE, .NONE, .NONE}, 0xE8000000, 0xFC000000, .VFPU_PSP, {}} },
    .SV_Q = { {.SV_Q, {.VFPU_Q, .MEM, .NONE, .NONE}, {.VFPU_VT_MEM, .VFPU_OFFSET_BASE, .NONE, .NONE}, 0xF8000000, 0xFC000000, .VFPU_PSP, {}} },

    // ---- VFPU arithmetic: 3-register form (vd = vs op vt) -------------------
    //
    //   bits 31:24 = opcode byte (0x60 = VFPU0 / VADD, 0x64 = VFPU1 / VMUL)
    //   bit  23    = sub-opcode (e.g., VADD vs VSUB share 0x60; VSUB has bit 23 set)
    //   bits 22:16 = vt   bit15 = width-hi    bits 14:8 = vs
    //   bit   7    = width-lo                 bits  6:0 = vd
    //
    // Mask covers opcode byte + sub-bit + the two width bits = 0xFF808080.
    // .s / .p / .t / .q baked in via the (bit15, bit7) pair on each entry.

    // VADD: 0x60000000 + width bits
    .VADD_S = { {.VADD_S, {.VFPU_S,.VFPU_S,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x60000000, 0xFF808080, .VFPU_PSP, {}} },
    .VADD_P = { {.VADD_P, {.VFPU_P,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x60000080, 0xFF808080, .VFPU_PSP, {}} },
    .VADD_T = { {.VADD_T, {.VFPU_T,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x60008000, 0xFF808080, .VFPU_PSP, {}} },
    .VADD_Q = { {.VADD_Q, {.VFPU_Q,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x60008080, 0xFF808080, .VFPU_PSP, {}} },

    // VSUB: 0x60800000 + width
    .VSUB_S = { {.VSUB_S, {.VFPU_S,.VFPU_S,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x60800000, 0xFF808080, .VFPU_PSP, {}} },
    .VSUB_P = { {.VSUB_P, {.VFPU_P,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x60800080, 0xFF808080, .VFPU_PSP, {}} },
    .VSUB_T = { {.VSUB_T, {.VFPU_T,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x60808000, 0xFF808080, .VFPU_PSP, {}} },
    .VSUB_Q = { {.VSUB_Q, {.VFPU_Q,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x60808080, 0xFF808080, .VFPU_PSP, {}} },

    // VMUL: 0x64000000 + width  (primary opcode 0x19 = VFPU1)
    .VMUL_S = { {.VMUL_S, {.VFPU_S,.VFPU_S,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x64000000, 0xFF808080, .VFPU_PSP, {}} },
    .VMUL_P = { {.VMUL_P, {.VFPU_P,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x64000080, 0xFF808080, .VFPU_PSP, {}} },
    .VMUL_T = { {.VMUL_T, {.VFPU_T,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x64008000, 0xFF808080, .VFPU_PSP, {}} },
    .VMUL_Q = { {.VMUL_Q, {.VFPU_Q,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x64008080, 0xFF808080, .VFPU_PSP, {}} },

    // VDIV: 0x63800000 + width  (scalar-only natively; .p/.t/.q are emulated)
    .VDIV_S = { {.VDIV_S, {.VFPU_S,.VFPU_S,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x63800000, 0xFF808080, .VFPU_PSP, {}} },
    .VDIV_P = { {.VDIV_P, {.VFPU_P,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x63800080, 0xFF808080, .VFPU_PSP, {}} },
    .VDIV_T = { {.VDIV_T, {.VFPU_T,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x63808000, 0xFF808080, .VFPU_PSP, {}} },
    .VDIV_Q = { {.VDIV_Q, {.VFPU_Q,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x63808080, 0xFF808080, .VFPU_PSP, {}} },

    // ---- VFPU unary: 2-register form (vd = op vs) ---------------------------
    //
    //   bits 31:16 = opcode header (0xD000 base for unary ALU; sub-op in bits 24:16)
    //   bit 15 / bit 7 = width  bits 14:8 = vs  bits 6:0 = vd  (vt unused)
    //
    // ABS / NEG / SQRT / RCP / RSQ / MOV all share the same skeleton with
    // a different sub-opcode in bits 24:16.

    // VABS: 0xD0010000 + width
    .VABS_S = { {.VABS_S, {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0010000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VABS_P = { {.VABS_P, {.VFPU_P,.VFPU_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0010080, 0xFFFF8080, .VFPU_PSP, {}} },
    .VABS_T = { {.VABS_T, {.VFPU_T,.VFPU_T,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0018000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VABS_Q = { {.VABS_Q, {.VFPU_Q,.VFPU_Q,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0018080, 0xFFFF8080, .VFPU_PSP, {}} },

    // VNEG: 0xD0020000 + width
    .VNEG_S = { {.VNEG_S, {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0020000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VNEG_P = { {.VNEG_P, {.VFPU_P,.VFPU_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0020080, 0xFFFF8080, .VFPU_PSP, {}} },
    .VNEG_T = { {.VNEG_T, {.VFPU_T,.VFPU_T,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0028000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VNEG_Q = { {.VNEG_Q, {.VFPU_Q,.VFPU_Q,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0028080, 0xFFFF8080, .VFPU_PSP, {}} },

    // VMOV: 0xD0000000 + width
    .VMOV_S = { {.VMOV_S, {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0000000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VMOV_P = { {.VMOV_P, {.VFPU_P,.VFPU_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0000080, 0xFFFF8080, .VFPU_PSP, {}} },
    .VMOV_T = { {.VMOV_T, {.VFPU_T,.VFPU_T,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0008000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VMOV_Q = { {.VMOV_Q, {.VFPU_Q,.VFPU_Q,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0008080, 0xFFFF8080, .VFPU_PSP, {}} },

    // VSQRT.S only (no .p/.t/.q natively)
    .VSQRT_S = { {.VSQRT_S, {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0160000, 0xFFFF8080, .VFPU_PSP, {}} },

    // VRCP: 0xD0100000 + width
    .VRCP_S = { {.VRCP_S, {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0100000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VRCP_P = { {.VRCP_P, {.VFPU_P,.VFPU_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0100080, 0xFFFF8080, .VFPU_PSP, {}} },
    .VRCP_T = { {.VRCP_T, {.VFPU_T,.VFPU_T,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0108000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VRCP_Q = { {.VRCP_Q, {.VFPU_Q,.VFPU_Q,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0108080, 0xFFFF8080, .VFPU_PSP, {}} },

    // VRSQ: 0xD0110000 + width
    .VRSQ_S = { {.VRSQ_S, {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0110000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VRSQ_P = { {.VRSQ_P, {.VFPU_P,.VFPU_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0110080, 0xFFFF8080, .VFPU_PSP, {}} },
    .VRSQ_T = { {.VRSQ_T, {.VFPU_T,.VFPU_T,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0118000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VRSQ_Q = { {.VRSQ_Q, {.VFPU_Q,.VFPU_Q,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0118080, 0xFFFF8080, .VFPU_PSP, {}} },

    // ---- VFPU min/max + scale ------------------------------------------------
    .VMIN_S = { {.VMIN_S, {.VFPU_S,.VFPU_S,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x6D000000, 0xFF808080, .VFPU_PSP, {}} },
    .VMIN_P = { {.VMIN_P, {.VFPU_P,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x6D000080, 0xFF808080, .VFPU_PSP, {}} },
    .VMIN_T = { {.VMIN_T, {.VFPU_T,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x6D008000, 0xFF808080, .VFPU_PSP, {}} },
    .VMIN_Q = { {.VMIN_Q, {.VFPU_Q,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x6D008080, 0xFF808080, .VFPU_PSP, {}} },
    .VMAX_S = { {.VMAX_S, {.VFPU_S,.VFPU_S,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x6D800000, 0xFF808080, .VFPU_PSP, {}} },
    .VMAX_P = { {.VMAX_P, {.VFPU_P,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x6D800080, 0xFF808080, .VFPU_PSP, {}} },
    .VMAX_T = { {.VMAX_T, {.VFPU_T,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x6D808000, 0xFF808080, .VFPU_PSP, {}} },
    .VMAX_Q = { {.VMAX_Q, {.VFPU_Q,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x6D808080, 0xFF808080, .VFPU_PSP, {}} },

    // VSCL: scalar-times-vector. vd = vs * vt[scalar]. Only .p/.t/.q forms.
    .VSCL_P = { {.VSCL_P, {.VFPU_P,.VFPU_P,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x65000080, 0xFF808080, .VFPU_PSP, {}} },
    .VSCL_T = { {.VSCL_T, {.VFPU_T,.VFPU_T,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x65008000, 0xFF808080, .VFPU_PSP, {}} },
    .VSCL_Q = { {.VSCL_Q, {.VFPU_Q,.VFPU_Q,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x65008080, 0xFF808080, .VFPU_PSP, {}} },

    // VDOT: vector dot-product into scalar. vd[.s] = sum(vs * vt) for .p/.t/.q.
    .VDOT_P = { {.VDOT_P, {.VFPU_S,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x64800080, 0xFF808080, .VFPU_PSP, {}} },
    .VDOT_T = { {.VDOT_T, {.VFPU_S,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x64808000, 0xFF808080, .VFPU_PSP, {}} },
    .VDOT_Q = { {.VDOT_Q, {.VFPU_S,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x64808080, 0xFF808080, .VFPU_PSP, {}} },

    // ---- VFPU constant load: VCST.S vd, #const_index ------------------------
    //   bits 31:21 = 11010000 011   bits 20:16 = const  bits 15:7 = 0
    //   bit 7 = width-lo  bits 6:0 = vd
    .VCST_S = { {.VCST_S, {.VFPU_S, .IMM5, .NONE, .NONE}, {.VFPU_VD, .VFPU_CONST, .NONE, .NONE}, 0xD0600000, 0xFFE08080, .VFPU_PSP, {}} },
    .VCST_P = { {.VCST_P, {.VFPU_P, .IMM5, .NONE, .NONE}, {.VFPU_VD, .VFPU_CONST, .NONE, .NONE}, 0xD0600080, 0xFFE08080, .VFPU_PSP, {}} },
    .VCST_T = { {.VCST_T, {.VFPU_T, .IMM5, .NONE, .NONE}, {.VFPU_VD, .VFPU_CONST, .NONE, .NONE}, 0xD0608000, 0xFFE08080, .VFPU_PSP, {}} },
    .VCST_Q = { {.VCST_Q, {.VFPU_Q, .IMM5, .NONE, .NONE}, {.VFPU_VD, .VFPU_CONST, .NONE, .NONE}, 0xD0608080, 0xFFE08080, .VFPU_PSP, {}} },

    // ---- VFPU prefix instructions: VPFXS / VPFXT / VPFXD --------------------
    //
    // Each takes a 20-bit prefix mask in the low 20 bits of the instruction
    // word that modifies the source/destination of the *next* vector op.
    //   VPFXS: 0xDC000000 base
    //   VPFXT: 0xDD000000
    //   VPFXD: 0xDE000000

    .VPFXS = { {.VPFXS, {.IMM20, .NONE, .NONE, .NONE}, {.VFPU_PFX, .NONE, .NONE, .NONE}, 0xDC000000, 0xFFF00000, .VFPU_PSP, {}} },
    .VPFXT = { {.VPFXT, {.IMM20, .NONE, .NONE, .NONE}, {.VFPU_PFX, .NONE, .NONE, .NONE}, 0xDD000000, 0xFFF00000, .VFPU_PSP, {}} },
    .VPFXD = { {.VPFXD, {.IMM20, .NONE, .NONE, .NONE}, {.VFPU_PFX, .NONE, .NONE, .NONE}, 0xDE000000, 0xFFF00000, .VFPU_PSP, {}} },

    // ---- VFPU move-between-GPR: MFV / MTV -----------------------------------
    //
    // MFV rt, vd  -- move VFPU vd[.s] -> GPR rt
    //   bits 31:21 = 01001000 011 (0x4827xxxx? no -- mfv encoding is in COP2 space)
    //   Standard layout:  010010 00011 rt vd[6:0]  (COP2 MF with sub-op 3)
    //   word = (0x12 << 26) | (3 << 21) | (rt << 16) | vd  = 0x48600000 | (rt<<16) | vd
    .MFV = { {.MFV, {.GPR, .VFPU_S, .NONE, .NONE}, {.RT, .VFPU_VD, .NONE, .NONE}, 0x48600000, 0xFFE00080, .VFPU_PSP, {}} },
    // MTV rt, vd -- move GPR rt -> VFPU vd[.s]
    //   word = (0x12 << 26) | (7 << 21) | (rt << 16) | vd  = 0x48E00000 | (rt<<16) | vd
    .MTV = { {.MTV, {.GPR, .VFPU_S, .NONE, .NONE}, {.RT, .VFPU_VD, .NONE, .NONE}, 0x48E00000, 0xFFE00080, .VFPU_PSP, {}} },

    // =========================================================================
    // §14 VFPU transcendentals (unary, single-precision only)
    // =========================================================================
    //
    // All live in the D0xx0000 unary block. Sub-op at bits 22:16 picks the
    // specific function. Mask 0xFFFF8080 covers opcode + sub-op + width bits.
    //
    //   VSIN   = 0xD0120000
    //   VCOS   = 0xD0130000
    //   VEXP2  = 0xD0140000
    //   VLOG2  = 0xD0150000
    //   VASIN  = 0xD0170000   (arcsine in turns; result/PI)
    //   VNRCP  = 0xD0180000   (negated reciprocal)
    //   VNSIN  = 0xD01A0000   (negated sine)
    //   VREXP2 = 0xD01C0000   (reciprocal of EXP2)
    //   VSGN   = 0xD04A0000   (sign extraction; -1 / 0 / +1)

    .VSIN_S   = { {.VSIN_S,   {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0120000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VCOS_S   = { {.VCOS_S,   {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0130000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VEXP2_S  = { {.VEXP2_S,  {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0140000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VLOG2_S  = { {.VLOG2_S,  {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0150000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VASIN_S  = { {.VASIN_S,  {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0170000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VNRCP_S  = { {.VNRCP_S,  {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0180000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VNSIN_S  = { {.VNSIN_S,  {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD01A0000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VREXP2_S = { {.VREXP2_S, {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD01C0000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VSGN_S   = { {.VSGN_S,   {.VFPU_S,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD04A0000, 0xFFFF8080, .VFPU_PSP, {}} },

    // =========================================================================
    // §15 VFPU FP <-> int conversions (with 5-bit scale immediate)
    // =========================================================================
    //
    // Format:
    //   bits 31:21 = 11010010 0 RR  (RR = round mode: 00=N, 01=Z, 10=U, 11=D)
    //   bits 20:16 = 5-bit scale (signed magnitude of binary scale factor)
    //   bit  15    = width-hi   bits 14:8 = vs
    //   bit   7    = width-lo   bits  6:0 = vd
    //
    //   VF2IN.* = 0xD2000000 base (round to nearest)
    //   VF2IZ.* = 0xD2200000 base (round to zero)
    //   VF2IU.* = 0xD2400000 base (round up)
    //   VF2ID.* = 0xD2600000 base (round down)
    //   VI2F.*  = 0xD2800000 base (int->float with scale)

    .VF2IN_S = { {.VF2IN_S, {.VFPU_S,.VFPU_S,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2000000, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IN_P = { {.VF2IN_P, {.VFPU_P,.VFPU_P,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2000080, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IN_T = { {.VF2IN_T, {.VFPU_T,.VFPU_T,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2008000, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IN_Q = { {.VF2IN_Q, {.VFPU_Q,.VFPU_Q,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2008080, 0xFFE08080, .VFPU_PSP, {}} },

    .VF2IZ_S = { {.VF2IZ_S, {.VFPU_S,.VFPU_S,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2200000, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IZ_P = { {.VF2IZ_P, {.VFPU_P,.VFPU_P,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2200080, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IZ_T = { {.VF2IZ_T, {.VFPU_T,.VFPU_T,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2208000, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IZ_Q = { {.VF2IZ_Q, {.VFPU_Q,.VFPU_Q,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2208080, 0xFFE08080, .VFPU_PSP, {}} },

    .VF2IU_S = { {.VF2IU_S, {.VFPU_S,.VFPU_S,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2400000, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IU_P = { {.VF2IU_P, {.VFPU_P,.VFPU_P,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2400080, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IU_T = { {.VF2IU_T, {.VFPU_T,.VFPU_T,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2408000, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2IU_Q = { {.VF2IU_Q, {.VFPU_Q,.VFPU_Q,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2408080, 0xFFE08080, .VFPU_PSP, {}} },

    .VF2ID_S = { {.VF2ID_S, {.VFPU_S,.VFPU_S,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2600000, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2ID_P = { {.VF2ID_P, {.VFPU_P,.VFPU_P,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2600080, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2ID_T = { {.VF2ID_T, {.VFPU_T,.VFPU_T,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2608000, 0xFFE08080, .VFPU_PSP, {}} },
    .VF2ID_Q = { {.VF2ID_Q, {.VFPU_Q,.VFPU_Q,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2608080, 0xFFE08080, .VFPU_PSP, {}} },

    .VI2F_S  = { {.VI2F_S,  {.VFPU_S,.VFPU_S,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2800000, 0xFFE08080, .VFPU_PSP, {}} },
    .VI2F_P  = { {.VI2F_P,  {.VFPU_P,.VFPU_P,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2800080, 0xFFE08080, .VFPU_PSP, {}} },
    .VI2F_T  = { {.VI2F_T,  {.VFPU_T,.VFPU_T,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2808000, 0xFFE08080, .VFPU_PSP, {}} },
    .VI2F_Q  = { {.VI2F_Q,  {.VFPU_Q,.VFPU_Q,.IMM5,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_CONST,.NONE}, 0xD2808080, 0xFFE08080, .VFPU_PSP, {}} },

    // VF2H pair -> two-half-packed-into-single (.P input -> .S output)
    .VF2H_P = { {.VF2H_P, {.VFPU_S,.VFPU_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0320080, 0xFFFF8080, .VFPU_PSP, {}} },
    // VH2F single (2 packed halfs) -> pair of floats
    .VH2F_S = { {.VH2F_S, {.VFPU_P,.VFPU_S,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0330000, 0xFFFF8080, .VFPU_PSP, {}} },

    // =========================================================================
    // §16 VFPU reductions (vd[.s] = reduce(vs[.p/.t/.q]))
    // =========================================================================
    //
    //   VFAD = sum of all lanes       base 0xD0460000 (D0 unary, sub-op 46)
    //   VAVG = average of all lanes   base 0xD0470000 (sub-op 47)
    //   VHDP = homogeneous dot prod   base 0x66000000 (VFPU1 / 3R-like, two srcs)

    .VFAD_P = { {.VFAD_P, {.VFPU_S,.VFPU_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0460080, 0xFFFF8080, .VFPU_PSP, {}} },
    .VFAD_T = { {.VFAD_T, {.VFPU_S,.VFPU_T,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0468000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VFAD_Q = { {.VFAD_Q, {.VFPU_S,.VFPU_Q,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0468080, 0xFFFF8080, .VFPU_PSP, {}} },

    .VAVG_P = { {.VAVG_P, {.VFPU_S,.VFPU_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0470080, 0xFFFF8080, .VFPU_PSP, {}} },
    .VAVG_T = { {.VAVG_T, {.VFPU_S,.VFPU_T,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0478000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VAVG_Q = { {.VAVG_Q, {.VFPU_S,.VFPU_Q,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xD0478080, 0xFFFF8080, .VFPU_PSP, {}} },

    .VHDP_P = { {.VHDP_P, {.VFPU_S,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x66000080, 0xFF808080, .VFPU_PSP, {}} },
    .VHDP_T = { {.VHDP_T, {.VFPU_S,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x66008000, 0xFF808080, .VFPU_PSP, {}} },
    .VHDP_Q = { {.VHDP_Q, {.VFPU_S,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x66008080, 0xFF808080, .VFPU_PSP, {}} },

    // =========================================================================
    // §17 VFPU vector compare (writes VCC, not a register)
    // =========================================================================
    //
    //   VCMP cond, vs, vt   =  bits 31:24 = 0x6C
    //                          bit 23 = 0
    //                          bits 22:16 = vt   bit 15 = width-hi
    //                          bits 14:8 = vs   bit 7 = width-lo
    //                          bits 6:4 = 000   bits 3:0 = cond (4-bit predicate)

    .VCMP_S = { {.VCMP_S, {.IMM5,.VFPU_S,.VFPU_S,.NONE}, {.VFPU_COND4,.VFPU_VS,.VFPU_VT,.NONE}, 0x6C000000, 0xFF8080F0, .VFPU_PSP, {}} },
    .VCMP_P = { {.VCMP_P, {.IMM5,.VFPU_P,.VFPU_P,.NONE}, {.VFPU_COND4,.VFPU_VS,.VFPU_VT,.NONE}, 0x6C000080, 0xFF8080F0, .VFPU_PSP, {}} },
    .VCMP_T = { {.VCMP_T, {.IMM5,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_COND4,.VFPU_VS,.VFPU_VT,.NONE}, 0x6C008000, 0xFF8080F0, .VFPU_PSP, {}} },
    .VCMP_Q = { {.VCMP_Q, {.IMM5,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_COND4,.VFPU_VS,.VFPU_VT,.NONE}, 0x6C008080, 0xFF8080F0, .VFPU_PSP, {}} },

    // =========================================================================
    // §18 VFPU matrix-vector ops
    // =========================================================================
    //
    // VMMUL md, ms, mt -- matrix multiply (vd = vs * vt)
    //   VMMUL.P (2x2) = 0xF0000080
    //   VMMUL.T (3x3) = 0xF0008000
    //   VMMUL.Q (4x4) = 0xF0008080
    //
    // VTFM[N] vd, ms, vt -- transform a vector by a matrix (vd = ms * vt)
    //   VTFM2.P = 0xF0800080
    //   VTFM3.T = 0xF0808000
    //   VTFM4.Q = 0xF0808080
    //
    // VHTFM[N] vd, ms, vt -- homogeneous transform (last comp implicit = 1)
    //   VHTFM2.P = 0xF0800000
    //   VHTFM3.T = 0xF1008000  (different opcode-byte from VTFM3)
    //   VHTFM4.Q = 0xF1008080

    .VMMUL_P = { {.VMMUL_P, {.VFPU_M_P,.VFPU_M_P,.VFPU_M_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF0000080, 0xFF808080, .VFPU_PSP, {}} },
    .VMMUL_T = { {.VMMUL_T, {.VFPU_M_T,.VFPU_M_T,.VFPU_M_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF0008000, 0xFF808080, .VFPU_PSP, {}} },
    .VMMUL_Q = { {.VMMUL_Q, {.VFPU_M_Q,.VFPU_M_Q,.VFPU_M_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF0008080, 0xFF808080, .VFPU_PSP, {}} },

    .VTFM2_P = { {.VTFM2_P, {.VFPU_P,.VFPU_M_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF0800080, 0xFF808080, .VFPU_PSP, {}} },
    .VTFM3_T = { {.VTFM3_T, {.VFPU_T,.VFPU_M_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF0808000, 0xFF808080, .VFPU_PSP, {}} },
    .VTFM4_Q = { {.VTFM4_Q, {.VFPU_Q,.VFPU_M_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF0808080, 0xFF808080, .VFPU_PSP, {}} },

    .VHTFM2_P = { {.VHTFM2_P, {.VFPU_P,.VFPU_M_P,.VFPU_P,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF0800000, 0xFF808080, .VFPU_PSP, {}} },
    .VHTFM3_T = { {.VHTFM3_T, {.VFPU_T,.VFPU_M_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF1008000, 0xFF808080, .VFPU_PSP, {}} },
    .VHTFM4_Q = { {.VHTFM4_Q, {.VFPU_Q,.VFPU_M_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF1008080, 0xFF808080, .VFPU_PSP, {}} },

    // VMSCL md, ms, vt[.s] -- scalar-times-matrix
    //   VMSCL.P = 0xF2000080 / .T = 0xF2008000 / .Q = 0xF2008080
    .VMSCL_P = { {.VMSCL_P, {.VFPU_M_P,.VFPU_M_P,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF2000080, 0xFF808080, .VFPU_PSP, {}} },
    .VMSCL_T = { {.VMSCL_T, {.VFPU_M_T,.VFPU_M_T,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF2008000, 0xFF808080, .VFPU_PSP, {}} },
    .VMSCL_Q = { {.VMSCL_Q, {.VFPU_M_Q,.VFPU_M_Q,.VFPU_S,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF2008080, 0xFF808080, .VFPU_PSP, {}} },

    // =========================================================================
    // §19 VFPU matrix-unary (matrix-move family)
    // =========================================================================
    //
    // Same unary layout as VMOV/VABS/VNEG but in the F3xx region; sub-op
    // at bits 22:16 picks the matrix function:
    //   VMMOV  = 0xF3800000   (matrix copy md = ms)
    //   VMIDT  = 0xF3830000   (identity matrix)
    //   VMZERO = 0xF3860000   (zero matrix)
    //   VMONE  = 0xF3870000   (all-ones matrix)
    //
    // VMIDT/VMZERO/VMONE take only a destination (no vs).

    .VMMOV_P  = { {.VMMOV_P,  {.VFPU_M_P,.VFPU_M_P,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xF3800080, 0xFFFF8080, .VFPU_PSP, {}} },
    .VMMOV_T  = { {.VMMOV_T,  {.VFPU_M_T,.VFPU_M_T,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xF3808000, 0xFFFF8080, .VFPU_PSP, {}} },
    .VMMOV_Q  = { {.VMMOV_Q,  {.VFPU_M_Q,.VFPU_M_Q,.NONE,.NONE}, {.VFPU_VD,.VFPU_VS,.NONE,.NONE}, 0xF3808080, 0xFFFF8080, .VFPU_PSP, {}} },

    .VMIDT_P  = { {.VMIDT_P,  {.VFPU_M_P,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3830080, 0xFFFFFF80, .VFPU_PSP, {}} },
    .VMIDT_T  = { {.VMIDT_T,  {.VFPU_M_T,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3838000, 0xFFFFFF80, .VFPU_PSP, {}} },
    .VMIDT_Q  = { {.VMIDT_Q,  {.VFPU_M_Q,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3838080, 0xFFFFFF80, .VFPU_PSP, {}} },

    .VMZERO_P = { {.VMZERO_P, {.VFPU_M_P,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3860080, 0xFFFFFF80, .VFPU_PSP, {}} },
    .VMZERO_T = { {.VMZERO_T, {.VFPU_M_T,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3868000, 0xFFFFFF80, .VFPU_PSP, {}} },
    .VMZERO_Q = { {.VMZERO_Q, {.VFPU_M_Q,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3868080, 0xFFFFFF80, .VFPU_PSP, {}} },

    .VMONE_P  = { {.VMONE_P,  {.VFPU_M_P,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3870080, 0xFFFFFF80, .VFPU_PSP, {}} },
    .VMONE_T  = { {.VMONE_T,  {.VFPU_M_T,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3878000, 0xFFFFFF80, .VFPU_PSP, {}} },
    .VMONE_Q  = { {.VMONE_Q,  {.VFPU_M_Q,.NONE,.NONE,.NONE}, {.VFPU_VD,.NONE,.NONE,.NONE}, 0xF3878080, 0xFFFFFF80, .VFPU_PSP, {}} },

    // =========================================================================
    // §20 VFPU cross product / quaternion
    // =========================================================================
    //
    //   VCRS.T  vd, vs, vt    cross product (triple only) = 0x66808000
    //   VCRSP.T vd, vs, vt    cross product (alt formula) = 0xF2818000
    //   VQMUL.Q vd, vs, vt    quaternion multiply (quad only) = 0xF2808080

    .VCRS_T  = { {.VCRS_T,  {.VFPU_T,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0x66808000, 0xFF808080, .VFPU_PSP, {}} },
    .VCRSP_T = { {.VCRSP_T, {.VFPU_T,.VFPU_T,.VFPU_T,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF2818000, 0xFF818080, .VFPU_PSP, {}} },
    .VQMUL_Q = { {.VQMUL_Q, {.VFPU_Q,.VFPU_Q,.VFPU_Q,.NONE}, {.VFPU_VD,.VFPU_VS,.VFPU_VT,.NONE}, 0xF2808080, 0xFF808080, .VFPU_PSP, {}} },

    // =========================================================================
    // §21 VFPU control-register transfer (FCR0-style)
    // =========================================================================
    //
    //   MFVC rt, vfpu_ctrl[5:0]   COP2 sub-op 6 = 0x48C00000 + (rt<<16) + ctrl
    //   MTVC rt, vfpu_ctrl[5:0]   COP2 sub-op 7 = 0x48E00000 (wait -- MTV uses 7)
    // Actually MFVC = 0x4840xxxx / MTVC = 0x48C0xxxx in some refs; the exact
    // sub-op selectors are 0x02 / 0x06 below the MFV/MTV pair. We emit:
    //   MFVC = 0x48400000, MTVC = 0x48C00000 with the same operand shape.

    .MFVC = { {.MFVC, {.GPR, .IMM5, .NONE, .NONE}, {.RT, .VFPU_CONST, .NONE, .NONE}, 0x48400000, 0xFFE00000, .VFPU_PSP, {}} },
    .MTVC = { {.MTVC, {.GPR, .IMM5, .NONE, .NONE}, {.RT, .VFPU_CONST, .NONE, .NONE}, 0x48C00000, 0xFFE00000, .VFPU_PSP, {}} },

    // =========================================================================
    // §22 VFPU branches (test VCC bits)
    // =========================================================================
    //
    //   BVF cc, label    -- branch if VCC[cc] = false
    //   BVT cc, label    -- branch if VCC[cc] = true
    //   BVFL cc, label   -- BVF with branch-likely semantics
    //   BVTL cc, label   -- BVT with branch-likely semantics
    //
    // Layout: COP2 BC2 sub-form
    //   bits 31:26 = 010010 (COP2)         bits 25:21 = 01000 (BC2)
    //   bits 20:18 = cc selector (3 bits, picks vcc[cc])
    //   bit 17 = likely flag (0 = standard, 1 = likely)
    //   bit 16 = condition (0 = false / BVF, 1 = true / BVT)
    //   bits 15:0 = signed 16-bit PC-rel offset (in instruction-words; <<2)
    //
    // Mask covers primary+BC2+bits 17:16; cc and offset are operand-driven.

    .BVF  = { {.BVF,  {.IMM5, .REL16, .NONE, .NONE}, {.VFPU_CC3, .BRANCH_16, .NONE, .NONE}, 0x49000000, 0xFFE30000, .VFPU_PSP, {delay_slot=true}} },
    .BVT  = { {.BVT,  {.IMM5, .REL16, .NONE, .NONE}, {.VFPU_CC3, .BRANCH_16, .NONE, .NONE}, 0x49010000, 0xFFE30000, .VFPU_PSP, {delay_slot=true}} },
    .BVFL = { {.BVFL, {.IMM5, .REL16, .NONE, .NONE}, {.VFPU_CC3, .BRANCH_16, .NONE, .NONE}, 0x49020000, 0xFFE30000, .VFPU_PSP, {delay_slot=true, likely=true}} },
    .BVTL = { {.BVTL, {.IMM5, .REL16, .NONE, .NONE}, {.VFPU_CC3, .BRANCH_16, .NONE, .NONE}, 0x49030000, 0xFFE30000, .VFPU_PSP, {delay_slot=true, likely=true}} },

    // =========================================================================
    // §23 VFPU unaligned quad load/store (LVL.Q / LVR.Q / SVL.Q / SVR.Q)
    // =========================================================================
    //
    // Same SP-style memory operand layout as LV/SV, but with explicit
    // "left" / "right" semantics for misaligned 16-byte loads/stores
    // (similar to MIPS LWL/LWR).
    //
    //   LVL.Q: primary 0x35 + bit 1 = 1 (left)   = 0xD4000002
    //   LVR.Q: primary 0x35 + bit 1 = 0 (right)  = 0xD4000000
    //   SVL.Q: primary 0x3D + bit 1 = 1          = 0xF4000002
    //   SVR.Q: primary 0x3D + bit 1 = 0          = 0xF4000000
    //
    // The low bit of the offset field doubles as the L/R selector (offset
    // must be 4-byte aligned), so the user encodes alignment + L/R via the
    // memory disp's low bits. Mask covers only the primary opcode.

    .LVL_Q = { {.LVL_Q, {.VFPU_Q, .MEM, .NONE, .NONE}, {.VFPU_VT_MEM, .VFPU_OFFSET_BASE, .NONE, .NONE}, 0xD4000002, 0xFC000002, .VFPU_PSP, {}} },
    .LVR_Q = { {.LVR_Q, {.VFPU_Q, .MEM, .NONE, .NONE}, {.VFPU_VT_MEM, .VFPU_OFFSET_BASE, .NONE, .NONE}, 0xD4000000, 0xFC000002, .VFPU_PSP, {}} },
    .SVL_Q = { {.SVL_Q, {.VFPU_Q, .MEM, .NONE, .NONE}, {.VFPU_VT_MEM, .VFPU_OFFSET_BASE, .NONE, .NONE}, 0xF4000002, 0xFC000002, .VFPU_PSP, {}} },
    .SVR_Q = { {.SVR_Q, {.VFPU_Q, .MEM, .NONE, .NONE}, {.VFPU_VT_MEM, .VFPU_OFFSET_BASE, .NONE, .NONE}, 0xF4000000, 0xFC000002, .VFPU_PSP, {}} },

    // =========================================================================
    // §24 VFPU integer/float immediate load
    // =========================================================================
    //
    //   VIIM.S vd, #imm16   load 16-bit signed integer immediate into vd (scalar)
    //   VFIM.S vd, #imm16   load 16-bit half-precision float into vd
    //
    // Both share the same skeleton: imm16 at bits 15:0 (the low 16 bits of
    // the instruction word), with vd in the IMM5-like bit 25:21 slot. The
    // VIIM vs VFIM distinction is in bit 23.
    //   VIIM = 0xDF000000 base   (bit 23 = 0)
    //   VFIM = 0xDF800000 base   (bit 23 = 1)
    //
    // Mask covers bits 31:24 only; vd lives at 25:21, imm at 15:0.

    .VIIM_S = { {.VIIM_S, {.VFPU_S, .IMM16S, .NONE, .NONE}, {.RT, .IMM_16, .NONE, .NONE}, 0xDF000000, 0xFF800000, .VFPU_PSP, {}} },
    .VFIM_S = { {.VFIM_S, {.VFPU_S, .IMM16S, .NONE, .NONE}, {.RT, .IMM_16, .NONE, .NONE}, 0xDF800000, 0xFF800000, .VFPU_PSP, {}} },

    // Paired-single FP that this llvm-mc cannot assemble (it knows only .S/.D
    // of these). Derived from the llvm-verified single forms by setting the
    // data format to PS: COP1X fused-multiply-add fmt is bits 2:0 (S=0 -> PS=6),
    // and the COP1 conditional-move fmt is bits 25:21 (S=16 -> PS=22, i.e.
    // +0x00C00000). Same operand slots and masks as the .S forms. Decode-clean.
    .MADD_PS  = { {.MADD_PS,  {.FPR_PS,.FPR_PS,.FPR_PS,.FPR_PS}, {.FD,.FR,.FS,.FT}, 0x4C000026, 0xFC00003F, .FPU, {}} },
    .MSUB_PS  = { {.MSUB_PS,  {.FPR_PS,.FPR_PS,.FPR_PS,.FPR_PS}, {.FD,.FR,.FS,.FT}, 0x4C00002E, 0xFC00003F, .FPU, {}} },
    .NMADD_PS = { {.NMADD_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.FPR_PS}, {.FD,.FR,.FS,.FT}, 0x4C000036, 0xFC00003F, .FPU, {}} },
    .NMSUB_PS = { {.NMSUB_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.FPR_PS}, {.FD,.FR,.FS,.FT}, 0x4C00003E, 0xFC00003F, .FPU, {}} },
    .MOVN_PS  = { {.MOVN_PS,  {.FPR_PS,.FPR_PS,.GPR,.NONE}, {.FD,.FS,.RT,.NONE}, 0x46C00013, 0xFFE0003F, .FPU, {}} },
    .MOVZ_PS  = { {.MOVZ_PS,  {.FPR_PS,.FPR_PS,.GPR,.NONE}, {.FD,.FS,.RT,.NONE}, 0x46C00012, 0xFFE0003F, .FPU, {}} },
    .MOVF_PS  = { {.MOVF_PS,  {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FD,.FS,.FCC_BC,.NONE}, 0x46C00011, 0xFFE3003F, .FPU, {}} },
    .MOVT_PS  = { {.MOVT_PS,  {.FPR_PS,.FPR_PS,.FCC,.NONE}, {.FD,.FS,.FCC_BC,.NONE}, 0x46C10011, 0xFFE3003F, .FPU, {}} },

    // SPECGEN:BEGIN
    .FADD_W = { {.FADD_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7800001B, 0xFFE0003F, .MSA, {}} },
    .FADD_D = { {.FADD_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7820001B, 0xFFE0003F, .MSA, {}} },
    .FSUB_W = { {.FSUB_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7840001B, 0xFFE0003F, .MSA, {}} },
    .FSUB_D = { {.FSUB_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7860001B, 0xFFE0003F, .MSA, {}} },
    .FMUL_W = { {.FMUL_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7880001B, 0xFFE0003F, .MSA, {}} },
    .FMUL_D = { {.FMUL_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78A0001B, 0xFFE0003F, .MSA, {}} },
    .FDIV_W = { {.FDIV_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78C0001B, 0xFFE0003F, .MSA, {}} },
    .FDIV_D = { {.FDIV_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78E0001B, 0xFFE0003F, .MSA, {}} },
    .FMAX_W = { {.FMAX_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7B80001B, 0xFFE0003F, .MSA, {}} },
    .FMAX_D = { {.FMAX_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7BA0001B, 0xFFE0003F, .MSA, {}} },
    .FMIN_W = { {.FMIN_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7B00001B, 0xFFE0003F, .MSA, {}} },
    .FMIN_D = { {.FMIN_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7B20001B, 0xFFE0003F, .MSA, {}} },
    .FCEQ_W = { {.FCEQ_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7880001A, 0xFFE0003F, .MSA, {}} },
    .FCEQ_D = { {.FCEQ_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78A0001A, 0xFFE0003F, .MSA, {}} },
    .FCLE_W = { {.FCLE_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7980001A, 0xFFE0003F, .MSA, {}} },
    .FCLE_D = { {.FCLE_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x79A0001A, 0xFFE0003F, .MSA, {}} },
    .FCLT_W = { {.FCLT_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7900001A, 0xFFE0003F, .MSA, {}} },
    .FCLT_D = { {.FCLT_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7920001A, 0xFFE0003F, .MSA, {}} },
    .FCNE_W = { {.FCNE_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78C0001C, 0xFFE0003F, .MSA, {}} },
    .FCNE_D = { {.FCNE_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78E0001C, 0xFFE0003F, .MSA, {}} },
    .DOTP_S_H = { {.DOTP_S_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78200013, 0xFFE0003F, .MSA, {}} },
    .DOTP_S_W = { {.DOTP_S_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78400013, 0xFFE0003F, .MSA, {}} },
    .DOTP_S_D = { {.DOTP_S_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78600013, 0xFFE0003F, .MSA, {}} },
    .DOTP_U_H = { {.DOTP_U_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78A00013, 0xFFE0003F, .MSA, {}} },
    .DOTP_U_W = { {.DOTP_U_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78C00013, 0xFFE0003F, .MSA, {}} },
    .DOTP_U_D = { {.DOTP_U_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78E00013, 0xFFE0003F, .MSA, {}} },
    .BMNZ_V = { {.BMNZ_V, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x7880001E, 0xFFE0003F, .MSA, {}} },
    .BMZ_V = { {.BMZ_V, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78A0001E, 0xFFE0003F, .MSA, {}} },
    .BSEL_V = { {.BSEL_V, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78C0001E, 0xFFE0003F, .MSA, {}} },
    .NLOC_B = { {.NLOC_B, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B08001E, 0xFFFF003F, .MSA, {}} },
    .NLOC_H = { {.NLOC_H, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B09001E, 0xFFFF003F, .MSA, {}} },
    .NLOC_W = { {.NLOC_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B0A001E, 0xFFFF003F, .MSA, {}} },
    .NLOC_D = { {.NLOC_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B0B001E, 0xFFFF003F, .MSA, {}} },
    .NLZC_B = { {.NLZC_B, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B0C001E, 0xFFFF003F, .MSA, {}} },
    .NLZC_H = { {.NLZC_H, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B0D001E, 0xFFFF003F, .MSA, {}} },
    .NLZC_W = { {.NLZC_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B0E001E, 0xFFFF003F, .MSA, {}} },
    .NLZC_D = { {.NLZC_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B0F001E, 0xFFFF003F, .MSA, {}} },
    .PCNT_B = { {.PCNT_B, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B04001E, 0xFFFF003F, .MSA, {}} },
    .PCNT_H = { {.PCNT_H, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B05001E, 0xFFFF003F, .MSA, {}} },
    .PCNT_W = { {.PCNT_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B06001E, 0xFFFF003F, .MSA, {}} },
    .PCNT_D = { {.PCNT_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B07001E, 0xFFFF003F, .MSA, {}} },
    .FSQRT_W = { {.FSQRT_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B26001E, 0xFFFF003F, .MSA, {}} },
    .FSQRT_D = { {.FSQRT_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B27001E, 0xFFFF003F, .MSA, {}} },
    .FRSQRT_W = { {.FRSQRT_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B28001E, 0xFFFF003F, .MSA, {}} },
    .FRSQRT_D = { {.FRSQRT_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B29001E, 0xFFFF003F, .MSA, {}} },
    .FRCP_W = { {.FRCP_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B2A001E, 0xFFFF003F, .MSA, {}} },
    .FRCP_D = { {.FRCP_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B2B001E, 0xFFFF003F, .MSA, {}} },
    .FRINT_W = { {.FRINT_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B2C001E, 0xFFFF003F, .MSA, {}} },
    .FRINT_D = { {.FRINT_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B2D001E, 0xFFFF003F, .MSA, {}} },
    .FTRUNC_S_W = { {.FTRUNC_S_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B22001E, 0xFFFF003F, .MSA, {}} },
    .FTRUNC_S_D = { {.FTRUNC_S_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B23001E, 0xFFFF003F, .MSA, {}} },
    .FTRUNC_U_W = { {.FTRUNC_U_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B24001E, 0xFFFF003F, .MSA, {}} },
    .FTRUNC_U_D = { {.FTRUNC_U_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B25001E, 0xFFFF003F, .MSA, {}} },
    .FFINT_S_W = { {.FFINT_S_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B3C001E, 0xFFFF003F, .MSA, {}} },
    .FFINT_S_D = { {.FFINT_S_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B3D001E, 0xFFFF003F, .MSA, {}} },
    .FFINT_U_W = { {.FFINT_U_W, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B3E001E, 0xFFFF003F, .MSA, {}} },
    .FFINT_U_D = { {.FFINT_U_D, {.MSA_VEC,.MSA_VEC,.NONE,.NONE}, {.WD,.WS,.NONE,.NONE}, 0x7B3F001E, 0xFFFF003F, .MSA, {}} },
    .SLLI_B = { {.SLLI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x78700009, 0xFFF8003F, .MSA, {}} },
    .SLLI_H = { {.SLLI_H, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x78600009, 0xFFF0003F, .MSA, {}} },
    .SLLI_W = { {.SLLI_W, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x78400009, 0xFFE0003F, .MSA, {}} },
    .SLLI_D = { {.SLLI_D, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x78000009, 0xFFC0003F, .MSA, {}} },
    .SRAI_B = { {.SRAI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x78F00009, 0xFFF8003F, .MSA, {}} },
    .SRAI_H = { {.SRAI_H, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x78E00009, 0xFFF0003F, .MSA, {}} },
    .SRAI_W = { {.SRAI_W, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x78C00009, 0xFFE0003F, .MSA, {}} },
    .SRAI_D = { {.SRAI_D, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x78800009, 0xFFC0003F, .MSA, {}} },
    .SRLI_B = { {.SRLI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x79700009, 0xFFF8003F, .MSA, {}} },
    .SRLI_H = { {.SRLI_H, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x79600009, 0xFFF0003F, .MSA, {}} },
    .SRLI_W = { {.SRLI_W, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x79400009, 0xFFE0003F, .MSA, {}} },
    .SRLI_D = { {.SRLI_D, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_BIT_SHIFT,.NONE}, 0x79000009, 0xFFC0003F, .MSA, {}} },
    .SPLATI_B = { {.SPLATI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x78400019, 0xFFF0003F, .MSA, {}} },
    .SPLATI_H = { {.SPLATI_H, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x78600019, 0xFFF8003F, .MSA, {}} },
    .SPLATI_W = { {.SPLATI_W, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x78700019, 0xFFFC003F, .MSA, {}} },
    .SPLATI_D = { {.SPLATI_D, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x78780019, 0xFFFE003F, .MSA, {}} },
    .SLDI_B = { {.SLDI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x78000019, 0xFFF0003F, .MSA, {}} },
    .SLDI_H = { {.SLDI_H, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x78200019, 0xFFF8003F, .MSA, {}} },
    .SLDI_W = { {.SLDI_W, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x78300019, 0xFFFC003F, .MSA, {}} },
    .SLDI_D = { {.SLDI_D, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x78380019, 0xFFFE003F, .MSA, {}} },
    .VSHF_B = { {.VSHF_B, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78000015, 0xFFE0003F, .MSA, {}} },
    .VSHF_H = { {.VSHF_H, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78200015, 0xFFE0003F, .MSA, {}} },
    .VSHF_W = { {.VSHF_W, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78400015, 0xFFE0003F, .MSA, {}} },
    .VSHF_D = { {.VSHF_D, {.MSA_VEC,.MSA_VEC,.MSA_VEC,.NONE}, {.WD,.WS,.WT,.NONE}, 0x78600015, 0xFFE0003F, .MSA, {}} },
    .SPLAT_B = { {.SPLAT_B, {.MSA_VEC,.MSA_VEC,.GPR,.NONE}, {.WD,.WS,.RT,.NONE}, 0x78800014, 0xFFE0003F, .MSA, {}} },
    .SPLAT_H = { {.SPLAT_H, {.MSA_VEC,.MSA_VEC,.GPR,.NONE}, {.WD,.WS,.RT,.NONE}, 0x78A00014, 0xFFE0003F, .MSA, {}} },
    .SPLAT_W = { {.SPLAT_W, {.MSA_VEC,.MSA_VEC,.GPR,.NONE}, {.WD,.WS,.RT,.NONE}, 0x78C00014, 0xFFE0003F, .MSA, {}} },
    .SPLAT_D = { {.SPLAT_D, {.MSA_VEC,.MSA_VEC,.GPR,.NONE}, {.WD,.WS,.RT,.NONE}, 0x78E00014, 0xFFE0003F, .MSA, {}} },
    .SLD_B = { {.SLD_B, {.MSA_VEC,.MSA_VEC,.GPR,.NONE}, {.WD,.WS,.RT,.NONE}, 0x78000014, 0xFFE0003F, .MSA, {}} },
    .SLD_H = { {.SLD_H, {.MSA_VEC,.MSA_VEC,.GPR,.NONE}, {.WD,.WS,.RT,.NONE}, 0x78200014, 0xFFE0003F, .MSA, {}} },
    .SLD_W = { {.SLD_W, {.MSA_VEC,.MSA_VEC,.GPR,.NONE}, {.WD,.WS,.RT,.NONE}, 0x78400014, 0xFFE0003F, .MSA, {}} },
    .SLD_D = { {.SLD_D, {.MSA_VEC,.MSA_VEC,.GPR,.NONE}, {.WD,.WS,.RT,.NONE}, 0x78600014, 0xFFE0003F, .MSA, {}} },
    .ANDI_B = { {.ANDI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x78000000, 0xFF00003F, .MSA, {}} },
    .ORI_B = { {.ORI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x79000000, 0xFF00003F, .MSA, {}} },
    .XORI_B = { {.XORI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x7B000000, 0xFF00003F, .MSA, {}} },
    .NORI_B = { {.NORI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x7A000000, 0xFF00003F, .MSA, {}} },
    .BMNZI_B = { {.BMNZI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x78000001, 0xFF00003F, .MSA, {}} },
    .BMZI_B = { {.BMZI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x79000001, 0xFF00003F, .MSA, {}} },
    .BSELI_B = { {.BSELI_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x7A000001, 0xFF00003F, .MSA, {}} },
    .SHF_B = { {.SHF_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x78000002, 0xFF00003F, .MSA, {}} },
    .SHF_H = { {.SHF_H, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x79000002, 0xFF00003F, .MSA, {}} },
    .SHF_W = { {.SHF_W, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_I8,.NONE}, 0x7A000002, 0xFF00003F, .MSA, {}} },
    .INSVE_B = { {.INSVE_B, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x79400019, 0xFFF0003F, .MSA, {}} },
    .INSVE_H = { {.INSVE_H, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x79600019, 0xFFF8003F, .MSA, {}} },
    .INSVE_W = { {.INSVE_W, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x79700019, 0xFFFC003F, .MSA, {}} },
    .INSVE_D = { {.INSVE_D, {.MSA_VEC,.MSA_VEC,.IMM5,.NONE}, {.WD,.WS,.MSA_ELM_IDX,.NONE}, 0x79780019, 0xFFFE003F, .MSA, {}} },
    .ADDU_PH = { {.ADDU_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000210, 0xFC0007FF, .DSP_R2, {}} },
    .ADDU_S_PH = { {.ADDU_S_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000310, 0xFC0007FF, .DSP_R2, {}} },
    .SUBU_PH = { {.SUBU_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000250, 0xFC0007FF, .DSP_R2, {}} },
    .SUBU_S_PH = { {.SUBU_S_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000350, 0xFC0007FF, .DSP_R2, {}} },
    .MULEQ_S_W_PHL = { {.MULEQ_S_W_PHL, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000710, 0xFC0007FF, .DSP_R2, {}} },
    .MULEQ_S_W_PHR = { {.MULEQ_S_W_PHR, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000750, 0xFC0007FF, .DSP_R2, {}} },
    .MULEU_S_PH_QBL = { {.MULEU_S_PH_QBL, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000190, 0xFC0007FF, .DSP_R2, {}} },
    .MULEU_S_PH_QBR = { {.MULEU_S_PH_QBR, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0001D0, 0xFC0007FF, .DSP_R2, {}} },
    .MULQ_RS_PH = { {.MULQ_RS_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0007D0, 0xFC0007FF, .DSP_R2, {}} },
    .MULQ_S_PH = { {.MULQ_S_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000790, 0xFC0007FF, .DSP_R2, {}} },
    .PRECRQ_PH_W = { {.PRECRQ_PH_W, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000511, 0xFC0007FF, .DSP_R2, {}} },
    .PRECRQ_QB_PH = { {.PRECRQ_QB_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000311, 0xFC0007FF, .DSP_R2, {}} },
    .PRECRQ_RS_PH_W = { {.PRECRQ_RS_PH_W, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000551, 0xFC0007FF, .DSP_R2, {}} },
    .PRECRQU_S_QB_PH = { {.PRECRQU_S_QB_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0003D1, 0xFC0007FF, .DSP_R2, {}} },
    .PICK_PH = { {.PICK_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0002D1, 0xFC0007FF, .DSP_R2, {}} },
    .PICK_QB = { {.PICK_QB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C0000D1, 0xFC0007FF, .DSP_R2, {}} },
    .CMPGU_EQ_QB = { {.CMPGU_EQ_QB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000111, 0xFC0007FF, .DSP_R2, {}} },
    .CMPGU_LE_QB = { {.CMPGU_LE_QB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000191, 0xFC0007FF, .DSP_R2, {}} },
    .CMPGU_LT_QB = { {.CMPGU_LT_QB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS,.RT,.NONE}, 0x7C000151, 0xFC0007FF, .DSP_R2, {}} },
    .SHLLV_PH = { {.SHLLV_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C000293, 0xFC0007FF, .DSP_R2, {}} },
    .SHLLV_S_PH = { {.SHLLV_S_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C000393, 0xFC0007FF, .DSP_R2, {}} },
    .SHLLV_S_W = { {.SHLLV_S_W, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C000593, 0xFC0007FF, .DSP_R2, {}} },
    .SHRAV_PH = { {.SHRAV_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C0002D3, 0xFC0007FF, .DSP_R2, {}} },
    .SHRAV_QB = { {.SHRAV_QB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C000193, 0xFC0007FF, .DSP_R2, {}} },
    .SHRAV_R_PH = { {.SHRAV_R_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C0003D3, 0xFC0007FF, .DSP_R2, {}} },
    .SHRAV_R_QB = { {.SHRAV_R_QB, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C0001D3, 0xFC0007FF, .DSP_R2, {}} },
    .SHRAV_R_W = { {.SHRAV_R_W, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C0005D3, 0xFC0007FF, .DSP_R2, {}} },
    .SHRLV_PH = { {.SHRLV_PH, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RT,.RS,.NONE}, 0x7C0006D3, 0xFC0007FF, .DSP_R2, {}} },
    .CMP_EQ_PH = { {.CMP_EQ_PH, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x7C000211, 0xFC00FFFF, .DSP_R2, {}} },
    .CMP_LE_PH = { {.CMP_LE_PH, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x7C000291, 0xFC00FFFF, .DSP_R2, {}} },
    .CMP_LT_PH = { {.CMP_LT_PH, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x7C000251, 0xFC00FFFF, .DSP_R2, {}} },
    .CMPU_EQ_QB = { {.CMPU_EQ_QB, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x7C000011, 0xFC00FFFF, .DSP_R2, {}} },
    .CMPU_LE_QB = { {.CMPU_LE_QB, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x7C000091, 0xFC00FFFF, .DSP_R2, {}} },
    .CMPU_LT_QB = { {.CMPU_LT_QB, {.GPR,.GPR,.NONE,.NONE}, {.RS,.RT,.NONE,.NONE}, 0x7C000051, 0xFC00FFFF, .DSP_R2, {}} },
    .MOVN_S = { {.MOVN_S, {.FPR_S,.FPR_S,.GPR,.NONE}, {.FD,.FS,.RT,.NONE}, 0x46000013, 0xFFE0003F, .FPU, {}} },
    .MOVN_D = { {.MOVN_D, {.FPR_D,.FPR_D,.GPR,.NONE}, {.FD,.FS,.RT,.NONE}, 0x46200013, 0xFFE0003F, .FPU, {}} },
    .MOVZ_S = { {.MOVZ_S, {.FPR_S,.FPR_S,.GPR,.NONE}, {.FD,.FS,.RT,.NONE}, 0x46000012, 0xFFE0003F, .FPU, {}} },
    .MOVZ_D = { {.MOVZ_D, {.FPR_D,.FPR_D,.GPR,.NONE}, {.FD,.FS,.RT,.NONE}, 0x46200012, 0xFFE0003F, .FPU, {}} },
    .MOVF_S = { {.MOVF_S, {.FPR_S,.FPR_S,.FCC,.NONE}, {.FD,.FS,.FCC_BC,.NONE}, 0x46000011, 0xFFE3003F, .FPU, {}} },
    .MOVF_D = { {.MOVF_D, {.FPR_D,.FPR_D,.FCC,.NONE}, {.FD,.FS,.FCC_BC,.NONE}, 0x46200011, 0xFFE3003F, .FPU, {}} },
    .MOVT_S = { {.MOVT_S, {.FPR_S,.FPR_S,.FCC,.NONE}, {.FD,.FS,.FCC_BC,.NONE}, 0x46010011, 0xFFE3003F, .FPU, {}} },
    .MOVT_D = { {.MOVT_D, {.FPR_D,.FPR_D,.FCC,.NONE}, {.FD,.FS,.FCC_BC,.NONE}, 0x46210011, 0xFFE3003F, .FPU, {}} },
    .FCVT_D_W = { {.FCVT_D_W, {.FPR_D,.FPR_W,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46800021, 0xFFFF003F, .FPU, {}} },
    .FCVT_S_D = { {.FCVT_S_D, {.FPR_S,.FPR_D,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46200020, 0xFFFF003F, .FPU, {}} },
    .FCVT_S_W = { {.FCVT_S_W, {.FPR_S,.FPR_W,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46800020, 0xFFFF003F, .FPU, {}} },
    .PRECEQU_PH_QBLA = { {.PRECEQU_PH_QBLA, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000192, 0xFFE007FF, .DSP_R2, {}} },
    .PRECEQU_PH_QBRA = { {.PRECEQU_PH_QBRA, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C0001D2, 0xFFE007FF, .DSP_R2, {}} },
    .PRECEU_PH_QBLA = { {.PRECEU_PH_QBLA, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C000792, 0xFFE007FF, .DSP_R2, {}} },
    .PRECEU_PH_QBRA = { {.PRECEU_PH_QBRA, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C0007D2, 0xFFE007FF, .DSP_R2, {}} },
    .REPLV_PH = { {.REPLV_PH, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C0002D2, 0xFFE007FF, .DSP_R2, {}} },
    .REPLV_QB = { {.REPLV_QB, {.GPR,.GPR,.NONE,.NONE}, {.RD,.RT,.NONE,.NONE}, 0x7C0000D2, 0xFFE007FF, .DSP_R2, {}} },
    .MADD_S = { {.MADD_S, {.FPR_S,.FPR_S,.FPR_S,.FPR_S}, {.FD,.FR,.FS,.FT}, 0x4C000020, 0xFC00003F, .FPU, {}} },
    .MADD_D = { {.MADD_D, {.FPR_D,.FPR_D,.FPR_D,.FPR_D}, {.FD,.FR,.FS,.FT}, 0x4C000021, 0xFC00003F, .FPU, {}} },
    .MSUB_S = { {.MSUB_S, {.FPR_S,.FPR_S,.FPR_S,.FPR_S}, {.FD,.FR,.FS,.FT}, 0x4C000028, 0xFC00003F, .FPU, {}} },
    .MSUB_D = { {.MSUB_D, {.FPR_D,.FPR_D,.FPR_D,.FPR_D}, {.FD,.FR,.FS,.FT}, 0x4C000029, 0xFC00003F, .FPU, {}} },
    .NMADD_S = { {.NMADD_S, {.FPR_S,.FPR_S,.FPR_S,.FPR_S}, {.FD,.FR,.FS,.FT}, 0x4C000030, 0xFC00003F, .FPU, {}} },
    .NMADD_D = { {.NMADD_D, {.FPR_D,.FPR_D,.FPR_D,.FPR_D}, {.FD,.FR,.FS,.FT}, 0x4C000031, 0xFC00003F, .FPU, {}} },
    .NMSUB_S = { {.NMSUB_S, {.FPR_S,.FPR_S,.FPR_S,.FPR_S}, {.FD,.FR,.FS,.FT}, 0x4C000038, 0xFC00003F, .FPU, {}} },
    .NMSUB_D = { {.NMSUB_D, {.FPR_D,.FPR_D,.FPR_D,.FPR_D}, {.FD,.FR,.FS,.FT}, 0x4C000039, 0xFC00003F, .FPU, {}} },
    .COPY_S_B = { {.COPY_S_B, {.GPR,.MSA_VEC,.IMM5,.NONE}, {.GPR_AT_6,.WS,.MSA_ELM_IDX,.NONE}, 0x78800019, 0xFFF0003F, .MSA, {}} },
    .COPY_S_H = { {.COPY_S_H, {.GPR,.MSA_VEC,.IMM5,.NONE}, {.GPR_AT_6,.WS,.MSA_ELM_IDX,.NONE}, 0x78A00019, 0xFFF8003F, .MSA, {}} },
    .COPY_S_W = { {.COPY_S_W, {.GPR,.MSA_VEC,.IMM5,.NONE}, {.GPR_AT_6,.WS,.MSA_ELM_IDX,.NONE}, 0x78B00019, 0xFFFC003F, .MSA, {}} },
    .COPY_U_B = { {.COPY_U_B, {.GPR,.MSA_VEC,.IMM5,.NONE}, {.GPR_AT_6,.WS,.MSA_ELM_IDX,.NONE}, 0x78C00019, 0xFFF0003F, .MSA, {}} },
    .COPY_U_H = { {.COPY_U_H, {.GPR,.MSA_VEC,.IMM5,.NONE}, {.GPR_AT_6,.WS,.MSA_ELM_IDX,.NONE}, 0x78E00019, 0xFFF8003F, .MSA, {}} },
    .INSERT_B = { {.INSERT_B, {.MSA_VEC,.GPR,.IMM5,.NONE}, {.WD,.GPR_AT_11,.MSA_ELM_IDX,.NONE}, 0x79000019, 0xFFF0003F, .MSA, {}} },
    .INSERT_H = { {.INSERT_H, {.MSA_VEC,.GPR,.IMM5,.NONE}, {.WD,.GPR_AT_11,.MSA_ELM_IDX,.NONE}, 0x79200019, 0xFFF8003F, .MSA, {}} },
    .INSERT_W = { {.INSERT_W, {.MSA_VEC,.GPR,.IMM5,.NONE}, {.WD,.GPR_AT_11,.MSA_ELM_IDX,.NONE}, 0x79300019, 0xFFFC003F, .MSA, {}} },
    .DI = { {.DI, {.GPR,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0x41606000, 0xFFE0FFFF, .MIPS32_R2, {}} },
    .EI = { {.EI, {.GPR,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0x41606020, 0xFFE0FFFF, .MIPS32_R2, {}} },
    .RDHWR = { {.RDHWR, {.GPR,.GPR,.NONE,.NONE}, {.RT,.RD,.NONE,.NONE}, 0x7C00003B, 0xFFE007FF, .MIPS32_R2, {}} },
    .SHRA_QB = { {.SHRA_QB, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.DSP_SA,.NONE}, 0x7C000113, 0xFF0007FF, .DSP_R2, {}} },
    .SHRA_R_QB = { {.SHRA_R_QB, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.DSP_SA,.NONE}, 0x7C000153, 0xFF0007FF, .DSP_R2, {}} },
    .SHRA_R_PH = { {.SHRA_R_PH, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.DSP_SA,.NONE}, 0x7C000353, 0xFE0007FF, .DSP_R2, {}} },
    .SHRL_PH = { {.SHRL_PH, {.GPR,.GPR,.IMM5,.NONE}, {.RD,.RT,.DSP_SA,.NONE}, 0x7C000653, 0xFE0007FF, .DSP_R2, {}} },
    .DPA_W_PH = { {.DPA_W_PH, {.IMM5,.GPR,.GPR,.NONE}, {.AC_NUM,.RS,.RT,.NONE}, 0x7C000030, 0xFC00E7FF, .DSP_R2, {}} },
    .DPAX_W_PH = { {.DPAX_W_PH, {.IMM5,.GPR,.GPR,.NONE}, {.AC_NUM,.RS,.RT,.NONE}, 0x7C000230, 0xFC00E7FF, .DSP_R2, {}} },
    .DPS_W_PH = { {.DPS_W_PH, {.IMM5,.GPR,.GPR,.NONE}, {.AC_NUM,.RS,.RT,.NONE}, 0x7C000070, 0xFC00E7FF, .DSP_R2, {}} },
    .DPSX_W_PH = { {.DPSX_W_PH, {.IMM5,.GPR,.GPR,.NONE}, {.AC_NUM,.RS,.RT,.NONE}, 0x7C000270, 0xFC00E7FF, .DSP_R2, {}} },
    .MAQ_S_W_PHL = { {.MAQ_S_W_PHL, {.IMM5,.GPR,.GPR,.NONE}, {.AC_NUM,.RS,.RT,.NONE}, 0x7C000530, 0xFC00E7FF, .DSP_R2, {}} },
    .MAQ_S_W_PHR = { {.MAQ_S_W_PHR, {.IMM5,.GPR,.GPR,.NONE}, {.AC_NUM,.RS,.RT,.NONE}, 0x7C0005B0, 0xFC00E7FF, .DSP_R2, {}} },
    .MAQ_SA_W_PHL = { {.MAQ_SA_W_PHL, {.IMM5,.GPR,.GPR,.NONE}, {.AC_NUM,.RS,.RT,.NONE}, 0x7C000430, 0xFC00E7FF, .DSP_R2, {}} },
    .MAQ_SA_W_PHR = { {.MAQ_SA_W_PHR, {.IMM5,.GPR,.GPR,.NONE}, {.AC_NUM,.RS,.RT,.NONE}, 0x7C0004B0, 0xFC00E7FF, .DSP_R2, {}} },
    .MTHLIP = { {.MTHLIP, {.GPR,.IMM5,.NONE,.NONE}, {.RS,.AC_NUM,.NONE,.NONE}, 0x7C0007F8, 0xFC1FE7FF, .DSP_R2, {}} },
    .SHILOV = { {.SHILOV, {.IMM5,.GPR,.NONE,.NONE}, {.AC_NUM,.RS,.NONE,.NONE}, 0x7C0006F8, 0xFC1FE7FF, .DSP_R2, {}} },
    .SHILO = { {.SHILO, {.IMM5,.IMM5,.NONE,.NONE}, {.AC_NUM,.SHILO_IMM,.NONE,.NONE}, 0x7C0006B8, 0xFC0FE7FF, .DSP_R2, {}} },
    .CVT_PS_S = { {.CVT_PS_S, {.FPR_PS,.FPR_S,.FPR_S,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46000026, 0xFFE0003F, .FPU, {}} },
    .CVT_S_PL = { {.CVT_S_PL, {.FPR_S,.FPR_PS,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46C00028, 0xFFFF003F, .FPU, {}} },
    .CVT_S_PU = { {.CVT_S_PU, {.FPR_S,.FPR_PS,.NONE,.NONE}, {.FD,.FS,.NONE,.NONE}, 0x46C00020, 0xFFFF003F, .FPU, {}} },
    .PLL_PS = { {.PLL_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46C0002C, 0xFFE0003F, .FPU, {}} },
    .PLU_PS = { {.PLU_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46C0002D, 0xFFE0003F, .FPU, {}} },
    .PUL_PS = { {.PUL_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46C0002E, 0xFFE0003F, .FPU, {}} },
    .PUU_PS = { {.PUU_PS, {.FPR_PS,.FPR_PS,.FPR_PS,.NONE}, {.FD,.FS,.FT,.NONE}, 0x46C0002F, 0xFFE0003F, .FPU, {}} },
    .INSERT_D = { {.INSERT_D, {.MSA_VEC,.GPR,.IMM5,.NONE}, {.WD,.GPR_AT_11,.MSA_ELM_IDX,.NONE}, 0x79380019, 0xFFFE003F, .MSA, {}} },
    .COPY_U_W = { {.COPY_U_W, {.GPR,.MSA_VEC,.IMM5,.NONE}, {.GPR_AT_6,.WS,.MSA_ELM_IDX,.NONE}, 0x78F00019, 0xFFFC003F, .MSA, {}} },
    .REPL_PH = { {.REPL_PH, {.GPR,.IMM5,.NONE,.NONE}, {.RD,.MSA_S10,.NONE,.NONE}, 0x7C000292, 0xFC0007FF, .DSP_R1, {}} },
    .REPL_QB = { {.REPL_QB, {.GPR,.IMM5,.NONE,.NONE}, {.RD,.MSA_I8,.NONE,.NONE}, 0x7C000092, 0xFF0007FF, .DSP_R1, {}} },
    .EXTPDP = { {.EXTPDP, {.GPR,.IMM5,.IMM5,.NONE}, {.RT,.AC_NUM,.EXT_SIZE,.NONE}, 0x7C0002B8, 0xFC00E7FF, .DSP_R2, {}} },
    .EXTPDPV = { {.EXTPDPV, {.GPR,.IMM5,.GPR,.NONE}, {.RT,.AC_NUM,.RS,.NONE}, 0x7C0002F8, 0xFC00E7FF, .DSP_R2, {}} },
    .EXTRV_R_W = { {.EXTRV_R_W, {.GPR,.IMM5,.GPR,.NONE}, {.RT,.AC_NUM,.RS,.NONE}, 0x7C000178, 0xFC00E7FF, .DSP_R2, {}} },
    .EXTRV_RS_W = { {.EXTRV_RS_W, {.GPR,.IMM5,.GPR,.NONE}, {.RT,.AC_NUM,.RS,.NONE}, 0x7C0001F8, 0xFC00E7FF, .DSP_R2, {}} },
    .EXTRV_S_H = { {.EXTRV_S_H, {.GPR,.IMM5,.GPR,.NONE}, {.RT,.AC_NUM,.RS,.NONE}, 0x7C0003F8, 0xFC00E7FF, .DSP_R2, {}} },
    .BZ_B = { {.BZ_B, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x47000000, 0xFFE00000, .MSA, {}} },
    .BZ_H = { {.BZ_H, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x47200000, 0xFFE00000, .MSA, {}} },
    .BZ_W = { {.BZ_W, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x47400000, 0xFFE00000, .MSA, {}} },
    .BZ_D = { {.BZ_D, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x47600000, 0xFFE00000, .MSA, {}} },
    .BZ_V = { {.BZ_V, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x45600000, 0xFFE00000, .MSA, {}} },
    .BNZ_B = { {.BNZ_B, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x47800000, 0xFFE00000, .MSA, {}} },
    .BNZ_H = { {.BNZ_H, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x47A00000, 0xFFE00000, .MSA, {}} },
    .BNZ_W = { {.BNZ_W, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x47C00000, 0xFFE00000, .MSA, {}} },
    .BNZ_D = { {.BNZ_D, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x47E00000, 0xFFE00000, .MSA, {}} },
    .BNZ_V = { {.BNZ_V, {.MSA_VEC,.REL16,.NONE,.NONE}, {.WT,.BRANCH_16,.NONE,.NONE}, 0x45E00000, 0xFFE00000, .MSA, {}} },
    .LWPC = { {.LWPC, {.GPR,.REL19,.NONE,.NONE}, {.RS,.BRANCH_19,.NONE,.NONE}, 0xEC080000, 0xFC180000, .MIPS32_R6, {}} },
    .LWUPC = { {.LWUPC, {.GPR,.REL19,.NONE,.NONE}, {.RS,.BRANCH_19,.NONE,.NONE}, 0xEC100000, 0xFC180000, .MIPS64_R6, {}} },
    .LDPC = { {.LDPC, {.GPR,.REL18,.NONE,.NONE}, {.RS,.BRANCH_18,.NONE,.NONE}, 0xEC180000, 0xFC1C0000, .MIPS64_R6, {}} },
    // SPECGEN:END
}
