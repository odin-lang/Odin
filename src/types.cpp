struct Scope;
struct Ast;
struct Entity;

enum BasicKind {
	Basic_Invalid,

	Basic_llvm_bool,
	Basic_bool,
	Basic_b8,
	Basic_b16,
	Basic_b32,
	Basic_b64,

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

	Basic_rune,

	// Basic_f16,
	Basic_f32,
	Basic_f64,

	// Basic_complex32,
	Basic_complex64,
	Basic_complex128,

	Basic_quaternion128,
	Basic_quaternion256,

	Basic_int,
	Basic_uint,
	Basic_uintptr,
	Basic_rawptr,
	Basic_string,  // ^u8 + int
	Basic_cstring, // ^u8
	Basic_any,     // rawptr + ^Type_Info

	Basic_typeid,

	// Endian Specific Types
	Basic_i16le,
	Basic_u16le,
	Basic_i32le,
	Basic_u32le,
	Basic_i64le,
	Basic_u64le,
	Basic_i128le,
	Basic_u128le,

	Basic_i16be,
	Basic_u16be,
	Basic_i32be,
	Basic_u32be,
	Basic_i64be,
	Basic_u64be,
	Basic_i128be,
	Basic_u128be,

	Basic_f32le,
	Basic_f64le,

	Basic_f32be,
	Basic_f64be,

	// Untyped types
	Basic_UntypedBool,
	Basic_UntypedInteger,
	Basic_UntypedFloat,
	Basic_UntypedComplex,
	Basic_UntypedQuaternion,
	Basic_UntypedString,
	Basic_UntypedRune,
	Basic_UntypedNil,
	Basic_UntypedUndef,

	Basic_COUNT,

	Basic_byte = Basic_u8,
};

enum BasicFlag {
	BasicFlag_Boolean     = GB_BIT(0),
	BasicFlag_Integer     = GB_BIT(1),
	BasicFlag_Unsigned    = GB_BIT(2),
	BasicFlag_Float       = GB_BIT(3),
	BasicFlag_Complex     = GB_BIT(4),
	BasicFlag_Quaternion  = GB_BIT(5),
	BasicFlag_Pointer     = GB_BIT(6),
	BasicFlag_String      = GB_BIT(7),
	BasicFlag_Rune        = GB_BIT(8),
	BasicFlag_Untyped     = GB_BIT(9),

	BasicFlag_LLVM        = GB_BIT(11),

	BasicFlag_EndianLittle = GB_BIT(13),
	BasicFlag_EndianBig    = GB_BIT(14),

	BasicFlag_Numeric        = BasicFlag_Integer | BasicFlag_Float   | BasicFlag_Complex | BasicFlag_Quaternion,
	BasicFlag_Ordered        = BasicFlag_Integer | BasicFlag_Float   | BasicFlag_String  | BasicFlag_Pointer | BasicFlag_Rune,
	BasicFlag_OrderedNumeric = BasicFlag_Integer | BasicFlag_Float   | BasicFlag_Rune,
	BasicFlag_ConstantType   = BasicFlag_Boolean | BasicFlag_Numeric | BasicFlag_String  | BasicFlag_Pointer | BasicFlag_Rune,
	BasicFlag_SimpleCompare  = BasicFlag_Boolean | BasicFlag_Numeric | BasicFlag_Pointer | BasicFlag_Rune,
};

struct BasicType {
	BasicKind kind;
	u32       flags;
	i64       size; // -1 if arch. dep.
	String    name;
};

enum StructSoaKind {
	StructSoa_None    = 0,
	StructSoa_Fixed   = 1,
	StructSoa_Slice   = 2,
	StructSoa_Dynamic = 3,
};

enum TypeAtomOpKind {
	TypeAtomOp_Invalid,

	TypeAtomOp_index_get,
	TypeAtomOp_index_set,
	TypeAtomOp_slice,
	TypeAtomOp_index_get_ptr,

	TypeAtomOp_COUNT,
};

struct TypeAtomOpTable {
	Entity *op[TypeAtomOp_COUNT];
};

struct TypeStruct {
	Array<Entity *> fields;
	Array<String>   tags;
	Array<i64>      offsets;
	Ast *           node;
	Scope *         scope;

	Type *     polymorphic_params; // Type_Tuple
	Type *     polymorphic_parent;

	i64      custom_align;
	Entity * names;

	TypeAtomOpTable *atom_op_table;

	Type *        soa_elem;
	i64           soa_count;
	StructSoaKind soa_kind;

	bool are_offsets_set;
	bool are_offsets_being_processed;
	bool is_packed;
	bool is_raw_union;
	bool is_polymorphic;
	bool is_poly_specialized;
};

struct TypeUnion {
	Array<Type *> variants;
	Ast *         node;
	Scope *       scope;
	i64           variant_block_size;
	i64           custom_align;
	i64           tag_size;
	Type *        polymorphic_params; // Type_Tuple
	Type *        polymorphic_parent;

	TypeAtomOpTable *atom_op_table;

	bool          no_nil;
	bool          maybe;
	bool          is_polymorphic;
	bool          is_poly_specialized;
};

struct TypeProc {
	Ast *node;
	Scope *  scope;
	Type *   params;  // Type_Tuple
	Type *   results; // Type_Tuple
	i32      param_count;
	i32      result_count;
	u64      tags;
	isize    specialization_count;
	ProcCallingConvention calling_convention;
	i32      variadic_index;
	Array<Type *> abi_compat_params;
	Type *        abi_compat_result_type;
	// TODO(bill): Make this a flag set rather than bools
	bool     variadic;
	bool     abi_types_set;
	bool     require_results;
	bool     c_vararg;
	bool     is_polymorphic;
	bool     is_poly_specialized;
	bool     has_proc_default_values;
	bool     has_named_results;
	bool     diverging; // no return
	bool     return_by_pointer;
	bool     optional_ok;
};

#define TYPE_KINDS                                        \
	TYPE_KIND(Basic, BasicType)                           \
	TYPE_KIND(Named, struct {                             \
		String  name;                                     \
		Type *  base;                                     \
		Entity *type_name; /* Entity_TypeName */          \
	})                                                    \
	TYPE_KIND(Generic, struct {                           \
		i64     id;                                       \
		String  name;                                     \
		Type *  specialized;                              \
		Scope * scope;                                    \
		Entity *entity;                                   \
	})                                                    \
	TYPE_KIND(Pointer, struct { Type *elem; })            \
	TYPE_KIND(Opaque,  struct { Type *elem; })            \
	TYPE_KIND(Array,   struct {                           \
		Type *elem;                                       \
		i64   count;                                      \
		Type *generic_count;                              \
	})                                                    \
	TYPE_KIND(EnumeratedArray, struct {                   \
		Type *elem;                                       \
		Type *index;                                      \
		ExactValue min_value;                             \
		ExactValue max_value;                             \
		i64 count;                                        \
		TokenKind op;                                     \
	})                                                    \
	TYPE_KIND(Slice,   struct { Type *elem; })            \
	TYPE_KIND(DynamicArray, struct { Type *elem; })       \
	TYPE_KIND(Map, struct {                               \
		Type *key;                                        \
		Type *value;                                      \
		Type *entry_type;                                 \
		Type *generated_struct_type;                      \
		Type *internal_type;                              \
		Type *lookup_result_type;                         \
	})                                                    \
	TYPE_KIND(Struct,  TypeStruct)                        \
	TYPE_KIND(Union,   TypeUnion)                         \
	TYPE_KIND(Enum, struct {                              \
		Array<Entity *> fields;                           \
		Ast *node;                                        \
		Scope *  scope;                                   \
		Entity * names;                                   \
		Type *   base_type;                               \
		ExactValue min_value;                             \
		ExactValue max_value;                             \
		isize min_value_index;                            \
		isize max_value_index;                            \
	})                                                    \
	TYPE_KIND(Tuple, struct {                             \
		Array<Entity *> variables; /* Entity_Variable */  \
		Array<i64>      offsets;                          \
		bool            are_offsets_being_processed;      \
		bool            are_offsets_set;                  \
		bool            is_packed;                        \
	})                                                    \
	TYPE_KIND(Proc, TypeProc)                             \
	TYPE_KIND(BitFieldValue, struct { u32 bits; })        \
	TYPE_KIND(BitField, struct {                          \
		Array<Entity *> fields;                           \
		Array<u32>      offsets;                          \
		Array<u32>      sizes;                            \
		Scope *         scope;                            \
		i64             custom_align;                     \
	})                                                    \
	TYPE_KIND(BitSet, struct {                            \
		Type *elem;                                       \
		Type *underlying;                                 \
		i64   lower;                                      \
		i64   upper;                                      \
	})                                                    \
	TYPE_KIND(SimdVector, struct {                        \
		i64   count;                                      \
		Type *elem;                                       \
		bool is_x86_mmx;                                  \
	})                                                    \
	TYPE_KIND(RelativePointer, struct {                   \
		Type *pointer_type;                               \
		Type *base_integer;                               \
	})                                                    \
	TYPE_KIND(RelativeSlice, struct {                     \
		Type *slice_type;                                 \
		Type *base_integer;                               \
	})


enum TypeKind {
	Type_Invalid,
#define TYPE_KIND(k, ...) GB_JOIN2(Type_, k),
	TYPE_KINDS
#undef TYPE_KIND
	Type_Count,
};

String const type_strings[] = {
	{cast(u8 *)"Invalid", gb_size_of("Invalid")},
#define TYPE_KIND(k, ...) {cast(u8 *)#k, gb_size_of(#k)-1},
	TYPE_KINDS
#undef TYPE_KIND
};

#define TYPE_KIND(k, ...) typedef __VA_ARGS__ GB_JOIN2(Type, k);
	TYPE_KINDS
#undef TYPE_KIND

enum TypeFlag : u32 {
	TypeFlag_Polymorphic     = 1<<1,
	TypeFlag_PolySpecialized = 1<<2,
};

struct Type {
	TypeKind kind;
	union {
#define TYPE_KIND(k, ...) GB_JOIN2(Type, k) k;
	TYPE_KINDS
#undef TYPE_KIND
	};

	// NOTE(bill): These need to be at the end to not affect the unionized data
	i64  cached_size;
	i64  cached_align;
	u32  flags; // TypeFlag
	bool failure;
};

// IMPORTANT NOTE(bill): This must match the same as the in core.odin
enum Typeid_Kind : u8 {
	Typeid_Invalid,
	Typeid_Integer,
	Typeid_Rune,
	Typeid_Float,
	Typeid_Complex,
	Typeid_Quaternion,
	Typeid_String,
	Typeid_Boolean,
	Typeid_Any,
	Typeid_Type_Id,
	Typeid_Pointer,
	Typeid_Procedure,
	Typeid_Array,
	Typeid_Enumerated_Array,
	Typeid_Dynamic_Array,
	Typeid_Slice,
	Typeid_Tuple,
	Typeid_Struct,
	Typeid_Union,
	Typeid_Enum,
	Typeid_Map,
	Typeid_Bit_Field,
	Typeid_Bit_Set,
	Typeid_Opaque,
	Typeid_Simd_Vector,
	Typeid_Relative_Pointer,
	Typeid_Relative_Slice,
};




// TODO(bill): Should I add extra information here specifying the kind of selection?
// e.g. field, constant, array field, type field, etc.
struct Selection {
	Entity *   entity;
	Array<i32> index;
	bool       indirect; // Set if there was a pointer deref anywhere down the line
};
Selection empty_selection = {0};

Selection make_selection(Entity *entity, Array<i32> index, bool indirect) {
	Selection s = {entity, index, indirect};
	return s;
}

void selection_add_index(Selection *s, isize index) {
	// IMPORTANT NOTE(bill): this requires a stretchy buffer/dynamic array so it requires some form
	// of heap allocation
	// TODO(bill): Find a way to use a backing buffer for initial use as the general case is probably .count<3
	if (s->index.data == nullptr) {
		array_init(&s->index, heap_allocator());
	}
	array_add(&s->index, cast(i32)index);
}

Selection selection_combine(Selection const &lhs, Selection const &rhs) {
	Selection new_sel = lhs;
	new_sel.indirect = lhs.indirect || rhs.indirect;
	new_sel.index = array_make<i32>(heap_allocator(), lhs.index.count+rhs.index.count);
	array_copy(&new_sel.index, lhs.index, 0);
	array_copy(&new_sel.index, rhs.index, lhs.index.count);
	return new_sel;
}

Selection sub_selection(Selection const &sel, isize offset) {
	Selection res = {};
	res.index.data = sel.index.data + offset;
	res.index.count = gb_max(sel.index.count - offset, 0);
	res.index.capacity = res.index.count;
	return res;
}

Selection sub_selection_with_length(Selection const &sel, isize offset, isize len) {
	Selection res = {};
	res.index.data = sel.index.data + offset;
	res.index.count = gb_max(len, gb_max(sel.index.count - offset, 0));
	res.index.capacity = res.index.count;
	return res;
}



