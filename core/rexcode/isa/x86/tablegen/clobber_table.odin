// clobber_table.odin  --  auxiliary side-effect table for rexcode_x86_tablegen
//
// DERIVED, NOT EXTRACTED.  The ENCODING_TABLE describes how bytes are laid out
// (opcode, ModRM roles, prefixes, REX). It carries no read/write direction and
// no implicit side effects, so this table cannot be produced from it alone --
// it is a hand-authored semantics layer sourced from the Intel SDM Vol.2
// ("Operation" + "Flags Affected") applied per instruction family.
//
// Conventions:
//   written / read      explicit operand slots (OP0..OP3). rmw = written & read.
//   implicit_wr / _rd   registers touched that are NOT explicit operands
//                       (widths follow operand size; e.g. RAX means AL/AX/EAX/RAX).
//   flags_wr            EFLAGS set to a DEFINED value (a cleared flag counts).
//   flags_undef         EFLAGS left ARCHITECTURALLY UNDEFINED (must be treated
//                       as clobbered by a compiler, value not guaranteed).
//   flags_rd            EFLAGS consumed by the instruction.
//   writes_mem/reads_mem  memory VALUE touched (explicit mem operand or
//                       implicit: PUSH/CALL/string ops/gather/scatter/etc).
//   side_effects        effects that are NOT clobbers but still make the
//                       instruction non-eliminable and/or non-reorderable
//                       (fences, serialization, traps, control flow, ...).
//                       This is what separates MFENCE -- orders memory,
//                       clobbers nothing -- from a genuine no-op.
// FPU_ST/FPU_SW = x87 stack / status word; MXCSR = SSE control-status;
// VECTOR = the whole SIMD register file (VZEROALL/VZEROUPPER).
//
// INVARIANT: an instruction is a pure, freely-eliminable no-op iff every
// clobber set is empty AND side_effects == {}. In this table only .NOP
// (and the .INVALID sentinel) satisfy that.

package rexcode_x86_tablegen

import "core:rexcode/isa/x86"

