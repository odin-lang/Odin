package rexcode_wasm_module

import "base:runtime"
import "core:strings"
import "core:rexcode/wasm"

Parse_Error :: enum {
	NONE = 0,
	TRUNCATED,
	BAD_MAGIC,
	BAD_TYPE_FORM, // a functype did not start with 0x60
	BAD_SECTION,   // section contents extend past the section size
	BAD_ULEB,      // ULEB number didn't stop after 10 bytes
}

Reader_Error :: union #shared_nil {
	Parse_Error,
	runtime.Allocator_Error,
}

Reader :: struct {
	data: []u8,
	off:  u32,
}

@(require_results)
reader :: proc(data: []u8, off: u32) -> Reader {
	return Reader{data = data, off = off}
}

@(require_results)
rd_byte :: proc(r: ^Reader) -> (u8, Parse_Error) {
	if r.off >= u32(len(r.data)) {
		return 0, .TRUNCATED
	}
	b := r.data[r.off]
	r.off += 1
	return b, .NONE
}

@(require_results)
rd_u32le_block :: proc(r: ^Reader) -> (u32, Parse_Error) {
	if r.off + 4 > u32(len(r.data)) {
		return 0, .TRUNCATED
	}
	v := u32(r.data[r.off]) |
	     u32(r.data[r.off+1])<<8 |
	     u32(r.data[r.off+2])<<16 |
	     u32(r.data[r.off+3])<<24
	r.off += 4
	return v, .NONE
}

@(require_results)
rd_uleb :: proc(r: ^Reader) -> (u64, Parse_Error) {
	shift: uint = 0
	value: u64 = 0
	for _ in 0..<10 {
		if r.off >= u32(len(r.data)) {
			return 0, .TRUNCATED
		}
		b := r.data[r.off]
		r.off += 1
		value |= u64(b & 0x7F) << shift
		if b & 0x80 == 0 {
			return value, .NONE
		}
		shift += 7
	}
	return 0, .BAD_ULEB
}

// Signed-LEB128 reader.
@(require_results)
rd_sleb :: proc(r: ^Reader) -> (i64, Parse_Error) {
	shift: uint = 0
	value: i64 = 0
	b: u8 = 0
	for _ in 0..<10 {
		if r.off >= u32(len(r.data)) {
			return 0, .TRUNCATED
		}
		b = r.data[r.off]
		r.off += 1
		value |= i64(b & 0x7F) << shift
		shift += 7
		if b & 0x80 == 0 {
			break
		}
	}
	if shift < 64 && (b & 0x40) != 0 {
		value |= -(i64(1) << shift)
	}
	return value, .NONE
}


@(require_results)
rd_u32 :: proc(r: ^Reader) -> (u32, Parse_Error) {
	v, err := rd_uleb(r)
	return u32(v), err
}

@(require_results)
rd_name :: proc(r: ^Reader) -> (val: string, err: Parse_Error) {
	n := rd_u32(r) or_return
	if r.off + n > u32(len(r.data)) {
		err = .TRUNCATED
		return
	}
	val = string(r.data[r.off:][:n])
	r.off += n
	return
}

@(require_results)
rd_valtype_vec :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []wasm.Value_Type, err: Reader_Error) {
	n := rd_u32(r) or_return

	// now actually parse it
	out = make([]wasm.Value_Type, int(n), allocator) or_return
	for &v in out {
		v = wasm.Value_Type(rd_byte(r) or_return)
	}
	return
}

@(require_results)
rd_limits :: proc(r: ^Reader) -> (min: u64, max: Maybe(u64), err: Parse_Error) {
	flags := rd_byte(r) or_return
	min    = rd_uleb(r) or_return
	if flags & 0x01 != 0 {
		max = rd_uleb(r) or_return
	}
	return
}


@(require_results)
parse :: proc(data: []u8, allocator := context.allocator) -> (m: Module, err: Reader_Error) {
	context.allocator = allocator

	m.data  = data
	m.start = -1
	m.allocator = allocator

	r := reader(data, 0)
	if (rd_u32le_block(&r) or_else 0) != WASM_MAGIC {
		return m, .BAD_MAGIC
	}
	m.version = rd_u32le_block(&r) or_return

	secs: [dynamic]Section
	for r.off < u32(len(data)) {
		id := Section_Id(rd_byte(&r) or_return)
		size := rd_u32(&r) or_return
		content := r.off
		if content + size > u32(len(data)) {
			return m, .BAD_SECTION
		}

		sec := Section{id = id, offset = content, size = size}
		switch id {
		case .CUSTOM:
			sub := reader(data, content)
			sec.name = rd_name(&sub) or_return
		case .START:
			// funcidx, no vector count
		case .TYPE, .IMPORT, .FUNCTION, .TABLE, .MEMORY, .GLOBAL,
		     .EXPORT, .ELEMENT, .CODE, .DATA, .DATA_COUNT:
			sub := reader(data, content)
			sec.count = rd_u32(&sub) or_return
		}
		append(&secs, sec) or_return
		r.off = content + size
	}
	m.sections = secs[:]


	func_typeidx: []u32
	codes:        []Code_Body

	for &sec in m.sections {
		s := reader(data, sec.offset)
		#partial switch sec.id {
		case .TYPE:     m.types      = parse_types           (&s, allocator) or_return
		case .IMPORT:   m.imports    = parse_imports         (&s, allocator) or_return
		case .FUNCTION: func_typeidx = parse_function_section(&s, allocator) or_return
		case .EXPORT:   m.exports    = parse_exports         (&s, allocator) or_return
		case .CODE:     codes        = parse_code            (&s, allocator) or_return
		case .START:    m.start      = i64(rd_u32(&s) or_return)
		}
	}

	parse_custom_sections(&m, allocator) or_return

	build_functions(&m, func_typeidx, codes, allocator) or_return
	apply_name_section(&m)

	m.reloc_groups = parse_relocations(m, allocator) or_return

	return
}

