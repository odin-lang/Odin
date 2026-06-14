package main

// =============================================================================
// N64 RSP DECODE-TABLE GENERATOR
// =============================================================================
//
// Walks rsp.ENCODING_TABLE and emits `decoding_tables.odin`. Same shape as
// mips/tools/gen_decode_tables.odin, with an RSP-specific dispatch tree:
//
//   primary opcode               -> DECODE_INDEX_PRIMARY  [64]
//     0x00 SPECIAL    -> by funct -> DECODE_INDEX_SPECIAL [64]
//     0x01 REGIMM     -> by rt    -> DECODE_INDEX_REGIMM  [32]
//     0x12 COP2       -> by funct -> DECODE_INDEX_COP2    [64]
//                        (handles both MFC2/MTC2/CFC2/CTC2 with CO=0 and
//                         all VU ops with CO=1; funct=0 has 5 candidates
//                         which we linearly scan -- the CO bit lives in
//                         the static mask so they disambiguate cleanly.)
//     0x32 LWC2       -> by op2   -> DECODE_INDEX_LWC2    [32]
//     0x3A SWC2       -> by op2   -> DECODE_INDEX_SWC2    [32]
//
// Within each Decode_Index range, entries are sorted by mask-popcount
// descending so the most-specific encoding form is matched first.
//
// Run with:  cd rsp && odin run tools/gen_decode_tables.odin -file
// Output:    ./decoding_tables.odin

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:math/bits"

import rsp "../"

Entry :: struct {
	mnemonic:   rsp.Mnemonic,
	ops:        [4]rsp.Operand_Type,
	enc:        [4]rsp.Operand_Encoding,
	bits:       u32,
	mask:       u32,
	feature: rsp.Feature,
	flags:      rsp.Encoding_Flags,
	primary_op: u8,
	sub_key:    u8,
}

Range :: struct {
	start: u16,
	count: u16,
}

main :: proc() {
	fmt.println("Generating RSP decoder tables from ENCODING_TABLE...")

	all: [dynamic]Entry
	defer delete(all)

	for mnem in rsp.Mnemonic {
		forms := rsp.ENCODING_TABLE[mnem]
		for f in forms {
			primary := u8((f.bits >> 26) & 0x3F)
			sub: u8
			switch primary {
			case 0x00, 0x12:
				sub = u8(f.bits & 0x3F)              // funct
			case 0x01:
				sub = u8((f.bits >> 16) & 0x1F)      // rt
			case 0x32, 0x3A:
				sub = u8((f.bits >> 11) & 0x1F)      // op2
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

	slice.sort_by(all[:], proc(a, b: Entry) -> bool {
		if a.primary_op != b.primary_op { return a.primary_op < b.primary_op }
		if a.sub_key    != b.sub_key    { return a.sub_key    < b.sub_key    }
		ac := bits.count_ones(a.mask)
		bc := bits.count_ones(b.mask)
		if ac != bc { return ac > bc }
		return u16(a.mnemonic) < u16(b.mnemonic)
	})

	primary_idx: [64]Range
	special_idx: [64]Range
	regimm_idx:  [32]Range
	cop2_idx:    [64]Range
	lwc2_idx:    [32]Range
	swc2_idx:    [32]Range

	for e, i in all {
		push_range(&primary_idx[e.primary_op], u16(i))
		switch e.primary_op {
		case 0x00: push_range(&special_idx[e.sub_key], u16(i))
		case 0x01: push_range(&regimm_idx [e.sub_key], u16(i))
		case 0x12: push_range(&cop2_idx   [e.sub_key], u16(i))
		case 0x32: push_range(&lwc2_idx   [e.sub_key], u16(i))
		case 0x3A: push_range(&swc2_idx   [e.sub_key], u16(i))
		}
	}

	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)

	emit_header(&sb)
	emit_entries(&sb, all[:])
	emit_range_table(&sb, "DECODE_INDEX_PRIMARY", primary_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_SPECIAL", special_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_REGIMM",  regimm_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_COP2",    cop2_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_LWC2",    lwc2_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_SWC2",    swc2_idx[:])

	output := strings.to_string(sb)
	err := os.write_entire_file("decoding_tables.odin", transmute([]u8)output)
	if err != nil {
		fmt.eprintfln("FAILED to write decoding_tables.odin: %v", err)
		os.exit(1)
	}

	max_primary, max_special, max_regimm, max_cop2, max_lwc2, max_swc2: u16
	for r in primary_idx { if r.count > max_primary { max_primary = r.count } }
	for r in special_idx { if r.count > max_special { max_special = r.count } }
	for r in regimm_idx  { if r.count > max_regimm  { max_regimm  = r.count } }
	for r in cop2_idx    { if r.count > max_cop2    { max_cop2    = r.count } }
	for r in lwc2_idx    { if r.count > max_lwc2    { max_lwc2    = r.count } }
	for r in swc2_idx    { if r.count > max_swc2    { max_swc2    = r.count } }

	fmt.printfln("OK -- %d entries", len(all))
	fmt.printfln("     max bucket sizes:  primary=%d  special=%d  regimm=%d  cop2=%d  lwc2=%d  swc2=%d",
				 max_primary, max_special, max_regimm, max_cop2, max_lwc2, max_swc2)
}

push_range :: proc(r: ^Range, i: u16) {
	if r.count == 0 { r.start = i }
	r.count += 1
}

emit_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_rsp

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_decode_tables.odin from ENCODING_TABLE.
// Regenerate with:  cd rsp && odin run tools/gen_decode_tables.odin -file
//

Decode_Entry :: struct #packed {
	mnemonic: Mnemonic,
	ops:      [4]Operand_Type,
	enc:      [4]Operand_Encoding,
	bits:     u32,
	mask:     u32,
	feature: Feature,
	flags:    Encoding_Flags,
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
	strings.write_string(sb, "}\n\n")
}

encode_flags_literal :: proc(f: rsp.Encoding_Flags) -> string {
	sb: strings.Builder
	strings.builder_init(&sb)
	first := true
	write := proc(sb: ^strings.Builder, first: ^bool, s: string) {
		if !first^ { strings.write_string(sb, ", ") }
		strings.write_string(sb, s)
		first^ = false
	}
	if f.delay_slot { write(&sb, &first, "delay_slot=true") }
	if f.likely     { write(&sb, &first, "likely=true")     }
	return strings.to_string(sb)
}

emit_range_table :: proc(sb: ^strings.Builder, name: string, ranges: []Range) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintfln(sb, "%s := [%d]Decode_Index{{", name, len(ranges))
	for r, i in ranges {
		if r.count == 0 {
			fmt.sbprintfln(sb, "    /* [%2d] */ {{0, 0}},", i)
		} else {
			fmt.sbprintfln(sb, "    /* [%2d] */ {{%d, %d}},", i, r.start, r.count)
		}
	}
	strings.write_string(sb, "}\n\n")
}
