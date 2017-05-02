typedef struct AstNode AstNode;
typedef struct Scope Scope;
typedef struct DeclInfo DeclInfo;

typedef enum ParseFileError {
	ParseFile_None,

	ParseFile_WrongExtension,
	ParseFile_InvalidFile,
	ParseFile_EmptyFile,
	ParseFile_Permission,
	ParseFile_NotFound,
	ParseFile_InvalidToken,

	ParseFile_Count,
} ParseFileError;

typedef Array(AstNode *) AstNodeArray;

gb_global i32 global_file_id = 0;

typedef struct AstFile {
	i32            id;
	gbArena        arena;
	Tokenizer      tokenizer;
	Array(Token)   tokens;
	isize          curr_token_index;
	Token          curr_token;
	Token          prev_token; // previous non-comment

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	isize          expr_level;
	bool           allow_range;
	bool           ignore_operand;

	AstNodeArray   decls;
	bool           is_global_scope;

	AstNode *      curr_proc;
	isize          scope_level;
	Scope *        scope;       // NOTE(bill): Created in checker
	DeclInfo *     decl_info;   // NOTE(bill): Created in checker

	// TODO(bill): Error recovery
#define PARSER_MAX_FIX_COUNT 6
	isize    fix_count;
	TokenPos fix_prev_pos;
} AstFile;

typedef struct ImportedFile {
	String   path;
	String   rel_path;
	TokenPos pos; // #import
} ImportedFile;

typedef struct Parser {
	String              init_fullpath;
	Array(AstFile)      files;
	Array(ImportedFile) imports;
	gbAtomic32          import_index;
	isize               total_token_count;
	isize               total_line_count;
	gbMutex             mutex;
} Parser;

typedef enum ProcTag {
	ProcTag_bounds_check    = 1<<0,
	ProcTag_no_bounds_check = 1<<1,

	ProcTag_require_results = 1<<4,

	ProcTag_foreign         = 1<<10,
	ProcTag_export          = 1<<11,
	ProcTag_link_name       = 1<<12,
	ProcTag_inline          = 1<<13,
	ProcTag_no_inline       = 1<<14,
	// ProcTag_dll_import      = 1<<15,
	// ProcTag_dll_export      = 1<<16,
} ProcTag;

typedef enum ProcCallingConvention {
	ProcCC_Odin = 0,
	ProcCC_C    = 1,
	ProcCC_Std  = 2,
	ProcCC_Fast = 3,

	ProcCC_Invalid,
} ProcCallingConvention;

typedef enum VarDeclFlag {
	VarDeclFlag_using            = 1<<0,
	VarDeclFlag_immutable        = 1<<1,
	VarDeclFlag_thread_local     = 1<<2,
} VarDeclFlag;

typedef enum StmtStateFlag {
	StmtStateFlag_bounds_check    = 1<<0,
	StmtStateFlag_no_bounds_check = 1<<1,
} StmtStateFlag;

typedef enum FieldFlag {
	FieldFlag_ellipsis  = 1<<0,
	FieldFlag_using     = 1<<1,
	FieldFlag_no_alias  = 1<<2,
	FieldFlag_immutable = 1<<3,

	FieldFlag_Signature = FieldFlag_ellipsis|FieldFlag_using|FieldFlag_no_alias|FieldFlag_immutable,
} FieldListTag;


AstNodeArray make_ast_node_array(AstFile *f) {
	AstNodeArray a;
	// array_init(&a, gb_arena_allocator(&f->arena));
	array_init(&a, heap_allocator());
	return a;
}


// NOTE(bill): This massive define is so it is possible to create a discriminated union (and extra debug info)
// for the AstNode. I personally prefer discriminated unions over subtype polymorphism as I can preallocate
// all the nodes and even memcpy in a different kind of node
#define AST_NODE_KINDS \
	AST_NODE_KIND(Ident,          "identifier",      Token) \
	AST_NODE_KIND(Implicit,       "implicit",        Token) \
	AST_NODE_KIND(BasicLit,       "basic literal",   Token) \
	AST_NODE_KIND(BasicDirective, "basic directive", struct { \
		Token token; \
		String name; \
	}) \
	AST_NODE_KIND(Ellipsis,       "ellipsis", struct { \
		Token token; \
		AstNode *expr; \
	}) \
	AST_NODE_KIND(ProcLit, "procedure literal", struct { \
		AstNode *type;            \
		AstNode *body;            \
		u64      tags;            \
		AstNode *foreign_library; \
		String   foreign_name;    \
		String   link_name;       \
	}) \
	AST_NODE_KIND(CompoundLit, "compound literal", struct { \
		AstNode *type; \
		AstNodeArray elems; \
		Token open, close; \
	}) \
	AST_NODE_KIND(Alias, "alias", struct { \
		Token token; \
		AstNode *expr; \
	}) \
AST_NODE_KIND(_ExprBegin,  "",  i32) \
	AST_NODE_KIND(BadExpr,      "bad expression",         struct { Token begin, end; }) \
	AST_NODE_KIND(TagExpr,      "tag expression",         struct { Token token, name; AstNode *expr; }) \
	AST_NODE_KIND(RunExpr,      "run expression",         struct { Token token, name; AstNode *expr; }) \
	AST_NODE_KIND(UnaryExpr,    "unary expression",       struct { Token op; AstNode *expr; }) \
	AST_NODE_KIND(BinaryExpr,   "binary expression",      struct { Token op; AstNode *left, *right; } ) \
	AST_NODE_KIND(ParenExpr,    "parentheses expression", struct { AstNode *expr; Token open, close; }) \
	AST_NODE_KIND(SelectorExpr, "selector expression",    struct { Token token; AstNode *expr, *selector; }) \
	AST_NODE_KIND(IndexExpr,    "index expression",       struct { AstNode *expr, *index; Token open, close; }) \
	AST_NODE_KIND(DerefExpr,    "dereference expression", struct { Token op; AstNode *expr; }) \
	AST_NODE_KIND(SliceExpr,    "slice expression", struct { \
		AstNode *expr; \
		Token open, close; \
		Token interval0; \
		Token interval1; \
		bool index3; \
		AstNode *low, *high, *max; \
	}) \
	AST_NODE_KIND(CallExpr,     "call expression", struct { \
		AstNode *    proc; \
		AstNodeArray args; \
		Token        open; \
		Token        close; \
		Token        ellipsis; \
	}) \
	AST_NODE_KIND(MacroCallExpr, "macro call expression", struct { \
		AstNode *    macro; \
		Token        bang; \
		AstNodeArray args; \
		Token        open; \
		Token        close; \
	}) \
	AST_NODE_KIND(FieldValue,    "field value",         struct { Token eq; AstNode *field, *value; }) \
	AST_NODE_KIND(TernaryExpr,   "ternary expression",  struct { AstNode *cond, *x, *y; }) \
	AST_NODE_KIND(TypeAssertion, "type assertion",      struct { AstNode *expr; Token dot; AstNode *type; }) \
AST_NODE_KIND(_ExprEnd,       "", i32) \
AST_NODE_KIND(_StmtBegin,     "", i32) \
	AST_NODE_KIND(BadStmt,    "bad statement",                 struct { Token begin, end; }) \
	AST_NODE_KIND(EmptyStmt,  "empty statement",               struct { Token token; }) \
	AST_NODE_KIND(ExprStmt,   "expression statement",          struct { AstNode *expr; } ) \
	AST_NODE_KIND(TagStmt,    "tag statement", struct { \
		Token token; \
		Token name; \
		AstNode *stmt; \
	}) \
	AST_NODE_KIND(AssignStmt, "assign statement", struct { \
		Token op; \
		AstNodeArray lhs, rhs; \
	}) \
	AST_NODE_KIND(IncDecStmt, "increment decrement statement", struct { \
		Token op; \
		AstNode *expr; \
	}) \
