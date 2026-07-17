// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

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

// One reverse-decode entry. Differs from Encoding: carries the instruction's
// total byte length and only [3] operand slots (no 6502 instruction uses 4).
Decode_Entry :: struct #packed {
	mnemonic: Mnemonic,            // 2
	ops:      [3]Operand_Type,     // 3
	enc:      [3]Operand_Encoding, // 3
	opcode:   u8,                  // 1
	length:   u8,                  // 1
	cpu:      CPU,                 // 1
	flags:    Encoding_Flags,      // 1
}
#assert(size_of(Decode_Entry) == 12)

Decode_Index :: struct #packed {
	start: u16,
	count: u16,
}
#assert(size_of(Decode_Index) == 4)

// -----------------------------------------------------------------------------
// Loaded tables (rodata, embedded from tables/*.bin at compile time)
// -----------------------------------------------------------------------------

@(rodata) ENCODE_FORMS        := #load("tables/mos6502.encode_forms.bin", []Encoding)
@(rodata) ENCODE_RUNS         := #load("tables/mos6502.encode_runs.bin",  []Encode_Run)
@(rodata) DECODE_ENTRIES      := #load("tables/mos6502.entries.bin",      []Decode_Entry)
@(rodata) DECODE_INDEX_OPCODE := #load("tables/mos6502.idx_opcode.bin",   []Decode_Index)

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
