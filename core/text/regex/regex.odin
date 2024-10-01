package regex

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "core:text/regex/common"
import "core:text/regex/compiler"
import "core:text/regex/optimizer"
import "core:text/regex/parser"
import "core:text/regex/virtual_machine"

Flag           :: common.Flag
Flags          :: common.Flags
Parser_Error   :: parser.Error
Compiler_Error :: compiler.Error

Creation_Error :: enum {
	None,
	// A `\` was supplied as the delimiter to `create_by_user`.
	Bad_Delimiter,
	// A pair of delimiters for `create_by_user` was not found.
	Expected_Delimiter,
	// An unknown letter was supplied to `create_by_user` after the last delimiter.
	Unknown_Flag,
}

Error :: union #shared_nil {
	// An error that can occur in the pattern parsing phase.
	//
	// Most of these are regular expression syntax errors and are either
	// context-dependent as to what they mean or have self-explanatory names.
	Parser_Error,
	// An error that can occur in the pattern compiling phase.
	//
	// Of the two that can be returned, they have to do with exceeding the
	// limitations of the Virtual Machine.
	Compiler_Error,
	// An error that occurs only for `create_by_user`.
	Creation_Error,
}

/*
This struct corresponds to a set of string captures from a RegEx match.

`pos` will contain the start and end positions for each string in `groups`,
such that `str[pos[0][0]:pos[0][1]] == groups[0]`.
*/
Capture :: struct {
	pos: [][2]int,
	groups: []string,
}

/*
A compiled Regular Expression value, to be used with the `match_*` procedures.
*/
Regular_Expression :: struct {
	flags: Flags `fmt:"-"`,
	class_data: []virtual_machine.Rune_Class_Data `fmt:"-"`,
	program: []virtual_machine.Opcode `fmt:"-"`,
}


/*
Create a regular expression from a string pattern and a set of flags.

*Allocates Using Provided Allocators*

Inputs:
- pattern: The pattern to compile.
- flags: A `bit_set` of RegEx flags.
- permanent_allocator: The allocator to use for the final regular expression. (default: context.allocator)
- temporary_allocator: The allocator to use for the intermediate compilation stages. (default: context.temp_allocator)

Returns:
- result: The regular expression.
- err: An error, if one occurred.
*/
@require_results
create :: proc(
	pattern: string,
	flags: Flags = {},
	permanent_allocator := context.allocator,
	temporary_allocator := context.temp_allocator,
) -> (result: Regular_Expression, err: Error) {

	// For the sake of speed and simplicity, we first run all the intermediate
	// processes such as parsing and compilation through the temporary
	// allocator.
	program: [dynamic]virtual_machine.Opcode = ---
	class_data: [dynamic]parser.Rune_Class_Data = ---
	{
		context.allocator = temporary_allocator

		ast := parser.parse(pattern, flags) or_return

		if .No_Optimization not_in flags {
			ast, _ = optimizer.optimize(ast, flags)
		}

		program, class_data = compiler.compile(ast, flags) or_return
	}

	// When that's successful, re-allocate all at once with the permanent
	// allocator so everything can be tightly packed.
	context.allocator = permanent_allocator

	result.flags = flags

	if len(class_data) > 0 {
		result.class_data = make([]virtual_machine.Rune_Class_Data, len(class_data))
	}
	for data, i in class_data {
		if len(data.runes) > 0 {
			result.class_data[i].runes = make([]rune, len(data.runes))
			copy(result.class_data[i].runes, data.runes[:])
		}
		if len(data.ranges) > 0 {
			result.class_data[i].ranges = make([]virtual_machine.Rune_Class_Range, len(data.ranges))
			copy(result.class_data[i].ranges, data.ranges[:])
		}
	}

	result.program = make([]virtual_machine.Opcode, len(program))
	copy(result.program, program[:])

	return
}

