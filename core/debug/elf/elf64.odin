
package elf

// List of resources on ELF object files: https://refspecs.linuxfoundation.org/

// ELF TYPE    SIZE  DESCRIPTION                 ODIN TYPE
// ----------  ----  -----------------------     ------
// Elf_Addr       8  Unsigned program address --> uintptr
// Elf_Off        8  Unsigned file offset     --> uintptr
// Elf_Half       2  Unsigned medium integer  --> u16
// Elf_Word       4  Unsigned integer         --> u32
// Elf_Sword      4  Signed integer           --> i32
// Elf_Xword      8  Unsigned long integer    --> u64
// Elf_Sxword     8  Signed long integer      --> i64
// unsigned char  1  Unsigned small integer   --> u8

/// Indices of the identification bytes in the `Elf64_Ehdr.ident` array
Elf_Ident :: enum {
	MAG0        = 0,
	MAG1        = 1,
	MAG2        = 2,
	MAG3        = 3,
	CLASS       = 4,
	DATA        = 5,
	VERSION     = 6,
	OSABI       = 7,
	ABIVERSION  = 8,
	PAD         = 9,
}

/// First magic byte of ELF
ELFMAG0 :: u8(0x7f)

/// Second magic byte of ELF
ELFMAG1 :: u8('E')

/// Third magic byte of ELF
ELFMAG2 :: u8('L')

/// Fourth magic byte of ELF
ELFMAG3 :: u8('F')

// Magic is over, all that follows is suffering

/// ELF class representing 32-bit ELF objects
ELFCLASS32     :: u8(1)

/// ELF class representing 64-bit ELF objects
ELFCLASS64     :: u8(2)

/// Object's file data are Little-endian
ELFDATA2LSB    :: u8(1)

/// Object's file data are bit endian
ELFDATA2MSB    :: u8(2)

/// The current version of ELF
EV_CURRENT     :: u8(1)

/// System V ABI
ELFOSABI_SYSV  :: u8(0)

/// Object uses GNU extensions
ELFOSABI_GNU   :: u8(3)

/// HP-UX operating system
ELFOSABI_HPUX  :: u8(1)

/// ARM EABI
ELFOSABI_ARM_AEABI :: u8(64)

/// ARM
ELFOSABI_ARM   :: u8(97)

/// Standalone ELF object
ELFOSABI_STANDALONE :: u8(255)

/// The type of the ELF file
Elf_Type :: enum u16 {
	NONE   = 0,
	REL    = 1,
	EXEC   = 2,
	DYN    = 3,
	CORE   = 4,
	// 0xfe00..0xfeff: OS-specific elf object files
	// 0xff00..0xffff: CPU-specific elf object files
}

/// Used to mark an undefined or meaningless section reference
SHN_UNDEF   :: 0

/// Start of processor-specific range for section indices
SHN_LOPROC  :: 0xff00

/// End of processor-specific range for section indices
SHN_HIPROC  :: 0xff1f

/// Start of OS-specific range for section indices
SHN_LOOS    :: 0xff20

/// End of OS-specific range for section indices
SHN_HIOS    :: 0xff3f

/// Used to mark that a corresponding reference is an absolute reference
SHN_ABS     :: 0xfff1

/// Used to mark that a symbol has been declared as a common block
SHN_COMMON  :: 0xfff2

/// The value of `Elf64_Ehdr.machine` representing no machine
EM_NONE     :: 0

/// (SysV) The value of `Elf64_Ehdr.machine` representing ARM32 machine
EM_ARM      :: 40

/// (SysV) The value of `Elf64_Ehdr.machine` representing i386 machine
EM_386      :: 3

/// (SysV) The value of `Elf64_Ehdr.machine` representing x86-64 machine
EM_X86_64   :: 62

/// (SysV) The value of `Elf64_Ehdr.machine` representing AARCH64 (ARM64) machine
EM_AARCH64  :: 183

/// CPU-specific elf flags
Elf_Flags :: bit_set[Elf_Flag; u32]

/// Bits for the CPU-specific elf flags
Elf_Flag :: enum {
	// ARM-specific
	ARM_RELEXEC          = 0,
	ARM_HASENTRY         = 1,  // .entry contains entry point
}

/// ELF64 File Header
Elf64_Ehdr :: struct {
	ident:     [Elf_Ident]u8,   // ELF identification
	type:      Elf_Type,        // Object file type
	machine:   u16,             // Machine type
	version:   u32,             // Object file version
	entry:     uintptr,         // Entry point address
	phoff:     uintptr,         // Program header offset
	shoff:     uintptr,         // Section header offset
	flags:     Elf_Flags,       // CPU-specific flags
	ehsize:    u16,             // ELF header size
	phentsize: u16,             // Size of program header entry
	phnum:     u16,             // Number of program header entries
	shentsize: u16,             // Size of section header entry
	shnum:     u16,             // Number of section header entries
	shstrndx:  u16,             // Section name string table index
}

/// Type of ELF section header
Shdr_Type :: enum u32 {
	NULL           = 0,          // Marks an unused section header
	PROGBITS       = 1,          // Contains information defined by the program
	SYMTAB         = 2,          // Contains a linker symbol table
	STRTAB         = 3,          // Contains a string table
	RELA           = 4,          // Contains “Rela” type relocation entries
	HASH           = 5,          // Contains a symbol hash table
	DYNAMIC        = 6,          // Contains dynamic linking tables
	NOTE           = 7,          // Contains note information
	NOBITS         = 8,          // Contains uninitialized space; does not occupy any space in the file
	REL            = 9,          // Contains “Rel” type relocation entries
	SHLIB          = 10,         // Reserved
	DYNSYM         = 11,         // Contains a dynamic loader symbol table
	// 0x6ffffff0..0x6fffffff: OS-specific section types
	GNU_ATTRIBUTES = 0x6ffffff5, // (GNU) Object attributes
	GNU_HASH       = 0x6ffffff6, // (GNU) GNU-style hash table
	GNU_LIBLIST    = 0x6ffffff7, // (GNU) Prelink library list
	GNU_verdef     = 0x6ffffffd, // (GNU) Version definition section
	GNU_verneed    = 0x6ffffffe, // (GNU) Version needs section
	GNU_versym     = 0x6fffffff, // (GNU) Version symbol table
	// 0x70000001..0x7fffffff: CPU-specific section types
	AMD64_UNWIND   = 0x70000001, // (x86): Contains unwind tables
	ARM_EXIDX      = 0x70000001, // (ARM64): ARM unwind section
	ARM_PREEMPTMAP = 0x70000002, // (ARM64): Preemption details
	ARM_ATTRIBUTES = 0x70000003, // (ARM64): Reserved for object compatibility attributes
	// 0x80000000..0xffffffff: User-specific section types
}

