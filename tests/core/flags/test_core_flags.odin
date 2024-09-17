package test_core_flags

import "base:runtime"
import "core:bytes"
import "core:flags"
import "core:fmt"
@require import "core:log"
import "core:math"
@require import "core:net"
import "core:os"
import "core:strings"
import "core:testing"
import "core:time/datetime"

Custom_Data :: struct {
	a: int,
}

@(init)
init_custom_type_setter :: proc() {
	// NOTE: This is done here so it can be out of the flow of the
	// multi-threaded test runner, to prevent any data races that could be
	// reported by using `-sanitize:thread`.
	//
	// Do mind that this means every test here acknowledges the `Custom_Data` type.
	flags.register_type_setter(proc (data: rawptr, data_type: typeid, _, _: string) -> (string, bool, runtime.Allocator_Error) {
		if data_type == Custom_Data {
			(cast(^Custom_Data)data).a = 32
			return "", true, nil
		}
		return "", false, nil
	})
}

@(test)
test_no_args :: proc(t: ^testing.T) {
	S :: struct {
		a: string,
	}
	s: S
	args: []string
	result := flags.parse(&s, args)
	testing.expect_value(t, result, nil)
}

@(test)
test_two_flags :: proc(t: ^testing.T) {
	S :: struct {
		i: string,
		o: string,
	}
	s: S
	args := [?]string { "-i:hellope", "-o:world" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.i, "hellope")
	testing.expect_value(t, s.o, "world")
}

@(test)
test_extra_arg :: proc(t: ^testing.T) {
	S :: struct {
		a: string,
	}
	s: S
	args := [?]string { "-a:hellope", "world" }
	result := flags.parse(&s, args[:])
	err, ok := result.(flags.Parse_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Extra_Positional)
	}
}

@(test)
test_assignment_oddities :: proc(t: ^testing.T) {
	S :: struct {
		s: string,
	}
	s: S

	{
		args := [?]string { "-s:=" }
		result := flags.parse(&s, args[:])
		testing.expect_value(t, result, nil)
		testing.expect_value(t, s.s, "=")
	}

	{
		args := [?]string { "-s=:" }
		result := flags.parse(&s, args[:])
		testing.expect_value(t, result, nil)
		testing.expect_value(t, s.s, ":")
	}

	{
		args := [?]string { "-" }
		result := flags.parse(&s, args[:])
		err, ok := result.(flags.Parse_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
		if ok {
			testing.expect_value(t, err.reason, flags.Parse_Error_Reason.No_Flag)
		}
	}
}

@(test)
test_string_into_int :: proc(t: ^testing.T) {
	S :: struct {
		n: int,
	}
	s: S
	args := [?]string { "-n:hellope" }
	result := flags.parse(&s, args[:])
	err, ok := result.(flags.Parse_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Bad_Value)
	}
}

@(test)
test_string_into_bool :: proc(t: ^testing.T) {
	S :: struct {
		b: bool,
	}
	s: S
	args := [?]string { "-b:hellope" }
	result := flags.parse(&s, args[:])
	err, ok := result.(flags.Parse_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Bad_Value)
	}
}

@(test)
test_all_bools :: proc(t: ^testing.T) {
	S :: struct {
		a: bool,
		b: b8,
		c: b16,
		d: b32,
		e: b64,
	}
	s: S
	s.a = true
	s.c = true
	args := [?]string { "-a:false", "-b:true", "-c:0", "-d", "-e:1" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, false)
	testing.expect_value(t, s.b, true)
	testing.expect_value(t, s.c, false)
	testing.expect_value(t, s.d, true)
	testing.expect_value(t, s.e, true)
}

@(test)
test_all_ints :: proc(t: ^testing.T) {
	S :: struct {
		a: u8,
		b: i8,
		c: u16,
		d: i16,
		e: u32,
		f: i32,
		g: u64,
		i: i64,
		j: u128,
		k: i128,
	}

	s: S
	args := [?]string {
		fmt.tprintf("-a:%i", max(u8)),
		fmt.tprintf("-b:%i", min(i8)),
		fmt.tprintf("-c:%i", max(u16)),
		fmt.tprintf("-d:%i", min(i16)),
		fmt.tprintf("-e:%i", max(u32)),
		fmt.tprintf("-f:%i", min(i32)),
		fmt.tprintf("-g:%i", max(u64)),
		fmt.tprintf("-i:%i", min(i64)),
		fmt.tprintf("-j:%i", max(u128)),
		fmt.tprintf("-k:%i", min(i128)),
	}

	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, max(u8))
	testing.expect_value(t, s.b, min(i8))
	testing.expect_value(t, s.c, max(u16))
	testing.expect_value(t, s.d, min(i16))
	testing.expect_value(t, s.e, max(u32))
	testing.expect_value(t, s.f, min(i32))
	testing.expect_value(t, s.g, max(u64))
	testing.expect_value(t, s.i, min(i64))
	testing.expect_value(t, s.j, max(u128))
	testing.expect_value(t, s.k, min(i128))
}

