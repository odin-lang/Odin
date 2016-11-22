#include "../exact_value.cpp"
#include "entity.cpp"
#include "types.cpp"

enum AddressingMode {
	Addressing_Invalid,
	Addressing_NoValue,
	Addressing_Value,
	Addressing_Variable,
	Addressing_Constant,
	Addressing_Type,
	Addressing_Builtin,
	Addressing_Count,
};

struct Operand {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
	AstNode *      expr;
	BuiltinProcId  builtin_id;
};

struct TypeAndValue {
	AddressingMode mode;
	Type *         type;
	ExactValue     value;
};

struct DeclInfo {
	Scope *scope;

	Entity **entities;
	isize    entity_count;

	AstNode *type_expr;
	AstNode *init_expr;
	AstNode *proc_decl; // AstNode_ProcDecl
	u32      var_decl_tags;

	Map<b32> deps; // Key: Entity *
};

struct ExpressionInfo {
	b32            is_lhs; // Debug info
	AddressingMode mode;
	Type *         type; // Type_Basic
	ExactValue     value;
};

ExpressionInfo make_expression_info(b32 is_lhs, AddressingMode mode, Type *type, ExactValue value) {
	ExpressionInfo ei = {is_lhs, mode, type, value};
	return ei;
}

struct ProcedureInfo {
	AstFile * file;
	Token     token;
	DeclInfo *decl;
	Type *    type; // Type_Procedure
	AstNode * body; // AstNode_BlockStatement
	u32       tags;
};

struct Scope {
	Scope *        parent;
	Scope *        prev, *next;
	Scope *        first_child;
	Scope *        last_child;
	Map<Entity *>  elements; // Key: String
	Map<Entity *>  implicit; // Key: String

	Array(Scope *) shared;
	Array(Scope *) imported;
	b32            is_proc;
	b32            is_global;
	b32            is_file;
	b32            is_init;
	AstFile *      file;
};
gb_global Scope *universal_scope = NULL;

enum ExprKind {
	Expr_Expr,
	Expr_Stmt,
};

enum BuiltinProcId {
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

	BuiltinProc_enum_to_string,

	BuiltinProc_Count,
};
struct BuiltinProc {
	String   name;
	isize    arg_count;
	b32      variadic;
	ExprKind kind;
};
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

	{STR_LIT("enum_to_string"),   1, false, Expr_Expr},
};

enum ImplicitValueId {
	ImplicitValue_Invalid,

	ImplicitValue_context,

	ImplicitValue_Count,
};
struct ImplicitValueInfo {
	String  name;
	String  backing_name;
	Type *  type;
};
// NOTE(bill): This is initialized later
gb_global ImplicitValueInfo implicit_value_infos[ImplicitValue_Count] = {};



struct CheckerContext {
	Scope *   scope;
	DeclInfo *decl;
	u32       stmt_state_flags;
};

// NOTE(bill): Symbol tables
struct CheckerInfo {
	Map<TypeAndValue>      types;           // Key: AstNode * | Expression -> Type (and value)
	Map<Entity *>          definitions;     // Key: AstNode * | Identifier -> Entity
	Map<Entity *>          uses;            // Key: AstNode * | Identifier -> Entity
	Map<Scope *>           scopes;          // Key: AstNode * | Node       -> Scope
	Map<ExpressionInfo>    untyped;         // Key: AstNode * | Expression -> ExpressionInfo
	Map<DeclInfo *>        entities;        // Key: Entity *
	Map<Entity *>          foreign_procs;   // Key: String
	Map<AstFile *>         files;           // Key: String (full path)
	Map<isize>             type_info_map;   // Key: Type *
	isize                  type_info_count;
	Entity *               implicit_values[ImplicitValue_Count];
};

struct Checker {
	Parser *    parser;
	CheckerInfo info;

	AstFile *              curr_ast_file;
	BaseTypeSizes          sizes;
	Scope *                global_scope;
	Array(ProcedureInfo)   procs; // NOTE(bill): Procedures to check

	gbArena                arena;
	gbArena                tmp_arena;
	gbAllocator            allocator;
	gbAllocator            tmp_allocator;

