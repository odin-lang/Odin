package debug_pe

Section_Header32 :: struct {
	name:                    [8]u8,
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

Reloc :: struct {
	virtual_address:    u32le,
	symbol_table_index: u32le,
	type:               IMAGE_REL,
}

IMAGE_SCN_CHARACTERISTICS :: enum u32le {
	TYPE_NO_PAD            = 0x00000008, // The section should not be padded to the next boundary. This flag is obsolete and is replaced by IMAGE_SCN_ALIGN_1BYTES. This is valid only for object files. = 0x00000010, // Reserved for future use.
	CNT_CODE               = 0x00000020, // The section contains executable code.
	CNT_INITIALIZED_DATA   = 0x00000040, // The section contains initialized data.
	CNT_UNINITIALIZED_DATA = 0x00000080, // The section contains uninitialized data.
	LNK_OTHER              = 0x00000100, // Reserved for future use.
	LNK_INFO               = 0x00000200, // The section contains comments or other information. The .drectve section has this type. This is valid for object files only. = 0x00000400, // Reserved for future use.
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


IMAGE_REL :: enum u16le {
	I386_ABSOLUTE         = 0x0000,
	I386_DIR16            = 0x0001,
	I386_REL16            = 0x0002,
	I386_DIR32            = 0x0006,
	I386_DIR32NB          = 0x0007,
	I386_SEG12            = 0x0009,
	I386_SECTION          = 0x000A,
	I386_SECREL           = 0x000B,
	I386_TOKEN            = 0x000C,
	I386_SECREL7          = 0x000D,
	I386_REL32            = 0x0014,

	AMD64_ABSOLUTE        = 0x0000,
	AMD64_ADDR64          = 0x0001,
	AMD64_ADDR32          = 0x0002,
	AMD64_ADDR32NB        = 0x0003,
	AMD64_REL32           = 0x0004,
	AMD64_REL32_1         = 0x0005,
	AMD64_REL32_2         = 0x0006,
	AMD64_REL32_3         = 0x0007,
	AMD64_REL32_4         = 0x0008,
	AMD64_REL32_5         = 0x0009,
	AMD64_SECTION         = 0x000A,
	AMD64_SECREL          = 0x000B,
	AMD64_SECREL7         = 0x000C,
	AMD64_TOKEN           = 0x000D,
	AMD64_SREL32          = 0x000E,
	AMD64_PAIR            = 0x000F,
	AMD64_SSPAN32         = 0x0010,

	ARM_ABSOLUTE          = 0x0000,
	ARM_ADDR32            = 0x0001,
	ARM_ADDR32NB          = 0x0002,
	ARM_BRANCH24          = 0x0003,
	ARM_BRANCH11          = 0x0004,
	ARM_SECTION           = 0x000E,
	ARM_SECREL            = 0x000F,
	ARM_MOV32             = 0x0010,

	THUMB_MOV32           = 0x0011,
	THUMB_BRANCH20        = 0x0012,
	THUMB_BRANCH24        = 0x0014,
	THUMB_BLX23           = 0x0015,

	ARM_PAIR              = 0x0016,

	ARM64_ABSOLUTE        = 0x0000,
	ARM64_ADDR32          = 0x0001,
	ARM64_ADDR32NB        = 0x0002,
	ARM64_BRANCH26        = 0x0003,
	ARM64_PAGEBASE_REL21  = 0x0004,
	ARM64_REL21           = 0x0005,
	ARM64_PAGEOFFSET_12A  = 0x0006,
	ARM64_PAGEOFFSET_12L  = 0x0007,
	ARM64_SECREL          = 0x0008,
	ARM64_SECREL_LOW12A   = 0x0009,
	ARM64_SECREL_HIGH12A  = 0x000A,
	ARM64_SECREL_LOW12L   = 0x000B,
	ARM64_TOKEN           = 0x000C,
	ARM64_SECTION         = 0x000D,
	ARM64_ADDR64          = 0x000E,
	ARM64_BRANCH19        = 0x000F,
	ARM64_BRANCH14        = 0x0010,
	ARM64_REL32           = 0x0011,
}

PE_CODE_VIEW_SIGNATURE_RSDS :: u32le(0x5344_5352)