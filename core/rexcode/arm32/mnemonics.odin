package rexcode_arm32

// =============================================================================
// AArch32 MNEMONICS (ARMv4-ARMv8 AArch32 + Thumb-1/Thumb-2 + VFP + NEON)
// =============================================================================
//
// Single Mnemonic enum shared between A32 (32-bit ARM) and T32 (Thumb). Each
// entry in ENCODING_TABLE carries a Mode tag (A32 vs T32) so the same mnemonic
// can have multiple encodings (one per mode, sometimes more for different
// operand-shape variants).
//
// Mnemonic naming convention:
//   * No size/condition suffix in the enum name -- conditions are runtime
//     parameters (cond field, 4 bits) and sizes are operand-derived.
//   * Variant suffixes describe operand shape, not condition:
//       _IMM = immediate operand
//       _REG = pure register form
//       _RSR = register-shifted-register
//       _LSL/_LSR/_ASR/_ROR/_RRX = immediate shift type
//       _D    = 64-bit double-register form (LDRD/STRD/VFPv2 D-reg)
//       _F32/_F64/_F16 = VFP float width
//       _I8/_I16/_I32/_I64 = NEON integer element width
//       _S8/_S16/_S32/_S64 = NEON signed integer
//       _U8/_U16/_U32/_U64 = NEON unsigned integer
//       _P8/_P64           = NEON polynomial (for VMULL etc.)
//
// We use the canonical UAL spelling so the printer can reconstruct
// assembly-style output (`VADD.F32 D0, D1, D2`) by combining mnemonic +
// data-type suffix from the entry's operand kinds.

