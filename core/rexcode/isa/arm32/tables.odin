// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Loads the flat binary encode/decode tables into @(rodata). Produced by tablegen:
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
	start: u32,
	count: u32,
}

Decode_Entry :: struct #packed {
	mnemonic: Mnemonic,            // 2
	ops:      [4]Operand_Type,     // 4
	enc:      [4]Operand_Encoding, // 4
	bits:     u32,                 // 4
	mask:     u32,                 // 4
	feature:  Feature,             // 1
	mode:     Mode,                // 1
	flags:    Encoding_Flags,      // 1
}
#assert(size_of(Decode_Entry) == 21)

Decode_Index :: struct #packed {
	start: u16,
	count: u16,
}
#assert(size_of(Decode_Index) == 4)

DECODE_T32_SUB_BUCKETS :: 32

// -----------------------------------------------------------------------------
// Loaded tables (rodata, embedded from tables/*.bin at compile time)
// -----------------------------------------------------------------------------

@(rodata) ENCODE_FORMS         := #load("tables/arm32.encode_forms.bin", []Encoding)
@(rodata) ENCODE_RUNS          := #load("tables/arm32.encode_runs.bin",  []Encode_Run)
@(rodata) DECODE_ENTRIES       := #load("tables/arm32.entries.bin",      []Decode_Entry)
@(rodata) DECODE_FORM_IDX      := #load("tables/arm32.form_idx.bin",     []u16)
@(rodata) DECODE_BUCKET_LIST   := #load("tables/arm32.bucket_list.bin",  []u16)
@(rodata) DECODE_INDEX_A32     := #load("tables/arm32.idx_a32.bin",      []Decode_Index)
@(rodata) DECODE_INDEX_T32     := #load("tables/arm32.idx_t32.bin",      []Decode_Index)
@(rodata) DECODE_INDEX_T16     := #load("tables/arm32.idx_t16.bin",      []Decode_Index)
@(rodata) DECODE_INDEX_T32_SUB := #load("tables/arm32.idx_t32_sub.bin",  []Decode_Index)

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
