// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

// GENERATED from spirv.core.grammar.json (SPIRV-Headers unified1) by tablegen/gen.odin.
// DO NOT EDIT -- regenerate with `odin run core/rexcode/ir/spirv/tablegen`.

inst_OpNop :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpNop), result = {id = ID_NONE}}
}

nop :: proc(b: ^Builder) {
	append(&b.ops, inst_OpNop())
}

inst_OpUndef :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpUndef), result = {result, result_type}}
}

undef :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUndef(result_type, r))
	return r
}

inst_OpSourceContinued :: #force_inline proc "contextless" (buf: []Operand, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpSourceContinued), result = {id = ID_NONE}, operands = buf[:n]}
}

source_continued :: proc(b: ^Builder, op1: string) {
	append(&b.ops, inst_OpSourceContinued(opbuf(b, (len(op1) + 4) / 4), op1))
}

inst_OpSource :: #force_inline proc "contextless" (buf: []Operand, op1: Source_Language, op2: i64, op3: Maybe(Id), op4: Maybe(string)) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	buf[n] = op_int(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_value(x); n += 1 }
	if s, sok := op4.?; sok { n += pack_string_operands(buf[n:], s) }
	return Operation{opcode = u16(Opcode.OpSource), result = {id = ID_NONE}, operands = buf[:n]}
}

source :: proc(b: ^Builder, op1: Source_Language, op2: i64, op3: Maybe(Id), op4: Maybe(string)) {
	append(&b.ops, inst_OpSource(opbuf(b, 1 + 1 + 1 + (len(op4.? or_else "") + 4) / 4), op1, op2, op3, op4))
}

inst_OpSourceExtension :: #force_inline proc "contextless" (buf: []Operand, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpSourceExtension), result = {id = ID_NONE}, operands = buf[:n]}
}

source_extension :: proc(b: ^Builder, op1: string) {
	append(&b.ops, inst_OpSourceExtension(opbuf(b, (len(op1) + 4) / 4), op1))
}

inst_OpName :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: string) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	n += pack_string_operands(buf[n:], op2)
	return Operation{opcode = u16(Opcode.OpName), result = {id = ID_NONE}, operands = buf[:n]}
}

name :: proc(b: ^Builder, op1: Id, op2: string) {
	append(&b.ops, inst_OpName(opbuf(b, 1 + (len(op2) + 4) / 4), op1, op2))
}

inst_OpMemberName :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: i64, op3: string) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	n += pack_string_operands(buf[n:], op3)
	return Operation{opcode = u16(Opcode.OpMemberName), result = {id = ID_NONE}, operands = buf[:n]}
}

member_name :: proc(b: ^Builder, op1: Id, op2: i64, op3: string) {
	append(&b.ops, inst_OpMemberName(opbuf(b, 1 + 1 + (len(op3) + 4) / 4), op1, op2, op3))
}

inst_OpString :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpString), result = {id = result}, operands = buf[:n]}
}

string_ :: proc(b: ^Builder, op1: string) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpString(opbuf(b, (len(op1) + 4) / 4), r, op1))
	return r
}

inst_OpLine :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: i64, op3: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	return Operation{opcode = u16(Opcode.OpLine), result = {id = ID_NONE}, operands = buf[:n]}
}

line :: proc(b: ^Builder, op1: Id, op2: i64, op3: i64) {
	append(&b.ops, inst_OpLine(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpExtension :: #force_inline proc "contextless" (buf: []Operand, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpExtension), result = {id = ID_NONE}, operands = buf[:n]}
}

extension :: proc(b: ^Builder, op1: string) {
	append(&b.ops, inst_OpExtension(opbuf(b, (len(op1) + 4) / 4), op1))
}

inst_OpExtInstImport :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpExtInstImport), result = {id = result}, operands = buf[:n]}
}

ext_inst_import :: proc(b: ^Builder, op1: string) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpExtInstImport(opbuf(b, (len(op1) + 4) / 4), r, op1))
	return r
}

inst_OpExtInst :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpExtInst), result = {result, result_type}, operands = buf[:n]}
}

ext_inst :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpExtInst(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpMemoryModel :: #force_inline proc "contextless" (buf: []Operand, op1: Addressing_Model, op2: Memory_Model) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpMemoryModel), result = {id = ID_NONE}, operands = buf[:n]}
}

memory_model :: proc(b: ^Builder, op1: Addressing_Model, op2: Memory_Model) {
	append(&b.ops, inst_OpMemoryModel(opbuf(b, 1 + 1), op1, op2))
}

inst_OpEntryPoint :: #force_inline proc "contextless" (buf: []Operand, op1: Execution_Model, op2: Id, op3: string, op4: []Id) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	buf[n] = op_value(op2); n += 1
	n += pack_string_operands(buf[n:], op3)
	for x in op4 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpEntryPoint), result = {id = ID_NONE}, operands = buf[:n]}
}

entry_point :: proc(b: ^Builder, op1: Execution_Model, op2: Id, op3: string, op4: []Id) {
	append(&b.ops, inst_OpEntryPoint(opbuf(b, 1 + 1 + (len(op3) + 4) / 4 + len(op4)), op1, op2, op3, op4))
}

inst_OpExecutionMode :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Execution_Mode) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpExecutionMode), result = {id = ID_NONE}, operands = buf[:n]}
}

execution_mode :: proc(b: ^Builder, op1: Id, op2: Execution_Mode) {
	append(&b.ops, inst_OpExecutionMode(opbuf(b, 1 + 1), op1, op2))
}

inst_OpCapability :: #force_inline proc "contextless" (buf: []Operand, op1: Capability) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	return Operation{opcode = u16(Opcode.OpCapability), result = {id = ID_NONE}, operands = buf[:n]}
}

capability :: proc(b: ^Builder, op1: Capability) {
	append(&b.ops, inst_OpCapability(opbuf(b, 1), op1))
}

inst_OpTypeVoid :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeVoid), result = {id = result}}
}

type_void_ :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeVoid(r))
	return r
}

inst_OpTypeBool :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeBool), result = {id = result}}
}

type_bool_ :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeBool(r))
	return r
}

inst_OpTypeInt :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: i64, op2: i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	buf[n] = op_int(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTypeInt), result = {id = result}, operands = buf[:n]}
}

type_int_ :: proc(b: ^Builder, op1: i64, op2: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeInt(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpTypeFloat :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: i64, op2: Maybe(FP_Encoding)) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	if x, xok := op2.?; xok { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpTypeFloat), result = {id = result}, operands = buf[:n]}
}

type_float_ :: proc(b: ^Builder, op1: i64, op2: Maybe(FP_Encoding)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeFloat(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpTypeVector :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTypeVector), result = {id = result}, operands = buf[:n]}
}

type_vector_ :: proc(b: ^Builder, op1: Id, op2: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeVector(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpTypeMatrix :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTypeMatrix), result = {id = result}, operands = buf[:n]}
}

type_matrix :: proc(b: ^Builder, op1: Id, op2: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeMatrix(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpTypeImage :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Dim, op3: i64, op4: i64, op5: i64, op6: i64, op7: Image_Format, op8: Maybe(Access_Qualifier)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(i64(op7)); n += 1
	if x, xok := op8.?; xok { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpTypeImage), result = {id = result}, operands = buf[:n]}
}

type_image :: proc(b: ^Builder, op1: Id, op2: Dim, op3: i64, op4: i64, op5: i64, op6: i64, op7: Image_Format, op8: Maybe(Access_Qualifier)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeImage(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpTypeSampler :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeSampler), result = {id = result}}
}

type_sampler :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeSampler(r))
	return r
}

inst_OpTypeSampledImage :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpTypeSampledImage), result = {id = result}, operands = buf[:n]}
}

type_sampled_image :: proc(b: ^Builder, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeSampledImage(opbuf(b, 1), r, op1))
	return r
}

inst_OpTypeArray :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTypeArray), result = {id = result}, operands = buf[:n]}
}

type_array_ :: proc(b: ^Builder, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeArray(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpTypeRuntimeArray :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpTypeRuntimeArray), result = {id = result}, operands = buf[:n]}
}

type_runtime_array :: proc(b: ^Builder, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeRuntimeArray(opbuf(b, 1), r, op1))
	return r
}

inst_OpTypeStruct :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTypeStruct), result = {id = result}, operands = buf[:n]}
}

type_struct :: proc(b: ^Builder, op1: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeStruct(opbuf(b, len(op1)), r, op1))
	return r
}

inst_OpTypeOpaque :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpTypeOpaque), result = {id = result}, operands = buf[:n]}
}

type_opaque :: proc(b: ^Builder, op1: string) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeOpaque(opbuf(b, (len(op1) + 4) / 4), r, op1))
	return r
}

inst_OpTypePointer :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Storage_Class, op2: Id) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTypePointer), result = {id = result}, operands = buf[:n]}
}

type_pointer_ :: proc(b: ^Builder, op1: Storage_Class, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypePointer(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpTypeFunction :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTypeFunction), result = {id = result}, operands = buf[:n]}
}

type_function :: proc(b: ^Builder, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeFunction(opbuf(b, 1 + len(op2)), r, op1, op2))
	return r
}

inst_OpTypeEvent :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeEvent), result = {id = result}}
}

type_event :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeEvent(r))
	return r
}

inst_OpTypeDeviceEvent :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeDeviceEvent), result = {id = result}}
}

type_device_event :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeDeviceEvent(r))
	return r
}

inst_OpTypeReserveId :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeReserveId), result = {id = result}}
}

type_reserve_id :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeReserveId(r))
	return r
}

inst_OpTypeQueue :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeQueue), result = {id = result}}
}

type_queue :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeQueue(r))
	return r
}

inst_OpTypePipe :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Access_Qualifier) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	return Operation{opcode = u16(Opcode.OpTypePipe), result = {id = result}, operands = buf[:n]}
}

type_pipe :: proc(b: ^Builder, op1: Access_Qualifier) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypePipe(opbuf(b, 1), r, op1))
	return r
}

inst_OpTypeForwardPointer :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Storage_Class) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpTypeForwardPointer), result = {id = ID_NONE}, operands = buf[:n]}
}

type_forward_pointer :: proc(b: ^Builder, op1: Id, op2: Storage_Class) {
	append(&b.ops, inst_OpTypeForwardPointer(opbuf(b, 1 + 1), op1, op2))
}

inst_OpConstantTrue :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpConstantTrue), result = {result, result_type}}
}

constant_true :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantTrue(result_type, r))
	return r
}

inst_OpConstantFalse :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpConstantFalse), result = {result, result_type}}
}

constant_false :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantFalse(result_type, r))
	return r
}

inst_OpConstant :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConstant), result = {result, result_type}, operands = buf[:n]}
}

constant :: proc(b: ^Builder, result_type: Type_Ref, op1: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstant(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConstantComposite :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpConstantComposite), result = {result, result_type}, operands = buf[:n]}
}

constant_composite :: proc(b: ^Builder, result_type: Type_Ref, op1: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantComposite(opbuf(b, len(op1)), result_type, r, op1))
	return r
}

inst_OpConstantSampler :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Sampler_Addressing_Mode, op2: i64, op3: Sampler_Filter_Mode) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(i64(op3)); n += 1
	return Operation{opcode = u16(Opcode.OpConstantSampler), result = {result, result_type}, operands = buf[:n]}
}

constant_sampler :: proc(b: ^Builder, result_type: Type_Ref, op1: Sampler_Addressing_Mode, op2: i64, op3: Sampler_Filter_Mode) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantSampler(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpConstantNull :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpConstantNull), result = {result, result_type}}
}

constant_null :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantNull(result_type, r))
	return r
}

inst_OpSpecConstantTrue :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpSpecConstantTrue), result = {result, result_type}}
}

spec_constant_true :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantTrue(result_type, r))
	return r
}

inst_OpSpecConstantFalse :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpSpecConstantFalse), result = {result, result_type}}
}

spec_constant_false :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantFalse(result_type, r))
	return r
}

inst_OpSpecConstant :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSpecConstant), result = {result, result_type}, operands = buf[:n]}
}

spec_constant :: proc(b: ^Builder, result_type: Type_Ref, op1: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstant(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSpecConstantComposite :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpSpecConstantComposite), result = {result, result_type}, operands = buf[:n]}
}

spec_constant_composite :: proc(b: ^Builder, result_type: Type_Ref, op1: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantComposite(opbuf(b, len(op1)), result_type, r, op1))
	return r
}

inst_OpSpecConstantOp :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSpecConstantOp), result = {result, result_type}, operands = buf[:n]}
}

spec_constant_op :: proc(b: ^Builder, result_type: Type_Ref, op1: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantOp(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpFunction :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Function_Control, op2: Id) -> Operation {
	n := 0
	buf[n] = op_int(i64(transmute(u32)op1)); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFunction), result = {result, result_type}, operands = buf[:n]}
}

function :: proc(b: ^Builder, result_type: Type_Ref, op1: Function_Control, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFunction(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFunctionParameter :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpFunctionParameter), result = {result, result_type}}
}

function_parameter :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFunctionParameter(result_type, r))
	return r
}

inst_OpFunctionEnd :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpFunctionEnd), result = {id = ID_NONE}}
}

function_end :: proc(b: ^Builder) {
	append(&b.ops, inst_OpFunctionEnd())
}

inst_OpFunctionCall :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpFunctionCall), result = {result, result_type}, operands = buf[:n]}
}

function_call :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFunctionCall(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpVariable :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Storage_Class, op2: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	if x, xok := op2.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpVariable), result = {result, result_type}, operands = buf[:n]}
}

variable :: proc(b: ^Builder, result_type: Type_Ref, op1: Storage_Class, op2: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVariable(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpImageTexelPointer :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpImageTexelPointer), result = {result, result_type}, operands = buf[:n]}
}

image_texel_pointer :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageTexelPointer(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpLoad :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	if x, xok := op2.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpLoad), result = {result, result_type}, operands = buf[:n]}
}

load :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Maybe(Memory_Access)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLoad(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpStore :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpStore), result = {id = ID_NONE}, operands = buf[:n]}
}

store :: proc(b: ^Builder, op1: Id, op2: Id, op3: Maybe(Memory_Access)) {
	append(&b.ops, inst_OpStore(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpCopyMemory :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Maybe(Memory_Access), op4: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCopyMemory), result = {id = ID_NONE}, operands = buf[:n]}
}

copy_memory :: proc(b: ^Builder, op1: Id, op2: Id, op3: Maybe(Memory_Access), op4: Maybe(Memory_Access)) {
	append(&b.ops, inst_OpCopyMemory(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpCopyMemorySized :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access), op5: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	if x, xok := op5.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCopyMemorySized), result = {id = ID_NONE}, operands = buf[:n]}
}

copy_memory_sized :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access), op5: Maybe(Memory_Access)) {
	append(&b.ops, inst_OpCopyMemorySized(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpAccessChain :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpAccessChain), result = {result, result_type}, operands = buf[:n]}
}

access_chain :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAccessChain(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpInBoundsAccessChain :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpInBoundsAccessChain), result = {result, result_type}, operands = buf[:n]}
}

in_bounds_access_chain :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpInBoundsAccessChain(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpPtrAccessChain :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpPtrAccessChain), result = {result, result_type}, operands = buf[:n]}
}

ptr_access_chain :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPtrAccessChain(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpArrayLength :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	return Operation{opcode = u16(Opcode.OpArrayLength), result = {result, result_type}, operands = buf[:n]}
}

array_length :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArrayLength(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGenericPtrMemSemantics :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpGenericPtrMemSemantics), result = {result, result_type}, operands = buf[:n]}
}

generic_ptr_mem_semantics :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGenericPtrMemSemantics(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpInBoundsPtrAccessChain :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpInBoundsPtrAccessChain), result = {result, result_type}, operands = buf[:n]}
}

in_bounds_ptr_access_chain :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpInBoundsPtrAccessChain(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpDecorate :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Decoration) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpDecorate), result = {id = ID_NONE}, operands = buf[:n]}
}

decorate :: proc(b: ^Builder, op1: Id, op2: Decoration) {
	append(&b.ops, inst_OpDecorate(opbuf(b, 1 + 1), op1, op2))
}

inst_OpMemberDecorate :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: i64, op3: Decoration) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(i64(op3)); n += 1
	return Operation{opcode = u16(Opcode.OpMemberDecorate), result = {id = ID_NONE}, operands = buf[:n]}
}

member_decorate :: proc(b: ^Builder, op1: Id, op2: i64, op3: Decoration) {
	append(&b.ops, inst_OpMemberDecorate(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpDecorationGroup :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpDecorationGroup), result = {id = result}}
}

decoration_group :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDecorationGroup(r))
	return r
}

inst_OpGroupDecorate :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupDecorate), result = {id = ID_NONE}, operands = buf[:n]}
}

group_decorate :: proc(b: ^Builder, op1: Id, op2: []Id) {
	append(&b.ops, inst_OpGroupDecorate(opbuf(b, 1 + len(op2)), op1, op2))
}

inst_OpGroupMemberDecorate :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: []Pair_Id_Lit) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for p in op2 { buf[n] = op_value(p.id); buf[n + 1] = op_int(p.lit); n += 2 }
	return Operation{opcode = u16(Opcode.OpGroupMemberDecorate), result = {id = ID_NONE}, operands = buf[:n]}
}

group_member_decorate :: proc(b: ^Builder, op1: Id, op2: []Pair_Id_Lit) {
	append(&b.ops, inst_OpGroupMemberDecorate(opbuf(b, 1 + 2 * len(op2)), op1, op2))
}

inst_OpVectorExtractDynamic :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpVectorExtractDynamic), result = {result, result_type}, operands = buf[:n]}
}

vector_extract_dynamic :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVectorExtractDynamic(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpVectorInsertDynamic :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpVectorInsertDynamic), result = {result, result_type}, operands = buf[:n]}
}

vector_insert_dynamic :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVectorInsertDynamic(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpVectorShuffle :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: []i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_int(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpVectorShuffle), result = {result, result_type}, operands = buf[:n]}
}

vector_shuffle :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: []i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVectorShuffle(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpCompositeConstruct :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpCompositeConstruct), result = {result, result_type}, operands = buf[:n]}
}

composite_construct :: proc(b: ^Builder, result_type: Type_Ref, op1: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCompositeConstruct(opbuf(b, len(op1)), result_type, r, op1))
	return r
}

inst_OpCompositeExtract :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_int(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpCompositeExtract), result = {result, result_type}, operands = buf[:n]}
}

composite_extract :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCompositeExtract(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpCompositeInsert :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: []i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_int(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpCompositeInsert), result = {result, result_type}, operands = buf[:n]}
}

composite_insert :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: []i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCompositeInsert(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpCopyObject :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCopyObject), result = {result, result_type}, operands = buf[:n]}
}

copy_object :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCopyObject(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpTranspose :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpTranspose), result = {result, result_type}, operands = buf[:n]}
}

transpose :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTranspose(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSampledImage :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSampledImage), result = {result, result_type}, operands = buf[:n]}
}

