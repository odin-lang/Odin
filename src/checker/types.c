typedef struct Scope Scope;

typedef enum BasicKind {
	Basic_Invalid,
	Basic_bool,
	Basic_i8,
	Basic_u8,
	Basic_i16,
	Basic_u16,
	Basic_i32,
	Basic_u32,
	Basic_i64,
	Basic_u64,
	Basic_i128,
	Basic_u128,
	// Basic_f16,
	Basic_f32,
	Basic_f64,
	// Basic_f128,
	Basic_int,
	Basic_uint,
	Basic_rawptr,
	Basic_string, // ^u8 + int
	Basic_any,    // ^Type_Info + rawptr

	Basic_UntypedBool,
	Basic_UntypedInteger,
	Basic_UntypedFloat,
	Basic_UntypedString,
	Basic_UntypedRune,
	Basic_UntypedNil,

	Basic_Count,

	Basic_byte = Basic_u8,
	Basic_rune = Basic_i32,
} BasicKind;

typedef enum BasicFlag {
	BasicFlag_Boolean  = GB_BIT(0),
	BasicFlag_Integer  = GB_BIT(1),
	BasicFlag_Unsigned = GB_BIT(2),
	BasicFlag_Float    = GB_BIT(3),
	BasicFlag_Pointer  = GB_BIT(4),
	BasicFlag_String   = GB_BIT(5),
	BasicFlag_Rune     = GB_BIT(6),
	BasicFlag_Untyped  = GB_BIT(7),

	BasicFlag_Numeric      = BasicFlag_Integer | BasicFlag_Float,
	BasicFlag_Ordered      = BasicFlag_Numeric | BasicFlag_String  | BasicFlag_Pointer,
	BasicFlag_ConstantType = BasicFlag_Boolean | BasicFlag_Numeric | BasicFlag_Pointer | BasicFlag_String | BasicFlag_Rune,
} BasicFlag;

typedef struct BasicType {
	BasicKind kind;
	u32       flags;
	i64       size; // -1 if arch. dep.
	String    name;
} BasicType;

typedef enum TypeRecordKind {
	TypeRecord_Invalid,

	TypeRecord_Struct,
	TypeRecord_Enum,
	TypeRecord_RawUnion,
	TypeRecord_Union, // Tagged

	TypeRecord_Count,
} TypeRecordKind;

typedef struct TypeRecord {
	TypeRecordKind kind;

	// All record types
	// Theses are arrays
	Entity **fields;      // Entity_Variable (otherwise Entity_TypeName if union)
	i32      field_count; // == offset_count is struct
	AstNode *node;

	union { // NOTE(bill): Reduce size_of Type
		struct { // enum only
			Type *   enum_base; // Default is `int`
			Entity * enum_count;
			Entity * min_value;
			Entity * max_value;
		};
		struct { // struct only
			i64 *    struct_offsets;
			bool      struct_are_offsets_set;
			bool      struct_is_packed;
			bool      struct_is_ordered;
			Entity **fields_in_src_order; // Entity_Variable
		};
	};

	// Entity_Constant or Entity_TypeName
	Entity **other_fields;
	i32      other_field_count;
} TypeRecord;

#define TYPE_KINDS \
	TYPE_KIND(Basic,   BasicType) \
	TYPE_KIND(Pointer, struct { Type *elem; }) \
	TYPE_KIND(Array,   struct { Type *elem; i64 count; }) \
	TYPE_KIND(Vector,  struct { Type *elem; i64 count; }) \
	TYPE_KIND(Slice,   struct { Type *elem; }) \
	TYPE_KIND(Maybe,   struct { Type *elem; }) \
	TYPE_KIND(Record,  TypeRecord) \
	TYPE_KIND(Named, struct { \
		String  name; \
		Type *  base; \
		Entity *type_name; /* Entity_TypeName */ \
	}) \
	TYPE_KIND(Tuple, struct { \
		Entity **variables; /* Entity_Variable */ \
		i32      variable_count; \
		bool     are_offsets_set; \
		i64 *    offsets; \
	}) \
	TYPE_KIND(Proc, struct { \
		Scope *scope; \
		Type * params;  /* Type_Tuple */ \
		Type * results; /* Type_Tuple */ \
		i32    param_count; \
		i32    result_count; \
		bool   variadic; \
	})

typedef enum TypeKind {
	Type_Invalid,
#define TYPE_KIND(k, ...) GB_JOIN2(Type_, k),
	TYPE_KINDS
#undef TYPE_KIND
	Type_Count,
} TypeKind;

String const type_strings[] = {
	{cast(u8 *)"Invalid", gb_size_of("Invalid")},
#define TYPE_KIND(k, ...) {cast(u8 *)#k, gb_size_of(#k)-1},
	TYPE_KINDS
#undef TYPE_KIND
};

#define TYPE_KIND(k, ...) typedef __VA_ARGS__ GB_JOIN2(Type, k);
	TYPE_KINDS
#undef TYPE_KIND

typedef struct Type {
	TypeKind kind;
	union {
#define TYPE_KIND(k, ...) GB_JOIN2(Type, k) k;
	TYPE_KINDS
#undef TYPE_KIND
	};
} Type;

// NOTE(bill): Internal sizes of certain types
// string: 2*word_size  (ptr+len)
// slice:  3*word_size  (ptr+len+cap)
// array:  count*size_of(elem) aligned

// NOTE(bill): Alignment of structures and other types are to be compatible with C

typedef struct BaseTypeSizes {
	i64 word_size;
	i64 max_align;
} BaseTypeSizes;

typedef Array(isize) Array_isize;

typedef struct Selection {
	Entity *    entity;
	Array_isize index;
	bool        indirect; // Set if there was a pointer deref anywhere down the line
} Selection;
Selection empty_selection = {0};

Selection make_selection(Entity *entity, Array_isize index, bool indirect) {
	Selection s = {entity, index, indirect};
	return s;
}

