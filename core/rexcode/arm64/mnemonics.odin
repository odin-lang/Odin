package rexcode_arm64

// =============================================================================
// AArch64 MNEMONICS (v1 -- base integer + FP scalar)
// =============================================================================
//
// This is the v1 cut focused on the base integer ISA + scalar FP. Each
// extension (NEON, LSE atomics, crypto, FP16/BF16, SVE, SVE2, SME, PAC,
// BTI, MTE, ...) lands in a follow-up turn.
//
// Some "instructions" that share an opcode with another are real
// aliases at the architectural level (e.g. MOV/MVN are aliases of
// ORR/ORN, NEG of SUB, CMP of SUBS, etc.). For v1 the explicit
// non-alias mnemonic is exposed; aliases can be added later as
// printer hints + encoder builders that lower to the real form.

Mnemonic :: enum u16 {
	INVALID = 0,

	// -------------------------------------------------------------------------
	// Data processing -- immediate
	// -------------------------------------------------------------------------

	ADD_IMM, ADDS_IMM, SUB_IMM, SUBS_IMM,    // optional LSL #12 carried in shift field
	MOVZ, MOVN, MOVK,                         // 16-bit imm + 2-bit hw
	ADR, ADRP,                                // PC-relative address

	// -------------------------------------------------------------------------
	// Data processing -- register (shifted register)
	// -------------------------------------------------------------------------

	ADD_SR, ADDS_SR, SUB_SR, SUBS_SR,
	AND_SR, ANDS_SR, ORR_SR, EOR_SR,
	BIC_SR, BICS_SR, ORN_SR, EON_SR,

	// -------------------------------------------------------------------------
	// Data processing -- register (extended register)
	// -------------------------------------------------------------------------

	ADD_ER, ADDS_ER, SUB_ER, SUBS_ER,

	// -------------------------------------------------------------------------
	// Data processing -- register (variable shifts / 2-source)
	// -------------------------------------------------------------------------

	LSLV, LSRV, ASRV, RORV,                   // also printed as LSL/LSR/ASR/ROR
	UDIV, SDIV,

	// -------------------------------------------------------------------------
	// Data processing -- register (3-source)
	// -------------------------------------------------------------------------

	MADD, MSUB,                               // 64x64+64 -> 64 (or 32 variant)
	SMADDL, SMSUBL, UMADDL, UMSUBL,           // 32x32+64 -> 64
	SMULH, UMULH,                             // 64x64 -> high 64

	// -------------------------------------------------------------------------
	// Data processing -- register (1-source bit-twiddling)
	// -------------------------------------------------------------------------

	CLZ, CLS, RBIT, REV, REV16, REV32,

	// -------------------------------------------------------------------------
	// Conditional select / compare
	// -------------------------------------------------------------------------

	CSEL, CSINC, CSINV, CSNEG,
	CCMP_REG, CCMP_IMM, CCMN_REG, CCMN_IMM,

	// -------------------------------------------------------------------------
	// Extract
	// -------------------------------------------------------------------------

	EXTR,

	// -------------------------------------------------------------------------
	// Branches
	// -------------------------------------------------------------------------

	B, BL,                                    // 26-bit PC-rel
	BR, BLR, RET,                             // register indirect
	B_COND,                                   // B.cond -- 19-bit PC-rel
	CBZ, CBNZ,                                // 19-bit PC-rel + Rt
	TBZ, TBNZ,                                // 14-bit PC-rel + bit position

	// -------------------------------------------------------------------------
	// Loads / stores
	// -------------------------------------------------------------------------

	// Plain (unsigned offset / signed unscaled / pre / post)
	LDR, STR,                                 // X/W variants (matched by reg width)
	LDRB, STRB, LDRSB,
	LDRH, STRH, LDRSH,
	LDRSW,

	// Pair
	LDP, STP, LDPSW,

	// PC-relative literal
	LDR_LIT,

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
	MRS, MSR_IMM, MSR_REG,
	ISB, DSB, DMB,
	SVC, HVC, SMC, BRK, HLT,
	ERET,

	// -------------------------------------------------------------------------
	// FP scalar (single / double)
	// -------------------------------------------------------------------------

	FMOV_REG, FMOV_IMM, FMOV_GEN,             // reg-reg / imm / between int/FP
	FABS, FNEG, FSQRT,
	FADD, FSUB, FMUL, FDIV, FNMUL,
	FMADD, FMSUB, FNMADD, FNMSUB,
	FCMP, FCMPE,
	FCSEL,
	FMAX, FMIN, FMAXNM, FMINNM,
	FCVT,                                     // between single/double/half
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
	AND_IMM, ANDS_IMM, ORR_IMM, EOR_IMM,
	TST_IMM,    // alias of ANDS_IMM with Rd=ZR; printed separately

	// -------------------------------------------------------------------------
	// Additional load/store addressing modes
	// -------------------------------------------------------------------------
	LDUR, STUR, LDURB, STURB, LDURSB, LDURH, STURH, LDURSH, LDURSW,
	LDR_PRE, STR_PRE, LDR_POST, STR_POST,
	LDRB_PRE, STRB_PRE, LDRB_POST, STRB_POST,
	LDRH_PRE, STRH_PRE, LDRH_POST, STRH_POST,
	LDR_REG, STR_REG, LDRB_REG, STRB_REG, LDRH_REG, STRH_REG,
	LDRSB_REG, LDRSH_REG, LDRSW_REG,
	LDP_PRE, STP_PRE, LDP_POST, STP_POST,
	LDPSW_PRE, LDPSW_POST,
	LDNP, STNP,                                // non-temporal pair
	LDXP, STXP, LDAXP, STLXP,                  // exclusive pair
	LDXRB, STXRB, LDAXRB, STLXRB,              // exclusive byte
	LDXRH, STXRH, LDAXRH, STLXRH,              // exclusive halfword
	LDARB_X, STLRB_X, LDARH_X, STLRH_X,        // acquire/release byte/half (the existing LDARB/STLRB/LDARH/STLRH are unsigned)
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
	// FP scalar half-precision (FP16)
	// -------------------------------------------------------------------------
	FABS_H, FNEG_H, FSQRT_H,
	FADD_H, FSUB_H, FMUL_H, FDIV_H, FNMUL_H,
	FMADD_H, FMSUB_H, FNMADD_H, FNMSUB_H,
	FCMP_H, FCMPE_H, FCSEL_H,
	FMAX_H, FMIN_H, FMAXNM_H, FMINNM_H,
	FCVT_H_S, FCVT_H_D, FCVT_S_H, FCVT_D_H,    // half<->single/double cross
	FMOV_H,
	SCVTF_H, UCVTF_H,
	FCVTZS_H, FCVTZU_H,

	// -------------------------------------------------------------------------
	// BFloat16 (BF16; v8.6-A)
	// -------------------------------------------------------------------------
	BFCVT,                                     // BFloat16 from single
	BFDOT, BFMMLA, BFMLALB, BFMLALT, BFCVTN, BFCVTN2,

	// -------------------------------------------------------------------------
	// NEON Advanced SIMD
	// -------------------------------------------------------------------------
	// The mnemonics here cover vector forms. Where a name collides with a
	// scalar mnemonic above (ADD/SUB/MUL/AND/ORR/EOR/MVN/...) we suffix
	// with _V; the printer strips the suffix so the disassembly reads the
	// canonical mnemonic (`add v0.16b, ...`).

	// 3-same arithmetic
	ADD_V, SUB_V, MUL_V, MLA_V, MLS_V, NEG_V, ABS_V,
	SHADD, UHADD, SHSUB, UHSUB, SRHADD, URHADD,
	SQADD, UQADD, SQSUB, UQSUB,
	SMAX, UMAX, SMIN, UMIN,
	SABD, UABD, SABA, UABA,
	ADDP_V, ADDV,
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
	SMULL_V, SMULL2_V, UMULL_V, UMULL2_V,
	SMLAL, SMLAL2, UMLAL, UMLAL2,
	SMLSL, SMLSL2, UMLSL, UMLSL2,
	SQDMULL, SQDMULL2, SQDMLAL, SQDMLAL2, SQDMLSL, SQDMLSL2,
	SQDMULH, SQRDMULH,

	// dot product
	SDOT, UDOT, USDOT,

	// FP vector
	FADD_V, FSUB_V, FMUL_V, FDIV_V, FNEG_V, FABS_V, FSQRT_V,
	FMLA_V, FMLS_V, FMULX,
	FMAX_V, FMIN_V, FMAXNM_V, FMINNM_V,
	FMAXP_V, FMINP_V, FMAXNMP, FMINNMP,
	FMAXV_V, FMINV_V, FMAXNMV, FMINNMV,
	FRECPE, FRSQRTE, FRECPS, FRSQRTS, FRECPX,
	FADDP_V,
	FRINTA_V, FRINTI_V, FRINTM_V, FRINTN_V, FRINTP_V, FRINTX_V, FRINTZ_V,
	SCVTF_V, UCVTF_V,
	FCVTAS_V, FCVTAU_V, FCVTMS_V, FCVTMU_V,
	FCVTNS_V, FCVTNU_V, FCVTPS_V, FCVTPU_V,
	FCVTZS_V, FCVTZU_V,
	FCVTL, FCVTL2, FCVTN, FCVTN2, FCVTXN, FCVTXN2,

	// FP compare (vector)
	FCMEQ, FCMGE, FCMGT, FCMLE, FCMLT,
	FACGE, FACGT,

	// Integer compare (vector)
	CMEQ, CMGE, CMGT, CMHI, CMHS, CMLE, CMLT, CMTST,

	// Logical (vector)
	AND_V, ORR_V, EOR_V, BIC_V, ORN_V, MVN_V,
	BIT, BIF, BSL,

	// Shifts
	SHL_V, SQSHL_V, SQSHLU, SRSHL, URSHL,
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
	DUP_V, INS, MOV_V,
	EXT_V,
	TBL, TBX,
	ZIP1, ZIP2, UZP1, UZP2, TRN1, TRN2,
	NOT_V, RBIT_V, REV16_V, REV32_V, REV64,
	CLS_V, CLZ_V, CNT,
	URECPE_V, URSQRTE_V,

	// Vector immediate
	MOVI, MVNI, FMOV_V_IMM,

	// NEON load/store
	LD1, LD2, LD3, LD4,                        // multiple structures
	ST1, ST2, ST3, ST4,
	LD1R, LD2R, LD3R, LD4R,                    // load-and-replicate to all lanes
	LD1_LANE, LD2_LANE, LD3_LANE, LD4_LANE,    // load single structure to lane
	ST1_LANE, ST2_LANE, ST3_LANE, ST4_LANE,

	// FP/SIMD load/store using V/D/S/H/B/Q registers
	LDR_V, STR_V,                              // imm/literal/pre/post/reg
	LDP_V, STP_V,
	LDUR_V, STUR_V,

	// -------------------------------------------------------------------------
	// SVE / SVE2 base
	// -------------------------------------------------------------------------
	//
	// SVE mnemonics carry a Z/P-relevant suffix on conflicts with base
	// integer / NEON names. `_Z` (Z-register), `_PRED` (predicated form
	// where there's a separate unpredicated form), `_P` (predicate-only).

	// Integer arithmetic (vectors, unpredicated)
	SVE_ADD_Z, SVE_SUB_Z, SVE_SQADD_Z, SVE_UQADD_Z, SVE_SQSUB_Z, SVE_UQSUB_Z,

	// Integer arithmetic (predicated, destructive merging)
	SVE_ADD_PRED, SVE_SUB_PRED, SVE_SUBR_PRED,
	SVE_MUL_PRED, SVE_SMULH_PRED, SVE_UMULH_PRED,
	SVE_SDIV_PRED, SVE_UDIV_PRED,
	SVE_SMAX_PRED, SVE_UMAX_PRED, SVE_SMIN_PRED, SVE_UMIN_PRED,
	SVE_SABD_PRED, SVE_UABD_PRED,
	SVE_AND_PRED, SVE_ORR_PRED, SVE_EOR_PRED, SVE_BIC_PRED,
	SVE_ASR_PRED, SVE_LSL_PRED, SVE_LSR_PRED, SVE_ASRR_PRED, SVE_LSLR_PRED, SVE_LSRR_PRED,
	SVE_ABS_PRED, SVE_NEG_PRED,
	SVE_CLS_PRED, SVE_CLZ_PRED, SVE_CNT_PRED,
	SVE_MOV_PRED,

	// FP arithmetic (unpredicated)
	SVE_FADD_Z, SVE_FSUB_Z, SVE_FMUL_Z,
	SVE_FRECPS, SVE_FRSQRTS, SVE_FTSMUL,

	// FP arithmetic (predicated, destructive merging)
	SVE_FADD_PRED, SVE_FSUB_PRED, SVE_FSUBR_PRED,
	SVE_FMUL_PRED, SVE_FDIV_PRED, SVE_FDIVR_PRED,
	SVE_FMAX_PRED, SVE_FMIN_PRED, SVE_FMAXNM_PRED, SVE_FMINNM_PRED,
	SVE_FABS_Z, SVE_FNEG_Z, SVE_FSQRT_Z, SVE_FRECPX_Z,
	SVE_FRINTN, SVE_FRINTP, SVE_FRINTM, SVE_FRINTZ, SVE_FRINTA, SVE_FRINTX, SVE_FRINTI,
	SVE_FMLA, SVE_FMLS, SVE_FNMLA, SVE_FNMLS,

	// Predicate logical / move
	SVE_AND_P, SVE_BIC_P, SVE_ORR_P, SVE_EOR_P,
	SVE_NAND_P, SVE_NOR_P, SVE_ORN_P, SVE_SEL_P,
	SVE_ANDS_P, SVE_BICS_P, SVE_ORRS_P, SVE_EORS_P,
	SVE_NANDS_P, SVE_NORS_P, SVE_ORNS_P,
	SVE_NOT_P, SVE_MOV_P, SVE_MOVS_P,
	SVE_PTRUE, SVE_PTRUES, SVE_PFALSE, SVE_PFIRST, SVE_PNEXT,
	SVE_BRKA, SVE_BRKB, SVE_BRKAS, SVE_BRKBS,
	SVE_BRKPA, SVE_BRKPB, SVE_BRKN,
	SVE_RDFFR, SVE_WRFFR, SVE_SETFFR,

	// Integer compare and set predicate
	SVE_CMPEQ, SVE_CMPNE, SVE_CMPGE, SVE_CMPGT, SVE_CMPLE, SVE_CMPLT,
	SVE_CMPHI, SVE_CMPHS, SVE_CMPLO, SVE_CMPLS,

	// FP compare and set predicate
	SVE_FCMEQ, SVE_FCMNE, SVE_FCMGE, SVE_FCMGT, SVE_FCMLE, SVE_FCMLT, SVE_FCMUO,

	// Permute / move / replicate
	SVE_DUP_Z, SVE_INSR, SVE_REV_Z, SVE_REV_P, SVE_TBL,
	SVE_ZIP1_Z, SVE_ZIP2_Z, SVE_UZP1_Z, SVE_UZP2_Z, SVE_TRN1_Z, SVE_TRN2_Z,
	SVE_ZIP1_P, SVE_ZIP2_P, SVE_UZP1_P, SVE_UZP2_P, SVE_TRN1_P, SVE_TRN2_P,
	SVE_CPY_Z, SVE_COMPACT, SVE_EXT_Z,

	// Loads / stores (contiguous)
	SVE_LD1B, SVE_LD1H, SVE_LD1W, SVE_LD1D,
	SVE_LD1SB, SVE_LD1SH, SVE_LD1SW,
	SVE_ST1B, SVE_ST1H, SVE_ST1W, SVE_ST1D,
	SVE_LDR_Z, SVE_STR_Z, SVE_LDR_P, SVE_STR_P,
	SVE_LDFF1B, SVE_LDFF1H, SVE_LDFF1W, SVE_LDFF1D,    // first-faulting

	// SVE2 additions
	SVE_WHILEGE, SVE_WHILEGT, SVE_WHILELE, SVE_WHILELT,
	SVE_WHILEHI, SVE_WHILEHS, SVE_WHILELO, SVE_WHILELS,
	SVE_SQRDMLAH, SVE_SQRDMLSH,
	SVE_ADCLB, SVE_ADCLT, SVE_SBCLB, SVE_SBCLT,
	SVE_TBL2, SVE_TBX,
	SVE_AESE, SVE_AESD, SVE_AESMC, SVE_AESIMC,         // SVE2 crypto
	SVE_BCAX_Z, SVE_XAR_Z, SVE_EOR3_Z,
	SVE_MATCH, SVE_NMATCH,
	SVE_HISTCNT, SVE_HISTSEG,

	// -------------------------------------------------------------------------
	// SME (Scalable Matrix Extension)
	// -------------------------------------------------------------------------
	SME_SMSTART, SME_SMSTOP,
	SME_RDSVL, SME_ADDHA, SME_ADDVA,
	SME_ZERO,
	SME_FMOPA, SME_FMOPS,
	SME_BFMOPA, SME_BFMOPS,
	SME_SMOPA, SME_SMOPS, SME_UMOPA, SME_UMOPS,
	SME_USMOPA, SME_SUMOPA,
	SME_MOVA_TO_Z, SME_MOVA_TO_ZA,
	SME_LD1B_ZA, SME_LD1H_ZA, SME_LD1W_ZA, SME_LD1D_ZA, SME_LD1Q_ZA,
	SME_ST1B_ZA, SME_ST1H_ZA, SME_ST1W_ZA, SME_ST1D_ZA, SME_ST1Q_ZA,
	SME_LDR_ZA, SME_STR_ZA,

	// -------------------------------------------------------------------------
	// SVE indexed FMLA / FMLS (lane-broadcast multiply-accumulate)
	// -------------------------------------------------------------------------
	SVE_FMLA_IDX_H, SVE_FMLA_IDX_S, SVE_FMLA_IDX_D,
	SVE_FMLS_IDX_H, SVE_FMLS_IDX_S, SVE_FMLS_IDX_D,

	// -------------------------------------------------------------------------
	// SVE gather/scatter (the practical 32-bit and 64-bit offset forms)
	// -------------------------------------------------------------------------
	SVE_LD1B_GATHER_S, SVE_LD1B_GATHER_D,
	SVE_LD1H_GATHER_S, SVE_LD1H_GATHER_D,
	SVE_LD1W_GATHER_S, SVE_LD1W_GATHER_D,
	SVE_LD1D_GATHER_D,
	SVE_LD1SB_GATHER_S, SVE_LD1SB_GATHER_D,
	SVE_LD1SH_GATHER_S, SVE_LD1SH_GATHER_D,
	SVE_LD1SW_GATHER_D,
	SVE_ST1B_SCATTER_S, SVE_ST1B_SCATTER_D,
	SVE_ST1H_SCATTER_S, SVE_ST1H_SCATTER_D,
	SVE_ST1W_SCATTER_S, SVE_ST1W_SCATTER_D,
	SVE_ST1D_SCATTER_D,

	// -------------------------------------------------------------------------
	// SME tile slice load/store (LD1B/H/W/D/Q to ZA tile slice; ST1 reverse)
	// -------------------------------------------------------------------------
	SME_LD1B_TILE, SME_LD1H_TILE, SME_LD1W_TILE, SME_LD1D_TILE, SME_LD1Q_TILE,
	SME_ST1B_TILE, SME_ST1H_TILE, SME_ST1W_TILE, SME_ST1D_TILE, SME_ST1Q_TILE,

	// MOVA between Z register and tile slice (both directions)
	SME_MOVA_Z_FROM_TILE, SME_MOVA_TILE_FROM_Z,

	// -------------------------------------------------------------------------
	// NEON complex FP multiply-add (v8.3-A FCMA extension)
	// -------------------------------------------------------------------------
	FCMLA_4H, FCMLA_8H, FCMLA_4S, FCMLA_2D,
	FCADD_4H, FCADD_8H, FCADD_4S, FCADD_2D,

	// -------------------------------------------------------------------------
	// SVE prefetch, non-temporal load/store, EXT/SPLICE/INDEX
	// -------------------------------------------------------------------------
	SVE_PRFB, SVE_PRFH, SVE_PRFW, SVE_PRFD,
	SVE_LDNT1B, SVE_LDNT1H, SVE_LDNT1W, SVE_LDNT1D,
	SVE_STNT1B, SVE_STNT1H, SVE_STNT1W, SVE_STNT1D,
	SVE_EXT, SVE_SPLICE,
	SVE_INDEX_II, SVE_INDEX_IR, SVE_INDEX_RI, SVE_INDEX_RR,

	// -------------------------------------------------------------------------
	// SVE2 bitwise select family + polynomial multiply
	// -------------------------------------------------------------------------
	SVE_BSL, SVE_BSL1N, SVE_BSL2N, SVE_NBSL,
	SVE_PMUL_VEC, SVE_PMULLB, SVE_PMULLT,

	// -------------------------------------------------------------------------
	// SVE BF16 conversions (BFCVT in SVE form)
	// -------------------------------------------------------------------------
	SVE_BFCVT, SVE_BFCVTNT,

	// -------------------------------------------------------------------------
	// PAC-authenticated loads (v8.3-A)
	// -------------------------------------------------------------------------
	LDRAA, LDRAB, LDRAA_PRE, LDRAB_PRE,

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
	BC_COND,

	// -------------------------------------------------------------------------
	// Sign/zero extend aliases (canonical names for SBFM/UBFM specific cases)
	// -------------------------------------------------------------------------
	UXTB, UXTH, UXTW,    // unsigned extends (UBFM aliases)
	SXTB, SXTH, SXTW,    // signed extends (SBFM aliases)

	// -------------------------------------------------------------------------
	// Carry arithmetic (add/sub with carry)
	// -------------------------------------------------------------------------
	ADC, ADCS, SBC, SBCS,
	NGC, NGCS,           // NGC Rd, Rm = SBC Rd, ZR, Rm; NGCS similar

	// -------------------------------------------------------------------------
	// RCpc / LDAPUR / STLUR (v8.4-A unscaled release-consistency loads/stores)
	// -------------------------------------------------------------------------
	LDAPUR, STLUR,                       // 32/64-bit word
	LDAPURB, STLURB, LDAPURH, STLURH,    // byte / half
	LDAPURSB, LDAPURSH, LDAPURSW,        // signed extending

	// -------------------------------------------------------------------------
	// SVE BF16 predicated arithmetic (3-same)
	// -------------------------------------------------------------------------
	SVE_BFADD, SVE_BFSUB, SVE_BFMUL,
	SVE_BFMLA, SVE_BFMLS,

	// -------------------------------------------------------------------------
	// Speculation / profiling barriers + speculation hints
	// -------------------------------------------------------------------------
	SB,                  // Speculation Barrier (v8.0)
	CSDB,                // Consumption of Speculative Data Barrier
	DGH,                 // Data Gathering Hint (v8.5-A)
	PSB_CSYNC,           // Profile Synchronization Barrier
	TSB_CSYNC,           // Trace Synchronization Barrier
	BTI_J, BTI_C, BTI_JC,// explicit BTI variants

	// -------------------------------------------------------------------------
	// Random number access (v8.5-A) -- read RNDR / RNDRRS via MRS
	// -------------------------------------------------------------------------
	// (sysreg constants are in sysregs.odin; the MRS mnemonic handles it)

	// -------------------------------------------------------------------------
	// More NEON aliases
	// -------------------------------------------------------------------------
	MOV_V_ALIAS,         // MOV Vd.<T>, Vn.<T> = ORR Vd, Vn, Vn  (vector copy)
	NOT_V_ALIAS,         // NOT Vd.<T>, Vn.<T> = MVN with Rm=Rn

	// -------------------------------------------------------------------------
	// Shift-by-immediate aliases (UBFM/SBFM specific cases)
	// -------------------------------------------------------------------------
	LSL_IMM,             // LSL Rd, Rn, #imm = UBFM Rd, Rn, #(-imm % regsize), #(regsize-1-imm)
	LSR_IMM,             // LSR Rd, Rn, #imm = UBFM Rd, Rn, #imm, #(regsize-1)
	ASR_IMM,             // ASR Rd, Rn, #imm = SBFM Rd, Rn, #imm, #(regsize-1)
	ROR_IMM,             // ROR Rd, Rn, #imm = EXTR Rd, Rn, Rn, #imm

	// -------------------------------------------------------------------------
	// SVE2.1 / SME2 -- BF16 unpredicated + clamp/min/max + multi-vector
	// -------------------------------------------------------------------------
	SVE_BFADD_UNPRED, SVE_BFSUB_UNPRED, SVE_BFMUL_UNPRED,
	SVE_BFCLAMP,                          // BFCLAMP Zd.H, Zn.H, Zm.H
	SVE_BFMAXNM, SVE_BFMINNM,             // BF16 min/max-num predicated

	// SME2 multi-vector: contiguous LD/ST and select-table lookup
	SME2_LUTI2_B, SME2_LUTI4_B,           // LUTI2/4 table lookup (byte)
	SME2_LD1B_X2,  SME2_LD1H_X2,          // 2-vector contiguous loads
	SME2_LD1W_X2,  SME2_LD1D_X2,
	SME2_LD1B_X4,  SME2_LD1H_X4,          // 4-vector contiguous loads
	SME2_LD1W_X4,  SME2_LD1D_X4,
	SME2_ST1B_X2,  SME2_ST1H_X2,
	SME2_ST1W_X2,  SME2_ST1D_X2,
	SME2_ST1B_X4,  SME2_ST1H_X4,
	SME2_ST1W_X4,  SME2_ST1D_X4,

	// SME2 ZIP / UZP multi-way (3-vector and 4-vector forms)
	SME2_ZIP_3, SME2_ZIP_4,
	SME2_UZP_3, SME2_UZP_4,

	// -------------------------------------------------------------------------
	// RME (Realm Management Extension, ARMv9-A)
	// -------------------------------------------------------------------------
	TLBI_RPALOS, TLBI_RPAOS,              // Realm physical address space
	AT_S1E1A,                              // stage-1 translate with implicit authority
	DC_CIPAPA, DC_CIGDPAPA,                // physical-address cache mgmt
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
	PRFM, PRFUM, PRFM_LIT,

	// -------------------------------------------------------------------------
	// Aliases (printed canonically; encode the underlying operation with
	// Rd=ZR or Rn=ZR fixed).
	// -------------------------------------------------------------------------
	MOV_REG,         // MOV Rd, Rm  =  ORR Rd, ZR, Rm  (shifted-register form)
	MOV_BITMASK,     // MOV Rd, #imm =  ORR Rd, ZR, #bitmask_imm
	MVN,             // MVN Rd, Rm  =  ORN Rd, ZR, Rm
	NEG_SR,          // NEG Rd, Rm{,shift}  =  SUB  Rd, ZR, Rm{,shift}
	NEGS,            // NEGS Rd, Rm{,shift} =  SUBS Rd, ZR, Rm{,shift}
	CMP_SR,          // CMP Rn, Rm{,shift}  =  SUBS ZR, Rn, Rm{,shift}
	CMP_ER,          // CMP Rn, Rm, ext     =  SUBS ZR, Rn, Rm, ext
	CMP_IMM,         // CMP Rn, #imm        =  SUBS ZR, Rn, #imm
	CMN_SR,          // CMN Rn, Rm{,shift}  =  ADDS ZR, Rn, Rm{,shift}
	CMN_ER,          // CMN Rn, Rm, ext     =  ADDS ZR, Rn, Rm, ext
	CMN_IMM,         // CMN Rn, #imm        =  ADDS ZR, Rn, #imm
	TST_SR,          // TST Rn, Rm{,shift}  =  ANDS ZR, Rn, Rm{,shift}
}
