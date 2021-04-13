package odin_printer

import "core:odin/ast"
import "core:odin/tokenizer"
import "core:strings"
import "core:runtime"
import "core:fmt"
import "core:unicode/utf8"
import "core:mem"

Line_Type_Enum :: enum{Line_Comment, Value_Decl};

Line_Type :: bit_set[Line_Type_Enum];

Line :: struct {
    format_tokens: [dynamic] Format_Token,
    finalized: bool,
    used: bool,
	depth: int,
	types: Line_Type,
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
    lines:                [dynamic] Line, //need to look into a better data structure, one that can handle inserting lines rather than appending
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
	tabs = false,
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
	
	if len(file.decls) > 0 {
		p.lines = make([dynamic] Line, 0, (file.decls[len(file.decls)-1].end.line - file.decls[0].pos.line) * 2, context.temp_allocator);
	}

	set_line(p, 0);

	push_generic_token(p, .Package, 0);
	push_ident_token(p, file.pkg_name, 1);

    for decl in file.decls {
        visit_decl(p, cast(^ast.Decl)decl);
    }

	if len(p.comments) > 0 {
		infinite := p.comments[len(p.comments)-1].end;
		infinite.offset = 9999999;
		push_comments(p, infinite);
	}

	fix_lines(p);

    builder := strings.make_builder(p.allocator);

    last_line := 0;

    for line, line_index in p.lines {
        diff_line := line_index - last_line;

        for i := 0; i < diff_line; i += 1 {
            strings.write_byte(&builder, '\n');
        }

		if p.config.tabs {
			for i := 0; i < line.depth; i += 1 {
				strings.write_byte(&builder, '\t');
			}
		} else {
			for i := 0; i < line.depth * p.config.spaces; i += 1 {
				strings.write_byte(&builder, ' ');
			}
		}

		if p.debug {
			strings.write_string(&builder, fmt.tprintf("line %v: ", line_index));
		}

		for format_token in line.format_tokens {

			for i := 0; i < format_token.spaces_before; i += 1 {
				strings.write_byte(&builder, ' ');
			}

			strings.write_string(&builder, format_token.text);
		}
    
		last_line = line_index;
    }

    return strings.to_string(builder);
}

fix_lines :: proc(p: ^Printer) {
	align_comments(p);
	align_var_decls(p);
	align_blocks(p);
}

align_var_decls :: proc(p: ^Printer) {

}

align_blocks :: proc(p: ^Printer) {

}

align_comments :: proc(p: ^Printer) {
	
	Comment_Align_Info :: struct {
		length: int,
		begin: int,
		end: int,
	};

	comment_infos := make([dynamic]Comment_Align_Info, 0, context.temp_allocator);

	current_info: Comment_Align_Info;

	for line, line_index in p.lines {

		if len(line.format_tokens) <= 0 {
			continue;
		}

		if .Line_Comment in line.types {

			if current_info.end + 1 != line_index {

				if (current_info.begin != 0 && current_info.end != 0) || current_info.length > 0 {
					append(&comment_infos, current_info);
				}

				current_info.begin = line_index;
				current_info.end = line_index;
				current_info.length = 0;
			}

			length := 0;

			for format_token, i in line.format_tokens {

				if format_token.kind == .Comment {
					current_info.length = max(current_info.length, length);
					current_info.end = line_index;
				}

				length += format_token.spaces_before + len(format_token.text);
			}

		}

	}

	if (current_info.begin != 0 && current_info.end != 0) || current_info.length > 0 {
		append(&comment_infos, current_info);
	}

	for info in comment_infos {

		if info.begin == info.end || info.length == 0 {
			continue;
		}

		for i := info.begin; i <= info.end; i += 1 {

			l := p.lines[i];

			length := 0;

			for format_token, i in l.format_tokens {

				if format_token.kind == .Comment {
					if len(l.format_tokens) == 1 {
						l.format_tokens[i].spaces_before += info.length + 1;
					} else {
						l.format_tokens[i].spaces_before += info.length - length;
					}			
				}

				length += format_token.spaces_before + len(format_token.text);
			}

		}

	}

}