sampled_image :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSampledImage(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpImageSampleImplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSampleImplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sample_implicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleImplicitLod(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSampleExplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Image_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_int(i64(transmute(u32)op3)); n += 1
	return Operation{opcode = u16(Opcode.OpImageSampleExplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sample_explicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Image_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleExplicitLod(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSampleDrefImplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSampleDrefImplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sample_dref_implicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleDrefImplicitLod(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSampleDrefExplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Image_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(i64(transmute(u32)op4)); n += 1
	return Operation{opcode = u16(Opcode.OpImageSampleDrefExplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sample_dref_explicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Image_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleDrefExplicitLod(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSampleProjImplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSampleProjImplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sample_proj_implicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleProjImplicitLod(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSampleProjExplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Image_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_int(i64(transmute(u32)op3)); n += 1
	return Operation{opcode = u16(Opcode.OpImageSampleProjExplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sample_proj_explicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Image_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleProjExplicitLod(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSampleProjDrefImplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSampleProjDrefImplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sample_proj_dref_implicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleProjDrefImplicitLod(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSampleProjDrefExplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Image_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(i64(transmute(u32)op4)); n += 1
	return Operation{opcode = u16(Opcode.OpImageSampleProjDrefExplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sample_proj_dref_explicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Image_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleProjDrefExplicitLod(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageFetch :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageFetch), result = {result, result_type}, operands = buf[:n]}
}

image_fetch :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageFetch(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageGather :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageGather), result = {result, result_type}, operands = buf[:n]}
}

image_gather :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageGather(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageDrefGather :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageDrefGather), result = {result, result_type}, operands = buf[:n]}
}

image_dref_gather :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageDrefGather(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageRead :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageRead), result = {result, result_type}, operands = buf[:n]}
}

image_read :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageRead(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageWrite :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageWrite), result = {id = ID_NONE}, operands = buf[:n]}
}

image_write :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) {
	append(&b.ops, inst_OpImageWrite(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpImage :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpImage), result = {result, result_type}, operands = buf[:n]}
}

image :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImage(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpImageQueryFormat :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpImageQueryFormat), result = {result, result_type}, operands = buf[:n]}
}

image_query_format :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageQueryFormat(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpImageQueryOrder :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpImageQueryOrder), result = {result, result_type}, operands = buf[:n]}
}

image_query_order :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageQueryOrder(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpImageQuerySizeLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpImageQuerySizeLod), result = {result, result_type}, operands = buf[:n]}
}

image_query_size_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageQuerySizeLod(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpImageQuerySize :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpImageQuerySize), result = {result, result_type}, operands = buf[:n]}
}

image_query_size :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageQuerySize(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpImageQueryLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpImageQueryLod), result = {result, result_type}, operands = buf[:n]}
}

image_query_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageQueryLod(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpImageQueryLevels :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpImageQueryLevels), result = {result, result_type}, operands = buf[:n]}
}

image_query_levels :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageQueryLevels(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpImageQuerySamples :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpImageQuerySamples), result = {result, result_type}, operands = buf[:n]}
}

image_query_samples :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageQuerySamples(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertFToU :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertFToU), result = {result, result_type}, operands = buf[:n]}
}

convert_f_to_u :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertFToU(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertFToS :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertFToS), result = {result, result_type}, operands = buf[:n]}
}

convert_f_to_s :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertFToS(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertSToF :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertSToF), result = {result, result_type}, operands = buf[:n]}
}

convert_s_to_f :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertSToF(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertUToF :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertUToF), result = {result, result_type}, operands = buf[:n]}
}

convert_u_to_f :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertUToF(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpUConvert :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpUConvert), result = {result, result_type}, operands = buf[:n]}
}

u_convert :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUConvert(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSConvert :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSConvert), result = {result, result_type}, operands = buf[:n]}
}

s_convert :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSConvert(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpFConvert :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpFConvert), result = {result, result_type}, operands = buf[:n]}
}

f_convert :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFConvert(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpQuantizeToF16 :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpQuantizeToF16), result = {result, result_type}, operands = buf[:n]}
}

quantize_to_f16 :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpQuantizeToF16(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertPtrToU :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertPtrToU), result = {result, result_type}, operands = buf[:n]}
}

convert_ptr_to_u :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertPtrToU(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSatConvertSToU :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSatConvertSToU), result = {result, result_type}, operands = buf[:n]}
}

sat_convert_s_to_u :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSatConvertSToU(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSatConvertUToS :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSatConvertUToS), result = {result, result_type}, operands = buf[:n]}
}

sat_convert_u_to_s :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSatConvertUToS(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertUToPtr :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertUToPtr), result = {result, result_type}, operands = buf[:n]}
}

convert_u_to_ptr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertUToPtr(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpPtrCastToGeneric :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpPtrCastToGeneric), result = {result, result_type}, operands = buf[:n]}
}

ptr_cast_to_generic :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPtrCastToGeneric(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpGenericCastToPtr :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpGenericCastToPtr), result = {result, result_type}, operands = buf[:n]}
}

generic_cast_to_ptr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGenericCastToPtr(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpGenericCastToPtrExplicit :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Storage_Class) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpGenericCastToPtrExplicit), result = {result, result_type}, operands = buf[:n]}
}

generic_cast_to_ptr_explicit :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Storage_Class) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGenericCastToPtrExplicit(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpBitcast :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpBitcast), result = {result, result_type}, operands = buf[:n]}
}

bitcast :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitcast(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSNegate :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSNegate), result = {result, result_type}, operands = buf[:n]}
}

s_negate :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSNegate(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpFNegate :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpFNegate), result = {result, result_type}, operands = buf[:n]}
}

f_negate :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFNegate(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpIAdd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIAdd), result = {result, result_type}, operands = buf[:n]}
}

i_add :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIAdd(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFAdd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFAdd), result = {result, result_type}, operands = buf[:n]}
}

f_add :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFAdd(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpISub :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpISub), result = {result, result_type}, operands = buf[:n]}
}

i_sub :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpISub(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFSub :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFSub), result = {result, result_type}, operands = buf[:n]}
}

f_sub :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFSub(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpIMul :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIMul), result = {result, result_type}, operands = buf[:n]}
}

i_mul :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIMul(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFMul :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFMul), result = {result, result_type}, operands = buf[:n]}
}

f_mul :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFMul(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUDiv :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUDiv), result = {result, result_type}, operands = buf[:n]}
}

u_div :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUDiv(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSDiv :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSDiv), result = {result, result_type}, operands = buf[:n]}
}

s_div :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSDiv(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFDiv :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFDiv), result = {result, result_type}, operands = buf[:n]}
}

f_div :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFDiv(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUMod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUMod), result = {result, result_type}, operands = buf[:n]}
}

u_mod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUMod(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSRem :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSRem), result = {result, result_type}, operands = buf[:n]}
}

s_rem :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSRem(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSMod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSMod), result = {result, result_type}, operands = buf[:n]}
}

s_mod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSMod(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFRem :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFRem), result = {result, result_type}, operands = buf[:n]}
}

f_rem :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFRem(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFMod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFMod), result = {result, result_type}, operands = buf[:n]}
}

f_mod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFMod(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpVectorTimesScalar :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpVectorTimesScalar), result = {result, result_type}, operands = buf[:n]}
}

vector_times_scalar :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVectorTimesScalar(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpMatrixTimesScalar :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpMatrixTimesScalar), result = {result, result_type}, operands = buf[:n]}
}

matrix_times_scalar :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpMatrixTimesScalar(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpVectorTimesMatrix :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpVectorTimesMatrix), result = {result, result_type}, operands = buf[:n]}
}

vector_times_matrix :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVectorTimesMatrix(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpMatrixTimesVector :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpMatrixTimesVector), result = {result, result_type}, operands = buf[:n]}
}

matrix_times_vector :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpMatrixTimesVector(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpMatrixTimesMatrix :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpMatrixTimesMatrix), result = {result, result_type}, operands = buf[:n]}
}

matrix_times_matrix :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpMatrixTimesMatrix(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpOuterProduct :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpOuterProduct), result = {result, result_type}, operands = buf[:n]}
}

outer_product :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpOuterProduct(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpDot :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpDot), result = {result, result_type}, operands = buf[:n]}
}

dot :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDot(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpIAddCarry :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIAddCarry), result = {result, result_type}, operands = buf[:n]}
}

i_add_carry :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIAddCarry(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpISubBorrow :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpISubBorrow), result = {result, result_type}, operands = buf[:n]}
}

i_sub_borrow :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpISubBorrow(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUMulExtended :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUMulExtended), result = {result, result_type}, operands = buf[:n]}
}

u_mul_extended :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUMulExtended(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSMulExtended :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSMulExtended), result = {result, result_type}, operands = buf[:n]}
}

s_mul_extended :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSMulExtended(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpAny :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpAny), result = {result, result_type}, operands = buf[:n]}
}

any_ :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAny(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpAll :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpAll), result = {result, result_type}, operands = buf[:n]}
}

all :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAll(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpIsNan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpIsNan), result = {result, result_type}, operands = buf[:n]}
}

is_nan :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIsNan(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpIsInf :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpIsInf), result = {result, result_type}, operands = buf[:n]}
}

is_inf :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIsInf(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpIsFinite :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpIsFinite), result = {result, result_type}, operands = buf[:n]}
}

is_finite :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIsFinite(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpIsNormal :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpIsNormal), result = {result, result_type}, operands = buf[:n]}
}

is_normal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIsNormal(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSignBitSet :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSignBitSet), result = {result, result_type}, operands = buf[:n]}
}

sign_bit_set :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSignBitSet(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpLessOrGreater :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpLessOrGreater), result = {result, result_type}, operands = buf[:n]}
}

less_or_greater :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLessOrGreater(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpOrdered :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpOrdered), result = {result, result_type}, operands = buf[:n]}
}

ordered :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpOrdered(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUnordered :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUnordered), result = {result, result_type}, operands = buf[:n]}
}

unordered :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUnordered(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpLogicalEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpLogicalEqual), result = {result, result_type}, operands = buf[:n]}
}

logical_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLogicalEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpLogicalNotEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpLogicalNotEqual), result = {result, result_type}, operands = buf[:n]}
}

logical_not_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLogicalNotEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpLogicalOr :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpLogicalOr), result = {result, result_type}, operands = buf[:n]}
}

logical_or :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLogicalOr(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpLogicalAnd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpLogicalAnd), result = {result, result_type}, operands = buf[:n]}
}

logical_and :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLogicalAnd(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpLogicalNot :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpLogicalNot), result = {result, result_type}, operands = buf[:n]}
}

logical_not :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLogicalNot(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSelect :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSelect), result = {result, result_type}, operands = buf[:n]}
}

select :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSelect(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpIEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIEqual), result = {result, result_type}, operands = buf[:n]}
}

i_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpINotEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpINotEqual), result = {result, result_type}, operands = buf[:n]}
}

i_not_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpINotEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUGreaterThan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUGreaterThan), result = {result, result_type}, operands = buf[:n]}
}

u_greater_than :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUGreaterThan(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSGreaterThan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSGreaterThan), result = {result, result_type}, operands = buf[:n]}
}

s_greater_than :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSGreaterThan(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUGreaterThanEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUGreaterThanEqual), result = {result, result_type}, operands = buf[:n]}
}

u_greater_than_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUGreaterThanEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSGreaterThanEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSGreaterThanEqual), result = {result, result_type}, operands = buf[:n]}
}

s_greater_than_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSGreaterThanEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpULessThan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpULessThan), result = {result, result_type}, operands = buf[:n]}
}

u_less_than :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpULessThan(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSLessThan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSLessThan), result = {result, result_type}, operands = buf[:n]}
}

s_less_than :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSLessThan(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpULessThanEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpULessThanEqual), result = {result, result_type}, operands = buf[:n]}
}

u_less_than_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpULessThanEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSLessThanEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSLessThanEqual), result = {result, result_type}, operands = buf[:n]}
}

s_less_than_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSLessThanEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFOrdEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFOrdEqual), result = {result, result_type}, operands = buf[:n]}
}

f_ord_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFOrdEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFUnordEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFUnordEqual), result = {result, result_type}, operands = buf[:n]}
}

f_unord_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFUnordEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFOrdNotEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFOrdNotEqual), result = {result, result_type}, operands = buf[:n]}
}

f_ord_not_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFOrdNotEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFUnordNotEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFUnordNotEqual), result = {result, result_type}, operands = buf[:n]}
}

f_unord_not_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFUnordNotEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFOrdLessThan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFOrdLessThan), result = {result, result_type}, operands = buf[:n]}
}

f_ord_less_than :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFOrdLessThan(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFUnordLessThan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFUnordLessThan), result = {result, result_type}, operands = buf[:n]}
}

f_unord_less_than :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFUnordLessThan(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFOrdGreaterThan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFOrdGreaterThan), result = {result, result_type}, operands = buf[:n]}
}

f_ord_greater_than :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFOrdGreaterThan(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFUnordGreaterThan :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFUnordGreaterThan), result = {result, result_type}, operands = buf[:n]}
}

f_unord_greater_than :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFUnordGreaterThan(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFOrdLessThanEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFOrdLessThanEqual), result = {result, result_type}, operands = buf[:n]}
}

f_ord_less_than_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFOrdLessThanEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFUnordLessThanEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFUnordLessThanEqual), result = {result, result_type}, operands = buf[:n]}
}

f_unord_less_than_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFUnordLessThanEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFOrdGreaterThanEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFOrdGreaterThanEqual), result = {result, result_type}, operands = buf[:n]}
}

f_ord_greater_than_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFOrdGreaterThanEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFUnordGreaterThanEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFUnordGreaterThanEqual), result = {result, result_type}, operands = buf[:n]}
}

f_unord_greater_than_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFUnordGreaterThanEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpShiftRightLogical :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpShiftRightLogical), result = {result, result_type}, operands = buf[:n]}
}

shift_right_logical :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpShiftRightLogical(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpShiftRightArithmetic :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpShiftRightArithmetic), result = {result, result_type}, operands = buf[:n]}
}

shift_right_arithmetic :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpShiftRightArithmetic(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpShiftLeftLogical :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpShiftLeftLogical), result = {result, result_type}, operands = buf[:n]}
}

shift_left_logical :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpShiftLeftLogical(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpBitwiseOr :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpBitwiseOr), result = {result, result_type}, operands = buf[:n]}
}

bitwise_or :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitwiseOr(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpBitwiseXor :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpBitwiseXor), result = {result, result_type}, operands = buf[:n]}
}

bitwise_xor :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitwiseXor(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpBitwiseAnd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpBitwiseAnd), result = {result, result_type}, operands = buf[:n]}
}

bitwise_and :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitwiseAnd(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpNot :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpNot), result = {result, result_type}, operands = buf[:n]}
}

not :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpNot(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpBitFieldInsert :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpBitFieldInsert), result = {result, result_type}, operands = buf[:n]}
}

bit_field_insert :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitFieldInsert(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpBitFieldSExtract :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpBitFieldSExtract), result = {result, result_type}, operands = buf[:n]}
}

bit_field_s_extract :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitFieldSExtract(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpBitFieldUExtract :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpBitFieldUExtract), result = {result, result_type}, operands = buf[:n]}
}

bit_field_u_extract :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitFieldUExtract(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpBitReverse :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpBitReverse), result = {result, result_type}, operands = buf[:n]}
}

bit_reverse :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitReverse(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpBitCount :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpBitCount), result = {result, result_type}, operands = buf[:n]}
}

bit_count :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitCount(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpDPdx :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpDPdx), result = {result, result_type}, operands = buf[:n]}
}

d_pdx :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDPdx(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpDPdy :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpDPdy), result = {result, result_type}, operands = buf[:n]}
}

d_pdy :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDPdy(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpFwidth :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpFwidth), result = {result, result_type}, operands = buf[:n]}
}

fwidth :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFwidth(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpDPdxFine :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpDPdxFine), result = {result, result_type}, operands = buf[:n]}
}

d_pdx_fine :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDPdxFine(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpDPdyFine :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpDPdyFine), result = {result, result_type}, operands = buf[:n]}
}

d_pdy_fine :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDPdyFine(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpFwidthFine :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpFwidthFine), result = {result, result_type}, operands = buf[:n]}
}

fwidth_fine :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFwidthFine(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpDPdxCoarse :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpDPdxCoarse), result = {result, result_type}, operands = buf[:n]}
}

d_pdx_coarse :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDPdxCoarse(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpDPdyCoarse :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpDPdyCoarse), result = {result, result_type}, operands = buf[:n]}
}

d_pdy_coarse :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDPdyCoarse(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpFwidthCoarse :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpFwidthCoarse), result = {result, result_type}, operands = buf[:n]}
}

fwidth_coarse :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFwidthCoarse(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpEmitVertex :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpEmitVertex), result = {id = ID_NONE}}
}

emit_vertex :: proc(b: ^Builder) {
	append(&b.ops, inst_OpEmitVertex())
}

inst_OpEndPrimitive :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpEndPrimitive), result = {id = ID_NONE}}
}

end_primitive :: proc(b: ^Builder) {
	append(&b.ops, inst_OpEndPrimitive())
}

inst_OpEmitStreamVertex :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpEmitStreamVertex), result = {id = ID_NONE}, operands = buf[:n]}
}

emit_stream_vertex :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpEmitStreamVertex(opbuf(b, 1), op1))
}

inst_OpEndStreamPrimitive :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpEndStreamPrimitive), result = {id = ID_NONE}, operands = buf[:n]}
}

end_stream_primitive :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpEndStreamPrimitive(opbuf(b, 1), op1))
}

inst_OpControlBarrier :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpControlBarrier), result = {id = ID_NONE}, operands = buf[:n]}
}

control_barrier :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpControlBarrier(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpMemoryBarrier :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpMemoryBarrier), result = {id = ID_NONE}, operands = buf[:n]}
}

memory_barrier :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpMemoryBarrier(opbuf(b, 1 + 1), op1, op2))
}

inst_OpAtomicLoad :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicLoad), result = {result, result_type}, operands = buf[:n]}
}

atomic_load :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicLoad(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpAtomicStore :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicStore), result = {id = ID_NONE}, operands = buf[:n]}
}

atomic_store :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id) {
	append(&b.ops, inst_OpAtomicStore(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpAtomicExchange :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicExchange), result = {result, result_type}, operands = buf[:n]}
}

atomic_exchange :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicExchange(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicCompareExchange :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicCompareExchange), result = {result, result_type}, operands = buf[:n]}
}

atomic_compare_exchange :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicCompareExchange(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpAtomicCompareExchangeWeak :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicCompareExchangeWeak), result = {result, result_type}, operands = buf[:n]}
}

atomic_compare_exchange_weak :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicCompareExchangeWeak(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpAtomicIIncrement :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicIIncrement), result = {result, result_type}, operands = buf[:n]}
}

atomic_i_increment :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicIIncrement(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpAtomicIDecrement :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicIDecrement), result = {result, result_type}, operands = buf[:n]}
}

atomic_i_decrement :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicIDecrement(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpAtomicIAdd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicIAdd), result = {result, result_type}, operands = buf[:n]}
}

atomic_i_add :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicIAdd(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicISub :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicISub), result = {result, result_type}, operands = buf[:n]}
}

atomic_i_sub :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicISub(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicSMin :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicSMin), result = {result, result_type}, operands = buf[:n]}
}

atomic_s_min :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicSMin(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicUMin :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicUMin), result = {result, result_type}, operands = buf[:n]}
}

atomic_u_min :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicUMin(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicSMax :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicSMax), result = {result, result_type}, operands = buf[:n]}
}

atomic_s_max :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicSMax(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicUMax :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicUMax), result = {result, result_type}, operands = buf[:n]}
}

atomic_u_max :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicUMax(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicAnd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicAnd), result = {result, result_type}, operands = buf[:n]}
}

atomic_and :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicAnd(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicOr :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicOr), result = {result, result_type}, operands = buf[:n]}
}

atomic_or :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicOr(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicXor :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicXor), result = {result, result_type}, operands = buf[:n]}
}

atomic_xor :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicXor(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpPhi :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []Pair_Id_Id) -> Operation {
	n := 0
	for p in op1 { buf[n] = op_value(p.a); buf[n + 1] = op_value(p.b); n += 2 }
	return Operation{opcode = u16(Opcode.OpPhi), result = {result, result_type}, operands = buf[:n]}
}

