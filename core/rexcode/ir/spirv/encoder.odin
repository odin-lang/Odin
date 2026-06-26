// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

import "base:intrinsics"

// =============================================================================
// SECTION: Encoder  (Module -> SPIR-V word stream)
// =============================================================================
//
// Emits the module header followed by the instruction stream in the spec's
// required section order (SPIR-V spec §2.4 Logical Layout): capabilities,
// extensions, ext-inst imports, memory model, entry points, execution modes,
// debug, annotations, then types/constants/globals and function definitions.
//
// Fast and single-pass: each word is one (host-endian) store into the caller's
// buffer; an instruction's header word is written as a placeholder, the operands
// streamed after it, and the word count backpatched at the end -- so variable-
// length instructions (strings, variadic operands) need no pre-measure pass.
// SPIR-V's endianness is self-describing via the magic word, so host-endian
// output is conformant.

// -----------------------------------------------------------------------------
// Word writer
// -----------------------------------------------------------------------------

Writer :: struct {
	code: []u8,
	pos:  u32,    // byte offset; always a multiple of 4
	ok:   bool,
}

@(private="file")
w_word :: #force_inline proc "contextless" (w: ^Writer, word: u32) {
	if int(w.pos) + 4 > len(w.code) {
		w.ok = false
		return
	}
	intrinsics.unaligned_store(cast(^u32)&w.code[w.pos], word)
	w.pos += 4
}

@(private="file") w_id :: #force_inline proc "contextless" (w: ^Writer, id: Id) { w_word(w, u32(id)) }

// SPIR-V LiteralString: the UTF-8 bytes, NUL-terminated, packed little-endian
// into words and zero-padded to a word boundary. (len+4)/4 words: always at
// least the terminator + padding, even for an empty / word-multiple string.
@(private="file")
w_string :: proc "contextless" (w: ^Writer, s: string) {
	nwords := (len(s) + 4) / 4
	for wi in 0 ..< nwords {
		word: u32 = 0
		for b in 0 ..< 4 {
			idx := wi * 4 + b
			if idx < len(s) {
				word |= u32(s[idx]) << uint(b * 8)
			}
		}
		w_word(w, word)
	}
}

// Reserve the instruction header word; pair with inst_end to backpatch its count.
@(private="file")
inst_begin :: #force_inline proc "contextless" (w: ^Writer) -> u32 {
	p := w.pos
	w_word(w, 0)
	return p
}

@(private="file")
inst_end :: #force_inline proc "contextless" (w: ^Writer, start: u32, opcode: Opcode) {
	if !w.ok { return }
	count := (w.pos - start) / 4
	intrinsics.unaligned_store(cast(^u32)&w.code[start], inst_head(count, opcode))
}

// -----------------------------------------------------------------------------
// Header + preamble sections
// -----------------------------------------------------------------------------

@(private="file")
emit_header :: proc "contextless" (w: ^Writer, m: ^Module) {
	w_word(w, MAGIC)
	w_word(w, m.version != 0 ? m.version : VERSION_1_5)
	w_word(w, m.generator)
	w_word(w, m.bound)          // exclusive upper bound on <id>s (caller-set / lowered)
	w_word(w, 0)                // schema
}

@(private="file")
emit_preamble :: proc "contextless" (w: ^Writer, m: ^Module) {
	for cap in m.capabilities {
		s := inst_begin(w); w_word(w, u32(cap)); inst_end(w, s, .OpCapability)
	}
	for ext in m.extensions {
		s := inst_begin(w); w_string(w, ext); inst_end(w, s, .OpExtension)
	}
	for ei in m.ext_imports {
		s := inst_begin(w); w_id(w, ei.result); w_string(w, ei.name); inst_end(w, s, .OpExtInstImport)
	}
	{
		s := inst_begin(w); w_word(w, u32(m.addressing)); w_word(w, u32(m.memory)); inst_end(w, s, .OpMemoryModel)
	}
	for ep in m.entry_points {
		s := inst_begin(w)
		w_word(w, u32(ep.model)); w_id(w, ep.function); w_string(w, ep.name)
		for iface in ep.interface { w_id(w, iface) }
		inst_end(w, s, .OpEntryPoint)
	}
	for em in m.exec_modes {
		s := inst_begin(w)
		w_id(w, em.entry); w_word(w, u32(em.mode))
		for op in em.operands { w_word(w, op) }
		inst_end(w, s, em.is_id ? .OpExecutionModeId : .OpExecutionMode)
	}
}

