package test_core_json

import "core:encoding/json"
import "core:testing"
import "core:fmt"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
    expect  :: testing.expect
    log     :: testing.log
} else {
    expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        TEST_count += 1
        if !condition {
            TEST_fail += 1
            fmt.println(message)
            return
        }
        fmt.println(" PASS")
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

    fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
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

	expect(t, err == .None, "expected json error to be none")
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
	
	expect(t, err == .None, "expected json error to be none")
}
