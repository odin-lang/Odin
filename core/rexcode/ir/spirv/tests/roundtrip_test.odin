// rexcode  ·  Brendan Punsky (dotbmp@github), original author

// SPIR-V codec round-trip suite. For each module shape: encode -> decode ->
// re-encode and assert the two encodings are byte-identical. A byte-exact
// round-trip exercises the encoder, the decoder, the <id> side tables, and the
// generic table-driven operation codec all at once: any drift in operand order,
// id mapping, or section layout shows up as a word mismatch.
package rexcode_spirv_tests

import "core:fmt"
import "core:os"
import "core:slice"
import spirv ".."

ok_count:   int
fail_count: int

@(private="file")
roundtrip :: proc(name: string, m: spirv.Module) {
	buf1 := make([]u8, 64 * 1024, context.temp_allocator)
	buf2 := make([]u8, 64 * 1024, context.temp_allocator)
	relocs: [dynamic]spirv.Relocation; defer delete(relocs)
	errors: [dynamic]spirv.Error;      defer delete(errors)

	n1, ok1 := spirv.encode(m, buf1, &relocs, &errors)
	if !ok1 {
		fmt.printf("  [FAIL] %s: encode failed\n", name); fail_count += 1; return
	}

	m2: spirv.Module
	derr: [dynamic]spirv.Error; defer delete(derr)
	_, ok2 := spirv.decode(buf1[:n1], &m2, &derr, context.temp_allocator)
	if !ok2 {
		fmt.printf("  [FAIL] %s: decode failed\n", name); fail_count += 1; return
	}

	n2, ok3 := spirv.encode(m2, buf2, &relocs, &errors)
	if !ok3 {
		fmt.printf("  [FAIL] %s: re-encode failed\n", name); fail_count += 1; return
	}

	if n1 != n2 || !slice.equal(buf1[:n1], buf2[:n2]) {
		fmt.printf("  [FAIL] %s: round-trip mismatch (n1=%d n2=%d)\n", name, n1, n2)
		for i := u32(0); i < max(n1, n2); i += 4 {
			w1 := i < n1 ? word_at(buf1, i) : 0
			w2 := i < n2 ? word_at(buf2, i) : 0
			if w1 != w2 { fmt.printf("           [%d] %08x != %08x\n", i / 4, w1, w2) }
		}
		fail_count += 1
		return
	}

	// big-endian: byte-swap every word and decode again. Endianness is detected
	// from the magic, so the same module must be recovered -- re-encoding it
	// (little-endian) reproduces buf1.
	be := make([]u8, n1, context.temp_allocator)
	for i := u32(0); i < n1; i += 4 {
		be[i], be[i + 1], be[i + 2], be[i + 3] = buf1[i + 3], buf1[i + 2], buf1[i + 1], buf1[i]
	}
	mbe: spirv.Module
	beerr: [dynamic]spirv.Error; defer delete(beerr)
	if _, ok := spirv.decode(be[:n1], &mbe, &beerr, context.temp_allocator); !ok {
		fmt.printf("  [FAIL] %s: big-endian decode failed\n", name); fail_count += 1; return
	}
	nbe, _ := spirv.encode(mbe, buf2, &relocs, &errors)
	if nbe != n1 || !slice.equal(buf1[:n1], buf2[:nbe]) {
		fmt.printf("  [FAIL] %s: big-endian round-trip mismatch (n1=%d nbe=%d)\n", name, n1, nbe)
		fail_count += 1
		return
	}

	fmt.printf("  [ok]   %-22s %d bytes\n", name, n1)
	ok_count += 1
}

@(private="file")
word_at :: proc(b: []u8, i: u32) -> u32 {
	return u32(b[i]) | u32(b[i + 1]) << 8 | u32(b[i + 2]) << 16 | u32(b[i + 3]) << 24
}

