package rexcode_x86

// =============================================================================
// SECTION: 9. PRINTER / DISASSEMBLER
// =============================================================================
//
// Modified Intel syntax disassembler with:
//   - User-provided allocator for output string
//   - Size suffixes on mnemonic instead of PTR notation:
//     .b = byte (8-bit)
//     .w = word (16-bit)
//     .d = dword (32-bit)
//     .q = qword (64-bit)
//     .x = xmmword (128-bit)
//     .y = ymmword (256-bit)
//     .z = zmmword (512-bit)
//   - Clean memory syntax: [base + index*scale + disp]
//
// Example outputs:
//   mov rax, rbx
//   mov.q rax, [rbx + rcx*8 + 0x10]
//   add.d eax, 42
//   vmovaps ymm0, ymm1

import "core:strings"
import "core:reflect"
import "core:io"
import "core:os"
import "../isa"

// -----------------------------------------------------------------------------
// 9.1 Printer Configuration (re-exported from isa)
// -----------------------------------------------------------------------------
//
// The token kinds, Print_Options, and number-formatting helpers are
// arch-independent and live in the isa package. Everything below in this
// file (register/memory/mnemonic formatting, the print sinks) is the
// per-arch part.

Token_Kind            :: isa.Token_Kind
Token                 :: isa.Token
Print_Options         :: isa.Print_Options
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS
Print_Result          :: isa.Print_Result

// -----------------------------------------------------------------------------
// 9.2 Enum-to-String Utilities
// -----------------------------------------------------------------------------

mnemonic_to_string :: proc(m: Mnemonic, lowercase: bool) -> string {
	#partial switch m {
	case .INVALID:   return "???"
	case .MOVSD_SSE: return lowercase ? "movsd" : "MOVSD"
	}
	if name, ok := reflect.enum_name_from_value(m); ok {
		return lowercase ? strings.to_lower(name, context.temp_allocator) : name
	}
	return "???"
}

token_kind_to_string :: isa.token_kind_to_string

register_name :: proc(r: Register, lowercase: bool) -> string {
	if r == NONE { return "???" }
	if r == RIP { return lowercase ? "rip" : "RIP" }

	class := reg_class(r)
	hw := reg_hw(r)

	name: string
	ok: bool

	switch class {
	case REG_GPR64: name, ok = reflect.enum_name_from_value(GPR64(hw))
	case REG_GPR32: name, ok = reflect.enum_name_from_value(GPR32(hw))
	case REG_GPR16: name, ok = reflect.enum_name_from_value(GPR16(hw))
	case REG_GPR8:  name, ok = reflect.enum_name_from_value(GPR8(hw))
	case REG_GPR8H: name, ok = reflect.enum_name_from_value(GPR8H(hw))
	case REG_XMM:   name, ok = reflect.enum_name_from_value(XMM(hw))
	case REG_YMM:   name, ok = reflect.enum_name_from_value(YMM(hw))
	case REG_ZMM:   name, ok = reflect.enum_name_from_value(ZMM(hw))
	case REG_K:     name, ok = reflect.enum_name_from_value(KREG(hw))
	case REG_SEG:   name, ok = reflect.enum_name_from_value(SREG(hw))
	case REG_MM:    name, ok = reflect.enum_name_from_value(MM(hw))
	case REG_CR:    name, ok = reflect.enum_name_from_value(CREG(hw))
	case REG_DR:    name, ok = reflect.enum_name_from_value(DREG(hw))
	case REG_ST:    name, ok = reflect.enum_name_from_value(ST(hw))
	case REG_BND:   name, ok = reflect.enum_name_from_value(BND(hw))
	case:           return "???"
	}

	if !ok { return "???" }
	return lowercase ? strings.to_lower(name, context.temp_allocator) : name
}

