package flags

@require import "core:container/bit_array"
@require import "core:fmt"

Parsing_Style :: enum {
	// Odin-style: `-flag`, `-flag:option`, `-map:key=value`
	Odin,
	// UNIX-style: `-flag` or `--flag`, `--flag=argument`, `--flag argument repeating-argument`
	Unix,
}

/*
Parse a slice of command-line arguments into an annotated struct.

*Allocates Using Provided Allocator*

By default, this proc will only allocate memory outside of its lifetime if it
has to append to a dynamic array, set a map value, or set a cstring.

The program is expected to free any allocations on `model` as a result of parsing.

Inputs:
- model: A pointer to an annotated struct with flag definitions.
- args: A slice of strings, usually `os.args[1:]`.
- style: The argument parsing style.
- validate_args: If `true`, will ensure that all required arguments are set if no errors occurred.
- strict: If `true`, will return on first error. Otherwise, parsing continues.
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)

Returns:
- error: A union of errors; parsing, file open, a help request, or validation.
*/
@(optimization_mode="size")
parse :: proc(
	model: ^$T,
	args: []string,
	style: Parsing_Style = .Odin,
	validate_args: bool = true,
	strict: bool = true,
	allocator := context.allocator,
	loc := #caller_location,
) -> (error: Error) {
	context.allocator = allocator
	validate_structure(model^, style, loc)

	parser: Parser
	defer {
		bit_array.destroy(&parser.filled_pos)
		bit_array.destroy(&parser.fields_set)
	}

	switch style {
	case .Odin:
		for arg in args {
			error = parse_one_odin_arg(model, &parser, arg)
			if strict && error != nil {
				return
			}
		}

	case .Unix:
		// Support for `-flag argument (repeating-argument ...)`
		future_args: int
		current_flag: string

		for i := 0; i < len(args); i += 1 {
			#no_bounds_check arg := args[i]
			future_args, current_flag, error = parse_one_unix_arg(model, &parser, arg)
			if strict && error != nil {
				return
			}

			for starting_future_args := future_args; future_args > 0; future_args -= 1 {
				i += 1
				if i == len(args) {
					if future_args == starting_future_args {
						return Parse_Error {
							.No_Value,
							fmt.tprintf("Expected a value for `%s` but none was given.", current_flag),
						}
					}
					break
				}
				#no_bounds_check arg = args[i]

				error = set_option(model, &parser, current_flag, arg)
				if strict && error != nil {
					return
				}
			}
		}
	}

	if error == nil && validate_args {
		return validate_arguments(model, &parser)
	}

	return
}