gb_global Type basic_types[] = {
	{Type_Basic, {Basic_Invalid,           0,                                          0, STR_LIT("invalid type")}},

	{Type_Basic, {Basic_llvm_bool,         BasicFlag_Boolean | BasicFlag_LLVM,         1, STR_LIT("llvm bool")}},

	{Type_Basic, {Basic_bool,              BasicFlag_Boolean,                          1, STR_LIT("bool")}},
	{Type_Basic, {Basic_b8,                BasicFlag_Boolean,                          1, STR_LIT("b8")}},
	{Type_Basic, {Basic_b16,               BasicFlag_Boolean,                          2, STR_LIT("b16")}},
	{Type_Basic, {Basic_b32,               BasicFlag_Boolean,                          4, STR_LIT("b32")}},
	{Type_Basic, {Basic_b64,               BasicFlag_Boolean,                          8, STR_LIT("b64")}},

	{Type_Basic, {Basic_i8,                BasicFlag_Integer,                          1, STR_LIT("i8")}},
	{Type_Basic, {Basic_u8,                BasicFlag_Integer | BasicFlag_Unsigned,     1, STR_LIT("u8")}},
	{Type_Basic, {Basic_i16,               BasicFlag_Integer,                          2, STR_LIT("i16")}},
	{Type_Basic, {Basic_u16,               BasicFlag_Integer | BasicFlag_Unsigned,     2, STR_LIT("u16")}},
	{Type_Basic, {Basic_i32,               BasicFlag_Integer,                          4, STR_LIT("i32")}},
	{Type_Basic, {Basic_u32,               BasicFlag_Integer | BasicFlag_Unsigned,     4, STR_LIT("u32")}},
	{Type_Basic, {Basic_i64,               BasicFlag_Integer,                          8, STR_LIT("i64")}},
	{Type_Basic, {Basic_u64,               BasicFlag_Integer | BasicFlag_Unsigned,     8, STR_LIT("u64")}},

	{Type_Basic, {Basic_i128,               BasicFlag_Integer,                        16, STR_LIT("i128")}},
	{Type_Basic, {Basic_u128,               BasicFlag_Integer | BasicFlag_Unsigned,   16, STR_LIT("u128")}},

	{Type_Basic, {Basic_rune,              BasicFlag_Integer | BasicFlag_Rune,         4, STR_LIT("rune")}},

	// {Type_Basic, {Basic_f16,               BasicFlag_Float,                            2, STR_LIT("f16")}},
	{Type_Basic, {Basic_f32,               BasicFlag_Float,                            4, STR_LIT("f32")}},
	{Type_Basic, {Basic_f64,               BasicFlag_Float,                            8, STR_LIT("f64")}},

	// {Type_Basic, {Basic_complex32,         BasicFlag_Complex,                          4, STR_LIT("complex32")}},
	{Type_Basic, {Basic_complex64,         BasicFlag_Complex,                          8, STR_LIT("complex64")}},
	{Type_Basic, {Basic_complex128,        BasicFlag_Complex,                         16, STR_LIT("complex128")}},

	{Type_Basic, {Basic_quaternion128,     BasicFlag_Quaternion,                      16, STR_LIT("quaternion128")}},
	{Type_Basic, {Basic_quaternion256,     BasicFlag_Quaternion,                      32, STR_LIT("quaternion256")}},

	{Type_Basic, {Basic_int,               BasicFlag_Integer,                         -1, STR_LIT("int")}},
	{Type_Basic, {Basic_uint,              BasicFlag_Integer | BasicFlag_Unsigned,    -1, STR_LIT("uint")}},
	{Type_Basic, {Basic_uintptr,           BasicFlag_Integer | BasicFlag_Unsigned,    -1, STR_LIT("uintptr")}},

	{Type_Basic, {Basic_rawptr,            BasicFlag_Pointer,                         -1, STR_LIT("rawptr")}},
	{Type_Basic, {Basic_string,            BasicFlag_String,                          -1, STR_LIT("string")}},
	{Type_Basic, {Basic_cstring,           BasicFlag_String,                          -1, STR_LIT("cstring")}},
	{Type_Basic, {Basic_any,               0,                                         -1, STR_LIT("any")}},

	{Type_Basic, {Basic_typeid,            0,                                         -1, STR_LIT("typeid")}},

	// Endian
	{Type_Basic, {Basic_i16le,  BasicFlag_Integer |                      BasicFlag_EndianLittle,  2, STR_LIT("i16le")}},
	{Type_Basic, {Basic_u16le,  BasicFlag_Integer | BasicFlag_Unsigned | BasicFlag_EndianLittle,  2, STR_LIT("u16le")}},
	{Type_Basic, {Basic_i32le,  BasicFlag_Integer |                      BasicFlag_EndianLittle,  4, STR_LIT("i32le")}},
	{Type_Basic, {Basic_u32le,  BasicFlag_Integer | BasicFlag_Unsigned | BasicFlag_EndianLittle,  4, STR_LIT("u32le")}},
	{Type_Basic, {Basic_i64le,  BasicFlag_Integer |                      BasicFlag_EndianLittle,  8, STR_LIT("i64le")}},
	{Type_Basic, {Basic_u64le,  BasicFlag_Integer | BasicFlag_Unsigned | BasicFlag_EndianLittle,  8, STR_LIT("u64le")}},
	{Type_Basic, {Basic_i128le, BasicFlag_Integer                      | BasicFlag_EndianLittle, 16, STR_LIT("i128le")}},
	{Type_Basic, {Basic_u128le, BasicFlag_Integer | BasicFlag_Unsigned | BasicFlag_EndianLittle, 16, STR_LIT("u128le")}},

	{Type_Basic, {Basic_i16be,  BasicFlag_Integer |                      BasicFlag_EndianBig,     2, STR_LIT("i16be")}},
	{Type_Basic, {Basic_u16be,  BasicFlag_Integer | BasicFlag_Unsigned | BasicFlag_EndianBig,     2, STR_LIT("u16be")}},
	{Type_Basic, {Basic_i32be,  BasicFlag_Integer |                      BasicFlag_EndianBig,     4, STR_LIT("i32be")}},
	{Type_Basic, {Basic_u32be,  BasicFlag_Integer | BasicFlag_Unsigned | BasicFlag_EndianBig,     4, STR_LIT("u32be")}},
	{Type_Basic, {Basic_i64be,  BasicFlag_Integer |                      BasicFlag_EndianBig,     8, STR_LIT("i64be")}},
	{Type_Basic, {Basic_u64be,  BasicFlag_Integer | BasicFlag_Unsigned | BasicFlag_EndianBig,     8, STR_LIT("u64be")}},
	{Type_Basic, {Basic_i128be, BasicFlag_Integer                      | BasicFlag_EndianBig,    16, STR_LIT("i128be")}},
	{Type_Basic, {Basic_u128be, BasicFlag_Integer | BasicFlag_Unsigned | BasicFlag_EndianBig,    16, STR_LIT("u128be")}},

	{Type_Basic, {Basic_f32le, BasicFlag_Float | BasicFlag_EndianLittle, 4, STR_LIT("f32le")}},
	{Type_Basic, {Basic_f64le, BasicFlag_Float | BasicFlag_EndianLittle, 8, STR_LIT("f64le")}},

	{Type_Basic, {Basic_f32be, BasicFlag_Float | BasicFlag_EndianBig,    4, STR_LIT("f32be")}},
	{Type_Basic, {Basic_f64be, BasicFlag_Float | BasicFlag_EndianBig,    8, STR_LIT("f64be")}},

	// Untyped types
	{Type_Basic, {Basic_UntypedBool,       BasicFlag_Boolean    | BasicFlag_Untyped,   0, STR_LIT("untyped bool")}},
	{Type_Basic, {Basic_UntypedInteger,    BasicFlag_Integer    | BasicFlag_Untyped,   0, STR_LIT("untyped integer")}},
	{Type_Basic, {Basic_UntypedFloat,      BasicFlag_Float      | BasicFlag_Untyped,   0, STR_LIT("untyped float")}},
	{Type_Basic, {Basic_UntypedComplex,    BasicFlag_Complex    | BasicFlag_Untyped,   0, STR_LIT("untyped complex")}},
	{Type_Basic, {Basic_UntypedQuaternion, BasicFlag_Quaternion | BasicFlag_Untyped,   0, STR_LIT("untyped quaternion")}},
	{Type_Basic, {Basic_UntypedString,     BasicFlag_String     | BasicFlag_Untyped,   0, STR_LIT("untyped string")}},
	{Type_Basic, {Basic_UntypedRune,       BasicFlag_Integer    | BasicFlag_Untyped,   0, STR_LIT("untyped rune")}},
	{Type_Basic, {Basic_UntypedNil,        BasicFlag_Untyped,                          0, STR_LIT("untyped nil")}},
	{Type_Basic, {Basic_UntypedUndef,      BasicFlag_Untyped,                          0, STR_LIT("untyped undefined")}},
};

// gb_global Type basic_type_aliases[] = {
// 	// {Type_Basic, {Basic_byte, BasicFlag_Integer | BasicFlag_Unsigned, 1, STR_LIT("byte")}},
// 	// {Type_Basic, {Basic_rune, BasicFlag_Integer,                      4, STR_LIT("rune")}},
// };

gb_global Type *t_invalid         = &basic_types[Basic_Invalid];
gb_global Type *t_llvm_bool       = &basic_types[Basic_llvm_bool];
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

gb_global Type *t_rune            = &basic_types[Basic_rune];

// gb_global Type *t_f16             = &basic_types[Basic_f16];
gb_global Type *t_f32             = &basic_types[Basic_f32];
gb_global Type *t_f64             = &basic_types[Basic_f64];

// gb_global Type *t_complex32       = &basic_types[Basic_complex32];
gb_global Type *t_complex64       = &basic_types[Basic_complex64];
gb_global Type *t_complex128      = &basic_types[Basic_complex128];

gb_global Type *t_quaternion128   = &basic_types[Basic_quaternion128];
gb_global Type *t_quaternion256   = &basic_types[Basic_quaternion256];

gb_global Type *t_int             = &basic_types[Basic_int];
gb_global Type *t_uint            = &basic_types[Basic_uint];
gb_global Type *t_uintptr         = &basic_types[Basic_uintptr];

gb_global Type *t_rawptr          = &basic_types[Basic_rawptr];
gb_global Type *t_string          = &basic_types[Basic_string];
gb_global Type *t_cstring         = &basic_types[Basic_cstring];
gb_global Type *t_any             = &basic_types[Basic_any];

gb_global Type *t_typeid          = &basic_types[Basic_typeid];

gb_global Type *t_i16le           = &basic_types[Basic_i16le];
gb_global Type *t_u16le           = &basic_types[Basic_u16le];
gb_global Type *t_i32le           = &basic_types[Basic_i32le];
gb_global Type *t_u32le           = &basic_types[Basic_u32le];
gb_global Type *t_i64le           = &basic_types[Basic_i64le];
gb_global Type *t_u64le           = &basic_types[Basic_u64le];
gb_global Type *t_i128le          = &basic_types[Basic_i128le];
gb_global Type *t_u128le          = &basic_types[Basic_u128le];

gb_global Type *t_i16be           = &basic_types[Basic_i16be];
gb_global Type *t_u16be           = &basic_types[Basic_u16be];
gb_global Type *t_i32be           = &basic_types[Basic_i32be];
gb_global Type *t_u32be           = &basic_types[Basic_u32be];
gb_global Type *t_i64be           = &basic_types[Basic_i64be];
gb_global Type *t_u64be           = &basic_types[Basic_u64be];
gb_global Type *t_i128be          = &basic_types[Basic_i128be];
gb_global Type *t_u128be          = &basic_types[Basic_u128be];


gb_global Type *t_untyped_bool       = &basic_types[Basic_UntypedBool];
gb_global Type *t_untyped_integer    = &basic_types[Basic_UntypedInteger];
gb_global Type *t_untyped_float      = &basic_types[Basic_UntypedFloat];
gb_global Type *t_untyped_complex    = &basic_types[Basic_UntypedComplex];
gb_global Type *t_untyped_quaternion = &basic_types[Basic_UntypedQuaternion];
gb_global Type *t_untyped_string     = &basic_types[Basic_UntypedString];
gb_global Type *t_untyped_rune       = &basic_types[Basic_UntypedRune];
gb_global Type *t_untyped_nil        = &basic_types[Basic_UntypedNil];
gb_global Type *t_untyped_undef      = &basic_types[Basic_UntypedUndef];



gb_global Type *t_u8_ptr       = nullptr;
gb_global Type *t_int_ptr      = nullptr;
gb_global Type *t_i64_ptr      = nullptr;
gb_global Type *t_f64_ptr      = nullptr;
gb_global Type *t_u8_slice     = nullptr;
gb_global Type *t_string_slice = nullptr;


// Type generated for the "preload" file
gb_global Type *t_type_info                      = nullptr;
gb_global Type *t_type_info_enum_value           = nullptr;
gb_global Type *t_type_info_ptr                  = nullptr;
gb_global Type *t_type_info_enum_value_ptr       = nullptr;

gb_global Type *t_type_info_named                = nullptr;
gb_global Type *t_type_info_integer              = nullptr;
gb_global Type *t_type_info_rune                 = nullptr;
gb_global Type *t_type_info_float                = nullptr;
gb_global Type *t_type_info_complex              = nullptr;
gb_global Type *t_type_info_quaternion           = nullptr;
gb_global Type *t_type_info_any                  = nullptr;
gb_global Type *t_type_info_typeid               = nullptr;
gb_global Type *t_type_info_string               = nullptr;
gb_global Type *t_type_info_boolean              = nullptr;
gb_global Type *t_type_info_pointer              = nullptr;
gb_global Type *t_type_info_procedure            = nullptr;
gb_global Type *t_type_info_array                = nullptr;
gb_global Type *t_type_info_enumerated_array     = nullptr;
gb_global Type *t_type_info_dynamic_array        = nullptr;
gb_global Type *t_type_info_slice                = nullptr;
gb_global Type *t_type_info_tuple                = nullptr;
gb_global Type *t_type_info_struct               = nullptr;
gb_global Type *t_type_info_union                = nullptr;
gb_global Type *t_type_info_enum                 = nullptr;
gb_global Type *t_type_info_map                  = nullptr;
gb_global Type *t_type_info_bit_field            = nullptr;
gb_global Type *t_type_info_bit_set              = nullptr;
gb_global Type *t_type_info_opaque               = nullptr;
gb_global Type *t_type_info_simd_vector          = nullptr;
gb_global Type *t_type_info_relative_pointer     = nullptr;
gb_global Type *t_type_info_relative_slice       = nullptr;

gb_global Type *t_type_info_named_ptr            = nullptr;
gb_global Type *t_type_info_integer_ptr          = nullptr;
gb_global Type *t_type_info_rune_ptr             = nullptr;
gb_global Type *t_type_info_float_ptr            = nullptr;
gb_global Type *t_type_info_complex_ptr          = nullptr;
gb_global Type *t_type_info_quaternion_ptr       = nullptr;
gb_global Type *t_type_info_any_ptr              = nullptr;
gb_global Type *t_type_info_typeid_ptr           = nullptr;
gb_global Type *t_type_info_string_ptr           = nullptr;
gb_global Type *t_type_info_boolean_ptr          = nullptr;
gb_global Type *t_type_info_pointer_ptr          = nullptr;
gb_global Type *t_type_info_procedure_ptr        = nullptr;
gb_global Type *t_type_info_array_ptr            = nullptr;
gb_global Type *t_type_info_enumerated_array_ptr = nullptr;
gb_global Type *t_type_info_dynamic_array_ptr    = nullptr;
gb_global Type *t_type_info_slice_ptr            = nullptr;
gb_global Type *t_type_info_tuple_ptr            = nullptr;
gb_global Type *t_type_info_struct_ptr           = nullptr;
gb_global Type *t_type_info_union_ptr            = nullptr;
gb_global Type *t_type_info_enum_ptr             = nullptr;
gb_global Type *t_type_info_map_ptr              = nullptr;
gb_global Type *t_type_info_bit_field_ptr        = nullptr;
gb_global Type *t_type_info_bit_set_ptr          = nullptr;
gb_global Type *t_type_info_opaque_ptr           = nullptr;
gb_global Type *t_type_info_simd_vector_ptr      = nullptr;
gb_global Type *t_type_info_relative_pointer_ptr = nullptr;
gb_global Type *t_type_info_relative_slice_ptr   = nullptr;

