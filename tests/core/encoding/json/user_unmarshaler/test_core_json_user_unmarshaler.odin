package test_core_json_user_unmarshaler

import "core:encoding/json"
import "core:io"
import "core:strings"
import "core:testing"
import "base:runtime"

SPECS :: [3]json.Specification{.JSON, .JSON5, .SJSON}

Celsius :: distinct f64
Word    :: distinct string
Lazy    :: distinct int
Box     :: distinct uintptr
Bag     :: struct {
	m: map[string]int,
}
Bag_Fields :: struct {
	m: map[string]int,
}
Lenient :: distinct map[string]int
Kind    :: enum {A, B}
Shout   :: enum {Quiet, Loud}

registry: map[typeid]json.User_Unmarshaler
marshal_registry: map[typeid]json.User_Marshaler

int_marshaler :: proc(w: io.Writer, v: any, opt: ^json.Marshal_Options) -> json.Marshal_Error {
	io.write_string(w, `"INT"`) or_return
	return nil
}

string_marshaler :: proc(w: io.Writer, v: any, opt: ^json.Marshal_Options) -> json.Marshal_Error {
	io.write_string(w, `"STRING"`) or_return
	return nil
}

shout_marshaler :: proc(w: io.Writer, v: any, opt: ^json.Marshal_Options) -> json.Marshal_Error {
	io.write_string(w, `"SHOUT"`) or_return
	return nil
}

celsius_unmarshaler :: proc(p: ^json.Parser, v: any) -> json.Unmarshal_Error {
	return json.unmarshal_value(p, any{v.data, typeid_of(f64)})
}

word_unmarshaler :: proc(p: ^json.Parser, v: any) -> json.Unmarshal_Error {
	if p.curr_token.kind != .Ident {
		return json.Error.Unexpected_Token
	}
	(^Word)(v.data)^ = Word(p.curr_token.text)
	json.advance_token(p)
	return nil
}

lazy_unmarshaler :: proc(p: ^json.Parser, v: any) -> json.Unmarshal_Error {
	return nil
}

box_unmarshaler :: proc(p: ^json.Parser, v: any) -> json.Unmarshal_Error {
	boxed, alloc_err := new(int, p.allocator)
	if alloc_err != nil {
		return json.Error.Out_Of_Memory
	}
	json.unmarshal_value(p, boxed^) or_return
	(^Box)(v.data)^ = Box(uintptr(boxed))
	return nil
}

bag_unmarshaler :: proc(p: ^json.Parser, v: any) -> json.Unmarshal_Error {
	return json.unmarshal_value(p, any{v.data, typeid_of(Bag_Fields)})
}

lenient_unmarshaler :: proc(p: ^json.Parser, v: any) -> json.Unmarshal_Error {
	return json.unmarshal_value(p, any{v.data, typeid_of(map[string]int)}, {.Allow_Duplicate_Fields})
}

@(init)
register_unmarshalers :: proc "contextless" () {
	context = runtime.default_context()
	json.set_user_unmarshalers(&registry)
	if json.register_user_unmarshaler(Celsius, celsius_unmarshaler) != .None ||
	   json.register_user_unmarshaler(Word, word_unmarshaler) != .None ||
	   json.register_user_unmarshaler(Lazy, lazy_unmarshaler) != .None ||
	   json.register_user_unmarshaler(Box, box_unmarshaler) != .None ||
	   json.register_user_unmarshaler(Bag, bag_unmarshaler) != .None ||
	   json.register_user_unmarshaler(Lenient, lenient_unmarshaler) != .None {
		panic("registering the user unmarshalers failed")
	}
	json.set_user_marshalers(&marshal_registry)
	if json.register_user_marshaler(int, int_marshaler) != .None ||
	   json.register_user_marshaler(string, string_marshaler) != .None ||
	   json.register_user_marshaler(Shout, shout_marshaler) != .None {
		panic("registering the user marshalers failed")
	}
}

@(test)
registered_types_unmarshal :: proc(t: ^testing.T) {
	S :: struct {
		c:  Celsius,
		cs: []Celsius,
	}
	s: S
	err := json.unmarshal_string(`{"c": 21.5, "cs": [1, 2]}`, &s, allocator = context.temp_allocator)
	testing.expectf(t, err == nil && s.c == 21.5 && len(s.cs) == 2 && s.cs[1] == 2, "%v %v", s, err)
}

