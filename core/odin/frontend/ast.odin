package odin_frontend

import "core:sync"
import "core:intrinsics"

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
}
Node_State_Flags :: distinct bit_set[Node_State_Flag]

Node :: struct {
	pos:         Pos,
	end:         Pos,
	state_flags: Node_State_Flags,
	derived:     Any_Node,
}

Comment_Group :: struct {
	using node: Node,
	list: []Token,
}




/*c++
struct AstFile {
	i32          id;
	u32          flags;
	AstPackage * pkg;
	Scope *      scope;

	Ast *        pkg_decl;

	String       fullpath;
	String       filename;
	String       directory;

	Tokenizer    tokenizer;
	Array<Token> tokens;
	isize        curr_token_index;
	isize        prev_token_index;
	Token        curr_token;
	Token        prev_token; // previous non-comment
	Token        package_token;
	String       package_name;

	u64          vet_flags;
	bool         vet_flags_set;

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	isize        expr_level;
	bool         allow_newline; // Only valid for expr_level == 0
	bool         allow_range;   // NOTE(bill): Ranges are only allowed in certain cases
	bool         allow_in_expr; // NOTE(bill): in expression are only allowed in certain cases
	bool         in_foreign_block;
	bool         allow_type;
	bool         in_when_statement;

	isize total_file_decl_count;
	isize delayed_decl_count;
	Slice<Ast *> decls;
	Array<Ast *> imports; // 'import'
	isize        directive_count;

	Ast *          curr_proc;
	isize          error_count;
	ParseFileError last_error;
	f64            time_to_tokenize; // seconds
	f64            time_to_parse;    // seconds

	CommentGroup *lead_comment;     // Comment (block) before the decl
	CommentGroup *line_comment;     // Comment after the semicolon
	CommentGroup *docs;             // current docs
	Array<CommentGroup *> comments; // All the comments!

	// This is effectively a queue but does not require any multi-threading capabilities
	Array<Ast *> delayed_decls_queues[AstDelayQueue_COUNT];

#define PARSER_MAX_FIX_COUNT 6
	isize    fix_count;
	TokenPos fix_prev_pos;

	struct LLVMOpaqueMetadata *llvm_metadata;
	struct LLVMOpaqueMetadata *llvm_metadata_scope;
};
*/






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
	tok: Token,
}


Undef :: struct {
	using node: Expr,
	tok:  Token_Kind,
}

Basic_Lit :: struct {
	using node: Expr,
	tok: Token,
}

Basic_Directive :: struct {
	using node: Expr,
	tok:  Token,
	name: string,
}

Ellipsis :: struct {
	using node: Expr,
	tok:  Token_Kind,
	expr: ^Expr,
}

Proc_Lit :: struct {
	using node: Expr,
	type: ^Proc_Type,
	body: ^Stmt,
	tags: Proc_Tags,
	inlining: Proc_Inlining,
	where_token: Token,
	where_clauses: []^Expr,
}

Comp_Lit :: struct {
	using node: Expr,
	type: ^Expr,
	open: Pos,
	elems: []^Expr,
	close: Pos,
	tag: ^Expr,
}


Tag_Expr :: struct {
	using node: Expr,
	op:      Token,
	name:    string,
	expr:    ^Expr,
}

Unary_Expr :: struct {
	using node: Expr,
	op:   Token,
	expr: ^Expr,
}

Binary_Expr :: struct {
	using node: Expr,
	left:  ^Expr,
	op:    Token,
	right: ^Expr,
}

Paren_Expr :: struct {
	using node: Expr,
	open:  Pos,
	expr:  ^Expr,
	close: Pos,
}

Selector_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	op:    Token,
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
	open:  Pos,
	index: ^Expr,
	close: Pos,
}

Deref_Expr :: struct {
	using node: Expr,
	expr: ^Expr,
	op:   Token,
}

Slice_Expr :: struct {
	using node: Expr,
	expr:     ^Expr,
	open:     Pos,
	low:      ^Expr,
	interval: Token,
	high:     ^Expr,
	close:    Pos,
}

Matrix_Index_Expr :: struct {
	using node: Expr,
	expr:         ^Expr,
	open:         Pos,
	row_index:    ^Expr,
	column_index: ^Expr,
	close:        Pos,
}

Call_Expr :: struct {
	using node: Expr,
	inlining: Proc_Inlining,
	expr:     ^Expr,
	open:     Pos,
	args:     []^Expr,
	ellipsis: Token,
	close:    Pos,
}

Field_Value :: struct {
	using node: Expr,
	field: ^Expr,
	sep:   Pos,
	value: ^Expr,
}

