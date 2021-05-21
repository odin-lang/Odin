package odin_format

import "core:odin/printer"
import "core:odin/parser"
import "core:odin/ast"

default_style := printer.default_style;

simplify :: proc(file: ^ast.File) {

}

format :: proc(source: string, config: printer.Config, parser_flags := parser.Flags{}, allocator := context.allocator) -> (string, bool) {
	pkg := ast.Package {
		kind = .Normal,
	};

	file := ast.File {
		pkg = &pkg,
		src = source,
	};

	p := parser.default_parser(parser_flags);

	ok := parser.parse_file(&p, &file);

	if !ok || file.syntax_error_count > 0  {
		return {}, false;
	}

	prnt := printer.make_printer(config, allocator);

	return printer.print(&prnt, &file), true;
}
