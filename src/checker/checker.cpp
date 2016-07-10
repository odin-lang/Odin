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
	Type *type;
	Value value;

	AstNode *expression;
	BuiltinProcedureId builtin_id;
};

struct TypeAndValue {
	AddressingMode mode;
	Type *type;
	Value value;
};

struct ExpressionInfo {
	b32 is_lhs; // Debug info
	AddressingMode mode;
	Type *type; // Type_Basic
	Value value;
};

ExpressionInfo make_expression_info(b32 is_lhs, AddressingMode mode, Type *type, Value value) {
	ExpressionInfo ei = {};
	ei.is_lhs = is_lhs;
	ei.mode   = mode;
	ei.type   = type;
	ei.value  = value;
	return ei;
}

struct Scope {
	Scope *parent;
	Scope *prev, *next;
	Scope *first_child, *last_child;
	Map<Entity *> elements; // Key: String
};

enum ExpressionKind {
	Expression_Expression,
	Expression_Conversion,
	Expression_Statement,
};

enum BuiltinProcedureId {
	BuiltinProcedure_Invalid,

	BuiltinProcedure_size_of,
	BuiltinProcedure_size_of_val,
	BuiltinProcedure_align_of,
	BuiltinProcedure_align_of_val,
	BuiltinProcedure_offset_of,
	BuiltinProcedure_offset_of_val,
	BuiltinProcedure_static_assert,
	BuiltinProcedure_len,
	BuiltinProcedure_cap,
	BuiltinProcedure_copy,
	BuiltinProcedure_copy_bytes,
	BuiltinProcedure_print,
	BuiltinProcedure_println,

	BuiltinProcedure_Count,
};
struct BuiltinProcedure {
	String name;
	isize arg_count;
	b32 variadic;
	ExpressionKind kind;
};
gb_global BuiltinProcedure builtin_procedures[BuiltinProcedure_Count] = {
	{STR_LIT(""),                 0, false, Expression_Statement},
	{STR_LIT("size_of"),          1, false, Expression_Expression},
	{STR_LIT("size_of_val"),      1, false, Expression_Expression},
	{STR_LIT("align_of"),         1, false, Expression_Expression},
	{STR_LIT("align_of_val"),     1, false, Expression_Expression},
	{STR_LIT("offset_of"),        2, false, Expression_Expression},
	{STR_LIT("offset_of_val"),    1, false, Expression_Expression},
	{STR_LIT("static_assert"),    1, false, Expression_Statement},
	{STR_LIT("len"),              1, false, Expression_Expression},
	{STR_LIT("cap"),              1, false, Expression_Expression},
	{STR_LIT("copy"),             2, false, Expression_Expression},
	{STR_LIT("copy_bytes"),       3, false, Expression_Statement},
	{STR_LIT("print"),            1, true,  Expression_Statement},
	{STR_LIT("println"),          1, true,  Expression_Statement},
};



struct Checker {
	Parser *            parser;
	Map<TypeAndValue>   types;       // Key: AstNode * | Expression -> Type (and value)
	Map<Entity *>       definitions; // Key: AstNode * | Identifier -> Entity
	Map<Entity *>       uses;        // Key: AstNode * | Identifier -> Entity
	Map<Scope *>        scopes;      // Key: AstNode * | Node       -> Scope
	Map<ExpressionInfo> untyped;     // Key: AstNode * | Expression -> ExpressionInfo
	BaseTypeSizes       sizes;
	Scope *             file_scope;

	gbArena     arena;
	gbAllocator allocator;

	Scope *curr_scope;
	gbArray(Type *) procedure_stack;
	b32 in_defer; // TODO(bill): Actually handle correctly

#define MAX_CHECKER_ERROR_COUNT 10
	isize error_prev_line;
	isize error_prev_column;
	isize error_count;
};


gb_global Scope *global_scope = NULL;


Scope *make_scope(Scope *parent, gbAllocator allocator) {
	Scope *s = gb_alloc_item(allocator, Scope);
	s->parent = parent;
	map_init(&s->elements, gb_heap_allocator());
	if (parent != NULL && parent != global_scope) {
		DLIST_APPEND(parent->first_child, parent->last_child, s);
	}
	return s;
}

void destroy_scope(Scope *scope) {
	for (Scope *child = scope->first_child; child != NULL; child = child->next) {
		destroy_scope(child);
	}
	map_destroy(&scope->elements);
	// NOTE(bill): No need to free scope as it "should" be allocated in an arena (except for the global scope)
}


void scope_lookup_parent_entity(Scope *s, String name, Scope **scope, Entity **entity) {
	u64 key = hash_string(name);
	for (; s != NULL; s = s->parent) {
		Entity **found = map_get(&s->elements, key);
		if (found) {
			if (entity) *entity = *found;
			if (scope) *scope = s;
			return;
		}
	}
	if (entity) *entity = NULL;
	if (scope) *scope = NULL;
}

Entity *scope_lookup_entity(Scope *s, String name) {
	Entity *entity = NULL;
	scope_lookup_parent_entity(s, name, NULL, &entity);
	return entity;
}

