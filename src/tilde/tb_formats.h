// This handles the generalized executable/object format parsing stuff
#ifndef TB_OBJECT_H
#define TB_OBJECT_H

#include <stdint.h>
#include <stddef.h>

typedef enum {
    TB_OBJECT_RELOC_NONE, // how?

    // Target independent
    TB_OBJECT_RELOC_ADDR32,
    TB_OBJECT_RELOC_ADDR64, // unsupported on 32bit platforms
    TB_OBJECT_RELOC_SECREL,
    TB_OBJECT_RELOC_SECTION,

    // COFF only
    TB_OBJECT_RELOC_ADDR32NB, // Relative virtual address

    // x64 only
    TB_OBJECT_RELOC_REL32,    // relative 32bit displacement

    // Aarch64 only
    TB_OBJECT_RELOC_BRANCH26, // 26bit displacement for B and BL instructions
    TB_OBJECT_RELOC_REL21,    // for ADR instructions

    // TODO(NeGate): fill in the rest of this later
} TB_ObjectRelocType;

typedef struct {
    TB_ObjectRelocType type;
    uint32_t symbol_index;
    size_t virtual_address;
    size_t addend;
} TB_ObjectReloc;

typedef enum {
    TB_OBJECT_SYMBOL_UNKNOWN,
    TB_OBJECT_SYMBOL_EXTERN,      // exported
    TB_OBJECT_SYMBOL_WEAK_EXTERN, // weak
    TB_OBJECT_SYMBOL_IMPORT,      // forward decl
    TB_OBJECT_SYMBOL_STATIC,      // local
    TB_OBJECT_SYMBOL_SECTION,     // local
} TB_ObjectSymbolType;

typedef struct {
    TB_ObjectSymbolType type;
    int section_num;

    uint32_t ordinal;
    uint32_t value;

    TB_Slice name;

    // for COFF, this is the auxillary
    void* extra;

    // this is zeroed out by the loader and left for the user to do crap with
    void* user_data;
} TB_ObjectSymbol;

typedef struct {
    TB_Slice name;
    uint32_t flags;

    size_t virtual_address;
    size_t virtual_size;

    // You can have a virtual size without having a raw
    // data size, that's how the BSS section works
    TB_Slice raw_data;

    size_t relocation_count;
    TB_ObjectReloc* relocations;

    // this is zeroed out by the loader and left for the user to do crap with
    void* user_data;
} TB_ObjectSection;

typedef enum {
    TB_OBJECT_FILE_UNKNOWN,

    TB_OBJECT_FILE_COFF,
    TB_OBJECT_FILE_ELF64
} TB_ObjectFileType;

typedef struct {
    TB_ObjectFileType type;
    TB_Arch           arch;

    TB_Slice          name;
    TB_Slice          ar_name;

    size_t           symbol_count;
    TB_ObjectSymbol* symbols;

    size_t           section_count;
    TB_ObjectSection sections[];
} TB_ObjectFile;

////////////////////////////////
// Archive parser
////////////////////////////////
typedef struct {
    TB_Slice name;

    // if import_name is empty, we're dealing with an object file
    TB_Slice import_name;
    uint16_t ordinal;

    TB_Slice content;
} TB_ArchiveEntry;

typedef struct {
    TB_Slice file;
    size_t pos;

    size_t member_count;
    uint32_t* members;

    size_t symbol_count;
    uint16_t* symbols;

    TB_Slice strtbl;
} TB_ArchiveFileParser;

// We do this to parse the header
bool tb_archive_parse(TB_Slice file, TB_ArchiveFileParser* restrict out_parser);
// After that we can enumerate any symbol entries to resolve imports
size_t tb_archive_parse_entries(TB_ArchiveFileParser* restrict parser, size_t i, size_t count, TB_ArchiveEntry* out_entry);

#endif // TB_OBJECT_H
