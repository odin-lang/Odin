package odin_parser

import "core:odin/ast"
import "core:odin/tokenizer"

import "core:fmt"

Warning_Handler :: #type proc(pos: tokenizer.Pos, fmt: string, args: ..any)
Error_Handler   :: #type proc(pos: tokenizer.Pos, fmt: string, args: ..any)

Flag :: enum u32 {
	Optional_Semicolons,
}

Flags :: distinct bit_set[Flag; u32]


Parser :: struct {
	file: ^ast.File,
	tok: tokenizer.Tokenizer,

	// If .Optional_Semicolons is true, semicolons are completely as statement terminators
	// different to .Insert_Semicolon in tok.flags
	flags: Flags,

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

	fix_count: int,
	fix_prev_pos: tokenizer.Pos,

	peeking: bool,
}

MAX_FIX_COUNT :: 10

Stmt_Allow_Flag :: enum {
	In,
	Label,
}
Stmt_Allow_Flags :: distinct bit_set[Stmt_Allow_Flag]


Import_Decl_Kind :: enum {
	Standard,
	Using,
}



default_warning_handler :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d): Warning: ", pos.file, pos.line, pos.column)
	fmt.eprintf(msg, ..args)
	fmt.eprintf("\n")
}
default_error_handler :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d): ", pos.file, pos.line, pos.column)
	fmt.eprintf(msg, ..args)
	fmt.eprintf("\n")
}

warn :: proc(p: ^Parser, pos: tokenizer.Pos, msg: string, args: ..any) {
	if p.warn != nil {
		p.warn(pos, msg, ..args)
	}
	p.file.syntax_warning_count += 1
}

error :: proc(p: ^Parser, pos: tokenizer.Pos, msg: string, args: ..any) {
	if p.err != nil {
		p.err(pos, msg, ..args)
	}
	p.file.syntax_error_count += 1
	p.error_count += 1
}


end_pos :: proc(tok: tokenizer.Token) -> tokenizer.Pos {
	pos := tok.pos
	pos.offset += len(tok.text)

	if tok.kind == .Comment {
		if tok.text[:2] != "/*" {
			pos.column += len(tok.text)
		} else {
			for i := 0; i < len(tok.text); i += 1 {
				c := tok.text[i]
				if c == '\n' {
					pos.line += 1
					pos.column = 1
				} else {
					pos.column += 1
				}
			}
		}
	} else {
		pos.column += len(tok.text)
	}
	return pos
}

default_parser :: proc(flags := Flags{.Optional_Semicolons}) -> Parser {
	return Parser {
		flags = flags,
		err  = default_error_handler,
		warn = default_warning_handler,
	}
}

is_package_name_reserved :: proc(name: string) -> bool {
	switch name {
	case "builtin", "intrinsics":
		return true
	}
	return false
}

parse_file :: proc(p: ^Parser, file: ^ast.File) -> bool {
	zero_parser: {
		p.prev_tok         = {}
		p.curr_tok         = {}
		p.expr_level       = 0
		p.allow_range      = false
		p.allow_in_expr    = false
		p.in_foreign_block = false
		p.allow_type       = false
		p.lead_comment     = nil
		p.line_comment     = nil
	}

	p.tok.flags += {.Insert_Semicolon}

	p.file = file
	tokenizer.init(&p.tok, file.src, file.fullpath, p.err)
	if p.tok.ch <= 0 {
		return true
	}


	advance_token(p)
	consume_comment_groups(p, p.prev_tok)

	docs := p.lead_comment

	p.file.pkg_token = expect_token(p, .Package)
	if p.file.pkg_token.kind != .Package {
		return false
	}

	pkg_name := expect_token_after(p, .Ident, "package")
	if pkg_name.kind == .Ident {
		switch name := pkg_name.text; {
		case is_blank_ident(name):
			error(p, pkg_name.pos, "invalid package name '_'")
		case is_package_name_reserved(name), file.pkg != nil && file.pkg.kind != .Runtime && name == "runtime":
			error(p, pkg_name.pos, "use of reserved package name '%s'", name)
		}
	}
	p.file.pkg_name = pkg_name.text

	pd := ast.new(ast.Package_Decl, pkg_name.pos, end_pos(p.prev_tok))
	pd.docs    = docs
	pd.token   = p.file.pkg_token
	pd.name    = pkg_name.text
	pd.comment = p.line_comment
	p.file.pkg_decl = pd
	p.file.docs = docs

	expect_semicolon(p, pd)

	if p.file.syntax_error_count > 0 {
		return false
	}

	p.file.decls = make([dynamic]^ast.Stmt)

	for p.curr_tok.kind != .EOF {
		stmt := parse_stmt(p)
		if stmt != nil {
			if _, ok := stmt.derived.(^ast.Empty_Stmt); !ok {
				append(&p.file.decls, stmt)
				if es, es_ok := stmt.derived.(^ast.Expr_Stmt); es_ok && es.expr != nil {
					if _, pl_ok := es.expr.derived.(^ast.Proc_Lit); pl_ok {
						error(p, stmt.pos, "procedure literal evaluated but not used")
					}
				}
			}
		}
	}

	return true
}

peek_token_kind :: proc(p: ^Parser, kind: tokenizer.Token_Kind, lookahead := 0) -> (ok: bool) {
	prev_parser := p^
	p.peeking = true

	defer {
		p^ = prev_parser
		p.peeking = false
	}

	p.tok.err = nil
	for i := 0; i <= lookahead; i += 1 {
		advance_token(p)
	}
	ok = p.curr_tok.kind == kind

	return
}

peek_token :: proc(p: ^Parser, lookahead := 0) -> (tok: tokenizer.Token) {
	prev_parser := p^
	p.peeking = true

	defer {
		p^ = prev_parser
		p.peeking = false
	}

	p.tok.err = nil
	for i := 0; i <= lookahead; i += 1 {
		advance_token(p)
	}
	tok = p.curr_tok
	return
}
skip_possible_newline :: proc(p: ^Parser) -> bool {
	if tokenizer.is_newline(p.curr_tok) {
		advance_token(p)
		return true
	}
	return false
}

skip_possible_newline_for_literal :: proc(p: ^Parser) -> bool {
	if .Optional_Semicolons not_in p.flags {
		return false
	}

	curr_pos := p.curr_tok.pos
	if tokenizer.is_newline(p.curr_tok) {
		next := peek_token(p)
		if curr_pos.line+1 >= next.pos.line {
			#partial switch next.kind {
			case .Open_Brace, .Else, .Where:
				advance_token(p)
				return true
			}
		}
	}

	return false
}


next_token0 :: proc(p: ^Parser) -> bool {
	p.curr_tok = tokenizer.scan(&p.tok)
	if p.curr_tok.kind == .EOF {
		// error(p, p.curr_tok.pos, "token is EOF");
		return false
	}
	return true
}

consume_comment :: proc(p: ^Parser) -> (tok: tokenizer.Token, end_line: int) {
	tok = p.curr_tok
	assert(tok.kind == .Comment)
	end_line = tok.pos.line

	if tok.text[1] == '*' {
		for c in tok.text {
			if c == '\n' {
				end_line += 1
			}
		}
	}

	_ = next_token0(p)
	if p.curr_tok.pos.line > tok.pos.line {
		end_line += 1
	}

	return
}

consume_comment_group :: proc(p: ^Parser, n: int) -> (comments: ^ast.Comment_Group, end_line: int) {
	list: [dynamic]tokenizer.Token
	end_line = p.curr_tok.pos.line
	for p.curr_tok.kind == .Comment &&
	    p.curr_tok.pos.line <= end_line+n {
	    comment: tokenizer.Token
		comment, end_line = consume_comment(p)
		append(&list, comment)
	}

	if len(list) > 0 && !p.peeking {
		comments = ast.new(ast.Comment_Group, list[0].pos, end_pos(list[len(list)-1]))
		comments.list = list[:]
		append(&p.file.comments, comments)
	}

	return
}

consume_comment_groups :: proc(p: ^Parser, prev: tokenizer.Token) {
	if p.curr_tok.kind == .Comment {
		comment: ^ast.Comment_Group
		end_line := 0

		if p.curr_tok.pos.line == prev.pos.line {
			comment, end_line = consume_comment_group(p, 0)
			if p.curr_tok.pos.line != end_line || p.curr_tok.kind == .EOF {
				p.line_comment = comment
			}
		}

		end_line = -1
		for p.curr_tok.kind == .Comment {
			comment, end_line = consume_comment_group(p, 1)
		}
		if end_line+1 >= p.curr_tok.pos.line || end_line < 0 {
			p.lead_comment = comment
		}

		assert(p.curr_tok.kind != .Comment)
	}
}

advance_token :: proc(p: ^Parser) -> tokenizer.Token {
	p.lead_comment = nil
	p.line_comment = nil
	p.prev_tok = p.curr_tok
	prev := p.prev_tok

	if next_token0(p) {
		consume_comment_groups(p, prev)
	}
	return prev
}

expect_token :: proc(p: ^Parser, kind: tokenizer.Token_Kind) -> tokenizer.Token {
	prev := p.curr_tok
	if prev.kind != kind {
		e := tokenizer.to_string(kind)
		g := tokenizer.token_to_string(prev)
		error(p, prev.pos, "expected '%s', got '%s'", e, g)
	}
	advance_token(p)
	return prev
}

expect_token_after :: proc(p: ^Parser, kind: tokenizer.Token_Kind, msg: string) -> tokenizer.Token {
	prev := p.curr_tok
	if prev.kind != kind {
		e := tokenizer.to_string(kind)
		g := tokenizer.token_to_string(prev)
		error(p, prev.pos, "expected '%s' after %s, got '%s'", e, msg, g)
	}
	advance_token(p)
	return prev
}

expect_operator :: proc(p: ^Parser) -> tokenizer.Token {
	prev := p.curr_tok
	#partial switch prev.kind {
	case .If, .When, .Or_Else:
		// okay
	case:
		if !tokenizer.is_operator(prev.kind) {
			g := tokenizer.token_to_string(prev)
			error(p, prev.pos, "expected an operator, got '%s'", g)
		}
	}
	advance_token(p)
	return prev
}

allow_token :: proc(p: ^Parser, kind: tokenizer.Token_Kind) -> bool {
	if p.curr_tok.kind == kind {
		advance_token(p)
		return true
	}
	return false
}

end_of_line_pos :: proc(p: ^Parser, tok: tokenizer.Token) -> tokenizer.Pos {
	offset := clamp(tok.pos.offset, 0, len(p.tok.src)-1)
	s := p.tok.src[offset:]
	pos := tok.pos
	pos.column -= 1
	for len(s) != 0 && s[0] != 0 && s[0] != '\n' {
		s = s[1:]
		pos.column += 1
	}
	return pos
}

expect_closing_brace_of_field_list :: proc(p: ^Parser) -> tokenizer.Token {
	return expect_closing_token_of_field_list(p, .Close_Brace, "field list")
}

expect_closing_token_of_field_list :: proc(p: ^Parser, closing_kind: tokenizer.Token_Kind, msg: string) -> tokenizer.Token {
	token := p.curr_tok
	if allow_token(p, closing_kind) {
		return token
	}
	if allow_token(p, .Semicolon) && !tokenizer.is_newline(token) {
		str := tokenizer.token_to_string(token)
		error(p, end_of_line_pos(p, p.prev_tok), "expected a comma, got %s", str)
	}
	expect_closing := expect_token_after(p, closing_kind, msg)

	if expect_closing.kind != closing_kind {
		for p.curr_tok.kind != closing_kind && p.curr_tok.kind != .EOF && !is_non_inserted_semicolon(p.curr_tok) {
			advance_token(p)
		}
		return p.curr_tok
	} 

	return expect_closing
}

expect_closing_parentheses_of_field_list :: proc(p: ^Parser) -> tokenizer.Token {
	token := p.curr_tok
	if allow_token(p, .Close_Paren) {
		return token
	}

	if allow_token(p, .Semicolon) && !tokenizer.is_newline(token) {
		str := tokenizer.token_to_string(token)
		error(p, end_of_line_pos(p, p.prev_tok), "expected a comma, got %s", str)
	}

	for p.curr_tok.kind != .Close_Paren && p.curr_tok.kind != .EOF && !is_non_inserted_semicolon(p.curr_tok) {
		advance_token(p)
	}

	return expect_token(p, .Close_Paren)
}

is_non_inserted_semicolon :: proc(tok: tokenizer.Token) -> bool {
	return tok.kind == .Semicolon && tok.text != "\n"
}

is_blank_ident :: proc{
	is_blank_ident_string,
	is_blank_ident_token,
	is_blank_ident_node,
}
is_blank_ident_string :: proc(str: string) -> bool {
	return str == "_"
}
is_blank_ident_token :: proc(tok: tokenizer.Token) -> bool {
	if tok.kind == .Ident {
		return is_blank_ident_string(tok.text)
	}
	return false
}
is_blank_ident_node :: proc(node: ^ast.Node) -> bool {
	if ident, ok := node.derived.(^ast.Ident); ok {
		return is_blank_ident(ident.name)
	}
	return true
}

fix_advance_to_next_stmt :: proc(p: ^Parser) {
	for {
		#partial switch t := p.curr_tok; t.kind {
		case .EOF, .Semicolon:
			return

		case .Package, .Foreign, .Import,
		     .If, .For, .When, .Return, .Switch,
		     .Defer, .Using,
		     .Break, .Continue, .Fallthrough,
		     .Hash:


			if t.pos == p.fix_prev_pos && p.fix_count < MAX_FIX_COUNT {
				p.fix_count += 1
				return
			}
			if t.pos.offset < p.fix_prev_pos.offset {
				p.fix_prev_pos = t.pos
				p.fix_count = 0
				return
			}
		}
		advance_token(p)
	}
}


