package text_template_parse

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:strconv"
import "../scan"

Error :: enum {
	None,

	Unexpected_Token,
	Unexpected_EOF,

	Expected_End,

	Invalid_Node,

	Invalid_Character,
	Invalid_Number,
	Invalid_String,

	Empty_Command,
	Missing_Value,
	Non_Executable_Command,
	Undefined_Variable,
	Unexpected_Operand,
	Invalid_For_Initialization,
	Too_Many_Declarations,
}
Tree :: struct {
	general_allocator: mem.Allocator,

	arena: virtual.Growing_Arena,
	name: string,

	tokens: []Token, // general_allocator

	root: ^Node_List,
	input: string,
	offset: uint,

	for_loop_depth: uint,

	vars: [dynamic]string,
}

@(require_results)
errorf :: proc(t: ^Tree, err: Error, format: string, args: ..any) -> Error {
	if err != nil {
		fmt.eprintf(format, ..args)
		fmt.eprintln()
	}
	return err
}

@(require_results)
unexpected_token :: proc(t: ^Tree, token: Token) -> Error {
	return errorf(t, .Unexpected_Token, "unexpected token: %s", token.value)
}


peek :: proc(t: ^Tree, n: uint = 0) -> Token {
	if t.offset+n < len(t.tokens) {
		return t.tokens[t.offset+n]
	}
	return Token{.EOF, "", Pos(len(t.input)), 0}
}
next :: proc(t: ^Tree) -> (token: Token) {
	if t.offset < len(t.tokens) {
		token = t.tokens[t.offset]
		t.offset += 1
		return
	}
	return Token{.EOF, "", Pos(len(t.input)), 0}
}
backup :: proc(t: ^Tree, n: uint = 1) {
	if n > t.offset {
		t.offset = 0
	} else {
		t.offset -= n
	}
}

next_non_space :: proc(t: ^Tree) -> (token: Token) {
	for {
		token = next(t)
		if token.kind != .Space {
			break
		}
	}
	return
}
peek_non_space :: proc(t: ^Tree, offset: uint = 0) -> (token: Token) {
	i := offset
	for {
		if t.offset+i < len(t.tokens) {
			token = t.tokens[t.offset+i]
		} else {
			token = Token{.EOF, "", Pos(len(t.input)), 0}
		}
		if token.kind != .Space {
			break
		}
		i += 1
	}
	return
}
peek_after_non_space :: proc(t: ^Tree) -> (token: Token) {
	return peek_non_space(t, 1)
}

expect :: proc(t: ^Tree, expected: Token_Kind, ctx: string) -> (token: Token, err: Error) {
	token = next_non_space(t)
	if token.kind != expected {
		err = errorf(t, .Unexpected_Token, "unexpected token, expected %s, got %s", expected, token.value)
	}
	return
}


parse :: proc(input: string, left_delim, right_delim: string, emit_comments: bool = false, general_allocator := context.allocator) -> (t: ^Tree, err: Error) {
	t = new(Tree, general_allocator)
	t.general_allocator = general_allocator
	t.vars.allocator = general_allocator
	t.input = input


	s := scan.init(&scan.Scanner{}, t.name, input, left_delim, right_delim, emit_comments)
	s.tokens.allocator = t.general_allocator
	scan.run(s)
	t.tokens = s.tokens[:] // general_allocator

	context.allocator = virtual.arena_allocator(&t.arena)

	t.root = new_node(Node_List)
	for peek(t).kind != .EOF {
		if peek(t).kind == .Left_Delim && peek_after_non_space(t).kind == .Declare {
			// TODO
			continue
		}
		node := text_or_action(t) or_return
		if node != nil {
			append(&t.root.nodes, node)
		} else {
			break
		}
	}

	return
}

destroy_tree :: proc(t: ^Tree) {
	if t != nil {
		virtual.arena_destroy(&t.arena)

		ga := t.general_allocator
		delete(t.tokens, ga)
		delete(t.vars)
		free(t, ga)
	}
}


text_or_action :: proc(t: ^Tree) -> (node: ^Node, err: Error) {
	#partial switch token := next_non_space(t); token.kind {
	case .Text:
		n := new_node(Node_Text, token.pos)
		n.text = token.value
		return n, nil
	case .Left_Delim:
		return action(t)
	case .Comment:
		n := new_node(Node_Comment, token.pos)
		n.text = token.value
		return n, nil
	case:
		return nil, unexpected_token(t, token)
	}
	return nil, nil
}

parse_list :: proc(t: ^Tree) -> (list: ^Node_List, next: ^Node, err: Error) {
	list = new_node(Node_List, peek_non_space(t).pos)
	for peek_non_space(t).kind != .EOF {
		node := text_or_action(t) or_return
		#partial switch n in node.variant {
		case ^Node_Else:
			next = n
			return
		case ^Node_End:
			next = n
			return
		}
		append(&list.nodes, node)
	}
	err = errorf(t, .Unexpected_EOF, "unexpected EOF")
	return
}

