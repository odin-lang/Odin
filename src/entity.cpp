struct Scope;
struct Checker;
struct Type;
struct DeclInfo;


#define ENTITY_KINDS \
	ENTITY_KIND(Invalid) \
	ENTITY_KIND(Constant) \
	ENTITY_KIND(Variable) \
	ENTITY_KIND(TypeName) \
	ENTITY_KIND(Procedure) \
	ENTITY_KIND(ProcGroup) \
	ENTITY_KIND(Builtin) \
	ENTITY_KIND(Alias) \
	ENTITY_KIND(ImportName) \
	ENTITY_KIND(LibraryName) \
	ENTITY_KIND(Nil) \
	ENTITY_KIND(Label)

enum EntityKind {
#define ENTITY_KIND(k) GB_JOIN2(Entity_, k),
	ENTITY_KINDS
#undef ENTITY_KIND
	Entity_Count,
};

String const entity_strings[] = {
#define ENTITY_KIND(k) {cast(u8 *)#k, gb_size_of(#k)-1},
	ENTITY_KINDS
#undef ENTITY_KIND
};

enum EntityFlag {
	EntityFlag_Visited       = 1<<0,
	EntityFlag_Used          = 1<<1,
	EntityFlag_Using         = 1<<2,
	EntityFlag_Field         = 1<<3,
	EntityFlag_Param         = 1<<4,
	EntityFlag_Result        = 1<<5,
	EntityFlag_ArrayElem     = 1<<6,
	EntityFlag_Ellipsis      = 1<<7,
	EntityFlag_NoAlias       = 1<<8,
	EntityFlag_TypeField     = 1<<9,
	EntityFlag_Value         = 1<<10,
	EntityFlag_Sret          = 1<<11,
	EntityFlag_BitFieldValue = 1<<12,
	EntityFlag_PolyConst     = 1<<13,

	EntityFlag_CVarArg       = 1<<20,
};

// Zero value means the overloading process is not yet done
enum OverloadKind {
	Overload_Unknown = 0,
	Overload_No      = 1,
	Overload_Yes     = 2,
};

enum EntityState {
	EntityState_Unresolved = 0,
	EntityState_InProgress  = 1,
	EntityState_Resolved   = 2,
};


// An Entity is a named "thing" in the language
struct Entity {
	EntityKind  kind;
	u64         id;
	u32         flags;
	EntityState state;
	Token       token;
	Scope *     scope;
	Type *      type;
	AstNode *   identifier; // Can be nullptr
	DeclInfo *  decl_info;
	DeclInfo *  parent_proc_decl; // nullptr if in file/global scope

	// TODO(bill): Cleanup how `using` works for entities
	Entity *    using_parent;
	AstNode *   using_expr;

	isize       order_in_src;
	String      deprecated_message;

	union {
		struct {
			ExactValue value;
		} Constant;
		struct {
			i32        field_index;
			i32        field_src_index;
			ExactValue default_value;
			Entity *   foreign_library;
			AstNode *  foreign_library_ident;
			String     link_name;
			String     link_prefix;
			String     thread_local_model;
			bool       default_is_nil;
			bool       default_is_undef;
			bool       default_is_location;
			bool       is_immutable;
			bool       is_foreign;
			bool       is_export;
		} Variable;
		struct {
			bool   is_type_alias;
			Type * type_parameter_specialization;
			String ir_mangled_name;
		} TypeName;
		struct {
			OverloadKind overload_kind;
			String       link_name;
			String       link_prefix;
			u64          tags;
			bool         is_export;
			bool         is_foreign;
			Entity *     foreign_library;
			AstNode *    foreign_library_ident;
		} Procedure;
		struct {
			Array<Entity *> entities;
		} ProcGroup;
		struct {
			i32 id;
		} Builtin;
		struct {
			Entity *base;
		} Alias;
		struct {
			String path;
			String name;
			Scope *scope;
			bool   used;
		} ImportName;
		struct {
			String path;
			String name;
			bool   used;
		} LibraryName;
		i32 Nil;
		struct {
			String   name;
			AstNode *node;
		} Label;
	};
};

gb_global Entity *e_context = nullptr;

bool is_entity_kind_exported(EntityKind kind) {
	switch (kind) {
	case Entity_Builtin:
	case Entity_ImportName:
	case Entity_LibraryName:
	case Entity_Nil:
		return false;
	}
	return true;
}

bool is_entity_exported(Entity *e) {
	// TODO(bill): Determine the actual exportation rules for imports of entities
	GB_ASSERT(e != nullptr);
	if (!is_entity_kind_exported(e->kind)) {
		return false;
	}

	String name = e->token.string;
	if (name.len == 0) {
		return false;
	}
	return name[0] != '_';
}


gb_global u64 global_entity_id = 0;

Entity *alloc_entity(EntityKind kind, Scope *scope, Token token, Type *type) {
	gbAllocator a = heap_allocator();
	Entity *entity = gb_alloc_item(a, Entity);
	entity->kind   = kind;
	entity->state  = EntityState_Unresolved;
	entity->scope  = scope;
	entity->token  = token;
	entity->type   = type;
	entity->id     = ++global_entity_id;
	return entity;
}

