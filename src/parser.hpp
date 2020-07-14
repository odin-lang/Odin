struct Ast;
struct Scope;
struct Type;
struct Entity;
struct DeclInfo;
struct AstFile;
struct AstPackage;

enum AddressingMode {
	Addressing_Invalid,       // invalid addressing mode
	Addressing_NoValue,       // no value (void in C)
	Addressing_Value,         // computed value (rvalue)
	Addressing_Context,       // context value
	Addressing_Variable,      // addressable variable (lvalue)
	Addressing_Constant,      // constant
	Addressing_Type,          // type
	Addressing_Builtin,       // built-in procedure
	Addressing_ProcGroup,     // procedure group (overloaded procedure)
	Addressing_MapIndex,      // map index expression -
	                          // 	lhs: acts like a Variable
	                          // 	rhs: acts like OptionalOk
	Addressing_OptionalOk,    // rhs: acts like a value with an optional boolean part (for existence check)
	Addressing_SoaVariable,   // Struct-Of-Arrays indexed variable

	Addressing_AtomOpAssign,  // Specialized for custom atom operations for assignments
};

struct TypeAndValue {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
};


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


enum PackageKind {
	Package_Normal,
	Package_Runtime,
	Package_Init,
};

struct ImportedPackage {
	PackageKind kind;
	String      path;
	String      rel_path;
	TokenPos    pos; // import
	isize       index;
};


struct ImportedFile {
	AstPackage *pkg;
	FileInfo    fi;
	TokenPos    pos; // import
	isize       index;
};

struct AstFile {
	isize        id;
	AstPackage * pkg;
	Scope *      scope;

	Arena        arena;

	Ast *        pkg_decl;
	String       fullpath;
	Tokenizer    tokenizer;
	Array<Token> tokens;
	isize        curr_token_index;
	Token        curr_token;
	Token        prev_token; // previous non-comment
	Token        package_token;
	String       package_name;

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	isize        expr_level;
	bool         allow_range;   // NOTE(bill): Ranges are only allowed in certain cases
	bool         allow_in_expr; // NOTE(bill): in expression are only allowed in certain cases
	bool         in_foreign_block;
	bool         allow_type;

	Array<Ast *> decls;
	Array<Ast *> imports; // 'import' 'using import'
	isize        directive_count;

	Ast *        curr_proc;
	isize        error_count;
	f64          time_to_tokenize; // seconds
	f64          time_to_parse;    // seconds

	CommentGroup *lead_comment;     // Comment (block) before the decl
	CommentGroup *line_comment;     // Comment after the semicolon
	CommentGroup *docs;             // current docs
	Array<CommentGroup *> comments; // All the comments!


#define PARSER_MAX_FIX_COUNT 6
	isize    fix_count;
	TokenPos fix_prev_pos;

	struct LLVMOpaqueMetadata *llvm_metadata;
	struct LLVMOpaqueMetadata *llvm_metadata_scope;
};


struct AstPackage {
	PackageKind      kind;
	isize            id;
	String           name;
	String           fullpath;
	Array<AstFile *> files;

	// NOTE(bill): Created/set in checker
	Scope *   scope;
	DeclInfo *decl_info;
	bool      used;
};


struct Parser {
	String                  init_fullpath;
	StringSet               imported_files; // fullpath
	StringMap<AstPackage *> package_map; // Key(package name)
	Array<AstPackage *>     packages;
	Array<ImportedPackage>  package_imports;
	isize                   file_to_process_count;
	isize                   total_token_count;
	isize                   total_line_count;
	gbMutex                 file_add_mutex;
	gbMutex                 file_decl_mutex;
};


gb_global ThreadPool parser_thread_pool = {};

struct ParserWorkerData {
	Parser *parser;
	ImportedFile imported_file;
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
	ProcTag_optional_ok     = 1<<5,
};

enum ProcCallingConvention {
	ProcCC_Invalid = 0,
	ProcCC_Odin,
	ProcCC_Contextless,
	ProcCC_Pure,
	ProcCC_CDecl,
	ProcCC_StdCall,
	ProcCC_FastCall,

	ProcCC_None,

	ProcCC_MAX,


	ProcCC_ForeignBlockDefault = -1,
};

