package test_core_json

import "core:encoding/json"
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:mem"
import "core:strings"
import "core:testing"
import "core:unicode/utf8"
import "core:mem/virtual"
import "base:runtime"

@test
parse_json :: proc(t: ^testing.T) {
   
	json_data := `
	{
	  "firstName": "John",
	  "lastName": "Smith",
	  "isAlive": true,
	  "age": 27,
	  "address": {
		"streetAddress": "21 2nd Street",
		"city": "New York",
		"state": "NY",
		"postalCode": "10021-3100"
	  },
	  "phoneNumbers": [
		{
		  "type": "home",
		  "number": "212 555-1234"
		},
		{
		  "type": "office",
		  "number": "646 555-4567"
		}
	  ],
	  "children": [],
	  "spouse": null
	}
	`
   
	val, err := json.parse(transmute([]u8)json_data)
	json.destroy_value(val)
	testing.expectf(t, err == nil, "Expected `json.parse` to return nil, got %v", err)
}

@test
out_of_memory_in_parse_json :: proc(t: ^testing.T) {
	arena: virtual.Arena
	arena_buffer: [256]byte
	arena_init_error := virtual.arena_init_buffer(&arena, arena_buffer[:])
	testing.expectf(t, arena_init_error == nil, "Expected arena initialization to not return error, got: %v\n", arena_init_error)

	context.allocator = virtual.arena_allocator(&arena)
	
	json_data := `
	{
	  "firstName": "John",
	  "lastName": "Smith",
	  "isAlive": true,
	  "age": 27,
	  "address": {
		"streetAddress": "21 2nd Street",
		"city": "New York",
		"state": "NY",
		"postalCode": "10021-3100"
	  },
	  "phoneNumbers": [
		{
		  "type": "home",
		  "number": "212 555-1234"
		},
		{
		  "type": "office",
		  "number": "646 555-4567"
		}
	  ],
	  "children": [],
	  "spouse": null
	}
	`

	val, err := json.parse(transmute([]u8)json_data)
	json.destroy_value(val)

	expected_error := json.Error.Out_Of_Memory
	testing.expectf(t, err == json.Error.Out_Of_Memory, "Expected `json.parse` to fail with %v, got %v", expected_error, err)
}

@test
out_of_memory_in_unmarshal :: proc(t: ^testing.T) {
	arena: virtual.Arena
	arena_buffer: [128]byte
	arena_init_error := virtual.arena_init_buffer(&arena, arena_buffer[:])
	testing.expectf(t, arena_init_error == nil, "Expected arena initialization to not return error, got: %v\n", arena_init_error)

	context.allocator = virtual.arena_allocator(&arena)

	json_data := `{
		"number": 42,
		"strs": [
			"Cat",
			"Dog",
			"Toucan"
		],
		"flag": true
	}`

	Test_Structure :: struct {
		number: int,
		strs: []string,
		flag: bool,
	}
	test_result: Test_Structure

	err := json.unmarshal(transmute([]u8)json_data, &test_result)
	testing.expectf(t, err == nil, "Expected `json.unmarshal` to succeed, got error %v", err)

	// Test #4515 fix.
	// Without `or_return` in `unmarshal_object`'s struct_loop, `json.unmarshal` would return OOM a few times and then return `Unsupported_Type_Error`.
	// With the fix we expect it to return OOM every time, so if this ever fails, it means we have a regression.
	for _ in 0..<8 {
		err  = json.unmarshal(transmute([]u8)json_data, &test_result)
		expected_error := json.Error.Out_Of_Memory
		testing.expectf(t, err == json.Error.Out_Of_Memory, "Expected `json.unmarshal` to fail with %v, got %v", expected_error, err)
	}
}

@test
marshal_json :: proc(t: ^testing.T) {
   
	My_Struct :: struct {
		a: int,
		b: int,
	}
   
	my_struct := My_Struct {
		a = 2,
		b = 5,
	}
   
	data, err := json.marshal(my_struct)
	defer delete(data)
	testing.expectf(t, err == nil, "Expected `json.marshal` to return nil, got %v", err)
}

PRODUCTS := `
{
	"cash":     "0",
	"products": [
		{
			"name": "Cog\nCola",
			"cost":  "3",
			"owned": "1",

			"profit": "4",
			"seconds": 3,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "gingerBeer",
			"cost":  "9",
			"owned": "0",

			"profit": "16",
			"seconds": 5,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "Coffee",
			"cost":  "27",
			"owned": "0",

			"profit": "64",
			"seconds": 7,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "Haggis",
			"cost":  "81",
			"owned": "0",

			"profit": "256",
			"seconds": 11,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "Lasagna",
			"cost":  "243",
			"owned": "0",

			"profit": "1024",
			"seconds": 13,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "Asparagus",
			"cost":  "729",
			"owned": "0",

			"profit": "4096",
			"seconds": 17,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "Yorkshire Pudding",
			"cost":  "2187",
			"owned": "0",

			"profit": "16384",
			"seconds": 19,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "Salmon Wrap",
			"cost":  "6561",
			"owned": "0",

			"profit": "65536",
			"seconds": 23,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "Poke Bowl",
			"cost":  "19683",
			"owned": "0",

			"profit": "262144",
			"seconds": 29,
			"multiplier": 1,
			"auto_click": false
		},
		{
			"name": "Chili Con Carne",
			"cost":  "59049",
			"owned": "0",

			"profit": "1048576",
			"seconds": 59,
			"multiplier": 1,
			"auto_click": false
		},
	],
}
`

