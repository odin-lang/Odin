// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

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
	flags:    Encoding_Flags,      // 1
}
#assert(size_of(Decode_Entry) == 20)

Decode_Index :: struct #packed {
	start: u16,
	count: u16,
}
#assert(size_of(Decode_Index) == 4)

// -----------------------------------------------------------------------------
// Loaded tables (rodata, embedded from tables/*.bin at compile time)
// -----------------------------------------------------------------------------

@(rodata) ENCODE_FORMS     := #load("tables/arm64.encode_forms.bin", []Encoding)
@(rodata) ENCODE_RUNS      := #load("tables/arm64.encode_runs.bin",  []Encode_Run)
@(rodata) DECODE_ENTRIES   := #load("tables/arm64.entries.bin",      []Decode_Entry)
@(rodata) DECODE_INDEX_OP0 := #load("tables/arm64.idx_op0.bin",      []Decode_Index)

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
