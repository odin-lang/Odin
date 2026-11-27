// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "base:runtime"
import "core:strings"
import "core:unicode/utf8"

// =============================================================================
// SECTION: Container decode  (a whole .wasm binary module -> ir Module)
// =============================================================================
//
// `decode_ops` / `decode_expr` (decoder.odin) turn a single WASM `expr` -- one
// instruction stream -- into ir.Operations. That is only the *code* of one
// function; a real `.wasm` file is a container: an 8-byte header (`\0asm`, a
// version) followed by a sequence of length-prefixed sections (type / import /
// function / table / memory / global / export / start / element / code / data,
// plus custom sections). This file is the missing outer layer: `decode` reads
// that whole container and populates the full `wasm.Module`.
//
// How the container maps onto the ir core:
//
//   * TYPE       -> `func_types`.
//   * FUNCTION   -> the typeidx per defined function (folded into signatures).
//   * CODE       -> for *each* defined function, the locals go to
//                   `function_locals` and the body `expr` is decoded (via the
//                   shared `decode_ops`) into a single `ir.Block` of Operations
//                   under an `ir.Function`. This is the plural fix: the old
//                   `decode` produced one function; a module has many.
//   * IMPORT     -> `imports`; imported functions also occupy the low function
//                   indices (with empty bodies) so the funcidx space is intact.
//   * EXPORT     -> `exports`, and names attached to the referenced functions.
//   * START      -> `start`.
//   * reloc.*    -> `relocations`; the CODE group is threaded into body decode
//                   so relocatable index fields decode as symbolic refs.
//
// TABLE / MEMORY / GLOBAL / ELEMENT / DATA are recorded as `sections` and left
// re-readable from `data` (the shared core has no structural slot for them and
// there is, as yet, no container *emitter* -- the codec's symmetric unit is the
// instruction stream, mirroring the original which only parsed the container).
//
// Structural problems surface as an `ir.Error` (BUFFER_TOO_SHORT for a
// truncation, MALFORMED_MODULE otherwise) and `ok = false`; per-instruction
// body errors are pushed by `decode_ops` as usual.

// decode: parse a whole `.wasm` binary module into `m`. Returns the number of
// bytes consumed (the file length on success) and whether it fully succeeded.
decode :: proc(
	data:      []u8,
	m:         ^Module,
	errors:    ^[dynamic]Error,
	allocator := context.allocator,
) -> (byte_count: u32, ok: bool) {
	context.allocator = allocator
	errors_start := u32(len(errors))

	m.base.dataflow = .STACK
	m.version       = WASM_VERSION
	m.start         = -1
	m.data          = data

	if err := parse_container(data, m, errors, allocator); err != nil {
		append(errors, Error{location = 0, code = parse_error_code(err)})
		return 0, false
	}

	byte_count = u32(len(data))
	ok = u32(len(errors)) == errors_start
	return
}

@(private, require_results)
parse_error_code :: proc "contextless" (err: Reader_Error) -> Error_Code {
	#partial switch e in err {
	case Parse_Error:
		if e == .TRUNCATED {
			return .BUFFER_TOO_SHORT
		}
	}
	return .MALFORMED_MODULE   // allocation failure / anything else
}

// =============================================================================
// Container walk
// =============================================================================

