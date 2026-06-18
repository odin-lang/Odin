// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86

// =============================================================================
// SECTION: 7. HIGH-PERFORMANCE ENCODER
// =============================================================================
//
// Ultra-fast table-driven x64 instruction encoder with:
// - Zero allocations: user provides all buffers
// - O(1) mnemonic lookup via enum-indexed table
// - O(1) label lookup via array indexing
// - Fully inlined hot path - no function call overhead
// - Trivially parallelizable: encode() is pure, no shared state
//
// API: Single entry point `encode()` that takes:
// - instructions: []Instruction to encode
// - label_defs: []Label_Definition mapping label_id -> instruction_index
// - code: []u8 output buffer for machine code
// - relocs: []Relocation output buffer for relocations
// - errors: []Error output buffer for errors
//
// Returns Result with counts and success status.
// Unresolved labels are returned as relocations (no extern/internal distinction).

import "base:intrinsics"
import "core:fmt"
import "../isa"

// -----------------------------------------------------------------------------
// SECTION: 7.1 Constants
// -----------------------------------------------------------------------------

MAX_INST_SIZE :: 15  // Maximum x64 instruction length


// -----------------------------------------------------------------------------
// SECTION: 7.6 Core Encoding Function
// -----------------------------------------------------------------------------

// encode: The single entry point for x64 instruction encoding.
//
// Parameters:
//   instructions  - Array of instructions to encode
//   label_defs    - Array mapping label_id -> instruction index. MODIFIED IN PLACE
//                   to contain byte offsets after encoding.
//   code          - Output buffer for machine code (must be large enough)
//   relocs        - Dynamic array; unresolved relocations are appended
//   errors        - Dynamic array; encoding errors are appended
//   resolve       - If true, resolve relocations and patch code in place
//   base_address  - Base address for absolute relocations (when resolve=true)
//
// Returns:
//   Result with code size and success status.
//
// After encoding, label_defs[label_id] contains the byte offset of that label.
// Unresolved references (labels not in label_defs) are appended to relocs.
//
encode :: proc(
	instructions: []Instruction,
	label_defs:   []Label_Definition,     // Input: inst index. Modified to byte offset.
	code:         []u8,
	relocs:       ^[dynamic]Relocation,        // Unresolved relocations appended here
	errors:       ^[dynamic]Error, // Errors appended here
	resolve:      bool       = true,
	base_address: u64        = 0,
	mode:         Mode       = ._64,           // i386 vs x86-64 mode
) -> (byte_count: u32, ok: bool) {
	if mode == ._16 {
		// Real-mode encoding is not implemented; the ModRM addressing
		// model differs from protected/long mode and needs a separate
		// emission path. See Mode enum comment in encoding_types.odin.
		fmt.panicf("x64.encode: Mode._16 (real mode) is not yet supported")
	}

	ok = true

	// Temp storage for pending relocations (before resolution)
	pending_relocations: [dynamic]Relocation
	defer delete(pending_relocations)

	// Temp storage for instruction byte offsets
	inst_offsets: [dynamic]u32
	defer delete(inst_offsets)
	resize(&inst_offsets, len(instructions))

	// =========================================================================
	// PASS 1: Encode all instructions, collect relocations
	// =========================================================================

	for &inst, instruction_index in instructions {
		// Record this instruction's byte offset
		inst_offsets[instruction_index] = byte_count

		// Validate operand_count bounds
		if inst.operand_count > 4 {
			append(errors, Error{u32(instruction_index), .INVALID_OPERAND_COUNT, {}})
			ok = false
			continue
		}

		// Check buffer space
		if byte_count + MAX_INST_SIZE > u32(len(code)) {
			append(errors, Error{u32(instruction_index), .BUFFER_OVERFLOW, {}})
			ok = false
			continue
		}

		// i386 operand validation. The following don't exist in 32-bit
		// protected mode and must be rejected up front so we don't
		// silently emit bytes that mean something else (e.g. SPL would
		// encode as AH in 32-bit). Catches legacy AND VEX/EVEX paths.
		if mode == ._32 {
			invalid := false
			for i in 0..<inst.operand_count {
				op := &inst.ops[i]
				#partial switch op.kind {
				case .REGISTER:
					// R8-R15, XMM8-31, YMM8-31, ZMM8-31 require REX/VEX/EVEX extension.
					if reg_needs_rex(op.reg) { invalid = true; break }
					// SPL/BPL/SIL/DIL (REG_GPR8 hw 4-7) don't exist in i386;
					// those encodings decode as AH/CH/DH/BH there. Users
					// wanting high-byte regs should use REG_GPR8H (AH..BH).
					if reg_class(op.reg) == REG_GPR8 {
						hw := reg_hw(op.reg)
						if hw >= 4 && hw <= 7 { invalid = true; break }
					}
				case .MEMORY:
					m := op.mem
					if (mem_has_base(m)  && m.base_ext)  ||
					   (mem_has_index(m) && m.index_ext) {
						invalid = true; break
					}
				}
			}
			if invalid {
				append(errors, Error{u32(instruction_index), .OPERAND_MISMATCH, {}})
				ok = false
				continue
			}
		}

		// Find matching encoding from table (O(1) mnemonic lookup)
		encodings := encoding_forms(inst.mnemonic)
		if len(encodings) == 0 {
			append(errors, Error{u32(instruction_index), .INVALID_MNEMONIC, {}})
			ok = false
			continue
		}

		// Find the first encoding that matches operands
		matched_enc: ^Encoding = nil
		for &e in encodings {
			if encoding_matches_inline(&inst, &e, mode) {
				matched_enc = &e
				break
			}
		}

		if matched_enc == nil {
			append(errors, Error{u32(instruction_index), .NO_MATCHING_ENCODING, {}})
			ok = false
			continue
		}

		// =====================================================================
		// ENCODE INSTRUCTION (fully inlined hot path)
		// =====================================================================

		enc := matched_enc
		out := code[byte_count:]
		pos: u32 = 0

		// --- Legacy Prefixes ---

		// Lock prefix (F0)
		if inst.flags.lock && enc.flags.lock_ok {
			out[pos] = 0xF0
			pos += 1
		}

		// Rep/Repne prefix
		#partial switch inst.flags.rep {
		case .REP:   out[pos] = 0xF3; pos += 1
		case .REPNE: out[pos] = 0xF2; pos += 1
		}

		// Segment override
		if inst.flags.segment != 0 {
			seg_prefix := [8]u8{0, 0x26, 0x2E, 0x36, 0x3E, 0x64, 0x65, 0}
			out[pos] = seg_prefix[inst.flags.segment]
			pos += 1
		}

		// Address size override (67h)
		if inst.flags.addr32 {
			out[pos] = 0x67
			pos += 1
		}

		// --- VEX/EVEX or Legacy Encoding ---

		#partial switch enc.flags.vex_type{
		case .VEX:
			// VEX prefix encoding
			r: u8 = 1; x: u8 = 1; b: u8 = 1
			vvvv: u8 = 0xF; l: u8 = 0; pp: u8 = 0; mmmmm: u8 = 1; w: u8 = 0

			#partial switch enc.flags.esc {
			case ._0F:   mmmmm = 1
			case ._0F38: mmmmm = 2
			case ._0F3A: mmmmm = 3
			}

			switch enc.flags.prefix {
			case 1: pp = 1  // 66
			case 2: pp = 2  // F3
			case 3: pp = 3  // F2
			}

			#partial switch enc.flags.vex_l {
			case .L1: l = 1
			}

			#partial switch enc.flags.vex_w {
			case .W1: w = 1
			}

			// Check operands for REX bits
			for enc_type, i in enc.enc {
				user_op := get_user_op_inline(&inst, enc, i)
				if user_op == nil { continue }

				#partial switch enc_type {
				case .REG:
					if user_op.kind == .REGISTER && reg_needs_rex(user_op.reg) { r = 0 }
				case .MR:
					#partial switch user_op.kind {
					case .REGISTER:
						if reg_needs_rex(user_op.reg) { b = 0 }
					case .MEMORY:
						m := user_op.mem
						if mem_has_base(m)  && m.base_ext  { b = 0 }
						if mem_has_index(m) && m.index_ext { x = 0 }
					}
				case .VVVV:
					if user_op.kind == .REGISTER { vvvv = ~reg_hw(user_op.reg) & 0xF }
				}
			}

			// 2-byte or 3-byte VEX
			if x == 1 && b == 1 && w == 0 && mmmmm == 1 {
				out[pos] = 0xC5
				out[pos+1] = (r << 7) | (vvvv << 3) | (l << 2) | pp
				pos += 2
			} else {
				out[pos] = 0xC4
				out[pos+1] = (r << 7) | (x << 6) | (b << 5) | mmmmm
				out[pos+2] = (w << 7) | (vvvv << 3) | (l << 2) | pp
				pos += 3
			}

		case .EVEX:
			// EVEX prefix encoding (4 bytes)
			r: u8 = 1; x: u8 = 1; b: u8 = 1; rr: u8 = 1
			mm: u8 = 1; w: u8 = 0; vvvv: u8 = 0xF; pp: u8 = 0
			z: u8 = 0; ll: u8 = 0; bb: u8 = 0; vvv: u8 = 1; aaa: u8 = 0

			#partial switch enc.flags.esc {
			case ._0F:   mm = 1
			case ._0F38: mm = 2
			case ._0F3A: mm = 3
			}

			switch enc.flags.prefix {
			case 1: pp = 1
			case 2: pp = 2
			case 3: pp = 3
			}

			#partial switch enc.flags.vex_l {
			case .L1: ll = 1
			case .L2: ll = 2
			}

			#partial switch enc.flags.vex_w {
			case .W1: w = 1
			}

			for i in 0..<4 {
				user_op := get_user_op_inline(&inst, enc, i)
				if user_op == nil { continue }

				#partial switch enc.enc[i] {
				case .REG:
					if user_op.kind == .REGISTER {
						hw := reg_hw(user_op.reg)
						if hw >= 8 { r = 0 }
						if hw >= 16 { rr = 0 }
					}
				case .MR:
					#partial switch user_op.kind {
					case .REGISTER:
						hw := reg_hw(user_op.reg)
						if hw >= 8 { b = 0 }
					case .MEMORY:
						m := user_op.mem
						if mem_has_base(m) && m.base_ext { b = 0 }
						if mem_has_index(m) && m.index_ext { x = 0 }
						if user_op.flags.broadcast != .NONE { bb = 1 }
					}
				case .VVVV:
					if user_op.kind == .REGISTER {
						hw := reg_hw(user_op.reg)
						vvvv = ~hw & 0xF
						if hw >= 16 { vvv = 0 }
					}
				case .AAA:
					if user_op.kind == .REGISTER { aaa = reg_hw(user_op.reg) & 0x7 }
				}
				if user_op.flags.zeroing { z = 1 }
			}

			out[pos] = 0x62
			out[pos+1] = (r << 7) | (x << 6) | (b << 5) | (rr << 4) | mm
			out[pos+2] = (w << 7) | (vvvv << 3) | 0x04 | pp
			out[pos+3] = (z << 7) | (ll << 5) | (bb << 4) | (vvv << 3) | aaa
			pos += 4

		case: // Legacy encoding
			// Operand size override (66h)
			needs_66 := false
			for i in 0..<inst.operand_count {
				if inst.ops[i].kind == .REGISTER && reg_class(inst.ops[i].reg) == REG_GPR16 {
					needs_66 = enc.flags.prefix != 1  // PREFIX_66
					break
				}
			}
			if needs_66 {
				out[pos] = 0x66
				pos += 1
			}

			// Mandatory prefix
			if enc.flags.prefix != 0 && !needs_66 {
				mand_prefix := [4]u8{0, 0x66, 0xF3, 0xF2}
				out[pos] = mand_prefix[enc.flags.prefix]
				pos += 1
			} else if enc.flags.prefix != 0 && enc.flags.prefix != 1 {
				mand_prefix := [4]u8{0, 0x66, 0xF3, 0xF2}
				out[pos] = mand_prefix[enc.flags.prefix]
				pos += 1
			}

			// REX prefix
			rex: u8 = 0
			if enc.flags.force_rex_w { rex |= 0x48 }

			for enc_type, i in enc.enc {
				if enc_type == .NONE { continue }
				user_op := get_user_op_inline(&inst, enc, i)
				if user_op == nil { continue }

				#partial switch enc_type {
				case .REG:
					if user_op.kind == .REGISTER && reg_needs_rex(user_op.reg) { rex |= 0x44 }
				case .MR:
					#partial switch user_op.kind {
					case .REGISTER:
						if reg_needs_rex(user_op.reg) { rex |= 0x41 }
					case .MEMORY:
						m := user_op.mem
						if mem_has_base(m) && m.base_ext { rex |= 0x41 }
						if mem_has_index(m) && m.index_ext { rex |= 0x42 }
					}
				case .OP_R:
					if user_op.kind == .REGISTER && reg_needs_rex(user_op.reg) { rex |= 0x41 }
				}
			}

			// SPL, BPL, SIL, DIL require REX (long mode only).
			if mode == ._64 {
				for i in 0..<inst.operand_count {
					op := &inst.ops[i]
					if op.kind == .REGISTER {
						class := reg_class(op.reg)
						hw := reg_hw(op.reg)
						if class == REG_GPR8 && hw >= 4 && hw <= 7 {
							if rex == 0 { rex = 0x40 }
						}
					}
				}
			}

			// 32-bit mode forbids the REX prefix entirely. If any operand
			// demanded REX bits (R8-R15, SPL/BPL/SIL/DIL, force_rex_w),
			// the instruction is not legal i386.
			if mode == ._32 && rex != 0 {
				append(errors, Error{u32(instruction_index), .OPERAND_MISMATCH, {}})
				ok = false
				continue
			}

			if rex != 0 {
				out[pos] = rex
				pos += 1
			}

			// Escape bytes
			#partial switch enc.flags.esc {
			case ._0F:
				out[pos] = 0x0F
				pos += 1
			case ._0F38:
				out[pos] = 0x0F; out[pos+1] = 0x38
				pos += 2
			case ._0F3A:
				out[pos] = 0x0F; out[pos+1] = 0x3A
				pos += 2
			}
		}

		// --- Opcode ---
		opcode := enc.opcode

		// Handle +rb/+rw/+rd/+ro (register in opcode). For x87 fixed-ModR/M
		// forms (opcodes 0xD8..0xDF with ext >= 0xC0), the .OP_R index goes
		// into the rm field of the fixed ModR/M byte instead of the opcode.
		x87_fixed_modrm := opcode >= 0xD8 && opcode <= 0xDF && enc.ext >= 0xC0
		opr_index: u8 = 0
		opr_seen := false
		for enc_type, i in enc.enc {
			if enc_type == .OP_R {
				user_op := get_user_op_inline(&inst, enc, i)
				if user_op != nil && user_op.kind == .REGISTER {
					opr_index = reg_hw(user_op.reg) & 0x07
					opr_seen  = true
				}
				break
			}
		}
		if opr_seen && !x87_fixed_modrm {
			opcode += opr_index
		}

		out[pos] = opcode
		pos += 1

		// --- ModR/M and SIB ---
		has_modrm := false
		mr_slot:  int = -1
		reg_slot: int = -1

		for enc_type, i in enc.enc {
			#partial switch enc_type {
			case .MR:  mr_slot  = i; has_modrm = true
			case .REG: reg_slot = i; has_modrm = true
			}
		}

		if has_modrm {
			has_sib := false
			mod:               u8  = 0
			reg_field:         u8  = 0
			rm:                u8  = 0
			sib:               u8  = 0
			disp:              i32 = 0
			displacement_size: u8  = 0

			// Reg field
			if enc.flags.modrm_reg_ext {
				reg_field = enc.ext & 0x07
			} else if reg_slot >= 0 {
				reg_op := get_user_op_inline(&inst, enc, reg_slot)
				if reg_op != nil && reg_op.kind == .REGISTER {
					reg_field = reg_hw(reg_op.reg) & 0x07
				}
			}

			// R/M field
			if mr_slot >= 0 {
				mr_op := get_user_op_inline(&inst, enc, mr_slot)
				if mr_op != nil {
					#partial switch mr_op.kind {
					case .REGISTER:
						mod = 0b11
						rm = reg_hw(mr_op.reg) & 0x07
					case .MEMORY:
						m := mr_op.mem

						if mem_is_rip_relative(m) {
							mod = 0b00
							rm = 0b101
							disp = m.disp
							displacement_size = 4
						} else if !mem_has_base(m) && !mem_has_index(m) {
							mod = 0b00
							rm = 0b100
							has_sib = true
							sib = 0b00_100_101
							disp = m.disp
							displacement_size = 4
						} else {
							base_hw := m.base_hw
							has_index := mem_has_index(m)
							disp_value := m.disp

							needs_sib := has_index || (base_hw & 0x07) == 4

							if needs_sib {
								has_sib = true
								rm = 0b100

								scale: u8 = 0
								switch mem_scale(m) {
								case 2: scale = 1
								case 4: scale = 2
								case 8: scale = 3
								}

								idx: u8 = 0b100
								if has_index { idx = m.index_hw & 0x07 }

								base_sib := base_hw & 0x07
								if !mem_has_base(m) { base_sib = 0b101 }

								sib = (scale << 6) | (idx << 3) | base_sib

								if mem_has_base(m) && (base_hw & 0x07) == 5 && disp_value == 0 {
									mod = 0b01; disp = 0; displacement_size = 1
								} else if !mem_has_base(m) {
									mod = 0b00; disp = disp_value; displacement_size = 4
								} else if disp_value == 0 {
									mod = 0b00
								} else if disp_value >= -128 && disp_value <= 127 {
									mod = 0b01; disp = disp_value; displacement_size = 1
								} else {
									mod = 0b10; disp = disp_value; displacement_size = 4
								}
							} else {
								rm = base_hw & 0x07

								if (base_hw & 0x07) == 5 && disp_value == 0 {
									mod = 0b01; disp = 0; displacement_size = 1
								} else if disp_value == 0 {
									mod = 0b00
								} else if disp_value >= -128 && disp_value <= 127 {
									mod = 0b01; disp = disp_value; displacement_size = 1
								} else {
									mod = 0b10; disp = disp_value; displacement_size = 4
								}
							}
						}
					}
				}
			}

			out[pos] = (mod << 6) | (reg_field << 3) | rm
			pos += 1

			if has_sib {
				out[pos] = sib
				pos += 1
			}

			for _ in 0..<displacement_size {
				out[pos] = u8(disp & 0xFF)
				disp >>= 8
				pos += 1
			}
		}

		// Fixed ModR/M for special instructions. Triggered for:
		//   - 0F-escape forms (NOP-class, MONITOR/MWAIT, etc.)
		//   - x87 ST(i) and special control instructions (opcodes 0xD8..0xDF)
		is_x87_opcode := enc.opcode >= 0xD8 && enc.opcode <= 0xDF
		if enc.ext >= 0xC0 && !has_modrm && (enc.flags.esc != .NONE || is_x87_opcode) {
			modrm_byte := enc.ext
			// For x87 ST(i) forms, OR the OP_R register index into the rm field
			if x87_fixed_modrm && opr_seen {
				modrm_byte = (modrm_byte & 0xF8) | opr_index
			}
			out[pos] = modrm_byte
			pos += 1
		}

		// --- Immediates ---
		for enc_type, i in enc.enc {
			#partial switch enc_type {
			case .IB:
				user_op := get_user_op_inline(&inst, enc, i)
				if user_op != nil {
					#partial switch user_op.kind {
					case .IMMEDIATE:
						out[pos] = u8(user_op.immediate)
						pos += 1
					case .RELATIVE:
						// Relative reference - record relocation
						label_id := u32(user_op.relative)
						append(&pending_relocations, Relocation{byte_count + pos, label_id, 0, .REL8, 1, u16(instruction_index)})
						out[pos] = 0
						pos += 1
					}
				}

			case .IW:
				user_op := get_user_op_inline(&inst, enc, i)
				if user_op != nil && user_op.kind == .IMMEDIATE {
					immediate_val := u16(user_op.immediate)
					out[pos] = u8(immediate_val); out[pos+1] = u8(immediate_val >> 8)
					pos += 2
				}

			case .ID:
				user_op := get_user_op_inline(&inst, enc, i)
				if user_op != nil {
					#partial switch user_op.kind {
					case .IMMEDIATE:
						immediate_val := u32(user_op.immediate)
						out[pos] = u8(immediate_val); out[pos+1] = u8(immediate_val >> 8)
						out[pos+2] = u8(immediate_val >> 16); out[pos+3] = u8(immediate_val >> 24)
						pos += 4
					case .RELATIVE:
						label_id := u32(user_op.relative)
						append(&pending_relocations, Relocation{byte_count + pos, label_id, 0, .REL32, 4, u16(instruction_index)})
						out[pos] = 0; out[pos+1] = 0; out[pos+2] = 0; out[pos+3] = 0
						pos += 4
					}
				}

			case .IQ:
				user_op := get_user_op_inline(&inst, enc, i)
				if user_op != nil && user_op.kind == .IMMEDIATE {
					immediate_val := u64(user_op.immediate)
					for j in u32(0)..<8 { out[pos + j] = u8(immediate_val >> (j * 8)) }
					pos += 8
				}
			}
		}

		byte_count += pos
	}

	// =========================================================================
	// PASS 1.5: Convert label_defs from instruction indices to byte offsets
	// =========================================================================

	isa.rewrite_label_defs_to_offsets(label_defs, inst_offsets[:])

	// =========================================================================
	// PASS 2: Resolve relocations (x64 dispatches its types to isa patch primitives)
	// =========================================================================

	for &relocation in pending_relocations {
		label_id := relocation.label_id

		// O(1) label lookup - label_defs now contains byte offsets
		if label_id >= u32(len(label_defs)) || label_defs[label_id] == LABEL_UNDEFINED {
			// Unresolved - append to user's relocs array
			append(relocs, relocation)
			continue
		}

		target_offset := u32(label_defs[label_id])
		patch_offset  := relocation.offset

		if !resolve {
			// User wants all relocations, even resolvable ones
			append(relocs, relocation)
			continue
		}

		#partial switch relocation.type {
		case .REL8:
			// x64 REL8: instruction ends 1 byte after the value field.
			next_pc := patch_offset + 1
			if !patch_pcrel_i8(code, patch_offset, target_offset, next_pc, relocation.addend) {
				append(errors, Error{u32(relocation.inst_idx), .LABEL_OUT_OF_RANGE, {}})
				ok = false
			}

		case .REL32:
			next_pc := patch_offset + 4
			patch_pcrel_i32(code, patch_offset, target_offset, next_pc, relocation.addend)

		case .ABS32:
			patch_abs32(code, patch_offset, target_offset, base_address, relocation.addend)

		case .ABS64:
			patch_abs64(code, patch_offset, target_offset, base_address, relocation.addend)
		}
	}

	return
}

