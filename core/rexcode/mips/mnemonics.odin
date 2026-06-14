package rexcode_mips

// =============================================================================
// MIPS MNEMONICS
// =============================================================================
//
// Covers MIPS I/II/III/IV/V, MIPS32/64 R1/R2/R6 (selected), FPU (COP1) in
// full, COP0 essentials, and console extensions: PS1 GTE (full), PS2 EE
// MMI (broad subset), PSP Allegrex VFPU (major families). FP arithmetic
// is bake-the-format-into-the-mnemonic: ADD.S => .ADD_S, ADD.D => .ADD_D,
// etc. — keeps the encoding lookup O(1).

Mnemonic :: enum u16 {
	INVALID = 0,

	// -------------------------------------------------------------------------
	// MIPS I — core integer
	// -------------------------------------------------------------------------

	// R-type arithmetic
	ADD, ADDU, SUB, SUBU,
	MULT, MULTU, DIV, DIVU,
	MFHI, MFLO, MTHI, MTLO,
	AND, OR, XOR, NOR,
	SLT, SLTU,

	// R-type shifts
	SLL, SRL, SRA,
	SLLV, SRLV, SRAV,

	// I-type arithmetic
	ADDI, ADDIU,
	SLTI, SLTIU,
	ANDI, ORI, XORI,
	LUI,

	// I-type branches
	BEQ, BNE, BLEZ, BGTZ,

	// REGIMM branches
	BLTZ, BGEZ, BLTZAL, BGEZAL,

	// J-type
	J, JAL,

	// R-type jumps
	JR, JALR,

	// Loads
	LB, LH, LW, LBU, LHU, LWL, LWR,

	// Stores
	SB, SH, SW, SWL, SWR,

	// System
	SYSCALL, BREAK, NOP,

	// -------------------------------------------------------------------------
	// MIPS II additions
	// -------------------------------------------------------------------------

	// Atomic
	LL, SC,

	// Synchronization
	SYNC,

	// Traps (immediate and register variants)
	TGEI, TGEIU, TLTI, TLTIU, TEQI, TNEI,
	TGE, TGEU, TLT, TLTU, TEQ, TNE,

	// Branch-likely (skip delay slot if not taken)
	BEQL, BNEL, BLEZL, BGTZL,
	BLTZL, BGEZL, BLTZALL, BGEZALL,

	// -------------------------------------------------------------------------
	// MIPS III additions (64-bit core)
	// -------------------------------------------------------------------------

	DADD, DADDU, DSUB, DSUBU,
	DADDI, DADDIU,
	DMULT, DMULTU, DDIV, DDIVU,

	DSLL, DSRL, DSRA,
	DSLLV, DSRLV, DSRAV,
	DSLL32, DSRL32, DSRA32,

	LD, LDL, LDR, LWU,
	SD, SDL, SDR,
	LLD, SCD,

	// -------------------------------------------------------------------------
	// MIPS IV additions
	// -------------------------------------------------------------------------

	MOVN, MOVZ,
	MOVF, MOVT,                 // FP-condition-based GPR move
	PREF, PREFX,
	LWXC1, SWXC1, LDXC1, SDXC1, // indexed FP load/store

	// -------------------------------------------------------------------------
	// MIPS32 R1 / R2 — integer additions
	// -------------------------------------------------------------------------

	CLZ, CLO, DCLZ, DCLO,
	MUL,                         // SPECIAL2 multiply-to-rd (doesn't touch HI/LO)
	MADD, MADDU, MSUB, MSUBU,
	SDBBP,
	SSNOP, EHB, PAUSE,

	// R2 bitfield + shuffle
	EXT, INS,
	DEXT, DEXTM, DEXTU,
	DINS, DINSM, DINSU,
	ROTR, ROTRV,
	DROTR, DROTRV, DROTR32,
	WSBH, DSBH, DSHD,
	SEB, SEH,

	// R2 misc
	RDHWR, RDPGPR, WRPGPR,
	DI, EI,
	ERET, DERET,
	WAIT,

	// -------------------------------------------------------------------------
	// MIPS32 R6 — compact branches and new mul/div
	// -------------------------------------------------------------------------

	// Compact (no delay slot)
	BC, BALC,                            // 26-bit
	BEQC, BNEC, BLTC, BGEC, BLTUC, BGEUC,
	BLEZC, BGEZC, BGTZC, BLTZC,
	BEQZC, BNEZC,
	BC1EQZ, BC1NEZ, BC2EQZ, BC2NEZ,
	JIC, JIALC,

	// R6 mul/div (replaces MULT/MULTU/DIV/DIVU; results in single GPR)
	MUH, MULU, MUHU, MOD, MODU,
	DMUL_R6, DMUH, DMULU, DMUHU,
	DDIV_R6, DMOD, DDIVU_R6, DMODU,

	// R6 PC-relative immediates
	AUI, AUIPC, ALUIPC, DAUI, DAHI, DATI,

	// R6 misc
	ALIGN, DALIGN,
	BITSWAP, DBITSWAP,
	LSA, DLSA,
	LWPC, LWUPC, LDPC,
	SELEQZ, SELNEZ,

	// R6 CRC32 (optional in MIPS32 R6)
	CRC32B, CRC32H, CRC32W, CRC32D,
	CRC32CB, CRC32CH, CRC32CW, CRC32CD,

	SIGRIE,    // signal reserved instruction exception

	// -------------------------------------------------------------------------
	// FPU (COP1) — moves between GPR/FPR/FCR
	// -------------------------------------------------------------------------

	MFC1, MTC1, DMFC1, DMTC1, CFC1, CTC1,
	MFHC1, MTHC1,                          // R2: high word of paired single

	LWC1, SWC1, LDC1, SDC1,

	// -------------------------------------------------------------------------
	// FPU arithmetic — .S (single), .D (double), .PS (paired single)
	// -------------------------------------------------------------------------

	ADD_S, ADD_D, ADD_PS,
	SUB_S, SUB_D, SUB_PS,
	MUL_S, MUL_D, MUL_PS,
	DIV_S, DIV_D,
	SQRT_S, SQRT_D,
	ABS_S, ABS_D, ABS_PS,
	NEG_S, NEG_D, NEG_PS,
	MOV_S, MOV_D, MOV_PS,
	RECIP_S, RECIP_D,
	RSQRT_S, RSQRT_D,

	// FMA family (MIPS IV+)
	MADD_S, MADD_D, MADD_PS,
	MSUB_S, MSUB_D, MSUB_PS,
	NMADD_S, NMADD_D, NMADD_PS,
	NMSUB_S, NMSUB_D, NMSUB_PS,

	// Conditional move (FPR by GPR / FCC)
	MOVN_S, MOVN_D, MOVN_PS,
	MOVZ_S, MOVZ_D, MOVZ_PS,
	MOVF_S, MOVF_D, MOVF_PS,
	MOVT_S, MOVT_D, MOVT_PS,

	// -------------------------------------------------------------------------
	// FPU conversions
	// -------------------------------------------------------------------------

	CVT_S_D, CVT_S_W, CVT_S_L,
	CVT_D_S, CVT_D_W, CVT_D_L,
	CVT_W_S, CVT_W_D,
	CVT_L_S, CVT_L_D,
	CVT_PS_S, CVT_S_PU, CVT_S_PL,
	PLL_PS, PLU_PS, PUL_PS, PUU_PS,

	// FPU round-to-fixed-point
	ROUND_W_S, ROUND_W_D, ROUND_L_S, ROUND_L_D,
	TRUNC_W_S, TRUNC_W_D, TRUNC_L_S, TRUNC_L_D,
	CEIL_W_S,  CEIL_W_D,  CEIL_L_S,  CEIL_L_D,
	FLOOR_W_S, FLOOR_W_D, FLOOR_L_S, FLOOR_L_D,

	// -------------------------------------------------------------------------
	// FPU compares — 16 conditions × 3 formats (.S, .D, .PS) = 48
	// -------------------------------------------------------------------------

	C_F_S,    C_F_D,    C_F_PS,
	C_UN_S,   C_UN_D,   C_UN_PS,
	C_EQ_S,   C_EQ_D,   C_EQ_PS,
	C_UEQ_S,  C_UEQ_D,  C_UEQ_PS,
	C_OLT_S,  C_OLT_D,  C_OLT_PS,
	C_ULT_S,  C_ULT_D,  C_ULT_PS,
	C_OLE_S,  C_OLE_D,  C_OLE_PS,
	C_ULE_S,  C_ULE_D,  C_ULE_PS,
	C_SF_S,   C_SF_D,   C_SF_PS,
	C_NGLE_S, C_NGLE_D, C_NGLE_PS,
	C_SEQ_S,  C_SEQ_D,  C_SEQ_PS,
	C_NGL_S,  C_NGL_D,  C_NGL_PS,
	C_LT_S,   C_LT_D,   C_LT_PS,
	C_NGE_S,  C_NGE_D,  C_NGE_PS,
	C_LE_S,   C_LE_D,   C_LE_PS,
	C_NGT_S,  C_NGT_D,  C_NGT_PS,

	// FPU branches
	BC1F, BC1T, BC1FL, BC1TL,

	// -------------------------------------------------------------------------
	// COP0 (system control)
	// -------------------------------------------------------------------------

	MFC0, MTC0, DMFC0, DMTC0,
	MFHC0, MTHC0,                  // R5+ high half of 64-bit registers
	TLBP, TLBR, TLBWI, TLBWR,
	CACHE,

	// -------------------------------------------------------------------------
	// PS1 GTE (COP2) — Geometry Transformation Engine
	// -------------------------------------------------------------------------

	// Standard COP2 moves (GTE registers via these)
	MFC2, MTC2, CFC2, CTC2, LWC2, SWC2,
	LDC2, SDC2,                    // LDC2/SDC2 exist on MIPS II+; PS1 R3000A does not implement

	// GTE ops (cofun-encoded, no GPR operands)
	RTPS, RTPT,
	DPCS, DPCT,
	INTPL,
	MVMVA,
	NCDS, NCDT,
	NCCS, NCCT,
	NCS,  NCT,
	CDP,  CC,
	NCLIP,
	AVSZ3, AVSZ4,
	OP_GTE,                         // "OP" (cross product) — disambiguated from MIPS R6 OP
	GPF, GPL,
	SQR_GTE,                        // "SQR" — disambiguated from generic
	DCPL,                           // depth-cue per light

	// -------------------------------------------------------------------------
	// PS2 EE — Multimedia Instructions (R5900 SPECIAL2 / MMI sub-spaces)
	// -------------------------------------------------------------------------

	// 128-bit GPR load/store
	LQ, SQ,

	// VU0 macro-mode 128-bit COP2 moves
	LQC2, SQC2,

	// Second HI/LO pair (R5900 dual MAC)
	MFHI1, MFLO1, MTHI1, MTLO1,
	MULT1, MULTU1, DIV1, DIVU1,
	MADD_EE, MADDU_EE, MSUB_EE, MSUBU_EE,
	MADD1, MADDU1, MSUB1, MSUBU1,

	// Packed pack/unpack HI:LO
	PMFHL_LW, PMFHL_UW, PMFHL_LH, PMFHL_SH, PMFHL_SLW,
	PMTHL_LW,

	// Parallel arithmetic (byte/halfword/word lanes)
	PADDB,  PADDH,  PADDW,
	PADDSB, PADDSH, PADDSW,
	PADDUB, PADDUH, PADDUW,
	PSUBB,  PSUBH,  PSUBW,
	PSUBSB, PSUBSH, PSUBSW,
	PSUBUB, PSUBUH, PSUBUW,

	// Parallel shifts
	PSLLH, PSRLH, PSRAH,
	PSLLW, PSRLW, PSRAW,
	PSLLVW, PSRLVW, PSRAVW,
	QFSRV,                          // quad funnel shift right (across 128 bits)

	// Parallel logical
	PAND, POR, PXOR, PNOR,

	// Parallel compare
	PCEQB, PCEQH, PCEQW,
	PCGTB, PCGTH, PCGTW,

	// Parallel multiply / divide
	PMULTW, PMULTUW, PMULTH,
	PMADDW, PMADDUW, PMADDH,
	PMSUBW, PMSUBH,
	PHMADH, PHMSBH,
	PDIVW, PDIVUW, PDIVBW,

	// Pack / rearrange
	PCPYLD, PCPYUD, PCPYH,
	PINTH, PINTOH,
	PEXEH, PEXEW,
	PEXCH, PEXCW,
	PROT3W,
	PPACB, PPACH, PPACW,
	PPAC5, PEXT5,
	PEXTLB, PEXTLH, PEXTLW,
	PEXTUB, PEXTUH, PEXTUW,

	// MMI HI/LO helpers
	PMFHI, PMFLO, PMTHI, PMTLO,

	// Misc MMI
	PLZCW, PABSH, PABSW,
	PMAXH, PMAXW, PMINH, PMINW,

	// Shift-amount register
	MFSA, MTSA, MTSAB, MTSAH,

	// -------------------------------------------------------------------------
	// MIPS DSP ASE (rev 1 + rev 2). 4-accumulator (ac0..ac3) packed-SIMD
	// operating on .QB (4×8-bit) and .PH (2×16-bit) lanes. Used heavily on
	// Ingenic XBurst, BCM/Atheros routers, and various 32-bit embedded MIPS.
	// -------------------------------------------------------------------------

	// Packed add/sub (saturating)
	ADDQ_PH, ADDQ_S_PH, ADDQ_S_W,
	SUBQ_PH, SUBQ_S_PH, SUBQ_S_W,
	ADDU_QB, ADDU_S_QB, ADDU_PH, ADDU_S_PH,
	SUBU_QB, SUBU_S_QB, SUBU_PH, SUBU_S_PH,
	ADDSC, ADDWC,                                    // 32-bit + carry/borrow

	// Packed multiply / dot-product / accumulate
	MULEU_S_PH_QBL, MULEU_S_PH_QBR,
	MULEQ_S_W_PHL,  MULEQ_S_W_PHR,
	MULQ_RS_PH, MULQ_S_PH,
	MULSAQ_S_W_PH,
	DPAQ_S_W_PH,  DPSQ_S_W_PH,
	DPAQ_SA_L_W,  DPSQ_SA_L_W,
	DPAU_H_QBL,   DPAU_H_QBR,
	DPSU_H_QBL,   DPSU_H_QBR,
	DPA_W_PH,     DPS_W_PH,                          // R2
	DPAX_W_PH,    DPSX_W_PH,                         // R2
	MAQ_S_W_PHL,  MAQ_S_W_PHR,
	MAQ_SA_W_PHL, MAQ_SA_W_PHR,

	// Extract / position / accumulator helpers
	EXTR_W, EXTR_R_W, EXTR_RS_W, EXTR_S_H,
	EXTRV_W, EXTRV_R_W, EXTRV_RS_W, EXTRV_S_H,
	EXTP, EXTPV, EXTPDP, EXTPDPV,
	SHILO, SHILOV,
	MTHLIP,
	WRDSP, RDDSP,

	// Pack / unpack
	PRECRQ_QB_PH,  PRECRQ_PH_W,
	PRECRQU_S_QB_PH,
	PRECEQ_W_PHL,  PRECEQ_W_PHR,
	PRECEQU_PH_QBL, PRECEQU_PH_QBR,
	PRECEQU_PH_QBLA, PRECEQU_PH_QBRA,
	PRECEU_PH_QBL,  PRECEU_PH_QBR,
	PRECEU_PH_QBLA, PRECEU_PH_QBRA,
	PRECRQ_RS_PH_W,

	// Compare / pick
	CMPU_EQ_QB, CMPU_LT_QB, CMPU_LE_QB,
	CMP_EQ_PH,  CMP_LT_PH,  CMP_LE_PH,
	CMPGU_EQ_QB, CMPGU_LT_QB, CMPGU_LE_QB,
	PICK_QB, PICK_PH,

	// Shift
	SHLL_QB,  SHLL_PH,  SHLL_S_PH,  SHLL_S_W,
	SHLLV_QB, SHLLV_PH, SHLLV_S_PH, SHLLV_S_W,
	SHRL_QB,  SHRL_PH,
	SHRLV_QB, SHRLV_PH,
	SHRA_QB,  SHRA_R_QB, SHRA_PH, SHRA_R_PH, SHRA_R_W,
	SHRAV_QB, SHRAV_R_QB, SHRAV_PH, SHRAV_R_PH, SHRAV_R_W,

	// Indexed loads (rs+rt addressing) — register-register addressing.
	LBUX, LHX, LWX,

	// DSP control / branch
	BPOSGE32,                  // branch if DSPControl.pos >= 32
	BPOSGE64,                  // 64-bit variant (only MIPS64 DSP)
	INSV,                      // insert variable position
	BITREV,                    // R2 bit reversal
	ABSQ_S_PH, ABSQ_S_W,
	REPL_PH, REPLV_PH,
	REPL_QB, REPLV_QB,

	// -------------------------------------------------------------------------
	// MIPS SIMD Architecture (MSA). Modern MIPS32/64 R5+ optional extension
	// with 32× 128-bit vector registers ($w0..$w31). 4-byte instructions in
	// opcode space 0x1E (CONFLICTS WITH PS2 LQ on R5900 — consumers
	// disambiguate by target ISA).
	// -------------------------------------------------------------------------

	// Vector register-register integer arithmetic (.B/.H/.W/.D lane width)
	ADDV_B, ADDV_H, ADDV_W, ADDV_D,
	SUBV_B, SUBV_H, SUBV_W, SUBV_D,
	ADDS_S_B, ADDS_S_H, ADDS_S_W, ADDS_S_D,
	ADDS_U_B, ADDS_U_H, ADDS_U_W, ADDS_U_D,
	SUBS_S_B, SUBS_S_H, SUBS_S_W, SUBS_S_D,
	SUBS_U_B, SUBS_U_H, SUBS_U_W, SUBS_U_D,
	MULV_B,  MULV_H,  MULV_W,  MULV_D,
	DIV_S_B, DIV_S_H, DIV_S_W, DIV_S_D,
	DIV_U_B, DIV_U_H, DIV_U_W, DIV_U_D,
	MOD_S_B, MOD_S_H, MOD_S_W, MOD_S_D,
	MOD_U_B, MOD_U_H, MOD_U_W, MOD_U_D,
	MADDV_B, MADDV_H, MADDV_W, MADDV_D,
	MSUBV_B, MSUBV_H, MSUBV_W, MSUBV_D,
	DOTP_S_H, DOTP_S_W, DOTP_S_D,
	DOTP_U_H, DOTP_U_W, DOTP_U_D,

	// Vector logical
	AND_V, OR_V, NOR_V, XOR_V,
	ANDI_B, ORI_B, NORI_B, XORI_B,
	BSEL_V, BSELI_B,
	BMNZ_V, BMNZI_B, BMZ_V, BMZI_B,

	// Vector compare
	CEQ_B, CEQ_H, CEQ_W, CEQ_D,
	CLT_S_B, CLT_S_H, CLT_S_W, CLT_S_D,
	CLT_U_B, CLT_U_H, CLT_U_W, CLT_U_D,
	CLE_S_B, CLE_S_H, CLE_S_W, CLE_S_D,
	CLE_U_B, CLE_U_H, CLE_U_W, CLE_U_D,

	// Vector min/max
	MIN_S_B, MIN_S_H, MIN_S_W, MIN_S_D,
	MIN_U_B, MIN_U_H, MIN_U_W, MIN_U_D,
	MAX_S_B, MAX_S_H, MAX_S_W, MAX_S_D,
	MAX_U_B, MAX_U_H, MAX_U_W, MAX_U_D,

	// Vector shifts
	SLL_B, SLL_H, SLL_W, SLL_D,
	SRL_B, SRL_H, SRL_W, SRL_D,
	SRA_B, SRA_H, SRA_W, SRA_D,
	SLLI_B, SLLI_H, SLLI_W, SLLI_D,
	SRLI_B, SRLI_H, SRLI_W, SRLI_D,
	SRAI_B, SRAI_H, SRAI_W, SRAI_D,

	// Vector FP arithmetic
	FADD_W, FADD_D, FSUB_W, FSUB_D,
	FMUL_W, FMUL_D, FDIV_W, FDIV_D,
	FSQRT_W, FSQRT_D, FRSQRT_W, FRSQRT_D,
	FRCP_W, FRCP_D, FRINT_W, FRINT_D,
	FMAX_W, FMAX_D, FMIN_W, FMIN_D,
	FCEQ_W, FCEQ_D, FCNE_W, FCNE_D,
	FCLT_W, FCLT_D, FCLE_W, FCLE_D,

	// Vector conversion
	FFINT_S_W, FFINT_S_D, FFINT_U_W, FFINT_U_D,
	FTRUNC_S_W, FTRUNC_S_D, FTRUNC_U_W, FTRUNC_U_D,
	FCVT_S_W, FCVT_S_D, FCVT_D_W,

	// Vector load/store + immediate
	LD_B, LD_H, LD_W, LD_D,
	ST_B, ST_H, ST_W, ST_D,
	LDI_B, LDI_H, LDI_W, LDI_D,

	// Vector shuffle / copy / insert
	COPY_S_B, COPY_S_H, COPY_S_W,
	COPY_U_B, COPY_U_H, COPY_U_W,
	INSERT_B, INSERT_H, INSERT_W, INSERT_D,
	INSVE_B, INSVE_H, INSVE_W, INSVE_D,
	SHF_B, SHF_H, SHF_W,
	VSHF_B, VSHF_H, VSHF_W, VSHF_D,
	SLD_B, SLD_H, SLD_W, SLD_D,
	SLDI_B, SLDI_H, SLDI_W, SLDI_D,
	SPLAT_B, SPLAT_H, SPLAT_W, SPLAT_D,
	SPLATI_B, SPLATI_H, SPLATI_W, SPLATI_D,

	// MSA branches (vector all-zero / any-non-zero across all lanes / per-lane)
	BZ_V, BNZ_V,
	BZ_B, BZ_H, BZ_W, BZ_D,
	BNZ_B, BNZ_H, BNZ_W, BNZ_D,

	// Element-permute / count / bit-ops
	NLOC_B, NLOC_H, NLOC_W, NLOC_D,
	NLZC_B, NLZC_H, NLZC_W, NLZC_D,
	PCNT_B, PCNT_H, PCNT_W, PCNT_D,

	// -------------------------------------------------------------------------
	// PSP Allegrex VFPU (Vector FPU) — major families
	// -------------------------------------------------------------------------
	//
	// VFPU operates on 128 32-bit registers organised as 8 matrices of 4x4.
	// Each instruction has a suffix .s / .p / .t / .q for scalar / pair /
	// triple / quad lane width. This enum names the major mnemonics; the
	// ENCODING_TABLE has stubs to be filled in as the project needs them.

	// Move / load / store / immediates
	VMOV_S, VMOV_P, VMOV_T, VMOV_Q,
	LV_S, LV_Q,
	SV_S, SV_Q,
	LVL_Q, LVR_Q,
	SVL_Q, SVR_Q,
	VIIM_S, VFIM_S,

	// Arithmetic
	VADD_S, VADD_P, VADD_T, VADD_Q,
	VSUB_S, VSUB_P, VSUB_T, VSUB_Q,
	VMUL_S, VMUL_P, VMUL_T, VMUL_Q,
	VDIV_S, VDIV_P, VDIV_T, VDIV_Q,
	VABS_S, VABS_P, VABS_T, VABS_Q,
	VNEG_S, VNEG_P, VNEG_T, VNEG_Q,
	VSQRT_S,
	VRCP_S, VRCP_P, VRCP_T, VRCP_Q,
	VRSQ_S, VRSQ_P, VRSQ_T, VRSQ_Q,

	// Reductions / dot / scale
	VDOT_P, VDOT_T, VDOT_Q,
	VSCL_P, VSCL_T, VSCL_Q,
	VHDP_P, VHDP_T, VHDP_Q,
	VAVG_P, VAVG_T, VAVG_Q,
	VFAD_P, VFAD_T, VFAD_Q,

	// Matrix ops
	VMMUL_P, VMMUL_T, VMMUL_Q,
	VTFM2_P, VTFM3_T, VTFM4_Q,
	VHTFM2_P, VHTFM3_T, VHTFM4_Q,
	VMSCL_P, VMSCL_T, VMSCL_Q,
	VMMOV_P, VMMOV_T, VMMOV_Q,
	VMIDT_P, VMIDT_T, VMIDT_Q,
	VMZERO_P, VMZERO_T, VMZERO_Q,
	VMONE_P, VMONE_T, VMONE_Q,

	// Cross / quaternion
	VCRS_T, VCRSP_T,
	VQMUL_Q,

	// Compares & sel
	VCMP_S, VCMP_P, VCMP_T, VCMP_Q,
	VMIN_S, VMIN_P, VMIN_T, VMIN_Q,
	VMAX_S, VMAX_P, VMAX_T, VMAX_Q,

	// Transcendentals
	VSIN_S, VCOS_S, VEXP2_S, VLOG2_S,
	VASIN_S, VNRCP_S, VNSIN_S, VREXP2_S,
	VSGN_S,

	// Conversion
	VI2F_S, VI2F_P, VI2F_T, VI2F_Q,
	VF2IN_S, VF2IN_P, VF2IN_T, VF2IN_Q,
	VF2IZ_S, VF2IZ_P, VF2IZ_T, VF2IZ_Q,
	VF2IU_S, VF2IU_P, VF2IU_T, VF2IU_Q,
	VF2ID_S, VF2ID_P, VF2ID_T, VF2ID_Q,
	VF2H_P, VH2F_S,

	// Control / move-between
	VFLUSH, VSYNC, VNOP,
	VPFXS, VPFXT, VPFXD,
	VCST_S, VCST_P, VCST_T, VCST_Q,
	MFV, MTV, MFVC, MTVC,
	BVF, BVT, BVFL, BVTL,
}
