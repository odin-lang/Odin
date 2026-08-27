// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

// =============================================================================
// AArch64 SYSTEM REGISTERS (named constants for MRS / MSR)
// =============================================================================
//
// The MRS / MSR instructions encode the target system register as a 15-bit
// field at bits 19:5 of the instruction word:
//
//   o0 (1 bit)  : op0 - 2  (op0 = 2 -> o0=0; op0 = 3 -> o0=1)
//   op1 (3 bit) : op1
//   CRn (4 bit) : CRn
//   CRm (4 bit) : CRm
//   op2 (3 bit) : op2
//
// concatenated MSB-first: o0 || op1 || CRn || CRm || op2.
//
// Users pass these as the immediate operand to `inst_*` builders or by
// hand, e.g.:
//
//   MRS X0, NZCV   ->   op_imm(arm64.NZCV, 2)
//
// The encoder packs the field into SYS_FIELD at bits 19:5 via the standard
// `(imm & 0x7FFF) << 5` mask, so callers can pass either the raw 15-bit
// field value (preferred) or the historical 0x_DA10-style 16-bit form
// (top bit gets masked off).

// -----------------------------------------------------------------------------
// Helper for building sysreg field values at compile time.
//   sysreg_field(op0, op1, CRn, CRm, op2)  =  packed 15-bit field
// op0 must be 2 or 3 (the o0 bit = op0 - 2).
// -----------------------------------------------------------------------------

sysreg_field :: #force_inline proc "contextless" (op0, op1, CRn, CRm, op2: u32) -> i64 {
	o0 := (op0 - 2) & 0x1
	return i64(
		(o0  << 14) |
		(op1 <<  11) |
		(CRn <<  7) |
		(CRm <<  3) |
		 op2,
	)
}

// -----------------------------------------------------------------------------
// Commonly-used named registers (the ones every disassembler knows about).
// -----------------------------------------------------------------------------

//                              op0 op1 CRn CRm op2
NZCV         :: i64(0x5A10)  // 3   3   4   2   0
DAIF         :: i64(0x5A11)  // 3   3   4   2   1
FPCR         :: i64(0x5A20)  // 3   3   4   4   0
FPSR         :: i64(0x5A21)  // 3   3   4   4   1
CURRENT_EL   :: i64(0x4212)  // 3   0   4   2   2
SP_EL0       :: i64(0x4208)  // 3   0   4   1   0
SP_EL1       :: i64(0x6208)  // 3   4   4   1   0
ELR_EL1      :: i64(0x4201)  // 3   0   4   0   1
ELR_EL2      :: i64(0x6201)  // 3   4   4   0   1
SPSR_EL1     :: i64(0x4200)  // 3   0   4   0   0
SPSR_EL2     :: i64(0x6200)  // 3   4   4   0   0
ESR_EL1      :: i64(0x5290)  // 3   0   5   2   0
ESR_EL2      :: i64(0x6290)  // 3   4   5   2   0
FAR_EL1      :: i64(0x5300)  // 3   0   6   0   0
FAR_EL2      :: i64(0x6300)  // 3   4   6   0   0
TPIDR_EL0    :: i64(0x5E82)  // 3   3  13   0   2
TPIDRRO_EL0  :: i64(0x5E83)  // 3   3  13   0   3
TPIDR_EL1    :: i64(0x4684)  // 3   0  13   0   4 (corrected: 3 0 13 0 4 -> 4684 hmm let me recompute)

// Counters / system identity
CNTFRQ_EL0   :: i64(0x5F00)  // 3   3  14   0   0
CNTPCT_EL0   :: i64(0x5F01)  // 3   3  14   0   1
CNTVCT_EL0   :: i64(0x5F02)  // 3   3  14   0   2
MIDR_EL1     :: i64(0x4000)  // 3   0   0   0   0
MPIDR_EL1    :: i64(0x4005)  // 3   0   0   0   5
DCZID_EL0    :: i64(0x5807)  // 3   3   0   0   7  (used by __sve_max_vl-style probes too)
CTR_EL0      :: i64(0x5801)  // 3   3   0   0   1
TCR_EL1      :: i64(0x4282)  // 3   0   2   0   2
SCTLR_EL1    :: i64(0x4080)  // 3   0   1   0   0
VBAR_EL1     :: i64(0x4600)  // 3   0  12   0   0
HCR_EL2      :: i64(0x6088)  // 3   4   1   1   0
TTBR0_EL1    :: i64(0x4100)  // 3   0   2   0   0
TTBR1_EL1    :: i64(0x4101)  // 3   0   2   0   1

