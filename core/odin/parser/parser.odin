package odin_parser

import "core:odin/ast"
import "core:odin/tokenizer"

import "core:fmt"

Warning_Handler :: #type proc(pos: tokenizer.Pos, fmt: string, args: ..any);
Error_Handler   :: #type proc(pos: tokenizer.Pos, fmt: string, args: ..any);

Parser :: struct {
	file: ^ast.File,
	tok: tokenizer.Tokenizer,

	warn: Warning_Handler,
	err:  Error_Handler,

	prev_tok: tokenizer.Token,
	curr_tok: tokenizer.Token,

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	expr_level:       int,
	allow_range:      bool, // NOTE(bill): Ranges are only allowed in certain cases
	allow_in_expr:    bool, // NOTE(bill): in expression are only allowed in certain cases
	in_foreign_block: bool,
	allow_type:       bool,

	lead_comment: ^ast.Comment_Group,
	line_comment: ^ast.Comment_Group,

	curr_proc: ^ast.Node,

	error_count: int,
}

Stmt_Allow_Flag :: enum {
	In,
	Label,
}
Stmt_Allow_Flags :: distinct bit_set[Stmt_Allow_Flag];


Import_Decl_Kind :: enum {
	Standard,
	Using,
}



default_warning_handler :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d): Warning: ", pos.file, pos.line, pos.column);
	fmt.eprintf(msg, ..args);
	fmt.eprintf("\n");
}
default_error_handler :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d): ", pos.file, pos.line, pos.column);
	fmt.eprintf(msg, ..args);
	fmt.eprintf("\n");
}

warn :: proc(p: ^Parser, pos: tokenizer.Pos, msg: string, args: ..any) {
	if p.warn != nil {
		p.warn(pos, msg, ..args);
	}
	p.file.syntax_warning_count += 1;
}

error :: proc(p: ^Parser, pos: tokenizer.Pos, msg: string, args: ..any) {
	if p.err != nil {
		p.err(pos, msg, ..args);
	}
	p.file.syntax_error_count += 1;
	p.error_count += 1;
}


end_pos :: proc(tok: tokenizer.Token) -> tokenizer.Pos {
	pos := tok.pos;
	pos.offset += len(tok.text);

	if tok.kind == .Comment {
		if tok.text[:2] != "/*" {
			pos.column += len(tok.text);
		} else {
			for i := 0; i < len(tok.text); i += 1 {
				c := tok.text[i];
				if c == '\n' {
					pos.line += 1;
					pos.column = 1;
				} else {
					pos.column += 1;
				}
			}
		}
	} else {
		pos.column += len(tok.text);
	}
	return pos;
}

default_parser :: proc() -> Parser {
	return Parser {
		err  = default_error_handler,
		warn = default_warning_handler,
	};
}

parse_file :: proc(p: ^Parser, file: ^ast.File) -> bool {
	zero_parser: {
		p.prev_tok         = {};
		p.curr_tok         = {};
		p.expr_level       = 0;
		p.allow_range      = false;
		p.allow_in_expr    = false;
		p.in_foreign_block = false;
		p.allow_type       = false;
		p.lead_comment     = nil;
		p.line_comment     = nil;
	}

	p.file = file;
	tokenizer.init(&p.tok, file.src, file.fullpath);
	if p.tok.ch <= 0 {
		return true;
	}


	advance_token(p);
	consume_comment_groups(p, p.prev_tok);

	docs := p.lead_comment;

	p.file.pkg_token = expect_token(p, .Package);
	if p.file.pkg_token.kind != .Package {
		return false;
	}

	pkg_name := expect_token_after(p, .Ident, "package");
	if pkg_name.kind == .Ident {
		if is_blank_ident(pkg_name) {
			error(p, pkg_name.pos, "invalid package name '_'");
		}
	}
	p.file.pkg_name = pkg_name.text;

	pd := ast.new(ast.Package_Decl, pkg_name.pos, end_pos(p.prev_tok));
	pd.docs    = docs;
	pd.token   = p.file.pkg_token;
	pd.name    = pkg_name.text;
	pd.comment = p.line_comment;
	p.file.pkg_decl = pd;

	expect_semicolon(p, pd);

	if p.file.syntax_error_count > 0 {
		return false;
	}

	p.file.decls = make([dynamic]^ast.Stmt);

	for p.curr_tok.kind != .EOF {
		stmt := parse_stmt(p);
		if stmt != nil {
			if _, ok := stmt.derived.(ast.Empty_Stmt); !ok {
				append(&p.file.decls, stmt);
				if es, es_ok := stmt.derived.(ast.Expr_Stmt); es_ok && es.expr != nil {
					if _, pl_ok := es.expr.derived.(ast.Proc_Lit); pl_ok {
						error(p, stmt.pos, "procedure literal evaluated but not used");
					}
				}
			}
		}
	}

	return true;
}


next_token0 :: proc(p: ^Parser) -> bool {
	p.curr_tok = tokenizer.scan(&p.tok);
	if p.curr_tok.kind == .EOF {
		// error(p, p.curr_tok.pos, "token is EOF");
		return false;
	}
	return true;
}

consume_comment :: proc(p: ^Parser) -> (tok: tokenizer.Token, end_line: int) {
	tok = p.curr_tok;
	assert(tok.kind == .Comment);
	end_line = tok.pos.line;

	if tok.text[1] == '*' {
		for c in tok.text {
			if c == '\n' {
				end_line += 1;
			}
		}
	}

	_ = next_token0(p);
	if p.curr_tok.pos.line > tok.pos.line {
		end_line += 1;
	}

	return;
}

consume_comment_group :: proc(p: ^Parser, n: int) -> (comments: ^ast.Comment_Group, end_line: int) {
	list: [dynamic]tokenizer.Token;
	end_line = p.curr_tok.pos.line;
	for p.curr_tok.kind == .Comment &&
	    p.curr_tok.pos.line <= end_line+n {
	    comment: tokenizer.Token;
    	comment, end_line = consume_comment(p);
		append(&list, comment);
    }

    if len(list) > 0 {
    	comments = new(ast.Comment_Group);
    	comments.list = list[:];
    	append(&p.file.comments, comments);
    }

    return;
}

consume_comment_groups :: proc(p: ^Parser, prev: tokenizer.Token) {
	if p.curr_tok.kind == .Comment {
		comment: ^ast.Comment_Group;
		end_line := 0;

		if p.curr_tok.pos.line == prev.pos.line {
			comment, end_line = consume_comment_group(p, 0);
			if p.curr_tok.pos.line != end_line || p.curr_tok.kind == .EOF {
				p.line_comment = comment;
			}
		}

		end_line = -1;
		for p.curr_tok.kind == .Comment {
			comment, end_line = consume_comment_group(p, 1);
		}
		if end_line+1 >= p.curr_tok.pos.line || end_line < 0 {
			p.lead_comment = comment;
		}

		assert(p.curr_tok.kind != .Comment);
	}
}

advance_token :: proc(p: ^Parser) -> tokenizer.Token {
	p.lead_comment = nil;
	p.line_comment = nil;
	p.prev_tok = p.curr_tok;
	prev := p.prev_tok;

	if next_token0(p) {
		consume_comment_groups(p, prev);
	}
	return prev;
}

expect_token :: proc(p: ^Parser, kind: tokenizer.Token_Kind) -> tokenizer.Token {
	prev := p.curr_tok;
	if prev.kind != kind {
		e := tokenizer.to_string(kind);
		g := tokenizer.to_string(prev.kind);
		error(p, prev.pos, "expected '%s', got '%s'", e, g);
	}
	advance_token(p);
	return prev;
}

expect_token_after :: proc(p: ^Parser, kind: tokenizer.Token_Kind, msg: string) -> tokenizer.Token {
	prev := p.curr_tok;
	if prev.kind != kind {
		e := tokenizer.to_string(kind);
		g := tokenizer.to_string(prev.kind);
		error(p, prev.pos, "expected '%s' after %s, got '%s'", e, msg, g);
	}
	advance_token(p);
	return prev;
}

expect_operator :: proc(p: ^Parser) -> tokenizer.Token {
	prev := p.curr_tok;
	if !tokenizer.is_operator(prev.kind) {
		g := tokenizer.to_string(prev.kind);
		error(p, prev.pos, "expected an operator, got '%s'", g);
	}
	advance_token(p);
	return prev;
}

allow_token :: proc(p: ^Parser, kind: tokenizer.Token_Kind) -> bool {
	if p.curr_tok.kind == kind {
		advance_token(p);
		return true;
	}
	return false;
}


is_blank_ident :: proc{
	is_blank_ident_string,
	is_blank_ident_token,
	is_blank_ident_node,
};
is_blank_ident_string :: inline proc(str: string) -> bool {
	return str == "_";
}
is_blank_ident_token :: inline proc(tok: tokenizer.Token) -> bool {
	if tok.kind == .Ident {
		return is_blank_ident_string(tok.text);
	}
	return false;
}
is_blank_ident_node :: inline proc(node: ^ast.Node) -> bool {
	if ident, ok := node.derived.(ast.Ident); ok {
		return is_blank_ident(ident.name);
	}
	return true;
}


is_semicolon_optional_for_node :: proc(p: ^Parser, node: ^ast.Node) -> bool {
	if node == nil {
		return false;
	}
	switch n in node.derived {
	case ast.Empty_Stmt, ast.Block_Stmt:
		return true;

	case ast.If_Stmt, ast.When_Stmt,
	     ast.For_Stmt, ast.Range_Stmt,
	     ast.Switch_Stmt, ast.Type_Switch_Stmt:
		return true;

	case ast.Helper_Type:
		return is_semicolon_optional_for_node(p, n.type);
	case ast.Distinct_Type:
		return is_semicolon_optional_for_node(p, n.type);
	case ast.Pointer_Type:
		return is_semicolon_optional_for_node(p, n.elem);
	case ast.Struct_Type, ast.Union_Type, ast.Enum_Type, ast.Bit_Field_Type:
		// Require semicolon within a procedure body
		return p.curr_proc == nil;
	case ast.Proc_Lit:
		return true;

	case ast.Package_Decl, ast.Import_Decl, ast.Foreign_Import_Decl:
		return true;

	case ast.Foreign_Block_Decl:
		return is_semicolon_optional_for_node(p, n.body);

	case ast.Value_Decl:
		if n.is_mutable {
			return false;
		}
		if len(n.values) > 0 {
			return is_semicolon_optional_for_node(p, n.values[len(n.values)-1]);
		}
	}

	return false;
}


expect_semicolon :: proc(p: ^Parser, node: ^ast.Node) -> bool {
	if allow_token(p, .Semicolon) {
		return true;
	}

	prev := p.prev_tok;
	if prev.kind == .Semicolon {
		return true;
	}

	if p.curr_tok.kind == .EOF {
		return true;
	}

	if node != nil {
		if prev.pos.line != p.curr_tok.pos.line {
			if is_semicolon_optional_for_node(p, node) {
				return true;
			}
		} else {
			switch p.curr_tok.kind {
			case .Close_Brace:
			case .Close_Paren:
			case .Else:
				return true;
			}
		}
	}

	error(p, prev.pos, "expected ';', got %s", tokenizer.to_string(prev.kind));
	return false;
}

