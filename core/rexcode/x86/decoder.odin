// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86

import "core:fmt"
import "../isa"

// =============================================================================
// SECTION: 8. DECODER
// =============================================================================
//
// High-performance table-driven x64 instruction decoder.
// Design goals:
//   - O(1) opcode lookups via precomputed tables
//   - Zero allocations (caller provides output buffer)
//   - Cache-friendly: hot tables fit in L1 (~5KB)
//   - Target: 400+ MB/s decode throughput

// -----------------------------------------------------------------------------
// 8.1 Instruction Info (per-instruction metadata)
// -----------------------------------------------------------------------------

// Instruction_Info captures extra metadata produced during decoding that isn't
// part of the core Instruction struct. For batch decoding, this is stored
// in a parallel array at the same index as the corresponding Instruction.
Instruction_Info :: struct {
	offset:   u32,      // Byte offset from start of decoded region

	// Prefix info
	rex:      u8,       // REX byte (0 if none)
	has_lock: bool,
	rep:      Rep,      // Rep prefix (uses same enum as Instruction_Flags)
	segment:  Register, // Segment override (NONE if none)

	// VEX/EVEX info
	vex_type: VEX_Type,
	vex_l:    VEX_L,
	vex_w:    VEX_W,
	evex_b:   bool,     // EVEX broadcast
	evex_z:   bool,     // EVEX zeroing
	opmask:   u8,       // EVEX opmask register (k0-k7)
}



// -----------------------------------------------------------------------------
// 8.2 Decoder State
// -----------------------------------------------------------------------------

Decoder_State :: struct {
	data:       []u8,       // Input bytes
	position:   int,        // Current position
	mode:       Mode,       // CPU mode (._64 = long mode, ._32 = i386)

	// Decoded prefix state
	rex:        u8,
	prefix_66:  bool,
	prefix_f2:  bool,
	prefix_f3:  bool,
	prefix_67:  bool,       // Address size override
	segment:    Register,
	has_lock:   bool,

	// +r opcode encoding
	opcode_reg: u8,         // Register encoded in low 3 bits of opcode

	// VEX/EVEX state
	vex_type:   VEX_Type,
	vex_r:      bool,       // VEX.R (inverted)
	vex_x:      bool,       // VEX.X (inverted)
	vex_b:      bool,       // VEX.B (inverted)
	vex_w:      bool,       // VEX.W
	vex_l:      u8,         // VEX.L (0, 1, or 2 for EVEX)
	vex_vvvv:   u8,         // VEX.vvvv register
	vex_pp:     u8,         // VEX.pp (implied prefix)
	vex_mmmmm:  u8,         // VEX.mmmmm (implied escape)

	// EVEX specific
	evex_r2:    bool,       // EVEX.R'
	evex_v2:    bool,       // EVEX.V'
	evex_z:     bool,       // EVEX.z (zeroing)
	evex_b:     bool,       // EVEX.b (broadcast/rc/sae)
	evex_aaa:   u8,         // EVEX.aaa (opmask)
}


// -----------------------------------------------------------------------------
// 8.3 Prefix Decoding
// -----------------------------------------------------------------------------

// Prefix type lookup table for O(1) prefix identification
// 0 = not a prefix, 1 = LOCK (F0), 2 = F2 (REPNE), 3 = F3 (REP)
// 4 = segment ES, 5 = segment CS, 6 = segment SS, 7 = segment DS
// 8 = segment FS, 9 = segment GS, 10 = 0x66, 11 = 0x67
// 12 = REX (0x40-0x4F), 13 = VEX2 (C5), 14 = VEX3 (C4), 15 = EVEX (62)
@(private="file", rodata)
PREFIX_TYPE_TABLE := [256]u8{
	0x26 = 4,   // ES
	0x2E = 5,   // CS
	0x36 = 6,   // SS
	0x3E = 7,   // DS
	0x40 = 12, 0x41 = 12, 0x42 = 12, 0x43 = 12,  // REX
	0x44 = 12, 0x45 = 12, 0x46 = 12, 0x47 = 12,
	0x48 = 12, 0x49 = 12, 0x4A = 12, 0x4B = 12,
	0x4C = 12, 0x4D = 12, 0x4E = 12, 0x4F = 12,
	0x62 = 15,  // EVEX
	0x64 = 8,   // FS
	0x65 = 9,   // GS
	0x66 = 10,  // Operand size
	0x67 = 11,  // Address size
	0xC4 = 14,  // VEX 3-byte
	0xC5 = 13,  // VEX 2-byte
	0xF0 = 1,   // LOCK
	0xF2 = 2,   // REPNE
	0xF3 = 3,   // REP
}

// Segment register lookup for prefix types 4-9
@(rodata)
PREFIX_SEGMENT_TABLE := [6]Register{ES, CS, SS, DS, FS, GS}