Ternary_If_Expr :: struct {
	using node: Expr,
	x:    ^Expr,
	op1:  Token,
	cond: ^Expr,
	op2:  Token,
	y:    ^Expr,
}

Ternary_When_Expr :: struct {
	using node: Expr,
	x:    ^Expr,
	op1:  Token,
	cond: ^Expr,
	op2:  Token,
	y:    ^Expr,
}

Or_Else_Expr :: struct {
	using node: Expr,
	x:     ^Expr,
	token: Token,
	y:     ^Expr,
}

Or_Return_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	token: Token,
}

Or_Branch_Expr :: struct {
	using node: Expr,
	expr:  ^Expr,
	token: Token,
	label: ^Expr,
}

Type_Assertion :: struct {
	using node: Expr,
	expr:  ^Expr,
	dot:   Pos,
	open:  Pos,
	type:  ^Expr,
	close: Pos,
}

Type_Cast :: struct {
	using node: Expr,
	tok:   Token,
	open:  Pos,
	type:  ^Expr,
	close: Pos,
	expr:  ^Expr,
}

Auto_Cast :: struct {
	using node: Expr,
	op:   Token,
	expr: ^Expr,
}

Inline_Asm_Dialect :: enum u8 {
	Default = 0,
	ATT     = 1,
	Intel   = 2,
}


Inline_Asm_Expr :: struct {
	using node: Expr,
	tok:                Token,
	param_types:        []^Expr,
	return_type:        ^Expr,
	has_side_effects:   bool,
	is_align_stack:     bool,
	dialect:            Inline_Asm_Dialect,
	open:               Pos,
	constraints_string: ^Expr,
	asm_string:         ^Expr,
	close:              Pos,
}




// Statements

Bad_Stmt :: struct {
	using node: Stmt,
}

Empty_Stmt :: struct {
	using node: Stmt,
	semicolon: Pos, // Position of the following ';'
}

Expr_Stmt :: struct {
	using node: Stmt,
	expr: ^Expr,
}

Tag_Stmt :: struct {
	using node: Stmt,
	op:      Token,
	name:    string,
	stmt:    ^Stmt,
}

Assign_Stmt :: struct {
	using node: Stmt,
	lhs:    []^Expr,
	op:     Token,
	rhs:    []^Expr,
}


Block_Stmt :: struct {
	using node: Stmt,
	label: ^Expr,
	open:  Pos,
	stmts: []^Stmt,
	close: Pos,
	uses_do: bool,
}

If_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	if_pos:    Pos,
	init:      ^Stmt,
	cond:      ^Expr,
	body:      ^Stmt,
	else_pos:  Pos,
	else_stmt: ^Stmt,
}

When_Stmt :: struct {
	using node: Stmt,
	when_pos:  Pos,
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
	for_pos:   Pos,
	init:      ^Stmt,
	cond:      ^Expr,
	post:      ^Stmt,
	body:      ^Stmt,
}

Range_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	for_pos:   Pos,
	vals:      []^Expr,
	in_pos:    Pos,
	expr:      ^Expr,
	body:      ^Stmt,
	reverse:   bool,
}

Inline_Range_Stmt :: struct {
	using node: Stmt,
	label:     ^Expr,
	inline_pos: Pos,
	for_pos:    Pos,
	val0:       ^Expr,
	val1:       ^Expr,
	in_pos:     Pos,
	expr:       ^Expr,
	body:       ^Stmt,
}

Case_Clause :: struct {
	using node: Stmt,
	case_pos:   Pos,
	list:       []^Expr,
	terminator: Token,
	body:       []^Stmt,
}

Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: Pos,
	init:       ^Stmt,
	cond:       ^Expr,
	body:       ^Stmt,
	partial:    bool,
}

Type_Switch_Stmt :: struct {
	using node: Stmt,
	label:      ^Expr,
	switch_pos: Pos,
	tag:        ^Stmt,
	expr:       ^Expr,
	body:       ^Stmt,
	partial:    bool,
}

Branch_Stmt :: struct {
	using node: Stmt,
	tok:   Token,
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
	token:   Token,
	name:    string,
	comment: ^Comment_Group,
}

Import_Decl :: struct {
	using node: Decl,
	docs:       ^Comment_Group,
	is_using:    bool,
	import_tok:  Token,
	name:        Token,
	relpath:     Token,
	fullpath:    string,
	comment:     ^Comment_Group,
}