AST_NODE_KIND(_ComplexStmtBegin, "", i32) \
	AST_NODE_KIND(BlockStmt, "block statement", struct { \
		AstNodeArray stmts; \
		Token open, close; \
	}) \
	AST_NODE_KIND(IfStmt, "if statement", struct { \
		Token token; \
		AstNode *init; \
		AstNode *cond; \
		AstNode *body; \
		AstNode *else_stmt; \
	}) \
	AST_NODE_KIND(WhenStmt, "when statement", struct { \
		Token token; \
		AstNode *cond; \
		AstNode *body; \
		AstNode *else_stmt; \
	}) \
	AST_NODE_KIND(ReturnStmt, "return statement", struct { \
		Token token; \
		AstNodeArray results; \
	}) \
	AST_NODE_KIND(ForStmt, "for statement", struct { \
		Token    token; \
		AstNode *label; \
		AstNode *init; \
		AstNode *cond; \
		AstNode *post; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(RangeStmt, "range statement", struct { \
		Token    token; \
		AstNode *label; \
		AstNode *value; \
		AstNode *index; \
		Token    in_token; \
		AstNode *expr; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(CaseClause, "case clause", struct { \
		Token token;        \
		AstNodeArray list;  \
		AstNodeArray stmts; \
	}) \
	AST_NODE_KIND(MatchStmt, "match statement", struct { \
		Token token;   \
		AstNode *label; \
		AstNode *init; \
		AstNode *tag;  \
		AstNode *body; \
	}) \
	AST_NODE_KIND(TypeMatchStmt, "type match statement", struct { \
		Token    token; \
		AstNode *label; \
		AstNode *tag;   \
		AstNode *body;  \
	}) \
	AST_NODE_KIND(DeferStmt,  "defer statement",  struct { Token token; AstNode *stmt; }) \
	AST_NODE_KIND(BranchStmt, "branch statement", struct { Token token; AstNode *label; }) \
	AST_NODE_KIND(UsingStmt,  "using statement",  struct { \
		Token token;   \
		AstNodeArray list; \
	}) \
	AST_NODE_KIND(AsmOperand, "assembly operand", struct { \
		Token string;     \
		AstNode *operand; \
	}) \
	AST_NODE_KIND(AsmStmt,    "assembly statement", struct { \
		Token token;           \
		bool is_volatile;      \
		Token open, close;     \
		Token code_string;     \
		AstNode *output_list;  \
		AstNode *input_list;   \
		AstNode *clobber_list; \
		isize output_count, input_count, clobber_count; \
	}) \
	AST_NODE_KIND(PushAllocator, "push_allocator statement", struct { \
		Token token;   \
		AstNode *expr; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(PushContext, "push_context statement", struct { \
		Token token;   \
		AstNode *expr; \
		AstNode *body; \
	}) \
AST_NODE_KIND(_ComplexStmtEnd, "", i32) \
AST_NODE_KIND(_StmtEnd,        "", i32) \
AST_NODE_KIND(_DeclBegin,      "", i32) \
	AST_NODE_KIND(BadDecl,     "bad declaration",     struct { Token begin, end; }) \
	AST_NODE_KIND(ValueDecl, "value declaration", struct { \
		bool         is_var; \
		AstNodeArray names;  \
		AstNode *    type;   \
		AstNodeArray values; \
		u32          flags;  \
	}) \
	AST_NODE_KIND(ImportDecl, "import declaration", struct { \
		Token     token;        \
		bool      is_import;    \
		Token     relpath;      \
		String    fullpath;     \
		Token     import_name;  \
		AstNode   *cond;        \
		AstNode   *note;        \
	}) \
	AST_NODE_KIND(ForeignLibrary, "foreign library", struct { \
		Token token, filepath; \
		Token library_name;     \
		String base_dir;       \
		AstNode *cond;         \
		bool is_system;        \
	}) \
	AST_NODE_KIND(Label, "label", struct { 	\
		Token token; \
		AstNode *name; \
	}) \
AST_NODE_KIND(_DeclEnd,   "", i32) \
	AST_NODE_KIND(Field, "field", struct { \
		AstNodeArray names;    \
		AstNode *    type;     \
		u32          flags;    \
	}) \
	AST_NODE_KIND(FieldList, "field list", struct { \
		Token token; \
		AstNodeArray list; \
	}) \
	AST_NODE_KIND(UnionField, "union field", struct { \
		AstNode *name; \
		AstNode *list; \
	}) \
AST_NODE_KIND(_TypeBegin, "", i32) \
	AST_NODE_KIND(HelperType, "type", struct { \
		Token token; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(ProcType, "procedure type", struct { \
		Token    token;   \
		AstNode *params;  \
		AstNode *results; \
		u64      tags;    \
		ProcCallingConvention calling_convention; \
	}) \
	AST_NODE_KIND(PointerType, "pointer type", struct { \
		Token token; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(AtomicType, "atomic type", struct { \
		Token token; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(ArrayType, "array type", struct { \
		Token token; \
		AstNode *count; \
		AstNode *elem; \
	}) \
	AST_NODE_KIND(DynamicArrayType, "dynamic array type", struct { \
		Token token; \
		AstNode *elem; \
	}) \
	AST_NODE_KIND(VectorType, "vector type", struct { \
		Token token; \
		AstNode *count; \
		AstNode *elem; \
	}) \
	AST_NODE_KIND(StructType, "struct type", struct { \
		Token token; \
		AstNodeArray fields; \
		isize field_count; \
		bool is_packed; \
		bool is_ordered; \
		AstNode *align; \
	}) \
	AST_NODE_KIND(UnionType, "union type", struct { \
		Token        token; \
		AstNodeArray fields; \
		isize        field_count; \
		AstNodeArray variants; \
	}) \
	AST_NODE_KIND(RawUnionType, "raw union type", struct { \
		Token token; \
		AstNodeArray fields; \
		isize field_count; \
	}) \
	AST_NODE_KIND(EnumType, "enum type", struct { \
		Token token; \
		AstNode *base_type; \
		AstNodeArray fields; /* FieldValue */ \
	}) \
	AST_NODE_KIND(MapType, "map type", struct { \
		Token token; \
		AstNode *count; \
		AstNode *key; \
		AstNode *value; \
	}) \
AST_NODE_KIND(_TypeEnd,  "", i32)

typedef enum AstNodeKind {
	AstNode_Invalid,
#define AST_NODE_KIND(_kind_name_, ...) GB_JOIN2(AstNode_, _kind_name_),
	AST_NODE_KINDS
#undef AST_NODE_KIND
	AstNode_Count,
} AstNodeKind;

String const ast_node_strings[] = {
	{cast(u8 *)"invalid node", gb_size_of("invalid node")},
#define AST_NODE_KIND(_kind_name_, name, ...) {cast(u8 *)name, gb_size_of(name)-1},
	AST_NODE_KINDS
#undef AST_NODE_KIND
};

#define AST_NODE_KIND(_kind_name_, name, ...) typedef __VA_ARGS__ GB_JOIN2(AstNode, _kind_name_);
	AST_NODE_KINDS
#undef AST_NODE_KIND

typedef struct AstNode {
	AstNodeKind kind;
	u32 stmt_state_flags;
	union {
#define AST_NODE_KIND(_kind_name_, name, ...) GB_JOIN2(AstNode, _kind_name_) _kind_name_;
	AST_NODE_KINDS
#undef AST_NODE_KIND
	};
} AstNode;


#define ast_node(n_, Kind_, node_) GB_JOIN2(AstNode, Kind_) *n_ = &(node_)->Kind_; GB_ASSERT((node_)->kind == GB_JOIN2(AstNode_, Kind_))
#define case_ast_node(n_, Kind_, node_) case GB_JOIN2(AstNode_, Kind_): { ast_node(n_, Kind_, node_);
#ifndef case_end
#define case_end } break;
#endif


gb_inline bool is_ast_node_expr(AstNode *node) {
	return gb_is_between(node->kind, AstNode__ExprBegin+1, AstNode__ExprEnd-1);
}
gb_inline bool is_ast_node_stmt(AstNode *node) {
	return gb_is_between(node->kind, AstNode__StmtBegin+1, AstNode__StmtEnd-1);
}
gb_inline bool is_ast_node_complex_stmt(AstNode *node) {
	return gb_is_between(node->kind, AstNode__ComplexStmtBegin+1, AstNode__ComplexStmtEnd-1);
}
gb_inline bool is_ast_node_decl(AstNode *node) {
	return gb_is_between(node->kind, AstNode__DeclBegin+1, AstNode__DeclEnd-1);
}
gb_inline bool is_ast_node_type(AstNode *node) {
	return gb_is_between(node->kind, AstNode__TypeBegin+1, AstNode__TypeEnd-1);
}
gb_inline bool is_ast_node_when_stmt(AstNode *node) {
	return node->kind == AstNode_WhenStmt;
}


Token ast_node_token(AstNode *node) {
	switch (node->kind) {
	case AstNode_Ident:          return node->Ident;
	case AstNode_Implicit:       return node->Implicit;
	case AstNode_BasicLit:       return node->BasicLit;
	case AstNode_BasicDirective: return node->BasicDirective.token;
	case AstNode_ProcLit:        return ast_node_token(node->ProcLit.type);
	case AstNode_CompoundLit:
		if (node->CompoundLit.type != NULL) {
			return ast_node_token(node->CompoundLit.type);
		}
		return node->CompoundLit.open;
	case AstNode_Alias:         return node->Alias.token;

	case AstNode_TagExpr:       return node->TagExpr.token;
	case AstNode_RunExpr:       return node->RunExpr.token;
	case AstNode_BadExpr:       return node->BadExpr.begin;
	case AstNode_UnaryExpr:     return node->UnaryExpr.op;
	case AstNode_BinaryExpr:    return ast_node_token(node->BinaryExpr.left);
	case AstNode_ParenExpr:     return node->ParenExpr.open;
	case AstNode_CallExpr:      return ast_node_token(node->CallExpr.proc);
	case AstNode_MacroCallExpr: return ast_node_token(node->MacroCallExpr.macro);
	case AstNode_SelectorExpr:
		if (node->SelectorExpr.selector != NULL) {
			return ast_node_token(node->SelectorExpr.selector);
		}
		return node->SelectorExpr.token;
	case AstNode_IndexExpr:     return node->IndexExpr.open;
	case AstNode_SliceExpr:     return node->SliceExpr.open;
	case AstNode_Ellipsis:      return node->Ellipsis.token;
	case AstNode_FieldValue:    return node->FieldValue.eq;
	case AstNode_DerefExpr:     return node->DerefExpr.op;
	case AstNode_TernaryExpr:   return ast_node_token(node->TernaryExpr.cond);
	case AstNode_TypeAssertion: return ast_node_token(node->TypeAssertion.expr);

	case AstNode_BadStmt:       return node->BadStmt.begin;
	case AstNode_EmptyStmt:     return node->EmptyStmt.token;
	case AstNode_ExprStmt:      return ast_node_token(node->ExprStmt.expr);
	case AstNode_TagStmt:       return node->TagStmt.token;
	case AstNode_AssignStmt:    return node->AssignStmt.op;
	case AstNode_IncDecStmt:    return ast_node_token(node->IncDecStmt.expr);
	case AstNode_BlockStmt:     return node->BlockStmt.open;
	case AstNode_IfStmt:        return node->IfStmt.token;
	case AstNode_WhenStmt:      return node->WhenStmt.token;
	case AstNode_ReturnStmt:    return node->ReturnStmt.token;
	case AstNode_ForStmt:       return node->ForStmt.token;
	case AstNode_RangeStmt:     return node->RangeStmt.token;
	case AstNode_MatchStmt:     return node->MatchStmt.token;
	case AstNode_CaseClause:    return node->CaseClause.token;
	case AstNode_DeferStmt:     return node->DeferStmt.token;
	case AstNode_BranchStmt:    return node->BranchStmt.token;
	case AstNode_UsingStmt:     return node->UsingStmt.token;
	case AstNode_AsmStmt:       return node->AsmStmt.token;
	case AstNode_PushAllocator: return node->PushAllocator.token;
	case AstNode_PushContext:   return node->PushContext.token;

	case AstNode_BadDecl:        return node->BadDecl.begin;
	case AstNode_ValueDecl:      return ast_node_token(node->ValueDecl.names.e[0]);
	case AstNode_ImportDecl:     return node->ImportDecl.token;
	case AstNode_ForeignLibrary: return node->ForeignLibrary.token;
	case AstNode_Label:      return node->Label.token;


	case AstNode_Field:
		if (node->Field.names.count > 0) {
			return ast_node_token(node->Field.names.e[0]);
		}
		return ast_node_token(node->Field.type);
	case AstNode_FieldList:
		return node->FieldList.token;
	case AstNode_UnionField:
		return ast_node_token(node->UnionField.name);

	case AstNode_HelperType:       return node->HelperType.token;
	case AstNode_ProcType:         return node->ProcType.token;
	case AstNode_PointerType:      return node->PointerType.token;
	case AstNode_AtomicType:       return node->AtomicType.token;
	case AstNode_ArrayType:        return node->ArrayType.token;
	case AstNode_DynamicArrayType: return node->DynamicArrayType.token;
	case AstNode_VectorType:       return node->VectorType.token;
	case AstNode_StructType:       return node->StructType.token;
	case AstNode_UnionType:        return node->UnionType.token;
	case AstNode_RawUnionType:     return node->RawUnionType.token;
	case AstNode_EnumType:         return node->EnumType.token;
	case AstNode_MapType:          return node->MapType.token;
	}

	return empty_token;
}


void error_node(AstNode *node, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	error_va(ast_node_token(node), fmt, va);
	va_end(va);
}

void warning_node(AstNode *node, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	warning_va(ast_node_token(node), fmt, va);
	va_end(va);
}

void syntax_error_node(AstNode *node, char *fmt, ...) {
	va_list va;
	va_start(va, fmt);
	syntax_error_va(ast_node_token(node), fmt, va);
	va_end(va);
}


bool ast_node_expect(AstNode *node, AstNodeKind kind) {
	if (node->kind != kind) {
		error_node(node, "Expected %.*s, got %.*s", LIT(ast_node_strings[node->kind]));
		return false;
	}
	return true;
}


// NOTE(bill): And this below is why is I/we need a new language! Discriminated unions are a pain in C/C++
AstNode *make_ast_node(AstFile *f, AstNodeKind kind) {
	gbArena *arena = &f->arena;
	if (gb_arena_size_remaining(arena, GB_DEFAULT_MEMORY_ALIGNMENT) <= gb_size_of(AstNode)) {
		// NOTE(bill): If a syntax error is so bad, just quit!
		gb_exit(1);
	}
	AstNode *node = gb_alloc_item(gb_arena_allocator(arena), AstNode);
	node->kind = kind;
	return node;
}

AstNode *ast_bad_expr(AstFile *f, Token begin, Token end) {
	AstNode *result = make_ast_node(f, AstNode_BadExpr);
	result->BadExpr.begin = begin;
	result->BadExpr.end   = end;
	return result;
}

AstNode *ast_tag_expr(AstFile *f, Token token, Token name, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_TagExpr);
	result->TagExpr.token = token;
	result->TagExpr.name = name;
	result->TagExpr.expr = expr;
	return result;
}

AstNode *ast_run_expr(AstFile *f, Token token, Token name, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_RunExpr);
	result->RunExpr.token = token;
	result->RunExpr.name = name;
	result->RunExpr.expr = expr;
	return result;
}


AstNode *ast_tag_stmt(AstFile *f, Token token, Token name, AstNode *stmt) {
	AstNode *result = make_ast_node(f, AstNode_TagStmt);
	result->TagStmt.token = token;
	result->TagStmt.name = name;
	result->TagStmt.stmt = stmt;
	return result;
}

AstNode *ast_unary_expr(AstFile *f, Token op, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_UnaryExpr);
	result->UnaryExpr.op = op;
	result->UnaryExpr.expr = expr;
	return result;
}

AstNode *ast_binary_expr(AstFile *f, Token op, AstNode *left, AstNode *right) {
	AstNode *result = make_ast_node(f, AstNode_BinaryExpr);

	if (left == NULL) {
		syntax_error(op, "No lhs expression for binary expression `%.*s`", LIT(op.string));
		left = ast_bad_expr(f, op, op);
	}
	if (right == NULL) {
		syntax_error(op, "No rhs expression for binary expression `%.*s`", LIT(op.string));
		right = ast_bad_expr(f, op, op);
	}

	result->BinaryExpr.op = op;
	result->BinaryExpr.left = left;
	result->BinaryExpr.right = right;

	return result;
}

AstNode *ast_paren_expr(AstFile *f, AstNode *expr, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_ParenExpr);
	result->ParenExpr.expr = expr;
	result->ParenExpr.open = open;
	result->ParenExpr.close = close;
	return result;
}

AstNode *ast_call_expr(AstFile *f, AstNode *proc, AstNodeArray args, Token open, Token close, Token ellipsis) {
	AstNode *result = make_ast_node(f, AstNode_CallExpr);
	result->CallExpr.proc     = proc;
	result->CallExpr.args     = args;
	result->CallExpr.open     = open;
	result->CallExpr.close    = close;
	result->CallExpr.ellipsis = ellipsis;
	return result;
}

AstNode *ast_macro_call_expr(AstFile *f, AstNode *macro, Token bang, AstNodeArray args, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_MacroCallExpr);
	result->MacroCallExpr.macro = macro;
	result->MacroCallExpr.bang  = bang;
	result->MacroCallExpr.args  = args;
	result->MacroCallExpr.open  = open;
	result->MacroCallExpr.close = close;
	return result;
}


AstNode *ast_selector_expr(AstFile *f, Token token, AstNode *expr, AstNode *selector) {
	AstNode *result = make_ast_node(f, AstNode_SelectorExpr);
	result->SelectorExpr.expr = expr;
	result->SelectorExpr.selector = selector;
	return result;
}

AstNode *ast_index_expr(AstFile *f, AstNode *expr, AstNode *index, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_IndexExpr);
	result->IndexExpr.expr = expr;
	result->IndexExpr.index = index;
	result->IndexExpr.open = open;
	result->IndexExpr.close = close;
	return result;
}


AstNode *ast_slice_expr(AstFile *f, AstNode *expr, Token open, Token close, Token interval0, Token interval1, bool index3, AstNode *low, AstNode *high, AstNode *max) {
	AstNode *result = make_ast_node(f, AstNode_SliceExpr);
	result->SliceExpr.expr = expr;
	result->SliceExpr.open = open;
	result->SliceExpr.close = close;
	result->SliceExpr.interval0 = interval0;
	result->SliceExpr.interval1 = interval1;
	result->SliceExpr.index3 = index3;
	result->SliceExpr.low = low;
	result->SliceExpr.high = high;
	result->SliceExpr.max = max;
	return result;
}

AstNode *ast_deref_expr(AstFile *f, AstNode *expr, Token op) {
	AstNode *result = make_ast_node(f, AstNode_DerefExpr);
	result->DerefExpr.expr = expr;
	result->DerefExpr.op = op;
	return result;
}




AstNode *ast_ident(AstFile *f, Token token) {
	AstNode *result = make_ast_node(f, AstNode_Ident);
	result->Ident = token;
	return result;
}

AstNode *ast_implicit(AstFile *f, Token token) {
	AstNode *result = make_ast_node(f, AstNode_Implicit);
	result->Implicit = token;
	return result;
}


AstNode *ast_basic_lit(AstFile *f, Token basic_lit) {
	AstNode *result = make_ast_node(f, AstNode_BasicLit);
	result->BasicLit = basic_lit;
	return result;
}

AstNode *ast_basic_directive(AstFile *f, Token token, String name) {
	AstNode *result = make_ast_node(f, AstNode_BasicDirective);
	result->BasicDirective.token = token;
	result->BasicDirective.name = name;
	return result;
}

AstNode *ast_ellipsis(AstFile *f, Token token, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_Ellipsis);
	result->Ellipsis.token = token;
	result->Ellipsis.expr = expr;
	return result;
}


AstNode *ast_proc_lit(AstFile *f, AstNode *type, AstNode *body, u64 tags, AstNode *foreign_library, String foreign_name, String link_name) {
	AstNode *result = make_ast_node(f, AstNode_ProcLit);
	result->ProcLit.type = type;
	result->ProcLit.body = body;
	result->ProcLit.tags = tags;
	result->ProcLit.foreign_library = foreign_library;
	result->ProcLit.foreign_name = foreign_name;
	result->ProcLit.link_name = link_name;
	return result;
}

AstNode *ast_field_value(AstFile *f, AstNode *field, AstNode *value, Token eq) {
	AstNode *result = make_ast_node(f, AstNode_FieldValue);
	result->FieldValue.field = field;
	result->FieldValue.value = value;
	result->FieldValue.eq = eq;
	return result;
}

AstNode *ast_compound_lit(AstFile *f, AstNode *type, AstNodeArray elems, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_CompoundLit);
	result->CompoundLit.type = type;
	result->CompoundLit.elems = elems;
	result->CompoundLit.open = open;
	result->CompoundLit.close = close;
	return result;
}
AstNode *ast_alias(AstFile *f, Token token, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_Alias);
	result->Alias.token = token;
	result->Alias.expr  = expr;
	return result;
}


AstNode *ast_ternary_expr(AstFile *f, AstNode *cond, AstNode *x, AstNode *y) {
	AstNode *result = make_ast_node(f, AstNode_TernaryExpr);
	result->TernaryExpr.cond = cond;
	result->TernaryExpr.x = x;
	result->TernaryExpr.y = y;
	return result;
}
AstNode *ast_type_assertion(AstFile *f, AstNode *expr, Token dot, AstNode *type) {
	AstNode *result = make_ast_node(f, AstNode_TypeAssertion);
	result->TypeAssertion.expr = expr;
	result->TypeAssertion.dot  = dot;
	result->TypeAssertion.type = type;
	return result;
}




AstNode *ast_bad_stmt(AstFile *f, Token begin, Token end) {
	AstNode *result = make_ast_node(f, AstNode_BadStmt);
	result->BadStmt.begin = begin;
	result->BadStmt.end   = end;
	return result;
}

AstNode *ast_empty_stmt(AstFile *f, Token token) {
	AstNode *result = make_ast_node(f, AstNode_EmptyStmt);
	result->EmptyStmt.token = token;
	return result;
}

AstNode *ast_expr_stmt(AstFile *f, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_ExprStmt);
	result->ExprStmt.expr = expr;
	return result;
}

AstNode *ast_assign_stmt(AstFile *f, Token op, AstNodeArray lhs, AstNodeArray rhs) {
	AstNode *result = make_ast_node(f, AstNode_AssignStmt);
	result->AssignStmt.op = op;
	result->AssignStmt.lhs = lhs;
	result->AssignStmt.rhs = rhs;
	return result;
}


AstNode *ast_inc_dec_stmt(AstFile *f, Token op, AstNode *expr) {
	AstNode *result = make_ast_node(f, AstNode_IncDecStmt);
	result->IncDecStmt.op = op;
	result->IncDecStmt.expr = expr;
	return result;
}



AstNode *ast_block_stmt(AstFile *f, AstNodeArray stmts, Token open, Token close) {
	AstNode *result = make_ast_node(f, AstNode_BlockStmt);
	result->BlockStmt.stmts = stmts;
	result->BlockStmt.open = open;
	result->BlockStmt.close = close;
	return result;
}

AstNode *ast_if_stmt(AstFile *f, Token token, AstNode *init, AstNode *cond, AstNode *body, AstNode *else_stmt) {
	AstNode *result = make_ast_node(f, AstNode_IfStmt);
	result->IfStmt.token = token;
	result->IfStmt.init = init;
	result->IfStmt.cond = cond;
	result->IfStmt.body = body;
	result->IfStmt.else_stmt = else_stmt;
	return result;
}

AstNode *ast_when_stmt(AstFile *f, Token token, AstNode *cond, AstNode *body, AstNode *else_stmt) {
	AstNode *result = make_ast_node(f, AstNode_WhenStmt);
	result->WhenStmt.token = token;
	result->WhenStmt.cond = cond;
	result->WhenStmt.body = body;
	result->WhenStmt.else_stmt = else_stmt;
	return result;
}


AstNode *ast_return_stmt(AstFile *f, Token token, AstNodeArray results) {
	AstNode *result = make_ast_node(f, AstNode_ReturnStmt);
	result->ReturnStmt.token = token;
	result->ReturnStmt.results = results;
	return result;
}


AstNode *ast_for_stmt(AstFile *f, Token token, AstNode *init, AstNode *cond, AstNode *post, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_ForStmt);
	result->ForStmt.token = token;
	result->ForStmt.init  = init;
	result->ForStmt.cond  = cond;
	result->ForStmt.post  = post;
	result->ForStmt.body  = body;
	return result;
}

AstNode *ast_range_stmt(AstFile *f, Token token, AstNode *value, AstNode *index, Token in_token, AstNode *expr, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_RangeStmt);
	result->RangeStmt.token = token;
	result->RangeStmt.value = value;
	result->RangeStmt.index = index;
	result->RangeStmt.in_token = in_token;
	result->RangeStmt.expr  = expr;
	result->RangeStmt.body  = body;
	return result;
}

