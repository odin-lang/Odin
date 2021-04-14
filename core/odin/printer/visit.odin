package odin_printer

import "core:odin/ast"
import "core:odin/tokenizer"
import "core:strings"
import "core:runtime"
import "core:fmt"
import "core:unicode/utf8"
import "core:mem"
import "core:sort"

//right the attribute order is not linearly parsed(bug?)
@(private)
sort_attribute :: proc(s: ^[dynamic]^ast.Attribute) -> sort.Interface {
	return sort.Interface {
		collection = rawptr(s),
		len = proc(it: sort.Interface) -> int {
			s := (^[dynamic]^ast.Attribute)(it.collection);
			return len(s^);
		},
		less = proc(it: sort.Interface, i, j: int) -> bool {
			s := (^[dynamic]^ast.Attribute)(it.collection);
			return s[i].pos.offset < s[j].pos.offset;
		},
		swap = proc(it: sort.Interface, i, j: int) {
			s := (^[dynamic]^ast.Attribute)(it.collection);
			s[i], s[j] = s[j], s[i];
		},
	};
}

@(private)
comment_before_position :: proc(p: ^Printer, pos: tokenizer.Pos) -> bool {

	if len(p.comments) <= p.latest_comment_index {
		return false;
	}

	comment := p.comments[p.latest_comment_index];

	return comment.pos.offset < pos.offset;
}

@(private)
next_comment_group :: proc(p: ^Printer) {
	p.latest_comment_index += 1;
}
 
@(private) 
push_comment :: proc(p: ^Printer, comment: tokenizer.Token) -> int {

	if len(comment.text) == 0 {
		return 0;
	}

	if comment.text[0] == '/' && comment.text[1] == '/' {
		format_token := Format_Token {
			spaces_before = 1,
			kind = .Comment,
			text = comment.text,
		};

		if len(p.current_line.format_tokens) == 0 {
			format_token.spaces_before = 0;
		}

		if !p.current_line.used {
			p.current_line.used = true;
			p.current_line.depth = p.depth;
		}

		append(&p.current_line.format_tokens, format_token); 
		p.last_token = &p.current_line.format_tokens[len(p.current_line.format_tokens)-1];

		hint_current_line(p, {.Line_Comment});

		return 0;
	} else {

		builder := strings.make_builder(context.temp_allocator);

		c_len := len(comment.text);
		trim_space := true;

		multilines: [dynamic] string;

		for i := 0; i < len(comment.text); i += 1 {

			c := comment.text[i];

			if c != ' ' && c != '\t' {
				trim_space = false;
			}

			if (c == ' ' || c == '\t' || c == '\n') && trim_space {
				continue;
			} else if c == 13 && comment.text[min(c_len - 1, i + 1)] == 10 {
				append(&multilines, strings.to_string(builder));
				builder = strings.make_builder(context.temp_allocator);
				trim_space = true;
				i += 1;
			} else if c == 10 {
				append(&multilines, strings.to_string(builder));
				builder = strings.make_builder(context.temp_allocator);
				trim_space = true;
			} else if c == '/' && comment.text[min(c_len - 1, i + 1)] == '*' {
				strings.write_string(&builder, "/*");
				trim_space = true;
				p.depth += 1;
				i += 1;
			} else if c == '*' && comment.text[min(c_len - 1, i + 1)] == '/' {
				p.depth -= 1;
				trim_space = true;
				strings.write_string(&builder, "*/");
				i += 1;
			} else {
				strings.write_byte(&builder, c);
			}

		}

		if strings.builder_len(builder) > 0 {
			append(&multilines, strings.to_string(builder));
		}

		for line in multilines {
			format_token := Format_Token {
				spaces_before = 1,
				kind = .Comment,
				text = line,
			};

			if len(p.current_line.format_tokens) == 0 {
				format_token.spaces_before = 0;
			}

			if strings.contains(line, "*/")  {
				unindent(p);
			}

			if !p.current_line.used {
				p.current_line.used = true;
				p.current_line.depth = p.depth;
			}

			append(&p.current_line.format_tokens, format_token); 
			p.last_token = &p.current_line.format_tokens[len(p.current_line.format_tokens)-1];

			if strings.contains(line, "/*") {
				indent(p);
			} 

			newline_position(p, 1);
		}

		return len(multilines);
	}
}

@(private)
push_comments :: proc(p: ^Printer, pos: tokenizer.Pos) {

	prev_comment: ^tokenizer.Token;
	prev_comment_lines: int;

	for comment_before_position(p, pos) {

		comment_group := p.comments[p.latest_comment_index];

		if prev_comment == nil {
			lines := comment_group.pos.line - p.last_source_position.line;
			set_line(p, p.last_line_index + min(p.config.newline_limit, lines));
		}

		for comment, i in comment_group.list {

			if prev_comment != nil && p.last_source_position.line != comment.pos.line {
			 	newline_position(p, min(p.config.newline_limit, comment.pos.line - prev_comment.pos.line - prev_comment_lines));
			}

			prev_comment_lines = push_comment(p, comment);
			prev_comment = &comment_group.list[i];
		}

		next_comment_group(p);
	}
 
	if prev_comment != nil {
		newline_position(p, min(p.config.newline_limit, p.source_position.line - prev_comment.pos.line));
	}
}