phi :: proc(b: ^Builder, result_type: Type_Ref, op1: []Pair_Id_Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPhi(opbuf(b, 2 * len(op1)), result_type, r, op1))
	return r
}

inst_OpLoopMerge :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Loop_Control) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_int(i64(transmute(u32)op3)); n += 1
	return Operation{opcode = u16(Opcode.OpLoopMerge), result = {id = ID_NONE}, operands = buf[:n]}
}

loop_merge :: proc(b: ^Builder, op1: Id, op2: Id, op3: Loop_Control) {
	append(&b.ops, inst_OpLoopMerge(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpSelectionMerge :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Selection_Control) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(transmute(u32)op2)); n += 1
	return Operation{opcode = u16(Opcode.OpSelectionMerge), result = {id = ID_NONE}, operands = buf[:n]}
}

selection_merge :: proc(b: ^Builder, op1: Id, op2: Selection_Control) {
	append(&b.ops, inst_OpSelectionMerge(opbuf(b, 1 + 1), op1, op2))
}

inst_OpLabel :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpLabel), result = {id = result}}
}

label :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpLabel(r))
	return r
}

inst_OpBranch :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpBranch), result = {id = ID_NONE}, operands = buf[:n]}
}

branch :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpBranch(opbuf(b, 1), op1))
}

inst_OpBranchConditional :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: []i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	for x in op4 { buf[n] = op_int(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpBranchConditional), result = {id = ID_NONE}, operands = buf[:n]}
}

branch_conditional :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: []i64) {
	append(&b.ops, inst_OpBranchConditional(opbuf(b, 1 + 1 + 1 + len(op4)), op1, op2, op3, op4))
}

inst_OpSwitch :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: []Pair_Lit_Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for p in op3 { buf[n] = op_int(p.lit); buf[n + 1] = op_value(p.id); n += 2 }
	return Operation{opcode = u16(Opcode.OpSwitch), result = {id = ID_NONE}, operands = buf[:n]}
}

switch_ :: proc(b: ^Builder, op1: Id, op2: Id, op3: []Pair_Lit_Id) {
	append(&b.ops, inst_OpSwitch(opbuf(b, 1 + 1 + 2 * len(op3)), op1, op2, op3))
}

inst_OpKill :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpKill), result = {id = ID_NONE}}
}

kill :: proc(b: ^Builder) {
	append(&b.ops, inst_OpKill())
}

inst_OpReturn :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpReturn), result = {id = ID_NONE}}
}

return_ :: proc(b: ^Builder) {
	append(&b.ops, inst_OpReturn())
}

inst_OpReturnValue :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpReturnValue), result = {id = ID_NONE}, operands = buf[:n]}
}

return_value :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpReturnValue(opbuf(b, 1), op1))
}

inst_OpUnreachable :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpUnreachable), result = {id = ID_NONE}}
}

unreachable :: proc(b: ^Builder) {
	append(&b.ops, inst_OpUnreachable())
}

inst_OpLifetimeStart :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	return Operation{opcode = u16(Opcode.OpLifetimeStart), result = {id = ID_NONE}, operands = buf[:n]}
}

lifetime_start :: proc(b: ^Builder, op1: Id, op2: i64) {
	append(&b.ops, inst_OpLifetimeStart(opbuf(b, 1 + 1), op1, op2))
}

inst_OpLifetimeStop :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	return Operation{opcode = u16(Opcode.OpLifetimeStop), result = {id = ID_NONE}, operands = buf[:n]}
}

lifetime_stop :: proc(b: ^Builder, op1: Id, op2: i64) {
	append(&b.ops, inst_OpLifetimeStop(opbuf(b, 1 + 1), op1, op2))
}

inst_OpGroupAsyncCopy :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	return Operation{opcode = u16(Opcode.OpGroupAsyncCopy), result = {result, result_type}, operands = buf[:n]}
}

group_async_copy :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupAsyncCopy(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpGroupWaitEvents :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupWaitEvents), result = {id = ID_NONE}, operands = buf[:n]}
}

group_wait_events :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpGroupWaitEvents(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpGroupAll :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupAll), result = {result, result_type}, operands = buf[:n]}
}

group_all :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupAll(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupAny :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupAny), result = {result, result_type}, operands = buf[:n]}
}

group_any :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupAny(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupBroadcast :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupBroadcast), result = {result, result_type}, operands = buf[:n]}
}

group_broadcast :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupBroadcast(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupIAdd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupIAdd), result = {result, result_type}, operands = buf[:n]}
}

group_i_add :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupIAdd(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupFAdd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupFAdd), result = {result, result_type}, operands = buf[:n]}
}

group_f_add :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupFAdd(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupFMin :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupFMin), result = {result, result_type}, operands = buf[:n]}
}

group_f_min :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupFMin(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupUMin :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupUMin), result = {result, result_type}, operands = buf[:n]}
}

group_u_min :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupUMin(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupSMin :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupSMin), result = {result, result_type}, operands = buf[:n]}
}

group_s_min :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupSMin(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupFMax :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupFMax), result = {result, result_type}, operands = buf[:n]}
}

group_f_max :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupFMax(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupUMax :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupUMax), result = {result, result_type}, operands = buf[:n]}
}

group_u_max :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupUMax(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupSMax :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupSMax), result = {result, result_type}, operands = buf[:n]}
}

group_s_max :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupSMax(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpReadPipe :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpReadPipe), result = {result, result_type}, operands = buf[:n]}
}

read_pipe :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpReadPipe(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpWritePipe :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpWritePipe), result = {result, result_type}, operands = buf[:n]}
}

write_pipe :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpWritePipe(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpReservedReadPipe :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	return Operation{opcode = u16(Opcode.OpReservedReadPipe), result = {result, result_type}, operands = buf[:n]}
}

reserved_read_pipe :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpReservedReadPipe(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpReservedWritePipe :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	return Operation{opcode = u16(Opcode.OpReservedWritePipe), result = {result, result_type}, operands = buf[:n]}
}

reserved_write_pipe :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpReservedWritePipe(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpReserveReadPipePackets :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpReserveReadPipePackets), result = {result, result_type}, operands = buf[:n]}
}

reserve_read_pipe_packets :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpReserveReadPipePackets(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpReserveWritePipePackets :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpReserveWritePipePackets), result = {result, result_type}, operands = buf[:n]}
}

reserve_write_pipe_packets :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpReserveWritePipePackets(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpCommitReadPipe :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpCommitReadPipe), result = {id = ID_NONE}, operands = buf[:n]}
}

commit_read_pipe :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id) {
	append(&b.ops, inst_OpCommitReadPipe(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpCommitWritePipe :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpCommitWritePipe), result = {id = ID_NONE}, operands = buf[:n]}
}

commit_write_pipe :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id) {
	append(&b.ops, inst_OpCommitWritePipe(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpIsValidReserveId :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpIsValidReserveId), result = {result, result_type}, operands = buf[:n]}
}

is_valid_reserve_id :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIsValidReserveId(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpGetNumPipePackets :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGetNumPipePackets), result = {result, result_type}, operands = buf[:n]}
}

get_num_pipe_packets :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetNumPipePackets(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGetMaxPipePackets :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGetMaxPipePackets), result = {result, result_type}, operands = buf[:n]}
}

get_max_pipe_packets :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetMaxPipePackets(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupReserveReadPipePackets :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpGroupReserveReadPipePackets), result = {result, result_type}, operands = buf[:n]}
}

group_reserve_read_pipe_packets :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupReserveReadPipePackets(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpGroupReserveWritePipePackets :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpGroupReserveWritePipePackets), result = {result, result_type}, operands = buf[:n]}
}

group_reserve_write_pipe_packets :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupReserveWritePipePackets(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpGroupCommitReadPipe :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpGroupCommitReadPipe), result = {id = ID_NONE}, operands = buf[:n]}
}

group_commit_read_pipe :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) {
	append(&b.ops, inst_OpGroupCommitReadPipe(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpGroupCommitWritePipe :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpGroupCommitWritePipe), result = {id = ID_NONE}, operands = buf[:n]}
}

group_commit_write_pipe :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) {
	append(&b.ops, inst_OpGroupCommitWritePipe(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpEnqueueMarker :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpEnqueueMarker), result = {result, result_type}, operands = buf[:n]}
}

enqueue_marker :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpEnqueueMarker(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpEnqueueKernel :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	for x in op11 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpEnqueueKernel), result = {result, result_type}, operands = buf[:n]}
}

enqueue_kernel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpEnqueueKernel(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + len(op11)), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11))
	return r
}

inst_OpGetKernelNDrangeSubGroupCount :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpGetKernelNDrangeSubGroupCount), result = {result, result_type}, operands = buf[:n]}
}

get_kernel_n_drange_sub_group_count :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetKernelNDrangeSubGroupCount(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpGetKernelNDrangeMaxSubGroupSize :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpGetKernelNDrangeMaxSubGroupSize), result = {result, result_type}, operands = buf[:n]}
}

get_kernel_n_drange_max_sub_group_size :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetKernelNDrangeMaxSubGroupSize(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpGetKernelWorkGroupSize :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpGetKernelWorkGroupSize), result = {result, result_type}, operands = buf[:n]}
}

get_kernel_work_group_size :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetKernelWorkGroupSize(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGetKernelPreferredWorkGroupSizeMultiple :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpGetKernelPreferredWorkGroupSizeMultiple), result = {result, result_type}, operands = buf[:n]}
}

get_kernel_preferred_work_group_size_multiple :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetKernelPreferredWorkGroupSizeMultiple(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpRetainEvent :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRetainEvent), result = {id = ID_NONE}, operands = buf[:n]}
}

retain_event :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpRetainEvent(opbuf(b, 1), op1))
}

inst_OpReleaseEvent :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpReleaseEvent), result = {id = ID_NONE}, operands = buf[:n]}
}

release_event :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpReleaseEvent(opbuf(b, 1), op1))
}

inst_OpCreateUserEvent :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpCreateUserEvent), result = {result, result_type}}
}

create_user_event :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCreateUserEvent(result_type, r))
	return r
}

inst_OpIsValidEvent :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpIsValidEvent), result = {result, result_type}, operands = buf[:n]}
}

is_valid_event :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIsValidEvent(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSetUserEventStatus :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSetUserEventStatus), result = {id = ID_NONE}, operands = buf[:n]}
}

set_user_event_status :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpSetUserEventStatus(opbuf(b, 1 + 1), op1, op2))
}

inst_OpCaptureEventProfilingInfo :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpCaptureEventProfilingInfo), result = {id = ID_NONE}, operands = buf[:n]}
}

capture_event_profiling_info :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpCaptureEventProfilingInfo(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpGetDefaultQueue :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpGetDefaultQueue), result = {result, result_type}}
}

get_default_queue :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetDefaultQueue(result_type, r))
	return r
}

inst_OpBuildNDRange :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpBuildNDRange), result = {result, result_type}, operands = buf[:n]}
}

build_nd_range :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBuildNDRange(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSparseSampleImplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSparseSampleImplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_sample_implicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseSampleImplicitLod(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSparseSampleExplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Image_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_int(i64(transmute(u32)op3)); n += 1
	return Operation{opcode = u16(Opcode.OpImageSparseSampleExplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_sample_explicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Image_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseSampleExplicitLod(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSparseSampleDrefImplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSparseSampleDrefImplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_sample_dref_implicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseSampleDrefImplicitLod(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSparseSampleDrefExplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Image_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(i64(transmute(u32)op4)); n += 1
	return Operation{opcode = u16(Opcode.OpImageSparseSampleDrefExplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_sample_dref_explicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Image_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseSampleDrefExplicitLod(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSparseSampleProjImplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSparseSampleProjImplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_sample_proj_implicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseSampleProjImplicitLod(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSparseSampleProjExplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Image_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_int(i64(transmute(u32)op3)); n += 1
	return Operation{opcode = u16(Opcode.OpImageSparseSampleProjExplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_sample_proj_explicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Image_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseSampleProjExplicitLod(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSparseSampleProjDrefImplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSparseSampleProjDrefImplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_sample_proj_dref_implicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseSampleProjDrefImplicitLod(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSparseSampleProjDrefExplicitLod :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Image_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(i64(transmute(u32)op4)); n += 1
	return Operation{opcode = u16(Opcode.OpImageSparseSampleProjDrefExplicitLod), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_sample_proj_dref_explicit_lod :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Image_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseSampleProjDrefExplicitLod(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSparseFetch :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSparseFetch), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_fetch :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseFetch(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageSparseGather :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSparseGather), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_gather :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseGather(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSparseDrefGather :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSparseDrefGather), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_dref_gather :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseDrefGather(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpImageSparseTexelsResident :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpImageSparseTexelsResident), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_texels_resident :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseTexelsResident(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpNoLine :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpNoLine), result = {id = ID_NONE}}
}

no_line :: proc(b: ^Builder) {
	append(&b.ops, inst_OpNoLine())
}

inst_OpAtomicFlagTestAndSet :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicFlagTestAndSet), result = {result, result_type}, operands = buf[:n]}
}

atomic_flag_test_and_set :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicFlagTestAndSet(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpAtomicFlagClear :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicFlagClear), result = {id = ID_NONE}, operands = buf[:n]}
}

atomic_flag_clear :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpAtomicFlagClear(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpImageSparseRead :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSparseRead), result = {result, result_type}, operands = buf[:n]}
}

image_sparse_read :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSparseRead(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSizeOf :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSizeOf), result = {result, result_type}, operands = buf[:n]}
}

size_of_ :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSizeOf(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpTypePipeStorage :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypePipeStorage), result = {id = result}}
}

type_pipe_storage :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypePipeStorage(r))
	return r
}

inst_OpConstantPipeStorage :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: i64, op2: i64, op3: i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	return Operation{opcode = u16(Opcode.OpConstantPipeStorage), result = {result, result_type}, operands = buf[:n]}
}

constant_pipe_storage :: proc(b: ^Builder, result_type: Type_Ref, op1: i64, op2: i64, op3: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantPipeStorage(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpCreatePipeFromPipeStorage :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCreatePipeFromPipeStorage), result = {result, result_type}, operands = buf[:n]}
}

create_pipe_from_pipe_storage :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCreatePipeFromPipeStorage(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpGetKernelLocalSizeForSubgroupCount :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpGetKernelLocalSizeForSubgroupCount), result = {result, result_type}, operands = buf[:n]}
}

get_kernel_local_size_for_subgroup_count :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetKernelLocalSizeForSubgroupCount(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpGetKernelMaxNumSubgroups :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpGetKernelMaxNumSubgroups), result = {result, result_type}, operands = buf[:n]}
}

get_kernel_max_num_subgroups :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGetKernelMaxNumSubgroups(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpTypeNamedBarrier :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeNamedBarrier), result = {id = result}}
}

type_named_barrier :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeNamedBarrier(r))
	return r
}

inst_OpNamedBarrierInitialize :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpNamedBarrierInitialize), result = {result, result_type}, operands = buf[:n]}
}

named_barrier_initialize :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpNamedBarrierInitialize(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpMemoryNamedBarrier :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpMemoryNamedBarrier), result = {id = ID_NONE}, operands = buf[:n]}
}

memory_named_barrier :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpMemoryNamedBarrier(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpModuleProcessed :: #force_inline proc "contextless" (buf: []Operand, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpModuleProcessed), result = {id = ID_NONE}, operands = buf[:n]}
}

module_processed :: proc(b: ^Builder, op1: string) {
	append(&b.ops, inst_OpModuleProcessed(opbuf(b, (len(op1) + 4) / 4), op1))
}

inst_OpExecutionModeId :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Execution_Mode) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpExecutionModeId), result = {id = ID_NONE}, operands = buf[:n]}
}

execution_mode_id :: proc(b: ^Builder, op1: Id, op2: Execution_Mode) {
	append(&b.ops, inst_OpExecutionModeId(opbuf(b, 1 + 1), op1, op2))
}

inst_OpDecorateId :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Decoration) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpDecorateId), result = {id = ID_NONE}, operands = buf[:n]}
}

decorate_id :: proc(b: ^Builder, op1: Id, op2: Decoration) {
	append(&b.ops, inst_OpDecorateId(opbuf(b, 1 + 1), op1, op2))
}

inst_OpGroupNonUniformElect :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformElect), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_elect :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformElect(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpGroupNonUniformAll :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformAll), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_all :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformAll(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupNonUniformAny :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformAny), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_any :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformAny(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupNonUniformAllEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformAllEqual), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_all_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformAllEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupNonUniformBroadcast :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBroadcast), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_broadcast :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBroadcast(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupNonUniformBroadcastFirst :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBroadcastFirst), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_broadcast_first :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBroadcastFirst(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupNonUniformBallot :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBallot), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_ballot :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBallot(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupNonUniformInverseBallot :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformInverseBallot), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_inverse_ballot :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformInverseBallot(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupNonUniformBallotBitExtract :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBallotBitExtract), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_ballot_bit_extract :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBallotBitExtract(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupNonUniformBallotBitCount :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBallotBitCount), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_ballot_bit_count :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBallotBitCount(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupNonUniformBallotFindLSB :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBallotFindLSB), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_ballot_find_lsb :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBallotFindLSB(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupNonUniformBallotFindMSB :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBallotFindMSB), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_ballot_find_msb :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBallotFindMSB(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupNonUniformShuffle :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformShuffle), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_shuffle :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformShuffle(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupNonUniformShuffleXor :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformShuffleXor), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_shuffle_xor :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformShuffleXor(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupNonUniformShuffleUp :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformShuffleUp), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_shuffle_up :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformShuffleUp(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupNonUniformShuffleDown :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformShuffleDown), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_shuffle_down :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformShuffleDown(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupNonUniformIAdd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformIAdd), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_i_add :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformIAdd(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformFAdd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformFAdd), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_f_add :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformFAdd(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformIMul :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformIMul), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_i_mul :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformIMul(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformFMul :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformFMul), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_f_mul :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformFMul(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformSMin :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformSMin), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_s_min :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformSMin(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformUMin :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformUMin), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_u_min :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformUMin(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformFMin :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformFMin), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_f_min :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformFMin(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformSMax :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformSMax), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_s_max :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformSMax(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformUMax :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformUMax), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_u_max :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformUMax(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformFMax :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformFMax), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_f_max :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformFMax(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformBitwiseAnd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBitwiseAnd), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_bitwise_and :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBitwiseAnd(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformBitwiseOr :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBitwiseOr), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_bitwise_or :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBitwiseOr(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformBitwiseXor :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformBitwiseXor), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_bitwise_xor :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformBitwiseXor(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformLogicalAnd :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformLogicalAnd), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_logical_and :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformLogicalAnd(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformLogicalOr :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformLogicalOr), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_logical_or :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformLogicalOr(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformLogicalXor :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformLogicalXor), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_logical_xor :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformLogicalXor(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpGroupNonUniformQuadBroadcast :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformQuadBroadcast), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_quad_broadcast :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformQuadBroadcast(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupNonUniformQuadSwap :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformQuadSwap), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_quad_swap :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformQuadSwap(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpCopyLogical :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCopyLogical), result = {result, result_type}, operands = buf[:n]}
}

copy_logical :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCopyLogical(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpPtrEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpPtrEqual), result = {result, result_type}, operands = buf[:n]}
}

ptr_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPtrEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpPtrNotEqual :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpPtrNotEqual), result = {result, result_type}, operands = buf[:n]}
}

ptr_not_equal :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPtrNotEqual(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpPtrDiff :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpPtrDiff), result = {result, result_type}, operands = buf[:n]}
}

ptr_diff :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPtrDiff(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpColorAttachmentReadEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	if x, xok := op2.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpColorAttachmentReadEXT), result = {result, result_type}, operands = buf[:n]}
}

