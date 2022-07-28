struct Ast;
struct Scope;
struct Type;
struct Entity;
struct DeclInfo;
struct AstFile;
struct AstPackage;

enum AddressingMode : u8 {
	Addressing_Invalid   = 0,        // invalid addressing mode
	Addressing_NoValue   = 1,        // no value (void in C)
	Addressing_Value     = 2,        // computed value (rvalue)
	Addressing_Context   = 3,        // context value
	Addressing_Variable  = 4,        // addressable variable (lvalue)
	Addressing_Constant  = 5,        // constant
	Addressing_Type      = 6,        // type
	Addressing_Builtin   = 7,        // built-in procedure
	Addressing_ProcGroup = 8,        // procedure group (overloaded procedure)
	Addressing_MapIndex  = 9,        // map index expression -
	                                 //         lhs: acts like a Variable
	                                 //         rhs: acts like OptionalOk
	Addressing_OptionalOk    = 10,   // rhs: acts like a value with an optional boolean part (for existence check)
	Addressing_OptionalOkPtr = 11,   // rhs: same as OptionalOk but the value is a pointer
	Addressing_SoaVariable   = 12,   // Struct-Of-Arrays indexed variable

	Addressing_SwizzleValue    = 13, // Swizzle indexed value
	Addressing_SwizzleVariable = 14, // Swizzle indexed variable
};

struct TypeAndValue {
	Type *         type;
	AddressingMode mode;
	bool           is_lhs; // Debug info
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
	ParseFile_GeneralError,
	ParseFile_FileTooLarge,
	ParseFile_DirectoryAlreadyExists,

	ParseFile_Count,
};

struct CommentGroup {
	Slice<Token> list; // Token_Comment
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

enum AstFileFlag : u32 {
	AstFile_IsPrivatePkg = 1<<0,
	AstFile_IsPrivateFile = 1<<1,

	AstFile_IsTest    = 1<<3,
	AstFile_IsLazy    = 1<<4,
};

enum AstDelayQueueKind {
	AstDelayQueue_Import,
	AstDelayQueue_Expr,
	AstDelayQueue_COUNT,
};

struct AstFile {
	i32          id;
	u32          flags;
	AstPackage * pkg;
	Scope *      scope;

	Ast *        pkg_decl;
	String       fullpath;
	Tokenizer    tokenizer;
	Array<Token> tokens;
	isize        curr_token_index;
	isize        prev_token_index;
	Token        curr_token;
	Token        prev_token; // previous non-comment
	Token        package_token;
	String       package_name;

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	isize        expr_level;
	bool         allow_newline; // Only valid for expr_level == 0
	bool         allow_range;   // NOTE(bill): Ranges are only allowed in certain cases
	bool         allow_in_expr; // NOTE(bill): in expression are only allowed in certain cases
	bool         in_foreign_block;
	bool         allow_type;

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

	// TODO(bill): make this a basic queue as it does not require
	// any multiple thread capabilities
	MPMCQueue<Ast *> delayed_decls_queues[AstDelayQueue_COUNT];

#define PARSER_MAX_FIX_COUNT 6
	isize    fix_count;
	TokenPos fix_prev_pos;

	struct LLVMOpaqueMetadata *llvm_metadata;
	struct LLVMOpaqueMetadata *llvm_metadata_scope;
};

enum AstForeignFileKind {
	AstForeignFile_Invalid,

	AstForeignFile_S, // Source,

	AstForeignFile_COUNT
};

struct AstForeignFile {
	AstForeignFileKind kind;
	String source;
};


struct AstPackageExportedEntity {
	Ast *identifier;
	Entity *entity;
};

struct AstPackage {
	PackageKind           kind;
	isize                 id;
	String                name;
	String                fullpath;
	Array<AstFile *>      files;
	Array<AstForeignFile> foreign_files;
	bool                  is_single_file;
	isize                 order;

