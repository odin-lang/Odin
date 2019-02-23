package odin_ast

import "core:odin/token"

Proc_Tag :: enum {
	Bounds_Check,
	No_Bounds_Check,
	Require_Results,
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
	list: []token.Token,
}

Node :: struct {
	pos:         token.Pos,
	end:         token.Pos,
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
	tok: token.Token,
}


Undef :: struct {
	using node: Expr,
	tok:  token.Kind,
}

Basic_Lit :: struct {
	using node: Expr,
	tok: token.Token,
}

Basic_Directive :: struct {
	using node: Expr,
	tok:  token.Token,
	name: string,
}

Ellipsis :: struct {
	using node: Expr,
	tok:  token.Kind,
	expr: ^Expr,
}

Proc_Lit :: struct {
	using node: Expr,
	type: ^Proc_Type,
	body: ^Stmt,
	tags: Proc_Tags,
	inlining: Proc_Inlining,
}

Comp_Lit :: struct {
	using node: Expr,
	type: ^Expr,
	open: token.Pos,
	elems: []^Expr,
	close: token.Pos,
}


Tag_Expr :: struct {
	using node: Expr,
	op:      token.Token,
	name:    string,
	expr:    ^Expr,
}

Unary_Expr :: struct {
	using node: Expr,
	op:   token.Token,
	expr: ^Expr,
}

Binary_Expr :: struct {
	using node: Expr,
	left:  ^Expr,
	op:    token.Token,
	right: ^Expr,
}

Paren_Expr :: struct {
	using node: Expr,
	open:  token.Pos,
	expr:  ^Expr,
	close: token.Pos,
}

Selector_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	field: ^Ident,
}


Index_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	open:  token.Pos,
	index: ^Expr,
	close: token.Pos,
}

Deref_Expr :: struct {
	using node: Expr,
	expr: ^Expr,
	op:   token.Token,
}

Slice_Expr :: struct {
	using node: Expr,
	expr:     ^Expr,
	open:     token.Pos,
	low:      ^Expr,
	interval: token.Token,
	high:     ^Expr,
	close:    token.Pos,
}

Call_Expr :: struct {
	using node: Expr,
	inlining: Proc_Inlining,
	expr:     ^Expr,
	open:     token.Pos,
	args:     []^Expr,
	ellipsis: token.Token,
	close:    token.Pos,
}

Field_Value :: struct {
	using node: Expr,
	field: ^Expr,
	sep:   token.Pos,
	value: ^Expr,
}

Ternary_Expr :: struct {
	using node: Expr,
	cond: ^Expr,
	op1:  token.Token,
	x:    ^Expr,
	op2:  token.Token,
	y:    ^Expr,
}

Type_Assertion :: struct {
	using node: Expr,
	expr:  ^Expr,
	dot:   token.Pos,
	open:  token.Pos,
	type:  ^Expr,
	close: token.Pos,
}

Type_Cast :: struct {
	using node: Expr,
	tok:   token.Token,
	open:  token.Pos,
	type:  ^Expr,
	close: token.Pos,
	expr:  ^Expr,
}

Auto_Cast :: struct {
	using node: Expr,
	op:   token.Token,
	expr: ^Expr,
}




// Statements

Bad_Stmt :: struct {
	using node: Stmt,
}

Empty_Stmt :: struct {
	using node: Stmt,
	semicolon: token.Pos, // Position of the following ';'
}

Expr_Stmt :: struct {
	using node: Stmt,
	expr: ^Expr,
}

Tag_Stmt :: struct {
	using node: Stmt,
	op:      token.Token,
	name:    string,
	stmt:    ^Stmt,
}

Assign_Stmt :: struct {
	using node: Stmt,
	lhs:    []^Expr,
	op:     token.Token,
	rhs:    []^Expr,
}


Block_Stmt :: struct {
	using node: Stmt,
	label: ^Expr,
	open:  token.Pos,
	stmts: []^Stmt,
	close: token.Pos,
}

If_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	if_pos:    token.Pos,
	init:      ^Stmt,
	cond:      ^Expr,
	body:      ^Stmt,
	else_stmt: ^Stmt,
}

When_Stmt :: struct {
	using node: Stmt,
	when_pos:  token.Pos,
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
	for_pos:   token.Pos,
	init:      ^Stmt,
	cond:      ^Expr,
	post:      ^Stmt,
	body:      ^Stmt,
}

Range_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	for_pos:   token.Pos,
	val0:      ^Expr,
	val1:      ^Expr,
	in_pos:    token.Pos,
	expr:      ^Expr,
	body:      ^Stmt,
}


Case_Clause :: struct {
	using node: Stmt,
	case_pos:   token.Pos,
	list:       []^Expr,
	terminator: token.Token,
	body:       []^Stmt,
}

Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: token.Pos,
	init:       ^Stmt,
	cond:       ^Expr,
	body:       ^Stmt,
	complete:   bool,
}

Type_Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: token.Pos,
	tag:        ^Stmt,
	expr:       ^Expr,
	body:       ^Stmt,
	complete:   bool,
}

Branch_Stmt :: struct {
	using node: Stmt,
	tok:   token.Token,
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
	token:   token.Token,
	name:    string,
	comment: ^Comment_Group,
}

