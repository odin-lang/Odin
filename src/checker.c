#include "exact_value.c"
#include "entity.c"

typedef enum ExprKind {
	Expr_Expr,
	Expr_Stmt,
} ExprKind;

// Statements and Declarations
typedef enum StmtFlag {
	Stmt_BreakAllowed       = 1<<0,
	Stmt_ContinueAllowed    = 1<<1,
	Stmt_FallthroughAllowed = 1<<2,

	Stmt_CheckScopeDecls    = 1<<5,
} StmtFlag;

typedef struct BuiltinProc {
	String   name;
	isize    arg_count;
	bool     variadic;
	ExprKind kind;
} BuiltinProc;
typedef enum BuiltinProcId {
	BuiltinProc_Invalid,

	BuiltinProc_len,
	BuiltinProc_cap,

	BuiltinProc_new,
	BuiltinProc_make,
	BuiltinProc_free,

	BuiltinProc_reserve,
	BuiltinProc_clear,
	BuiltinProc_append,
	BuiltinProc_delete,

	BuiltinProc_size_of,
	BuiltinProc_size_of_val,
	BuiltinProc_align_of,
	BuiltinProc_align_of_val,
	BuiltinProc_offset_of,
	BuiltinProc_offset_of_val,
	BuiltinProc_type_of_val,

	BuiltinProc_type_info,
	BuiltinProc_type_info_of_val,

	BuiltinProc_compile_assert,
	BuiltinProc_assert,
	BuiltinProc_panic,

	BuiltinProc_copy,

	BuiltinProc_swizzle,

	BuiltinProc_complex,
	BuiltinProc_quaternion,
	BuiltinProc_real,
	BuiltinProc_imag,
	BuiltinProc_jmag,
	BuiltinProc_kmag,
	BuiltinProc_conj,

	BuiltinProc_slice_ptr,
	BuiltinProc_slice_to_bytes,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,
	BuiltinProc_clamp,

	BuiltinProc_transmute,

	BuiltinProc_Count,
} BuiltinProcId;
gb_global BuiltinProc builtin_procs[BuiltinProc_Count] = {
	{STR_LIT(""),                 0, false, Expr_Stmt},

	{STR_LIT("len"),              1, false, Expr_Expr},
	{STR_LIT("cap"),              1, false, Expr_Expr},

	{STR_LIT("new"),              1, false, Expr_Expr},
	{STR_LIT("make"),             1, true,  Expr_Expr},
	{STR_LIT("free"),             1, false, Expr_Stmt},

	{STR_LIT("reserve"),          2, false, Expr_Stmt},
	{STR_LIT("clear"),            1, false, Expr_Stmt},
	{STR_LIT("append"),           1, true,  Expr_Expr},
	{STR_LIT("delete"),           2, false, Expr_Stmt},

	{STR_LIT("size_of"),          1, false, Expr_Expr},
	{STR_LIT("size_of_val"),      1, false, Expr_Expr},
	{STR_LIT("align_of"),         1, false, Expr_Expr},
	{STR_LIT("align_of_val"),     1, false, Expr_Expr},
	{STR_LIT("offset_of"),        2, false, Expr_Expr},
	{STR_LIT("offset_of_val"),    1, false, Expr_Expr},
	{STR_LIT("type_of_val"),      1, false, Expr_Expr},

	{STR_LIT("type_info"),        1, false, Expr_Expr},
	{STR_LIT("type_info_of_val"), 1, false, Expr_Expr},

	{STR_LIT("compile_assert"),   1, false, Expr_Expr},
	{STR_LIT("assert"),           1, false, Expr_Expr},
	{STR_LIT("panic"),            1, false, Expr_Stmt},

	{STR_LIT("copy"),             2, false, Expr_Expr},

	{STR_LIT("swizzle"),          1, true,  Expr_Expr},

	{STR_LIT("complex"),          2, false, Expr_Expr},
	{STR_LIT("quaternion"),       4, false, Expr_Expr},
	{STR_LIT("real"),             1, false, Expr_Expr},
	{STR_LIT("imag"),             1, false, Expr_Expr},
	{STR_LIT("jmag"),             1, false, Expr_Expr},
	{STR_LIT("kmag"),             1, false, Expr_Expr},
	{STR_LIT("conj"),             1, false, Expr_Expr},

	{STR_LIT("slice_ptr"),        2, true,   Expr_Expr},
	{STR_LIT("slice_to_bytes"),   1, false,  Expr_Stmt},

	{STR_LIT("min"),              2, false, Expr_Expr},
	{STR_LIT("max"),              2, false, Expr_Expr},
	{STR_LIT("abs"),              1, false, Expr_Expr},
	{STR_LIT("clamp"),            3, false, Expr_Expr},

	{STR_LIT("transmute"),        2, false, Expr_Expr},
};


#include "types.c"

typedef enum AddressingMode {
	Addressing_Invalid,    // invalid addressing mode
	Addressing_NoValue,    // no value (void in C)
	Addressing_Value,      // computed value (rvalue)
	Addressing_Immutable,  // immutable computed value (const rvalue)
	Addressing_Variable,   // addressable variable (lvalue)
	Addressing_Constant,   // constant
	Addressing_Type,       // type
	Addressing_Builtin,    // built-in procedure
	Addressing_Overload,   // overloaded procedure
	Addressing_MapIndex,   // map index expression -
	                       // 	lhs: acts like a Variable
	                       // 	rhs: acts like OptionalOk
	Addressing_OptionalOk, // rhs: acts like a value with an optional boolean part (for existence check)
} AddressingMode;

// Operand is used as an intermediate value whilst checking
// Operands store an addressing mode, the expression being evaluated,
// its type and node, and other specific information for certain
// addressing modes
// Its zero-value is a valid "invalid operand"
typedef struct Operand {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
	AstNode *      expr;
	BuiltinProcId  builtin_id;
	isize          overload_count;
	Entity **      overload_entities;
} Operand;

typedef struct TypeAndValue {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
} TypeAndValue;

bool is_operand_value(Operand o) {
	switch (o.mode) {
	case Addressing_Value:
	case Addressing_Variable:
	case Addressing_Immutable:
	case Addressing_Constant:
	case Addressing_MapIndex:
		return true;
	}
	return false;
}
bool is_operand_nil(Operand o) {
	return o.mode == Addressing_Value && o.type == t_untyped_nil;
}


typedef struct BlockLabel {
	String   name;
	AstNode *label; //  AstNode_Label;
} BlockLabel;

// DeclInfo is used to store information of certain declarations to allow for "any order" usage
typedef struct DeclInfo DeclInfo;
struct DeclInfo {
	DeclInfo *        parent; // NOTE(bill): only used for procedure literals at the moment
	Scope *           scope;

	Entity **         entities;
	isize             entity_count;

	AstNode *         type_expr;
	AstNode *         init_expr;
	AstNode *         proc_lit; // AstNode_ProcLit

	MapBool           deps; // Key: Entity *
	Array(BlockLabel) labels;
};

// ProcedureInfo stores the information needed for checking a procedure


typedef struct ProcedureInfo {
	AstFile *             file;
	Token                 token;
	DeclInfo *            decl;
	Type *                type; // Type_Procedure
	AstNode *             body; // AstNode_BlockStmt
	u32                   tags;
} ProcedureInfo;

// ExprInfo stores information used for "untyped" expressions
typedef struct ExprInfo {
	bool           is_lhs; // Debug info
	AddressingMode mode;
	Type *         type; // Type_Basic
	ExactValue     value;
} ExprInfo;

ExprInfo make_expr_info(bool is_lhs, AddressingMode mode, Type *type, ExactValue value) {
	ExprInfo ei = {is_lhs, mode, type, value};
	return ei;
}



#define MAP_TYPE Entity *
#define MAP_PROC map_entity_
#define MAP_NAME MapEntity
#include "map.c"

typedef struct Scope {
	Scope *          parent;
	Scope *          prev, *next;
	Scope *          first_child;
	Scope *          last_child;
	MapEntity        elements; // Key: String
	MapBool          implicit; // Key: Entity *

	Array(Scope *)   shared;
	Array(Scope *)   imported;
	bool             is_proc;
	bool             is_global;
	bool             is_file;
	bool             is_init;
	bool             has_been_imported; // This is only applicable to file scopes
	AstFile *        file;
} Scope;
gb_global Scope *universal_scope = NULL;





#define MAP_TYPE TypeAndValue
#define MAP_PROC map_tav_
#define MAP_NAME MapTypeAndValue
#include "map.c"

#define MAP_TYPE Scope *
#define MAP_PROC map_scope_
#define MAP_NAME MapScope
#include "map.c"

#define MAP_TYPE DeclInfo *
#define MAP_PROC map_decl_info_
#define MAP_NAME MapDeclInfo
#include "map.c"