	MPMCQueue<AstPackageExportedEntity> exported_entity_queue;

	// NOTE(bill): Created/set in checker
	Scope *   scope;
	DeclInfo *decl_info;
	bool      is_extra;
};


struct Parser {
	String                    init_fullpath;
	StringSet                 imported_files; // fullpath
	Array<AstPackage *>       packages;
	Array<ImportedPackage>    package_imports;
	isize                     file_to_process_count;
	isize                     total_token_count;
	isize                     total_line_count;
	BlockingMutex             wait_mutex;
	BlockingMutex             import_mutex;
	BlockingMutex             file_add_mutex;
	BlockingMutex             file_decl_mutex;
	BlockingMutex             packages_mutex;
	MPMCQueue<ParseFileError> file_error_queue;
};

struct ParserWorkerData {
	Parser *parser;
	ImportedFile imported_file;
};

struct ForeignFileWorkerData {
	Parser *parser;
	ImportedFile imported_file;
	AstForeignFileKind foreign_kind;
};






enum ProcInlining {
	ProcInlining_none = 0,
	ProcInlining_inline = 1,
	ProcInlining_no_inline = 2,
};

enum ProcTag {
	ProcTag_bounds_check    = 1<<0,
	ProcTag_no_bounds_check = 1<<1,
	ProcTag_type_assert     = 1<<2,
	ProcTag_no_type_assert  = 1<<3,

	ProcTag_require_results = 1<<4,
	ProcTag_optional_ok     = 1<<5,
	ProcTag_optional_second = 1<<6,
};

enum ProcCallingConvention : i32 {
	ProcCC_Invalid     = 0,
	ProcCC_Odin        = 1,
	ProcCC_Contextless = 2,
	ProcCC_CDecl       = 3,
	ProcCC_StdCall     = 4,
	ProcCC_FastCall    = 5,

	ProcCC_None        = 6,
	ProcCC_Naked       = 7,

	ProcCC_InlineAsm   = 8,

	ProcCC_Win64       = 9,
	ProcCC_SysV        = 10,


	ProcCC_MAX,


	ProcCC_ForeignBlockDefault = -1,
};

char const *proc_calling_convention_strings[ProcCC_MAX] = {
	"",
	"odin",
	"contextless",
	"cdecl",
	"stdcall",
	"fastcall",
	"none",
	"naked",
	"inlineasm",
	"win64",
	"sysv",
};

ProcCallingConvention default_calling_convention(void) {
	return ProcCC_Odin;
}

enum StateFlag : u8 {
	StateFlag_bounds_check    = 1<<0,
	StateFlag_no_bounds_check = 1<<1,
	StateFlag_type_assert     = 1<<2,
	StateFlag_no_type_assert  = 1<<3,

	StateFlag_SelectorCallExpr = 1<<6,

	StateFlag_BeenHandled = 1<<7,
};

enum ViralStateFlag : u8 {
	ViralStateFlag_ContainsDeferredProcedure = 1<<0,
};


enum FieldFlag : u32 {
	FieldFlag_NONE      = 0,
	FieldFlag_ellipsis  = 1<<0,
	FieldFlag_using     = 1<<1,
	FieldFlag_no_alias  = 1<<2,
	FieldFlag_c_vararg  = 1<<3,
	FieldFlag_auto_cast = 1<<4,
	FieldFlag_const     = 1<<5,
	FieldFlag_any_int   = 1<<6,
	FieldFlag_subtype   = 1<<7,
	FieldFlag_by_ptr    = 1<<8,

	// Internal use by the parser only
	FieldFlag_Tags      = 1<<10,
	FieldFlag_Results   = 1<<16,