/// Section header flags
Shdr_Flags :: bit_set[Shdr_Flag; u64]

/// Bits for the `Shdr_Flags`
Shdr_Flag :: enum {
	WRITE            = 0,       // Section contains writable data
	ALLOC            = 1,       // Section is allocated in memory image of program
	EXECINSTR        = 2,       // Section contains executable instructions
	MERGE            = 4,       // Might be merged
	STRINGS          = 5,       // Contains nul-terminated strings
	INFO_LINK        = 6,       // `sh_info' contains SHT index
	LINK_ORDER       = 7,       // Preserve order after combining
	OS_NONCONFORMING = 8,       // Non-standard OS specific handling required
	GROUP            = 9,       // Section is member of a group
	TLS              = 10,      // Section hold thread-local data
	COMPRESSED       = 11,      // Section with compressed data
	// 20..27: OS-specific section flags
	GNU_RETAIN       = 21,      // (GNU): Not to be GCed by linker
	// 28..31: Arch-specific section flags
	AMD64_LARGE      = 28,      // (SysV, Amd64): Section can hold more than 2GB of data
	ARM_ENTRYSECT    = 28,      // (SysV, ARM): Contains an entry point
	ARM_COMDEF       = 31,      // (SysV, ARM): This section can be multiple
}

/// Section contains writeable data
SHF_WRITE     :: Shdr_Flags{.WRITE}

/// Section is allocated in the memory image of a running program
SHF_ALLOC     :: Shdr_Flags{.ALLOC}

/// Section contains executable instructions
SHF_EXECINSTR :: Shdr_Flags{.EXECINSTR}

// /// Mask for OS-specific sections
// SHF_MASKOS    :: transmute(Shdr_Flags) cast(u64) 0x0f000000

/// If an object file section does not have this flag set, then it
/// may not hold more than 2GB and can be freely referred to in objects
/// using smaller code model
SHF_AMD64_LARGE :: Shdr_Flags{.AMD64_LARGE}

SHF_ARM_ENTRYSECT :: Shdr_Flags{.ARM_ENTRYSECT}

// /// Mask for processor-specific sections
// SHF_MASKPROC  :: transmute(Shdr_Flags) cast(u64) 0xf0000000

/// ELF64 Section Header
Elf64_Shdr :: struct #packed {
	name:      u32,            // Section name
	type:      Shdr_Type,      // Section type
	flags:     Shdr_Flags,     // Section attributes
	addr:      uintptr,        // Virtual address in memory
	offset:    uintptr,        // Offset in file
	size:      u64,            // Size of section
	link:      u32,            // Link to an associated section
	info:      u32,            // Miscellaneous information
	addralign: u64,            // Address alignment boundary
	entsize:   u64,            // Size of entries, if section has table
}

/// Elf section compression type
Elf_Compression :: enum {
	ZLIB = 1, // ZLIB/DEFLATE algorithm
	ZSTD = 2, // Zstandard algorithm
	//0x60000000..0x6fffffff: OS-specific compression
	//0x70000000..0x7fffffff: CPU-specific compression
}

/// Elf section compression header (for sections that have .COMPRESS flag)
Elf64_Chdr :: struct #packed {
	ch_type:      Elf_Compression, // Compression format
	ch_reserved:  u32,
	ch_size:      u64,           // Uncompressed data size
	ch_addralign: u64,           // Uncompressed data alignment
}

/// Symbol binding attribute
/// Located in high 4 bits of Elf64_Sym.info
Sym_Binding :: enum u8 {
	LOCAL   = 0,               // Not visible outside the object file
	GLOBAL  = 1,               // Global symbol, visible to all object files
	WEAK    = 2,               // Global scope, but with lower precedence than global symbols
	LOOS    = 10,              // OS-specific symbol bindings start
	HIOS    = 12,              // OS-specific symbol bindings end
	LOPROC  = 13,              // CPU-specific symbol bindings start
	HIPROC  = 15,              // CPU-specific symbol bindings end
}

/// Symbol type
/// Located in low 4 bits of Elf64_Sym.info
Sym_Type :: enum u8 {
	NOTYPE  = 0,               // No type specified (e.g., an absolute symbol)
	OBJECT  = 1,               // Data object
	FUNC    = 2,               // Function entry point
	SECTION = 3,               // Symbol is associated with a section
	FILE    = 4,               // Source file associated with the object file
	LOOS    = 10,              // OS-specific symbol types start
	GNU_IFUNC = 10,            // (SysV, i386) Symbol is an indirect code object
	HIOS    = 12,              // OS-specific symbol types end
	LOPROC  = 13,              // CPU-specific symbol types start
	HIPROC  = 15,              // CPU-specific symbol types end
}

/// ELF64 symbol
/// To unwrap the `info` field use the `sym_info_unwrap` helper function
Elf64_Sym :: struct #packed {
	name:   u32,               // Symbol name
	info:   u8,                // Type and Binding attributes
	other:  u8,                // Reserved
	shndx:  u16,               // Section table index
	value:  uintptr,           // Symbol value
	size:   u64,               // Size of object (e.g., common)
}

