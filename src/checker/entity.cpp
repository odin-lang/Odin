struct Scope;
struct Checker;

enum EntityKind {
	Entity_Invalid,

	Entity_Constant,
	Entity_Variable,
	Entity_TypeName,
	Entity_Procedure,
	Entity_Builtin,

	Entity_Count,
};

typedef i64 EntityGuid;

struct Entity {
	EntityKind kind;
	EntityGuid guid;

	Scope *parent;
	Token token;
	Type *type;

	union {
		struct { Value value; } constant;
		struct {
			b8 visited;
			b8 is_field;
			b8 used;
		} variable;
		struct {} type_name;
		struct {} procedure;
		struct { i32 id; } builtin;
	};
};

gb_global gbAtomic64 entity_guid_counter = {0};

EntityGuid next_entity_guid(void) {
	return cast(EntityGuid)gb_atomic64_fetch_add(&entity_guid_counter, 1);
}

Entity *alloc_entity(gbAllocator a, EntityKind kind, Scope *parent, Token token, Type *type) {
	Entity *entity = gb_alloc_item(a, Entity);
	entity->kind   = kind;
	entity->guid   = next_entity_guid();
	entity->parent = parent;
	entity->token  = token;
	entity->type   = type;
	return entity;
}




Entity *make_entity_variable (Checker *c, Scope *parent, Token token, Type *type);
Entity *make_entity_constant (Checker *c, Scope *parent, Token token, Type *type, Value value);
Entity *make_entity_type_name(Checker *c, Scope *parent, Token token, Type *type);
Entity *make_entity_param    (Checker *c, Scope *parent, Token token, Type *type);
Entity *make_entity_field    (Checker *c, Scope *parent, Token token, Type *type);
Entity *make_entity_procedure(Checker *c, Scope *parent, Token token, Type *signature_type);
Entity *make_entity_builtin  (Checker *c, Scope *parent, Token token, Type *type, i32 id);

Entity *make_entity_dummy_variable(Checker *c, Token token);