void selection_add_index(Selection *s, isize index) {
	// IMPORTANT NOTE(bill): this requires a stretchy buffer/dynamic array so it requires some form
	// of heap allocation
	if (s->index.e == NULL) {
		array_init(&s->index, heap_allocator());
	}
	array_add(&s->index, index);
}



#define STR_LIT(x) {cast(u8 *)(x), gb_size_of(x)-1}
gb_global Type basic_types[] = {
	{Type_Basic, {Basic_Invalid,        0,                                       0, STR_LIT("invalid type")}},
	{Type_Basic, {Basic_bool,           BasicFlag_Boolean,                       1, STR_LIT("bool")}},
	{Type_Basic, {Basic_i8,             BasicFlag_Integer,                       1, STR_LIT("i8")}},
	{Type_Basic, {Basic_u8,             BasicFlag_Integer | BasicFlag_Unsigned,  1, STR_LIT("u8")}},
	{Type_Basic, {Basic_i16,            BasicFlag_Integer,                       2, STR_LIT("i16")}},
	{Type_Basic, {Basic_u16,            BasicFlag_Integer | BasicFlag_Unsigned,  2, STR_LIT("u16")}},
	{Type_Basic, {Basic_i32,            BasicFlag_Integer,                       4, STR_LIT("i32")}},
	{Type_Basic, {Basic_u32,            BasicFlag_Integer | BasicFlag_Unsigned,  4, STR_LIT("u32")}},
	{Type_Basic, {Basic_i64,            BasicFlag_Integer,                       8, STR_LIT("i64")}},
	{Type_Basic, {Basic_u64,            BasicFlag_Integer | BasicFlag_Unsigned,  8, STR_LIT("u64")}},
	{Type_Basic, {Basic_i128,           BasicFlag_Integer,                      16, STR_LIT("i128")}},
	{Type_Basic, {Basic_u128,           BasicFlag_Integer | BasicFlag_Unsigned, 16, STR_LIT("u128")}},
	// {Type_Basic, {Basic_f16,            BasicFlag_Float,                         2, STR_LIT("f16")}},
	{Type_Basic, {Basic_f32,            BasicFlag_Float,                         4, STR_LIT("f32")}},
	{Type_Basic, {Basic_f64,            BasicFlag_Float,                         8, STR_LIT("f64")}},
	// {Type_Basic, {Basic_f128,           BasicFlag_Float,                        16, STR_LIT("f128")}},
	{Type_Basic, {Basic_int,            BasicFlag_Integer,                      -1, STR_LIT("int")}},
	{Type_Basic, {Basic_uint,           BasicFlag_Integer | BasicFlag_Unsigned, -1, STR_LIT("uint")}},
	{Type_Basic, {Basic_rawptr,         BasicFlag_Pointer,                      -1, STR_LIT("rawptr")}},
	{Type_Basic, {Basic_string,         BasicFlag_String,                       -1, STR_LIT("string")}},
	{Type_Basic, {Basic_any,            0,                                      -1, STR_LIT("any")}},
	{Type_Basic, {Basic_UntypedBool,    BasicFlag_Boolean | BasicFlag_Untyped,   0, STR_LIT("untyped bool")}},
	{Type_Basic, {Basic_UntypedInteger, BasicFlag_Integer | BasicFlag_Untyped,   0, STR_LIT("untyped integer")}},
	{Type_Basic, {Basic_UntypedFloat,   BasicFlag_Float   | BasicFlag_Untyped,   0, STR_LIT("untyped float")}},
	{Type_Basic, {Basic_UntypedString,  BasicFlag_String  | BasicFlag_Untyped,   0, STR_LIT("untyped string")}},
	{Type_Basic, {Basic_UntypedRune,    BasicFlag_Integer | BasicFlag_Untyped,   0, STR_LIT("untyped rune")}},
	{Type_Basic, {Basic_UntypedNil,     BasicFlag_Untyped,                       0, STR_LIT("untyped nil")}},
};

gb_global Type basic_type_aliases[] = {
	{Type_Basic, {Basic_byte, BasicFlag_Integer | BasicFlag_Unsigned, 1, STR_LIT("byte")}},
	{Type_Basic, {Basic_rune, BasicFlag_Integer,                      4, STR_LIT("rune")}},
};

gb_global Type *t_invalid         = &basic_types[Basic_Invalid];
gb_global Type *t_bool            = &basic_types[Basic_bool];
gb_global Type *t_i8              = &basic_types[Basic_i8];
gb_global Type *t_u8              = &basic_types[Basic_u8];
gb_global Type *t_i16             = &basic_types[Basic_i16];
gb_global Type *t_u16             = &basic_types[Basic_u16];
gb_global Type *t_i32             = &basic_types[Basic_i32];
gb_global Type *t_u32             = &basic_types[Basic_u32];
gb_global Type *t_i64             = &basic_types[Basic_i64];
gb_global Type *t_u64             = &basic_types[Basic_u64];
gb_global Type *t_i128            = &basic_types[Basic_i128];
gb_global Type *t_u128            = &basic_types[Basic_u128];
// gb_global Type *t_f16             = &basic_types[Basic_f16];
gb_global Type *t_f32             = &basic_types[Basic_f32];
gb_global Type *t_f64             = &basic_types[Basic_f64];
// gb_global Type *t_f128            = &basic_types[Basic_f128];
gb_global Type *t_int             = &basic_types[Basic_int];
gb_global Type *t_uint            = &basic_types[Basic_uint];
gb_global Type *t_rawptr          = &basic_types[Basic_rawptr];
gb_global Type *t_string          = &basic_types[Basic_string];
gb_global Type *t_any             = &basic_types[Basic_any];
gb_global Type *t_untyped_bool    = &basic_types[Basic_UntypedBool];
gb_global Type *t_untyped_integer = &basic_types[Basic_UntypedInteger];
gb_global Type *t_untyped_float   = &basic_types[Basic_UntypedFloat];
gb_global Type *t_untyped_string  = &basic_types[Basic_UntypedString];
gb_global Type *t_untyped_rune    = &basic_types[Basic_UntypedRune];
gb_global Type *t_untyped_nil     = &basic_types[Basic_UntypedNil];
gb_global Type *t_byte            = &basic_type_aliases[0];
gb_global Type *t_rune            = &basic_type_aliases[1];


