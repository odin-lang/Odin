struct AstNode;
struct Scope;
struct Type;
struct Entity;
struct DeclInfo;


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

struct CommentGroup {
	Array<Token> list; // Token_Comment
};


enum ImportedFileKind {
	ImportedFile_Normal,
	ImportedFile_Shared,
	ImportedFile_Init,
};

struct ImportedFile {
	ImportedFileKind kind;
	String           path;
	String           rel_path;
	TokenPos         pos; // import
	isize            index;
};


struct AstFile {
	isize               id;
	String              fullpath;
	gbArena             arena;
	Tokenizer           tokenizer;
	Array<Token>        tokens;
	isize               curr_token_index;
	Token               curr_token;
	Token               prev_token; // previous non-comment

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	isize               expr_level;
	bool                allow_range; // NOTE(bill): Ranges are only allowed in certain cases
	bool                in_foreign_block;
	bool                allow_type;
	isize               when_level;

	Array<AstNode *>    decls;
	ImportedFileKind    file_kind;
	bool                is_global_scope;
	Array<AstNode *>    imports_and_exports; // 'import' 'using import' 'export'


	AstNode *           curr_proc;
	isize               scope_level;
	Scope *             scope;       // NOTE(bill): Created in checker
	DeclInfo *          decl_info;   // NOTE(bill): Created in checker


	CommentGroup        lead_comment; // Comment (block) before the decl
	CommentGroup        line_comment; // Comment after the semicolon
	CommentGroup        docs;         // current docs
	Array<CommentGroup> comments;     // All the comments!


#define PARSER_MAX_FIX_COUNT 6
	isize    fix_count;
	TokenPos fix_prev_pos;
};


struct Parser {
	String              init_fullpath;
	Array<AstFile *>    files;
	Array<ImportedFile> imports;
	isize               total_token_count;
	isize               total_line_count;
	gbMutex             file_add_mutex;
	gbMutex             file_decl_mutex;
};

enum ProcInlining {
	ProcInlining_none = 0,
	ProcInlining_inline = 1,
	ProcInlining_no_inline = 2,
};

enum ProcTag {
	ProcTag_bounds_check    = 1<<0,
	ProcTag_no_bounds_check = 1<<1,
	ProcTag_require_results = 1<<4,
};

enum ProcCallingConvention {
	ProcCC_Invalid = 0,
	ProcCC_Odin,
	ProcCC_Contextless,
	ProcCC_CDecl,
	ProcCC_StdCall,
	ProcCC_FastCall,

	// TODO(bill): Add extra calling conventions
	// ProcCC_VectorCall,
	// ProcCC_ClrCall,

	ProcCC_ForeignBlockDefault = -1,
};

enum StmtStateFlag {
	StmtStateFlag_bounds_check    = 1<<0,
	StmtStateFlag_no_bounds_check = 1<<1,
};

enum FieldFlag {
	FieldFlag_NONE      = 0,
	FieldFlag_ellipsis  = 1<<0,
	FieldFlag_using     = 1<<1,
	FieldFlag_no_alias  = 1<<2,
	FieldFlag_c_vararg  = 1<<3,

	FieldFlag_in        = 1<<5,


	FieldFlag_Results   = 1<<16,

	// FieldFlag_Signature = FieldFlag_ellipsis|FieldFlag_using|FieldFlag_no_alias|FieldFlag_c_vararg|FieldFlag_in,
	FieldFlag_Signature = FieldFlag_ellipsis|FieldFlag_using|FieldFlag_no_alias|FieldFlag_c_vararg,
	FieldFlag_Struct    = FieldFlag_using,
};

enum StmtAllowFlag {
	StmtAllowFlag_None  = 0,
	StmtAllowFlag_In    = 1<<0,
	StmtAllowFlag_Label = 1<<1,
};



// NOTE(bill): This massive define is so it is possible to create a discriminated union (and extra debug info)
// for the AstNode. I personally prefer discriminated unions over subtype polymorphism as I can preallocate
// all the nodes and even memcpy in a different kind of node
#define AST_NODE_KINDS \
	AST_NODE_KIND(Ident,          "identifier",      struct { \
		Token   token;  \
		Entity *entity; \
	}) \
	AST_NODE_KIND(Implicit,       "implicit",        Token) \
	AST_NODE_KIND(Undef,          "undef",           Token) \
	AST_NODE_KIND(BasicLit,       "basic literal",   struct { \
		Token token; \
	}) \
	AST_NODE_KIND(BasicDirective, "basic directive", struct { \
		Token  token; \
		String name; \
	}) \
	AST_NODE_KIND(Ellipsis,       "ellipsis", struct { \
		Token    token; \
		AstNode *expr; \
	}) \
	AST_NODE_KIND(ProcGroup, "procedure group", struct { \
		Token            token; \
		Token            open;  \
		Token            close; \
		Array<AstNode *> args; \
	}) \
	AST_NODE_KIND(ProcLit, "procedure literal", struct { \
		AstNode *    type; \
		AstNode *    body; \
		u64          tags; \
		ProcInlining inlining; \
	}) \
	AST_NODE_KIND(CompoundLit, "compound literal", struct { \
		AstNode *type; \
		Array<AstNode *> elems; \
		Token open, close; \
	}) \