new_blank_ident :: proc(p: ^Parser, pos: tokenizer.Pos) -> ^ast.Ident {
	tok: tokenizer.Token;
	tok.pos = pos;
	i := ast.new(ast.Ident, pos, end_pos(tok));
	i.name = "_";
	return i;
}

parse_ident :: proc(p: ^Parser) -> ^ast.Ident {
	tok := p.curr_tok;
	pos := tok.pos;
	name := "_";
	if tok.kind == .Ident {
		name = tok.text;
		advance_token(p);
	} else {
		expect_token(p, .Ident);
	}
	i := ast.new(ast.Ident, pos, end_pos(tok));
	i.name = name;
	return i;
}

parse_stmt_list :: proc(p: ^Parser) -> []^ast.Stmt {
	list: [dynamic]^ast.Stmt;
	for p.curr_tok.kind != .Case &&
	    p.curr_tok.kind != .Close_Brace &&
	    p.curr_tok.kind != .EOF  {
		stmt := parse_stmt(p);
		if stmt != nil {
			if _, ok := stmt.derived.(ast.Empty_Stmt); !ok {
				append(&list, stmt);
				if es, es_ok := stmt.derived.(ast.Expr_Stmt); es_ok && es.expr != nil {
					if _, pl_ok := es.expr.derived.(ast.Proc_Lit); pl_ok {
						error(p, stmt.pos, "procedure literal evaluated but not used");
					}
				}
			}
		}
	}
	return list[:];
}

parse_block_stmt :: proc(p: ^Parser, is_when: bool) -> ^ast.Stmt {
	if !is_when && p.curr_proc == nil {
		error(p, p.curr_tok.pos, "you cannot use a block statement in the file scope");
	}
	return parse_body(p);
}

parse_when_stmt :: proc(p: ^Parser) -> ^ast.When_Stmt {
	tok := expect_token(p, .When);

	cond: ^ast.Expr;
	body: ^ast.Stmt;
	else_stmt: ^ast.Stmt;

	prev_level := p.expr_level;
	p.expr_level = -1;
	cond = parse_expr(p, false);
	p.expr_level = prev_level;

	if cond == nil {
		error(p, p.curr_tok.pos, "expected a condition for when statement");
	}
	if allow_token(p, .Do) {
		body = convert_stmt_to_body(p, parse_stmt(p));
	} else {
		body = parse_block_stmt(p, true);
	}

	if allow_token(p, .Else) {
		switch p.curr_tok.kind {
		case .When:
			else_stmt = parse_when_stmt(p);
		case .Open_Brace:
			else_stmt = parse_block_stmt(p, true);
		case .Do:
			expect_token(p, .Do);
			else_stmt = convert_stmt_to_body(p, parse_stmt(p));
		case:
			error(p, p.curr_tok.pos, "expected when statement block statement");
			else_stmt = ast.new(ast.Bad_Stmt, p.curr_tok.pos, end_pos(p.curr_tok));
		}
	}

	end := body.end;
	if else_stmt != nil {
		end = else_stmt.end;
	}
	when_stmt := ast.new(ast.When_Stmt, tok.pos, end);
	when_stmt.when_pos  = tok.pos;
	when_stmt.cond      = cond;
	when_stmt.body      = body;
	when_stmt.else_stmt = else_stmt;
	return when_stmt;
}

convert_stmt_to_expr :: proc(p: ^Parser, stmt: ^ast.Stmt, kind: string) -> ^ast.Expr {
	if stmt == nil {
		return nil;
	}
	if es, ok := stmt.derived.(ast.Expr_Stmt); ok {
		return es.expr;
	}
	error(p, stmt.pos, "expected %s, found a simple statement", kind);
	return ast.new(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok));
}

parse_if_stmt :: proc(p: ^Parser) -> ^ast.If_Stmt {
	tok := expect_token(p, .If);

	init: ^ast.Stmt;
	cond: ^ast.Expr;
	body: ^ast.Stmt;
	else_stmt: ^ast.Stmt;

	prev_level := p.expr_level;
	p.expr_level = -1;
	prev_allow_in_expr := p.allow_in_expr;
	p.allow_in_expr = true;
	if allow_token(p, .Semicolon) {
		cond = parse_expr(p, false);
	} else {
		init = parse_simple_stmt(p, nil);
		if allow_token(p, .Semicolon) {
			cond = parse_expr(p, false);
		} else {
			cond = convert_stmt_to_expr(p, init, "boolean expression");
			init = nil;
		}
	}

	p.expr_level = prev_level;
	p.allow_in_expr = prev_allow_in_expr;

	if cond == nil {
		error(p, p.curr_tok.pos, "expected a condition for if statement");

	}
	if allow_token(p, .Do) {
		body = convert_stmt_to_body(p, parse_stmt(p));
	} else {
		body = parse_block_stmt(p, false);
	}

	if allow_token(p, .Else) {
		switch p.curr_tok.kind {
		case .If:
			else_stmt = parse_if_stmt(p);
		case .Open_Brace:
			else_stmt = parse_block_stmt(p, false);
		case .Do:
			expect_token(p, .Do);
			else_stmt = convert_stmt_to_body(p, parse_stmt(p));
		case:
			error(p, p.curr_tok.pos, "expected if statement block statement");
			else_stmt = ast.new(ast.Bad_Stmt, p.curr_tok.pos, end_pos(p.curr_tok));
		}
	}

	end := body.end;
	if else_stmt != nil {
		end = else_stmt.end;
	}
	if_stmt := ast.new(ast.If_Stmt, tok.pos, end);
	if_stmt.if_pos  = tok.pos;
	if_stmt.init      = init;
	if_stmt.cond      = cond;
	if_stmt.body      = body;
	if_stmt.else_stmt = else_stmt;
	return if_stmt;
}

parse_for_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	if p.curr_proc == nil {
		error(p, p.curr_tok.pos, "you cannot use a for statement in the file scope");
	}

	tok := expect_token(p, .For);

	init: ^ast.Stmt;
	cond: ^ast.Stmt;
	post: ^ast.Stmt;
	body: ^ast.Stmt;
	is_range := false;

	if p.curr_tok.kind != .Open_Brace && p.curr_tok.kind != .Do {
		prev_level := p.expr_level;
		defer p.expr_level = prev_level;
		p.expr_level = -1;

		if p.curr_tok.kind == .In {
			in_tok := expect_token(p, .In);
			rhs: ^ast.Expr;

			prev_allow_range := p.allow_range;
			p.allow_range = true;
			rhs = parse_expr(p, false);
			p.allow_range = prev_allow_range;

			if allow_token(p, .Do) {
				body = convert_stmt_to_body(p, parse_stmt(p));
			} else {
				body = parse_body(p);
			}

			range_stmt := ast.new(ast.Range_Stmt, tok.pos, body.end);
			range_stmt.for_pos = tok.pos;
			range_stmt.in_pos = in_tok.pos;
			range_stmt.expr = rhs;
			range_stmt.body = body;
			return range_stmt;
		}

		if p.curr_tok.kind != .Semicolon {
			cond = parse_simple_stmt(p, {Stmt_Allow_Flag.In});
			if as, ok := cond.derived.(ast.Assign_Stmt); ok && as.op.kind == .In {
				is_range = true;
			}
		}

		if !is_range && allow_token(p, .Semicolon) {
			init = cond;
			cond = nil;
			if p.curr_tok.kind != .Semicolon {
				cond = parse_simple_stmt(p, nil);
			}
			expect_semicolon(p, cond);
			if p.curr_tok.kind != .Open_Brace && p.curr_tok.kind != .Do {
				post = parse_simple_stmt(p, nil);
			}
		}
	}

	if allow_token(p, .Do) {
		body = convert_stmt_to_body(p, parse_stmt(p));
	} else {
		body = parse_body(p);
	}


	if is_range {
		assign_stmt := cond.derived.(ast.Assign_Stmt);
		val0, val1: ^ast.Expr;

		switch len(assign_stmt.lhs) {
		case 1:
			val0 = assign_stmt.lhs[0];
		case 2:
			val0 = assign_stmt.lhs[0];
			val1 = assign_stmt.lhs[1];
		case:
			error(p, cond.pos, "expected either 1 or 2 identifiers");
			return ast.new(ast.Bad_Stmt, tok.pos, body.end);
		}

		rhs: ^ast.Expr;
		if len(assign_stmt.rhs) > 0 {
			rhs = assign_stmt.rhs[0];
		}

		range_stmt := ast.new(ast.Range_Stmt, tok.pos, body.end);
		range_stmt.for_pos = tok.pos;
		range_stmt.val0 = val0;
		range_stmt.val1 = val1;
		range_stmt.in_pos = assign_stmt.op.pos;
		range_stmt.expr = rhs;
		range_stmt.body = body;
		return range_stmt;
	}

	cond_expr := convert_stmt_to_expr(p, cond, "boolean expression");
	for_stmt := ast.new(ast.For_Stmt, tok.pos, body.end);
	for_stmt.for_pos = tok.pos;
	for_stmt.init = init;
	for_stmt.cond = cond_expr;
	for_stmt.post = post;
	for_stmt.body = body;
	return for_stmt;
}

parse_case_clause :: proc(p: ^Parser, is_type_switch: bool) -> ^ast.Case_Clause {
	tok := expect_token(p, .Case);

	list: []^ast.Expr;

	if p.curr_tok.kind != .Colon {
		prev_allow_range, prev_allow_in_expr := p.allow_range, p.allow_in_expr;
		defer p.allow_range, p.allow_in_expr = prev_allow_range, prev_allow_in_expr;
		p.allow_range, p.allow_in_expr = !is_type_switch, !is_type_switch;

		list = parse_rhs_expr_list(p);
	}

	terminator := expect_token(p, .Colon);

	stmts := parse_stmt_list(p);

	cc := ast.new(ast.Case_Clause, tok.pos, end_pos(p.prev_tok));
	cc.list = list;
	cc.terminator = terminator;
	cc.body = stmts;
	return cc;
}

parse_switch_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	tok := expect_token(p, .Switch);

	init: ^ast.Stmt;
	tag:  ^ast.Stmt;
	is_type_switch := false;
	clauses: [dynamic]^ast.Stmt;

	if p.curr_tok.kind != .Open_Brace {
		prev_level := p.expr_level;
		defer p.expr_level = prev_level;
		p.expr_level = -1;

		if p.curr_tok.kind == .In {
			in_tok := expect_token(p, .In);
			is_type_switch = true;

			lhs := make([]^ast.Expr, 1);
			rhs := make([]^ast.Expr, 1);
			lhs[0] = new_blank_ident(p, tok.pos);
			rhs[0] = parse_expr(p, true);

			as := ast.new(ast.Assign_Stmt, tok.pos, rhs[0].end);
			as.lhs = lhs;
			as.op  = in_tok;
			as.rhs = rhs;
			tag = as;
		} else {
			tag = parse_simple_stmt(p, {Stmt_Allow_Flag.In});
			if as, ok := tag.derived.(ast.Assign_Stmt); ok && as.op.kind == .In {
				is_type_switch = true;
			} else if allow_token(p, .Semicolon) {
				init = tag;
				tag = nil;
				if p.curr_tok.kind != .Open_Brace {
					tag = parse_simple_stmt(p, nil);
				}
			}
		}
	}


	open := expect_token(p, .Open_Brace);

	for p.curr_tok.kind == .Case {
		clause := parse_case_clause(p, is_type_switch);
		append(&clauses, clause);
	}

	close := expect_token(p, .Close_Brace);

	body := ast.new(ast.Block_Stmt, open.pos, end_pos(close));
	body.stmts = clauses[:];

	if is_type_switch {
		ts := ast.new(ast.Type_Switch_Stmt, tok.pos, body.end);
		ts.tag  = tag;
		ts.body = body;
		return ts;
	} else {
		cond := convert_stmt_to_expr(p, tag, "switch expression");
		ts := ast.new(ast.Switch_Stmt, tok.pos, body.end);
		ts.init = init;
		ts.cond = cond;
		ts.body = body;
		return ts;
	}
}

