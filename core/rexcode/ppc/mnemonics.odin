package rexcode_ppc

// =============================================================================
// PowerPC MNEMONICS
// =============================================================================
//
// One entry per assembler mnemonic. Variants that share a mnemonic but
// differ in encoding (Rc-bit, OE-bit, mode, size) live as multiple
// Encodings under the same mnemonic key in ENCODING_TABLE.
//
// PPC convention adds suffixes ".", "o", "a", "l", "ctr", "lr" to many
// mnemonics. We keep those as separate enum members where the disassembler
// must distinguish (e.g. ADD vs ADD_O vs ADD_DOT vs ADD_O_DOT) so the
// printer can recover the right textual form. The aliases (mr/li/nop/etc.)
// are also separate mnemonics that map to the underlying encoding for
// printing convenience.

Mnemonic :: enum u16 {
	INVALID = 0,

	// -------------------------------------------------------------------------
	// §1 Branch (I/B/XL-form)
	// -------------------------------------------------------------------------
	B,         BL,         BA,         BLA,
	BC,        BCL,        BCA,        BCLA,
	BCLR,      BCLRL,
	BCCTR,     BCCTRL,
	BCTAR,     BCTARL,    // ISA 2.07 (POWER8)
	SC,                    // system call

	// -------------------------------------------------------------------------
	// §2 Condition register logical (XL-form)
	// -------------------------------------------------------------------------
	CRAND,     CRNAND,     CROR,       CRNOR,
	CRXOR,     CREQV,      CRANDC,     CRORC,
	MCRF,                   // Move CR field

	// -------------------------------------------------------------------------
	// §3 Fixed-point load (D / DS / X / DQ-form)
	// -------------------------------------------------------------------------
	LBZ,       LBZU,       LBZX,       LBZUX,
	LHZ,       LHZU,       LHZX,       LHZUX,
	LHA,       LHAU,       LHAX,       LHAUX,
	LWZ,       LWZU,       LWZX,       LWZUX,
	LWA,       LWAX,       LWAUX,      // PPC64
	LD,        LDU,        LDX,        LDUX,   // PPC64
	LQ,                                 // 128-bit pair load (POWER8)

	LHBRX,     LWBRX,      LDBRX,
	LMW,                                // load multiple word (rare)
	LSWI,      LSWX,                    // load string

	// -------------------------------------------------------------------------
	// §4 Fixed-point store (D / DS / X / DQ-form)
	// -------------------------------------------------------------------------
	STB,       STBU,       STBX,       STBUX,
	STH,       STHU,       STHX,       STHUX,
	STW,       STWU,       STWX,       STWUX,
	STD,       STDU,       STDX,       STDUX,  // PPC64
	STQ,                                // POWER8

	STHBRX,    STWBRX,     STDBRX,
	STMW,
	STSWI,     STSWX,

	// -------------------------------------------------------------------------
	// §5 Load/Store with reservation (atomic primitives)
	// -------------------------------------------------------------------------
	LBARX,     LHARX,      LWARX,      LDARX,
	LQARX,                              // POWER8 quad-word reservation
	STBCX_DOT, STHCX_DOT,  STWCX_DOT,  STDCX_DOT,
	STQCX_DOT,                          // POWER8

	// -------------------------------------------------------------------------
	// §6 Fixed-point arithmetic (D / XO-form)
	// -------------------------------------------------------------------------
	ADDI,      ADDIS,
	ADDIC,     ADDIC_DOT,   // addic.
	SUBFIC,
	ADDPCIS,                            // ISA 3.0
	ADD,       ADD_DOT,    ADD_O,      ADD_O_DOT,
	ADDC,      ADDC_DOT,   ADDC_O,     ADDC_O_DOT,
	ADDE,      ADDE_DOT,   ADDE_O,     ADDE_O_DOT,
	ADDME,     ADDME_DOT,  ADDME_O,    ADDME_O_DOT,
	ADDZE,     ADDZE_DOT,  ADDZE_O,    ADDZE_O_DOT,
	ADDEX,                              // POWER9
	SUBF,      SUBF_DOT,   SUBF_O,     SUBF_O_DOT,
	SUBFC,     SUBFC_DOT,  SUBFC_O,    SUBFC_O_DOT,
	SUBFE,     SUBFE_DOT,  SUBFE_O,    SUBFE_O_DOT,
	SUBFME,    SUBFME_DOT, SUBFME_O,   SUBFME_O_DOT,
	SUBFZE,    SUBFZE_DOT, SUBFZE_O,   SUBFZE_O_DOT,
	NEG,       NEG_DOT,    NEG_O,      NEG_O_DOT,

	MULLI,
	MULHW,     MULHW_DOT,   MULHWU,     MULHWU_DOT,
	MULLW,     MULLW_DOT,  MULLW_O,    MULLW_O_DOT,
	MULLD,     MULLD_DOT,  MULLD_O,    MULLD_O_DOT,  // PPC64
	MULHD,     MULHD_DOT,   MULHDU,     MULHDU_DOT,   // PPC64
	MADDLD,                             // POWER9 (mul-add)
	MADDHD,    MADDHDU,                 // POWER9

	DIVW,      DIVW_DOT,   DIVW_O,     DIVW_O_DOT,
	DIVWU,     DIVWU_DOT,  DIVWU_O,    DIVWU_O_DOT,
	DIVD,      DIVD_DOT,   DIVD_O,     DIVD_O_DOT,    // PPC64
	DIVDU,     DIVDU_DOT,  DIVDU_O,    DIVDU_O_DOT,   // PPC64
	DIVWE,     DIVWE_DOT,  DIVWE_O,    DIVWE_O_DOT,   // POWER7 extended
	DIVWEU,    DIVWEU_DOT, DIVWEU_O,   DIVWEU_O_DOT,
	DIVDE,     DIVDE_DOT,  DIVDE_O,    DIVDE_O_DOT,
	DIVDEU,    DIVDEU_DOT, DIVDEU_O,   DIVDEU_O_DOT,
	MODSW,     MODUW,                  // POWER9
	MODSD,     MODUD,                  // POWER9

	// Trap
	TWI,       TW,
	TDI,       TD,                     // PPC64

	// -------------------------------------------------------------------------
	// §7 Fixed-point logical / shift / rotate (X / M / MD / MDS-form)
	// -------------------------------------------------------------------------
	ANDI_DOT,  ANDIS_DOT,
	ORI,       ORIS,
	XORI,      XORIS,
	AND,       AND_DOT,
	OR,        OR_DOT,
	XOR,       XOR_DOT,
	NAND,      NAND_DOT,
	NOR,       NOR_DOT,
	EQV,       EQV_DOT,
	ANDC,      ANDC_DOT,
	ORC,       ORC_DOT,

	EXTSB,     EXTSB_DOT,
	EXTSH,     EXTSH_DOT,
	EXTSW,     EXTSW_DOT,             // PPC64
	CNTLZW,    CNTLZW_DOT,
	CNTLZD,    CNTLZD_DOT,            // PPC64
	CNTTZW,    CNTTZW_DOT,            // POWER9
	CNTTZD,    CNTTZD_DOT,            // POWER9
	POPCNTB,                          // ISA 2.02
	POPCNTW,                          // POWER7
	POPCNTD,                          // POWER7
	PRTYW,     PRTYD,                 // POWER7 parity
	BPERMD,                           // POWER7
	CMPB,                             // POWER6

	SLW,       SLW_DOT,
	SRW,       SRW_DOT,
	SRAW,      SRAW_DOT,
	SRAWI,     SRAWI_DOT,
	SLD,       SLD_DOT,               // PPC64
	SRD,       SRD_DOT,               // PPC64
	SRAD,      SRAD_DOT,              // PPC64
	SRADI,     SRADI_DOT,             // PPC64

	RLWINM,    RLWINM_DOT,
	RLWNM,     RLWNM_DOT,
	RLWIMI,    RLWIMI_DOT,
	RLDICL,    RLDICL_DOT,            // PPC64
	RLDICR,    RLDICR_DOT,            // PPC64
	RLDIC,     RLDIC_DOT,             // PPC64
	RLDIMI,    RLDIMI_DOT,            // PPC64
	RLDCL,     RLDCL_DOT,             // PPC64
	RLDCR,     RLDCR_DOT,             // PPC64

	// -------------------------------------------------------------------------
	// §8 Compare
	// -------------------------------------------------------------------------
	CMPI,      CMPLI,
	CMP,       CMPL,
	CMPRB,                            // ISA 3.0
	CMPEQB,                           // ISA 3.0

	// -------------------------------------------------------------------------
	// §9 Floating-point arithmetic (A / X-form)
	// -------------------------------------------------------------------------
	FADD,      FADD_DOT,
	FADDS,     FADDS_DOT,
	FSUB,      FSUB_DOT,
	FSUBS,     FSUBS_DOT,
	FMUL,      FMUL_DOT,
	FMULS,     FMULS_DOT,
	FDIV,      FDIV_DOT,
	FDIVS,     FDIVS_DOT,
	FSQRT,     FSQRT_DOT,
	FSQRTS,    FSQRTS_DOT,
	FRE,       FRE_DOT,
	FRES,      FRES_DOT,
	FRSQRTE,   FRSQRTE_DOT,
	FRSQRTES,  FRSQRTES_DOT,
	FMADD,     FMADD_DOT,
	FMADDS,    FMADDS_DOT,
	FMSUB,     FMSUB_DOT,
	FMSUBS,    FMSUBS_DOT,
	FNMADD,    FNMADD_DOT,
	FNMADDS,   FNMADDS_DOT,
	FNMSUB,    FNMSUB_DOT,
	FNMSUBS,   FNMSUBS_DOT,
	FSEL,      FSEL_DOT,

	FCPSGN,    FCPSGN_DOT,
	FNEG,      FNEG_DOT,
	FABS,      FABS_DOT,
	FNABS,     FNABS_DOT,
	FMR,       FMR_DOT,

	FRSP,      FRSP_DOT,
	FCTID,     FCTID_DOT,
	FCTIDU,    FCTIDU_DOT,
	FCTIDZ,    FCTIDZ_DOT,
	FCTIDUZ,   FCTIDUZ_DOT,
	FCTIW,     FCTIW_DOT,
	FCTIWU,    FCTIWU_DOT,
	FCTIWZ,    FCTIWZ_DOT,
	FCTIWUZ,   FCTIWUZ_DOT,
	FCFID,     FCFID_DOT,
	FCFIDU,    FCFIDU_DOT,
	FCFIDS,    FCFIDS_DOT,
	FCFIDUS,   FCFIDUS_DOT,
	FRIN,      FRIN_DOT,
	FRIZ,      FRIZ_DOT,
	FRIP,      FRIP_DOT,
	FRIM,      FRIM_DOT,

	FCMPU,     FCMPO,
	FTDIV,     FTSQRT,                // POWER7
	FMRGEW,    FMRGOW,                // POWER8

	LFS,       LFSU,       LFSX,      LFSUX,
	LFD,       LFDU,       LFDX,      LFDUX,
	LFIWAX,    LFIWZX,
	LFDP,      LFDPX,                 // ISA 2.05 quad-word
	STFS,      STFSU,      STFSX,     STFSUX,
	STFD,      STFDU,      STFDX,     STFDUX,
	STFIWX,
	STFDP,     STFDPX,

	MFFS,      MFFS_DOT,
	MCRFS,
	MTFSB0,    MTFSB0_DOT,
	MTFSB1,    MTFSB1_DOT,
	MTFSFI,    MTFSFI_DOT,
	MTFSF,     MTFSF_DOT,

	// -------------------------------------------------------------------------
	// §10 SPR / system / cache
	// -------------------------------------------------------------------------
	MFSPR,     MTSPR,
	MFTB,                                      // deprecated by ISA 2.06 (use mfspr 268/269)
	MFCR,      MTCRF,      MTOCRF,
	MFOCRF,
	MTMSR,     MFMSR,      MTMSRD,             // supervisor / hypervisor
	SC_HV,                                     // hypervisor sc level
	RFI,       RFID,       HRFID,
	SYNC,      LWSYNC,     PTESYNC,
	EIEIO,
	ISYNC,
	DCBT,      DCBTST,     DCBA,     DCBF,
	DCBZ,      DCBZL,                          // POWER6 large-line dcbz
	ICBI,
	ICBT,                                      // ISA 2.06+
	NAP,                                       // power management hints
	WAIT,                                      // POWER9
	MSYNC,                                     // alias for sync L=2 (POWER8)

	TLBIE,     TLBIEL,     TLBSYNC,            // supervisor TLB
	SLBIE,     SLBIA,      SLBMTE,   SLBMFEE,  // segment lookaside buffer
	SLBMFEV,   SLBSYNC,    SLBIEG,             // POWER8/9
	DARN,                                      // POWER9 random number

	// -------------------------------------------------------------------------
	// §11 AltiVec (VMX) — see Power ISA Book I §6
	// -------------------------------------------------------------------------
	VAND,      VANDC,      VOR,       VORC,
	VNOR,      VXOR,       VEQV,      VNAND,    // VEQV/VNAND ISA 2.07
	VSEL,
	VADDUBM,   VADDUHM,    VADDUWM,   VADDUDM,
	VADDFP,                                     // single-precision FP vector
	VSUBUBM,   VSUBUHM,    VSUBUWM,   VSUBUDM,
	VSUBFP,
	VADDCUW,   VADDCUQ,                         // POWER8 carry-out add
	VADDECUQ,  VADDEUQM,                        // POWER8 ext carry-in 128-bit
	VSUBCUW,   VSUBCUQ,
	VSUBECUQ,  VSUBEUQM,
	VADDUBS,   VADDUHS,    VADDUWS,             // saturating unsigned add
	VADDSBS,   VADDSHS,    VADDSWS,             // saturating signed add
	VSUBUBS,   VSUBUHS,    VSUBUWS,
	VSUBSBS,   VSUBSHS,    VSUBSWS,
	VMULESB,   VMULESH,    VMULESW,             // even/odd multiply
	VMULEUB,   VMULEUH,    VMULEUW,
	VMULOSB,   VMULOSH,    VMULOSW,
	VMULOUB,   VMULOUH,    VMULOUW,
	VMULUWM,                                   // POWER8 mul lo
	VMSUMUBM,  VMSUMMBM,
	VMSUMUHM,  VMSUMSHM,
	VMSUMUHS,  VMSUMSHS,
	VMSUMUDM,                                  // POWER8

	VCMPEQUB,  VCMPEQUB_DOT,
	VCMPEQUH,  VCMPEQUH_DOT,
	VCMPEQUW,  VCMPEQUW_DOT,
	VCMPEQUD,  VCMPEQUD_DOT,
	VCMPNEB,   VCMPNEB_DOT,                    // POWER9
	VCMPNEH,   VCMPNEH_DOT,
	VCMPNEW,   VCMPNEW_DOT,
	VCMPGTSB,  VCMPGTSB_DOT,
	VCMPGTSH,  VCMPGTSH_DOT,
	VCMPGTSW,  VCMPGTSW_DOT,
	VCMPGTSD,  VCMPGTSD_DOT,
	VCMPGTUB,  VCMPGTUB_DOT,
	VCMPGTUH,  VCMPGTUH_DOT,
	VCMPGTUW,  VCMPGTUW_DOT,
	VCMPGTUD,  VCMPGTUD_DOT,
	VCMPEQFP,  VCMPEQFP_DOT,
	VCMPGEFP,  VCMPGEFP_DOT,
	VCMPGTFP,  VCMPGTFP_DOT,
	VCMPBFP,   VCMPBFP_DOT,

	VMAXSB,    VMAXSH,     VMAXSW,    VMAXSD,
	VMAXUB,    VMAXUH,     VMAXUW,    VMAXUD,
	VMAXFP,
	VMINSB,    VMINSH,     VMINSW,    VMINSD,
	VMINUB,    VMINUH,     VMINUW,    VMINUD,
	VMINFP,

	VAVGSB,    VAVGSH,     VAVGSW,
	VAVGUB,    VAVGUH,     VAVGUW,

	VSL,       VSR,        VSLO,      VSRO,
	VSLB,      VSLH,        VSLW,     VSLD,
	VSRB,      VSRH,        VSRW,     VSRD,
	VSRAB,     VSRAH,       VSRAW,    VSRAD,
	VRLB,      VRLH,        VRLW,     VRLD,

	VPERM,     VPERMR,                          // POWER9
	VSLDOI,
	VBPERMQ,                                    // POWER8 bit permute
	VBPERMD,                                    // POWER9
	VMRGHB,    VMRGHH,      VMRGHW,
	VMRGLB,    VMRGLH,      VMRGLW,
	VMRGEW,    VMRGOW,                          // POWER8 merge even/odd word
	VSPLTB,    VSPLTH,      VSPLTW,
	VSPLTISB,  VSPLTISH,    VSPLTISW,
	VPKPX,     VPKUHUM,     VPKUWUM,   VPKUDUM,
	VPKUHUS,   VPKUWUS,     VPKUDUS,
	VPKSHUS,   VPKSWUS,     VPKSDUS,
	VPKSHSS,   VPKSWSS,     VPKSDSS,
	VUPKHSB,   VUPKHSH,     VUPKHSW,
	VUPKLSB,   VUPKLSH,     VUPKLSW,
	VUPKHPX,   VUPKLPX,
	VCIPHER,   VCIPHERLAST,                     // POWER8 AES
	VNCIPHER,  VNCIPHERLAST,
	VSBOX,
	VSHASIGMAW, VSHASIGMAD,                     // POWER8 SHA
	VPMSUMB,   VPMSUMH,    VPMSUMW,   VPMSUMD,  // POWER8 polynomial multiply

	VRFIM,     VRFIN,       VRFIP,    VRFIZ,    // round-to-int FP
	VEXPTEFP,  VLOGEFP,
	VREFP,     VRSQRTEFP,
	VMADDFP,   VNMSUBFP,
	VCFSX,     VCFUX,
	VCTSXS,    VCTUXS,

	LVX,       LVXL,                            // load vector
	LVEBX,     LVEHX,       LVEWX,
	LVSL,      LVSR,
	STVX,      STVXL,
	STVEBX,    STVEHX,      STVEWX,

	MFVSCR,    MTVSCR,

	// ISA 3.0 vector additions
	VABSDUB,   VABSDUH,    VABSDUW,             // unsigned absolute difference
	VEXTSB2W,  VEXTSH2W,                        // sign-extend within vector
	VEXTSB2D,  VEXTSH2D,    VEXTSW2D,
	VPRTYBW,   VPRTYBD,    VPRTYBQ,             // parity byte by word/dword/qword
	VRLWNM,    VRLDNM,                          // vector rotate
	VRLWMI,    VRLDMI,
	VCMPNEZB,  VCMPNEZB_DOT,
	VCMPNEZH,  VCMPNEZH_DOT,
	VCMPNEZW,  VCMPNEZW_DOT,
	VCLZB,     VCLZH,        VCLZW,    VCLZD,
	VCTZB,     VCTZH,        VCTZW,    VCTZD,
	VPOPCNTB,  VPOPCNTH,    VPOPCNTW, VPOPCNTD,
	VEXTRACTUB,VEXTRACTUH,  VEXTRACTUW, VEXTRACTD,
	VINSERTB,  VINSERTH,    VINSERTW,   VINSERTD,
	VSLV,      VSRV,                            // POWER9 variable shift
	VMUL10UQ,  VMUL10CUQ,                       // POWER9 decimal-multiply helpers
	VMUL10EUQ, VMUL10ECUQ,
	// VBPERMW removed: not a real Power ISA mnemonic per LLVM 22; use VBPERMD or VBPERMQ.

	// -------------------------------------------------------------------------
	// §12 VSX (POWER7+) — see Power ISA Book I §7
	// -------------------------------------------------------------------------
	LXSDX,     LXSIWAX,    LXSIWZX,
	LXVD2X,    LXVDSX,     LXVW4X,
	STXSDX,    STXSIWX,
	STXVD2X,   STXVW4X,

	// ISA 2.07 BE/LE byte-mirroring loads
	LXSSPX,    STXSSPX,                          // single-precision via VSX

	// ISA 3.0 (POWER9) VSX additions
	LXV,        STXV,                            // D-form 16-byte vsx
	LXVH8X,     LXVB16X,    LXVL,    LXVLL,      // length-controlled loads
	STXVH8X,    STXVB16X,   STXVL,   STXVLL,
	LXVX,       STXVX,                           // X-form vsx vector
	LXSIBZX,    LXSIHZX,
	STXSIBX,    STXSIHX,
	LXSD,       STXSD,                           // DS-form scalar VSX
	LXSSP,      STXSSP,                          // DS-form single VSX

	// XX2 / XX3 arithmetic — POWER7+
	XSADDSP,   XSADDDP,
	XSSUBSP,   XSSUBDP,
	XSMULSP,   XSMULDP,
	XSDIVSP,   XSDIVDP,
	XSSQRTSP,  XSSQRTDP,
	XSRESP,    XSREDP,
	XSRSQRTESP,XSRSQRTEDP,
	XSMADDASP, XSMADDADP,    XSMADDMSP, XSMADDMDP,
	XSMSUBASP, XSMSUBADP,    XSMSUBMSP, XSMSUBMDP,
	XSNMADDASP,XSNMADDADP,   XSNMADDMSP,XSNMADDMDP,
	XSNMSUBASP,XSNMSUBADP,   XSNMSUBMSP,XSNMSUBMDP,
	XSMAXDP,   XSMINDP,
	XSMAXCDP,  XSMINCDP,                      // POWER9
	XSMAXJDP,  XSMINJDP,                      // POWER9
	XSCMPODP,  XSCMPUDP,
	XSCMPEQDP, XSCMPGTDP,    XSCMPGEDP,        // POWER9 compare
	XSCPSGNDP, XSABSDP,       XSNABSDP,
	XSNEGDP,
	XSCVDPSP,  XSCVSPDP,    XSCVDPSXDS,  XSCVDPUXDS,
	XSCVSXDDP, XSCVUXDDP,
	XSCVDPSXWS,XSCVDPUXWS,
	XSCVDPHP,  XSCVHPDP,    XSCVSPDPN,   XSCVDPSPN,
	XSRDPI,    XSRDPIM,     XSRDPIP,     XSRDPIZ,
	XSRDPIC,   XSRSP,
	XSIEXPDP,  XSXEXPDP,    XSXSIGDP,            // POWER9

	XVADDSP,   XVADDDP,
	XVSUBSP,   XVSUBDP,
	XVMULSP,   XVMULDP,
	XVDIVSP,   XVDIVDP,
	XVSQRTSP,  XVSQRTDP,
	XVRESP,    XVREDP,
	XVRSQRTESP,XVRSQRTEDP,
	XVMADDASP, XVMADDADP,    XVMADDMSP, XVMADDMDP,
	XVMSUBASP, XVMSUBADP,    XVMSUBMSP, XVMSUBMDP,
	XVNMADDASP,XVNMADDADP,   XVNMADDMSP,XVNMADDMDP,
	XVNMSUBASP,XVNMSUBADP,   XVNMSUBMSP,XVNMSUBMDP,
	XVMAXSP,   XVMAXDP,
	XVMINSP,   XVMINDP,
	XVCMPEQSP, XVCMPEQSP_DOT,
	XVCMPEQDP, XVCMPEQDP_DOT,
	XVCMPGTSP, XVCMPGTSP_DOT,
	XVCMPGTDP, XVCMPGTDP_DOT,
	XVCMPGESP, XVCMPGESP_DOT,
	XVCMPGEDP, XVCMPGEDP_DOT,
	XVCPSGNSP, XVCPSGNDP,
	XVABSSP,   XVABSDP,    XVNABSSP, XVNABSDP,
	XVNEGSP,   XVNEGDP,
	XVCVSPDP,  XVCVDPSP,
	XVCVSPSXDS,XVCVSPUXDS,
	XVCVDPSXDS,XVCVDPUXDS,
	XVCVSPSXWS,XVCVSPUXWS,
	XVCVDPSXWS,XVCVDPUXWS,
	XVCVSXDSP, XVCVUXDSP,    XVCVSXDDP, XVCVUXDDP,
	XVCVSXWSP, XVCVUXWSP,    XVCVSXWDP, XVCVUXWDP,
	XVRSPI,    XVRSPIM,      XVRSPIP,   XVRSPIZ,
	XVRSPIC,
	XVRDPI,    XVRDPIM,      XVRDPIP,   XVRDPIZ,
	XVRDPIC,
	XVIEXPSP,  XVIEXPDP,                       // POWER9
	XVXEXPSP,  XVXEXPDP,    XVXSIGSP, XVXSIGDP,
	XVTSTDCSP, XVTSTDCDP,                      // POWER9 test
	XSTSTDCSP, XSTSTDCDP,                      // POWER9
	XSTSQRTDP, XVTSQRTSP,   XVTSQRTDP,
	XSTDIVDP,  XVTDIVSP,    XVTDIVDP,

	XXLAND,    XXLANDC,    XXLOR,    XXLXOR,
	XXLNOR,    XXLEQV,      XXLNAND, XXLORC,
	XXSEL,
	XXSPLTW,   XXSPLTIB,                       // POWER9
	XXSLDWI,   XXPERMDI,
	XXMRGHW,   XXMRGLW,
	XXEXTRACTUW,XXINSERTW,                     // POWER9
	XXSPLTIW,  XXSPLTIDP,   XXSPLTI32DX,       // POWER10 (8RR-form prefixed)
	XSCMPEQQP, XSCMPGTQP,   XSCMPGEQP,         // POWER10 quad

	// POWER9 binary128 (quad-precision FP) — see Power ISA Book I §7
	XSADDQP,   XSADDQPO,
	XSSUBQP,   XSSUBQPO,
	XSMULQP,   XSMULQPO,
	XSDIVQP,   XSDIVQPO,
	XSSQRTQP,  XSSQRTQPO,
	XSMADDQP,  XSMADDQPO,
	XSMSUBQP,  XSMSUBQPO,
	XSNMADDQP, XSNMADDQPO,
	XSNMSUBQP, XSNMSUBQPO,
	XSABSQP,   XSNABSQP,   XSNEGQP,
	XSCPSGNQP,
	XSCMPOQP,  XSCMPUQP,
	XSTSTDCQP,
	XSRQPI,    XSRQPIX,    XSRQPXP,
	XSXEXPQP,  XSXSIGQP,   XSIEXPQP,
	// QP conversions
	XSCVQPDP,  XSCVQPDPO,
	XSCVDPQP,
	XSCVQPSDZ, XSCVQPSWZ,
	XSCVQPUDZ, XSCVQPUWZ,
	XSCVSDQP,  XSCVUDQP,

	// Decimal Floating Point (DFP, POWER6+) — see Power ISA Book I §5
	DADD,      DADD_DOT,
	DSUB,      DSUB_DOT,
	DMUL,      DMUL_DOT,
	DDIV,      DDIV_DOT,
	DCMPU,     DCMPO,
	DRSP,      DRSP_DOT,
	DCTDP,     DCTDP_DOT,
	DXEX,      DXEX_DOT,
	DIEX,      DIEX_DOT,
	DRRND,     DRRND_DOT,
	DRINTX,    DRINTX_DOT,
	DRINTN,    DRINTN_DOT,
	DQUA,      DQUA_DOT,
	DQUAI,     DQUAI_DOT,
	DSCLI,     DSCLI_DOT,
	DSCRI,     DSCRI_DOT,
	DCFFIX,    DCFFIX_DOT,
	DCTFIX,    DCTFIX_DOT,
	DTSTDC,    DTSTDG,
	DTSTEX,    DTSTSF,
	DENBCD,    DENBCD_DOT,
	DDEDPD,    DDEDPD_DOT,

	// DFPQ (128-bit decimal) — POWER6+
	DADDQ,     DADDQ_DOT,
	DSUBQ,     DSUBQ_DOT,
	DMULQ,     DMULQ_DOT,
	DDIVQ,     DDIVQ_DOT,
	DCMPUQ,    DCMPOQ,
	DCTFIXQ,   DCTFIXQ_DOT,

	// MMA accelerator non-prefixed (POWER10) — see Power ISA Book I §8
	XXMTACC,   XXMFACC,   XXSETACCZ,
	XVF16GER2, XVF16GER2PP, XVF16GER2PN, XVF16GER2NP, XVF16GER2NN,
	XVF32GER,  XVF32GERPP,  XVF32GERPN,  XVF32GERNP,  XVF32GERNN,
	XVF64GER,  XVF64GERPP,  XVF64GERPN,  XVF64GERNP,  XVF64GERNN,
	XVBF16GER2,XVBF16GER2PP,XVBF16GER2PN,XVBF16GER2NP,XVBF16GER2NN,
	XVI4GER8,  XVI4GER8PP,
	XVI8GER4,  XVI8GER4PP,  XVI8GER4SPP,
	XVI16GER2, XVI16GER2PP, XVI16GER2S,  XVI16GER2SPP,

	// POWER10 additional vector AltiVec / VSX
	VSTRIBL,   VSTRIBR,    VSTRIBL_DOT,  VSTRIBR_DOT,
	VSTRIHL,   VSTRIHR,    VSTRIHL_DOT,  VSTRIHR_DOT,
	VMSUMCUD,                                  // POWER10 carry-sum
	VCFUGED,                                   // POWER10 centrifuge
	VPDEPD,    VPEXTD,                         // POWER10 deposit/extract
	VGNB,                                      // POWER10 gather-nybble
	VSLDBI,    VSRDBI,                         // POWER10 double-bit shift
	VCLZDM,    VCTZDM,                         // POWER10 count zeros under mask
	VCLRLB,    VCLRRB,                         // POWER10 vector clear left/right byte
	VEXPANDBM, VEXPANDHM, VEXPANDWM, VEXPANDDM, VEXPANDQM,  // POWER10 expand
	VEXTRACTBM,VEXTRACTHM,VEXTRACTWM,VEXTRACTDM,VEXTRACTQM, // POWER10 extract mask
	VCNTMBB,   VCNTMBH,   VCNTMBW,   VCNTMBD,              // POWER10 count mask bits
	MTVSRBM,   MTVSRHM,   MTVSRWM,   MTVSRDM,   MTVSRQM,   // POWER10 move-mask to VSR

	// POWER10 paste / copy
	COPY,      PASTE_DOT,

	// Hypervisor-priv cache-inhibited X-form loads/stores
	LBZCIX,    LHZCIX,    LWZCIX,    LDCIX,
	STBCIX,    STHCIX,    STWCIX,    STDCIX,

	// HTM (Hardware Transactional Memory, POWER8)
	TBEGIN_DOT,   TEND_DOT,
	TABORT_DOT,   TABORTWC_DOT, TABORTWCI_DOT, TABORTDC_DOT, TABORTDCI_DOT,
	TRECLAIM_DOT, TRECHKPT_DOT,
	TSUSPEND_DOT, TRESUME_DOT,
	TCHECK,

	// BCD conversion (POWER6/7)
	ADDG6S,
	CBCDTD,    CDTBCD,

	// Event-based branch / debug return
	RFEBB,     RFDI,

	// Inter-processor messaging (sync only — msgsnd/msgclr/p variants need
	// booke or server-specific feature support that LLVM 22 doesn't expose
	// via a single mattr flag — deferred).
	MSGSYNC,

	// Integer-Select (POWER7) and TH=16 cache hints (POWER8)
	ISEL,
	DCBTT,     DCBTSTT,

	// POWER10 vector insert / extract with right/left-justification
	VEXTUBLX,  VEXTUHLX,  VEXTUWLX,
	VEXTUBRX,  VEXTUHRX,  VEXTUWRX,
	VINSBVLX,  VINSHVLX,  VINSWVLX,
	VINSBVRX,  VINSHVRX,  VINSWVRX,
	VINSBLX,   VINSHLX,   VINSWLX,   VINSDLX,
	VINSBRX,   VINSHRX,   VINSWRX,   VINSDRX,
	VINSW,     VINSD,
	VEXTDUBVLX,VEXTDUHVLX,VEXTDUWVLX,VEXTDDVLX,
	VEXTDUBVRX,VEXTDUHVRX,VEXTDUWVRX,VEXTDDVRX,

	// POWER10 VSX byte/half/word/doubleword load right-justified
	LXVRBX,    LXVRHX,    LXVRWX,    LXVRDX,
	STXVRBX,   STXVRHX,   STXVRWX,   STXVRDX,
	LXVKQ,                                      // load known quad
	XSMAXCQP,  XSMINCQP,                        // POWER10 QP max/min

	// POWER10 vector quad rotate / shift / divide / modulo / multiply
	VRLQ,      VRLQMI,    VRLQNM,
	VSLQ,      VSRQ,      VSRAQ,
	VMULESD,   VMULEUD,   VMULOSD,   VMULOUD,   VMULLD,
	VMULHSW,   VMULHSD,   VMULHUW,   VMULHUD,
	VDIVSW,    VDIVUW,    VDIVSD,    VDIVUD,    VDIVSQ,   VDIVUQ,
	VDIVESW,   VDIVEUW,   VDIVESD,   VDIVEUD,   VDIVESQ,  VDIVEUQ,
	VMODSW,    VMODUW,    VMODSD,    VMODUD,    VMODSQ,   VMODUQ,

	// POWER9/POWER10 misc
	SETB,      MCRXRX,
	XVCVBF16SPN, XVCVSPBF16,
	XXGENPCVBM,XXGENPCVHM,XXGENPCVWM,XXGENPCVDM,
	XXBLENDVB, XXBLENDVH, XXBLENDVW, XXBLENDVD,
	XXPERMX,   XXEVAL,
	XXPERM,                                    // POWER9 byte permute

	// -------------------------------------------------------------------------
	// §13 Power ISA 3.1 prefixed (POWER10) — 8-byte instructions
	// -------------------------------------------------------------------------
	PLD,       PSTD,                            // prefixed load/store doubleword
	PLWZ,      PSTW,
	PLBZ,      PSTB,
	PLHZ,      PSTH,
	PLHA,      PLWA,
	PLFD,      PSTFD,
	PLFS,      PSTFS,
	PLXV,      PSTXV,                           // prefixed VSX
	PLXSD,     PSTXSD,
	PLXSSP,    PSTXSSP,
	PADDI,     PLI,                             // 34-bit imm add / load-immediate
	PSUBI,                                      // alias-style
	PMXVF32GER, PMXVF64GER,                     // MMA accelerator (sketch)
	PMXVI4GER8, PMXVI8GER4, PMXVI16GER2,        // MMA integer
	// POWER10 MMA full prefix variants (pp/pn/np/nn + s/spp)
	PMXVF16GER2, PMXVF16GER2PP, PMXVF16GER2PN, PMXVF16GER2NP, PMXVF16GER2NN,
	PMXVF32GERPP, PMXVF32GERPN, PMXVF32GERNP, PMXVF32GERNN,
	PMXVF64GERPP, PMXVF64GERPN, PMXVF64GERNP, PMXVF64GERNN,
	PMXVBF16GER2, PMXVBF16GER2PP, PMXVBF16GER2PN, PMXVBF16GER2NP, PMXVBF16GER2NN,
	PMXVI4GER8PP,
	PMXVI8GER4PP, PMXVI8GER4SPP,
	PMXVI16GER2PP, PMXVI16GER2S, PMXVI16GER2SPP,

	// POWER10 paired VSX load/store
	LXVP,      STXVP,                          // DQ-form 32-byte VSX pair
	LXVPX,     STXVPX,                         // X-form indexed

	// BookE / Embedded-EP cache management and effective-physical loads
	DCBI,
	ICBIEP,    DCBTEP,    DCBTSTEP,
	LBEPX,     LHEPX,     LWEPX,
	STBEPX,    STHEPX,    STWEPX,
	LFDEPX,    STFDEPX,
	TLBSX,
	DCCCI,     ICCCI,
	WRTEE,     WRTEEI,

	// BookE / Embedded TLB and other extended
	TLBRE,     TLBWE,
	TLBIVAX,   TLBILX,
	TLBLD,     TLBLI,                          // 601-specific
	MFPMR,     MTPMR,                          // Performance Monitor Reg

	// 32-bit segment-register move (Book III-S 32-bit only)
	MFSR,      MTSR,
	MFSRIN,    MTSRIN,

	// AltiVec data-stream touch / cancel (deprecated but in ISA)
	DST,       DSTT,
	DSTST,     DSTSTT,
	DSS,       DSSALL,

	// AltiVec sum-across (legacy)
	VSUMSWS,
	VSUM2SWS,
	VSUM4SBS,  VSUM4SHS,  VSUM4UBS,

	// POWER9 FPSCR moves
	MFFSCE,
	MFFSCDRN,  MFFSCDRNI,
	MFFSCRN,   MFFSCRNI,
	MFFSL,

	// POWER9/10 misc system
	STOP,                                      // POWER9 idle
	CPABORT,                                   // POWER10 copy abort
	ATTN,                                      // server attention

	// POWER8 GPR ↔ FPR/VSR moves (LLVM-canonical mt/mf-fpr* spellings).
	// Note: mtvsrd / mfvsrd are spec mnemonics that LLVM 22 prints as
	// mtfprd / mffprd when the target register is in the FPR-aliased half.
	MTFPRD,    MFFPRD,
	MTFPRWA,
	MTFPRWZ,   MFFPRWZ,
	// POWER9 GPR ↔ VSR moves
	MFVSRLD,   MTVSRDD,   MTVSRWS,

	// POWER9 sign-extend-shift-left immediate
	EXTSWSLI,  EXTSWSLI_DOT,

	// ISEL canonical-condition aliases
	ISELLT,    ISELGT,    ISELEQ,

	// Trap aliases (specific TO values)
	TWEQ,      TWNE,      TWGT,      TWLT,
	TWGTI,     TWLTI,     TWEQI,     TWNEI,     TWUI,
	TDEQ,      TDNE,      TDGT,      TDLT,
	TDGTI,     TDLTI,     TDEQI,     TDNEI,     TDUI,

	// POWER8/9 BCD arithmetic and conversion (Vector BCD)
	BCDADD_DOT, BCDSUB_DOT,
	BCDS_DOT,   BCDUS_DOT,
	BCDSR_DOT,
	BCDCFN_DOT, BCDCTN_DOT,
	BCDCFZ_DOT, BCDCTZ_DOT,
	BCDCPSGN_DOT,
	BCDTRUNC_DOT, BCDUTRUNC_DOT,
	BCDCFSQ_DOT, BCDCTSQ_DOT,

	// POWER9 SCV (System Call Vectored)
	SCV,

	// Counter+CR+LK branch aliases
	BDNZTL,    BDZTL,
	BDNZFL,    BDZFL,

	// Counter+CR+LR aliases
	BDNZTLR,   BDZTLR,
	BDNZFLR,   BDZFLR,
	BDNZTLRL,  BDZTLRL,
	BDNZFLRL,  BDZFLRL,

	// SPR-specific move aliases (LLVM treats these as distinct mnemonics)
	MTCR,                                       // = mtcrf 255, RS
	MFDSCR,    MTDSCR,                          // POWER8 Data Stream Control
	MFCFAR,    MTCFAR,                          // POWER6+ Come-From Addr Reg
	MFPPR,     MTPPR,                           // POWER7+ Process Priority Reg
	MFDEC,     MTDEC,
	MFSRR0,    MTSRR0,    MFSRR1,    MTSRR1,
	MFDAR,     MTDAR,
	MFDSISR,   MTDSISR,
	MFASR,     MTASR,                           // 32-bit MSR/SR
	MFAMR,     MTAMR,                           // ISA 2.05 AMR
	MFTCR,     MTTCR,                           // BookE Timer Control
	MFESR,     MTESR,                           // BookE Exception Syndrome
	MFDCCR,    MTDCCR,                          // BookE Data Cache Control
	MTBR0,     MTBR1,                           // BookE Branch BR
	MTTBL,     MTTBU,                           // Time Base writes

	// POWER9 atomic memory operations
	LWAT,      LDAT,
	STWAT,     STDAT,

	// POWER10 vector extend sign double → quad
	VEXTSD2Q,

	// POWER10 paired length-controlled VSX
	LXVPRL,    LXVPRLL,   STXVPRL,   STXVPRLL,
	LXVRL,     LXVRLL,    STXVRL,    STXVRLL,

	// BookE machine check return
	RFMCI,

	// -------------------------------------------------------------------------
	// §14 Common assembler aliases (the printer emits these for legibility;
	// the encoder builds them via their underlying form)
	// -------------------------------------------------------------------------
	NOP,        // ori 0,0,0
	XNOP,       // xori 0,0,0
	LI,         // addi rD, 0, value
	LIS,        // addis rD, 0, value
	LA,         // addi rD, rA, disp
	MR,         // or rD, rS, rS
	MR_DOT,     // or. rD, rS, rS
	NOT,        // nor rD, rS, rS
	NOT_DOT,
	BLR,        // bclr 20, 0  (return)
	BLRL,
	BCTR,       // bcctr 20, 0
	BCTRL,
	BEQ, BNE, BLT, BLE, BGT, BGE, BSO, BNS,
	BEQL, BNEL, BLTL, BLEL, BGTL, BGEL, BSOL, BNSL,
	BEQLR, BNELR, BLTLR, BLELR, BGTLR, BGELR, BSOLR, BNSLR,
	BEQCTR, BNECTR, BLTCTR, BLECTR, BGTCTR, BGECTR, BSOCTR, BNSCTR,
	BDZ, BDNZ, BDZL, BDNZL,
	BDZLR, BDNZLR, BDZLRL, BDNZLRL,
	BDZF, BDZT, BDNZF, BDNZT,
	TRAP,                                       // trap unconditional / always
	MFLR,       // mfspr rD, 8
	MTLR,       // mtspr 8, rS
	MFCTR,      // mfspr rD, 9
	MTCTR,      // mtspr 9, rS
	MFXER,      // mfspr rD, 1
	MTXER,      // mtspr 1, rS

	SLWI,       // rlwinm Rx, Ry, n, 0, 31-n
	SRWI,       // rlwinm Rx, Ry, 32-n, n, 31
	SLDI,       // rldicr Rx, Ry, n, 63-n
	SRDI,       // rldicl Rx, Ry, 64-n, n
	CLRRWI,     CLRLWI,
	CLRRDI,     CLRLDI,
	EXTLDI,     EXTRDI,                          // rldicl extractions
	EXTLWI,     EXTRWI,
	INSLWI,     INSRWI,
	ROTLW,      ROTLWI,
	ROTRW,
	ROTLD,      ROTLDI,                          // rldcl alias
	ROTRDI,

	SUB,        SUB_DOT,                         // subf alias (operand-reverse)
	SUB_O,      SUB_O_DOT,
	SUBC,       SUBC_DOT,
	SUBC_O,     SUBC_O_DOT,

	CMPW,       CMPLW,                           // cmp/cmpl L=0
	CMPD,       CMPLD,                           // cmp/cmpl L=1
	CMPWI,      CMPLWI,
	CMPDI,      CMPLDI,

	// -------------------------------------------------------------------------
	// §33 SPE / EFS / EFD (Freescale e500/e500v2 Signal Processing Engine)
	// -------------------------------------------------------------------------
	// SPE core integer/logical/shift/compare/memory
	EVADDW,     EVADDIW,    EVSUBFW,    EVSUBIFW,
	EVABS,      EVEXTSH,    EVEXTSB,    EVCNTLZW,   EVCNTLSW,
	EVRLW,      EVRLWI,     EVSLW,      EVSLWI,
	EVSPLATI,   EVSPLATFI,
	EVSRWU,     EVSRWS,     EVSRWIU,    EVSRWIS,
	EVAND,      EVOR,       EVXOR,      EVNAND,     EVNOR,      EVANDC,     EVORC,      EVEQV,
	EVCMPGTS,   EVCMPGTU,   EVCMPLTS,   EVCMPLTU,   EVCMPEQ,
	EVSEL,
	EVMERGEHI,  EVMERGELO,  EVMERGEHILO, EVMERGELOHI,
	EVDIVWS,    EVDIVWU,
	EVMRA,

	// SPE memory (D/X-form)
	EVLDD,      EVLDDX,     EVLDW,      EVLDWX,     EVLDH,      EVLDHX,
	EVSTDD,     EVSTDDX,    EVSTDW,     EVSTDWX,    EVSTDH,     EVSTDHX,
	EVLWWSPLAT, EVLWHSPLAT,
	EVLHHESPLAT, EVLHHOSSPLAT, EVLHHOUSPLAT,
	EVLWHE,     EVLWHOU,    EVLWHOS,    EVLWHEX,
	EVSTWWE,    EVSTWWO,    EVSTWHE,    EVSTWHO,    EVSTWHEX,

	// SPE-FP (single, vector — evfs*)
	EVFSADD,    EVFSSUB,    EVFSABS,    EVFSNABS,   EVFSNEG,
	EVFSMUL,    EVFSDIV,
	EVFSCMPGT,  EVFSCMPLT,  EVFSCMPEQ,
	EVFSTSTGT,  EVFSTSTLT,  EVFSTSTEQ,
	EVFSCFUI,   EVFSCFSI,   EVFSCFUF,   EVFSCFSF,
	EVFSCTUI,   EVFSCTSI,   EVFSCTUF,   EVFSCTSF,
	EVFSCTUIZ,  EVFSCTSIZ,

	// EFS — single-precision scalar SPE FP
	EFSADD,     EFSSUB,     EFSABS,     EFSNABS,    EFSNEG,
	EFSMUL,     EFSDIV,
	EFSCMPGT,   EFSCMPLT,   EFSCMPEQ,
	EFSTSTGT,   EFSTSTLT,   EFSTSTEQ,
	EFSCFUI,    EFSCFSI,    EFSCFUF,    EFSCFSF,
	EFSCTUI,    EFSCTSI,    EFSCTUF,    EFSCTSF,
	EFSCTUIZ,   EFSCTSIZ,
	EFSCFD,

	// EFD — double-precision scalar SPE FP
	EFDADD,     EFDSUB,     EFDABS,     EFDNABS,    EFDNEG,
	EFDMUL,     EFDDIV,
	EFDCMPGT,   EFDCMPLT,   EFDCMPEQ,
	EFDTSTGT,   EFDTSTLT,   EFDTSTEQ,
	EFDCFUI,    EFDCFSI,    EFDCFUF,    EFDCFSF,
	EFDCTUI,    EFDCTSI,    EFDCTUF,    EFDCTSF,
	EFDCTUIZ,   EFDCTSIZ,
	EFDCFS,
	EFDCFSID,   EFDCFUID,   EFDCTSIDZ,  EFDCTUIDZ,

	// SPE multiply / multiply-accumulate (evm*)
	EVMHOSSF,   EVMHOSSFA,  EVMHOSSFAAW, EVMHOSSFANW,
	EVMHOSSIAAW, EVMHOSSIANW,
	EVMHOSMF,   EVMHOSMFA,  EVMHOSMFAAW, EVMHOSMFANW,
	EVMHOSMI,   EVMHOSMIA,  EVMHOSMIAAW, EVMHOSMIANW,
	EVMHESMF,   EVMHESMFA,  EVMHESMFAAW, EVMHESMFANW,
	EVMHESMI,   EVMHESMIA,  EVMHESMIAAW, EVMHESMIANW,
	EVMHESSF,   EVMHESSFA,  EVMHESSFAAW, EVMHESSFANW,
	EVMHESSIAAW, EVMHESSIANW,
	EVMHEUMI,   EVMHEUMIA,  EVMHEUMIAAW, EVMHEUMIANW,
	EVMHEUSIAAW, EVMHEUSIANW,
	EVMHOUMI,   EVMHOUMIA,  EVMHOUMIAAW, EVMHOUMIANW,
	EVMHOUSIAAW, EVMHOUSIANW,
	EVMHOGSMFAA, EVMHOGSMFAN,
	EVMHOGSMIAA, EVMHOGSMIAN,
	EVMHOGUMIAA, EVMHOGUMIAN,
	EVMHEGSMFAA, EVMHEGSMFAN,
	EVMHEGSMIAA, EVMHEGSMIAN,
	EVMHEGUMIAA, EVMHEGUMIAN,
	EVMWHSSF,   EVMWHSSFA,
	EVMWLSSIAAW, EVMWLSSIANW,
	EVMWHSMF,   EVMWHSMFA,
	EVMWHSMI,   EVMWHSMIA,
	EVMWHUMI,   EVMWHUMIA,
	EVMWLSMIAAW, EVMWLSMIANW,
	EVMWLUMI,   EVMWLUMIA,  EVMWLUMIAAW, EVMWLUMIANW,
	EVMWLUSIAAW, EVMWLUSIANW,
	EVMWSMF,    EVMWSMFA,   EVMWSMFAA,  EVMWSMFAN,
	EVMWSMI,    EVMWSMIA,   EVMWSMIAA,  EVMWSMIAN,
	EVMWSSF,    EVMWSSFA,   EVMWSSFAA,  EVMWSSFAN,
	EVMWUMI,    EVMWUMIA,   EVMWUMIAA,  EVMWUMIAN,
	BRINC,                                         // SPE bit-reverse increment

	// SPE X-form indexed memory (additional)
	EVLWHSPLATX,  EVLWWSPLATX, EVLHHESPLATX, EVLHHOSSPLATX, EVLHHOUSPLATX,
	EVLWHOUX,     EVLWHOSX,    EVSTWWEX,     EVSTWWOX,      EVSTWHOX,

	// -------------------------------------------------------------------------
	// §34 BookE / embedded - additions found via LLVM probing
	// -------------------------------------------------------------------------
	ICBTLS,     ICBLC,                             // I-cache hint+lock
	DCBST,      MBAR,                              // cache / barrier
	MTDCR,      MFDCR,                             // Device Control Register
	TLBILXVA,                                      // TLB invalidate local (va variant)

	// -------------------------------------------------------------------------
	// §35 POWER9 VSX additions found via LLVM probing
	// -------------------------------------------------------------------------
	XSCVSXDSP,  XSCVUXDSP,                         // VSX scalar conversion to single
	XXBRH,      XXBRW,      XXBRD,      XXBRQ,     // VSX byte-reverse (POWER9)

	// -------------------------------------------------------------------------
	// §36 POWER10 scalar bit-manipulation additions
	// -------------------------------------------------------------------------
	PDEPD,      PEXTD,                              // parallel bit deposit/extract
	CNTLZDM,    CNTTZDM,                            // count leading/trailing zeros (masked)
	CFUGED,                                         // center-from-ungate doubleword
	BRH,        BRW,        BRD,                    // byte-reverse half/word/doubleword

	// -------------------------------------------------------------------------
	// §37 Extended-divide OE-variants (POWER7+)
	// -------------------------------------------------------------------------
	DIVWEO,     DIVWEUO,    DIVDEO,     DIVDEUO,

	// -------------------------------------------------------------------------
	// §38 POWER10 VSX small additions
	// -------------------------------------------------------------------------
	XVTLSBB,    XVCVHPSP,   XVCVSPHP,   XXPERMR,

	// -------------------------------------------------------------------------
	// §39 SPE/EFS2 FP MADD/MSUB + scalar extensions
	// -------------------------------------------------------------------------
	// From binutils PPCSPE/PPCEFS2 sets. LLVM 22 lacks these mnemonics, so
	// they will be marked expected_unknown like bctar/lswx/prtyw. Bit patterns
	// are derived from binutils opcodes/ppc-opc.c.
	EVFSMADD,   EVFSMSUB,   EVFSNMADD,  EVFSNMSUB,    // SPE vector single MADD
	EFSMADD,    EFSMSUB,    EFSNMADD,   EFSNMSUB,     // EFS2 scalar single MADD
	EFDMADD,    EFDMSUB,    EFDNMADD,   EFDNMSUB,     // EFS2 scalar double MADD

	// EFS2 max/min/sqrt/half-precision conversion (scalar+vector)
	EVFSSQRT,   EVFSMAX,    EVFSMIN,    EVFSCFH,    EVFSCTH,
	EVFSADDSUB, EVFSSUBADD, EVFSSUM,    EVFSDIFF,   EVFSSUMDIFF, EVFSDIFFSUM,
	EVFSADDX,   EVFSSUBX,   EVFSADDSUBX, EVFSSUBADDX,
	EVFSMULX,   EVFSMULE,   EVFSMULO,
	EFSSQRT,    EFSMAX,     EFSMIN,     EFSCFH,     EFSCTH,
	EFDSQRT,    EFDMAX,     EFDMIN,     EFDCFH,     EFDCTH,

	// -------------------------------------------------------------------------
	// §40 Full SPE2 / EFS2 vector family (Freescale e6500/e500z extension)
	// -------------------------------------------------------------------------
	// 838 entries derived from binutils ppc-opc.c PPCSPE2 set. None of these
	// are in LLVM 22's tablegen — they're all expected_unknown in the verifier.
	EVSUBW, EVSUBIW, EVNEG, EVRNDW, EVMR, EVNOT, EVSADD, EVSSUB,
	EVSABS, EVSNABS, EVSNEG, EVSMUL, EVSDIV, EVSCMPGT, EVSGMPLT, EVSGMPEQ,
	EVSCFUI, EVSCFSI, EVSCFUF, EVSCFSF, EVSCTUI, EVSCTSI, EVSCTUF, EVSCTSF,
	EVSCTUIZ, EVSCTSIZ, EVSTSTGT, EVSTSTLT, EVSTSTEQ, EVMWLSSF, EVMWLSMF, EVMWLSSFA,
	EVMWLSMFA, EVADDUSIAAW, EVADDSSIAAW, EVSUBFUSIAAW, EVSUBFSSIAAW, EVADDUMIAAW, EVADDSMIAAW, EVSUBFUMIAAW,
	EVSUBFSMIAAW, EVMWLSSFAAW, EVMWHUSIAA, EVMWHSSMAA, EVMWHSSFAA, EVMWLSMFAAW, EVMWHUMIAA, EVMWHSMIAA,
	EVMWHSMFAA, EVMWHGUMIAA, EVMWHGSMIAA, EVMWHGSSFAA, EVMWHGSMFAA, EVMWLSSFANW, EVMWHUSIAN, EVMWHSSIAN,
	EVMWHSSFAN, EVMWLSMFANW, EVMWHUMIAN, EVMWHSMIAN, EVMWHSMFAN, EVMWHGUMIAN, EVMWHGSMIAN, EVMWHGSSFAN,
	EVMWHGSMFAN, EVDOTPWCSSI, EVDOTPWCSMI, EVDOTPWCSSFR, EVDOTPWCSSF, EVDOTPWGASMF, EVDOTPWXGASMF, EVDOTPWGASMFR,
	EVDOTPWXGASMFR, EVDOTPWGSSMF, EVDOTPWXGSSMF, EVDOTPWGSSMFR, EVDOTPWXGSSMFR, EVDOTPWCSSIAAW3, EVDOTPWCSMIAAW3, EVDOTPWCSSFRAAW3,
	EVDOTPWCSSFAAW3, EVDOTPWGASMFAA3, EVDOTPWXGASMFAA3, EVDOTPWGASMFRAA3, EVDOTPWXGASMFRAA3, EVDOTPWGSSMFAA3, EVDOTPWXGSSMFAA3, EVDOTPWGSSMFRAA3,
	EVDOTPWXGSSMFRAA3, EVDOTPWCSSIA, EVDOTPWCSMIA, EVDOTPWCSSFRA, EVDOTPWCSSFA, EVDOTPWGASMFA, EVDOTPWXGASMFA, EVDOTPWGASMFRA,
	EVDOTPWXGASMFRA, EVDOTPWGSSMFA, EVDOTPWXGSSMFA, EVDOTPWGSSMFRA, EVDOTPWXGSSMFRA, EVDOTPWCSSIAAW, EVDOTPWCSMIAAW, EVDOTPWCSSFRAAW,
	EVDOTPWCSSFAAW, EVDOTPWGASMFAA, EVDOTPWXGASMFAA, EVDOTPWGASMFRAA, EVDOTPWXGASMFRAA, EVDOTPWGSSMFAA, EVDOTPWXGSSMFAA, EVDOTPWGSSMFRAA,
	EVDOTPWXGSSMFRAA, EVDOTPHIHCSSI, EVDOTPLOHCSSI, EVDOTPHIHCSSF, EVDOTPLOHCSSF, EVDOTPHIHCSMI, EVDOTPLOHCSMI, EVDOTPHIHCSSFR,
	EVDOTPLOHCSSFR, EVDOTPHIHCSSIAAW3, EVDOTPLOHCSSIAAW3, EVDOTPHIHCSSFAAW3, EVDOTPLOHCSSFAAW3, EVDOTPHIHCSMIAAW3, EVDOTPLOHCSMIAAW3, EVDOTPHIHCSSFRAAW3,
	EVDOTPLOHCSSFRAAW3, EVDOTPHIHCSSIA, EVDOTPLOHCSSIA, EVDOTPHIHCSSFA, EVDOTPLOHCSSFA, EVDOTPHIHCSMIA, EVDOTPLOHCSMIA, EVDOTPHIHCSSFRA,
	EVDOTPLOHCSSFRA, EVDOTPHIHCSSIAAW, EVDOTPLOHCSSIAAW, EVDOTPHIHCSSFAAW, EVDOTPLOHCSSFAAW, EVDOTPHIHCSMIAAW, EVDOTPLOHCSMIAAW, EVDOTPHIHCSSFRAAW,
	EVDOTPLOHCSSFRAAW, EVDOTPHAUSI, EVDOTPHASSI, EVDOTPHASUSI, EVDOTPHASSF, EVDOTPHSSSF, EVDOTPHAUMI, EVDOTPHASMI,
	EVDOTPHASUMI, EVDOTPHASSFR, EVDOTPHSSMI, EVDOTPHSSSI, EVDOTPHSSSFR, EVDOTPHAUSIAAW3, EVDOTPHASSIAAW3, EVDOTPHASUSIAAW3,
	EVDOTPHASSFAAW3, EVDOTPHSSSIAAW3, EVDOTPHSSSFAAW3, EVDOTPHAUMIAAW3, EVDOTPHASMIAAW3, EVDOTPHASUMIAAW3, EVDOTPHASSFRAAW3, EVDOTPHSSMIAAW3,
	EVDOTPHSSSFRAAW3, EVDOTPHAUSIA, EVDOTPHASSIA, EVDOTPHASUSIA, EVDOTPHASSFA, EVDOTPHSSSFA, EVDOTPHAUMIA, EVDOTPHASMIA,
	EVDOTPHASUMIA, EVDOTPHASSFRA, EVDOTPHSSMIA, EVDOTPHSSSIA, EVDOTPHSSSFRA, EVDOTPHAUSIAAW, EVDOTPHASSIAAW, EVDOTPHASUSIAAW,
	EVDOTPHASSFAAW, EVDOTPHSSSIAAW, EVDOTPHSSSFAAW, EVDOTPHAUMIAAW, EVDOTPHASMIAAW, EVDOTPHASUMIAAW, EVDOTPHASSFRAAW, EVDOTPHSSMIAAW,
	EVDOTPHSSSFRAAW, EVDOTP4HGAUMI, EVDOTP4HGASMI, EVDOTP4HGASUMI, EVDOTP4HGASMF, EVDOTP4HGSSMI, EVDOTP4HGSSMF, EVDOTP4HXGASMI,
	EVDOTP4HXGASMF, EVDOTPBAUMI, EVDOTPBASMI, EVDOTPBASUMI, EVDOTP4HXGSSMI, EVDOTP4HXGSSMF, EVDOTP4HGAUMIAA3, EVDOTP4HGASMIAA3,
	EVDOTP4HGASUMIAA3, EVDOTP4HGASMFAA3, EVDOTP4HGSSMIAA3, EVDOTP4HGSSMFAA3, EVDOTP4HXGASMIAA3, EVDOTP4HXGASMFAA3, EVDOTPBAUMIAAW3, EVDOTPBASMIAAW3,
	EVDOTPBASUMIAAW3, EVDOTP4HXGSSMIAA3, EVDOTP4HXGSSMFAA3, EVDOTP4HGAUMIA, EVDOTP4HGASMIA, EVDOTP4HGASUMIA, EVDOTP4HGASMFA, EVDOTP4HGSSMIA,
	EVDOTP4HGSSMFA, EVDOTP4HXGASMIA, EVDOTP4HXGASMFA, EVDOTPBAUMIA, EVDOTPBASMIA, EVDOTPBASUMIA, EVDOTP4HXGSSMIA, EVDOTP4HXGSSMFA,
	EVDOTP4HGAUMIAA, EVDOTP4HGASMIAA, EVDOTP4HGASUMIAA, EVDOTP4HGASMFAA, EVDOTP4HGSSMIAA, EVDOTP4HGSSMFAA, EVDOTP4HXGASMIAA, EVDOTP4HXGASMFAA,
	EVDOTPBAUMIAAW, EVDOTPBASMIAAW, EVDOTPBASUMIAAW, EVDOTP4HXGSSMIAA, EVDOTP4HXGSSMFAA, EVDOTPWAUSI, EVDOTPWASSI, EVDOTPWASUSI,
	EVDOTPWAUMI, EVDOTPWASMI, EVDOTPWASUMI, EVDOTPWSSMI, EVDOTPWSSSI, EVDOTPWAUSIAA3, EVDOTPWASSIAA3, EVDOTPWASUSIAA3,
	EVDOTPWSSSIAA3, EVDOTPWAUMIAA3, EVDOTPWASMIAA3, EVDOTPWASUMIAA3, EVDOTPWSSMIAA3, EVDOTPWAUSIA, EVDOTPWASSIA, EVDOTPWASUSIA,
	EVDOTPWAUMIA, EVDOTPWASMIA, EVDOTPWASUMIA, EVDOTPWSSMIA, EVDOTPWSSSIA, EVDOTPWAUSIAA, EVDOTPWASSIAA, EVDOTPWASUSIAA,
	EVDOTPWSSSIAA, EVDOTPWAUMIAA, EVDOTPWASMIAA, EVDOTPWASUMIAA, EVDOTPWSSMIAA, EVADDIB, EVADDIH, EVSUBIFH,
	EVSUBIFB, EVABSB, EVABSH, EVABSD, EVABSS, EVABSBS, EVABSHS, EVABSDS,
	EVNEGWO, EVNEGB, EVNEGBO, EVNEGH, EVNEGHO, EVNEGD, EVNEGS, EVNEGWOS,
	EVNEGBS, EVNEGBOS, EVNEGHS, EVNEGHOS, EVNEGDS, EVEXTZB, EVEXTSBH, EVEXTSW,
	EVRNDWH, EVRNDHB, EVRNDDW, EVRNDWHUS, EVRNDWHSS, EVRNDHBUS, EVRNDHBSS, EVRNDDWUS,
	EVRNDDWSS, EVRNDWNH, EVRNDHNB, EVRNDDNW, EVRNDWNHUS, EVRNDWNHSS, EVRNDHNBUS, EVRNDHNBSS,
	EVRNDDNWUS, EVRNDDNWSS, EVCNTLZH, EVCNTLSH, EVPOPCNTB, CIRCINC, EVUNPKHIBUI, EVUNPKHIBSI,
	EVUNPKHIHUI, EVUNPKHIHSI, EVUNPKLOBUI, EVUNPKLOBSI, EVUNPKLOHUI, EVUNPKLOHSI, EVUNPKLOHF, EVUNPKHIHF,
	EVUNPKLOWGSF, EVUNPKHIWGSF, EVSATSDUW, EVSATSDSW, EVSATSHUB, EVSATSHSB, EVSATUWUH, EVSATSWSH,
	EVSATSWUH, EVSATUHUB, EVSATUDUW, EVSATUWSW, EVSATSHUH, EVSATUHSH, EVSATSWUW, EVSATSWGSDF,
	EVSATSBUB, EVSATUBSB, EVMAXHPUW, EVMAXHPSW, EVMAXBPUH, EVMAXBPSH, EVMAXWPUD, EVMAXWPSD,
	EVMINHPUW, EVMINHPSW, EVMINBPUH, EVMINBPSH, EVMINWPUD, EVMINWPSD, EVMAXMAGWS, EVSL,
	EVSLI, EVSPLATIE, EVSPLATIB, EVSPLATIBE, EVSPLATIH, EVSPLATIHE, EVSPLATID, EVSPLATIA,
	EVSPLATIEA, EVSPLATIBA, EVSPLATIBEA, EVSPLATIHA, EVSPLATIHEA, EVSPLATIDA, EVSPLATFIO, EVSPLATFIB,
	EVSPLATFIBO, EVSPLATFIH, EVSPLATFIHO, EVSPLATFID, EVSPLATFIA, EVSPLATFIOA, EVSPLATFIBA, EVSPLATFIBOA,
	EVSPLATFIHA, EVSPLATFIHOA, EVSPLATFIDA, EVCMPGTDU, EVCMPGTDS, EVCMPLTDU, EVCMPLTDS, EVCMPEQD,
	EVSWAPBHILO, EVSWAPBLOHI, EVSWAPHHILO, EVSWAPHLOHI, EVSWAPHE, EVSWAPHHI, EVSWAPHLO, EVSWAPHO,
	EVINSB, EVXTRB, EVSPLATH, EVSPLATB, EVINSH, EVCLRBE, EVCLRBO, EVCLRH,
	EVXTRH, EVSELBITM0, EVSELBITM1, EVSELBIT, EVPERM, EVPERM2, EVPERM3, EVXTRD,
	EVSRBU, EVSRBS, EVSRBIU, EVSRBIS, EVSLB, EVRLB, EVSLBI, EVRLBI,
	EVSRHU, EVSRHS, EVSRHIU, EVSRHIS, EVSLH, EVRLH, EVSLHI, EVRLHI,
	EVSRU, EVSRS, EVSRIU, EVSRIS, EVLVSL, EVLVSR, EVSROIU, EVSROIS,
	EVSLOI, EVLDBX, EVLDB, EVLHHSPLATHX, EVLHHSPLATH, EVLWBSPLATWX, EVLWBSPLATW, EVLWHSPLATWX,
	EVLWHSPLATW, EVLBBSPLATBX, EVLBBSPLATB, EVSTDBX, EVSTDB, EVLWBEX, EVLWBE, EVLWBOUX,
	EVLWBOU, EVLWBOSX, EVLWBOS, EVSTWBEX, EVSTWBE, EVSTWBOX, EVSTWBO, EVSTWBX,
	EVSTWB, EVSTHBX, EVSTHB, EVLDDMX, EVLDDU, EVLDWMX, EVLDWU, EVLDHMX,
	EVLDHU, EVLDBMX, EVLDBU, EVLHHESPLATMX, EVLHHESPLATU, EVLHHSPLATHMX, EVLHHSPLATHU, EVLHHOUSPLATMX,
	EVLHHOUSPLATU, EVLHHOSSPLATMX, EVLHHOSSPLATU, EVLWHEMX, EVLWHEU, EVLWBSPLATWMX, EVLWBSPLATWU, EVLWHOUMX,
	EVLWHOUU, EVLWHOSMX, EVLWHOSU, EVLWWSPLATMX, EVLWWSPLATU, EVLWHSPLATWMX, EVLWHSPLATWU, EVLWHSPLATMX,
	EVLWHSPLATU, EVLBBSPLATBMX, EVLBBSPLATBU, EVSTDDMX, EVSTDDU, EVSTDWMX, EVSTDWU, EVSTDHMX,
	EVSTDHU, EVSTDBMX, EVSTDBU, EVLWBEMX, EVLWBEU, EVLWBOUMX, EVLWBOUU, EVLWBOSMX,
	EVLWBOSU, EVSTWHEMX, EVSTWHEU, EVSTWBEMX, EVSTWBEU, EVSTWHOMX, EVSTWHOU, EVSTWBOMX,
	EVSTWBOU, EVSTWWEMX, EVSTWWEU, EVSTWBMX, EVSTWBU, EVSTWWOMX, EVSTWWOU, EVSTHBMX,
	EVSTHBU, EVMHUSI, EVMHSSI, EVMHSUSI, EVMHSSF, EVMHUMI, EVMHSSFR, EVMHESUMI,
	EVMHOSUMI, EVMBEUMI, EVMBESMI, EVMBESUMI, EVMBOUMI, EVMBOSMI, EVMBOSUMI, EVMHESUMIA,
	EVMHOSUMIA, EVMBEUMIA, EVMBESMIA, EVMBESUMIA, EVMBOUMIA, EVMBOSMIA, EVMBOSUMIA, EVMWUSIW,
	EVMWSSIW, EVMWHSSFR, EVMWEHGSMFR, EVMWEHGSMF, EVMWOHGSMFR, EVMWOHGSMF, EVMWHSSFRA, EVMWEHGSMFRA,
	EVMWEHGSMFA, EVMWOHGSMFRA, EVMWOHGSMFA, EVADDUSIAA, EVADDSSIAA, EVSUBFUSIAA, EVSUBFSSIAA, EVADDSMIAA,
	EVSUBFSMIAA, EVADDH, EVADDHSS, EVSUBFH, EVSUBFHSS, EVADDHX, EVADDHXSS, EVSUBFHX,
	EVSUBFHXSS, EVADDD, EVADDDSS, EVSUBFD, EVSUBFDSS, EVADDB, EVADDBSS, EVSUBFB,
	EVSUBFBSS, EVADDSUBFH, EVADDSUBFHSS, EVSUBFADDH, EVSUBFADDHSS, EVADDSUBFHX, EVADDSUBFHXSS, EVSUBFADDHX,
	EVSUBFADDHXSS, EVADDDUS, EVADDBUS, EVSUBFDUS, EVSUBFBUS, EVADDWUS, EVADDWXUS, EVSUBFWUS,
	EVSUBFWXUS, EVADD2SUBF2H, EVADD2SUBF2HSS, EVSUBF2ADD2H, EVSUBF2ADD2HSS, EVADDHUS, EVADDHXUS, EVSUBFHUS,
	EVSUBFHXUS, EVADDWSS, EVSUBFWSS, EVADDWX, EVADDWXSS, EVSUBFWX, EVSUBFWXSS, EVADDSUBFW,
	EVADDSUBFWSS, EVSUBFADDW, EVSUBFADDWSS, EVADDSUBFWX, EVADDSUBFWXSS, EVSUBFADDWX, EVSUBFADDWXSS, EVMAR,
	EVSUMWU, EVSUMWS, EVSUM4BU, EVSUM4BS, EVSUM2HU, EVSUM2HS, EVDIFF2HIS, EVSUM2HIS,
	EVSUMWUA, EVSUMWSA, EVSUM4BUA, EVSUM4BSA, EVSUM2HUA, EVSUM2HSA, EVDIFF2HISA, EVSUM2HISA,
	EVSUMWUAA, EVSUMWSAA, EVSUM4BUAAW, EVSUM4BSAAW, EVSUM2HUAAW, EVSUM2HSAAW, EVDIFF2HISAAW, EVSUM2HISAAW,
	EVDIVWSF, EVDIVWUF, EVDIVS, EVDIVU, EVADDWEGSI, EVADDWEGSF, EVSUBFWEGSI, EVSUBFWEGSF,
	EVADDWOGSI, EVADDWOGSF, EVSUBFWOGSI, EVSUBFWOGSF, EVADDHHIUW, EVADDHHISW, EVSUBFHHIUW, EVSUBFHHISW,
	EVADDHLOUW, EVADDHLOSW, EVSUBFHLOUW, EVSUBFHLOSW, EVMHESUSIAAW, EVMHOSUSIAAW, EVMHESUMIAAW, EVMHOSUMIAAW,
	EVMBEUSIAAH, EVMBESSIAAH, EVMBESUSIAAH, EVMBOUSIAAH, EVMBOSSIAAH, EVMBOSUSIAAH, EVMBEUMIAAH, EVMBESMIAAH,
	EVMBESUMIAAH, EVMBOUMIAAH, EVMBOSMIAAH, EVMBOSUMIAAH, EVMWLUSIAAW3, EVMWLSSIAAW3, EVMWHSSFRAAW3, EVMWHSSFAAW3,
	EVMWHSSFRAAW, EVMWHSSFAAW, EVMWLUMIAAW3, EVMWLSMIAAW3, EVMWUSIAA, EVMWSSIAA, EVMWEHGSMFRAA, EVMWEHGSMFAA,
	EVMWOHGSMFRAA, EVMWOHGSMFAA, EVMHESUSIANW, EVMHOSUSIANW, EVMHESUMIANW, EVMHOSUMIANW, EVMBEUSIANH, EVMBESSIANH,
	EVMBESUSIANH, EVMBOUSIANH, EVMBOSSIANH, EVMBOSUSIANH, EVMBEUMIANH, EVMBESMIANH, EVMBESUMIANH, EVMBOUMIANH,
	EVMBOSMIANH, EVMBOSUMIANH, EVMWLUSIANW3, EVMWLSSIANW3, EVMWHSSFRANW3, EVMWHSSFANW3, EVMWHSSFRANW, EVMWHSSFANW,
	EVMWLUMIANW3, EVMWLSMIANW3, EVMWUSIAN, EVMWSSIAN, EVMWEHGSMFRAN, EVMWEHGSMFAN, EVMWOHGSMFRAN, EVMWOHGSMFAN,
	EVSETEQB, EVSETEQH, EVSETEQW, EVSETGTHU, EVSETGTHS, EVSETGTWU, EVSETGTWS, EVSETGTBU,
	EVSETGTBS, EVSETLTBU, EVSETLTBS, EVSETLTHU, EVSETLTHS, EVSETLTWU, EVSETLTWS, EVSADUW,
	EVSADSW, EVSAD4UB, EVSAD4SB, EVSAD2UH, EVSAD2SH, EVSADUWA, EVSADSWA, EVSAD4UBA,
	EVSAD4SBA, EVSAD2UHA, EVSAD2SHA, EVABSDIFUW, EVABSDIFSW, EVABSDIFUB, EVABSDIFSB, EVABSDIFUH,
	EVABSDIFSH, EVSADUWAA, EVSADSWAA, EVSAD4UBAAW, EVSAD4SBAAW, EVSAD2UHAAW, EVSAD2SHAAW, EVPKSHUBS,
	EVPKSHSBS, EVPKSWUHS, EVPKSWSHS, EVPKUHUBS, EVPKUWUHS, EVPKSWSHILVS, EVPKSWGSHEFRS, EVPKSWSHFRS,
	EVPKSWSHILVFRS, EVPKSDSWFRS, EVPKSDSHEFRS, EVPKUDUWS, EVPKSDSWS, EVPKSWGSWFRS, EVILVEH, EVILVEOH,
	EVILVHIH, EVILVHILOH, EVILVLOH, EVILVLOHIH, EVILVOEH, EVILVOH, EVDLVEB, EVDLVEH,
	EVDLVEOB, EVDLVEOH, EVDLVOB, EVDLVOH, EVDLVOEB, EVDLVOEH, EVMAXBU, EVMAXBS,
	EVMAXHU, EVMAXHS, EVMAXWU, EVMAXWS, EVMAXDU, EVMAXDS, EVMINBU, EVMINBS,
	EVMINHU, EVMINHS, EVMINWU, EVMINWS, EVMINDU, EVMINDS, EVAVGWU, EVAVGWS,
	EVAVGBU, EVAVGBS, EVAVGHU, EVAVGHS, EVAVGDU, EVAVGDS, EVAVGWUR, EVAVGWSR,
	EVAVGBUR, EVAVGBSR, EVAVGHUR, EVAVGHSR, EVAVGDUR, EVAVGDSR,

	// -------------------------------------------------------------------------
	// §41 Paired Singles (Gekko/Broadway — GameCube + Wii)
	// -------------------------------------------------------------------------
	// 62 entries from binutils PPCPS set. LLVM 22 lacks all of these.
	// Bit patterns from Gekko/Broadway User's Manual §1.2.4 (A/X/XOPS/XW forms,
	// primary opcode 4 sharing space with AltiVec/SPE — disambiguated by XO).
	PS_DIV,      PS_DIV_DOT,
	PS_SUB,      PS_SUB_DOT,
	PS_ADD,      PS_ADD_DOT,
	PS_SEL,      PS_SEL_DOT,
	PS_RES,      PS_RES_DOT,
	PS_MUL,      PS_MUL_DOT,
	PS_RSQRTE,   PS_RSQRTE_DOT,
	PS_MSUB,     PS_MSUB_DOT,
	PS_MADD,     PS_MADD_DOT,
	PS_NMSUB,    PS_NMSUB_DOT,
	PS_NMADD,    PS_NMADD_DOT,
	PS_SUM0,     PS_SUM0_DOT,
	PS_SUM1,     PS_SUM1_DOT,
	PS_MULS0,    PS_MULS0_DOT,
	PS_MULS1,    PS_MULS1_DOT,
	PS_MADDS0,   PS_MADDS0_DOT,
	PS_MADDS1,   PS_MADDS1_DOT,
	PS_NEG,      PS_NEG_DOT,
	PS_MR,       PS_MR_DOT,
	PS_NABS,     PS_NABS_DOT,
	PS_ABS,      PS_ABS_DOT,
	PS_CMPU0,    PS_CMPU1,    PS_CMPO0,    PS_CMPO1,
	PS_MERGE00,  PS_MERGE00_DOT,
	PS_MERGE01,  PS_MERGE01_DOT,
	PS_MERGE10,  PS_MERGE10_DOT,
	PS_MERGE11,  PS_MERGE11_DOT,
	// Paired single quantized loads/stores (use GQR0..GQR7 SPRs for format)
	PSQ_LX,      PSQ_LUX,     PSQ_STX,     PSQ_STUX,
	PSQ_L,       PSQ_LU,      PSQ_ST,      PSQ_STU,

	// -------------------------------------------------------------------------
	// §42 VMX128 (Xenon — Xbox 360 vector extension; 128-register VR file)
	// -------------------------------------------------------------------------
	// ~60 entries. LLVM 22 and binutils lack VMX128 entirely — bit patterns
	// sourced from the xenia Xbox 360 emulator's disassembler tables and the
	// Free60 wiki. All classified as expected_unknown.
	//
	// VMX128 uses primary opcodes 4 and 5 (5 was unused in standard PPC).
	// Register fields are 7-bit, with the extra 2 bits scattered. We model
	// these as bake-everything: encoder emits the canonical bit pattern for
	// each mnemonic, and users construct via the Instruction builders.

	// ---- Arithmetic / FP ----
	VADDFP128,      VSUBFP128,      VMULFP128,
	VMADDFP128,     VMADDCFP128,    VNMSUBFP128,
	VMSUM3FP128,    VMSUM4FP128,
	VMAXFP128,      VMINFP128,
	VREFP128,       VRSQRTEFP128,   VEXPTEFP128,    VLOGEFP128,

	// ---- Logical ----
	VAND128,        VANDC128,       VOR128,         VXOR128,        VNOR128,
	VSEL128,

	// ---- Compare ----
	VCMPEQFP128,    VCMPEQFP128_DOT,
	VCMPGEFP128,    VCMPGEFP128_DOT,
	VCMPGTFP128,    VCMPGTFP128_DOT,
	VCMPBFP128,     VCMPBFP128_DOT,
	VCMPEQUW128,    VCMPEQUW128_DOT,

	// ---- Rounding ----
	VRFIM128,       VRFIN128,       VRFIP128,       VRFIZ128,

	// ---- Convert ----
	VCFPSXWS128,    VCFPUXWS128,    VCSXWFP128,     VCUXWFP128,

	// ---- Splat / merge / permute ----
	VSPLTW128,      VSPLTISW128,
	VMRGHW128,      VMRGLW128,
	VPKD3D128,      VUPKD3D128,
	VPERM128,       VPERMWI128,     VRLIMI128,
	VSLDOI128,

	// ---- Shift / rotate ----
	VRLW128,        VSLW128,        VSRW128,        VSRAW128,

	// ---- Memory (load/store indexed) ----
	LVEBX128,       LVEHX128,       LVEWX128,       LVX128,         LVXL128,
	LVLX128,        LVRX128,        LVLXL128,       LVRXL128,
	STVEBX128,      STVEHX128,      STVEWX128,      STVX128,        STVXL128,
	STVLX128,       STVRX128,       STVLXL128,      STVRXL128,


	// -------------------------------------------------------------------------
	// §43 Remaining binutils PPC categories (MULHW/M601/PWRCOM/PPCCOM/PPCA2/
	//     E6500/PPC403/405/440/476/TITAN/CELL/etc.) — 518 entries.
	// -------------------------------------------------------------------------
	// LLVM 22 lacks most of these; all classified as expected_unknown.
	TI, MULHHWU, MULHHWU_DOT, MACHHWU, MACHHWU_DOT, MULHHW, MULHHW_DOT, MACHHW,
	MACHHW_DOT, NMACHHW, NMACHHW_DOT, MACHHWSU, MACHHWSU_DOT, MACHHWS, MACHHWS_DOT, NMACHHWS,
	NMACHHWS_DOT, VADDUQM, VCMPUQ, MULCHWU, MULCHWU_DOT, MACCHWU, MACCHWU_DOT, VCMPSQ,
	MULCHW, MULCHW_DOT, MACCHW, MACCHW_DOT, NMACCHW, NMACCHW_DOT, MACCHWSU, MACCHWSU_DOT,
	VCMPEQUQ, MACCHWS, MACCHWS_DOT, NMACCHWS, NMACCHWS_DOT, VCMPGTUQ, VCUXWFP, MULLHWU,
	MULLHWU_DOT, MACLHWU, MACLHWU_DOT, VCSXWFP, MULLHW, MULLHW_DOT, MACLHW, MACLHW_DOT,
	NMACLHW, NMACLHW_DOT, VCMPGTSQ, VCFPUXWS, MACLHWSU, MACLHWSU_DOT, VCFPSXWS, MACLHWS,
	MACLHWS_DOT, NMACLHWS, NMACLHWS_DOT, MACHHWUO, MACHHWUO_DOT, MACHHWO, MACHHWO_DOT, NMACHHWO,
	NMACHHWO_DOT, VMR, MACHHWSUO, MACHHWSUO_DOT, MACHHWSO, MACHHWSO_DOT, NMACHHWSO, NMACHHWSO_DOT,
	VSUBUQM, VNOT, VGBBD, MACCHWUO, MACCHWUO_DOT, MACCHWO, MACCHWO_DOT, NMACCHWO,
	NMACCHWO_DOT, MACCHWSUO, MACCHWSUO_DOT, VCMPEQUQ_DOT, MACCHWSO, MACCHWSO_DOT, NMACCHWSO, NMACCHWSO_DOT,
	VCMPGTUQ_DOT, MACLHWUO, MACLHWUO_DOT, MACLHWO, MACLHWO_DOT, NMACLHWO, NMACLHWO_DOT, VCMPGTSQ_DOT,
	MACLHWSUO, MACLHWSUO_DOT, MACLHWSO, MACLHWSO_DOT, NMACLHWSO, NMACLHWSO_DOT, DCBZ_L, MULI,
	SFI, DOZI, AI, SUBIC, AI_DOT, SUBIC_DOT, LIL, CAL,
	SUBI, LIU, CAU, SUBIS, CRNOT, RFCI, RFSCV, RFSVC,
	RFGI, ICS, CRCLR, DNH, CRSET, URFID, DOZE, CRMOVE,
	SLEEP, RVWINKLE, ORIL, ORIU, XORIL, XORIU, ANDIL_DOT, ANDIU_DOT,
	ROTLDI_DOT, ROTRDI_DOT, CLRLDI_DOT, SRDI_DOT, EXTRDI_DOT, CLRRDI_DOT, SLDI_DOT, EXTLDI_DOT,
	CLRLSLDI, CLRLSLDI_DOT, INSRDI, INSRDI_DOT, ROTLD_DOT, T, SF, SF_DOT,
	A_DOT, LX, SL, SL_DOT, CNTLZ, CNTLZ_DOT, MASKG, MASKG_DOT,
	LDEPX, WAITASEC, MVIWSPLT, MFVSRD, ERATILX, LUX, SUBWUS, SUBWUS_DOT,
	SUBDUS, SUBDUS_DOT, SUBFUS, SUBFUS_DOT, DLMZB, DLMZB_DOT, DNI, MUL,
	MUL_DOT, MVIDSPLT, MTSRDIN, MFVSRWZ, CLF, DCBTSTLS, SFE, SFE_DOT,
	AE, AE_DOT, DCBTSTLSE, MTSLE, ERATSX, ERATSX_DOT, STX, SLQ,
	SLQ_DOT, SLE, SLE_DOT, STDEPX, DCBTLS, DCBTLSE, MTVSRD, ERATRE,
	WCHKALL, STUX, SLIQ, SLIQ_DOT, ICBLQ_DOT, SFZE, SFZE_DOT, AZE,
	AZE_DOT, MTVSRWA, ERATWE, LDAWX_DOT, SLLQ, SLLQ_DOT, SLEQ, SLEQ_DOT,
	SFME, SFME_DOT, AME, AME_DOT, MULS, MULS_DOT, ICBLCE, MTSRI,
	MTVSRWZ, DCBTSTCT, DCBTSTDS, SLLIQ, SLLIQ_DOT, MFDCRX, MFDCRX_DOT, LVEXBX,
	LVEPXL, DOZ, DOZ_DOT, CAX, CAX_DOT, EHPRIV, MFAPIDI, LSCBX,
	LSCBX_DOT, DCBTCT, DCBTDS, MFDCRUX, LVEXHX, LVEPX, MFBHRBE, TLBI,
	ECIWX, MFDCR_DOT, LVEXWX, DCREAD, DIV, DIV_DOT, MFTMR, ABS,
	ABS_DOT, DIVS, DIVS_DOT, LXVWSX, TLBIA, SETBC, MTDCRX, MTDCRX_DOT,
	STVEXBX, DCBLC, DCBLCE, PBT_DOT, ICSWX, ICSWX_DOT, SETBCR, MTDCRUX,
	STVEXHX, DCBLQ_DOT, CLRBHRB, ECOWX, SETNBC, MTDCR_DOT, STVEXWX, DCI,
	MTTMR, SETNBCR, DSN, NABS, NABS_DOT, ICBTLSE, CLI, MCRXR,
	LBDCBX, LBDX, BBLELS, LVLX, SUBFCO, SFO, SUBCO, SUBFCO_DOT,
	SFO_DOT, SUBCO_DOT, ADDCO, AO, ADDCO_DOT, AO_DOT, CLCS, LSX,
	LBRX, SR_DOT, RRIB, RRIB_DOT, MASKIR, MASKIR_DOT, LHDCBX, LHDX,
	LVTRX, BBELR, LVRX, SUBFO, SUBO, SUBFO_DOT, SUBO_DOT, LWDCBX,
	LWDX, LVTLX, LSI, DCS, MFFGPR, LDDX, LVSWX, NEGO,
	NEGO_DOT, MULO, MULO_DOT, MFSRI, DCLST, STBDCBX, STBDX, STVLX,
	SUBFEO, SFEO, SUBFEO_DOT, SFEO_DOT, ADDEO, AEO, ADDEO_DOT, AEO_DOT,
	HASHSTP, STSX, STBRX, SRQ, SRQ_DOT, SRE, SRE_DOT, STHDCBX,
	STHDX, STVFRX, STVRX, HASHCHKP, SRIQ, SRIQ_DOT, STWDCBX, STWDX,
	STVFLX, SUBFZEO, SFZEO, SUBFZEO_DOT, SFZEO_DOT, ADDZEO, AZEO, ADDZEO_DOT,
	AZEO_DOT, HASHST, STSI, SRLQ, SRLQ_DOT, SREQ, SREQ_DOT, MFTGPR,
	STDDX, STVSWX, SUBFMEO, SFMEO, SUBFMEO_DOT, SFMEO_DOT, MULLDO, MULLDO_DOT,
	ADDMEO, AMEO, ADDMEO_DOT, AMEO_DOT, MULLWO, MULSO, MULLWO_DOT, MULSO_DOT,
	TSR_DOT, HASHCHK, SRLIQ, SRLIQ_DOT, LVSM, STVEPXL, LVLXL, DOZO,
	DOZO_DOT, ADDO, CAXO, ADDO_DOT, CAXO_DOT, LFQX, SRA, SRA_DOT,
	EVLDDEPX, LFDDX, LVTRXL, STVEPX, LVRXL, RAC, ERATIVAX, LFQUX,
	SRAI, SRAI_DOT, LVTLXL, DIVO, DIVO_DOT, TLBSRX_DOT, SLBIAG, LVSWXL,
	ABSO, ABSO_DOT, DIVSO, DIVSO_DOT, RMIEG, STVLXL, DIVDEUO_DOT, DIVWEUO_DOT,
	TLBSX_DOT, STFQX, SRAQ, SRAQ_DOT, SREA, SREA_DOT, EXTS, EXTS_DOT,
	EVSTDDEPX, STFDDX, STVFRXL, WCLRALL, WCLR, STVRXL, DIVDEO_DOT, DIVWEO_DOT,
	ICSWEPX, ICSWEPX_DOT, STFQUX, SRAIQ, SRAIQ_DOT, STVFLXL, ICI, DIVDUO,
	DIVDUO_DOT, DIVWUO, DIVWUO_DOT, SLBFEE_DOT, STVSWXL, ICREAD, NABSO, NABSO_DOT,
	DIVDO, DIVDO_DOT, DIVWO, DIVWO_DOT, DCLZ, LU, ST, STU,
	LM, STM, LFQ, LFQU, STFQ, STFQU, FCIR, FCIR_DOT,
	FCIRZ, FCIRZ_DOT, FD, FD_DOT, FS, FS_DOT, FA, FA_DOT,
	FM, FM_DOT, FMS, FMS_DOT, FMA, FMA_DOT, FNMS, FNMS_DOT,
	FNMA, FNMA_DOT, DTSTEXQ, XSCMPEXPQP, DXEXQ, DXEXQ_DOT, DTSTSFQ, EVSETEQB_DOT,
	EVSETEQH_DOT, EVSETEQW_DOT, EVSETGTHU_DOT, EVSETGTHS_DOT, EVSETGTWU_DOT, EVSETGTWS_DOT, EVSETGTBU_DOT, EVSETGTBS_DOT,
	EVSETLTBU_DOT, EVSETLTBS_DOT, EVSETLTHU_DOT, EVSETLTHS_DOT, EVSETLTWU_DOT, EVSETLTWS_DOT,

	// -------------------------------------------------------------------------
}