parse_container :: proc(data: []u8, m: ^Module, errors: ^[dynamic]Error, allocator: runtime.Allocator) -> Reader_Error {
	r := reader(data, 0)
	if (rd_u32le_block(&r) or_else 0) != WASM_MAGIC {
		return .BAD_MAGIC
	}
	m.version = rd_u32le_block(&r) or_return
	if m.version != WASM_VERSION {
		return .BAD_VERSION
	}

	// Pass 1: collect every section header (id, content offset, size, count).
	secs: [dynamic]Section
	secs.allocator = allocator
	last_rank := 0
	for r.off < u32(len(data)) {
		raw_id := rd_byte(&r) or_return
		if raw_id > u8(max(Section_Id)) {
			return .BAD_SECTION_ID
		}
		id := Section_Id(raw_id)
		size := rd_u32(&r) or_return
		content := r.off
		if size > reader_remaining(&r) {
			return .BAD_SECTION
		}
		if id != .CUSTOM {
			rank := section_rank(id)
			if rank <= last_rank {
				return .BAD_SECTION_ORDER
			}
			last_rank = rank
		}
		sec := Section{id = id, offset = content, size = size}
		switch id {
		case .CUSTOM:
			sub := section_reader(data, sec)
			sec.name = rd_name(&sub) or_return
		case .START:
			// funcidx only, no vector count
		case .TYPE, .IMPORT, .FUNCTION, .TABLE, .MEMORY, .GLOBAL,
		     .EXPORT, .ELEMENT, .CODE, .DATA, .DATA_COUNT:
			sub := section_reader(data, sec)
			sec.count = rd_u32(&sub) or_return
		}
		append(&secs, sec) or_return
		r.off = content + size
	}
	m.sections = secs[:]

	// Pass 2: parse the structured sections.
	func_typeidx: []u32
	codes:        []Code_Body
	data_count:   Maybe(u32)
	data_segments: u32
	for &sec in m.sections {
		s := section_reader(data, sec)
		#partial switch sec.id {
		case .TYPE:       m.func_types  = parse_types           (&s, allocator) or_return
		case .IMPORT:     m.imports     = parse_imports         (&s, allocator) or_return
		case .FUNCTION:   func_typeidx  = parse_function_section(&s, allocator) or_return
		case .EXPORT:     m.exports     = parse_exports         (&s, allocator) or_return
		case .CODE:       codes         = parse_code            (&s, allocator) or_return
		case .START:      m.start       = i64(rd_u32(&s) or_return)
		case .DATA_COUNT: data_count    = rd_u32(&s) or_return
		case .DATA:       data_segments = check_data_section    (&s, allocator) or_return
		case .TABLE:      check_limits_section  (&s, table = true)  or_return
		case .MEMORY:     check_limits_section  (&s, table = false) or_return
		case .GLOBAL:     check_global_section  (&s, allocator) or_return
		case .ELEMENT:    check_element_section (&s, allocator) or_return
		case:             continue
		}
		if s.off != sec.offset + sec.size {
			return .SECTION_SIZE_MISMATCH
		}
	}
	if len(codes) != len(func_typeidx) {
		return .FUNCTION_CODE_MISMATCH
	}
	if n, ok := data_count.?; ok && n != data_segments {
		return .DATA_COUNT_MISMATCH
	}

	parse_custom_sections(m, allocator) or_return

	// Relocations must be parsed before the bodies: the CODE group is threaded
	// into body decode so relocatable index fields become symbolic refs.
	m.relocations = parse_relocations(m^, allocator) or_return

	build_functions(m, func_typeidx, codes, errors, allocator) or_return
	if data_count == nil && functions_use_data_index(m.functions) {
		return .DATA_COUNT_REQUIRED
	}
	apply_name_section(m)
	return nil
}

// =============================================================================
// Byte reader  (container-level, distinct from leb.odin's stream primitives:
// it tracks position and reports structural errors -- TRUNCATED / BAD_*)
// =============================================================================

Parse_Error :: enum u8 {
	NONE = 0,
	TRUNCATED,       // read past the end of the buffer
	BAD_MAGIC,       // not a `\0asm` module
	BAD_TYPE_FORM,   // a functype did not start with 0x60
	BAD_SECTION,     // section contents extend past the buffer
	BAD_ULEB,        // a ULEB was longer or wider than its field allows
	BAD_SLEB,
	BAD_SECTION_ID,
	BAD_SECTION_ORDER,
	SECTION_SIZE_MISMATCH,
	FUNCTION_CODE_MISMATCH,
	BAD_LIMITS,
	BAD_KIND,
	BAD_VALTYPE,
	TOO_MANY_LOCALS,
	BAD_NAME,
	BAD_VERSION,
	BAD_OPCODE,
	BAD_SEGMENT,
	BAD_MUTABILITY,
	DATA_COUNT_MISMATCH,
	DATA_COUNT_REQUIRED,
}

