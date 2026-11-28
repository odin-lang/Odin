package test_core_flags

import "base:runtime"
import "core:flags"
import "core:mem"
import "core:testing"

@(private="file")
Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
	err:     runtime.Allocator_Error,
}

@(private="file")
failing_allocator_proc :: proc(
	data: rawptr, mode: runtime.Allocator_Mode,
	size, alignment: int, old_memory: rawptr, old_size: int,
	loc := #caller_location,
) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.count == fa.fail_at {
			fa.count += 1
			if fa.err != nil {
				return nil, fa.err
			}
			return nil, .Out_Of_Memory
		}
		fa.count += 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
failing_allocator :: proc(fa: ^Failing_Allocator) -> runtime.Allocator {
	return {procedure = failing_allocator_proc, data = fa}
}

@(private="file")
Leak_Model :: struct {
	m: map[cstring]cstring,
	d: [dynamic]cstring,
	c: cstring,
	n: map[string]int,
}

@(private="file")
leak_model_destroy :: proc(s: ^Leak_Model, allocator: runtime.Allocator) {
	for k, v in s.m {
		delete(k, allocator)
		delete(v, allocator)
	}
	delete(s.m)
	for v in s.d {
		delete(v, allocator)
	}
	delete(s.d)
	delete(s.c, allocator)
	delete(s.n)
	s^ = {}
}

@(private="file")
track_init :: proc(track: ^mem.Tracking_Allocator) {
	mem.tracking_allocator_init(track, context.allocator)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
}

@(test)
test_map_cstring_keys_are_owned :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	track_init(&track)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	s: Leak_Model
	args := [?]string{"-m:a=1", "-m:b=2", "-m:a=3"}
	result := flags.parse(&s, args[:], allocator = allocator)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.m), 2)
	testing.expect_value(t, s.m["a"], "3")
	testing.expect_value(t, s.m["b"], "2")

	leak_model_destroy(&s, allocator)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_cstring_default_is_not_freed :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	track_init(&track)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	s := Leak_Model{c = "default"}
	args := [?]string{"-c:one", "-c:two"}
	result := flags.parse(&s, args[:], allocator = allocator)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.c, "two")

	leak_model_destroy(&s, allocator)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_map_value_error_is_not_inserted :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	track_init(&track)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	s: Leak_Model
	args := [?]string{"-n:a=notanumber"}
	result := flags.parse(&s, args[:], allocator = allocator)
	_, is_parse_error := result.(flags.Parse_Error)
	testing.expect(t, is_parse_error)
	testing.expect_value(t, len(s.n), 0)

	leak_model_destroy(&s, allocator)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_parse_oom :: proc(t: ^testing.T) {
	args := [?]string{"-m:a=1", "-m:b=2", "-m:a=3", "-d:x", "-d:y", "-c:z", "-c:w", "-n:k=4", "-n:k=5"}

	total: int
	{
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		allocator := failing_allocator(&fa)

		s: Leak_Model
		result := flags.parse(&s, args[:], allocator = allocator)
		total = fa.count
		testing.expect_value(t, result, nil)
		testing.expect_value(t, s.m["a"], "3")
		testing.expect_value(t, len(s.d), 2)
		testing.expect_value(t, s.c, "w")
		testing.expect_value(t, s.n["k"], 5)
		leak_model_destroy(&s, allocator)
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
	}
	testing.expect(t, total >= 8)

	for k in 0..<total {
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		allocator := failing_allocator(&fa)

		s: Leak_Model
		result := flags.parse(&s, args[:], allocator = allocator)
		parse_err, is_parse_err := result.(flags.Parse_Error)
		testing.expectf(t, is_parse_err && parse_err.reason == runtime.Allocator_Error.Out_Of_Memory, "k=%d of %d: %v", k, total, result)
		leak_model_destroy(&s, allocator)
		testing.expectf(t, len(track.allocation_map) == 0, "k=%d of %d: %d leaked", k, total, len(track.allocation_map))
		testing.expectf(t, len(track.bad_free_array) == 0, "k=%d of %d: %d bad frees", k, total, len(track.bad_free_array))
	}
}

Leak_CString :: distinct cstring
Leak_Setter_CString :: distinct cstring

leak_setter_literal: cstring = "lit"

@(private="file")
Distinct_Model :: struct {
	c: Leak_CString        `args:"indistinct"`,
	s: Leak_Setter_CString `args:"indistinct"`,
	d: [dynamic]Leak_CString `args:"indistinct"`,
	m: map[string]Leak_CString `args:"indistinct"`,
}

@(private="file")
distinct_model_destroy :: proc(s: ^Distinct_Model, allocator: runtime.Allocator) {
	delete(cstring(s.c), allocator)
	if rawptr(s.s) != rawptr(leak_setter_literal) {
		delete(cstring(s.s), allocator)
	}
	for v in s.d {
		delete(cstring(v), allocator)
	}
	delete(s.d)
	for _, v in s.m {
		delete(cstring(v), allocator)
	}
	delete(s.m)
	s^ = {}
}

@(private="file")
DISTINCT_ARGS := [?]string{"-c:one", "-c:two", "-s:x", "-s:lit", "-s:y", "-s:lit", "-s:z", "-d:a", "-d:b", "-m:k=1", "-m:k=2", "-m:j=3"}

@(private="file")
expect_distinct_model :: proc(t: ^testing.T, s: ^Distinct_Model, loc := #caller_location) {
	testing.expect_value(t, string(s.c), "two", loc)
	testing.expect_value(t, string(s.s), "z", loc)
	if testing.expect_value(t, len(s.d), 2, loc) {
		testing.expect_value(t, string(s.d[1]), "b", loc)
	}
	testing.expect_value(t, len(s.m), 2, loc)
	testing.expect_value(t, string(s.m["k"]), "2", loc)
}

