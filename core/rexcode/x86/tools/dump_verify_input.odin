package main

// =============================================================================
// x86 verification manifest dumper
// =============================================================================
//
// For each entry in x86's ENCODING_TABLE, builds a representative
// Instruction (canonical low-numbered registers, zero immediates, [RAX]
// memory base) and runs it through x86.encode() to produce a concrete
// byte sequence. Each sequence is dumped as a hex byte list for llvm-mc
// to disassemble.
//
// Writes:
//   /tmp/rexcode_x86_input.hex  -- 0xAA,0xBB,... per line (variable length)
//   /tmp/rexcode_x86_meta.txt   -- mnemonic\topcode\text\thex
//
// Skips entries that can't be safely encoded standalone (segment overrides,
// label-relative branches, REL operands, etc.).
//
// Run:  cd x86 && odin run tools/dump_verify_input.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

import x "../"

// Build a representative operand of the given type. Returns ok=false for
// types we don't construct in this harness (e.g. label-relative jumps).
build_operand :: proc(t: x.Operand_Type) -> (op: x.Operand, ok: bool) {
	#partial switch t {
	case .NONE:
		return x.Operand{}, false
	case .R8, .RM8:
		return x.Operand{reg = x.AL,   kind = .REGISTER, size = 1}, true
	case .R16, .RM16:
		return x.Operand{reg = x.AX,   kind = .REGISTER, size = 2}, true
	case .R32, .RM32:
		return x.Operand{reg = x.EAX,  kind = .REGISTER, size = 4}, true
	case .R64, .RM64:
		return x.Operand{reg = x.RAX,  kind = .REGISTER, size = 8}, true
	case .M, .M8, .M16, .M32, .M64, .M80, .M128, .M256, .M512:
		// [RAX] -- base only, no displacement
		m := x.Memory{}
		m.base_hw = u8(u32(x.RAX) & 0x1F)
		sz: u8 = 0
		#partial switch t {
		case .M8:   sz = 1
		case .M16:  sz = 2
		case .M32:  sz = 4
		case .M64:  sz = 8
		case .M80:  sz = 10
		case .M128: sz = 16
		case .M256: sz = 32
		case .M512: sz = 64
		case:       sz = 8
		}
		return x.Operand{mem = m, kind = .MEMORY, size = sz}, true
	case .IMM8, .IMM8SX:
		return x.Operand{immediate = 0, kind = .IMMEDIATE, size = 1}, true
	case .IMM16:
		return x.Operand{immediate = 0, kind = .IMMEDIATE, size = 2}, true
	case .IMM32:
		return x.Operand{immediate = 0, kind = .IMMEDIATE, size = 4}, true
	case .IMM64:
		return x.Operand{immediate = 0, kind = .IMMEDIATE, size = 8}, true
	case .AL_IMPL, .AX_IMPL, .EAX_IMPL, .RAX_IMPL,
		 .CL_IMPL, .DX_IMPL, .ONE_IMPL,
		 .ST0_IMPL, .XMM0_IMPL:
		// Implicit -- no operand consumed in the Instruction.ops array
		return x.Operand{}, false
	case .SREG:
		return x.Operand{reg = x.ES, kind = .REGISTER, size = 2}, true
	case .CR:
		return x.Operand{reg = x.CR0, kind = .REGISTER, size = 8}, true
	case .DR:
		return x.Operand{reg = x.DR0, kind = .REGISTER, size = 8}, true
	case .XMM, .XMM_M32, .XMM_M64, .XMM_M128:
		return x.Operand{reg = x.XMM0, kind = .REGISTER, size = 16}, true
	case .YMM, .YMM_M256:
		return x.Operand{reg = x.YMM0, kind = .REGISTER, size = 32}, true
	case .ZMM, .ZMM_M512:
		return x.Operand{reg = x.ZMM0, kind = .REGISTER, size = 64}, true
	case .MM, .MM_M64:
		return x.Operand{reg = x.MM0, kind = .REGISTER, size = 8}, true
	case .STI:
		return x.Operand{reg = x.ST1, kind = .REGISTER, size = 10}, true
	case .K, .K_M8, .K_M16, .K_M32, .K_M64:
		return x.Operand{reg = x.K1, kind = .REGISTER, size = 8}, true
	case .REL8, .REL32:
		// Label-relative; we don't try to encode these in the harness.
		return x.Operand{}, false
	case .MOFFS8, .MOFFS16, .MOFFS32, .MOFFS64:
		return x.Operand{}, false
	}
	return x.Operand{}, false
}

main :: proc() {
	fmt.println("Dumping x86 verification manifest...")

	hex_buf, meta_buf: strings.Builder
	strings.builder_init(&hex_buf)
	strings.builder_init(&meta_buf)
	defer strings.builder_destroy(&hex_buf)
	defer strings.builder_destroy(&meta_buf)

	code_buf: [64]u8
	relocs:   [dynamic]x.Relocation
	errors:   [dynamic]x.Error
	defer delete(relocs)
	defer delete(errors)

	total, dumped, skipped := 0, 0, 0
	for mn in x.Mnemonic {
		for entry, ei in x.ENCODING_TABLE[mn] {
			total += 1

			// Skip entries that need REL/MOFFS or other forms we can't easily
			// construct.
			skip := false
			for t in entry.ops {
				#partial switch t {
				case .REL8, .REL32, .MOFFS8, .MOFFS16, .MOFFS32, .MOFFS64:
					skip = true
				}
			}
			if skip { skipped += 1; continue }

			inst := x.Instruction{ mnemonic = mn, operand_count = 0 }
			idx: u8 = 0
			for t, oi in entry.ops {
				if t == .NONE { continue }
				op, ok := build_operand(t)
				if !ok { continue }
				if idx >= 4 { break }
				inst.ops[idx] = op
				idx += 1
			}
			inst.operand_count = idx

			clear(&relocs)
			clear(&errors)
			insts := [1]x.Instruction{inst}
			r := x.encode(insts[:], nil, code_buf[:], &relocs, &errors)
			if !r.success || r.byte_count == 0 {
				skipped += 1
				continue
			}

			// Emit hex bytes (comma-separated, lowercase)
			for i in 0..<r.byte_count {
				if i > 0 { strings.write_byte(&hex_buf, ',') }
				fmt.sbprintf(&hex_buf, "0x%02x", code_buf[i])
			}
			strings.write_byte(&hex_buf, '\n')

			// Meta: mnemonic, opcode hex, ext, entry index, byte count
			fmt.sbprintf(&meta_buf, "%v\t%02x\t%d\t%d\t%d\n",
						 mn, entry.opcode, entry.ext, ei, r.byte_count)
			dumped += 1
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_x86_input.hex", hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_x86_meta.txt", meta_buf.buf[:])

	fmt.printf("Total entries: %d, dumped: %d, skipped: %d\n", total, dumped, skipped)
}
