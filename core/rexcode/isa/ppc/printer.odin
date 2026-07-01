// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc

import "core:strings"
import "core:fmt"
import "core:io"
import "core:os"
import "core:reflect"
import "core:rexcode/isa"

// =============================================================================
// PowerPC PRINTER
// =============================================================================
//
// Canonical assembler syntax (as accepted by binutils/LLVM):
//
//   add   rD, rA, rB            arithmetic
//   addi  rD, rA, simm          D-form immediate
//   lwz   rD, D(rA)             D-form load (mem operand printed as "off(base)")
//   lwzx  rD, rA, rB            X-form indexed
//   stwx  rS, rA, rB            X-form store
//   beq   crN, label            cond branch with CR field
//   bl    label                 unconditional+link
//   addi. rD, rA, simm          Rc=1 variant prints with trailing "."
//   addo  rD, rA, rB            OE=1 variant prints with trailing "o"
//
// Mnemonic emitted lowercase by default; flags map to "." (Rc) and "o" (OE)
// suffixes consistent with the Mnemonic enum naming (e.g. ADD_DOT -> "add.").

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
			strings.write_string(sb, "    .long 0x????????\n")
			continue
		}

		strings.write_string(sb, "    ")
		write_mnemonic(sb, inst.mnemonic, opts.uppercase)

		if inst.operand_count > 0 {
			strings.write_string(sb, " ")
			for k in 0..<inst.operand_count {
				if k > 0 { strings.write_string(sb, ", ") }
				write_operand(sb, &inst.ops[k], offset, &offset_to_label, label_names, opts)
			}
		}
		strings.write_string(sb, "\n")
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
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(os.stdout, strings.to_string(sb))
}

println :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(os.stdout, strings.to_string(sb))
}

aprint :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

aprintln :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

tprint :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

tprintln :: proc(
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

bprint :: proc(
	buf:          []u8,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) -> string {
	sb := strings.builder_from_bytes(buf)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

bprintln :: proc(
	buf:          []u8,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) -> string {
	sb := strings.builder_from_bytes(buf)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

fprint :: proc(
	fd:           ^os.File,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(fd, strings.to_string(sb))
}

fprintln :: proc(
	fd:           ^os.File,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(fd, strings.to_string(sb))
}

wprint :: proc(
	w:            io.Writer,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	io.write_string(w, strings.to_string(sb))
}

wprintln :: proc(
	w:            io.Writer,
	instructions: []Instruction,
	inst_info:    []Instruction_Info,
	label_defs:   []Label_Definition,
	tokens:       ^[dynamic]Token = nil,
	options:      ^Print_Options  = nil,
	label_names:  ^map[u32]string = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	io.write_string(w, strings.to_string(sb))
}

// =============================================================================
// Mnemonic / register writers
// =============================================================================

write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, uppercase: bool) {
	name := reflect.enum_string(m)
	// The Mnemonic enum uses _DOT / _O / _O_DOT suffixes for Rc / OE / both;
	// translate to canonical "." / "o" / "o." suffixes.
	suffix := ""
	if strings.has_suffix(name, "_O_DOT") {
		name = name[:len(name)-6]
		suffix = "o."
	} else if strings.has_suffix(name, "_DOT") {
		name = name[:len(name)-4]
		suffix = "."
	} else if strings.has_suffix(name, "_O") {
		name = name[:len(name)-2]
		suffix = "o"
	}
	if uppercase {
		strings.write_string(sb, strings.to_upper(name, context.temp_allocator))
		strings.write_string(sb, strings.to_upper(suffix, context.temp_allocator))
	} else {
		strings.write_string(sb, strings.to_lower(name, context.temp_allocator))
		strings.write_string(sb, suffix)
	}
}

write_register :: proc(sb: ^strings.Builder, r: Register, uppercase: bool) {
	hw := reg_hw(r)
	switch reg_class(r) {
	case REG_GPR:  fmt.sbprintf(sb, uppercase ? "R%d" : "r%d", hw)
	case REG_FPR:  fmt.sbprintf(sb, uppercase ? "F%d" : "f%d", hw)
	case REG_VR:   fmt.sbprintf(sb, uppercase ? "V%d" : "v%d", hw)
	case REG_VR128: fmt.sbprintf(sb, uppercase ? "VR%d" : "vr%d", u16(r) & 0x7F)
	case REG_VSR:  fmt.sbprintf(sb, uppercase ? "VS%d" : "vs%d", u16(r) & 0x3F)
	case REG_CR:   fmt.sbprintf(sb, uppercase ? "CR%d" : "cr%d", hw & 0x7)
	case REG_SPR:
		switch u16(r) & 0x3FF {
		case 1:    strings.write_string(sb, uppercase ? "XER"    : "xer")
		case 8:    strings.write_string(sb, uppercase ? "LR"     : "lr")
		case 9:    strings.write_string(sb, uppercase ? "CTR"    : "ctr")
		case 17:   strings.write_string(sb, uppercase ? "DSCR"   : "dscr")
		case 18:   strings.write_string(sb, uppercase ? "DSISR"  : "dsisr")
		case 19:   strings.write_string(sb, uppercase ? "DAR"    : "dar")
		case 22:   strings.write_string(sb, uppercase ? "DEC"    : "dec")
		case 26:   strings.write_string(sb, uppercase ? "SRR0"   : "srr0")
		case 27:   strings.write_string(sb, uppercase ? "SRR1"   : "srr1")
		case 256:  strings.write_string(sb, uppercase ? "VRSAVE" : "vrsave")
		case 268:  strings.write_string(sb, uppercase ? "TBL"    : "tbl")
		case 269:  strings.write_string(sb, uppercase ? "TBU"    : "tbu")
		case:      fmt.sbprintf(sb, "%d", u16(r) & 0x3FF)
		}
	case:
		fmt.sbprintf(sb, "?%04x", u16(r))
	}
}

// =============================================================================
// Operand writer
// =============================================================================

write_operand :: proc(
	sb:              ^strings.Builder,
	op:              ^Operand,
	inst_offset:     u32,
	offset_to_label: ^map[u32]u32,
	label_names:     ^map[u32]string,
	opts:            ^Print_Options,
) {
	#partial switch op.kind {
	case .NONE:
		// skip

	case .REGISTER:
		write_register(sb, op.reg, opts.uppercase)

	case .IMMEDIATE:
		fmt.sbprintf(sb, "%d", op.immediate)

	case .MEMORY:
		if op.mem.index == NONE {
			// D-form: "disp(rA)"
			fmt.sbprintf(sb, "%d(", op.mem.disp)
			write_register(sb, op.mem.base, opts.uppercase)
			strings.write_string(sb, ")")
		} else {
			// X-form indexed: "rA, rB"
			write_register(sb, op.mem.base, opts.uppercase)
			strings.write_string(sb, ", ")
			write_register(sb, op.mem.index, opts.uppercase)
		}

	case .RELATIVE:
		// op.relative holds a signed byte offset relative to this instruction
		// (post-decode) or an absolute label target if a label_defs roundtrip
		// has resolved it. Prefer label form when we can match the target.
		target := u32(i32(inst_offset) + i32(op.relative))
		if id, ok := offset_to_label[target]; ok {
			if label_names != nil {
				if name, has := label_names[id]; has {
					strings.write_string(sb, name)
					return
				}
			}
			fmt.sbprintf(sb, "L%d", id)
		} else {
			// Print as PC-relative offset
			if op.relative >= 0 {
				fmt.sbprintf(sb, ".+%d", op.relative)
			} else {
				fmt.sbprintf(sb, ".-%d", -op.relative)
			}
		}
	}
}
