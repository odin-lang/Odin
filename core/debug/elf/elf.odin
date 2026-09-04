package elf

/*
Handy References:
- https://refspecs.linuxbase.org/elf/elf.pdf
- http://man7.org/linux/man-pages/man5/elf.5.html
*/

ELFCLASS32  :: 1
ELFCLASS64  :: 2
ELFDATA2LSB :: 1
ELFDATA2MSB :: 2

File_Type :: enum {
	none        = 0x0,
	relocatable = 0x1,
	executable  = 0x2,
	shared_obj  = 0x3,
	core        = 0x4,
	lo_os       = 0xFE00,
	hi_os       = 0xFEFF,
	lo_proc     = 0xFF00,
	hi_proc     = 0xFFFF,
}

Processor_Type :: enum {
	none              = 0x000,
	att_we_32100      = 0x001,
	sparc             = 0x002,
	x86               = 0x003,
	m68k              = 0x004,
	m88k              = 0x005,
	imcu              = 0x006,
	i80860            = 0x007,
	mips              = 0x008,
	system_370        = 0x009,
	mips_rs3000_le    = 0x00A,
	hp_pa_risc        = 0x00E,
	i80960            = 0x013,
	ppc               = 0x014,
	ppc_64            = 0x015,
	s390              = 0x016,
	ibm_spu           = 0x017,
	nec_v800          = 0x024,
	fujitsu_fr20      = 0x025,
	trw_rh32          = 0x026,
	motorola_rce      = 0x027,
	arm               = 0x028,
	alpha             = 0x029,
	super_h           = 0x02A,
	sparc_v9          = 0x02B,
	siemens_tricore   = 0x02C,
	argonaut_risc     = 0x02D,
	hitachi_h8_300    = 0x02E,
	hitachi_h8_300h   = 0x02F,
	hitachi_h8s       = 0x030,
	hitachi_h8_500    = 0x031,
	itanium           = 0x032,
	stanford_mips_x   = 0x033,
	motorola_coldfire = 0x034,
	motorola_m68hc12  = 0x035,
	fujitsu_mma       = 0x036,
	siemens_pcp       = 0x037,
	sony_ncpu_risc    = 0x038,
	denso_ndr1        = 0x039,
	motorola_starcore = 0x03A,
	toyota_me16       = 0x03B,
	stmicro_st100     = 0x03C,
	alc_tinyj         = 0x03D,
	x86_64            = 0x03E,
	tms320c6000       = 0x08C,
	mcst_elbrus_e2k   = 0x0AF,
	arm_64            = 0x0B7,
	risc_v            = 0x0F3,
	bpf               = 0x0F7,
	wdc_65c816        = 0x101,
}

Target_ABI :: enum {
	system_v       = 0x00,
	hp_ux          = 0x01,
	netbsd         = 0x02,
	linux          = 0x03,
	gnu_hurd       = 0x04,
	solaris        = 0x06,
	aix            = 0x07,
	irix           = 0x08,
	freebsd        = 0x09,
	tru64          = 0x0A,
	novell_modesto = 0x0B,
	openbsd        = 0x0C,
	openvms        = 0x0D,
	nonstop_kernel = 0x0E,
	aros           = 0x0F,
	fenix_os       = 0x10,
	cloud_abi      = 0x11,
	open_vos       = 0x12,
}

Section_Flags :: enum u64 {
	write      = 0x1,
	alloc      = 0x2,
	executable = 0x4,
	merge      = 0x10,
	strings    = 0x20,
	info_link  = 0x40,
	os_nonconforming = 0x100,
	group      = 0x200,
	tls        = 0x400,
	mask_os    = 0x0FF00000,
	mask_proc  = 0xF0000000,
	ordered    = 0x4000000,
	exclude    = 0x8000000,
}

Section_Header_Type :: enum {
	null     = 0x00,
	progbits = 0x01,
	symtab   = 0x02,
	strtab   = 0x03,
	rela     = 0x04,
	hash     = 0x05,
	dyn      = 0x06,
	note     = 0x07,
	nobits   = 0x08,
	rel      = 0x09,
	dynsym   = 0x0B,
	init_array  = 0x0E,
	fini_array  = 0x0F,
	gnu_hash    = 0x6FFFFFF6,
	gnu_verdef  = 0x6FFFFFFD,
	gnu_verneed = 0x6FFFFFFE,
	gnu_versym  = 0x6FFFFFFF,
	unwind      = 0x70000001,
}

Section_Type :: enum {
	null    = 0,
	load    = 1,
	dyn     = 2,
	interp  = 3,
	note    = 4,
	shlib   = 5,
	phdr    = 6,
	tls     = 7,
	gnu_eh_frame = 0x6474e550,
	gnu_stack    = 0x6474e551,
	gnu_relro    = 0x6474e552,
	gnu_property = 0x6474e553,
	lowproc      = 0x70000000,
	hiproc       = 0x7FFFFFFF,
}

