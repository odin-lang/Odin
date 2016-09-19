#include "../exact_value.cpp"
#include "entity.cpp"
#include "type.cpp"

#define ADDRESSING_KINDS \
	ADDRESSING_MODE(Invalid), \
	ADDRESSING_MODE(NoValue), \
	ADDRESSING_MODE(Value), \
	ADDRESSING_MODE(Variable), \
	ADDRESSING_MODE(Constant), \
	ADDRESSING_MODE(Type), \
	ADDRESSING_MODE(Builtin), \
	ADDRESSING_MODE(Count), \

enum AddressingMode {
#define ADDRESSING_MODE(x) GB_JOIN2(Addressing_, x)
	ADDRESSING_KINDS
#undef ADDRESSING_MODE
};

String const addressing_mode_strings[] = {
#define ADDRESSING_MODE(x) {cast(u8 *)#x, gb_size_of(#x)-1}
	ADDRESSING_KINDS
#undef ADDRESSING_MODE
};


struct Operand {
	AddressingMode mode;
	Type *type;
	ExactValue value;
	AstNode *expr;
	BuiltinProcId builtin_id;
};

struct TypeAndValue {
	AddressingMode mode;
	Type *type;
	ExactValue value;
};

struct DeclInfo {
	Scope *scope;

	Entity **entities;
	isize entity_count;

	AstNode *type_expr;
	AstNode *init_expr;
	AstNode *proc_decl; // AstNode_ProcDecl
	u32 var_decl_tags;

	Map<b32> deps; // Key: Entity *
};


void init_declaration_info(DeclInfo *d, Scope *scope) {
	d->scope = scope;
	map_init(&d->deps, gb_heap_allocator());
}

DeclInfo *make_declaration_info(gbAllocator a, Scope *scope) {
	DeclInfo *d = gb_alloc_item(a, DeclInfo);
	init_declaration_info(d, scope);
	return d;
}

void destroy_declaration_info(DeclInfo *d) {
	map_destroy(&d->deps);
}

b32 has_init(DeclInfo *d) {
	if (d->init_expr != NULL)
		return true;
	if (d->proc_decl != NULL) {
		ast_node(pd, ProcDecl, d->proc_decl);
		if (pd->body != NULL)
			return true;
	}

	return false;
}


struct ExpressionInfo {
	b32 is_lhs; // Debug info
	AddressingMode mode;
	Type *type; // Type_Basic
	ExactValue value;
};

ExpressionInfo make_expression_info(b32 is_lhs, AddressingMode mode, Type *type, ExactValue value) {
	ExpressionInfo ei = {};
	ei.is_lhs = is_lhs;
	ei.mode   = mode;
	ei.type   = type;
	ei.value  = value;
	return ei;
}

struct ProcedureInfo {
	AstFile * file;
	Token     token;
	DeclInfo *decl;
	Type *    type; // Type_Procedure
	AstNode * body; // AstNode_BlockStatement
};

struct Scope {
	Scope *parent;
	Scope *prev, *next;
	Scope *first_child, *last_child;
	Map<Entity *> elements; // Key: String
	Map<Entity *> implicit; // Key: String

	gbArray(Scope *) shared;
	gbArray(Scope *) imported;
	b32 is_proc;
	b32 is_global;
	b32 is_file;
	b32 is_init;
	AstFile *file;
};

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

	BuiltinProc_compile_assert,
	BuiltinProc_assert,

	BuiltinProc_copy,
	BuiltinProc_append,

	BuiltinProc_swizzle,

	BuiltinProc_ptr_offset,
	BuiltinProc_ptr_sub,
	BuiltinProc_slice_ptr,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,

	BuiltinProc_enum_to_string,


	BuiltinProc_Count,
};
struct BuiltinProc {
	String name;
	isize arg_count;
	b32 variadic;
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

	{STR_LIT("compile_assert"),   1, false, Expr_Stmt},
	{STR_LIT("assert"),           1, false, Expr_Stmt},

	{STR_LIT("copy"),             2, false, Expr_Expr},
	{STR_LIT("append"),           2, false, Expr_Expr},

	{STR_LIT("swizzle"),          1, true,  Expr_Expr},

	{STR_LIT("ptr_offset"),       2, false, Expr_Expr},
	{STR_LIT("ptr_sub"),          2, false, Expr_Expr},
	{STR_LIT("slice_ptr"),        2, true,  Expr_Expr},