AstNode *ast_match_stmt(AstFile *f, Token token, AstNode *init, AstNode *tag, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_MatchStmt);
	result->MatchStmt.token = token;
	result->MatchStmt.init  = init;
	result->MatchStmt.tag   = tag;
	result->MatchStmt.body  = body;
	return result;
}


AstNode *ast_type_match_stmt(AstFile *f, Token token, AstNode *tag, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_TypeMatchStmt);
	result->TypeMatchStmt.token = token;
	result->TypeMatchStmt.tag   = tag;
	result->TypeMatchStmt.body  = body;
	return result;
}

AstNode *ast_case_clause(AstFile *f, Token token, AstNodeArray list, AstNodeArray stmts) {
	AstNode *result = make_ast_node(f, AstNode_CaseClause);
	result->CaseClause.token = token;
	result->CaseClause.list  = list;
	result->CaseClause.stmts = stmts;
	return result;
}


AstNode *ast_defer_stmt(AstFile *f, Token token, AstNode *stmt) {
	AstNode *result = make_ast_node(f, AstNode_DeferStmt);
	result->DeferStmt.token = token;
	result->DeferStmt.stmt = stmt;
	return result;
}

AstNode *ast_branch_stmt(AstFile *f, Token token, AstNode *label) {
	AstNode *result = make_ast_node(f, AstNode_BranchStmt);
	result->BranchStmt.token = token;
	result->BranchStmt.label = label;
	return result;
}

AstNode *ast_using_stmt(AstFile *f, Token token, AstNodeArray list) {
	AstNode *result = make_ast_node(f, AstNode_UsingStmt);
	result->UsingStmt.token = token;
	result->UsingStmt.list  = list;
	return result;
}


AstNode *ast_asm_operand(AstFile *f, Token string, AstNode *operand) {
	AstNode *result = make_ast_node(f, AstNode_AsmOperand);
	result->AsmOperand.string  = string;
	result->AsmOperand.operand = operand;
	return result;

}

AstNode *ast_asm_stmt(AstFile *f, Token token, bool is_volatile, Token open, Token close, Token code_string,
                                 AstNode *output_list, AstNode *input_list, AstNode *clobber_list,
                                 isize output_count, isize input_count, isize clobber_count) {
	AstNode *result = make_ast_node(f, AstNode_AsmStmt);
	result->AsmStmt.token = token;
	result->AsmStmt.is_volatile = is_volatile;
	result->AsmStmt.open  = open;
	result->AsmStmt.close = close;
	result->AsmStmt.code_string = code_string;
	result->AsmStmt.output_list = output_list;
	result->AsmStmt.input_list = input_list;
	result->AsmStmt.clobber_list = clobber_list;
	result->AsmStmt.output_count = output_count;
	result->AsmStmt.input_count = input_count;
	result->AsmStmt.clobber_count = clobber_count;
	return result;
}

AstNode *ast_push_allocator(AstFile *f, Token token, AstNode *expr, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_PushAllocator);
	result->PushAllocator.token = token;
	result->PushAllocator.expr = expr;
	result->PushAllocator.body = body;
	return result;
}

AstNode *ast_push_context(AstFile *f, Token token, AstNode *expr, AstNode *body) {
	AstNode *result = make_ast_node(f, AstNode_PushContext);
	result->PushContext.token = token;
	result->PushContext.expr = expr;
	result->PushContext.body = body;
	return result;
}




AstNode *ast_bad_decl(AstFile *f, Token begin, Token end) {
	AstNode *result = make_ast_node(f, AstNode_BadDecl);
	result->BadDecl.begin = begin;
	result->BadDecl.end = end;
	return result;
}

AstNode *ast_field(AstFile *f, AstNodeArray names, AstNode *type, u32 flags) {
	AstNode *result = make_ast_node(f, AstNode_Field);
	result->Field.names = names;
	result->Field.type = type;
	result->Field.flags = flags;
	return result;
}

AstNode *ast_field_list(AstFile *f, Token token, AstNodeArray list) {
	AstNode *result = make_ast_node(f, AstNode_FieldList);
	result->FieldList.token = token;
	result->FieldList.list  = list;
	return result;
}
AstNode *ast_union_field(AstFile *f, AstNode *name, AstNode *list) {
	AstNode *result = make_ast_node(f, AstNode_UnionField);
	result->UnionField.name = name;
	result->UnionField.list = list;
	return result;
}


AstNode *ast_helper_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_ast_node(f, AstNode_HelperType);
	result->HelperType.token = token;
	result->HelperType.type = type;
	return result;
}


AstNode *ast_proc_type(AstFile *f, Token token, AstNode *params, AstNode *results, u64 tags, ProcCallingConvention calling_convention) {
	AstNode *result = make_ast_node(f, AstNode_ProcType);
	result->ProcType.token = token;
	result->ProcType.params = params;
	result->ProcType.results = results;
	result->ProcType.tags = tags;
	result->ProcType.calling_convention = calling_convention;
	return result;
}

AstNode *ast_pointer_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_ast_node(f, AstNode_PointerType);
	result->PointerType.token = token;
	result->PointerType.type = type;
	return result;
}

AstNode *ast_atomic_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_ast_node(f, AstNode_AtomicType);
	result->AtomicType.token = token;
	result->AtomicType.type = type;
	return result;
}

AstNode *ast_array_type(AstFile *f, Token token, AstNode *count, AstNode *elem) {
	AstNode *result = make_ast_node(f, AstNode_ArrayType);
	result->ArrayType.token = token;
	result->ArrayType.count = count;
	result->ArrayType.elem = elem;
	return result;
}

AstNode *ast_dynamic_array_type(AstFile *f, Token token, AstNode *elem) {
	AstNode *result = make_ast_node(f, AstNode_DynamicArrayType);
	result->DynamicArrayType.token = token;
	result->DynamicArrayType.elem  = elem;
	return result;
}

AstNode *ast_vector_type(AstFile *f, Token token, AstNode *count, AstNode *elem) {
	AstNode *result = make_ast_node(f, AstNode_VectorType);
	result->VectorType.token = token;
	result->VectorType.count = count;
	result->VectorType.elem  = elem;
	return result;
}

AstNode *ast_struct_type(AstFile *f, Token token, AstNodeArray fields, isize field_count,
                         bool is_packed, bool is_ordered, AstNode *align) {
	AstNode *result = make_ast_node(f, AstNode_StructType);
	result->StructType.token       = token;
	result->StructType.fields      = fields;
	result->StructType.field_count = field_count;
	result->StructType.is_packed   = is_packed;
	result->StructType.is_ordered  = is_ordered;
	result->StructType.align       = align;
	return result;
}


AstNode *ast_union_type(AstFile *f, Token token, AstNodeArray fields, isize field_count, AstNodeArray variants) {
	AstNode *result = make_ast_node(f, AstNode_UnionType);
	result->UnionType.token = token;
	result->UnionType.fields = fields;
	result->UnionType.field_count = field_count;
	result->UnionType.variants = variants;
	return result;
}

AstNode *ast_raw_union_type(AstFile *f, Token token, AstNodeArray fields, isize field_count) {
	AstNode *result = make_ast_node(f, AstNode_RawUnionType);
	result->RawUnionType.token = token;
	result->RawUnionType.fields = fields;
	result->RawUnionType.field_count = field_count;
	return result;
}


AstNode *ast_enum_type(AstFile *f, Token token, AstNode *base_type, AstNodeArray fields) {
	AstNode *result = make_ast_node(f, AstNode_EnumType);
	result->EnumType.token = token;
	result->EnumType.base_type = base_type;
	result->EnumType.fields = fields;
	return result;
}

AstNode *ast_map_type(AstFile *f, Token token, AstNode *count, AstNode *key, AstNode *value) {
	AstNode *result = make_ast_node(f, AstNode_MapType);
	result->MapType.token = token;
	result->MapType.count = count;
	result->MapType.key   = key;
	result->MapType.value = value;
	return result;
}


AstNode *ast_value_decl(AstFile *f, bool is_var, AstNodeArray names, AstNode *type, AstNodeArray values) {
	AstNode *result = make_ast_node(f, AstNode_ValueDecl);
	result->ValueDecl.is_var = is_var;
	result->ValueDecl.names  = names;
	result->ValueDecl.type   = type;
	result->ValueDecl.values = values;
	return result;
}


AstNode *ast_import_decl(AstFile *f, Token token, bool is_import, Token relpath, Token import_name, AstNode *cond) {
	AstNode *result = make_ast_node(f, AstNode_ImportDecl);
	result->ImportDecl.token = token;
	result->ImportDecl.is_import = is_import;
	result->ImportDecl.relpath = relpath;
	result->ImportDecl.import_name = import_name;
	result->ImportDecl.cond = cond;
	return result;
}

AstNode *ast_foreign_library(AstFile *f, Token token, Token filepath, Token library_name, AstNode *cond, bool is_system) {
	AstNode *result = make_ast_node(f, AstNode_ForeignLibrary);
	result->ForeignLibrary.token = token;
	result->ForeignLibrary.filepath = filepath;
	result->ForeignLibrary.library_name = library_name;
	result->ForeignLibrary.cond = cond;
	result->ForeignLibrary.is_system = is_system;
	return result;
}

AstNode *ast_label_decl(AstFile *f, Token token, AstNode *name) {
	AstNode *result = make_ast_node(f, AstNode_Label);
	result->Label.token = token;
	result->Label.name  = name;
	return result;
}


bool next_token(AstFile *f) {
	Token prev = f->curr_token;
	if (f->curr_token_index+1 < f->tokens.count) {
		if (f->curr_token.kind != Token_Comment) {
			f->prev_token = f->curr_token;
		}

		f->curr_token_index++;
		f->curr_token = f->tokens.e[f->curr_token_index];
		if (f->curr_token.kind == Token_Comment) {
			return next_token(f);
		}
		return true;
	}
	syntax_error(f->curr_token, "Token is EOF");
	return false;
}

TokenKind look_ahead_token_kind(AstFile *f, isize amount) {
	GB_ASSERT(amount > 0);

	TokenKind kind = Token_Invalid;
	isize index = f->curr_token_index;
	while (amount > 0) {
		index++;
		kind = f->tokens.e[index].kind;
		if (kind != Token_Comment) {
			amount--;
		}
	}
	return kind;
}

Token expect_token(AstFile *f, TokenKind kind) {
	Token prev = f->curr_token;
	if (prev.kind != kind) {
		String p = token_strings[prev.kind];
		syntax_error(f->curr_token, "Expected `%.*s`, got `%.*s`",
		             LIT(token_strings[kind]),
		             LIT(token_strings[prev.kind]));
		if (prev.kind == Token_EOF) {
			gb_exit(1);
		}
	}

	next_token(f);
	return prev;
}

Token expect_token_after(AstFile *f, TokenKind kind, char *msg) {
	Token prev = f->curr_token;
	if (prev.kind != kind) {
		String p = token_strings[prev.kind];
		syntax_error(f->curr_token, "Expected `%.*s` after %s, got `%.*s`",
		             LIT(token_strings[kind]),
		             msg,
		             LIT(p));
	}
	next_token(f);
	return prev;
}


Token expect_operator(AstFile *f) {
	Token prev = f->curr_token;
	if (!gb_is_between(prev.kind, Token__OperatorBegin+1, Token__OperatorEnd-1)) {
		syntax_error(f->curr_token, "Expected an operator, got `%.*s`",
		             LIT(token_strings[prev.kind]));
	} else if (!f->allow_range && (prev.kind == Token_Ellipsis || prev.kind == Token_HalfClosed)) {
		syntax_error(f->curr_token, "Expected an non-range operator, got `%.*s`",
		             LIT(token_strings[prev.kind]));
	}
	next_token(f);
	return prev;
}

Token expect_keyword(AstFile *f) {
	Token prev = f->curr_token;
	if (!gb_is_between(prev.kind, Token__KeywordBegin+1, Token__KeywordEnd-1)) {
		syntax_error(f->curr_token, "Expected a keyword, got `%.*s`",
		             LIT(token_strings[prev.kind]));
	}
	next_token(f);
	return prev;
}

bool allow_token(AstFile *f, TokenKind kind) {
	Token prev = f->curr_token;
	if (prev.kind == kind) {
		next_token(f);
		return true;
	}
	return false;
}


bool is_blank_ident(String str) {
	if (str.len == 1) {
		return str.text[0] == '_';
	}
	return false;
}


// NOTE(bill): Go to next statement to prevent numerous error messages popping up
void fix_advance_to_next_stmt(AstFile *f) {
	// TODO(bill): fix_advance_to_next_stmt
#if 1
	for (;;) {
		Token t = f->curr_token;
		switch (t.kind) {
		case Token_EOF:
		case Token_Semicolon:
			return;

		case Token_if:
		case Token_when:
		case Token_return:
		case Token_match:
		case Token_defer:
		case Token_asm:
		case Token_using:
		// case Token_thread_local:
		case Token_no_alias:
		// case Token_immutable:

		case Token_break:
		case Token_continue:
		case Token_fallthrough:

		case Token_push_allocator:
		case Token_push_context:

		case Token_Hash:
		{
			if (token_pos_eq(t.pos, f->fix_prev_pos) &&
			    f->fix_count < PARSER_MAX_FIX_COUNT) {
				f->fix_count++;
				return;
			}
			if (token_pos_cmp(f->fix_prev_pos, t.pos) < 0) {
				f->fix_prev_pos = t.pos;
				f->fix_count = 0; // NOTE(bill): Reset
				return;
			}
			// NOTE(bill): Reaching here means there is a parsing bug
		} break;
		}
		next_token(f);
	}
#endif
}

Token expect_closing(AstFile *f, TokenKind kind, String context) {
	if (f->curr_token.kind != kind &&
	    f->curr_token.kind == Token_Semicolon &&
	    str_eq(f->curr_token.string, str_lit("\n"))) {
		error(f->curr_token, "Missing `,` before newline in %.*s", LIT(context));
		next_token(f);
	}
	return expect_token(f, kind);
}

bool is_semicolon_optional_for_node(AstFile *f, AstNode *s) {
	if (s == NULL) {
		return false;
	}

	switch (s->kind) {
	case AstNode_HelperType:
		return is_semicolon_optional_for_node(f, s->HelperType.type);

	case AstNode_PointerType:
		return is_semicolon_optional_for_node(f, s->PointerType.type);

	case AstNode_AtomicType:
		return is_semicolon_optional_for_node(f, s->AtomicType.type);

	case AstNode_StructType:
	case AstNode_UnionType:
	case AstNode_RawUnionType:
	case AstNode_EnumType:
		return true;
	case AstNode_ProcLit:
		return s->ProcLit.body != NULL;

	case AstNode_ValueDecl:
		if (!s->ValueDecl.is_var) {
			if (s->ValueDecl.values.count > 0) {
				AstNode *last = s->ValueDecl.values.e[s->ValueDecl.values.count-1];
				return is_semicolon_optional_for_node(f, last);
			}
		}
		break;
	}

	return false;
}

