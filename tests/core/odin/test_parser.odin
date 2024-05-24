package test_core_odin_parser

import "core:fmt"
import "core:odin/ast"
import "core:odin/parser"
import "core:os"
import "core:testing"


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
	test_parse_demo(&t)
	test_parse_bitfield(&t)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}


@test
test_parse_demo :: proc(t: ^testing.T) {
	pkg, ok := parser.parse_package_from_path("examples/demo")
	
	expect(t, ok == true, "parser.parse_package_from_path failed")

	for key, value in pkg.files {
		expect(t, value.syntax_error_count == 0, fmt.tprintf("%v should contain zero errors", key))
	}
}

@test
test_parse_bitfield :: proc(t: ^testing.T) {
	file := ast.File{
		fullpath = "test.odin",
		src = `
package main

Foo :: bit_field uint {}

Foo :: bit_field uint {hello: bool | 1}

Foo :: bit_field uint {
	hello: bool | 1,
	hello: bool | 5,
}

// Hellope 1.
Foo :: bit_field uint {
	// Hellope 2.
	hello: bool | 1,
	hello: bool | 5, // Hellope 3.
}
		`,
	}

	p := parser.default_parser()
	ok := parser.parse_file(&p, &file)
	expect(t, ok == true, "bad parse")
}
