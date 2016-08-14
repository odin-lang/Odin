struct AstNode;
struct Type;
struct AstScope;

enum ParseFileError {
	ParseFile_None,

	ParseFile_WrongExtension,
	ParseFile_InvalidFile,
	ParseFile_EmptyFile,
	ParseFile_Permission,
	ParseFile_NotFound,
	ParseFile_InvalidToken,

	ParseFile_Count,
};


struct AstFile {
	gbArena        arena;
	Tokenizer      tokenizer;
	gbArray(Token) tokens;
	Token *        cursor; // NOTE(bill): Current token, easy to peek forward and backwards if needed

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	isize expr_level;

	AstNode *decls;
	isize decl_count;

	AstScope *file_scope;
	AstScope *curr_scope;
	isize scope_level;

	ErrorCollector error_collector;

	// NOTE(bill): Error recovery
#define PARSER_MAX_FIX_COUNT 6
	isize    fix_count;
	TokenPos fix_prev_pos;
};

// NOTE(bill): Just used to quickly check if there is double declaration in the same scope
// No type checking actually happens
// TODO(bill): Should this be completely handled in the semantic checker or is it better here?
struct AstEntity {
	Token     token;
	AstScope *parent;
	AstNode * decl;
};

struct AstScope {
	AstScope *parent;
	Map<AstEntity> entities; // Key: Token.string
};

struct Parser {
	String init_fullpath;
	gbArray(AstFile) files;
	gbArray(String) imports;
	isize import_index;
	isize total_token_count;
};

enum DeclKind {
	Declaration_Invalid,
	Declaration_Mutable,
	Declaration_Immutable,
	Declaration_Count,
};

enum ProcTag {
	ProcTag_foreign   = GB_BIT(0),
	ProcTag_inline    = GB_BIT(1),
	ProcTag_no_inline = GB_BIT(2),
};