gb_global Type *t_allocator                      = nullptr;
gb_global Type *t_allocator_ptr                  = nullptr;
gb_global Type *t_context                        = nullptr;
gb_global Type *t_context_ptr                    = nullptr;

gb_global Type *t_source_code_location           = nullptr;
gb_global Type *t_source_code_location_ptr       = nullptr;

gb_global Type *t_map_key                        = nullptr;
gb_global Type *t_map_header                     = nullptr;

gb_global Type *t_vector_x86_mmx                 = nullptr;



i64      type_size_of               (Type *t);
i64      type_align_of              (Type *t);
i64      type_offset_of             (Type *t, i32 index);
gbString type_to_string             (Type *type);
void     init_map_internal_types(Type *type);
Type *   bit_set_to_int(Type *t);
bool are_types_identical(Type *x, Type *y);

bool is_type_pointer(Type *t);
bool is_type_slice(Type *t);
bool is_type_integer(Type *t);

bool type_ptr_set_exists(PtrSet<Type *> *s, Type *t) {
	if (ptr_set_exists(s, t)) {
		return true;
	}

	// TODO(bill, 2019-10-05): This is very slow and it's probably a lot
	// faster to cache types correctly
	for_array(i, s->entries) {
		Type *f = s->entries[i].ptr;
		if (are_types_identical(t, f)) {
			ptr_set_add(s, t);
			return true;
		}
	}

	return false;
}

Type *base_type(Type *t) {
	for (;;) {
		if (t == nullptr) {
			break;
		}
		if (t->kind != Type_Named) {
			break;
		}
		if (t == t->Named.base) {
			return t_invalid;
		}
		t = t->Named.base;
	}
	return t;
}

Type *strip_opaque_type(Type *t) {
	for (;;) {
		if (t == nullptr) {
			break;
		}
		if (t->kind != Type_Opaque) {
			break;
		}
		t = t->Opaque.elem;
	}
	return t;
}

Type *base_enum_type(Type *t) {
	Type *bt = base_type(t);
	if (bt != nullptr &&
	    bt->kind == Type_Enum) {
		return bt->Enum.base_type;
	}
	return t;
}

Type *core_type(Type *t) {
	for (;;) {
		if (t == nullptr) {
			break;
		}

		switch (t->kind) {
		case Type_Named:
			if (t == t->Named.base) {
				return t_invalid;
			}
			t = t->Named.base;
			continue;
		case Type_Enum:
			t = t->Enum.base_type;
			continue;
		case Type_Opaque:
			t = t->Opaque.elem;
			continue;
		}
		break;
	}
	return t;
}

void set_base_type(Type *t, Type *base) {
	if (t && t->kind == Type_Named) {
		t->Named.base = base;
	}
}


Type *alloc_type(TypeKind kind) {
	gbAllocator a = heap_allocator();
	Type *t = gb_alloc_item(a, Type);
	zero_item(t);
	t->kind = kind;
	t->cached_size  = -1;
	t->cached_align = -1;
	return t;
}


Type *alloc_type_generic(Scope *scope, i64 id, String name, Type *specialized) {
	Type *t = alloc_type(Type_Generic);
	t->Generic.id = id;
	t->Generic.name = name;
	t->Generic.specialized = specialized;
	t->Generic.scope = scope;
	return t;
}

Type *alloc_type_opaque(Type *elem) {
	Type *t = alloc_type(Type_Opaque);
	t->Opaque.elem = elem;
	return t;
}

Type *alloc_type_pointer(Type *elem) {
	Type *t = alloc_type(Type_Pointer);
	t->Pointer.elem = elem;
	return t;
}

Type *alloc_type_array(Type *elem, i64 count, Type *generic_count = nullptr) {
	if (generic_count != nullptr) {
		Type *t = alloc_type(Type_Array);
		t->Array.elem = elem;
		t->Array.count = count;
		t->Array.generic_count = generic_count;
		return t;
	}
	Type *t = alloc_type(Type_Array);
	t->Array.elem = elem;
	t->Array.count = count;
	return t;
}

Type *alloc_type_enumerated_array(Type *elem, Type *index, ExactValue min_value, ExactValue max_value, TokenKind op) {
	Type *t = alloc_type(Type_EnumeratedArray);
	t->EnumeratedArray.elem = elem;
	t->EnumeratedArray.index = index;
	t->EnumeratedArray.min_value = min_value;
	t->EnumeratedArray.max_value = max_value;
	t->EnumeratedArray.op = op;

	t->EnumeratedArray.count = 1 + exact_value_to_i64(exact_value_sub(max_value, min_value));
	return t;
}


Type *alloc_type_slice(Type *elem) {
	Type *t = alloc_type(Type_Slice);
	t->Array.elem = elem;
	return t;
}

Type *alloc_type_dynamic_array(Type *elem) {
	Type *t = alloc_type(Type_DynamicArray);
	t->DynamicArray.elem = elem;
	return t;
}


Type *alloc_type_struct() {
	Type *t = alloc_type(Type_Struct);
	return t;
}

Type *alloc_type_union() {
	Type *t = alloc_type(Type_Union);
	return t;
}

Type *alloc_type_enum() {
	Type *t = alloc_type(Type_Enum);
	return t;
}

Type *alloc_type_relative_pointer(Type *pointer_type, Type *base_integer) {
	GB_ASSERT(is_type_pointer(pointer_type));
	GB_ASSERT(is_type_integer(base_integer));
	Type *t = alloc_type(Type_RelativePointer);
	t->RelativePointer.pointer_type = pointer_type;
	t->RelativePointer.base_integer = base_integer;
	return t;
}

Type *alloc_type_relative_slice(Type *slice_type, Type *base_integer) {
	GB_ASSERT(is_type_slice(slice_type));
	GB_ASSERT(is_type_integer(base_integer));
	Type *t = alloc_type(Type_RelativeSlice);
	t->RelativeSlice.slice_type   = slice_type;
	t->RelativeSlice.base_integer = base_integer;
	return t;
}

Type *alloc_type_named(String name, Type *base, Entity *type_name) {
	Type *t = alloc_type(Type_Named);
	t->Named.name = name;
	t->Named.base = base;
	t->Named.type_name = type_name;
	return t;
}

Type *alloc_type_tuple() {
	Type *t = alloc_type(Type_Tuple);
	return t;
}

Type *alloc_type_proc(Scope *scope, Type *params, isize param_count, Type *results, isize result_count, bool variadic, ProcCallingConvention calling_convention) {
	Type *t = alloc_type(Type_Proc);

	if (variadic) {
		if (param_count == 0) {
			GB_PANIC("variadic procedure must have at least one parameter");
		}
		GB_ASSERT(params != nullptr && params->kind == Type_Tuple);
		Entity *e = params->Tuple.variables[param_count-1];
		if (base_type(e->type)->kind != Type_Slice) {
			// NOTE(bill): For custom calling convention
			GB_PANIC("variadic parameter must be of type slice");
		}
	}

	t->Proc.scope        = scope;
	t->Proc.params       = params;
	t->Proc.param_count  = cast(i32)param_count;
	t->Proc.results      = results;
	t->Proc.result_count = cast(i32)result_count;
	t->Proc.variadic     = variadic;
	t->Proc.calling_convention = calling_convention;
	return t;
}

bool is_type_valid_for_keys(Type *t);

Type *alloc_type_map(i64 count, Type *key, Type *value) {
	if (key != nullptr) {
		GB_ASSERT(is_type_valid_for_keys(key));
		GB_ASSERT(value != nullptr);
	}
	Type *t = alloc_type(Type_Map);
	t->Map.key   = key;
	t->Map.value = value;
	return t;
}

Type *alloc_type_bit_field_value(u32 bits) {
	Type *t = alloc_type(Type_BitFieldValue);
	t->BitFieldValue.bits = bits;
	return t;
}

Type *alloc_type_bit_field() {
	Type *t = alloc_type(Type_BitField);
	return t;
}
Type *alloc_type_bit_set() {
	Type *t = alloc_type(Type_BitSet);
	return t;
}



Type *alloc_type_simd_vector(i64 count, Type *elem) {
	Type *t = alloc_type(Type_SimdVector);
	t->SimdVector.count = count;
	t->SimdVector.elem = elem;
	return t;
}




////////////////////////////////////////////////////////////////


Type *type_deref(Type *t) {
	if (t != nullptr) {
		Type *bt = base_type(t);
		if (bt == nullptr) {
			return nullptr;
		}
		if (bt != nullptr && bt->kind == Type_Pointer) {
			return bt->Pointer.elem;
		}
		if (bt != nullptr && bt->kind == Type_RelativePointer) {
			return type_deref(bt->RelativePointer.pointer_type);
		}
	}
	return t;
}

bool is_type_named(Type *t) {
	if (t->kind == Type_Basic) {
		return true;
	}
	return t->kind == Type_Named;
}
bool is_type_named_alias(Type *t) {
	if (!is_type_named(t)) {
		return false;
	}
	Entity *e = t->Named.type_name;
	if (e == nullptr) {
		return false;
	}
	if (e->kind != Entity_TypeName) {
		return false;
	}
	return e->TypeName.is_type_alias;
}

bool is_type_boolean(Type *t) {
	// t = core_type(t);
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Boolean) != 0;
	}
	return false;
}
bool is_type_integer(Type *t) {
	// t = core_type(t);
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Integer) != 0;
	}
	return false;
}
bool is_type_unsigned(Type *t) {
	t = base_type(t);
	// t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Unsigned) != 0;
	}
	return false;
}
bool is_type_integer_128bit(Type *t) {
	// t = core_type(t);
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Integer) != 0 && t->Basic.size == 16;
	}
	return false;
}
bool is_type_rune(Type *t) {
	// t = core_type(t);
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Rune) != 0;
	}
	return false;
}
bool is_type_numeric(Type *t) {
	// t = core_type(t);
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Numeric) != 0;
	} else if (t->kind == Type_Enum) {
		return is_type_numeric(t->Enum.base_type);
	}
	// TODO(bill): Should this be here?
	if (t->kind == Type_Array) {
		return is_type_numeric(t->Array.elem);
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
bool is_type_cstring(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		return t->Basic.kind == Basic_cstring;
	}
	return false;
}
bool is_type_typed(Type *t) {
	t = base_type(t);
	if (t == nullptr) {
		return false;
	}
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
	t = core_type(t);
	switch (t->kind) {
	case Type_Basic:
		return (t->Basic.flags & BasicFlag_Ordered) != 0;
	case Type_Pointer:
		return true;
	}
	return false;
}
bool is_type_ordered_numeric(Type *t) {
	t = core_type(t);
	switch (t->kind) {
	case Type_Basic:
		return (t->Basic.flags & BasicFlag_OrderedNumeric) != 0;
	}
	return false;
}
bool is_type_constant_type(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_ConstantType) != 0;
	}
	if (t->kind == Type_BitSet) {
		return true;
	}
	if (t->kind == Type_Proc) {
		return true;
	}
	return false;
}
bool is_type_float(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Float) != 0;
	}
	return false;
}
bool is_type_complex(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Complex) != 0;
	}
	return false;
}
bool is_type_quaternion(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return (t->Basic.flags & BasicFlag_Quaternion) != 0;
	}
	return false;
}
bool is_type_f32(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		return t->Basic.kind == Basic_f32;
	}
	return false;
}
bool is_type_f64(Type *t) {
	t = core_type(t);
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
bool is_type_tuple(Type *t) {
	t = base_type(t);
	return t->kind == Type_Tuple;
}
bool is_type_opaque(Type *t) {
	t = base_type(t);
	return t->kind == Type_Opaque;
}
bool is_type_uintptr(Type *t) {
	if (t->kind == Type_Basic) {
		return (t->Basic.kind == Basic_uintptr);
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
bool is_type_enumerated_array(Type *t) {
	t = base_type(t);
	return t->kind == Type_EnumeratedArray;
}
bool is_type_dynamic_array(Type *t) {
	t = base_type(t);
	return t->kind == Type_DynamicArray;
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
bool is_type_u8_ptr(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Pointer) {
		return is_type_u8(t->Slice.elem);
	}
	return false;
}
bool is_type_proc(Type *t) {
	t = base_type(t);
	return t->kind == Type_Proc;
}
bool is_type_poly_proc(Type *t) {
	t = base_type(t);
	return t->kind == Type_Proc && t->Proc.is_polymorphic;
}
bool is_type_simd_vector(Type *t) {
	t = base_type(t);
	return t->kind == Type_SimdVector;
}

Type *base_array_type(Type *t) {
	Type *bt = base_type(t);
	if (is_type_array(bt)) {
		return bt->Array.elem;
	} else if (is_type_enumerated_array(bt)) {
		return bt->EnumeratedArray.elem;
	} else if (is_type_simd_vector(bt)) {
		return bt->SimdVector.elem;
	}
	return t;
}

bool is_type_generic(Type *t) {
	t = base_type(t);
	return t->kind == Type_Generic;
}

bool is_type_relative_pointer(Type *t) {
	t = base_type(t);
	return t->kind == Type_RelativePointer;
}
bool is_type_relative_slice(Type *t) {
	t = base_type(t);
	return t->kind == Type_RelativeSlice;
}


Type *core_array_type(Type *t) {
	for (;;) {
		Type *prev = t;
		t = base_array_type(t);
		if (t->kind != Type_Array && t->kind != Type_SimdVector) {
			break;
		}
	}
	return t;
}

// NOTE(bill): type can be easily compared using memcmp
bool is_type_simple_compare(Type *t) {
	t = core_type(t);
	switch (t->kind) {
	case Type_Array:
		return is_type_simple_compare(t->Array.elem);

	case Type_EnumeratedArray:
		return is_type_simple_compare(t->EnumeratedArray.elem);

	case Type_Basic:
		if (t->Basic.flags & BasicFlag_SimpleCompare) {
			return true;
		}
		return false;

	case Type_Pointer:
	case Type_Proc:
	case Type_BitSet:
	case Type_BitField:
		return true;

	case Type_Struct:
		for_array(i, t->Struct.fields) {
			Entity *f = t->Struct.fields[i];
			if (!is_type_simple_compare(f->type)) {
				return false;
			}
		}
		return true;

	case Type_Union:
		for_array(i, t->Union.variants) {
			Type *v = t->Union.variants[i];
			if (!is_type_simple_compare(v)) {
				return false;
			}
		}
		return true;

	case Type_SimdVector:
		return is_type_simple_compare(t->SimdVector.elem);

	}

	return false;
}

Type *base_complex_elem_type(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		switch (t->Basic.kind) {
		// case Basic_complex32:         return t_f16;
		case Basic_complex64:         return t_f32;
		case Basic_complex128:        return t_f64;
		case Basic_quaternion128:     return t_f32;
		case Basic_quaternion256:     return t_f64;
		case Basic_UntypedComplex:    return t_untyped_float;
		case Basic_UntypedQuaternion: return t_untyped_float;
		}
	}
	GB_PANIC("Invalid complex type");
	return t_invalid;
}

bool is_type_struct(Type *t) {
	t = base_type(t);
	return t->kind == Type_Struct;
}
bool is_type_union(Type *t) {
	t = base_type(t);
	return t->kind == Type_Union;
}
bool is_type_soa_struct(Type *t) {
	t = base_type(t);
	return t->kind == Type_Struct && t->Struct.soa_kind != StructSoa_None;
}

bool is_type_raw_union(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Struct && t->Struct.is_raw_union);
}
bool is_type_enum(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Enum);
}
bool is_type_bit_field(Type *t) {
	t = base_type(t);
	return (t->kind == Type_BitField);
}
bool is_type_bit_field_value(Type *t) {
	t = base_type(t);
	return (t->kind == Type_BitFieldValue);
}
bool is_type_bit_set(Type *t) {
	t = base_type(t);
	return (t->kind == Type_BitSet);
}
bool is_type_map(Type *t) {
	t = base_type(t);
	return t->kind == Type_Map;
}

