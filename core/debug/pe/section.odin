package debug_pe

// The section header of images and objects
Section_Header32 :: struct #packed {
	name:                    [8]u8, // NUL-padded, or "/<decimal>" or "//<base64>" string table offset in objects
	virtual_size:            u32le,
	virtual_address:         u32le,
	size_of_raw_data:        u32le,
	pointer_to_raw_data:     u32le,
	pointer_to_relocations:  u32le,
	pointer_to_line_numbers: u32le,
	number_of_relocations:   u16le,
	number_of_line_numbers:  u16le,
	characteristics:         IMAGE_SCN_CHARACTERISTICS,
}
#assert(size_of(Section_Header32) == 40)

// A COFF relocation
Reloc :: struct #packed {
	virtual_address:    u32le,
	symbol_table_index: u32le,
	type:               u16le, // IMAGE_REL_* of the machine
}
#assert(size_of(Reloc) == 10)

// The relocation count at which `LNK_NRELOC_OVFL` is set and the first relocation holds the real count
IMAGE_SCN_MAX_RELOC :: 0xFFFF

// The alignment field of the characteristics, log2(alignment)+1
IMAGE_SCN_ALIGN_MASK  :: 0x00F0_0000
IMAGE_SCN_ALIGN_SHIFT :: 20

// The section flags and the `ALIGN_*` values
IMAGE_SCN_CHARACTERISTICS :: enum u32le {
	TYPE_NO_PAD            = 0x00000008, // The section should not be padded to the next boundary. This flag is obsolete and is replaced by IMAGE_SCN_ALIGN_1BYTES. This is valid only for object files.
	CNT_CODE               = 0x00000020, // The section contains executable code.
	CNT_INITIALIZED_DATA   = 0x00000040, // The section contains initialized data.
	CNT_UNINITIALIZED_DATA = 0x00000080, // The section contains uninitialized data.
	LNK_OTHER              = 0x00000100, // Reserved for future use.
	LNK_INFO               = 0x00000200, // The section contains comments or other information. The .drectve section has this type. This is valid for object files only.
	LNK_REMOVE             = 0x00000800, // The section will not become part of the image. This is valid only for object files.
	LNK_COMDAT             = 0x00001000, // The section contains COMDAT data. For more information, see COMDAT Sections (Object Only). This is valid only for object files.
	GPREL                  = 0x00008000, // The section contains data referenced through the global pointer (GP).
	MEM_PURGEABLE          = 0x00020000, // Reserved for future use.
	MEM_16BIT              = 0x00020000, // Reserved for future use.
	MEM_LOCKED             = 0x00040000, // Reserved for future use.
	MEM_PRELOAD            = 0x00080000, // Reserved for future use.
	ALIGN_1BYTES           = 0x00100000, // Align data on a 1-byte boundary. Valid only for object files.
	ALIGN_2BYTES           = 0x00200000, // Align data on a 2-byte boundary. Valid only for object files.
	ALIGN_4BYTES           = 0x00300000, // Align data on a 4-byte boundary. Valid only for object files.
	ALIGN_8BYTES           = 0x00400000, // Align data on an 8-byte boundary. Valid only for object files.
	ALIGN_16BYTES          = 0x00500000, // Align data on a 16-byte boundary. Valid only for object files.
	ALIGN_32BYTES          = 0x00600000, // Align data on a 32-byte boundary. Valid only for object files.
	ALIGN_64BYTES          = 0x00700000, // Align data on a 64-byte boundary. Valid only for object files.
	ALIGN_128BYTES         = 0x00800000, // Align data on a 128-byte boundary. Valid only for object files.
	ALIGN_256BYTES         = 0x00900000, // Align data on a 256-byte boundary. Valid only for object files.
	ALIGN_512BYTES         = 0x00A00000, // Align data on a 512-byte boundary. Valid only for object files.
	ALIGN_1024BYTES        = 0x00B00000, // Align data on a 1024-byte boundary. Valid only for object files.
	ALIGN_2048BYTES        = 0x00C00000, // Align data on a 2048-byte boundary. Valid only for object files.
	ALIGN_4096BYTES        = 0x00D00000, // Align data on a 4096-byte boundary. Valid only for object files.
	ALIGN_8192BYTES        = 0x00E00000, // Align data on an 8192-byte boundary. Valid only for object files.
	LNK_NRELOC_OVFL        = 0x01000000, // The section contains extended relocations.
	MEM_DISCARDABLE        = 0x02000000, // The section can be discarded as needed.
	MEM_NOT_CACHED         = 0x04000000, // The section cannot be cached.
	MEM_NOT_PAGED          = 0x08000000, // The section is not pageable.
	MEM_SHARED             = 0x10000000, // The section can be shared in memory.
	MEM_EXECUTE            = 0x20000000, // The section can be executed as code.
	MEM_READ               = 0x40000000, // The section can be read.
	MEM_WRITE              = 0x80000000, // The section can be written to.
}