Entity *alloc_entity_variable(Scope *scope, Token token, Type *type, bool is_immutable, EntityState state = EntityState_Unresolved) {
	Entity *entity = alloc_entity(Entity_Variable, scope, token, type);
	entity->Variable.is_immutable = is_immutable;
	entity->state = state;
	return entity;
}

Entity *alloc_entity_using_variable(Entity *parent, Token token, Type *type) {
	GB_ASSERT(parent != nullptr);
	token.pos = parent->token.pos;
	Entity *entity = alloc_entity(Entity_Variable, parent->scope, token, type);
	entity->using_parent = parent;
	entity->parent_proc_decl = parent->parent_proc_decl;
	entity->flags |= EntityFlag_Using;
	entity->flags |= EntityFlag_Used;
	entity->state = EntityState_Resolved;
	return entity;
}


Entity *alloc_entity_constant(Scope *scope, Token token, Type *type, ExactValue value) {
	Entity *entity = alloc_entity(Entity_Constant, scope, token, type);
	entity->Constant.value = value;
	return entity;
}

Entity *alloc_entity_type_name(Scope *scope, Token token, Type *type, EntityState state = EntityState_Unresolved) {
	Entity *entity = alloc_entity(Entity_TypeName, scope, token, type);
	entity->state = state;
	return entity;
}

Entity *alloc_entity_param(Scope *scope, Token token, Type *type, bool is_using, bool is_value) {
	bool is_immutable = false;
	Entity *entity = alloc_entity_variable(scope, token, type, is_immutable);
	entity->flags |= EntityFlag_Used;
	entity->flags |= EntityFlag_Param;
	entity->state = EntityState_Resolved;
	if (is_using) entity->flags |= EntityFlag_Using;
	if (is_value) entity->flags |= EntityFlag_Value;
	return entity;
}


Entity *alloc_entity_const_param(Scope *scope, Token token, Type *type, ExactValue value, bool poly_const) {
	Entity *entity = alloc_entity_constant(scope, token, type, value);
	entity->flags |= EntityFlag_Used;
	if (poly_const) entity->flags |= EntityFlag_PolyConst;
	entity->flags |= EntityFlag_Param;
	return entity;
}


Entity *alloc_entity_field(Scope *scope, Token token, Type *type, bool is_using, i32 field_src_index, EntityState state = EntityState_Unresolved) {
	Entity *entity = alloc_entity_variable(scope, token, type, false);
	entity->Variable.field_src_index = field_src_index;
	entity->Variable.field_index = field_src_index;
	if (is_using) entity->flags |= EntityFlag_Using;
	entity->flags |= EntityFlag_Field;
	entity->state = state;
	return entity;
}

Entity *alloc_entity_array_elem(Scope *scope, Token token, Type *type, i32 field_src_index) {
	Entity *entity = alloc_entity_variable(scope, token, type, false);
	entity->Variable.field_src_index = field_src_index;
	entity->Variable.field_index = field_src_index;
	entity->flags |= EntityFlag_Field;
	entity->flags |= EntityFlag_ArrayElem;
	entity->state = EntityState_Resolved;
	return entity;
}

Entity *alloc_entity_procedure(Scope *scope, Token token, Type *signature_type, u64 tags) {
	Entity *entity = alloc_entity(Entity_Procedure, scope, token, signature_type);
	entity->Procedure.tags = tags;
	return entity;
}

Entity *alloc_entity_proc_group(Scope *scope, Token token, Type *type) {
	Entity *entity = alloc_entity(Entity_ProcGroup, scope, token, type);
	return entity;
}


Entity *alloc_entity_builtin(Scope *scope, Token token, Type *type, i32 id) {
	Entity *entity = alloc_entity(Entity_Builtin, scope, token, type);
	entity->Builtin.id = id;
	entity->state = EntityState_Resolved;
	return entity;
}

Entity *alloc_entity_alias(Scope *scope, Token token, Type *type, Entity *base) {
	Entity *entity = alloc_entity(Entity_Alias, scope, token, type);
	entity->Alias.base = base;
	return entity;
}

Entity *alloc_entity_import_name(Scope *scope, Token token, Type *type,
                                 String path, String name, Scope *import_scope) {
	Entity *entity = alloc_entity(Entity_ImportName, scope, token, type);
	entity->ImportName.path = path;
	entity->ImportName.name = name;
	entity->ImportName.scope = import_scope;
	entity->state = EntityState_Resolved; // TODO(bill): Is this correct?
	return entity;
}

Entity *alloc_entity_library_name(Scope *scope, Token token, Type *type,
                                  String path, String name) {
	Entity *entity = alloc_entity(Entity_LibraryName, scope, token, type);
	entity->LibraryName.path = path;
	entity->LibraryName.name = name;
	entity->state = EntityState_Resolved; // TODO(bill): Is this correct?
	return entity;
}





Entity *alloc_entity_nil(String name, Type *type) {
	Entity *entity = alloc_entity(Entity_Nil, nullptr, make_token_ident(name), type);
	return entity;
}

Entity *alloc_entity_label(Scope *scope, Token token, Type *type, AstNode *node) {
	Entity *entity = alloc_entity(Entity_Label, scope, token, type);
	entity->Label.node = node;
	entity->state = EntityState_Resolved;
	return entity;
}

Entity *alloc_entity_dummy_variable(Scope *scope, Token token) {
	token.string = str_lit("_");
	return alloc_entity_variable(scope, token, nullptr, false);
}

