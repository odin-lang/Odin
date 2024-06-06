// checker.hpp

struct Type;
struct Entity;
struct Scope;
struct DeclInfo;
struct AstFile;
struct Checker;
struct CheckerInfo;
struct CheckerContext;

enum AddressingMode : u8;
struct TypeAndValue;

// ExprInfo stores information used for "untyped" expressions
struct ExprInfo {
	AddressingMode mode;
	bool is_lhs; // Debug info
	Type *         type;
	ExactValue     value;
};

gb_internal gb_inline ExprInfo *make_expr_info(AddressingMode mode, Type *type, ExactValue const &value, bool is_lhs) {
	ExprInfo *ei = gb_alloc_item(permanent_allocator(), ExprInfo);
	ei->mode   = mode;
	ei->type   = type;
	ei->value  = value;
	ei->is_lhs = is_lhs;
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

	Stmt_TypeSwitch = 1<<4,

	Stmt_CheckScopeDecls = 1<<5,
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
	bool diverging;
	bool ignore_results; // ignores require results handling
};


#include "checker_builtin_procs.hpp"


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
	DeferredProcedure_in_out,

	DeferredProcedure_in_by_ptr,
	DeferredProcedure_out_by_ptr,
	DeferredProcedure_in_out_by_ptr,
};
struct DeferredProcedure {
	DeferredProcedureKind kind;
	Entity *entity;
};


enum InstrumentationFlag : i32 {
	Instrumentation_Enabled  = -1,
	Instrumentation_Default  = 0,
	Instrumentation_Disabled = +1,
};

struct AttributeContext {
	String  link_name;
	String  link_prefix;
	String  link_suffix;
	String  link_section;
	String  linkage;
	isize   init_expr_list_count;
	String  thread_local_model;
	String  deprecated_message;
	String  warning_message;
	DeferredProcedure deferred_procedure;
	bool    is_export             : 1;
	bool    is_static             : 1;
	bool    require_results       : 1;
	bool    require_declaration   : 1;
	bool    has_disabled_proc     : 1;
	bool    disabled_proc         : 1;
	bool    test                  : 1;
	bool    init                  : 1;
	bool    fini                  : 1;
	bool    set_cold              : 1;
	bool    entry_point_only      : 1;
	bool    instrumentation_enter : 1;
	bool    instrumentation_exit  : 1;
	bool    rodata                : 1;
	u32 optimization_mode; // ProcedureOptimizationMode
	i64 foreign_import_priority_index;
	String extra_linker_flags;
	InstrumentationFlag no_instrumentation;

	String  objc_class;
	String  objc_name;
	bool    objc_is_class_method;
	Type *  objc_type;

	String require_target_feature; // required by the target micro-architecture
	String enable_target_feature;  // will be enabled for the procedure only
};

gb_internal gb_inline AttributeContext make_attribute_context(String link_prefix, String link_suffix) {
	AttributeContext ac = {};
	ac.link_prefix = link_prefix;
	ac.link_suffix = link_suffix;
	return ac;
}

#define DECL_ATTRIBUTE_PROC(_name) bool _name(CheckerContext *c, Ast *elem, String name, Ast *value, AttributeContext *ac)
typedef DECL_ATTRIBUTE_PROC(DeclAttributeProc);

gb_internal void check_decl_attributes(CheckerContext *c, Array<Ast *> const &attributes, DeclAttributeProc *proc, AttributeContext *ac);


enum ProcCheckedState : u8 {
	ProcCheckedState_Unchecked,
	ProcCheckedState_InProgress,
	ProcCheckedState_Checked,

	ProcCheckedState_COUNT
};

char const *ProcCheckedState_strings[ProcCheckedState_COUNT] {
	"Unchecked",
	"In Progress",
	"Checked",
};

// DeclInfo is used to store information of certain declarations to allow for "any order" usage
struct DeclInfo {
	DeclInfo *    parent; // NOTE(bill): only used for procedure literals at the moment

	BlockingMutex next_mutex;
	DeclInfo *    next_child;
	DeclInfo *    next_sibling;

