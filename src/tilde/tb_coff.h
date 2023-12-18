// PE/COFF is the executable/object format used by Microsoft.
#ifndef TB_COFF_H
#define TB_COFF_H

#include "tb_formats.h"

#define IMAGE_SCN_LNK_NRELOC_OVFL 0x01000000

#define IMAGE_SYM_CLASS_EXTERNAL      0x0002
#define IMAGE_SYM_CLASS_STATIC        0x0003
#define IMAGE_SYM_CLASS_LABEL         0x0006
#define IMAGE_SYM_CLASS_FILE          0x0067
#define IMAGE_SYM_CLASS_SECTION       0x0068
#define IMAGE_SYM_CLASS_WEAK_EXTERNAL 0x0069

#define IMAGE_FILE_LINE_NUMS_STRIPPED 0x0004

#define IMAGE_REL_AMD64_ADDR64   0x0001
#define IMAGE_REL_AMD64_ADDR32   0x0002
#define IMAGE_REL_AMD64_ADDR32NB 0x0003
#define IMAGE_REL_AMD64_REL32    0x0004
#define IMAGE_REL_AMD64_REL32_1  0x0005
#define IMAGE_REL_AMD64_REL32_2  0x0006
#define IMAGE_REL_AMD64_REL32_3  0x0007
#define IMAGE_REL_AMD64_REL32_4  0x0008
#define IMAGE_REL_AMD64_REL32_5  0x0009
#define IMAGE_REL_AMD64_SECTION  0x000A
#define IMAGE_REL_AMD64_SECREL   0x000B

#define IMAGE_SCN_LNK_REMOVE      0x00000800
#define IMAGE_SCN_LNK_COMDAT      0x00001000
#define IMAGE_SCN_MEM_DISCARDABLE 0x02000000
#define IMAGE_SCN_MEM_EXECUTE     0x20000000
#define IMAGE_SCN_MEM_READ        0x40000000
#define IMAGE_SCN_MEM_WRITE       0x80000000

#define IMAGE_SCN_CNT_CODE                   0x00000020  /* Section contains code. */
#define IMAGE_SCN_CNT_INITIALIZED_DATA       0x00000040  /* Section contains initialized data. */
#define IMAGE_SCN_CNT_UNINITIALIZED_DATA     0x00000080  /* Section contains uninitialized data. */

#define IMAGE_DIRECTORY_ENTRY_EXPORT          0   // Export Directory
#define IMAGE_DIRECTORY_ENTRY_IMPORT          1   // Import Directory
#define IMAGE_DIRECTORY_ENTRY_RESOURCE        2   // Resource Directory
#define IMAGE_DIRECTORY_ENTRY_EXCEPTION       3   // Exception Directory
#define IMAGE_DIRECTORY_ENTRY_SECURITY        4   // Security Directory
#define IMAGE_DIRECTORY_ENTRY_BASERELOC       5   // Base Relocation Table
#define IMAGE_DIRECTORY_ENTRY_DEBUG           6   // Debug Directory
#define IMAGE_DIRECTORY_ENTRY_ARCHITECTURE    7   // Architecture Specific Data
#define IMAGE_DIRECTORY_ENTRY_GLOBALPTR       8   // RVA of GP
#define IMAGE_DIRECTORY_ENTRY_TLS             9   // TLS Directory
#define IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG    10   // Load Configuration Directory
#define IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT   11   // Bound Import Directory in headers
#define IMAGE_DIRECTORY_ENTRY_IAT            12   // Import Address Table
#define IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT   13   // Delay Load Import Descriptors
#define IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR 14   // COM Runtime descriptor

#define IMAGE_SUBSYSTEM_WINDOWS_GUI 2
#define IMAGE_SUBSYSTEM_WINDOWS_CUI 3
#define IMAGE_SUBSYSTEM_EFI_APPLICATION 10

typedef enum {
    TB_COFF_SECTION_NO_PAD      = 0x00000008,
    TB_COFF_SECTION_CODE        = 0x00000020,
    TB_COFF_SECTION_INIT        = 0x00000040,
    TB_COFF_SECTION_UNINIT      = 0x00000080,
    TB_COFF_SECTION_OTHER       = 0x00000100,
    TB_COFF_SECTION_INFO        = 0x00000200,
    TB_COFF_SECTION_REMOVE      = 0x00000800,
    TB_COFF_SECTION_COMDAT      = 0x00001000,

    // this is actually a 4bit field
    TB_COFF_SECTION_ALIGN       = 0x00F00000,

    // if we have more than 65535 relocations we do this
    TB_COFF_SECTION_RELOC_OVR   = 0x00F00000,

    // memory flags
    TB_COFF_SECTION_DISCARDABLE = 0x02000000,
    TB_COFF_SECTION_NOT_CACHED  = 0x04000000,
    TB_COFF_SECTION_NOT_PAGED   = 0x08000000,
    TB_COFF_SECTION_SHARED      = 0x10000000,
    TB_COFF_SECTION_EXECUTE     = 0x20000000,
    TB_COFF_SECTION_READ        = 0x40000000,
    TB_COFF_SECTION_WRITE       = 0x80000000,
} TB_COFF_SectionFlags;