parse_attribute :: proc(p: ^Parser, tok: tokenizer.Token, open_kind, close_kind: tokenizer.Token_Kind, docs: ^ast.Comment_Group) -> ^ast.Stmt {
	elems: [dynamic]^ast.Expr;

	open, close: tokenizer.Token;

	if p.curr_tok.kind == .Ident {
		elem := parse_ident(p);
		append(&elems, elem);
	} else {
		open = expect_token(p, open_kind);
		p.expr_level += 1;
		for p.curr_tok.kind != close_kind &&
			p.curr_tok.kind != .EOF {
			elem: ^ast.Expr;
			elem = parse_ident(p);
			if p.curr_tok.kind == .Eq {
				eq := expect_token(p, .Eq);
				value := parse_value(p);
				fv := ast.new(ast.Field_Value, elem.pos, value.end);
				fv.field = elem;
				fv.sep   = eq.pos;
				fv.value = value;

				elem = fv;
			}
			append(&elems, elem);

			if !allow_token(p, .Comma) {
				break;
			}
		}
		p.expr_level -= 1;
		close = expect_token_after(p, close_kind, "attribute");
	}

	attribute := ast.new(ast.Attribute, tok.pos, end_pos(close));
	attribute.tok   = tok.kind;
	attribute.open  = open.pos;
	attribute.elems = elems[:];
	attribute.close = close.pos;

	decl := parse_stmt(p);
	switch d in &decl.derived {
	case ast.Value_Decl:
		if d.docs == nil do d.docs = docs;
		append(&d.attributes, attribute);
	case ast.Foreign_Block_Decl:
		if d.docs == nil do d.docs = docs;
		append(&d.attributes, attribute);
	case ast.Foreign_Import_Decl:
		if d.docs == nil do d.docs = docs;
		append(&d.attributes, attribute);
	case:
		error(p, decl.pos, "expected a value or foreign declaration after an attribute");
		free(attribute);
		delete(elems);
	}
	return decl;

}

parse_foreign_block_decl :: proc(p: ^Parser) -> ^ast.Stmt {
	decl := parse_stmt(p);
	switch in decl.derived {
	case ast.Empty_Stmt, ast.Bad_Stmt, ast.Bad_Decl:
		// Ignore
		return nil;
	case ast.When_Stmt, ast.Value_Decl:
		return decl;
	}

	error(p, decl.pos, "foreign blocks only allow procedure and variable declarations");

	return nil;

}

parse_foreign_block :: proc(p: ^Parser, tok: tokenizer.Token) -> ^ast.Foreign_Block_Decl {
	docs := p.lead_comment;

	foreign_library: ^ast.Expr;
	switch p.curr_tok.kind {
	case .Open_Brace:
		i := ast.new(ast.Ident, tok.pos, end_pos(tok));
		i.name = "_";
		foreign_library = i;
	case:
		foreign_library = parse_ident(p);
	}

	decls: [dynamic]^ast.Stmt;

	prev_in_foreign_block := p.in_foreign_block;
	defer p.in_foreign_block = prev_in_foreign_block;
	p.in_foreign_block = true;

	open := expect_token(p, .Open_Brace);
	for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
		decl := parse_foreign_block_decl(p);
		if decl != nil {
			append(&decls, decl);
		}
	}
	close := expect_token(p, .Close_Brace);

	body := ast.new(ast.Block_Stmt, open.pos, end_pos(close));
	body.open = open.pos;
	body.stmts = decls[:];
	body.close = close.pos;

	decl := ast.new(ast.Foreign_Block_Decl, tok.pos, body.end);
	decl.docs            = docs;
	decl.tok             = tok;
	decl.foreign_library = foreign_library;
	decl.body            = body;
	return decl;
}


parse_foreign_decl :: proc(p: ^Parser) -> ^ast.Decl {
	docs := p.lead_comment;
	tok := expect_token(p, .Foreign);

	switch p.curr_tok.kind {
	case .Ident, .Open_Brace:
		return parse_foreign_block(p, tok);

	case .Import:
		import_tok := expect_token(p, .Import);
		name: ^ast.Ident;
		if p.curr_tok.kind == .Ident {
			name = parse_ident(p);
		}

		if name != nil && is_blank_ident(name) {
			error(p, name.pos, "illegal foreign import name: '_'");
		}

		fullpaths: [dynamic]string;
		if allow_token(p, .Open_Brace) {
			for p.curr_tok.kind != .Close_Brace &&
				p.curr_tok.kind != .EOF {
				path := expect_token(p, .String);
				append(&fullpaths, path.text);

				if !allow_token(p, .Comma) {
					break;
				}
			}
			expect_token(p, .Close_Brace);
		} else {
			path := expect_token(p, .String);
			reserve(&fullpaths, 1);
			append(&fullpaths, path.text);
		}

		if len(fullpaths) == 0 {
			error(p, import_tok.pos, "foreign import without any paths");
		}

		decl := ast.new(ast.Foreign_Import_Decl, tok.pos, end_pos(p.prev_tok));
		decl.docs            = docs;
		decl.foreign_tok     = tok;
		decl.import_tok      = import_tok;
		decl.name            = name;
		decl.fullpaths       = fullpaths[:];
		expect_semicolon(p, decl);
		decl.comment = p.line_comment;
		return decl;
	}

	error(p, tok.pos, "invalid foreign declaration");
	return ast.new(ast.Bad_Decl, tok.pos, end_pos(tok));
}


parse_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	switch p.curr_tok.kind {
	// Operands
	case .Context, // Also allows for 'context = '
	     .Proc,
	     .Inline, .No_Inline,
	     .Ident,
	     .Integer, .Float, .Imag,
	     .Rune, .String,
	     .Open_Paren,
	     .Pointer,
	     // Unary Expressions
	     .Add, .Sub, .Xor, .Not, .And:
	    s := parse_simple_stmt(p, {Stmt_Allow_Flag.Label});
	    expect_semicolon(p, s);
		return s;


	case .Import:  return parse_import_decl(p);
	case .Foreign: return parse_foreign_decl(p);
	case .If:      return parse_if_stmt(p);
	case .When:    return parse_when_stmt(p);
	case .For:     return parse_for_stmt(p);
	case .Switch:  return parse_switch_stmt(p);

	case .Defer:
		tok := advance_token(p);
		stmt := parse_stmt(p);
		switch s in stmt.derived {
		case ast.Empty_Stmt:
			error(p, s.pos, "empty statement after defer (e.g. ';')");
		case ast.Defer_Stmt:
			error(p, s.pos, "you cannot defer a defer statement");
			stmt = s.stmt;
		case ast.Return_Stmt:
			error(p, s.pos, "you cannot defer a return statement");
		}
		ds := ast.new(ast.Defer_Stmt, tok.pos, stmt.end);
		ds.stmt = stmt;
		return ds;

	case .Return:
		tok := advance_token(p);

		if p.expr_level > 0 {
			error(p, tok.pos, "you cannot use a return statement within an expression");
		}

		results: [dynamic]^ast.Expr;
		for p.curr_tok.kind != .Semicolon {
			result := parse_expr(p, false);
			append(&results, result);
			if p.curr_tok.kind != .Comma ||
			   p.curr_tok.kind == .EOF {
				break;
			}
			advance_token(p);
		}

		end := end_pos(tok);
		if len(results) > 0 {
			end = results[len(results)-1].pos;
		}

		rs := ast.new(ast.Return_Stmt, tok.pos, end);
		rs.results = results[:];
		return rs;

	case .Break, .Continue, .Fallthrough:
		tok := advance_token(p);
		label: ^ast.Expr;
		if tok.kind != .Fallthrough && p.curr_tok.kind == .Ident {
			label = parse_ident(p);
		}
		end := label != nil ? label.end : end_pos(tok);
		s := ast.new(ast.Branch_Stmt, tok.pos, end);
		expect_semicolon(p, s);
		return s;

	case .Using:
		docs := p.lead_comment;
		tok := expect_token(p, .Using);

		if p.curr_tok.kind == .Import {
			return parse_import_decl(p, Import_Decl_Kind.Using);
		}

		list := parse_lhs_expr_list(p);
		if len(list) == 0 {
			error(p, tok.pos, "illegal use of 'using' statement");
			expect_semicolon(p, nil);
			return ast.new(ast.Bad_Stmt, tok.pos, end_pos(p.prev_tok));
		}

		if p.curr_tok.kind != .Colon {
			end := list[len(list)-1];
			expect_semicolon(p, end);
			us := ast.new(ast.Using_Stmt, tok.pos, end.end);
			us.list = list;
			return us;
		}
		expect_token_after(p, .Colon, "identifier list");
		decl := parse_value_decl(p, list, docs);
		if decl != nil do switch d in &decl.derived {
		case ast.Value_Decl:
			d.is_using = true;
			return decl;
		}

		error(p, tok.pos, "illegal use of 'using' statement");
		return ast.new(ast.Bad_Stmt, tok.pos, end_pos(p.prev_tok));

	case .At:
		docs := p.lead_comment;
		tok := advance_token(p);
		return parse_attribute(p, tok, .Open_Paren, .Close_Paren, docs);

	case .Hash:
		tok := expect_token(p, .Hash);
		tag := expect_token(p, .Ident);
		name := tag.text;

		switch name {
		case "bounds_check", "no_bounds_check":
			stmt := parse_stmt(p);
			switch name {
			case "bounds_check":
				stmt.state_flags |= {.Bounds_Check};
			case "no_bounds_check":
				stmt.state_flags |= {.No_Bounds_Check};
			}
			return stmt;
		case "complete":
			stmt := parse_stmt(p);
			switch s in &stmt.derived {
			case ast.Switch_Stmt:      s.complete = true;
			case ast.Type_Switch_Stmt: s.complete = true;
			case: error(p, stmt.pos, "#complete can only be applied to a switch statement");
			}
			return stmt;
		case "assert", "panic":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(tag));
			bd.tok  = tok;
			bd.name = name;
			ce := parse_call_expr(p, bd);
			es := ast.new(ast.Expr_Stmt, ce.pos, ce.end);
			es.expr = ce;
			return es;
		case "include":
			error(p, tag.pos, "#include is not a valid import declaration kind. Did you meant 'import'?");
			return ast.new(ast.Bad_Stmt, tok.pos, end_pos(tag));
		case:
			stmt := parse_stmt(p);
			te := ast.new(ast.Tag_Stmt, tok.pos, stmt.pos);
			te.op   = tok;
			te.name = name;
			te.stmt = stmt;
			return te;
		}
	case .Open_Brace:
		return parse_block_stmt(p, false);

	case .Semicolon:
		tok := advance_token(p);
		s := ast.new(ast.Empty_Stmt, tok.pos, end_pos(tok));
		return s;
	}

	tok := advance_token(p);
	error(p, tok.pos, "expected a statement, got %s", tokenizer.to_string(tok.kind));
	s := ast.new(ast.Bad_Stmt, tok.pos, end_pos(tok));
	return s;
}