@(private)
append_format_token :: proc(p: ^Printer, format_token: Format_Token) -> ^Format_Token {

	format_token := format_token;

	if p.last_token != nil && (p.last_token.kind == .Ellipsis  || p.last_token.kind == .Range_Half || 
							   p.last_token.kind == .Open_Paren || p.last_token.kind == .Period ||
							   p.last_token.kind == .Open_Brace || p.last_token.kind == .Open_Bracket) {
		format_token.spaces_before = 0;
	} else if p.merge_next_token {
		format_token.spaces_before = 0;
		p.merge_next_token = false;
	} else if p.space_next_token {
		format_token.spaces_before = 1;
		p.space_next_token = false;
	}

	push_comments(p, p.source_position);

	unwrapped_line := p.current_line;

	if !unwrapped_line.used {
    	unwrapped_line.used = true;
		unwrapped_line.depth = p.depth;
	}

	if len(unwrapped_line.format_tokens) == 0 && format_token.spaces_before == 1 {
		format_token.spaces_before = 0;
	}
    
	p.last_source_position = p.source_position;
	p.last_line_index = p.current_line_index;

	append(&unwrapped_line.format_tokens, format_token); 
	return &unwrapped_line.format_tokens[len(unwrapped_line.format_tokens)-1];
}

@(private)
push_format_token :: proc(p: ^Printer, format_token: Format_Token) {
	p.last_token = append_format_token(p, format_token);
}

@(private)
push_generic_token :: proc(p: ^Printer, kind: tokenizer.Token_Kind, spaces_before: int, value := "") {
 
    format_token := Format_Token {
        spaces_before = spaces_before,
        kind = kind,
        text = tokenizer.tokens[kind],
    };

	if value != "" {
		format_token.text = value;
	}

    p.last_token = append_format_token(p, format_token);
}

@(private)
push_string_token :: proc(p: ^Printer, text: string, spaces_before: int) {

    format_token := Format_Token {
        spaces_before = spaces_before,
        kind = .String,
        text = text,
    };

    p.last_token = append_format_token(p, format_token);
}

@(private)
push_ident_token :: proc(p: ^Printer, text: string, spaces_before: int) {

    format_token := Format_Token {
        spaces_before = spaces_before,
        kind = .Ident,
        text = text,
    };

    p.last_token = append_format_token(p, format_token); 
}

@(private)
set_source_position :: proc(p: ^Printer, pos: tokenizer.Pos) {
	p.source_position = pos;
}

@(private)
move_line :: proc(p: ^Printer, pos: tokenizer.Pos) {
	move_line_limit(p, pos, p.config.newline_limit);
}

@(private)
move_line_limit :: proc(p: ^Printer, pos: tokenizer.Pos, limit: int) -> bool {
	lines := min(pos.line - p.source_position.line, limit);

	if lines < 0 {
		return false;
	}

	p.source_position = pos;
	p.current_line_index += lines;
	set_line(p, p.current_line_index);
	return lines > 0;
}

@(private)
set_line :: proc(p: ^Printer, line: int) -> ^Line {

	unwrapped_line: ^Line;

	if line >= len(p.lines) {
		for i := len(p.lines); i <= line; i += 1 {
			new_line: Line;
			new_line.format_tokens = make([dynamic] Format_Token, 0, 50, p.allocator);
			append(&p.lines, new_line);
		}
		unwrapped_line = &p.lines[line];
    } else {
        unwrapped_line = &p.lines[line];
    }

	p.current_line = unwrapped_line;
	p.current_line_index = line;

	return unwrapped_line;
}

@(private)
newline_position :: proc(p: ^Printer, count: int) {
	p.current_line_index += count;
	set_line(p, p.current_line_index);
}

@(private)
indent :: proc(p: ^Printer) {
	p.depth += 1;
}

@(private)
unindent :: proc(p: ^Printer) {
	p.depth -= 1;
}

@(private)
merge_next_token :: proc(p: ^Printer) {
	p.merge_next_token = true;
}

@(private)
space_next_token :: proc(p: ^Printer) {
	p.space_next_token = true;
}

@(private)
hint_current_line :: proc(p: ^Printer, hint: Line_Type) {
	p.current_line.types |= hint;
}

