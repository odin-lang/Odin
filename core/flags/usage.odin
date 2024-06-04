package flags

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:reflect"
import "core:slice"
import "core:strconv"
import "core:strings"

_, _, _, _, _, _, _, _ :: runtime, fmt, io, os, reflect, slice, strconv, strings

// Write out the documentation for the command-line arguments.
write_usage :: proc(out: io.Writer, data: ^$T, program: string = "") {
	Flag :: struct {
		name:           string,
		usage:          string,
		name_with_type: string,
		pos:            int,
		is_positional:  bool,
		is_required:    bool,
		is_boolean:     bool,
		is_hidden:      bool,
	}

	sort_flags :: proc(a, b: Flag) -> slice.Ordering {
		if a.is_positional && b.is_positional {
			return slice.cmp(a.pos, b.pos)
		}

		if a.is_required && !b.is_required {
			return .Less
		} else if !a.is_required && b.is_required {
			return .Greater
		}

		if a.is_positional && !b.is_positional {
			return .Less
		} else if b.is_positional && !a.is_positional {
			return .Greater
		}

		return slice.cmp(a.name, b.name)
	}

	flags: [dynamic]Flag
	defer delete(flags)

	longest_flag_length: int

	for field in reflect.struct_fields_zipped(T) {
		flag: Flag

		flag.name = get_field_name(field)
		#partial switch t in field.type.variant {
		case runtime.Type_Info_Map:
			flag.name_with_type = fmt.tprintf("%s:<%v>=<%v>", flag.name, t.key.id, t.value.id)
		case runtime.Type_Info_Dynamic_Array:
			flag.name_with_type = fmt.tprintf("%s:<%v, ...>", flag.name, t.elem.id)
		case:
			flag.name_with_type = fmt.tprintf("%s:<%v>", flag.name, field.type.id)
		}

		if usage, ok := reflect.struct_tag_lookup(field.tag, TAG_USAGE); ok {
			flag.usage = usage
		} else {
			flag.usage = UNDOCUMENTED_FLAG
		}

		if args_tag, ok := reflect.struct_tag_lookup(field.tag, TAG_ARGS); ok {
			if pos_str, is_pos := get_struct_subtag(args_tag, SUBTAG_POS); is_pos {
				flag.is_positional = true
				if pos, ok := strconv.parse_int(pos_str); ok && pos >= 0 {
					flag.pos = pos
				} else {
					fmt.panicf("%v has incorrect pos subtag specifier `%s`", typeid_of(T), pos_str)
				}
			}
			if _, is_required := get_struct_subtag(args_tag, SUBTAG_REQUIRED); is_required {
				flag.is_required = true
			}
			if reflect.type_kind(field.type.id) == .Boolean {
				flag.is_boolean = true
			}
			if _, is_hidden := get_struct_subtag(args_tag, SUBTAG_HIDDEN); is_hidden {
				flag.is_hidden = true
			}
		}

		if !flag.is_hidden {
			longest_flag_length = max(longest_flag_length, len(flag.name_with_type))
		}

		append(&flags, flag)
	}

	slice.sort_by_cmp(flags[:], sort_flags)

	if len(program) > 0 {
		fmt.wprintf(out, "Usage:\n\t%s", program)

		for flag in flags {
			if flag.is_hidden {
				continue
			}

			io.write_byte(out, ' ')

			if flag.name == SUBTAG_POS {
				io.write_string(out, "...")
				continue
			}

			if !flag.is_required   { io.write_byte(out, '[') }
			if !flag.is_positional { io.write_byte(out, '-') }
			io.write_string(out, flag.name)
			if !flag.is_required   { io.write_byte(out, ']') }
		}
		io.write_byte(out, '\n')
	}

	fmt.wprintln(out, "Flags:")
	for flag in flags {
		if flag.is_hidden {
			continue
		}

		spacing := strings.repeat(" ",
			(MINIMUM_SPACING + longest_flag_length) - len(flag.name_with_type),
			context.temp_allocator)
		fmt.wprintf(out, "\t-%s%s%s\n", flag.name_with_type, spacing, flag.usage)
	}
}

// Print out the documentation for the command-line arguments.
print_usage :: proc(data: ^$T, program: string = "") {
	write_usage(os.stream_from_handle(os.stdout), data, program)
}
