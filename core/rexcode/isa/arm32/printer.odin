// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

import "core:strings"
import "core:fmt"
import "core:io"
import "core:os"
import "core:reflect"
import "core:rexcode/isa"

// =============================================================================
// AArch32 PRINTER
// =============================================================================
//
// Canonical UAL syntax:
//
//   ADD{<c>}{S} <Rd>, <Rn>, #<imm>             A32 / T32 data-proc imm
//   ADD{<c>}{S} <Rd>, <Rn>, <Rm>{, <shift>}    A32 / T32 data-proc reg
//   LDR{<c>}    <Rt>, [<Rn>, #±<imm>]          load/store immediate
//   LDR{<c>}    <Rt>, [<Rn>, ±<Rm>{, <shift>}] load/store reg-offset
//   PUSH        {R0, R1, R4-R7, LR}            register list
//   B{<c>}      <label>                        branch
//   VADD.<dt>   <Vd>, <Vn>, <Vm>               VFP/NEON
//
// Mnemonic is uppercased by default (configurable); condition code suffix
// is appended (EQ/NE/...) after the mnemonic when cond != AL.

Token                 :: isa.Token
Token_Kind            :: isa.Token_Kind
Print_Options         :: isa.Print_Options
Print_Result          :: isa.Print_Result
DEFAULT_PRINT_OPTIONS :: isa.DEFAULT_PRINT_OPTIONS

@(rodata, private="file")
COND_SUFFIX := [16]string{
	"eq", "ne", "cs", "cc", "mi", "pl", "vs", "vc",
	"hi", "ls", "ge", "lt", "gt", "le", "",   "",   // 14=AL (no suffix), 15=NV/unconditional
}

@(rodata, private="file")
GPR_NAMES := [16]string{
	"r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7",
	"r8", "r9", "r10", "fp", "ip", "sp", "lr", "pc",
}

@(rodata, private="file")
SHIFT_NAMES := [5]string{"lsl", "lsr", "asr", "ror", "rrx"}