bool is_type_union_maybe_pointer(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Union && t->Union.maybe) {
		if (t->Union.variants.count == 1) {
			return is_type_pointer(t->Union.variants[0]);
		}
	}
	return false;
}


bool is_type_union_maybe_pointer_original_alignment(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Union && t->Union.maybe) {
		if (t->Union.variants.count == 1) {
			Type *v = t->Union.variants[0];
			if (is_type_pointer(v)) {
				return type_align_of(v) == type_align_of(t);
			}
		}
	}
	return false;
}




bool is_type_integer_endian_big(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		if (t->Basic.flags & BasicFlag_EndianBig) {
			return true;
		} else if (t->Basic.flags & BasicFlag_EndianLittle) {
			return false;
		}
		return build_context.endian_kind == TargetEndian_Big;
	} else if (t->kind == Type_BitSet) {
		return is_type_integer_endian_big(bit_set_to_int(t));
	} else if (t->kind == Type_Pointer) {
		return is_type_integer_endian_big(&basic_types[Basic_uintptr]);
	}
	return build_context.endian_kind == TargetEndian_Big;
}


bool is_type_integer_endian_little(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Basic) {
		if (t->Basic.flags & BasicFlag_EndianLittle) {
			return true;
		} else if (t->Basic.flags & BasicFlag_EndianBig) {
			return false;
		}
		return build_context.endian_kind == TargetEndian_Little;
	} else if (t->kind == Type_BitSet) {
		return is_type_integer_endian_little(bit_set_to_int(t));
	} else if (t->kind == Type_Pointer) {
		return is_type_integer_endian_little(&basic_types[Basic_uintptr]);
	}
	return build_context.endian_kind == TargetEndian_Little;
}
bool is_type_endian_big(Type *t) {
	return is_type_integer_endian_big(t);
}
bool is_type_endian_little(Type *t) {
	return is_type_integer_endian_little(t);
}

bool types_have_same_internal_endian(Type *a, Type *b) {
	return is_type_endian_little(a) == is_type_endian_little(b);
}


bool is_type_dereferenceable(Type *t) {
	if (is_type_rawptr(t)) {
		return false;
	}
	return is_type_pointer(t);
}



bool is_type_different_to_arch_endianness(Type *t) {
	switch (build_context.endian_kind) {
	case TargetEndian_Little:
		return !is_type_integer_endian_little(t);
	case TargetEndian_Big:
		return !is_type_integer_endian_big(t);
	}
	return false;
}

Type *integer_endian_type_to_platform_type(Type *t) {
	t = core_type(t);
	if (t->kind == Type_BitSet) {
		t = bit_set_to_int(t);
	}
	GB_ASSERT(t->kind == Type_Basic);

	switch (t->Basic.kind) {
	// Endian Specific Types
	case Basic_i16le: return t_i16;
	case Basic_u16le: return t_u16;
	case Basic_i32le: return t_i32;
	case Basic_u32le: return t_u32;
	case Basic_i64le: return t_i64;
	case Basic_u64le: return t_u64;

	case Basic_i16be: return t_i16;
	case Basic_u16be: return t_u16;
	case Basic_i32be: return t_i32;
	case Basic_u32be: return t_u32;
	case Basic_i64be: return t_i64;
	case Basic_u64be: return t_u64;

	case Basic_f32le: return t_f32;
	case Basic_f32be: return t_f32;
	case Basic_f64le: return t_f64;
	case Basic_f64be: return t_f64;
	}

	return t;
}



bool is_type_any(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_any);
}
bool is_type_typeid(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_typeid);
}
bool is_type_untyped_nil(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_UntypedNil);
}
bool is_type_untyped_undef(Type *t) {
	t = base_type(t);
	return (t->kind == Type_Basic && t->Basic.kind == Basic_UntypedUndef);
}


bool is_type_empty_union(Type *t) {
	t = base_type(t);
	return t->kind == Type_Union && t->Union.variants.count == 0;
}
bool is_type_empty_struct(Type *t) {
	t = base_type(t);
	return t->kind == Type_Struct && !t->Struct.is_raw_union && t->Struct.fields.count == 0;
}


bool is_type_valid_for_keys(Type *t) {
	t = core_type(t);
	if (t->kind == Type_Generic) {
		return true;
	}
	if (is_type_untyped(t)) {
		return false;
	}
	if (is_type_integer(t)) {
		return true;
	}
	if (is_type_float(t)) {
		return true;
	}
	if (is_type_string(t)) {
		return true;
	}
	if (is_type_pointer(t)) {
		return true;
	}
	if (is_type_typeid(t)) {
		return true;
	}

	return false;
}

bool is_type_valid_bit_set_elem(Type *t) {
	if (is_type_enum(t)) {
		return true;
	}
	t = core_type(t);
	if (t->kind == Type_Generic) {
		return true;
	}
	return false;
}

Type *bit_set_to_int(Type *t) {
	GB_ASSERT(is_type_bit_set(t));
	Type *bt = base_type(t);
	Type *underlying = bt->BitSet.underlying;
	if (underlying != nullptr && is_type_integer(underlying)) {
		return underlying;
	}

	i64 sz = type_size_of(t);
	switch (sz) {
	case 0:  return t_u8;
	case 1:  return t_u8;
	case 2:  return t_u16;
	case 4:  return t_u32;
	case 8:  return t_u64;
	case 16: return t_u128;
	}
	GB_PANIC("Unknown bit_set size");
	return nullptr;
}

bool is_type_valid_vector_elem(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Basic) {
		if (t->Basic.flags & BasicFlag_EndianLittle) {
			return false;
		}
		if (t->Basic.flags & BasicFlag_EndianBig) {
			return false;
		}
		if (is_type_integer(t)) {
			return true;
		}
		if (is_type_float(t)) {
			return true;
		}
	}
	return false;
}


bool is_type_indexable(Type *t) {
	Type *bt = base_type(t);
	switch (bt->kind) {
	case Type_Basic:
		return bt->Basic.kind == Basic_string;
	case Type_Array:
	case Type_Slice:
	case Type_DynamicArray:
	case Type_Map:
		return true;
	case Type_EnumeratedArray:
		return true;
	case Type_RelativeSlice:
		return true;
	}
	return false;
}

bool is_type_sliceable(Type *t) {
	Type *bt = base_type(t);
	switch (bt->kind) {
	case Type_Basic:
		return bt->Basic.kind == Basic_string;
	case Type_Array:
	case Type_Slice:
	case Type_DynamicArray:
		return true;
	case Type_EnumeratedArray:
		return false;
	case Type_RelativeSlice:
		return true;
	}
	return false;
}


bool is_type_polymorphic_record(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Struct) {
		return t->Struct.is_polymorphic;
	} else if (t->kind == Type_Union) {
		return t->Union.is_polymorphic;
	}
	return false;
}

Scope *polymorphic_record_parent_scope(Type *t) {
	t = base_type(t);
	if (is_type_polymorphic_record(t)) {
		if (t->kind == Type_Struct) {
			return t->Struct.scope->parent;
		} else if (t->kind == Type_Union) {
			return t->Union.scope->parent;
		}
	}
	return nullptr;
}

bool is_type_polymorphic_record_specialized(Type *t) {
	Type *original_type = t;
	t = base_type(t);
	if (t->kind == Type_Struct) {
		return t->Struct.is_poly_specialized;
	} else if (t->kind == Type_Union) {
		return t->Union.is_poly_specialized;
	}
	return false;
}

bool is_type_polymorphic_record_unspecialized(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Struct) {
		return t->Struct.is_polymorphic && !t->Struct.is_poly_specialized;
	} else if (t->kind == Type_Struct) {
		return t->Struct.is_polymorphic && !t->Struct.is_poly_specialized;
	}
	return false;
}

TypeTuple *get_record_polymorphic_params(Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Struct:
		if (t->Struct.polymorphic_params) {
			return &t->Struct.polymorphic_params->Tuple;
		}
		break;
	case Type_Union:
		if (t->Union.polymorphic_params) {
			return &t->Union.polymorphic_params->Tuple;
		}
		break;
	}
	return nullptr;
}


bool is_type_polymorphic(Type *t, bool or_specialized=false) {
	switch (t->kind) {
	case Type_Generic:
		return true;

	case Type_Named:
		return is_type_polymorphic(t->Named.base, or_specialized);
	case Type_Opaque:
		return is_type_polymorphic(t->Opaque.elem, or_specialized);
	case Type_Pointer:
		return is_type_polymorphic(t->Pointer.elem, or_specialized);

	case Type_EnumeratedArray:
		if (is_type_polymorphic(t->EnumeratedArray.index, or_specialized)) {
			return true;
		}
		return is_type_polymorphic(t->EnumeratedArray.elem, or_specialized);
	case Type_Array:
		if (t->Array.generic_count != nullptr) {
			return true;
		}
		return is_type_polymorphic(t->Array.elem, or_specialized);
	case Type_DynamicArray:
		return is_type_polymorphic(t->DynamicArray.elem, or_specialized);
	case Type_Slice:
		return is_type_polymorphic(t->Slice.elem, or_specialized);

	case Type_Tuple:
		for_array(i, t->Tuple.variables) {
			if (is_type_polymorphic(t->Tuple.variables[i]->type, or_specialized)) {
				return true;
			}
		}
		break;

	case Type_Proc:
		if (t->Proc.is_polymorphic) {
			return true;
		}
		#if 1
		if (t->Proc.param_count > 0 &&
		    is_type_polymorphic(t->Proc.params, or_specialized)) {
			return true;
		}
		if (t->Proc.result_count > 0 &&
		    is_type_polymorphic(t->Proc.results, or_specialized)) {
			return true;
		}
		#endif
		break;

	case Type_Enum:
		if (t->kind == Type_Enum) {
			if (t->Enum.base_type != nullptr) {
				return is_type_polymorphic(t->Enum.base_type, or_specialized);
			}
			return false;
		}
		break;
	case Type_Union:
		if (t->Union.is_polymorphic) {
			return true;
		}
		if (or_specialized && t->Union.is_poly_specialized) {
			return true;
		}
		// for_array(i, t->Union.variants) {
		//     if (is_type_polymorphic(t->Union.variants[i], or_specialized)) {
		//     	return true;
		//     }
		// }
		break;
	case Type_Struct:
		if (t->Struct.is_polymorphic) {
			return true;
		}
		if (or_specialized && t->Struct.is_poly_specialized) {
			return true;
		}
		break;

	case Type_Map:
		if (t->Map.key == nullptr || t->Map.value == nullptr) {
			return false;
		}
		if (is_type_polymorphic(t->Map.key, or_specialized)) {
			return true;
		}
		if (is_type_polymorphic(t->Map.value, or_specialized)) {
			return true;
		}
		break;

	}

	return false;
}


bool type_has_undef(Type *t) {
	return true;
}

bool type_has_nil(Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Basic: {
		switch (t->Basic.kind) {
		case Basic_rawptr:
		case Basic_any:
			return true;
		case Basic_cstring:
			return true;
		case Basic_typeid:
			return true;
		}
		return false;
	} break;
	case Type_Enum:
	case Type_BitSet:
	case Type_BitField:
		return true;
	case Type_Slice:
	case Type_Proc:
	case Type_Pointer:
	case Type_DynamicArray:
	case Type_Map:
		return true;
	case Type_Union:
		return !t->Union.no_nil;
	case Type_Struct:
		if (is_type_soa_struct(t)) {
			switch (t->Struct.soa_kind) {
			case StructSoa_Fixed:   return false;
			case StructSoa_Slice:   return true;
			case StructSoa_Dynamic: return true;
			}
		}
		return false;
	case Type_Opaque:
		return true;

	case Type_RelativePointer:
	case Type_RelativeSlice:
		return true;
	}
	return false;
}

bool elem_type_can_be_constant(Type *t) {
	t = base_type(t);
	if (t == t_invalid) {
		return false;
	}
	if (is_type_any(t) || is_type_union(t) || is_type_raw_union(t)) {
		return false;
	}
	return true;
}


