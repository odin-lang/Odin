package flags

import "core:strings"
_ :: strings

@(private)
parse_one_arg :: proc(data: ^$T, arg: string, pos: ^int, set_args: ^[dynamic]string) -> (err: Error) {
	arg := arg

	if strings.has_prefix(arg, "-") {
		arg = arg[1:]

		if colon := strings.index_byte(arg, ':'); colon != -1 {
			flag := arg[:colon]
			arg = arg[1 + colon:]

			if equals := strings.index_byte(arg, '='); equals != -1 {
				// -map:key=value
				key := arg[:equals]
				value := arg[1 + equals:]
				set_key_value(data, flag, key, value) or_return
				append(set_args, flag)
			} else {
				// -flag:option
				set_option(data, flag, arg) or_return
				append(set_args, flag)
			}

		} else if equals := strings.index_byte(arg, '='); equals != -1 {
			// -flag=option, alternative syntax
			flag := arg[:equals]
			arg = arg[1 + equals:]

			set_option(data, flag, arg) or_return
			append(set_args, flag)
		} else {
			// -flag
			set_flag(data, arg) or_return
			append(set_args, arg)
		}

	} else {
		// positional
		err = add_positional(data, pos^, arg)
		pos^ += 1
	}

	return
}

// Parse a slice of command-line arguments into an annotated struct.
//
// If `validate_args` is set, an error will be returned if all required
// arguments are not set. This step is only completed if there were no errors
// from parsing.
//
// If `strict` is set, an error will cause parsing to stop and the procedure
// will return with the message. Otherwise, parsing will continue and only the
// last error will be returned.
parse :: proc(data: ^$T, args: []string, validate_args: bool = true, strict: bool = true) -> (err: Error) {
	// For checking required arguments.
	set_args: [dynamic]string
	defer delete(set_args)

	// Positional argument tracker.
	pos := 0

	if strict {
		for arg in args {
			parse_one_arg(data, arg, &pos, &set_args) or_return
		}
	} else {
		for arg in args {
			this_error := parse_one_arg(data, arg, &pos, &set_args)
			if this_error != nil {
				err = this_error
			}
		}
	}

	if err == nil && validate_args {
		return validate(data, pos, set_args[:])
	}

	return err
}