gb_global Type *t_u8_ptr  = NULL;
gb_global Type *t_int_ptr = NULL;

gb_global Type *t_type_info            = NULL;
gb_global Type *t_type_info_ptr        = NULL;
gb_global Type *t_type_info_member     = NULL;
gb_global Type *t_type_info_member_ptr = NULL;

gb_global Type *t_type_info_named      = NULL;
gb_global Type *t_type_info_integer    = NULL;
gb_global Type *t_type_info_float      = NULL;
gb_global Type *t_type_info_any        = NULL;
gb_global Type *t_type_info_string     = NULL;
gb_global Type *t_type_info_boolean    = NULL;
gb_global Type *t_type_info_pointer    = NULL;
gb_global Type *t_type_info_maybe      = NULL;
gb_global Type *t_type_info_procedure  = NULL;
gb_global Type *t_type_info_array      = NULL;
gb_global Type *t_type_info_slice      = NULL;
gb_global Type *t_type_info_vector     = NULL;
gb_global Type *t_type_info_tuple      = NULL;
gb_global Type *t_type_info_struct     = NULL;
gb_global Type *t_type_info_union      = NULL;
gb_global Type *t_type_info_raw_union  = NULL;
gb_global Type *t_type_info_enum       = NULL;

gb_global Type *t_allocator            = NULL;
gb_global Type *t_allocator_ptr        = NULL;
gb_global Type *t_context              = NULL;
gb_global Type *t_context_ptr          = NULL;






gbString type_to_string(Type *type);

Type *base_type(Type *t) {
	for (;;) {
		if (t == NULL || t->kind != Type_Named) {
			break;
		}
		t = t->Named.base;
	}
	return t;
}

void set_base_type(Type *t, Type *base) {
	if (t && t->kind == Type_Named) {
		t->Named.base = base;
	}
}


Type *alloc_type(gbAllocator a, TypeKind kind) {
	Type *t = gb_alloc_item(a, Type);
	t->kind = kind;
	return t;
}


Type *make_type_basic(gbAllocator a, BasicType basic) {
	Type *t = alloc_type(a, Type_Basic);
	t->Basic = basic;
	return t;
}

Type *make_type_pointer(gbAllocator a, Type *elem) {
	Type *t = alloc_type(a, Type_Pointer);
	t->Pointer.elem = elem;
	return t;
}

Type *make_type_maybe(gbAllocator a, Type *elem) {
	Type *t = alloc_type(a, Type_Maybe);
	t->Maybe.elem = elem;
	return t;
}

Type *make_type_array(gbAllocator a, Type *elem, i64 count) {
	Type *t = alloc_type(a, Type_Array);
	t->Array.elem = elem;
	t->Array.count = count;
	return t;
}

Type *make_type_vector(gbAllocator a, Type *elem, i64 count) {
	Type *t = alloc_type(a, Type_Vector);
	t->Vector.elem = elem;
	t->Vector.count = count;
	return t;
}

Type *make_type_slice(gbAllocator a, Type *elem) {
	Type *t = alloc_type(a, Type_Slice);
	t->Array.elem = elem;
	return t;
}


Type *make_type_struct(gbAllocator a) {
	Type *t = alloc_type(a, Type_Record);
	t->Record.kind = TypeRecord_Struct;
	return t;
}

Type *make_type_union(gbAllocator a) {
	Type *t = alloc_type(a, Type_Record);
	t->Record.kind = TypeRecord_Union;
	return t;
}

Type *make_type_raw_union(gbAllocator a) {
	Type *t = alloc_type(a, Type_Record);
	t->Record.kind = TypeRecord_RawUnion;
	return t;
}

Type *make_type_enum(gbAllocator a) {
	Type *t = alloc_type(a, Type_Record);
	t->Record.kind = TypeRecord_Enum;
	return t;
}



Type *make_type_named(gbAllocator a, String name, Type *base, Entity *type_name) {
	Type *t = alloc_type(a, Type_Named);
	t->Named.name = name;
	t->Named.base = base;
	t->Named.type_name = type_name;
	return t;
}

Type *make_type_tuple(gbAllocator a) {
	Type *t = alloc_type(a, Type_Tuple);
	return t;
}

Type *make_type_proc(gbAllocator a, Scope *scope, Type *params, isize param_count, Type *results, isize result_count, bool variadic) {
	Type *t = alloc_type(a, Type_Proc);

	if (variadic) {
		if (param_count == 0) {
			GB_PANIC("variadic procedure must have at least one parameter");
		}
		GB_ASSERT(params != NULL && params->kind == Type_Tuple);
		Entity *e = params->Tuple.variables[param_count-1];
		if (base_type(e->type)->kind != Type_Slice) {
			// NOTE(bill): For custom calling convention
			GB_PANIC("variadic parameter must be of type slice");
		}
	}

	t->Proc.scope        = scope;
	t->Proc.params       = params;
	t->Proc.param_count  = param_count;
	t->Proc.results      = results;
	t->Proc.result_count = result_count;
	t->Proc.variadic     = variadic;
	return t;
}


Type *type_deref(Type *t) {
	if (t != NULL) {
		Type *bt = base_type(t);
		if (bt == NULL)
			return NULL;
		if (bt != NULL && bt->kind == Type_Pointer)
			return bt->Pointer.elem;
	}
	return t;
}

Type *get_enum_base_type(Type *t) {
	Type *bt = base_type(t);
	if (bt->kind == Type_Record && bt->Record.kind == TypeRecord_Enum) {
		GB_ASSERT(bt->Record.enum_base != NULL);
		return bt->Record.enum_base;
	}
	return t;
}