is_semicolon_optional_for_node :: proc(p: ^Parser, node: ^ast.Node) -> bool {
	if node == nil {
		return false
	}

	if .Optional_Semicolons in p.flags {
		return true
	}

	#partial switch n in node.derived {
	case ^ast.Empty_Stmt, ^ast.Block_Stmt:
		return true

	case ^ast.If_Stmt, ^ast.When_Stmt,
	     ^ast.For_Stmt, ^ast.Range_Stmt, ^ast.Inline_Range_Stmt,
	     ^ast.Switch_Stmt, ^ast.Type_Switch_Stmt:
		return true

	case ^ast.Helper_Type:
		return is_semicolon_optional_for_node(p, n.type)
	case ^ast.Distinct_Type:
		return is_semicolon_optional_for_node(p, n.type)
	case ^ast.Pointer_Type:
		return is_semicolon_optional_for_node(p, n.elem)
	case ^ast.Struct_Type, ^ast.Union_Type, ^ast.Enum_Type, ^ast.Bit_Set_Type, ^ast.Bit_Field_Type:
		// Require semicolon within a procedure body
		return p.curr_proc == nil
	case ^ast.Proc_Lit:
		return true

	case ^ast.Package_Decl, ^ast.Import_Decl, ^ast.Foreign_Import_Decl:
		return true

	case ^ast.Foreign_Block_Decl:
		return is_semicolon_optional_for_node(p, n.body)

	case ^ast.Value_Decl:
		if n.is_mutable {
			return false
		}
		if len(n.values) > 0 {
			return is_semicolon_optional_for_node(p, n.values[len(n.values)-1])
		}
	}

	return false
}

expect_semicolon_newline_error :: proc(p: ^Parser, token: tokenizer.Token, s: ^ast.Node) {
	if .Optional_Semicolons not_in p.flags && .Insert_Semicolon in p.tok.flags && token.text == "\n" {
		#partial switch token.kind {
		case .Close_Brace:
		case .Close_Paren:
		case .Else:
			return
		}
		if is_semicolon_optional_for_node(p, s) {
			return
		}

		tok := token
		tok.pos.column -= 1
		error(p, tok.pos, "expected ';', got newline")
	}
}


expect_semicolon :: proc(p: ^Parser, node: ^ast.Node) -> bool {
	if allow_token(p, .Semicolon) {
		expect_semicolon_newline_error(p, p.prev_tok, node)
		return true
	}

	prev := p.prev_tok
	if prev.kind == .Semicolon {
		expect_semicolon_newline_error(p, p.prev_tok, node)
		return true
	}

	if p.curr_tok.kind == .EOF {
		return true
	}

	if node != nil {
		if .Insert_Semicolon in p.tok.flags  {
			#partial switch p.curr_tok.kind {
			case .Close_Brace, .Close_Paren, .Else, .EOF:
				return true
			}

			if is_semicolon_optional_for_node(p, node) {
				return true
			}
		} else if prev.pos.line != p.curr_tok.pos.line {
			if is_semicolon_optional_for_node(p, node) {
				return true
			}
		} else {
			#partial switch p.curr_tok.kind {
			case .Close_Brace, .Close_Paren, .Else:
				return true
			case .EOF:
				if is_semicolon_optional_for_node(p, node) {
					return true
				}
			}
		}
	} else {
		if p.curr_tok.kind == .EOF {
			return true
		}
	}

	error(p, prev.pos, "expected ';', got %s", tokenizer.token_to_string(p.curr_tok))
	fix_advance_to_next_stmt(p)
	return false
}

new_blank_ident :: proc(p: ^Parser, pos: tokenizer.Pos) -> ^ast.Ident {
	tok: tokenizer.Token
	tok.pos = pos
	i := ast.new(ast.Ident, pos, end_pos(tok))
	i.name = "_"
	return i
}

parse_ident :: proc(p: ^Parser) -> ^ast.Ident {
	tok := p.curr_tok
	pos := tok.pos
	name := "_"
	if tok.kind == .Ident {
		name = tok.text
		advance_token(p)
	} else {
		expect_token(p, .Ident)
	}
	i := ast.new(ast.Ident, pos, end_pos(tok))
	i.name = name
	return i
}

parse_stmt_list :: proc(p: ^Parser) -> []^ast.Stmt {
	list: [dynamic]^ast.Stmt
	for p.curr_tok.kind != .Case &&
	    p.curr_tok.kind != .Close_Brace &&
	    p.curr_tok.kind != .EOF  {
		stmt := parse_stmt(p)
		if stmt != nil {
			if _, ok := stmt.derived.(^ast.Empty_Stmt); !ok {
				append(&list, stmt)
				if es, es_ok := stmt.derived.(^ast.Expr_Stmt); es_ok && es.expr != nil {
					if _, pl_ok := es.expr.derived.(^ast.Proc_Lit); pl_ok {
						error(p, stmt.pos, "procedure literal evaluated but not used")
					}
				}
			}
		}
	}
	return list[:]
}

parse_block_stmt :: proc(p: ^Parser, is_when: bool) -> ^ast.Stmt {
	skip_possible_newline_for_literal(p)
	if !is_when && p.curr_proc == nil {
		error(p, p.curr_tok.pos, "you cannot use a block statement in the file scope")
	}
	return parse_body(p)
}

parse_when_stmt :: proc(p: ^Parser) -> ^ast.When_Stmt {
	tok := expect_token(p, .When)

	cond: ^ast.Expr
	body: ^ast.Stmt
	else_stmt: ^ast.Stmt

	prev_level := p.expr_level
	p.expr_level = -1
	cond = parse_expr(p, false)
	p.expr_level = prev_level

	if cond == nil {
		error(p, p.curr_tok.pos, "expected a condition for when statement")
	}
	if allow_token(p, .Do) {
		body = convert_stmt_to_body(p, parse_stmt(p))
		if cond.pos.line != body.pos.line {
			error(p, body.pos, "the body of a 'do' must be on the same line as when statement")
		}
	} else {
		body = parse_block_stmt(p, true)
	}

	skip_possible_newline_for_literal(p)
	if p.curr_tok.kind == .Else {
		else_tok := expect_token(p, .Else)
		#partial switch p.curr_tok.kind {
		case .When:
			else_stmt = parse_when_stmt(p)
		case .Open_Brace:
			else_stmt = parse_block_stmt(p, true)
		case .Do:
			expect_token(p, .Do)
			else_stmt = convert_stmt_to_body(p, parse_stmt(p))
			if else_tok.pos.line != else_stmt.pos.line {
				error(p, else_stmt.pos, "the body of a 'do' must be on the same line as 'else'")
			}
		case:
			error(p, p.curr_tok.pos, "expected when statement block statement")
			else_stmt = ast.new(ast.Bad_Stmt, p.curr_tok.pos, end_pos(p.curr_tok))
		}
	}

	end := body.end
	if else_stmt != nil {
		end = else_stmt.end
	}
	when_stmt := ast.new(ast.When_Stmt, tok.pos, end)
	when_stmt.when_pos  = tok.pos
	when_stmt.cond      = cond
	when_stmt.body      = body
	when_stmt.else_stmt = else_stmt
	return when_stmt
}

convert_stmt_to_expr :: proc(p: ^Parser, stmt: ^ast.Stmt, kind: string) -> ^ast.Expr {
	if stmt == nil {
		return nil
	}
	if es, ok := stmt.derived.(^ast.Expr_Stmt); ok {
		return es.expr
	}
	error(p, stmt.pos, "expected %s, found a simple statement", kind)
	return ast.new(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok))
}

parse_if_stmt :: proc(p: ^Parser) -> ^ast.If_Stmt {
	tok := expect_token(p, .If)

	init: ^ast.Stmt
	cond: ^ast.Expr
	body: ^ast.Stmt
	else_stmt: ^ast.Stmt

	prev_level := p.expr_level
	p.expr_level = -1
	prev_allow_in_expr := p.allow_in_expr
	p.allow_in_expr = true
	if allow_token(p, .Semicolon) {
		cond = parse_expr(p, false)
	} else {
		init = parse_simple_stmt(p, nil)
		if parse_control_statement_semicolon_separator(p) {
			cond = parse_expr(p, false)
		} else {
			cond = convert_stmt_to_expr(p, init, "boolean expression")
			init = nil
		}
	}

	p.expr_level = prev_level
	p.allow_in_expr = prev_allow_in_expr

	if cond == nil {
		error(p, p.curr_tok.pos, "expected a condition for if statement")

	}
	if allow_token(p, .Do) {
		body = convert_stmt_to_body(p, parse_stmt(p))
		if cond.pos.line != body.pos.line {
			error(p, body.pos, "the body of a 'do' must be on the same line as the if condition")
		}
	} else {
		body = parse_block_stmt(p, false)
	}

	else_tok := p.curr_tok.pos

	skip_possible_newline_for_literal(p)
	if p.curr_tok.kind == .Else {
		else_tok := expect_token(p, .Else)
		#partial switch p.curr_tok.kind {
		case .If:
			else_stmt = parse_if_stmt(p)
		case .Open_Brace:
			else_stmt = parse_block_stmt(p, false)
		case .Do:
			expect_token(p, .Do)
			else_stmt = convert_stmt_to_body(p, parse_stmt(p))
			if else_tok.pos.line != else_stmt.pos.line {
				error(p, body.pos, "the body of a 'do' must be on the same line as 'else'")
			}
		case:
			error(p, p.curr_tok.pos, "expected if statement block statement")
			else_stmt = ast.new(ast.Bad_Stmt, p.curr_tok.pos, end_pos(p.curr_tok))
		}
	}
	
	end: tokenizer.Pos
	if body != nil {
		end = body.end
	}
	if else_stmt != nil {
		end = else_stmt.end
	}
	if_stmt := ast.new(ast.If_Stmt, tok.pos, end)
	if_stmt.if_pos  = tok.pos
	if_stmt.init      = init
	if_stmt.cond      = cond
	if_stmt.body      = body
	if_stmt.else_stmt = else_stmt
	if_stmt.else_pos = else_tok
	return if_stmt
}

parse_control_statement_semicolon_separator :: proc(p: ^Parser) -> bool {
	tok := peek_token(p)
	if tok.kind != .Open_Brace {
		return allow_token(p, .Semicolon)
	}
	if p.curr_tok.text == ";" {
		return allow_token(p, .Semicolon)
	}
	return false

}

parse_for_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	if p.curr_proc == nil {
		error(p, p.curr_tok.pos, "you cannot use a for statement in the file scope")
	}

	tok := expect_token(p, .For)

	init: ^ast.Stmt
	cond: ^ast.Stmt
	post: ^ast.Stmt
	body: ^ast.Stmt
	is_range := false

	if p.curr_tok.kind != .Open_Brace && p.curr_tok.kind != .Do {
		prev_level := p.expr_level
		defer p.expr_level = prev_level
		p.expr_level = -1

		if p.curr_tok.kind == .In {
			in_tok := expect_token(p, .In)
			rhs: ^ast.Expr

			prev_allow_range := p.allow_range
			p.allow_range = true
			rhs = parse_expr(p, false)
			p.allow_range = prev_allow_range

			if allow_token(p, .Do) {
				body = convert_stmt_to_body(p, parse_stmt(p))
				if tok.pos.line != body.pos.line {
					error(p, body.pos, "the body of a 'do' must be on the same line as 'else'")
				}

			} else {
				body = parse_body(p)
			}

			range_stmt := ast.new(ast.Range_Stmt, tok.pos, body)
			range_stmt.for_pos = tok.pos
			range_stmt.in_pos = in_tok.pos
			range_stmt.expr = rhs
			range_stmt.body = body
			return range_stmt
		}

		if p.curr_tok.kind != .Semicolon {
			cond = parse_simple_stmt(p, {Stmt_Allow_Flag.In})
			if as, ok := cond.derived.(^ast.Assign_Stmt); ok && as.op.kind == .In {
				is_range = true
			}
		}

		if !is_range && parse_control_statement_semicolon_separator(p) {
			init = cond
			cond = nil


			if p.curr_tok.kind == .Open_Brace || p.curr_tok.kind == .Do {
				error(p, p.curr_tok.pos, "Expected ';', followed by a condition expression and post statement, got %s", tokenizer.tokens[p.curr_tok.kind])
			} else {
				if p.curr_tok.kind != .Semicolon {
					cond = parse_simple_stmt(p, nil)
				}

				if p.curr_tok.text != ";" {
					error(p, p.curr_tok.pos, "Expected ';', got %s", tokenizer.token_to_string(p.curr_tok))
				} else {
					expect_semicolon(p, nil)
				}

				if p.curr_tok.kind != .Open_Brace && p.curr_tok.kind != .Do {
					post = parse_simple_stmt(p, nil)
				}
			}
		}
	}

	if allow_token(p, .Do) {
		body = convert_stmt_to_body(p, parse_stmt(p))
		if tok.pos.line != body.pos.line {
			error(p, body.pos, "the body of a 'do' must be on the same line as the 'for' token")
		}
	} else {
		allow_token(p, .Semicolon)
		body = parse_body(p)
	}


	if is_range {
		assign_stmt := cond.derived.(^ast.Assign_Stmt)
		vals := assign_stmt.lhs[:]

		rhs: ^ast.Expr
		if len(assign_stmt.rhs) > 0 {
			rhs = assign_stmt.rhs[0]
		}

		range_stmt := ast.new(ast.Range_Stmt, tok.pos, body)
		range_stmt.for_pos = tok.pos
		range_stmt.vals = vals
		range_stmt.in_pos = assign_stmt.op.pos
		range_stmt.expr = rhs
		range_stmt.body = body
		return range_stmt
	}

	cond_expr := convert_stmt_to_expr(p, cond, "boolean expression")
	for_stmt := ast.new(ast.For_Stmt, tok.pos, body)
	for_stmt.for_pos = tok.pos
	for_stmt.init = init
	for_stmt.cond = cond_expr
	for_stmt.post = post
	for_stmt.body = body
	return for_stmt
}

