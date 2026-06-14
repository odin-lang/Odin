package rexcode_mos6502

// =============================================================================
// MOS 6502 OPERANDS
// =============================================================================
//
// The 6502 has more *addressing modes* than it has registers. The
// addressing mode is encoded into the operand as part of the Memory
// type so the matcher can dispatch to the correct opcode form for a
// given mnemonic. Layout:
//
//   LDA #$12         IMMEDIATE  imm = 0x12
//   LDA $12          MEMORY    {mode = ZP,         address = 0x0012}
//   LDA $12,X        MEMORY    {mode = ZP_X,       address = 0x0012}
//   LDA $1234        MEMORY    {mode = ABS,        address = 0x1234}
//   LDA $1234,X      MEMORY    {mode = ABS_X,      address = 0x1234}
//   LDA $1234,Y      MEMORY    {mode = ABS_Y,      address = 0x1234}
//   LDA ($12,X)      MEMORY    {mode = IND_X,      address = 0x0012}
//   LDA ($12),Y      MEMORY    {mode = IND_Y,      address = 0x0012}
//   LDA ($12)        MEMORY    {mode = IND_ZP,     address = 0x0012}    -- 65C02
//   JMP ($1234)      MEMORY    {mode = IND,        address = 0x1234}
//   JMP ($1234,X)    MEMORY    {mode = IND_ABS_X,  address = 0x1234}    -- 65C02
//   BEQ label        RELATIVE  relative = label_id
//   ROL A            REGISTER  reg = A

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,      // mostly used for `A` in `ROL A` (implicit; rarely needed)
	IMMEDIATE,
	MEMORY,
	RELATIVE,      // PC-relative target (label or raw byte offset)
}

Address_Mode :: enum u8 {
	ZP,           // $nn
	ZP_X,         // $nn,X
	ZP_Y,         // $nn,Y
	ABS,          // $nnnn
	ABS_X,        // $nnnn,X
	ABS_Y,        // $nnnn,Y
	IND,          // ($nnnn) -- JMP only
	IND_X,        // ($nn,X)
	IND_Y,        // ($nn),Y
	IND_ZP,       // ($nn) -- 65C02
	IND_ABS_X,    // ($nnnn,X) -- 65C02 JMP only
}

Memory :: struct #packed {
	address: u16,
	mode:    Address_Mode,
	_:       u8,
}
#assert(size_of(Memory) == 4)

// -----------------------------------------------------------------------------
// Memory constructors (one per addressing mode)
// -----------------------------------------------------------------------------

mem_zp        :: #force_inline proc "contextless" (addr: u8)  -> Memory { return Memory{address = u16(addr), mode = .ZP        } }
mem_zp_x      :: #force_inline proc "contextless" (addr: u8)  -> Memory { return Memory{address = u16(addr), mode = .ZP_X      } }
mem_zp_y      :: #force_inline proc "contextless" (addr: u8)  -> Memory { return Memory{address = u16(addr), mode = .ZP_Y      } }
mem_abs       :: #force_inline proc "contextless" (addr: u16) -> Memory { return Memory{address = addr,     mode = .ABS       } }
mem_abs_x     :: #force_inline proc "contextless" (addr: u16) -> Memory { return Memory{address = addr,     mode = .ABS_X     } }
mem_abs_y     :: #force_inline proc "contextless" (addr: u16) -> Memory { return Memory{address = addr,     mode = .ABS_Y     } }
mem_ind       :: #force_inline proc "contextless" (addr: u16) -> Memory { return Memory{address = addr,     mode = .IND       } }
mem_ind_x     :: #force_inline proc "contextless" (addr: u8)  -> Memory { return Memory{address = u16(addr), mode = .IND_X     } }
mem_ind_y     :: #force_inline proc "contextless" (addr: u8)  -> Memory { return Memory{address = u16(addr), mode = .IND_Y     } }
mem_ind_zp    :: #force_inline proc "contextless" (addr: u8)  -> Memory { return Memory{address = u16(addr), mode = .IND_ZP    } }
mem_ind_abs_x :: #force_inline proc "contextless" (addr: u16) -> Memory { return Memory{address = addr,     mode = .IND_ABS_X } }

// -----------------------------------------------------------------------------
// Operand: kind-tagged union, 16 bytes
// -----------------------------------------------------------------------------

Operand :: struct #packed {
	using _: struct #raw_union {
		reg:       Register,    // 2 bytes
		mem:       Memory,      // 4 bytes
		immediate: i64,         // 8 bytes
		relative:  i64,         // 8 bytes (label id pre-resolution; byte offset post)
	},
	kind: Operand_Kind,         // 1
	size: u8,                   // 1
	_:    [6]u8,                // 6
}
#assert(size_of(Operand) == 16)

// Generic constructors -------------------------------------------------------

op_reg :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 1}
}

op_imm8 :: #force_inline proc "contextless" (v: i64) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = 1}
}

op_imm16 :: #force_inline proc "contextless" (v: i64) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = 2}
}

op_mem :: #force_inline proc "contextless" (m: Memory) -> Operand {
	size: u8 = 2
	switch m.mode {
	case .ZP, .ZP_X, .ZP_Y, .IND_X, .IND_Y, .IND_ZP:
		size = 1
	case .ABS, .ABS_X, .ABS_Y, .IND, .IND_ABS_X:
		size = 2
	}
	return Operand{mem = m, kind = .MEMORY, size = size}
}

op_label :: #force_inline proc "contextless" (label_id: u32, size: u8 = 1) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = size}
}

op_rel_offset :: #force_inline proc "contextless" (offset: i64) -> Operand {
	return Operand{relative = offset, kind = .RELATIVE, size = 1}
}

// Address-mode-named operand helpers (call site reads like asm).
op_zp        :: #force_inline proc "contextless" (a: u8)  -> Operand { return op_mem(mem_zp(a))        }
op_zp_x      :: #force_inline proc "contextless" (a: u8)  -> Operand { return op_mem(mem_zp_x(a))      }
op_zp_y      :: #force_inline proc "contextless" (a: u8)  -> Operand { return op_mem(mem_zp_y(a))      }
op_abs       :: #force_inline proc "contextless" (a: u16) -> Operand { return op_mem(mem_abs(a))       }
op_abs_x     :: #force_inline proc "contextless" (a: u16) -> Operand { return op_mem(mem_abs_x(a))     }
op_abs_y     :: #force_inline proc "contextless" (a: u16) -> Operand { return op_mem(mem_abs_y(a))     }
op_ind       :: #force_inline proc "contextless" (a: u16) -> Operand { return op_mem(mem_ind(a))       }
op_ind_x     :: #force_inline proc "contextless" (a: u8)  -> Operand { return op_mem(mem_ind_x(a))     }
op_ind_y     :: #force_inline proc "contextless" (a: u8)  -> Operand { return op_mem(mem_ind_y(a))     }
op_ind_zp    :: #force_inline proc "contextless" (a: u8)  -> Operand { return op_mem(mem_ind_zp(a))    }
op_ind_abs_x :: #force_inline proc "contextless" (a: u16) -> Operand { return op_mem(mem_ind_abs_x(a)) }
