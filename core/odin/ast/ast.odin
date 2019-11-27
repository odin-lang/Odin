package odin_ast

import "core:odin/tokenizer"

Proc_Tag :: enum {
	Bounds_Check,
	No_Bounds_Check,
}
Proc_Tags :: distinct bit_set[Proc_Tag; u32];

Proc_Inlining :: enum u32 {
	None      = 0,
	Inline    = 1,
	No_Inline = 2,
}

Proc_Calling_Convention :: enum i32 {
	Invalid = 0,
	Odin,
	Contextless,
	C_Decl,
	Std_Call,
	Fast_Call,

	Foreign_Block_Default = -1,
}

Node_State_Flag :: enum {
	Bounds_Check,
	No_Bounds_Check,
}
Node_State_Flags :: distinct bit_set[Node_State_Flag];


Comment_Group :: struct {
	list: []tokenizer.Token,
}

Node :: struct {
	pos:         tokenizer.Pos,
	end:         tokenizer.Pos,
	derived:     any,
	state_flags: Node_State_Flags,
}


Expr :: struct {
	using expr_base: Node,
}
Stmt :: struct {
	using stmt_base: Node,
}
Decl :: struct {
	using decl_base: Stmt,
}

// Expressions

Bad_Expr :: struct {
	using node: Expr,
}

Ident :: struct {
	using node: Expr,
	name: string,
}

Implicit :: struct {
	using node: Expr,
	tok: tokenizer.Token,
}


Undef :: struct {
	using node: Expr,
	tok:  tokenizer.Token_Kind,
}

Basic_Lit :: struct {
	using node: Expr,
	tok: tokenizer.Token,
}

Basic_Directive :: struct {
	using node: Expr,
	tok:  tokenizer.Token,
	name: string,
}

Ellipsis :: struct {
	using node: Expr,
	tok:  tokenizer.Token_Kind,
	expr: ^Expr,
}

Proc_Lit :: struct {
	using node: Expr,
	type: ^Proc_Type,
	body: ^Stmt,
	tags: Proc_Tags,
	inlining: Proc_Inlining,
	where_token: tokenizer.Token,
	where_clauses: []^Expr,
}

Comp_Lit :: struct {
	using node: Expr,
	type: ^Expr,
	open: tokenizer.Pos,
	elems: []^Expr,
	close: tokenizer.Pos,
}


Tag_Expr :: struct {
	using node: Expr,
	op:      tokenizer.Token,
	name:    string,
	expr:    ^Expr,
}

Unary_Expr :: struct {
	using node: Expr,
	op:   tokenizer.Token,
	expr: ^Expr,
}

Binary_Expr :: struct {
	using node: Expr,
	left:  ^Expr,
	op:    tokenizer.Token,
	right: ^Expr,
}

Paren_Expr :: struct {
	using node: Expr,
	open:  tokenizer.Pos,
	expr:  ^Expr,
	close: tokenizer.Pos,
}

Selector_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	field: ^Ident,
}

Implicit_Selector_Expr :: struct {
	using node: Expr,
	field: ^Ident,
}

Index_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	open:  tokenizer.Pos,
	index: ^Expr,
	close: tokenizer.Pos,
}

Deref_Expr :: struct {
	using node: Expr,
	expr: ^Expr,
	op:   tokenizer.Token,
}

Slice_Expr :: struct {
	using node: Expr,
	expr:     ^Expr,
	open:     tokenizer.Pos,
	low:      ^Expr,
	interval: tokenizer.Token,
	high:     ^Expr,
	close:    tokenizer.Pos,
}

Call_Expr :: struct {
	using node: Expr,
	inlining: Proc_Inlining,
	expr:     ^Expr,
	open:     tokenizer.Pos,
	args:     []^Expr,
	ellipsis: tokenizer.Token,
	close:    tokenizer.Pos,
}

Field_Value :: struct {
	using node: Expr,
	field: ^Expr,
	sep:   tokenizer.Pos,
	value: ^Expr,
}

Ternary_Expr :: struct {
	using node: Expr,
	cond: ^Expr,
	op1:  tokenizer.Token,
	x:    ^Expr,
	op2:  tokenizer.Token,
	y:    ^Expr,
}

Type_Assertion :: struct {
	using node: Expr,
	expr:  ^Expr,
	dot:   tokenizer.Pos,
	open:  tokenizer.Pos,
	type:  ^Expr,
	close: tokenizer.Pos,
}

Type_Cast :: struct {
	using node: Expr,
	tok:   tokenizer.Token,
	open:  tokenizer.Pos,
	type:  ^Expr,
	close: tokenizer.Pos,
	expr:  ^Expr,
}