@(test)
test_distinct_cstring_values_are_owned :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	track_init(&track)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	s: Distinct_Model
	result := flags.parse(&s, DISTINCT_ARGS[:], allocator = allocator)
	testing.expect_value(t, result, nil)
	expect_distinct_model(t, &s)
	distinct_model_destroy(&s, allocator)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)

	lit_last := [?]string{"-s:x", "-s:lit"}
	result = flags.parse(&s, lit_last[:], allocator = allocator)
	testing.expect_value(t, result, nil)
	testing.expect(t, rawptr(s.s) == rawptr(leak_setter_literal))
	distinct_model_destroy(&s, allocator)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_distinct_cstring_oom :: proc(t: ^testing.T) {
	total: int
	{
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		allocator := failing_allocator(&fa)

		s: Distinct_Model
		result := flags.parse(&s, DISTINCT_ARGS[:], allocator = allocator)
		total = fa.count
		testing.expect_value(t, result, nil)
		expect_distinct_model(t, &s)
		distinct_model_destroy(&s, allocator)
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
	}
	testing.expect(t, total >= 10)

	for want in ([]runtime.Allocator_Error{.Out_Of_Memory, .Invalid_Argument}) {
		for k in 0..<total {
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k, err = want}
			allocator := failing_allocator(&fa)

			s: Distinct_Model
			result := flags.parse(&s, DISTINCT_ARGS[:], allocator = allocator)
			parse_err, is_parse_err := result.(flags.Parse_Error)
			reason_ok := parse_err.reason == want || parse_err.reason == runtime.Allocator_Error.Out_Of_Memory
			testing.expectf(t, is_parse_err && reason_ok, "%v k=%d of %d: %v", want, k, total, result)
			distinct_model_destroy(&s, allocator)
			testing.expectf(t, len(track.allocation_map) == 0, "%v k=%d of %d: %d leaked", want, k, total, len(track.allocation_map))
			testing.expectf(t, len(track.bad_free_array) == 0, "%v k=%d of %d: %d bad frees", want, k, total, len(track.bad_free_array))
		}
	}
}

@(private="file")
Bit_Model :: struct {
	a:        int `args:"pos=0"`,
	b:        int `args:"pos=70"`,
	f:        bool,
	o:        int,
	overflow: [dynamic]string,
}

@(test)
test_parse_bit_array_oom :: proc(t: ^testing.T) {
	odin_args := [?]string{"-f", "-o:3", "7", "x", "y", "-b:9"}
	unix_args := [?]string{"--f", "--o", "3", "7", "x", "--b", "9", "y"}

	for style in flags.Parsing_Style {
		args := odin_args[:] if style == .Odin else unix_args[:]

		total: int
		{
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
			allocator := failing_allocator(&fa)

			s: Bit_Model
			result := flags.parse(&s, args, style, allocator = allocator)
			total = fa.count
			testing.expect_value(t, result, nil)
			testing.expect_value(t, s.a, 7)
			testing.expect_value(t, s.b, 9)
			testing.expect_value(t, s.f, true)
			testing.expect_value(t, s.o, 3)
			testing.expect_value(t, len(s.overflow), 2)
			delete(s.overflow)
			testing.expect_value(t, len(track.allocation_map), 0)
		}
		testing.expectf(t, total >= 4, "%v: %d allocations", style, total)

		for k in 0..<total {
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
			allocator := failing_allocator(&fa)

			s: Bit_Model
			result := flags.parse(&s, args, style, allocator = allocator)
			parse_err, is_parse_err := result.(flags.Parse_Error)
			testing.expectf(t, is_parse_err && parse_err.reason == runtime.Allocator_Error.Out_Of_Memory, "%v k=%d of %d: %v", style, k, total, result)
			delete(s.overflow)
			testing.expectf(t, len(track.allocation_map) == 0, "%v k=%d of %d: %d leaked", style, k, total, len(track.allocation_map))
			testing.expectf(t, len(track.bad_free_array) == 0, "%v k=%d of %d: %d bad frees", style, k, total, len(track.bad_free_array))
		}
	}
}

@(test)
test_parse_dynamic_array_allocator_error :: proc(t: ^testing.T) {
	args := [?]string{"-c:z", "-d:x", "-d:y", "-d:z"}

	prefix, total: int
	for n in ([]int{1, len(args)}) {
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		allocator := failing_allocator(&fa)

		s: Leak_Model
		result := flags.parse(&s, args[:n], allocator = allocator)
		prefix, total = total, fa.count
		testing.expect_value(t, result, nil)
		testing.expect_value(t, len(s.d), n - 1)
		leak_model_destroy(&s, allocator)
		testing.expect_value(t, len(track.allocation_map), 0)
	}
	testing.expect(t, total >= prefix + 9)

	for want in ([]runtime.Allocator_Error{.Out_Of_Memory, .Invalid_Argument}) {
		for k in prefix..<total {
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k, err = want}
			allocator := failing_allocator(&fa)

			s: Leak_Model
			result := flags.parse(&s, args[:], allocator = allocator)
			parse_err, is_parse_err := result.(flags.Parse_Error)
			testing.expectf(t, is_parse_err && parse_err.reason == want, "%v k=%d of %d: %v", want, k, total, result)
			leak_model_destroy(&s, allocator)
			testing.expectf(t, len(track.allocation_map) == 0, "%v k=%d of %d: %d leaked", want, k, total, len(track.allocation_map))
			testing.expectf(t, len(track.bad_free_array) == 0, "%v k=%d of %d: %d bad frees", want, k, total, len(track.bad_free_array))
		}
	}
}
