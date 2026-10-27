// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "core:fmt"
import "core:strings"
import "core:strconv"

// =============================================================================
// SECTION: Printer  (Module -> WebAssembly text listing)
// =============================================================================
//
// The third ir verb (docs/ir_design.md §4), same signature as the SPIR-V
// printer: `print(m, sb, options)`, disassembling the module into a caller-owned
// builder. It walks functions -> blocks -> operations and emits one instruction
// per line in the linear (unfolded) WAT form
//
//   <mnemonic> <immediate>*
//
// e.g.
//
//   i32.const 42
//   local.get 0
//   i32.add
//   call 3
//   block (result i32)
//   i32.load offset=8 align=2
//   br_table 0 1 2            ; cases 0 1, default 2
//   ref.null func
//   f64.const 3.14
//   v128.const i8x16 0x01 0x02 ...
//
// The folded-stack form is not reconstructed (that needs structure the linear
// stream does not carry). Mnemonic spelling comes from the explicit
// MNEMONIC_NAMES table (WASM mixes '.' and '_' irregularly, e.g. `local.get`
// vs `i32.trunc_f32_s`). Immediates are recovered from the shared `ir.Operand`
// model via the operands.odin accessors -- structured payloads (memarg,
// blocktype, reftype, lanes, v128) ride in ATTRIBUTE operands tagged in `aux`.

// print: disassemble `m` into the caller-owned builder `sb`. The canonical ir
// print verb; `sbprint` / `tprint` below are thin convenience sinks over it.
print :: proc(m: Module, sb: ^strings.Builder, options: ^Print_Options = nil) {
	m := m
	opts := DEFAULT_PRINT_OPTIONS
	if options != nil { opts = options^ }

	for fn in m.functions {
		if fn.name != "" {
			strings.write_string(sb, "func ")
			strings.write_string(sb, fn.name)
			strings.write_string(sb, ":")
			strings.write_string(sb, opts.separator)
		}
		for blk in fn.blocks {
			for &op in blk.ops {
				write_operation(sb, &op, &opts, &m)
				strings.write_string(sb, opts.separator)
			}
		}
	}
}

// sbprint: disassemble a bare operation stream (a WASM `expr`) -- the reusable
// core that `print` runs per block, and the mirror of the encoder's
// `encode_ops` / decoder's `decode_ops`.
sbprint :: proc(sb: ^strings.Builder, ops: []Operation, options: ^Print_Options = nil) {
	opts := DEFAULT_PRINT_OPTIONS
	if options != nil { opts = options^ }
	for &op in ops {
		write_operation(sb, &op, &opts, nil)
		strings.write_string(sb, opts.separator)
	}
}

// tprint: temp-allocated string of an operation stream (spot-checks / debugging).
@(require_results)
tprint :: proc(ops: []Operation, options: ^Print_Options = nil) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, ops, options)
	return strings.to_string(sb)
}

// aprint: caller-allocated string of an operation stream.
@(require_results)
aprint :: proc(ops: []Operation, options: ^Print_Options = nil, allocator := context.allocator) -> string {
	sb := strings.builder_make(allocator)
	sbprint(&sb, ops, options)
	return strings.to_string(sb)
}

@(require_results)
mnemonic_to_string :: proc(op: Opcode, uppercase := false, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_mnemonic(&sb, op, uppercase)
	return strings.to_string(sb)
}

// =============================================================================
// Per-operation writer
// =============================================================================

write_operation :: proc(sb: ^strings.Builder, op: ^Operation, opts: ^Print_Options, module: Maybe(^Module)) {
	strings.write_string(sb, opts.indent)

	opcode := Opcode(op.opcode)
	write_mnemonic(sb, opcode, opts.uppercase)

	// A couple of opcodes carry a bespoke operand layout the generic per-operand
	// walk would mis-order; specialise those, and fall through for the rest.
	#partial switch opcode {
	case .BR_TABLE:
		// operands = [default, case0, case1, ...]; WAT prints the cases first,
		// then the default depth, matching the binary order.
		for c in op.operands[1:] {
			strings.write_byte(sb, ' ')
			strings.write_u64(sb, u64(operand_index(c)))
		}
		if len(op.operands) > 0 {
			strings.write_byte(sb, ' ')
			strings.write_u64(sb, u64(operand_index(op.operands[0])))
		}

	case .V128_CONST:
		strings.write_string(sb, " i8x16")
		if len(op.operands) >= 2 {
			bytes := operand_v128(op.operands[0], op.operands[1])
			for bb in bytes {
				strings.write_byte(sb, ' ')
				print_hex(sb, u64(bb), opts)
			}
		}

	case .I8X16_SHUFFLE:
		if len(op.operands) >= 2 {
			bytes := operand_v128(op.operands[0], op.operands[1])
			for bb in bytes {
				strings.write_byte(sb, ' ')
				strings.write_u64(sb, u64(bb))
			}
		}

	case .CALL:
		if m, ok := module.?; ok {
			assert(len(op.operands) == 1)
			o := op.operands[0]
			if o.kind == .REF {
				if o.imm < i64(len(m.functions)) {
					name := m.functions[o.imm].name
					write_name_or_id(sb, name, Id(o.imm))
					break
				}

			}
		}
		fallthrough
	case:
		for &o in op.operands {
			write_operand(sb, &o, opcode, opts)
		}
	}
}

@(private, require_results)
ident_ok :: proc(s: string) -> bool {
	if len(s) == 0 {
		return false
	}
	#no_bounds_check for i in 0..<len(s) {
		c := s[i]
		switch c {
		case '0'..='9', 'A'..='Z', 'a'..='z':
			// okay
		case '!', '#', '$', '%', '&', '\'', '*', '+', '-', '.', '/',
		     ':', '<', '=', '>', '?', '@', '\\', '^', '_', '`', '|',
		     '~':
			// okay
		case:
			return false
		}
	}
	return true
}