Entity *current_scope_lookup_entity(Scope *s, String name) {
	u64 key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found)
		return *found;
	return NULL;
}



Entity *scope_insert_entity(Scope *s, Entity *entity) {
	String name = entity->token.string;
	u64 key = hash_string(name);
	Entity **found = map_get(&s->elements, key);
	if (found)
		return *found;
	map_set(&s->elements, key, entity);
	if (entity->parent == NULL)
		entity->parent = s;
	return NULL;
}





void add_global_entity(Entity *entity) {
	String name = entity->token.string;
	if (gb_memchr(name.text, ' ', name.len)) {
		return; // NOTE(bill): `untyped thing`
	}
	if (scope_insert_entity(global_scope, entity)) {
		GB_PANIC("Internal type checking error: double declaration");
	}
}

void add_global_constant(gbAllocator a, String name, Type *type, Value value) {
	Token token = {Token_Identifier};
	token.string = name;
	Entity *entity = alloc_entity(a, Entity_Constant, NULL, token, type);
	entity->constant.value = value;
	add_global_entity(entity);
}

void init_global_scope(void) {
	// NOTE(bill): No need to free these
	gbAllocator a = gb_heap_allocator();
	global_scope = make_scope(NULL, a);

// Types
	for (isize i = 0; i < gb_count_of(basic_types); i++) {
		Token token = {Token_Identifier};
		token.string = basic_types[i].basic.name;
		add_global_entity(alloc_entity(a, Entity_TypeName, NULL, token, &basic_types[i]));
	}
	for (isize i = 0; i < gb_count_of(basic_type_aliases); i++) {
		Token token = {Token_Identifier};
		token.string = basic_type_aliases[i].basic.name;
		add_global_entity(alloc_entity(a, Entity_TypeName, NULL, token, &basic_type_aliases[i]));
	}

// Constants
	add_global_constant(a, make_string("true"),  &basic_types[Basic_UntypedBool],    make_value_bool(true));
	add_global_constant(a, make_string("false"), &basic_types[Basic_UntypedBool],    make_value_bool(false));
	add_global_constant(a, make_string("null"),  &basic_types[Basic_UntypedPointer], make_value_pointer(NULL));

// Builtin Procedures
	for (isize i = 0; i < gb_count_of(builtin_procedures); i++) {
		BuiltinProcedureId id = cast(BuiltinProcedureId)i;
		Token token = {Token_Identifier};
		token.string = builtin_procedures[i].name;
		Entity *entity = alloc_entity(a, Entity_Builtin, NULL, token, &basic_types[Basic_Invalid]);
		entity->builtin.id = id;
		add_global_entity(entity);
	}
}







void init_checker(Checker *c, Parser *parser) {
	gbAllocator a = gb_heap_allocator();

	c->parser = parser;
	map_init(&c->types,       gb_heap_allocator());
	map_init(&c->definitions, gb_heap_allocator());
	map_init(&c->uses,        gb_heap_allocator());
	map_init(&c->scopes,      gb_heap_allocator());
	c->sizes.word_size = 8;
	c->sizes.max_align = 8;

	map_init(&c->untyped, a);

	gb_array_init(c->procedure_stack, a);

	// NOTE(bill): Is this big enough or too small?
	isize item_size = gb_max(gb_max(gb_size_of(Entity), gb_size_of(Type)), gb_size_of(Scope));
	isize arena_size = 2 * item_size * gb_array_count(c->parser->tokens);
	gb_arena_init_from_allocator(&c->arena, a, arena_size);
	c->allocator = gb_arena_allocator(&c->arena);

	c->file_scope = make_scope(global_scope, c->allocator);
	c->curr_scope = c->file_scope;
}

void destroy_checker(Checker *c) {
	map_destroy(&c->types);
	map_destroy(&c->definitions);
	map_destroy(&c->uses);
	map_destroy(&c->scopes);
	map_destroy(&c->untyped);
	destroy_scope(c->file_scope);
	gb_array_free(c->procedure_stack);
	gb_arena_free(&c->arena);
}

#define print_checker_error(p, token, fmt, ...) print_checker_error_(p, __FUNCTION__, token, fmt, ##__VA_ARGS__)
void print_checker_error_(Checker *c, char *function, Token token, char *fmt, ...) {


	// NOTE(bill): Duplicate error, skip it
	if (!(c->error_prev_line == token.line && c->error_prev_column == token.column)) {
		c->error_prev_line = token.line;
		c->error_prev_column = token.column;

	#if 0
		gb_printf_err("%s()\n", function);
	#endif

		va_list va;
		va_start(va, fmt);
		gb_printf_err("%s(%td:%td) %s\n",
		              c->parser->tokenizer.fullpath, token.line, token.column,
		              gb_bprintf_va(fmt, va));
		va_end(va);

	}
	c->error_count++;
	// NOTE(bill): If there are too many errors, just quit
	if (c->error_count > MAX_CHECKER_ERROR_COUNT) {
		gb_exit(1);
		return;
	}
}