decode_prefixes :: #force_inline proc(state: ^Decoder_State) -> Error_Code {
	data := state.data
	pos := state.position
	data_length := len(data)

	for prefix_count := 0; pos < data_length && prefix_count < 15; prefix_count += 1 {
		b := data[pos]
		ptype := PREFIX_TYPE_TABLE[b]

		switch ptype {
		case 0:
			// Not a prefix, done
			state.position = pos
			return .NONE
		case 1:
			state.has_lock = true
			pos += 1
		case 2:
			state.prefix_f2 = true
			pos += 1
		case 3:
			state.prefix_f3 = true
			pos += 1
		case 4..=9:
			state.segment = PREFIX_SEGMENT_TABLE[ptype - 4]
			pos += 1
		case 10:
			state.prefix_66 = true
			pos += 1
		case 11:
			state.prefix_67 = true
			pos += 1
		case 12:
			if state.mode == ._32 {
				// In i386, bytes 0x40-0x4F are short-form INC/DEC opcodes,
				// not REX prefixes. End the prefix-decoding loop here so
				// the opcode dispatcher picks them up.
				state.position = pos
				return .NONE
			}
			state.rex = b
			pos += 1
		case 13:
			state.position = pos
			return decode_vex2(state)
		case 14:
			state.position = pos
			return decode_vex3(state)
		case 15:
			state.position = pos
			return decode_evex(state)
		}
	}

	state.position = pos
	return pos < data_length ? .NONE : .TOO_MANY_PREFIXES
}

// -----------------------------------------------------------------------------
// 8.4 VEX/EVEX Prefix Decoding
// -----------------------------------------------------------------------------

decode_vex2 :: #force_inline proc(state: ^Decoder_State) -> Error_Code {
	if state.position + 2 > len(state.data) {
		return .BUFFER_TOO_SHORT
	}

	b1 := state.data[state.position + 1]
	state.position += 2

	state.vex_type  = .VEX
	state.vex_r     = (b1 & 0x80) == 0  // true = extend (bit was 0)
	state.vex_x     = false             // Implied 1 in 2-byte VEX = no extend
	state.vex_b     = false             // Implied 1 in 2-byte VEX = no extend
	state.vex_vvvv  = (b1 >> 3) & 0x0F
	state.vex_l     = (b1 >> 2) & 0x01
	state.vex_pp    =  b1 & 0x03
	state.vex_mmmmm = 1                 // Implied 0F escape
	state.vex_w     = false             // Implied 0 in 2-byte VEX

	return .NONE
}

decode_vex3 :: #force_inline proc(state: ^Decoder_State) -> Error_Code {
	if state.position + 3 > len(state.data) {
		return .BUFFER_TOO_SHORT
	}

	data := state.data
	pos  := state.position
	b1   := data[pos + 1]
	b2   := data[pos + 2]
	state.position = pos + 3

	state.vex_type  = .VEX
	state.vex_r     = (b1 & 0x80) == 0      // Inverted
	state.vex_x     = (b1 & 0x40) == 0      // Inverted
	state.vex_b     = (b1 & 0x20) == 0      // Inverted
	state.vex_mmmmm =  b1 & 0x1F
	state.vex_w     = (b2 & 0x80) != 0
	state.vex_vvvv  = (b2 >> 3) & 0x0F
	state.vex_l     = (b2 >> 2) & 0x01
	state.vex_pp    = b2 & 0x03

	return .NONE
}

decode_evex :: #force_inline proc(state: ^Decoder_State) -> Error_Code {
	if state.position + 4 > len(state.data) {
		return .BUFFER_TOO_SHORT
	}

	data := state.data
	pos := state.position
	b1 := data[pos + 1]
	b2 := data[pos + 2]
	b3 := data[pos + 3]
	state.position = pos + 4

	state.vex_type = .EVEX
	// Byte 1: R, X, B, R', 0, 0, m, m
	state.vex_r     = (b1 & 0x80) == 0   // Inverted
	state.vex_x     = (b1 & 0x40) == 0   // Inverted
	state.vex_b     = (b1 & 0x20) == 0   // Inverted
	state.evex_r2   = (b1 & 0x10) == 0   // Inverted (R')
	state.vex_mmmmm =  b1 & 0x03
	// Byte 2: W, v, v, v, v, 1, p, p
	state.vex_w    = (b2 & 0x80) != 0
	state.vex_vvvv = (b2 >> 3) & 0x0F
	state.vex_pp   = b2 & 0x03
	// Byte 3: z, L', L, b, V', a, a, a
	state.evex_z   = (b3 & 0x80) != 0
	state.vex_l    = ((b3 >> 5) & 0x03)  // L'L combined
	state.evex_b   = (b3 & 0x10) != 0
	state.evex_v2  = (b3 & 0x08) == 0    // Inverted (V')
	state.evex_aaa = b3 & 0x07

	return .NONE
}

// -----------------------------------------------------------------------------
// 8.5 Opcode Decoding
// -----------------------------------------------------------------------------