bool is_type_comparable(Type *t) {
	t = base_type(t);
	switch (t->kind) {
	case Type_Basic:
		switch (t->Basic.kind) {
		case Basic_UntypedNil:
		case Basic_any:
			return false;
		case Basic_rune:
			return true;
		case Basic_string:
			return true;
		case Basic_cstring:
			return true;
		case Basic_typeid:
			return true;
		}
		return true;
	case Type_Pointer:
		return true;
	case Type_Enum:
		return is_type_comparable(core_type(t));
	case Type_EnumeratedArray:
		return is_type_comparable(t->EnumeratedArray.elem);
	case Type_Array:
		return is_type_comparable(t->Array.elem);
	case Type_Proc:
		return true;

	case Type_BitSet:
		return true;

	case Type_BitFieldValue:
		return true;

	case Type_Opaque:
		return is_type_comparable(t->Opaque.elem);
	}
	return false;
}

Type *strip_type_aliasing(Type *x) {
	if (x == nullptr) {
		return x;
	}
	if (x->kind == Type_Named) {
		Entity *e = x->Named.type_name;
		if (e != nullptr && e->kind == Entity_TypeName && e->TypeName.is_type_alias) {
			return x->Named.base;
		}
	}
	return x;
}

bool are_types_identical(Type *x, Type *y) {
	if (x == y) {
		return true;
	}

	if ((x == nullptr && y != nullptr) ||
	    (x != nullptr && y == nullptr)) {
		return false;
	}

	x = strip_type_aliasing(x);
	y = strip_type_aliasing(y);

	switch (x->kind) {
	case Type_Generic:
		if (y->kind == Type_Generic) {
			return are_types_identical(x->Generic.specialized, y->Generic.specialized);
		}
		break;

	case Type_Opaque:
		if (y->kind == Type_Opaque) {
			return are_types_identical(x->Opaque.elem, y->Opaque.elem);
		}
		break;

	case Type_Basic:
		if (y->kind == Type_Basic) {
			return x->Basic.kind == y->Basic.kind;
		}
		break;

	case Type_EnumeratedArray:
		if (y->kind == Type_EnumeratedArray) {
			return are_types_identical(x->EnumeratedArray.index, y->EnumeratedArray.index) &&
			       are_types_identical(x->EnumeratedArray.elem,  y->EnumeratedArray.elem);
		}
		break;

	case Type_Array:
		if (y->kind == Type_Array) {
			return (x->Array.count == y->Array.count) && are_types_identical(x->Array.elem, y->Array.elem);
		}
		break;

	case Type_DynamicArray:
		if (y->kind == Type_DynamicArray) {
			return are_types_identical(x->DynamicArray.elem, y->DynamicArray.elem);
		}
		break;

	case Type_Slice:
		if (y->kind == Type_Slice) {
			return are_types_identical(x->Slice.elem, y->Slice.elem);
		}
		break;

	case Type_BitField:
		if (y->kind == Type_BitField) {
			if (x->BitField.fields.count == y->BitField.fields.count &&
			    x->BitField.custom_align == y->BitField.custom_align) {
				for (i32 i = 0; i < x->BitField.fields.count; i++) {
					if (x->BitField.offsets[i] != y->BitField.offsets[i]) {
						return false;
					}
					if (x->BitField.sizes[i] != y->BitField.sizes[i]) {
						return false;
					}
				}

				return true;
			}
		}
		break;

	case Type_BitSet:
		if (y->kind == Type_BitSet) {
			return are_types_identical(x->BitSet.elem, y->BitSet.elem) &&
			       are_types_identical(x->BitSet.underlying, y->BitSet.underlying) &&
			       x->BitSet.lower == y->BitSet.lower &&
			       x->BitSet.upper == y->BitSet.upper;
		}
		break;


	case Type_Enum:
		return x == y; // NOTE(bill): All enums are unique

	case Type_Union:
		if (y->kind == Type_Union) {
			if (x->Union.variants.count == y->Union.variants.count &&
			    x->Union.custom_align == y->Union.custom_align &&
			    x->Union.no_nil == y->Union.no_nil) {
				// NOTE(bill): zeroth variant is nullptr
				for_array(i, x->Union.variants) {
					if (!are_types_identical(x->Union.variants[i], y->Union.variants[i])) {
						return false;
					}
				}
				return true;
			}
		}
		break;

	case Type_Struct:
		if (y->kind == Type_Struct) {
			if (x->Struct.is_raw_union == y->Struct.is_raw_union &&
			    x->Struct.fields.count == y->Struct.fields.count &&
			    x->Struct.is_packed    == y->Struct.is_packed &&
			    x->Struct.custom_align == y->Struct.custom_align &&
			    x->Struct.soa_kind == y->Struct.soa_kind &&
			    x->Struct.soa_count == y->Struct.soa_count &&
			    are_types_identical(x->Struct.soa_elem, y->Struct.soa_elem)) {
				// TODO(bill); Fix the custom alignment rule
				for_array(i, x->Struct.fields) {
					Entity *xf = x->Struct.fields[i];
					Entity *yf = y->Struct.fields[i];
					if (xf->kind != yf->kind) {
						return false;
					}
					if (!are_types_identical(xf->type, yf->type)) {
						return false;
					}
					if (xf->token.string != yf->token.string) {
						return false;
					}
					bool xf_is_using = (xf->flags&EntityFlag_Using) != 0;
					bool yf_is_using = (yf->flags&EntityFlag_Using) != 0;
					if (xf_is_using ^ yf_is_using) {
						return false;
					}
					if (x->Struct.tags.count != y->Struct.tags.count) {
						return false;
					}
					if (x->Struct.tags.count > 0 && x->Struct.tags[i] != y->Struct.tags[i]) {
						return false;
					}
				}
				return true;
			}
		}
		break;

	case Type_Pointer:
		if (y->kind == Type_Pointer) {
			return are_types_identical(x->Pointer.elem, y->Pointer.elem);
		}
		break;

	case Type_Named:
		if (y->kind == Type_Named) {
			return x->Named.type_name == y->Named.type_name;
		}
		break;

	case Type_Tuple:
		if (y->kind == Type_Tuple) {
			if (x->Tuple.variables.count == y->Tuple.variables.count &&
			    x->Tuple.is_packed == y->Tuple.is_packed) {
				for_array(i, x->Tuple.variables) {
					Entity *xe = x->Tuple.variables[i];
					Entity *ye = y->Tuple.variables[i];
					if (xe->kind != ye->kind || !are_types_identical(xe->type, ye->type)) {
						return false;
					}
					if (xe->kind == Entity_Constant && !compare_exact_values(Token_CmpEq, xe->Constant.value, ye->Constant.value)) {
						// NOTE(bill): This is needed for polymorphic procedures
						return false;
					}
				}
				return true;
			}
		}
		break;

	case Type_Proc:
		if (y->kind == Type_Proc) {
			return x->Proc.calling_convention == y->Proc.calling_convention &&
			       x->Proc.c_vararg    == y->Proc.c_vararg    &&
			       x->Proc.variadic    == y->Proc.variadic    &&
			       x->Proc.diverging   == y->Proc.diverging   &&
			       x->Proc.optional_ok == y->Proc.optional_ok &&
			       are_types_identical(x->Proc.params, y->Proc.params) &&
			       are_types_identical(x->Proc.results, y->Proc.results);
		}
		break;

	case Type_Map:
		if (y->kind == Type_Map) {
			return are_types_identical(x->Map.key,   y->Map.key) &&
			       are_types_identical(x->Map.value, y->Map.value);
		}
		break;

	case Type_SimdVector:
		if (y->kind == Type_SimdVector) {
			if (x->SimdVector.is_x86_mmx == y->SimdVector.is_x86_mmx) {
				if (x->SimdVector.is_x86_mmx) {
					return true;
				} else if (x->SimdVector.count == y->SimdVector.count) {
					return are_types_identical(x->SimdVector.elem, y->SimdVector.elem);
				}
			}
		}
		break;
	}

	return false;
}

Type *default_bit_field_value_type(Type *type) {
	if (type == nullptr) {
		return t_invalid;
	}
	Type *t = base_type(type);
	if (t->kind == Type_BitFieldValue) {
		i32 bits = t->BitFieldValue.bits;
		i32 size = 8*next_pow2((bits+7)/8);
		switch (size) {
		case 8:   return t_u8;
		case 16:  return t_u16;
		case 32:  return t_u32;
		case 64:  return t_u64;
		default:  GB_PANIC("Too big of a bit size!"); break;
		}
	}
	return type;
}

Type *default_type(Type *type) {
	if (type == nullptr) {
		return t_invalid;
	}
	if (type->kind == Type_Basic) {
		switch (type->Basic.kind) {
		case Basic_UntypedBool:       return t_bool;
		case Basic_UntypedInteger:    return t_int;
		case Basic_UntypedFloat:      return t_f64;
		case Basic_UntypedComplex:    return t_complex128;
		case Basic_UntypedQuaternion: return t_quaternion256;
		case Basic_UntypedString:     return t_string;
		case Basic_UntypedRune:       return t_rune;
		}
	}
	if (type->kind == Type_BitFieldValue) {
		return default_bit_field_value_type(type);
	}
	return type;
}

i64 union_variant_index(Type *u, Type *v) {
	u = base_type(u);
	GB_ASSERT(u->kind == Type_Union);

	for_array(i, u->Union.variants) {
		Type *vt = u->Union.variants[i];
		if (are_types_identical(v, vt)) {
			if (u->Union.no_nil) {
				return cast(i64)(i+0);
			} else {
				return cast(i64)(i+1);
			}
		}
	}
	return 0;
}

i64 union_tag_size(Type *u) {
	u = base_type(u);
	GB_ASSERT(u->kind == Type_Union);
	if (u->Union.tag_size > 0) {
		return u->Union.tag_size;
	}

	u64 n = cast(u64)u->Union.variants.count;
	if (n == 0) {
		return 0;
	}

#if 1
	// TODO(bill): Is this an okay approach?
	i64 max_align = 1;
	for_array(i, u->Union.variants) {
		Type *variant_type = u->Union.variants[i];
		i64 align = type_align_of(variant_type);
		if (max_align < align) {
			max_align = align;
		}
	}

	u->Union.tag_size = gb_min(max_align, build_context.max_align);
	return max_align;
#else
	i64 bytes = next_pow2(cast(i64)(floor_log2(n)/8 + 1));
	i64 tag_size = gb_max(bytes, 1);

	u->Union.tag_size = tag_size;
	return tag_size;
#endif
}

Type *union_tag_type(Type *u) {
	i64 s = union_tag_size(u);
	switch (s) {
	case  0: return  t_u8;
	case  1: return  t_u8;
	case  2: return  t_u16;
	case  4: return  t_u32;
	case  8: return  t_u64;
	}
	GB_PANIC("Invalid union_tag_size");
	return t_uint;
}



enum ProcTypeOverloadKind {
	ProcOverload_Identical, // The types are identical

	ProcOverload_CallingConvention,
	ProcOverload_ParamCount,
	ProcOverload_ParamVariadic,
	ProcOverload_ParamTypes,
	ProcOverload_ResultCount,
	ProcOverload_ResultTypes,
	ProcOverload_Polymorphic,

	ProcOverload_NotProcedure,

};

ProcTypeOverloadKind are_proc_types_overload_safe(Type *x, Type *y) {
	if (x == nullptr && y == nullptr) return ProcOverload_NotProcedure;
	if (x == nullptr && y != nullptr) return ProcOverload_NotProcedure;
	if (x != nullptr && y == nullptr) return ProcOverload_NotProcedure;
 	if (!is_type_proc(x))       return ProcOverload_NotProcedure;
 	if (!is_type_proc(y))       return ProcOverload_NotProcedure;

	TypeProc px = base_type(x)->Proc;
	TypeProc py = base_type(y)->Proc;


	// if (px.calling_convention != py.calling_convention) {
		// return ProcOverload_CallingConvention;
	// }

	// if (px.is_polymorphic != py.is_polymorphic) {
		// return ProcOverload_Polymorphic;
	// }

	if (px.param_count != py.param_count) {
		return ProcOverload_ParamCount;
	}

	for (isize i = 0; i < px.param_count; i++) {
		Entity *ex = px.params->Tuple.variables[i];
		Entity *ey = py.params->Tuple.variables[i];
		if (!are_types_identical(ex->type, ey->type)) {
			return ProcOverload_ParamTypes;
		}
	}
	// IMPORTANT TODO(bill): Determine the rules for overloading procedures with variadic parameters
	if (px.variadic != py.variadic) {
		return ProcOverload_ParamVariadic;
	}


	if (px.is_polymorphic != py.is_polymorphic) {
		return ProcOverload_Polymorphic;
	}

	if (px.result_count != py.result_count) {
		return ProcOverload_ResultCount;
	}

	for (isize i = 0; i < px.result_count; i++) {
		Entity *ex = px.results->Tuple.variables[i];
		Entity *ey = py.results->Tuple.variables[i];
		if (!are_types_identical(ex->type, ey->type)) {
			return ProcOverload_ResultTypes;
		}
	}

	if (px.params != nullptr && py.params != nullptr) {
		Entity *ex = px.params->Tuple.variables[0];
		Entity *ey = py.params->Tuple.variables[0];
		bool ok = are_types_identical(ex->type, ey->type);
		if (ok) {
		}
	}

	return ProcOverload_Identical;
}





Selection lookup_field_with_selection(Type *type_, String field_name, bool is_type, Selection sel, bool allow_blank_ident=false);

Selection lookup_field(Type *type_, String field_name, bool is_type, bool allow_blank_ident=false) {
	return lookup_field_with_selection(type_, field_name, is_type, empty_selection, allow_blank_ident);
}

Selection lookup_field_from_index(Type *type, i64 index) {
	GB_ASSERT(is_type_struct(type) || is_type_union(type) || is_type_tuple(type));
	type = base_type(type);

	gbAllocator a = heap_allocator();
	isize max_count = 0;
	switch (type->kind) {
	case Type_Struct:   max_count = type->Struct.fields.count;   break;
	case Type_Tuple:    max_count = type->Tuple.variables.count; break;
	case Type_BitField: max_count = type->BitField.fields.count; break;
	}

	if (index >= max_count) {
		return empty_selection;
	}

	switch (type->kind) {
	case Type_Struct:
		for (isize i = 0; i < max_count; i++) {
			Entity *f = type->Struct.fields[i];
			if (f->kind == Entity_Variable) {
				if (f->Variable.field_src_index == index) {
					auto sel_array = array_make<i32>(a, 1);
					sel_array[0] = cast(i32)i;
					return make_selection(f, sel_array, false);
				}
			}
		}
		break;
	case Type_Tuple:
		for (isize i = 0; i < max_count; i++) {
			Entity *f = type->Tuple.variables[i];
			if (i == index) {
				auto sel_array = array_make<i32>(a, 1);
				sel_array[0] = cast(i32)i;
				return make_selection(f, sel_array, false);
			}
		}
		break;

	case Type_BitField: {
		auto sel_array = array_make<i32>(a, 1);
		sel_array[0] = cast(i32)index;
		return make_selection(type->BitField.fields[cast(isize)index], sel_array, false);
	} break;

	}

	GB_PANIC("Illegal index");
	return empty_selection;
}


