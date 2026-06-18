// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm_tests

// Spot-check ENCODING_TABLE entries against the canonical opcode bytes from
// the WebAssembly core specification (binary format, §5.4). One or two
// representatives from each opcode region, plus both 0xFC misc endpoints.
//
// Run with: odin run wasm/tests

import "core:fmt"
import "core:os"
import wasm "../"

@(private="file") passes   := 0
@(private="file") failures := 0

@(private="file")
check :: proc(name: string, m: wasm.Mnemonic, want_prefix: u8, want_opcode: u16) {
	e := wasm.ENCODING_TABLE[m]
	if e.prefix != want_prefix || e.opcode != want_opcode {
		fmt.printfln("  [FAIL] %-22s got prefix=%02x op=%02x  want prefix=%02x op=%02x",
			name, e.prefix, e.opcode, want_prefix, want_opcode)
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %-22s prefix=%02x op=%02x", name, e.prefix, e.opcode)
	passes += 1
}

main :: proc() {
	fmt.println("== wasm encoding-table spot checks ==")

	// control
	check("unreachable",   .UNREACHABLE,   0x00, 0x00)
	check("block",         .BLOCK,         0x00, 0x02)
	check("br_table",      .BR_TABLE,      0x00, 0x0E)
	check("call",          .CALL,          0x00, 0x10)
	check("call_indirect", .CALL_INDIRECT, 0x00, 0x11)

	// parametric / variable
	check("drop",          .DROP,          0x00, 0x1A)
	check("local.get",     .LOCAL_GET,     0x00, 0x20)
	check("global.set",    .GLOBAL_SET,    0x00, 0x24)

	// memory
	check("i32.load",      .I32_LOAD,      0x00, 0x28)
	check("i64.store32",   .I64_STORE32,   0x00, 0x3E)
	check("memory.size",   .MEMORY_SIZE,   0x00, 0x3F)
	check("memory.grow",   .MEMORY_GROW,   0x00, 0x40)

	// numeric
	check("i32.const",     .I32_CONST,     0x00, 0x41)
	check("f64.const",     .F64_CONST,     0x00, 0x44)
	check("i32.add",       .I32_ADD,       0x00, 0x6A)
	check("i64.mul",       .I64_MUL,       0x00, 0x7E)
	check("f32.add",       .F32_ADD,       0x00, 0x92)
	check("f64.sqrt",      .F64_SQRT,      0x00, 0x9F)

	// conversions / sign-extension / reftypes
	check("i32.wrap_i64",  .I32_WRAP_I64,  0x00, 0xA7)
	check("i32.extend8_s", .I32_EXTEND8_S, 0x00, 0xC0)
	check("ref.null",      .REF_NULL,      0x00, 0xD0)
	check("ref.func",      .REF_FUNC,      0x00, 0xD2)

	// 0xFC misc group endpoints
	check("i32.trunc_sat_f32_s", .I32_TRUNC_SAT_F32_S, 0xFC, 0)
	check("memory.init",         .MEMORY_INIT,         0xFC, 8)
	check("table.fill",          .TABLE_FILL,          0xFC, 17)

	// 0xFD SIMD group
	check("v128.load",     .V128_LOAD,     0xFD, 0x00)
	check("v128.const",    .V128_CONST,    0xFD, 0x0C)
	check("i8x16.shuffle", .I8X16_SHUFFLE, 0xFD, 0x0D)
	check("i32x4.add",     .I32X4_ADD,     0xFD, 0xAE)
	check("simd hi (relaxed)", .I32X4_RELAXED_DOT_I8X16_I7X16_ADD_S, 0xFD, 0x113)

	// 0xFE threads / atomics group
	check("memory.atomic.notify", .MEMORY_ATOMIC_NOTIFY, 0xFE, 0x00)
	check("atomic.fence",         .ATOMIC_FENCE,         0xFE, 0x03)
	check("i32.atomic.load",      .I32_ATOMIC_LOAD,      0xFE, 0x10)

	fmt.printfln("\n%d passed, %d failed", passes, failures)
	if failures > 0 { os.exit(1) }
}