main :: proc() {
	fmt.println("==== SPIR-V codec round-trip ====")

	// (1) a void compute entry point: header + preamble + a void function.
	{
		m := spirv.make_module()
		m.capabilities = {.Shader}
		m.entry_points = {{model = .GLCompute, function = spirv.Id(4), name = "main"}}
		m.types = {
			{kind = .VOID},
			{kind = .FUNCTION, fields = {spirv.Type_Ref(0)}, count = 0},
		}
		m.type_ids = {spirv.Id(2), spirv.Id(3)}
		m.functions = {
			{signature = spirv.Type_Ref(1), blocks = {
				{id = spirv.Id(5), ops = {{opcode = u16(spirv.Opcode.OpReturn)}}},
			}},
		}
		m.function_ids = {spirv.Id(4)}
		m.bound = 6
		roundtrip("void_main", m)
	}

	// (2) an int type + two scalar constants (the constant pool + OpConstant width).
	{
		m := spirv.make_module()
		m.capabilities = {.Shader}
		m.types = {{kind = .INT, bits = 32, aux = 1}}   // signed i32
		m.type_ids = {spirv.Id(1)}
		m.constants = {
			{result = {spirv.Id(2), spirv.Type_Ref(0)}, opcode = .OpConstant, value = 10},
			{result = {spirv.Id(3), spirv.Type_Ref(0)}, opcode = .OpConstant, value = 0xDEAD_BEEF},
		}
		m.bound = 4
		roundtrip("int_constants", m)
	}

	// (3) a function body with a real operation (the generic operand codec):
	//     %6 = OpIAdd %i32 %const_a %const_b ; OpReturn
	{
		m := spirv.make_module()
		m.capabilities = {.Shader}
		m.types = {
			{kind = .VOID},
			{kind = .INT, bits = 32, aux = 1},
			{kind = .FUNCTION, fields = {spirv.Type_Ref(0)}, count = 0},
		}
		m.type_ids = {spirv.Id(1), spirv.Id(2), spirv.Id(3)}
		m.constants = {
			{result = {spirv.Id(4), spirv.Type_Ref(1)}, opcode = .OpConstant, value = 10},
			{result = {spirv.Id(5), spirv.Type_Ref(1)}, opcode = .OpConstant, value = 20},
		}
		add := spirv.Operation{
			opcode   = u16(spirv.Opcode.OpIAdd),
			result   = {spirv.Id(6), spirv.Type_Ref(1)},
			operands = {spirv.op_value(spirv.Id(4)), spirv.op_value(spirv.Id(5))},
		}
		m.functions = {
			{signature = spirv.Type_Ref(2), blocks = {
				{id = spirv.Id(8), ops = {add, {opcode = u16(spirv.Opcode.OpReturn)}}},
			}},
		}
		m.function_ids = {spirv.Id(7)}
		m.bound = 9
		roundtrip("iadd_function", m)
	}

	// (4) a function with a parameter, and bound left 0 so encode computes it:
	//     i32 @f(i32 %4) { %5: OpReturnValue %4 }
	{
		m := spirv.make_module()
		m.capabilities = {.Shader}
		m.types = {
			{kind = .INT, bits = 32, aux = 1},
			{kind = .FUNCTION, fields = {spirv.Type_Ref(0), spirv.Type_Ref(0)}, count = 1},
		}
		m.type_ids = {spirv.Id(1), spirv.Id(2)}
		ret := spirv.Operation{
			opcode   = u16(spirv.Opcode.OpReturnValue),
			result   = {id = spirv.ID_NONE},
			operands = {spirv.op_value(spirv.Id(4))},
		}
		m.functions = {
			{signature = spirv.Type_Ref(1), blocks = {
				{
					id     = spirv.Id(5),
					params = {{id = spirv.Id(4), type = spirv.Type_Ref(0)}},   // OpFunctionParameter
					ops    = {ret},
				},
			}},
		}
		m.function_ids = {spirv.Id(3)}
		// m.bound left 0 -> computed
		roundtrip("param_function", m)
	}

	// (5) an enum-parameter operand: OpLoad ... MemoryAccess Aligned 16, where the
	//     alignment (16) is a trailing operand pulled in by the Aligned bit.
	{
		m := spirv.make_module()
		m.capabilities = {.Shader}
		m.types = {
			{kind = .VOID},
			{kind = .FLOAT, bits = 32},
			{kind = .POINTER, aux = 7, elem = spirv.Type_Ref(1)},   // Function* float
			{kind = .FUNCTION, fields = {spirv.Type_Ref(0)}, count = 0},
		}
		m.type_ids = {spirv.Id(1), spirv.Id(2), spirv.Id(3), spirv.Id(4)}
		var := spirv.Operation{   // %7 = OpVariable %ptr Function
			opcode = u16(spirv.Opcode.OpVariable), result = {spirv.Id(7), spirv.Type_Ref(2)},
			operands = {spirv.op_int(7)},
		}
		load := spirv.Operation{  // %8 = OpLoad %float %7 Aligned 16
			opcode = u16(spirv.Opcode.OpLoad), result = {spirv.Id(8), spirv.Type_Ref(1)},
			operands = {spirv.op_value(spirv.Id(7)), spirv.op_int(0x2), spirv.op_int(16)},
		}
		m.functions = {
			{signature = spirv.Type_Ref(3), blocks = {
				{id = spirv.Id(6), ops = {var, load, {opcode = u16(spirv.Opcode.OpReturn)}}},
			}},
		}
		m.function_ids = {spirv.Id(5)}
		roundtrip("load_aligned", m)
	}

	fmt.printf("\n%d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}