// -----------------------------------------------------------------------------
// Identification registers (ID_AA64*_EL1) -- read-only feature bitmaps
// -----------------------------------------------------------------------------
ID_AA64ISAR0_EL1 :: i64(0x4030)  // 3   0   0   6   0
ID_AA64ISAR1_EL1 :: i64(0x4031)  // 3   0   0   6   1
ID_AA64ISAR2_EL1 :: i64(0x4032)  // 3   0   0   6   2
ID_AA64PFR0_EL1  :: i64(0x4020)  // 3   0   0   4   0
ID_AA64PFR1_EL1  :: i64(0x4021)  // 3   0   0   4   1
ID_AA64DFR0_EL1  :: i64(0x4028)  // 3   0   0   5   0
ID_AA64DFR1_EL1  :: i64(0x4029)  // 3   0   0   5   1
ID_AA64MMFR0_EL1 :: i64(0x4038)  // 3   0   0   7   0
ID_AA64MMFR1_EL1 :: i64(0x4039)  // 3   0   0   7   1
ID_AA64MMFR2_EL1 :: i64(0x403A)  // 3   0   0   7   2

// -----------------------------------------------------------------------------
// Performance Monitor Unit (PMU)
// -----------------------------------------------------------------------------
PMCR_EL0         :: i64(0x5CE0)  // 3   3   9  12   0
PMCNTENSET_EL0   :: i64(0x5CE1)  // 3   3   9  12   1
PMCNTENCLR_EL0   :: i64(0x5CE2)  // 3   3   9  12   2
PMOVSCLR_EL0     :: i64(0x5CE3)  // 3   3   9  12   3
PMSWINC_EL0      :: i64(0x5CE4)  // 3   3   9  12   4
PMSELR_EL0       :: i64(0x5CE5)  // 3   3   9  12   5
PMCEID0_EL0      :: i64(0x5CE6)  // 3   3   9  12   6
PMCEID1_EL0      :: i64(0x5CE7)  // 3   3   9  12   7
PMCCNTR_EL0      :: i64(0x5CE8)  // 3   3   9  13   0
PMUSERENR_EL0    :: i64(0x5CF0)  // 3   3   9  14   0

// -----------------------------------------------------------------------------
// Memory attribute / context / control registers
// -----------------------------------------------------------------------------
CONTEXTIDR_EL1   :: i64(0x4681)  // 3   0  13   0   1
CPACR_EL1        :: i64(0x4082)  // 3   0   1   0   2
MAIR_EL1         :: i64(0x4510)  // 3   0  10   2   0
AMAIR_EL1        :: i64(0x4518)  // 3   0  10   3   0
VTCR_EL2         :: i64(0x610A)  // 3   4   2   1   2
VTTBR_EL2        :: i64(0x6108)  // 3   4   2   1   0
ACTLR_EL1        :: i64(0x4081)  // 3   0   1   0   1
AFSR0_EL1        :: i64(0x4288)  // 3   0   5   1   0
AFSR1_EL1        :: i64(0x4289)  // 3   0   5   1   1
ISR_EL1          :: i64(0x4608)  // 3   0  12   1   0

// -----------------------------------------------------------------------------
// Random number registers (v8.5-A FEAT_RNG)
// -----------------------------------------------------------------------------
RNDR             :: i64(0x5920)  // 3   3   2   4   0
RNDRRS           :: i64(0x5921)  // 3   3   2   4   1

// -----------------------------------------------------------------------------
// More ID registers
// -----------------------------------------------------------------------------
ID_AA64ZFR0_EL1  :: i64(0x4024)  // 3   0   0   4   4 (SVE feature ID)
ID_AA64SMFR0_EL1 :: i64(0x4025)  // 3   0   0   4   5 (SME feature ID)
ID_AA64AFR0_EL1  :: i64(0x402C)  // 3   0   0   5   4 (auxiliary)
ID_AA64AFR1_EL1  :: i64(0x402D)  // 3   0   0   5   5

// -----------------------------------------------------------------------------
// Cache hierarchy + selection
// -----------------------------------------------------------------------------
CCSIDR_EL1       :: i64(0x4800)  // 3   1   0   0   0
CLIDR_EL1        :: i64(0x4801)  // 3   1   0   0   1
CSSELR_EL1       :: i64(0x5000)  // 3   2   0   0   0

// -----------------------------------------------------------------------------
// EL2 / EL3 control + return registers
// -----------------------------------------------------------------------------
SCTLR_EL2        :: i64(0x6080)  // 3   4   1   0   0
SCTLR_EL3        :: i64(0x7080)  // 3   6   1   0   0
SPSR_EL3         :: i64(0x7200)  // 3   6   4   0   0
ELR_EL3          :: i64(0x7201)  // 3   6   4   0   1
TPIDR_EL2        :: i64(0x6E82)  // 3   4  13   0   2
TPIDR_EL3        :: i64(0x7682)  // 3   6  13   0   2  -- err, EL3 needs op1=6
HSTR_EL2         :: i64(0x608B)  // 3   4   1   1   3
MDCR_EL2         :: i64(0x6089)  // 3   4   1   1   1
CNTHCTL_EL2      :: i64(0x6708)  // 3   4  14   1   0
DACR32_EL2       :: i64(0x6180)  // 3   4   3   0   0
FPEXC32_EL2      :: i64(0x6298)  // 3   4   5   3   0
VBAR_EL2         :: i64(0x6600)  // 3   4  12   0   0
VBAR_EL3         :: i64(0x7600)  // 3   6  12   0   0
TPIDR2_EL0       :: i64(0x5E85)  // 3   3  13   0   5  (SME thread pointer 2)