token_precedence :: proc(p: ^Parser, kind: tokenizer.Token_Kind) -> int {
	switch kind {
	case .Question:
		return 1;
	case .Ellipsis, .Range_Half:
		if !p.allow_range {
			return 0;
		}
		return 2;
	case .Cmp_Or:
		return 3;
	case .Cmp_And:
		return 4;
	case .Cmp_Eq, .Not_Eq,
	     .Lt, .Gt,
	     .Lt_Eq, .Gt_Eq:
		return 5;
	case .In, .Notin:
		if p.expr_level < 0 && !p.allow_in_expr {
			return 0;
		}
		fallthrough;
	case .Add, .Sub, .Or, .Xor:
		return 6;
	case .Mul, .Quo,
	     .Mod, .Mod_Mod,
	     .And, .And_Not,
	     .Shl, .Shr:
		return 7;
	}
	return 0;
}

parse_type_or_ident :: proc(p: ^Parser) -> ^ast.Expr {
	prev_allow_type := p.allow_type;
	prev_expr_level := p.expr_level;
	defer {
		p.allow_type = prev_allow_type;
		p.expr_level = prev_expr_level;
	}

	p.allow_type = true;
	p.expr_level = -1;

	lhs := true;
	return parse_atom_expr(p, parse_operand(p, lhs), lhs);
}
parse_type :: proc(p: ^Parser) -> ^ast.Expr {
	type := parse_type_or_ident(p);
	if type == nil {
		error(p, p.curr_tok.pos, "expected a type");
		return ast.new(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok));
	}
	return type;
}

parse_body :: proc(p: ^Parser) -> ^ast.Block_Stmt {
	prev_expr_level := p.expr_level;
	defer p.expr_level = prev_expr_level;

	p.expr_level = 0;
	open := expect_token(p, .Open_Brace);
	stmts := parse_stmt_list(p);
	close := expect_token(p, .Close_Brace);

	bs := ast.new(ast.Block_Stmt, open.pos, end_pos(close));
	bs.open = open.pos;
	bs.stmts = stmts;
	bs.close = close.pos;
	return bs;
}

convert_stmt_to_body :: proc(p: ^Parser, stmt: ^ast.Stmt) -> ^ast.Stmt {
	switch s in stmt.derived {
	case ast.Block_Stmt:
		error(p, stmt.pos, "expected a normal statement rather than a block statement");
		return stmt;
	case ast.Empty_Stmt:
		error(p, stmt.pos, "expected a non-empty statement");
	}

	bs := ast.new(ast.Block_Stmt, stmt.pos, stmt.end);
	bs.open = stmt.pos;
	bs.stmts = make([]^ast.Stmt, 1);
	bs.stmts[0] = stmt;
	bs.close = stmt.end;
	return bs;
}

new_ast_field :: proc(names: []^ast.Expr, type: ^ast.Expr, default_value: ^ast.Expr) -> ^ast.Field {
	pos, end: tokenizer.Pos;

	if len(names) > 0 {
		pos = names[0].pos;
		if default_value != nil {
			end = default_value.end;
		} else if type != nil {
			end = type.end;
		} else {
			end = names[len(names)-1].pos;
		}
	} else {
		if type != nil {
			pos = type.pos;
		} else if default_value != nil {
			pos = default_value.pos;
		}

		if default_value != nil {
			end = default_value.end;
		} else if type != nil {
			end = type.end;
		}
	}

	field := ast.new(ast.Field, pos, end);
	field.names = names;
	field.type  = type;
	field.default_value = default_value;
	return field;
}


Field_Prefix :: enum {
	Invalid,
	Unknown,

	Using,
	No_Alias,
	C_Vararg,
	In,
	Auto_Cast,
}

Field_Prefixes :: distinct bit_set[Field_Prefix];

Expr_And_Flags :: struct {
	expr:  ^ast.Expr,
	flags: ast.Field_Flags,
}

convert_to_ident_list :: proc(p: ^Parser, list: []Expr_And_Flags, ignore_flags, allow_poly_names: bool) -> []^ast.Expr {
	idents := make([dynamic]^ast.Expr, 0, len(list));

	for ident, i in list {
		if !ignore_flags {
			if i != 0 {
				error(p, ident.expr.pos, "illegal use of prefixes in parameter list");
			}
		}

		id: ^ast.Expr = ident.expr;

		switch n in ident.expr.derived {
		case ast.Ident:
		case ast.Bad_Expr:
		case ast.Poly_Type:
			if allow_poly_names {
				if n.specialization == nil {
					break;
				} else {
					error(p, ident.expr.pos, "expected a polymorphic identifier without an specialization");
				}
			} else {
				error(p, ident.expr.pos, "expected a non-polymorphic identifier");
			}
		case:
			error(p, ident.expr.pos, "expected an identifier");
			id = ast.new(ast.Ident, ident.expr.pos, ident.expr.end);
		}

		append(&idents, id);
	}

	return idents[:];
}

is_token_field_prefix :: proc(p: ^Parser) -> Field_Prefix {
	using Field_Prefix;
	switch p.curr_tok.kind {
	case .EOF:
		return Invalid;
	case .Using:
		advance_token(p);
		return Using;
	case .In:
		advance_token(p);
		return In;
	case .Auto_Cast:
		advance_token(p);
		return Auto_Cast;
	case .Hash:
		advance_token(p);
		defer advance_token(p);
		switch p.curr_tok.kind {
		case .Ident:
			switch p.curr_tok.text {
			case "no_alias":
				return No_Alias;
			case "c_vararg":
				return C_Vararg;
			}
		}
		return Unknown;
	}
	return Invalid;
}

parse_field_prefixes :: proc(p: ^Parser) -> ast.Field_Flags {
	counts: [len(Field_Prefix)]int;

	for {
		kind := is_token_field_prefix(p);
		if kind == Field_Prefix.Invalid {
			break;
		}

		if kind == Field_Prefix.Unknown {
			error(p, p.curr_tok.pos, "unknown prefix kind '#%s'", p.curr_tok.text);
			continue;
		}

		counts[kind] += 1;
	}

	flags: ast.Field_Flags;

	for kind in Field_Prefix {
		count := counts[kind];
		using Field_Prefix;
		#complete switch kind {
		case Invalid, Unknown: // Ignore
		case Using:
			if count > 1 do error(p, p.curr_tok.pos, "multiple 'using' in this field list");
			if count > 0 do flags |= {ast.Field_Flag.Using};
		case No_Alias:
			if count > 1 do error(p, p.curr_tok.pos, "multiple '#no_alias' in this field list");
			if count > 0 do flags |= {ast.Field_Flag.No_Alias};
		case C_Vararg:
			if count > 1 do error(p, p.curr_tok.pos, "multiple '#c_vararg' in this field list");
			if count > 0 do flags |= {ast.Field_Flag.C_Vararg};
		case In:
			if count > 1 do error(p, p.curr_tok.pos, "multiple 'in' in this field list");
			if count > 0 do flags |= {ast.Field_Flag.In};
		case Auto_Cast:
			if count > 1 do error(p, p.curr_tok.pos, "multiple 'auto_cast' in this field list");
			if count > 0 do flags |= {ast.Field_Flag.Auto_Cast};
		}
	}

	return flags;
}

check_field_flag_prefixes :: proc(p: ^Parser, name_count: int, allowed_flags, set_flags: ast.Field_Flags) -> (flags: ast.Field_Flags) {
	flags = set_flags;
	if name_count > 1 && ast.Field_Flag.Using in flags {
		error(p, p.curr_tok.pos, "cannot apply 'using' to more than one of the same type");
		flags &~= {ast.Field_Flag.Using};
	}

	for flag in ast.Field_Flag {
		if flag notin allowed_flags && flag in flags {
			#complete switch flag {
			case .Using:
				error(p, p.curr_tok.pos, "'using' is not allowed within this field list");
			case .No_Alias:
				error(p, p.curr_tok.pos, "'#no_alias' is not allowed within this field list");
			case .C_Vararg:
				error(p, p.curr_tok.pos, "'#c_vararg' is not allowed within this field list");
			case .Auto_Cast:
				error(p, p.curr_tok.pos, "'auto_cast' is not allowed within this field list");
			case .In:
				error(p, p.curr_tok.pos, "'in' is not allowed within this field list");
			case .Tags, .Ellipsis, .Results, .Default_Parameters, .Typeid_Token:
				panic("Impossible prefixes");
			}
			flags &~= {flag};
		}
	}

	if ast.Field_Flag.Using in allowed_flags && ast.Field_Flag.Using in flags {
		flags &~= {ast.Field_Flag.Using};
	}

	return flags;
}

parse_var_type :: proc(p: ^Parser, flags: ast.Field_Flags) -> ^ast.Expr {
	if ast.Field_Flag.Ellipsis in flags && p.curr_tok.kind == .Ellipsis {
		tok := advance_token(p);
		type := parse_type_or_ident(p);
		if type == nil {
			error(p, tok.pos, "variadic field missing type after '..'");
			type = ast.new(ast.Bad_Expr, tok.pos, end_pos(tok));
		}
		e := ast.new(ast.Ellipsis, type.pos, type.end);
		e.expr = type;
		return e;
	}
	type: ^ast.Expr;
	if ast.Field_Flag.Typeid_Token in flags && p.curr_tok.kind == .Typeid {
		tok := expect_token(p, .Typeid);
		specialization: ^ast.Expr;
		end := tok.pos;
		if allow_token(p, .Quo) {
			specialization = parse_type(p);
			end = specialization.end;
		}

		ti := ast.new(ast.Typeid_Type, tok.pos, end);
		ti.tok = tok.kind;
		ti.specialization = specialization;
		type = ti;
	} else {
		type = parse_type(p);
	}

	return type;
}

check_procedure_name_list :: proc(p: ^Parser, names: []^ast.Expr) -> bool {
	if len(names) == 0 {
		return false;
	}

	_, first_is_polymorphic := names[0].derived.(ast.Poly_Type);
	any_polymorphic_names := first_is_polymorphic;

	for i := 1; i < len(names); i += 1 {
		name := names[i];

		if first_is_polymorphic {
			if _, ok := name.derived.(ast.Poly_Type); ok {
				any_polymorphic_names = true;
			} else {
				error(p, name.pos, "mixture of polymorphic and non-polymorphic identifiers");
				return any_polymorphic_names;
			}
		} else {
			if _, ok := name.derived.(ast.Poly_Type); ok {
				any_polymorphic_names = true;
				error(p, name.pos, "mixture of polymorphic and non-polymorphic identifiers");
				return any_polymorphic_names;
			} else {
				// Okay
			}
		}
	}

	return any_polymorphic_names;
}