// -----------------------------------------------------------------------------
// 9.3 Internal Mnemonic Printing
// -----------------------------------------------------------------------------

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, inst: ^Instruction, options: ^Print_Options) {
	strings.write_string(sb, mnemonic_to_string(inst.mnemonic, !options.uppercase))
	for i in 0..<inst.operand_count {
		if inst.ops[i].kind == .MEMORY {
			suffix := size_to_suffix(inst.ops[i].size)
			if suffix != 0 {
				strings.write_byte(sb, '.')
				strings.write_byte(sb, options.uppercase ? suffix - 32 : suffix)
			}
			break
		}
	}
}

@(private="file")
size_to_suffix :: proc(size: u8) -> u8 {
	switch size {
	case 1:  return 'b'
	case 2:  return 'w'
	case 4:  return 'd'
	case 8:  return 'q'
	case 16: return 'x'
	case 32: return 'y'
	case 64: return 'z'
	}
	return 0
}

// -----------------------------------------------------------------------------
// 9.4 Internal Operand Printing
// -----------------------------------------------------------------------------

@(private="file")
write_operand :: proc(sb: ^strings.Builder, op: ^Operand, options: ^Print_Options) {
	switch op.kind {
	case .NONE:      // Nothing
	case .REGISTER:  write_register(sb, op.reg, options)
	case .MEMORY:    write_memory(sb, op.mem, options)
	case .IMMEDIATE: write_immediate(sb, op.immediate, op.size, options)
	case .RELATIVE:  write_relative(sb, op.relative, op.size, options)
	}
}

// -----------------------------------------------------------------------------
// 9.5 Internal Register Printing
// -----------------------------------------------------------------------------

@(private="file")
write_register :: proc(sb: ^strings.Builder, r: Register, options: ^Print_Options) {
	strings.write_string(sb, register_name(r, !options.uppercase))
}

// -----------------------------------------------------------------------------
// 9.6 Internal Memory Operand Printing
// -----------------------------------------------------------------------------

@(private="file")
write_memory :: proc(sb: ^strings.Builder, m: Memory, options: ^Print_Options) {
	strings.write_byte(sb, '[')

	has_content := false

	// RIP-relative
	if mem_is_rip_relative(m) {
		if options.uppercase {
			strings.write_string(sb, "RIP")
		} else {
			strings.write_string(sb, "rip")
		}
		has_content = true

		disp := m.disp
		if disp != 0 {
			if disp > 0 {
				strings.write_string(sb, " + ")
				print_hex(sb, u64(disp), options)
			} else {
				strings.write_string(sb, " - ")
				print_hex(sb, u64(-disp), options)
			}
		}
	} else {
		// Base register
		if mem_has_base(m) {
			base := mem_base(m)
			write_register(sb, base, options)
			has_content = true
		}

		// Index register with scale
		if mem_has_index(m) {
			if has_content {
				strings.write_string(sb, " + ")
			}
			index := mem_index(m)
			write_register(sb, index, options)

			scale := mem_scale(m)
			if scale > 1 {
				strings.write_byte(sb, '*')
				strings.write_byte(sb, '0' + scale)
			}
			has_content = true
		}

		// Displacement
		disp := m.disp
		if disp != 0 || !has_content {
			if has_content {
				if disp > 0 {
					strings.write_string(sb, " + ")
					print_hex(sb, u64(disp), options)
				} else {
					strings.write_string(sb, " - ")
					print_hex(sb, u64(-disp), options)
				}
			} else {
				// Absolute address
				print_hex(sb, u64(u32(disp)), options)
				has_content = true
			}
		}
	}

	strings.write_byte(sb, ']')
}

// -----------------------------------------------------------------------------
// 9.7 Internal Immediate and Relative Printing
// -----------------------------------------------------------------------------

@(private="file")
write_immediate :: proc(sb: ^strings.Builder, immediate: i64, size: u8, options: ^Print_Options) {
	// Small positive values: print as decimal
	if immediate >= 0 && immediate < 10 {
		strings.write_byte(sb, '0' + u8(immediate))
		return
	}

	// Negative small values: print as signed decimal
	if immediate < 0 && immediate >= -9 {
		strings.write_byte(sb, '-')
		strings.write_byte(sb, '0' + u8(-immediate))
		return
	}

	// Otherwise print as hex
	if immediate < 0 {
		strings.write_byte(sb, '-')
		print_hex(sb, u64(-immediate), options)
	} else {
		print_hex(sb, u64(immediate), options)
	}
}