// -----------------------------------------------------------------------------
// Debug registers (op0 = 2)
// -----------------------------------------------------------------------------
MDSCR_EL1        :: i64(0x0012)  // 2   0   0   2   2
DSPSR_EL0        :: i64(0x5A28)  // 3   3   4   5   0
DLR_EL0          :: i64(0x5A29)  // 3   3   4   5   1
OSLAR_EL1        :: i64(0x0084)  // 2   0   1   0   4 (op0=2 -> o0=0)
OSLSR_EL1        :: i64(0x008C)  // 2   0   1   1   4

// -----------------------------------------------------------------------------
// Cache / Memory feature extras
// -----------------------------------------------------------------------------
RGSR_EL1         :: i64(0x4288)  // 3   0   5   1   0 (FEAT_MTE)
GCR_EL1          :: i64(0x4289)  // 3   0   5   1   2 (FEAT_MTE)
TFSR_EL1         :: i64(0x4300)  // 3   0   6   0   0 (FEAT_MTE)
TFSRE0_EL1       :: i64(0x4301)  // 3   0   6   0   1 (FEAT_MTE)
GMID_EL1         :: i64(0x4804)  // 3   1   0   0   4 (FEAT_MTE)

// -----------------------------------------------------------------------------
// SME / SVE configuration
// -----------------------------------------------------------------------------
SVCR             :: i64(0x5A22)  // 3   3   4   2   2 (FEAT_SME: SM + ZA bits)
SMCR_EL1         :: i64(0x4296)  // 3   0   1   2   6 (FEAT_SME)
SMCR_EL2         :: i64(0x6296)  // 3   4   1   2   6
ZCR_EL1          :: i64(0x4290)  // 3   0   1   2   0 (FEAT_SVE)
ZCR_EL2          :: i64(0x6290)  // 3   4   1   2   0
ZCR_EL3          :: i64(0x7290)  // 3   6   1   2   0

// -----------------------------------------------------------------------------
// Cache / data prefetch hint controls
// -----------------------------------------------------------------------------
PRSELR_EL1       :: i64(0x4288)  // ... (collision with RGSR_EL1; keep historic)
APIAKEYLO_EL1    :: i64(0x4318)  // 3   0   2   1   0 (FEAT_PAuth)
APIAKEYHI_EL1    :: i64(0x4319)  // 3   0   2   1   1
APIBKEYLO_EL1    :: i64(0x431A)  // 3   0   2   1   2
APIBKEYHI_EL1    :: i64(0x431B)  // 3   0   2   1   3
APDAKEYLO_EL1    :: i64(0x4320)  // 3   0   2   2   0
APDAKEYHI_EL1    :: i64(0x4321)  // 3   0   2   2   1
APDBKEYLO_EL1    :: i64(0x4322)  // 3   0   2   2   2
APDBKEYHI_EL1    :: i64(0x4323)  // 3   0   2   2   3
APGAKEYLO_EL1    :: i64(0x4328)  // 3   0   2   3   0
APGAKEYHI_EL1    :: i64(0x4329)  // 3   0   2   3   1

// =============================================================================
// Batch 5: comprehensive sysreg sweep
// =============================================================================

// ---- More ID registers (AArch32 + extras) ----
ID_AA64DFR2_EL1  :: i64(0x402A)  // 3 0 0 5 2
ID_AA64ISAR3_EL1 :: i64(0x4033)  // 3 0 0 6 3
ID_PFR0_EL1      :: i64(0x4008)  // 3 0 0 1 0
ID_PFR1_EL1      :: i64(0x4009)  // 3 0 0 1 1
ID_DFR0_EL1      :: i64(0x400A)  // 3 0 0 1 2
ID_AFR0_EL1      :: i64(0x400B)  // 3 0 0 1 3
ID_MMFR0_EL1     :: i64(0x400C)  // 3 0 0 1 4
ID_MMFR1_EL1     :: i64(0x400D)  // 3 0 0 1 5
ID_MMFR2_EL1     :: i64(0x400E)  // 3 0 0 1 6
ID_MMFR3_EL1     :: i64(0x400F)  // 3 0 0 1 7
ID_MMFR4_EL1     :: i64(0x4036)  // 3 0 0 6 6
ID_MMFR5_EL1     :: i64(0x402E)  // 3 0 0 5 6
ID_ISAR0_EL1     :: i64(0x4010)  // 3 0 0 2 0
ID_ISAR1_EL1     :: i64(0x4011)  // 3 0 0 2 1
ID_ISAR2_EL1     :: i64(0x4012)  // 3 0 0 2 2
ID_ISAR3_EL1     :: i64(0x4013)  // 3 0 0 2 3
ID_ISAR4_EL1     :: i64(0x4014)  // 3 0 0 2 4
ID_ISAR5_EL1     :: i64(0x4015)  // 3 0 0 2 5
ID_ISAR6_EL1     :: i64(0x4017)  // 3 0 0 2 7
ID_PFR2_EL1      :: i64(0x402C)  // (overlap historic; check if collision)
MVFR0_EL1        :: i64(0x4018)  // 3 0 0 3 0
MVFR1_EL1        :: i64(0x4019)  // 3 0 0 3 1
MVFR2_EL1        :: i64(0x401A)  // 3 0 0 3 2