parse_ident_list :: proc(p: ^Parser, allow_poly_names: bool) -> []^ast.Expr {
	list: [dynamic]^ast.Expr;

	for {
		if allow_poly_names && p.curr_tok.kind == .Dollar {
			tok := expect_token(p, .Dollar);
			ident := parse_ident(p);
			if is_blank_ident(ident) {
				error(p, ident.pos, "invalid polymorphic type definition with a blank identifier");
			}
			poly_name := ast.new(ast.Poly_Type, tok.pos, ident.end);
			poly_name.type = ident;
			append(&list, poly_name);
		} else {
			ident := parse_ident(p);
			append(&list, ident);
		}
		if p.curr_tok.kind != .Comma ||
		   p.curr_tok.kind == .EOF {
		   	break;
		}
		advance_token(p);
	}

	return list[:];
}



parse_field_list :: proc(p: ^Parser, follow: tokenizer.Token_Kind, allowed_flags: ast.Field_Flags) -> (field_list: ^ast.Field_List, total_name_count: int) {
	handle_field :: proc(p: ^Parser,
	                     seen_ellipsis: ^bool, fields: ^[dynamic]^ast.Field,
	                     docs: ^ast.Comment_Group,
	                     names: []^ast.Expr,
	                     allowed_flags, set_flags: ast.Field_Flags
	                     ) -> bool {

		expect_field_separator :: proc(p: ^Parser, param: ^ast.Expr) -> bool {
			tok := p.curr_tok;
			if allow_token(p, .Comma) {
				return true;
			}
			if allow_token(p, .Semicolon) {
				error(p, tok.pos, "expected a comma, got a semicolon");
				return true;
			}
			return false;
		}
		is_type_ellipsis :: proc(type: ^ast.Expr) -> bool {
			if type == nil do return false;
			_, ok := type.derived.(ast.Ellipsis);
			return ok;
		}

		is_signature := (allowed_flags & ast.Field_Flags_Signature_Params) == ast.Field_Flags_Signature_Params;

		any_polymorphic_names := check_procedure_name_list(p, names);
		flags := check_field_flag_prefixes(p, len(names), allowed_flags, set_flags);

		type:          ^ast.Expr;
		default_value: ^ast.Expr;
		tag: tokenizer.Token;

		expect_token_after(p, .Colon, "field list");
		if p.curr_tok.kind != .Eq {
			type = parse_var_type(p, allowed_flags);
			tt := ast.unparen_expr(type);
			if is_signature && !any_polymorphic_names {
				if ti, ok := tt.derived.(ast.Typeid_Type); ok && ti.specialization != nil {
					error(p, tt.pos, "specialization of typeid is not allowed without polymorphic names");
				}
			}
		}

		if allow_token(p, .Eq) {
			default_value = parse_expr(p, false);
			if ast.Field_Flag.Default_Parameters notin allowed_flags {
				error(p, p.curr_tok.pos, "default parameters are only allowed for procedures");
				default_value = nil;
			}
		}

		if default_value != nil && len(names) > 1 {
			error(p, p.curr_tok.pos, "default parameters can only be applied to single values");
		}

		if allowed_flags == ast.Field_Flags_Struct && default_value != nil {
			error(p, default_value.pos, "default parameters are not allowed for structs");
			default_value = nil;
		}

		if is_type_ellipsis(type) {
			if seen_ellipsis^ do error(p, type.pos, "extra variadic parameter after ellipsis");
			seen_ellipsis^ = true;
			if len(names) != 1 {
				error(p, type.pos, "variadic parameters can only have one field name");
			}
		} else if seen_ellipsis^ && default_value == nil {
			error(p, p.curr_tok.pos, "extra parameter after ellipsis without a default value");
		}

		if type != nil && default_value == nil {
			if p.curr_tok.kind == .String {
				tag = expect_token(p, .String);
				if .Tags notin allowed_flags {
					error(p, tag.pos, "Field tags are only allowed within structures");
				}
			}
		}

		ok := expect_field_separator(p, type);

		field := new_ast_field(names, type, default_value);
		field.tag     = tag;
		field.docs    = docs;
		field.flags   = flags;
		field.comment = p.line_comment;
		append(fields, field);

		return ok;
	}


	start_tok := p.curr_tok;

	docs := p.lead_comment;

	fields: [dynamic]^ast.Field;

	list: [dynamic]Expr_And_Flags;
	defer delete(list);

	seen_ellipsis := false;

	allow_typeid_token := ast.Field_Flag.Typeid_Token in allowed_flags;
	allow_poly_names := allow_typeid_token;

	for p.curr_tok.kind != follow &&
	    p.curr_tok.kind != .Colon &&
	    p.curr_tok.kind != .EOF {
		prefix_flags := parse_field_prefixes(p);
		param := parse_var_type(p, allowed_flags & {ast.Field_Flag.Typeid_Token, ast.Field_Flag.Ellipsis});
		if _, ok := param.derived.(ast.Ellipsis); ok {
			if seen_ellipsis {
				error(p, param.pos, "extra variadic parameter after ellipsis");
			}
			seen_ellipsis = true;
		} else if seen_ellipsis {
			error(p, param.pos, "extra parameter after ellipsis");
		}

		eaf := Expr_And_Flags{param, prefix_flags};
		append(&list, eaf);
		if !allow_token(p, .Comma) {
			break;
		}
	}

	if p.curr_tok.kind != .Colon {
		for eaf in list {
			type := eaf.expr;
			tok: tokenizer.Token;
			tok.pos = type.pos;
			if ast.Field_Flag.Results notin allowed_flags {
				tok.text = "_";
			}

			names := make([]^ast.Expr, 1);
			names[0] = ast.new(ast.Ident, tok.pos, end_pos(tok));
			names[0].derived.(ast.Ident).name = tok.text;

			flags := check_field_flag_prefixes(p, len(list), allowed_flags, eaf.flags);

			field := new_ast_field(names, type, nil);
			field.docs    = docs;
			field.flags   = flags;
			field.comment = p.line_comment;
			append(&fields, field);
		}
	} else {
		names := convert_to_ident_list(p, list[:], true, allow_poly_names);
		if len(names) == 0 {
			error(p, p.curr_tok.pos, "empty field declaration");
		}

		set_flags: ast.Field_Flags;
		if len(list) > 0 {
			set_flags = list[0].flags;
		}
		total_name_count += len(names);
		handle_field(p, &seen_ellipsis, &fields, docs, names, allowed_flags, set_flags);

		for p.curr_tok.kind != follow && p.curr_tok.kind != .EOF {
			docs = p.lead_comment;
			set_flags = parse_field_prefixes(p);
			names = parse_ident_list(p, allow_poly_names);

			total_name_count += len(names);
			ok := handle_field(p, &seen_ellipsis, &fields, docs, names, allowed_flags, set_flags);
			if !ok {
				break;
			}
		}
	}

	field_list = ast.new(ast.Field_List, start_tok.pos, p.curr_tok.pos);
	field_list.list = fields[:];
	return;
}


parse_results :: proc(p: ^Parser) -> (list: ^ast.Field_List, diverging: bool) {
	if !allow_token(p, .Arrow_Right) {
		return;
	}

	if allow_token(p, .Not) {
		diverging = true;
		return;
	}

	prev_level := p.expr_level;
	defer p.expr_level = prev_level;

	if p.curr_tok.kind != .Open_Paren {
		type := parse_type(p);
		field := new_ast_field(nil, type, nil);

		list = ast.new(ast.Field_List, field.pos, field.end);
		list.list = make([]^ast.Field, 1);
		list.list[0] = field;
		return;
	}

	expect_token(p, .Open_Paren);
	list, _ = parse_field_list(p, .Close_Paren, ast.Field_Flags_Signature_Results);
	expect_token_after(p, .Close_Paren, "parameter list");
	return;
}


string_to_calling_convention :: proc(s: string) -> ast.Proc_Calling_Convention {
	using ast.Proc_Calling_Convention;
	if s[0] != '"' && s[0] != '`' {
		return Invalid;
	}
	switch s[1:len(s)-1] {
	case "odin":
		return Odin;
	case "contextless":
		return Contextless;
	case "cdecl", "c":
		return C_Decl;
	case "stdcall", "std":
		return Std_Call;
	case "fast", "fastcall":
		return Fast_Call;
	}
	return Invalid;
}

parse_proc_tags :: proc(p: ^Parser) -> (tags: ast.Proc_Tags) {
	for p.curr_tok.kind == .Hash {
		_ = expect_token(p, .Hash);
		ident := expect_token(p, .Ident);

		switch ident.text {
		case "bounds_check":
			tags |= {.Bounds_Check};
		case "no_bounds_check":
			tags |= {.No_Bounds_Check};
		case:
		}
	}

	if .Bounds_Check in tags && .No_Bounds_Check in tags {
		p.err(p.curr_tok.pos, "#bounds_check and #no_bounds_check applied to the same procedure type");
	}

	return;
}

parse_proc_type :: proc(p: ^Parser, tok: tokenizer.Token) -> ^ast.Proc_Type {
	cc := ast.Proc_Calling_Convention.Invalid;
	if p.curr_tok.kind == .String {
		str := expect_token(p, .String);
		cc = string_to_calling_convention(str.text);
		if cc == ast.Proc_Calling_Convention.Invalid {
			error(p, str.pos, "unknown calling convention '%s'", str.text);
		}
	}

	if cc == ast.Proc_Calling_Convention.Invalid {
		if p.in_foreign_block {
			cc = ast.Proc_Calling_Convention.Foreign_Block_Default;
		} else {
			cc = ast.Proc_Calling_Convention.Odin;
		}
	}

	expect_token(p, .Open_Paren);
	params, _ := parse_field_list(p, .Close_Paren, ast.Field_Flags_Signature_Params);
	expect_token(p, .Close_Paren);
	results, diverging := parse_results(p);

	is_generic := false;

	loop: for param in params.list {
		if param.type != nil {
			if _, ok := param.type.derived.(ast.Poly_Type); ok {
				is_generic = true;
				break loop;
			}
			for name in param.names {
				if _, ok := name.derived.(ast.Poly_Type); ok {
					is_generic = true;
					break loop;
				}
			}
		}
	}

	end := end_pos(p.prev_tok);
	pt := ast.new(ast.Proc_Type, tok.pos, end);
	pt.tok = tok;
	pt.calling_convention = cc;
	pt.params = params;
	pt.results = results;
	pt.diverging = diverging;
	pt.generic = is_generic;
	return pt;
}

check_poly_params_for_type :: proc(p: ^Parser, poly_params: ^ast.Field_List, tok: tokenizer.Token) {
	if poly_params == nil {
		return;
	}
	for field in poly_params.list {
		for name in field.names {
			if name == nil do continue;
			if _, ok := name.derived.(ast.Poly_Type); ok {
				error(p, name.pos, "polymorphic names are not needed for %s parameters", tok.text);
				return;
			}
		}
	}
}