	CheckerContext         context;

	Array(Type *)          proc_stack;
	b32                    in_defer; // TODO(bill): Actually handle correctly
};

struct CycleChecker {
	Array(Entity *) path; // Entity_TypeName
};




CycleChecker *cycle_checker_add(CycleChecker *cc, Entity *e) {
	if (cc == NULL) {
		return NULL;
	}
	if (cc->path.e == NULL) {
		array_init(&cc->path, heap_allocator());
	}
	GB_ASSERT(e != NULL && e->kind == Entity_TypeName);
	array_add(&cc->path, e);
	return cc;
}

void cycle_checker_destroy(CycleChecker *cc) {
	if (cc != NULL && cc->path.e != NULL)  {
		array_free(&cc->path);
	}
}


void init_declaration_info(DeclInfo *d, Scope *scope) {
	d->scope = scope;
	map_init(&d->deps, heap_allocator());
}

DeclInfo *make_declaration_info(gbAllocator a, Scope *scope) {
	DeclInfo *d = gb_alloc_item(a, DeclInfo);
	init_declaration_info(d, scope);
	return d;
}

void destroy_declaration_info(DeclInfo *d) {
	map_destroy(&d->deps);
}

b32 decl_info_has_init(DeclInfo *d) {
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

	map_destroy(&scope->elements);
	map_destroy(&scope->implicit);
	array_free(&scope->shared);
	array_free(&scope->imported);

	// NOTE(bill): No need to free scope as it "should" be allocated in an arena (except for the global scope)
}

void add_scope(Checker *c, AstNode *node, Scope *scope) {
	GB_ASSERT(node != NULL);
	GB_ASSERT(scope != NULL);
	map_set(&c->info.scopes, hash_pointer(node), scope);
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
	b32 gone_thru_proc = false;
	HashKey key = hash_string(name);
	for (Scope *s = scope; s != NULL; s = s->parent) {
		Entity **found = map_get(&s->elements, key);
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
				Entity **found = map_get(&shared->elements, key);
				if (found) {
					Entity *e = *found;
					if (e->kind == Entity_Variable &&
					    !e->scope->is_file &&
					    !e->scope->is_global) {
						continue;
					}

					if (e->scope != shared) {
						// Do not return imported entities even #load ones
						continue;
					}
					if (!is_entity_exported(e)) {
						continue;
					}
					if (entity_) *entity_ = e;
					if (scope_) *scope_ = shared;
					return;
				}
			}
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
	Entity **found = map_get(&s->elements, key);
	if (found) {
		return *found;
	}
	for_array(i, s->shared) {
		Entity **found = map_get(&s->shared.e[i]->elements, key);
		if (found) {
			return *found;
		}
	}
	return NULL;
}



Entity *scope_insert_entity(Scope *s, Entity *entity) {
	String name = entity->token.string;
	HashKey key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found) {
		return *found;
	}
	map_set(&s->elements, key, entity);
	if (entity->scope == NULL) {
		entity->scope = s;
	}
	return NULL;
}

void check_scope_usage(Checker *c, Scope *scope) {
	// TODO(bill): Use this?
#if 0
	for_array(i, scope->elements.entries) {
		auto *entry = scope->elements.entries + i;
		Entity *e = entry->value;
		if (e->kind == Entity_Variable) {
			auto *v = &e->Variable;
			if (!v->is_field && !v->used) {
				warning(e->token, "Unused variable: %.*s", LIT(e->token.string));
			}
		}
	}

	for (Scope *child = scope->first_child; child != NULL; child = child->next) {
		check_scope_usage(c, child);
	}
#endif
}


void add_dependency(DeclInfo *d, Entity *e) {
	map_set(&d->deps, hash_pointer(e), cast(b32)true);
}