parse_control :: proc(t: ^Tree, allow_else_if: bool, ctx: string) -> (pipe: ^Node_Pipeline, list, else_list: ^Node_List, err: Error) {
	pipe = pipeline(t, ctx, .Right_Delim) or_return

	if ctx == "for" {
		t.for_loop_depth += 1
	}

	next_node: ^Node
	list, next_node = parse_list(t) or_return

	if ctx == "for" {
		t.for_loop_depth -= 1
	}

	#partial switch n in next_node.variant {
	case ^Node_End:
		// We are done

	case ^Node_Else:
		if allow_else_if && peek(t).kind == .If {
			// {{if a}}...{{else if b}}...{{end}}
			// is translated into
			// {{if a}}...{{else}}{{if b}}...{{end}}{{end}}
			next(t)
			else_list = new_node(Node_List, next_node.pos)
			append(&else_list.nodes, parse_if(t) or_return)
			break
		}
		else_list, next_node = parse_list(t) or_return
		if _, ok := next_node.variant.(^Node_End); !ok {
			errorf(t, .Expected_End, "expected end") or_return
		}
	}
	return
}

// {{if pipeline}} list {{end}}
// {{if pipeline}} list {{else}} list {{end}}
// {{if pipeline}} list {{else if pipeline}} list {{end}}
parse_if :: proc(t: ^Tree) -> (node: ^Node_If, err: Error) {
	pipe, list, else_list := parse_control(t, true, "if") or_return
	node = new_node(Node_If, pipe.pos)
	node.pipe = pipe
	node.list = list
	node.else_list = else_list
	return
}

// {{for pipeline}} list {{end}}
// {{for pipeline}} list {{else}} list {{end}}
parse_for :: proc(t: ^Tree) -> (node: ^Node_For, err: Error) {
	pipe, list, else_list := parse_control(t, false, "for") or_return
	node = new_node(Node_For, pipe.pos)
	node.pipe = pipe
	node.list = list
	node.else_list = else_list
	return
}

// {{with pipeline}} list {{end}}
// {{with pipeline}} list {{else}} list {{end}}
parse_with :: proc(t: ^Tree) -> (node: ^Node_With, err: Error) {
	pipe, list, else_list := parse_control(t, false, "with") or_return
	node = new_node(Node_With, pipe.pos)
	node.pipe = pipe
	node.list = list
	node.else_list = else_list
	return
}


// {{else}}
parse_else :: proc(t: ^Tree) -> (node: ^Node_Else, err: Error) {
	p := peek_non_space(t)
	if p.kind == .If {
		node = new_node(Node_Else, p.pos)
		return
	}
	token := expect(t, .Right_Delim, "else") or_return
	node = new_node(Node_Else, token.pos)
	return
}
// {{end}}
parse_end :: proc(t: ^Tree) -> (node: ^Node_End, err: Error) {
	token := expect(t, .Right_Delim, "end") or_return
	node = new_node(Node_End, token.pos)
	return
}




action :: proc(t: ^Tree) -> (^Node, Error) {
	// TODO actions
	#partial switch token := next_non_space(t); token.kind {
	case .If:   return parse_if(t)
	case .For:  return parse_for(t)
	case .With: return parse_with(t)
	case .Else: return parse_else(t)
	case .End:  return parse_end(t)

	case .Block:
		return nil, .Invalid_Node
	case .Break:
		return nil, .Invalid_Node
	case .Continue:
		return nil, .Invalid_Node
	case .Include:
		return nil, .Invalid_Node
	}
	backup(t)

	return pipeline(t, "command", .Right_Delim)
}


pipeline :: proc(t: ^Tree, ctx: string, end: Token_Kind) -> (pipe: ^Node_Pipeline, err: Error) {
	pipe = new_node(Node_Pipeline, peek_non_space(t).pos)

	decls: for v := peek_non_space(t); v.kind == .Variable; /**/ {
		next_non_space(t)

		token_after_variable := peek(t) // could be space
		next := peek_non_space(t)
		switch {
		case next.kind == .Assign, next.kind == .Declare:
			pipe.is_assign = next.kind == .Assign
			next_non_space(t)
			append(&t.vars, v.value)
			append(&pipe.decl, parse_variable(t, v) or_return)

		case next.kind == .Char && next.value == ",":
			next_non_space(t)
			append(&t.vars, v.value)
			append(&pipe.decl, parse_variable(t, v) or_return)
			if ctx == "for" && len(pipe.decl) < 2 {
				#partial switch peek_non_space(t).kind {
				case .Variable, .Right_Delim, .Right_Paren:
					v = peek_non_space(t)
					continue decls
				}
				errorf(t, .Invalid_For_Initialization, "for can only initialize variables") or_return
			}
			errorf(t, .Too_Many_Declarations, "too many declarations in %s", ctx) or_return

		case token_after_variable.kind == .Space:
			backup(t, 2)
		case:
			backup(t, 1)
		}

		break decls
	}

	for {
		#partial switch tok := next_non_space(t); tok.kind {
		case end:
			if len(pipe.cmds) == 0 {
				errorf(t, .Missing_Value, "missing value for %s", ctx) or_return
			}
			for c, i in pipe.cmds[1:] {
				#partial switch n in c.variant {
				case ^Node_Bool, ^Node_Dot, ^Node_Nil, ^Node_Number, ^Node_String:
					errorf(t, .Non_Executable_Command, "non executable command in pipeline stage for %d", i+2) or_return
				}
			}
			return
		case .Bool, .Char, .Dot, .Field, .Identifier, .Operator, .Number, .Nil, .Raw_String, .String, .Variable, .Left_Paren:
			backup(t)
			append(&pipe.cmds, command(t) or_return)
		case:
			err = unexpected_token(t, tok)
			return
		}
	}
}