parse_case_clause :: proc(p: ^Parser, is_type_switch: bool) -> ^ast.Case_Clause {
	tok := expect_token(p, .Case)

	list: []^ast.Expr

	if p.curr_tok.kind != .Colon {
		prev_allow_range, prev_allow_in_expr := p.allow_range, p.allow_in_expr
		defer p.allow_range, p.allow_in_expr = prev_allow_range, prev_allow_in_expr
		p.allow_range, p.allow_in_expr = !is_type_switch, !is_type_switch

		list = parse_rhs_expr_list(p)
	}

	terminator := expect_token(p, .Colon)

	stmts := parse_stmt_list(p)

	cc := ast.new(ast.Case_Clause, tok.pos, end_pos(p.prev_tok))
	cc.list = list
	cc.terminator = terminator
	cc.body = stmts
	cc.case_pos = tok.pos
	return cc
}

parse_switch_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	tok := expect_token(p, .Switch)

	init: ^ast.Stmt
	tag:  ^ast.Stmt
	is_type_switch := false
	clauses: [dynamic]^ast.Stmt

	if p.curr_tok.kind != .Open_Brace {
		prev_level := p.expr_level
		defer p.expr_level = prev_level
		p.expr_level = -1

		if p.curr_tok.kind == .In {
			in_tok := expect_token(p, .In)
			is_type_switch = true

			lhs := make([]^ast.Expr, 1)
			rhs := make([]^ast.Expr, 1)
			lhs[0] = new_blank_ident(p, tok.pos)
			rhs[0] = parse_expr(p, true)

			as := ast.new(ast.Assign_Stmt, tok.pos, rhs[0])
			as.lhs = lhs
			as.op  = in_tok
			as.rhs = rhs
			tag = as
		} else {
			tag = parse_simple_stmt(p, {Stmt_Allow_Flag.In})
			if as, ok := tag.derived.(^ast.Assign_Stmt); ok && as.op.kind == .In {
				is_type_switch = true
			} else if parse_control_statement_semicolon_separator(p) {
				init = tag
				tag = nil
				if p.curr_tok.kind != .Open_Brace {
					tag = parse_simple_stmt(p, nil)
				}
			}
		}
	}


	skip_possible_newline(p)
	open := expect_token(p, .Open_Brace)

	for p.curr_tok.kind == .Case {
		clause := parse_case_clause(p, is_type_switch)
		append(&clauses, clause)
	}

	close := expect_token(p, .Close_Brace)

	body := ast.new(ast.Block_Stmt, open.pos, end_pos(close))
	body.stmts = clauses[:]

	if is_type_switch {
		ts := ast.new(ast.Type_Switch_Stmt, tok.pos, body)
		ts.tag  = tag
		ts.body = body
		ts.switch_pos = tok.pos
		return ts
	} else {
		cond := convert_stmt_to_expr(p, tag, "switch expression")
		ts := ast.new(ast.Switch_Stmt, tok.pos, body)
		ts.init = init
		ts.cond = cond
		ts.body = body
		ts.switch_pos = tok.pos
		return ts
	}
}

parse_attribute :: proc(p: ^Parser, tok: tokenizer.Token, open_kind, close_kind: tokenizer.Token_Kind, docs: ^ast.Comment_Group) -> ^ast.Stmt {
	elems: [dynamic]^ast.Expr

	open, close: tokenizer.Token

	if p.curr_tok.kind == .Ident {
		elem := parse_ident(p)
		append(&elems, elem)
	} else {
		open = expect_token(p, open_kind)
		p.expr_level += 1
		for p.curr_tok.kind != close_kind &&
			p.curr_tok.kind != .EOF {
			elem: ^ast.Expr
			elem = parse_ident(p)
			if p.curr_tok.kind == .Eq {
				eq := expect_token(p, .Eq)
				value := parse_value(p)
				fv := ast.new(ast.Field_Value, elem.pos, value)
				fv.field = elem
				fv.sep   = eq.pos
				fv.value = value

				elem = fv
			}
			append(&elems, elem)

			allow_token(p, .Comma) or_break
		}
		p.expr_level -= 1
		close = expect_token_after(p, close_kind, "attribute")
	}

	attribute := ast.new(ast.Attribute, tok.pos, end_pos(close))
	attribute.tok   = tok.kind
	attribute.open  = open.pos
	attribute.elems = elems[:]
	attribute.close = close.pos

	skip_possible_newline(p)

	decl := parse_stmt(p)
	#partial switch d in decl.derived_stmt {
	case ^ast.Value_Decl:
		if d.docs == nil { d.docs = docs }
		append(&d.attributes, attribute)
	case ^ast.Foreign_Block_Decl:
		if d.docs == nil { d.docs = docs }
		append(&d.attributes, attribute)
	case ^ast.Foreign_Import_Decl:
		if d.docs == nil { d.docs = docs }
		append(&d.attributes, attribute)
	case:
		error(p, decl.pos, "expected a value or foreign declaration after an attribute")
		free(attribute)
		delete(elems)
	}
	return decl

}

parse_foreign_block_decl :: proc(p: ^Parser) -> ^ast.Stmt {
	decl := parse_stmt(p)
	#partial switch _ in decl.derived_stmt {
	case ^ast.Empty_Stmt, ^ast.Bad_Stmt, ^ast.Bad_Decl:
		// Ignore
		return nil
	case ^ast.When_Stmt, ^ast.Value_Decl:
		return decl
	}

	error(p, decl.pos, "foreign blocks only allow procedure and variable declarations")

	return nil

}

parse_foreign_block :: proc(p: ^Parser, tok: tokenizer.Token) -> ^ast.Foreign_Block_Decl {
	docs := p.lead_comment

	foreign_library: ^ast.Expr
	#partial switch p.curr_tok.kind {
	case .Open_Brace:
		i := ast.new(ast.Ident, tok.pos, end_pos(tok))
		i.name = "_"
		foreign_library = i
	case:
		foreign_library = parse_ident(p)
	}

	decls: [dynamic]^ast.Stmt

	prev_in_foreign_block := p.in_foreign_block
	defer p.in_foreign_block = prev_in_foreign_block
	p.in_foreign_block = true

	skip_possible_newline_for_literal(p)
	open := expect_token(p, .Open_Brace)
	for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
		decl := parse_foreign_block_decl(p)
		if decl != nil {
			append(&decls, decl)
		}
	}
	close := expect_token(p, .Close_Brace)

	body := ast.new(ast.Block_Stmt, open.pos, end_pos(close))
	body.open = open.pos
	body.stmts = decls[:]
	body.close = close.pos

	decl := ast.new(ast.Foreign_Block_Decl, tok.pos, body)
	decl.docs            = docs
	decl.tok             = tok
	decl.foreign_library = foreign_library
	decl.body            = body
	return decl
}


parse_foreign_decl :: proc(p: ^Parser) -> ^ast.Decl {
	docs := p.lead_comment
	tok := expect_token(p, .Foreign)

	#partial switch p.curr_tok.kind {
	case .Ident, .Open_Brace:
		return parse_foreign_block(p, tok)

	case .Import:
		import_tok := expect_token(p, .Import)
		name: ^ast.Ident
		if p.curr_tok.kind == .Ident {
			name = parse_ident(p)
		}

		if name != nil && is_blank_ident(name) {
			error(p, name.pos, "illegal foreign import name: '_'")
		}

		fullpaths: [dynamic]^ast.Expr
		if allow_token(p, .Open_Brace) {
			for p.curr_tok.kind != .Close_Brace &&
				p.curr_tok.kind != .EOF {
				path := parse_expr(p, false)
				append(&fullpaths, path)

				allow_token(p, .Comma) or_break
			}
			expect_token(p, .Close_Brace)
		} else {
			path := expect_token(p, .String)
			reserve(&fullpaths, 1)
			bl := ast.new(ast.Basic_Lit, path.pos, end_pos(path))
			bl.tok = tok
			append(&fullpaths, bl)
		}

		if len(fullpaths) == 0 {
			error(p, import_tok.pos, "foreign import without any paths")
		}

		decl := ast.new(ast.Foreign_Import_Decl, tok.pos, end_pos(p.prev_tok))
		decl.docs            = docs
		decl.foreign_tok     = tok
		decl.import_tok      = import_tok
		decl.name            = name
		decl.fullpaths       = fullpaths[:]
		expect_semicolon(p, decl)
		decl.comment = p.line_comment
		return decl
	}

	error(p, tok.pos, "invalid foreign declaration")
	return ast.new(ast.Bad_Decl, tok.pos, end_pos(tok))
}


parse_unrolled_for_loop :: proc(p: ^Parser, inline_tok: tokenizer.Token) -> ^ast.Stmt {
	for_tok := expect_token(p, .For)
	val0, val1: ^ast.Expr
	in_tok: tokenizer.Token
	expr: ^ast.Expr
	body: ^ast.Stmt

	bad_stmt := false

	if p.curr_tok.kind != .In {
		idents := parse_ident_list(p, false)
		switch len(idents) {
		case 1:
			val0 = idents[0]
		case 2:
			val0, val1 = idents[0], idents[1]
		case:
			error(p, for_tok.pos, "expected either 1 or 2 identifiers")
			bad_stmt = true
		}
	}

	in_tok = expect_token(p, .In)

	prev_allow_range := p.allow_range
	prev_level := p.expr_level
	p.allow_range = true
	p.expr_level = -1

	expr = parse_expr(p, false)

	p.expr_level = prev_level
	p.allow_range = prev_allow_range

	if allow_token(p, .Do) {
		body = convert_stmt_to_body(p, parse_stmt(p))
		if for_tok.pos.line != body.pos.line {
			error(p, body.pos, "the body of a 'do' must be on the same line as the 'for' token")
		}
	} else {
		body = parse_block_stmt(p, false)
	}

	if bad_stmt {
		return ast.new(ast.Bad_Stmt, inline_tok.pos, end_pos(p.prev_tok))
	}

	range_stmt := ast.new(ast.Inline_Range_Stmt, inline_tok.pos, body)
	range_stmt.inline_pos = inline_tok.pos
	range_stmt.for_pos = for_tok.pos
	range_stmt.val0 = val0
	range_stmt.val1 = val1
	range_stmt.in_pos = in_tok.pos
	range_stmt.expr = expr
	range_stmt.body = body
	return range_stmt
}