color_attachment_read_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpColorAttachmentReadEXT(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpDepthAttachmentReadEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Maybe(Id)) -> Operation {
	n := 0
	if x, xok := op1.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpDepthAttachmentReadEXT), result = {result, result_type}, operands = buf[:n]}
}

depth_attachment_read_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpDepthAttachmentReadEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpStencilAttachmentReadEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Maybe(Id)) -> Operation {
	n := 0
	if x, xok := op1.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpStencilAttachmentReadEXT), result = {result, result_type}, operands = buf[:n]}
}

stencil_attachment_read_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpStencilAttachmentReadEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpTypeTensorARM :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Maybe(Id), op3: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	if x, xok := op2.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op3.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTypeTensorARM), result = {id = result}, operands = buf[:n]}
}

type_tensor_arm :: proc(b: ^Builder, op1: Id, op2: Maybe(Id), op3: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeTensorARM(opbuf(b, 1 + 1 + 1), r, op1, op2, op3))
	return r
}

inst_OpTensorReadARM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Tensor_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpTensorReadARM), result = {result, result_type}, operands = buf[:n]}
}

tensor_read_arm :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Tensor_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorReadARM(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpTensorWriteARM :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Maybe(Tensor_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpTensorWriteARM), result = {id = ID_NONE}, operands = buf[:n]}
}

tensor_write_arm :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Maybe(Tensor_Operands)) {
	append(&b.ops, inst_OpTensorWriteARM(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpTensorQuerySizeARM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTensorQuerySizeARM), result = {result, result_type}, operands = buf[:n]}
}

tensor_query_size_arm :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorQuerySizeARM(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGraphConstantARM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	return Operation{opcode = u16(Opcode.OpGraphConstantARM), result = {result, result_type}, operands = buf[:n]}
}

graph_constant_arm :: proc(b: ^Builder, result_type: Type_Ref, op1: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGraphConstantARM(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpGraphEntryPointARM :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: string, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	n += pack_string_operands(buf[n:], op2)
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGraphEntryPointARM), result = {id = ID_NONE}, operands = buf[:n]}
}

graph_entry_point_arm :: proc(b: ^Builder, op1: Id, op2: string, op3: []Id) {
	append(&b.ops, inst_OpGraphEntryPointARM(opbuf(b, 1 + (len(op2) + 4) / 4 + len(op3)), op1, op2, op3))
}

inst_OpGraphARM :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpGraphARM), result = {result, result_type}}
}

graph_arm :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGraphARM(result_type, r))
	return r
}

inst_OpGraphInputARM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGraphInputARM), result = {result, result_type}, operands = buf[:n]}
}

graph_input_arm :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGraphInputARM(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpGraphSetOutputARM :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGraphSetOutputARM), result = {id = ID_NONE}, operands = buf[:n]}
}

graph_set_output_arm :: proc(b: ^Builder, op1: Id, op2: Id, op3: []Id) {
	append(&b.ops, inst_OpGraphSetOutputARM(opbuf(b, 1 + 1 + len(op3)), op1, op2, op3))
}

inst_OpGraphEndARM :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpGraphEndARM), result = {id = ID_NONE}}
}

graph_end_arm :: proc(b: ^Builder) {
	append(&b.ops, inst_OpGraphEndARM())
}

inst_OpTypeGraphARM :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: i64, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTypeGraphARM), result = {id = result}, operands = buf[:n]}
}

type_graph_arm :: proc(b: ^Builder, op1: i64, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeGraphARM(opbuf(b, 1 + len(op2)), r, op1, op2))
	return r
}

inst_OpTerminateInvocation :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpTerminateInvocation), result = {id = ID_NONE}}
}

terminate_invocation :: proc(b: ^Builder) {
	append(&b.ops, inst_OpTerminateInvocation())
}

inst_OpTypeUntypedPointerKHR :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Storage_Class) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	return Operation{opcode = u16(Opcode.OpTypeUntypedPointerKHR), result = {id = result}, operands = buf[:n]}
}

type_untyped_pointer_khr :: proc(b: ^Builder, op1: Storage_Class) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeUntypedPointerKHR(opbuf(b, 1), r, op1))
	return r
}

inst_OpUntypedVariableKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Storage_Class, op2: Maybe(Id), op3: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	if x, xok := op2.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op3.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpUntypedVariableKHR), result = {result, result_type}, operands = buf[:n]}
}

untyped_variable_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Storage_Class, op2: Maybe(Id), op3: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedVariableKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpUntypedAccessChainKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpUntypedAccessChainKHR), result = {result, result_type}, operands = buf[:n]}
}

untyped_access_chain_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedAccessChainKHR(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpUntypedInBoundsAccessChainKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpUntypedInBoundsAccessChainKHR), result = {result, result_type}, operands = buf[:n]}
}

untyped_in_bounds_access_chain_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedInBoundsAccessChainKHR(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupBallotKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupBallotKHR), result = {result, result_type}, operands = buf[:n]}
}

subgroup_ballot_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupBallotKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupFirstInvocationKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupFirstInvocationKHR), result = {result, result_type}, operands = buf[:n]}
}

subgroup_first_invocation_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupFirstInvocationKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpUntypedPtrAccessChainKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	for x in op4 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpUntypedPtrAccessChainKHR), result = {result, result_type}, operands = buf[:n]}
}

untyped_ptr_access_chain_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedPtrAccessChainKHR(opbuf(b, 1 + 1 + 1 + len(op4)), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpUntypedInBoundsPtrAccessChainKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	for x in op4 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpUntypedInBoundsPtrAccessChainKHR), result = {result, result_type}, operands = buf[:n]}
}

untyped_in_bounds_ptr_access_chain_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedInBoundsPtrAccessChainKHR(opbuf(b, 1 + 1 + 1 + len(op4)), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpUntypedArrayLengthKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_int(op3); n += 1
	return Operation{opcode = u16(Opcode.OpUntypedArrayLengthKHR), result = {result, result_type}, operands = buf[:n]}
}

untyped_array_length_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedArrayLengthKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpUntypedPrefetchKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Maybe(Id), op4: Maybe(Id), op5: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op5.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpUntypedPrefetchKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

untyped_prefetch_khr :: proc(b: ^Builder, op1: Id, op2: Id, op3: Maybe(Id), op4: Maybe(Id), op5: Maybe(Id)) {
	append(&b.ops, inst_OpUntypedPrefetchKHR(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpFmaKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpFmaKHR), result = {result, result_type}, operands = buf[:n]}
}

fma_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFmaKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAllKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAllKHR), result = {result, result_type}, operands = buf[:n]}
}

subgroup_all_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAllKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAnyKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAnyKHR), result = {result, result_type}, operands = buf[:n]}
}

subgroup_any_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAnyKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAllEqualKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAllEqualKHR), result = {result, result_type}, operands = buf[:n]}
}

subgroup_all_equal_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAllEqualKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpGroupNonUniformRotateKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpGroupNonUniformRotateKHR), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_rotate_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformRotateKHR(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupReadInvocationKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupReadInvocationKHR), result = {result, result_type}, operands = buf[:n]}
}

subgroup_read_invocation_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupReadInvocationKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpExtInstWithForwardRefsKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpExtInstWithForwardRefsKHR), result = {result, result_type}, operands = buf[:n]}
}

ext_inst_with_forward_refs_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpExtInstWithForwardRefsKHR(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpUntypedGroupAsyncCopyKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Maybe(Memory_Access), op9: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	if x, xok := op8.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	if x, xok := op9.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpUntypedGroupAsyncCopyKHR), result = {result, result_type}, operands = buf[:n]}
}

untyped_group_async_copy_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Maybe(Memory_Access), op9: Maybe(Memory_Access)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedGroupAsyncCopyKHR(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8, op9))
	return r
}

inst_OpTraceRayKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	return Operation{opcode = u16(Opcode.OpTraceRayKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

trace_ray_khr :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id) {
	append(&b.ops, inst_OpTraceRayKHR(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11))
}

inst_OpExecuteCallableKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpExecuteCallableKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

execute_callable_khr :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpExecuteCallableKHR(opbuf(b, 1 + 1), op1, op2))
}

inst_OpConvertUToAccelerationStructureKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertUToAccelerationStructureKHR), result = {result, result_type}, operands = buf[:n]}
}

convert_u_to_acceleration_structure_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertUToAccelerationStructureKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpIgnoreIntersectionKHR :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpIgnoreIntersectionKHR), result = {id = ID_NONE}}
}

ignore_intersection_khr :: proc(b: ^Builder) {
	append(&b.ops, inst_OpIgnoreIntersectionKHR())
}

inst_OpTerminateRayKHR :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpTerminateRayKHR), result = {id = ID_NONE}}
}

terminate_ray_khr :: proc(b: ^Builder) {
	append(&b.ops, inst_OpTerminateRayKHR())
}

inst_OpSDot :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Packed_Vector_Format)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpSDot), result = {result, result_type}, operands = buf[:n]}
}

s_dot :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Packed_Vector_Format)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSDot(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpUDot :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Packed_Vector_Format)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpUDot), result = {result, result_type}, operands = buf[:n]}
}

u_dot :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Packed_Vector_Format)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUDot(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSUDot :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Packed_Vector_Format)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpSUDot), result = {result, result_type}, operands = buf[:n]}
}

su_dot :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Packed_Vector_Format)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSUDot(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSDotAccSat :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Packed_Vector_Format)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpSDotAccSat), result = {result, result_type}, operands = buf[:n]}
}

s_dot_acc_sat :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Packed_Vector_Format)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSDotAccSat(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpUDotAccSat :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Packed_Vector_Format)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpUDotAccSat), result = {result, result_type}, operands = buf[:n]}
}

u_dot_acc_sat :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Packed_Vector_Format)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUDotAccSat(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSUDotAccSat :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Packed_Vector_Format)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpSUDotAccSat), result = {result, result_type}, operands = buf[:n]}
}

su_dot_acc_sat :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Packed_Vector_Format)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSUDotAccSat(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpTypeCooperativeMatrixKHR :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpTypeCooperativeMatrixKHR), result = {id = result}, operands = buf[:n]}
}

type_cooperative_matrix_khr :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeCooperativeMatrixKHR(opbuf(b, 1 + 1 + 1 + 1 + 1), r, op1, op2, op3, op4, op5))
	return r
}

inst_OpCooperativeMatrixLoadKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Id), op4: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixLoadKHR), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_load_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Id), op4: Maybe(Memory_Access)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixLoadKHR(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpCooperativeMatrixStoreKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Maybe(Id), op5: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op5.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixStoreKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

cooperative_matrix_store_khr :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Maybe(Id), op5: Maybe(Memory_Access)) {
	append(&b.ops, inst_OpCooperativeMatrixStoreKHR(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpCooperativeMatrixMulAddKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Cooperative_Matrix_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixMulAddKHR), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_mul_add_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Cooperative_Matrix_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixMulAddKHR(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpCooperativeMatrixLengthKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixLengthKHR), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_length_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixLengthKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConstantCompositeReplicateEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConstantCompositeReplicateEXT), result = {result, result_type}, operands = buf[:n]}
}

constant_composite_replicate_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantCompositeReplicateEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSpecConstantCompositeReplicateEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSpecConstantCompositeReplicateEXT), result = {result, result_type}, operands = buf[:n]}
}

spec_constant_composite_replicate_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantCompositeReplicateEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpCompositeConstructReplicateEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCompositeConstructReplicateEXT), result = {result, result_type}, operands = buf[:n]}
}

composite_construct_replicate_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCompositeConstructReplicateEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpTypeRayQueryKHR :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeRayQueryKHR), result = {id = result}}
}

type_ray_query_khr :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeRayQueryKHR(r))
	return r
}

inst_OpRayQueryInitializeKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryInitializeKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

ray_query_initialize_khr :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id) {
	append(&b.ops, inst_OpRayQueryInitializeKHR(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8))
}

inst_OpRayQueryTerminateKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryTerminateKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

ray_query_terminate_khr :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpRayQueryTerminateKHR(opbuf(b, 1), op1))
}

inst_OpRayQueryGenerateIntersectionKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGenerateIntersectionKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

ray_query_generate_intersection_khr :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpRayQueryGenerateIntersectionKHR(opbuf(b, 1 + 1), op1, op2))
}

inst_OpRayQueryConfirmIntersectionKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryConfirmIntersectionKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

ray_query_confirm_intersection_khr :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpRayQueryConfirmIntersectionKHR(opbuf(b, 1), op1))
}

inst_OpRayQueryProceedKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryProceedKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_proceed_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryProceedKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpRayQueryGetIntersectionTypeKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionTypeKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_type_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionTypeKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpImageSampleWeightedQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpImageSampleWeightedQCOM), result = {result, result_type}, operands = buf[:n]}
}

image_sample_weighted_qcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleWeightedQCOM(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageBoxFilterQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpImageBoxFilterQCOM), result = {result, result_type}, operands = buf[:n]}
}

image_box_filter_qcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageBoxFilterQCOM(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpImageBlockMatchSSDQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpImageBlockMatchSSDQCOM), result = {result, result_type}, operands = buf[:n]}
}

image_block_match_ssdqcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageBlockMatchSSDQCOM(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpImageBlockMatchSADQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpImageBlockMatchSADQCOM), result = {result, result_type}, operands = buf[:n]}
}

image_block_match_sadqcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageBlockMatchSADQCOM(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpBitCastArrayQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpBitCastArrayQCOM), result = {result, result_type}, operands = buf[:n]}
}

bit_cast_array_qcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitCastArrayQCOM(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpImageBlockMatchWindowSSDQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpImageBlockMatchWindowSSDQCOM), result = {result, result_type}, operands = buf[:n]}
}

image_block_match_window_ssdqcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageBlockMatchWindowSSDQCOM(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpImageBlockMatchWindowSADQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpImageBlockMatchWindowSADQCOM), result = {result, result_type}, operands = buf[:n]}
}

image_block_match_window_sadqcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageBlockMatchWindowSADQCOM(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpImageBlockMatchGatherSSDQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpImageBlockMatchGatherSSDQCOM), result = {result, result_type}, operands = buf[:n]}
}

image_block_match_gather_ssdqcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageBlockMatchGatherSSDQCOM(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpImageBlockMatchGatherSADQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpImageBlockMatchGatherSADQCOM), result = {result, result_type}, operands = buf[:n]}
}

image_block_match_gather_sadqcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageBlockMatchGatherSADQCOM(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpCompositeConstructCoopMatQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCompositeConstructCoopMatQCOM), result = {result, result_type}, operands = buf[:n]}
}

composite_construct_coop_mat_qcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCompositeConstructCoopMatQCOM(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpCompositeExtractCoopMatQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCompositeExtractCoopMatQCOM), result = {result, result_type}, operands = buf[:n]}
}

composite_extract_coop_mat_qcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCompositeExtractCoopMatQCOM(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpExtractSubArrayQCOM :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpExtractSubArrayQCOM), result = {result, result_type}, operands = buf[:n]}
}

extract_sub_array_qcom :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpExtractSubArrayQCOM(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpGroupIAddNonUniformAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupIAddNonUniformAMD), result = {result, result_type}, operands = buf[:n]}
}

group_i_add_non_uniform_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupIAddNonUniformAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupFAddNonUniformAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupFAddNonUniformAMD), result = {result, result_type}, operands = buf[:n]}
}

group_f_add_non_uniform_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupFAddNonUniformAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupFMinNonUniformAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupFMinNonUniformAMD), result = {result, result_type}, operands = buf[:n]}
}

group_f_min_non_uniform_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupFMinNonUniformAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupUMinNonUniformAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupUMinNonUniformAMD), result = {result, result_type}, operands = buf[:n]}
}

group_u_min_non_uniform_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupUMinNonUniformAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupSMinNonUniformAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupSMinNonUniformAMD), result = {result, result_type}, operands = buf[:n]}
}

group_s_min_non_uniform_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupSMinNonUniformAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupFMaxNonUniformAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupFMaxNonUniformAMD), result = {result, result_type}, operands = buf[:n]}
}

group_f_max_non_uniform_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupFMaxNonUniformAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupUMaxNonUniformAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupUMaxNonUniformAMD), result = {result, result_type}, operands = buf[:n]}
}

group_u_max_non_uniform_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupUMaxNonUniformAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupSMaxNonUniformAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupSMaxNonUniformAMD), result = {result, result_type}, operands = buf[:n]}
}

group_s_max_non_uniform_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupSMaxNonUniformAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpFragmentMaskFetchAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpFragmentMaskFetchAMD), result = {result, result_type}, operands = buf[:n]}
}

fragment_mask_fetch_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFragmentMaskFetchAMD(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpFragmentFetchAMD :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpFragmentFetchAMD), result = {result, result_type}, operands = buf[:n]}
}

fragment_fetch_amd :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFragmentFetchAMD(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpReadClockKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpReadClockKHR), result = {result, result_type}, operands = buf[:n]}
}

read_clock_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpReadClockKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpAllocateNodePayloadsAMDX :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpAllocateNodePayloadsAMDX), result = {result, result_type}, operands = buf[:n]}
}

allocate_node_payloads_amdx :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAllocateNodePayloadsAMDX(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpEnqueueNodePayloadsAMDX :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpEnqueueNodePayloadsAMDX), result = {id = ID_NONE}, operands = buf[:n]}
}

enqueue_node_payloads_amdx :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpEnqueueNodePayloadsAMDX(opbuf(b, 1), op1))
}

inst_OpTypeNodePayloadArrayAMDX :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpTypeNodePayloadArrayAMDX), result = {id = result}, operands = buf[:n]}
}

type_node_payload_array_amdx :: proc(b: ^Builder, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeNodePayloadArrayAMDX(opbuf(b, 1), r, op1))
	return r
}

inst_OpFinishWritingNodePayloadAMDX :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpFinishWritingNodePayloadAMDX), result = {result, result_type}, operands = buf[:n]}
}

finish_writing_node_payload_amdx :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFinishWritingNodePayloadAMDX(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpNodePayloadArrayLengthAMDX :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpNodePayloadArrayLengthAMDX), result = {result, result_type}, operands = buf[:n]}
}

node_payload_array_length_amdx :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpNodePayloadArrayLengthAMDX(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpIsNodePayloadValidAMDX :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIsNodePayloadValidAMDX), result = {result, result_type}, operands = buf[:n]}
}

is_node_payload_valid_amdx :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIsNodePayloadValidAMDX(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpConstantStringAMDX :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpConstantStringAMDX), result = {id = result}, operands = buf[:n]}
}

constant_string_amdx :: proc(b: ^Builder, op1: string) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantStringAMDX(opbuf(b, (len(op1) + 4) / 4), r, op1))
	return r
}

inst_OpSpecConstantStringAMDX :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpSpecConstantStringAMDX), result = {id = result}, operands = buf[:n]}
}

spec_constant_string_amdx :: proc(b: ^Builder, op1: string) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantStringAMDX(opbuf(b, (len(op1) + 4) / 4), r, op1))
	return r
}

inst_OpGroupNonUniformQuadAllKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformQuadAllKHR), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_quad_all_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformQuadAllKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpGroupNonUniformQuadAnyKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformQuadAnyKHR), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_quad_any_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformQuadAnyKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpTypeBufferEXT :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Storage_Class) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	return Operation{opcode = u16(Opcode.OpTypeBufferEXT), result = {id = result}, operands = buf[:n]}
}

type_buffer_ext :: proc(b: ^Builder, op1: Storage_Class) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeBufferEXT(opbuf(b, 1), r, op1))
	return r
}

inst_OpBufferPointerEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpBufferPointerEXT), result = {result, result_type}, operands = buf[:n]}
}

buffer_pointer_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBufferPointerEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpAbortKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpAbortKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

abort_khr :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpAbortKHR(opbuf(b, 1 + 1), op1, op2))
}

inst_OpUntypedImageTexelPointerEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpUntypedImageTexelPointerEXT), result = {result, result_type}, operands = buf[:n]}
}

untyped_image_texel_pointer_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedImageTexelPointerEXT(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpMemberDecorateIdEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: i64, op3: Decoration) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(i64(op3)); n += 1
	return Operation{opcode = u16(Opcode.OpMemberDecorateIdEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

member_decorate_id_ext :: proc(b: ^Builder, op1: Id, op2: i64, op3: Decoration) {
	append(&b.ops, inst_OpMemberDecorateIdEXT(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpConstantSizeOfEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConstantSizeOfEXT), result = {result, result_type}, operands = buf[:n]}
}

constant_size_of_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantSizeOfEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConstantDataKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []i64) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_int(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpConstantDataKHR), result = {result, result_type}, operands = buf[:n]}
}

constant_data_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: []i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantDataKHR(opbuf(b, len(op1)), result_type, r, op1))
	return r
}

inst_OpSpecConstantDataKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []i64) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_int(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpSpecConstantDataKHR), result = {result, result_type}, operands = buf[:n]}
}

spec_constant_data_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: []i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantDataKHR(opbuf(b, len(op1)), result_type, r, op1))
	return r
}

inst_OpPoisonKHR :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpPoisonKHR), result = {result, result_type}}
}

poison_khr :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPoisonKHR(result_type, r))
	return r
}

inst_OpFreezeKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpFreezeKHR), result = {result, result_type}, operands = buf[:n]}
}

freeze_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFreezeKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectRecordHitMotionNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id, op14: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	buf[n] = op_value(op13); n += 1
	buf[n] = op_value(op14); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordHitMotionNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_hit_motion_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id, op14: Id) {
	append(&b.ops, inst_OpHitObjectRecordHitMotionNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12, op13, op14))
}

inst_OpHitObjectRecordHitWithIndexMotionNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	buf[n] = op_value(op13); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordHitWithIndexMotionNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_hit_with_index_motion_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id) {
	append(&b.ops, inst_OpHitObjectRecordHitWithIndexMotionNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12, op13))
}

inst_OpHitObjectRecordMissMotionNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordMissMotionNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_miss_motion_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id) {
	append(&b.ops, inst_OpHitObjectRecordMissMotionNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7))
}

inst_OpHitObjectGetWorldToObjectNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetWorldToObjectNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_world_to_object_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetWorldToObjectNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetObjectToWorldNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetObjectToWorldNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_object_to_world_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetObjectToWorldNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetObjectRayDirectionNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetObjectRayDirectionNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_object_ray_direction_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetObjectRayDirectionNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetObjectRayOriginNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetObjectRayOriginNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_object_ray_origin_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetObjectRayOriginNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectTraceRayMotionNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	buf[n] = op_value(op13); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectTraceRayMotionNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_trace_ray_motion_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id) {
	append(&b.ops, inst_OpHitObjectTraceRayMotionNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12, op13))
}

inst_OpHitObjectGetShaderRecordBufferHandleNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetShaderRecordBufferHandleNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_shader_record_buffer_handle_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetShaderRecordBufferHandleNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetShaderBindingTableRecordIndexNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetShaderBindingTableRecordIndexNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_shader_binding_table_record_index_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetShaderBindingTableRecordIndexNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectRecordEmptyNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordEmptyNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_empty_nv :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpHitObjectRecordEmptyNV(opbuf(b, 1), op1))
}

inst_OpHitObjectTraceRayNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectTraceRayNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_trace_ray_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) {
	append(&b.ops, inst_OpHitObjectTraceRayNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12))
}

inst_OpHitObjectRecordHitNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	buf[n] = op_value(op13); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordHitNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_hit_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id) {
	append(&b.ops, inst_OpHitObjectRecordHitNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12, op13))
}

inst_OpHitObjectRecordHitWithIndexNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordHitWithIndexNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_hit_with_index_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) {
	append(&b.ops, inst_OpHitObjectRecordHitWithIndexNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12))
}

inst_OpHitObjectRecordMissNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordMissNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_miss_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) {
	append(&b.ops, inst_OpHitObjectRecordMissNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6))
}

inst_OpHitObjectExecuteShaderNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectExecuteShaderNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_execute_shader_nv :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpHitObjectExecuteShaderNV(opbuf(b, 1 + 1), op1, op2))
}

inst_OpHitObjectGetCurrentTimeNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetCurrentTimeNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_current_time_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetCurrentTimeNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetAttributesNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetAttributesNV), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_get_attributes_nv :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpHitObjectGetAttributesNV(opbuf(b, 1 + 1), op1, op2))
}

inst_OpHitObjectGetHitKindNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetHitKindNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_hit_kind_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetHitKindNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetPrimitiveIndexNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetPrimitiveIndexNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_primitive_index_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetPrimitiveIndexNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetGeometryIndexNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetGeometryIndexNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_geometry_index_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetGeometryIndexNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetInstanceIdNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetInstanceIdNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_instance_id_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetInstanceIdNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetInstanceCustomIndexNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetInstanceCustomIndexNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_instance_custom_index_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetInstanceCustomIndexNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetWorldRayDirectionNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetWorldRayDirectionNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_world_ray_direction_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetWorldRayDirectionNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetWorldRayOriginNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetWorldRayOriginNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_world_ray_origin_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetWorldRayOriginNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetRayTMaxNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetRayTMaxNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_ray_t_max_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetRayTMaxNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetRayTMinNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetRayTMinNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_ray_t_min_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetRayTMinNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectIsEmptyNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectIsEmptyNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_is_empty_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectIsEmptyNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectIsHitNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectIsHitNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_is_hit_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectIsHitNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectIsMissNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectIsMissNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_is_miss_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectIsMissNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpReorderThreadWithHitObjectNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Maybe(Id), op3: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	if x, xok := op2.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op3.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpReorderThreadWithHitObjectNV), result = {id = ID_NONE}, operands = buf[:n]}
}

reorder_thread_with_hit_object_nv :: proc(b: ^Builder, op1: Id, op2: Maybe(Id), op3: Maybe(Id)) {
	append(&b.ops, inst_OpReorderThreadWithHitObjectNV(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpReorderThreadWithHintNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpReorderThreadWithHintNV), result = {id = ID_NONE}, operands = buf[:n]}
}

reorder_thread_with_hint_nv :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpReorderThreadWithHintNV(opbuf(b, 1 + 1), op1, op2))
}

inst_OpTypeHitObjectNV :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeHitObjectNV), result = {id = result}}
}

type_hit_object_nv :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeHitObjectNV(r))
	return r
}

inst_OpImageSampleFootprintNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Image_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	if x, xok := op5.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpImageSampleFootprintNV), result = {result, result_type}, operands = buf[:n]}
}

image_sample_footprint_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Image_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpImageSampleFootprintNV(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpTypeVectorIdEXT :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTypeVectorIdEXT), result = {id = result}, operands = buf[:n]}
}

type_vector_id_ext :: proc(b: ^Builder, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeVectorIdEXT(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpCooperativeVectorMatrixMulNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Maybe(Id), op11: Maybe(Cooperative_Matrix_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	if x, xok := op10.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op11.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeVectorMatrixMulNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_vector_matrix_mul_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Maybe(Id), op11: Maybe(Cooperative_Matrix_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeVectorMatrixMulNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11))
	return r
}

inst_OpCooperativeVectorOuterProductAccumulateNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	if x, xok := op7.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeVectorOuterProductAccumulateNV), result = {id = ID_NONE}, operands = buf[:n]}
}

cooperative_vector_outer_product_accumulate_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Maybe(Id)) {
	append(&b.ops, inst_OpCooperativeVectorOuterProductAccumulateNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7))
}

inst_OpCooperativeVectorReduceSumAccumulateNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeVectorReduceSumAccumulateNV), result = {id = ID_NONE}, operands = buf[:n]}
}

cooperative_vector_reduce_sum_accumulate_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpCooperativeVectorReduceSumAccumulateNV(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpCooperativeVectorMatrixMulAddNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Maybe(Id), op14: Maybe(Cooperative_Matrix_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	if x, xok := op13.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op14.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeVectorMatrixMulAddNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_vector_matrix_mul_add_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Maybe(Id), op14: Maybe(Cooperative_Matrix_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeVectorMatrixMulAddNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12, op13, op14))
	return r
}

inst_OpCooperativeMatrixConvertNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixConvertNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_convert_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixConvertNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpEmitMeshTasksEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpEmitMeshTasksEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

emit_mesh_tasks_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Maybe(Id)) {
	append(&b.ops, inst_OpEmitMeshTasksEXT(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpSetMeshOutputsEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSetMeshOutputsEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

set_mesh_outputs_ext :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpSetMeshOutputsEXT(opbuf(b, 1 + 1), op1, op2))
}

inst_OpGroupNonUniformPartitionEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpGroupNonUniformPartitionEXT), result = {result, result_type}, operands = buf[:n]}
}

group_non_uniform_partition_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupNonUniformPartitionEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpWritePackedPrimitiveIndices4x8NV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpWritePackedPrimitiveIndices4x8NV), result = {id = ID_NONE}, operands = buf[:n]}
}

write_packed_primitive_indices4x8_nv :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpWritePackedPrimitiveIndices4x8NV(opbuf(b, 1 + 1), op1, op2))
}

inst_OpFetchMicroTriangleVertexPositionNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpFetchMicroTriangleVertexPositionNV), result = {result, result_type}, operands = buf[:n]}
}

fetch_micro_triangle_vertex_position_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFetchMicroTriangleVertexPositionNV(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpFetchMicroTriangleVertexBarycentricNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpFetchMicroTriangleVertexBarycentricNV), result = {result, result_type}, operands = buf[:n]}
}

fetch_micro_triangle_vertex_barycentric_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFetchMicroTriangleVertexBarycentricNV(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpCooperativeVectorLoadNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeVectorLoadNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_vector_load_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Maybe(Memory_Access)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeVectorLoadNV(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpCooperativeVectorStoreNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeVectorStoreNV), result = {id = ID_NONE}, operands = buf[:n]}
}

cooperative_vector_store_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access)) {
	append(&b.ops, inst_OpCooperativeVectorStoreNV(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpHitObjectRecordFromQueryEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	if x, xok := op5.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpHitObjectRecordFromQueryEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_from_query_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Id)) {
	append(&b.ops, inst_OpHitObjectRecordFromQueryEXT(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpHitObjectRecordMissEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordMissEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_miss_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id) {
	append(&b.ops, inst_OpHitObjectRecordMissEXT(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7))
}

inst_OpHitObjectRecordMissMotionEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordMissMotionEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_miss_motion_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id) {
	append(&b.ops, inst_OpHitObjectRecordMissMotionEXT(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8))
}

inst_OpHitObjectGetIntersectionTriangleVertexPositionsEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetIntersectionTriangleVertexPositionsEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_intersection_triangle_vertex_positions_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetIntersectionTriangleVertexPositionsEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetRayFlagsEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetRayFlagsEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_ray_flags_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetRayFlagsEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectSetShaderBindingTableRecordIndexEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectSetShaderBindingTableRecordIndexEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_set_shader_binding_table_record_index_ext :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpHitObjectSetShaderBindingTableRecordIndexEXT(opbuf(b, 1 + 1), op1, op2))
}

inst_OpHitObjectReorderExecuteShaderEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Maybe(Id), op4: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op4.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpHitObjectReorderExecuteShaderEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_reorder_execute_shader_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Maybe(Id), op4: Maybe(Id)) {
	append(&b.ops, inst_OpHitObjectReorderExecuteShaderEXT(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpHitObjectTraceReorderExecuteEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Maybe(Id), op14: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	if x, xok := op13.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op14.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpHitObjectTraceReorderExecuteEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_trace_reorder_execute_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Maybe(Id), op14: Maybe(Id)) {
	append(&b.ops, inst_OpHitObjectTraceReorderExecuteEXT(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12, op13, op14))
}

inst_OpHitObjectTraceMotionReorderExecuteEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id, op14: Maybe(Id), op15: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	buf[n] = op_value(op13); n += 1
	if x, xok := op14.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op15.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpHitObjectTraceMotionReorderExecuteEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_trace_motion_reorder_execute_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id, op14: Maybe(Id), op15: Maybe(Id)) {
	append(&b.ops, inst_OpHitObjectTraceMotionReorderExecuteEXT(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12, op13, op14, op15))
}

inst_OpTypeHitObjectEXT :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeHitObjectEXT), result = {id = result}}
}

type_hit_object_ext :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeHitObjectEXT(r))
	return r
}

inst_OpReorderThreadWithHintEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpReorderThreadWithHintEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

reorder_thread_with_hint_ext :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpReorderThreadWithHintEXT(opbuf(b, 1 + 1), op1, op2))
}

inst_OpReorderThreadWithHitObjectEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Maybe(Id), op3: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	if x, xok := op2.?; xok { buf[n] = op_value(x); n += 1 }
	if x, xok := op3.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpReorderThreadWithHitObjectEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

reorder_thread_with_hit_object_ext :: proc(b: ^Builder, op1: Id, op2: Maybe(Id), op3: Maybe(Id)) {
	append(&b.ops, inst_OpReorderThreadWithHitObjectEXT(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpHitObjectTraceRayEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectTraceRayEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_trace_ray_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) {
	append(&b.ops, inst_OpHitObjectTraceRayEXT(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12))
}

inst_OpHitObjectTraceRayMotionEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	buf[n] = op_value(op13); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectTraceRayMotionEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_trace_ray_motion_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id, op13: Id) {
	append(&b.ops, inst_OpHitObjectTraceRayMotionEXT(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12, op13))
}

inst_OpHitObjectRecordEmptyEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectRecordEmptyEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_record_empty_ext :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpHitObjectRecordEmptyEXT(opbuf(b, 1), op1))
}

inst_OpHitObjectExecuteShaderEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectExecuteShaderEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_execute_shader_ext :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpHitObjectExecuteShaderEXT(opbuf(b, 1 + 1), op1, op2))
}

inst_OpHitObjectGetCurrentTimeEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetCurrentTimeEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_current_time_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetCurrentTimeEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetAttributesEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetAttributesEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

hit_object_get_attributes_ext :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpHitObjectGetAttributesEXT(opbuf(b, 1 + 1), op1, op2))
}

inst_OpHitObjectGetHitKindEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetHitKindEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_hit_kind_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetHitKindEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetPrimitiveIndexEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetPrimitiveIndexEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_primitive_index_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetPrimitiveIndexEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetGeometryIndexEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetGeometryIndexEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_geometry_index_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetGeometryIndexEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetInstanceIdEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetInstanceIdEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_instance_id_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetInstanceIdEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetInstanceCustomIndexEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetInstanceCustomIndexEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_instance_custom_index_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetInstanceCustomIndexEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetObjectRayOriginEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetObjectRayOriginEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_object_ray_origin_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetObjectRayOriginEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetObjectRayDirectionEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetObjectRayDirectionEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_object_ray_direction_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetObjectRayDirectionEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetWorldRayDirectionEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetWorldRayDirectionEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_world_ray_direction_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetWorldRayDirectionEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetWorldRayOriginEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetWorldRayOriginEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_world_ray_origin_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetWorldRayOriginEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetObjectToWorldEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetObjectToWorldEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_object_to_world_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetObjectToWorldEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetWorldToObjectEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetWorldToObjectEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_world_to_object_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetWorldToObjectEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetRayTMaxEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetRayTMaxEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_ray_t_max_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetRayTMaxEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpReportIntersectionKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpReportIntersectionKHR), result = {result, result_type}, operands = buf[:n]}
}

report_intersection_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpReportIntersectionKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpIgnoreIntersectionNV :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpIgnoreIntersectionNV), result = {id = ID_NONE}}
}

ignore_intersection_nv :: proc(b: ^Builder) {
	append(&b.ops, inst_OpIgnoreIntersectionNV())
}

inst_OpTerminateRayNV :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpTerminateRayNV), result = {id = ID_NONE}}
}

terminate_ray_nv :: proc(b: ^Builder) {
	append(&b.ops, inst_OpTerminateRayNV())
}

inst_OpTraceNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	return Operation{opcode = u16(Opcode.OpTraceNV), result = {id = ID_NONE}, operands = buf[:n]}
}

trace_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id) {
	append(&b.ops, inst_OpTraceNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11))
}

inst_OpTraceMotionNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	return Operation{opcode = u16(Opcode.OpTraceMotionNV), result = {id = ID_NONE}, operands = buf[:n]}
}

trace_motion_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) {
	append(&b.ops, inst_OpTraceMotionNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12))
}

inst_OpTraceRayMotionNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	buf[n] = op_value(op12); n += 1
	return Operation{opcode = u16(Opcode.OpTraceRayMotionNV), result = {id = ID_NONE}, operands = buf[:n]}
}

trace_ray_motion_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id, op12: Id) {
	append(&b.ops, inst_OpTraceRayMotionNV(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11, op12))
}

inst_OpRayQueryGetIntersectionTriangleVertexPositionsKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionTriangleVertexPositionsKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_triangle_vertex_positions_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionTriangleVertexPositionsKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpTypeAccelerationStructureKHR :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAccelerationStructureKHR), result = {id = result}}
}

type_acceleration_structure_khr :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAccelerationStructureKHR(r))
	return r
}

inst_OpExecuteCallableNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpExecuteCallableNV), result = {id = ID_NONE}, operands = buf[:n]}
}

execute_callable_nv :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpExecuteCallableNV(opbuf(b, 1 + 1), op1, op2))
}

inst_OpRayQueryGetIntersectionClusterIdNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionClusterIdNV), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_cluster_id_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionClusterIdNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpHitObjectGetClusterIdNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetClusterIdNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_cluster_id_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetClusterIdNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetRayTMinEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetRayTMinEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_ray_t_min_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetRayTMinEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetShaderBindingTableRecordIndexEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetShaderBindingTableRecordIndexEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_shader_binding_table_record_index_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetShaderBindingTableRecordIndexEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetShaderRecordBufferHandleEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetShaderRecordBufferHandleEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_shader_record_buffer_handle_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetShaderRecordBufferHandleEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectIsEmptyEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectIsEmptyEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_is_empty_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectIsEmptyEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectIsHitEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectIsHitEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_is_hit_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectIsHitEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectIsMissEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectIsMissEXT), result = {result, result_type}, operands = buf[:n]}
}

hit_object_is_miss_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectIsMissEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpTypeCooperativeMatrixNV :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpTypeCooperativeMatrixNV), result = {id = result}, operands = buf[:n]}
}

type_cooperative_matrix_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeCooperativeMatrixNV(opbuf(b, 1 + 1 + 1 + 1), r, op1, op2, op3, op4))
	return r
}

inst_OpCooperativeMatrixLoadNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixLoadNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_load_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixLoadNV(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpCooperativeMatrixStoreNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	if x, xok := op5.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixStoreNV), result = {id = ID_NONE}, operands = buf[:n]}
}

cooperative_matrix_store_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Memory_Access)) {
	append(&b.ops, inst_OpCooperativeMatrixStoreNV(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpCooperativeMatrixMulAddNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixMulAddNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_mul_add_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixMulAddNV(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpCooperativeMatrixLengthNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixLengthNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_length_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixLengthNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpBeginInvocationInterlockEXT :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpBeginInvocationInterlockEXT), result = {id = ID_NONE}}
}

begin_invocation_interlock_ext :: proc(b: ^Builder) {
	append(&b.ops, inst_OpBeginInvocationInterlockEXT())
}

inst_OpEndInvocationInterlockEXT :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpEndInvocationInterlockEXT), result = {id = ID_NONE}}
}