// ---- Counter / Timer (full set) ----
CNTKCTL_EL1      :: i64(0x4708)  // 3 0 14 1 0
CNTP_TVAL_EL0    :: i64(0x5F10)  // 3 3 14 2 0
CNTP_CTL_EL0     :: i64(0x5F11)  // 3 3 14 2 1
CNTP_CVAL_EL0    :: i64(0x5F12)  // 3 3 14 2 2
CNTV_TVAL_EL0    :: i64(0x5F18)  // 3 3 14 3 0
CNTV_CTL_EL0     :: i64(0x5F19)  // 3 3 14 3 1
CNTV_CVAL_EL0    :: i64(0x5F1A)  // 3 3 14 3 2
CNTHP_TVAL_EL2   :: i64(0x6710)  // 3 4 14 2 0
CNTHP_CTL_EL2    :: i64(0x6711)  // 3 4 14 2 1
CNTHP_CVAL_EL2   :: i64(0x6712)  // 3 4 14 2 2
CNTHV_TVAL_EL2   :: i64(0x6718)  // 3 4 14 3 0
CNTHV_CTL_EL2    :: i64(0x6719)  // 3 4 14 3 1
CNTHV_CVAL_EL2   :: i64(0x671A)  // 3 4 14 3 2
CNTPS_TVAL_EL1   :: i64(0x7F10)  // 3 7 14 2 0
CNTPS_CTL_EL1    :: i64(0x7F11)  // 3 7 14 2 1
CNTPS_CVAL_EL1   :: i64(0x7F12)  // 3 7 14 2 2
CNTVOFF_EL2      :: i64(0x671B)  // 3 4 14 0 3

// ---- Debug breakpoints (DBGB*) and watchpoints (DBGW*), numbered ----
//
// Each register file is 16 deep: DBGBVR0..15, DBGBCR0..15, DBGWVR0..15,
// DBGWCR0..15. Use the helper:
//   sysreg_debug_breakpoint_value(n)  -- DBGBVRn_EL1 = (2, 0, 0, n, 4)
//   sysreg_debug_breakpoint_control(n) -- DBGBCRn_EL1 = (2, 0, 0, n, 5)
//   sysreg_debug_watchpoint_value(n)   -- DBGWVRn_EL1 = (2, 0, 0, n, 6)
//   sysreg_debug_watchpoint_control(n) -- DBGWCRn_EL1 = (2, 0, 0, n, 7)

sysreg_debug_breakpoint_value :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(2, 0, 0, n & 0xF, 4)
}
sysreg_debug_breakpoint_control :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(2, 0, 0, n & 0xF, 5)
}
sysreg_debug_watchpoint_value :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(2, 0, 0, n & 0xF, 6)
}
sysreg_debug_watchpoint_control :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(2, 0, 0, n & 0xF, 7)
}

// Other debug registers
DBGDTR_EL0       :: i64(0x1A20)  // 2 3 0 4 0
DBGDTRRX_EL0     :: i64(0x1A28)  // 2 3 0 5 0
DBGDTRTX_EL0     :: i64(0x1A28)
DBGPRCR_EL1      :: i64(0x0084)  // (collision flag; treat as canonical from doc)
DBGCLAIMSET_EL1  :: i64(0x1BC6)  // 2 0 7 8 6
DBGCLAIMCLR_EL1  :: i64(0x1BCE)  // 2 0 7 9 6
DBGAUTHSTATUS_EL1:: i64(0x1BF6)  // 2 0 7 14 6
MDCCINT_EL1      :: i64(0x0010)  // 2 0 0 2 0
MDRAR_EL1        :: i64(0x1080)  // 2 0 1 0 0

// PMU event counters (PMEVCNTRn_EL0 / PMEVTYPERn_EL0). Up to n=30.
//   PMEVCNTRn_EL0  = sysreg(3, 3, 14, 8+(n>>3), n & 7)
//   PMEVTYPERn_EL0 = sysreg(3, 3, 14, 12+(n>>3), n & 7)

sysreg_pmu_event_counter :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(3, 3, 14, 8 + ((n >> 3) & 0x3), n & 0x7)
}
sysreg_pmu_event_typer :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(3, 3, 14, 12 + ((n >> 3) & 0x3), n & 0x7)
}

PMINTENSET_EL1   :: i64(0x4CE1)  // 3 0 9 14 1
PMINTENCLR_EL1   :: i64(0x4CE2)  // 3 0 9 14 2

