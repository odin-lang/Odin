package odin_doc_format

import "core:mem"

Array :: struct($T: typeid) {
	offset: u32le,
	length: u32le,
}

String :: distinct Array(byte);

Version_Type_Major :: 0;
Version_Type_Minor :: 1;
Version_Type_Patch :: 0;

Version_Type :: struct {
	major, minor, patch: u8,
	_: u8,
};

Version_Type_Default :: Version_Type{
	major=Version_Type_Major,
	minor=Version_Type_Minor,
	patch=Version_Type_Patch,
};

Magic_String :: "odindoc\x00";

Header_Base :: struct {
	magic: [8]byte,
	_: u32le,
	version:     Version_Type,
	total_size:  u32le,
	header_size: u32le,
	hash:        u32le,
}

Header :: struct {
	using base: Header_Base,

	// NOTE: These arrays reserve the zero element as a sentinel value
	files:    Array(File),
	pkgs:     Array(Pkg),
	entities: Array(Entity),
	types:    Array(Type),
}

File_Index   :: distinct u32le;
Pkg_Index    :: distinct u32le;
Entity_Index :: distinct u32le;
Type_Index   :: distinct u32le;


Position :: struct {
	file:   File_Index,
	line:   u32le,
	column: u32le,
	offset: u32le,
};

File :: struct {
	pkg:  Pkg_Index,
	name: String,
}

Pkg_Flag :: enum u32le {
	Builtin = 0,
	Runtime = 1,
	Init    = 2,
}

Pkg_Flags :: distinct bit_set[Pkg_Flag; u32le];

Pkg :: struct {
	fullpath: String,
	name:     String,
	flags:    Pkg_Flags,
	docs:     String,
	files:    Array(File_Index),
	entities: Array(Entity_Index),
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
}

Entity_Flag :: enum u32le {
	Foreign = 0,
	Export  = 1,

	Param_Using     = 2,
	Param_Const     = 3,
	Param_Auto_Cast = 4,
	Param_Ellipsis  = 5,
	Param_CVararg   = 6,
	Param_No_Alias  = 7,

	Type_Alias = 8,

	Var_Thread_Local = 9,
}

Entity_Flags :: distinct bit_set[Entity_Flag; u32le];

Entity :: struct {
	kind:             Entity_Kind,
	flags:            Entity_Flags,
	pos:              Position,
	name:             String,
	type:             Type_Index,
	init_string:      String,
	_:                u32le,
	comment:          String,
	docs:             String,
	foreign_library:  Entity_Index,
	link_name:        String,
	attributes:       Array(Attribute),
	grouped_entities: Array(Entity_Index), // Procedure Groups
	where_clauses:    Array(String), // Procedures
}

Attribute :: struct {
	name:  String,
	value: String,
}

Type_Kind :: enum u32le {
	Invalid            = 0,
	Basic              = 1,
	Named              = 2,
	Generic            = 3,
	Pointer            = 4,
	Array              = 5,
	Enumerated_Array   = 6,
	Slice              = 7,
	Dynamic_Array      = 8,
	Map                = 9,
	Struct             = 10,
	Union              = 11,
	Enum               = 12,
	Tuple              = 13,
	Proc               = 14,
	Bit_Set            = 15,
	Simd_Vector        = 16,
	SOA_Struct_Fixed   = 17,
	SOA_Struct_Slice   = 18,
	SOA_Struct_Dynamic = 19,
	Relative_Pointer   = 20,
	Relative_Slice     = 21,
}

Type_Elems_Cap :: 4;

Type :: struct {
	kind:         Type_Kind,
	flags:        u32le, // Type_Kind specific
	name:         String,
	custom_align: String,

	// Used by some types
	elem_count_len: u32le,
	elem_counts:    [Type_Elems_Cap]i64le,

	// Each of these is esed by some types, not all
	calling_convention: String, // Procedures
	types:              Array(Type_Index),
	entities:           Array(Entity_Index),
	polymorphic_params: Type_Index, // Struct, Union
	where_clauses:      Array(String), // Struct, Union
}

Type_Flags_Basic :: distinct bit_set[Type_Flag_Basic; u32le];
Type_Flag_Basic :: enum u32le {
	Untyped = 1,
}

Type_Flags_Struct :: distinct bit_set[Type_Flag_Struct; u32le];
Type_Flag_Struct :: enum u32le {
	Polymorphic = 0,
	Packed      = 1,
	Raw_Union   = 2,
}

Type_Flags_Union :: distinct bit_set[Type_Flag_Union; u32le];
Type_Flag_Union :: enum u32le {
	Polymorphic = 0,
	No_Nil      = 1,
	Maybe       = 2,
}

Type_Flags_Proc :: distinct bit_set[Type_Flag_Proc; u32le];
Type_Flag_Proc :: enum u32le {
	Polymorphic = 0,
	Diverging   = 1,
	Optional_Ok = 2,
	Variadic    = 3,
	C_Vararg    = 4,
}

Type_Flags_Bit_Set :: distinct bit_set[Type_Flag_Bit_Set; u32le];
Type_Flag_Bit_Set :: enum u32le {
	Range            = 1,
	Op_Lt            = 2,
	Op_Lt_Eq         = 3,
	Underlying_Type  = 4,
}

from_array :: proc(base: ^Header_Base, a: $A/Array($T)) -> []T {
	s: mem.Raw_Slice;
	s.data = rawptr(uintptr(base) + uintptr(a.offset));
	s.len = int(a.length);
	return transmute([]T)s;
}
from_string :: proc(base: ^Header_Base, s: String) -> string {
	return string(from_array(base, s));
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
		err = .Header_Too_Small;
		return;
	}
	header_base := (^Header_Base)(raw_data(data));
	if header_base.magic != Magic_String {
		err = .Invalid_Magic;
		return;
	}
	if len(data) < int(header_base.total_size) {
		err = .Data_Too_Small;
		return;
	}
	if header_base.version != Version_Type_Default {
		err = .Invalid_Version;
		return;
	}
	h = (^Header)(header_base);
	return;
}