parse_operand :: proc(p: ^Parser, lhs: bool) -> ^ast.Expr {
	switch p.curr_tok.kind {
	case .Ident:
		return parse_ident(p);

	case .Undef:
		tok := expect_token(p, .Undef);
		undef := ast.new(ast.Undef, tok.pos, end_pos(tok));
		undef.tok = tok.kind;
		return undef;

	case .Context:
		tok := expect_token(p, .Context);
		ctx := ast.new(ast.Implicit, tok.pos, end_pos(tok));
		ctx.tok = tok;
		return ctx;

	case .Integer, .Float, .Imag,
	     .Rune, .String:
	     tok := advance_token(p);
	     bl := ast.new(ast.Basic_Lit, tok.pos, end_pos(tok));
	     bl.tok = tok;
	     return bl;


	case .Size_Of, .Align_Of, .Offset_Of:
		tok := advance_token(p);
		expr := ast.new(ast.Implicit, tok.pos, end_pos(tok));
		expr.tok = tok;
		return parse_call_expr(p, expr);

	case .Open_Brace:
		if !lhs {
			return parse_literal_value(p, nil);
		}

	case .Open_Paren:
		open := expect_token(p, .Open_Paren);
		p.expr_level += 1;
		expr := parse_expr(p, false);
		p.expr_level -= 1;
		close := expect_token(p, .Close_Paren);

		pe := ast.new(ast.Paren_Expr, open.pos, end_pos(close));
		pe.open  = open.pos;
		pe.expr  = expr;
		pe.close = close.pos;
		return pe;

	case .Distinct:
		tok := advance_token(p);
		type := parse_type(p);
		dt := ast.new(ast.Distinct_Type, tok.pos, type.end);
		dt.tok  = tok.kind;
		dt.type = type;
		return dt;

	case .Opaque:
		tok := advance_token(p);
		type := parse_type(p);
		ot := ast.new(ast.Opaque_Type, tok.pos, type.end);
		ot.tok  = tok.kind;
		ot.type = type;
		return ot;
	case .Hash:
		tok := expect_token(p, .Hash);
		name := expect_token(p, .Ident);
		switch name.text {
		case "type":
			type := parse_type(p);
			hp := ast.new(ast.Helper_Type, tok.pos, type.end);
			hp.tok  = tok.kind;
			hp.type = type;
			return hp;

		case "file", "line", "procedure", "caller_location":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(name));
			bd.tok  = tok;
			bd.name = name.text;
			return bd;
		case "location", "load", "assert", "defined":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(name));
			bd.tok  = tok;
			bd.name = name.text;
			return parse_call_expr(p, bd);


		case "soa", "vector":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(name));
			bd.tok  = tok;
			bd.name = name.text;
			original_type := parse_type(p);
			type := ast.unparen_expr(original_type);
			switch t in &type.derived {
			case ast.Array_Type:         t.tag = bd;
			case ast.Dynamic_Array_Type: t.tag = bd;
			case:
				error(p, original_type.pos, "expected an array type after #%s");
			}
			return original_type;
		case:
			expr := parse_expr(p, lhs);
			te := ast.new(ast.Tag_Expr, tok.pos, expr.pos);
			te.op   = tok;
			te.name = name.text;
			te.expr = expr;
			return te;
		}

	case .Inline, .No_Inline:
		tok := advance_token(p);
		expr := parse_unary_expr(p, lhs);

		pi := ast.Proc_Inlining.None;
		switch tok.kind {
		case .Inline:
			pi = ast.Proc_Inlining.Inline;
		case .No_Inline:
			pi = ast.Proc_Inlining.No_Inline;
		}

		switch e in &ast.unparen_expr(expr).derived {
		case ast.Proc_Lit:
			if e.inlining != ast.Proc_Inlining.None && e.inlining != pi {
				error(p, expr.pos, "both 'inline' and 'no_inline' cannot be applied to a procedure literal");
			}
			e.inlining = pi;
		case ast.Call_Expr:
			if e.inlining != ast.Proc_Inlining.None && e.inlining != pi {
				error(p, expr.pos, "both 'inline' and 'no_inline' cannot be applied to a procedure call");
			}
			e.inlining = pi;
		case:
			error(p, tok.pos, "'%s' must be followed by a procedure literal or call", tok.text);
			return ast.new(ast.Bad_Expr, tok.pos, expr.end);
		}
		return expr;

	case .Proc:
		tok := expect_token(p, .Proc);

		if p.curr_tok.kind == .Open_Brace {
			open := expect_token(p, .Open_Brace);

			args: [dynamic]^ast.Expr;

			for p.curr_tok.kind != .Close_Brace &&
			    p.curr_tok.kind != .EOF {
				elem := parse_expr(p, false);
				append(&args, elem);

				if !allow_token(p, .Comma) {
					break;
				}
			}

			close := expect_token(p, .Close_Brace);

			if len(args) == 0 {
				error(p, tok.pos, "expected at least 1 argument in procedure group");
			}

			pg := ast.new(ast.Proc_Group, tok.pos, end_pos(close));
			pg.tok   = tok;
			pg.open  = open.pos;
			pg.args  = args[:];
			pg.close = close.pos;
			return pg;
		}

		type := parse_proc_type(p, tok);

		where_token: tokenizer.Token;
		where_clauses: []^ast.Expr;
		if (p.curr_tok.kind == .Where) {
			where_token = expect_token(p, .Where);
			prev_level := p.expr_level;
			p.expr_level = -1;
			where_clauses = parse_rhs_expr_list(p);
			p.expr_level = prev_level;
		}

		if p.allow_type && p.expr_level < 0 {
			if where_token.kind != .Invalid {
				error(p, where_token.pos, "'where' clauses are not allowed on procedure types");
			}
			return type;
		}
		body: ^ast.Stmt;

		if allow_token(p, .Undef) {
			// Okay
			if where_token.kind != .Invalid {
				error(p, where_token.pos, "'where' clauses are not allowed on procedure literals without a defined body (replaced with ---");
			}
		} else if p.curr_tok.kind == .Open_Brace {
			prev_proc := p.curr_proc;
			p.curr_proc = type;
			body = parse_body(p);
			p.curr_proc = prev_proc;
		} else if allow_token(p, .Do) {
			prev_proc := p.curr_proc;
			p.curr_proc = type;
			body = convert_stmt_to_body(p, parse_stmt(p));
			p.curr_proc = prev_proc;
		} else {
			return type;
		}

		pl := ast.new(ast.Proc_Lit, tok.pos, end_pos(p.prev_tok));
		pl.type = type;
		pl.body = body;
		pl.where_token = where_token;
		pl.where_clauses = where_clauses;
		return pl;

	case .Dollar:
		tok := advance_token(p);
		type := parse_ident(p);
		end := type.end;

		specialization: ^ast.Expr;
		if allow_token(p, .Quo) {
			specialization = parse_type(p);
			end = specialization.pos;
		}
		if is_blank_ident(type) {
			error(p, type.pos, "invalid polymorphic type definition with a blank identifier");
		}

		pt := ast.new(ast.Poly_Type, tok.pos, end);
		pt.dollar = tok.pos;
		pt.type = type;
		pt.specialization = specialization;
		return pt;

	case .Typeid:
		tok := advance_token(p);
		ti := ast.new(ast.Typeid_Type, tok.pos, end_pos(tok));
		ti.tok = tok.kind;
		ti.specialization = nil;
		return ti;

	case .Type_Of:
		tok := advance_token(p);
		i := ast.new(ast.Implicit, tok.pos, end_pos(tok));
		i.tok = tok;
		type: ^ast.Expr = parse_call_expr(p, i);
		for p.curr_tok.kind == .Period {
			period := advance_token(p);

			field := parse_ident(p);
			sel := ast.new(ast.Selector_Expr, period.pos, field.end);
			sel.expr = type;
			sel.field = field;

			type = sel;
		}

		return type;


	case .Pointer:
		tok := expect_token(p, .Pointer);
		elem := parse_type(p);
		ptr := ast.new(ast.Pointer_Type, tok.pos, elem.end);
		ptr.elem = elem;
		return ptr;

	case .Open_Bracket:
		open := expect_token(p, .Open_Bracket);
		count: ^ast.Expr;
		if p.curr_tok.kind == .Question {
			tok := expect_token(p, .Question);
			q := ast.new(ast.Unary_Expr, tok.pos, end_pos(tok));
			q.op = tok;
			count = q;
		} else if p.curr_tok.kind == .Dynamic {
			tok := expect_token(p, .Dynamic);
			close := expect_token(p, .Close_Bracket);
			elem := parse_type(p);
			da := ast.new(ast.Dynamic_Array_Type, open.pos, elem.end);
			da.open = open.pos;
			da.dynamic_pos = tok.pos;
			da.close = close.pos;
			da.elem = elem;

			return da;
		} else if p.curr_tok.kind != .Close_Bracket {
			p.expr_level += 1;
			count = parse_expr(p, false);
			p.expr_level -= 1;
		}
		close := expect_token(p, .Close_Bracket);
		elem := parse_type(p);
		at := ast.new(ast.Array_Type, open.pos, elem.end);
		at.open  = open.pos;
		at.len   = count;
		at.close = close.pos;
		at.elem  = elem;
		return at;

	case .Map:
		tok := expect_token(p, .Map);
		expect_token(p, .Open_Bracket);
		key := parse_type(p);
		expect_token(p, .Close_Bracket);
		value := parse_type(p);

		mt := ast.new(ast.Map_Type, tok.pos, value.end);
		mt.tok_pos = tok.pos;
		mt.key = key;
		mt.value = value;
		return mt;

	case .Struct:
		tok := expect_token(p, .Struct);

		poly_params: ^ast.Field_List;
		align:        ^ast.Expr;
		is_packed:    bool;
		is_raw_union: bool;
		fields:       ^ast.Field_List;
		name_count:   int;

		if allow_token(p, .Open_Paren) {
			param_count: int;
			poly_params, param_count = parse_field_list(p, .Close_Paren, ast.Field_Flags_Record_Poly_Params);
			if param_count == 0 {
				error(p, poly_params.pos, "expected at least 1 polymorphic parameter");
				poly_params = nil;
			}
			expect_token_after(p, .Close_Paren, "parameter list");
			check_poly_params_for_type(p, poly_params, tok);
		}

		prev_level := p.expr_level;
		p.expr_level = -1;
		for allow_token(p, .Hash) {
			tag := expect_token_after(p, .Ident, "#");
			switch tag.text {
			case "packed":
				if is_packed do error(p, tag.pos, "duplicate struct tag '#%s'", tag.text);
				is_packed = true;
			case "align":
				if align != nil do error(p, tag.pos, "duplicate struct tag '#%s'", tag.text);
				align = parse_expr(p, true);
			case "raw_union":
				if is_raw_union do error(p, tag.pos, "duplicate struct tag '#%s'", tag.text);
				is_raw_union = true;
			case:
				error(p, tag.pos, "invalid struct tag '#%s", tag.text);
			}
		}
		p.expr_level = prev_level;

		if is_raw_union && is_packed {
			is_packed = false;
			error(p, tok.pos, "'#raw_union' cannot also be '#packed");
		}

		where_token: tokenizer.Token;
		where_clauses: []^ast.Expr;
		if (p.curr_tok.kind == .Where) {
			where_token = expect_token(p, .Where);
			prev_level := p.expr_level;
			p.expr_level = -1;
			where_clauses = parse_rhs_expr_list(p);
			p.expr_level = prev_level;
		}

		expect_token(p, .Open_Brace);
		fields, name_count = parse_field_list(p, .Close_Brace, ast.Field_Flags_Struct);
		close := expect_token(p, .Close_Brace);

		st := ast.new(ast.Struct_Type, tok.pos, end_pos(close));
		st.poly_params   = poly_params;
		st.align         = align;
		st.is_packed     = is_packed;
		st.is_raw_union  = is_raw_union;
		st.fields        = fields;
		st.name_count    = name_count;
		st.where_token   = where_token;
		st.where_clauses = where_clauses;
		return st;

	case .Union:
		tok := expect_token(p, .Union);
		poly_params: ^ast.Field_List;
		align:       ^ast.Expr;

		if allow_token(p, .Open_Paren) {
			param_count: int;
			poly_params, param_count = parse_field_list(p, .Close_Paren, ast.Field_Flags_Record_Poly_Params);
			if param_count == 0 {
				error(p, poly_params.pos, "expected at least 1 polymorphic parameter");
				poly_params = nil;
			}
			expect_token_after(p, .Close_Paren, "parameter list");
			check_poly_params_for_type(p, poly_params, tok);
		}

		prev_level := p.expr_level;
		p.expr_level = -1;
		for allow_token(p, .Hash) {
			tag := expect_token_after(p, .Ident, "#");
			switch tag.text {
			case "align":
				if align != nil do error(p, tag.pos, "duplicate union tag '#%s'", tag.text);
				align = parse_expr(p, true);
			case:
				error(p, tag.pos, "invalid union tag '#%s", tag.text);
			}
		}
		p.expr_level = prev_level;

		where_token: tokenizer.Token;
		where_clauses: []^ast.Expr;
		if (p.curr_tok.kind == .Where) {
			where_token = expect_token(p, .Where);
			prev_level := p.expr_level;
			p.expr_level = -1;
			where_clauses = parse_rhs_expr_list(p);
			p.expr_level = prev_level;
		}

		variants: [dynamic]^ast.Expr;

		expect_token_after(p, .Open_Brace, "union");

		for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
			type := parse_type(p);
			if _, ok := type.derived.(ast.Bad_Expr); !ok {
				append(&variants, type);
			}
			if !allow_token(p, .Comma) {
				break;
			}
		}

		close := expect_token(p, .Close_Brace);

		ut := ast.new(ast.Union_Type, tok.pos, end_pos(close));
		ut.poly_params   = poly_params;
		ut.variants      = variants[:];
		ut.align         = align;
		ut.where_token   = where_token;
		ut.where_clauses = where_clauses;

		return ut;

	case .Enum:
		tok := expect_token(p, .Enum);
		base_type: ^ast.Expr;
		if p.curr_tok.kind != .Open_Brace {
			base_type = parse_type(p);
		}
		open := expect_token(p, .Open_Brace);
		fields := parse_elem_list(p);
		close := expect_token(p, .Close_Brace);

		et := ast.new(ast.Enum_Type, tok.pos, end_pos(close));
		et.base_type = base_type;
		et.open = open.pos;
		et.fields = fields;
		et.close = close.pos;
		return et;

	case .Bit_Field:
		tok := expect_token(p, .Bit_Field);

		fields: [dynamic]^ast.Field_Value;
		align: ^ast.Expr;

		prev_level := p.expr_level;
		p.expr_level = -1;

		for allow_token(p, .Hash) {
			tag := expect_token_after(p, .Ident, "#");
			switch tag.text {
			case "align":
				if align != nil {
					error(p, tag.pos, "duplicate bit_field tag '#%s", tag.text);
				}
				align = parse_expr(p, true);
			case:
				error(p, tag.pos, "invalid bit_field tag '#%s", tag.text);
			}
		}

		p.expr_level = prev_level;

		open := expect_token_after(p, .Open_Brace, "bit_field");

		for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
			name := parse_ident(p);
			colon := expect_token(p, .Colon);
			value := parse_expr(p, true);

			fv := ast.new(ast.Field_Value, name.pos, value.end);
			fv.field = name;
			fv.sep   = colon.pos;
			fv.value = value;
			append(&fields, fv);

			if !allow_token(p, .Comma) {
				break;
			}
		}

		close := expect_token(p, .Close_Brace);

		bft := ast.new(ast.Bit_Field_Type, tok.pos, end_pos(close));
		bft.tok_pos = tok.pos;
		bft.open    = open.pos;
		bft.fields  = fields[:];
		bft.close   = close.pos;
		bft.align   = align;

		return bft;

	case .Bit_Set:
		tok := expect_token(p, .Bit_Set);
		open := expect_token(p, .Open_Bracket);
		elem, underlying: ^ast.Expr;

		prev_allow_range := p.allow_range;
		p.allow_range = true;
		elem = parse_expr(p, false);
		p.allow_range = prev_allow_range;

		if allow_token(p, .Semicolon) {
			underlying = parse_type(p);
		}


		close := expect_token(p, .Close_Bracket);

		bst := ast.new(ast.Bit_Set_Type, tok.pos, end_pos(close));
		bst.tok_pos = tok.pos;
		bst.open = open.pos;
		bst.elem = elem;
		bst.underlying = underlying;
		bst.close = close.pos;
		return bst;

	}

	return nil;
}