// -----------------------------------------------------------------------------
// SECTION: 7.7 Inline Helper Functions
// -----------------------------------------------------------------------------

// Check if instruction matches encoding (inlined for hot path).
// `mode` lets default_64 entries match 32-bit operands in i386 and
// filters out mode-restricted (mode_32_only) encodings when not in i386.
encoding_matches_inline :: proc "contextless" (inst: ^Instruction, enc: ^Encoding, mode: Mode) -> bool {
	// Mode gate: skip i386-only encodings (short-form INC/DEC at 0x40-0x4F)
	// when not in Mode._32.
	if enc.flags.mode_32_only && mode != ._32 { return false }

	explicit_count := enc.flags.explicit_count

	if !enc.flags.has_implicit {
		if inst.operand_count != explicit_count { return false }
		for i in 0 ..< explicit_count {
			eff := mode_rewrite_op_type(enc.ops[i], mode, enc.flags.default_64)
			operand_matches_inline(&inst.ops[i], eff) or_return
		}
		return true
	}

	// Special case: if user provides exactly one more operand than non-implicit count,
	// check if the extra operand matches an implicit operand (e.g., CL for shifts)
	if inst.operand_count == explicit_count + 1 {
		// Check if the last user operand matches an implicit operand in the encoding
		last_user_op := &inst.ops[inst.operand_count - 1]
		found_matching_implicit := false
		for op_type in enc.ops {
			if op_type == .NONE { break }
			if is_implicit_op_inline(op_type) && implicit_operand_matches(last_user_op, op_type) {
				found_matching_implicit = true
				break
			}
		}
		if !found_matching_implicit { return false }

		// Match the first (operand_count - 1) user operands against non-implicit encoding operands
		user_idx: u8 = 0
		for op_type in enc.ops {
			if op_type == .NONE { break }
			if is_implicit_op_inline(op_type) { continue }

			if user_idx >= inst.operand_count - 1 { return false }
			effective_op_type := mode_rewrite_op_type(op_type, mode, enc.flags.default_64)
			operand_matches_inline(&inst.ops[user_idx], effective_op_type) or_return
			user_idx += 1
		}
		return user_idx == inst.operand_count - 1
	}

	// STandard case: operand count must match non-implicit count
	if inst.operand_count != explicit_count { return false }

	// Match each user operand against non-implicit encoding operands
	user_idx: u8 = 0
	for op_type in enc.ops {
		if op_type == .NONE { break }
		if is_implicit_op_inline(op_type) { continue }

		if user_idx >= inst.operand_count { return false }
		effective_op_type := mode_rewrite_op_type(op_type, mode, enc.flags.default_64)
		operand_matches_inline(&inst.ops[user_idx], effective_op_type) or_return
		user_idx += 1
	}

	return true
}