@(test)
test_all_floats :: proc(t: ^testing.T) {
	S :: struct {
		a: f16,
		b: f32,
		c: f64,
		d: f64,
		e: f64,
	}
	s: S
	args := [?]string { "-a:100", "-b:3.14", "-c:-123.456", "-d:nan", "-e:inf" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, 100)
	testing.expect_value(t, s.b, 3.14)
	testing.expect_value(t, s.c, -123.456)
	testing.expectf(t, math.is_nan(s.d), "expected NaN, got %v", s.d)
	testing.expectf(t, math.is_inf(s.e, +1), "expected +Inf, got %v", s.e)
}

@(test)
test_all_enums :: proc(t: ^testing.T) {
	E :: enum { A, B }
	S :: struct {
		nameless: enum { C, D },
		named: E,
	}
	s: S
	args := [?]string { "-nameless:D", "-named:B" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, cast(int)s.nameless, 1)
	testing.expect_value(t, s.named, E.B)
}

@(test)
test_all_complex :: proc(t: ^testing.T) {
	S :: struct {
		a: complex32,
		b: complex64,
		c: complex128,
	}
	s: S
	args := [?]string { "-a:1+0i", "-b:3+7i", "-c:NaNNaNi" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, real(s.a), 1)
	testing.expect_value(t, imag(s.a), 0)
	testing.expect_value(t, real(s.b), 3)
	testing.expect_value(t, imag(s.b), 7)
	testing.expectf(t, math.is_nan(real(s.c)), "expected NaN, got %v", real(s.c))
	testing.expectf(t, math.is_nan(imag(s.c)), "expected NaN, got %v", imag(s.c))
}

@(test)
test_all_quaternion :: proc(t: ^testing.T) {
	S :: struct {
		a: quaternion64,
		b: quaternion128,
		c: quaternion256,
	}
	s: S
	args := [?]string { "-a:1+0i+1j+0k", "-b:3+7i+5j-3k", "-c:NaNNaNi+Infj-Infk" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)

	raw_a := (cast(^runtime.Raw_Quaternion64)&s.a)
	raw_b := (cast(^runtime.Raw_Quaternion128)&s.b)
	raw_c := (cast(^runtime.Raw_Quaternion256)&s.c)

	testing.expect_value(t, raw_a.real, 1)
	testing.expect_value(t, raw_a.imag, 0)
	testing.expect_value(t, raw_a.jmag, 1)
	testing.expect_value(t, raw_a.kmag, 0)

	testing.expect_value(t, raw_b.real, 3)
	testing.expect_value(t, raw_b.imag, 7)
	testing.expect_value(t, raw_b.jmag, 5)
	testing.expect_value(t, raw_b.kmag, -3)

	testing.expectf(t, math.is_nan(raw_c.real), "expected NaN, got %v", raw_c.real)
	testing.expectf(t, math.is_nan(raw_c.imag), "expected NaN, got %v", raw_c.imag)
	testing.expectf(t, math.is_inf(raw_c.jmag, +1), "expected +Inf, got %v", raw_c.jmag)
	testing.expectf(t, math.is_inf(raw_c.kmag, -1), "expected -Inf, got %v", raw_c.kmag)
}

@(test)
test_all_bit_sets :: proc(t: ^testing.T) {
	E :: enum {
		Option_A,
		Option_B,
	}
	S :: struct {
		a: bit_set[0..<8],
		b: bit_set[0..<16; u16],
		c: bit_set[16..<18; rune],
		d: bit_set[0..<1; i8],
		e: bit_set[0..<128],
		f: bit_set[-32..<32],
		g: bit_set[E],
		i: bit_set[E; u8],
	}
	s: S
	{
		args := [?]string {
			"-a:10101",
			"-b:0000_0000_0000_0001",
			"-c:11",
			"-d:___1",
			"-e:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001",
			"-f:1",
			"-g:01",
			"-i:1",
		}
		result := flags.parse(&s, args[:])
		testing.expect_value(t, result, nil)
		testing.expect_value(t, s.a, bit_set[0..<8]{0, 2, 4})
		testing.expect_value(t, s.b, bit_set[0..<16; u16]{15})
		testing.expect_value(t, s.c, bit_set[16..<18; rune]{16, 17})
		testing.expect_value(t, s.d, bit_set[0..<1; i8]{0})
		testing.expect_value(t, s.e, bit_set[0..<128]{127})
		testing.expect_value(t, s.f, bit_set[-32..<32]{-32})
		testing.expect_value(t, s.g, bit_set[E]{E.Option_B})
		testing.expect_value(t, s.i, bit_set[E; u8]{E.Option_A})
	}
	{
		args := [?]string { "-d:11" }
		result := flags.parse(&s, args[:])
		err, ok := result.(flags.Parse_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
		if ok {
			testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Bad_Value)
		}
	}
}

