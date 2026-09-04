package main

MACH_MAGIC_64 :: 0xfeedfacf

MACH_CMD_SYMTAB      :: 0x2
MACH_CMD_SEGMENT_64  :: 0x19
MACH_FILETYPE_EXEC   :: 2
MACH_FILETYPE_DSYM   :: 10
Mach_Header_64 :: struct #packed {
	magic:       u32,
	cpu_type:    u32,
	cpu_subtype: u32,
	file_type:   u32,
	cmd_count:   u32,
	cmd_size:    u32,
	flags:       u32,
	reserved:    u32,
}

Mach_Load_Command :: struct #packed {
	type: u32,
	size: u32,
}

Mach_Segment_64_Command :: struct #packed {
	type:                u32,
	size:                u32,
	name:             [16]u8,
	address:             u64,
	mem_size:            u64,
	file_offset:         u64,
	file_size:           u64,
	max_protection:      i32,
	init_protection:     i32,
	section_count:       u32,
	flags:               u32,
}

Mach_Section :: struct #packed {
	name:         [16]u8,
	segment_name: [16]u8,
	address:         u64,
	size:            u64,
	offset:          u32,
	align:           u32,
	reloc_offset:    u32,
	reloc_count:     u32,
	flags:           u32,
	_rsv1:           u32,
	_rsv2:           u32,
	_rsv3:           u32,
}

Mach_Symtab_Command :: struct #packed {
	type:                u32,
	size:                u32,
	symbol_table_offset: u32,
	symbol_count:        u32,
	string_table_offset: u32,
	string_table_size:   u32,
}

Mach_Symbol_Entry_64 :: struct #packed {
	string_table_idx: u32,
	type: u8,
	section_count: u8,
	description: u16,
	value: u64,
}