Foreign_Block_Decl :: struct {
	using node: Decl,
	docs:            ^Comment_Group,
	attributes:      [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	tok:             Token,
	foreign_library: ^Expr,
	body:            ^Stmt,
}

Foreign_Import_Decl :: struct {
	using node: Decl,
	docs:            ^Comment_Group,
	attributes:      [dynamic]^Attribute, // dynamic as parsing will add to them lazily
	foreign_tok:     Token,
	import_tok:      Token,
	name:            ^Ident,
	collection_name: string,
	fullpaths:       []string,
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

	.Results            = "results",
	.Tags               = "field tag",
	.Default_Parameters = "default parameters",
	.Typeid_Token       = "typeid",
}

field_hash_flag_strings := []struct{key: string, flag: Field_Flag}{
	{"no_alias", .No_Alias},
	{"c_vararg", .C_Vararg},
	{"const",    .Const},
	{"any_int",  .Any_Int},
	{"subtype",  .Subtype},
	{"by_ptr",   .By_Ptr},
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
	.Default_Parameters,
}

Field_Flags_Signature_Params  :: Field_Flags_Signature | {Field_Flag.Typeid_Token}
Field_Flags_Signature_Results :: Field_Flags_Signature


Proc_Group :: struct {
	using node: Expr,
	tok:   Token,
	open:  Pos,
	args:  []^Expr,
	close: Pos,
}

Attribute :: struct {
	using node: Node,
	tok:   Token_Kind,
	open:  Pos,
	elems: []^Expr,
	close: Pos,
}

Field :: struct {
	using node: Node,
	docs:          ^Comment_Group,
	names:         []^Expr, // Could be polymorphic
	type:          ^Expr,
	default_value: ^Expr,
	tag:           Token,
	flags:         Field_Flags,
	comment:       ^Comment_Group,
}

Field_List :: struct {
	using node: Node,
	open:  Pos,
	list:  []^Field,
	close: Pos,
}


// Types
Typeid_Type :: struct {
	using node: Expr,
	tok:            Token_Kind,
	specialization: ^Expr,
}

Helper_Type :: struct {
	using node: Expr,
	tok:  Token_Kind,
	type: ^Expr,
}

Distinct_Type :: struct {
	using node: Expr,
	tok:  Token_Kind,
	type: ^Expr,
}

Poly_Type :: struct {
	using node: Expr,
	dollar:         Pos,
	type:           ^Ident,
	specialization: ^Expr,
}

Proc_Type :: struct {
	using node: Expr,
	tok:       Token,
	calling_convention: Proc_Calling_Convention,
	params:    ^Field_List,
	arrow:     Pos,
	results:   ^Field_List,
	tags:      Proc_Tags,
	generic:   bool,
	diverging: bool,
}

Pointer_Type :: struct {
	using node: Expr,
	tag:     ^Expr,
	pointer: Pos,
	elem:    ^Expr,
}

Multi_Pointer_Type :: struct {
	using node: Expr,
	open:    Pos,
	pointer: Pos,
	close:   Pos,
	elem:    ^Expr,
}

Array_Type :: struct {
	using node: Expr,
	open:  Pos,
	tag:   ^Expr,
	len:   ^Expr, // Ellipsis node for [?]T arrray types, nil for slice types
	close: Pos,
	elem:  ^Expr,
}

Dynamic_Array_Type :: struct {
	using node: Expr,
	tag:         ^Expr,
	open:        Pos,
	dynamic_pos: Pos,
	close:       Pos,
	elem:        ^Expr,
}

Struct_Type :: struct {
	using node: Expr,
	tok_pos:       Pos,
	poly_params:   ^Field_List,
	align:         ^Expr,
	where_token:   Token,
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
	tok_pos:       Pos,
	poly_params:   ^Field_List,
	align:         ^Expr,
	kind:          Union_Type_Kind,
	where_token:   Token,
	where_clauses: []^Expr,
	variants:      []^Expr,
}

Enum_Type :: struct {
	using node: Expr,
	tok_pos:  Pos,
	base_type: ^Expr,
	open:      Pos,
	fields:    []^Expr,
	close:     Pos,

	is_using:  bool,
}

Bit_Set_Type :: struct {
	using node: Expr,
	tok_pos:    Pos,
	open:       Pos,
	elem:       ^Expr,
	underlying: ^Expr,
	close:      Pos,
}

Map_Type :: struct {
	using node: Expr,
	tok_pos: Pos,
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
	tok_pos:      Pos,
	row_count:    ^Expr,
	column_count: ^Expr,
	elem:         ^Expr,
}


Any_Node :: union {
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

new_node :: proc($T: typeid, pos, end: Pos, allocator := context.allocator) -> ^T {
	n, _ := new(T, allocator)
	n.pos = pos
	n.end = end
	n.derived = n
	base: ^Node = n // Dummy check
	_ = base // make -vet happy
	when intrinsics.type_has_field(T, "derived_expr") {
		n.derived_expr = n
	}
	when intrinsics.type_has_field(T, "derived_stmt") {
		n.derived_stmt = n
	}
	return n
}