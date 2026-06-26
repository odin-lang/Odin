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

	words := mem.slice_data_cast([]u32, buf[:n])
	ver := words[1]   // header fields as actually encoded (bound is computed there)
	fmt.sbprintf(sb, "; SPIR-V\n; Version: %d.%d\n; Generator: 0x%08x\n; Bound: %d\n; Schema: 0\n",
		(ver >> 16) & 0xFF, (ver >> 8) & 0xFF, words[2], words[3])
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
		if fmt_enum(sb, kind, w[0]) { return 1 }
		fmt.sbprintf(sb, "%d", w[0]); return 1
	}
}

// Symbolic name for the common enum operand kinds (others fall back to numeric).
// ValueEnums print their member name, BitEnums their set; an out-of-range value
// prints numerically via fmt's enum handling.
@(private="file")
fmt_enum :: proc(sb: ^strings.Builder, kind: Spec_Kind, v: u32) -> bool {
	#partial switch kind {
	case .SourceLanguage:  fmt.sbprintf(sb, "%v", Source_Language(v))
	case .ExecutionModel:  fmt.sbprintf(sb, "%v", Execution_Model(v))
	case .AddressingModel: fmt.sbprintf(sb, "%v", Addressing_Model(v))
	case .MemoryModel:     fmt.sbprintf(sb, "%v", Memory_Model(v))
	case .ExecutionMode:   fmt.sbprintf(sb, "%v", Execution_Mode(v))
	case .StorageClass:    fmt.sbprintf(sb, "%v", Storage_Class(v))
	case .Decoration:      fmt.sbprintf(sb, "%v", Decoration(v))
	case .Capability:      fmt.sbprintf(sb, "%v", Capability(v))
	// BitEnums (FunctionControl, MemoryAccess, ...) stay numeric -- their bit_set
	// %v form is too verbose to read inline.
	case: return false
	}
	return true
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