@(test)
test_all_strings :: proc(t: ^testing.T) {
	S :: struct {
		a, b, c: string,
		d: cstring,
	}
	s: S
	args := [?]string { "-a:hi", "-b:hellope", "-c:spaced out", "-d:cstr", "-d:cstr-overwrite" }
	result := flags.parse(&s, args[:])
	defer delete(s.d)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, "hi")
	testing.expect_value(t, s.b, "hellope")
	testing.expect_value(t, s.c, "spaced out")
	testing.expect_value(t, s.d, "cstr-overwrite")
}

@(test)
test_runes :: proc(t: ^testing.T) {
	S :: struct {
		a, b, c: rune,
	}
	s: S
	args := [?]string { "-a:a", "-b:ツ", "-c:\U0010FFFF" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, 'a')
	testing.expect_value(t, s.b, 'ツ')
	testing.expect_value(t, s.c, '\U0010FFFF')
}

@(test)
test_no_value :: proc(t: ^testing.T) {
	S :: struct {
		a: rune,
	}
	s: S

	{
		args := [?]string { "-a:" }
		result := flags.parse(&s, args[:])
		err, ok := result.(flags.Parse_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
		if ok {
			testing.expect_value(t, err.reason, flags.Parse_Error_Reason.No_Value)
		}
	}

	{
		args := [?]string { "-a=" }
		result := flags.parse(&s, args[:])
		err, ok := result.(flags.Parse_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
		if ok {
			testing.expect_value(t, err.reason, flags.Parse_Error_Reason.No_Value)
		}
	}
}

@(test)
test_overflow :: proc(t: ^testing.T) {
	S :: struct {
		a: u8,
	}
	s: S
	args := [?]string { "-a:256" }
	result := flags.parse(&s, args[:])
	err, ok := result.(flags.Parse_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Bad_Value)
	}
}

@(test)
test_underflow :: proc(t: ^testing.T) {
	S :: struct {
		a: i8,
	}
	s: S
	args := [?]string { "-a:-129" }
	result := flags.parse(&s, args[:])
	err, ok := result.(flags.Parse_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Bad_Value)
	}
}

@(test)
test_arrays :: proc(t: ^testing.T) {
	S :: struct {
		a: [dynamic]string,
		b: [dynamic]int,
	}
	s: S
	args := [?]string { "-a:abc", "-b:1", "-a:foo", "-b:3" }
	result := flags.parse(&s, args[:])
	defer {
		delete(s.a)
		delete(s.b)
	}
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.a), 2)
	testing.expect_value(t, len(s.b), 2)

	if len(s.a) < 2 || len(s.b) < 2 {
		return
	}

	testing.expect_value(t, s.a[0], "abc")
	testing.expect_value(t, s.a[1], "foo")
	testing.expect_value(t, s.b[0], 1)
	testing.expect_value(t, s.b[1], 3)
}

@(test)
test_varargs :: proc(t: ^testing.T) {
	S :: struct {
		varg: [dynamic]string,
	}
	s: S
	args := [?]string { "abc", "foo", "bar" }
	result := flags.parse(&s, args[:])
	defer delete(s.varg)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.varg), 3)

	if len(s.varg) < 3 {
		return
	}

	testing.expect_value(t, s.varg[0], "abc")
	testing.expect_value(t, s.varg[1], "foo")
	testing.expect_value(t, s.varg[2], "bar")
}

@(test)
test_mixed_varargs :: proc(t: ^testing.T) {
	S :: struct {
		input: string `args:"pos=0"`,
		varg: [dynamic]string,
	}
	s: S
	args := [?]string { "abc", "foo", "bar" }
	result := flags.parse(&s, args[:])
	defer delete(s.varg)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.varg), 2)

	if len(s.varg) < 2 {
		return
	}

	testing.expect_value(t, s.input, "abc")
	testing.expect_value(t, s.varg[0], "foo")
	testing.expect_value(t, s.varg[1], "bar")
}

@(test)
test_maps :: proc(t: ^testing.T) {
	S :: struct {
		a: map[string]string,
		b: map[string]int,
	}
	s: S
	args := [?]string { "-a:abc=foo", "-b:bar=42" }
	result := flags.parse(&s, args[:])
	defer {
		delete(s.a)
		delete(s.b)
	}
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.a), 1)
	testing.expect_value(t, len(s.b), 1)

	if len(s.a) < 1 || len(s.b) < 1 {
		return
	}

	abc, has_abc := s.a["abc"]
	bar, has_bar := s.b["bar"]

	testing.expect(t, has_abc, "expected map to have `abc` key set")
	testing.expect(t, has_bar, "expected map to have `bar` key set")
	testing.expect_value(t, abc, "foo")
	testing.expect_value(t, bar, 42)
}