decode_opcode :: proc(state: ^Decoder_State) -> (entry: ^Decode_Entry, vex_entry: ^VEX_Decode_Entry, err: Error_Code) {
	if state.position >= len(state.data) {
		return nil, nil, .BUFFER_TOO_SHORT
	}

	// Handle VEX/EVEX encoded instructions
	if state.vex_type != nil {
		return decode_opcode_vex(state)
	}

	// Legacy instruction decoding
	opcode := state.data[state.position]
	state.position += 1

	esc := Escape.NONE

	// Check for escape sequences
	if opcode == 0x0F {
		if state.position >= len(state.data) {
			return nil, nil, .BUFFER_TOO_SHORT
		}
		opcode = state.data[state.position]
		state.position += 1

		if opcode == 0x38 {
			if state.position >= len(state.data) {
				return nil, nil, .BUFFER_TOO_SHORT
			}
			opcode = state.data[state.position]
			state.position += 1
			esc = ._0F38
		} else if opcode == 0x3A {
			if state.position >= len(state.data) {
				return nil, nil, .BUFFER_TOO_SHORT
			}
			opcode = state.data[state.position]
			state.position += 1
			esc = ._0F3A
		} else {
			esc = ._0F
		}
	}

	// Determine mandatory prefix
	// For legacy (no escape), 0x66 is operand size override, not mandatory prefix
	// For 0F/0F38/0F3A, 0x66 can be mandatory prefix - try with prefix first, fallback to no prefix
	prefix: u8 = 0
	if state.prefix_66 { prefix = 1 }
	else if state.prefix_f3 { prefix = 2 }
	else if state.prefix_f2 { prefix = 3 }

	// Look up in index table
	idx: Decode_Index
	switch esc {
	case .NONE:
		// For legacy instructions, 0x66 is operand size override, use prefix=0
		idx = didx(DECODE_INDEX_LEGACY, 0, opcode)
	case ._0F:
		idx = didx(DECODE_INDEX_ESC_0F, prefix, opcode)
		// If not found with 66 prefix, try without (66 is operand size override)
		if idx.count == 0 && prefix == 1 {
			idx = didx(DECODE_INDEX_ESC_0F, 0, opcode)
		}
	case ._0F38:
		idx = didx(DECODE_INDEX_ESC_0F38, prefix, opcode)
		if idx.count == 0 && prefix == 1 {
			idx = didx(DECODE_INDEX_ESC_0F38, 0, opcode)
		}
	case ._0F3A:
		idx = didx(DECODE_INDEX_ESC_0F3A, prefix, opcode)
		if idx.count == 0 && prefix == 1 {
			idx = didx(DECODE_INDEX_ESC_0F3A, 0, opcode)
		}
	}

	// If not found, try +r encoding (opcode with register in low 3 bits)
	if idx.count == 0 && esc == .NONE {
		base_opcode := opcode & 0xF8  // Mask off low 3 bits
		idx = didx(DECODE_INDEX_LEGACY, prefix, base_opcode)

		// Check if this is actually an Op_R encoding
		if idx.count > 0 {
			first := &LEGACY_DECODE_ENTRIES[idx.start]
			if first.enc[0] == .OP_R {
				// Store the register number for later operand decoding
				state.opcode_reg = opcode & 0x07

				// For Op_R with multiple entries (e.g., PUSH/POP with R64 and R16),
				// select based on prefix_66 and default_64 flag
				if idx.count > 1 {
					for i in 0..<int(idx.count) {
						e := &LEGACY_DECODE_ENTRIES[int(idx.start) + i]
						op0 := e.ops[0]

						if state.prefix_66 {
							if op0 == .R16 {
								return e, nil, .NONE
							}
						} else {
							is_64 := state.mode == ._64 && (e.flags.default_64 || (state.rex & 0x08 != 0))
							if is_64 && op0 == .R64 {
								return e, nil, .NONE
							}
							if !is_64 && op0 == .R32 {
								return e, nil, .NONE
							}
							// i386: default_64 entries are the "default operand size" form,
							// which is 32-bit; bytes encode the same as long-mode R64+default_64.
							if state.mode == ._32 && op0 == .R64 && e.flags.default_64 {
								return e, nil, .NONE
							}
						}
					}
				}
				return first, nil, .NONE
			}
		}
		return nil, nil, .INVALID_OPCODE
	}

	if idx.count == 0 {
		return nil, nil, .INVALID_OPCODE
	}

	// Check if this is a +r encoding (register in low 3 bits of opcode)
	// This needs to be checked BEFORE the ModR/M disambiguation
	first_entry := &LEGACY_DECODE_ENTRIES[idx.start]
	uses_op_r := false
	for enc in first_entry.enc {
		if enc == .OP_R {
			uses_op_r = true
			break
		}
	}
	if uses_op_r {
		state.opcode_reg = opcode & 0x07
		// For NOP (0x90), if opcode_reg == 0, check if there's a NOP entry
		if opcode == 0x90 && state.opcode_reg == 0 {
			// Look for NOP entry (no operands)
			for i in 0..<int(idx.count) {
				e := &LEGACY_DECODE_ENTRIES[int(idx.start) + i]
				if e.mnemonic == .NOP {
					return e, nil, .NONE
				}
			}
		}

		// For Op_R with multiple entries (e.g., PUSH/POP with R64 and R16 variants),
		// we need to select based on prefix_66 and default_64 flag
		if idx.count > 1 {
			// In 64-bit mode: default_64=true means 64-bit without REX.W
			// prefix_66 means 16-bit
			for i in 0..<int(idx.count) {
				e := &LEGACY_DECODE_ENTRIES[int(idx.start) + i]
				op0 := e.ops[0]

				if state.prefix_66 {
					// 16-bit operand requested
					if op0 == .R16 {
						return e, nil, .NONE
					}
				} else {
					// No prefix - check if default_64 or REX.W
					is_64 := state.mode == ._64 && (e.flags.default_64 || (state.rex & 0x08 != 0))
					if is_64 && op0 == .R64 {
						return e, nil, .NONE
					}
					if !is_64 && op0 == .R32 {
						return e, nil, .NONE
					}
					// i386: default_64 entries are the "default operand size" form (32-bit).
					if state.mode == ._32 && op0 == .R64 && e.flags.default_64 {
						return e, nil, .NONE
					}
				}
			}
		}
		return first_entry, nil, .NONE
	}

	// If there's a ModR/M extension, we need to peek at it
	if idx.count > 1 {
		// Multiple entries - need to disambiguate by ModR/M.reg field and operand size
		// Peek at ModR/M byte (don't consume it yet)
		if state.position >= len(state.data) {
			return nil, nil, .BUFFER_TOO_SHORT
		}
		modrm := state.data[state.position]
		modrm_reg := (modrm >> 3) & 0x07

		// Determine target operand size based on prefixes
		// REX.W -> 64-bit, 0x66 -> 16-bit, default -> 32-bit
		target_size: Operand_Type = .RM32  // default
		if state.rex & 0x08 != 0 {  // REX.W
			target_size = .RM64
		} else if state.prefix_66 {
			target_size = .RM16
		}

		// Search for matching entry based on extension field AND operand size
		for i in 0..<int(idx.count) {
			e := &LEGACY_DECODE_ENTRIES[int(idx.start) + i]

			// Check if extension matches (or entry doesn't use extension)
			ext_matches := e.ext == 0xFF || e.ext == modrm_reg
			if !ext_matches { continue }

			// Check if operand size matches
			op0 := e.ops[0]
			size_matches := false

			#partial switch target_size {
			case .RM64:
				size_matches = op0 == .RM64 || op0 == .R64 || op0 == .RAX_IMPL
			case .RM16:
				size_matches = op0 == .RM16 || op0 == .R16 || op0 == .AX_IMPL
			case .RM32:
				size_matches = op0 == .RM32 || op0 == .R32 || op0 == .EAX_IMPL
			}

			if size_matches {
				return e, nil, .NONE
			}
		}

		// Fall back to first entry with matching extension
		for i in 0..<int(idx.count) {
			e := &LEGACY_DECODE_ENTRIES[int(idx.start) + i]
			if e.ext == 0xFF || e.ext == modrm_reg {
				return e, nil, .NONE
			}
		}

		return &LEGACY_DECODE_ENTRIES[idx.start], nil, .NONE
	}

	return &LEGACY_DECODE_ENTRIES[idx.start], nil, .NONE
}