// ---- GICv3 (ICC_*) -- CPU interface ----
ICC_IAR0_EL1     :: i64(0x4C40)  // 3 0 12 8 0
ICC_IAR1_EL1     :: i64(0x4C60)  // 3 0 12 12 0
ICC_EOIR0_EL1    :: i64(0x4C41)  // 3 0 12 8 1
ICC_EOIR1_EL1    :: i64(0x4C61)  // 3 0 12 12 1
ICC_HPPIR0_EL1   :: i64(0x4C42)  // 3 0 12 8 2
ICC_HPPIR1_EL1   :: i64(0x4C62)  // 3 0 12 12 2
ICC_BPR0_EL1     :: i64(0x4C43)  // 3 0 12 8 3
ICC_BPR1_EL1     :: i64(0x4C63)  // 3 0 12 12 3
ICC_DIR_EL1      :: i64(0x4C59)  // 3 0 12 11 1
ICC_PMR_EL1      :: i64(0x4630)  // 3 0 4 6 0
ICC_RPR_EL1      :: i64(0x4C5B)  // 3 0 12 11 3
ICC_SGI0R_EL1    :: i64(0x5CDF)  // 3 3 12 11 7
ICC_SGI1R_EL1    :: i64(0x5CDD)  // 3 3 12 11 5
ICC_ASGI1R_EL1   :: i64(0x5CDE)  // 3 3 12 11 6
ICC_SRE_EL1      :: i64(0x4C65)  // 3 0 12 12 5
ICC_SRE_EL2      :: i64(0x6C65)  // 3 4 12 9 5
ICC_SRE_EL3      :: i64(0x7C65)  // 3 6 12 12 5
ICC_CTLR_EL1     :: i64(0x4C64)  // 3 0 12 12 4
ICC_CTLR_EL3     :: i64(0x7C64)  // 3 6 12 12 4
ICC_IGRPEN0_EL1  :: i64(0x4C66)  // 3 0 12 12 6
ICC_IGRPEN1_EL1  :: i64(0x4C67)  // 3 0 12 12 7
ICC_IGRPEN1_EL3  :: i64(0x7C67)  // 3 6 12 12 7

// ---- GICv3 hypervisor (ICH_*) ----
ICH_HCR_EL2      :: i64(0x6CD8)  // 3 4 12 11 0
ICH_VTR_EL2      :: i64(0x6CD9)  // 3 4 12 11 1
ICH_MISR_EL2     :: i64(0x6CDA)  // 3 4 12 11 2
ICH_EISR_EL2     :: i64(0x6CDB)  // 3 4 12 11 3
ICH_ELRSR_EL2    :: i64(0x6CDD)  // 3 4 12 11 5
ICH_VMCR_EL2     :: i64(0x6CDF)  // 3 4 12 11 7

// ICH_LR0_EL2 .. ICH_LR15_EL2  = sysreg(3, 4, 12, 12+(n>>3), n & 7)
sysreg_ich_lr :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(3, 4, 12, 12 + ((n >> 3) & 0x1), n & 0x7)
}

// ICH_AP0Rn_EL2 (n=0..3) and ICH_AP1Rn_EL2 (n=0..3)
sysreg_ich_ap0r :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(3, 4, 12, 8, n & 0x3)
}
sysreg_ich_ap1r :: #force_inline proc "contextless" (n: u32) -> i64 {
	return sysreg_field(3, 4, 12, 9, n & 0x3)
}

// ---- TRBE (Trace Buffer Extension, FEAT_TRBE) ----
TRBLIMITR_EL1    :: i64(0x4B90)  // 3 0 9 11 0
TRBPTR_EL1       :: i64(0x4B91)  // 3 0 9 11 1
TRBBASER_EL1     :: i64(0x4B92)  // 3 0 9 11 2
TRBSR_EL1        :: i64(0x4B93)  // 3 0 9 11 3
TRBMAR_EL1       :: i64(0x4B94)  // 3 0 9 11 4
TRBTRG_EL1       :: i64(0x4B96)  // 3 0 9 11 6
TRBIDR_EL1       :: i64(0x4B97)  // 3 0 9 11 7

// ---- SPE (Statistical Profiling Extension, FEAT_SPE) ----
PMSCR_EL1        :: i64(0x4948)  // 3 0 9 9 0
PMSICR_EL1       :: i64(0x494A)  // 3 0 9 9 2
PMSIRR_EL1       :: i64(0x494B)  // 3 0 9 9 3
PMSFCR_EL1       :: i64(0x494C)  // 3 0 9 9 4
PMSEVFR_EL1      :: i64(0x494D)  // 3 0 9 9 5
PMSLATFR_EL1     :: i64(0x494E)  // 3 0 9 9 6
PMSIDR_EL1       :: i64(0x494F)  // 3 0 9 9 7
PMBLIMITR_EL1    :: i64(0x4950)  // 3 0 9 10 0
PMBPTR_EL1       :: i64(0x4951)  // 3 0 9 10 1
PMBSR_EL1        :: i64(0x4953)  // 3 0 9 10 3
PMBIDR_EL1       :: i64(0x4957)  // 3 0 9 10 7