AST_NODE_KIND(_ExprBegin,  "",  struct {}) \
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
		Token interval; \
		AstNode *low, *high; \
	}) \
	AST_NODE_KIND(CallExpr,     "call expression", struct { \
		AstNode *    proc; \
		Array<AstNode *> args; \
		Token        open; \
		Token        close; \
		Token        ellipsis; \
	}) \
	AST_NODE_KIND(FieldValue,    "field value",         struct { Token eq; AstNode *field, *value; }) \
	AST_NODE_KIND(TernaryExpr,   "ternary expression",  struct { AstNode *cond, *x, *y; }) \
	AST_NODE_KIND(TypeAssertion, "type assertion",      struct { AstNode *expr; Token dot; AstNode *type; }) \
	AST_NODE_KIND(TypeCast,      "type cast",           struct { Token token; AstNode *type, *expr; }) \
	AST_NODE_KIND(AutoCast,      "auto_cast",           struct { Token token; AstNode *expr; }) \
AST_NODE_KIND(_ExprEnd,       "", struct {}) \
AST_NODE_KIND(_StmtBegin,     "", struct {}) \
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
		Array<AstNode *> lhs, rhs; \
	}) \
	AST_NODE_KIND(IncDecStmt, "increment decrement statement", struct { \
		Token op; \
		AstNode *expr; \
	}) \
AST_NODE_KIND(_ComplexStmtBegin, "", struct {}) \
	AST_NODE_KIND(BlockStmt, "block statement", struct { \
		Array<AstNode *> stmts; \
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
		bool is_cond_determined; \
		bool determined_cond; \
	}) \
	AST_NODE_KIND(ReturnStmt, "return statement", struct { \
		Token token; \
		Array<AstNode *> results; \
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
		AstNode *val0; \
		AstNode *val1; \
		Token    in_token; \
		AstNode *expr; \
		AstNode *body; \
	}) \
	AST_NODE_KIND(CaseClause, "case clause", struct { \
		Token token;             \
		Array<AstNode *> list;   \
		Array<AstNode *> stmts;  \
		Entity *implicit_entity; \
	}) \
	AST_NODE_KIND(SwitchStmt, "switch statement", struct { \
		Token    token;    \
		AstNode *label;    \
		AstNode *init;     \
		AstNode *tag;      \
		AstNode *body;     \
		bool     complete; \
	}) \
	AST_NODE_KIND(TypeSwitchStmt, "type switch statement", struct { \
		Token    token;    \
		AstNode *label;    \
		AstNode *tag;      \
		AstNode *body;     \
		bool     complete; \
	}) \
	AST_NODE_KIND(DeferStmt,  "defer statement",  struct { Token token; AstNode *stmt; }) \
	AST_NODE_KIND(BranchStmt, "branch statement", struct { Token token; AstNode *label; }) \
	AST_NODE_KIND(UsingStmt,  "using statement",  struct { \
		Token token;   \
		Array<AstNode *> list; \
	}) \
	AST_NODE_KIND(UsingInStmt, "using in statement",  struct { \
		Token using_token;     \
		Array<AstNode *> list; \
		Token in_token;        \
		AstNode *expr;         \
	}) \
	AST_NODE_KIND(PushContext, "context <- statement", struct { \
		Token token;   \
		AstNode *expr; \
		AstNode *body; \
	}) \
AST_NODE_KIND(_ComplexStmtEnd, "", struct {}) \
AST_NODE_KIND(_StmtEnd,        "", struct {}) \
AST_NODE_KIND(_DeclBegin,      "", struct {}) \
	AST_NODE_KIND(BadDecl,     "bad declaration",     struct { Token begin, end; }) \
	AST_NODE_KIND(ForeignBlockDecl, "foreign block declaration", struct { \
		Token            token;           \
		AstNode *        foreign_library; \
		Token            open, close;     \
		Array<AstNode *> decls;           \
		Array<AstNode *> attributes;      \
		CommentGroup     docs;            \
		bool             been_handled;    \
	}) \
	AST_NODE_KIND(Label, "label", struct { 	\
		Token token; \
		AstNode *name; \
	}) \
	AST_NODE_KIND(ValueDecl, "value declaration", struct { \
		Array<AstNode *> names;        \
		AstNode *        type;         \
		Array<AstNode *> values;       \
		Array<AstNode *> attributes;   \
		CommentGroup     docs;         \
		CommentGroup     comment;      \
		bool             is_using;     \
		bool             is_mutable;   \
		bool             been_handled; \
	}) \
	AST_NODE_KIND(ImportDecl, "import declaration", struct { \
		AstFile *file;          \
		Token    token;         \
		Token    relpath;       \
		String   fullpath;      \
		Token    import_name;   \
		Array<AstNode *> using_in_list; \
		CommentGroup docs;      \
		CommentGroup comment;   \
		bool     is_using;      \
		bool     been_handled;  \
	}) \
	AST_NODE_KIND(ExportDecl, "export declaration", struct { \
		AstFile *file;          \
		Token    token;         \
		Token    relpath;       \
		String   fullpath;      \
		Array<AstNode *> using_in_list; \
		CommentGroup docs;      \
		CommentGroup comment;   \
		bool     been_handled;  \
	}) \
	AST_NODE_KIND(ForeignImportDecl, "foreign import declaration", struct { \
		Token    token;           \
		Token    filepath;        \
		Token    library_name;    \
		String   base_dir;        \
		String   collection_name; \
		String   fullpath;        \
		CommentGroup docs;        \
		CommentGroup comment;     \
		bool     been_handled;    \
	}) \
