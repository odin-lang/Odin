struct Scope;

enum BasicKind {
	Basic_Invalid,
	Basic_bool,
	Basic_i8,
	Basic_i16,
	Basic_i32,
	Basic_i64,
	Basic_u8,
	Basic_u16,
	Basic_u32,
	Basic_u64,
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
	BasicFlag_Untyped  = GB_BIT(6),

	BasicFlag_Numeric      = BasicFlag_Integer | BasicFlag_Float,
	BasicFlag_Ordered      = BasicFlag_Numeric | BasicFlag_String  | BasicFlag_Pointer,
	BasicFlag_ConstantType = BasicFlag_Boolean | BasicFlag_Numeric | BasicFlag_String | BasicFlag_Pointer,
};

struct BasicType {
	BasicKind kind;
	u32       flags;
	String    name;
};


enum TypeKind {
	Type_Invalid,

	Type_Basic,
	Type_Array,
	Type_Slice,
	Type_Structure,
	Type_Pointer,
	Type_Named,
	Type_Tuple,
	Type_Procedure,

	Type_Count,
};
struct Type {
	TypeKind kind;
	union {
		BasicType basic;
		struct {
			Type *element;
			i64 count;
		} array;
		struct {
			Type *element;
		} slice;
		struct {
			// Theses are arrays
			Entity **fields; // Entity_Variable
			isize    field_count; // == offset_count
			i64 *    offsets;
			b32      offsets_set;
		} structure;
		struct { Type *element; } pointer;
		struct {
			String  name;
			Type *  base;
			Entity *type_name; // Entity_TypeName
		} named;
		struct {
			Entity **variables; // Entity_Variable
			isize    variable_count;
		} tuple;
		struct {
			Scope *scope;
			Type * params;  // Type_Tuple
			Type * results; // Type_Tuple
			isize  params_count;
			isize  results_count;
		} procedure;
	};
};

Type *get_base_type(Type *t) {
	while (t->kind == Type_Named)
		t = t->named.base;
	return t;
}

void set_base_type(Type *t, Type *base) {
	if (t && t->kind == Type_Named) {
		t->named.base = base;
	}
}


Type *alloc_type(gbAllocator a, TypeKind kind) {
	Type *t = gb_alloc_item(a, Type);
	t->kind = kind;
	return t;
}


Type *make_type_basic(gbAllocator a, BasicType basic) {
	Type *t = alloc_type(a, Type_Basic);
	t->basic = basic;
	return t;
}

Type *make_type_array(gbAllocator a, Type *element, i64 count) {
	Type *t = alloc_type(a, Type_Array);
	t->array.element = element;
	t->array.count = count;
	return t;
}

Type *make_type_slice(gbAllocator a, Type *element) {
	Type *t = alloc_type(a, Type_Slice);
	t->array.element = element;
	return t;
}

Type *make_type_structure(gbAllocator a) {
	Type *t = alloc_type(a, Type_Structure);
	return t;
}

Type *make_type_pointer(gbAllocator a, Type *element) {
	Type *t = alloc_type(a, Type_Pointer);
	t->pointer.element = element;
	return t;
}

Type *make_type_named(gbAllocator a, String name, Type *base, Entity *type_name) {
	Type *t = alloc_type(a, Type_Named);
	t->named.name = name;
	t->named.base = base;
	t->named.type_name = type_name;
	return t;
}

Type *make_type_tuple(gbAllocator a) {
	Type *t = alloc_type(a, Type_Tuple);
	return t;
}

Type *make_type_procedure(gbAllocator a, Scope *scope, Type *params, isize params_count, Type *results, isize results_count) {
	Type *t = alloc_type(a, Type_Procedure);
	t->procedure.scope = scope;
	t->procedure.params = params;
	t->procedure.params_count = params_count;
	t->procedure.results = results;
	t->procedure.results_count = results_count;
	return t;
}