enum StateFlag {
	StateFlag_bounds_check    = 1<<0,
	StateFlag_no_bounds_check = 1<<1,

	StateFlag_no_deferred = 1<<5,
};

enum ViralStateFlag {
	ViralStateFlag_ContainsDeferredProcedure = 1<<0,
};


enum FieldFlag {
	FieldFlag_NONE      = 0,
	FieldFlag_ellipsis  = 1<<0,
	FieldFlag_using     = 1<<1,
	FieldFlag_no_alias  = 1<<2,
	FieldFlag_c_vararg  = 1<<3,
	FieldFlag_auto_cast = 1<<4,

	FieldFlag_Tags = 1<<10,

	FieldFlag_Results   = 1<<16,

	FieldFlag_Signature = FieldFlag_ellipsis|FieldFlag_using|FieldFlag_no_alias|FieldFlag_c_vararg|FieldFlag_auto_cast,
	FieldFlag_Struct    = FieldFlag_using|FieldFlag_Tags,
};

enum StmtAllowFlag {
	StmtAllowFlag_None    = 0,
	StmtAllowFlag_In      = 1<<0,
	StmtAllowFlag_Label   = 1<<1,
};

#define AST_KINDS \
	AST_KIND(Ident,          "identifier",      struct { \
		Token   token;  \
		Entity *entity; \
	}) \
	AST_KIND(Implicit,       "implicit",        Token) \
	AST_KIND(Undef,          "undef",           Token) \
	AST_KIND(BasicLit,       "basic literal",   struct { \
		Token token; \
		ExactValue value; \
	}) \
	AST_KIND(BasicDirective, "basic directive", struct { \
		Token  token; \
		String name; \
	}) \
	AST_KIND(Ellipsis,       "ellipsis", struct { \
		Token    token; \
		Ast *expr; \
	}) \
	AST_KIND(ProcGroup, "procedure group", struct { \
		Token        token; \
		Token        open;  \
		Token        close; \
		Array<Ast *> args;  \
	}) \
	AST_KIND(ProcLit, "procedure literal", struct { \
		Ast *type; \
		Ast *body; \
		u64  tags; \
		ProcInlining inlining; \
		Token where_token; \
		Array<Ast *> where_clauses; \
		DeclInfo *decl; \
	}) \
	AST_KIND(CompoundLit, "compound literal", struct { \
		Ast *type; \
		Array<Ast *> elems; \
		Token open, close; \
		i64 max_count; \
	}) \
AST_KIND(_ExprBegin,  "",  bool) \
	AST_KIND(BadExpr,      "bad expression",         struct { Token begin, end; }) \
	AST_KIND(TagExpr,      "tag expression",         struct { Token token, name; Ast *expr; }) \
	AST_KIND(UnaryExpr,    "unary expression",       struct { Token op; Ast *expr; }) \
	AST_KIND(BinaryExpr,   "binary expression",      struct { Token op; Ast *left, *right; } ) \
	AST_KIND(ParenExpr,    "parentheses expression", struct { Ast *expr; Token open, close; }) \
	AST_KIND(SelectorExpr, "selector expression",    struct { Token token; Ast *expr, *selector; }) \
	AST_KIND(ImplicitSelectorExpr, "implicit selector expression",    struct { Token token; Ast *selector; }) \
	AST_KIND(SelectorCallExpr, "selector call expression",    struct { Token token; Ast *expr, *call; bool modified_call; }) \
	AST_KIND(IndexExpr,    "index expression",       struct { Ast *expr, *index; Token open, close; }) \
	AST_KIND(DerefExpr,    "dereference expression", struct { Token op; Ast *expr; }) \
	AST_KIND(SliceExpr,    "slice expression", struct { \
		Ast *expr; \
		Token open, close; \
		Token interval; \
		Ast *low, *high; \
	}) \
	AST_KIND(CallExpr,     "call expression", struct { \
		Ast *        proc; \
		Array<Ast *> args; \
		Token        open; \
		Token        close; \
		Token        ellipsis; \
		ProcInlining inlining; \
		bool         optional_ok_one; \
	}) \
	AST_KIND(FieldValue,      "field value",              struct { Token eq; Ast *field, *value; }) \
	AST_KIND(TernaryExpr,     "ternary expression",       struct { Ast *cond, *x, *y; }) \
	AST_KIND(TernaryIfExpr,   "ternary if expression",    struct { Ast *x, *cond, *y; }) \
	AST_KIND(TernaryWhenExpr, "ternary when expression",  struct { Ast *x, *cond, *y; }) \
	AST_KIND(TypeAssertion, "type assertion",      struct { Ast *expr; Token dot; Ast *type; Type *type_hint; }) \
	AST_KIND(TypeCast,      "type cast",           struct { Token token; Ast *type, *expr; }) \
	AST_KIND(AutoCast,      "auto_cast",           struct { Token token; Ast *expr; }) \
