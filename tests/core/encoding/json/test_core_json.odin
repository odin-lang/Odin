package test_core_json

import "core:encoding/json"
import "core:testing"
import "core:mem/virtual"

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