	{STR_LIT("min"),              2, false, Expr_Expr},
	{STR_LIT("max"),              2, false, Expr_Expr},
	{STR_LIT("abs"),              1, false, Expr_Expr},

	{STR_LIT("enum_to_string"),   1, false, Expr_Expr},

};

struct CheckerContext {
	Scope *scope;
	DeclInfo *decl;
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
	Map<isize>             type_info_map;   // Key: Type *
	Map<AstFile *>         files;           // Key: String
	isize                  type_info_index;
};

struct Checker {
	Parser *    parser;
	CheckerInfo info;

	AstFile *              curr_ast_file;
	BaseTypeSizes          sizes;
	Scope *                global_scope;
	gbArray(ProcedureInfo) procs; // NOTE(bill): Procedures to check

	gbArena     arena;
	gbAllocator allocator;

	CheckerContext context;

	gbArray(Type *) proc_stack;
	b32 in_defer; // TODO(bill): Actually handle correctly
};

gb_global Scope *universal_scope = NULL;

struct CycleChecker {
	gbArray(Entity *) path; // Entity_TypeName
};

CycleChecker *cycle_checker_add(CycleChecker *cc, Entity *e) {
	GB_ASSERT(cc != NULL);
	if (cc->path == NULL) {
		gb_array_init(cc->path, gb_heap_allocator());
	}
	GB_ASSERT(e != NULL && e->kind == Entity_TypeName);
	gb_array_append(cc->path, e);
	return cc;
}



Scope *make_scope(Scope *parent, gbAllocator allocator) {
	Scope *s = gb_alloc_item(allocator, Scope);
	s->parent = parent;
	map_init(&s->elements,     gb_heap_allocator());
	map_init(&s->implicit,     gb_heap_allocator());
	gb_array_init(s->shared,   gb_heap_allocator());
	gb_array_init(s->imported, gb_heap_allocator());

	if (parent != NULL && parent != universal_scope) {
		DLIST_APPEND(parent->first_child, parent->last_child, s);
	}
	return s;
}