AST_KIND(_ExprEnd,       "", bool) \
AST_KIND(_StmtBegin,     "", bool) \
	AST_KIND(BadStmt,    "bad statement",                 struct { Token begin, end; }) \
	AST_KIND(EmptyStmt,  "empty statement",               struct { Token token; }) \
	AST_KIND(ExprStmt,   "expression statement",          struct { Ast *expr; } ) \
	AST_KIND(TagStmt,    "tag statement", struct { \
		Token token; \
		Token name; \
		Ast * stmt; \
	}) \
	AST_KIND(AssignStmt, "assign statement", struct { \
		Token op; \
		Array<Ast *> lhs, rhs; \
	}) \
	AST_KIND(IncDecStmt, "increment decrement statement", struct { \
		Token op; \
		Ast *expr; \
	}) \
AST_KIND(_ComplexStmtBegin, "", bool) \
	AST_KIND(BlockStmt, "block statement", struct { \
		Array<Ast *> stmts; \
		Ast *label;         \
		Token open, close; \
	}) \
	AST_KIND(IfStmt, "if statement", struct { \
		Token token;     \
		Ast *label;      \
		Ast * init;      \
		Ast * cond;      \
		Ast * body;      \
		Ast * else_stmt; \
	}) \
	AST_KIND(WhenStmt, "when statement", struct { \
		Token token; \
		Ast *cond; \
		Ast *body; \
		Ast *else_stmt; \
		bool is_cond_determined; \
		bool determined_cond; \
	}) \
	AST_KIND(ReturnStmt, "return statement", struct { \
		Token token; \
		Array<Ast *> results; \
	}) \
	AST_KIND(ForStmt, "for statement", struct { \
		Token token; \
		Ast *label; \
		Ast *init; \
		Ast *cond; \
		Ast *post; \
		Ast *body; \
	}) \
	AST_KIND(RangeStmt, "range statement", struct { \
		Token token; \
		Ast *label; \
		Ast *val0; \
		Ast *val1; \
		Token in_token; \
		Ast *expr; \
		Ast *body; \
	}) \
	AST_KIND(InlineRangeStmt, "inline range statement", struct { \
		Token inline_token; \
		Token for_token; \
		Ast *val0; \
		Ast *val1; \
		Token in_token; \
		Ast *expr; \
		Ast *body; \
	}) \
	AST_KIND(CaseClause, "case clause", struct { \
		Token token;             \
		Array<Ast *> list;   \
		Array<Ast *> stmts;  \
		Entity *implicit_entity; \
	}) \
	AST_KIND(SwitchStmt, "switch statement", struct { \
		Token token;  \
		Ast *label;   \
		Ast *init;    \
		Ast *tag;     \
		Ast *body;    \
		bool partial; \
	}) \
	AST_KIND(TypeSwitchStmt, "type switch statement", struct { \
		Token token; \
		Ast *label;  \
		Ast *tag;    \
		Ast *body;   \
		bool partial; \
}) \
	AST_KIND(DeferStmt,  "defer statement",  struct { Token token; Ast *stmt; }) \
	AST_KIND(BranchStmt, "branch statement", struct { Token token; Ast *label; }) \
	AST_KIND(UsingStmt,  "using statement",  struct { \
		Token token; \
		Array<Ast *> list; \
	}) \
