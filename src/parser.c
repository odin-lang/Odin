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
	gbMutex             mutex;
} Parser;

typedef enum ProcTag {
	ProcTag_bounds_check    = GB_BIT(0),
	ProcTag_no_bounds_check = GB_BIT(1),

	ProcTag_foreign         = GB_BIT(10),
	ProcTag_link_name       = GB_BIT(11),
	ProcTag_inline          = GB_BIT(12),
	ProcTag_no_inline       = GB_BIT(13),
	ProcTag_dll_import      = GB_BIT(14),
	ProcTag_dll_export      = GB_BIT(15),

	ProcTag_stdcall         = GB_BIT(16),
	ProcTag_fastcall        = GB_BIT(17),
	// ProcTag_cdecl           = GB_BIT(18),
} ProcTag;

typedef enum VarDeclTag {
	VarDeclTag_thread_local = GB_BIT(0),
} VarDeclTag;

typedef enum StmtStateFlag {
	StmtStateFlag_bounds_check    = GB_BIT(0),
	StmtStateFlag_no_bounds_check = GB_BIT(1),
} StmtStateFlag;

AstNodeArray make_ast_node_array(AstFile *f) {
	AstNodeArray a;
	// array_init(&a, gb_arena_allocator(&f->arena));
	array_init(&a, heap_allocator());
	return a;
}