void expect_semicolon(AstFile *f, AstNode *s) {
	if (allow_token(f, Token_Semicolon)) {
		return;
	}
	Token prev_token = f->prev_token;

	switch (f->curr_token.kind) {
	case Token_EOF:
		return;
	}

	if (s != NULL) {
		if (prev_token.pos.line != f->curr_token.pos.line) {
			if (is_semicolon_optional_for_node(f, s)) {
				return;
			}
		} else {
			// switch (s->kind) {
			// case AstNode_GiveExpr:
			// 	if (f->curr_token.kind == Token_CloseBrace) {
			// 		return;
			// 	}
			// 	break;
			// }
		}
		syntax_error(prev_token, "Expected `;` after %.*s, got %.*s",
		             LIT(ast_node_strings[s->kind]), LIT(token_strings[prev_token.kind]));
	} else {
		syntax_error(prev_token, "Expected `;`");
	}
	fix_advance_to_next_stmt(f);
}


AstNode *    parse_expr(AstFile *f, bool lhs);
AstNode *    parse_proc_type(AstFile *f, AstNode **foreign_library, String *foreign_name, String *link_name);
AstNodeArray parse_stmt_list(AstFile *f);
AstNode *    parse_stmt(AstFile *f);
AstNode *    parse_body(AstFile *f);




AstNode *parse_ident(AstFile *f) {
	Token token = f->curr_token;
	if (token.kind == Token_Ident) {
		next_token(f);
	} else {
		token.string = str_lit("_");
		expect_token(f, Token_Ident);
	}
	return ast_ident(f, token);
}

AstNode *parse_tag_expr(AstFile *f, AstNode *expression) {
	Token token = expect_token(f, Token_Hash);
	Token name  = expect_token(f, Token_Ident);
	return ast_tag_expr(f, token, name, expression);
}

AstNode *unparen_expr(AstNode *node) {
	for (;;) {
		if (node == NULL) {
			return NULL;
		}
		if (node->kind != AstNode_ParenExpr) {
			return node;
		}
		node = node->ParenExpr.expr;
	}
}

AstNode *parse_value(AstFile *f);

AstNodeArray parse_element_list(AstFile *f) {
	AstNodeArray elems = make_ast_node_array(f);

	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		AstNode *elem = parse_value(f);
		if (f->curr_token.kind == Token_Eq) {
			Token eq = expect_token(f, Token_Eq);
			AstNode *value = parse_value(f);
			elem = ast_field_value(f, elem, value, eq);
		}

		array_add(&elems, elem);

		if (!allow_token(f, Token_Comma)) {
			break;
		}
	}

	return elems;
}

AstNode *parse_literal_value(AstFile *f, AstNode *type) {
	AstNodeArray elems = {0};
	Token open = expect_token(f, Token_OpenBrace);
	f->expr_level++;
	if (f->curr_token.kind != Token_CloseBrace) {
		elems = parse_element_list(f);
	}
	f->expr_level--;
	Token close = expect_closing(f, Token_CloseBrace, str_lit("compound literal"));

	return ast_compound_lit(f, type, elems, open, close);
}

AstNode *parse_value(AstFile *f) {
	if (f->curr_token.kind == Token_OpenBrace) {
		return parse_literal_value(f, NULL);
	}

	AstNode *value = parse_expr(f, false);
	return value;
}

AstNode *parse_type_or_ident(AstFile *f);


void check_proc_add_tag(AstFile *f, AstNode *tag_expr, u64 *tags, ProcTag tag, String tag_name) {
	if (*tags & tag) {
		syntax_error_node(tag_expr, "Procedure tag already used: %.*s", LIT(tag_name));
	}
	*tags |= tag;
}

bool is_foreign_name_valid(String name) {
	// TODO(bill): is_foreign_name_valid
	if (name.len == 0)
		return false;
	isize offset = 0;
	while (offset < name.len) {
		Rune rune;
		isize remaining = name.len - offset;
		isize width = gb_utf8_decode(name.text+offset, remaining, &rune);
		if (rune == GB_RUNE_INVALID && width == 1) {
			return false;
		} else if (rune == GB_RUNE_BOM && remaining > 0) {
			return false;
		}

		if (offset == 0) {
			switch (rune) {
			case '-':
			case '$':
			case '.':
			case '_':
				break;
			default:
				if (!gb_char_is_alpha(cast(char)rune))
					return false;
				break;
			}
		} else {
			switch (rune) {
			case '-':
			case '$':
			case '.':
			case '_':
				break;
			default:
				if (!gb_char_is_alphanumeric(cast(char)rune)) {
					return false;
				}
				break;
			}
		}

		offset += width;
	}

	return true;
}