typedef struct TB_COFF_Parser {
    // inputs
    TB_Slice name, file;

    // results
    size_t section_count;
    size_t symbol_table, symbol_count;

    // private
    TB_Slice string_table;
} TB_COFF_Parser;

// fills the parser with results from the COFF header
bool tb_coff_parse_init(TB_COFF_Parser* restrict parser);
bool tb_coff_parse_section(TB_COFF_Parser* restrict parser, size_t i, TB_ObjectSection* out_sec);

// how many symbols does this one symbol take up (basically 1 + aux symbols).
// returns 0 if error.
size_t tb_coff_parse_symbol(TB_COFF_Parser* restrict parser, size_t i, TB_ObjectSymbol* restrict out_sym);

#endif // TB_COFF_H

#ifdef TB_COFF_IMPL
#include <common.h>

#pragma pack(push, 2)
typedef struct COFF_SectionHeader {
    char name[8];
    union {
        uint32_t physical_address;
        uint32_t virtual_size;
    } misc;
    uint32_t virtual_address;
    uint32_t raw_data_size;
    uint32_t raw_data_pos;
    uint32_t pointer_to_reloc;
    uint32_t pointer_to_lineno;
    uint16_t num_reloc;
    uint16_t num_lineno;
    uint32_t characteristics;
} COFF_SectionHeader;

typedef struct COFF_FileHeader {
    uint16_t machine;
    uint16_t section_count;
    uint32_t timestamp;
    uint32_t symbol_table;
    uint32_t symbol_count;
    uint16_t optional_header_size;
    uint16_t flags;
} COFF_FileHeader;

typedef struct COFF_Symbol {
    union {
        uint8_t  short_name[8];
        uint32_t long_name[2];
    };
    uint32_t value;
    int16_t  section_number;
    uint16_t type;
    uint8_t  storage_class;
    uint8_t  aux_symbols_count;
} COFF_Symbol;

typedef struct COFF_ImageReloc {
    union {
        uint32_t VirtualAddress;
        uint32_t RelocCount;
    };
    uint32_t SymbolTableIndex;
    uint16_t Type;
} COFF_ImageReloc;
#pragma pack(pop)

// sanity checks
static_assert(sizeof(COFF_SectionHeader) == 40, "COFF Section header size != 40 bytes");
static_assert(sizeof(COFF_ImageReloc) == 10,    "COFF Image Relocation size != 10 bytes");
static_assert(sizeof(COFF_FileHeader) == 20,    "COFF File header size != 20 bytes");
static_assert(sizeof(COFF_Symbol) == 18,        "COFF Symbol size != 18 bytes");

bool tb_coff_parse_init(TB_COFF_Parser* restrict parser) {
    TB_Slice file = parser->file;

    if (file.length < sizeof(COFF_FileHeader)) return false;
    COFF_FileHeader* header = (COFF_FileHeader*) &parser->file.data[0];

    // locate string table (it spans until the end of the file)
    size_t string_table_pos = header->symbol_table + (header->symbol_count * sizeof(COFF_Symbol));
    if (file.length < string_table_pos) return false;

    parser->symbol_count = header->symbol_count;
    parser->symbol_table = header->symbol_table;
    parser->section_count = header->section_count;
    parser->string_table = (TB_Slice){
        .length = file.length - string_table_pos,
        .data   = &file.data[string_table_pos]
    };

    return true;
}

static long long tb__parse_decimal_int(size_t n, const char* str) {
    const char* end = &str[n];

    int result = 0;
    while (str != end) {
        if (*str < '0' || *str > '9') break;

        result *= 10;
        result += *str - '0';
        str++;
    }

    return result;
}