@(private)
visit_decl :: proc(p: ^Printer, decl: ^ast.Decl, called_in_stmt := false) {

	using ast;

	if decl == nil {
		return;
	}

	switch v in &decl.derived {
	case Expr_Stmt:
		move_line(p, decl.pos);
		visit_expr(p, v.expr);
		if p.config.semicolons {
            push_generic_token(p, .Semicolon, 0);
		}
	case When_Stmt:
		visit_stmt(p, cast(^Stmt)decl);
	case Foreign_Import_Decl:
		if len(v.attributes) > 0 {
			sort.sort(sort_attribute(&v.attributes));
			move_line(p, v.attributes[0].pos);
			visit_attributes(p, v.attributes);
		} 

		move_line(p, decl.pos);
		
        push_generic_token(p, v.foreign_tok.kind, 0);
        push_generic_token(p, v.import_tok.kind, 1);

		if v.name != nil {
            push_ident_token(p, v.name.name, 1);
		} 

		for path in v.fullpaths {
            push_ident_token(p, path, 0);
		}
	case Foreign_Block_Decl:

		if len(v.attributes) > 0 {
			sort.sort(sort_attribute(&v.attributes));
			move_line(p, v.attributes[0].pos);
			visit_attributes(p, v.attributes);
		} 
			
		move_line(p, decl.pos);
		
        push_generic_token(p, .Foreign, 0);

		visit_expr(p, v.foreign_library);
		visit_stmt(p, v.body);
	case Import_Decl:
		move_line(p, decl.pos);

		if v.name.text != "" {
            push_generic_token(p, v.import_tok.kind, 1);
            push_generic_token(p, v.name.kind, 1);
            push_ident_token(p, v.fullpath, 0);
		} else {
            push_generic_token(p, v.import_tok.kind, 1);
            push_ident_token(p, v.fullpath, 0);
		}

	case Value_Decl:
		if len(v.attributes) > 0 {
			sort.sort(sort_attribute(&v.attributes));
			move_line(p, v.attributes[0].pos);
			visit_attributes(p, v.attributes);
		}

		move_line(p, decl.pos);

		if v.is_using {
            push_generic_token(p, .Using, 0);
		}

		visit_exprs(p, v.names, true);

		if v.type != nil {
            if !v.is_mutable && v.type != nil {
                push_generic_token(p, .Colon, 0);
		    } else {
                push_generic_token(p, .Colon, 0);
            }

			visit_expr(p, v.type);
		} else {
            if !v.is_mutable && v.type == nil {
                push_generic_token(p, .Colon, 1);
			    push_generic_token(p, .Colon, 0);
            } else {
                push_generic_token(p, .Colon, 1);
            }
		}

		if v.is_mutable && v.type != nil && len(v.values) != 0 {
            push_generic_token(p, .Eq, 1);
		} else if v.is_mutable && v.type == nil && len(v.values) != 0 {
			push_generic_token(p, .Eq, 0);
		} else if !v.is_mutable && v.type != nil {
            push_generic_token(p, .Colon, 0);
		}

		visit_exprs(p, v.values, true);

		add_semicolon := true;

		for value in v.values {
			switch a in value.derived {
			case Proc_Lit, Union_Type, Enum_Type, Struct_Type:
				add_semicolon = false || called_in_stmt;
			}
		}

		if add_semicolon && p.config.semicolons && !p.skip_semicolon {
            push_generic_token(p, .Semicolon, 0);
		}

	case:
		panic(fmt.aprint(decl.derived));
	}
}

@(private)
visit_exprs :: proc(p: ^Printer, list: []^ast.Expr, add_comma := false, trailing := false) {

	if len(list) == 0 {
		return;
	}

	//we have to newline the expressions to respect the source
	for expr, i in list {

		move_line_limit(p, expr.pos, 1);

		visit_expr(p, expr);

		if (i != len(list) - 1 || trailing) && add_comma {
			push_generic_token(p, .Comma, 0);
		} 
	}
}

@(private)
visit_attributes :: proc(p: ^Printer, attributes: [dynamic]^ast.Attribute) {

	if len(attributes) == 0 {
		return;
	}

	for attribute, i in attributes {

		move_line_limit(p, attribute.pos, 1);

		push_generic_token(p, .At, 0);
		push_generic_token(p, .Open_Paren, 0);

		visit_exprs(p, attribute.elems, true);

		push_generic_token(p, .Close_Paren, 0);	
	}
}

