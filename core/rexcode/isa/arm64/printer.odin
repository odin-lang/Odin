// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

import "core:strings"
import "core:reflect"
import "core:os"
import "core:io"
import "core:rexcode/isa"

// =============================================================================
// AArch64 PRINTER
// =============================================================================
//
// Canonical Arm assembly syntax:
//
//   add  x0, x1, x2                 (R-type)
//   add  x0, x1, #16                (imm)
//   add  x0, x1, x2, lsl #3         (shifted register)
//   add  x0, x1, w2, sxtw #2        (extended register)
//   ldr  x0, [x1, #8]               (offset)
//   ldr  x0, [x1, #-8]!             (pre-index)
//   ldr  x0, [x1], #8               (post-index)
//   ldr  x0, [x1, x2, lsl #3]       (register offset)
//   ldr  x0, [x1, w2, sxtw #2]      (extended-register offset)
//   b    .L0                        (relative)
//   b.eq .L0                        (B.cond with condition suffix)
//   cbz  x0, .L0
//   tbz  x0, #5, .L0
//   fadd d0, d1, d2                 (FP scalar)
//   fmov w0, s0                     (cross-class FMOV)
//
// FP mnemonics: the enum names already include the dot via the underscore-
// to-dot rule (FADD_S -> fadd.s). For the canonical assembly form we want
// no dot inside .S/.D (it's just `fadd s0, s0, s0`) -- the operand types
// disambiguate. So the printer special-cases the FP mnemonics.

Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

@(rodata, private="file")
COND_NAMES := [16]string{
	"eq", "ne", "cs", "cc", "mi", "pl", "vs", "vc",
	"hi", "ls", "ge", "lt", "gt", "le", "al", "nv",
}

@(rodata, private="file")
SHIFT_NAMES := [4]string{ "lsl", "lsr", "asr", "ror" }