/// CPU-specific relocation types
Rel_Type :: enum u32 {
	// ========= AMD64-specific relocations: ======== //
	// The meaning of letters in the calculation:
	//   A = addend
	//   B = object base address
	//   G = offset into GOT table
	//   L = PLT address
	//   P = the place of the storage unit being relocated
	//   S = value of the symbol
	//   Z = size of the symbol
	//   GOT = the address of GOT
	// Relocation            No     Size Calculation
	// --------------        --     ---  ---------------
	X86_64_NONE            = 0,  // ---  ---
	X86_64_64              = 1,  // u64  S+A
	X86_64_PC32            = 2,  // u32  S+A-P
	X86_64_GOT32           = 3,  // u32  G+A
	X86_64_PLT32           = 4,  // u32  L+A-P
	X86_64_COPY            = 5,  // ---  ---
	X86_64_GLOB_DAT        = 6,  // u64  S
	X86_64_JUMP_SLOT       = 7,  // u64  S
	X86_64_RELATIVE        = 8,  // u64  B+A
	X86_64_GOTPCREL        = 9,  // u32  G+GOT+A-P
	X86_64_32              = 10, // u32  S+A
	X86_64_32S             = 11, // u32  S+A
	X86_64_16              = 12, // u16  S+A
	X86_64_PC16            = 13, // u16  S+A-P
	X86_64_8               = 14, // u8   S+A
	X86_64_PC8             = 15, // u8   S+A-P
	X86_64_DPTMOD64        = 16, // u64  (TODO)
	X86_64_DTPOFF64        = 17, // u64  (TODO)
	X86_64_TPOFF64         = 18, // u64  (TODO)
	X86_64_TLSGD           = 19, // u32  (TODO)
	X86_64_TLSLD           = 20, // u32  (TODO)
	X86_64_DTPOFF32        = 21, // u32  (TODO)
	X86_64_GOTTPOFF        = 22, // u32  (TODO)
	X86_64_TPOFF32         = 23, // u32  (TODO)
	X86_64_PC64            = 24, // u64  S+A-P
	X86_64_GOTOFF64        = 25, // u64  S+A-GOT
	X86_64_GOTPC32         = 26, // u32  GOT+A-P
	X86_64_GOT64           = 27, // u64  G+A
	X86_64_GOTPCREL64      = 28, // u64  G+GOT-P+A
	X86_64_GOTPC64         = 29, // u64  GOT-P+A
	X86_64_GOTPLT64        = 30, // u64  G+A
	X86_64_PLTOFF64        = 31, // u64  L-GOT+A
	X86_64_SIZE32          = 32, // u32  Z + A
	X86_64_SIZE64          = 33, // u64  Z + A
	X86_64_GOTPC32_TLSDESC = 34, // u32  (TODO)
	X86_64_TLSDESC_CALL    = 35, // ---  ---
	X86_64_TLSDESC         = 36, // u128 (TODO)
	X86_64_IRELATIVE       = 37, // u32  indirect(B+A)
	// ========= I386-specific relocations: ======== //
	// NOTE: these are the same as AMD64
	//   A = addend
	//   B = object base address
	//   G = offset into GOT table
	//   L = PLT address
	//   P = the place of the storage unit being relocated
	//   S = value of the symbol
	//   Z = size of the symbol
	//   GOT = the address of GOT
	// Relocation            No     Size Calculation
	// --------------        --     ---  ---------------
	I386_NONE              = 0,  // ---  ---
	I386_32                = 1,  // u32  S+A
	I386_PC32              = 2,  // u32  S+A-P
	I386_GOT32             = 3,  // u32  G+A-GOT
	I386_PLT32             = 4,  // u32  L+A-P
	I386_COPY              = 5,  // ---  ---
	I386_GLOB_DAT          = 6,  // u32  S
	I386_JUMP_SLOT         = 7,  // u32  S
	I386_RELATIVE          = 8,  // u32  B+A
	I386_GOTOFF            = 9,  // u32  S+A-GOT
	I386_GOTPC             = 10, // u32  GOT+A-P
	I386_TLS_TPOFF         = 14, // u32
	I386_TLS_IE            = 15, // u32
	I386_TLS_GOTIE         = 16, // u32
	I386_TLS_LE            = 17, // u32
	I386_TLS_GD            = 18, // u32
	I386_TLS_LDM           = 19, // u32
	I386_16                = 20, // u16  S+A
	I386_PC16              = 21, // u16  S+A-P
	I386_8                 = 22, // u8   S+A
	I386_PC8               = 23, // u8   S+A-P
	I386_TLS_GD_32         = 24, // u32
	I386_TLS_GD_PUSH       = 25, // u32
	I386_TLS_GD_CALL       = 26, // u32
	I386_TLS_GD_POP        = 27, // u32
	I386_TLS_LDM_32        = 28, // u32
	I386_TLS_LDM_PUSH      = 29, // u32
	I386_TLS_LDM_CALL      = 30, // u32
	I386_TLS_LDM_POP       = 31, // u32
	I386_TLS_LDO_32        = 32, // u32
	I386_TLS_IE_32         = 33, // u32
	I386_TLS_LE_32         = 34, // u32
	I386_TLS_DTPMOD32      = 35, // u32
	I386_TLS_DTPOFF32      = 36, // u32
	I386_TLS_TPOFF32       = 37, // u32
	I386_SIZE32            = 38, // u32 Z+A
	I386_TLS_GOTDESC       = 39, // u32
	I386_TLS_DESC_CALL     = 40, // --- ---
	I386_TLS_DESC          = 41, // u32
	I386_IRELATIVE         = 42, // u32 indirect(B+A)
	// ========== ARM32-specific relocations: ======== //
	//   A = addend
	//   P = section base + .offset
	//   B = base address of the section, for ARM_SBREL32 it's the object base
	//   S = value of the symbol
	// Relocation              No    Field          Calculation  Notes
	// --------------          --    ---            ------------ -----------
	ARM32_NONE               = 0,   // ---            ----       Encodes dependencies between sections.
	ARM32_PC24               = 1,   // *Deprecated
	ARM32_ABS32              = 2,   // u32            S+A
	ARM32_REL32              = 3,   // u32            S–P+A
	ARM32_PC13               = 4,   // ARM LDR pc     S–P+A
	ARM32_ABS16              = 5,   // u16            S+A
	ARM32_ABS12              = 6,   // ARM LDR/STR    S+A
	ARM32_THM_ABS5           = 7,   // Thumb LDR/STR  S+A
	ARM32_ABS8               = 8,   // u8             S+A
	ARM32_SBREL32            = 9,   // u32            S–B+A
	ARM32_THM_PC22           = 10,  // Thumb BL pair  S–P+A
	ARM32_THM_PC8            = 11,  // Thumb LDR pc   S–P+A
	ARM32_AMP_VCALL9         = 12,  // AMP            ---        Obsolete  
	ARM32_SWI24              = 13,  // ARM SWI        S+A
	ARM32_THM_SWI8           = 14,  // ---            ---        Reserved
	ARM32_XPC25              = 15,  // ---            ---        Reserved
	ARM32_THM_XPC22          = 16,  // ---            ---        Reserved
	ARM32_TLS_DTPMOD32       = 17,  // ID of module containing symbol
	ARM32_TLS_DTPOFF32       = 18,  // Offset in TLS block
	ARM32_TLS_TPOFF32        = 19,  // Offset in static TLS block
	ARM32_COPY               = 20,  // Copy symbol at runtime
	ARM32_GLOB_DAT           = 21,  // Create GOT entry
	ARM32_JUMP_SLOT          = 22,  // Create PLT entry
	ARM32_RELATIVE           = 23,  // Adjust by program base
	ARM32_GOTOFF             = 24,  // 32 bit offset to GOT
	ARM32_GOTPC              = 25,  // 32 bit PC relative offset to GOT
	ARM32_GOT32              = 26,  // 32 bit GOT entry
	ARM32_PLT32              = 27,  // ---            ---        Deprecated
	ARM32_CALL               = 28,  // PC relative 24 bit (BL, BLX
	ARM32_JUMP24             = 29,  // PC relative 24 bit (B, BL<cond
	ARM32_THM_JUMP24         = 30,  // PC relative 24 bit (Thumb32 B.W
	ARM32_BASE_ABS           = 31,  // Adjust by program base
	ARM32_ALU_PCREL_7_0      = 32,  // ---            ---        Obsolete
	ARM32_ALU_PCREL_15_8     = 33,  // ---            ---        Obsolete
	ARM32_ALU_PCREL_23_15    = 34,  // ---            ---        Obsolete
	ARM32_LDR_SBREL_11_0     = 35,  // ---            ---        Deprecated
	ARM32_ALU_SBREL_19_12    = 36,  // ---            ---        Deprecated
	ARM32_ALU_SBREL_27_20    = 37,  // ---            ---        Deprecated
	ARM32_TARGET1            = 38,
	ARM32_SBREL31            = 39,  // Program base relative
	ARM32_V4BX               = 40,
	ARM32_TARGET2            = 41,
	ARM32_PREL31             = 42,  // 32 bit PC relative
	ARM32_MOVW_ABS_NC        = 43,  // Direct 16-bit (MOVW)
	ARM32_MOVT_ABS           = 44,  // Direct high 16-bit (MOVT)
	ARM32_MOVW_PREL_NC       = 45,  // PC relative 16-bit (MOVW)
	ARM32_MOVT_PREL          = 46,  // PC relative (MOVT)
	ARM32_THM_MOVW_ABS_NC    = 47,  // Direct 16 bit (Thumb32 MOVW)
	ARM32_THM_MOVT_ABS       = 48,  // Direct high 16 bit (Thumb32 MOVT)
	ARM32_THM_MOVW_PREL_NC   = 49,  // PC relative 16 bit (Thumb32 MOVW)
	ARM32_THM_MOVT_PREL      = 50,  // PC relative high 16 bit (Thumb32 MOVT)
	ARM32_THM_JUMP19         = 51,  // PC relative 20 bit (Thumb32 B<cond>.W)
	ARM32_THM_JUMP6          = 52,  // PC relative X & 0x7E (Thumb16 CBZ, CBNZ)
	ARM32_THM_ALU_PREL_11_0  = 53,  // PC relative 12 bit (Thumb32 ADR.W)
	ARM32_THM_PC12           = 54,  // PC relative 12 bit (Thumb32 LDR{D,SB,H,SH})
	ARM32_ABS32_NOI          = 55,  // Direct 32-bit
	ARM32_REL32_NOI          = 56,  // PC relative 32-bit
	ARM32_ALU_PC_G0_NC       = 57,  // PC relative (ADD, SUB)
	ARM32_ALU_PC_G0          = 58,  // PC relative (ADD, SUB)
	ARM32_ALU_PC_G1_NC       = 59,  // PC relative (ADD, SUB)
	ARM32_ALU_PC_G1          = 60,  // PC relative (ADD, SUB)
	ARM32_ALU_PC_G2          = 61,  // PC relative (ADD, SUB)
	ARM32_LDR_PC_G1          = 62,  // PC relative (LDR,STR,LDRB,STRB)
	ARM32_LDR_PC_G2          = 63,  // PC relative (LDR,STR,LDRB,STRB)
	ARM32_LDRS_PC_G0         = 64,  // PC relative (STR{D,H}, LDR{D,SB,H,SH})
	ARM32_LDRS_PC_G1         = 65,  // PC relative (STR{D,H}, LDR{D,SB,H,SH})
	ARM32_LDRS_PC_G2         = 66,  // PC relative (STR{D,H},LDR{D,SB,H,SH})
	ARM32_LDC_PC_G0          = 67,  // PC relative (LDC, STC)
	ARM32_LDC_PC_G1          = 68,  // PC relative (LDC, STC)
	ARM32_LDC_PC_G2          = 69,  // PC relative (LDC, STC)
	ARM32_ALU_SB_G0_NC       = 70,  // Program base relative (ADD,SUB)
	ARM32_ALU_SB_G0          = 71,  // Program base relative (ADD,SUB)
	ARM32_ALU_SB_G1_NC       = 72,  // Program base relative (ADD,SUB)
	ARM32_ALU_SB_G1          = 73,  // Program base relative (ADD,SUB)
	ARM32_ALU_SB_G2          = 74,  // Program base relative (ADD,SUB)
	ARM32_LDR_SB_G0          = 75,  // Program base relative (LDR, STR, LDRB, STRB)
	ARM32_LDR_SB_G1          = 76,  // Program base relative (LDR, STR, LDRB, STRB)
	ARM32_LDR_SB_G2          = 77,  // Program base relative (LDR, STR, LDRB, STRB)
	ARM32_LDRS_SB_G0         = 78,  // Program base relative (LDR, STR, LDRB, STRB)
	ARM32_LDRS_SB_G1         = 79,  // Program base relative (LDR, STR, LDRB, STRB)
	ARM32_LDRS_SB_G2         = 80,  // Program base relative (LDR, STR, LDRB, STRB)
	ARM32_LDC_SB_G0          = 81,  // Program base relative (LDC,STC)
	ARM32_LDC_SB_G1          = 82,  // Program base relative (LDC,STC)
	ARM32_LDC_SB_G2          = 83,  // Program base relative (LDC,STC)
	ARM32_MOVW_BREL_NC       = 84,  // Program base relative 16 bit (MOVW)
	ARM32_MOVT_BREL          = 85,  // Program base relative high 16 bit (MOVT)
	ARM32_MOVW_BREL          = 86,  // Program base relative 16 bit (MOVW)
	ARM32_THM_MOVW_BREL_NC   = 87,  // Program base relative 16 bit (Thumb32 MOVW)
	ARM32_THM_MOVT_BREL      = 88,  // Program base relative high 16 bit (Thumb32 MOVT)
	ARM32_THM_MOVW_BREL      = 89,  // Program base relative 16 bit (Thumb32 MOVW)
	ARM32_TLS_GOTDESC        = 90,
	ARM32_TLS_CALL           = 91,
	ARM32_TLS_DESCSEQ        = 92,  // TLS relaxation
	ARM32_THM_TLS_CALL       = 93,
	ARM32_PLT32_ABS          = 94,
	ARM32_GOT_ABS            = 95,  // GOT entry
	ARM32_GOT_PREL           = 96,  // PC relative GOT entry
	ARM32_GOT_BREL12         = 97,  // GOT entry relative to GOT origin (LDR)
	ARM32_GOTOFF12           = 98,  // 12 bit, GOT entry relative to GOT origin (LDR, STR)
	ARM32_GOTRELAX           = 99,
	ARM32_GNU_VTENTRY        = 100,
	ARM32_GNU_VTINHERIT      = 101,
	ARM32_THM_PC11           = 102, // PC relative & 0xFFE (Thumb16 B)
	ARM32_THM_PC9            = 103, // PC relative & 0x1FE (Thumb16 B/B<cond>)
	ARM32_TLS_GD32           = 104, // PC-rel 32 bit for global dynamic thread local data
	ARM32_TLS_LDM32          = 105, // PC-rel 32 bit for local dynamic thread local data
	ARM32_TLS_LDO32          = 106, // 32 bit offset relative to TLS block
	ARM32_TLS_IE32           = 107, // PC-rel 32 bit for GOT entry of static TLS block offset
	ARM32_TLS_LE32           = 108, // 32 bit offset relative to static TLS block
	ARM32_TLS_LDO12          = 109, // 12 bit relative to TLS block (LDR, STR)
	ARM32_TLS_LE12           = 110, // 12 bit relative to static TLS block (LDR, STR)
	ARM32_TLS_IE12GP         = 111, // 12 bit GOT entry relative to GOT origin (LDR)
	ARM32_ME_TOO             = 128, // Obsolete
	ARM32_THM_TLS_DESCSEQ    = 129,
	ARM32_THM_TLS_DESCSEQ16  = 129,
	ARM32_THM_TLS_DESCSEQ32  = 130,
	ARM32_THM_GOT_BREL12     = 131, // GOT entry relative to GOT origin, 12 bit (Thumb32 LDR)
	ARM32_IRELATIVE          = 160,
	ARM32_RXPC25             = 249,
	ARM32_RSBREL32           = 250,
	ARM32_THM_RPC22          = 251,
	ARM32_RREL32             = 252,
	ARM32_RABS22             = 253,
	ARM32_RPC24              = 254,
	ARM32_RBASE              = 255,
	// ========== ARM64-specific relocations: ======== //
	ARM64_NONE                         = 0,  // No relocation.
	/* ILP32 AArch64 relocs.  */
	ARM64_P32_ABS32                    = 1,  // Direct 32 bit.
	ARM64_P32_COPY                     = 180,  // Copy symbol at runtime.
	ARM64_P32_GLOB_DAT                 = 181,  // Create GOT entry.
	ARM64_P32_JUMP_SLOT                = 182,  // Create PLT entry.
	ARM64_P32_RELATIVE                 = 183,  // Adjust by program base.
	ARM64_P32_TLS_DTPMOD               = 184,  // Module number, 32 bit.
	ARM64_P32_TLS_DTPREL               = 185,  // Module-relative offset, 32 bit.
	ARM64_P32_TLS_TPREL                = 186,  // TP-relative offset, 32 bit.
	ARM64_P32_TLSDESC                  = 187,  // TLS Descriptor.
	ARM64_P32_IRELATIVE                = 188,  // STT_GNU_IFUNC relocation
	/* LP64 AArch64 relocs.  */
	ARM64_ABS64                        = 257,  // Direct 64 bit
	ARM64_ABS32                        = 258,  // Direct 32 bit.
	ARM64_ABS16                        = 259,  // Direct 16-bit.
	ARM64_PREL64                       = 260,  // PC-relative 64-bit.
	ARM64_PREL32                       = 261,  // PC-relative 32-bit.
	ARM64_PREL16                       = 262,  // PC-relative 16-bit.
	ARM64_MOVW_UABS_G0                 = 263,  // Dir. MOVZ imm. from bits 15:0.
	ARM64_MOVW_UABS_G0_NC              = 264,  // Likewise for MOVK; no check.
	ARM64_MOVW_UABS_G1                 = 265,  // Dir. MOVZ imm. from bits 31:16.
	ARM64_MOVW_UABS_G1_NC              = 266,  // Likewise for MOVK; no check.
	ARM64_MOVW_UABS_G2                 = 267,  // Dir. MOVZ imm. from bits 47:32.
	ARM64_MOVW_UABS_G2_NC              = 268,  // Likewise for MOVK; no check.
	ARM64_MOVW_UABS_G3                 = 269,  // Dir. MOV{K,Z} imm. from 63:48.
	ARM64_MOVW_SABS_G0                 = 270,  // Dir. MOV{N,Z} imm. from 15:0.
	ARM64_MOVW_SABS_G1                 = 271,  // Dir. MOV{N,Z} imm. from 31:16.
	ARM64_MOVW_SABS_G2                 = 272,  // Dir. MOV{N,Z} imm. from 47:32.
	ARM64_LD_PREL_LO19                 = 273,  // PC-rel. LD imm. from bits 20:2.
	ARM64_ADR_PREL_LO21                = 274,  // PC-rel. ADR imm. from bits 20:0.
	ARM64_ADR_PREL_PG_HI21             = 275,  // Page-rel. ADRP imm. from 32:12.
	ARM64_ADR_PREL_PG_HI21_NC          = 276,  // Likewise; no overflow check.
	ARM64_ADD_ABS_LO12_NC              = 277,  // Dir. ADD imm. from bits 11:0.
	ARM64_LDST8_ABS_LO12_NC            = 278,  // Likewise for LD/ST; no check
	ARM64_TSTBR14                      = 279,  // PC-rel. TBZ/TBNZ imm. from 15:2.
	ARM64_CONDBR19                     = 280,  // PC-rel. cond. br. imm. from 20:2
	ARM64_JUMP26                       = 282,  // PC-rel. B imm. from bits 27:2.
	ARM64_CALL26                       = 283,  // Likewise for CALL.
	ARM64_LDST16_ABS_LO12_NC           = 284,  // Dir. ADD imm. from bits 11:1.
	ARM64_LDST32_ABS_LO12_NC           = 285,  // Likewise for bits 11:2.
	ARM64_LDST64_ABS_LO12_NC           = 286,  // Likewise for bits 11:3.
	ARM64_MOVW_PREL_G0                 = 287,  // PC-rel. MOV{N,Z} imm. from 15:0.
	ARM64_MOVW_PREL_G0_NC              = 288,  // Likewise for MOVK; no check.
	ARM64_MOVW_PREL_G1                 = 289,  // PC-rel. MOV{N,Z} imm. from 31:16
	ARM64_MOVW_PREL_G1_NC              = 290,  // Likewise for MOVK; no check.
	ARM64_MOVW_PREL_G2                 = 291,  // PC-rel. MOV{N,Z} imm. from 47:32
	ARM64_MOVW_PREL_G2_NC              = 292,  // Likewise for MOVK; no check.
	ARM64_MOVW_PREL_G3                 = 293,  // PC-rel. MOV{N,Z} imm. from 63:48
	ARM64_LDST128_ABS_LO12_NC          = 299,  // Dir. ADD imm. from bits 11:4.
	ARM64_MOVW_GOTOFF_G0               = 300,  // GOT-rel. off. MOV{N,Z} imm. 15:0
	ARM64_MOVW_GOTOFF_G0_NC            = 301,  // Likewise for MOVK; no check.
	ARM64_MOVW_GOTOFF_G1               = 302,  // GOT-rel. o. MOV{N,Z} imm. 31:16.
	ARM64_MOVW_GOTOFF_G1_NC            = 303,  // Likewise for MOVK; no check.
	ARM64_MOVW_GOTOFF_G2               = 304,  // GOT-rel. o. MOV{N,Z} imm. 47:32.
	ARM64_MOVW_GOTOFF_G2_NC            = 305,  // Likewise for MOVK; no check.
	ARM64_MOVW_GOTOFF_G3               = 306,  // GOT-rel. o. MOV{N,Z} imm. 63:48.
	ARM64_GOTREL64                     = 307,  // GOT-relative 64-bit.
	ARM64_GOTREL32                     = 308,  // GOT-relative 32-bit.
	ARM64_GOT_LD_PREL19                = 309,  // PC-rel. GOT off. load imm. 20:2.
	ARM64_LD64_GOTOFF_LO15             = 310,  // GOT-rel. off. LD/ST imm. 14:3.
	ARM64_ADR_GOT_PAGE                 = 311,  // P-page-rel. GOT off. ADRP 32:12.
	ARM64_LD64_GOT_LO12_NC             = 312,  // Dir. GOT off. LD/ST imm. 11:3.
	ARM64_LD64_GOTPAGE_LO15            = 313,  // GOT-page-rel. GOT off. LD/ST 14:
	ARM64_TLSGD_ADR_PREL21             = 512,  // PC-relative ADR imm. 20:0.
	ARM64_TLSGD_ADR_PAGE21             = 513,  // page-rel. ADRP imm. 32:12.
	ARM64_TLSGD_ADD_LO12_NC            = 514,  // direct ADD imm. from 11:0.
	ARM64_TLSGD_MOVW_G1                = 515,  // GOT-rel. MOV{N,Z} 31:16.
	ARM64_TLSGD_MOVW_G0_NC             = 516,  // GOT-rel. MOVK imm. 15:0.
	ARM64_TLSLD_ADR_PREL21             = 517,  // Like 512; local dynamic model.
	ARM64_TLSLD_ADR_PAGE21             = 518,  // Like 513; local dynamic model.
	ARM64_TLSLD_ADD_LO12_NC            = 519,  // Like 514; local dynamic model.
	ARM64_TLSLD_MOVW_G1                = 520,  // Like 515; local dynamic model.
	ARM64_TLSLD_MOVW_G0_NC             = 521,  // Like 516; local dynamic model.
	ARM64_TLSLD_LD_PREL19              = 522,  // TLS PC-rel. load imm. 20:2.
	ARM64_TLSLD_MOVW_DTPREL_G2         = 523,  // TLS DTP-rel. MOV{N,Z} 47:32.
	ARM64_TLSLD_MOVW_DTPREL_G1         = 524,  // TLS DTP-rel. MOV{N,Z} 31:16.
	ARM64_TLSLD_MOVW_DTPREL_G1_NC      = 525,  // Likewise; MOVK; no check.
	ARM64_TLSLD_MOVW_DTPREL_G0         = 526,  // TLS DTP-rel. MOV{N,Z} 15:0.
	ARM64_TLSLD_MOVW_DTPREL_G0_NC      = 527,  // Likewise; MOVK; no check.
	ARM64_TLSLD_ADD_DTPREL_HI12        = 528,  // DTP-rel. ADD imm. from 23:12
	ARM64_TLSLD_ADD_DTPREL_LO12        = 529,  // DTP-rel. ADD imm. from 11:0.
	ARM64_TLSLD_ADD_DTPREL_LO12_NC     = 530,  // Likewise; no ovfl. check.
	ARM64_TLSLD_LDST8_DTPREL_LO12      = 531,  // DTP-rel. LD/ST imm. 11:0.
	ARM64_TLSLD_LDST8_DTPREL_LO12_NC   = 532,  // Likewise; no check.
	ARM64_TLSLD_LDST16_DTPREL_LO12     = 533,  // DTP-rel. LD/ST imm. 11:1.
	ARM64_TLSLD_LDST16_DTPREL_LO12_NC  = 534,  // Likewise; no check.
	ARM64_TLSLD_LDST32_DTPREL_LO12     = 535,  // DTP-rel. LD/ST imm. 11:2.
	ARM64_TLSLD_LDST32_DTPREL_LO12_NC  = 536,  // Likewise; no check.
	ARM64_TLSLD_LDST64_DTPREL_LO12     = 537,  // DTP-rel. LD/ST imm. 11:3.
	ARM64_TLSLD_LDST64_DTPREL_LO12_NC  = 538,  // Likewise; no check.
	ARM64_TLSIE_MOVW_GOTTPREL_G1       = 539,  // GOT-rel. MOV{N,Z} 31:16.
	ARM64_TLSIE_MOVW_GOTTPREL_G0_NC    = 540,  // GOT-rel. MOVK 15:0.
	ARM64_TLSIE_ADR_GOTTPREL_PAGE21    = 541,  // Page-rel. ADRP 32:12.
	ARM64_TLSIE_LD64_GOTTPREL_LO12_NC  = 542,  // Direct LD off. 11:3.
	ARM64_TLSIE_LD_GOTTPREL_PREL19     = 543,  // PC-rel. load imm. 20:2.
	ARM64_TLSLE_MOVW_TPREL_G2          = 544,  // TLS TP-rel. MOV{N,Z} 47:32.
	ARM64_TLSLE_MOVW_TPREL_G1          = 545,  // TLS TP-rel. MOV{N,Z} 31:16.
	ARM64_TLSLE_MOVW_TPREL_G1_NC       = 546,  // Likewise; MOVK; no check.
	ARM64_TLSLE_MOVW_TPREL_G0          = 547,  // TLS TP-rel. MOV{N,Z} 15:0.
	ARM64_TLSLE_MOVW_TPREL_G0_NC       = 548,  // Likewise; MOVK; no check.
	ARM64_TLSLE_ADD_TPREL_HI12         = 549,  // TP-rel. ADD imm. 23:12.
	ARM64_TLSLE_ADD_TPREL_LO12         = 550,  // TP-rel. ADD imm. 11:0.
	ARM64_TLSLE_ADD_TPREL_LO12_NC      = 551,  // Likewise; no ovfl. check.
	ARM64_TLSLE_LDST8_TPREL_LO12       = 552,  // TP-rel. LD/ST off. 11:0.
	ARM64_TLSLE_LDST8_TPREL_LO12_NC    = 553,  // Likewise; no ovfl. check
	ARM64_TLSLE_LDST16_TPREL_LO12      = 554,  // TP-rel. LD/ST off. 11:1.
	ARM64_TLSLE_LDST16_TPREL_LO12_NC   = 555,  // Likewise; no check.
	ARM64_TLSLE_LDST32_TPREL_LO12      = 556,  // TP-rel. LD/ST off. 11:2.
	ARM64_TLSLE_LDST32_TPREL_LO12_NC   = 557,  // Likewise; no check.
	ARM64_TLSLE_LDST64_TPREL_LO12      = 558,  // TP-rel. LD/ST off. 11:3.
	ARM64_TLSLE_LDST64_TPREL_LO12_NC   = 559,  // Likewise; no check.
	ARM64_TLSDESC_LD_PREL19            = 560,  // PC-rel. load immediate 20:2.
	ARM64_TLSDESC_ADR_PREL21           = 561,  // PC-rel. ADR immediate 20:0.
	ARM64_TLSDESC_ADR_PAGE21           = 562,  // Page-rel. ADRP imm. 32:12.
	ARM64_TLSDESC_LD64_LO12            = 563,  // Direct LD off. from 11:3.
	ARM64_TLSDESC_ADD_LO12             = 564,  // Direct ADD imm. from 11:0.
	ARM64_TLSDESC_OFF_G1               = 565,  // GOT-rel. MOV{N,Z} imm. 31:16.
	ARM64_TLSDESC_OFF_G0_NC            = 566,  // GOT-rel. MOVK imm. 15:0; no ck.
	ARM64_TLSDESC_LDR                  = 567,  // Relax LDR.
	ARM64_TLSDESC_ADD                  = 568,  // Relax ADD.
	ARM64_TLSDESC_CALL                 = 569,  // Relax BLR.
	ARM64_TLSLE_LDST128_TPREL_LO12     = 570,  // TP-rel. LD/ST off. 11:4.
	ARM64_TLSLE_LDST128_TPREL_LO12_NC  = 571,  // Likewise; no check.
	ARM64_TLSLD_LDST128_DTPREL_LO12    = 572,  // DTP-rel. LD/ST imm. 11:4
	ARM64_TLSLD_LDST128_DTPREL_LO12_NC = 573,  // Likewise; no check.
	ARM64_COPY                         = 1024,  // Copy symbol at runtime.
	ARM64_GLOB_DAT                     = 1025,  // Create GOT entry.
	ARM64_JUMP_SLOT                    = 1026,  // Create PLT entry.
	ARM64_RELATIVE                     = 1027,  // Adjust by program base.
	ARM64_TLS_DTPMOD                   = 1028,  // Module number, 64 bit.
	ARM64_TLS_DTPREL                   = 1029,  // Module-relative offset, 64 bit.
	ARM64_TLS_TPREL                    = 1030,  // TP-relative offset, 64 bit.
	ARM64_TLSDESC                      = 1031,  // TLS Descriptor.
	ARM64_IRELATIVE                    = 1032,  // STT_GNU_IFUNC relocation.
}