bool is_type_named(Type *t) {
	if (t->kind == Type_Basic) {
		return true;
	}
	return t->kind == Type_Named;
}
bool is_type_boolean(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Boolean) != 0;
	}
	return false;
}
bool is_type_integer(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Integer) != 0;
	}
	return false;
}
bool is_type_unsigned(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Unsigned) != 0;
	}
	return false;
}
bool is_type_numeric(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Numeric) != 0;
	}
	if (t->kind == Type_Vector) {
		return is_type_numeric(t->Vector.elem);
	}
	return false;
}
bool is_type_string(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_String) != 0;
	}
	return false;
}
bool is_type_typed(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Untyped) == 0;
	}
	return true;
}
bool is_type_untyped(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Untyped) != 0;
	}
	return false;
}
bool is_type_ordered(Type *t) {
	t = base_type(get_enum_base_type(t));
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Ordered) != 0;
	}
	if (t->kind == Type_Pointer) {
		return true;
	}
	return false;
}
bool is_type_constant_type(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_ConstantType) != 0;
	}
	if (t->kind == Type_Record) {
		return t->Record.kind == TypeRecord_Enum;
	}
	return false;
}
bool is_type_float(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Float) != 0;
	}
	return false;
}
bool is_type_f32(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return t->Basic.kind == Basic_f32;
	}
	return false;
}
bool is_type_f64(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return t->Basic.kind == Basic_f64;
	}
	return false;
}
bool is_type_pointer(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Pointer) != 0;
	}
	return t->kind == Type_Pointer;
}
bool is_type_maybe(Type *t) {
	t = base_type(t);
	return t->kind == Type_Maybe;
}
bool is_type_tuple(Type *t) {
	t = base_type(t);
	return t->kind == Type_Tuple;
}


bool is_type_int_or_uint(Type *t) {
	if (t->kind == Type_Basic) {
		return (t->Basic.kind == Basic_int) || (t->Basic.kind == Basic_uint);
	}
	return false;
}
bool is_type_rawptr(Type *t) {
	if (t->kind == Type_Basic) {
		return t->Basic.kind == Basic_rawptr;
	}
	return false;
}
bool is_type_u8(Type *t) {
	if (t->kind == Type_Basic) {
		return t->Basic.kind == Basic_u8;
	}
	return false;
}
bool is_type_array(Type *t) {
	t = base_type(t);
	return t->kind == Type_Array;
}
bool is_type_slice(Type *t) {
	t = base_type(t);
	return t->kind == Type_Slice;
}
bool is_type_u8_slice(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Slice) {
		return is_type_u8(t->Slice.elem);
	}
	return false;
}
bool is_type_vector(Type *t) {
	t = base_type(t);
	return t->kind == Type_Vector;
}
bool is_type_proc(Type *t) {
	t = base_type(t);
	return t->kind == Type_Proc;
}
Type *base_vector_type(Type *t) {
	if (is_type_vector(t)) {
		t = base_type(t);
		return t->Vector.elem;
	}
	return t;
}


bool is_type_enum(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Record && t->Record.kind == TypeRecord_Enum);
}
bool is_type_struct(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Record && t->Record.kind == TypeRecord_Struct);
}
bool is_type_union(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Record && t->Record.kind == TypeRecord_Union);
}
bool is_type_raw_union(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Record && t->Record.kind == TypeRecord_RawUnion);
}

bool is_type_any(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_any);
}
bool is_type_untyped_nil(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_UntypedNil);
}



bool is_type_indexable(Type *t) {
	return is_type_array(t) || is_type_slice(t) || is_type_vector(t) || is_type_string(t);
}


bool type_has_nil(Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Basic:
		return is_type_rawptr(t);

	case Type_Tuple:
		return false;

	case Type_Record:
		switch (t->Record.kind) {
		case TypeRecord_Enum:
			return false;
		}
		break;
	}
	return true;
}


bool is_type_comparable(Type *t) {
	t = base_type(get_enum_base_type(t));
	switch (t->kind) {
	case Type_Basic:
		return t->kind != Basic_UntypedNil;
	case Type_Pointer:
		return true;
	case Type_Record: {
		if (false && is_type_struct(t)) {
			// TODO(bill): Should I even allow this?
			for (isize i = 0; i < t->Record.field_count; i++) {
				if (!is_type_comparable(t->Record.fields[i]->type))
					return false;
			}
		} else if (is_type_enum(t)) {
			return is_type_comparable(t->Record.enum_base);
		}
		return false;
	} break;
	case Type_Array:
		return is_type_comparable(t->Array.elem);
	case Type_Vector:
		return is_type_comparable(t->Vector.elem);
	case Type_Proc:
		return true;
	}
	return false;
}

bool are_types_identical(Type *x, Type *y) {
	if (x == y)
		return true;

	if ((x == NULL && y != NULL) ||
	    (x != NULL && y == NULL)) {
		return false;
	}

	switch (x->kind) {
	case Type_Basic:
		if (y->kind == Type_Basic) {
			return x->Basic.kind == y->Basic.kind;
		}
		break;

	case Type_Array:
		if (y->kind == Type_Array) {
			return (x->Array.count == y->Array.count) && are_types_identical(x->Array.elem, y->Array.elem);
		}
		break;

	case Type_Vector:
		if (y->kind == Type_Vector) {
			return (x->Vector.count == y->Vector.count) && are_types_identical(x->Vector.elem, y->Vector.elem);
		}
		break;

	case Type_Slice:
		if (y->kind == Type_Slice) {
			return are_types_identical(x->Slice.elem, y->Slice.elem);
		}
		break;

	case Type_Record:
		if (y->kind == Type_Record) {
			if (x->Record.kind == y->Record.kind) {
				switch (x->Record.kind) {
				case TypeRecord_Struct:
				case TypeRecord_RawUnion:
				case TypeRecord_Union:
					if (x->Record.field_count == y->Record.field_count &&
					    x->Record.struct_is_packed == y->Record.struct_is_packed &&
					    x->Record.struct_is_ordered == y->Record.struct_is_ordered) {
						for (isize i = 0; i < x->Record.field_count; i++) {
							if (!are_types_identical(x->Record.fields[i]->type, y->Record.fields[i]->type)) {
								return false;
							}
							if (str_ne(x->Record.fields[i]->token.string, y->Record.fields[i]->token.string)) {
								return false;
							}
						}
						return true;
					}
					break;

				case TypeRecord_Enum:
					// NOTE(bill): Each enum is unique
					return x == y;
				}
			}
		}
		break;

	case Type_Pointer:
		if (y->kind == Type_Pointer) {
			return are_types_identical(x->Pointer.elem, y->Pointer.elem);
		}
		break;

	case Type_Maybe:
		if (y->kind == Type_Maybe) {
			return are_types_identical(x->Maybe.elem, y->Maybe.elem);
		}
		break;

	case Type_Named:
		if (y->kind == Type_Named) {
			return x->Named.base == y->Named.base;
		}
		break;

	case Type_Tuple:
		if (y->kind == Type_Tuple) {
			if (x->Tuple.variable_count == y->Tuple.variable_count) {
				for (isize i = 0; i < x->Tuple.variable_count; i++) {
					if (!are_types_identical(x->Tuple.variables[i]->type, y->Tuple.variables[i]->type)) {
						return false;
					}
				}
				return true;
			}
		}
		break;

	case Type_Proc:
		if (y->kind == Type_Proc) {
			return are_types_identical(x->Proc.params, y->Proc.params) &&
			       are_types_identical(x->Proc.results, y->Proc.results);
		}
		break;
	}


	return false;
}