#define MAP_TYPE AstFile *
#define MAP_PROC map_ast_file_
#define MAP_NAME MapAstFile
#include "map.c"

#define MAP_TYPE ExprInfo
#define MAP_PROC map_expr_info_
#define MAP_NAME MapExprInfo
#include "map.c"

typedef struct DelayedDecl {
	Scope *  parent;
	AstNode *decl;
} DelayedDecl;

typedef struct CheckerFileNode {
	i32       id;
	Array_i32 wheres;
	Array_i32 whats;
	i32       score; // Higher the score, the better
} CheckerFileNode;

typedef struct CheckerContext {
	Scope *    file_scope;
	Scope *    scope;
	DeclInfo * decl;
	u32        stmt_state_flags;
	bool       in_defer; // TODO(bill): Actually handle correctly
	String     proc_name;
	Type *     type_hint;
	DeclInfo * curr_proc_decl;
} CheckerContext;

// CheckerInfo stores all the symbol information for a type-checked program
typedef struct CheckerInfo {
	MapTypeAndValue      types;           // Key: AstNode * | Expression -> Type (and value)
	MapEntity            definitions;     // Key: AstNode * | Identifier -> Entity
	MapEntity            uses;            // Key: AstNode * | Identifier -> Entity
	MapScope             scopes;          // Key: AstNode * | Node       -> Scope
	MapExprInfo          untyped;         // Key: AstNode * | Expression -> ExprInfo
	MapDeclInfo          entities;        // Key: Entity *
	MapEntity            implicits;       // Key: AstNode *
	MapEntity            foreigns;        // Key: String
	MapAstFile           files;           // Key: String (full path)
	MapIsize             type_info_map;   // Key: Type *
	isize                type_info_count;
} CheckerInfo;

typedef struct Checker {
	Parser *    parser;
	CheckerInfo info;

	AstFile *              curr_ast_file;
	Scope *                global_scope;
	Array(ProcedureInfo)   procs; // NOTE(bill): Procedures to check
	Array(DelayedDecl)     delayed_imports;
	Array(DelayedDecl)     delayed_foreign_libraries;
	Array(CheckerFileNode) file_nodes;

	gbArena                arena;
	gbArena                tmp_arena;
	gbAllocator            allocator;
	gbAllocator            tmp_allocator;

	CheckerContext         context;

	Array(Type *)          proc_stack;
	bool                   done_preload;
} Checker;


typedef struct DelayedEntity {
	AstNode *   ident;
	Entity *    entity;
	DeclInfo *  decl;
} DelayedEntity;

typedef Array(DelayedEntity) DelayedEntities;




void init_declaration_info(DeclInfo *d, Scope *scope, DeclInfo *parent) {
	d->parent = parent;
	d->scope  = scope;
	map_bool_init(&d->deps, heap_allocator());
	array_init(&d->labels,  heap_allocator());
}

DeclInfo *make_declaration_info(gbAllocator a, Scope *scope, DeclInfo *parent) {
	DeclInfo *d = gb_alloc_item(a, DeclInfo);
	init_declaration_info(d, scope, parent);
	return d;
}

void destroy_declaration_info(DeclInfo *d) {
	map_bool_destroy(&d->deps);
}

bool decl_info_has_init(DeclInfo *d) {
	if (d->init_expr != NULL) {
		return true;
	}
	if (d->proc_lit != NULL) {
		switch (d->proc_lit->kind) {
		case_ast_node(pd, ProcLit, d->proc_lit);
			if (pd->body != NULL) {
				return true;
			}
		case_end;
		}
	}

	return false;
}





Scope *make_scope(Scope *parent, gbAllocator allocator) {
	Scope *s = gb_alloc_item(allocator, Scope);
	s->parent = parent;
	map_entity_init(&s->elements,   heap_allocator());
	map_bool_init(&s->implicit,     heap_allocator());
	array_init(&s->shared,          heap_allocator());
	array_init(&s->imported,        heap_allocator());

	if (parent != NULL && parent != universal_scope) {
		DLIST_APPEND(parent->first_child, parent->last_child, s);
	}
	return s;
}

void destroy_scope(Scope *scope) {
	for_array(i, scope->elements.entries) {
		Entity *e =scope->elements.entries.e[i].value;
		if (e->kind == Entity_Variable) {
			if (!(e->flags & EntityFlag_Used)) {
#if 0
				warning(e->token, "Unused variable `%.*s`", LIT(e->token.string));
#endif
			}
		}
	}

	for (Scope *child = scope->first_child; child != NULL; child = child->next) {
		destroy_scope(child);
	}

	map_entity_destroy(&scope->elements);
	map_bool_destroy(&scope->implicit);
	array_free(&scope->shared);
	array_free(&scope->imported);

	// NOTE(bill): No need to free scope as it "should" be allocated in an arena (except for the global scope)
}

void add_scope(Checker *c, AstNode *node, Scope *scope) {
	GB_ASSERT(node != NULL);
	GB_ASSERT(scope != NULL);
	map_scope_set(&c->info.scopes, hash_pointer(node), scope);
}


void check_open_scope(Checker *c, AstNode *node) {
	GB_ASSERT(node != NULL);
	node = unparen_expr(node);
	GB_ASSERT(node->kind == AstNode_Invalid ||
	          is_ast_node_stmt(node) ||
	          is_ast_node_type(node));
	Scope *scope = make_scope(c->context.scope, c->allocator);
	add_scope(c, node, scope);
	if (node->kind == AstNode_ProcType) {
		scope->is_proc = true;
	}
	c->context.scope = scope;
	c->context.stmt_state_flags |= StmtStateFlag_bounds_check;
}

void check_close_scope(Checker *c) {
	c->context.scope = c->context.scope->parent;
}


Entity *current_scope_lookup_entity(Scope *s, String name) {
	HashKey key = hash_string(name);
	Entity **found = map_entity_get(&s->elements, key);
	if (found) {
		return *found;
	}
	for_array(i, s->shared) {
		Scope *shared = s->shared.e[i];
		Entity **found = map_entity_get(&shared->elements, key);
		if (found) {
			Entity *e = *found;
			if (e->kind == Entity_Variable &&
			    !e->scope->is_file &&
			    !e->scope->is_global) {
				continue;
			}

			if (e->scope != shared) {
				// Do not return imported entities even #include ones
				continue;
			}

			return e;
		}
	}
	return NULL;
}

void scope_lookup_parent_entity(Scope *scope, String name, Scope **scope_, Entity **entity_) {
	bool gone_thru_proc = false;
	bool gone_thru_file = false;
	HashKey key = hash_string(name);
	for (Scope *s = scope; s != NULL; s = s->parent) {
		Entity **found = map_entity_get(&s->elements, key);
		if (found) {
			Entity *e = *found;
			if (gone_thru_proc) {
				// if (e->kind == Entity_Label) {
					// continue;
				// }
				// if (e->kind == Entity_Variable &&
				    // !e->scope->is_file &&
				    // !e->scope->is_global) {
					// continue;
				// }
			}

			if (entity_) *entity_ = e;
			if (scope_) *scope_ = s;
			return;
		}

		if (s->is_proc) {
			gone_thru_proc = true;
		} else {
			// Check shared scopes - i.e. other files @ global scope
			for_array(i, s->shared) {
				Scope *shared = s->shared.e[i];
				Entity **found = map_entity_get(&shared->elements, key);
				if (found) {
					Entity *e = *found;
					if (e->kind == Entity_Variable &&
					    !e->scope->is_file &&
					    !e->scope->is_global) {
						continue;
					}

					if (e->scope != shared) {
						// Do not return imported entities even #include ones
						continue;
					}

					if ((e->kind == Entity_ImportName ||
					     e->kind == Entity_LibraryName)
					     && gone_thru_file) {
						continue;
					}

					if (entity_) *entity_ = e;
					if (scope_) *scope_ = shared;
					return;
				}
			}
		}

		if (s->is_file) {
			gone_thru_file = true;
		}
	}


	if (entity_) *entity_ = NULL;
	if (scope_) *scope_ = NULL;
}

Entity *scope_lookup_entity(Scope *s, String name) {
	Entity *entity = NULL;
	scope_lookup_parent_entity(s, name, NULL, &entity);
	return entity;
}



Entity *scope_insert_entity(Scope *s, Entity *entity) {
	String name = entity->token.string;
	HashKey key = hash_string(name);
	Entity **found = map_entity_get(&s->elements, key);

#if 1
	// IMPORTANT NOTE(bill): Procedure overloading code
	Entity *prev = NULL;
	if (found) {
		prev = *found;
		if (prev->kind != Entity_Procedure ||
		    entity->kind != Entity_Procedure) {
			return prev;
		}
	}

	if (prev != NULL &&
	    entity->kind == Entity_Procedure) {
		if (s->is_global) {
			return prev;
		}
		map_entity_multi_insert(&s->elements, key, entity);
	} else {
		map_entity_set(&s->elements, key, entity);
	}
#else
	if (found) {
		return *found;
	}
	map_entity_set(&s->elements, key, entity);
#endif
	if (entity->scope == NULL) {
		entity->scope = s;
	}
	return NULL;
}