	Scope *       scope;

	Entity *entity;

	Ast *         decl_node;
	Ast *         type_expr;
	Ast *         init_expr;
	Array<Ast *>  attributes;
	Ast *         proc_lit;      // Ast_ProcLit
	Type *        gen_proc_type; // Precalculated
	bool          is_using;
	bool          where_clauses_evaluated;
	std::atomic<ProcCheckedState> proc_checked_state;
	BlockingMutex proc_checked_mutex;
	isize         defer_used;
	bool          defer_use_checked;

	CommentGroup *comment;
	CommentGroup *docs;

	RwMutex          deps_mutex;
	PtrSet<Entity *> deps;

	RwMutex     type_info_deps_mutex;
	PtrSet<Type *>    type_info_deps;

	BlockingMutex type_and_value_mutex;

	Array<BlockLabel> labels;

	// NOTE(bill): this is to prevent a race condition since these procedure literals can be created anywhere at any time
	struct lbModule *code_gen_module;
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



enum ScopeFlag : i32 {
	ScopeFlag_Pkg     = 1<<1,
	ScopeFlag_Builtin = 1<<2,
	ScopeFlag_Global  = 1<<3,
	ScopeFlag_File    = 1<<4,
	ScopeFlag_Init    = 1<<5,
	ScopeFlag_Proc    = 1<<6,
	ScopeFlag_Type    = 1<<7,

	ScopeFlag_HasBeenImported = 1<<10, // This is only applicable to file scopes

	ScopeFlag_ContextDefined = 1<<16,
};

enum { DEFAULT_SCOPE_CAPACITY = 32 };

struct Scope {
	Ast *         node;
	Scope *       parent;
	std::atomic<Scope *> next;
	std::atomic<Scope *> head_child;

	RwMutex mutex;
	StringMap<Entity *> elements;
	PtrSet<Scope *> imported;

	i32             flags; // ScopeFlag
	union {
		AstPackage *pkg;
		AstFile *   file;
		Entity *    procedure_entity;
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

enum EntityVisiblityKind {
	EntityVisiblity_Public,
	EntityVisiblity_PrivateToPackage,
	EntityVisiblity_PrivateToFile,
};


struct ForeignContext {
	Ast *                 curr_library;
	ProcCallingConvention default_cc;
	String                link_prefix;
	String                link_suffix;
	EntityVisiblityKind   visibility_kind;
};

typedef Array<Entity *> CheckerTypePath;
typedef Array<Type *>   CheckerPolyPath;

struct AtomOpMapEntry {
	u32  kind;
	Ast *node;
};


struct CheckerContext;

struct UntypedExprInfo {
	Ast *expr;
	ExprInfo *info;
};

typedef PtrMap<Ast *, ExprInfo *> UntypedExprInfoMap; 

enum ObjcMsgKind : u32 {
	ObjcMsg_normal,
	ObjcMsg_fpret,
	ObjcMsg_fp2ret,
	ObjcMsg_stret,
};
struct ObjcMsgData {
	ObjcMsgKind kind;
	Type *proc_type;
};

enum LoadFileTier {
	LoadFileTier_Invalid,
	LoadFileTier_Exists,
	LoadFileTier_Contents,
};

struct LoadFileCache {
	LoadFileTier   tier;
	bool           exists;
	String         path;
	gbFileError    file_error;
	String         data;
	StringMap<u64> hashes;
};


struct LoadDirectoryFile {
	String file_name;
	String data;
};

struct LoadDirectoryCache {
	String                 path;
	gbFileError            file_error;
	Array<LoadFileCache *> files;
};


struct GenProcsData {
	Array<Entity *> procs;
	RwMutex         mutex;
};

struct GenTypesData {
	Array<Entity *> types;
	RecursiveMutex  mutex;
};

// CheckerInfo stores all the symbol information for a type-checked program
struct CheckerInfo {
	Checker *checker;

	StringMap<AstFile *>    files;    // Key (full path)
	StringMap<AstPackage *> packages; // Key (full path)
	Array<DeclInfo *>       variable_init_order;

