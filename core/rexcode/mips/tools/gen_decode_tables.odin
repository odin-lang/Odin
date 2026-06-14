package main

// =============================================================================
// MIPS DECODE-TABLE GENERATOR
// =============================================================================
//
// Walks the encoder's ENCODING_TABLE (the single source of truth) and emits
// `decoding_tables.odin` -- a flat Decode_Entry array plus a hierarchical set
// of Decode_Index tables so the runtime decoder can pinpoint candidate
// entries in O(1) average and never scan more than a handful of forms.
//
// Run with:   cd mips && odin run tools/gen_decode_tables.odin -file
// Output:     ./decoding_tables.odin (current working directory)
//
// Dispatch tree (top to bottom):
//
//   primary = bits[31:26]   -- 64 buckets, indexed by primary opcode
//
//   For the five dense primary opcodes we add a secondary table:
//
//     0x00 SPECIAL   ->  DECODE_INDEX_SPECIAL   [funct=bits[5:0]]
//     0x01 REGIMM    ->  DECODE_INDEX_REGIMM    [rt=bits[20:16]]
//     0x11 COP1      ->  DECODE_INDEX_COP1      [rs(fmt)=bits[25:21]]
//     0x1C SPECIAL2  ->  DECODE_INDEX_SPECIAL2  [funct=bits[5:0]]
//     0x1F SPECIAL3  ->  DECODE_INDEX_SPECIAL3  [funct=bits[5:0]]
//
// Everything else (J-type, normal I-type, COP0, COP2) sits in
// DECODE_INDEX_PRIMARY and is linearly scanned within its primary bucket
// (worst case ~25 entries for COP2/GTE).
//
// Within every Decode_Index range, entries are sorted by mask-popcount
// descending so the most-specific encoding form is checked first. That
// makes the linear scan return the right answer when an instruction
// would match both a strict form (e.g. NOP = SLL $0,$0,0) and a relaxed
// one (general SLL).

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:math/bits"

import mips "../"

Entry :: struct {
	mnemonic:   mips.Mnemonic,
	ops:        [4]mips.Operand_Type,
	enc:        [4]mips.Operand_Encoding,
	bits:       u32,
	mask:       u32,
	feature: mips.Feature,
	flags:      mips.Encoding_Flags,
	primary_op: u8,
	sub_key:    u8,
}

Range :: struct {
	start: u16,
	count: u16,
}

main :: proc() {
	fmt.println("Generating MIPS decoder tables from ENCODING_TABLE...")

	// ---- 1. Collect all encoding forms ------------------------------------
	all: [dynamic]Entry
	defer delete(all)

	for mnem in mips.Mnemonic {
		forms := mips.ENCODING_TABLE[mnem]
		for f in forms {
			primary := u8((f.bits >> 26) & 0x3F)
			sub: u8
			switch primary {
			case 0x00, 0x1C, 0x1F:
				sub = u8(f.bits & 0x3F)          // funct
			case 0x01:
				sub = u8((f.bits >> 16) & 0x1F)  // rt
			case 0x11:
				sub = u8((f.bits >> 21) & 0x1F)  // rs (fmt)
			}
			append(&all, Entry{
				mnemonic   = mnem,
				ops        = f.ops,
				enc        = f.enc,
				bits       = f.bits,
				mask       = f.mask,
				feature   = f.feature,
				flags      = f.flags,
				primary_op = primary,
				sub_key    = sub,
			})
		}
	}

	// ---- 2. Sort: primary asc, sub_key asc, mask-popcount desc -----------
	slice.sort_by(all[:], proc(a, b: Entry) -> bool {
		if a.primary_op != b.primary_op { return a.primary_op < b.primary_op }
		if a.sub_key    != b.sub_key    { return a.sub_key    < b.sub_key    }
		ac := bits.count_ones(a.mask)
		bc := bits.count_ones(b.mask)
		if ac != bc { return ac > bc }
		// Stable tie-break by mnemonic for reproducible output.
		return u16(a.mnemonic) < u16(b.mnemonic)
	})

	// ---- 3. Compute indexes ------------------------------------------------
	primary_idx:  [64]Range
	special_idx:  [64]Range
	regimm_idx:   [32]Range
	cop1_idx:     [32]Range
	special2_idx: [64]Range
	special3_idx: [64]Range

	for e, i in all {
		push_range(&primary_idx[e.primary_op], u16(i))

		switch e.primary_op {
		case 0x00: push_range(&special_idx [e.sub_key], u16(i))
		case 0x01: push_range(&regimm_idx  [e.sub_key], u16(i))
		case 0x11: push_range(&cop1_idx    [e.sub_key], u16(i))
		case 0x1C: push_range(&special2_idx[e.sub_key], u16(i))
		case 0x1F: push_range(&special3_idx[e.sub_key], u16(i))
		}
	}

	// ---- 4. Emit the file --------------------------------------------------
	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)

	emit_header(&sb)
	emit_entries(&sb, all[:])
	fmt.sbprintfln(&sb, "")
	emit_range_table(&sb, "DECODE_INDEX_PRIMARY",  primary_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_SPECIAL",  special_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_REGIMM",   regimm_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_COP1",     cop1_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_SPECIAL2", special2_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_SPECIAL3", special3_idx[:])

	output := strings.to_string(sb)
	err := os.write_entire_file("decoding_tables.odin", transmute([]u8)output)
	if err != nil {
		fmt.eprintfln("FAILED to write decoding_tables.odin: %v", err)
		os.exit(1)
	}

	// Stats for the human.
	total := len(all)
	max_primary, max_special, max_regimm, max_cop1, max_special2, max_special3: u16
	for r in primary_idx  { if r.count > max_primary  { max_primary  = r.count } }
	for r in special_idx  { if r.count > max_special  { max_special  = r.count } }
	for r in regimm_idx   { if r.count > max_regimm   { max_regimm   = r.count } }
	for r in cop1_idx     { if r.count > max_cop1     { max_cop1     = r.count } }
	for r in special2_idx { if r.count > max_special2 { max_special2 = r.count } }
	for r in special3_idx { if r.count > max_special3 { max_special3 = r.count } }

	fmt.printfln("OK -- %d entries", total)
	fmt.printfln("     max bucket sizes:  primary=%d  special=%d  regimm=%d  cop1=%d  special2=%d  special3=%d",
				 max_primary, max_special, max_regimm, max_cop1, max_special2, max_special3)
}