Reader_Error :: union #shared_nil {
	Parse_Error,
	runtime.Allocator_Error,
}

Reader :: struct {
	data: []u8,
	off:  u32,
}

@(private, require_results)
reader :: proc "contextless" (data: []u8, off: u32) -> Reader {
	return Reader{data = data, off = off}
}

@(private, require_results)
rd_byte :: proc "contextless" (r: ^Reader) -> (u8, Parse_Error) {
	if r.off >= u32(len(r.data)) { return 0, .TRUNCATED }
	b := r.data[r.off]
	r.off += 1
	return b, .NONE
}

@(private, require_results)
rd_u32le_block :: proc "contextless" (r: ^Reader) -> (u32, Parse_Error) {
	if r.off + 4 > u32(len(r.data)) { return 0, .TRUNCATED }
	v := u32(r.data[r.off])       |
	     u32(r.data[r.off+1]) << 8 |
	     u32(r.data[r.off+2]) << 16 |
	     u32(r.data[r.off+3]) << 24
	r.off += 4
	return v, .NONE
}

@(private, require_results)
rd_uleb :: proc "contextless" (r: ^Reader, bits: uint = 64) -> (u64, Parse_Error) {
	start := r.off
	v, ok := read_uleb(r.data, &r.off, bits)
	if !ok {
		return 0, leb_error(r, start, bits, .BAD_ULEB)
	}
	return v, .NONE
}

@(private, require_results)
rd_sleb :: proc "contextless" (r: ^Reader, bits: uint = 64) -> (i64, Parse_Error) {
	start := r.off
	v, ok := read_sleb(r.data, &r.off, bits)
	if !ok {
		return 0, leb_error(r, start, bits, .BAD_SLEB)
	}
	return v, .NONE
}

@(private, require_results)
leb_error :: proc "contextless" (r: ^Reader, start: u32, bits: uint, malformed: Parse_Error) -> Parse_Error {
	n := r.off - start
	if r.off >= u32(len(r.data)) && n < u32((bits + 6) / 7) && (n == 0 || r.data[r.off - 1] & 0x80 != 0) {
		return .TRUNCATED
	}
	return malformed
}

@(private, require_results)
rd_u32 :: proc "contextless" (r: ^Reader) -> (u32, Parse_Error) {
	v, err := rd_uleb(r, 32)
	return u32(v), err
}

@(private, require_results)
rd_count :: proc "contextless" (r: ^Reader) -> (n: u32, err: Parse_Error) {
	n = rd_u32(r) or_return
	if n > reader_remaining(r) {
		return 0, .TRUNCATED
	}
	return
}

@(private, require_results)
reader_remaining :: proc "contextless" (r: ^Reader) -> u32 {
	if r.off >= u32(len(r.data)) {
		return 0
	}
	return u32(len(r.data)) - r.off
}

@(private, require_results)
section_reader :: proc "contextless" (data: []u8, sec: Section) -> Reader {
	end := u64(sec.offset) + u64(sec.size)
	if end > u64(len(data)) {
		return Reader{data = data, off = u32(len(data))}
	}
	return Reader{data = data[:end], off = sec.offset}
}

@(private, require_results)
rd_name :: proc "contextless" (r: ^Reader) -> (val: string, err: Parse_Error) {
	n := rd_u32(r) or_return
	if n > reader_remaining(r) { err = .TRUNCATED; return }
	val = string(r.data[r.off:][:n])
	if !utf8.valid_string(val) {
		return "", .BAD_NAME
	}
	r.off += n
	return
}

@(private, require_results)
rd_valtype :: proc "contextless" (r: ^Reader) -> (t: Value_Type, err: Parse_Error) {
	t = Value_Type(rd_byte(r) or_return)
	if !value_type_is_known(t) {
		err = .BAD_VALTYPE
	}
	return
}

@(private, require_results)
rd_valtype_vec :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Value_Type, err: Reader_Error) {
	n := rd_count(r) or_return
	vec := make([]Value_Type, int(n), allocator) or_return
	defer if err != nil {
		delete(vec, allocator)
	}
	for &v in vec {
		v = rd_valtype(r) or_return
	}
	return vec, nil
}