@(private)
visit_stmt :: proc(p: ^Printer, stmt: ^ast.Stmt, block_type: Block_Type = .Generic, empty_block := false, block_stmt := false) {

	using ast;

	if stmt == nil {
		return;
	}

	switch v in stmt.derived {
	case Value_Decl:
		visit_decl(p, cast(^Decl)stmt, true);
		return;
	case Foreign_Import_Decl:
		visit_decl(p, cast(^Decl)stmt, true);
		return;
	case Foreign_Block_Decl:
		visit_decl(p, cast(^Decl)stmt, true);
		return;
	}

	switch v in stmt.derived {
	case Using_Stmt:
		move_line(p, v.pos);

		push_generic_token(p, .Using, 1);

		visit_exprs(p, v.list, true);

		if p.config.semicolons {
			push_generic_token(p, .Semicolon, 0);
		}
	case Block_Stmt:
		move_line(p, v.pos);

		if v.pos.line == v.end.line && len(v.stmts) > 1 && p.config.split_multiple_stmts {

			if !empty_block {
				visit_begin_brace(p, v.pos, block_type, len(v.stmts));
			}

			set_source_position(p, v.pos);

			visit_block_stmts(p, v.stmts, true);

			set_source_position(p, v.end);

			if !empty_block {
				visit_end_brace(p, v.end);
			}
		} else if v.pos.line == v.end.line {
			if !empty_block {
				push_generic_token(p, .Open_Brace, 0);
			}

			set_source_position(p, v.pos);

			visit_block_stmts(p, v.stmts);

			set_source_position(p, v.end);

			if !empty_block {
				push_generic_token(p, .Close_Brace, 0);
			}
		} else {
			if !empty_block {
				visit_begin_brace(p, v.pos, block_type, len(v.stmts));
			}

			set_source_position(p, v.pos);

			visit_block_stmts(p, v.stmts);

			set_source_position(p, v.end);

			if !empty_block {
				visit_end_brace(p, v.end);
			}
		}
	case If_Stmt:
		move_line(p, v.pos);

		if v.label != nil {
			visit_expr(p, v.label);
			push_generic_token(p, .Colon, 0);
		}

		push_generic_token(p, .If, 1);

		if v.init != nil {
			p.skip_semicolon = true;
			visit_stmt(p, v.init);
			p.skip_semicolon = false;
			push_generic_token(p, .Semicolon, 0);
		}

		visit_expr(p, v.cond);

		uses_do := false;

		if check_stmt, ok := v.body.derived.(Block_Stmt); ok && check_stmt.uses_do {
			uses_do = true;
		}

		if uses_do && !p.config.convert_do {
			push_generic_token(p, .Do, 1);
			visit_stmt(p, v.body, .If_Stmt, true);
		} else {
			if uses_do {
				newline_position(p, 1);
			}

			visit_stmt(p, v.body, .If_Stmt);
		}

		if v.else_stmt != nil {

			if p.config.brace_style == .Allman || p.config.brace_style == .Stroustrup {
				newline_position(p, 1);
			} 

			push_generic_token(p, .Else, 1);

			set_source_position(p, v.else_stmt.pos);

			visit_stmt(p, v.else_stmt);
		}
	case Switch_Stmt:
		move_line(p, v.pos);

		if v.label != nil {
			visit_expr(p, v.label);
			push_generic_token(p, .Colon, 0);
		}

		if v.partial {
			push_ident_token(p, "#partial", 1);
		}

		push_generic_token(p, .Switch, 1);

		hint_current_line(p, {.Switch_Stmt});

		if v.init != nil {
			p.skip_semicolon = true;
			visit_stmt(p, v.init);
			p.skip_semicolon = false;
		}

		if v.init != nil && v.cond != nil {
			push_generic_token(p, .Semicolon, 0);
		}

		visit_expr(p, v.cond);
		visit_stmt(p, v.body);
	case Case_Clause:
		move_line(p, v.pos);

		if !p.config.indent_cases {
			unindent(p);
		}

		push_generic_token(p, .Case, 0);

		if v.list != nil {
			visit_exprs(p, v.list, true);
		}

		push_generic_token(p, v.terminator.kind, 0);

		indent(p);

		visit_block_stmts(p, v.body);

		unindent(p);

		if !p.config.indent_cases {
			indent(p);
		}
	case Type_Switch_Stmt:
		move_line(p, v.pos);

		if v.label != nil {
			visit_expr(p, v.label);
			push_generic_token(p, .Colon, 0);
		}

		if v.partial {
			push_ident_token(p, "#partial", 1);
		}

		push_generic_token(p, .Switch, 1);

		visit_stmt(p, v.tag);
		visit_stmt(p, v.body);
	case Assign_Stmt:
		move_line(p, v.pos);

		visit_exprs(p, v.lhs, true);

		push_generic_token(p, v.op.kind, 1);

		visit_exprs(p, v.rhs, true);

		if block_stmt && p.config.semicolons {
			push_generic_token(p, .Semicolon, 0);
		}
	case Expr_Stmt:
		move_line(p, v.pos);
		visit_expr(p, v.expr);
		if block_stmt && p.config.semicolons {
			push_generic_token(p, .Semicolon, 0);
		}
	case For_Stmt:
		//this should be simplified
		move_line(p, v.pos);

		if v.label != nil {
			visit_expr(p, v.label);
			push_generic_token(p, .Colon, 0);
		}

		push_generic_token(p, .For, 1);

		if v.init != nil {
			p.skip_semicolon = true;
			visit_stmt(p, v.init);
			p.skip_semicolon = false;
			push_generic_token(p, .Semicolon, 0);
		} else if v.post != nil {
			push_generic_token(p, .Semicolon, 0);
		}

		if v.cond != nil {
			visit_expr(p, v.cond);
		}

		if v.post != nil {
			push_generic_token(p, .Semicolon, 0);
			visit_stmt(p, v.post);
		} else if v.post == nil && v.cond != nil && v.init != nil {
			push_generic_token(p, .Semicolon, 0);
		}

		visit_stmt(p, v.body);
	case Inline_Range_Stmt:

		move_line(p, v.pos);

		if v.label != nil {
			visit_expr(p, v.label);
			push_generic_token(p, .Colon, 1);
		}

		push_ident_token(p, "#unroll", 0);

		push_generic_token(p, .For, 1);
		visit_expr(p, v.val0);

		if v.val1 != nil {
			push_generic_token(p, .Comma, 0);
			visit_expr(p, v.val1);
		}

		push_generic_token(p, .In, 1);

		visit_expr(p, v.expr);
		visit_stmt(p, v.body);
	case Range_Stmt:

		move_line(p, v.pos);

		if v.label != nil {
			visit_expr(p, v.label);
			push_generic_token(p, .Colon, 1);
		}

		push_generic_token(p, .For, 1);

		if len(v.vals) >= 1 {
			visit_expr(p, v.vals[0]);
		}

		if len(v.vals) >= 2 {
			push_generic_token(p, .Comma, 0);
			visit_expr(p, v.vals[1]);
		} 

		push_generic_token(p, .In, 1);

		visit_expr(p, v.expr);

		visit_stmt(p, v.body);
	case Return_Stmt:
		move_line(p, v.pos);

		push_generic_token(p, .Return, 1);

		if v.results != nil {
			visit_exprs(p, v.results, true);
		}

		if block_stmt && p.config.semicolons {
			push_generic_token(p, .Semicolon, 0);
		}
	case Defer_Stmt:
		move_line(p, v.pos);
		push_generic_token(p, .Defer, 0);

		visit_stmt(p, v.stmt);

		if p.config.semicolons {
			push_generic_token(p, .Semicolon, 0);
		}
	case When_Stmt:
		move_line(p, v.pos);
		push_generic_token(p, .When, 1);
		visit_expr(p, v.cond);

		visit_stmt(p, v.body);

		if v.else_stmt != nil {

			if p.config.brace_style == .Allman {
				newline_position(p, 1);
			} 

			push_generic_token(p, .Else, 1);

			set_source_position(p, v.else_stmt.pos);

			visit_stmt(p, v.else_stmt);
		}

	case Branch_Stmt:

		move_line(p, v.pos);

		push_generic_token(p, v.tok.kind, 0);

		if v.label != nil {
			visit_expr(p, v.label);
		}

		if p.config.semicolons {
			push_generic_token(p, .Semicolon, 0);
		}
	case:
		panic(fmt.aprint(stmt.derived));
	}

	set_source_position(p, stmt.end);
}


