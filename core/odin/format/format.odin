package odin_format

import "core:odin/printer"
import "core:odin/parser"
import "core:odin/ast"

default_style := printer.default_style;

simplify :: proc(file: ^ast.File) {

}

format :: proc(source: [] u8, config: printer.Config, allocator := context.allocator) -> ([] u8, bool) {

    pkg := ast.Package {
        kind = .Normal,
    };

    file := ast.File {
        pkg = &pkg,
        src = source,
    };

    p := parser.default_parser();

    ok := parser.parse_file(&p, &file);

    if !ok || file.syntax_error_count > 0  {
        return {}, false;
    }

    prnt := printer.make_printer(config, allocator);

    return transmute([]u8) printer.print(&prnt, &file), true;
}