decode_opcode_vex :: #force_inline proc(state: ^Decoder_State) -> (entry: ^Decode_Entry, vex_entry: ^VEX_Decode_Entry, err: Error_Code) {
	if state.position >= len(state.data) {
		return nil, nil, .BUFFER_TOO_SHORT
	}

	opcode := state.data[state.position]
	state.position += 1

	// Determine escape index from VEX.mmmmm (1=0F, 2=0F38, 3=0F3A -> 0, 1, 2)
	esc_idx := state.vex_mmmmm - 1
	if esc_idx > 2 {
		return nil, nil, .INVALID_VEX
	}

	// Determine prefix from VEX.pp (0=none, 1=66, 2=F3, 3=F2)
	prefix := state.vex_pp

	// Use indexed lookup for O(1) opcode resolution
	idx: Decode_Index
	entries: []VEX_Decode_Entry

	if state.vex_type == .EVEX {
		switch esc_idx {
		case 0: idx = didx(EVEX_INDEX_0F, prefix, opcode)
		case 1: idx = didx(EVEX_INDEX_0F38, prefix, opcode)
		case 2: idx = didx(EVEX_INDEX_0F3A, prefix, opcode)
		}
		entries = EVEX_DECODE_ENTRIES[:]
	} else {
		switch esc_idx {
		case 0: idx = didx(VEX_INDEX_0F, prefix, opcode)
		case 1: idx = didx(VEX_INDEX_0F38, prefix, opcode)
		case 2: idx = didx(VEX_INDEX_0F3A, prefix, opcode)
		}
		entries = VEX_DECODE_ENTRIES[:]
	}

	if idx.count == 0 {
		return nil, nil, .INVALID_OPCODE
	}

	// Search within the indexed range for VEX.W and VEX.L match
	for i in 0..<int(idx.count) {
		e := &entries[int(idx.start) + i]

		// Check VEX.W constraint
		w_match := e.vex_w == .WIG ||
				   (e.vex_w == .W0 && !state.vex_w) ||
				   (e.vex_w == .W1 && state.vex_w)
		if !w_match { continue }

		// Check VEX.L constraint
		l_match := e.vex_l == .LIG ||
				   (e.vex_l == .L0 && state.vex_l == 0) ||
				   (e.vex_l == .L1 && state.vex_l == 1) ||
				   (e.vex_l == .L2 && state.vex_l == 2)
		if !l_match { continue }

		return nil, e, .NONE
	}

	return nil, nil, .INVALID_OPCODE
}