// Check if a user operand matches an implicit operand type (for explicit implicit operand matching)
implicit_operand_matches :: #force_inline proc "contextless" (op: ^Operand, op_type: Operand_Type) -> bool {
	if op.kind != .REGISTER { return false }
	#partial switch op_type {
	case .CL_IMPL:   return op.reg == CL
	case .DX_IMPL:   return op.reg == DX
	case .ST0_IMPL:  return op.reg == ST0
	case .XMM0_IMPL: return op.reg == XMM0
	// Don't match AL/AX/EAX/RAX_Impl - those are for short-form encodings
	// Don't match One_Impl - can't provide "1" as a register
	}
	return false
}

is_implicit_op_inline :: #force_inline proc "contextless" (op: Operand_Type) -> bool {
	#partial switch op {
	case .AL_IMPL, .AX_IMPL, .EAX_IMPL, .RAX_IMPL,
	     .CL_IMPL, .DX_IMPL, .ONE_IMPL, .ST0_IMPL, .XMM0_IMPL:
		return true
	}
	return false
}

operand_matches_inline :: #force_inline proc "contextless" (op: ^Operand, op_type: Operand_Type) -> bool {
	switch op.kind {
	case .NONE:      return op_type == .NONE
	case .REGISTER:  return reg_matches_inline(op, op_type)
	case .MEMORY:    return mem_matches_inline(op, op_type)
	case .IMMEDIATE: return imm_matches_inline(op, op_type)
	case .RELATIVE:
		// Respect user's size preference: size=1 -> REL8, size=4 -> REL32
		if op.size == 1 { return op_type == .REL8  }
		if op.size == 4 { return op_type == .REL32 }
		// Default: accept either
		return op_type == .REL8 || op_type == .REL32
	}
	return false
}