#define AST_NODE_KINDS \
	AST_NODE_KIND(BasicLit, "basic literal", Token) \
	AST_NODE_KIND(Ident,    "identifier",    Token) \
	AST_NODE_KIND(Ellipsis, "ellipsis", struct { \
		Token token; \
		AstNode *expr; \
	}) \
	AST_NODE_KIND(ProcLit, "procedure literal", struct { \
		AstNode *type; \
		AstNode *body; \
		u64 tags;      \
	}) \
	AST_NODE_KIND(CompoundLit, "compound literal", struct { \
		AstNode *type; \
		AstNodeArray elems; \
		Token open, close; \
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
	AST_NODE_KIND(DemaybeExpr,  "demaybe expression",     struct { Token op; AstNode *expr; }) \
	AST_NODE_KIND(CallExpr,     "call expression", struct { \
		AstNode *proc; \
		AstNodeArray args; \
		Token open, close; \
		Token ellipsis; \
	}) \
	AST_NODE_KIND(SliceExpr, "slice expression", struct { \
		AstNode *expr; \
		Token open, close; \
		AstNode *low, *high, *max; \
		bool triple_indexed; \
	}) \
	AST_NODE_KIND(FieldValue, "field value", struct { Token eq; AstNode *field, *value; }) \
AST_NODE_KIND(_ExprEnd,       "", i32) \
AST_NODE_KIND(_StmtBegin,     "", i32) \
	AST_NODE_KIND(BadStmt,    "bad statement",                 struct { Token begin, end; }) \
	AST_NODE_KIND(EmptyStmt,  "empty statement",               struct { Token token; }) \
	AST_NODE_KIND(ExprStmt,   "expression statement",          struct { AstNode *expr; } ) \
	AST_NODE_KIND(IncDecStmt, "increment/decrement statement", struct { Token op; AstNode *expr; }) \
	AST_NODE_KIND(TagStmt,    "tag statement", struct { \
		Token token; \
		Token name; \
		AstNode *stmt; \
	}) \
	AST_NODE_KIND(AssignStmt, "assign statement", struct { \
		Token op; \
		AstNodeArray lhs, rhs; \
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
		Token token; \
		AstNode *init, *cond, *post; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(CaseClause, "case clause", struct { \
		Token token; \
		AstNodeArray list, stmts; \
	}) \
	AST_NODE_KIND(MatchStmt, "match statement", struct { \
		Token token; \
		AstNode *init, *tag; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(TypeMatchStmt, "type match statement", struct { \
		Token token; \
		AstNode *tag, *var; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(DeferStmt,  "defer statement",  struct { Token token; AstNode *stmt; }) \
	AST_NODE_KIND(BranchStmt, "branch statement", struct { Token token; }) \
	AST_NODE_KIND(UsingStmt,  "using statement",  struct { Token token; AstNode *node; }) \
	AST_NODE_KIND(AsmOperand, "assembly operand", struct { \
		Token string; \
		AstNode *operand; \
	}) \
	AST_NODE_KIND(AsmStmt,    "assembly statement", struct { \
		Token token; \
		bool is_volatile; \
		Token open, close; \
		Token code_string; \
		AstNode *output_list; \
		AstNode *input_list; \
		AstNode *clobber_list; \
		isize output_count, input_count, clobber_count; \
	}) \
	AST_NODE_KIND(PushAllocator, "push_allocator statement", struct { \
		Token token; \
		AstNode *expr; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(PushContext, "push_context statement", struct { \
		Token token; \
		AstNode *expr; \
		AstNode *body; \
	}) \
\
AST_NODE_KIND(_ComplexStmtEnd, "", i32) \
AST_NODE_KIND(_StmtEnd,        "", i32) \
AST_NODE_KIND(_DeclBegin,      "", i32) \
	AST_NODE_KIND(BadDecl,  "bad declaration", struct { Token begin, end; }) \
	AST_NODE_KIND(VarDecl,  "variable declaration", struct { \
			u64          tags; \
			bool          is_using; \
			AstNodeArray names; \
			AstNode *    type; \
			AstNodeArray values; \
			AstNode *    note; \
	}) \
	AST_NODE_KIND(ConstDecl,  "constant declaration", struct { \
			u64          tags; \
			AstNodeArray names; \
			AstNode *    type; \
			AstNodeArray values; \
			AstNode *    note; \
	}) \
	AST_NODE_KIND(ProcDecl, "procedure declaration", struct { \
			AstNode *name;         \
			AstNode *type;         \
			AstNode *body;         \
			u64      tags;         \
			String   foreign_name; \
			String   link_name;    \
			AstNode *note;          \
	}) \
	AST_NODE_KIND(TypeDecl,   "type declaration",   struct { \
		Token token; \
		AstNode *name, *type; \
		AstNode *note; \
	}) \
	AST_NODE_KIND(ImportDecl, "import declaration", struct { \
		Token token, relpath; \
		String fullpath;      \
		Token import_name;    \
		bool is_load;         \
		AstNode *cond;        \
		AstNode *note;        \
	}) \
	AST_NODE_KIND(ForeignLibrary, "foreign library", struct { \
		Token token, filepath; \
		String base_dir;       \
		AstNode *cond;         \
		bool is_system;        \
	}) \
AST_NODE_KIND(_DeclEnd,   "", i32) \
AST_NODE_KIND(_TypeBegin, "", i32) \
	AST_NODE_KIND(Parameter, "parameter", struct { \
		AstNodeArray names; \
		AstNode *type; \
		bool is_using; \
	}) \
	AST_NODE_KIND(ProcType, "procedure type", struct { \
		Token token;          \
		AstNodeArray params;  \
		AstNodeArray results; \
	}) \
	AST_NODE_KIND(PointerType, "pointer type", struct { \
		Token token; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(MaybeType, "maybe type", struct { \
		Token token; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(ArrayType, "array type", struct { \
		Token token; \
		AstNode *count; \
		AstNode *elem; \
	}) \
	AST_NODE_KIND(VectorType, "vector type", struct { \
		Token token; \
		AstNode *count; \
		AstNode *elem; \
	}) \
	AST_NODE_KIND(StructType, "struct type", struct { \
		Token token; \
		AstNodeArray decls; \
		isize decl_count; \
		bool is_packed; \
		bool is_ordered; \
	}) \
	AST_NODE_KIND(UnionType, "union type", struct { \
		Token token; \
		AstNodeArray decls; \
		isize decl_count; \
	}) \
	AST_NODE_KIND(RawUnionType, "raw union type", struct { \
		Token token; \
		AstNodeArray decls; \
		isize decl_count; \
	}) \
	AST_NODE_KIND(EnumType, "enum type", struct { \
		Token token; \
		AstNode *base_type; \
		AstNodeArray fields; \
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
	// AstNode *prev, *next; // NOTE(bill): allow for Linked list
	u32 stmt_state_flags;
	union {
#define AST_NODE_KIND(_kind_name_, name, ...) GB_JOIN2(AstNode, _kind_name_) _kind_name_;
	AST_NODE_KINDS
#undef AST_NODE_KIND
	};
} AstNode;


#define ast_node(n_, Kind_, node_) GB_JOIN2(AstNode, Kind_) *n_ = &(node_)->Kind_; GB_ASSERT((node_)->kind == GB_JOIN2(AstNode_, Kind_))
#define case_ast_node(n_, Kind_, node_) case GB_JOIN2(AstNode_, Kind_): { ast_node(n_, Kind_, node_);
#define case_end } break;


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
	case AstNode_BasicLit:
		return node->BasicLit;
	case AstNode_Ident:
		return node->Ident;
	case AstNode_ProcLit:
		return ast_node_token(node->ProcLit.type);
	case AstNode_CompoundLit:
		if (node->CompoundLit.type != NULL) {
			return ast_node_token(node->CompoundLit.type);
		}
		return node->CompoundLit.open;
	case AstNode_TagExpr:
		return node->TagExpr.token;
	case AstNode_RunExpr:
		return node->RunExpr.token;
	case AstNode_BadExpr:
		return node->BadExpr.begin;
	case AstNode_UnaryExpr:
		return node->UnaryExpr.op;
	case AstNode_BinaryExpr:
		return ast_node_token(node->BinaryExpr.left);
	case AstNode_ParenExpr:
		return node->ParenExpr.open;
	case AstNode_CallExpr:
		return ast_node_token(node->CallExpr.proc);
	case AstNode_SelectorExpr:
		return ast_node_token(node->SelectorExpr.selector);
	case AstNode_IndexExpr:
		return node->IndexExpr.open;
	case AstNode_SliceExpr:
		return node->SliceExpr.open;
	case AstNode_Ellipsis:
		return node->Ellipsis.token;
	case AstNode_FieldValue:
		return node->FieldValue.eq;
	case AstNode_DerefExpr:
		return node->DerefExpr.op;
	case AstNode_DemaybeExpr:
		return node->DemaybeExpr.op;
	case AstNode_BadStmt:
		return node->BadStmt.begin;
	case AstNode_EmptyStmt:
		return node->EmptyStmt.token;
	case AstNode_ExprStmt:
		return ast_node_token(node->ExprStmt.expr);
	case AstNode_TagStmt:
		return node->TagStmt.token;
	case AstNode_IncDecStmt:
		return node->IncDecStmt.op;
	case AstNode_AssignStmt:
		return node->AssignStmt.op;
	case AstNode_BlockStmt:
		return node->BlockStmt.open;
	case AstNode_IfStmt:
		return node->IfStmt.token;
	case AstNode_WhenStmt:
		return node->WhenStmt.token;
	case AstNode_ReturnStmt:
		return node->ReturnStmt.token;
	case AstNode_ForStmt:
		return node->ForStmt.token;
	case AstNode_MatchStmt:
		return node->MatchStmt.token;
	case AstNode_CaseClause:
		return node->CaseClause.token;
	case AstNode_DeferStmt:
		return node->DeferStmt.token;
	case AstNode_BranchStmt:
		return node->BranchStmt.token;
	case AstNode_UsingStmt:
		return node->UsingStmt.token;
	case AstNode_AsmStmt:
		return node->AsmStmt.token;
	case AstNode_PushAllocator:
		return node->PushAllocator.token;
	case AstNode_PushContext:
		return node->PushContext.token;
	case AstNode_BadDecl:
		return node->BadDecl.begin;
	case AstNode_VarDecl:
		return ast_node_token(node->VarDecl.names.e[0]);
	case AstNode_ConstDecl:
		return ast_node_token(node->ConstDecl.names.e[0]);
	case AstNode_ProcDecl:
		return node->ProcDecl.name->Ident;
	case AstNode_TypeDecl:
		return node->TypeDecl.token;
	case AstNode_ImportDecl:
		return node->ImportDecl.token;
	case AstNode_ForeignLibrary:
		return node->ForeignLibrary.token;
	case AstNode_Parameter: {
		if (node->Parameter.names.count > 0) {
			return ast_node_token(node->Parameter.names.e[0]);
		} else {
			return ast_node_token(node->Parameter.type);
		}
	}
	case AstNode_ProcType:
		return node->ProcType.token;
	case AstNode_PointerType:
		return node->PointerType.token;
	case AstNode_MaybeType:
		return node->MaybeType.token;
	case AstNode_ArrayType:
		return node->ArrayType.token;
	case AstNode_VectorType:
		return node->VectorType.token;
	case AstNode_StructType:
		return node->StructType.token;
	case AstNode_UnionType:
		return node->UnionType.token;
	case AstNode_RawUnionType:
		return node->RawUnionType.token;
	case AstNode_EnumType:
		return node->EnumType.token;
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
AstNode *make_node(AstFile *f, AstNodeKind kind) {
	gbArena *arena = &f->arena;
	if (gb_arena_size_remaining(arena, GB_DEFAULT_MEMORY_ALIGNMENT) <= gb_size_of(AstNode)) {
		// NOTE(bill): If a syntax error is so bad, just quit!
		gb_exit(1);
	}
	AstNode *node = gb_alloc_item(gb_arena_allocator(arena), AstNode);
	node->kind = kind;
	return node;
}

AstNode *make_bad_expr(AstFile *f, Token begin, Token end) {
	AstNode *result = make_node(f, AstNode_BadExpr);
	result->BadExpr.begin = begin;
	result->BadExpr.end   = end;
	return result;
}

AstNode *make_tag_expr(AstFile *f, Token token, Token name, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_TagExpr);
	result->TagExpr.token = token;
	result->TagExpr.name = name;
	result->TagExpr.expr = expr;
	return result;
}

AstNode *make_run_expr(AstFile *f, Token token, Token name, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_RunExpr);
	result->RunExpr.token = token;
	result->RunExpr.name = name;
	result->RunExpr.expr = expr;
	return result;
}


AstNode *make_tag_stmt(AstFile *f, Token token, Token name, AstNode *stmt) {
	AstNode *result = make_node(f, AstNode_TagStmt);
	result->TagStmt.token = token;
	result->TagStmt.name = name;
	result->TagStmt.stmt = stmt;
	return result;
}

AstNode *make_unary_expr(AstFile *f, Token op, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_UnaryExpr);
	result->UnaryExpr.op = op;
	result->UnaryExpr.expr = expr;
	return result;
}

AstNode *make_binary_expr(AstFile *f, Token op, AstNode *left, AstNode *right) {
	AstNode *result = make_node(f, AstNode_BinaryExpr);

	if (left == NULL) {
		syntax_error(op, "No lhs expression for binary expression `%.*s`", LIT(op.string));
		left = make_bad_expr(f, op, op);
	}
	if (right == NULL) {
		syntax_error(op, "No rhs expression for binary expression `%.*s`", LIT(op.string));
		right = make_bad_expr(f, op, op);
	}

	result->BinaryExpr.op = op;
	result->BinaryExpr.left = left;
	result->BinaryExpr.right = right;

	return result;
}

AstNode *make_paren_expr(AstFile *f, AstNode *expr, Token open, Token close) {
	AstNode *result = make_node(f, AstNode_ParenExpr);
	result->ParenExpr.expr = expr;
	result->ParenExpr.open = open;
	result->ParenExpr.close = close;
	return result;
}

AstNode *make_call_expr(AstFile *f, AstNode *proc, AstNodeArray args, Token open, Token close, Token ellipsis) {
	AstNode *result = make_node(f, AstNode_CallExpr);
	result->CallExpr.proc = proc;
	result->CallExpr.args = args;
	result->CallExpr.open     = open;
	result->CallExpr.close    = close;
	result->CallExpr.ellipsis = ellipsis;
	return result;
}

AstNode *make_selector_expr(AstFile *f, Token token, AstNode *expr, AstNode *selector) {
	AstNode *result = make_node(f, AstNode_SelectorExpr);
	result->SelectorExpr.expr = expr;
	result->SelectorExpr.selector = selector;
	return result;
}

AstNode *make_index_expr(AstFile *f, AstNode *expr, AstNode *index, Token open, Token close) {
	AstNode *result = make_node(f, AstNode_IndexExpr);
	result->IndexExpr.expr = expr;
	result->IndexExpr.index = index;
	result->IndexExpr.open = open;
	result->IndexExpr.close = close;
	return result;
}


AstNode *make_slice_expr(AstFile *f, AstNode *expr, Token open, Token close, AstNode *low, AstNode *high, AstNode *max, bool triple_indexed) {
	AstNode *result = make_node(f, AstNode_SliceExpr);
	result->SliceExpr.expr = expr;
	result->SliceExpr.open = open;
	result->SliceExpr.close = close;
	result->SliceExpr.low = low;
	result->SliceExpr.high = high;
	result->SliceExpr.max = max;
	result->SliceExpr.triple_indexed = triple_indexed;
	return result;
}

AstNode *make_deref_expr(AstFile *f, AstNode *expr, Token op) {
	AstNode *result = make_node(f, AstNode_DerefExpr);
	result->DerefExpr.expr = expr;
	result->DerefExpr.op = op;
	return result;
}

AstNode *make_demaybe_expr(AstFile *f, AstNode *expr, Token op) {
	AstNode *result = make_node(f, AstNode_DemaybeExpr);
	result->DemaybeExpr.expr = expr;
	result->DemaybeExpr.op = op;
	return result;
}


AstNode *make_basic_lit(AstFile *f, Token basic_lit) {
	AstNode *result = make_node(f, AstNode_BasicLit);
	result->BasicLit = basic_lit;
	return result;
}

AstNode *make_ident(AstFile *f, Token token) {
	AstNode *result = make_node(f, AstNode_Ident);
	result->Ident = token;
	return result;
}

AstNode *make_ellipsis(AstFile *f, Token token, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_Ellipsis);
	result->Ellipsis.token = token;
	result->Ellipsis.expr = expr;
	return result;
}


AstNode *make_proc_lit(AstFile *f, AstNode *type, AstNode *body, u64 tags) {
	AstNode *result = make_node(f, AstNode_ProcLit);
	result->ProcLit.type = type;
	result->ProcLit.body = body;
	result->ProcLit.tags = tags;
	return result;
}

AstNode *make_field_value(AstFile *f, AstNode *field, AstNode *value, Token eq) {
	AstNode *result = make_node(f, AstNode_FieldValue);
	result->FieldValue.field = field;
	result->FieldValue.value = value;
	result->FieldValue.eq = eq;
	return result;
}

AstNode *make_compound_lit(AstFile *f, AstNode *type, AstNodeArray elems, Token open, Token close) {
	AstNode *result = make_node(f, AstNode_CompoundLit);
	result->CompoundLit.type = type;
	result->CompoundLit.elems = elems;
	result->CompoundLit.open = open;
	result->CompoundLit.close = close;
	return result;
}

AstNode *make_bad_stmt(AstFile *f, Token begin, Token end) {
	AstNode *result = make_node(f, AstNode_BadStmt);
	result->BadStmt.begin = begin;
	result->BadStmt.end   = end;
	return result;
}

AstNode *make_empty_stmt(AstFile *f, Token token) {
	AstNode *result = make_node(f, AstNode_EmptyStmt);
	result->EmptyStmt.token = token;
	return result;
}

AstNode *make_expr_stmt(AstFile *f, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_ExprStmt);
	result->ExprStmt.expr = expr;
	return result;
}

AstNode *make_inc_dec_stmt(AstFile *f, Token op, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_IncDecStmt);
	result->IncDecStmt.op = op;
	result->IncDecStmt.expr = expr;
	return result;
}

AstNode *make_assign_stmt(AstFile *f, Token op, AstNodeArray lhs, AstNodeArray rhs) {
	AstNode *result = make_node(f, AstNode_AssignStmt);
	result->AssignStmt.op = op;
	result->AssignStmt.lhs = lhs;
	result->AssignStmt.rhs = rhs;
	return result;
}

AstNode *make_block_stmt(AstFile *f, AstNodeArray stmts, Token open, Token close) {
	AstNode *result = make_node(f, AstNode_BlockStmt);
	result->BlockStmt.stmts = stmts;
	result->BlockStmt.open = open;
	result->BlockStmt.close = close;
	return result;
}

AstNode *make_if_stmt(AstFile *f, Token token, AstNode *init, AstNode *cond, AstNode *body, AstNode *else_stmt) {
	AstNode *result = make_node(f, AstNode_IfStmt);
	result->IfStmt.token = token;
	result->IfStmt.init = init;
	result->IfStmt.cond = cond;
	result->IfStmt.body = body;
	result->IfStmt.else_stmt = else_stmt;
	return result;
}

AstNode *make_when_stmt(AstFile *f, Token token, AstNode *cond, AstNode *body, AstNode *else_stmt) {
	AstNode *result = make_node(f, AstNode_WhenStmt);
	result->WhenStmt.token = token;
	result->WhenStmt.cond = cond;
	result->WhenStmt.body = body;
	result->WhenStmt.else_stmt = else_stmt;
	return result;
}


AstNode *make_return_stmt(AstFile *f, Token token, AstNodeArray results) {
	AstNode *result = make_node(f, AstNode_ReturnStmt);
	result->ReturnStmt.token = token;
	result->ReturnStmt.results = results;
	return result;
}

AstNode *make_for_stmt(AstFile *f, Token token, AstNode *init, AstNode *cond, AstNode *post, AstNode *body) {
	AstNode *result = make_node(f, AstNode_ForStmt);
	result->ForStmt.token = token;
	result->ForStmt.init  = init;
	result->ForStmt.cond  = cond;
	result->ForStmt.post  = post;
	result->ForStmt.body  = body;
	return result;
}


AstNode *make_match_stmt(AstFile *f, Token token, AstNode *init, AstNode *tag, AstNode *body) {
	AstNode *result = make_node(f, AstNode_MatchStmt);
	result->MatchStmt.token = token;
	result->MatchStmt.init  = init;
	result->MatchStmt.tag   = tag;
	result->MatchStmt.body  = body;
	return result;
}


AstNode *make_type_match_stmt(AstFile *f, Token token, AstNode *tag, AstNode *var, AstNode *body) {
	AstNode *result = make_node(f, AstNode_TypeMatchStmt);
	result->TypeMatchStmt.token = token;
	result->TypeMatchStmt.tag   = tag;
	result->TypeMatchStmt.var   = var;
	result->TypeMatchStmt.body  = body;
	return result;
}

AstNode *make_case_clause(AstFile *f, Token token, AstNodeArray list, AstNodeArray stmts) {
	AstNode *result = make_node(f, AstNode_CaseClause);
	result->CaseClause.token = token;
	result->CaseClause.list  = list;
	result->CaseClause.stmts = stmts;
	return result;
}


AstNode *make_defer_stmt(AstFile *f, Token token, AstNode *stmt) {
	AstNode *result = make_node(f, AstNode_DeferStmt);
	result->DeferStmt.token = token;
	result->DeferStmt.stmt = stmt;
	return result;
}

AstNode *make_branch_stmt(AstFile *f, Token token) {
	AstNode *result = make_node(f, AstNode_BranchStmt);
	result->BranchStmt.token = token;
	return result;
}

AstNode *make_using_stmt(AstFile *f, Token token, AstNode *node) {
	AstNode *result = make_node(f, AstNode_UsingStmt);
	result->UsingStmt.token = token;
	result->UsingStmt.node  = node;
	return result;
}

AstNode *make_asm_operand(AstFile *f, Token string, AstNode *operand) {
	AstNode *result = make_node(f, AstNode_AsmOperand);
	result->AsmOperand.string  = string;
	result->AsmOperand.operand = operand;
	return result;

}

AstNode *make_asm_stmt(AstFile *f, Token token, bool is_volatile, Token open, Token close, Token code_string,
                                 AstNode *output_list, AstNode *input_list, AstNode *clobber_list,
                                 isize output_count, isize input_count, isize clobber_count) {
	AstNode *result = make_node(f, AstNode_AsmStmt);
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

AstNode *make_push_allocator(AstFile *f, Token token, AstNode *expr, AstNode *body) {
	AstNode *result = make_node(f, AstNode_PushAllocator);
	result->PushAllocator.token = token;
	result->PushAllocator.expr = expr;
	result->PushAllocator.body = body;
	return result;
}

AstNode *make_push_context(AstFile *f, Token token, AstNode *expr, AstNode *body) {
	AstNode *result = make_node(f, AstNode_PushContext);
	result->PushContext.token = token;
	result->PushContext.expr = expr;
	result->PushContext.body = body;
	return result;
}




AstNode *make_bad_decl(AstFile *f, Token begin, Token end) {
	AstNode *result = make_node(f, AstNode_BadDecl);
	result->BadDecl.begin = begin;
	result->BadDecl.end = end;
	return result;
}

AstNode *make_var_decl(AstFile *f, AstNodeArray names, AstNode *type, AstNodeArray values) {
	AstNode *result = make_node(f, AstNode_VarDecl);
	result->VarDecl.names = names;
	result->VarDecl.type = type;
	result->VarDecl.values = values;
	return result;
}

AstNode *make_const_decl(AstFile *f, AstNodeArray names, AstNode *type, AstNodeArray values) {
	AstNode *result = make_node(f, AstNode_ConstDecl);
	result->ConstDecl.names = names;
	result->ConstDecl.type = type;
	result->ConstDecl.values = values;
	return result;
}

AstNode *make_parameter(AstFile *f, AstNodeArray names, AstNode *type, bool is_using) {
	AstNode *result = make_node(f, AstNode_Parameter);
	result->Parameter.names = names;
	result->Parameter.type = type;
	result->Parameter.is_using = is_using;
	return result;
}

AstNode *make_proc_type(AstFile *f, Token token, AstNodeArray params, AstNodeArray results) {
	AstNode *result = make_node(f, AstNode_ProcType);
	result->ProcType.token = token;
	result->ProcType.params = params;
	result->ProcType.results = results;
	return result;
}

AstNode *make_proc_decl(AstFile *f, AstNode *name, AstNode *proc_type, AstNode *body, u64 tags, String foreign_name, String link_name) {
	AstNode *result = make_node(f, AstNode_ProcDecl);
	result->ProcDecl.name = name;
	result->ProcDecl.type = proc_type;
	result->ProcDecl.body = body;
	result->ProcDecl.tags = tags;
	result->ProcDecl.foreign_name = foreign_name;
	result->ProcDecl.link_name = link_name;
	return result;
}

AstNode *make_pointer_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_node(f, AstNode_PointerType);
	result->PointerType.token = token;
	result->PointerType.type = type;
	return result;
}

AstNode *make_maybe_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_node(f, AstNode_MaybeType);
	result->MaybeType.token = token;
	result->MaybeType.type = type;
	return result;
}

AstNode *make_array_type(AstFile *f, Token token, AstNode *count, AstNode *elem) {
	AstNode *result = make_node(f, AstNode_ArrayType);
	result->ArrayType.token = token;
	result->ArrayType.count = count;
	result->ArrayType.elem = elem;
	return result;
}

AstNode *make_vector_type(AstFile *f, Token token, AstNode *count, AstNode *elem) {
	AstNode *result = make_node(f, AstNode_VectorType);
	result->VectorType.token = token;
	result->VectorType.count = count;
	result->VectorType.elem  = elem;
	return result;
}

AstNode *make_struct_type(AstFile *f, Token token, AstNodeArray decls, isize decl_count, bool is_packed, bool is_ordered) {
	AstNode *result = make_node(f, AstNode_StructType);
	result->StructType.token = token;
	result->StructType.decls = decls;
	result->StructType.decl_count = decl_count;
	result->StructType.is_packed = is_packed;
	result->StructType.is_ordered = is_ordered;
	return result;
}


AstNode *make_union_type(AstFile *f, Token token, AstNodeArray decls, isize decl_count) {
	AstNode *result = make_node(f, AstNode_UnionType);
	result->UnionType.token = token;
	result->UnionType.decls = decls;
	result->UnionType.decl_count = decl_count;
	return result;
}

AstNode *make_raw_union_type(AstFile *f, Token token, AstNodeArray decls, isize decl_count) {
	AstNode *result = make_node(f, AstNode_RawUnionType);
	result->RawUnionType.token = token;
	result->RawUnionType.decls = decls;
	result->RawUnionType.decl_count = decl_count;
	return result;
}


AstNode *make_enum_type(AstFile *f, Token token, AstNode *base_type, AstNodeArray fields) {
	AstNode *result = make_node(f, AstNode_EnumType);
	result->EnumType.token = token;
	result->EnumType.base_type = base_type;
	result->EnumType.fields = fields;
	return result;
}

AstNode *make_type_decl(AstFile *f, Token token, AstNode *name, AstNode *type) {
	AstNode *result = make_node(f, AstNode_TypeDecl);
	result->TypeDecl.token = token;
	result->TypeDecl.name = name;
	result->TypeDecl.type = type;
	return result;
}

AstNode *make_import_decl(AstFile *f, Token token, Token relpath, Token import_name,
                          AstNode *cond,
                          bool is_load) {
	AstNode *result = make_node(f, AstNode_ImportDecl);
	result->ImportDecl.token = token;
	result->ImportDecl.relpath = relpath;
	result->ImportDecl.import_name = import_name;
	result->ImportDecl.cond = cond;
	result->ImportDecl.is_load = is_load;
	return result;
}

AstNode *make_foreign_library(AstFile *f, Token token, Token filepath, AstNode *cond, bool is_system) {
	AstNode *result = make_node(f, AstNode_ForeignLibrary);
	result->ForeignLibrary.token = token;
	result->ForeignLibrary.filepath = filepath;
	result->ForeignLibrary.cond = cond;
	result->ForeignLibrary.is_system = is_system;
	return result;
}

bool next_token(AstFile *f) {
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

Token expect_token(AstFile *f, TokenKind kind) {
	Token prev = f->curr_token;
	if (prev.kind != kind) {
		String p = token_strings[prev.kind];
		if (prev.kind == Token_Semicolon &&
		    str_eq(prev.string, str_lit("\n"))) {
			syntax_error(f->curr_token, "Expected `%.*s`, got newline",
			             LIT(token_strings[kind]),
			             LIT(p));
		} else {
			syntax_error(f->curr_token, "Expected `%.*s`, got `%.*s`",
			             LIT(token_strings[kind]),
			             LIT(token_strings[prev.kind]));
		}
	}
	next_token(f);
	return prev;
}

Token expect_token_after(AstFile *f, TokenKind kind, char *msg) {
	Token prev = f->curr_token;
	if (prev.kind != kind) {
		String p = token_strings[prev.kind];
		if (prev.kind == Token_Semicolon &&
		    str_eq(prev.string, str_lit("\n"))) {
			p = str_lit("newline");
		}
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
		case Token_for:
		case Token_match:
		case Token_defer:
		case Token_asm:
		case Token_using:

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

void expect_semicolon(AstFile *f, AstNode *s) {
	if (f->prev_token.kind == Token_CloseBrace ||
	    f->prev_token.kind == Token_CloseBrace) {
		return;
	}

	if (f->curr_token.kind != Token_CloseParen &&
	    f->curr_token.kind != Token_CloseBrace) {
		switch (f->curr_token.kind) {
		case Token_Comma:
			expect_token(f, Token_Semicolon);
			/*fallthrough*/
		case Token_Semicolon:
			next_token(f);
			break;
		default:
			expect_token(f, Token_Semicolon);
			fix_advance_to_next_stmt(f);
		}
	}

	// if (s != NULL) {
	// 	syntax_error(f->prev_token, "Expected `;` after %.*s, got `%.*s`",
	// 	             LIT(ast_node_strings[s->kind]), LIT(token_strings[f->prev_token.kind]));
	// } else {
	// 	syntax_error(f->prev_token, "Expected `;`");
	// }
	// fix_advance_to_next_stmt(f);
}

bool parse_at_comma(AstFile *f, String context, TokenKind follow) {
	if (f->curr_token.kind == Token_Comma) {
		return true;
	}
	if (f->curr_token.kind != follow) {
		if (f->curr_token.kind == Token_Semicolon &&
		    str_eq(f->curr_token.string, str_lit("\n"))) {
			error(f->curr_token, "Missing `,` before new line in %.*s", LIT(context));
		}
		error(f->curr_token, "Missing `,` in %.*s", LIT(context));
		return true;
	}
	return false;
}



AstNode *    parse_expr(AstFile *f, bool lhs);
AstNode *    parse_proc_type(AstFile *f);
AstNodeArray parse_stmt_list(AstFile *f);
AstNode *    parse_stmt(AstFile *f);
AstNode *    parse_body(AstFile *f);

AstNode *parse_identifier(AstFile *f) {
	Token token = f->curr_token;
	if (token.kind == Token_Ident) {
		next_token(f);
	} else {
		token.string = str_lit("_");
		expect_token(f, Token_Ident);
	}
	return make_ident(f, token);
}

AstNode *parse_tag_expr(AstFile *f, AstNode *expression) {
	Token token = expect_token(f, Token_Hash);
	Token name  = expect_token(f, Token_Ident);
	return make_tag_expr(f, token, name, expression);
}

AstNode *unparen_expr(AstNode *node) {
	for (;;) {
		if (node->kind != AstNode_ParenExpr)
			return node;
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
			elem = make_field_value(f, elem, value, eq);
		}

		array_add(&elems, elem);

		if (!parse_at_comma(f, str_lit("compound literal"), Token_CloseBrace)) {
			break;
		}
		next_token(f);
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

	return make_compound_lit(f, type, elems, open, close);
}

AstNode *parse_value(AstFile *f) {
	if (f->curr_token.kind == Token_OpenBrace) {
		return parse_literal_value(f, NULL);
	}

	AstNode *value = parse_expr(f, false);
	return value;
}

AstNode *parse_identifier_or_type(AstFile *f, u32 flags);


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

void parse_proc_tags(AstFile *f, u64 *tags, String *foreign_name, String *link_name) {
	// TODO(bill): Add this to procedure literals too
	GB_ASSERT(foreign_name != NULL);
	GB_ASSERT(link_name    != NULL);

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
		ELSE_IF_ADD_TAG(bounds_check)
		ELSE_IF_ADD_TAG(no_bounds_check)
		ELSE_IF_ADD_TAG(inline)
		ELSE_IF_ADD_TAG(no_inline)
		ELSE_IF_ADD_TAG(dll_import)
		ELSE_IF_ADD_TAG(dll_export)
		ELSE_IF_ADD_TAG(stdcall)
		ELSE_IF_ADD_TAG(fastcall)
		// ELSE_IF_ADD_TAG(cdecl)
		else {
			syntax_error_node(tag_expr, "Unknown procedure tag");
		}

		#undef ELSE_IF_ADD_TAG
	}

	if ((*tags & ProcTag_foreign) && (*tags & ProcTag_link_name)) {
		syntax_error(f->curr_token, "You cannot apply both #foreign and #link_name to a procedure");
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

	if ((*tags & ProcTag_stdcall) && (*tags & ProcTag_fastcall)) {
		syntax_error(f->curr_token, "You cannot apply one calling convention to a procedure");
	}
}

AstNode *parse_operand(AstFile *f, bool lhs) {
	AstNode *operand = NULL; // Operand
	switch (f->curr_token.kind) {
	case Token_Ident:
		operand = parse_identifier(f);
		if (!lhs) {
			// TODO(bill): Handle?
		}
		return operand;

	case Token_Integer:
	case Token_Float:
	case Token_Rune:
		operand = make_basic_lit(f, f->curr_token);
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

		return make_basic_lit(f, token);
	}


	case Token_OpenParen: {
		Token open, close;
		// NOTE(bill): Skip the Paren Expression
		open = expect_token(f, Token_OpenParen);
		f->expr_level++;
		operand = parse_expr(f, false);
		f->expr_level--;
		close = expect_token(f, Token_CloseParen);
		return make_paren_expr(f, operand, open, close);
	}

	case Token_Hash: {
		Token token = expect_token(f, Token_Hash);
		Token name  = expect_token(f, Token_Ident);
		if (str_eq(name.string, str_lit("file"))) {
			Token token = name;
			token.kind = Token_String;
			token.string = token.pos.file;
			return make_basic_lit(f, token);
		} else if (str_eq(name.string, str_lit("line"))) {
			Token token = name;
			token.kind = Token_Integer;
			char *str = gb_alloc_array(gb_arena_allocator(&f->arena), char, 20);
			gb_i64_to_str(token.pos.line, str, 10);
			token.string = make_string_c(str);
			return make_basic_lit(f, token);
		} else if (str_eq(name.string, str_lit("run"))) {
			AstNode *expr = parse_expr(f, false);
			operand = make_run_expr(f, token, name, expr);
			if (unparen_expr(expr)->kind != AstNode_CallExpr) {
				error_node(expr, "#run can only be applied to procedure calls");
				operand = make_bad_expr(f, token, f->curr_token);
			}
			warning(token, "#run is not yet implemented");
		} else {
			operand = make_tag_expr(f, token, name, parse_expr(f, false));
		}
		return operand;
	}

	// Parse Procedure Type or Literal
	case Token_proc: {
		AstNode *curr_proc = f->curr_proc;
		AstNode *type = parse_proc_type(f);
		f->curr_proc = type;

		u64 tags = 0;
		String foreign_name = {0};
		String link_name = {0};
		parse_proc_tags(f, &tags, &foreign_name, &link_name);
		if (tags & ProcTag_foreign) {
			syntax_error(f->curr_token, "#foreign cannot be applied to procedure literals");
		}
		if (tags & ProcTag_link_name) {
			syntax_error(f->curr_token, "#link_name cannot be applied to procedure literals");
		}

		if (f->curr_token.kind == Token_OpenBrace) {
			AstNode *body;

			f->expr_level++;
			body = parse_body(f);
			f->expr_level--;

			type = make_proc_lit(f, type, body, tags);
		}
		f->curr_proc = curr_proc;
		return type;
	}

	default: {
		AstNode *type = parse_identifier_or_type(f, 0);
		if (type != NULL) {
			// NOTE(bill): Sanity check as identifiers should be handled already
			GB_ASSERT_MSG(type->kind != AstNode_Ident, "Type Cannot be identifier");
			return type;
		}
	}
	}

	Token begin = f->curr_token;
	syntax_error(begin, "Expected an operand");
	fix_advance_to_next_stmt(f);
	return make_bad_expr(f, begin, f->curr_token);
}

bool is_literal_type(AstNode *node) {
	switch (node->kind) {
	case AstNode_BadExpr:
	case AstNode_Ident:
	case AstNode_SelectorExpr:
	case AstNode_ArrayType:
	case AstNode_VectorType:
	case AstNode_StructType:
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
		if (f->curr_token.kind == Token_Comma)
			syntax_error(f->curr_token, "Expected an expression not a ,");

		if (f->curr_token.kind == Token_Ellipsis) {
			ellipsis = f->curr_token;
			next_token(f);
		}

		AstNode *arg = parse_expr(f, false);
		array_add(&args, arg);

		if (!parse_at_comma(f, str_lit("argument list"), Token_CloseParen)) {
			break;
		}
		next_token(f);
	}

	f->expr_level--;
	close_paren = expect_closing(f, Token_CloseParen, str_lit("argument list"));

	return make_call_expr(f, operand, args, open_paren, close_paren, ellipsis);
}

AstNode *parse_atom_expr(AstFile *f, bool lhs) {
	AstNode *operand = parse_operand(f, lhs);

	bool loop = true;
	while (loop) {
		switch (f->curr_token.kind) {
		case Token_OpenParen:
			operand = parse_call_expr(f, operand);
			break;

		case Token_Period: {
			Token token = f->curr_token;
			next_token(f);
			switch (f->curr_token.kind) {
			case Token_Ident:
				operand = make_selector_expr(f, token, operand, parse_identifier(f));
				break;
			default: {
				syntax_error(f->curr_token, "Expected a selector");
				next_token(f);
				operand = make_selector_expr(f, f->curr_token, operand, NULL);
			} break;
			}
		} break;

		case Token_OpenBracket: {
			if (lhs) {
				// TODO(bill): Handle this
			}
			Token open, close;
			AstNode *indices[3] = {0};

			f->expr_level++;
			open = expect_token(f, Token_OpenBracket);

			if (f->curr_token.kind != Token_Colon)
				indices[0] = parse_expr(f, false);
			isize colon_count = 0;
			Token colons[2] = {0};

			while (f->curr_token.kind == Token_Colon && colon_count < 2) {
				colons[colon_count++] = f->curr_token;
				next_token(f);
				if (f->curr_token.kind != Token_Colon &&
				    f->curr_token.kind != Token_CloseBracket &&
				    f->curr_token.kind != Token_EOF) {
					indices[colon_count] = parse_expr(f, false);
				}
			}

			f->expr_level--;
			close = expect_token(f, Token_CloseBracket);

			if (colon_count == 0) {
				operand = make_index_expr(f, operand, indices[0], open, close);
			} else {
				bool triple_indexed = false;
				if (colon_count == 2) {
					triple_indexed = true;
					if (indices[1] == NULL) {
						syntax_error(colons[0], "Second index is required in a triple indexed slice");
						indices[1] = make_bad_expr(f, colons[0], colons[1]);
					}
					if (indices[2] == NULL) {
						syntax_error(colons[1], "Third index is required in a triple indexed slice");
						indices[2] = make_bad_expr(f, colons[1], close);
					}
				}
				operand = make_slice_expr(f, operand, open, close, indices[0], indices[1], indices[2], triple_indexed);
			}
		} break;

		case Token_Pointer: // Deference
			operand = make_deref_expr(f, operand, expect_token(f, Token_Pointer));
			break;

		case Token_Maybe: // Demaybe
			operand = make_demaybe_expr(f, operand, expect_token(f, Token_Maybe));
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

AstNode *parse_type(AstFile *f);

AstNode *parse_unary_expr(AstFile *f, bool lhs) {
	switch (f->curr_token.kind) {
	case Token_Pointer:
	case Token_Maybe:
	case Token_Add:
	case Token_Sub:
	case Token_Not:
	case Token_Xor: {
		Token op = f->curr_token;
		next_token(f);
		return make_unary_expr(f, op, parse_unary_expr(f, lhs));
	} break;
	}

	return parse_atom_expr(f, lhs);
}

// NOTE(bill): result == priority
i32 token_precedence(Token t) {
	switch (t.kind) {
	case Token_CmpOr:
		return 1;
	case Token_CmpAnd:
		return 2;
	case Token_CmpEq:
	case Token_NotEq:
	case Token_Lt:
	case Token_Gt:
	case Token_LtEq:
	case Token_GtEq:
		return 3;
	case Token_Add:
	case Token_Sub:
	case Token_Or:
	case Token_Xor:
		return 4;
	case Token_Mul:
	case Token_Quo:
	case Token_Mod:
	case Token_And:
	case Token_AndNot:
	case Token_Shl:
	case Token_Shr:
		return 5;
	case Token_as:
	case Token_transmute:
	case Token_down_cast:
	case Token_union_cast:
		return 6;
	}
	return 0;
}

AstNode *parse_binary_expr(AstFile *f, bool lhs, i32 prec_in) {
	AstNode *expression = parse_unary_expr(f, lhs);
	for (i32 prec = token_precedence(f->curr_token); prec >= prec_in; prec--) {
		for (;;) {
			AstNode *right;
			Token op = f->curr_token;
			i32 op_prec = token_precedence(op);
			if (op_prec != prec) {
				break;
			}
			expect_operator(f); // NOTE(bill): error checks too
			if (lhs) {
				// TODO(bill): error checking
				lhs = false;
			}

			switch (op.kind) {
			case Token_as:
			case Token_transmute:
			case Token_down_cast:
			case Token_union_cast:
				right = parse_type(f);
				break;

			default:
				right = parse_binary_expr(f, false, prec+1);
				if (!right) {
					syntax_error(op, "Expected expression on the right hand side of the binary operator");
				}
				break;
			}
			expression = make_binary_expr(f, op, expression, right);
		}
	}
	return expression;
}

AstNode *parse_expr(AstFile *f, bool lhs) {
	return parse_binary_expr(f, lhs, 0+1);
}


AstNodeArray parse_expr_list(AstFile *f, bool lhs) {
	AstNodeArray list = make_ast_node_array(f);
	do {
		AstNode *e = parse_expr(f, lhs);
		array_add(&list, e);
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		next_token(f);
	} while (true);

	return list;
}

AstNodeArray parse_lhs_expr_list(AstFile *f) {
	return parse_expr_list(f, true);
}

AstNodeArray parse_rhs_expr_list(AstFile *f) {
	return parse_expr_list(f, false);
}

AstNode *parse_decl(AstFile *f, AstNodeArray names);

AstNode *parse_simple_stmt(AstFile *f) {
	isize lhs_count = 0, rhs_count = 0;
	AstNodeArray lhs = parse_lhs_expr_list(f);


	AstNode *statement = NULL;
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
			return make_bad_stmt(f, f->curr_token, f->curr_token);
		}
		next_token(f);
		AstNodeArray rhs = parse_rhs_expr_list(f);
		if (rhs.count == 0) {
			syntax_error(token, "No right-hand side in assignment statement.");
			return make_bad_stmt(f, token, f->curr_token);
		}
		return make_assign_stmt(f, token, lhs, rhs);
	} break;

	case Token_Colon: // Declare
		return parse_decl(f, lhs);
	}

	if (lhs_count > 1) {
		syntax_error(token, "Expected 1 expression");
		return make_bad_stmt(f, token, f->curr_token);
	}

	token = f->curr_token;
	switch (token.kind) {
	case Token_Increment:
	case Token_Decrement:
		if (f->curr_proc == NULL) {
			syntax_error(f->curr_token, "You cannot use a simple statement in the file scope");
			return make_bad_stmt(f, f->curr_token, f->curr_token);
		}
		statement = make_inc_dec_stmt(f, token, lhs.e[0]);
		next_token(f);
		return statement;
	}

	return make_expr_stmt(f, lhs.e[0]);
}



AstNode *parse_block_stmt(AstFile *f, b32 is_when) {
	if (!is_when && f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a block statement in the file scope");
		return make_bad_stmt(f, f->curr_token, f->curr_token);
	}
	return parse_body(f);
}

AstNode *convert_stmt_to_expr(AstFile *f, AstNode *statement, String kind) {
	if (statement == NULL) {
		return NULL;
	}

	if (statement->kind == AstNode_ExprStmt) {
		return statement->ExprStmt.expr;
	}

	syntax_error(f->curr_token, "Expected `%.*s`, found a simple statement.", LIT(kind));
	return make_bad_expr(f, f->curr_token, f->tokens.e[f->curr_token_index+1]);
}

AstNodeArray parse_identfier_list(AstFile *f) {
	AstNodeArray list = make_ast_node_array(f);

	do {
		array_add(&list, parse_identifier(f));
		if (f->curr_token.kind != Token_Comma ||
		    f->curr_token.kind == Token_EOF) {
		    break;
		}
		next_token(f);
	} while (true);

	return list;
}



AstNode *parse_type_attempt(AstFile *f) {
	AstNode *type = parse_identifier_or_type(f, 0);
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
		return make_bad_expr(f, token, f->curr_token);
	}
	return type;
}


Token parse_proc_signature(AstFile *f, AstNodeArray *params, AstNodeArray *results);

AstNode *parse_proc_type(AstFile *f) {
	AstNodeArray params = {0};
	AstNodeArray results = {0};

	Token proc_token = parse_proc_signature(f, &params, &results);

	return make_proc_type(f, proc_token, params, results);
}


AstNodeArray parse_parameter_list(AstFile *f) {
	AstNodeArray params = make_ast_node_array(f);

	while (f->curr_token.kind == Token_Ident ||
	       f->curr_token.kind == Token_using) {
		bool is_using = false;
		if (allow_token(f, Token_using)) {
			is_using = true;
		}

		AstNodeArray names = parse_lhs_expr_list(f);
		if (names.count == 0) {
			syntax_error(f->curr_token, "Empty parameter declaration");
		}

		if (names.count > 1 && is_using) {
			syntax_error(f->curr_token, "Cannot apply `using` to more than one of the same type");
			is_using = false;
		}

		expect_token_after(f, Token_Colon, "parameter list");

		AstNode *type = NULL;
		if (f->curr_token.kind == Token_Ellipsis) {
			Token ellipsis = f->curr_token;
			next_token(f);
			type = parse_type_attempt(f);
			if (type == NULL) {
				syntax_error(f->curr_token, "variadic parameter is missing a type after `..`");
				type = make_bad_expr(f, ellipsis, f->curr_token);
			} else {
				if (names.count > 1) {
					syntax_error(f->curr_token, "mutliple variadic parameters, only  `..`");
				} else {
					type = make_ellipsis(f, ellipsis, type);
				}
			}
		} else {
			type = parse_type_attempt(f);
		}


		if (type == NULL) {
			syntax_error(f->curr_token, "Expected a type for this parameter declaration");
		}

		array_add(&params, make_parameter(f, names, type, is_using));
		if (!parse_at_comma(f, str_lit("parameter list"), Token_CloseParen)) {
			break;
		}
		next_token(f);
	}

	return params;
}


AstNodeArray parse_record_params(AstFile *f, isize *decl_count_, bool using_allowed, String context) {
	AstNodeArray decls = make_ast_node_array(f);
	isize decl_count = 0;

	while (f->curr_token.kind != Token_CloseBrace &&
	       f->curr_token.kind != Token_EOF) {
		AstNode *decl = parse_stmt(f);
		if (is_ast_node_decl(decl) ||
		    decl->kind == AstNode_UsingStmt ||
		    decl->kind == AstNode_EmptyStmt) {
			switch (decl->kind) {
			case AstNode_EmptyStmt:
				break;

			case AstNode_ProcDecl:
				syntax_error(f->curr_token, "Procedure declarations are not allowed within a %.*s", LIT(context));
				break;

			case AstNode_UsingStmt: {
				bool is_using = true;
				if (!using_allowed) {
					syntax_error(f->curr_token, "Cannot apply `using` to members of a %.*s", LIT(context));
					is_using = false;
				}
				if (decl->UsingStmt.node->kind == AstNode_VarDecl) {
					AstNode *vd = decl->UsingStmt.node;
					vd->VarDecl.is_using = is_using && using_allowed;
					if (vd->VarDecl.values.count > 0) {
						syntax_error(f->curr_token, "Default variable assignments within a %.*s will be ignored", LIT(context));
					}
					array_add(&decls, vd);
				} else {
					syntax_error_node(decl, "Illegal %.*s field", LIT(context));
				}
			} break;

			case AstNode_VarDecl: {
				if (decl->VarDecl.values.count > 0) {
					syntax_error(f->curr_token, "Default variable assignments within a %.*s will be ignored", LIT(context));
				}
				array_add(&decls, decl);
			}

			case AstNode_BadDecl:
				break;

			case AstNode_ConstDecl:
			case AstNode_TypeDecl:
			default:
				decl_count += 1;
				array_add(&decls, decl);
				break;
			}
		} else {
			syntax_error_node(decl, "Illegal record field: %.*s", LIT(ast_node_strings[decl->kind]));
		}
	}

	if (decl_count_) *decl_count_ = decl_count;

	return decls;
}

AstNode *parse_identifier_or_type(AstFile *f, u32 flags) {
	switch (f->curr_token.kind) {
	case Token_Ident: {
		AstNode *e = parse_identifier(f);
		while (f->curr_token.kind == Token_Period) {
			Token token = f->curr_token;
			next_token(f);
			AstNode *sel = parse_identifier(f);
			e = make_selector_expr(f, token, e, sel);
		}
		if (f->curr_token.kind == Token_OpenParen) {
			// HACK NOTE(bill): For type_of_val(expr)
			e = parse_call_expr(f, e);
		}
		return e;
	}

	case Token_Pointer: {
		Token token = expect_token(f, Token_Pointer);
		AstNode *elem = parse_type(f);
		return make_pointer_type(f, token, elem);
	}

	case Token_Maybe: {
		Token token = expect_token(f, Token_Maybe);
		AstNode *elem = parse_type(f);
		return make_maybe_type(f, token, elem);
	}

	case Token_OpenBracket: {
		f->expr_level++;
		Token token = expect_token(f, Token_OpenBracket);
		AstNode *count_expr = NULL;
		bool is_vector = false;

		if (f->curr_token.kind == Token_Ellipsis) {
			count_expr = make_ellipsis(f, f->curr_token, NULL);
			next_token(f);
		} else if (f->curr_token.kind == Token_vector) {
			next_token(f);
			if (f->curr_token.kind != Token_CloseBracket) {
				count_expr = parse_expr(f, false);
			} else {
				syntax_error(f->curr_token, "Vector type missing count");
			}
			is_vector = true;
		} else if (f->curr_token.kind != Token_CloseBracket) {
			count_expr = parse_expr(f, false);
		}
		expect_token(f, Token_CloseBracket);
		f->expr_level--;
		if (is_vector) {
			return make_vector_type(f, token, count_expr, parse_type(f));
		}
		return make_array_type(f, token, count_expr, parse_type(f));
	}

	case Token_struct: {
		Token token = expect_token(f, Token_struct);
		bool is_packed = false;
		bool is_ordered = false;
		while (allow_token(f, Token_Hash)) {
			Token tag = expect_token_after(f, Token_Ident, "`#`");
			if (str_eq(tag.string, str_lit("packed"))) {
				if (is_packed) {
					syntax_error(tag, "Duplicate struct tag `#%.*s`", LIT(tag.string));
				}
				is_packed = true;
			} else if (str_eq(tag.string, str_lit("ordered"))) {
				if (is_ordered) {
					syntax_error(tag, "Duplicate struct tag `#%.*s`", LIT(tag.string));
				}
				is_ordered = true;
			} else {
				syntax_error(tag, "Invalid struct tag `#%.*s`", LIT(tag.string));
			}
		}

		if (is_packed && is_ordered) {
			syntax_error(token, "`#ordered` is not needed with `#packed` which implies ordering");
		}

		Token open = expect_token_after(f, Token_OpenBrace, "`struct`");
		isize decl_count = 0;
		AstNodeArray decls = parse_record_params(f, &decl_count, true, str_lit("struct"));
		Token close = expect_token(f, Token_CloseBrace);

		return make_struct_type(f, token, decls, decl_count, is_packed, is_ordered);
	} break;

	case Token_union: {
		Token token = expect_token(f, Token_union);
		Token open = expect_token_after(f, Token_OpenBrace, "`union`");
		isize decl_count = 0;
		AstNodeArray decls = parse_record_params(f, &decl_count, false, str_lit("union"));
		Token close = expect_token(f, Token_CloseBrace);

		return make_union_type(f, token, decls, decl_count);
	}

	case Token_raw_union: {
		Token token = expect_token(f, Token_raw_union);
		Token open = expect_token_after(f, Token_OpenBrace, "`raw_union`");
		isize decl_count = 0;
		AstNodeArray decls = parse_record_params(f, &decl_count, true, str_lit("raw_union"));
		Token close = expect_token(f, Token_CloseBrace);

		return make_raw_union_type(f, token, decls, decl_count);
	}

	case Token_enum: {
		Token token = expect_token(f, Token_enum);
		AstNode *base_type = NULL;
		Token open, close;

		if (f->curr_token.kind != Token_OpenBrace) {
			base_type = parse_type(f);
		}

		AstNodeArray fields = make_ast_node_array(f);

		open = expect_token_after(f, Token_OpenBrace, "`enum`");

		while (f->curr_token.kind != Token_CloseBrace &&
		       f->curr_token.kind != Token_EOF) {
			AstNode *name = parse_identifier(f);
			AstNode *value = NULL;
			Token eq = empty_token;
			if (f->curr_token.kind == Token_Eq) {
				eq = expect_token(f, Token_Eq);
				value = parse_value(f);
			}
			AstNode *field = make_field_value(f, name, value, eq);
			array_add(&fields, field);
			if (f->curr_token.kind != Token_Comma) {
				break;
			}
			next_token(f);
		}

		close = expect_token(f, Token_CloseBrace);

		return make_enum_type(f, token, base_type, fields);
	}

	case Token_proc:
		return parse_proc_type(f);

	case Token_OpenParen: {
		// NOTE(bill): Skip the paren expression
		AstNode *type;
		Token open, close;
		open = expect_token(f, Token_OpenParen);
		type = parse_type(f);
		close = expect_token(f, Token_CloseParen);
		return type;
		// return make_paren_expr(f, type, open, close);
	}

	// TODO(bill): Why is this even allowed? Is this a parsing error?
	case Token_Colon:
		break;

	case Token_Eq:
		if (f->prev_token.kind == Token_Colon) {
			break;
		}
		// fallthrough
	default: {
		String prev = str_lit("newline");
		if (str_ne(f->prev_token.string, str_lit("\n"))) {
			prev = f->prev_token.string;
		}
		syntax_error(f->curr_token,
		             "Expected a type or identifier after %.*s, got %.*s", LIT(prev), LIT(f->curr_token.string));
	} break;
	}

	return NULL;
}


AstNodeArray parse_results(AstFile *f) {
	AstNodeArray results = make_ast_node_array(f);
	if (allow_token(f, Token_ArrowRight)) {
		if (f->curr_token.kind == Token_OpenParen) {
			expect_token(f, Token_OpenParen);
			while (f->curr_token.kind != Token_CloseParen &&
			       f->curr_token.kind != Token_EOF) {
				array_add(&results, parse_type(f));
				if (f->curr_token.kind != Token_Comma) {
					break;
				}
				next_token(f);
			}
			expect_token(f, Token_CloseParen);

			return results;
		}

		array_add(&results, parse_type(f));
		return results;
	}
	return results;
}

Token parse_proc_signature(AstFile *f,
                           AstNodeArray *params,
                           AstNodeArray *results) {
	Token proc_token = expect_token(f, Token_proc);
	expect_token(f, Token_OpenParen);
	*params = parse_parameter_list(f);
	expect_token_after(f, Token_CloseParen, "parameter list");
	*results = parse_results(f);
	return proc_token;
}

AstNode *parse_body(AstFile *f) {
	AstNodeArray stmts = {0};
	Token open, close;
	open = expect_token(f, Token_OpenBrace);
	stmts = parse_stmt_list(f);
	close = expect_token(f, Token_CloseBrace);

	return make_block_stmt(f, stmts, open, close);
}



AstNode *parse_proc_decl(AstFile *f, Token proc_token, AstNode *name) {
	AstNode *proc_type = parse_proc_type(f);

	AstNode *body = NULL;
	u64 tags = 0;
	String foreign_name = {0};
	String link_name = {0};

	parse_proc_tags(f, &tags, &foreign_name, &link_name);

	AstNode *curr_proc = f->curr_proc;
	f->curr_proc = proc_type;

	if (f->curr_token.kind == Token_OpenBrace) {
		if ((tags & ProcTag_foreign) != 0) {
			syntax_error_node(name, "A procedure tagged as `#foreign` cannot have a body");
		}
		body = parse_body(f);
	} else if ((tags & ProcTag_foreign) == 0) {
		syntax_error_node(name, "Only a procedure tagged as `#foreign` cannot have a body");
	}

	f->curr_proc = curr_proc;
	return make_proc_decl(f, name, proc_type, body, tags, foreign_name, link_name);
}

AstNode *parse_decl(AstFile *f, AstNodeArray names) {
	AstNodeArray values = {0};
	AstNode *type = NULL;

	for_array(i, names) {
		AstNode *name = names.e[i];
		if (name->kind == AstNode_Ident) {
			String n = name->Ident.string;
			// NOTE(bill): Check for reserved identifiers
			if (str_eq(n, str_lit("context"))) {
				syntax_error_node(name, "`context` is a reserved identifier");
				break;
			}
		}
	}

	if (allow_token(f, Token_Colon)) {
		if (!allow_token(f, Token_type)) {
			type = parse_identifier_or_type(f, 0);
		}
	} else if (f->curr_token.kind != Token_Eq && f->curr_token.kind != Token_Semicolon) {
		syntax_error(f->curr_token, "Expected type separator `:` or `=`");
	}

	bool is_mutable = true;

	if (f->curr_token.kind == Token_Eq || f->curr_token.kind == Token_Colon) {
		if (f->curr_token.kind == Token_Colon) {
			is_mutable = false;
		}
		next_token(f);

		if (f->curr_token.kind == Token_type ||
		    f->curr_token.kind == Token_struct ||
		    f->curr_token.kind == Token_enum ||
		    f->curr_token.kind == Token_union ||
		    f->curr_token.kind == Token_raw_union) {
			Token token = f->curr_token;
			if (token.kind == Token_type) {
				next_token(f);
			}
			if (names.count != 1) {
				syntax_error_node(names.e[0], "You can only declare one type at a time");
				return make_bad_decl(f, names.e[0]->Ident, token);
			}

			if (type != NULL) {
				syntax_error(f->prev_token, "Expected either `type` or nothing between : and :");
				// NOTE(bill): Do not fail though
			}

			return make_type_decl(f, token, names.e[0], parse_type(f));
		} else if (f->curr_token.kind == Token_proc && is_mutable == false) {
		    // NOTE(bill): Procedure declarations
			Token proc_token = f->curr_token;
			AstNode *name = names.e[0];
			if (names.count != 1) {
				syntax_error(proc_token, "You can only declare one procedure at a time");
				return make_bad_decl(f, name->Ident, proc_token);
			}

			return parse_proc_decl(f, proc_token, name);

		} else {
			values = parse_rhs_expr_list(f);
			if (values.count > names.count) {
				syntax_error(f->curr_token, "Too many values on the right hand side of the declaration");
			} else if (values.count < names.count && !is_mutable) {
				syntax_error(f->curr_token, "All constant declarations must be defined");
			} else if (values.count == 0) {
				syntax_error(f->curr_token, "Expected an expression for this declaration");
			}
		}
	}

	if (is_mutable) {
		if (type == NULL && values.count == 0) {
			syntax_error(f->curr_token, "Missing variable type or initialization");
			return make_bad_decl(f, f->curr_token, f->curr_token);
		}
	} else {
		if (type == NULL && values.count == 0 && names.count > 0) {
			syntax_error(f->curr_token, "Missing constant value");
			return make_bad_decl(f, f->curr_token, f->curr_token);
		}
	}

	if (values.e == NULL) {
		values = make_ast_node_array(f);
	}

	if (is_mutable) {
		return make_var_decl(f, names, type, values);
	}
	return make_const_decl(f, names, type, values);
}


AstNode *parse_if_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use an if statement in the file scope");
		return make_bad_stmt(f, f->curr_token, f->curr_token);
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
		init = parse_simple_stmt(f);
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
			else_stmt = make_bad_stmt(f, f->curr_token, f->tokens.e[f->curr_token_index+1]);
			break;
		}
	} else {
		expect_semicolon(f, body);
	}

	return make_if_stmt(f, token, init, cond, body, else_stmt);
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
			else_stmt = make_bad_stmt(f, f->curr_token, f->tokens.e[f->curr_token_index+1]);
			break;
		}
	}

	return make_when_stmt(f, token, cond, body, else_stmt);
}


AstNode *parse_return_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a return statement in the file scope");
		return make_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_return);
	AstNodeArray results = make_ast_node_array(f);

	if (f->curr_token.kind != Token_Semicolon && f->curr_token.kind != Token_CloseBrace &&
	    f->curr_token.pos.line == token.pos.line) {
		results = parse_rhs_expr_list(f);
	}

	expect_semicolon(f, results.e[0]);
	return make_return_stmt(f, token, results);
}

AstNode *parse_for_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a for statement in the file scope");
		return make_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_for);

	AstNode *init = NULL;
	AstNode *cond = NULL;
	AstNode *end  = NULL;
	AstNode *body = NULL;

	if (f->curr_token.kind != Token_OpenBrace) {
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		if (f->curr_token.kind != Token_Semicolon) {
			cond = parse_simple_stmt(f);
			if (is_ast_node_complex_stmt(cond)) {
				syntax_error(f->curr_token,
				             "You are not allowed that type of statement in a for statement, it is too complex!");
			}
		}

		if (allow_token(f, Token_Semicolon)) {
			init = cond;
			cond = NULL;
			if (f->curr_token.kind != Token_Semicolon) {
				cond = parse_simple_stmt(f);
			}
			expect_token(f, Token_Semicolon);
			if (f->curr_token.kind != Token_OpenBrace) {
				end = parse_simple_stmt(f);
			}
		}
		f->expr_level = prev_level;
	}
	body = parse_block_stmt(f, false);

	cond = convert_stmt_to_expr(f, cond, str_lit("boolean expression"));

	return make_for_stmt(f, token, init, cond, end, body);
}