Import_Decl :: struct {
	using node: Decl,
	docs:       ^Comment_Group,
	is_using:    bool,
	import_tok:  token.Token,
	name:        token.Token,
	relpath:     token.Token,
	fullpath:    string,
	comment:     ^Comment_Group,
}

Foreign_Block_Decl :: struct {
	using node: Decl,
	docs:            ^Comment_Group,
	attributes:      [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	tok:             token.Token,
	foreign_library: ^Expr,
	body:            ^Stmt,
}

Foreign_Import_Decl :: struct {
	using node: Decl,
	docs:            ^Comment_Group,
	foreign_tok:     token.Token,
	import_tok:      token.Token,
	name:            ^Ident,
	collection_name: string,
	fullpaths:       []string,
	comment:         ^Comment_Group,
}



// Other things
unparen_expr :: proc(expr: ^Expr) -> ^Expr {
	if expr == nil {
		return nil;
	}
	for {
		e, ok := expr.derived.(Paren_Expr);
		if !ok do break;
		expr = e.expr;
	}
	return expr;
}

Field_Flag :: enum {
	Ellipsis,
	Using,
	No_Alias,
	C_Vararg,
	Auto_Cast,
	In,
	Results,
	Default_Parameters,
	Typeid_Token,
}

Field_Flags :: distinct bit_set[Field_Flag];

Field_Flags_Struct :: Field_Flags{
	Field_Flag.Using,
};
Field_Flags_Record_Poly_Params :: Field_Flags{
	Field_Flag.Typeid_Token,
};
Field_Flags_Signature :: Field_Flags{
	Field_Flag.Ellipsis,
	Field_Flag.Using,
	Field_Flag.No_Alias,
	Field_Flag.C_Vararg,
	Field_Flag.Auto_Cast,
	Field_Flag.Default_Parameters,
};

Field_Flags_Signature_Params  :: Field_Flags_Signature | {Field_Flag.Typeid_Token};
Field_Flags_Signature_Results :: Field_Flags_Signature;


Proc_Group :: struct {
	using node: Expr,
	tok:   token.Token,
	open:  token.Pos,
	args:  []^Expr,
	close: token.Pos,
}

Attribute :: struct {
	using node: Node,
	tok:   token.Kind,
	open:  token.Pos,
	elems: []^Expr,
	close: token.Pos,
}

Field :: struct {
	using node: Node,
	docs:          ^Comment_Group,
	names:         []^Expr, // Could be polymorphic
	type:          ^Expr,
	default_value: ^Expr,
	flags:         Field_Flags,
	comment:       ^Comment_Group,
}

Field_List :: struct {
	using node: Node,
	open:  token.Pos,
	list:  []^Field,
	close: token.Pos,
}


// Types
Typeid_Type :: struct {
	using node: Expr,
	tok:            token.Kind,
	specialization: ^Expr,
}

Helper_Type :: struct {
	using node: Expr,
	tok:  token.Kind,
	type: ^Expr,
}

Distinct_Type :: struct {
	using node: Expr,
	tok:  token.Kind,
	type: ^Expr,
}

Opaque_Type :: struct {
	using node: Expr,
	tok:  token.Kind,
	type: ^Expr,
}

Poly_Type :: struct {
	using node: Expr,
	dollar:         token.Pos,
	type:           ^Ident,
	specialization: ^Expr,
}

Proc_Type :: struct {
	using node: Expr,
	tok:       token.Token,
	calling_convention: Proc_Calling_Convention,
	params:    ^Field_List,
	arrow:     token.Pos,
	results:   ^Field_List,
	tags:      Proc_Tags,
	generic:   bool,
	diverging: bool,
}

Pointer_Type :: struct {
	using node: Expr,
	pointer: token.Pos,
	elem:    ^Expr,
}

Array_Type :: struct {
	using node: Expr,
	open:  token.Pos,
	len:   ^Expr, // Ellipsis node for [?]T arrray types, nil for slice types
	close: token.Pos,
	elem:  ^Expr,
}

Dynamic_Array_Type :: struct {
	using node: Expr,
	open:        token.Pos,
	dynamic_pos: token.Pos,
	close:       token.Pos,
	elem:        ^Expr,
}

Struct_Type :: struct {
	using node: Expr,
	tok_pos:   token.Pos,
	poly_params:  ^Field_List,
	align:        ^Expr,
	is_packed:    bool,
	is_raw_union: bool,
	fields:       ^Field_List,
	name_count:  int,
}

Union_Type :: struct {
	using node: Expr,
	tok_pos:     token.Pos,
	poly_params: ^Field_List,
	align:       ^Expr,
	variants:    []^Expr,
}

Enum_Type :: struct {
	using node: Expr,
	tok_pos:  token.Pos,
	base_type: ^Expr,
	open:      token.Pos,
	fields:    []^Expr,
	close:     token.Pos,

	is_using:  bool,
}

Bit_Field_Type :: struct {
	using node: Expr,
	tok_pos: token.Pos,
	align:   ^Expr,
	open:    token.Pos,
	fields:  []^Field_Value, // Field_Value with ':' rather than '='
	close:   token.Pos,
}

Bit_Set_Type :: struct {
	using node: Expr,
	tok_pos:    token.Pos,
	open:       token.Pos,
	elem:       ^Expr,
	underlying: ^Expr,
	close:      token.Pos,
}

Map_Type :: struct {
	using node: Expr,
	tok_pos: token.Pos,
	key:     ^Expr,
	value:   ^Expr,
}