@(private="file")
write_relative :: proc(sb: ^strings.Builder, relative: i64, size: u8, options: ^Print_Options) {
	// Relative offset - print as signed hex offset
	if relative >= 0 {
		strings.write_byte(sb, '+')
		print_hex(sb, u64(relative), options)
	} else {
		strings.write_byte(sb, '-')
		print_hex(sb, u64(-relative), options)
	}
}

// Number-formatting helpers are arch-independent — re-exported from isa.
print_hex        :: isa.print_hex
print_hex_digits :: isa.print_hex_digits
print_decimal    :: isa.print_decimal

// -----------------------------------------------------------------------------
// 9.8 Batch Disassembly Printer
// -----------------------------------------------------------------------------
sbprint :: proc(
	sb:           ^strings.Builder,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,  // Optional: for named label output (id → name)
) {
	options := options != nil ? options^ : DEFAULT_PRINT_OPTIONS

	emit_token :: proc(tokens: ^[dynamic]Token, sb: ^strings.Builder, kind: Token_Kind, instruction_index: u16, start: int) {
		if tokens != nil {
			length := strings.builder_len(sb^) - start
			if length > 0 {
				append(tokens, Token{
					offset = u32(start),
					length = u16(length),
					kind = kind,
					instruction_index = instruction_index,
				})
			}
		}
	}

	for &inst, instruction_index in instructions {
		info := &inst_info[instruction_index]

		// Check if there's a label at this offset
		for label_def, label_id in label_defs {
			if label_def != LABEL_UNDEFINED && u32(label_def) == info.offset {
				// Print label definition
				start := strings.builder_len(sb^)
				if name, ok := label_names^[u32(label_id)]; ok {
					strings.write_string(sb, name)
				} else {
					strings.write_string(sb, options.label_prefix)
					print_decimal(sb, u32(label_id))
				}
				strings.write_byte(sb, ':')
				emit_token(tokens, sb, .LABEL_DEF, 0xFFFF, start)

				start = strings.builder_len(sb^)
				strings.write_string(sb, options.separator)
				emit_token(tokens, sb, .NEWLINE, 0xFFFF, start)
				break
			}
		}

		// Print offset if requested, otherwise indent
		if options.show_offsets {
			start := strings.builder_len(sb^)
			print_hex(sb, u64(info.offset), &options)
			strings.write_byte(sb, ':')
			emit_token(tokens, sb, .OFFSET, u16(instruction_index), start)

			start = strings.builder_len(sb^)
			strings.write_byte(sb, ' ')
			emit_token(tokens, sb, .WHITESPACE, u16(instruction_index), start)
		} else if len(options.indent) > 0 {
			start := strings.builder_len(sb^)
			strings.write_string(sb, options.indent)
			emit_token(tokens, sb, .WHITESPACE, u16(instruction_index), start)
		}

		// Print mnemonic
		{
			start := strings.builder_len(sb^)
			write_mnemonic(sb, &inst, &options)
			emit_token(tokens, sb, .MNEMONIC, u16(instruction_index), start)
		}

		// Print operands
		for i in 0..<inst.operand_count {
			if i == 0 {
				start := strings.builder_len(sb^)
				strings.write_byte(sb, ' ')
				emit_token(tokens, sb, .WHITESPACE, u16(instruction_index), start)
			} else {
				start := strings.builder_len(sb^)
				strings.write_byte(sb, ',')
				emit_token(tokens, sb, .PUNCTUATION, u16(instruction_index), start)
				if options.space_after_comma {
					start = strings.builder_len(sb^)
					strings.write_byte(sb, ' ')
					emit_token(tokens, sb, .WHITESPACE, u16(instruction_index), start)
				}
			}

			op := &inst.ops[i]
			switch op.kind {
			case .NONE:
				//
			case .REGISTER:
				start := strings.builder_len(sb^)
				write_register(sb, op.reg, &options)
				emit_token(tokens, sb, .REGISTER, u16(instruction_index), start)

			case .IMMEDIATE:
				start := strings.builder_len(sb^)
				write_immediate(sb, op.immediate, op.size, &options)
				emit_token(tokens, sb, .IMMEDIATE, u16(instruction_index), start)

			case .MEMORY:
				write_memory_with_tokens(sb, op.mem, &options, tokens, u16(instruction_index))

			case .RELATIVE:
				// Compute absolute target and check if it matches a label
				inst_end := i64(info.offset) + i64(inst.length)
				target := inst_end + op.relative

				// Find label at this target
				found_label: u32 = 0
				found_label_valid := false
				for lbl_id in 0..<u32(len(label_defs)) {
					if label_defs[lbl_id] != LABEL_UNDEFINED && i64(label_defs[lbl_id]) == target {
						found_label = lbl_id
						found_label_valid = true
						break
					}
				}

				if found_label_valid {
					start := strings.builder_len(sb^)
					if name, ok := label_names^[found_label]; ok {
						strings.write_string(sb, name)
					} else {
						strings.write_string(sb, options.label_prefix)
						print_decimal(sb, found_label)
					}
					emit_token(tokens, sb, .LABEL_REF, u16(instruction_index), start)
				} else {
					start := strings.builder_len(sb^)
					write_relative(sb, op.relative, op.size, &options)
					emit_token(tokens, sb, .IMMEDIATE, u16(instruction_index), start)
				}
			}
		}

		// Separator (newline by default)
		if len(options.separator) > 0 {
			start := strings.builder_len(sb^)
			strings.write_string(sb, options.separator)
			emit_token(tokens, sb, .NEWLINE, u16(instruction_index), start)
		}
	}
}