void parse_proc_tags(AstFile *f, u64 *tags, AstNode **foreign_library_token, String *foreign_name, String *link_name, ProcCallingConvention *calling_convention) {
	// TODO(bill): Add this to procedure literals too
	GB_ASSERT(tags         != NULL);
	GB_ASSERT(link_name    != NULL);
	GB_ASSERT(link_name    != NULL);

	ProcCallingConvention cc = ProcCC_Invalid;

	while (f->curr_token.kind == Token_Hash) {
		AstNode *tag_expr = parse_tag_expr(f, NULL);
		ast_node(te, TagExpr, tag_expr);
		String tag_name = te->name.string;

		#define ELSE_IF_ADD_TAG(name) \
		else if (str_eq(tag_name, str_lit(#name))) { \
			check_proc_add_tag(f, tag_expr, tags, ProcTag_##name, tag_name); \
		}

		if (str_eq(tag_name, str_lit("foreign"))) {
			check_proc_add_tag(f, tag_expr, tags, ProcTag_foreign, tag_name);
			*foreign_library_token = parse_ident(f);
			if (f->curr_token.kind == Token_String) {
				*foreign_name = f->curr_token.string;
				// TODO(bill): Check if valid string
				if (!is_foreign_name_valid(*foreign_name)) {
					syntax_error_node(tag_expr, "Invalid alternative foreign procedure name: `%.*s`", LIT(*foreign_name));
				}

				next_token(f);
			}
		} else if (str_eq(tag_name, str_lit("link_name"))) {
			check_proc_add_tag(f, tag_expr, tags, ProcTag_link_name, tag_name);
			if (f->curr_token.kind == Token_String) {
				*link_name = f->curr_token.string;
				// TODO(bill): Check if valid string
				if (!is_foreign_name_valid(*link_name)) {
					syntax_error_node(tag_expr, "Invalid alternative link procedure name `%.*s`", LIT(*link_name));
				}

				next_token(f);
			} else {
				expect_token(f, Token_String);
			}
		}
		ELSE_IF_ADD_TAG(require_results)
		ELSE_IF_ADD_TAG(export)
		ELSE_IF_ADD_TAG(bounds_check)
		ELSE_IF_ADD_TAG(no_bounds_check)
		ELSE_IF_ADD_TAG(inline)
		ELSE_IF_ADD_TAG(no_inline)
		// ELSE_IF_ADD_TAG(dll_import)
		// ELSE_IF_ADD_TAG(dll_export)
		else if (str_eq(tag_name, str_lit("cc_odin"))) {
			if (cc == ProcCC_Invalid) {
				cc = ProcCC_Odin;
			} else {
				syntax_error_node(tag_expr, "Multiple calling conventions for procedure type");
			}
		} else if (str_eq(tag_name, str_lit("cc_c"))) {
			if (cc == ProcCC_Invalid) {
				cc = ProcCC_C;
			} else {
				syntax_error_node(tag_expr, "Multiple calling conventions for procedure type");
			}
		} else if (str_eq(tag_name, str_lit("cc_std"))) {
			if (cc == ProcCC_Invalid) {
				cc = ProcCC_Std;
			} else {
				syntax_error_node(tag_expr, "Multiple calling conventions for procedure type");
			}
		} else if (str_eq(tag_name, str_lit("cc_fast"))) {
			if (cc == ProcCC_Invalid) {
				cc = ProcCC_Fast;
			} else {
				syntax_error_node(tag_expr, "Multiple calling conventions for procedure type");
			}
		} else {
			syntax_error_node(tag_expr, "Unknown procedure tag #%.*s\n", LIT(tag_name));
		}

		#undef ELSE_IF_ADD_TAG
	}

	if (cc == ProcCC_Invalid) {
		if ((*tags) & ProcTag_foreign) {
			cc = ProcCC_C;
		} else {
			cc = ProcCC_Odin;
		}
	}

	if (calling_convention) {
		*calling_convention = cc;
	}

	if ((*tags & ProcTag_foreign) && (*tags & ProcTag_export)) {
		syntax_error(f->curr_token, "You cannot apply both #foreign and #export to a procedure");
	}

	if ((*tags & ProcTag_inline) && (*tags & ProcTag_no_inline)) {
		syntax_error(f->curr_token, "You cannot apply both #inline and #no_inline to a procedure");
	}

	if ((*tags & ProcTag_bounds_check) && (*tags & ProcTag_no_bounds_check)) {
		syntax_error(f->curr_token, "You cannot apply both #bounds_check and #no_bounds_check to a procedure");
	}

	if (((*tags & ProcTag_bounds_check) || (*tags & ProcTag_no_bounds_check)) && (*tags & ProcTag_foreign)) {
		syntax_error(f->curr_token, "You cannot apply both #bounds_check or #no_bounds_check to a procedure without a body");
	}
}

AstNodeArray parse_lhs_expr_list(AstFile *f);
AstNodeArray parse_rhs_expr_list(AstFile *f);
AstNode *    parse_simple_stmt  (AstFile *f, bool in_stmt_ok);
AstNode *    parse_type         (AstFile *f);

AstNode *convert_stmt_to_expr(AstFile *f, AstNode *statement, String kind) {
	if (statement == NULL) {
		return NULL;
	}

	if (statement->kind == AstNode_ExprStmt) {
		return statement->ExprStmt.expr;
	}

	syntax_error(f->curr_token, "Expected `%.*s`, found a simple statement.", LIT(kind));
	return ast_bad_expr(f, f->curr_token, f->tokens.e[f->curr_token_index+1]);
}



// AstNode *parse_block_expr(AstFile *f) {
// 	AstNodeArray stmts = {0};
// 	Token open, close;
// 	open = expect_token(f, Token_OpenBrace);
// 	f->expr_level++;
// 	stmts = parse_stmt_list(f);
// 	f->expr_level--;
// 	close = expect_token(f, Token_CloseBrace);
// 	return ast_block_expr(f, stmts, open, close);
// }

// AstNode *parse_if_expr(AstFile *f) {
// 	if (f->curr_proc == NULL) {
// 		syntax_error(f->curr_token, "You cannot use an if expression in the file scope");
// 		return ast_bad_stmt(f, f->curr_token, f->curr_token);
// 	}

// 	Token token = expect_token(f, Token_if);
// 	AstNode *init = NULL;
// 	AstNode *cond = NULL;
// 	AstNode *body = NULL;
// 	AstNode *else_expr = NULL;

// 	isize prev_level = f->expr_level;
// 	f->expr_level = -1;

// 	if (allow_token(f, Token_Semicolon)) {
// 		cond = parse_expr(f, false);
// 	} else {
// 		init = parse_simple_stmt(f, false);
// 		if (allow_token(f, Token_Semicolon)) {
// 			cond = parse_expr(f, false);
// 		} else {
// 			cond = convert_stmt_to_expr(f, init, str_lit("boolean expression"));
// 			init = NULL;
// 		}
// 	}

// 	f->expr_level = prev_level;

// 	if (cond == NULL) {
// 		syntax_error(f->curr_token, "Expected condition for if statement");
// 	}

// 	body = parse_block_expr(f);

// 	if (allow_token(f, Token_else)) {
// 		switch (f->curr_token.kind) {
// 		case Token_if:
// 			else_expr = parse_if_expr(f);
// 			break;
// 		case Token_OpenBrace:
// 			else_expr = parse_block_expr(f);
// 			break;
// 		default:
// 			syntax_error(f->curr_token, "Expected if expression block statement");
// 			else_expr = ast_bad_expr(f, f->curr_token, f->tokens.e[f->curr_token_index+1]);
// 			break;
// 		}
// 	} else {
// 		syntax_error(f->curr_token, "An if expression must have an else clause");
// 		return ast_bad_stmt(f, f->curr_token, f->tokens.e[f->curr_token_index+1]);
// 	}

// 	return ast_if_expr(f, token, init, cond, body, else_expr);
// }

AstNode *parse_operand(AstFile *f, bool lhs) {
	AstNode *operand = NULL; // Operand
	switch (f->curr_token.kind) {
	case Token_Ident:
		return parse_ident(f);

	case Token_context:
		return ast_implicit(f, expect_token(f, Token_context));

	case Token_Integer:
	case Token_Float:
	case Token_Imag:
	case Token_Rune:
		operand = ast_basic_lit(f, f->curr_token);
		next_token(f);
		return operand;

	case Token_String: {
		Token token = f->curr_token;
		next_token(f);
		if (f->curr_token.kind == Token_String) {
			// NOTE(bill): Allow neighbouring string literals to be merge together to
			// become one big string
			String s = f->curr_token.string;
			Array(u8) data;
			array_init_reserve(&data, heap_allocator(), token.string.len+s.len);
			gb_memmove(data.e, token.string.text, token.string.len);
			data.count += token.string.len;

			while (f->curr_token.kind == Token_String) {
				String s = f->curr_token.string;
				isize old_count = data.count;
				array_resize(&data, data.count + s.len);
				gb_memmove(data.e+old_count, s.text, s.len);
				next_token(f);
			}

			token.string = make_string(data.e, data.count);
			array_add(&f->tokenizer.allocated_strings, token.string);
		}

		return ast_basic_lit(f, token);
	}


	case Token_OpenParen: {
		Token open, close;
		// NOTE(bill): Skip the Paren Expression
		open = expect_token(f, Token_OpenParen);
		f->expr_level++;
		operand = parse_expr(f, false);
		f->expr_level--;
		close = expect_token(f, Token_CloseParen);
		return ast_paren_expr(f, operand, open, close);
	}

	case Token_Hash: {
		Token token = expect_token(f, Token_Hash);
		Token name  = expect_token(f, Token_Ident);
		if (str_eq(name.string, str_lit("run"))) {
			AstNode *expr = parse_expr(f, false);
			operand = ast_run_expr(f, token, name, expr);
			if (unparen_expr(expr)->kind != AstNode_CallExpr) {
				error_node(expr, "#run can only be applied to procedure calls");
				operand = ast_bad_expr(f, token, f->curr_token);
			}
			warning(token, "#run is not yet implemented");
		} else if (str_eq(name.string, str_lit("file"))) { return ast_basic_directive(f, token, name.string);
		} else if (str_eq(name.string, str_lit("line"))) { return ast_basic_directive(f, token, name.string);
		} else if (str_eq(name.string, str_lit("procedure"))) { return ast_basic_directive(f, token, name.string);
		} else if (str_eq(name.string, str_lit("type"))) { return ast_helper_type(f, token, parse_type(f));
		} else if (!lhs && str_eq(name.string, str_lit("alias"))) { return ast_alias(f, token, parse_expr(f, false));
		} else {
			operand = ast_tag_expr(f, token, name, parse_expr(f, false));
		}
		return operand;
	}

	// Parse Procedure Type or Literal
	case Token_proc: {
		Token token = f->curr_token;
		AstNode *foreign_library = NULL;
		String foreign_name = {0};
		String link_name = {0};
		AstNode *type = parse_proc_type(f, &foreign_library, &foreign_name, &link_name);
		u64 tags = type->ProcType.tags;

		if (f->curr_token.kind == Token_OpenBrace) {
			if ((tags & ProcTag_foreign) != 0) {
				syntax_error(token, "A procedure tagged as `#foreign` cannot have a body");
			}
			AstNode *curr_proc = f->curr_proc;
			AstNode *body = NULL;
			f->curr_proc = type;
			body = parse_body(f);
			f->curr_proc = curr_proc;

			return ast_proc_lit(f, type, body, tags, foreign_library, foreign_name, link_name);
		}

		if ((tags & ProcTag_foreign) != 0) {
			return ast_proc_lit(f, type, NULL, tags, foreign_library, foreign_name, link_name);
		}
		if (tags != 0) {
			syntax_error(token, "A procedure type cannot have tags");
		}

		return type;
	}

	default: {
		AstNode *type = parse_type_or_ident(f);
		if (type != NULL) {
			// TODO(bill): Is this correct???
			// NOTE(bill): Sanity check as identifiers should be handled already
			TokenPos pos = ast_node_token(type).pos;
			GB_ASSERT_MSG(type->kind != AstNode_Ident, "Type cannot be identifier %.*s(%td:%td)", LIT(pos.file), pos.line, pos.column);
			return type;
		}
		break;
	}
	}

	return NULL;
}

bool is_literal_type(AstNode *node) {
	node = unparen_expr(node);
	switch (node->kind) {
	case AstNode_BadExpr:
	case AstNode_Ident:
	case AstNode_SelectorExpr:
	case AstNode_ArrayType:
	case AstNode_VectorType:
	case AstNode_StructType:
	case AstNode_DynamicArrayType:
	case AstNode_MapType:
		return true;
	}
	return false;
}

AstNode *parse_call_expr(AstFile *f, AstNode *operand) {
	AstNodeArray args = make_ast_node_array(f);
	Token open_paren, close_paren;
	Token ellipsis = {0};

	f->expr_level++;
	open_paren = expect_token(f, Token_OpenParen);

	while (f->curr_token.kind != Token_CloseParen &&
	       f->curr_token.kind != Token_EOF &&
	       ellipsis.pos.line == 0) {
		if (f->curr_token.kind == Token_Comma) {
			syntax_error(f->curr_token, "Expected an expression not a ,");
		}

		if (f->curr_token.kind == Token_Ellipsis) {
			ellipsis = f->curr_token;
			next_token(f);
		}

		AstNode *arg = parse_expr(f, false);
		array_add(&args, arg);

		if (!allow_token(f, Token_Comma)) {
			break;
		}
	}

	f->expr_level--;
	close_paren = expect_closing(f, Token_CloseParen, str_lit("argument list"));

	return ast_call_expr(f, operand, args, open_paren, close_paren, ellipsis);
}


AstNode *parse_macro_call_expr(AstFile *f, AstNode *operand) {
	AstNodeArray args = make_ast_node_array(f);
	Token bang, open_paren, close_paren;

	bang = expect_token(f, Token_Not);

	f->expr_level++;
	open_paren = expect_token(f, Token_OpenParen);

	while (f->curr_token.kind != Token_CloseParen &&
	       f->curr_token.kind != Token_EOF) {
		if (f->curr_token.kind == Token_Comma) {
			syntax_error(f->curr_token, "Expected an expression not a ,");
		}

		AstNode *arg = parse_expr(f, false);
		array_add(&args, arg);

		if (!allow_token(f, Token_Comma)) {
			break;
		}
	}

	f->expr_level--;
	close_paren = expect_closing(f, Token_CloseParen, str_lit("argument list"));

	return ast_macro_call_expr(f, operand, bang, args, open_paren, close_paren);
}

AstNode *parse_atom_expr(AstFile *f, bool lhs) {
	AstNode *operand = parse_operand(f, lhs);
	if (operand == NULL) {
		Token begin = f->curr_token;
		syntax_error(begin, "Expected an operand");
		fix_advance_to_next_stmt(f);
		operand = ast_bad_expr(f, begin, f->curr_token);
	}

	bool loop = true;
	while (loop) {
		switch (f->curr_token.kind) {
		case Token_OpenParen:
			operand = parse_call_expr(f, operand);
			break;
		case Token_Not:
			operand = parse_macro_call_expr(f, operand);
			break;

		case Token_Period: {
			Token token = f->curr_token;
			next_token(f);
			switch (f->curr_token.kind) {
			case Token_Ident:
				operand = ast_selector_expr(f, token, operand, parse_ident(f));
				break;
			// case Token_Integer:
				// operand = ast_selector_expr(f, token, operand, parse_expr(f, lhs));
				// break;
			case Token_OpenParen: {
				Token open = expect_token(f, Token_OpenParen);
				AstNode *type = parse_type(f);
				Token close = expect_token(f, Token_CloseParen);
				operand = ast_type_assertion(f, operand, token, type);
			} break;

			default:
				syntax_error(f->curr_token, "Expected a selector");
				next_token(f);
				operand = ast_bad_expr(f, ast_node_token(operand), f->curr_token);
				// operand = ast_selector_expr(f, f->curr_token, operand, NULL);
				break;
			}
		} break;

		case Token_OpenBracket: {
			if (lhs) {
				// TODO(bill): Handle this
			}
			bool prev_allow_range = f->allow_range;
			f->allow_range = false;

			Token open = {0}, close = {0}, interval = {0};
			AstNode *indices[3] = {0};
			isize ellipsis_count = 0;
			Token ellipses[2] = {0};

			f->expr_level++;
			open = expect_token(f, Token_OpenBracket);

			if (f->curr_token.kind != Token_Ellipsis &&
			    f->curr_token.kind != Token_HalfClosed) {
				indices[0] = parse_expr(f, false);
			}
			bool is_index = true;

			while ((f->curr_token.kind == Token_Ellipsis ||
			        f->curr_token.kind == Token_HalfClosed)
			        && ellipsis_count < gb_count_of(ellipses)) {
				ellipses[ellipsis_count++] = f->curr_token;
				next_token(f);
				if (f->curr_token.kind != Token_Ellipsis &&
				    f->curr_token.kind != Token_HalfClosed &&
				    f->curr_token.kind != Token_CloseBracket &&
				    f->curr_token.kind != Token_EOF) {
					indices[ellipsis_count] = parse_expr(f, false);
				}
			}


			f->expr_level--;
			close = expect_token(f, Token_CloseBracket);

			if (ellipsis_count > 0) {
				bool index3 = false;
				if (ellipsis_count == 2) {
					index3 = true;
					// 2nd and 3rd index must be present
					if (indices[1] == NULL) {
						error(ellipses[0], "2nd index required in 3-index slice expression");
						indices[1] = ast_bad_expr(f, ellipses[0], ellipses[1]);
					}
					if (indices[2] == NULL) {
						error(ellipses[1], "3rd index required in 3-index slice expression");
						indices[2] = ast_bad_expr(f, ellipses[1], close);
					}
				}
				operand = ast_slice_expr(f, operand, open, close, ellipses[0], ellipses[1], index3, indices[0], indices[1], indices[2]);
			} else {
				operand = ast_index_expr(f, operand, indices[0], open, close);
			}

			f->allow_range = prev_allow_range;
		} break;

		case Token_Pointer: // Deference
			operand = ast_deref_expr(f, operand, expect_token(f, Token_Pointer));
			break;

		case Token_OpenBrace:
			if (!lhs && is_literal_type(operand) && f->expr_level >= 0) {
				operand = parse_literal_value(f, operand);
			} else {
				loop = false;
			}
			break;

		default:
			loop = false;
			break;
		}

		lhs = false; // NOTE(bill): 'tis not lhs anymore
	}

	return operand;
}


AstNode *parse_unary_expr(AstFile *f, bool lhs) {
	switch (f->curr_token.kind) {
	case Token_Add:
	case Token_Sub:
	case Token_Not:
	case Token_Xor:
	case Token_And: {
		Token op = f->curr_token;
		next_token(f);
		return ast_unary_expr(f, op, parse_unary_expr(f, lhs));
	} break;
	}

	return parse_atom_expr(f, lhs);
}

bool is_ast_node_a_range(AstNode *expr) {
	if (expr == NULL) {
		return false;
	}
	if (expr->kind != AstNode_BinaryExpr) {
		return false;
	}
	TokenKind op = expr->BinaryExpr.op.kind;
	switch (op) {
	case Token_Ellipsis:
	case Token_HalfClosed:
		return true;
	}
	return false;
}

// NOTE(bill): result == priority
i32 token_precedence(AstFile *f, TokenKind t) {
	switch (t) {
	case Token_Question:
		return 1;
	case Token_Ellipsis:
	case Token_HalfClosed:
		if (f->allow_range) {
			return 2;
		}
		return 0;
	case Token_CmpOr:
		return 3;
	case Token_CmpAnd:
		return 4;
	case Token_CmpEq:
	case Token_NotEq:
	case Token_Lt:
	case Token_Gt:
	case Token_LtEq:
	case Token_GtEq:
		return 5;
	case Token_Add:
	case Token_Sub:
	case Token_Or:
	case Token_Xor:
		return 6;
	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_And:
	case Token_AndNot:
	case Token_Shl:
	case Token_Shr:
		return 7;
	}
	return 0;
}

AstNode *parse_binary_expr(AstFile *f, bool lhs, i32 prec_in) {
	AstNode *expr = parse_unary_expr(f, lhs);
	for (i32 prec = token_precedence(f, f->curr_token.kind); prec >= prec_in; prec--) {
		for (;;) {
			Token op = f->curr_token;
			i32 op_prec = token_precedence(f, op.kind);
			if (op_prec != prec) {
				// NOTE(bill): This will also catch operators that are not valid "binary" operators
				break;
			}
			expect_operator(f); // NOTE(bill): error checks too

			if (op.kind == Token_Question) {
				AstNode *cond = expr;
				// Token_Question
				AstNode *x = parse_expr(f, lhs);
				Token token_c = expect_token(f, Token_Colon);
				AstNode *y = parse_expr(f, lhs);
				expr = ast_ternary_expr(f, cond, x, y);
			} else {
				AstNode *right = parse_binary_expr(f, false, prec+1);
				if (right == NULL) {
					syntax_error(op, "Expected expression on the right-hand side of the binary operator");
				}
				expr = ast_binary_expr(f, op, expr, right);
			}

			lhs = false;
		}
	}
	return expr;
}

AstNode *parse_expr(AstFile *f, bool lhs) {
	return parse_binary_expr(f, lhs, 0+1);
}


AstNodeArray parse_expr_list(AstFile *f, bool lhs) {
	AstNodeArray list = make_ast_node_array(f);
	for (;;) {
		AstNode *e = parse_expr(f, lhs);
		array_add(&list, e);
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		next_token(f);
	}

	return list;
}

AstNodeArray parse_lhs_expr_list(AstFile *f) {
	return parse_expr_list(f, true);
}

AstNodeArray parse_rhs_expr_list(AstFile *f) {
	return parse_expr_list(f, false);
}

AstNodeArray parse_ident_list(AstFile *f) {
	AstNodeArray list = make_ast_node_array(f);

	do {
		array_add(&list, parse_ident(f));
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		next_token(f);
	} while (true);

	return list;
}


AstNode *parse_type_attempt(AstFile *f) {
	AstNode *type = parse_type_or_ident(f);
	if (type != NULL) {
		// TODO(bill): Handle?
	}
	return type;
}

AstNode *parse_type(AstFile *f) {
	AstNode *type = parse_type_attempt(f);
	if (type == NULL) {
		Token token = f->curr_token;
		syntax_error(token, "Expected a type");
		next_token(f);
		return ast_bad_expr(f, token, f->curr_token);
	}
	return type;
}


AstNode *parse_value_decl(AstFile *f, AstNodeArray lhs) {
	AstNode *type = NULL;
	AstNodeArray values = {0};
	bool is_mutable = true;

	if (allow_token(f, Token_Colon)) {
		type = parse_type_attempt(f);
	} else if (f->curr_token.kind != Token_Eq &&
	           f->curr_token.kind != Token_Semicolon) {
		syntax_error(f->curr_token, "Expected a type separator `:` or `=`");
	}


	switch (f->curr_token.kind) {
	case Token_Colon:
		is_mutable = false;
		/*fallthrough*/
	case Token_Eq:
		next_token(f);
		values = parse_rhs_expr_list(f);
		if (values.count > lhs.count) {
			syntax_error(f->curr_token, "Too many values on the right hand side of the declaration");
		} else if (values.count < lhs.count && !is_mutable) {
			syntax_error(f->curr_token, "All constant declarations must be defined");
		} else if (values.count == 0) {
			syntax_error(f->curr_token, "Expected an expression for this declaration");
		}
		break;
	}

	if (is_mutable) {
		if (type == NULL && values.count == 0) {
			syntax_error(f->curr_token, "Missing variable type or initialization");
			return ast_bad_decl(f, f->curr_token, f->curr_token);
		}
	} else {
		if (type == NULL && values.count == 0 && lhs.count > 0) {
			syntax_error(f->curr_token, "Missing constant value");
			return ast_bad_decl(f, f->curr_token, f->curr_token);
		}
	}

	if (values.e == NULL) {
		values = make_ast_node_array(f);
	}

	AstNodeArray specs = {0};
	array_init_reserve(&specs, heap_allocator(), 1);
	return ast_value_decl(f, is_mutable, lhs, type, values);
}



AstNode *parse_simple_stmt(AstFile *f, bool in_stmt_ok) {
	AstNodeArray lhs = parse_lhs_expr_list(f);
	Token token = f->curr_token;
	switch (token.kind) {
	case Token_Eq:
	case Token_AddEq:
	case Token_SubEq:
	case Token_MulEq:
	case Token_QuoEq:
	case Token_ModEq:
	case Token_AndEq:
	case Token_OrEq:
	case Token_XorEq:
	case Token_ShlEq:
	case Token_ShrEq:
	case Token_AndNotEq:
	case Token_CmpAndEq:
	case Token_CmpOrEq:
	{
		if (f->curr_proc == NULL) {
			syntax_error(f->curr_token, "You cannot use a simple statement in the file scope");
			return ast_bad_stmt(f, f->curr_token, f->curr_token);
		}
		next_token(f);
		AstNodeArray rhs = parse_rhs_expr_list(f);
		if (rhs.count == 0) {
			syntax_error(token, "No right-hand side in assignment statement.");
			return ast_bad_stmt(f, token, f->curr_token);
		}
		return ast_assign_stmt(f, token, lhs, rhs);
	} break;

	case Token_in:
		if (in_stmt_ok) {
			allow_token(f, Token_in);
			bool prev_allow_range = f->allow_range;
			f->allow_range = true;
			AstNode *expr = parse_expr(f, false);
			f->allow_range = prev_allow_range;

			AstNodeArray rhs = {0};
			array_init_count(&rhs, heap_allocator(), 1);
			rhs.e[0] = expr;

			return ast_assign_stmt(f, token, lhs, rhs);
		}
		break;

	case Token_Colon:
		return parse_value_decl(f, lhs);
	}

	if (lhs.count > 1) {
		syntax_error(token, "Expected 1 expression");
		return ast_bad_stmt(f, token, f->curr_token);
	}

	switch (token.kind) {
	case Token_Inc:
	case Token_Dec:
		next_token(f);
		return ast_inc_dec_stmt(f, token, lhs.e[0]);
	}

	return ast_expr_stmt(f, lhs.e[0]);
}



AstNode *parse_block_stmt(AstFile *f, b32 is_when) {
	if (!is_when && f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a block statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}
	return parse_body(f);
}

AstNode *parse_field_list(AstFile *f, isize *name_count_, u32 allowed_flags, TokenKind follow);


AstNode *parse_results(AstFile *f) {
	if (!allow_token(f, Token_ArrowRight)) {
		return NULL;
	}

	if (f->curr_token.kind != Token_OpenParen) {
		Token begin_token = f->curr_token;
		AstNodeArray empty_names = {0};
		AstNodeArray list = make_ast_node_array(f);
		AstNode *type = parse_type(f);
		array_add(&list, ast_field(f, empty_names, type, 0));
		return ast_field_list(f, begin_token, list);
	}

	AstNode *list = NULL;
	expect_token(f, Token_OpenParen);
	list = parse_field_list(f, NULL, 0, Token_CloseParen);
	expect_token_after(f, Token_CloseParen, "parameter list");
	return list;
}

AstNode *parse_proc_type(AstFile *f, AstNode **foreign_library_, String *foreign_name_, String *link_name_) {
	AstNode *params = {0};
	AstNode *results = {0};

	Token proc_token = expect_token(f, Token_proc);
	expect_token(f, Token_OpenParen);
	params = parse_field_list(f, NULL, FieldFlag_Signature, Token_CloseParen);
	expect_token_after(f, Token_CloseParen, "parameter list");
	results = parse_results(f);

	u64 tags = 0;
	String foreign_name = {0};
	String link_name = {0};
	AstNode *foreign_library = NULL;
	ProcCallingConvention cc = ProcCC_Odin;

	parse_proc_tags(f, &tags, &foreign_library, &foreign_name, &link_name, &cc);

	if (foreign_library_) *foreign_library_ = foreign_library;
	if (foreign_name_)    *foreign_name_    = foreign_name;
	if (link_name_)       *link_name_       = link_name;

	return ast_proc_type(f, proc_token, params, results, tags, cc);
}

AstNode *parse_var_type(AstFile *f, bool allow_ellipsis) {
	if (allow_ellipsis && f->curr_token.kind == Token_Ellipsis) {
		Token tok = f->curr_token;
		next_token(f);
		AstNode *type = parse_type_or_ident(f);
		if (type == NULL) {
			error(tok, "variadic field missing type after `...`");
			type = ast_bad_expr(f, tok, f->curr_token);
		}
		return ast_ellipsis(f, tok, type);
	}
	AstNode *type = parse_type_attempt(f);
	if (type == NULL) {
		Token tok = f->curr_token;
		error(tok, "Expected a type");
		type = ast_bad_expr(f, tok, f->curr_token);
	}
	return type;
}

bool is_token_field_prefix(TokenKind kind) {
	switch (kind) {
	case Token_using:
	case Token_no_alias:
	case Token_immutable:
		return true;
	}
	return false;
}


u32 parse_field_prefixes(AstFile *f) {
	i32 using_count     = 0;
	i32 no_alias_count  = 0;
	i32 immutable_count = 0;

	while (is_token_field_prefix(f->curr_token.kind)) {
		switch (f->curr_token.kind) {
		case Token_using:     using_count     += 1; next_token(f); break;
		case Token_no_alias:  no_alias_count  += 1; next_token(f); break;
		case Token_immutable: immutable_count += 1; next_token(f); break;
		}
	}
	if (using_count     > 1) syntax_error(f->curr_token, "Multiple `using` in this field list");
	if (no_alias_count  > 1) syntax_error(f->curr_token, "Multiple `no_alias` in this field list");
	if (immutable_count > 1) syntax_error(f->curr_token, "Multiple `immutable` in this field list");


	u32 field_flags = 0;
	if (using_count     > 0) field_flags |= FieldFlag_using;
	if (no_alias_count  > 0) field_flags |= FieldFlag_no_alias;
	if (immutable_count > 0) field_flags |= FieldFlag_immutable;
	return field_flags;
}

u32 check_field_prefixes(AstFile *f, isize name_count, u32 allowed_flags, u32 set_flags) {
	if (name_count > 1 && (set_flags&FieldFlag_using)) {
		syntax_error(f->curr_token, "Cannot apply `using` to more than one of the same type");
		set_flags &= ~FieldFlag_using;
	}

	if ((allowed_flags&FieldFlag_using) == 0 && (set_flags&FieldFlag_using)) {
		syntax_error(f->curr_token, "`using` is not allowed within this field list");
		set_flags &= ~FieldFlag_using;
	}
	if ((allowed_flags&FieldFlag_no_alias) == 0 && (set_flags&FieldFlag_no_alias)) {
		syntax_error(f->curr_token, "`no_alias` is not allowed within this field list");
		set_flags &= ~FieldFlag_no_alias;
	}
	if ((allowed_flags&FieldFlag_immutable) == 0 && (set_flags&FieldFlag_immutable)) {
		syntax_error(f->curr_token, "`immutable` is not allowed within this field list");
		set_flags &= ~FieldFlag_immutable;
	}
	return set_flags;
}

typedef struct AstNodeAndFlags {
	AstNode *node;
	u32      flags;
} AstNodeAndFlags;

typedef Array(AstNodeAndFlags) AstNodeAndFlagsArray;

AstNodeArray convert_to_ident_list(AstFile *f, AstNodeAndFlagsArray list, bool ignore_flags) {
	AstNodeArray idents = {0};
	array_init_reserve(&idents, heap_allocator(), list.count);
	// Convert to ident list
	for_array(i, list) {
		AstNode *ident = list.e[i].node;

		if (!ignore_flags) {
			if (i != 0) {
				error_node(ident, "Illegal use of prefixes in parameter list");
			}
		}

		switch (ident->kind) {
		case AstNode_Ident:
		case AstNode_BadExpr:
			break;
		default:
			error_node(ident, "Expected an identifier");
			ident = ast_ident(f, blank_token);
			break;
		}
		array_add(&idents, ident);
	}
	return idents;
}


bool parse_expect_field_separator(AstFile *f, AstNode *param) {
	Token token = f->curr_token;
	if (allow_token(f, Token_Comma)) {
		return true;
	}
	if (token.kind == Token_Semicolon) {
		next_token(f);
		error(f->curr_token, "Expected a comma, got a semicolon");
		return true;
	}
	return false;
}

AstNode *parse_field_list(AstFile *f, isize *name_count_, u32 allowed_flags, TokenKind follow) {
	TokenKind separator = Token_Comma;
	Token start_token = f->curr_token;

	AstNodeArray params = make_ast_node_array(f);
	AstNodeAndFlagsArray list = {0}; array_init(&list, heap_allocator()); // LEAK(bill):
	isize total_name_count = 0;
	bool allow_ellipsis = allowed_flags&FieldFlag_ellipsis;

	while (f->curr_token.kind != follow &&
	       f->curr_token.kind != Token_Colon &&
	       f->curr_token.kind != Token_EOF) {
		u32 flags = parse_field_prefixes(f);
		AstNode *param = parse_var_type(f, allow_ellipsis);
		AstNodeAndFlags naf = {param, flags};
		array_add(&list, naf);
		if (f->curr_token.kind != Token_Comma) {
			break;
		}
		next_token(f);
	}

	if (f->curr_token.kind == Token_Colon) {
		AstNodeArray names = convert_to_ident_list(f, list, true); // Copy for semantic reasons
		if (names.count == 0) {
			syntax_error(f->curr_token, "Empty field declaration");
		}
		u32 set_flags = 0;
		if (list.count > 0) {
			set_flags = list.e[0].flags;
		}
		set_flags = check_field_prefixes(f, names.count, allowed_flags, set_flags);
		total_name_count += names.count;

		expect_token_after(f, Token_Colon, "field list");
		AstNode *type = parse_var_type(f, allow_ellipsis);
		AstNode *param = ast_field(f, names, type, set_flags);
		array_add(&params, param);

		parse_expect_field_separator(f, type);

		while (f->curr_token.kind != follow &&
		       f->curr_token.kind != Token_EOF) {
			u32 set_flags = parse_field_prefixes(f);
			AstNodeArray names = parse_ident_list(f);
			if (names.count == 0) {
				syntax_error(f->curr_token, "Empty field declaration");
				break;
			}
			set_flags = check_field_prefixes(f, names.count, allowed_flags, set_flags);
			total_name_count += names.count;

			expect_token_after(f, Token_Colon, "field list");
			AstNode *type = parse_var_type(f, allow_ellipsis);
			AstNode *param = ast_field(f, names, type, set_flags);
			array_add(&params, param);

			if (!parse_expect_field_separator(f, param)) {
				break;
			}
		}

		if (name_count_) *name_count_ = total_name_count;
		return ast_field_list(f, start_token, params);
	}

	for_array(i, list) {
		AstNodeArray names = {0};
		AstNode *type = list.e[i].node;
		Token token = blank_token;

		array_init_count(&names, heap_allocator(), 1);
		token.pos = ast_node_token(type).pos;
		names.e[0] = ast_ident(f, token);
		u32 flags = check_field_prefixes(f, list.count, allowed_flags, list.e[i].flags);

		AstNode *param = ast_field(f, names, list.e[i].node, flags);
		array_add(&params, param);
	}

	if (name_count_) *name_count_ = total_name_count;
	return ast_field_list(f, start_token, params);
}


AstNode *parse_record_fields(AstFile *f, isize *field_count_, u32 flags, String context) {
	return parse_field_list(f, field_count_, flags, Token_CloseBrace);
}

AstNode *parse_type_or_ident(AstFile *f) {
	switch (f->curr_token.kind) {
	case Token_Ident:
	{
		AstNode *e = parse_ident(f);
		while (f->curr_token.kind == Token_Period) {
			Token token = f->curr_token;
			next_token(f);
			AstNode *sel = parse_ident(f);
			e = ast_selector_expr(f, token, e, sel);
		}
		// TODO(bill): Merge type_or_ident into the general parsing for expressions
		// if (f->curr_token.kind == Token_OpenParen) {
			// HACK NOTE(bill): For type_of_val(expr) et al.
			// e = parse_call_expr(f, e);
		// }
		return e;
	}

	case Token_Hash: {
		Token hash_token = expect_token(f, Token_Hash);
		Token name = expect_token(f, Token_Ident);
		String tag = name.string;
		if (str_eq(tag, str_lit("type"))) {
			AstNode *type = parse_type(f);
			return ast_helper_type(f, hash_token, type);
		}
		syntax_error(name, "Expected `type` after #");
		return ast_bad_expr(f, hash_token, f->curr_token);
	}

	case Token_Pointer: {
		Token token = expect_token(f, Token_Pointer);
		AstNode *elem = parse_type(f);
		return ast_pointer_type(f, token, elem);
	}

	case Token_atomic: {
		Token token = expect_token(f, Token_atomic);
		AstNode *elem = parse_type(f);
		return ast_atomic_type(f, token, elem);
	}

	case Token_OpenBracket: {
		Token token = expect_token(f, Token_OpenBracket);
		AstNode *count_expr = NULL;
		bool is_vector = false;

		if (f->curr_token.kind == Token_Ellipsis) {
			count_expr = ast_unary_expr(f, expect_token(f, Token_Ellipsis), NULL);
		} else if (f->curr_token.kind == Token_vector) {
			next_token(f);
			if (f->curr_token.kind != Token_CloseBracket) {
				f->expr_level++;
				count_expr = parse_expr(f, false);
				f->expr_level--;
			} else {
				syntax_error(f->curr_token, "Vector type missing count");
			}
			is_vector = true;
		} else if (f->curr_token.kind == Token_dynamic) {
			next_token(f);
			expect_token(f, Token_CloseBracket);
			return ast_dynamic_array_type(f, token, parse_type(f));
		} else if (f->curr_token.kind != Token_CloseBracket) {
			f->expr_level++;
			count_expr = parse_expr(f, false);
			f->expr_level--;
		}
		expect_token(f, Token_CloseBracket);
		if (is_vector) {
			return ast_vector_type(f, token, count_expr, parse_type(f));
		}
		return ast_array_type(f, token, count_expr, parse_type(f));
	}

	case Token_map: {
		Token token = expect_token(f, Token_map);
		AstNode *count = NULL;
		AstNode *key   = NULL;
		AstNode *value = NULL;

		Token open  = expect_token_after(f, Token_OpenBracket, "map");
		key = parse_expr(f, true);
		if (allow_token(f, Token_Comma)) {
			count = key;
			key = parse_type(f);
		}
		Token close = expect_token(f, Token_CloseBracket);
		value = parse_type(f);

		return ast_map_type(f, token, count, key, value);
	} break;

	case Token_struct: {
		Token token = expect_token(f, Token_struct);
		bool is_packed = false;
		bool is_ordered = false;
		AstNode *align = NULL;

		isize prev_level = f->expr_level;
		f->expr_level = -1;

		while (allow_token(f, Token_Hash)) {
			Token tag = expect_token_after(f, Token_Ident, "#");
			if (str_eq(tag.string, str_lit("packed"))) {
				if (is_packed) {
					syntax_error(tag, "Duplicate struct tag `#%.*s`", LIT(tag.string));
				}
				is_packed = true;
			// } else if (str_eq(tag.string, str_lit("ordered"))) {
				// if (is_ordered) {
					// syntax_error(tag, "Duplicate struct tag `#%.*s`", LIT(tag.string));
				// }
				// is_ordered = true;
			} else if (str_eq(tag.string, str_lit("align"))) {
				if (align) {
					syntax_error(tag, "Duplicate struct tag `#%.*s`", LIT(tag.string));
				}
				align = parse_expr(f, true);
			} else {
				syntax_error(tag, "Invalid struct tag `#%.*s`", LIT(tag.string));
			}
		}

		f->expr_level = prev_level;

		if (is_packed && is_ordered) {
			syntax_error(token, "`#ordered` is not needed with `#packed` which implies ordering");
		}

		Token open = expect_token_after(f, Token_OpenBrace, "struct");
		isize decl_count = 0;
		AstNode *fields = parse_record_fields(f, &decl_count, FieldFlag_using, str_lit("struct"));
		Token close = expect_token(f, Token_CloseBrace);

		AstNodeArray decls = {0};
		if (fields != NULL) {
			GB_ASSERT(fields->kind == AstNode_FieldList);
			decls = fields->FieldList.list;
		}

		return ast_struct_type(f, token, decls, decl_count, is_packed, is_ordered, align);
	} break;

	case Token_union: {
		Token token = expect_token(f, Token_union);
		Token open = expect_token_after(f, Token_OpenBrace, "union");
		AstNodeArray decls    = make_ast_node_array(f);
		AstNodeArray variants = make_ast_node_array(f);
		isize total_decl_name_count = 0;

		while (f->curr_token.kind != Token_CloseBrace &&
		       f->curr_token.kind != Token_EOF) {
			u32 decl_flags = parse_field_prefixes(f);
			if (decl_flags != 0) {
				AstNodeArray names = parse_ident_list(f);
				if (names.count == 0) {
					syntax_error(f->curr_token, "Empty field declaration");
				}
				u32 set_flags = check_field_prefixes(f, names.count, FieldFlag_using, decl_flags);
				total_decl_name_count += names.count;
				expect_token_after(f, Token_Colon, "field list");
				AstNode *type = parse_var_type(f, false);
				array_add(&decls, ast_field(f, names, type, set_flags));
			} else {
				AstNodeArray names = parse_ident_list(f);
				if (names.count == 0) {
					break;
				}
				if (names.count > 1 || f->curr_token.kind == Token_Colon) {
					u32 set_flags = check_field_prefixes(f, names.count, FieldFlag_using, decl_flags);
					total_decl_name_count += names.count;
					expect_token_after(f, Token_Colon, "field list");
					AstNode *type = parse_var_type(f, false);
					array_add(&decls, ast_field(f, names, type, set_flags));
				} else {
					AstNode *name  = names.e[0];
					Token    open  = expect_token(f, Token_OpenBrace);
					isize decl_count = 0;
					AstNode *list  = parse_record_fields(f, &decl_count, FieldFlag_using, str_lit("union"));
					Token    close = expect_token(f, Token_CloseBrace);

					array_add(&variants, ast_union_field(f, name, list));
				}
			}
			if (f->curr_token.kind != Token_Comma) {
				break;
			}
			next_token(f);
		}

		Token close = expect_token(f, Token_CloseBrace);


		return ast_union_type(f, token, decls, total_decl_name_count, variants);
	}

	case Token_raw_union: {
		Token token = expect_token(f, Token_raw_union);
		Token open = expect_token_after(f, Token_OpenBrace, "raw_union");
		isize decl_count = 0;
		AstNode *fields = parse_record_fields(f, &decl_count, FieldFlag_using, str_lit("raw_union"));
		Token close = expect_token(f, Token_CloseBrace);

		AstNodeArray decls = {0};
		if (fields != NULL) {
			GB_ASSERT(fields->kind == AstNode_FieldList);
			decls = fields->FieldList.list;
		}

		return ast_raw_union_type(f, token, decls, decl_count);
	}

	case Token_enum: {
		Token token = expect_token(f, Token_enum);
		AstNode *base_type = NULL;
		if (f->curr_token.kind != Token_OpenBrace) {
			base_type = parse_type(f);
		}
		Token open = expect_token(f, Token_OpenBrace);

		AstNodeArray values = parse_element_list(f);
		Token close = expect_token(f, Token_CloseBrace);

		return ast_enum_type(f, token, base_type, values);
	}

	case Token_proc: {
		Token token = f->curr_token;
		AstNode *pt = parse_proc_type(f, NULL, NULL, NULL);
		if (pt->ProcType.tags != 0) {
			syntax_error(token, "A procedure type cannot have tags");
		}
		return pt;
	}

	case Token_OpenParen: {
		Token    open  = expect_token(f, Token_OpenParen);
		AstNode *type  = parse_type(f);
		Token    close = expect_token(f, Token_CloseParen);
		return ast_paren_expr(f, type, open, close);
	} break;
	}

	// No type found
	return NULL;
}


AstNode *parse_body(AstFile *f) {
	AstNodeArray stmts = {0};
	Token open, close;
	isize prev_expr_level = f->expr_level;

	// NOTE(bill): The body may be within an expression so reset to zero
	f->expr_level = 0;
	open = expect_token(f, Token_OpenBrace);
	stmts = parse_stmt_list(f);
	close = expect_token(f, Token_CloseBrace);
	f->expr_level = prev_expr_level;

	return ast_block_stmt(f, stmts, open, close);
}

AstNode *parse_if_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use an if statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_if);
	AstNode *init = NULL;
	AstNode *cond = NULL;
	AstNode *body = NULL;
	AstNode *else_stmt = NULL;

	isize prev_level = f->expr_level;
	f->expr_level = -1;

	if (allow_token(f, Token_Semicolon)) {
		cond = parse_expr(f, false);
	} else {
		init = parse_simple_stmt(f, false);
		if (allow_token(f, Token_Semicolon)) {
			cond = parse_expr(f, false);
		} else {
			cond = convert_stmt_to_expr(f, init, str_lit("boolean expression"));
			init = NULL;
		}
	}

	f->expr_level = prev_level;

	if (cond == NULL) {
		syntax_error(f->curr_token, "Expected condition for if statement");
	}

	body = parse_block_stmt(f, false);

	if (allow_token(f, Token_else)) {
		switch (f->curr_token.kind) {
		case Token_if:
			else_stmt = parse_if_stmt(f);
			break;
		case Token_OpenBrace:
			else_stmt = parse_block_stmt(f, false);
			break;
		default:
			syntax_error(f->curr_token, "Expected if statement block statement");
			else_stmt = ast_bad_stmt(f, f->curr_token, f->tokens.e[f->curr_token_index+1]);
			break;
		}
	}

	return ast_if_stmt(f, token, init, cond, body, else_stmt);
}

AstNode *parse_when_stmt(AstFile *f) {
	Token token = expect_token(f, Token_when);
	AstNode *cond = NULL;
	AstNode *body = NULL;
	AstNode *else_stmt = NULL;

	isize prev_level = f->expr_level;
	f->expr_level = -1;

	cond = parse_expr(f, false);

	f->expr_level = prev_level;

	if (cond == NULL) {
		syntax_error(f->curr_token, "Expected condition for when statement");
	}

	body = parse_block_stmt(f, true);

	if (allow_token(f, Token_else)) {
		switch (f->curr_token.kind) {
		case Token_when:
			else_stmt = parse_when_stmt(f);
			break;
		case Token_OpenBrace:
			else_stmt = parse_block_stmt(f, true);
			break;
		default:
			syntax_error(f->curr_token, "Expected when statement block statement");
			else_stmt = ast_bad_stmt(f, f->curr_token, f->tokens.e[f->curr_token_index+1]);
			break;
		}
	}

	return ast_when_stmt(f, token, cond, body, else_stmt);
}


AstNode *parse_return_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a return statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}
	if (f->expr_level > 0) {
		syntax_error(f->curr_token, "You cannot use a return statement within an expression");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_return);
	AstNodeArray results;
	if (f->curr_token.kind != Token_Semicolon && f->curr_token.kind != Token_CloseBrace) {
		results = parse_rhs_expr_list(f);
	} else {
		results = make_ast_node_array(f);
	}

	expect_semicolon(f, results.e[0]);
	return ast_return_stmt(f, token, results);
}


