package flags

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:reflect"
import "core:slice"
import "core:strconv"
import "core:strings"

/*
Write out the documentation for the command-line arguments to a stream.

Inputs:
- out: The stream to write to.
- data_type: The typeid of the data structure to describe.
- program: The name of the program, usually the first argument to `os.args`.
- style: The argument parsing style, required to show flags in the proper style.
*/
@(optimization_mode="favor_size")
write_usage :: proc(out: io.Writer, data_type: typeid, program: string = "", style: Parsing_Style = .Odin) {
	// All flags get their tags parsed so they can be reasoned about later.
	Flag :: struct {
		name: string,
		usage: string,
		type_description: string,
		full_length: int,
		pos: int,
		required_min, required_max: int,
		is_positional: bool,
		is_required: bool,
		is_boolean: bool,
		is_variadic: bool,
		variadic_length: int,
	}

	//
	// POSITIONAL+REQUIRED, POSITIONAL, REQUIRED, NON_REQUIRED+NON_POSITIONAL, ...
	//
	sort_flags :: proc(i, j: Flag) -> slice.Ordering {
		// `varg` goes to the end.
		if i.name == INTERNAL_VARIADIC_FLAG {
			return .Greater
		} else if j.name == INTERNAL_VARIADIC_FLAG {
			return .Less
		}

		// Handle positionals.
		if i.is_positional {
			if j.is_positional {
				return slice.cmp(i.pos, j.pos)
			} else {
				return .Less
			}
		} else {
			if j.is_positional {
				return .Greater
			}
		}

		// Then required flags.
		if i.is_required {
			if !j.is_required {
				return .Less
			}
		} else if j.is_required {
			return .Greater
		}

		// Finally, sort by name.
		return slice.cmp(i.name, j.name)
	}

	describe_array_requirements :: proc(flag: Flag) -> (spec: string) {
		if flag.is_required {
			if flag.required_min == flag.required_max - 1 {
				spec = fmt.tprintf(", exactly %i", flag.required_min)
			} else if flag.required_min > 0 && flag.required_max == max(int) {
				spec = fmt.tprintf(", at least %i", flag.required_min)
			} else if flag.required_min == 0 && flag.required_max > 1 {
				spec = fmt.tprintf(", at most %i", flag.required_max - 1)
			} else if flag.required_min > 0 && flag.required_max > 1 {
				spec = fmt.tprintf(", between %i and %i", flag.required_min, flag.required_max - 1)
			} else {
				spec = ", required"
			}
		}
		return
	}

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	flag_prefix, flag_assignment: string = ---, ---
	switch style {
	case .Odin: flag_prefix = "-";  flag_assignment = ":"
	case .Unix: flag_prefix = "--"; flag_assignment = " "
	}

	visible_flags: [dynamic]Flag
	defer delete(visible_flags)

	longest_flag_length: int

	for field in reflect.struct_fields_zipped(data_type) {
		flag: Flag

		if args_tag, ok := reflect.struct_tag_lookup(field.tag, TAG_ARGS); ok {
			if _, is_hidden := get_struct_subtag(args_tag, SUBTAG_HIDDEN); is_hidden {
				// Hidden flags stay hidden.
				continue
			}
			if pos_str, is_pos := get_struct_subtag(args_tag, SUBTAG_POS); is_pos {
				flag.is_positional = true
				if pos, parse_ok := strconv.parse_u64_of_base(pos_str, 10); parse_ok {
					flag.pos = cast(int)pos
				}
			}
			if requirement, is_required := get_struct_subtag(args_tag, SUBTAG_REQUIRED); is_required {
				flag.is_required = true
				flag.required_min, flag.required_max, _ = parse_requirements(requirement)
			}
			if length_str, is_variadic := get_struct_subtag(args_tag, SUBTAG_VARIADIC); is_variadic {
				flag.is_variadic = true
				if length, parse_ok := strconv.parse_u64_of_base(length_str, 10); parse_ok {
					flag.variadic_length = cast(int)length
				}
			}
		}

		flag.name = get_field_name(field)
		flag.is_boolean = reflect.is_boolean(field.type)

		if usage, ok := reflect.struct_tag_lookup(field.tag, TAG_USAGE); ok {
			flag.usage = usage
		} else {
			flag.usage = UNDOCUMENTED_FLAG
		}

		#partial switch specific_type_info in field.type.variant {
		case runtime.Type_Info_Map:
			flag.type_description = fmt.tprintf("<%v>=<%v>%s",
				specific_type_info.key.id,
				specific_type_info.value.id,
				", required" if flag.is_required else "")

		case runtime.Type_Info_Dynamic_Array:
			requirement_spec := describe_array_requirements(flag)

			if flag.is_variadic || flag.name == INTERNAL_VARIADIC_FLAG {
				if flag.variadic_length == 0 {
					flag.type_description = fmt.tprintf("<%v, ...>%s",
						specific_type_info.elem.id,
						requirement_spec)
				} else {
					flag.type_description = fmt.tprintf("<%v, %i at once>%s",
						specific_type_info.elem.id,
						flag.variadic_length,
						requirement_spec)
				}
			} else {
				flag.type_description = fmt.tprintf("<%v>%s", specific_type_info.elem.id,
					requirement_spec if len(requirement_spec) > 0 else ", multiple")
			}

		case:
			if flag.is_boolean {
				/*
				if flag.is_required {
					flag.type_description = ", required"
				}
				*/
			} else {
				flag.type_description = fmt.tprintf("<%v>%s",
					field.type.id,
					", required" if flag.is_required else "")
			}
		}

		if flag.name == INTERNAL_VARIADIC_FLAG {
			flag.full_length = len(flag.type_description)
		} else if flag.is_boolean {
			flag.full_length = len(flag_prefix) + len(flag.name) + len(flag.type_description)
		} else {
			flag.full_length = len(flag_prefix) + len(flag.name) + len(flag_assignment) + len(flag.type_description)
		}

		longest_flag_length = max(longest_flag_length, flag.full_length)

		append(&visible_flags, flag)
	}

	slice.sort_by_cmp(visible_flags[:], sort_flags)

	// All the flags have been figured out now.

	if len(program) > 0 {
		keep_it_short := len(visible_flags) >= ONE_LINE_FLAG_CUTOFF_COUNT

		strings.write_string(&builder, "Usage:\n\t")
		strings.write_string(&builder, program)

		for flag in visible_flags {
			if keep_it_short && !(flag.is_required || flag.is_positional || flag.name == INTERNAL_VARIADIC_FLAG) {
				continue
			}

			strings.write_byte(&builder, ' ')

			if flag.name == INTERNAL_VARIADIC_FLAG {
				strings.write_string(&builder, "...")
				continue
			}

			if !flag.is_required { strings.write_byte(&builder, '[') }
			if !flag.is_positional { strings.write_string(&builder, flag_prefix) }
			strings.write_string(&builder, flag.name)
			if !flag.is_required { strings.write_byte(&builder, ']') }
		}

		strings.write_byte(&builder, '\n')
	}

	if len(visible_flags) == 0 {
		// No visible flags. An unusual situation, but prevent any extra work.
		fmt.wprint(out, strings.to_string(builder))
		return
	}

	strings.write_string(&builder, "Flags:\n")
	
	// Divide the positional/required arguments and the non-required arguments.
	divider_index := -1
	for flag, i in visible_flags {
		if !flag.is_positional && !flag.is_required {
			divider_index = i
			break
		}
	}
	if divider_index == 0 {
		divider_index = -1
	}

	for flag, i in visible_flags {
		if i == divider_index {
			SPACING :: 2 // Number of spaces before the '|' from below.
			strings.write_byte(&builder, '\t')
			spacing := strings.repeat(" ", SPACING + longest_flag_length, context.temp_allocator)
			strings.write_string(&builder, spacing)
			strings.write_string(&builder, "|\n")
		}

		strings.write_byte(&builder, '\t')

		if flag.name == INTERNAL_VARIADIC_FLAG {
			strings.write_string(&builder, flag.type_description)
		} else {
			strings.write_string(&builder, flag_prefix)
			strings.write_string(&builder, flag.name)
			if !flag.is_boolean {
				strings.write_string(&builder, flag_assignment)
			}
			strings.write_string(&builder, flag.type_description)
		}

		if strings.contains_rune(flag.usage, '\n') {
			// Multi-line usage documentation. Let's make it look nice.
			usage_builder := strings.builder_make(context.temp_allocator)

			strings.write_byte(&usage_builder, '\n')
			iter := strings.trim_space(flag.usage)
			for line in strings.split_lines_iterator(&iter) {
				strings.write_string(&usage_builder, "\t\t")
				strings.write_string(&usage_builder, strings.trim_left_space(line))
				strings.write_byte(&usage_builder, '\n')
			}

			strings.write_string(&builder, strings.to_string(usage_builder))
		} else {
			// Single-line usage documentation.
			spacing := strings.repeat(" ",
				(longest_flag_length) - flag.full_length,
				context.temp_allocator)

			strings.write_string(&builder, spacing)
			strings.write_string(&builder, "  | ")
			strings.write_string(&builder, flag.usage)
			strings.write_byte(&builder, '\n')
		}
	}

	fmt.wprint(out, strings.to_string(builder))
}