@(rodata, private="file")
EXTEND_NAMES := [8]string{
	"uxtb", "uxth", "uxtw", "uxtx",
	"sxtb", "sxth", "sxtw", "sxtx",
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
	label_names:  ^isa.Label_Names = nil,
) {
	opts := options
	if opts == nil {
		@(static) defaults := DEFAULT_PRINT_OPTIONS
		opts = &defaults
	}

	// Display-side label naming: numbers in ADDRESS order (independent of the internal ids'
	// allocation order), caller names keyed by byte offset (isa.Label_Display).
	display: isa.Label_Display
	isa.label_display_init(&display, label_defs, label_names)
	defer isa.label_display_destroy(&display)

	for i in 0..<len(instructions) {
		inst := &instructions[i]
		offset := u32(i) * 4
		if i < len(inst_info) {
			offset = inst_info[i].offset
		}

		// A displayable label at this offset — a definition, or a caller-named offset?
		if isa.label_display_at(&display, offset) {
			isa.label_display_write(&display, sb, offset, opts.label_prefix)
			strings.write_byte(sb, ':')
			strings.write_string(sb, opts.separator)
		}

		strings.write_string(sb, opts.indent)
		if opts.show_offsets {
			isa.print_hex(sb, u64(offset), opts)
			strings.write_string(sb, ": ")
		}

		write_full_mnemonic(sb, inst, opts.uppercase)


		// MOVZ/MOVN/MOVK store the shift as an hw index (0..3 = LSL #0/16/32/48),
		// which assemblers write as `lsl #16` and omit entirely when it is zero.
		mov_wide := inst.mnemonic == .MOVZ || inst.mnemonic == .MOVN || inst.mnemonic == .MOVK
		end_slot := int(inst.operand_count)
		if mov_wide && end_slot == 3 && inst.ops[2].kind == .IMMEDIATE && inst.ops[2].immediate == 0 {
			end_slot = 2
		}

		if end_slot > 0 {
			strings.write_byte(sb, ' ')
			for slot in 0..<end_slot {
				op := &inst.ops[slot]
				// A lane index belongs to the register before it, so it is
				// written `[3]` with no separator rather than as an operand.
				lane_index := op.kind == .IMMEDIATE && op.size == LANE_INDEX
				if slot > 0 && !lane_index {
					strings.write_byte(sb, ',')
					if opts.space_after_comma { strings.write_byte(sb, ' ') }
				}
				// A register the syntax writes as a list keeps its braces, and
				// names every register in the run.
				list := op.kind == .REGISTER && op.list_count > 0
				switch {
				case lane_index:
					strings.write_byte(sb, '[')
					write_decimal_u32(sb, u32(op.immediate))
					strings.write_byte(sb, ']')
				case mov_wide && slot == 2:
					strings.write_string(sb, opts.uppercase ? "LSL #" : "lsl #")
					write_decimal_u32(sb, u32(op.immediate) * 16)
				case list:
					strings.write_byte(sb, '{')
					if opts.space_after_comma { strings.write_byte(sb, ' ') }
					for n in 0 ..< op.list_count {
						if n > 0 {
							strings.write_byte(sb, ',')
							if opts.space_after_comma { strings.write_byte(sb, ' ') }
						}
						// The run is consecutive and wraps at v31.
						member := op^
						member.reg = Register(reg_class(op.reg) | u16((reg_hw(op.reg) + n) & 0x1F))
						write_operand(sb, &member, &display, opts)
					}
					if opts.space_after_comma { strings.write_byte(sb, ' ') }
					strings.write_byte(sb, '}')
				case:
					write_operand(sb, op, &display, opts)
				}
			}
			// CMLE/CMLT/FCMLE/FCMLT only ever compare against zero, and the
			// zero is part of the syntax rather than an encoded operand -- an
			// assembler will not take the instruction without it.
			if inst.mnemonic == .CMLE || inst.mnemonic == .CMLT {
				strings.write_string(sb, opts.space_after_comma ? ", #0" : ",#0")
			} else if inst.mnemonic == .FCMLE || inst.mnemonic == .FCMLT {
				strings.write_string(sb, opts.space_after_comma ? ", #0.0" : ",#0.0")
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
	label_names:  ^isa.Label_Names = nil,
) {
	sbprint(sb, instructions, inst_info, label_defs, tokens, options, label_names)
	strings.write_byte(sb, '\n')
}

// =============================================================================
// Sink wrappers
// =============================================================================

print :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(os.stdout, strings.to_string(sb))
}

println :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(os.stdout, strings.to_string(sb))
}

aprint :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

aprintln :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
	allocator := context.allocator,
) -> string {
	sb := strings.builder_make(allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

tprint :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

tprintln :: proc(
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

bprint :: proc(
	buf: []u8,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) -> string {
	sb := strings.builder_from_bytes(buf)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

bprintln :: proc(
	buf: []u8,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) -> string {
	sb := strings.builder_from_bytes(buf)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	return strings.to_string(sb)
}

fprint :: proc(
	fd: ^os.File,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(fd, strings.to_string(sb))
}

fprintln :: proc(
	fd: ^os.File,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	os.write_string(fd, strings.to_string(sb))
}

wprint :: proc(
	w: io.Writer,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	io.write_string(w, strings.to_string(sb))
}

wprintln :: proc(
	w: io.Writer,
	instructions: []Instruction, inst_info: []Instruction_Info, label_defs: []Label_Definition,
	tokens: ^[dynamic]Token = nil, options: ^Print_Options = nil, label_names: ^isa.Label_Names = nil,
) {
	sb := strings.builder_make(context.temp_allocator)
	sbprintln(&sb, instructions, inst_info, label_defs, tokens, options, label_names)
	io.write_string(w, strings.to_string(sb))
}

// =============================================================================
// Internal writers
// =============================================================================

// Every mnemonic now prints straight from its name -- the conditional
// branches carry their condition in the name (B_LE -> `b.le`), so there is
// no operand to fold in.
@(private="file")
write_full_mnemonic :: proc(sb: ^strings.Builder, inst: ^Instruction, uppercase: bool) {
	write_mnemonic(sb, inst.mnemonic, uppercase)
}

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, uppercase: bool) {
	name, ok := reflect.enum_name_from_value(m)
	if !ok { strings.write_string(sb, "<?>"); return }

	// Enum names are the assembler mnemonics, so this is a straight
	// transliteration -- with one exception. The system instructions below
	// are written by assemblers as a mnemonic plus an op-name token
	// (`dc zva`, `tlbi vae1`, `bti j`), which we store as one enum member,
	// so for those the first underscore prints as a space. Every other
	// underscore is kept: AMX_LDX is an undocumented Apple coprocessor op
	// with no assembler spelling at all, and printing it `amx ldx` would
	// imply a two-token syntax that does not exist.
	split, sep := -1, byte(' ')
	for prefix in ([]string{"DC_", "IC_", "AT_", "TLBI_", "BTI_", "PSB_", "TSB_"}) {
		if len(name) > len(prefix) && name[:len(prefix)] == prefix {
			split = len(prefix) - 1
			break
		}
	}
	// Conditional branches spell the separator as a dot: B_LE -> `b.le`.
	// BC_ is checked first, since it also starts with B.
	if split < 0 {
		for prefix in ([]string{"BC_", "B_"}) {
			if len(name) > len(prefix) && name[:len(prefix)] == prefix {
				split, sep = len(prefix) - 1, '.'
				break
			}
		}
	}

	for i in 0..<len(name) {
		c := name[i]
		if i == split {
			strings.write_byte(sb, sep)
		} else if !uppercase && c >= 'A' && c <= 'Z' {
			strings.write_byte(sb, c + 32)
		} else {
			strings.write_byte(sb, c)
		}
	}
}

// NEON arrangement (`.4s`), element view (`.d`) or SVE element width (`.s`)
// suffix. Vector operands carry the shape in op.size using the codes
// op_v_*/op_z_* produce and the decoder restores (see operands.odin);
// arrangements are multiples of 8, element views are odd, and the neutral 4
// that every scalar class uses prints nothing.
//
// A lane index arrives as its own immediate operand carrying the LANE_INDEX
// marker; the operand loop glues it to the register it indexes (`v0.s[2]`)
// instead of writing it as a separate `#2`.
// A system register by name (`cntvct_el0`), falling back to the raw field
// when it is not one we know.
@(private="file")
write_sysreg :: proc(sb: ^strings.Builder, sr: System_Register, uppercase: bool) {
	name, ok := sysreg_name(sr)
	if !ok {
		strings.write_byte(sb, '#')
		write_signed_decimal(sb, i64(sr))
		return
	}
	for i in 0 ..< len(name) {
		c := name[i]
		if uppercase && c >= 'a' && c <= 'z' {
			strings.write_byte(sb, c - 'a' + 'A')
		} else {
			strings.write_byte(sb, c)
		}
	}
}

// ZERO's tile list: the largest tiles that exactly cover the mask, biggest
// first, so a mask of every bit reads `{za}` rather than eight .d tiles.
@(private="file")
write_za_tile_mask :: proc(sb: ^strings.Builder, mask: u8, opts: ^Print_Options) {
	strings.write_byte(sb, '{')
	rest  := mask
	first := true
	emit :: proc(sb: ^strings.Builder, first: ^bool, opts: ^Print_Options, n: int, suffix: string) {
		if !first^ {
			strings.write_byte(sb, ',')
			if opts.space_after_comma { strings.write_byte(sb, ' ') }
		}
		first^ = false
		strings.write_string(sb, opts.uppercase ? "ZA" : "za")
		write_decimal_u32(sb, u32(n))
		if suffix != "" {
			strings.write_byte(sb, '.')
			strings.write_string(sb, suffix)
		}
	}
	if rest == 0xFF {
		strings.write_string(sb, opts.uppercase ? "ZA" : "za")
		strings.write_byte(sb, '}')
		return
	}
	for n in 0 ..< 2 {
		bit := u8(0x55) << u8(n)
		if rest & bit == bit { emit(sb, &first, opts, n, opts.uppercase ? "H" : "h"); rest &~= bit }
	}
	for n in 0 ..< 4 {
		bit := u8(0x11) << u8(n)
		if rest & bit == bit { emit(sb, &first, opts, n, opts.uppercase ? "S" : "s"); rest &~= bit }
	}
	for n in 0 ..< 8 {
		bit := u8(1) << u8(n)
		if rest & bit == bit { emit(sb, &first, opts, n, opts.uppercase ? "D" : "d"); rest &~= bit }
	}
	strings.write_byte(sb, '}')
}

@(private="file")
write_lowercase :: proc(sb: ^strings.Builder, s: string, uppercase: bool) {
	for i in 0 ..< len(s) {
		c := s[i]
		if uppercase && c >= 'a' && c <= 'z' {
			strings.write_byte(sb, c - 'a' + 'A')
		} else {
			strings.write_byte(sb, c)
		}
	}
}

@(private="file")
write_vector_shape :: proc(sb: ^strings.Builder, r: Register, size: u8, uppercase: bool) {
	shape := ""
	sep := byte('.')
	switch reg_class(r) {
	case REG_V:
		switch size {
		case 8:  shape = "8b"
		case 16: shape = "16b"
		case 24: shape = "4h"
		case 32: shape = "8h"
		case 40: shape = "2s"
		case 48: shape = "4s"
		case 56: shape = "1d"
		case 64: shape = "2d"
		case 72: shape = "1q"
		case 1:  shape = "b"
		case 3:  shape = "h"
		case 5:  shape = "s"
		case 7:  shape = "d"
		}
	case REG_Z, REG_ZA:
		switch size {
		case 1:  shape = "b"
		case 2:  shape = "h"
		case 4:  shape = "s"
		case 8:  shape = "d"
		case 16: shape = "q"
		}
	// A predicate's suffix is its governing qualifier, and it hangs off a
	// slash rather than a dot.
	case REG_P, REG_PN:
		switch size {
		case PQUAL_ZERO:  sep = '/'; shape = "z"
		case PQUAL_MERGE: sep = '/'; shape = "m"
		case PSHAPE_B:    shape = "b"
		case PSHAPE_H:    shape = "h"
		case PSHAPE_S:    shape = "s"
		case PSHAPE_D:    shape = "d"
		}
	}
	if shape == "" {
		return
	}
	strings.write_byte(sb, sep)
	for i in 0..<len(shape) {
		c := shape[i]
		if uppercase && c >= 'a' && c <= 'z' {
			strings.write_byte(sb, c - 32)
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

	// SP and ZR have named forms; the rest are letter+number.
	switch cls {
	case REG_XSP:
		strings.write_string(sb, uppercase ? "SP" : "sp")
		return
	case REG_WSP:
		strings.write_string(sb, uppercase ? "WSP" : "wsp")
		return
	case REG_X:
		if hw == 31 {
			strings.write_string(sb, uppercase ? "XZR" : "xzr")
			return
		}
		strings.write_byte(sb, uppercase ? 'X' : 'x')
		write_decimal_u32(sb, u32(hw))
	case REG_W:
		if hw == 31 {
			strings.write_string(sb, uppercase ? "WZR" : "wzr")
			return
		}
		strings.write_byte(sb, uppercase ? 'W' : 'w')
		write_decimal_u32(sb, u32(hw))
	case REG_B:
		strings.write_byte(sb, uppercase ? 'B' : 'b')
		write_decimal_u32(sb, u32(hw))
	case REG_H:
		strings.write_byte(sb, uppercase ? 'H' : 'h')
		write_decimal_u32(sb, u32(hw))
	case REG_S:
		strings.write_byte(sb, uppercase ? 'S' : 's')
		write_decimal_u32(sb, u32(hw))
	case REG_D:
		strings.write_byte(sb, uppercase ? 'D' : 'd')
		write_decimal_u32(sb, u32(hw))
	case REG_Q:
		strings.write_byte(sb, uppercase ? 'Q' : 'q')
		write_decimal_u32(sb, u32(hw))
	case REG_V:
		strings.write_byte(sb, uppercase ? 'V' : 'v')
		write_decimal_u32(sb, u32(hw))
	case REG_Z:
		strings.write_byte(sb, uppercase ? 'Z' : 'z')
		write_decimal_u32(sb, u32(hw))
	case REG_P:
		strings.write_byte(sb, uppercase ? 'P' : 'p')
		write_decimal_u32(sb, u32(hw))
	case REG_PN:
		strings.write_string(sb, uppercase ? "PN" : "pn")
		write_decimal_u32(sb, u32(hw))
	case REG_ZT:
		strings.write_string(sb, uppercase ? "ZT" : "zt")
		write_decimal_u32(sb, u32(hw))
	case REG_ZA:
		strings.write_string(sb, uppercase ? "ZA" : "za")
		write_decimal_u32(sb, u32(hw))
	}
}

@(private="file")
write_operand :: proc(
	sb:      ^strings.Builder,
	op:      ^Operand,
	display: ^isa.Label_Display,
	opts:    ^Print_Options,
) {
	switch op.kind {
	case .NONE:

	case .REGISTER:
		write_register(sb, op.reg, opts.uppercase)
		write_vector_shape(sb, op.reg, op.size, opts.uppercase)

	case .IMMEDIATE:
		// An SVE element-count pattern has a name, and its multiplier is
		// written `mul #N` rather than as a bare immediate.
		if op.size == SVE_PATTERN_IMM {
			name := SVE_PATTERN_NAMES[op.immediate & 0x1F]
			if name != "" {
				write_lowercase(sb, name, opts.uppercase)
				return
			}
		} else if op.size == ZA_TILE_MASK {
			write_za_tile_mask(sb, u8(op.immediate), opts)
			return
		} else if op.size == SVE_MUL_IMM {
			strings.write_string(sb, opts.uppercase ? "MUL #" : "mul #")
			write_signed_decimal(sb, op.immediate)
			return
		}
		strings.write_byte(sb, '#')
		write_signed_decimal(sb, op.immediate)

	case .SYSTEM_REGISTER:
		write_sysreg(sb, op.sysreg, opts.uppercase)

	case .ZA_SLICE:
		// `za0h.b[w12, 0]`, or plain `za[w12, 0]` for a whole array vector
		strings.write_string(sb, opts.uppercase ? "ZA" : "za")
		if op.za.elem != 0 {
			write_decimal_u32(sb, u32(op.za.tile))
			strings.write_byte(sb, op.za.vertical ? (opts.uppercase ? 'V' : 'v') : (opts.uppercase ? 'H' : 'h'))
			write_vector_shape(sb, Register(REG_Z), op.za.elem, opts.uppercase)
		}
		strings.write_byte(sb, '[')
		strings.write_string(sb, opts.uppercase ? "W" : "w")
		write_decimal_u32(sb, 12 + u32(op.za.ws))
		strings.write_string(sb, opts.space_after_comma ? ", " : ",")
		write_decimal_u32(sb, u32(op.za.offset))
		strings.write_byte(sb, ']')

	case .COND:
		c := op.cond & 0xF
		s := COND_NAMES[c]
		if opts.uppercase {
			for i in 0..<len(s) {
				ch := s[i]
				if ch >= 'a' && ch <= 'z' { strings.write_byte(sb, ch - 32) } else { strings.write_byte(sb, ch) }
			}
		} else {
			strings.write_string(sb, s)
		}

	case .SHIFTED_REG:
		write_register(sb, op.shifted.reg, opts.uppercase)
		if op.shifted.amount != 0 || op.shifted.type != .LSL {
			if opts.space_after_comma {
				strings.write_string(sb, ", ")
			} else {
				strings.write_byte(sb, ',')
			}
			strings.write_string(sb, SHIFT_NAMES[u8(op.shifted.type) & 0x3])
			strings.write_string(sb, " #")
			write_decimal_u32(sb, u32(op.shifted.amount))
		}

	case .EXTENDED_REG:
		write_register(sb, op.extended.reg, opts.uppercase)
		if opts.space_after_comma {
			strings.write_string(sb, ", ")
		} else {
			strings.write_byte(sb, ',')
		}
		strings.write_string(sb, EXTEND_NAMES[u8(op.extended.extend) & 0x7])
		if op.extended.amount != 0 {
			strings.write_string(sb, " #")
			write_decimal_u32(sb, u32(op.extended.amount))
		}

	case .MEMORY:
		write_memory(sb, op.mem, op.size, opts)

	case .RELATIVE:
		target := u32(op.relative)
		if isa.label_display_at(display, target) {
			isa.label_display_write(display, sb, target, opts.label_prefix)
		} else {
			isa.print_hex(sb, u64(target), opts)
		}
	}
}

@(private="file")
// `index_shape` names the element size of a vector index (SVE gather), which
// Memory has no room left to carry; it is 0 for every ordinary addressing mode.
write_memory :: proc(sb: ^strings.Builder, m: Memory, index_shape: u8, opts: ^Print_Options) {
	strings.write_byte(sb, '[')
	write_register(sb, m.base, opts.uppercase)

	switch m.mode {
	case .OFFSET:
		if m.disp != 0 {
			if opts.space_after_comma {
				strings.write_string(sb, ", #")
			} else {
				strings.write_string(sb, ",#")
			}
			write_signed_decimal(sb, i64(m.disp))
		}
		strings.write_byte(sb, ']')

	case .PRE_INDEXED:
		if opts.space_after_comma {
			strings.write_string(sb, ", #")
		} else {
			strings.write_string(sb, ",#")
		}
		write_signed_decimal(sb, i64(m.disp))
		strings.write_string(sb, "]!")

	case .POST_INDEXED:
		strings.write_string(sb, "], #")
		write_signed_decimal(sb, i64(m.disp))

	case .REG_OFFSET:
		strings.write_string(sb, ", ")
		write_register(sb, m.index, opts.uppercase)
		if reg_class(m.index) == REG_Z {
			write_vector_shape(sb, m.index, index_shape, opts.uppercase)
		}
		if m.shift != 0 {
			strings.write_string(sb, ", lsl #")
			write_decimal_u32(sb, u32(m.shift))
		}
		strings.write_byte(sb, ']')

	case .EXT_REG_OFFSET:
		strings.write_string(sb, ", ")
		write_register(sb, m.index, opts.uppercase)
		if reg_class(m.index) == REG_Z {
			write_vector_shape(sb, m.index, index_shape, opts.uppercase)
		}
		strings.write_string(sb, ", ")
		strings.write_string(sb, EXTEND_NAMES[u8(m.extend) & 0x7])
		if m.shift != 0 {
			strings.write_string(sb, " #")
			write_decimal_u32(sb, u32(m.shift))
		}
		strings.write_byte(sb, ']')

	case .LITERAL:
		strings.write_byte(sb, ']')   // shouldn't normally appear
	}
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
