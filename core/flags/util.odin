package flags

import          "core:fmt"
@require import "core:os"
@require import "core:path/filepath"
import          "core:strings"

/*
Parse any arguments into an annotated struct or exit if there was an error.

*Allocates Using Provided Allocator*

This is a convenience wrapper over `parse` and `print_errors`.

Inputs:
- model: A pointer to an annotated struct.
- program_args: A slice of strings, usually `os.args`.
- style: The argument parsing style.
- color: Whether to colorize output; a tagged color field in the model overrides this value.
- allocator: (default: context.allocator)
- loc: The caller location for debugging purposes (default: #caller_location)
*/
@(optimization_mode="favor_size")
parse_or_exit :: proc(
	model: ^$T,
	program_args: []string,
	style: Parsing_Style = .Odin,
	color: Color_Mode = .Never,
	allocator := context.allocator,
	loc := #caller_location,
) {
	assert(len(program_args) > 0, "Program arguments slice is empty.", loc)

	program := filepath.base(program_args[0])
	args: []string

	if len(program_args) > 1 {
		args = program_args[1:]
	}

	effective_color := resolve_color_mode(T, args, style, color)
	error := parse(model, args, style, true, true, allocator, loc)
	if error != nil {
		stderr := os.to_stream(os.stderr)

		if len(args) == 0 {
			// No arguments entered, and there was an error; show the usage,
			// specifically on STDERR.
			write_usage(stderr, T, program, style, effective_color)
			fmt.wprintln(stderr)
		}

		print_errors(T, error, program, style, effective_color)

		_, was_help_request := error.(Help_Request)
		os.exit(0 if was_help_request else 1)
	}
}
/*
Print out any errors that may have resulted from parsing.

All error messages print to STDERR, while usage goes to STDOUT, if requested.

Inputs:
- data_type: The typeid of the data structure to describe, if usage is requested.
- error: The error returned from `parse`.
- style: The argument parsing style, required to show flags in the proper style, when usage is shown.
- color: Whether to colorize output.
*/
@(optimization_mode="favor_size")
print_errors :: proc(
	data_type: typeid,
	error: Error,
	program: string,
	style: Parsing_Style = .Odin,
	color: Color_Mode = .Never,
) {
	stderr := os.to_stream(os.stderr)
	stdout := os.to_stream(os.stdout)

	switch specific_error in error {
	case Parse_Error:
		stderr_palette := make_color_palette(should_colorize(color, stderr))
		fmt.wprintfln(stderr, "%s[%T.%v]%s %s",
			stderr_palette.error, specific_error, specific_error.reason, stderr_palette.reset, specific_error.message)
	case Open_File_Error:
		stderr_palette := make_color_palette(should_colorize(color, stderr))
		if os.exists(specific_error.filename) {
			flags: string
			if specific_error.flags == {.Read} {
				flags = "read-only"
			} else if specific_error.flags == {.Write} {
				flags = "write-only"
			} else if specific_error.flags == {.Read, .Write} {
				flags = "read/write"
			}

			if flags != "" {
				fmt.wprintfln(stderr, "%s[%T#%i]%s Unable to open %q with perms 0o%o as %s",
					stderr_palette.error,
					specific_error,
					specific_error.errno,
					stderr_palette.reset,
					specific_error.filename,
					u16(transmute(u32)specific_error.perms),
					flags)
			} else {
				fmt.wprintfln(stderr, "%s[%T#%i]%s Unable to open %q with perms 0o%o and flags %v",
					stderr_palette.error,
					specific_error,
					specific_error.errno,
					stderr_palette.reset,
					specific_error.filename,
					u16(transmute(u32)specific_error.perms),
					specific_error.flags)
			}
		} else {
			fmt.wprintfln(stderr, "%s[%T#%i]%s Unable to open %q. File not found",
				stderr_palette.error,
				specific_error,
				specific_error.errno,
				stderr_palette.reset,
				specific_error.filename)
		}
	case Validation_Error:
		stderr_palette := make_color_palette(should_colorize(color, stderr))
		fmt.wprintfln(stderr, "%s[%T]%s %s",
			stderr_palette.error, specific_error, stderr_palette.reset, specific_error.message)
	case Help_Request:
		write_usage(stdout, data_type, program, style, color)
	}
}
/*
Get the value for a subtag.

This is useful if you need to parse through the `args` tag for a struct field
on a custom type setter or custom flag checker.

Example:

	import "core:flags"
	import "core:fmt"

	get_subtag_example :: proc() {
		args_tag := "precision=3,signed"

		precision, has_precision := flags.get_subtag(args_tag, "precision")
		signed, is_signed := flags.get_subtag(args_tag, "signed")

		fmt.printfln("precision = %q, %t", precision, has_precision)
		fmt.printfln("signed = %q, %t", signed, is_signed)
	}

Output:

	precision = "3", true
	signed = "", true

*/
get_subtag :: proc(tag, id: string) -> (value: string, ok: bool) {
	// This proc was initially private in `internal_rtti.odin`, but given how
	// useful it would be to custom type setters and flag checkers, it lives
	// here now.

	tag := tag

	for subtag in strings.split_iterator(&tag, ",") {
		if equals := strings.index_byte(subtag, '='); equals != -1 && id == subtag[:equals] {
			return subtag[1 + equals:], true
		} else if id == subtag {
			return "", true
		}
	}

	return
}