Dynamic_Type :: enum {
	null         = 0,
	needed       = 1,
	plt_rel_size = 2,
	plt_got      = 3,
	hash         = 4,
	strtab       = 5,
	symtab       = 6,
	rela         = 7,
	rela_size    = 8,
	rela_entry   = 9,
	str_size     = 10,
	symbol_entry = 11,
	init         = 12,
	fini         = 13,
	so_name      = 14,
	rpath        = 15,
	symbolic     = 16,
	rel          = 17,
	rel_size     = 18,
	rel_entry    = 19,
	plt_rel      = 20,
	debug        = 21,
	text_rel     = 22,
	jump_rel     = 23,
	bind_now     = 24,
	init_array   = 25,
	init_array_size  = 26,
	fini_array       = 27,
	fini_array_size  = 28,
	gnu_hash         = 0x6FFFFEF5,
	version_symbol   = 0x6FFFFFF0,
	version_need     = 0x6FFFFFFE,
	version_need_num = 0x6FFFFFFF,
	lo_proc          = 0x70000000,
	hi_proc          = 0x7FFFFFFF,
}

Symbol_Binding :: enum u8 {
	local  = 0,
	global = 1,
	weak   = 2,
	loos   = 10,
	hios   = 12,
	loproc = 13,
	hiproc = 15,
}

Symbol_Type :: enum u8 {
	notype  = 0,
	object  = 1,
	func    = 2,
	section = 3,
	file    = 4,
	common  = 5,
	tls     = 6,
	loos    = 10,
	hios    = 12,
	loproc  = 13,
	hiproc  = 15,
}

Symbol :: struct {
	name: cstring,
	value: u64,
	size: u64,
	type: Symbol_Type,
	bind: Symbol_Binding,
}

ELF_Pre_Header :: struct #packed {
	magic: [4]u8,
	class: u8,
	endian: u8,
	hdr_version: u8,
	target_abi: u8,
	pad: [8]u8,
}

ELF32_Header :: struct #packed {
	ident: [16]u8,

	type: u16,
	machine: u16,
	version: u32,
	entry: u32,
	program_hdr_offset: u32,
	section_hdr_offset: u32,
	flags: u32,
	ehsize: u16,
	program_hdr_entry_size: u16,
	program_hdr_num: u16,
	section_entry_size: u16,
	section_hdr_num: u16,
	section_hdr_str_idx: u16,
}

ELF64_Header :: struct #packed {
	ident: [16]u8,

	type: u16,
	machine: u16,
	version: u32,
	entry: u64,
	program_hdr_offset: u64,
	section_hdr_offset: u64,
	flags: u32,
	ehsize: u16,
	program_hdr_entry_size: u16,
	program_hdr_num: u16,
	section_entry_size: u16,
	section_hdr_num: u16,
	section_hdr_str_idx: u16,
}

ELF_Header :: struct {
	program_hdr_offset: u64,
	section_hdr_offset: u64,
	program_hdr_num: u16,
	program_hdr_entry_size: u16,
	section_entry_size: u16,
	section_hdr_num: u16,
	section_hdr_str_idx: u16,
}

ELF32_Section_Header :: struct #packed {
	name: u32,
	type: u32,
	flags: u32,
	addr: u32,
	offset: u32,
	size: u32,
	link: u32,
	info: u32,
	addr_align: u32,
	entry_size: u32,
}

ELF64_Section_Header :: struct #packed {
	name: u32,
	type: u32,
	flags: u64,
	addr: u64,
	offset: u64,
	size: u64,
	link: u32,
	info: u32,
	addr_align: u64,
	entry_size: u64,
}

ELF_Section_Header :: struct {
	name: u32,
	type: Section_Header_Type,
	flags: u64,
	addr: u64,
	offset: u64,
	size: u64,
	link: u32,
	info: u32,
	addr_align: u64,
	entry_size: u64,
}

ELF32_Program_Header :: struct #packed {
	type: u32,
	offset: u32,
	virtual_addr: u32,
	physical_addr: u32,
	file_size: u32,
	mem_size: u32,
	flags: u32,
	align: u32,
}

ELF64_Program_Header :: struct #packed {
	type: u32,
	flags: u32,
	offset: u64,
	virtual_addr: u64,
	physical_addr: u64,
	file_size: u64,
	mem_size: u64,
	align: u64,
}

ELF_Program_Header :: struct {
	type: Section_Type,
	flags:         u32,
	offset:        u64,
	virtual_addr:  u64,
	physical_addr: u64,
	file_size:     u64,
	mem_size:      u64,
	align:         u64,
}

ELF32_Dyn :: struct #packed {
	tag: i32,
	val: u32,
}

ELF64_Dyn :: struct #packed {
	tag: i64,
	val: u64,
}

ELF_Dynamic :: struct {
	tag: i64,
	val: u64,
}

ELF32_Sym :: struct #packed {
	name:  u32,
	value: u32,
	size:  u32,
	info:  u8,
	other: u8,
	shndx: u16,
}

ELF64_Sym :: struct #packed {
	name:  u32,
	info:  u8,
	other: u8,
	shndx: u16,
	value: u64,
	size:  u64,
}

ELF_Symbol :: struct {
	name:  u32,
	info:  u8,
	other: u8,
	shndx: u16,
	value: u64,
	size:  u64,
}

ELF32_Rel :: struct #packed {
	offset: u32,
	info:   u32,
}

ELF32_Rela :: struct #packed {
	offset: u32,
	info:   u32,
	addend: i32,
}

ELF64_Rel :: struct #packed {
	offset: u64,
	info:   u64,
}

ELF64_Rela :: struct #packed {
	offset: u64,
	info:   u64,
	addend: i64,
}

Relocation :: struct {
	offset: u64,
	symbol: u32,
	type:   u32,
	addend: i64,
}