@(private, require_results)
rd_limits :: proc "contextless" (r: ^Reader, table: bool) -> (min: u64, max: Maybe(u64), flags: Limits_Flags, err: Parse_Error) {
	raw := rd_byte(r) or_return
	flags = transmute(Limits_Flags)raw
	if raw > 0x07 || (table && .Shared in flags) {
		err = .BAD_LIMITS
		return
	}
	min = rd_uleb(r) or_return
	if .Has_Max in flags {
		max = rd_uleb(r) or_return
	}
	return
}

@(private, require_results)
check_limits_section :: proc "contextless" (r: ^Reader, table: bool) -> Parse_Error {
	n := rd_count(r) or_return
	for _ in 0..<n {
		if table {
			t := rd_valtype(r) or_return
			if !value_type_is_ref(t) {
				return .BAD_VALTYPE
			}
		}
		_, _, _ = rd_limits(r, table) or_return
	}
	return nil
}

@(private, require_results)
check_global_section :: proc(r: ^Reader, allocator: runtime.Allocator) -> Reader_Error {
	n := rd_count(r) or_return
	for _ in 0..<n {
		_ = rd_valtype(r) or_return
		if (rd_byte(r) or_return) > 1 {
			return .BAD_MUTABILITY
		}
		skip_const_expr(r, allocator) or_return
	}
	return nil
}

@(private, require_results)
check_element_section :: proc(r: ^Reader, allocator: runtime.Allocator) -> Reader_Error {
	n := rd_count(r) or_return
	for _ in 0..<n {
		flags := rd_u32(r) or_return
		if flags > 7 {
			return .BAD_SEGMENT
		}
		exprs := flags & 4 != 0
		if flags & 3 == 2 {
			_ = rd_u32(r) or_return
		}
		if flags & 1 == 0 {
			skip_const_expr(r, allocator) or_return
		}
		if flags & 3 != 0 {
			if exprs {
				t := rd_valtype(r) or_return
				if !value_type_is_ref(t) {
					return .BAD_VALTYPE
				}
			} else if (rd_byte(r) or_return) != 0x00 {
				return .BAD_SEGMENT
			}
		}
		count := rd_count(r) or_return
		for _ in 0..<count {
			if exprs {
				skip_const_expr(r, allocator) or_return
			} else {
				_ = rd_u32(r) or_return
			}
		}
	}
	return nil
}

@(private, require_results)
check_data_section :: proc(r: ^Reader, allocator: runtime.Allocator) -> (n: u32, err: Reader_Error) {
	n = rd_count(r) or_return
	for _ in 0..<n {
		switch rd_u32(r) or_return {
		case 0:
			skip_const_expr(r, allocator) or_return
		case 1:
		case 2:
			_ = rd_u32(r) or_return
			skip_const_expr(r, allocator) or_return
		case:
			return n, .BAD_SEGMENT
		}
		size := rd_count(r) or_return
		r.off += size
	}
	return
}

@(private, require_results)
skip_const_expr :: proc(r: ^Reader, allocator: runtime.Allocator) -> Reader_Error {
	for {
		if r.off >= u32(len(r.data)) {
			return .TRUNCATED
		}
		op, next, ok := decode_one(r.data, nil, r.off, allocator)
		if !ok {
			return .BAD_OPCODE
		}
		delete(op.operands, allocator)
		r.off = next
		if Opcode(op.opcode) == .END {
			return nil
		}
	}
}

@(private)
Limits_Flag :: enum u8 {
	Has_Max    = 0,
	Shared     = 1,
	Address_64 = 2,
}

@(private)
Limits_Flags :: bit_set[Limits_Flag; u8]

// =============================================================================
// Structured section parsers
// =============================================================================

