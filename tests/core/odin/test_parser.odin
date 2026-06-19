package test_core_odin_parser

import "base:runtime"

import "core:fmt"
import "core:log"
import "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"
import "core:testing"

parse_file_source :: proc(t: ^testing.T, src: string) -> (file: ast.File, ok: bool) {
	file = ast.File{
		fullpath = "test.odin",
		src      = src,
	}

	p := parser.default_parser()
	ok = parser.parse_file(&p, &file)

	testing.expectf(t, ok, "expected parse_file to succeed, got %v syntax errors", file.syntax_error_count)
	return
}

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
	hello: bool | 1 ` + "`fmt:\"-\"`" + `,
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

	p.err = proc(pos: tokenizer.Pos, format: string, args: ..any) {
		message := fmt.tprintf(format, ..args)
		log.errorf("%s(%d:%d): %s", pos.file, pos.line, pos.column, message)
	}

	p.warn = proc(pos: tokenizer.Pos, format: string, args: ..any) {
		message := fmt.tprintf(format, ..args)
		log.warnf("%s(%d:%d): %s", pos.file, pos.line, pos.column, message)
	}

	ok := parser.parse_file(&p, &file)
	testing.expect(t, ok, "bad parse")
}

@test
test_parse_multiline_if_condition :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	multiline_file, multiline_ok := parse_file_source(t, `
package main

import "core:fmt"

f :: proc() {
	x := 1
	if (x == 2
		|| x == 3) {
		fmt.println("1")
	}
	fmt.println("0")
}
`)
	testing.expect(t, multiline_ok, "multiline if condition should parse")
	testing.expectf(t, multiline_file.syntax_error_count == 0, "multiline if condition produced %v syntax errors", multiline_file.syntax_error_count)

	single_line_file, single_line_ok := parse_file_source(t, `
package main

import "core:fmt"

f :: proc() {
	x := 1
	if (x == 2 || x == 3) {
		fmt.println("1")
	}
	fmt.println("0")
}
`)
	testing.expect(t, single_line_ok, "single-line if condition should parse")
	testing.expectf(t, single_line_file.syntax_error_count == 0, "single-line if condition produced %v syntax errors", single_line_file.syntax_error_count)
}

@test
test_parse_parser :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	pkg, ok := parser.parse_package_from_path(ODIN_ROOT + "core/odin/parser")
	
	testing.expect(t, ok, "parser.parse_package_from_path failed")

	for key, value in pkg.files {
		testing.expectf(t, value.syntax_error_count == 0, "%v should contain zero errors", key)
	}
}

@test
test_parse_stb_image :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	pkg, ok := parser.parse_package_from_path(ODIN_ROOT + "vendor/stb/image")
	
	testing.expect(t, ok, "parser.parse_package_from_path failed")

	for key, value in pkg.files {
		testing.expectf(t, value.syntax_error_count == 0, "%v should contain zero errors", key)
	}
}
