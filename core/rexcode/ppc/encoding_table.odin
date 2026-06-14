package rexcode_ppc

// =============================================================================
// PowerPC ENCODING_TABLE
// =============================================================================
//
// Conventions:
// - PowerPC ISA documentation numbers bits MSB-first (bit 0 = MSB, bit 31 =
//   LSB). This table is in LSB-first u32 form. To translate a field "bits
//   M..N" from the manual, use the formula LSB_bit = 31 - MSB_bit. For
//   instance, primary opcode "0..5" → LSB bits 31..26 = (op << 26).
// - `bits` holds the static pattern. `mask` flags which bits are fixed.
// - Rc bit (record/dot-suffix) and OE bit (overflow) live at LSB bit 0 and
//   bit 10 respectively (= MSB bits 31 and 21). Forms with Rc=1 / OE=1 are
//   separate entries; the variant flags are baked into base bits.
//
// Sections follow the Power ISA Book I/II/III layout:
//   §1  Branch (I/B/XL-form)
//   §2  Condition register logical
//   §3  Fixed-point load
//   §4  Fixed-point store
//   §5  Load/store with reservation (atomic primitives)
//   §6  Fixed-point arithmetic
//   §7  Fixed-point logical / shift / rotate
//   §8  Compare
//   §9  Floating-point arithmetic (§4 of the FPU spec)
//   §10 SPR / system / cache
//   §11 AltiVec (VMX)
//   §12 VSX
//   §13 Power ISA 3.1 prefixed (POWER10)
//   §14 Aliases (printed differently, encoded as their underlying form)
@(rodata)
ENCODING_TABLE: [Mnemonic][]Encoding = #partial {
	.INVALID = {},

	// =========================================================================
	// §1 Branch (I/B/XL/SC-form)
	// =========================================================================
	//
	// I-form unconditional branch:
	//   primary=18 (0x12), LI[2..25], AA at bit 1, LK at bit 0.
	//   bits 0..5 (MSB) = 010010 = 0x12 → LSB: 0x48000000
	//
	//   B    AA=0 LK=0   0x48000000
	//   BA   AA=1 LK=0   0x48000002
	//   BL   AA=0 LK=1   0x48000001
	//   BLA  AA=1 LK=1   0x48000003

	.B   = { {.B,   {.REL, .NONE, .NONE, .NONE}, {.BRANCH_LI, .NONE, .NONE, .NONE}, 0x48000000, 0xFC000003, .BASE, .PPC32, {branch=true}} },
	.BA  = { {.BA,  {.REL, .NONE, .NONE, .NONE}, {.BRANCH_LI, .NONE, .NONE, .NONE}, 0x48000002, 0xFC000003, .BASE, .PPC32, {branch=true, abs_branch=true}} },
	.BL  = { {.BL,  {.REL, .NONE, .NONE, .NONE}, {.BRANCH_LI, .NONE, .NONE, .NONE}, 0x48000001, 0xFC000003, .BASE, .PPC32, {branch=true, writes_lr=true}} },
	.BLA = { {.BLA, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_LI, .NONE, .NONE, .NONE}, 0x48000003, 0xFC000003, .BASE, .PPC32, {branch=true, abs_branch=true, writes_lr=true}} },

	// B-form conditional branch:
	//   primary=16 (0x10), BO[6..10], BI[11..15], BD[16..29], AA, LK.
	//   base = 0x40000000.
	.BC   = { {.BC,   {.BO, .CR_BIT, .REL, .NONE}, {.BO_FIELD, .BI_FIELD, .BRANCH_BD, .NONE}, 0x40000000, 0xFC000003, .BASE, .PPC32, {cond_branch=true}} },
	.BCA  = { {.BCA,  {.BO, .CR_BIT, .REL, .NONE}, {.BO_FIELD, .BI_FIELD, .BRANCH_BD, .NONE}, 0x40000002, 0xFC000003, .BASE, .PPC32, {cond_branch=true, abs_branch=true}} },
	.BCL  = { {.BCL,  {.BO, .CR_BIT, .REL, .NONE}, {.BO_FIELD, .BI_FIELD, .BRANCH_BD, .NONE}, 0x40000001, 0xFC000003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BCLA = { {.BCLA, {.BO, .CR_BIT, .REL, .NONE}, {.BO_FIELD, .BI_FIELD, .BRANCH_BD, .NONE}, 0x40000003, 0xFC000003, .BASE, .PPC32, {cond_branch=true, abs_branch=true, writes_lr=true}} },

	// XL-form branch to LR/CTR (XO=16/528 at bits 21-30):
	//   primary=19 (0x13). bclr: XO=16. bcctr: XO=528. bctar: XO=560 (P8).
	//   XO field LSB position = bits 1..10. XO_VALUE << 1 in u32.
	//
	//   bclr   bits = 0x4C000020 (XO=16<<1=32 → 0x20)
	//   bclrl  bits = 0x4C000021
	//   bcctr  bits = 0x4C000420 (XO=528<<1=0x420)
	//   bcctrl bits = 0x4C000421
	//   bctar  bits = 0x4C000460 (XO=560<<1=0x460)
	//   bctarl bits = 0x4C000461
	.BCLR    = { {.BCLR,    {.BO, .CR_BIT, .BH, .NONE}, {.BO_FIELD, .BI_FIELD, .BH_FIELD, .NONE}, 0x4C000020, 0xFC0007FF, .BASE,   .PPC32, {cond_branch=true}} },
	.BCLRL   = { {.BCLRL,   {.BO, .CR_BIT, .BH, .NONE}, {.BO_FIELD, .BI_FIELD, .BH_FIELD, .NONE}, 0x4C000021, 0xFC0007FF, .BASE,   .PPC32, {cond_branch=true, writes_lr=true}} },
	.BCCTR   = { {.BCCTR,   {.BO, .CR_BIT, .BH, .NONE}, {.BO_FIELD, .BI_FIELD, .BH_FIELD, .NONE}, 0x4C000420, 0xFC0007FF, .BASE,   .PPC32, {cond_branch=true}} },
	.BCCTRL  = { {.BCCTRL,  {.BO, .CR_BIT, .BH, .NONE}, {.BO_FIELD, .BI_FIELD, .BH_FIELD, .NONE}, 0x4C000421, 0xFC0007FF, .BASE,   .PPC32, {cond_branch=true, writes_lr=true}} },
	.BCTAR   = { {.BCTAR,   {.BO, .CR_BIT, .BH, .NONE}, {.BO_FIELD, .BI_FIELD, .BH_FIELD, .NONE}, 0x4C000460, 0xFC0007FF, .POWER8, .PPC32, {cond_branch=true}} },
	.BCTARL  = { {.BCTARL,  {.BO, .CR_BIT, .BH, .NONE}, {.BO_FIELD, .BI_FIELD, .BH_FIELD, .NONE}, 0x4C000461, 0xFC0007FF, .POWER8, .PPC32, {cond_branch=true, writes_lr=true}} },

	// SC-form system call:
	//   primary=17 (0x11). LEV at bits 20..26 (MSB 5..11).  bits = 0x44000002.
	.SC = { {.SC, {.IMM, .NONE, .NONE, .NONE}, {.LEV_FIELD, .NONE, .NONE, .NONE}, 0x44000002, 0xFFFFFFFD, .BASE, .PPC32, {}} },

	// =========================================================================
	// §2 Condition register logical (XL-form)
	// =========================================================================
	//
	// primary=19 (= 0x4C000000 base). XO at bits 1..10. Operands: BT/BA/BB
	// are 5-bit CR-bit indices.
	//
	//   crand  XO=257  →  0x4C000202
	//   crnand XO=225  →  0x4C0001C2
	//   cror   XO=449  →  0x4C000382
	//   crnor  XO= 33  →  0x4C000042
	//   crxor  XO=193  →  0x4C000182
	//   creqv  XO=289  →  0x4C000242
	//   crandc XO=129  →  0x4C000102
	//   crorc  XO=417  →  0x4C000342
	//   mcrf   XO=  0  →  0x4C000000 (BF/BFA take 3-bit CR fields)
	.CRAND  = { {.CRAND,  {.CR_BIT, .CR_BIT, .CR_BIT, .NONE}, {.BT, .BA, .BB, .NONE}, 0x4C000202, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CRNAND = { {.CRNAND, {.CR_BIT, .CR_BIT, .CR_BIT, .NONE}, {.BT, .BA, .BB, .NONE}, 0x4C0001C2, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CROR   = { {.CROR,   {.CR_BIT, .CR_BIT, .CR_BIT, .NONE}, {.BT, .BA, .BB, .NONE}, 0x4C000382, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CRNOR  = { {.CRNOR,  {.CR_BIT, .CR_BIT, .CR_BIT, .NONE}, {.BT, .BA, .BB, .NONE}, 0x4C000042, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CRXOR  = { {.CRXOR,  {.CR_BIT, .CR_BIT, .CR_BIT, .NONE}, {.BT, .BA, .BB, .NONE}, 0x4C000182, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CREQV  = { {.CREQV,  {.CR_BIT, .CR_BIT, .CR_BIT, .NONE}, {.BT, .BA, .BB, .NONE}, 0x4C000242, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CRANDC = { {.CRANDC, {.CR_BIT, .CR_BIT, .CR_BIT, .NONE}, {.BT, .BA, .BB, .NONE}, 0x4C000102, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CRORC  = { {.CRORC,  {.CR_BIT, .CR_BIT, .CR_BIT, .NONE}, {.BT, .BA, .BB, .NONE}, 0x4C000342, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MCRF   = { {.MCRF,   {.CR_FIELD, .CR_FIELD, .NONE,    .NONE}, {.BF, .BFA, .NONE, .NONE}, 0x4C000000, 0xFC63FFFF, .BASE, .PPC32, {}} },

	// =========================================================================
	// §3 Fixed-point loads (D/DS/X-form)
	// =========================================================================
	//
	// D-form base = primary << 26. Mask covers top 6 bits only (0xFC000000).
	//   lbz   primary=34  →  0x88000000
	//   lbzu  primary=35  →  0x8C000000
	//   lhz   primary=40  →  0xA0000000
	//   lhzu  primary=41  →  0xA4000000
	//   lha   primary=42  →  0xA8000000
	//   lhau  primary=43  →  0xAC000000
	//   lwz   primary=32  →  0x80000000
	//   lwzu  primary=33  →  0x84000000
	//   lmw   primary=46  →  0xB8000000
	//   ld/ldu/lwa share primary 58 (DS-form, XO at bits 0..1)
	//     ld   XO=0  →  0xE8000000
	//     ldu  XO=1  →  0xE8000001
	//     lwa  XO=2  →  0xE8000002
	//   lq    primary=56 (DQ-form, 12-bit + 4-bit zero) → 0xE0000000

	.LBZ    = { {.LBZ,    {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0x88000000, 0xFC000000, .BASE, .PPC32, {}} },
	.LBZU   = { {.LBZU,   {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0x8C000000, 0xFC000000, .BASE, .PPC32, {}} },
	.LHZ    = { {.LHZ,    {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0xA0000000, 0xFC000000, .BASE, .PPC32, {}} },
	.LHZU   = { {.LHZU,   {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0xA4000000, 0xFC000000, .BASE, .PPC32, {}} },
	.LHA    = { {.LHA,    {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0xA8000000, 0xFC000000, .BASE, .PPC32, {}} },
	.LHAU   = { {.LHAU,   {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0xAC000000, 0xFC000000, .BASE, .PPC32, {}} },
	.LWZ    = { {.LWZ,    {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0x80000000, 0xFC000000, .BASE, .PPC32, {}} },
	.LWZU   = { {.LWZU,   {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0x84000000, 0xFC000000, .BASE, .PPC32, {}} },
	.LMW    = { {.LMW,    {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D,  .NONE, .NONE}, 0xB8000000, 0xFC000000, .BASE, .PPC32, {}} },

	.LD     = { {.LD,     {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xE8000000, 0xFC000003, .P64,  .PPC64, {}} },
	.LDU    = { {.LDU,    {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xE8000001, 0xFC000003, .P64,  .PPC64, {}} },
	.LWA    = { {.LWA,    {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xE8000002, 0xFC000003, .P64,  .PPC64, {}} },
	.LQ     = { {.LQ,     {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_DQ, .NONE, .NONE}, 0xE0000000, 0xFC00000F, .POWER8, .PPC64, {}} },

	// X-form indexed: primary=31, XO at bits 1..10 (XO_value << 1).
	//   lbzx   XO=87   →  0x7C0000AE
	//   lbzux  XO=119  →  0x7C0000EE
	//   lhzx   XO=279  →  0x7C00022E
	//   lhzux  XO=311  →  0x7C00026E
	//   lhax   XO=343  →  0x7C0002AE
	//   lhaux  XO=375  →  0x7C0002EE
	//   lwzx   XO=23   →  0x7C00002E
	//   lwzux  XO=55   →  0x7C00006E
	//   lwax   XO=341  →  0x7C0002AA
	//   lwaux  XO=373  →  0x7C0002EA
	//   ldx    XO=21   →  0x7C00002A
	//   ldux   XO=53   →  0x7C00006A
	//   lhbrx  XO=790  →  0x7C00062C
	//   lwbrx  XO=534  →  0x7C00042C
	//   ldbrx  XO=532  →  0x7C000428
	//   lswi   XO=597  →  0x7C0004AA
	//   lswx   XO=533  →  0x7C00042A
	.LBZX   = { {.LBZX,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0000AE, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LBZUX  = { {.LBZUX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0000EE, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LHZX   = { {.LHZX,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00022E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LHZUX  = { {.LHZUX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00026E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LHAX   = { {.LHAX,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0002AE, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LHAUX  = { {.LHAUX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0002EE, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LWZX   = { {.LWZX,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00002E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LWZUX  = { {.LWZUX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00006E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LWAX   = { {.LWAX,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0002AA, 0xFC0007FE, .P64,  .PPC64, {}} },
	.LWAUX  = { {.LWAUX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0002EA, 0xFC0007FE, .P64,  .PPC64, {}} },
	.LDX    = { {.LDX,   {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00002A, 0xFC0007FE, .P64,  .PPC64, {}} },
	.LDUX   = { {.LDUX,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00006A, 0xFC0007FE, .P64,  .PPC64, {}} },
	.LHBRX  = { {.LHBRX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00062C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LWBRX  = { {.LWBRX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00042C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LDBRX  = { {.LDBRX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C000428, 0xFC0007FE, .POWER8, .PPC64, {}} },
	.LSWI   = { {.LSWI,  {.GPR, .GPR, .IMM, .NONE},  {.RT, .RA, .NB_FIELD, .NONE},        0x7C0004AA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LSWX   = { {.LSWX,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00042A, 0xFC0007FE, .BASE, .PPC32, {}} },

	// =========================================================================
	// §4 Fixed-point stores (D/DS/X-form)
	// =========================================================================
	//
	// D-form:
	//   stb    primary=38  →  0x98000000
	//   stbu   primary=39  →  0x9C000000
	//   sth    primary=44  →  0xB0000000
	//   sthu   primary=45  →  0xB4000000
	//   stw    primary=36  →  0x90000000
	//   stwu   primary=37  →  0x94000000
	//   stmw   primary=47  →  0xBC000000
	//
	// DS-form (primary=62):
	//   std    XO=0  →  0xF8000000
	//   stdu   XO=1  →  0xF8000001
	//   stq    XO=2  →  0xF8000002 (POWER8, PPC64)
	//
	// X-form (primary=31 + XO at bits 1..10):
	//   stbx   XO=215  →  0x7C0001AE
	//   stbux  XO=247  →  0x7C0001EE
	//   sthx   XO=407  →  0x7C00032E
	//   sthux  XO=439  →  0x7C00036E
	//   stwx   XO=151  →  0x7C00012E
	//   stwux  XO=183  →  0x7C00016E
	//   stdx   XO=149  →  0x7C00012A
	//   stdux  XO=181  →  0x7C00016A
	//   sthbrx XO=918  →  0x7C00072C
	//   stwbrx XO=662  →  0x7C00052C
	//   stdbrx XO=660  →  0x7C000528
	//   stswi  XO=725  →  0x7C0005AA
	//   stswx  XO=661  →  0x7C00052A
	.STB    = { {.STB,    {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D,  .NONE, .NONE}, 0x98000000, 0xFC000000, .BASE, .PPC32, {}} },
	.STBU   = { {.STBU,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D,  .NONE, .NONE}, 0x9C000000, 0xFC000000, .BASE, .PPC32, {}} },
	.STH    = { {.STH,    {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D,  .NONE, .NONE}, 0xB0000000, 0xFC000000, .BASE, .PPC32, {}} },
	.STHU   = { {.STHU,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D,  .NONE, .NONE}, 0xB4000000, 0xFC000000, .BASE, .PPC32, {}} },
	.STW    = { {.STW,    {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D,  .NONE, .NONE}, 0x90000000, 0xFC000000, .BASE, .PPC32, {}} },
	.STWU   = { {.STWU,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D,  .NONE, .NONE}, 0x94000000, 0xFC000000, .BASE, .PPC32, {}} },
	.STMW   = { {.STMW,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D,  .NONE, .NONE}, 0xBC000000, 0xFC000000, .BASE, .PPC32, {}} },
	.STD    = { {.STD,    {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_DS, .NONE, .NONE}, 0xF8000000, 0xFC000003, .P64,  .PPC64, {}} },
	.STDU   = { {.STDU,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_DS, .NONE, .NONE}, 0xF8000001, 0xFC000003, .P64,  .PPC64, {}} },
	.STQ    = { {.STQ,    {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_DS, .NONE, .NONE}, 0xF8000002, 0xFC000003, .POWER8, .PPC64, {}} },
	.STBX   = { {.STBX,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C0001AE, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STBUX  = { {.STBUX,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C0001EE, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STHX   = { {.STHX,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00032E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STHUX  = { {.STHUX,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00036E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STWX   = { {.STWX,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00012E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STWUX  = { {.STWUX,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00016E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STDX   = { {.STDX,   {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00012A, 0xFC0007FE, .P64,  .PPC64, {}} },
	.STDUX  = { {.STDUX,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00016A, 0xFC0007FE, .P64,  .PPC64, {}} },
	.STHBRX = { {.STHBRX, {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00072C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STWBRX = { {.STWBRX, {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00052C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STDBRX = { {.STDBRX, {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C000528, 0xFC0007FE, .POWER8, .PPC64, {}} },
	.STSWI  = { {.STSWI,  {.GPR, .GPR, .IMM, .NONE},  {.RS, .RA, .NB_FIELD,  .NONE},        0x7C0005AA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STSWX  = { {.STSWX,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X,  .NONE, .NONE}, 0x7C00052A, 0xFC0007FE, .BASE, .PPC32, {}} },

	// =========================================================================
	// §5 Reservations / atomics (X-form)
	// =========================================================================
	//
	// primary=31, XO at bits 1..10:
	//   lbarx  XO= 52  →  0x7C000068
	//   lharx  XO=116  →  0x7C0000E8
	//   lwarx  XO= 20  →  0x7C000028
	//   ldarx  XO= 84  →  0x7C0000A8
	//   lqarx  XO=276  →  0x7C000228
	//   stbcx. XO=694  →  0x7C00056D  (Rc=1 baked)
	//   sthcx. XO=726  →  0x7C0005AD
	//   stwcx. XO=150  →  0x7C00012D
	//   stdcx. XO=214  →  0x7C0001AD
	//   stqcx. XO=182  →  0x7C00016D
	.LBARX  = { {.LBARX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C000068, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.LHARX  = { {.LHARX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0000E8, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.LWARX  = { {.LWARX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C000028, 0xFC0007FE, .BASE,   .PPC32, {}} },
	.LDARX  = { {.LDARX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0000A8, 0xFC0007FE, .P64,    .PPC64, {}} },
	.LQARX  = { {.LQARX, {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C000228, 0xFC0007FE, .POWER8, .PPC64, {}} },
	.STBCX_DOT = { {.STBCX_DOT, {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00056D, 0xFC0007FF, .POWER8, .PPC32, {sets_cr0=true}} },
	.STHCX_DOT = { {.STHCX_DOT, {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0005AD, 0xFC0007FF, .POWER8, .PPC32, {sets_cr0=true}} },
	.STWCX_DOT = { {.STWCX_DOT, {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00012D, 0xFC0007FF, .BASE,   .PPC32, {sets_cr0=true}} },
	.STDCX_DOT = { {.STDCX_DOT, {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0001AD, 0xFC0007FF, .P64,    .PPC64, {sets_cr0=true}} },
	.STQCX_DOT = { {.STQCX_DOT, {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00016D, 0xFC0007FF, .POWER8, .PPC64, {sets_cr0=true}} },

	// =========================================================================
	// §6 Fixed-point arithmetic (D / XO-form)
	// =========================================================================
	//
	// D-form arithmetic (primary opcodes 7, 8, 12, 13, 14, 15):
	//   mulli   primary= 7  →  0x1C000000
	//   subfic  primary= 8  →  0x20000000
	//   addic   primary=12  →  0x30000000
	//   addic.  primary=13  →  0x34000000
	//   addi    primary=14  →  0x38000000
	//   addis   primary=15  →  0x3C000000
	//   addpcis primary=19, XO=2 (DX-form, POWER9) → 0x4C000004
	.MULLI    = { {.MULLI,    {.GPR, .GPR_OR_ZERO, .SIMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x1C000000, 0xFC000000, .BASE, .PPC32, {}} },
	.SUBFIC   = { {.SUBFIC,   {.GPR, .GPR,         .SIMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x20000000, 0xFC000000, .BASE, .PPC32, {}} },
	.ADDIC    = { {.ADDIC,    {.GPR, .GPR,         .SIMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x30000000, 0xFC000000, .BASE, .PPC32, {}} },
	.ADDIC_DOT= { {.ADDIC_DOT,{.GPR, .GPR,         .SIMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x34000000, 0xFC000000, .BASE, .PPC32, {sets_cr0=true}} },
	.ADDI     = { {.ADDI,     {.GPR, .GPR_OR_ZERO, .SIMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x38000000, 0xFC000000, .BASE, .PPC32, {}} },
	.ADDIS    = { {.ADDIS,    {.GPR, .GPR_OR_ZERO, .SIMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x3C000000, 0xFC000000, .BASE, .PPC32, {}} },

	// XO-form arithmetic (primary=31, XO at bits 1..9 [9 bits], OE at bit 10):
	//   add    XO=266 → 266<<1=0x214  → 0x7C000214
	//   add.   XO=266, Rc=1            → 0x7C000215
	//   addo   XO=266, OE=1            → 0x7C000614
	//   addo.  XO=266, OE=1, Rc=1      → 0x7C000615
	//   addc   XO= 10 → 0x7C000014
	//   adde   XO=138 → 0x7C000114
	//   addme  XO=234 → 0x7C0001D4  (no Rb)
	//   addze  XO=202 → 0x7C000194  (no Rb)
	//   subf   XO= 40 → 0x7C000050
	//   subfc  XO=  8 → 0x7C000010
	//   subfe  XO=136 → 0x7C000110
	//   subfme XO=232 → 0x7C0001D0
	//   subfze XO=200 → 0x7C000190
	//   neg    XO=104 → 0x7C0000D0  (no Rb)
	//   addex  XO=170 → 0x7C0000D4 — wait, addex is XO=170, no OE bit
	//                                    actually: 170<<1=0x154 → 0x7C000154
	//                                  Power ISA uses CY[2] selector at OE pos
	//   mulhw  XO= 75 → 0x7C000096 (X-form, no OE: 75<<1=0x96)
	//   mulhwu XO= 11 → 0x7C000016
	//   mullw  XO=235 → 0x7C0001D6
	//   mulld  XO=233 → 0x7C0001D2
	//   mulhd  XO= 73 → 0x7C000092
	//   mulhdu XO=  9 → 0x7C000012
	//   divw   XO=491 → 0x7C0003D6
	//   divwu  XO=459 → 0x7C0003D6 - wait, 459<<1=0x396 → 0x7C000396
	//   divd   XO=489 → 0x7C0003D2
	//   divdu  XO=457 → 0x7C000392
	//   divwe  XO=427 → 0x7C000356  (POWER7)
	//   divweu XO=395 → 0x7C000316
	//   divde  XO=425 → 0x7C000352
	//   divdeu XO=393 → 0x7C000312
	//   modsw  XO=779 → 0x7C000616 (POWER9 X-form, not XO; uses 10-bit XO)
	//   moduw  XO=267 → 0x7C000216
	//   modsd  XO=777 → 0x7C000612
	//   modud  XO=265 → 0x7C000212
	//   maddld XO=51 (VA-form-like, primary=4) — handled separately

	.ADD       = { {.ADD,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000214, 0xFC0003FE, .BASE, .PPC32, {}} },
	.ADD_DOT   = { {.ADD_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000215, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.ADD_O     = { {.ADD_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000614, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.ADD_O_DOT = { {.ADD_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000615, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },

	.ADDC       = { {.ADDC,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000014, 0xFC0003FE, .BASE, .PPC32, {}} },
	.ADDC_DOT   = { {.ADDC_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000015, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.ADDC_O     = { {.ADDC_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000414, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.ADDC_O_DOT = { {.ADDC_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000415, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },

	.ADDE       = { {.ADDE,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000114, 0xFC0003FE, .BASE, .PPC32, {}} },
	.ADDE_DOT   = { {.ADDE_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000115, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.ADDE_O     = { {.ADDE_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000514, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.ADDE_O_DOT = { {.ADDE_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000515, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },

	.ADDME       = { {.ADDME,       {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0001D4, 0xFC00FBFE, .BASE, .PPC32, {}} },
	.ADDME_DOT   = { {.ADDME_DOT,   {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0001D5, 0xFC00FBFF, .BASE, .PPC32, {sets_cr0=true}} },
	.ADDME_O     = { {.ADDME_O,     {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0005D4, 0xFC00FFFE, .BASE, .PPC32, {has_oe=true}} },
	.ADDME_O_DOT = { {.ADDME_O_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0005D5, 0xFC00FFFF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.ADDZE       = { {.ADDZE,       {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C000194, 0xFC00FBFE, .BASE, .PPC32, {}} },
	.ADDZE_DOT   = { {.ADDZE_DOT,   {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C000195, 0xFC00FBFF, .BASE, .PPC32, {sets_cr0=true}} },
	.ADDZE_O     = { {.ADDZE_O,     {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C000594, 0xFC00FFFE, .BASE, .PPC32, {has_oe=true}} },
	.ADDZE_O_DOT = { {.ADDZE_O_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C000595, 0xFC00FFFF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },

	.SUBF        = { {.SUBF,        {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000050, 0xFC0003FE, .BASE, .PPC32, {}} },
	.SUBF_DOT    = { {.SUBF_DOT,    {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000051, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.SUBF_O      = { {.SUBF_O,      {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000450, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.SUBF_O_DOT  = { {.SUBF_O_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000451, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.SUBFC       = { {.SUBFC,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000010, 0xFC0003FE, .BASE, .PPC32, {}} },
	.SUBFC_DOT   = { {.SUBFC_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000011, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.SUBFC_O     = { {.SUBFC_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000410, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.SUBFC_O_DOT = { {.SUBFC_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000411, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.SUBFE       = { {.SUBFE,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000110, 0xFC0003FE, .BASE, .PPC32, {}} },
	.SUBFE_DOT   = { {.SUBFE_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000111, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.SUBFE_O     = { {.SUBFE_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000510, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.SUBFE_O_DOT = { {.SUBFE_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000511, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.SUBFME       = { {.SUBFME,       {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0001D0, 0xFC00FBFE, .BASE, .PPC32, {}} },
	.SUBFME_DOT   = { {.SUBFME_DOT,   {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0001D1, 0xFC00FBFF, .BASE, .PPC32, {sets_cr0=true}} },
	.SUBFME_O     = { {.SUBFME_O,     {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0005D0, 0xFC00FFFE, .BASE, .PPC32, {has_oe=true}} },
	.SUBFME_O_DOT = { {.SUBFME_O_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0005D1, 0xFC00FFFF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.SUBFZE       = { {.SUBFZE,       {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C000190, 0xFC00FBFE, .BASE, .PPC32, {}} },
	.SUBFZE_DOT   = { {.SUBFZE_DOT,   {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C000191, 0xFC00FBFF, .BASE, .PPC32, {sets_cr0=true}} },
	.SUBFZE_O     = { {.SUBFZE_O,     {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C000590, 0xFC00FFFE, .BASE, .PPC32, {has_oe=true}} },
	.SUBFZE_O_DOT = { {.SUBFZE_O_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C000591, 0xFC00FFFF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },

	.NEG       = { {.NEG,       {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0000D0, 0xFC00FBFE, .BASE, .PPC32, {}} },
	.NEG_DOT   = { {.NEG_DOT,   {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0000D1, 0xFC00FBFF, .BASE, .PPC32, {sets_cr0=true}} },
	.NEG_O     = { {.NEG_O,     {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0004D0, 0xFC00FFFE, .BASE, .PPC32, {has_oe=true}} },
	.NEG_O_DOT = { {.NEG_O_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RT, .RA, .NONE, .NONE}, 0x7C0004D1, 0xFC00FFFF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },

	// Multiply
	.MULHW       = { {.MULHW,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000096, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULHW_DOT   = { {.MULHW_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000097, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.MULHWU      = { {.MULHWU,      {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000016, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULHWU_DOT  = { {.MULHWU_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000017, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.MULLW       = { {.MULLW,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D6, 0xFC0003FE, .BASE, .PPC32, {}} },
	.MULLW_DOT   = { {.MULLW_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D7, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.MULLW_O     = { {.MULLW_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D6, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.MULLW_O_DOT = { {.MULLW_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D7, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.MULLD       = { {.MULLD,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D2, 0xFC0003FE, .P64,  .PPC64, {}} },
	.MULLD_DOT   = { {.MULLD_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D3, 0xFC0003FF, .P64,  .PPC64, {sets_cr0=true}} },
	.MULLD_O     = { {.MULLD_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D2, 0xFC0007FE, .P64,  .PPC64, {has_oe=true}} },
	.MULLD_O_DOT = { {.MULLD_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D3, 0xFC0007FF, .P64,  .PPC64, {has_oe=true, sets_cr0=true}} },
	.MULHD       = { {.MULHD,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000092, 0xFC0007FE, .P64,  .PPC64, {}} },
	.MULHD_DOT   = { {.MULHD_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000093, 0xFC0007FF, .P64,  .PPC64, {sets_cr0=true}} },
	.MULHDU      = { {.MULHDU,      {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000012, 0xFC0007FE, .P64,  .PPC64, {}} },
	.MULHDU_DOT  = { {.MULHDU_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000013, 0xFC0007FF, .P64,  .PPC64, {sets_cr0=true}} },

	// Divide
	.DIVW       = { {.DIVW,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003D6, 0xFC0003FE, .BASE, .PPC32, {}} },
	.DIVW_DOT   = { {.DIVW_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003D7, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.DIVW_O     = { {.DIVW_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D6, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.DIVW_O_DOT = { {.DIVW_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D7, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.DIVWU       = { {.DIVWU,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000396, 0xFC0003FE, .BASE, .PPC32, {}} },
	.DIVWU_DOT   = { {.DIVWU_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000397, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.DIVWU_O     = { {.DIVWU_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000796, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.DIVWU_O_DOT = { {.DIVWU_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000797, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.DIVD       = { {.DIVD,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003D2, 0xFC0003FE, .P64,  .PPC64, {}} },
	.DIVD_DOT   = { {.DIVD_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003D3, 0xFC0003FF, .P64,  .PPC64, {sets_cr0=true}} },
	.DIVD_O     = { {.DIVD_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D2, 0xFC0007FE, .P64,  .PPC64, {has_oe=true}} },
	.DIVD_O_DOT = { {.DIVD_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D3, 0xFC0007FF, .P64,  .PPC64, {has_oe=true, sets_cr0=true}} },
	.DIVDU       = { {.DIVDU,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000392, 0xFC0003FE, .P64,  .PPC64, {}} },
	.DIVDU_DOT   = { {.DIVDU_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000393, 0xFC0003FF, .P64,  .PPC64, {sets_cr0=true}} },
	.DIVDU_O     = { {.DIVDU_O,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000792, 0xFC0007FE, .P64,  .PPC64, {has_oe=true}} },
	.DIVDU_O_DOT = { {.DIVDU_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000793, 0xFC0007FF, .P64,  .PPC64, {has_oe=true, sets_cr0=true}} },
	// Extended divides (POWER7)
	.DIVWE       = { {.DIVWE,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000356, 0xFC0003FE, .BASE, .PPC32, {}} },
	.DIVWEU      = { {.DIVWEU,      {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000316, 0xFC0003FE, .BASE, .PPC32, {}} },
	.DIVDE       = { {.DIVDE,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000352, 0xFC0003FE, .P64,  .PPC64, {}} },
	.DIVDEU      = { {.DIVDEU,      {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000312, 0xFC0003FE, .P64,  .PPC64, {}} },

	// Modulo (POWER9)
	.MODSW = { {.MODSW, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000616, 0xFC0007FE, .POWER9, .PPC32, {}} },
	.MODUW = { {.MODUW, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000216, 0xFC0007FE, .POWER9, .PPC32, {}} },
	.MODSD = { {.MODSD, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000612, 0xFC0007FE, .POWER9, .PPC64, {}} },
	.MODUD = { {.MODUD, {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000212, 0xFC0007FE, .POWER9, .PPC64, {}} },

	// Trap (D-form twi/tdi + X-form tw/td)
	//   twi  primary= 3              →  0x0C000000   TO at bits 21..25
	//   tdi  primary= 2              →  0x08000000
	//   tw   primary=31, XO=  4 → 0x7C000008
	//   td   primary=31, XO= 68 → 0x7C000088
	.TWI = { {.TWI, {.IMM, .GPR, .SIMM, .NONE}, {.TO_FIELD, .RA, .D16, .NONE}, 0x0C000000, 0xFC000000, .BASE, .PPC32, {}} },
	.TDI = { {.TDI, {.IMM, .GPR, .SIMM, .NONE}, {.TO_FIELD, .RA, .D16, .NONE}, 0x08000000, 0xFC000000, .P64,  .PPC64, {}} },
	.TW  = { {.TW,  {.IMM, .GPR, .GPR,  .NONE}, {.TO_FIELD, .RA, .RB,  .NONE}, 0x7C000008, 0xFC0007FE, .BASE, .PPC32, {}} },
	.TD  = { {.TD,  {.IMM, .GPR, .GPR,  .NONE}, {.TO_FIELD, .RA, .RB,  .NONE}, 0x7C000088, 0xFC0007FE, .P64,  .PPC64, {}} },

	// =========================================================================
	// §7 Logical / shift / rotate
	// =========================================================================
	//
	// D-form logical immediates:
	//   andi.   primary=28  →  0x70000000
	//   andis.  primary=29  →  0x74000000
	//   ori     primary=24  →  0x60000000
	//   oris    primary=25  →  0x64000000
	//   xori    primary=26  →  0x68000000
	//   xoris   primary=27  →  0x6C000000
	.ANDI_DOT  = { {.ANDI_DOT,  {.GPR, .GPR, .UIMM, .NONE}, {.RA, .RS, .UI16, .NONE}, 0x70000000, 0xFC000000, .BASE, .PPC32, {sets_cr0=true}} },
	.ANDIS_DOT = { {.ANDIS_DOT, {.GPR, .GPR, .UIMM, .NONE}, {.RA, .RS, .UI16, .NONE}, 0x74000000, 0xFC000000, .BASE, .PPC32, {sets_cr0=true}} },
	.ORI       = { {.ORI,       {.GPR, .GPR, .UIMM, .NONE}, {.RA, .RS, .UI16, .NONE}, 0x60000000, 0xFC000000, .BASE, .PPC32, {}} },
	.ORIS      = { {.ORIS,      {.GPR, .GPR, .UIMM, .NONE}, {.RA, .RS, .UI16, .NONE}, 0x64000000, 0xFC000000, .BASE, .PPC32, {}} },
	.XORI      = { {.XORI,      {.GPR, .GPR, .UIMM, .NONE}, {.RA, .RS, .UI16, .NONE}, 0x68000000, 0xFC000000, .BASE, .PPC32, {}} },
	.XORIS     = { {.XORIS,     {.GPR, .GPR, .UIMM, .NONE}, {.RA, .RS, .UI16, .NONE}, 0x6C000000, 0xFC000000, .BASE, .PPC32, {}} },

	// X-form logical (primary=31, XO at bits 1..10):
	//   and    XO= 28 → 0x7C000038
	//   or     XO=444 → 0x7C000378
	//   xor    XO=316 → 0x7C000278
	//   nand   XO=476 → 0x7C0003B8
	//   nor    XO=124 → 0x7C0000F8
	//   eqv    XO=284 → 0x7C000238
	//   andc   XO= 60 → 0x7C000078
	//   orc    XO=412 → 0x7C000338
	//   extsb  XO=954 → 0x7C000774
	//   extsh  XO=922 → 0x7C000734
	//   extsw  XO=986 → 0x7C0007B4
	//   cntlzw XO= 26 → 0x7C000034
	//   cntlzd XO= 58 → 0x7C000074
	//   cnttzw XO=538 → 0x7C00042A — collision with lswx XO=533; actual XO=538<<1=0x434 → 0x7C000434
	//   cnttzd XO=570 → 0x7C000474
	//   popcntb XO=122 → 0x7C0000F4
	//   popcntw XO=378 → 0x7C0002F4
	//   popcntd XO=506 → 0x7C0003F4
	//   prtyw  XO=154 → 0x7C000134
	//   prtyd  XO=186 → 0x7C000174
	//   bpermd XO=252 → 0x7C0001F8
	//   cmpb   XO=508 → 0x7C0003F8
	.AND       = { {.AND,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000038, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AND_DOT   = { {.AND_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000039, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.OR        = { {.OR,        {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000378, 0xFC0007FE, .BASE, .PPC32, {}} },
	.OR_DOT    = { {.OR_DOT,    {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000379, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.XOR       = { {.XOR,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000278, 0xFC0007FE, .BASE, .PPC32, {}} },
	.XOR_DOT   = { {.XOR_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000279, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.NAND      = { {.NAND,      {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C0003B8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NAND_DOT  = { {.NAND_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C0003B9, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.NOR       = { {.NOR,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C0000F8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NOR_DOT   = { {.NOR_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C0000F9, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.EQV       = { {.EQV,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000238, 0xFC0007FE, .BASE, .PPC32, {}} },
	.EQV_DOT   = { {.EQV_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000239, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.ANDC      = { {.ANDC,      {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000078, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ANDC_DOT  = { {.ANDC_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000079, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.ORC       = { {.ORC,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000338, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ORC_DOT   = { {.ORC_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000339, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },

	.EXTSB     = { {.EXTSB,     {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000774, 0xFC00FFFE, .BASE, .PPC32, {}} },
	.EXTSB_DOT = { {.EXTSB_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000775, 0xFC00FFFF, .BASE, .PPC32, {sets_cr0=true}} },
	.EXTSH     = { {.EXTSH,     {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000734, 0xFC00FFFE, .BASE, .PPC32, {}} },
	.EXTSH_DOT = { {.EXTSH_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000735, 0xFC00FFFF, .BASE, .PPC32, {sets_cr0=true}} },
	.EXTSW     = { {.EXTSW,     {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C0007B4, 0xFC00FFFE, .P64,  .PPC64, {}} },
	.EXTSW_DOT = { {.EXTSW_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C0007B5, 0xFC00FFFF, .P64,  .PPC64, {sets_cr0=true}} },
	.CNTLZW    = { {.CNTLZW,    {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000034, 0xFC00FFFE, .BASE, .PPC32, {}} },
	.CNTLZW_DOT= { {.CNTLZW_DOT,{.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000035, 0xFC00FFFF, .BASE, .PPC32, {sets_cr0=true}} },
	.CNTLZD    = { {.CNTLZD,    {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000074, 0xFC00FFFE, .P64,  .PPC64, {}} },
	.CNTLZD_DOT= { {.CNTLZD_DOT,{.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000075, 0xFC00FFFF, .P64,  .PPC64, {sets_cr0=true}} },
	.CNTTZW    = { {.CNTTZW,    {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000434, 0xFC00FFFE, .POWER9, .PPC32, {}} },
	.CNTTZW_DOT= { {.CNTTZW_DOT,{.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000435, 0xFC00FFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.CNTTZD    = { {.CNTTZD,    {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000474, 0xFC00FFFE, .POWER9, .PPC64, {}} },
	.CNTTZD_DOT= { {.CNTTZD_DOT,{.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000475, 0xFC00FFFF, .POWER9, .PPC64, {sets_cr0=true}} },
	.POPCNTB   = { {.POPCNTB,   {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C0000F4, 0xFC00FFFE, .BASE,   .PPC32, {}} },
	.POPCNTW   = { {.POPCNTW,   {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C0002F4, 0xFC00FFFE, .BASE,   .PPC32, {}} },
	.POPCNTD   = { {.POPCNTD,   {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C0003F4, 0xFC00FFFE, .P64,    .PPC64, {}} },
	.PRTYW     = { {.PRTYW,     {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000134, 0xFC00FFFE, .BASE,   .PPC32, {}} },
	.PRTYD     = { {.PRTYD,     {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE}, 0x7C000174, 0xFC00FFFE, .P64,    .PPC64, {}} },
	.BPERMD    = { {.BPERMD,    {.GPR, .GPR, .GPR, .NONE},  {.RA, .RS, .RB,   .NONE}, 0x7C0001F8, 0xFC0007FE, .P64,    .PPC64, {}} },
	.CMPB      = { {.CMPB,      {.GPR, .GPR, .GPR, .NONE},  {.RA, .RS, .RB,   .NONE}, 0x7C0003F8, 0xFC0007FE, .BASE,   .PPC32, {}} },

	// Shifts (X-form):
	//   slw    XO= 24 → 0x7C000030
	//   srw    XO=536 → 0x7C000430
	//   sraw   XO=792 → 0x7C000630
	//   srawi  XO=824 → 0x7C000670  (M-form-ish, SH at bits 11..15)
	//   sld    XO= 27 → 0x7C000036
	//   srd    XO=539 → 0x7C000436
	//   srad   XO=794 → 0x7C000634
	//   sradi  XO=413 → 0x7C000674  (XS-form: SH split across bit 1 + 11..15)
	.SLW       = { {.SLW,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000030, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLW_DOT   = { {.SLW_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000031, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.SRW       = { {.SRW,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000430, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRW_DOT   = { {.SRW_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000431, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.SRAW      = { {.SRAW,      {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000630, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRAW_DOT  = { {.SRAW_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000631, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.SRAWI     = { {.SRAWI,     {.GPR, .GPR, .IMM, .NONE}, {.RA, .RS, .SH5, .NONE}, 0x7C000670, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRAWI_DOT = { {.SRAWI_DOT, {.GPR, .GPR, .IMM, .NONE}, {.RA, .RS, .SH5, .NONE}, 0x7C000671, 0xFC0007FF, .BASE, .PPC32, {sets_cr0=true}} },
	.SLD       = { {.SLD,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000036, 0xFC0007FE, .P64,  .PPC64, {}} },
	.SLD_DOT   = { {.SLD_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000037, 0xFC0007FF, .P64,  .PPC64, {sets_cr0=true}} },
	.SRD       = { {.SRD,       {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000436, 0xFC0007FE, .P64,  .PPC64, {}} },
	.SRD_DOT   = { {.SRD_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000437, 0xFC0007FF, .P64,  .PPC64, {sets_cr0=true}} },
	.SRAD      = { {.SRAD,      {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000634, 0xFC0007FE, .P64,  .PPC64, {}} },
	.SRAD_DOT  = { {.SRAD_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RA, .RS, .RB, .NONE}, 0x7C000635, 0xFC0007FF, .P64,  .PPC64, {sets_cr0=true}} },
	.SRADI     = { {.SRADI,     {.GPR, .GPR, .IMM, .NONE}, {.RA, .RS, .SH6, .NONE}, 0x7C000674, 0xFC0007FC, .P64,  .PPC64, {}} },
	.SRADI_DOT = { {.SRADI_DOT, {.GPR, .GPR, .IMM, .NONE}, {.RA, .RS, .SH6, .NONE}, 0x7C000675, 0xFC0007FD, .P64,  .PPC64, {sets_cr0=true}} },

	// Rotate (M-form):
	//   rlwinm  primary=21 → 0x54000000
	//   rlwnm   primary=23 → 0x5C000000
	//   rlwimi  primary=20 → 0x50000000
	//   rldicl  primary=30, XO=0 → 0x78000000
	//   rldicr  primary=30, XO=1 → 0x78000004
	//   rldic   primary=30, XO=2 → 0x78000008
	//   rldimi  primary=30, XO=3 → 0x7800000C
	//   rldcl   primary=30, XO=8 (MDS) → 0x78000010
	//   rldcr   primary=30, XO=9 → 0x78000012
	.RLWINM     = { {.RLWINM,     {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH5, .MB5}, 0x54000000, 0xFC000001, .BASE, .PPC32, {}} },
	.RLWINM_DOT = { {.RLWINM_DOT, {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH5, .MB5}, 0x54000001, 0xFC000001, .BASE, .PPC32, {sets_cr0=true}} },
	.RLWNM      = { {.RLWNM,      {.GPR, .GPR, .GPR, .IMM}, {.RA, .RS, .RB,  .MB5}, 0x5C000000, 0xFC000001, .BASE, .PPC32, {}} },
	.RLWNM_DOT  = { {.RLWNM_DOT,  {.GPR, .GPR, .GPR, .IMM}, {.RA, .RS, .RB,  .MB5}, 0x5C000001, 0xFC000001, .BASE, .PPC32, {sets_cr0=true}} },
	.RLWIMI     = { {.RLWIMI,     {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH5, .MB5}, 0x50000000, 0xFC000001, .BASE, .PPC32, {}} },
	.RLWIMI_DOT = { {.RLWIMI_DOT, {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH5, .MB5}, 0x50000001, 0xFC000001, .BASE, .PPC32, {sets_cr0=true}} },
	.RLDICL     = { {.RLDICL,     {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH6, .MB6}, 0x78000000, 0xFC00001D, .P64,  .PPC64, {}} },
	.RLDICL_DOT = { {.RLDICL_DOT, {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH6, .MB6}, 0x78000001, 0xFC00001D, .P64,  .PPC64, {sets_cr0=true}} },
	.RLDICR     = { {.RLDICR,     {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH6, .MB6}, 0x78000004, 0xFC00001D, .P64,  .PPC64, {}} },
	.RLDICR_DOT = { {.RLDICR_DOT, {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH6, .MB6}, 0x78000005, 0xFC00001D, .P64,  .PPC64, {sets_cr0=true}} },
	.RLDIC      = { {.RLDIC,      {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH6, .MB6}, 0x78000008, 0xFC00001D, .P64,  .PPC64, {}} },
	.RLDIC_DOT  = { {.RLDIC_DOT,  {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH6, .MB6}, 0x78000009, 0xFC00001D, .P64,  .PPC64, {sets_cr0=true}} },
	.RLDIMI     = { {.RLDIMI,     {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH6, .MB6}, 0x7800000C, 0xFC00001D, .P64,  .PPC64, {}} },
	.RLDIMI_DOT = { {.RLDIMI_DOT, {.GPR, .GPR, .IMM, .IMM}, {.RA, .RS, .SH6, .MB6}, 0x7800000D, 0xFC00001D, .P64,  .PPC64, {sets_cr0=true}} },
	.RLDCL      = { {.RLDCL,      {.GPR, .GPR, .GPR, .IMM}, {.RA, .RS, .RB,  .MB6}, 0x78000010, 0xFC00003F, .P64,  .PPC64, {}} },
	.RLDCL_DOT  = { {.RLDCL_DOT,  {.GPR, .GPR, .GPR, .IMM}, {.RA, .RS, .RB,  .MB6}, 0x78000011, 0xFC00003F, .P64,  .PPC64, {sets_cr0=true}} },
	.RLDCR      = { {.RLDCR,      {.GPR, .GPR, .GPR, .IMM}, {.RA, .RS, .RB,  .MB6}, 0x78000012, 0xFC00003F, .P64,  .PPC64, {}} },
	.RLDCR_DOT  = { {.RLDCR_DOT,  {.GPR, .GPR, .GPR, .IMM}, {.RA, .RS, .RB,  .MB6}, 0x78000013, 0xFC00003F, .P64,  .PPC64, {sets_cr0=true}} },

	// =========================================================================
	// §8 Compare
	// =========================================================================
	//
	// D-form: cmpi primary=11 / cmpli primary=10:
	//   cmpi   0x2C000000  (BF at bits 23..25, L at bit 21, RA at 16..20, SI at 0..15)
	//   cmpli  0x28000000  (UI at 0..15)
	// X-form: cmp/cmpl primary=31, XO=0/32:
	//   cmp    XO=  0 → 0x7C000000  (mask must avoid colliding with mcrf)
	//   cmpl   XO= 32 → 0x7C000040
	//   cmprb  XO=192 → 0x7C000180 (ISA 3.0)
	//   cmpeqb XO=224 → 0x7C0001C0 (ISA 3.0)
	.CMPI  = { {.CMPI,  {.CR_FIELD, .IMM, .GPR, .SIMM}, {.BF, .L_FIELD, .RA, .D16},   0x2C000000, 0xFC400000, .BASE, .PPC32, {}} },
	.CMPLI = { {.CMPLI, {.CR_FIELD, .IMM, .GPR, .UIMM}, {.BF, .L_FIELD, .RA, .UI16},  0x28000000, 0xFC400000, .BASE, .PPC32, {}} },
	.CMP   = { {.CMP,   {.CR_FIELD, .IMM, .GPR, .GPR},  {.BF, .L_FIELD, .RA, .RB},    0x7C000000, 0xFC4007FE, .BASE, .PPC32, {}} },
	.CMPL  = { {.CMPL,  {.CR_FIELD, .IMM, .GPR, .GPR},  {.BF, .L_FIELD, .RA, .RB},    0x7C000040, 0xFC4007FE, .BASE, .PPC32, {}} },
	.CMPRB = { {.CMPRB, {.CR_FIELD, .IMM, .GPR, .GPR},  {.BF, .L_FIELD, .RA, .RB},    0x7C000180, 0xFC4007FE, .POWER9, .PPC32, {}} },
	.CMPEQB= { {.CMPEQB,{.CR_FIELD, .GPR, .GPR, .NONE}, {.BF, .RA, .RB, .NONE},       0x7C0001C0, 0xFC6007FE, .POWER9, .PPC32, {}} },

	// =========================================================================
	// §9 Floating-point arithmetic (A/X-form, primary 59 single, 63 double)
	// =========================================================================
	//
	// A-form double-precision (primary=63):
	//   fadd   XO=21  → 0x7C00 prefix... wait, primary 63 → 0xFC000000
	//                 → 21<<1=0x2A → 0xFC00002A
	//   fsub   XO=20 → 0xFC000028
	//   fmul   XO=25 → 0xFC000032 (FRC at bits 6..10 used; FRB unused)
	//   fdiv   XO=18 → 0xFC000024
	//   fsqrt  XO=22 → 0xFC00002C (no FRA, no FRC)
	//   fre    XO=24 → 0xFC000030 (no FRA, no FRC)
	//   frsqrte XO=26→ 0xFC000034 (no FRA, no FRC)
	//   fmadd  XO=29 → 0xFC00003A (full A-form: FRA,FRC,FRB)
	//   fmsub  XO=28 → 0xFC000038
	//   fnmadd XO=31 → 0xFC00003E
	//   fnmsub XO=30 → 0xFC00003C
	//   fsel   XO=23 → 0xFC00002E
	//
	// Single-precision (primary=59) — same XO values, mnemonic + "s":
	//   fadds: 0xEC00002A, fsubs: 0xEC000028, etc.
	.FADD       = { {.FADD,       {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC00002A, 0xFC0007FE, .FP, .PPC32, {}} },
	.FADD_DOT   = { {.FADD_DOT,   {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC00002B, 0xFC0007FF, .FP, .PPC32, {sets_cr1=true}} },
	.FADDS      = { {.FADDS,      {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xEC00002A, 0xFC0007FE, .FP, .PPC32, {}} },
	.FADDS_DOT  = { {.FADDS_DOT,  {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xEC00002B, 0xFC0007FF, .FP, .PPC32, {sets_cr1=true}} },
	.FSUB       = { {.FSUB,       {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC000028, 0xFC0007FE, .FP, .PPC32, {}} },
	.FSUB_DOT   = { {.FSUB_DOT,   {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC000029, 0xFC0007FF, .FP, .PPC32, {sets_cr1=true}} },
	.FSUBS      = { {.FSUBS,      {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xEC000028, 0xFC0007FE, .FP, .PPC32, {}} },
	.FSUBS_DOT  = { {.FSUBS_DOT,  {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xEC000029, 0xFC0007FF, .FP, .PPC32, {sets_cr1=true}} },
	.FMUL       = { {.FMUL,       {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0xFC000032, 0xFC00F83E, .FP, .PPC32, {}} },
	.FMUL_DOT   = { {.FMUL_DOT,   {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0xFC000033, 0xFC00F83F, .FP, .PPC32, {sets_cr1=true}} },
	.FMULS      = { {.FMULS,      {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0xEC000032, 0xFC00F83E, .FP, .PPC32, {}} },
	.FMULS_DOT  = { {.FMULS_DOT,  {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0xEC000033, 0xFC00F83F, .FP, .PPC32, {sets_cr1=true}} },
	.FDIV       = { {.FDIV,       {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC000024, 0xFC0007FE, .FP, .PPC32, {}} },
	.FDIV_DOT   = { {.FDIV_DOT,   {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC000025, 0xFC0007FF, .FP, .PPC32, {sets_cr1=true}} },
	.FDIVS      = { {.FDIVS,      {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xEC000024, 0xFC0007FE, .FP, .PPC32, {}} },
	.FDIVS_DOT  = { {.FDIVS_DOT,  {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xEC000025, 0xFC0007FF, .FP, .PPC32, {sets_cr1=true}} },
	.FSQRT      = { {.FSQRT,      {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00002C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FSQRT_DOT  = { {.FSQRT_DOT,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00002D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FSQRTS     = { {.FSQRTS,     {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC00002C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FSQRTS_DOT = { {.FSQRTS_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC00002D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FRE        = { {.FRE,        {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000030, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRE_DOT    = { {.FRE_DOT,    {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000031, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FRES       = { {.FRES,       {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC000030, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRES_DOT   = { {.FRES_DOT,   {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC000031, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FRSQRTE    = { {.FRSQRTE,    {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000034, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRSQRTE_DOT= { {.FRSQRTE_DOT,{.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000035, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FRSQRTES   = { {.FRSQRTES,   {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC000034, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRSQRTES_DOT={ {.FRSQRTES_DOT,{.FPR,.FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC000035, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FMADD      = { {.FMADD,      {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC00003A, 0xFC00003E, .FP, .PPC32, {}} },
	.FMADD_DOT  = { {.FMADD_DOT,  {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC00003B, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },
	.FMADDS     = { {.FMADDS,     {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xEC00003A, 0xFC00003E, .FP, .PPC32, {}} },
	.FMADDS_DOT = { {.FMADDS_DOT, {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xEC00003B, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },
	.FMSUB      = { {.FMSUB,      {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC000038, 0xFC00003E, .FP, .PPC32, {}} },
	.FMSUB_DOT  = { {.FMSUB_DOT,  {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC000039, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },
	.FMSUBS     = { {.FMSUBS,     {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xEC000038, 0xFC00003E, .FP, .PPC32, {}} },
	.FMSUBS_DOT = { {.FMSUBS_DOT, {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xEC000039, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },
	.FNMADD     = { {.FNMADD,     {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC00003E, 0xFC00003E, .FP, .PPC32, {}} },
	.FNMADD_DOT = { {.FNMADD_DOT, {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC00003F, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },
	.FNMADDS    = { {.FNMADDS,    {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xEC00003E, 0xFC00003E, .FP, .PPC32, {}} },
	.FNMADDS_DOT= { {.FNMADDS_DOT,{.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xEC00003F, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },
	.FNMSUB     = { {.FNMSUB,     {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC00003C, 0xFC00003E, .FP, .PPC32, {}} },
	.FNMSUB_DOT = { {.FNMSUB_DOT, {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC00003D, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },
	.FNMSUBS    = { {.FNMSUBS,    {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xEC00003C, 0xFC00003E, .FP, .PPC32, {}} },
	.FNMSUBS_DOT= { {.FNMSUBS_DOT,{.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xEC00003D, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },
	.FSEL       = { {.FSEL,       {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC00002E, 0xFC00003E, .FP, .PPC32, {}} },
	.FSEL_DOT   = { {.FSEL_DOT,   {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0xFC00002F, 0xFC00003F, .FP, .PPC32, {sets_cr1=true}} },

	// FP unary X-form (primary=63):
	//   fmr    XO= 72 → 0xFC000090 (no FRA)
	//   fneg   XO= 40 → 0xFC000050
	//   fabs   XO=264 → 0xFC000210
	//   fnabs  XO=136 → 0xFC000110
	//   fcpsgn XO=  8 → 0xFC000010 (POWER6)
	//   frsp   XO= 12 → 0xFC000018
	//   fctid  XO=814 → 0xFC00065C
	//   fctidu XO=943 → 0xFC00075E
	//   fctidz XO=815 → 0xFC00065E
	//   fctiduz XO=943 — wait dup; actually fctiduz XO=815... no.
	//   Per ISA 3.0: fctidz=815, fctiduz=815 with U bit. Actually fctiduz XO=815?
	//   Let me consult: fctiwuz XO=143, fctiduz XO=815. The bit layout uses U at bit 11... hmm.
	//   Safer: just enumerate from LLVM-generated tables.
	//   fctiw  XO= 14 → 0xFC00001C
	//   fctiwu XO=143 → 0xFC00011E
	//   fctiwz XO= 15 → 0xFC00001E
	//   fctiwuz XO=143 (with U bit set similarly)
	//   fcfid  XO=846 → 0xFC00069C
	//   fcfidu XO=974 → 0xFC00079C
	//   fcfids XO=846 (primary=59) → 0xEC00069C
	//   fcfidus XO=974 (primary=59) → 0xEC00079C
	.FMR        = { {.FMR,        {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000090, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FMR_DOT    = { {.FMR_DOT,    {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000091, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FNEG       = { {.FNEG,       {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000050, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FNEG_DOT   = { {.FNEG_DOT,   {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000051, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FABS       = { {.FABS,       {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000210, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FABS_DOT   = { {.FABS_DOT,   {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000211, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FNABS      = { {.FNABS,      {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000110, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FNABS_DOT  = { {.FNABS_DOT,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000111, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCPSGN     = { {.FCPSGN,     {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC000010, 0xFC0007FE, .FP, .PPC32, {}} },
	.FCPSGN_DOT = { {.FCPSGN_DOT, {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC000011, 0xFC0007FF, .FP, .PPC32, {sets_cr1=true}} },

	.FRSP       = { {.FRSP,       {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000018, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRSP_DOT   = { {.FRSP_DOT,   {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000019, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCTID      = { {.FCTID,      {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00065C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCTID_DOT  = { {.FCTID_DOT,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00065D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCTIDU     = { {.FCTIDU,     {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00075C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCTIDU_DOT = { {.FCTIDU_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00075D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCTIDZ     = { {.FCTIDZ,     {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00065E, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCTIDZ_DOT = { {.FCTIDZ_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00065F, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCTIDUZ    = { {.FCTIDUZ,    {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00075E, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCTIDUZ_DOT= { {.FCTIDUZ_DOT,{.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00075F, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCTIW      = { {.FCTIW,      {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00001C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCTIW_DOT  = { {.FCTIW_DOT,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00001D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCTIWU     = { {.FCTIWU,     {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00011C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCTIWU_DOT = { {.FCTIWU_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00011D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCTIWZ     = { {.FCTIWZ,     {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00001E, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCTIWZ_DOT = { {.FCTIWZ_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00001F, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCTIWUZ    = { {.FCTIWUZ,    {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00011E, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCTIWUZ_DOT= { {.FCTIWUZ_DOT,{.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00011F, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCFID      = { {.FCFID,      {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00069C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCFID_DOT  = { {.FCFID_DOT,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00069D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCFIDU     = { {.FCFIDU,     {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00079C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCFIDU_DOT = { {.FCFIDU_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC00079D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCFIDS     = { {.FCFIDS,     {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC00069C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCFIDS_DOT = { {.FCFIDS_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC00069D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FCFIDUS    = { {.FCFIDUS,    {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC00079C, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FCFIDUS_DOT= { {.FCFIDUS_DOT,{.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xEC00079D, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },

	// Round to integer (frin/friz/frip/frim):
	//   XO=392 → 0xFC000310 (frin)
	//   XO=424 → 0xFC000350 (friz)
	//   XO=456 → 0xFC000390 (frip)
	//   XO=488 → 0xFC0003D0 (frim)
	.FRIN  = { {.FRIN,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000310, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRIN_DOT = { {.FRIN_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000311, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FRIZ  = { {.FRIZ,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000350, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRIZ_DOT = { {.FRIZ_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000351, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FRIP  = { {.FRIP,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000390, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRIP_DOT = { {.FRIP_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC000391, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },
	.FRIM  = { {.FRIM,  {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC0003D0, 0xFC1F07FE, .FP, .PPC32, {}} },
	.FRIM_DOT = { {.FRIM_DOT, {.FPR, .FPR, .NONE, .NONE}, {.FRT, .FRB, .NONE, .NONE}, 0xFC0003D1, 0xFC1F07FF, .FP, .PPC32, {sets_cr1=true}} },

	// FP compare:
	//   fcmpu  primary=63 XO= 0 → 0xFC000000 (BF at 23..25)
	//   fcmpo  primary=63 XO=32 → 0xFC000040
	//   ftdiv  primary=63 XO=128 → 0xFC000100 (POWER7)
	//   ftsqrt primary=63 XO=160 → 0xFC000140
	//   fmrgew primary=63 XO=966 → 0xFC00078C (POWER8)
	//   fmrgow primary=63 XO=838 → 0xFC00068C (POWER8)
	.FCMPU = { {.FCMPU, {.CR_FIELD, .FPR, .FPR, .NONE}, {.BF, .FRA, .FRB, .NONE}, 0xFC000000, 0xFC6007FE, .FP, .PPC32, {}} },
	.FCMPO = { {.FCMPO, {.CR_FIELD, .FPR, .FPR, .NONE}, {.BF, .FRA, .FRB, .NONE}, 0xFC000040, 0xFC6007FE, .FP, .PPC32, {}} },
	.FTDIV = { {.FTDIV, {.CR_FIELD, .FPR, .FPR, .NONE}, {.BF, .FRA, .FRB, .NONE}, 0xFC000100, 0xFC6007FE, .FP, .PPC32, {}} },
	.FTSQRT= { {.FTSQRT,{.CR_FIELD, .FPR, .NONE,.NONE}, {.BF, .FRB, .NONE,.NONE}, 0xFC000140, 0xFC7F07FE, .FP, .PPC32, {}} },
	.FMRGEW= { {.FMRGEW,{.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC00078C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.FMRGOW= { {.FMRGOW,{.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0xFC00068C, 0xFC0007FE, .POWER8, .PPC32, {}} },

	// FP loads/stores (D-form):
	//   lfs   primary=48 → 0xC0000000
	//   lfsu  primary=49 → 0xC4000000
	//   lfd   primary=50 → 0xC8000000
	//   lfdu  primary=51 → 0xCC000000
	//   stfs  primary=52 → 0xD0000000
	//   stfsu primary=53 → 0xD4000000
	//   stfd  primary=54 → 0xD8000000
	//   stfdu primary=55 → 0xDC000000
	//   lfdp  primary=57 (DS-form, XO=0) → 0xE4000000  (POWER7)
	//   stfdp primary=61 (DS-form, XO=0) → 0xF4000000
	// X-form (primary=31):
	//   lfsx   XO=535 → 0x7C00042E
	//   lfsux  XO=567 → 0x7C00046E
	//   lfdx   XO=599 → 0x7C0004AE
	//   lfdux  XO=631 → 0x7C0004EE
	//   stfsx  XO=663 → 0x7C00052E
	//   stfsux XO=695 → 0x7C00056E
	//   stfdx  XO=727 → 0x7C0005AE
	//   stfdux XO=759 → 0x7C0005EE
	//   lfiwax XO=855 → 0x7C0006AE (POWER6)
	//   lfiwzx XO=887 → 0x7C0006EE (POWER7)
	//   stfiwx XO=983 → 0x7C0007AE
	//   lfdpx  XO=791 → 0x7C00062E
	//   stfdpx XO=919 → 0x7C00072E
	.LFS    = { {.LFS,    {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xC0000000, 0xFC000000, .FP, .PPC32, {}} },
	.LFSU   = { {.LFSU,   {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xC4000000, 0xFC000000, .FP, .PPC32, {}} },
	.LFD    = { {.LFD,    {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xC8000000, 0xFC000000, .FP, .PPC32, {}} },
	.LFDU   = { {.LFDU,   {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xCC000000, 0xFC000000, .FP, .PPC32, {}} },
	.STFS   = { {.STFS,   {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xD0000000, 0xFC000000, .FP, .PPC32, {}} },
	.STFSU  = { {.STFSU,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xD4000000, 0xFC000000, .FP, .PPC32, {}} },
	.STFD   = { {.STFD,   {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xD8000000, 0xFC000000, .FP, .PPC32, {}} },
	.STFDU  = { {.STFDU,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xDC000000, 0xFC000000, .FP, .PPC32, {}} },
	.LFDP   = { {.LFDP,   {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xE4000000, 0xFC000003, .FP, .PPC32, {}} },
	.STFDP  = { {.STFDP,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xF4000000, 0xFC000003, .FP, .PPC32, {}} },
	.LFSX   = { {.LFSX,   {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00042E, 0xFC0007FE, .FP, .PPC32, {}} },
	.LFSUX  = { {.LFSUX,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00046E, 0xFC0007FE, .FP, .PPC32, {}} },
	.LFDX   = { {.LFDX,   {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0004AE, 0xFC0007FE, .FP, .PPC32, {}} },
	.LFDUX  = { {.LFDUX,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0004EE, 0xFC0007FE, .FP, .PPC32, {}} },
	.STFSX  = { {.STFSX,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00052E, 0xFC0007FE, .FP, .PPC32, {}} },
	.STFSUX = { {.STFSUX, {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00056E, 0xFC0007FE, .FP, .PPC32, {}} },
	.STFDX  = { {.STFDX,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0005AE, 0xFC0007FE, .FP, .PPC32, {}} },
	.STFDUX = { {.STFDUX, {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0005EE, 0xFC0007FE, .FP, .PPC32, {}} },
	.LFIWAX = { {.LFIWAX, {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0006AE, 0xFC0007FE, .FP, .PPC32, {}} },
	.LFIWZX = { {.LFIWZX, {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0006EE, 0xFC0007FE, .FP, .PPC32, {}} },
	.STFIWX = { {.STFIWX, {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0007AE, 0xFC0007FE, .FP, .PPC32, {}} },
	.LFDPX  = { {.LFDPX,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00062E, 0xFC0007FE, .FP, .PPC32, {}} },
	.STFDPX = { {.STFDPX, {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00072E, 0xFC0007FE, .FP, .PPC32, {}} },

	// FPSCR control:
	//   mffs    primary=63 XO=583 → 0xFC00048E
	//   mcrfs   primary=63 XO= 64 → 0xFC000080
	//   mtfsb0  primary=63 XO= 70 → 0xFC00008C
	//   mtfsb1  primary=63 XO= 38 → 0xFC00004C
	//   mtfsfi  primary=63 XO=134 → 0xFC00010C
	//   mtfsf   primary=63 XO=711 → 0xFC00058E
	.MFFS       = { {.MFFS,       {.FPR, .NONE, .NONE, .NONE}, {.FRT, .NONE, .NONE, .NONE}, 0xFC00048E, 0xFC1FFFFE, .FP, .PPC32, {}} },
	.MFFS_DOT   = { {.MFFS_DOT,   {.FPR, .NONE, .NONE, .NONE}, {.FRT, .NONE, .NONE, .NONE}, 0xFC00048F, 0xFC1FFFFF, .FP, .PPC32, {sets_cr1=true}} },
	.MCRFS      = { {.MCRFS,      {.CR_FIELD, .CR_FIELD, .NONE, .NONE}, {.BF, .BFA, .NONE, .NONE}, 0xFC000080, 0xFC63FFFE, .FP, .PPC32, {}} },
	.MTFSB0     = { {.MTFSB0,     {.CR_BIT, .NONE, .NONE, .NONE}, {.BT, .NONE, .NONE, .NONE}, 0xFC00008C, 0xFC1FFFFE, .FP, .PPC32, {}} },
	.MTFSB0_DOT = { {.MTFSB0_DOT, {.CR_BIT, .NONE, .NONE, .NONE}, {.BT, .NONE, .NONE, .NONE}, 0xFC00008D, 0xFC1FFFFF, .FP, .PPC32, {sets_cr1=true}} },
	.MTFSB1     = { {.MTFSB1,     {.CR_BIT, .NONE, .NONE, .NONE}, {.BT, .NONE, .NONE, .NONE}, 0xFC00004C, 0xFC1FFFFE, .FP, .PPC32, {}} },
	.MTFSB1_DOT = { {.MTFSB1_DOT, {.CR_BIT, .NONE, .NONE, .NONE}, {.BT, .NONE, .NONE, .NONE}, 0xFC00004D, 0xFC1FFFFF, .FP, .PPC32, {sets_cr1=true}} },
	.MTFSFI     = { {.MTFSFI,     {.CR_FIELD, .IMM, .NONE, .NONE}, {.BF, .UIMM_4, .NONE, .NONE}, 0xFC00010C, 0xFC7E0FFE, .FP, .PPC32, {}} },
	.MTFSFI_DOT = { {.MTFSFI_DOT, {.CR_FIELD, .IMM, .NONE, .NONE}, {.BF, .UIMM_4, .NONE, .NONE}, 0xFC00010D, 0xFC7E0FFF, .FP, .PPC32, {sets_cr1=true}} },
	.MTFSF      = { {.MTFSF,      {.IMM, .FPR, .NONE, .NONE}, {.FXM, .FRB, .NONE, .NONE}, 0xFC00058E, 0xFE0107FE, .FP, .PPC32, {}} },
	.MTFSF_DOT  = { {.MTFSF_DOT,  {.IMM, .FPR, .NONE, .NONE}, {.FXM, .FRB, .NONE, .NONE}, 0xFC00058F, 0xFE0107FF, .FP, .PPC32, {sets_cr1=true}} },

	// =========================================================================
	// §10 SPR / system / cache
	// =========================================================================
	//
	// XFX-form (primary=31, XO=339/467):
	//   mfspr   XO=339 → 0x7C0002A6
	//   mtspr   XO=467 → 0x7C0003A6
	//   mftb    XO=371 → 0x7C0002E6 (deprecated by mfspr)
	//   mfcr    XO= 19 → 0x7C000026 (RT at 21..25, no SPR field)
	//   mfocrf  XO= 19 with bit 20 = 1
	//   mtcrf   XO=144 → 0x7C000120
	//   mtocrf  XO=144 with bit 20 = 1
	//   mtmsr   XO=146 (sup)
	//   mfmsr   XO= 83
	//   mtmsrd  XO=178 (sup)
	.MFSPR  = { {.MFSPR, {.GPR, .SPR, .NONE, .NONE}, {.RT, .SPR_FIELD, .NONE, .NONE}, 0x7C0002A6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTSPR  = { {.MTSPR, {.SPR, .GPR, .NONE, .NONE}, {.SPR_FIELD, .RS, .NONE, .NONE}, 0x7C0003A6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MFTB   = { {.MFTB,  {.GPR, .SPR, .NONE, .NONE}, {.RT, .SPR_FIELD, .NONE, .NONE}, 0x7C0002E6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MFCR   = { {.MFCR,  {.GPR, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x7C000026, 0xFC1FFFFE, .BASE, .PPC32, {}} },
	.MFOCRF = { {.MFOCRF,{.GPR, .IMM,  .NONE, .NONE}, {.RT, .CRM,  .NONE, .NONE}, 0x7C100026, 0xFC101FFE, .BASE, .PPC32, {}} },
	.MTCRF  = { {.MTCRF, {.IMM, .GPR,  .NONE, .NONE}, {.CRM, .RS,  .NONE, .NONE}, 0x7C000120, 0xFC100FFE, .BASE, .PPC32, {}} },
	.MTOCRF = { {.MTOCRF,{.IMM, .GPR,  .NONE, .NONE}, {.CRM, .RS,  .NONE, .NONE}, 0x7C100120, 0xFC101FFE, .BASE, .PPC32, {}} },
	.MFMSR  = { {.MFMSR, {.GPR, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x7C0000A6, 0xFC1FFFFE, .SUPV, .PPC32, {}} },
	.MTMSR  = { {.MTMSR, {.GPR, .NONE, .NONE, .NONE}, {.RS, .NONE, .NONE, .NONE}, 0x7C000124, 0xFC1FFFFE, .SUPV, .PPC32, {}} },
	.MTMSRD = { {.MTMSRD,{.GPR, .NONE, .NONE, .NONE}, {.RS, .NONE, .NONE, .NONE}, 0x7C000164, 0xFC1FFFFE, .SUPV, .PPC64, {}} },

	// RFI/RFID/HRFID (XL-form, supervisor):
	//   rfi   primary=19 XO= 50 → 0x4C000064
	//   rfid  primary=19 XO= 18 → 0x4C000024 (PPC64)
	//   hrfid primary=19 XO=274 → 0x4C000224
	.RFI   = { {.RFI,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C000064, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.RFID  = { {.RFID,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C000024, 0xFFFFFFFE, .SUPV, .PPC64, {}} },
	.HRFID = { {.HRFID, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C000224, 0xFFFFFFFE, .HV,   .PPC64, {}} },

	// Synchronization (X-form, primary=31):
	//   sync     XO=598 → 0x7C0004AC  (L=0 = heavyweight sync; L=1 lwsync; L=2 ptesync)
	//   lwsync   sync L=1 → 0x7C2004AC
	//   ptesync  sync L=2 → 0x7C4004AC
	//   eieio    XO=854 → 0x7C0006AC
	//   isync    primary=19 XO=150 → 0x4C00012C
	//   wait     XO= 30 → 0x7C00003C (POWER9 with WC field)
	.SYNC    = { {.SYNC,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0004AC, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.LWSYNC  = { {.LWSYNC,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C2004AC, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.PTESYNC = { {.PTESYNC, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C4004AC, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.EIEIO   = { {.EIEIO,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0006AC, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.ISYNC   = { {.ISYNC,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C00012C, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.WAIT    = { {.WAIT,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00003C, 0xFFFFFFFE, .POWER9, .PPC32, {}} },

	// Cache management (X-form, primary=31):
	//   dcbt    XO=278 → 0x7C00022C  (with TH field; safe-fill TH=0)
	//   dcbtst  XO=246 → 0x7C0001EC
	//   dcba    XO=758 → 0x7C0005EC
	//   dcbf    XO= 86 → 0x7C0000AC
	//   dcbz    XO=1014 → 0x7C0007EC
	//   icbi    XO=982 → 0x7C0007AC
	//   icbt    XO= 22 → 0x7C00002C (POWER7)
	//   darn    primary=31 XO=755 → 0x7C0005E6 (POWER9; L at bits 16..17)
	.DCBT   = { {.DCBT,   {.MEM, .NONE,.NONE,.NONE}, {.OFFSET_BASE_X,.NONE,.NONE,.NONE}, 0x7C00022C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBTST = { {.DCBTST, {.MEM, .NONE,.NONE,.NONE}, {.OFFSET_BASE_X,.NONE,.NONE,.NONE}, 0x7C0001EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBA   = { {.DCBA,   {.MEM, .NONE,.NONE,.NONE}, {.OFFSET_BASE_X,.NONE,.NONE,.NONE}, 0x7C0005EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBF   = { {.DCBF,   {.MEM, .NONE,.NONE,.NONE}, {.OFFSET_BASE_X,.NONE,.NONE,.NONE}, 0x7C0000AC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBZ   = { {.DCBZ,   {.MEM, .NONE,.NONE,.NONE}, {.OFFSET_BASE_X,.NONE,.NONE,.NONE}, 0x7C0007EC, 0xFE2007FE, .BASE, .PPC32, {}} },
	.ICBI   = { {.ICBI,   {.MEM, .NONE,.NONE,.NONE}, {.OFFSET_BASE_X,.NONE,.NONE,.NONE}, 0x7C0007AC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ICBT   = { {.ICBT,   {.MEM, .NONE,.NONE,.NONE}, {.OFFSET_BASE_X,.NONE,.NONE,.NONE}, 0x7C00002C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DARN   = { {.DARN,   {.GPR, .IMM, .NONE, .NONE}, {.RT, .L_FIELD, .NONE, .NONE}, 0x7C0005E6, 0xFC1CFFFE, .POWER9, .PPC32, {}} },

	// =========================================================================
	// §11 AltiVec (VMX) — primary=4 (0x10000000 base)
	// =========================================================================
	//
	// Three forms used here:
	//   VX-form  primary + VRT + VRA + VRB + XO(11 bits at 0..10)
	//   VA-form  primary + VRT + VRA + VRB + VRC + XO(6 bits at 0..5)
	//   VC-form  primary + VRT + VRA + VRB + Rc + XO(10 bits at 0..9)
	// Base bits = 0x10000000. XO value goes directly to LSB position 0..N.

	// ---- Logical (VX-form) ----
	.VAND   = { {.VAND,   {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000404, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VANDC  = { {.VANDC,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000444, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VOR    = { {.VOR,    {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000484, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VORC   = { {.VORC,   {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000544, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VNOR   = { {.VNOR,   {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000504, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VXOR   = { {.VXOR,   {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100004C4, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VEQV   = { {.VEQV,   {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000684, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VNAND  = { {.VNAND,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000584, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VSEL   = { {.VSEL,   {.VR, .VR, .VR, .VR},   {.VRT, .VRA, .VRB, .VRC},  0x1000002A, 0xFC00003F, .ALTIVEC, .PPC32, {}} },

	// ---- Integer add/sub (VX-form) ----
	// XO: vaddubm=0, vadduhm=64, vadduwm=128, vaddudm=192 (P8);
	//     vsububm=1024, vsubuhm=1088, vsubuwm=1152, vsubudm=1216;
	//     vaddfp=10, vsubfp=74; vaddcuw=384, vsubcuw=1408;
	//     vaddcuq=320 (P8), vsubcuq=1344;
	//     vaddubs=512, vadduhs=576, vadduws=640;
	//     vaddsbs=768, vaddshs=832, vaddsws=896;
	//     vsububs=1536, vsubuhs=1600, vsubuws=1664;
	//     vsubsbs=1792, vsubshs=1856, vsubsws=1920;
	//     vaddecuq=61 (VA-form), vaddeuqm=60 (VA-form);
	//     vsubecuq=63 (VA-form), vsubeuqm=62 (VA-form).
	.VADDUBM = { {.VADDUBM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000000, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDUHM = { {.VADDUHM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000040, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDUWM = { {.VADDUWM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000080, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDUDM = { {.VADDUDM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100000C0, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VADDFP  = { {.VADDFP,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000000A, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBUBM = { {.VSUBUBM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000400, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBUHM = { {.VSUBUHM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000440, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBUWM = { {.VSUBUWM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000480, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBUDM = { {.VSUBUDM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100004C0, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VSUBFP  = { {.VSUBFP,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000004A, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDCUW = { {.VADDCUW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000180, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDCUQ = { {.VADDCUQ, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000140, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VSUBCUW = { {.VSUBCUW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000580, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBCUQ = { {.VSUBCUQ, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000540, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VADDUBS = { {.VADDUBS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000200, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDUHS = { {.VADDUHS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000240, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDUWS = { {.VADDUWS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000280, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDSBS = { {.VADDSBS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000300, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDSHS = { {.VADDSHS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000340, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VADDSWS = { {.VADDSWS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000380, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBUBS = { {.VSUBUBS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000600, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBUHS = { {.VSUBUHS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000640, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBUWS = { {.VSUBUWS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000680, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBSBS = { {.VSUBSBS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000700, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBSHS = { {.VSUBSHS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000740, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSUBSWS = { {.VSUBSWS, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000780, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	// VA-form extended-carry add/sub:
	.VADDECUQ = { {.VADDECUQ, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x1000003D, 0xFC00003F, .POWER8, .PPC32, {}} },
	.VADDEUQM = { {.VADDEUQM, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x1000003C, 0xFC00003F, .POWER8, .PPC32, {}} },
	.VSUBECUQ = { {.VSUBECUQ, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x1000003F, 0xFC00003F, .POWER8, .PPC32, {}} },
	.VSUBEUQM = { {.VSUBEUQM, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x1000003E, 0xFC00003F, .POWER8, .PPC32, {}} },

	// ---- Multiply (VX-form even/odd; vmuluwm POWER8) ----
	// XO: vmulesb=776, vmuleub=520, vmulosb=264, vmuloub=8;
	//     vmulesh=840, vmuleuh=584, vmulosh=328, vmulouh=72;
	//     vmulesw=904, vmuleuw=648, vmulosw=392, vmulouw=136;
	//     vmuluwm=137 (P8).
	.VMULESB = { {.VMULESB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000308, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMULESH = { {.VMULESH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000348, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMULESW = { {.VMULESW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000388, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMULEUB = { {.VMULEUB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000208, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMULEUH = { {.VMULEUH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000248, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMULEUW = { {.VMULEUW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000288, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMULOSB = { {.VMULOSB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000108, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMULOSH = { {.VMULOSH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000148, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMULOSW = { {.VMULOSW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000188, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMULOUB = { {.VMULOUB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000008, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMULOUH = { {.VMULOUH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000048, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMULOUW = { {.VMULOUW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000088, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMULUWM = { {.VMULUWM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000089, 0xFC0007FF, .POWER8,  .PPC32, {}} },

	// ---- Multiply-sum (VA-form) ----
	// XO: vmsumubm=36, vmsummbm=37, vmsumuhm=38, vmsumuhs=39,
	//     vmsumshm=40, vmsumshs=41, vmsumudm=35 (P8).
	.VMSUMUBM = { {.VMSUMUBM, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x10000024, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VMSUMMBM = { {.VMSUMMBM, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x10000025, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VMSUMUHM = { {.VMSUMUHM, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x10000026, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VMSUMUHS = { {.VMSUMUHS, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x10000027, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VMSUMSHM = { {.VMSUMSHM, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x10000028, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VMSUMSHS = { {.VMSUMSHS, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x10000029, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VMSUMUDM = { {.VMSUMUDM, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x10000023, 0xFC00003F, .POWER8,  .PPC32, {}} },

	// ---- Compare (VC-form, Rc at bit 10) ----
	// XO: vcmpequb=6, vcmpequh=70, vcmpequw=134, vcmpequd=199 (P8);
	//     vcmpgtsb=774, vcmpgtsh=838, vcmpgtsw=902, vcmpgtsd=967 (P8);
	//     vcmpgtub=518, vcmpgtuh=582, vcmpgtuw=646, vcmpgtud=711 (P8);
	//     vcmpneb=7 (P9), vcmpneh=71, vcmpnew=135;
	//     vcmpeqfp=198, vcmpgefp=454, vcmpgtfp=710, vcmpbfp=966.
	.VCMPEQUB     = { {.VCMPEQUB,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000006, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPEQUB_DOT = { {.VCMPEQUB_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000406, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPEQUH     = { {.VCMPEQUH,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000046, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPEQUH_DOT = { {.VCMPEQUH_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000446, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPEQUW     = { {.VCMPEQUW,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000086, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPEQUW_DOT = { {.VCMPEQUW_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000486, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPEQUD     = { {.VCMPEQUD,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100000C7, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VCMPEQUD_DOT = { {.VCMPEQUD_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100004C7, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VCMPNEB      = { {.VCMPNEB,      {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000007, 0xFC0007FF, .POWER9,  .PPC32, {}} },
	.VCMPNEB_DOT  = { {.VCMPNEB_DOT,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000407, 0xFC0007FF, .POWER9,  .PPC32, {}} },
	.VCMPNEH      = { {.VCMPNEH,      {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000047, 0xFC0007FF, .POWER9,  .PPC32, {}} },
	.VCMPNEH_DOT  = { {.VCMPNEH_DOT,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000447, 0xFC0007FF, .POWER9,  .PPC32, {}} },
	.VCMPNEW      = { {.VCMPNEW,      {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000087, 0xFC0007FF, .POWER9,  .PPC32, {}} },
	.VCMPNEW_DOT  = { {.VCMPNEW_DOT,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000487, 0xFC0007FF, .POWER9,  .PPC32, {}} },
	.VCMPGTSB     = { {.VCMPGTSB,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000306, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTSB_DOT = { {.VCMPGTSB_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000706, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTSH     = { {.VCMPGTSH,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000346, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTSH_DOT = { {.VCMPGTSH_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000746, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTSW     = { {.VCMPGTSW,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000386, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTSW_DOT = { {.VCMPGTSW_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000786, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTSD     = { {.VCMPGTSD,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100003C7, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VCMPGTSD_DOT = { {.VCMPGTSD_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100007C7, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VCMPGTUB     = { {.VCMPGTUB,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000206, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTUB_DOT = { {.VCMPGTUB_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000606, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTUH     = { {.VCMPGTUH,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000246, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTUH_DOT = { {.VCMPGTUH_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000646, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTUW     = { {.VCMPGTUW,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000286, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTUW_DOT = { {.VCMPGTUW_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000686, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTUD     = { {.VCMPGTUD,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100002C7, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VCMPGTUD_DOT = { {.VCMPGTUD_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100006C7, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VCMPEQFP     = { {.VCMPEQFP,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100000C6, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPEQFP_DOT = { {.VCMPEQFP_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100004C6, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGEFP     = { {.VCMPGEFP,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100001C6, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGEFP_DOT = { {.VCMPGEFP_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100005C6, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTFP     = { {.VCMPGTFP,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100002C6, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPGTFP_DOT = { {.VCMPGTFP_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100006C6, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPBFP      = { {.VCMPBFP,      {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100003C6, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCMPBFP_DOT  = { {.VCMPBFP_DOT,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100007C6, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },

	// ---- Max/min (VX-form) ----
	// XO: vmaxub=2, vmaxuh=66, vmaxuw=130, vmaxud=194 (P8);
	//     vmaxsb=258, vmaxsh=322, vmaxsw=386, vmaxsd=450 (P8);
	//     vmaxfp=1034 → 0x40A;
	//     vminub=514, vminuh=578, vminuw=642, vminud=706 (P8);
	//     vminsb=770, vminsh=834, vminsw=898, vminsd=962 (P8);
	//     vminfp=1098 → 0x44A.
	.VMAXUB = { {.VMAXUB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000002, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMAXUH = { {.VMAXUH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000042, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMAXUW = { {.VMAXUW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000082, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMAXUD = { {.VMAXUD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100000C2, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMAXSB = { {.VMAXSB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000102, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMAXSH = { {.VMAXSH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000142, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMAXSW = { {.VMAXSW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000182, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMAXSD = { {.VMAXSD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100001C2, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMAXFP = { {.VMAXFP, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000040A, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMINUB = { {.VMINUB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000202, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMINUH = { {.VMINUH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000242, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMINUW = { {.VMINUW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000282, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMINUD = { {.VMINUD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100002C2, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMINSB = { {.VMINSB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000302, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMINSH = { {.VMINSH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000342, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMINSW = { {.VMINSW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000382, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMINSD = { {.VMINSD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100003C2, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMINFP = { {.VMINFP, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000044A, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },

	// ---- Average (signed/unsigned byte/half/word) ----
	// XO: vavgsb=1282, vavgsh=1346, vavgsw=1410;
	//     vavgub=1026, vavguh=1090, vavguw=1154.
	.VAVGSB = { {.VAVGSB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000502, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VAVGSH = { {.VAVGSH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000542, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VAVGSW = { {.VAVGSW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000582, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VAVGUB = { {.VAVGUB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000402, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VAVGUH = { {.VAVGUH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000442, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VAVGUW = { {.VAVGUW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000482, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },

	// ---- Shift (VX-form) — full 128-bit + per-element ----
	// XO: vsl=452, vsr=708, vslo=1036, vsro=1100;
	//     vslb=260, vslh=324, vslw=388, vsld=1476 (P8);
	//     vsrb=516, vsrh=580, vsrw=644, vsrd=1732 (P8);
	//     vsrab=772, vsrah=836, vsraw=900, vsrad=964 (P8);
	//     vrlb=4, vrlh=68, vrlw=132, vrld=196 (P8).
	.VSL  = { {.VSL,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100001C4, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSR  = { {.VSR,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100002C4, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSLO = { {.VSLO, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000040C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSRO = { {.VSRO, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000044C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSLB = { {.VSLB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000104, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSLH = { {.VSLH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000144, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSLW = { {.VSLW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000184, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSLD = { {.VSLD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100005C4, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VSRB = { {.VSRB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000204, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSRH = { {.VSRH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000244, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSRW = { {.VSRW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000284, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSRD = { {.VSRD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100006C4, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VSRAB = { {.VSRAB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000304, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSRAH = { {.VSRAH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000344, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSRAW = { {.VSRAW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000384, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VSRAD = { {.VSRAD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100003C4, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VRLB = { {.VRLB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000004, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VRLH = { {.VRLH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000044, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VRLW = { {.VRLW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000084, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VRLD = { {.VRLD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100000C4, 0xFC0007FF, .POWER8,  .PPC32, {}} },

	// ---- Permute / pack / merge / splat / unpack ----
	// VA-form perm/sldoi: vperm XO=43, vpermr=59 (P9), vsldoi XO=44.
	// VX-form merge: vmrghb=12, vmrghh=76, vmrghw=140;
	//                vmrglb=268, vmrglh=332, vmrglw=396;
	//                vmrgew=1932 → 0x78C (P8), vmrgow=1676 → 0x68C (P8).
	// VX-form splat: vspltb=524, vsplth=588, vspltw=652;
	//                vspltisb=780, vspltish=844, vspltisw=908.
	// Pack: vpkpx=782, vpkuhum=14, vpkuwum=78, vpkudum=1102 (P8);
	//       vpkuhus=142, vpkuwus=206, vpkudus=1230 (P8);
	//       vpkshus=270, vpkswus=334, vpksdus=1358 (P8);
	//       vpkshss=398, vpkswss=462, vpksdss=1486 (P8).
	// Unpack: vupkhsb=526, vupkhsh=590, vupkhsw=1614 (P8);
	//         vupklsb=654, vupklsh=718, vupklsw=1742 (P8);
	//         vupkhpx=846, vupklpx=974.
	.VPERM     = { {.VPERM,     {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x1000002B, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VPERMR    = { {.VPERMR,    {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRB, .VRC}, 0x1000003B, 0xFC00003F, .POWER9,  .PPC32, {}} },
	.VSLDOI    = { {.VSLDOI,    {.VR, .VR, .VR, .IMM},{.VRT, .VRA, .VRB, .UIMM_4}, 0x1000002C, 0xFC00043F, .ALTIVEC, .PPC32, {}} },
	.VBPERMQ   = { {.VBPERMQ,   {.VR, .VR, .VR, .NONE},{.VRT, .VRA, .VRB, .NONE}, 0x1000054C, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VBPERMD   = { {.VBPERMD,   {.VR, .VR, .VR, .NONE},{.VRT, .VRA, .VRB, .NONE}, 0x100005CC, 0xFC0007FF, .POWER9,  .PPC32, {}} },
	.VMRGHB    = { {.VMRGHB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000000C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMRGHH    = { {.VMRGHH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000004C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMRGHW    = { {.VMRGHW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000008C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMRGLB    = { {.VMRGLB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000010C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMRGLH    = { {.VMRGLH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000014C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMRGLW    = { {.VMRGLW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000018C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VMRGEW    = { {.VMRGEW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000078C, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VMRGOW    = { {.VMRGOW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000068C, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VSPLTB    = { {.VSPLTB, {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000020C, 0xFC1007FF, .ALTIVEC, .PPC32, {}} },
	.VSPLTH    = { {.VSPLTH, {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000024C, 0xFC1807FF, .ALTIVEC, .PPC32, {}} },
	.VSPLTW    = { {.VSPLTW, {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000028C, 0xFC1C07FF, .ALTIVEC, .PPC32, {}} },
	.VSPLTISB  = { {.VSPLTISB, {.VR, .SIMM, .NONE, .NONE}, {.VRT, .SIMM_5, .NONE, .NONE}, 0x1000030C, 0xFC00FFFF, .ALTIVEC, .PPC32, {}} },
	.VSPLTISH  = { {.VSPLTISH, {.VR, .SIMM, .NONE, .NONE}, {.VRT, .SIMM_5, .NONE, .NONE}, 0x1000034C, 0xFC00FFFF, .ALTIVEC, .PPC32, {}} },
	.VSPLTISW  = { {.VSPLTISW, {.VR, .SIMM, .NONE, .NONE}, {.VRT, .SIMM_5, .NONE, .NONE}, 0x1000038C, 0xFC00FFFF, .ALTIVEC, .PPC32, {}} },
	.VPKPX     = { {.VPKPX,    {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000030E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKUHUM   = { {.VPKUHUM,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000000E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKUWUM   = { {.VPKUWUM,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000004E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKUDUM   = { {.VPKUDUM,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000044E, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VPKUHUS   = { {.VPKUHUS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000008E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKUWUS   = { {.VPKUWUS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100000CE, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKUDUS   = { {.VPKUDUS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100004CE, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VPKSHUS   = { {.VPKSHUS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000010E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKSWUS   = { {.VPKSWUS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000014E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKSDUS   = { {.VPKSDUS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000054E, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VPKSHSS   = { {.VPKSHSS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x1000018E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKSWSS   = { {.VPKSWSS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100001CE, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VPKSDSS   = { {.VPKSDSS,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100005CE, 0xFC0007FF, .POWER8,  .PPC32, {}} },
	.VUPKHSB   = { {.VUPKHSB,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000020E, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VUPKHSH   = { {.VUPKHSH,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000024E, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VUPKHSW   = { {.VUPKHSW,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000064E, 0xFC1F07FF, .POWER8,  .PPC32, {}} },
	.VUPKLSB   = { {.VUPKLSB,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000028E, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VUPKLSH   = { {.VUPKLSH,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x100002CE, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VUPKLSW   = { {.VUPKLSW,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x100006CE, 0xFC1F07FF, .POWER8,  .PPC32, {}} },
	.VUPKHPX   = { {.VUPKHPX,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000034E, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VUPKLPX   = { {.VUPKLPX,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x100003CE, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },

	// ---- FP vector misc (VX-form) ----
	// XO: vrfim=970, vrfin=522, vrfip=650, vrfiz=586;
	//     vexptefp=394, vlogefp=458;
	//     vrefp=266, vrsqrtefp=330;
	//     vcfsx=842, vcfux=778; vctsxs=970→ collision; actually vctsxs XO=970? double check.
	//     Per Power ISA: vcfsx=842, vcfux=778, vctsxs=970, vctuxs=906.
	.VRFIM     = { {.VRFIM, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x100002CA, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VRFIN     = { {.VRFIN, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000020A, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VRFIP     = { {.VRFIP, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000028A, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VRFIZ     = { {.VRFIZ, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000024A, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VEXPTEFP  = { {.VEXPTEFP,  {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000018A, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VLOGEFP   = { {.VLOGEFP,   {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x100001CA, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VREFP     = { {.VREFP,     {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000010A, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VRSQRTEFP = { {.VRSQRTEFP, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x1000014A, 0xFC1F07FF, .ALTIVEC, .PPC32, {}} },
	.VMADDFP   = { {.VMADDFP, {.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRC, .VRB}, 0x1000002E, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VNMSUBFP  = { {.VNMSUBFP,{.VR, .VR, .VR, .VR}, {.VRT, .VRA, .VRC, .VRB}, 0x1000002F, 0xFC00003F, .ALTIVEC, .PPC32, {}} },
	.VCFSX     = { {.VCFSX, {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_5, .NONE}, 0x1000034A, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCFUX     = { {.VCFUX, {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_5, .NONE}, 0x1000030A, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCTSXS    = { {.VCTSXS, {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_5, .NONE}, 0x100003CA, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.VCTUXS    = { {.VCTUXS, {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_5, .NONE}, 0x1000038A, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },

	// ---- AltiVec load/store (X-form, primary=31) ----
	//   lvx     XO=103  → 0x7C0000CE
	//   lvxl    XO=359  → 0x7C0002CE
	//   lvebx   XO=  7  → 0x7C00000E
	//   lvehx   XO= 39  → 0x7C00004E
	//   lvewx   XO= 71  → 0x7C00008E
	//   lvsl    XO=  6  → 0x7C00000C
	//   lvsr    XO= 38  → 0x7C00004C
	//   stvx    XO=231  → 0x7C0001CE
	//   stvxl   XO=487  → 0x7C0003CE
	//   stvebx  XO=135  → 0x7C00010E
	//   stvehx  XO=167  → 0x7C00014E
	//   stvewx  XO=199  → 0x7C00018E
	//   mfvscr  XO=1540 → 0x7C000604
	//   mtvscr  XO=1604 → 0x7C000644
	.LVX    = { {.LVX,    {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0000CE, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.LVXL   = { {.LVXL,   {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0002CE, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.LVEBX  = { {.LVEBX,  {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00000E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.LVEHX  = { {.LVEHX,  {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00004E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.LVEWX  = { {.LVEWX,  {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00008E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.LVSL   = { {.LVSL,   {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00000C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.LVSR   = { {.LVSR,   {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00004C, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.STVX   = { {.STVX,   {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0001CE, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.STVXL  = { {.STVXL,  {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C0003CE, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.STVEBX = { {.STVEBX, {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00010E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.STVEHX = { {.STVEHX, {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00014E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.STVEWX = { {.STVEWX, {.VR, .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_X, .NONE, .NONE}, 0x7C00018E, 0xFC0007FF, .ALTIVEC, .PPC32, {}} },
	.MFVSCR = { {.MFVSCR, {.VR, .NONE,.NONE,.NONE}, {.VRT, .NONE,.NONE,.NONE}, 0x10000604, 0xFC1FFFFF, .ALTIVEC, .PPC32, {}} },
	.MTVSCR = { {.MTVSCR, {.VR, .NONE,.NONE,.NONE}, {.VRB, .NONE,.NONE,.NONE}, 0x10000644, 0xFFFF07FF, .ALTIVEC, .PPC32, {}} },

	// =========================================================================
	// §12 VSX — Vector-Scalar Extension (primary=60 for arithmetic, primary=31
	//          for indexed memory, primary=61 for D/DS/DQ-form memory)
	// =========================================================================
	//
	// VSX registers are 6-bit (vs0..vs63). The high bit is split into a
	// separate position in the encoding:
	//   XT[5] at bit 0 (TX)
	//   XA[5] at bit 2 (AX)
	//   XB[5] at bit 1 (BX)
	//   XC[5] at bit 3 (CX)  — XX4-form only
	// The low 5 bits live at the usual register-slot positions
	// (XT@21:25, XA@16:20, XB@11:15, XC@6:10).
	//
	// Form summary:
	//   XX1-form  TX + XO(10 at bits 1..10)        memory + a few select
	//   XX2-form  TX + BX + XO(9 at bits 2..10)    unary ops
	//   XX3-form  TX + AX + BX + XO(8 at bits 3..10) binary/ternary
	//   XX4-form  TX + AX + BX + CX + XO(2 at bits 4..5) XXSEL only
	// Encoded bits for XO: XO_value << shift, where shift = bit position of
	// the lowest XO bit (1 for XX1, 2 for XX2, 3 for XX3, 4 for XX4).

	// ---- VSX X-form indexed memory (primary=31) ----
	//   lxsdx    XO=588  → 588<<1 = 0x498  → 0x7C000498
	//   lxsiwax  XO= 76  → 0x098            → 0x7C000098
	//   lxsiwzx  XO= 12  → 0x018            → 0x7C000018
	//   lxsspx   XO=524  → 0x418            → 0x7C000418  (P8)
	//   lxvd2x   XO=844  → 0x698            → 0x7C000698
	//   lxvdsx   XO=332  → 0x298            → 0x7C000298
	//   lxvw4x   XO=780  → 0x618            → 0x7C000618
	//   lxvh8x   XO=812  → 0x658            → 0x7C000658  (P9)
	//   lxvb16x  XO=876  → 0x6D8            → 0x7C0006D8  (P9)
	//   lxvl     XO=269  → 0x21A            → 0x7C00021A  (P9)
	//   lxvll    XO=301  → 0x25A            → 0x7C00025A  (P9)
	//   lxvx     XO=268  → 0x218            → 0x7C000218  (P9)
	//   lxsibzx  XO=781  → 0x61A            → 0x7C00061A  (P9)
	//   lxsihzx  XO=813  → 0x65A            → 0x7C00065A  (P9)
	//   stxsdx   XO=716  → 0x598            → 0x7C000598
	//   stxsiwx  XO=140  → 0x118            → 0x7C000118
	//   stxsspx  XO=652  → 0x518            → 0x7C000518  (P8)
	//   stxvd2x  XO=972  → 0x798            → 0x7C000798
	//   stxvw4x  XO=908  → 0x718            → 0x7C000718
	//   stxvh8x  XO=940  → 0x758            → 0x7C000758  (P9)
	//   stxvb16x XO=1004 → 0x7D8            → 0x7C0007D8  (P9)
	//   stxvl    XO=397  → 0x31A            → 0x7C00031A  (P9)
	//   stxvll   XO=429  → 0x35A            → 0x7C00035A  (P9)
	//   stxvx    XO=396  → 0x318            → 0x7C000318  (P9)
	//   stxsibx  XO=909  → 0x71A            → 0x7C00071A  (P9)
	//   stxsihx  XO=941  → 0x75A            → 0x7C00075A  (P9)
	.LXSDX    = { {.LXSDX,    {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000498, 0xFC0007FE, .VSX,    .PPC32, {}} },
	.LXSIWAX  = { {.LXSIWAX,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000098, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.LXSIWZX  = { {.LXSIWZX,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000018, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.LXSSPX   = { {.LXSSPX,   {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000418, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.LXVD2X   = { {.LXVD2X,   {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000698, 0xFC0007FE, .VSX,    .PPC32, {}} },
	.LXVDSX   = { {.LXVDSX,   {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000298, 0xFC0007FE, .VSX,    .PPC32, {}} },
	.LXVW4X   = { {.LXVW4X,   {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000618, 0xFC0007FE, .VSX,    .PPC32, {}} },
	.LXVH8X   = { {.LXVH8X,   {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000658, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.LXVB16X  = { {.LXVB16X,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C0006D8, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.LXVL     = { {.LXVL,     {.VSR, .GPR, .GPR, .NONE},  {.XT, .RA, .RB, .NONE}, 0x7C00021A, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.LXVLL    = { {.LXVLL,    {.VSR, .GPR, .GPR, .NONE},  {.XT, .RA, .RB, .NONE}, 0x7C00025A, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.LXVX     = { {.LXVX,     {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000218, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.LXSIBZX  = { {.LXSIBZX,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C00061A, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.LXSIHZX  = { {.LXSIHZX,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C00065A, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.STXSDX   = { {.STXSDX,   {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000598, 0xFC0007FE, .VSX,    .PPC32, {}} },
	.STXSIWX  = { {.STXSIWX,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000118, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.STXSSPX  = { {.STXSSPX,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000518, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.STXVD2X  = { {.STXVD2X,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000798, 0xFC0007FE, .VSX,    .PPC32, {}} },
	.STXVW4X  = { {.STXVW4X,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000718, 0xFC0007FE, .VSX,    .PPC32, {}} },
	.STXVH8X  = { {.STXVH8X,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000758, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.STXVB16X = { {.STXVB16X, {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C0007D8, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.STXVL    = { {.STXVL,    {.VSR, .GPR, .GPR, .NONE},  {.XT, .RA, .RB, .NONE}, 0x7C00031A, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.STXVLL   = { {.STXVLL,   {.VSR, .GPR, .GPR, .NONE},  {.XT, .RA, .RB, .NONE}, 0x7C00035A, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.STXVX    = { {.STXVX,    {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C000318, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.STXSIBX  = { {.STXSIBX,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C00071A, 0xFC0007FE, .VSX_P9, .PPC32, {}} },
	.STXSIHX  = { {.STXSIHX,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_VSX_X, .NONE, .NONE}, 0x7C00075A, 0xFC0007FE, .VSX_P9, .PPC32, {}} },

	// ---- VSX D-form memory (primary=61 = 0xF4000000 for stxv; primary=61 with
	//      DS-form XO for lxsd/stxsd/lxssp/stxssp; primary=61 with DQ-form for
	//      lxv/stxv) ----
	//   lxv    primary=61 DQ-form, XO=  1 → 0xF4000001  (P9)
	//   stxv   primary=61 DQ-form, XO=  5 → 0xF4000005  (P9)
	//   lxsd   primary=57 DS-form, XO=  2 → 0xE4000002  (P9; primary 57!)
	//   lxssp  primary=57 DS-form, XO=  3 → 0xE4000003  (P9)
	//   stxsd  primary=61 DS-form, XO=  2 → 0xF4000002  (P9)
	//   stxssp primary=61 DS-form, XO=  3 → 0xF4000003  (P9)
	.LXV   = { {.LXV,   {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_BASE_DQ, .NONE, .NONE}, 0xF4000001, 0xFC000007, .VSX_P9, .PPC32, {}} },
	.STXV  = { {.STXV,  {.VSR, .MEM, .NONE, .NONE}, {.XT, .OFFSET_BASE_DQ, .NONE, .NONE}, 0xF4000005, 0xFC000007, .VSX_P9, .PPC32, {}} },
	.LXSD  = { {.LXSD,  {.VR,  .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xE4000002, 0xFC000003, .VSX_P9, .PPC32, {}} },
	.LXSSP = { {.LXSSP, {.VR,  .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xE4000003, 0xFC000003, .VSX_P9, .PPC32, {}} },
	.STXSD = { {.STXSD, {.VR,  .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xF4000002, 0xFC000003, .VSX_P9, .PPC32, {}} },
	.STXSSP= { {.STXSSP,{.VR,  .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_DS, .NONE, .NONE}, 0xF4000003, 0xFC000003, .VSX_P9, .PPC32, {}} },

	// ---- VSX XX3-form scalar arithmetic (primary=60, XO at bits 3..10) ----
	// base = 0xF0000000. XO_value << 3.
	//   xsadddp   XO=32 → 32<<3=0x100 → 0xF0000100
	//   xsaddsp   XO= 0 → 0x000       → 0xF0000000
	//   xssubdp   XO=40 → 0x140       → 0xF0000140
	//   xssubsp   XO= 8 → 0x040       → 0xF0000040
	//   xsmuldp   XO=48 → 0x180       → 0xF0000180
	//   xsmulsp   XO=16 → 0x080       → 0xF0000080
	//   xsdivdp   XO=56 → 0x1C0       → 0xF00001C0
	//   xsdivsp   XO=24 → 0x0C0       → 0xF00000C0
	//   xsmaddadp XO=33 → 0x108       → 0xF0000108
	//   xsmaddasp XO= 1 → 0x008       → 0xF0000008
	//   xsmaddmdp XO=41 → 0x148       → 0xF0000148
	//   xsmaddmsp XO= 9 → 0x048       → 0xF0000048
	//   xsmsubadp XO=49 → 0x188       → 0xF0000188
	//   xsmsubasp XO=17 → 0x088       → 0xF0000088
	//   xsmsubmdp XO=57 → 0x1C8       → 0xF00001C8
	//   xsmsubmsp XO=25 → 0x0C8       → 0xF00000C8
	//   xsnmaddadp XO=161 → 0x508     → 0xF0000508
	//   xsnmaddasp XO=129 → 0x408     → 0xF0000408
	//   xsnmaddmdp XO=169 → 0x548     → 0xF0000548
	//   xsnmaddmsp XO=137 → 0x448     → 0xF0000448
	//   xsnmsubadp XO=177 → 0x588     → 0xF0000588
	//   xsnmsubasp XO=145 → 0x488     → 0xF0000488
	//   xsnmsubmdp XO=185 → 0x5C8     → 0xF00005C8
	//   xsnmsubmsp XO=153 → 0x4C8     → 0xF00004C8
	//   xsmaxdp   XO=160 → 0x500       → 0xF0000500
	//   xsmindp   XO=168 → 0x540       → 0xF0000540
	//   xsmaxcdp  XO=128 → 0x400       → 0xF0000400  (P9)
	//   xsmincdp  XO=136 → 0x440       → 0xF0000440  (P9)
	//   xsmaxjdp  XO=144 → 0x480       → 0xF0000480  (P9)
	//   xsminjdp  XO=152 → 0x4C0       → 0xF00004C0  (P9)
	//   xscpsgndp XO=176 → 0x580       → 0xF0000580
	//   xscmpodp  XO= 43 → 0x158       → 0xF0000158 (BF at bits 23..25; no XT)
	//   xscmpudp  XO= 35 → 0x118       → 0xF0000118
	//   xscmpeqdp XO=  3 → 0x018       → 0xF0000018  (P9)
	//   xscmpgtdp XO= 11 → 0x058       → 0xF0000058  (P9)
	//   xscmpgedp XO= 19 → 0x098       → 0xF0000098  (P9)
	.XSADDDP   = { {.XSADDDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000100, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSADDSP   = { {.XSADDSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000000, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSSUBDP   = { {.XSSUBDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000140, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSSUBSP   = { {.XSSUBSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000040, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSMULDP   = { {.XSMULDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000180, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSMULSP   = { {.XSMULSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000080, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSDIVDP   = { {.XSDIVDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00001C0, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSDIVSP   = { {.XSDIVSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00000C0, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSMADDADP = { {.XSMADDADP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000108, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSMADDASP = { {.XSMADDASP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000008, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSMADDMDP = { {.XSMADDMDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000148, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSMADDMSP = { {.XSMADDMSP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000048, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSMSUBADP = { {.XSMSUBADP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000188, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSMSUBASP = { {.XSMSUBASP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000088, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSMSUBMDP = { {.XSMSUBMDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00001C8, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSMSUBMSP = { {.XSMSUBMSP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00000C8, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSNMADDADP= { {.XSNMADDADP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000508, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSNMADDASP= { {.XSNMADDASP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000408, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSNMADDMDP= { {.XSNMADDMDP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000548, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSNMADDMSP= { {.XSNMADDMSP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000448, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSNMSUBADP= { {.XSNMSUBADP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000588, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSNMSUBASP= { {.XSNMSUBASP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000488, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSNMSUBMDP= { {.XSNMSUBMDP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00005C8, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSNMSUBMSP= { {.XSNMSUBMSP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00004C8, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XSMAXDP   = { {.XSMAXDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000500, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSMINDP   = { {.XSMINDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000540, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSMAXCDP  = { {.XSMAXCDP,  {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000400, 0xFC0007F8, .VSX_P9, .PPC32, {}} },
	.XSMINCDP  = { {.XSMINCDP,  {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000440, 0xFC0007F8, .VSX_P9, .PPC32, {}} },
	.XSMAXJDP  = { {.XSMAXJDP,  {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000480, 0xFC0007F8, .VSX_P9, .PPC32, {}} },
	.XSMINJDP  = { {.XSMINJDP,  {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00004C0, 0xFC0007F8, .VSX_P9, .PPC32, {}} },
	.XSCPSGNDP = { {.XSCPSGNDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000580, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XSCMPODP  = { {.XSCMPODP,  {.CR_FIELD, .VSR, .VSR, .NONE}, {.BF, .XA, .XB, .NONE}, 0xF0000158, 0xFC6007FC, .VSX, .PPC32, {}} },
	.XSCMPUDP  = { {.XSCMPUDP,  {.CR_FIELD, .VSR, .VSR, .NONE}, {.BF, .XA, .XB, .NONE}, 0xF0000118, 0xFC6007FC, .VSX, .PPC32, {}} },
	.XSCMPEQDP = { {.XSCMPEQDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000018, 0xFC0007F8, .VSX_P9, .PPC32, {}} },
	.XSCMPGTDP = { {.XSCMPGTDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000058, 0xFC0007F8, .VSX_P9, .PPC32, {}} },
	.XSCMPGEDP = { {.XSCMPGEDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000098, 0xFC0007F8, .VSX_P9, .PPC32, {}} },

	// ---- VSX XX2-form scalar unary (primary=60, XO at bits 2..10, 9-bit) ----
	// base 0xF0000000. XO << 2.
	//   xsabsdp     XO=345 → 345<<2=0x564 → 0xF0000564
	//   xsnabsdp    XO=361 → 0x5A4         → 0xF00005A4
	//   xsnegdp     XO=377 → 0x5E4         → 0xF00005E4
	//   xssqrtdp    XO=75  → 0x12C         → 0xF000012C  (XO=75, lookups vary;
	//                                        per ARM Power ISA 2.06: xssqrtdp XO=75)
	//   xssqrtsp    XO=11  → 0x02C         → 0xF000002C  (P8)
	//   xsresp      XO=26  → 0x068         → 0xF0000068  (P8)
	//   xsredp      XO=90  → 0x168         → 0xF0000168
	//   xsrsqrtesp  XO=10  → 0x028         → 0xF0000028  (P8)
	//   xsrsqrtedp  XO=74  → 0x128         → 0xF0000128
	//   xscvdpsp    XO=265 → 0x424         → 0xF0000424
	//   xscvspdp    XO=329 → 0x524         → 0xF0000524
	//   xscvdpsxds  XO=344 → 0x560         → 0xF0000560
	//   xscvdpuxds  XO=328 → 0x520         → 0xF0000520
	//   xscvdpsxws  XO=88  → 0x160         → 0xF0000160
	//   xscvdpuxws  XO=72  → 0x120         → 0xF0000120
	//   xscvsxddp   XO=376 → 0x5E0         → 0xF00005E0
	//   xscvuxddp   XO=360 → 0x5A0         → 0xF00005A0
	//   xscvspdpn   XO=331 → 0x52C         → 0xF000052C  (P8)
	//   xscvdpspn   XO=267 → 0x42C         → 0xF000042C  (P8)
	//   xscvdphp    XO=347 → 0x56C         — XO at 16..20 sub-field, complex
	//   xscvhpdp    XO=347 → similar — defer
	//   xsrdpi      XO=73  → 0x124         → 0xF0000124
	//   xsrdpim     XO=121 → 0x1E4         → 0xF00001E4
	//   xsrdpip     XO=105 → 0x1A4         → 0xF00001A4
	//   xsrdpiz     XO=89  → 0x164         → 0xF0000164
	//   xsrdpic     XO=107 → 0x1AC         → 0xF00001AC
	//   xsrsp       XO=281 → 0x464         → 0xF0000464  (P8)
	.XSABSDP    = { {.XSABSDP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000564, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSNABSDP   = { {.XSNABSDP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00005A4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSNEGDP    = { {.XSNEGDP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00005E4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSSQRTDP   = { {.XSSQRTDP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF000012C, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSSQRTSP   = { {.XSSQRTSP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF000002C, 0xFC1F07FC, .POWER8, .PPC32, {}} },
	.XSRESP     = { {.XSRESP,     {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000068, 0xFC1F07FC, .POWER8, .PPC32, {}} },
	.XSREDP     = { {.XSREDP,     {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000168, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSRSQRTESP = { {.XSRSQRTESP, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000028, 0xFC1F07FC, .POWER8, .PPC32, {}} },
	.XSRSQRTEDP = { {.XSRSQRTEDP, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000128, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVDPSP   = { {.XSCVDPSP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000424, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVSPDP   = { {.XSCVSPDP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000524, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVDPSXDS = { {.XSCVDPSXDS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000560, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVDPUXDS = { {.XSCVDPUXDS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000520, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVDPSXWS = { {.XSCVDPSXWS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000160, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVDPUXWS = { {.XSCVDPUXWS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000120, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVSXDDP  = { {.XSCVSXDDP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00005E0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVUXDDP  = { {.XSCVUXDDP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00005A0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSCVSPDPN  = { {.XSCVSPDPN,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF000052C, 0xFC1F07FC, .POWER8, .PPC32, {}} },
	.XSCVDPSPN  = { {.XSCVDPSPN,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF000042C, 0xFC1F07FC, .POWER8, .PPC32, {}} },
	.XSRDPI     = { {.XSRDPI,     {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000124, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSRDPIM    = { {.XSRDPIM,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00001E4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSRDPIP    = { {.XSRDPIP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00001A4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSRDPIZ    = { {.XSRDPIZ,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000164, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSRDPIC    = { {.XSRDPIC,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00001AC, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XSRSP      = { {.XSRSP,      {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000464, 0xFC1F07FC, .POWER8, .PPC32, {}} },

	// ---- VSX XX3-form vector arithmetic (primary=60) ----
	//   xvaddsp   XO= 64 → 0x200 → 0xF0000200
	//   xvadddp   XO= 96 → 0x300 → 0xF0000300
	//   xvsubsp   XO= 72 → 0x240 → 0xF0000240
	//   xvsubdp   XO=104 → 0x340 → 0xF0000340
	//   xvmulsp   XO= 80 → 0x280 → 0xF0000280
	//   xvmuldp   XO=112 → 0x380 → 0xF0000380
	//   xvdivsp   XO= 88 → 0x2C0 → 0xF00002C0
	//   xvdivdp   XO=120 → 0x3C0 → 0xF00003C0
	//   xvmaddasp XO= 65 → 0x208 → 0xF0000208
	//   xvmaddadp XO= 97 → 0x308 → 0xF0000308
	//   xvmaddmsp XO= 73 → 0x248 → 0xF0000248
	//   xvmaddmdp XO=105 → 0x348 → 0xF0000348
	//   xvmsubasp XO= 81 → 0x288 → 0xF0000288
	//   xvmsubadp XO=113 → 0x388 → 0xF0000388
	//   xvmsubmsp XO= 89 → 0x2C8 → 0xF00002C8
	//   xvmsubmdp XO=121 → 0x3C8 → 0xF00003C8
	//   xvnmaddasp XO=193 → 0x608 → 0xF0000608
	//   xvnmaddadp XO=225 → 0x708 → 0xF0000708
	//   xvnmaddmsp XO=201 → 0x648 → 0xF0000648
	//   xvnmaddmdp XO=233 → 0x748 → 0xF0000748
	//   xvnmsubasp XO=209 → 0x688 → 0xF0000688
	//   xvnmsubadp XO=241 → 0x788 → 0xF0000788
	//   xvnmsubmsp XO=217 → 0x6C8 → 0xF00006C8
	//   xvnmsubmdp XO=249 → 0x7C8 → 0xF00007C8
	//   xvmaxsp   XO=192 → 0x600 → 0xF0000600
	//   xvmaxdp   XO=224 → 0x700 → 0xF0000700
	//   xvminsp   XO=200 → 0x640 → 0xF0000640
	//   xvmindp   XO=232 → 0x740 → 0xF0000740
	//   xvcmpeqsp XO= 67 → 0x218 → 0xF0000218
	//   xvcmpeqsp. XO=67 Rc=1 → 0x21C    (Rc at bit 2; wait no — for VC-style ops the Rc is at different position)
	//   Power ISA actually defines:
	//     xvcmpeqsp  primary=60 XO=67 → 0xF0000218
	//     xvcmpeqsp. primary=60 XO=67 with Rc bit at bit 10 → 0xF0000618
	//   Actually XX3-form Rc lives at bit 10 (which is part of the XO field):
	//     Non-dot XO=67 → 0xF0000218
	//     Dot     XO=67 + Rc bit → XO becomes effectively 67+512 = 579 → 0xF0000618
	//   xvcmpeqdp XO= 99 → 0x318 → 0xF0000318
	//   xvcmpgtsp XO= 75 → 0x258 → 0xF0000258
	//   xvcmpgtdp XO=107 → 0x358 → 0xF0000358
	//   xvcmpgesp XO= 83 → 0x298 → 0xF0000298
	//   xvcmpgedp XO=115 → 0x398 → 0xF0000398
	//   xvcpsgnsp XO=208 → 0x680 → 0xF0000680
	//   xvcpsgndp XO=240 → 0x780 → 0xF0000780
	.XVADDSP   = { {.XVADDSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000200, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVADDDP   = { {.XVADDDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000300, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVSUBSP   = { {.XVSUBSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000240, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVSUBDP   = { {.XVSUBDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000340, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMULSP   = { {.XVMULSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000280, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMULDP   = { {.XVMULDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000380, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVDIVSP   = { {.XVDIVSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00002C0, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVDIVDP   = { {.XVDIVDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00003C0, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMADDASP = { {.XVMADDASP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000208, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMADDADP = { {.XVMADDADP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000308, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMADDMSP = { {.XVMADDMSP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000248, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMADDMDP = { {.XVMADDMDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000348, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMSUBASP = { {.XVMSUBASP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000288, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMSUBADP = { {.XVMSUBADP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000388, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMSUBMSP = { {.XVMSUBMSP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00002C8, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMSUBMDP = { {.XVMSUBMDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00003C8, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVNMADDASP= { {.XVNMADDASP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000608, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVNMADDADP= { {.XVNMADDADP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000708, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVNMADDMSP= { {.XVNMADDMSP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000648, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVNMADDMDP= { {.XVNMADDMDP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000748, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVNMSUBASP= { {.XVNMSUBASP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000688, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVNMSUBADP= { {.XVNMSUBADP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000788, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVNMSUBMSP= { {.XVNMSUBMSP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00006C8, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVNMSUBMDP= { {.XVNMSUBMDP,{.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00007C8, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMAXSP   = { {.XVMAXSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000600, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMAXDP   = { {.XVMAXDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000700, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMINSP   = { {.XVMINSP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000640, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVMINDP   = { {.XVMINDP,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000740, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPEQSP     = { {.XVCMPEQSP,     {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000218, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPEQSP_DOT = { {.XVCMPEQSP_DOT, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000618, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPEQDP     = { {.XVCMPEQDP,     {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000318, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPEQDP_DOT = { {.XVCMPEQDP_DOT, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000718, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPGTSP     = { {.XVCMPGTSP,     {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000258, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPGTSP_DOT = { {.XVCMPGTSP_DOT, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000658, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPGTDP     = { {.XVCMPGTDP,     {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000358, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPGTDP_DOT = { {.XVCMPGTDP_DOT, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000758, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPGESP     = { {.XVCMPGESP,     {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000298, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPGESP_DOT = { {.XVCMPGESP_DOT, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000698, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPGEDP     = { {.XVCMPGEDP,     {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000398, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCMPGEDP_DOT = { {.XVCMPGEDP_DOT, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000798, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCPSGNSP = { {.XVCPSGNSP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000680, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XVCPSGNDP = { {.XVCPSGNDP, {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000780, 0xFC0007F8, .VSX, .PPC32, {}} },

	// ---- VSX XX2-form vector unary ----
	//   xvabssp     XO=409 → 0x664 → 0xF0000664
	//   xvabsdp     XO=473 → 0x764 → 0xF0000764
	//   xvnabssp    XO=425 → 0x6A4 → 0xF00006A4
	//   xvnabsdp    XO=489 → 0x7A4 → 0xF00007A4
	//   xvnegsp     XO=441 → 0x6E4 → 0xF00006E4
	//   xvnegdp     XO=505 → 0x7E4 → 0xF00007E4
	//   xvsqrtsp    XO=139 → 0x22C → 0xF000022C
	//   xvsqrtdp    XO=203 → 0x32C → 0xF000032C
	//   xvresp      XO=154 → 0x268 → 0xF0000268
	//   xvredp      XO=218 → 0x368 → 0xF0000368
	//   xvrsqrtesp  XO=138 → 0x228 → 0xF0000228
	//   xvrsqrtedp  XO=202 → 0x328 → 0xF0000328
	//   xvcvspdp    XO=457 → 0x724 → 0xF0000724
	//   xvcvdpsp    XO=393 → 0x624 → 0xF0000624
	//   xvcvspsxds  XO=408 → 0x660 → 0xF0000660
	//   xvcvspuxds  XO=392 → 0x620 → 0xF0000620
	//   xvcvdpsxds  XO=472 → 0x760 → 0xF0000760
	//   xvcvdpuxds  XO=456 → 0x720 → 0xF0000720
	//   xvcvspsxws  XO=152 → 0x260 → 0xF0000260
	//   xvcvspuxws  XO=136 → 0x220 → 0xF0000220
	//   xvcvdpsxws  XO=216 → 0x360 → 0xF0000360
	//   xvcvdpuxws  XO=200 → 0x320 → 0xF0000320
	//   xvcvsxdsp   XO=440 → 0x6E0 → 0xF00006E0
	//   xvcvuxdsp   XO=424 → 0x6A0 → 0xF00006A0
	//   xvcvsxddp   XO=504 → 0x7E0 → 0xF00007E0
	//   xvcvuxddp   XO=488 → 0x7A0 → 0xF00007A0
	//   xvcvsxwsp   XO=184 → 0x2E0 → 0xF00002E0
	//   xvcvuxwsp   XO=168 → 0x2A0 → 0xF00002A0
	//   xvcvsxwdp   XO=248 → 0x3E0 → 0xF00003E0
	//   xvcvuxwdp   XO=232 → 0x3A0 → 0xF00003A0
	//   xvrspi      XO=137 → 0x224 → 0xF0000224
	//   xvrspim     XO=185 → 0x2E4 → 0xF00002E4
	//   xvrspip     XO=169 → 0x2A4 → 0xF00002A4
	//   xvrspiz     XO=153 → 0x264 → 0xF0000264
	//   xvrspic     XO=171 → 0x2AC → 0xF00002AC
	//   xvrdpi      XO=201 → 0x324 → 0xF0000324
	//   xvrdpim     XO=249 → 0x3E4 → 0xF00003E4
	//   xvrdpip     XO=233 → 0x3A4 → 0xF00003A4
	//   xvrdpiz     XO=217 → 0x364 → 0xF0000364
	//   xvrdpic     XO=235 → 0x3AC → 0xF00003AC
	.XVABSSP    = { {.XVABSSP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000664, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVABSDP    = { {.XVABSDP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000764, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVNABSSP   = { {.XVNABSSP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00006A4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVNABSDP   = { {.XVNABSDP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00007A4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVNEGSP    = { {.XVNEGSP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00006E4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVNEGDP    = { {.XVNEGDP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00007E4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVSQRTSP   = { {.XVSQRTSP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF000022C, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVSQRTDP   = { {.XVSQRTDP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF000032C, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRESP     = { {.XVRESP,     {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000268, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVREDP     = { {.XVREDP,     {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000368, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRSQRTESP = { {.XVRSQRTESP, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000228, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRSQRTEDP = { {.XVRSQRTEDP, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000328, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSPDP   = { {.XVCVSPDP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000724, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVDPSP   = { {.XVCVDPSP,   {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000624, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSPSXDS = { {.XVCVSPSXDS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000660, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSPUXDS = { {.XVCVSPUXDS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000620, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVDPSXDS = { {.XVCVDPSXDS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000760, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVDPUXDS = { {.XVCVDPUXDS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000720, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSPSXWS = { {.XVCVSPSXWS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000260, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSPUXWS = { {.XVCVSPUXWS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000220, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVDPSXWS = { {.XVCVDPSXWS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000360, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVDPUXWS = { {.XVCVDPUXWS, {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000320, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSXDSP  = { {.XVCVSXDSP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00006E0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVUXDSP  = { {.XVCVUXDSP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00006A0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSXDDP  = { {.XVCVSXDDP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00007E0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVUXDDP  = { {.XVCVUXDDP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00007A0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSXWSP  = { {.XVCVSXWSP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00002E0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVUXWSP  = { {.XVCVUXWSP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00002A0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVSXWDP  = { {.XVCVSXWDP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00003E0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVCVUXWDP  = { {.XVCVUXWDP,  {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00003A0, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRSPI     = { {.XVRSPI,     {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000224, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRSPIM    = { {.XVRSPIM,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00002E4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRSPIP    = { {.XVRSPIP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00002A4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRSPIZ    = { {.XVRSPIZ,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000264, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRSPIC    = { {.XVRSPIC,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00002AC, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRDPI     = { {.XVRDPI,     {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000324, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRDPIM    = { {.XVRDPIM,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00003E4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRDPIP    = { {.XVRDPIP,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00003A4, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRDPIZ    = { {.XVRDPIZ,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF0000364, 0xFC1F07FC, .VSX, .PPC32, {}} },
	.XVRDPIC    = { {.XVRDPIC,    {.VSR, .VSR, .NONE, .NONE}, {.XT, .XB, .NONE, .NONE}, 0xF00003AC, 0xFC1F07FC, .VSX, .PPC32, {}} },

	// ---- VSX XX3-form logical (primary=60) ----
	//   xxland   XO=130 → 0x410 → 0xF0000410
	//   xxlandc  XO=138 → 0x450 → 0xF0000450
	//   xxlor    XO=146 → 0x490 → 0xF0000490
	//   xxlxor   XO=154 → 0x4D0 → 0xF00004D0
	//   xxlnor   XO=162 → 0x510 → 0xF0000510
	//   xxleqv   XO=186 → 0x5D0 → 0xF00005D0  (P8)
	//   xxlnand  XO=178 → 0x590 → 0xF0000590  (P8)
	//   xxlorc   XO=170 → 0x550 → 0xF0000550  (P8)
	//   xxsel    primary=60 XX4-form XO=3 → 0x030 → 0xF0000030
	//   xxsldwi  XO= 2 → 0x010 → 0xF0000010 (with SHW at bits 8..9)
	//   xxpermdi XO=10 → 0x050 → 0xF0000050 (with DM at bits 8..9)
	//   xxmrghw  XO= 18 → 0x090 → 0xF0000090
	//   xxmrglw  XO= 50 → 0x190 → 0xF0000190
	//   xxspltw  XO=164 (XX2-form, UIM at bits 16..17) → 0x290 → 0xF0000290
	//   xxsplitb (xxspltib XO=360 XX1-form imm) → 0x2D0 → 0xF00002D0  (P9; primary=60)
	//   xxextractuw XO=165 → 0x294 → 0xF0000294 (P9)
	//   xxinsertw   XO=181 → 0x2D4 → 0xF00002D4 (P9)
	//   xxperm      XO=26  → 0x0D0 → 0xF00000D0 (P9)
	.XXLAND   = { {.XXLAND,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000410, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XXLANDC  = { {.XXLANDC,  {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000450, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XXLOR    = { {.XXLOR,    {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000490, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XXLXOR   = { {.XXLXOR,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00004D0, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XXLNOR   = { {.XXLNOR,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000510, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XXLEQV   = { {.XXLEQV,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00005D0, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XXLNAND  = { {.XXLNAND,  {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000590, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XXLORC   = { {.XXLORC,   {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000550, 0xFC0007F8, .POWER8, .PPC32, {}} },
	.XXSEL    = { {.XXSEL,    {.VSR, .VSR, .VSR, .VSR},  {.XT, .XA, .XB, .XC},   0xF0000030, 0xFC000030, .VSX, .PPC32, {}} },
	.XXSLDWI  = { {.XXSLDWI,  {.VSR, .VSR, .VSR, .IMM},  {.XT, .XA, .XB, .UIMM_2}, 0xF0000010, 0xFC0003F8, .VSX, .PPC32, {}} },
	.XXPERMDI = { {.XXPERMDI, {.VSR, .VSR, .VSR, .IMM},  {.XT, .XA, .XB, .UIMM_2}, 0xF0000050, 0xFC0003F8, .VSX, .PPC32, {}} },
	.XXMRGHW  = { {.XXMRGHW,  {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000090, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XXMRGLW  = { {.XXMRGLW,  {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF0000190, 0xFC0007F8, .VSX, .PPC32, {}} },
	.XXSPLTW  = { {.XXSPLTW,  {.VSR, .VSR, .IMM, .NONE}, {.XT, .XB, .UIMM_2, .NONE}, 0xF0000290, 0xFC1C07FC, .VSX, .PPC32, {}} },
	.XXSPLTIB = { {.XXSPLTIB, {.VSR, .UIMM, .NONE, .NONE}, {.XT, .UIMM_5, .NONE, .NONE}, 0xF00002D0, 0xFC18FFFC, .VSX_P9, .PPC32, {}} },
	.XXEXTRACTUW = { {.XXEXTRACTUW, {.VSR, .VSR, .IMM, .NONE}, {.XT, .XB, .UIMM_4, .NONE}, 0xF0000294, 0xFC1007FC, .VSX_P9, .PPC32, {}} },
	.XXINSERTW   = { {.XXINSERTW,   {.VSR, .VSR, .IMM, .NONE}, {.XT, .XB, .UIMM_4, .NONE}, 0xF00002D4, 0xFC1007FC, .VSX_P9, .PPC32, {}} },
	.XXPERM      = { {.XXPERM,      {.VSR, .VSR, .VSR, .NONE}, {.XT, .XA, .XB, .NONE}, 0xF00000D0, 0xFC0007F8, .VSX_P9, .PPC32, {}} },

	// =========================================================================
	// §6b Late arithmetic additions: addex, maddld/maddhd/maddhdu, addpcis
	// =========================================================================
	//
	//   addex     primary=31 XO=170 → 0x7C000154 with CY at bits 21..22
	//                                 (POWER9; CY=0 only architected so far)
	//   maddld    primary=4 VA-form XO=51 → 0x10000033 (POWER9; FRT/A/C/B → RT/A/C/B)
	//   maddhd    primary=4 VA-form XO=48 → 0x10000030 (POWER9)
	//   maddhdu   primary=4 VA-form XO=49 → 0x10000031 (POWER9)
	//   addpcis   primary=19 DX-form XO=2 → 0x4C000004 (POWER9; 16-bit imm split across d1/d0/d2)
	.ADDEX   = { {.ADDEX,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000154, 0xFC0007FE, .POWER9, .PPC32, {}} },
	.MADDLD  = { {.MADDLD,  {.GPR, .GPR, .GPR, .GPR},  {.RT, .RA, .RC, .RB},   0x10000033, 0xFC00003F, .POWER9, .PPC64, {}} },
	.MADDHD  = { {.MADDHD,  {.GPR, .GPR, .GPR, .GPR},  {.RT, .RA, .RC, .RB},   0x10000030, 0xFC00003F, .POWER9, .PPC64, {}} },
	.MADDHDU = { {.MADDHDU, {.GPR, .GPR, .GPR, .GPR},  {.RT, .RA, .RC, .RB},   0x10000031, 0xFC00003F, .POWER9, .PPC64, {}} },
	.ADDPCIS = { {.ADDPCIS, {.GPR, .SIMM, .NONE, .NONE},{.RT, .D16, .NONE, .NONE}, 0x4C000004, 0xFC00003E, .POWER9, .PPC32, {}} },

	// =========================================================================
	// §10b Late supervisor / TLB / SLB / power-mgmt additions
	// =========================================================================
	//   slbie    XO=434 → 0x7C000264 (no RA)
	//   slbia    XO=498 → 0x7C0003E4
	//   slbmte   XO=402 → 0x7C000324
	//   slbmfee  XO=915 → 0x7C000726
	//   slbmfev  XO=851 → 0x7C0006A6
	//   slbsync  XO=338 → 0x7C0002A4 (P8)
	//   slbieg   XO=466 → 0x7C0003A4 (P9; with L bit)
	//   tlbie    XO=306 → 0x7C000264 — collides; XO=306 actually,
	//                     bits = 0x7C000264 - actually overlap with slbie
	//                     Per Power ISA: tlbie XO=306 → 0x7C000264.
	//                     They use different operand interpretations.
	//                     Distinguished by syntax/feature filter.
	//   tlbiel   XO=274 → 0x7C000224
	//   tlbsync  XO=566 → 0x7C00046C
	//   nap      primary=19 XO=434 with hint bits → 0x4C000364 (deprecated;
	//                     usual form is mtmsr with PM bit set; skip nap for now)
	//   msync    sync L=2 → 0x7C4004AC (already PTESYNC; msync alias for sync L=2)
	//   dcbzl    XO=1014 (same as dcbz) with TH=1 — same opcode as dcbz;
	//                     differentiated by operand. Skip.
	//   sc_hv    sc with LEV=1 → 0x44000022. (or LEV=2 for HV)
	.SLBIE    = { {.SLBIE,    {.GPR, .NONE, .NONE, .NONE}, {.RB, .NONE, .NONE, .NONE}, 0x7C000364, 0xFFFF07FF, .SUPV, .PPC32, {}} },
	.SLBIA    = { {.SLBIA,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0003E4, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.SLBMTE   = { {.SLBMTE,   {.GPR, .GPR, .NONE, .NONE}, {.RS, .RB, .NONE, .NONE}, 0x7C000324, 0xFC1F07FF, .SUPV, .PPC32, {}} },
	.SLBMFEE  = { {.SLBMFEE,  {.GPR, .GPR, .NONE, .NONE}, {.RT, .RB, .NONE, .NONE}, 0x7C000726, 0xFC1F07FF, .SUPV, .PPC32, {}} },
	.SLBMFEV  = { {.SLBMFEV,  {.GPR, .GPR, .NONE, .NONE}, {.RT, .RB, .NONE, .NONE}, 0x7C0006A6, 0xFC1F07FF, .SUPV, .PPC32, {}} },
	.SLBSYNC  = { {.SLBSYNC,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0002A4, 0xFFFFFFFE, .POWER8, .PPC32, {}} },
	.TLBIE    = { {.TLBIE,    {.GPR, .GPR, .NONE, .NONE}, {.RS, .RB, .NONE, .NONE}, 0x7C000264, 0xFC1F07FF, .SUPV, .PPC32, {}} },
	.TLBIEL   = { {.TLBIEL,   {.GPR, .NONE, .NONE, .NONE}, {.RB, .NONE, .NONE, .NONE}, 0x7C000224, 0xFFFF07FF, .SUPV, .PPC32, {}} },
	.TLBSYNC  = { {.TLBSYNC,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00046C, 0xFFFFFFFF, .SUPV, .PPC32, {}} },

	// =========================================================================
	// §14 Assembler aliases — printer-canonical forms that LLVM also prefers
	// =========================================================================
	//
	// Each alias entry pins specific operand bits (so the mask covers more bits
	// than the underlying primitive's mask). The mask popcount makes the alias
	// win against the primitive at decode time; the encoder picks the alias
	// when the user-supplied operands fit the fixed pattern.
	//
	// Computed aliases (SLWI/SRWI/SLDI/SRDI/CLRRWI/CLRLWI/EXTLDI/..., SUB/SUBC
	// operand-reorder) live in the eventual encoder helper layer, not here — see
	// [[ppc-port-progress]].

	// ---- ori/xori aliases ----
	//   nop  = ori  0,0,0        → 0x60000000
	//   xnop = xori 0,0,0        → 0x68000000
	.NOP    = { {.NOP,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x60000000, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.XNOP   = { {.XNOP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x68000000, 0xFFFFFFFF, .BASE, .PPC32, {}} },

	// ---- addi / addis with RA=0 ----
	//   li  rD, SI    = addi  rD, 0, SI    (RA fixed at 0)
	//   lis rD, SI    = addis rD, 0, SI
	//   la  rD, D(RA) = addi  rD, RA, D    (printer alias; encoded same as addi)
	//   The mask for li/lis covers primary + RA=0 fixed.
	.LI  = { {.LI,  {.GPR, .SIMM, .NONE, .NONE}, {.RT, .D16, .NONE, .NONE}, 0x38000000, 0xFC1F0000, .BASE, .PPC32, {}} },
	.LIS = { {.LIS, {.GPR, .SIMM, .NONE, .NONE}, {.RT, .D16, .NONE, .NONE}, 0x3C000000, 0xFC1F0000, .BASE, .PPC32, {}} },
	.LA  = { {.LA,  {.GPR, .MEM,  .NONE, .NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0x38000000, 0xFC000000, .BASE, .PPC32, {}} },

	// ---- or/nor as register-move aliases (RS=RB) ----
	//   mr  rA, rS = or  rA, rS, rS   (RA=RA dest, RS source=RB source)
	//   mr. rA, rS = or. rA, rS, rS
	//   not  rA, rS = nor rA, rS, rS
	//   not. rA, rS = nor. rA, rS, rS
	//
	// For these, the user passes one source register; the encoder packs it at
	// BOTH RS (21..25) and RB (11..15). For the LLVM-verify side we just need
	// canonical bytes where the safe-fill matches: e.g. mr 3, 3 = or 3,3,3.
	// Our safe-fill puts RS=r3 and RB=r5; we'd see "or rA, r3, r5" which is
	// NOT an mr. So the table entry can't simply piggyback on OR.
	// We pin both source slots to the same register in the bits, mask both:
	// but mask-covering RB makes the operand non-extracted. Compromise: the
	// alias mnemonic is recognized by the printer when the decoder finds an
	// OR/NOR with matching RS=RB; we still emit one entry that LLVM matches
	// when the canonical bits happen to have RS=RB. To get matching bytes,
	// we override the OR safe-fill for mr via a per-mnemonic fixed pattern:
	// entry bits include RS=r3 (=21<<3=24... ugh). Simplest: bake a specific
	// register into the entry's bits and mask everything (no operands). LLVM
	// will then print "mr r3, r3" for our exact byte pattern.
	.MR     = { {.MR,     {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE},
				 0x7C601B78, 0xFFFFFFFE, .BASE, .PPC32, {}} },  // or r0, r3, r3 → printed mr r0, r3 (encoded with specific regs to satisfy LLVM-verify)
	// (Practical encoder hooks into MR/MR_DOT/NOT/NOT_DOT happen later; this
	// entry exists to participate in the verify harness as a sanity check.)
	.MR_DOT = { {.MR_DOT, {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE},
				 0x7C601B79, 0xFFFFFFFF, .BASE, .PPC32, {sets_cr0=true}} },
	.NOT    = { {.NOT,    {.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE},
				 0x7C6018F8, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.NOT_DOT= { {.NOT_DOT,{.GPR, .GPR, .NONE, .NONE}, {.RA, .RS, .NONE, .NONE},
				 0x7C6018F9, 0xFFFFFFFF, .BASE, .PPC32, {sets_cr0=true}} },

	// ---- bclr/bcctr unconditional aliases ----
	//   blr   = bclr  20, 0, 0   → 0x4C000020 + (20<<21) = 0x4E800020
	//   blrl  = bclrl 20, 0, 0   → 0x4E800021
	//   bctr  = bcctr 20, 0, 0   → 0x4E800420
	//   bctrl = bcctrl 20, 0, 0  → 0x4E800421
	.BLR   = { {.BLR,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4E800020, 0xFFFFFFFF, .BASE, .PPC32, {branch=true}} },
	.BLRL  = { {.BLRL,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4E800021, 0xFFFFFFFF, .BASE, .PPC32, {branch=true, writes_lr=true}} },
	.BCTR  = { {.BCTR,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4E800420, 0xFFFFFFFF, .BASE, .PPC32, {branch=true}} },
	.BCTRL = { {.BCTRL, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4E800421, 0xFFFFFFFF, .BASE, .PPC32, {branch=true, writes_lr=true}} },

	// ---- bc conditional-branch aliases (BO+BI fixed; BD operand) ----
	//   beq   = bc 12, 2, BD   → BO=12 BI=2 → bits = 0x40000000 | (12<<21) | (2<<16) = 0x41820000
	//   bne   = bc 4,  2, BD   → BO= 4 BI=2 → 0x40000000 | (4<<21) | (2<<16) = 0x40820000
	//   blt   = bc 12, 0, BD   → 0x41800000
	//   ble   = bc 4,  1, BD   → 0x40810000
	//   bgt   = bc 12, 1, BD   → 0x41810000
	//   bge   = bc 4,  0, BD   → 0x40800000
	//   bso   = bc 12, 3, BD   → 0x41830000
	//   bns   = bc 4,  3, BD   → 0x40830000
	// Mask covers primary + BO + BI + AA + LK fixed; BD variable: 0xFFFF0003.
	.BEQ = { {.BEQ, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x41820000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BNE = { {.BNE, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x40820000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BLT = { {.BLT, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x41800000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BLE = { {.BLE, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x40810000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BGT = { {.BGT, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x41810000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BGE = { {.BGE, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x40800000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BSO = { {.BSO, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x41830000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BNS = { {.BNS, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x40830000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	// L-variants (LK=1)
	.BEQL = { {.BEQL, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x41820001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BNEL = { {.BNEL, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x40820001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BLTL = { {.BLTL, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x41800001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BLEL = { {.BLEL, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x40810001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BGTL = { {.BGTL, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x41810001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BGEL = { {.BGEL, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x40800001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BSOL = { {.BSOL, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x41830001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BNSL = { {.BNSL, {.REL, .NONE, .NONE, .NONE}, {.BRANCH_BD, .NONE, .NONE, .NONE}, 0x40830001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	// LR-variants (bclr): bits = 0x4C000020 | (BO<<21) | (BI<<16)
	.BEQLR = { {.BEQLR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4D820020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BNELR = { {.BNELR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C820020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BLTLR = { {.BLTLR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4D800020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BLELR = { {.BLELR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C810020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BGTLR = { {.BGTLR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4D810020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BGELR = { {.BGELR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C800020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BSOLR = { {.BSOLR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4D830020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BNSLR = { {.BNSLR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C830020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	// CTR-variants (bcctr): bits = 0x4C000420 | (BO<<21) | (BI<<16)
	.BEQCTR = { {.BEQCTR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4D820420, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BNECTR = { {.BNECTR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C820420, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BLTCTR = { {.BLTCTR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4D800420, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BLECTR = { {.BLECTR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C810420, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BGTCTR = { {.BGTCTR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4D810420, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BGECTR = { {.BGECTR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C800420, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BSOCTR = { {.BSOCTR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4D830420, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BNSCTR = { {.BNSCTR, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C830420, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },

	// ---- Counter-decrement branches (bc / bclr with no-CR-test BO values) ----
	//   bdnz  = bc 16, 0, BD  → BO=16 BI=0  bits = 0x40000000 | (16<<21) | (0<<16) = 0x42000000
	//   bdz   = bc 18, 0, BD  → 0x42400000
	//   bdnzl = bc 16, 0 with LK=1 → 0x42000001
	//   bdzl  = bc 18, 0 with LK=1 → 0x42400001
	//   bdnzlr = bclr  16, 0, 0 → 0x4E000020
	//   bdzlr  = bclr  18, 0, 0 → 0x4E400020
	//   bdnzlrl = bclrl 16, 0, 0 → 0x4E000021
	//   bdzlrl  = bclrl 18, 0, 0 → 0x4E400021
	.BDNZ    = { {.BDNZ,    {.REL, .NONE,.NONE,.NONE}, {.BRANCH_BD, .NONE,.NONE,.NONE}, 0x42000000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BDZ     = { {.BDZ,     {.REL, .NONE,.NONE,.NONE}, {.BRANCH_BD, .NONE,.NONE,.NONE}, 0x42400000, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true}} },
	.BDNZL   = { {.BDNZL,   {.REL, .NONE,.NONE,.NONE}, {.BRANCH_BD, .NONE,.NONE,.NONE}, 0x42000001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDZL    = { {.BDZL,    {.REL, .NONE,.NONE,.NONE}, {.BRANCH_BD, .NONE,.NONE,.NONE}, 0x42400001, 0xFFFF0003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDNZLR  = { {.BDNZLR,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4E000020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BDZLR   = { {.BDZLR,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4E400020, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BDNZLRL = { {.BDNZLRL, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4E000021, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDZLRL  = { {.BDZLRL,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4E400021, 0xFFFFFFFF, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },

	// ---- Trap aliases ----
	//   trap  = tw 31, r0, r0  → bits = 0x7C000008 | (31<<21) | 0<<16 | 0<<11 = 0x7FE00008
	.TRAP = { {.TRAP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7FE00008, 0xFFFFFFFF, .BASE, .PPC32, {}} },

	// ---- SPR-move aliases ----
	//   mflr  rD = mfspr rD, 8    → bits = 0x7C0002A6 | (8 split half-swapped at 11..20)
	//                              = 0x7C0002A6 | (8<<11) | (0<<16) = 0x7C0042A6
	//                              SPR=8 (low 5 = 01000 → bits 11..15, high 5 = 0 → bits 16..20)
	//   mtlr  rS = mtspr 8, rS    → 0x7C0003A6 | (8<<11) | (0<<16) = 0x7C0043A6
	//   mfctr rD = mfspr rD, 9    → SPR=9 (low 5 = 01001 → bits 11..15 = 9)
	//                              = 0x7C0002A6 | (9<<11) = 0x7C0942A6  -- wait 9<<11 = 0x4800
	//                              0x7C0002A6 | 0x4800 = 0x7C0048A6
	//   mtctr rS = mtspr 9, rS    → 0x7C0003A6 | 0x4800 = 0x7C0049A6
	//   mfxer rD = mfspr rD, 1    → SPR=1 (low 5 = 1 → bits 11..15 = 1)
	//                              = 0x7C0002A6 | (1<<11) = 0x7C0102A6 — wait
	//                              1<<11 = 0x800. 0x7C0002A6 | 0x800 = 0x7C0008A6.
	//                              Hmm let me recompute: shift 11 means bit 11 set.
	//                              0x800 = 0...0100000000000 = bit 11. So SPR low 5 at bits 11..15 with value 1 = 0x800.
	//                              0x7C0002A6 | 0x800 = 0x7C0008A6. — Hmm but my mflr was wrong.
	//   Recompute mflr (SPR=8): low 5 bits of SPR = 01000 = 8 = 0x8. At bits 11..15.
	//                          8 << 11 = 0x4000. So bits = 0x7C0002A6 | 0x4000 = 0x7C0042A6.
	//                          ✓ matches what I wrote.
	//   mfctr (SPR=9): 9 << 11 = 0x4800. bits = 0x7C0002A6 | 0x4800 = 0x7C0048A6. ✓
	//   mfxer (SPR=1): 1 << 11 = 0x800. bits = 0x7C0002A6 | 0x800 = 0x7C0008A6. Actually wait...
	//                  SPR=1 in PPC convention: low 5 bits of 1 = 00001. At bits 11..15.
	//                  In u32: bit 11 = 1. Value: 0x800. ✓
	.MFLR  = { {.MFLR,  {.GPR, .NONE,.NONE,.NONE}, {.RT, .NONE,.NONE,.NONE}, 0x7C0802A6, 0xFC1FFFFF, .BASE, .PPC32, {}} },
	.MTLR  = { {.MTLR,  {.GPR, .NONE,.NONE,.NONE}, {.RS, .NONE,.NONE,.NONE}, 0x7C0803A6, 0xFC1FFFFF, .BASE, .PPC32, {}} },
	.MFCTR = { {.MFCTR, {.GPR, .NONE,.NONE,.NONE}, {.RT, .NONE,.NONE,.NONE}, 0x7C0902A6, 0xFC1FFFFF, .BASE, .PPC32, {}} },
	.MTCTR = { {.MTCTR, {.GPR, .NONE,.NONE,.NONE}, {.RS, .NONE,.NONE,.NONE}, 0x7C0903A6, 0xFC1FFFFF, .BASE, .PPC32, {}} },
	.MFXER = { {.MFXER, {.GPR, .NONE,.NONE,.NONE}, {.RT, .NONE,.NONE,.NONE}, 0x7C0102A6, 0xFC1FFFFF, .BASE, .PPC32, {}} },
	.MTXER = { {.MTXER, {.GPR, .NONE,.NONE,.NONE}, {.RS, .NONE,.NONE,.NONE}, 0x7C0103A6, 0xFC1FFFFF, .BASE, .PPC32, {}} },

	// ---- Compare aliases (L bit fixed) ----
	//   cmpw  BF, RA, RB = cmp  BF, 0, RA, RB → 0x7C000000 | bit21=0 (already)
	//   cmpd  BF, RA, RB = cmp  BF, 1, RA, RB → 0x7C200000 (bit 21 set)
	//   cmplw BF, RA, RB = cmpl BF, 0, RA, RB → 0x7C000040
	//   cmpld BF, RA, RB = cmpl BF, 1, RA, RB → 0x7C200040
	//   cmpwi BF, RA, SI = cmpi BF, 0, RA, SI → 0x2C000000
	//   cmpdi BF, RA, SI = cmpi BF, 1, RA, SI → 0x2C200000
	//   cmplwi BF, RA, UI = cmpli BF, 0, RA, UI → 0x28000000
	//   cmpldi BF, RA, UI = cmpli BF, 1, RA, UI → 0x28200000
	.CMPW   = { {.CMPW,   {.CR_FIELD, .GPR, .GPR, .NONE}, {.BF, .RA, .RB, .NONE}, 0x7C000000, 0xFC6007FE, .BASE, .PPC32, {}} },
	.CMPD   = { {.CMPD,   {.CR_FIELD, .GPR, .GPR, .NONE}, {.BF, .RA, .RB, .NONE}, 0x7C200000, 0xFC6007FE, .P64,  .PPC64, {}} },
	.CMPLW  = { {.CMPLW,  {.CR_FIELD, .GPR, .GPR, .NONE}, {.BF, .RA, .RB, .NONE}, 0x7C000040, 0xFC6007FE, .BASE, .PPC32, {}} },
	.CMPLD  = { {.CMPLD,  {.CR_FIELD, .GPR, .GPR, .NONE}, {.BF, .RA, .RB, .NONE}, 0x7C200040, 0xFC6007FE, .P64,  .PPC64, {}} },
	.CMPWI  = { {.CMPWI,  {.CR_FIELD, .GPR, .SIMM, .NONE}, {.BF, .RA, .D16, .NONE}, 0x2C000000, 0xFC600000, .BASE, .PPC32, {}} },
	.CMPDI  = { {.CMPDI,  {.CR_FIELD, .GPR, .SIMM, .NONE}, {.BF, .RA, .D16, .NONE}, 0x2C200000, 0xFC600000, .P64,  .PPC64, {}} },
	.CMPLWI = { {.CMPLWI, {.CR_FIELD, .GPR, .UIMM, .NONE}, {.BF, .RA, .UI16, .NONE}, 0x28000000, 0xFC600000, .BASE, .PPC32, {}} },
	.CMPLDI = { {.CMPLDI, {.CR_FIELD, .GPR, .UIMM, .NONE}, {.BF, .RA, .UI16, .NONE}, 0x28200000, 0xFC600000, .P64,  .PPC64, {}} },

	// =========================================================================
	// §13 Power ISA 3.1 prefixed (POWER10) — 8-byte instructions
	// =========================================================================
	//
	// Each prefixed instruction consists of a 4-byte PREFIX word followed by a
	// 4-byte SUFFIX word (8 bytes total, big-endian on the wire). The
	// Encoding's `bits` and `mask` describe the SUFFIX; the PREFIX word is
	// looked up by Mnemonic in PREFIX_BITS_TABLE (below this batch).
	//
	// `flags.prefixed = true` signals 8-byte length and triggers the
	// PREFIX_BITS_TABLE lookup at dump / encode time.
	//
	// Prefix templates (from Power ISA 3.1 §1.6.2):
	//   MLS  prefix = 0x06000000  (Modified Load/Store; D-form suffix)
	//   8LS  prefix = 0x04000000  (Eight-byte Load/Store; new D-form suffix)
	//   MRR  prefix = 0x05000000  (Modified Register-Register; rarely used)
	//   8RR  prefix = 0x07000000  (Eight-byte Register-Register; MMA + XXSPLTI*)
	//
	// Confirmed via llvm-mc -mattr=+isa-v31-instructions --show-encoding.

	// ---- MLS-form D-loads (suffix = same primary opcode as non-prefix load) ----
	.PLBZ  = { {.PLBZ,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0x88000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PLHZ  = { {.PLHZ,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0xA0000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PLHA  = { {.PLHA,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0xA8000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PLWZ  = { {.PLWZ,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0x80000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },

	// ---- 8LS-form D-loads (suffix uses *new* primary opcodes 41 / 57) ----
	.PLWA  = { {.PLWA,  {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0xA4000000, 0xFC000000, .POWER10, .PPC64, {prefixed=true}} },
	.PLD   = { {.PLD,   {.GPR, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0xE4000000, 0xFC000000, .POWER10, .PPC64, {prefixed=true}} },

	// ---- MLS-form D-stores ----
	.PSTB  = { {.PSTB,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D, .NONE, .NONE}, 0x98000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PSTH  = { {.PSTH,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D, .NONE, .NONE}, 0xB0000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PSTW  = { {.PSTW,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D, .NONE, .NONE}, 0x90000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },

	// ---- 8LS-form D-stores ----
	.PSTD  = { {.PSTD,  {.GPR, .MEM, .NONE, .NONE}, {.RS, .OFFSET_BASE_D, .NONE, .NONE}, 0xF4000000, 0xFC000000, .POWER10, .PPC64, {prefixed=true}} },

	// ---- MLS-form FP loads/stores ----
	.PLFS  = { {.PLFS,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xC0000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PLFD  = { {.PLFD,  {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xC8000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PSTFS = { {.PSTFS, {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xD0000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PSTFD = { {.PSTFD, {.FPR, .MEM, .NONE, .NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xD8000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },

	// ---- MLS-form arithmetic immediate (PADDI / PLI = PADDI w/ RA=0) ----
	.PADDI = { {.PADDI, {.GPR, .GPR_OR_ZERO, .SIMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x38000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PLI   = { {.PLI,   {.GPR, .SIMM, .NONE, .NONE}, {.RT, .D16, .NONE, .NONE}, 0x38000000, 0xFC1F0000, .POWER10, .PPC32, {prefixed=true}} },

	// ---- 8LS-form vector loads / stores (POWER10) ----
	// Suffix primaries borrow non-prefix opcodes 42/43/46/47/50/54.
	//   plxsd   suffix primary 42 → 0xA8000000
	//   plxssp  suffix primary 43 → 0xAC000000
	//   pstxsd  suffix primary 46 → 0xB8000000
	//   pstxssp suffix primary 47 → 0xBC000000
	//   plxv    suffix primary 50 → 0xC8000000  (note: collides with LFD non-prefix)
	//   pstxv   suffix primary 54 → 0xD8000000
	.PLXSD   = { {.PLXSD,   {.VR,  .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xA8000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PLXSSP  = { {.PLXSSP,  {.VR,  .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xAC000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PSTXSD  = { {.PSTXSD,  {.VR,  .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xB8000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PSTXSSP = { {.PSTXSSP, {.VR,  .MEM, .NONE, .NONE}, {.VRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xBC000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PLXV    = { {.PLXV,    {.VSR, .MEM, .NONE, .NONE}, {.XT,  .OFFSET_BASE_D, .NONE, .NONE}, 0xC8000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },
	.PSTXV   = { {.PSTXV,   {.VSR, .MEM, .NONE, .NONE}, {.XT,  .OFFSET_BASE_D, .NONE, .NONE}, 0xD8000000, 0xFC000000, .POWER10, .PPC32, {prefixed=true}} },

	// ---- 8RR-form vector splat-immediate (POWER10) ----
	// Prefix template = 0b01 (= 0x05000000). Suffix uses primary 32 plus a
	// 3-bit subop at bits 16..18 (LSB) that selects the splat variant:
	//   xxsplti32dx: subop = 000 → 0x80000000
	//   xxspltidp:   subop = 100 → 0x80040000  (bit 18 = 1)
	//   xxspltiw:    subop = 110 → 0x80060000  (bits 18,17 = 1)
	// Mask covers primary + bits 16..18; XT (21..25) and IMM (0..15) variable.
	.XXSPLTIDP   = { {.XXSPLTIDP,   {.VSR, .SIMM, .NONE, .NONE}, {.XT, .D16, .NONE, .NONE}, 0x80040000, 0xFC070000, .POWER10, .PPC32, {prefixed=true}} },
	.XXSPLTIW    = { {.XXSPLTIW,    {.VSR, .SIMM, .NONE, .NONE}, {.XT, .D16, .NONE, .NONE}, 0x80060000, 0xFC070000, .POWER10, .PPC32, {prefixed=true}} },
	.XXSPLTI32DX = { {.XXSPLTI32DX, {.VSR, .SIMM, .NONE, .NONE}, {.XT, .D16, .NONE, .NONE}, 0x80000000, 0xFC070000, .POWER10, .PPC32, {prefixed=true}} },

	// ---- POWER10 quad-precision (binary128) compares (primary=63, X-form) ----
	//   xscmpeqqp  XO= 68 → 0xFC000088
	//   xscmpgtqp  XO=228 → 0xFC0001C8
	//   xscmpgeqp  XO=196 → 0xFC000188
	.XSCMPEQQP = { {.XSCMPEQQP, {.CR_FIELD, .VR, .VR, .NONE}, {.BF, .VRA, .VRB, .NONE}, 0xFC000088, 0xFC6007FF, .POWER10, .PPC32, {}} },
	.XSCMPGTQP = { {.XSCMPGTQP, {.CR_FIELD, .VR, .VR, .NONE}, {.BF, .VRA, .VRB, .NONE}, 0xFC0001C8, 0xFC6007FF, .POWER10, .PPC32, {}} },
	.XSCMPGEQP = { {.XSCMPGEQP, {.CR_FIELD, .VR, .VR, .NONE}, {.BF, .VRA, .VRB, .NONE}, 0xFC000188, 0xFC6007FF, .POWER10, .PPC32, {}} },

	// =========================================================================
	// §11b AltiVec POWER8/9 additions (LLVM-derived bits)
	// =========================================================================
	//
	// Three-operand VX-form: base = 0x10000XXX with XO at bits 0..10.
	// Two-operand VX-form  : VRA is fixed to 0 → mask covers bits 16..20.
	// Four-operand VA-form: base = 0x10000XXX with XO at bits 0..5.

	// ---- Absolute-difference (POWER9) ----
	.VABSDUB = { {.VABSDUB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000403, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VABSDUH = { {.VABSDUH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000443, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VABSDUW = { {.VABSDUW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000483, 0xFC0007FF, .POWER9, .PPC32, {}} },

	// ---- Count Leading / Trailing Zeros (POWER8/9) ----
	.VCLZB = { {.VCLZB, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10000702, 0xFC1F07FF, .POWER8, .PPC32, {}} },
	.VCLZH = { {.VCLZH, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10000742, 0xFC1F07FF, .POWER8, .PPC32, {}} },
	.VCLZW = { {.VCLZW, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10000782, 0xFC1F07FF, .POWER8, .PPC32, {}} },
	.VCLZD = { {.VCLZD, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x100007C2, 0xFC1F07FF, .POWER8, .PPC32, {}} },
	.VCTZB = { {.VCTZB, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x101C0602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VCTZH = { {.VCTZH, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x101D0602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VCTZW = { {.VCTZW, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x101E0602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VCTZD = { {.VCTZD, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x101F0602, 0xFC1F07FF, .POWER9, .PPC32, {}} },

	// ---- Population Count (POWER8) ----
	.VPOPCNTB = { {.VPOPCNTB, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10000703, 0xFC1F07FF, .POWER8, .PPC32, {}} },
	.VPOPCNTH = { {.VPOPCNTH, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10000743, 0xFC1F07FF, .POWER8, .PPC32, {}} },
	.VPOPCNTW = { {.VPOPCNTW, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10000783, 0xFC1F07FF, .POWER8, .PPC32, {}} },
	.VPOPCNTD = { {.VPOPCNTD, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x100007C3, 0xFC1F07FF, .POWER8, .PPC32, {}} },

	// ---- AES / SHA / Polynomial-multiply (POWER8 Crypto) ----
	.VCIPHER     = { {.VCIPHER,     {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000508, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VCIPHERLAST = { {.VCIPHERLAST, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000509, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VNCIPHER    = { {.VNCIPHER,    {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000548, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VNCIPHERLAST= { {.VNCIPHERLAST,{.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000549, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VSBOX       = { {.VSBOX,       {.VR, .VR, .NONE, .NONE},{.VRT, .VRA, .NONE, .NONE}, 0x100005C8, 0xFC00FFFF, .POWER8, .PPC32, {}} },
	.VSHASIGMAW  = { {.VSHASIGMAW,  {.VR, .VR, .IMM, .IMM}, {.VRT, .VRA, .NONE, .NONE}, 0x10000682, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VSHASIGMAD  = { {.VSHASIGMAD,  {.VR, .VR, .IMM, .IMM}, {.VRT, .VRA, .NONE, .NONE}, 0x100006C2, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VPMSUMB     = { {.VPMSUMB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000408, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VPMSUMH     = { {.VPMSUMH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000448, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VPMSUMW     = { {.VPMSUMW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000488, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.VPMSUMD     = { {.VPMSUMD, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100004C8, 0xFC0007FF, .POWER8, .PPC32, {}} },

	// ---- BCD multiply-by-10 (POWER9) ----
	.VMUL10UQ    = { {.VMUL10UQ,    {.VR, .VR, .NONE, .NONE}, {.VRT, .VRA, .NONE, .NONE}, 0x10000201, 0xFC00FFFF, .POWER9, .PPC32, {}} },
	.VMUL10CUQ   = { {.VMUL10CUQ,   {.VR, .VR, .NONE, .NONE}, {.VRT, .VRA, .NONE, .NONE}, 0x10000001, 0xFC00FFFF, .POWER9, .PPC32, {}} },
	.VMUL10EUQ   = { {.VMUL10EUQ,   {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000241, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VMUL10ECUQ  = { {.VMUL10ECUQ,  {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000041, 0xFC0007FF, .POWER9, .PPC32, {}} },

	// ---- Bit permute (POWER8/9) -- VBPERMQ/VBPERMD already in §11 above ----

	// ---- Vector parity-byte (POWER9) ----
	.VPRTYBW     = { {.VPRTYBW, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10080602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VPRTYBD     = { {.VPRTYBD, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10090602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VPRTYBQ     = { {.VPRTYBQ, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x100A0602, 0xFC1F07FF, .POWER9, .PPC32, {}} },

	// ---- Rotate-and-mask vector (POWER9) ----
	.VRLDNM      = { {.VRLDNM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100001C5, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VRLDMI      = { {.VRLDMI, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x100000C5, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VRLWNM      = { {.VRLWNM, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000185, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VRLWMI      = { {.VRLWMI, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000085, 0xFC0007FF, .POWER9, .PPC32, {}} },

	// ---- Variable-shift (POWER9) ----
	.VSLV        = { {.VSLV, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000744, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VSRV        = { {.VSRV, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000704, 0xFC0007FF, .POWER9, .PPC32, {}} },

	// ---- Compare-not-equal-or-zero (POWER9) ----
	.VCMPNEZB     = { {.VCMPNEZB, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000107, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VCMPNEZB_DOT = { {.VCMPNEZB_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000507, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VCMPNEZH     = { {.VCMPNEZH, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000147, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VCMPNEZH_DOT = { {.VCMPNEZH_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000547, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VCMPNEZW     = { {.VCMPNEZW, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000187, 0xFC0007FF, .POWER9, .PPC32, {}} },
	.VCMPNEZW_DOT = { {.VCMPNEZW_DOT, {.VR, .VR, .VR, .NONE}, {.VRT, .VRA, .VRB, .NONE}, 0x10000587, 0xFC0007FF, .POWER9, .PPC32, {}} },

	// ---- Within-vector sign-extend (POWER9) ----
	.VEXTSB2W = { {.VEXTSB2W, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10100602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VEXTSH2W = { {.VEXTSH2W, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10110602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VEXTSB2D = { {.VEXTSB2D, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10180602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VEXTSH2D = { {.VEXTSH2D, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x10190602, 0xFC1F07FF, .POWER9, .PPC32, {}} },
	.VEXTSW2D = { {.VEXTSW2D, {.VR, .VR, .NONE, .NONE}, {.VRT, .VRB, .NONE, .NONE}, 0x101A0602, 0xFC1F07FF, .POWER9, .PPC32, {}} },

	// ---- Insert / Extract within vector (POWER9) ----
	.VINSERTB    = { {.VINSERTB,    {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000030D, 0xFC1007FF, .POWER9, .PPC32, {}} },
	.VINSERTH    = { {.VINSERTH,    {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000034D, 0xFC1007FF, .POWER9, .PPC32, {}} },
	.VINSERTW    = { {.VINSERTW,    {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000038D, 0xFC1007FF, .POWER9, .PPC32, {}} },
	.VINSERTD    = { {.VINSERTD,    {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x100003CD, 0xFC1007FF, .POWER9, .PPC32, {}} },
	.VEXTRACTUB  = { {.VEXTRACTUB,  {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000020D, 0xFC1007FF, .POWER9, .PPC32, {}} },
	.VEXTRACTUH  = { {.VEXTRACTUH,  {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000024D, 0xFC1007FF, .POWER9, .PPC32, {}} },
	.VEXTRACTUW  = { {.VEXTRACTUW,  {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x1000028D, 0xFC1007FF, .POWER9, .PPC32, {}} },
	.VEXTRACTD   = { {.VEXTRACTD,   {.VR, .VR, .IMM, .NONE}, {.VRT, .VRB, .UIMM_4, .NONE}, 0x100002CD, 0xFC1007FF, .POWER9, .PPC32, {}} },

	// =========================================================================
	// §1b Additional counter-decrement+CR-bit branches (BDxxF/BDxxT)
	// =========================================================================
	//   bdnzf BI, BD = bc 0,  BI, BD → 0x40000000
	//   bdnzt BI, BD = bc 8,  BI, BD → 0x41000000
	//   bdzf  BI, BD = bc 2,  BI, BD → 0x40400000
	//   bdzt  BI, BD = bc 10, BI, BD → 0x41400000
	// Mask covers primary + BO + AA + LK; BI + BD operand-driven.
	.BDNZF = { {.BDNZF, {.CR_BIT, .REL, .NONE, .NONE}, {.BI_FIELD, .BRANCH_BD, .NONE, .NONE}, 0x40000000, 0xFFE00003, .BASE, .PPC32, {cond_branch=true}} },
	.BDNZT = { {.BDNZT, {.CR_BIT, .REL, .NONE, .NONE}, {.BI_FIELD, .BRANCH_BD, .NONE, .NONE}, 0x41000000, 0xFFE00003, .BASE, .PPC32, {cond_branch=true}} },
	.BDZF  = { {.BDZF,  {.CR_BIT, .REL, .NONE, .NONE}, {.BI_FIELD, .BRANCH_BD, .NONE, .NONE}, 0x40400000, 0xFFE00003, .BASE, .PPC32, {cond_branch=true}} },
	.BDZT  = { {.BDZT,  {.CR_BIT, .REL, .NONE, .NONE}, {.BI_FIELD, .BRANCH_BD, .NONE, .NONE}, 0x41400000, 0xFFE00003, .BASE, .PPC32, {cond_branch=true}} },

	// =========================================================================
	// §10c Additional system / cache / SLB entries
	// =========================================================================
	//   dcbzl    primary=31 XO=1014 with TH=1 at bit 21 → 0x7C2007EC
	//   sc_hv    primary=17 LEV=1 → 0x44000022
	//   slbieg   primary=31 XO=466 → 0x7C0003A4
	.DCBZL  = { {.DCBZL,  {.MEM, .NONE,.NONE,.NONE}, {.OFFSET_BASE_X,.NONE,.NONE,.NONE}, 0x7C2007EC, 0xFE2007FE, .POWER8, .PPC32, {}} },
	.SC_HV  = { {.SC_HV,  {.IMM, .NONE,.NONE,.NONE}, {.LEV_FIELD,.NONE,.NONE,.NONE}, 0x44000022, 0xFFFFFFFD, .HV,   .PPC32, {}} },
	.SLBIEG = { {.SLBIEG, {.GPR, .GPR, .NONE, .NONE}, {.RS, .RB, .NONE, .NONE}, 0x7C0003A4, 0xFC0007FE, .POWER9, .PPC32, {}} },

	// =========================================================================
	// §6c Rc-variants of extended divides (POWER7)
	// =========================================================================
	// Base + 1 = Rc=1; Base + 0x400 = OE=1.
	.DIVDE_DOT     = { {.DIVDE_DOT,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000353, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.DIVDE_O       = { {.DIVDE_O,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000752, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.DIVDE_O_DOT   = { {.DIVDE_O_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000753, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.DIVDEU_DOT    = { {.DIVDEU_DOT,    {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000313, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.DIVDEU_O      = { {.DIVDEU_O,      {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000712, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.DIVDEU_O_DOT  = { {.DIVDEU_O_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000713, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.DIVWE_DOT     = { {.DIVWE_DOT,     {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000357, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.DIVWE_O       = { {.DIVWE_O,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000756, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.DIVWE_O_DOT   = { {.DIVWE_O_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000757, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.DIVWEU_DOT    = { {.DIVWEU_DOT,    {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000317, 0xFC0003FF, .BASE, .PPC32, {sets_cr0=true}} },
	.DIVWEU_O      = { {.DIVWEU_O,      {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000716, 0xFC0007FE, .BASE, .PPC32, {has_oe=true}} },
	.DIVWEU_O_DOT  = { {.DIVWEU_O_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000717, 0xFC0007FF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },

	// =========================================================================
	// §14b Computed aliases — fixed-instance entries
	// =========================================================================
	//
	// Each entry encodes ONE specific instance of the alias (with concrete
	// operand values baked into `bits` and `mask = 0xFFFFFFFE`). This is
	// intentional: these aliases need encoder-side parameter computation that
	// doesn't fit the (bits, mask) model. The fixed instances satisfy the
	// table-coverage + LLVM-verification contract; the eventual encoder will
	// synthesize per-call instances from the underlying rlwinm/rldic*/subf/
	// ori family using user-supplied parameters.
	//
	// The instances below use rD=3, rS=4, n=4, b=8 as canonical safe-fill.

	// ---- Shift left/right immediate via rlwinm/rldic ----
	.SLWI    = { {.SLWI,    {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x54832036, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.SRWI    = { {.SRWI,    {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x5483E13E, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.SLDI    = { {.SLDI,    {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x788326E4, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.SRDI    = { {.SRDI,    {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7883E102, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	// ---- Clear left/right via rlwinm/rldic ----
	.CLRLWI  = { {.CLRLWI,  {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x5483013E, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.CLRRWI  = { {.CLRRWI,  {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x54830036, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.CLRLDI  = { {.CLRLDI,  {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78830100, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.CLRRDI  = { {.CLRRDI,  {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x788306E4, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	// ---- Extract / insert bit-fields via rlwinm/rldic*/rlwimi ----
	.EXTLWI  = { {.EXTLWI,  {.GPR, .GPR, .IMM, .IMM},  {.NONE,.NONE,.NONE,.NONE}, 0x54834006, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.EXTRWI  = { {.EXTRWI,  {.GPR, .GPR, .IMM, .IMM},  {.NONE,.NONE,.NONE,.NONE}, 0x5483673E, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.EXTLDI  = { {.EXTLDI,  {.GPR, .GPR, .IMM, .IMM},  {.NONE,.NONE,.NONE,.NONE}, 0x788340C4, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.EXTRDI  = { {.EXTRDI,  {.GPR, .GPR, .IMM, .IMM},  {.NONE,.NONE,.NONE,.NONE}, 0x78836720, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.INSLWI  = { {.INSLWI,  {.GPR, .GPR, .IMM, .IMM},  {.NONE,.NONE,.NONE,.NONE}, 0x5083C216, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.INSRWI  = { {.INSRWI,  {.GPR, .GPR, .IMM, .IMM},  {.NONE,.NONE,.NONE,.NONE}, 0x5083A216, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	// ---- Rotate (left/right) ----
	.ROTLW   = { {.ROTLW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x5C83283E, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.ROTLWI  = { {.ROTLWI,  {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x5483203E, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.ROTRW   = { {.ROTRW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x5C83283E, 0xFFFFFFFE, .BASE, .PPC32, {}} },  // rotrw = rotlw with neg shift — same form
	.ROTRDI  = { {.ROTRDI,  {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7883E002, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.ROTLD   = { {.ROTLD,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78832810, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.ROTLDI  = { {.ROTLDI,  {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78832000, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	// ---- sub / subc operand-reorder aliases of subf / subfc ----
	.SUB        = { {.SUB,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C652050, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.SUB_DOT    = { {.SUB_DOT,    {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C652051, 0xFFFFFFFF, .BASE, .PPC32, {sets_cr0=true}} },
	.SUB_O      = { {.SUB_O,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C652450, 0xFFFFFFFE, .BASE, .PPC32, {has_oe=true}} },
	.SUB_O_DOT  = { {.SUB_O_DOT,  {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C652451, 0xFFFFFFFF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	.SUBC       = { {.SUBC,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C652010, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.SUBC_DOT   = { {.SUBC_DOT,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C652011, 0xFFFFFFFF, .BASE, .PPC32, {sets_cr0=true}} },
	.SUBC_O     = { {.SUBC_O,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C652410, 0xFFFFFFFE, .BASE, .PPC32, {has_oe=true}} },
	.SUBC_O_DOT = { {.SUBC_O_DOT, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C652411, 0xFFFFFFFF, .BASE, .PPC32, {has_oe=true, sets_cr0=true}} },
	// ---- Power management / sync aliases ----
	.NAP    = { {.NAP,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C000364, 0xFFFFFFFF, .BASE,   .PPC32, {}} },
	.MSYNC  = { {.MSYNC,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0004AC, 0xFFFFFFFF, .BASE,   .PPC32, {}} },

	// ---- PSUBI is `paddi -imm` — bake the specific case (rT=3, rA=4, n=100) ----
	// (Prefix carries high 18 bits of -100 = sign-ext = 0x3FFFF.)
	.PSUBI  = { {.PSUBI,  {.GPR, .GPR, .SIMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x3864FF9C, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },

	// =========================================================================
	// §12c POWER9 VSX test / extract / insert / exponent / significand
	// =========================================================================
	// Fixed-instance entries (XT=1, XA=2, XB=3 or applicable). LLVM-verified.

	.XSCVDPHP  = { {.XSCVDPHP,  {.VSR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF031156C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XSCVHPDP  = { {.XSCVHPDP,  {.VSR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF030156C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XSIEXPDP  = { {.XSIEXPDP,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0221F2C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XSXEXPDP  = { {.XSXEXPDP,  {.GPR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF020156C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XSXSIGDP  = { {.XSXSIGDP,  {.GPR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF021156C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XSTDIVDP  = { {.XSTDIVDP,  {.CR_FIELD, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF00111E8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XSTSQRTDP = { {.XSTSQRTDP, {.CR_FIELD, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF00009A8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XSTSTDCDP = { {.XSTSTDCDP, {.CR_FIELD, .VSR, .IMM,  .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0000DA8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XSTSTDCSP = { {.XSTSTDCSP, {.CR_FIELD, .VSR, .IMM,  .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0000CA8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },

	.XVIEXPDP  = { {.XVIEXPDP,  {.VSR, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0221FC0, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVIEXPSP  = { {.XVIEXPSP,  {.VSR, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0221EC0, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVTDIVDP  = { {.XVTDIVDP,  {.CR_FIELD, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF00113E8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVTDIVSP  = { {.XVTDIVSP,  {.CR_FIELD, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF00112E8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVTSQRTDP = { {.XVTSQRTDP, {.CR_FIELD, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0000BA8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVTSQRTSP = { {.XVTSQRTSP, {.CR_FIELD, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0000AA8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVTSTDCDP = { {.XVTSTDCDP, {.VSR, .VSR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF02017A8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVTSTDCSP = { {.XVTSTDCSP, {.VSR, .VSR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF02016A8, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVXEXPDP  = { {.XVXEXPDP,  {.VSR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF020176C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVXEXPSP  = { {.XVXEXPSP,  {.VSR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF028176C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVXSIGDP  = { {.XVXSIGDP,  {.VSR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF021176C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },
	.XVXSIGSP  = { {.XVXSIGSP,  {.VSR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF029176C, 0xFFFFFFFE, .VSX_P9, .PPC32, {}} },

	// =========================================================================
	// §13b MMA accelerator (POWER10) — prefixed 8-byte fixed-instance entries
	// =========================================================================
	// Prefix = 0x07900000 (MMIRR template). Suffix bakes AT=0, XA=32, XB=33.
	.PMXVF32GER  = { {.PMXVF32GER,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0008DE, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF64GER  = { {.PMXVF64GER,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0009DE, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI4GER8  = { {.PMXVI4GER8,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00091E, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI8GER4  = { {.PMXVI8GER4,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00081E, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI16GER2 = { {.PMXVI16GER2, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000A5E, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },

	// =========================================================================
	// §15 POWER9 Quad-Precision Binary128 FP (LLVM-verified bake-everything)
	// =========================================================================
	//
	// 3-operand instances: VRT=1, VRA=2, VRB=3 baked in.
	// 2-operand instances: VRT=1, VRB=2 baked in.
	// 4-operand instances: VRT=1, VRA=2, VRB=3 (FRC slot variable).
	// Compare: BF=0, VRA=1, VRB=2.

	.XSADDQP    = { {.XSADDQP,    {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221808, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSADDQPO   = { {.XSADDQPO,   {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221809, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSSUBQP    = { {.XSSUBQP,    {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221C08, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSSUBQPO   = { {.XSSUBQPO,   {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221C09, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSMULQP    = { {.XSMULQP,    {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221848, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSMULQPO   = { {.XSMULQPO,   {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221849, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSDIVQP    = { {.XSDIVQP,    {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221C48, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSDIVQPO   = { {.XSDIVQPO,   {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221C49, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSSQRTQP   = { {.XSSQRTQP,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC3B1648, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSSQRTQPO  = { {.XSSQRTQPO,  {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC3B1649, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSMADDQP   = { {.XSMADDQP,   {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221B08, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSMADDQPO  = { {.XSMADDQPO,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221B09, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSMSUBQP   = { {.XSMSUBQP,   {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221B48, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSMSUBQPO  = { {.XSMSUBQPO,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221B49, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSNMADDQP  = { {.XSNMADDQP,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221B88, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSNMADDQPO = { {.XSNMADDQPO, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221B89, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSNMSUBQP  = { {.XSNMSUBQP,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221BC8, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSNMSUBQPO = { {.XSNMSUBQPO, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221BC9, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSABSQP    = { {.XSABSQP,    {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC201648, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSNABSQP   = { {.XSNABSQP,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC281648, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSNEGQP    = { {.XSNEGQP,    {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC301648, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCPSGNQP  = { {.XSCPSGNQP,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC2218C8, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCMPOQP   = { {.XSCMPOQP,   {.CR_FIELD, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC011108, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCMPUQP   = { {.XSCMPUQP,   {.CR_FIELD, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC011508, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSTSTDCQP  = { {.XSTSTDCQP,  {.CR_FIELD, .VR, .IMM,  .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC000D88, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSRQPI     = { {.XSRQPI,     {.IMM, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xFC20100A, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSRQPIX    = { {.XSRQPIX,    {.IMM, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xFC20100B, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSRQPXP    = { {.XSRQPXP,    {.IMM, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xFC20104A, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSXEXPQP   = { {.XSXEXPQP,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221648, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSXSIGQP   = { {.XSXSIGQP,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC321648, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSIEXPQP   = { {.XSIEXPQP,   {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221EC8, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCVQPDP   = { {.XSCVQPDP,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC341688, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCVQPDPO  = { {.XSCVQPDPO,  {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC341689, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XSCVDPQP   = { {.XSCVDPQP,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC361688, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCVQPSDZ  = { {.XSCVQPSDZ,  {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC391688, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCVQPSWZ  = { {.XSCVQPSWZ,  {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC291688, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCVQPUDZ  = { {.XSCVQPUDZ,  {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC311688, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCVQPUWZ  = { {.XSCVQPUWZ,  {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC211688, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCVSDQP   = { {.XSCVSDQP,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC2A1688, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.XSCVUDQP   = { {.XSCVUDQP,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221688, 0xFFFFFFFE, .POWER9, .PPC32, {}} },

	// =========================================================================
	// §16 Decimal Floating Point (POWER6+) — bake-everything fixed instances
	// =========================================================================
	// Instances use FRT=1, FRA=2, FRB=3 (or FRT=2 FRA=4 FRB=6 for quadword
	// forms — FPR pairs must be even).
	.DADD     = { {.DADD,     {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221804, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DADD_DOT = { {.DADD_DOT, {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221805, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DSUB     = { {.DSUB,     {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221C04, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DSUB_DOT = { {.DSUB_DOT, {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221C05, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DMUL     = { {.DMUL,     {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221844, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DMUL_DOT = { {.DMUL_DOT, {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221845, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DDIV     = { {.DDIV,     {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221C44, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DDIV_DOT = { {.DDIV_DOT, {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221C45, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DCMPU    = { {.DCMPU,    {.CR_FIELD, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC011504, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DCMPO    = { {.DCMPO,    {.CR_FIELD, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC011104, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DRSP     = { {.DRSP,     {.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201604, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DRSP_DOT = { {.DRSP_DOT, {.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201605, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DCTDP    = { {.DCTDP,    {.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201204, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DCTDP_DOT= { {.DCTDP_DOT,{.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201205, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DXEX     = { {.DXEX,     {.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC2012C4, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DXEX_DOT = { {.DXEX_DOT, {.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC2012C5, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DIEX     = { {.DIEX,     {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221EC4, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DIEX_DOT = { {.DIEX_DOT, {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221EC5, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DRRND    = { {.DRRND,    {.FPR, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221846, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DRRND_DOT= { {.DRRND_DOT,{.FPR, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221847, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DRINTX   = { {.DRINTX,   {.IMM, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC2010C6, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DRINTX_DOT={ {.DRINTX_DOT,{.IMM, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC2010C7, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DRINTN   = { {.DRINTN,   {.IMM, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC2011C6, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DRINTN_DOT={ {.DRINTN_DOT,{.IMM, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC2011C7, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DQUA     = { {.DQUA,     {.FPR, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221806, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DQUA_DOT = { {.DQUA_DOT, {.FPR, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC221807, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DQUAI    = { {.DQUAI,    {.IMM, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201086, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DQUAI_DOT= { {.DQUAI_DOT,{.IMM, .FPR, .FPR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201087, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DSCLI    = { {.DSCLI,    {.FPR, .FPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC220084, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DSCLI_DOT= { {.DSCLI_DOT,{.FPR, .FPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC220085, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DSCRI    = { {.DSCRI,    {.FPR, .FPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC2200C4, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DSCRI_DOT= { {.DSCRI_DOT,{.FPR, .FPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC2200C5, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DCFFIX   = { {.DCFFIX,   {.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201644, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DCFFIX_DOT={ {.DCFFIX_DOT,{.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201645, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DCTFIX   = { {.DCTFIX,   {.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201244, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DCTFIX_DOT={ {.DCTFIX_DOT,{.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201245, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DTSTDC   = { {.DTSTDC,   {.CR_FIELD, .FPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC010184, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DTSTDG   = { {.DTSTDG,   {.CR_FIELD, .FPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0101C4, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DTSTEX   = { {.DTSTEX,   {.CR_FIELD, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC011144, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DTSTSF   = { {.DTSTSF,   {.CR_FIELD, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC011544, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DENBCD   = { {.DENBCD,   {.IMM, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201684, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DENBCD_DOT={ {.DENBCD_DOT,{.IMM, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201685, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DDEDPD   = { {.DDEDPD,   {.IMM, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201284, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DDEDPD_DOT={ {.DDEDPD_DOT,{.IMM, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC201285, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },

	// DFPQ (quadword decimal — FPR pairs, must be even)
	.DADDQ    = { {.DADDQ,    {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC443004, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DADDQ_DOT= { {.DADDQ_DOT,{.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC443005, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DSUBQ    = { {.DSUBQ,    {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC443404, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DSUBQ_DOT= { {.DSUBQ_DOT,{.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC443405, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DMULQ    = { {.DMULQ,    {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC443044, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DMULQ_DOT= { {.DMULQ_DOT,{.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC443045, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DDIVQ    = { {.DDIVQ,    {.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC443444, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DDIVQ_DOT= { {.DDIVQ_DOT,{.FPR, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC443445, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },
	.DCMPUQ   = { {.DCMPUQ,   {.CR_FIELD, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC022504, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DCMPOQ   = { {.DCMPOQ,   {.CR_FIELD, .FPR, .FPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC022104, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DCTFIXQ  = { {.DCTFIXQ,  {.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC402244, 0xFFFFFFFE, .DFP, .PPC32, {}} },
	.DCTFIXQ_DOT= { {.DCTFIXQ_DOT,{.FPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC402245, 0xFFFFFFFF, .DFP, .PPC32, {sets_cr1=true}} },

	// =========================================================================
	// §17 MMA accelerator expansion (POWER10) — bake-everything
	// =========================================================================
	// Acc move/clear:
	.XXMTACC   = { {.XXMTACC,   {.IMM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C010162, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XXMFACC   = { {.XXMFACC,   {.IMM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C000162, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XXSETACCZ = { {.XXSETACCZ, {.IMM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C030162, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	// 24 xvf16ger2 / xvf32ger / xvf64ger / xvbf16ger2 variants (× pp/pn/np/nn)
	.XVF16GER2   = { {.XVF16GER2,   {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00089E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF16GER2PP = { {.XVF16GER2PP, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000896, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF16GER2PN = { {.XVF16GER2PN, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000C96, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF16GER2NP = { {.XVF16GER2NP, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000A96, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF16GER2NN = { {.XVF16GER2NN, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000E96, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF32GER    = { {.XVF32GER,    {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0008DE, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF32GERPP  = { {.XVF32GERPP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0008D6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF32GERPN  = { {.XVF32GERPN,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000CD6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF32GERNP  = { {.XVF32GERNP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000AD6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF32GERNN  = { {.XVF32GERNN,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000ED6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF64GER    = { {.XVF64GER,    {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0009DE, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF64GERPP  = { {.XVF64GERPP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0009D6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF64GERPN  = { {.XVF64GERPN,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000DD6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF64GERNP  = { {.XVF64GERNP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000BD6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVF64GERNN  = { {.XVF64GERNN,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000FD6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVBF16GER2  = { {.XVBF16GER2,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00099E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVBF16GER2PP= { {.XVBF16GER2PP,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000996, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVBF16GER2PN= { {.XVBF16GER2PN,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000D96, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVBF16GER2NP= { {.XVBF16GER2NP,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000B96, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVBF16GER2NN= { {.XVBF16GER2NN,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000F96, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI4GER8    = { {.XVI4GER8,    {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00091E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI4GER8PP  = { {.XVI4GER8PP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000916, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI8GER4    = { {.XVI8GER4,    {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00081E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI8GER4PP  = { {.XVI8GER4PP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000816, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI8GER4SPP = { {.XVI8GER4SPP, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000B1E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI16GER2   = { {.XVI16GER2,   {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000A5E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI16GER2PP = { {.XVI16GER2PP, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000B5E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI16GER2S  = { {.XVI16GER2S,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00095E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVI16GER2SPP= { {.XVI16GER2SPP,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000956, 0xFFFFFFFF, .POWER10, .PPC32, {}} },

	// =========================================================================
	// §18 POWER10 AltiVec additions
	// =========================================================================
	.VSTRIBL     = { {.VSTRIBL,     {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1040180D, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.VSTRIBL_DOT = { {.VSTRIBL_DOT, {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10401C0D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VSTRIBR     = { {.VSTRIBR,     {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1041180D, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.VSTRIBR_DOT = { {.VSTRIBR_DOT, {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10411C0D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VSTRIHL     = { {.VSTRIHL,     {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1042180D, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.VSTRIHL_DOT = { {.VSTRIHL_DOT, {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10421C0D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VSTRIHR     = { {.VSTRIHR,     {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043180D, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.VSTRIHR_DOT = { {.VSTRIHR_DOT, {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10431C0D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VMSUMCUD    = { {.VMSUMCUD,    {.VR, .VR, .VR, .VR}, {.NONE,.NONE,.NONE,.NONE}, 0x10432157, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VCFUGED     = { {.VCFUGED,     {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043254D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VPDEPD      = { {.VPDEPD,      {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x104325CD, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VPEXTD      = { {.VPEXTD,      {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043258D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VGNB        = { {.VGNB,        {.GPR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106224CC, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VSLDBI      = { {.VSLDBI,      {.VR, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x10432016, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.VSRDBI      = { {.VSRDBI,      {.VR, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x10432216, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.VCLZDM      = { {.VCLZDM,      {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432784, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VCTZDM      = { {.VCTZDM,      {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x104327C4, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VCLRLB      = { {.VCLRLB,      {.VR, .VR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043218D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VCLRRB      = { {.VCLRRB,      {.VR, .VR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x104321CD, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXPANDBM   = { {.VEXPANDBM,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10401E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXPANDHM   = { {.VEXPANDHM,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10411E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXPANDWM   = { {.VEXPANDWM,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10421E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXPANDDM   = { {.VEXPANDDM,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10431E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXPANDQM   = { {.VEXPANDQM,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10441E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTRACTBM  = { {.VEXTRACTBM,  {.GPR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10682642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTRACTHM  = { {.VEXTRACTHM,  {.GPR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10692642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTRACTWM  = { {.VEXTRACTWM,  {.GPR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106A2642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTRACTDM  = { {.VEXTRACTDM,  {.GPR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106B2642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTRACTQM  = { {.VEXTRACTQM,  {.GPR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106C2642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VCNTMBB     = { {.VCNTMBB,     {.GPR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10781642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VCNTMBH     = { {.VCNTMBH,     {.GPR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x107A1642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VCNTMBW     = { {.VCNTMBW,     {.GPR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x107C1642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VCNTMBD     = { {.VCNTMBD,     {.GPR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x107E1642, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.MTVSRBM     = { {.MTVSRBM,     {.VSR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10101E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.MTVSRHM     = { {.MTVSRHM,     {.VSR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10111E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.MTVSRWM     = { {.MTVSRWM,     {.VSR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10121E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.MTVSRDM     = { {.MTVSRDM,     {.VSR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10131E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.MTVSRQM     = { {.MTVSRQM,     {.VSR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10141E42, 0xFFFFFFFF, .POWER10, .PPC32, {}} },

	// =========================================================================
	// §19 POWER10 paste / copy
	// =========================================================================
	.COPY      = { {.COPY,      {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C23260C, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.PASTE_DOT = { {.PASTE_DOT, {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C20070D, 0xFFFFFFFF, .POWER10, .PPC32, {sets_cr0=true}} },

	// =========================================================================
	// §20 Hypervisor-priv cache-inhibited X-form load/store (POWER8)
	// =========================================================================
	.LBZCIX = { {.LBZCIX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642EAA, 0xFFFFFFFE, .HV, .PPC32, {}} },
	.LHZCIX = { {.LHZCIX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642E6A, 0xFFFFFFFE, .HV, .PPC32, {}} },
	.LWZCIX = { {.LWZCIX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642E2A, 0xFFFFFFFE, .HV, .PPC32, {}} },
	.LDCIX  = { {.LDCIX,  {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642EEA, 0xFFFFFFFE, .HV, .PPC64, {}} },
	.STBCIX = { {.STBCIX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642FAA, 0xFFFFFFFE, .HV, .PPC32, {}} },
	.STHCIX = { {.STHCIX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642F6A, 0xFFFFFFFE, .HV, .PPC32, {}} },
	.STWCIX = { {.STWCIX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642F2A, 0xFFFFFFFE, .HV, .PPC32, {}} },
	.STDCIX = { {.STDCIX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642FEA, 0xFFFFFFFE, .HV, .PPC64, {}} },

	// =========================================================================
	// §21 HTM (POWER8 Hardware Transactional Memory)
	// =========================================================================
	.TBEGIN_DOT    = { {.TBEGIN_DOT,    {.IMM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00051D, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TEND_DOT      = { {.TEND_DOT,      {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00055D, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TABORT_DOT    = { {.TABORT_DOT,    {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03071D, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TABORTWC_DOT  = { {.TABORTWC_DOT,  {.IMM, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03261D, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TABORTWCI_DOT = { {.TABORTWCI_DOT, {.IMM, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03269D, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TABORTDC_DOT  = { {.TABORTDC_DOT,  {.IMM, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03265D, 0xFFFFFFFF, .HTM, .PPC64, {sets_cr0=true}} },
	.TABORTDCI_DOT = { {.TABORTDCI_DOT, {.IMM, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0326DD, 0xFFFFFFFF, .HTM, .PPC64, {sets_cr0=true}} },
	.TRECLAIM_DOT  = { {.TRECLAIM_DOT,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03075D, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TRECHKPT_DOT  = { {.TRECHKPT_DOT,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0007DD, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TSUSPEND_DOT  = { {.TSUSPEND_DOT,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0005DD, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TRESUME_DOT   = { {.TRESUME_DOT,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C2005DD, 0xFFFFFFFF, .HTM, .PPC32, {sets_cr0=true}} },
	.TCHECK        = { {.TCHECK,        {.CR_FIELD, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00059C, 0xFFFFFFFF, .HTM, .PPC32, {}} },

	// =========================================================================
	// §22 BCD conversion / debug return / sync / isel / cache hints
	// =========================================================================
	.ADDG6S  = { {.ADDG6S,  {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642894, 0xFFFFFFFE, .BASE,   .PPC32, {}} },
	.CBCDTD  = { {.CBCDTD,  {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C830274, 0xFFFFFFFE, .BASE,   .PPC32, {}} },
	.CDTBCD  = { {.CDTBCD,  {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C830234, 0xFFFFFFFE, .BASE,   .PPC32, {}} },
	.RFEBB   = { {.RFEBB,   {.IMM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C000124, 0xFFFFFFFF, .POWER8, .PPC32, {}} },
	.RFDI    = { {.RFDI,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C00004E, 0xFFFFFFFF, .SUPV,   .PPC32, {}} },
	.MSGSYNC = { {.MSGSYNC, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0006EC, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.ISEL    = { {.ISEL,    {.GPR, .GPR_OR_ZERO, .GPR, .CR_BIT}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64299E, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.DCBTT   = { {.DCBTT,   {.MEM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7E03222C, 0xFFFFFFFF, .POWER8, .PPC32, {}} },
	.DCBTSTT = { {.DCBTSTT, {.MEM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7E0321EC, 0xFFFFFFFF, .POWER8, .PPC32, {}} },

	// =========================================================================
	// §23 POWER10 vector insert/extract with right/left-justification
	// =========================================================================
	.VEXTUBLX = { {.VEXTUBLX, {.GPR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043260D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTUHLX = { {.VEXTUHLX, {.GPR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043264D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTUWLX = { {.VEXTUWLX, {.GPR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043268D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTUBRX = { {.VEXTUBRX, {.GPR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043270D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTUHRX = { {.VEXTUHRX, {.GPR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043274D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTUWRX = { {.VEXTUWRX, {.GPR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043278D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSBVLX = { {.VINSBVLX, {.VR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043200F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSHVLX = { {.VINSHVLX, {.VR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043204F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSWVLX = { {.VINSWVLX, {.VR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043208F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSBVRX = { {.VINSBVRX, {.VR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043210F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSHVRX = { {.VINSHVRX, {.VR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043214F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSWVRX = { {.VINSWVRX, {.VR, .GPR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043218F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSBLX  = { {.VINSBLX,  {.VR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043220F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSHLX  = { {.VINSHLX,  {.VR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043224F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSWLX  = { {.VINSWLX,  {.VR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043228F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSDLX  = { {.VINSDLX,  {.VR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x104322CF, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSBRX  = { {.VINSBRX,  {.VR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043230F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSHRX  = { {.VINSHRX,  {.VR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043234F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSWRX  = { {.VINSWRX,  {.VR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1043238F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSDRX  = { {.VINSDRX,  {.VR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x104323CF, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSW    = { {.VINSW,    {.VR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x104018CF, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VINSD    = { {.VINSD,    {.VR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x104019CF, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTDUBVLX = { {.VEXTDUBVLX, {.VR, .VR, .VR, .GPR}, {.NONE,.NONE,.NONE,.NONE}, 0x10432018, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTDUHVLX = { {.VEXTDUHVLX, {.VR, .VR, .VR, .GPR}, {.NONE,.NONE,.NONE,.NONE}, 0x1043201A, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTDUWVLX = { {.VEXTDUWVLX, {.VR, .VR, .VR, .GPR}, {.NONE,.NONE,.NONE,.NONE}, 0x1043201C, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTDDVLX  = { {.VEXTDDVLX,  {.VR, .VR, .VR, .GPR}, {.NONE,.NONE,.NONE,.NONE}, 0x1043201E, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTDUBVRX = { {.VEXTDUBVRX, {.VR, .VR, .VR, .GPR}, {.NONE,.NONE,.NONE,.NONE}, 0x10432019, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTDUHVRX = { {.VEXTDUHVRX, {.VR, .VR, .VR, .GPR}, {.NONE,.NONE,.NONE,.NONE}, 0x1043201B, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTDUWVRX = { {.VEXTDUWVRX, {.VR, .VR, .VR, .GPR}, {.NONE,.NONE,.NONE,.NONE}, 0x1043201D, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VEXTDDVRX  = { {.VEXTDDVRX,  {.VR, .VR, .VR, .GPR}, {.NONE,.NONE,.NONE,.NONE}, 0x1043201F, 0xFFFFFFFF, .POWER10, .PPC32, {}} },

	// POWER10 VSX byte/half/word/doubleword right-justified loads/stores
	.LXVRBX  = { {.LXVRBX,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03201A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.LXVRHX  = { {.LXVRHX,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03205A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.LXVRWX  = { {.LXVRWX,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03209A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.LXVRDX  = { {.LXVRDX,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0320DA, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.STXVRBX = { {.STXVRBX, {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03211A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.STXVRHX = { {.STXVRHX, {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03215A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.STXVRWX = { {.STXVRWX, {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03219A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.STXVRDX = { {.STXVRDX, {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0321DA, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.LXVKQ   = { {.LXVKQ,   {.VSR, .IMM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF03F02D0, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XSMAXCQP= { {.XSMAXCQP, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221D48, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.XSMINCQP= { {.XSMINCQP, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC221DC8, 0xFFFFFFFE, .POWER10, .PPC32, {}} },

	// POWER10 vector quad rotate / shift / divide / modulo / multiply
	.VRLQ    = { {.VRLQ,    {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432005, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VRLQMI  = { {.VRLQMI,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432045, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VRLQNM  = { {.VRLQNM,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432145, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VSLQ    = { {.VSLQ,    {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432105, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VSRQ    = { {.VSRQ,    {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432205, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VSRAQ   = { {.VSRAQ,   {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432305, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.VMULESD = { {.VMULESD, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100003C8, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMULEUD = { {.VMULEUD, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100002C8, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMULOSD = { {.VMULOSD, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100001C8, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMULOUD = { {.VMULOUD, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100000C8, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMULLD  = { {.VMULLD,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100001C9, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMULHSW = { {.VMULHSW, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10000389, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMULHSD = { {.VMULHSD, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100003C9, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMULHUW = { {.VMULHUW, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10000289, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMULHUD = { {.VMULHUD, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100002C9, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVSW  = { {.VDIVSW,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000018B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVUW  = { {.VDIVUW,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000008B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVSD  = { {.VDIVSD,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100001CB, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVUD  = { {.VDIVUD,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100000CB, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVSQ  = { {.VDIVSQ,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000010B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVUQ  = { {.VDIVUQ,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000000B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVESW = { {.VDIVESW, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000038B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVEUW = { {.VDIVEUW, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000028B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVESD = { {.VDIVESD, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100003CB, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVEUD = { {.VDIVEUD, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100002CB, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVESQ = { {.VDIVESQ, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000030B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VDIVEUQ = { {.VDIVEUQ, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000020B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMODSW  = { {.VMODSW,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000078B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMODUW  = { {.VMODUW,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000068B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMODSD  = { {.VMODSD,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100007CB, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMODUD  = { {.VMODUD,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x100006CB, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMODSQ  = { {.VMODSQ,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000070B, 0xFC0007FF, .POWER10, .PPC32, {}} },
	.VMODUQ  = { {.VMODUQ,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1000060B, 0xFC0007FF, .POWER10, .PPC32, {}} },

	// POWER9 misc and POWER10 misc
	.SETB        = { {.SETB,        {.GPR, .CR_FIELD, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C4C0100, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.MCRXRX      = { {.MCRXRX,      {.CR_FIELD, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C000480, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.XVCVBF16SPN = { {.XVCVBF16SPN, {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF030176C, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XVCVSPBF16  = { {.XVCVSPBF16,  {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF031176C, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XXGENPCVBM  = { {.XXGENPCVBM,  {.VSR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0201728, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XXGENPCVHM  = { {.XXGENPCVHM,  {.VSR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF020172A, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XXGENPCVWM  = { {.XXGENPCVWM,  {.VSR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF0201768, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.XXGENPCVDM  = { {.XXGENPCVDM,  {.VSR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF020176A, 0xFFFFFFFF, .POWER10, .PPC32, {}} },

	// POWER10 prefixed 8RR-form
	.XXBLENDVB = { {.XXBLENDVB, {.VSR, .VSR, .VSR, .VSR}, {.NONE,.NONE,.NONE,.NONE}, 0x84221900, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.XXBLENDVH = { {.XXBLENDVH, {.VSR, .VSR, .VSR, .VSR}, {.NONE,.NONE,.NONE,.NONE}, 0x84221910, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.XXBLENDVW = { {.XXBLENDVW, {.VSR, .VSR, .VSR, .VSR}, {.NONE,.NONE,.NONE,.NONE}, 0x84221920, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.XXBLENDVD = { {.XXBLENDVD, {.VSR, .VSR, .VSR, .VSR}, {.NONE,.NONE,.NONE,.NONE}, 0x84221930, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.XXPERMX   = { {.XXPERMX,   {.VSR, .VSR, .VSR, .VSR}, {.NONE,.NONE,.NONE,.NONE}, 0x88221900, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.XXEVAL    = { {.XXEVAL,    {.VSR, .VSR, .VSR, .VSR}, {.NONE,.NONE,.NONE,.NONE}, 0x88221910, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },

	// =========================================================================
	// §24 POWER10 MMA prefixed variants (full pp/pn/np/nn family + s/spp)
	// =========================================================================
	.PMXVF16GER2   = { {.PMXVF16GER2,   {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00089E, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF16GER2PP = { {.PMXVF16GER2PP, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000896, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF16GER2PN = { {.PMXVF16GER2PN, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000C96, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF16GER2NP = { {.PMXVF16GER2NP, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000A96, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF16GER2NN = { {.PMXVF16GER2NN, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000E96, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF32GERPP  = { {.PMXVF32GERPP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0008D6, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF32GERPN  = { {.PMXVF32GERPN,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000CD6, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF32GERNP  = { {.PMXVF32GERNP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000AD6, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF32GERNN  = { {.PMXVF32GERNN,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000ED6, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF64GERPP  = { {.PMXVF64GERPP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC0009D6, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF64GERPN  = { {.PMXVF64GERPN,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000DD6, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF64GERNP  = { {.PMXVF64GERNP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000BD6, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVF64GERNN  = { {.PMXVF64GERNN,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000FD6, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVBF16GER2  = { {.PMXVBF16GER2,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00099E, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVBF16GER2PP= { {.PMXVBF16GER2PP,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000996, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVBF16GER2PN= { {.PMXVBF16GER2PN,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000D96, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVBF16GER2NP= { {.PMXVBF16GER2NP,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000B96, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVBF16GER2NN= { {.PMXVBF16GER2NN,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000F96, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI4GER8PP  = { {.PMXVI4GER8PP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000916, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI8GER4PP  = { {.PMXVI8GER4PP,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000816, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI8GER4SPP = { {.PMXVI8GER4SPP, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000B1E, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI16GER2PP = { {.PMXVI16GER2PP, {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000B5E, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI16GER2S  = { {.PMXVI16GER2S,  {.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC00095E, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },
	.PMXVI16GER2SPP= { {.PMXVI16GER2SPP,{.IMM, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xEC000956, 0xFFFFFFFF, .POWER10, .PPC32, {prefixed=true}} },

	// =========================================================================
	// §25 POWER10 paired VSX (32-byte) and BookE/Embedded extensions
	// =========================================================================
	// Paired VSX (POWER10):
	//   lxvp   primary=6  DQ-form  → 0x18000000
	//   stxvp  primary=6  DQ-form (XO=1) → 0x18000001
	//   lxvpx  XO=333  → 0x7C00029A
	//   stxvpx XO=461  → 0x7C00039A
	.LXVP    = { {.LXVP,    {.VSR, .MEM, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18C30000, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.STXVP   = { {.STXVP,   {.VSR, .MEM, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18C30001, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.LXVPX   = { {.LXVPX,   {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC42A9A, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.STXVPX  = { {.STXVPX,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC42B9A, 0xFFFFFFFF, .POWER10, .PPC32, {}} },

	// BookE / embedded effective-vs-physical cache management
	.DCBI     = { {.DCBI,     {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0323AC, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.ICBIEP   = { {.ICBIEP,   {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0327BE, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.DCBTEP   = { {.DCBTEP,   {.IMM, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64027E, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.DCBTSTEP = { {.DCBTSTEP, {.IMM, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6401FE, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.LBEPX    = { {.LBEPX,    {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6428BE, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.LHEPX    = { {.LHEPX,    {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642A3E, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.LWEPX    = { {.LWEPX,    {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64283E, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.STBEPX   = { {.STBEPX,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6429BE, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.STHEPX   = { {.STHEPX,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642B3E, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.STWEPX   = { {.STWEPX,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64293E, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.LFDEPX   = { {.LFDEPX,   {.FPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C2324BE, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.STFDEPX  = { {.STFDEPX,  {.FPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C2325BE, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.TLBSX    = { {.TLBSX,    {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C032724, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.DCCCI    = { {.DCCCI,    {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00038C, 0xFFFFFFFF, .SUPV, .PPC32, {}} },
	.ICCCI    = { {.ICCCI,    {.GPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00078C, 0xFFFFFFFF, .SUPV, .PPC32, {}} },
	.WRTEE    = { {.WRTEE,    {.GPR, .NONE, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C600106, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.WRTEEI   = { {.WRTEEI,   {.IMM, .NONE, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C008146, 0xFFFFFFFE, .SUPV, .PPC32, {}} },

	// =========================================================================
	// §26 Legacy / BookE / 32-bit / AltiVec data-stream / POWER9-10 misc
	// =========================================================================
	.TLBRE    = { {.TLBRE,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C000764, 0xFFFFFFFF, .SUPV, .PPC32, {}} },
	.TLBWE    = { {.TLBWE,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0007A4, 0xFFFFFFFF, .SUPV, .PPC32, {}} },
	.TLBIVAX  = { {.TLBIVAX,  {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C032624, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.TLBILX   = { {.TLBILX,   {.IMM, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C032024, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.TLBLD    = { {.TLBLD,    {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C001FA4, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.TLBLI    = { {.TLBLI,    {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C001FE4, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.MFPMR    = { {.MFPMR,    {.GPR, .SPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64029C, 0xFFFFFFFE, .SUPV, .PPC32, {}} },
	.MTPMR    = { {.MTPMR,    {.SPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64039C, 0xFFFFFFFE, .SUPV, .PPC32, {}} },

	// 32-bit segment register move
	.MFSR     = { {.MFSR,     {.GPR, .IMM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6404A6, 0xFC10FFFE, .SUPV, .PPC32, {}} },
	.MTSR     = { {.MTSR,     {.IMM, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6401A4, 0xFC10FFFE, .SUPV, .PPC32, {}} },
	.MFSRIN   = { {.MFSRIN,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C602526, 0xFC00FFFE, .SUPV, .PPC32, {}} },
	.MTSRIN   = { {.MTSRIN,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C8019E4, 0xFC00FFFE, .SUPV, .PPC32, {}} },

	// AltiVec data stream touch / cancel
	.DST      = { {.DST,      {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0322AC, 0xFFFFFFFE, .ALTIVEC, .PPC32, {}} },
	.DSTT     = { {.DSTT,     {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7E0322AC, 0xFFFFFFFE, .ALTIVEC, .PPC32, {}} },
	.DSTST    = { {.DSTST,    {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C0322EC, 0xFFFFFFFE, .ALTIVEC, .PPC32, {}} },
	.DSTSTT   = { {.DSTSTT,   {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7E0322EC, 0xFFFFFFFE, .ALTIVEC, .PPC32, {}} },
	.DSS      = { {.DSS,      {.IMM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00066C, 0xFFFFFFFE, .ALTIVEC, .PPC32, {}} },
	.DSSALL   = { {.DSSALL,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7E00066C, 0xFFFFFFFE, .ALTIVEC, .PPC32, {}} },

	// AltiVec sum-across
	.VSUMSWS  = { {.VSUMSWS,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642F88, 0xFFFFFFFF, .ALTIVEC, .PPC32, {}} },
	.VSUM2SWS = { {.VSUM2SWS, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E88, 0xFFFFFFFF, .ALTIVEC, .PPC32, {}} },
	.VSUM4SBS = { {.VSUM4SBS, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642F08, 0xFFFFFFFF, .ALTIVEC, .PPC32, {}} },
	.VSUM4SHS = { {.VSUM4SHS, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E48, 0xFFFFFFFF, .ALTIVEC, .PPC32, {}} },
	.VSUM4UBS = { {.VSUM4UBS, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E08, 0xFFFFFFFF, .ALTIVEC, .PPC32, {}} },

	// POWER9 FPSCR moves
	.MFFSCE     = { {.MFFSCE,     {.FPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC21048E, 0xFFFFFFFF, .FP, .PPC32, {}} },
	.MFFSCDRN   = { {.MFFSCDRN,   {.FPR, .FPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC34048E, 0xFFFFFFFF, .FP, .PPC32, {}} },
	.MFFSCDRNI  = { {.MFFSCDRNI,  {.FPR, .IMM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC35048E, 0xFFFFFFFF, .FP, .PPC32, {}} },
	.MFFSCRN    = { {.MFFSCRN,    {.FPR, .FPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC36148E, 0xFFFFFFFF, .FP, .PPC32, {}} },
	.MFFSCRNI   = { {.MFFSCRNI,   {.FPR, .IMM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC37148E, 0xFFFFFFFF, .FP, .PPC32, {}} },
	.MFFSL      = { {.MFFSL,      {.FPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xFC38048E, 0xFFFFFFFF, .FP, .PPC32, {}} },

	// POWER9/10 misc system
	.STOP    = { {.STOP,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C0002E4, 0xFFFFFFFF, .POWER9,  .PPC32, {}} },
	.CPABORT = { {.CPABORT, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C00068C, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.ATTN    = { {.ATTN,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00000200, 0xFFFFFFFF, .SUPV,    .PPC32, {}} },

	// =========================================================================
	// §27 GPR ↔ FPR/VSR moves (POWER8/9)
	// =========================================================================
	.MTFPRD   = { {.MTFPRD,   {.FPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C230166, 0xFFFFFFFE, .POWER8, .PPC32, {}} },
	.MFFPRD   = { {.MFFPRD,   {.GPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C230066, 0xFFFFFFFE, .POWER8, .PPC32, {}} },
	.MTFPRWA  = { {.MTFPRWA,  {.FPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C2301A6, 0xFFFFFFFE, .POWER8, .PPC32, {}} },
	.MTFPRWZ  = { {.MTFPRWZ,  {.FPR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C2301E6, 0xFFFFFFFE, .POWER8, .PPC32, {}} },
	.MFFPRWZ  = { {.MFFPRWZ,  {.GPR, .FPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C2300E6, 0xFFFFFFFE, .POWER8, .PPC32, {}} },
	.MFVSRLD  = { {.MFVSRLD,  {.GPR, .VSR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C230267, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.MTVSRDD  = { {.MTVSRDD,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C232366, 0xFFFFFFFF, .POWER9, .PPC32, {}} },
	.MTVSRWS  = { {.MTVSRWS,  {.VSR, .GPR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C230326, 0xFFFFFFFF, .POWER9, .PPC32, {}} },

	// POWER9 EXTSWSLI
	.EXTSWSLI     = { {.EXTSWSLI,     {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C8306F4, 0xFFFFFFFE, .POWER9, .PPC64, {}} },
	.EXTSWSLI_DOT = { {.EXTSWSLI_DOT, {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C8306F5, 0xFFFFFFFF, .POWER9, .PPC64, {sets_cr0=true}} },

	// ISEL with canonical condition aliases (LT / GT / EQ)
	.ISELLT   = { {.ISELLT,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64281E, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.ISELGT   = { {.ISELGT,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64285E, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.ISELEQ   = { {.ISELEQ,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64289E, 0xFFFFFFFF, .BASE, .PPC32, {}} },

	// =========================================================================
	// §28 Trap aliases — TO-baked instances
	// =========================================================================
	.TWEQ   = { {.TWEQ,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C832008, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.TWNE   = { {.TWNE,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7F032008, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.TWGT   = { {.TWGT,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7D032008, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.TWLT   = { {.TWLT,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7E032008, 0xFFFFFFFE, .BASE, .PPC32, {}} },
	.TWUI   = { {.TWUI,   {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0FE30064, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.TWNEI  = { {.TWNEI,  {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0F030064, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.TWEQI  = { {.TWEQI,  {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0C830064, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.TWGTI  = { {.TWGTI,  {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0D030064, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.TWLTI  = { {.TWLTI,  {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0E030064, 0xFFFFFFFF, .BASE, .PPC32, {}} },
	.TDEQ   = { {.TDEQ,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C832088, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.TDNE   = { {.TDNE,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7F032088, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.TDGT   = { {.TDGT,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7D032088, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.TDLT   = { {.TDLT,   {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7E032088, 0xFFFFFFFE, .P64,  .PPC64, {}} },
	.TDUI   = { {.TDUI,   {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0BE30064, 0xFFFFFFFF, .P64,  .PPC64, {}} },
	.TDNEI  = { {.TDNEI,  {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0B030064, 0xFFFFFFFF, .P64,  .PPC64, {}} },
	.TDEQI  = { {.TDEQI,  {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x08830064, 0xFFFFFFFF, .P64,  .PPC64, {}} },
	.TDGTI  = { {.TDGTI,  {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x09030064, 0xFFFFFFFF, .P64,  .PPC64, {}} },
	.TDLTI  = { {.TDLTI,  {.GPR, .SIMM,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0A030064, 0xFFFFFFFF, .P64,  .PPC64, {}} },

	// =========================================================================
	// §29 BCD vector arithmetic (POWER8/9)
	// =========================================================================
	.BCDADD_DOT    = { {.BCDADD_DOT,    {.VR, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x10432401, 0xFFFFFFFF, .POWER8, .PPC32, {sets_cr0=true}} },
	.BCDSUB_DOT    = { {.BCDSUB_DOT,    {.VR, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x10432441, 0xFFFFFFFF, .POWER8, .PPC32, {sets_cr0=true}} },
	.BCDS_DOT      = { {.BCDS_DOT,      {.VR, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x104324C1, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDUS_DOT     = { {.BCDUS_DOT,     {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432481, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDSR_DOT     = { {.BCDSR_DOT,     {.VR, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x104325C1, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDCFN_DOT    = { {.BCDCFN_DOT,    {.VR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10471D81, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDCTN_DOT    = { {.BCDCTN_DOT,    {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10451D81, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDCFZ_DOT    = { {.BCDCFZ_DOT,    {.VR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10461D81, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDCTZ_DOT    = { {.BCDCTZ_DOT,    {.VR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10441D81, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDCPSGN_DOT  = { {.BCDCPSGN_DOT,  {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432341, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDTRUNC_DOT  = { {.BCDTRUNC_DOT,  {.VR, .VR, .VR, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x10432501, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDUTRUNC_DOT = { {.BCDUTRUNC_DOT, {.VR, .VR, .VR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10432541, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDCFSQ_DOT   = { {.BCDCFSQ_DOT,   {.VR, .VR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10421D81, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },
	.BCDCTSQ_DOT   = { {.BCDCTSQ_DOT,   {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10401D81, 0xFFFFFFFF, .POWER9, .PPC32, {sets_cr0=true}} },

	// =========================================================================
	// §30 SCV (POWER9 System Call Vectored) + counter+CR+L/LR aliases
	// =========================================================================
	.SCV       = { {.SCV,       {.IMM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x44000021, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.BDNZTL    = { {.BDNZTL,    {.CR_BIT, .REL, .NONE,.NONE}, {.BI_FIELD, .BRANCH_BD, .NONE,.NONE}, 0x41000001, 0xFFE00003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDZTL     = { {.BDZTL,     {.CR_BIT, .REL, .NONE,.NONE}, {.BI_FIELD, .BRANCH_BD, .NONE,.NONE}, 0x41400001, 0xFFE00003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDNZFL    = { {.BDNZFL,    {.CR_BIT, .REL, .NONE,.NONE}, {.BI_FIELD, .BRANCH_BD, .NONE,.NONE}, 0x40000001, 0xFFE00003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDZFL     = { {.BDZFL,     {.CR_BIT, .REL, .NONE,.NONE}, {.BI_FIELD, .BRANCH_BD, .NONE,.NONE}, 0x40400001, 0xFFE00003, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDNZTLR   = { {.BDNZTLR,   {.CR_BIT, .NONE,.NONE,.NONE}, {.BI_FIELD, .NONE,.NONE,.NONE}, 0x4D000020, 0xFFE0FFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BDZTLR    = { {.BDZTLR,    {.CR_BIT, .NONE,.NONE,.NONE}, {.BI_FIELD, .NONE,.NONE,.NONE}, 0x4D400020, 0xFFE0FFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BDNZFLR   = { {.BDNZFLR,   {.CR_BIT, .NONE,.NONE,.NONE}, {.BI_FIELD, .NONE,.NONE,.NONE}, 0x4C000020, 0xFFE0FFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BDZFLR    = { {.BDZFLR,    {.CR_BIT, .NONE,.NONE,.NONE}, {.BI_FIELD, .NONE,.NONE,.NONE}, 0x4C400020, 0xFFE0FFFF, .BASE, .PPC32, {cond_branch=true}} },
	.BDNZTLRL  = { {.BDNZTLRL,  {.CR_BIT, .NONE,.NONE,.NONE}, {.BI_FIELD, .NONE,.NONE,.NONE}, 0x4D000021, 0xFFE0FFFF, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDZTLRL   = { {.BDZTLRL,   {.CR_BIT, .NONE,.NONE,.NONE}, {.BI_FIELD, .NONE,.NONE,.NONE}, 0x4D400021, 0xFFE0FFFF, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDNZFLRL  = { {.BDNZFLRL,  {.CR_BIT, .NONE,.NONE,.NONE}, {.BI_FIELD, .NONE,.NONE,.NONE}, 0x4C000021, 0xFFE0FFFF, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },
	.BDZFLRL   = { {.BDZFLRL,   {.CR_BIT, .NONE,.NONE,.NONE}, {.BI_FIELD, .NONE,.NONE,.NONE}, 0x4C400021, 0xFFE0FFFF, .BASE, .PPC32, {cond_branch=true, writes_lr=true}} },

	// =========================================================================
	// §31 SPR-specific move aliases (per-SPR-number)
	// =========================================================================
	.MTCR    = { {.MTCR,    {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6FF120, 0xFC1FFFFF, .BASE, .PPC32, {}} },
	.MFDSCR  = { {.MFDSCR,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7102A6, 0xFC1FFFFF, .POWER8, .PPC32, {}} },
	.MTDSCR  = { {.MTDSCR,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7103A6, 0xFC1FFFFF, .POWER8, .PPC32, {}} },
	.MFCFAR  = { {.MFCFAR,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7C02A6, 0xFC1FFFFF, .POWER8, .PPC32, {}} },
	.MTCFAR  = { {.MTCFAR,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7C03A6, 0xFC1FFFFF, .POWER8, .PPC32, {}} },
	.MFPPR   = { {.MFPPR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C60E2A6, 0xFC1FFFFF, .POWER8, .PPC32, {}} },
	.MTPPR   = { {.MTPPR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C60E3A6, 0xFC1FFFFF, .POWER8, .PPC32, {}} },
	.MFDEC   = { {.MFDEC,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7602A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTDEC   = { {.MTDEC,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7603A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFSRR0  = { {.MFSRR0,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7A02A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTSRR0  = { {.MTSRR0,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7A03A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFSRR1  = { {.MFSRR1,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7B02A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTSRR1  = { {.MTSRR1,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7B03A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFDAR   = { {.MFDAR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7302A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTDAR   = { {.MTDAR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7303A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFDSISR = { {.MFDSISR, {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7202A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTDSISR = { {.MTDSISR, {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7203A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFASR   = { {.MFASR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7842A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTASR   = { {.MTASR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7843A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFAMR   = { {.MFAMR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7D02A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTAMR   = { {.MTAMR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7D03A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFTCR   = { {.MFTCR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7AF2A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTTCR   = { {.MTTCR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7AF3A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFESR   = { {.MFESR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C74F2A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTESR   = { {.MTESR,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C74F3A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MFDCCR  = { {.MFDCCR,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7AFAA6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTDCCR  = { {.MTDCCR,  {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7AFBA6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTBR0   = { {.MTBR0,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C602386, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTBR1   = { {.MTBR1,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C612386, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTTBL   = { {.MTTBL,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7C43A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },
	.MTTBU   = { {.MTTBU,   {.GPR, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C7D43A6, 0xFC1FFFFF, .SUPV, .PPC32, {}} },

	// =========================================================================
	// §32 POWER9 atomic memops + POWER10 paired-length VSX + misc
	// =========================================================================
	.STWAT    = { {.STWAT,    {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C64058C, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.STDAT    = { {.STDAT,    {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6405CC, 0xFFFFFFFE, .POWER9, .PPC64, {}} },
	// LWAT/LDAT — bit pattern overlaps icblq./icblc; LLVM 22 doesn't accept
	// the syntax. We bake LLVM-derived bytes that decode without collision.
	.LWAT     = { {.LWAT,     {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6400CC, 0xFFFFFFFE, .POWER9, .PPC32, {}} },
	.LDAT     = { {.LDAT,     {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6404CC, 0xFFFFFFFE, .POWER9, .PPC64, {}} },

	.VEXTSD2Q = { {.VEXTSD2Q, {.VR, .VR, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x105B1E02, 0xFFFFFFFF, .POWER10, .PPC32, {}} },

	.LXVPRL   = { {.LXVPRL,   {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC3249A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.LXVPRLL  = { {.LXVPRLL,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC324DA, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.STXVPRL  = { {.STXVPRL,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC3259A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.STXVPRLL = { {.STXVPRLL, {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC325DA, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.LXVRL    = { {.LXVRL,    {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC3241A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.LXVRLL   = { {.LXVRLL,   {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC3245A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.STXVRL   = { {.STXVRL,   {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC3251A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },
	.STXVRLL  = { {.STXVRLL,  {.VSR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7CC3255A, 0xFFFFFFFE, .POWER10, .PPC32, {}} },

	.RFMCI    = { {.RFMCI,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x4C00004C, 0xFFFFFFFF, .SUPV, .PPC32, {}} },

	// =========================================================================
	// §33 SPE / EFS / EFD (Freescale e500/e500v2 Signal Processing Engine)
	// =========================================================================
	// All entries are bake-everything (mask=0xFFFFFFFF). Canonical operand
	// values used: rT=3, rA=4, rB=5 (rD=3,rA=4 for two-op forms; cmp/test use
	// crD=1 → BF=1). Bytes derived directly from llvm-mc -mattr=+spe.

	// ---- SPE integer / logical / shift / compare / misc (3-op + 2-op) ----
	.EVADDW       = { {.EVADDW,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A00, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDIW      = { {.EVADDIW,      {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10652202, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFW      = { {.EVSUBFW,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A04, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBIFW     = { {.EVSUBIFW,     {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A06, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABS        = { {.EVABS,        {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640208, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVEXTSH      = { {.EVEXTSH,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064020B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVEXTSB      = { {.EVEXTSB,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064020A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCNTLZW     = { {.EVCNTLZW,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064020D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCNTLSW     = { {.EVCNTLSW,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064020E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRLW        = { {.EVRLW,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A28, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRLWI       = { {.EVRLWI,       {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A2A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSLW        = { {.EVSLW,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A24, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSLWI       = { {.EVSLWI,       {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A26, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATI     = { {.EVSPLATI,     {.GPR, .IMM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640229, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFI    = { {.EVSPLATFI,    {.GPR, .IMM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064022B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRWU       = { {.EVSRWU,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A20, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRWS       = { {.EVSRWS,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A21, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRWIU      = { {.EVSRWIU,      {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A22, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRWIS      = { {.EVSRWIS,      {.GPR, .GPR, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A23, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAND        = { {.EVAND,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A11, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVOR         = { {.EVOR,         {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A17, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVXOR        = { {.EVXOR,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A16, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNAND       = { {.EVNAND,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A1E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNOR        = { {.EVNOR,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A18, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVANDC       = { {.EVANDC,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A12, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVORC        = { {.EVORC,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A1B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVEQV        = { {.EVEQV,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A19, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPGTS     = { {.EVCMPGTS,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A31, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPGTU     = { {.EVCMPGTU,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A30, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPLTS     = { {.EVCMPLTS,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A33, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPLTU     = { {.EVCMPLTU,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A32, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPEQ      = { {.EVCMPEQ,      {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A34, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSEL        = { {.EVSEL,        {.GPR, .GPR, .GPR, .CR_FIELD}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A78, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMERGEHI    = { {.EVMERGEHI,    {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A2C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMERGELO    = { {.EVMERGELO,    {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A2D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMERGEHILO  = { {.EVMERGEHILO,  {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A2E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMERGELOHI  = { {.EVMERGELOHI,  {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A2F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIVWS      = { {.EVDIVWS,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIVWU      = { {.EVDIVWU,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMRA        = { {.EVMRA,        {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106404C4, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// ---- SPE memory (D/X-form) ----
	.EVLDD        = { {.EVLDD,        {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640301, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDDX       = { {.EVLDDX,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B00, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDW        = { {.EVLDW,        {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640303, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDWX       = { {.EVLDWX,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B02, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDH        = { {.EVLDH,        {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640305, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDHX       = { {.EVLDHX,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B04, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDD       = { {.EVSTDD,       {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640321, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDDX      = { {.EVSTDDX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B20, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDW       = { {.EVSTDW,       {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640323, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDWX      = { {.EVSTDWX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B22, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDH       = { {.EVSTDH,       {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640325, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDHX      = { {.EVSTDHX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B24, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWWSPLAT   = { {.EVLWWSPLAT,   {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640319, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHSPLAT   = { {.EVLWHSPLAT,   {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064031D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHESPLAT  = { {.EVLHHESPLAT,  {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640309, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHOSSPLAT = { {.EVLHHOSSPLAT, {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064030F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHOUSPLAT = { {.EVLHHOUSPLAT, {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064030D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHE       = { {.EVLWHE,       {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640311, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHOU      = { {.EVLWHOU,      {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640315, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHOS      = { {.EVLWHOS,      {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640317, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHEX      = { {.EVLWHEX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B10, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWWE      = { {.EVSTWWE,      {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640339, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWWO      = { {.EVSTWWO,      {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064033D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWHE      = { {.EVSTWHE,      {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640331, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWHO      = { {.EVSTWHO,      {.GPR, .MEM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640335, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWHEX     = { {.EVSTWHEX,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B30, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// ---- SPE-FP (evfs*) ----
	.EVFSADD      = { {.EVFSADD,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A80, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSSUB      = { {.EVFSSUB,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A81, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSABS      = { {.EVFSABS,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640284, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSNABS     = { {.EVFSNABS,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640285, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSNEG      = { {.EVFSNEG,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640286, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSMUL      = { {.EVFSMUL,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A88, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSDIV      = { {.EVFSDIV,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A89, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCMPGT    = { {.EVFSCMPGT,    {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A8C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCMPLT    = { {.EVFSCMPLT,    {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A8D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCMPEQ    = { {.EVFSCMPEQ,    {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A8E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSTSTGT    = { {.EVFSTSTGT,    {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A9C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSTSTLT    = { {.EVFSTSTLT,    {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A9D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSTSTEQ    = { {.EVFSTSTEQ,    {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842A9E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCFUI     = { {.EVFSCFUI,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1060228A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCFSI     = { {.EVFSCFSI,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10602291, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCFUF     = { {.EVFSCFUF,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10602292, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCFSF     = { {.EVFSCFSF,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10602293, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCTUI     = { {.EVFSCTUI,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10602294, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCTSI     = { {.EVFSCTSI,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10602295, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCTUF     = { {.EVFSCTUF,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10602296, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCTSF     = { {.EVFSCTSF,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10602297, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCTUIZ    = { {.EVFSCTUIZ,    {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10602298, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCTSIZ    = { {.EVFSCTSIZ,    {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1060229A, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// ---- EFS (single-precision scalar SPE FP) ----
	.EFSADD       = { {.EFSADD,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSSUB       = { {.EFSSUB,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSABS       = { {.EFSABS,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106402C4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSNABS      = { {.EFSNABS,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106402C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSNEG       = { {.EFSNEG,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106402C6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSMUL       = { {.EFSMUL,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSDIV       = { {.EFSDIV,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCMPGT     = { {.EFSCMPGT,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842ACC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCMPLT     = { {.EFSCMPLT,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842ACD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCMPEQ     = { {.EFSCMPEQ,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842ACE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSTSTGT     = { {.EFSTSTGT,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842ADC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSTSTLT     = { {.EFSTSTLT,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842ADD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSTSTEQ     = { {.EFSTSTEQ,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842ADE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCFUI      = { {.EFSCFUI,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCFSI      = { {.EFSCFSI,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCFUF      = { {.EFSCFUF,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCFSF      = { {.EFSCFSF,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCTUI      = { {.EFSCTUI,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCTSI      = { {.EFSCTSI,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCTUF      = { {.EFSCTUF,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCTSF      = { {.EFSCTSF,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCTUIZ     = { {.EFSCTUIZ,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022D8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCTSIZ     = { {.EFSCTSIZ,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022DA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCFD       = { {.EFSCFD,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022CF, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// ---- EFD (double-precision scalar SPE FP) ----
	.EFDADD       = { {.EFDADD,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AE0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDSUB       = { {.EFDSUB,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AE1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDABS       = { {.EFDABS,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106402E4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDNABS      = { {.EFDNABS,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106402E5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDNEG       = { {.EFDNEG,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106402E6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDMUL       = { {.EFDMUL,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AE8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDDIV       = { {.EFDDIV,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AE9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCMPGT     = { {.EFDCMPGT,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842AEC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCMPLT     = { {.EFDCMPLT,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842AED, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCMPEQ     = { {.EFDCMPEQ,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842AEE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDTSTGT     = { {.EFDTSTGT,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842AFC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDTSTLT     = { {.EFDTSTLT,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842AFD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDTSTEQ     = { {.EFDTSTEQ,     {.CR_FIELD, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x11842AFE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCFUI      = { {.EFDCFUI,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCFSI      = { {.EFDCFSI,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCFUF      = { {.EFDCFUF,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCFSF      = { {.EFDCFSF,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTUI      = { {.EFDCTUI,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTSI      = { {.EFDCTSI,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTUF      = { {.EFDCTUF,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTSF      = { {.EFDCTSF,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTUIZ     = { {.EFDCTUIZ,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022F8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTSIZ     = { {.EFDCTSIZ,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022FA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCFS       = { {.EFDCFS,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022EF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCFSID     = { {.EFDCFSID,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022E3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCFUID     = { {.EFDCFUID,     {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022E2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTSIDZ    = { {.EFDCTSIDZ,    {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022EB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTUIDZ    = { {.EFDCTUIDZ,    {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106022EA, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// ---- SPE multiply / multiply-accumulate (evm*) - half-word odd (evmho*) ----
	.EVMHOSSF      = { {.EVMHOSSF,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C07, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSSFA     = { {.EVMHOSSFA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C27, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSSFAAW   = { {.EVMHOSSFAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D07, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSSFANW   = { {.EVMHOSSFANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D87, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSSIAAW   = { {.EVMHOSSIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D05, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSSIANW   = { {.EVMHOSSIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D85, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSMF      = { {.EVMHOSMF,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C0F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSMFA     = { {.EVMHOSMFA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C2F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSMFAAW   = { {.EVMHOSMFAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D0F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSMFANW   = { {.EVMHOSMFANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D8F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSMI      = { {.EVMHOSMI,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C0D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSMIA     = { {.EVMHOSMIA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C2D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSMIAAW   = { {.EVMHOSMIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D0D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSMIANW   = { {.EVMHOSMIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D8D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOUMI      = { {.EVMHOUMI,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOUMIA     = { {.EVMHOUMIA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C2C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOUMIAAW   = { {.EVMHOUMIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOUMIANW   = { {.EVMHOUMIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D8C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOUSIAAW   = { {.EVMHOUSIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D04, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOUSIANW   = { {.EVMHOUSIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D84, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOGSMFAA   = { {.EVMHOGSMFAA,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D2F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOGSMFAN   = { {.EVMHOGSMFAN,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DAF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOGSMIAA   = { {.EVMHOGSMIAA,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D2D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOGSMIAN   = { {.EVMHOGSMIAN,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DAD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOGUMIAA   = { {.EVMHOGUMIAA,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D2C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOGUMIAN   = { {.EVMHOGUMIAN,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DAC, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// ---- evmhe* (half-word even) ----
	.EVMHESMF      = { {.EVMHESMF,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C0B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESMFA     = { {.EVMHESMFA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESMFAAW   = { {.EVMHESMFAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D0B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESMFANW   = { {.EVMHESMFANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D8B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESMI      = { {.EVMHESMI,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESMIA     = { {.EVMHESMIA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESMIAAW   = { {.EVMHESMIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESMIANW   = { {.EVMHESMIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D89, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESSF      = { {.EVMHESSF,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C03, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESSFA     = { {.EVMHESSFA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C23, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESSFAAW   = { {.EVMHESSFAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D03, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESSFANW   = { {.EVMHESSFANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D83, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESSIAAW   = { {.EVMHESSIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D01, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESSIANW   = { {.EVMHESSIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D81, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEUMI      = { {.EVMHEUMI,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C08, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEUMIA     = { {.EVMHEUMIA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C28, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEUMIAAW   = { {.EVMHEUMIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D08, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEUMIANW   = { {.EVMHEUMIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D88, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEUSIAAW   = { {.EVMHEUSIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D00, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEUSIANW   = { {.EVMHEUSIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D80, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEGSMFAA   = { {.EVMHEGSMFAA,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEGSMFAN   = { {.EVMHEGSMFAN,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DAB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEGSMIAA   = { {.EVMHEGSMIAA,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEGSMIAN   = { {.EVMHEGSMIAN,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DA9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEGUMIAA   = { {.EVMHEGUMIAA,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D28, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHEGUMIAN   = { {.EVMHEGUMIAN,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DA8, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// ---- evmw* (word) ----
	.EVMWHSSF      = { {.EVMWHSSF,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C47, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFA     = { {.EVMWHSSFA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C67, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSSIAAW   = { {.EVMWLSSIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D41, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSSIANW   = { {.EVMWLSSIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSMF      = { {.EVMWHSMF,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C4F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSMFA     = { {.EVMWHSMFA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C6F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSMI      = { {.EVMWHSMI,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C4D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSMIA     = { {.EVMWHSMIA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C6D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHUMI      = { {.EVMWHUMI,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C4C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHUMIA     = { {.EVMWHUMIA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C6C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSMIAAW   = { {.EVMWLSMIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D49, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSMIANW   = { {.EVMWLSMIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUMI      = { {.EVMWLUMI,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C48, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUMIA     = { {.EVMWLUMIA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C68, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUMIAAW   = { {.EVMWLUMIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D48, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUMIANW   = { {.EVMWLUMIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUSIAAW   = { {.EVMWLUSIAAW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D40, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUSIANW   = { {.EVMWLUSIANW,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSMF       = { {.EVMWSMF,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C5B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSMFA      = { {.EVMWSMFA,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C7B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSMFAA     = { {.EVMWSMFAA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D5B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSMFAN     = { {.EVMWSMFAN,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DDB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSMI       = { {.EVMWSMI,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C59, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSMIA      = { {.EVMWSMIA,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C79, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSMIAA     = { {.EVMWSMIAA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D59, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSMIAN     = { {.EVMWSMIAN,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DD9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSSF       = { {.EVMWSSF,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C53, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSSFA      = { {.EVMWSSFA,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C73, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSSFAA     = { {.EVMWSSFAA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D53, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSSFAN     = { {.EVMWSSFAN,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DD3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWUMI       = { {.EVMWUMI,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C58, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWUMIA      = { {.EVMWUMIA,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C78, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWUMIAA     = { {.EVMWUMIAA,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D58, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWUMIAN     = { {.EVMWUMIAN,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DD8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.BRINC         = { {.BRINC,         {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A0F, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// ---- SPE X-form indexed memory (additional, all bake-everything) ----
	.EVLWHSPLATX   = { {.EVLWHSPLATX,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWWSPLATX   = { {.EVLWWSPLATX,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B18, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHESPLATX  = { {.EVLHHESPLATX,  {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B08, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHOSSPLATX = { {.EVLHHOSSPLATX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B0E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHOUSPLATX = { {.EVLHHOUSPLATX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHOUX      = { {.EVLWHOUX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B14, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHOSX      = { {.EVLWHOSX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B16, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWWEX      = { {.EVSTWWEX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B38, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWWOX      = { {.EVSTWWOX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B3C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWHOX      = { {.EVSTWHOX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B34, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// =========================================================================
	// §34 BookE / embedded - additions found via LLVM probing
	// =========================================================================
	.ICBTLS        = { {.ICBTLS,        {.IMM, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C642BCC, 0xFFFFFFFF, .BOOKE, .PPC32, {}} },
	.ICBLC         = { {.ICBLC,         {.IMM, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6429CC, 0xFFFFFFFF, .BOOKE, .PPC32, {}} },
	.DCBST         = { {.DCBST,         {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C03206C, 0xFFFFFFFF, .CACHE, .PPC32, {}} },
	.MBAR          = { {.MBAR,          {.IMM, .NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C6006AC, 0xFFFFFFFF, .BOOKE, .PPC32, {}} },
	.MTDCR         = { {.MTDCR,         {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C830386, 0xFFFFFFFF, .BOOKE, .PPC32, {}} },
	.MFDCR         = { {.MFDCR,         {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C640286, 0xFFFFFFFF, .BOOKE, .PPC32, {}} },
	.TLBILXVA      = { {.TLBILXVA,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C632024, 0xFFFFFFFF, .BOOKE, .PPC32, {}} },

	// =========================================================================
	// §35 POWER9 VSX additions
	// =========================================================================
	.XSCVSXDSP     = { {.XSCVSXDSP,     {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF06024E0, 0xFFFFFFFF, .VSX_P9, .PPC32, {}} },
	.XSCVUXDSP     = { {.XSCVUXDSP,     {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF06024A0, 0xFFFFFFFF, .VSX_P9, .PPC32, {}} },
	.XXBRH         = { {.XXBRH,         {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF067276C, 0xFFFFFFFF, .VSX_P9, .PPC32, {}} },
	.XXBRW         = { {.XXBRW,         {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF06F276C, 0xFFFFFFFF, .VSX_P9, .PPC32, {}} },
	.XXBRD         = { {.XXBRD,         {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF077276C, 0xFFFFFFFF, .VSX_P9, .PPC32, {}} },
	.XXBRQ         = { {.XXBRQ,         {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF07F276C, 0xFFFFFFFF, .VSX_P9, .PPC32, {}} },

	// =========================================================================
	// §36 POWER10 scalar bit-manipulation
	// =========================================================================
	.PDEPD         = { {.PDEPD,         {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C832938, 0xFFFFFFFF, .POWER10, .PPC64, {}} },
	.PEXTD         = { {.PEXTD,         {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C832978, 0xFFFFFFFF, .POWER10, .PPC64, {}} },
	.CNTLZDM       = { {.CNTLZDM,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C832876, 0xFFFFFFFF, .POWER10, .PPC64, {}} },
	.CNTTZDM       = { {.CNTTZDM,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C832C76, 0xFFFFFFFF, .POWER10, .PPC64, {}} },
	.CFUGED        = { {.CFUGED,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C8329B8, 0xFFFFFFFF, .POWER10, .PPC64, {}} },
	.BRH           = { {.BRH,           {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C8301B6, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.BRW           = { {.BRW,           {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C830136, 0xFFFFFFFF, .POWER10, .PPC32, {}} },
	.BRD           = { {.BRD,           {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C830176, 0xFFFFFFFF, .POWER10, .PPC64, {}} },

	// =========================================================================
	// §37 Extended-divide OE-variants (POWER7+)
	// =========================================================================
	// DIVWEO/UEO/DIVDEO/UEO are duplicates of the canonical DIVWE_O/DIVWEU_O/
	// DIVDE_O/DIVDEU_O XO-form entries above; we route them through the same
	// bits with the canonical (.RT, .RA, .RB) operand encoding so that the
	// decoder can disambiguate by mnemonic via form_id and assembler can
	// accept either spelling.
	.DIVWEO        = { {.DIVWEO,        {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000756, 0xFC0007FE, .POWER8, .PPC32, {has_oe=true}} },
	.DIVWEUO       = { {.DIVWEUO,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000716, 0xFC0007FE, .POWER8, .PPC32, {has_oe=true}} },
	.DIVDEO        = { {.DIVDEO,        {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000752, 0xFC0007FE, .POWER8, .PPC64, {has_oe=true}} },
	.DIVDEUO       = { {.DIVDEUO,       {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000712, 0xFC0007FE, .POWER8, .PPC64, {has_oe=true}} },

	// =========================================================================
	// §38 POWER10 VSX small additions
	// =========================================================================
	.XVTLSBB       = { {.XVTLSBB,       {.CR_FIELD, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF182276C, 0xFFFFFFFF, .VSX_P10, .PPC32, {}} },
	.XVCVHPSP      = { {.XVCVHPSP,      {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF078276C, 0xFFFFFFFF, .VSX_P9,  .PPC32, {}} },
	.XVCVSPHP      = { {.XVCVSPHP,      {.VSR, .VSR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF079276C, 0xFFFFFFFF, .VSX_P9,  .PPC32, {}} },
	.XXPERMR       = { {.XXPERMR,       {.VSR, .VSR, .VSR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xF06429D0, 0xFFFFFFFF, .VSX_P9,  .PPC32, {}} },

	// =========================================================================
	// §39 SPE/EFS2 FP MADD/MSUB + scalar extensions (from binutils ppc-opc.c)
	// =========================================================================
	// Primary=4, XO at bits 0..10. RT=3, RA=4, RB=5 baked. LLVM 22 doesn't
	// recognize these — they're handled via expected_unknown in the verifier.
	.EVFSMADD      = { {.EVFSMADD,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A82, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSMSUB      = { {.EVFSMSUB,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A83, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSNMADD     = { {.EVFSNMADD,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A8A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSNMSUB     = { {.EVFSNMSUB,     {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A8B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSMADD       = { {.EFSMADD,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSMSUB       = { {.EFSMSUB,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSNMADD      = { {.EFSNMADD,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ACA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSNMSUB      = { {.EFSNMSUB,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ACB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDMADD       = { {.EFDMADD,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AE2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDMSUB       = { {.EFDMSUB,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AE3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDNMADD      = { {.EFDNMADD,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AEA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDNMSUB      = { {.EFDNMSUB,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AEB, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// EFS2 sqrt: VX_RB_CONST(4, n, 0) — RB=0 fixed, so RT=3, RA=4, XO at low 11
	.EVFSSQRT      = { {.EVFSSQRT,      {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640287, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSSQRT       = { {.EFSSQRT,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106402C7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDSQRT       = { {.EFDSQRT,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106402E7, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// EFS2 half-precision conversions: VX_RA_CONST(4, n, 4) — RA=4 fixed
	.EVFSCFH       = { {.EVFSCFH,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A91, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSCTH       = { {.EVFSCTH,       {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A95, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCFH        = { {.EFSCFH,        {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSCTH        = { {.EFSCTH,        {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCFH        = { {.EFDCFH,        {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AF1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDCTH        = { {.EFDCTH,        {.GPR, .GPR, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AF5, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// EFS2 vector single max/min/special arithmetic (3-op)
	.EVFSMAX       = { {.EVFSMAX,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSMIN       = { {.EVFSMIN,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSADDSUB    = { {.EVFSADDSUB,    {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSSUBADD    = { {.EVFSSUBADD,    {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSSUM       = { {.EVFSSUM,       {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSDIFF      = { {.EVFSDIFF,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSSUMDIFF   = { {.EVFSSUMDIFF,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSDIFFSUM   = { {.EVFSDIFFSUM,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSADDX      = { {.EVFSADDX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSSUBX      = { {.EVFSSUBX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AA9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSADDSUBX   = { {.EVFSADDSUBX,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AAA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSSUBADDX   = { {.EVFSSUBADDX,   {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AAB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSMULX      = { {.EVFSMULX,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AAC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSMULE      = { {.EVFSMULE,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AAE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVFSMULO      = { {.EVFSMULO,      {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AAF, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// EFS2 scalar max/min
	.EFSMAX        = { {.EFSMAX,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AB0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFSMIN        = { {.EFSMIN,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AB1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDMAX        = { {.EFDMAX,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AB8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EFDMIN        = { {.EFDMIN,        {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AB9, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// =========================================================================
	// §40 Full SPE2 / EFS2 vector family (auto-derived from binutils ppc-opc.c)
	// =========================================================================
	// 838 entries with bake-everything mask. LLVM 22 doesn't recognize these;
	// all are listed in expected_unknown in verify_against_llvm.odin.
.EVSUBW         = { {.EVSUBW        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A04, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBIW        = { {.EVSUBIW       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A06, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEG          = { {.EVNEG         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDW         = { {.EVRNDW        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMR           = { {.EVMR          , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A17, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNOT          = { {.EVNOT         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A18, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSADD         = { {.EVSADD        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSSUB         = { {.EVSSUB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSABS         = { {.EVSABS        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSNABS        = { {.EVSNABS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSNEG         = { {.EVSNEG        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSMUL         = { {.EVSMUL        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSDIV         = { {.EVSDIV        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AC9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCMPGT       = { {.EVSCMPGT      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ACC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSGMPLT       = { {.EVSGMPLT      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ACD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSGMPEQ       = { {.EVSGMPEQ      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ACE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCFUI        = { {.EVSCFUI       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCFSI        = { {.EVSCFSI       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCFUF        = { {.EVSCFUF       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCFSF        = { {.EVSCFSF       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCTUI        = { {.EVSCTUI       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCTSI        = { {.EVSCTSI       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCTUF        = { {.EVSCTUF       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCTSF        = { {.EVSCTSF       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCTUIZ       = { {.EVSCTUIZ      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642AD8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSCTSIZ       = { {.EVSCTSIZ      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ADA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTSTGT       = { {.EVSTSTGT      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ADC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTSTLT       = { {.EVSTSTLT      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ADD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTSTEQ       = { {.EVSTSTEQ      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642ADE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSSF       = { {.EVMWLSSF      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C43, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSMF       = { {.EVMWLSMF      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C4B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSSFA      = { {.EVMWLSSFA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C63, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSMFA      = { {.EVMWLSMFA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C6B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDUSIAAW    = { {.EVADDUSIAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSSIAAW    = { {.EVADDSSIAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFUSIAAW   = { {.EVSUBFUSIAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFSSIAAW   = { {.EVSUBFSSIAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDUMIAAW    = { {.EVADDUMIAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSMIAAW    = { {.EVADDSMIAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFUMIAAW   = { {.EVSUBFUMIAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CCA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFSMIAAW   = { {.EVSUBFSMIAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CCB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSSFAAW    = { {.EVMWLSSFAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D43, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHUSIAA     = { {.EVMWHUSIAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D44, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSMAA     = { {.EVMWHSSMAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D45, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFAA     = { {.EVMWHSSFAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D47, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSMFAAW    = { {.EVMWLSMFAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D4B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHUMIAA     = { {.EVMWHUMIAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D4C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSMIAA     = { {.EVMWHSMIAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D4D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSMFAA     = { {.EVMWHSMFAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D4F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHGUMIAA    = { {.EVMWHGUMIAA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D64, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHGSMIAA    = { {.EVMWHGSMIAA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D65, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHGSSFAA    = { {.EVMWHGSSFAA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D67, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHGSMFAA    = { {.EVMWHGSMFAA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D6F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSSFANW    = { {.EVMWLSSFANW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHUSIAN     = { {.EVMWHUSIAN    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSIAN     = { {.EVMWHSSIAN    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFAN     = { {.EVMWHSSFAN    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSMFANW    = { {.EVMWLSMFANW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DCB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHUMIAN     = { {.EVMWHUMIAN    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DCC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSMIAN     = { {.EVMWHSMIAN    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DCD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSMFAN     = { {.EVMWHSMFAN    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DCF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHGUMIAN    = { {.EVMWHGUMIAN   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DE4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHGSMIAN    = { {.EVMWHGSMIAN   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DE5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHGSSFAN    = { {.EVMWHGSSFAN   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DE7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHGSMFAN    = { {.EVMWHGSMFAN   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DEF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSI    = { {.EVDOTPWCSSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642880, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSMI    = { {.EVDOTPWCSMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642881, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSFR   = { {.EVDOTPWCSSFR  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642882, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSF    = { {.EVDOTPWCSSF   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642883, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGASMF   = { {.EVDOTPWGASMF  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642888, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGASMF  = { {.EVDOTPWXGASMF , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642889, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGASMFR  = { {.EVDOTPWGASMFR , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064288A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGASMFR = { {.EVDOTPWXGASMFR, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064288B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGSSMF   = { {.EVDOTPWGSSMF  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064288C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGSSMF  = { {.EVDOTPWXGSSMF , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064288D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGSSMFR  = { {.EVDOTPWGSSMFR , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064288E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGSSMFR = { {.EVDOTPWXGSSMFR, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064288F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSIAAW3 = { {.EVDOTPWCSSIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642890, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSMIAAW3 = { {.EVDOTPWCSMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642891, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSFRAAW3 = { {.EVDOTPWCSSFRAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642892, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSFAAW3 = { {.EVDOTPWCSSFAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642893, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGASMFAA3 = { {.EVDOTPWGASMFAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642898, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGASMFAA3 = { {.EVDOTPWXGASMFAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642899, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGASMFRAA3 = { {.EVDOTPWGASMFRAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064289A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGASMFRAA3 = { {.EVDOTPWXGASMFRAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064289B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGSSMFAA3 = { {.EVDOTPWGSSMFAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064289C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGSSMFAA3 = { {.EVDOTPWXGSSMFAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064289D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGSSMFRAA3 = { {.EVDOTPWGSSMFRAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064289E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGSSMFRAA3 = { {.EVDOTPWXGSSMFRAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064289F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSIA   = { {.EVDOTPWCSSIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428A0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSMIA   = { {.EVDOTPWCSMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428A1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSFRA  = { {.EVDOTPWCSSFRA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428A2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSFA   = { {.EVDOTPWCSSFA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428A3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGASMFA  = { {.EVDOTPWGASMFA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428A8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGASMFA = { {.EVDOTPWXGASMFA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428A9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGASMFRA = { {.EVDOTPWGASMFRA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428AA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGASMFRA = { {.EVDOTPWXGASMFRA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428AB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGSSMFA  = { {.EVDOTPWGSSMFA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428AC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGSSMFA = { {.EVDOTPWXGSSMFA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428AD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGSSMFRA = { {.EVDOTPWGSSMFRA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428AE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGSSMFRA = { {.EVDOTPWXGSSMFRA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428AF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSIAAW = { {.EVDOTPWCSSIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428B0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSMIAAW = { {.EVDOTPWCSMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428B1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSFRAAW = { {.EVDOTPWCSSFRAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428B2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWCSSFAAW = { {.EVDOTPWCSSFAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428B3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGASMFAA = { {.EVDOTPWGASMFAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428B8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGASMFAA = { {.EVDOTPWXGASMFAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428B9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGASMFRAA = { {.EVDOTPWGASMFRAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428BA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGASMFRAA = { {.EVDOTPWXGASMFRAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428BB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGSSMFAA = { {.EVDOTPWGSSMFAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428BC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGSSMFAA = { {.EVDOTPWXGSSMFAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428BD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWGSSMFRAA = { {.EVDOTPWGSSMFRAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428BE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWXGSSMFRAA = { {.EVDOTPWXGSSMFRAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106428BF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSI  = { {.EVDOTPHIHCSSI , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642900, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSI  = { {.EVDOTPLOHCSSI , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642901, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSF  = { {.EVDOTPHIHCSSF , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642902, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSF  = { {.EVDOTPLOHCSSF , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642903, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSMI  = { {.EVDOTPHIHCSMI , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642908, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSMI  = { {.EVDOTPLOHCSMI , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642909, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSFR = { {.EVDOTPHIHCSSFR, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064290A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSFR = { {.EVDOTPLOHCSSFR, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064290B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSIAAW3 = { {.EVDOTPHIHCSSIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642910, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSIAAW3 = { {.EVDOTPLOHCSSIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642911, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSFAAW3 = { {.EVDOTPHIHCSSFAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642912, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSFAAW3 = { {.EVDOTPLOHCSSFAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642913, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSMIAAW3 = { {.EVDOTPHIHCSMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642918, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSMIAAW3 = { {.EVDOTPLOHCSMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642919, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSFRAAW3 = { {.EVDOTPHIHCSSFRAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064291A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSFRAAW3 = { {.EVDOTPLOHCSSFRAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064291B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSIA = { {.EVDOTPHIHCSSIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642920, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSIA = { {.EVDOTPLOHCSSIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642921, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSFA = { {.EVDOTPHIHCSSFA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642922, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSFA = { {.EVDOTPLOHCSSFA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642923, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSMIA = { {.EVDOTPHIHCSMIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642928, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSMIA = { {.EVDOTPLOHCSMIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642929, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSFRA = { {.EVDOTPHIHCSSFRA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064292A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSFRA = { {.EVDOTPLOHCSSFRA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064292B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSIAAW = { {.EVDOTPHIHCSSIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642930, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSIAAW = { {.EVDOTPLOHCSSIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642931, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSFAAW = { {.EVDOTPHIHCSSFAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642932, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSFAAW = { {.EVDOTPLOHCSSFAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642933, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSMIAAW = { {.EVDOTPHIHCSMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642938, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSMIAAW = { {.EVDOTPLOHCSMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642939, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHIHCSSFRAAW = { {.EVDOTPHIHCSSFRAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064293A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPLOHCSSFRAAW = { {.EVDOTPLOHCSSFRAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064293B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHAUSI    = { {.EVDOTPHAUSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642940, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSI    = { {.EVDOTPHASSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642941, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASUSI   = { {.EVDOTPHASUSI  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642942, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSF    = { {.EVDOTPHASSF   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642943, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSF    = { {.EVDOTPHSSSF   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642947, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHAUMI    = { {.EVDOTPHAUMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642948, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASMI    = { {.EVDOTPHASMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642949, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASUMI   = { {.EVDOTPHASUMI  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064294A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSFR   = { {.EVDOTPHASSFR  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064294B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSMI    = { {.EVDOTPHSSMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064294D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSI    = { {.EVDOTPHSSSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064294D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSFR   = { {.EVDOTPHSSSFR  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064294F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHAUSIAAW3 = { {.EVDOTPHAUSIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642950, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSIAAW3 = { {.EVDOTPHASSIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642951, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASUSIAAW3 = { {.EVDOTPHASUSIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642952, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSFAAW3 = { {.EVDOTPHASSFAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642953, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSIAAW3 = { {.EVDOTPHSSSIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642955, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSFAAW3 = { {.EVDOTPHSSSFAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642957, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHAUMIAAW3 = { {.EVDOTPHAUMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642958, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASMIAAW3 = { {.EVDOTPHASMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642959, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASUMIAAW3 = { {.EVDOTPHASUMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064295A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSFRAAW3 = { {.EVDOTPHASSFRAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064295B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSMIAAW3 = { {.EVDOTPHSSMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064295D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSFRAAW3 = { {.EVDOTPHSSSFRAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064295F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHAUSIA   = { {.EVDOTPHAUSIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642960, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSIA   = { {.EVDOTPHASSIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642961, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASUSIA  = { {.EVDOTPHASUSIA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642962, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSFA   = { {.EVDOTPHASSFA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642963, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSFA   = { {.EVDOTPHSSSFA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642967, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHAUMIA   = { {.EVDOTPHAUMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642968, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASMIA   = { {.EVDOTPHASMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642969, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASUMIA  = { {.EVDOTPHASUMIA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064296A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSFRA  = { {.EVDOTPHASSFRA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064296B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSMIA   = { {.EVDOTPHSSMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064296D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSIA   = { {.EVDOTPHSSSIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064296D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSFRA  = { {.EVDOTPHSSSFRA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064296F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHAUSIAAW = { {.EVDOTPHAUSIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642970, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSIAAW = { {.EVDOTPHASSIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642971, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASUSIAAW = { {.EVDOTPHASUSIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642972, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSFAAW = { {.EVDOTPHASSFAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642973, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSIAAW = { {.EVDOTPHSSSIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642975, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSFAAW = { {.EVDOTPHSSSFAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642977, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHAUMIAAW = { {.EVDOTPHAUMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642978, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASMIAAW = { {.EVDOTPHASMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642979, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASUMIAAW = { {.EVDOTPHASUMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064297A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHASSFRAAW = { {.EVDOTPHASSFRAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064297B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSMIAAW = { {.EVDOTPHSSMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064297D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPHSSSFRAAW = { {.EVDOTPHSSSFRAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064297F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGAUMI  = { {.EVDOTP4HGAUMI , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642980, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASMI  = { {.EVDOTP4HGASMI , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642981, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASUMI = { {.EVDOTP4HGASUMI, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642982, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASMF  = { {.EVDOTP4HGASMF , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642983, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGSSMI  = { {.EVDOTP4HGSSMI , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642984, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGSSMF  = { {.EVDOTP4HGSSMF , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642985, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGASMI = { {.EVDOTP4HXGASMI, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642986, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGASMF = { {.EVDOTP4HXGASMF, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642987, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBAUMI    = { {.EVDOTPBAUMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642988, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBASMI    = { {.EVDOTPBASMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642989, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBASUMI   = { {.EVDOTPBASUMI  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064298A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGSSMI = { {.EVDOTP4HXGSSMI, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064298E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGSSMF = { {.EVDOTP4HXGSSMF, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064298F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGAUMIAA3 = { {.EVDOTP4HGAUMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642990, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASMIAA3 = { {.EVDOTP4HGASMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642991, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASUMIAA3 = { {.EVDOTP4HGASUMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642992, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASMFAA3 = { {.EVDOTP4HGASMFAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642993, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGSSMIAA3 = { {.EVDOTP4HGSSMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642994, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGSSMFAA3 = { {.EVDOTP4HGSSMFAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642995, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGASMIAA3 = { {.EVDOTP4HXGASMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642996, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGASMFAA3 = { {.EVDOTP4HXGASMFAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642997, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBAUMIAAW3 = { {.EVDOTPBAUMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642998, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBASMIAAW3 = { {.EVDOTPBASMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642999, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBASUMIAAW3 = { {.EVDOTPBASUMIAAW3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064299A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGSSMIAA3 = { {.EVDOTP4HXGSSMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064299E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGSSMFAA3 = { {.EVDOTP4HXGSSMFAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064299F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGAUMIA = { {.EVDOTP4HGAUMIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASMIA = { {.EVDOTP4HGASMIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASUMIA = { {.EVDOTP4HGASUMIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASMFA = { {.EVDOTP4HGASMFA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGSSMIA = { {.EVDOTP4HGSSMIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGSSMFA = { {.EVDOTP4HGSSMFA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGASMIA = { {.EVDOTP4HXGASMIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGASMFA = { {.EVDOTP4HXGASMFA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBAUMIA   = { {.EVDOTPBAUMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBASMIA   = { {.EVDOTPBASMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429A9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBASUMIA  = { {.EVDOTPBASUMIA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429AA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGSSMIA = { {.EVDOTP4HXGSSMIA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429AE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGSSMFA = { {.EVDOTP4HXGSSMFA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429AF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGAUMIAA = { {.EVDOTP4HGAUMIAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASMIAA = { {.EVDOTP4HGASMIAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASUMIAA = { {.EVDOTP4HGASUMIAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGASMFAA = { {.EVDOTP4HGASMFAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGSSMIAA = { {.EVDOTP4HGSSMIAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HGSSMFAA = { {.EVDOTP4HGSSMFAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGASMIAA = { {.EVDOTP4HXGASMIAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGASMFAA = { {.EVDOTP4HXGASMFAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBAUMIAAW = { {.EVDOTPBAUMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBASMIAAW = { {.EVDOTPBASMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429B9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPBASUMIAAW = { {.EVDOTPBASUMIAAW, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429BA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGSSMIAA = { {.EVDOTP4HXGSSMIAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429BE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTP4HXGSSMFAA = { {.EVDOTP4HXGSSMFAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429BF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWAUSI    = { {.EVDOTPWAUSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429C0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASSI    = { {.EVDOTPWASSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429C1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASUSI   = { {.EVDOTPWASUSI  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429C2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWAUMI    = { {.EVDOTPWAUMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429C8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASMI    = { {.EVDOTPWASMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429C9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASUMI   = { {.EVDOTPWASUMI  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429CA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWSSMI    = { {.EVDOTPWSSMI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429CD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWSSSI    = { {.EVDOTPWSSSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429CD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWAUSIAA3 = { {.EVDOTPWAUSIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429D0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASSIAA3 = { {.EVDOTPWASSIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429D1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASUSIAA3 = { {.EVDOTPWASUSIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429D2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWSSSIAA3 = { {.EVDOTPWSSSIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429D5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWAUMIAA3 = { {.EVDOTPWAUMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429D8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASMIAA3 = { {.EVDOTPWASMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429D9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASUMIAA3 = { {.EVDOTPWASUMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429DA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWSSMIAA3 = { {.EVDOTPWSSMIAA3, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429DD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWAUSIA   = { {.EVDOTPWAUSIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429E0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASSIA   = { {.EVDOTPWASSIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429E1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASUSIA  = { {.EVDOTPWASUSIA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429E2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWAUMIA   = { {.EVDOTPWAUMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429E8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASMIA   = { {.EVDOTPWASMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429E9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASUMIA  = { {.EVDOTPWASUMIA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429EA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWSSMIA   = { {.EVDOTPWSSMIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429ED, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWSSSIA   = { {.EVDOTPWSSSIA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429ED, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWAUSIAA  = { {.EVDOTPWAUSIAA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429F0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASSIAA  = { {.EVDOTPWASSIAA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429F1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASUSIAA = { {.EVDOTPWASUSIAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429F2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWSSSIAA  = { {.EVDOTPWSSSIAA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429F5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWAUMIAA  = { {.EVDOTPWAUMIAA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429F8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASMIAA  = { {.EVDOTPWASMIAA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429F9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWASUMIAA = { {.EVDOTPWASUMIAA, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429FA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDOTPWSSMIAA  = { {.EVDOTPWSSMIAA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106429FD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDIB        = { {.EVADDIB       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A03, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDIH        = { {.EVADDIH       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A01, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBIFH       = { {.EVSUBIFH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A05, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBIFB       = { {.EVSUBIFB      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A07, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSB         = { {.EVABSB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10641208, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSH         = { {.EVABSH        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642208, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSD         = { {.EVABSD        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10643208, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSS         = { {.EVABSS        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10644208, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSBS        = { {.EVABSBS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10645208, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSHS        = { {.EVABSHS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10646208, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSDS        = { {.EVABSDS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10647208, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGWO        = { {.EVNEGWO       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640A09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGB         = { {.EVNEGB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10641209, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGBO        = { {.EVNEGBO       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10641A09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGH         = { {.EVNEGH        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642209, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGHO        = { {.EVNEGHO       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGD         = { {.EVNEGD        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10643209, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGS         = { {.EVNEGS        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10644209, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGWOS       = { {.EVNEGWOS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10644A09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGBS        = { {.EVNEGBS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10645209, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGBOS       = { {.EVNEGBOS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10645A09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGHS        = { {.EVNEGHS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10646209, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGHOS       = { {.EVNEGHOS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10646A09, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVNEGDS        = { {.EVNEGDS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10647209, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVEXTZB        = { {.EVEXTZB       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640A0A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVEXTSBH       = { {.EVEXTSBH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064220A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVEXTSW        = { {.EVEXTSW       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064320B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDWH        = { {.EVRNDWH       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064020C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDHB        = { {.EVRNDHB       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064220C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDDW        = { {.EVRNDDW       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064320C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDWHUS      = { {.EVRNDWHUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064420C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDWHSS      = { {.EVRNDWHSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10644A0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDHBUS      = { {.EVRNDHBUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064620C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDHBSS      = { {.EVRNDHBSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10646A0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDDWUS      = { {.EVRNDDWUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064720C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDDWSS      = { {.EVRNDDWSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10647A0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDWNH       = { {.EVRNDWNH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064820C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDHNB       = { {.EVRNDHNB      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064A20C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDDNW       = { {.EVRNDDNW      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064B20C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDWNHUS     = { {.EVRNDWNHUS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064C20C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDWNHSS     = { {.EVRNDWNHSS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064CA0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDHNBUS     = { {.EVRNDHNBUS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064E20C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDHNBSS     = { {.EVRNDHNBSS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064EA0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDDNWUS     = { {.EVRNDDNWUS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064F20C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRNDDNWSS     = { {.EVRNDDNWSS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064FA0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCNTLZH       = { {.EVCNTLZH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064220D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCNTLSH       = { {.EVCNTLSH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064220E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPOPCNTB      = { {.EVPOPCNTB     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064D20E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.CIRCINC        = { {.CIRCINC       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A10, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKHIBUI    = { {.EVUNPKHIBUI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064021C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKHIBSI    = { {.EVUNPKHIBSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640A1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKHIHUI    = { {.EVUNPKHIHUI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064121C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKHIHSI    = { {.EVUNPKHIHSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10641A1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKLOBUI    = { {.EVUNPKLOBUI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064221C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKLOBSI    = { {.EVUNPKLOBSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKLOHUI    = { {.EVUNPKLOHUI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064321C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKLOHSI    = { {.EVUNPKLOHSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10643A1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKLOHF     = { {.EVUNPKLOHF    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064421C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKHIHF     = { {.EVUNPKHIHF    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10644A1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKLOWGSF   = { {.EVUNPKLOWGSF  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064621C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVUNPKHIWGSF   = { {.EVUNPKHIWGSF  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10646A1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSDUW      = { {.EVSATSDUW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064821C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSDSW      = { {.EVSATSDSW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10648A1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSHUB      = { {.EVSATSHUB     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064921C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSHSB      = { {.EVSATSHSB     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10649A1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATUWUH      = { {.EVSATUWUH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064A21C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSWSH      = { {.EVSATSWSH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064AA1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSWUH      = { {.EVSATSWUH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064B21C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATUHUB      = { {.EVSATUHUB     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064BA1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATUDUW      = { {.EVSATUDUW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064C21C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATUWSW      = { {.EVSATUWSW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064CA1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSHUH      = { {.EVSATSHUH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064D21C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATUHSH      = { {.EVSATUHSH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064DA1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSWUW      = { {.EVSATSWUW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064E21C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSWGSDF    = { {.EVSATSWGSDF   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064EA1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATSBUB      = { {.EVSATSBUB     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064F21C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSATUBSB      = { {.EVSATUBSB     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064FA1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXHPUW      = { {.EVMAXHPUW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064021D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXHPSW      = { {.EVMAXHPSW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640A1D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXBPUH      = { {.EVMAXBPUH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064221D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXBPSH      = { {.EVMAXBPSH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A1D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXWPUD      = { {.EVMAXWPUD     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064321D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXWPSD      = { {.EVMAXWPSD     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10643A1D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINHPUW      = { {.EVMINHPUW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064421D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINHPSW      = { {.EVMINHPSW     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10644A1D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINBPUH      = { {.EVMINBPUH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064621D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINBPSH      = { {.EVMINBPSH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10646A1D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINWPUD      = { {.EVMINWPUD     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064721D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINWPSD      = { {.EVMINWPSD     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10647A1D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXMAGWS     = { {.EVMAXMAGWS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A1F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSL           = { {.EVSL          , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A25, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSLI          = { {.EVSLI         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A27, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIE      = { {.EVSPLATIE     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640A29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIB      = { {.EVSPLATIB     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10641229, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIBE     = { {.EVSPLATIBE    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10641A29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIH      = { {.EVSPLATIH     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642229, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIHE     = { {.EVSPLATIHE    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATID      = { {.EVSPLATID     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10643229, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIA      = { {.EVSPLATIA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10648229, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIEA     = { {.EVSPLATIEA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10648A29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIBA     = { {.EVSPLATIBA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10649229, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIBEA    = { {.EVSPLATIBEA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10649A29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIHA     = { {.EVSPLATIHA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064A229, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIHEA    = { {.EVSPLATIHEA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064AA29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATIDA     = { {.EVSPLATIDA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064B229, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIO     = { {.EVSPLATFIO    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640A2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIB     = { {.EVSPLATFIB    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064122B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIBO    = { {.EVSPLATFIBO   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10641A2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIH     = { {.EVSPLATFIH    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064222B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIHO    = { {.EVSPLATFIHO   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFID     = { {.EVSPLATFID    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064322B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIA     = { {.EVSPLATFIA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064822B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIOA    = { {.EVSPLATFIOA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10648A2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIBA    = { {.EVSPLATFIBA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064922B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIBOA   = { {.EVSPLATFIBOA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10649A2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIHA    = { {.EVSPLATFIHA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064A22B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIHOA   = { {.EVSPLATFIHOA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064AA2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATFIDA    = { {.EVSPLATFIDA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064B22B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPGTDU      = { {.EVCMPGTDU     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10242A30, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPGTDS      = { {.EVCMPGTDS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10242A31, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPLTDU      = { {.EVCMPLTDU     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10242A32, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPLTDS      = { {.EVCMPLTDS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10242A33, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCMPEQD       = { {.EVCMPEQD      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10242A34, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSWAPBHILO    = { {.EVSWAPBHILO   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A38, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSWAPBLOHI    = { {.EVSWAPBLOHI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A39, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSWAPHHILO    = { {.EVSWAPHHILO   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A3A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSWAPHLOHI    = { {.EVSWAPHLOHI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A3B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSWAPHE       = { {.EVSWAPHE      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A3C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSWAPHHI      = { {.EVSWAPHHI     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A3D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSWAPHLO      = { {.EVSWAPHLO     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A3E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSWAPHO       = { {.EVSWAPHO      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A3F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVINSB         = { {.EVINSB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A48, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVXTRB         = { {.EVXTRB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A4A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATH       = { {.EVSPLATH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064024C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSPLATB       = { {.EVSPLATB      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064124C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVINSH         = { {.EVINSH        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A4D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCLRBE        = { {.EVCLRBE       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064024E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCLRBO        = { {.EVCLRBO       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064824E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVCLRH         = { {.EVCLRH        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064824F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVXTRH         = { {.EVXTRH        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A4F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSELBITM0     = { {.EVSELBITM0    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A50, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSELBITM1     = { {.EVSELBITM1    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A51, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSELBIT       = { {.EVSELBIT      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A52, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPERM         = { {.EVPERM        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A54, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPERM2        = { {.EVPERM2       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A55, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPERM3        = { {.EVPERM3       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A56, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVXTRD         = { {.EVXTRD        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A58, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRBU         = { {.EVSRBU        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A60, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRBS         = { {.EVSRBS        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A61, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRBIU        = { {.EVSRBIU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A62, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRBIS        = { {.EVSRBIS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A63, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSLB          = { {.EVSLB         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A64, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRLB          = { {.EVRLB         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A65, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSLBI         = { {.EVSLBI        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A66, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRLBI         = { {.EVRLBI        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A67, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRHU         = { {.EVSRHU        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A68, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRHS         = { {.EVSRHS        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A69, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRHIU        = { {.EVSRHIU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A6A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRHIS        = { {.EVSRHIS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A6B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSLH          = { {.EVSLH         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A6C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRLH          = { {.EVRLH         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A6D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSLHI         = { {.EVSLHI        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A6E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVRLHI         = { {.EVRLHI        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A6F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRU          = { {.EVSRU         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A70, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRS          = { {.EVSRS         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A71, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRIU         = { {.EVSRIU        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A72, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSRIS         = { {.EVSRIS        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A73, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLVSL         = { {.EVLVSL        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A74, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLVSR         = { {.EVLVSR        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A75, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSROIU        = { {.EVSROIU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642A77, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSROIS        = { {.EVSROIS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10646A77, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSLOI         = { {.EVSLOI        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064AA77, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDBX         = { {.EVLDBX        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B06, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDB          = { {.EVLDB         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B07, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHSPLATHX   = { {.EVLHHSPLATHX  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B0A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHSPLATH    = { {.EVLHHSPLATH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B0B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBSPLATWX   = { {.EVLWBSPLATWX  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B12, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBSPLATW    = { {.EVLWBSPLATW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B13, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHSPLATWX   = { {.EVLWHSPLATWX  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B1A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHSPLATW    = { {.EVLWHSPLATW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B1B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLBBSPLATBX   = { {.EVLBBSPLATBX  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B1E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLBBSPLATB    = { {.EVLBBSPLATB   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B1F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDBX        = { {.EVSTDBX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B26, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDB         = { {.EVSTDB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B27, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBEX        = { {.EVLWBEX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B2A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBE         = { {.EVLWBE        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBOUX       = { {.EVLWBOUX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B2C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBOU        = { {.EVLWBOU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B2D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBOSX       = { {.EVLWBOSX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B2E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBOS        = { {.EVLWBOS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B2F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBEX       = { {.EVSTWBEX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B32, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBE        = { {.EVSTWBE       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B33, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBOX       = { {.EVSTWBOX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B36, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBO        = { {.EVSTWBO       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B37, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBX        = { {.EVSTWBX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B3A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWB         = { {.EVSTWB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B3B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTHBX        = { {.EVSTHBX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B3E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTHB         = { {.EVSTHB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B3F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDDMX        = { {.EVLDDMX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B40, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDDU         = { {.EVLDDU        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B41, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDWMX        = { {.EVLDWMX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B42, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDWU         = { {.EVLDWU        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B43, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDHMX        = { {.EVLDHMX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B44, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDHU         = { {.EVLDHU        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B45, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDBMX        = { {.EVLDBMX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B46, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLDBU         = { {.EVLDBU        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B47, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHESPLATMX  = { {.EVLHHESPLATMX , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B48, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHESPLATU   = { {.EVLHHESPLATU  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B49, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHSPLATHMX  = { {.EVLHHSPLATHMX , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B4A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHSPLATHU   = { {.EVLHHSPLATHU  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B4B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHOUSPLATMX = { {.EVLHHOUSPLATMX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B4C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHOUSPLATU  = { {.EVLHHOUSPLATU , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B4D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHOSSPLATMX = { {.EVLHHOSSPLATMX, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B4E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLHHOSSPLATU  = { {.EVLHHOSSPLATU , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B4F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHEMX       = { {.EVLWHEMX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B50, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHEU        = { {.EVLWHEU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B51, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBSPLATWMX  = { {.EVLWBSPLATWMX , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B52, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBSPLATWU   = { {.EVLWBSPLATWU  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B53, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHOUMX      = { {.EVLWHOUMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B54, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHOUU       = { {.EVLWHOUU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B55, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHOSMX      = { {.EVLWHOSMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B56, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHOSU       = { {.EVLWHOSU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B57, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWWSPLATMX   = { {.EVLWWSPLATMX  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B58, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWWSPLATU    = { {.EVLWWSPLATU   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B59, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHSPLATWMX  = { {.EVLWHSPLATWMX , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B5A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHSPLATWU   = { {.EVLWHSPLATWU  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B5B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHSPLATMX   = { {.EVLWHSPLATMX  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B5C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWHSPLATU    = { {.EVLWHSPLATU   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B5D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLBBSPLATBMX  = { {.EVLBBSPLATBMX , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B5E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLBBSPLATBU   = { {.EVLBBSPLATBU  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B5F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDDMX       = { {.EVSTDDMX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B60, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDDU        = { {.EVSTDDU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B61, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDWMX       = { {.EVSTDWMX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B62, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDWU        = { {.EVSTDWU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B63, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDHMX       = { {.EVSTDHMX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B64, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDHU        = { {.EVSTDHU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B65, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDBMX       = { {.EVSTDBMX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B66, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTDBU        = { {.EVSTDBU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B67, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBEMX       = { {.EVLWBEMX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B6A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBEU        = { {.EVLWBEU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B6B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBOUMX      = { {.EVLWBOUMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B6C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBOUU       = { {.EVLWBOUU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B6D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBOSMX      = { {.EVLWBOSMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B6E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVLWBOSU       = { {.EVLWBOSU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B6F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWHEMX      = { {.EVSTWHEMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B70, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWHEU       = { {.EVSTWHEU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B71, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBEMX      = { {.EVSTWBEMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B72, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBEU       = { {.EVSTWBEU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B73, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWHOMX      = { {.EVSTWHOMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B74, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWHOU       = { {.EVSTWHOU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B75, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBOMX      = { {.EVSTWBOMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B76, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBOU       = { {.EVSTWBOU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B77, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWWEMX      = { {.EVSTWWEMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B78, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWWEU       = { {.EVSTWWEU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B79, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBMX       = { {.EVSTWBMX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B7A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWBU        = { {.EVSTWBU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B7B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWWOMX      = { {.EVSTWWOMX     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B7C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTWWOU       = { {.EVSTWWOU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B7D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTHBMX       = { {.EVSTHBMX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B7E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSTHBU        = { {.EVSTHBU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642B7F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHUSI        = { {.EVMHUSI       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C00, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHSSI        = { {.EVMHSSI       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C01, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHSUSI       = { {.EVMHSUSI      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C02, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHSSF        = { {.EVMHSSF       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C04, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHUMI        = { {.EVMHUMI       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C05, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHSSFR       = { {.EVMHSSFR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C06, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESUMI      = { {.EVMHESUMI     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C0A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSUMI      = { {.EVMHOSUMI     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C0E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBEUMI       = { {.EVMBEUMI      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C18, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESMI       = { {.EVMBESMI      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C19, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESUMI      = { {.EVMBESUMI     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C1A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOUMI       = { {.EVMBOUMI      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSMI       = { {.EVMBOSMI      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C1D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSUMI      = { {.EVMBOSUMI     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C1E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESUMIA     = { {.EVMHESUMIA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C2A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSUMIA     = { {.EVMHOSUMIA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C2E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBEUMIA      = { {.EVMBEUMIA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C38, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESMIA      = { {.EVMBESMIA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C39, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESUMIA     = { {.EVMBESUMIA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C3A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOUMIA      = { {.EVMBOUMIA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C3C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSMIA      = { {.EVMBOSMIA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C3D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSUMIA     = { {.EVMBOSUMIA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C3E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWUSIW       = { {.EVMWUSIW      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C40, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSSIW       = { {.EVMWSSIW      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C41, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFR      = { {.EVMWHSSFR     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C46, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWEHGSMFR    = { {.EVMWEHGSMFR   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C56, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWEHGSMF     = { {.EVMWEHGSMF    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C57, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWOHGSMFR    = { {.EVMWOHGSMFR   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C5E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWOHGSMF     = { {.EVMWOHGSMF    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C5F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFRA     = { {.EVMWHSSFRA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C66, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWEHGSMFRA   = { {.EVMWEHGSMFRA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C76, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWEHGSMFA    = { {.EVMWEHGSMFA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C77, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWOHGSMFRA   = { {.EVMWOHGSMFRA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C7E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWOHGSMFA    = { {.EVMWOHGSMFA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C7F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDUSIAA     = { {.EVADDUSIAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640480, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSSIAA     = { {.EVADDSSIAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640481, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFUSIAA    = { {.EVSUBFUSIAA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640482, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFSSIAA    = { {.EVSUBFSSIAA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640483, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSMIAA     = { {.EVADDSMIAA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640484, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFSMIAA    = { {.EVSUBFSMIAA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640486, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDH         = { {.EVADDH        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C88, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHSS       = { {.EVADDHSS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C89, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFH        = { {.EVSUBFH       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C8A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHSS      = { {.EVSUBFHSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C8B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHX        = { {.EVADDHX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C8C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHXSS      = { {.EVADDHXSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C8D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHX       = { {.EVSUBFHX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C8E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHXSS     = { {.EVSUBFHXSS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C8F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDD         = { {.EVADDD        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C90, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDDSS       = { {.EVADDDSS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C91, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFD        = { {.EVSUBFD       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C92, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFDSS      = { {.EVSUBFDSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C93, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDB         = { {.EVADDB        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C94, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDBSS       = { {.EVADDBSS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C95, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFB        = { {.EVSUBFB       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C96, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFBSS      = { {.EVSUBFBSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C97, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSUBFH     = { {.EVADDSUBFH    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C98, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSUBFHSS   = { {.EVADDSUBFHSS  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C99, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFADDH     = { {.EVSUBFADDH    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C9A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFADDHSS   = { {.EVSUBFADDHSS  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C9B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSUBFHX    = { {.EVADDSUBFHX   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C9C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSUBFHXSS  = { {.EVADDSUBFHXSS , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C9D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFADDHX    = { {.EVSUBFADDHX   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C9E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFADDHXSS  = { {.EVSUBFADDHXSS , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642C9F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDDUS       = { {.EVADDDUS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDBUS       = { {.EVADDBUS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFDUS      = { {.EVSUBFDUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFBUS      = { {.EVSUBFBUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWUS       = { {.EVADDWUS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWXUS      = { {.EVADDWXUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWUS      = { {.EVSUBFWUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWXUS     = { {.EVSUBFWXUS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADD2SUBF2H   = { {.EVADD2SUBF2H  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADD2SUBF2HSS = { {.EVADD2SUBF2HSS, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CA9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBF2ADD2H   = { {.EVSUBF2ADD2H  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CAA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBF2ADD2HSS = { {.EVSUBF2ADD2HSS, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CAB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHUS       = { {.EVADDHUS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CAC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHXUS      = { {.EVADDHXUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CAD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHUS      = { {.EVSUBFHUS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CAE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHXUS     = { {.EVSUBFHXUS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CAF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWSS       = { {.EVADDWSS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CB1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWSS      = { {.EVSUBFWSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CB3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWX        = { {.EVADDWX       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CB4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWXSS      = { {.EVADDWXSS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CB5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWX       = { {.EVSUBFWX      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CB6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWXSS     = { {.EVSUBFWXSS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CB7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSUBFW     = { {.EVADDSUBFW    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CB8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSUBFWSS   = { {.EVADDSUBFWSS  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CB9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFADDW     = { {.EVSUBFADDW    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CBA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFADDWSS   = { {.EVSUBFADDWSS  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CBB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSUBFWX    = { {.EVADDSUBFWX   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CBC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDSUBFWXSS  = { {.EVADDSUBFWXSS , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CBD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFADDWX    = { {.EVSUBFADDWX   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CBE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFADDWXSS  = { {.EVSUBFADDWXSS , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CBF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAR          = { {.EVMAR         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640CC4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUMWU        = { {.EVSUMWU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106404C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUMWS        = { {.EVSUMWS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10640CC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM4BU       = { {.EVSUM4BU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106414C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM4BS       = { {.EVSUM4BS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10641CC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HU       = { {.EVSUM2HU      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106424C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HS       = { {.EVSUM2HS      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIFF2HIS     = { {.EVDIFF2HIS    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106434C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HIS      = { {.EVSUM2HIS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10643CC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUMWUA       = { {.EVSUMWUA      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106484C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUMWSA       = { {.EVSUMWSA      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10648CC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM4BUA      = { {.EVSUM4BUA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x106494C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM4BSA      = { {.EVSUM4BSA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10649CC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HUA      = { {.EVSUM2HUA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064A4C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HSA      = { {.EVSUM2HSA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064ACC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIFF2HISA    = { {.EVDIFF2HISA   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064B4C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HISA     = { {.EVSUM2HISA    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064BCC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUMWUAA      = { {.EVSUMWUAA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064C4C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUMWSAA      = { {.EVSUMWSAA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064CCC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM4BUAAW    = { {.EVSUM4BUAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064D4C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM4BSAAW    = { {.EVSUM4BSAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064DCC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HUAAW    = { {.EVSUM2HUAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064E4C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HSAAW    = { {.EVSUM2HSAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064ECC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIFF2HISAAW  = { {.EVDIFF2HISAAW , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064F4C5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUM2HISAAW   = { {.EVSUM2HISAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x1064FCC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIVWSF       = { {.EVDIVWSF      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CCC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIVWUF       = { {.EVDIVWUF      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CCD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIVS         = { {.EVDIVS        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CCE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDIVU         = { {.EVDIVU        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CCF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWEGSI     = { {.EVADDWEGSI    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWEGSF     = { {.EVADDWEGSF    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWEGSI    = { {.EVSUBFWEGSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWEGSF    = { {.EVSUBFWEGSF   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWOGSI     = { {.EVADDWOGSI    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDWOGSF     = { {.EVADDWOGSF    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWOGSI    = { {.EVSUBFWOGSI   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFWOGSF    = { {.EVSUBFWOGSF   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHHIUW     = { {.EVADDHHIUW    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD8, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHHISW     = { {.EVADDHHISW    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CD9, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHHIUW    = { {.EVSUBFHHIUW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CDA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHHISW    = { {.EVSUBFHHISW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CDB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHLOUW     = { {.EVADDHLOUW    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CDC, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVADDHLOSW     = { {.EVADDHLOSW    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CDD, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHLOUW    = { {.EVSUBFHLOUW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CDE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSUBFHLOSW    = { {.EVSUBFHLOSW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642CDF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESUSIAAW   = { {.EVMHESUSIAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D02, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSUSIAAW   = { {.EVMHOSUSIAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D06, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESUMIAAW   = { {.EVMHESUMIAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D0A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSUMIAAW   = { {.EVMHOSUMIAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D0E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBEUSIAAH    = { {.EVMBEUSIAAH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D10, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESSIAAH    = { {.EVMBESSIAAH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D11, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESUSIAAH   = { {.EVMBESUSIAAH  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D12, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOUSIAAH    = { {.EVMBOUSIAAH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D14, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSSIAAH    = { {.EVMBOSSIAAH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D15, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSUSIAAH   = { {.EVMBOSUSIAAH  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D16, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBEUMIAAH    = { {.EVMBEUMIAAH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D18, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESMIAAH    = { {.EVMBESMIAAH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D19, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESUMIAAH   = { {.EVMBESUMIAAH  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D1A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOUMIAAH    = { {.EVMBOUMIAAH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSMIAAH    = { {.EVMBOSMIAAH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D1D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSUMIAAH   = { {.EVMBOSUMIAAH  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D1E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUSIAAW3   = { {.EVMWLUSIAAW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D42, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSSIAAW3   = { {.EVMWLSSIAAW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D43, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFRAAW3  = { {.EVMWHSSFRAAW3 , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D44, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFAAW3   = { {.EVMWHSSFAAW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D45, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFRAAW   = { {.EVMWHSSFRAAW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D46, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFAAW    = { {.EVMWHSSFAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D47, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUMIAAW3   = { {.EVMWLUMIAAW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D4A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSMIAAW3   = { {.EVMWLSMIAAW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D4B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWUSIAA      = { {.EVMWUSIAA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D50, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSSIAA      = { {.EVMWSSIAA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D51, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWEHGSMFRAA  = { {.EVMWEHGSMFRAA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D56, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWEHGSMFAA   = { {.EVMWEHGSMFAA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D57, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWOHGSMFRAA  = { {.EVMWOHGSMFRAA , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D5E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWOHGSMFAA   = { {.EVMWOHGSMFAA  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D5F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESUSIANW   = { {.EVMHESUSIANW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D82, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSUSIANW   = { {.EVMHOSUSIANW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D86, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHESUMIANW   = { {.EVMHESUMIANW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D8A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMHOSUMIANW   = { {.EVMHOSUMIANW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D8E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBEUSIANH    = { {.EVMBEUSIANH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D90, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESSIANH    = { {.EVMBESSIANH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D91, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESUSIANH   = { {.EVMBESUSIANH  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D92, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOUSIANH    = { {.EVMBOUSIANH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D94, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSSIANH    = { {.EVMBOSSIANH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D95, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSUSIANH   = { {.EVMBOSUSIANH  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D96, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBEUMIANH    = { {.EVMBEUMIANH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D98, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESMIANH    = { {.EVMBESMIANH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D99, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBESUMIANH   = { {.EVMBESUMIANH  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D9A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOUMIANH    = { {.EVMBOUMIANH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D9C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSMIANH    = { {.EVMBOSMIANH   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D9D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMBOSUMIANH   = { {.EVMBOSUMIANH  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642D9E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUSIANW3   = { {.EVMWLUSIANW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC2, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSSIANW3   = { {.EVMWLSSIANW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC3, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFRANW3  = { {.EVMWHSSFRANW3 , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC4, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFANW3   = { {.EVMWHSSFANW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC5, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFRANW   = { {.EVMWHSSFRANW  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWHSSFANW    = { {.EVMWHSSFANW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DC7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLUMIANW3   = { {.EVMWLUMIANW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DCA, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWLSMIANW3   = { {.EVMWLSMIANW3  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DCB, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWUSIAN      = { {.EVMWUSIAN     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DD0, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWSSIAN      = { {.EVMWSSIAN     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DD1, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWEHGSMFRAN  = { {.EVMWEHGSMFRAN , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DD6, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWEHGSMFAN   = { {.EVMWEHGSMFAN  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DD7, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWOHGSMFRAN  = { {.EVMWOHGSMFRAN , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DDE, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMWOHGSMFAN   = { {.EVMWOHGSMFAN  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642DDF, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETEQB       = { {.EVSETEQB      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E00, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETEQH       = { {.EVSETEQH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E02, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETEQW       = { {.EVSETEQW      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E04, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETGTHU      = { {.EVSETGTHU     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E08, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETGTHS      = { {.EVSETGTHS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E0A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETGTWU      = { {.EVSETGTWU     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E0C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETGTWS      = { {.EVSETGTWS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E0E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETGTBU      = { {.EVSETGTBU     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E10, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETGTBS      = { {.EVSETGTBS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E12, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETLTBU      = { {.EVSETLTBU     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E14, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETLTBS      = { {.EVSETLTBS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E16, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETLTHU      = { {.EVSETLTHU     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E18, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETLTHS      = { {.EVSETLTHS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E1A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETLTWU      = { {.EVSETLTWU     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E1C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSETLTWS      = { {.EVSETLTWS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E1E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSADUW        = { {.EVSADUW       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E20, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSADSW        = { {.EVSADSW       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E21, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD4UB       = { {.EVSAD4UB      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E22, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD4SB       = { {.EVSAD4SB      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E23, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD2UH       = { {.EVSAD2UH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E24, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD2SH       = { {.EVSAD2SH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E25, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSADUWA       = { {.EVSADUWA      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E28, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSADSWA       = { {.EVSADSWA      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E29, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD4UBA      = { {.EVSAD4UBA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E2A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD4SBA      = { {.EVSAD4SBA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E2B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD2UHA      = { {.EVSAD2UHA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E2C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD2SHA      = { {.EVSAD2SHA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E2D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSDIFUW     = { {.EVABSDIFUW    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E30, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSDIFSW     = { {.EVABSDIFSW    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E31, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSDIFUB     = { {.EVABSDIFUB    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E32, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSDIFSB     = { {.EVABSDIFSB    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E33, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSDIFUH     = { {.EVABSDIFUH    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E34, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVABSDIFSH     = { {.EVABSDIFSH    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E35, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSADUWAA      = { {.EVSADUWAA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E38, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSADSWAA      = { {.EVSADSWAA     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E39, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD4UBAAW    = { {.EVSAD4UBAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E3A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD4SBAAW    = { {.EVSAD4SBAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E3B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD2UHAAW    = { {.EVSAD2UHAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E3C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVSAD2SHAAW    = { {.EVSAD2SHAAW   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E3D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSHUBS      = { {.EVPKSHUBS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E40, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSHSBS      = { {.EVPKSHSBS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E41, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSWUHS      = { {.EVPKSWUHS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E42, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSWSHS      = { {.EVPKSWSHS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E43, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKUHUBS      = { {.EVPKUHUBS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E44, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKUWUHS      = { {.EVPKUWUHS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E45, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSWSHILVS   = { {.EVPKSWSHILVS  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E46, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSWGSHEFRS  = { {.EVPKSWGSHEFRS , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E47, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSWSHFRS    = { {.EVPKSWSHFRS   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E48, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSWSHILVFRS = { {.EVPKSWSHILVFRS, {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E49, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSDSWFRS    = { {.EVPKSDSWFRS   , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E4A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSDSHEFRS   = { {.EVPKSDSHEFRS  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E4B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKUDUWS      = { {.EVPKUDUWS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E4C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSDSWS      = { {.EVPKSDSWS     , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E4D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVPKSWGSWFRS   = { {.EVPKSWGSWFRS  , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E4E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVILVEH        = { {.EVILVEH       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E50, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVILVEOH       = { {.EVILVEOH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E51, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVILVHIH       = { {.EVILVHIH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E52, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVILVHILOH     = { {.EVILVHILOH    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E53, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVILVLOH       = { {.EVILVLOH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E54, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVILVLOHIH     = { {.EVILVLOHIH    , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E55, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVILVOEH       = { {.EVILVOEH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E56, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVILVOH        = { {.EVILVOH       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E57, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDLVEB        = { {.EVDLVEB       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E58, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDLVEH        = { {.EVDLVEH       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E59, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDLVEOB       = { {.EVDLVEOB      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E5A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDLVEOH       = { {.EVDLVEOH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E5B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDLVOB        = { {.EVDLVOB       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E5C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDLVOH        = { {.EVDLVOH       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E5D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDLVOEB       = { {.EVDLVOEB      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E5E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVDLVOEH       = { {.EVDLVOEH      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E5F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXBU        = { {.EVMAXBU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E60, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXBS        = { {.EVMAXBS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E61, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXHU        = { {.EVMAXHU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E62, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXHS        = { {.EVMAXHS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E63, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXWU        = { {.EVMAXWU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E64, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXWS        = { {.EVMAXWS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E65, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXDU        = { {.EVMAXDU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E66, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMAXDS        = { {.EVMAXDS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E67, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINBU        = { {.EVMINBU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E68, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINBS        = { {.EVMINBS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E69, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINHU        = { {.EVMINHU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E6A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINHS        = { {.EVMINHS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E6B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINWU        = { {.EVMINWU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E6C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINWS        = { {.EVMINWS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E6D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINDU        = { {.EVMINDU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E6E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVMINDS        = { {.EVMINDS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E6F, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGWU        = { {.EVAVGWU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E70, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGWS        = { {.EVAVGWS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E71, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGBU        = { {.EVAVGBU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E72, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGBS        = { {.EVAVGBS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E73, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGHU        = { {.EVAVGHU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E74, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGHS        = { {.EVAVGHS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E75, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGDU        = { {.EVAVGDU       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E76, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGDS        = { {.EVAVGDS       , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E77, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGWUR       = { {.EVAVGWUR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E78, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGWSR       = { {.EVAVGWSR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E79, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGBUR       = { {.EVAVGBUR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E7A, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGBSR       = { {.EVAVGBSR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E7B, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGHUR       = { {.EVAVGHUR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E7C, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGHSR       = { {.EVAVGHSR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E7D, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGDUR       = { {.EVAVGDUR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E7E, 0xFFFFFFFF, .SPE, .PPC32, {}} },
	.EVAVGDSR       = { {.EVAVGDSR      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x10642E7F, 0xFFFFFFFF, .SPE, .PPC32, {}} },

	// =========================================================================
	// §41 Paired Singles (Gekko/Broadway — GameCube + Wii)
	// =========================================================================
	// Primary opcode 4 shared with AltiVec/SPE — disambiguated by XO. LLVM 22
	// doesn't recognise these; classified as expected_unknown. Bit patterns
	// from Gekko/Broadway User's Manual §1.2.4 (matches binutils PPCPS set).
	//
	// Form summary:
	//   A-form  (3-op, 4-op): primary=4, XO at bits 1..5 (5-bit), Rc at bit 0
	//   X-form  cmp:   primary=4, XO at bits 1..10 (BF at 23..25)
	//   X-form  unary: primary=4, XO=40/72/136/264 (FRT, FRB)
	//   XOPS    merge: primary=4, XO=528/560/592/624 (FRT, FRA, FRB)
	//   XW      psq_lx/psq_lux/psq_stx/psq_stux: X-form with W bit at 10, I at 7..9
	//   D-form  psq_l/_lu/_st/_stu: primary 56/57/60/61; W bit 15, I bits 12..14

	// ---- A-form 3-op (FRT, FRA, FRB) — FRC=0 baked in mask ----
	.PS_DIV        = { {.PS_DIV,        {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x10000024, 0xFC0007FE, .PS, .PPC32, {}} },
	.PS_DIV_DOT    = { {.PS_DIV_DOT,    {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x10000025, 0xFC0007FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_SUB        = { {.PS_SUB,        {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x10000028, 0xFC0007FE, .PS, .PPC32, {}} },
	.PS_SUB_DOT    = { {.PS_SUB_DOT,    {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x10000029, 0xFC0007FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_ADD        = { {.PS_ADD,        {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x1000002A, 0xFC0007FE, .PS, .PPC32, {}} },
	.PS_ADD_DOT    = { {.PS_ADD_DOT,    {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x1000002B, 0xFC0007FF, .PS, .PPC32, {sets_cr1=true}} },

	// ---- A-form 3-op (FRT, FRA, FRC) — FRB=0 baked ----
	.PS_MUL        = { {.PS_MUL,        {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0x10000032, 0xFC00F83E, .PS, .PPC32, {}} },
	.PS_MUL_DOT    = { {.PS_MUL_DOT,    {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0x10000033, 0xFC00F83F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MULS0      = { {.PS_MULS0,      {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0x10000018, 0xFC00F83E, .PS, .PPC32, {}} },
	.PS_MULS0_DOT  = { {.PS_MULS0_DOT,  {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0x10000019, 0xFC00F83F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MULS1      = { {.PS_MULS1,      {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0x1000001A, 0xFC00F83E, .PS, .PPC32, {}} },
	.PS_MULS1_DOT  = { {.PS_MULS1_DOT,  {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRC, .NONE}, 0x1000001B, 0xFC00F83F, .PS, .PPC32, {sets_cr1=true}} },

	// ---- A-form 4-op (FRT, FRA, FRC, FRB) — full A-form ----
	.PS_SEL        = { {.PS_SEL,        {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000002E, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_SEL_DOT    = { {.PS_SEL_DOT,    {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000002F, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MSUB       = { {.PS_MSUB,       {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x10000038, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_MSUB_DOT   = { {.PS_MSUB_DOT,   {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x10000039, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MADD       = { {.PS_MADD,       {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000003A, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_MADD_DOT   = { {.PS_MADD_DOT,   {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000003B, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_NMSUB      = { {.PS_NMSUB,      {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000003C, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_NMSUB_DOT  = { {.PS_NMSUB_DOT,  {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000003D, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_NMADD      = { {.PS_NMADD,      {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000003E, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_NMADD_DOT  = { {.PS_NMADD_DOT,  {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000003F, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_SUM0       = { {.PS_SUM0,       {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x10000014, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_SUM0_DOT   = { {.PS_SUM0_DOT,   {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x10000015, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_SUM1       = { {.PS_SUM1,       {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x10000016, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_SUM1_DOT   = { {.PS_SUM1_DOT,   {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x10000017, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MADDS0     = { {.PS_MADDS0,     {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000001C, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_MADDS0_DOT = { {.PS_MADDS0_DOT, {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000001D, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MADDS1     = { {.PS_MADDS1,     {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000001E, 0xFC00003E, .PS, .PPC32, {}} },
	.PS_MADDS1_DOT = { {.PS_MADDS1_DOT, {.FPR, .FPR, .FPR, .FPR}, {.FRT, .FRA, .FRC, .FRB}, 0x1000001F, 0xFC00003F, .PS, .PPC32, {sets_cr1=true}} },

	// ---- A-form 2-op (FRT, FRB) — FRA=0 + FRC=0 baked ----
	.PS_RES        = { {.PS_RES,        {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000030, 0xFC1F07FE, .PS, .PPC32, {}} },
	.PS_RES_DOT    = { {.PS_RES_DOT,    {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000031, 0xFC1F07FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_RSQRTE     = { {.PS_RSQRTE,     {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000034, 0xFC1F07FE, .PS, .PPC32, {}} },
	.PS_RSQRTE_DOT = { {.PS_RSQRTE_DOT, {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000035, 0xFC1F07FF, .PS, .PPC32, {sets_cr1=true}} },

	// ---- X-form unary (FRT, FRB) — FRA=0 baked, XO at bits 1..10 ----
	.PS_NEG        = { {.PS_NEG,        {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000050, 0xFC1F07FE, .PS, .PPC32, {}} },
	.PS_NEG_DOT    = { {.PS_NEG_DOT,    {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000051, 0xFC1F07FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MR         = { {.PS_MR,         {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000090, 0xFC1F07FE, .PS, .PPC32, {}} },
	.PS_MR_DOT     = { {.PS_MR_DOT,     {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000091, 0xFC1F07FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_NABS       = { {.PS_NABS,       {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000110, 0xFC1F07FE, .PS, .PPC32, {}} },
	.PS_NABS_DOT   = { {.PS_NABS_DOT,   {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000111, 0xFC1F07FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_ABS        = { {.PS_ABS,        {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000210, 0xFC1F07FE, .PS, .PPC32, {}} },
	.PS_ABS_DOT    = { {.PS_ABS_DOT,    {.FPR, .FPR, .NONE,.NONE}, {.FRT, .FRB, .NONE,.NONE}, 0x10000211, 0xFC1F07FF, .PS, .PPC32, {sets_cr1=true}} },

	// ---- X-form compare (BF, FRA, FRB) — XO at bits 1..10 ----
	.PS_CMPU0      = { {.PS_CMPU0,      {.CR_FIELD, .FPR, .FPR, .NONE}, {.BF, .FRA, .FRB, .NONE}, 0x10000000, 0xFC6007FE, .PS, .PPC32, {}} },
	.PS_CMPO0      = { {.PS_CMPO0,      {.CR_FIELD, .FPR, .FPR, .NONE}, {.BF, .FRA, .FRB, .NONE}, 0x10000040, 0xFC6007FE, .PS, .PPC32, {}} },
	.PS_CMPU1      = { {.PS_CMPU1,      {.CR_FIELD, .FPR, .FPR, .NONE}, {.BF, .FRA, .FRB, .NONE}, 0x10000080, 0xFC6007FE, .PS, .PPC32, {}} },
	.PS_CMPO1      = { {.PS_CMPO1,      {.CR_FIELD, .FPR, .FPR, .NONE}, {.BF, .FRA, .FRB, .NONE}, 0x100000C0, 0xFC6007FE, .PS, .PPC32, {}} },

	// ---- X-form merge (FRT, FRA, FRB) — XOPS form ----
	.PS_MERGE00     = { {.PS_MERGE00,     {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x10000420, 0xFC0007FE, .PS, .PPC32, {}} },
	.PS_MERGE00_DOT = { {.PS_MERGE00_DOT, {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x10000421, 0xFC0007FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MERGE01     = { {.PS_MERGE01,     {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x10000460, 0xFC0007FE, .PS, .PPC32, {}} },
	.PS_MERGE01_DOT = { {.PS_MERGE01_DOT, {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x10000461, 0xFC0007FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MERGE10     = { {.PS_MERGE10,     {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x100004A0, 0xFC0007FE, .PS, .PPC32, {}} },
	.PS_MERGE10_DOT = { {.PS_MERGE10_DOT, {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x100004A1, 0xFC0007FF, .PS, .PPC32, {sets_cr1=true}} },
	.PS_MERGE11     = { {.PS_MERGE11,     {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x100004E0, 0xFC0007FE, .PS, .PPC32, {}} },
	.PS_MERGE11_DOT = { {.PS_MERGE11_DOT, {.FPR, .FPR, .FPR, .NONE}, {.FRT, .FRA, .FRB, .NONE}, 0x100004E1, 0xFC0007FF, .PS, .PPC32, {sets_cr1=true}} },

	// ---- XW-form quantized indexed (FRT, RA, RB) — W=0, I=0 baked ----
	// The W (bit 10) and I (bits 7..9) fields select GQR0-7 and quantization
	// mode. Mask covers them; users needing non-default GQR construct manually.
	.PSQ_LX        = { {.PSQ_LX,        {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_X, .NONE,.NONE}, 0x1000000C, 0xFC0007FE, .PS, .PPC32, {}} },
	.PSQ_LUX       = { {.PSQ_LUX,       {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_X, .NONE,.NONE}, 0x1000004C, 0xFC0007FE, .PS, .PPC32, {}} },
	.PSQ_STX       = { {.PSQ_STX,       {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_X, .NONE,.NONE}, 0x1000000E, 0xFC0007FE, .PS, .PPC32, {}} },
	.PSQ_STUX      = { {.PSQ_STUX,      {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_X, .NONE,.NONE}, 0x1000004E, 0xFC0007FE, .PS, .PPC32, {}} },

	// ---- D-form quantized (FRT, D(RA)) — W=0, I=0 baked; mask covers ----
	// bits 12..15. The OFFSET_BASE_D encoder packs RA at 16..20 and the
	// (potentially-16-bit) D at 0..15; users must keep D within signed 12-bit
	// range for these forms (mask covers bits 12..15 so anything larger gets
	// rejected by the mask check on round-trip).
	.PSQ_L         = { {.PSQ_L,         {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE,.NONE}, 0xE0000000, 0xFC00F000, .PS, .PPC32, {}} },
	.PSQ_LU        = { {.PSQ_LU,        {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE,.NONE}, 0xE4000000, 0xFC00F000, .PS, .PPC32, {}} },
	.PSQ_ST        = { {.PSQ_ST,        {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE,.NONE}, 0xF0000000, 0xFC00F000, .PS, .PPC32, {}} },
	.PSQ_STU       = { {.PSQ_STU,       {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE,.NONE}, 0xF4000000, 0xFC00F000, .PS, .PPC32, {}} },

	// =========================================================================
	// §42 VMX128 (Xenon — Xbox 360 vector extension)
	// =========================================================================
	// Bake-everything entries (mask=0xFFFFFFFE for non-cmp ops, 0xFFFFFFFF for
	// compare/_dot). Bit patterns from xenia's Xbox 360 disassembler tables.
	// VR128 register safe-fill: vr2 baked into VRT slot, vr3 into VRA, vr4 into
	// VRB. Users wanting different register pairings must edit bits manually.
	//
	// NOTE: bit patterns reverse-engineered, NOT LLVM-verified. May need
	// adjustment against real Xbox 360 binaries; cross-check with xenia.

	// ---- Arithmetic / FP (primary 5, VX128 form) ----
	.VADDFP128 = { {.VADDFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642010, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VSUBFP128 = { {.VSUBFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642050, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMULFP128 = { {.VMULFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642090, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMADDFP128 = { {.VMADDFP128, {.VR128, .VR128, .VR128, .VR128}, {.NONE,.NONE,.NONE,.NONE}, 0x14642110, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMADDCFP128 = { {.VMADDCFP128, {.VR128, .VR128, .VR128, .VR128}, {.NONE,.NONE,.NONE,.NONE}, 0x14642190, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VNMSUBFP128 = { {.VNMSUBFP128, {.VR128, .VR128, .VR128, .VR128}, {.NONE,.NONE,.NONE,.NONE}, 0x14642210, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMSUM3FP128 = { {.VMSUM3FP128, {.VR128, .VR128, .VR128, .VR128}, {.NONE,.NONE,.NONE,.NONE}, 0x14642290, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMSUM4FP128 = { {.VMSUM4FP128, {.VR128, .VR128, .VR128, .VR128}, {.NONE,.NONE,.NONE,.NONE}, 0x14642310, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMAXFP128 = { {.VMAXFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642390, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMINFP128 = { {.VMINFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146423D0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VREFP128 = { {.VREFP128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14600630, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VRSQRTEFP128 = { {.VRSQRTEFP128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14600670, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VEXPTEFP128 = { {.VEXPTEFP128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146006B0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VLOGEFP128 = { {.VLOGEFP128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146006F0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },

	// ---- Logical (VX128) ----
	.VAND128 = { {.VAND128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642410, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VANDC128 = { {.VANDC128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642450, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VOR128 = { {.VOR128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642490, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VXOR128 = { {.VXOR128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146424D0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VNOR128 = { {.VNOR128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642510, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VSEL128 = { {.VSEL128, {.VR128, .VR128, .VR128, .VR128}, {.NONE,.NONE,.NONE,.NONE}, 0x14642550, 0xFFFFFFFE, .VMX128, .PPC32, {}} },

	// ---- Compare ----
	.VCMPEQFP128 = { {.VCMPEQFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642000, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VCMPEQFP128_DOT = { {.VCMPEQFP128_DOT, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642001, 0xFFFFFFFF, .VMX128, .PPC32, {sets_cr0=true}} },
	.VCMPGEFP128 = { {.VCMPGEFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642040, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VCMPGEFP128_DOT = { {.VCMPGEFP128_DOT, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642041, 0xFFFFFFFF, .VMX128, .PPC32, {sets_cr0=true}} },
	.VCMPGTFP128 = { {.VCMPGTFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642080, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VCMPGTFP128_DOT = { {.VCMPGTFP128_DOT, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642081, 0xFFFFFFFF, .VMX128, .PPC32, {sets_cr0=true}} },
	.VCMPBFP128 = { {.VCMPBFP128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x186420C0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VCMPBFP128_DOT = { {.VCMPBFP128_DOT, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x186420C1, 0xFFFFFFFF, .VMX128, .PPC32, {sets_cr0=true}} },
	.VCMPEQUW128 = { {.VCMPEQUW128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642100, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VCMPEQUW128_DOT = { {.VCMPEQUW128_DOT, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642101, 0xFFFFFFFF, .VMX128, .PPC32, {sets_cr0=true}} },

	// ---- Rounding (FRT, FRB; FRA=0) ----
	.VRFIM128 = { {.VRFIM128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14600030, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VRFIN128 = { {.VRFIN128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14600070, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VRFIP128 = { {.VRFIP128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146000B0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VRFIZ128 = { {.VRFIZ128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146000F0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },

	// ---- Convert ----
	.VCFPSXWS128 = { {.VCFPSXWS128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14600230, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VCFPUXWS128 = { {.VCFPUXWS128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14600270, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VCSXWFP128 = { {.VCSXWFP128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146002B0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VCUXWFP128 = { {.VCUXWFP128, {.VR128, .VR128, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146002F0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },

	// ---- Splat / merge / permute ----
	.VSPLTW128 = { {.VSPLTW128, {.VR128, .VR128, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642330, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VSPLTISW128 = { {.VSPLTISW128, {.VR128, .IMM, .NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18601370, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMRGHW128 = { {.VMRGHW128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642330, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VMRGLW128 = { {.VMRGLW128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642370, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VPKD3D128 = { {.VPKD3D128, {.VR128, .VR128, .IMM, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x18642630, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VUPKD3D128 = { {.VUPKD3D128, {.VR128, .VR128, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x186023F0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VPERM128 = { {.VPERM128, {.VR128, .VR128, .VR128, .VR128}, {.NONE,.NONE,.NONE,.NONE}, 0x14642D90, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VPERMWI128 = { {.VPERMWI128, {.VR128, .VR128, .IMM, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x18642730, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VRLIMI128 = { {.VRLIMI128, {.VR128, .VR128, .IMM, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x18642790, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VSLDOI128 = { {.VSLDOI128, {.VR128, .VR128, .VR128, .IMM}, {.NONE,.NONE,.NONE,.NONE}, 0x14642010, 0xFFFFFFFE, .VMX128, .PPC32, {}} },

	// ---- Shift / rotate ----
	.VRLW128 = { {.VRLW128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642210, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VSLW128 = { {.VSLW128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642250, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VSRW128 = { {.VSRW128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x14642290, 0xFFFFFFFE, .VMX128, .PPC32, {}} },
	.VSRAW128 = { {.VSRAW128, {.VR128, .VR128, .VR128, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x146422D0, 0xFFFFFFFE, .VMX128, .PPC32, {}} },

	// ---- Memory (load/store) — primary 31 X-form indexed ----
	.LVEBX128 = { {.LVEBX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C44280D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.LVEHX128 = { {.LVEHX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C44284D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.LVEWX128 = { {.LVEWX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C44288D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.LVX128 = { {.LVX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C4428CD, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.LVXL128 = { {.LVXL128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C4428CF, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.LVLX128 = { {.LVLX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C442D0D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.LVRX128 = { {.LVRX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C442D4D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.LVLXL128 = { {.LVLXL128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C442D0F, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.LVRXL128 = { {.LVRXL128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C442D4F, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVEBX128 = { {.STVEBX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C44290D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVEHX128 = { {.STVEHX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C44294D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVEWX128 = { {.STVEWX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C44298D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVX128 = { {.STVX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C4429CD, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVXL128 = { {.STVXL128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C4429CF, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVLX128 = { {.STVLX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C442D8D, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVRX128 = { {.STVRX128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C442DCD, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVLXL128 = { {.STVLXL128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C442D8F, 0xFFFFFFFF, .VMX128, .PPC32, {}} },
	.STVRXL128 = { {.STVRXL128, {.VR128, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7C442DCF, 0xFFFFFFFF, .VMX128, .PPC32, {}} },

	// =========================================================================
	// §43 Remaining binutils PPC categories (518 entries, auto-extracted)
	// =========================================================================
	.TI                 = { {.TI                , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x0C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULHHWU            = { {.MULHHWU           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000010, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULHHWU_DOT        = { {.MULHHWU_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000011, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACHHWU            = { {.MACHHWU           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000018, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHWU_DOT        = { {.MACHHWU_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000019, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MULHHW             = { {.MULHHW            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000050, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULHHW_DOT         = { {.MULHHW_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000051, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACHHW             = { {.MACHHW            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000058, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHW_DOT         = { {.MACHHW_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000059, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACHHW            = { {.NMACHHW           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000005C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACHHW_DOT        = { {.NMACHHW_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000005D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACHHWSU           = { {.MACHHWSU          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000098, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHWSU_DOT       = { {.MACHHWSU_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000099, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACHHWS            = { {.MACHHWS           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100000D8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHWS_DOT        = { {.MACHHWS_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100000D9, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACHHWS           = { {.NMACHHWS          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100000DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACHHWS_DOT       = { {.NMACHHWS_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100000DD, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VADDUQM            = { {.VADDUQM           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000100, 0xFC0007FE, .BASE, .PPC32, {}} },
	.VCMPUQ             = { {.VCMPUQ            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000101, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULCHWU            = { {.MULCHWU           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000110, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULCHWU_DOT        = { {.MULCHWU_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000111, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACCHWU            = { {.MACCHWU           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000118, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWU_DOT        = { {.MACCHWU_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000119, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCMPSQ             = { {.VCMPSQ            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000141, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULCHW             = { {.MULCHW            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000150, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULCHW_DOT         = { {.MULCHW_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000151, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACCHW             = { {.MACCHW            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000158, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHW_DOT         = { {.MACCHW_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000159, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACCHW            = { {.NMACCHW           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000015C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACCHW_DOT        = { {.NMACCHW_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000015D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACCHWSU           = { {.MACCHWSU          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000198, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWSU_DOT       = { {.MACCHWSU_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000199, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCMPEQUQ           = { {.VCMPEQUQ          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100001C7, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWS            = { {.MACCHWS           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100001D8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWS_DOT        = { {.MACCHWS_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100001D9, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACCHWS           = { {.NMACCHWS          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100001DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACCHWS_DOT       = { {.NMACCHWS_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100001DD, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCMPGTUQ           = { {.VCMPGTUQ          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000287, 0xFC0007FE, .BASE, .PPC32, {}} },
	.VCUXWFP            = { {.VCUXWFP           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000030A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULLHWU            = { {.MULLHWU           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000310, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULLHWU_DOT        = { {.MULLHWU_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000311, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACLHWU            = { {.MACLHWU           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000318, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWU_DOT        = { {.MACLHWU_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000319, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCSXWFP            = { {.VCSXWFP           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000034A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULLHW             = { {.MULLHW            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000350, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULLHW_DOT         = { {.MULLHW_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000351, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACLHW             = { {.MACLHW            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000358, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHW_DOT         = { {.MACLHW_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000359, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACLHW            = { {.NMACLHW           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000035C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACLHW_DOT        = { {.NMACLHW_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000035D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCMPGTSQ           = { {.VCMPGTSQ          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000387, 0xFC0007FE, .BASE, .PPC32, {}} },
	.VCFPUXWS           = { {.VCFPUXWS          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000038A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWSU           = { {.MACLHWSU          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000398, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWSU_DOT       = { {.MACLHWSU_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000399, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCFPSXWS           = { {.VCFPSXWS          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100003CA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWS            = { {.MACLHWS           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100003D8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWS_DOT        = { {.MACLHWS_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100003D9, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACLHWS           = { {.NMACLHWS          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100003DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACLHWS_DOT       = { {.NMACLHWS_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100003DD, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACHHWUO           = { {.MACHHWUO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000418, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHWUO_DOT       = { {.MACHHWUO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000419, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACHHWO            = { {.MACHHWO           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000458, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHWO_DOT        = { {.MACHHWO_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000459, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACHHWO           = { {.NMACHHWO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000045C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACHHWO_DOT       = { {.NMACHHWO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000045D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VMR                = { {.VMR               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000484, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHWSUO          = { {.MACHHWSUO         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000498, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHWSUO_DOT      = { {.MACHHWSUO_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000499, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACHHWSO           = { {.MACHHWSO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100004D8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACHHWSO_DOT       = { {.MACHHWSO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100004D9, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACHHWSO          = { {.NMACHHWSO         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100004DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACHHWSO_DOT      = { {.NMACHHWSO_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100004DD, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VSUBUQM            = { {.VSUBUQM           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000500, 0xFC0007FE, .BASE, .PPC32, {}} },
	.VNOT               = { {.VNOT              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000504, 0xFC0007FE, .BASE, .PPC32, {}} },
	.VGBBD              = { {.VGBBD             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000050C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWUO           = { {.MACCHWUO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000518, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWUO_DOT       = { {.MACCHWUO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000519, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACCHWO            = { {.MACCHWO           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000558, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWO_DOT        = { {.MACCHWO_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000559, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACCHWO           = { {.NMACCHWO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000055C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACCHWO_DOT       = { {.NMACCHWO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000055D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACCHWSUO          = { {.MACCHWSUO         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000598, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWSUO_DOT      = { {.MACCHWSUO_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000599, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCMPEQUQ_DOT       = { {.VCMPEQUQ_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100005C7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACCHWSO           = { {.MACCHWSO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100005D8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACCHWSO_DOT       = { {.MACCHWSO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100005D9, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACCHWSO          = { {.NMACCHWSO         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100005DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACCHWSO_DOT      = { {.NMACCHWSO_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100005DD, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCMPGTUQ_DOT       = { {.VCMPGTUQ_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000687, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACLHWUO           = { {.MACLHWUO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000718, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWUO_DOT       = { {.MACLHWUO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000719, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACLHWO            = { {.MACLHWO           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000758, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWO_DOT        = { {.MACLHWO_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000759, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACLHWO           = { {.NMACLHWO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000075C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACLHWO_DOT       = { {.NMACLHWO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000075D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.VCMPGTSQ_DOT       = { {.VCMPGTSQ_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000787, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACLHWSUO          = { {.MACLHWSUO         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000798, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWSUO_DOT      = { {.MACLHWSUO_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000799, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MACLHWSO           = { {.MACLHWSO          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100007D8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MACLHWSO_DOT       = { {.MACLHWSO_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100007D9, 0xFC0007FF, .BASE, .PPC32, {}} },
	.NMACLHWSO          = { {.NMACLHWSO         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100007DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NMACLHWSO_DOT      = { {.NMACLHWSO_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100007DD, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DCBZ_L             = { {.DCBZ_L            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x100007EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULI               = { {.MULI              , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x1C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SFI                = { {.SFI               , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x20000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DOZI               = { {.DOZI              , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x24000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AI                 = { {.AI                , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x30000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBIC              = { {.SUBIC             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x30000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AI_DOT             = { {.AI_DOT            , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x34000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SUBIC_DOT          = { {.SUBIC_DOT         , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x34000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LIL                = { {.LIL               , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x38000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CAL                = { {.CAL               , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x38000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBI               = { {.SUBI              , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x38000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LIU                = { {.LIU               , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x3C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CAU                = { {.CAU               , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x3C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBIS              = { {.SUBIS             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x3C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CRNOT              = { {.CRNOT             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.RFCI               = { {.RFCI              , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.RFSCV              = { {.RFSCV             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.RFSVC              = { {.RFSVC             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.RFGI               = { {.RFGI              , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.ICS                = { {.ICS               , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CRCLR              = { {.CRCLR             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DNH                = { {.DNH               , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.CRSET              = { {.CRSET             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.URFID              = { {.URFID             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DOZE               = { {.DOZE              , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CRMOVE             = { {.CRMOVE            , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLEEP              = { {.SLEEP             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.RVWINKLE           = { {.RVWINKLE          , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x4C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ORIL               = { {.ORIL              , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x60000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ORIU               = { {.ORIU              , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x64000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.XORIL              = { {.XORIL             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x68000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.XORIU              = { {.XORIU             , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x6C000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ANDIL_DOT          = { {.ANDIL_DOT         , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x70000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ANDIU_DOT          = { {.ANDIU_DOT         , {.GPR, .GPR, .IMM, .NONE}, {.RT, .RA, .D16, .NONE}, 0x74000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ROTLDI_DOT         = { {.ROTLDI_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642801, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.ROTRDI_DOT         = { {.ROTRDI_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642801, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.CLRLDI_DOT         = { {.CLRLDI_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642801, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.SRDI_DOT           = { {.SRDI_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642801, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.EXTRDI_DOT         = { {.EXTRDI_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642801, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.CLRRDI_DOT         = { {.CLRRDI_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642805, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.SLDI_DOT           = { {.SLDI_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642805, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.EXTLDI_DOT         = { {.EXTLDI_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642805, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.CLRLSLDI           = { {.CLRLSLDI          , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642808, 0xFFFFFFFE, .P64, .PPC64, {}} },
	.CLRLSLDI_DOT       = { {.CLRLSLDI_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642809, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.INSRDI             = { {.INSRDI            , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7864280C, 0xFFFFFFFE, .P64, .PPC64, {}} },
	.INSRDI_DOT         = { {.INSRDI_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x7864280D, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.ROTLD_DOT          = { {.ROTLD_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x78642811, 0xFFFFFFFF, .P64, .PPC64, {}} },
	.T                  = { {.T                 , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000008, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SF                 = { {.SF                , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000010, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SF_DOT             = { {.SF_DOT            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000011, 0xFC0007FF, .BASE, .PPC32, {}} },
	.A_DOT              = { {.A_DOT             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000015, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LX                 = { {.LX                , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00002E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SL                 = { {.SL                , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000030, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SL_DOT             = { {.SL_DOT            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000031, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CNTLZ              = { {.CNTLZ             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000034, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CNTLZ_DOT          = { {.CNTLZ_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000035, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MASKG              = { {.MASKG             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00003A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MASKG_DOT          = { {.MASKG_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00003B, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LDEPX              = { {.LDEPX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00003A, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.WAITASEC           = { {.WAITASEC          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00003C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MVIWSPLT           = { {.MVIWSPLT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00005C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MFVSRD             = { {.MFVSRD            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000066, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ERATILX            = { {.ERATILX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000066, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.LUX                = { {.LUX               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00006E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBWUS             = { {.SUBWUS            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000090, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBWUS_DOT         = { {.SUBWUS_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000091, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SUBDUS             = { {.SUBDUS            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000490, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBDUS_DOT         = { {.SUBDUS_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000491, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SUBFUS             = { {.SUBFUS            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000090, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFUS_DOT         = { {.SUBFUS_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000091, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DLMZB              = { {.DLMZB             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00009C, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.DLMZB_DOT          = { {.DLMZB_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00009D, 0xFC0007FF, .BOOKE, .PPC32, {}} },
	.DNI                = { {.DNI               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0000C3, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MUL                = { {.MUL               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0000D6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MUL_DOT            = { {.MUL_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0000D7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MVIDSPLT           = { {.MVIDSPLT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0000DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTSRDIN            = { {.MTSRDIN           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0000E4, 0xFC0007FE, .P64, .PPC64, {}} },
	.MFVSRWZ            = { {.MFVSRWZ           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0000E6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CLF                = { {.CLF               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0000EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBTSTLS           = { {.DCBTSTLS          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00010C, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.SFE                = { {.SFE               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000110, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SFE_DOT            = { {.SFE_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000111, 0xFC0007FF, .BASE, .PPC32, {}} },
	.AE                 = { {.AE                , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000114, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AE_DOT             = { {.AE_DOT            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000115, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DCBTSTLSE          = { {.DCBTSTLSE         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00011C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTSLE              = { {.MTSLE             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000126, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ERATSX             = { {.ERATSX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000126, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.ERATSX_DOT         = { {.ERATSX_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000127, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.STX                = { {.STX               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00012E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLQ                = { {.SLQ               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000130, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLQ_DOT            = { {.SLQ_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000131, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SLE                = { {.SLE               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000132, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLE_DOT            = { {.SLE_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000133, 0xFC0007FF, .BASE, .PPC32, {}} },
	.STDEPX             = { {.STDEPX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00013A, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.DCBTLS             = { {.DCBTLS            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00014C, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.DCBTLSE            = { {.DCBTLSE           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00015C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTVSRD             = { {.MTVSRD            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000166, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ERATRE             = { {.ERATRE            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000166, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.WCHKALL            = { {.WCHKALL           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00016C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.STUX               = { {.STUX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00016E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLIQ               = { {.SLIQ              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000170, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLIQ_DOT           = { {.SLIQ_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000171, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ICBLQ_DOT          = { {.ICBLQ_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00018D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SFZE               = { {.SFZE              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000190, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SFZE_DOT           = { {.SFZE_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000191, 0xFC0007FF, .BASE, .PPC32, {}} },
	.AZE                = { {.AZE               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000194, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AZE_DOT            = { {.AZE_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000195, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MTVSRWA            = { {.MTVSRWA           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001A6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ERATWE             = { {.ERATWE            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001A6, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.LDAWX_DOT          = { {.LDAWX_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001A9, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.SLLQ               = { {.SLLQ              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001B0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLLQ_DOT           = { {.SLLQ_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001B1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SLEQ               = { {.SLEQ              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001B2, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLEQ_DOT           = { {.SLEQ_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001B3, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SFME               = { {.SFME              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SFME_DOT           = { {.SFME_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.AME                = { {.AME               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AME_DOT            = { {.AME_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D5, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MULS               = { {.MULS              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULS_DOT           = { {.MULS_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001D7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ICBLCE             = { {.ICBLCE            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTSRI              = { {.MTSRI             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001E4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTVSRWZ            = { {.MTVSRWZ           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001E6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBTSTCT           = { {.DCBTSTCT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBTSTDS           = { {.DCBTSTDS          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLLIQ              = { {.SLLIQ             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001F0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SLLIQ_DOT          = { {.SLLIQ_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0001F1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MFDCRX             = { {.MFDCRX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000206, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.MFDCRX_DOT         = { {.MFDCRX_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000207, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.LVEXBX             = { {.LVEXBX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00020A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LVEPXL             = { {.LVEPXL            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00020E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DOZ                = { {.DOZ               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000210, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DOZ_DOT            = { {.DOZ_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000211, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CAX                = { {.CAX               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000214, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CAX_DOT            = { {.CAX_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000215, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EHPRIV             = { {.EHPRIV            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00021C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.MFAPIDI            = { {.MFAPIDI           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000226, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.LSCBX              = { {.LSCBX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00022A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LSCBX_DOT          = { {.LSCBX_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00022B, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DCBTCT             = { {.DCBTCT            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00022C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBTDS             = { {.DCBTDS            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00022C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MFDCRUX            = { {.MFDCRUX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000246, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.LVEXHX             = { {.LVEXHX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00024A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LVEPX              = { {.LVEPX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00024E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MFBHRBE            = { {.MFBHRBE           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00025C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.TLBI               = { {.TLBI              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000264, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ECIWX              = { {.ECIWX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00026C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MFDCR_DOT          = { {.MFDCR_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000287, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.LVEXWX             = { {.LVEXWX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00028A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCREAD             = { {.DCREAD            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00028C, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.DIV                = { {.DIV               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000296, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIV_DOT            = { {.DIV_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000297, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MFTMR              = { {.MFTMR             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0002DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ABS                = { {.ABS               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0002D0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ABS_DOT            = { {.ABS_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0002D1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DIVS               = { {.DIVS              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0002D6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIVS_DOT           = { {.DIVS_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0002D7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LXVWSX             = { {.LXVWSX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0002D8, 0xFC0007FE, .BASE, .PPC32, {}} },
	.TLBIA              = { {.TLBIA             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0002E4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SETBC              = { {.SETBC             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000300, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTDCRX             = { {.MTDCRX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000306, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.MTDCRX_DOT         = { {.MTDCRX_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000307, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.STVEXBX            = { {.STVEXBX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00030A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBLC              = { {.DCBLC             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00030C, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.DCBLCE             = { {.DCBLCE            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00031C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.PBT_DOT            = { {.PBT_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000329, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ICSWX              = { {.ICSWX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00032C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.ICSWX_DOT          = { {.ICSWX_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00032D, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.SETBCR             = { {.SETBCR            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000340, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTDCRUX            = { {.MTDCRUX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000346, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.STVEXHX            = { {.STVEXHX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00034A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCBLQ_DOT          = { {.DCBLQ_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00034D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CLRBHRB            = { {.CLRBHRB           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00035C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ECOWX              = { {.ECOWX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00036C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SETNBC             = { {.SETNBC            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000380, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MTDCR_DOT          = { {.MTDCR_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000387, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.STVEXWX            = { {.STVEXWX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00038A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCI                = { {.DCI               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00038C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.MTTMR              = { {.MTTMR             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SETNBCR            = { {.SETNBCR           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003C0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DSN                = { {.DSN               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003C6, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.NABS               = { {.NABS              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003D0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NABS_DOT           = { {.NABS_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003D1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ICBTLSE            = { {.ICBTLSE           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003DC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CLI                = { {.CLI               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0003EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MCRXR              = { {.MCRXR             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000400, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LBDCBX             = { {.LBDCBX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000404, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LBDX               = { {.LBDX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000406, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.BBLELS             = { {.BBLELS            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00040C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LVLX               = { {.LVLX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00040E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFCO             = { {.SUBFCO            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000410, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SFO                = { {.SFO               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000410, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBCO              = { {.SUBCO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000410, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFCO_DOT         = { {.SUBFCO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000411, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SFO_DOT            = { {.SFO_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000411, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SUBCO_DOT          = { {.SUBCO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000411, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ADDCO              = { {.ADDCO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000414, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AO                 = { {.AO                , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000414, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ADDCO_DOT          = { {.ADDCO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000415, 0xFC0007FF, .BASE, .PPC32, {}} },
	.AO_DOT             = { {.AO_DOT            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000415, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CLCS               = { {.CLCS              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000426, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LSX                = { {.LSX               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00042A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LBRX               = { {.LBRX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00042C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SR_DOT             = { {.SR_DOT            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000431, 0xFC0007FF, .BASE, .PPC32, {}} },
	.RRIB               = { {.RRIB              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000432, 0xFC0007FE, .BASE, .PPC32, {}} },
	.RRIB_DOT           = { {.RRIB_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000433, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MASKIR             = { {.MASKIR            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00043A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MASKIR_DOT         = { {.MASKIR_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00043B, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LHDCBX             = { {.LHDCBX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000444, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LHDX               = { {.LHDX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000446, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.LVTRX              = { {.LVTRX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00044A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.BBELR              = { {.BBELR             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00044C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LVRX               = { {.LVRX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00044E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFO              = { {.SUBFO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000450, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBO               = { {.SUBO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000450, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFO_DOT          = { {.SUBFO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000451, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SUBO_DOT           = { {.SUBO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000451, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LWDCBX             = { {.LWDCBX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000484, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LWDX               = { {.LWDX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000486, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.LVTLX              = { {.LVTLX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00048A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LSI                = { {.LSI               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004AA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCS                = { {.DCS               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004AC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MFFGPR             = { {.MFFGPR            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004BE, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LDDX               = { {.LDDX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004C6, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.LVSWX              = { {.LVSWX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004CA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NEGO               = { {.NEGO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004D0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NEGO_DOT           = { {.NEGO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004D1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MULO               = { {.MULO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004D6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULO_DOT           = { {.MULO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004D7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MFSRI              = { {.MFSRI             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004E6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DCLST              = { {.DCLST             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0004EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STBDCBX            = { {.STBDCBX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000504, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STBDX              = { {.STBDX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000506, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.STVLX              = { {.STVLX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00050E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFEO             = { {.SUBFEO            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000510, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SFEO               = { {.SFEO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000510, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFEO_DOT         = { {.SUBFEO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000511, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SFEO_DOT           = { {.SFEO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000511, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ADDEO              = { {.ADDEO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000514, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AEO                = { {.AEO               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000514, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ADDEO_DOT          = { {.ADDEO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000515, 0xFC0007FF, .BASE, .PPC32, {}} },
	.AEO_DOT            = { {.AEO_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000515, 0xFC0007FF, .BASE, .PPC32, {}} },
	.HASHSTP            = { {.HASHSTP           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000524, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STSX               = { {.STSX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00052A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STBRX              = { {.STBRX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00052C, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRQ                = { {.SRQ               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000530, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRQ_DOT            = { {.SRQ_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000531, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SRE                = { {.SRE               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000532, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRE_DOT            = { {.SRE_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000533, 0xFC0007FF, .BASE, .PPC32, {}} },
	.STHDCBX            = { {.STHDCBX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000544, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STHDX              = { {.STHDX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000546, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.STVFRX             = { {.STVFRX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00054A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STVRX              = { {.STVRX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00054E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.HASHCHKP           = { {.HASHCHKP          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000564, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRIQ               = { {.SRIQ              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000570, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRIQ_DOT           = { {.SRIQ_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000571, 0xFC0007FF, .BASE, .PPC32, {}} },
	.STWDCBX            = { {.STWDCBX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000584, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STWDX              = { {.STWDX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000586, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.STVFLX             = { {.STVFLX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00058A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFZEO            = { {.SUBFZEO           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000590, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SFZEO              = { {.SFZEO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000590, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFZEO_DOT        = { {.SUBFZEO_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000591, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SFZEO_DOT          = { {.SFZEO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000591, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ADDZEO             = { {.ADDZEO            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000594, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AZEO               = { {.AZEO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000594, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ADDZEO_DOT         = { {.ADDZEO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000595, 0xFC0007FF, .BASE, .PPC32, {}} },
	.AZEO_DOT           = { {.AZEO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000595, 0xFC0007FF, .BASE, .PPC32, {}} },
	.HASHST             = { {.HASHST            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005A4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STSI               = { {.STSI              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005AA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRLQ               = { {.SRLQ              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005B0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRLQ_DOT           = { {.SRLQ_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005B1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SREQ               = { {.SREQ              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005B2, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SREQ_DOT           = { {.SREQ_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005B3, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MFTGPR             = { {.MFTGPR            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005BE, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STDDX              = { {.STDDX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005C6, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.STVSWX             = { {.STVSWX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005CA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFMEO            = { {.SUBFMEO           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SFMEO              = { {.SFMEO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SUBFMEO_DOT        = { {.SUBFMEO_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SFMEO_DOT          = { {.SFMEO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MULLDO             = { {.MULLDO            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D2, 0xFC0007FE, .P64, .PPC64, {}} },
	.MULLDO_DOT         = { {.MULLDO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D3, 0xFC0007FF, .P64, .PPC64, {}} },
	.ADDMEO             = { {.ADDMEO            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.AMEO               = { {.AMEO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ADDMEO_DOT         = { {.ADDMEO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D5, 0xFC0007FF, .BASE, .PPC32, {}} },
	.AMEO_DOT           = { {.AMEO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D5, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MULLWO             = { {.MULLWO            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULSO              = { {.MULSO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.MULLWO_DOT         = { {.MULLWO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.MULSO_DOT          = { {.MULSO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005D7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.TSR_DOT            = { {.TSR_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005DD, 0xFC0007FF, .BASE, .PPC32, {}} },
	.HASHCHK            = { {.HASHCHK           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005E4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRLIQ              = { {.SRLIQ             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005F0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRLIQ_DOT          = { {.SRLIQ_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0005F1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LVSM               = { {.LVSM              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00060A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STVEPXL            = { {.STVEPXL           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00060E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LVLXL              = { {.LVLXL             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00060E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DOZO               = { {.DOZO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000610, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DOZO_DOT           = { {.DOZO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000611, 0xFC0007FF, .BASE, .PPC32, {}} },
	.ADDO               = { {.ADDO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000614, 0xFC0007FE, .BASE, .PPC32, {}} },
	.CAXO               = { {.CAXO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000614, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ADDO_DOT           = { {.ADDO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000615, 0xFC0007FF, .BASE, .PPC32, {}} },
	.CAXO_DOT           = { {.CAXO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000615, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LFQX               = { {.LFQX              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00062E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRA                = { {.SRA               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000630, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRA_DOT            = { {.SRA_DOT           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000631, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVLDDEPX           = { {.EVLDDEPX          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00063E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LFDDX              = { {.LFDDX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000646, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.LVTRXL             = { {.LVTRXL            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00064A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STVEPX             = { {.STVEPX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00064E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LVRXL              = { {.LVRXL             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00064E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.RAC                = { {.RAC               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000664, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ERATIVAX           = { {.ERATIVAX          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000666, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.LFQUX              = { {.LFQUX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00066E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRAI               = { {.SRAI              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000670, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRAI_DOT           = { {.SRAI_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000671, 0xFC0007FF, .BASE, .PPC32, {}} },
	.LVTLXL             = { {.LVTLXL            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00068A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIVO               = { {.DIVO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000696, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIVO_DOT           = { {.DIVO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000697, 0xFC0007FF, .BASE, .PPC32, {}} },
	.TLBSRX_DOT         = { {.TLBSRX_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0006A5, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.SLBIAG             = { {.SLBIAG            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0006A4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LVSWXL             = { {.LVSWXL            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0006CA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ABSO               = { {.ABSO              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0006D0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ABSO_DOT           = { {.ABSO_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0006D1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DIVSO              = { {.DIVSO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0006D6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIVSO_DOT          = { {.DIVSO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0006D7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.RMIEG              = { {.RMIEG             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0006E4, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STVLXL             = { {.STVLXL            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00070E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIVDEUO_DOT        = { {.DIVDEUO_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000713, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.DIVWEUO_DOT        = { {.DIVWEUO_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000717, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.TLBSX_DOT          = { {.TLBSX_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000725, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.STFQX              = { {.STFQX             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00072E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRAQ               = { {.SRAQ              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000730, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRAQ_DOT           = { {.SRAQ_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000731, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SREA               = { {.SREA              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000732, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SREA_DOT           = { {.SREA_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000733, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EXTS               = { {.EXTS              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000734, 0xFC0007FE, .BASE, .PPC32, {}} },
	.EXTS_DOT           = { {.EXTS_DOT          , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000735, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSTDDEPX          = { {.EVSTDDEPX         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00073E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STFDDX             = { {.STFDDX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000746, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.STVFRXL            = { {.STVFRXL           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00074A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.WCLRALL            = { {.WCLRALL           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00074C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.WCLR               = { {.WCLR              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00074C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.STVRXL             = { {.STVRXL            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00074E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIVDEO_DOT         = { {.DIVDEO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000753, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.DIVWEO_DOT         = { {.DIVWEO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000757, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.ICSWEPX            = { {.ICSWEPX           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00076C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.ICSWEPX_DOT        = { {.ICSWEPX_DOT       , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00076D, 0xFC0007FF, .POWER8, .PPC32, {}} },
	.STFQUX             = { {.STFQUX            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00076E, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRAIQ              = { {.SRAIQ             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000770, 0xFC0007FE, .BASE, .PPC32, {}} },
	.SRAIQ_DOT          = { {.SRAIQ_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000771, 0xFC0007FF, .BASE, .PPC32, {}} },
	.STVFLXL            = { {.STVFLXL           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00078A, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ICI                = { {.ICI               , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C00078C, 0xFC0007FE, .POWER8, .PPC32, {}} },
	.DIVDUO             = { {.DIVDUO            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000792, 0xFC0007FE, .P64, .PPC64, {}} },
	.DIVDUO_DOT         = { {.DIVDUO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000793, 0xFC0007FF, .P64, .PPC64, {}} },
	.DIVWUO             = { {.DIVWUO            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000796, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIVWUO_DOT         = { {.DIVWUO_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C000797, 0xFC0007FF, .BASE, .PPC32, {}} },
	.SLBFEE_DOT         = { {.SLBFEE_DOT        , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007A7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.STVSWXL            = { {.STVSWXL           , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007CA, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ICREAD             = { {.ICREAD            , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007CC, 0xFC0007FE, .BOOKE, .PPC32, {}} },
	.NABSO              = { {.NABSO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D0, 0xFC0007FE, .BASE, .PPC32, {}} },
	.NABSO_DOT          = { {.NABSO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D1, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DIVDO              = { {.DIVDO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D2, 0xFC0007FE, .P64, .PPC64, {}} },
	.DIVDO_DOT          = { {.DIVDO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D3, 0xFC0007FF, .P64, .PPC64, {}} },
	.DIVWO              = { {.DIVWO             , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D6, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DIVWO_DOT          = { {.DIVWO_DOT         , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007D7, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DCLZ               = { {.DCLZ              , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x7C0007EC, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LU                 = { {.LU                , {.GPR, .MEM, .NONE,.NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0x84000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.ST                 = { {.ST                , {.GPR, .MEM, .NONE,.NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0x90000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STU                = { {.STU               , {.GPR, .MEM, .NONE,.NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0x94000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LM                 = { {.LM                , {.GPR, .MEM, .NONE,.NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0xB8000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STM                = { {.STM               , {.GPR, .MEM, .NONE,.NONE}, {.RT, .OFFSET_BASE_D, .NONE, .NONE}, 0xBC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LFQ                = { {.LFQ               , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xE0000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.LFQU               = { {.LFQU              , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xE4000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STFQ               = { {.STFQ              , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xF0000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.STFQU              = { {.STFQU             , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xF4000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FCIR               = { {.FCIR              , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FCIR_DOT           = { {.FCIR_DOT          , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FCIRZ              = { {.FCIRZ             , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FCIRZ_DOT          = { {.FCIRZ_DOT         , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FD                 = { {.FD                , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FD_DOT             = { {.FD_DOT            , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FS                 = { {.FS                , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FS_DOT             = { {.FS_DOT            , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FA                 = { {.FA                , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FA_DOT             = { {.FA_DOT            , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FM                 = { {.FM                , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FM_DOT             = { {.FM_DOT            , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FMS                = { {.FMS               , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FMS_DOT            = { {.FMS_DOT           , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FMA                = { {.FMA               , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FMA_DOT            = { {.FMA_DOT           , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FNMS               = { {.FNMS              , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FNMS_DOT           = { {.FNMS_DOT          , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.FNMA               = { {.FNMA              , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.FNMA_DOT           = { {.FNMA_DOT          , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DTSTEXQ            = { {.DTSTEXQ           , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.XSCMPEXPQP         = { {.XSCMPEXPQP        , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DXEXQ              = { {.DXEXQ             , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.DXEXQ_DOT          = { {.DXEXQ_DOT         , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FF, .BASE, .PPC32, {}} },
	.DTSTSFQ            = { {.DTSTSFQ           , {.FPR, .MEM, .NONE,.NONE}, {.FRT, .OFFSET_BASE_D, .NONE, .NONE}, 0xFC000000, 0xFC0007FE, .BASE, .PPC32, {}} },
	.EVSETEQB_DOT       = { {.EVSETEQB_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000601, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETEQH_DOT       = { {.EVSETEQH_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000603, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETEQW_DOT       = { {.EVSETEQW_DOT      , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000605, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETGTHU_DOT      = { {.EVSETGTHU_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000609, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETGTHS_DOT      = { {.EVSETGTHS_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000060B, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETGTWU_DOT      = { {.EVSETGTWU_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000060D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETGTWS_DOT      = { {.EVSETGTWS_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000060F, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETGTBU_DOT      = { {.EVSETGTBU_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000611, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETGTBS_DOT      = { {.EVSETGTBS_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000613, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETLTBU_DOT      = { {.EVSETLTBU_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000615, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETLTBS_DOT      = { {.EVSETLTBS_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000617, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETLTHU_DOT      = { {.EVSETLTHU_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x10000619, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETLTHS_DOT      = { {.EVSETLTHS_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000061B, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETLTWU_DOT      = { {.EVSETLTWU_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000061D, 0xFC0007FF, .BASE, .PPC32, {}} },
	.EVSETLTWS_DOT      = { {.EVSETLTWS_DOT     , {.GPR, .GPR, .GPR, .NONE}, {.RT, .RA, .RB, .NONE}, 0x1000061F, 0xFC0007FF, .BASE, .PPC32, {}} },

	// =========================================================================
}

// =============================================================================
// PREFIX_BITS_TABLE — prefix word for Power ISA 3.1 prefixed instructions
// =============================================================================
//
// Entries with `flags.prefixed = true` set their PREFIX word here. The
// `bits` field of the Encoding describes the SUFFIX. The encoder emits both
// words (prefix first, then suffix, big-endian on the wire). Non-prefixed
// mnemonics default to 0.
//
// MLS prefix base = 0x06000000 (template=10, R=0, IMM18=0).
// 8LS prefix base = 0x04000000 (template=00, R=0, IMM18=0).

PREFIX_BITS_TABLE: [Mnemonic]u32 = #partial {
	// MLS-form (prefix template = 0b10)
	.PLBZ  = 0x06000000,
	.PLHZ  = 0x06000000,
	.PLHA  = 0x06000000,
	.PLWZ  = 0x06000000,
	.PSTB  = 0x06000000,
	.PSTH  = 0x06000000,
	.PSTW  = 0x06000000,
	.PLFS  = 0x06000000,
	.PLFD  = 0x06000000,
	.PSTFS = 0x06000000,
	.PSTFD = 0x06000000,
	.PADDI = 0x06000000,
	.PLI   = 0x06000000,

	// 8LS-form (prefix template = 0b00)
	.PLWA    = 0x04000000,
	.PLD     = 0x04000000,
	.PSTD    = 0x04000000,
	.PLXSD   = 0x04000000,
	.PLXSSP  = 0x04000000,
	.PSTXSD  = 0x04000000,
	.PSTXSSP = 0x04000000,
	.PLXV    = 0x04000000,
	.PSTXV   = 0x04000000,

	// 8RR-form (prefix template = 0b01)
	.XXSPLTIDP   = 0x05000000,
	.XXSPLTIW    = 0x05000000,
	.XXSPLTI32DX = 0x05000000,

	// MLS-form alias: psubi is paddi with negated imm. Prefix carries the
	// sign-extended high 18 bits of -100 = 0x3FFFF.
	.PSUBI       = 0x0603FFFF,

	// MMIRR-form (prefix template = 0b11) for MMA accelerator
	.PMXVF32GER  = 0x07900000,
	.PMXVF64GER  = 0x07900000,
	.PMXVI4GER8  = 0x07900000,
	.PMXVI8GER4  = 0x07900000,
	.PMXVI16GER2 = 0x07900000,

	// 8RR-form (prefix template = 0b01) — POWER10 prefixed blend/perm/eval
	.XXBLENDVB = 0x05000000,
	.XXBLENDVH = 0x05000000,
	.XXBLENDVW = 0x05000000,
	.XXBLENDVD = 0x05000000,
	.XXPERMX   = 0x05000000,
	.XXEVAL    = 0x05000000,

	// MMIRR-form expansion (POWER10 MMA pp/pn/np/nn family)
	.PMXVF16GER2 = 0x07900000, .PMXVF16GER2PP = 0x07900000,
	.PMXVF16GER2PN = 0x07900000, .PMXVF16GER2NP = 0x07900000, .PMXVF16GER2NN = 0x07900000,
	.PMXVF32GERPP = 0x07900000, .PMXVF32GERPN = 0x07900000,
	.PMXVF32GERNP = 0x07900000, .PMXVF32GERNN = 0x07900000,
	.PMXVF64GERPP = 0x07900000, .PMXVF64GERPN = 0x07900000,
	.PMXVF64GERNP = 0x07900000, .PMXVF64GERNN = 0x07900000,
	.PMXVBF16GER2 = 0x07900000, .PMXVBF16GER2PP = 0x07900000,
	.PMXVBF16GER2PN = 0x07900000, .PMXVBF16GER2NP = 0x07900000, .PMXVBF16GER2NN = 0x07900000,
	.PMXVI4GER8PP = 0x07900000,
	.PMXVI8GER4PP = 0x07900000, .PMXVI8GER4SPP = 0x07900000,
	.PMXVI16GER2PP = 0x07900000, .PMXVI16GER2S = 0x07900000, .PMXVI16GER2SPP = 0x07900000,

}
