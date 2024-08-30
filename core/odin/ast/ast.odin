package odin_ast

import "core:odin/tokenizer"

Proc_Tag :: enum {
	Bounds_Check,
	No_Bounds_Check,
	Optional_Ok,
	Optional_Allocator_Error,
}
Proc_Tags :: distinct bit_set[Proc_Tag; u32]

Proc_Inlining :: enum u32 {
	None      = 0,
	Inline    = 1,
	No_Inline = 2,
}

Proc_Calling_Convention_Extra :: enum i32 {
	Foreign_Block_Default,
}
Proc_Calling_Convention :: union {
	string,
	Proc_Calling_Convention_Extra,
}

Node_State_Flag :: enum {
	Bounds_Check,
	No_Bounds_Check,
	Type_Assert,
	No_Type_Assert,
}
Node_State_Flags :: distinct bit_set[Node_State_Flag]

Node :: struct {
	pos:         tokenizer.Pos,
	end:         tokenizer.Pos,
	state_flags: Node_State_Flags,
	derived:     Any_Node,
}

Comment_Group :: struct {
	using node: Node,
	list: []tokenizer.Token,
}

Package_Kind :: enum {
	Normal,
	Runtime,
	Init,
}

Package :: struct {
	using node: Node,
	kind:     Package_Kind,
	id:       int,
	name:     string,
	fullpath: string,
	files:    map[string]^File,

	user_data: rawptr,
}

File :: struct {
	using node: Node,
	id: int,
	pkg: ^Package,

	fullpath: string,
	src:      string,

	docs: ^Comment_Group,

	pkg_decl:  ^Package_Decl,
	pkg_token: tokenizer.Token,
	pkg_name:  string,

	decls:   [dynamic]^Stmt,
	imports: [dynamic]^Import_Decl,
	directive_count: int,

	comments: [dynamic]^Comment_Group,

	syntax_warning_count: int,
	syntax_error_count:   int,
}


// Base Types

Expr :: struct {
	using expr_base: Node,
	derived_expr: Any_Expr,
}
Stmt :: struct {
	using stmt_base: Node,
	derived_stmt: Any_Stmt,
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
	tag: ^Expr,
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
	op:    tokenizer.Token,
	field: ^Ident,
}

Implicit_Selector_Expr :: struct {
	using node: Expr,
	field: ^Ident,
}

Selector_Call_Expr :: struct {
	using node: Expr,
	expr: ^Expr,
	call: ^Call_Expr,
	modified_call: bool,
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

Matrix_Index_Expr :: struct {
	using node: Expr,
	expr:         ^Expr,
	open:         tokenizer.Pos,
	row_index:    ^Expr,
	column_index: ^Expr,
	close:        tokenizer.Pos,
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

Ternary_If_Expr :: struct {
	using node: Expr,
	x:    ^Expr,
	op1:  tokenizer.Token,
	cond: ^Expr,
	op2:  tokenizer.Token,
	y:    ^Expr,
}

Ternary_When_Expr :: struct {
	using node: Expr,
	x:    ^Expr,
	op1:  tokenizer.Token,
	cond: ^Expr,
	op2:  tokenizer.Token,
	y:    ^Expr,
}

Or_Else_Expr :: struct {
	using node: Expr,
	x:     ^Expr,
	token: tokenizer.Token,
	y:     ^Expr,
}

Or_Return_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	token: tokenizer.Token,
}

Or_Branch_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	token: tokenizer.Token,
	label: ^Expr,
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

Inline_Asm_Dialect :: enum u8 {
	Default = 0,
	ATT     = 1,
	Intel   = 2,
}


Inline_Asm_Expr :: struct {
	using node: Expr,
	tok:                tokenizer.Token,
	param_types:        []^Expr,
	return_type:        ^Expr,
	has_side_effects:   bool,
	is_align_stack:     bool,
	dialect:            Inline_Asm_Dialect,
	open:               tokenizer.Pos,
	constraints_string: ^Expr,
	asm_string:         ^Expr,
	close:              tokenizer.Pos,
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
	uses_do: bool,
}

If_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	if_pos:    tokenizer.Pos,
	init:      ^Stmt,
	cond:      ^Expr,
	body:      ^Stmt,
	else_pos:  tokenizer.Pos,
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
	vals:      []^Expr,
	in_pos:    tokenizer.Pos,
	expr:      ^Expr,
	body:      ^Stmt,
	reverse:   bool,
}

Inline_Range_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	inline_pos: tokenizer.Pos,
	for_pos:    tokenizer.Pos,
	val0:       ^Expr,
	val1:       ^Expr,
	in_pos:     tokenizer.Pos,
	expr:       ^Expr,
	body:       ^Stmt,
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
	partial:    bool,
}

