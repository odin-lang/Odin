// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm_tests

// End-to-end WASM pipeline: build a short instruction sequence, encode it,
// assert the exact byte stream against hand-computed LEB128 encodings, then
// decode the bytes back and confirm the mnemonics/operands round-trip, and
// finally print the decoded form and check the WAT text.
//
// Covers: nullary ops, signed-LEB constants, index immediates, a blocktype,
// a memarg, and the br_table vector form.
//
// Run with: odin run wasm/tests

import "core:fmt"
import "core:os"
import wasm "../"

@(private="file") rpasses   := 0
@(private="file") rfailures := 0

@(private="file")
ok :: proc(name: string, cond: bool) {
	if cond {
		fmt.printfln("  [ok]   %s", name)
		rpasses += 1
	} else {
		fmt.printfln("  [FAIL] %s", name)
		rfailures += 1
	}
}

@(private="file")
eq_bytes :: proc(name: string, got, want: []u8) {
	same := len(got) == len(want)
	if same {
		for i in 0..<len(got) {
			if got[i] != want[i] { same = false; break }
		}
	}
	if same {
		fmt.printfln("  [ok]   %s (% x)", name, got)
		rpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-18s got=[% x] want=[% x]", name, got, want)
		rfailures += 1
	}
}

@(private="file")
eq_str :: proc(name, got, want: string) {
	if got == want {
		fmt.printfln("  [ok]   %-18s %q", name, got)
		rpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-18s got=%q want=%q", name, got, want)
		rfailures += 1
	}
}

main :: proc() {
	fmt.println("== wasm encode/decode/print pipeline ==")

	insts := []wasm.Instruction{
		wasm.inst_i(.I32_CONST, wasm.op_i32(42)),       // 0x41 0x2A
		wasm.inst_idx(.LOCAL_GET, wasm.op_local(0)),     // 0x20 0x00
		wasm.inst_none(.I32_ADD),                        // 0x6A
		wasm.inst_idx(.CALL, wasm.op_func(3)),           // 0x10 0x03
		wasm.inst_block(.BLOCK, .I32),                   // 0x02 0x7F
		wasm.inst_memarg(.I32_LOAD, wasm.memarg(2, 8)),  // 0x28 0x02 0x08
		wasm.inst_none(.END),                            // 0x0B
	}

	code := make([]u8, wasm.encode_max_code_size(len(insts)))
	defer delete(code)
	relocs: [dynamic]wasm.Relocation
	errors: [dynamic]wasm.Error
	defer delete(relocs)
	defer delete(errors)

	n, enc_ok := wasm.encode(insts, nil, code, &relocs, &errors)
	ok("encode ok", enc_ok && len(errors) == 0)

	want := []u8{
		0x41, 0x2A,
		0x20, 0x00,
		0x6A,
		0x10, 0x03,
		0x02, 0x7F,
		0x28, 0x02, 0x08,
		0x0B,
	}
	eq_bytes("byte stream", code[:n], want)

	// ---- br_table on its own (vector immediate) ----------------------------
	bt := []wasm.Instruction{
		wasm.inst_br_table([]u32{0, 1}, 2),   // 0x0E 0x02 0x00 0x01 0x02
	}
	bt_code := make([]u8, 32)
	defer delete(bt_code)
	bt_relocs: [dynamic]wasm.Relocation
	bt_errors: [dynamic]wasm.Error
	defer delete(bt_relocs)
	defer delete(bt_errors)
	bn, _ := wasm.encode(bt, nil, bt_code, &bt_relocs, &bt_errors)
	eq_bytes("br_table bytes", bt_code[:bn], []u8{0x0E, 0x02, 0x00, 0x01, 0x02})

	// ---- decode round-trip --------------------------------------------------
	dinsts: [dynamic]wasm.Instruction
	dinfo:  [dynamic]wasm.Instruction_Info
	dlabels:[dynamic]wasm.Label_Definition
	derrs:  [dynamic]wasm.Error
	defer delete(dinsts)
	defer delete(dinfo)
	defer delete(dlabels)
	defer delete(derrs)

	dn, dec_ok := wasm.decode(code[:n], nil, &dinsts, &dinfo, &dlabels, &derrs)
	ok("decode ok",        dec_ok && len(derrs) == 0)
	ok("decode byte count", dn == n)
	ok("decode count",      len(dinsts) == len(insts))

	if len(dinsts) == len(insts) {
		ok("m[0] i32.const", dinsts[0].mnemonic == .I32_CONST && dinsts[0].ops[0].immediate == 42)
		ok("m[1] local.get", dinsts[1].mnemonic == .LOCAL_GET && dinsts[1].ops[0].index == 0)
		ok("m[2] i32.add",   dinsts[2].mnemonic == .I32_ADD   && dinsts[2].operand_count == 0)
		ok("m[3] call",      dinsts[3].mnemonic == .CALL      && dinsts[3].ops[0].idx_kind == .FUNC)
		ok("m[4] block",     dinsts[4].mnemonic == .BLOCK     && dinsts[4].ops[0].kind == .BLOCK_TYPE)
		ok("m[5] i32.load",  dinsts[5].mnemonic == .I32_LOAD  && dinsts[5].ops[0].memarg.offset == 8)
		ok("m[6] end",       dinsts[6].mnemonic == .END)
	}

	// ---- print --------------------------------------------------------------
	text := wasm.tprint(dinsts[:], dinfo[:], dlabels[:])
	want_text :=
		"    i32.const 42\n" +
		"    local.get 0\n" +
		"    i32.add\n" +
		"    call 3\n" +
		"    block (result i32)\n" +
		"    i32.load offset=8 align=2\n" +
		"    end\n"
	eq_str("disassembly", text, want_text)

	fmt.printfln("\n%d passed, %d failed", rpasses, rfailures)
	if rfailures > 0 { os.exit(1) }
}
