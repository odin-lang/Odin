package test_core_json

import "core:encoding/json"
import "core:testing"
import "core:fmt"
import "core:os"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

main :: proc() {
	t := testing.T{}

	parse_json(&t)
	marshal_json(&t)
	unmarshal_json(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

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
   
	_, err := json.parse(transmute([]u8)json_data)

	msg := fmt.tprintf("Expected `json.parse` to return nil, got %v", err)
	expect(t, err == nil, msg)
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
   
	_, err := json.marshal(my_struct)
	msg := fmt.tprintf("Expected `json.marshal` to return nil, got %v", err)
	expect(t, err == nil, msg)
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

	msg := fmt.tprintf("Expected `json.unmarshal` to return nil, got %v", err)
	expect(t, err == nil, msg)

	msg = fmt.tprintf("Expected %v products to have been unmarshaled, got %v", len(original_data.products), len(g.products))
	expect(t, len(g.products) == len(original_data.products), msg)

	msg = fmt.tprintf("Expected cash to have been unmarshaled as %v, got %v", original_data.cash, g.cash)
	expect(t, original_data.cash == g.cash, msg)

	for p, i in g.products {
		expect(t, p == original_data.products[i], "Producted unmarshaled improperly")
	}
}