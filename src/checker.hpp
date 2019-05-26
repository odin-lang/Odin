// checker.hpp

struct Type;
struct Entity;
struct Scope;
struct DeclInfo;
struct AstFile;
struct Checker;
struct CheckerInfo;
struct CheckerContext;

enum AddressingMode;
struct TypeAndValue;

// ExprInfo stores information used for "untyped" expressions
struct ExprInfo {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
	bool is_lhs; // Debug info
};

gb_inline ExprInfo make_expr_info(AddressingMode mode, Type *type, ExactValue value, bool is_lhs) {
	ExprInfo ei = {};
	ei.mode   = mode;
	ei.type   = type;
	ei.value  = value;
	ei.is_lhs = is_lhs;
	return ei;
}




enum ExprKind {
	Expr_Expr,
	Expr_Stmt,
};

// Statements and Declarations
enum StmtFlag {
	Stmt_BreakAllowed       = 1<<0,
	Stmt_ContinueAllowed    = 1<<1,
	Stmt_FallthroughAllowed = 1<<2,

	Stmt_CheckScopeDecls    = 1<<5,
};

enum BuiltinProcPkg {
	BuiltinProcPkg_builtin,
	BuiltinProcPkg_intrinsics,
};

struct BuiltinProc {
	String   name;
	isize    arg_count;
	bool     variadic;
	ExprKind kind;
	BuiltinProcPkg pkg;
};

enum BuiltinProcId {
	BuiltinProc_Invalid,

	BuiltinProc_len,
	BuiltinProc_cap,

	BuiltinProc_size_of,
	BuiltinProc_align_of,
	BuiltinProc_offset_of,
	BuiltinProc_type_of,
	BuiltinProc_type_info_of,
	BuiltinProc_typeid_of,

	BuiltinProc_swizzle,

	BuiltinProc_complex,
	BuiltinProc_real,
	BuiltinProc_imag,
	BuiltinProc_conj,

	BuiltinProc_expand_to_tuple,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,
	BuiltinProc_clamp,

	BuiltinProc_DIRECTIVE, // NOTE(bill): This is used for specialized hash-prefixed procedures

	// "Intrinsics"
	BuiltinProc_vector,

	BuiltinProc_atomic_fence,
	BuiltinProc_atomic_fence_acq,
	BuiltinProc_atomic_fence_rel,
	BuiltinProc_atomic_fence_acqrel,

	BuiltinProc_atomic_store,
	BuiltinProc_atomic_store_rel,
	BuiltinProc_atomic_store_relaxed,
	BuiltinProc_atomic_store_unordered,

	BuiltinProc_atomic_load,
	BuiltinProc_atomic_load_acq,
	BuiltinProc_atomic_load_relaxed,
	BuiltinProc_atomic_load_unordered,

	BuiltinProc_atomic_add,
	BuiltinProc_atomic_add_acq,
	BuiltinProc_atomic_add_rel,
	BuiltinProc_atomic_add_acqrel,
	BuiltinProc_atomic_add_relaxed,
	BuiltinProc_atomic_sub,
	BuiltinProc_atomic_sub_acq,
	BuiltinProc_atomic_sub_rel,
	BuiltinProc_atomic_sub_acqrel,
	BuiltinProc_atomic_sub_relaxed,
	BuiltinProc_atomic_and,
	BuiltinProc_atomic_and_acq,
	BuiltinProc_atomic_and_rel,
	BuiltinProc_atomic_and_acqrel,
	BuiltinProc_atomic_and_relaxed,
	BuiltinProc_atomic_nand,
	BuiltinProc_atomic_nand_acq,
	BuiltinProc_atomic_nand_rel,
	BuiltinProc_atomic_nand_acqrel,
	BuiltinProc_atomic_nand_relaxed,
	BuiltinProc_atomic_or,
	BuiltinProc_atomic_or_acq,
	BuiltinProc_atomic_or_rel,
	BuiltinProc_atomic_or_acqrel,
	BuiltinProc_atomic_or_relaxed,
	BuiltinProc_atomic_xor,
	BuiltinProc_atomic_xor_acq,
	BuiltinProc_atomic_xor_rel,
	BuiltinProc_atomic_xor_acqrel,
	BuiltinProc_atomic_xor_relaxed,

	BuiltinProc_atomic_xchg,
	BuiltinProc_atomic_xchg_acq,
	BuiltinProc_atomic_xchg_rel,
	BuiltinProc_atomic_xchg_acqrel,
	BuiltinProc_atomic_xchg_relaxed,

