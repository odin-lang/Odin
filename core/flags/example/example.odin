package core_flags_example

import "base:runtime"
import "core:flags"
import "core:fmt"
import "core:net"
import "core:os"
import "core:time/datetime"


Fixed_Point1_1 :: struct {
	integer: u8,
	fractional: u8,
}

Optimization_Level :: enum {
	Slow,
	Fast,
	Warp_Speed,
	Ludicrous_Speed,
}

// It's simple but powerful.
my_custom_type_setter :: proc(
	data: rawptr,
	data_type: typeid,
	unparsed_value: string,
	args_tag: string,
) -> (
	error: string,
	handled: bool,
	alloc_error: runtime.Allocator_Error,
) {
	if data_type == Fixed_Point1_1 {
		handled = true
		ptr := cast(^Fixed_Point1_1)data

		// precision := flags.get_subtag(args_tag, "precision")

		if len(unparsed_value) == 3 {
			ptr.integer = unparsed_value[0] - '0'
			ptr.fractional = unparsed_value[2] - '0'
		} else {
			error = "Incorrect format. Must be in the form of `i.f`."
		}

		// Perform sanity checking here in the type parsing phase.
		//
		// The validation phase is flag-specific.
		if !(0 <= ptr.integer && ptr.integer < 10) || !(0 <= ptr.fractional && ptr.fractional < 10) {
			error = "Incorrect format. Must be between `0.0` and `9.9`."
		}
	}

	return
}

my_custom_flag_checker :: proc(
	model: rawptr,
	name: string,
	value: any,
	args_tag: string,
) -> (error: string) {
	if name == "iterations" {
		v := value.(int)
		if !(1 <= v && v < 5) {
			error = "Iterations only supports 1 ..< 5."
		}
	}

	return
}

Distinct_Int :: distinct int

main :: proc() {
	Options :: struct {

		file: os.Handle `args:"pos=0,required,file=r" usage:"Input file."`,
		output: os.Handle `args:"pos=1,file=cw" usage:"Output file."`,

		hub: net.Host_Or_Endpoint `usage:"Internet address to contact for updates."`,
		schedule: datetime.DateTime `usage:"Launch tasks at this time."`,

		opt: Optimization_Level `usage:"Optimization level."`,
		todo: [dynamic]string `usage:"Todo items."`,

		accuracy: Fixed_Point1_1 `args:"required" usage:"Lenience in FLOP calculations."`,
		iterations: int `usage:"Run this many times."`,

		// Note how the parser will transform this flag's name into `special-int`.
		special_int: Distinct_Int `args:"indistinct" usage:"Able to set distinct types."`,

		quat: quaternion256,

		bits: bit_set[0..<8],

		// Many different requirement styles:

		// gadgets: [dynamic]string `args:"required=1" usage:"gadgets"`,
		// widgets: [dynamic]string `args:"required=<3" usage:"widgets"`,
		// foos: [dynamic]string `args:"required=2<4"`,
		// bars: [dynamic]string `args:"required=3<4"`,
		// bots: [dynamic]string `args:"required"`,

		// (Maps) Only available in Odin style:

		// assignments: map[string]u8 `args:"name=assign" usage:"Number of jobs per worker."`,

		// (Variadic) Only available in UNIX style:

		// bots: [dynamic]string `args:"variadic=2,required"`,

		verbose: bool `usage:"Show verbose output."`,
		debug: bool `args:"hidden" usage:"print debug info"`,

		varg: [dynamic]string `usage:"Any extra arguments go here."`,
	}

	opt: Options
	style : flags.Parsing_Style = .Odin

	flags.register_type_setter(my_custom_type_setter)
	flags.register_flag_checker(my_custom_flag_checker)
	flags.parse_or_exit(&opt, os.args, style)

	fmt.printfln("%#v", opt)

	if opt.output != 0 {
		os.write_string(opt.output, "Hellope!\n")
	}
}
