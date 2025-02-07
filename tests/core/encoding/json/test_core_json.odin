package test_core_json

import "core:encoding/json"
import "core:testing"
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
utf8_string_of_multibyte_characters :: proc(t: ^testing.T) {
	val, err := json.parse_string(`"🐛✅"`)
	defer json.destroy_value(val)
	testing.expectf(t, err == nil, "Expected `json.parse` to return nil, got %v", err)
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
unparse_json_schema :: proc(t: ^testing.T) {
	
	json_schema: json.Value = json.Object{
		"title" = "example",
		"description" = "example json schema for unparse test",
		"type" = "object",
		"properties" = json.Object{
			"id" = json.Object{"type" = "integer"},
			"name" = json.Object{"type" = "string"},
			"is_valid" = json.Object{"type" = "boolean"},
			"tags" = json.Object{
				"type" = "array",
				"items" = json.Object{"type" = "string"},
			},
			"also" = json.Object{
				"integer" = 42,
				"float" = 3.1415,
				"bool" = false,
				"null" = nil,
				"array" = json.Array{42, 3.1415, false, nil, "string"},
			},
		},
	}

	// having fun cleaning up json literals
	defer {
		delete(json_schema.(json.Object)["properties"].(json.Object)["also"].(json.Object)["array"].(json.Array))
		delete(json_schema.(json.Object)["properties"].(json.Object)["tags"].(json.Object)["items"].(json.Object))
		for k, &v in json_schema.(json.Object)["properties"].(json.Object) {
			delete(v.(json.Object))
		}
		delete(json_schema.(json.Object)["properties"].(json.Object))
		delete(json_schema.(json.Object))
	}

	is_error :: proc(t: ^testing.T, E: $Error_Type, fn: string) -> bool {
		testing.expectf(t, E == nil, "%s failed with error: %v", fn, E)
		return E != nil
	}

	unparsed_json_schema, unparse_err := json.unparse(json_schema, json.Marshal_Options{sort_maps_by_key=true})
	if is_error(t, unparse_err, "json.unparse(json_schema)") do return
	defer delete(unparsed_json_schema)

	parsed_json_schema, parse_err := json.parse(unparsed_json_schema, parse_integers=true)
	if is_error(t, parse_err, "json.parse(unparsed_json_schema)") do return 
	defer json.destroy_value(parsed_json_schema)

	buf1, marshal_err1 := json.marshal(json_schema, json.Marshal_Options{sort_maps_by_key=true})
	if is_error(t, marshal_err1, "json.marshal(json_schema)") do return
	defer delete(buf1)
	
	buf2, marshal_err2 := json.marshal(parsed_json_schema, json.Marshal_Options{sort_maps_by_key=true})
	if is_error(t, marshal_err2, "json.marshal(parsed_json_schema)") do return
	defer delete(buf2)
	
	marshaled_parsed_json_schema := string(buf2)
	testing.expect_value(t, marshaled_parsed_json_schema, string(buf1))
	testing.expect_value(t, string(unparsed_json_schema), string(buf1))
}
