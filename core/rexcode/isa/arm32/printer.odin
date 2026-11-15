// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

import "core:strings"
import "core:fmt"
import "core:io"
import "core:os"
import "core:reflect"
import "core:rexcode/isa"

// =============================================================================
// AArch32 PRINTER
// =============================================================================
//
// Canonical UAL syntax:
//
//   ADD{<c>}{S} <Rd>, <Rn>, #<imm>             A32 / T32 data-proc imm
//   ADD{<c>}{S} <Rd>, <Rn>, <Rm>{, <shift>}    A32 / T32 data-proc reg
//   LDR{<c>}    <Rt>, [<Rn>, #±<imm>]          load/store immediate
//   LDR{<c>}    <Rt>, [<Rn>, ±<Rm>{, <shift>}] load/store reg-offset
//   PUSH        {R0, R1, R4-R7, LR}            register list
//   B{<c>}      <label>                        branch
//   VADD.<dt>   <Vd>, <Vn>, <Vm>               VFP/NEON
//
// Mnemonic is uppercased by default (configurable); condition code suffix
// is appended (EQ/NE/...) after the mnemonic when cond != AL.

Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

@(rodata, private="file")
COND_SUFFIX := [16]string{
	"eq", "ne", "cs", "cc", "mi", "pl", "vs", "vc",
	"hi", "ls", "ge", "lt", "gt", "le", "",   "",   // 14=AL (no suffix), 15=NV/unconditional
}

@(rodata, private="file")
GPR_NAMES := [16]string{
	"r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7",
	"r8", "r9", "r10", "fp", "ip", "sp", "lr", "pc",
}

@(rodata, private="file")
SHIFT_NAMES := [5]string{"lsl", "lsr", "asr", "ror", "rrx"}

mnemonic_to_string :: proc(m: Mnemonic, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_mnemonic(&sb, m, 14, false, !lowercase)
	return strings.to_string(sb)
}

register_name :: proc(r: Register, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_register(&sb, r, !lowercase)
	return strings.to_string(sb)
}

// =============================================================================
// Core sbprint
// =============================================================================

sbprint :: proc(
	sb:           ^strings.Builder,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^isa.Label_Names = nil,
) {
	opts := options
	if opts == nil {
		@(static) defaults := DEFAULT_PRINT_OPTIONS
		opts = &defaults
	}

	// Display-side label naming: numbers in ADDRESS order (independent of the internal ids'
	// allocation order), caller names keyed by byte offset (isa.Label_Display).
	display: isa.Label_Display
	isa.label_display_init(&display, label_defs, label_names)
	defer isa.label_display_destroy(&display)

	for i in 0..<len(instructions) {
		inst := &instructions[i]
		offset := u32(i) * 4
		if i < len(inst_info) {
			offset = inst_info[i].offset
		}

		// A displayable label at this offset — a definition, or a caller-named offset
		if isa.label_display_at(&display, offset) {
			isa.label_display_write(&display, sb, offset, opts.label_prefix)
			strings.write_string(sb, ":\n")
		}

		if opts.show_offsets {
			fmt.sbprintf(sb, "%08x:  ", offset)
		}

		if inst.mnemonic == .INVALID {
			strings.write_string(sb, "    .word 0xINVALID\n")
			continue
		}

		strings.write_string(sb, "    ")

		// The `.<dt>` suffix. It is data on the instruction now, so there is
		// nothing to reconstruct: read it straight off. This is also what
		// makes the convert family print correctly -- `vcvt.s32.f32` names
		// both ends, and the old bit-pattern inference only ever produced one.
		dt_suffix := ""
		dt := inst.dt
		if dt[0] == .NONE && i < len(inst_info) {
			de_idx := int(inst_info[i].decode_entry)
			if de_idx < len(DECODE_ENTRIES) {
				dt = DECODE_ENTRIES[de_idx].dt
			}
		}
		// No fallback beyond this. Guessing a data type from the register
		// bank produced one for every VFP instruction that does not take
		// any -- `vldr.f32`, `vorn.f64` -- and those are not accepted
		// syntax. If a form needs a suffix, the table is where it says so.


		write_mnemonic(sb, inst.mnemonic, inst.cond, inst.sets_flags, opts.uppercase)
		if dt[0] != .NONE {
			write_data_type(sb, dt, opts.uppercase)
		} else if dt_suffix != "" {
			strings.write_string(sb, dt_suffix)
		}

		if inst.operand_count > 0 {
			strings.write_string(sb, " ")
			for k in 0..<inst.operand_count {
				if k > 0 { strings.write_string(sb, ", ") }
				write_operand(sb, &inst.ops[k], inst, offset, &display, opts)
				// LDM/STM write the updated base back, and the syntax marks
				// that with a `!` on the base register itself.
				if k == 0 && inst.writeback { strings.write_byte(sb, '!') }
			}
		}
		strings.write_string(sb, "\n")
	}
}