void check_scope_usage(Checker *c, Scope *scope) {
	// TODO(bill): Use this?
}


void add_dependency(DeclInfo *d, Entity *e) {
	map_bool_set(&d->deps, hash_pointer(e), cast(bool)true);
}

void add_declaration_dependency(Checker *c, Entity *e) {
	if (e == NULL) {
		return;
	}
	if (c->context.decl != NULL) {
		DeclInfo **found = map_decl_info_get(&c->info.entities, hash_pointer(e));
		if (found) {
			add_dependency(c->context.decl, e);
		}
	}
}


Entity *add_global_entity(Entity *entity) {
	String name = entity->token.string;
	if (gb_memchr(name.text, ' ', name.len)) {
		return entity; // NOTE(bill): `untyped thing`
	}
	if (scope_insert_entity(universal_scope, entity)) {
		compiler_error("double declaration");
	}
	return entity;
}

void add_global_constant(gbAllocator a, String name, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(a, Entity_Constant, NULL, make_token_ident(name), type);
	entity->Constant.value = value;
	add_global_entity(entity);
}


void add_global_string_constant(gbAllocator a, String name, String value) {
	add_global_constant(a, name, t_untyped_string, exact_value_string(value));

}

Type *add_global_type_alias(gbAllocator a, String name, Type *t) {
	Entity *e = add_global_entity(make_entity_type_alias(a, NULL, make_token_ident(name), t));
	return e->type;
}


void init_universal_scope(void) {
	BuildContext *bc = &build_context;
	// NOTE(bill): No need to free these
	gbAllocator a = heap_allocator();
	universal_scope = make_scope(NULL, a);

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		add_global_entity(make_entity_type_name(a, NULL, make_token_ident(basic_types[i].Basic.name), &basic_types[i]));
	}
#if 1
	for (isize i = 0; i < gb_count_of(basic_type_aliases); i++) {
		add_global_entity(make_entity_type_name(a, NULL, make_token_ident(basic_type_aliases[i].Basic.name), &basic_type_aliases[i]));
	}
#else
	{
		t_byte = add_global_type_alias(a, str_lit("byte"), &basic_types[Basic_u8]);
		t_rune = add_global_type_alias(a, str_lit("rune"), &basic_types[Basic_i32]);
	}
#endif

// Constants
	add_global_constant(a, str_lit("true"),  t_untyped_bool, exact_value_bool(true));
	add_global_constant(a, str_lit("false"), t_untyped_bool, exact_value_bool(false));

	add_global_entity(make_entity_nil(a, str_lit("nil"), t_untyped_nil));
	add_global_entity(make_entity_library_name(a,  universal_scope,
	                                           make_token_ident(str_lit("__llvm_core")), t_invalid,
	                                           str_lit(""), str_lit("__llvm_core")));

	// TODO(bill): Set through flags in the compiler
	add_global_string_constant(a, str_lit("ODIN_OS"),      bc->ODIN_OS);
	add_global_string_constant(a, str_lit("ODIN_ARCH"),    bc->ODIN_ARCH);
	add_global_string_constant(a, str_lit("ODIN_ENDIAN"),  bc->ODIN_ENDIAN);
	add_global_string_constant(a, str_lit("ODIN_VENDOR"),  bc->ODIN_VENDOR);
	add_global_string_constant(a, str_lit("ODIN_VERSION"), bc->ODIN_VERSION);
	add_global_string_constant(a, str_lit("ODIN_ROOT"),    bc->ODIN_ROOT);


// Builtin Procedures
	for (isize i = 0; i < gb_count_of(builtin_procs); i++) {
		BuiltinProcId id = cast(BuiltinProcId)i;
		Entity *entity = alloc_entity(a, Entity_Builtin, NULL, make_token_ident(builtin_procs[i].name), t_invalid);
		entity->Builtin.id = id;
		add_global_entity(entity);
	}


	t_u8_ptr       = make_type_pointer(a, t_u8);
	t_int_ptr      = make_type_pointer(a, t_int);
	t_i64_ptr      = make_type_pointer(a, t_i64);
	t_f64_ptr      = make_type_pointer(a, t_f64);
	t_byte_slice   = make_type_slice(a, t_byte);
	t_string_slice = make_type_slice(a, t_string);
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = heap_allocator();
	map_tav_init(&i->types,            a);
	map_entity_init(&i->definitions,   a);
	map_entity_init(&i->uses,          a);
	map_scope_init(&i->scopes,         a);
	map_decl_info_init(&i->entities,   a);
	map_expr_info_init(&i->untyped,    a);
	map_entity_init(&i->foreigns,      a);
	map_entity_init(&i->implicits,     a);
	map_isize_init(&i->type_info_map,  a);
	map_ast_file_init(&i->files,       a);
	i->type_info_count = 0;

}

void destroy_checker_info(CheckerInfo *i) {
	map_tav_destroy(&i->types);
	map_entity_destroy(&i->definitions);
	map_entity_destroy(&i->uses);
	map_scope_destroy(&i->scopes);
	map_decl_info_destroy(&i->entities);
	map_expr_info_destroy(&i->untyped);
	map_entity_destroy(&i->foreigns);
	map_entity_destroy(&i->implicits);
	map_isize_destroy(&i->type_info_map);
	map_ast_file_destroy(&i->files);
}


void init_checker(Checker *c, Parser *parser, BuildContext *bc) {
	if (global_error_collector.count > 0) {
		gb_exit(1);
	}

	gbAllocator a = heap_allocator();

	c->parser = parser;
	init_checker_info(&c->info);

	array_init(&c->proc_stack, a);
	array_init(&c->procs, a);
	array_init(&c->delayed_imports, a);
	array_init(&c->delayed_foreign_libraries, a);
	array_init(&c->file_nodes, a);

	for_array(i, parser->files) {
		AstFile *file = &parser->files.e[i];
		CheckerFileNode node = {0};
		node.id = file->id;
		array_init(&node.whats,  a);
		array_init(&node.wheres, a);
		array_add(&c->file_nodes, node);
	}

	// NOTE(bill): Is this big enough or too small?
	isize item_size = gb_max3(gb_size_of(Entity), gb_size_of(Type), gb_size_of(Scope));
	isize total_token_count = 0;
	for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files.e[i];
		total_token_count += f->tokens.count;
	}
	isize arena_size = 2 * item_size * total_token_count;
	gb_arena_init_from_allocator(&c->arena, a, arena_size);
	gb_arena_init_from_allocator(&c->tmp_arena, a, arena_size);


	c->allocator     = gb_arena_allocator(&c->arena);
	c->tmp_allocator = gb_arena_allocator(&c->tmp_arena);

	c->global_scope = make_scope(universal_scope, c->allocator);
	c->context.scope = c->global_scope;
}

void destroy_checker(Checker *c) {
	destroy_checker_info(&c->info);
	destroy_scope(c->global_scope);
	array_free(&c->proc_stack);
	array_free(&c->procs);
	array_free(&c->delayed_imports);
	array_free(&c->delayed_foreign_libraries);
	array_free(&c->file_nodes);

	gb_arena_free(&c->arena);
}



Entity *entity_of_ident(CheckerInfo *i, AstNode *identifier) {
	if (identifier->kind == AstNode_Ident) {
		Entity **found = map_entity_get(&i->definitions, hash_pointer(identifier));
		if (found) {
			return *found;
		}
		found = map_entity_get(&i->uses, hash_pointer(identifier));
		if (found) {
			return *found;
		}
	}
	return NULL;
}


TypeAndValue type_and_value_of_expr(CheckerInfo *i, AstNode *expression) {
	TypeAndValue result = {0};
	TypeAndValue *found = map_tav_get(&i->types, hash_pointer(expression));
	if (found) result = *found;
	return result;
}


Type *type_of_expr(CheckerInfo *i, AstNode *expr) {
	TypeAndValue tav = type_and_value_of_expr(i, expr);
	if (tav.mode != Addressing_Invalid) {
		return tav.type;
	}
	if (expr->kind == AstNode_Ident) {
		Entity *entity = entity_of_ident(i, expr);
		if (entity) {
			return entity->type;
		}
	}

	return NULL;
}


void add_untyped(CheckerInfo *i, AstNode *expression, bool lhs, AddressingMode mode, Type *basic_type, ExactValue value) {
	map_expr_info_set(&i->untyped, hash_pointer(expression), make_expr_info(lhs, mode, basic_type, value));
}

