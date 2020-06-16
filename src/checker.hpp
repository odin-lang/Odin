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

	Stmt_TypeSwitch = 1<<4,

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
};
struct DeferredProcedure {
	DeferredProcedureKind kind;
	Entity *entity;
};


struct AttributeContext {
	bool    is_export;
	bool    is_static;
	bool    require_results;
	bool    require_declaration;
	bool    has_disabled_proc;
	bool    disabled_proc;
	String  link_name;
	String  link_prefix;
	isize   init_expr_list_count;
	String  thread_local_model;
	String  deprecated_message;
	DeferredProcedure deferred_procedure;
	struct TypeAtomOpTable *atom_op_table;
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
	bool          where_clauses_evaluated;

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



enum ScopeFlag : i32 {
	ScopeFlag_Pkg    = 1<<1,
	ScopeFlag_Global = 1<<2,
	ScopeFlag_File   = 1<<3,
	ScopeFlag_Init   = 1<<4,
	ScopeFlag_Proc   = 1<<5,
	ScopeFlag_Type   = 1<<6,

	ScopeFlag_HasBeenImported = 1<<10, // This is only applicable to file scopes

	ScopeFlag_ContextDefined = 1<<16,
};

enum { DEFAULT_SCOPE_CAPACITY = 29 };

struct Scope {
	Ast *         node;
	Scope *       parent;
	Scope *       prev;
	Scope *       next;
	Scope *       first_child;
	Scope *       last_child;
	StringMap<Entity *> elements;

	Array<Ast *>    delayed_directives;
	Array<Ast *>    delayed_imports;
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
	EntityVisiblityKind   visibility_kind;
};

typedef Array<Entity *> CheckerTypePath;
typedef Array<Type *>   CheckerPolyPath;

struct AtomOpMapEntry {
	u32  kind;
	Ast *node;
};


// CheckerInfo stores all the symbol information for a type-checked program
struct CheckerInfo {
	Map<ExprInfo>         untyped; // Key: Ast * | Expression -> ExprInfo
	                               // NOTE(bill): This needs to be a map and not on the Ast
	                               // as it needs to be iterated across
	StringMap<AstFile *>    files;    // Key (full path)
	StringMap<AstPackage *> packages; // Key (full path)
	StringMap<Entity *>     foreigns;
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

	Array<Entity *>       required_foreign_imports_through_force;
	Array<Entity *>       required_global_variables;

	Map<AtomOpMapEntry>   atom_op_map; // Key: Ast *


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

	u32            state_flags;
	bool           in_defer; // TODO(bill): Actually handle correctly
	Type *         type_hint;

	String         proc_name;
	DeclInfo *     curr_proc_decl;
	Type *         curr_proc_sig;
	ProcCallingConvention curr_proc_calling_convention;
	bool           in_proc_sig;
	ForeignContext foreign_context;
	gbAllocator    allocator;

	CheckerTypePath *type_path;
	isize            type_level; // TODO(bill): Actually handle correctly
	CheckerPolyPath *poly_path;
	isize            poly_level; // TODO(bill): Actually handle correctly

#define MAX_INLINE_FOR_DEPTH 1024ll
	i64 inline_for_depth;

	bool       in_enum_type;
	bool       collect_delayed_decls;
	bool       allow_polymorphic_types;
	bool       no_polymorphic_errors;
	bool       hide_polymorphic_errors;
	bool       in_polymorphic_specialization;
	Scope *    polymorphic_scope;

	Ast *assignment_lhs_hint;
	Ast *unary_address_hint;
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
gb_global AstPackage *config_pkg      = nullptr;


HashKey hash_node     (Ast *node)  { return hash_pointer(node); }
HashKey hash_ast_file (AstFile *file)  { return hash_pointer(file); }
HashKey hash_entity   (Entity *e)      { return hash_pointer(e); }
HashKey hash_type     (Type *t)        { return hash_pointer(t); }
HashKey hash_decl_info(DeclInfo *decl) { return hash_pointer(decl); }


// CheckerInfo API
TypeAndValue type_and_value_of_expr (Ast *expr);
Type *       type_of_expr           (Ast *expr);
Entity *     implicit_entity_of_node(Ast *clause);
Scope *      scope_of_node          (Ast *node);
DeclInfo *   decl_info_of_ident     (Ast *ident);
DeclInfo *   decl_info_of_entity    (Entity * e);
AstFile *    ast_file_of_filename   (CheckerInfo *i, String   filename);
// IMPORTANT: Only to use once checking is done
isize        type_info_index        (CheckerInfo *i, Type *type, bool error_on_failure);

// Will return nullptr if not found
Entity *entity_of_node(Ast *expr);


Entity *scope_lookup_current(Scope *s, String const &name);
Entity *scope_lookup (Scope *s, String const &name);
void    scope_lookup_parent (Scope *s, String const &name, Scope **scope_, Entity **entity_);
Entity *scope_insert (Scope *s, Entity *entity);


ExprInfo *check_get_expr_info     (CheckerInfo *i, Ast *expr);
void      check_set_expr_info     (CheckerInfo *i, Ast *expr, ExprInfo info);
void      check_remove_expr_info  (CheckerInfo *i, Ast *expr);
void      add_untyped             (CheckerInfo *i, Ast *expression, bool lhs, AddressingMode mode, Type *basic_type, ExactValue value);
void      add_type_and_value      (CheckerInfo *i, Ast *expression, AddressingMode mode, Type *type, ExactValue value);
void      add_entity_use          (CheckerContext *c, Ast *identifier, Entity *entity);
void      add_implicit_entity     (CheckerContext *c, Ast *node, Entity *e);
void      add_entity_and_decl_info(CheckerContext *c, Ast *identifier, Entity *e, DeclInfo *d, bool is_exported=true);
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

void init_core_context(Checker *c);
