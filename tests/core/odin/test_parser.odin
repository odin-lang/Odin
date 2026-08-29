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
	testing.expect(t, file.syntax_error_count == 0, "should contain zero errors")
}

@test
test_parse_struct_field_comments :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	expect_comments :: proc (t: ^testing.T, docs: ^ast.Comment_Group, expected: []string, loc := #caller_location) {
		if expected == nil {
			testing.expect_value(t, docs, nil, loc)
		} else {
			testing.expect(t, docs != nil, "comment should not be nil", loc=loc)
			testing.expect_value(t, len(docs.list), len(expected), loc)
			for tok, i in docs.list {
				testing.expect_value(t, tok.text, expected[i], loc)
			}
		}
	}

	file := ast.File{
		fullpath = "test.odin",
		src = `
package main

// foo doc
Foo :: struct {
	// doc1
	a: int, // c1
	b: int, // c2
	// not included

	// doc2
	// doc3
	c, d: int,  /* c3
c4 */

	e: struct {
	} // c5
	// not included
}

// not included

Bar :: struct {x, y: int /* c4 */} // after`,
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

	testing.expect_value(t, len(file.decls), 2)

	foo_decl := file.decls[0].derived.(^ast.Value_Decl)
	expect_comments(t, foo_decl.docs,    {"// foo doc"})
	expect_comments(t, foo_decl.comment, nil)

	foo := foo_decl.values[0].derived.(^ast.Struct_Type)
	testing.expect_value(t, len(foo.fields.list), 4)
	expect_comments(t, foo.fields.list[0].docs,    {"// doc1"})
	expect_comments(t, foo.fields.list[0].comment, {"// c1"})
	expect_comments(t, foo.fields.list[1].docs,    nil)
	expect_comments(t, foo.fields.list[1].comment, {"// c2"})
	expect_comments(t, foo.fields.list[2].docs,    {"// doc2", "// doc3"})
	expect_comments(t, foo.fields.list[2].comment, {"/* c3\nc4 */"})
	expect_comments(t, foo.fields.list[3].docs,    nil)
	expect_comments(t, foo.fields.list[3].comment, {"// c5"})

	bar_decl := file.decls[1].derived.(^ast.Value_Decl)
	expect_comments(t, bar_decl.docs,    nil)
	expect_comments(t, bar_decl.comment, {"// after"})

	bar := bar_decl.values[0].derived.(^ast.Struct_Type)
	testing.expect_value(t, len(bar.fields.list), 1)
	expect_comments(t, bar.fields.list[0].docs,    nil)
	expect_comments(t, bar.fields.list[0].comment, {"/* c4 */"})
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
