package rexcode_arm32

import "core:strings"
import "core:fmt"
import "core:io"
import "core:os"
import "core:reflect"
import "../isa"

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
	label_names:  ^map[u32]string = nil,
) {
	opts := options
	if opts == nil {
		@(static) defaults := DEFAULT_PRINT_OPTIONS
		opts = &defaults
	}

	offset_to_label: map[u32]u32
	defer delete(offset_to_label)
	for ld, id in label_defs {
		if ld != LABEL_UNDEFINED {
			offset_to_label[u32(ld)] = u32(id)
		}
	}

	for i in 0..<len(instructions) {
		inst := &instructions[i]
		offset := u32(i) * 4
		if i < len(inst_info) {
			offset = inst_info[i].offset
		}

		// Label preceding this instruction (if any)
		if id, ok := offset_to_label[offset]; ok {
			if label_names != nil {
				if name, has := label_names[id]; has {
					strings.write_string(sb, name)
					strings.write_string(sb, ":\n")
				}
			} else {
				fmt.sbprintf(sb, "L%d:\n", id)
			}
		}

		if opts.show_offsets {
			fmt.sbprintf(sb, "%08x:  ", offset)
		}

		if inst.mnemonic == .INVALID {
			strings.write_string(sb, "    .word 0xINVALID\n")
			continue
		}

		strings.write_string(sb, "    ")

		// Compute the .<dt> suffix from the matched decoder entry (if any)
		// and from the operand kinds when no entry is available.
		dt_suffix := ""
		if i < len(inst_info) {
			de_idx := int(inst_info[i].decode_entry)
			if de_idx < len(DECODE_ENTRIES) {
				dt_suffix = infer_dt_suffix(&DECODE_ENTRIES[de_idx], inst)
			}
		}
		if dt_suffix == "" {
			dt_suffix = infer_dt_suffix_from_inst(inst)
		}

		write_mnemonic(sb, inst.mnemonic, inst.cond, inst.flags.sets_flags, opts.uppercase)
		if dt_suffix != "" {
			strings.write_string(sb, dt_suffix)
		}

		if inst.operand_count > 0 {
			strings.write_string(sb, " ")
			for k in 0..<inst.operand_count {
				if k > 0 { strings.write_string(sb, ", ") }
				write_operand(sb, &inst.ops[k], inst, offset, &offset_to_label, label_names, opts)
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
infer_dt_suffix_from_inst :: proc(inst: ^Instruction) -> string {
	if inst.operand_count == 0 { return "" }
	op0 := &inst.ops[0]
	if op0.kind != .REGISTER { return "" }
	switch reg_class(op0.reg) {
	case REG_SPR: return ".f32"
	case REG_DPR: return ".f64"
	case REG_QPR: return ""        // can't tell integer vs FP from operand alone
	}
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
	label_names:  ^map[u32]string = nil,
) {
	sbprint(sb, instructions, inst_info, label_defs, tokens, options, label_names)
	strings.write_byte(sb, '\n')
}

// =============================================================================
// Sink wrappers (cross-arch naming contract -- see docs/cross_arch_design.md §6)
// =============================================================================

print :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(os.stdout, strings.to_string(sb))
}

println :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(os.stdout, strings.to_string(sb))
}

aprint :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

aprintln :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

tprint :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

tprintln :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

bprint :: proc(
	buf: []u8,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) -> string {
	sb := strings.builder_from_bytes(buf)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

bprintln :: proc(
	buf: []u8,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) -> string {
	sb := strings.builder_from_bytes(buf)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

fprint :: proc(
	fd: ^os.File,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(fd, strings.to_string(sb))
}

fprintln :: proc(
	fd: ^os.File,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(fd, strings.to_string(sb))
}

wprint :: proc(
	w: io.Writer,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	io.write_string(w, strings.to_string(sb))
}

wprintln :: proc(
	w: io.Writer,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	io.write_string(w, strings.to_string(sb))
}

// =============================================================================
// Writers
// =============================================================================

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, cond: u8, sets_flags: bool, uppercase: bool) {
	name, _ := reflect.enum_name_from_value(m)
	if uppercase {
		strings.write_string(sb, name)
	} else {
		for r in name {
			if r >= 'A' && r <= 'Z' { strings.write_byte(sb, u8(r - 'A' + 'a')) }
			else                    { strings.write_rune(sb, r) }
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
	offset_to_label:  ^map[u32]u32,
	label_names:      ^map[u32]string,
	opts:             ^Print_Options,
) {
	switch op.kind {
	case .NONE:
		return
	case .REGISTER:
		write_register(sb, op.reg)
		if op.shift_type != .NONE && op.shift_type != .RRX && op.shift_amt > 0 {
			fmt.sbprintf(sb, ", %s #%d", SHIFT_NAMES[int(op.shift_type)], op.shift_amt)
		}
		if op.lane != 0 {
			fmt.sbprintf(sb, "[%d]", op.lane)
		}
	case .IMMEDIATE:
		fmt.sbprintf(sb, "#%d", op.immediate)
	case .MEMORY:
		write_memory(sb, op.mem)
	case .RELATIVE:
		// Resolve to label if possible
		target := u32(i64(offset) + op.relative)
		if id, ok := offset_to_label[target]; ok {
			if label_names != nil {
				if name, has := label_names[id]; has {
					strings.write_string(sb, name)
					return
				}
			}
			fmt.sbprintf(sb, "L%d", id)
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
	if reg_class(m.index) == REG_GPR && reg_hw(m.index) != 0 {
		// Register offset
		switch m.mode {
		case .OFFSET:
			strings.write_string(sb, ", ")
			if m.sign < 0 { strings.write_string(sb, "-") }
			write_register(sb, m.index)
			if m.shift_type != .NONE && m.shift_amt > 0 {
				fmt.sbprintf(sb, ", %s #%d", SHIFT_NAMES[int(m.shift_type)], m.shift_amt)
			}
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
	} else if m.disp != 0 {
		// Immediate offset
		switch m.mode {
		case .OFFSET:    fmt.sbprintf(sb, ", #%d]", m.disp)
		case .PRE_INDEX: fmt.sbprintf(sb, ", #%d]!", m.disp)
		case .POST_INDEX: fmt.sbprintf(sb, "], #%d", m.disp)
		}
	} else {
		strings.write_string(sb, "]")
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