command :: proc(t: ^Tree) -> (cmd: ^Node_Command, err: Error) {
	cmd = new_node(Node_Command, peek_non_space(t).pos)
	loop: for {
		op := operand(t) or_return
		if op != nil {
			append(&cmd.args, op)
		}
		#partial switch token := next(t); token.kind {
		case .Space:
			continue loop
		case .Right_Delim, .Right_Paren:
			backup(t)
		case .Pipe:
			break loop
		case:
			errorf(t, .Unexpected_Operand, "unexpected operand %s", token.value) or_return
		}
		break loop
	}
	if len(cmd.args) == 0 {
		err = errorf(t, .Empty_Command, "empty command")
	}
	return
}

operand :: proc(t: ^Tree) -> (node: ^Node, err: Error) {
	node = term(t) or_return
	if node == nil {
		return
	}
	if p := peek(t); p.kind == .Field {
		chain := new_node(Node_Chain, p.pos)
		chain.node = node
		for peek(t).kind == .Field {
			chain_add(chain, next(t).value)
		}

		#partial switch n in node.variant {
		case ^Node_Field:
			f := new_node(Node_Field, chain.pos)
			resize(&chain.fields, len(chain.fields)+len(n.idents))
			copy(chain.fields[len(n.idents):], chain.fields[:])
			copy(chain.fields[:], n.idents)
			f.idents = chain.fields[:]
			node = f
		case:
			node = chain
		}

	}
	return
}

// literal (number, string, nil, boolean)
// function (identifier)
// operator (function-like thing)
// .
// .field
// $
// $
// '(' pipeline ')'
term :: proc(t: ^Tree) -> (^Node, Error) {
	#partial switch token := next_non_space(t); token.kind {
	case .Identifier:
		n := new_node(Node_Identifier, token.pos)
		n.ident = token.value
		return n, nil
	case .Operator:
		n := new_node(Node_Operator, token.pos)
		n.value = token.value
		return n, nil
	case .Dot: return new_node(Node_Dot, token.pos), nil
	case .Nil: return new_node(Node_Nil, token.pos), nil
	case .Variable:
		return parse_variable(t, token)
	case .Field:
		f := new_node(Node_Field, token.pos)
		f.idents = make([]string, 1)
		f.idents[0] = token.value[1:]
		return f, nil
	case .Bool:
		b := new_node(Node_Bool, token.pos)
		b.ok = token.value == "true"
		return b, nil
	case .Char, .Number:
		return parse_number(t, token)
	case .String, .Raw_String:
		text, _, ok := strconv.unquote_string(token.value)
		if !ok {
			return nil, errorf(t, .Invalid_String, "invalid string literal: %s", token.value)
		}
		n := new_node(Node_String, token.pos)
		n.quoted = token.value
		n.text = text
		return n, nil
	case .Left_Paren:
		return pipeline(t, "parenthesized pipeline", .Right_Paren)
	}
	backup(t)
	return nil, nil
}


parse_number :: proc(t: ^Tree, token: Token) -> (^Node_Number, Error) {
	text := token.value
	n := new_node(Node_Number, token.pos)
	n.text = text
	if token.kind == .Char {
		r, _, tail, ok := strconv.unquote_char(text[:], text[0])
		if !ok || tail != "" {
			return nil, errorf(t, .Invalid_Character, "invalid character literal: %s", text)
		}
		n.i = i64(r)
		n.u = u64(r)
		n.f = f64(r)
		return n, nil
	}


	if u, ok := strconv.parse_u64(text); ok {
		n.u = u
	}
	if i, ok := strconv.parse_i64(text); ok {
		n.i = i
		if i == 0 {
			n.u = 0
		}
	}
	if n.u == nil && n.i == nil {
		if f, ok := strconv.parse_f64(text); ok {
			n.f = f
		}
	}
	if n.u == nil && n.i == nil && n.f == nil {
		return nil, errorf(t, .Invalid_Number, "invalid number syntax: %q", text)
	}
	return n, nil

}

parse_variable :: proc(t: ^Tree, token: Token) -> (^Node_Variable, Error) {
	v := new_node(Node_Variable, token.pos)
	v.name = token.value
	for var in t.vars {
		if var == v.name {
			return v, nil
		}
	}
	return nil, errorf(t, .Undefined_Variable, "undefined variable %q", v.name)
}