// -----------------------------------------------------------------------------
// 8.6 Operand Decoding
// -----------------------------------------------------------------------------

decode_operands :: proc(state: ^Decoder_State, entry: ^Decode_Entry) -> (inst: Instruction, err: Error_Code) {
	inst.mnemonic = entry.mnemonic

	modrm: u8 = 0
	modrm_info: ModRM_Info
	sib: u8 = 0
	sib_info: SIB_Info
	has_sib := false

	needs_modrm := entry.flags.needs_modrm

	if needs_modrm {
		if state.position >= len(state.data) {
			return {}, .BUFFER_TOO_SHORT
		}
		modrm = state.data[state.position]
		state.position += 1
		modrm_info = MODRM_TABLE[modrm]

		// Check for ModR/M reg extension match
		if entry.ext != 0xFF {
			if modrm_info.reg != entry.ext {
				return {}, .INVALID_MODRM
			}
		}

		// Parse SIB if needed
		if modrm_info.has_sib {
			if state.position >= len(state.data) {
				return {}, .BUFFER_TOO_SHORT
			}
			sib = state.data[state.position]
			state.position += 1
			sib_info = SIB_TABLE[sib]
			has_sib = true
		}
	}

	// Decode each operand
	op_count := entry.flags.op_count
	for i in 0..<op_count {
		op_enc := entry.enc[i]

		// i386: default_64 entries have R64/RM64 operand types but
		// really mean R32/RM32 in 32-bit mode (same encoded bytes).
		effective := mode_rewrite_op_type(entry.ops[i], state.mode, entry.flags.default_64)
		inst.ops[i] = decode_single_operand(state, effective, op_enc, modrm_info, sib_info, has_sib) or_return
	}
	inst.operand_count += op_count

	return
}

decode_operands_vex :: proc(state: ^Decoder_State, entry: ^VEX_Decode_Entry) -> (inst: Instruction, err: Error_Code) {
	inst.mnemonic = entry.mnemonic

	// VEX instructions always have ModR/M
	if state.position >= len(state.data) {
		return {}, .BUFFER_TOO_SHORT
	}
	modrm := state.data[state.position]
	state.position += 1
	modrm_info := MODRM_TABLE[modrm]

	sib: u8 = 0
	sib_info: SIB_Info
	has_sib := false

	if modrm_info.has_sib {
		if state.position >= len(state.data) {
			return {}, .BUFFER_TOO_SHORT
		}
		sib = state.data[state.position]
		state.position += 1
		sib_info = SIB_TABLE[sib]
		has_sib = true
	}

	// Decode each operand
	for op_type, i in entry.ops {
		if op_type == .NONE {
			break
		}
		op_enc := entry.enc[i]

		inst.ops[i] = decode_single_operand_vex(state, op_type, op_enc, modrm_info, sib_info, has_sib) or_return
		inst.operand_count += 1
	}

	return
}

decode_single_operand :: proc(state: ^Decoder_State, op_type: Operand_Type, op_enc: Operand_Encoding,
                              modrm_info: ModRM_Info, sib_info: SIB_Info, has_sib: bool) -> (op: Operand, err: Error_Code) {

	switch op_enc {
	case .NONE:
		return

	case .REG:
		// Register encoded in ModR/M.reg
		register_number := modrm_info.reg
		if state.rex & 0x04 != 0 {  // REX.R
			register_number += 8
		}
		reg := decode_register(register_number, op_type, state.rex)
		op = op_reg(reg)
		return

	case .MR:
		// Register or memory in ModR/M.rm
		if modrm_info.mod == 3 {
			// Register
			register_number := modrm_info.rm
			if state.rex & 0x01 != 0 {  // REX.B
				register_number += 8
			}
			reg := decode_register(register_number, op_type, state.rex)
			op = op_reg(reg)
			return
		} else {
			// Memory
			return decode_memory_operand(state, modrm_info, sib_info, has_sib, op_type)
		}

	case .IB:
		// 8-bit immediate or rel8
		if state.position >= len(state.data) {
			err = .BUFFER_TOO_SHORT
			return
		}
		immediate_value := i64(i8(state.data[state.position]))
		state.position += 1
		op = Operand{kind = (op_type == .REL8 ? .RELATIVE : .IMMEDIATE), relative = immediate_value, size = 1}
		return

	case .IW:
		// 16-bit immediate
		if state.position + 2 > len(state.data) {
			err = .BUFFER_TOO_SHORT
			return
		}
		immediate_value := i64(i16(u16(state.data[state.position]) | u16(state.data[state.position+1]) << 8))
		state.position += 2
		op = Operand{kind = .IMMEDIATE, immediate = immediate_value, size = 2}
		return

	case .ID:
		// 32-bit immediate or rel32
		if state.position + 4 > len(state.data) {
			err = .BUFFER_TOO_SHORT
			return
		}
		immediate_value := i64(i32(u32(state.data[state.position]) |
					   u32(state.data[state.position+1]) << 8 |
					   u32(state.data[state.position+2]) << 16 |
					   u32(state.data[state.position+3]) << 24))
		state.position += 4
		op = Operand{kind = (op_type == .REL32 ? .RELATIVE : .IMMEDIATE), relative = immediate_value, size = 4}
		return

	case .IQ:
		// 64-bit immediate
		if state.position + 8 > len(state.data) {
			err = .BUFFER_TOO_SHORT
			return
		}
		immediate_value := i64(u64(state.data[state.position]) |
				   u64(state.data[state.position+1]) << 8 |
				   u64(state.data[state.position+2]) << 16 |
				   u64(state.data[state.position+3]) << 24 |
				   u64(state.data[state.position+4]) << 32 |
				   u64(state.data[state.position+5]) << 40 |
				   u64(state.data[state.position+6]) << 48 |
				   u64(state.data[state.position+7]) << 56)
		state.position += 8
		op = Operand{kind = .IMMEDIATE, immediate = immediate_value, size = 8}
		return

	case .IMPL:
		// Implicit register - decode from operand type
		return decode_implicit_operand(op_type), .NONE

	case .OP_R:
		// Register encoded in low 3 bits of opcode
		register_number := state.opcode_reg
		if state.rex & 0x01 != 0 {  // REX.B extends the register
			register_number += 8
		}
		reg := decode_register(register_number, op_type, state.rex)
		op = op_reg(reg)
		return

	case .VVVV:
		// VEX.vvvv register
		register_number := 15 - state.vex_vvvv
		if state.evex_v2 {
			register_number += 16
		}
		reg := decode_register(register_number, op_type, state.rex)
		op = op_reg(reg)
		return

	case .IS4:
		// Immediate byte with register in high 4 bits
		if state.position >= len(state.data) {
			err = .BUFFER_TOO_SHORT
			return
		}
		immediate_byte := state.data[state.position]
		state.position += 1
		register_number := (immediate_byte >> 4) & 0x0F
		reg := decode_register(register_number, op_type, state.rex)
		op = op_reg(reg)
		return

	case .AAA:
		// EVEX opmask - already decoded in state
		return
	}

	return
}