reg_matches_inline :: #force_inline proc "contextless" (op: ^Operand, op_type: Operand_Type) -> bool {
	class := reg_class(op.reg)
	#partial switch op_type {
	case .R8, .RM8:                           return class == REG_GPR8 || class == REG_GPR8H
	case .R16, .RM16:                         return class == REG_GPR16
	case .R32, .RM32:                         return class == REG_GPR32
	case .R64, .RM64:                         return class == REG_GPR64
	case .XMM, .XMM_M32, .XMM_M64, .XMM_M128: return class == REG_XMM
	case .YMM, .YMM_M256:                     return class == REG_YMM
	case .ZMM, .ZMM_M512:                     return class == REG_ZMM
	case .MM, .MM_M64:                        return class == REG_MM
	case .K, .K_M8, .K_M16, .K_M32, .K_M64:   return class == REG_K
	case .SREG:                               return class == REG_SEG
	case .CR:                                 return class == REG_CR
	case .DR:                                 return class == REG_DR
	case .STI:                                return class == REG_ST
	}
	return false
}

mem_matches_inline :: #force_inline proc "contextless" (op: ^Operand, op_type: Operand_Type) -> bool {
	#partial switch op_type {
	case .M:        return true  // Any size memory
	case .RM8:      return op.size == 1
	case .RM16:     return op.size == 2
	case .RM32:     return op.size == 4
	case .RM64:     return op.size == 8
	case .M8:       return op.size == 1
	case .M16:      return op.size == 2
	case .M32:      return op.size == 4
	case .M64:      return op.size == 8
	case .M80:      return op.size == 10
	case .M128:     return op.size == 16
	case .M256:     return op.size == 32
	case .M512:     return op.size == 64
	case .XMM_M32:  return op.size == 4
	case .XMM_M64, .MM_M64: return op.size == 8
	case .XMM_M128: return op.size == 16
	case .YMM_M256: return op.size == 32
	case .ZMM_M512: return op.size == 64
	case .K_M8:     return op.size == 1
	case .K_M16:    return op.size == 2
	case .K_M32:    return op.size == 4
	case .K_M64:    return op.size == 8
	case .M16_16, .M16_32, .M16_64: return true
	}
	return false
}