Mnemonic :: enum u16 {
	INVALID = 0,

	// -------------------------------------------------------------------------
	// Data processing -- core 16 ops (A32 + T32)
	// -------------------------------------------------------------------------
	AND,  EOR,  SUB,  RSB,  ADD,  ADC,  SBC,  RSC,
	TST,  TEQ,  CMP,  CMN,  ORR,  MOV,  BIC,  MVN,

	// Shift mnemonics (in A32 these are MOV aliases with shift, but in Thumb
	// they are first-class encodings, so they have their own Mnemonic entries)
	LSL,  LSR,  ASR,  ROR,  RRX,

	// Thumb-1 specific: ADR is an alias for ADD Rd, PC, #imm  (also exists in
	// A32 as an ADD/SUB imm to PC alias)
	ADR,
	NEG,                                   // Thumb-1 only: NEG Rd, Rm = RSB Rd, Rm, #0

	// ARMv6T2: 16-bit immediate moves
	MOVW,                                  // MOV with 16-bit immediate (low half)
	MOVT,                                  // MOV-Top (high half, preserves low)

	// ARMv6T2: bit field manipulation
	BFC,   BFI,   SBFX,  UBFX,

	// ARMv6: register operand sign/zero extends with optional rotation
	SXTB,  SXTB16, SXTH, UXTB, UXTB16, UXTH,
	SXTAB, SXTAB16, SXTAH, UXTAB, UXTAB16, UXTAH,

	// ARMv6: bit reverse / byte swap / count leading zeros
	CLZ,   RBIT,  REV,   REV16, REVSH,
	SEL,                                   // select bytes per APSR.GE flags

	// ARMv6T2/v7: PKHBT/PKHTB (pack halfword)
	PKHBT, PKHTB,

	// ARMv6: USAD8 (sum of absolute differences)
	USAD8, USADA8,

	// ARMv6: saturating arithmetic
	SSAT,  USAT,  SSAT16, USAT16,
	QADD,  QSUB,  QDADD,  QDSUB,

	// ARMv6: SIMD on GPRs (8/16-bit lanes packed in 32-bit reg)
	SADD8,  SADD16,  SASX,  SSAX,  SSUB8,  SSUB16,
	UADD8,  UADD16,  UASX,  USAX,  USUB8,  USUB16,
	QADD8,  QADD16,  QASX,  QSAX,  QSUB8,  QSUB16,
	UQADD8, UQADD16, UQASX, UQSAX, UQSUB8, UQSUB16,
	SHADD8, SHADD16, SHASX, SHSAX, SHSUB8, SHSUB16,
	UHADD8, UHADD16, UHASX, UHSAX, UHSUB8, UHSUB16,

	// ARMv6: dual multiply-accumulate
	SMUAD,  SMUADX,  SMUSD,  SMUSDX,
	SMLAD,  SMLADX,  SMLSD,  SMLSDX,
	SMLALD, SMLALDX, SMLSLD, SMLSLDX,

	// Most-significant-word multiply
	SMMUL,  SMMULR, SMMLA, SMMLAR, SMMLS, SMMLSR,

	// Multiply / multiply-accumulate (ARMv4+ core)
	MUL,    MLA,
	MLS,                                   // ARMv6T2: multiply-subtract
	UMULL,  UMLAL, SMULL, SMLAL,
	UMAAL,                                 // ARMv6: unsigned long multiply-acc-acc

	// Halfword multiply (ARMv5TE / ARMv6 DSP):
	//   SMLA{x}{y}, SMLAW{y}, SMUL{x}{y}, SMULW{y}, SMLAL{x}{y}
	SMLABB, SMLABT, SMLATB, SMLATT,
	SMLAWB, SMLAWT,
	SMULBB, SMULBT, SMULTB, SMULTT,
	SMULWB, SMULWT,
	SMLALBB, SMLALBT, SMLALTB, SMLALTT,

	// Integer division (ARMv7-A optional, ARMv7-R/M mandatory; v7VE adds A-profile)
	SDIV,  UDIV,

	// -------------------------------------------------------------------------
	// Branches
	// -------------------------------------------------------------------------
	B,                                     // signed 24/26-bit branch
	BL,                                    // branch + link
	BX,                                    // branch and exchange (to ARM/Thumb)
	BLX,                                   // branch+link+exchange (reg or imm)
	BXJ,                                   // branch and exchange to Jazelle (deprecated)

	// ARMv6T2+: compare and branch (Thumb-only)
	CBZ,   CBNZ,

	// ARMv6T2+: table branch (Thumb-only)
	TBB,   TBH,

	// -------------------------------------------------------------------------
	// Status register access / hint instructions
	// -------------------------------------------------------------------------
	MSR,   MRS,
	CPS,                                   // change processor state
	SETEND,                                // set endianness (deprecated in v8)

	NOP,    YIELD,   WFE,    WFI,    SEV,
	SEVL,                                  // ARMv8: sev local
	DBG,    HINT,                          // generic hint with imm

	DMB,    DSB,     ISB,                  // ARMv7 barriers
	CLREX,                                 // clear exclusive monitor
	PLD,    PLDW,    PLI,                  // preload

	// ARMv8 AArch32 additions
	HLT,                                   // halt instruction (debug)
	DCPS1,  DCPS2,   DCPS3,                // debug change processor state
	ERET,                                  // exception return (PL2+)

	// ARMv8 security/profiling/trace barriers (FEAT_RAS, FEAT_SB, FEAT_SPE, FEAT_TRF)
	ESB,                                   // error synchronization barrier (HINT #16)
	PSB_CSYNC,                             // profile sync barrier (HINT #17)
	TSB_CSYNC,                             // trace sync barrier (HINT #18)
	CSDB,                                  // consumption of speculative data barrier (HINT #20)
	SB,                                    // synchronization barrier (ARMv8.5, dedicated encoding)

	// ARMv8.1 PAN (Privileged Access Never) bit toggle
	SETPAN,

	// -------------------------------------------------------------------------
	// Exception generation
	// -------------------------------------------------------------------------
	SVC,                                   // supervisor call (was SWI)
	BKPT,                                  // breakpoint
	HVC,                                   // hypervisor call (ARMv7VE)
	SMC,                                   // secure monitor call (TrustZone)
	UDF,                                   // permanently undefined

	// -------------------------------------------------------------------------
	// Load / Store
	// -------------------------------------------------------------------------
	LDR,    STR,                           // word
	LDRB,   STRB,                          // byte
	LDRH,   STRH,                          // halfword
	LDRSB,  LDRSH,                         // signed loads
	LDRD,   STRD,                          // doubleword (Rt/Rt+1 pair)

	LDRT,   STRT,                          // user-mode (privileged-mode pretend)
	LDRBT,  STRBT,
	LDRHT,  STRHT,
	LDRSBT, LDRSHT,

	// ARMv6+ acquire/release
	LDA,    STL,                           // word acquire/release
	LDAB,   STLB,                          // byte
	LDAH,   STLH,                          // halfword

	// ARMv6 exclusive load/store
	LDREX,  STREX,
	LDREXB, STREXB,
	LDREXH, STREXH,
	LDREXD, STREXD,
	LDAEX,  STLEX,                         // ARMv8 acquire/release exclusive
	LDAEXB, STLEXB,
	LDAEXH, STLEXH,
	LDAEXD, STLEXD,

	// Block move
	LDM,    STM,                           // base mnemonic w/ IA/IB/DA/DB suffix flag

	// Stack convenience aliases
	PUSH,   POP,

	// Swap (deprecated since ARMv6 but still encoded)
	SWP,    SWPB,

	// -------------------------------------------------------------------------
	// ARMv6 / Return-from-Exception
	// -------------------------------------------------------------------------
	RFE,                                   // return from exception
	SRS,                                   // store return state

	// -------------------------------------------------------------------------
	// Coprocessor (legacy CP-space; many subsumed by VFP/NEON)
	// -------------------------------------------------------------------------
	CDP,    CDP2,
	MCR,    MCR2,    MRC,    MRC2,
	MCRR,   MCRR2,   MRRC,   MRRC2,
	LDC,    LDC2,    STC,    STC2,

	// -------------------------------------------------------------------------
	// ARMv8 AArch32 CRC32 (FEAT_CRC32)
	// -------------------------------------------------------------------------
	CRC32B,  CRC32H,  CRC32W,
	CRC32CB, CRC32CH, CRC32CW,

	// -------------------------------------------------------------------------
	// VFP / Advanced SIMD shared opcodes
	// -------------------------------------------------------------------------
	// -- Scalar FP arithmetic (operates on S<n>, D<n>) -------------------------
	VADD,   VSUB,   VMUL,   VDIV,
	VMLA,   VMLS,   VNMUL,  VNMLA,  VNMLS,
	VFMA,   VFMS,   VFNMA,  VFNMS,

	VABS,   VNEG,   VSQRT,
	VCMP,   VCMPE,
	VCVT,                                  // cross-format conversion (encoded via cmode bits)
	VCVTB,  VCVTT,                         // half-precision conversion (bottom/top lane)
	VCVTA,  VCVTN,  VCVTP,  VCVTM,         // ARMv8: rounding-mode FP-to-int
	VCVTR,                                 // FP-to-int using FPSCR rounding

	VMOV,                                  // many forms (reg-reg, reg-imm, GPR-FPR)
	VMRS,   VMSR,                          // FPSCR/coprocessor access
	VLDR,   VSTR,
	VLDM,   VSTM,
	VPUSH,  VPOP,

	VSEL,                                  // ARMv8 conditional select
	VMAXNM, VMINNM,                        // ARMv8 IEEE 754-2008 min/max
	VRINTA, VRINTN, VRINTP, VRINTM,        // ARMv8 round-to-int by mode
	VRINTR, VRINTZ, VRINTX,                // round to int per current/zero/exact

	// -- NEON-specific (vector D/Q reg) -----------------------------------------
	VADDL,  VADDW,  VSUBL,  VSUBW,
	VHADD,  VHSUB,  VRHADD,
	VQADD,  VQSUB,
	VMULL,  VMLAL,  VMLSL,
	VQDMULL,VQDMLAL,VQDMLSL,
	VQDMULH,VQRDMULH,
	VQDMULH_LANE, VQRDMULH_LANE,           // indexed variants

	// ARMv8.1 FEAT_RDM: rounding doubling multiply-accumulate
	VQRDMLAH, VQRDMLSH,

	VABA,   VABAL,
	VABD,   VABDL,

	VAND,   VBIC,   VORR,   VORN,   VEOR,
	VBSL,   VBIT,   VBIF,
	VMVN,
	VMOVN,  VQMOVN, VQMOVUN,
	VMOVL,                                 // extend halve-width to full-width
	VTST,
	VCEQ,   VCGE,   VCGT,   VCLE,   VCLT,
	VACGE,  VACGT,                         // absolute compare for FP
	VACLE,  VACLT,

	VMAX,   VMIN,
	VPMAX,  VPMIN,
	VPADD,  VPADDL, VPADAL,

	VRECPE, VRECPS,                        // reciprocal estimate / step
	VRSQRTE,VRSQRTS,

	VSHL,   VSHR,   VSRA,   VRSHL,  VRSHR, VRSRA,
	VSLI,   VSRI,
	VQSHL,  VQSHRN, VQSHRUN,
	VQRSHL, VQRSHRN, VQRSHRUN,
	VSHRN,  VRSHRN,
	VSHLL,                                 // shift-left long

	VCLS,   VCLZ,   VCNT,
	VPADD_F, VRECPE_F, VRSQRTE_F,          // (placeholders; canonical via operand types)

	VREV16, VREV32, VREV64,
	VEXT,                                  // vector extract
	VTBL,   VTBX,                          // table lookup
	VTRN,   VUZP,   VZIP,
	VDUP,                                  // duplicate scalar to vector
	VSWP,                                  // swap

	// Lane access
	VMOV_LANE,                             // VMOV.<dt> R, D[i] / VMOV.<dt> D[i], R

	// Load/Store structures (NEON)
	VLD1, VLD2, VLD3, VLD4,
	VST1, VST2, VST3, VST4,

	// -- Advanced SIMD / NEON crypto (ARMv8 AArch32 FEAT_AES + FEAT_SHA1/2) ---
	AESE,    AESD,    AESMC,   AESIMC,
	SHA1H,   SHA1SU0, SHA1SU1, SHA1C,    SHA1M,    SHA1P,
	SHA256H, SHA256H2, SHA256SU0, SHA256SU1,

	// -- VFP rounding (ARMv8 FEAT_FP) ----------------------------------------
	VRINT,   VJCVT,                        // VJCVT: F64-to-S32 with FPSCR.RM rounding

	// -- Dot Product (FEAT_DotProd) ------------------------------------------
	VSDOT,   VUDOT,
	VSDOT_LANE, VUDOT_LANE,

	// -- BF16 (FEAT_BF16) ----------------------------------------------------
	VCVT_BF16,                             // BF16<->F32
	VDOT_BF16,
	VFMA_BF16,
	VMMLA_BF16,

	// -- FHM (FEAT_FHM) FP16 matrix mul/acc ----------------------------------
	VFMAL,   VFMSL,                        // F16 fused multiply-add long

	// -- ComplexNum (FEAT_FCMA) ----------------------------------------------
	VCMLA,   VCADD,
	VCMLA_LANE,                            // VCMLA by indexed scalar

	// -- I8MM (FEAT_I8MM, ARMv8.6) integer matrix multiply + mixed-sign dot --
	VSMMLA,                                // signed-signed 8x8 matrix mul
	VUMMLA,                                // unsigned-unsigned
	VUSMMLA,                               // unsigned-signed
	VSUDOT,                                // signed-unsigned dot product
	VUSDOT,                                // unsigned-signed dot product
	VSUDOT_LANE,
	VUSDOT_LANE,

	// -- Lane-indexed NEON multiply / MAC forms (heavily used in DSP/codec) --
	VMUL_LANE,   VMLA_LANE,   VMLS_LANE,
	VMULL_LANE,  VMLAL_LANE,  VMLSL_LANE,
	VQDMULL_LANE, VQDMLAL_LANE, VQDMLSL_LANE,
	VFMA_LANE,   VFMS_LANE,
	VQRDMLAH_LANE, VQRDMLSH_LANE,

	// -- MVE saturating unary -----------------------------------------------
	VQABS,    VQNEG,

	// -- MVE FP lane manipulation (F16 packing) -----------------------------
	VMOVX,                                 // extract high F16 lane from S-reg
	VINS,                                  // insert F16 into high lane of S-reg

	// -- MVE gather/scatter (vector offset addressing) ----------------------
	VLDRB_GATHER, VLDRH_GATHER, VLDRW_GATHER, VLDRD_GATHER,
	VSTRB_SCATTER, VSTRH_SCATTER, VSTRW_SCATTER, VSTRD_SCATTER,

	// -- NEON compare-with-zero (distinct encodings from reg-vs-reg) --------
	VCEQ_Z,    VCGE_Z,    VCGT_Z,    VCLE_Z,    VCLT_Z,

	// -- NEON replicate loads (broadcast one element to all lanes) ----------
	//    VLD1R already covered in VLD1; these are the 2/3/4 variants.
	VLD2R,    VLD3R,    VLD4R,

	// -- NEON single-element-lane load/store (lane form, not multi-vec) -----
	VLD1_LANE, VLD2_LANE, VLD3_LANE, VLD4_LANE,
	VST1_LANE, VST2_LANE, VST3_LANE, VST4_LANE,

	// -- VFP fixed-point conversions (with #fbits operand) ------------------
	VCVT_FIXED,                            // VCVT.<dt> Sd, Sd, #fbits family

	// -------------------------------------------------------------------------
	// Thumb-only mnemonics (extra ones not shared with A32)
	// -------------------------------------------------------------------------
	IT,                                    // if-then block (Thumb-2)

	// ARMv6: change endianness in Thumb
	// SETEND already covers both A32 and T32

	// -------------------------------------------------------------------------
	// ARMv8-M Security Extensions (TrustZone-M)
	// -------------------------------------------------------------------------
	TT,                                    // test target
	TTT,                                   // test target unprivileged
	TTA,                                   // test target alternate domain
	TTAT,                                  // test target alternate domain unprivileged
	SG,                                    // secure gateway (enter secure state)
	BXNS,                                  // branch and exchange non-secure
	BLXNS,                                 // branch with link and exchange non-secure

	// -------------------------------------------------------------------------
	// PACBTI for ARMv8.1-M (Cortex-M85)
	// -------------------------------------------------------------------------
	PAC,                                   // PAC R12, LR, SP
	PACBTI,                                // PACBTI R12, LR, SP (combined PAC + BTI marker)
	AUT,                                   // AUT R12, LR, SP
	AUTG,                                  // AUTG Rd, Rn, Rm (general form)
	BTI,                                   // M-profile branch target identification

	// -------------------------------------------------------------------------
	// ARMv8.1-M low-overhead loops (Helium prerequisite, but useful even without MVE)
	// -------------------------------------------------------------------------
	WLS,                                   // while loop start
	WLSTP,                                 // while loop start with tail predication
	DLS,                                   // do loop start
	DLSTP,                                 // do loop start with tail predication
	LE,                                    // loop end
	LETP,                                  // loop end with tail predication
	LCTP,                                  // loop clear tail predication

	BF,                                    // branch future (ARMv8.1-M)
	BFI_BR,                                // branch future indirect
	BFL,                                   // branch future and link
	BFLX,                                  // branch future link and exchange
	BFCSEL,                                // branch future conditional select

	// -------------------------------------------------------------------------
	// Custom Datapath Extension (CDE)
	// -------------------------------------------------------------------------
	CX1,    CX1A,                          // dual-coprocessor + GPR dest (32-bit)
	CX1D,   CX1DA,                         // 64-bit GPR pair dest
	CX2,    CX2A,                          // + Rn input
	CX2D,   CX2DA,
	CX3,    CX3A,                          // + two Rn inputs
	CX3D,   CX3DA,
	VCX1,   VCX1A,                         // VFP S/D-reg dest
	VCX2,   VCX2A,
	VCX3,   VCX3A,

	// -------------------------------------------------------------------------
	// MVE (Helium / M-profile Vector Extension) -- ARMv8.1-M
	// -------------------------------------------------------------------------
	//
	// Note: many MVE ops share mnemonics with NEON (VADD/VSUB/VMUL/VAND/etc).
	// Distinct MVE-only mnemonics are below. Shared ones get additional
	// MVE-mode entries in ENCODING_TABLE.

	// Predication block (then/else interleaved)
	VPT,                                   // predicate-then block
	VPST,                                  // predicate-then-set block (single)
	VPSEL,                                 // predicate select (per-element)
	VPNOT,                                 // invert VPR
	VCTP,                                  // create tail predicate (.8/.16/.32/.64)

	// Reductions (single-vector accumulate)
	VADDV,    VADDVA,                      // accumulate sum across vector (signed/unsigned, +acc)
	VADDLV,   VADDLVA,                     // long version (S64 accumulator)
	VMAXV,    VMAXAV,                      // max (and absolute)
	VMINV,    VMINAV,
	VMAXNMV,  VMAXNMAV,                    // FP max-num
	VMINNMV,  VMINNMAV,

	// Dual MAC reductions (multiply-accumulate then sum)
	VABAV,                                 // accumulate absolute difference
	VMLADAV,  VMLADAVA,  VMLADAVX, VMLADAVAX,
	VMLALDAV, VMLALDAVA, VMLALDAVX, VMLALDAVAX,
	VMLSDAV,  VMLSDAVA,  VMLSDAVX, VMLSDAVAX,
	VMLSLDAV, VMLSLDAVA, VMLSLDAVX, VMLSLDAVAX,
	VRMLALDAVH, VRMLALDAVHA, VRMLALDAVHX, VRMLALDAVHAX,
	VRMLSLDAVH, VRMLSLDAVHA, VRMLSLDAVHX, VRMLSLDAVHAX,
	VMLAV,    VMLAVA,                      // simple MAC across vector
	VMLSV,    VMLSVA,

	// Complex arithmetic (Q-register vector form)
	VCMUL,                                 // complex multiply (separate from VCMLA)
	VHCADD,                                // halving complex add

	// Bit reverse + shifts unique to MVE
	VBRSR,                                 // bit reverse with shift right
	VSHLC,                                 // shift left with carry
	VRSHL_MVE,                             // (placeholder if needed; usually VRSHL)
	VDDUP,                                 // decrement and duplicate
	VIDUP,                                 // increment and duplicate
	VDWDUP,                                // decrement-wrap and duplicate
	VIWDUP,                                // increment-wrap and duplicate

	// Narrowing with B/T (bottom/top)
	VMOVNB,    VMOVNT,                     // narrow bottom/top
	VQMOVNB,   VQMOVNT,                    // saturating narrow B/T
	VQMOVUNB,  VQMOVUNT,                   // saturating-unsigned narrow B/T

	// Widening with B/T
	VSHLLB,    VSHLLT,                     // shift left long bottom/top
	VMULLB,    VMULLT,                     // multiply long B/T
	VMLALB,    VMLALT,                     // multiply-accumulate long B/T
	VMLSLB,    VMLSLT,

	VSHRNB,    VSHRNT,                     // shift right narrow B/T
	VRSHRNB,   VRSHRNT,
	VQSHRNB,   VQSHRNT,
	VQRSHRNB,  VQRSHRNT,
	VQSHRUNB,  VQSHRUNT,
	VQRSHRUNB, VQRSHRUNT,

	// Move between Qd-lane and GPR (MVE-specific 4-element split forms)
	VMOV_Q_R,                              // VMOV Qd[i], Rt  -- single lane to GPR
	VMOV_R_Q,                              // VMOV Rt, Qd[i]
	VMOV_2GPR_Q,                           // VMOV Qd[2*i], Qd[2*i+1], Rt, Rt2 -- pair

	// Saturating doubling MAC reductions
	VQDMLADH,   VQDMLADHX,
	VQDMLSDH,   VQDMLSDHX,
	VQRDMLADH,  VQRDMLADHX,
	VQRDMLSDH,  VQRDMLSDHX,

	// Misc
	VPRINT,                                // printf-like debug op (rare)
	VHCADD_SAT,                            // (rarely used)
	VCMLA_MVE,                             // (MVE form; VCMLA already exists)

	// MVE load/store (mostly reuses VLDR/VSTR but distinct forms exist):
	VLDRB,   VLDRH,   VLDRW,   VLDRD,      // MVE contiguous load (B/H/W/D)
	VSTRB,   VSTRH,   VSTRW,   VSTRD,      // MVE contiguous store
	VLD20,   VLD21,                        // 2-vector interleaved (halves)
	VLD40,   VLD41,   VLD42,   VLD43,      // 4-vector interleaved (quarters)
	VST20,   VST21,
	VST40,   VST41,   VST42,   VST43,

	// -------------------------------------------------------------------------
	// Sentinel
	// -------------------------------------------------------------------------
	_COUNT,
}
