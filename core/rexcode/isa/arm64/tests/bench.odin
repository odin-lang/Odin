// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64_tests

// Encode / decode / print throughput benchmarks, at three working-set sizes so
// the cache story is visible (Instruction is 64 bytes, so the instruction
// array is inst_count * 64B; the code buffer is inst_count * 4B on top).
//
// Run with: odin run arm64/tests -o:speed -- bench
//
// The instruction mix deliberately covers the operand kinds with distinct
// encoder paths: plain registers, immediates, shifted/extended registers,
// every common addressing mode, condition codes, FP/NEON registers, and the
// MRS/MSR system-register path.

import "core:fmt"
import "core:strings"
import "core:time"
import a "../"

@(private="file")
Working_Set :: struct {
	name:       string,
	inst_count: int,
}

@(private="file")
WORKING_SETS :: [3]Working_Set{
	{"32KB (L1)",  512},
	{"512KB (L2)", 8192},
	{"16MB (RAM)", 262144},
}

// Total instructions pushed through encode/decode per measurement, so every
// working set does the same amount of work and only residency differs.
@(private="file") ENCODE_DECODE_WORK :: 33_554_432
// The printer is roughly an order of magnitude slower, so it gets less.
@(private="file") PRINT_WORK :: 4_194_304

// One block of the mix; repeated to fill each working set. Kept free of
// RELATIVE operands so no label plumbing is needed and every iteration is
// self-contained. The literal is local to this frame, so the block is only
// valid while `fill_instructions` runs -- it is copied out, never returned.
@(private="file")
fill_instructions :: proc(instructions: ^[dynamic]a.Instruction, inst_count: int) {
	block := []a.Instruction{
		// Data-processing: immediates, plain / shifted / extended registers.
		a.inst_r_r_i(.ADD,  a.X0,  a.X1, 100),
		a.inst_r_r_i(.SUB,  a.W2,  a.W3, 257),
		a.inst_mov_imm(.MOVZ, a.X4, 0x1234, 1),
		a.inst_mov_imm(.MOVK, a.X4, 0x5678, 0),
		{mnemonic = .ADD,  operand_count = 3, length = 4,
		 ops = {a.op_reg(a.X5), a.op_reg(a.X6), a.op_shifted(a.X7, .LSL, 3), {}, {}}},
		{mnemonic = .SUB,  operand_count = 3, length = 4,
		 ops = {a.op_reg(a.X8), a.op_reg(a.X9), a.op_extended(a.W10, .SXTW, 2), {}, {}}},
		a.inst_r_r_r(.LSL,  a.X11, a.X12, a.X13),
		a.inst_r_r_r(.UDIV, a.X14, a.X15, a.X16),
		a.inst_r_r_r_r(.MADD, a.X17, a.X18, a.X19, a.X20),
		a.inst_r_r(.CLZ, a.X21, a.X22),
		{mnemonic = .CSEL, operand_count = 4, length = 4,
		 ops = {a.op_reg(a.X0), a.op_reg(a.X1), a.op_reg(a.X2), a.op_cond(.GT), {}}},

		// Loads / stores: unsigned offset, pre/post-indexed, register offset,
		// and a pair.
		a.inst_ldst(.LDR,  a.X0, a.mem_offset(a.X1, 64)),
		a.inst_ldst(.STR,  a.X2, a.mem_offset(a.SP, 16)),
		a.inst_ldst(.LDR,  a.X3, a.mem_pre(a.X4, -32)),
		a.inst_ldst(.STR,  a.X5, a.mem_post(a.X6, 48)),
		a.inst_ldst(.LDR,  a.X7, a.mem_reg(a.X8, a.X9, 3)),
		a.inst_ldst(.LDRB, a.W10, a.mem_reg(a.X11, a.X12)),
		a.inst_ldp_stp(.LDP, a.X13, a.X14, a.mem_offset(a.X15, 96)),
		a.inst_ldp_stp(.STP, a.X16, a.X17, a.mem_pre(a.SP, -64)),

		// FP scalar and NEON vector.
		a.inst_r_r_r(.FADD, a.d_reg(0), a.d_reg(1), a.d_reg(2)),
		a.inst_r_r_r(.FMUL, a.s_reg(3), a.s_reg(4), a.s_reg(5)),
		a.inst_r_r(.FABS, a.d_reg(6), a.d_reg(7)),
		{mnemonic = .ADD, operand_count = 3, length = 4,
		 ops = {a.op_v_16b(a.V0), a.op_v_16b(a.V1), a.op_v_16b(a.V2), {}, {}}},
		{mnemonic = .FADD, operand_count = 3, length = 4,
		 ops = {a.op_v_4s(a.V3), a.op_v_4s(a.V4), a.op_v_4s(a.V5), {}, {}}},

		// System registers -- the path the sysreg/register merge changes.
		a.inst_mrs_r_s(a.X23, a.NZCV),
		a.inst_msr_s_r(a.FPCR, a.X24),
		a.inst_mrs_r_s(a.X25, a.ELR_EL1),

		a.inst_none(.NOP),
	}

	clear(instructions)
	for len(instructions) < inst_count {
		remaining := inst_count - len(instructions)
		if remaining >= len(block) {
			append(instructions, ..block)
		} else {
			append(instructions, ..block[:remaining])
		}
	}
}