// The relocation types, one enum per machine

IMAGE_REL_I386 :: enum u16le {
	ABSOLUTE = 0x0000,
	DIR16    = 0x0001,
	REL16    = 0x0002,
	DIR32    = 0x0006,
	DIR32NB  = 0x0007,
	SEG12    = 0x0009,
	SECTION  = 0x000A,
	SECREL   = 0x000B,
	TOKEN    = 0x000C,
	SECREL7  = 0x000D,
	REL32    = 0x0014,
}

IMAGE_REL_AMD64 :: enum u16le {
	ABSOLUTE = 0x0000,
	ADDR64   = 0x0001,
	ADDR32   = 0x0002,
	ADDR32NB = 0x0003,
	REL32    = 0x0004,
	REL32_1  = 0x0005,
	REL32_2  = 0x0006,
	REL32_3  = 0x0007,
	REL32_4  = 0x0008,
	REL32_5  = 0x0009,
	SECTION  = 0x000A,
	SECREL   = 0x000B,
	SECREL7  = 0x000C,
	TOKEN    = 0x000D,
	SREL32   = 0x000E,
	PAIR     = 0x000F,
	SSPAN32  = 0x0010,
}

// ARM and Thumb (ARMNT)
IMAGE_REL_ARM :: enum u16le {
	ABSOLUTE       = 0x0000,
	ADDR32         = 0x0001,
	ADDR32NB       = 0x0002,
	BRANCH24       = 0x0003,
	BRANCH11       = 0x0004,
	TOKEN          = 0x0005,
	GPREL12        = 0x0006,
	GPREL7         = 0x0007,
	BLX24          = 0x0008,
	BLX11          = 0x0009,
	REL32          = 0x000A,
	SECTION        = 0x000E,
	SECREL         = 0x000F,
	MOV32          = 0x0010,
	THUMB_MOV32    = 0x0011,
	THUMB_BRANCH20 = 0x0012,
	THUMB_BRANCH24 = 0x0014,
	THUMB_BLX23    = 0x0015,
	PAIR           = 0x0016,
}

// ARM64, ARM64EC and ARM64X
IMAGE_REL_ARM64 :: enum u16le {
	ABSOLUTE       = 0x0000,
	ADDR32         = 0x0001,
	ADDR32NB       = 0x0002,
	BRANCH26       = 0x0003,
	PAGEBASE_REL21 = 0x0004,
	REL21          = 0x0005,
	PAGEOFFSET_12A = 0x0006,
	PAGEOFFSET_12L = 0x0007,
	SECREL         = 0x0008,
	SECREL_LOW12A  = 0x0009,
	SECREL_HIGH12A = 0x000A,
	SECREL_LOW12L  = 0x000B,
	TOKEN          = 0x000C,
	SECTION        = 0x000D,
	ADDR64         = 0x000E,
	BRANCH19       = 0x000F,
	BRANCH14       = 0x0010,
	REL32          = 0x0011,
}
