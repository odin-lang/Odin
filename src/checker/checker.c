#include "../exact_value.c"
#include "entity.c"
#include "types.c"

#define MAP_TYPE Entity *
#define MAP_PROC map_entity_
#define MAP_NAME MapEntity
#include "../map.c"

typedef enum AddressingMode {
	Addressing_Invalid,
	Addressing_NoValue,
	Addressing_Value,
	Addressing_Variable,
	Addressing_Constant,
	Addressing_Type,
	Addressing_Builtin,
	Addressing_Count,
} AddressingMode;

typedef struct Operand {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
	AstNode *      expr;
	BuiltinProcId  builtin_id;
} Operand;

typedef struct TypeAndValue {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
} TypeAndValue;



typedef struct DeclInfo {
	Scope *scope;

	Entity **entities;
	isize    entity_count;

	AstNode *type_expr;
	AstNode *init_expr;
	AstNode *proc_decl; // AstNode_ProcDecl
	u32      var_decl_tags;

	MapBool deps; // Key: Entity *
} DeclInfo;

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

typedef struct ProcedureInfo {
	AstFile * file;
	Token     token;
	DeclInfo *decl;
	Type *    type; // Type_Procedure
	AstNode * body; // AstNode_BlockStmt
	u32       tags;
} ProcedureInfo;

typedef struct Scope {
	Scope *        parent;
	Scope *        prev, *next;
	Scope *        first_child;
	Scope *        last_child;
	MapEntity      elements; // Key: String
	MapEntity      implicit; // Key: String

	Array(Scope *) shared;
	Array(Scope *) imported;
	bool           is_proc;
	bool           is_global;
	bool           is_file;
	bool           is_init;
	AstFile *      file;
} Scope;
gb_global Scope *universal_scope = NULL;

typedef enum ExprKind {
	Expr_Expr,
	Expr_Stmt,
} ExprKind;

typedef enum BuiltinProcId {
	BuiltinProc_Invalid,

	BuiltinProc_new,
	BuiltinProc_new_slice,

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
	BuiltinProc_append,

	BuiltinProc_swizzle,

	// BuiltinProc_ptr_offset,
	// BuiltinProc_ptr_sub,
	BuiltinProc_slice_ptr,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,
	BuiltinProc_clamp,

	BuiltinProc_enum_to_string,

	BuiltinProc_Count,
} BuiltinProcId;
typedef struct BuiltinProc {
	String   name;
	isize    arg_count;
	bool     variadic;
	ExprKind kind;
} BuiltinProc;
gb_global BuiltinProc builtin_procs[BuiltinProc_Count] = {
	{STR_LIT(""),                 0, false, Expr_Stmt},

	{STR_LIT("new"),              1, false, Expr_Expr},
	{STR_LIT("new_slice"),        2, true,  Expr_Expr},

	{STR_LIT("size_of"),          1, false, Expr_Expr},
	{STR_LIT("size_of_val"),      1, false, Expr_Expr},
	{STR_LIT("align_of"),         1, false, Expr_Expr},
	{STR_LIT("align_of_val"),     1, false, Expr_Expr},
	{STR_LIT("offset_of"),        2, false, Expr_Expr},
	{STR_LIT("offset_of_val"),    1, false, Expr_Expr},
	{STR_LIT("type_of_val"),      1, false, Expr_Expr},

	{STR_LIT("type_info"),        1, false, Expr_Expr},
	{STR_LIT("type_info_of_val"), 1, false, Expr_Expr},

	{STR_LIT("compile_assert"),   1, false, Expr_Stmt},
	{STR_LIT("assert"),           1, false, Expr_Stmt},
	{STR_LIT("panic"),            1, false, Expr_Stmt},

	{STR_LIT("copy"),             2, false, Expr_Expr},
	{STR_LIT("append"),           2, false, Expr_Expr},

	{STR_LIT("swizzle"),          1, true,  Expr_Expr},

	// {STR_LIT("ptr_offset"),       2, false, Expr_Expr},
	// {STR_LIT("ptr_sub"),          2, false, Expr_Expr},
	{STR_LIT("slice_ptr"),        2, true,  Expr_Expr},

	{STR_LIT("min"),              2, false, Expr_Expr},
	{STR_LIT("max"),              2, false, Expr_Expr},
	{STR_LIT("abs"),              1, false, Expr_Expr},
	{STR_LIT("clamp"),            3, false, Expr_Expr},

	{STR_LIT("enum_to_string"),   1, false, Expr_Expr},
};