Type *default_type(Type *type) {
	if (type->kind == Type_Basic) {
		switch (type->Basic.kind) {
		case Basic_UntypedBool:    return t_bool;
		case Basic_UntypedInteger: return t_int;
		case Basic_UntypedFloat:   return t_f64;
		case Basic_UntypedString:  return t_string;
		case Basic_UntypedRune:    return t_rune;
		}
	}
	return type;
}




gb_global Entity *entity__any_type_info  = NULL;
gb_global Entity *entity__any_data       = NULL;
gb_global Entity *entity__string_data    = NULL;
gb_global Entity *entity__string_count   = NULL;
gb_global Entity *entity__slice_count    = NULL;
gb_global Entity *entity__slice_capacity = NULL;

Selection lookup_field_with_selection(gbAllocator a, Type *type_, String field_name, bool is_type, Selection sel);

Selection lookup_field(gbAllocator a, Type *type_, String field_name, bool is_type) {
	return lookup_field_with_selection(a, type_, field_name, is_type, empty_selection);
}

Selection lookup_field_with_selection(gbAllocator a, Type *type_, String field_name, bool is_type, Selection sel) {
	GB_ASSERT(type_ != NULL);

	if (str_eq(field_name, str_lit("_"))) {
		return empty_selection;
	}

	Type *type = type_deref(type_);
	bool is_ptr = type != type_;
	sel.indirect = sel.indirect || is_ptr;

	type = base_type(type);

	if (type->kind == Type_Basic) {
		switch (type->Basic.kind) {
		case Basic_any: {
			String type_info_str = str_lit("type_info");
			String data_str = str_lit("data");
			if (entity__any_type_info == NULL) {
				entity__any_type_info = make_entity_field(a, NULL, make_token_ident(type_info_str), t_type_info_ptr, false, 0);
			}
			if (entity__any_data == NULL) {
				entity__any_data = make_entity_field(a, NULL, make_token_ident(data_str), t_rawptr, false, 1);
			}

			if (str_eq(field_name, type_info_str)) {
				selection_add_index(&sel, 0);
				sel.entity = entity__any_type_info;
				return sel;
			} else if (str_eq(field_name, data_str)) {
				selection_add_index(&sel, 1);
				sel.entity = entity__any_data;
				return sel;
			}
		} break;
		case Basic_string: {
			String data_str = str_lit("data");
			String count_str = str_lit("count");
			if (entity__string_data == NULL) {
				entity__string_data = make_entity_field(a, NULL, make_token_ident(data_str), make_type_pointer(a, t_u8), false, 0);
			}

			if (entity__string_count == NULL) {
				entity__string_count = make_entity_field(a, NULL, make_token_ident(count_str), t_int, false, 1);
			}

			if (str_eq(field_name, data_str)) {
				selection_add_index(&sel, 0);
				sel.entity = entity__string_data;
				return sel;
			} else if (str_eq(field_name, count_str)) {
				selection_add_index(&sel, 1);
				sel.entity = entity__string_count;
				return sel;
			}
		} break;
		}

		return sel;
	} else if (type->kind == Type_Array) {
		String count_str = str_lit("count");
		// NOTE(bill): Underlying memory address cannot be changed
		if (str_eq(field_name, count_str)) {
			// HACK(bill): Memory leak
			sel.entity = make_entity_constant(a, NULL, make_token_ident(count_str), t_int, make_exact_value_integer(type->Array.count));
			return sel;
		}
	} else if (type->kind == Type_Vector) {
		String count_str = str_lit("count");
		// NOTE(bill): Vectors are not addressable
		if (str_eq(field_name, count_str)) {
			// HACK(bill): Memory leak
			sel.entity = make_entity_constant(a, NULL, make_token_ident(count_str), t_int, make_exact_value_integer(type->Vector.count));
			return sel;
		}

		if (type->Vector.count <= 4 && !is_type_boolean(type->Vector.elem)) {
			// HACK(bill): Memory leak
			switch (type->Vector.count) {
			#define _VECTOR_FIELD_CASE(_length, _name) \
			case (_length): \
				if (str_eq(field_name, str_lit(_name))) { \
					selection_add_index(&sel, (_length)-1); \
					sel.entity = make_entity_vector_elem(a, NULL, make_token_ident(str_lit(_name)), type->Vector.elem, (_length)-1); \
					return sel; \
				} \
				/*fallthrough*/

			_VECTOR_FIELD_CASE(4, "w");
			_VECTOR_FIELD_CASE(3, "z");
			_VECTOR_FIELD_CASE(2, "y");
			_VECTOR_FIELD_CASE(1, "x");
			default: break;

			#undef _VECTOR_FIELD_CASE
			}
		}

	} else if (type->kind == Type_Slice) {
		String data_str     = str_lit("data");
		String count_str    = str_lit("count");
		String capacity_str = str_lit("capacity");

		if (str_eq(field_name, data_str)) {
			selection_add_index(&sel, 0);
			// HACK(bill): Memory leak
			sel.entity = make_entity_field(a, NULL, make_token_ident(data_str), make_type_pointer(a, type->Slice.elem), false, 0);
			return sel;
		} else if (str_eq(field_name, count_str)) {
			selection_add_index(&sel, 1);
			if (entity__slice_count == NULL) {
				entity__slice_count = make_entity_field(a, NULL, make_token_ident(count_str), t_int, false, 1);
			}

			sel.entity = entity__slice_count;
			return sel;
		} else if (str_eq(field_name, capacity_str)) {
			selection_add_index(&sel, 2);
			if (entity__slice_capacity == NULL) {
				entity__slice_capacity = make_entity_field(a, NULL, make_token_ident(capacity_str), t_int, false, 2);
			}

			sel.entity = entity__slice_capacity;
			return sel;
		}
	}

	if (type->kind != Type_Record) {
		return sel;
	}
	if (is_type) {
		if (is_type_union(type)) {
			// NOTE(bill): The subtype for a union are stored in the fields
			// as they are "kind of" like variables but not
			for (isize i = 0; i < type->Record.field_count; i++) {
				Entity *f = type->Record.fields[i];
				GB_ASSERT(f->kind == Entity_TypeName);
				String str = f->token.string;

				if (str_eq(field_name, str)) {
					sel.entity = f;
					selection_add_index(&sel, i);
					return sel;
				}
			}
		}

		for (isize i = 0; i < type->Record.other_field_count; i++) {
			Entity *f = type->Record.other_fields[i];
			GB_ASSERT(f->kind != Entity_Variable);
			String str = f->token.string;

			if (str_eq(field_name, str)) {
				sel.entity = f;
				selection_add_index(&sel, i);
				return sel;
			}
		}

		if (is_type_enum(type)) {
			if (str_eq(field_name, str_lit("count"))) {
				sel.entity = type->Record.enum_count;
				return sel;
			} else if (str_eq(field_name, str_lit("min_value"))) {
				sel.entity = type->Record.min_value;
				return sel;
			} else if (str_eq(field_name, str_lit("max_value"))) {
				sel.entity = type->Record.max_value;
				return sel;
			}
		}

	} else if (!is_type_enum(type) && !is_type_union(type)) {
		for (isize i = 0; i < type->Record.field_count; i++) {
			Entity *f = type->Record.fields[i];
			GB_ASSERT(f->kind == Entity_Variable && f->flags & EntityFlag_Field);
			String str = f->token.string;
			if (str_eq(field_name, str)) {
				selection_add_index(&sel, i);  // HACK(bill): Leaky memory
				sel.entity = f;
				return sel;
			}

			if (f->flags & EntityFlag_Anonymous) {
				isize prev_count = sel.index.count;
				selection_add_index(&sel, i); // HACK(bill): Leaky memory

				sel = lookup_field_with_selection(a, f->type, field_name, is_type, sel);

				if (sel.entity != NULL) {
					if (is_type_pointer(f->type)) {
						sel.indirect = true;
					}
					return sel;
				}
				sel.index.count = prev_count;
			}
		}
	}

	return sel;
}