@(test)
test_invalid_map_syntax :: proc(t: ^testing.T) {
	S :: struct {
		a: map[string]string,
	}
	s: S
	args := [?]string { "-a:foo:42" }
	result := flags.parse(&s, args[:])
	err, ok := result.(flags.Parse_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.No_Value)
	}
}

@(test)
test_underline_name_to_dash :: proc(t: ^testing.T) {
	S :: struct {
		a_b: int,
	}
	s: S
	args := [?]string { "-a-b:3" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a_b, 3)
}

@(test)
test_tags_pos :: proc(t: ^testing.T) {
	S :: struct {
		b: int `args:"pos=1"`,
		a: int `args:"pos=0"`,
	}
	s: S
	args := [?]string { "42", "99" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, 42)
	testing.expect_value(t, s.b, 99)
}

@(test)
test_tags_name :: proc(t: ^testing.T) {
	S :: struct {
		a: int `args:"name=alice"`,
		b: int `args:"name=bill"`,
	}
	s: S
	args := [?]string { "-alice:1", "-bill:2" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, 1)
	testing.expect_value(t, s.b, 2)
}

@(test)
test_tags_required :: proc(t: ^testing.T) {
	S :: struct {
		a: int,
		b: int `args:"required"`,
	}
	s: S
	args := [?]string { "-a:1" }
	result := flags.parse(&s, args[:])
	_, ok := result.(flags.Validation_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
}

@(test)
test_tags_required_pos :: proc(t: ^testing.T) {
	S :: struct {
		a: int `args:"pos=0,required"`,
		b: int `args:"pos=1"`,
	}
	s: S
	args := [?]string { "-b:5" }
	result := flags.parse(&s, args[:])
	_, ok := result.(flags.Validation_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
}

@(test)
test_tags_required_limit_min :: proc(t: ^testing.T) {
	S :: struct {
		n: [dynamic]int `args:"required=3"`,
	}

	{
		s: S
		args := [?]string { "-n:1" }
		result := flags.parse(&s, args[:])
		defer delete(s.n)
		_, ok := result.(flags.Validation_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
	}

	{
		s: S
		args := [?]string { "-n:3", "-n:5", "-n:7" }
		result := flags.parse(&s, args[:])
		defer delete(s.n)
		testing.expect_value(t, result, nil)
		testing.expect_value(t, len(s.n), 3)

		if len(s.n) == 3 {
			testing.expect_value(t, s.n[0], 3)
			testing.expect_value(t, s.n[1], 5)
			testing.expect_value(t, s.n[2], 7)
		}
	}
}

@(test)
test_tags_required_limit_min_max :: proc(t: ^testing.T) {
	S :: struct {
		n: [dynamic]int `args:"required=2<4"`,
	}

	{
		s: S
		args := [?]string { "-n:1" }
		result := flags.parse(&s, args[:])
		defer delete(s.n)
		_, ok := result.(flags.Validation_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
	}

	{
		s: S
		args := [?]string { "-n:1", "-n:2", "-n:3", "-n:4" }
		result := flags.parse(&s, args[:])
		defer delete(s.n)
		_, ok := result.(flags.Validation_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
	}

	{
		s: S
		args := [?]string { "-n:3", "-n:5", "-n:7" }
		result := flags.parse(&s, args[:])
		defer delete(s.n)
		testing.expect_value(t, result, nil)
		testing.expect_value(t, len(s.n), 3)

		if len(s.n) == 3 {
			testing.expect_value(t, s.n[0], 3)
			testing.expect_value(t, s.n[1], 5)
			testing.expect_value(t, s.n[2], 7)
		}
	}
}

@(test)
test_tags_required_limit_max :: proc(t: ^testing.T) {
	S :: struct {
		n: [dynamic]int `args:"required=<4"`,
	}

	{
		s: S
		args: []string
		result := flags.parse(&s, args)
		testing.expect_value(t, result, nil)
	}

	{
		s: S
		args := [?]string { "-n:1", "-n:2", "-n:3", "-n:4" }
		result := flags.parse(&s, args[:])
		defer delete(s.n)
		_, ok := result.(flags.Validation_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
	}

	{
		s: S
		args := [?]string { "-n:3", "-n:5", "-n:7" }
		result := flags.parse(&s, args[:])
		defer delete(s.n)
		testing.expect_value(t, result, nil)
		testing.expect_value(t, len(s.n), 3)

		if len(s.n) == 3 {
			testing.expect_value(t, s.n[0], 3)
			testing.expect_value(t, s.n[1], 5)
			testing.expect_value(t, s.n[2], 7)
		}
	}
}

@(test)
test_tags_pos_out_of_order :: proc(t: ^testing.T) {
	S :: struct {
		a: int `args:"pos=2"`,
		varg: [dynamic]int,
	}
	s: S
	args := [?]string { "1", "2", "3", "4" }
	result := flags.parse(&s, args[:])
	defer delete(s.varg)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.varg), 3)

	if len(s.varg) < 3 {
		return
	}

	testing.expect_value(t, s.a, 3)
	testing.expect_value(t, s.varg[0], 1)
	testing.expect_value(t, s.varg[1], 2)
	testing.expect_value(t, s.varg[2], 4)
}

@(test)
test_missing_flag :: proc(t: ^testing.T) {
	S :: struct {
		a: int,
	}
	s: S
	args := [?]string { "-b" }
	result := flags.parse(&s, args[:])
	err, ok := result.(flags.Parse_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Missing_Flag)
	}
}

@(test)
test_alt_syntax :: proc(t: ^testing.T) {
	S :: struct {
		a: int,
	}
	s: S
	args := [?]string { "-a=3" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, 3)
}

@(test)
test_strict_returns_first_error :: proc(t: ^testing.T) {
	S :: struct {
		b: int,
		c: int,
	}
	s: S
	args := [?]string { "-a=3", "-b=3" }
	result := flags.parse(&s, args[:], strict=true)
	err, ok := result.(flags.Parse_Error)
	testing.expect_value(t, s.b, 0)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Missing_Flag)
	}
}

@(test)
test_non_strict_returns_last_error :: proc(t: ^testing.T) {
	S :: struct {
		a: int,
		b: int,
	}
	s: S
	args := [?]string { "-a=foo", "-b=2", "-c=3" }
	result := flags.parse(&s, args[:], strict=false)
	err, ok := result.(flags.Parse_Error)
	testing.expect_value(t, s.b, 2)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Missing_Flag)
	}
}

