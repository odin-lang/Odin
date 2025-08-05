package odin_doc_format

import "core:mem"

Array :: struct($T: typeid) {
	offset: u32le,
	length: u32le,
}

String :: distinct Array(byte)

Version_Type_Major :: 0
Version_Type_Minor :: 3
Version_Type_Patch :: 1

Version_Type :: struct {
	major, minor, patch: u8,
	_: u8,
}

Version_Type_Default :: Version_Type{
	major=Version_Type_Major,
	minor=Version_Type_Minor,
	patch=Version_Type_Patch,
}

Magic_String :: "odindoc\x00"

Header_Base :: struct {
	magic: [8]byte,
	_: u32le, // padding
	version:     Version_Type,
	total_size:  u32le, // in bytes
	header_size: u32le, // in bytes
	hash:        u32le, // hash of the data after the header (header_size)
}

Header :: struct {
	using base: Header_Base,

	// NOTE: These arrays reserve the zero element as a sentinel value
	files:    Array(File),
	pkgs:     Array(Pkg),
	entities: Array(Entity),
	types:    Array(Type),
}

File_Index   :: distinct u32le
Pkg_Index    :: distinct u32le
Entity_Index :: distinct u32le
Type_Index   :: distinct u32le


Position :: struct {
	file:   File_Index,
	line:   u32le,
	column: u32le,
	offset: u32le,
}

File :: struct {
	pkg:  Pkg_Index,
	name: String,
}

Pkg_Flag :: enum u32le {
	Builtin = 0,
	Runtime = 1,
	Init    = 2,
}

Pkg_Flags :: distinct bit_set[Pkg_Flag; u32le]

Pkg :: struct {
	fullpath: String,
	name:     String,
	flags:    Pkg_Flags,
	docs:     String,
	files:    Array(File_Index),
	entries:  Array(Scope_Entry),
}

Scope_Entry :: struct {
	name:   String,
	entity: Entity_Index,
}


Entity_Kind :: enum u32le {
	Invalid      = 0,
	Constant     = 1,
	Variable     = 2,
	Type_Name    = 3,
	Procedure    = 4,
	Proc_Group   = 5,
	Import_Name  = 6,
	Library_Name = 7,
	Builtin      = 8,
}

Entity_Flag :: enum u32le {
	Foreign = 0,
	Export  = 1,

	Param_Using        = 2, // using
	Param_Const        = 3, // #const
	Param_Auto_Cast    = 4, // auto_cast
	Param_Ellipsis     = 5, // Variadic parameter
	Param_CVararg      = 6, // #c_vararg
	Param_No_Alias     = 7, // #no_alias
	Param_Any_Int      = 8, // #any_int
	Param_By_Ptr       = 9, // #by_ptr
	Param_No_Broadcast = 10, // #no_broadcast

	Bit_Field_Field = 19,

	Type_Alias = 20,

	Builtin_Pkg_Builtin    = 30,
	Builtin_Pkg_Intrinsics = 31,

	Var_Thread_Local = 40,
	Var_Static       = 41,

	Private = 50,
}

Entity_Flags :: distinct bit_set[Entity_Flag; u64le]

Entity :: struct {
	kind:             Entity_Kind,
	_:                u32le, // reserved
	flags:            Entity_Flags,
	pos:              Position,
	name:             String,
	type:             Type_Index,
	init_string:      String,
	_:                u32le, // reserved for init
	comment:          String,
	docs:             String,
	// May be used by (Struct fields and procedure fields):
	// .Variable
	// .Constant
	// This is equal to the negative of the "bit size" it this is a `bit_field`s field
	field_group_index: i32le,

	// May used by:
	// .Variable
	// .Procedure
	foreign_library:  Entity_Index,
	// May used by:
	// .Variable
	// .Procedure
	link_name:        String,

	attributes:       Array(Attribute),

	// Used by: .Proc_Group
	grouped_entities: Array(Entity_Index),
	// May used by: .Procedure
	where_clauses:    Array(String),
}

Attribute :: struct {
	name:  String,
	value: String,
}

Type_Kind :: enum u32le {
	Invalid                = 0,
	Basic                  = 1,
	Named                  = 2,
	Generic                = 3,
	Pointer                = 4,
	Array                  = 5,
	Enumerated_Array       = 6,
	Slice                  = 7,
	Dynamic_Array          = 8,
	Map                    = 9,
	Struct                 = 10,
	Union                  = 11,
	Enum                   = 12,
	Parameters             = 13,
	Proc                   = 14,
	Bit_Set                = 15,
	Simd_Vector            = 16,
	SOA_Struct_Fixed       = 17,
	SOA_Struct_Slice       = 18,
	SOA_Struct_Dynamic     = 19,
	Relative_Pointer       = 20,
	Relative_Multi_Pointer = 21,
	Multi_Pointer          = 22,
	Matrix                 = 23,
	Soa_Pointer            = 24,
	Bit_Field              = 25,
}

Type_Elems_Cap :: 4

