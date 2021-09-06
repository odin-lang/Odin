package odin_format

import "core:odin/printer"
import "core:odin/parser"
import "core:odin/ast"

default_style := printer.default_style

simplify :: proc(file: ^ast.File) {

}

format :: proc(filepath: string, source: string, config: printer.Config, parser_flags := parser.Flags{}, allocator := context.allocator) -> (string, bool) {
	config := config

	pkg := ast.Package {
		kind = .Normal,
	}

	file := ast.File {
		pkg = &pkg,
		src = source,
		fullpath = filepath,
	}

	config.newline_limit      = clamp(config.newline_limit, 0, 16)
	config.spaces             = clamp(config.spaces, 1, 16)
	config.align_length_break = clamp(config.align_length_break, 0, 64)

	p := parser.default_parser(parser_flags)

	ok := parser.parse_file(&p, &file)

	if !ok || file.syntax_error_count > 0  {
		return {}, false
	}

	prnt := printer.make_printer(config, allocator)

	return printer.print(&prnt, &file), true
}