// write_memory_with_tokens: Print memory operand with token metadata
@(private="file")
write_memory_with_tokens :: proc(
	sb:                ^strings.Builder,
	m:                 Memory,
	options:           ^Print_Options,
	tokens:            ^[dynamic]Token,
	instruction_index: u16,
) {
	emit_token :: proc(tokens: ^[dynamic]Token, sb: ^strings.Builder, kind: Token_Kind, instruction_index: u16, start: int) {
		if tokens != nil {
			length := strings.builder_len(sb^) - start
			if length > 0 {
				append(tokens, Token{
					offset = u32(start),
					length = u16(length),
					kind = kind,
					instruction_index = instruction_index,
				})
			}
		}
	}

	start := strings.builder_len(sb^)
	strings.write_byte(sb, '[')
	emit_token(tokens, sb, .MEMORY_BRACKET, instruction_index, start)

	has_content := false

	// RIP-relative
	if mem_is_rip_relative(m) {
		start = strings.builder_len(sb^)
		if options.uppercase {
			strings.write_string(sb, "RIP")
		} else {
			strings.write_string(sb, "rip")
		}
		emit_token(tokens, sb, .REGISTER, instruction_index, start)
		has_content = true

		disp := m.disp
		if disp != 0 {
			start = strings.builder_len(sb^)
			if disp > 0 {
				strings.write_string(sb, " + ")
			} else {
				strings.write_string(sb, " - ")
			}
			emit_token(tokens, sb, .MEMORY_OPERATOR, instruction_index, start)

			start = strings.builder_len(sb^)
			print_hex(sb, u64(disp > 0 ? disp : -disp), options)
			emit_token(tokens, sb, .MEMORY_DISP, instruction_index, start)
		}
	} else {
		// Base register
		if mem_has_base(m) {
			base := mem_base(m)
			start = strings.builder_len(sb^)
			write_register(sb, base, options)
			emit_token(tokens, sb, .REGISTER, instruction_index, start)
			has_content = true
		}

		// Index register with scale
		if mem_has_index(m) {
			if has_content {
				start = strings.builder_len(sb^)
				strings.write_string(sb, " + ")
				emit_token(tokens, sb, .MEMORY_OPERATOR, instruction_index, start)
			}

			index := mem_index(m)
			start = strings.builder_len(sb^)
			write_register(sb, index, options)
			emit_token(tokens, sb, .REGISTER, instruction_index, start)

			scale := mem_scale(m)
			if scale > 1 {
				start = strings.builder_len(sb^)
				strings.write_byte(sb, '*')
				emit_token(tokens, sb, .MEMORY_OPERATOR, instruction_index, start)

				start = strings.builder_len(sb^)
				strings.write_byte(sb, '0' + scale)
				emit_token(tokens, sb, .MEMORY_SCALE, instruction_index, start)
			}
			has_content = true
		}

		// Displacement
		disp := m.disp
		if disp != 0 || !has_content {
			if has_content {
				start = strings.builder_len(sb^)
				if disp > 0 {
					strings.write_string(sb, " + ")
				} else {
					strings.write_string(sb, " - ")
				}
				emit_token(tokens, sb, .MEMORY_OPERATOR, instruction_index, start)

				start = strings.builder_len(sb^)
				print_hex(sb, u64(disp > 0 ? disp : -disp), options)
				emit_token(tokens, sb, .MEMORY_DISP, instruction_index, start)
			} else {
				// Absolute address
				start = strings.builder_len(sb^)
				print_hex(sb, u64(u32(disp)), options)
				emit_token(tokens, sb, .MEMORY_DISP, instruction_index, start)
			}
		}
	}

	start = strings.builder_len(sb^)
	strings.write_byte(sb, ']')
	emit_token(tokens, sb, .MEMORY_BRACKET, instruction_index, start)
}

