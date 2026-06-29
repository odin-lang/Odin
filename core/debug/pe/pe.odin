// A reader for the Windows `PE` executable format for debug purposes.
package debug_pe

PE_SIGNATURE_OFFSET_INDEX_POS :: 0x3c
PE_SIGNATURE :: u32le(0x0000_4550) // "PE\x00\x00"
PE_SIGNATURE_STRING :: "PE\x00\x00"

OPTIONAL_HEADER_MAGIC :: enum u16le {
	PE32      = 0x010b,
	PE32_PLUS = 0x020b,
}

Optional_Header_Base :: struct #packed {
	magic:                          OPTIONAL_HEADER_MAGIC,
	major_linker_version:           u8,
	minor_linker_version:           u8,
	size_of_code:                   u32le,
	size_of_initialized_data:       u32le,
	size_of_uninitialized_data:     u32le,
	address_of_entry_point:         u32le,
	base_of_code:                   u32le,
}

File_Header :: struct #packed {
	machine:                 IMAGE_FILE_MACHINE,
	number_of_sections:      u16le,
	time_date_stamp:         u32le,
	pointer_to_symbol_table: u32le,
	number_of_symbols:       u32le,
	size_of_optional_header: u16le,
	characteristics:         IMAGE_FILE_CHARACTERISTICS,
}

Data_Directory :: struct #packed {
	virtual_address: u32le,
	size:            u32le,
}

Optional_Header32 :: struct #packed {
	using base: Optional_Header_Base,
	base_of_data:                   u32le,
	image_base:                     u32le,
	section_alignment:              u32le,
	file_alignment:                 u32le,
	major_operating_system_version: u16le,
	minor_operating_system_version: u16le,
	major_image_version:            u16le,
	minor_image_version:            u16le,
	major_subsystem_version:        u16le,
	minor_subsystem_version:        u16le,
	win32_version_value:            u32le,
	size_of_image:                  u32le,
	size_of_headers:                u32le,
	check_sum:                      u32le,
	subsystem:                      IMAGE_SUBSYSTEM,
	dll_characteristics:            IMAGE_DLLCHARACTERISTICS,
	size_of_stack_reserve:          u32le,
	size_of_stack_commit:           u32le,
	size_of_heap_reserve:           u32le,
	size_of_heap_commit:            u32le,
	loader_flags:                   u32le,
	number_of_rva_and_sizes:        u32le,
	data_directory:                 [16]Data_Directory,
}

Optional_Header64 :: struct #packed {
	using base: Optional_Header_Base,
	image_base:                     u64le,
	section_alignment:              u32le,
	file_alignment:                 u32le,
	major_operating_system_version: u16le,
	minor_operating_system_version: u16le,
	major_image_version:            u16le,
	minor_image_version:            u16le,
	major_subsystem_version:        u16le,
	minor_subsystem_version:        u16le,
	win32_version_value:            u32le,
	size_of_image:                  u32le,
	size_of_headers:                u32le,
	check_sum:                      u32le,
	subsystem:                      IMAGE_SUBSYSTEM,
	dll_characteristics:            IMAGE_DLLCHARACTERISTICS,
	size_of_stack_reserve:          u64le,
	size_of_stack_commit:           u64le,
	size_of_heap_reserve:           u64le,
	size_of_heap_commit:            u64le,
	loader_flags:                   u32le,
	number_of_rva_and_sizes:        u32le,
	data_directory:                 [16]Data_Directory,
}

// .debug section
Debug_Directory_Entry :: struct {
	characteristics:     u32le,
	time_date_stamp:     u32le,
	major_version:       u16le,
	minor_version:       u16le,
	type:                IMAGE_DEBUG_TYPE,
	size_of_data:        u32le,
	address_of_raw_data: u32le,
	pointer_to_raw_data: u32le,
}


IMAGE_FILE_MACHINE :: enum u16le {
	UNKNOWN     = 0x0,
	AM33        = 0x1d3,
	AMD64       = 0x8664,
	ARM         = 0x1c0,
	ARMNT       = 0x1c4,
	ARM64       = 0xaa64,
	EBC         = 0xebc,
	I386        = 0x14c,
	IA64        = 0x200,
	LOONGARCH32 = 0x6232,
	LOONGARCH64 = 0x6264,
	M32R        = 0x9041,
	MIPS16      = 0x266,
	MIPSFPU     = 0x366,
	MIPSFPU16   = 0x466,
	POWERPC     = 0x1f0,
	POWERPCFP   = 0x1f1,
	R4000       = 0x166,
	SH3         = 0x1a2,
	SH3DSP      = 0x1a3,
	SH4         = 0x1a6,
	SH5         = 0x1a8,
	THUMB       = 0x1c2,
	WCEMIPSV2   = 0x169,
}

