// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "core:strings"
import "core:strconv"
import "core:os"
import "core:io"
import "core:rexcode/isa"

// =============================================================================
// WebAssembly PRINTER
// =============================================================================
//
// Emits WebAssembly text-format (WAT) instruction syntax: the folded-stack
// form is not reconstructed (that needs structure the linear stream does not
// carry); instead each instruction prints on its own line as
//
//   <mnemonic> <immediate>*
//
// Examples:
//
//   i32.const 42
//   local.get 0
//   i32.add
//   call 3
//   block (result i32)
//   i32.load offset=8 align=2
//   br_table 0 1 2          ; cases 0 1, default 2
//   ref.null func
//   f64.const 3.14
//
// Mnemonic spelling comes from the explicit MNEMONIC_NAMES table (WASM mixes
// '.' and '_' irregularly, e.g. `local.get` vs `i32.trunc_f32_s`). WASM has
// no register file, so register printing is vestigial.

Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

mnemonic_to_string :: proc(m: Mnemonic, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_mnemonic(&sb, m, !lowercase)
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

	for &inst, i in instructions {
		offset := inst_info[i].offset if i < len(inst_info) else u32(0)

		strings.write_string(sb, opts.indent)
		if opts.show_offsets {
			isa.print_hex(sb, u64(offset), opts)
			strings.write_string(sb, ": ")
		}

		write_mnemonic(sb, inst.mnemonic, opts.uppercase)

		// br_table prints its case vector followed by the default depth.
		#partial switch inst.mnemonic {
		case .BR_TABLE:
			for t in inst.targets {
				strings.write_byte(sb, ' ')
				write_decimal_u32(sb, t)
			}
			strings.write_byte(sb, ' ')
			write_decimal_u32(sb, inst.ops[0].index)
		case .V128_CONST:
			strings.write_string(sb, " i8x16")
			for bb in inst.bytes {
				strings.write_byte(sb, ' ')
				isa.print_hex(sb, u64(bb), opts)
			}
		case .I8X16_SHUFFLE:
			for bb in inst.bytes {
				strings.write_byte(sb, ' ')
				write_decimal_u32(sb, u32(bb))
			}
		case:
			for slot in 0..<int(inst.operand_count) {
				strings.write_byte(sb, ' ')
				write_operand(sb, &inst.ops[slot], inst.mnemonic, label_names, opts)
			}
		}

		strings.write_string(sb, opts.separator)
	}
	_ = tokens
	_ = label_defs
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
	name := MNEMONIC_NAMES[m]
	if name == "" { strings.write_string(sb, "<?>"); return }
	if uppercase {
		for i in 0..<len(name) {
			c := name[i] // to force ASCII
			if 'a' <= c && c <= 'z' {
				strings.write_byte(sb, c - 32)
			} else {
				strings.write_byte(sb, c)
			}
		}
	} else {
		strings.write_string(sb, name)
	}
}

@(private="file")
write_operand :: proc(
	sb:          ^strings.Builder,
	op:          ^Operand,
	mnemonic:    Mnemonic,
	label_names: ^map[u32]string,
	opts:        ^Print_Options,
) {
	switch op.kind {
	case .NONE:

	case .IMMEDIATE:
		if mnemonic == .REF_NULL {
			write_heap_type(sb, u8(op.immediate))
		} else if op.flags.is_float {
			write_float(sb, op)
		} else {
			write_signed_decimal(sb, op.immediate)
		}

	case .INDEX:
		if op.flags.symbolic {
			write_label(sb, op.index, label_names, opts)
		} else {
			write_decimal_u32(sb, op.index)
		}

	case .MEMARG:
		// WAT prints non-trivial memargs as `offset=N align=N` (omitting either
		// when it is the natural default is a refinement; we print both).
		strings.write_string(sb, "offset=")
		write_decimal_u32(sb, op.memarg.offset)
		strings.write_string(sb, " align=")
		write_decimal_u32(sb, op.memarg.align)

	case .BLOCK_TYPE:
		write_block_type(sb, op.immediate)
	}
}

@(private="file")
write_block_type :: proc(sb: ^strings.Builder, v: i64) {
	switch Block_Type(v) {
	case .EMPTY:     // no result annotation
	case .I32:       strings.write_string(sb, "(result i32)")
	case .I64:       strings.write_string(sb, "(result i64)")
	case .F32:       strings.write_string(sb, "(result f32)")
	case .F64:       strings.write_string(sb, "(result f64)")
	case .V128:      strings.write_string(sb, "(result v128)")
	case .FUNCREF:   strings.write_string(sb, "(result funcref)")
	case .EXTERNREF: strings.write_string(sb, "(result externref)")
	case:
		// non-negative: a type index
		strings.write_string(sb, "(type ")
		write_decimal_u32(sb, u32(v))
		strings.write_byte(sb, ')')
	}
}

@(private="file")
write_heap_type :: proc(sb: ^strings.Builder, b: u8) {
	#partial switch Value_Type(b) {
	case .FUNCREF:   strings.write_string(sb, "func")
	case .EXTERNREF: strings.write_string(sb, "extern")
	case:
		write_decimal_u32(sb, u32(b))
	}
}

@(private="file")
write_float :: proc(sb: ^strings.Builder, op: ^Operand) {
	buf: [40]u8
	if op.size == 4 {
		f := transmute(f32)u32(op.immediate)
		s := strconv.write_float(buf[:], f64(f), 'g', -1, 32)
		strings.write_string(sb, s)
	} else {
		f := transmute(f64)u64(op.immediate)
		s := strconv.write_float(buf[:], f, 'g', -1, 64)
		strings.write_string(sb, s)
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
		write_decimal_u64(sb, u64(-(v + 1)) + 1)
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