/*
Create a regular expression from a delimited string pattern, such as one
provided by users of a program or those found in a configuration file.

They are in the form of:

	[DELIMITER] [regular expression] [DELIMITER] [flags]

For example, the following strings are valid:

	/hellope/i
	#hellope#i
	•hellope•i
	つhellopeつi

The delimiter is determined by the very first rune in the string.
The only restriction is that the delimiter cannot be `\`, as that rune is used
to escape the delimiter if found in the middle of the string.

All runes after the closing delimiter will be parsed as flags:

- 'g': Global
- 'm': Multiline
- 'i': Case_Insensitive
- 'x': Ignore_Whitespace
- 'u': Unicode
- 'n': No_Capture
- '-': No_Optimization


*Allocates Using Provided Allocators*

Inputs:
- pattern: The delimited pattern with optional flags to compile.
- str: The string to match against.
- permanent_allocator: The allocator to use for the final regular expression. (default: context.allocator)
- temporary_allocator: The allocator to use for the intermediate compilation stages. (default: context.temp_allocator)

Returns:
- result: The regular expression.
- err: An error, if one occurred.
*/
@require_results
create_by_user :: proc(
	pattern: string,
	permanent_allocator := context.allocator,
	temporary_allocator := context.temp_allocator,
) -> (result: Regular_Expression, err: Error) {

	if len(pattern) == 0 {
		err = .Expected_Delimiter
		return
	}

	delimiter: rune
	start := -1
	end := -1

	flags: Flags

	escaping: bool
	parse_loop: for r, i in pattern {
		if delimiter == 0 {
			if r == '\\' {
				err = .Bad_Delimiter
				return
			}
			delimiter = r
			continue parse_loop
		}

		if start == -1 {
			start = i
		}

		if escaping {
			escaping = false
			continue parse_loop
		}

		switch r {
		case '\\':
			escaping = true
		case delimiter:
			end = i
			break parse_loop
		}
	}

	if end == -1 {
		err = .Expected_Delimiter
		return
	}

	// `start` is also the size of the delimiter, which is why it's being added
	// to `end` here.
	for r in pattern[start + end:] {
		switch r {
		case 'g': flags += { .Global }
		case 'm': flags += { .Multiline }
		case 'i': flags += { .Case_Insensitive }
		case 'x': flags += { .Ignore_Whitespace }
		case 'u': flags += { .Unicode }
		case 'n': flags += { .No_Capture }
		case '-': flags += { .No_Optimization }
		case:
			err = .Unknown_Flag
			return
		}
	}

	return create(pattern[start:end], flags, permanent_allocator, temporary_allocator)
}

/*
Match a regular expression against a string and allocate the results into the
returned `capture` structure.

The resulting capture strings will be slices to the string `str`, not wholly
copied strings, so they won't need to be individually deleted.

*Allocates Using Provided Allocators*

Inputs:
- regex: The regular expression.
- str: The string to match against.
- permanent_allocator: The allocator to use for the capture results. (default: context.allocator)
- temporary_allocator: The allocator to use for the virtual machine. (default: context.temp_allocator)

Returns:
- capture: The capture groups found in the string.
- success: True if the regex matched the string.
*/
@require_results
match_and_allocate_capture :: proc(
	regex: Regular_Expression,
	str: string,
	permanent_allocator := context.allocator,
	temporary_allocator := context.temp_allocator,
) -> (capture: Capture, success: bool) {

	saved: ^[2 * common.MAX_CAPTURE_GROUPS]int

	{
		context.allocator = temporary_allocator

		vm := virtual_machine.create(regex.program, str)
		vm.class_data = regex.class_data

		if .Unicode in regex.flags {
			saved, success = virtual_machine.run(&vm, true)
		} else {
			saved, success = virtual_machine.run(&vm, false)
		}
	}

	if saved != nil {
		context.allocator = permanent_allocator

		num_groups := 0
		#no_bounds_check for i := 0; i < len(saved); i += 2 {
			a, b := saved[i], saved[i + 1]
			if a == -1 || b == -1 {
				continue
			}
			num_groups += 1
		}

		if num_groups > 0 {
			capture.groups = make([]string, num_groups)
			capture.pos = make([][2]int, num_groups)
			n := 0

			#no_bounds_check for i := 0; i < len(saved); i += 2 {
				a, b := saved[i], saved[i + 1]
				if a == -1 || b == -1 {
					continue
				}

				capture.groups[n] = str[a:b]
				capture.pos[n] = {a, b}
				n += 1
			}
		}
	}

	return
}