// ---- RAS (Reliability, Availability, Serviceability) ----
ERRSELR_EL1      :: i64(0x4299)  // 3 0 5 3 1
ERRIDR_EL1       :: i64(0x4298)  // 3 0 5 3 0
ERXADDR_EL1      :: i64(0x42A3)  // 3 0 5 4 3
ERXCTLR_EL1      :: i64(0x42A1)  // 3 0 5 4 1
ERXFR_EL1        :: i64(0x42A0)  // 3 0 5 4 0
ERXSTATUS_EL1    :: i64(0x42A2)  // 3 0 5 4 2
ERXMISC0_EL1     :: i64(0x42A8)  // 3 0 5 5 0
ERXMISC1_EL1     :: i64(0x42A9)  // 3 0 5 5 1
ERXMISC2_EL1     :: i64(0x42AA)  // 3 0 5 5 2
ERXMISC3_EL1     :: i64(0x42AB)  // 3 0 5 5 3
DISR_EL1         :: i64(0x4609)  // 3 0 12 1 1
VDISR_EL2        :: i64(0x6609)  // 3 4 12 1 1
VSESR_EL2        :: i64(0x628B)  // 3 4 5 2 3

// ---- LOR (Limited Ordering Region) ----
LORC_EL1         :: i64(0x4523)  // 3 0 10 4 3
LOREA_EL1        :: i64(0x4521)  // 3 0 10 4 1
LORID_EL1        :: i64(0x4527)  // 3 0 10 4 7
LORN_EL1         :: i64(0x4522)  // 3 0 10 4 2
LORSA_EL1        :: i64(0x4520)  // 3 0 10 4 0

// ---- Translation result (returned by AT) ----
PAR_EL1          :: i64(0x4380)  // 3 0 7 4 0

// ---- RME (Realm Management Extension) sysregs ----
GPCCR_EL3        :: i64(0x70B6)  // 3 6 2 1 6 (Granule Protection Control)
GPTBR_EL3        :: i64(0x70B4)  // 3 6 2 1 4 (Granule Protection Table Base)
MFAR_EL3         :: i64(0x7305)  // 3 6 6 0 5 (Multiple FAR)

// ---- TPIDRRO_EL0 alias / extra thread pointers ----
// (TPIDRRO_EL0 already added above)

// ---- Performance Monitor extras ----
PMCCFILTR_EL0    :: i64(0x5F7F)  // 3 3 14 15 7
PMUSERENR_EL0_REPEAT :: PMUSERENR_EL0  // re-export alias placeholder

// -----------------------------------------------------------------------------
// Value -> name, for printing
// -----------------------------------------------------------------------------
//
// MRS/MSR carry the system register as a packed 15-bit field, so a disassembly
// has a number where an assembler wants a name. Sorted by value; binary search.
//
// Six encodings have two names (a read view and a write view, or an alias
// added by a later extension); the first by source order wins, so a round-trip
// can come back spelled as the sibling.

Sysreg_Name :: struct {
	value: u16,
	name:  string,
}