end_invocation_interlock_ext :: proc(b: ^Builder) {
	append(&b.ops, inst_OpEndInvocationInterlockEXT())
}

inst_OpCooperativeMatrixReduceNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Cooperative_Matrix_Reduce, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(transmute(u32)op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixReduceNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_reduce_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Cooperative_Matrix_Reduce, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixReduceNV(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpCooperativeMatrixLoadTensorNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Memory_Access, op5: Tensor_Addressing_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(i64(transmute(u32)op4)); n += 1
	buf[n] = op_int(i64(transmute(u32)op5)); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixLoadTensorNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_load_tensor_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Memory_Access, op5: Tensor_Addressing_Operands) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixLoadTensorNV(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpCooperativeMatrixStoreTensorNV :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Memory_Access, op5: Tensor_Addressing_Operands) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(i64(transmute(u32)op4)); n += 1
	buf[n] = op_int(i64(transmute(u32)op5)); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixStoreTensorNV), result = {id = ID_NONE}, operands = buf[:n]}
}

cooperative_matrix_store_tensor_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Memory_Access, op5: Tensor_Addressing_Operands) {
	append(&b.ops, inst_OpCooperativeMatrixStoreTensorNV(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpCooperativeMatrixPerElementOpNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixPerElementOpNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_per_element_op_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixPerElementOpNV(opbuf(b, 1 + 1 + len(op3)), result_type, r, op1, op2, op3))
	return r
}

inst_OpTypeTensorLayoutNV :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTypeTensorLayoutNV), result = {id = result}, operands = buf[:n]}
}

type_tensor_layout_nv :: proc(b: ^Builder, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeTensorLayoutNV(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpTypeTensorViewNV :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Id, op3: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	for x in op3 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTypeTensorViewNV), result = {id = result}, operands = buf[:n]}
}

type_tensor_view_nv :: proc(b: ^Builder, op1: Id, op2: Id, op3: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeTensorViewNV(opbuf(b, 1 + 1 + len(op3)), r, op1, op2, op3))
	return r
}

inst_OpCreateTensorLayoutNV :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpCreateTensorLayoutNV), result = {result, result_type}}
}

create_tensor_layout_nv :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCreateTensorLayoutNV(result_type, r))
	return r
}

inst_OpTensorLayoutSetDimensionNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTensorLayoutSetDimensionNV), result = {result, result_type}, operands = buf[:n]}
}

tensor_layout_set_dimension_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorLayoutSetDimensionNV(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpTensorLayoutSetStrideNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTensorLayoutSetStrideNV), result = {result, result_type}, operands = buf[:n]}
}

tensor_layout_set_stride_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorLayoutSetStrideNV(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpTensorLayoutSliceNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTensorLayoutSliceNV), result = {result, result_type}, operands = buf[:n]}
}

tensor_layout_slice_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorLayoutSliceNV(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpTensorLayoutSetClampValueNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpTensorLayoutSetClampValueNV), result = {result, result_type}, operands = buf[:n]}
}

tensor_layout_set_clamp_value_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorLayoutSetClampValueNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpCreateTensorViewNV :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpCreateTensorViewNV), result = {result, result_type}}
}

create_tensor_view_nv :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCreateTensorViewNV(result_type, r))
	return r
}

inst_OpTensorViewSetDimensionNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTensorViewSetDimensionNV), result = {result, result_type}, operands = buf[:n]}
}

tensor_view_set_dimension_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorViewSetDimensionNV(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpTensorViewSetStrideNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTensorViewSetStrideNV), result = {result, result_type}, operands = buf[:n]}
}

tensor_view_set_stride_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorViewSetStrideNV(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpDemoteToHelperInvocation :: #force_inline proc "contextless" () -> Operation {
	return Operation{opcode = u16(Opcode.OpDemoteToHelperInvocation), result = {id = ID_NONE}}
}

demote_to_helper_invocation :: proc(b: ^Builder) {
	append(&b.ops, inst_OpDemoteToHelperInvocation())
}

inst_OpIsHelperInvocationEXT :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpIsHelperInvocationEXT), result = {result, result_type}}
}

is_helper_invocation_ext :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIsHelperInvocationEXT(result_type, r))
	return r
}

inst_OpTensorViewSetClipNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpTensorViewSetClipNV), result = {result, result_type}, operands = buf[:n]}
}

tensor_view_set_clip_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorViewSetClipNV(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpTensorLayoutSetBlockSizeNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTensorLayoutSetBlockSizeNV), result = {result, result_type}, operands = buf[:n]}
}

tensor_layout_set_block_size_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTensorLayoutSetBlockSizeNV(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpCooperativeMatrixTransposeNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCooperativeMatrixTransposeNV), result = {result, result_type}, operands = buf[:n]}
}

cooperative_matrix_transpose_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCooperativeMatrixTransposeNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertUToImageNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertUToImageNV), result = {result, result_type}, operands = buf[:n]}
}

convert_u_to_image_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertUToImageNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertUToSamplerNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertUToSamplerNV), result = {result, result_type}, operands = buf[:n]}
}

convert_u_to_sampler_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertUToSamplerNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertImageToUNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertImageToUNV), result = {result, result_type}, operands = buf[:n]}
}

convert_image_to_unv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertImageToUNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertSamplerToUNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertSamplerToUNV), result = {result, result_type}, operands = buf[:n]}
}

convert_sampler_to_unv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertSamplerToUNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertUToSampledImageNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertUToSampledImageNV), result = {result, result_type}, operands = buf[:n]}
}

convert_u_to_sampled_image_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertUToSampledImageNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertSampledImageToUNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertSampledImageToUNV), result = {result, result_type}, operands = buf[:n]}
}

convert_sampled_image_to_unv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertSampledImageToUNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSamplerImageAddressingModeNV :: #force_inline proc "contextless" (buf: []Operand, op1: i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSamplerImageAddressingModeNV), result = {id = ID_NONE}, operands = buf[:n]}
}

sampler_image_addressing_mode_nv :: proc(b: ^Builder, op1: i64) {
	append(&b.ops, inst_OpSamplerImageAddressingModeNV(opbuf(b, 1), op1))
}

inst_OpRawAccessChainNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Raw_Access_Chain_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	if x, xok := op5.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpRawAccessChainNV), result = {result, result_type}, operands = buf[:n]}
}

raw_access_chain_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Raw_Access_Chain_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRawAccessChainNV(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpRayQueryGetIntersectionSpherePositionNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionSpherePositionNV), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_sphere_position_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionSpherePositionNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionSphereRadiusNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionSphereRadiusNV), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_sphere_radius_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionSphereRadiusNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionLSSPositionsNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionLSSPositionsNV), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_lss_positions_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionLSSPositionsNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionLSSRadiiNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionLSSRadiiNV), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_lss_radii_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionLSSRadiiNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionLSSHitValueNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionLSSHitValueNV), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_lss_hit_value_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionLSSHitValueNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpHitObjectGetSpherePositionNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetSpherePositionNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_sphere_position_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetSpherePositionNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetSphereRadiusNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetSphereRadiusNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_sphere_radius_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetSphereRadiusNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetLSSPositionsNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetLSSPositionsNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_lss_positions_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetLSSPositionsNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectGetLSSRadiiNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectGetLSSRadiiNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_get_lss_radii_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectGetLSSRadiiNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectIsSphereHitNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectIsSphereHitNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_is_sphere_hit_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectIsSphereHitNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpHitObjectIsLSSHitNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpHitObjectIsLSSHitNV), result = {result, result_type}, operands = buf[:n]}
}

hit_object_is_lss_hit_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpHitObjectIsLSSHitNV(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpRayQueryIsSphereHitNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryIsSphereHitNV), result = {result, result_type}, operands = buf[:n]}
}

ray_query_is_sphere_hit_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryIsSphereHitNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryIsLSSHitNV :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryIsLSSHitNV), result = {result, result_type}, operands = buf[:n]}
}

ray_query_is_lss_hit_nv :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryIsLSSHitNV(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupShuffleINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupShuffleINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_shuffle_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupShuffleINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupShuffleDownINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupShuffleDownINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_shuffle_down_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupShuffleDownINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupShuffleUpINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupShuffleUpINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_shuffle_up_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupShuffleUpINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupShuffleXorINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupShuffleXorINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_shuffle_xor_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupShuffleXorINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupBlockReadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupBlockReadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_block_read_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupBlockReadINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupBlockWriteINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupBlockWriteINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup_block_write_intel :: proc(b: ^Builder, op1: Id, op2: Id) {
	append(&b.ops, inst_OpSubgroupBlockWriteINTEL(opbuf(b, 1 + 1), op1, op2))
}

inst_OpSubgroupImageBlockReadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupImageBlockReadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_image_block_read_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupImageBlockReadINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupImageBlockWriteINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupImageBlockWriteINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup_image_block_write_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpSubgroupImageBlockWriteINTEL(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpSubgroupImageMediaBlockReadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupImageMediaBlockReadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_image_media_block_read_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupImageMediaBlockReadINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupImageMediaBlockWriteINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupImageMediaBlockWriteINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup_image_media_block_write_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) {
	append(&b.ops, inst_OpSubgroupImageMediaBlockWriteINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5))
}

inst_OpUCountLeadingZerosINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpUCountLeadingZerosINTEL), result = {result, result_type}, operands = buf[:n]}
}

u_count_leading_zeros_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUCountLeadingZerosINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpUCountTrailingZerosINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpUCountTrailingZerosINTEL), result = {result, result_type}, operands = buf[:n]}
}

u_count_trailing_zeros_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUCountTrailingZerosINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpAbsISubINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpAbsISubINTEL), result = {result, result_type}, operands = buf[:n]}
}

abs_i_sub_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAbsISubINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpAbsUSubINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpAbsUSubINTEL), result = {result, result_type}, operands = buf[:n]}
}

abs_u_sub_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAbsUSubINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpIAddSatINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIAddSatINTEL), result = {result, result_type}, operands = buf[:n]}
}

i_add_sat_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIAddSatINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUAddSatINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUAddSatINTEL), result = {result, result_type}, operands = buf[:n]}
}

u_add_sat_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUAddSatINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpIAverageINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIAverageINTEL), result = {result, result_type}, operands = buf[:n]}
}

i_average_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIAverageINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUAverageINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUAverageINTEL), result = {result, result_type}, operands = buf[:n]}
}

u_average_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUAverageINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpIAverageRoundedINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIAverageRoundedINTEL), result = {result, result_type}, operands = buf[:n]}
}

i_average_rounded_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIAverageRoundedINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUAverageRoundedINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUAverageRoundedINTEL), result = {result, result_type}, operands = buf[:n]}
}

u_average_rounded_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUAverageRoundedINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpISubSatINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpISubSatINTEL), result = {result, result_type}, operands = buf[:n]}
}

i_sub_sat_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpISubSatINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUSubSatINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUSubSatINTEL), result = {result, result_type}, operands = buf[:n]}
}

u_sub_sat_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUSubSatINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpIMul32x16INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpIMul32x16INTEL), result = {result, result_type}, operands = buf[:n]}
}

i_mul32x16_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpIMul32x16INTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpUMul32x16INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUMul32x16INTEL), result = {result, result_type}, operands = buf[:n]}
}

u_mul32x16_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUMul32x16INTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpConstantFunctionPointerINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConstantFunctionPointerINTEL), result = {result, result_type}, operands = buf[:n]}
}

constant_function_pointer_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConstantFunctionPointerINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpFunctionPointerCallINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpFunctionPointerCallINTEL), result = {result, result_type}, operands = buf[:n]}
}

function_pointer_call_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFunctionPointerCallINTEL(opbuf(b, len(op1)), result_type, r, op1))
	return r
}

inst_OpAsmTargetINTEL :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: string) -> Operation {
	n := 0
	n += pack_string_operands(buf[n:], op1)
	return Operation{opcode = u16(Opcode.OpAsmTargetINTEL), result = {id = result}, operands = buf[:n]}
}

asm_target_intel :: proc(b: ^Builder, op1: string) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAsmTargetINTEL(opbuf(b, (len(op1) + 4) / 4), r, op1))
	return r
}

inst_OpAsmINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: string, op4: string) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	n += pack_string_operands(buf[n:], op3)
	n += pack_string_operands(buf[n:], op4)
	return Operation{opcode = u16(Opcode.OpAsmINTEL), result = {result, result_type}, operands = buf[:n]}
}

asm_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: string, op4: string) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAsmINTEL(opbuf(b, 1 + 1 + (len(op3) + 4) / 4 + (len(op4) + 4) / 4), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAsmCallINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpAsmCallINTEL), result = {result, result_type}, operands = buf[:n]}
}

asm_call_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAsmCallINTEL(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpAtomicFMinEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicFMinEXT), result = {result, result_type}, operands = buf[:n]}
}

atomic_f_min_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicFMinEXT(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAtomicFMaxEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicFMaxEXT), result = {result, result_type}, operands = buf[:n]}
}

atomic_f_max_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicFMaxEXT(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpAssumeTrueKHR :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpAssumeTrueKHR), result = {id = ID_NONE}, operands = buf[:n]}
}

assume_true_khr :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpAssumeTrueKHR(opbuf(b, 1), op1))
}

inst_OpExpectKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpExpectKHR), result = {result, result_type}, operands = buf[:n]}
}

expect_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpExpectKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpDecorateString :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Decoration) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpDecorateString), result = {id = ID_NONE}, operands = buf[:n]}
}

decorate_string :: proc(b: ^Builder, op1: Id, op2: Decoration) {
	append(&b.ops, inst_OpDecorateString(opbuf(b, 1 + 1), op1, op2))
}

inst_OpMemberDecorateString :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: i64, op3: Decoration) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(i64(op3)); n += 1
	return Operation{opcode = u16(Opcode.OpMemberDecorateString), result = {id = ID_NONE}, operands = buf[:n]}
}

member_decorate_string :: proc(b: ^Builder, op1: Id, op2: i64, op3: Decoration) {
	append(&b.ops, inst_OpMemberDecorateString(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpVmeImageINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpVmeImageINTEL), result = {result, result_type}, operands = buf[:n]}
}

vme_image_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVmeImageINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpTypeVmeImageINTEL :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpTypeVmeImageINTEL), result = {id = result}, operands = buf[:n]}
}

type_vme_image_intel :: proc(b: ^Builder, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeVmeImageINTEL(opbuf(b, 1), r, op1))
	return r
}

inst_OpTypeAvcImePayloadINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcImePayloadINTEL), result = {id = result}}
}

type_avc_ime_payload_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcImePayloadINTEL(r))
	return r
}

inst_OpTypeAvcRefPayloadINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcRefPayloadINTEL), result = {id = result}}
}

type_avc_ref_payload_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcRefPayloadINTEL(r))
	return r
}

inst_OpTypeAvcSicPayloadINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcSicPayloadINTEL), result = {id = result}}
}

type_avc_sic_payload_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcSicPayloadINTEL(r))
	return r
}

inst_OpTypeAvcMcePayloadINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcMcePayloadINTEL), result = {id = result}}
}

type_avc_mce_payload_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcMcePayloadINTEL(r))
	return r
}

inst_OpTypeAvcMceResultINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcMceResultINTEL), result = {id = result}}
}

type_avc_mce_result_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcMceResultINTEL(r))
	return r
}

inst_OpTypeAvcImeResultINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcImeResultINTEL), result = {id = result}}
}

type_avc_ime_result_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcImeResultINTEL(r))
	return r
}

inst_OpTypeAvcImeResultSingleReferenceStreamoutINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcImeResultSingleReferenceStreamoutINTEL), result = {id = result}}
}

type_avc_ime_result_single_reference_streamout_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcImeResultSingleReferenceStreamoutINTEL(r))
	return r
}

inst_OpTypeAvcImeResultDualReferenceStreamoutINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcImeResultDualReferenceStreamoutINTEL), result = {id = result}}
}

type_avc_ime_result_dual_reference_streamout_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcImeResultDualReferenceStreamoutINTEL(r))
	return r
}

inst_OpTypeAvcImeSingleReferenceStreaminINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcImeSingleReferenceStreaminINTEL), result = {id = result}}
}

type_avc_ime_single_reference_streamin_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcImeSingleReferenceStreaminINTEL(r))
	return r
}

inst_OpTypeAvcImeDualReferenceStreaminINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcImeDualReferenceStreaminINTEL), result = {id = result}}
}

type_avc_ime_dual_reference_streamin_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcImeDualReferenceStreaminINTEL(r))
	return r
}

inst_OpTypeAvcRefResultINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcRefResultINTEL), result = {id = result}}
}

type_avc_ref_result_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcRefResultINTEL(r))
	return r
}

inst_OpTypeAvcSicResultINTEL :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeAvcSicResultINTEL), result = {id = result}}
}

type_avc_sic_result_intel :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeAvcSicResultINTEL(r))
	return r
}

inst_OpSubgroupAvcMceGetDefaultInterBaseMultiReferencePenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultInterBaseMultiReferencePenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_default_inter_base_multi_reference_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultInterBaseMultiReferencePenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceSetInterBaseMultiReferencePenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceSetInterBaseMultiReferencePenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_set_inter_base_multi_reference_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceSetInterBaseMultiReferencePenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceGetDefaultInterShapePenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultInterShapePenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_default_inter_shape_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultInterShapePenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceSetInterShapePenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceSetInterShapePenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_set_inter_shape_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceSetInterShapePenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceGetDefaultInterDirectionPenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultInterDirectionPenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_default_inter_direction_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultInterDirectionPenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceSetInterDirectionPenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceSetInterDirectionPenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_set_inter_direction_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceSetInterDirectionPenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceGetDefaultIntraLumaShapePenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultIntraLumaShapePenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_default_intra_luma_shape_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultIntraLumaShapePenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceGetDefaultInterMotionVectorCostTableINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultInterMotionVectorCostTableINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_default_inter_motion_vector_cost_table_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultInterMotionVectorCostTableINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceGetDefaultHighPenaltyCostTableINTEL :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultHighPenaltyCostTableINTEL), result = {result, result_type}}
}

subgroup_avc_mce_get_default_high_penalty_cost_table_intel :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultHighPenaltyCostTableINTEL(result_type, r))
	return r
}

inst_OpSubgroupAvcMceGetDefaultMediumPenaltyCostTableINTEL :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultMediumPenaltyCostTableINTEL), result = {result, result_type}}
}

subgroup_avc_mce_get_default_medium_penalty_cost_table_intel :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultMediumPenaltyCostTableINTEL(result_type, r))
	return r
}

inst_OpSubgroupAvcMceGetDefaultLowPenaltyCostTableINTEL :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultLowPenaltyCostTableINTEL), result = {result, result_type}}
}

subgroup_avc_mce_get_default_low_penalty_cost_table_intel :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultLowPenaltyCostTableINTEL(result_type, r))
	return r
}

inst_OpSubgroupAvcMceSetMotionVectorCostFunctionINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceSetMotionVectorCostFunctionINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_set_motion_vector_cost_function_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceSetMotionVectorCostFunctionINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcMceGetDefaultIntraLumaModePenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultIntraLumaModePenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_default_intra_luma_mode_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultIntraLumaModePenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceGetDefaultNonDcLumaIntraPenaltyINTEL :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultNonDcLumaIntraPenaltyINTEL), result = {result, result_type}}
}

subgroup_avc_mce_get_default_non_dc_luma_intra_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultNonDcLumaIntraPenaltyINTEL(result_type, r))
	return r
}