is_literal_type :: proc(expr: ^ast.Expr) -> bool {
	val := ast.unparen_expr(expr);
	if val == nil {
		return false;
	}
	switch _ in val.derived {
	case ast.Bad_Expr,
		ast.Ident,
		ast.Selector_Expr,
		ast.Array_Type,
		ast.Struct_Type,
		ast.Union_Type,
		ast.Enum_Type,
		ast.Dynamic_Array_Type,
		ast.Map_Type,
		ast.Bit_Field_Type,
		ast.Bit_Set_Type,
		ast.Call_Expr:
		return true;
	}
	return false;
}

parse_value :: proc(p: ^Parser) -> ^ast.Expr {
	if p.curr_tok.kind == .Open_Brace {
		return parse_literal_value(p, nil);
	}
	prev_allow_range := p.allow_range;
	defer p.allow_range = prev_allow_range;
	p.allow_range = true;
	return parse_expr(p, false);
}

parse_elem_list :: proc(p: ^Parser) -> []^ast.Expr {
	elems: [dynamic]^ast.Expr;

	for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
		elem := parse_value(p);
		if p.curr_tok.kind == .Eq {
			eq := expect_token(p, .Eq);
			value := parse_value(p);

			fv := ast.new(ast.Field_Value, elem.pos, value.end);
			fv.field = elem;
			fv.sep   = eq.pos;
			fv.value = value;

			elem = fv;
		}

		append(&elems, elem);

		if !allow_token(p, .Comma) {
			break;
		}
	}

	return elems[:];
}

parse_literal_value :: proc(p: ^Parser, type: ^ast.Expr) -> ^ast.Comp_Lit {
	elems: []^ast.Expr;
	open := expect_token(p, .Open_Brace);
	p.expr_level += 1;
	if p.curr_tok.kind != .Close_Brace {
		elems = parse_elem_list(p);
	}
	p.expr_level -= 1;

	close := expect_token_after(p, .Close_Brace, "compound literal");

	pos := type != nil ? type.pos : open.pos;
	lit := ast.new(ast.Comp_Lit, pos, end_pos(close));
	lit.type  = type;
	lit.open  = open.pos;
	lit.elems = elems;
	lit.close = close.pos;
	return lit;
}

parse_call_expr :: proc(p: ^Parser, operand: ^ast.Expr) -> ^ast.Call_Expr {
	args: [dynamic]^ast.Expr;

	ellipsis: tokenizer.Token;

	p.expr_level += 1;
	open := expect_token(p, .Open_Paren);

	for p.curr_tok.kind != .Close_Paren &&
	    p.curr_tok.kind != .EOF &&
	    ellipsis.pos.line == 0 {

		if p.curr_tok.kind == .Comma {
			error(p, p.curr_tok.pos, "expected an expression not ,");
		} else if p.curr_tok.kind == .Eq {
			error(p, p.curr_tok.pos, "expected an expression not =");
		}

		prefix_ellipsis := false;
		if p.curr_tok.kind == .Ellipsis {
			prefix_ellipsis = true;
			ellipsis = expect_token(p, .Ellipsis);
		}

		arg := parse_expr(p, false);
		if p.curr_tok.kind == .Eq {
			eq := expect_token(p, .Eq);

			if prefix_ellipsis {
				error(p, ellipsis.pos, "'..' must be applied to value rather than a field name");
			}

			value := parse_value(p);
			fv := ast.new(ast.Field_Value, arg.pos, value.end);
			fv.field = arg;
			fv.sep   = eq.pos;
			fv.value = value;

			arg = fv;
		}

		append(&args, arg);

		if !allow_token(p, .Comma) {
			break;
		}
	}

	close := expect_token_after(p, .Close_Paren, "argument list");
	p.expr_level -= 1;

	ce := ast.new(ast.Call_Expr, operand.pos, end_pos(close));
	ce.expr     = operand;
	ce.open     = open.pos;
	ce.args     = args[:];
	ce.ellipsis = ellipsis;
	ce.close    = close.pos;

	return ce;
}