// IMAGE_DIRECTORY_ENTRY constants
IMAGE_DIRECTORY_ENTRY :: enum u8 {
	EXPORT         = 0,
	IMPORT         = 1,
	RESOURCE       = 2,
	EXCEPTION      = 3,
	SECURITY       = 4,
	BASERELOC      = 5,
	DEBUG          = 6,
	ARCHITECTURE   = 7, // reserved
	GLOBALPTR      = 8,
	TLS            = 9,
	LOAD_CONFIG    = 10,
	BOUND_IMPORT   = 11,
	IAT            = 12,
	DELAY_IMPORT   = 13,
	COM_DESCRIPTOR = 14, // DLR Runtime headers
	_RESERVED      = 15,
}
#assert(len(IMAGE_DIRECTORY_ENTRY) == 16)


IMAGE_FILE_CHARACTERISTICS :: distinct bit_set[IMAGE_FILE_CHARACTERISTIC; u16le]
IMAGE_FILE_CHARACTERISTIC :: enum u16le {
	RELOCS_STRIPPED         = 0,
	EXECUTABLE_IMAGE        = 1,
	LINE_NUMS_STRIPPED      = 2,
	LOCAL_SYMS_STRIPPED     = 3,
	AGGRESIVE_WS_TRIM       = 4,
	LARGE_ADDRESS_AWARE     = 5,

	BYTES_REVERSED_LO       = 7,
	MACHINE_32BIT           = 8, // IMAGE_FILE_32BIT_MACHINE  originally
	DEBUG_STRIPPED          = 9,
	REMOVABLE_RUN_FROM_SWAP = 10,
	NET_RUN_FROM_SWAP       = 11,
	SYSTEM                  = 12,
	DLL                     = 13,
	UP_SYSTEM_ONLY          = 14,
	BYTES_REVERSED_HI       = 15,
}

IMAGE_SUBSYSTEM :: enum u16le {
	UNKNOWN                  = 0,
	NATIVE                   = 1,
	WINDOWS_GUI              = 2,
	WINDOWS_CUI              = 3,
	OS2_CUI                  = 5,
	POSIX_CUI                = 7,
	NATIVE_WINDOWS           = 8,
	WINDOWS_CE_GUI           = 9,
	EFI_APPLICATION          = 10,
	EFI_BOOT_SERVICE_DRIVER  = 11,
	EFI_RUNTIME_DRIVER       = 12,
	EFI_ROM                  = 13,
	XBOX                     = 14,
	WINDOWS_BOOT_APPLICATION = 16,
}

IMAGE_DLLCHARACTERISTICS :: distinct bit_set[IMAGE_DLLCHARACTERISTIC; u16le]
IMAGE_DLLCHARACTERISTIC :: enum u16le {
	HIGH_ENTROPY_VA       = 5,
	DYNAMIC_BASE          = 6,
	FORCE_INTEGRITY       = 7,
	NX_COMPAT             = 8,
	NO_ISOLATION          = 9,
	NO_SEH                = 10,
	NO_BIND               = 11,
	APPCONTAINER          = 12,
	WDM_DRIVER            = 13,
	GUARD_CF              = 14,
	TERMINAL_SERVER_AWARE = 15,
}

IMAGE_DEBUG_TYPE :: enum u32le {
	UNKNOWN               = 0,  // An unknown value that is ignored by all tools.
	COFF                  = 1,  // The COFF debug information (line numbers, symbol table, and string table). This type of debug information is also pointed to by fields in the file headers.
	CODEVIEW              = 2,  // The Visual C++ debug information.
	FPO                   = 3,  // The frame pointer omission (FPO) information. This information tells the debugger how to interpret nonstandard stack frames, which use the EBP register for a purpose other than as a frame pointer.
	MISC                  = 4,  // The location of DBG file.
	EXCEPTION             = 5,  // A copy of .pdata section.
	FIXUP                 = 6,  // Reserved.
	OMAP_TO_SRC           = 7,  // The mapping from an RVA in image to an RVA in source image.
	OMAP_FROM_SRC         = 8,  // The mapping from an RVA in source image to an RVA in image.
	BORLAND               = 9,  // Reserved for Borland.
	RESERVED10            = 10, // Reserved.
	CLSID                 = 11, // Reserved.
	REPRO                 = 16, // PE determinism or reproducibility.
	EX_DLLCHARACTERISTICS = 20, // Extended DLL characteristics bits.
}