AST_NODE_KIND(_DeclEnd,   "", struct {}) \
	AST_NODE_KIND(Attribute, "attribute", struct { \
		Token    token;         \
		AstNode *type;          \
		Array<AstNode *> elems; \
		Token open, close;      \
	}) \
	AST_NODE_KIND(Field, "field", struct { \
		Array<AstNode *> names;            \
		AstNode *        type;             \
		AstNode *        default_value;    \
		u32              flags;            \
		CommentGroup     docs;             \
		CommentGroup     comment;          \
	}) \
	AST_NODE_KIND(FieldList, "field list", struct { \
		Token token; \
		Array<AstNode *> list; \
	}) \
	AST_NODE_KIND(UnionField, "union field", struct { \
		AstNode *name; \
		AstNode *list; \
	}) \
AST_NODE_KIND(_TypeBegin, "", struct {}) \
	AST_NODE_KIND(TypeType, "type", struct { \
		Token token; \
		AstNode *specialization; \
	}) \
	AST_NODE_KIND(HelperType, "helper type", struct { \
		Token token; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(DistinctType, "distinct type", struct { \
		Token token; \
		AstNode *type; \
	}) \
	AST_NODE_KIND(PolyType, "polymorphic type", struct { \
		Token    token; \
		AstNode *type;  \
		AstNode *specialization;  \
	}) \
	AST_NODE_KIND(ProcType, "procedure type", struct { \
		Token    token;   \
		AstNode *params;  \
		AstNode *results; \
		u64      tags;    \
		ProcCallingConvention calling_convention; \
		bool     generic; \
	}) \
	AST_NODE_KIND(PointerType, "pointer type", struct { \
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
	AST_NODE_KIND(StructType, "struct type", struct { \
		Token            token;               \
		Array<AstNode *> fields;              \
		isize            field_count;         \
		AstNode *        polymorphic_params;  \
		AstNode *        align;               \
		bool             is_packed;           \
		bool             is_raw_union;        \
	}) \
	AST_NODE_KIND(UnionType, "union type", struct { \
		Token            token;    \
		Array<AstNode *> variants; \
		AstNode *        align;    \
	}) \
	AST_NODE_KIND(EnumType, "enum type", struct { \
		Token            token; \
		AstNode *        base_type; \
		Array<AstNode *> fields; /* FieldValue */ \
		bool             is_export; \
	}) \
	AST_NODE_KIND(BitFieldType, "bit field type", struct { \
		Token            token; \
		Array<AstNode *> fields; /* FieldValue with : */ \
		AstNode *        align; \
	}) \
	AST_NODE_KIND(MapType, "map type", struct { \
		Token    token; \
		AstNode *count; \
		AstNode *key; \
		AstNode *value; \
	}) \
AST_NODE_KIND(_TypeEnd,  "", struct {})

enum AstNodeKind {
	AstNode_Invalid,
#define AST_NODE_KIND(_kind_name_, ...) GB_JOIN2(AstNode_, _kind_name_),
	AST_NODE_KINDS
#undef AST_NODE_KIND
	AstNode_Count,
};

String const ast_node_strings[] = {
	{cast(u8 *)"invalid node", gb_size_of("invalid node")},
#define AST_NODE_KIND(_kind_name_, name, ...) {cast(u8 *)name, gb_size_of(name)-1},
	AST_NODE_KINDS
#undef AST_NODE_KIND
};

#define AST_NODE_KIND(_kind_name_, name, ...) typedef __VA_ARGS__ GB_JOIN2(AstNode, _kind_name_);
	AST_NODE_KINDS
#undef AST_NODE_KIND

struct AstNode {
	AstNodeKind kind;
	u32         stmt_state_flags;
	AstFile *   file;
	Scope *     scope;

	union {
#define AST_NODE_KIND(_kind_name_, name, ...) GB_JOIN2(AstNode, _kind_name_) _kind_name_;
	AST_NODE_KINDS
#undef AST_NODE_KIND
	};
};


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