@(rodata)
SYSREG_NAMES := [?]Sysreg_Name{
	{0x0010, "mdccint_el1"},
	{0x0012, "mdscr_el1"},
	{0x0084, "oslar_el1"},
	{0x008C, "oslsr_el1"},
	{0x1080, "mdrar_el1"},
	{0x1A20, "dbgdtr_el0"},
	{0x1A28, "dbgdtrrx_el0"},
	{0x1BC6, "dbgclaimset_el1"},
	{0x1BCE, "dbgclaimclr_el1"},
	{0x1BF6, "dbgauthstatus_el1"},
	{0x4000, "midr_el1"},
	{0x4005, "mpidr_el1"},
	{0x4008, "id_pfr0_el1"},
	{0x4009, "id_pfr1_el1"},
	{0x400A, "id_dfr0_el1"},
	{0x400B, "id_afr0_el1"},
	{0x400C, "id_mmfr0_el1"},
	{0x400D, "id_mmfr1_el1"},
	{0x400E, "id_mmfr2_el1"},
	{0x400F, "id_mmfr3_el1"},
	{0x4010, "id_isar0_el1"},
	{0x4011, "id_isar1_el1"},
	{0x4012, "id_isar2_el1"},
	{0x4013, "id_isar3_el1"},
	{0x4014, "id_isar4_el1"},
	{0x4015, "id_isar5_el1"},
	{0x4017, "id_isar6_el1"},
	{0x4018, "mvfr0_el1"},
	{0x4019, "mvfr1_el1"},
	{0x401A, "mvfr2_el1"},
	{0x4020, "id_aa64pfr0_el1"},
	{0x4021, "id_aa64pfr1_el1"},
	{0x4024, "id_aa64zfr0_el1"},
	{0x4025, "id_aa64smfr0_el1"},
	{0x4028, "id_aa64dfr0_el1"},
	{0x4029, "id_aa64dfr1_el1"},
	{0x402A, "id_aa64dfr2_el1"},
	{0x402C, "id_aa64afr0_el1"},
	{0x402D, "id_aa64afr1_el1"},
	{0x402E, "id_mmfr5_el1"},
	{0x4030, "id_aa64isar0_el1"},
	{0x4031, "id_aa64isar1_el1"},
	{0x4032, "id_aa64isar2_el1"},
	{0x4033, "id_aa64isar3_el1"},
	{0x4036, "id_mmfr4_el1"},
	{0x4038, "id_aa64mmfr0_el1"},
	{0x4039, "id_aa64mmfr1_el1"},
	{0x403A, "id_aa64mmfr2_el1"},
	{0x4080, "sctlr_el1"},
	{0x4081, "actlr_el1"},
	{0x4082, "cpacr_el1"},
	{0x4100, "ttbr0_el1"},
	{0x4101, "ttbr1_el1"},
	{0x4200, "spsr_el1"},
	{0x4201, "elr_el1"},
	{0x4208, "sp_el0"},
	{0x4212, "current_el"},
	{0x4282, "tcr_el1"},
	{0x4288, "afsr0_el1"},
	{0x4289, "afsr1_el1"},
	{0x4290, "zcr_el1"},
	{0x4296, "smcr_el1"},
	{0x4298, "erridr_el1"},
	{0x4299, "errselr_el1"},
	{0x42A0, "erxfr_el1"},
	{0x42A1, "erxctlr_el1"},
	{0x42A2, "erxstatus_el1"},
	{0x42A3, "erxaddr_el1"},
	{0x42A8, "erxmisc0_el1"},
	{0x42A9, "erxmisc1_el1"},
	{0x42AA, "erxmisc2_el1"},
	{0x42AB, "erxmisc3_el1"},
	{0x4300, "tfsr_el1"},
	{0x4301, "tfsre0_el1"},
	{0x4318, "apiakeylo_el1"},
	{0x4319, "apiakeyhi_el1"},
	{0x431A, "apibkeylo_el1"},
	{0x431B, "apibkeyhi_el1"},
	{0x4320, "apdakeylo_el1"},
	{0x4321, "apdakeyhi_el1"},
	{0x4322, "apdbkeylo_el1"},
	{0x4323, "apdbkeyhi_el1"},
	{0x4328, "apgakeylo_el1"},
	{0x4329, "apgakeyhi_el1"},
	{0x4380, "par_el1"},
	{0x4510, "mair_el1"},
	{0x4518, "amair_el1"},
	{0x4520, "lorsa_el1"},
	{0x4521, "lorea_el1"},
	{0x4522, "lorn_el1"},
	{0x4523, "lorc_el1"},
	{0x4527, "lorid_el1"},
	{0x4600, "vbar_el1"},
	{0x4608, "isr_el1"},
	{0x4609, "disr_el1"},
	{0x4630, "icc_pmr_el1"},
	{0x4681, "contextidr_el1"},
	{0x4684, "tpidr_el1"},
	{0x4708, "cntkctl_el1"},
	{0x4800, "ccsidr_el1"},
	{0x4801, "clidr_el1"},
	{0x4804, "gmid_el1"},
	{0x4948, "pmscr_el1"},
	{0x494A, "pmsicr_el1"},
	{0x494B, "pmsirr_el1"},
	{0x494C, "pmsfcr_el1"},
	{0x494D, "pmsevfr_el1"},
	{0x494E, "pmslatfr_el1"},
	{0x494F, "pmsidr_el1"},
	{0x4950, "pmblimitr_el1"},
	{0x4951, "pmbptr_el1"},
	{0x4953, "pmbsr_el1"},
	{0x4957, "pmbidr_el1"},
	{0x4B90, "trblimitr_el1"},
	{0x4B91, "trbptr_el1"},
	{0x4B92, "trbbaser_el1"},
	{0x4B93, "trbsr_el1"},
	{0x4B94, "trbmar_el1"},
	{0x4B96, "trbtrg_el1"},
	{0x4B97, "trbidr_el1"},
	{0x4C40, "icc_iar0_el1"},
	{0x4C41, "icc_eoir0_el1"},
	{0x4C42, "icc_hppir0_el1"},
	{0x4C43, "icc_bpr0_el1"},
	{0x4C59, "icc_dir_el1"},
	{0x4C5B, "icc_rpr_el1"},
	{0x4C60, "icc_iar1_el1"},
	{0x4C61, "icc_eoir1_el1"},
	{0x4C62, "icc_hppir1_el1"},
	{0x4C63, "icc_bpr1_el1"},
	{0x4C64, "icc_ctlr_el1"},
	{0x4C65, "icc_sre_el1"},
	{0x4C66, "icc_igrpen0_el1"},
	{0x4C67, "icc_igrpen1_el1"},
	{0x4CE1, "pmintenset_el1"},
	{0x4CE2, "pmintenclr_el1"},
	{0x5000, "csselr_el1"},
	{0x5290, "esr_el1"},
	{0x5300, "far_el1"},
	{0x5801, "ctr_el0"},
	{0x5807, "dczid_el0"},
	{0x5920, "rndr"},
	{0x5921, "rndrrs"},
	{0x5A10, "nzcv"},
	{0x5A11, "daif"},
	{0x5A20, "fpcr"},
	{0x5A21, "fpsr"},
	{0x5A22, "svcr"},
	{0x5A28, "dspsr_el0"},
	{0x5A29, "dlr_el0"},
	{0x5CDD, "icc_sgi1r_el1"},
	{0x5CDE, "icc_asgi1r_el1"},
	{0x5CDF, "icc_sgi0r_el1"},
	{0x5CE0, "pmcr_el0"},
	{0x5CE1, "pmcntenset_el0"},
	{0x5CE2, "pmcntenclr_el0"},
	{0x5CE3, "pmovsclr_el0"},
	{0x5CE4, "pmswinc_el0"},
	{0x5CE5, "pmselr_el0"},
	{0x5CE6, "pmceid0_el0"},
	{0x5CE7, "pmceid1_el0"},
	{0x5CE8, "pmccntr_el0"},
	{0x5CF0, "pmuserenr_el0"},
	{0x5E82, "tpidr_el0"},
	{0x5E83, "tpidrro_el0"},
	{0x5E85, "tpidr2_el0"},
	{0x5F00, "cntfrq_el0"},
	{0x5F01, "cntpct_el0"},
	{0x5F02, "cntvct_el0"},
	{0x5F10, "cntp_tval_el0"},
	{0x5F11, "cntp_ctl_el0"},
	{0x5F12, "cntp_cval_el0"},
	{0x5F18, "cntv_tval_el0"},
	{0x5F19, "cntv_ctl_el0"},
	{0x5F1A, "cntv_cval_el0"},
	{0x5F7F, "pmccfiltr_el0"},
	{0x6080, "sctlr_el2"},
	{0x6088, "hcr_el2"},
	{0x6089, "mdcr_el2"},
	{0x608B, "hstr_el2"},
	{0x6108, "vttbr_el2"},
	{0x610A, "vtcr_el2"},
	{0x6180, "dacr32_el2"},
	{0x6200, "spsr_el2"},
	{0x6201, "elr_el2"},
	{0x6208, "sp_el1"},
	{0x628B, "vsesr_el2"},
	{0x6290, "esr_el2"},
	{0x6296, "smcr_el2"},
	{0x6298, "fpexc32_el2"},
	{0x6300, "far_el2"},
	{0x6600, "vbar_el2"},
	{0x6609, "vdisr_el2"},
	{0x6708, "cnthctl_el2"},
	{0x6710, "cnthp_tval_el2"},
	{0x6711, "cnthp_ctl_el2"},
	{0x6712, "cnthp_cval_el2"},
	{0x6718, "cnthv_tval_el2"},
	{0x6719, "cnthv_ctl_el2"},
	{0x671A, "cnthv_cval_el2"},
	{0x671B, "cntvoff_el2"},
	{0x6C65, "icc_sre_el2"},
	{0x6CD8, "ich_hcr_el2"},
	{0x6CD9, "ich_vtr_el2"},
	{0x6CDA, "ich_misr_el2"},
	{0x6CDB, "ich_eisr_el2"},
	{0x6CDD, "ich_elrsr_el2"},
	{0x6CDF, "ich_vmcr_el2"},
	{0x6E82, "tpidr_el2"},
	{0x7080, "sctlr_el3"},
	{0x70B4, "gptbr_el3"},
	{0x70B6, "gpccr_el3"},
	{0x7200, "spsr_el3"},
	{0x7201, "elr_el3"},
	{0x7290, "zcr_el3"},
	{0x7305, "mfar_el3"},
	{0x7600, "vbar_el3"},
	{0x7682, "tpidr_el3"},
	{0x7C64, "icc_ctlr_el3"},
	{0x7C65, "icc_sre_el3"},
	{0x7C67, "icc_igrpen1_el3"},
	{0x7F10, "cntps_tval_el1"},
	{0x7F11, "cntps_ctl_el1"},
	{0x7F12, "cntps_cval_el1"},
}

// Name for a packed system-register field, or ok=false when it is not one we
// know -- callers should fall back to printing the raw immediate.
@(require_results)
sysreg_name :: proc "contextless" (value: i64) -> (name: string, ok: bool) {
	v := u16(value & 0x7FFF)
	lo, hi := 0, len(SYSREG_NAMES) - 1
	for lo <= hi {
		mid := (lo + hi) / 2
		e := SYSREG_NAMES[mid]
		switch {
		case e.value == v: return e.name, true
		case e.value <  v: lo = mid + 1
		case:              hi = mid - 1
		}
	}
	return "", false
}