@(test)
test_map_overwrite :: proc(t: ^testing.T) {
	S :: struct {
		m: map[string]int,
	}
	s: S
	args := [?]string { "-m:foo=3", "-m:foo=5" }
	result := flags.parse(&s, args[:])
	defer delete(s.m)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.m), 1)
	foo, has_foo := s.m["foo"]
	testing.expect(t, has_foo, "expected map to have `foo` key set")
	testing.expect_value(t, foo, 5)
}

@(test)
test_maps_of_arrays :: proc(t: ^testing.T) {
	// Why you would ever want to do this, I don't know, but it's possible!
	S :: struct {
		m: map[string][dynamic]int,
	}
	s: S
	args := [?]string { "-m:foo=1", "-m:foo=2", "-m:bar=3" }
	result := flags.parse(&s, args[:])
	defer {
		for _, v in s.m {
			delete(v)
		}
		delete(s.m)
	}
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.m), 2)

	if len(s.m) != 2 {
		return
	}

	foo, has_foo := s.m["foo"]
	bar, has_bar := s.m["bar"]

	testing.expect_value(t, has_foo, true)
	testing.expect_value(t, has_bar, true)

	if has_foo {
		testing.expect_value(t, len(foo), 2)
		if len(foo) == 2 {
			testing.expect_value(t, foo[0], 1)
			testing.expect_value(t, foo[1], 2)
		}
	}

	if has_bar {
		testing.expect_value(t, len(bar), 1)
		if len(bar) == 1 {
			testing.expect_value(t, bar[0], 3)
		}
	}
}

@(test)
test_builtin_help_flag :: proc(t: ^testing.T) {
	S :: struct {}
	s: S

	args_short  := [?]string { "-h" }
	args_normal := [?]string { "-help" }

	result := flags.parse(&s, args_short[:])
	_, ok := result.(flags.Help_Request)
	testing.expectf(t, ok, "unexpected result: %v", result)

	result = flags.parse(&s, args_normal[:])
	_, ok = result.(flags.Help_Request)
	testing.expectf(t, ok, "unexpected result: %v", result)
}

// This test makes sure that if a positional argument is specified, it won't be
// overwritten by an unspecified positional, which should follow the principle
// of least surprise for the user.
@(test)
test_pos_nonoverlap :: proc(t: ^testing.T) {
	S :: struct {
		a: int `args:"pos=0"`,
		b: int `args:"pos=1"`,
	}
	s: S

	args := [?]string { "-a:3", "5" }

	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, 3)
	testing.expect_value(t, s.b, 5)
}