parse_stmt :: proc(p: ^Parser) -> ^ast.Stmt {
	#partial switch p.curr_tok.kind {
	case .Inline:
		if peek_token_kind(p, .For) {
			inline_tok := expect_token(p, .Inline)
			return parse_unrolled_for_loop(p, inline_tok)
		}
		fallthrough
	// Operands
	case .No_Inline,
	     .Context, // Also allows for 'context = '
	     .Proc,
	     .Ident,
	     .Integer, .Float, .Imag,
	     .Rune, .String,
	     .Open_Paren,
	     .Pointer,
	     .Asm, // Inline assembly
	     // Unary Expressions
	     .Add, .Sub, .Xor, .Not, .And:

	    s := parse_simple_stmt(p, {Stmt_Allow_Flag.Label})
	    expect_semicolon(p, s)
		return s


	case .Foreign: return parse_foreign_decl(p)
	case .Import:  return parse_import_decl(p)
	case .If:      return parse_if_stmt(p)
	case .When:    return parse_when_stmt(p)
	case .For:     return parse_for_stmt(p)
	case .Switch:  return parse_switch_stmt(p)

	case .Defer:
		tok := advance_token(p)
		stmt := parse_stmt(p)
		#partial switch s in stmt.derived_stmt {
		case ^ast.Empty_Stmt:
			error(p, s.pos, "empty statement after defer (e.g. ';')")
		case ^ast.Defer_Stmt:
			error(p, s.pos, "you cannot defer a defer statement")
			stmt = s.stmt
		case ^ast.Return_Stmt:
			error(p, s.pos, "you cannot defer a return statement")
		}
		ds := ast.new(ast.Defer_Stmt, tok.pos, stmt)
		ds.stmt = stmt
		return ds

	case .Return:
		tok := advance_token(p)

		if p.expr_level > 0 {
			error(p, tok.pos, "you cannot use a return statement within an expression")
		}

		results: [dynamic]^ast.Expr
		for p.curr_tok.kind != .Semicolon && p.curr_tok.kind != .Close_Brace {
			result := parse_expr(p, false)
			append(&results, result)
			if p.curr_tok.kind != .Comma ||
			   p.curr_tok.kind == .EOF {
				break
			}
			advance_token(p)
		}

		end := end_pos(tok)
		if len(results) > 0 {
			end = results[len(results)-1].end
		}

		rs := ast.new(ast.Return_Stmt, tok.pos, end)
		rs.results = results[:]
		expect_semicolon(p, rs)
		return rs

	case .Break, .Continue, .Fallthrough:
		tok := advance_token(p)
		label: ^ast.Ident
		if tok.kind != .Fallthrough && p.curr_tok.kind == .Ident {
			label = parse_ident(p)
		}
		s := ast.new(ast.Branch_Stmt, tok.pos, label)
		s.tok = tok
		s.label = label
		expect_semicolon(p, s)
		return s

	case .Using:
		docs := p.lead_comment
		tok := expect_token(p, .Using)

		if p.curr_tok.kind == .Import {
			return parse_import_decl(p, Import_Decl_Kind.Using)
		}

		list := parse_lhs_expr_list(p)
		if len(list) == 0 {
			error(p, tok.pos, "illegal use of 'using' statement")
			expect_semicolon(p, nil)
			return ast.new(ast.Bad_Stmt, tok.pos, end_pos(p.prev_tok))
		}

		if p.curr_tok.kind != .Colon {
			end := list[len(list)-1]
			expect_semicolon(p, end)
			us := ast.new(ast.Using_Stmt, tok.pos, end)
			us.list = list
			return us
		}
		expect_token_after(p, .Colon, "identifier list")
		decl := parse_value_decl(p, list, docs)
		if decl != nil {
			#partial switch d in decl.derived_stmt {
			case ^ast.Value_Decl:
				d.is_using = true
				return decl
			}
		}

		error(p, tok.pos, "illegal use of 'using' statement")
		return ast.new(ast.Bad_Stmt, tok.pos, end_pos(p.prev_tok))

	case .At:
		docs := p.lead_comment
		tok := advance_token(p)
		return parse_attribute(p, tok, .Open_Paren, .Close_Paren, docs)

	case .Hash:
		tok := expect_token(p, .Hash)
		tag := expect_token(p, .Ident)
		name := tag.text

		switch name {
		case "bounds_check", "no_bounds_check":
			stmt := parse_stmt(p)
			switch name {
			case "bounds_check":
				stmt.state_flags += {.Bounds_Check}
			case "no_bounds_check":
				stmt.state_flags += {.No_Bounds_Check}
			}
			return stmt
		case "partial":
			stmt := parse_stmt(p)
			#partial switch s in stmt.derived_stmt {
			case ^ast.Switch_Stmt:      s.partial = true
			case ^ast.Type_Switch_Stmt: s.partial = true
			case: error(p, stmt.pos, "#partial can only be applied to a switch statement")
			}
			return stmt
		case "assert", "panic":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(tag))
			bd.tok  = tok
			bd.name = name
			ce := parse_call_expr(p, bd)
			es := ast.new(ast.Expr_Stmt, ce.pos, ce)
			es.expr = ce
			return es

		case "force_inline", "force_no_inline":
			expr := parse_inlining_operand(p, true, tag)
			es := ast.new(ast.Expr_Stmt, expr.pos, expr)
			es.expr = expr
			return es
		case "unroll":
			return parse_unrolled_for_loop(p, tag)
		case "reverse":
			stmt := parse_for_stmt(p)

			if range, is_range := stmt.derived.(^ast.Range_Stmt); is_range {
				if range.reverse {
					error(p, range.pos, "#reverse already applied to a 'for in' statement")
				}
				range.reverse = true
			} else {
				error(p, stmt.pos, "#reverse can only be applied to a 'for in' statement")
			}
			return stmt
		case "include":
			error(p, tag.pos, "#include is not a valid import declaration kind. Did you meant 'import'?")
			return ast.new(ast.Bad_Stmt, tok.pos, end_pos(tag))
		case:
			stmt := parse_stmt(p)
			end := stmt.pos if stmt != nil else end_pos(tok)
			te := ast.new(ast.Tag_Stmt, tok.pos, end)
			te.op   = tok
			te.name = name
			te.stmt = stmt

			fix_advance_to_next_stmt(p)
			return te
		}
	case .Open_Brace:
		return parse_block_stmt(p, false)

	case .Semicolon:
		tok := advance_token(p)
		s := ast.new(ast.Empty_Stmt, tok.pos, end_pos(tok))
		return s
	}


	#partial switch p.curr_tok.kind {
	case .Else:
		token := expect_token(p, .Else)
		error(p, token.pos, "'else' unattached to an 'if' statement")
		#partial switch p.curr_tok.kind {
		case .If:
			return parse_if_stmt(p)
		case .When:
			return parse_when_stmt(p)
		case .Open_Brace:
			return parse_block_stmt(p, true)
		case .Do:
			expect_token(p, .Do)
			return convert_stmt_to_body(p, parse_stmt(p))
		case:
			fix_advance_to_next_stmt(p)
			return ast.new(ast.Bad_Stmt, token.pos, end_pos(p.curr_tok))
		}
	}


	tok := advance_token(p)
	error(p, tok.pos, "expected a statement, got %s", tokenizer.token_to_string(tok))
	fix_advance_to_next_stmt(p)
	s := ast.new(ast.Bad_Stmt, tok.pos, end_pos(tok))
	return s
}


token_precedence :: proc(p: ^Parser, kind: tokenizer.Token_Kind) -> int {
	#partial switch kind {
	case .Question, .If, .When, .Or_Else:
		return 1
	case .Ellipsis, .Range_Half, .Range_Full:
		if !p.allow_range {
			return 0
		}
		return 2
	case .Cmp_Or:
		return 3
	case .Cmp_And:
		return 4
	case .Cmp_Eq, .Not_Eq,
	     .Lt, .Gt,
	     .Lt_Eq, .Gt_Eq:
		return 5
	case .In, .Not_In:
		if p.expr_level < 0 && !p.allow_in_expr {
			return 0
		}
		fallthrough
	case .Add, .Sub, .Or, .Xor:
		return 6
	case .Mul, .Quo,
	     .Mod, .Mod_Mod,
	     .And, .And_Not,
	     .Shl, .Shr:
		return 7
	}
	return 0
}

parse_type_or_ident :: proc(p: ^Parser) -> ^ast.Expr {
	prev_allow_type := p.allow_type
	prev_expr_level := p.expr_level
	defer {
		p.allow_type = prev_allow_type
		p.expr_level = prev_expr_level
	}

	p.allow_type = true
	p.expr_level = -1

	lhs := true
	return parse_atom_expr(p, parse_operand(p, lhs), lhs)
}
parse_type :: proc(p: ^Parser) -> ^ast.Expr {
	type := parse_type_or_ident(p)
	if type == nil {
		error(p, p.curr_tok.pos, "expected a type")
		return ast.new(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok))
	}
	return type
}

parse_body :: proc(p: ^Parser) -> ^ast.Block_Stmt {
	prev_expr_level := p.expr_level
	defer p.expr_level = prev_expr_level

	p.expr_level = 0
	open := expect_token(p, .Open_Brace)
	stmts := parse_stmt_list(p)
	close := expect_token(p, .Close_Brace)

	bs := ast.new(ast.Block_Stmt, open.pos, end_pos(close))
	bs.open = open.pos
	bs.stmts = stmts
	bs.close = close.pos
	return bs
}

convert_stmt_to_body :: proc(p: ^Parser, stmt: ^ast.Stmt) -> ^ast.Stmt {
	#partial switch s in stmt.derived_stmt {
	case ^ast.Block_Stmt:
		error(p, stmt.pos, "expected a normal statement rather than a block statement")
		return stmt
	case ^ast.Empty_Stmt:
		error(p, stmt.pos, "expected a non-empty statement")
	}

	bs := ast.new(ast.Block_Stmt, stmt.pos, stmt)
	bs.open = stmt.pos
	bs.stmts = make([]^ast.Stmt, 1)
	bs.stmts[0] = stmt
	bs.close = stmt.end
	bs.uses_do = true
	return bs
}

new_ast_field :: proc(names: []^ast.Expr, type: ^ast.Expr, default_value: ^ast.Expr) -> ^ast.Field {
	pos, end: tokenizer.Pos

	if len(names) > 0 {
		pos = names[0].pos
		if default_value != nil {
			end = default_value.end
		} else if type != nil {
			end = type.end
		} else {
			end = names[len(names)-1].pos
		}
	} else {
		if type != nil {
			pos = type.pos
		} else if default_value != nil {
			pos = default_value.pos
		}

		if default_value != nil {
			end = default_value.end
		} else if type != nil {
			end = type.end
		}
	}

	field := ast.new(ast.Field, pos, end)
	field.names = names
	field.type  = type
	field.default_value = default_value
	return field
}

Expr_And_Flags :: struct {
	expr:  ^ast.Expr,
	flags: ast.Field_Flags,
}

convert_to_ident_list :: proc(p: ^Parser, list: []Expr_And_Flags, ignore_flags, allow_poly_names: bool) -> []^ast.Expr {
	idents := make([dynamic]^ast.Expr, 0, len(list))

	for ident, i in list {
		if !ignore_flags {
			if i != 0 {
				error(p, ident.expr.pos, "illegal use of prefixes in parameter list")
			}
		}

		id: ^ast.Expr = ident.expr

		#partial switch n in ident.expr.derived_expr {
		case ^ast.Ident:
		case ^ast.Bad_Expr:
		case ^ast.Poly_Type:
			if allow_poly_names {
				if n.specialization == nil {
					break
				} else {
					error(p, ident.expr.pos, "expected a polymorphic identifier without an specialization")
				}
			} else {
				error(p, ident.expr.pos, "expected a non-polymorphic identifier")
			}
		case:
			error(p, ident.expr.pos, "expected an identifier")
			id = ast.new(ast.Ident, ident.expr.pos, ident.expr.end)
		}

		append(&idents, id)
	}

	return idents[:]
}

is_token_field_prefix :: proc(p: ^Parser) -> ast.Field_Flag {
	#partial switch p.curr_tok.kind {
	case .EOF:
		return .Invalid
	case .Using:
		advance_token(p)
		return .Using
	case .Hash:
		tok: tokenizer.Token
		advance_token(p)
		tok = p.curr_tok
		advance_token(p)
		if tok.kind == .Ident {
			for kf in ast.field_hash_flag_strings {
				if kf.key == tok.text {
					return kf.flag
				}
			}
		}
		return .Unknown
	}
	return .Invalid
}

parse_field_prefixes :: proc(p: ^Parser) -> (flags: ast.Field_Flags) {
	counts: [len(ast.Field_Flag)]int

	for {
		kind := is_token_field_prefix(p)
		if kind == .Invalid {
			break
		}

		if kind == .Unknown {
			error(p, p.curr_tok.pos, "unknown prefix kind '#%s'", p.curr_tok.text)
			continue
		}

		counts[kind] += 1
	}

	for kind in ast.Field_Flag {
		count := counts[kind]
		if kind == .Invalid || kind == .Unknown {
			// Ignore
		} else {
			if count > 1 { error(p, p.curr_tok.pos, "multiple '%s' in this field list", ast.field_flag_strings[kind]) }
			if count > 0 { flags += {kind} }
		}
	}

	return
}

check_field_flag_prefixes :: proc(p: ^Parser, name_count: int, allowed_flags, set_flags: ast.Field_Flags) -> (flags: ast.Field_Flags) {
	flags = set_flags
	if name_count > 1 && .Using in flags {
		error(p, p.curr_tok.pos, "cannot apply 'using' to more than one of the same type")
		flags -= {.Using}
	}

	for flag in ast.Field_Flag {
		if flag not_in allowed_flags && flag in flags {
			#partial switch flag {
			case .Unknown, .Invalid:
				// ignore
			case .Tags, .Ellipsis, .Results, .Default_Parameters, .Typeid_Token:
				panic("Impossible prefixes")
			case:
				error(p, p.curr_tok.pos, "'%s' is not allowed within this field list", ast.field_flag_strings[flag])
			}
			flags -= {flag}
		}
	}

	return flags
}

parse_var_type :: proc(p: ^Parser, flags: ast.Field_Flags) -> ^ast.Expr {
	if .Ellipsis in flags && p.curr_tok.kind == .Ellipsis {
		tok := advance_token(p)
		type := parse_type_or_ident(p)
		if type == nil {
			error(p, tok.pos, "variadic field missing type after '..'")
			type = ast.new(ast.Bad_Expr, tok.pos, end_pos(tok))
		}
		e := ast.new(ast.Ellipsis, type.pos, type)
		e.expr = type
		return e
	}
	type: ^ast.Expr
	if .Typeid_Token in flags && p.curr_tok.kind == .Typeid {
		tok := expect_token(p, .Typeid)
		specialization: ^ast.Expr
		end := tok.pos
		if allow_token(p, .Quo) {
			specialization = parse_type(p)
			end = specialization.end
		}

		ti := ast.new(ast.Typeid_Type, tok.pos, end)
		ti.tok = tok.kind
		ti.specialization = specialization
		type = ti
	} else {
		type = parse_type(p)
	}

	return type
}

check_procedure_name_list :: proc(p: ^Parser, names: []^ast.Expr) -> bool {
	if len(names) == 0 {
		return false
	}

	_, first_is_polymorphic := names[0].derived.(^ast.Poly_Type)
	any_polymorphic_names := first_is_polymorphic

	for i := 1; i < len(names); i += 1 {
		name := names[i]

		if first_is_polymorphic {
			if _, ok := name.derived.(^ast.Poly_Type); ok {
				any_polymorphic_names = true
			} else {
				error(p, name.pos, "mixture of polymorphic and non-polymorphic identifiers")
				return any_polymorphic_names
			}
		} else {
			if _, ok := name.derived.(^ast.Poly_Type); ok {
				any_polymorphic_names = true
				error(p, name.pos, "mixture of polymorphic and non-polymorphic identifiers")
				return any_polymorphic_names
			} else {
				// Okay
			}
		}
	}

	return any_polymorphic_names
}