decode_single_operand_vex :: proc(state: ^Decoder_State, op_type: Operand_Type, op_enc: Operand_Encoding,
                                  modrm_info: ModRM_Info, sib_info: SIB_Info, has_sib: bool) -> (op: Operand, err: Error_Code) {
	#partial switch op_enc {
	case .REG:
		// Register in ModR/M.reg, extended by VEX.R
		// vex_r is true when the encoded bit is 0, meaning extension is active
		register_number := modrm_info.reg
		if state.vex_r {  // vex_r=true means extend (bit was 0 in inverted encoding)
			register_number += 8
		}
		if state.vex_type == .EVEX && state.evex_r2 {  // evex_r2=true means extend
			register_number += 16
		}
		reg := decode_register(register_number, op_type, 0)
		return op_reg(reg), .NONE

	case .MR:
		if modrm_info.mod == 3 {
			// Register in ModR/M.rm, extended by VEX.B
			// vex_b is true when the encoded bit is 0, meaning extension is active
			register_number := modrm_info.rm
			if state.vex_b {  // vex_b=true means extend
				register_number += 8
			}
			reg := decode_register(register_number, op_type, 0)
			return op_reg(reg), .NONE
		} else {
			return decode_memory_operand(state, modrm_info, sib_info, has_sib, op_type)
		}

	case .VVVV:
		register_number := 15 - state.vex_vvvv
		if state.vex_type == .EVEX && state.evex_v2 {
			register_number += 16
		}
		reg := decode_register(register_number, op_type, 0)
		return op_reg(reg), .NONE

	case:
		// Fall back to legacy handling
		return decode_single_operand(state, op_type, op_enc, modrm_info, sib_info, has_sib)
	}
}

// -----------------------------------------------------------------------------
// 8.7 Memory Operand Decoding
// -----------------------------------------------------------------------------

