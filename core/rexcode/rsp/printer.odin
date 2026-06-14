package rexcode_rsp

import "core:strings"
import "core:reflect"
import "core:os"
import "core:io"
import "../isa"

// =============================================================================
// N64 RSP PRINTER
// =============================================================================
//
// Classical MIPS-ish syntax adapted for the RSP:
//   - Scalar GPRs use the same ABI names as MIPS (`$zero`, `$t0`, `$sp`).
//   - Vector regs are `$v0..$v31` with an optional element suffix `[N]`
//     for VR_ELEM operands (`vmulf $v0, $v1, $v2[3]`).
//   - Vector flag regs print as `vco`, `vcc`, `vce`.
//   - Vector memory is `e[N], offset(base)` matching N64 toolchain output.
//   - CP0 DMA registers print by enum name when known.
//
// All seven sink families (sbprint / print / aprint / tprint / bprint /
// fprint / wprint) wrap the same core `sbprint`.

Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

@(private="file")
GPR_NAMES_ABI := [32]string{
	"zero", "at",
	"v0", "v1",
	"a0", "a1", "a2", "a3",
	"t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
	"s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
	"t8", "t9",
	"k0", "k1",
	"gp", "sp", "fp", "ra",
}

@(private="file")
CP0_NAMES := [16]string{
	"sp_mem_addr",  "sp_dram_addr", "sp_rd_len",   "sp_wr_len",
	"sp_status",    "sp_dma_full",  "sp_dma_busy", "sp_semaphore",
	"dp_start",     "dp_end",       "dp_current",  "dp_status",
	"dp_clock",     "dp_bufbusy",   "dp_pipebusy", "dp_tmem",
}

mnemonic_to_string :: proc(m: Mnemonic, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_mnemonic(&sb, m, !lowercase)
	return strings.to_string(sb)
}

register_name :: proc(r: Register, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_register(&sb, r, !lowercase, 0xFF)   // no element suffix
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
					if opts.space_after_comma {
						strings.write_byte(sb, ' ')
					}
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

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, uppercase: bool) {
	name, ok := reflect.enum_name_from_value(m)
	if !ok {
		strings.write_string(sb, "<?>")
		return
	}
	for i in 0..<len(name) {
		c := name[i]
		if !uppercase && c >= 'A' && c <= 'Z' {
			strings.write_byte(sb, c + 32)
		} else {
			strings.write_byte(sb, c)
		}
	}
}

@(private="file")
write_register :: proc(sb: ^strings.Builder, r: Register, uppercase: bool, element: u8) {
	if r == NONE {
		strings.write_string(sb, "<none>")
		return
	}
	cls := reg_class(r)
	hw  := reg_hw(r)

	// Vector flag regs print without `$`.
	if cls == REG_VC {
		s: string
		switch hw {
		case 0: s = uppercase ? "VCO" : "vco"
		case 1: s = uppercase ? "VCC" : "vcc"
		case 2: s = uppercase ? "VCE" : "vce"
		case:   s = "?"
		}
		strings.write_string(sb, s)
		return
	}

	strings.write_byte(sb, '$')
	switch cls {
	case REG_GPR:
		name := GPR_NAMES_ABI[hw]
		if uppercase {
			for i in 0..<len(name) {
				c := name[i]
				if c >= 'a' && c <= 'z' { strings.write_byte(sb, c - 32) }
				else                    { strings.write_byte(sb, c)      }
			}
		} else {
			strings.write_string(sb, name)
		}
	case REG_VR:
		strings.write_byte(sb, uppercase ? 'V' : 'v')
		write_decimal_u32(sb, u32(hw))
		if element != 0xFF {
			strings.write_byte(sb, '[')
			write_decimal_u32(sb, u32(element))
			strings.write_byte(sb, ']')
		}
	case REG_CP0:
		if int(hw) < len(CP0_NAMES) {
			name := CP0_NAMES[hw]
			if uppercase {
				for i in 0..<len(name) {
					c := name[i]
					if c >= 'a' && c <= 'z' { strings.write_byte(sb, c - 32) }
					else                    { strings.write_byte(sb, c)      }
				}
			} else {
				strings.write_string(sb, name)
			}
		} else {
			write_decimal_u32(sb, u32(hw))
		}
	case:
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
		write_register(sb, op.reg, opts.uppercase, 0xFF)

	case .VECTOR_REG:
		// Print element only when non-zero (idiomatic disassembly).
		elem := op.element
		if elem == 0 { elem = 0xFF }
		write_register(sb, op.reg, opts.uppercase, elem)

	case .IMMEDIATE:
		write_signed_decimal(sb, op.immediate)

	case .MEMORY:
		write_signed_decimal(sb, i64(op.mem.disp))
		strings.write_byte(sb, '(')
		write_register(sb, op.mem.base, opts.uppercase, 0xFF)
		strings.write_byte(sb, ')')

	case .VECTOR_MEM:
		// Syntax: `offset(base)` -- element comes from the paired vector reg
		// operand, not from VECTOR_MEM, so we don't repeat it here.
		write_signed_decimal(sb, i64(op.vmem.offset))
		strings.write_byte(sb, '(')
		write_register(sb, op.vmem.base, opts.uppercase, 0xFF)
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
	if v == 0 {
		strings.write_byte(sb, '0')
		return
	}
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
	if v == 0 {
		strings.write_byte(sb, '0')
		return
	}
	buf: [20]u8
	i := 0
	n := v
	for n > 0 { buf[i] = '0' + u8(n % 10); n /= 10; i += 1 }
	for j := i - 1; j >= 0; j -= 1 { strings.write_byte(sb, buf[j]) }
}