Auto_Cast :: struct {
	using node: Expr,
	op:   tokenizer.Token,
	expr: ^Expr,
}




// Statements

Bad_Stmt :: struct {
	using node: Stmt,
}

Empty_Stmt :: struct {
	using node: Stmt,
	semicolon: tokenizer.Pos, // Position of the following ';'
}

Expr_Stmt :: struct {
	using node: Stmt,
	expr: ^Expr,
}

Tag_Stmt :: struct {
	using node: Stmt,
	op:      tokenizer.Token,
	name:    string,
	stmt:    ^Stmt,
}

Assign_Stmt :: struct {
	using node: Stmt,
	lhs:    []^Expr,
	op:     tokenizer.Token,
	rhs:    []^Expr,
}


Block_Stmt :: struct {
	using node: Stmt,
	label: ^Expr,
	open:  tokenizer.Pos,
	stmts: []^Stmt,
	close: tokenizer.Pos,
}

If_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	if_pos:    tokenizer.Pos,
	init:      ^Stmt,
	cond:      ^Expr,
	body:      ^Stmt,
	else_stmt: ^Stmt,
}

When_Stmt :: struct {
	using node: Stmt,
	when_pos:  tokenizer.Pos,
	cond:      ^Expr,
	body:      ^Stmt,
	else_stmt: ^Stmt,
}

Return_Stmt :: struct {
	using node: Stmt,
	results: []^Expr,
}

Defer_Stmt :: struct {
	using node: Stmt,
	stmt: ^Stmt,
}

For_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	for_pos:   tokenizer.Pos,
	init:      ^Stmt,
	cond:      ^Expr,
	post:      ^Stmt,
	body:      ^Stmt,
}

Range_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	for_pos:   tokenizer.Pos,
	val0:      ^Expr,
	val1:      ^Expr,
	in_pos:    tokenizer.Pos,
	expr:      ^Expr,
	body:      ^Stmt,
}


Case_Clause :: struct {
	using node: Stmt,
	case_pos:   tokenizer.Pos,
	list:       []^Expr,
	terminator: tokenizer.Token,
	body:       []^Stmt,
}

Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: tokenizer.Pos,
	init:       ^Stmt,
	cond:       ^Expr,
	body:       ^Stmt,
	complete:   bool,
}

Type_Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: tokenizer.Pos,
	tag:        ^Stmt,
	expr:       ^Expr,
	body:       ^Stmt,
	complete:   bool,
}

Branch_Stmt :: struct {
	using node: Stmt,
	tok:   tokenizer.Token,
	label: ^Ident,
}

Using_Stmt :: struct {
	using node: Stmt,
	list: []^Expr,
}


// Declarations

Bad_Decl :: struct {
	using node: Decl,
}

