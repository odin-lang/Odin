package debug_pe

COFF_SYMBOL_SIZE     :: 18 // The record size of a regular object
COFF_SYMBOL_EX_SIZE  :: 20 // The record size of a bigobj object
COFF_SYMBOL_NAME_LEN :: 8

// A symbol of a regular object, followed by its aux records
COFF_Symbol :: struct #packed {
	name:                  [COFF_SYMBOL_NAME_LEN]u8, // or 4 zero bytes and a string table offset
	value:                 u32le,
	section_number:        i16le, // 1-based, or an IMAGE_SYM_* value
	type:                  IMAGE_SYM_TYPE,
	storage_class:         IMAGE_SYM_CLASS,
	number_of_aux_symbols: u8,
}
#assert(size_of(COFF_Symbol) == COFF_SYMBOL_SIZE)

// A symbol of a bigobj object, followed by its 20-byte aux records
COFF_Symbol_Ex :: struct #packed {
	name:                  [COFF_SYMBOL_NAME_LEN]u8,
	value:                 u32le,
	section_number:        i32le,
	type:                  IMAGE_SYM_TYPE,
	storage_class:         IMAGE_SYM_CLASS,
	number_of_aux_symbols: u8,
}
#assert(size_of(COFF_Symbol_Ex) == COFF_SYMBOL_EX_SIZE)

// The header of a bigobj object, in place of `File_Header`
Bigobj_Header :: struct #packed {
	sig1:                    u16le, // 0
	sig2:                    u16le, // 0xFFFF
	version:                 u16le, // 2
	machine:                 IMAGE_FILE_MACHINE,
	time_date_stamp:         u32le,
	class_id:                [16]u8, // BIGOBJ_CLASS_ID
	size_of_data:            u32le,
	flags:                   u32le,
	meta_data_size:          u32le,
	meta_data_offset:        u32le,
	number_of_sections:      u32le,
	pointer_to_symbol_table: u32le,
	number_of_symbols:       u32le,
}
#assert(size_of(Bigobj_Header) == 56)

// {D1BAA1C7-BAEE-4ba9-AF20-FAF66AA4DCB8}
BIGOBJ_CLASS_ID :: [16]u8{0xC7, 0xA1, 0xBA, 0xD1, 0xEE, 0xBA, 0xA9, 0x4B, 0xAF, 0x20, 0xFA, 0xF6, 0x6A, 0xA4, 0xDC, 0xB8}

// The header of a short import library member, followed by the import name and the DLL name
Import_Object_Header :: struct #packed {
	sig1:            u16le, // 0
	sig2:            u16le, // 0xFFFF
	version:         u16le, // 0
	machine:         IMAGE_FILE_MACHINE,
	time_date_stamp: u32le,
	size_of_data:    u32le,
	ordinal_or_hint: u16le,
	type_info:       u16le, // bits 0-1: IMPORT_OBJECT_TYPE, bits 2-4: IMPORT_OBJECT_NAME_TYPE
}
#assert(size_of(Import_Object_Header) == 20)

IMPORT_OBJECT_TYPE :: enum u8 {
	CODE  = 0,
	DATA  = 1,
	CONST = 2,
}

IMPORT_OBJECT_NAME_TYPE :: enum u8 {
	ORDINAL         = 0,
	NAME            = 1,
	NAME_NOPREFIX   = 2,
	NAME_UNDECORATE = 3,
	NAME_EXPORTAS   = 4,
}

// Aux format 1: function definition
COFF_Symbol_Aux_Function_Definition :: struct #packed {
	tag_index:                u32le, // symbol index of the .bf record
	total_size:               u32le,
	pointer_to_line_number:   u32le,
	pointer_to_next_function: u32le,
	_:                        [2]u8,
}
#assert(size_of(COFF_Symbol_Aux_Function_Definition) == COFF_SYMBOL_SIZE)

// Aux format 2: .bf and .ef symbols
COFF_Symbol_Aux_Bf_Ef :: struct #packed {
	_:                        [4]u8,
	line_number:              u16le,
	_:                        [6]u8,
	pointer_to_next_function: u32le, // .bf only
	_:                        [2]u8,
}
#assert(size_of(COFF_Symbol_Aux_Bf_Ef) == COFF_SYMBOL_SIZE)

// Aux format 3: weak external
COFF_Symbol_Aux_Weak_External :: struct #packed {
	tag_index:       u32le, // symbol index of the fallback
	characteristics: IMAGE_WEAK_EXTERN,
	_:               [10]u8,
}
#assert(size_of(COFF_Symbol_Aux_Weak_External) == COFF_SYMBOL_SIZE)

IMAGE_WEAK_EXTERN :: enum u32le {
	SEARCH_NOLIBRARY = 1,
	SEARCH_LIBRARY   = 2,
	SEARCH_ALIAS     = 3,
	ANTI_DEPENDENCY  = 4,
}