@(private, require_results)
section_rank :: proc "contextless" (id: Section_Id) -> int {
	switch id {
	case .CUSTOM:     return 0
	case .TYPE:       return 1
	case .IMPORT:     return 2
	case .FUNCTION:   return 3
	case .TABLE:      return 4
	case .MEMORY:     return 5
	case .GLOBAL:     return 6
	case .EXPORT:     return 7
	case .START:      return 8
	case .ELEMENT:    return 9
	case .DATA_COUNT: return 10
	case .CODE:       return 11
	case .DATA:       return 12
	}
	return 0
}

@(private, require_results)
parse_types :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Func_Type, err: Reader_Error) {
	n := rd_count(r) or_return
	types := make([]Func_Type, int(n), allocator) or_return
	defer if err != nil {
		for ft in types {
			delete(ft.params, allocator)
			delete(ft.results, allocator)
		}
		delete(types, allocator)
	}
	for &ft in types {
		form := rd_byte(r) or_return
		if form != 0x60 { return nil, .BAD_TYPE_FORM }
		ft.params  = rd_valtype_vec(r, allocator) or_return
		ft.results = rd_valtype_vec(r, allocator) or_return
	}
	return types, nil
}

@(private, require_results)
parse_imports :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Import, err: Reader_Error) {
	n := rd_count(r) or_return
	imports := make([]Import, int(n), allocator) or_return
	defer if err != nil {
		delete(imports, allocator)
	}
	for &imp in imports {
		imp.module_name = rd_name(r) or_return
		imp.field_name  = rd_name(r) or_return
		imp.kind        = External_Kind(rd_byte(r) or_return)
		switch imp.kind {
		case .FUNC:
			imp.index = rd_u32(r) or_return
		case .TABLE:
			rt := rd_valtype(r) or_return // reftype
			if !value_type_is_ref(rt) {
				return nil, .BAD_VALTYPE
			}
			_, _, _ = rd_limits(r, true) or_return
		case .MEMORY:
			_, _, _ = rd_limits(r, false) or_return
		case .GLOBAL:
			_ = rd_valtype(r) or_return // valtype
			if (rd_byte(r) or_return) > 1 { // mutability
				return nil, .BAD_MUTABILITY
			}
		case:
			return nil, .BAD_KIND
		}
	}
	return imports, nil
}

@(private, require_results)
parse_function_section :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []u32, err: Reader_Error) {
	n := rd_count(r) or_return
	typeidx := make([]u32, int(n), allocator) or_return
	defer if err != nil {
		delete(typeidx, allocator)
	}
	for &idx in typeidx {
		idx = rd_u32(r) or_return
	}
	return typeidx, nil
}

@(private, require_results)
parse_exports :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Export, err: Reader_Error) {
	n := rd_count(r) or_return
	exports := make([]Export, int(n), allocator) or_return
	defer if err != nil {
		delete(exports, allocator)
	}
	for &e in exports {
		e.name  = rd_name(r) or_return
		kind   := rd_byte(r) or_return
		if kind > u8(max(External_Kind)) {
			return nil, .BAD_KIND
		}
		e.kind  = External_Kind(kind)
		e.index = rd_u32(r) or_return
	}
	return exports, nil
}

// One code entry's locals (still compressed as `count x type` groups) and the
// file span of its body `expr`.
@(private)
Code_Body :: struct {
	locals:      []Local_Group,
	body_offset: u32,   // file offset of the instruction stream
	body_size:   u32,   // instruction-stream length in bytes
}

@(private)
Local_Group :: struct {
	count: u32,
	type:  Value_Type,
}

@(private, require_results)
parse_code :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Code_Body, err: Reader_Error) {
	n := rd_count(r) or_return
	bodies := make([]Code_Body, int(n), allocator) or_return
	defer if err != nil {
		for cb in bodies {
			delete(cb.locals, allocator)
		}
		delete(bodies, allocator)
	}
	for &cb in bodies {
		total := rd_u32(r) or_return
		if total > reader_remaining(r) {
			return nil, .TRUNCATED
		}
		body_end := r.off + total
		body := Reader{data = r.data[:body_end], off = r.off}

		nl := rd_count(&body) or_return
		cb.locals = make([]Local_Group, int(nl), allocator) or_return
		local_total: u64
		for &g in cb.locals {
			g.count = rd_u32(&body) or_return
			g.type  = rd_valtype(&body) or_return
			local_total += u64(g.count)
		}
		if local_total > MAX_FUNCTION_LOCALS {
			return nil, .TOO_MANY_LOCALS
		}
		cb.body_offset = body.off
		cb.body_size   = body_end - body.off
		r.off = body_end   // jump past the expr to the next entry
	}
	return bodies, nil
}


