// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mips

import "core:strings"
import "core:reflect"
import "core:os"
import "core:io"
import "core:rexcode/isa"

// =============================================================================
// MIPS PRINTER
// =============================================================================
//
// Classical MIPS assembly syntax: lowercase mnemonics with `.suffix` for
// typed variants (`add.s`, `c.eq.d`, `paddw`), GPRs printed by ABI name
// (`$zero`, `$t0`, `$sp`), FPRs as `$f0..$f31`, and memory operands as
// `disp(base)`.
//
// Architecture-independent scaffolding (Token types, Print_Options sink
// table, hex/decimal number formatting) lives in `isa/print.odin` and is
// re-exported below so consumers only ever import `mips`. The seven sink
// families (sbprint / print / aprint / tprint / bprint / fprint / wprint
// + their `ln` variants) mirror the x86 contract exactly.

// Re-exports.
Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

// ---- ABI register name tables ----------------------------------------------

@(rodata, private="file")
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

// =============================================================================
// Public string accessors
// =============================================================================

// Canonical mnemonic spelling (lowercase, with `_` mapped to `.`).
// The few enum names that carry a disambiguator suffix get a hand mapping.
mnemonic_to_string :: proc(m: Mnemonic, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_mnemonic(&sb, m, !lowercase)
	return strings.to_string(sb)
}

// Canonical register name with leading `$`.
register_name :: proc(r: Register, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_register(&sb, r, !lowercase)
	return strings.to_string(sb)
}

// =============================================================================
// Core: sbprint (everything else is a sink wrapper)
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
		// Local copy so we can take address.
		@(static) defaults := DEFAULT_PRINT_OPTIONS
		opts = &defaults
	}

	// Offset -> label_id index (single linear pass over label_defs).
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

		// Label at this offset?
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
// Internal: token-by-token writers
// =============================================================================

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, uppercase: bool) {
	// Disambiguator-suffix overrides: enum names like DMUL_R6, OP_GTE,
	// MADD_EE carry a disambiguator that should NOT appear in the printed
	// mnemonic (the canonical assembly form is just `dmul`, `op`, `madd`).
	name: string
	#partial switch m {
	case .DMUL_R6:  name = "DMUL"
	case .DDIV_R6:  name = "DDIV"
	case .DDIVU_R6: name = "DDIVU"
	case .OP_GTE:   name = "OP"
	case .SQR_GTE:  name = "SQR"
	case .MADD_EE:  name = "MADD"
	case .MADDU_EE: name = "MADDU"
	case .MSUB_EE:  name = "MSUB"
	case .MSUBU_EE: name = "MSUBU"
	case:
		n, ok := reflect.enum_name_from_value(m)
		if !ok {
			strings.write_string(sb, "<?>")
			return
		}
		name = n
	}
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
	if r == NONE {
		strings.write_string(sb, "<none>")
		return
	}
	cls := reg_class(r)
	hw  := reg_hw(r)

	// HI/LO have no `$` prefix in canonical syntax.
	if cls == REG_HILO {
		switch hw {
		case 0: strings.write_string(sb, uppercase ? "HI"  : "hi")
		case 1: strings.write_string(sb, uppercase ? "LO"  : "lo")
		case 2: strings.write_string(sb, uppercase ? "HI1" : "hi1")
		case 3: strings.write_string(sb, uppercase ? "LO1" : "lo1")
		}
		return
	}

	strings.write_byte(sb, '$')
	switch cls {
	case REG_GPR:
		name := GPR_NAMES_ABI[hw]
		if uppercase {
			for i in 0..<len(name) {
				c := name[i]
				if c >= 'a' && c <= 'z' {
					strings.write_byte(sb, c - 32)
				} else {
					strings.write_byte(sb, c)
				}
			}
		} else {
			strings.write_string(sb, name)
		}
	case REG_FPR:
		strings.write_byte(sb, uppercase ? 'F' : 'f')
		write_decimal_u32(sb, u32(hw))
	case REG_FCR:
		strings.write_string(sb, uppercase ? "FCR" : "fcr")
		write_decimal_u32(sb, u32(hw))
	case REG_MSA:
		strings.write_byte(sb, uppercase ? 'W' : 'w')
		write_decimal_u32(sb, u32(hw))
	case:
		// CP0/CP2D/CP2C/VFPU printed numerically for now.
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
		// Shouldn't appear inside operand_count, but harmless.

	case .REGISTER:
		write_register(sb, op.reg, opts.uppercase)

	case .IMMEDIATE:
		write_signed_decimal(sb, op.immediate)

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
			// No label discovered at this target -- fall back to absolute hex.
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
	for n > 0 {
		buf[i] = '0' + u8(n % 10)
		n /= 10
		i += 1
	}
	for j := i - 1; j >= 0; j -= 1 {
		strings.write_byte(sb, buf[j])
	}
}

@(private="file")
write_signed_decimal :: proc(sb: ^strings.Builder, v: i64) {
	if v < 0 {
		strings.write_byte(sb, '-')
		// Avoid i64.min overflow by going through u64.
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
	for n > 0 {
		buf[i] = '0' + u8(n % 10)
		n /= 10
		i += 1
	}
	for j := i - 1; j >= 0; j -= 1 {
		strings.write_byte(sb, buf[j])
	}
}