@(private="file")
emit_debug :: proc "contextless" (w: ^Writer, m: ^Module) {
	for str in m.debug.strings {
		s := inst_begin(w); w_id(w, str.result); w_string(w, str.text); inst_end(w, s, .OpString)
	}
	if m.debug.source_language != 0 {
		s := inst_begin(w)
		w_word(w, m.debug.source_language); w_word(w, m.debug.source_version)
		if m.debug.source_file != ID_NONE { w_id(w, m.debug.source_file) }
		inst_end(w, s, .OpSource)
	}
	for nm in m.debug.names {
		s := inst_begin(w)
		w_id(w, nm.target)
		if nm.member != MEMBER_NONE {
			w_word(w, nm.member); w_string(w, nm.text); inst_end(w, s, .OpMemberName)
		} else {
			w_string(w, nm.text); inst_end(w, s, .OpName)
		}
	}
}

@(private="file")
emit_annotations :: proc "contextless" (w: ^Writer, m: ^Module) {
	for d in m.decorations {
		s := inst_begin(w)
		w_id(w, d.target)
		if d.member != MEMBER_NONE {
			w_word(w, d.member); w_word(w, u32(d.decoration))
			for op in d.operands { w_word(w, op) }
			inst_end(w, s, .OpMemberDecorate)
		} else {
			w_word(w, u32(d.decoration))
			for op in d.operands { w_word(w, op) }
			inst_end(w, s, .OpDecorate)
		}
	}
}

// -----------------------------------------------------------------------------
// Types / constants / globals  (the <id>-defining body, before functions)
// -----------------------------------------------------------------------------

// Type_Ref -> the type's wire <id>, via the side table.
@(private="file")
tid :: #force_inline proc "contextless" (m: ^Module, t: Type_Ref) -> Id {
	i := u32(t)
	return i < u32(len(m.type_ids)) ? m.type_ids[i] : ID_NONE
}

// Lower ir.Type -> OpTypeXxx. INT signedness and POINTER storage class ride in
// Type.aux. (ARRAY/OPAQUE/REF need a length constant / extra modelling and are
// skipped for now.)
@(private="file")
emit_types :: proc "contextless" (w: ^Writer, m: ^Module) {
	for t, i in m.types {
		s := inst_begin(w)
		w_id(w, i < len(m.type_ids) ? m.type_ids[i] : ID_NONE)
		op: Opcode
		switch t.kind {
		case .VOID:    op = .OpTypeVoid
		case .BOOL:    op = .OpTypeBool
		case .INT:     w_word(w, u32(t.bits)); w_word(w, u32(t.aux & 1)); op = .OpTypeInt
		case .FLOAT:   w_word(w, u32(t.bits)); op = .OpTypeFloat
		case .VECTOR:  w_id(w, tid(m, t.elem)); w_word(w, t.count); op = .OpTypeVector
		case .ARRAY:   w_id(w, tid(m, t.elem)); w_id(w, t.len_ref); op = .OpTypeArray   // length: a constant <id>
		case .POINTER: w_word(w, u32(t.aux)); w_id(w, tid(m, t.elem)); op = .OpTypePointer
		case .STRUCT:
			for f in t.fields { w_id(w, tid(m, f)) }
			op = .OpTypeStruct
		case .FUNCTION:
			w_id(w, tid(m, t.fields[t.count]))              // return type
			for pi in 0 ..< int(t.count) { w_id(w, tid(m, t.fields[pi])) }
			op = .OpTypeFunction
		case .OPAQUE, .REF:
			w.pos = s    // rewind the placeholder; not yet lowered
			continue
		}
		inst_end(w, s, op)
	}
}

@(private="file")
emit_constants :: proc "contextless" (w: ^Writer, m: ^Module) {
	for c in m.constants {
		s := inst_begin(w)
		w_id(w, tid(m, c.result.type))
		w_id(w, c.result.id)
		#partial switch c.opcode {
		case .OpConstant:
			t := m.types[u32(c.result.type)]
			w_word(w, u32(c.value))
			if (t.kind == .INT || t.kind == .FLOAT) && t.bits > 32 {
				w_word(w, u32(c.value >> 32))   // context-dependent number, second word
			}
		case .OpConstantComposite:
			for e in c.elements { w_id(w, e) }
		}
		inst_end(w, s, c.opcode)
	}
}

@(private="file")
emit_globals :: proc "contextless" (w: ^Writer, m: ^Module) {
	for g, gi in m.globals {
		s := inst_begin(w)
		w_id(w, tid(m, g.type))   // a pointer type
		w_id(w, gi < len(m.global_ids) ? m.global_ids[gi] : ID_NONE)
		w_word(w, u32(m.types[u32(g.type)].aux))   // storage class = the pointer's address space
		if g.init != ID_NONE { w_id(w, g.init) }
		inst_end(w, s, .OpVariable)
	}
}

// -----------------------------------------------------------------------------
// Function bodies  (the generic, table-driven operation emit)
// -----------------------------------------------------------------------------