@(private, require_results)
parse_custom_sections :: proc(m: ^Module, allocator: runtime.Allocator) -> Reader_Error {
	custom_count := 0
	for &sec in m.sections {
		if sec.id == .CUSTOM {
			custom_count += 1
		}
	}
	m.customs = make([]Custom_Section, custom_count, allocator) or_return
	custom_index := 0
	for &sec in m.sections {
		if sec.id != .CUSTOM {
			continue
		}

		custom := &m.customs[custom_index]
		custom_index += 1

		custom.section = sec

		custom.payload = m.data[sec.offset:][:sec.size]

		r := reader(custom.payload, 0)
		sec_name := rd_name(&r) or_continue
		assert(sec_name == sec.name)

		if strings.has_prefix(sec.name, ".debug_") {
			// DWARF debug stuff
		} else if strings.has_prefix(sec.name, "reloc.") {
			// other relocation stuff
		}

		custom_block: switch sec.name {
		case "linking":
			// not yet handled
		case "producers":
			// not yet handled
		case "dynlink.0":
			// not yet handled
		case "external_debug_info", "sourceMappingURL":
			// not yet handled, but debugging related
		case "metadata.code.branch_hint":
			// not yet handled
		case "name":
			cname, err := parse_name_section(&r, allocator)
			if err == nil {
				custom.variant = cname
			} else if alloc_err, is_alloc := err.(runtime.Allocator_Error); is_alloc {
				return alloc_err
			}

		case "target_features":
			target_features, err := parse_target_features(&r, allocator)
			if err == nil {
				custom.variant = target_features
			} else if alloc_err, is_alloc := err.(runtime.Allocator_Error); is_alloc {
				return alloc_err
			}
		}
	}

	return nil
}

@(private, require_results)
parse_name_section :: proc(r: ^Reader, allocator: runtime.Allocator) -> (cname: Custom_Section_Name, err: Reader_Error) {
	names: Custom_Section_Name
	defer if err != nil {
		custom_section_name_destroy(names, allocator)
	}
	for r.off < u32(len(r.data)) {
		id   := rd_byte(r) or_return
		size := rd_u32(r)  or_return
		if size > reader_remaining(r) {
			return {}, .TRUNCATED
		}
		sub := Reader{data = r.data[:r.off + size], off = r.off}
		r.off += size

		switch id {
		case 0: // module
			names.module_name = rd_name(&sub) or_return
		case 1: // functions
			count := rd_count(&sub) or_return
			functions := make([]Custom_Section_Name_Function, count, allocator) or_return
			delete(names.functions, allocator)
			names.functions = functions
			for &func in names.functions {
				func.id   = rd_u32(&sub)  or_return
				func.name = rd_name(&sub) or_return
			}
		case 2: // locals
			count := rd_count(&sub) or_return

			locals := make([]Custom_Section_Name_Function_Locals, count, allocator) or_return
			for l in names.locals {
				delete(l.locals, allocator)
			}
			delete(names.locals, allocator)
			names.locals = locals

			for &local_func in names.locals {
				local_func.func_idx = rd_u32(&sub) or_return
				local_count := rd_count(&sub) or_return
				local_func.locals = make([]Custom_Section_Name_Local, local_count, allocator) or_return
				for &local in local_func.locals {
					local.idx  = rd_u32(&sub)  or_return
					local.name = rd_name(&sub) or_return
				}
			}
		}
	}
	return names, nil
}