// AstNode *parse_give_stmt(AstFile *f) {
// 	if (f->curr_proc == NULL) {
// 		syntax_error(f->curr_token, "You cannot use a give statement in the file scope");
// 		return ast_bad_stmt(f, f->curr_token, f->curr_token);
// 	}
// 	if (f->expr_level == 0) {
// 		syntax_error(f->curr_token, "A give statement must be used within an expression");
// 		return ast_bad_stmt(f, f->curr_token, f->curr_token);
// 	}

// 	Token token = expect_token(f, Token_give);
// 	AstNodeArray results;
// 	if (f->curr_token.kind != Token_Semicolon && f->curr_token.kind != Token_CloseBrace) {
// 		results = parse_rhs_expr_list(f);
// 	} else {
// 		results = make_ast_node_array(f);
// 	}
// 	AstNode *ge = ast_give_expr(f, token, results);
// 	expect_semicolon(f, ge);
// 	return ast_expr_stmt(f, ge);
// }

AstNode *parse_for_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a for statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_for);

	AstNode *init = NULL;
	AstNode *cond = NULL;
	AstNode *post = NULL;
	AstNode *body = NULL;
	bool is_range = false;

	if (f->curr_token.kind != Token_OpenBrace) {
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		if (f->curr_token.kind != Token_Semicolon) {
			cond = parse_simple_stmt(f, true);
			if (cond->kind == AstNode_AssignStmt && cond->AssignStmt.op.kind == Token_in) {
				is_range = true;
			}
		}

		if (!is_range && f->curr_token.kind == Token_Semicolon) {
			next_token(f);
			init = cond;
			cond = NULL;
			if (f->curr_token.kind != Token_Semicolon) {
				cond = parse_simple_stmt(f, false);
			}
			expect_semicolon(f, cond);
			if (f->curr_token.kind != Token_OpenBrace) {
				post = parse_simple_stmt(f, false);
			}
		}

		f->expr_level = prev_level;
	}

	body = parse_block_stmt(f, false);

	if (is_range) {
		GB_ASSERT(cond->kind == AstNode_AssignStmt);
		Token in_token = cond->AssignStmt.op;
		AstNode *value = NULL;
		AstNode *index = NULL;
		switch (cond->AssignStmt.lhs.count) {
		case 1:
			value = cond->AssignStmt.lhs.e[0];
			break;
		case 2:
			value = cond->AssignStmt.lhs.e[0];
			index = cond->AssignStmt.lhs.e[1];
			break;
		default:
			error_node(cond, "Expected at 1 or 2 identifiers");
			return ast_bad_stmt(f, token, f->curr_token);
		}

		AstNode *rhs = NULL;
		if (cond->AssignStmt.rhs.count > 0) {
			rhs = cond->AssignStmt.rhs.e[0];
		}
		return ast_range_stmt(f, token, value, index, in_token, rhs, body);
	}

	cond = convert_stmt_to_expr(f, cond, str_lit("boolean expression"));
	return ast_for_stmt(f, token, init, cond, post, body);
}


