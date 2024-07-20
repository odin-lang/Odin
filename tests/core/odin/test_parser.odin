package test_core_odin_parser

import "core:odin/ast"
import "core:odin/parser"
import "base:runtime"
import "core:testing"

@test
test_parse_demo :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	pkg, ok := parser.parse_package_from_path(ODIN_ROOT + "examples/demo")
	
	testing.expect(t, ok, "parser.parse_package_from_path failed")

	for key, value in pkg.files {
		testing.expectf(t, value.syntax_error_count == 0, "%v should contain zero errors", key)
	}
}

@test
test_parse_bitfield :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

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
	testing.expect(t, ok, "bad parse")
}