@(test)
malformed_input_is_an_error :: proc(t: ^testing.T) {
	S :: struct {
		a: int,
	}
	for spec in SPECS {
		for flags in ([]json.Unmarshal_Flags{{}, {.Skip_Validation}}) {
			m: map[string]int
			err := json.unmarshal_string(`{"a" 1}`, &m, spec, context.temp_allocator, flags)
			testing.expectf(t, err == json.Error.Expected_Colon_After_Key, "%v %v: %v", spec, flags, err)

			s: S
			err = json.unmarshal_string(`{"a": 1`, &s, spec, context.temp_allocator, flags)
			testing.expectf(t, err == json.Error.EOF, "%v %v: %v", spec, flags, err)
			err = json.unmarshal_string(`{"a": 1e}`, &s, spec, context.temp_allocator, flags)
			testing.expectf(t, err == json.Error.Invalid_Number, "%v %v: %v", spec, flags, err)

			a: [dynamic]int
			err = json.unmarshal_string(`[1, 2`, &a, spec, context.temp_allocator, flags)
			testing.expectf(t, err == json.Error.EOF, "%v %v: %v", spec, flags, err)

			sl: []int
			err = json.unmarshal_string(`[[1], [2`, &sl, spec, context.temp_allocator, flags)
			testing.expectf(t, err == json.Error.EOF, "%v %v: %v", spec, flags, err)
		}
	}
}

@(test)
custom_values_in_arrays :: proc(t: ^testing.T) {
	ws: []Word
	err := json.unmarshal_string(`[foo, bar]`, &ws, .JSON, context.temp_allocator)
	testing.expectf(t, err == nil && len(ws) == 2 && ws[0] == "foo" && ws[1] == "bar", "%v %v", ws, err)

	deep := strings.concatenate({strings.repeat("[", 200, context.temp_allocator), strings.repeat("]", 200, context.temp_allocator)}, context.temp_allocator)
	err = json.unmarshal_string(deep, &ws, .JSON, context.temp_allocator)
	testing.expectf(t, err == json.Error.Max_Depth_Exceeded, "%v", err)
}

@(test)
custom_values_in_unions :: proc(t: ^testing.T) {
	Either :: union {
		Celsius,
		Word,
	}
	es: []Either
	err := json.unmarshal_string(`[1.5, foo]`, &es, .JSON, context.temp_allocator)
	testing.expectf(t, err == nil && len(es) == 2 && es[0] == Celsius(1.5) && es[1] == Word("foo"), "%v %v", es, err)

	S1 :: struct {
		b: Box,
		x: int,
	}
	S2 :: struct {
		b: Box,
		y: string,
	}
	s: union{S1, S2}
	err = json.unmarshal_string(`{"b": 7, "y": "s"}`, &s)
	s2, is_s2 := s.(S2)
	testing.expectf(t, err == nil && is_s2 && s2.b != 0 && (^int)(uintptr(s2.b))^ == 7 && s2.y == "s", "%v %v", s, err)
	free(rawptr(uintptr(s2.b)))
	delete(s2.y)
}

@(test)
flags_reach_nested_values :: proc(t: ^testing.T) {
	DUP :: `{"m": {"a": 1, "a": 2}}`
	bag: Bag
	err := json.unmarshal_string(DUP, &bag, allocator = context.temp_allocator, flags = {.Allow_Duplicate_Fields})
	testing.expectf(t, err == nil && len(bag.m) == 1 && bag.m["a"] == 2, "%v %v", bag, err)
	bag = {}
	err = json.unmarshal_string(DUP, &bag, allocator = context.temp_allocator)
	testing.expectf(t, err == json.Unmarshal_Data_Error.Multiple_Use_Field, "%v %v", bag, err)

	S :: struct {
		l: Lenient,
		m: map[string]int,
	}
	s: S
	err = json.unmarshal_string(`{"l": {"a": 1, "a": 2}, "m": {"b": 1}}`, &s, allocator = context.temp_allocator)
	testing.expectf(t, err == nil && s.l["a"] == 2 && s.m["b"] == 1, "%v %v", s, err)
	s = {}
	err = json.unmarshal_string(`{"l": {"a": 1}, "m": {"b": 1, "b": 2}}`, &s, allocator = context.temp_allocator)
	testing.expectf(t, err == json.Unmarshal_Data_Error.Multiple_Use_Field, "%v %v", s, err)
}

@(test)
custom_value_that_reads_nothing :: proc(t: ^testing.T) {
	ls: []Lazy
	err := json.unmarshal_string(`[1]`, &ls, .SJSON, context.temp_allocator)
	testing.expectf(t, err == json.Error.Unexpected_Token, "%v %v", ls, err)
}

@(test)
enums_bypass_base_type_marshalers :: proc(t: ^testing.T) {
	expect :: proc(t: ^testing.T, v: any, opt: json.Marshal_Options, want: string, loc := #caller_location) {
		data, err := json.marshal(v, opt, context.temp_allocator)
		testing.expectf(t, err == nil && string(data) == want, "%v: %q %v, want %q", v.id, data, err, want, loc = loc)
	}
	expect(t, 5, {}, `"INT"`)
	expect(t, "x", {}, `"STRING"`)
	expect(t, Kind.B, {}, "1")
	expect(t, Kind.B, {use_enum_names = true}, `"B"`)
	expect(t, Kind(9), {use_enum_names = true}, "9")
	expect(t, Shout.Loud, {}, `"SHOUT"`)
	expect(t, Shout.Loud, {use_enum_names = true}, `"SHOUT"`)
	S :: struct {
		k: Kind,
		n: int,
	}
	expect(t, S{.B, 1}, {use_enum_names = true}, `{"k":"B","n":"INT"}`)
}
