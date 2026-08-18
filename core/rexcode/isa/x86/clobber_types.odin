package rexcode_x86

Clobber_Flags :: distinct bit_set[Clobber_Flag; u16]
Clobber_Flag :: enum u8 {
	CF,
	PF,
	AF,
	ZF,
	SF,
	OF,
	DF,
	IF,
	TF,
}

Side_Effect :: enum u8 {
	FENCE,        // memory-ordering barrier (LFENCE/SFENCE/MFENCE, LOCK)
	SERIALIZING,  // architecturally serializing (drains pipeline)
	HINT,         // microarchitectural hint, architecturally inert (PAUSE/PREFETCH*/ENDBR)
	CACHE,        // cache-line maintenance with coherence effects (CLFLUSH/CLWB)
	TRAP,         // may deliberately raise a fault (#UD/#BR): UD0-2, BOUND
	INTERRUPT,    // software interrupt / syscall gate
	HALT,         // stops execution until an external event
	PRIVILEGED,   // requires CPL0 / reads-writes supervisor machine state
	CONTROL,      // alters control flow (writes RIP): branches, calls, returns
	CET,          // control-flow-enforcement: landing pads, shadow-stack ops
}
Side_Effects :: distinct bit_set[Side_Effect; u16]

Clobber_Regs :: distinct bit_set[Clobber_Reg; u16]
Clobber_Reg :: enum u8 {
	RAX, RBX, RCX, RDX,
	RSI, RDI, RSP, RBP,
	R11, XMM0, VECTOR, MXCSR,
	FPU_ST, FPU_SW,
}

Operand_Set  :: distinct bit_set[0..<4; u8]

Clobber :: struct {
	written:      Operand_Set,
	read:         Operand_Set,
	implicit_wr:  Clobber_Regs,
	implicit_rd:  Clobber_Regs,
	flags_wr:     Clobber_Flags,
	flags_undef:  Clobber_Flags,
	flags_rd:     Clobber_Flags,
	writes_mem:   bool,
	reads_mem:    bool,
	side_effects: Side_Effects,
}