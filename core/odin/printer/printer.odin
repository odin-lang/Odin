package odin_printer

import "core:odin/ast"
import "core:odin/tokenizer"
import "core:strings"
import "core:runtime"
import "core:fmt"
import "core:unicode/utf8"
import "core:mem"

Line :: struct {
    format_tokens: [dynamic] Format_Token,
    finalized: bool,
    used: bool,
	depth: int,
}

Format_Token :: struct {
    kind: tokenizer.Token_Kind,
    text: string,
    spaces_before: int,
}

Printer :: struct {
	string_builder:       strings.Builder,
	config:               Config,
	depth:                int, //the identation depth
	comments:             [dynamic]^ast.Comment_Group,
	latest_comment_index: int,
	allocator:            mem.Allocator,
	file:                 ^ast.File,
    source_position:      tokenizer.Pos,
	last_source_position: tokenizer.Pos,
    lines:                map [int]^Line,
    skip_semicolon:       bool,
	current_line:         ^Line,
	current_line_index:   int,
	last_line_index:      int,
	last_token:           ^Format_Token,
	merge_next_token:     bool,
	space_next_token:     bool,
	debug:                bool,
}

Config :: struct {
	spaces:               int, //Spaces per indentation
	newline_limit:        int, //The limit of newlines between statements and declarations.
	tabs:                 bool, //Enable or disable tabs
	convert_do:           bool, //Convert all do statements to brace blocks
	semicolons:           bool, //Enable semicolons
	split_multiple_stmts: bool,
	brace_style:          Brace_Style,
	align_assignments:    bool,
	align_style:          Alignment_Style,
	indent_cases:         bool,
}

Brace_Style :: enum {
	_1TBS,
	Allman,
	Stroustrup,
	K_And_R,
}

Block_Type :: enum {
	None,
	If_Stmt,
	Proc,
	Generic,
	Comp_Lit,
}

Alignment_Style :: enum {
	Align_On_Colon_And_Equals,
	Align_On_Type_And_Equals,
}

default_style := Config {
	spaces = 4,
	newline_limit = 2,
	convert_do = false,
	semicolons = true,
	tabs = true,
	brace_style = ._1TBS,
	split_multiple_stmts = true,
	align_assignments = true,
	align_style = .Align_On_Type_And_Equals,
	indent_cases = false,
};

make_printer :: proc(config: Config, allocator := context.allocator) -> Printer {
	return {
		config = config,
		allocator = allocator,
		debug = false,
	};
}

print :: proc(p: ^Printer, file: ^ast.File) -> string {

	p.comments = file.comments;

    for decl in file.decls {
        visit_decl(p, cast(^ast.Decl)decl);
    }

	fix_lines(p);

    builder := strings.make_builder(p.allocator);

    last_line := 0;

    for key, value in p.lines {
        diff_line := key - last_line;
        
        for i := 0; i < diff_line; i += 1 {
            strings.write_byte(&builder, '\n');
        }

		for i := 0; i < value.depth * 4; i += 1 {
			strings.write_byte(&builder, ' ');
		}

		if p.debug {
			strings.write_string(&builder, fmt.tprintf("line %v: ", key));
		}

		for format_token in value.format_tokens {

			for i := 0; i < format_token.spaces_before; i += 1 {
				strings.write_byte(&builder, ' ');
			}

			strings.write_string(&builder, format_token.text);
		}
    
		last_line = key;
    }

    return strings.to_string(builder);
}

fix_lines :: proc(p: ^Printer) {

	for key, value in p.lines {

		if len(value.format_tokens) <= 0 {
			continue;
		}



	}


}