mnemonic_to_string :: proc(m: Mnemonic, lowercase: bool = true, allocator := context.temp_allocator) -> string {
	sb := strings.builder_make(allocator)
	write_mnemonic(&sb, m, 14, false, !lowercase)
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

	// ITSTATE, followed the way the decoder follows it, so that `.w` can be
	// decided for instructions built by hand as well as decoded ones.
	it_state: u8 = 0
	// A VPT block, followed the same way: whether each instruction in it is
	// predicated Then or Else, which the syntax spells on the mnemonic.
	vpt_block: VPT_Block
	vpt_next := 0

	for i in 0..<len(instructions) {
		inst := &instructions[i]
		// The decoder says where a decoded instruction sits; an instruction
		// built by hand is placed by the VPT before it.
		predicate := inst.vector_predicate
		if vpt_next < vpt_block.count {
			if predicate == .NONE { predicate = vpt_block.predicates[vpt_next] }
			vpt_next += 1
		}
		if inst.mnemonic == .VPT || inst.mnemonic == .VPST {
			vpt_block = vpt_block_of(u8(inst.ops[0].immediate))
			vpt_next = 0
		}
		in_it_block := inst.mode == .T32 && (it_state & 0xF != 0 || inst.in_it_block)
		if inst.mnemonic == .IT {
			it_state = u8(inst.ops[0].immediate & 0xF) << 4 | u8(inst.ops[1].immediate & 0xF)
		} else if it_state & 0xF != 0 {
			if it_state & 0x7 == 0 {
				it_state = 0
			} else {
				it_state = (it_state & 0xE0) | ((it_state << 1) & 0x1F)
			}
		}
		offset := u32(i) * 4
		if i < len(inst_info) {
			offset = inst_info[i].offset
		}

		// A displayable label at this offset — a definition, or a caller-named offset
		if isa.label_display_at(&display, offset) {
			isa.label_display_write(&display, sb, offset, opts.label_prefix)
			strings.write_string(sb, ":\n")
		}

		if opts.show_offsets {
			fmt.sbprintf(sb, "%08x:  ", offset)
		}

		if inst.mnemonic == .INVALID {
			strings.write_string(sb, "    .word 0xINVALID\n")
			continue
		}

		strings.write_string(sb, "    ")

		// The `.<dt>` suffix. It is data on the instruction now, so there is
		// nothing to reconstruct: read it straight off. This is also what
		// makes the convert family print correctly -- `vcvt.s32.f32` names
		// both ends, and the old bit-pattern inference only ever produced one.
		dt := inst.dt
		if dt[0] == .NONE && i < len(inst_info) {
			de_idx := int(inst_info[i].decode_entry)
			if de_idx < len(DECODE_ENTRIES) {
				dt = DECODE_ENTRIES[de_idx].dt
			}
		}
		// No fallback beyond this. Guessing a data type from the register
		// bank produced one for every VFP instruction that does not take
		// any -- `vldr.f32`, `vorn.f64` -- and those are not accepted
		// syntax. If a form needs a suffix, the table is where it says so.


		// IT spells its block on the mnemonic -- `itte eq` -- and the
		// condition is its operand, not a suffix.
		if inst.mnemonic == .IT {
			write_it(sb, inst, opts.uppercase)
			strings.write_string(sb, "\n")
			continue
		}

		// VPT and VPST spell their block on the mnemonic, as IT does, and
		// their mask is not written as an operand.
		first_operand := u8(0)
		if inst.mnemonic == .VPT || inst.mnemonic == .VPST {
			write_vpt(sb, inst, opts.uppercase)
			first_operand = 1
		} else {
			write_mnemonic(sb, inst.mnemonic, inst.cond, inst.sets_flags, opts.uppercase)
		}
		switch predicate {
		case .NONE:
		case .THEN: strings.write_byte(sb, opts.uppercase ? 'T' : 't')
		case .ELSE: strings.write_byte(sb, opts.uppercase ? 'E' : 'e')
		}
		if dt[0] != .NONE {
			write_data_type(sb, dt, opts.uppercase)
		}
		// A 32-bit Thumb instruction that a 16-bit form could also encode
		// says so with `.w`; an assembler otherwise picks the narrow one.
		// Where none could, the suffix is left off -- assemblers reject it on
		// some instructions that have no narrow form at all. A condition on
		// anything but a branch also means the instruction is in an IT block.
		//
		// MOV with an immediate is the one 32-bit form that needs `.w` even
		// with nothing narrow in reach: assemblers read `mov r0, #648` as
		// MOVW whenever the value fits sixteen bits.
		if inst.mode == .T32 && inst.length == 4 {
			in_block := in_it_block || (inst.cond != 14 && !is_thumb_conditional_branch(inst))
			mov_immediate := inst.mnemonic == .MOV && inst.ops[1].kind != .REGISTER
			if mov_immediate || has_narrow_encoding(inst, in_block) || is_wide_load_store(inst) {
				strings.write_string(sb, opts.uppercase ? ".W" : ".w")
			}
		}

		if inst.operand_count > first_operand {
			strings.write_string(sb, " ")
			for k in first_operand ..< inst.operand_count {
				if k > first_operand { strings.write_string(sb, ", ") }
				write_operand(sb, &inst.ops[k], inst, offset, &display, opts)
				// LDM/STM write the updated base back, and the syntax marks
				// that with a `!` on the base register itself.
				if k == 0 && inst.writeback && inst.ops[0].kind == .REGISTER { strings.write_byte(sb, '!') }
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
	label_names:  ^isa.Label_Names = nil,
) {
	sbprint(sb, instructions, inst_info, label_defs, tokens, options, label_names)
	strings.write_byte(sb, '\n')
}

// =============================================================================
// Sink wrappers (cross-arch naming contract -- see docs/cross_arch_design.md §6)
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
// Writers
// =============================================================================

// `.i32`, `.s32.f32`, `.8`. Both slots print when the second is set.
// A shift suffix on a register operand. Three spellings, and the enum covers
// all of them: `, lsl #3` for an immediate amount, `, lsl r3` when the count
// comes from a register (Shift_Type.LSL_REG..ROR_REG keep the Rs index in
// shift_amt), and a bare `, rrx`, which takes no amount at all.
//
// SHIFT_NAMES only holds LSL..RRX, so the register-shifted variants have to be
// folded back onto it. Indexing it with the raw enum value ran off the end --
// LSL_REG is 6 against a 5-entry table -- and crashed the printer outright.
// `it`, then a `t` or an `e` for each further instruction in the block, then
// the condition. The block's length is where the mask's lowest set bit is, and
// an instruction is a `t` when its mask bit matches the first condition's
// low bit.
@(private="file")
write_it :: proc(sb: ^strings.Builder, inst: ^Instruction, uppercase: bool) {
	first_condition := u8(inst.ops[0].immediate) & 0xF
	mask := u8(inst.ops[1].immediate) & 0xF
	strings.write_string(sb, uppercase ? "IT" : "it")
	for bit := u8(3); bit > 0 && mask & ((1 << bit) - 1) != 0; bit -= 1 {
		then := (mask >> bit) & 1 == first_condition & 1
		if uppercase {
			strings.write_byte(sb, then ? 'T' : 'E')
		} else {
			strings.write_byte(sb, then ? 't' : 'e')
		}
	}
	strings.write_byte(sb, ' ')
	strings.write_string(sb, first_condition == 14 ? "al" : COND_SUFFIX[first_condition])
}

// VPT and VPST name the block they open by a T or an E per instruction
// after the first. Below the mask's top bit each bit says whether the next
// instruction is predicated the other way from the one before; the lowest set
// bit ends the block.
@(private="file")
write_vpt :: proc(sb: ^strings.Builder, inst: ^Instruction, uppercase: bool) {
	block := vpt_block_of(u8(inst.ops[0].immediate))
	if uppercase {
		strings.write_string(sb, inst.mnemonic == .VPT ? "VPT" : "VPST")
	} else {
		strings.write_string(sb, inst.mnemonic == .VPT ? "vpt" : "vpst")
	}
	// The first is always THEN, and not written.
	for k in 1 ..< block.count {
		then := block.predicates[k] == .THEN
		strings.write_byte(sb, uppercase ? (then ? 'T' : 'E') : (then ? 't' : 'e'))
	}
}



// `apsr_nzcvq`, `cpsr_fc`, `spsr_fsxc`: the mask bits are f, s, x and c from
// the top. APSR is CPSR seen from the application level, and it only has the
// two fields an application can write -- nzcvq (f) and g (s) -- so the CPSR
// forms that fit that are written as APSR.
@(private="file")
write_psr_fields :: proc(sb: ^strings.Builder, hw: u16) {
	mask := hw & 0xF
	if hw & 0x10 == 0 && mask & 0x3 == 0 && mask != 0 {
		strings.write_string(sb, "apsr_")
		if mask & 0x8 != 0 { strings.write_string(sb, "nzcvq") }
		if mask & 0x4 != 0 { strings.write_string(sb, "g") }
		return
	}
	strings.write_string(sb, hw & 0x10 != 0 ? "spsr_" : "cpsr_")
	if mask & 0x8 != 0 { strings.write_byte(sb, 'f') }
	if mask & 0x4 != 0 { strings.write_byte(sb, 's') }
	if mask & 0x2 != 0 { strings.write_byte(sb, 'x') }
	if mask & 0x1 != 0 { strings.write_byte(sb, 'c') }
}

// An M-profile special register by its SYSm number; an MSR to one of the
// APSRs also names the fields it writes.
@(private="file")
write_sysm :: proc(sb: ^strings.Builder, hw: u16) {
	sysm := hw & 0xFF
	name := ""
	switch sysm {
	case 0x00: name = "apsr"
	case 0x01: name = "iapsr"
	case 0x02: name = "eapsr"
	case 0x03: name = "xpsr"
	case 0x05: name = "ipsr"
	case 0x06: name = "epsr"
	case 0x07: name = "iepsr"
	case 0x08: name = "msp"
	case 0x09: name = "psp"
	case 0x0A: name = "msplim"
	case 0x0B: name = "psplim"
	case 0x10: name = "primask"
	case 0x11: name = "basepri"
	case 0x12: name = "basepri_max"
	case 0x13: name = "faultmask"
	case 0x14: name = "control"
	case 0x20: name = "pac_key_p_0"
	case 0x21: name = "pac_key_p_1"
	case 0x22: name = "pac_key_p_2"
	case 0x23: name = "pac_key_p_3"
	case 0x24: name = "pac_key_u_0"
	case 0x25: name = "pac_key_u_1"
	case 0x26: name = "pac_key_u_2"
	case 0x27: name = "pac_key_u_3"
	case 0x88: name = "msp_ns"
	case 0x89: name = "psp_ns"
	case 0x8A: name = "msplim_ns"
	case 0x8B: name = "psplim_ns"
	case 0x90: name = "primask_ns"
	case 0x91: name = "basepri_ns"
	case 0x93: name = "faultmask_ns"
	case 0x94: name = "control_ns"
	case 0x98: name = "sp_ns"
	case 0xA0: name = "pac_key_p_0_ns"
	case 0xA1: name = "pac_key_p_1_ns"
	case 0xA2: name = "pac_key_p_2_ns"
	case 0xA3: name = "pac_key_p_3_ns"
	case 0xA4: name = "pac_key_u_0_ns"
	case 0xA5: name = "pac_key_u_1_ns"
	case 0xA6: name = "pac_key_u_2_ns"
	case 0xA7: name = "pac_key_u_3_ns"
	case:
		// A SYSm the architecture does not name is written as its number.
		fmt.sbprintf(sb, "%d", sysm)
		return
	}
	strings.write_string(sb, name)
	// MSR's mask: nzcvq is 10, g is 01. Only the APSR forms carry one.
	if sysm <= 3 {
		switch (hw >> 8) & 0x3 {
		case 1: strings.write_string(sb, "_g")
		case 2: strings.write_string(sb, "_nzcvq")
		case 3: strings.write_string(sb, "_nzcvqg")
		}
	}
}

// DMB and DSB name their option -- `dmb ish` -- and ISB has the one name, SY.
// The values the architecture leaves unnamed are written as numbers.
@(private="file")
is_coprocessor_transfer :: proc "contextless" (m: Mnemonic) -> bool {
	return m == .LDC || m == .LDCL || m == .LDC2 || m == .LDC2L ||
	       m == .STC || m == .STCL || m == .STC2 || m == .STC2L
}

@(private="file")
barrier_option_name :: proc(mnemonic: Mnemonic, option: i64, m_profile: bool) -> string {
	if mnemonic == .ISB {
		return option == 0xF ? "sy" : ""
	}
	if mnemonic != .DMB && mnemonic != .DSB {
		return ""
	}
	// The load-only barriers are v8-A's; v8-M has none of them.
	if m_profile && (option == 0x1 || option == 0x5 || option == 0x9 || option == 0xD) {
		return ""
	}
	switch option {
	case 0x1: return "oshld"
	case 0x2: return "oshst"
	case 0x3: return "osh"
	case 0x5: return "nshld"
	case 0x6: return "nshst"
	case 0x7: return "nsh"
	case 0x9: return "ishld"
	case 0xA: return "ishst"
	case 0xB: return "ish"
	case 0xD: return "ld"
	case 0xE: return "st"
	case 0xF: return "sy"
	}
	return ""
}

// The loads and stores with a 12-bit offset have 16-bit forms with smaller
// ones, and llvm writes them with `.w` whatever the offset -- and needs it
// where the register is SP or PC, which no 16-bit form takes.
@(private="file")
is_wide_load_store :: proc "contextless" (inst: ^Instruction) -> bool {
	m := inst.mnemonic
	if m != .LDR && m != .LDRB && m != .LDRH && m != .LDRSB && m != .LDRSH && m != .STR && m != .STRB && m != .STRH {
		return false
	}
	address := &inst.ops[1]
	return address.kind == .MEMORY && address.mem.mode == .OFFSET && reg_class(address.mem.index) != REG_GPR &&
	       address.mem.disp >= 0 && address.mem.sign >= 0
}

// A B<c> carries its own condition; every other conditional Thumb
// instruction has it from an IT block.
@(private="file")
is_thumb_conditional_branch :: proc(inst: ^Instruction) -> bool {
	if inst.mnemonic != .B || inst.form_id == 0 {
		return false
	}
	forms := encoding_forms(inst.mnemonic)
	if int(inst.form_id) - 1 >= len(forms) {
		return false
	}
	return forms[inst.form_id - 1].flags.thumb_condition
}

@(private="file")
write_shift :: proc(sb: ^strings.Builder, st: Shift_Type, amt: u8) {
	switch st {
	case .LSL, .LSR, .ASR, .ROR:
		if amt == 0 {
			return
		}
		fmt.sbprintf(sb, ", %s #%d", SHIFT_NAMES[int(st)], amt)
	case .RRX:
		strings.write_string(sb, ", rrx")
	case .NONE:
		// no shift to print
	case .LSL_REG, .LSR_REG, .ASR_REG, .ROR_REG:
		fmt.sbprintf(sb, ", %s %s", SHIFT_NAMES[int(st) - int(Shift_Type.LSL_REG)], GPR_NAMES[amt & 0xF])
	case .UXTW:
		fmt.sbprintf(sb, ", uxtw #%d", amt)
	}
}

@(private="file")
write_data_type :: proc(sb: ^strings.Builder, dt: Data_Types, uppercase: bool) {
	for d in dt {
		if d == .NONE { continue }
		strings.write_byte(sb, '.')
		name := DATA_TYPE_NAMES[d]
		for i in 0 ..< len(name) {
			c := name[i]
			if uppercase && c >= 'a' && c <= 'z' {
				strings.write_byte(sb, c - 'a' + 'A')
			} else {
				strings.write_byte(sb, c)
			}
		}
	}
}

@(rodata, private="file")
DATA_TYPE_NAMES := [Data_Type]string{
	.NONE = "",
	.S8 = "s8", .S16 = "s16", .S32 = "s32", .S64 = "s64",
	.U8 = "u8", .U16 = "u16", .U32 = "u32", .U64 = "u64",
	.I8 = "i8", .I16 = "i16", .I32 = "i32", .I64 = "i64",
	.F16 = "f16", .F32 = "f32", .F64 = "f64",
	.P8 = "p8", .P16 = "p16", .P64 = "p64", .BF16 = "bf16",
	.SZ8 = "8", .SZ16 = "16", .SZ32 = "32", .SZ64 = "64",
}

@(private="file")
write_mnemonic :: proc(sb: ^strings.Builder, m: Mnemonic, cond: u8, sets_flags: bool, uppercase: bool) {
	name, _ := reflect.enum_name_from_value(m)
	// TSB_CSYNC is the only name holding an underscore: assemblers write it
	// as a mnemonic plus an operand token, `tsb csync`, so that underscore is
	// a space. No other mnemonic has one.
	split := -1
	if len(name) > 4 && name[:4] == "TSB_" {
		split = 3
	}
	for i in 0..<len(name) {
		c := name[i]
		if i == split {
			strings.write_byte(sb, ' ')
		} else if !uppercase && c >= 'A' && c <= 'Z' {
			strings.write_byte(sb, c - 'A' + 'a')
		} else {
			strings.write_byte(sb, c)
		}
	}
	if sets_flags {
		strings.write_string(sb, uppercase ? "S" : "s")
	}
	if cond != 14 && cond != 15 {
		strings.write_string(sb, uppercase ? COND_SUFFIX[cond] : COND_SUFFIX[cond])
		// (Both forms identical for cond; we keep the table lowercase and
		// post-process if uppercase requested.)
	}
}

@(private="file")
write_register :: proc(sb: ^strings.Builder, r: Register, uppercase: bool = false) {
	cls := reg_class(r)
	hw  := reg_hw(r)
	switch cls {
	case REG_GPR:
		strings.write_string(sb, GPR_NAMES[hw & 0xF])
	case REG_SPR:
		fmt.sbprintf(sb, "s%d", hw)
	case REG_DPR:
		fmt.sbprintf(sb, "d%d", hw)
	case REG_QPR:
		fmt.sbprintf(sb, "q%d", hw)
	case REG_SREG:
		switch hw {
		case 0: strings.write_string(sb, "apsr")
		case 1: strings.write_string(sb, "cpsr")
		case 2: strings.write_string(sb, "spsr")
		case 3: strings.write_string(sb, "apsr_nzcv")
		case:   fmt.sbprintf(sb, "psr%d", hw)
		}
	case REG_FPSC:
		// The VMRS/VMSR system registers by their reg field.
		switch hw {
		case 0x0: strings.write_string(sb, "fpsid")
		case 0x1: strings.write_string(sb, "fpscr")
		case 0x2: strings.write_string(sb, "fpscr_nzcvqc")
		case 0x5: strings.write_string(sb, "mvfr2")
		case 0x6: strings.write_string(sb, "mvfr1")
		case 0x7: strings.write_string(sb, "mvfr0")
		case 0x8: strings.write_string(sb, "fpexc")
		case 0x9: strings.write_string(sb, "fpinst")
		case 0xA: strings.write_string(sb, "fpinst2")
		case 0xC: strings.write_string(sb, "vpr")
		case 0xD: strings.write_string(sb, "p0")
		case 0xE: strings.write_string(sb, "fpcxtns")
		case 0xF: strings.write_string(sb, "fpcxts")
		case:     fmt.sbprintf(sb, "fpsc%d", hw)
		}
	case REG_COPROC:
		fmt.sbprintf(sb, "c%d", hw)
	case REG_COPROC_NUM:
		fmt.sbprintf(sb, "p%d", hw)
	case REG_ENDIAN:
		strings.write_string(sb, hw == 0 ? "le" : "be")
	case REG_BANKED:
		strings.write_string(sb, banked_name(hw))
	case REG_ZR:
		strings.write_string(sb, "zr")
	case REG_COND:
		strings.write_string(sb, hw == 14 ? "al" : COND_SUFFIX[hw & 0xF])
	case REG_PSR_FIELDS:
		write_psr_fields(sb, hw)
	case REG_SYSM:
		write_sysm(sb, hw)
	case REG_IFLAGS:
		if hw & 4 != 0 { strings.write_byte(sb, 'a') }
		if hw & 2 != 0 { strings.write_byte(sb, 'i') }
		if hw & 1 != 0 { strings.write_byte(sb, 'f') }
		if hw & 7 == 0 { strings.write_string(sb, "none") }
	case:
		fmt.sbprintf(sb, "?%d", hw)
	}
}

@(private="file")
write_operand :: proc(
	sb:               ^strings.Builder,
	op:               ^Operand,
	inst:             ^Instruction,
	offset:           u32,
	display:          ^isa.Label_Display,
	opts:             ^Print_Options,
) {
	switch op.kind {
	case .NONE:
		return
	case .REGISTER:
		// A VFP/NEON list is a contiguous run written in braces, and every
		// register is named -- `{d1, d2, d3}`, not a range.
		if op.list.count > 0 {
			strings.write_string(sb, "{")
			step := u16(max(op.list.stride, 1))
			for n in 0 ..< u16(op.list.count) {
				if n > 0 { strings.write_string(sb, ", ") }
				write_register(sb, Register(reg_class(op.reg) | ((reg_hw(op.reg) + n * step) & 0x1F)))
				// Every member of a single-lane list carries the index:
				// `{d0[1], d1[1]}`. `{d0[]}` is the to-all-lanes form.
				if op.list.all_lanes {
					strings.write_string(sb, "[]")
				} else if op.has_lane {
					fmt.sbprintf(sb, "[%d]", op.lane)
				}
			}
			strings.write_string(sb, "}")
			return
		}
		write_register(sb, op.reg)
		write_shift(sb, op.shift_type, op.shift_amt)
		if op.has_lane {
			fmt.sbprintf(sb, "[%d]", op.lane)
		}
	case .IMMEDIATE:
		if name := barrier_option_name(inst.mnemonic, op.immediate, inst.m_profile); name != "" {
			strings.write_string(sb, name)
			return
		}
		// A coprocessor load or store has no other immediate operand: this
		// is the option it passes the coprocessor in place of an offset.
		if is_coprocessor_transfer(inst.mnemonic) {
			strings.write_byte(sb, '{')
			strings.write_i64(sb, op.immediate)
			strings.write_byte(sb, '}')
			return
		}
		fmt.sbprintf(sb, "#%d", op.immediate)
	case .HEX_IMMEDIATE:
		fmt.sbprintf(sb, "#0x%x", u64(op.immediate))
	case .ROTATED_IMMEDIATE:
		fmt.sbprintf(sb, "#%d, #%d", op.immediate, op.size)
	case .FLOAT_IMMEDIATE:
		fmt.sbprintf(sb, "#%e", f64(transmute(f32)u32(op.immediate)))
	case .MEMORY:
		write_memory(sb, op.mem)
	case .RELATIVE:
		// A decoded target is an absolute offset; name it if a label is there.
		target := u32(op.relative)
		if isa.label_display_at(display, target) {
			isa.label_display_write(display, sb, target, opts.label_prefix)
		} else {
			// raw absolute
			fmt.sbprintf(sb, "0x%x", target)
		}
	case .REG_LIST:
		write_reg_list(sb, u16(op.immediate), inst.mnemonic == .CLRM)
		if op.list.user { strings.write_byte(sb, '^') }
	}
}

@(private="file")
write_memory :: proc(sb: ^strings.Builder, m: Memory) {
	strings.write_string(sb, "[")
	write_register(sb, m.base)
	if m.align != 0 {
		fmt.sbprintf(sb, ":%d", u32(8) << m.align)
	}
	// An immediate-only form leaves index at Register(0), whose class is not
	// REG_GPR -- so the class alone says whether there is an index. Excluding
	// hw 0 as well made r0 unusable as one. MVE's vector offset is a Q one.
	if reg_class(m.index) == REG_GPR || reg_class(m.index) == REG_QPR {
		// Register offset
		switch m.mode {
		case .OFFSET:
			strings.write_string(sb, ", ")
			if m.sign < 0 { strings.write_string(sb, "-") }
			write_register(sb, m.index)
			write_shift(sb, m.shift_type, m.shift_amt)
			strings.write_string(sb, "]")
		case .PRE_INDEX:
			strings.write_string(sb, ", ")
			if m.sign < 0 { strings.write_string(sb, "-") }
			write_register(sb, m.index)
			write_shift(sb, m.shift_type, m.shift_amt)
			strings.write_string(sb, "]!")
		case .POST_INDEX:
			strings.write_string(sb, "], ")
			if m.sign < 0 { strings.write_string(sb, "-") }
			write_register(sb, m.index)
			write_shift(sb, m.shift_type, m.shift_amt)
		case .POST_INCREMENT:
			panic("a post-increment address steps by what it transfers, and has no index register")
		}
	} else {
		// An indexed form writes its displacement even when it is zero: the
		// writeback is the point, and `[r0]` alone is the plain offset form.
		// The U bit also survives a zero displacement, and an assembler needs
		// to see it -- `#-0` and `#0` are different words.
		neg := m.disp == 0 && m.sign < 0 ? "-" : ""
		switch m.mode {
		case .OFFSET:
			if m.disp != 0 || m.sign < 0 {
				fmt.sbprintf(sb, ", #%s%d]", neg, m.disp)
			} else {
				strings.write_string(sb, "]")
			}
		case .PRE_INDEX:  fmt.sbprintf(sb, ", #%s%d]!", neg, m.disp)
		case .POST_INDEX: fmt.sbprintf(sb, "], #%s%d", neg, m.disp)
		case .POST_INCREMENT: strings.write_string(sb, "]!")
		}
	}
}

@(private="file")
// CLRM's list has APSR where bit 15 would be PC, and it ends no range.
write_reg_list :: proc(sb: ^strings.Builder, mask: u16, apsr_last := false) {
	strings.write_string(sb, "{")
	first := true
	range_start: int = -1
	last := apsr_last ? 14 : 15
	for b in 0 ..= last {
		bit := mask & (1 << u32(b)) != 0
		next_bit := b < last && mask & (1 << u32(b + 1)) != 0
		if bit && range_start < 0 { range_start = b }
		if bit && !next_bit {
			if !first { strings.write_string(sb, ", ") }
			first = false
			if range_start == b {
				strings.write_string(sb, GPR_NAMES[b])
			} else {
				fmt.sbprintf(sb, "%s-%s", GPR_NAMES[range_start], GPR_NAMES[b])
			}
			range_start = -1
		}
	}
	if apsr_last && mask & 0x8000 != 0 {
		if !first { strings.write_string(sb, ", ") }
		strings.write_string(sb, "apsr")
	}
	strings.write_string(sb, "}")
}
