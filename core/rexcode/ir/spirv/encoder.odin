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
// Entry point
// -----------------------------------------------------------------------------

// encode: serialize `m` into `code`, returning the byte count written.
//
// (Types / constants / globals / function bodies are not yet emitted -- that
// half needs the <id> assignment + ir.Type -> OpTypeXxx lowering, which lands
// next. The header + preamble / debug / annotation sections are complete.)
encode :: proc(m: Module, code: []u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) -> (byte_count: u32, ok: bool) {
	m := m
	w := Writer{code = code, ok = true}
	emit_header(&w, &m)
	emit_preamble(&w, &m)
	emit_debug(&w, &m)
	emit_annotations(&w, &m)
	// TODO(codec): emit_types_constants_globals + emit_functions (the lowered body).
	return w.pos, w.ok
}
