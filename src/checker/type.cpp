struct Scope;

enum BasicKind {
	Basic_Invalid,
	Basic_bool,
	Basic_i8,
	Basic_i16,
	Basic_i32,
	Basic_i64,
	Basic_i128,
	Basic_u8,
	Basic_u16,
	Basic_u32,
	Basic_u64,
	Basic_u128,
	Basic_f32,
	Basic_f64,
	Basic_int,
	Basic_uint,
	Basic_rawptr,
	Basic_string,

	Basic_any,

	Basic_UntypedBool,
	Basic_UntypedInteger,
	Basic_UntypedFloat,
	Basic_UntypedPointer,
	Basic_UntypedString,
	Basic_UntypedRune,


	Basic_Count,

	Basic_byte = Basic_u8,
	Basic_rune = Basic_i32,
};

enum BasicFlag : u32 {
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
};

struct BasicType {
	BasicKind kind;
	u32       flags;
	String    name;
};



#define TYPE_KINDS \
	TYPE_KIND(Invalid), \
	TYPE_KIND(Basic), \
	TYPE_KIND(Array), \
	TYPE_KIND(Vector), \
	TYPE_KIND(Slice), \
	TYPE_KIND(Record), \
	TYPE_KIND(Pointer), \
	TYPE_KIND(Named), \
	TYPE_KIND(Tuple), \
	TYPE_KIND(Proc), \
	TYPE_KIND(Count),

enum TypeKind {
#define TYPE_KIND(k) GB_JOIN2(Type_, k)
	TYPE_KINDS
#undef TYPE_KIND
};

String const type_strings[] = {
#define TYPE_KIND(k) {cast(u8 *)#k, gb_size_of(#k)-1}
	TYPE_KINDS
#undef TYPE_KIND
};

enum TypeFlag {
	TypeFlag_thread_local = GB_BIT(0),
	TypeFlag_volatile     = GB_BIT(1),
};

enum TypeRecordKind {
	TypeRecord_Invalid,

	TypeRecord_Struct,
	TypeRecord_Enum,
	TypeRecord_RawUnion,
	TypeRecord_Union, // Tagged

	TypeRecord_Count,
};

struct Type {
	u32 flags;
	TypeKind kind;
	union {
		BasicType Basic;
		struct {
			Type *elem;
			i64 count;
		} Array;
		struct {
			Type *elem;
			i64 count;
		} Vector;
		struct {
			Type *elem;
		} Slice;
		struct {
			TypeRecordKind kind;

			// All record types
			// Theses are arrays
			Entity **fields;      // Entity_Variable (otherwise Entity_TypeName if union)
			isize    field_count; // == offset_count is struct
			AstNode *node;

			// enum only
			Type *   enum_base; // Default is `int`

			// struct only
			i64 *    struct_offsets;
			b32      struct_are_offsets_set;
			b32      struct_is_packed;

			// Entity_Constant or Entity_TypeName
			Entity **other_fields;
			isize    other_field_count;
		} Record;
		struct { Type *elem; } Pointer;
		struct {
			String  name;
			Type *  base;
			Entity *type_name; // Entity_TypeName
		} Named;
		struct {
			Entity **variables; // Entity_Variable
			isize    variable_count;
		} Tuple;
		struct {
			Scope *scope;
			Type * params;  // Type_Tuple
			Type * results; // Type_Tuple
			isize  param_count;
			isize  result_count;
			b32    variadic;
		} Proc;
	};
};

gbString type_to_string(Type *type, gbAllocator a = gb_heap_allocator());