@(private)
visit_expr :: proc(p: ^Printer, expr: ^ast.Expr) {

	using ast;

	if expr == nil {
		return;
	}

	set_source_position(p, expr.pos);

	switch v in expr.derived {
	case Inline_Asm_Expr:
		push_generic_token(p, v.tok.kind, 1, v.tok.text);

		push_generic_token(p, .Open_Paren, 1);
		visit_exprs(p, v.param_types, true, false);
		push_generic_token(p, .Close_Paren, 0);

		push_generic_token(p, .Sub, 1);
		push_generic_token(p, .Gt, 0);

		visit_expr(p, v.return_type);

		push_generic_token(p, .Open_Brace, 1);
		visit_expr(p, v.asm_string);
		push_generic_token(p, .Comma, 0);
		visit_expr(p, v.constraints_string);
		push_generic_token(p, .Close_Brace, 0);
	case Undef:
		push_generic_token(p, .Undef, 1);
	case Auto_Cast:
		push_generic_token(p, v.op.kind, 1);
		visit_expr(p, v.expr);
	case Ternary_Expr:
		visit_expr(p, v.cond);
		push_generic_token(p, v.op1.kind, 1);
		visit_expr(p, v.x);
		push_generic_token(p, v.op2.kind, 1);
		visit_expr(p, v.y);
	case Ternary_If_Expr:
		visit_expr(p, v.x);
		push_generic_token(p, v.op1.kind, 1);
		visit_expr(p, v.cond);
		push_generic_token(p, v.op2.kind, 1);
		visit_expr(p, v.y);
	case Ternary_When_Expr:
		visit_expr(p, v.x);
		push_generic_token(p, v.op1.kind, 1);
		visit_expr(p, v.cond);
		push_generic_token(p, v.op2.kind, 1);
		visit_expr(p, v.y);
	case Selector_Call_Expr:
		visit_expr(p, v.call.expr);
		push_generic_token(p, .Open_Paren, 1);
		visit_exprs(p, v.call.args, true);
		push_generic_token(p, .Close_Paren, 0);
	case Ellipsis:
		push_generic_token(p, .Ellipsis, 1);
		visit_expr(p, v.expr);
	case Relative_Type:
		visit_expr(p, v.tag);
		visit_expr(p, v.type);
	case Slice_Expr:
		visit_expr(p, v.expr);
		push_generic_token(p, .Open_Bracket, 0);
		visit_expr(p, v.low);
		push_generic_token(p, v.interval.kind, 0);
		if v.high != nil {
			merge_next_token(p);
			visit_expr(p, v.high);
		}
		push_generic_token(p, .Close_Bracket, 0);
	case Ident:
		push_ident_token(p, v.name, 1);
	case Deref_Expr:
		visit_expr(p, v.expr);
		push_generic_token(p, v.op.kind, 0);
	case Type_Cast:
		push_generic_token(p, v.tok.kind, 1);
		push_generic_token(p, .Open_Paren, 1);
		visit_expr(p, v.type);
		push_generic_token(p, .Close_Paren, 0);
		visit_expr(p, v.expr);
	case Basic_Directive:
		push_generic_token(p, v.tok.kind, 1);
		push_ident_token(p, v.name, 0);
	case Distinct_Type:
		push_generic_token(p, .Distinct, 1);
		visit_expr(p, v.type);
	case Dynamic_Array_Type:
		visit_expr(p, v.tag);
		push_generic_token(p, .Open_Bracket, 1);
		push_generic_token(p, .Dynamic, 0);
		push_generic_token(p, .Close_Bracket, 0);
		visit_expr(p, v.elem);
	case Bit_Set_Type:
		push_generic_token(p, .Bit_Set, 1);
		push_generic_token(p, .Open_Bracket, 0);

		visit_expr(p, v.elem);

		if v.underlying != nil {
			push_generic_token(p, .Semicolon, 0);
			visit_expr(p, v.underlying);
		}

		push_generic_token(p, .Close_Bracket, 0);
	case Union_Type:
		push_generic_token(p, .Union, 1);

		if v.poly_params != nil {
			push_generic_token(p, .Open_Paren, 0);
			visit_field_list(p, v.poly_params, true, false);
			push_generic_token(p, .Close_Paren, 0);
		}
		
		if v.is_maybe {
			push_ident_token(p, "#maybe", 1);
		}

		if v.where_clauses != nil {
			move_line(p, v.where_clauses[0].pos);
			push_generic_token(p, .Where, 1);
			visit_exprs(p, v.where_clauses, true);
		}

		if v.variants != nil && (len(v.variants) == 0 || v.pos.line == v.end.line) {
			push_generic_token(p, .Open_Brace, 1);
			visit_exprs(p, v.variants, true);
			push_generic_token(p, .Close_Brace, 0);
		} else {
			visit_begin_brace(p, v.pos, .Generic);
			newline_position(p, 1);
			set_source_position(p, v.variants[0].pos);
			visit_exprs(p, v.variants, true, true);
			visit_end_brace(p, v.end);
		}
	case Enum_Type:
		push_generic_token(p, .Enum, 1);

		if v.base_type != nil {
			visit_expr(p, v.base_type);
		}

		if v.fields != nil && (len(v.fields) == 0 || v.pos.line == v.end.line) {
			push_generic_token(p, .Open_Brace, 1);
			visit_exprs(p, v.fields, true);
			push_generic_token(p, .Close_Brace, 0);
		} else {
			visit_begin_brace(p, v.pos, .Generic);
			newline_position(p, 1);
			set_source_position(p, v.fields[0].pos);
			visit_exprs(p, v.fields, true, true);
			visit_end_brace(p, v.end);
		}

		set_source_position(p, v.end);
	case Struct_Type:
		push_generic_token(p, .Struct, 1);

		hint_current_line(p, {.Struct});

		if v.is_packed {
			push_ident_token(p, "#packed", 1);
		}

		if v.is_raw_union {
			push_ident_token(p, "#raw_union", 1);
		}

		if v.align != nil {
			push_ident_token(p, "#align", 1);
			visit_expr(p, v.align);
		}

		if v.poly_params != nil {
			push_generic_token(p, .Open_Paren, 0);
			visit_field_list(p, v.poly_params, true, false);
			push_generic_token(p, .Close_Paren, 0);
		}

		if v.where_clauses != nil {
			move_line(p, v.where_clauses[0].pos);
			push_generic_token(p, .Where, 1);
			visit_exprs(p, v.where_clauses, true);
		}

		if v.fields != nil && (len(v.fields.list) == 0 || v.pos.line == v.end.line) {
			push_generic_token(p, .Open_Brace, 1);
			set_source_position(p, v.fields.pos);
			visit_field_list(p, v.fields, true);
			push_generic_token(p, .Close_Brace, 0);
		} else if v.fields != nil {
			visit_begin_brace(p, v.pos, .Generic, len(v.fields.list));
			set_source_position(p, v.fields.pos);
			visit_field_list(p, v.fields, true, true, true);
			visit_end_brace(p, v.end);
		}

		set_source_position(p, v.end);
	case Proc_Lit:

		if v.inlining == .Inline {
			push_ident_token(p, "#force_inline", 0);
		}

		visit_proc_type(p, v.type^);

		if v.where_clauses != nil {
			move_line(p, v.where_clauses[0].pos);
			push_generic_token(p, .Where, 1);
			visit_exprs(p, v.where_clauses, true);
		}

		if v.body != nil {
			set_source_position(p, v.body.pos);
			visit_stmt(p, v.body, .Proc);
		} else {
			push_generic_token(p, .Undef, 1);
		}
	case Proc_Type:
		visit_proc_type(p, v);
	case Basic_Lit:
		push_generic_token(p, v.tok.kind, 1, v.tok.text);
	case Binary_Expr:
		visit_binary_expr(p, v);
	case Implicit_Selector_Expr:
		push_generic_token(p, .Period, 0);
		push_ident_token(p, v.field.name, 0);
	case Call_Expr:
		visit_expr(p, v.expr);
		push_generic_token(p, .Open_Paren, 0);
		visit_call_exprs(p, v.args, v.ellipsis.kind == .Ellipsis);
		push_generic_token(p, .Close_Paren, 0);
	case Typeid_Type:
		push_generic_token(p, .Typeid, 1);

		if v.specialization != nil {
			push_generic_token(p, .Quo, 0);
			visit_expr(p, v.specialization);
		}
	case Selector_Expr:
		visit_expr(p, v.expr);
		push_generic_token(p, v.op.kind, 0);
		visit_expr(p, v.field);
	case Paren_Expr:
		push_generic_token(p, .Open_Paren, 1);
		visit_expr(p, v.expr);
		push_generic_token(p, .Close_Paren, 0);
	case Index_Expr:
		visit_expr(p, v.expr);
		push_generic_token(p, .Open_Bracket, 0);
		visit_expr(p, v.index);
		push_generic_token(p, .Close_Bracket, 0);
	case Proc_Group:
	
		push_generic_token(p, v.tok.kind, 0);

		if len(v.args) != 0 && v.pos.line != v.args[len(v.args) - 1].pos.line {
			visit_begin_brace(p, v.pos, .Generic);
			newline_position(p, 1);
			set_source_position(p, v.args[0].pos);
			visit_exprs(p, v.args, true, true);
			visit_end_brace(p, v.end);
		} else {
			push_generic_token(p, .Open_Brace, 0);
			visit_exprs(p, v.args, true);
			push_generic_token(p, .Close_Brace, 0);
		}
		
	case Comp_Lit:
		
		if v.type != nil {
			visit_expr(p, v.type);
		}

		if len(v.elems) != 0 && v.pos.line != v.elems[len(v.elems) - 1].pos.line {
			visit_begin_brace(p, v.pos, .Comp_Lit);
			newline_position(p, 1);
			set_source_position(p, v.elems[0].pos);
			visit_exprs(p, v.elems, true, true);
			visit_end_brace(p, v.end);
		} else {
			push_generic_token(p, .Open_Brace, 0);
			visit_exprs(p, v.elems, true);
			push_generic_token(p, .Close_Brace, 0);
		}
		
	case Unary_Expr:
		push_generic_token(p, v.op.kind, 1);
		merge_next_token(p);
		visit_expr(p, v.expr);
	case Field_Value:
		visit_expr(p, v.field);
		push_generic_token(p, .Eq, 1);
		visit_expr(p, v.value);
	case Type_Assertion:
		visit_expr(p, v.expr);

		if unary, ok := v.type.derived.(Unary_Expr); ok && unary.op.text == "?" {
			push_generic_token(p, .Period, 0);
			visit_expr(p, v.type);
		} else {
			push_generic_token(p, .Period, 0);
			push_generic_token(p, .Open_Paren, 0);
			visit_expr(p, v.type);
			push_generic_token(p, .Close_Paren, 0);
		}

	case Pointer_Type:
		push_generic_token(p, .Pointer, 1);
		merge_next_token(p);
		visit_expr(p, v.elem);
	case Implicit:
		push_generic_token(p, v.tok.kind, 1);
	case Poly_Type:
		push_generic_token(p, .Dollar, 1);
		merge_next_token(p);
		visit_expr(p, v.type);

		if v.specialization != nil {
			push_generic_token(p, .Quo, 0);
			merge_next_token(p);
			visit_expr(p, v.specialization);
		}
	case Array_Type:
		visit_expr(p, v.tag);
		push_generic_token(p, .Open_Bracket, 1);
		visit_expr(p, v.len);
		push_generic_token(p, .Close_Bracket, 0);
		visit_expr(p, v.elem);
	case Map_Type:
		push_generic_token(p, .Map, 1);
		push_generic_token(p, .Open_Bracket, 0);
		visit_expr(p, v.key);
		push_generic_token(p, .Close_Bracket, 0);
		visit_expr(p, v.value);
	case Helper_Type:
		visit_expr(p, v.type);
	case:
		panic(fmt.aprint(expr.derived));
	}
}