/// Elf64 rel-type relocation
/// To unpack the `info` field use `rel_info_unwrap` helper function
/// This variant is not used on x86 architectures
Elf64_Rel :: struct #packed {
	offset: uintptr,           // Address of reference
	info:   u64,               // Symbol index and type of relocation
}

/// Elf64 rela-type relocation
/// To unpack the `info` field use `rel_info_unwrap` helper function
Elf64_Rela :: struct #packed {
	offset: uintptr,           // Address of reference
	info:   u64,               // Symbol index and type of relocation
	addend: i64,               // Constant part of expression
}

/// Program header type
Phdr_Type :: enum u32 {
	NULL    = 0,               // Unused entry
	LOAD    = 1,               // Loadable segment
	DYNAMIC = 2,               // Dynamic linking tables
	INTERP  = 3,               // Program interpreter path name
	NOTE    = 4,               // Note sections
	SHLIB   = 5,               // Reserved
	PHDR    = 6,               // Program header table
	LOOS    = 0x60000000,      // OS-specific program header types start
	HIOS    = 0x6fffffff,      // OS-specific program header types end
	LOPROC  = 0x70000000,      // CPU-specific program header types start
	ARM64_ARCHEXT    = 0x70000000, // (SysV, ARM64): Reserved for architecture compatibility information
	ARM64_UNWIND     = 0x70000001, // (SysV, ARM64): Reserved for exception unwinding tables
	ARM64_MEMTAG_MTE = 0x70000002, // (SysV, ARM64): Reserved for MTE memory tag data dumps in core files
	HIPROC  = 0x7fffffff,      // CPU-specific program header types end
}

