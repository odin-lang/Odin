// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "base:runtime"
import "core:strings"

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

	// Pass 1: collect every section header (id, content offset, size, count).
	secs: [dynamic]Section
	secs.allocator = allocator
	for r.off < u32(len(data)) {
		id := Section_Id(rd_byte(&r) or_return)
		size := rd_u32(&r) or_return
		content := r.off
		if content + size > u32(len(data)) {
			return .BAD_SECTION
		}
		sec := Section{id = id, offset = content, size = size}
		switch id {
		case .CUSTOM:
			sub := reader(data, content)
			sec.name = rd_name(&sub) or_return
		case .START:
			// funcidx only, no vector count
		case .TYPE, .IMPORT, .FUNCTION, .TABLE, .MEMORY, .GLOBAL,
		     .EXPORT, .ELEMENT, .CODE, .DATA, .DATA_COUNT:
			sub := reader(data, content)
			sec.count = rd_u32(&sub) or_return
		}
		append(&secs, sec) or_return
		r.off = content + size
	}
	m.sections = secs[:]

	// Pass 2: parse the structured sections.
	func_typeidx: []u32
	codes:        []Code_Body
	for &sec in m.sections {
		s := reader(data, sec.offset)
		#partial switch sec.id {
		case .TYPE:     m.func_types = parse_types           (&s, allocator) or_return
		case .IMPORT:   m.imports    = parse_imports         (&s, allocator) or_return
		case .FUNCTION: func_typeidx = parse_function_section(&s, allocator) or_return
		case .EXPORT:   m.exports    = parse_exports         (&s, allocator) or_return
		case .CODE:     codes        = parse_code            (&s, allocator) or_return
		case .START:    m.start      = i64(rd_u32(&s) or_return)
		}
	}

	parse_custom_sections(m, allocator) or_return

	// Relocations must be parsed before the bodies: the CODE group is threaded
	// into body decode so relocatable index fields become symbolic refs.
	m.relocations = parse_relocations(m^, allocator) or_return

	build_functions(m, func_typeidx, codes, errors, allocator) or_return
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
	BAD_ULEB,        // a ULEB did not terminate within 10 bytes
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
rd_uleb :: proc "contextless" (r: ^Reader) -> (u64, Parse_Error) {
	shift: uint = 0
	value: u64 = 0
	for _ in 0..<10 {
		if r.off >= u32(len(r.data)) { return 0, .TRUNCATED }
		b := r.data[r.off]
		r.off += 1
		value |= u64(b & 0x7F) << shift
		if b & 0x80 == 0 { return value, .NONE }
		shift += 7
	}
	return 0, .BAD_ULEB
}

@(private, require_results)
rd_sleb :: proc "contextless" (r: ^Reader) -> (i64, Parse_Error) {
	shift: uint = 0
	value: i64 = 0
	b: u8 = 0
	for _ in 0..<10 {
		if r.off >= u32(len(r.data)) { return 0, .TRUNCATED }
		b = r.data[r.off]
		r.off += 1
		value |= i64(b & 0x7F) << shift
		shift += 7
		if b & 0x80 == 0 { break }
	}
	if shift < 64 && (b & 0x40) != 0 {
		value |= -(i64(1) << shift)
	}
	return value, .NONE
}

@(private, require_results)
rd_u32 :: proc "contextless" (r: ^Reader) -> (u32, Parse_Error) {
	v, err := rd_uleb(r)
	return u32(v), err
}

@(private, require_results)
rd_name :: proc "contextless" (r: ^Reader) -> (val: string, err: Parse_Error) {
	n := rd_u32(r) or_return
	if r.off + n > u32(len(r.data)) { err = .TRUNCATED; return }
	val = string(r.data[r.off:][:n])
	r.off += n
	return
}

@(private, require_results)
rd_valtype_vec :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Value_Type, err: Reader_Error) {
	n := rd_u32(r) or_return
	out = make([]Value_Type, int(n), allocator) or_return
	for &v in out {
		v = Value_Type(rd_byte(r) or_return)
	}
	return
}

@(private, require_results)
rd_limits :: proc "contextless" (r: ^Reader) -> (min: u64, max: Maybe(u64), err: Parse_Error) {
	flags := rd_byte(r) or_return
	min    = rd_uleb(r) or_return
	if flags & 0x01 != 0 {
		max = rd_uleb(r) or_return
	}
	return
}

// =============================================================================
// Structured section parsers
// =============================================================================

@(private, require_results)
parse_types :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Func_Type, err: Reader_Error) {
	n := rd_u32(r) or_return
	out = make([]Func_Type, int(n), allocator) or_return
	for &ft in out {
		form := rd_byte(r) or_return
		if form != 0x60 { return out, .BAD_TYPE_FORM }
		ft.params  = rd_valtype_vec(r, allocator) or_return
		ft.results = rd_valtype_vec(r, allocator) or_return
	}
	return
}

@(private, require_results)
parse_imports :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Import, err: Reader_Error) {
	n := rd_u32(r) or_return
	out = make([]Import, int(n), allocator) or_return
	for &imp in out {
		imp.module_name = rd_name(r) or_return
		imp.field_name  = rd_name(r) or_return
		imp.kind        = External_Kind(rd_byte(r) or_return)
		switch imp.kind {
		case .FUNC:
			imp.index = rd_u32(r) or_return
		case .TABLE:
			_ = rd_byte(r)   or_return // reftype
			_, _ = rd_limits(r) or_return
		case .MEMORY:
			_, _ = rd_limits(r) or_return
		case .GLOBAL:
			_ = rd_byte(r) or_return // valtype
			_ = rd_byte(r) or_return // mutability
		}
	}
	return
}