parse_ident_list :: proc(p: ^Parser, allow_poly_names: bool) -> []^ast.Expr {
	list: [dynamic]^ast.Expr

	for {
		if allow_poly_names && p.curr_tok.kind == .Dollar {
			tok := expect_token(p, .Dollar)
			ident := parse_ident(p)
			if is_blank_ident(ident) {
				error(p, ident.pos, "invalid polymorphic type definition with a blank identifier")
			}
			poly_name := ast.new(ast.Poly_Type, tok.pos, ident)
			poly_name.type = ident
			append(&list, poly_name)
		} else {
			ident := parse_ident(p)
			append(&list, ident)
		}
		if p.curr_tok.kind != .Comma ||
		   p.curr_tok.kind == .EOF {
		   	break
		}
		advance_token(p)
	}

	return list[:]
}



parse_field_list :: proc(p: ^Parser, follow: tokenizer.Token_Kind, allowed_flags: ast.Field_Flags) -> (field_list: ^ast.Field_List, total_name_count: int) {
	handle_field :: proc(p: ^Parser,
	                     seen_ellipsis: ^bool, fields: ^[dynamic]^ast.Field,
	                     docs: ^ast.Comment_Group,
	                     names: []^ast.Expr,
	                     allowed_flags, set_flags: ast.Field_Flags,
	                     ) -> bool {

		expect_field_separator :: proc(p: ^Parser, param: ^ast.Expr) -> bool {
			tok := p.curr_tok
			if allow_token(p, .Comma) {
				return true
			}
			if allow_token(p, .Semicolon) {
				if !tokenizer.is_newline(tok) {
					error(p, tok.pos, "expected a comma, got a semicolon")
				}
				return true
			}
			return false
		}
		is_type_ellipsis :: proc(type: ^ast.Expr) -> bool {
			if type == nil {
				return false
			}
			_, ok := type.derived.(^ast.Ellipsis)
			return ok
		}

		is_signature := (allowed_flags & ast.Field_Flags_Signature_Params) == ast.Field_Flags_Signature_Params

		any_polymorphic_names := check_procedure_name_list(p, names)
		flags := check_field_flag_prefixes(p, len(names), allowed_flags, set_flags)

		type:          ^ast.Expr
		default_value: ^ast.Expr
		tag: tokenizer.Token

		expect_token_after(p, .Colon, "field list")
		if p.curr_tok.kind != .Eq {
			type = parse_var_type(p, allowed_flags)
			tt := ast.unparen_expr(type)
			if is_signature && !any_polymorphic_names {
				if ti, ok := tt.derived.(^ast.Typeid_Type); ok && ti.specialization != nil {
					error(p, tt.pos, "specialization of typeid is not allowed without polymorphic names")
				}
			}
		}

		if allow_token(p, .Eq) {
			default_value = parse_expr(p, false)
			if .Default_Parameters not_in allowed_flags {
				error(p, p.curr_tok.pos, "default parameters are only allowed for procedures")
				default_value = nil
			}
		}

		if default_value != nil && len(names) > 1 {
			error(p, p.curr_tok.pos, "default parameters can only be applied to single values")
		}

		if allowed_flags == ast.Field_Flags_Struct && default_value != nil {
			error(p, default_value.pos, "default parameters are not allowed for structs")
			default_value = nil
		}

		if is_type_ellipsis(type) {
			if seen_ellipsis^ {
				error(p, type.pos, "extra variadic parameter after ellipsis")
			}
			seen_ellipsis^ = true
			if len(names) != 1 {
				error(p, type.pos, "variadic parameters can only have one field name")
			}
		} else if seen_ellipsis^ && default_value == nil {
			error(p, p.curr_tok.pos, "extra parameter after ellipsis without a default value")
		}

		if type != nil && default_value == nil {
			if p.curr_tok.kind == .String {
				tag = expect_token(p, .String)
				if .Tags not_in allowed_flags {
					error(p, tag.pos, "Field tags are only allowed within structures")
				}
			}
		}

		ok := expect_field_separator(p, type)

		field := new_ast_field(names, type, default_value)
		field.tag     = tag
		field.docs    = docs
		field.flags   = flags
		field.comment = p.line_comment
		append(fields, field)

		return ok
	}


	start_tok := p.curr_tok

	docs := p.lead_comment

	fields: [dynamic]^ast.Field

	list: [dynamic]Expr_And_Flags
	defer delete(list)

	seen_ellipsis := false

	allow_typeid_token := .Typeid_Token in allowed_flags
	allow_poly_names := allow_typeid_token

	for p.curr_tok.kind != follow &&
	    p.curr_tok.kind != .Colon &&
	    p.curr_tok.kind != .EOF {
		prefix_flags := parse_field_prefixes(p)
		param := parse_var_type(p, allowed_flags & {.Typeid_Token, .Ellipsis})
		if _, ok := param.derived.(^ast.Ellipsis); ok {
			if seen_ellipsis {
				error(p, param.pos, "extra variadic parameter after ellipsis")
			}
			seen_ellipsis = true
		} else if seen_ellipsis {
			error(p, param.pos, "extra parameter after ellipsis")
		}

		eaf := Expr_And_Flags{param, prefix_flags}
		append(&list, eaf)
		allow_token(p, .Comma) or_break
	}

	if p.curr_tok.kind != .Colon {
		for eaf in list {
			type := eaf.expr
			tok: tokenizer.Token
			tok.pos = type.pos
			if .Results not_in allowed_flags {
				tok.text = "_"
			}

			names := make([]^ast.Expr, 1)
			names[0] = ast.new(ast.Ident, tok.pos, end_pos(tok))
			#partial switch ident in names[0].derived_expr {
			case ^ast.Ident:
				ident.name = tok.text
			case:
				unreachable()
			}

			flags := check_field_flag_prefixes(p, len(list), allowed_flags, eaf.flags)

			field := new_ast_field(names, type, nil)
			field.docs    = docs
			field.flags   = flags
			field.comment = p.line_comment
			append(&fields, field)
		}
	} else {
		names := convert_to_ident_list(p, list[:], true, allow_poly_names)
		if len(names) == 0 {
			error(p, p.curr_tok.pos, "empty field declaration")
		}

		set_flags: ast.Field_Flags
		if len(list) > 0 {
			set_flags = list[0].flags
		}
		total_name_count += len(names)
		handle_field(p, &seen_ellipsis, &fields, docs, names, allowed_flags, set_flags)

		for p.curr_tok.kind != follow && p.curr_tok.kind != .EOF {
			docs = p.lead_comment
			set_flags = parse_field_prefixes(p)
			names = parse_ident_list(p, allow_poly_names)

			total_name_count += len(names)
			handle_field(p, &seen_ellipsis, &fields, docs, names, allowed_flags, set_flags) or_break
		}
	}

	field_list = ast.new(ast.Field_List, start_tok.pos, p.curr_tok.pos)
	field_list.list = fields[:]
	return
}


parse_results :: proc(p: ^Parser) -> (list: ^ast.Field_List, diverging: bool) {
	if !allow_token(p, .Arrow_Right) {
		return
	}

	if allow_token(p, .Not) {
		diverging = true
		return
	}

	prev_level := p.expr_level
	defer p.expr_level = prev_level

	if p.curr_tok.kind != .Open_Paren {
		type := parse_type(p)
		field := new_ast_field(nil, type, nil)

		list = ast.new(ast.Field_List, field.pos, field.end)
		list.list = make([]^ast.Field, 1)
		list.list[0] = field
		return
	}

	expect_token(p, .Open_Paren)
	list, _ = parse_field_list(p, .Close_Paren, ast.Field_Flags_Signature_Results)
	expect_token_after(p, .Close_Paren, "parameter list")
	return
}


string_to_calling_convention :: proc(s: string) -> ast.Proc_Calling_Convention {
	if s[0] != '"' && s[0] != '`' {
		return nil
	}
	if len(s) == 2 {
		return nil
	}
	return s
}

parse_proc_tags :: proc(p: ^Parser) -> (tags: ast.Proc_Tags) {
	for p.curr_tok.kind == .Hash {
		_ = expect_token(p, .Hash)
		ident := expect_token(p, .Ident)

		switch ident.text {
		case "bounds_check":    tags += {.Bounds_Check}
		case "no_bounds_check": tags += {.No_Bounds_Check}
		case "optional_ok":     tags += {.Optional_Ok}
		case "optional_allocator_error": tags += {.Optional_Allocator_Error}
		case:
		}
	}

	if .Bounds_Check in tags && .No_Bounds_Check in tags {
		p.err(p.curr_tok.pos, "#bounds_check and #no_bounds_check applied to the same procedure type")
	}

	return
}

parse_proc_type :: proc(p: ^Parser, tok: tokenizer.Token) -> ^ast.Proc_Type {
	cc: ast.Proc_Calling_Convention
	if p.curr_tok.kind == .String {
		str := expect_token(p, .String)
		cc = string_to_calling_convention(str.text)
		if cc == nil {
			error(p, str.pos, "unknown calling convention '%s'", str.text)
		}
	}

	if cc == nil && p.in_foreign_block {
		cc = .Foreign_Block_Default
	}

	expect_token(p, .Open_Paren)
	p.expr_level += 1
	params, _ := parse_field_list(p, .Close_Paren, ast.Field_Flags_Signature_Params)
	p.expr_level -= 1
	expect_closing_parentheses_of_field_list(p)
	results, diverging := parse_results(p)

	is_generic := false

	loop: for param in params.list {
		if param.type != nil {
			if _, ok := param.type.derived.(^ast.Poly_Type); ok {
				is_generic = true
				break loop
			}
			for name in param.names {
				if _, ok := name.derived.(^ast.Poly_Type); ok {
					is_generic = true
					break loop
				}
			}
		}
	}

	end := end_pos(p.prev_tok)
	pt := ast.new(ast.Proc_Type, tok.pos, end)
	pt.tok = tok
	pt.calling_convention = cc
	pt.params = params
	pt.results = results
	pt.diverging = diverging
	pt.generic = is_generic
	return pt
}

parse_inlining_operand :: proc(p: ^Parser, lhs: bool, tok: tokenizer.Token) -> ^ast.Expr {
	expr := parse_unary_expr(p, lhs)

	pi := ast.Proc_Inlining.None
	#partial switch tok.kind {
	case .Inline:
		pi = .Inline
	case .No_Inline:
		pi = .No_Inline
	case .Ident:
		switch tok.text {
		case "force_inline":
			pi = .Inline
		case "force_no_inline":
			pi = .No_Inline
		}
	}

	#partial switch e in ast.strip_or_return_expr(expr).derived_expr {
	case ^ast.Proc_Lit:
		if e.inlining != .None && e.inlining != pi {
			error(p, expr.pos, "both 'inline' and 'no_inline' cannot be applied to a procedure literal")
		}
		e.inlining = pi
	case ^ast.Call_Expr:
		if e.inlining != .None && e.inlining != pi {
			error(p, expr.pos, "both 'inline' and 'no_inline' cannot be applied to a procedure call")
		}
		e.inlining = pi
	case:
		error(p, tok.pos, "'%s' must be followed by a procedure literal or call", tok.text)
		return ast.new(ast.Bad_Expr, tok.pos, expr)
	}
	return expr
}

