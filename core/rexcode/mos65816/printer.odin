// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos65816

import "core:strings"
import "core:reflect"
import "core:os"
import "core:io"
import "../isa"

// =============================================================================
// W65C816S PRINTER
// =============================================================================
//
// 65816 assembly idiom: lowercase mnemonics, `$XX`/`$XXXX`/`$XXXXXX` hex
// with `$` prefix, addressing-mode-specific bracket syntax:
//
//   lda #$12              -- 8-bit immediate
//   lda #$1234            -- 16-bit immediate (M=0)
//   lda $12               -- direct page
//   lda $12,X             -- direct page, X
//   lda ($12,X)           -- DP indirect, X
//   lda ($12)             -- DP indirect
//   lda ($12),Y           -- DP indirect, Y
//   lda [$12]             -- DP indirect long
//   lda [$12],Y           -- DP indirect long, Y
//   lda $1234             -- absolute
//   lda $1234,X           -- absolute, X
//   lda $123456           -- long
//   lda $123456,X         -- long, X
//   lda $12,S             -- stack relative
//   lda ($12,S),Y         -- stack relative indirect, Y
//   jmp ($1234)           -- absolute indirect (JMP only)
//   jml [$1234]           -- long absolute indirect (JML only)
//   jsr ($1234,X)         -- absolute indexed indirect
//   mvn #$00, #$7E        -- block move (src bank, dst bank)
//   bra .L0               -- relative
//   brl .L0               -- 16-bit relative

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

		// MVN/MVP prints as `mvn #$src, #$dst` -- both bank operands hex.
		is_block_move := inst.mnemonic == .MVN || inst.mnemonic == .MVP

		if inst.operand_count > 0 {
			strings.write_byte(sb, ' ')
			for slot in 0..<int(inst.operand_count) {
				if slot > 0 {
					strings.write_byte(sb, ',')
					if opts.space_after_comma {
						strings.write_byte(sb, ' ')
					}
				}
				if is_block_move {
					strings.write_byte(sb, '#')
					write_hex_value(sb, u64(inst.ops[slot].immediate), 1)
				} else {
					write_operand(sb, &inst.ops[slot], offset_to_label, label_names, opts)
				}
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
			write_hex_value(sb, u64(target), op.size)
		}
	}
}

@(private="file")
write_memory :: proc(sb: ^strings.Builder, m: Memory, uppercase: bool) {
	// Width of the address literal per mode.
	addr_size: u8
	switch m.mode {
	case .DP, .DP_X, .DP_Y, .DP_IND, .DP_IND_X, .DP_IND_Y,
		 .DP_IND_LONG, .DP_IND_LONG_Y, .SR, .SR_IND_Y:
		addr_size = 1
	case .ABS, .ABS_X, .ABS_Y, .ABS_IND, .ABS_IND_LONG, .ABS_IND_X:
		addr_size = 2
	case .LONG, .LONG_X:
		addr_size = 3
	}

	X := uppercase ? "X" : "x"
	Y := uppercase ? "Y" : "y"
	S := uppercase ? "S" : "s"

	switch m.mode {
	case .DP, .ABS, .LONG:
		write_hex_value(sb, u64(m.address), addr_size)

	case .DP_X, .ABS_X, .LONG_X:
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, X)

	case .DP_Y, .ABS_Y:
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, Y)

	case .DP_IND, .ABS_IND:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ')')

	case .DP_IND_X, .ABS_IND_X:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, X)
		strings.write_byte(sb, ')')

	case .DP_IND_Y:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ')')
		strings.write_byte(sb, ',')
		strings.write_string(sb, Y)

	case .DP_IND_LONG, .ABS_IND_LONG:
		strings.write_byte(sb, '[')
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ']')

	case .DP_IND_LONG_Y:
		strings.write_byte(sb, '[')
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ']')
		strings.write_byte(sb, ',')
		strings.write_string(sb, Y)

	case .SR:
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, S)

	case .SR_IND_Y:
		strings.write_byte(sb, '(')
		write_hex_value(sb, u64(m.address), addr_size)
		strings.write_byte(sb, ',')
		strings.write_string(sb, S)
		strings.write_byte(sb, ')')
		strings.write_byte(sb, ',')
		strings.write_string(sb, Y)
	}
}

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
