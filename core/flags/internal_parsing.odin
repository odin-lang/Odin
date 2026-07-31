#+private
package flags

import "core:container/bit_array"
@require import "core:fmt"
import "core:strconv"
import "core:strings"

// Used to group state together.
Parser :: struct {
	// `fields_set` tracks which arguments have been set.
	// It uses their struct field index.
	fields_set: bit_array.Bit_Array,

	// `filled_pos` tracks which arguments have been filled into positional
	// spots, much like how `fmt` treats them.
	filled_pos: bit_array.Bit_Array,
}

parse_one_odin_arg :: proc(model: ^$T, parser: ^Parser, arg: string) -> (error: Error) {
	arg := arg

	if strings.has_prefix(arg, "-") {
		arg = arg[1:]

		flag: string
		assignment_rune: rune
		find_assignment: for r, i in arg {
			switch r {
			case ':', '=':
				assignment_rune = r
				flag = arg[:i]
				arg = arg[1 + i:]
				break find_assignment
			case:
				continue find_assignment
			}
		}

		if assignment_rune == 0 {
			if len(arg) == 0 {
				return Parse_Error {
					.No_Flag,
					"No flag was given.",
				}
			}

			// -flag
			set_odin_flag(model, parser, arg) or_return

		} else if assignment_rune == ':' {
			// -flag:option <OR> -map:key=value
			error = set_option(model, parser, flag, arg)

			if error != nil {
				// -flag:option did not work, so this may be a -map:key=value set.
				find_equals: for r, i in arg {
					if r == '=' {
						key := arg[:i]
						arg = arg[1 + i:]
						error = set_key_value(model, parser, flag, key, arg)
						break find_equals
					}
				}
			}

		} else {
			// -flag=option, alternative syntax
			set_option(model, parser, flag, arg) or_return
		}

	} else {
		// positional
		error = push_positional(model, parser, arg)
	}

	return
}

parse_one_unix_arg :: proc(model: ^$T, parser: ^Parser, arg: string) -> (
	future_args: int,
	current_flag: string,
	error: Error,
) {
	arg := arg

	if strings.has_prefix(arg, "-") {
		// -short or --flag
		arg = arg[1:]
		is_short := true

		if strings.has_prefix(arg, "-") {
			// --flag
			arg = arg[1:]
			is_short = false

			if len(arg) == 0 {
				// `--`, and only `--`.
				// Everything from now on will be treated as an argument.
				future_args = max(int)
				current_flag = INTERNAL_OVERFLOW_FLAG
				return
			}
		}

		if is_short {
			return parse_unix_short_arg(model, parser, arg)
		}

		flag: string
		find_assignment: for r, i in arg {
			if r == '=' {
				// --flag=option
				flag = arg[:i]
				arg = arg[1 + i:]
				flag = resolve_unix_flag_name(model, flag, is_short) or_return
				error = set_option(model, parser, flag, arg)
				return
			}
		}

		// --flag option, potentially
		current_flag = resolve_unix_flag_name(model, arg, is_short) or_return
		future_args = set_unix_flag(model, parser, current_flag, false) or_return

	} else {
		// positional
		error = push_positional(model, parser, arg)
	}

	return
}

// Parse one or more declared single-dash short options. Every option before
// the last must be boolean; the final option may consume a value.
parse_unix_short_arg :: proc(model: ^$T, parser: ^Parser, arg: string) -> (
	future_args: int,
	current_flag: string,
	error: Error,
) {
	shorts := arg
	option: string
	has_option: bool

	if equals := strings.index_byte(arg, '='); equals >= 0 {
		shorts = arg[:equals]
		option = arg[equals + 1:]
		has_option = true
	}

	if len(shorts) == 0 {
		current_flag = resolve_unix_flag_name(model, shorts, true) or_return
		return
	}

	for i in 0 ..< len(shorts) {
		#no_bounds_check short := shorts[i:i + 1]
		is_last := i == len(shorts) - 1
		current_flag = resolve_unix_flag_name(model, short, true) or_return

		if is_last && has_option {
			error = set_option(model, parser, current_flag, option)
			return
		}

		future_args = set_unix_flag(model, parser, current_flag, !is_last) or_return
	}

	return
}

// Resolve a declared single-dash short name to the field's canonical long name.
// Double-dash names are already canonical and pass through unchanged.
resolve_unix_flag_name :: proc(model: ^$T, name: string, is_short: bool) -> (resolved_name: string, error: Error) {
	if !is_short || name == RESERVED_HELP_FLAG_SHORT {
		return name, nil
	}

	if field, _, ok := get_field_by_short(model, name); ok {
		return get_field_name(field), nil
	}

	return "", Parse_Error {
		.Missing_Flag,
		fmt.tprintf("Unable to find any short flag named `%s`.", name),
	}
}

// Parse a number of requirements specifier.
//
// Examples:
//
//    `min`
//    `<max`
//    `min<max`
parse_requirements :: proc(str: string) -> (minimum, maximum: int, ok: bool) {
	if len(str) == 0 {
		return 1, max(int), true
	}

	if less_than := strings.index_byte(str, '<'); less_than != -1 {
		if len(str) == 1 {
			return 0, 0, false
		}

		#no_bounds_check left  := str[:less_than]
		#no_bounds_check right := str[1 + less_than:]

		if left_value, parse_ok := strconv.parse_u64_of_base(left, 10); parse_ok {
			minimum = cast(int)left_value
		} else if len(left) > 0 {
			return 0, 0, false
		}

		if right_value, parse_ok := strconv.parse_u64_of_base(right, 10); parse_ok {
			maximum = cast(int)right_value
		} else if len(right) > 0 {
			return 0, 0, false
		} else {
			maximum = max(int)
		}
	} else {
		if value, parse_ok := strconv.parse_u64_of_base(str, 10); parse_ok {
			minimum = cast(int)value
			maximum = max(int)
		} else {
			return 0, 0, false
		}
	}

	ok = true
	return
}
