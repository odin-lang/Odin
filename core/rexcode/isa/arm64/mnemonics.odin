// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

// =============================================================================
// AArch64 MNEMONICS
// =============================================================================
//
// One member per ASSEMBLER mnemonic -- the name an A64 assembler actually
// accepts, and nothing finer. An instruction's variants are not separate
// mnemonics: ADD covers the immediate, shifted-register, extended-register
// and NEON forms, LDR covers every addressing mode, and the encoder picks
// between them by matching the operands against that mnemonic's run of
// forms in INSTRUCTION_TABLE (see tablegen/instruction_table.odin).
//
// Names holding an underscore are the ones an assembler writes with a
// separator: the two-token system instructions -- `dc zva`, `tlbi vae1`,
// `at s1e1r`, `bti j`, `psb csync` -- and the conditional branches, where
// the underscore is a dot: B_LE prints `b.le`, BC_NE prints `bc.ne`. The
// AMX_* pseudo-ops keep theirs literally; Apple's undocumented coprocessor
// has no assembler spelling at all.
//
// Architectural aliases that share an encoding (MOV/MVN of ORR/ORN, NEG of
// SUB, CMP of SUBS, TST of ANDS, ...) are listed as the mnemonics they are:
// each is a name assemblers accept, so each gets its own member and forms.