original_data := Game_Marshal{
	cash = "0",
	products = {
		{
			name       = "Cog\nCola",
			cost       = "3",
			owned      = "1",
			profit     = "4",
			seconds    = 3,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "gingerBeer",
			cost       = "9",
			owned      = "0",
			profit     = "16",
			seconds    = 5,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "Coffee",
			cost       = "27",
			owned      = "0",
			profit     = "64",
			seconds    = 7,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "Haggis",
			cost       = "81",
			owned      = "0",
			profit     = "256",
			seconds    = 11,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "Lasagna",
			cost       = "243",
			owned      = "0",
			profit     = "1024",
			seconds    = 13,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "Asparagus",
			cost       = "729",
			owned      = "0",
			profit     = "4096",
			seconds    = 17,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "Yorkshire Pudding",
			cost       = "2187",
			owned      = "0",
			profit     = "16384",
			seconds    = 19,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "Salmon Wrap",
			cost       = "6561",
			owned      = "0",
			profit     = "65536",
			seconds    = 23,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "Poke Bowl",
			cost       = "19683",
			owned      = "0",
			profit     = "262144",
			seconds    = 29,
			multiplier = 1,
			auto_click = false,
		},
		{
			name       = "Chili Con Carne",
			cost       = "59049",
			owned      = "0",
			profit     = "1048576",
			seconds    = 59,
			multiplier = 1,
			auto_click = false,
		},
	},
}

Product_Marshal :: struct {
	name:       cstring,
	owned:      string,

	cost:       string,

	profit:     string,
	seconds:    int,
	multiplier: int,

	auto_click: bool,
}

Game_Marshal :: struct {
	cash:     string,
	products: []Product_Marshal,
}

cleanup :: proc(g: Game_Marshal) {
	for p in g.products {
		delete(p.name)
		delete(p.owned)
		delete(p.cost)
		delete(p.profit)
	}
	delete(g.products)
	delete(g.cash)
}

@test
unmarshal_json :: proc(t: ^testing.T) {
	g: Game_Marshal
	err := json.unmarshal(transmute([]u8)PRODUCTS, &g, json.DEFAULT_SPECIFICATION)
	defer cleanup(g)

	testing.expectf(t, err == nil,                                     "Expected `json.unmarshal` to return nil, got %v", err)
	testing.expectf(t, len(g.products) == len(original_data.products), "Expected %v products to have been unmarshaled, got %v", len(original_data.products), len(g.products))
	testing.expectf(t, original_data.cash == g.cash,                   "Expected cash to have been unmarshaled as %v, got %v", original_data.cash, g.cash)

	for p, i in g.products {
		testing.expect(t, p == original_data.products[i], "Producted unmarshaled improperly")
	}
}

@test
unmarshal_empty_struct :: proc(t: ^testing.T) {
	TestStruct :: struct {}
	test := make(map[string]TestStruct)
	input: = `{
		"test_1": {},
		"test_2": {}
	}`
	err := json.unmarshal(transmute([]u8)input, &test)
	defer {
		for k in test {
			delete(k)
		}
		delete(test)
	}
	testing.expect(t, err == nil, "Expected empty struct to unmarshal without error")
}

@test
surrogate :: proc(t: ^testing.T) {
	input := `+ + * 😃 - /`

	out, err := json.marshal(input)
	defer delete(out)
	testing.expectf(t, err == nil,    "Expected `json.marshal(%q)` to return a nil error, got %v", input, err)

	back: string
	uerr := json.unmarshal(out, &back)
	defer delete(back)
	testing.expectf(t, uerr == nil,   "Expected `json.unmarshal(%q)` to return a nil error, got %v", string(out), uerr)
	testing.expectf(t, back == input, "Expected `json.unmarshal(%q)` to return %q, got %v", string(out), input, uerr)
}