Type :: struct {
	kind:  Type_Kind,
	// Type_Kind specific used by some types
	// Underlying flag types:
	// .Basic   - Type_Flags_Basic
	// .Struct  - Type_Flags_Struct
	// .Union   - Type_Flags_Union
	// .Proc    - Type_Flags_Proc
	// .Bit_Set - Type_Flags_Bit_Set
	flags: u32le,

	// Used by:
	// .Basic
	// .Named
	// .Generic
	name: String,

	// Used By: .Struct, .Union
	custom_align: String,

	// Used by:
	// .Array            - 1 count: 0=len
	// .Enumerated_Array - 1 count: 0=len
	// .SOA_Struct_Fixed - 1 count: 0=len
	// .Bit_Set          - 2 count: 0=lower, 1=upper
	// .Simd_Vector      - 1 count: 0=len
	// .Matrix           - 2 count: 0=row_count, 1=column_count
	elem_count_len: u32le,
	elem_counts:    [Type_Elems_Cap]i64le,

	// Used by: .Procedures
	// blank implies the "odin" calling convention
	calling_convention: String,

	// Used by:
	// .Named              - 1 type:    0=base type
	// .Generic            - <1 type:   0=specialization
	// .Pointer            - 1 type:    0=element
	// .Array              - 1 type:    0=element
	// .Enumerated_Array   - 2 types:   0=index and 1=element
	// .Slice              - 1 type:    0=element
	// .Dynamic_Array      - 1 type:    0=element
	// .Map                - 2 types:   0=key, 1=value
	// .SOA_Struct_Fixed   - 1 type:    underlying SOA struct element
	// .SOA_Struct_Slice   - 1 type:    underlying SOA struct element
	// .SOA_Struct_Dynamic - 1 type:    underlying SOA struct element
	// .Union              - 0+ types:  variants
	// .Enum               - <1 type:   0=base type
	// .Proc               - 2 types:   0=parameters, 1=results
	// .Bit_Set            - <=2 types: 0=element type, 1=underlying type (Underlying_Type flag will be set)
	// .Simd_Vector        - 1 type:    0=element
	// .Relative_Pointer   - 2 types:   0=pointer type, 1=base integer
	// .Multi_Pointer      - 1 type:    0=element
	// .Matrix             - 1 type:    0=element
	// .Soa_Pointer        - 1 type:    0=element
	// .Bit_Field          - 1 type:    0=backing type
	types: Array(Type_Index),

	// Used by:
	// .Named       - 1 field for the definition
	// .Struct      - fields
	// .Enum        - fields
	// .Parameters  - parameters (procedures only)
	entities: Array(Entity_Index),

	// Used By: .Struct, .Union
	polymorphic_params: Type_Index,
	// Used By: .Struct, .Union
	where_clauses: Array(String),
	// Used By: .Struct
	tags: Array(String),
}

Type_Flags_Basic :: distinct bit_set[Type_Flag_Basic; u32le]
Type_Flag_Basic :: enum u32le {
	Untyped = 1,
}

Type_Flags_Struct :: distinct bit_set[Type_Flag_Struct; u32le]
Type_Flag_Struct :: enum u32le {
	Polymorphic = 0,
	Packed      = 1,
	Raw_Union   = 2,
}

Type_Flags_Union :: distinct bit_set[Type_Flag_Union; u32le]
Type_Flag_Union :: enum u32le {
	Polymorphic = 0,
	No_Nil      = 1,
	Maybe       = 2,
}

Type_Flags_Proc :: distinct bit_set[Type_Flag_Proc; u32le]
Type_Flag_Proc :: enum u32le {
	Polymorphic = 0,
	Diverging   = 1,
	Optional_Ok = 2,
	Variadic    = 3,
	C_Vararg    = 4,
}

Type_Flags_Bit_Set :: distinct bit_set[Type_Flag_Bit_Set; u32le]
Type_Flag_Bit_Set :: enum u32le {
	Range            = 1,
	Op_Lt            = 2,
	Op_Lt_Eq         = 3,
	Underlying_Type  = 4,
}

from_array :: proc(base: ^Header_Base, a: $A/Array($T)) -> []T {
	s: mem.Raw_Slice
	s.data = rawptr(uintptr(base) + uintptr(a.offset))
	s.len = int(a.length)
	return transmute([]T)s
}
from_string :: proc(base: ^Header_Base, s: String) -> string {
	return string(from_array(base, s))
}




Reader_Error :: enum {
	None,
	Header_Too_Small,
	Invalid_Magic,
	Data_Too_Small,
	Invalid_Version,
}

read_from_bytes :: proc(data: []byte) -> (h: ^Header, err: Reader_Error) {
	if len(data) < size_of(Header_Base) {
		err = .Header_Too_Small
		return
	}
	header_base := (^Header_Base)(raw_data(data))
	if header_base.magic != Magic_String {
		err = .Invalid_Magic
		return
	}
	if len(data) < int(header_base.total_size) {
		err = .Data_Too_Small
		return
	}
	if header_base.version != Version_Type_Default {
		err = .Invalid_Version
		return
	}
	h = (^Header)(header_base)
	return
}