// -----------------------------------------------------------------------------
// 9.9 Print Function Variants
// -----------------------------------------------------------------------------

// sbprintln: Print instructions to string builder with trailing newline
sbprintln :: proc(
	sb:           ^strings.Builder,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) {
	#force_inline sbprint(sb, instructions, inst_info, label_defs, tokens, options, label_names)
	strings.write_byte(sb, '\n')
}

// print: Print instructions to stdout
print :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	#force_inline sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	os.write_string(os.stdout, result)
}

// println: Print instructions to stdout with trailing newline
println :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	#force_inline sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	os.write_string(os.stdout, result)
}

// aprint: Print instructions to an allocated string
aprint :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	#force_inline sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	return result
}

// aprintln: Print instructions to an allocated string with trailing newline
aprintln :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	#force_inline sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	return result
}

// tprint: Print instructions to a string using the temp allocator
tprint :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
	allocator := context.temp_allocator,
) -> string {
	sb := strings.builder_make(allocator)
	#force_inline sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	return result
}

// tprintln: Print instructions to a string using the temp allocator with temp allocator
tprintln :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
	allocator := context.temp_allocator,
) -> string {
	sb := strings.builder_make(allocator)
	#force_inline sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	return result
}

// bprint: Print instructions to a byte buffer
bprint :: #force_inline proc(
	buf:          []u8,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) -> string {
	sb := strings.builder_from_slice(buf)
	#force_inline sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	return result
}

// bprintln: Print instructions to a byte buffer with trailing newline
bprintln :: proc(
	buf:          []u8,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) -> string {
	sb := strings.builder_from_slice(buf)
	#force_inline sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	return result
}

// fprint: Print instructions to a file handle
fprint :: proc(
	fd:           ^os.File,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	#force_inline sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	os.write_string(fd, result)
}

// fprintln: Print instructions to a file handle with trailing newline
fprintln :: proc(
	fd:           ^os.File,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	#force_inline sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	os.write_string(fd, result)
}

// wprint: Print instructions to an io.Writer
wprint :: #force_inline proc(
	w:            io.Writer,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	io.write_string(w, result)
}

// wprintln: Print instructions to an io.Writer with trailing newline
wprintln :: #force_inline proc(
	w:            io.Writer,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	result := strings.to_string(sb)
	io.write_string(w, result)
}
