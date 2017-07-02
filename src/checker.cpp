#include "exact_value.cpp"
#include "entity.cpp"

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
	BuiltinProc_free,

	BuiltinProc_reserve,
	BuiltinProc_clear,
	BuiltinProc_append,
	BuiltinProc_delete,

	BuiltinProc_size_of,
	BuiltinProc_align_of,
	BuiltinProc_offset_of,
	BuiltinProc_type_of,
	BuiltinProc_type_info,

	BuiltinProc_compile_assert,

	BuiltinProc_swizzle,

	BuiltinProc_complex,
	BuiltinProc_real,
	BuiltinProc_imag,
	BuiltinProc_conj,

	BuiltinProc_slice_ptr,
	BuiltinProc_slice_to_bytes,

	BuiltinProc_expand_to_tuple,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,
	BuiltinProc_clamp,

	BuiltinProc_transmute,

	BuiltinProc_DIRECTIVE, // NOTE(bill): This is used for specialized hash-prefixed procedures

	BuiltinProc_COUNT,
};
gb_global BuiltinProc builtin_procs[BuiltinProc_COUNT] = {
	{STR_LIT(""),                 0, false, Expr_Stmt},

	{STR_LIT("len"),              1, false, Expr_Expr},
	{STR_LIT("cap"),              1, false, Expr_Expr},

	// {STR_LIT("new"),              1, false, Expr_Expr},
	{STR_LIT("make"),             1, true,  Expr_Expr},
	{STR_LIT("free"),             1, false, Expr_Stmt},

	{STR_LIT("reserve"),          2, false, Expr_Stmt},
	{STR_LIT("clear"),            1, false, Expr_Stmt},
	{STR_LIT("append"),           1, true,  Expr_Expr},
	{STR_LIT("delete"),           2, false, Expr_Stmt},

	{STR_LIT("size_of"),          1, false, Expr_Expr},
	{STR_LIT("align_of"),         1, false, Expr_Expr},
	{STR_LIT("offset_of"),        2, false, Expr_Expr},
	{STR_LIT("type_of"),          1, false, Expr_Expr},
	{STR_LIT("type_info"),        1, false, Expr_Expr},

	{STR_LIT("compile_assert"),   1, false, Expr_Expr},

	{STR_LIT("swizzle"),          1, true,  Expr_Expr},

	{STR_LIT("complex"),          2, false, Expr_Expr},
	{STR_LIT("real"),             1, false, Expr_Expr},
	{STR_LIT("imag"),             1, false, Expr_Expr},
	{STR_LIT("conj"),             1, false, Expr_Expr},

	{STR_LIT("slice_ptr"),        2, true,  Expr_Expr},
	{STR_LIT("slice_to_bytes"),   1, false, Expr_Stmt},

	{STR_LIT("expand_to_tuple"),  1, false, Expr_Expr},

	{STR_LIT("min"),              2, false, Expr_Expr},
	{STR_LIT("max"),              2, false, Expr_Expr},
	{STR_LIT("abs"),              1, false, Expr_Expr},
	{STR_LIT("clamp"),            3, false, Expr_Expr},

	{STR_LIT("transmute"),        2, false, Expr_Expr},

	{STR_LIT(""),                 0, true,  Expr_Expr}, // DIRECTIVE
};


#include "types.cpp"

enum AddressingMode {
	Addressing_Invalid,       // invalid addressing mode
	Addressing_NoValue,       // no value (void in C)
	Addressing_Value,         // computed value (rvalue)
	Addressing_Immutable,     // immutable computed value (const rvalue)
	Addressing_Variable,      // addressable variable (lvalue)
	Addressing_Constant,      // constant
	Addressing_Type,          // type
	Addressing_Builtin,       // built-in procedure
	Addressing_Overload,      // overloaded procedure
	Addressing_MapIndex,      // map index expression -
	                          // 	lhs: acts like a Variable
	                          // 	rhs: acts like OptionalOk
	Addressing_OptionalOk,    // rhs: acts like a value with an optional boolean part (for existence check)
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
	isize          overload_count;
	Entity **      overload_entities;
};

struct TypeAndValue {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
};

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
	AstNode *         proc_lit; // AstNode_ProcLit
	Type *            gen_proc_type; // Precalculated

	Map<bool>         deps; // Key: Entity *
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

// ExprInfo stores information used for "untyped" expressions
struct ExprInfo {
	bool           is_lhs; // Debug info
	AddressingMode mode;
	Type *         type; // Type_Basic
	ExactValue     value;
};

ExprInfo make_expr_info(bool is_lhs, AddressingMode mode, Type *type, ExactValue value) {
	ExprInfo ei = {is_lhs, mode, type, value};
	return ei;
}



struct Scope {
	AstNode *        node;
	Scope *          parent;
	Scope *          prev, *next;
	Scope *          first_child;
	Scope *          last_child;
	Map<Entity *>    elements; // Key: String
	Map<bool>        implicit; // Key: Entity *

	Array<Scope *>   shared;
	Array<Scope *>   imported;
	bool             is_proc;
	bool             is_global;
	bool             is_file;
	bool             is_init;
	bool             has_been_imported; // This is only applicable to file scopes
	AstFile *        file;
};
gb_global Scope *universal_scope = NULL;

void scope_reset(Scope *scope) {
	if (scope == NULL) return;

	scope->first_child = NULL;
	scope->last_child  = NULL;
	map_clear  (&scope->elements);
	map_clear  (&scope->implicit);
	array_clear(&scope->shared);
	array_clear(&scope->imported);
}


