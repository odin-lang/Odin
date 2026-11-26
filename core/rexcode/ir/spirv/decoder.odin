// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

import "base:intrinsics"
import "base:runtime"
import "core:slice"
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
	defs:         [dynamic]Def,   // type/constant/global definition order
	opaque_info:  [dynamic]Opaque_Info,   // parallel to types; set for OPAQUE

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
Lower_Error :: union #shared_nil {
	Error_Code,
	runtime.Allocator_Error,
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
rd_string :: proc(d: ^Decoder, w: []u32) -> (s: string, nwords: int, err: runtime.Allocator_Error) {
	buf: [dynamic]u8
	defer delete(buf)
	outer: for word in w {
		for b in 0 ..< 4 {
			c := u8(word >> uint(b * 8))
			if c == 0 { break outer }
			append(&buf, c) or_return
		}
	}
	s = strings.clone(string(buf[:])) or_return
	return s, (len(buf) + 4) / 4, nil
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
required_words :: proc "contextless" (opcode: Opcode) -> int {
	run: Spec_Run
	if int(opcode) < len(INSTRUCTION_INDEX) { run = INSTRUCTION_INDEX[u16(opcode)] }
	n := 0
	for si in 0 ..< int(run.count) {
		if INSTRUCTION_SPECS[int(run.start) + si].quant == .ONE {
			n += 1
		}
	}
	return n
}

@(private="file")
tref :: proc(d: ^Decoder, id: u32) -> Type_Ref {
	if r, ok := d.id_to_type[Id(id)]; ok { return r }
	return TYPE_NONE
}

@(private="file")
add_type :: proc(d: ^Decoder, id: Id, t: Type) -> (err: runtime.Allocator_Error) {
	defer if err != nil {
		delete(t.fields)
	}
	map_insert(&d.id_to_type, id, Type_Ref(len(d.types))) or_return
	append(&d.defs, Def{.TYPE, u32(len(d.types))}) or_return
	append(&d.type_ids, id) or_return
	append(&d.opaque_info, Opaque_Info{}) or_return   // stay parallel; filled for OPAQUE
	append(&d.types, t) or_return
	return nil
}

// A type-defining instruction the codec doesn't model: store it as OPAQUE plus
// its verbatim operand words (after the result <id>) so it re-emits exactly.
@(private="file")
add_opaque :: proc(d: ^Decoder, opcode: Opcode, w: []u32) -> runtime.Allocator_Error {
	add_type(d, Id(w[0]), Type{kind = .OPAQUE}) or_return
	words := slice.clone(w[1:]) or_return
	d.opaque_info[len(d.opaque_info) - 1] = Opaque_Info{opcode = opcode, words = words}
	return nil
}

@(private="file")
add_const :: proc(d: ^Decoder, c: Constant) -> (err: runtime.Allocator_Error) {
	defer if err != nil {
		delete(c.elements)
	}
	append(&d.defs, Def{.CONSTANT, u32(len(d.constants))}) or_return
	append(&d.constants, c) or_return
	return nil
}

// Decode a function-body operation generically, by its operand layout: the
// result-type/result-id prefix from the leading specs, then one operand per
// remaining spec (Id specs -> entity/type refs, the rest -> integer literals).
@(private="file")
decode_operation :: proc(d: ^Decoder, opcode: Opcode, w: []u32) -> (op: Operation, err: runtime.Allocator_Error) {
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

	ops := make([]Operand, len(w) - wi) or_return
	k := 0
	for ; si < int(run.count) && wi < len(w); si += 1 {
		spec := INSTRUCTION_SPECS[int(run.start) + si]
		if spec.quant == .VARIADIC {
			for wi < len(w) {
				ops[k] = is_id_spec(spec.kind) ? id_operand(d, w[wi]) : op_int(i64(w[wi]))
				k += 1
				wi += 1
			}
		} else {
			ops[k] = is_id_spec(spec.kind) ? id_operand(d, w[wi]) : op_int(i64(w[wi]))
			k += 1
			wi += 1
		}
	}
	// Trailing words beyond the fixed layout: the parameter operands an enum
	// value/bit pulls in (MemoryAccess Aligned's alignment, etc.). Captured as
	// literals -- enough to re-encode byte-exact (semantic typing is a refinement).
	for wi < len(w) {
		ops[k] = op_int(i64(w[wi]))
		k += 1
		wi += 1
	}
	op.operands = ops
	return
}

@(private="file")
finish_block :: proc(d: ^Decoder) -> runtime.Allocator_Error {
	if d.have_blk {
		append(&d.fn_blocks, Block{id = d.blk_id, ops = d.blk_ops[:], params = d.blk_params}) or_return
		d.blk_ops = nil
		d.blk_params = nil
		d.have_blk = false
	}
	return nil
}

@(private="file")
finish_function :: proc(d: ^Decoder) -> runtime.Allocator_Error {
	finish_block(d) or_return
	append(&d.functions, Function{signature = d.fn_sig, blocks = d.fn_blocks[:]}) or_return
	d.fn_blocks = nil
	delete(d.fn_params)
	d.fn_params = nil
	d.in_fn = false
	append(&d.function_ids, d.fn_id) or_return
	return nil
}

@(private="file")
lower :: proc(d: ^Decoder, opcode: Opcode, w: []u32) -> Lower_Error {
	if len(w) < required_words(opcode) {
		return Error_Code.MALFORMED_MODULE
	}
	#partial switch opcode {
	case .OpCapability:
		append(&d.caps, Capability(w[0])) or_return
	case .OpExtension:
		append(&d.exts, "") or_return
		d.exts[len(d.exts) - 1], _ = rd_string(d, w) or_return
	case .OpExtInstImport:
		append(&d.ext_imports, Ext_Import{Id(w[0]), ""}) or_return
		d.ext_imports[len(d.ext_imports) - 1].name, _ = rd_string(d, w[1:]) or_return
	case .OpMemoryModel:
		d.addressing = Addressing_Model(w[0]); d.memory = Memory_Model(w[1])
	case .OpEntryPoint:
		append(&d.entry_points, Entry_Point{Execution_Model(w[0]), Id(w[1]), "", nil}) or_return
		ep := &d.entry_points[len(d.entry_points) - 1]
		nw: int
		ep.name, nw = rd_string(d, w[2:]) or_return
		first := min(2 + nw, len(w))
		ep.interface = make([]Id, len(w) - first) or_return
		for j in first ..< len(w) { ep.interface[j - first] = Id(w[j]) }
	case .OpExecutionMode, .OpExecutionModeId:
		append(&d.exec_modes, Exec_Mode{Id(w[0]), Execution_Mode(w[1]), nil, opcode == .OpExecutionModeId}) or_return
		d.exec_modes[len(d.exec_modes) - 1].operands = slice.clone(w[2:]) or_return

	case .OpString:
		append(&d.strs, Str{Id(w[0]), ""}) or_return
		d.strs[len(d.strs) - 1].text, _ = rd_string(d, w[1:]) or_return
	case .OpSource:
		d.src_lang = w[0]; d.src_ver = len(w) > 1 ? w[1] : 0
		d.src_file = len(w) > 2 ? Id(w[2]) : ID_NONE
	case .OpName:
		append(&d.names, Name{Id(w[0]), MEMBER_NONE, ""}) or_return
		d.names[len(d.names) - 1].text, _ = rd_string(d, w[1:]) or_return
	case .OpMemberName:
		append(&d.names, Name{Id(w[0]), w[1], ""}) or_return
		d.names[len(d.names) - 1].text, _ = rd_string(d, w[2:]) or_return
	case .OpDecorate:
		append(&d.decorations, Decoration_Inst{Id(w[0]), Decoration(w[1]), MEMBER_NONE, nil}) or_return
		d.decorations[len(d.decorations) - 1].operands = slice.clone(w[2:]) or_return
	case .OpMemberDecorate:
		append(&d.decorations, Decoration_Inst{Id(w[0]), Decoration(w[2]), w[1], nil}) or_return
		d.decorations[len(d.decorations) - 1].operands = slice.clone(w[3:]) or_return

	case .OpTypeVoid:    add_type(d, Id(w[0]), Type{kind = .VOID}) or_return
	case .OpTypeBool:    add_type(d, Id(w[0]), Type{kind = .BOOL}) or_return
	case .OpTypeArray:   add_type(d, Id(w[0]), Type{kind = .ARRAY, elem = tref(d, w[1]), len_ref = Id(w[2])}) or_return
	case .OpTypeInt:     add_type(d, Id(w[0]), Type{kind = .INT,   bits = u16(w[1]), aux = u16(w[2] & 1)}) or_return
	case .OpTypeFloat:   add_type(d, Id(w[0]), Type{kind = .FLOAT, bits = u16(w[1])}) or_return
	case .OpTypeVector:  add_type(d, Id(w[0]), Type{kind = .VECTOR, elem = tref(d, w[1]), count = w[2]}) or_return
	case .OpTypeRuntimeArray: add_type(d, Id(w[0]), Type{kind = .ARRAY, elem = tref(d, w[1]), len_ref = ID_NONE}) or_return
	case .OpTypePointer: add_type(d, Id(w[0]), Type{kind = .POINTER, aux = u16(w[1]), elem = tref(d, w[2])}) or_return
	case .OpTypeStruct:
		fields := make([]Type_Ref, len(w) - 1) or_return
		for j in 1 ..< len(w) { fields[j - 1] = tref(d, w[j]) }
		add_type(d, Id(w[0]), Type{kind = .STRUCT, fields = fields}) or_return
	case .OpTypeFunction:
		nparam := len(w) - 2
		fields := make([]Type_Ref, nparam + 1) or_return
		for j in 0 ..< nparam { fields[j] = tref(d, w[2 + j]) }
		fields[nparam] = tref(d, w[1])   // return type last: fields = params ++ [result]
		add_type(d, Id(w[0]), Type{kind = .FUNCTION, fields = fields, count = u32(nparam)}) or_return
	case .OpTypeMatrix, .OpTypeImage, .OpTypeSampler, .OpTypeSampledImage,
	     .OpTypeOpaque, .OpTypeEvent, .OpTypeDeviceEvent, .OpTypeReserveId,
	     .OpTypeQueue, .OpTypePipe:
		add_opaque(d, opcode, w) or_return   // captured verbatim -> OPAQUE

	case .OpConstant:
		c := Constant{result = {Id(w[1]), tref(d, w[0])}, opcode = opcode, value = u64(w[2])}
		if len(w) > 3 { c.value |= u64(w[3]) << 32 }
		add_const(d, c) or_return
	case .OpConstantTrue, .OpConstantFalse, .OpConstantNull:
		add_const(d, Constant{result = {Id(w[1]), tref(d, w[0])}, opcode = opcode}) or_return
	case .OpConstantComposite:
		elems := make([]Id, len(w) - 2) or_return
		for j in 2 ..< len(w) { elems[j - 2] = Id(w[j]) }
		add_const(d, Constant{result = {Id(w[1]), tref(d, w[0])}, opcode = opcode, elements = elems}) or_return

	case .OpVariable:
		if d.in_fn {
			if d.have_blk {
				append(&d.blk_ops, Operation{}) or_return
				d.blk_ops[len(d.blk_ops) - 1] = decode_operation(d, opcode, w) or_return
			}
		} else {
			append(&d.defs, Def{.GLOBAL, u32(len(d.globals))}) or_return
			append(&d.globals, Global{type = tref(d, w[0]), init = len(w) > 3 ? Id(w[3]) : ID_NONE}) or_return
			append(&d.global_ids, Id(w[1])) or_return
		}

	case .OpFunction:
		if d.in_fn {
			return Error_Code.MALFORMED_MODULE
		}
		d.in_fn = true
		d.fn_id = Id(w[1]); d.fn_sig = tref(d, w[3])
		d.fn_blocks = nil; d.fn_params = nil; d.first_block = true
	case .OpFunctionParameter:
		if !d.in_fn || !d.first_block {
			return Error_Code.MALFORMED_MODULE
		}
		append(&d.fn_params, Result{id = Id(w[1]), type = tref(d, w[0])}) or_return
	case .OpLabel:
		if !d.in_fn {
			return Error_Code.MALFORMED_MODULE
		}
		finish_block(d) or_return
		d.have_blk = true; d.blk_id = Id(w[0]); d.blk_ops = nil
		if d.first_block { d.blk_params = d.fn_params[:]; d.fn_params = nil; d.first_block = false }
	case .OpFunctionEnd:
		if !d.in_fn {
			return Error_Code.MALFORMED_MODULE
		}
		finish_function(d) or_return

	case:
		if d.in_fn && d.have_blk {
			append(&d.blk_ops, Operation{}) or_return
			d.blk_ops[len(d.blk_ops) - 1] = decode_operation(d, opcode, w) or_return
		}
	}
	return nil
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
	m.defs          = d.defs[:]
	m.opaque_info   = d.opaque_info[:]

	return u32(nwords * 4), true
}