Type_Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: tokenizer.Pos,
	tag:        ^Stmt,
	expr:       ^Expr,
	body:       ^Stmt,
	partial:    bool,
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
	attributes:  [dynamic]^Attribute, // dynamic as parsing will add to them lazily
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
	attributes:      [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	foreign_tok:     tokenizer.Token,
	import_tok:      tokenizer.Token,
	name:            ^Ident,
	collection_name: string,
	fullpaths:       []^Expr,
	comment:         ^Comment_Group,
}



// Other things
unparen_expr :: proc(expr: ^Expr) -> (val: ^Expr) {
	val = expr
	if expr == nil {
		return
	}
	for {
		e := val.derived.(^Paren_Expr) or_break
		if e.expr == nil {
			break
		}
		val = e.expr
	}
	return
}

strip_or_return_expr :: proc(expr: ^Expr) -> (val: ^Expr) {
	val = expr
	if expr == nil {
		return
	}
	for {
		inner: ^Expr
		#partial switch e in val.derived {
		case ^Or_Return_Expr:
			inner = e.expr
		case ^Or_Branch_Expr:
			inner = e.expr
		case ^Paren_Expr:
			inner = e.expr
		}
		if inner == nil {
			break
		}
		val = inner
	}
	return
}

Field_Flags :: distinct bit_set[Field_Flag]

Field_Flag :: enum {
	Invalid,
	Unknown,

	Ellipsis,
	Using,
	No_Alias,
	C_Vararg,
	Const,
	Any_Int,
	Subtype,
	By_Ptr,
	No_Broadcast,
	No_Capture,

	Results,
	Tags,
	Default_Parameters,
	Typeid_Token,
}

field_flag_strings := [Field_Flag]string{
	.Invalid            = "",
	.Unknown            = "",

	.Ellipsis           = "..",
	.Using              = "using",
	.No_Alias           = "#no_alias",
	.C_Vararg           = "#c_vararg",
	.Const              = "#const",
	.Any_Int            = "#any_int",
	.Subtype            = "#subtype",
	.By_Ptr             = "#by_ptr",
	.No_Broadcast       = "#no_broadcast",
	.No_Capture         = "#no_capture",

	.Results            = "results",
	.Tags               = "field tag",
	.Default_Parameters = "default parameters",
	.Typeid_Token       = "typeid",
}

field_hash_flag_strings := []struct{key: string, flag: Field_Flag}{
	{"no_alias",     .No_Alias},
	{"c_vararg",     .C_Vararg},
	{"const",        .Const},
	{"any_int",      .Any_Int},
	{"subtype",      .Subtype},
	{"by_ptr",       .By_Ptr},
	{"no_broadcast", .No_Broadcast},
	{"no_capture",   .No_Capture},
}


Field_Flags_Struct :: Field_Flags{
	.Using,
	.Tags,
	.Subtype,
}
Field_Flags_Record_Poly_Params :: Field_Flags{
	.Typeid_Token,
	.Default_Parameters,
}
Field_Flags_Signature :: Field_Flags{
	.Ellipsis,
	.Using,
	.No_Alias,
	.C_Vararg,
	.Const,
	.Any_Int,
	.By_Ptr,
	.No_Broadcast,
	.Default_Parameters,
}

Field_Flags_Signature_Params  :: Field_Flags_Signature | {Field_Flag.Typeid_Token}
Field_Flags_Signature_Results :: Field_Flags_Signature


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
	tag:     ^Expr,
	pointer: tokenizer.Pos,
	elem:    ^Expr,
}

Multi_Pointer_Type :: struct {
	using node: Expr,
	open:    tokenizer.Pos,
	pointer: tokenizer.Pos,
	close:   tokenizer.Pos,
	elem:    ^Expr,
}

Array_Type :: struct {
	using node: Expr,
	open:  tokenizer.Pos,
	tag:   ^Expr,
	len:   ^Expr, // Unary_Expr node for [?]T array types, nil for slice types
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
	field_align:   ^Expr,
	where_token:   tokenizer.Token,
	where_clauses: []^Expr,
	is_packed:     bool,
	is_raw_union:  bool,
	is_no_copy:    bool,
	fields:        ^Field_List,
	name_count:    int,
}

Union_Type_Kind :: enum u8 {
	Normal,
	maybe,
	no_nil,
	shared_nil,
}