void destroy_scope(Scope *scope) {
	gb_for_array(i, scope->elements.entries) {
		Entity *e =scope->elements.entries[i].value;
		if (e->kind == Entity_Variable) {
			if (!e->Variable.used) {
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
	gb_array_free(scope->shared);
	gb_array_free(scope->imported);

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
			gb_for_array(i, s->shared) {
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
	gb_for_array(i, s->shared) {
		Entity **found = map_get(&s->shared[i]->elements, key);
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
	if (found)
		return *found;
	map_set(&s->elements, key, entity);
	if (entity->scope == NULL) {
		entity->scope = s;
	}
	return NULL;
}

void check_scope_usage(Checker *c, Scope *scope) {
	// TODO(bill): Use this?
#if 1
	gb_for_array(i, scope->elements.entries) {
		auto *entry = scope->elements.entries + i;
		Entity *e = entry->value;
		if (e->kind == Entity_Variable && !e->Variable.used) {
			warning(e->token, "Unused variable: %.*s", LIT(e->token.string));
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
	if (c->context.decl) {
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
	Token token = {Token_Identifier};
	token.string = name;
	Entity *entity = alloc_entity(a, Entity_Constant, NULL, token, type);
	entity->Constant.value = value;
	add_global_entity(entity);
}





void init_universal_scope(void) {
	// NOTE(bill): No need to free these
	gbAllocator a = gb_heap_allocator();
	universal_scope = make_scope(NULL, a);

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		Token token = {Token_Identifier};
		token.string = basic_types[i].Basic.name;
		add_global_entity(make_entity_type_name(a, NULL, token, &basic_types[i]));
	}
	for (isize i = 0; i < gb_count_of(basic_type_aliases); i++) {
		Token token = {Token_Identifier};
		token.string = basic_type_aliases[i].Basic.name;
		add_global_entity(make_entity_type_name(a, NULL, token, &basic_type_aliases[i]));
	}

// Constants
	add_global_constant(a, make_string("true"),  t_untyped_bool,    make_exact_value_bool(true));
	add_global_constant(a, make_string("false"), t_untyped_bool,    make_exact_value_bool(false));
	add_global_constant(a, make_string("null"),  t_untyped_pointer, make_exact_value_pointer(NULL));

// Builtin Procedures
	for (isize i = 0; i < gb_count_of(builtin_procs); i++) {
		BuiltinProcId id = cast(BuiltinProcId)i;
		Token token = {Token_Identifier};
		token.string = builtin_procs[i].name;
		Entity *entity = alloc_entity(a, Entity_Builtin, NULL, token, t_invalid);
		entity->Builtin.id = id;
		add_global_entity(entity);
	}
}




void init_checker_info(CheckerInfo *i) {
	gbAllocator a = gb_heap_allocator();
	map_init(&i->types,           a);
	map_init(&i->definitions,     a);
	map_init(&i->uses,            a);
	map_init(&i->scopes,          a);
	map_init(&i->entities,        a);
	map_init(&i->untyped,         a);
	map_init(&i->foreign_procs,   a);
	map_init(&i->type_info_map,   a);
	map_init(&i->files,           a);
	i->type_info_index = 0;

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
	gbAllocator a = gb_heap_allocator();

	c->parser = parser;
	init_checker_info(&c->info);
	c->sizes = sizes;

	gb_array_init(c->proc_stack, a);
	gb_array_init(c->procs, a);

	// NOTE(bill): Is this big enough or too small?
	isize item_size = gb_max(gb_max(gb_size_of(Entity), gb_size_of(Type)), gb_size_of(Scope));
	isize total_token_count = 0;
	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		total_token_count += gb_array_count(f->tokens);
	}
	isize arena_size = 2 * item_size * total_token_count;
	gb_arena_init_from_allocator(&c->arena, a, arena_size);
	c->allocator = gb_arena_allocator(&c->arena);

	c->global_scope = make_scope(universal_scope, c->allocator);
	c->context.scope = c->global_scope;
}

void destroy_checker(Checker *c) {
	destroy_checker_info(&c->info);
	destroy_scope(c->global_scope);
	gb_array_free(c->proc_stack);
	gb_array_free(c->procs);

	gb_arena_free(&c->arena);
}


TypeAndValue *type_and_value_of_expression(CheckerInfo *i, AstNode *expression) {
	TypeAndValue *found = map_get(&i->types, hash_pointer(expression));
	return found;
}


Entity *entity_of_ident(CheckerInfo *i, AstNode *identifier) {
	GB_ASSERT(identifier->kind == AstNode_Ident);
	Entity **found = map_get(&i->definitions, hash_pointer(identifier));
	if (found)
		return *found;

	found = map_get(&i->uses, hash_pointer(identifier));
	if (found)
		return *found;
	return NULL;
}

Type *type_of_expr(CheckerInfo *i, AstNode *expression) {
	TypeAndValue *found = type_and_value_of_expression(i, expression);
	if (found)
		return found->type;
	if (expression->kind == AstNode_Ident) {
		Entity *entity = entity_of_ident(i, expression);
		if (entity)
			return entity->type;
	}

	return NULL;
}


void add_untyped(CheckerInfo *i, AstNode *expression, b32 lhs, AddressingMode mode, Type *basic_type, ExactValue value) {
	map_set(&i->untyped, hash_pointer(expression), make_expression_info(lhs, mode, basic_type, value));
}


void add_type_and_value(CheckerInfo *i, AstNode *expression, AddressingMode mode, Type *type, ExactValue value) {
	GB_ASSERT(expression != NULL);
	if (mode == Addressing_Invalid)
		return;

	if (mode == Addressing_Constant) {
		GB_ASSERT(value.kind != ExactValue_Invalid);
		GB_ASSERT_MSG(type != t_invalid || is_type_constant_type(type),
		              "type: %s", type_to_string(type));
	}

	TypeAndValue tv = {};
	tv.type  = type;
	tv.value = value;
	tv.mode  = mode;
	map_set(&i->types, hash_pointer(expression), tv);
}

void add_entity_definition(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	GB_ASSERT(identifier->kind == AstNode_Ident);
	HashKey key = hash_pointer(identifier);
	map_set(&i->definitions, key, entity);
}

b32 add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	if (!are_strings_equal(entity->token.string, make_string("_"))) {
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

void add_entity_use(CheckerInfo *i, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	GB_ASSERT(identifier->kind == AstNode_Ident);
	HashKey key = hash_pointer(identifier);
	map_set(&i->uses, key, entity);

	if (entity != NULL && entity->kind == Entity_ImportName) {
		entity->ImportName.used = true;
	}
}


void add_file_entity(Checker *c, Scope *file_scope, AstNode *identifier, Entity *e, DeclInfo *d) {
	GB_ASSERT(are_strings_equal(identifier->Ident.string, e->token.string));
	add_entity(c, file_scope, identifier, e);
	map_set(&c->info.entities, hash_pointer(e), d);
}

void add_type_info_type(Checker *c, Type *t) {
	if (t == NULL) {
		return;
	}
	t = default_type(t);
	if (map_get(&c->info.type_info_map, hash_pointer(t)) != NULL) {
		// Types have already been added
		return;
	}

	isize ti_index = -1;
	gb_for_array(i, c->info.type_info_map.entries) {
		auto *e = &c->info.type_info_map.entries[i];
		Type *prev_type = cast(Type *)cast(uintptr)e->key.key;
		if (are_types_identical(t, prev_type)) {
			// Duplicate entry
			ti_index = i;
			break;
		}
	}
	if (ti_index < 0) {
		// Unique entry
		// NOTE(bill): map entries grow linearly and in order
		ti_index = c->info.type_info_index;
		c->info.type_info_index++;
	}
	map_set(&c->info.type_info_map, hash_pointer(t), ti_index);


	// Add nested types

	if (t->kind == Type_Named) {
		// NOTE(bill): Just in case
		add_type_info_type(c, t->Named.base);
		return;
	}

	Type *bt = get_base_type(t);
	switch (bt->kind) {
	case Type_Basic: {
		if (bt->Basic.kind == Basic_string) {
			add_type_info_type(c, make_type_pointer(c->allocator, t_u8));
			add_type_info_type(c, t_int);
		}
	} break;

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


void check_procedure_later(Checker *c, AstFile *file, Token token, DeclInfo *decl, Type *type, AstNode *body) {
	ProcedureInfo info = {};
	info.file = file;
	info.token = token;
	info.decl  = decl;
	info.type  = type;
	info.body  = body;
	gb_array_append(c->procs, info);
}

void push_procedure(Checker *c, Type *type) {
	gb_array_append(c->proc_stack, type);
}

void pop_procedure(Checker *c) {
	gb_array_pop(c->proc_stack);
}

Type *const curr_procedure(Checker *c) {
	isize count = gb_array_count(c->proc_stack);
	if (count > 0) {
		return c->proc_stack[count-1];
	}
	return NULL;
}

void add_curr_ast_file(Checker *c, AstFile *file) {
	TokenPos zero_pos = {};
	global_error_collector.prev = zero_pos;
	c->curr_ast_file = file;
}




#include "expr.cpp"
#include "stmt.cpp"



struct CycleCheck {
	gbArray(Entity *) path; // HACK(bill): Memory Leak
};

void cycle_check_add(CycleCheck *cc, Entity *entity) {
	if (cc == NULL)
		return;
	if (cc->path == NULL) {
		gb_array_init(cc->path, gb_heap_allocator());
	}
	GB_ASSERT(entity->kind == Entity_TypeName);
	gb_array_append(cc->path, entity);
}

void check_type_name_cycles(Checker *c, CycleCheck *cc, Entity *e) {
	GB_ASSERT(e->kind == Entity_TypeName);
	Type *t = e->type;
	// if (t->kind == Type_Named) {
	// 	if (t->Named.type_name == e) {
	// 		gb_printf("Illegal cycle %.*s!!!\n", LIT(e->token.string));
	// 		GB_PANIC("!!!");
	// 	}
	// }
}

void init_type_info_types(Checker *c) {
	if (t_type_info == NULL) {
		String type_info_str = make_string("Type_Info");
		Entity *e = current_scope_lookup_entity(c->global_scope, type_info_str);
		if (e == NULL) {
			compiler_error("Could not find type declaration for `Type_Info`\n"
			               "Is `runtime.odin` missing from the `core` directory relative to odin.exe?");
		}
		t_type_info = e->type;
		t_type_info_ptr = make_type_pointer(c->allocator, t_type_info);

		auto *record = &get_base_type(e->type)->Record;

		t_type_info_member = record->other_fields[0]->type;
		t_type_info_member_ptr = make_type_pointer(c->allocator, t_type_info_member);

		if (record->field_count != 16) {
			compiler_error("Invalid `Type_Info` layout");
		}
		t_type_info_named     = record->fields[ 1]->type;
		t_type_info_integer   = record->fields[ 2]->type;
		t_type_info_float     = record->fields[ 3]->type;
		t_type_info_string    = record->fields[ 4]->type;
		t_type_info_boolean   = record->fields[ 5]->type;
		t_type_info_pointer   = record->fields[ 6]->type;
		t_type_info_procedure = record->fields[ 7]->type;
		t_type_info_array     = record->fields[ 8]->type;
		t_type_info_slice     = record->fields[ 9]->type;
		t_type_info_vector    = record->fields[10]->type;
		t_type_info_tuple     = record->fields[11]->type;
		t_type_info_struct    = record->fields[12]->type;
		t_type_info_union     = record->fields[13]->type;
		t_type_info_raw_union = record->fields[14]->type;
		t_type_info_enum      = record->fields[15]->type;
	}

}


void check_parsed_files(Checker *c) {

	gbArray(AstNode *) import_decls;
	gb_array_init(import_decls, gb_heap_allocator());
	defer (gb_array_free(import_decls));

	Map<Scope *> file_scopes; // Key: String (fullpath)
	map_init(&file_scopes, gb_heap_allocator());
	defer (map_destroy(&file_scopes));

	// Map full filepaths to Scopes
	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
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
			gb_array_append(c->global_scope->shared, scope);
		}

		f->scope = scope;
		HashKey key = hash_string(f->tokenizer.fullpath);
		map_set(&file_scopes, key, scope);
		map_set(&c->info.files, key, f);
	}

	// Collect Entities
	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		add_curr_ast_file(c, f);

		Scope *file_scope = f->scope;

		gb_for_array(decl_index, f->decls) {
			AstNode *decl = f->decls[decl_index];
			if (!is_ast_node_decl(decl)) {
				continue;
			}

			switch (decl->kind) {
			case_ast_node(bd, BadDecl, decl);
			case_end;
			case_ast_node(id, ImportDecl, decl);
				// NOTE(bill): Handle later
			case_end;
			case_ast_node(fsl, ForeignSystemLibrary, decl);
				// NOTE(bill): ignore
			case_end;

			case_ast_node(cd, ConstDecl, decl);
				gb_for_array(i, cd->values) {
					AstNode *name = cd->names[i];
					AstNode *value = cd->values[i];
					ExactValue v = {ExactValue_Invalid};
					Entity *e = make_entity_constant(c->allocator, file_scope, name->Ident, NULL, v);
					DeclInfo *di = make_declaration_info(c->allocator, file_scope);
					di->type_expr = cd->type;
					di->init_expr = value;
					add_file_entity(c, file_scope, name, e, di);
				}

				isize lhs_count = gb_array_count(cd->names);
				isize rhs_count = gb_array_count(cd->values);

				if (rhs_count == 0 && cd->type == NULL) {
					error(ast_node_token(decl), "Missing type or initial expression");
				} else if (lhs_count < rhs_count) {
					error(ast_node_token(decl), "Extra initial expression");
				}
			case_end;

			case_ast_node(vd, VarDecl, decl);
				isize entity_count = gb_array_count(vd->names);
				isize entity_index = 0;
				Entity **entities = gb_alloc_array(c->allocator, Entity *, entity_count);
				DeclInfo *di = NULL;
				if (gb_array_count(vd->values) > 0) {
					di = make_declaration_info(gb_heap_allocator(), file_scope);
					di->entities = entities;
					di->entity_count = entity_count;
					di->type_expr = vd->type;
					di->init_expr = vd->values[0]; // TODO(bill): Is this correct?
				}

				gb_for_array(i, vd->names) {
					AstNode *name = vd->names[i];
					AstNode *value = NULL;
					if (i < gb_array_count(vd->values)) {
						value = vd->values[i];
					}
					Entity *e = make_entity_variable(c->allocator, file_scope, name->Ident, NULL);
					entities[entity_index++] = e;

					DeclInfo *d = di;
					if (d == NULL) {
						AstNode *init_expr = value;
						d = make_declaration_info(gb_heap_allocator(), file_scope);
						d->type_expr = vd->type;
						d->init_expr = init_expr;
						d->var_decl_tags = vd->tags;
					}

					add_file_entity(c, file_scope, name, e, d);
				}
			case_end;

			case_ast_node(td, TypeDecl, decl);
				ast_node(n, Ident, td->name);
				Entity *e = make_entity_type_name(c->allocator, file_scope, *n, NULL);
				DeclInfo *d = make_declaration_info(c->allocator, e->scope);
				d->type_expr = td->type;
				add_file_entity(c, file_scope, td->name, e, d);
			case_end;

			case_ast_node(pd, ProcDecl, decl);
				ast_node(n, Ident, pd->name);
				Token token = *n;
				Entity *e = make_entity_procedure(c->allocator, file_scope, token, NULL);
				DeclInfo *d = make_declaration_info(c->allocator, e->scope);
				d->proc_decl = decl;
				add_file_entity(c, file_scope, pd->name, e, d);
			case_end;

			default:
				error(ast_node_token(decl), "Only declarations are allowed at file scope");
				break;
			}
		}
	}

	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		add_curr_ast_file(c, f);

		Scope *file_scope = f->scope;

		gb_for_array(decl_index, f->decls) {
			AstNode *decl = f->decls[decl_index];
			if (decl->kind != AstNode_ImportDecl) {
				continue;
			}
			ast_node(id, ImportDecl, decl);

			HashKey key = hash_string(id->fullpath);
			auto found = map_get(&file_scopes, key);
			GB_ASSERT_MSG(found != NULL, "Unable to find scope for file: %.*s", LIT(id->fullpath));
			Scope *scope = *found;
			b32 previously_added = false;
			gb_for_array(import_index, file_scope->imported) {
				Scope *prev = file_scope->imported[import_index];
				if (prev == scope) {
					previously_added = true;
					break;
				}
			}
			if (!previously_added) {
				gb_array_append(file_scope->imported, scope);
			} else {
				warning(id->token, "Multiple #import of the same file within this scope");
			}

			if (are_strings_equal(id->import_name.string, make_string("_"))) {
				// NOTE(bill): Add imported entities to this file's scope
				gb_for_array(elem_index, scope->elements.entries) {
					Entity *e = scope->elements.entries[elem_index].value;
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
				GB_ASSERT(id->import_name.string.len > 0);
				Entity *e = make_entity_import_name(c->allocator, file_scope, id->import_name, t_invalid,
				                                    id->fullpath, id->import_name.string,
				                                    scope);
				add_entity(c, file_scope, NULL, e);
			}
		}
	}

	auto check_global_entity = [](Checker *c, EntityKind kind) {
		gb_for_array(i, c->info.entities.entries) {
			auto *entry = &c->info.entities.entries[i];
			Entity *e = cast(Entity *)cast(uintptr)entry->key.key;
			if (e->kind == kind) {
				DeclInfo *d = entry->value;

				add_curr_ast_file(c, d->scope->file);

				Scope *prev_scope = c->context.scope;
				c->context.scope = d->scope;
				GB_ASSERT(d->scope == e->scope);
				check_entity_decl(c, e, d, NULL);
			}
		}
	};

	check_global_entity(c, Entity_TypeName);

	init_type_info_types(c);
#if 1
	check_global_entity(c, Entity_Constant);
	check_global_entity(c, Entity_Procedure);
	check_global_entity(c, Entity_Variable);

	// Check procedure bodies
	gb_for_array(i, c->procs) {
		ProcedureInfo *pi = &c->procs[i];
		add_curr_ast_file(c, pi->file);
		check_proc_body(c, pi->token, pi->decl, pi->type, pi->body);
	}


	// Add untyped expression values
	gb_for_array(i, c->info.untyped.entries) {
		auto *entry = c->info.untyped.entries + i;
		HashKey key = entry->key;
		AstNode *expr = cast(AstNode *)cast(uintptr)key.key;
		ExpressionInfo *info = &entry->value;
		if (info != NULL && expr != NULL) {
			if (is_type_typed(info->type)) {
				compiler_error("%s (type %s) is typed!", expr_to_string(expr), info->type);
			}
			add_type_and_value(&c->info, expr, info->mode, info->type, info->value);
		}
	}
#endif

	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		Scope *scope = f->scope;
		gb_for_array(j, scope->elements.entries) {
			Entity *e = scope->elements.entries[j].value;
			switch (e->kind) {
			case Entity_ImportName: {
				if (!e->ImportName.used) {
					warning(e->token, "Unused import name: %.*s", LIT(e->ImportName.name));
				}
			} break;
			}
		}
	}
}