#define STR_LIT(x) {cast(u8 *)(x), gb_size_of(x)-1}
gb_global Type basic_types[] = {
	{Type_Basic, {Basic_Invalid,        0,                                      STR_LIT("invalid type")}},
	{Type_Basic, {Basic_bool,           BasicFlag_Boolean,                      STR_LIT("bool")}},
	{Type_Basic, {Basic_i8,             BasicFlag_Integer,                      STR_LIT("i8")}},
	{Type_Basic, {Basic_i16,            BasicFlag_Integer,                      STR_LIT("i16")}},
	{Type_Basic, {Basic_i32,            BasicFlag_Integer,                      STR_LIT("i32")}},
	{Type_Basic, {Basic_i64,            BasicFlag_Integer,                      STR_LIT("i64")}},
	{Type_Basic, {Basic_u8,             BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u8")}},
	{Type_Basic, {Basic_u16,            BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u16")}},
	{Type_Basic, {Basic_u32,            BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u32")}},
	{Type_Basic, {Basic_u64,            BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("u64")}},
	{Type_Basic, {Basic_f32,            BasicFlag_Float,                        STR_LIT("f32")}},
	{Type_Basic, {Basic_f64,            BasicFlag_Float,                        STR_LIT("f64")}},
	{Type_Basic, {Basic_int,            BasicFlag_Integer,                      STR_LIT("int")}},
	{Type_Basic, {Basic_uint,           BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("uint")}},
	{Type_Basic, {Basic_rawptr,         BasicFlag_Pointer,                      STR_LIT("rawptr")}},
	{Type_Basic, {Basic_string,         BasicFlag_String,                       STR_LIT("string")}},
	{Type_Basic, {Basic_UntypedBool,    BasicFlag_Boolean | BasicFlag_Untyped,  STR_LIT("untyped bool")}},
	{Type_Basic, {Basic_UntypedInteger, BasicFlag_Integer | BasicFlag_Untyped,  STR_LIT("untyped integer")}},
	{Type_Basic, {Basic_UntypedFloat,   BasicFlag_Float   | BasicFlag_Untyped,  STR_LIT("untyped float")}},
	{Type_Basic, {Basic_UntypedPointer, BasicFlag_Pointer | BasicFlag_Untyped,  STR_LIT("untyped pointer")}},
	{Type_Basic, {Basic_UntypedString,  BasicFlag_String  | BasicFlag_Untyped,  STR_LIT("untyped string")}},
	{Type_Basic, {Basic_UntypedRune,    BasicFlag_Integer | BasicFlag_Untyped,  STR_LIT("untyped rune")}},
};

gb_global Type basic_type_aliases[] = {
	{Type_Basic, {Basic_byte, BasicFlag_Integer | BasicFlag_Unsigned, STR_LIT("byte")}},
	{Type_Basic, {Basic_rune, BasicFlag_Integer,                      STR_LIT("rune")}},
};


b32 is_type_named(Type *t) {
	if (t->kind == Type_Basic)
		return true;
	return t->kind == Type_Named;
}
b32 is_type_boolean(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Boolean) != 0;
	return false;
}
b32 is_type_integer(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Integer) != 0;
	return false;
}
b32 is_type_unsigned(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Unsigned) != 0;
	return false;
}
b32 is_type_numeric(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Numeric) != 0;
	return false;
}
b32 is_type_string(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_String) != 0;
	return false;
}
b32 is_type_typed(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Untyped) == 0;
	return true;
}
b32 is_type_untyped(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Untyped) != 0;
	return false;
}
b32 is_type_ordered(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Ordered) != 0;
	return false;
}
b32 is_type_constant_type(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_ConstantType) != 0;
	return false;
}
b32 is_type_float(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Float) != 0;
	return false;
}
b32 is_type_pointer(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.flags & BasicFlag_Pointer) != 0;
	return t->kind == Type_Pointer;
}

b32 is_type_int_or_uint(Type *t) {
	if (t->kind == Type_Basic)
		return (t->basic.kind == Basic_int) || (t->basic.kind == Basic_uint);
	return false;
}