// This test ensures the underlying `bit_array` container handles many
// arguments in a sane manner.
@(test)
test_pos_many_args :: proc(t: ^testing.T) {
	S :: struct {
		varg: [dynamic]int,
		a: int `args:"pos=0,required"`,
		b: int `args:"pos=64,required"`,
		c: int `args:"pos=66,required"`,
		d: int `args:"pos=129,required"`,
	}
	s: S

	args: [dynamic]string
	defer delete(s.varg)

	for i in 0 ..< 130 { append(&args, fmt.aprintf("%i", 1 + i)) }
	defer {
		for a in args {
			delete(a)
		}
		delete(args)
	}

	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)

	testing.expect_value(t, s.a, 1)
	for i in 1 ..< 63 { testing.expect_value(t, s.varg[i], 2 + i) }
	testing.expect_value(t, s.b, 65)
	testing.expect_value(t, s.varg[63], 66)
	testing.expect_value(t, s.c, 67)
	testing.expect_value(t, s.varg[64], 68)
	testing.expect_value(t, s.varg[65], 69)
	testing.expect_value(t, s.varg[66], 70)
	for i in 67 ..< 126 { testing.expect_value(t, s.varg[i], 4 + i) }
	testing.expect_value(t, s.d, 130)
}

@(test)
test_unix :: proc(t: ^testing.T) {
	S :: struct {
		a: string,
	}
	s: S

	{
		args := [?]string { "--a", "hellope" }

		result := flags.parse(&s, args[:], .Unix)
		testing.expect_value(t, result, nil)
		testing.expect_value(t, s.a, "hellope")
	}

	{
		args := [?]string { "-a", "hellope", "--a", "world" }

		result := flags.parse(&s, args[:], .Unix)
		testing.expect_value(t, result, nil)
		testing.expect_value(t, s.a, "world")
	}

	{
		args := [?]string { "-a=hellope" }

		result := flags.parse(&s, args[:], .Unix)
		testing.expect_value(t, result, nil)
		testing.expect_value(t, s.a, "hellope")
	}
}

@(test)
test_unix_variadic :: proc(t: ^testing.T) {
	S :: struct {
		a: [dynamic]int `args:"variadic"`,
	}
	s: S

	args := [?]string { "--a", "7", "32", "11" }

	result := flags.parse(&s, args[:], .Unix)
	defer delete(s.a)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.a), 3)

	if len(s.a) < 3 {
		return
	}

	testing.expect_value(t, s.a[0], 7)
	testing.expect_value(t, s.a[1], 32)
	testing.expect_value(t, s.a[2], 11)
}

@(test)
test_unix_variadic_limited :: proc(t: ^testing.T) {
	S :: struct {
		a: [dynamic]int `args:"variadic=2"`,
		b: int,
	}
	s: S

	args := [?]string { "-a", "11", "101", "-b", "3" }

	result := flags.parse(&s, args[:], .Unix)
	defer delete(s.a)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.a), 2)

	if len(s.a) < 2 {
		return
	}

	testing.expect_value(t, s.a[0], 11)
	testing.expect_value(t, s.a[1], 101)
	testing.expect_value(t, s.b, 3)
}

@(test)
test_unix_positional :: proc(t: ^testing.T) {
	S :: struct {
		a: int `args:"pos=1"`,
		b: int `args:"pos=0"`,
	}
	s: S

	args := [?]string { "-b", "17", "11" }

	result := flags.parse(&s, args[:], .Unix)
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a, 11)
	testing.expect_value(t, s.b, 17)
}

@(test)
test_unix_positional_with_variadic :: proc(t: ^testing.T) {
	S :: struct {
		varg: [dynamic]int,
		v: [dynamic]int `args:"variadic"`,
	}
	s: S

	args := [?]string { "35", "-v", "17", "11" }

	result := flags.parse(&s, args[:], .Unix)
	defer {
		delete(s.varg)
		delete(s.v)
	}
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.varg), 1)
	testing.expect_value(t, len(s.v), 2)
}

@(test)
test_unix_double_dash_variadic :: proc(t: ^testing.T) {
	S :: struct {
		varg: [dynamic]string,
		i: int,
	}
	s: S

	args := [?]string { "-i", "3", "--", "hellope", "-i", "5" }

	result := flags.parse(&s, args[:], .Unix)
	defer {
		delete(s.varg)
	}
	testing.expect_value(t, result, nil)
	testing.expect_value(t, len(s.varg), 3)
	testing.expect_value(t, s.i, 3)

	if len(s.varg) != 3 {
		return
	}

	testing.expect_value(t, s.varg[0], "hellope")
	testing.expect_value(t, s.varg[1], "-i")
	testing.expect_value(t, s.varg[2], "5")
}

@(test)
test_unix_no_value :: proc(t: ^testing.T) {
	S :: struct {
		i: int,
	}
	s: S

	args := [?]string { "--i" }

	result := flags.parse(&s, args[:], .Unix)
	err, ok := result.(flags.Parse_Error)
	testing.expectf(t, ok, "unexpected result: %v", result)
	if ok {
		testing.expect_value(t, err.reason, flags.Parse_Error_Reason.No_Value)
	}
}

