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
	TYPE_KIND(Struct), \
	TYPE_KIND(Union), \
	TYPE_KIND(Enum), \
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
			// Theses are arrays
			Entity **fields; // Entity_Variable
			isize    field_count; // == offset_count
			i64 *    offsets;
			b32      are_offsets_set;
			b32      is_packed;

			Entity **other_fields; // Entity_Constant or Entity_TypeName
			isize    other_field_count;
		} Struct;
		struct {
			// IMPORTANT HACK(bill): The positions of fields and field_count
			// must be same for Struct and Union
			Entity **fields; // Entity_Variable
			isize    field_count;
		} Union;
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
		} Proc;
		struct {
			Type *   base; // Default is `int`
			Entity **fields; // Entity_Constant
			isize    field_count;
		} Enum;
	};
};

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
	Type *t = alloc_type(a, Type_Struct);
	return t;
}

Type *make_type_union(gbAllocator a) {
	Type *t = alloc_type(a, Type_Union);
	return t;
}

Type *make_type_enum(gbAllocator a) {
	Type *t = alloc_type(a, Type_Enum);
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

Type *make_type_proc(gbAllocator a, Scope *scope, Type *params, isize param_count, Type *results, isize result_count) {
	Type *t = alloc_type(a, Type_Proc);
	t->Proc.scope = scope;
	t->Proc.params = params;
	t->Proc.param_count = param_count;
	t->Proc.results = results;
	t->Proc.result_count = result_count;
	return t;
}


Type *type_deref(Type *t) {
	if (t != NULL) {
		Type *bt = get_base_type(t);
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
gb_global Type *t_untyped_bool    = &basic_types[Basic_UntypedBool];
gb_global Type *t_untyped_integer = &basic_types[Basic_UntypedInteger];
gb_global Type *t_untyped_float   = &basic_types[Basic_UntypedFloat];
gb_global Type *t_untyped_pointer = &basic_types[Basic_UntypedPointer];
gb_global Type *t_untyped_string  = &basic_types[Basic_UntypedString];
gb_global Type *t_untyped_rune    = &basic_types[Basic_UntypedRune];
gb_global Type *t_byte            = &basic_type_aliases[Basic_byte];
gb_global Type *t_rune            = &basic_type_aliases[Basic_rune];


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
	return t->kind == Type_Enum;
}
Type *get_enum_base_type(Type *t) {
	Type *bt = get_base_type(t);
	if (is_type_enum(bt)) {
		return bt->Enum.base;
	}
	return t;
}



b32 is_type_comparable(Type *t) {
	t = get_base_type(t);
	switch (t->kind) {
	case Type_Basic:
		return true;
	case Type_Pointer:
		return true;
	case Type_Struct: {
		for (isize i = 0; i < t->Struct.field_count; i++) {
			if (!is_type_comparable(t->Struct.fields[i]->type))
				return false;
		}
		return true;
	} break;
	case Type_Array:
		return is_type_comparable(t->Array.elem);
	case Type_Vector:
		return is_type_comparable(t->Vector.elem);
	case Type_Enum:
		return is_type_comparable(t->Enum.base);
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

	case Type_Struct:
		if (y->kind == Type_Struct) {
			if (x->Struct.field_count == y->Struct.field_count) {
				for (isize i = 0; i < x->Struct.field_count; i++) {
					if (!are_types_identical(x->Struct.fields[i]->type, y->Struct.fields[i]->type)) {
						return false;
					}
				}

				return true;
			}
		}
		break;

	case Type_Pointer:
		if (y->kind == Type_Pointer)
			return are_types_identical(x->Pointer.elem, y->Pointer.elem);
		break;

	case Type_Named:
		if (y->kind == Type_Named)
			return x->Named.base == y->Named.base;
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

	case Type_Struct: {
		if (!t->Struct.is_packed) {
			i64 max = 1;
			for (isize i = 0; i < t->Struct.field_count; i++) {
				i64 align = type_align_of(s, allocator, t->Struct.fields[i]->type);
				if (max < align)
					max = align;
			}
			return max;
		}
	} break;

	case Type_Union: {
		i64 max = 1;
		for (isize i = 0; i < t->Union.field_count; i++) {
			i64 align = type_align_of(s, allocator, t->Union.fields[i]->type);
			if (max < align)
				max = align;
		}
		return max;
	} break;

	case Type_Enum:
		return type_align_of(s, allocator, t->Enum.base);
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
	GB_ASSERT(t->kind == Type_Struct);
	if (!t->Struct.are_offsets_set) {
		t->Struct.offsets = type_set_offsets_of(s, allocator, t->Struct.fields, t->Struct.field_count, t->Struct.is_packed);
		t->Struct.are_offsets_set = true;
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

	case Type_Struct: {
		i64 count = t->Struct.field_count;
		if (count == 0)
			return 0;
		type_set_offsets(s, allocator, t);
		return t->Struct.offsets[count-1] + type_size_of(s, allocator, t->Struct.fields[count-1]->type);
	} break;

	case Type_Union: {
		i64 count = t->Union.field_count;
		i64 max = 0;
		for (isize i = 0; i < count; i++) {
			i64 size = type_size_of(s, allocator, t->Struct.fields[i]->type);
			if (max < size)
				max = size;
		}
		return max;
	} break;

	case Type_Enum:
		return type_size_of(s, allocator, t->Enum.base);
	}

	// Catch all
	return s.word_size;
}

i64 type_offset_of(BaseTypeSizes s, gbAllocator allocator, Type *t, isize index) {
	if (t->kind == Type_Struct) {
		type_set_offsets(s, allocator, t);
		if (gb_is_between(index, 0, t->Struct.field_count-1)) {
			return t->Struct.offsets[index];
		}
	}
	return 0;
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

	case Type_Struct: {
		str = gb_string_appendc(str, "struct{");
		for (isize i = 0; i < type->Struct.field_count; i++) {
			Entity *f = type->Struct.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			if (i > 0)
				str = gb_string_appendc(str, ", ");
			str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
			str = gb_string_appendc(str, ": ");
			str = write_type_to_string(str, f->type);
		}
		str = gb_string_appendc(str, "}");
	} break;

	case Type_Union: {
		str = gb_string_appendc(str, "union{");
		for (isize i = 0; i < type->Union.field_count; i++) {
			Entity *f = type->Union.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			if (i > 0)
				str = gb_string_appendc(str, ", ");
			str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
			str = gb_string_appendc(str, ": ");
			str = write_type_to_string(str, f->type);
		}
		str = gb_string_appendc(str, "}");
	} break;

	case Type_Enum: {
		str = gb_string_appendc(str, "enum ");
		str = write_type_to_string(str, type->Enum.base);
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


gbString type_to_string(Type *type, gbAllocator a = gb_heap_allocator()) {
	gbString str = gb_string_make(a, "");
	return write_type_to_string(str, type);
}