// =============================================================================
// Data-type suffix inference
// =============================================================================
//
// UAL syntax for VFP/NEON ops: VADD.F32 / VADD.I16 / VADD.F64 etc.
// The suffix is determined by the matched encoding form's:
//   * Feature flag (HALF_FP -> .F16, NEON_HALF_FP -> .F16, VFPV2 -> .F32/.F64)
//   * Opcode bits (11:8 within the NEON 3-reg-same family)
//   * Size bits (21:20 select element width for integer NEON)
//   * U bit (24) for signed/unsigned (e.g. .S16 vs .U16)
//   * Register class of operand 0 (SPR -> single, DPR -> double or NEON D, QPR -> NEON Q)

@(private="file")
infer_dt_suffix :: proc(form: ^Decode_Entry, inst: ^Instruction) -> string {
	op0 := form.ops[0]
	feat := form.feature

	// VFP scalar single/double/half by register class + feature
	if op0 == .SPR && (feat == .VFPV2 || feat == .VFPV3 || feat == .VFPV4 ||
					   feat == .V8 || feat == .DIV) {
		return ".f32"
	}
	if op0 == .DPR && (feat == .VFPV2 || feat == .VFPV3 || feat == .VFPV4 ||
					   feat == .V8) && !is_neon_class_op(form) {
		return ".f64"
	}
	if (op0 == .SPR || op0 == .DPR) && feat == .HALF_FP {
		return ".f16"
	}
	if feat == .NEON_HALF_FP {
		return ".f16"
	}

	// MVE FP forms
	if feat == .MVE_FP {
		// MVE bit 20 distinguishes F16 (1) from F32 (0)
		if (form.bits >> 20) & 1 != 0 { return ".f16" }
		return ".f32"
	}
	if feat == .MVE_INT {
		sz := (form.bits >> 20) & 0x3
		switch sz {
		case 0: return ".i8"
		case 1: return ".i16"
		case 2: return ".i32"
		case 3: return ".i64"
		}
	}

	// NEON integer / FP by opcode bits 11:8 + size bits 21:20
	if feat == .NEON && (op0 == .DPR || op0 == .QPR) {
		return neon_3reg_suffix(form)
	}

	// BF16 / DOT / FCMA / FHM
	if feat == .BF16 { return ".bf16" }
	if feat == .DOT  { return ".s8" }    // VSDOT / VUDOT default suffix
	if feat == .FHM  { return ".f16" }
	if feat == .FCMA { return ".f32" }

	return ""
}

@(private="file")
is_neon_class_op :: proc(form: ^Decode_Entry) -> bool {
	// NEON A32 unconditional class top byte is F2/F3; T32 is E2/E3 (after bit-28 swap).
	top := (form.bits >> 24) & 0xFF
	if top == 0xF2 || top == 0xF3 { return true }
	if top == 0xE2 || top == 0xE3 { return true }
	return false
}

