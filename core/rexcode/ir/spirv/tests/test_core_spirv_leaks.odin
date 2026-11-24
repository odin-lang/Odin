package rexcode_spirv_tests
import "core:testing"
import spirv ".."

@(private="file")
put :: proc(w: ^[dynamic]u32, opcode: spirv.Opcode, operands: ..u32) {
	append(w, u32(len(operands) + 1) << 16 | u32(opcode))
	append(w, ..operands)
}

@(private="file")
str :: proc(s: string) -> []u32 {
	out := make([]u32, (len(s) + 4) / 4, context.temp_allocator)
	for i in 0 ..< len(s) {
		out[i / 4] |= u32(s[i]) << uint((i % 4) * 8)
	}
	return out
}

@(private="file")
cat :: proc(parts: ..[]u32) -> []u32 {
	out := make([dynamic]u32, context.temp_allocator)
	for p in parts {
		append(&out, ..p)
	}
	return out[:]
}

@(private="file")
header :: proc() -> [dynamic]u32 {
	w := make([dynamic]u32, context.temp_allocator)
	append(&w, spirv.MAGIC, 0x0001_0500, 0, 100, 0)
	return w
}

@(private="file")
preamble :: proc(w: ^[dynamic]u32) {
	put(w, .OpCapability, 1)
	put(w, .OpExtension, ..str("SPV_KHR_storage_buffer_storage_class"))
	put(w, .OpExtInstImport, ..cat({1}, str("GLSL.std.450")))
	put(w, .OpMemoryModel, 0, 1)
	put(w, .OpEntryPoint, ..cat({5, 10}, str("main"), {30, 31}))
	put(w, .OpExecutionMode, 10, 17, 8, 8, 1)
	put(w, .OpString, ..cat({2}, str("file.glsl")))
	put(w, .OpSource, 2, 450, 2)
	put(w, .OpName, ..cat({10}, str("main")))
	put(w, .OpMemberName, ..cat({22, 0}, str("field")))
	put(w, .OpDecorate, 30, 30, 0)
	put(w, .OpMemberDecorate, 22, 0, 35, 0)
	put(w, .OpTypeVoid, 20)
	put(w, .OpTypeBool, 21)
	put(w, .OpTypeInt, 23, 32, 1)
	put(w, .OpTypeFloat, 24, 32)
	put(w, .OpTypeVector, 25, 24, 4)
	put(w, .OpTypeStruct, 22, 23, 24)
	put(w, .OpTypePointer, 26, 6, 23)
	put(w, .OpTypeFunction, 27, 20)
	put(w, .OpTypeFunction, 28, 23, 23, 23)
	put(w, .OpConstant, 23, 40, 4)
	put(w, .OpTypeArray, 29, 23, 40)
	put(w, .OpTypeRuntimeArray, 32, 24)
	put(w, .OpTypeImage, 33, 24, 1, 0, 0, 0, 1, 0)
	put(w, .OpConstantTrue, 21, 41)
	put(w, .OpConstant, 23, 42, 7)
	put(w, .OpTypeVector, 34, 23, 2)
	put(w, .OpConstantComposite, 34, 43, 40, 42)
	put(w, .OpConstantNull, 23, 44)
	put(w, .OpVariable, 26, 30, 6, 42)
	put(w, .OpVariable, 26, 31, 6)
}

@(private="file")
functions :: proc(w: ^[dynamic]u32) {
	put(w, .OpFunction, 20, 10, 0, 27)
	put(w, .OpLabel, 11)
	put(w, .OpVariable, 26, 50, 7)
	put(w, .OpLoad, 23, 51, 30, 2, 4)
	put(w, .OpBranch, 12)
	put(w, .OpLabel, 12)
	put(w, .OpPhi, 23, 52, 51, 11)
	put(w, .OpReturn)
	put(w, .OpFunctionEnd)
	put(w, .OpFunction, 23, 13, 0, 28)
	put(w, .OpFunctionParameter, 23, 14)
	put(w, .OpFunctionParameter, 23, 15)
	put(w, .OpLabel, 16)
	put(w, .OpIAdd, 23, 53, 14, 15)
	put(w, .OpReturnValue, 53)
	put(w, .OpFunctionEnd)
}

@(private="file")
encode_module :: proc(m: spirv.Module) -> (out: []u8, ok: bool) {
	buf := make([]u8, spirv.encoded_size(m), context.temp_allocator)
	relocs := make([dynamic]spirv.Relocation, context.temp_allocator)
	errors := make([dynamic]spirv.Error, context.temp_allocator)
	n: u32
	n, ok = spirv.encode(m, buf, &relocs, &errors)
	return buf[:n], ok
}

@(test)
test_encode_out_of_range_indices :: proc(t: ^testing.T) {
	m := spirv.make_module()
	m.types = {{kind = .FUNCTION, fields = {spirv.Type_Ref(0)}, count = 0x8000_0000}}
	m.type_ids = {spirv.Id(1)}
	m.defs = {{.TYPE, 0}, {.TYPE, 0x8000_0000}, {.CONSTANT, 0xffff_ffff}, {.GLOBAL, 0x8000_0001}}
	m.functions = {{signature = spirv.Type_Ref(0)}, {signature = spirv.TYPE_NONE}}
	m.function_ids = {spirv.Id(2), spirv.Id(3)}
	m.constants = {{result = {spirv.Id(4), spirv.TYPE_NONE}, opcode = .OpConstant, value = 1}}
	m.globals = {{type = spirv.TYPE_NONE}}
	m.global_ids = {spirv.Id(5)}
	out, ok := encode_module(m)
	testing.expect(t, ok && len(out) > 20)
	m.defs = nil
	out, ok = encode_module(m)
	testing.expect(t, ok && len(out) > 20)
}
