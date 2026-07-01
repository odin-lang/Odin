package rexcode_wasm_module

import "core:strings"
import "core:os"
import "core:fmt"
import wasm "../"

print_module :: proc(m: Module, file: ^os.File) {
	sb := strings.builder_make(context.allocator)
	defer strings.builder_destroy(&sb)
	sbprint_module(&sb, m)
	s := strings.to_string(sb)
	os.write_string(file, s)
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


	strings.write_string(sb, "module\n")
	strings.write_string(sb, "  version: ")
	strings.write_u64(sb, u64(m.version))
	strings.write_byte(sb, '\n')
	for c in m.customs {
		#partial switch v in c.variant {
		case Custom_Section_Name:
			if v.module_name != "" {
				strings.write_string(sb, "  file: ")
				strings.write_quoted_string(sb, v.module_name)
				strings.write_byte(sb, '\n')
			}
		}
	}


	label_names: map[u32]string
	defer delete(label_names)
	for f in m.functions {
		if f.name != "" {
			label_names[f.func_index] = f.name
		}
	}

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

		section_data := m.data[sec.offset:][:sec.size]

		section_printing: #partial switch sec.id {
		case .CUSTOM:
			for c in m.customs {
				if c.section != sec {
					continue
				}
				switch v in c.variant {
				case Custom_Section_Name:
					if v.module_name != "" {
						fmt.sbprintf(sb, "  module: %q\n", v.module_name)
					}
					// if len(v.functions) > 0 {
					// 	fmt.sbprintf(sb, "  functions:\n")
					// 	for f in v.functions {
					// 		fmt.sbprintf(sb, "    [%d] %q\n", f.id, f.name)
					// 	}
					// }
					// if len(v.locals) > 0 {
					// 	fmt.sbprintf(sb, "  locals:\n")
					// 	for fl in v.locals {
					// 		fmt.sbprintf(sb, "    [%d] function\n", fl.func_idx)
					// 		for local in fl.locals {
					// 			fmt.sbprintf(sb, "      [%d] %q\n", local.idx, local.name)
					// 		}
					// 	}
					// }
				case Custom_Section_Target_Features:
					for f in v.features {
						fmt.sbprintf(sb, "  \"%c%s\"\n", u8(f.prefix), f.feature)
					}
				}
				break
			}

		case .DATA:
			r := reader(section_data, 0)
			count := rd_u32(&r) or_break section_printing
			assert(count == sec.count)
			for i in 0..<sec.count {
				fmt.sbprintf(sb, "  [%d]\n", i)
				kind := rd_u32(&r) or_break section_printing

				switch kind {
				case 2: // memidx + expr + bytes
					memidx := rd_u32(&r) or_break section_printing
					if memidx != 0 {
						fmt.sbprintf(sb, "  memidx:%d\n", memidx)
					}
					fallthrough
				case 0: // expr + bytes
					relocs := relocations_from_section_id(m.reloc_groups, sec.id)
					for r.off < u32(len(r.data)) {
						inst, info, next := wasm.decode_one(r.data[r.off:], relocs=relocs, pc=0, targets_allocator=context.temp_allocator) or_break section_printing
						r.off += next
						if inst.mnemonic == .END {
							break
						}
						wasm.sbprint(sb, {inst}, {info}, nil, &label_names)
					}
				case 1: // bytes
					break
				}

				size := rd_u32(&r) or_break section_printing
				fmt.sbprintf(sb, "    %q\n", r.data[r.off:][:size])
				r.off += size
			}
		case .MEMORY:
			r := reader(section_data, 0)
			count := rd_u32(&r) or_break section_printing
			assert(count == sec.count)
			for i in 0..<sec.count {
				fmt.sbprintf(sb, "  [%d] ", i)
				min, max := rd_limits(&r) or_break section_printing
				if max == nil {
					fmt.sbprintf(sb, "limits: %v..inf\n", min)
				} else {
					fmt.sbprintf(sb, "limits: %v..%v\n", min, max)
				}
			}
		}
	}

	strings.write_string(sb, "\n")

	if len(m.imports) > 0 {
		strings.write_string(sb, ".import\n")
		for imp in m.imports {
			f := &m.functions[imp.index]
			fmt.sbprintf(sb, "  %s %q %q", external_kind_string[imp.kind], imp.module_name, imp.field_name)
			write_func_type(sb, f.type)
			strings.write_string(sb, "\n")
		}
		strings.write_string(sb, "\n")
	}

	if len(m.exports) > 0 {
		strings.write_string(sb, ".export\n")
		for e in m.exports {
			f := &m.functions[e.index]
			fmt.sbprintf(sb, "  %s %q", external_kind_string[e.kind], e.name)
			write_func_type(sb, f.type)
			strings.write_string(sb, "\n")
		}
		strings.write_string(sb, "\n")
	}

	// if len(m.types) > 0 {
	// 	strings.write_string(sb, "\n.")
	// 	strings.write_string(sb, section_name(.TYPE))
	// 	strings.write_string(sb, "\n")
	// 	for t, i in m.types {
	// 		strings.write_string(sb, "  [")
	// 		strings.write_u64(sb, u64(i))
	// 		strings.write_string(sb, "] ")
	// 		write_func_type(sb, t)
	// 		strings.write_byte(sb, '\n')
	// 	}
	// }


	func_relocs := relocations_from_section_id(m.reloc_groups, .FUNCTION)

	for f in m.functions {
		if f.exported {
			strings.write_string(sb, "export ")
		}
		if f.name != "" {
			strings.write_string(sb, external_kind_string[.FUNC])
			strings.write_byte(sb, ' ')
			strings.write_quoted_string(sb, f.name)
		}
		write_func_type(sb, f.type)


		if f.imported {
			strings.write_string(sb, "\n  import ")
			strings.write_quoted_string(sb, f.import_module)
			strings.write_string(sb, " ")
			strings.write_quoted_string(sb, f.import_field)
			strings.write_string(sb, "\n")
			continue
		}

		strings.write_byte(sb, '\n')

		if len(f.locals) != 0 {
			strings.write_string(sb, "  locals:")
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
			sbprint_function(sb, m, f, func_relocs, &label_names)
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