@test
marshal_escapes_map_keys_as_json :: proc(t: ^testing.T) {
	// Keys used to be quoted without `for_json`, so a rune outside the BMP came out as `\U0001f600`
	// and control characters as `\x01` or `\v`, none of which are valid JSON escapes.
	input: map[string]int
	defer delete(input)
	input["😀"]       = 1
	input["a\x01\vb"] = 2

	out, err := json.marshal(input, {spec = .JSON, sort_maps_by_key = true})
	defer delete(out)
	testing.expectf(t, err == nil, "Expected `json.marshal` to return a nil error, got %v", err)
	testing.expect_value(t, string(out), `{"a\u0001\u000bb":2,"\ud83d\ude00":1}`)

	back: map[string]int
	defer {
		for k in back { delete(k) }
		delete(back)
	}
	uerr := json.unmarshal(out, &back)
	testing.expectf(t, uerr == nil, "Expected `json.unmarshal(%q)` to return a nil error, got %v", string(out), uerr)
	testing.expect_value(t, len(back), len(input))
	for k, v in input {
		testing.expectf(t, back[k] == v, "Expected key %q to round-trip with value %v, got %v", k, v, back[k])
	}
}

@test
utf8_string_of_multibyte_characters :: proc(t: ^testing.T) {
	val, err := json.parse_string(`"🐛✅"`)
	defer json.destroy_value(val)
	testing.expectf(t, err == nil, "Expected `json.parse` to return nil, got %v", err)
}

@test
invalid_utf8_in_string_is_replaced :: proc(t: ^testing.T) {
	// Every one of these bytes is invalid on its own, so each is replaced by
	// U+FFFD, which is three bytes: the unquoted string is longer than the quoted
	// one, and the buffer has to have been sized for that.
	val, err := json.parse_string("\"\xff\xfe\xff\xfe\xff\xfe\xff\xfe\"")
	defer json.destroy_value(val)
	testing.expectf(t, err == nil, "Expected `json.parse_string` to return nil, got %v", err)

	str, ok := val.(json.String)
	testing.expect(t, ok, "Expected a string value")
	testing.expectf(t, len(str) == 8 * utf8.rune_size(utf8.RUNE_ERROR), "Expected eight replacement characters, got %d bytes", len(str))
	testing.expect(t, utf8.valid_string(string(str)), "Expected the unquoted string to be valid UTF-8")
	for r in string(str) {
		testing.expectf(t, r == utf8.RUNE_ERROR, "Expected every rune to be U+FFFD, got %U", r)
	}
}

@test
struct_with_ignore_tags :: proc(t: ^testing.T) {
	My_Struct :: struct {
		a: string `json:"-"`,
	}

	my_struct := My_Struct{
		a = "test",
	}

	my_struct_marshaled, marshal_err := json.marshal(my_struct)
	defer delete(my_struct_marshaled)

	testing.expectf(t, marshal_err == nil, "Expected `json.marshal` to return nil error, got %v", marshal_err)

	my_struct_json := transmute(string)my_struct_marshaled
	expected_json := `{}`

	testing.expectf(t, expected_json == my_struct_json, "Expected `json.marshal` to return %s, got %s", expected_json, my_struct_json)
}

@test
map_with_integer_keys :: proc(t: ^testing.T) {
	my_map := make(map[i32]string)
	defer delete_map(my_map)

	my_map[-1] = "a"
	my_map[0] = "b"
	my_map[42] = "c"
	my_map[99999999] = "d"

	marshaled_data, marshal_err := json.marshal(my_map)
	defer delete(marshaled_data)
	
	testing.expectf(t, marshal_err == nil, "Expected `json.marshal` to return nil error, got %v", marshal_err)

	my_map2 := make(map[i32]string)
	defer delete_map(my_map2)

	unmarshal_err := json.unmarshal(marshaled_data, &my_map2)
	defer for _, item in my_map2 {
		runtime.delete_string(item)
	}
	testing.expectf(t, unmarshal_err == nil, "Expected `json.unmarshal` to return nil, got %v", unmarshal_err)

	testing.expectf(t, len(my_map) == len(my_map2), "Expected %v map items to have been unmarshaled, got %v", len(my_map), len(my_map2))

	for key, item in my_map {
		testing.expectf(t, key in my_map2, "Expected key %v to be present in unmarshaled map", key)
		
		if key in my_map2 {
			testing.expectf(t, runtime.string_eq(item, my_map2[key]), "Expected value %s to be present in unmarshaled map", key)
		}
	}
}

@test
map_with_cstring_keys :: proc(t: ^testing.T) {
	my_map: map[cstring]int
	defer {
		for key in my_map {
			delete(key)
		}
		delete(my_map)
	}

	err := json.unmarshal_string(`{"a": 1, "with\tescape": 3}`, &my_map)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(my_map), 2)
	testing.expect_value(t, my_map["a"], 1)
	testing.expect_value(t, my_map["with\tescape"], 3)
}