Entity *scope_lookup_current(Scope *s, String const &name);

Selection lookup_field_with_selection(Type *type_, String field_name, bool is_type, Selection sel, bool allow_blank_ident) {
	GB_ASSERT(type_ != nullptr);

	if (!allow_blank_ident && is_blank_ident(field_name)) {
		return empty_selection;
	}

	gbAllocator a = heap_allocator();
	Type *type = type_deref(type_);
	bool is_ptr = type != type_;
	sel.indirect = sel.indirect || is_ptr;

	type = base_type(type);

	if (is_type) {
		switch (type->kind) {
		case Type_Struct:
			if (type->Struct.names != nullptr &&
			    field_name == "names") {
				sel.entity = type->Struct.names;
				return sel;
			}
			break;
		case Type_Enum:
			if (type->Enum.names != nullptr &&
			    field_name == "names") {
				sel.entity = type->Enum.names;
				return sel;
			}
			break;
		}


		if (is_type_enum(type)) {
			// NOTE(bill): These may not have been added yet, so check in case
			for_array(i, type->Enum.fields) {
				Entity *f = type->Enum.fields[i];
				GB_ASSERT(f->kind == Entity_Constant);
				String str = f->token.string;

				if (field_name == str) {
					sel.entity = f;
					// selection_add_index(&sel, i);
					return sel;
				}
			}
		}

		if (type->kind == Type_Struct) {
			Scope *s = type->Struct.scope;
			if (s != nullptr) {
				Entity *found = scope_lookup_current(s, field_name);
				if (found != nullptr && found->kind != Entity_Variable) {
					sel.entity = found;
					return sel;
				}
			}
		} else if (type->kind == Type_Union) {
			Scope *s = type->Union.scope;
			if (s != nullptr) {
				Entity *found = scope_lookup_current(s, field_name);
				if (found != nullptr && found->kind != Entity_Variable) {
					sel.entity = found;
					return sel;
				}
			}
		} else if (type->kind == Type_BitSet) {
			return lookup_field_with_selection(type->BitSet.elem, field_name, true, sel, allow_blank_ident);
		}


		if (type->kind == Type_Generic && type->Generic.specialized != nullptr) {
			Type *specialized = type->Generic.specialized;
			return lookup_field_with_selection(specialized, field_name, is_type, sel, allow_blank_ident);
		}

	} else if (type->kind == Type_Union) {

	} else if (type->kind == Type_Struct) {
		for_array(i, type->Struct.fields) {
			Entity *f = type->Struct.fields[i];
			if (f->kind != Entity_Variable || (f->flags & EntityFlag_Field) == 0) {
				continue;
			}
			String str = f->token.string;
			if (field_name == str) {
				selection_add_index(&sel, i);  // HACK(bill): Leaky memory
				sel.entity = f;
				return sel;
			}

			if (f->flags & EntityFlag_Using) {
				isize prev_count = sel.index.count;
				selection_add_index(&sel, i); // HACK(bill): Leaky memory

				sel = lookup_field_with_selection(f->type, field_name, is_type, sel, allow_blank_ident);

				if (sel.entity != nullptr) {
					if (is_type_pointer(f->type)) {
						sel.indirect = true;
					}
					return sel;
				}
				sel.index.count = prev_count;
			}
		}

		bool is_soa = type->Struct.soa_kind != StructSoa_None;
		bool is_soa_of_array = is_soa && is_type_array(type->Struct.soa_elem);

		if (is_soa_of_array) {
			String mapped_field_name = {};
			     if (field_name == "r") mapped_field_name = str_lit("x");
			else if (field_name == "g") mapped_field_name = str_lit("y");
			else if (field_name == "b") mapped_field_name = str_lit("z");
			else if (field_name == "a") mapped_field_name = str_lit("w");
			return lookup_field_with_selection(type, mapped_field_name, is_type, sel, allow_blank_ident);
		}

	} else if (type->kind == Type_BitField) {
		for_array(i, type->BitField.fields) {
			Entity *f = type->BitField.fields[i];
			if (f->kind != Entity_Variable ||
			    (f->flags & EntityFlag_BitFieldValue) == 0) {
				continue;
			}

			String str = f->token.string;
			if (field_name == str) {
				selection_add_index(&sel, i);  // HACK(bill): Leaky memory
				sel.entity = f;
				return sel;
			}
		}
	} else if (type->kind == Type_Basic) {
		switch (type->Basic.kind) {
		case Basic_any: {
		#if 1
			// IMPORTANT TODO(bill): Should these members be available to should I only allow them with
			// `Raw_Any` type?
			String data_str = str_lit("data");
			String id_str = str_lit("id");
			gb_local_persist Entity *entity__any_data = alloc_entity_field(nullptr, make_token_ident(data_str), t_rawptr, false, 0);
			gb_local_persist Entity *entity__any_id = alloc_entity_field(nullptr, make_token_ident(id_str), t_typeid, false, 1);

			if (field_name == data_str) {
				selection_add_index(&sel, 0);
				sel.entity = entity__any_data;
				return sel;
			} else if (field_name == id_str) {
				selection_add_index(&sel, 1);
				sel.entity = entity__any_id;
				return sel;
			}
		#endif
		} break;

		case Basic_quaternion128: {
			// @QuaternionLayout
			gb_local_persist String w = str_lit("w");
			gb_local_persist String x = str_lit("x");
			gb_local_persist String y = str_lit("y");
			gb_local_persist String z = str_lit("z");
			gb_local_persist Entity *entity__w = alloc_entity_field(nullptr, make_token_ident(w), t_f32, false, 3);
			gb_local_persist Entity *entity__x = alloc_entity_field(nullptr, make_token_ident(x), t_f32, false, 0);
			gb_local_persist Entity *entity__y = alloc_entity_field(nullptr, make_token_ident(y), t_f32, false, 1);
			gb_local_persist Entity *entity__z = alloc_entity_field(nullptr, make_token_ident(z), t_f32, false, 2);
			if (field_name == w) {
				selection_add_index(&sel, 3);
				sel.entity = entity__w;
				return sel;
			} else if (field_name == x) {
				selection_add_index(&sel, 0);
				sel.entity = entity__x;
				return sel;
			} else if (field_name == y) {
				selection_add_index(&sel, 1);
				sel.entity = entity__y;
				return sel;
			} else if (field_name == z) {
				selection_add_index(&sel, 2);
				sel.entity = entity__z;
				return sel;
			}
		} break;

		case Basic_quaternion256: {
			// @QuaternionLayout
			gb_local_persist String w = str_lit("w");
			gb_local_persist String x = str_lit("x");
			gb_local_persist String y = str_lit("y");
			gb_local_persist String z = str_lit("z");
			gb_local_persist Entity *entity__w = alloc_entity_field(nullptr, make_token_ident(w), t_f64, false, 3);
			gb_local_persist Entity *entity__x = alloc_entity_field(nullptr, make_token_ident(x), t_f64, false, 0);
			gb_local_persist Entity *entity__y = alloc_entity_field(nullptr, make_token_ident(y), t_f64, false, 1);
			gb_local_persist Entity *entity__z = alloc_entity_field(nullptr, make_token_ident(z), t_f64, false, 2);
			if (field_name == w) {
				selection_add_index(&sel, 3);
				sel.entity = entity__w;
				return sel;
			} else if (field_name == x) {
				selection_add_index(&sel, 0);
				sel.entity = entity__x;
				return sel;
			} else if (field_name == y) {
				selection_add_index(&sel, 1);
				sel.entity = entity__y;
				return sel;
			} else if (field_name == z) {
				selection_add_index(&sel, 2);
				sel.entity = entity__z;
				return sel;
			}
		} break;

		case Basic_UntypedQuaternion: {
			// @QuaternionLayout
			gb_local_persist String w = str_lit("w");
			gb_local_persist String x = str_lit("x");
			gb_local_persist String y = str_lit("y");
			gb_local_persist String z = str_lit("z");
			gb_local_persist Entity *entity__w = alloc_entity_field(nullptr, make_token_ident(w), t_untyped_float, false, 3);
			gb_local_persist Entity *entity__x = alloc_entity_field(nullptr, make_token_ident(x), t_untyped_float, false, 0);
			gb_local_persist Entity *entity__y = alloc_entity_field(nullptr, make_token_ident(y), t_untyped_float, false, 1);
			gb_local_persist Entity *entity__z = alloc_entity_field(nullptr, make_token_ident(z), t_untyped_float, false, 2);
			if (field_name == w) {
				selection_add_index(&sel, 3);
				sel.entity = entity__w;
				return sel;
			} else if (field_name == x) {
				selection_add_index(&sel, 0);
				sel.entity = entity__x;
				return sel;
			} else if (field_name == y) {
				selection_add_index(&sel, 1);
				sel.entity = entity__y;
				return sel;
			} else if (field_name == z) {
				selection_add_index(&sel, 2);
				sel.entity = entity__z;
				return sel;
			}
		} break;

		}

		return sel;
	} else if (type->kind == Type_Array) {
		if (type->Array.count <= 4) {
			// HACK(bill): Memory leak
			switch (type->Array.count) {
			#define _ARRAY_FIELD_CASE_IF(_length, _name) \
				if (field_name == (_name)) { \
					selection_add_index(&sel, (_length)-1); \
					sel.entity = alloc_entity_array_elem(nullptr, make_token_ident(str_lit(_name)), type->Array.elem, (_length)-1); \
					return sel; \
				}
			#define _ARRAY_FIELD_CASE(_length, _name0, _name1) \
			case (_length): \
				_ARRAY_FIELD_CASE_IF(_length, _name0); \
				_ARRAY_FIELD_CASE_IF(_length, _name1); \
				/*fallthrough*/

			_ARRAY_FIELD_CASE(4, "w", "a");
			_ARRAY_FIELD_CASE(3, "z", "b");
			_ARRAY_FIELD_CASE(2, "y", "g");
			_ARRAY_FIELD_CASE(1, "x", "r");
			default: break;

			#undef _ARRAY_FIELD_CASE
			}
		}
	} else if (type->kind == Type_DynamicArray) {
		// IMPORTANT TODO(bill): Should these members be available to should I only allow them with
		// `Raw_Dynamic_Array` type?
		GB_ASSERT(t_allocator != nullptr);
		String allocator_str = str_lit("allocator");
		gb_local_persist Entity *entity__allocator = alloc_entity_field(nullptr, make_token_ident(allocator_str), t_allocator, false, 3);

		if (field_name == allocator_str) {
			selection_add_index(&sel, 3);
			sel.entity = entity__allocator;
			return sel;
		}
	} else if (type->kind == Type_Map) {
		// IMPORTANT TODO(bill): Should these members be available to should I only allow them with
		// `Raw_Map` type?
		GB_ASSERT(t_allocator != nullptr);
		String allocator_str = str_lit("allocator");
		gb_local_persist Entity *entity__allocator = alloc_entity_field(nullptr, make_token_ident(allocator_str), t_allocator, false, 3);

		if (field_name == allocator_str) {
			selection_add_index(&sel, 1);
			selection_add_index(&sel, 3);
			sel.entity = entity__allocator;
			return sel;
		}
	}

	return sel;
}


// IMPORTANT TODO(bill): SHould this TypePath code be removed since type cycle checking is handled much earlier on?

struct TypePath {
	Array<Entity *> path; // Entity_TypeName;
	bool failure;
};


void type_path_init(TypePath *tp) {
	tp->path.allocator = heap_allocator();
}

void type_path_free(TypePath *tp) {
	array_free(&tp->path);
}

void type_path_print_illegal_cycle(TypePath *tp, isize start_index) {
	GB_ASSERT(tp != nullptr);

	GB_ASSERT(start_index < tp->path.count);
	Entity *e = tp->path[start_index];
	GB_ASSERT(e != nullptr);
	error(e->token, "Illegal declaration cycle of `%.*s`", LIT(e->token.string));
	// NOTE(bill): Print cycle, if it's deep enough
	for (isize j = start_index; j < tp->path.count; j++) {
		Entity *e = tp->path[j];
		error(e->token, "\t%.*s refers to", LIT(e->token.string));
	}
	// NOTE(bill): This will only print if the path count > 1
	error(e->token, "\t%.*s", LIT(e->token.string));
	tp->failure = true;
	e->type->failure = true;
	base_type(e->type)->failure = true;
}

bool type_path_push(TypePath *tp, Type *t) {
	GB_ASSERT(tp != nullptr);
	if (t->kind != Type_Named) {
		return false;
	}
	Entity *e = t->Named.type_name;

	for (isize i = 0; i < tp->path.count; i++) {
		Entity *p = tp->path[i];
		if (p == e) {
			type_path_print_illegal_cycle(tp, i);
		}
	}

	array_add(&tp->path, e);
	return true;
}

void type_path_pop(TypePath *tp) {
	if (tp != nullptr && tp->path.count > 0) {
		array_pop(&tp->path);
	}
}


#define FAILURE_SIZE      0
#define FAILURE_ALIGNMENT 0


i64 type_size_of_internal (Type *t, TypePath *path);
i64 type_align_of_internal(Type *t, TypePath *path);



i64 type_size_of(Type *t) {
	if (t == nullptr) {
		return 0;
	}
	// NOTE(bill): Always calculate the size when it is a Type_Basic
	if (t->kind == Type_Named && t->cached_size >= 0) {

	} else if (t->kind != Type_Basic && t->cached_size >= 0) {
		return t->cached_size;
	}
	TypePath path = {0};
	type_path_init(&path);
	t->cached_size = type_size_of_internal(t, &path);
	type_path_free(&path);
	return t->cached_size;
}

i64 type_align_of(Type *t) {
	if (t == nullptr) {
		return 1;
	}
	// NOTE(bill): Always calculate the size when it is a Type_Basic
	if (t->kind == Type_Named && t->cached_align >= 0) {

	} if (t->kind != Type_Basic && t->cached_align > 0) {
		return t->cached_align;
	}

	TypePath path = {0};
	type_path_init(&path);
	t->cached_align = type_align_of_internal(t, &path);
	type_path_free(&path);
	return t->cached_align;
}