typedef enum ImplicitValueId {
	ImplicitValue_Invalid,

	ImplicitValue_context,

	ImplicitValue_Count,
} ImplicitValueId;
typedef struct ImplicitValueInfo {
	String  name;
	String  backing_name;
	Type *  type;
} ImplicitValueInfo;
// NOTE(bill): This is initialized later
gb_global ImplicitValueInfo implicit_value_infos[ImplicitValue_Count] = {0};



typedef struct CheckerContext {
	Scope *   scope;
	DeclInfo *decl;
	u32       stmt_state_flags;
} CheckerContext;

#define MAP_TYPE TypeAndValue
#define MAP_PROC map_tav_
#define MAP_NAME MapTypeAndValue
#include "../map.c"

#define MAP_TYPE Scope *
#define MAP_PROC map_scope_
#define MAP_NAME MapScope
#include "../map.c"

#define MAP_TYPE DeclInfo *
#define MAP_PROC map_decl_info_
#define MAP_NAME MapDeclInfo
#include "../map.c"

#define MAP_TYPE AstFile *
#define MAP_PROC map_ast_file_
#define MAP_NAME MapAstFile
#include "../map.c"

#define MAP_TYPE ExprInfo
#define MAP_PROC map_expr_info_
#define MAP_NAME MapExprInfo
#include "../map.c"

typedef struct DelayedDecl {
	Scope *  parent;
	AstNode *decl;
} DelayedDecl;


// NOTE(bill): Symbol tables
typedef struct CheckerInfo {
	MapTypeAndValue      types;           // Key: AstNode * | Expression -> Type (and value)
	MapEntity            definitions;     // Key: AstNode * | Identifier -> Entity
	MapEntity            uses;            // Key: AstNode * | Identifier -> Entity
	MapScope             scopes;          // Key: AstNode * | Node       -> Scope
	MapExprInfo          untyped;         // Key: AstNode * | Expression -> ExprInfo
	MapDeclInfo          entities;        // Key: Entity *
	MapEntity            foreign_procs;   // Key: String
	MapAstFile           files;           // Key: String (full path)
	MapIsize             type_info_map;   // Key: Type *
	isize                type_info_count;
	Entity *             implicit_values[ImplicitValue_Count];
	Array(String)        foreign_libraries; // For the linker
} CheckerInfo;

typedef struct Checker {
	Parser *    parser;
	CheckerInfo info;

	AstFile *              curr_ast_file;
	BaseTypeSizes          sizes;
	Scope *                global_scope;
	Array(ProcedureInfo)   procs; // NOTE(bill): Procedures to check
	Array(DelayedDecl)   delayed_imports;
	Array(DelayedDecl)   delayed_foreign_libraries;


	gbArena                arena;
	gbArena                tmp_arena;
	gbAllocator            allocator;
	gbAllocator            tmp_allocator;

	CheckerContext         context;

	Array(Type *)          proc_stack;
	bool                   in_defer; // TODO(bill): Actually handle correctly
	bool                   done_preload;
} Checker;




void init_declaration_info(DeclInfo *d, Scope *scope) {
	d->scope = scope;
	map_bool_init(&d->deps, heap_allocator());
}

DeclInfo *make_declaration_info(gbAllocator a, Scope *scope) {
	DeclInfo *d = gb_alloc_item(a, DeclInfo);
	init_declaration_info(d, scope);
	return d;
}

void destroy_declaration_info(DeclInfo *d) {
	map_bool_destroy(&d->deps);
}

bool decl_info_has_init(DeclInfo *d) {
	if (d->init_expr != NULL) {
		return true;
	}
	if (d->proc_decl != NULL) {
		ast_node(pd, ProcDecl, d->proc_decl);
		if (pd->body != NULL) {
			return true;
		}
	}

	return false;
}