parse_atom_expr :: proc(p: ^Parser, value: ^ast.Expr, lhs: bool) -> (operand: ^ast.Expr) {
	operand = value;
	if operand == nil {
		if p.allow_type do return nil;
		error(p, p.curr_tok.pos, "expected an operand");
		be := ast.new(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok));
		advance_token(p);
		operand = be;
	}

	loop := true;
	is_lhs := lhs;
	for loop {
		switch p.curr_tok.kind {
		case:
			loop = false;

		case .Open_Paren:
			operand = parse_call_expr(p, operand);

		case .Open_Bracket:
			prev_allow_range := p.allow_range;
			defer p.allow_range = prev_allow_range;
			p.allow_range = false;

			indicies: [2]^ast.Expr;
			interval: tokenizer.Token;
			is_slice_op := false;

			p.expr_level += 1;
			open := expect_token(p, .Open_Bracket);

			switch p.curr_tok.kind {
			case .Colon, .Ellipsis, .Range_Half:
				// NOTE(bill): Do not err yet
				break;
			case:
				indicies[0] = parse_expr(p, false);
			}

			switch p.curr_tok.kind {
			case .Ellipsis, .Range_Half:
				error(p, p.curr_tok.pos, "expected a colon, not a range");
				fallthrough;
			case .Colon:
				interval = advance_token(p);
				is_slice_op = true;
				if (p.curr_tok.kind != .Close_Bracket && p.curr_tok.kind != .EOF) {
					indicies[1] = parse_expr(p, false);
				}
			}

			close := expect_token(p, .Close_Bracket);
			p.expr_level -= 1;

			if is_slice_op {
				se := ast.new(ast.Slice_Expr, operand.pos, end_pos(close));
				se.expr = operand;
				se.open = open.pos;
				se.low = indicies[0];
				se.interval = interval;
				se.high = indicies[1];
				se.close = close.pos;

				operand = se;
			} else {
				ie := ast.new(ast.Index_Expr, operand.pos, end_pos(close));
				ie.expr = operand;
				ie.open = open.pos;
				ie.index = indicies[0];
				ie.close = close.pos;

				operand = ie;
			}


		case .Period:
			tok := expect_token(p, .Period);
			switch p.curr_tok.kind {
			case .Ident:
				field := parse_ident(p);

				sel := ast.new(ast.Selector_Expr, operand.pos, field.end);
				sel.expr  = operand;
				sel.field = field;

				operand = sel;

			case .Open_Paren:
				open := expect_token(p, .Open_Paren);
				type := parse_type(p);
				close := expect_token(p, .Close_Paren);

				ta := ast.new(ast.Type_Assertion, operand.pos, end_pos(close));
				ta.expr  = operand;
				ta.open  = open.pos;
				ta.type  = type;
				ta.close = close.pos;

				operand = ta;

			case:
				error(p, p.curr_tok.pos, "expected a selector");
				advance_token(p);
				operand = ast.new(ast.Bad_Expr, operand.pos, end_pos(tok));
			}

		case .Pointer:
			op := expect_token(p, .Pointer);
			deref := ast.new(ast.Deref_Expr, operand.pos, end_pos(op));
			deref.expr = operand;
			deref.op   = op;

			operand = deref;

		case .Open_Brace:
			if !is_lhs && is_literal_type(operand) && p.expr_level >= 0 {
				operand = parse_literal_value(p, operand);
			} else {
				loop = false;
			}

		}

		is_lhs = false;
	}

	return operand;

}

parse_expr :: proc(p: ^Parser, lhs: bool) -> ^ast.Expr {
	return parse_binary_expr(p, lhs, 0+1);
}
parse_unary_expr :: proc(p: ^Parser, lhs: bool) -> ^ast.Expr {
	switch p.curr_tok.kind {
	case .Transmute, .Cast:
		tok := advance_token(p);
		open := expect_token(p, .Open_Paren);
		type := parse_type(p);
		close := expect_token(p, .Close_Paren);
		expr := parse_unary_expr(p, lhs);

		tc := ast.new(ast.Type_Cast, tok.pos, expr.end);
		tc.tok   = tok;
		tc.open  = open.pos;
		tc.type  = type;
		tc.close = close.pos;
		tc.expr  = expr;
		return tc;

	case .Auto_Cast:
		op := advance_token(p);
		expr := parse_unary_expr(p, lhs);

		ac := ast.new(ast.Auto_Cast, op.pos, expr.end);
		ac.op   = op;
		ac.expr = expr;
		return ac;

	case .Add, .Sub,
	     .Not, .Xor,
	     .And:
		op := advance_token(p);
		expr := parse_unary_expr(p, lhs);

		ue := ast.new(ast.Unary_Expr, op.pos, expr.end);
		ue.op   = op;
		ue.expr = expr;
		return ue;

	case .Period:
		op := advance_token(p);
		field := parse_ident(p);
		ise := ast.new(ast.Implicit_Selector_Expr, op.pos, field.end);
		ise.field = field;
		return ise;

	}
	return parse_atom_expr(p, parse_operand(p, lhs), lhs);
}
parse_binary_expr :: proc(p: ^Parser, lhs: bool, prec_in: int) -> ^ast.Expr {
	expr := parse_unary_expr(p, lhs);
	for prec := token_precedence(p, p.curr_tok.kind); prec >= prec_in; prec -= 1 {
		for {
			op := p.curr_tok;
			op_prec := token_precedence(p, op.kind);
			if op_prec != prec {
				break;
			}
			expect_operator(p);

			if op.kind == .Question {
				cond := expr;
				x := parse_expr(p, lhs);
				colon := expect_token(p, .Colon);
				y := parse_expr(p, lhs);
				te := ast.new(ast.Ternary_Expr, expr.pos, end_pos(p.prev_tok));
				te.cond = cond;
				te.op1  = op;
				te.x    = x;
				te.op2  = colon;
				te.y    = y;

				expr = te;
			} else {
				right := parse_binary_expr(p, false, prec+1);
				if right == nil {
					error(p, op.pos, "expected expression on the right-hand side of the binary operator");
				}
				be := ast.new(ast.Binary_Expr, expr.pos, end_pos(p.prev_tok));
				be.left  = expr;
				be.op    = op;
				be.right = right;

				expr = be;
			}
		}
	}

	return expr;
}


parse_expr_list :: proc(p: ^Parser, lhs: bool) -> ([]^ast.Expr) {
	list: [dynamic]^ast.Expr;
	for {
		expr := parse_expr(p, lhs);
		append(&list, expr);
		if p.curr_tok.kind != .Comma || p.curr_tok.kind == .EOF {
			break;
		}
		advance_token(p);
	}

	return list[:];
}
parse_lhs_expr_list :: proc(p: ^Parser) -> []^ast.Expr {
	return parse_expr_list(p, true);
}
parse_rhs_expr_list :: proc(p: ^Parser) -> []^ast.Expr {
	return parse_expr_list(p, false);
}

parse_simple_stmt :: proc(p: ^Parser, flags: Stmt_Allow_Flags) -> ^ast.Stmt {
	start_tok := p.curr_tok;
	docs := p.lead_comment;

	lhs := parse_lhs_expr_list(p);
	op := p.curr_tok;
	switch {
	case tokenizer.is_assignment_operator(op.kind):
		// if p.curr_proc == nil {
		// 	error(p, p.curr_tok.pos, "simple statements are not allowed at the file scope");
		// 	return ast.new(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok));
		// }
		advance_token(p);
		rhs := parse_rhs_expr_list(p);
		if len(rhs) == 0 {
			error(p, p.curr_tok.pos, "no right-hand side in assignment statement");
			return ast.new(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok));
		}
		stmt := ast.new(ast.Assign_Stmt, lhs[0].pos, rhs[len(rhs)-1].end);
		stmt.lhs = lhs;
		stmt.op = op;
		stmt.rhs = rhs;
		return stmt;

	case op.kind == .In:
		if .In in flags {
			allow_token(p, .In);
			prev_allow_range := p.allow_range;
			p.allow_range = true;
			expr := parse_expr(p, false);
			p.allow_range = prev_allow_range;

			rhs := make([]^ast.Expr, 1);
			rhs[0] = expr;

			stmt := ast.new(ast.Assign_Stmt, lhs[0].pos, rhs[len(rhs)-1].end);
			stmt.lhs = lhs;
			stmt.op = op;
			stmt.rhs = rhs;
			return stmt;
		}
	case op.kind == .Colon:
		expect_token_after(p, .Colon, "identifier list");
		if .Label in flags && len(lhs) == 1 {
			switch p.curr_tok.kind {
			case .Open_Brace, .If, .For, .Switch:
				label := lhs[0];
				stmt := parse_stmt(p);

				if stmt != nil do switch n in &stmt.derived {
				case ast.Block_Stmt:       n.label = label;
				case ast.If_Stmt:          n.label = label;
				case ast.For_Stmt:         n.label = label;
				case ast.Switch_Stmt:      n.label = label;
				case ast.Type_Switch_Stmt: n.label = label;
				}

				return stmt;
			}
		}
		return parse_value_decl(p, lhs, docs);
	}

	if len(lhs) > 1 {
		error(p, op.pos, "expected 1 expression, got %d", len(lhs));
		return ast.new(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok));
	}

	es := ast.new(ast.Expr_Stmt, lhs[0].pos, lhs[0].end);
	es.expr = lhs[0];
	return es;
}

parse_value_decl :: proc(p: ^Parser, names: []^ast.Expr, docs: ^ast.Comment_Group) -> ^ast.Decl {
	is_mutable := true;

	values: []^ast.Expr;
	type := parse_type_or_ident(p);

	switch p.curr_tok.kind {
	case .Eq, .Colon:
		sep := advance_token(p);
		is_mutable = sep.kind != .Colon;

		values = parse_rhs_expr_list(p);
		if len(values) > len(names) {
			error(p, p.curr_tok.pos, "too many values on the right-hand side of the declaration");
		} else if len(values) < len(names) && !is_mutable {
			error(p, p.curr_tok.pos, "all constant declarations must be defined");
		} else if len(values) == 0 {
			error(p, p.curr_tok.pos, "expected an expression for this declaration");
		}
	}

	if is_mutable {
		if type == nil && len(values) == 0 {
			error(p, p.curr_tok.pos, "missing variable type or initialization");
			return ast.new(ast.Bad_Decl, names[0].pos, end_pos(p.curr_tok));
		}
	} else {
		if type == nil && len(values) == 0 && len(names) > 0 {
			error(p, p.curr_tok.pos, "missing constant value");
			return ast.new(ast.Bad_Decl, names[0].pos, end_pos(p.curr_tok));
		}
	}

	if p.expr_level >= 0 {
		end: ^ast.Expr;
		if !is_mutable && len(values) > 0 {
			end = values[len(values)-1];
		}
		if p.curr_tok.kind == .Close_Brace &&
		   p.curr_tok.pos.line == p.prev_tok.pos.line {

		} else {
			expect_semicolon(p, end);
		}
	}

	if p.curr_proc == nil {
		if len(values) > 0 && len(names) != len(values) {
			error(p, values[0].pos, "expected %d expressions on the right-hand side, got %d", len(names), len(values));
		}
	}

	decl := ast.new(ast.Value_Decl, names[0].pos, end_pos(p.prev_tok));
	decl.docs = docs;
	decl.names = names;
	decl.type = type;
	decl.values = values;
	decl.is_mutable = is_mutable;
	return decl;
}


parse_import_decl :: proc(p: ^Parser, kind := Import_Decl_Kind.Standard) -> ^ast.Import_Decl {
	docs := p.lead_comment;
	tok := expect_token(p, .Import);

	import_name: tokenizer.Token;
	is_using := kind != Import_Decl_Kind.Standard;

	switch p.curr_tok.kind {
	case .Ident:
		import_name = advance_token(p);
	case:
		import_name.pos = p.curr_tok.pos;
	}

	if !is_using && is_blank_ident(import_name) {
		error(p, import_name.pos, "illegal import name: '_'");
	}

	path := expect_token_after(p, .String, "import");

	decl := ast.new(ast.Import_Decl, tok.pos, end_pos(path));
	decl.docs       = docs;
	decl.is_using   = is_using;
	decl.import_tok = tok;
	decl.name       = import_name;
	decl.relpath    = path;
	decl.fullpath   = path.text;

	if p.curr_proc != nil {
		error(p, decl.pos, "import declarations cannot be used within a procedure, it must be done at the file scope");
	} else {
		append(&p.file.imports, decl);
	}
	expect_semicolon(p, decl);
	decl.comment = p.line_comment;

	return decl;
}