void add_type_and_value(CheckerInfo *i, AstNode *expression, AddressingMode mode, Type *type, ExactValue value) {
	if (expression == NULL) {
		return;
	}
	if (mode == Addressing_Invalid) {
		return;
	}

	if (mode == Addressing_Constant) {
		if (is_type_constant_type(type)) {
			// if (value.kind == ExactValue_Invalid) {
				// TODO(bill): Is this correct?
				// return;
			// }
			if (!(type != t_invalid || is_type_constant_type(type))) {
				compiler_error("add_type_and_value - invalid type: %s", type_to_string(type));
			}
		}
	}

	TypeAndValue tv = {0};
	tv.type  = type;
	tv.value = value;
	tv.mode  = mode;
	map_tav_set(&i->types, hash_pointer(expression), tv);
}

void add_entity_definition(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	if (identifier->kind == AstNode_Ident) {
		if (str_eq(identifier->Ident.string, str_lit("_"))) {
			return;
		}
		HashKey key = hash_pointer(identifier);
		map_entity_set(&i->definitions, key, entity);
	} else {
		// NOTE(bill): Error should handled elsewhere
	}
}

bool add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	String name = entity->token.string;
	if (!str_eq(name, str_lit("_"))) {
		Entity *ie = scope_insert_entity(scope, entity);
		if (ie) {
			TokenPos pos = ie->token.pos;
			Entity *up = ie->using_parent;
			if (up != NULL) {
				if (token_pos_eq(pos, up->token.pos)) {
					// NOTE(bill): Error should have been handled already
					return false;
				}
				error(entity->token,
				      "Redeclaration of `%.*s` in this scope through `using`\n"
				      "\tat %.*s(%td:%td)",
				      LIT(name),
				      LIT(up->token.pos.file), up->token.pos.line, up->token.pos.column);
				return false;
			} else {
				if (token_pos_eq(pos, entity->token.pos)) {
					// NOTE(bill): Error should have been handled already
					return false;
				}
				error(entity->token,
				      "Redeclaration of `%.*s` in this scope\n"
				      "\tat %.*s(%td:%td)",
				      LIT(name),
				      LIT(pos.file), pos.line, pos.column);
				return false;
			}
		}
	}
	if (identifier != NULL) {
		add_entity_definition(&c->info, identifier, entity);
	}
	return true;
}

void add_entity_use(Checker *c, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	if (identifier->kind != AstNode_Ident) {
		return;
	}
	HashKey key = hash_pointer(identifier);
	map_entity_set(&c->info.uses, key, entity);
	add_declaration_dependency(c, entity); // TODO(bill): Should this be here?
}


void add_entity_and_decl_info(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(identifier->kind == AstNode_Ident);
	GB_ASSERT(e != NULL && d != NULL);
	GB_ASSERT(str_eq(identifier->Ident.string, e->token.string));
	add_entity(c, e->scope, identifier, e);
	map_decl_info_set(&c->info.entities, hash_pointer(e), d);
}


void add_implicit_entity(Checker *c, AstNode *node, Entity *e) {
	GB_ASSERT(node != NULL);
	GB_ASSERT(e != NULL);
	map_entity_set(&c->info.implicits, hash_pointer(node), e);
}


void add_type_info_type(Checker *c, Type *t) {
	if (t == NULL) {
		return;
	}
	t = default_type(t);
	if (is_type_untyped(t)) {
		return; // Could be nil
	}

	if (map_isize_get(&c->info.type_info_map, hash_pointer(t)) != NULL) {
		// Types have already been added
		return;
	}

	isize ti_index = -1;
	for_array(i, c->info.type_info_map.entries) {
		MapIsizeEntry *e = &c->info.type_info_map.entries.e[i];
		Type *prev_type = cast(Type *)e->key.ptr;
		if (are_types_identical(t, prev_type)) {
			// Duplicate entry
			ti_index = e->value;
			break;
		}
	}
	if (ti_index < 0) {
		// Unique entry
		// NOTE(bill): map entries grow linearly and in order
		ti_index = c->info.type_info_count;
		c->info.type_info_count++;
	}
	map_isize_set(&c->info.type_info_map, hash_pointer(t), ti_index);




	// Add nested types

	if (t->kind == Type_Named) {
		// NOTE(bill): Just in case
		add_type_info_type(c, t->Named.base);
		return;
	}

	Type *bt = base_type(t);
	add_type_info_type(c, bt);

	switch (bt->kind) {
	case Type_Basic: {
		switch (bt->Basic.kind) {
		case Basic_string:
			add_type_info_type(c, t_u8_ptr);
			add_type_info_type(c, t_int);
			break;
		case Basic_any:
			add_type_info_type(c, t_type_info_ptr);
			add_type_info_type(c, t_rawptr);
			break;

		case Basic_complex64:
			add_type_info_type(c, t_type_info_float);
			add_type_info_type(c, t_f32);
			break;
		case Basic_complex128:
			add_type_info_type(c, t_type_info_float);
			add_type_info_type(c, t_f64);
			break;

		case Basic_quaternion128:
			add_type_info_type(c, t_type_info_float);
			add_type_info_type(c, t_f32);
			break;
		case Basic_quaternion256:
			add_type_info_type(c, t_type_info_float);
			add_type_info_type(c, t_f64);
			break;
		}
	} break;

	case Type_Pointer:
		add_type_info_type(c, bt->Pointer.elem);
		break;

	case Type_Atomic:
		add_type_info_type(c, bt->Atomic.elem);
		break;

	case Type_Array:
		add_type_info_type(c, bt->Array.elem);
		add_type_info_type(c, make_type_pointer(c->allocator, bt->Array.elem));
		add_type_info_type(c, t_int);
		break;
	case Type_DynamicArray:
		add_type_info_type(c, bt->DynamicArray.elem);
		add_type_info_type(c, make_type_pointer(c->allocator, bt->DynamicArray.elem));
		add_type_info_type(c, t_int);
		add_type_info_type(c, t_allocator);
		break;
	case Type_Slice:
		add_type_info_type(c, bt->Slice.elem);
		add_type_info_type(c, make_type_pointer(c->allocator, bt->Slice.elem));
		add_type_info_type(c, t_int);
		break;
	case Type_Vector:
		add_type_info_type(c, bt->Vector.elem);
		add_type_info_type(c, t_int);
		break;

	case Type_Record: {
		switch (bt->Record.kind) {
		case TypeRecord_Enum:
			add_type_info_type(c, bt->Record.enum_base_type);
			break;
		case TypeRecord_Union:
			add_type_info_type(c, t_int);
			for (isize i = 0; i < bt->Record.variant_count; i++) {
				Entity *f = bt->Record.variants[i];
				add_type_info_type(c, f->type);
			}
			/* fallthrough */
		default:
			for (isize i = 0; i < bt->Record.field_count; i++) {
				Entity *f = bt->Record.fields[i];
				add_type_info_type(c, f->type);
			}
			break;
		}
	} break;

	case Type_Map: {
		add_type_info_type(c, bt->Map.key);
		add_type_info_type(c, bt->Map.value);
		add_type_info_type(c, bt->Map.generated_struct_type);
	} break;

	case Type_Tuple:
		for (isize i = 0; i < bt->Tuple.variable_count; i++) {
			Entity *var = bt->Tuple.variables[i];
			add_type_info_type(c, var->type);
		}
		break;

	case Type_Proc:
		add_type_info_type(c, bt->Proc.params);
		add_type_info_type(c, bt->Proc.results);
		break;
	}
}


void check_procedure_later(Checker *c, AstFile *file, Token token, DeclInfo *decl, Type *type, AstNode *body, u32 tags) {
	ProcedureInfo info = {0};
	info.file = file;
	info.token = token;
	info.decl  = decl;
	info.type  = type;
	info.body  = body;
	info.tags  = tags;
	array_add(&c->procs, info);
}

void push_procedure(Checker *c, Type *type) {
	array_add(&c->proc_stack, type);
}

void pop_procedure(Checker *c) {
	array_pop(&c->proc_stack);
}

Type *const curr_procedure_type(Checker *c) {
	isize count = c->proc_stack.count;
	if (count > 0) {
		return c->proc_stack.e[count-1];
	}
	return NULL;
}

void add_curr_ast_file(Checker *c, AstFile *file) {
	if (file != NULL) {
		TokenPos zero_pos = {0};
		global_error_collector.prev = zero_pos;
		c->curr_ast_file = file;
		c->context.decl  = file->decl_info;
		c->context.scope = file->scope;
		c->context.file_scope = file->scope;
	}
}




