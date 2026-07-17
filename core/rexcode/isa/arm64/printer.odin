// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

import "core:strings"
import "core:reflect"
import "core:os"
import "core:io"
import "core:rexcode/isa"

// =============================================================================
// AArch64 PRINTER
// =============================================================================
//
// Canonical Arm assembly syntax:
//
//   add  x0, x1, x2                 (R-type)
//   add  x0, x1, #16                (imm)
//   add  x0, x1, x2, lsl #3         (shifted register)
//   add  x0, x1, w2, sxtw #2        (extended register)
//   ldr  x0, [x1, #8]               (offset)
//   ldr  x0, [x1, #-8]!             (pre-index)
//   ldr  x0, [x1], #8               (post-index)
//   ldr  x0, [x1, x2, lsl #3]       (register offset)
//   ldr  x0, [x1, w2, sxtw #2]      (extended-register offset)
//   b    .L0                        (relative)
//   b.eq .L0                        (B.cond with condition suffix)
//   cbz  x0, .L0
//   tbz  x0, #5, .L0
//   fadd d0, d1, d2                 (FP scalar)
//   fmov w0, s0                     (cross-class FMOV)
//
// FP mnemonics: the enum names already include the dot via the underscore-
// to-dot rule (FADD_S -> fadd.s). For the canonical assembly form we want
// no dot inside .S/.D (it's just `fadd s0, s0, s0`) -- the operand types
// disambiguate. So the printer special-cases the FP mnemonics.

Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

@(rodata, private="file")
COND_NAMES := [16]string{
	"eq", "ne", "cs", "cc", "mi", "pl", "vs", "vc",
	"hi", "ls", "ge", "lt", "gt", "le", "al", "nv",
}

@(rodata, private="file")
SHIFT_NAMES := [4]string{ "lsl", "lsr", "asr", "ror" }

@(rodata, private="file")
EXTEND_NAMES := [8]string{
	"uxtb", "uxth", "uxtw", "uxtx",
	"sxtb", "sxth", "sxtw", "sxtx",
}

mnemonic_to_string :: proc(m: Mnemonic, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_mnemonic(&sb, m, !lowercase)
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

		if label_id, has := offset_to_label[offset]; has {
			write_label(sb, label_id, label_names, opts)
			strings.write_byte(sb, ':')
			strings.write_string(sb, opts.separator)
		}

		strings.write_string(sb, opts.indent)
		if opts.show_offsets {
			isa.print_hex(sb, u64(offset), opts)
			strings.write_string(sb, ": ")
		}

		write_full_mnemonic(sb, inst, opts.uppercase)

		// B.cond's condition is encoded into the mnemonic suffix (b.eq),
		// so when printing we skip the first operand (it IS the cond).
		start_slot := 0
		if inst.mnemonic == .B_COND && inst.operand_count >= 1 && inst.ops[0].kind == .COND {
			start_slot = 1
		}

		if int(inst.operand_count) > start_slot {
			strings.write_byte(sb, ' ')
			for slot in start_slot..<int(inst.operand_count) {
				if slot > start_slot {
					strings.write_byte(sb, ',')
					if opts.space_after_comma { strings.write_byte(sb, ' ') }
				}
				write_operand(sb, &inst.ops[slot], offset_to_label, label_names, opts)
			}
		}
		strings.write_string(sb, opts.separator)
	}
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
// Sink wrappers
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
// Internal writers
// =============================================================================

// write_full_mnemonic handles a few special cases that need transformation:
//   * Suffix family mnemonics (ADD_IMM/ADD_SR/ADD_ER) collapse to `add`.
//   * B_COND prints as `b.<cond>` using the first operand's cond payload.
//   * Mov-wide / shifted/extended/imm variants all share the canonical
//     ARM ARM mnemonic; the suffix is for our internal disambiguation.