i64 type_size_of(BaseTypeSizes s, gbAllocator allocator, Type *t);
i64 type_align_of(BaseTypeSizes s, gbAllocator allocator, Type *t);
i64 type_offset_of(BaseTypeSizes s, gbAllocator allocator, Type *t, i64 index);

i64 align_formula(i64 size, i64 align) {
	if (align > 0) {
		i64 result = size + align-1;
		return result - result%align;
	}
	return size;
}

i64 type_align_of(BaseTypeSizes s, gbAllocator allocator, Type *t) {
	t = base_type(t);

	switch (t->kind) {
	case Type_Array:
		return type_align_of(s, allocator, t->Array.elem);
	case Type_Vector: {
		i64 size = type_size_of(s, allocator, t->Vector.elem);
		i64 count = gb_max(prev_pow2(t->Vector.count), 1);
		i64 total = size * count;
		return gb_clamp(total, 1, s.max_align);
	} break;

	case Type_Tuple: {
		i64 max = 1;
		for (isize i = 0; i < t->Tuple.variable_count; i++) {
			i64 align = type_align_of(s, allocator, t->Tuple.variables[i]->type);
			if (max < align) {
				max = align;
			}
		}
		return max;
	} break;

	case Type_Maybe:
		return gb_max(type_align_of(s, allocator, t->Maybe.elem), type_align_of(s, allocator, t_bool));

	case Type_Record: {
		switch (t->Record.kind) {
		case TypeRecord_Struct:
			if (t->Record.field_count > 0) {
				// TODO(bill): What is this supposed to be?
				if (t->Record.struct_is_packed) {
					i64 max = s.word_size;
					for (isize i = 1; i < t->Record.field_count; i++) {
						// NOTE(bill): field zero is null
						i64 align = type_align_of(s, allocator, t->Record.fields[i]->type);
						if (max < align) {
							max = align;
						}
					}
					return max;
				}
				return type_align_of(s, allocator, t->Record.fields[0]->type);
			}
			break;
		case TypeRecord_Union: {
			i64 max = 1;
			for (isize i = 1; i < t->Record.field_count; i++) {
				// NOTE(bill): field zero is null
				i64 align = type_align_of(s, allocator, t->Record.fields[i]->type);
				if (max < align) {
					max = align;
				}
			}
			return max;
		} break;
		case TypeRecord_RawUnion: {
			i64 max = 1;
			for (isize i = 0; i < t->Record.field_count; i++) {
				i64 align = type_align_of(s, allocator, t->Record.fields[i]->type);
				if (max < align) {
					max = align;
				}
			}
			return max;
		} break;
		case TypeRecord_Enum:
			return type_align_of(s, allocator, t->Record.enum_base);
		}
	} break;
	}

	// return gb_clamp(next_pow2(type_size_of(s, allocator, t)), 1, s.max_align);
	// NOTE(bill): Things that are bigger than s.word_size, are actually comprised of smaller types
	// TODO(bill): Is this correct for 128-bit types (integers)?
	return gb_clamp(next_pow2(type_size_of(s, allocator, t)), 1, s.word_size);
}