@(require_results)
parse_types :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Func_Type, err: Reader_Error) {
	n := rd_u32(r) or_return
	out = make([]Func_Type, int(n), allocator) or_return
	for &func in out {
		form := rd_byte(r) or_return
		if form != 0x60 {
			return out, .BAD_TYPE_FORM
		}
		func.params  = rd_valtype_vec(r, allocator) or_return
		func.results = rd_valtype_vec(r, allocator) or_return
	}
	return
}

@(require_results)
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
			_ = rd_byte(r)      or_return // reftype
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

@(require_results)
parse_function_section :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []u32, err: Reader_Error) {
	n := rd_u32(r) or_return
	out = make([]u32, int(n), allocator) or_return
	for &idx in out {
		idx = rd_u32(r) or_return
	}
	return
}

@(require_results)
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

Code_Body :: struct {
	locals:      []Local_Group,
	body_offset: u32,
	body_size:   u32,
}

@(require_results)
parse_code :: proc(r: ^Reader, allocator: runtime.Allocator) -> (out: []Code_Body, err: Reader_Error) {
	n := rd_u32(r) or_return
	out = make([]Code_Body, int(n), allocator) or_return
	for &code_body in out {
		total := rd_u32(r) or_return
		body_start := r.off
		body_end := body_start + total

		nl := rd_u32(r) or_return
		locals := make([]Local_Group, int(nl), allocator) or_return
		for &local in locals {
			cnt := rd_u32(r) or_return
			t   := wasm.Value_Type(rd_byte(r) or_return)
			local = Local_Group{count = cnt, type = t}
		}
		code_body = Code_Body{
			locals      = locals,
			body_offset = r.off,
			body_size   = body_end > r.off ? body_end - r.off : 0,
		}
		r.off = body_end // jump past the expression to the next entry
	}
	return
}

@(require_results)
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

@(require_results)
build_functions :: proc(m: ^Module, func_typeidx: []u32, codes: []Code_Body, allocator: runtime.Allocator) -> runtime.Allocator_Error {
	num_imports := 0
	for imp in m.imports {
		if imp.kind == .FUNC {
			num_imports += 1
		}
	}
	total := num_imports + len(func_typeidx)
	if total == 0 {
		return nil
	}

	funcs := make([]Function, total, allocator) or_return

	idx := 0
	for imp in m.imports {
		(imp.kind == .FUNC) or_continue
		f := Function{
			func_index    = u32(idx),
			type_index    = imp.index,
			imported      = true,
			name          = imp.field_name,
			import_module = imp.module_name,
			import_field  = imp.field_name,
		}
		if int(imp.index) < len(m.types) {
			f.type = m.types[imp.index]
		}
		funcs[idx] = f
		idx += 1
	}

	for tidx, i in func_typeidx {
		fi := num_imports + i
		f := Function{
			func_index = u32(fi),
			type_index = tidx,
			imported   = false,
		}
		if int(tidx) < len(m.types) {
			f.type = m.types[tidx]
		}
		if i < len(codes) {
			c := &codes[i]
			f.locals      = c.locals
			f.body_offset = c.body_offset
			f.body_size   = c.body_size
		}
		funcs[fi] = f
	}

	for e in m.exports {
		if e.kind == .FUNC && int(e.index) < total && funcs[e.index].name == "" {
			f := &funcs[e.index]
			f.name = e.name
			f.exported = true
		}
	}

	m.functions = funcs
	return nil
}

// Override function names with debug names from the "name" custom section's function-names subsection (id 1), if it exists.
apply_name_section :: proc(m: ^Module) {
	for sec in m.sections {
		if sec.id != .CUSTOM || sec.name != "name" {
			continue
		}

		r := reader(m.data, sec.offset)
		_ = rd_name(&r) or_break // re-read the section name to position at the subsections
		end := sec.offset + sec.size

		for r.off < end {
			sub_id   := rd_byte(&r) or_break
			sub_size := rd_u32(&r)  or_break
			payload_end := r.off + sub_size
			if sub_id == 1 {
				count := rd_u32(&r) or_break
				for _ in 0..<count {
					fidx := rd_u32(&r)  or_break
					name := rd_name(&r) or_break
					if int(fidx) < len(m.functions) {
						m.functions[fidx].name = name
					}
				}
			}
			// skip any subsection we do not need to interpret
			r.off = payload_end
		}
		return
	}
}

module_destroy :: proc(m: ^Module) {
	relocations_destroy(m.reloc_groups, m.allocator)

	for t in m.types {
		delete(t.params,  m.allocator)
		delete(t.results, m.allocator)
	}
	for f in m.functions {
		if !f.imported {
			delete(f.locals, m.allocator)
		}
	}
	for c in m.customs {
		switch v in c.variant {
		case Custom_Section_Name:
			for function_locals in v.locals {
				delete(function_locals.locals, m.allocator)
			}
			delete(v.functions, m.allocator)
			delete(v.locals, m.allocator)
		case Custom_Section_Target_Features:
			delete(v.features)
		}
	}
	delete(m.customs,   m.allocator)
	delete(m.sections,  m.allocator)
	delete(m.types,     m.allocator)
	delete(m.imports,   m.allocator)
	delete(m.functions, m.allocator)
	delete(m.exports,   m.allocator)
	m^ = {}
}