Entity *entity_of_identifier(Checker *c, AstNode *identifier) {
	GB_ASSERT(identifier->kind == AstNode_Identifier);
	Entity **found = map_get(&c->definitions, hash_pointer(identifier));
	if (found)
		return *found;

	found = map_get(&c->uses, hash_pointer(identifier));
	if (found)
		return *found;
	return NULL;
}

Type *type_of_expression(Checker *c, AstNode *expression) {
	TypeAndValue *found = map_get(&c->types, hash_pointer(expression));
	if (found)
		return found->type;
	if (expression->kind == AstNode_Identifier) {
		Entity *entity = entity_of_identifier(c, expression);
		if (entity)
			return entity->type;
	}

	return NULL;
}


void add_untyped(Checker *c, AstNode *expression, b32 lhs, AddressingMode mode, Type *basic_type, Value value) {
	map_set(&c->untyped, hash_pointer(expression), make_expression_info(lhs, mode, basic_type, value));
}


void add_type_and_value(Checker *c, AstNode *expression, AddressingMode mode, Type *type, Value value) {
	GB_ASSERT(expression != NULL);
	GB_ASSERT(type != NULL);
	if (mode == Addressing_Invalid)
		return;

	if (mode == Addressing_Constant) {
		GB_ASSERT(value.kind != Value_Invalid);
		GB_ASSERT(type == &basic_types[Basic_Invalid] || is_type_constant_type(type));
	}

	TypeAndValue tv = {};
	tv.type = type;
	tv.value = value;
	map_set(&c->types, hash_pointer(expression), tv);
}

void add_entity_definition(Checker *c, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	GB_ASSERT(identifier->kind == AstNode_Identifier);
	u64 key = hash_pointer(identifier);
	map_set(&c->definitions, key, entity);
}

void add_entity(Checker *c, Scope *scope, AstNode *identifier, Entity *entity) {
	Entity *insert_entity = scope_insert_entity(scope, entity);
	if (insert_entity) {
		print_checker_error(c, entity->token, "Redeclared entity in this scope: %.*s", LIT(entity->token.string));
		return;
	}
	if (identifier)
		add_entity_definition(c, identifier, entity);
}

void add_entity_use(Checker *c, AstNode *identifier, Entity *entity) {
	GB_ASSERT(identifier != NULL);
	GB_ASSERT(identifier->kind == AstNode_Identifier);
	u64 key = hash_pointer(identifier);
	map_set(&c->uses, key, entity);
}

void add_scope(Checker *c, AstNode *node, Scope *scope) {
	GB_ASSERT(node != NULL);
	GB_ASSERT(scope != NULL);
	map_set(&c->scopes, hash_pointer(node), scope);
}


void check_open_scope(Checker *c, AstNode *statement) {
	Scope *scope = make_scope(c->curr_scope, c->allocator);
	add_scope(c, statement, scope);
	c->curr_scope = scope;
}

void check_close_scope(Checker *c) {
	c->curr_scope = c->curr_scope->parent;
}

void push_procedure(Checker *c, Type *procedure_type) {
	gb_array_append(c->procedure_stack, procedure_type);
}

void pop_procedure(Checker *c) {
	gb_array_pop(c->procedure_stack);
}




Entity *make_entity_variable(Checker *c, Scope *parent, Token token, Type *type) {
	Entity *entity = alloc_entity(c->allocator, Entity_Variable, parent, token, type);
	return entity;
}

Entity *make_entity_constant(Checker *c, Scope *parent, Token token, Type *type, Value value) {
	Entity *entity = alloc_entity(c->allocator, Entity_Constant, parent, token, type);
	entity->constant.value = value;
	return entity;
}

Entity *make_entity_type_name(Checker *c, Scope *parent, Token token, Type *type) {
	Entity *entity = alloc_entity(c->allocator, Entity_TypeName, parent, token, type);
	return entity;
}

Entity *make_entity_param(Checker *c, Scope *parent, Token token, Type *type) {
	Entity *entity = alloc_entity(c->allocator, Entity_Variable, parent, token, type);
	entity->variable.used = true;
	return entity;
}

Entity *make_entity_field(Checker *c, Scope *parent, Token token, Type *type) {
	Entity *entity = alloc_entity(c->allocator, Entity_Variable, parent, token, type);
	entity->variable.is_field  = true;
	return entity;
}

Entity *make_entity_procedure(Checker *c, Scope *parent, Token token, Type *signature_type) {
	Entity *entity = alloc_entity(c->allocator, Entity_Procedure, parent, token, signature_type);
	return entity;
}

Entity *make_entity_builtin(Checker *c, Scope *parent, Token token, Type *type, BuiltinProcedureId id) {
	Entity *entity = alloc_entity(c->allocator, Entity_Builtin, parent, token, type);
	entity->builtin.id = id;
	return entity;
}

Entity *make_entity_dummy_variable(Checker *c, Token token) {
	token.string = make_string("_");
	return make_entity_variable(c, c->file_scope, token, NULL);
}