b32 is_type_rawptr(Type *t) {
	if (t->kind == Type_Basic)
		return t->basic.kind == Basic_rawptr;
	return false;
}

b32 is_type_comparable(Type *t) {
	t = get_base_type(t);
	switch (t->kind) {
	case Type_Basic:
		return true;
	case Type_Pointer:
		return true;
	case Type_Structure: {
		for (isize i = 0; i < t->structure.field_count; i++) {
			if (!is_type_comparable(t->structure.fields[i]->type))
				return false;
		}
		return true;
	} break;
	case Type_Array:
		return is_type_comparable(t->array.element);
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
			return x->basic.kind == y->basic.kind;
		break;

	case Type_Array:
		if (y->kind == Type_Array)
			return (x->array.count == y->array.count) && are_types_identical(x->array.element, y->array.element);
		break;

	case Type_Structure:
		if (y->kind == Type_Structure) {
			if (x->structure.field_count == y->structure.field_count) {
				for (isize i = 0; i < x->structure.field_count; i++) {
					if (!are_types_identical(x->structure.fields[i]->type, y->structure.fields[i]->type)) {
						return false;
					}
				}

				return true;
			}
		}
		break;

	case Type_Pointer:
		if (y->kind == Type_Pointer)
			return are_types_identical(x->pointer.element, y->pointer.element);
		break;

	case Type_Named:
		if (y->kind == Type_Named)
			return x->named.base == y->named.base;
		break;


	case Type_Tuple:
		if (y->kind == Type_Tuple) {
			if (x->tuple.variable_count == y->tuple.variable_count) {
				for (isize i = 0; i < x->tuple.variable_count; i++) {
					if (!are_types_identical(x->tuple.variables[i]->type, y->tuple.variables[i]->type))
						return false;
				}
				return true;
			}
		}
		break;

	case Type_Procedure:
		if (y->kind == Type_Procedure) {
			return are_types_identical(x->procedure.params, y->procedure.params) &&
			       are_types_identical(x->procedure.results, y->procedure.results);
		}
		break;
	}


	return false;
}