visit_begin_brace :: proc(p: ^Printer, begin: tokenizer.Pos, type: Block_Type, count := 0) {

	set_source_position(p, begin);

	newline_braced := p.config.brace_style == .Allman;
	newline_braced |= p.config.brace_style == .K_And_R && type == .Proc;
	newline_braced &= p.config.brace_style != ._1TBS;

	format_token := Format_Token {
		kind = .Open_Brace,
		parameter_count = count,
		text = "{",
	};

	if newline_braced {
		newline_position(p, 1);
		push_format_token(p, format_token);
		indent(p);
	} else {
		format_token.spaces_before = 1;
		push_format_token(p, format_token);
		indent(p);
	}
}

visit_end_brace :: proc(p: ^Printer, end: tokenizer.Pos) {
	set_source_position(p, end);
	newline_position(p, 1);
	push_generic_token(p, .Close_Brace, 0);
	unindent(p); 
	p.current_line.depth = p.depth;
}

visit_block_stmts :: proc(p: ^Printer, stmts: []^ast.Stmt, newline_each := false) {
	for stmt, i in stmts {

		if newline_each {
			newline_position(p, 1);
		}

		visit_stmt(p, stmt, .Generic, false, true);
	}
}

visit_field_list :: proc(p: ^Printer, list: ^ast.Field_List, add_comma := false, trailing := false, enforce_newline := false) {

	if list.list == nil {
		return;
	}

	for field, i in list.list {

		if !move_line_limit(p, field.pos, 1) && enforce_newline {
			newline_position(p, 1);
		}	

		if .Using in field.flags {
			push_generic_token(p, .Using, 0);
		}

		visit_exprs(p, field.names, true);

		if len(field.names) != 0 {
			push_generic_token(p, .Colon, 0);
		}

		if field.type != nil {
			visit_expr(p, field.type);
		} else {
			push_generic_token(p, .Colon, 0);
			push_generic_token(p, .Eq, 0);
			visit_expr(p, field.default_value);
		}

		if field.tag.text != "" {
			push_generic_token(p, field.tag.kind, 1, field.tag.text);
		}

		if (i != len(list.list) - 1 || trailing) && add_comma {
			push_generic_token(p, .Comma, 0);
		}
	}
}