@(private="file")
write_full_mnemonic :: proc(sb: ^strings.Builder, inst: ^Instruction, uppercase: bool) {
	// B_COND -> `b.<cond>` based on the first operand.
	if inst.mnemonic == .B_COND && inst.operand_count >= 1 && inst.ops[0].kind == .COND {
		strings.write_string(sb, uppercase ? "B." : "b.")
		c := inst.ops[0].cond & 0xF
		cn := COND_NAMES[c]
		if uppercase {
			for i in 0..<len(cn) {
				ch := cn[i]
				if ch >= 'a' && ch <= 'z' { strings.write_byte(sb, ch - 32) } else { strings.write_byte(sb, ch) }
			}
		} else {
			strings.write_string(sb, cn)
		}
		return
	}

	write_mnemonic(sb, inst.mnemonic, uppercase)
}

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, uppercase: bool) {
	name, ok := reflect.enum_name_from_value(m)
	if !ok { strings.write_string(sb, "<?>"); return }

	// Strip internal disambiguator suffixes -- the user-facing mnemonic
	// is just the base name (ADD_IMM -> add, ADD_SR -> add, LDR_LIT -> ldr,
	// CCMP_REG -> ccmp, MSR_REG -> msr, FMOV_GEN -> fmov, ...).
	n := len(name)
	suffixes := []string{ "_IMM", "_SR", "_ER", "_LIT", "_REG", "_COND", "_GEN" }
	for s in suffixes {
		if n > len(s) {
			tail := name[n - len(s):]
			if tail == s {
				n -= len(s)
				break
			}
		}
	}

	for i in 0..<n {
		c := name[i]
		if c == '_' {
			strings.write_byte(sb, '.')
		} else if !uppercase && c >= 'A' && c <= 'Z' {
			strings.write_byte(sb, c + 32)
		} else {
			strings.write_byte(sb, c)
		}
	}
}

@(private="file")
write_register :: proc(sb: ^strings.Builder, r: Register, uppercase: bool) {
	if r == NONE { strings.write_string(sb, "<none>"); return }
	cls := reg_class(r)
	hw  := reg_hw(r)

	// SP and ZR have named forms; the rest are letter+number.
	switch cls {
	case REG_XSP:
		strings.write_string(sb, uppercase ? "SP" : "sp")
		return
	case REG_WSP:
		strings.write_string(sb, uppercase ? "WSP" : "wsp")
		return
	case REG_X:
		if hw == 31 {
			strings.write_string(sb, uppercase ? "XZR" : "xzr")
			return
		}
		strings.write_byte(sb, uppercase ? 'X' : 'x')
		write_decimal_u32(sb, u32(hw))
	case REG_W:
		if hw == 31 {
			strings.write_string(sb, uppercase ? "WZR" : "wzr")
			return
		}
		strings.write_byte(sb, uppercase ? 'W' : 'w')
		write_decimal_u32(sb, u32(hw))
	case REG_B:
		strings.write_byte(sb, uppercase ? 'B' : 'b')
		write_decimal_u32(sb, u32(hw))
	case REG_H:
		strings.write_byte(sb, uppercase ? 'H' : 'h')
		write_decimal_u32(sb, u32(hw))
	case REG_S:
		strings.write_byte(sb, uppercase ? 'S' : 's')
		write_decimal_u32(sb, u32(hw))
	case REG_D:
		strings.write_byte(sb, uppercase ? 'D' : 'd')
		write_decimal_u32(sb, u32(hw))
	case REG_Q:
		strings.write_byte(sb, uppercase ? 'Q' : 'q')
		write_decimal_u32(sb, u32(hw))
	case REG_V:
		strings.write_byte(sb, uppercase ? 'V' : 'v')
		write_decimal_u32(sb, u32(hw))
	case REG_Z:
		strings.write_byte(sb, uppercase ? 'Z' : 'z')
		write_decimal_u32(sb, u32(hw))
	case REG_P:
		strings.write_byte(sb, uppercase ? 'P' : 'p')
		write_decimal_u32(sb, u32(hw))
	}
}

