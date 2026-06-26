// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Loads the flat binary encode/decode tables into @(rodata) and exposes the
// accessors the encoder/decoder drive. Produced by tablegen:
//
//   odin run tablegen            # Stage A: ENCODING_TABLE -> generated/ + this file
//   odin run tablegen/generated  # Stage B: typed Odin literals -> tables/*.bin
//
// The .bin blobs are raw, host-endian, packed struct images.

// -----------------------------------------------------------------------------
// Subsidiary table types (generated scaffolding)
// -----------------------------------------------------------------------------

// Companion run index: ENCODE_RUNS[mnemonic] -> contiguous run in ENCODE_FORMS.
Encode_Run :: struct {
	start: u32, // start index in ENCODE_FORMS
	count: u32, // number of forms for this mnemonic
}

// Precomputed extraction of mod, reg, rm fields from a ModR/M byte.
ModRM_Info :: struct #packed {
	mod:       u8,
	reg:       u8,
	rm:        u8,
	has_sib:   bool,
	disp_size: u8,
}

// Precomputed extraction of scale, index, base fields from a SIB byte.
SIB_Info :: struct #packed {
	scale: u8,
	index: u8,
	base:  u8,
}

// Information needed to decode an instruction given its opcode bytes.
Decode_Entry :: struct {
	esc:      Escape,
	prefix:   u8,
	opcode:   u8,
	ext:      u8,
	mnemonic: Mnemonic,
	ops:      [4]Operand_Type,
	enc:      [4]Operand_Encoding,
	flags:    Encoding_Flags,
}

VEX_Decode_Entry :: struct {
	esc:      Escape,
	prefix:   u8,
	opcode:   u8,
	ext:      u8,
	vex_w:    VEX_W,
	vex_l:    VEX_L,
	mnemonic: Mnemonic,
	ops:      [4]Operand_Type,
	enc:      [4]Operand_Encoding,
	flags:    Encoding_Flags,
}

// (start, count) into a *_DECODE_ENTRIES array. Index tables are stored flat:
// a logical [4][256] is loaded as [1024]; address with `didx`.
Decode_Index :: struct {
	start: u16,
	count: u8,
}

// -----------------------------------------------------------------------------
// Loaded tables (rodata, embedded from tables/*.bin at compile time)
// -----------------------------------------------------------------------------

@(rodata) ENCODE_FORMS          := #load("tables/x86.encode_forms.bin",   []Encoding)
@(rodata) ENCODE_RUNS           := #load("tables/x86.encode_runs.bin",    []Encode_Run)
@(rodata) ENCODE_RECIPES        := #load("tables/x86.encode_recipes.bin", []Form_Recipe)
@(rodata) MODRM_TABLE           := #load("tables/x86.modrm.bin",          []ModRM_Info)
@(rodata) SIB_TABLE             := #load("tables/x86.sib.bin",            []SIB_Info)
@(rodata) LEGACY_DECODE_ENTRIES := #load("tables/x86.legacy.bin",         []Decode_Entry)
@(rodata) VEX_DECODE_ENTRIES    := #load("tables/x86.vex.bin",            []VEX_Decode_Entry)
@(rodata) EVEX_DECODE_ENTRIES   := #load("tables/x86.evex.bin",           []VEX_Decode_Entry)
@(rodata) DECODE_INDEX_LEGACY   := #load("tables/x86.idx_legacy.bin",     []Decode_Index)
@(rodata) DECODE_INDEX_ESC_0F   := #load("tables/x86.idx_0f.bin",         []Decode_Index)
@(rodata) DECODE_INDEX_ESC_0F38 := #load("tables/x86.idx_0f38.bin",       []Decode_Index)
@(rodata) DECODE_INDEX_ESC_0F3A := #load("tables/x86.idx_0f3a.bin",       []Decode_Index)
@(rodata) VEX_INDEX_0F          := #load("tables/x86.vex_idx_0f.bin",     []Decode_Index)
@(rodata) VEX_INDEX_0F38        := #load("tables/x86.vex_idx_0f38.bin",   []Decode_Index)
@(rodata) VEX_INDEX_0F3A        := #load("tables/x86.vex_idx_0f3a.bin",   []Decode_Index)
@(rodata) EVEX_INDEX_0F         := #load("tables/x86.evex_idx_0f.bin",    []Decode_Index)
@(rodata) EVEX_INDEX_0F38       := #load("tables/x86.evex_idx_0f38.bin",  []Decode_Index)
@(rodata) EVEX_INDEX_0F3A       := #load("tables/x86.evex_idx_0f3a.bin",  []Decode_Index)

// -----------------------------------------------------------------------------
// Accessors
// -----------------------------------------------------------------------------

// Per-mnemonic encode forms: the run of ENCODE_FORMS belonging to `m`.
// Replaces the old ENCODING_TABLE[m] slice; the returned view is into rodata.
@(private, require_results)
encoding_forms :: #force_inline proc "contextless" (m: Mnemonic) -> []Encoding {
	r := ENCODE_RUNS[u16(m)]
	return ENCODE_FORMS[r.start:][:r.count]
}

// Flat [prefix][opcode] lookup into a logical [4][256] index table.
@(private, require_results)
didx :: #force_inline proc "contextless" (t: []Decode_Index, prefix, opcode: u8) -> Decode_Index {
	return t[(int(prefix) << 8) | int(opcode)]
}
