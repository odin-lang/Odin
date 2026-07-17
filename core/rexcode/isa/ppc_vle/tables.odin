// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle

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
	start: u32,
	count: u16,
	_:     u16,
}
#assert(size_of(Decode_Index) == 8)

// -----------------------------------------------------------------------------
// Loaded tables (rodata, embedded from tables/*.bin at compile time)
// -----------------------------------------------------------------------------

@(rodata) ENCODE_FORMS       := #load("tables/ppc_vle.encode_forms.bin", []Encoding)
@(rodata) ENCODE_RUNS        := #load("tables/ppc_vle.encode_runs.bin",  []Encode_Run)
@(rodata) DECODE_ENTRIES     := #load("tables/ppc_vle.entries.bin",      []Decode_Entry)
@(rodata) DECODE_FORM_IDX    := #load("tables/ppc_vle.form_idx.bin",     []u16)
@(rodata) DECODE_BUCKET_LIST := #load("tables/ppc_vle.bucket_list.bin",  []u16)
@(rodata) DECODE_INDEX_SHORT := #load("tables/ppc_vle.idx_short.bin",    []Decode_Index)
@(rodata) DECODE_INDEX_LONG  := #load("tables/ppc_vle.idx_long.bin",     []Decode_Index)

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