parse_operand :: proc(p: ^Parser, lhs: bool) -> ^ast.Expr {
	#partial switch p.curr_tok.kind {
	case .Ident:
		return parse_ident(p)

	case .Undef:
		tok := expect_token(p, .Undef)
		undef := ast.new(ast.Undef, tok.pos, end_pos(tok))
		undef.tok = tok.kind
		return undef

	case .Context:
		tok := expect_token(p, .Context)
		ctx := ast.new(ast.Implicit, tok.pos, end_pos(tok))
		ctx.tok = tok
		return ctx

	case .Integer, .Float, .Imag,
	     .Rune, .String:
	     tok := advance_token(p)
	     bl := ast.new(ast.Basic_Lit, tok.pos, end_pos(tok))
	     bl.tok = tok
	     return bl

	case .Open_Brace:
		if !lhs {
			return parse_literal_value(p, nil)
		}

	case .Open_Paren:
		open := expect_token(p, .Open_Paren)
		p.expr_level += 1
		expr := parse_expr(p, false)
		p.expr_level -= 1
		close := expect_token(p, .Close_Paren)

		pe := ast.new(ast.Paren_Expr, open.pos, end_pos(close))
		pe.open  = open.pos
		pe.expr  = expr
		pe.close = close.pos
		return pe

	case .Distinct:
		tok := advance_token(p)
		type := parse_type(p)
		dt := ast.new(ast.Distinct_Type, tok.pos, type)
		dt.tok  = tok.kind
		dt.type = type
		return dt

	case .Hash:
		tok := expect_token(p, .Hash)
		name := expect_token(p, .Ident)
		switch name.text {
		case "type":
			type := parse_type(p)
			hp := ast.new(ast.Helper_Type, tok.pos, type)
			hp.tok  = tok.kind
			hp.type = type
			return hp

		case "file", "line", "procedure", "caller_location":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(name))
			bd.tok  = tok
			bd.name = name.text
			return bd
		case "location", "load", "assert", "defined", "config":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(name))
			bd.tok  = tok
			bd.name = name.text
			return parse_call_expr(p, bd)


		case "soa":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(name))
			bd.tok  = tok
			bd.name = name.text
			original_type := parse_type(p)
			type := ast.unparen_expr(original_type)
			#partial switch t in type.derived_expr {
			case ^ast.Array_Type:         t.tag = bd
			case ^ast.Dynamic_Array_Type: t.tag = bd
			case ^ast.Pointer_Type:       t.tag = bd
			case:
				error(p, original_type.pos, "expected an array or pointer type after #%s", name.text)
			}
			return original_type

		case "simd":
			bd := ast.new(ast.Basic_Directive, tok.pos, end_pos(name))
			bd.tok  = tok
			bd.name = name.text
			original_type := parse_type(p)
			type := ast.unparen_expr(original_type)
			#partial switch t in type.derived_expr {
			case ^ast.Array_Type:         t.tag = bd
			case:
				error(p, original_type.pos, "expected an array type after #%s", name.text)
			}
			return original_type

		case "partial":
			tag := ast.new(ast.Basic_Directive, tok.pos, end_pos(name))
			tag.tok = tok
			tag.name = name.text
			original_expr := parse_expr(p, lhs)
			expr := ast.unparen_expr(original_expr)
			#partial switch t in expr.derived_expr {
			case ^ast.Comp_Lit:
				t.tag = tag
			case ^ast.Array_Type:
				t.tag = tag
				error(p, tok.pos, "#%s has been replaced with #sparse for non-contiguous enumerated array types", name.text)
			case:
				error(p, tok.pos, "expected a compound literal after #%s", name.text)

			}
			return original_expr

		case "sparse":
			tag := ast.new(ast.Basic_Directive, tok.pos, end_pos(name))
			tag.tok = tok
			tag.name = name.text
			original_type := parse_type(p)
			type := ast.unparen_expr(original_type)
			#partial switch t in type.derived_expr {
			case ^ast.Array_Type:
				t.tag = tag
			case:
				error(p, tok.pos, "expected an enumerated array type after #%s", name.text)

			}
			return original_type

		case "bounds_check", "no_bounds_check":
			operand := parse_expr(p, lhs)

			switch name.text {
			case "bounds_check":
				operand.state_flags += {.Bounds_Check}
				if .No_Bounds_Check in operand.state_flags {
					error(p, name.pos, "#bounds_check and #no_bounds_check cannot be applied together")
				}
			case "no_bounds_check":
				operand.state_flags += {.No_Bounds_Check}
				if .Bounds_Check in operand.state_flags {
					error(p, name.pos, "#bounds_check and #no_bounds_check cannot be applied together")
				}
			case: unimplemented()
			}
			return operand

		case "relative":
			tag := ast.new(ast.Basic_Directive, tok.pos, end_pos(name))
			tag.tok = tok
			tag.name = name.text

			tag_call := parse_call_expr(p, tag)
			type := parse_type(p)

			rt := ast.new(ast.Relative_Type, tok.pos, type)
			rt.tag = tag_call
			rt.type = type
			return rt

		case "force_inline", "force_no_inline":
			return parse_inlining_operand(p, lhs, name)
		case:
			expr := parse_expr(p, lhs)
			end := expr.pos if expr != nil else end_pos(tok)
			te := ast.new(ast.Tag_Expr, tok.pos, end)
			te.op   = tok
			te.name = name.text
			te.expr = expr
			return te
		}

	case .Inline, .No_Inline:
		tok := advance_token(p)
		return parse_inlining_operand(p, lhs, tok)

	case .Proc:
		tok := expect_token(p, .Proc)

		if p.curr_tok.kind == .Open_Brace {
			open := expect_token(p, .Open_Brace)

			args: [dynamic]^ast.Expr

			for p.curr_tok.kind != .Close_Brace &&
			    p.curr_tok.kind != .EOF {
				elem := parse_expr(p, false)
				append(&args, elem)

				allow_token(p, .Comma) or_break
			}

			close := expect_token(p, .Close_Brace)

			if len(args) == 0 {
				error(p, tok.pos, "expected at least 1 argument in procedure group")
			}

			pg := ast.new(ast.Proc_Group, tok.pos, end_pos(close))
			pg.tok   = tok
			pg.open  = open.pos
			pg.args  = args[:]
			pg.close = close.pos
			return pg
		}

		type := parse_proc_type(p, tok)
		tags: ast.Proc_Tags
		where_token: tokenizer.Token
		where_clauses: []^ast.Expr

		skip_possible_newline_for_literal(p)

		if p.curr_tok.kind == .Where {
			where_token = expect_token(p, .Where)
			prev_level := p.expr_level
			p.expr_level = -1
			where_clauses = parse_rhs_expr_list(p)
			p.expr_level = prev_level
		}
		tags = parse_proc_tags(p)
		type.tags = tags

		if p.allow_type && p.expr_level < 0 {
			if where_token.kind != .Invalid {
				error(p, where_token.pos, "'where' clauses are not allowed on procedure types")
			}
			return type
		}
		body: ^ast.Stmt

		skip_possible_newline_for_literal(p)

		if allow_token(p, .Undef) {
			body = nil
			if where_token.kind != .Invalid {
				error(p, where_token.pos, "'where' clauses are not allowed on procedure literals without a defined body (replaced with ---")
			}
		} else if p.curr_tok.kind == .Open_Brace {
			prev_proc := p.curr_proc
			p.curr_proc = type
			body = parse_body(p)
			p.curr_proc = prev_proc
		} else if allow_token(p, .Do) {
			prev_proc := p.curr_proc
			p.curr_proc = type
			body = convert_stmt_to_body(p, parse_stmt(p))
			p.curr_proc = prev_proc
			if type.pos.line != body.pos.line {
				error(p, body.pos, "the body of a 'do' must be on the same line as the signature")
			}
		} else {
			return type
		}

		pl := ast.new(ast.Proc_Lit, tok.pos, end_pos(p.prev_tok))
		pl.type = type
		pl.body = body
		pl.tags = tags
		pl.where_token = where_token
		pl.where_clauses = where_clauses
		return pl

	case .Dollar:
		tok := advance_token(p)
		type := parse_ident(p)
		end := type.end

		specialization: ^ast.Expr
		if allow_token(p, .Quo) {
			specialization = parse_type(p)
			end = specialization.pos
		}
		if is_blank_ident(type) {
			error(p, type.pos, "invalid polymorphic type definition with a blank identifier")
		}

		pt := ast.new(ast.Poly_Type, tok.pos, end)
		pt.dollar = tok.pos
		pt.type = type
		pt.specialization = specialization
		return pt

	case .Typeid:
		tok := advance_token(p)
		ti := ast.new(ast.Typeid_Type, tok.pos, end_pos(tok))
		ti.tok = tok.kind
		ti.specialization = nil
		return ti

	case .Pointer:
		tok := expect_token(p, .Pointer)
		elem := parse_type(p)
		ptr := ast.new(ast.Pointer_Type, tok.pos, elem)
		ptr.pointer = tok.pos
		ptr.elem = elem
		return ptr


	case .Open_Bracket:
		open := expect_token(p, .Open_Bracket)
		count: ^ast.Expr
		#partial switch p.curr_tok.kind {
		case .Pointer:
			tok := expect_token(p, .Pointer)
			close := expect_token(p, .Close_Bracket)
			elem := parse_type(p)
			t := ast.new(ast.Multi_Pointer_Type, open.pos, elem)
			t.open = open.pos
			t.pointer = tok.pos
			t.close = close.pos
			t.elem = elem
			return t
		case .Dynamic:
			tok := expect_token(p, .Dynamic)
			close := expect_token(p, .Close_Bracket)
			elem := parse_type(p)
			da := ast.new(ast.Dynamic_Array_Type, open.pos, elem)
			da.open = open.pos
			da.dynamic_pos = tok.pos
			da.close = close.pos
			da.elem = elem
			return da
		case .Question:
			tok := expect_token(p, .Question)
			q := ast.new(ast.Unary_Expr, tok.pos, end_pos(tok))
			q.op = tok
			count = q
		case:
			p.expr_level += 1
			count = parse_expr(p, false)
			p.expr_level -= 1
		case .Close_Bracket:
			// handle below
		}
		close := expect_token(p, .Close_Bracket)
		elem := parse_type(p)
		at := ast.new(ast.Array_Type, open.pos, elem)
		at.open  = open.pos
		at.len   = count
		at.close = close.pos
		at.elem  = elem
		return at

	case .Map:
		tok := expect_token(p, .Map)
		expect_token(p, .Open_Bracket)
		key := parse_type(p)
		expect_token(p, .Close_Bracket)
		value := parse_type(p)

		mt := ast.new(ast.Map_Type, tok.pos, value)
		mt.tok_pos = tok.pos
		mt.key = key
		mt.value = value
		return mt

	case .Struct:
		tok := expect_token(p, .Struct)

		poly_params: ^ast.Field_List
		align:        ^ast.Expr
		field_align:  ^ast.Expr
		is_packed:    bool
		is_raw_union: bool
		is_no_copy:   bool
		fields:       ^ast.Field_List
		name_count:   int

		if allow_token(p, .Open_Paren) {
			param_count: int
			poly_params, param_count = parse_field_list(p, .Close_Paren, ast.Field_Flags_Record_Poly_Params)
			if param_count == 0 {
				error(p, poly_params.pos, "expected at least 1 polymorphic parameter")
				poly_params = nil
			}
			expect_token_after(p, .Close_Paren, "parameter list")
		}

		prev_level := p.expr_level
		p.expr_level = -1
		for allow_token(p, .Hash) {
			tag := expect_token_after(p, .Ident, "#")
			switch tag.text {
			case "packed":
				if is_packed {
					error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
				}
				is_packed = true
			case "align":
				if align != nil {
					error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
				}
				align = parse_expr(p, true)
			case "field_align":
				if field_align != nil {
					error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
				}
				field_align = parse_expr(p, true)
			case "raw_union":
				if is_raw_union {
					error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
				}
				is_raw_union = true
			case "no_copy":
				if is_no_copy {
					error(p, tag.pos, "duplicate struct tag '#%s'", tag.text)
				}
				is_no_copy = true
			case:
				error(p, tag.pos, "invalid struct tag '#%s", tag.text)
			}
		}
		p.expr_level = prev_level

		if is_raw_union && is_packed {
			is_packed = false
			error(p, tok.pos, "'#raw_union' cannot also be '#packed")
		}

		where_token: tokenizer.Token
		where_clauses: []^ast.Expr

		skip_possible_newline_for_literal(p)

		if p.curr_tok.kind == .Where {
			where_token = expect_token(p, .Where)
			where_prev_level := p.expr_level
			p.expr_level = -1
			where_clauses = parse_rhs_expr_list(p)
			p.expr_level = where_prev_level
		}

		skip_possible_newline_for_literal(p)
		expect_token(p, .Open_Brace)
		fields, name_count = parse_field_list(p, .Close_Brace, ast.Field_Flags_Struct)
		close := expect_closing_brace_of_field_list(p)

		st := ast.new(ast.Struct_Type, tok.pos, end_pos(close))
		st.poly_params   = poly_params
		st.align         = align
		st.field_align   = field_align
		st.is_packed     = is_packed
		st.is_raw_union  = is_raw_union
		st.is_no_copy    = is_no_copy
		st.fields        = fields
		st.name_count    = name_count
		st.where_token   = where_token
		st.where_clauses = where_clauses
		return st

	case .Union:
		tok := expect_token(p, .Union)
		poly_params: ^ast.Field_List
		align:       ^ast.Expr
		is_no_nil:     bool
		is_shared_nil: bool

		if allow_token(p, .Open_Paren) {
			param_count: int
			poly_params, param_count = parse_field_list(p, .Close_Paren, ast.Field_Flags_Record_Poly_Params)
			if param_count == 0 {
				error(p, poly_params.pos, "expected at least 1 polymorphic parameter")
				poly_params = nil
			}
			expect_token_after(p, .Close_Paren, "parameter list")
		}

		prev_level := p.expr_level
		p.expr_level = -1
		for allow_token(p, .Hash) {
			tag := expect_token_after(p, .Ident, "#")
			switch tag.text {
			case "align":
				if align != nil {
					error(p, tag.pos, "duplicate union tag '#%s'", tag.text)
				}
				align = parse_expr(p, true)
			case "maybe":
				error(p, tag.pos, "#%s functionality has now been merged with standard 'union' functionality", tag.text)
			case "no_nil":
				if is_no_nil {
					error(p, tag.pos, "duplicate union tag '#%s'", tag.text)
				}
				is_no_nil = true
			case "shared_nil":
				if is_shared_nil {
					error(p, tag.pos, "duplicate union tag '#%s'", tag.text)
				}
				is_shared_nil = true
			case:
				error(p, tag.pos, "invalid union tag '#%s", tag.text)
			}
		}
		p.expr_level = prev_level

		if is_no_nil && is_shared_nil {
			error(p, p.curr_tok.pos, "#shared_nil and #no_nil cannot be applied together")
		}

		union_kind := ast.Union_Type_Kind.Normal
		switch {
		case is_no_nil:     union_kind = .no_nil
		case is_shared_nil: union_kind = .shared_nil
		}

		where_token: tokenizer.Token
		where_clauses: []^ast.Expr

		skip_possible_newline_for_literal(p)

		if p.curr_tok.kind == .Where {
			where_token = expect_token(p, .Where)
			where_prev_level := p.expr_level
			p.expr_level = -1
			where_clauses = parse_rhs_expr_list(p)
			p.expr_level = where_prev_level
		}


		skip_possible_newline_for_literal(p)
		expect_token_after(p, .Open_Brace, "union")

		variants: [dynamic]^ast.Expr
		for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
			type := parse_type(p)
			if _, ok := type.derived.(^ast.Bad_Expr); !ok {
				append(&variants, type)
			}
			allow_token(p, .Comma) or_break
		}

		close := expect_closing_brace_of_field_list(p)



		ut := ast.new(ast.Union_Type, tok.pos, end_pos(close))
		ut.poly_params   = poly_params
		ut.variants      = variants[:]
		ut.align         = align
		ut.where_token   = where_token
		ut.where_clauses = where_clauses
		ut.kind          = union_kind

		return ut

	case .Enum:
		tok := expect_token(p, .Enum)
		base_type: ^ast.Expr
		if p.curr_tok.kind != .Open_Brace {
			base_type = parse_type(p)
		}

		skip_possible_newline_for_literal(p)
		open := expect_token(p, .Open_Brace)
		fields := parse_elem_list(p)
		close := expect_closing_brace_of_field_list(p)

		et := ast.new(ast.Enum_Type, tok.pos, end_pos(close))
		et.base_type = base_type
		et.open = open.pos
		et.fields = fields
		et.close = close.pos
		return et

	case .Bit_Set:
		tok := expect_token(p, .Bit_Set)
		open := expect_token(p, .Open_Bracket)
		elem, underlying: ^ast.Expr

		prev_allow_range := p.allow_range
		p.allow_range = true
		elem = parse_expr(p, false)
		p.allow_range = prev_allow_range

		if allow_token(p, .Semicolon) {
			underlying = parse_type(p)
		}


		close := expect_token(p, .Close_Bracket)

		bst := ast.new(ast.Bit_Set_Type, tok.pos, end_pos(close))
		bst.tok_pos = tok.pos
		bst.open = open.pos
		bst.elem = elem
		bst.underlying = underlying
		bst.close = close.pos
		return bst
		
	case .Matrix:
		tok := expect_token(p, .Matrix)
		expect_token(p, .Open_Bracket)
		row_count := parse_expr(p, false)
		expect_token(p, .Comma)
		column_count := parse_expr(p, false)
		expect_token(p, .Close_Bracket)
		elem := parse_type(p)

		mt := ast.new(ast.Matrix_Type, tok.pos, elem)
		mt.tok_pos = tok.pos
		mt.row_count = row_count
		mt.column_count = column_count
		mt.elem = elem
		return mt
	
	case .Bit_Field:
		tok := expect_token(p, .Bit_Field)

		backing_type := parse_type_or_ident(p)
		if backing_type == nil {
			token := advance_token(p)
			error(p, token.pos, "Expected a backing type for a 'bit_field'")
		}

		skip_possible_newline_for_literal(p)
		open := expect_token_after(p, .Open_Brace, "bit_field")

		fields: [dynamic]^ast.Bit_Field_Field
		for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
			name := parse_ident(p)
			expect_token(p, .Colon)
			type := parse_type(p)
			expect_token(p, .Or)
			bit_size := parse_expr(p, true)

			field := ast.new(ast.Bit_Field_Field, name.pos, bit_size)

			field.name     = name
			field.type     = type
			field.bit_size = bit_size

			append(&fields, field)

			allow_token(p, .Comma) or_break
		}

		close := expect_closing_brace_of_field_list(p)

		bf := ast.new(ast.Bit_Field_Type, tok.pos, close.pos)

		bf.tok_pos      = tok.pos
		bf.backing_type = backing_type
		bf.open         = open.pos
		bf.fields       = fields[:]
		bf.close        = close.pos
		return bf

	case .Asm:
		tok := expect_token(p, .Asm)

		param_types: [dynamic]^ast.Expr
		return_type: ^ast.Expr
		if allow_token(p, .Open_Paren) {
			for p.curr_tok.kind != .Close_Paren && p.curr_tok.kind != .EOF {
				t := parse_type(p)
				append(&param_types, t)
				if p.curr_tok.kind != .Comma ||
				   p.curr_tok.kind == .EOF {
					break
				}
				advance_token(p)
			}
			expect_token(p, .Close_Paren)

			if allow_token(p, .Arrow_Right) {
				return_type = parse_type(p)
			}
		}

		has_side_effects := false
		is_align_stack := false
		dialect := ast.Inline_Asm_Dialect.Default
		for allow_token(p, .Hash) {
			if p.curr_tok.kind == .Ident {
				name := advance_token(p)
				switch name.text {
				case "side_effects":
					if has_side_effects {
						error(p, tok.pos, "duplicate directive on inline asm expression: '#side_effects'")
					}
					has_side_effects = true
				case "align_stack":
					if is_align_stack {
						error(p, tok.pos, "duplicate directive on inline asm expression: '#align_stack'")
					}
					is_align_stack = true
				case "att":
					if dialect == .ATT {
						error(p, tok.pos, "duplicate directive on inline asm expression: '#att'")
					} else if dialect != .Default {
						error(p, tok.pos, "conflicting asm dialects")
					} else {
						dialect = .ATT
					}
				case "intel":
					if dialect == .Intel {
						error(p, tok.pos, "duplicate directive on inline asm expression: '#intel'")
					} else if dialect != .Default {
						error(p, tok.pos, "conflicting asm dialects")
					} else {
						dialect = .Intel
					}
				}

			} else {
				error(p, p.curr_tok.pos, "expected an identifier after hash")
			}
		}

		skip_possible_newline_for_literal(p)
		open := expect_token(p, .Open_Brace)
		asm_string := parse_expr(p, false)
		expect_token(p, .Comma)
		constraints_string := parse_expr(p, false)
		allow_token(p, .Comma)
		close := expect_closing_brace_of_field_list(p)

		e := ast.new(ast.Inline_Asm_Expr, tok.pos, end_pos(close))
		e.tok                = tok
		e.param_types        = param_types[:]
		e.return_type        = return_type
		e.constraints_string = constraints_string
		e.has_side_effects   = has_side_effects
		e.is_align_stack     = is_align_stack
		e.dialect            = dialect
		e.open               = open.pos
		e.asm_string         = asm_string
		e.close              = close.pos

		return e

	}

	return nil
}