i64 type_align_of_internal(Type *t, TypePath *path) {
	GB_ASSERT(path != nullptr);
	if (t->failure) {
		return FAILURE_ALIGNMENT;
	}

	t = base_type(t);

	switch (t->kind) {
	case Type_Basic: {
		GB_ASSERT(is_type_typed(t));
		switch (t->Basic.kind) {
		case Basic_string:  return build_context.word_size;
		case Basic_cstring: return build_context.word_size;
		case Basic_any:     return build_context.word_size;
		case Basic_typeid:  return build_context.word_size;

		case Basic_int: case Basic_uint: case Basic_uintptr: case Basic_rawptr:
			return build_context.word_size;

		case Basic_complex64: case Basic_complex128:
			return type_size_of_internal(t, path) / 2;
		case Basic_quaternion128: case Basic_quaternion256:
			return type_size_of_internal(t, path) / 4;
		}
	} break;

	case Type_Array: {
		Type *elem = t->Array.elem;
		bool pop = type_path_push(path, elem);
		if (path->failure) {
			return FAILURE_ALIGNMENT;
		}
		i64 align = type_align_of_internal(t->Array.elem, path);
		if (pop) type_path_pop(path);
		return align;
	}

	case Type_EnumeratedArray: {
		Type *elem = t->EnumeratedArray.elem;
		bool pop = type_path_push(path, elem);
		if (path->failure) {
			return FAILURE_ALIGNMENT;
		}
		i64 align = type_align_of_internal(t->EnumeratedArray.elem, path);
		if (pop) type_path_pop(path);
		return align;
	}

	case Type_Opaque:
		return type_align_of_internal(t->Opaque.elem, path);

	case Type_DynamicArray:
		// data, count, capacity, allocator
		return build_context.word_size;

	case Type_Slice:
		return build_context.word_size;


	case Type_Tuple: {
		i64 max = 1;
		for_array(i, t->Tuple.variables) {
			i64 align = type_align_of_internal(t->Tuple.variables[i]->type, path);
			if (max < align) {
				max = align;
			}
		}
		return max;
	} break;

	case Type_Map:
		init_map_internal_types(t);
		return type_align_of_internal(t->Map.internal_type, path);
	case Type_Enum:
		return type_align_of_internal(t->Enum.base_type, path);

	case Type_Union: {
		if (t->Union.variants.count == 0) {
			return 1;
		}
		if (t->Union.custom_align > 0) {
			return gb_clamp(t->Union.custom_align, 1, build_context.max_align);
		}

		i64 max = 1;
		for_array(i, t->Union.variants) {
			Type *variant = t->Union.variants[i];
			bool pop = type_path_push(path, variant);
			if (path->failure) {
				return FAILURE_ALIGNMENT;
			}
			i64 align = type_align_of_internal(variant, path);
			if (pop) type_path_pop(path);
			if (max < align) {
				max = align;
			}
		}
		return max;
	} break;

	case Type_Struct: {
		if (t->Struct.custom_align > 0) {
			return gb_clamp(t->Struct.custom_align, 1, build_context.max_align);
		}
		if (t->Struct.is_raw_union) {
			i64 max = 1;
			for_array(i, t->Struct.fields) {
				Type *field_type = t->Struct.fields[i]->type;
				bool pop = type_path_push(path, field_type);
				if (path->failure) {
					return FAILURE_ALIGNMENT;
				}
				i64 align = type_align_of_internal(field_type, path);
				if (pop) type_path_pop(path);
				if (max < align) {
					max = align;
				}
			}
			return max;
		} else if (t->Struct.fields.count > 0) {
			i64 max = 1;
			// NOTE(bill): Check the fields to check for cyclic definitions
			for_array(i, t->Struct.fields) {
				Type *field_type = t->Struct.fields[i]->type;
				bool pop = type_path_push(path, field_type);
				if (path->failure) return FAILURE_ALIGNMENT;
				i64 align = type_align_of_internal(field_type, path);
				if (pop) type_path_pop(path);
				if (max < align) {
					max = align;
				}
			}
			if (t->Struct.is_packed) {
				return 1;
			}
			return max;
		}
	} break;

	case Type_BitField: {
		i64 align = 1;
		if (t->BitField.custom_align > 0) {
			align = t->BitField.custom_align;
		}
		return gb_clamp(next_pow2(align), 1, build_context.max_align);
	} break;

	case Type_BitSet: {
		if (t->BitSet.underlying != nullptr) {
			return type_align_of(t->BitSet.underlying);
		}
		i64 bits = t->BitSet.upper - t->BitSet.lower + 1;
		if (bits <= 8)   return 1;
		if (bits <= 16)  return 2;
		if (bits <= 32)  return 4;
		if (bits <= 64)  return 8;
		if (bits <= 128) return 16;
		return 8; // NOTE(bill): Could be an invalid range so limit it for now
	}

	case Type_SimdVector: {
		if (t->SimdVector.is_x86_mmx) {
			return 8;
		}
		// align of
		i64 count = t->SimdVector.count;
		Type *elem = t->SimdVector.elem;
		i64 size = count * type_size_of_internal(elem, path);
		// IMPORTANT TODO(bill): Figure out the alignment of vector types
		return gb_clamp(next_pow2(type_size_of_internal(t, path)), 1, build_context.max_align);
	}

	case Type_RelativePointer:
		return type_align_of_internal(t->RelativePointer.base_integer, path);
	case Type_RelativeSlice:
		return type_align_of_internal(t->RelativeSlice.base_integer, path);
	}

	// return gb_clamp(next_pow2(type_size_of(t)), 1, build_context.max_align);
	// NOTE(bill): Things that are bigger than build_context.word_size, are actually comprised of smaller types
	// TODO(bill): Is this correct for 128-bit types (integers)?
	return gb_clamp(next_pow2(type_size_of_internal(t, path)), 1, build_context.word_size);
}

Array<i64> type_set_offsets_of(Array<Entity *> const &fields, bool is_packed, bool is_raw_union) {
	gbAllocator a = heap_allocator();
	auto offsets = array_make<i64>(a, fields.count);
	i64 curr_offset = 0;
	if (is_raw_union) {
		for_array(i, fields) {
			offsets[i] = 0;
		}
	} else if (is_packed) {
		for_array(i, fields) {
			i64 size = type_size_of(fields[i]->type);
			offsets[i] = curr_offset;
			curr_offset += size;
		}
	} else {
		for_array(i, fields) {
			Type *t = fields[i]->type;
			i64 align = gb_max(type_align_of(t), 1);
			i64 size  = gb_max(type_size_of( t), 0);
			curr_offset = align_formula(curr_offset, align);
			offsets[i] = curr_offset;
			curr_offset += size;
		}
	}
	return offsets;
}

bool type_set_offsets(Type *t) {
	t = base_type(t);
	if (t->kind == Type_Struct) {
		if (!t->Struct.are_offsets_set) {
			t->Struct.are_offsets_being_processed = true;
			t->Struct.offsets = type_set_offsets_of(t->Struct.fields, t->Struct.is_packed, t->Struct.is_raw_union);
			GB_ASSERT(t->Struct.offsets.count == t->Struct.fields.count);
			t->Struct.are_offsets_being_processed = false;
			t->Struct.are_offsets_set = true;
			return true;
		}
	} else if (is_type_tuple(t)) {
		if (!t->Tuple.are_offsets_set) {
			t->Tuple.are_offsets_being_processed = true;
			t->Tuple.offsets = type_set_offsets_of(t->Tuple.variables, t->Tuple.is_packed, false);
			t->Tuple.are_offsets_being_processed = false;
			t->Tuple.are_offsets_set = true;
			return true;
		}
	} else {
		GB_PANIC("Invalid type for setting offsets");
	}
	return false;
}

i64 type_size_of_internal(Type *t, TypePath *path) {
	if (t->failure) {
		return FAILURE_SIZE;
	}

	switch (t->kind) {
	case Type_Named: {
		bool pop = type_path_push(path, t);
		if (path->failure) {
			return FAILURE_ALIGNMENT;
		}
		i64 size = type_size_of_internal(t->Named.base, path);
		if (pop) type_path_pop(path);
		return size;
	} break;

	case Type_Basic: {
		GB_ASSERT_MSG(is_type_typed(t), "%s", type_to_string(t));
		BasicKind kind = t->Basic.kind;
		i64 size = t->Basic.size;
		if (size > 0) {
			return size;
		}
		switch (kind) {
		case Basic_string:  return 2*build_context.word_size;
		case Basic_cstring: return build_context.word_size;
		case Basic_any:     return 2*build_context.word_size;
		case Basic_typeid:  return build_context.word_size;

		case Basic_int: case Basic_uint: case Basic_uintptr: case Basic_rawptr:
			return build_context.word_size;
		}
	} break;

	case Type_Pointer:
		return build_context.word_size;

	case Type_Opaque:
		return type_size_of_internal(t->Opaque.elem, path);

	case Type_Array: {
		i64 count, align, size, alignment;
		count = t->Array.count;
		if (count == 0) {
			return 0;
		}
		align = type_align_of_internal(t->Array.elem, path);
		if (path->failure) {
			return FAILURE_SIZE;
		}
		size  = type_size_of_internal( t->Array.elem, path);
		alignment = align_formula(size, align);
		return alignment*(count-1) + size;
	} break;

	case Type_EnumeratedArray: {
		i64 count, align, size, alignment;
		count = t->EnumeratedArray.count;
		if (count == 0) {
			return 0;
		}
		align = type_align_of_internal(t->EnumeratedArray.elem, path);
		if (path->failure) {
			return FAILURE_SIZE;
		}
		size  = type_size_of_internal( t->EnumeratedArray.elem, path);
		alignment = align_formula(size, align);
		return alignment*(count-1) + size;
	} break;

	case Type_Slice: // ptr + len
		return 2 * build_context.word_size;

	case Type_DynamicArray:
		// data + len + cap + allocator(procedure+data)
		return 3*build_context.word_size + 2*build_context.word_size;

	case Type_Map:
		init_map_internal_types(t);
		return type_size_of_internal(t->Map.internal_type, path);

	case Type_Tuple: {
		i64 count, align, size;
		count = t->Tuple.variables.count;
		if (count == 0) {
			return 0;
		}
		align = type_align_of_internal(t, path);
		type_set_offsets(t);
		size = t->Tuple.offsets[cast(isize)count-1] + type_size_of_internal(t->Tuple.variables[cast(isize)count-1]->type, path);
		return align_formula(size, align);
	} break;

	case Type_Enum:
		return type_size_of_internal(t->Enum.base_type, path);

	case Type_Union: {
		if (t->Union.variants.count == 0) {
			return 0;
		}
		i64 align = type_align_of_internal(t, path);
		if (path->failure) {
			return FAILURE_SIZE;
		}

		i64 max = 0;
		i64 field_size = 0;

		for_array(i, t->Union.variants) {
			Type *variant_type = t->Union.variants[i];
			i64 size = type_size_of_internal(variant_type, path);
			if (max < size) {
				max = size;
			}
		}

		i64 size = 0;

		if (is_type_union_maybe_pointer(t)) {
			size = max;
			t->Union.tag_size = 0;
			t->Union.variant_block_size = size;
		} else {
			// NOTE(bill): Align to tag
			i64 tag_size = union_tag_size(t);
			size = align_formula(max, tag_size);
			// NOTE(bill): Calculate the padding between the common fields and the tag
			t->Union.tag_size = tag_size;
			t->Union.variant_block_size = size - field_size;

			size += tag_size;
		}
		return align_formula(size, align);
	} break;


	case Type_Struct: {
		if (t->Struct.is_raw_union) {
			i64 count = t->Struct.fields.count;
			i64 align = type_align_of_internal(t, path);
			if (path->failure) {
				return FAILURE_SIZE;
			}
			i64 max = 0;
			for (isize i = 0; i < count; i++) {
				i64 size = type_size_of_internal(t->Struct.fields[i]->type, path);
				if (max < size) {
					max = size;
				}
			}
			// TODO(bill): Is this how it should work?
			return align_formula(max, align);
		} else {
			i64 count = 0, size = 0, align = 0;

			count = t->Struct.fields.count;
			if (count == 0) {
				return 0;
			}
			align = type_align_of_internal(t, path);
			if (path->failure) {
				return FAILURE_SIZE;
			}
			if (t->Struct.are_offsets_being_processed && t->Struct.offsets.data == nullptr) {
				type_path_print_illegal_cycle(path, path->path.count-1);
				return FAILURE_SIZE;
			}
			if (t->Struct.are_offsets_set && t->Struct.offsets.count != t->Struct.fields.count) {
				// TODO(bill, 2019-04-28): Determine exactly why the offsets length is different thatn the field length
				// Are the the same at some point and then the struct length is increased?
				// Why is this not handled by the type cycle checker?
				t->Struct.are_offsets_set = false;
			}
			type_set_offsets(t);
			GB_ASSERT_MSG(t->Struct.offsets.count == t->Struct.fields.count, "%s", type_to_string(t));
			size = t->Struct.offsets[cast(isize)count-1] + type_size_of_internal(t->Struct.fields[cast(isize)count-1]->type, path);
			return align_formula(size, align);
		}
	} break;

	case Type_BitField: {
		i64 align = 8*type_align_of_internal(t, path);
		i64 end = 0;
		if (t->BitField.fields.count > 0) {
			i64 last = t->BitField.fields.count-1;
			end = t->BitField.offsets[cast(isize)last] + t->BitField.sizes[cast(isize)last];
		}
		i64 bits = align_formula(end, align);
		GB_ASSERT((bits%8) == 0);
		return bits/8;
	} break;

	case Type_BitSet: {
		if (t->BitSet.underlying != nullptr) {
			return type_size_of(t->BitSet.underlying);
		}
		i64 bits = t->BitSet.upper - t->BitSet.lower + 1;
		if (bits <= 8)   return 1;
		if (bits <= 16)  return 2;
		if (bits <= 32)  return 4;
		if (bits <= 64)  return 8;
		if (bits <= 128) return 16;
		return 8; // NOTE(bill): Could be an invalid range so limit it for now
	}

	case Type_SimdVector: {
		if (t->SimdVector.is_x86_mmx) {
			return 8;
		}
		i64 count = t->SimdVector.count;
		Type *elem = t->SimdVector.elem;
		return count * type_size_of_internal(elem, path);
	}

	case Type_RelativePointer:
		return type_size_of_internal(t->RelativePointer.base_integer, path);
	case Type_RelativeSlice:
		return 2*type_size_of_internal(t->RelativeSlice.base_integer, path);
	}

	// Catch all
	return build_context.word_size;
}