AstNode *parse_case_clause(AstFile *f) {
	Token token = f->curr_token;
	AstNodeArray list = make_ast_node_array(f);
	if (allow_token(f, Token_case)) {
		list = parse_rhs_expr_list(f);
	} else {
		expect_token(f, Token_default);
	}
	expect_token(f, Token_Colon); // TODO(bill): Is this the best syntax?
	// expect_token(f, Token_ArrowRight); // TODO(bill): Is this the best syntax?
	AstNodeArray stmts = parse_stmt_list(f);

	return make_case_clause(f, token, list, stmts);
}


AstNode *parse_type_case_clause(AstFile *f) {
	Token token = f->curr_token;
	AstNodeArray clause = make_ast_node_array(f);
	if (allow_token(f, Token_case)) {
		array_add(&clause, parse_type(f));
	} else {
		expect_token(f, Token_default);
	}
	expect_token(f, Token_Colon); // TODO(bill): Is this the best syntax?
	// expect_token(f, Token_ArrowRight); // TODO(bill): Is this the best syntax?
	AstNodeArray stmts = parse_stmt_list(f);

	return make_case_clause(f, token, clause, stmts);
}


AstNode *parse_match_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a match statement in the file scope");
		return make_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_match);
	AstNode *init = NULL;
	AstNode *tag  = NULL;
	AstNode *body = NULL;
	Token open, close;

	if (allow_token(f, Token_type)) {
		isize prev_level = f->expr_level;
		f->expr_level = -1;

		AstNode *var = parse_identifier(f);
		expect_token(f, Token_Colon);
		tag = parse_simple_stmt(f);

		f->expr_level = prev_level;

		open = expect_token(f, Token_OpenBrace);
		AstNodeArray list = make_ast_node_array(f);

		while (f->curr_token.kind == Token_case ||
		       f->curr_token.kind == Token_default) {
			array_add(&list, parse_type_case_clause(f));
		}

		close = expect_token(f, Token_CloseBrace);
		body = make_block_stmt(f, list, open, close);

		tag = convert_stmt_to_expr(f, tag, str_lit("type match expression"));
		return make_type_match_stmt(f, token, tag, var, body);
	} else {
		if (f->curr_token.kind != Token_OpenBrace) {
			isize prev_level = f->expr_level;
			f->expr_level = -1;
			if (f->curr_token.kind != Token_Semicolon) {
				tag = parse_simple_stmt(f);
			}
			if (allow_token(f, Token_Semicolon)) {
				init = tag;
				tag = NULL;
				if (f->curr_token.kind != Token_OpenBrace) {
					tag = parse_simple_stmt(f);
				}
			}

			f->expr_level = prev_level;
		}

		open = expect_token(f, Token_OpenBrace);
		AstNodeArray list = make_ast_node_array(f);

		while (f->curr_token.kind == Token_case ||
		       f->curr_token.kind == Token_default) {
			array_add(&list, parse_case_clause(f));
		}

		close = expect_token(f, Token_CloseBrace);

		body = make_block_stmt(f, list, open, close);

		tag = convert_stmt_to_expr(f, tag, str_lit("match expression"));
		return make_match_stmt(f, token, init, tag, body);
	}
}