	AstPackage *          builtin_package;
	AstPackage *          runtime_package;
	AstPackage *          init_package;
	Scope *               init_scope;
	Entity *              entry_point;
	PtrSet<Entity *>      minimum_dependency_set;
	PtrMap</*type info index*/isize, /*min dep index*/isize>  minimum_dependency_type_info_set;



	Array<Entity *> testing_procedures;
	Array<Entity *> init_procedures;
	Array<Entity *> fini_procedures;

	Array<Entity *> definitions;
	Array<Entity *> entities;
	Array<Entity *> required_foreign_imports_through_force;


	// Below are accessed within procedures
	RwMutex            global_untyped_mutex;
	UntypedExprInfoMap global_untyped; // NOTE(bill): This needs to be a map and not on the Ast
	                                   // as it needs to be iterated across afterwards
	BlockingMutex builtin_mutex;

	BlockingMutex type_and_value_mutex;

	RecursiveMutex lazy_mutex; // Mutex required for lazy type checking of specific files

	BlockingMutex                  gen_types_mutex;
	PtrMap<Type *, GenTypesData *> gen_types;

	BlockingMutex type_info_mutex; // NOT recursive
	Array<Type *> type_info_types;
	PtrMap<Type *, isize> type_info_map;

	BlockingMutex foreign_mutex; // NOT recursive
	StringMap<Entity *> foreigns;

	MPSCQueue<Entity *> definition_queue;
	MPSCQueue<Entity *> entity_queue;
	MPSCQueue<Entity *> required_global_variable_queue;
	MPSCQueue<Entity *> required_foreign_imports_through_force_queue;
	MPSCQueue<Entity *> foreign_imports_to_check_fullpaths;

	MPSCQueue<Ast *> intrinsics_entry_point_usage;

	BlockingMutex objc_types_mutex;
	PtrMap<Ast *, ObjcMsgData> objc_msgSend_types;

	BlockingMutex load_file_mutex;
	StringMap<LoadFileCache *> load_file_cache;

	BlockingMutex all_procedures_mutex;
	Array<ProcInfo *> all_procedures;

	BlockingMutex instrumentation_mutex;
	Entity *instrumentation_enter_entity;
	Entity *instrumentation_exit_entity;


	BlockingMutex                       load_directory_mutex;
	StringMap<LoadDirectoryCache *>     load_directory_cache;
	PtrMap<Ast *, LoadDirectoryCache *> load_directory_map; // Key: Ast_CallExpr *


};

struct CheckerContext {
	// Order matters here
	BlockingMutex  mutex;
	Checker *      checker;
	CheckerInfo *  info;

	AstPackage *   pkg;
	AstFile *      file;
	Scope *        scope;
	DeclInfo *     decl;

	// Order doesn't matter after this
	u32            state_flags;
	bool           in_defer;
	Type *         type_hint;
	Ast *          type_hint_expr;

	String         proc_name;
	DeclInfo *     curr_proc_decl;
	Type *         curr_proc_sig;
	ProcCallingConvention curr_proc_calling_convention;
	bool           in_proc_sig;
	ForeignContext foreign_context;

	CheckerTypePath *type_path;
	isize            type_level;

	UntypedExprInfoMap *untyped;

#define MAX_INLINE_FOR_DEPTH 1024ll
	i64 inline_for_depth;

	u32        stmt_flags;
	bool       in_enum_type;
	bool       collect_delayed_decls;
	bool       allow_polymorphic_types;
	bool       no_polymorphic_errors;
	bool       hide_polymorphic_errors;
	bool       in_polymorphic_specialization;
	bool       allow_arrow_right_selector_expr;
	u8         bit_field_bit_size;
	Scope *    polymorphic_scope;

	Ast *assignment_lhs_hint;
};

gb_internal u64 check_vet_flags(CheckerContext *c);
gb_internal u64 check_vet_flags(Ast *node);


struct Checker {
	Parser *    parser;
	CheckerInfo info;

	CheckerContext builtin_ctx;

