package rexcode_riscv

import "core:strings"
import "core:reflect"
import "core:os"
import "core:io"
import "../isa"

// =============================================================================
// RISC-V PRINTER
// =============================================================================
//
// Canonical RISC-V assembly syntax:
//
//   add  rd, rs1, rs2          (R-type)
//   addi rd, rs1, imm          (I-type ALU, signed decimal)
//   lw   rd, disp(rs1)         (loads)
//   sw   rs2, disp(rs1)        (stores)
//   beq  rs1, rs2, label       (branches)
//   jal  rd, label             (J-type)
//   lui  rd, 0x12345           (U-type, hex)
//   csrrw rd, csr, rs1         (Zicsr)
//   fadd.s rd, rs1, rs2        (FP -- dot in mnemonic)
//   fmadd.s rd, rs1, rs2, rs3  (R4-type FMA)
//
// Register names use the ABI convention (zero/ra/sp/gp/tp/t0-t6/s0-s11/
// a0-a7 for GPRs; ft0-ft11/fa0-fa7/fs0-fs11 for FPRs). FP mnemonics
// translate underscore-to-dot for the suffix (FADD_S -> fadd.s).

Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

@(rodata, private="file")
GPR_ABI := [32]string{
	"zero", "ra", "sp", "gp", "tp",
	"t0", "t1", "t2",
	"s0", "s1",
	"a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7",
	"s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11",
	"t3", "t4", "t5", "t6",
}

@(rodata, private="file")
FPR_ABI := [32]string{
	"ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6", "ft7",
	"fs0", "fs1",
	"fa0", "fa1", "fa2", "fa3", "fa4", "fa5", "fa6", "fa7",
	"fs2", "fs3", "fs4", "fs5", "fs6", "fs7", "fs8", "fs9", "fs10", "fs11",
	"ft8", "ft9", "ft10", "ft11",
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

		write_mnemonic(sb, inst.mnemonic, opts.uppercase)

		if inst.operand_count > 0 {
			strings.write_byte(sb, ' ')
			for slot in 0..<int(inst.operand_count) {
				if slot > 0 {
					strings.write_byte(sb, ',')
					if opts.space_after_comma { strings.write_byte(sb, ' ') }
				}
				write_operand(sb, &inst.ops[slot], inst.mnemonic, offset_to_label, label_names, opts)
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

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, uppercase: bool) {
	name, ok := reflect.enum_name_from_value(m)
	if !ok { strings.write_string(sb, "<?>"); return }

	// FP mnemonics: replace `_` with `.` (FADD_S -> fadd.s, FMV_X_W -> fmv.x.w)
	for i in 0..<len(name) {
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
	name: string
	if cls == REG_FPR {
		name = FPR_ABI[hw]
	} else {
		name = GPR_ABI[hw]
	}
	if uppercase {
		for i in 0..<len(name) {
			c := name[i]
			if c >= 'a' && c <= 'z' { strings.write_byte(sb, c - 32) } else { strings.write_byte(sb, c) }
		}
	} else {
		strings.write_string(sb, name)
	}
}

@(private="file")
write_operand :: proc(
	sb:              ^strings.Builder,
	op:              ^Operand,
	mnemonic:        Mnemonic,
	offset_to_label: map[u32]u32,
	label_names:     ^map[u32]string,
	opts:            ^Print_Options,
) {
	switch op.kind {
	case .NONE:

	case .REGISTER:
		write_register(sb, op.reg, opts.uppercase)

	case .IMMEDIATE:
		// U-type immediates (LUI/AUIPC) are conventionally printed in hex.
		if mnemonic == .LUI || mnemonic == .AUIPC {
			isa.print_hex(sb, u64(op.immediate) & 0xFFFFF, opts)
		} else {
			write_signed_decimal(sb, op.immediate)
		}

	case .MEMORY:
		write_signed_decimal(sb, i64(op.mem.disp))
		strings.write_byte(sb, '(')
		write_register(sb, op.mem.base, opts.uppercase)
		strings.write_byte(sb, ')')

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