is_literal_type :: proc(expr: ^ast.Expr) -> bool {
	val := ast.unparen_expr(expr)
	if val == nil {
		return false
	}
	#partial switch _ in val.derived_expr {
	case ^ast.Bad_Expr,
		^ast.Ident,
		^ast.Selector_Expr,
		^ast.Array_Type,
		^ast.Struct_Type,
		^ast.Union_Type,
		^ast.Enum_Type,
		^ast.Dynamic_Array_Type,
		^ast.Map_Type,
		^ast.Bit_Set_Type,
		^ast.Matrix_Type,
		^ast.Call_Expr,
		^ast.Bit_Field_Type:
		return true
	}
	return false
}

parse_value :: proc(p: ^Parser) -> ^ast.Expr {
	if p.curr_tok.kind == .Open_Brace {
		return parse_literal_value(p, nil)
	}
	prev_allow_range := p.allow_range
	defer p.allow_range = prev_allow_range
	p.allow_range = true
	return parse_expr(p, false)
}

parse_elem_list :: proc(p: ^Parser) -> []^ast.Expr {
	elems: [dynamic]^ast.Expr

	for p.curr_tok.kind != .Close_Brace && p.curr_tok.kind != .EOF {
		elem := parse_value(p)
		if p.curr_tok.kind == .Eq {
			eq := expect_token(p, .Eq)
			value := parse_value(p)

			fv := ast.new(ast.Field_Value, elem.pos, value)
			fv.field = elem
			fv.sep   = eq.pos
			fv.value = value

			elem = fv
		}

		append(&elems, elem)

		allow_token(p, .Comma) or_break
	}

	return elems[:]
}

parse_literal_value :: proc(p: ^Parser, type: ^ast.Expr) -> ^ast.Comp_Lit {
	elems: []^ast.Expr
	open := expect_token(p, .Open_Brace)
	p.expr_level += 1
	if p.curr_tok.kind != .Close_Brace {
		elems = parse_elem_list(p)
	}
	p.expr_level -= 1

  	skip_possible_newline(p)
	close := expect_closing_brace_of_field_list(p)

	pos := type.pos if type != nil else open.pos
	lit := ast.new(ast.Comp_Lit, pos, end_pos(close))
	lit.type  = type
	lit.open  = open.pos
	lit.elems = elems
	lit.close = close.pos
	return lit
}

parse_call_expr :: proc(p: ^Parser, operand: ^ast.Expr) -> ^ast.Expr {
	args: [dynamic]^ast.Expr

	ellipsis: tokenizer.Token

	p.expr_level += 1
	open := expect_token(p, .Open_Paren)

	seen_ellipsis := false
	for p.curr_tok.kind != .Close_Paren &&
		p.curr_tok.kind != .EOF {

		if p.curr_tok.kind == .Comma {
			error(p, p.curr_tok.pos, "expected an expression not ,")
		} else if p.curr_tok.kind == .Eq {
			error(p, p.curr_tok.pos, "expected an expression not =")
		}

		prefix_ellipsis := false
		if p.curr_tok.kind == .Ellipsis {
			prefix_ellipsis = true
			ellipsis = expect_token(p, .Ellipsis)
		}

		arg := parse_expr(p, false)
		if p.curr_tok.kind == .Eq {
			eq := expect_token(p, .Eq)

			if prefix_ellipsis {
				error(p, ellipsis.pos, "'..' must be applied to value rather than a field name")
			}

			value := parse_value(p)
			fv := ast.new(ast.Field_Value, arg.pos, value)
			fv.field = arg
			fv.sep   = eq.pos
			fv.value = value

			arg = fv
		} else if seen_ellipsis {
			error(p, arg.pos, "Positional arguments are not allowed after '..'")
		}

		append(&args, arg)

		if ellipsis.pos.line != 0 {
			seen_ellipsis = true
		}

		allow_token(p, .Comma) or_break
	}

	close := expect_closing_token_of_field_list(p, .Close_Paren, "argument list")
	p.expr_level -= 1

	ce := ast.new(ast.Call_Expr, operand.pos, end_pos(close))
	ce.expr     = operand
	ce.open     = open.pos
	ce.args     = args[:]
	ce.ellipsis = ellipsis
	ce.close    = close.pos

	o := ast.unparen_expr(operand)
	if se, ok := o.derived.(^ast.Selector_Expr); ok && se.op.kind == .Arrow_Right {
		sce := ast.new(ast.Selector_Call_Expr, ce.pos, ce)
		sce.expr = o
		sce.call = ce
		return sce
	}

	return ce
}


parse_atom_expr :: proc(p: ^Parser, value: ^ast.Expr, lhs: bool) -> (operand: ^ast.Expr) {
	operand = value
	if operand == nil {
		if p.allow_type {
			return nil
		}
		error(p, p.curr_tok.pos, "expected an operand")
		fix_advance_to_next_stmt(p)
		be := ast.new(ast.Bad_Expr, p.curr_tok.pos, end_pos(p.curr_tok))
		operand = be
	}

	loop := true
	is_lhs := lhs
	for loop {
		#partial switch p.curr_tok.kind {
		case:
			loop = false

		case .Open_Paren:
			operand = parse_call_expr(p, operand)

		case .Open_Bracket:
			prev_allow_range := p.allow_range
			defer p.allow_range = prev_allow_range
			p.allow_range = false

			indices: [2]^ast.Expr
			interval: tokenizer.Token
			is_slice_op := false

			p.expr_level += 1
			open := expect_token(p, .Open_Bracket)

			#partial switch p.curr_tok.kind {
			case .Colon, .Ellipsis, .Range_Half, .Range_Full:
				// NOTE(bill): Do not err yet
				break
			case:
				indices[0] = parse_expr(p, false)
			}

			#partial switch p.curr_tok.kind {
			case .Ellipsis, .Range_Half, .Range_Full:
				error(p, p.curr_tok.pos, "expected a colon, not a range")
				fallthrough
			case .Colon, .Comma/*matrix index*/:
				interval = advance_token(p)
				is_slice_op = true
				if p.curr_tok.kind != .Close_Bracket && p.curr_tok.kind != .EOF {
					indices[1] = parse_expr(p, false)
				}
			}

			close := expect_token(p, .Close_Bracket)
			p.expr_level -= 1

			if is_slice_op {
				if interval.kind == .Comma {
					if indices[0] == nil || indices[1] == nil {
						error(p, p.curr_tok.pos, "matrix index expressions require both row and column indices")
					}
					se := ast.new(ast.Matrix_Index_Expr, operand.pos, end_pos(close))
					se.expr = operand
					se.open = open.pos
					se.row_index = indices[0]
					se.column_index = indices[1]
					se.close = close.pos

					operand = se
				} else {
					se := ast.new(ast.Slice_Expr, operand.pos, end_pos(close))
					se.expr = operand
					se.open = open.pos
					se.low = indices[0]
					se.interval = interval
					se.high = indices[1]
					se.close = close.pos

					operand = se
				}
			} else {
				ie := ast.new(ast.Index_Expr, operand.pos, end_pos(close))
				ie.expr = operand
				ie.open = open.pos
				ie.index = indices[0]
				ie.close = close.pos

				operand = ie
			}


		case .Period:
			tok := expect_token(p, .Period)
			#partial switch p.curr_tok.kind {
			case .Ident:
				field := parse_ident(p)

				sel := ast.new(ast.Selector_Expr, operand.pos, field)
				sel.expr  = operand
				sel.op = tok
				sel.field = field

				operand = sel

			case .Open_Paren:
				open := expect_token(p, .Open_Paren)
				type := parse_type(p)
				close := expect_token(p, .Close_Paren)

				ta := ast.new(ast.Type_Assertion, operand.pos, end_pos(close))
				ta.expr  = operand
				ta.open  = open.pos
				ta.type  = type
				ta.close = close.pos

				operand = ta

			case .Question:
				question := expect_token(p, .Question)
				type := ast.new(ast.Unary_Expr, question.pos, end_pos(question))
				type.op = question
				type.expr = nil

				ta := ast.new(ast.Type_Assertion, operand.pos, type)
				ta.expr  = operand
				ta.type  = type

				operand = ta

			case:
				error(p, p.curr_tok.pos, "expected a selector")
				advance_token(p)
				operand = ast.new(ast.Bad_Expr, operand.pos, end_pos(tok))
			}

		case .Arrow_Right:
			tok := expect_token(p, .Arrow_Right)
			#partial switch p.curr_tok.kind {
			case .Ident:
				field := parse_ident(p)

				sel := ast.new(ast.Selector_Expr, operand.pos, field)
				sel.expr  = operand
				sel.op = tok
				sel.field = field

				operand = sel
			case:
				error(p, p.curr_tok.pos, "expected a selector")
				advance_token(p)
				operand = ast.new(ast.Bad_Expr, operand.pos, end_pos(tok))
			}

		case .Pointer:
			op := expect_token(p, .Pointer)
			deref := ast.new(ast.Deref_Expr, operand.pos, end_pos(op))
			deref.expr = operand
			deref.op   = op

			operand = deref

		case .Or_Return:
			token := expect_token(p, .Or_Return)
			oe := ast.new(ast.Or_Return_Expr, operand.pos, end_pos(token))
			oe.expr  = operand
			oe.token = token

			operand = oe

		case .Or_Break, .Or_Continue:
			token := advance_token(p)
			label: ^ast.Ident

			end := end_pos(token)
			if p.curr_tok.kind == .Ident {
				end = end_pos(p.curr_tok)
				label = parse_ident(p)
			}

			oe := ast.new(ast.Or_Branch_Expr, operand.pos, end)
			oe.expr  = operand
			oe.token = token
			oe.label = label

			operand = oe

		case .Open_Brace:
			if !is_lhs && is_literal_type(operand) && p.expr_level >= 0 {
				operand = parse_literal_value(p, operand)
			} else {
				loop = false
			}

		case .Increment, .Decrement:
			if !lhs {
				tok := advance_token(p)
				error(p, tok.pos, "postfix '%s' operator is not supported", tok.text)
			} else {
				loop = false
			}
		}

		is_lhs = false
	}

	return operand

}