	// Parameter List Restrictions
	FieldFlag_Signature = FieldFlag_ellipsis|FieldFlag_using|FieldFlag_no_alias|FieldFlag_c_vararg|FieldFlag_auto_cast|FieldFlag_const|FieldFlag_any_int|FieldFlag_by_ptr,
	FieldFlag_Struct    = FieldFlag_using|FieldFlag_subtype|FieldFlag_Tags,
};

enum StmtAllowFlag {
	StmtAllowFlag_None    = 0,
	StmtAllowFlag_In      = 1<<0,
	StmtAllowFlag_Label   = 1<<1,
};

enum InlineAsmDialectKind : u8 {
	InlineAsmDialect_Default, // ATT is default
	InlineAsmDialect_ATT,
	InlineAsmDialect_Intel,

	InlineAsmDialect_COUNT,
};

char const *inline_asm_dialect_strings[InlineAsmDialect_COUNT] = {
	"",
	"att",
	"intel",
};

enum UnionTypeKind : u8 {
	UnionType_Normal     = 0,
	UnionType_maybe      = 1, // removed
	UnionType_no_nil     = 2,
	UnionType_shared_nil = 3,
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
	}) \
	AST_KIND(BasicDirective, "basic directive", struct { \
		Token token; \
		Token name; \
	}) \
	AST_KIND(Ellipsis,       "ellipsis", struct { \
		Token    token; \
		Ast *expr; \
	}) \
	AST_KIND(ProcGroup, "procedure group", struct { \
		Token        token; \
		Token        open;  \
		Token        close; \
		Slice<Ast *> args;  \
	}) \
	AST_KIND(ProcLit, "procedure literal", struct { \
		Ast *type; \
		Ast *body; \
		u64  tags; \
		ProcInlining inlining; \
		Token where_token; \
		Slice<Ast *> where_clauses; \
		DeclInfo *decl; \
	}) \
	AST_KIND(CompoundLit, "compound literal", struct { \
		Ast *type; \
		Slice<Ast *> elems; \
		Token open, close; \
		i64 max_count; \
		Ast *tag; \
	}) \
AST_KIND(_ExprBegin,  "",  bool) \
	AST_KIND(BadExpr,      "bad expression",         struct { Token begin, end; }) \
	AST_KIND(TagExpr,      "tag expression",         struct { Token token, name; Ast *expr; }) \
	AST_KIND(UnaryExpr,    "unary expression",       struct { Token op; Ast *expr; }) \
	AST_KIND(BinaryExpr,   "binary expression",      struct { Token op; Ast *left, *right; } ) \
	AST_KIND(ParenExpr,    "parentheses expression", struct { Ast *expr; Token open, close; }) \
	AST_KIND(SelectorExpr, "selector expression",    struct { \
		Token token; \
		Ast *expr, *selector; \
		u8 swizzle_count; /*maximum of 4 components, if set, count >= 2*/ \
		u8 swizzle_indices; /*2 bits per component*/ \
	}) \
	AST_KIND(ImplicitSelectorExpr, "implicit selector expression",    struct { Token token; Ast *selector; }) \
	AST_KIND(SelectorCallExpr, "selector call expression", struct { \
		Token token; \
		Ast *expr, *call;  \
		bool modified_call; \
	}) \
	AST_KIND(IndexExpr,    "index expression",       struct { Ast *expr, *index; Token open, close; }) \
	AST_KIND(DerefExpr,    "dereference expression", struct { Ast *expr; Token op; }) \
	AST_KIND(SliceExpr,    "slice expression", struct { \
		Ast *expr; \
		Token open, close; \
		Token interval; \
		Ast *low, *high; \
	}) \
	AST_KIND(CallExpr,     "call expression", struct { \
		Ast *        proc; \
		Slice<Ast *> args; \
		Token        open; \
		Token        close; \
		Token        ellipsis; \
		ProcInlining inlining; \
		bool         optional_ok_one; \
		bool         was_selector; \
	}) \
	AST_KIND(FieldValue,      "field value",              struct { Token eq; Ast *field, *value; }) \
	AST_KIND(EnumFieldValue,  "enum field value",         struct { \
		Ast *name;          \
		Ast *value;         \
		CommentGroup *docs; \
		CommentGroup *comment; \
	}) \
	AST_KIND(TernaryIfExpr,   "ternary if expression",    struct { Ast *x, *cond, *y; }) \
	AST_KIND(TernaryWhenExpr, "ternary when expression",  struct { Ast *x, *cond, *y; }) \
	AST_KIND(OrElseExpr,      "or_else expression",       struct { Ast *x; Token token; Ast *y; }) \
	AST_KIND(OrReturnExpr,    "or_return expression",     struct { Ast *expr; Token token; }) \
	AST_KIND(TypeAssertion, "type assertion", struct { \
		Ast *expr; \
		Token dot; \
		Ast *type; \
		Type *type_hint; \
		bool ignores[2]; \
	}) \
	AST_KIND(TypeCast,      "type cast",           struct { Token token; Ast *type, *expr; }) \
	AST_KIND(AutoCast,      "auto_cast",           struct { Token token; Ast *expr; }) \
	AST_KIND(InlineAsmExpr, "inline asm expression", struct { \
		Token token; \
		Token open, close; \
		Slice<Ast *> param_types; \
		Ast *return_type; \
		Ast *asm_string; \
		Ast *constraints_string; \
		bool has_side_effects; \
		bool is_align_stack; \
		InlineAsmDialectKind dialect; \
	}) \
	AST_KIND(MatrixIndexExpr, "matrix index expression",       struct { Ast *expr, *row_index, *column_index; Token open, close; }) \
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
		Slice<Ast *> lhs, rhs; \
	}) \