AstNode *parse_defer_stmt(AstFile *f) {
	if (f->curr_proc == NULL) {
		syntax_error(f->curr_token, "You cannot use a defer statement in the file scope");
		return make_bad_stmt(f, f->curr_token, f->curr_token);
	}

	Token token = expect_token(f, Token_defer);
	AstNode *statement = parse_stmt(f);
	switch (statement->kind) {
	case AstNode_EmptyStmt:
		syntax_error(token, "Empty statement after defer (e.g. `;`)");
		break;
	case AstNode_DeferStmt:
		syntax_error(token, "You cannot defer a defer statement");
		break;
	case AstNode_ReturnStmt:
		syntax_error(token, "You cannot a return statement");
		break;
	}

	return make_defer_stmt(f, token, statement);
}

AstNode *parse_asm_stmt(AstFile *f) {
	Token token = expect_token(f, Token_asm);
	bool is_volatile = false;
	if (allow_token(f, Token_volatile)) {
		is_volatile = true;
	}
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

	return make_asm_stmt(f, token, is_volatile, open, close, code_string,
	                     output_list, input_list, clobber_list,
	                     output_count, input_count, clobber_count);

}



AstNode *parse_stmt(AstFile *f) {
	AstNode *s = NULL;
	Token token = f->curr_token;
	switch (token.kind) {
	// Operands
	case Token_Ident:
	case Token_Integer:
	case Token_Float:
	case Token_Rune:
	case Token_String:
	case Token_OpenParen:
	case Token_proc:
	// Unary Operators
	case Token_Add:
	case Token_Sub:
	case Token_Xor:
	case Token_Not:
		s = parse_simple_stmt(f);
		expect_semicolon(f, s);
		return s;

	// TODO(bill): other keywords
	case Token_if:     return parse_if_stmt(f);
	case Token_when:   return parse_when_stmt(f);
	case Token_for:    return parse_for_stmt(f);
	case Token_match:  return parse_match_stmt(f);
	case Token_defer:  return parse_defer_stmt(f);
	case Token_asm:    return parse_asm_stmt(f);
	case Token_return: return parse_return_stmt(f);

	case Token_break:
	case Token_continue:
	case Token_fallthrough:
		next_token(f);
		s = make_branch_stmt(f, token);
		expect_semicolon(f, s);
		return s;


	case Token_using: {
		AstNode *node = NULL;

		next_token(f);
		node = parse_stmt(f);

		bool valid = false;

		switch (node->kind) {
		case AstNode_ExprStmt: {
			AstNode *e = unparen_expr(node->ExprStmt.expr);
			while (e->kind == AstNode_SelectorExpr) {
				e = unparen_expr(e->SelectorExpr.selector);
			}
			if (e->kind == AstNode_Ident) {
				valid = true;
			}
		} break;
		case AstNode_VarDecl:
			valid = true;
			break;
		}

		if (!valid) {
			syntax_error(token, "Illegal use of `using` statement.");
			return make_bad_stmt(f, token, f->curr_token);
		}


		return make_using_stmt(f, token, node);
	} break;

	case Token_push_allocator: {
		next_token(f);
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		AstNode *expr = parse_expr(f, false);
		f->expr_level = prev_level;

		AstNode *body = parse_block_stmt(f, false);
		return make_push_allocator(f, token, expr, body);
	} break;

	case Token_push_context: {
		next_token(f);
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		AstNode *expr = parse_expr(f, false);
		f->expr_level = prev_level;

		AstNode *body = parse_block_stmt(f, false);
		return make_push_context(f, token, expr, body);
	} break;

	case Token_Hash: {
		AstNode *s = NULL;
		Token hash_token = expect_token(f, Token_Hash);
		Token name = expect_token(f, Token_Ident);
		String tag = name.string;
		if (str_eq(tag, str_lit("shared_global_scope"))) {
			if (f->curr_proc == NULL) {
				f->is_global_scope = true;
				s = make_empty_stmt(f, f->curr_token);
			} else {
				syntax_error(token, "You cannot use #shared_global_scope within a procedure. This must be done at the file scope");
				s = make_bad_decl(f, token, f->curr_token);
			}
			expect_semicolon(f, s);
			return s;
		} else if (str_eq(tag, str_lit("foreign_system_library"))) {
			AstNode *cond = NULL;
			Token file_path = expect_token(f, Token_String);

			if (allow_token(f, Token_when)) {
				cond = parse_expr(f, false);
			}

			if (f->curr_proc == NULL) {
				s = make_foreign_library(f, hash_token, file_path, cond, true);
			} else {
				syntax_error(token, "You cannot use #foreign_system_library within a procedure. This must be done at the file scope");
				s = make_bad_decl(f, token, file_path);
			}
			expect_semicolon(f, s);
			return s;
		} else if (str_eq(tag, str_lit("foreign_library"))) {
			AstNode *cond = NULL;
			Token file_path = expect_token(f, Token_String);

			if (allow_token(f, Token_when)) {
				cond = parse_expr(f, false);
			}

			if (f->curr_proc == NULL) {
				s = make_foreign_library(f, hash_token, file_path, cond, false);
			} else {
				syntax_error(token, "You cannot use #foreign_library within a procedure. This must be done at the file scope");
				s = make_bad_decl(f, token, file_path);
			}
			expect_semicolon(f, s);
			return s;
		}  else if (str_eq(tag, str_lit("import"))) {
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
				import_name.pos = hash_token.pos;
				break;
			}

			if (str_eq(import_name.string, str_lit("_"))) {
				syntax_error(token, "Illegal import name: `_`");
			}

			Token file_path = expect_token_after(f, Token_String, "#import");
			if (allow_token(f, Token_when)) {
				cond = parse_expr(f, false);
			}

			if (f->curr_proc != NULL) {
				syntax_error(token, "You cannot use #import within a procedure. This must be done at the file scope");
				s = make_bad_decl(f, token, file_path);
			} else {
				s = make_import_decl(f, hash_token, file_path, import_name, cond, false);
				expect_semicolon(f, s);
			}
			return s;
		} else if (str_eq(tag, str_lit("include"))) {
			AstNode *cond = NULL;
			Token file_path = expect_token(f, Token_String);
			Token import_name = file_path;
			import_name.string = str_lit(".");

			if (allow_token(f, Token_when)) {
				cond = parse_expr(f, false);
			}

			if (f->curr_proc == NULL) {
				s = make_import_decl(f, hash_token, file_path, import_name, cond, true);
			} else {
				syntax_error(token, "You cannot use #include within a procedure. This must be done at the file scope");
				s = make_bad_decl(f, token, file_path);
			}
			expect_semicolon(f, s);
			return s;
		} else if (str_eq(tag, str_lit("thread_local"))) {
			AstNode *var_decl = parse_simple_stmt(f);
			if (var_decl->kind != AstNode_VarDecl) {
				syntax_error(token, "#thread_local may only be applied to variable declarations");
				return make_bad_decl(f, token, ast_node_token(var_decl));
			}
			if (f->curr_proc != NULL) {
				syntax_error(token, "#thread_local is only allowed at the file scope");
				return make_bad_decl(f, token, ast_node_token(var_decl));
			}
			var_decl->VarDecl.tags |= VarDeclTag_thread_local;
			return var_decl;
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

		return make_tag_stmt(f, hash_token, name, parse_stmt(f));
	} break;

	case Token_OpenBrace:
		return parse_block_stmt(f, false);

	case Token_Semicolon:
		s = make_empty_stmt(f, token);
		next_token(f);
		return s;
	}

	syntax_error(token,
	             "Expected a statement, got `%.*s`",
	             LIT(token_strings[token.kind]));
	fix_advance_to_next_stmt(f);
	return make_bad_stmt(f, token, f->curr_token);
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
		}
	}

	return list;
}