void add_dependency_to_map(MapEntity *map, CheckerInfo *info, Entity *node) {
	if (node == NULL) {
		return;
	}
	if (map_entity_get(map, hash_pointer(node)) != NULL) {
		return;
	}
	map_entity_set(map, hash_pointer(node), node);


	DeclInfo **found = map_decl_info_get(&info->entities, hash_pointer(node));
	if (found == NULL) {
		return;
	}

	DeclInfo *decl = *found;
	for_array(i, decl->deps.entries) {
		Entity *e = cast(Entity *)decl->deps.entries.e[i].key.ptr;
		add_dependency_to_map(map, info, e);
	}
}

MapEntity generate_minimum_dependency_map(CheckerInfo *info, Entity *start) {
	MapEntity map = {0}; // Key: Entity *
	map_entity_init(&map, heap_allocator());

	for_array(i, info->definitions.entries) {
		Entity *e = info->definitions.entries.e[i].value;
		if (e->scope->is_global) {
			// NOTE(bill): Require runtime stuff
			add_dependency_to_map(&map, info, e);
		} else if (e->kind == Entity_Procedure) {
			if ((e->Procedure.tags & ProcTag_export) != 0) {
				add_dependency_to_map(&map, info, e);
			}
			if (e->Procedure.is_foreign) {
				add_dependency_to_map(&map, info, e->Procedure.foreign_library);
			}
		}
	}

	add_dependency_to_map(&map, info, start);

	return map;
}


Entity *find_core_entity(Checker *c, String name) {
	Entity *e = current_scope_lookup_entity(c->global_scope, name);
	if (e == NULL) {
		compiler_error("Could not find type declaration for `%.*s`\n"
		               "Is `_preload.odin` missing from the `core` directory relative to odin.exe?", LIT(name));
		// NOTE(bill): This will exit the program as it's cannot continue without it!
	}
	return e;
}

void init_preload(Checker *c) {
	if (c->done_preload) {
		return;
	}

	if (t_type_info == NULL) {
		Entity *type_info_entity = find_core_entity(c, str_lit("TypeInfo"));

		t_type_info = type_info_entity->type;
		t_type_info_ptr = make_type_pointer(c->allocator, t_type_info);
		GB_ASSERT(is_type_union(type_info_entity->type));
		TypeRecord *record = &base_type(type_info_entity->type)->Record;

		t_type_info_record = find_core_entity(c, str_lit("TypeInfoRecord"))->type;
		t_type_info_record_ptr = make_type_pointer(c->allocator, t_type_info_record);
		t_type_info_enum_value = find_core_entity(c, str_lit("TypeInfoEnumValue"))->type;
		t_type_info_enum_value_ptr = make_type_pointer(c->allocator, t_type_info_enum_value);



		if (record->variant_count != 22) {
			compiler_error("Invalid `TypeInfo` layout");
		}
		t_type_info_named         = record->variants[ 1]->type;
		t_type_info_integer       = record->variants[ 2]->type;
		t_type_info_float         = record->variants[ 3]->type;
		t_type_info_complex       = record->variants[ 4]->type;
		t_type_info_quaternion    = record->variants[ 5]->type;
		t_type_info_string        = record->variants[ 6]->type;
		t_type_info_boolean       = record->variants[ 7]->type;
		t_type_info_any           = record->variants[ 8]->type;
		t_type_info_pointer       = record->variants[ 9]->type;
		t_type_info_atomic        = record->variants[10]->type;
		t_type_info_procedure     = record->variants[11]->type;
		t_type_info_array         = record->variants[12]->type;
		t_type_info_dynamic_array = record->variants[13]->type;
		t_type_info_slice         = record->variants[14]->type;
		t_type_info_vector        = record->variants[15]->type;
		t_type_info_tuple         = record->variants[16]->type;
		t_type_info_struct        = record->variants[17]->type;
		t_type_info_raw_union     = record->variants[18]->type;
		t_type_info_union         = record->variants[19]->type;
		t_type_info_enum          = record->variants[20]->type;
		t_type_info_map           = record->variants[21]->type;

		t_type_info_named_ptr         = make_type_pointer(c->allocator, t_type_info_named);
		t_type_info_integer_ptr       = make_type_pointer(c->allocator, t_type_info_integer);
		t_type_info_float_ptr         = make_type_pointer(c->allocator, t_type_info_float);
		t_type_info_complex_ptr       = make_type_pointer(c->allocator, t_type_info_complex);
		t_type_info_quaternion_ptr    = make_type_pointer(c->allocator, t_type_info_quaternion);
		t_type_info_string_ptr        = make_type_pointer(c->allocator, t_type_info_string);
		t_type_info_boolean_ptr       = make_type_pointer(c->allocator, t_type_info_boolean);
		t_type_info_any_ptr           = make_type_pointer(c->allocator, t_type_info_any);
		t_type_info_pointer_ptr       = make_type_pointer(c->allocator, t_type_info_pointer);
		t_type_info_atomic_ptr        = make_type_pointer(c->allocator, t_type_info_atomic);
		t_type_info_procedure_ptr     = make_type_pointer(c->allocator, t_type_info_procedure);
		t_type_info_array_ptr         = make_type_pointer(c->allocator, t_type_info_array);
		t_type_info_dynamic_array_ptr = make_type_pointer(c->allocator, t_type_info_dynamic_array);
		t_type_info_slice_ptr         = make_type_pointer(c->allocator, t_type_info_slice);
		t_type_info_vector_ptr        = make_type_pointer(c->allocator, t_type_info_vector);
		t_type_info_tuple_ptr         = make_type_pointer(c->allocator, t_type_info_tuple);
		t_type_info_struct_ptr        = make_type_pointer(c->allocator, t_type_info_struct);
		t_type_info_raw_union_ptr     = make_type_pointer(c->allocator, t_type_info_raw_union);
		t_type_info_union_ptr         = make_type_pointer(c->allocator, t_type_info_union);
		t_type_info_enum_ptr          = make_type_pointer(c->allocator, t_type_info_enum);
		t_type_info_map_ptr           = make_type_pointer(c->allocator, t_type_info_map);
	}

	if (t_allocator == NULL) {
		Entity *e = find_core_entity(c, str_lit("Allocator"));
		t_allocator = e->type;
		t_allocator_ptr = make_type_pointer(c->allocator, t_allocator);
	}

	if (t_context == NULL) {
		Entity *e = find_core_entity(c, str_lit("Context"));
		e_context = e;
		t_context = e->type;
		t_context_ptr = make_type_pointer(c->allocator, t_context);
	}

	if (t_map_key == NULL) {
		Entity *e = find_core_entity(c, str_lit("__MapKey"));
		t_map_key = e->type;
	}

	if (t_map_header == NULL) {
		Entity *e = find_core_entity(c, str_lit("__MapHeader"));
		t_map_header = e->type;
	}

	c->done_preload = true;
}




bool check_arity_match(Checker *c, AstNodeValueDecl *d);
void check_collect_entities(Checker *c, AstNodeArray nodes, bool is_file_scope);
void check_collect_entities_from_when_stmt(Checker *c, AstNodeWhenStmt *ws, bool is_file_scope);

bool check_is_entity_overloaded(Entity *e) {
	if (e->kind != Entity_Procedure) {
		return false;
	}
	Scope *s = e->scope;
	HashKey key = hash_string(e->token.string);
	isize overload_count = map_entity_multi_count(&s->elements, key);
	return overload_count > 1;
}

void check_procedure_overloading(Checker *c, Entity *e) {
	GB_ASSERT(e->kind == Entity_Procedure);
	if (e->type == t_invalid) {
		return;
	}
	if (e->Procedure.overload_kind != Overload_Unknown) {
		// NOTE(bill): The overloading has already been handled
		return;
	}


	// NOTE(bill): Procedures call only overload other procedures in the same scope

	String name = e->token.string;
	HashKey key = hash_string(name);
	Scope *s = e->scope;
	isize overload_count = map_entity_multi_count(&s->elements, key);
	GB_ASSERT(overload_count >= 1);
	if (overload_count == 1) {
		e->Procedure.overload_kind = Overload_No;
		return;
	}
	GB_ASSERT(overload_count > 1);


	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	Entity **procs = gb_alloc_array(c->tmp_allocator, Entity *, overload_count);
	map_entity_multi_get_all(&s->elements, key, procs);

	for (isize j = 0; j < overload_count; j++) {
		Entity *p = procs[j];
		if (p->type == t_invalid) {
			// NOTE(bill): This invalid overload has already been handled
			continue;
		}

		String name = p->token.string;

		GB_ASSERT(p->kind == Entity_Procedure);
		for (isize k = j+1; k < overload_count; k++) {
			Entity *q = procs[k];
			GB_ASSERT(p != q);

			bool is_invalid = false;
			GB_ASSERT(q->kind == Entity_Procedure);

			TokenPos pos = q->token.pos;

			ProcTypeOverloadKind kind = are_proc_types_overload_safe(p->type, q->type);
			switch (kind) {
			case ProcOverload_Identical:
				error(p->token, "Overloaded procedure `%.*s` as the same type as another procedure in this scope", LIT(name));
				is_invalid = true;
				break;
			// case ProcOverload_CallingConvention:
				// error(p->token, "Overloaded procedure `%.*s` as the same type as another procedure in this scope", LIT(name));
				// is_invalid = true;
				// break;
			case ProcOverload_ParamVariadic:
				error(p->token, "Overloaded procedure `%.*s` as the same type as another procedure in this scope", LIT(name));
				is_invalid = true;
				break;
			case ProcOverload_ResultCount:
			case ProcOverload_ResultTypes:
				error(p->token, "Overloaded procedure `%.*s` as the same parameters but different results in this scope", LIT(name));
				is_invalid = true;
				break;
			case ProcOverload_ParamCount:
			case ProcOverload_ParamTypes:
				// This is okay :)
				break;

			}

			if (is_invalid) {
				gb_printf_err("\tprevious procedure at %.*s(%td:%td)\n", LIT(pos.file), pos.line, pos.column);
				q->type = t_invalid;
			}
		}
	}

	for (isize j = 0; j < overload_count; j++) {
		Entity *p = procs[j];
		if (p->type != t_invalid) {
			p->Procedure.overload_kind = Overload_Yes;
		}
	}

	gb_temp_arena_memory_end(tmp);
}