void add_declaration_dependency(Checker *c, Entity *e) {
	if (e == NULL) {
		return;
	}
	if (c->context.decl != NULL) {
		auto found = map_get(&c->info.entities, hash_pointer(e));
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



void init_universal_scope(void) {
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
	map_init(&i->types,           a);
	map_init(&i->definitions,     a);
	map_init(&i->uses,            a);
	map_init(&i->scopes,          a);
	map_init(&i->entities,        a);
	map_init(&i->untyped,         a);
	map_init(&i->foreign_procs,   a);
	map_init(&i->type_info_map,   a);
	map_init(&i->files,           a);
	i->type_info_count = 0;

}

void destroy_checker_info(CheckerInfo *i) {
	map_destroy(&i->types);
	map_destroy(&i->definitions);
	map_destroy(&i->uses);
	map_destroy(&i->scopes);
	map_destroy(&i->entities);
	map_destroy(&i->untyped);
	map_destroy(&i->foreign_procs);
	map_destroy(&i->type_info_map);
	map_destroy(&i->files);
}


void init_checker(Checker *c, Parser *parser, BaseTypeSizes sizes) {
	PROF_PROC();

	gbAllocator a = heap_allocator();

	c->parser = parser;
	init_checker_info(&c->info);
	c->sizes = sizes;

	array_init(&c->proc_stack, a);
	array_init(&c->procs, a);

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

	gb_arena_free(&c->arena);
}


TypeAndValue *type_and_value_of_expression(CheckerInfo *i, AstNode *expression) {
	TypeAndValue *found = map_get(&i->types, hash_pointer(expression));
	return found;
}


Entity *entity_of_ident(CheckerInfo *i, AstNode *identifier) {
	if (identifier->kind == AstNode_Ident) {
		Entity **found = map_get(&i->definitions, hash_pointer(identifier));
		if (found) {
			return *found;
		}
		found = map_get(&i->uses, hash_pointer(identifier));
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


void add_untyped(CheckerInfo *i, AstNode *expression, b32 lhs, AddressingMode mode, Type *basic_type, ExactValue value) {
	map_set(&i->untyped, hash_pointer(expression), make_expression_info(lhs, mode, basic_type, value));
}

void add_type_and_value(CheckerInfo *i, AstNode *expression, AddressingMode mode, Type *type, ExactValue value) {
	GB_ASSERT(expression != NULL);
	if (mode == Addressing_Invalid) {
		return;
	}

	if (mode == Addressing_Constant) {
		if (is_type_constant_type(type)) {
			GB_ASSERT(value.kind != ExactValue_Invalid);
			if (!(type != t_invalid || is_type_constant_type(type))) {
				compiler_error("add_type_and_value - invalid type: %s", type_to_string(type));
			}
		}
	}

	TypeAndValue tv = {};
	tv.type  = type;
	tv.value = value;
	tv.mode  = mode;
	map_set(&i->types, hash_pointer(expression), tv);
}

void add_entity_definition(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	if (identifier->kind == AstNode_Ident) {
		GB_ASSERT(identifier->kind == AstNode_Ident);
		HashKey key = hash_pointer(identifier);
		map_set(&i->definitions, key, entity);
	} else {
		// NOTE(bill): Error should handled elsewhere
	}
}

b32 add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
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
				if (token_pos_are_equal(pos, entity->token.pos)) {
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
	map_set(&c->info.uses, hash_pointer(identifier), entity);
	add_declaration_dependency(c, entity); // TODO(bill): Should this be here?
}


void add_entity_and_decl_info(Checker *c, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(str_eq(identifier->Ident.string, e->token.string));
	add_entity(c, e->scope, identifier, e);
	map_set(&c->info.entities, hash_pointer(e), d);
}

void add_type_info_type(Checker *c, Type *t) {
	if (t == NULL) {
		return;
	}
	t = default_type(t);
	if (is_type_untyped(t)) {
		return; // Could be nil
	}

	if (map_get(&c->info.type_info_map, hash_pointer(t)) != NULL) {
		// Types have already been added
		return;
	}

	isize ti_index = -1;
	for_array(i, c->info.type_info_map.entries) {
		auto *e = &c->info.type_info_map.entries.e[i];
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
	map_set(&c->info.type_info_map, hash_pointer(t), ti_index);




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
	ProcedureInfo info = {};
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
	TokenPos zero_pos = {};
	global_error_collector.prev = zero_pos;
	c->curr_ast_file = file;
	c->context.decl = file->decl_info;
}




void add_dependency_to_map(Map<Entity *> *map, CheckerInfo *info, Entity *node) {
	if (node == NULL) {
		return;
	}
	if (map_get(map, hash_pointer(node)) != NULL) {
		return;
	}
	map_set(map, hash_pointer(node), node);


	DeclInfo **found = map_get(&info->entities, hash_pointer(node));
	if (found == NULL) {
		return;
	}

	DeclInfo *decl = *found;
	for_array(i, decl->deps.entries) {
		Entity *e = cast(Entity *)decl->deps.entries.e[i].key.ptr;
		add_dependency_to_map(map, info, e);
	}
}

Map<Entity *> generate_minimum_dependency_map(CheckerInfo *info, Entity *start) {
	Map<Entity *> map = {}; // Key: Entity *
	map_init(&map, heap_allocator());

	for_array(i, info->entities.entries) {
		auto *entry = &info->entities.entries.e[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
		if (e->scope->is_global) {
			// NOTE(bill): Require runtime stuff
			add_dependency_to_map(&map, info, e);
		}
	}

	add_dependency_to_map(&map, info, start);

	return map;
}




#include "expr.cpp"
#include "decl.cpp"
#include "stmt.cpp"

void init_preload_types(Checker *c) {
	PROF_PROC();


	if (t_type_info == NULL) {
		Entity *e = current_scope_lookup_entity(c->global_scope, str_lit("Type_Info"));
		if (e == NULL) {
			compiler_error("Could not find type declaration for `Type_Info`\n"
			               "Is `runtime.odin` missing from the `core` directory relative to odin.exe?");
		}
		t_type_info = e->type;
		t_type_info_ptr = make_type_pointer(c->allocator, t_type_info);
		GB_ASSERT(is_type_union(e->type));
		auto *record = &base_type(e->type)->Record;

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

}

void add_implicit_value(Checker *c, ImplicitValueId id, String name, String backing_name, Type *type) {
	ImplicitValueInfo info = {name, backing_name, type};
	Entity *value = make_entity_implicit_value(c->allocator, info.name, info.type, id);
	Entity *prev = scope_insert_entity(c->global_scope, value);
	GB_ASSERT(prev == NULL);
	implicit_value_infos[id] = info;
	c->info.implicit_values[id] = value;
}


void check_global_entity(Checker *c, EntityKind kind) {
	PROF_SCOPED("check_global_entity");
	for_array(i, c->info.entities.entries) {
		auto *entry = &c->info.entities.entries.e[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
		if (e->kind == kind) {
			DeclInfo *d = entry->value;

			add_curr_ast_file(c, d->scope->file);

			if (d->scope == e->scope) {
				if (kind != Entity_Procedure && str_eq(e->token.string, str_lit("main"))) {
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
			}
		}
	}
}

void check_parsed_files(Checker *c) {
	AstNodeArray import_decls;
	array_init(&import_decls, heap_allocator());

	Map<Scope *> file_scopes; // Key: String (fullpath)
	map_init(&file_scopes, heap_allocator());

	// Map full filepaths to Scopes
	for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files.e[i];
		Scope *scope = NULL;
		scope = make_scope(c->global_scope, c->allocator);
		scope->is_global = f->is_global_scope;
		scope->is_file   = true;
		scope->file      = f;
		if (i == 0) {
			// NOTE(bill): First file is always the initial file
			// thus it must contain main
			scope->is_init = true;
		}

		if (scope->is_global) {
			array_add(&c->global_scope->shared, scope);
		}

		f->scope = scope;
		f->decl_info = make_declaration_info(c->allocator, f->scope);
		HashKey key = hash_string(f->tokenizer.fullpath);
		map_set(&file_scopes, key, scope);
		map_set(&c->info.files, key, f);
	}

	// Collect Entities
	for_array(i, c->parser->files) {
		PROF_SCOPED("Collect Entities");

		AstFile *f = &c->parser->files.e[i];
		add_curr_ast_file(c, f);

		Scope *file_scope = f->scope;

		for_array(decl_index, f->decls) {
			AstNode *decl = f->decls.e[decl_index];
			if (!is_ast_node_decl(decl)) {
				continue;
			}

			switch (decl->kind) {
			case_ast_node(bd, BadDecl, decl);
			case_end;
			case_ast_node(id, ImportDecl, decl);
				// NOTE(bill): Handle later
			case_end;
			case_ast_node(fsl, ForeignLibrary, decl);
				// NOTE(bill): ignore
			case_end;

			case_ast_node(cd, ConstDecl, decl);
				for_array(i, cd->values) {
					AstNode *name = cd->names.e[i];
					AstNode *value = cd->values.e[i];
					ExactValue v = {ExactValue_Invalid};
					Entity *e = make_entity_constant(c->allocator, file_scope, name->Ident, NULL, v);
					e->identifier = name;
					DeclInfo *di = make_declaration_info(c->allocator, file_scope);
					di->type_expr = cd->type;
					di->init_expr = value;
					add_entity_and_decl_info(c, name, e, di);
				}

				isize lhs_count = cd->names.count;
				isize rhs_count = cd->values.count;

				if (rhs_count == 0 && cd->type == NULL) {
					error(ast_node_token(decl), "Missing type or initial expression");
				} else if (lhs_count < rhs_count) {
					error(ast_node_token(decl), "Extra initial expression");
				}
			case_end;

			case_ast_node(vd, VarDecl, decl);
				isize entity_count = vd->names.count;
				isize entity_index = 0;
				Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_count);
				DeclInfo *di = NULL;
				if (vd->values.count > 0) {
					di = make_declaration_info(heap_allocator(), file_scope);
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
					Entity *e = make_entity_variable(c->allocator, file_scope, name->Ident, NULL);
					e->identifier = name;
					entities[entity_index++] = e;

					DeclInfo *d = di;
					if (d == NULL) {
						AstNode *init_expr = value;
						d = make_declaration_info(heap_allocator(), file_scope);
						d->type_expr = vd->type;
						d->init_expr = init_expr;
						d->var_decl_tags = vd->tags;
					}

					add_entity_and_decl_info(c, name, e, d);
				}
			case_end;

			case_ast_node(td, TypeDecl, decl);
				ast_node(n, Ident, td->name);
				Entity *e = make_entity_type_name(c->allocator, file_scope, *n, NULL);
				e->identifier = td->name;
				DeclInfo *d = make_declaration_info(c->allocator, e->scope);
				d->type_expr = td->type;
				add_entity_and_decl_info(c, td->name, e, d);
			case_end;

			case_ast_node(pd, ProcDecl, decl);
				ast_node(n, Ident, pd->name);
				Token token = *n;
				Entity *e = make_entity_procedure(c->allocator, file_scope, token, NULL);
				e->identifier = pd->name;
				DeclInfo *d = make_declaration_info(c->allocator, e->scope);
				d->proc_decl = decl;
				add_entity_and_decl_info(c, pd->name, e, d);
			case_end;

			default:
				error(ast_node_token(decl), "Only declarations are allowed at file scope");
				break;
			}
		}
	}

	for_array(i, c->parser->files) {
		PROF_SCOPED("Import Entities");

		AstFile *f = &c->parser->files.e[i];
		add_curr_ast_file(c, f);

		Scope *file_scope = f->scope;

		for_array(decl_index, f->decls) {
			AstNode *decl = f->decls.e[decl_index];
			if (decl->kind != AstNode_ImportDecl) {
				continue;
			}
			ast_node(id, ImportDecl, decl);

			HashKey key = hash_string(id->fullpath);
			auto found = map_get(&file_scopes, key);
			GB_ASSERT_MSG(found != NULL, "Unable to find scope for file: %.*s", LIT(id->fullpath));
			Scope *scope = *found;

			if (scope->is_global) {
				error(id->token, "Importing a #shared_global_scope is disallowed and unnecessary");
				continue;
			}

			b32 previously_added = false;
			for_array(import_index, file_scope->imported) {
				Scope *prev = file_scope->imported.e[import_index];
				if (prev == scope) {
					previously_added = true;
					break;
				}
			}

			if (!previously_added) {
				array_add(&file_scope->imported, scope);
			} else {
				warning(id->token, "Multiple #import of the same file within this scope");
			}

			if (str_eq(id->import_name.string, str_lit("."))) {
				// NOTE(bill): Add imported entities to this file's scope
				for_array(elem_index, scope->elements.entries) {
					Entity *e = scope->elements.entries.e[elem_index].value;
					if (e->scope == file_scope) {
						continue;
					}
					// NOTE(bill): Do not add other imported entities
					if (is_entity_exported(e)) {
						add_entity(c, file_scope, NULL, e);
						if (!id->is_load) { // `#import`ed entities don't get exported
							HashKey key = hash_string(e->token.string);
							map_set(&file_scope->implicit, key, e);
						}
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
						error(ast_node_token(decl),
						      "File name, %.*s, cannot be as an import name as it is not a valid identifier",
						      LIT(filename));
					}
				}

				if (import_name.len > 0) {
					id->import_name.string = import_name;
					Entity *e = make_entity_import_name(c->allocator, file_scope, id->import_name, t_invalid,
					                                    id->fullpath, id->import_name.string,
					                                    scope);
					add_entity(c, file_scope, NULL, e);
				}
			}
		}
	}

	check_global_entity(c, Entity_TypeName);

	init_preload_types(c);
	add_implicit_value(c, ImplicitValue_context, str_lit("context"), str_lit("__context"), t_context);

	check_global_entity(c, Entity_Constant);
	check_global_entity(c, Entity_Procedure);
	check_global_entity(c, Entity_Variable);

	for (isize i = 1; i < ImplicitValue_Count; i++) {
		// NOTE(bill): First is invalid
		Entity *e = c->info.implicit_values[i];
		GB_ASSERT(e->kind == Entity_ImplicitValue);

		ImplicitValueInfo *ivi = &implicit_value_infos[i];
		Entity *backing = scope_lookup_entity(e->scope, ivi->backing_name);
		GB_ASSERT(backing != NULL);
		e->ImplicitValue.backing = backing;
	}


	// Check procedure bodies
	for_array(i, c->procs) {
		ProcedureInfo *pi = &c->procs.e[i];
		add_curr_ast_file(c, pi->file);

		b32 bounds_check    = (pi->tags & ProcTag_bounds_check)    != 0;
		b32 no_bounds_check = (pi->tags & ProcTag_no_bounds_check) != 0;

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
		PROF_SCOPED("Untyped expr values");

		auto *entry = &c->info.untyped.entries.e[i];
		HashKey key = entry->key;
		AstNode *expr = cast(AstNode *)cast(uintptr)key.key;
		ExpressionInfo *info = &entry->value;
		if (info != NULL && expr != NULL) {
			if (is_type_typed(info->type)) {
				compiler_error("%s (type %s) is typed!", expr_to_string(expr), type_to_string(info->type));
			}
			add_type_and_value(&c->info, expr, info->mode, info->type, info->value);
		}
	}

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

	// for_array(i, c->info.type_info_map.entries) {
	// 	auto *e = &c->info.type_info_map.entries[i];
	// 	Type *prev_type = cast(Type *)e->key.ptr;
	// 	gb_printf("%td - %s\n", i, type_to_string(prev_type));
	// }

	// for_array(i, c->info.type_info_map.entries) {
	// 	auto *p = &c->info.type_info_map.entries[i];
	// 	for (isize j = 0; j < i-1; j++) {
	// 		auto *q = &c->info.type_info_map.entries[j];
	// 		Type *a = cast(Type *)p->key.ptr;
	// 		Type *b = cast(Type *)q->key.ptr;
	// 		p->value = i;
	// 		// GB_ASSERT(!are_types_identical(a, b));
	// 	}
	// }

	// for_array(i, c->info.type_info_map.entries) {
	// 	auto *e = &c->info.type_info_map.entries[i];
	// 	Type *prev_type = cast(Type *)e->key.ptr;
	// 	gb_printf("%td - %s\n", e->value, type_to_string(prev_type));
	// }

	map_destroy(&file_scopes);
	array_free(&import_decls);
}