	BuiltinProc_atomic_cxchg,
	BuiltinProc_atomic_cxchg_acq,
	BuiltinProc_atomic_cxchg_rel,
	BuiltinProc_atomic_cxchg_acqrel,
	BuiltinProc_atomic_cxchg_relaxed,
	BuiltinProc_atomic_cxchg_failrelaxed,
	BuiltinProc_atomic_cxchg_failacq,
	BuiltinProc_atomic_cxchg_acq_failrelaxed,
	BuiltinProc_atomic_cxchg_acqrel_failrelaxed,

	BuiltinProc_atomic_cxchgweak,
	BuiltinProc_atomic_cxchgweak_acq,
	BuiltinProc_atomic_cxchgweak_rel,
	BuiltinProc_atomic_cxchgweak_acqrel,
	BuiltinProc_atomic_cxchgweak_relaxed,
	BuiltinProc_atomic_cxchgweak_failrelaxed,
	BuiltinProc_atomic_cxchgweak_failacq,
	BuiltinProc_atomic_cxchgweak_acq_failrelaxed,
	BuiltinProc_atomic_cxchgweak_acqrel_failrelaxed,

	BuiltinProc_COUNT,
};
gb_global BuiltinProc builtin_procs[BuiltinProc_COUNT] = {
	{STR_LIT(""),                 0, false, Expr_Stmt, BuiltinProcPkg_builtin},

	{STR_LIT("len"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("cap"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("size_of"),          1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("align_of"),         1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("offset_of"),        2, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("type_of"),          1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("type_info_of"),     1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("typeid_of"),        1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("swizzle"),          1, true,  Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("complex"),          2, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("real"),             1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("imag"),             1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("conj"),             1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("expand_to_tuple"),  1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("min"),              1, true,  Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("max"),              1, true,  Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("abs"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("clamp"),            3, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT(""),                 0, true,  Expr_Expr, BuiltinProcPkg_builtin}, // DIRECTIVE


	// "Intrinsics"
	{STR_LIT("vector"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics}, // Type


	{STR_LIT("atomic_fence"),        0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_fence_acq"),    0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_fence_rel"),    0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_fence_acqrel"), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_store"),           2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_store_rel"),       2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_store_relaxed"),   2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_store_unordered"), 2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_load"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_load_acq"),        1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_load_relaxed"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_load_unordered"),  1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_add"),             2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_add_acq"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_add_rel"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_add_acqrel"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_add_relaxed"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub"),             2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub_acq"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub_rel"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub_acqrel"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub_relaxed"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and"),             2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and_acq"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and_rel"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and_acqrel"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and_relaxed"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand"),            2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand_acq"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand_rel"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand_acqrel"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand_relaxed"),    2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or"),              2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or_acq"),          2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or_rel"),          2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or_acqrel"),       2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or_relaxed"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor"),             2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor_acq"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor_rel"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor_acqrel"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor_relaxed"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_xchg"),            2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xchg_acq"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xchg_rel"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xchg_acqrel"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xchg_relaxed"),    2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_cxchg"),                    3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_acq"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_rel"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_acqrel"),             3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_relaxed"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_failrelaxed"),        3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_failacq"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_acq_failrelaxed"),    3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_acqrel_failrelaxed"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_cxchgweak"),                    3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_acq"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_rel"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_acqrel"),             3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_relaxed"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_failrelaxed"),        3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_failacq"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_acq_failrelaxed"),    3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_acqrel_failrelaxed"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
};


// Operand is used as an intermediate value whilst checking
// Operands store an addressing mode, the expression being evaluated,
// its type and node, and other specific information for certain
// addressing modes
// Its zero-value is a valid "invalid operand"
struct Operand {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
	Ast *      expr;
	BuiltinProcId  builtin_id;
	Entity *       proc_group;
};


struct BlockLabel {
	String   name;
	Ast *label; //  Ast_Label;
};

enum DeferredProcedureKind {
	DeferredProcedure_none,
	DeferredProcedure_in,
	DeferredProcedure_out,
};
struct DeferredProcedure {
	DeferredProcedureKind kind;
	Entity *entity;
};


struct AttributeContext {
	bool    is_export;
	bool    is_static;
	String  link_name;
	String  link_prefix;
	isize   init_expr_list_count;
	String  thread_local_model;
	String  deprecated_message;
	DeferredProcedure deferred_procedure;
};

AttributeContext make_attribute_context(String link_prefix) {
	AttributeContext ac = {};
	ac.link_prefix = link_prefix;
	return ac;
}