@(private="file")
write_operand :: proc(
	sb:              ^strings.Builder,
	op:              ^Operand,
	offset_to_label: map[u32]u32,
	label_names:     ^map[u32]string,
	opts:            ^Print_Options,
) {
	switch op.kind {
	case .NONE:

	case .REGISTER:
		write_register(sb, op.reg, opts.uppercase)

	case .IMMEDIATE:
		strings.write_byte(sb, '#')
		write_signed_decimal(sb, op.immediate)

	case .COND:
		c := op.cond & 0xF
		s := COND_NAMES[c]
		if opts.uppercase {
			for i in 0..<len(s) {
				ch := s[i]
				if ch >= 'a' && ch <= 'z' { strings.write_byte(sb, ch - 32) } else { strings.write_byte(sb, ch) }
			}
		} else {
			strings.write_string(sb, s)
		}

	case .SHIFTED_REG:
		write_register(sb, op.shifted.reg, opts.uppercase)
		if op.shifted.amount != 0 || op.shifted.type != .LSL {
			if opts.space_after_comma {
				strings.write_string(sb, ", ")
			} else {
				strings.write_byte(sb, ',')
			}
			strings.write_string(sb, SHIFT_NAMES[u8(op.shifted.type) & 0x3])
			strings.write_string(sb, " #")
			write_decimal_u32(sb, u32(op.shifted.amount))
		}

	case .EXTENDED_REG:
		write_register(sb, op.extended.reg, opts.uppercase)
		if opts.space_after_comma {
			strings.write_string(sb, ", ")
		} else {
			strings.write_byte(sb, ',')
		}
		strings.write_string(sb, EXTEND_NAMES[u8(op.extended.extend) & 0x7])
		if op.extended.amount != 0 {
			strings.write_string(sb, " #")
			write_decimal_u32(sb, u32(op.extended.amount))
		}

	case .MEMORY:
		write_memory(sb, op.mem, opts)

	case .RELATIVE:
		target := u32(op.relative)
		if id, has := offset_to_label[target]; has {
			write_label(sb, id, label_names, opts)
		} else {
			isa.print_hex(sb, u64(target), opts)
		}
	}
}

@(private="file")
write_memory :: proc(sb: ^strings.Builder, m: Memory, opts: ^Print_Options) {
	strings.write_byte(sb, '[')
	write_register(sb, m.base, opts.uppercase)

	switch m.mode {
	case .OFFSET:
		if m.disp != 0 {
			if opts.space_after_comma {
				strings.write_string(sb, ", #")
			} else {
				strings.write_string(sb, ",#")
			}
			write_signed_decimal(sb, i64(m.disp))
		}
		strings.write_byte(sb, ']')

	case .PRE_INDEXED:
		if opts.space_after_comma {
			strings.write_string(sb, ", #")
		} else {
			strings.write_string(sb, ",#")
		}
		write_signed_decimal(sb, i64(m.disp))
		strings.write_string(sb, "]!")

	case .POST_INDEXED:
		strings.write_string(sb, "], #")
		write_signed_decimal(sb, i64(m.disp))

	case .REG_OFFSET:
		strings.write_string(sb, ", ")
		write_register(sb, m.index, opts.uppercase)
		if m.shift != 0 {
			strings.write_string(sb, ", lsl #")
			write_decimal_u32(sb, u32(m.shift))
		}
		strings.write_byte(sb, ']')

	case .EXT_REG_OFFSET:
		strings.write_string(sb, ", ")
		write_register(sb, m.index, opts.uppercase)
		strings.write_string(sb, ", ")
		strings.write_string(sb, EXTEND_NAMES[u8(m.extend) & 0x7])
		if m.shift != 0 {
			strings.write_string(sb, " #")
			write_decimal_u32(sb, u32(m.shift))
		}
		strings.write_byte(sb, ']')

	case .LITERAL:
		strings.write_byte(sb, ']')   // shouldn't normally appear
	}
}

@(private="file")
write_label :: proc(
	sb:          ^strings.Builder,
	label_id:    u32,
	label_names: ^map[u32]string,
	opts:        ^Print_Options,
) {
	if label_names != nil {
		if name, has := label_names^[label_id]; has {
			strings.write_string(sb, name)
			return
		}
	}
	strings.write_string(sb, opts.label_prefix)
	write_decimal_u32(sb, label_id)
}

@(private="file")
write_decimal_u32 :: proc(sb: ^strings.Builder, v: u32) {
	if v == 0 { strings.write_byte(sb, '0'); return }
	buf: [10]u8
	i := 0
	n := v
	for n > 0 { buf[i] = '0' + u8(n % 10); n /= 10; i += 1 }
	for j := i - 1; j >= 0; j -= 1 { strings.write_byte(sb, buf[j]) }
}

@(private="file")
write_signed_decimal :: proc(sb: ^strings.Builder, v: i64) {
	if v < 0 {
		strings.write_byte(sb, '-')
		n := u64(-(v + 1)) + 1
		write_decimal_u64(sb, n)
	} else {
		write_decimal_u64(sb, u64(v))
	}
}

@(private="file")
write_decimal_u64 :: proc(sb: ^strings.Builder, v: u64) {
	if v == 0 { strings.write_byte(sb, '0'); return }
	buf: [20]u8
	i := 0
	n := v
	for n > 0 { buf[i] = '0' + u8(n % 10); n /= 10; i += 1 }
	for j := i - 1; j >= 0; j -= 1 { strings.write_byte(sb, buf[j]) }
}