inst_OpSubgroupAvcMceGetDefaultIntraChromaModeBasePenaltyINTEL :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetDefaultIntraChromaModeBasePenaltyINTEL), result = {result, result_type}}
}

subgroup_avc_mce_get_default_intra_chroma_mode_base_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetDefaultIntraChromaModeBasePenaltyINTEL(result_type, r))
	return r
}

inst_OpSubgroupAvcMceSetAcOnlyHaarINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceSetAcOnlyHaarINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_set_ac_only_haar_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceSetAcOnlyHaarINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceSetSourceInterlacedFieldPolarityINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceSetSourceInterlacedFieldPolarityINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_set_source_interlaced_field_polarity_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceSetSourceInterlacedFieldPolarityINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceSetSingleReferenceInterlacedFieldPolarityINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceSetSingleReferenceInterlacedFieldPolarityINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_set_single_reference_interlaced_field_polarity_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceSetSingleReferenceInterlacedFieldPolarityINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcMceSetDualReferenceInterlacedFieldPolaritiesINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceSetDualReferenceInterlacedFieldPolaritiesINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_set_dual_reference_interlaced_field_polarities_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceSetDualReferenceInterlacedFieldPolaritiesINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcMceConvertToImePayloadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceConvertToImePayloadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_convert_to_ime_payload_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceConvertToImePayloadINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceConvertToImeResultINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceConvertToImeResultINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_convert_to_ime_result_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceConvertToImeResultINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceConvertToRefPayloadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceConvertToRefPayloadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_convert_to_ref_payload_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceConvertToRefPayloadINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceConvertToRefResultINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceConvertToRefResultINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_convert_to_ref_result_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceConvertToRefResultINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceConvertToSicPayloadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceConvertToSicPayloadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_convert_to_sic_payload_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceConvertToSicPayloadINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceConvertToSicResultINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceConvertToSicResultINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_convert_to_sic_result_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceConvertToSicResultINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetMotionVectorsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetMotionVectorsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_motion_vectors_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetMotionVectorsINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetInterDistortionsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetInterDistortionsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_inter_distortions_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetInterDistortionsINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetBestInterDistortionsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetBestInterDistortionsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_best_inter_distortions_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetBestInterDistortionsINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetInterMajorShapeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetInterMajorShapeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_inter_major_shape_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetInterMajorShapeINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetInterMinorShapeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetInterMinorShapeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_inter_minor_shape_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetInterMinorShapeINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetInterDirectionsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetInterDirectionsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_inter_directions_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetInterDirectionsINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetInterMotionVectorCountINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetInterMotionVectorCountINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_inter_motion_vector_count_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetInterMotionVectorCountINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetInterReferenceIdsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetInterReferenceIdsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_inter_reference_ids_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetInterReferenceIdsINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcMceGetInterReferenceInterlacedFieldPolaritiesINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcMceGetInterReferenceInterlacedFieldPolaritiesINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_mce_get_inter_reference_interlaced_field_polarities_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcMceGetInterReferenceInterlacedFieldPolaritiesINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcImeInitializeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeInitializeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_initialize_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeInitializeINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcImeSetSingleReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeSetSingleReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_set_single_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeSetSingleReferenceINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcImeSetDualReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeSetDualReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_set_dual_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeSetDualReferenceINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcImeRefWindowSizeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeRefWindowSizeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_ref_window_size_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeRefWindowSizeINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcImeAdjustRefOffsetINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeAdjustRefOffsetINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_adjust_ref_offset_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeAdjustRefOffsetINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcImeConvertToMcePayloadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeConvertToMcePayloadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_convert_to_mce_payload_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeConvertToMcePayloadINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeSetMaxMotionVectorCountINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeSetMaxMotionVectorCountINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_set_max_motion_vector_count_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeSetMaxMotionVectorCountINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcImeSetUnidirectionalMixDisableINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeSetUnidirectionalMixDisableINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_set_unidirectional_mix_disable_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeSetUnidirectionalMixDisableINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeSetEarlySearchTerminationThresholdINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeSetEarlySearchTerminationThresholdINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_set_early_search_termination_threshold_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeSetEarlySearchTerminationThresholdINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcImeSetWeightedSadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeSetWeightedSadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_set_weighted_sad_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeSetWeightedSadINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcImeEvaluateWithSingleReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeEvaluateWithSingleReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_evaluate_with_single_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeEvaluateWithSingleReferenceINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcImeEvaluateWithDualReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeEvaluateWithDualReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_evaluate_with_dual_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeEvaluateWithDualReferenceINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcImeEvaluateWithSingleReferenceStreaminINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeEvaluateWithSingleReferenceStreaminINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_evaluate_with_single_reference_streamin_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeEvaluateWithSingleReferenceStreaminINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcImeEvaluateWithDualReferenceStreaminINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeEvaluateWithDualReferenceStreaminINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_evaluate_with_dual_reference_streamin_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeEvaluateWithDualReferenceStreaminINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpSubgroupAvcImeEvaluateWithSingleReferenceStreamoutINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeEvaluateWithSingleReferenceStreamoutINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_evaluate_with_single_reference_streamout_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeEvaluateWithSingleReferenceStreamoutINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcImeEvaluateWithDualReferenceStreamoutINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeEvaluateWithDualReferenceStreamoutINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_evaluate_with_dual_reference_streamout_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeEvaluateWithDualReferenceStreamoutINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcImeEvaluateWithSingleReferenceStreaminoutINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeEvaluateWithSingleReferenceStreaminoutINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_evaluate_with_single_reference_streaminout_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeEvaluateWithSingleReferenceStreaminoutINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcImeEvaluateWithDualReferenceStreaminoutINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeEvaluateWithDualReferenceStreaminoutINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_evaluate_with_dual_reference_streaminout_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeEvaluateWithDualReferenceStreaminoutINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpSubgroupAvcImeConvertToMceResultINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeConvertToMceResultINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_convert_to_mce_result_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeConvertToMceResultINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeGetSingleReferenceStreaminINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetSingleReferenceStreaminINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_single_reference_streamin_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetSingleReferenceStreaminINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeGetDualReferenceStreaminINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetDualReferenceStreaminINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_dual_reference_streamin_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetDualReferenceStreaminINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeStripSingleReferenceStreamoutINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeStripSingleReferenceStreamoutINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_strip_single_reference_streamout_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeStripSingleReferenceStreamoutINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeStripDualReferenceStreamoutINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeStripDualReferenceStreamoutINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_strip_dual_reference_streamout_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeStripDualReferenceStreamoutINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeMotionVectorsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeMotionVectorsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_streamout_single_reference_major_shape_motion_vectors_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeMotionVectorsINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeDistortionsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeDistortionsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_streamout_single_reference_major_shape_distortions_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeDistortionsINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeReferenceIdsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeReferenceIdsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_streamout_single_reference_major_shape_reference_ids_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetStreamoutSingleReferenceMajorShapeReferenceIdsINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeMotionVectorsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeMotionVectorsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_streamout_dual_reference_major_shape_motion_vectors_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeMotionVectorsINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeDistortionsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeDistortionsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_streamout_dual_reference_major_shape_distortions_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeDistortionsINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeReferenceIdsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeReferenceIdsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_streamout_dual_reference_major_shape_reference_ids_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetStreamoutDualReferenceMajorShapeReferenceIdsINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcImeGetBorderReachedINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetBorderReachedINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_border_reached_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetBorderReachedINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcImeGetTruncatedSearchIndicationINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetTruncatedSearchIndicationINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_truncated_search_indication_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetTruncatedSearchIndicationINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeGetUnidirectionalEarlySearchTerminationINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetUnidirectionalEarlySearchTerminationINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_unidirectional_early_search_termination_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetUnidirectionalEarlySearchTerminationINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeGetWeightingPatternMinimumMotionVectorINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetWeightingPatternMinimumMotionVectorINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_weighting_pattern_minimum_motion_vector_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetWeightingPatternMinimumMotionVectorINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcImeGetWeightingPatternMinimumDistortionINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcImeGetWeightingPatternMinimumDistortionINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ime_get_weighting_pattern_minimum_distortion_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcImeGetWeightingPatternMinimumDistortionINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcFmeInitializeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcFmeInitializeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_fme_initialize_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcFmeInitializeINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7))
	return r
}

inst_OpSubgroupAvcBmeInitializeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcBmeInitializeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_bme_initialize_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcBmeInitializeINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpSubgroupAvcRefConvertToMcePayloadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcRefConvertToMcePayloadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ref_convert_to_mce_payload_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcRefConvertToMcePayloadINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcRefSetBidirectionalMixDisableINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcRefSetBidirectionalMixDisableINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ref_set_bidirectional_mix_disable_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcRefSetBidirectionalMixDisableINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcRefSetBilinearFilterEnableINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcRefSetBilinearFilterEnableINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ref_set_bilinear_filter_enable_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcRefSetBilinearFilterEnableINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcRefEvaluateWithSingleReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcRefEvaluateWithSingleReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ref_evaluate_with_single_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcRefEvaluateWithSingleReferenceINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcRefEvaluateWithDualReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcRefEvaluateWithDualReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ref_evaluate_with_dual_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcRefEvaluateWithDualReferenceINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcRefEvaluateWithMultiReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcRefEvaluateWithMultiReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ref_evaluate_with_multi_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcRefEvaluateWithMultiReferenceINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcRefEvaluateWithMultiReferenceInterlacedINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcRefEvaluateWithMultiReferenceInterlacedINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ref_evaluate_with_multi_reference_interlaced_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcRefEvaluateWithMultiReferenceInterlacedINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcRefConvertToMceResultINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcRefConvertToMceResultINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_ref_convert_to_mce_result_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcRefConvertToMceResultINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicInitializeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicInitializeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_initialize_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicInitializeINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicConfigureSkcINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicConfigureSkcINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_configure_skc_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicConfigureSkcINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpSubgroupAvcSicConfigureIpeLumaINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicConfigureIpeLumaINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_configure_ipe_luma_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicConfigureIpeLumaINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpSubgroupAvcSicConfigureIpeLumaChromaINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	buf[n] = op_value(op11); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicConfigureIpeLumaChromaINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_configure_ipe_luma_chroma_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id, op11: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicConfigureIpeLumaChromaINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8, op9, op10, op11))
	return r
}

inst_OpSubgroupAvcSicGetMotionVectorMaskINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetMotionVectorMaskINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_motion_vector_mask_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetMotionVectorMaskINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcSicConvertToMcePayloadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicConvertToMcePayloadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_convert_to_mce_payload_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicConvertToMcePayloadINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicSetIntraLumaShapePenaltyINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicSetIntraLumaShapePenaltyINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_set_intra_luma_shape_penalty_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicSetIntraLumaShapePenaltyINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcSicSetIntraLumaModeCostFunctionINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicSetIntraLumaModeCostFunctionINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_set_intra_luma_mode_cost_function_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicSetIntraLumaModeCostFunctionINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcSicSetIntraChromaModeCostFunctionINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicSetIntraChromaModeCostFunctionINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_set_intra_chroma_mode_cost_function_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicSetIntraChromaModeCostFunctionINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcSicSetBilinearFilterEnableINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicSetBilinearFilterEnableINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_set_bilinear_filter_enable_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicSetBilinearFilterEnableINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicSetSkcForwardTransformEnableINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicSetSkcForwardTransformEnableINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_set_skc_forward_transform_enable_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicSetSkcForwardTransformEnableINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcSicSetBlockBasedRawSkipSadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicSetBlockBasedRawSkipSadINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_set_block_based_raw_skip_sad_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicSetBlockBasedRawSkipSadINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcSicEvaluateIpeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicEvaluateIpeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_evaluate_ipe_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicEvaluateIpeINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpSubgroupAvcSicEvaluateWithSingleReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicEvaluateWithSingleReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_evaluate_with_single_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicEvaluateWithSingleReferenceINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcSicEvaluateWithDualReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicEvaluateWithDualReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_evaluate_with_dual_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicEvaluateWithDualReferenceINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcSicEvaluateWithMultiReferenceINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicEvaluateWithMultiReferenceINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_evaluate_with_multi_reference_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicEvaluateWithMultiReferenceINTEL(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpSubgroupAvcSicEvaluateWithMultiReferenceInterlacedINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicEvaluateWithMultiReferenceInterlacedINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_evaluate_with_multi_reference_interlaced_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicEvaluateWithMultiReferenceInterlacedINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSubgroupAvcSicConvertToMceResultINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicConvertToMceResultINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_convert_to_mce_result_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicConvertToMceResultINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicGetIpeLumaShapeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetIpeLumaShapeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_ipe_luma_shape_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetIpeLumaShapeINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicGetBestIpeLumaDistortionINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetBestIpeLumaDistortionINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_best_ipe_luma_distortion_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetBestIpeLumaDistortionINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicGetBestIpeChromaDistortionINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetBestIpeChromaDistortionINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_best_ipe_chroma_distortion_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetBestIpeChromaDistortionINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicGetPackedIpeLumaModesINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetPackedIpeLumaModesINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_packed_ipe_luma_modes_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetPackedIpeLumaModesINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicGetIpeChromaModeINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetIpeChromaModeINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_ipe_chroma_mode_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetIpeChromaModeINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicGetPackedSkcLumaCountThresholdINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetPackedSkcLumaCountThresholdINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_packed_skc_luma_count_threshold_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetPackedSkcLumaCountThresholdINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicGetPackedSkcLumaSumThresholdINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetPackedSkcLumaSumThresholdINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_packed_skc_luma_sum_threshold_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetPackedSkcLumaSumThresholdINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSubgroupAvcSicGetInterRawSadsINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroupAvcSicGetInterRawSadsINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_avc_sic_get_inter_raw_sads_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupAvcSicGetInterRawSadsINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpVariableLengthArrayINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpVariableLengthArrayINTEL), result = {result, result_type}, operands = buf[:n]}
}

variable_length_array_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpVariableLengthArrayINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpSaveMemoryINTEL :: #force_inline proc "contextless" (result_type: Type_Ref, result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpSaveMemoryINTEL), result = {result, result_type}}
}

save_memory_intel :: proc(b: ^Builder, result_type: Type_Ref) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSaveMemoryINTEL(result_type, r))
	return r
}

inst_OpRestoreMemoryINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRestoreMemoryINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

restore_memory_intel :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpRestoreMemoryINTEL(opbuf(b, 1), op1))
}

inst_OpArbitraryFloatSinCosPiALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatSinCosPiALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_sin_cos_pi_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatSinCosPiALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatCastALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatCastALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_cast_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatCastALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatCastFromIntALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatCastFromIntALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_cast_from_int_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatCastFromIntALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatCastToIntALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatCastToIntALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_cast_to_int_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatCastToIntALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatAddALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatAddALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_add_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatAddALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpArbitraryFloatSubALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatSubALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_sub_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatSubALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpArbitraryFloatMulALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatMulALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_mul_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatMulALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpArbitraryFloatDivALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatDivALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_div_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatDivALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpArbitraryFloatGTALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatGTALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_gtaltera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatGTALTERA(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpArbitraryFloatGEALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatGEALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_gealtera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatGEALTERA(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpArbitraryFloatLTALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatLTALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_ltaltera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatLTALTERA(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpArbitraryFloatLEALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatLEALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_lealtera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatLEALTERA(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpArbitraryFloatEQALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatEQALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_eqaltera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatEQALTERA(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpArbitraryFloatRecipALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatRecipALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_recip_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatRecipALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatRSqrtALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatRSqrtALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_r_sqrt_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatRSqrtALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatCbrtALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatCbrtALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_cbrt_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatCbrtALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatHypotALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatHypotALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_hypot_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatHypotALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpArbitraryFloatSqrtALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatSqrtALTERA), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_sqrt_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatSqrtALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatLogINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatLogINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_log_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatLogINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatLog2INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatLog2INTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_log2_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatLog2INTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatLog10INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatLog10INTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_log10_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatLog10INTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatLog1pINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatLog1pINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_log1p_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatLog1pINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatExpINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatExpINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_exp_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatExpINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatExp2INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatExp2INTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_exp2_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatExp2INTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatExp10INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatExp10INTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_exp10_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatExp10INTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatExpm1INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatExpm1INTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_expm1_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatExpm1INTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatSinINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatSinINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_sin_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatSinINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatCosINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatCosINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_cos_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatCosINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatSinCosINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatSinCosINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_sin_cos_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatSinCosINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatSinPiINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatSinPiINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_sin_pi_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatSinPiINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatCosPiINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatCosPiINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_cos_pi_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatCosPiINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatASinINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatASinINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_a_sin_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatASinINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatASinPiINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatASinPiINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_a_sin_pi_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatASinPiINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatACosINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatACosINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_a_cos_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatACosINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatACosPiINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatACosPiINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_a_cos_pi_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatACosPiINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatATanINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatATanINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_a_tan_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatATanINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatATanPiINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatATanPiINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_a_tan_pi_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatATanPiINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpArbitraryFloatATan2INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatATan2INTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_a_tan2_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatATan2INTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpArbitraryFloatPowINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatPowINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_pow_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatPowINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpArbitraryFloatPowRINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatPowRINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_pow_rintel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatPowRINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpArbitraryFloatPowNINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	buf[n] = op_int(op7); n += 1
	buf[n] = op_int(op8); n += 1
	return Operation{opcode = u16(Opcode.OpArbitraryFloatPowNINTEL), result = {result, result_type}, operands = buf[:n]}
}

arbitrary_float_pow_nintel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: i64, op5: i64, op6: i64, op7: i64, op8: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArbitraryFloatPowNINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6, op7, op8))
	return r
}

inst_OpLoopControlINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: []i64) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_int(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpLoopControlINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

loop_control_intel :: proc(b: ^Builder, op1: []i64) {
	append(&b.ops, inst_OpLoopControlINTEL(opbuf(b, len(op1)), op1))
}

inst_OpAliasDomainDeclINTEL :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Maybe(Id)) -> Operation {
	n := 0
	if x, xok := op1.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpAliasDomainDeclINTEL), result = {id = result}, operands = buf[:n]}
}

alias_domain_decl_intel :: proc(b: ^Builder, op1: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAliasDomainDeclINTEL(opbuf(b, 1), r, op1))
	return r
}

inst_OpAliasScopeDeclINTEL :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Id, op2: Maybe(Id)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	if x, xok := op2.?; xok { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpAliasScopeDeclINTEL), result = {id = result}, operands = buf[:n]}
}

alias_scope_decl_intel :: proc(b: ^Builder, op1: Id, op2: Maybe(Id)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAliasScopeDeclINTEL(opbuf(b, 1 + 1), r, op1, op2))
	return r
}

inst_OpAliasScopeListDeclINTEL :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpAliasScopeListDeclINTEL), result = {id = result}, operands = buf[:n]}
}

alias_scope_list_decl_intel :: proc(b: ^Builder, op1: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAliasScopeListDeclINTEL(opbuf(b, len(op1)), r, op1))
	return r
}

