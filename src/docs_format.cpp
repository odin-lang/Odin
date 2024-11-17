#define OdinDocHeader_MagicString "odindoc\0"

template <typename T>
struct OdinDocArray {
	u32 offset;
	u32 length;
};

using OdinDocString = OdinDocArray<u8>;

struct OdinDocVersionType {
	u8 major, minor, patch;
	u8 pad0;
};

#define OdinDocVersionType_Major 0
#define OdinDocVersionType_Minor 3
#define OdinDocVersionType_Patch 1

struct OdinDocHeaderBase {
	u8                 magic[8];
	u32                padding0;
	OdinDocVersionType version;
	u32                total_size;
	u32                header_size;
	u32                hash; // after header
};

template <typename T>
gb_internal Slice<T> from_array(OdinDocHeaderBase *base, OdinDocArray<T> const &a) {
	Slice<T> s = {};
	s.data  = cast(T *)(cast(uintptr)base + cast(uintptr)a.offset);
	s.count = cast(isize)a.length;
	return s;
}

gb_internal String from_string(OdinDocHeaderBase *base, OdinDocString const &s) {
	String str = {};
	str.text = cast(u8 *)(cast(uintptr)base + cast(uintptr)s.offset);
	str.len  = cast(isize)s.length;
	return str;
}

typedef u32 OdinDocFileIndex;
typedef u32 OdinDocPkgIndex;
typedef u32 OdinDocEntityIndex;
typedef u32 OdinDocTypeIndex;

struct OdinDocFile {
	OdinDocPkgIndex pkg;
	OdinDocString   name;
};

struct OdinDocPosition {
	OdinDocFileIndex file;
	u32              line;
	u32              column;
	u32              offset;
};

enum OdinDocTypeKind : u32 {
	OdinDocType_Invalid              = 0,
	OdinDocType_Basic                = 1,
	OdinDocType_Named                = 2,
	OdinDocType_Generic              = 3,
	OdinDocType_Pointer              = 4,
	OdinDocType_Array                = 5,
	OdinDocType_EnumeratedArray      = 6,
	OdinDocType_Slice                = 7,
	OdinDocType_DynamicArray         = 8,
	OdinDocType_Map                  = 9,
	OdinDocType_Struct               = 10,
	OdinDocType_Union                = 11,
	OdinDocType_Enum                 = 12,
	OdinDocType_Tuple                = 13,
	OdinDocType_Proc                 = 14,
	OdinDocType_BitSet               = 15,
	OdinDocType_SimdVector           = 16,
	OdinDocType_SOAStructFixed       = 17,
	OdinDocType_SOAStructSlice       = 18,
	OdinDocType_SOAStructDynamic     = 19,

	OdinDocType_MultiPointer         = 22,
	OdinDocType_Matrix               = 23,
	OdinDocType_SoaPointer           = 24,
	OdinDocType_BitField             = 25,
};

enum OdinDocTypeFlag_Basic : u32 {
	OdinDocTypeFlag_Basic_untyped = 1<<1,
};

enum OdinDocTypeFlag_Struct : u32 {
	OdinDocTypeFlag_Struct_polymorphic = 1<<0,
	OdinDocTypeFlag_Struct_packed      = 1<<1,
	OdinDocTypeFlag_Struct_raw_union   = 1<<2,
};

enum OdinDocTypeFlag_Union : u32 {
	OdinDocTypeFlag_Union_polymorphic = 1<<0,
	OdinDocTypeFlag_Union_no_nil      = 1<<1,
	OdinDocTypeFlag_Union_shared_nil  = 1<<3,
};

enum OdinDocTypeFlag_Proc : u32 {
	OdinDocTypeFlag_Proc_polymorphic = 1<<0,
	OdinDocTypeFlag_Proc_diverging   = 1<<1,
	OdinDocTypeFlag_Proc_optional_ok = 1<<2,
	OdinDocTypeFlag_Proc_variadic    = 1<<3,
	OdinDocTypeFlag_Proc_c_vararg    = 1<<4,
};

enum OdinDocTypeFlag_BitSet : u32 {
	OdinDocTypeFlag_BitSet_Range          = 1<<1,
	OdinDocTypeFlag_BitSet_OpLt           = 1<<2,
	OdinDocTypeFlag_BitSet_OpLtEq         = 1<<3,
	OdinDocTypeFlag_BitSet_UnderlyingType = 1<<4,
};