decode_memory_operand :: proc(state: ^Decoder_State, modrm_info: ModRM_Info,
							   sib_info: SIB_Info, has_sib: bool, op_type: Operand_Type) -> (op: Operand, err: Error_Code) {

	base_reg := NONE
	index_reg := NONE
	scale: u8 = 1
	disp: i32 = 0

	// Address-register width: 32-bit in i386, 64-bit in long mode.
	addr_reg_from_num :: #force_inline proc(num: u8, mode: Mode) -> Register {
		return mode == ._32 ? gpr32_from_num(num) : gpr64_from_num(num)
	}

	if has_sib {
		// SIB addressing
		base_number := sib_info.base
		if state.rex & 0x01 != 0 {  // REX.B
			base_number += 8
		}

		// Special case: base=5 with mod=0 means no base (displacement32 only)
		if sib_info.base == 5 && modrm_info.mod == 0 {
			base_reg = NONE
		} else {
			base_reg = addr_reg_from_num(base_number, state.mode)
		}

		// Index register (0xFF means no index)
		if sib_info.index != 0xFF {
			index_number := sib_info.index
			if state.rex & 0x02 != 0 {  // REX.X
				index_number += 8
			}
			index_reg = addr_reg_from_num(index_number, state.mode)
			scale = sib_info.scale
		}
	} else {
		// Simple addressing with ModR/M.rm as base
		if modrm_info.mod == 0 && modrm_info.rm == 5 {
			// In long mode this is [RIP + disp32]; in i386 it's [disp32]
			// (RIP doesn't exist) -- leave base as NONE, disp
			// carries the absolute address.
			if state.mode == ._64 {
				base_reg = RIP
			} else {
				base_reg = NONE
			}
		} else {
			base_number := modrm_info.rm
			if state.rex & 0x01 != 0 {  // REX.B
				base_number += 8
			}
			base_reg = addr_reg_from_num(base_number, state.mode)
		}
	}

	// Read disp
	if modrm_info.disp_size == 1 {
		if state.position >= len(state.data) {
			return {}, .BUFFER_TOO_SHORT
		}
		disp = i32(i8(state.data[state.position]))
		state.position += 1
	} else if modrm_info.disp_size == 4 {
		if state.position + 4 > len(state.data) {
			return {}, .BUFFER_TOO_SHORT
		}
		disp = i32(u32(state.data[state.position]) |
				   u32(state.data[state.position+1]) << 8 |
				   u32(state.data[state.position+2]) << 16 |
				   u32(state.data[state.position+3]) << 24)
		state.position += 4
	}

	// Determine operand size from op_type
	size := op_type_to_size(op_type)

	mem := mem_make(base_reg, index_reg, scale, disp, NONE)

	return op_mem(mem, size), .NONE
}

// -----------------------------------------------------------------------------
// 8.8 Register Decoding Helpers
// -----------------------------------------------------------------------------

decode_register :: #force_inline proc "contextless" (num: u8, op_type: Operand_Type, rex: u8) -> Register {
	#partial switch op_type {
	case .R64, .RM64:
		return gpr64_from_num(num)
	case .R32, .RM32:
		return gpr32_from_num(num)
	case .R16, .RM16:
		return gpr16_from_num(num)
	case .R8, .RM8:
		return gpr8_from_num(num, rex != 0)
	case .XMM, .XMM_M32, .XMM_M64, .XMM_M128:
		return xmm_from_num(num)
	case .YMM, .YMM_M256:
		return ymm_from_num(num)
	case .ZMM, .ZMM_M512:
		return zmm_from_num(num)
	case .MM:
		return mm_from_num(num)
	case:
		return gpr64_from_num(num)
	}
}

decode_implicit_operand :: proc(op_type: Operand_Type) -> Operand {
	#partial switch op_type {
	case .AL_IMPL:
		return op_reg(AL)
	case .AX_IMPL:
		return op_reg(AX)
	case .EAX_IMPL:
		return op_reg(EAX)
	case .RAX_IMPL:
		return op_reg(RAX)
	case .CL_IMPL:
		return op_reg(CL)
	case:
		return {}
	}
}



// =============================================================================
// -----------------------------------------------------------------------------
// 8.9 Core Decode Procedure
// -----------------------------------------------------------------------------

