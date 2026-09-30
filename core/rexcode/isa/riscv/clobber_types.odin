package rexcode_riscv

// Operand slots (indices into the Encoding operand list) that are read/written.
// Max 4 operands (R4-type FMA: rd, rs1, rs2, rs3).
Operand_Set :: distinct bit_set[0..<4; u8]

FFlags :: distinct bit_set[FFlag; u8]
// fcsr accrued exception flags. This is the ONLY flag state in RISC-V — there
// are no integer condition codes, so there is no EFLAGS-style triad here.
FFlag :: enum u8 {
	NV, // invalid operation
	DZ, // divide by zero
	OF, // overflow
	UF, // underflow
	NX, // inexact
}

Clobber_Regs :: distinct bit_set[Clobber_Reg; u8]
// Implicitly-touched registers that are NOT distinct operands. RISC-V's base
// ISA has almost none of these (unlike x86's RAX/RDX/RSP-heavy encodings) —
// only the compressed link/stack forms.
Clobber_Reg :: enum u8 {
	RA, // x1, implicit link on C.JAL / C.JALR
	SP, // x2, implicit base on the *SP compressed forms
}

Side_Effects :: distinct bit_set[Side_Effect; u8]
Side_Effect :: enum u8 {
	CONTROL,     // writes pc: branches, jumps, and trap redirects
	TRAP,        // synchronous environment trap (ECALL / EBREAK)
	FENCE,       // explicit memory-ordering barrier (FENCE)
	IFENCE,      // instruction-fetch synchronization (FENCE.I)
	ATOMIC,      // indivisible memory RMW (AMO*, and the LR/SC pair)
	RESERVATION, // sets or tests an LR/SC reservation
}

Clobber :: struct {
	written:      Operand_Set,  // operand slots whose register/CSR is written
	read:         Operand_Set,  // operand slots whose register/CSR/mem-base is read
	implicit_wr:  Clobber_Regs, // implicit reg writes (ra on C.JAL/C.JALR)
	implicit_rd:  Clobber_Regs, // implicit reg reads (sp on the *SP forms)
	fflags_wr:    FFlags,       // accrued exception flags this op may raise
	reads_frm:    bool,         // consumes the dynamic rounding mode from fcsr
	writes_mem:   bool,
	reads_mem:    bool,
	side_effects: Side_Effects,
}