i64 *type_set_offsets_of(BaseTypeSizes s, gbAllocator allocator, Entity **fields, isize field_count, bool is_packed) {
	i64 *offsets = gb_alloc_array(allocator, i64, field_count);
	i64 curr_offset = 0;
	if (is_packed) {
		for (isize i = 0; i < field_count; i++) {
			offsets[i] = curr_offset;
			curr_offset += type_size_of(s, allocator, fields[i]->type);
		}

	} else {
		for (isize i = 0; i < field_count; i++) {
			i64 align = type_align_of(s, allocator, fields[i]->type);
			curr_offset = align_formula(curr_offset, align);
			offsets[i] = curr_offset;
			curr_offset += type_size_of(s, allocator, fields[i]->type);
		}
	}
	return offsets;
}

bool type_set_offsets(BaseTypeSizes s, gbAllocator allocator, Type *t) {
	t = base_type(t);
	if (is_type_struct(t)) {
		if (!t->Record.struct_are_offsets_set) {
			t->Record.struct_offsets = type_set_offsets_of(s, allocator, t->Record.fields, t->Record.field_count, t->Record.struct_is_packed);
			t->Record.struct_are_offsets_set = true;
			return true;
		}
	} else if (is_type_tuple(t)) {
		if (!t->Tuple.are_offsets_set) {
			t->Tuple.offsets = type_set_offsets_of(s, allocator, t->Tuple.variables, t->Tuple.variable_count, false);
			t->Tuple.are_offsets_set = true;
			return true;
		}
	} else {
		GB_PANIC("Invalid type for setting offsets");
	}
	return false;
}

i64 type_size_of(BaseTypeSizes s, gbAllocator allocator, Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Basic: {
		GB_ASSERT(is_type_typed(t));
		BasicKind kind = t->Basic.kind;
		i64 size = t->Basic.size;
		if (size > 0) {
			return size;
		}
		switch (kind) {
		case Basic_string: return 2*s.word_size;
		case Basic_any:    return 2*s.word_size;

		case Basic_int: case Basic_uint: case Basic_rawptr:
			return s.word_size;
		}
	} break;

	case Type_Array: {
		i64 count = t->Array.count;
		if (count == 0) {
			return 0;
		}
		i64 align = type_align_of(s, allocator, t->Array.elem);
		i64 size  = type_size_of(s,  allocator, t->Array.elem);
		i64 alignment = align_formula(size, align);
		return alignment*(count-1) + size;
	} break;

	case Type_Vector: {
		i64 count = t->Vector.count;
		if (count == 0) {
			return 0;
		}
		// i64 align = type_align_of(s, allocator, t->Vector.elem);
		i64 bit_size = 8*type_size_of(s,  allocator, t->Vector.elem);
		if (is_type_boolean(t->Vector.elem)) {
			bit_size = 1; // NOTE(bill): LLVM can store booleans as 1 bit because a boolean _is_ an `i1`
			              // Silly LLVM spec
		}
		i64 total_size_in_bits = bit_size * count;
		i64 total_size = (total_size_in_bits+7)/8;
		return total_size;
	} break;


	case Type_Slice: // ptr + len + cap
		return 3 * s.word_size;

	case Type_Maybe: { // value + bool
		Type *elem = t->Maybe.elem;
		i64 align = type_align_of(s, allocator, elem);
		i64 size = align_formula(type_size_of(s, allocator, elem), align);
		size += type_size_of(s, allocator, t_bool);
		return align_formula(size, align);
	}

	case Type_Tuple: {
		i64 count = t->Tuple.variable_count;
		if (count == 0) {
			return 0;
		}
		type_set_offsets(s, allocator, t);
		i64 size = t->Tuple.offsets[count-1] + type_size_of(s, allocator, t->Tuple.variables[count-1]->type);
		i64 align = type_align_of(s, allocator, t);
		return align_formula(size, align);
	} break;

	case Type_Record: {
		switch (t->Record.kind) {
		case TypeRecord_Struct: {
			i64 count = t->Record.field_count;
			if (count == 0) {
				return 0;
			}
			type_set_offsets(s, allocator, t);
			i64 size = t->Record.struct_offsets[count-1] + type_size_of(s, allocator, t->Record.fields[count-1]->type);
			i64 align = type_align_of(s, allocator, t);
			return align_formula(size, align);
		} break;

		case TypeRecord_Union: {
			i64 count = t->Record.field_count;
			i64 max = 0;
			// NOTE(bill): Zeroth field is invalid
			for (isize i = 1; i < count; i++) {
				i64 size = type_size_of(s, allocator, t->Record.fields[i]->type);
				if (max < size) {
					max = size;
				}
			}
			// NOTE(bill): Align to int
			i64 align = type_align_of(s, allocator, t);
			isize size =  align_formula(max, s.word_size);
			size += type_size_of(s, allocator, t_int);
			return align_formula(size, align);
		} break;

		case TypeRecord_RawUnion: {
			i64 count = t->Record.field_count;
			i64 max = 0;
			for (isize i = 0; i < count; i++) {
				i64 size = type_size_of(s, allocator, t->Record.fields[i]->type);
				if (max < size) {
					max = size;
				}
			}
			// TODO(bill): Is this how it should work?
			i64 align = type_align_of(s, allocator, t);
			return align_formula(max, align);
		} break;

		case TypeRecord_Enum: {
			return type_size_of(s, allocator, t->Record.enum_base);
		} break;
		}
	} break;
	}

	// Catch all
	return s.word_size;
}