push_range :: proc(r: ^Range, i: u16) {
	if r.count == 0 { r.start = i }
	r.count += 1
}

// =============================================================================
// emit helpers
// =============================================================================

emit_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_mips

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_decode_tables.odin from ENCODING_TABLE.
// Regenerate with:  cd mips && odin run tools/gen_decode_tables.odin -file
//

Decode_Entry :: struct #packed {
	mnemonic: Mnemonic,            // 2
	ops:      [4]Operand_Type,     // 4
	enc:      [4]Operand_Encoding, // 4
	bits:     u32,                 // 4
	mask:     u32,                 // 4
	feature: Feature,                 // 1
	flags:    Encoding_Flags,      // 1
}
#assert(size_of(Decode_Entry) == 20)

Decode_Index :: struct #packed {
	start: u16,
	count: u16,
}
#assert(size_of(Decode_Index) == 4)

`)
}

emit_entries :: proc(sb: ^strings.Builder, entries: []Entry) {
	fmt.sbprintfln(sb, "")
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintfln(sb, "DECODE_ENTRIES := [%d]Decode_Entry{{", len(entries))
	for e in entries {
		flags_str := encode_flags_literal(e.flags)
		fmt.sbprintfln(sb,
			"\t{{ .%v, {{.%v,.%v,.%v,.%v}}, {{.%v,.%v,.%v,.%v}}, 0x%08X, 0x%08X, .%v, {{%s}} }},",
			e.mnemonic,
			e.ops[0], e.ops[1], e.ops[2], e.ops[3],
			e.enc[0], e.enc[1], e.enc[2], e.enc[3],
			e.bits, e.mask, e.feature, flags_str)
	}
	strings.write_string(sb, "}")
}

encode_flags_literal :: proc(f: mips.Encoding_Flags) -> string {
	sb: strings.Builder
	strings.builder_init(&sb)
	first := true
	write := proc(sb: ^strings.Builder, first: ^bool, s: string) {
		if !first^ { strings.write_string(sb, ", ") }
		strings.write_string(sb, s)
		first^ = false
	}
	if f.delay_slot  { write(&sb, &first, "delay_slot=true")  }
	if f.likely      { write(&sb, &first, "likely=true")      }
	if f.only_64     { write(&sb, &first, "only_64=true")     }
	if f.writes_hilo { write(&sb, &first, "writes_hilo=true") }
	if f.compact     { write(&sb, &first, "compact=true")     }
	return strings.to_string(sb)
}

emit_range_table :: proc(sb: ^strings.Builder, name: string, ranges: []Range) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintfln(sb, "%s := [%d]Decode_Index{{", name, len(ranges))
	for r, i in ranges {
		if r.count != 0 {
			fmt.sbprintfln(sb, "\t0x%02X = {{%d, %d}},", i, r.start, r.count)
		}
	}
	strings.write_string(sb, "}\n\n")
}