Union_Type :: struct {
	using node: Expr,
	tok_pos:       tokenizer.Pos,
	poly_params:   ^Field_List,
	align:         ^Expr,
	kind:          Union_Type_Kind,
	where_token:   tokenizer.Token,
	where_clauses: []^Expr,
	variants:      []^Expr,
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


Relative_Type :: struct {
	using node: Expr,
	tag:  ^Expr,
	type: ^Expr,
}

Matrix_Type :: struct {
	using node: Expr,
	tok_pos:      tokenizer.Pos,
	row_count:    ^Expr,
	column_count: ^Expr,
	elem:         ^Expr,
}

Bit_Field_Type :: struct {
	using node:   Expr,
	tok_pos:      tokenizer.Pos,
	backing_type: ^Expr,
	open:         tokenizer.Pos,
	fields:       []^Bit_Field_Field,
	close:        tokenizer.Pos,
}

Bit_Field_Field :: struct {
	using node: Node,
	docs:       ^Comment_Group,
	name:       ^Expr,
	type:       ^Expr,
	bit_size:   ^Expr,
	tag:        tokenizer.Token,
	comments:   ^Comment_Group,
}

Any_Node :: union {
	^Package,
	^File,
	^Comment_Group,

	^Bad_Expr,
	^Ident,
	^Implicit,
	^Undef,
	^Basic_Lit,
	^Basic_Directive,
	^Ellipsis,
	^Proc_Lit,
	^Comp_Lit,
	^Tag_Expr,
	^Unary_Expr,
	^Binary_Expr,
	^Paren_Expr,
	^Selector_Expr,
	^Implicit_Selector_Expr,
	^Selector_Call_Expr,
	^Index_Expr,
	^Deref_Expr,
	^Slice_Expr,
	^Matrix_Index_Expr,
	^Call_Expr,
	^Field_Value,
	^Ternary_If_Expr,
	^Ternary_When_Expr,
	^Or_Else_Expr,
	^Or_Return_Expr,
	^Or_Branch_Expr,
	^Type_Assertion,
	^Type_Cast,
	^Auto_Cast,
	^Inline_Asm_Expr,

	^Proc_Group,

	^Typeid_Type,
	^Helper_Type,
	^Distinct_Type,
	^Poly_Type,
	^Proc_Type,
	^Pointer_Type,
	^Multi_Pointer_Type,
	^Array_Type,
	^Dynamic_Array_Type,
	^Struct_Type,
	^Union_Type,
	^Enum_Type,
	^Bit_Set_Type,
	^Map_Type,
	^Relative_Type,
	^Matrix_Type,
	^Bit_Field_Type,

	^Bad_Stmt,
	^Empty_Stmt,
	^Expr_Stmt,
	^Tag_Stmt,
	^Assign_Stmt,
	^Block_Stmt,
	^If_Stmt,
	^When_Stmt,
	^Return_Stmt,
	^Defer_Stmt,
	^For_Stmt,
	^Range_Stmt,
	^Inline_Range_Stmt,
	^Case_Clause,
	^Switch_Stmt,
	^Type_Switch_Stmt,
	^Branch_Stmt,
	^Using_Stmt,

	^Bad_Decl,
	^Value_Decl,
	^Package_Decl,
	^Import_Decl,
	^Foreign_Block_Decl,
	^Foreign_Import_Decl,

	^Attribute,
	^Field,
	^Field_List,
	^Bit_Field_Field,
}


Any_Expr :: union {
	^Bad_Expr,
	^Ident,
	^Implicit,
	^Undef,
	^Basic_Lit,
	^Basic_Directive,
	^Ellipsis,
	^Proc_Lit,
	^Comp_Lit,
	^Tag_Expr,
	^Unary_Expr,
	^Binary_Expr,
	^Paren_Expr,
	^Selector_Expr,
	^Implicit_Selector_Expr,
	^Selector_Call_Expr,
	^Index_Expr,
	^Deref_Expr,
	^Slice_Expr,
	^Matrix_Index_Expr,
	^Call_Expr,
	^Field_Value,
	^Ternary_If_Expr,
	^Ternary_When_Expr,
	^Or_Else_Expr,
	^Or_Return_Expr,
	^Or_Branch_Expr,
	^Type_Assertion,
	^Type_Cast,
	^Auto_Cast,
	^Inline_Asm_Expr,

	^Proc_Group,

	^Typeid_Type,
	^Helper_Type,
	^Distinct_Type,
	^Poly_Type,
	^Proc_Type,
	^Pointer_Type,
	^Multi_Pointer_Type,
	^Array_Type,
	^Dynamic_Array_Type,
	^Struct_Type,
	^Union_Type,
	^Enum_Type,
	^Bit_Set_Type,
	^Map_Type,
	^Relative_Type,
	^Matrix_Type,
	^Bit_Field_Type,
}


Any_Stmt :: union {
	^Bad_Stmt,
	^Empty_Stmt,
	^Expr_Stmt,
	^Tag_Stmt,
	^Assign_Stmt,
	^Block_Stmt,
	^If_Stmt,
	^When_Stmt,
	^Return_Stmt,
	^Defer_Stmt,
	^For_Stmt,
	^Range_Stmt,
	^Inline_Range_Stmt,
	^Case_Clause,
	^Switch_Stmt,
	^Type_Switch_Stmt,
	^Branch_Stmt,
	^Using_Stmt,

	^Bad_Decl,
	^Value_Decl,
	^Package_Decl,
	^Import_Decl,
	^Foreign_Block_Decl,
	^Foreign_Import_Decl,
}