// Aux format 4: file name, spanning all aux records of the .file symbol (20 bytes each in bigobj)
COFF_Symbol_Aux_File :: struct #packed {
	file_name: [COFF_SYMBOL_SIZE]u8,
}
#assert(size_of(COFF_Symbol_Aux_File) == COFF_SYMBOL_SIZE)

// Aux format 5: section definition
// https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#auxiliary-format-5-section-definitions
COFF_Symbol_Aux_Format5 :: struct #packed {
	size:             u32le,
	num_relocs:       u16le,
	num_line_numbers: u16le,
	checksum:         u32le,
	sec_num:          u16le, // 1-based section of an ASSOCIATIVE COMDAT
	selection:        IMAGE_COMDAT_SELECT,
	_:                u8,
	sec_num_high:     u16le, // high 16 bits of `sec_num` in bigobj objects
}
#assert(size_of(COFF_Symbol_Aux_Format5) == COFF_SYMBOL_SIZE)

COFF_Symbol_Aux_Section_Definition :: COFF_Symbol_Aux_Format5

// Aux format of a CLR_TOKEN symbol
COFF_Symbol_Aux_CLR_Token :: struct #packed {
	aux_type:           u8, // 1 (TOKEN_DEF)
	_:                  u8,
	symbol_table_index: u32le,
	_:                  [12]u8,
}
#assert(size_of(COFF_Symbol_Aux_CLR_Token) == COFF_SYMBOL_SIZE)

IMAGE_COMDAT_SELECT :: enum u8 {
	NODUPLICATES = 1,
	ANY          = 2,
	SAME_SIZE    = 3,
	EXACT_MATCH  = 4,
	ASSOCIATIVE  = 5,
	LARGEST      = 6,
}


// Special section numbers

// The symbol record is not yet assigned a section. A value of zero indicates
// that a reference to an external symbol is defined elsewhere. A value of
// non-zero is a common symbol with a size that is specified by the value.
IMAGE_SYM_UNDEFINED              :: 0
// The symbol has an absolute (non-relocatable) value and is not an address.
IMAGE_SYM_ABSOLUTE               :: -1
// The symbol provides general type or debugging information but does not
// correspond to a section. Microsoft tools use this setting along
// with .file records (storage class FILE).
IMAGE_SYM_DEBUG                  :: -2
// The highest section number of a regular object
IMAGE_SYM_SECTION_MAX            :: 0xFEFF
// The highest section number of a bigobj object
IMAGE_SYM_SECTION_MAX_BIGOBJ     :: 0x7FFFFFFF

// The base type (bits 0-3) and the DTYPE_* derived type (bits 4-5) of a symbol
IMAGE_SYM_TYPE :: enum u16le {
	NULL   = 0,
	VOID   = 1,
	CHAR   = 2,
	SHORT  = 3,
	INT    = 4,
	LONG   = 5,
	FLOAT  = 6,
	DOUBLE = 7,
	STRUCT = 8,
	UNION  = 9,
	ENUM   = 10,
	MOE    = 11,
	BYTE   = 12,
	WORD   = 13,
	UINT   = 14,
	DWORD  = 15,
	PCODE  = 32768,

	DTYPE_NULL     = 0,
	DTYPE_POINTER  = 0x10,
	DTYPE_FUNCTION = 0x20,
	DTYPE_ARRAY    = 0x30,
}

IMAGE_SYM_TYPE_BASE_MASK    :: 0x000F
IMAGE_SYM_TYPE_DERIVED_MASK :: 0x0030

IMAGE_SYM_CLASS :: enum u8 {
	NULL             = 0,
	AUTOMATIC        = 1,
	EXTERNAL         = 2,
	STATIC           = 3,
	REGISTER         = 4,
	EXTERNAL_DEF     = 5,
	LABEL            = 6,
	UNDEFINED_LABEL  = 7,
	MEMBER_OF_STRUCT = 8,
	ARGUMENT         = 9,
	STRUCT_TAG       = 10,
	MEMBER_OF_UNION  = 11,
	UNION_TAG        = 12,
	TYPE_DEFINITION  = 13,
	UNDEFINED_STATIC = 14,
	ENUM_TAG         = 15,
	MEMBER_OF_ENUM   = 16,
	REGISTER_PARAM   = 17,
	BIT_FIELD        = 18,
	FAR_EXTERNAL     = 68, // Not in PECOFF v8 spec
	BLOCK            = 100,
	FUNCTION         = 101,
	END_OF_STRUCT    = 102,
	FILE             = 103,
	SECTION          = 104,
	WEAK_EXTERNAL    = 105,
	CLR_TOKEN        = 107,

	END_OF_FUNCTION  = 255,
}
