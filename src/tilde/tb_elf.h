#ifndef TB_ELF_H
#define TB_ELF_H

#include <stdint.h>

#define TB_EI_MAG0       0
#define TB_EI_MAG1       1
#define TB_EI_MAG2       2
#define TB_EI_MAG3       3
#define TB_EI_CLASS      4  /* Class of machine. */
#define TB_EI_DATA       5  /* Data format. */
#define TB_EI_VERSION    6  /* ELF format version. */
#define TB_EI_OSABI      7  /* Operating system / ABI identification */
#define TB_EI_ABIVERSION 8  /* ABI version */
#define TB_OLD_EI_BRAND  8  /* Start of architecture identification. */
#define TB_EI_PAD        9  /* Start of padding (per SVR4 ABI). */
#define TB_EI_NIDENT     16 /* Size of e_ident array. */

/* Values for e_type. */
#define TB_ET_NONE   0      /* Unknown type. */
#define TB_ET_REL    1      /* Relocatable. */
#define TB_ET_EXEC   2      /* Executable. */
#define TB_ET_DYN    3      /* Shared object. */
#define TB_ET_CORE   4      /* Core file. */
#define TB_ET_LOOS   0xfe00 /* First operating system specific. */
#define TB_ET_HIOS   0xfeff /* Last operating system-specific. */
#define TB_ET_LOPROC 0xff00 /* First processor-specific. */
#define TB_ET_HIPROC 0xffff /* Last processor-specific. */

/* Values for e_machine. */
#define TB_EM_NONE    0   /* Unknown machine. */
#define TB_EM_MIPS    8   /* Mips */
#define TB_EM_X86_64  62  /* Advanced Micro Devices x86-64 */
#define TB_EM_AARCH64 183 /* AArch64 (64-bit ARM) */

/* sh_type */
#define TB_SHT_NULL     0 /* inactive */
#define TB_SHT_PROGBITS 1 /* program defined information */
#define TB_SHT_SYMTAB   2 /* symbol table section */
#define TB_SHT_STRTAB   3 /* string table section */
#define TB_SHT_RELA     4 /* relocation section with addends */
#define TB_SHT_NOBITS   8 /* no space section */

/* Flags for sh_flags. */
#define TB_SHF_WRITE            0x1        /* Section contains writable data. */
#define TB_SHF_ALLOC            0x2        /* Section occupies memory. */
#define TB_SHF_EXECINSTR        0x4        /* Section contains instructions. */
#define TB_SHF_MERGE            0x10       /* Section may be merged. */
#define TB_SHF_STRINGS          0x20       /* Section contains strings. */
#define TB_SHF_INFO_LINK        0x40       /* sh_info holds section index. */
#define TB_SHF_LINK_ORDER       0x80       /* Special ordering requirements. */
#define TB_SHF_OS_NONCONFORMING 0x100      /* OS-specific processing required. */
#define TB_SHF_GROUP            0x200      /* Member of section group. */
#define TB_SHF_TLS              0x400      /* Section contains TLS data. */
#define TB_SHF_MASKOS           0x0ff00000 /* OS-specific semantics. */
#define TB_SHF_MASKPROC         0xf0000000 /* Processor-specific semantics. */

/* Values for p_flags. */
#define TB_PF_X		0x1        /* Executable. */
#define TB_PF_W		0x2        /* Writable. */
#define TB_PF_R		0x4        /* Readable. */
#define TB_PF_MASKOS   0x0ff00000 /* Operating system-specific. */
#define TB_PF_MASKPROC 0xf0000000 /* Processor-specific. */

/* Values for p_type. */
#define TB_PT_NULL      0	/* Unused entry. */
#define TB_PT_LOAD      1	/* Loadable segment. */
#define TB_PT_DYNAMIC   2	/* Dynamic linking information segment. */
#define TB_PT_INTERP    3	/* Pathname of interpreter. */
#define TB_PT_NOTE      4	/* Auxiliary information. */
#define TB_PT_SHLIB     5	/* Reserved (not used). */
#define TB_PT_PHDR      6	/* Location of program header itself. */
#define TB_PT_TLS       7	/* Thread local storage segment */

/* Values for relocation */
typedef enum {
    TB_ELF_X86_64_NONE     = 0,
    TB_ELF_X86_64_64       = 1,
    TB_ELF_X86_64_PC32     = 2,
    TB_ELF_X86_64_GOT32    = 3,
    TB_ELF_X86_64_PLT32    = 4,
    TB_ELF_X86_64_GOTPCREL = 9,
} TB_ELF_RelocType;

// ST_TYPE
#define TB_ELF64_STT_NOTYPE  0
#define TB_ELF64_STT_OBJECT  1
#define TB_ELF64_STT_FUNC    2
#define TB_ELF64_STT_SECTION 3

// ST_INFO
#define TB_ELF64_STB_LOCAL  0
#define TB_ELF64_STB_GLOBAL 1
#define TB_ELF64_STB_WEAK   2

/* Macros for accessing the fields of st_info. */
#define TB_ELF64_ST_BIND(info) ((info) >> 4)
#define TB_ELF64_ST_TYPE(info) ((info) & 0xf)

#define TB_ELF64_ST_INFO(b, t) (((b) << 4) | ((t) & 0xF))

#define TB_ELF64_R_SYM(i)     ((i) >> 32u)
#define TB_ELF64_R_TYPE(i)    ((i)&0xffffffffULL)
#define TB_ELF64_R_INFO(s, t) (((uint64_t)(s) << 32ULL) + ((uint64_t)(t) & 0xffffffffULL))

// http://web.mit.edu/freebsd/head/sys/sys/elf64.h
// https://cirosantilli.com/elf-hello-world#minimal-elf-file
// https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
typedef struct {
    uint8_t  ident[16];
    uint16_t type;
    uint16_t machine;
    uint32_t version;
    uint64_t entry;
    uint64_t phoff;
    uint64_t shoff;
    uint32_t flags;
    uint16_t ehsize;
    uint16_t phentsize;
    uint16_t phnum;
    uint16_t shentsize;
    uint16_t shnum;
    uint16_t shstrndx;
} TB_Elf64_Ehdr;

typedef struct {
    uint32_t name;
    uint32_t type;
    uint64_t flags;
    uint64_t addr;
    uint64_t offset;
    uint64_t size;
    uint32_t link;
    uint32_t info;
    uint64_t addralign;
    uint64_t entsize;
} TB_Elf64_Shdr;

// Segment header for ELF64.
typedef struct {
    uint32_t type;   // Type of segment
    uint32_t flags;  // Segment flags
    uint64_t offset; // File offset where segment is located, in bytes
    uint64_t vaddr;  // Virtual address of beginning of segment
    uint64_t paddr;  // Physical addr of beginning of segment (OS-specific)
    uint64_t filesz; // Num. of bytes in file image of segment (may be zero)
    uint64_t memsz;  // Num. of bytes in mem image of segment (may be zero)
    uint64_t align;  // Segment alignment constraint
} TB_Elf64_Phdr;

typedef struct {
    uint32_t name;
    uint8_t  info;
    uint8_t  other;
    uint16_t shndx;
    uint64_t value;
    uint64_t size;
} TB_Elf64_Sym;

typedef struct {
    uint64_t offset;
    uint64_t info;
    int64_t  addend;
} TB_Elf64_Rela;

typedef struct {
    uint64_t offset;
    uint64_t info;
} TB_Elf64_Rel;

#endif /* TB_ELF_H */