/// Program header flags
Phdr_Flags :: bit_set[Phdr_Flag; u32]

/// Bits for `Phdr_Flags`
Phdr_Flag :: enum {
	X = 0,
	W = 1,
	R = 2,
}

/// Execute permission
PF_X        :: Phdr_Flags{.X}

/// Write permission
PF_W        :: Phdr_Flags{.W}

/// Read permission
PF_R        :: Phdr_Flags{.R}

// /// Mask for OS-specific program hedaer flags
// PF_MASKOS   :: transmute(Phdr_Flag) cast(u32) 0x00FF0000

// /// Mask for CPU-specific program header flags
// PF_MASKPROC :: transmute(Phdr_Flag) cast(u32) 0xFF000000

/// Elf64 Program header
Elf64_Phdr :: struct #packed {
	type:   Phdr_Type,         // Type of segment
	flags:  u32,               // Segment attributes
	offset: uintptr,           // Offset in file
	vaddr:  uintptr,           // Virtual address in memory
	paddr:  uintptr,           // Reserved
	filesz: u64,               // Size of segment in file
	memsz:  u64,               // Size of segment in memory
	align:  u64,               // Alignment of segment
}

/// Dynamic table entry tag
Dyn_Tag :: enum i64 {
	NULL         = 0,          // ---     Marks the end of the dynamic array
	NEEDED       = 1,          // d_val:  The string table offset of the name of a needed library
	PLTRELSZ     = 2,          // d_val:  Total size of the relocation entries associated with the procedure linkage table.
	PLTGOT       = 3,          // d_ptr:  Contains an address associated with the linkage table. The specific meaning of this field is processor-dependent.
	HASH         = 4,          // d_ptr:  Address of the symbol hash table, described below.
	STRTAB       = 5,          // d_ptr:  Address of the dynamic string table.
	SYMTAB       = 6,          // d_ptr:  Address of the dynamic symbol table.
	RELA         = 7,          // d_ptr:  Address of a relocation table with Elf64_Rela entries.
	RELASZ       = 8,          // d_val:  Total size of the DT_RELA relocation table.
	RELAENT      = 9,          // d_val:  Size of each DT_RELA relocation entry.
	STRSZ        = 10,         // d_val:  Total size of the string table.
	SYMENT       = 11,         // d_val:  Size of each symbol table entry.
	INIT         = 12,         // d_ptr:  Address of the initialization function.
	FINI         = 13,         // d_ptr:  Address of the termination function.
	SONAME       = 14,         // d_val:  The string table offset of the name of this shared object.
	RPATH        = 15,         // d_val:  The string table offset of a shared library search path string.
	SYMBOLIC     = 16,         // ---     The presence of this dynamic table entry modifies the symbol resolution algorithm for references within the library. Symbols defined within the library are used to resolve references before the dynamic linker searches the usual search path.
	REL          = 17,         // d_ptr:  Address of a relocation table with Elf64_Rel entries.
	RELSZ        = 18,         // d_val:  Total size of the DT_REL relocation table.
	RELENT       = 19,         // d_val:  Size of each DT_REL relocation entry.
	PLTREL       = 20,         // d_val:  Type of relocation entry used for the procedure linkage table. The d_val member contains either DT_REL or DT_RELA.
	DEBUG        = 21,         // d_ptr:  Reserved for debugger use.
	TEXTREL      = 22,         // ---     The presence of this dynamic table entry signals that the relocation table contains relocations for a non-writable segment.
	JMPREL       = 23,         // d_ptr:  Address of the relocations associated with the procedure linkage table.
	BIND_NOW     = 24,         // ---     The presence of this dynamic table entry signals that the dynamic loader should process all relocations for this object before transferring control to the program.
	INIT_ARRAY   = 25,         // d_ptr:  Pointer to an array of pointers to initialization functions.
	FINI_ARRAY   = 26,         // d_ptr:  Pointer to an array of pointers to termination functions.
	INIT_ARRAYSZ = 27,         // d_val:  Size of the array of initialization functions.
	FINI_ARRAYSZ = 28,         // d_val:  Size of the array of termination functions.
	RUNPATH      = 29,         // Library search path */
	FLAGS        = 30,         // Flags for the object being loaded */
	ENCODING     = 32,         // Start of encoded range */
	PREINIT_ARRAY = 32,        // Array with addresses of preinit fct*/
	PREINIT_ARRAYSZ = 33,      // size in bytes of DT_PREINIT_ARRAY */
	SYMTAB_SHNDX = 34,         // Address of SYMTAB_SHNDX section */
	RELRSZ       = 35,         // Total size of RELR relative relocations */
	RELR         = 36,         // Address of RELR relative relocations */
	RELRENT      = 37,         // Size of one RELR relative relocaction */
	// 0x60000000..0x6fffffff: OS-specific Dynamic table entry tags
	VERSYM       = 0x6ffffff0, // d_ptr (SysV): 
	VERDEF       = 0x6ffffffc, // d_ptr (SysV): Address of version definition
	VERDEFNUM    = 0x6ffffffd, // d_val (SysV): Number of version definitions
	VERNEED      = 0x6ffffffe, // d_ptr (SysV): Address of table with needed versions
	VERNEEDNUM   = 0x6ffffffd, // d_val (SysV): Number of needed versions
	GNU_HASH     = 0x6ffffef5, // d_ptr (GNU):  GNU-style hash table
	GNU_CONFLICT = 0x6ffffef8, // d_ptr (GNU):  Start of conflict section
	GNU_LIBLIST  = 0x6ffffef9, // d_ptr (GNU):  Library list
	// 0x70000000..0x7fffffff: CPU-specific Dynmic table entry tags
	ARM64_BTI_PLT     = 0x70000001, // d_val PLTs enabled with Branch Target Identification mechanism
	ARM64_PAC_PLT     = 0x70000003, // d_val PLTs enabled with Pointer Authentication
	ARM64_VARIANT_PCS = 0x70000005, // d_val TODO
}