visit_proc_type :: proc(p: ^Printer, proc_type: ast.Proc_Type) {

	push_generic_token(p, .Proc, 1);

	explicit_calling := false;

	switch proc_type.calling_convention {
	case .Odin:
	case .Contextless:
		push_string_token(p, "\"contextless\"", 1);
		explicit_calling = true;
	case .C_Decl:
		push_string_token(p, "\"c\"", 1);
		explicit_calling = true;
	case .Std_Call:
		push_string_token(p, "\"std\"", 1);
		explicit_calling = true;
	case .Fast_Call:
		push_string_token(p, "\"fast\"", 1);
		explicit_calling = true;
	case .None:
			//nothing i guess
	case .Invalid:
			//nothing i guess
	case .Foreign_Block_Default:
	}

	if explicit_calling {
		push_generic_token(p, .Open_Paren, 1);
	} else {
		push_generic_token(p, .Open_Paren, 0);
	}

	visit_signature_list(p, proc_type.params, false);

	push_generic_token(p, .Close_Paren, 0);

	if proc_type.results != nil {
		push_generic_token(p, .Sub, 1);
		push_generic_token(p, .Gt, 0);

		use_parens := false;
		use_named  := false;

		if len(proc_type.results.list) > 1 {
			use_parens = true;
		} else if len(proc_type.results.list) == 1 {

			for name in proc_type.results.list[0].names {
				if ident, ok := name.derived.(ast.Ident); ok {
					if ident.name != "_" {
						use_parens = true;
					}
				}
			}
		}

		if use_parens {
			push_generic_token(p, .Open_Paren, 1);
			visit_signature_list(p, proc_type.results);
			push_generic_token(p, .Close_Paren, 0);
		} else {
			visit_signature_list(p, proc_type.results);
		}
	}
	
}

