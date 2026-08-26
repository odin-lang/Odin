package rexcode_arm64

// Operand slots (indices into the Encoding operand list) that are read/written.
// Max 4 operands (R4-style FMA: FMADD rd, rn, rm, ra). Register lists on the
// LD1-4/ST1-4 structure forms count as a single operand slot.
Operand_Set :: distinct bit_set[0..<4; u8]

// The NZCV condition flags — the ONLY application-visible flag state in AArch64.
// There is no parity/aux-carry/direction flag as on x86. The other PSTATE bits
// (DAIF interrupt masks, PAN, UAO, SSBS, SP-select, ...) are system state
// reached only through MSR/MRS, and are modelled via the PRIVILEGED side effect
// rather than here.
NZCV_Flags :: distinct bit_set[NZCV_Flag; u8]
NZCV_Flag :: enum u8 {
	N, // negative result
	Z, // zero result
	C, // carry-out / no-borrow (unsigned sense)
	V, // signed overflow
}

// FPSR cumulative exception + saturation flags — the AArch64 analogue of RISC-V
// fflags / x86 MXCSR status. The rounding mode lives separately in FPCR (see
// reads_fpcr below), so there is no EFLAGS-style triad for FP either.
FPSR_Flags :: distinct bit_set[FPSR_Flag; u8]
FPSR_Flag :: enum u8 {
	IOC, // invalid operation
	DZC, // divide by zero
	OFC, // overflow
	UFC, // underflow
	IXC, // inexact
	IDC, // input denormal
	QC,  // cumulative saturation (Advanced SIMD saturating ops)
}

// Implicitly-touched GPRs that are NOT distinct operands. Like RISC-V, AArch64
// has very few of these: the SIMD/FP register file is always addressed through
// explicit operands, so there is no x86-style VECTOR/XMM0 implicit clobber.
//
// X16/X17 are here for the pointer-authentication *1716 hint forms
// (PACIA1716/AUTIA1716/...), which implicitly read X16 (modifier) and
// read-modify-write X17 (the pointer) without naming either as an operand.
Clobber_Regs :: distinct bit_set[Clobber_Reg; u8]
Clobber_Reg :: enum u8 {
	LR,  // x30, implicit link written by BL/BLR, implicitly read by RET
	SP,  // sp,  implicit base on PACIASP/AUTIASP (and stack-relative forms)
	X16, // implicit modifier register for PAC*1716 / AUT*1716
	X17, // implicit pointer register (read-modify-write) for PAC*1716 / AUT*1716
}

Side_Effects :: distinct bit_set[Side_Effect; u16]
Side_Effect :: enum u8 {
	CONTROL,          // writes pc: B/BL/BR/BLR/RET, B.cond, CBZ/CBNZ, TBZ/TBNZ
	EXCEPTION,        // exception-generating call: SVC / HVC / SMC
	TRAP,             // deliberately faults: BRK (breakpoint), UDF (undefined)
	FENCE,            // memory-ordering barrier: DMB/DSB, and acquire/release accesses
	ISYNC,            // instruction-stream / context synchronization: ISB
	ATOMIC,           // indivisible RMW: LDXR/STXR pair, LSE (LDADD/SWP/CAS...)
	RESERVATION,      // sets/tests/clears the local exclusive monitor: LDXR/STXR, CLREX
	CACHE,            // cache maintenance with coherence effects: DC, IC
	HINT,             // architecturally-inert hint: NOP/YIELD/PRFM/SEV/ESB/CSDB
	BTI,              // branch-target-identification landing pad (control-flow integrity)
	PAC,              // pointer authentication: reads an implicit key, may fault (FEAT_FPAC)
	WAIT,             // suspends execution until an event/interrupt: WFI/WFE
	PRIVILEGED,       // reads/writes system state: MSR/MRS, ERET, TLBI, AT, DAIF
	FFR,              // reads/writes the SVE first-fault register: SETFFR/RDFFR/WRFFR, LDFF*
	NONDETERMINISTIC, // RNDR/RNDRRS, counter/timer reads (CNTVCT), TSTART
}

Clobber :: struct {
	written:      Operand_Set,  // operand slots whose register/SIMD reg is written
	read:         Operand_Set,  // operand slots whose register / mem-base is read
	implicit_wr:  Clobber_Regs, // implicit reg writes (LR on BL/BLR)
	implicit_rd:  Clobber_Regs, // implicit reg reads (LR on RET, SP on PAC*SP)
	nzcv_wr:      NZCV_Flags,   // condition flags written (ADDS/SUBS/ANDS, CMP, FCMP, CCMP...)
	nzcv_undef:   NZCV_Flags,   // condition flags left UNKNOWN — rare in A64, usually empty
	nzcv_rd:      NZCV_Flags,   // condition flags read (B.cond, CSEL, ADC/SBC, CCMP...)
	fpsr_wr:      FPSR_Flags,   // FP cumulative exception/saturation flags this op may raise
	reads_fpcr:   bool,         // consumes the rounding mode / FP control from FPCR
	writes_mem:   bool,
	reads_mem:    bool,
	side_effects: Side_Effects,
}