// This test ensures there are no bad frees with cstrings.
@(test)
test_if_dynamic_cstrings_get_freed :: proc(t: ^testing.T) {
	S :: struct {
		varg: [dynamic]cstring,
	}
	s: S

	args := [?]string { "Hellope", "world!" }
	result := flags.parse(&s, args[:])
	defer {
		for v in s.varg {
			delete(v)
		}
		delete(s.varg)
	}
	testing.expect_value(t, result, nil)
}

// This test ensures there are no double allocations with cstrings.
@(test)
test_if_map_cstrings_get_freed :: proc(t: ^testing.T) {
	S :: struct {
		m: map[cstring]cstring,
	}
	s: S

	args := [?]string { "-m:hellope=world", "-m:hellope=bar", "-m:hellope=foo" }
	result := flags.parse(&s, args[:])
	defer {
		for _, v in s.m {
			delete(v)
		}
		delete(s.m)
	}
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.m["hellope"], "foo")
}

@(test)
test_os_handle :: proc(t: ^testing.T) {
	defer if !testing.failed(t) {
		// Delete the file now that we're done.
		//
		// This is not done all the time, just in case the file is useful to debugging.
		testing.expect_value(t, os.remove(TEMPORARY_FILENAME), nil)
	}

	TEMPORARY_FILENAME :: "test_core_flags_write_test_output_data"

	test_data := "Hellope!"

	W :: struct {
		outf: os.Handle `args:"file=cw"`,
	}
	w: W

	args := [?]string { fmt.tprintf("-outf:%s", TEMPORARY_FILENAME) }
	result := flags.parse(&w, args[:])
	testing.expect_value(t, result, nil)
	if result != nil {
		return
	}
	defer os.close(w.outf)
	os.write_string(w.outf, test_data)

	R :: struct {
		inf: os.Handle `args:"file=r"`,
	}
	r: R

	args = [?]string { fmt.tprintf("-inf:%s", TEMPORARY_FILENAME) }
	result = flags.parse(&r, args[:])
	testing.expect_value(t, result, nil)
	if result != nil {
		return
	}
	defer os.close(r.inf)
	data, read_ok := os.read_entire_file_from_handle(r.inf, context.temp_allocator)
	testing.expect_value(t, read_ok, true)
	file_contents_equal := 0 == bytes.compare(transmute([]u8)test_data, data)
	testing.expectf(t, file_contents_equal, "expected file contents to be the same, got %v", data)
}

@(test)
test_distinct_types :: proc(t: ^testing.T) {
	I :: distinct int
	S :: struct {
		base_i: I `args:"indistinct"`,
		unmodified_i: I,
	}
	s: S

	{
		args := [?]string {"-base-i:1"}
		result := flags.parse(&s, args[:])
		testing.expect_value(t, result, nil)
	}

	{
		args := [?]string {"-unmodified-i:1"}
		result := flags.parse(&s, args[:])
		err, ok := result.(flags.Parse_Error)
		testing.expectf(t, ok, "unexpected result: %v", result)
		if ok {
			testing.expect_value(t, err.reason, flags.Parse_Error_Reason.Unsupported_Type)
		}
	}
}

@(test)
test_datetime :: proc(t: ^testing.T) {
	when flags.IMPORTING_TIME {
		W :: struct {
			t: datetime.DateTime,
		}
		w: W

		args := [?]string { "-t:2024-06-04T12:34:56Z" }
		result := flags.parse(&w, args[:])
		testing.expect_value(t, result, nil)
		if result != nil {
			return
		}
		testing.expect_value(t, w.t.date.year, 2024)
		testing.expect_value(t, w.t.date.month, 6)
		testing.expect_value(t, w.t.date.day, 4)
	} else {
		log.info("Skipping test due to lack of platform support.")
	}
}

@(test)
test_net :: proc(t: ^testing.T) {
	when flags.IMPORTING_NET {
		W :: struct {
			addr: net.Host_Or_Endpoint,
		}
		w: W

		args := [?]string { "-addr:odin-lang.org:80" }
		result := flags.parse(&w, args[:])
		testing.expect_value(t, result, nil)
		if result != nil {
			return
		}
		host, is_host := w.addr.(net.Host)
		testing.expectf(t, is_host, "expected type of `addr` to be `net.Host`, was %v", w.addr)
		testing.expect_value(t, host.hostname, "odin-lang.org")
		testing.expect_value(t, host.port, 80)
	} else {
		log.info("Skipping test due to lack of platform support.")
	}
}

@(test)
test_custom_type_setter :: proc(t: ^testing.T) {
	Custom_Bool :: distinct bool

	S :: struct {
		a: Custom_Data,
		b: Custom_Bool `args:"indistinct"`,
	}
	s: S

	args := [?]string { "-a:hellope", "-b:true" }
	result := flags.parse(&s, args[:])
	testing.expect_value(t, result, nil)
	testing.expect_value(t, s.a.a, 32)
	testing.expect_value(t, s.b, true)
}