@(private, require_results)
parse_target_features :: proc(r: ^Reader, allocator: runtime.Allocator) -> (target_features: Custom_Section_Target_Features, err: Reader_Error) {
	count := rd_count(r) or_return
	features := make([]Custom_Section_Target_Feature, count, allocator) or_return
	defer if err != nil {
		delete(features, allocator)
	}

	for &feature in features {
		feature.prefix  = Custom_Section_Target_Feature_Prefix(rd_byte(r) or_return)
		feature.feature = rd_name(r) or_return
	}
	return {features = features}, nil
}

// =============================================================================
// Function index space  (imports ++ defined) with eagerly-decoded bodies
// =============================================================================

@(private, require_results)
build_functions :: proc(
	m:            ^Module,
	func_typeidx: []u32,
	codes:        []Code_Body,
	errors:       ^[dynamic]Error,
	allocator:    runtime.Allocator,
) -> Reader_Error {
	num_imports := 0
	for imp in m.imports {
		if imp.kind == .FUNC { num_imports += 1 }
	}
	total := num_imports + len(func_typeidx)
	if total == 0 { return nil }

	funcs  := make([]Function,      total, allocator) or_return
	locals := make([][]Value_Type,  total, allocator) or_return

	// CODE-section file offset, to rebase its relocations to body-relative.
	code_off: u32 = 0
	for s in m.sections {
		if s.id == .CODE { code_off = s.offset; break }
	}
	code_relocs := relocations_for_section(m.relocations, .CODE)

	// Imported functions: low indices, no body.
	idx := 0
	for imp in m.imports {
		(imp.kind == .FUNC) or_continue
		funcs[idx] = Function{
			name      = imp.field_name,
			signature = Type_Ref(imp.index),   // typeidx into func_types
		}
		idx += 1
	}

	// Defined functions: decode each body into a single ir.Block.
	for tidx, i in func_typeidx {
		fi := num_imports + i
		f := Function{signature = Type_Ref(tidx)}

		if i < len(codes) {
			cb := codes[i]

			// Expand the compressed local groups to a flat value-type list.
			nlocals := 0
			for g in cb.locals { nlocals += int(g.count) }
			flat := make([]Value_Type, nlocals, allocator) or_return
			w := 0
			for g in cb.locals {
				for _ in 0..<int(g.count) {
					flat[w] = g.type; w += 1
				}
			}
			locals[fi] = flat

			// Decode the body, threading the (rebased) CODE relocations.
			body := m.data[cb.body_offset:][:cb.body_size]
			body_rel := cb.body_offset - code_off
			body_relocs := relocs_for_body(code_relocs, body_rel, cb.body_size, allocator)

			ops, _, _ := decode_ops(body, body_relocs, errors, allocator)
			if !body_well_nested(ops, allocator) {
				append(errors, Error{location = cb.body_offset, code = .MALFORMED_MODULE})
			}
			blocks := make([]Block, 1, allocator) or_return
			blocks[0] = Block{id = ID_NONE, ops = ops}
			f.blocks = blocks
			f.id = Id(fi)
		}
		funcs[fi] = f
	}

	// Names from the export section (kept if the name section overrides later).
	for e in m.exports {
		if e.kind == .FUNC && int(e.index) < total && funcs[e.index].name == "" {
			funcs[e.index].name = e.name
		}
	}

	m.base.functions   = funcs
	m.function_locals  = locals
	return nil
}

@(private, require_results)
body_well_nested :: proc(ops: []Operation, allocator: runtime.Allocator) -> bool {
	open_ifs := make([dynamic]bool, allocator)
	defer delete(open_ifs)
	for op, i in ops {
		#partial switch Opcode(op.opcode) {
		case .BLOCK, .LOOP:
			if _, err := append(&open_ifs, false); err != nil {
				return false
			}
		case .IF:
			if _, err := append(&open_ifs, true); err != nil {
				return false
			}
		case .ELSE:
			if len(open_ifs) == 0 || !open_ifs[len(open_ifs) - 1] {
				return false
			}
			open_ifs[len(open_ifs) - 1] = false
		case .END:
			if len(open_ifs) == 0 {
				return i == len(ops) - 1
			}
			pop(&open_ifs)
		}
	}
	return false
}