@test
enumerated_array :: proc(t: ^testing.T) {
	Fruit :: enum { Apple, Banana, Pear }
	Fruit_Stock :: [Fruit]uint {
		.Apple = 14,
		.Banana = 3,
		.Pear = 513,
	}

	{ // test unmarshaling from array
		marshaled := "[14,3,513]"

		unmarshaled: [Fruit]uint
		err := json.unmarshal_string(marshaled, &unmarshaled)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, unmarshaled, Fruit_Stock)
	}

	Sparse_Fruit :: enum { Apple, Banana, Cherry = 23, Pear }
	Sparse_Fruit_Stock :: #partial #sparse [Sparse_Fruit]uint {
		.Apple = 14,
		.Banana = 3,
		.Pear = 513,
	}

	{ // test unmarshaling from object
		marshaled := `{"Apple":14,"Banana":3,"Cherry":0,"Pear":513}`

		unmarshaled: #sparse [Sparse_Fruit]uint
		err := json.unmarshal_string(marshaled, &unmarshaled)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, unmarshaled, Sparse_Fruit_Stock)
	}

	{ // test marshal -> unmarshal
		marshaled, err_marshal := json.marshal(Sparse_Fruit_Stock)
		defer delete(marshaled)
		testing.expect_value(t, err_marshal, nil)

		unmarshaled: #sparse [Sparse_Fruit]uint
		err_unmarshal := json.unmarshal(marshaled, &unmarshaled)
		testing.expect_value(t, err_unmarshal, nil)
		testing.expect_value(t, unmarshaled, Sparse_Fruit_Stock)
	}
}

@test
malformed_object_frees_its_partial_allocations :: proc(t: ^testing.T) {
	// parse_object_body allocates a key, then may fail in parse_colon or parse_value before that
	// key is ever inserted into the object. That proc's cleanup only walks the object, so such a
	// key was orphaned: unreachable to the caller, which is handed a nil Value, and therefore
	// leaked on every malformed input of this shape.
	//
	// JSON5 makes it reachable from ordinary input, since an unquoted ident is a legal key and
	// anything other than a colon after it fails -- but plain JSON leaks it too, via a quoted key.
	//
	// The test runner's memory tracking is what asserts this: each case only has to parse and be
	// destroyed without leaving an allocation behind.
	cases := []string {
		`{ broken not json`,
		`{"a" 1}`,
		`{"a": }`,
		`{"a": 1, "a": 2}`,
		`{"a": {"b" 1}}`,
		`{"a": {"b": {"c" 1}}}`,
		`{"a": [1, }`,
	}

	for spec in ([]json.Specification{.JSON, .JSON5}) {
		for src in cases {
			value, err := json.parse(transmute([]u8)src, spec = spec)
			testing.expectf(t, err != nil, "%q must not parse under %v", src, spec)
			json.destroy_value(value)
		}
	}
}

@test
unmarshal_skip_validation :: proc(t: ^testing.T) {
	// With `.Skip_Validation` the input is not checked up front: valid input gives the same result,
	// and a syntax error is reported where it is reached, as a specific error instead of
	// `.Invalid_Data`. None of the invalid cases below allocates anything that outlives the call,
	// so the test runner's memory tracking also checks that the error paths free their keys.
	Point :: struct {
		x, y: int,
	}
	Named :: struct {
		name: string,
		x:    int,
	}

	valid := `{"x": 1, "y": 2}`
	a, b: Point
	testing.expect_value(t, json.unmarshal_string(valid, &a), nil)
	testing.expect_value(t, json.unmarshal_string(valid, &b, flags = {.Skip_Validation}), nil)
	testing.expect_value(t, b, a)

	cases := []struct {
		src:  string,
		spec: json.Specification,
		err:  json.Error,
	}{
		{`{"x" 1}`,                   .JSON,  .Expected_Colon_After_Key},
		{`{"x": 1 "y": 2}`,           .JSON,  .Unexpected_Token},
		{`{"x": 1,`,                  .JSON,  .EOF},
		{`{"x": [1, 2`,               .JSON5, .EOF},
		{`{"x": nope}`,               .JSON5, .Unexpected_Token},
		{"{\"name\": \"a\tb\"}",      .JSON,  .Invalid_String},
		{"{\"other\": \"a\tb\"}",     .JSON,  .Invalid_String},
	}
	for c in cases {
		n: Named
		err := json.unmarshal_string(c.src, &n, c.spec)
		testing.expectf(t, err == json.Unmarshal_Data_Error.Invalid_Data, "%q: expected Invalid_Data when validating, got %v", c.src, err)
		err = json.unmarshal_string(c.src, &n, c.spec, flags = {.Skip_Validation})
		testing.expectf(t, err == c.err, "%q: expected %v with .Skip_Validation, got %v", c.src, c.err, err)
	}
}