@(private="file")
neon_3reg_suffix :: proc(form: ^Decode_Entry) -> string {
	// For 3-reg-same family: bits 11:8 = opcode, bit 4 = subtype, bit 24 = U
	op_bits := (form.bits >> 8) & 0xF
	sz := (form.bits >> 20) & 0x3
	u  := (form.bits >> 24) & 1

	switch op_bits {
	case 0xD:    // FP add/sub/mul/abd
		return ".f32"
	case 0xF:    // FP max/min/recps/rsqrts/etc.
		return ".f32"
	case 0x1:    // VAND/VBIC/VORR/VORN/VEOR/VBSL/VBIT/VBIF (no size suffix)
		return ""
	}

	// Integer ops -- size from bits 21:20, signed/unsigned from U
	prefix := u == 1 ? ".u" : ".s"
	// Some ops are size-agnostic (.I8/.I16/etc. when signedness doesn't matter)
	#partial switch form.mnemonic {
	case .VADD, .VSUB, .VMUL, .VMLA, .VMLS, .VEXT, .VCEQ, .VTST:
		prefix = ".i"
	}
	switch sz {
	case 0: return strings.concatenate({prefix, "8"},  context.temp_allocator)
	case 1: return strings.concatenate({prefix, "16"}, context.temp_allocator)
	case 2: return strings.concatenate({prefix, "32"}, context.temp_allocator)
	case 3: return strings.concatenate({prefix, "64"}, context.temp_allocator)
	}
	return ""
}

sbprintln :: proc(
	sb:           ^strings.Builder,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^isa.Label_Names = nil,
) {
	sbprint(sb, instructions, inst_info, label_defs, tokens, options, label_names)
	strings.write_byte(sb, '\n')
}

// =============================================================================
// Sink wrappers (cross-arch naming contract -- see docs/cross_arch_design.md §6)
// =============================================================================

print :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(os.stdout, strings.to_string(sb))
}

println :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(os.stdout, strings.to_string(sb))
}

aprint :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

aprintln :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

tprint :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

tprintln :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