@(rodata)
CLOBBER_TABLE := [Mnemonic]x86.Clobber{
	.INVALID = {},

	// ---- 8.1 Data Transfer Encodings ----
	.MOV    = {written={.OP0}, read={.OP1}, writes_mem=true, reads_mem=true},
	.MOVABS = {written={.OP0}, read={.OP1}, writes_mem=true, reads_mem=true},
	.MOVZX  = {written={.OP0}, read={.OP1}, reads_mem=true},
	.MOVSX  = {written={.OP0}, read={.OP1}, reads_mem=true},
	.MOVSXD = {written={.OP0}, read={.OP1}, reads_mem=true},
	.XCHG   = {written={.OP0, .OP1}, read={.OP0, .OP1}, writes_mem=true, reads_mem=true},  // asserts LOCK when a mem operand is used
	.PUSH   = {read={.OP0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true},
	.POP    = {written={.OP0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true},
	.LEA    = {written={.OP0}},  // no memory access: computes effective address only

	// ---- 8.2 Arithmetic Encodings ----
	.ADD  = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	.ADC  = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
	.SUB  = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	.SBB  = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
	.MUL  = {read={.OP0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.SF, .ZF, .AF, .PF}, reads_mem=true},  // RAX/RDX widths follow operand size (r/m8 -> AX only)
	.IMUL = {written={.OP0}, read={.OP0, .OP1, .OP2}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX}, flags_wr={.CF, .OF}, flags_undef={.SF, .ZF, .AF, .PF}, reads_mem=true},  // union of forms: 1-op writes RDX:RAX (implicit); 2/3-op writes OP0, no implicit
	.DIV  = {read={.OP0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},  // RDX:RAX = quotient/remainder; r/m8 uses AX only
	.IDIV = {read={.OP0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX}, flags_undef={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},  // RDX:RAX = quotient/remainder; r/m8 uses AX only
	.INC  = {written={.OP0}, read={.OP0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},  // CF deliberately NOT affected
	.DEC  = {written={.OP0}, read={.OP0}, flags_wr={.PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},  // CF deliberately NOT affected
	.NEG  = {written={.OP0}, read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},
	.CMP  = {read={.OP0, .OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},  // no operand written; flags only

	// ---- 8.3 Logical Encodings ----
	.AND  = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.OF, .CF, .SF, .ZF, .PF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	.OR   = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.OF, .CF, .SF, .ZF, .PF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	.XOR  = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.OF, .CF, .SF, .ZF, .PF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},
	.NOT  = {written={.OP0}, read={.OP0}, writes_mem=true, reads_mem=true},
	.TEST = {read={.OP0, .OP1}, flags_wr={.OF, .CF, .SF, .ZF, .PF}, flags_undef={.AF}, reads_mem=true},  // no operand written; flags only

	// ---- 8.4 Shift/Rotate Encodings ----
	.SHL  = {written={.OP0}, read={.OP0, .OP1}, implicit_rd={.RCX}, flags_wr={.CF, .SF, .ZF, .PF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},  // OF defined only for 1-bit count; count==0 leaves flags unchanged
	.SHR  = {written={.OP0}, read={.OP0, .OP1}, implicit_rd={.RCX}, flags_wr={.CF, .SF, .ZF, .PF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},  // OF defined only for 1-bit count; count==0 leaves flags unchanged
	.SAR  = {written={.OP0}, read={.OP0, .OP1}, implicit_rd={.RCX}, flags_wr={.CF, .SF, .ZF, .PF, .OF}, flags_undef={.AF}, writes_mem=true, reads_mem=true},  // OF defined only for 1-bit count; count==0 leaves flags unchanged
	.ROL  = {written={.OP0}, read={.OP0, .OP1}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},  // only CF/OF affected; count==0 leaves flags unchanged
	.ROR  = {written={.OP0}, read={.OP0, .OP1}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, writes_mem=true, reads_mem=true},  // only CF/OF affected; count==0 leaves flags unchanged
	.RCL  = {written={.OP0}, read={.OP0, .OP1}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
	.RCR  = {written={.OP0}, read={.OP0, .OP1}, implicit_rd={.RCX}, flags_wr={.CF, .OF}, flags_rd={.CF}, writes_mem=true, reads_mem=true},
	.SHLD = {written={.OP0}, read={.OP0, .OP1, .OP2}, implicit_rd={.RCX}, flags_wr={.CF, .SF, .ZF, .PF}, flags_undef={.OF, .AF}, writes_mem=true, reads_mem=true},
	.SHRD = {written={.OP0}, read={.OP0, .OP1, .OP2}, implicit_rd={.RCX}, flags_wr={.CF, .SF, .ZF, .PF}, flags_undef={.OF, .AF}, writes_mem=true, reads_mem=true},

	// ---- 8.5 Bit Operation Encodings ----
	.BT     = {read={.OP0, .OP1}, flags_wr={.CF}, flags_undef={.OF, .SF, .AF, .PF}, reads_mem=true},  // ZF unaffected
	.BTS    = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.CF}, flags_undef={.OF, .SF, .AF, .PF}, writes_mem=true, reads_mem=true},  // ZF unaffected
	.BTR    = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.CF}, flags_undef={.OF, .SF, .AF, .PF}, writes_mem=true, reads_mem=true},  // ZF unaffected
	.BTC    = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.CF}, flags_undef={.OF, .SF, .AF, .PF}, writes_mem=true, reads_mem=true},  // ZF unaffected
	.BSF    = {written={.OP0}, read={.OP1}, flags_wr={.ZF}, flags_undef={.CF, .OF, .SF, .AF, .PF}, reads_mem=true},  // destination undefined when source == 0
	.BSR    = {written={.OP0}, read={.OP1}, flags_wr={.ZF}, flags_undef={.CF, .OF, .SF, .AF, .PF}, reads_mem=true},  // destination undefined when source == 0
	.POPCNT = {written={.OP0}, read={.OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true},  // ZF per source; CF/OF/SF/AF/PF cleared
	.LZCNT  = {written={.OP0}, read={.OP1}, flags_wr={.CF, .ZF}, flags_undef={.OF, .SF, .AF, .PF}, reads_mem=true},
	.TZCNT  = {written={.OP0}, read={.OP1}, flags_wr={.CF, .ZF}, flags_undef={.OF, .SF, .AF, .PF}, reads_mem=true},

	// ---- 8.6 Control Flow Encodings ----
	.JMP      = {read={.OP0}, reads_mem=true, side_effects={.CONTROL}},  // indirect forms read reg/mem; writes RIP
	.JA       = {flags_rd={.CF, .ZF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JAE      = {flags_rd={.CF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JB       = {flags_rd={.CF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JBE      = {flags_rd={.CF, .ZF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JC       = {flags_rd={.CF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JE       = {flags_rd={.ZF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JZ       = {flags_rd={.ZF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JG       = {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JGE      = {flags_rd={.SF, .OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JL       = {flags_rd={.SF, .OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JLE      = {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNA      = {flags_rd={.CF, .ZF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNAE     = {flags_rd={.CF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNB      = {flags_rd={.CF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNBE     = {flags_rd={.CF, .ZF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNC      = {flags_rd={.CF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNE      = {flags_rd={.ZF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNZ      = {flags_rd={.ZF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNG      = {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNGE     = {flags_rd={.SF, .OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNL      = {flags_rd={.SF, .OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNLE     = {flags_rd={.ZF, .SF, .OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNO      = {flags_rd={.OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNP      = {flags_rd={.PF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JNS      = {flags_rd={.SF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JO       = {flags_rd={.OF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JP       = {flags_rd={.PF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JPE      = {flags_rd={.PF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JPO      = {flags_rd={.PF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JS       = {flags_rd={.SF}, side_effects={.CONTROL}},  // reads flags; writes RIP on taken branch
	.JCXZ     = {implicit_rd={.RCX}, side_effects={.CONTROL}},  // reads CX
	.JECXZ    = {implicit_rd={.RCX}, side_effects={.CONTROL}},  // reads ECX
	.JRCXZ    = {implicit_rd={.RCX}, side_effects={.CONTROL}},  // reads RCX
	.LOOP     = {implicit_wr={.RCX}, implicit_rd={.RCX}, side_effects={.CONTROL}},
	.LOOPE    = {implicit_wr={.RCX}, implicit_rd={.RCX}, flags_rd={.ZF}, side_effects={.CONTROL}},
	.LOOPNE   = {implicit_wr={.RCX}, implicit_rd={.RCX}, flags_rd={.ZF}, side_effects={.CONTROL}},
	.CALL     = {read={.OP0}, implicit_wr={.RSP}, implicit_rd={.RSP}, writes_mem=true, reads_mem=true, side_effects={.CONTROL}},  // pushes return address
	.RET      = {implicit_wr={.RSP}, implicit_rd={.RSP}, reads_mem=true, side_effects={.CONTROL}},  // pops return address (+imm16 form adjusts RSP)
	.IRET     = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}},  // pops RIP/CS/RFLAGS (privileged bits conditionally)
	.IRETD    = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}},  // pops RIP/CS/RFLAGS (privileged bits conditionally)
	.IRETQ    = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true, side_effects={.SERIALIZING, .CONTROL}},  // pops RIP/CS/RFLAGS (privileged bits conditionally)
	.INT      = {read={.OP0}, implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}},  // pushes RFLAGS/CS/RIP; clears TF/IF via gate
	.INT3     = {read={.OP0}, implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}},  // pushes RFLAGS/CS/RIP; clears TF/IF via gate
	.INTO     = {implicit_wr={.RSP}, flags_wr={.IF}, flags_rd={.OF, .CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true, side_effects={.INTERRUPT, .CONTROL}},  // #OF only if OF=1
	.SYSCALL  = {implicit_wr={.RCX, .R11}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, side_effects={.INTERRUPT, .CONTROL}},  // RCX<-RIP, R11<-RFLAGS; RFLAGS masked by IA32_FMASK
	.SYSRET   = {implicit_rd={.RCX, .R11}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, side_effects={.SERIALIZING, .INTERRUPT, .PRIVILEGED, .CONTROL}},  // RIP<-RCX, RFLAGS<-R11
	.SYSENTER = {implicit_wr={.RSP}, flags_wr={.IF}, side_effects={.INTERRUPT, .CONTROL}},  // privileged; RSP/RIP from MSRs
	.SYSEXIT  = {implicit_wr={.RSP}, implicit_rd={.RCX, .RDX}, side_effects={.SERIALIZING, .INTERRUPT, .PRIVILEGED, .CONTROL}},  // privileged; RSP<-RDX/RCX, RIP<-RCX/RDX

	// ---- 8.7 Conditional Set/Move Encodings ----
	.SETA    = {written={.OP0}, flags_rd={.CF, .ZF}, writes_mem=true},
	.SETAE   = {written={.OP0}, flags_rd={.CF}, writes_mem=true},
	.SETB    = {written={.OP0}, flags_rd={.CF}, writes_mem=true},
	.SETBE   = {written={.OP0}, flags_rd={.CF, .ZF}, writes_mem=true},
	.SETC    = {written={.OP0}, flags_rd={.CF}, writes_mem=true},
	.SETE    = {written={.OP0}, flags_rd={.ZF}, writes_mem=true},
	.SETG    = {written={.OP0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true},
	.SETGE   = {written={.OP0}, flags_rd={.SF, .OF}, writes_mem=true},
	.SETL    = {written={.OP0}, flags_rd={.SF, .OF}, writes_mem=true},
	.SETLE   = {written={.OP0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true},
	.SETNA   = {written={.OP0}, flags_rd={.CF, .ZF}, writes_mem=true},
	.SETNAE  = {written={.OP0}, flags_rd={.CF}, writes_mem=true},
	.SETNB   = {written={.OP0}, flags_rd={.CF}, writes_mem=true},
	.SETNBE  = {written={.OP0}, flags_rd={.CF, .ZF}, writes_mem=true},
	.SETNC   = {written={.OP0}, flags_rd={.CF}, writes_mem=true},
	.SETNE   = {written={.OP0}, flags_rd={.ZF}, writes_mem=true},
	.SETNG   = {written={.OP0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true},
	.SETNGE  = {written={.OP0}, flags_rd={.SF, .OF}, writes_mem=true},
	.SETNL   = {written={.OP0}, flags_rd={.SF, .OF}, writes_mem=true},
	.SETNLE  = {written={.OP0}, flags_rd={.ZF, .SF, .OF}, writes_mem=true},
	.SETNO   = {written={.OP0}, flags_rd={.OF}, writes_mem=true},
	.SETNP   = {written={.OP0}, flags_rd={.PF}, writes_mem=true},
	.SETNS   = {written={.OP0}, flags_rd={.SF}, writes_mem=true},
	.SETNZ   = {written={.OP0}, flags_rd={.ZF}, writes_mem=true},
	.SETO    = {written={.OP0}, flags_rd={.OF}, writes_mem=true},
	.SETP    = {written={.OP0}, flags_rd={.PF}, writes_mem=true},
	.SETPE   = {written={.OP0}, flags_rd={.PF}, writes_mem=true},
	.SETPO   = {written={.OP0}, flags_rd={.PF}, writes_mem=true},
	.SETS    = {written={.OP0}, flags_rd={.SF}, writes_mem=true},
	.SETZ    = {written={.OP0}, flags_rd={.ZF}, writes_mem=true},
	.CMOVA   = {written={.OP0}, read={.OP1}, flags_rd={.CF, .ZF}, reads_mem=true},  // conditional write of OP0
	.CMOVAE  = {written={.OP0}, read={.OP1}, flags_rd={.CF}, reads_mem=true},  // conditional write of OP0
	.CMOVB   = {written={.OP0}, read={.OP1}, flags_rd={.CF}, reads_mem=true},  // conditional write of OP0
	.CMOVBE  = {written={.OP0}, read={.OP1}, flags_rd={.CF, .ZF}, reads_mem=true},  // conditional write of OP0
	.CMOVC   = {written={.OP0}, read={.OP1}, flags_rd={.CF}, reads_mem=true},  // conditional write of OP0
	.CMOVE   = {written={.OP0}, read={.OP1}, flags_rd={.ZF}, reads_mem=true},  // conditional write of OP0
	.CMOVG   = {written={.OP0}, read={.OP1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},  // conditional write of OP0
	.CMOVGE  = {written={.OP0}, read={.OP1}, flags_rd={.SF, .OF}, reads_mem=true},  // conditional write of OP0
	.CMOVL   = {written={.OP0}, read={.OP1}, flags_rd={.SF, .OF}, reads_mem=true},  // conditional write of OP0
	.CMOVLE  = {written={.OP0}, read={.OP1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},  // conditional write of OP0
	.CMOVNA  = {written={.OP0}, read={.OP1}, flags_rd={.CF, .ZF}, reads_mem=true},  // conditional write of OP0
	.CMOVNAE = {written={.OP0}, read={.OP1}, flags_rd={.CF}, reads_mem=true},  // conditional write of OP0
	.CMOVNB  = {written={.OP0}, read={.OP1}, flags_rd={.CF}, reads_mem=true},  // conditional write of OP0
	.CMOVNBE = {written={.OP0}, read={.OP1}, flags_rd={.CF, .ZF}, reads_mem=true},  // conditional write of OP0
	.CMOVNC  = {written={.OP0}, read={.OP1}, flags_rd={.CF}, reads_mem=true},  // conditional write of OP0
	.CMOVNE  = {written={.OP0}, read={.OP1}, flags_rd={.ZF}, reads_mem=true},  // conditional write of OP0
	.CMOVNG  = {written={.OP0}, read={.OP1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},  // conditional write of OP0
	.CMOVNGE = {written={.OP0}, read={.OP1}, flags_rd={.SF, .OF}, reads_mem=true},  // conditional write of OP0
	.CMOVNL  = {written={.OP0}, read={.OP1}, flags_rd={.SF, .OF}, reads_mem=true},  // conditional write of OP0
	.CMOVNLE = {written={.OP0}, read={.OP1}, flags_rd={.ZF, .SF, .OF}, reads_mem=true},  // conditional write of OP0
	.CMOVNO  = {written={.OP0}, read={.OP1}, flags_rd={.OF}, reads_mem=true},  // conditional write of OP0
	.CMOVNP  = {written={.OP0}, read={.OP1}, flags_rd={.PF}, reads_mem=true},  // conditional write of OP0
	.CMOVNS  = {written={.OP0}, read={.OP1}, flags_rd={.SF}, reads_mem=true},  // conditional write of OP0
	.CMOVNZ  = {written={.OP0}, read={.OP1}, flags_rd={.ZF}, reads_mem=true},  // conditional write of OP0
	.CMOVO   = {written={.OP0}, read={.OP1}, flags_rd={.OF}, reads_mem=true},  // conditional write of OP0
	.CMOVP   = {written={.OP0}, read={.OP1}, flags_rd={.PF}, reads_mem=true},  // conditional write of OP0
	.CMOVPE  = {written={.OP0}, read={.OP1}, flags_rd={.PF}, reads_mem=true},  // conditional write of OP0
	.CMOVPO  = {written={.OP0}, read={.OP1}, flags_rd={.PF}, reads_mem=true},  // conditional write of OP0
	.CMOVS   = {written={.OP0}, read={.OP1}, flags_rd={.SF}, reads_mem=true},  // conditional write of OP0
	.CMOVZ   = {written={.OP0}, read={.OP1}, flags_rd={.ZF}, reads_mem=true},  // conditional write of OP0

	// ---- 8.8 String Operation Encodings ----
	.MOVS  = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.MOVSB = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.MOVSW = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.MOVSD = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.MOVSQ = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.CMPS  = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.CMPSB = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.CMPSW = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.CMPSD = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.CMPSQ = {implicit_wr={.RSI, .RDI, .RCX}, implicit_rd={.RSI, .RDI, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.SCAS  = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.SCASB = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.SCASW = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.SCASD = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.SCASQ = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.LODS  = {implicit_wr={.RSI, .RAX}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.LODSB = {implicit_wr={.RSI, .RAX}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.LODSW = {implicit_wr={.RSI, .RAX}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.LODSD = {implicit_wr={.RSI, .RAX}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.LODSQ = {implicit_wr={.RSI, .RAX}, implicit_rd={.RSI}, flags_rd={.DF}, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.STOS  = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.STOSB = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.STOSW = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.STOSD = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX
	.STOSQ = {implicit_wr={.RDI, .RCX}, implicit_rd={.RDI, .RAX, .RCX}, flags_rd={.DF}, writes_mem=true, reads_mem=true},  // REP/REPZ/REPNZ forms read+write RCX

	// ---- 8.9 Flag Operation Encodings ----
	.CLC    = {flags_wr={.CF}},
	.STC    = {flags_wr={.CF}},
	.CMC    = {flags_wr={.CF}, flags_rd={.CF}},
	.CLD    = {flags_wr={.DF}},
	.STD    = {flags_wr={.DF}},
	.CLI    = {flags_wr={.IF}},
	.STI    = {flags_wr={.IF}},
	.LAHF   = {implicit_wr={.RAX}, flags_rd={.SF, .ZF, .AF, .PF, .CF}},  // AH <- flags
	.SAHF   = {implicit_rd={.RAX}, flags_wr={.SF, .ZF, .AF, .PF, .CF}},  // flags <- AH
	.PUSHF  = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true},
	.PUSHFD = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true},
	.PUSHFQ = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_rd={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, writes_mem=true},
	.POPF   = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true},
	.POPFD  = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true},
	.POPFQ  = {implicit_wr={.RSP}, implicit_rd={.RSP}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF, .DF, .IF}, reads_mem=true},

	// ---- 8.10 Miscellaneous Encodings ----
	.NOP    = {},  // no register/flag/memory clobber
	.HLT    = {side_effects={.HALT, .PRIVILEGED}},  // no register/flag/memory clobber
	.WAIT   = {implicit_rd={.FPU_SW}},  // waits on pending x87 exception
	.LOCK   = {side_effects={.FENCE}},  // no register/flag/memory clobber
	.UD0    = {side_effects={.TRAP}},  // no register/flag/memory clobber
	.UD1    = {side_effects={.TRAP}},  // no register/flag/memory clobber
	.UD2    = {side_effects={.TRAP}},  // no register/flag/memory clobber
	.CPUID  = {implicit_wr={.RAX, .RBX, .RCX, .RDX}, implicit_rd={.RAX, .RCX}, side_effects={.SERIALIZING}},
	.RDTSC  = {implicit_wr={.RAX, .RDX}},
	.RDTSCP = {implicit_wr={.RAX, .RDX, .RCX}},
	.RDPMC  = {implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}},
	.XGETBV = {implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}},
	.XSETBV = {implicit_rd={.RCX, .RDX, .RAX}},  // privileged; writes XCR[ECX]
	.CBW    = {implicit_wr={.RAX}, implicit_rd={.RAX}},
	.CWDE   = {implicit_wr={.RAX}, implicit_rd={.RAX}},
	.CDQE   = {implicit_wr={.RAX}, implicit_rd={.RAX}},
	.CWD    = {implicit_wr={.RDX}, implicit_rd={.RAX}},
	.CDQ    = {implicit_wr={.RDX}, implicit_rd={.RAX}},
	.CQO    = {implicit_wr={.RDX}, implicit_rd={.RAX}},

	// ---- 8.11 BMI/ADX Encodings ----
	.ANDN   = {written={.OP0}, read={.OP1, .OP2}, flags_wr={.SF, .ZF, .CF, .OF}, flags_undef={.AF, .PF}, reads_mem=true},
	.BEXTR  = {written={.OP0}, read={.OP1, .OP2}, flags_wr={.ZF, .CF, .OF}, flags_undef={.SF, .AF, .PF}, reads_mem=true},
	.BLSI   = {written={.OP0}, read={.OP1}, flags_wr={.CF, .SF, .ZF, .OF}, flags_undef={.AF, .PF}, reads_mem=true},
	.BLSMSK = {written={.OP0}, read={.OP1}, flags_wr={.CF, .SF, .ZF, .OF}, flags_undef={.AF, .PF}, reads_mem=true},
	.BLSR   = {written={.OP0}, read={.OP1}, flags_wr={.CF, .SF, .ZF, .OF}, flags_undef={.AF, .PF}, reads_mem=true},
	.BZHI   = {written={.OP0}, read={.OP1, .OP2}, flags_wr={.ZF, .SF, .CF, .OF}, flags_undef={.AF, .PF}, reads_mem=true},
	.PDEP   = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // no flags affected
	.PEXT   = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // no flags affected
	.RORX   = {written={.OP0}, read={.OP1}, reads_mem=true},  // no flags affected
	.SARX   = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // no flags affected (unlike SAR/SHL/SHR)
	.SHLX   = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // no flags affected (unlike SAR/SHL/SHR)
	.SHRX   = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // no flags affected (unlike SAR/SHL/SHR)
	.MULX   = {written={.OP0, .OP1}, read={.OP2}, implicit_rd={.RDX}, reads_mem=true},  // no flags affected; implicit multiplicand in rDX
	.ADCX   = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.CF}, flags_rd={.CF}, reads_mem=true},  // only CF (chains with ADCX)
	.ADOX   = {written={.OP0}, read={.OP0, .OP1}, flags_wr={.OF}, flags_rd={.OF}, reads_mem=true},  // only OF (chains with ADOX)

	// ---- 8.12 SSE Encodings ----
	.MOVAPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVUPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVAPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVUPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVSD_SSE       = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVDQA          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVDQU          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVQ            = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVD            = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVLPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVHPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVLPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVHPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVLHPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.MOVHLPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.MOVMSKPS        = {written={.OP0}, read={.OP1}},  // destination is a GPR
	.MOVMSKPD        = {written={.OP0}, read={.OP1}},  // destination is a GPR
	.MOVNTPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVNTPD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVNTDQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.MOVNTDQA        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.ADDPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.ADDPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.ADDSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.ADDSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.SUBPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.SUBPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.SUBSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.SUBSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MULPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MULPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MULSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MULSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.DIVPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.DIVPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.DIVSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.DIVSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.SQRTPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.SQRTPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.SQRTSS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.SQRTSD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.RCPPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.RCPSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.RSQRTPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.RSQRTSS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MAXPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MAXPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MAXSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MAXSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MINPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MINPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MINSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MINSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.ANDPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.ANDPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.ANDNPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.ANDNPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.ORPS            = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.ORPD            = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.XORPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.XORPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.CMPPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CMPPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CMPSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CMPSD_SSE       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.COMISS          = {read={.OP0, .OP1}, implicit_wr={.MXCSR}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}, reads_mem=true},  // OF/SF/AF cleared
	.COMISD          = {read={.OP0, .OP1}, implicit_wr={.MXCSR}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}, reads_mem=true},  // OF/SF/AF cleared
	.UCOMISS         = {read={.OP0, .OP1}, implicit_wr={.MXCSR}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}, reads_mem=true},  // OF/SF/AF cleared
	.UCOMISD         = {read={.OP0, .OP1}, implicit_wr={.MXCSR}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}, reads_mem=true},  // OF/SF/AF cleared
	.SHUFPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.SHUFPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.UNPCKLPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.UNPCKHPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.UNPCKLPD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.UNPCKHPD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.CVTPS2PD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTPD2PS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTSS2SD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTSD2SS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTPS2DQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTPD2DQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTDQ2PS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTDQ2PD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTSS2SI        = {written={.OP0}, read={.OP1}, implicit_wr={.MXCSR}, reads_mem=true},  // destination is a GPR
	.CVTSD2SI        = {written={.OP0}, read={.OP1}, implicit_wr={.MXCSR}, reads_mem=true},  // destination is a GPR
	.CVTSI2SS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTSI2SD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTTPS2DQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTTPD2DQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.CVTTSS2SI       = {written={.OP0}, read={.OP1}, implicit_wr={.MXCSR}, reads_mem=true},  // destination is a GPR
	.CVTTSD2SI       = {written={.OP0}, read={.OP1}, implicit_wr={.MXCSR}, reads_mem=true},  // destination is a GPR
	.PADDB           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PADDW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PADDD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PADDQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSUBB           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSUBW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSUBD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSUBQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PADDSB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PADDSW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PADDUSB         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PADDUSW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSUBSB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSUBSW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSUBUSB         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSUBUSW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMULLW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMULHW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMULHUW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMULUDQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMADDWD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PAND            = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PANDN           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.POR             = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PXOR            = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSLLW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSLLD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSLLQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSRLW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSRLD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSRLQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSRAW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSRAD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PCMPEQB         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PCMPEQW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PCMPEQD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PCMPGTB         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PCMPGTW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PCMPGTD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PACKSSWB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PACKSSDW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PACKUSWB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PUNPCKLBW       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PUNPCKLWD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PUNPCKLDQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PUNPCKLQDQ      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PUNPCKHBW       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PUNPCKHWD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PUNPCKHDQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PUNPCKHQDQ      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSHUFD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSHUFHW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSHUFLW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSHUFW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PEXTRW          = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.PINSRW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVMSKB        = {written={.OP0}, read={.OP1}},  // destination is a GPR
	.PAVGB           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PAVGW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMAXUB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMAXSW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMINUB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMINSW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSADBW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.MASKMOVDQU      = {read={.OP0, .OP1}, implicit_rd={.RDI}, flags_rd={.DF}, writes_mem=true},  // byte-masked store to DS:[rDI]
	.LFENCE          = {side_effects={.FENCE, .SERIALIZING}},  // ordering/hint; no clobber
	.SFENCE          = {side_effects={.FENCE}},  // ordering/hint; no clobber
	.MFENCE          = {side_effects={.FENCE}},  // ordering/hint; no clobber
	.PAUSE           = {side_effects={.HINT}},  // ordering/hint; no clobber
	.CLFLUSH         = {read={.OP0}, reads_mem=true, side_effects={.CACHE}},  // flushes cache line for the addressed byte
	.ADDSUBPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.ADDSUBPD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.HADDPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.HADDPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.HSUBPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.HSUBPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.MOVDDUP         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.MOVSLDUP        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.MOVSHDUP        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.LDDQU           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSHUFB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PHADDW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PHADDD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PHADDSW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PHSUBW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PHSUBD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PHSUBSW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMADDUBSW       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMULHRSW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSIGNB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSIGNW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PSIGND          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PABSB           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PABSW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PABSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PALIGNR         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.BLENDPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.BLENDPD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.BLENDVPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.BLENDVPD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PBLENDW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PBLENDVB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.DPPS            = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.DPPD            = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.EXTRACTPS       = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.INSERTPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.MPSADBW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PACKUSDW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PEXTRB          = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.PEXTRD          = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.PEXTRQ          = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.PHMINPOSUW      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PINSRB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PINSRD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PINSRQ          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMAXSB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMAXSD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMAXUW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMAXUD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMINSB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMINSD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMINUW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMINUD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVSXBW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVSXBD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVSXBQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVSXWD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVSXWQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVSXDQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVZXBW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVZXBD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVZXBQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVZXWD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVZXWQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMOVZXDQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMULDQ          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PMULLD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PTEST           = {read={.OP0, .OP1}, flags_wr={.ZF, .CF}, flags_undef={.OF, .SF, .AF, .PF}, reads_mem=true},  // ZF from AND, CF from ANDN; others cleared
	.ROUNDPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.ROUNDPD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.ROUNDSS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.ROUNDSD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.PCMPEQQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.CRC32           = {written={.OP0}, read={.OP0, .OP1}, reads_mem=true},  // accumulates CRC into OP0; no flags
	.PCMPESTRI       = {implicit_wr={.RCX}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .ZF, .SF, .OF, .AF, .PF}, reads_mem=true},  // ECX<-index; CF/ZF/SF/OF set, AF/PF cleared ; reads EAX/EDX lengths
	.PCMPESTRM       = {implicit_wr={.XMM0}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .ZF, .SF, .OF, .AF, .PF}, reads_mem=true},  // XMM0<-mask; CF/ZF/SF/OF set, AF/PF cleared ; reads EAX/EDX lengths
	.PCMPISTRI       = {implicit_wr={.RCX}, flags_wr={.CF, .ZF, .SF, .OF, .AF, .PF}, reads_mem=true},  // ECX<-index; CF/ZF/SF/OF set, AF/PF cleared
	.PCMPISTRM       = {implicit_wr={.XMM0}, flags_wr={.CF, .ZF, .SF, .OF, .AF, .PF}, reads_mem=true},  // XMM0<-mask; CF/ZF/SF/OF set, AF/PF cleared
	.PCMPGTQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.PCLMULQDQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.AESDEC          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.AESDECLAST      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.AESENC          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.AESENCLAST      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.AESIMC          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.AESKEYGENASSIST = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.SHA1MSG1        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.SHA1MSG2        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.SHA1NEXTE       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.SHA1RNDS4       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.SHA256MSG1      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.SHA256MSG2      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.SHA256RNDS2     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},

	// ---- 8.13 AVX/AVX2 Encodings ----
	.VADDPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VADDPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VADDSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VADDSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSUBPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSUBPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSUBSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSUBSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMULPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMULPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMULSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMULSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VDIVPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VDIVPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VDIVSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VDIVSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSQRTPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSQRTPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSQRTSS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSQRTSD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRCPPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRCPSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRSQRTPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRSQRTSS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMAXPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMAXPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMAXSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMAXSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMINPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMINPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMINSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VMINSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VANDPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VANDPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VANDNPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VANDNPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VORPS            = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VORPD            = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VXORPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VXORPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VCMPPS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCMPPD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCMPSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCMPSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCOMISS          = {read={.OP0, .OP1}, implicit_wr={.MXCSR}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}, reads_mem=true},  // OF/SF/AF cleared
	.VCOMISD          = {read={.OP0, .OP1}, implicit_wr={.MXCSR}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}, reads_mem=true},  // OF/SF/AF cleared
	.VUCOMISS         = {read={.OP0, .OP1}, implicit_wr={.MXCSR}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}, reads_mem=true},  // OF/SF/AF cleared
	.VUCOMISD         = {read={.OP0, .OP1}, implicit_wr={.MXCSR}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}, reads_mem=true},  // OF/SF/AF cleared
	.VSHUFPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VSHUFPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VUNPCKLPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VUNPCKHPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VUNPCKLPD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VUNPCKHPD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBLENDPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBLENDPD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBLENDVPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBLENDVPD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VDPPS            = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VDPPD            = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VROUNDPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VROUNDPD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VROUNDSS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VROUNDSD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VEXTRACTPS       = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.VINSERTPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVAPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVUPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVAPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVUPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVSS           = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVDQA          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVDQU          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVQ            = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVD            = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVLPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVHPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVLPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVHPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVLHPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVHLPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVMSKPS        = {written={.OP0}, read={.OP1}},  // destination is a GPR
	.VMOVMSKPD        = {written={.OP0}, read={.OP1}},  // destination is a GPR
	.VMOVNTPS         = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVNTPD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVNTDQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMOVNTDQA        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VADDSUBPS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VADDSUBPD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VHADDPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VHADDPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VHSUBPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VHSUBPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VLDDQU           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVDDUP         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVSLDUP        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVSHDUP        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPESTRI       = {implicit_wr={.RCX}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .ZF, .SF, .OF, .AF, .PF}, reads_mem=true},  // ECX<-index; CF/ZF/SF/OF set, AF/PF cleared ; reads EAX/EDX lengths
	.VPCMPESTRM       = {implicit_wr={.XMM0}, implicit_rd={.RAX, .RDX}, flags_wr={.CF, .ZF, .SF, .OF, .AF, .PF}, reads_mem=true},  // XMM0<-mask; CF/ZF/SF/OF set, AF/PF cleared ; reads EAX/EDX lengths
	.VPCMPISTRI       = {implicit_wr={.RCX}, flags_wr={.CF, .ZF, .SF, .OF, .AF, .PF}, reads_mem=true},  // ECX<-index; CF/ZF/SF/OF set, AF/PF cleared
	.VPCMPISTRM       = {implicit_wr={.XMM0}, flags_wr={.CF, .ZF, .SF, .OF, .AF, .PF}, reads_mem=true},  // XMM0<-mask; CF/ZF/SF/OF set, AF/PF cleared
	.VPBROADCASTB     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBROADCASTW     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBROADCASTD     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBROADCASTQ     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VCVTPS2PD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTPD2PS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTSS2SD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTSD2SS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTPS2DQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTPD2DQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTDQ2PS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTDQ2PD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTSS2SI        = {written={.OP0}, read={.OP1}, implicit_wr={.MXCSR}, reads_mem=true},  // destination is a GPR
	.VCVTSD2SI        = {written={.OP0}, read={.OP1}, implicit_wr={.MXCSR}, reads_mem=true},  // destination is a GPR
	.VCVTSI2SS        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTSI2SD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTTPS2DQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTTPD2DQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTTSS2SI       = {written={.OP0}, read={.OP1}, implicit_wr={.MXCSR}, reads_mem=true},  // destination is a GPR
	.VCVTTSD2SI       = {written={.OP0}, read={.OP1}, implicit_wr={.MXCSR}, reads_mem=true},  // destination is a GPR
	.VPADDB           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPADDW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPADDD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPADDQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSUBB           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSUBW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSUBD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSUBQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMULLW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMULHW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMULHUW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMULUDQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMADDWD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPAND            = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPANDN           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPOR             = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPXOR            = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSLLW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSLLD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSLLQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRLW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRLD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRLQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRAW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRAD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPEQB         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPEQW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPEQD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPEQQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPGTB         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPGTW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPGTD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPGTQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPACKSSWB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPACKSSDW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPACKUSWB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPACKUSDW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPUNPCKLBW       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPUNPCKLWD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPUNPCKLDQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPUNPCKLQDQ      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPUNPCKHBW       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPUNPCKHWD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPUNPCKHDQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPUNPCKHQDQ      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSHUFD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSHUFHW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSHUFLW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPEXTRB          = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.VPEXTRW          = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.VPEXTRD          = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.VPEXTRQ          = {written={.OP0}, read={.OP1}, writes_mem=true},  // destination may be memory
	.VPINSRB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPINSRW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPINSRD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPINSRQ          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVMSKB        = {written={.OP0}, read={.OP1}},  // destination is a GPR
	.VPTEST           = {read={.OP0, .OP1}, flags_wr={.ZF, .CF}, flags_undef={.OF, .SF, .AF, .PF}, reads_mem=true},  // ZF from AND, CF from ANDN; others cleared
	.VPSHUFB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPHADDW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPHADDD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPHADDSW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPHSUBW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPHSUBD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPHSUBSW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMADDUBSW       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMULHRSW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSIGNB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSIGNW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSIGND          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPABSB           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPABSW           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPABSD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPALIGNR         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBLENDW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBLENDVB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMPSADBW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPHMINPOSUW      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMAXSB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMAXSD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMAXUW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMAXUD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMINSB          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMINSD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMINUW          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMINUD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSXBW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSXBD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSXBQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSXWD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSXWQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSXDQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVZXBW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVZXBD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVZXBQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVZXWD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVZXWQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVZXDQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMULDQ          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMULLD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMASKMOVDQU      = {read={.OP0, .OP1}, implicit_rd={.RDI}, flags_rd={.DF}, writes_mem=true},  // byte-masked store to DS:[rDI]
	.VPCLMULQDQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VAESDEC          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VAESDECLAST      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VAESENC          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VAESENCLAST      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VAESIMC          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VAESKEYGENASSIST = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBROADCASTSS     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBROADCASTSD     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBROADCASTF128   = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VEXTRACTF128     = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VINSERTF128      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERM2F128       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMASKMOVPS       = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VMASKMOVPD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VTESTPS          = {read={.OP0, .OP1}, flags_wr={.ZF, .CF}, flags_undef={.OF, .SF, .AF, .PF}, reads_mem=true},  // ZF from AND, CF from ANDN; others cleared
	.VTESTPD          = {read={.OP0, .OP1}, flags_wr={.ZF, .CF}, flags_undef={.OF, .SF, .AF, .PF}, reads_mem=true},  // ZF from AND, CF from ANDN; others cleared
	.VZEROALL         = {implicit_wr={.VECTOR}},  // zeroes the entire vector register file (YMM/ZMM)
	.VZEROUPPER       = {implicit_wr={.VECTOR}},  // zeroes bits [MAXVL-1:128] of every vector register
	.VBROADCASTI128   = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VEXTRACTI128     = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VINSERTI128      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERM2I128       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMD           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMPS          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMQ           = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMPD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBLENDD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSLLVD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSLLVQ          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRLVD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRLVQ          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRAVD          = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMASKMOVD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VPMASKMOVQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, writes_mem=true, reads_mem=true},
	.VGATHERDPS       = {written={.OP0, .OP2}, read={.OP0, .OP1, .OP2}, reads_mem=true},  // mask operand (OP2) is zeroed as elements are gathered
	.VGATHERDPD       = {written={.OP0, .OP2}, read={.OP0, .OP1, .OP2}, reads_mem=true},  // mask operand (OP2) is zeroed as elements are gathered
	.VGATHERQPS       = {written={.OP0, .OP2}, read={.OP0, .OP1, .OP2}, reads_mem=true},  // mask operand (OP2) is zeroed as elements are gathered
	.VGATHERQPD       = {written={.OP0, .OP2}, read={.OP0, .OP1, .OP2}, reads_mem=true},  // mask operand (OP2) is zeroed as elements are gathered
	.VPGATHERDD       = {written={.OP0, .OP2}, read={.OP0, .OP1, .OP2}, reads_mem=true},  // mask operand (OP2) is zeroed as elements are gathered
	.VPGATHERDQ       = {written={.OP0, .OP2}, read={.OP0, .OP1, .OP2}, reads_mem=true},  // mask operand (OP2) is zeroed as elements are gathered
	.VPGATHERQD       = {written={.OP0, .OP2}, read={.OP0, .OP1, .OP2}, reads_mem=true},  // mask operand (OP2) is zeroed as elements are gathered
	.VPGATHERQQ       = {written={.OP0, .OP2}, read={.OP0, .OP1, .OP2}, reads_mem=true},  // mask operand (OP2) is zeroed as elements are gathered

	// ---- 8.14 FMA Encodings ----
	.VFMADD132PS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD213PS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD231PS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD132PD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD213PD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD231PD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD132SS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD213SS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD231SS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD132SD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD213SD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADD231SD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB132PS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB213PS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB231PS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB132PD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB213PD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB231PD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB132SS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB213SS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB231SS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB132SD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB213SD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUB231SD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD132PS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD213PS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD231PS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD132PD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD213PD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD231PD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD132SS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD213SS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD231SS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD132SD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD213SD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMADD231SD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB132PS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB213PS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB231PS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB132PD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB213PD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB231PD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB132SS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB213SS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB231SS   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB132SD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB213SD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFNMSUB231SD   = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADDSUB132PS = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADDSUB213PS = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADDSUB231PS = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADDSUB132PD = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADDSUB213PD = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMADDSUB231PD = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUBADD132PS = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUBADD213PS = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUBADD231PS = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUBADD132PD = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUBADD213PD = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFMSUBADD231PD = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTPH2PS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VCVTPS2PH      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, writes_mem=true, reads_mem=true},  // may set MXCSR exception/status bits

	// ---- 8.15 AVX-512 Encodings ----
	.VMOVDQA32      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVDQA64      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVDQU8       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVDQU16      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVDQU32      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VMOVDQU64      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBLENDMB      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBLENDMW      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBLENDMD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPBLENDMQ      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBLENDMPS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VBLENDMPD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCMPB         = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPCMPUB        = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPCMPW         = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPCMPUW        = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPCMPD         = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPCMPUD        = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPCMPQ         = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPCMPUQ        = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPTESTMB       = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPTESTMW       = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPTESTMD       = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPTESTMQ       = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPTESTNMB      = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPTESTNMW      = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPTESTNMD      = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPTESTNMQ      = {written={.OP0}, read={.OP1, .OP2}, reads_mem=true},  // result written to an opmask register (k1), not EFLAGS
	.VPCOMPRESSD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCOMPRESSQ    = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VCOMPRESSPS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VCOMPRESSPD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPEXPANDD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPEXPANDQ      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VEXPANDPS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VEXPANDPD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCONFLICTD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPCONFLICTQ    = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPLZCNTD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPLZCNTQ       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMI2B       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMI2W       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMI2D       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMI2Q       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMI2PS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMI2PD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMT2B       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMT2W       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMT2D       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMT2Q       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMT2PS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMT2PD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMB         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPERMW         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVB2M       = {written={.OP0}, read={.OP1}},  // sign bits -> opmask register
	.VPMOVW2M       = {written={.OP0}, read={.OP1}},  // sign bits -> opmask register
	.VPMOVD2M       = {written={.OP0}, read={.OP1}},  // sign bits -> opmask register
	.VPMOVQ2M       = {written={.OP0}, read={.OP1}},  // sign bits -> opmask register
	.VPMOVM2B       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVM2W       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVM2D       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVM2Q       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVQB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSQB       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVUSQB      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVQW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSQW       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVUSQW      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVQD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSQD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVUSQD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVDB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSDB       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVUSDB      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVDW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSDW       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVUSDW      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVWB        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVSWB       = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMOVUSWB      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPROLD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPROLQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPROLVD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPROLVQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPRORD         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPRORQ         = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPRORVD        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPRORVQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSCATTERDD    = {read={.OP0, .OP1}, writes_mem=true},  // opmask k1 is consumed and cleared per element
	.VPSCATTERDQ    = {read={.OP0, .OP1}, writes_mem=true},  // opmask k1 is consumed and cleared per element
	.VPSCATTERQD    = {read={.OP0, .OP1}, writes_mem=true},  // opmask k1 is consumed and cleared per element
	.VPSCATTERQQ    = {read={.OP0, .OP1}, writes_mem=true},  // opmask k1 is consumed and cleared per element
	.VSCATTERDPS    = {read={.OP0, .OP1}, writes_mem=true},  // opmask k1 is consumed and cleared per element
	.VSCATTERDPD    = {read={.OP0, .OP1}, writes_mem=true},  // opmask k1 is consumed and cleared per element
	.VSCATTERQPS    = {read={.OP0, .OP1}, writes_mem=true},  // opmask k1 is consumed and cleared per element
	.VSCATTERQPD    = {read={.OP0, .OP1}, writes_mem=true},  // opmask k1 is consumed and cleared per element
	.VPSRAVQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRAVW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSLLVW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPSRLVW        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VRANGEPS       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRANGEPD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRANGESS       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRANGESD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VREDUCEPS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VREDUCEPD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VREDUCESS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VREDUCESD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRNDSCALEPS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRNDSCALEPD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRNDSCALESS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRNDSCALESD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRSQRT14PS     = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRSQRT14PD     = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRSQRT14SS     = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRSQRT14SD     = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRCP14PS       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRCP14PD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRCP14SS       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VRCP14SD       = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSCALEFPS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSCALEFPD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSCALEFSS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VSCALEFSD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VGETEXPPS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VGETEXPPD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VGETEXPSS      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VGETEXPSD      = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VGETMANTPS     = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VGETMANTPD     = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VGETMANTSS     = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VGETMANTSD     = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFIXUPIMMPS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFIXUPIMMPD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFIXUPIMMSS    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFIXUPIMMSD    = {written={.OP0}, read={.OP1, .OP2, .OP3}, implicit_wr={.MXCSR}, reads_mem=true},  // may set MXCSR exception/status bits
	.VFPCLASSPS     = {written={.OP0}, read={.OP1}, reads_mem=true},  // class predicate written to an opmask register
	.VFPCLASSPD     = {written={.OP0}, read={.OP1}, reads_mem=true},  // class predicate written to an opmask register
	.VFPCLASSSS     = {written={.OP0}, read={.OP1}, reads_mem=true},  // class predicate written to an opmask register
	.VFPCLASSSD     = {written={.OP0}, read={.OP1}, reads_mem=true},  // class predicate written to an opmask register
	.VALIGNQ        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VALIGND        = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VDBPSADBW      = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPTERNLOGD     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPTERNLOGQ     = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.VPMULTISHIFTQB = {written={.OP0}, read={.OP1, .OP2, .OP3}, reads_mem=true},
	.KADDW          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KADDB          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KADDQ          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KADDD          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KANDW          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KANDB          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KANDQ          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KANDD          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KANDNW         = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KANDNB         = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KANDNQ         = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KANDND         = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KMOVW          = {written={.OP0}, read={.OP1}, writes_mem=true, reads_mem=true},  // opmask <-> GPR/mem/opmask
	.KMOVB          = {written={.OP0}, read={.OP1}, writes_mem=true, reads_mem=true},  // opmask <-> GPR/mem/opmask
	.KMOVQ          = {written={.OP0}, read={.OP1}, writes_mem=true, reads_mem=true},  // opmask <-> GPR/mem/opmask
	.KMOVD          = {written={.OP0}, read={.OP1}, writes_mem=true, reads_mem=true},  // opmask <-> GPR/mem/opmask
	.KNOTW          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KNOTB          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KNOTQ          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KNOTD          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KORW           = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KORB           = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KORQ           = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KORD           = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KORTESTW       = {read={.OP0, .OP1}, flags_wr={.ZF, .CF, .PF, .SF, .OF, .AF}},  // sets ZF/CF from mask test
	.KORTESTB       = {read={.OP0, .OP1}, flags_wr={.ZF, .CF, .PF, .SF, .OF, .AF}},  // sets ZF/CF from mask test
	.KORTESTQ       = {read={.OP0, .OP1}, flags_wr={.ZF, .CF, .PF, .SF, .OF, .AF}},  // sets ZF/CF from mask test
	.KORTESTD       = {read={.OP0, .OP1}, flags_wr={.ZF, .CF, .PF, .SF, .OF, .AF}},  // sets ZF/CF from mask test
	.KSHIFTLW       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KSHIFTLB       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KSHIFTLQ       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KSHIFTLD       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KSHIFTRW       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KSHIFTRB       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KSHIFTRQ       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KSHIFTRD       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KTESTW         = {read={.OP0, .OP1}, flags_wr={.ZF, .CF, .PF, .SF, .OF, .AF}},  // sets ZF/CF from mask test
	.KTESTB         = {read={.OP0, .OP1}, flags_wr={.ZF, .CF, .PF, .SF, .OF, .AF}},  // sets ZF/CF from mask test
	.KTESTQ         = {read={.OP0, .OP1}, flags_wr={.ZF, .CF, .PF, .SF, .OF, .AF}},  // sets ZF/CF from mask test
	.KTESTD         = {read={.OP0, .OP1}, flags_wr={.ZF, .CF, .PF, .SF, .OF, .AF}},  // sets ZF/CF from mask test
	.KUNPCKBW       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KUNPCKWD       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KUNPCKDQ       = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KXNORW         = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KXNORB         = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KXNORQ         = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KXNORD         = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KXORW          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KXORB          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KXORQ          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation
	.KXORD          = {written={.OP0}, read={.OP1, .OP2}},  // opmask register operation

	// ---- 8.16 x87 FPU Encodings ----
	.FADD      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FADDP     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FIADD     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FSUB      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FSUBP     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FISUB     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FSUBR     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FSUBRP    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FISUBR    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FMUL      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FMULP     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FIMUL     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FDIV      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FDIVP     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FIDIV     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FDIVR     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FDIVRP    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FIDIVR    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FSQRT     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FABS      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FCHS      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FPREM     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FPREM1    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FRNDINT   = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FSCALE    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FXTRACT   = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FXAM      = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FLD       = {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},  // push onto x87 stack
	.FILD      = {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},  // push onto x87 stack
	.FBLD      = {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},  // push onto x87 stack
	.FST       = {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},  // store (FSTP/FISTP/FBSTP pop the stack)
	.FSTP      = {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},  // store (FSTP/FISTP/FBSTP pop the stack)
	.FIST      = {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},  // store (FSTP/FISTP/FBSTP pop the stack)
	.FISTP     = {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},  // store (FSTP/FISTP/FBSTP pop the stack)
	.FISTTP    = {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},  // store (FSTP/FISTP/FBSTP pop the stack)
	.FBSTP     = {implicit_wr={.FPU_ST, .FPU_SW}, writes_mem=true},  // store (FSTP/FISTP/FBSTP pop the stack)
	.FXCH      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FCMOVB    = {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF}},  // conditional x87 move; reads EFLAGS
	.FCMOVE    = {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.ZF}},  // conditional x87 move; reads EFLAGS
	.FCMOVBE   = {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF, .ZF}},  // conditional x87 move; reads EFLAGS
	.FCMOVU    = {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.PF}},  // conditional x87 move; reads EFLAGS
	.FCMOVNB   = {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF}},  // conditional x87 move; reads EFLAGS
	.FCMOVNE   = {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.ZF}},  // conditional x87 move; reads EFLAGS
	.FCMOVNBE  = {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.CF, .ZF}},  // conditional x87 move; reads EFLAGS
	.FCMOVNU   = {implicit_wr={.FPU_ST}, implicit_rd={.FPU_ST}, flags_rd={.PF}},  // conditional x87 move; reads EFLAGS
	.FCOM      = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FCOMP     = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FCOMPP    = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FICOM     = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FICOMP    = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FCOMI     = {implicit_rd={.FPU_ST}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}},  // compares ST(0):ST(i) into EFLAGS
	.FCOMIP    = {implicit_rd={.FPU_ST}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}},  // compares ST(0):ST(i) into EFLAGS
	.FUCOMI    = {implicit_rd={.FPU_ST}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}},  // compares ST(0):ST(i) into EFLAGS
	.FUCOMIP   = {implicit_rd={.FPU_ST}, flags_wr={.ZF, .PF, .CF}, flags_undef={.OF, .SF, .AF}},  // compares ST(0):ST(i) into EFLAGS
	.FUCOM     = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FUCOMP    = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FUCOMPP   = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FTST      = {implicit_wr={.FPU_SW}, implicit_rd={.FPU_ST}},  // sets x87 condition codes C0-C3 (status word), not EFLAGS
	.FLDZ      = {implicit_wr={.FPU_ST, .FPU_SW}},  // push onto x87 stack
	.FLD1      = {implicit_wr={.FPU_ST, .FPU_SW}},  // push onto x87 stack
	.FLDPI     = {implicit_wr={.FPU_ST, .FPU_SW}},  // push onto x87 stack
	.FLDL2T    = {implicit_wr={.FPU_ST, .FPU_SW}},  // push onto x87 stack
	.FLDL2E    = {implicit_wr={.FPU_ST, .FPU_SW}},  // push onto x87 stack
	.FLDLG2    = {implicit_wr={.FPU_ST, .FPU_SW}},  // push onto x87 stack
	.FLDLN2    = {implicit_wr={.FPU_ST, .FPU_SW}},  // push onto x87 stack
	.FSIN      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FCOS      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FSINCOS   = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FPTAN     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FPATAN    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.F2XM1     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FYL2X     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FYL2XP1   = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FINIT     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FNINIT    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FINCSTP   = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FDECSTP   = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FFREE     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FFREEP    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FNOP      = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FWAIT     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}, reads_mem=true},  // x87 arithmetic: updates ST(0) and status word C1
	.FCLEX     = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FNCLEX    = {implicit_wr={.FPU_ST, .FPU_SW}, implicit_rd={.FPU_ST}},  // x87 arithmetic: updates ST(0) and status word C1
	.FSTCW     = {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},  // stores x87 (and SSE) state to memory
	.FNSTCW    = {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},  // stores x87 (and SSE) state to memory
	.FLDCW     = {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},  // loads x87 (and SSE) state from memory
	.FSTENV    = {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},  // stores x87 (and SSE) state to memory
	.FNSTENV   = {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},  // stores x87 (and SSE) state to memory
	.FLDENV    = {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},  // loads x87 (and SSE) state from memory
	.FSAVE     = {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},  // stores x87 (and SSE) state to memory
	.FNSAVE    = {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},  // stores x87 (and SSE) state to memory
	.FRSTOR    = {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},  // loads x87 (and SSE) state from memory
	.FSTSW     = {implicit_wr={.RAX, .FPU_SW}, writes_mem=true},  // AX form writes AX; m2byte form writes memory
	.FNSTSW    = {implicit_wr={.RAX, .FPU_SW}, writes_mem=true},  // AX form writes AX; m2byte form writes memory
	.FXSAVE    = {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},  // stores x87 (and SSE) state to memory
	.FXSAVE64  = {implicit_rd={.FPU_ST, .FPU_SW}, writes_mem=true},  // stores x87 (and SSE) state to memory
	.FXRSTOR   = {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},  // loads x87 (and SSE) state from memory
	.FXRSTOR64 = {implicit_wr={.FPU_ST, .FPU_SW}, reads_mem=true},  // loads x87 (and SSE) state from memory

	// ---- 8.17 System Instruction Encodings ----
	.LGDT     = {read={.OP0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged load
	.SGDT     = {written={.OP0}, writes_mem=true},  // stores descriptor/register to r/m (privileged for some)
	.LIDT     = {read={.OP0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged load
	.SIDT     = {written={.OP0}, writes_mem=true},  // stores descriptor/register to r/m (privileged for some)
	.LLDT     = {read={.OP0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged load
	.SLDT     = {written={.OP0}, writes_mem=true},  // stores descriptor/register to r/m (privileged for some)
	.LTR      = {read={.OP0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged load
	.STR      = {written={.OP0}, writes_mem=true},  // stores descriptor/register to r/m (privileged for some)
	.LMSW     = {read={.OP0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged load
	.SMSW     = {written={.OP0}, writes_mem=true},  // stores descriptor/register to r/m (privileged for some)
	.CLTS     = {side_effects={.PRIVILEGED}},  // privileged; no GPR/EFLAGS clobber modeled
	.ARPL     = {written={.OP0}, read={.OP1}, flags_wr={.ZF}, writes_mem=true, reads_mem=true},  // legacy; adjusts RPL, sets ZF
	.LAR      = {written={.OP0}, read={.OP1}, flags_wr={.ZF}, reads_mem=true},  // ZF=1 on success; OP0 undefined on failure
	.LSL      = {written={.OP0}, read={.OP1}, flags_wr={.ZF}, reads_mem=true},  // ZF=1 on success; OP0 undefined on failure
	.VERR     = {read={.OP0}, flags_wr={.ZF}, reads_mem=true},  // ZF=1 if segment is readable/writable
	.VERW     = {read={.OP0}, flags_wr={.ZF}, reads_mem=true},  // ZF=1 if segment is readable/writable
	.INVD     = {side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged; no GPR/EFLAGS clobber modeled
	.WBINVD   = {side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged; no GPR/EFLAGS clobber modeled
	.INVLPG   = {read={.OP0}, reads_mem=true, side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged; no GPR/EFLAGS clobber modeled
	.INVPCID  = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF
	.RSM      = {side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged; no GPR/EFLAGS clobber modeled
	.RDMSR    = {implicit_wr={.RAX, .RDX}, implicit_rd={.RCX}, side_effects={.PRIVILEGED}},  // privileged; EDX:EAX <- MSR[ECX]
	.WRMSR    = {implicit_rd={.RAX, .RCX, .RDX}, side_effects={.SERIALIZING, .PRIVILEGED}},  // privileged; MSR[ECX] <- EDX:EAX
	.VMCALL   = {side_effects={.PRIVILEGED}},  // privileged; no GPR/EFLAGS clobber modeled
	.VMLAUNCH = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF
	.VMRESUME = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF
	.VMXOFF   = {side_effects={.PRIVILEGED}},  // privileged; no GPR/EFLAGS clobber modeled
	.VMXON    = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF
	.VMCLEAR  = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF
	.VMPTRLD  = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF
	.VMPTRST  = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF
	.VMREAD   = {written={.OP0}, read={.OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX status in ZF/CF
	.VMWRITE  = {read={.OP0, .OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX status in ZF/CF
	.VMFUNC   = {side_effects={.PRIVILEGED}},  // privileged; no GPR/EFLAGS clobber modeled
	.INVEPT   = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF
	.INVVPID  = {read={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, reads_mem=true, side_effects={.PRIVILEGED}},  // VMX/INVx status reported in ZF/CF

	// ---- 8.18 Security and Memory Protection Encodings ----
	.ENCLS       = {side_effects={.PRIVILEGED}},  // SGX enclave leaf; behaviour selected by EAX
	.ENCLU       = {side_effects={.PRIVILEGED}},  // SGX enclave leaf; behaviour selected by EAX
	.ENCLV       = {side_effects={.PRIVILEGED}},  // SGX enclave leaf; behaviour selected by EAX
	.RDPKRU      = {implicit_wr={.RAX}, implicit_rd={.RCX}},  // EAX <- PKRU (EDX cleared); reads ECX
	.WRPKRU      = {implicit_rd={.RAX, .RCX, .RDX}},  // PKRU <- EAX; ECX/EDX must be 0
	.INCSSPD     = {read={.OP0}, writes_mem=true, side_effects={.CET}},  // advances SSP
	.INCSSPQ     = {read={.OP0}, writes_mem=true, side_effects={.CET}},  // advances SSP
	.RDSSPD      = {written={.OP0}, side_effects={.CET}},  // reads shadow-stack pointer into OP0
	.RDSSPQ      = {written={.OP0}, side_effects={.CET}},  // reads shadow-stack pointer into OP0
	.SAVEPREVSSP = {side_effects={.CET}},  // CET shadow-stack management
	.RSTORSSP    = {side_effects={.CET}},  // CET shadow-stack management
	.WRSSD       = {read={.OP0, .OP1}, writes_mem=true, side_effects={.CET}},  // writes to shadow stack
	.WRSSQ       = {read={.OP0, .OP1}, writes_mem=true, side_effects={.CET}},  // writes to shadow stack
	.WRUSSD      = {read={.OP0, .OP1}, writes_mem=true, side_effects={.CET}},  // writes to shadow stack
	.WRUSSQ      = {read={.OP0, .OP1}, writes_mem=true, side_effects={.CET}},  // writes to shadow stack
	.SETSSBSY    = {side_effects={.CET}},  // CET shadow-stack management
	.CLRSSBSY    = {side_effects={.CET}},  // CET shadow-stack management
	.ENDBR64     = {side_effects={.HINT, .CET}},  // CET landing pad; NOP-like
	.ENDBR32     = {side_effects={.HINT, .CET}},  // CET landing pad; NOP-like

	// ---- 8.19 XSAVE/XRSTOR State Management Encodings ----
	.XSAVE      = {implicit_rd={.RAX, .RDX}, writes_mem=true},  // saves state components selected by EDX:EAX
	.XSAVE64    = {implicit_rd={.RAX, .RDX}, writes_mem=true},  // saves state components selected by EDX:EAX
	.XRSTOR     = {implicit_wr={.FPU_ST, .FPU_SW, .MXCSR}, implicit_rd={.RAX, .RDX}, reads_mem=true},  // restores state components selected by EDX:EAX
	.XRSTOR64   = {implicit_wr={.FPU_ST, .FPU_SW, .MXCSR}, implicit_rd={.RAX, .RDX}, reads_mem=true},  // restores state components selected by EDX:EAX
	.XSAVEOPT   = {implicit_rd={.RAX, .RDX}, writes_mem=true},  // saves state components selected by EDX:EAX
	.XSAVEOPT64 = {implicit_rd={.RAX, .RDX}, writes_mem=true},  // saves state components selected by EDX:EAX
	.XSAVEC     = {implicit_rd={.RAX, .RDX}, writes_mem=true},  // saves state components selected by EDX:EAX
	.XSAVEC64   = {implicit_rd={.RAX, .RDX}, writes_mem=true},  // saves state components selected by EDX:EAX
	.XSAVES     = {implicit_rd={.RAX, .RDX}, writes_mem=true, side_effects={.PRIVILEGED}},  // saves state components selected by EDX:EAX
	.XSAVES64   = {implicit_rd={.RAX, .RDX}, writes_mem=true, side_effects={.PRIVILEGED}},  // saves state components selected by EDX:EAX
	.XRSTORS    = {implicit_wr={.FPU_ST, .FPU_SW, .MXCSR}, implicit_rd={.RAX, .RDX}, reads_mem=true, side_effects={.PRIVILEGED}},  // restores state components selected by EDX:EAX
	.XRSTORS64  = {implicit_wr={.FPU_ST, .FPU_SW, .MXCSR}, implicit_rd={.RAX, .RDX}, reads_mem=true, side_effects={.PRIVILEGED}},  // restores state components selected by EDX:EAX

	// ---- 8.20 Cache and Prefetch Encodings ----
	.PREFETCHT0  = {read={.OP0}, reads_mem=true, side_effects={.HINT}},  // cache hint/maintenance; no register or flag clobber
	.PREFETCHT1  = {read={.OP0}, reads_mem=true, side_effects={.HINT}},  // cache hint/maintenance; no register or flag clobber
	.PREFETCHT2  = {read={.OP0}, reads_mem=true, side_effects={.HINT}},  // cache hint/maintenance; no register or flag clobber
	.PREFETCHNTA = {read={.OP0}, reads_mem=true, side_effects={.HINT}},  // cache hint/maintenance; no register or flag clobber
	.PREFETCHW   = {read={.OP0}, reads_mem=true, side_effects={.HINT}},  // cache hint/maintenance; no register or flag clobber
	.CLFLUSHOPT  = {read={.OP0}, reads_mem=true, side_effects={.CACHE}},  // cache hint/maintenance; no register or flag clobber
	.CLWB        = {read={.OP0}, reads_mem=true, side_effects={.CACHE}},  // cache hint/maintenance; no register or flag clobber
	.CLDEMOTE    = {read={.OP0}, reads_mem=true, side_effects={.HINT}},  // cache hint/maintenance; no register or flag clobber

	// ---- 8.21 Atomic and Byte Swap Encodings ----
	.BSWAP      = {written={.OP0}, read={.OP0}},
	.CMPXCHG    = {written={.OP0}, read={.OP0, .OP1}, implicit_wr={.RAX}, implicit_rd={.RAX}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},  // ZF set on match; on mismatch RAX <- dest
	.CMPXCHG8B  = {read={.OP0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX, .RBX, .RCX}, flags_wr={.ZF}, writes_mem=true, reads_mem=true},  // EDX:EAX (RDX:RAX) compared; ECX:EBX (RCX:RBX) is the new value
	.CMPXCHG16B = {read={.OP0}, implicit_wr={.RAX, .RDX}, implicit_rd={.RAX, .RDX, .RBX, .RCX}, flags_wr={.ZF}, writes_mem=true, reads_mem=true},  // EDX:EAX (RDX:RAX) compared; ECX:EBX (RCX:RBX) is the new value
	.XADD       = {written={.OP0, .OP1}, read={.OP0, .OP1}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}, writes_mem=true, reads_mem=true},

	// ---- 8.22 Miscellaneous Encodings ----
	.BOUND  = {read={.OP0, .OP1}, reads_mem=true, side_effects={.TRAP}},  // #BR if out of bounds
	.ENTER  = {implicit_wr={.RSP, .RBP}, implicit_rd={.RSP, .RBP}, writes_mem=true},  // builds stack frame
	.LEAVE  = {implicit_wr={.RSP, .RBP}, implicit_rd={.RBP}, reads_mem=true},
	.XLAT   = {implicit_wr={.RAX}, implicit_rd={.RAX, .RBX}, reads_mem=true},  // AL <- [rBX + AL]
	.XLATB  = {implicit_wr={.RAX}, implicit_rd={.RAX, .RBX}, reads_mem=true},  // AL <- [rBX + AL]
	.MOVBE  = {written={.OP0}, read={.OP1}, writes_mem=true, reads_mem=true},  // byte-swapping load/store
	.RDRAND = {written={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},  // CF=1 if value valid; OF/SF/ZF/AF/PF cleared
	.RDSEED = {written={.OP0}, flags_wr={.CF, .PF, .AF, .ZF, .SF, .OF}},  // CF=1 if value valid; OF/SF/ZF/AF/PF cleared
}