visit_binary_expr :: proc(p: ^Printer, binary: ast.Binary_Expr) {

	move_line(p, binary.left.pos);

	if v, ok := binary.left.derived.(ast.Binary_Expr); ok {
		visit_binary_expr(p, v);
	} else {
		visit_expr(p, binary.left);
	}

	if binary.op.kind == .Ellipsis || binary.op.kind == .Range_Half {
		push_generic_token(p, binary.op.kind, 0);
	} else {
		push_generic_token(p, binary.op.kind, 1);
	}

	move_line(p, binary.right.pos);

	if v, ok := binary.right.derived.(ast.Binary_Expr); ok {
		visit_binary_expr(p, v);
	} else {
		visit_expr(p, binary.right);
	}

}

visit_call_exprs :: proc(p: ^Printer, list: []^ast.Expr, ellipsis := false) {

	if len(list) == 0 {
		return;
	}

	//all the expression are on the line
	if list[0].pos.line == list[len(list) - 1].pos.line {
		for expr, i in list {

			if i == len(list) - 1 && ellipsis {
				push_generic_token(p, .Ellipsis, 0);
			}

			visit_expr(p, expr);

			if i != len(list) - 1 {
				push_generic_token(p, .Comma, 0);
			}
		}
	} else {
		for expr, i in list {

			//we have to newline the expressions to respect the source
			move_line_limit(p, expr.pos, 1);
			

			if i == len(list) - 1 && ellipsis {
				push_generic_token(p, .Ellipsis, 0);
			}

			visit_expr(p, expr);

			if i != len(list) - 1 {
				push_generic_token(p, .Comma, 0);
			}
		}
	}
}


visit_signature_list :: proc(p: ^Printer, list: ^ast.Field_List, remove_blank := true) {

	if list.list == nil {
		return;
	}

	for field, i in list.list {

		move_line_limit(p, field.pos, 1);

		if .Using in field.flags {
			push_generic_token(p, .Using, 0);
		}

		named := false;

		for name in field.names {
			if ident, ok := name.derived.(ast.Ident); ok {
				//for some reason the parser uses _ to mean empty
				if ident.name != "_" || !remove_blank {
					named = true;
				}
			} else {
				//alternative is poly names
				named = true;
			}
		}

		if named {
			visit_exprs(p, field.names, true);

			if len(field.names) != 0 && field.type != nil {
				push_generic_token(p, .Colon, 0);
			} 
		}

		if field.type != nil && field.default_value != nil {
			visit_expr(p, field.type);
			push_generic_token(p, .Eq, 0);
			visit_expr(p, field.default_value);
		} else if field.type != nil {
			visit_expr(p, field.type);
		} else {
			push_generic_token(p, .Colon, 1);
			push_generic_token(p, .Eq, 0);
			visit_expr(p, field.default_value);
		}

		if i != len(list.list) - 1 {
			push_generic_token(p, .Comma, 0);
		}
	}
}