// This test is sensitive to many of the underlying mechanisms of the library,
// so if something isn't working, it'll probably show up here first, but it may
// not be immediately obvious as to what's wrong.
//
// It makes for a good early warning system.
@(test)
test_usage_write_odin :: proc(t: ^testing.T) {
	Expected_Output :: `Usage:
	varg required-number [number] [name] -bars -bots -foos -gadgets -widgets [-array] [-count] [-greek] [-map-type] [-verbose] ...
Flags:
	-required-number:<int>, required  | some number
	-number:<int>                     | some other number
	-name:<string>
		Multi-line documentation
		gets formatted
		very nicely.
	-bars:<string>, exactly 3         | <This flag has not been documented yet.>
	-bots:<string>, at least 1        | <This flag has not been documented yet.>
	-foos:<string>, between 2 and 3   | <This flag has not been documented yet.>
	-gadgets:<string>, at least 1     | <This flag has not been documented yet.>
	-widgets:<string>, at most 2      | <This flag has not been documented yet.>
	                                  |
	-array:<rune>, multiple           | <This flag has not been documented yet.>
	-count:<u8>                       | <This flag has not been documented yet.>
	-greek:<Custom_Enum>              | <This flag has not been documented yet.>
	-map-type:<cstring>=<u8>          | <This flag has not been documented yet.>
	-verbose                          | <This flag has not been documented yet.>
	<string, ...>                     | <This flag has not been documented yet.>
`

	Custom_Enum :: enum {
		Alpha,
		Omega,
	}

	S :: struct {
		required_number: int `args:"pos=0,required" usage:"some number"`,
		number: int `args:"pos=1" usage:"some other number"`,
		name: string `args:"pos=2" usage:"
	Multi-line documentation
		gets formatted
very nicely.

"`,

		c: u8 `args:"name=count"`,
		greek: Custom_Enum,

		array: [dynamic]rune,
		map_type: map[cstring]byte,

		gadgets: [dynamic]string `args:"required=1"`,
		widgets: [dynamic]string `args:"required=<3"`,
		foos: [dynamic]string `args:"required=2<4"`,
		bars: [dynamic]string `args:"required=3<4"`,
		bots: [dynamic]string `args:"required"`,

		debug: bool `args:"hidden" usage:"print debug info"`,
		verbose: bool,

		varg: [dynamic]string,
	}

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)
	writer := strings.to_stream(&builder)
	flags.write_usage(writer, S, "varg", .Odin)
	testing.expect_value(t, strings.to_string(builder), Expected_Output)
}

@(test)
test_usage_write_unix :: proc(t: ^testing.T) {
	Expected_Output :: `Usage:
	varg required-number [number] [name] --bars --bots --foos --gadgets --variadic-flag --widgets [--array] [--count] [--greek] [--verbose] ...
Flags:
	--required-number <int>, required       | some number
	--number <int>                          | some other number
	--name <string>
		Multi-line documentation
		gets formatted
		very nicely.
	--bars <string>, exactly 3              | <This flag has not been documented yet.>
	--bots <string>, at least 1             | <This flag has not been documented yet.>
	--foos <string>, between 2 and 3        | <This flag has not been documented yet.>
	--gadgets <string>, at least 1          | <This flag has not been documented yet.>
	--variadic-flag <int, ...>, at least 2  | <This flag has not been documented yet.>
	--widgets <string>, at most 2           | <This flag has not been documented yet.>
	                                        |
	--array <rune>, multiple                | <This flag has not been documented yet.>
	--count <u8>                            | <This flag has not been documented yet.>
	--greek <Custom_Enum>                   | <This flag has not been documented yet.>
	--verbose                               | <This flag has not been documented yet.>
	<string, ...>                           | <This flag has not been documented yet.>
`

	Custom_Enum :: enum {
		Alpha,
		Omega,
	}

	S :: struct {
		required_number: int `args:"pos=0,required" usage:"some number"`,
		number: int `args:"pos=1" usage:"some other number"`,
		name: string `args:"pos=2" usage:"
	Multi-line documentation
		gets formatted
very nicely.

"`,

		c: u8 `args:"name=count"`,
		greek: Custom_Enum,

		array: [dynamic]rune,
		variadic_flag: [dynamic]int `args:"variadic,required=2"`,

		gadgets: [dynamic]string `args:"required=1"`,
		widgets: [dynamic]string `args:"required=<3"`,
		foos: [dynamic]string `args:"required=2<4"`,
		bars: [dynamic]string `args:"required=3<4"`,
		bots: [dynamic]string `args:"required"`,

		debug: bool `args:"hidden" usage:"print debug info"`,
		verbose: bool,

		varg: [dynamic]string,
	}

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)
	writer := strings.to_stream(&builder)
	flags.write_usage(writer, S, "varg", .Unix)
	testing.expect_value(t, strings.to_string(builder), Expected_Output)
}