bprint :: proc(
	buf: []u8,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) -> string {
	sb := strings.builder_from_bytes(buf)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

bprintln :: proc(
	buf: []u8,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) -> string {
	sb := strings.builder_from_bytes(buf)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

fprint :: proc(
	fd: ^os.File,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(fd, strings.to_string(sb))
}

fprintln :: proc(
	fd: ^os.File,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(fd, strings.to_string(sb))
}

wprint :: proc(
	w: io.Writer,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	io.write_string(w, strings.to_string(sb))
}

wprintln :: proc(
	w: io.Writer,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	io.write_string(w, strings.to_string(sb))
}

// =============================================================================
// Writers
// =============================================================================

// `.i32`, `.s32.f32`, `.8`. Both slots print when the second is set.
// A shift suffix on a register operand. Three spellings, and the enum covers
// all of them: `, lsl #3` for an immediate amount, `, lsl r3` when the count
// comes from a register (Shift_Type.LSL_REG..ROR_REG keep the Rs index in
// shift_amt), and a bare `, rrx`, which takes no amount at all.
//
// SHIFT_NAMES only holds LSL..RRX, so the register-shifted variants have to be
// folded back onto it. Indexing it with the raw enum value ran off the end --
// LSL_REG is 6 against a 5-entry table -- and crashed the printer outright.
@(private="file")
write_shift :: proc(sb: ^strings.Builder, st: Shift_Type, amt: u8) {
	switch st {
	case .LSL, .LSR, .ASR, .ROR:
		if amt == 0 {
			return
		}
		fmt.sbprintf(sb, ", %s #%d", SHIFT_NAMES[int(st)], amt)
	case .RRX:
		strings.write_string(sb, ", rrx")
	case .NONE:
		// no shift to print
	case .LSL_REG, .LSR_REG, .ASR_REG, .ROR_REG:
		fmt.sbprintf(sb, ", %s %s", SHIFT_NAMES[int(st) - int(Shift_Type.LSL_REG)], GPR_NAMES[amt & 0xF])
	}
}

@(private="file")
write_data_type :: proc(sb: ^strings.Builder, dt: Data_Types, uppercase: bool) {
	for d in dt {
		if d == .NONE { continue }
		strings.write_byte(sb, '.')
		name := DATA_TYPE_NAMES[d]
		for i in 0 ..< len(name) {
			c := name[i]
			if uppercase && c >= 'a' && c <= 'z' {
				strings.write_byte(sb, c - 'a' + 'A')
			} else {
				strings.write_byte(sb, c)
			}
		}
	}
}

@(rodata, private="file")
DATA_TYPE_NAMES := [Data_Type]string{
	.NONE = "",
	.S8 = "s8", .S16 = "s16", .S32 = "s32", .S64 = "s64",
	.U8 = "u8", .U16 = "u16", .U32 = "u32", .U64 = "u64",
	.I8 = "i8", .I16 = "i16", .I32 = "i32", .I64 = "i64",
	.F16 = "f16", .F32 = "f32", .F64 = "f64",
	.P8 = "p8", .P16 = "p16", .BF16 = "bf16",
	.SZ8 = "8", .SZ16 = "16", .SZ32 = "32", .SZ64 = "64",
}

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, cond: u8, sets_flags: bool, uppercase: bool) {
	name, _ := reflect.enum_name_from_value(m)
	// PSB_CSYNC / TSB_CSYNC are the only names left holding an underscore:
	// assemblers write them as a mnemonic plus an operand token, `psb csync`,
	// so that underscore is a space. No other mnemonic has one.
	split := -1
	if len(name) > 4 && (name[:4] == "PSB_" || name[:4] == "TSB_") {
		split = 3
	}
	for i in 0..<len(name) {
		c := name[i]
		if i == split {
			strings.write_byte(sb, ' ')
		} else if !uppercase && c >= 'A' && c <= 'Z' {
			strings.write_byte(sb, c - 'A' + 'a')
		} else {
			strings.write_byte(sb, c)
		}
	}
	if sets_flags {
		strings.write_string(sb, uppercase ? "S" : "s")
	}
	if cond != 14 && cond != 15 {
		strings.write_string(sb, uppercase ? COND_SUFFIX[cond] : COND_SUFFIX[cond])
		// (Both forms identical for cond; we keep the table lowercase and
		// post-process if uppercase requested.)
	}
}

@(private="file")
write_register :: proc(sb: ^strings.Builder, r: Register, uppercase: bool = false) {
	cls := reg_class(r)
	hw  := reg_hw(r)
	switch cls {
	case REG_GPR:
		strings.write_string(sb, GPR_NAMES[hw & 0xF])
	case REG_SPR:
		fmt.sbprintf(sb, "s%d", hw)
	case REG_DPR:
		fmt.sbprintf(sb, "d%d", hw)
	case REG_QPR:
		fmt.sbprintf(sb, "q%d", hw)
	case REG_SREG:
		switch hw {
		case 0: strings.write_string(sb, "apsr")
		case 1: strings.write_string(sb, "cpsr")
		case 2: strings.write_string(sb, "spsr")
		case:   fmt.sbprintf(sb, "psr%d", hw)
		}
	case REG_FPSC:
		switch hw {
		case 0: strings.write_string(sb, "fpsid")
		case 1: strings.write_string(sb, "fpscr")
		case 8: strings.write_string(sb, "fpexc")
		case:   fmt.sbprintf(sb, "fpsc%d", hw)
		}
	case REG_COPROC:
		fmt.sbprintf(sb, "c%d", hw)
	case REG_COPROC_NUM:
		fmt.sbprintf(sb, "p%d", hw)
	case REG_ENDIAN:
		strings.write_string(sb, hw == 0 ? "le" : "be")
	case:
		fmt.sbprintf(sb, "?%d", hw)
	}
}

@(private="file")
write_operand :: proc(
	sb:               ^strings.Builder,
	op:               ^Operand,
	inst:             ^Instruction,
	offset:           u32,
	display:          ^isa.Label_Display,
	opts:             ^Print_Options,
) {
	switch op.kind {
	case .NONE:
		return
	case .REGISTER:
		// A VFP/NEON list is a contiguous run written in braces, and every
		// register is named -- `{d1, d2, d3}`, not a range.
		if op.list.count > 0 {
			strings.write_string(sb, "{")
			step := u16(max(op.list.stride, 1))
			for n in 0 ..< u16(op.list.count) {
				if n > 0 { strings.write_string(sb, ", ") }
				write_register(sb, Register(reg_class(op.reg) | ((reg_hw(op.reg) + n * step) & 0x1F)))
				// Every member of a single-lane list carries the index:
				// `{d0[1], d1[1]}`. `{d0[]}` is the to-all-lanes form.
				if op.list.all_lanes {
					strings.write_string(sb, "[]")
				} else if op.has_lane {
					fmt.sbprintf(sb, "[%d]", op.lane)
				}
			}
			strings.write_string(sb, "}")
			return
		}
		write_register(sb, op.reg)
		write_shift(sb, op.shift_type, op.shift_amt)
		if op.has_lane {
			fmt.sbprintf(sb, "[%d]", op.lane)
		}
	case .IMMEDIATE:
		fmt.sbprintf(sb, "#%d", op.immediate)
	case .HEX_IMMEDIATE:
		fmt.sbprintf(sb, "#0x%x", op.immediate)
	case .FLOAT_IMMEDIATE:
		fmt.sbprintf(sb, "#%e", f64(transmute(f32)u32(op.immediate)))
	case .MEMORY:
		write_memory(sb, op.mem)
	case .RELATIVE:
		// Resolve to label if possible
		target := u32(i64(offset) + op.relative)
		if isa.label_display_at(display, target) {
			isa.label_display_write(display, sb, target, opts.label_prefix)
		} else {
			// raw absolute
			fmt.sbprintf(sb, "0x%x", target)
		}
	case .REG_LIST:
		write_reg_list(sb, u16(op.immediate))
	}
}

@(private="file")
write_memory :: proc(sb: ^strings.Builder, m: Memory) {
	strings.write_string(sb, "[")
	write_register(sb, m.base)
	// An immediate-only form leaves index at Register(0), whose class is not
	// REG_GPR -- so the class alone says whether there is an index. Excluding
	// hw 0 as well made r0 unusable as one.
	if reg_class(m.index) == REG_GPR {
		// Register offset
		switch m.mode {
		case .OFFSET:
			strings.write_string(sb, ", ")
			if m.sign < 0 { strings.write_string(sb, "-") }
			write_register(sb, m.index)
			write_shift(sb, m.shift_type, m.shift_amt)
			strings.write_string(sb, "]")
		case .PRE_INDEX:
			strings.write_string(sb, ", ")
			if m.sign < 0 { strings.write_string(sb, "-") }
			write_register(sb, m.index)
			strings.write_string(sb, "]!")
		case .POST_INDEX:
			strings.write_string(sb, "], ")
			if m.sign < 0 { strings.write_string(sb, "-") }
			write_register(sb, m.index)
		}
	} else {
		// An indexed form writes its displacement even when it is zero: the
		// writeback is the point, and `[r0]` alone is the plain offset form.
		// The U bit also survives a zero displacement, and an assembler needs
		// to see it -- `#-0` and `#0` are different words.
		neg := m.disp == 0 && m.sign < 0 ? "-" : ""
		switch m.mode {
		case .OFFSET:
			if m.disp != 0 || m.sign < 0 {
				fmt.sbprintf(sb, ", #%s%d]", neg, m.disp)
			} else {
				strings.write_string(sb, "]")
			}
		case .PRE_INDEX:  fmt.sbprintf(sb, ", #%s%d]!", neg, m.disp)
		case .POST_INDEX: fmt.sbprintf(sb, "], #%s%d", neg, m.disp)
		}
	}
}

@(private="file")
write_reg_list :: proc(sb: ^strings.Builder, mask: u16) {
	strings.write_string(sb, "{")
	first := true
	range_start: int = -1
	for b in 0..<16 {
		bit := mask & (1 << u32(b)) != 0
		next_bit := b < 15 && mask & (1 << u32(b + 1)) != 0
		if bit && range_start < 0 { range_start = b }
		if bit && !next_bit {
			if !first { strings.write_string(sb, ", ") }
			first = false
			if range_start == b {
				strings.write_string(sb, GPR_NAMES[b])
			} else {
				fmt.sbprintf(sb, "%s-%s", GPR_NAMES[range_start], GPR_NAMES[b])
			}
			range_start = -1
		}
	}
	strings.write_string(sb, "}")
}
