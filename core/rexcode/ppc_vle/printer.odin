package rexcode_ppc_vle

import "core:strings"
import "core:fmt"
import "core:io"
import "core:os"
import "core:reflect"
import "../isa"

// =============================================================================
// PowerPC VLE Printer
// =============================================================================
//
// Outputs canonical VLE assembly: `se_li r3, 0`, `e_add16i r3, r4, 100`, etc.
// Mnemonics are lowercased; `_DOT` suffix translates to `.`.

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
			strings.write_string(sb, "    .short 0xINVALID\n")
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

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, uppercase: bool) {
	name := reflect.enum_string(m)
	suffix := ""
	if strings.has_suffix(name, "_DOT") {
		name = name[:len(name)-4]
		suffix = "."
	}
	if uppercase {
		strings.write_string(sb, strings.to_upper(name, context.temp_allocator))
	} else {
		strings.write_string(sb, strings.to_lower(name, context.temp_allocator))
	}
	strings.write_string(sb, suffix)
}

write_register :: proc(sb: ^strings.Builder, r: Register, uppercase: bool) {
	hw := reg_hw(r)
	switch reg_class(r) {
	case REG_GPR:  fmt.sbprintf(sb, uppercase ? "R%d" : "r%d", hw)
	case REG_CR:   fmt.sbprintf(sb, uppercase ? "CR%d" : "cr%d", hw & 0x7)
	case REG_SPR:
		switch u16(r) & 0x3FF {
		// BookE / Power ISA base
		case 1:    strings.write_string(sb, uppercase ? "XER"    : "xer")
		case 8:    strings.write_string(sb, uppercase ? "LR"     : "lr")
		case 9:    strings.write_string(sb, uppercase ? "CTR"    : "ctr")
		case 22:   strings.write_string(sb, uppercase ? "DEC"    : "dec")
		case 26:   strings.write_string(sb, uppercase ? "SRR0"   : "srr0")
		case 27:   strings.write_string(sb, uppercase ? "SRR1"   : "srr1")
		case 48:   strings.write_string(sb, uppercase ? "PID"    : "pid")
		case 54:   strings.write_string(sb, uppercase ? "DECAR"  : "decar")
		// BookE debug / exception (Freescale e200)
		case 58:   strings.write_string(sb, uppercase ? "CSRR0"  : "csrr0")
		case 59:   strings.write_string(sb, uppercase ? "CSRR1"  : "csrr1")
		case 61:   strings.write_string(sb, uppercase ? "DEAR"   : "dear")
		case 62:   strings.write_string(sb, uppercase ? "ESR"    : "esr")
		case 63:   strings.write_string(sb, uppercase ? "IVPR"   : "ivpr")
		// e200 SPRGs
		case 272:  strings.write_string(sb, uppercase ? "SPRG0"  : "sprg0")
		case 273:  strings.write_string(sb, uppercase ? "SPRG1"  : "sprg1")
		case 274:  strings.write_string(sb, uppercase ? "SPRG2"  : "sprg2")
		case 275:  strings.write_string(sb, uppercase ? "SPRG3"  : "sprg3")
		case 276:  strings.write_string(sb, uppercase ? "SPRG4"  : "sprg4")
		case 277:  strings.write_string(sb, uppercase ? "SPRG5"  : "sprg5")
		case 278:  strings.write_string(sb, uppercase ? "SPRG6"  : "sprg6")
		case 279:  strings.write_string(sb, uppercase ? "SPRG7"  : "sprg7")
		case 284:  strings.write_string(sb, uppercase ? "TBL"    : "tbl")
		case 285:  strings.write_string(sb, uppercase ? "TBU"    : "tbu")
		case 286:  strings.write_string(sb, uppercase ? "PIR"    : "pir")
		case 287:  strings.write_string(sb, uppercase ? "PVR"    : "pvr")
		// Debug (e200)
		case 304:  strings.write_string(sb, uppercase ? "DBSR"   : "dbsr")
		case 308:  strings.write_string(sb, uppercase ? "DBCR0"  : "dbcr0")
		case 309:  strings.write_string(sb, uppercase ? "DBCR1"  : "dbcr1")
		case 310:  strings.write_string(sb, uppercase ? "DBCR2"  : "dbcr2")
		case 312:  strings.write_string(sb, uppercase ? "IAC1"   : "iac1")
		case 313:  strings.write_string(sb, uppercase ? "IAC2"   : "iac2")
		case 314:  strings.write_string(sb, uppercase ? "IAC3"   : "iac3")
		case 315:  strings.write_string(sb, uppercase ? "IAC4"   : "iac4")
		case 316:  strings.write_string(sb, uppercase ? "DAC1"   : "dac1")
		case 317:  strings.write_string(sb, uppercase ? "DAC2"   : "dac2")
		// Interrupt vectors (BookE)
		case 400:  strings.write_string(sb, uppercase ? "IVOR0"  : "ivor0")
		case 401:  strings.write_string(sb, uppercase ? "IVOR1"  : "ivor1")
		case 402:  strings.write_string(sb, uppercase ? "IVOR2"  : "ivor2")
		case 403:  strings.write_string(sb, uppercase ? "IVOR3"  : "ivor3")
		case 404:  strings.write_string(sb, uppercase ? "IVOR4"  : "ivor4")
		case 405:  strings.write_string(sb, uppercase ? "IVOR5"  : "ivor5")
		case 406:  strings.write_string(sb, uppercase ? "IVOR6"  : "ivor6")
		case 407:  strings.write_string(sb, uppercase ? "IVOR7"  : "ivor7")
		case 408:  strings.write_string(sb, uppercase ? "IVOR8"  : "ivor8")
		case 409:  strings.write_string(sb, uppercase ? "IVOR9"  : "ivor9")
		case 410:  strings.write_string(sb, uppercase ? "IVOR10" : "ivor10")
		case 411:  strings.write_string(sb, uppercase ? "IVOR11" : "ivor11")
		case 412:  strings.write_string(sb, uppercase ? "IVOR12" : "ivor12")
		case 413:  strings.write_string(sb, uppercase ? "IVOR13" : "ivor13")
		case 414:  strings.write_string(sb, uppercase ? "IVOR14" : "ivor14")
		case 415:  strings.write_string(sb, uppercase ? "IVOR15" : "ivor15")
		// L1 cache control
		case 512:  strings.write_string(sb, uppercase ? "SPEFSCR": "spefscr")
		case 515:  strings.write_string(sb, uppercase ? "L1CFG0" : "l1cfg0")
		case 516:  strings.write_string(sb, uppercase ? "L1CFG1" : "l1cfg1")
		case 1008: strings.write_string(sb, uppercase ? "HID0"   : "hid0")
		case 1009: strings.write_string(sb, uppercase ? "HID1"   : "hid1")
		case:      fmt.sbprintf(sb, "%d", u16(r) & 0x3FF)
		}
	case:
		fmt.sbprintf(sb, "?%04x", u16(r))
	}
}

write_operand :: proc(
	sb:              ^strings.Builder,
	op:              ^Operand,
	inst_offset:     u32,
	offset_to_label: ^map[u32]u32,
	label_names:     ^map[u32]string,
	opts:            ^Print_Options,
) {
	#partial switch op.kind {
	case .NONE: // skip
	case .REGISTER:  write_register(sb, op.reg, opts.uppercase)
	case .IMMEDIATE: fmt.sbprintf(sb, "%d", op.immediate)
	case .MEMORY:
		if op.mem.index == NONE {
			fmt.sbprintf(sb, "%d(", op.mem.disp)
			write_register(sb, op.mem.base, opts.uppercase)
			strings.write_string(sb, ")")
		} else {
			write_register(sb, op.mem.base, opts.uppercase)
			strings.write_string(sb, ", ")
			write_register(sb, op.mem.index, opts.uppercase)
		}
	case .RELATIVE:
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
			if op.relative >= 0 {
				fmt.sbprintf(sb, ".+%d", op.relative)
			} else {
				fmt.sbprintf(sb, ".-%d", -op.relative)
			}
		}
	}
}