/*
Match a regular expression against a string and save the capture results into
the provided `capture` structure.

The resulting capture strings will be slices to the string `str`, not wholly
copied strings, so they won't need to be individually deleted.

*Allocates Using Provided Allocator*

Inputs:
- regex: The regular expression.
- str: The string to match against.
- capture: A pointer to a Capture structure with `groups` and `pos` already allocated.
- temporary_allocator: The allocator to use for the virtual machine. (default: context.temp_allocator)

Returns:
- num_groups: The number of capture groups set into `capture`.
- success: True if the regex matched the string.
*/
@require_results
match_with_preallocated_capture :: proc(
	regex: Regular_Expression,
	str: string,
	capture: ^Capture,
	temporary_allocator := context.temp_allocator,
) -> (num_groups: int, success: bool) {

	assert(capture != nil, "Pre-allocated RegEx capture must not be nil.")
	assert(len(capture.groups) >= common.MAX_CAPTURE_GROUPS,
		"Pre-allocated RegEx capture `groups` must be at least 10 elements long.")
	assert(len(capture.pos) >= common.MAX_CAPTURE_GROUPS,
		"Pre-allocated RegEx capture `pos` must be at least 10 elements long.")

	saved: ^[2 * common.MAX_CAPTURE_GROUPS]int

	{
		context.allocator = temporary_allocator

		vm := virtual_machine.create(regex.program, str)
		vm.class_data = regex.class_data

		if .Unicode in regex.flags {
			saved, success = virtual_machine.run(&vm, true)
		} else {
			saved, success = virtual_machine.run(&vm, false)
		}
	}

	if saved != nil {
		n := 0

		#no_bounds_check for i := 0; i < len(saved); i += 2 {
			a, b := saved[i], saved[i + 1]
			if a == -1 || b == -1 {
				continue
			}

			capture.groups[n] = str[a:b]
			capture.pos[n] = {a, b}
			n += 1
		}
	}

	return
}

match :: proc {
	match_and_allocate_capture,
	match_with_preallocated_capture,
}

/*
Allocate a `Capture` in advance for use with `match`. This can save some time
if you plan on performing several matches at once and only need the results
between matches.

Inputs:
- allocator: (default: context.allocator)

Returns:
- result: The `Capture` with the maximum number of groups allocated.
*/
@require_results
preallocate_capture :: proc(allocator := context.allocator) -> (result: Capture) {
	context.allocator = allocator
	result.pos = make([][2]int, common.MAX_CAPTURE_GROUPS)
	result.groups = make([]string, common.MAX_CAPTURE_GROUPS)
	return
}

/*
Free all data allocated by the `create*` procedures.

*Frees Using Provided Allocator*

Inputs:
- regex: A regular expression.
- allocator: (default: context.allocator)
*/
destroy_regex :: proc(regex: Regular_Expression, allocator := context.allocator) {
	context.allocator = allocator
	delete(regex.program)
	for data in regex.class_data {
		delete(data.runes)
		delete(data.ranges)
	}
	delete(regex.class_data)
}

/*
Free all data allocated by the `match_and_allocate_capture` procedure.

*Frees Using Provided Allocator*

Inputs:
- capture: A Capture.
- allocator: (default: context.allocator)
*/
destroy_capture :: proc(capture: Capture, allocator := context.allocator) {
	context.allocator = allocator
	delete(capture.groups)
	delete(capture.pos)
}

destroy :: proc {
	destroy_regex,
	destroy_capture,
}