AST_KIND(_ComplexStmtEnd, "", bool) \
AST_KIND(_StmtEnd,        "", bool) \
AST_KIND(_DeclBegin,      "", bool) \
	AST_KIND(BadDecl,     "bad declaration",     struct { Token begin, end; }) \
	AST_KIND(ForeignBlockDecl, "foreign block declaration", struct { \
		Token token;             \
		Ast *foreign_library;    \
		Ast *body;               \
		Array<Ast *> attributes; \
		CommentGroup *docs;      \
	}) \
	AST_KIND(Label, "label", struct { 	\
		Token token; \
		Ast *name; \
	}) \
	AST_KIND(ValueDecl, "value declaration", struct { \
		Array<Ast *> names;       \
		Ast *        type;        \
		Array<Ast *> values;      \
		Array<Ast *> attributes;  \
		CommentGroup *docs;       \
		CommentGroup *comment;    \
		bool          is_using;   \
		bool          is_mutable; \
	}) \
	AST_KIND(PackageDecl, "package declaration", struct { \
		Token token;           \
		Token name;            \
		CommentGroup *docs;    \
		CommentGroup *comment; \
	}) \
	AST_KIND(ImportDecl, "import declaration", struct { \
		AstPackage *package;    \
		Token    token;         \
		Token    relpath;       \
		String   fullpath;      \
		Token    import_name;   \
		CommentGroup *docs;     \
		CommentGroup *comment;  \
		bool     is_using;      \
	}) \
	AST_KIND(ForeignImportDecl, "foreign import declaration", struct { \
		Token    token;           \
		Array<Token> filepaths;   \
		Token    library_name;    \
		String   collection_name; \
		Array<String> fullpaths;  \
		Array<Ast *> attributes;  \
		CommentGroup *docs;       \
		CommentGroup *comment;    \
	}) \
AST_KIND(_DeclEnd,   "", bool) \
	AST_KIND(Attribute, "attribute", struct { \
		Token token;        \
		Array<Ast *> elems; \
		Token open, close;  \
	}) \
	AST_KIND(Field, "field", struct { \
		Array<Ast *> names;         \
		Ast *        type;          \
		Ast *        default_value; \
		Token        tag;           \
		u32              flags;     \
		CommentGroup *   docs;      \
		CommentGroup *   comment;   \
	}) \
	AST_KIND(FieldList, "field list", struct { \
		Token token;       \
		Array<Ast *> list; \
	}) \
AST_KIND(_TypeBegin, "", bool) \
	AST_KIND(TypeidType, "typeid", struct { \
		Token token; \
		Ast *specialization; \
	}) \
	AST_KIND(HelperType, "helper type", struct { \
		Token token; \
		Ast *type; \
	}) \
	AST_KIND(DistinctType, "distinct type", struct { \
		Token token; \
		Ast *type; \
	}) \
	AST_KIND(OpaqueType, "opaque type", struct { \
		Token token; \
		Ast *type; \
	}) \
	AST_KIND(PolyType, "polymorphic type", struct { \
		Token token; \
		Ast * type;  \
		Ast * specialization;  \
	}) \
	AST_KIND(ProcType, "procedure type", struct { \
		Token token;   \
		Ast *params;  \
		Ast *results; \
		u64 tags;    \
		ProcCallingConvention calling_convention; \
		bool generic; \
		bool diverging; \
	}) \
	AST_KIND(PointerType, "pointer type", struct { \
		Token token; \
		Ast *type; \
	}) \
	AST_KIND(RelativeType, "relative type", struct { \
		Ast *tag; \
		Ast *type; \
	}) \
	AST_KIND(ArrayType, "array type", struct { \
		Token token; \
		Ast *count; \
		Ast *elem; \
		Ast *tag;  \
	}) \
	AST_KIND(DynamicArrayType, "dynamic array type", struct { \
		Token token; \
		Ast *elem; \
		Ast *tag;  \
	}) \
	AST_KIND(StructType, "struct type", struct { \
		Token token;                \
		Array<Ast *> fields;        \
		isize field_count;          \
		Ast *polymorphic_params;    \
		Ast *align;                 \
		Token where_token;          \
		Array<Ast *> where_clauses; \
		bool is_packed;             \
		bool is_raw_union;          \
	}) \
	AST_KIND(UnionType, "union type", struct { \
		Token        token;         \
		Array<Ast *> variants;      \
		Ast *polymorphic_params;    \
		Ast *        align;         \
		bool         maybe;         \
		bool         no_nil;        \
		Token where_token;          \
		Array<Ast *> where_clauses; \
	}) \
	AST_KIND(EnumType, "enum type", struct { \
		Token        token; \
		Ast *        base_type; \
		Array<Ast *> fields; /* FieldValue */ \
		bool         is_using; \
	}) \
	AST_KIND(BitFieldType, "bit field type", struct { \
		Token        token; \
		Array<Ast *> fields; /* FieldValue with : */ \
		Ast *        align; \
	}) \
	AST_KIND(BitSetType, "bit set type", struct { \
		Token token; \
		Ast * elem;  \
		Ast * underlying; \
	}) \
	AST_KIND(MapType, "map type", struct { \
		Token token; \
		Ast *count; \
		Ast *key; \
		Ast *value; \
	}) \