i64 type_offset_of(BaseTypeSizes s, gbAllocator allocator, Type *t, isize index) {
	t = base_type(t);
	if (t->kind == Type_Record && t->Record.kind == TypeRecord_Struct) {
		type_set_offsets(s, allocator, t);
		if (gb_is_between(index, 0, t->Record.field_count-1)) {
			return t->Record.struct_offsets[index];
		}
	} else if (t->kind == Type_Tuple) {
		type_set_offsets(s, allocator, t);
		if (gb_is_between(index, 0, t->Tuple.variable_count-1)) {
			return t->Tuple.offsets[index];
		}
	}  else if (t->kind == Type_Basic) {
		if (t->Basic.kind == Basic_string) {
			switch (index) {
			case 0: return 0;
			case 1: return s.word_size;
			}
		} else if (t->Basic.kind == Basic_any) {
			switch (index) {
			case 0: return 0;
			case 1: return s.word_size;
			}
		}
	} else if (t->kind == Type_Slice) {
		switch (index) {
		case 0: return 0;
		case 1: return 1*s.word_size;
		case 2: return 2*s.word_size;
		}
	}
	return 0;
}


i64 type_offset_of_from_selection(BaseTypeSizes s, gbAllocator allocator, Type *type, Selection sel) {
	GB_ASSERT(sel.indirect == false);

	Type *t = type;
	i64 offset = 0;
	for_array(i, sel.index) {
		isize index = sel.index.e[i];
		t = base_type(t);
		offset += type_offset_of(s, allocator, t, index);
		if (t->kind == Type_Record && t->Record.kind == TypeRecord_Struct) {
			t = t->Record.fields[index]->type;
		} else {
			// NOTE(bill): string/any/slices don't have record fields so this case doesn't need to be handled
		}
	}
	return offset;
}



gbString write_type_to_string(gbString str, Type *type) {
	if (type == NULL) {
		return gb_string_appendc(str, "<no type>");
	}

	switch (type->kind) {
	case Type_Basic:
		str = gb_string_append_length(str, type->Basic.name.text, type->Basic.name.len);
		break;

	case Type_Pointer:
		str = gb_string_appendc(str, "^");
		str = write_type_to_string(str, type->Pointer.elem);
		break;

	case Type_Maybe:
		str = gb_string_appendc(str, "?");
		str = write_type_to_string(str, type->Maybe.elem);
		break;

	case Type_Array:
		str = gb_string_appendc(str, gb_bprintf("[%td]", type->Array.count));
		str = write_type_to_string(str, type->Array.elem);
		break;

	case Type_Vector:
		str = gb_string_appendc(str, gb_bprintf("{%td}", type->Vector.count));
		str = write_type_to_string(str, type->Vector.elem);
		break;

	case Type_Slice:
		str = gb_string_appendc(str, "[]");
		str = write_type_to_string(str, type->Array.elem);
		break;

	case Type_Record: {
		switch (type->Record.kind) {
		case TypeRecord_Struct:
			str = gb_string_appendc(str, "struct");
			if (type->Record.struct_is_packed) {
				str = gb_string_appendc(str, " #packed");
			}
			if (type->Record.struct_is_ordered) {
				str = gb_string_appendc(str, " #ordered");
			}
			str = gb_string_appendc(str, " {");
			for (isize i = 0; i < type->Record.field_count; i++) {
				Entity *f = type->Record.fields[i];
				GB_ASSERT(f->kind == Entity_Variable);
				if (i > 0)
					str = gb_string_appendc(str, "; ");
				str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
				str = gb_string_appendc(str, ": ");
				str = write_type_to_string(str, f->type);
			}
			str = gb_string_appendc(str, "}");
			break;

		case TypeRecord_Union:
			str = gb_string_appendc(str, "union{");
			for (isize i = 1; i < type->Record.field_count; i++) {
				Entity *f = type->Record.fields[i];
				GB_ASSERT(f->kind == Entity_TypeName);
				if (i > 1) {
					str = gb_string_appendc(str, "; ");
				}
				str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
				str = gb_string_appendc(str, ": ");
				str = write_type_to_string(str, base_type(f->type));
			}
			str = gb_string_appendc(str, "}");
			break;

		case TypeRecord_RawUnion:
			str = gb_string_appendc(str, "raw_union{");
			for (isize i = 0; i < type->Record.field_count; i++) {
				Entity *f = type->Record.fields[i];
				GB_ASSERT(f->kind == Entity_Variable);
				if (i > 0) {
					str = gb_string_appendc(str, ", ");
				}
				str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
				str = gb_string_appendc(str, ": ");
				str = write_type_to_string(str, f->type);
			}
			str = gb_string_appendc(str, "}");
			break;

		case TypeRecord_Enum:
			str = gb_string_appendc(str, "enum ");
			str = write_type_to_string(str, type->Record.enum_base);
			break;
		}
	} break;


	case Type_Named:
		if (type->Named.type_name != NULL) {
			str = gb_string_append_length(str, type->Named.name.text, type->Named.name.len);
		} else {
			// NOTE(bill): Just in case
			str = gb_string_appendc(str, "<named type>");
		}
		break;

	case Type_Tuple:
		if (type->Tuple.variable_count > 0) {
			for (isize i = 0; i < type->Tuple.variable_count; i++) {
				Entity *var = type->Tuple.variables[i];
				if (var != NULL) {
					GB_ASSERT(var->kind == Entity_Variable);
					if (i > 0)
						str = gb_string_appendc(str, ", ");
					str = write_type_to_string(str, var->type);
				}
			}
		}
		break;

	case Type_Proc:
		str = gb_string_appendc(str, "proc(");
		if (type->Proc.params)
			str = write_type_to_string(str, type->Proc.params);
		str = gb_string_appendc(str, ")");
		if (type->Proc.results) {
			str = gb_string_appendc(str, " -> ");
			str = write_type_to_string(str, type->Proc.results);
		}
		break;
	}

	return str;
}


gbString type_to_string(Type *type) {
	gbString str = gb_string_make(gb_heap_allocator(), "");
	return write_type_to_string(str, type);
}