Mnemonic :: enum u16 {
	INVALID = 0,

	// -------------------------------------------------------------------------
	// Data processing -- immediate
	// -------------------------------------------------------------------------

	ADD, ADDS, SUB, SUBS,                      // optional LSL #12 carried in shift field
	MOVZ, MOVN, MOVK,                          // 16-bit imm + 2-bit hw
	ADR, ADRP,                                 // PC-relative address

	// -------------------------------------------------------------------------
	// Data processing -- register (shifted register)
	// -------------------------------------------------------------------------

	AND, ANDS, ORR, EOR,
	BIC, BICS, ORN, EON,

	// -------------------------------------------------------------------------
	// Data processing -- register (variable shifts / 2-source)
	// -------------------------------------------------------------------------

	LSL, LSR, ASR, ROR,                        // register and immediate forms both
	UDIV, SDIV,

	// -------------------------------------------------------------------------
	// Data processing -- register (3-source)
	// -------------------------------------------------------------------------

	MADD, MSUB,                                // 64x64+64 -> 64 (or 32 variant)
	SMADDL, SMSUBL, UMADDL, UMSUBL,            // 32x32+64 -> 64
	SMULH, UMULH,                              // 64x64 -> high 64

	// -------------------------------------------------------------------------
	// Data processing -- register (1-source bit-twiddling)
	// -------------------------------------------------------------------------

	CLZ, CLS, RBIT, REV, REV16, REV32,

	// -------------------------------------------------------------------------
	// Conditional select / compare
	// -------------------------------------------------------------------------

	CSEL, CSINC, CSINV, CSNEG,
	CCMP, CCMN,
	// Aliases of the above with the condition inverted; every assembler both
	// accepts and prefers these spellings.
	CSET, CSETM,                               // CSINC/CSINV with Rn = Rm = ZR
	CINC, CINV, CNEG,                          // CSINC/CSINV/CSNEG with Rn = Rm

	// -------------------------------------------------------------------------
	// Extract
	// -------------------------------------------------------------------------

	EXTR,

	// -------------------------------------------------------------------------
	// Branches
	// -------------------------------------------------------------------------

	B, BL,                                     // 26-bit PC-rel
	BR, BLR, RET,                              // register indirect
	// One member per condition, the way an assembler spells them and the way
	// x86 does its Jcc. The condition is not an operand: it is four bits of
	// the opcode, and splitting it lets each entry record the flags it
	// actually reads -- b.eq consults Z alone, b.le consults N, Z and V --
	// where a single B_COND had to claim all four for every condition.
	B_EQ, B_NE, B_CS, B_CC,                    // B.cond -- 19-bit PC-rel
	B_MI, B_PL, B_VS, B_VC,
	B_HI, B_LS, B_GE, B_LT,
	B_GT, B_LE, B_AL, B_NV,
	CBZ, CBNZ,                                 // 19-bit PC-rel + Rt
	TBZ, TBNZ,                                 // 14-bit PC-rel + bit position

	// -------------------------------------------------------------------------
	// Loads / stores
	// -------------------------------------------------------------------------

	// Plain (unsigned offset / signed unscaled / pre / post)
	LDR, STR,                                  // X/W variants (matched by reg width)
	LDRB, STRB, LDRSB,
	LDRH, STRH, LDRSH,
	LDRSW,

	// Pair
	LDP, STP, LDPSW,

	// PC-relative literal

	// Acquire / release
	LDAR, STLR,
	LDARB, STLRB, LDARH, STLRH,

	// Exclusive (load-linked / store-conditional)
	LDXR, STXR, LDAXR, STLXR,

	// -------------------------------------------------------------------------
	// System
	// -------------------------------------------------------------------------

	NOP, YIELD, WFE, WFI, SEV, SEVL,
	HINT,
	MRS, MSR,
	ISB, DSB, DMB,
	SVC, HVC, SMC, BRK, HLT,
	ERET,

	// -------------------------------------------------------------------------
	// FP scalar (single / double)
	// -------------------------------------------------------------------------

	FMOV,                                      // reg-reg / imm / between int/FP
	FABS, FNEG, FSQRT,
	FADD, FSUB, FMUL, FDIV, FNMUL,
	FMADD, FMSUB, FNMADD, FNMSUB,
	FCMP, FCMPE,
	FCSEL,
	FMAX, FMIN, FMAXNM, FMINNM,
	FCVT,                                      // between single/double/half
	SCVTF, UCVTF,
	FCVTZS, FCVTZU,
	FCVTAS, FCVTAU,
	FCVTNS, FCVTNU,
	FCVTPS, FCVTPU,
	FCVTMS, FCVTMU,
	FRINTA, FRINTI, FRINTM, FRINTN, FRINTP, FRINTX, FRINTZ,

	// -------------------------------------------------------------------------
	// Logical immediate (bitmask-encoded; N:imms:immr)
	// -------------------------------------------------------------------------
	TST,                                       // ANDS with Rd=ZR

	// -------------------------------------------------------------------------
	// Additional load/store addressing modes
	// -------------------------------------------------------------------------
	LDUR, STUR, LDURB, STURB, LDURSB, LDURH, STURH, LDURSH, LDURSW,
	LDNP, STNP,                                // non-temporal pair
	LDXP, STXP, LDAXP, STLXP,                  // exclusive pair
	LDXRB, STXRB, LDAXRB, STLXRB,              // exclusive byte
	LDXRH, STXRH, LDAXRH, STLXRH,              // exclusive halfword
	LDAPR, LDAPRB, LDAPRH,                     // load-acquire RCpc

	// -------------------------------------------------------------------------
	// LSE atomics (8 ops x 4 acq/rel x 2 width = 64 forms, named by op only;
	// size and acq/rel encoded in the bits + flags)
	// -------------------------------------------------------------------------
	LDADD, LDADDA, LDADDL, LDADDAL,
	LDCLR, LDCLRA, LDCLRL, LDCLRAL,
	LDEOR, LDEORA, LDEORL, LDEORAL,
	LDSET, LDSETA, LDSETL, LDSETAL,
	LDSMAX, LDSMAXA, LDSMAXL, LDSMAXAL,
	LDSMIN, LDSMINA, LDSMINL, LDSMINAL,
	LDUMAX, LDUMAXA, LDUMAXL, LDUMAXAL,
	LDUMIN, LDUMINA, LDUMINL, LDUMINAL,
	SWP, SWPA, SWPL, SWPAL,
	CAS, CASA, CASL, CASAL,                    // 32/64
	CASB, CASAB, CASLB, CASALB,                // byte
	CASH, CASAH, CASLH, CASALH,                // half
	CASP, CASPA, CASPL, CASPAL,                // pair (W,W)/(X,X)

	// -------------------------------------------------------------------------
	// Pointer Authentication (PAC v8.3-A)
	// -------------------------------------------------------------------------
	PACIA, PACIB, PACDA, PACDB,
	PACIZA, PACIZB, PACDZA, PACDZB,            // implicit-zero variants
	AUTIA, AUTIB, AUTDA, AUTDB,
	AUTIZA, AUTIZB, AUTDZA, AUTDZB,
	PACIASP, PACIBSP, AUTIASP, AUTIBSP,        // hint-encoded SP variants
	PACIA1716, PACIB1716, AUTIA1716, AUTIB1716,
	PACGA,
	XPACI, XPACD, XPACLRI,
	RETAA, RETAB,
	BRAA, BRAB, BRAAZ, BRABZ,
	BLRAA, BLRAB, BLRAAZ, BLRABZ,
	ERETAA, ERETAB,

	// -------------------------------------------------------------------------
	// Branch Target Identification (BTI v8.5-A)
	// -------------------------------------------------------------------------
	BTI,                                       // single mnemonic; modifier (c/j/jc) in operand

	// -------------------------------------------------------------------------
	// Memory Tagging Extension (MTE v8.5-A)
	// -------------------------------------------------------------------------
	IRG, ADDG, SUBG, GMI, SUBP, SUBPS,
	LDG, STG, ST2G, STZG, STZ2G, STGP,
	LDGM, STGM, STZGM,

	// -------------------------------------------------------------------------
	// CRC32 (v8.0-A optional, mandatory v8.1+)
	// -------------------------------------------------------------------------
	CRC32B, CRC32H, CRC32W, CRC32X,
	CRC32CB, CRC32CH, CRC32CW, CRC32CX,

	// -------------------------------------------------------------------------
	// Crypto: AES / SHA / SM3 / SM4 / polynomial multiply
	// -------------------------------------------------------------------------
	AESE, AESD, AESMC, AESIMC,
	SHA1H, SHA1C, SHA1P, SHA1M, SHA1SU0, SHA1SU1,
	SHA256H, SHA256H2, SHA256SU0, SHA256SU1,
	SHA512H, SHA512H2, SHA512SU0, SHA512SU1,   // v8.2-A
	EOR3, BCAX, RAX1, XAR,                     // SHA3 v8.2-A
	SM3PARTW1, SM3PARTW2, SM3SS1, SM3TT1A, SM3TT1B, SM3TT2A, SM3TT2B,
	SM4E, SM4EKEY,
	PMULL, PMULL2,

	// -------------------------------------------------------------------------
	// BFloat16 (BF16; v8.6-A)
	// -------------------------------------------------------------------------
	BFCVT,                                     // BFloat16 from single
	BFDOT, BFMMLA, BFMLALB, BFMLALT, BFCVTN, BFCVTN2,

	// -------------------------------------------------------------------------
	// NEON Advanced SIMD
	// -------------------------------------------------------------------------
	// Vector forms. A name that also has a scalar form above (ADD/SUB/MUL/
	// AND/ORR/EOR/MVN/...) is the SAME mnemonic -- the vector forms simply
	// join that mnemonic's run, selected by the V-register operand types.
	// Only names with no scalar counterpart appear below.

	// 3-same arithmetic
	MUL, MLA, MLS, NEG, ABS,
	SHADD, UHADD, SHSUB, UHSUB, SRHADD, URHADD,
	SQADD, UQADD, SQSUB, UQSUB,
	SMAX, UMAX, SMIN, UMIN,
	SABD, UABD, SABA, UABA,
	ADDP, ADDV,
	SADDLP, UADDLP, SADALP, UADALP,
	SADDLV, UADDLV, SMAXV, UMAXV, SMINV, UMINV,
	SMAXP, UMAXP, SMINP, UMINP,

	// long / wide / narrowing
	SADDL, SADDL2, UADDL, UADDL2,
	SSUBL, SSUBL2, USUBL, USUBL2,
	SADDW, SADDW2, UADDW, UADDW2,
	SSUBW, SSUBW2, USUBW, USUBW2,
	RADDHN, RADDHN2, RSUBHN, RSUBHN2,
	ADDHN, ADDHN2, SUBHN, SUBHN2,
	XTN, XTN2, SQXTN, SQXTN2, UQXTN, UQXTN2, SQXTUN, SQXTUN2,

	// multiply long / multiply-accumulate long
	SMULL, SMULL2, UMULL, UMULL2,
	SMLAL, SMLAL2, UMLAL, UMLAL2,
	SMLSL, SMLSL2, UMLSL, UMLSL2,
	SQDMULL, SQDMULL2, SQDMLAL, SQDMLAL2, SQDMLSL, SQDMLSL2,
	SQDMULH, SQRDMULH,

	// dot product
	SDOT, UDOT, USDOT,

	// FP vector
	FMLA, FMLS, FMULX,
	FMAXP, FMINP, FMAXNMP, FMINNMP,
	FMAXV, FMINV, FMAXNMV, FMINNMV,
	FRECPE, FRSQRTE, FRECPS, FRSQRTS, FRECPX,
	FADDP,
	FCVTL, FCVTL2, FCVTN, FCVTN2, FCVTXN, FCVTXN2,

	// FP compare (vector)
	FCMEQ, FCMGE, FCMGT, FCMLE, FCMLT,
	FACGE, FACGT,

	// Integer compare (vector)
	CMEQ, CMGE, CMGT, CMHI, CMHS, CMLE, CMLT, CMTST,

	// Logical (vector)
	MVN,
	BIT, BIF, BSL,

	// Shifts
	SHL, SQSHL, SQSHLU, SRSHL, URSHL,
	SSHR, USHR, SSRA, USRA, SRSHR, URSHR, SRSRA, URSRA,
	SSHL, USHL,
	SLI, SRI,
	SSHLL, SSHLL2, USHLL, USHLL2,
	SXTL, SXTL2, UXTL, UXTL2,                  // aliases of SSHLL/USHLL with imm=0
	SHRN, SHRN2, RSHRN, RSHRN2,
	SQSHRN, SQSHRN2, UQSHRN, UQSHRN2,
	SQRSHRN, SQRSHRN2, UQRSHRN, UQRSHRN2,
	SQSHRUN, SQSHRUN2, SQRSHRUN, SQRSHRUN2,

	// Misc / permute / bit
	DUP, INS, MOV,
	EXT,
	TBL, TBX,
	ZIP1, ZIP2, UZP1, UZP2, TRN1, TRN2,
	NOT, REV64,
	CNT,
	URECPE, URSQRTE,

	// Vector immediate
	MOVI, MVNI,

	// NEON load/store
	LD1, LD2, LD3, LD4,                        // multiple structures
	ST1, ST2, ST3, ST4,
	LD1R, LD2R, LD3R, LD4R,                    // load-and-replicate to all lanes

	// FP/SIMD load/store using V/D/S/H/B/Q registers

	// -------------------------------------------------------------------------
	// SVE / SVE2 base
	// -------------------------------------------------------------------------
	//
	// SVE reuses the base integer / NEON mnemonics: `add z0.s, z1.s, z2.s`
	// and `add z0.s, p0/m, z0.s, z1.s` are both ADD, and land in ADD's run
	// as forms taking Z / predicate operands. Only SVE-only names are listed.

	// Integer arithmetic (vectors, unpredicated)

	// Integer arithmetic (predicated, destructive merging)
	SUBR,
	ASRR, LSLR, LSRR,

	// FP arithmetic (unpredicated)
	FTSMUL,

	// FP arithmetic (predicated, destructive merging)
	FSUBR,
	FDIVR,
	FNMLA, FNMLS,

	// Predicate logical / move
	NAND, NOR, SEL,
	ORRS, EORS,
	NANDS, NORS, ORNS,
	MOVS,
	PTRUE, PTRUES, PFALSE, PFIRST, PNEXT,
	BRKA, BRKB, BRKAS, BRKBS,
	BRKPA, BRKPB, BRKN,
	RDFFR, WRFFR, SETFFR,

	// Integer compare and set predicate
	CMPEQ, CMPNE, CMPGE, CMPGT, CMPLE, CMPLT,
	CMPHI, CMPHS, CMPLO, CMPLS,

	// FP compare and set predicate
	FCMNE, FCMUO,

	// Permute / move / replicate
	INSR,
	CPY, COMPACT,

	// Loads / stores (contiguous)
	LD1B, LD1H, LD1W, LD1D,
	LD1SB, LD1SH, LD1SW,
	ST1B, ST1H, ST1W, ST1D,
	LDFF1B, LDFF1H, LDFF1W, LDFF1D,            // first-faulting

	// SVE2 additions
	WHILEGE, WHILEGT, WHILELE, WHILELT,
	WHILEHI, WHILEHS, WHILELO, WHILELS,
	SQRDMLAH, SQRDMLSH,
	ADCLB, ADCLT, SBCLB, SBCLT,
	TBL2,
	MATCH, NMATCH,
	HISTCNT, HISTSEG,

	// -------------------------------------------------------------------------
	// SME (Scalable Matrix Extension)
	// -------------------------------------------------------------------------
	SMSTART, SMSTOP,
	RDSVL, ADDHA, ADDVA,
	ZERO,
	FMOPA, FMOPS,
	BFMOPA, BFMOPS,
	SMOPA, SMOPS, UMOPA, UMOPS,
	USMOPA, SUMOPA,

	// -------------------------------------------------------------------------
	// SME tile slice load/store (LD1B/H/W/D/Q to ZA tile slice; ST1 reverse)
	// -------------------------------------------------------------------------
	LD1Q,
	ST1Q,

	// MOVA between Z register and tile slice (both directions)
	MOVA,

	// -------------------------------------------------------------------------
	// NEON complex FP multiply-add (v8.3-A FCMA extension)
	// -------------------------------------------------------------------------
	FCMLA,
	FCADD,

	// -------------------------------------------------------------------------
	// SVE prefetch, non-temporal load/store, EXT/SPLICE/INDEX
	// -------------------------------------------------------------------------
	PRFB, PRFH, PRFW, PRFD,
	LDNT1B, LDNT1H, LDNT1W, LDNT1D,
	STNT1B, STNT1H, STNT1W, STNT1D,
	SPLICE,
	INDEX,

	// -------------------------------------------------------------------------
	// SVE2 bitwise select family + polynomial multiply
	// -------------------------------------------------------------------------
	BSL1N, BSL2N, NBSL,
	PMUL, PMULLB, PMULLT,

	// -------------------------------------------------------------------------
	// SVE BF16 conversions (BFCVT in SVE form)
	// -------------------------------------------------------------------------
	BFCVTNT,

	// -------------------------------------------------------------------------
	// PAC-authenticated loads (v8.3-A)
	// -------------------------------------------------------------------------
	LDRAA, LDRAB,

	// -------------------------------------------------------------------------
	// Transactional Memory Extension (TME, v9.0-A)
	// -------------------------------------------------------------------------
	TSTART, TCOMMIT, TCANCEL, TTEST,

	// -------------------------------------------------------------------------
	// Wait with timeout (v8.7-A)
	// -------------------------------------------------------------------------
	WFET, WFIT,

	// -------------------------------------------------------------------------
	// Branch consistency hint (v8.8-A BC.cond)
	// -------------------------------------------------------------------------
	// BC.cond: the consistent-branch form, same 16 conditions.
	BC_EQ, BC_NE, BC_CS, BC_CC,
	BC_MI, BC_PL, BC_VS, BC_VC,
	BC_HI, BC_LS, BC_GE, BC_LT,
	BC_GT, BC_LE, BC_AL, BC_NV,

	// -------------------------------------------------------------------------
	// Sign/zero extend aliases (canonical names for SBFM/UBFM specific cases)
	// -------------------------------------------------------------------------
	UXTB, UXTH, UXTW,                          // unsigned extends (UBFM aliases)
	SXTB, SXTH, SXTW,                          // signed extends (SBFM aliases)

	// -------------------------------------------------------------------------
	// Carry arithmetic (add/sub with carry)
	// -------------------------------------------------------------------------
	ADC, ADCS, SBC, SBCS,
	NGC, NGCS,                                 // NGC Rd, Rm = SBC Rd, ZR, Rm; NGCS similar

	// -------------------------------------------------------------------------
	// RCpc / LDAPUR / STLUR (v8.4-A unscaled release-consistency loads/stores)
	// -------------------------------------------------------------------------
	LDAPUR, STLUR,                             // 32/64-bit word
	LDAPURB, STLURB, LDAPURH, STLURH,          // byte / half
	LDAPURSB, LDAPURSH, LDAPURSW,              // signed extending

	// -------------------------------------------------------------------------
	// SVE BF16 predicated arithmetic (3-same)
	// -------------------------------------------------------------------------
	BFADD, BFSUB, BFMUL,
	BFMLA, BFMLS,

	// -------------------------------------------------------------------------
	// Speculation / profiling barriers + speculation hints
	// -------------------------------------------------------------------------
	SB,                                        // Speculation Barrier (v8.0)
	CSDB,                                      // Consumption of Speculative Data Barrier
	DGH,                                       // Data Gathering Hint (v8.5-A)
	PSB_CSYNC,                                 // Profile Synchronization Barrier
	TSB_CSYNC,                                 // Trace Synchronization Barrier
	BTI_J, BTI_C, BTI_JC,                      // explicit BTI variants

	// -------------------------------------------------------------------------
	// SVE2.1 / SME2 -- BF16 unpredicated + clamp/min/max + multi-vector
	// -------------------------------------------------------------------------
	BFCLAMP,                                   // BFCLAMP Zd.H, Zn.H, Zm.H
	BFMAXNM, BFMINNM,                          // BF16 min/max-num predicated

	// SME2 multi-vector: contiguous LD/ST and select-table lookup
	LUTI2, LUTI4,                              // LUTI2/4 table lookup (byte)

	// SME2 ZIP / UZP multi-way (3-vector and 4-vector forms)
	ZIP,
	UZP,

	// -------------------------------------------------------------------------
	// RME (Realm Management Extension, ARMv9-A)
	// -------------------------------------------------------------------------
	TLBI_RPALOS, TLBI_RPAOS,                   // Realm physical address space
	AT_S1E1A,                                  // stage-1 translate with implicit authority
	DC_CIPAPA, DC_CIGDPAPA,                    // physical-address cache mgmt
	TLBI_PAALL, TLBI_PAALLOS,

	// -------------------------------------------------------------------------
	// Apple AMX (undocumented vendor coprocessor; A13+/M1+)
	// -------------------------------------------------------------------------
	//
	// All AMX instructions share the encoding 0x00201000 | (op << 5) | xn,
	// where xn is a 5-bit operand (typically a GPR holding pointer +
	// control word). The reserved bit pattern lives in the system-
	// instruction space (op0 = 0b0000) so it doesn't collide with any
	// standard A64 mnemonic. Reverse-engineered ops:
	//
	//   00 LDX     load X register set (16 input rows)
	//   01 LDY     load Y register set (16 input rows)
	//   02 STX     store X
	//   03 STY     store Y
	//   04 LDZ     load Z accumulator (64 rows)
	//   05 STZ     store Z
	//   06 LDZI    load Z interleaved
	//   07 STZI    store Z interleaved
	//   08 EXTRX   extract from X
	//   09 EXTRY   extract from Y
	//   10 FMA64   FP64 fused multiply-add
	//   11 FMS64   FP64 fused multiply-subtract
	//   12 FMA32   FP32 fused multiply-add
	//   13 FMS32   FP32 fused multiply-subtract
	//   14 MAC16   int16 multiply-accumulate
	//   15 FMA16   FP16 fused multiply-add
	//   16 FMS16   FP16 fused multiply-subtract
	//   17 SET     enable AMX (operand=0)
	//   18 CLR     disable AMX
	//   19 VECINT  integer vector ops
	//   20 VECFP   FP vector ops
	//   21 MATINT  integer matrix ops
	//   22 MATFP   FP matrix ops
	//   23 GENLUT  general lookup table (A14+)
	AMX_LDX, AMX_LDY, AMX_STX, AMX_STY,
	AMX_LDZ, AMX_STZ, AMX_LDZI, AMX_STZI,
	AMX_EXTRX, AMX_EXTRY,
	AMX_FMA64, AMX_FMS64,
	AMX_FMA32, AMX_FMS32,
	AMX_MAC16, AMX_FMA16, AMX_FMS16,
	AMX_SET, AMX_CLR,
	AMX_VECINT, AMX_VECFP, AMX_MATINT, AMX_MATFP,
	AMX_GENLUT,

	// -------------------------------------------------------------------------
	// MOPS (Memory Operations, v8.8-A)
	// -------------------------------------------------------------------------
	//
	// Each operation is split into a 3-instruction Prologue/Main/Epilogue
	// sequence that all share the same {Xd, Xs, Xn} destructive operands.
	//   CPY*  : general memcpy (may overlap)
	//   CPYF* : forward-only memcpy
	//   SET*  : memset (Xs holds the byte value)
	CPYP, CPYM, CPYE,
	CPYFP, CPYFM, CPYFE,
	SETP, SETM, SETE,

	// -------------------------------------------------------------------------
	// Cache management (SYS-encoded under op0=3 or op0=0)
	// -------------------------------------------------------------------------
	//
	// Data cache:
	DC_IVAC, DC_ISW, DC_CSW, DC_CISW,
	DC_ZVA, DC_CVAC, DC_CVAU, DC_CIVAC,
	// Instruction cache:
	IC_IALLUIS, IC_IALLU, IC_IVAU,
	// Address translate (PE current EL):
	AT_S1E1R, AT_S1E1W, AT_S1E0R, AT_S1E0W,
	AT_S1E2R, AT_S1E2W, AT_S1E3R, AT_S1E3W,
	AT_S12E1R, AT_S12E1W, AT_S12E0R, AT_S12E0W,
	// TLB invalidate (the practical subset):
	TLBI_VMALLE1, TLBI_VMALLE1IS,
	TLBI_VAE1, TLBI_VAE1IS,
	TLBI_ASIDE1, TLBI_ASIDE1IS,
	TLBI_VAAE1, TLBI_VAAE1IS,
	TLBI_VALE1, TLBI_VALE1IS,
	TLBI_VAALE1, TLBI_VAALE1IS,
	TLBI_ALLE1, TLBI_ALLE1IS,
	TLBI_ALLE2, TLBI_ALLE2IS, TLBI_ALLE3, TLBI_ALLE3IS,

	// -------------------------------------------------------------------------
	// Prefetch
	// -------------------------------------------------------------------------
	PRFM, PRFUM,

	// -------------------------------------------------------------------------
	// Aliases (printed canonically; encode the underlying operation with
	// Rd=ZR or Rn=ZR fixed).
	// -------------------------------------------------------------------------
	NEGS,                                      // NEGS Rd, Rm{,shift} =  SUBS Rd, ZR, Rm{,shift}
	CMP,                                       // CMP Rn, Rm{,shift}  =  SUBS ZR, Rn, Rm{,shift}
	CMN,                                       // CMN Rn, Rm{,shift}  =  ADDS ZR, Rn, Rm{,shift}
}