imm_matches_inline :: #force_inline proc "contextless" (op: ^Operand, op_type: Operand_Type) -> bool {
	// Match based on whether the VALUE fits in the encoding's immediate size.
	// x64 immediates are interpreted as both signed and unsigned depending on context:
	// - ADD r32, imm8sx: sign-extended, so -1 becomes 0xFFFFFFFF
	// - MOV r32, imm32: can be 0xFFFFFFFF (unsigned) or -1 (signed), same encoding
	// We accept the full range that can be encoded (union of signed and unsigned).
	#partial switch op_type {
	case .IMM8:
		// Full 8-bit range: signed [-128, 127] OR unsigned [0, 255]
		return        -128 <= op.immediate && op.immediate <= 255
	case .IMM8SX:
		// Sign-extended 8-bit: must be in signed 8-bit range
		return        -128 <= op.immediate && op.immediate <= 127
	case .IMM16:
		// Full 16-bit range: signed [-32768, 32767] OR unsigned [0, 65535]
		return      -32768 <= op.immediate && op.immediate <= 65535
	case .IMM32:
		// Full 32-bit range: signed [-2147483648, 2147483647] OR unsigned [0, 4294967295]
		return -2147483648 <= op.immediate && op.immediate <= 4294967295
	case .IMM64:
		return true  // Any i64 value fits
	}
	return false
}