bool tb_coff_parse_section(TB_COFF_Parser* restrict parser, size_t i, TB_ObjectSection* restrict out_sec) {
    TB_Slice file = parser->file;
    size_t section_offset = sizeof(COFF_FileHeader) + (i * sizeof(COFF_SectionHeader));

    if (file.length < section_offset + sizeof(COFF_SectionHeader)) {
        return false;
    }

    COFF_SectionHeader* sec = (COFF_SectionHeader*) &file.data[section_offset];
    *out_sec = (TB_ObjectSection) { .flags = sec->characteristics };

    // Parse string table name stuff
    if (sec->name[0] == '/') {
        // string table access
        int offset = tb__parse_decimal_int(7, &sec->name[1]);
        if (file.length > offset) {
            return false;
        }

        const uint8_t* data = &parser->string_table.data[offset];
        out_sec->name = (TB_Slice){ strlen((const char*) data), data };
    } else {
        // normal inplace string
        size_t len = strlen(sec->name);
        out_sec->name = (TB_Slice){ len, (uint8_t*) sec->name };
    }

    // Parse relocations
    if (sec->num_reloc > 0) {
        out_sec->relocation_count = sec->num_reloc;
        COFF_ImageReloc* src_relocs = (COFF_ImageReloc*) &file.data[sec->pointer_to_reloc];

        TB_ObjectReloc* dst_relocs = tb_platform_heap_alloc(sec->num_reloc * sizeof(TB_ObjectReloc));
        FOREACH_N(j, 0, sec->num_reloc) {
            dst_relocs[j] = (TB_ObjectReloc){ 0 };
            switch (src_relocs[j].Type) {
                case IMAGE_REL_AMD64_ADDR32NB: dst_relocs[j].type = TB_OBJECT_RELOC_ADDR32NB; break;
                case IMAGE_REL_AMD64_ADDR32:   dst_relocs[j].type = TB_OBJECT_RELOC_ADDR32; break;
                case IMAGE_REL_AMD64_ADDR64:   dst_relocs[j].type = TB_OBJECT_RELOC_ADDR64; break;
                case IMAGE_REL_AMD64_SECREL:   dst_relocs[j].type = TB_OBJECT_RELOC_SECREL; break;
                case IMAGE_REL_AMD64_SECTION:  dst_relocs[j].type = TB_OBJECT_RELOC_SECTION; break;

                case IMAGE_REL_AMD64_REL32:
                case IMAGE_REL_AMD64_REL32_1:
                case IMAGE_REL_AMD64_REL32_2:
                case IMAGE_REL_AMD64_REL32_3:
                case IMAGE_REL_AMD64_REL32_4:
                case IMAGE_REL_AMD64_REL32_5:
                dst_relocs[j].type = TB_OBJECT_RELOC_REL32;
                break;

                default: tb_todo();
            }

            if (src_relocs[j].Type >= IMAGE_REL_AMD64_REL32 && src_relocs[j].Type <= IMAGE_REL_AMD64_REL32_5) {
                dst_relocs[j].addend = 4 + (src_relocs[j].Type - IMAGE_REL_AMD64_REL32);
            }

            dst_relocs[j].symbol_index = src_relocs[j].SymbolTableIndex;
            dst_relocs[j].virtual_address = src_relocs[j].VirtualAddress;
        }

        out_sec->relocations = dst_relocs;
    }

    // Parse virtual region
    out_sec->virtual_address = sec->virtual_address;
    out_sec->virtual_size = sec->misc.virtual_size;

    // Read raw data (if applies)
    if (sec->raw_data_size) {
        assert(sec->raw_data_pos + sec->raw_data_size < file.length);
        out_sec->raw_data = (TB_Slice){ sec->raw_data_size, &file.data[sec->raw_data_pos] };
    }

    return true;
}

TB_ObjectSymbolType classify_symbol_type(uint16_t st_class) {
    switch (st_class) {
        case 2:    return TB_OBJECT_SYMBOL_EXTERN;
        case 3:    return TB_OBJECT_SYMBOL_STATIC;
        case 6:    return TB_OBJECT_SYMBOL_STATIC;
        case 0x68: return TB_OBJECT_SYMBOL_SECTION;
        case 0x69: return TB_OBJECT_SYMBOL_WEAK_EXTERN;
        default: return TB_OBJECT_SYMBOL_UNKNOWN;
    }
}

size_t tb_coff_parse_symbol(TB_COFF_Parser* restrict parser, size_t i, TB_ObjectSymbol* restrict out_sym) {
    TB_Slice file = parser->file;
    size_t symbol_offset = parser->symbol_table + (i * sizeof(COFF_Symbol));

    if (file.length < symbol_offset + sizeof(COFF_Symbol)) {
        return 0;
    }

    COFF_Symbol* sym = (COFF_Symbol*) &file.data[symbol_offset];
    *out_sym = (TB_ObjectSymbol) {
        .ordinal = i,
        .type = classify_symbol_type(sym->storage_class),
        .section_num = sym->section_number,
        .value = sym->value
    };

    // Parse string table name stuff
    if (sym->long_name[0] == 0) {
        // string table access (read a cstring)
        // TODO(NeGate): bounds check this
        const uint8_t* data = &parser->string_table.data[sym->long_name[1]];
        out_sym->name = (TB_Slice){ strlen((const char*) data), data };
    } else {
        // normal inplace string
        size_t len = 1;
        const char* name = (const char*) sym->short_name;
        while (len < 8 && name[len] != 0) {
            len++;
        }
        out_sym->name = (TB_Slice){ len, sym->short_name };
    }

    // TODO(NeGate): Process aux symbols
    if (sym->aux_symbols_count) {
        out_sym->extra = &sym[1];

        // FOREACH_N(j, 0, sym->aux_symbols_count) {}
    }

    return sym->aux_symbols_count + 1;
}

#endif // TB_COFF_IMPL
