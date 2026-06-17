package rexcode_wasm_module

import "core:strings"
import "core:os"
import "core:fmt"
import wasm "../"

print_module :: proc(m: Module) {
	sb := strings.builder_make(context.allocator)
	defer strings.builder_destroy(&sb)
	sbprint_module(&sb, m)
	s := strings.to_string(sb)
	os.write_string(os.stdout, s)
}

sbprint_module :: proc(sb: ^strings.Builder, m: Module) {
	write_func_type :: proc(sb: ^strings.Builder, t: Func_Type) {
		strings.write_byte(sb, '(')
		for p, i in t.params {
			if i > 0 { strings.write_string(sb, ", ") }
			strings.write_string(sb, valtype_name(p))
		}
		strings.write_string(sb, ") -> ")
		strings.write_byte(sb, '(')
		for rt, i in t.results {
			if i > 0 { strings.write_string(sb, ", ") }
			strings.write_string(sb, valtype_name(rt))
		}
		strings.write_byte(sb, ')')
	}


	strings.write_string(sb, "WebAssembly Module, Version: ")
	strings.write_u64(sb, u64(m.version))
	strings.write_byte(sb, '\n')

	label_names: map[u32]string
	defer delete(label_names)
	for f in m.functions {
		if f.name != "" {
			label_names[f.func_index] = f.name
		}
	}

	relocs_group, _ := parse_relocations(m, m.allocator)
	defer delete(relocs_group, m.allocator)

	// sections
	for sec in m.sections {
		write_padded :: proc(sb: ^strings.Builder, s: string, width: int) {
			strings.write_string(sb, s)
			for _ in len(s)..<width {
				strings.write_byte(sb, ' ')
			}
		}

		strings.write_string(sb, ".")
		write_padded(sb, section_name(sec.id), 12)
		#partial switch sec.id {
		case .CUSTOM:
			strings.write_string(sb, "  \"")
			strings.write_string(sb, sec.name)
			strings.write_byte(sb, '"')
		case .START:
			// do nothing
		case:
			strings.write_string(sb, "  (")
			strings.write_u64(sb, u64(sec.count))
			strings.write_string(sb, " entries)")
		}
		strings.write_byte(sb, '\n')

		data := m.data[sec.offset:][:sec.size]

		section_printing: #partial switch sec.id {
		case .DATA:
			r := reader(data, 0)
			count := rd_u32(&r) or_break section_printing
			assert(count == sec.count)
			for i in 0..<sec.count {
				fmt.sbprintf(sb, "  [%d]\n", i)
				kind := rd_u32(&r) or_break section_printing
				switch kind {
				case 2: // memidx + expr + []byte
					memidx := rd_u32(&r) or_break section_printing
					fmt.sbprintf(sb, "    memidx:%d\n", memidx)
					fallthrough
				case 0: // expr + []byte
					relocs: []wasm.Relocation
					for rg in relocs_group {
						if rg.target_section == sec.id {
							relocs = rg.relocs
							break
						}
					}

					for r.off < u32(len(r.data)) {
						inst, info, next := wasm.decode_one(r.data[r.off:], relocs=relocs, pc=0, targets_allocator=context.temp_allocator) or_break section_printing
						r.off += next
						if inst.mnemonic == .END {
							break
						}
						wasm.sbprint(sb, {inst}, {info}, nil, &label_names)
					}
					size := rd_u32(&r) or_break section_printing
					fmt.sbprintf(sb, "    %q\n", r.data[r.off:][:size])
				case 1:  // []byte
					fmt.sbprintf(sb, "    %q\n", r.data[r.off:])
				}
			}
		case .MEMORY:
			r := reader(data, 0)
			count := rd_u32(&r) or_break section_printing
			assert(count == sec.count)
			for i in 0..<sec.count {
				fmt.sbprintf(sb, "  [%d]\n", i)
				min, max := rd_limits(&r) or_break section_printing
				if max == nil {
					fmt.sbprintf(sb, "    limits: %v..inf\n", min)
				} else {
					fmt.sbprintf(sb, "    limits: %v..%v\n", min, max)
				}
			}
		}
	}

	if len(m.imports) > 0 {
		strings.write_string(sb, "\n.import\n")
		for imp, i in m.imports {
			fmt.sbprintf(sb, "  [%d] %s %q %q idx:%d\n", i, external_kind_string[imp.kind], imp.module_name, imp.field_name, imp.index)
		}
	}

	if len(m.exports) > 0 {
		strings.write_string(sb, "\n.export\n")
		for e, i in m.exports {
			fmt.sbprintf(sb, "  [%d] %s %q idx:%d\n", i, external_kind_string[e.kind], e.name, e.index)
		}
	}

	if len(m.types) > 0 {
		strings.write_string(sb, "\n.")
		strings.write_string(sb, section_name(.TYPE))
		strings.write_string(sb, "\n")
		for t, i in m.types {
			strings.write_string(sb, "  [")
			strings.write_u64(sb, u64(i))
			strings.write_string(sb, "] ")
			write_func_type(sb, t)
			strings.write_byte(sb, '\n')
		}
	}


	func_relocs: []wasm.Relocation
	for rg in relocs_group {
		if rg.target_section == .FUNCTION {
			func_relocs = rg.relocs
			break
		}
	}

	strings.write_string(sb, "\nfunctions:\n")
	for f in m.functions {
		strings.write_string(sb, "  [")
		strings.write_u64(sb, u64(f.func_index))
		strings.write_string(sb, "] ")
		if f.name != "" {
			strings.write_byte(sb, '$')
			strings.write_quoted_string(sb, f.name)
			strings.write_byte(sb, ' ')
		}
		write_func_type(sb, f.type)

		if f.imported {
			strings.write_string(sb, " @ import ")
			strings.write_quoted_string(sb, f.import_module)
			strings.write_string(sb, " ")
			strings.write_quoted_string(sb, f.import_field)
			strings.write_string(sb, "\n")
			continue
		}

		strings.write_byte(sb, '\n')

		if len(f.locals) != 0 {
			strings.write_string(sb, "    locals:")
			for g in f.locals {
				strings.write_byte(sb, ' ')
				if g.count > 1 {
					strings.write_u64(sb, u64(g.count))
					strings.write_string(sb, "x")
				}
				strings.write_string(sb, valtype_name(g.type))
			}
			strings.write_byte(sb, '\n')
		}

		if f.body_size != 0 {
			tmp_sb: strings.Builder
			defer strings.builder_destroy(&tmp_sb)
			text := sbprint_function(&tmp_sb, m, f, func_relocs, &label_names)
			for line in strings.split_lines_iterator(&text) {
				if line == "" {
					continue
				}
				strings.write_string(sb, "  ")
				strings.write_string(sb, line)
				strings.write_byte(sb, '\n')
			}
		}
	}
}

// Disassemble and print one function body. Returns the empty string for
// imported functions (which have no body).
sbprint_function :: proc(sb: ^strings.Builder, m: Module, f: Function, relocs: []wasm.Relocation, label_names: ^map[u32]string) -> string {
	if f.imported || f.body_size == 0 {
		return ""
	}
	body := m.data[f.body_offset:][:f.body_size]

	insts:  [dynamic]wasm.Instruction
	info:   [dynamic]wasm.Instruction_Info
	errs:   [dynamic]wasm.Error
	defer delete(insts)
	defer delete(info)
	defer delete(errs)

	wasm.decode(body, relocs, &insts, &info, &errs)
	wasm.sbprint(sb, insts[:], info[:], label_names=label_names)
	return strings.to_string(sb^)
}