@test
unmarshal_without_temporary_allocations :: proc(t: ^testing.T) {
	// Keys, enum names, numbers in strings and runes are read without allocating, so unmarshalling
	// into a struct holding none of `string`, `cstring`, slices or maps allocates nothing at all.
	Kind :: enum {A, B, C}
	Thing :: struct {
		x, y:   int,
		kind:   Kind,
		n:      int,
		f:      f32,
		r:      rune,
		counts: [Kind]int,
	}
	src := `{"x": 1, "\u0079": 2, "kind": "B", "n": "42", "f": "1.5", "r": "\u00e9", "counts": {"A": 1, "\u0043": 3}, "other": "skipped"}`

	for flags in ([]json.Unmarshal_Flags{{}, {.Skip_Validation}}) {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)

		thing: Thing
		err := json.unmarshal_string(src, &thing, allocator = mem.tracking_allocator(&track), flags = flags)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, thing, Thing{x = 1, y = 2, kind = .B, n = 42, f = 1.5, r = 'é', counts = {.A = 1, .B = 0, .C = 3}})
		testing.expectf(t, track.total_allocation_count == 0, "%v: expected no allocations, got %d", flags, track.total_allocation_count)
	}
}

@test
unmarshal_reserve_maps :: proc(t: ^testing.T) {
	// With `.Reserve_Maps` a map is allocated once at its final size, never grown, and holds the same
	// entries. The sizes straddle the points where an unreserved map grows.
	for n in ([]int{0, 1, 5, 6, 7, 12, 13, 24, 25, 100, 1000}) {
		b := strings.builder_make(context.temp_allocator)
		strings.write_byte(&b, '{')
		for i in 0..<n {
			fmt.sbprintf(&b, `%s"%d": %d`, "," if i > 0 else "", i*7, i)
		}
		strings.write_byte(&b, '}')
		src := strings.to_string(b)

		expected: map[int]int
		defer delete(expected)
		testing.expect_value(t, json.unmarshal_string(src, &expected), nil)

		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)

		reserved: map[int]int
		defer delete(reserved)
		testing.expect_value(t, json.unmarshal_string(src, &reserved, allocator = mem.tracking_allocator(&track), flags = {.Reserve_Maps}), nil)

		testing.expectf(t, len(reserved) == n, "%d entries: got %d", n, len(reserved))
		for k, v in expected {
			testing.expectf(t, reserved[k] == v, "%d entries: key %d is %d, expected %d", n, k, reserved[k], v)
		}
		testing.expectf(t, track.total_allocation_count == (1 if n > 0 else 0) && track.total_free_count == 0,
			"%d entries: expected one allocation and no frees, got %d and %d", n, track.total_allocation_count, track.total_free_count)
	}
}

Duplicate_Base :: struct {
	id: int,
}

Duplicate_Mid :: struct {
	using _: Duplicate_Base,
	mid:     int,
}

// `none` has no size, so it shares its offset with `after`, and `after` is past the first byte of the
// bitset that tracks the fields.
Duplicate_Fields :: struct {
	a:       int,
	b:       string `json:"B"`,
	using _: Duplicate_Mid,
	c, d, e: int,
	f, g, h: int,
	none:    struct{},
	after:   int,
}

@(test)
unmarshal_duplicate_fields :: proc(t: ^testing.T) {
	Case :: struct {
		src: string,
		err: json.Unmarshal_Error,
	}
	cases := []Case{
		{`{"a": 1, "a": 2}`,                        .Multiple_Use_Field},
		{`{"a": 1, "\u0061": 2}`,                   .Multiple_Use_Field},
		{`{"B": "x", "B": "y"}`,                    .Multiple_Use_Field},
		{`{"mid": 1, "mid": 2}`,                    .Multiple_Use_Field},
		{`{"id": 1, "mid": 2, "id": 3}`,            .Multiple_Use_Field},
		{`{"after": 1, "h": 2, "after": 3}`,        .Multiple_Use_Field},
		{`{"none": {}, "none": {}}`,                .Multiple_Use_Field},
		{`{"none": {}, "after": 1}`,                nil},
		{`{"id": 1, "mid": 2, "a": 3, "after": 4}`, nil},
		{`{"B": "x", "mid": 1, "id": 2, "a": 3}`,   nil},
		{`{"x": 1, "x": 2, "c": 3, "d": 4}`,        nil},
	}
	for c in cases {
		v: Duplicate_Fields
		err := json.unmarshal_string(c.src, &v)
		delete(v.b)
		testing.expectf(t, err == c.err, "%s: expected %v, got %v", c.src, c.err, err)
	}

	// Separate objects never share fields.
	list: []Duplicate_Fields
	testing.expect_value(t, json.unmarshal_string(`[{"a": 1, "id": 1}, {"a": 2, "id": 2}]`, &list), nil)
	testing.expect_value(t, len(list), 2)
	delete(list)

	// `.Allow_Duplicate_Fields` keeps the last value, as before.
	v: Duplicate_Fields
	testing.expect_value(t, json.unmarshal_string(`{"a": 1, "id": 2, "a": 3, "id": 4}`, &v, flags = {.Allow_Duplicate_Fields}), nil)
	testing.expect_value(t, v.a, 3)
	testing.expect_value(t, v.id, 4)
}