#define DECL_ATTRIBUTE_PROC(_name) bool _name(CheckerContext *c, Ast *elem, String name, Ast *value, AttributeContext *ac)
typedef DECL_ATTRIBUTE_PROC(DeclAttributeProc);

void check_decl_attributes(CheckerContext *c, Array<Ast *> const &attributes, DeclAttributeProc *proc, AttributeContext *ac);


// DeclInfo is used to store information of certain declarations to allow for "any order" usage
struct DeclInfo {
	DeclInfo *    parent; // NOTE(bill): only used for procedure literals at the moment
	Scope *       scope;

	Entity *entity;

	Ast *         type_expr;
	Ast *         init_expr;
	Array<Ast *>  attributes;
	Ast *         proc_lit;      // Ast_ProcLit
	Type *        gen_proc_type; // Precalculated
	bool          is_using;

	PtrSet<Entity *>  deps;
	PtrSet<Type *>    type_info_deps;
	Array<BlockLabel> labels;
};

// ProcInfo stores the information needed for checking a procedure
struct ProcInfo {
	AstFile * file;
	Token     token;
	DeclInfo *decl;
	Type *    type; // Type_Procedure
	Ast *     body; // Ast_BlockStmt
	u64       tags;
	bool      generated_from_polymorphic;
	Ast *     poly_def_node;
};



enum ScopeFlag {
	ScopeFlag_Pkg    = 1<<1,
	ScopeFlag_Global = 1<<2,
	ScopeFlag_File   = 1<<3,
	ScopeFlag_Init   = 1<<4,
	ScopeFlag_Proc   = 1<<5,
	ScopeFlag_Type   = 1<<6,

	ScopeFlag_HasBeenImported = 1<<10, // This is only applicable to file scopes
};

struct Scope {
	Ast *         node;
	Scope *       parent;
	Scope *       prev;
	Scope *       next;
	Scope *       first_child;
	Scope *       last_child;
	Map<Entity *> elements; // Key: String

	Array<Ast *>    delayed_directives;
	Array<Ast *>    delayed_imports;
	PtrSet<Scope *> imported;

	i32             flags; // ScopeFlag
	union {
		AstPackage *pkg;
		AstFile *   file;
	};
};




struct EntityGraphNode;
typedef PtrSet<EntityGraphNode *> EntityGraphNodeSet;

struct EntityGraphNode {
	Entity *     entity; // Procedure, Variable, Constant
	EntityGraphNodeSet pred;
	EntityGraphNodeSet succ;
	isize        index; // Index in array/queue
	isize        dep_count;
};



struct ImportGraphNode;
typedef PtrSet<ImportGraphNode *> ImportGraphNodeSet;


struct ImportGraphNode {
	AstPackage *       pkg;
	Scope *            scope;
	ImportGraphNodeSet pred;
	ImportGraphNodeSet succ;
	isize              index; // Index in array/queue
	isize              dep_count;
};


struct ForeignContext {
	Ast *                 curr_library;
	ProcCallingConvention default_cc;
	String                link_prefix;
	bool                  is_private;
};

typedef Array<Entity *> CheckerTypePath;
typedef Array<Type *>   CheckerPolyPath;

// CheckerInfo stores all the symbol information for a type-checked program
struct CheckerInfo {
	Map<ExprInfo>         untyped; // Key: Ast * | Expression -> ExprInfo
	                               // NOTE(bill): This needs to be a map and not on the Ast
	                               // as it needs to be iterated across
	Map<AstFile *>        files;           // Key: String (full path)
	Map<AstPackage *>     packages;        // Key: String (full path)
	Map<Entity *>         foreigns;        // Key: String
	Array<Entity *>       definitions;
	Array<Entity *>       entities;
	Array<DeclInfo *>     variable_init_order;

	Map<Array<Entity *> > gen_procs;       // Key: Ast * | Identifier -> Entity
	Map<Array<Entity *> > gen_types;       // Key: Type *

	Array<Type *>         type_info_types;
	Map<isize>            type_info_map;   // Key: Type *


	AstPackage *          builtin_package;
	AstPackage *          runtime_package;
	Scope *               init_scope;
	Entity *              entry_point;
	PtrSet<Entity *>      minimum_dependency_set;
	PtrSet<isize>         minimum_dependency_type_info_set;


	bool allow_identifier_uses;
	Array<Ast *> identifier_uses; // only used by 'odin query'
};

struct CheckerContext {
	Checker *      checker;
	CheckerInfo *  info;
	AstPackage *   pkg;
	AstFile *      file;
	Scope *        scope;
	DeclInfo *     decl;