#include "check_expr.c"
#include "check_decl.c"
#include "check_stmt.c"




bool check_arity_match(Checker *c, AstNodeValueDecl *d) {
	isize lhs = d->names.count;
	isize rhs = d->values.count;

	if (rhs == 0) {
		if (d->type == NULL) {
			error_node(d->names.e[0], "Missing type or initial expression");
			return false;
		}
	} else if (lhs < rhs) {
		if (lhs < d->values.count) {
			AstNode *n = d->values.e[lhs];
			gbString str = expr_to_string(n);
			error_node(n, "Extra initial expression `%s`", str);
			gb_string_free(str);
		} else {
			error_node(d->names.e[0], "Extra initial expression");
		}
		return false;
	} else if (lhs > rhs && rhs != 1) {
		AstNode *n = d->names.e[rhs];
		gbString str = expr_to_string(n);
		error_node(n, "Missing expression for `%s`", str);
		gb_string_free(str);
		return false;
	}

	return true;
}

void check_collect_entities_from_when_stmt(Checker *c, AstNodeWhenStmt *ws, bool is_file_scope) {
	Operand operand = {Addressing_Invalid};
	check_expr(c, &operand, ws->cond);
	if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
		error_node(ws->cond, "Non-boolean condition in `when` statement");
	}
	if (operand.mode != Addressing_Constant) {
		error_node(ws->cond, "Non-constant condition in `when` statement");
	}
	if (ws->body == NULL || ws->body->kind != AstNode_BlockStmt) {
		error_node(ws->cond, "Invalid body for `when` statement");
	} else {
		if (operand.value.kind == ExactValue_Bool &&
		    operand.value.value_bool) {
			check_collect_entities(c, ws->body->BlockStmt.stmts, is_file_scope);
		} else if (ws->else_stmt) {
			switch (ws->else_stmt->kind) {
			case AstNode_BlockStmt:
				check_collect_entities(c, ws->else_stmt->BlockStmt.stmts, is_file_scope);
				break;
			case AstNode_WhenStmt:
				check_collect_entities_from_when_stmt(c, &ws->else_stmt->WhenStmt, is_file_scope);
				break;
			default:
				error_node(ws->else_stmt, "Invalid `else` statement in `when` statement");
				break;
			}
		}
	}
}