AstNode *parse_case_clause(AstFile *f) {
	Token token = f->curr_token;
	AstNodeArray list = make_ast_node_array(f);
	if (allow_token(f, Token_case)) {
		bool prev_allow_range = f->allow_range;
		f->allow_range = true;
		list = parse_rhs_expr_list(f);
		f->allow_range = prev_allow_range;
	} else {
		expect_token(f, Token_default);
	}
	expect_token(f, Token_Colon); // TODO(bill): Is this the best syntax?
	// expect_token(f, Token_ArrowRight); // TODO(bill): Is this the best syntax?
	AstNodeArray stmts = parse_stmt_list(f);

	return ast_case_clause(f, token, list, stmts);
}


AstNode *parse_type_case_clause(AstFile *f) {
	Token token = f->curr_token;
	AstNodeArray list = make_ast_node_array(f);
	if (allow_token(f, Token_case)) {
		for (;;) {
			AstNode *t = parse_type(f);
			array_add(&list, t);
			if (f->curr_token.kind != Token_Comma ||
			    f->curr_token.kind == Token_EOF) {
			    break;
			}
			next_token(f);
		}
	} else {
		expect_token(f, Token_default);
	}
	expect_token(f, Token_Colon); // TODO(bill): Is this the best syntax?
	// expect_token(f, Token_ArrowRight); // TODO(bill): Is this the best syntax?
	AstNodeArray stmts = parse_stmt_list(f);

	return ast_case_clause(f, token, list, stmts);
}



AstNode *parse_match_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a match statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_match);
	AstNode *init = NULL;
	AstNode *tag  = NULL;
	AstNode *body = NULL;
	Token open, close;
	bool is_type_match = false;

	if (f->curr_token.kind != Token_OpenBrace) {
		isize prev_level = f->expr_level;
		f->expr_level = -1;

		tag = parse_simple_stmt(f, true);
		if (tag->kind == AstNode_AssignStmt && tag->AssignStmt.op.kind == Token_in) {
			is_type_match = true;
		} else {
			if (allow_token(f, Token_Semicolon)) {
				init = tag;
				tag = NULL;
				if (f->curr_token.kind != Token_OpenBrace) {
					tag = parse_simple_stmt(f, false);
				}
			}
		}
		f->expr_level = prev_level;
	}
	open = expect_token(f, Token_OpenBrace);
	AstNodeArray list = make_ast_node_array(f);

	while (f->curr_token.kind == Token_case ||
	       f->curr_token.kind == Token_default) {
		if (is_type_match) {
			array_add(&list, parse_type_case_clause(f));
		} else {
			array_add(&list, parse_case_clause(f));
		}
	}

	close = expect_token(f, Token_CloseBrace);

	body = ast_block_stmt(f, list, open, close);

	if (!is_type_match) {
		tag = convert_stmt_to_expr(f, tag, str_lit("match expression"));
		return ast_match_stmt(f, token, init, tag, body);
	} else {
		return ast_type_match_stmt(f, token, tag, body);
	}
}

AstNode *parse_defer_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a defer statement in the file scope");
		return ast_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_defer);
	AstNode *stmt = parse_stmt(f);
	switch (stmt->kind) {
	case AstNode_EmptyStmt:
		syntax_error(token, "Empty statement after defer (e.g. `;`)");
		break;
	case AstNode_DeferStmt:
		syntax_error(token, "You cannot defer a defer statement");
		stmt = stmt->DeferStmt.stmt;
		break;
	case AstNode_ReturnStmt:
		syntax_error(token, "You cannot a return statement");
		break;
	}

	return ast_defer_stmt(f, token, stmt);
}

AstNode *parse_asm_stmt(AstFile *f) {
	Token token = expect_token(f, Token_asm);
	bool is_volatile = false;
	Token open, close, code_string;
	open = expect_token(f, Token_OpenBrace);
	code_string = expect_token(f, Token_String);
	AstNode *output_list = NULL;
	AstNode *input_list = NULL;
	AstNode *clobber_list = NULL;
	isize output_count = 0;
	isize input_count = 0;
	isize clobber_count = 0;

	// TODO(bill): Finish asm statement and determine syntax

	// if (f->curr_token.kind != Token_CloseBrace) {
		// expect_token(f, Token_Colon);
	// }

	close = expect_token(f, Token_CloseBrace);

	return ast_asm_stmt(f, token, is_volatile, open, close, code_string,
	                     output_list, input_list, clobber_list,
	                     output_count, input_count, clobber_count);

}