Scope *make_scope(Scope *parent, gbAllocator allocator) {
	Scope *s = gb_alloc_item(allocator, Scope);
	s->parent = parent;
	map_entity_init(&s->elements,   heap_allocator());
	map_entity_init(&s->implicit,   heap_allocator());
	array_init(&s->shared,   heap_allocator());
	array_init(&s->imported, heap_allocator());

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
	map_entity_destroy(&scope->implicit);
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

void scope_lookup_parent_entity(Scope *scope, String name, Scope **scope_, Entity **entity_) {
	bool gone_thru_proc = false;
	bool gone_thru_file = false;
	HashKey key = hash_string(name);
	for (Scope *s = scope; s != NULL; s = s->parent) {
		Entity **found = map_entity_get(&s->elements, key);
		if (found) {
			Entity *e = *found;
			if (gone_thru_proc) {
				if (e->kind == Entity_Variable &&
				    !e->scope->is_file &&
				    !e->scope->is_global) {
					continue;
				}
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

					if (e->kind == Entity_ImportName && gone_thru_file) {
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

Entity *current_scope_lookup_entity(Scope *s, String name) {
	HashKey key = hash_string(name);
	Entity **found = map_entity_get(&s->elements, key);
	if (found) {
		return *found;
	}
	for_array(i, s->shared) {
		Entity **found = map_entity_get(&s->shared.e[i]->elements, key);
		if (found) {
			return *found;
		}
	}
	return NULL;
}



Entity *scope_insert_entity(Scope *s, Entity *entity) {
	String name = entity->token.string;
	HashKey key = hash_string(name);
	Entity **found = map_entity_get(&s->elements, key);
	if (found) {
		return *found;
	}
	map_entity_set(&s->elements, key, entity);
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


void add_global_entity(Entity *entity) {
	String name = entity->token.string;
	if (gb_memchr(name.text, ' ', name.len)) {
		return; // NOTE(bill): `untyped thing`
	}
	if (scope_insert_entity(universal_scope, entity)) {
		compiler_error("double declaration");
	}
}

void add_global_constant(gbAllocator a, String name, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(a, Entity_Constant, NULL, make_token_ident(name), type);
	entity->Constant.value = value;
	add_global_entity(entity);
}


void add_global_string_constant(gbAllocator a, String name, String value) {
	add_global_constant(a, name, t_untyped_string, make_exact_value_string(value));

}


void init_universal_scope(BuildContext *bc) {
	// NOTE(bill): No need to free these
	gbAllocator a = heap_allocator();
	universal_scope = make_scope(NULL, a);

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		add_global_entity(make_entity_type_name(a, NULL, make_token_ident(basic_types[i].Basic.name), &basic_types[i]));
	}
	for (isize i = 0; i < gb_count_of(basic_type_aliases); i++) {
		add_global_entity(make_entity_type_name(a, NULL, make_token_ident(basic_type_aliases[i].Basic.name), &basic_type_aliases[i]));
	}

// Constants
	add_global_constant(a, str_lit("true"),  t_untyped_bool, make_exact_value_bool(true));
	add_global_constant(a, str_lit("false"), t_untyped_bool, make_exact_value_bool(false));

	add_global_entity(make_entity_nil(a, str_lit("nil"), t_untyped_nil));

	// TODO(bill): Set through flags in the compiler
	add_global_string_constant(a, str_lit("ODIN_OS"),      bc->ODIN_OS);
	add_global_string_constant(a, str_lit("ODIN_ARCH"),    bc->ODIN_ARCH);
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


	t_u8_ptr = make_type_pointer(a, t_u8);
	t_int_ptr = make_type_pointer(a, t_int);
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = heap_allocator();
	map_tav_init(&i->types,            a);
	map_entity_init(&i->definitions,   a);
	map_entity_init(&i->uses,          a);
	map_scope_init(&i->scopes,         a);
	map_decl_info_init(&i->entities,   a);
	map_expr_info_init(&i->untyped,    a);
	map_entity_init(&i->foreign_procs, a);
	map_isize_init(&i->type_info_map,  a);
	map_ast_file_init(&i->files,       a);
	array_init(&i->foreign_libraries,  a);
	i->type_info_count = 0;

}

void destroy_checker_info(CheckerInfo *i) {
	map_tav_destroy(&i->types);
	map_entity_destroy(&i->definitions);
	map_entity_destroy(&i->uses);
	map_scope_destroy(&i->scopes);
	map_decl_info_destroy(&i->entities);
	map_expr_info_destroy(&i->untyped);
	map_entity_destroy(&i->foreign_procs);
	map_isize_destroy(&i->type_info_map);
	map_ast_file_destroy(&i->files);
	array_free(&i->foreign_libraries);
}


void init_checker(Checker *c, Parser *parser, BuildContext *bc) {
	gbAllocator a = heap_allocator();

	c->parser = parser;
	init_checker_info(&c->info);
	c->sizes.word_size = bc->word_size;
	c->sizes.max_align = bc->max_align;

	array_init(&c->proc_stack, a);
	array_init(&c->procs, a);
	array_init(&c->delayed_imports, a);
	array_init(&c->delayed_foreign_libraries, a);

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

	gb_arena_free(&c->arena);
}


TypeAndValue *type_and_value_of_expression(CheckerInfo *i, AstNode *expression) {
	TypeAndValue *found = map_tav_get(&i->types, hash_pointer(expression));
	return found;
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

Type *type_of_expr(CheckerInfo *i, AstNode *expression) {
	TypeAndValue *found = type_and_value_of_expression(i, expression);
	if (found) {
		return found->type;
	}
	if (expression->kind == AstNode_Ident) {
		Entity *entity = entity_of_ident(i, expression);
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
	GB_ASSERT(expression != NULL);
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
		HashKey key = hash_pointer(identifier);
		map_entity_set(&i->definitions, key, entity);
	} else {
		// NOTE(bill): Error should handled elsewhere
	}
}

bool add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	if (str_ne(entity->token.string, str_lit("_"))) {
		Entity *insert_entity = scope_insert_entity(scope, entity);
		if (insert_entity) {
			Entity *up = insert_entity->using_parent;
			if (up != NULL) {
				error(entity->token,
				      "Redeclararation of `%.*s` in this scope through `using`\n"
				      "\tat %.*s(%td:%td)",
				      LIT(entity->token.string),
				      LIT(up->token.pos.file), up->token.pos.line, up->token.pos.column);
				return false;
			} else {
				TokenPos pos = insert_entity->token.pos;
				if (token_pos_eq(pos, entity->token.pos)) {
					// NOTE(bill): Error should have been handled already
					return false;
				}
				error(entity->token,
				      "Redeclararation of `%.*s` in this scope\n"
				      "\tat %.*s(%td:%td)",
				      LIT(entity->token.string),
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
	map_entity_set(&c->info.uses, hash_pointer(identifier), entity);
	add_declaration_dependency(c, entity); // TODO(bill): Should this be here?
}


void add_entity_and_decl_info(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(identifier->kind == AstNode_Ident);
	GB_ASSERT(str_eq(identifier->Ident.string, e->token.string));
	add_entity(c, e->scope, identifier, e);
	map_decl_info_set(&c->info.entities, hash_pointer(e), d);
}

// NOTE(bill): Returns true if it's added
bool try_add_foreign_library_path(Checker *c, String import_file) {
	for_array(i, c->info.foreign_libraries) {
		String import = c->info.foreign_libraries.e[i];
		if (str_eq(import, import_file)) {
			return false;
		}
	}
	array_add(&c->info.foreign_libraries, import_file);
	return true;
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
		}
	} break;

	case Type_Maybe:
		add_type_info_type(c, bt->Maybe.elem);
		add_type_info_type(c, t_bool);
		break;

	case Type_Pointer:
		add_type_info_type(c, bt->Pointer.elem);
		break;

	case Type_Array:
		add_type_info_type(c, bt->Array.elem);
		add_type_info_type(c, make_type_pointer(c->allocator, bt->Array.elem));
		add_type_info_type(c, t_int);
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
			add_type_info_type(c, bt->Record.enum_base);
			break;

		case TypeRecord_Union:
			add_type_info_type(c, t_int);
			/* fallthrough */
		default:
			for (isize i = 0; i < bt->Record.field_count; i++) {
				Entity *f = bt->Record.fields[i];
				add_type_info_type(c, f->type);
			}
			break;
		}
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

Type *const curr_procedure(Checker *c) {
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
		c->context.decl = file->decl_info;
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

	for_array(i, info->entities.entries) {
		MapDeclInfoEntry *entry = &info->entities.entries.e[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
		if (e->scope->is_global) {
			// NOTE(bill): Require runtime stuff
			add_dependency_to_map(&map, info, e);
		}
	}

	add_dependency_to_map(&map, info, start);

	return map;
}


void add_implicit_value(Checker *c, ImplicitValueId id, String name, String backing_name, Type *type) {
	ImplicitValueInfo info = {name, backing_name, type};
	Entity *value = make_entity_implicit_value(c->allocator, info.name, info.type, id);
	Entity *prev = scope_insert_entity(c->global_scope, value);
	GB_ASSERT(prev == NULL);
	implicit_value_infos[id] = info;
	c->info.implicit_values[id] = value;
}


void init_preload(Checker *c) {
	if (c->done_preload) {
		return;
	}

	if (t_type_info == NULL) {
		Entity *e = current_scope_lookup_entity(c->global_scope, str_lit("Type_Info"));
		if (e == NULL) {
			compiler_error("Could not find type declaration for `Type_Info`\n"
			               "Is `runtime.odin` missing from the `core` directory relative to odin.exe?");
		}
		t_type_info = e->type;
		t_type_info_ptr = make_type_pointer(c->allocator, t_type_info);
		GB_ASSERT(is_type_union(e->type));
		TypeRecord *record = &base_type(e->type)->Record;

		t_type_info_member = record->other_fields[0]->type;
		t_type_info_member_ptr = make_type_pointer(c->allocator, t_type_info_member);

		if (record->field_count != 18) {
			compiler_error("Invalid `Type_Info` layout");
		}
		t_type_info_named     = record->fields[ 1]->type;
		t_type_info_integer   = record->fields[ 2]->type;
		t_type_info_float     = record->fields[ 3]->type;
		t_type_info_any       = record->fields[ 4]->type;
		t_type_info_string    = record->fields[ 5]->type;
		t_type_info_boolean   = record->fields[ 6]->type;
		t_type_info_pointer   = record->fields[ 7]->type;
		t_type_info_maybe     = record->fields[ 8]->type;
		t_type_info_procedure = record->fields[ 9]->type;
		t_type_info_array     = record->fields[10]->type;
		t_type_info_slice     = record->fields[11]->type;
		t_type_info_vector    = record->fields[12]->type;
		t_type_info_tuple     = record->fields[13]->type;
		t_type_info_struct    = record->fields[14]->type;
		t_type_info_union     = record->fields[15]->type;
		t_type_info_raw_union = record->fields[16]->type;
		t_type_info_enum      = record->fields[17]->type;
	}

	if (t_allocator == NULL) {
		Entity *e = current_scope_lookup_entity(c->global_scope, str_lit("Allocator"));
		if (e == NULL) {
			compiler_error("Could not find type declaration for `Allocator`\n"
			               "Is `runtime.odin` missing from the `core` directory relative to odin.exe?");
		}
		t_allocator = e->type;
		t_allocator_ptr = make_type_pointer(c->allocator, t_allocator);
	}

	if (t_context == NULL) {
		Entity *e = current_scope_lookup_entity(c->global_scope, str_lit("Context"));
		if (e == NULL) {
			compiler_error("Could not find type declaration for `Context`\n"
			               "Is `runtime.odin` missing from the `core` directory relative to odin.exe?");
		}
		t_context = e->type;
		t_context_ptr = make_type_pointer(c->allocator, t_context);
	}

	c->done_preload = true;
}





#include "expr.c"
#include "decl.c"
#include "stmt.c"

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

		if (e->kind != Entity_Procedure && str_eq(e->token.string, str_lit("main"))) {
			if (e->scope->is_init) {
				error(e->token, "`main` is reserved as the entry point procedure in the initial scope");
				continue;
			}
		} else if (e->scope->is_global && str_eq(e->token.string, str_lit("main"))) {
			error(e->token, "`main` is reserved as the entry point procedure in the initial scope");
			continue;
		}

		Scope *prev_scope = c->context.scope;
		c->context.scope = d->scope;
		check_entity_decl(c, e, d, NULL);


		if (d->scope->is_init && !c->done_preload) {
			init_preload(c);
		}
	}
}

void check_global_collect_entities_from_file(Checker *c, Scope *parent_scope, AstNodeArray nodes, MapScope *file_scopes) {
	for_array(decl_index, nodes) {
		AstNode *decl = nodes.e[decl_index];
		if (!is_ast_node_decl(decl) && !is_ast_node_when_stmt(decl)) {
			continue;
		}

		switch (decl->kind) {
		case_ast_node(bd, BadDecl, decl);
		case_end;
		case_ast_node(id, ImportDecl, decl);
			if (!parent_scope->is_file) {
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}
			DelayedDecl di = {parent_scope, decl};
			array_add(&c->delayed_imports, di);
		case_end;
		case_ast_node(fl, ForeignLibrary, decl);
			if (!parent_scope->is_file) {
				// NOTE(bill): _Should_ be caught by the parser
				// TODO(bill): Better error handling if it isn't
				continue;
			}

			DelayedDecl di = {parent_scope, decl};
			array_add(&c->delayed_foreign_libraries, di);
		case_end;
		case_ast_node(cd, ConstDecl, decl);
			for_array(i, cd->values) {
				AstNode *name = cd->names.e[i];
				AstNode *value = cd->values.e[i];
				ExactValue v = {ExactValue_Invalid};
				if (name->kind != AstNode_Ident) {
					error_node(name, "A declaration's name but be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
				}
				Entity *e = make_entity_constant(c->allocator, parent_scope, name->Ident, NULL, v);
				e->identifier = name;
				DeclInfo *di = make_declaration_info(c->allocator, parent_scope);
				di->type_expr = cd->type;
				di->init_expr = value;
				add_entity_and_decl_info(c, name, e, di);
			}

			isize lhs_count = cd->names.count;
			isize rhs_count = cd->values.count;

			if (rhs_count == 0 && cd->type == NULL) {
				error_node(decl, "Missing type or initial expression");
			} else if (lhs_count < rhs_count) {
				error_node(decl, "Extra initial expression");
			}
		case_end;
		case_ast_node(vd, VarDecl, decl);
			if (!parent_scope->is_file) {
				// NOTE(bill): Within a procedure, variables must be in order
				continue;
			}

			// NOTE(bill): You need to store the entity information here unline a constant declaration
			isize entity_count = vd->names.count;
			isize entity_index = 0;
			Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_count);
			DeclInfo *di = NULL;
			if (vd->values.count > 0) {
				di = make_declaration_info(heap_allocator(), parent_scope);
				di->entities = entities;
				di->entity_count = entity_count;
				di->type_expr = vd->type;
				di->init_expr = vd->values.e[0];
			}

			for_array(i, vd->names) {
				AstNode *name = vd->names.e[i];
				AstNode *value = NULL;
				if (i < vd->values.count) {
					value = vd->values.e[i];
				}
				if (name->kind != AstNode_Ident) {
					error_node(name, "A declaration's name but be an identifier, got %.*s", LIT(ast_node_strings[name->kind]));
				}
				Entity *e = make_entity_variable(c->allocator, parent_scope, name->Ident, NULL);
				e->identifier = name;
				entities[entity_index++] = e;

				DeclInfo *d = di;
				if (d == NULL) {
					AstNode *init_expr = value;
					d = make_declaration_info(heap_allocator(), parent_scope);
					d->type_expr = vd->type;
					d->init_expr = init_expr;
					d->var_decl_tags = vd->tags;
				}

				add_entity_and_decl_info(c, name, e, d);
			}
		case_end;
		case_ast_node(td, TypeDecl, decl);
			ast_node(n, Ident, td->name);
			Entity *e = make_entity_type_name(c->allocator, parent_scope, *n, NULL);
			e->identifier = td->name;
			DeclInfo *d = make_declaration_info(c->allocator, e->scope);
			d->type_expr = td->type;
			add_entity_and_decl_info(c, td->name, e, d);
		case_end;
		case_ast_node(pd, ProcDecl, decl);
			ast_node(n, Ident, pd->name);
			Token token = *n;
			Entity *e = make_entity_procedure(c->allocator, parent_scope, token, NULL);
			e->identifier = pd->name;
			DeclInfo *d = make_declaration_info(c->allocator, e->scope);
			d->proc_decl = decl;
			add_entity_and_decl_info(c, pd->name, e, d);
		case_end;

		default:
			if (parent_scope->is_file) {
				error_node(decl, "Only declarations are allowed at file scope");
			}
			break;
		}
	}
}

void check_import_entities(Checker *c, MapScope *file_scopes) {
	for_array(i, c->delayed_imports) {
		Scope *parent_scope = c->delayed_imports.e[i].parent;
		AstNode *decl = c->delayed_imports.e[i].decl;
		ast_node(id, ImportDecl, decl);

		HashKey key = hash_string(id->fullpath);
		Scope **found = map_scope_get(file_scopes, key);
		if (found == NULL) {
			for_array(scope_index, file_scopes->entries) {
				Scope *scope = file_scopes->entries.e[scope_index].value;
				gb_printf_err("%.*s\n", LIT(scope->file->tokenizer.fullpath));
			}
			gb_printf_err("%.*s(%td:%td)\n", LIT(id->token.pos.file), id->token.pos.line, id->token.pos.column);
			GB_PANIC("Unable to find scope for file: %.*s", LIT(id->fullpath));
		}
		Scope *scope = *found;

		if (scope->is_global) {
			error(id->token, "Importing a #shared_global_scope is disallowed and unnecessary");
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
			warning(id->token, "Multiple #import of the same file within this scope");
		}

		if (str_eq(id->import_name.string, str_lit("."))) {
			// NOTE(bill): Add imported entities to this file's scope
			for_array(elem_index, scope->elements.entries) {
				Entity *e = scope->elements.entries.e[elem_index].value;
				if (e->scope == parent_scope) {
					continue;
				}



				// NOTE(bill): Do not add other imported entities
				add_entity(c, parent_scope, NULL, e);
				if (!id->is_load) { // `#import`ed entities don't get exported
					HashKey key = hash_string(e->token.string);
					map_entity_set(&parent_scope->implicit, key, e);
				}
			}
		} else {
			String import_name = id->import_name.string;
			if (import_name.len == 0) {
				// NOTE(bill): use file name (without extension) as the identifier
				// If it is a valid identifier
				String filename = id->fullpath;
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
					import_name = filename;
				} else {
					error(id->token,
					      "File name, %.*s, cannot be as an import name as it is not a valid identifier",
					      LIT(filename));
				}
			}

			if (import_name.len > 0) {
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

		try_add_foreign_library_path(c, file_str);
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

		f->scope = scope;
		f->decl_info = make_declaration_info(c->allocator, f->scope);
		HashKey key = hash_string(f->tokenizer.fullpath);
		map_scope_set(&file_scopes, key, scope);
		map_ast_file_set(&c->info.files, key, f);
	}

	// Collect Entities
	for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files.e[i];
		add_curr_ast_file(c, f);
		check_global_collect_entities_from_file(c, f->scope, f->decls, &file_scopes);
	}

	check_import_entities(c, &file_scopes);

	map_scope_destroy(&file_scopes);

	check_all_global_entities(c);
	init_preload(c); // NOTE(bill): This could be setup previously through the use of `type_info(_of_val)`
	// NOTE(bill): Nothing is the global scope _should_ depend on this implicit value as implicit
	// values are only useful within procedures
	add_implicit_value(c, ImplicitValue_context, str_lit("context"), str_lit("__context"), t_context);

	// Initialize implicit values with backing variables
	// TODO(bill): Are implicit values "too implicit"?
	for (isize i = 1; i < ImplicitValue_Count; i++) {
		// NOTE(bill): 0th is invalid
		Entity *e = c->info.implicit_values[i];
		GB_ASSERT(e->kind == Entity_ImplicitValue);

		ImplicitValueInfo *ivi = &implicit_value_infos[i];
		Entity *backing = scope_lookup_entity(e->scope, ivi->backing_name);
		GB_ASSERT(backing != NULL);
		e->ImplicitValue.backing = backing;
	}


	// Check procedure bodies
	// NOTE(bill): Nested procedures bodies will be added to this "queue"
	for_array(i, c->procs) {
		ProcedureInfo *pi = &c->procs.e[i];
		add_curr_ast_file(c, pi->file);

		bool bounds_check    = (pi->tags & ProcTag_bounds_check)    != 0;
		bool no_bounds_check = (pi->tags & ProcTag_no_bounds_check) != 0;

		CheckerContext prev_context = c->context;

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

	// NOTE(bill): Check for illegal cyclic type declarations
	for_array(i, c->info.definitions.entries) {
		Entity *e = c->info.definitions.entries.e[i].value;
		if (e->kind == Entity_TypeName) {
			// i64 size  = type_size_of(c->sizes, c->allocator, e->type);
			i64 align = type_align_of(c->sizes, c->allocator, e->type);
		}
	}
}



