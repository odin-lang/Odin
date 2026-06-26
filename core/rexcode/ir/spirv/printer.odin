// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

import "core:fmt"
import "core:mem"
import "core:strings"

// =============================================================================
// SECTION: Printer  (Module -> textual disassembly)
// =============================================================================
//
// The third ir verb. Disassembles into a spirv-dis-style listing -- a header
// comment block, then one line per instruction: `%result = OpName args`, args
// right-aligned past the result column.
//
// It works by encoding to a scratch buffer and walking the word stream
// generically through the operand-layout table, so every opcode disassembles
// with no per-op code: Id operands print as %id, LiteralString as "...", and
// everything else (literals, enums) as its numeric value for now (symbolic enum
// names are a later refinement).

// print: disassemble `m` into the caller-owned builder `sb`.
print :: proc(m: Module, sb: ^strings.Builder, options: ^Print_Options = nil) {
	opts := DEFAULT_PRINT_OPTIONS
	if options != nil { opts = options^ }
	if opts.value_prefix == "" { opts.value_prefix = "%" }

	// encode to a scratch buffer, doubling on overflow.
	size := 4096
	buf: []u8
	n:   u32
	ok:  bool
	for {
		buf = make([]u8, size, context.temp_allocator)
		relocs: [dynamic]Relocation
		errors: [dynamic]Error
		n, ok = encode(m, buf, &relocs, &errors)
		delete(relocs); delete(errors)
		if ok || size >= 64 * 1024 * 1024 { break }
		size *= 2
	}
	if !ok {
		strings.write_string(sb, "; <encode failed>\n")
		return
	}

	fmt.sbprintf(sb, "; SPIR-V\n; Version: %d.%d\n; Generator: 0x%08x\n; Bound: %d\n; Schema: 0\n",
		(m.version >> 16) & 0xFF, (m.version >> 8) & 0xFF, m.generator, m.bound)

	words := mem.slice_data_cast([]u32, buf[:n])
	wi := int(HEADER_WORDS)
	for wi < len(words) {
		head := words[wi]
		count := int(head >> 16)
		opcode := Opcode(head & 0xFFFF)
		if count == 0 || wi + count > len(words) { break }
		fmt_inst(sb, opcode, words[wi + 1 : wi + count], &opts)
		wi += count
	}
}

@(private="file")
fmt_inst :: proc(sb: ^strings.Builder, opcode: Opcode, w: []u32, opts: ^Print_Options) {
	run: Spec_Run
	if int(opcode) < len(INSTRUCTION_INDEX) { run = INSTRUCTION_INDEX[u16(opcode)] }

	args := strings.builder_make(context.temp_allocator)
	result_id:  u32
	has_result: bool

	wi, si := 0, 0
	for si < int(run.count) && wi < len(w) {
		spec := INSTRUCTION_SPECS[int(run.start) + si]
		si += 1
		if spec.kind == .IdResult {
			result_id = w[wi]; has_result = true; wi += 1
			continue
		}
		if spec.quant == .VARIADIC {
			for wi < len(w) {
				strings.write_byte(&args, ' ')
				wi += fmt_operand(&args, spec.kind, w[wi:], opts)
			}
		} else {
			strings.write_byte(&args, ' ')
			wi += fmt_operand(&args, spec.kind, w[wi:], opts)
		}
	}

	// right-align the "%id = " result column, then OpName + args.
	COL :: 14
	prefix := has_result ? fmt.tprintf("%s%d = ", opts.value_prefix, result_id) : ""
	for _ in 0 ..< max(0, COL - len(prefix)) { strings.write_byte(sb, ' ') }
	strings.write_string(sb, prefix)
	fmt.sbprintf(sb, "%v%s\n", opcode, strings.to_string(args))
}

@(private="file")
fmt_operand :: proc(sb: ^strings.Builder, kind: Spec_Kind, w: []u32, opts: ^Print_Options) -> int {
	#partial switch kind {
	case .IdResultType, .IdRef, .IdScope, .IdMemorySemantics:
		fmt.sbprintf(sb, "%s%d", opts.value_prefix, w[0]); return 1
	case .LiteralString:
		s, nwords := str_from_words(w)
		fmt.sbprintf(sb, "%q", s); return nwords
	case:
		fmt.sbprintf(sb, "%d", w[0]); return 1
	}
}

@(private="file")
str_from_words :: proc(w: []u32) -> (s: string, nwords: int) {
	buf := strings.builder_make(context.temp_allocator)
	outer: for word in w {
		for b in 0 ..< 4 {
			c := u8(word >> uint(b * 8))
			if c == 0 { break outer }
			strings.write_byte(&buf, c)
		}
	}
	return strings.to_string(buf), (len(buf.buf) + 4) / 4
}