AST_KIND(_ComplexStmtBegin, "", bool) \
	AST_KIND(BlockStmt, "block statement", struct { \
		Scope *scope; \
		Slice<Ast *> stmts; \
		Ast *label;         \
		Token open, close; \
	}) \
	AST_KIND(IfStmt, "if statement", struct { \
		Scope *scope; \
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
		Slice<Ast *> results; \
	}) \
	AST_KIND(ForStmt, "for statement", struct { \
		Scope *scope; \
		Token token; \
		Ast *label; \
		Ast *init; \
		Ast *cond; \
		Ast *post; \
		Ast *body; \
	}) \
	AST_KIND(RangeStmt, "range statement", struct { \
		Scope *scope; \
		Token token; \
		Ast *label; \
		Slice<Ast *> vals; \
		Token in_token; \
		Ast *expr; \
		Ast *body; \
	}) \
	AST_KIND(UnrollRangeStmt, "#unroll range statement", struct { \
		Scope *scope; \
		Token unroll_token; \
		Token for_token; \
		Ast *val0; \
		Ast *val1; \
		Token in_token; \
		Ast *expr; \
		Ast *body; \
	}) \
	AST_KIND(CaseClause, "case clause", struct { \
		Scope *scope; \
		Token token;             \
		Slice<Ast *> list;   \
		Slice<Ast *> stmts;  \
		Entity *implicit_entity; \
	}) \
	AST_KIND(SwitchStmt, "switch statement", struct { \
		Scope *scope; \
		Token token;  \
		Ast *label;   \
		Ast *init;    \
		Ast *tag;     \
		Ast *body;    \
		bool partial; \
	}) \
	AST_KIND(TypeSwitchStmt, "type switch statement", struct { \
		Scope *scope; \
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
		Slice<Ast *> list; \
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
		Slice<Ast *> names;       \
		Ast *        type;        \
		Slice<Ast *> values;      \
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
	}) \
	AST_KIND(ForeignImportDecl, "foreign import declaration", struct { \
		Token    token;           \
		Slice<Token> filepaths;   \
		Token    library_name;    \
		String   collection_name; \
		Slice<String> fullpaths;  \
		Array<Ast *> attributes;  \
		CommentGroup *docs;       \
		CommentGroup *comment;    \
	}) \