#define AST_NODE_KINDS \
	AST_NODE_KIND(Invalid, struct{}) \
	AST_NODE_KIND(BasicLit, Token) \
	AST_NODE_KIND(Ident, struct { \
		Token token; \
		AstEntity *entity; \
	}) \
	AST_NODE_KIND(ProcLit, struct { \
		AstNode *type; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(CompoundLit, struct { \
		AstNode *type; \
		AstNode *elem_list; \
		isize elem_count; \
		Token open, close; \
	}) \
AST_NODE_KIND(_ExprBegin,       struct{}) \
	AST_NODE_KIND(BadExpr,      struct { Token begin, end; }) \
	AST_NODE_KIND(TagExpr,      struct { Token token, name; AstNode *expr; }) \
	AST_NODE_KIND(UnaryExpr,    struct { Token op; AstNode *expr; }) \
	AST_NODE_KIND(BinaryExpr,   struct { Token op; AstNode *left, *right; } ) \
	AST_NODE_KIND(ParenExpr,    struct { AstNode *expr; Token open, close; }) \
	AST_NODE_KIND(SelectorExpr, struct { Token token; AstNode *expr, *selector; }) \
	AST_NODE_KIND(IndexExpr,    struct { AstNode *expr, *index; Token open, close; }) \
	AST_NODE_KIND(DerefExpr,    struct { Token op; AstNode *expr; }) \
	AST_NODE_KIND(CallExpr, struct { \
		AstNode *proc, *arg_list; \
		isize arg_list_count; \
		Token open, close; \
	}) \
	AST_NODE_KIND(SliceExpr, struct { \
		AstNode *expr; \
		Token open, close; \
		AstNode *low, *high, *max; \
		b32 triple_indexed; \
	}) \
	AST_NODE_KIND(Ellipsis, struct { Token token; }) \
AST_NODE_KIND(_ExprEnd,       struct{}) \
AST_NODE_KIND(_StmtBegin,     struct{}) \
	AST_NODE_KIND(BadStmt,    struct { Token begin, end; }) \
	AST_NODE_KIND(EmptyStmt,  struct { Token token; }) \
	AST_NODE_KIND(ExprStmt,   struct { AstNode *expr; } ) \
	AST_NODE_KIND(IncDecStmt, struct { Token op; AstNode *expr; }) \
	AST_NODE_KIND(TagStmt, struct { \
		Token token; \
		Token name; \
		AstNode *stmt; \
	}) \
	AST_NODE_KIND(AssignStmt, struct { \
		Token op; \
		AstNode *lhs_list, *rhs_list; \
		isize lhs_count, rhs_count; \
	}) \
AST_NODE_KIND(_ComplexStmtBegin, struct{}) \
	AST_NODE_KIND(BlockStmt, struct { \
		AstNode *list; \
		isize list_count; \
		Token open, close; \
	}) \
	AST_NODE_KIND(IfStmt, struct { \
		Token token; \
		AstNode *init; \
		AstNode *cond; \
		AstNode *body; \
		AstNode *else_stmt; \
	}) \
	AST_NODE_KIND(ReturnStmt, struct { \
		Token token; \
		AstNode *result_list; \
		isize result_count; \
	}) \
	AST_NODE_KIND(ForStmt, struct { \
		Token token; \
		AstNode *init, *cond, *post; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(DeferStmt,  struct { Token token; AstNode *stmt; }) \
	AST_NODE_KIND(BranchStmt, struct { Token token; }) \
\
AST_NODE_KIND(_ComplexStmtEnd, struct{}) \
AST_NODE_KIND(_StmtEnd,        struct{}) \
AST_NODE_KIND(_DeclBegin,      struct{}) \
	AST_NODE_KIND(BadDecl, struct { Token begin, end; }) \
	AST_NODE_KIND(VarDecl, struct { \
			DeclKind kind; \
			AstNode *name_list; \
			AstNode *type; \
			AstNode *value_list; \
			isize name_count, value_count; \
		}) \
	AST_NODE_KIND(ProcDecl, struct { \
			AstNode *name;           \
			AstNode *type;           \
			AstNode *body;           \
			u64     tags;            \
			String  foreign_name;    \
		}) \
	AST_NODE_KIND(TypeDecl,   struct { Token token; AstNode *name, *type; }) \
	AST_NODE_KIND(AliasDecl,  struct { Token token; AstNode *name, *type; }) \
	AST_NODE_KIND(ImportDecl, struct { Token token, filepath; }) \
AST_NODE_KIND(_DeclEnd, struct{}) \
AST_NODE_KIND(_TypeBegin, struct{}) \
	AST_NODE_KIND(Field, struct { \
		AstNode *name_list; \
		isize name_count; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(ProcType, struct { \
		Token token;          \
		AstNode *param_list;  \
		AstNode *result_list; \
		isize param_count;    \
		isize result_count;   \
	}) \
	AST_NODE_KIND(PointerType, struct { \
		Token token; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(ArrayType, struct { \
		Token token; \
		AstNode *count; \
		AstNode *elem; \
	}) \
	AST_NODE_KIND(VectorType, struct { \
		Token token; \
		AstNode *count; \
		AstNode *elem; \
	}) \
	AST_NODE_KIND(StructType, struct { \
		Token token; \
		AstNode *field_list; \
		isize field_count; \
		b32 is_packed; \
	}) \
AST_NODE_KIND(_TypeEnd, struct{}) \
	AST_NODE_KIND(Count, struct{})

enum AstNodeKind {
#define AST_NODE_KIND(name, ...) GB_JOIN2(AstNode_, name),
	AST_NODE_KINDS
#undef AST_NODE_KIND
};

String const ast_node_strings[] = {
#define AST_NODE_KIND(name, ...) {cast(u8 *)#name, gb_size_of(#name)-1},
	AST_NODE_KINDS
#undef AST_NODE_KIND
};

struct AstNode {
	AstNodeKind kind;
	AstNode *prev, *next; // NOTE(bill): allow for Linked list
	union {
#define AST_NODE_KIND(_kind_name_, ...) __VA_ARGS__ _kind_name_;
	AST_NODE_KINDS
#undef AST_NODE_KIND
	};
};


#define ast_node(n_, Kind_, node_) auto *n_ = &(node_)->Kind_; GB_ASSERT((node_)->kind == GB_JOIN2(AstNode_, Kind_))
#define case_ast_node(n_, Kind_, node_) case GB_JOIN2(AstNode_, Kind_): { ast_node(n_, Kind_, node_);
#define case_end } break;





gb_inline AstScope *make_ast_scope(AstFile *f, AstScope *parent) {
	AstScope *scope = gb_alloc_item(gb_arena_allocator(&f->arena), AstScope);
	map_init(&scope->entities, gb_heap_allocator());
	scope->parent = parent;
	return scope;
}


gb_inline b32 is_ast_node_expr(AstNode *node) {
	return gb_is_between(node->kind, AstNode__ExprBegin+1, AstNode__ExprEnd-1);
}
gb_inline b32 is_ast_node_stmt(AstNode *node) {
	return gb_is_between(node->kind, AstNode__StmtBegin+1, AstNode__StmtEnd-1);
}
gb_inline b32 is_ast_node_complex_stmt(AstNode *node) {
	return gb_is_between(node->kind, AstNode__ComplexStmtBegin+1, AstNode__ComplexStmtEnd-1);
}
gb_inline b32 is_ast_node_decl(AstNode *node) {
	return gb_is_between(node->kind, AstNode__DeclBegin+1, AstNode__DeclEnd-1);
}
gb_inline b32 is_ast_node_type(AstNode *node) {
	return gb_is_between(node->kind, AstNode__TypeBegin+1, AstNode__TypeEnd-1);
}


Token ast_node_token(AstNode *node) {
	switch (node->kind) {
	case AstNode_BasicLit:
		return node->BasicLit;
	case AstNode_Ident:
		return node->Ident.token;
	case AstNode_ProcLit:
		return ast_node_token(node->ProcLit.type);
	case AstNode_CompoundLit:
		return ast_node_token(node->CompoundLit.type);
	case AstNode_TagExpr:
		return node->TagExpr.token;
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
	case AstNode_DerefExpr:
		return node->DerefExpr.op;
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
	case AstNode_ReturnStmt:
		return node->ReturnStmt.token;
	case AstNode_ForStmt:
		return node->ForStmt.token;
	case AstNode_DeferStmt:
		return node->DeferStmt.token;
	case AstNode_BranchStmt:
		return node->BranchStmt.token;
	case AstNode_BadDecl:
		return node->BadDecl.begin;
	case AstNode_VarDecl:
		return ast_node_token(node->VarDecl.name_list);
	case AstNode_ProcDecl:
		return node->ProcDecl.name->Ident.token;
	case AstNode_TypeDecl:
		return node->TypeDecl.token;
	case AstNode_AliasDecl:
		return node->AliasDecl.token;
	case AstNode_ImportDecl:
		return node->ImportDecl.token;
	case AstNode_Field: {
		if (node->Field.name_list)
			return ast_node_token(node->Field.name_list);
		else
			return ast_node_token(node->Field.type);
	}
	case AstNode_ProcType:
		return node->ProcType.token;
	case AstNode_PointerType:
		return node->PointerType.token;
	case AstNode_ArrayType:
		return node->ArrayType.token;
	case AstNode_VectorType:
		return node->VectorType.token;
	case AstNode_StructType:
		return node->StructType.token;
	}

	return empty_token;
;}

gb_inline void destroy_ast_scope(AstScope *scope) {
	// NOTE(bill): No need to free the actual pointer to the AstScope
	// as there should be enough room in the arena
	map_destroy(&scope->entities);
}

gb_inline AstScope *open_ast_scope(AstFile *f) {
	AstScope *scope = make_ast_scope(f, f->curr_scope);
	f->curr_scope = scope;
	f->scope_level++;
	return f->curr_scope;
}

gb_inline void close_ast_scope(AstFile *f) {
	GB_ASSERT_NOT_NULL(f->curr_scope);
	GB_ASSERT(f->scope_level > 0);
	{
		AstScope *parent = f->curr_scope->parent;
		if (f->curr_scope) {
			destroy_ast_scope(f->curr_scope);
		}
		f->curr_scope = parent;
		f->scope_level--;
	}
}

AstEntity *make_ast_entity(AstFile *f, Token token, AstNode *decl, AstScope *parent) {
	AstEntity *entity = gb_alloc_item(gb_arena_allocator(&f->arena), AstEntity);
	entity->token = token;
	entity->decl = decl;
	entity->parent = parent;
	return entity;
}

u64 hash_token(Token t) {
	return hash_string(t.string);
}

AstEntity *ast_scope_lookup(AstScope *scope, Token token) {
	return map_get(&scope->entities, hash_token(token));
}

AstEntity *ast_scope_insert(AstScope *scope, AstEntity entity) {
	AstEntity *prev = ast_scope_lookup(scope, entity.token);
	if (prev == NULL) {
		map_set(&scope->entities, hash_token(entity.token), entity);
	}
	return prev;
}


#define ast_file_err(f, token, fmt, ...) ast_file_err_(f, __FUNCTION__, token, fmt, ##__VA_ARGS__)
void ast_file_err_(AstFile *file, char *function, Token token, char *fmt, ...) {
	// NOTE(bill): Duplicate error, skip it
	if (!token_pos_are_equal(file->error_collector.prev, token.pos)) {
		va_list va;

		file->error_collector.prev = token.pos;

	#if 0
		gb_printf_err("%s()\n", function);
	#endif
		va_start(va, fmt);
		gb_printf_err("%.*s(%td:%td) Syntax error: %s\n",
		              LIT(token.pos.file), token.pos.line, token.pos.column,
		              gb_bprintf_va(fmt, va));
		va_end(va);
	}
	file->error_collector.count++;
}


// NOTE(bill): And this below is why is I/we need a new language! Discriminated unions are a pain in C/C++
gb_inline AstNode *make_node(AstFile *f, AstNodeKind kind) {
	gbArena *arena = &f->arena;
	if (gb_arena_size_remaining(arena, GB_DEFAULT_MEMORY_ALIGNMENT) < gb_size_of(AstNode)) {
		// NOTE(bill): If a syntax error is so bad, just quit!
		gb_exit(1);
	}
	AstNode *node = gb_alloc_item(gb_arena_allocator(arena), AstNode);
	node->kind = kind;
	return node;
}

gb_inline AstNode *make_bad_expr(AstFile *f, Token begin, Token end) {
	AstNode *result = make_node(f, AstNode_BadExpr);
	result->BadExpr.begin = begin;
	result->BadExpr.end   = end;
	return result;
}

gb_inline AstNode *make_tag_expr(AstFile *f, Token token, Token name, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_TagExpr);
	result->TagExpr.token = token;
	result->TagExpr.name = name;
	result->TagExpr.expr = expr;
	return result;
}

gb_inline AstNode *make_tag_stmt(AstFile *f, Token token, Token name, AstNode *stmt) {
	AstNode *result = make_node(f, AstNode_TagStmt);
	result->TagStmt.token = token;
	result->TagStmt.name = name;
	result->TagStmt.stmt = stmt;
	return result;
}

gb_inline AstNode *make_unary_expr(AstFile *f, Token op, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_UnaryExpr);
	result->UnaryExpr.op = op;
	result->UnaryExpr.expr = expr;
	return result;
}

gb_inline AstNode *make_binary_expr(AstFile *f, Token op, AstNode *left, AstNode *right) {
	AstNode *result = make_node(f, AstNode_BinaryExpr);

	if (left == NULL) {
		ast_file_err(f, op, "No lhs expression for binary expression `%.*s`", LIT(op.string));
		left = make_bad_expr(f, op, op);
	}
	if (right == NULL) {
		ast_file_err(f, op, "No rhs expression for binary expression `%.*s`", LIT(op.string));
		right = make_bad_expr(f, op, op);
	}

	result->BinaryExpr.op = op;
	result->BinaryExpr.left = left;
	result->BinaryExpr.right = right;

	return result;
}

gb_inline AstNode *make_paren_expr(AstFile *f, AstNode *expr, Token open, Token close) {
	AstNode *result = make_node(f, AstNode_ParenExpr);
	result->ParenExpr.expr = expr;
	result->ParenExpr.open = open;
	result->ParenExpr.close = close;
	return result;
}

gb_inline AstNode *make_call_expr(AstFile *f, AstNode *proc, AstNode *arg_list, isize arg_list_count, Token open, Token close) {
	AstNode *result = make_node(f, AstNode_CallExpr);
	result->CallExpr.proc = proc;
	result->CallExpr.arg_list = arg_list;
	result->CallExpr.arg_list_count = arg_list_count;
	result->CallExpr.open  = open;
	result->CallExpr.close = close;
	return result;
}

gb_inline AstNode *make_selector_expr(AstFile *f, Token token, AstNode *expr, AstNode *selector) {
	AstNode *result = make_node(f, AstNode_SelectorExpr);
	result->SelectorExpr.expr = expr;
	result->SelectorExpr.selector = selector;
	return result;
}

gb_inline AstNode *make_index_expr(AstFile *f, AstNode *expr, AstNode *index, Token open, Token close) {
	AstNode *result = make_node(f, AstNode_IndexExpr);
	result->IndexExpr.expr = expr;
	result->IndexExpr.index = index;
	result->IndexExpr.open = open;
	result->IndexExpr.close = close;
	return result;
}


gb_inline AstNode *make_slice_expr(AstFile *f, AstNode *expr, Token open, Token close, AstNode *low, AstNode *high, AstNode *max, b32 triple_indexed) {
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

gb_inline AstNode *make_deref_expr(AstFile *f, AstNode *expr, Token op) {
	AstNode *result = make_node(f, AstNode_DerefExpr);
	result->DerefExpr.expr = expr;
	result->DerefExpr.op = op;
	return result;
}


gb_inline AstNode *make_ellipsis(AstFile *f, Token token) {
	AstNode *result = make_node(f, AstNode_Ellipsis);
	result->Ellipsis.token = token;
	return result;
}
gb_inline AstNode *make_basic_lit(AstFile *f, Token basic_lit) {
	AstNode *result = make_node(f, AstNode_BasicLit);
	result->BasicLit = basic_lit;
	return result;
}

gb_inline AstNode *make_identifier(AstFile *f, Token token, AstEntity *entity = NULL) {
	AstNode *result = make_node(f, AstNode_Ident);
	result->Ident.token = token;
	result->Ident.entity   = entity;
	return result;
}

gb_inline AstNode *make_procedure_literal(AstFile *f, AstNode *type, AstNode *body) {
	AstNode *result = make_node(f, AstNode_ProcLit);
	result->ProcLit.type = type;
	result->ProcLit.body = body;
	return result;
}


gb_inline AstNode *make_compound_literal(AstFile *f, AstNode *type, AstNode *elem_list, isize elem_count,
                                         Token open, Token close) {
	AstNode *result = make_node(f, AstNode_CompoundLit);
	result->CompoundLit.type = type;
	result->CompoundLit.elem_list = elem_list;
	result->CompoundLit.elem_count = elem_count;
	result->CompoundLit.open = open;
	result->CompoundLit.close = close;
	return result;
}

gb_inline AstNode *make_bad_stmt(AstFile *f, Token begin, Token end) {
	AstNode *result = make_node(f, AstNode_BadStmt);
	result->BadStmt.begin = begin;
	result->BadStmt.end   = end;
	return result;
}

gb_inline AstNode *make_empty_stmt(AstFile *f, Token token) {
	AstNode *result = make_node(f, AstNode_EmptyStmt);
	result->EmptyStmt.token = token;
	return result;
}

gb_inline AstNode *make_expr_stmt(AstFile *f, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_ExprStmt);
	result->ExprStmt.expr = expr;
	return result;
}

gb_inline AstNode *make_inc_dec_stmt(AstFile *f, Token op, AstNode *expr) {
	AstNode *result = make_node(f, AstNode_IncDecStmt);
	result->IncDecStmt.op = op;
	result->IncDecStmt.expr = expr;
	return result;
}

gb_inline AstNode *make_assign_stmt(AstFile *f, Token op, AstNode *lhs_list, isize lhs_count, AstNode *rhs_list, isize rhs_count) {
	AstNode *result = make_node(f, AstNode_AssignStmt);
	result->AssignStmt.op = op;
	result->AssignStmt.lhs_list = lhs_list;
	result->AssignStmt.lhs_count = lhs_count;
	result->AssignStmt.rhs_list = rhs_list;
	result->AssignStmt.rhs_count = rhs_count;
	return result;
}

gb_inline AstNode *make_block_stmt(AstFile *f, AstNode *list, isize list_count, Token open, Token close) {
	AstNode *result = make_node(f, AstNode_BlockStmt);
	result->BlockStmt.list = list;
	result->BlockStmt.list_count = list_count;
	result->BlockStmt.open = open;
	result->BlockStmt.close = close;
	return result;
}

gb_inline AstNode *make_if_stmt(AstFile *f, Token token, AstNode *init, AstNode *cond, AstNode *body, AstNode *else_stmt) {
	AstNode *result = make_node(f, AstNode_IfStmt);
	result->IfStmt.token = token;
	result->IfStmt.init = init;
	result->IfStmt.cond = cond;
	result->IfStmt.body = body;
	result->IfStmt.else_stmt = else_stmt;
	return result;
}

gb_inline AstNode *make_return_stmt(AstFile *f, Token token, AstNode *result_list, isize result_count) {
	AstNode *result = make_node(f, AstNode_ReturnStmt);
	result->ReturnStmt.token = token;
	result->ReturnStmt.result_list = result_list;
	result->ReturnStmt.result_count = result_count;
	return result;
}

gb_inline AstNode *make_for_stmt(AstFile *f, Token token, AstNode *init, AstNode *cond, AstNode *post, AstNode *body) {
	AstNode *result = make_node(f, AstNode_ForStmt);
	result->ForStmt.token = token;
	result->ForStmt.init = init;
	result->ForStmt.cond = cond;
	result->ForStmt.post = post;
	result->ForStmt.body = body;
	return result;
}
gb_inline AstNode *make_defer_stmt(AstFile *f, Token token, AstNode *stmt) {
	AstNode *result = make_node(f, AstNode_DeferStmt);
	result->DeferStmt.token = token;
	result->DeferStmt.stmt = stmt;
	return result;
}

gb_inline AstNode *make_branch_stmt(AstFile *f, Token token) {
	AstNode *result = make_node(f, AstNode_BranchStmt);
	result->BranchStmt.token = token;
	return result;
}


gb_inline AstNode *make_bad_decl(AstFile *f, Token begin, Token end) {
	AstNode *result = make_node(f, AstNode_BadDecl);
	result->BadDecl.begin = begin;
	result->BadDecl.end = end;
	return result;
}

gb_inline AstNode *make_var_decl(AstFile *f, DeclKind kind, AstNode *name_list, isize name_count, AstNode *type, AstNode *value_list, isize value_count) {
	AstNode *result = make_node(f, AstNode_VarDecl);
	result->VarDecl.kind = kind;
	result->VarDecl.name_list = name_list;
	result->VarDecl.name_count = name_count;
	result->VarDecl.type = type;
	result->VarDecl.value_list = value_list;
	result->VarDecl.value_count = value_count;
	return result;
}

gb_inline AstNode *make_field(AstFile *f, AstNode *name_list, isize name_count, AstNode *type) {
	AstNode *result = make_node(f, AstNode_Field);
	result->Field.name_list = name_list;
	result->Field.name_count = name_count;
	result->Field.type = type;
	return result;
}

gb_inline AstNode *make_proc_type(AstFile *f, Token token, AstNode *param_list, isize param_count, AstNode *result_list, isize result_count) {
	AstNode *result = make_node(f, AstNode_ProcType);
	result->ProcType.token = token;
	result->ProcType.param_list = param_list;
	result->ProcType.param_count = param_count;
	result->ProcType.result_list = result_list;
	result->ProcType.result_count = result_count;
	return result;
}

gb_inline AstNode *make_proc_decl(AstFile *f, AstNode *name, AstNode *proc_type, AstNode *body, u64 tags, String foreign_name) {
	AstNode *result = make_node(f, AstNode_ProcDecl);
	result->ProcDecl.name = name;
	result->ProcDecl.type = proc_type;
	result->ProcDecl.body = body;
	result->ProcDecl.tags = tags;
	result->ProcDecl.foreign_name = foreign_name;
	return result;
}

gb_inline AstNode *make_pointer_type(AstFile *f, Token token, AstNode *type) {
	AstNode *result = make_node(f, AstNode_PointerType);
	result->PointerType.token = token;
	result->PointerType.type = type;
	return result;
}

gb_inline AstNode *make_array_type(AstFile *f, Token token, AstNode *count, AstNode *elem) {
	AstNode *result = make_node(f, AstNode_ArrayType);
	result->ArrayType.token = token;
	result->ArrayType.count = count;
	result->ArrayType.elem = elem;
	return result;
}

gb_inline AstNode *make_vector_type(AstFile *f, Token token, AstNode *count, AstNode *elem) {
	AstNode *result = make_node(f, AstNode_VectorType);
	result->VectorType.token = token;
	result->VectorType.count = count;
	result->VectorType.elem  = elem;
	return result;
}

gb_inline AstNode *make_struct_type(AstFile *f, Token token, AstNode *field_list, isize field_count, b32 is_packed) {
	AstNode *result = make_node(f, AstNode_StructType);
	result->StructType.token = token;
	result->StructType.field_list = field_list;
	result->StructType.field_count = field_count;
	result->StructType.is_packed = is_packed;
	return result;
}

gb_inline AstNode *make_type_decl(AstFile *f, Token token, AstNode *name, AstNode *type) {
	AstNode *result = make_node(f, AstNode_TypeDecl);
	result->TypeDecl.token = token;
	result->TypeDecl.name = name;
	result->TypeDecl.type = type;
	return result;
}

gb_inline AstNode *make_alias_decl(AstFile *f, Token token, AstNode *name, AstNode *type) {
	AstNode *result = make_node(f, AstNode_AliasDecl);
	result->AliasDecl.token = token;
	result->AliasDecl.name = name;
	result->AliasDecl.type = type;
	return result;
}


gb_inline AstNode *make_import_decl(AstFile *f, Token token, Token filepath) {
	AstNode *result = make_node(f, AstNode_ImportDecl);
	result->ImportDecl.token = token;
	result->ImportDecl.filepath = filepath;
	return result;
}


gb_inline b32 next_token(AstFile *f) {
	if (f->cursor+1 < f->tokens + gb_array_count(f->tokens)) {
		f->cursor++;
		return true;
	} else {
		ast_file_err(f, f->cursor[0], "Token is EOF");
		return false;
	}
}

gb_inline Token expect_token(AstFile *f, TokenKind kind) {
	Token prev = f->cursor[0];
	if (prev.kind != kind) {
		ast_file_err(f, f->cursor[0], "Expected `%.*s`, got `%.*s`",
		             LIT(token_strings[kind]),
		             LIT(token_strings[prev.kind]));
	}
	next_token(f);
	return prev;
}

gb_inline Token expect_operator(AstFile *f) {
	Token prev = f->cursor[0];
	if (!gb_is_between(prev.kind, Token__OperatorBegin+1, Token__OperatorEnd-1)) {
		ast_file_err(f, f->cursor[0], "Expected an operator, got `%.*s`",
		             LIT(token_strings[prev.kind]));
	}
	next_token(f);
	return prev;
}

gb_inline Token expect_keyword(AstFile *f) {
	Token prev = f->cursor[0];
	if (!gb_is_between(prev.kind, Token__KeywordBegin+1, Token__KeywordEnd-1)) {
		ast_file_err(f, f->cursor[0], "Expected a keyword, got `%.*s`",
		             LIT(token_strings[prev.kind]));
	}
	next_token(f);
	return prev;
}

gb_inline b32 allow_token(AstFile *f, TokenKind kind) {
	Token prev = f->cursor[0];
	if (prev.kind == kind) {
		next_token(f);
		return true;
	}
	return false;
}


gb_internal void add_ast_entity(AstFile *f, AstScope *scope, AstNode *declaration, AstNode *name_list) {
	for (AstNode *n = name_list; n != NULL; n = n->next) {
		if (n->kind != AstNode_Ident) {
			ast_file_err(f, ast_node_token(declaration), "Identifier is already declared or resolved");
			continue;
		}

		AstEntity *entity = make_ast_entity(f, n->Ident.token, declaration, scope);
		n->Ident.entity = entity;

		AstEntity *insert_entity = ast_scope_insert(scope, *entity);
		if (insert_entity != NULL &&
		    !are_strings_equal(insert_entity->token.string, make_string("_"))) {
			ast_file_err(f, entity->token,
			             "There is already a previous declaration of `%.*s` in the current scope at\n"
			             "\t%.*s(%td:%td)",
			             LIT(insert_entity->token.string),
			             LIT(insert_entity->token.pos.file),
			             insert_entity->token.pos.line,
			             insert_entity->token.pos.column);
		}
	}
}



void fix_advance_to_next_stmt(AstFile *f) {
	// TODO(bill): fix_advance_to_next_stmt
#if 0
	for (;;) {
		Token t = f->cursor[0];
		switch (t.kind) {
		case Token_EOF:
			return;

		case Token_type:
		case Token_break:
		case Token_continue:
		case Token_fallthrough:
		case Token_if:
		case Token_for:
		case Token_defer:
		case Token_return:
			if (token_pos_are_equal(t.pos, f->fix_prev_pos) &&
			    f->fix_count < PARSER_MAX_FIX_COUNT) {
				f->fix_count++;
				return;
			}
			if (token_pos_cmp(f->fix_prev_pos, t.pos) < 0) {
				f->fix_prev_pos = t.pos;
				f->fix_count = 0; // NOTE(bill): Reset
				return;
			}

		}
		next_token(f);
	}
#endif
}



AstNode *parse_expr(AstFile *f, b32 lhs);
AstNode *parse_proc_type(AstFile *f, AstScope **scope_);
AstNode *parse_stmt_list(AstFile *f, isize *list_count_);
AstNode *parse_stmt(AstFile *f);
AstNode *parse_body(AstFile *f, AstScope *scope);

AstNode *parse_identifier(AstFile *f) {
	Token token = f->cursor[0];
	if (token.kind == Token_Identifier) {
		next_token(f);
	} else {
		token.string = make_string("_");
		expect_token(f, Token_Identifier);
	}
	return make_identifier(f, token);
}

AstNode *parse_tag_expr(AstFile *f, AstNode *expression) {
	Token token = expect_token(f, Token_Hash);
	Token name  = expect_token(f, Token_Identifier);
	return make_tag_expr(f, token, name, expression);
}

AstNode *parse_tag_stmt(AstFile *f, AstNode *statement) {
	Token token = expect_token(f, Token_Hash);
	Token name  = expect_token(f, Token_Identifier);
	return make_tag_stmt(f, token, name, statement);
}

AstNode *unparen_expr(AstNode *node) {
	for (;;) {
		if (node->kind != AstNode_ParenExpr)
			return node;
		node = node->ParenExpr.expr;
	}
}

AstNode *parse_value(AstFile *f);

AstNode *parse_element_list(AstFile *f, isize *element_count_) {
	AstNode *root = NULL;
	AstNode *curr = NULL;
	isize element_count = 0;

	while (f->cursor[0].kind != Token_CloseBrace &&
	       f->cursor[0].kind != Token_EOF) {
		AstNode *elem = parse_value(f);
	#if 0
		// TODO(bill): Designated Initializers
		if (f->cursor[0].kind == Token_Eq) {
			Token eq = expect_token(f, Token_Eq);
		}
	#endif
		DLIST_APPEND(root, curr, elem);
		element_count++;
		if (f->cursor[0].kind != Token_Comma)
			break;
		next_token(f);
	}

	if (element_count_) *element_count_ = element_count;
	return root;
}

AstNode *parse_literal_value(AstFile *f, AstNode *type) {
	AstNode *element_list = NULL;
	isize element_count = 0;
	Token open = expect_token(f, Token_OpenBrace);
	f->expr_level++;
	if (f->cursor[0].kind != Token_CloseBrace)
		element_list = parse_element_list(f, &element_count);
	f->expr_level--;
	Token close = expect_token(f, Token_CloseBrace);

	return make_compound_literal(f, type, element_list, element_count, open, close);
}

AstNode *parse_value(AstFile *f) {
	if (f->cursor[0].kind == Token_OpenBrace)
		return parse_literal_value(f, NULL);

	AstNode *value = parse_expr(f, false);
	return value;
}

AstNode *parse_identifier_or_type(AstFile *f);

AstNode *parse_operand(AstFile *f, b32 lhs) {
	AstNode *operand = NULL; // Operand
	switch (f->cursor[0].kind) {
	case Token_Identifier:
		operand = parse_identifier(f);
		if (!lhs) {
			// TODO(bill): Handle?
		}
		return operand;

	case Token_Integer:
	case Token_Float:
	case Token_String:
	case Token_Rune:
		operand = make_basic_lit(f, f->cursor[0]);
		next_token(f);
		return operand;

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
		operand = parse_tag_expr(f, NULL);
		operand->TagExpr.expr = parse_expr(f, false);
		return operand;
	}

	// Parse Procedure Type or Literal
	case Token_proc: {
		AstScope *scope = NULL;
		AstNode *type = parse_proc_type(f, &scope);

		if (f->cursor[0].kind != Token_OpenBrace) {
			return type;
		} else {
			AstNode *body;
			AstScope *curr_scope = f->curr_scope;

			f->curr_scope = scope;
			f->expr_level++;
			body = parse_body(f, scope);
			f->expr_level--;
			f->curr_scope = curr_scope;

			return make_procedure_literal(f, type, body);
		}
	}

	default: {
		AstNode *type = parse_identifier_or_type(f);
		if (type != NULL) {
			// NOTE(bill): Sanity check as identifiers should be handled already
			GB_ASSERT_MSG(type->kind != AstNode_Ident, "Type Cannot be identifier");
			return type;
		}
	}
	}

	Token begin = f->cursor[0];
	ast_file_err(f, begin, "Expected an operand");
	fix_advance_to_next_stmt(f);
	return make_bad_expr(f, begin, f->cursor[0]);
}

b32 is_literal_type(AstNode *node) {
	switch (node->kind) {
	case AstNode_BadExpr:
	case AstNode_Ident:
	case AstNode_ArrayType:
	case AstNode_VectorType:
	case AstNode_StructType:
		return true;
	}
	return false;
}

AstNode *parse_atom_expr(AstFile *f, b32 lhs) {
	AstNode *operand = parse_operand(f, lhs);

	b32 loop = true;
	while (loop) {
		switch (f->cursor[0].kind) {
		case Token_OpenParen: {
			if (lhs) {
				// TODO(bill): Handle this shit! Is this even allowed in this language?!
			}
			AstNode *arg_list = NULL;
			AstNode *arg_list_curr = NULL;
			isize arg_list_count = 0;
			Token open_paren, close_paren;

			f->expr_level++;
			open_paren = expect_token(f, Token_OpenParen);

			while (f->cursor[0].kind != Token_CloseParen &&
			       f->cursor[0].kind != Token_EOF) {
				if (f->cursor[0].kind == Token_Comma)
					ast_file_err(f, f->cursor[0], "Expected an expression not a ,");

				DLIST_APPEND(arg_list, arg_list_curr, parse_expr(f, false));
				arg_list_count++;

				if (f->cursor[0].kind != Token_Comma) {
					if (f->cursor[0].kind == Token_CloseParen)
						break;
				}

				next_token(f);
			}

			f->expr_level--;
			close_paren = expect_token(f, Token_CloseParen);

			operand = make_call_expr(f, operand, arg_list, arg_list_count, open_paren, close_paren);
		} break;

		case Token_Period: {
			Token token = f->cursor[0];
			next_token(f);
			if (lhs) {
				// TODO(bill): handle this
			}
			switch (f->cursor[0].kind) {
			case Token_Identifier:
				operand = make_selector_expr(f, token, operand, parse_identifier(f));
				break;
			default: {
				ast_file_err(f, f->cursor[0], "Expected a selector");
				next_token(f);
				operand = make_selector_expr(f, f->cursor[0], operand, NULL);
			} break;
			}
		} break;

		case Token_OpenBracket: {
			if (lhs) {
				// TODO(bill): Handle this
			}
			Token open, close;
			AstNode *indices[3] = {};

			f->expr_level++;
			open = expect_token(f, Token_OpenBracket);

			if (f->cursor[0].kind != Token_Colon)
				indices[0] = parse_expr(f, false);
			isize colon_count = 0;
			Token colons[2] = {};

			while (f->cursor[0].kind == Token_Colon && colon_count < 2) {
				colons[colon_count++] = f->cursor[0];
				next_token(f);
				if (f->cursor[0].kind != Token_Colon &&
				    f->cursor[0].kind != Token_CloseBracket &&
				    f->cursor[0].kind != Token_EOF) {
					indices[colon_count] = parse_expr(f, false);
				}
			}

			f->expr_level--;
			close = expect_token(f, Token_CloseBracket);

			if (colon_count == 0) {
				operand = make_index_expr(f, operand, indices[0], open, close);
			} else {
				b32 triple_indexed = false;
				if (colon_count == 2) {
					triple_indexed = true;
					if (indices[1] == NULL) {
						ast_file_err(f, colons[0], "Second index is required in a triple indexed slice");
						indices[1] = make_bad_expr(f, colons[0], colons[1]);
					}
					if (indices[2] == NULL) {
						ast_file_err(f, colons[1], "Third index is required in a triple indexed slice");
						indices[2] = make_bad_expr(f, colons[1], close);
					}
				}
				operand = make_slice_expr(f, operand, open, close, indices[0], indices[1], indices[2], triple_indexed);
			}
		} break;

		case Token_Pointer: // Deference
			operand = make_deref_expr(f, operand, expect_token(f, Token_Pointer));
			break;

		case Token_OpenBrace: {
			if (is_literal_type(operand) && f->expr_level >= 0) {
				if (lhs) {
					// TODO(bill): Handle this
				}
				operand = parse_literal_value(f, operand);
			} else {
				loop = false;
			}
		} break;

		default:
			loop = false;
			break;
		}

		lhs = false; // NOTE(bill): 'tis not lhs anymore
	}

	return operand;
}

AstNode *parse_type(AstFile *f);

AstNode *parse_unary_expr(AstFile *f, b32 lhs) {
	switch (f->cursor[0].kind) {
	case Token_Pointer:
	case Token_Add:
	case Token_Sub:
	case Token_Not:
	case Token_Xor: {
		AstNode *operand;
		Token op = f->cursor[0];
		next_token(f);
		operand = parse_unary_expr(f, false);
		return make_unary_expr(f, op, operand);
	} break;
	}

	return parse_atom_expr(f, lhs);
}

AstNode *parse_binary_expr(AstFile *f, b32 lhs, i32 prec_in) {
	AstNode *expression = parse_unary_expr(f, lhs);
	for (i32 prec = token_precedence(f->cursor[0]); prec >= prec_in; prec--) {
		for (;;) {
			AstNode *right;
			Token op = f->cursor[0];
			i32 op_prec = token_precedence(op);
			if (op_prec != prec)
				break;
			expect_operator(f); // NOTE(bill): error checks too
			if (lhs) {
				// TODO(bill): error checking
				lhs = false;
			}

			if (op.kind == Token_as || op.kind == Token_transmute) {
				right = parse_type(f);
			} else {
				right = parse_binary_expr(f, false, prec+1);
				if (!right) {
					ast_file_err(f, op, "Expected expression on the right hand side of the binary operator");
				}
			}
			expression = make_binary_expr(f, op, expression, right);

		}
	}
	return expression;
}

AstNode *parse_expr(AstFile *f, b32 lhs) {
	return parse_binary_expr(f, lhs, 0+1);
}


AstNode *parse_expr_list(AstFile *f, b32 lhs, isize *list_count_) {
	AstNode *list_root = NULL;
	AstNode *list_curr = NULL;
	isize list_count = 0;

	do {
		AstNode *e = parse_expr(f, lhs);
		DLIST_APPEND(list_root, list_curr, e);
		list_count++;
		if (f->cursor[0].kind != Token_Comma ||
		    f->cursor[0].kind == Token_EOF)
		    break;
		next_token(f);
	} while (true);

	if (list_count_) *list_count_ = list_count;

	return list_root;
}

AstNode *parse_lhs_expr_list(AstFile *f, isize *list_count) {
	return parse_expr_list(f, true, list_count);
}

AstNode *parse_rhs_expr_list(AstFile *f, isize *list_count) {
	return parse_expr_list(f, false, list_count);
}

AstNode *parse_decl(AstFile *f, AstNode *name_list, isize name_count);

AstNode *parse_simple_stmt(AstFile *f) {
	isize lhs_count = 0, rhs_count = 0;
	AstNode *lhs_expr_list = parse_lhs_expr_list(f, &lhs_count);


	AstNode *statement = NULL;
	Token token = f->cursor[0];
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
		if (f->curr_scope == f->file_scope) {
			ast_file_err(f, f->cursor[0], "You cannot use a simple statement in the file scope");
			return make_bad_stmt(f, f->cursor[0], f->cursor[0]);
		}
		next_token(f);
		AstNode *rhs_expr_list = parse_rhs_expr_list(f, &rhs_count);
		if (rhs_expr_list == NULL) {
			ast_file_err(f, token, "No right-hand side in assignment statement.");
			return make_bad_stmt(f, token, f->cursor[0]);
		}
		return make_assign_stmt(f, token,
		                             lhs_expr_list, lhs_count,
		                             rhs_expr_list, rhs_count);
	} break;

	case Token_Colon: // Declare
		return parse_decl(f, lhs_expr_list, lhs_count);
	}

	if (lhs_count > 1) {
		ast_file_err(f, token, "Expected 1 expression");
		return make_bad_stmt(f, token, f->cursor[0]);
	}

	token = f->cursor[0];
	switch (token.kind) {
	case Token_Increment:
	case Token_Decrement:
		if (f->curr_scope == f->file_scope) {
			ast_file_err(f, f->cursor[0], "You cannot use a simple statement in the file scope");
			return make_bad_stmt(f, f->cursor[0], f->cursor[0]);
		}
		statement = make_inc_dec_stmt(f, token, lhs_expr_list);
		next_token(f);
		return statement;
	}

	return make_expr_stmt(f, lhs_expr_list);
}



AstNode *parse_block_stmt(AstFile *f) {
	if (f->curr_scope == f->file_scope) {
		ast_file_err(f, f->cursor[0], "You cannot use a block statement in the file scope");
		return make_bad_stmt(f, f->cursor[0], f->cursor[0]);
	}
	AstNode *block_stmt;

	open_ast_scope(f);
	block_stmt = parse_body(f, f->curr_scope);
	close_ast_scope(f);
	return block_stmt;
}

AstNode *convert_stmt_to_expr(AstFile *f, AstNode *statement, String kind) {
	if (statement == NULL)
		return NULL;

	if (statement->kind == AstNode_ExprStmt)
		return statement->ExprStmt.expr;

	ast_file_err(f, f->cursor[0], "Expected `%.*s`, found a simple statement.", LIT(kind));
	return make_bad_expr(f, f->cursor[0], f->cursor[1]);
}

AstNode *parse_identfier_list(AstFile *f, isize *list_count_) {
	AstNode *list_root = NULL;
	AstNode *list_curr = NULL;
	isize list_count = 0;

	do {
		DLIST_APPEND(list_root, list_curr, parse_identifier(f));
		list_count++;
		if (f->cursor[0].kind != Token_Comma ||
		    f->cursor[0].kind == Token_EOF)
		    break;
		next_token(f);
	} while (true);

	if (list_count_) *list_count_ = list_count;

	return list_root;
}



AstNode *parse_type_attempt(AstFile *f) {
	AstNode *type = parse_identifier_or_type(f);
	if (type != NULL) {
		// TODO(bill): Handle?
	}
	return type;
}

AstNode *parse_type(AstFile *f) {
	AstNode *type = parse_type_attempt(f);
	if (type == NULL) {
		Token token = f->cursor[0];
		ast_file_err(f, token, "Expected a type");
		next_token(f);
		return make_bad_expr(f, token, f->cursor[0]);
	}
	return type;
}

AstNode *parse_field_decl(AstFile *f, AstScope *scope) {
	AstNode *name_list = NULL;
	isize name_count = 0;
	name_list = parse_lhs_expr_list(f, &name_count);
	if (name_count == 0)
		ast_file_err(f, f->cursor[0], "Empty field declaration");

	expect_token(f, Token_Colon);

	AstNode *type = parse_type_attempt(f);
	if (type == NULL)
		ast_file_err(f, f->cursor[0], "Expected a type for this field declaration");

	AstNode *field = make_field(f, name_list, name_count, type);
	add_ast_entity(f, scope, field, name_list);
	return field;
}

Token parse_procedure_signature(AstFile *f, AstScope *scope,
                                AstNode **param_list, isize *param_count,
                                AstNode **result_list, isize *result_count);

AstNode *parse_proc_type(AstFile *f, AstScope **scope_) {
	AstScope *scope = make_ast_scope(f, f->file_scope); // Procedure's scope
	AstNode *params = NULL;
	AstNode *results = NULL;
	isize param_count = 0;
	isize result_count = 0;

	Token proc_token = parse_procedure_signature(f, scope, &params, &param_count, &results, &result_count);

	if (scope_) *scope_ = scope;
	return make_proc_type(f, proc_token, params, param_count, results, result_count);
}


AstNode *parse_parameter_list(AstFile *f, AstScope *scope, isize *param_count_) {
	AstNode *param_list = NULL;
	AstNode *param_list_curr = NULL;
	isize param_count = 0;
	while (f->cursor[0].kind == Token_Identifier) {
		AstNode *field = parse_field_decl(f, scope);
		DLIST_APPEND(param_list, param_list_curr, field);
		param_count += field->Field.name_count;
		if (f->cursor[0].kind != Token_Comma)
			break;
		next_token(f);
	}

	if (param_count_) *param_count_ = param_count;
	return param_list;
}

AstNode *parse_identifier_or_type(AstFile *f) {
	switch (f->cursor[0].kind) {
	case Token_Identifier:
		return parse_identifier(f);

	case Token_Pointer:
		return make_pointer_type(f, expect_token(f, Token_Pointer), parse_type(f));

	case Token_OpenBracket: {
		f->expr_level++;
		Token token = expect_token(f, Token_OpenBracket);
		AstNode *count_expr = NULL;

		if (f->cursor[0].kind == Token_Ellipsis) {
			count_expr = make_ellipsis(f, f->cursor[0]);
			next_token(f);
		} else if (f->cursor[0].kind != Token_CloseBracket) {
			count_expr = parse_expr(f, false);
		}
		expect_token(f, Token_CloseBracket);
		f->expr_level--;
		return make_array_type(f, token, count_expr, parse_type(f));
	}

	case Token_OpenBrace: {
		f->expr_level++;
		Token token = expect_token(f, Token_OpenBrace);
		AstNode *count_expr = parse_expr(f, false);
		expect_token(f, Token_CloseBrace);
		f->expr_level--;
		return make_vector_type(f, token, count_expr, parse_type(f));
	}

	case Token_struct: {
		Token token = expect_token(f, Token_struct);
		Token open, close;
		AstNode *params = NULL;
		isize param_count = 0;
		AstScope *scope = make_ast_scope(f, NULL); // NOTE(bill): The struct needs its own scope with NO parent
		b32 is_packed = false;
		if (allow_token(f, Token_Hash)) {
			Token tag = expect_token(f, Token_Identifier);
			if (are_strings_equal(tag.string, make_string("packed"))) {
				is_packed = true;
			} else {
				ast_file_err(f, tag, "Expected a `#packed` tag");
			}
		}

		open   = expect_token(f, Token_OpenBrace);
		params = parse_parameter_list(f, scope, &param_count);
		close  = expect_token(f, Token_CloseBrace);

		return make_struct_type(f, token, params, param_count, is_packed);
	}

	case Token_proc:
		return parse_proc_type(f, NULL);


	case Token_OpenParen: {
		// NOTE(bill): Skip the paren expression
		AstNode *type;
		Token open, close;
		open = expect_token(f, Token_OpenParen);
		type = parse_type(f);
		close = expect_token(f, Token_CloseParen);
		return make_paren_expr(f, type, open, close);
	}

	// TODO(bill): Why is this even allowed? Is this a parsing error?
	case Token_Colon:
		break;

	case Token_Eq:
		if (f->cursor[-1].kind == Token_Colon)
			break;
		// fallthrough
	default:
		ast_file_err(f, f->cursor[0],
		             "Expected a type after `%.*s`, got `%.*s`", LIT(f->cursor[-1].string), LIT(f->cursor[0].string));
		break;
	}

	return NULL;
}


AstNode *parse_results(AstFile *f, AstScope *scope, isize *result_count) {
	if (allow_token(f, Token_ArrowRight)) {
		if (f->cursor[0].kind == Token_OpenParen) {
			expect_token(f, Token_OpenParen);
			AstNode *list = NULL;
			AstNode *list_curr = NULL;
			isize count = 0;
			while (f->cursor[0].kind != Token_CloseParen &&
			       f->cursor[0].kind != Token_EOF) {
				DLIST_APPEND(list, list_curr, parse_type(f));
				count++;
				if (f->cursor[0].kind != Token_Comma)
					break;
				next_token(f);
			}
			expect_token(f, Token_CloseParen);

			if (result_count) *result_count = count;
			return list;
		}

		AstNode *result = parse_type(f);
		if (result_count) *result_count = 1;
		return result;
	}
	if (result_count) *result_count = 0;
	return NULL;
}

Token parse_procedure_signature(AstFile *f, AstScope *scope,
                               AstNode **param_list, isize *param_count,
                               AstNode **result_list, isize *result_count) {
	Token proc_token = expect_token(f, Token_proc);
	expect_token(f, Token_OpenParen);
	*param_list = parse_parameter_list(f, scope, param_count);
	expect_token(f, Token_CloseParen);
	*result_list = parse_results(f, scope, result_count);
	return proc_token;
}

AstNode *parse_body(AstFile *f, AstScope *scope) {
	AstNode *statement_list = NULL;
	isize statement_list_count = 0;
	Token open, close;
	open = expect_token(f, Token_OpenBrace);
	statement_list = parse_stmt_list(f, &statement_list_count);
	close = expect_token(f, Token_CloseBrace);

	return make_block_stmt(f, statement_list, statement_list_count, open, close);
}

AstNode *parse_proc_decl(AstFile *f, Token proc_token, AstNode *name) {
	AstNode *param_list = NULL;
	AstNode *result_list = NULL;
	isize param_count = 0;
	isize result_count = 0;

	AstScope *scope = open_ast_scope(f);

	parse_procedure_signature(f, scope, &param_list, &param_count, &result_list, &result_count);

	AstNode *body = NULL;
	u64 tags = 0;
	String foreign_name = {};
	while (f->cursor[0].kind == Token_Hash) {
		AstNode *tag_expr = parse_tag_expr(f, NULL);
		ast_node(te, TagExpr, tag_expr);
		String tag_name = te->name.string;
		if (are_strings_equal(tag_name, make_string("foreign"))) {
			tags |= ProcTag_foreign;
			if (f->cursor[0].kind == Token_String) {
				foreign_name = f->cursor[0].string;
				// TODO(bill): Check if valid string
				if (foreign_name.len == 0) {
					ast_file_err(f, ast_node_token(tag_expr), "Invalid alternative foreign procedure name");
				}

				next_token(f);
			}
		} else if (are_strings_equal(tag_name, make_string("inline"))) {
			tags |= ProcTag_inline;
		} else if (are_strings_equal(tag_name, make_string("no_inline"))) {
			tags |= ProcTag_no_inline;
		} else {
			ast_file_err(f, ast_node_token(tag_expr), "Unknown procedure tag");
		}
	}

	b32 is_inline    = (tags & ProcTag_inline) != 0;
	b32 is_no_inline = (tags & ProcTag_no_inline) != 0;

	if (is_inline && is_no_inline) {
		ast_file_err(f, f->cursor[0], "You cannot apply both `inline` and `no_inline` to a procedure");
	}

	if (f->cursor[0].kind == Token_OpenBrace) {
		if ((tags & ProcTag_foreign) != 0) {
			ast_file_err(f, f->cursor[0], "A procedure tagged as `#foreign` cannot have a body");
		}
		body = parse_body(f, scope);
	}

	close_ast_scope(f);

	AstNode *proc_type = make_proc_type(f, proc_token, param_list, param_count, result_list, result_count);
	return make_proc_decl(f, name, proc_type, body, tags, foreign_name);
}

AstNode *parse_decl(AstFile *f, AstNode *name_list, isize name_count) {
	AstNode *value_list = NULL;
	AstNode *type = NULL;
	isize value_count = 0;
	if (allow_token(f, Token_Colon)) {
		type = parse_identifier_or_type(f);
	} else if (f->cursor[0].kind != Token_Eq && f->cursor[0].kind != Token_Semicolon) {
		ast_file_err(f, f->cursor[0], "Expected type separator `:` or `=`");
	}

	DeclKind declaration_kind = Declaration_Mutable;

	if (f->cursor[0].kind == Token_Eq ||
	    f->cursor[0].kind == Token_Colon) {
		if (f->cursor[0].kind == Token_Colon)
			declaration_kind = Declaration_Immutable;
		next_token(f);

		if (f->cursor[0].kind == Token_proc &&
		    declaration_kind == Declaration_Immutable) {
		    // NOTE(bill): Procedure declarations
			Token proc_token = f->cursor[0];
			AstNode *name = name_list;
			if (name_count != 1) {
				ast_file_err(f, proc_token, "You can only declare one procedure at a time (at the moment)");
				return make_bad_decl(f, name->Ident.token, proc_token);
			}

			AstNode *proc_decl = parse_proc_decl(f, proc_token, name);
			add_ast_entity(f, f->curr_scope, proc_decl, name_list);
			return proc_decl;

		} else {
			value_list = parse_rhs_expr_list(f, &value_count);
			if (value_count > name_count) {
				ast_file_err(f, f->cursor[0], "Too many values on the right hand side of the declaration");
			} else if (value_count < name_count &&
			           declaration_kind == Declaration_Immutable) {
				ast_file_err(f, f->cursor[0], "All constant declarations must be defined");
			} else if (value_list == NULL) {
				ast_file_err(f, f->cursor[0], "Expected an expression for this declaration");
			}
		}
	}

	if (declaration_kind == Declaration_Mutable) {
		if (type == NULL && value_list == NULL) {
			ast_file_err(f, f->cursor[0], "Missing variable type or initialization");
			return make_bad_decl(f, f->cursor[0], f->cursor[0]);
		}
	} else if (declaration_kind == Declaration_Immutable) {
		if (type == NULL && value_list == NULL && name_count > 0) {
			ast_file_err(f, f->cursor[0], "Missing constant value");
			return make_bad_decl(f, f->cursor[0], f->cursor[0]);
		}
	} else {
		Token begin = f->cursor[0];
		ast_file_err(f, begin, "Unknown type of variable declaration");
		fix_advance_to_next_stmt(f);
		return make_bad_decl(f, begin, f->cursor[0]);
	}

	AstNode *var_decl = make_var_decl(f, declaration_kind, name_list, name_count, type, value_list, value_count);
	add_ast_entity(f, f->curr_scope, var_decl, name_list);
	return var_decl;
}


AstNode *parse_if_stmt(AstFile *f) {
	if (f->curr_scope == f->file_scope) {
		ast_file_err(f, f->cursor[0], "You cannot use an if statement in the file scope");
		return make_bad_stmt(f, f->cursor[0], f->cursor[0]);
	}

	Token token = expect_token(f, Token_if);
	AstNode *init = NULL;
	AstNode *cond = NULL;
	AstNode *body = NULL;
	AstNode *else_stmt = NULL;

	open_ast_scope(f);
	defer (close_ast_scope(f));

	isize prev_level = f->expr_level;
	f->expr_level = -1;


	if (allow_token(f, Token_Semicolon)) {
		cond = parse_expr(f, false);
	} else {
		init = parse_simple_stmt(f);
		if (allow_token(f, Token_Semicolon)) {
			cond = parse_expr(f, false);
		} else {
			cond = convert_stmt_to_expr(f, init, make_string("boolean expression"));
			init = NULL;
		}
	}

	f->expr_level = prev_level;

	if (cond == NULL) {
		ast_file_err(f, f->cursor[0], "Expected condition for if statement");
	}

	body = parse_block_stmt(f);
	if (allow_token(f, Token_else)) {
		switch (f->cursor[0].kind) {
		case Token_if:
			else_stmt = parse_if_stmt(f);
			break;
		case Token_OpenBrace:
			else_stmt = parse_block_stmt(f);
			break;
		default:
			ast_file_err(f, f->cursor[0], "Expected if statement block statement");
			else_stmt = make_bad_stmt(f, f->cursor[0], f->cursor[1]);
			break;
		}
	}

	return make_if_stmt(f, token, init, cond, body, else_stmt);
}

AstNode *parse_return_stmt(AstFile *f) {
	if (f->curr_scope == f->file_scope) {
		ast_file_err(f, f->cursor[0], "You cannot use a return statement in the file scope");
		return make_bad_stmt(f, f->cursor[0], f->cursor[0]);
	}

	Token token = expect_token(f, Token_return);
	AstNode *result = NULL;
	isize result_count = 0;
	if (f->cursor[0].kind != Token_Semicolon)
		result = parse_rhs_expr_list(f, &result_count);
	if (f->cursor[0].kind != Token_CloseBrace)
		expect_token(f, Token_Semicolon);

	return make_return_stmt(f, token, result, result_count);
}

AstNode *parse_for_stmt(AstFile *f) {
	if (f->curr_scope == f->file_scope) {
		ast_file_err(f, f->cursor[0], "You cannot use a for statement in the file scope");
		return make_bad_stmt(f, f->cursor[0], f->cursor[0]);
	}

	Token token = expect_token(f, Token_for);
	open_ast_scope(f);
	defer (close_ast_scope(f));

	AstNode *init = NULL;
	AstNode *cond = NULL;
	AstNode *end  = NULL;
	AstNode *body = NULL;

	if (f->cursor[0].kind != Token_OpenBrace) {
		isize prev_level = f->expr_level;
		f->expr_level = -1;
		if (f->cursor[0].kind != Token_Semicolon) {
			cond = parse_simple_stmt(f);
			if (is_ast_node_complex_stmt(cond)) {
				ast_file_err(f, f->cursor[0],
				             "You are not allowed that type of statement in a for statement, it is too complex!");
			}
		}

		if (allow_token(f, Token_Semicolon)) {
			init = cond;
			cond = NULL;
			if (f->cursor[0].kind != Token_Semicolon) {
				cond = parse_simple_stmt(f);
			}
			expect_token(f, Token_Semicolon);
			if (f->cursor[0].kind != Token_OpenBrace) {
				end = parse_simple_stmt(f);
			}
		}
		f->expr_level = prev_level;
	}
	body = parse_block_stmt(f);

	cond = convert_stmt_to_expr(f, cond, make_string("boolean expression"));

	return make_for_stmt(f, token, init, cond, end, body);
}

AstNode *parse_defer_stmt(AstFile *f) {
	if (f->curr_scope == f->file_scope) {
		ast_file_err(f, f->cursor[0], "You cannot use a defer statement in the file scope");
		return make_bad_stmt(f, f->cursor[0], f->cursor[0]);
	}

	Token token = expect_token(f, Token_defer);
	AstNode *statement = parse_stmt(f);
	switch (statement->kind) {
	case AstNode_EmptyStmt:
		ast_file_err(f, token, "Empty statement after defer (e.g. `;`)");
		break;
	case AstNode_DeferStmt:
		ast_file_err(f, token, "You cannot defer a defer statement");
		break;
	case AstNode_ReturnStmt:
		ast_file_err(f, token, "You cannot a return statement");
		break;
	}

	return make_defer_stmt(f, token, statement);
}

AstNode *parse_stmt(AstFile *f) {
	AstNode *s = NULL;
	Token token = f->cursor[0];
	switch (token.kind) {
	case Token_type: {
		Token   token = expect_token(f, Token_type);
		AstNode *name = parse_identifier(f);
		expect_token(f, Token_Colon);
		AstNode *type = parse_type(f);

		AstNode *type_decl = make_type_decl(f, token, name, type);

		if (type->kind != AstNode_StructType &&
		    type->kind != AstNode_ProcType) {
			expect_token(f, Token_Semicolon);
		}

		return type_decl;
	} break;

	case Token_alias: {
		Token   token = expect_token(f, Token_alias);
		AstNode *name = parse_identifier(f);
		expect_token(f, Token_Colon);
		AstNode *type = parse_type(f);

		AstNode *alias_decl = make_alias_decl(f, token, name, type);

		if (type->kind != AstNode_StructType &&
		    type->kind != AstNode_ProcType) {
			expect_token(f, Token_Semicolon);
		}

		return alias_decl;
	} break;

	case Token_import: {
		Token token = expect_token(f, Token_import);
		Token filepath = expect_token(f, Token_String);
		if (f->curr_scope == f->file_scope) {
			return make_import_decl(f, token, filepath);
		}
		ast_file_err(f, token, "You cannot `import` within a procedure. This must be done at the file scope.");
		return make_bad_decl(f, token, filepath);
	} break;

	// Operands
	case Token_Identifier:
	case Token_Integer:
	case Token_Float:
	case Token_Rune:
	case Token_String:
	case Token_OpenParen:
	// Unary Operators
	case Token_Add:
	case Token_Sub:
	case Token_Xor:
	case Token_Not:
		s = parse_simple_stmt(f);
		if (s->kind != AstNode_ProcDecl && !allow_token(f, Token_Semicolon)) {
			// CLEANUP(bill): Semicolon handling in parser
			ast_file_err(f, f->cursor[0],
			             "Expected `;` after statement, got `%.*s`",
			             LIT(token_strings[f->cursor[0].kind]));
		}
		return s;

	// TODO(bill): other keywords
	case Token_if:     return parse_if_stmt(f);
	case Token_return: return parse_return_stmt(f);
	case Token_for:    return parse_for_stmt(f);
	case Token_defer:  return parse_defer_stmt(f);
	// case Token_match: return NULL; // TODO(bill): Token_match
	// case Token_case: return NULL; // TODO(bill): Token_case

	case Token_break:
	case Token_continue:
	case Token_fallthrough:
		next_token(f);
		expect_token(f, Token_Semicolon);
		return make_branch_stmt(f, token);

	case Token_Hash:
		s = parse_tag_stmt(f, NULL);
		s->TagStmt.stmt = parse_stmt(f); // TODO(bill): Find out why this doesn't work as an argument
		return s;

	case Token_OpenBrace: return parse_block_stmt(f);

	case Token_Semicolon:
		s = make_empty_stmt(f, token);
		next_token(f);
		return s;
	}

	ast_file_err(f, token,
	             "Expected a statement, got `%.*s`",
	             LIT(token_strings[token.kind]));
	fix_advance_to_next_stmt(f);
	return make_bad_stmt(f, token, f->cursor[0]);
}

AstNode *parse_stmt_list(AstFile *f, isize *list_count_) {
	AstNode *list_root = NULL;
	AstNode *list_curr = NULL;
	isize list_count = 0;

	while (f->cursor[0].kind != Token_case &&
	       f->cursor[0].kind != Token_CloseBrace &&
	       f->cursor[0].kind != Token_EOF) {
		DLIST_APPEND(list_root, list_curr, parse_stmt(f));
		list_count++;
	}

	if (list_count_) *list_count_ = list_count;

	return list_root;
}



ParseFileError init_ast_file(AstFile *f, String fullpath) {
	if (!string_has_extension(fullpath, make_string("odin"))) {
		gb_printf_err("Only `.odin` files are allowed\n");
		return ParseFile_WrongExtension;
	}
	TokenizerInitError err = init_tokenizer(&f->tokenizer, fullpath);
	if (err == TokenizerInit_None) {
		gb_array_init(f->tokens, gb_heap_allocator());
		for (;;) {
			Token token = tokenizer_get_token(&f->tokenizer);
			if (token.kind == Token_Invalid)
				return ParseFile_InvalidToken;
			gb_array_append(f->tokens, token);

			if (token.kind == Token_EOF)
				break;
		}

		f->cursor = &f->tokens[0];

		// NOTE(bill): Is this big enough or too small?
		isize arena_size = gb_max(gb_size_of(AstNode), gb_size_of(AstScope));
		arena_size *= 2*gb_array_count(f->tokens);
		gb_arena_init_from_allocator(&f->arena, gb_heap_allocator(), arena_size);

		open_ast_scope(f);
		f->file_scope = f->curr_scope;

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
	close_ast_scope(f);
	gb_arena_free(&f->arena);
	gb_array_free(f->tokens);
	gb_free(gb_heap_allocator(), f->tokenizer.fullpath.text);
	destroy_tokenizer(&f->tokenizer);
}

b32 init_parser(Parser *p) {
	gb_array_init(p->files, gb_heap_allocator());
	gb_array_init(p->imports, gb_heap_allocator());
	return true;
}

void destroy_parser(Parser *p) {
	// TODO(bill): Fix memory leak
	gb_for_array(i, p->files) {
		destroy_ast_file(&p->files[i]);
	}
#if 1
	gb_for_array(i, p->imports) {
		// gb_free(gb_heap_allocator(), p->imports[i].text);
	}
#endif
	gb_array_free(p->files);
	gb_array_free(p->imports);
}

// NOTE(bill): Returns true if it's added
b32 try_add_import_path(Parser *p, String import_file) {
	gb_for_array(i, p->imports) {
		String import = p->imports[i];
		if (are_strings_equal(import, import_file)) {
			return false;
		}
	}

	gb_array_append(p->imports, import_file);
	return true;
}

gb_global Rune illegal_import_runes[] = {
	'"', '\'', '`', ' ',
	'\\', // NOTE(bill): Disallow windows style filepaths
	'!', '$', '%', '^', '&', '*', '(', ')', '=', '+',
	'[', ']', '{', '}',
	';', ':', '#',
	'|', ',',  '<', '>', '?',
};

b32 is_import_path_valid(String path) {
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


void parse_file(Parser *p, AstFile *f) {
	String filepath = f->tokenizer.fullpath;
	String base_dir = filepath;
	for (isize i = filepath.len-1; i >= 0; i--) {
		if (base_dir.text[i] == GB_PATH_SEPARATOR)
			break;
		base_dir.len--;
	}

	f->decls = parse_stmt_list(f, &f->decl_count);

	for (AstNode *node = f->decls; node != NULL; node = node->next) {
		if (!is_ast_node_decl(node) &&
		    node->kind != AstNode_BadStmt &&
		    node->kind != AstNode_EmptyStmt) {
			// NOTE(bill): Sanity check
			ast_file_err(f, ast_node_token(node), "Only declarations are allowed at file scope");
		} else {
			if (node->kind == AstNode_ImportDecl) {
				auto *id = &node->ImportDecl;
				String file_str = id->filepath.string;

				char ext[] = ".odin";
				isize ext_len = gb_size_of(ext)-1;
				b32 append_ext = false;

				if (!is_import_path_valid(file_str)) {
					ast_file_err(f, ast_node_token(node), "Invalid import path");
					continue;
				}

				if (string_extension_position(file_str) < 0)
					append_ext = true;

				isize str_len = base_dir.len+file_str.len;
				if (append_ext)
					str_len += ext_len;
				u8 *str = gb_alloc_array(gb_heap_allocator(), u8, str_len+1);
				defer (gb_free(gb_heap_allocator(), str));

				gb_memcopy(str, base_dir.text, base_dir.len);
				gb_memcopy(str+base_dir.len, file_str.text, file_str.len);
				if (append_ext)
					gb_memcopy(str+base_dir.len+file_str.len, ext, ext_len+1);
				str[str_len] = '\0';
				char *path_str = gb_path_get_full_name(gb_heap_allocator(), cast(char *)str);
				String import_file = make_string(path_str);

				if (!try_add_import_path(p, import_file)) {
					gb_free(gb_heap_allocator(), import_file.text);
				}
			}
		}
	}
}


ParseFileError parse_files(Parser *p, char *init_filename) {
	char *fullpath_str = gb_path_get_full_name(gb_heap_allocator(), init_filename);
	String init_fullpath = make_string(fullpath_str);
	gb_array_append(p->imports, init_fullpath);
	p->init_fullpath = init_fullpath;

	gb_for_array(i, p->imports) {
		String import_path = p->imports[i];
		AstFile file = {};
		ParseFileError err = init_ast_file(&file, import_path);
		if (err != ParseFile_None) {
			gb_printf_err("Failed to parse file: %.*s\n", LIT(import_path));
			switch (err) {
			case ParseFile_WrongExtension:
				gb_printf_err("\tInvalid file extension\n");
				break;
			case ParseFile_InvalidFile:
				gb_printf_err("\tInvalid file\n");
				break;
			case ParseFile_EmptyFile:
				gb_printf_err("\tFile is empty\n");
				break;
			case ParseFile_Permission:
				gb_printf_err("\tFile permissions problem\n");
				break;
			case ParseFile_NotFound:
				gb_printf_err("\tFile cannot be found\n");
				break;
			case ParseFile_InvalidToken:
				gb_printf_err("\tInvalid token found in file\n");
				break;
			}
			return err;
		}
		parse_file(p, &file);
		gb_array_append(p->files, file);
		p->total_token_count += gb_array_count(file.tokens);
	}


	return ParseFile_None;
}


