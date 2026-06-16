// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// WebAssembly verification manifest dumper
// =============================================================================
//
// Encodes one representative instruction per mnemonic (synthesising operands
// that fit the entry's immediate layout) and writes:
//
//   /tmp/rexcode_wasm_input.hex  -- comma-separated LE hex bytes, one row each
//   /tmp/rexcode_wasm_meta.txt   -- "<mnemonic>\t<prefix>\t<opcode>\t<size>"
//
// The canonical external oracle for cross-checking these bytes is wabt's
// `wasm-objdump` / `wasm2wat`, or LLVM's `llvm-mc -triple=wasm32`. Feed the
// hex rows through the disassembler and diff its mnemonics against the meta
// file.
//
// Run:  cd wasm && odin run tools/dump_verify_input.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

import w "../"

main :: proc() {
	fmt.println("Dumping WASM verification manifest...")

	hex_buf, meta_buf: strings.Builder
	strings.builder_init(&hex_buf)
	strings.builder_init(&meta_buf)
	defer strings.builder_destroy(&hex_buf)
	defer strings.builder_destroy(&meta_buf)

	code: [32]u8
	count := 0

	for mn in w.Mnemonic {
		if mn == .INVALID { continue }
		form := w.ENCODING_TABLE[mn]

		inst := synth(mn, form)
		one := []w.Instruction{inst}

		relocs: [dynamic]w.Relocation
		errors: [dynamic]w.Error
		defer delete(relocs)
		defer delete(errors)

		n, ok := w.encode(one, nil, code[:], &relocs, &errors)
		if !ok { continue }

		for i in 0..<n {
			if i > 0 { strings.write_byte(&hex_buf, ',') }
			fmt.sbprintf(&hex_buf, "0x%02x", code[i])
		}
		strings.write_byte(&hex_buf, '\n')

		fmt.sbprintf(&meta_buf, "%v\t0x%02x\t0x%02x\t%d\n", mn, form.prefix, form.opcode, n)
		count += 1
	}

	_ = os.write_entire_file("/tmp/rexcode_wasm_input.hex", hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_wasm_meta.txt", meta_buf.buf[:])

	fmt.printf("Wrote %d entries.\n", count)
}

// Build a minimal valid instruction for `mn` whose operands satisfy the
// immediate layout in `form`.
synth :: proc(mn: w.Mnemonic, form: w.Encoding) -> w.Instruction {
	if mn == .BR_TABLE {
		@(static) tbl := [1]u32{0}
		return w.inst_br_table(tbl[:], 0)
	}

	inst := w.Instruction{mnemonic = mn}
	slot := 0
	for k in form.imm {
		switch k {
		case .NONE, .ZERO_BYTE:
			// no operand
		case .BLOCKTYPE:
			inst.ops[slot] = w.op_blocktype(.EMPTY); slot += 1
		case .I32:
			inst.ops[slot] = w.op_i32(1); slot += 1
		case .I64:
			inst.ops[slot] = w.op_i64(1); slot += 1
		case .F32:
			inst.ops[slot] = w.op_f32(1); slot += 1
		case .F64:
			inst.ops[slot] = w.op_f64(1); slot += 1
		case .IDX:
			inst.ops[slot] = w.op_func(0); slot += 1
		case .MEMARG:
			inst.ops[slot] = w.op_memarg(0, 0); slot += 1
		case .REFTYPE:
			inst.ops[slot] = w.op_reftype(.FUNCREF); slot += 1
		case .LANE:
			inst.ops[slot] = w.op_lane(0); slot += 1
		case .LANES16:
			// 16-byte value lives in inst.bytes (left zero), no operand
		case .BR_TABLE:
			// handled above
		}
	}
	inst.operand_count = u8(slot)
	return inst
}
