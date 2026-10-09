package test_core_odin_parser

import "base:runtime"

import "core:fmt"
import "core:log"
import "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"
import "core:os"
import "core:strings"
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
test_parse_base_core_vendor :: proc(t: ^testing.T) {
	for root in ([]string{ODIN_ROOT + "base", ODIN_ROOT + "core", ODIN_ROOT + "vendor"}) {
		w := os.walker_create(root)
		defer os.walker_destroy(&w)

		for info in os.walker_walk(&w) {
			if info.type != .Directory {
				continue
			}
			if root == ODIN_ROOT + "base" && (info.name == "builtin" || info.name == "intrinsics") {
				// documentation in pseudo-syntax, e.g. `proc(values: ...)`
				continue
			}

			context.allocator = context.temp_allocator
			runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

			pkg, ok := parser.collect_package(info.fullpath)
			if !testing.expectf(t, ok, "%v could not be read", info.fullpath) {
				continue
			}

			// one file at a time, as a directory can hold other packages in `#+build ignore` files
			p := parser.default_parser()
			for path, file in pkg.files {
				parser.parse_file(&p, file)
				testing.expectf(t, file.syntax_error_count == 0, "%v should contain zero errors", path)
			}
		}

		path, err := os.walker_error(&w)
		testing.expectf(t, err == nil, "failed walking %v: %v", path, err)
	}
}

@test
test_parse_error_recovery :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	decl_name :: proc(stmt: ^ast.Stmt) -> string {
		if vd, ok := stmt.derived.(^ast.Value_Decl); ok && len(vd.names) > 0 {
			if id, id_ok := vd.names[0].derived.(^ast.Ident); id_ok {
				return id.name
			}
		}
		return ""
	}

	// each is left unfinished above a declaration, which must survive along with everything after it
	Case :: struct {
		name, src: string,
		errors:    int,
	}
	cases := []Case{
		{"if, no condition",                   "\tif",                                      2},
		{"if, no body",                        "\tif pokemon.x > 0",                        1},
		{"if, `{` deleted",                    "\tif pokemon.x > 0\n\t\tfoo()\n\t}",        1},
		{"if, condition and `{` deleted",      "\tif\n\t\tfoo()\n\t}",                     1},
		{"when, no condition",                 "\twhen",                                    2},
		{"for, no condition",                  "\tfor",                                     1},
		{"for in, no expression",              "\tfor x in",                                2},
		{"for, no body",                       "\tfor i := 0; i < 10; i += 1",              1},
		{"for, `{` deleted",                   "\tfor i in 0..<3\n\t\tfoo()\n\t}",          1},
		{"switch, no tag",                     "\tswitch",                                  1},
		{"switch, no body",                    "\tswitch pokemon",                          1},
		{"switch, `{` deleted",                "\tswitch e\n\tcase .A:\n\t\tfoo()\n\t}",    1},
		{"switch, tag and `{` deleted",        "\tswitch\n\tcase .A:\n\t\tfoo()\n\t}",      1},
		{"selector, no field",                 "\tpokemon.",                                1},
		{"selector chain, no field",           "\tpokemon.a.",                              1},
		{"arrow, no field",                    "\tpokemon->",                               1},
		{"selector in call, no field",         "\tfoo(pokemon.)",                           1},
		{"return, selector no field",          "\treturn pokemon.",                         1},
		{"call, unclosed",                     "\tfoo(",                                    1},
		{"call, unclosed after an argument",   "\tfoo(pokemon, ",                           1},
		{"call, unclosed before `}`",          "\tif true {\n\t\tfoo(pokemon,\n\t}",        1},
		{"assign, no value",                   "\tx := ",                                   1},
		{"assign, no value before `}`",        "\tif true {\n\t\tx := \n\t}",               1},
		{"binary, no right-hand side",         "\ty := pokemon +",                          1},
		{"compound literal, unclosed",         "\tz := Snorlax{",                           1},
		{"compound literal, `{` deleted",      "\tz := []Snorlax\n\t\tSnorlax{},\n\t\tSnorlax{},\n\t}", 1},
		{"compound literal, `{` deleted, one", "\tz := Snorlax\n\t\ta = 1\n\t}",           1},
		{"return, literal `{` deleted",        "\treturn Snorlax\n\t\ta = 1,\n\t}",        1},
		{"index, unclosed",                    "\tw := arr[",                               2},
	}

	for c in cases {
		src := strings.concatenate({
			"package p\n\ntest :: proc() {\n\tpokemon: Snorlax\n",
			c.src,
			"\n\tSnorlax :: struct {}\n\tafter_local := 1\n}\n\nafter :: proc() {}\n",
		})
		file := ast.File{src = src, fullpath = c.name}
		p := parser.default_parser()
		p.err = nil
		parser.parse_file(&p, &file)

		testing.expectf(t, file.syntax_error_count == c.errors, "%s: expected %d errors, got %d", c.name, c.errors, file.syntax_error_count)
		if !testing.expectf(t, len(file.decls) == 2 && decl_name(file.decls[1]) == "after", "%s: the procedure after it did not survive", c.name) {
			continue
		}
		test := file.decls[0].derived.(^ast.Value_Decl).values[0].derived.(^ast.Proc_Lit).body.derived.(^ast.Block_Stmt)
		n := len(test.stmts)
		testing.expectf(t, n >= 2 && decl_name(test.stmts[n-2]) == "Snorlax" && decl_name(test.stmts[n-1]) == "after_local", "%s: the declarations after it did not survive", c.name)
	}
}