AST_KIND(_DeclEnd,   "", bool) \
	AST_KIND(Attribute, "attribute", struct { \
		Token token;        \
		Slice<Ast *> elems; \
		Token open, close;  \
	}) \
	AST_KIND(Field, "field", struct { \
		Slice<Ast *> names;         \
		Ast *        type;          \
		Ast *        default_value; \
		Token        tag;           \
		u32              flags;     \
		CommentGroup *   docs;      \
		CommentGroup *   comment;   \
	}) \
	AST_KIND(FieldList, "field list", struct { \
		Token token;       \
		Slice<Ast *> list; \
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
	AST_KIND(PolyType, "polymorphic type", struct { \
		Token token; \
		Ast * type;  \
		Ast * specialization;  \
	}) \
	AST_KIND(ProcType, "procedure type", struct { \
		Scope *scope; \
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
	AST_KIND(MultiPointerType, "multi pointer type", struct { \
		Token token; \
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
		Scope *scope; \
		Token token;                \
		Slice<Ast *> fields;        \
		isize field_count;          \
		Ast *polymorphic_params;    \
		Ast *align;                 \
		Token where_token;          \
		Slice<Ast *> where_clauses; \
		bool is_packed;             \
		bool is_raw_union;          \
	}) \
	AST_KIND(UnionType, "union type", struct { \
		Scope *scope; \
		Token        token;         \
		Slice<Ast *> variants;      \
		Ast *polymorphic_params;    \
		Ast *        align;         \
		UnionTypeKind kind;       \
		Token where_token;          \
		Slice<Ast *> where_clauses; \
	}) \
	AST_KIND(EnumType, "enum type", struct { \
		Scope *scope; \
		Token        token; \
		Ast *        base_type; \
		Slice<Ast *> fields; /* FieldValue */ \
		bool         is_using; \
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
	AST_KIND(MatrixType, "matrix type", struct { \
		Token token;       \
		Ast *row_count;    \
		Ast *column_count; \
		Ast *elem;         \
	}) \
AST_KIND(_TypeEnd,  "", bool)

enum AstKind : u16 {
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
	AstKind      kind; // u16
	u8           state_flags;
	u8           viral_state_flags;
	i32          file_id;
	TypeAndValue tav; // TODO(bill): Make this a pointer to minimize 'Ast' size
};

struct Ast {
	AstKind      kind; // u16
	u8           state_flags;
	u8           viral_state_flags;
	i32          file_id;
	TypeAndValue tav; // TODO(bill): Make this a pointer to minimize 'Ast' size

	// IMPORTANT NOTE(bill): This must be at the end since the AST is allocated to be size of the variant
	union {
#define AST_KIND(_kind_name_, name, ...) GB_JOIN2(Ast, _kind_name_) _kind_name_;
	AST_KINDS
#undef AST_KIND
	};
	
	
	// NOTE(bill): I know I dislike methods but this is hopefully a temporary thing 
	// for refactoring purposes
	gb_inline AstFile *file() const {
		// NOTE(bill): This doesn't need to call get_ast_file_from_id which 
		return global_files[this->file_id];
	}
	gb_inline AstFile *thread_safe_file() const {
		return thread_safe_get_ast_file_from_id(this->file_id);
	}
};


#define ast_node(n_, Kind_, node_) GB_JOIN2(Ast, Kind_) *n_ = &(node_)->Kind_; gb_unused(n_); GB_ASSERT_MSG((node_)->kind == GB_JOIN2(Ast_, Kind_), \
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

gb_global gb_thread_local Arena global_thread_local_ast_arena = {};

gbAllocator ast_allocator(AstFile *f) {
	Arena *arena = &global_thread_local_ast_arena;
	return arena_allocator(arena);
}

Ast *alloc_ast_node(AstFile *f, AstKind kind);

gbString expr_to_string(Ast *expression);
bool allow_field_separator(AstFile *f);