Type *default_type(Type *type) {
	if (type->kind == Type_Basic) {
		switch (type->basic.kind) {
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
// array:  count*size_of(element) aligned

// NOTE(bill): Alignment of structures and other types are to be compatible with C

struct BaseTypeSizes {
	i64 word_size;
	i64 max_align;
};

// TODO(bill): Change
gb_global i64 basic_type_sizes[] = {
	0, // Basic_Invalid
	1, // Basic_bool // TODO(bill): What size should this be? And should I have different booleans?
	1, // Basic_i8
	2, // Basic_i16
	4, // Basic_i32
	8, // Basic_i64
	1, // Basic_u8
	2, // Basic_u16
	4, // Basic_u32
	8, // Basic_u64
	4, // Basic_f32
	8, // Basic_f64
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
		return type_align_of(s, allocator, t->array.element);
	case Type_Structure: {
		i64 max = 1;
		for (isize i = 0; i < t->structure.field_count; i++) {
			i64 align = type_align_of(s, allocator, t->structure.fields[i]->type);
			if (max < align)
				max = align;
		}
		return max;
	} break;
	}

	return gb_clamp(type_size_of(s, allocator, t), 1, s.max_align);
}

i64 *type_set_offsets_of(BaseTypeSizes s, gbAllocator allocator, Entity **fields, isize field_count) {
	// TODO(bill): use arena allocation
	i64 *offsets = gb_alloc_array(allocator, i64, field_count);
	i64 curr_offset = 0;
	for (isize i = 0; i < field_count; i++) {
		i64 align = type_align_of(s, allocator, fields[i]->type);
		curr_offset = align_formula(curr_offset, align);
		offsets[i] = curr_offset;
		curr_offset += type_size_of(s, allocator, fields[i]->type);
	}

	return offsets;
}

b32 type_set_offsets(BaseTypeSizes s, gbAllocator allocator, Type *t) {
	GB_ASSERT(t->kind == Type_Structure);
	if (!t->structure.offsets_set) {
		t->structure.offsets = type_set_offsets_of(s, allocator, t->structure.fields, t->structure.field_count);
		t->structure.offsets_set = true;
		return true;
	}
	return false;
}

i64 type_size_of(BaseTypeSizes s, gbAllocator allocator, Type *t) {
	t = get_base_type(t);
	switch (t->kind) {
	case Type_Basic: {
		GB_ASSERT(is_type_typed(t));
		BasicKind kind = t->basic.kind;
		if (kind < gb_count_of(basic_type_sizes)) {
			i64 size = basic_type_sizes[kind];
			if (size > 0)
				return size;
		}
		if (kind == Basic_string)
			return 2 * s.word_size;
	} break;

	case Type_Array: {
		i64 count = t->array.count;
		if (count == 0)
			return 0;
		i64 align = type_align_of(s, allocator, t->array.element);
		i64 size  = type_size_of(s,  allocator, t->array.element);
		i64 alignment = align_formula(size, align);
		return alignment*(count-1) + size;
	} break;

	case Type_Slice: // ptr + len + cap
		return 3 * s.word_size;

	case Type_Structure: {
		i64 count = t->structure.field_count;
		if (count == 0)
			return 0;
		type_set_offsets(s, allocator, t);
		return t->structure.offsets[count-1] + type_size_of(s, allocator, t->structure.fields[count-1]->type);
	} break;
	}

	// Catch all
	return s.word_size;
}

i64 type_offset_of(BaseTypeSizes s, gbAllocator allocator, Type *t, isize index) {
	if (t->kind == Type_Structure) {
		type_set_offsets(s, allocator, t);
		if (gb_is_between(index, 0, t->structure.field_count-1)) {
			return t->structure.offsets[index];
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
		str = gb_string_append_length(str, type->basic.name.text, type->basic.name.len);
		break;

	case Type_Array:
		str = gb_string_appendc(str, gb_bprintf("[%td]", type->array.count));
		str = write_type_to_string(str, type->array.element);
		break;

	case Type_Slice:
		str = gb_string_appendc(str, "[]");
		str = write_type_to_string(str, type->array.element);
		break;

	case Type_Structure: {
		str = gb_string_appendc(str, "struct{");
		for (isize i = 0; i < type->structure.field_count; i++) {
			Entity *f = type->structure.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			if (i > 0)
				str = gb_string_appendc(str, "; ");
			str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
			str = gb_string_appendc(str, ": ");
			str = write_type_to_string(str, f->type);
		}
		str = gb_string_appendc(str, "}");
	} break;

	case Type_Pointer:
		str = gb_string_appendc(str, "^");
		str = write_type_to_string(str, type->pointer.element);
		break;

	case Type_Named:
		if (type->named.type_name != NULL) {
			str = gb_string_append_length(str, type->named.name.text, type->named.name.len);
		} else {
			// NOTE(bill): Just in case
			str = gb_string_appendc(str, "<named type>");
		}
		break;

	case Type_Tuple:
		if (type->tuple.variable_count > 0) {
			for (isize i = 0; i < type->tuple.variable_count; i++) {
				Entity *var = type->tuple.variables[i];
				GB_ASSERT(var->kind == Entity_Variable);
				if (i > 0)
					str = gb_string_appendc(str, ", ");
				str = write_type_to_string(str, var->type);
			}
		}
		break;

	case Type_Procedure:
		str = gb_string_appendc(str, "proc(");
		if (type->procedure.params)
			str = write_type_to_string(str, type->procedure.params);
		str = gb_string_appendc(str, ")");
		if (type->procedure.results) {
			str = gb_string_appendc(str, " -> ");
			str = write_type_to_string(str, type->procedure.results);
		}
		break;
	}

	return str;
}


gbString type_to_string(Type *type, gbAllocator a = gb_heap_allocator()) {
	gbString str = gb_string_make(a, "");
	return write_type_to_string(str, type);
}