get_user_op_inline :: #force_inline proc "contextless" (inst: ^Instruction, enc: ^Encoding, slot: int) -> ^Operand {
	user_idx := 0
	for op, i in enc.ops {
		if op == .NONE { break }
		if is_implicit_op_inline(op) { continue }
		if i == slot {
			if user_idx < int(inst.operand_count) {
				return &inst.ops[user_idx]
			}
			return nil
		}
		user_idx += 1
	}
	return nil
}

// -----------------------------------------------------------------------------
// SECTION: 7.8 Convenience Functions
// -----------------------------------------------------------------------------

// Compute safe buffer sizes for encoding
encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int {
	return n * MAX_INST_SIZE
}

encode_max_relocation_count :: #force_inline proc "contextless" (n: int) -> int {
	return n  // At most 1 reloc per instruction
}

// -----------------------------------------------------------------------------
// SECTION: 7.10 Dynamic Array Instruction Emitters
// -----------------------------------------------------------------------------

// Instruction emitters
emit_none :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic) {
	append(instructions, inst_none(mnemonic))
}

emit_r :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, r: Register) {
	append(instructions, inst_r(mnemonic, r))
}

emit_rr :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination, source: Register) {
	append(instructions, inst_r_r(mnemonic, destination, source))
}

emit_ri :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination: Register, immediate: i64, immediate_size: u8) {
	append(instructions, inst_r_i(mnemonic, destination, immediate, immediate_size))
}