@(test)
unmarshal_many_unknown_keys :: proc(t: ^testing.T) {
	// Each key used to grow the stack by a bitset as large as the struct, which overflowed it.
	Big :: struct {
		id:  int,
		pad: [8192]byte,
	}

	b := strings.builder_make(context.temp_allocator)
	strings.write_string(&b, `{"id": 1`)
	for i in 0..<20_000 {
		fmt.sbprintf(&b, `, "k%d": 0`, i)
	}
	strings.write_byte(&b, '}')

	v := new(Big)
	defer free(v)
	testing.expect_value(t, json.unmarshal_string(strings.to_string(b), v), nil)
	testing.expect_value(t, v.id, 1)
}

@(test)
unmarshal_empty_key :: proc(t: ^testing.T) {
	// An empty key matches only a field tagged exactly `json:""`, never an untagged field nor one
	// whose tag only names options.
	Plain :: struct {
		a, b: int,
	}
	Tagged_Empty :: struct {
		a: int,
		o: int `json:",omitempty"`,
		e: int `json:""`,
	}
	Embedded :: struct {
		using _: Plain,
		c:       int,
	}
	Embedded_Empty :: struct {
		using _: Tagged_Empty,
		c:       int,
	}

	plain: Plain
	testing.expect_value(t, json.unmarshal_string(`{"": 1, "a": 2}`, &plain), nil)
	testing.expect_value(t, plain, Plain{a = 2})

	tagged: Tagged_Empty
	testing.expect_value(t, json.unmarshal_string(`{"": 5}`, &tagged), nil)
	testing.expect_value(t, tagged, Tagged_Empty{e = 5})

	// `e` is reached by its name and by the empty key, so both set the same field.
	tagged = {}
	err := json.unmarshal_string(`{"e": 1, "": 2}`, &tagged)
	testing.expectf(t, err == .Multiple_Use_Field, "expected Multiple_Use_Field, got %v", err)
	tagged = {}
	testing.expect_value(t, json.unmarshal_string(`{"e": 1, "": 2}`, &tagged, flags = {.Allow_Duplicate_Fields}), nil)
	testing.expect_value(t, tagged, Tagged_Empty{e = 2})

	embedded: Embedded
	testing.expect_value(t, json.unmarshal_string(`{"": {"a": 3}, "c": 4}`, &embedded), nil)
	testing.expect_value(t, embedded, Embedded{c = 4})

	embedded_empty: Embedded_Empty
	testing.expect_value(t, json.unmarshal_string(`{"": 9}`, &embedded_empty), nil)
	testing.expect_value(t, embedded_empty, Embedded_Empty{e = 9})
}

@(test)
marshal_floats :: proc(t: ^testing.T) {
	expect_marshal :: proc(t: ^testing.T, v: any, expected: string, spec := json.Specification.JSON, loc := #caller_location) {
		data, err := json.marshal(v, {spec = spec}, context.temp_allocator)
		testing.expectf(t, err == nil && string(data) == expected, "marshal %v (%v): expected %s, got %s (%v)", v, v.id, expected, string(data), err, loc = loc)
	}

	// The shortest text that reads back as the same value: fixed notation for 1e-6 <= |x| < 1e21,
	// with ".0" when it would otherwise read as an integer, and exponent notation outside it.
	F64_Case :: struct { v: f64, s: string }
	for c in ([]F64_Case{
		{0, "0.0"}, {math.copy_sign(f64(0), -1), "-0.0"}, {1, "1.0"}, {-1.5, "-1.5"}, {0.1, "0.1"},
		{1.0/3, "0.3333333333333333"}, {1e6, "1000000.0"}, {9007199254740992, "9007199254740992.0"},
		{1e20, "100000000000000000000.0"}, {1e21, "1e+21"}, {6.02214076e23, "6.02214076e+23"},
		{max(f64), "1.7976931348623157e+308"}, {1e-6, "0.000001"}, {1e-7, "1e-07"},
		{1.234e-17, "1.234e-17"}, {5e-324, "5e-324"}, {5894.866874872898, "5894.866874872898"},
	}) {
		expect_marshal(t, c.v, c.s)
	}

	F32_Case :: struct { v: f32, s: string }
	for c in ([]F32_Case{
		{0.1, "0.1"}, {1e-10, "1e-10"}, {16777216, "16777216.0"}, {3.4e38, "3.4e+38"}, {1e-6, "1e-06"},
	}) {
		expect_marshal(t, c.v, c.s)
	}

	F16_Case :: struct { v: f16, s: string }
	for c in ([]F16_Case{
		{0.1, "0.1"}, {6.1e-5, "0.000061"}, {65504, "65500.0"}, {6e-8, "6e-08"},
	}) {
		expect_marshal(t, c.v, c.s)
	}

	expect_marshal(t, complex64(complex(1, 0.1)), "[1.0, 0.1]")
	expect_marshal(t, complex(1e-20, -2), "[1e-20, -2.0]")

	// Infinity and NaN only exist in JSON5 and MJSON.
	inf, nan := math.inf_f64(1), math.nan_f64()
	for v in ([]f64{inf, -inf, nan}) {
		_, err := json.marshal(v, {}, context.temp_allocator)
		testing.expectf(t, err == .Non_Finite_Float, "marshal %v as JSON: expected Non_Finite_Float, got %v", v, err)
	}
	_, err := json.marshal(complex(1, inf), {}, context.temp_allocator)
	testing.expectf(t, err == .Non_Finite_Float, "marshal a complex with an infinite part as JSON: expected Non_Finite_Float, got %v", err)
	for spec in ([]json.Specification{.JSON5, .MJSON}) {
		expect_marshal(t, inf,       "Infinity",  spec)
		expect_marshal(t, -inf,      "-Infinity", spec)
		expect_marshal(t, nan,       "NaN",       spec)
		expect_marshal(t, f32(-inf), "-Infinity", spec)
	}

	// `unparse` writes a `json.Value` float the same way.
	text, unparse_err := json.unparse(json.Float(1), {}, context.temp_allocator)
	testing.expect_value(t, text, "1.0")
	testing.expect_value(t, unparse_err, nil)
	text, unparse_err = json.unparse(json.Float(1e-20), {}, context.temp_allocator)
	testing.expect_value(t, text, "1e-20")
	_, unparse_err = json.unparse(json.Float(inf), {}, context.temp_allocator)
	testing.expectf(t, unparse_err == .Non_Finite_Float, "unparse Infinity as JSON: expected Non_Finite_Float, got %v", unparse_err)
	text, unparse_err = json.unparse(json.Float(inf), {spec = .JSON5}, context.temp_allocator)
	testing.expect_value(t, text, "Infinity")

	free_all(context.temp_allocator)
}