Type *get_base_type(Type *t) {
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

Type *make_type_pointer(gbAllocator a, Type *elem) {
	Type *t = alloc_type(a, Type_Pointer);
	t->Pointer.elem = elem;
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

Type *make_type_proc(gbAllocator a, Scope *scope, Type *params, isize param_count, Type *results, isize result_count, b32 variadic) {
	Type *t = alloc_type(a, Type_Proc);

	if (variadic) {
		if (param_count == 0) {
			GB_PANIC("variadic procedure must have at least one parameter");
		}
		GB_ASSERT(params != NULL && params->kind == Type_Tuple);
		Entity *e = params->Tuple.variables[param_count-1];
		if (get_base_type(e->type)->kind != Type_Slice) {
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
		Type *bt = get_base_type(t);
		if (bt == NULL)
			return NULL;
		if (bt != NULL && bt->kind == Type_Pointer)
			return bt->Pointer.elem;
	}
	return t;
}


#define STR_LIT(x) {cast(u8 *)(x), gb_size_of(x)-1}
gb_global Type basic_types[] = {
	{0, Type_Basic, {Basic_Invalid,        0,                                      STR_LIT("invalid type")}},
	{0, Type_Basic, {Basic_bool,           BasicFlag_Boolean,                      STR_LIT("bool")}},
	{0, Type_Basic, {Basic_i8,             BasicFlag_Integer,                      STR_LIT("i8")}},
	{0, Type_Basic, {Basic_i16,            BasicFlag_Integer,                      STR_LIT("i16")}},
	{0, Type_Basic, {Basic_i32,            BasicFlag_Integer,                      STR_LIT("i32")}},
	{0, Type_Basic, {Basic_i64,            BasicFlag_Integer,                      STR_LIT("i64")}},
	{0, Type_Basic, {Basic_i128,           BasicFlag_Integer,                      STR_LIT("i128")}},
	{0, Type_Basic, {Basic_u8,             BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u8")}},
	{0, Type_Basic, {Basic_u16,            BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u16")}},
	{0, Type_Basic, {Basic_u32,            BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u32")}},
	{0, Type_Basic, {Basic_u64,            BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u64")}},
	{0, Type_Basic, {Basic_u128,           BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u128")}},
	{0, Type_Basic, {Basic_f32,            BasicFlag_Float,                        STR_LIT("f32")}},
	{0, Type_Basic, {Basic_f64,            BasicFlag_Float,                        STR_LIT("f64")}},
	{0, Type_Basic, {Basic_int,            BasicFlag_Integer,                      STR_LIT("int")}},
	{0, Type_Basic, {Basic_uint,           BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("uint")}},
	{0, Type_Basic, {Basic_rawptr,         BasicFlag_Pointer,                      STR_LIT("rawptr")}},
	{0, Type_Basic, {Basic_string,         BasicFlag_String,                       STR_LIT("string")}},
	{0, Type_Basic, {Basic_any,            0,                                      STR_LIT("any")}},
	{0, Type_Basic, {Basic_UntypedBool,    BasicFlag_Boolean | BasicFlag_Untyped,  STR_LIT("untyped bool")}},
	{0, Type_Basic, {Basic_UntypedInteger, BasicFlag_Integer | BasicFlag_Untyped,  STR_LIT("untyped integer")}},
	{0, Type_Basic, {Basic_UntypedFloat,   BasicFlag_Float   | BasicFlag_Untyped,  STR_LIT("untyped float")}},
	{0, Type_Basic, {Basic_UntypedPointer, BasicFlag_Pointer | BasicFlag_Untyped,  STR_LIT("untyped pointer")}},
	{0, Type_Basic, {Basic_UntypedString,  BasicFlag_String  | BasicFlag_Untyped,  STR_LIT("untyped string")}},
	{0, Type_Basic, {Basic_UntypedRune,    BasicFlag_Integer | BasicFlag_Untyped,  STR_LIT("untyped rune")}},
};

gb_global Type basic_type_aliases[] = {
	{0, Type_Basic, {Basic_byte, BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("byte")}},
	{0, Type_Basic, {Basic_rune, BasicFlag_Integer,                      STR_LIT("rune")}},
};

gb_global Type *t_invalid         = &basic_types[Basic_Invalid];
gb_global Type *t_bool            = &basic_types[Basic_bool];
gb_global Type *t_i8              = &basic_types[Basic_i8];
gb_global Type *t_i16             = &basic_types[Basic_i16];
gb_global Type *t_i32             = &basic_types[Basic_i32];
gb_global Type *t_i64             = &basic_types[Basic_i64];
gb_global Type *t_i128            = &basic_types[Basic_i128];
gb_global Type *t_u8              = &basic_types[Basic_u8];
gb_global Type *t_u16             = &basic_types[Basic_u16];
gb_global Type *t_u32             = &basic_types[Basic_u32];
gb_global Type *t_u64             = &basic_types[Basic_u64];
gb_global Type *t_u128            = &basic_types[Basic_u128];
gb_global Type *t_f32             = &basic_types[Basic_f32];
gb_global Type *t_f64             = &basic_types[Basic_f64];
gb_global Type *t_int             = &basic_types[Basic_int];
gb_global Type *t_uint            = &basic_types[Basic_uint];
gb_global Type *t_rawptr          = &basic_types[Basic_rawptr];
gb_global Type *t_string          = &basic_types[Basic_string];
gb_global Type *t_any             = &basic_types[Basic_any];
gb_global Type *t_untyped_bool    = &basic_types[Basic_UntypedBool];
gb_global Type *t_untyped_integer = &basic_types[Basic_UntypedInteger];
gb_global Type *t_untyped_float   = &basic_types[Basic_UntypedFloat];
gb_global Type *t_untyped_pointer = &basic_types[Basic_UntypedPointer];
gb_global Type *t_untyped_string  = &basic_types[Basic_UntypedString];
gb_global Type *t_untyped_rune    = &basic_types[Basic_UntypedRune];
gb_global Type *t_byte            = &basic_type_aliases[Basic_byte];
gb_global Type *t_rune            = &basic_type_aliases[Basic_rune];

gb_global Type *t_type_info           = NULL;
gb_global Type *t_type_info_ptr       = NULL;

gb_global Type *t_type_info_named     = NULL;
gb_global Type *t_type_info_integer   = NULL;
gb_global Type *t_type_info_float     = NULL;
gb_global Type *t_type_info_string    = NULL;
gb_global Type *t_type_info_boolean   = NULL;
gb_global Type *t_type_info_pointer   = NULL;
gb_global Type *t_type_info_procedure = NULL;
gb_global Type *t_type_info_array     = NULL;
gb_global Type *t_type_info_slice     = NULL;
gb_global Type *t_type_info_vector    = NULL;
gb_global Type *t_type_info_struct    = NULL;
gb_global Type *t_type_info_union     = NULL;
gb_global Type *t_type_info_raw_union = NULL;
gb_global Type *t_type_info_enum      = NULL;



b32 is_type_named(Type *t) {
	if (t->kind == Type_Basic)
		return true;
	return t->kind == Type_Named;
}
b32 is_type_boolean(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Boolean) != 0;
	return false;
}
b32 is_type_integer(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Integer) != 0;
	return false;
}
b32 is_type_unsigned(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Unsigned) != 0;
	return false;
}
b32 is_type_numeric(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Numeric) != 0;
	if (t->kind == Type_Vector)
		return is_type_numeric(t->Vector.elem);
	return false;
}
b32 is_type_string(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_String) != 0;
	return false;
}
b32 is_type_typed(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Untyped) == 0;
	return true;
}
b32 is_type_untyped(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Untyped) != 0;
	return false;
}
b32 is_type_ordered(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Ordered) != 0;
	if (t->kind == Type_Pointer)
		return true;
	return false;
}
b32 is_type_constant_type(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_ConstantType) != 0;
	return false;
}
b32 is_type_float(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Float) != 0;
	return false;
}
b32 is_type_pointer(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Basic)
		return (t->Basic.flags & BasicFlag_Pointer) != 0;
	return t->kind == Type_Pointer;
}

b32 is_type_int_or_uint(Type *t) {
	if (t->kind == Type_Basic)
		return (t->Basic.kind == Basic_int) || (t->Basic.kind == Basic_uint);
	return false;
}
b32 is_type_rawptr(Type *t) {
	if (t->kind == Type_Basic)
		return t->Basic.kind == Basic_rawptr;
	return false;
}
b32 is_type_u8(Type *t) {
	if (t->kind == Type_Basic)
		return t->Basic.kind == Basic_u8;
	return false;
}
b32 is_type_slice(Type *t) {
	t = get_base_type(t);
	return t->kind == Type_Slice;
}
b32 is_type_u8_slice(Type *t) {
	t = get_base_type(t);
	if (t->kind == Type_Slice)
		return is_type_u8(t->Slice.elem);
	return false;
}
b32 is_type_vector(Type *t) {
	return t->kind == Type_Vector;
}
b32 is_type_proc(Type *t) {
	t = get_base_type(t);
	return t->kind == Type_Proc;
}
Type *base_vector_type(Type *t) {
	if (is_type_vector(t)) {
		return t->Vector.elem;
	}
	return t;
}


b32 is_type_enum(Type *t) {
	t = get_base_type(t);
	return (t->kind == Type_Record && t->Record.kind == TypeRecord_Enum);
}
b32 is_type_struct(Type *t) {
	t = get_base_type(t);
	return (t->kind == Type_Record && t->Record.kind == TypeRecord_Struct);
}
b32 is_type_union(Type *t) {
	t = get_base_type(t);
	return (t->kind == Type_Record && t->Record.kind == TypeRecord_Union);
}
b32 is_type_raw_union(Type *t) {
	t = get_base_type(t);
	return (t->kind == Type_Record && t->Record.kind == TypeRecord_RawUnion);
}

Type *get_enum_base_type(Type *t) {
	Type *bt = get_base_type(t);
	if (is_type_enum(bt)) {
		return bt->Record.enum_base;
	}
	return t;
}

b32 is_type_any(Type *t) {
	t = get_base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_any);
}



b32 is_type_comparable(Type *t) {
	t = get_base_type(t);
	switch (t->kind) {
	case Type_Basic:
		return true;
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

b32 are_types_identical(Type *x, Type *y) {
	if (x == y)
		return true;

	if ((x == NULL && y != NULL) ||
	    (x != NULL && y == NULL)) {
		return false;
	}

	switch (x->kind) {
	case Type_Basic:
		if (y->kind == Type_Basic)
			return x->Basic.kind == y->Basic.kind;
		break;

	case Type_Array:
		if (y->kind == Type_Array)
			return (x->Array.count == y->Array.count) && are_types_identical(x->Array.elem, y->Array.elem);
		break;

	case Type_Vector:
		if (y->kind == Type_Vector)
			return (x->Vector.count == y->Vector.count) && are_types_identical(x->Vector.elem, y->Vector.elem);
		break;

	case Type_Slice:
		if (y->kind == Type_Slice)
			return are_types_identical(x->Slice.elem, y->Slice.elem);
		break;

	case Type_Record:
		if (y->kind == Type_Record) {
			if (x->Record.kind == y->Record.kind) {
				switch (x->Record.kind) {
				case TypeRecord_Struct:
				case TypeRecord_RawUnion:
				case TypeRecord_Union:
					if (x->Record.field_count == y->Record.field_count) {
						for (isize i = 0; i < x->Record.field_count; i++) {
							if (!are_types_identical(x->Record.fields[i]->type, y->Record.fields[i]->type)) {
								return false;
							}
						}
						return true;
					}
					break;

				case TypeRecord_Enum:
					return are_types_identical(x->Record.enum_base, y->Record.enum_base);
				}
			}
		}
		break;

	case Type_Pointer:
		if (y->kind == Type_Pointer)
			return are_types_identical(x->Pointer.elem, y->Pointer.elem);
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
					if (!are_types_identical(x->Tuple.variables[i]->type, y->Tuple.variables[i]->type))
						return false;
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
		case Basic_UntypedBool:    return &basic_types[Basic_bool];
		case Basic_UntypedInteger: return &basic_types[Basic_int];
		case Basic_UntypedFloat:   return &basic_types[Basic_f64];
		case Basic_UntypedString:  return &basic_types[Basic_string];
		case Basic_UntypedRune:    return &basic_types[Basic_rune];
		case Basic_UntypedPointer: return &basic_types[Basic_rawptr];
		}
	}
	return type;
}


// NOTE(bill): Internal sizes of certain types
// string: 2*word_size  (ptr+len)
// slice:  3*word_size  (ptr+len+cap)
// array:  count*size_of(elem) aligned

// NOTE(bill): Alignment of structures and other types are to be compatible with C

struct BaseTypeSizes {
	i64 word_size;
	i64 max_align;
};

// TODO(bill): Change
gb_global i64 basic_type_sizes[] = {
	0,  // Basic_Invalid
	1,  // Basic_bool
	1,  // Basic_i8
	2,  // Basic_i16
	4,  // Basic_i32
	8,  // Basic_i64
	16, // Basic_i128
	1,  // Basic_u8
	2,  // Basic_u16
	4,  // Basic_u32
	8,  // Basic_u64
	16, // Basic_u128
	4,  // Basic_f32
	8,  // Basic_f64
};



struct Selection {
	Entity *entity;
	gbArray(isize) index;
	b32 indirect; // Set if there was a pointer deref anywhere down the line
};
Selection empty_selection = {};

Selection make_selection(Entity *entity, gbArray(isize) index, b32 indirect) {
	Selection s = {entity, index, indirect};
	return s;
}

void selection_add_index(Selection *s, isize index) {
	if (s->index == NULL) {
		gb_array_init(s->index, gb_heap_allocator());
	}
	gb_array_append(s->index, index);
}

gb_global Entity *entity_any_type_info = NULL;
gb_global Entity *entity_any_data      = NULL;

Selection lookup_field(Type *type_, String field_name, b32 is_type, Selection sel = empty_selection) {
	GB_ASSERT(type_ != NULL);

	if (are_strings_equal(field_name, make_string("_"))) {
		return empty_selection;
	}

	Type *type = type_deref(type_);
	b32 is_ptr = type != type_;
	type = get_base_type(type);

	if (type->kind == Type_Basic) {
		if (type->Basic.kind == Basic_any) {
			String type_info_str = make_string("type_info");
			String data_str = make_string("data");
			if (entity_any_type_info == NULL) {
				Token token = {Token_Identifier};
				token.string = type_info_str;
				entity_any_type_info = make_entity_field(gb_heap_allocator(), NULL, token, t_type_info_ptr, false);
			}
			if (entity_any_data == NULL) {
				Token token = {Token_Identifier};
				token.string = data_str;
				entity_any_data = make_entity_field(gb_heap_allocator(), NULL, token, t_type_info_ptr, false);
			}

			if (are_strings_equal(field_name, type_info_str)) {
				selection_add_index(&sel, 0);
				sel.entity = entity_any_type_info;
				return sel;
			} else if (are_strings_equal(field_name, data_str)) {
				selection_add_index(&sel, 1);
				sel.entity = entity_any_data;
				return sel;
			}
		}

		return sel;
	}

	if (type->kind != Type_Record) {
		return sel;
	}
	if (is_type) {
		if (is_type_union(type)) {
			for (isize i = 0; i < type->Record.field_count; i++) {
				Entity *f = type->Record.fields[i];
				GB_ASSERT(f->kind == Entity_TypeName);
				String str = f->token.string;

				if (are_strings_equal(field_name, str)) {
					return make_selection(f, NULL, i);
				}
			}
		}

		for (isize i = 0; i < type->Record.other_field_count; i++) {
			Entity *f = type->Record.other_fields[i];
			GB_ASSERT(f->kind != Entity_Variable);
			String str = f->token.string;

			if (are_strings_equal(field_name, str)) {
				return make_selection(f, NULL, i);
			}
		}
	} else if (!is_type_enum(type) && !is_type_union(type)) {
		for (isize i = 0; i < type->Record.field_count; i++) {
			Entity *f = type->Record.fields[i];
			GB_ASSERT(f->kind == Entity_Variable && f->Variable.is_field);
			String str = f->token.string;
			if (are_strings_equal(field_name, str)) {
				selection_add_index(&sel, i);
				sel.entity = f;
				return sel;
			}

			if (f->Variable.anonymous) {
				isize prev_count = 0;
				if (sel.index != NULL) {
					prev_count = gb_array_count(sel.index);
				}
				selection_add_index(&sel, i); // HACK(bill): Leaky memory

				sel = lookup_field(f->type, field_name, is_type, sel);

				if (sel.entity != NULL) {
					if (is_type_pointer(f->type))
						sel.indirect = true;
					return sel;
				}
				gb_array_count(sel.index) = prev_count;
			}
		}
	}

	return sel;
}



i64 type_size_of(BaseTypeSizes s, gbAllocator allocator, Type *t);
i64 type_align_of(BaseTypeSizes s, gbAllocator allocator, Type *t);
i64 type_offset_of(BaseTypeSizes s, gbAllocator allocator, Type *t, i64 index);

i64 align_formula(i64 size, i64 align) {
	i64 result = size + align-1;
	return result - result%align;
}

i64 type_align_of(BaseTypeSizes s, gbAllocator allocator, Type *t) {
	t = get_base_type(t);

	switch (t->kind) {
	case Type_Array:
		return type_align_of(s, allocator, t->Array.elem);
	case Type_Vector: {
		i64 size = type_size_of(s, allocator, t->Vector.elem);
		size *= t->Vector.count;
		size = next_pow2(size);
		// TODO(bill): Type_Vector type_align_of
		return gb_clamp(size, s.max_align, 4*s.max_align);
	} break;

	case Type_Record: {
		switch (t->Record.kind) {
		case TypeRecord_Struct:
			if (!t->Record.struct_is_packed) {
				i64 max = 1;
				for (isize i = 0; i < t->Record.field_count; i++) {
					i64 align = type_align_of(s, allocator, t->Record.fields[i]->type);
					if (max < align)
						max = align;
				}
				return max;
			}
			break;
		case TypeRecord_Union: {
			i64 max = s.word_size;
			for (isize i = 1; i < t->Record.field_count; i++) {
				// NOTE(bill): field zero is null
				i64 align = type_align_of(s, allocator, t->Record.fields[i]->type);
				if (max < align)
					max = align;
			}
			return max;
		} break;
		case TypeRecord_RawUnion: {
			i64 max = 1;
			for (isize i = 0; i < t->Record.field_count; i++) {
				i64 align = type_align_of(s, allocator, t->Record.fields[i]->type);
				if (max < align)
					max = align;
			}
			return max;
		} break;
		case TypeRecord_Enum:
			return type_align_of(s, allocator, t->Record.enum_base);
		}
	} break;
	}

	return gb_clamp(next_pow2(type_size_of(s, allocator, t)), 1, s.max_align);
}

i64 *type_set_offsets_of(BaseTypeSizes s, gbAllocator allocator, Entity **fields, isize field_count, b32 is_packed) {
	// TODO(bill): use arena allocation
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

b32 type_set_offsets(BaseTypeSizes s, gbAllocator allocator, Type *t) {
	GB_ASSERT(is_type_struct(t));
	if (!t->Record.struct_are_offsets_set) {
		t->Record.struct_offsets = type_set_offsets_of(s, allocator, t->Record.fields, t->Record.field_count, t->Record.struct_is_packed);
		t->Record.struct_are_offsets_set = true;
		return true;
	}
	return false;
}

i64 type_size_of(BaseTypeSizes s, gbAllocator allocator, Type *t) {
	t = get_base_type(t);

	switch (t->kind) {
	case Type_Basic: {
		GB_ASSERT(is_type_typed(t));
		BasicKind kind = t->Basic.kind;
		if (kind < gb_count_of(basic_type_sizes)) {
			i64 size = basic_type_sizes[kind];
			if (size > 0)
				return size;
		}
		if (kind == Basic_string)
			return 2 * s.word_size;
	} break;

	case Type_Array: {
		i64 count = t->Array.count;
		if (count == 0)
			return 0;
		i64 align = type_align_of(s, allocator, t->Array.elem);
		i64 size  = type_size_of(s,  allocator, t->Array.elem);
		i64 alignment = align_formula(size, align);
		return alignment*(count-1) + size;
	} break;

	case Type_Vector: {
		i64 count = t->Vector.count;
		if (count == 0)
			return 0;
		// i64 align = type_align_of(s, allocator, t->Vector.elem);
		i64 bit_size = 8*type_size_of(s,  allocator, t->Vector.elem);
		if (is_type_boolean(t->Vector.elem)) {
			bit_size = 1; // NOTE(bill): LLVM can store booleans as 1 bit because a boolean _is_ an `i1`
			              // Silly LLVM spec
		}
		i64 total_size_in_bits = bit_size * count;
		i64 total_size = (total_size_in_bits+7)/8;
		return total_size;

		// i64 alignment = align_formula(size, align);
		// return alignment*(count-1) + size;
	} break;


	case Type_Slice: // ptr + len + cap
		return 3 * s.word_size;

	case Type_Record: {
		switch (t->Record.kind) {
		case TypeRecord_Struct: {
			i64 count = t->Record.field_count;
			if (count == 0)
				return 0;
			type_set_offsets(s, allocator, t);
			return t->Record.struct_offsets[count-1] + type_size_of(s, allocator, t->Record.fields[count-1]->type);
		} break;

		case TypeRecord_Union: {
			i64 count = t->Record.field_count;
			i64 max = 0;
			// NOTE(bill): Zeroth field is invalid
			for (isize i = 1; i < count; i++) {
				i64 size = type_size_of(s, allocator, t->Record.fields[i]->type);
				if (max < size)
					max = size;
			}
			return align_formula(max, s.max_align) + type_size_of(s, allocator, t_int);
		} break;

		case TypeRecord_RawUnion: {
			i64 count = t->Record.field_count;
			i64 max = 0;
			for (isize i = 0; i < count; i++) {
				i64 size = type_size_of(s, allocator, t->Record.fields[i]->type);
				if (max < size)
					max = size;
			}
			return max;
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
	if (t->kind == Type_Record && t->Record.kind == TypeRecord_Struct) {
		type_set_offsets(s, allocator, t);
		if (gb_is_between(index, 0, t->Record.field_count-1)) {
			return t->Record.struct_offsets[index];
		}
	}
	return 0;
}


i64 type_offset_of_from_selection(BaseTypeSizes s, gbAllocator allocator, Type *t, Selection sel) {
	i64 offset = 0;
	for (isize i = 0; i < gb_array_count(sel.index); i++) {
		isize index = sel.index[i];
		t = get_base_type(t);
		if (t->kind == Type_Record && t->Record.kind == TypeRecord_Struct) {
			type_set_offsets(s, allocator, t);
			GB_ASSERT(gb_is_between(index, 0, t->Record.field_count-1));
			offset += t->Record.struct_offsets[index];
			t = t->Record.fields[index]->type;
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
			str = gb_string_appendc(str, "struct{");
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
			for (isize i = 0; i < type->Record.field_count; i++) {
				Entity *f = type->Record.fields[i];
				GB_ASSERT(f->kind == Entity_TypeName);
				if (i > 0) {
					str = gb_string_appendc(str, "; ");
				}
				str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
				str = gb_string_appendc(str, ": ");
				str = write_type_to_string(str, f->type);
			}
			str = gb_string_appendc(str, "}");
			break;

		case TypeRecord_RawUnion:
			str = gb_string_appendc(str, "raw_union{");
			for (isize i = 0; i < type->Record.field_count; i++) {
				Entity *f = type->Record.fields[i];
				GB_ASSERT(f->kind == Entity_Variable);
				if (i > 0)
					str = gb_string_appendc(str, ", ");
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

	case Type_Pointer:
		str = gb_string_appendc(str, "^");
		str = write_type_to_string(str, type->Pointer.elem);
		break;

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


gbString type_to_string(Type *type, gbAllocator a) {
	gbString str = gb_string_make(a, "");
	return write_type_to_string(str, type);
}