ParseFileError init_ast_file(AstFile *f, String fullpath) {
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
#if 1
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


// // NOTE(bill): Returns true if it's added
// bool try_add_foreign_library_path(Parser *p, String import_file) {
// 	gb_mutex_lock(&p->mutex);

// 	for_array(i, p->foreign_libraries) {
// 		String import = p->foreign_libraries.e[i];
// 		if (str_eq(import, import_file)) {
// 			return false;
// 		}
// 	}
// 	array_add(&p->foreign_libraries, import_file);
// 	gb_mutex_unlock(&p->mutex);
// 	return true;
// }

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
		Rune r = -1;
		while (curr < end) {
			isize width = 1;
			r = curr[0];
			if (r >= 0x80) {
				width = gb_utf8_decode(curr, end-curr, &r);
				if (r == GB_RUNE_INVALID && width == 1)
					return false;
				else if (r == GB_RUNE_BOM && curr-start > 0)
					return false;
			}

			for (isize i = 0; i < gb_count_of(illegal_import_runes); i++) {
				if (r == illegal_import_runes[i])
					return false;
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
			AstNodeImportDecl *id = &node->ImportDecl;
			String file_str = id->relpath.string;

			if (!is_import_path_valid(file_str)) {
				if (id->is_load) {
					syntax_error_node(node, "Invalid #include path: `%.*s`", LIT(file_str));
				} else {
					syntax_error_node(node, "Invalid #import path: `%.*s`", LIT(file_str));
				}
				// NOTE(bill): It's a naughty name
				decls.e[i] = make_bad_decl(f, id->token, id->token);
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
				f->decls.e[i] = make_bad_decl(f, fl->token, fl->token);
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
				gb_printf_err("Invalid file");
				break;
			case ParseFile_Permission:
				gb_printf_err("File permissions problem");
				break;
			case ParseFile_NotFound:
				gb_printf_err("File cannot be found");
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
			gb_mutex_unlock(&p->mutex);
		}
	}

	for_array(i, p->files) {
		p->total_token_count += p->files.e[i].tokens.count;
	}


	return ParseFile_None;
}