@(private, require_results)
functions_use_data_index :: proc "contextless" (functions: []Function) -> bool {
	for f in functions {
		for blk in f.blocks {
			for op in blk.ops {
				#partial switch Opcode(op.opcode) {
				case .MEMORY_INIT, .DATA_DROP:
					return true
				}
			}
		}
	}
	return false
}

// Filter a section's relocations down to one body and rebase their offsets to
// be relative to the body start (so `decode_ops` -- whose pc starts at 0 --
// matches them). Returns nil when there are none (the common, linked-module
// case), so no allocation happens.
@(private, require_results)
relocs_for_body :: proc(all: []Relocation, body_off_in_sec, size: u32, allocator: runtime.Allocator) -> []Relocation {
	if len(all) == 0 { return nil }
	lo := body_off_in_sec
	hi := body_off_in_sec + size
	out: [dynamic]Relocation
	out.allocator = allocator
	for rr in all {
		if rr.offset >= lo && rr.offset < hi {
			r2 := rr
			r2.offset = rr.offset - lo
			append(&out, r2)
		}
	}
	return out[:]
}

// =============================================================================
// Relocations  (object-file `reloc.*` custom sections)
// =============================================================================

@(private, require_results)
parse_relocations :: proc(m: Module, allocator: runtime.Allocator) -> (groups_out: []Reloc_Group, err: Reader_Error) {
	groups: [dynamic]Reloc_Group
	groups.allocator = allocator
	out: []Relocation
	defer if err != nil {
		delete(out, allocator)
		for g in groups {
			delete(g.relocs, allocator)
		}
		delete(groups)
	}
	for sec in m.sections {
		if !(sec.id == .CUSTOM && strings.has_prefix(sec.name, "reloc.")) { continue }

		r := reader(m.data[sec.offset:][:sec.size], 0)
		_ = rd_name(&r) or_return                    // step past the custom-section name
		target_index := rd_u32(&r) or_return
		if target_index >= u32(len(m.sections)) {
			return nil, .BAD_SECTION
		}
		target := m.sections[target_index].id
		count  := rd_count(&r) or_return

		out = make([]Relocation, int(count), allocator) or_return
		w := 0
		for _ in 0..<count {
			code   := rd_byte(&r) or_return
			offset := rd_u32(&r)  or_return          // field offset within target section
			index  := rd_u32(&r)  or_return          // symbol / target index
			addend: i64 = 0
			if reloc_has_addend(code) {
				addend = rd_sleb(&r) or_return
			}
			t := reloc_type_from_wire(code) or_continue
			if addend < i64(min(i32)) || addend > i64(max(i32)) {
				return nil, .BAD_SLEB
			}
			out[w] = Relocation{
				offset   = offset,
				label_id = index,
				addend   = i32(addend),
				type     = t,
				size     = reloc_field_size(t),
			}
			w += 1
		}
		append(&groups, Reloc_Group{target_section = target, relocs = out[:w]}) or_return
		out = nil
	}
	return groups[:], nil
}

// Override function names with the "name" custom section's function-name
// subsection (id 1) when present -- these are the authoritative debug names.
@(private)
apply_name_section :: proc(m: ^Module) {
	for sec in m.sections {
		if sec.id != .CUSTOM || sec.name != "name" { continue }

		r := section_reader(m.data, sec)
		_ = rd_name(&r) or_break   // re-read the section name to reach the subsections
		end := sec.offset + sec.size

		for r.off < end {
			sub_id   := rd_byte(&r) or_break
			sub_size := rd_u32(&r)  or_break
			if sub_size > reader_remaining(&r) {
				break
			}
			payload_end := r.off + sub_size
			if sub_id == 1 {   // function names
				count := rd_u32(&r) or_break
				for _ in 0..<count {
					fidx := rd_u32(&r)  or_break
					name := rd_name(&r) or_break
					if fidx < u32(len(m.base.functions)) {
						m.base.functions[fidx].name = name
					}
				}
			}
			r.off = payload_end   // skip subsections we do not interpret
		}
		return
	}
}