/// Elf64 Dynamic table entry
Elf64_Dyn :: struct #packed {
	tag: Dyn_Tag,
	using un: struct #raw_union {
		val: u64,
		ptr: uintptr,
	},
}

/// Type of the auxiliary vector values
Aux_Type :: enum {
	NULL          = 0,  // end of vector
	IGNORE        = 1,  // entry should be ignored
	EXECFD        = 2,  // file descriptor of program
	PHDR          = 3,  // program headers for program
	PHENT         = 4,  // size of program header entry
	PHNUM         = 5,  // number of program headers
	PAGESZ        = 6,  // system page size
	BASE          = 7,  // base address of interpreter
	FLAGS         = 8,  // flags
	ENTRY         = 9,  // entry point of program
	NOTELF        = 10, // program is not ELF
	UID           = 11, // real uid
	EUID          = 12, // effective uid
	GID           = 13, // real gid
	EGID          = 14, // effective gid
	PLATFORM      = 15, // string identifying CPU for optimizations
	HWCAP         = 16, // arch dependent hints at CPU capabilities
	CLKTCK        = 17, // frequency at which times() increments
	SECURE        = 23, // secure mode boolean
	BASE_PLATFORM = 24, // tring identifying real platform, may differ from AT_PLATFORM.
	RANDOM        = 25, // address of 16 random bytes
	EXECFN        = 31, // filename of program
}

/// Auxiliary vector values
Aux_Value :: struct #packed {
	type:  Aux_Type,
	value: u64,
}