emit_rm :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination: Register, source: Memory, size: u8) {
	append(instructions, inst_r_m(mnemonic, destination, source, size))
}

emit_mr :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination: Memory, size: u8, source: Register) {
	append(instructions, inst_m_r(mnemonic, destination, size, source))
}

emit_m :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, m: Memory, size: u8) {
	append(instructions, inst_m(mnemonic, m, size))
}

emit_mi :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination: Memory, size: u8, immediate: i64, immediate_size: u8) {
	append(instructions, inst_m_i(mnemonic, destination, size, immediate, immediate_size))
}

emit_rel :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, label_id: u32, size: u8 = 4) {
	append(instructions, inst_rel(mnemonic, label_id, size))
}

emit_rrr :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination, source1, source2: Register) {
	append(instructions, inst_r_r_r(mnemonic, destination, source1, source2))
}

emit_rrm :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination, source1: Register, source2: Memory, size: u8) {
	append(instructions, inst_r_r_m(mnemonic, destination, source1, source2, size))
}

emit_rri :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination, source: Register, immediate: i64, immediate_size: u8) {
	append(instructions, inst_r_r_i(mnemonic, destination, source, immediate, immediate_size))
}

emit_rrrr :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination, source1, source2, source3: Register) {
	append(instructions, inst_r_r_r_r(mnemonic, destination, source1, source2, source3))
}

emit_i :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, immediate: i64, immediate_size: u8) {
	append(instructions, inst_i(mnemonic, immediate, immediate_size))
}

emit_rmi :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination: Register, source: Memory, mem_size: u8, immediate: i64, immediate_size: u8) {
	append(instructions, inst_r_m_i(mnemonic, destination, source, mem_size, immediate, immediate_size))
}

emit_mri :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, destination: Memory, mem_size: u8, source: Register, immediate: i64, immediate_size: u8) {
	append(instructions, inst_m_r_i(mnemonic, destination, mem_size, source, immediate, immediate_size))
}

emit_rel_offset :: #force_inline proc(instructions: ^[dynamic]Instruction, mnemonic: Mnemonic, offset: i64, offset_size: u8) {
	append(instructions, inst_rel_offset(mnemonic, offset, offset_size))
}
