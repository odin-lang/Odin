package rexcode_mos65816

// =============================================================================
// W65C816S OPERANDS
// =============================================================================
//
// 24-bit address space with banked addressing. Address modes:
//
//   Direct Page (formerly zero-page; D register makes it movable)
//     DP            $nn
//     DP_X          $nn,X
//     DP_Y          $nn,Y
//     DP_IND        ($nn)              -- 16-bit indirect via DP, uses DBR
//     DP_IND_X      ($nn,X)
//     DP_IND_Y      ($nn),Y
//     DP_IND_LONG   [$nn]              -- 24-bit indirect (65816 NEW)
//     DP_IND_LONG_Y [$nn],Y            -- 24-bit indirect indexed (65816 NEW)
//
//   Absolute (16-bit within DBR / PBR)
//     ABS           $nnnn
//     ABS_X         $nnnn,X
//     ABS_Y         $nnnn,Y
//     ABS_IND       ($nnnn)            -- JMP only (PBR)
//     ABS_IND_LONG  [$nnnn]            -- JML only (24-bit target)
//     ABS_IND_X     ($nnnn,X)          -- JMP/JSR
//
//   Long (24-bit; bypasses DBR)
//     LONG          $nnnnnn            -- 65816 NEW
//     LONG_X        $nnnnnn,X          -- 65816 NEW
//
//   Stack relative
//     SR            $nn,S              -- 65816 NEW
//     SR_IND_Y      ($nn,S),Y          -- 65816 NEW
//
// Branch offsets (REL, REL_LONG) and block-move bank pairs (MVN/MVP) are
// handled as separate Operand_Type values; they don't ride in Memory.

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,
	IMMEDIATE,
	MEMORY,
	RELATIVE,
}

Address_Mode :: enum u8 {
	DP, DP_X, DP_Y,
	DP_IND, DP_IND_X, DP_IND_Y,
	DP_IND_LONG, DP_IND_LONG_Y,
	ABS, ABS_X, ABS_Y,
	ABS_IND, ABS_IND_LONG, ABS_IND_X,
	LONG, LONG_X,
	SR, SR_IND_Y,
}

// 24-bit address packed alongside the mode in 4 bytes.
Memory :: bit_field u32 {
	address: u32          | 24,
	mode:    Address_Mode | 8,
}
#assert(size_of(Memory) == 4)

mem_dp           :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .DP            } }
mem_dp_x         :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .DP_X          } }
mem_dp_y         :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .DP_Y          } }
mem_dp_ind       :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .DP_IND        } }
mem_dp_ind_x     :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .DP_IND_X      } }
mem_dp_ind_y     :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .DP_IND_Y      } }
mem_dp_ind_long  :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .DP_IND_LONG   } }
mem_dp_ind_long_y:: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .DP_IND_LONG_Y } }
mem_abs          :: #force_inline proc "contextless" (a: u16) -> Memory { return Memory{address = u32(a), mode = .ABS           } }
mem_abs_x        :: #force_inline proc "contextless" (a: u16) -> Memory { return Memory{address = u32(a), mode = .ABS_X         } }
mem_abs_y        :: #force_inline proc "contextless" (a: u16) -> Memory { return Memory{address = u32(a), mode = .ABS_Y         } }
mem_abs_ind      :: #force_inline proc "contextless" (a: u16) -> Memory { return Memory{address = u32(a), mode = .ABS_IND       } }
mem_abs_ind_long :: #force_inline proc "contextless" (a: u16) -> Memory { return Memory{address = u32(a), mode = .ABS_IND_LONG  } }
mem_abs_ind_x    :: #force_inline proc "contextless" (a: u16) -> Memory { return Memory{address = u32(a), mode = .ABS_IND_X     } }
mem_long         :: #force_inline proc "contextless" (a: u32) -> Memory { return Memory{address = a & 0xFFFFFF, mode = .LONG    } }
mem_long_x       :: #force_inline proc "contextless" (a: u32) -> Memory { return Memory{address = a & 0xFFFFFF, mode = .LONG_X  } }
mem_sr           :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .SR            } }
mem_sr_ind_y     :: #force_inline proc "contextless" (a: u8)  -> Memory { return Memory{address = u32(a), mode = .SR_IND_Y      } }

Operand :: struct #packed {
	using _: struct #raw_union {
		reg:       Register,
		mem:       Memory,
		immediate: i64,
		relative:  i64,
	},
	kind: Operand_Kind,
	size: u8,
	_:    [6]u8,
}
#assert(size_of(Operand) == 16)

op_reg    :: #force_inline proc "contextless" (r: Register) -> Operand { return Operand{reg = r, kind = .REGISTER, size = 1} }
op_imm8   :: #force_inline proc "contextless" (v: i64)      -> Operand { return Operand{immediate = v, kind = .IMMEDIATE, size = 1} }
op_imm16  :: #force_inline proc "contextless" (v: i64)      -> Operand { return Operand{immediate = v, kind = .IMMEDIATE, size = 2} }
op_mem    :: #force_inline proc "contextless" (m: Memory)   -> Operand {
	// Operand size = width of the address literal as encoded.
	size: u8 = 2
	switch m.mode {
	case .DP, .DP_X, .DP_Y, .DP_IND, .DP_IND_X, .DP_IND_Y,
		 .DP_IND_LONG, .DP_IND_LONG_Y, .SR, .SR_IND_Y:
		size = 1
	case .ABS, .ABS_X, .ABS_Y, .ABS_IND, .ABS_IND_LONG, .ABS_IND_X:
		size = 2
	case .LONG, .LONG_X:
		size = 3
	}
	return Operand{mem = m, kind = .MEMORY, size = size}
}

op_label   :: #force_inline proc "contextless" (label_id: u32, size: u8 = 1) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = size}
}
op_rel_offset :: #force_inline proc "contextless" (off: i64) -> Operand {
	return Operand{relative = off, kind = .RELATIVE, size = 1}
}