	MPSCQueue<Entity *> procs_with_deferred_to_check;
	Array<ProcInfo *> procs_to_check;

	BlockingMutex nested_proc_lits_mutex;
	Array<DeclInfo *> nested_proc_lits;


	MPSCQueue<UntypedExprInfo> global_untyped_queue;
	MPSCQueue<Type *> soa_types_to_complete;
};



gb_global AstPackage *builtin_pkg    = nullptr;
gb_global AstPackage *intrinsics_pkg = nullptr;
gb_global AstPackage *config_pkg      = nullptr;


// CheckerInfo API
gb_internal TypeAndValue type_and_value_of_expr (Ast *expr);
gb_internal Type *       type_of_expr           (Ast *expr);
gb_internal Entity *     implicit_entity_of_node(Ast *clause);
gb_internal DeclInfo *   decl_info_of_ident     (Ast *ident);
gb_internal DeclInfo *   decl_info_of_entity    (Entity * e);
gb_internal AstFile *    ast_file_of_filename   (CheckerInfo *i, String   filename);
// IMPORTANT: Only to use once checking is done
gb_internal isize        type_info_index        (CheckerInfo *i, Type *type, bool error_on_failure);

// Will return nullptr if not found
gb_internal Entity *entity_of_node(Ast *expr);


gb_internal Entity *scope_lookup_current(Scope *s, String const &name);
gb_internal Entity *scope_lookup (Scope *s, String const &name);
gb_internal void    scope_lookup_parent (Scope *s, String const &name, Scope **scope_, Entity **entity_);
gb_internal Entity *scope_insert (Scope *s, Entity *entity);


gb_internal void      add_type_and_value      (CheckerContext *c, Ast *expression, AddressingMode mode, Type *type, ExactValue const &value);
gb_internal ExprInfo *check_get_expr_info     (CheckerContext *c, Ast *expr);
gb_internal void      add_untyped             (CheckerContext *c, Ast *expression, AddressingMode mode, Type *basic_type, ExactValue const &value);
gb_internal void      add_entity_use          (CheckerContext *c, Ast *identifier, Entity *entity);
gb_internal void      add_implicit_entity     (CheckerContext *c, Ast *node, Entity *e);
gb_internal void      add_entity_and_decl_info(CheckerContext *c, Ast *identifier, Entity *e, DeclInfo *d, bool is_exported=true);
gb_internal void      add_type_info_type      (CheckerContext *c, Type *t);

gb_internal void check_add_import_decl(CheckerContext *c, Ast *decl);
gb_internal void check_add_foreign_import_decl(CheckerContext *c, Ast *decl);


gb_internal void check_entity_decl(CheckerContext *c, Entity *e, DeclInfo *d, Type *named_type);
gb_internal void check_const_decl(CheckerContext *c, Entity *e, Ast *type_expr, Ast *init_expr, Type *named_type);
gb_internal void check_type_decl(CheckerContext *c, Entity *e, Ast *type_expr, Type *def);

gb_internal bool check_arity_match(CheckerContext *c, AstValueDecl *vd, bool is_global = false);
gb_internal void check_collect_entities(CheckerContext *c, Slice<Ast *> const &nodes);
gb_internal void check_collect_entities_from_when_stmt(CheckerContext *c, AstWhenStmt *ws);
gb_internal void check_delayed_file_import_entity(CheckerContext *c, Ast *decl);

gb_internal CheckerTypePath *new_checker_type_path();
gb_internal void destroy_checker_type_path(CheckerTypePath *tp);

gb_internal void    check_type_path_push(CheckerContext *c, Entity *e);
gb_internal Entity *check_type_path_pop (CheckerContext *c);

gb_internal void init_core_context(Checker *c);
gb_internal void init_mem_allocator(Checker *c);

gb_internal void add_untyped_expressions(CheckerInfo *cinfo, UntypedExprInfoMap *untyped);


gb_internal GenTypesData *ensure_polymorphic_record_entity_has_gen_types(CheckerContext *ctx, Type *original_type);


gb_internal void init_map_internal_types(Type *type);