// Emit one ir.Operand by its kind. Type refs resolve through the type-id table;
// entity refs and literals are emitted as-is.
@(private="file")
emit_operand :: #force_inline proc "contextless" (w: ^Writer, m: ^Module, o: Operand) {
	switch o.kind {
	case .NONE:
	case .LIT_INT, .LIT_FLOAT, .ATTRIBUTE: w_word(w, u32(o.imm))
	case .REF:                             w_id(w, operand_id(o))
	case .TYPE:                            w_id(w, tid(m, operand_type(o)))
	}
}

// Emit one Operation. The opcode's layout (INSTRUCTION_INDEX) supplies the
// leading IdResultType/IdResult from `result`; the remaining operands are
// `op.operands` in order (the producer built them correctly, so no per-operand
// spec match is needed -- only whether a result type/id prefix exists).
@(private="file")
emit_operation :: proc "contextless" (w: ^Writer, m: ^Module, op: ^Operation) {
	run: Spec_Run
	if int(op.opcode) < len(INSTRUCTION_INDEX) { run = INSTRUCTION_INDEX[op.opcode] }
	s := inst_begin(w)
	si := 0
	if si < int(run.count) && INSTRUCTION_SPECS[int(run.start) + si].kind == .IdResultType {
		w_id(w, tid(m, op.result.type)); si += 1
	}
	if si < int(run.count) && INSTRUCTION_SPECS[int(run.start) + si].kind == .IdResult {
		w_id(w, op.result.id); si += 1
	}
	for o in op.operands { emit_operand(w, m, o) }
	inst_end(w, s, Opcode(op.opcode))
}

@(private="file")
emit_functions :: proc "contextless" (w: ^Writer, m: ^Module) {
	for fn, fi in m.functions {
		sig := m.types[u32(fn.signature)]   // a FUNCTION type: fields = params ++ [result]
		s := inst_begin(w)
		w_id(w, tid(m, sig.fields[sig.count]))                          // result = return type
		w_id(w, fi < len(m.function_ids) ? m.function_ids[fi] : ID_NONE)
		w_word(w, 0)                                                    // FunctionControl (none)
		w_id(w, tid(m, fn.signature))
		inst_end(w, s, .OpFunction)
		// Function parameters: the entry block's params are the OpFunctionParameters,
		// emitted between OpFunction and the entry OpLabel.
		if len(fn.blocks) > 0 {
			for p in fn.blocks[0].params {
				sp := inst_begin(w); w_id(w, tid(m, p.type)); w_id(w, p.id); inst_end(w, sp, .OpFunctionParameter)
			}
		}
		for blk in fn.blocks {
			sl := inst_begin(w); w_id(w, blk.id); inst_end(w, sl, .OpLabel)
			for &op in blk.ops { emit_operation(w, m, &op) }
		}
		se := inst_begin(w); inst_end(w, se, .OpFunctionEnd)
	}
}

// -----------------------------------------------------------------------------
// Entry point
// -----------------------------------------------------------------------------

@(private="file")
max_id :: #force_inline proc "contextless" (cur: u32, id: Id) -> u32 {
	return id != ID_NONE ? max(cur, u32(id)) : cur
}

// The exclusive upper bound on every <id> in the module (the header's `bound`).
@(private="file")
compute_bound :: proc "contextless" (m: ^Module) -> u32 {
	hi := u32(0)
	for id in m.type_ids     { hi = max_id(hi, id) }
	for id in m.global_ids   { hi = max_id(hi, id) }
	for id in m.function_ids { hi = max_id(hi, id) }
	for ei in m.ext_imports  { hi = max_id(hi, ei.result) }
	for s in m.debug.strings { hi = max_id(hi, s.result) }
	for c in m.constants     { hi = max_id(hi, c.result.id) }
	for fn in m.functions {
		for blk in fn.blocks {
			hi = max_id(hi, blk.id)
			for p in blk.params { hi = max_id(hi, p.id) }
			for op in blk.ops   { hi = max_id(hi, op.result.id) }
		}
	}
	return hi + 1
}

// encode: serialize `m` into `code` in spec layout order, returning the byte
// count written. `bound` is computed when left 0 (else taken as-is, so a decoded
// module re-encodes with its original bound).
encode :: proc(m: Module, code: []u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) -> (byte_count: u32, ok: bool) {
	m := m
	if m.bound == 0 { m.bound = compute_bound(&m) }
	w := Writer{code = code, ok = true}
	emit_header(&w, &m)
	emit_preamble(&w, &m)
	emit_debug(&w, &m)
	emit_annotations(&w, &m)
	emit_types(&w, &m)
	emit_constants(&w, &m)
	emit_globals(&w, &m)
	emit_functions(&w, &m)
	return w.pos, w.ok
}