AST_KIND(_TypeEnd,  "", bool)

enum AstKind {
	Ast_Invalid,
#define AST_KIND(_kind_name_, ...) GB_JOIN2(Ast_, _kind_name_),
	AST_KINDS
#undef AST_KIND
	Ast_COUNT,
};

String const ast_strings[] = {
	{cast(u8 *)"invalid node", gb_size_of("invalid node")},
#define AST_KIND(_kind_name_, name, ...) {cast(u8 *)name, gb_size_of(name)-1},
	AST_KINDS
#undef AST_KIND
};


#define AST_KIND(_kind_name_, name, ...) typedef __VA_ARGS__ GB_JOIN2(Ast, _kind_name_);
	AST_KINDS
#undef AST_KIND


isize const ast_variant_sizes[] = {
	0,
#define AST_KIND(_kind_name_, name, ...) gb_size_of(GB_JOIN2(Ast, _kind_name_)),
	AST_KINDS
#undef AST_KIND
};

struct AstCommonStuff {
	AstKind      kind;
	u32          state_flags;
	u32          viral_state_flags;
	bool         been_handled;
	AstFile *    file;
	Scope *      scope;
	TypeAndValue tav;
};

struct Ast {
	AstKind      kind;
	u32          state_flags;
	u32          viral_state_flags;
	bool         been_handled;
	AstFile *    file;
	Scope *      scope;
	TypeAndValue tav;

	union {
#define AST_KIND(_kind_name_, name, ...) GB_JOIN2(Ast, _kind_name_) _kind_name_;
	AST_KINDS
#undef AST_KIND
	};
};


#define ast_node(n_, Kind_, node_) GB_JOIN2(Ast, Kind_) *n_ = &(node_)->Kind_; GB_ASSERT_MSG((node_)->kind == GB_JOIN2(Ast_, Kind_), \
	"expected '%.*s' got '%.*s'", \
	LIT(ast_strings[GB_JOIN2(Ast_, Kind_)]), LIT(ast_strings[(node_)->kind]))
#define case_ast_node(n_, Kind_, node_) case GB_JOIN2(Ast_, Kind_): { ast_node(n_, Kind_, node_);
#ifndef case_end
#define case_end } break;
#endif


gb_inline bool is_ast_expr(Ast *node) {
	return gb_is_between(node->kind, Ast__ExprBegin+1, Ast__ExprEnd-1);
}
gb_inline bool is_ast_stmt(Ast *node) {
	return gb_is_between(node->kind, Ast__StmtBegin+1, Ast__StmtEnd-1);
}
gb_inline bool is_ast_complex_stmt(Ast *node) {
	return gb_is_between(node->kind, Ast__ComplexStmtBegin+1, Ast__ComplexStmtEnd-1);
}
gb_inline bool is_ast_decl(Ast *node) {
	return gb_is_between(node->kind, Ast__DeclBegin+1, Ast__DeclEnd-1);
}
gb_inline bool is_ast_type(Ast *node) {
	return gb_is_between(node->kind, Ast__TypeBegin+1, Ast__TypeEnd-1);
}
gb_inline bool is_ast_when_stmt(Ast *node) {
	return node->kind == Ast_WhenStmt;
}

gb_global Arena global_ast_arena = {};

gbAllocator ast_allocator(AstFile *f) {
	Arena *arena = f ? &f->arena : &global_ast_arena;
	// Arena *arena = &global_ast_arena;
	return arena_allocator(arena);
}

Ast *alloc_ast_node(AstFile *f, AstKind kind);