@(test)
marshal_floats_round_trip :: proc(t: ^testing.T) {
	// Every finite value, written as JSON, must be valid JSON and read back bit for bit.
	round_trip :: proc(t: ^testing.T, v: $T, bits: $B) -> bool {
		data, err := json.marshal(v, {}, context.temp_allocator)
		if err != nil || !json.is_valid(data, .JSON) {
			testing.expectf(t, false, "marshal %v (bits %x): %s (%v) is not valid JSON", v, bits, string(data), err)
			return false
		}
		back: T
		uerr := json.unmarshal(data, &back, allocator = context.temp_allocator)
		if uerr != nil || transmute(B)back != bits {
			testing.expectf(t, false, "%v (bits %x) wrote %s and read back %v (%v)", v, bits, string(data), back, uerr)
			return false
		}
		return true
	}

	for _ in 0..<20_000 {
		defer free_all(context.temp_allocator)
		b64 := rand.uint64()
		b32 := u32(b64)
		b16 := u16(b64 >> 32)
		f64v, f32v, f16v := transmute(f64)b64, transmute(f32)b32, transmute(f16)b16
		if !math.is_nan(f64v) && !math.is_inf(f64v) && !round_trip(t, f64v, b64) {
			return
		}
		if !math.is_nan(f32v) && !math.is_inf(f32v) && !round_trip(t, f32v, b32) {
			return
		}
		if !math.is_nan(f16v) && !math.is_inf(f16v) && !round_trip(t, f16v, b16) {
			return
		}
	}

	// In JSON5 and MJSON the special values read back too.
	for spec in ([]json.Specification{.JSON5, .MJSON}) {
		for v in ([]f64{math.inf_f64(1), math.inf_f64(-1), math.nan_f64()}) {
			data, err := json.marshal(v, {spec = spec}, context.temp_allocator)
			back: f64
			uerr := json.unmarshal(data, &back, spec, context.temp_allocator)
			same := back == v || (math.is_nan(v) && math.is_nan(back))
			testing.expectf(t, err == nil && uerr == nil && same, "%v in %v: wrote %s (%v), read back %v (%v)", v, spec, string(data), err, back, uerr)
		}
	}
	free_all(context.temp_allocator)
}