// decode: The single entry point for x64 instruction decoding.
//
// Parameters:
//   data          - Input bytes to decode
//   instructions  - Output buffer for decoded Instructions (user-provided)
//   inst_info     - Output buffer for per-instruction metadata (parallel to instructions)
//   label_defs    - Array where label_defs[label_id] will be set to byte offset.
//                   On input, all entries should be LABEL_UNDEFINED.
//                   On output, defined labels have byte offsets.
//   relocs        - Dynamic array; unresolved relocations are appended
//   errors        - Dynamic array; decoding errors are appended
//
// Returns:
//   Result with bytes read and success status.
//
// After decoding:
//   - instructions[0..n] contains decoded instructions
//   - inst_info[0..n] contains parallel metadata (offsets, prefix info, etc.)
//   - label_defs contains labels inferred from branch targets
//
// The relocs parameter is optional input - if provided, relocations are used
// to give labels proper names. If empty or missing info, labels get placeholder
// names based on offset when printed.
//
decode :: proc(
	data:         []u8,
	relocs:       []Relocation,
	instructions: ^[dynamic]Instruction,
	inst_info:    ^[dynamic]Instruction_Info,
	label_defs:   ^[dynamic]Label_Definition,
	errors:       ^[dynamic]Error,
	mode:         Mode = ._64,
) -> (byte_count: u32, ok: bool) {
	if mode == ._16 {
		// Real-mode decoding is not implemented; the ModRM addressing
		// model differs from protected/long mode and needs a separate
		// decode path. See Mode enum comment in encoding_types.odin.
		fmt.panicf("x64.decode: Mode._16 (real mode) is not yet supported")
	}
	ok = true

	if len(data) == 0 {
		return
	}

	data_length := u32(len(data))

	// Track branch targets for label inference (resolved in pass 2 by isa).
	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	// =========================================================================
	// PASS 1: Decode all instructions, collect branch targets
	// =========================================================================

	for byte_count < data_length {
		inst: Instruction
		info: Instruction_Info

		// Record offset
		info.offset = byte_count

		// Initialize decoder state
		state := Decoder_State{
			data     = data[byte_count:],
			position = 0,
			mode     = mode,
			segment  = NONE,
		}

		// Phase 1: Parse prefixes
		err := decode_prefixes(&state)
		if err != nil {
			append(errors, Error{inst_idx = u32(len(instructions)), code = err})
			ok = false
			break
		}

		// Phase 1.5: i386 short-form INC/DEC (0x40-0x4F). These bytes are
		// REX prefixes in long mode (handled in decode_prefixes), but in
		// i386 they are 1-byte INC/DEC EAX..EDI (or AX..DI with 0x66).
		// ENCODING_TABLE doesn't carry these forms (they collide with REX
		// in 64-bit and the table is shared), so we materialise the
		// instruction inline here.
		if state.mode == ._32 && state.position < len(state.data) {
			b := state.data[state.position]
			if b >= 0x40 && b <= 0x4F {
				state.position += 1
				reg_num := b & 0x07
				is_dec  := (b & 0x08) != 0
				reg: Register = state.prefix_66 ? gpr16_from_num(reg_num) : gpr32_from_num(reg_num)

				inst.mnemonic      = is_dec ? .DEC : .INC
				inst.operand_count = 1
				inst.ops[0]        = op_reg(reg)
				inst.length        = u8(state.position)
				inst.flags.lock    = state.has_lock
				inst.flags.rep     = state.prefix_f2 ? .REPNE : (state.prefix_f3 ? .REP : .NONE)
				inst.flags.addr32  = state.prefix_67
				inst.flags.segment = state.segment != NONE ? u8(reg_hw(state.segment)) + 1 : 0

				info.has_lock = state.has_lock
				info.rep      = inst.flags.rep
				info.segment  = state.segment

				append(instructions, inst)
				append(inst_info, info)
				byte_count += u32(state.position)
				continue
			}
		}

		// Phase 2: Decode opcode and find instruction entry
		entry: ^Decode_Entry
		vex_entry: ^VEX_Decode_Entry
		entry, vex_entry, err = decode_opcode(&state)
		if err != nil {
			append(errors, Error{inst_idx = u32(len(instructions)), code = err})
			ok = false
			break
		}

		// Phase 3: Decode operands
		if vex_entry != nil {
			inst, err = decode_operands_vex(&state, vex_entry)
		} else if entry != nil {
			inst, err = decode_operands(&state, entry)
		} else {
			append(errors, Error{inst_idx = u32(len(instructions)), code = .INVALID_OPCODE})
			ok = false
			break
		}
		if err != nil {
			append(errors, Error{inst_idx = u32(len(instructions)), code = err})
			ok = false
			break
		}

		// Fill instruction length and flags (for round-trip encode/decode)
		inst.length = u8(state.position)
		inst.flags.lock = state.has_lock
		inst.flags.rep = state.prefix_f2 ? .REPNE : (state.prefix_f3 ? .REP : .NONE)
		inst.flags.addr32 = state.prefix_67
		// Segment: 0=none, 1=ES, 2=CS, 3=SS, 4=DS, 5=FS, 6=GS
		inst.flags.segment = state.segment != NONE ? u8(reg_hw(state.segment)) + 1 : 0

		// Fill instruction info (extended metadata)
		info.rex = state.rex
		info.has_lock = state.has_lock
		info.rep = inst.flags.rep
		info.segment = state.segment
		info.vex_type = state.vex_type
		if state.vex_type != nil && vex_entry != nil {
			// Use encoding requirements to distinguish LIG/WIG from L0/W0
			// If encoding says LIG, the actual L value doesn't matter for re-encoding
			// If encoding says L0/L1/L2, we should preserve the actual value
			if vex_entry.vex_l == .LIG {
				info.vex_l = .LIG
			} else {
				info.vex_l = state.vex_l == 0 ? .L0 : (state.vex_l == 1 ? .L1 : .L2)
			}
			if vex_entry.vex_w == .WIG {
				info.vex_w = .WIG
			} else {
				info.vex_w = state.vex_w ? .W1 : .W0
			}
			info.evex_b = state.evex_b
			info.evex_z = state.evex_z
			info.opmask = state.evex_aaa
		} else if state.vex_type != nil {
			// Fallback when vex_entry is nil (shouldn't happen normally)
			info.vex_l = state.vex_l == 0 ? .L0 : (state.vex_l == 1 ? .L1 : .L2)
			info.vex_w = state.vex_w ? .W1 : .W0
			info.evex_b = state.evex_b
			info.evex_z = state.evex_z
			info.opmask = state.evex_aaa
		}

		// Check for relative operands and record pending branch targets
		inst_end := byte_count + u32(state.position)
		for op_idx in 0..<inst.operand_count {
			op := &inst.ops[op_idx]
			if op.kind == .RELATIVE {
				// Compute absolute target address
				target := i64(inst_end) + op.relative
				if target >= 0 {
					append(&pending_branches, isa.Branch_Target{
						inst_idx = u32(len(instructions)),
						op_idx   = op_idx,
						target   = u32(target),
					})
				}
			}
		}

		append(instructions, inst)
		append(inst_info, info)

		byte_count += u32(state.position)
	}

	// =========================================================================
	// PASS 2: Infer labels from branch targets within the decoded region
	// =========================================================================

	isa.infer_labels_from_branches(pending_branches[:], byte_count, label_defs, relocs)

	return
}