enum {
	// constants
	OdinDocType_ElemsCap = 4,
};

struct OdinDocType {
	OdinDocTypeKind kind;
	u32             flags;
	OdinDocString   name;
	OdinDocString   custom_align;

	// Used by some types
	u32 elem_count_len;
	i64 elem_counts[OdinDocType_ElemsCap];

	// Each of these is esed by some types, not all
	OdinDocString calling_convention;
	OdinDocArray<OdinDocTypeIndex> types;
	OdinDocArray<OdinDocEntityIndex> entities;
	OdinDocTypeIndex polmorphic_params;
	OdinDocArray<OdinDocString> where_clauses;
	OdinDocArray<OdinDocString> tags; // struct field tags
};

struct OdinDocAttribute {
	OdinDocString name;
	OdinDocString value;
};

enum OdinDocEntityKind : u32 {
	OdinDocEntity_Invalid     = 0,
	OdinDocEntity_Constant    = 1,
	OdinDocEntity_Variable    = 2,
	OdinDocEntity_TypeName    = 3,
	OdinDocEntity_Procedure   = 4,
	OdinDocEntity_ProcGroup   = 5,
	OdinDocEntity_ImportName  = 6,
	OdinDocEntity_LibraryName = 7,
	OdinDocEntity_Builtin     = 8,
};

enum OdinDocEntityFlag : u64 {
	OdinDocEntityFlag_Foreign = 1ull<<0,
	OdinDocEntityFlag_Export  = 1ull<<1,

	OdinDocEntityFlag_Param_Using       = 1ull<<2,
	OdinDocEntityFlag_Param_Const       = 1ull<<3,
	OdinDocEntityFlag_Param_AutoCast    = 1ull<<4,
	OdinDocEntityFlag_Param_Ellipsis    = 1ull<<5,
	OdinDocEntityFlag_Param_CVararg     = 1ull<<6,
	OdinDocEntityFlag_Param_NoAlias     = 1ull<<7,
	OdinDocEntityFlag_Param_AnyInt      = 1ull<<8,
	OdinDocEntityFlag_Param_ByPtr       = 1ull<<9,
	OdinDocEntityFlag_Param_NoBroadcast = 1ull<<10,

	OdinDocEntityFlag_BitField_Field = 1ull<<19,

	OdinDocEntityFlag_Type_Alias = 1ull<<20,

	OdinDocEntityFlag_Builtin_Pkg_Builtin    = 1ull<<30,
	OdinDocEntityFlag_Builtin_Pkg_Intrinsics = 1ull<<31,

	OdinDocEntityFlag_Var_Thread_Local = 1ull<<40,
	OdinDocEntityFlag_Var_Static       = 1ull<<41,

	OdinDocEntityFlag_Private          = 1ull<<50,
};

struct OdinDocEntity {
	OdinDocEntityKind  kind;
	u32                reserved;
	u64                flags;
	OdinDocPosition    pos;
	OdinDocString      name;
	OdinDocTypeIndex   type;
	OdinDocString      init_string;
	u32                reserved_for_init;
	OdinDocString      comment; // line comment
	OdinDocString      docs; // preceding comment
	i32                field_group_index; // For `bit_field`s this is the "bit_size"
	OdinDocEntityIndex foreign_library;
	OdinDocString      link_name;
	OdinDocArray<OdinDocAttribute> attributes;
	OdinDocArray<OdinDocEntityIndex> grouped_entities; // Procedure Groups
	OdinDocArray<OdinDocString>      where_clauses; // Procedures
};

enum OdinDocPkgFlags : u32 {
	OdinDocPkgFlag_Builtin = 1<<0,
	OdinDocPkgFlag_Runtime = 1<<1,
	OdinDocPkgFlag_Init    = 1<<2,
};

struct OdinDocScopeEntry {
	OdinDocString      name;
	OdinDocEntityIndex entity;
};

struct OdinDocPkg {
	OdinDocString fullpath;
	OdinDocString name;
	u32           flags;
	OdinDocString docs;
	OdinDocArray<OdinDocFileIndex>  files;
	OdinDocArray<OdinDocScopeEntry> entries;
};


struct OdinDocHeader {
	OdinDocHeaderBase base;

	OdinDocArray<OdinDocFile>   files;
	OdinDocArray<OdinDocPkg>    pkgs;
	OdinDocArray<OdinDocEntity> entities;
	OdinDocArray<OdinDocType>   types;
};