i64 type_offset_of(Type *t, i32 index) {
	t = base_type(t);
	if (t->kind == Type_Struct) {
		type_set_offsets(t);
		if (gb_is_between(index, 0, t->Struct.fields.count-1)) {
			return t->Struct.offsets[index];
		}
	} else if (t->kind == Type_Tuple) {
		type_set_offsets(t);
		if (gb_is_between(index, 0, t->Tuple.variables.count-1)) {
			return t->Tuple.offsets[index];
		}
	}  else if (t->kind == Type_Basic) {
		if (t->Basic.kind == Basic_string) {
			switch (index) {
			case 0: return 0;                       // data
			case 1: return build_context.word_size; // len
			}
		} else if (t->Basic.kind == Basic_any) {
			switch (index) {
			case 0: return 0;                       // type_info
			case 1: return build_context.word_size; // data
			}
		}
	} else if (t->kind == Type_Slice) {
		switch (index) {
		case 0: return 0;                         // data
		case 1: return 1*build_context.word_size; // len
		case 2: return 2*build_context.word_size; // cap
		}
	} else if (t->kind == Type_DynamicArray) {
		switch (index) {
		case 0: return 0;                         // data
		case 1: return 1*build_context.word_size; // len
		case 2: return 2*build_context.word_size; // cap
		case 3: return 3*build_context.word_size; // allocator
		}
	} else if (t->kind == Type_Union) {
		/* i64 s = */ type_size_of(t);
		switch (index) {
		case -1: return align_formula(t->Union.variant_block_size, build_context.word_size); // __type_info
		}
	}
	return 0;
}


i64 type_offset_of_from_selection(Type *type, Selection sel) {
	GB_ASSERT(sel.indirect == false);

	Type *t = type;
	i64 offset = 0;
	for_array(i, sel.index) {
		i32 index = sel.index[i];
		t = base_type(t);
		offset += type_offset_of(t, index);
		if (t->kind == Type_Struct && !t->Struct.is_raw_union) {
			t = t->Struct.fields[index]->type;
		} else {
			// NOTE(bill): No need to worry about custom types, just need the alignment
			switch (t->kind) {
			case Type_Basic:
				if (t->Basic.kind == Basic_string) {
					switch (index) {
					case 0: t = t_rawptr; break;
					case 1: t = t_int;    break;
					}
				} else if (t->Basic.kind == Basic_any) {
					switch (index) {
					case 0: t = t_type_info_ptr; break;
					case 1: t = t_rawptr;        break;
					}
				}
				break;
			case Type_Slice:
				switch (index) {
				case 0: t = t_rawptr; break;
				case 1: t = t_int;    break;
				case 2: t = t_int;    break;
				}
				break;
			case Type_DynamicArray:
				switch (index) {
				case 0: t = t_rawptr;    break;
				case 1: t = t_int;       break;
				case 2: t = t_int;       break;
				case 3: t = t_allocator; break;
				}
				break;
			}
		}
	}
	return offset;
}


Type *get_struct_field_type(Type *t, isize index) {
	t = base_type(type_deref(t));
	GB_ASSERT(t->kind == Type_Struct);
	return t->Struct.fields[index]->type;
}


gbString write_type_to_string(gbString str, Type *type) {
	if (type == nullptr) {
		return gb_string_appendc(str, "<no type>");
	}

	switch (type->kind) {
	case Type_Basic:
		str = gb_string_append_length(str, type->Basic.name.text, type->Basic.name.len);
		break;

	case Type_Generic:
		if (type->Generic.name.len == 0) {
			if (type->Generic.entity != nullptr) {
				String name = type->Generic.entity->token.string;
				str = gb_string_append_rune(str, '$');
				str = gb_string_append_length(str, name.text, name.len);
			} else {
				str = gb_string_appendc(str, "type");
			}
		} else {
			String name = type->Generic.name;
			str = gb_string_append_rune(str, '$');
			str = gb_string_append_length(str, name.text, name.len);
			if (type->Generic.specialized != nullptr) {
				str = gb_string_append_rune(str, '/');
				str = write_type_to_string(str, type->Generic.specialized);
			}
		}
		break;

	case Type_Pointer:
		str = gb_string_append_rune(str, '^');
		str = write_type_to_string(str, type->Pointer.elem);
		break;

	case Type_Opaque:
		str = gb_string_appendc(str, "opaque ");
		str = write_type_to_string(str, type->Opaque.elem);
		break;

	case Type_EnumeratedArray:
		str = gb_string_append_rune(str, '[');
		str = write_type_to_string(str, type->EnumeratedArray.index);
		str = gb_string_append_rune(str, ']');
		str = write_type_to_string(str, type->EnumeratedArray.elem);
		break;

	case Type_Array:
		str = gb_string_appendc(str, gb_bprintf("[%d]", cast(int)type->Array.count));
		str = write_type_to_string(str, type->Array.elem);
		break;

	case Type_Slice:
		str = gb_string_appendc(str, "[]");
		str = write_type_to_string(str, type->Array.elem);
		break;

	case Type_DynamicArray:
		str = gb_string_appendc(str, "[dynamic]");
		str = write_type_to_string(str, type->DynamicArray.elem);
		break;

	case Type_Enum:
		str = gb_string_appendc(str, "enum");
		if (type->Enum.base_type != nullptr) {
			str = gb_string_appendc(str, " ");
			str = write_type_to_string(str, type->Enum.base_type);
		}
		str = gb_string_appendc(str, " {");
		for_array(i, type->Enum.fields) {
			Entity *f = type->Enum.fields[i];
			GB_ASSERT(f->kind == Entity_Constant);
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
			// str = gb_string_appendc(str, " = ");
		}
		str = gb_string_append_rune(str, '}');
		break;

	case Type_Union:
		str = gb_string_appendc(str, "union");
		if (type->Union.no_nil != 0) str = gb_string_appendc(str, " #no_nil");
		if (type->Union.maybe != 0)  str = gb_string_appendc(str, " #maybe");
		if (type->Union.custom_align != 0) str = gb_string_append_fmt(str, " #align %d", cast(int)type->Union.custom_align);
		str = gb_string_appendc(str, " {");
		for_array(i, type->Union.variants) {
			Type *t = type->Union.variants[i];
			if (i > 0) str = gb_string_appendc(str, ", ");
			str = write_type_to_string(str, t);
		}
		str = gb_string_append_rune(str, '}');
		break;

	case Type_Struct: {
		if (type->Struct.soa_kind != StructSoa_None) {
			switch (type->Struct.soa_kind) {
			case StructSoa_Fixed:   str = gb_string_append_fmt(str, "#soa[%d]", cast(int)type->Struct.soa_count); break;
			case StructSoa_Slice:   str = gb_string_appendc(str,    "#soa[]");                                    break;
			case StructSoa_Dynamic: str = gb_string_appendc(str,    "#soa[dynamic]");                             break;
			default: GB_PANIC("Unknown StructSoaKind"); break;
			}
			str = write_type_to_string(str, type->Struct.soa_elem);
			break;
		}

		str = gb_string_appendc(str, "struct");
		if (type->Struct.is_packed)    str = gb_string_appendc(str, " #packed");
		if (type->Struct.is_raw_union) str = gb_string_appendc(str, " #raw_union");
		if (type->Struct.custom_align != 0) str = gb_string_append_fmt(str, " #align %d", cast(int)type->Struct.custom_align);
		str = gb_string_appendc(str, " {");
		for_array(i, type->Struct.fields) {
			Entity *f = type->Struct.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
			str = gb_string_appendc(str, ": ");
			str = write_type_to_string(str, f->type);
		}
		str = gb_string_append_rune(str, '}');
	} break;

	case Type_Map: {
		str = gb_string_appendc(str, "map[");
		str = write_type_to_string(str, type->Map.key);
		str = gb_string_append_rune(str, ']');
		str = write_type_to_string(str, type->Map.value);
	} break;

	case Type_Named:
		if (type->Named.type_name != nullptr) {
			str = gb_string_append_length(str, type->Named.name.text, type->Named.name.len);
		} else {
			// NOTE(bill): Just in case
			str = gb_string_appendc(str, "<named type>");
		}
		break;

	case Type_Tuple:
		if (type->Tuple.variables.count > 0) {
			isize comma_index = 0;
			for_array(i, type->Tuple.variables) {
				Entity *var = type->Tuple.variables[i];
				if (var == nullptr) {
					continue;
				}
				String name = var->token.string;
				if (var->kind == Entity_Constant) {
					str = gb_string_appendc(str, "$");
					str = gb_string_append_length(str, name.text, name.len);
					if (!is_type_untyped(var->type)) {
						str = gb_string_appendc(str, ": ");
						str = write_type_to_string(str, var->type);
						str = gb_string_appendc(str, " = ");
						str = write_exact_value_to_string(str, var->Constant.value);
					} else {
						str = gb_string_appendc(str, "=");
						str = write_exact_value_to_string(str, var->Constant.value);
					}
					continue;
				}

				if (comma_index++ > 0) {
					str = gb_string_appendc(str, ", ");
				}

				if (var->kind == Entity_Variable) {
					if (var->flags&EntityFlag_CVarArg) {
						str = gb_string_appendc(str, "#c_vararg ");
					}
					if (var->flags&EntityFlag_Ellipsis) {
						Type *slice = base_type(var->type);
						str = gb_string_appendc(str, "..");
						GB_ASSERT(var->type->kind == Type_Slice);
						str = write_type_to_string(str, slice->Slice.elem);
					} else {
						str = write_type_to_string(str, var->type);
					}
				} else {
					GB_ASSERT(var->kind == Entity_TypeName);
					if (var->type->kind == Type_Generic) {
						str = gb_string_appendc(str, "typeid/");
						str = write_type_to_string(str, var->type);
					} else {
						if (var->kind == Entity_TypeName) {
							str = gb_string_appendc(str, "$");
							str = gb_string_append_length(str, name.text, name.len);
							str = gb_string_appendc(str, "=");
							str = write_type_to_string(str, var->type);
						} else {
							str = gb_string_appendc(str, "typeid");
						}
					}
				}
			}
		}
		break;

	case Type_Proc:
		str = gb_string_appendc(str, "proc");

		switch (type->Proc.calling_convention) {
		case ProcCC_Odin:
			break;
		case ProcCC_Contextless:
			str = gb_string_appendc(str, " \"contextless\" ");
			break;
		case ProcCC_CDecl:
			str = gb_string_appendc(str, " \"cdecl\" ");
			break;
		case ProcCC_StdCall:
			str = gb_string_appendc(str, " \"stdcall\" ");
			break;
		case ProcCC_FastCall:
			str = gb_string_appendc(str, " \"fastcall\" ");
			break;
		case ProcCC_None:
			str = gb_string_appendc(str, " \"none\" ");
			break;
		case ProcCC_Pure:
			str = gb_string_appendc(str, " \"pure\" ");
			break;
		// case ProcCC_VectorCall:
		// 	str = gb_string_appendc(str, " \"vectorcall\" ");
		// 	break;
		// case ProcCC_ClrCall:
		// 	str = gb_string_appendc(str, " \"clrcall\" ");
		// 	break;
		}
		str = gb_string_appendc(str, "(");
		if (type->Proc.params) {
			str = write_type_to_string(str, type->Proc.params);
		}
		str = gb_string_appendc(str, ")");
		if (type->Proc.results) {
			str = gb_string_appendc(str, " -> ");
			if (type->Proc.results->Tuple.variables.count > 1) {
				str = gb_string_appendc(str, "(");
			}
			str = write_type_to_string(str, type->Proc.results);
			if (type->Proc.results->Tuple.variables.count > 1) {
				str = gb_string_appendc(str, ")");
			}
		}
		break;

	case Type_BitField:
		str = gb_string_appendc(str, "bit_field ");
		if (type->BitField.custom_align != 0) {
			str = gb_string_append_fmt(str, "#align %d ", cast(int)type->BitField.custom_align);
		}
		str = gb_string_append_rune(str, '{');

		for_array(i, type->BitField.fields)	{
			Entity *f = type->BitField.fields[i];
			GB_ASSERT(f->kind == Entity_Variable);
			GB_ASSERT(f->type != nullptr && f->type->kind == Type_BitFieldValue);
			if (i > 0) {
				str = gb_string_appendc(str, ", ");
			}
			str = gb_string_append_length(str, f->token.string.text, f->token.string.len);
			str = gb_string_appendc(str, ": ");
			str = gb_string_append_fmt(str, "%lld", cast(long long)f->type->BitFieldValue.bits);
		}
		str = gb_string_append_rune(str, '}');
		break;

	case Type_BitFieldValue:
		str = gb_string_append_fmt(str, "(bit field value with %d bits)", cast(int)type->BitFieldValue.bits);
		break;

	case Type_BitSet:
		str = gb_string_appendc(str, "bit_set[");
		str = write_type_to_string(str, type->BitSet.elem);
		if (type->BitSet.underlying != nullptr) {
			str = gb_string_appendc(str, "; ");
			str = write_type_to_string(str, type->BitSet.underlying);
		}
		str = gb_string_appendc(str, "]");
		break;

	case Type_SimdVector:
		if (type->SimdVector.is_x86_mmx) {
			return gb_string_appendc(str, "intrinsics.x86_mmx");
		} else {
			str = gb_string_append_fmt(str, "#simd[%d]", cast(int)type->SimdVector.count);
			str = write_type_to_string(str, type->SimdVector.elem);
		}
		break;

	case Type_RelativePointer:
		str = gb_string_append_fmt(str, "#relative(");
		str = write_type_to_string(str, type->RelativePointer.base_integer);
		str = gb_string_append_fmt(str, ") ");
		str = write_type_to_string(str, type->RelativePointer.pointer_type);
		break;
	case Type_RelativeSlice:
		str = gb_string_append_fmt(str, "#relative(");
		str = write_type_to_string(str, type->RelativeSlice.base_integer);
		str = gb_string_append_fmt(str, ") ");
		str = write_type_to_string(str, type->RelativeSlice.slice_type);
		break;
	}

	return str;
}


gbString type_to_string(Type *type) {
	return write_type_to_string(gb_string_make(heap_allocator(), ""), type);
}

