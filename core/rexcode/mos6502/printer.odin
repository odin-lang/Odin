// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

import "core:strings"
import "core:reflect"
import "core:os"
import "core:io"
import "../isa"

// =============================================================================
// MOS 6502 PRINTER
// =============================================================================
//
// Canonical 6502 assembly syntax. The dialect choices here match what
// you'd see in cc65, ca65, da65, and the original MOS manual:
//
//   lda #$12              IMMEDIATE
//   lda $12               ZP
//   lda $12,x             ZP,X
//   lda $1234             ABS
//   lda $1234,x           ABS,X
//   lda ($12,x)           IND_X
//   lda ($12),y           IND_Y
//   lda ($12)             IND_ZP        (65C02)
//   jmp ($1234)           IND
//   jmp ($1234,x)         IND_ABS_X     (65C02)
//   asl a                 A_IMPL
//   bne .L0               REL (label)
//   bbr0 $12, .L0         ZP + REL
//   tii $0000,$2000,$1000 IMM_16 x3     (HuC6280 block xfer)
//
// Mnemonics are lowercased by default. Hex numbers use a leading `$`
// (the canonical 6502 prefix) regardless of Print_Options.hex_prefix,
// because the alternative looks alien in 6502 source.

Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

// -----------------------------------------------------------------------------
// Public string accessors
// -----------------------------------------------------------------------------

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

	offset_to_label: map[u32]u32
	defer delete(offset_to_label)
	for ld, id in label_defs {
		if ld != LABEL_UNDEFINED {
			offset_to_label[u32(ld)] = u32(id)
		}
	}

	for i in 0..<len(instructions) {
		inst := &instructions[i]
		offset: u32 = 0
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
	// SAX_NMOS prints as "sax" in conventional disassembly (the suffix is
	// just our internal disambiguator vs the HuC6280 SAX).
	name: string
	#partial switch m {
	case .SAX_NMOS: name = "SAX"
	case:
		n, ok := reflect.enum_name_from_value(m)
		if !ok { strings.write_string(sb, "<?>"); return }
		name = n
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
		// The only register operand we emit is `A` for accumulator-implied ops.
		strings.write_byte(sb, opts.uppercase ? 'A' : 'a')

	case .IMMEDIATE:
		strings.write_byte(sb, '#')
		write_hex_value(sb, u64(op.immediate), op.size)

	case .MEMORY:
		write_memory(sb, op.mem, opts.uppercase)

	case .RELATIVE:
		target := u32(op.relative)
		if id, has := offset_to_label[target]; has {
			write_label(sb, id, label_names, opts)
		} else {
			// Fall back to absolute hex when the target isn't a known label.
			// Use the operand size to decide width: size=1 -> $XX, size=2 -> $XXXX.
			write_hex_value(sb, u64(target), op.size)
		}
	}
}

@(private="file")
write_memory :: proc(sb: ^strings.Builder, m: Memory, uppercase: bool) {
	// Width of the address literal:
	//   ZP / ZP_X / ZP_Y / IND_X / IND_Y / IND_ZP  ->  $nn   (1 byte)
	//   ABS / ABS_X / ABS_Y / IND / IND_ABS_X      ->  $nnnn (2 bytes)
	is_zp: bool
	switch m.mode {
	case .ZP, .ZP_X, .ZP_Y, .IND_X, .IND_Y, .IND_ZP:
		is_zp = true
	case .ABS, .ABS_X, .ABS_Y, .IND, .IND_ABS_X:
		is_zp = false
	}
	size: u8 = is_zp ? 1 : 2

	X := uppercase ? "X" : "x"
	Y := uppercase ? "Y" : "y"

	switch m.mode {
	case .ZP, .ABS:
		write_hex_value(sb, u64(m.address), size)
	case .ZP_X, .ABS_X:
		write_hex_value(sb, u64(m.address), size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, X)
	case .ZP_Y, .ABS_Y:
		write_hex_value(sb, u64(m.address), size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, Y)
	case .IND:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), size)
		strings.write_byte(sb, ')')
	case .IND_X:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, X)
		strings.write_byte(sb, ')')
	case .IND_Y:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), size)
		strings.write_byte(sb, ')')
		strings.write_byte(sb, ',')
		strings.write_string(sb, Y)
	case .IND_ZP:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), size)
		strings.write_byte(sb, ')')
	case .IND_ABS_X:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, X)
		strings.write_byte(sb, ')')
	}
}

// `$XX` for 1-byte values, `$XXXX` for 2-byte values. The `$` prefix is
// the 6502 convention regardless of Print_Options.hex_prefix.
@(private="file")
write_hex_value :: proc(sb: ^strings.Builder, v: u64, size: u8) {
	strings.write_byte(sb, '$')
	width := int(size) * 2
	if width <= 0 { width = 2 }
	if width > 8  { width = 8 }
	hex := "0123456789abcdef"
	for i := width - 1; i >= 0; i -= 1 {
		nibble := u8((v >> u8(i*4)) & 0xF)
		strings.write_byte(sb, hex[nibble])
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
