package text_template_parse

import "../scan"
import "core:strings"

Pos :: scan.Pos
Token :: scan.Token
Token_Kind :: scan.Token_Kind

new_node :: proc($T: typeid, pos: Pos = 0, allocator := context.allocator) -> ^T {
	n := new(T, allocator)
	n.pos = pos
	n.variant = n
	return n
}

Node :: struct {
	pos: Pos,
	variant: union{
		^Node_Text,
		^Node_Comment,
		^Node_Action,
		^Node_Pipeline,
		^Node_Chain,
		^Node_Command,
		^Node_Import,
		^Node_Dot,
		^Node_Field,
		^Node_Identifier,
		^Node_Operator,
		^Node_If,
		^Node_For,
		^Node_List,
		^Node_Nil,
		^Node_Bool,
		^Node_Number,
		^Node_String,
		^Node_Variable,
		^Node_With,
		^Node_Break,
		^Node_Continue,

		// Dummy nodes
		^Node_Else,
		^Node_End,
	},
}

Node_Branch :: struct{
	using base: Node,
	pipe: ^Node_Pipeline,
	list: ^Node_List,
	else_list: ^Node_List,
}

Node_Text :: struct{
	using base: Node,
	text: string,
}
Node_Action :: struct{
	using base: Node,
	pipe: ^Node_Pipeline,
}
Node_Bool :: struct{
	using base: Node,
	ok: bool,
}
Node_Chain :: struct{
	using base: Node,
	node: ^Node,
	fields: [dynamic]string,
}
Node_Command :: struct{
	using base: Node,
	args: [dynamic]^Node,
}
Node_Dot :: struct{
	using base: Node,
}
Node_Field :: struct{
	using base: Node,
	idents: []string,
}
Node_Identifier :: struct{
	using base: Node,
	ident: string,
}
Node_Operator :: struct{
	using base: Node,
	value: string,
}


Node_If   :: distinct Node_Branch
Node_For  :: distinct Node_Branch
Node_With :: distinct Node_Branch

Node_List :: struct{
	using base: Node,
	nodes: [dynamic]^Node,
}
Node_Nil :: struct{
	using base: Node,
}
Node_Number :: struct{
	using base: Node,
	text: string,
	i: Maybe(i64),
	u: Maybe(u64),
	f: Maybe(f64),
}
Node_Pipeline :: struct{
	using base: Node,
	is_assign: bool,
	decl: [dynamic]^Node_Variable,
	cmds: [dynamic]^Node_Command,
}
Node_String :: struct{
	using base: Node,
	quoted: string,
	text: string, // after processing
}
Node_Import :: struct{
	using base: Node,
	name: string, // unquoted
	pipe: ^Node_Pipeline,
}
Node_Variable :: struct{
	using base: Node,
	name: string,
}
Node_Comment :: struct{
	using base: Node,
	text: string,
}
Node_Break :: struct{
	using base: Node,
}
Node_Continue :: struct{
	using base: Node,
}

Node_Else :: struct {
	using base: Node,
}

Node_End :: struct {
	using base: Node,
}

chain_add :: proc(c: ^Node_Chain, field: string) {
	field := field
	if len(field) == 0 || field[0] != '.' {
		panic("not a .field")
	}
	field = field[1:]
	if field == "" {
		panic("empty field")
	}
	append(&c.fields, field)
}

