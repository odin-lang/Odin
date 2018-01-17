// checker.hpp

struct Type;
struct Entity;
struct Scope;
struct DeclInfo;
struct AstFile;

enum AddressingMode {
	Addressing_Invalid,       // invalid addressing mode
	Addressing_NoValue,       // no value (void in C)
	Addressing_Value,         // computed value (rvalue)
	Addressing_Immutable,     // immutable computed value (const rvalue)
	Addressing_Variable,      // addressable variable (lvalue)
	Addressing_Constant,      // constant
	Addressing_Type,          // type
	Addressing_Builtin,       // built-in procedure
	Addressing_ProcGroup,     // procedure group (overloaded procedure)
	Addressing_MapIndex,      // map index expression -
	                          // 	lhs: acts like a Variable
	                          // 	rhs: acts like OptionalOk
	Addressing_OptionalOk,    // rhs: acts like a value with an optional boolean part (for existence check)
};

struct TypeAndValue {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
};


// ExprInfo stores information used for "untyped" expressions
struct ExprInfo {
	bool           is_lhs; // Debug info
	AddressingMode mode;
	Type *         type; // Type_Basic
	ExactValue     value;
};

gb_inline ExprInfo make_expr_info(bool is_lhs, AddressingMode mode, Type *type, ExactValue value) {
	ExprInfo ei = {is_lhs, mode, type, value};
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

struct BuiltinProc {
	String   name;
	isize    arg_count;
	bool     variadic;
	ExprKind kind;
};
enum BuiltinProcId {
	BuiltinProc_Invalid,

	BuiltinProc_len,
	BuiltinProc_cap,

	// BuiltinProc_new,
	BuiltinProc_make,
	// BuiltinProc_free,

	// BuiltinProc_reserve,
	// BuiltinProc_clear,
	// BuiltinProc_append,
	// BuiltinProc_delete,

	BuiltinProc_size_of,
	BuiltinProc_align_of,
	BuiltinProc_offset_of,
	BuiltinProc_type_of,
	BuiltinProc_type_info_of,

	BuiltinProc_compile_assert,

	BuiltinProc_swizzle,

	BuiltinProc_complex,
	BuiltinProc_real,
	BuiltinProc_imag,
	BuiltinProc_conj,

	// BuiltinProc_slice_ptr,
	// BuiltinProc_slice_to_bytes,

	BuiltinProc_expand_to_tuple,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,
	BuiltinProc_clamp,

	BuiltinProc_DIRECTIVE, // NOTE(bill): This is used for specialized hash-prefixed procedures

	BuiltinProc_COUNT,
};
gb_global BuiltinProc builtin_procs[BuiltinProc_COUNT] = {
	{STR_LIT(""),                 0, false, Expr_Stmt},

	{STR_LIT("len"),              1, false, Expr_Expr},
	{STR_LIT("cap"),              1, false, Expr_Expr},

	// {STR_LIT("new"),              1, false, Expr_Expr},
	{STR_LIT("make"),             1, true,  Expr_Expr},
	// {STR_LIT("free"),             1, false, Expr_Stmt},

	// {STR_LIT("reserve"),          2, false, Expr_Stmt},
	// {STR_LIT("clear"),            1, false, Expr_Stmt},
	// {STR_LIT("append"),           1, true,  Expr_Expr},
	// {STR_LIT("delete"),           2, false, Expr_Stmt},

	{STR_LIT("size_of"),          1, false, Expr_Expr},
	{STR_LIT("align_of"),         1, false, Expr_Expr},
	{STR_LIT("offset_of"),        2, false, Expr_Expr},
	{STR_LIT("type_of"),          1, false, Expr_Expr},
	{STR_LIT("type_info_of"),     1, false, Expr_Expr},

	{STR_LIT("compile_assert"),   1, false, Expr_Expr},

	{STR_LIT("swizzle"),          1, true,  Expr_Expr},

	{STR_LIT("complex"),          2, false, Expr_Expr},
	{STR_LIT("real"),             1, false, Expr_Expr},
	{STR_LIT("imag"),             1, false, Expr_Expr},
	{STR_LIT("conj"),             1, false, Expr_Expr},

	// {STR_LIT("slice_ptr"),        2, true,  Expr_Expr},
	// {STR_LIT("slice_to_bytes"),   1, false, Expr_Expr},

	{STR_LIT("expand_to_tuple"),  1, false, Expr_Expr},

	{STR_LIT("min"),              2, false, Expr_Expr},
	{STR_LIT("max"),              2, false, Expr_Expr},
	{STR_LIT("abs"),              1, false, Expr_Expr},
	{STR_LIT("clamp"),            3, false, Expr_Expr},

	{STR_LIT(""),                 0, true,  Expr_Expr}, // DIRECTIVE
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
	AstNode *      expr;
	BuiltinProcId  builtin_id;
	Entity *       proc_group;
};


struct BlockLabel {
	String   name;
	AstNode *label; //  AstNode_Label;
};

// DeclInfo is used to store information of certain declarations to allow for "any order" usage
struct DeclInfo {
	DeclInfo *        parent; // NOTE(bill): only used for procedure literals at the moment
	Scope *           scope;

	Entity **         entities;
	isize             entity_count;

	AstNode *         type_expr;
	AstNode *         init_expr;
	Array<AstNode *>  init_expr_list;
	Array<AstNode *>  attributes;
	AstNode *         proc_lit;      // AstNode_ProcLit
	Type *            gen_proc_type; // Precalculated

	PtrSet<Entity *>  deps;
	Array<BlockLabel> labels;
};

// ProcedureInfo stores the information needed for checking a procedure


struct ProcedureInfo {
	AstFile *             file;
	Token                 token;
	DeclInfo *            decl;
	Type *                type; // Type_Procedure
	AstNode *             body; // AstNode_BlockStmt
	u64                   tags;
	bool                  generated_from_polymorphic;
};


struct Scope {
	AstNode *        node;
	Scope *          parent;
	Scope *          prev, *next;
	Scope *          first_child;
	Scope *          last_child;
	Map<Entity *>    elements; // Key: String
	PtrSet<Entity *> implicit;

	Array<Scope *>   shared;
	Array<AstNode *> delayed_file_decls;
	PtrSet<Scope *>  imported;
	PtrSet<Scope *>  exported; // NOTE(bhall): Contains 'using import' too
	bool             is_proc;
	bool             is_global;
	bool             is_file;
	bool             is_init;
	bool             is_struct;
	bool             has_been_imported; // This is only applicable to file scopes
	AstFile *        file;
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
	Scope *            scope;
	String             path;
	isize              file_id;
	ImportGraphNodeSet pred;
	ImportGraphNodeSet succ;
	isize              index; // Index in array/queue
	isize              dep_count;
};


struct ForeignContext {
	AstNode *             curr_library;
	ProcCallingConvention default_cc;
	String                link_prefix;
	bool                  in_export;
};

struct CheckerContext {
	Scope *    file_scope;
	Scope *    scope;
	DeclInfo * decl;
	u32        stmt_state_flags;
	bool       in_defer; // TODO(bill): Actually handle correctly
	String     proc_name;
	Type *     type_hint;
	DeclInfo * curr_proc_decl;
	ForeignContext foreign_context;

	bool       collect_delayed_decls;
	bool       allow_polymorphic_types;
	bool       no_polymorphic_errors;
	Scope *    polymorphic_scope;
};


// CheckerInfo stores all the symbol information for a type-checked program
struct CheckerInfo {
	Map<TypeAndValue>     types;           // Key: AstNode * | Expression -> Type (and value)
	Map<ExprInfo>         untyped;         // Key: AstNode * | Expression -> ExprInfo
	Map<AstFile *>        files;           // Key: String (full path)
	Map<Entity *>         foreigns;        // Key: String
	Array<Entity *>       definitions;
	Array<Entity *>       entities;
	Array<DeclInfo *>     variable_init_order;

	Map<Array<Entity *> > gen_procs;       // Key: AstNode * | Identifier -> Entity
	Map<Array<Entity *> > gen_types;       // Key: Type *

	Map<isize>            type_info_map;   // Key: Type *
	isize                 type_info_count;

	Scope *               init_scope;
	Entity *              entry_point;
	PtrSet<Entity *>      minimum_dependency_set;
};

struct Checker {
	Parser *    parser;
	CheckerInfo info;
	gbMutex     mutex;

	AstFile *                  curr_ast_file;
	Scope *                    global_scope;
	// NOTE(bill): Procedures to check
	Array<ProcedureInfo>       procs;
	Map<Scope *>               file_scopes; // Key: String (fullpath)
	Array<ImportGraphNode *>   file_order;

	gbAllocator                allocator;
	gbArena                    arena;
	gbArena                    tmp_arena;
	gbAllocator                tmp_allocator;

	CheckerContext             context;

	Array<Type *>              proc_stack;
	bool                       done_preload;

	PtrSet<AstFile *>          checked_files;

};



HashKey hash_node     (AstNode *node)  { return hash_pointer(node); }
HashKey hash_ast_file (AstFile *file)  { return hash_pointer(file); }
HashKey hash_entity   (Entity *e)      { return hash_pointer(e); }
HashKey hash_type     (Type *t)        { return hash_pointer(t); }
HashKey hash_decl_info(DeclInfo *decl) { return hash_pointer(decl); }



// CheckerInfo API
TypeAndValue type_and_value_of_expr (CheckerInfo *i, AstNode *expr);
Type *       type_of_expr           (CheckerInfo *i, AstNode *expr);
Entity *     entity_of_ident        (CheckerInfo *i, AstNode *identifier);
Entity *     implicit_entity_of_node(CheckerInfo *i, AstNode *clause);
Scope *      scope_of_node          (CheckerInfo *i, AstNode *node);
DeclInfo *   decl_info_of_ident     (CheckerInfo *i, AstNode *ident);
DeclInfo *   decl_info_of_entity    (CheckerInfo *i, Entity * e);
AstFile *    ast_file_of_filename   (CheckerInfo *i, String   filename);
// IMPORTANT: Only to use once checking is done
isize        type_info_index        (CheckerInfo *i, Type *   type, bool error_on_failure = true);


Entity *current_scope_lookup_entity(Scope *s, String name);
Entity *scope_lookup_entity        (Scope *s, String name);
void    scope_lookup_parent_entity (Scope *s, String name, Scope **scope_, Entity **entity_);
Entity *scope_insert_entity        (Scope *s, Entity *entity);


ExprInfo *check_get_expr_info     (CheckerInfo *i, AstNode *expr);
void      check_set_expr_info     (CheckerInfo *i, AstNode *expr, ExprInfo info);
void      check_remove_expr_info  (CheckerInfo *i, AstNode *expr);
void      add_untyped             (CheckerInfo *i, AstNode *expression, bool lhs, AddressingMode mode, Type *basic_type, ExactValue value);
void      add_type_and_value      (CheckerInfo *i, AstNode *expression, AddressingMode mode, Type *type, ExactValue value);
void      add_entity_use          (Checker *c, AstNode *identifier, Entity *entity);
void      add_implicit_entity     (Checker *c, AstNode *node, Entity *e);
void      add_entity_and_decl_info(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d);

void check_add_import_decl(Checker *c, AstNodeImportDecl *id);
void check_add_export_decl(Checker *c, AstNodeExportDecl *ed);
void check_add_foreign_import_decl(Checker *c, AstNode *decl);



bool check_arity_match(Checker *c, AstNodeValueDecl *vd, bool is_global = false);
void check_collect_entities(Checker *c, Array<AstNode *> nodes);
void check_collect_entities_from_when_stmt(Checker *c, AstNodeWhenStmt *ws);
void check_delayed_file_import_entity(Checker *c, AstNode *decl);


struct AttributeContext {
	String  link_name;
	String  link_prefix;
	isize   init_expr_list_count;
	String  thread_local_model;
};

AttributeContext make_attribute_context(String link_prefix) {
	AttributeContext ac = {};
	ac.link_prefix = link_prefix;
	return ac;
}

#define DECL_ATTRIBUTE_PROC(_name) bool _name(Checker *c, AstNode *elem, String name, ExactValue value, AttributeContext *ac)
typedef DECL_ATTRIBUTE_PROC(DeclAttributeProc);

void check_decl_attributes(Checker *c, Array<AstNode *> attributes, DeclAttributeProc *proc, AttributeContext *ac);