write_name_or_id :: proc(sb: ^strings.Builder, name: string, index: Id) {
	if name != "" && ident_ok(name) {
		strings.write_string(sb, " $")
		strings.write_string(sb, name)
	} else {
		fmt.sbprintf(sb, " %d", index)
	}
}


write_id_or_comment :: proc(sb: ^strings.Builder, name: string, index: Id) {
	if name != "" && ident_ok(name) {
		strings.write_string(sb, " $")
		strings.write_string(sb, name)
	} else {
		fmt.sbprintf(sb, " (;%d;)", index)
	}
}

// =============================================================================
// Internal writers
// =============================================================================

write_mnemonic :: proc(sb: ^strings.Builder, op: Opcode, uppercase: bool) {
	name := MNEMONIC_NAMES[op]
	if name == "" {
		strings.write_string(sb, "<?>")
		return
	}
	if uppercase {
		for i in 0..<len(name) {
			switch c := name[i]; c { // force ASCII
			case 'a'..='z':
				strings.write_byte(sb, c - 32)
			case:
				strings.write_byte(sb, c)
			}
		}
	} else {
		strings.write_string(sb, name)
	}
}

// One `ir.Operand`, dispatched on its shared kind (then, for ATTRIBUTE, on the
// WASM `Attr` tag in `aux`). A leading space separates it from the mnemonic /
// previous operand -- matching the old ISA printer's spacing.
write_operand :: proc(sb: ^strings.Builder, o: ^Operand, opcode: Opcode, opts: ^Print_Options) {
	switch o.kind {
	case .NONE:
		// nothing

	case .LIT_INT:
		strings.write_byte(sb, ' ')
		strings.write_i64(sb, o.imm)

	case .LIT_FLOAT:
		strings.write_byte(sb, ' ')
		write_float(sb, o)

	case .REF:
		strings.write_byte(sb, ' ')
		if operand_symbolic(o^) {
			write_label(sb, operand_index(o^))
		} else {
			strings.write_u64(sb, u64(operand_index(o^)))
		}

	case .TYPE:
		strings.write_byte(sb, ' ')
		strings.write_string(sb, "(type ")
		strings.write_u64(sb, u64(u32(operand_type(o^))))
		strings.write_byte(sb, ')')

	case .ATTRIBUTE:
		write_attribute(sb, o, opts)
	}
}

write_attribute :: proc(sb: ^strings.Builder, o: ^Operand, opts: ^Print_Options) {
	switch operand_attr(o^) {
	case .NONE:
		// nothing

	case .BLOCKTYPE:
		write_block_type(sb, o.imm)

	case .MEMARG:
		// WAT prints non-trivial memargs as `offset=N align=N`, omitting either
		// when it is the natural default. (`align` here is the byte alignment,
		// already expanded from the on-wire log2 by the decoder.)
		ma := operand_memarg(o^)
		if ma.offset != 0 {
			strings.write_string(sb, " offset=")
			strings.write_u64(sb, u64(ma.offset))
		}
		if ma.align != 0 {
			strings.write_string(sb, " align=")
			strings.write_u64(sb, u64(ma.align))
		}

	case .REFTYPE:
		strings.write_byte(sb, ' ')
		write_heap_type(sb, u8(o.imm))

	case .LANE:
		strings.write_byte(sb, ' ')
		strings.write_u64(sb, u64(u8(o.imm)))

	case .V128_LO, .V128_HI:
		// v128 literals are printed by the V128_CONST / I8X16_SHUFFLE special
		// cases in write_operation; a stray half here needs no output.
	}
}

// A blocktype annotation. Returns nothing meaningful; kept a proc for symmetry
// with the old printer. EMPTY prints nothing (the common `block`/`loop` case).
write_block_type :: proc(sb: ^strings.Builder, v: i64) -> (printed: bool) {
	switch Block_Type(v) {
	case .EMPTY:     // no result annotation
	case .I32:       strings.write_string(sb, " (result i32)");       return true
	case .I64:       strings.write_string(sb, " (result i64)");       return true
	case .F32:       strings.write_string(sb, " (result f32)");       return true
	case .F64:       strings.write_string(sb, " (result f64)");       return true
	case .V128:      strings.write_string(sb, " (result v128)");      return true
	case .FUNCREF:   strings.write_string(sb, " (result funcref)");   return true
	case .EXTERNREF: strings.write_string(sb, " (result externref)"); return true
	case:
		if v >= 0 {
			// a type index (positive s33)
			strings.write_string(sb, " (type ")
			strings.write_u64(sb, u64(u32(v)))
			strings.write_byte(sb, ')')
			return true
		}
	}
	return false
}

write_heap_type :: proc(sb: ^strings.Builder, b: u8) {
	#partial switch Value_Type(b) {
	case .FUNCREF:   strings.write_string(sb, "func")
	case .EXTERNREF: strings.write_string(sb, "extern")
	case:            strings.write_u64(sb, u64(u32(b)))
	}
}

write_float :: proc(sb: ^strings.Builder, o: ^Operand) {
	buf: [40]u8
	if o.aux == 32 {
		f := transmute(f32)u32(o.imm)
		s := strconv.write_float(buf[:], f64(f), 'g', -1, 32)
		strings.write_string(sb, s)
	} else {
		f := transmute(f64)u64(o.imm)
		s := strconv.write_float(buf[:], f, 'g', -1, 64)
		strings.write_string(sb, s)
	}
}

write_label :: proc(sb: ^strings.Builder, label_id: u32) {
	strings.write_byte(sb, '$')
	strings.write_u64(sb, u64(label_id))
}