parse_expr :: proc(p: ^Parser, lhs: bool) -> ^ast.Expr {
	return parse_binary_expr(p, lhs, 0+1)
}
parse_unary_expr :: proc(p: ^Parser, lhs: bool) -> ^ast.Expr {
	#partial switch p.curr_tok.kind {
	case .Transmute, .Cast:
		tok := advance_token(p)
		open := expect_token(p, .Open_Paren)
		type := parse_type(p)
		close := expect_token(p, .Close_Paren)
		expr := parse_unary_expr(p, lhs)

		tc := ast.new(ast.Type_Cast, tok.pos, expr)
		tc.tok   = tok
		tc.open  = open.pos
		tc.type  = type
		tc.close = close.pos
		tc.expr  = expr
		return tc

	case .Auto_Cast:
		op := advance_token(p)
		expr := parse_unary_expr(p, lhs)

		ac := ast.new(ast.Auto_Cast, op.pos, expr)
		ac.op   = op
		ac.expr = expr
		return ac

	case .Add, .Sub,
	     .Not, .Xor,
	     .And:
		op := advance_token(p)
		expr := parse_unary_expr(p, lhs)
		
		ue := ast.new(ast.Unary_Expr, op.pos, expr)
		ue.op   = op
		ue.expr = expr
		return ue

	case .Increment, .Decrement:
		op := advance_token(p)
		error(p, op.pos, "unary '%s' operator is not supported", op.text)
		expr := parse_unary_expr(p, lhs)

		ue := ast.new(ast.Unary_Expr, op.pos, expr)
		ue.op   = op
		ue.expr = expr
		return ue

	case .Period:
		op := advance_token(p)
		field := parse_ident(p)
		ise := ast.new(ast.Implicit_Selector_Expr, op.pos, field)
		ise.field = field
		return ise

	}
	return parse_atom_expr(p, parse_operand(p, lhs), lhs)
}
parse_binary_expr :: proc(p: ^Parser, lhs: bool, prec_in: int) -> ^ast.Expr {
	start_pos := p.curr_tok.pos
	expr := parse_unary_expr(p, lhs)

	if expr == nil {
		return ast.new(ast.Bad_Expr, start_pos, end_pos(p.prev_tok))
	}

	for prec := token_precedence(p, p.curr_tok.kind); prec >= prec_in; prec -= 1 {
		loop: for {
			op := p.curr_tok
			op_prec := token_precedence(p, op.kind)
			if op_prec != prec {
				break loop
			}

			#partial switch op.kind {
			case .If, .When:
				if p.prev_tok.pos.line < op.pos.line {
					// NOTE(bill): Check to see if the `if` or `when` is on the same line of the `lhs` condition
					break loop
				}
			}

			expect_operator(p)

			#partial switch op.kind {
			case .Question:

				cond := expr
				x := parse_expr(p, lhs)
				colon := expect_token(p, .Colon)
				y := parse_expr(p, lhs)
				te := ast.new(ast.Ternary_If_Expr, expr.pos, end_pos(p.prev_tok))
				te.cond = cond
				te.op1  = op
				te.x    = x
				te.op2  = colon
				te.y    = y

				expr = te
			case .If:
				x := expr
				cond := parse_expr(p, lhs)
				else_tok := expect_token(p, .Else)
				y := parse_expr(p, lhs)
				te := ast.new(ast.Ternary_If_Expr, expr.pos, end_pos(p.prev_tok))
				te.x    = x
				te.op1  = op
				te.cond = cond
				te.op2  = else_tok
				te.y    = y

				expr = te
			case .When:
				x := expr
				cond := parse_expr(p, lhs)
				else_tok := expect_token(p, .Else)
				y := parse_expr(p, lhs)
				te := ast.new(ast.Ternary_When_Expr, expr.pos, end_pos(p.prev_tok))
				te.x    = x
				te.op1  = op
				te.cond = cond
				te.op2  = else_tok
				te.y    = y

				expr = te
			case .Or_Else:
				x := expr
				y := parse_expr(p, lhs)
				oe := ast.new(ast.Or_Else_Expr, expr.pos, end_pos(p.prev_tok))
				oe.x     = x
				oe.token = op
				oe.y     = y

				expr = oe

			case:
				right := parse_binary_expr(p, false, prec+1)
				if right == nil {
					error(p, op.pos, "expected expression on the right-hand side of the binary operator")
				}
				be := ast.new(ast.Binary_Expr, expr.pos, end_pos(p.prev_tok))
				be.left  = expr
				be.op    = op
				be.right = right

				expr = be
			}
		}
	}

	return expr
}


parse_expr_list :: proc(p: ^Parser, lhs: bool) -> ([]^ast.Expr) {
	list: [dynamic]^ast.Expr
	for {
		expr := parse_expr(p, lhs)
		append(&list, expr)
		if p.curr_tok.kind != .Comma || p.curr_tok.kind == .EOF {
			break
		}
		advance_token(p)
	}

	return list[:]
}
parse_lhs_expr_list :: proc(p: ^Parser) -> []^ast.Expr {
	return parse_expr_list(p, true)
}
parse_rhs_expr_list :: proc(p: ^Parser) -> []^ast.Expr {
	return parse_expr_list(p, false)
}

parse_simple_stmt :: proc(p: ^Parser, flags: Stmt_Allow_Flags) -> ^ast.Stmt {
	start_tok := p.curr_tok
	docs := p.lead_comment

	lhs := parse_lhs_expr_list(p)
	op := p.curr_tok
	switch {
	case tokenizer.is_assignment_operator(op.kind):
		// if p.curr_proc == nil {
		// 	error(p, p.curr_tok.pos, "simple statements are not allowed at the file scope");
		// 	return ast.new(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok));
		// }
		advance_token(p)
		rhs := parse_rhs_expr_list(p)
		if len(rhs) == 0 {
			error(p, p.curr_tok.pos, "no right-hand side in assignment statement")
			return ast.new(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok))
		}
		stmt := ast.new(ast.Assign_Stmt, lhs[0].pos, rhs[len(rhs)-1])
		stmt.lhs = lhs
		stmt.op = op
		stmt.rhs = rhs
		return stmt

	case op.kind == .In:
		if .In in flags {
			allow_token(p, .In)
			prev_allow_range := p.allow_range
			p.allow_range = true
			expr := parse_expr(p, false)
			p.allow_range = prev_allow_range

			rhs := make([]^ast.Expr, 1)
			rhs[0] = expr

			stmt := ast.new(ast.Assign_Stmt, lhs[0].pos, rhs[len(rhs)-1])
			stmt.lhs = lhs
			stmt.op = op
			stmt.rhs = rhs
			return stmt
		}
	case op.kind == .Colon:
		expect_token_after(p, .Colon, "identifier list")
		if .Label in flags && len(lhs) == 1 {
			#partial switch p.curr_tok.kind {
			case .Open_Brace, .If, .For, .Switch:
				label := lhs[0]
				stmt := parse_stmt(p)

				if stmt != nil {
					#partial switch n in stmt.derived_stmt {
					case ^ast.Block_Stmt:       n.label = label
					case ^ast.If_Stmt:          n.label = label
					case ^ast.For_Stmt:         n.label = label
					case ^ast.Switch_Stmt:      n.label = label
					case ^ast.Type_Switch_Stmt: n.label = label
					case ^ast.Range_Stmt:	    n.label = label
					}
				}

				return stmt
			}
		}
		return parse_value_decl(p, lhs, docs)
	}

	if len(lhs) > 1 {
		error(p, op.pos, "expected 1 expression, got %d", len(lhs))
		return ast.new(ast.Bad_Stmt, start_tok.pos, end_pos(p.curr_tok))
	}

	#partial switch op.kind {
	case .Increment, .Decrement:
		advance_token(p)
		error(p, op.pos, "postfix '%s' statement is not supported", op.text)
	}

	es := ast.new(ast.Expr_Stmt, lhs[0].pos, lhs[0])
	es.expr = lhs[0]
	return es
}

parse_value_decl :: proc(p: ^Parser, names: []^ast.Expr, docs: ^ast.Comment_Group) -> ^ast.Decl {
	is_mutable := true

	values: []^ast.Expr
	type := parse_type_or_ident(p)

	#partial switch p.curr_tok.kind {
	case .Eq, .Colon:
		sep := advance_token(p)
		is_mutable = sep.kind != .Colon

		values = parse_rhs_expr_list(p)
		if len(values) > len(names) {
			error(p, p.curr_tok.pos, "too many values on the right-hand side of the declaration")
		} else if len(values) < len(names) && !is_mutable {
			error(p, p.curr_tok.pos, "all constant declarations must be defined")
		} else if len(values) == 0 {
			error(p, p.curr_tok.pos, "expected an expression for this declaration")
		}
	}

	if is_mutable {
		if type == nil && len(values) == 0 {
			error(p, p.curr_tok.pos, "missing variable type or initialization")
			return ast.new(ast.Bad_Decl, names[0].pos, end_pos(p.curr_tok))
		}
	} else {
		if type == nil && len(values) == 0 && len(names) > 0 {
			error(p, p.curr_tok.pos, "missing constant value")
			return ast.new(ast.Bad_Decl, names[0].pos, end_pos(p.curr_tok))
		}
	}

	if p.expr_level >= 0 {
		end: ^ast.Expr
		if !is_mutable && len(values) > 0 {
			end = values[len(values)-1]
		}
		if p.curr_tok.kind == .Close_Brace &&
		   p.curr_tok.pos.line == p.prev_tok.pos.line {

		} else {
			expect_semicolon(p, end)
		}
	}

	if p.curr_proc == nil {
		if len(values) > 0 && len(names) != len(values) {
			error(p, values[0].pos, "expected %d expressions on the right-hand side, got %d", len(names), len(values))
		}
	}

	decl := ast.new(ast.Value_Decl, names[0].pos, end_pos(p.prev_tok))
	decl.docs = docs
	decl.names = names
	decl.type = type
	decl.values = values
	decl.is_mutable = is_mutable
	return decl
}


parse_import_decl :: proc(p: ^Parser, kind := Import_Decl_Kind.Standard) -> ^ast.Import_Decl {
	docs := p.lead_comment
	tok := expect_token(p, .Import)

	import_name: tokenizer.Token
	is_using := kind != Import_Decl_Kind.Standard

	#partial switch p.curr_tok.kind {
	case .Ident:
		import_name = advance_token(p)
	case:
		import_name.pos = p.curr_tok.pos
	}

	if !is_using && is_blank_ident(import_name) {
		error(p, import_name.pos, "illegal import name: '_'")
	}

	path := expect_token_after(p, .String, "import")

	decl := ast.new(ast.Import_Decl, tok.pos, end_pos(path))
	decl.docs       = docs
	decl.is_using   = is_using
	decl.import_tok = tok
	decl.name       = import_name
	decl.relpath    = path
	decl.fullpath   = path.text

	if p.curr_proc != nil {
		error(p, decl.pos, "import declarations cannot be used within a procedure, it must be done at the file scope")
	} else {
		append(&p.file.imports, decl)
	}
	expect_semicolon(p, decl)
	decl.comment = p.line_comment

	return decl
}