Value_Decl :: struct {
	using node: Decl,
	docs:       ^Comment_Group,
	attributes: [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	names:      []^Expr,
	type:       ^Expr,
	values:     []^Expr,
	comment:    ^Comment_Group,
	is_using:   bool,
	is_mutable: bool,
}

Package_Decl :: struct {
	using node: Decl,
	docs:    ^Comment_Group,
	token:   tokenizer.Token,
	name:    string,
	comment: ^Comment_Group,
}

Import_Decl :: struct {
	using node: Decl,
	docs:       ^Comment_Group,
	is_using:    bool,
	import_tok:  tokenizer.Token,
	name:        tokenizer.Token,
	relpath:     tokenizer.Token,
	fullpath:    string,
	comment:     ^Comment_Group,
}

Foreign_Block_Decl :: struct {
	using node: Decl,
	docs:            ^Comment_Group,
	attributes:      [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	tok:             tokenizer.Token,
	foreign_library: ^Expr,
	body:            ^Stmt,
}

Foreign_Import_Decl :: struct {
	using node: Decl,
	docs:            ^Comment_Group,
	foreign_tok:     tokenizer.Token,
	import_tok:      tokenizer.Token,
	name:            ^Ident,
	collection_name: string,
	fullpaths:       []string,
	attributes:      [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	comment:         ^Comment_Group,
}



// Other things
unparen_expr :: proc(expr: ^Expr) -> (val: ^Expr) {
	val = expr;
	if expr == nil {
		return;
	}
	for {
		e, ok := val.derived.(Paren_Expr);
		if !ok do break;
		val = e.expr;
	}
	return;
}

Field_Flag :: enum {
	Ellipsis,
	Using,
	No_Alias,
	C_Vararg,
	Auto_Cast,
	In,

	Results,
	Tags,
	Default_Parameters,
	Typeid_Token,
}

Field_Flags :: distinct bit_set[Field_Flag];

Field_Flags_Struct :: Field_Flags{
	.Using,
	.Tags,
};
Field_Flags_Record_Poly_Params :: Field_Flags{
	.Typeid_Token,
};
Field_Flags_Signature :: Field_Flags{
	.Ellipsis,
	.Using,
	.No_Alias,
	.C_Vararg,
	.Auto_Cast,
	.Default_Parameters,
};

Field_Flags_Signature_Params  :: Field_Flags_Signature | {Field_Flag.Typeid_Token};
Field_Flags_Signature_Results :: Field_Flags_Signature;


Proc_Group :: struct {
	using node: Expr,
	tok:   tokenizer.Token,
	open:  tokenizer.Pos,
	args:  []^Expr,
	close: tokenizer.Pos,
}

Attribute :: struct {
	using node: Node,
	tok:   tokenizer.Token_Kind,
	open:  tokenizer.Pos,
	elems: []^Expr,
	close: tokenizer.Pos,
}

Field :: struct {
	using node: Node,
	docs:          ^Comment_Group,
	names:         []^Expr, // Could be polymorphic
	type:          ^Expr,
	default_value: ^Expr,
	tag:           tokenizer.Token,
	flags:         Field_Flags,
	comment:       ^Comment_Group,
}

Field_List :: struct {
	using node: Node,
	open:  tokenizer.Pos,
	list:  []^Field,
	close: tokenizer.Pos,
}


// Types
Typeid_Type :: struct {
	using node: Expr,
	tok:            tokenizer.Token_Kind,
	specialization: ^Expr,
}

Helper_Type :: struct {
	using node: Expr,
	tok:  tokenizer.Token_Kind,
	type: ^Expr,
}

Distinct_Type :: struct {
	using node: Expr,
	tok:  tokenizer.Token_Kind,
	type: ^Expr,
}

Opaque_Type :: struct {
	using node: Expr,
	tok:  tokenizer.Token_Kind,
	type: ^Expr,
}

Poly_Type :: struct {
	using node: Expr,
	dollar:         tokenizer.Pos,
	type:           ^Ident,
	specialization: ^Expr,
}

Proc_Type :: struct {
	using node: Expr,
	tok:       tokenizer.Token,
	calling_convention: Proc_Calling_Convention,
	params:    ^Field_List,
	arrow:     tokenizer.Pos,
	results:   ^Field_List,
	tags:      Proc_Tags,
	generic:   bool,
	diverging: bool,
}

Pointer_Type :: struct {
	using node: Expr,
	pointer: tokenizer.Pos,
	elem:    ^Expr,
}

Array_Type :: struct {
	using node: Expr,
	open:  tokenizer.Pos,
	tag:   ^Expr,
	len:   ^Expr, // Ellipsis node for [?]T arrray types, nil for slice types
	close: tokenizer.Pos,
	elem:  ^Expr,
}

Dynamic_Array_Type :: struct {
	using node: Expr,
	tag:         ^Expr,
	open:        tokenizer.Pos,
	dynamic_pos: tokenizer.Pos,
	close:       tokenizer.Pos,
	elem:        ^Expr,
}

Struct_Type :: struct {
	using node: Expr,
	tok_pos:       tokenizer.Pos,
	poly_params:   ^Field_List,
	align:         ^Expr,
	fields:        ^Field_List,
	name_count:    int,
	where_token:   tokenizer.Token,
	where_clauses: []^Expr,
	is_packed:     bool,
	is_raw_union:  bool,
}

Union_Type :: struct {
	using node: Expr,
	tok_pos:     tokenizer.Pos,
	poly_params: ^Field_List,
	align:       ^Expr,
	variants:    []^Expr,
	where_token: tokenizer.Token,
	where_clauses: []^Expr,
}

Enum_Type :: struct {
	using node: Expr,
	tok_pos:  tokenizer.Pos,
	base_type: ^Expr,
	open:      tokenizer.Pos,
	fields:    []^Expr,
	close:     tokenizer.Pos,

	is_using:  bool,
}

Bit_Field_Type :: struct {
	using node: Expr,
	tok_pos: tokenizer.Pos,
	align:   ^Expr,
	open:    tokenizer.Pos,
	fields:  []^Field_Value, // Field_Value with ':' rather than '='
	close:   tokenizer.Pos,
}

Bit_Set_Type :: struct {
	using node: Expr,
	tok_pos:    tokenizer.Pos,
	open:       tokenizer.Pos,
	elem:       ^Expr,
	underlying: ^Expr,
	close:      tokenizer.Pos,
}

Map_Type :: struct {
	using node: Expr,
	tok_pos: tokenizer.Pos,
	key:     ^Expr,
	value:   ^Expr,
}