	u32            stmt_state_flags;
	bool           in_defer; // TODO(bill): Actually handle correctly
	Type *         type_hint;

	String         proc_name;
	DeclInfo *     curr_proc_decl;
	Type *         curr_proc_sig;
	bool           in_proc_sig;
	ForeignContext foreign_context;
	gbAllocator    allocator;

	CheckerTypePath *type_path;
	isize            type_level; // TODO(bill): Actually handle correctly
	CheckerPolyPath *poly_path;
	isize            poly_level; // TODO(bill): Actually handle correctly

	bool       in_enum_type;
	bool       collect_delayed_decls;
	bool       allow_polymorphic_types;
	bool       no_polymorphic_errors;
	bool       in_polymorphic_specialization;
	Scope *    polymorphic_scope;
};

struct Checker {
	Parser *    parser;
	CheckerInfo info;

	Array<ProcInfo> procs_to_check;
	Array<Entity *> procs_with_deferred_to_check;

	CheckerContext *curr_ctx;
	gbAllocator    allocator;
	CheckerContext init_ctx;
};





gb_global AstPackage *builtin_pkg    = nullptr;
gb_global AstPackage *intrinsics_pkg = nullptr;


HashKey hash_node     (Ast *node)  { return hash_pointer(node); }
HashKey hash_ast_file (AstFile *file)  { return hash_pointer(file); }
HashKey hash_entity   (Entity *e)      { return hash_pointer(e); }
HashKey hash_type     (Type *t)        { return hash_pointer(t); }
HashKey hash_decl_info(DeclInfo *decl) { return hash_pointer(decl); }


// CheckerInfo API
TypeAndValue type_and_value_of_expr (Ast *expr);
Type *       type_of_expr           (Ast *expr);
Entity *     entity_of_ident        (Ast *identifier);
Entity *     implicit_entity_of_node(Ast *clause);
Scope *      scope_of_node          (Ast *node);
DeclInfo *   decl_info_of_ident     (Ast *ident);
DeclInfo *   decl_info_of_entity    (Entity * e);
AstFile *    ast_file_of_filename   (CheckerInfo *i, String   filename);
// IMPORTANT: Only to use once checking is done
isize        type_info_index        (CheckerInfo *i, Type *   type, bool error_on_failure = true);

// Will return nullptr if not found
Entity *entity_of_node(Ast *expr);


Entity *scope_lookup_current(Scope *s, String name);
Entity *scope_lookup (Scope *s, String name);
void    scope_lookup_parent (Scope *s, String name, Scope **scope_, Entity **entity_);
Entity *scope_insert (Scope *s, Entity *entity);


ExprInfo *check_get_expr_info     (CheckerInfo *i, Ast *expr);
void      check_set_expr_info     (CheckerInfo *i, Ast *expr, ExprInfo info);
void      check_remove_expr_info  (CheckerInfo *i, Ast *expr);
void      add_untyped             (CheckerInfo *i, Ast *expression, bool lhs, AddressingMode mode, Type *basic_type, ExactValue value);
void      add_type_and_value      (CheckerInfo *i, Ast *expression, AddressingMode mode, Type *type, ExactValue value);
void      add_entity_use          (CheckerContext *c, Ast *identifier, Entity *entity);
void      add_implicit_entity     (CheckerContext *c, Ast *node, Entity *e);
void      add_entity_and_decl_info(CheckerContext *c, Ast *identifier, Entity *e, DeclInfo *d);
void      add_type_info_type      (CheckerContext *c, Type *t);

void check_add_import_decl(CheckerContext *c, Ast *decl);
void check_add_foreign_import_decl(CheckerContext *c, Ast *decl);


bool check_arity_match(CheckerContext *c, AstValueDecl *vd, bool is_global = false);
void check_collect_entities(CheckerContext *c, Array<Ast *> const &nodes);
void check_collect_entities_from_when_stmt(CheckerContext *c, AstWhenStmt *ws);
void check_delayed_file_import_entity(CheckerContext *c, Ast *decl);

CheckerTypePath *new_checker_type_path();
void destroy_checker_type_path(CheckerTypePath *tp);

void    check_type_path_push(CheckerContext *c, Entity *e);
Entity *check_type_path_pop (CheckerContext *c);

CheckerPolyPath *new_checker_poly_path();
void destroy_checker_poly_path(CheckerPolyPath *);

void  check_poly_path_push(CheckerContext *c, Type *t);
Type *check_poly_path_pop (CheckerContext *c);