@(test)
parse_integers_out_of_range :: proc(t: ^testing.T) {
	// An integer outside i64 wraps to 64 bits in a `Value`, the same as when it is unmarshalled
	// into an `i64`. Past i128 only the digits that fit in an i128 are read.
	Case :: struct {
		text:     string,
		spec:     json.Specification,
		expected: i64,
	}
	cases := [?]Case{
		{"9223372036854775807",    .JSON,  max(i64)},
		{"-9223372036854775808",   .JSON,  min(i64)},
		{"9223372036854775808",    .JSON,  min(i64)},
		{"-9223372036854775809",   .JSON,  max(i64)},
		{"18446744073709551615",   .JSON,  -1},
		{"18446744073709551616",   .JSON,  0},
		{"+18446744073709551617",  .JSON5, 1},
		{"0xFFFFFFFFFFFFFFFF",     .JSON5, -1},
		{"0x10000000000000000",    .MJSON, 0},
		{"1000000000000000000000000000000000000000000000", .JSON, 687399551400673280}, // 10^38, wrapped
	}
	only_integer :: proc(v: json.Value) -> (i: i64, ok: bool) {
		array := v.(json.Array) or_return
		if len(array) != 1 {
			return
		}
		return array[0].(json.Integer)
	}
	for c in cases {
		data := fmt.tprintf("[%s]", c.text)

		parsed, perr := json.parse_string(data, c.spec, true, context.temp_allocator)
		i, ok := only_integer(parsed)
		testing.expectf(t, perr == nil && ok && i == c.expected,
			"parse %s (%v): expected [%d], got %v (%v)", c.text, c.spec, c.expected, parsed, perr)

		value: json.Value
		err := json.unmarshal_string(data, &value, c.spec, context.temp_allocator)
		i, ok = only_integer(value)
		testing.expectf(t, err == nil && ok && i == c.expected,
			"unmarshal %s (%v) into json.Value: expected [%d], got %v (%v)", c.text, c.spec, c.expected, value, err)

		typed: []i64
		err = json.unmarshal_string(data, &typed, c.spec, context.temp_allocator)
		testing.expectf(t, err == nil && len(typed) == 1 && typed[0] == c.expected,
			"unmarshal %s (%v) into []i64: expected [%d], got %v (%v)", c.text, c.spec, c.expected, typed, err)
	}
	free_all(context.temp_allocator)
}

@(test)
keys_checked_like_values :: proc(t: ^testing.T) {
	// `is_valid` rejects a key that it would reject as a string value, and so does unmarshalling with
	// `.Skip_Validation`, with `.Invalid_String` as for such a value.
	Target :: struct {
		a, c: int,
	}
	Color :: enum {
		Red,
		Green,
	}
	bad := [?]string{
		"{\"a\tb\":1}",
		"{\"c\r\":5}",
		"{\"\xff\":1}",
		"{\"\\q\":1}",
		"{\"\\u12\":1}",
		"{\"a\":1,\"x\":{\"k\x01\":2}}", // in a value that is skipped
	}
	for s in bad {
		for spec in ([?]json.Specification{.JSON, .JSON5, .MJSON}) {
			testing.expectf(t, !json.is_valid(transmute([]byte)s, spec), "is_valid accepts %q (%v)", s, spec)

			target: Target
			err := json.unmarshal_string(s, &target, spec, context.temp_allocator)
			testing.expectf(t, err == json.Unmarshal_Data_Error.Invalid_Data, "unmarshal %q (%v): expected Invalid_Data, got %v", s, spec, err)

			err = json.unmarshal_string(s, &target, spec, context.temp_allocator, {.Skip_Validation})
			testing.expectf(t, err == json.Error.Invalid_String, "unmarshal %q (%v) into a struct with .Skip_Validation: expected Invalid_String, got %v", s, spec, err)

			m: map[string]json.Value
			err = json.unmarshal_string(s, &m, spec, context.temp_allocator, {.Skip_Validation})
			testing.expectf(t, err == json.Error.Invalid_String, "unmarshal %q (%v) into a map with .Skip_Validation: expected Invalid_String, got %v", s, spec, err)

			v: json.Value
			err = json.unmarshal_string(s, &v, spec, context.temp_allocator, {.Skip_Validation})
			testing.expectf(t, err == json.Error.Invalid_String, "unmarshal %q (%v) into a Value with .Skip_Validation: expected Invalid_String, got %v", s, spec, err)
		}
	}

	colors: [Color]int
	err := json.unmarshal_string("{\"Red\t\":1}", &colors, .JSON, context.temp_allocator, {.Skip_Validation})
	testing.expectf(t, err == json.Error.Invalid_String, "unmarshal into an enumerated array with .Skip_Validation: expected Invalid_String, got %v", err)

	// A key that ends unterminated at a newline, where the tokenizer ends it.
	unterminated := "[{\"a\n:1},\"x\"]"
	testing.expect(t, !json.is_valid(transmute([]byte)unterminated, .JSON))
	values: []json.Value
	err = json.unmarshal_string(unterminated, &values, .JSON, context.temp_allocator, {.Skip_Validation})
	testing.expectf(t, err == json.Error.Invalid_String, "unterminated key with .Skip_Validation: expected Invalid_String, got %v", err)

	Good :: struct {
		s:    string,
		spec: json.Specification,
	}
	good := [?]Good{{"{\"a\":1}", .JSON}, {"{\"\\u00e9\":1}", .JSON}, {"{'a':1}", .JSON5}, {"{a:1}", .JSON5}, {"{\"a\\\nb\":1}", .JSON5}}
	for g in good {
		testing.expectf(t, json.is_valid(transmute([]byte)g.s, g.spec), "is_valid rejects %q (%v)", g.s, g.spec)
	}
	free_all(context.temp_allocator)
}
