package debug_pe

COFF_SYMBOL_SIZE :: 18

COFF_Symbol :: struct {
	name:                  [8]u8,
	value:                 u32le,
	section_number:        i16le,
	type:                  IMAGE_SYM_TYPE,
	storage_class:         IMAGE_SYM_CLASS,
	number_of_aux_symbols: u8,
}

// COFF_Symbol_Aux_Format5 describes the expected form of an aux symbol
// attached to a section definition symbol. The PE format defines a
// number of different aux symbol formats: format 1 for function
// definitions, format 2 for .be and .ef symbols, and so on. Format 5
// holds extra info associated with a section definition, including
// number of relocations + line numbers, as well as COMDAT info. See
// https://docs.microsoft.com/en-us/windows/win32/debug/pe-format#auxiliary-format-5-section-definitions
// for more on what's going on here.
COFF_Symbol_Aux_Format5 :: struct {
	size:             u32le,
	num_relocs:       u16le,
	num_line_numbers: u16le,
	checksum:         u32le,
	sec_num:          u16le,
	selection:        IMAGE_COMDAT_SELECT,
	_:                [3]u8, // padding
}

IMAGE_COMDAT_SELECT :: enum u8 {
	NODUPLICATES = 1,
	ANY          = 2,
	SAME_SIZE    = 3,
	EXACT_MATCH  = 4,
	ASSOCIATIVE  = 5,
	LARGEST      = 6,
}


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
