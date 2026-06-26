// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

import "base:intrinsics"
import "core:strings"

// =============================================================================
// SECTION: Decoder  (SPIR-V word stream -> Module)
// =============================================================================
//
// The inverse of the encoder: read the 5-word header (detecting endianness from
// the magic), then walk the instruction stream, lowering each instruction by its
// opcode into the structured Module + side sections. Types/constants/globals/
// functions are recovered into the ir core; the preamble / debug / annotations
// into the SPIR-V sections; the flat <id> space into the side id tables, with an
// id->Type_Ref map so operands that name a type lower to a TYPE operand.
//
// Every slice/string in the returned Module is allocated with `allocator` (set
// as context.allocator for the whole pass). String operands assume little-endian
// byte packing -- our encoder's output; big-endian sources are a later refinement.

@(private="file")
Decoder :: struct {
	data: []u8,
	swap: bool,

	scratch: [dynamic]u32,   // reused per-instruction operand-word buffer

	// section accumulators
	caps:         [dynamic]Capability,
	exts:         [dynamic]string,
	ext_imports:  [dynamic]Ext_Import,
	addressing:   Addressing_Model,
	memory:       Memory_Model,
	entry_points: [dynamic]Entry_Point,
	exec_modes:   [dynamic]Exec_Mode,
	names:        [dynamic]Name,
	strs:         [dynamic]Str,
	src_lang:     u32,
	src_ver:      u32,
	src_file:     Id,
	decorations:  [dynamic]Decoration_Inst,
	types:        [dynamic]Type,
	type_ids:     [dynamic]Id,
	id_to_type:   map[Id]Type_Ref,
	constants:    [dynamic]Constant,
	globals:      [dynamic]Global,
	global_ids:   [dynamic]Id,
	functions:    [dynamic]Function,
	function_ids: [dynamic]Id,

	// in-flight function / block
	in_fn:       bool,
	fn_sig:      Type_Ref,
	fn_id:       Id,
	fn_blocks:   [dynamic]Block,
	fn_params:   [dynamic]Result,   // OpFunctionParameters, attached to the entry block
	first_block: bool,
	have_blk:    bool,
	blk_id:      Id,
	blk_params:  []Result,
	blk_ops:     [dynamic]Operation,
}

@(private="file")
rd :: #force_inline proc "contextless" (d: ^Decoder, wi: int) -> u32 {
	o := wi * 4
	w := u32(d.data[o]) | (u32(d.data[o + 1]) << 8) | (u32(d.data[o + 2]) << 16) | (u32(d.data[o + 3]) << 24)
	return d.swap ? intrinsics.byte_swap(w) : w
}

// A LiteralString carried in `w`: NUL-terminated UTF-8 packed little-endian into
// words. Returns the (cloned) string and the words it occupied.
@(private="file")
rd_string :: proc(d: ^Decoder, w: []u32) -> (s: string, nwords: int) {
	buf: [dynamic]u8
	defer delete(buf)
	outer: for word in w {
		for b in 0 ..< 4 {
			c := u8(word >> uint(b * 8))
			if c == 0 { break outer }
			append(&buf, c)
		}
	}
	return strings.clone(string(buf[:])), (len(buf) + 4) / 4
}

// An IdRef operand: a known type id lowers to a TYPE operand, anything else to a VALUE.
@(private="file")
id_operand :: proc(d: ^Decoder, w: u32) -> Operand {
	if t, is_type := d.id_to_type[Id(w)]; is_type { return op_type(t) }
	return op_value(Id(w))
}

@(private="file")
is_id_spec :: proc "contextless" (k: Spec_Kind) -> bool {
	return k == .IdRef || k == .IdScope || k == .IdMemorySemantics
}

@(private="file")
tref :: proc(d: ^Decoder, id: u32) -> Type_Ref {
	if r, ok := d.id_to_type[Id(id)]; ok { return r }
	return TYPE_NONE
}

@(private="file")
add_type :: proc(d: ^Decoder, id: Id, t: Type) {
	d.id_to_type[id] = Type_Ref(len(d.types))
	append(&d.types, t)
	append(&d.type_ids, id)
}