inst_OpFixedSqrtALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedSqrtALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_sqrt_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedSqrtALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedRecipALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedRecipALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_recip_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedRecipALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedRsqrtALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedRsqrtALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_rsqrt_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedRsqrtALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedSinALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedSinALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_sin_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedSinALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedCosALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedCosALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_cos_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedCosALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedSinCosALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedSinCosALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_sin_cos_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedSinCosALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedSinPiALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedSinPiALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_sin_pi_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedSinPiALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedCosPiALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedCosPiALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_cos_pi_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedCosPiALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedSinCosPiALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedSinCosPiALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_sin_cos_pi_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedSinCosPiALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedLogALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedLogALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_log_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedLogALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpFixedExpALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	buf[n] = op_int(op6); n += 1
	return Operation{opcode = u16(Opcode.OpFixedExpALTERA), result = {result, result_type}, operands = buf[:n]}
}

fixed_exp_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64, op6: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFixedExpALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5, op6))
	return r
}

inst_OpPtrCastToCrossWorkgroupALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpPtrCastToCrossWorkgroupALTERA), result = {result, result_type}, operands = buf[:n]}
}

ptr_cast_to_cross_workgroup_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPtrCastToCrossWorkgroupALTERA(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpCrossWorkgroupCastToPtrALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpCrossWorkgroupCastToPtrALTERA), result = {result, result_type}, operands = buf[:n]}
}

cross_workgroup_cast_to_ptr_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpCrossWorkgroupCastToPtrALTERA(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpReadPipeBlockingALTERA :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpReadPipeBlockingALTERA), result = {id = ID_NONE}, operands = buf[:n]}
}

read_pipe_blocking_altera :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id) {
	append(&b.ops, inst_OpReadPipeBlockingALTERA(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpWritePipeBlockingALTERA :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpWritePipeBlockingALTERA), result = {id = ID_NONE}, operands = buf[:n]}
}

write_pipe_blocking_altera :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id) {
	append(&b.ops, inst_OpWritePipeBlockingALTERA(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpFPGARegALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpFPGARegALTERA), result = {result, result_type}, operands = buf[:n]}
}

fpga_reg_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFPGARegALTERA(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpRayQueryGetRayTMinKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetRayTMinKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_ray_t_min_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetRayTMinKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpRayQueryGetRayFlagsKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetRayFlagsKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_ray_flags_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetRayFlagsKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpRayQueryGetIntersectionTKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionTKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_tkhr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionTKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionInstanceCustomIndexKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionInstanceCustomIndexKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_instance_custom_index_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionInstanceCustomIndexKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionInstanceIdKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionInstanceIdKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_instance_id_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionInstanceIdKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionInstanceShaderBindingTableRecordOffsetKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionInstanceShaderBindingTableRecordOffsetKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_instance_shader_binding_table_record_offset_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionInstanceShaderBindingTableRecordOffsetKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionGeometryIndexKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionGeometryIndexKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_geometry_index_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionGeometryIndexKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionPrimitiveIndexKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionPrimitiveIndexKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_primitive_index_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionPrimitiveIndexKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionBarycentricsKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionBarycentricsKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_barycentrics_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionBarycentricsKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionFrontFaceKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionFrontFaceKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_front_face_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionFrontFaceKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionCandidateAABBOpaqueKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionCandidateAABBOpaqueKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_candidate_aabb_opaque_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionCandidateAABBOpaqueKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpRayQueryGetIntersectionObjectRayDirectionKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionObjectRayDirectionKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_object_ray_direction_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionObjectRayDirectionKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionObjectRayOriginKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionObjectRayOriginKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_object_ray_origin_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionObjectRayOriginKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetWorldRayDirectionKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetWorldRayDirectionKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_world_ray_direction_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetWorldRayDirectionKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpRayQueryGetWorldRayOriginKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetWorldRayOriginKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_world_ray_origin_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetWorldRayOriginKHR(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpRayQueryGetIntersectionObjectToWorldKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionObjectToWorldKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_object_to_world_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionObjectToWorldKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpRayQueryGetIntersectionWorldToObjectKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpRayQueryGetIntersectionWorldToObjectKHR), result = {result, result_type}, operands = buf[:n]}
}

ray_query_get_intersection_world_to_object_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRayQueryGetIntersectionWorldToObjectKHR(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpAtomicFAddEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpAtomicFAddEXT), result = {result, result_type}, operands = buf[:n]}
}

atomic_f_add_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpAtomicFAddEXT(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpTypeBufferSurfaceINTEL :: #force_inline proc "contextless" (buf: []Operand, result: Id, op1: Access_Qualifier) -> Operation {
	n := 0
	buf[n] = op_int(i64(op1)); n += 1
	return Operation{opcode = u16(Opcode.OpTypeBufferSurfaceINTEL), result = {id = result}, operands = buf[:n]}
}

type_buffer_surface_intel :: proc(b: ^Builder, op1: Access_Qualifier) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeBufferSurfaceINTEL(opbuf(b, 1), r, op1))
	return r
}

inst_OpTypeStructContinuedINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTypeStructContinuedINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

type_struct_continued_intel :: proc(b: ^Builder, op1: []Id) {
	append(&b.ops, inst_OpTypeStructContinuedINTEL(opbuf(b, len(op1)), op1))
}

inst_OpConstantCompositeContinuedINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpConstantCompositeContinuedINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

constant_composite_continued_intel :: proc(b: ^Builder, op1: []Id) {
	append(&b.ops, inst_OpConstantCompositeContinuedINTEL(opbuf(b, len(op1)), op1))
}

inst_OpSpecConstantCompositeContinuedINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpSpecConstantCompositeContinuedINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

spec_constant_composite_continued_intel :: proc(b: ^Builder, op1: []Id) {
	append(&b.ops, inst_OpSpecConstantCompositeContinuedINTEL(opbuf(b, len(op1)), op1))
}

inst_OpCompositeConstructContinuedINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpCompositeConstructContinuedINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

composite_construct_continued_intel :: proc(b: ^Builder, op1: []Id) {
	append(&b.ops, inst_OpCompositeConstructContinuedINTEL(opbuf(b, len(op1)), op1))
}

inst_OpConvertFToBF16INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertFToBF16INTEL), result = {result, result_type}, operands = buf[:n]}
}

convert_f_to_bf16_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertFToBF16INTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertBF16ToFINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertBF16ToFINTEL), result = {result, result_type}, operands = buf[:n]}
}

convert_bf16_to_fintel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertBF16ToFINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpControlBarrierArriveEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpControlBarrierArriveEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

control_barrier_arrive_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpControlBarrierArriveEXT(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpControlBarrierWaitEXT :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpControlBarrierWaitEXT), result = {id = ID_NONE}, operands = buf[:n]}
}

control_barrier_wait_ext :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id) {
	append(&b.ops, inst_OpControlBarrierWaitEXT(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpArithmeticFenceEXT :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpArithmeticFenceEXT), result = {result, result_type}, operands = buf[:n]}
}

arithmetic_fence_ext :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpArithmeticFenceEXT(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpTaskSequenceCreateALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	buf[n] = op_int(op5); n += 1
	return Operation{opcode = u16(Opcode.OpTaskSequenceCreateALTERA), result = {result, result_type}, operands = buf[:n]}
}

task_sequence_create_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: i64, op4: i64, op5: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTaskSequenceCreateALTERA(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpTaskSequenceAsyncALTERA :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	for x in op2 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpTaskSequenceAsyncALTERA), result = {id = ID_NONE}, operands = buf[:n]}
}

task_sequence_async_altera :: proc(b: ^Builder, op1: Id, op2: []Id) {
	append(&b.ops, inst_OpTaskSequenceAsyncALTERA(opbuf(b, 1 + len(op2)), op1, op2))
}

inst_OpTaskSequenceGetALTERA :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpTaskSequenceGetALTERA), result = {result, result_type}, operands = buf[:n]}
}

task_sequence_get_altera :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTaskSequenceGetALTERA(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpTaskSequenceReleaseALTERA :: #force_inline proc "contextless" (buf: []Operand, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpTaskSequenceReleaseALTERA), result = {id = ID_NONE}, operands = buf[:n]}
}

task_sequence_release_altera :: proc(b: ^Builder, op1: Id) {
	append(&b.ops, inst_OpTaskSequenceReleaseALTERA(opbuf(b, 1), op1))
}

inst_OpTypeTaskSequenceALTERA :: #force_inline proc "contextless" (result: Id) -> Operation {
	return Operation{opcode = u16(Opcode.OpTypeTaskSequenceALTERA), result = {id = result}}
}

type_task_sequence_altera :: proc(b: ^Builder) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpTypeTaskSequenceALTERA(r))
	return r
}

inst_OpSubgroupBlockPrefetchINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	if x, xok := op3.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpSubgroupBlockPrefetchINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup_block_prefetch_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Maybe(Memory_Access)) {
	append(&b.ops, inst_OpSubgroupBlockPrefetchINTEL(opbuf(b, 1 + 1 + 1), op1, op2, op3))
}

inst_OpSubgroup2DBlockLoadINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroup2DBlockLoadINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup2_d_block_load_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id) {
	append(&b.ops, inst_OpSubgroup2DBlockLoadINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10))
}

inst_OpSubgroup2DBlockLoadTransformINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroup2DBlockLoadTransformINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup2_d_block_load_transform_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id) {
	append(&b.ops, inst_OpSubgroup2DBlockLoadTransformINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10))
}

inst_OpSubgroup2DBlockLoadTransposeINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroup2DBlockLoadTransposeINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup2_d_block_load_transpose_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id) {
	append(&b.ops, inst_OpSubgroup2DBlockLoadTransposeINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10))
}

inst_OpSubgroup2DBlockPrefetchINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroup2DBlockPrefetchINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup2_d_block_prefetch_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id) {
	append(&b.ops, inst_OpSubgroup2DBlockPrefetchINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9))
}

inst_OpSubgroup2DBlockStoreINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	buf[n] = op_value(op5); n += 1
	buf[n] = op_value(op6); n += 1
	buf[n] = op_value(op7); n += 1
	buf[n] = op_value(op8); n += 1
	buf[n] = op_value(op9); n += 1
	buf[n] = op_value(op10); n += 1
	return Operation{opcode = u16(Opcode.OpSubgroup2DBlockStoreINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

subgroup2_d_block_store_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Id, op5: Id, op6: Id, op7: Id, op8: Id, op9: Id, op10: Id) {
	append(&b.ops, inst_OpSubgroup2DBlockStoreINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1), op1, op2, op3, op4, op5, op6, op7, op8, op9, op10))
}

inst_OpSubgroupMatrixMultiplyAccumulateINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Matrix_Multiply_Accumulate_Operands)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	if x, xok := op5.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpSubgroupMatrixMultiplyAccumulateINTEL), result = {result, result_type}, operands = buf[:n]}
}

subgroup_matrix_multiply_accumulate_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id, op5: Maybe(Matrix_Multiply_Accumulate_Operands)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSubgroupMatrixMultiplyAccumulateINTEL(opbuf(b, 1 + 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4, op5))
	return r
}

inst_OpBitwiseFunctionINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpBitwiseFunctionINTEL), result = {result, result_type}, operands = buf[:n]}
}

bitwise_function_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpBitwiseFunctionINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpUntypedVariableLengthArrayINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	return Operation{opcode = u16(Opcode.OpUntypedVariableLengthArrayINTEL), result = {result, result_type}, operands = buf[:n]}
}

untyped_variable_length_array_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpUntypedVariableLengthArrayINTEL(opbuf(b, 1 + 1), result_type, r, op1, op2))
	return r
}

inst_OpConditionalExtensionINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: string) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	n += pack_string_operands(buf[n:], op2)
	return Operation{opcode = u16(Opcode.OpConditionalExtensionINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

conditional_extension_intel :: proc(b: ^Builder, op1: Id, op2: string) {
	append(&b.ops, inst_OpConditionalExtensionINTEL(opbuf(b, 1 + (len(op2) + 4) / 4), op1, op2))
}

inst_OpConditionalEntryPointINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Execution_Model, op3: Id, op4: string, op5: []Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	n += pack_string_operands(buf[n:], op4)
	for x in op5 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpConditionalEntryPointINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

conditional_entry_point_intel :: proc(b: ^Builder, op1: Id, op2: Execution_Model, op3: Id, op4: string, op5: []Id) {
	append(&b.ops, inst_OpConditionalEntryPointINTEL(opbuf(b, 1 + 1 + 1 + (len(op4) + 4) / 4 + len(op5)), op1, op2, op3, op4, op5))
}

inst_OpConditionalCapabilityINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Capability) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	return Operation{opcode = u16(Opcode.OpConditionalCapabilityINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

conditional_capability_intel :: proc(b: ^Builder, op1: Id, op2: Capability) {
	append(&b.ops, inst_OpConditionalCapabilityINTEL(opbuf(b, 1 + 1), op1, op2))
}

inst_OpSpecConstantTargetINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: i64, op2: []i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	for x in op2 { buf[n] = op_int(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpSpecConstantTargetINTEL), result = {result, result_type}, operands = buf[:n]}
}

spec_constant_target_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: i64, op2: []i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantTargetINTEL(opbuf(b, 1 + len(op2)), result_type, r, op1, op2))
	return r
}

inst_OpSpecConstantArchitectureINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: i64, op2: i64, op3: i64, op4: i64) -> Operation {
	n := 0
	buf[n] = op_int(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_int(op4); n += 1
	return Operation{opcode = u16(Opcode.OpSpecConstantArchitectureINTEL), result = {result, result_type}, operands = buf[:n]}
}

spec_constant_architecture_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: i64, op2: i64, op3: i64, op4: i64) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantArchitectureINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpSpecConstantCapabilitiesINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []Capability) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_int(i64(x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpSpecConstantCapabilitiesINTEL), result = {result, result_type}, operands = buf[:n]}
}

spec_constant_capabilities_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: []Capability) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpSpecConstantCapabilitiesINTEL(opbuf(b, len(op1)), result_type, r, op1))
	return r
}

inst_OpConditionalCopyObjectINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: []Id) -> Operation {
	n := 0
	for x in op1 { buf[n] = op_value(x); n += 1 }
	return Operation{opcode = u16(Opcode.OpConditionalCopyObjectINTEL), result = {result, result_type}, operands = buf[:n]}
}

conditional_copy_object_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: []Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConditionalCopyObjectINTEL(opbuf(b, len(op1)), result_type, r, op1))
	return r
}

inst_OpPredicatedLoadINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpPredicatedLoadINTEL), result = {result, result_type}, operands = buf[:n]}
}

predicated_load_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access)) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpPredicatedLoadINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpPredicatedStoreINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access)) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	if x, xok := op4.?; xok { buf[n] = op_int(i64(transmute(u32)x)); n += 1 }
	return Operation{opcode = u16(Opcode.OpPredicatedStoreINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

predicated_store_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: Id, op4: Maybe(Memory_Access)) {
	append(&b.ops, inst_OpPredicatedStoreINTEL(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpGroupIMulKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupIMulKHR), result = {result, result_type}, operands = buf[:n]}
}

group_i_mul_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupIMulKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupFMulKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupFMulKHR), result = {result, result_type}, operands = buf[:n]}
}

group_f_mul_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupFMulKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupBitwiseAndKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupBitwiseAndKHR), result = {result, result_type}, operands = buf[:n]}
}

group_bitwise_and_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupBitwiseAndKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupBitwiseOrKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupBitwiseOrKHR), result = {result, result_type}, operands = buf[:n]}
}

group_bitwise_or_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupBitwiseOrKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupBitwiseXorKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupBitwiseXorKHR), result = {result, result_type}, operands = buf[:n]}
}

group_bitwise_xor_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupBitwiseXorKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupLogicalAndKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupLogicalAndKHR), result = {result, result_type}, operands = buf[:n]}
}

group_logical_and_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupLogicalAndKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupLogicalOrKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupLogicalOrKHR), result = {result, result_type}, operands = buf[:n]}
}

group_logical_or_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupLogicalOrKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpGroupLogicalXorKHR :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Group_Operation, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(i64(op2)); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpGroupLogicalXorKHR), result = {result, result_type}, operands = buf[:n]}
}

group_logical_xor_khr :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Group_Operation, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpGroupLogicalXorKHR(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpRoundFToTF32INTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpRoundFToTF32INTEL), result = {result, result_type}, operands = buf[:n]}
}

round_f_to_tf32_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpRoundFToTF32INTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpMaskedGatherINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: i64, op3: Id, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_int(op2); n += 1
	buf[n] = op_value(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpMaskedGatherINTEL), result = {result, result_type}, operands = buf[:n]}
}

masked_gather_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: i64, op3: Id, op4: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpMaskedGatherINTEL(opbuf(b, 1 + 1 + 1 + 1), result_type, r, op1, op2, op3, op4))
	return r
}

inst_OpMaskedScatterINTEL :: #force_inline proc "contextless" (buf: []Operand, op1: Id, op2: Id, op3: i64, op4: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_int(op3); n += 1
	buf[n] = op_value(op4); n += 1
	return Operation{opcode = u16(Opcode.OpMaskedScatterINTEL), result = {id = ID_NONE}, operands = buf[:n]}
}

masked_scatter_intel :: proc(b: ^Builder, op1: Id, op2: Id, op3: i64, op4: Id) {
	append(&b.ops, inst_OpMaskedScatterINTEL(opbuf(b, 1 + 1 + 1 + 1), op1, op2, op3, op4))
}

inst_OpConvertHandleToImageINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertHandleToImageINTEL), result = {result, result_type}, operands = buf[:n]}
}

convert_handle_to_image_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertHandleToImageINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertHandleToSamplerINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertHandleToSamplerINTEL), result = {result, result_type}, operands = buf[:n]}
}

convert_handle_to_sampler_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertHandleToSamplerINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpConvertHandleToSampledImageINTEL :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	return Operation{opcode = u16(Opcode.OpConvertHandleToSampledImageINTEL), result = {result, result_type}, operands = buf[:n]}
}

convert_handle_to_sampled_image_intel :: proc(b: ^Builder, result_type: Type_Ref, op1: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpConvertHandleToSampledImageINTEL(opbuf(b, 1), result_type, r, op1))
	return r
}

inst_OpFDot2MixAcc32VALVE :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpFDot2MixAcc32VALVE), result = {result, result_type}, operands = buf[:n]}
}

f_dot2_mix_acc32_valve :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFDot2MixAcc32VALVE(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpFDot2MixAcc16VALVE :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpFDot2MixAcc16VALVE), result = {result, result_type}, operands = buf[:n]}
}

f_dot2_mix_acc16_valve :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFDot2MixAcc16VALVE(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}

inst_OpFDot4MixAcc32VALVE :: #force_inline proc "contextless" (buf: []Operand, result_type: Type_Ref, result: Id, op1: Id, op2: Id, op3: Id) -> Operation {
	n := 0
	buf[n] = op_value(op1); n += 1
	buf[n] = op_value(op2); n += 1
	buf[n] = op_value(op3); n += 1
	return Operation{opcode = u16(Opcode.OpFDot4MixAcc32VALVE), result = {result, result_type}, operands = buf[:n]}
}

f_dot4_mix_acc32_valve :: proc(b: ^Builder, result_type: Type_Ref, op1: Id, op2: Id, op3: Id) -> Id {
	r := alloc_id(b)
	append(&b.ops, inst_OpFDot4MixAcc32VALVE(opbuf(b, 1 + 1 + 1), result_type, r, op1, op2, op3))
	return r
}