@(private, require_results)
parse_function_section :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []u32, err: Reader_Error) {
	n := rd_u32(r) or_return
	out = make([]u32, int(n), allocator) or_return
	for &idx in out {
		idx = rd_u32(r) or_return
	}
	return
}

@(private, require_results)
parse_exports :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Export, err: Reader_Error) {
	n := rd_u32(r) or_return
	out = make([]Export, int(n), allocator) or_return
	for &e in out {
		e.name  = rd_name(r) or_return
		e.kind  = External_Kind(rd_byte(r) or_return)
		e.index = rd_u32(r) or_return
	}
	return
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
	n := rd_u32(r) or_return
	out = make([]Code_Body, int(n), allocator) or_return
	for &cb in out {
		total := rd_u32(r) or_return
		body_end := r.off + total

		nl := rd_u32(r) or_return
		locals := make([]Local_Group, int(nl), allocator) or_return
		for &g in locals {
			g.count = rd_u32(r) or_return
			g.type  = Value_Type(rd_byte(r) or_return)
		}
		cb = Code_Body{
			locals      = locals,
			body_offset = r.off,
			body_size   = body_end > r.off ? body_end - r.off : 0,
		}
		r.off = body_end   // jump past the expr to the next entry
	}
	return
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
			cname: Custom_Section_Name
			defer custom.variant = cname

			for r.off < u32(len(r.data)) {
				id   := rd_byte(&r) or_return
				size := rd_u32(&r)  or_return
				end_off := r.off+size
				defer r.off = end_off

				switch id {
				case 0: // module
					cname.module_name = rd_name(&r) or_return
				case 1: // functions
					count := rd_u32(&r) or_return
					cname.functions = make([]Custom_Section_Name_Function, count, allocator) or_return
					for &func in cname.functions {
						func.id   = rd_u32(&r)  or_return
						func.name = rd_name(&r) or_return
					}
				case 2: // locals
					count := rd_u32(&r) or_return

					cname.locals = make([]Custom_Section_Name_Function_Locals, count, allocator) or_return

					for &local_func in cname.locals {
						local_func.func_idx = rd_u32(&r) or_return
						local_count := rd_u32(&r) or_return
						local_func.locals = make([]Custom_Section_Name_Local, local_count, allocator) or_return
						for &local in local_func.locals {
							local.idx  = rd_u32(&r)  or_return
							local.name = rd_name(&r) or_return
						}
					}
				}
			}

		case "target_features":
			target_features: Custom_Section_Target_Features
			defer custom.variant = target_features

			count := rd_u32(&r) or_return
			target_features.features = make([]Custom_Section_Target_Feature, count, allocator) or_return

			for &feature in target_features.features {
				feature.prefix  = Custom_Section_Target_Feature_Prefix(rd_byte(&r) or_return)
				feature.feature = rd_name(&r) or_return
			}
		}
	}

	return nil
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
	for sec in m.sections {
		if !(sec.id == .CUSTOM && strings.has_prefix(sec.name, "reloc.")) { continue }

		r := reader(m.data[sec.offset:][:sec.size], 0)
		_ = rd_name(&r) or_return                    // step past the custom-section name
		target := Section_Id(rd_u32(&r) or_return)
		count  := rd_u32(&r) or_return

		out := make([]Relocation, int(count), allocator) or_return
		w := 0
		for _ in 0..<count {
			code   := rd_byte(&r) or_return
			offset := rd_u32(&r)  or_return          // field offset within target section
			index  := rd_u32(&r)  or_return          // symbol / target index
			addend: i32 = 0
			if reloc_has_addend(code) {
				addend = i32(rd_sleb(&r) or_return)
			}
			t := reloc_type_from_wire(code) or_continue
			out[w] = Relocation{
				offset   = offset,
				label_id = index,
				addend   = addend,
				type     = t,
				size     = reloc_field_size(t),
			}
			w += 1
		}
		append(&groups, Reloc_Group{target_section = target, relocs = out[:w]}) or_return
	}
	groups_out = groups[:]
	return
}

// Override function names with the "name" custom section's function-name
// subsection (id 1) when present -- these are the authoritative debug names.
@(private)
apply_name_section :: proc(m: ^Module) {
	for sec in m.sections {
		if sec.id != .CUSTOM || sec.name != "name" { continue }

		r := reader(m.data, sec.offset)
		_ = rd_name(&r) or_break   // re-read the section name to reach the subsections
		end := sec.offset + sec.size

		for r.off < end {
			sub_id   := rd_byte(&r) or_break
			sub_size := rd_u32(&r)  or_break
			payload_end := r.off + sub_size
			if sub_id == 1 {   // function names
				count := rd_u32(&r) or_break
				for _ in 0..<count {
					fidx := rd_u32(&r)  or_break
					name := rd_name(&r) or_break
					if int(fidx) < len(m.base.functions) {
						m.base.functions[fidx].name = name
					}
				}
			}
			r.off = payload_end   // skip subsections we do not interpret
		}
		return
	}
}