// Decode a function-body operation generically, by its operand layout: the
// result-type/result-id prefix from the leading specs, then one operand per
// remaining spec (Id specs -> entity/type refs, the rest -> integer literals).
@(private="file")
decode_operation :: proc(d: ^Decoder, opcode: Opcode, w: []u32) -> Operation {
	op: Operation
	op.opcode = u16(opcode)
	op.result.id = ID_NONE
	run: Spec_Run
	if int(opcode) < len(INSTRUCTION_INDEX) { run = INSTRUCTION_INDEX[u16(opcode)] }

	wi, si := 0, 0
	if si < int(run.count) && INSTRUCTION_SPECS[int(run.start) + si].kind == .IdResultType {
		op.result.type = tref(d, w[wi]); wi += 1; si += 1
	}
	if si < int(run.count) && INSTRUCTION_SPECS[int(run.start) + si].kind == .IdResult {
		op.result.id = Id(w[wi]); wi += 1; si += 1
	}

	ops: [dynamic]Operand
	for ; si < int(run.count) && wi < len(w); si += 1 {
		spec := INSTRUCTION_SPECS[int(run.start) + si]
		if spec.quant == .VARIADIC {
			for wi < len(w) {
				append(&ops, is_id_spec(spec.kind) ? id_operand(d, w[wi]) : op_int(i64(w[wi])))
				wi += 1
			}
		} else {
			append(&ops, is_id_spec(spec.kind) ? id_operand(d, w[wi]) : op_int(i64(w[wi])))
			wi += 1
		}
	}
	// Trailing words beyond the fixed layout: the parameter operands an enum
	// value/bit pulls in (MemoryAccess Aligned's alignment, etc.). Captured as
	// literals -- enough to re-encode byte-exact (semantic typing is a refinement).
	for wi < len(w) {
		append(&ops, op_int(i64(w[wi])))
		wi += 1
	}
	op.operands = ops[:]
	return op
}

@(private="file")
finish_block :: proc(d: ^Decoder) {
	if d.have_blk {
		append(&d.fn_blocks, Block{id = d.blk_id, ops = d.blk_ops[:], params = d.blk_params})
		d.blk_ops = nil
		d.blk_params = nil
		d.have_blk = false
	}
}

@(private="file")
finish_function :: proc(d: ^Decoder) {
	finish_block(d)
	append(&d.functions, Function{signature = d.fn_sig, blocks = d.fn_blocks[:]})
	append(&d.function_ids, d.fn_id)
	d.fn_blocks = nil
	d.in_fn = false
}

@(private="file")
lower :: proc(d: ^Decoder, opcode: Opcode, w: []u32) {
	#partial switch opcode {
	case .OpCapability:
		append(&d.caps, Capability(w[0]))
	case .OpExtension:
		s, _ := rd_string(d, w); append(&d.exts, s)
	case .OpExtInstImport:
		s, _ := rd_string(d, w[1:]); append(&d.ext_imports, Ext_Import{Id(w[0]), s})
	case .OpMemoryModel:
		d.addressing = Addressing_Model(w[0]); d.memory = Memory_Model(w[1])
	case .OpEntryPoint:
		name, nw := rd_string(d, w[2:])
		iface: [dynamic]Id
		for j in 2 + nw ..< len(w) { append(&iface, Id(w[j])) }
		append(&d.entry_points, Entry_Point{Execution_Model(w[0]), Id(w[1]), name, iface[:]})
	case .OpExecutionMode, .OpExecutionModeId:
		operands := make([]u32, len(w) - 2)
		for j in 2 ..< len(w) { operands[j - 2] = w[j] }
		append(&d.exec_modes, Exec_Mode{Id(w[0]), Execution_Mode(w[1]), operands, opcode == .OpExecutionModeId})

	case .OpString:
		s, _ := rd_string(d, w[1:]); append(&d.strs, Str{Id(w[0]), s})
	case .OpSource:
		d.src_lang = w[0]; d.src_ver = len(w) > 1 ? w[1] : 0
		d.src_file = len(w) > 2 ? Id(w[2]) : ID_NONE
	case .OpName:
		name, _ := rd_string(d, w[1:]); append(&d.names, Name{Id(w[0]), MEMBER_NONE, name})
	case .OpMemberName:
		name, _ := rd_string(d, w[2:]); append(&d.names, Name{Id(w[0]), w[1], name})
	case .OpDecorate:
		ops := make([]u32, len(w) - 2)
		for j in 2 ..< len(w) { ops[j - 2] = w[j] }
		append(&d.decorations, Decoration_Inst{Id(w[0]), Decoration(w[1]), MEMBER_NONE, ops})
	case .OpMemberDecorate:
		ops := make([]u32, len(w) - 3)
		for j in 3 ..< len(w) { ops[j - 3] = w[j] }
		append(&d.decorations, Decoration_Inst{Id(w[0]), Decoration(w[2]), w[1], ops})

	case .OpTypeVoid:    add_type(d, Id(w[0]), Type{kind = .VOID})
	case .OpTypeBool:    add_type(d, Id(w[0]), Type{kind = .BOOL})
	case .OpTypeArray:   add_type(d, Id(w[0]), Type{kind = .ARRAY, elem = tref(d, w[1]), len_ref = Id(w[2])})
	case .OpTypeInt:     add_type(d, Id(w[0]), Type{kind = .INT,   bits = u16(w[1]), aux = u16(w[2] & 1)})
	case .OpTypeFloat:   add_type(d, Id(w[0]), Type{kind = .FLOAT, bits = u16(w[1])})
	case .OpTypeVector:  add_type(d, Id(w[0]), Type{kind = .VECTOR, elem = tref(d, w[1]), count = w[2]})
	case .OpTypePointer: add_type(d, Id(w[0]), Type{kind = .POINTER, aux = u16(w[1]), elem = tref(d, w[2])})
	case .OpTypeStruct:
		fields := make([]Type_Ref, len(w) - 1)
		for j in 1 ..< len(w) { fields[j - 1] = tref(d, w[j]) }
		add_type(d, Id(w[0]), Type{kind = .STRUCT, fields = fields})
	case .OpTypeFunction:
		nparam := len(w) - 2
		fields := make([]Type_Ref, nparam + 1)
		for j in 0 ..< nparam { fields[j] = tref(d, w[2 + j]) }
		fields[nparam] = tref(d, w[1])   // return type last: fields = params ++ [result]
		add_type(d, Id(w[0]), Type{kind = .FUNCTION, fields = fields, count = u32(nparam)})

	case .OpConstant:
		c := Constant{result = {Id(w[1]), tref(d, w[0])}, opcode = opcode, value = u64(w[2])}
		if len(w) > 3 { c.value |= u64(w[3]) << 32 }
		append(&d.constants, c)
	case .OpConstantTrue, .OpConstantFalse, .OpConstantNull:
		append(&d.constants, Constant{result = {Id(w[1]), tref(d, w[0])}, opcode = opcode})
	case .OpConstantComposite:
		elems := make([]Id, len(w) - 2)
		for j in 2 ..< len(w) { elems[j - 2] = Id(w[j]) }
		append(&d.constants, Constant{result = {Id(w[1]), tref(d, w[0])}, opcode = opcode, elements = elems})

	case .OpVariable:
		if d.in_fn {
			if d.have_blk { append(&d.blk_ops, decode_operation(d, opcode, w)) }
		} else {
			append(&d.globals, Global{type = tref(d, w[0]), init = len(w) > 3 ? Id(w[3]) : ID_NONE})
			append(&d.global_ids, Id(w[1]))
		}

	case .OpFunction:
		d.in_fn = true
		d.fn_id = Id(w[1]); d.fn_sig = tref(d, w[3])
		d.fn_blocks = nil; d.fn_params = nil; d.first_block = true
	case .OpFunctionParameter:
		append(&d.fn_params, Result{id = Id(w[1]), type = tref(d, w[0])})
	case .OpLabel:
		finish_block(d)
		d.have_blk = true; d.blk_id = Id(w[0]); d.blk_ops = nil
		if d.first_block { d.blk_params = d.fn_params[:]; d.first_block = false }
	case .OpFunctionEnd:
		finish_function(d)

	case:
		if d.in_fn && d.have_blk {
			append(&d.blk_ops, decode_operation(d, opcode, w))
		}
	}
}

