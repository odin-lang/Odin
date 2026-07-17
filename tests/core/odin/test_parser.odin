package test_core_odin_parser

import "base:runtime"

import "core:fmt"
import "core:log"
import "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"
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

@test
test_parse_multiline_ternary :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	file := ast.File{
		fullpath = "test.odin",
		src = `
package main

my_func :: proc (cond: bool, a: string, b: string) -> string {
    out := (
        cond
        ? a
        : b
    )
    return out
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
	testing.expect(t, file.syntax_error_count == 0, "should contain zero errors")
}


@test
test_parse_multiline_ternary_infix_with_comment :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	file := ast.File{
		fullpath = "test.odin",
		src = `
			package main

			my_func :: proc (cond: bool, a: string, b: string) -> string {
					out := (
							cond
							? a // This is a comment!
							: b
					)
					return out
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
	testing.expect(t, file.syntax_error_count == 0, "should contain zero errors")
}

@test
test_parse_ternary_if_statements_with_comment :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	file := ast.File{
		fullpath = "test.odin",
		src = `
			package main

			my_func :: proc (cond: bool, a: string, b: string) -> string {
					out := (
							cond
							if a // This is a comment!
							else b
					)
					return out
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
	testing.expect(t, file.syntax_error_count == 0, "should contain zero errors")
}