// NOTE(bill): If file_scopes == NULL, this will act like a local scope
void check_collect_entities(Checker *c, AstNodeArray nodes, bool is_file_scope) {
	// NOTE(bill): File scope and local scope are different kinds of scopes
	if (is_file_scope) {
		GB_ASSERT(c->context.scope->is_file);
	} else {
		GB_ASSERT(!c->context.scope->is_file);
	}

	for_array(decl_index, nodes) {
		AstNode *decl = nodes.e[decl_index];
		if (!is_ast_node_decl(decl) && !is_ast_node_when_stmt(decl)) {
			continue;
		}

		switch (decl->kind) {
		case_ast_node(bd, BadDecl, decl);
		case_end;

		case_ast_node(ws, WhenStmt, decl);
			if (c->context.scope->is_file) {
				error_node(decl, "`when` statements are not allowed at file scope");
			} else {
				// Will be handled later
			}
		case_end;

		case_ast_node(vd, ValueDecl, decl);
			if (vd->is_var) {
				if (!c->context.scope->is_file) {
					// NOTE(bill): local scope -> handle later and in order
					break;
				}
				// NOTE(bill): You need to store the entity information here unline a constant declaration
				isize entity_cap = vd->names.count;
				isize entity_count = 0;
				Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_cap);
				DeclInfo *di = NULL;
				if (vd->values.count > 0) {
					di = make_declaration_info(heap_allocator(), c->context.scope, c->context.decl);
					di->entities = entities;
					di->type_expr = vd->type;
					di->init_expr = vd->values.e[0];


					if (vd->flags & VarDeclFlag_thread_local) {
						error_node(decl, "#thread_local variable declarations cannot have initialization values");
					}
				}


				for_array(i, vd->names) {
					AstNode *name = vd->names.e[i];
					AstNode *value = NULL;
					if (i < vd->values.count) {
						value = vd->values.e[i];
					}
					if (name->kind != AstNode_Ident) {
						error_node(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
						continue;
					}
					Entity *e = make_entity_variable(c->allocator, c->context.scope, name->Ident, NULL, vd->flags & VarDeclFlag_immutable);
					e->Variable.is_thread_local = (vd->flags & VarDeclFlag_thread_local) != 0;
					e->identifier = name;

					if (vd->flags & VarDeclFlag_using) {
						vd->flags &= ~VarDeclFlag_using; // NOTE(bill): This error will be only caught once
						error_node(name, "`using` is not allowed at the file scope");
					}
					entities[entity_count++] = e;

					DeclInfo *d = di;
					if (d == NULL) {
						AstNode *init_expr = value;
						d = make_declaration_info(heap_allocator(), e->scope, c->context.decl);
						d->type_expr = vd->type;
						d->init_expr = init_expr;
					}

					add_entity_and_decl_info(c, name, e, d);
				}

				if (di != NULL) {
					di->entity_count = entity_count;
				}

				check_arity_match(c, vd);
			} else {
				for_array(i, vd->names) {
					AstNode *name = vd->names.e[i];
					if (name->kind != AstNode_Ident) {
						error_node(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
						continue;
					}

					AstNode *init = NULL;
					if (i < vd->values.count) {
						init = vd->values.e[i];
					}

					DeclInfo *d = make_declaration_info(c->allocator, c->context.scope, c->context.decl);
					Entity *e = NULL;

					AstNode *up_init = unparen_expr(init);
					if (up_init != NULL && is_ast_node_type(up_init)) {
						AstNode *type = up_init;
						e = make_entity_type_name(c->allocator, d->scope, name->Ident, NULL);
						// TODO(bill): What if vd->type != NULL??? How to handle this case?
						d->type_expr = type;
						d->init_expr = type;
					} else if (up_init != NULL && up_init->kind == AstNode_Alias) {
					#if 1
						error_node(up_init, "#alias declarations are not yet supported");
						continue;
					#else
						e = make_entity_alias(c->allocator, d->scope, name->Ident, NULL, EntityAlias_Invalid, NULL);
						d->type_expr = vd->type;
						d->init_expr = up_init->Alias.expr;
					#endif
					} else if (init != NULL && up_init->kind == AstNode_ProcLit) {
						e = make_entity_procedure(c->allocator, d->scope, name->Ident, NULL, up_init->ProcLit.tags);
						d->proc_lit = up_init;
						d->type_expr = vd->type;
					} else {
						e = make_entity_constant(c->allocator, d->scope, name->Ident, NULL, (ExactValue){0});
						d->type_expr = vd->type;
						d->init_expr = init;
					}
					GB_ASSERT(e != NULL);
					e->identifier = name;

					add_entity_and_decl_info(c, name, e, d);
				}

				check_arity_match(c, vd);
			}
		case_end;

		case_ast_node(id, ImportDecl, decl);
			if (!c->context.scope->is_file) {
				if (id->is_import) {
					error_node(decl, "#import declarations are only allowed in the file scope");
				} else {
					error_node(decl, "#load declarations are only allowed in the file scope");
				}
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}
			DelayedDecl di = {c->context.scope, decl};
			array_add(&c->delayed_imports, di);
		case_end;
		case_ast_node(fl, ForeignLibrary, decl);
			if (!c->context.scope->is_file) {
				if (fl->is_system) {
					error_node(decl, "#foreign_system_library declarations are only allowed in the file scope");
				} else {
					error_node(decl, "#foreign_library declarations are only allowed in the file scope");
				}
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}

			if (fl->cond != NULL) {
				Operand operand = {Addressing_Invalid};
				check_expr(c, &operand, fl->cond);
				if (operand.mode != Addressing_Constant || !is_type_boolean(operand.type)) {
					error_node(fl->cond, "Non-constant boolean `when` condition");
					continue;
				}
				if (operand.value.kind == ExactValue_Bool &&
					!operand.value.value_bool) {
					continue;
				}
			}

			DelayedDecl di = {c->context.scope, decl};
			array_add(&c->delayed_foreign_libraries, di);
		case_end;
		default:
			if (c->context.scope->is_file) {
				error_node(decl, "Only declarations are allowed at file scope");
			}
			break;
		}
	}

	if (!c->context.scope->is_file) {
		// NOTE(bill): `when` stmts need to be handled after the other as the condition may refer to something
		// declared after this stmt in source
		for_array(i, nodes) {
			AstNode *node = nodes.e[i];
			switch (node->kind) {
			case_ast_node(ws, WhenStmt, node);
				check_collect_entities_from_when_stmt(c, ws, is_file_scope);
			case_end;
			}
		}
	}
}


void check_all_global_entities(Checker *c) {
	Scope *prev_file = {0};

	for_array(i, c->info.entities.entries) {
		MapDeclInfoEntry *entry = &c->info.entities.entries.e[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
		DeclInfo *d = entry->value;

		if (d->scope != e->scope) {
			continue;
		}
		add_curr_ast_file(c, d->scope->file);

		if (!d->scope->has_been_imported) {
			// NOTE(bill): All of these unchecked entities could mean a lot of unused allocations
			// TODO(bill): Should this be worried about?
			continue;
		}

		if (e->kind != Entity_Procedure && str_eq(e->token.string, str_lit("main"))) {
			if (e->scope->is_init) {
				error(e->token, "`main` is reserved as the entry point procedure in the initial scope");
				continue;
			}
		} else if (e->scope->is_global && str_eq(e->token.string, str_lit("main"))) {
			error(e->token, "`main` is reserved as the entry point procedure in the initial scope");
			continue;
		}

		CheckerContext prev_context = c->context;
		c->context.decl = d;
		c->context.scope = d->scope;
		check_entity_decl(c, e, d, NULL);
		c->context = prev_context;


		if (d->scope->is_init && !c->done_preload) {
			init_preload(c);
		}
	}

	for_array(i, c->info.entities.entries) {
		MapDeclInfoEntry *entry = &c->info.entities.entries.e[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
		if (e->kind != Entity_Procedure) {
			continue;
		}
		check_procedure_overloading(c, e);
	}
}


bool is_string_an_identifier(String s) {
	isize offset = 0;
	if (s.len < 1) {
		return false;
	}
	while (offset < s.len) {
		bool ok = false;
		Rune r = -1;
		isize size = gb_utf8_decode(s.text+offset, s.len-offset, &r);
		if (offset == 0) {
			ok = rune_is_letter(r);
		} else {
			ok = rune_is_letter(r) || rune_is_digit(r);
		}

		if (!ok) {
			return false;
		}
		offset += size;
	}

	return offset == s.len;
}

String path_to_entity_name(String name, String fullpath) {
	if (name.len != 0) {
		return name;
	}
	// NOTE(bill): use file name (without extension) as the identifier
	// If it is a valid identifier
	String filename = fullpath;
	isize slash = 0;
	isize dot = 0;
	for (isize i = filename.len-1; i >= 0; i--) {
		u8 c = filename.text[i];
		if (c == '/' || c == '\\') {
			break;
		}
		slash = i;
	}

	filename.text += slash;
	filename.len -= slash;

	dot = filename.len;
	while (dot --> 0) {
		u8 c = filename.text[dot];
		if (c == '.') {
			break;
		}
	}

	filename.len = dot;

	if (is_string_an_identifier(filename)) {
		return filename;
	} else {
		return str_lit("_");
	}
}

void check_import_entities(Checker *c, MapScope *file_scopes) {
#if 0
	// TODO(bill): Dependency ordering for imports
	{
		Array_i32 shared_global_file_ids = {0};
		array_init_reserve(&shared_global_file_ids, heap_allocator(), c->file_nodes.count);
		for_array(i, c->file_nodes) {
			CheckerFileNode *node = &c->file_nodes.e[i];
			AstFile *f = &c->parser->files.e[node->id];
			GB_ASSERT(f->id == node->id);
			if (f->scope->is_global) {
				array_add(&shared_global_file_ids, f->id);
			}
		}

		for_array(i, c->file_nodes) {
			CheckerFileNode *node = &c->file_nodes.e[i];
			AstFile *f = &c->parser->files.e[node->id];
			if (!f->scope->is_global) {
				for_array(j, shared_global_file_ids) {
					array_add(&node->whats, shared_global_file_ids.e[j]);
				}
			}
		}

		array_free(&shared_global_file_ids);
	}

	for_array(i, c->delayed_imports) {
		Scope *parent_scope = c->delayed_imports.e[i].parent;
		AstNode *decl = c->delayed_imports.e[i].decl;
		ast_node(id, ImportDecl, decl);
		Token token = id->relpath;

		GB_ASSERT(parent_scope->is_file);

		if (!parent_scope->has_been_imported) {
			continue;
		}

		HashKey key = hash_string(id->fullpath);
		Scope **found = map_scope_get(file_scopes, key);
		if (found == NULL) {
			for_array(scope_index, file_scopes->entries) {
				Scope *scope = file_scopes->entries.e[scope_index].value;
				gb_printf_err("%.*s\n", LIT(scope->file->tokenizer.fullpath));
			}
			gb_printf_err("%.*s(%td:%td)\n", LIT(token.pos.file), token.pos.line, token.pos.column);
			GB_PANIC("Unable to find scope for file: %.*s", LIT(id->fullpath));
		}
		Scope *scope = *found;

		if (scope->is_global) {
			continue;
		}

		i32 parent_id = parent_scope->file->id;
		i32 child_id  = scope->file->id;

		// TODO(bill): Very slow
		CheckerFileNode *parent_node = &c->file_nodes.e[parent_id];
		bool add_child = true;
		for_array(j, parent_node->whats) {
			if (parent_node->whats.e[j] == child_id) {
				add_child = false;
				break;
			}
		}
		if (add_child) {
			array_add(&parent_node->whats, child_id);
		}

		CheckerFileNode *child_node  = &c->file_nodes.e[child_id];
		bool add_parent = true;
		for_array(j, parent_node->wheres) {
			if (parent_node->wheres.e[j] == parent_id) {
				add_parent = false;
				break;
			}
		}
		if (add_parent) {
			array_add(&child_node->wheres, parent_id);
		}
	}

	for_array(i, c->file_nodes) {
		CheckerFileNode *node = &c->file_nodes.e[i];
		AstFile *f = &c->parser->files.e[node->id];
		gb_printf_err("File %d %.*s", node->id, LIT(f->tokenizer.fullpath));
		gb_printf_err("\n  wheres:");
		for_array(j, node->wheres) {
			gb_printf_err(" %d", node->wheres.e[j]);
		}
		gb_printf_err("\n  whats:");
		for_array(j, node->whats) {
			gb_printf_err(" %d", node->whats.e[j]);
		}
		gb_printf_err("\n");
	}
#endif

	for_array(i, c->delayed_imports) {
		Scope *parent_scope = c->delayed_imports.e[i].parent;
		AstNode *decl = c->delayed_imports.e[i].decl;
		ast_node(id, ImportDecl, decl);
		Token token = id->relpath;

		GB_ASSERT(parent_scope->is_file);

		if (!parent_scope->has_been_imported) {
			continue;
		}

		HashKey key = hash_string(id->fullpath);
		Scope **found = map_scope_get(file_scopes, key);
		if (found == NULL) {
			for_array(scope_index, file_scopes->entries) {
				Scope *scope = file_scopes->entries.e[scope_index].value;
				gb_printf_err("%.*s\n", LIT(scope->file->tokenizer.fullpath));
			}
			gb_printf_err("%.*s(%td:%td)\n", LIT(token.pos.file), token.pos.line, token.pos.column);
			GB_PANIC("Unable to find scope for file: %.*s", LIT(id->fullpath));
		}
		Scope *scope = *found;

		if (scope->is_global) {
			error(token, "Importing a #shared_global_scope is disallowed and unnecessary");
			continue;
		}

		if (id->cond != NULL) {
			Operand operand = {Addressing_Invalid};
			check_expr(c, &operand, id->cond);
			if (operand.mode != Addressing_Constant || !is_type_boolean(operand.type)) {
				error_node(id->cond, "Non-constant boolean `when` condition");
				continue;
			}
			if (operand.value.kind == ExactValue_Bool &&
			    !operand.value.value_bool) {
				continue;
			}
		}

		bool previously_added = false;
		for_array(import_index, parent_scope->imported) {
			Scope *prev = parent_scope->imported.e[import_index];
			if (prev == scope) {
				previously_added = true;
				break;
			}
		}

		if (!previously_added) {
			array_add(&parent_scope->imported, scope);
		} else {
			warning(token, "Multiple import of the same file within this scope");
		}

		scope->has_been_imported = true;

		if (str_eq(id->import_name.string, str_lit("."))) {
			// NOTE(bill): Add imported entities to this file's scope
			for_array(elem_index, scope->elements.entries) {
				Entity *e = scope->elements.entries.e[elem_index].value;
				if (e->scope == parent_scope) {
					continue;
				}


				if (!is_entity_kind_exported(e->kind)) {
					continue;
				}
				if (id->is_import) {
					if (is_entity_exported(e)) {
						// TODO(bill): Should these entities be imported but cause an error when used?
						bool ok = add_entity(c, parent_scope, e->identifier, e);
						if (ok) {
							map_bool_set(&parent_scope->implicit, hash_pointer(e), true);
						}
					}
				} else {
					add_entity(c, parent_scope, e->identifier, e);
				}
			}
		} else {
			String import_name = path_to_entity_name(id->import_name.string, id->fullpath);
			if (str_eq(import_name, str_lit("_"))) {
				error(token, "File name, %.*s, cannot be as an import name as it is not a valid identifier", LIT(id->import_name.string));
			} else {
				GB_ASSERT(id->import_name.pos.line != 0);
				id->import_name.string = import_name;
				Entity *e = make_entity_import_name(c->allocator, parent_scope, id->import_name, t_invalid,
				                                    id->fullpath, id->import_name.string,
				                                    scope);


				add_entity(c, parent_scope, NULL, e);
			}
		}
	}

	for_array(i, c->delayed_foreign_libraries) {
		Scope *parent_scope = c->delayed_foreign_libraries.e[i].parent;
		AstNode *decl = c->delayed_foreign_libraries.e[i].decl;
		ast_node(fl, ForeignLibrary, decl);

		String file_str = fl->filepath.string;
		String base_dir = fl->base_dir;

		if (!fl->is_system) {
			gbAllocator a = heap_allocator(); // TODO(bill): Change this allocator

			String rel_path = get_fullpath_relative(a, base_dir, file_str);
			String import_file = rel_path;
			if (!gb_file_exists(cast(char *)rel_path.text)) { // NOTE(bill): This should be null terminated
				String abs_path = get_fullpath_core(a, file_str);
				if (gb_file_exists(cast(char *)abs_path.text)) {
					import_file = abs_path;
				}
			}
			file_str = import_file;
		}

		if (fl->cond != NULL) {
			Operand operand = {Addressing_Invalid};
			check_expr(c, &operand, fl->cond);
			if (operand.mode != Addressing_Constant || !is_type_boolean(operand.type)) {
				error_node(fl->cond, "Non-constant boolean `when` condition");
				continue;
			}
			if (operand.value.kind == ExactValue_Bool &&
			    !operand.value.value_bool) {
				continue;
			}
		}


		String library_name = path_to_entity_name(fl->library_name.string, file_str);
		if (str_eq(library_name, str_lit("_"))) {
			error(fl->token, "File name, %.*s, cannot be as a library name as it is not a valid identifier", LIT(fl->library_name.string));
		} else {
			GB_ASSERT(fl->library_name.pos.line != 0);
			fl->library_name.string = library_name;
			Entity *e = make_entity_library_name(c->allocator, parent_scope, fl->library_name, t_invalid,
			                                     file_str, library_name);
			add_entity(c, parent_scope, NULL, e);
		}
	}
}


void check_parsed_files(Checker *c) {
	MapScope file_scopes; // Key: String (fullpath)
	map_scope_init(&file_scopes, heap_allocator());

	// Map full filepaths to Scopes
	for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files.e[i];
		Scope *scope = NULL;
		scope = make_scope(c->global_scope, c->allocator);
		scope->is_global = f->is_global_scope;
		scope->is_file   = true;
		scope->file      = f;
		if (str_eq(f->tokenizer.fullpath, c->parser->init_fullpath)) {
			scope->is_init = true;
		}

		if (scope->is_global) {
			array_add(&c->global_scope->shared, scope);
		}

		if (scope->is_init || scope->is_global) {
			scope->has_been_imported = true;
		}

		f->scope = scope;
		f->decl_info = make_declaration_info(c->allocator, f->scope, c->context.decl);
		HashKey key = hash_string(f->tokenizer.fullpath);
		map_scope_set(&file_scopes, key, scope);
		map_ast_file_set(&c->info.files, key, f);
	}

	// Collect Entities
	for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files.e[i];
		CheckerContext prev_context = c->context;
		add_curr_ast_file(c, f);
		check_collect_entities(c, f->decls, true);
		c->context = prev_context;
	}

	check_import_entities(c, &file_scopes);

	check_all_global_entities(c);
	init_preload(c); // NOTE(bill): This could be setup previously through the use of `type_info(_of_val)`

	// Check procedure bodies
	// NOTE(bill): Nested procedures bodies will be added to this "queue"
	for_array(i, c->procs) {
		ProcedureInfo *pi = &c->procs.e[i];
		CheckerContext prev_context = c->context;
		add_curr_ast_file(c, pi->file);

		bool bounds_check    = (pi->tags & ProcTag_bounds_check)    != 0;
		bool no_bounds_check = (pi->tags & ProcTag_no_bounds_check) != 0;


		if (bounds_check) {
			c->context.stmt_state_flags |= StmtStateFlag_bounds_check;
			c->context.stmt_state_flags &= ~StmtStateFlag_no_bounds_check;
		} else if (no_bounds_check) {
			c->context.stmt_state_flags |= StmtStateFlag_no_bounds_check;
			c->context.stmt_state_flags &= ~StmtStateFlag_bounds_check;
		}

		check_proc_body(c, pi->token, pi->decl, pi->type, pi->body);

		c->context = prev_context;
	}

	// Add untyped expression values
	for_array(i, c->info.untyped.entries) {
		MapExprInfoEntry *entry = &c->info.untyped.entries.e[i];
		HashKey key = entry->key;
		AstNode *expr = cast(AstNode *)cast(uintptr)key.key;
		ExprInfo *info = &entry->value;
		if (info != NULL && expr != NULL) {
			if (is_type_typed(info->type)) {
				compiler_error("%s (type %s) is typed!", expr_to_string(expr), type_to_string(info->type));
			}
			add_type_and_value(&c->info, expr, info->mode, info->type, info->value);
		}
	}

	// TODO(bill): Check for unused imports (and remove) or even warn/err
	// TODO(bill): Any other checks?


#if 1
	// Add "Basic" type information
	for (isize i = 0; i < gb_count_of(basic_types)-1; i++) {
		Type *t = &basic_types[i];
		if (t->Basic.size > 0) {
			add_type_info_type(c, t);
		}
	}

	for (isize i = 0; i < gb_count_of(basic_type_aliases)-1; i++) {
		Type *t = &basic_type_aliases[i];
		if (t->Basic.size > 0) {
			add_type_info_type(c, t);
		}
	}
#endif


	// NOTE(bill): Check for illegal cyclic type declarations
	for_array(i, c->info.definitions.entries) {
		Entity *e = c->info.definitions.entries.e[i].value;
		if (e->kind == Entity_TypeName) {
			if (e->type != NULL) {
				// i64 size  = type_size_of(c->sizes, c->allocator, e->type);
				i64 align = type_align_of(c->allocator, e->type);
				if (align > 0) {
					// add_type_info_type(c, e->type);
				}
			}
		}
	}

	// gb_printf_err("Count: %td\n", c->info.type_info_count++);

	if (!build_context.is_dll) {
		for_array(i, file_scopes.entries) {
			Scope *s = file_scopes.entries.e[i].value;
			if (s->is_init) {
				Entity *e = current_scope_lookup_entity(s, str_lit("main"));
				if (e == NULL) {
					Token token = {0};
					if (s->file->tokens.count > 0) {
						token = s->file->tokens.e[0];
					} else {
						token.pos.file = s->file->tokenizer.fullpath;
						token.pos.line = 1;
						token.pos.column = 1;
					}

					error(token, "Undefined entry point procedure `main`");
				}

				break;
			}
		}
	}

	map_scope_destroy(&file_scopes);

}