run_benchmarks :: proc() {
	fmt.println("=== AArch64 encode/decode/print benchmarks ===")
	fmt.printfln("  size_of(Register)    = %d", size_of(a.Register))
	fmt.printfln("  size_of(Operand)     = %d", size_of(a.Operand))
	fmt.printfln("  size_of(Memory)      = %d", size_of(a.Memory))
	fmt.printfln("  size_of(Instruction) = %d", size_of(a.Instruction))
	fmt.println()

	instructions: [dynamic]a.Instruction
	defer delete(instructions)

	relocs: [dynamic]a.Relocation
	errors: [dynamic]a.Error
	defer delete(relocs)
	defer delete(errors)

	decoded:    [dynamic]a.Instruction
	inst_info:  [dynamic]a.Instruction_Info
	label_defs: [dynamic]a.Label_Definition
	defer delete(decoded)
	defer delete(inst_info)
	defer delete(label_defs)

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	working_sets := WORKING_SETS
	for ws in working_sets {
		fill_instructions(&instructions, ws.inst_count)

		code_buffer := make([]u8, ws.inst_count * 4)
		defer delete(code_buffer)

		// Correctness gate: the whole mix must encode cleanly, and decode must
		// give back one instruction per word, or the numbers mean nothing.
		{
			clear(&relocs)
			clear(&errors)
			byte_count, success := a.encode(instructions[:], nil, code_buffer, &relocs, &errors)
			if !success || int(byte_count) != ws.inst_count * 4 {
				fmt.printfln("  [FAIL] %s: bench mix does not encode (bytes=%d, errors=%d)",
							 ws.name, byte_count, len(errors))
				for e in errors {
					fmt.printfln("         inst %d: %v", e.inst_idx, e.code)
				}
				return
			}
			clear(&decoded)
			clear(&inst_info)
			clear(&label_defs)
			clear(&errors)
			_, dec_success := a.decode(code_buffer, nil, &decoded, &inst_info, &label_defs, &errors)
			if !dec_success || len(decoded) != ws.inst_count {
				fmt.printfln("  [FAIL] %s: bench mix does not decode (insts=%d, errors=%d)",
							 ws.name, len(decoded), len(errors))
				return
			}
		}

		iterations := ENCODE_DECODE_WORK / ws.inst_count

		// ---- Encode --------------------------------------------------------
		encode_start := time.now()
		for _ in 0..<iterations {
			clear(&relocs)
			clear(&errors)
			a.encode(instructions[:], nil, code_buffer, &relocs, &errors)
		}
		encode_seconds := time.duration_seconds(time.since(encode_start))

		// ---- Decode --------------------------------------------------------
		decode_start := time.now()
		for _ in 0..<iterations {
			clear(&decoded)
			clear(&inst_info)
			clear(&label_defs)
			clear(&errors)
			a.decode(code_buffer, nil, &decoded, &inst_info, &label_defs, &errors)
		}
		decode_seconds := time.duration_seconds(time.since(decode_start))

		// ---- Print ---------------------------------------------------------
		print_iterations := max(PRINT_WORK / ws.inst_count, 1)
		print_start := time.now()
		for _ in 0..<print_iterations {
			strings.builder_reset(&builder)
			a.sbprint(&builder, decoded[:], inst_info[:], label_defs[:])
		}
		print_seconds := time.duration_seconds(time.since(print_start))

		total_insts := f64(iterations * ws.inst_count)
		encode_rate := total_insts / encode_seconds
		decode_rate := total_insts / decode_seconds
		print_rate  := f64(print_iterations * ws.inst_count) / print_seconds

		fmt.printfln("  %-12s (%d insts x %d iters)", ws.name, ws.inst_count, iterations)
		fmt.printfln("    encode: %.1f M insts/s  (%.1f MB/s of code)",
					 encode_rate / 1e6, encode_rate * 4 / 1e6)
		fmt.printfln("    decode: %.1f M insts/s  (%.1f MB/s of code)",
					 decode_rate / 1e6, decode_rate * 4 / 1e6)
		fmt.printfln("    print:  %.1f M insts/s", print_rate / 1e6)
	}
}