@test
test_parse_error_recovery_unclosed_block :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// a declaration starting a line ends the blocks left unclosed in the procedure above it
	sources := []string{
		"package p\n\ntest :: proc() {\n\tif x {\n\t\tfoo()\n}\n\nafter :: proc() {}\n",
		"package p\n\ntest :: proc() -> Foo {\n\treturn Foo{a = 1, b =\n}\n\n@(require_results)\nafter :: proc() -> int { return 0 }\n",
	}
	for src, i in sources {
		file := ast.File{src = src, fullpath = "test"}
		p := parser.default_parser()
		p.err = nil
		parser.parse_file(&p, &file)

		if !testing.expectf(t, len(file.decls) == 2, "source %d: expected 2 declarations, got %d", i, len(file.decls)) {
			continue
		}
		vd, ok := file.decls[1].derived.(^ast.Value_Decl)
		testing.expectf(t, ok && vd.names[0].derived.(^ast.Ident).name == "after", "source %d: the procedure after it did not survive", i)
	}
}

@test
test_parse_error_recovery_case_clause :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	// an unfinished `case .` must not take the next clause
	src := `package p

test :: proc() {
	switch e {
	case .
	case .A, .B:
	}
}
`
	file := ast.File{src = src, fullpath = "test"}
	p := parser.default_parser()
	p.err = nil
	parser.parse_file(&p, &file)

	testing.expect_value(t, file.syntax_error_count, 2)
	test := file.decls[0].derived.(^ast.Value_Decl).values[0].derived.(^ast.Proc_Lit).body.derived.(^ast.Block_Stmt)
	sw := test.stmts[0].derived.(^ast.Switch_Stmt)
	clauses := sw.body.derived.(^ast.Block_Stmt).stmts
	if !testing.expect_value(t, len(clauses), 2) {
		return
	}
	first  := clauses[0].derived.(^ast.Case_Clause)
	second := clauses[1].derived.(^ast.Case_Clause)
	testing.expect_value(t, len(first.list), 1)
	testing.expect_value(t, first.list[0].derived.(^ast.Implicit_Selector_Expr).field.name, "_")
	testing.expect_value(t, len(second.list), 2)
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

@test
test_parse_multiline_triple_quoted_string :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	file := ast.File{
		fullpath = "test.odin",
		src = `
			package main

			my_func :: proc (cond: bool, a: string, b: string) -> string {
					_ := "Usual string"
					out := """
						This is a
						multiline string
					"""
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
test_parse_multiline_triple_ticked_string :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	file := ast.File{
		fullpath = "test.odin",
		src = """
			package main

			my_func :: proc (cond: bool, a: string, b: string) -> string {
					_ := `Usual raw string`
					out := ```
						This is a
						multiline raw string
					```
					return out
			}
		""",
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