AstNode *parse_stmt(AstFile *f) {
	AstNode *s = NULL;
	Token token = f->curr_token;
	switch (token.kind) {
	// Operands
	case Token_context:
	case Token_Ident:
	case Token_Integer:
	case Token_Float:
	case Token_Imag:
	case Token_Rune:
	case Token_String:
	case Token_OpenParen:
	case Token_Pointer:
	// Unary Operators
	case Token_Add:
	case Token_Sub:
	case Token_Xor:
	case Token_Not:
	case Token_And:
		s = parse_simple_stmt(f, false);
		expect_semicolon(f, s);
		return s;

	case Token_if:     return parse_if_stmt(f);
	case Token_when:   return parse_when_stmt(f);
	case Token_for:    return parse_for_stmt(f);
	case Token_match:  return parse_match_stmt(f);
	case Token_defer:  return parse_defer_stmt(f);
	case Token_asm:    return parse_asm_stmt(f);
	case Token_return: return parse_return_stmt(f);
	// case Token_give:   return parse_give_stmt(f);

	case Token_break:
	case Token_continue:
	case Token_fallthrough: {
		AstNode *label = NULL;
		next_token(f);
		if (token.kind != Token_fallthrough &&
		    f->curr_token.kind == Token_Ident) {
			label = parse_ident(f);
		}
		s = ast_branch_stmt(f, token, label);
		expect_semicolon(f, s);
		return s;
	}

	case Token_using: {
		// TODO(bill): Make using statements better
		Token token = expect_token(f, Token_using);
		AstNodeArray list = parse_lhs_expr_list(f);
		if (list.count == 0) {
			syntax_error(token, "Illegal use of `using` statement");
			expect_semicolon(f, NULL);
			return ast_bad_stmt(f, token, f->curr_token);
		}

		if (f->curr_token.kind != Token_Colon) {
			expect_semicolon(f, list.e[list.count-1]);
			return ast_using_stmt(f, token, list);
		}

		AstNode *decl = parse_value_decl(f, list);
		expect_semicolon(f, decl);

		if (decl->kind == AstNode_ValueDecl) {
			#if 1
			if (!decl->ValueDecl.is_var) {
				syntax_error(token, "`using` may not be applied to constant declarations");
				return decl;
			}
			if (f->curr_proc == NULL) {
				syntax_error(token, "`using` is not allowed at the file scope");
			} else {
				decl->ValueDecl.flags |= VarDeclFlag_using;
			}
			#else
				decl->ValueDecl.flags |= VarDeclFlag_using;
			#endif
			return decl;
		}

		syntax_error(token, "Illegal use of `using` statement");
		return ast_bad_stmt(f, token, f->curr_token);
	} break;

#if 1
	case Token_immutable: {
		Token token = expect_token(f, Token_immutable);
		AstNode *node = parse_stmt(f);

		if (node->kind == AstNode_ValueDecl) {
			if (!node->ValueDecl.is_var) {
				syntax_error(token, "`immutable` may not be applied to constant declarations");
			} else {
				node->ValueDecl.flags |= VarDeclFlag_immutable;
			}
			return node;
		}
		syntax_error(token, "`immutable` may only be applied to a variable declaration");
		return ast_bad_stmt(f, token, f->curr_token);
	} break;
#endif

	case Token_push_allocator: {
		next_token(f);
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		AstNode *expr = parse_expr(f, false);
		f->expr_level = prev_level;

		AstNode *body = parse_block_stmt(f, false);
		return ast_push_allocator(f, token, expr, body);
	} break;

	case Token_push_context: {
		next_token(f);
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		AstNode *expr = parse_expr(f, false);
		f->expr_level = prev_level;

		AstNode *body = parse_block_stmt(f, false);
		return ast_push_context(f, token, expr, body);
	} break;

	case Token_Hash: {
		AstNode *s = NULL;
		Token hash_token = expect_token(f, Token_Hash);
		Token name = expect_token(f, Token_Ident);
		String tag = name.string;

		if (str_eq(tag, str_lit("label"))) {
			AstNode *name  = parse_ident(f);
			AstNode *label = ast_label_decl(f, token, name);
			AstNode *stmt  = parse_stmt(f);

		#define _SET_LABEL(Kind_, label_) case GB_JOIN2(AstNode_, Kind_): (stmt->Kind_).label = label_; break
			switch (stmt->kind) {
			_SET_LABEL(ForStmt, label);
			_SET_LABEL(RangeStmt, label);
			_SET_LABEL(MatchStmt, label);
			_SET_LABEL(TypeMatchStmt, label);
			default:
				syntax_error(token, "#label cannot only be applied to a loop or match statement");
				break;
			}
		#undef _SET_LABEL

			return stmt;
		} else if (str_eq(tag, str_lit("import"))) {
			AstNode *cond = NULL;
			Token import_name = {0};

			switch (f->curr_token.kind) {
			case Token_Period:
				import_name = f->curr_token;
				import_name.kind = Token_Ident;
				next_token(f);
				break;
			case Token_Ident:
				import_name = f->curr_token;
				next_token(f);
				break;
			default:
				import_name.pos = f->curr_token.pos;
				break;
			}

			if (str_eq(import_name.string, str_lit("_"))) {
				syntax_error(import_name, "Illegal #import name: `_`");
			}

			Token file_path = expect_token_after(f, Token_String, "#import");
			if (allow_token(f, Token_when)) {
				cond = parse_expr(f, false);
			}

			AstNode *decl = NULL;
			if (f->curr_proc != NULL) {
				syntax_error(import_name, "You cannot use `#import` within a procedure. This must be done at the file scope");
				decl = ast_bad_decl(f, import_name, file_path);
			} else {
				decl = ast_import_decl(f, hash_token, true, file_path, import_name, cond);
			}
			expect_semicolon(f, decl);
			return decl;
		} else if (str_eq(tag, str_lit("load"))) {
			AstNode *cond = NULL;
			Token file_path = expect_token_after(f, Token_String, "#load");
			Token import_name = file_path;
			import_name.string = str_lit(".");

			if (allow_token(f, Token_when)) {
				cond = parse_expr(f, false);
			}

			AstNode *decl = NULL;
			if (f->curr_proc != NULL) {
				syntax_error(import_name, "You cannot use `#load` within a procedure. This must be done at the file scope");
				decl = ast_bad_decl(f, import_name, file_path);
			} else {
				decl = ast_import_decl(f, hash_token, false, file_path, import_name, cond);
			}
			expect_semicolon(f, decl);
			return decl;
		} else if (str_eq(tag, str_lit("shared_global_scope"))) {
			if (f->curr_proc == NULL) {
				f->is_global_scope = true;
				s = ast_empty_stmt(f, f->curr_token);
			} else {
				syntax_error(token, "You cannot use #shared_global_scope within a procedure. This must be done at the file scope");
				s = ast_bad_decl(f, token, f->curr_token);
			}
			expect_semicolon(f, s);
			return s;
		} else if (str_eq(tag, str_lit("foreign_system_library"))) {
			AstNode *cond = NULL;
			Token lib_name = {0};

			switch (f->curr_token.kind) {
			case Token_Ident:
				lib_name = f->curr_token;
				next_token(f);
				break;
			default:
				lib_name.pos = f->curr_token.pos;
				break;
			}

			if (str_eq(lib_name.string, str_lit("_"))) {
				syntax_error(lib_name, "Illegal #foreign_library name: `_`");
			}
			Token file_path = expect_token(f, Token_String);

			if (allow_token(f, Token_when)) {
				cond = parse_expr(f, false);
			}

			if (f->curr_proc == NULL) {
				s = ast_foreign_library(f, hash_token, file_path, lib_name, cond, true);
			} else {
				syntax_error(token, "You cannot use #foreign_system_library within a procedure. This must be done at the file scope");
				s = ast_bad_decl(f, token, file_path);
			}
			expect_semicolon(f, s);
			return s;
		} else if (str_eq(tag, str_lit("foreign_library"))) {
			AstNode *cond = NULL;
			Token lib_name = {0};

			switch (f->curr_token.kind) {
			case Token_Ident:
				lib_name = f->curr_token;
				next_token(f);
				break;
			default:
				lib_name.pos = f->curr_token.pos;
				break;
			}

			if (str_eq(lib_name.string, str_lit("_"))) {
				syntax_error(lib_name, "Illegal #foreign_library name: `_`");
			}
			Token file_path = expect_token(f, Token_String);

			if (allow_token(f, Token_when)) {
				cond = parse_expr(f, false);
			}

			if (f->curr_proc == NULL) {
				s = ast_foreign_library(f, hash_token, file_path, lib_name, cond, false);
			} else {
				syntax_error(token, "You cannot use #foreign_library within a procedure. This must be done at the file scope");
				s = ast_bad_decl(f, token, file_path);
			}
			expect_semicolon(f, s);
			return s;
		} else if (str_eq(tag, str_lit("thread_local"))) {
			AstNode *s = parse_stmt(f);

			if (s->kind == AstNode_ValueDecl) {
				if (!s->ValueDecl.is_var) {
					syntax_error(token, "`thread_local` may not be applied to constant declarations");
				}
				if (f->curr_proc != NULL) {
					syntax_error(token, "`thread_local` is only allowed at the file scope");
				} else {
					s->ValueDecl.flags |= VarDeclFlag_thread_local;
				}
				return s;
			}
			syntax_error(token, "`thread_local` may only be applied to a variable declaration");
			return ast_bad_stmt(f, token, f->curr_token);
		} else if (str_eq(tag, str_lit("bounds_check"))) {
			s = parse_stmt(f);
			s->stmt_state_flags |= StmtStateFlag_bounds_check;
			if ((s->stmt_state_flags & StmtStateFlag_no_bounds_check) != 0) {
				syntax_error(token, "#bounds_check and #no_bounds_check cannot be applied together");
			}
			return s;
		} else if (str_eq(tag, str_lit("no_bounds_check"))) {
			s = parse_stmt(f);
			s->stmt_state_flags |= StmtStateFlag_no_bounds_check;
			if ((s->stmt_state_flags & StmtStateFlag_bounds_check) != 0) {
				syntax_error(token, "#bounds_check and #no_bounds_check cannot be applied together");
			}
			return s;
		}

		if (str_eq(tag, str_lit("include"))) {
			syntax_error(token, "#include is not a valid import declaration kind. Use #load instead");
			s = ast_bad_stmt(f, token, f->curr_token);
		} else {
			syntax_error(token, "Unknown tag directive used: `%.*s`", LIT(tag));
			s = ast_bad_stmt(f, token, f->curr_token);
		}

		fix_advance_to_next_stmt(f);

		return s;
	} break;

	case Token_OpenBrace:
		return parse_block_stmt(f, false);

	case Token_Semicolon:
		s = ast_empty_stmt(f, token);
		next_token(f);
		return s;
	}

	syntax_error(token,
	             "Expected a statement, got `%.*s`",
	             LIT(token_strings[token.kind]));
	fix_advance_to_next_stmt(f);
	return ast_bad_stmt(f, token, f->curr_token);
}

AstNodeArray parse_stmt_list(AstFile *f) {
	AstNodeArray list = make_ast_node_array(f);

	while (f->curr_token.kind != Token_case &&
	       f->curr_token.kind != Token_default &&
	       f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		AstNode *stmt = parse_stmt(f);
		if (stmt && stmt->kind != AstNode_EmptyStmt) {
			array_add(&list, stmt);
			if (stmt->kind == AstNode_ExprStmt &&
			    stmt->ExprStmt.expr != NULL &&
			    stmt->ExprStmt.expr->kind == AstNode_ProcLit) {
				syntax_error_node(stmt, "Procedure literal evaluated but not used");
			}
		}
	}

	return list;
}


ParseFileError init_ast_file(AstFile *f, String fullpath) {
	fullpath = string_trim_whitespace(fullpath); // Just in case
	if (!string_has_extension(fullpath, str_lit("odin"))) {
		return ParseFile_WrongExtension;
	}
	TokenizerInitError err = init_tokenizer(&f->tokenizer, fullpath);
	if (err == TokenizerInit_None) {
		array_init(&f->tokens, heap_allocator());
		{
			for (;;) {
				Token token = tokenizer_get_token(&f->tokenizer);
				if (token.kind == Token_Invalid) {
					return ParseFile_InvalidToken;
				}
				array_add(&f->tokens, token);

				if (token.kind == Token_EOF) {
					break;
				}
			}
		}

		f->curr_token_index = 0;
		f->prev_token = f->tokens.e[f->curr_token_index];
		f->curr_token = f->tokens.e[f->curr_token_index];

		// NOTE(bill): Is this big enough or too small?
		isize arena_size = gb_size_of(AstNode);
		arena_size *= 2*f->tokens.count;
		gb_arena_init_from_allocator(&f->arena, heap_allocator(), arena_size);

		f->curr_proc = NULL;
		f->id = ++global_file_id;

		return ParseFile_None;
	}

	switch (err) {
	case TokenizerInit_NotExists:
		return ParseFile_NotFound;
	case TokenizerInit_Permission:
		return ParseFile_Permission;
	case TokenizerInit_Empty:
		return ParseFile_EmptyFile;
	}

	return ParseFile_InvalidFile;
}

void destroy_ast_file(AstFile *f) {
	gb_arena_free(&f->arena);
	array_free(&f->tokens);
	gb_free(heap_allocator(), f->tokenizer.fullpath.text);
	destroy_tokenizer(&f->tokenizer);
}

bool init_parser(Parser *p) {
	array_init(&p->files, heap_allocator());
	array_init(&p->imports, heap_allocator());
	gb_mutex_init(&p->mutex);
	return true;
}

void destroy_parser(Parser *p) {
	// TODO(bill): Fix memory leak
	for_array(i, p->files) {
		destroy_ast_file(&p->files.e[i]);
	}
#if 0
	for_array(i, p->imports) {
		// gb_free(heap_allocator(), p->imports[i].text);
	}
#endif
	array_free(&p->files);
	array_free(&p->imports);
	gb_mutex_destroy(&p->mutex);
}

// NOTE(bill): Returns true if it's added
bool try_add_import_path(Parser *p, String path, String rel_path, TokenPos pos) {
	gb_mutex_lock(&p->mutex);

	path = string_trim_whitespace(path);
	rel_path = string_trim_whitespace(rel_path);

	for_array(i, p->imports) {
		String import = p->imports.e[i].path;
		if (str_eq(import, path)) {
			return false;
		}
	}

	ImportedFile item;
	item.path = path;
	item.rel_path = rel_path;
	item.pos = pos;
	array_add(&p->imports, item);

	gb_mutex_unlock(&p->mutex);

	return true;
}

gb_global Rune illegal_import_runes[] = {
	'"', '\'', '`', ' ', '\t', '\r', '\n', '\v', '\f',
	'\\', // NOTE(bill): Disallow windows style filepaths
	'!', '$', '%', '^', '&', '*', '(', ')', '=', '+',
	'[', ']', '{', '}',
	';', ':', '#',
	'|', ',',  '<', '>', '?',
};

bool is_import_path_valid(String path) {
	if (path.len > 0) {
		u8 *start = path.text;
		u8 *end = path.text + path.len;
		u8 *curr = start;
		while (curr < end) {
			isize width = 1;
			Rune r = curr[0];
			if (r >= 0x80) {
				width = gb_utf8_decode(curr, end-curr, &r);
				if (r == GB_RUNE_INVALID && width == 1) {
					return false;
				}
				else if (r == GB_RUNE_BOM && curr-start > 0) {
					return false;
				}
			}

			for (isize i = 0; i < gb_count_of(illegal_import_runes); i++) {
				if (r == illegal_import_runes[i]) {
					return false;
				}
			}

			curr += width;
		}

		return true;
	}
	return false;
}

void parse_setup_file_decls(Parser *p, AstFile *f, String base_dir, AstNodeArray decls) {
	for_array(i, decls) {
		AstNode *node = decls.e[i];
		if (!is_ast_node_decl(node) &&
		    node->kind != AstNode_BadStmt &&
		    node->kind != AstNode_EmptyStmt) {
			// NOTE(bill): Sanity check
			syntax_error_node(node, "Only declarations are allowed at file scope %.*s", LIT(ast_node_strings[node->kind]));
		} else if (node->kind == AstNode_ImportDecl) {
			ast_node(id, ImportDecl, node);
			String file_str = id->relpath.string;

			if (!is_import_path_valid(file_str)) {
				if (id->is_import) {
					syntax_error_node(node, "Invalid import path: `%.*s`", LIT(file_str));
				} else {
					syntax_error_node(node, "Invalid include path: `%.*s`", LIT(file_str));
				}
				// NOTE(bill): It's a naughty name
				decls.e[i] = ast_bad_decl(f, id->relpath, id->relpath);
				continue;
			}

			gbAllocator allocator = heap_allocator(); // TODO(bill): Change this allocator

			String rel_path = get_fullpath_relative(allocator, base_dir, file_str);
			String import_file = rel_path;
			if (!gb_file_exists(cast(char *)rel_path.text)) { // NOTE(bill): This should be null terminated
				String abs_path = get_fullpath_core(allocator, file_str);
				if (gb_file_exists(cast(char *)abs_path.text)) {
					import_file = abs_path;
				}
			}

			id->fullpath = import_file;
			try_add_import_path(p, import_file, file_str, ast_node_token(node).pos);
		} else if (node->kind == AstNode_ForeignLibrary) {
			AstNodeForeignLibrary *fl = &node->ForeignLibrary;
			String file_str = fl->filepath.string;

			if (!is_import_path_valid(file_str)) {
				if (fl->is_system) {
					syntax_error_node(node, "Invalid `foreign_system_library` path");
				} else {
					syntax_error_node(node, "Invalid `foreign_library` path");
				}
				// NOTE(bill): It's a naughty name
				f->decls.e[i] = ast_bad_decl(f, fl->token, fl->token);
				continue;
			}

			fl->base_dir = base_dir;
		}
	}
}

void parse_file(Parser *p, AstFile *f) {
	String filepath = f->tokenizer.fullpath;
	String base_dir = filepath;
	for (isize i = filepath.len-1; i >= 0; i--) {
		if (base_dir.text[i] == '\\' ||
		    base_dir.text[i] == '/') {
			break;
		}
		base_dir.len--;
	}

	while (f->curr_token.kind == Token_Comment) {
		next_token(f);
	}

	f->decls = parse_stmt_list(f);
	parse_setup_file_decls(p, f, base_dir, f->decls);
}



ParseFileError parse_files(Parser *p, char *init_filename) {
	char *fullpath_str = gb_path_get_full_name(heap_allocator(), init_filename);
	String init_fullpath = make_string_c(fullpath_str);
	TokenPos init_pos = {0};
	ImportedFile init_imported_file = {init_fullpath, init_fullpath, init_pos};


	{
		String s = get_fullpath_core(heap_allocator(), str_lit("_preload.odin"));
		ImportedFile runtime_file = {s, s, init_pos};
		array_add(&p->imports, runtime_file);
	}
	{
		String s = get_fullpath_core(heap_allocator(), str_lit("_soft_numbers.odin"));
		ImportedFile runtime_file = {s, s, init_pos};
		array_add(&p->imports, runtime_file);
	}

	array_add(&p->imports, init_imported_file);
	p->init_fullpath = init_fullpath;

	for_array(i, p->imports) {
		ImportedFile imported_file = p->imports.e[i];
		String import_path = imported_file.path;
		String import_rel_path = imported_file.rel_path;
		TokenPos pos = imported_file.pos;
		AstFile file = {0};

		ParseFileError err = init_ast_file(&file, import_path);

		if (err != ParseFile_None) {
			if (err == ParseFile_EmptyFile) {
				if (str_eq(import_path, init_fullpath)) {
					gb_printf_err("Initial file is empty - %.*s\n", LIT(init_fullpath));
					gb_exit(1);
				}
				return ParseFile_None;
			}

			if (pos.line != 0) {
				gb_printf_err("%.*s(%td:%td) ", LIT(pos.file), pos.line, pos.column);
			}
			gb_printf_err("Failed to parse file: %.*s\n\t", LIT(import_rel_path));
			switch (err) {
			case ParseFile_WrongExtension:
				gb_printf_err("Invalid file extension: File must have the extension `.odin`");
				break;
			case ParseFile_InvalidFile:
				gb_printf_err("Invalid file or cannot be found");
				break;
			case ParseFile_Permission:
				gb_printf_err("File permissions problem");
				break;
			case ParseFile_NotFound:
				gb_printf_err("File cannot be found (`%.*s`)", LIT(import_path));
				break;
			case ParseFile_InvalidToken:
				gb_printf_err("Invalid token found in file");
				break;
			}
			gb_printf_err("\n");
			return err;
		}
		parse_file(p, &file);

		{
			gb_mutex_lock(&p->mutex);
			file.id = p->files.count;
			array_add(&p->files, file);
			p->total_line_count += file.tokenizer.line_count;
			gb_mutex_unlock(&p->mutex);
		}
	}

	for_array(i, p->files) {
		p->total_token_count += p->files.e[i].tokens.count;
	}


	return ParseFile_None;
}