struct DelayedDecl {
	Scope *  parent;
	AstNode *decl;
};

struct CheckerFileNode {
	i32        id;
	Array<i32> wheres;
	Array<i32> whats;
	i32        score; // Higher the score, the better
};

struct CheckerContext {
	Scope *    file_scope;
	Scope *    scope;
	DeclInfo * decl;
	u32        stmt_state_flags;
	bool       in_defer; // TODO(bill): Actually handle correctly
	bool       allow_polymorphic_types;
	bool       no_polymorphic_errors;
	String     proc_name;
	Type *     type_hint;
	DeclInfo * curr_proc_decl;
	AstNode *  curr_foreign_library;
};


// CheckerInfo stores all the symbol information for a type-checked program
struct CheckerInfo {
	Map<TypeAndValue>     types;           // Key: AstNode * | Expression -> Type (and value)
	Map<Entity *>         definitions;     // Key: AstNode * | Identifier -> Entity
	Map<Entity *>         uses;            // Key: AstNode * | Identifier -> Entity
	Map<Scope *>          scopes;          // Key: AstNode * | Node       -> Scope
	Map<ExprInfo>         untyped;         // Key: AstNode * | Expression -> ExprInfo
	Map<Entity *>         implicits;       // Key: AstNode *
	Map<Array<Entity *> > gen_procs;       // Key: AstNode * | Identifier -> Entity
	Map<DeclInfo *>       entities;        // Key: Entity *
	Map<Entity *>         foreigns;        // Key: String
	Map<AstFile *>        files;           // Key: String (full path)
	Map<isize>            type_info_map;   // Key: Type *
	isize                 type_info_count;
};

struct Checker {
	Parser *    parser;
	CheckerInfo info;

	AstFile *                  curr_ast_file;
	Scope *                    global_scope;
	// NOTE(bill): Procedures to check
	Map<ProcedureInfo>         procs; // Key: DeclInfo *
	Array<DelayedDecl>         delayed_imports;
	Array<DelayedDecl>         delayed_foreign_libraries;
	Array<CheckerFileNode>     file_nodes;

	gbArena                    arena;
	gbArena                    tmp_arena;
	gbAllocator                allocator;
	gbAllocator                tmp_allocator;

	CheckerContext             context;