// -----------------------------------------------------------------------------
// Entry point
// -----------------------------------------------------------------------------

decode :: proc(data: []u8, m: ^Module, errors: ^[dynamic]Error, allocator := context.allocator) -> (byte_count: u32, ok: bool) {
	context.allocator = allocator

	if len(data) < HEADER_WORDS * 4 {
		if errors != nil { append(errors, Error{location = 0, code = .BUFFER_TOO_SHORT}) }
		return 0, false
	}
	d := Decoder{data = data}
	defer delete(d.scratch)

	// endianness from the magic word
	raw := u32(data[0]) | (u32(data[1]) << 8) | (u32(data[2]) << 16) | (u32(data[3]) << 24)
	if raw == MAGIC {
		d.swap = false
	} else if raw == intrinsics.byte_swap(MAGIC) {
		d.swap = true
	} else {
		if errors != nil { append(errors, Error{location = 0, code = .INVALID_OPCODE}) }
		return 0, false
	}

	m.dataflow  = .SSA
	m.version   = rd(&d, 1)
	m.generator = rd(&d, 2)
	m.bound     = rd(&d, 3)

	wi := HEADER_WORDS
	nwords := len(data) / 4
	for wi < nwords {
		head := rd(&d, wi)
		count := int(head >> 16)
		opcode := Opcode(head & 0xFFFF)
		if count == 0 || wi + count > nwords {
			if errors != nil { append(errors, Error{location = u32(wi * 4), code = .BUFFER_TOO_SHORT}) }
			return 0, false
		}
		clear(&d.scratch)
		for j in 0 ..< count - 1 { append(&d.scratch, rd(&d, wi + 1 + j)) }
		lower(&d, opcode, d.scratch[:])
		wi += count
	}

	m.capabilities  = d.caps[:]
	m.extensions    = d.exts[:]
	m.ext_imports   = d.ext_imports[:]
	m.addressing    = d.addressing
	m.memory        = d.memory
	m.entry_points  = d.entry_points[:]
	m.exec_modes    = d.exec_modes[:]
	m.decorations   = d.decorations[:]
	m.debug = Debug{
		source_language = d.src_lang,
		source_version  = d.src_ver,
		source_file     = d.src_file,
		names           = d.names[:],
		strings         = d.strs[:],
	}
	m.types         = d.types[:]
	m.type_ids      = d.type_ids[:]
	m.constants     = d.constants[:]
	m.globals       = d.globals[:]
	m.global_ids    = d.global_ids[:]
	m.functions     = d.functions[:]
	m.function_ids  = d.function_ids[:]

	return u32(nwords * 4), true
}