	Array<Type *>              proc_stack;
	bool                       done_preload;
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


ExprInfo *check_get_expr_info(CheckerInfo *i, AstNode *expr);
void check_set_expr_info(CheckerInfo *i, AstNode *expr, ExprInfo info);
void check_remove_expr_info(CheckerInfo *i, AstNode *expr);
void add_untyped(CheckerInfo *i, AstNode *expression, bool lhs, AddressingMode mode, Type *basic_type, ExactValue value);
void add_type_and_value(CheckerInfo *i, AstNode *expression, AddressingMode mode, Type *type, ExactValue value);
void add_entity_use(Checker *c, AstNode *identifier, Entity *entity);
void add_implicit_entity(Checker *c, AstNode *node, Entity *e);
void add_entity_and_decl_info(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d);
void add_implicit_entity(Checker *c, AstNode *node, Entity *e);


void init_declaration_info(DeclInfo *d, Scope *scope, DeclInfo *parent) {
	d->parent = parent;
	d->scope  = scope;
	map_init(&d->deps, heap_allocator());
	array_init(&d->labels,  heap_allocator());
}

DeclInfo *make_declaration_info(gbAllocator a, Scope *scope, DeclInfo *parent) {
	DeclInfo *d = gb_alloc_item(a, DeclInfo);
	init_declaration_info(d, scope, parent);
	return d;
}

void destroy_declaration_info(DeclInfo *d) {
	map_destroy(&d->deps);
}

bool decl_info_has_init(DeclInfo *d) {
	if (d->init_expr != NULL) {
		return true;
	}
	if (d->proc_lit != NULL) {
		switch (d->proc_lit->kind) {
		case_ast_node(pl, ProcLit, d->proc_lit);
			if (pl->body != NULL) {
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
	map_init(&s->elements,   heap_allocator());
	map_init(&s->implicit,   heap_allocator());
	array_init(&s->shared,   heap_allocator());
	array_init(&s->imported, heap_allocator());

	if (parent != NULL && parent != universal_scope) {
		DLIST_APPEND(parent->first_child, parent->last_child, s);
	}
	return s;
}

void destroy_scope(Scope *scope) {
	for_array(i, scope->elements.entries) {
		Entity *e =scope->elements.entries[i].value;
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

	map_destroy(&scope->elements);
	map_destroy(&scope->implicit);
	array_free(&scope->shared);
	array_free(&scope->imported);

	// NOTE(bill): No need to free scope as it "should" be allocated in an arena (except for the global scope)
}


void add_scope(Checker *c, AstNode *node, Scope *scope) {
	GB_ASSERT(node != NULL);
	GB_ASSERT(scope != NULL);
	scope->node = node;
	map_set(&c->info.scopes, hash_node(node), scope);
}


void check_open_scope(Checker *c, AstNode *node) {
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
	Entity **found = map_get(&s->elements, key);
	if (found) {
		return *found;
	}
	for_array(i, s->shared) {
		Scope *shared = s->shared[i];
		Entity **found = map_get(&shared->elements, key);
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
		Entity **found = map_get(&s->elements, key);
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
				Scope *shared = s->shared[i];
				Entity **found = map_get(&shared->elements, key);
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
	Entity **found = map_get(&s->elements, key);

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
		multi_map_insert(&s->elements, key, entity);
	} else {
		map_set(&s->elements, key, entity);
	}
#else
	if (found) {
		return *found;
	}
	map_set(&s->elements, key, entity);
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
	map_set(&d->deps, hash_entity(e), cast(bool)true);
}

void add_declaration_dependency(Checker *c, Entity *e) {
	if (e == NULL) {
		return;
	}
	if (c->context.decl != NULL) {
		DeclInfo **found = map_get(&c->info.entities, hash_entity(e));
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
	// for (isize i = 0; i < gb_count_of(basic_type_aliases); i++) {
		// add_global_entity(make_entity_type_name(a, NULL, make_token_ident(basic_type_aliases[i].Basic.name), &basic_type_aliases[i]));
	// }
#else
	{
		t_byte = add_global_type_alias(a, str_lit("byte"), &basic_types[Basic_u8]);
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
		String name = builtin_procs[i].name;
		if (name != "") {
			Entity *entity = alloc_entity(a, Entity_Builtin, NULL, make_token_ident(name), t_invalid);
			entity->Builtin.id = id;
			add_global_entity(entity);
		}
	}


	t_u8_ptr       = make_type_pointer(a, t_u8);
	t_int_ptr      = make_type_pointer(a, t_int);
	t_i64_ptr      = make_type_pointer(a, t_i64);
	t_i128_ptr     = make_type_pointer(a, t_i128);
	t_f64_ptr      = make_type_pointer(a, t_f64);
	t_u8_slice     = make_type_slice(a, t_u8);
	t_string_slice = make_type_slice(a, t_string);
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = heap_allocator();
	map_init(&i->types,         a);
	map_init(&i->definitions,   a);
	map_init(&i->uses,          a);
	map_init(&i->scopes,        a);
	map_init(&i->entities,      a);
	map_init(&i->untyped,       a);
	map_init(&i->foreigns,      a);
	map_init(&i->implicits,     a);
	map_init(&i->gen_procs,     a);
	map_init(&i->type_info_map, a);
	map_init(&i->files,         a);
	i->type_info_count = 0;

}

void destroy_checker_info(CheckerInfo *i) {
	map_destroy(&i->types);
	map_destroy(&i->definitions);
	map_destroy(&i->uses);
	map_destroy(&i->scopes);
	map_destroy(&i->entities);
	map_destroy(&i->untyped);
	map_destroy(&i->foreigns);
	map_destroy(&i->implicits);
	map_destroy(&i->gen_procs);
	map_destroy(&i->type_info_map);
	map_destroy(&i->files);
}


void init_checker(Checker *c, Parser *parser) {
	if (global_error_collector.count > 0) {
		gb_exit(1);
	}
	BuildContext *bc = &build_context;

	gbAllocator a = heap_allocator();

	c->parser = parser;
	init_checker_info(&c->info);

	array_init(&c->proc_stack, a);
	map_init(&c->procs, a);
	array_init(&c->delayed_imports, a);
	array_init(&c->delayed_foreign_libraries, a);
	array_init(&c->file_nodes, a);

	for_array(i, parser->files) {
		AstFile *file = &parser->files[i];
		CheckerFileNode node = {};
		node.id = file->id;
		array_init(&node.whats,  a);
		array_init(&node.wheres, a);
		array_add(&c->file_nodes, node);
	}

	// NOTE(bill): Is this big enough or too small?
	isize item_size = gb_max3(gb_size_of(Entity), gb_size_of(Type), gb_size_of(Scope));
	isize total_token_count = 0;
	for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
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
	map_destroy(&c->procs);
	array_free(&c->delayed_imports);
	array_free(&c->delayed_foreign_libraries);
	array_free(&c->file_nodes);

	gb_arena_free(&c->arena);
}


Entity *entity_of_ident(CheckerInfo *i, AstNode *identifier) {
	if (identifier->kind == AstNode_Ident) {
		Entity **found = map_get(&i->definitions, hash_node(identifier));
		if (found) {
			return *found;
		}
		found = map_get(&i->uses, hash_node(identifier));
		if (found) {
			return *found;
		}
	}
	return NULL;
}

TypeAndValue type_and_value_of_expr(CheckerInfo *i, AstNode *expr) {
	TypeAndValue result = {};
	TypeAndValue *found = map_get(&i->types, hash_node(expr));
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

Entity *implicit_entity_of_node(CheckerInfo *i, AstNode *clause) {
	Entity **found = map_get(&i->implicits, hash_node(clause));
	if (found != NULL) {
		return *found;
	}
	return NULL;
}
bool is_entity_implicitly_imported(Entity *import_name, Entity *e) {
	GB_ASSERT(import_name->kind == Entity_ImportName);
	return map_get(&import_name->ImportName.scope->implicit, hash_entity(e)) != NULL;
}


DeclInfo *decl_info_of_entity(CheckerInfo *i, Entity *e) {
	if (e != NULL) {
		DeclInfo **found = map_get(&i->entities, hash_entity(e));
		if (found != NULL) {
			return *found;
		}
	}
	return NULL;
}

DeclInfo *decl_info_of_ident(CheckerInfo *i, AstNode *ident) {
	return decl_info_of_entity(i, entity_of_ident(i, ident));
}

AstFile *ast_file_of_filename(CheckerInfo *i, String filename) {
	AstFile **found = map_get(&i->files, hash_string(filename));
	if (found != NULL) {
		return *found;
	}
	return NULL;
}
Scope *scope_of_node(CheckerInfo *i, AstNode *node) {
	Scope **found = map_get(&i->scopes, hash_node(node));
	if (found) {
		return *found;
	}
	return NULL;
}
ExprInfo *check_get_expr_info(CheckerInfo *i, AstNode *expr) {
	return map_get(&i->untyped, hash_node(expr));
}
void check_set_expr_info(CheckerInfo *i, AstNode *expr, ExprInfo info) {
	map_set(&i->untyped, hash_node(expr), info);
}
void check_remove_expr_info(CheckerInfo *i, AstNode *expr) {
	map_remove(&i->untyped, hash_node(expr));
}



isize type_info_index(CheckerInfo *info, Type *type, bool error_on_failure) {
	type = default_type(type);

	isize entry_index = -1;
	HashKey key = hash_type(type);
	isize *found_entry_index = map_get(&info->type_info_map, key);
	if (found_entry_index) {
		entry_index = *found_entry_index;
	}
	if (entry_index < 0) {
		// NOTE(bill): Do manual search
		// TODO(bill): This is O(n) and can be very slow
		for_array(i, info->type_info_map.entries){
			auto *e = &info->type_info_map.entries[i];
			Type *prev_type = cast(Type *)e->key.ptr;
			if (are_types_identical(prev_type, type)) {
				entry_index = e->value;
				// NOTE(bill): Add it to the search map
				map_set(&info->type_info_map, key, entry_index);
				break;
			}
		}
	}

	if (error_on_failure && entry_index < 0) {
		compiler_error("TypeInfo for `%s` could not be found", type_to_string(type));
	}
	return entry_index;
}


void add_untyped(CheckerInfo *i, AstNode *expression, bool lhs, AddressingMode mode, Type *basic_type, ExactValue value) {
	map_set(&i->untyped, hash_node(expression), make_expr_info(lhs, mode, basic_type, value));
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

	TypeAndValue tv = {};
	tv.type  = type;
	tv.value = value;
	tv.mode  = mode;
	map_set(&i->types, hash_node(expression), tv);
}

void add_entity_definition(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	if (identifier->kind == AstNode_Ident) {
		if (identifier->Ident.token.string == "_") {
			return;
		}
		HashKey key = hash_node(identifier);
		map_set(&i->definitions, key, entity);
	} else {
		// NOTE(bill): Error should be handled elsewhere
	}
}

bool add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	if (scope == NULL) {
		return false;
	}
	String name = entity->token.string;
	if (name != "_") {
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
	HashKey key = hash_node(identifier);
	map_set(&c->info.uses, key, entity);
	add_declaration_dependency(c, entity); // TODO(bill): Should this be here?
}


void add_entity_and_decl_info(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(identifier->kind == AstNode_Ident);
	GB_ASSERT(e != NULL && d != NULL);
	GB_ASSERT(identifier->Ident.token.string == e->token.string);
	if (e->scope != NULL) add_entity(c, e->scope, identifier, e);
	add_entity_definition(&c->info, identifier, e);
	map_set(&c->info.entities, hash_entity(e), d);
}


void add_implicit_entity(Checker *c, AstNode *node, Entity *e) {
	GB_ASSERT(node != NULL);
	GB_ASSERT(e != NULL);
	map_set(&c->info.implicits, hash_node(node), e);
}





void add_type_info_type(Checker *c, Type *t) {
	if (t == NULL) {
		return;
	}
	t = default_type(t);
	if (is_type_bit_field_value(t)) {
		t = default_bit_field_value_type(t);
	}
	if (is_type_untyped(t)) {
		return; // Could be nil
	}

	if (map_get(&c->info.type_info_map, hash_type(t)) != NULL) {
		// Types have already been added
		return;
	}

	isize ti_index = -1;
	for_array(i, c->info.type_info_map.entries) {
		auto *e = &c->info.type_info_map.entries[i];
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
	map_set(&c->info.type_info_map, hash_type(t), ti_index);




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

void check_procedure_later(Checker *c, ProcedureInfo info) {
	if (info.decl != NULL) {
		map_set(&c->procs, hash_decl_info(info.decl), info);
	}
}

void check_procedure_later(Checker *c, AstFile *file, Token token, DeclInfo *decl, Type *type, AstNode *body, u64 tags) {
	ProcedureInfo info = {};
	info.file = file;
	info.token = token;
	info.decl  = decl;
	info.type  = type;
	info.body  = body;
	info.tags  = tags;
	check_procedure_later(c, info);
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
		return c->proc_stack[count-1];
	}
	return NULL;
}

void add_curr_ast_file(Checker *c, AstFile *file) {
	if (file != NULL) {
		TokenPos zero_pos = {};
		global_error_collector.prev = zero_pos;
		c->curr_ast_file = file;
		c->context.decl  = file->decl_info;
		c->context.scope = file->scope;
		c->context.file_scope = file->scope;
	}
}


void add_dependency_to_map(Map<Entity *> *map, CheckerInfo *info, Entity *entity) {
	if (entity == NULL) {
		return;
	}
	if (entity->type != NULL &&
	    is_type_polymorphic(entity->type)) {
		DeclInfo *decl = decl_info_of_entity(info, entity);
		if (decl->gen_proc_type == NULL) {
			return;
		}
	}

	if (map_get(map, hash_entity(entity)) != NULL) {
		return;
	}
	map_set(map, hash_entity(entity), entity);


	DeclInfo *decl = decl_info_of_entity(info, entity);
	if (decl == NULL) {
		return;
	}

	for_array(i, decl->deps.entries) {
		Entity *e = cast(Entity *)decl->deps.entries[i].key.ptr;
		add_dependency_to_map(map, info, e);
	}
}

Map<Entity *> generate_minimum_dependency_map(CheckerInfo *info, Entity *start) {
	Map<Entity *> map = {}; // Key: Entity *
	map_init(&map, heap_allocator());

	for_array(i, info->definitions.entries) {
		Entity *e = info->definitions.entries[i].value;
		// if (e->scope->is_global && !is_type_poly_proc(e->type)) { // TODO(bill): is the check enough?
		if (e->scope->is_global) { // TODO(bill): is the check enough?
			if (!is_type_poly_proc(e->type))  {
				// NOTE(bill): Require runtime stuff
				add_dependency_to_map(&map, info, e);
			}
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

bool is_entity_in_dependency_map(Map<Entity *> *map, Entity *e) {
	return map_get(map, hash_entity(e)) != NULL;
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



		if (record->variant_count != 23) {
			compiler_error("Invalid `TypeInfo` layout");
		}
		t_type_info_named         = record->variants[ 1]->type;
		t_type_info_integer       = record->variants[ 2]->type;
		t_type_info_rune          = record->variants[ 3]->type;
		t_type_info_float         = record->variants[ 4]->type;
		t_type_info_complex       = record->variants[ 5]->type;
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
		t_type_info_bit_field     = record->variants[22]->type;

		t_type_info_named_ptr         = make_type_pointer(c->allocator, t_type_info_named);
		t_type_info_integer_ptr       = make_type_pointer(c->allocator, t_type_info_integer);
		t_type_info_rune_ptr          = make_type_pointer(c->allocator, t_type_info_rune);
		t_type_info_float_ptr         = make_type_pointer(c->allocator, t_type_info_float);
		t_type_info_complex_ptr       = make_type_pointer(c->allocator, t_type_info_complex);
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
		t_type_info_bit_field_ptr     = make_type_pointer(c->allocator, t_type_info_bit_field);
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

	if (t_source_code_location == NULL) {
		Entity *e = find_core_entity(c, str_lit("SourceCodeLocation"));
		t_source_code_location = e->type;
		t_source_code_location_ptr = make_type_pointer(c->allocator, t_allocator);
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




bool check_arity_match(Checker *c, AstNodeValueDecl *vd);
void check_collect_entities(Checker *c, Array<AstNode *> nodes, bool is_file_scope);
void check_collect_entities_from_when_stmt(Checker *c, AstNodeWhenStmt *ws, bool is_file_scope);

bool check_is_entity_overloaded(Entity *e) {
	if (e->kind != Entity_Procedure) {
		return false;
	}
	Scope *s = e->scope;
	HashKey key = hash_string(e->token.string);
	isize overload_count = multi_map_count(&s->elements, key);
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
	isize overload_count = multi_map_count(&s->elements, key);
	GB_ASSERT(overload_count >= 1);
	if (overload_count == 1) {
		e->Procedure.overload_kind = Overload_No;
		return;
	}
	GB_ASSERT(overload_count > 1);


	gbTempArenaMemory tmp = gb_temp_arena_memory_begin(&c->tmp_arena);
	Entity **procs = gb_alloc_array(c->tmp_allocator, Entity *, overload_count);
	multi_map_get_all(&s->elements, key, procs);

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

			if (q->type == NULL || q->type == t_invalid) {
				continue;
			}

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
			case ProcOverload_Polymorphic:
				#if 0
				error(p->token, "Overloaded procedure `%.*s` has a polymorphic counterpart in this scope which is not allowed", LIT(name));
				is_invalid = true;
				#endif
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


#include "check_expr.cpp"
#include "check_decl.cpp"
#include "check_stmt.cpp"



bool check_arity_match(Checker *c, AstNodeValueDecl *vd) {
	isize lhs = vd->names.count;
	isize rhs = vd->values.count;

	if (rhs == 0) {
		if (vd->type == NULL) {
			error(vd->names[0], "Missing type or initial expression");
			return false;
		}
	} else if (lhs < rhs) {
		if (lhs < vd->values.count) {
			AstNode *n = vd->values[lhs];
			gbString str = expr_to_string(n);
			error(n, "Extra initial expression `%s`", str);
			gb_string_free(str);
		} else {
			error(vd->names[0], "Extra initial expression");
		}
		return false;
	} else if (lhs > rhs && rhs != 1) {
		AstNode *n = vd->names[rhs];
		gbString str = expr_to_string(n);
		error(n, "Missing expression for `%s`", str);
		gb_string_free(str);
		return false;
	}

	return true;
}

void check_collect_entities_from_when_stmt(Checker *c, AstNodeWhenStmt *ws, bool is_file_scope) {
	Operand operand = {Addressing_Invalid};
	check_expr(c, &operand, ws->cond);
	if (operand.mode != Addressing_Invalid && !is_type_boolean(operand.type)) {
		error(ws->cond, "Non-boolean condition in `when` statement");
	}
	if (operand.mode != Addressing_Constant) {
		error(ws->cond, "Non-constant condition in `when` statement");
	}
	if (ws->body == NULL || ws->body->kind != AstNode_BlockStmt) {
		error(ws->cond, "Invalid body for `when` statement");
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
				error(ws->else_stmt, "Invalid `else` statement in `when` statement");
				break;
			}
		}
	}
}

// NOTE(bill): If file_scopes == NULL, this will act like a local scope
void check_collect_entities(Checker *c, Array<AstNode *> nodes, bool is_file_scope) {
	// NOTE(bill): File scope and local scope are different kinds of scopes
	if (is_file_scope) {
		GB_ASSERT(c->context.scope->is_file);
	} else {
		GB_ASSERT(!c->context.scope->is_file);
	}

	for_array(decl_index, nodes) {
		AstNode *decl = nodes[decl_index];
		if (!is_ast_node_decl(decl) && !is_ast_node_when_stmt(decl)) {
			continue;
		}

		switch (decl->kind) {
		case_ast_node(bd, BadDecl, decl);
		case_end;

		case_ast_node(ws, WhenStmt, decl);
			if (c->context.scope->is_file) {
				error(decl, "`when` statements are not allowed at file scope");
			} else {
				// Will be handled later
			}
		case_end;

		case_ast_node(vd, ValueDecl, decl);
			if (vd->is_mutable) {
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
					di->init_expr = vd->values[0];


					if (vd->flags & VarDeclFlag_thread_local) {
						error(decl, "#thread_local variable declarations cannot have initialization values");
					}
				}


				for_array(i, vd->names) {
					AstNode *name = vd->names[i];
					AstNode *value = NULL;
					if (i < vd->values.count) {
						value = vd->values[i];
					}
					if (name->kind != AstNode_Ident) {
						error(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
						continue;
					}
					Entity *e = make_entity_variable(c->allocator, c->context.scope, name->Ident.token, NULL, false);
					e->Variable.is_thread_local = (vd->flags & VarDeclFlag_thread_local) != 0;
					e->identifier = name;

					if (vd->flags & VarDeclFlag_using) {
						vd->flags &= ~VarDeclFlag_using; // NOTE(bill): This error will be only caught once
						error(name, "`using` is not allowed at the file scope");
					}

					AstNode *fl = c->context.curr_foreign_library;
					if (fl != NULL) {
						GB_ASSERT(fl->kind == AstNode_Ident);
						e->Variable.is_foreign = true;
						e->Variable.foreign_library_ident = fl;
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
					AstNode *name = vd->names[i];
					if (name->kind != AstNode_Ident) {
						error(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
						continue;
					}

					AstNode *init = unparen_expr(vd->values[i]);
					if (init == NULL) {
						error(name, "Expected a value for this constant value declaration");
						continue;
					}

					AstNode *fl = c->context.curr_foreign_library;
					DeclInfo *d = make_declaration_info(c->allocator, c->context.scope, c->context.decl);
					Entity *e = NULL;

					if (is_ast_node_type(init)) {
						e = make_entity_type_name(c->allocator, d->scope, name->Ident.token, NULL);
						d->type_expr = init;
						d->init_expr = init;
					} else if (init->kind == AstNode_ProcLit) {
						ast_node(pl, ProcLit, init);
						e = make_entity_procedure(c->allocator, d->scope, name->Ident.token, NULL, pl->tags);
						if (fl != NULL) {
							GB_ASSERT(fl->kind == AstNode_Ident);
							e->Procedure.foreign_library_ident = fl;
							pl->tags |= ProcTag_foreign;
						}
						d->proc_lit = init;
						d->type_expr = pl->type;
					} else {
						e = make_entity_constant(c->allocator, d->scope, name->Ident.token, NULL, empty_exact_value);
						d->type_expr = vd->type;
						d->init_expr = init;
					}
					e->identifier = name;

					if (fl != NULL && e->kind != Entity_Procedure) {
						AstNodeKind kind = init->kind;
						error(name, "Only procedures and variables are allowed to be in a foreign block, got %.*s", LIT(ast_node_strings[kind]));
						if (kind == AstNode_ProcType) {
							gb_printf_err("\tDid you forget to append `---` to the procedure?\n");
						}
						// continue;
					}


					add_entity_and_decl_info(c, name, e, d);
				}

				check_arity_match(c, vd);
			}
		case_end;

		case_ast_node(gd, GenDecl, decl);
			for_array(i, gd->specs) {
				AstNode *spec = gd->specs[i];
				switch (gd->token.kind) {
				case Token_import:
				case Token_import_load: {
					ast_node(ts, ImportSpec, spec);
					if (!c->context.scope->is_file) {
						if (ts->is_import) {
							error(decl, "import declarations are only allowed in the file scope");
						} else {
							error(decl, "import_load declarations are only allowed in the file scope");
						}
						// NOTE(bill): _Should_ be caught by the parser
						// TODO(bill): Better error handling if it isn't
						continue;
					}
					DelayedDecl di = {c->context.scope, spec};
					array_add(&c->delayed_imports, di);
				} break;

				case Token_foreign_library:
				case Token_foreign_system_library:  {
					ast_node(fl, ForeignLibrarySpec, spec);
					if (!c->context.scope->is_file) {
						if (fl->is_system) {
							error(spec, "foreign_system_library declarations are only allowed in the file scope");
						} else {
							error(spec, "foreign_library declarations are only allowed in the file scope");
						}
						// NOTE(bill): _Should_ be caught by the parser
						// TODO(bill): Better error handling if it isn't
						continue;
					}

					if (fl->cond != NULL) {
						Operand operand = {Addressing_Invalid};
						check_expr(c, &operand, fl->cond);
						if (operand.mode != Addressing_Constant || !is_type_boolean(operand.type)) {
							error(fl->cond, "Non-constant boolean `when` condition");
							continue;
						}
						if (operand.value.kind == ExactValue_Bool &&
							!operand.value.value_bool) {
							continue;
						}
					}

					DelayedDecl di = {c->context.scope, spec};
					array_add(&c->delayed_foreign_libraries, di);
				} break;
				}
			}
		case_end;

		case_ast_node(fb, ForeignBlockDecl, decl);
			AstNode *foreign_library = fb->foreign_library;
			if (foreign_library->kind != AstNode_Ident) {
				error(foreign_library, "foreign library name must be an identifier");
				foreign_library = NULL;
			}

			CheckerContext prev_context = c->context;
			c->context.curr_foreign_library = foreign_library;
			check_collect_entities(c, fb->decls, is_file_scope);
			c->context = prev_context;
		case_end;

		// case_ast_node(pd, ProcDecl, decl);
		// 	AstNode *name = pd->name;
		// 	if (name->kind != AstNode_Ident) {
		// 		error(name, "A declaration's name must be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
		// 		break;
		// 	}


		// 	DeclInfo *d = make_declaration_info(c->allocator, c->context.scope, c->context.decl);
		// 	Entity *e = NULL;

		// 	e = make_entity_procedure(c->allocator, d->scope, name->Ident, NULL, pd->tags);
		// 	AstNode *fl = c->context.curr_foreign_library;
		// 	if (fl != NULL) {
		// 		GB_ASSERT(fl->kind == AstNode_Ident);
		// 		e->Procedure.foreign_library_ident = fl;
		// 		pd->tags |= ProcTag_foreign;
		// 	}
		// 	d->proc_decl = decl;
		// 	d->type_expr = pd->type;
		// 	e->identifier = name;
		// 	add_entity_and_decl_info(c, name, e, d);
		// case_end;

		default:
			if (c->context.scope->is_file) {
				error(decl, "Only declarations are allowed at file scope");
			}
			break;
		}
	}

	// NOTE(bill): `when` stmts need to be handled after the other as the condition may refer to something
	// declared after this stmt in source
	if (!c->context.scope->is_file) {
		for_array(i, nodes) {
			AstNode *node = nodes[i];
			switch (node->kind) {
			case_ast_node(ws, WhenStmt, node);
					check_collect_entities_from_when_stmt(c, ws, is_file_scope);
			case_end;
			}
		}
	}
}


void check_all_global_entities(Checker *c) {
	Scope *prev_file = NULL;

	for_array(i, c->info.entities.entries) {
		auto *entry = &c->info.entities.entries[i];
		Entity *e = cast(Entity *)entry->key.ptr;
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

		if (e->token.string == "main") {
			if (e->kind != Entity_Procedure) {
				if (e->scope->is_init) {
					error(e->token, "`main` is reserved as the entry point procedure in the initial scope");
					continue;
				}
			} else if (e->scope->is_global) {
				error(e->token, "`main` is reserved as the entry point procedure in the initial scope");
				continue;
			}
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
		auto *entry = &c->info.entities.entries[i];
		Entity *e = cast(Entity *)entry->key.ptr;
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
		u8 c = filename[i];
		if (c == '/' || c == '\\') {
			break;
		}
		slash = i;
	}

	filename.text += slash;
	filename.len -= slash;

	dot = filename.len;
	while (dot --> 0) {
		u8 c = filename[dot];
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

void check_import_entities(Checker *c, Map<Scope *> *file_scopes) {
#if 0
	// TODO(bill): Dependency ordering for imports
	{
		Array_i32 shared_global_file_ids = {};
		array_init_reserve(&shared_global_file_ids, heap_allocator(), c->file_nodes.count);
		for_array(i, c->file_nodes) {
			CheckerFileNode *node = &c->file_nodes[i];
			AstFile *f = &c->parser->files[node->id];
			GB_ASSERT(f->id == node->id);
			if (f->scope->is_global) {
				array_add(&shared_global_file_ids, f->id);
			}
		}

		for_array(i, c->file_nodes) {
			CheckerFileNode *node = &c->file_nodes[i];
			AstFile *f = &c->parser->files[node->id];
			if (!f->scope->is_global) {
				for_array(j, shared_global_file_ids) {
					array_add(&node->whats, shared_global_file_ids[j]);
				}
			}
		}

		array_free(&shared_global_file_ids);
	}

	for_array(i, c->delayed_imports) {
		Scope *parent_scope = c->delayed_imports[i].parent;
		AstNode *decl = c->delayed_imports[i].decl;
		ast_node(id, ImportDecl, decl);
		Token token = id->relpath;

		GB_ASSERT(parent_scope->is_file);

		if (!parent_scope->has_been_imported) {
			continue;
		}

		HashKey key = hash_string(id->fullpath);
		Scope **found = map_get(file_scopes, key);
		if (found == NULL) {
			for_array(scope_index, file_scopes->entries) {
				Scope *scope = file_scopes->entries[scope_index].value;
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
		CheckerFileNode *parent_node = &c->file_nodes[parent_id];
		bool add_child = true;
		for_array(j, parent_node->whats) {
			if (parent_node->whats[j] == child_id) {
				add_child = false;
				break;
			}
		}
		if (add_child) {
			array_add(&parent_node->whats, child_id);
		}

		CheckerFileNode *child_node  = &c->file_nodes[child_id];
		bool add_parent = true;
		for_array(j, parent_node->wheres) {
			if (parent_node->wheres[j] == parent_id) {
				add_parent = false;
				break;
			}
		}
		if (add_parent) {
			array_add(&child_node->wheres, parent_id);
		}
	}

	for_array(i, c->file_nodes) {
		CheckerFileNode *node = &c->file_nodes[i];
		AstFile *f = &c->parser->files[node->id];
		gb_printf_err("File %d %.*s", node->id, LIT(f->tokenizer.fullpath));
		gb_printf_err("\n  wheres:");
		for_array(j, node->wheres) {
			gb_printf_err(" %d", node->wheres[j]);
		}
		gb_printf_err("\n  whats:");
		for_array(j, node->whats) {
			gb_printf_err(" %d", node->whats[j]);
		}
		gb_printf_err("\n");
	}
#endif

	for_array(i, c->delayed_imports) {
		Scope *parent_scope = c->delayed_imports[i].parent;
		AstNode *decl = c->delayed_imports[i].decl;
		ast_node(id, ImportSpec, decl);
		Token token = id->relpath;

		GB_ASSERT(parent_scope->is_file);

		if (!parent_scope->has_been_imported) {
			continue;
		}

		HashKey key = hash_string(id->fullpath);
		Scope **found = map_get(file_scopes, key);
		if (found == NULL) {
			for_array(scope_index, file_scopes->entries) {
				Scope *scope = file_scopes->entries[scope_index].value;
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
				error(id->cond, "Non-constant boolean `when` condition");
				continue;
			}
			if (operand.value.kind == ExactValue_Bool &&
			    operand.value.value_bool == false) {
				continue;
			}
		}

		bool previously_added = false;
		for_array(import_index, parent_scope->imported) {
			Scope *prev = parent_scope->imported[import_index];
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

		if (id->import_name.string == ".") {
			// NOTE(bill): Add imported entities to this file's scope
			for_array(elem_index, scope->elements.entries) {
				Entity *e = scope->elements.entries[elem_index].value;
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
							map_set(&parent_scope->implicit, hash_entity(e), true);
						}
					}
				} else {
					add_entity(c, parent_scope, e->identifier, e);
				}
			}
		} else {
			String import_name = path_to_entity_name(id->import_name.string, id->fullpath);
			if (import_name == "_") {
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
		Scope *parent_scope = c->delayed_foreign_libraries[i].parent;
		AstNode *spec = c->delayed_foreign_libraries[i].decl;
		ast_node(fl, ForeignLibrarySpec, spec);

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
				error(fl->cond, "Non-constant boolean `when` condition");
				continue;
			}
			if (operand.value.kind == ExactValue_Bool &&
			    !operand.value.value_bool) {
				continue;
			}
		}


		String library_name = path_to_entity_name(fl->library_name.string, file_str);
		if (library_name == "_") {
			error(spec, "File name, %.*s, cannot be as a library name as it is not a valid identifier", LIT(fl->library_name.string));
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
	Map<Scope *> file_scopes; // Key: String (fullpath)
	map_init(&file_scopes, heap_allocator());
	defer (map_destroy(&file_scopes));

	add_type_info_type(c, t_invalid);

	// Map full filepaths to Scopes
	for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		Scope *scope = NULL;
		scope = make_scope(c->global_scope, c->allocator);
		scope->is_global = f->is_global_scope;
		scope->is_file   = true;
		scope->file      = f;
		if (f->tokenizer.fullpath == c->parser->init_fullpath) {
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
		map_set(&file_scopes, key, scope);
		map_set(&c->info.files, key, f);
	}

	// Collect Entities
	for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
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
	for_array(i, c->procs.entries) {
		ProcedureInfo *pi = &c->procs.entries[i].value;
		if (pi->type == NULL) {
			continue;
		}
		CheckerContext prev_context = c->context;
		defer (c->context = prev_context);

		TypeProc *pt = &pi->type->Proc;
		if (pt->is_polymorphic) {
			if (pi->decl->gen_proc_type == NULL) {
				continue;
			}
		}

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
	}

	// Add untyped expression values
	for_array(i, c->info.untyped.entries) {
		auto *entry = &c->info.untyped.entries[i];
		HashKey key = entry->key;
		AstNode *expr = cast(AstNode *)key.ptr;
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

	/*
	for (isize i = 0; i < gb_count_of(basic_type_aliases)-1; i++) {
		Type *t = &basic_type_aliases[i];
		if (t->Basic.size > 0) {
			add_type_info_type(c, t);
		}
	}
	*/
#endif


	// NOTE(bill): Check for illegal cyclic type declarations
	for_array(i, c->info.definitions.entries) {
		Entity *e = c->info.definitions.entries[i].value;
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
			Scope *s = file_scopes.entries[i].value;
			if (s->is_init) {
				Entity *e = current_scope_lookup_entity(s, str_lit("main"));
				if (e == NULL) {
					Token token = {};
					if (s->file->tokens.count > 0) {
						token = s->file->tokens[0];
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
}
