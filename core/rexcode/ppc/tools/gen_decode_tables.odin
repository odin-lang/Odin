package main

// =============================================================================
// PowerPC DECODE-TABLE GENERATOR
// =============================================================================
//
// Two-level dispatch (one DECODE_ENTRIES array, two index tables):
//
//   Primary (64 buckets):
//     key = bits[26:31] of the instruction word (6 bits = primary opcode).
//     Covers all PowerPC instructions including 8-byte prefixed (whose SUFFIX
//     word's primary opcode is also used here — the suffix's primary is
//     distinct from the prefix's primary=1).
//
//   Secondary (64 * 256 = 16384 buckets):
//     key = primary * 256 + bits[1:8] (low 8 bits of the XO field, skipping
//     the Rc bit at position 0). Most PPC entries have XO covered by the
//     mask in bits 1..10, so secondary buckets are sparsely populated and
//     scan length is small.
//
// At decode time:
//   1. Compute primary key. If primary == 1 (prefixed-instruction prefix),
//      the next 4 bytes are the SUFFIX word and we redo dispatch on the
//      suffix's primary.
//   2. Compute secondary key. If DECODE_INDEX_SUB[sub_key].count > 0, scan
//      that bucket. Else fall back to DECODE_INDEX_PRIMARY[primary].
//   3. Within a bucket, entries are sorted by mask popcount descending so
//      the most-specific match wins on first hit.
//
// Run with:  cd ppc && odin run tools/gen_decode_tables.odin -file
// Output:    ./decoding_tables.odin

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:math/bits"

import p ".."

Entry :: struct {
	mnemonic: p.Mnemonic,
	ops:      [4]p.Operand_Type,
	enc:      [4]p.Operand_Encoding,
	bits:     u32,
	mask:     u32,
	feature:  p.Feature,
	mode:     p.Mode,
	flags:    p.Encoding_Flags,
	form_idx: u16,
}

Range :: struct {
	start: u32,
	count: u16,
	_:     u16,
}

PRIMARY_BUCKETS :: 64       // bits[26:31] of word
SUB_BITS        :: 8        // bits[1:8] of word (low XO bits, skipping Rc)
SUB_BUCKETS     :: PRIMARY_BUCKETS * (1 << SUB_BITS)   // 64 * 256 = 16384

Pair :: struct { bucket: u32, entry_idx: u16 }

main :: proc() {
	fmt.println("Generating PowerPC decoder tables from ENCODING_TABLE...")

	all: [dynamic]Entry
	defer delete(all)

	for mn in p.Mnemonic {
		for f, fi in p.ENCODING_TABLE[mn] {
			e := Entry{
				mnemonic = mn,
				ops      = f.ops,
				enc      = f.enc,
				bits     = f.bits,
				mask     = f.mask,
				feature  = f.feature,
				mode     = f.mode,
				flags    = f.flags,
				form_idx = u16(fi),
			}
			append(&all, e)
		}
	}

	// Sort the global entries array: by primary opcode, then mask popcount
	// descending so within-bucket scan picks the most specific first.
	slice.sort_by(all[:], proc(x, y: Entry) -> bool {
		px := (x.bits >> 26) & 0x3F
		py := (y.bits >> 26) & 0x3F
		if px != py { return px < py }
		xc := bits.count_ones(x.mask)
		yc := bits.count_ones(y.mask)
		if xc != yc { return xc > yc }
		return u16(x.mnemonic) < u16(y.mnemonic)
	})

	// For each entry, enumerate the (primary, sub-key) pairs it can match.
	// enumerate_keys handles variable bits in the bucket-key field.
	primary_pairs: [dynamic]Pair
	sub_pairs:     [dynamic]Pair
	defer delete(primary_pairs); defer delete(sub_pairs)

	keys: [dynamic]u32
	defer delete(keys)

	for e, i in all {
		// Primary key
		enumerate_keys(e.bits, e.mask, 26, 6, &keys)
		for k in keys {
			append(&primary_pairs, Pair{bucket = k, entry_idx = u16(i)})
		}

		// Sub key: primary << SUB_BITS | bits[1..SUB_BITS+1)
		// (enumerate_keys handles variable bits in both ranges; we combine
		// primary and XO low bits into a single 14-bit key.)
		prim_keys: [dynamic]u32
		sub_only:  [dynamic]u32
		defer delete(prim_keys); defer delete(sub_only)
		enumerate_keys(e.bits, e.mask, 26, 6, &prim_keys)
		enumerate_keys(e.bits, e.mask, 1,  SUB_BITS, &sub_only)
		for pk in prim_keys {
			for sk in sub_only {
				key := pk * (1 << SUB_BITS) + sk
				append(&sub_pairs, Pair{bucket = key, entry_idx = u16(i)})
			}
		}
	}

	// Re-sort pair lists: primary order, then mask popcount descending
	rebuild :: proc(pairs: ^[dynamic]Pair, all: []Entry) {
		Sort_Pair :: struct { sort_key: u64, entry_idx: u16, bucket: u32 }
		sortable := make([dynamic]Sort_Pair, 0, len(pairs), context.temp_allocator)
		for pp in pairs^ {
			e := all[pp.entry_idx]
			pop := u64(bits.count_ones(e.mask))
			// (bucket << 40) | ((63 - pop) << 32) | mnemonic
			key := (u64(pp.bucket) << 40) | ((63 - pop) << 32) | u64(e.mnemonic)
			append(&sortable, Sort_Pair{sort_key = key, entry_idx = pp.entry_idx, bucket = pp.bucket})
		}
		slice.sort_by_key(sortable[:], proc(s: Sort_Pair) -> u64 { return s.sort_key })
		clear(pairs)
		for s in sortable { append(pairs, Pair{bucket = s.bucket, entry_idx = s.entry_idx}) }
	}
	rebuild(&primary_pairs, all[:])
	rebuild(&sub_pairs,     all[:])

	// Build flat u16 dispatch list. Each bucket points to a contiguous run.
	primary_idx: [PRIMARY_BUCKETS]Range
	sub_idx:     [SUB_BUCKETS]Range
	bucket_list: [dynamic]u16
	defer delete(bucket_list)

	emit_pairs :: proc(pairs: []Pair, idx: []Range, list: ^[dynamic]u16) {
		prev_bucket: i64 = -1
		for pp in pairs {
			cur := i64(pp.bucket)
			if cur != prev_bucket {
				idx[cur].start = u32(len(list))
				idx[cur].count = 0
				prev_bucket = cur
			}
			append(list, pp.entry_idx)
			idx[cur].count += 1
		}
	}
	emit_pairs(primary_pairs[:], primary_idx[:], &bucket_list)
	emit_pairs(sub_pairs[:],     sub_idx[:],     &bucket_list)

	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)

	emit_header(&sb)
	emit_entries(&sb, all[:])
	emit_form_idx(&sb, all[:])
	emit_bucket_list(&sb, bucket_list[:])
	emit_range_table(&sb, "DECODE_INDEX_PRIMARY", primary_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_SUB",     sub_idx[:])

	err := os.write_entire_file("decoding_tables.odin", transmute([]u8)strings.to_string(sb))
	if err != nil {
		fmt.eprintfln("FAILED to write decoding_tables.odin: %v", err)
		os.exit(1)
	}

	// Stats
	max_primary, max_sub: u16
	pop_primary, pop_sub: int
	for r in primary_idx { if r.count > max_primary { max_primary = r.count }; if r.count > 0 { pop_primary += 1 } }
	for r in sub_idx     { if r.count > max_sub     { max_sub     = r.count }; if r.count > 0 { pop_sub     += 1 } }
	fmt.printfln("OK — %d entries: PRIMARY %d/%d buckets (max=%d); SUB %d/%d buckets (max=%d); bucket_list %d entries",
				 len(all), pop_primary, PRIMARY_BUCKETS, max_primary,
				 pop_sub, SUB_BUCKETS, max_sub, len(bucket_list))
}

enumerate_keys :: proc(b, mask: u32, key_shift: u32, key_bits: u32, out: ^[dynamic]u32) {
	clear(out)
	key_mask := (u32(1) << key_bits) - 1
	fixed_key := ((b & mask) >> key_shift) & key_mask
	var_bits := (~mask >> key_shift) & key_mask
	sub: u32 = 0
	for {
		append(out, fixed_key | sub)
		if var_bits == 0 { break }
		if sub == var_bits { break }
		sub = (sub - var_bits) & var_bits
	}
}

emit_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_ppc

// =============================================================================
// GENERATED FILE — DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_decode_tables.odin from ENCODING_TABLE.
// Regenerate with:  cd ppc && odin run tools/gen_decode_tables.odin -file
//

Decode_Entry :: struct #packed {
	mnemonic: Mnemonic,
	ops:      [4]Operand_Type,
	enc:      [4]Operand_Encoding,
	bits:     u32,
	mask:     u32,
	feature:  Feature,
	mode:     Mode,
	flags:    Encoding_Flags,
}

Decode_Index :: struct #packed {
	start: u32,
	count: u16,
	_:     u16,
}

DECODE_SUB_BUCKETS :: 256   // per primary
`)
}

emit_entries :: proc(sb: ^strings.Builder, entries: []Entry) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintfln(sb, "DECODE_ENTRIES := [%d]Decode_Entry{{", len(entries))
	for e in entries {
		flags_str := encode_flags_literal(e.flags)
		fmt.sbprintfln(sb,
			"\t{{ .%v, {{.%v, .%v, .%v, .%v}}, {{.%v, .%v, .%v, .%v}}, 0x%08X, 0x%08X, .%v, .%v, {{%s}} }},",
			e.mnemonic,
			e.ops[0], e.ops[1], e.ops[2], e.ops[3],
			e.enc[0], e.enc[1], e.enc[2], e.enc[3],
			e.bits, e.mask, e.feature, e.mode, flags_str)
	}
	strings.write_string(sb, "}\n\n")
}

encode_flags_literal :: proc(f: p.Encoding_Flags) -> string {
	sb: strings.Builder
	strings.builder_init(&sb)
	first := true
	w :: proc(sb: ^strings.Builder, first: ^bool, s: string) {
		if !first^ { strings.write_string(sb, ", ") }
		strings.write_string(sb, s)
		first^ = false
	}
	if f.branch      { w(&sb, &first, "branch=true") }
	if f.cond_branch { w(&sb, &first, "cond_branch=true") }
	if f.writes_lr   { w(&sb, &first, "writes_lr=true") }
	if f.sets_cr0    { w(&sb, &first, "sets_cr0=true") }
	if f.sets_cr1    { w(&sb, &first, "sets_cr1=true") }
	if f.abs_branch  { w(&sb, &first, "abs_branch=true") }
	if f.has_oe      { w(&sb, &first, "has_oe=true") }
	if f.prefixed    { w(&sb, &first, "prefixed=true") }
	return strings.to_string(sb)
}

emit_range_table :: proc(sb: ^strings.Builder, name: string, ranges: []Range) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintf(sb, "%s := [%d]Decode_Index{{", name, len(ranges))
	amount_set := 0
	for r, i in ranges {
		if r.count != 0 {
			if amount_set % 16 == 0 { strings.write_string(sb, "\n\t") }
			fmt.sbprintf(sb, "0x%04X = {{%d, % 2d, 0}}, ", i, r.start, r.count)
			amount_set += 1
		}
	}
	strings.write_string(sb, "\n}\n\n")
}

emit_form_idx :: proc(sb: ^strings.Builder, entries: []Entry) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintf(sb, "DECODE_FORM_IDX := [%d]u16{{", len(entries))
	for e, i in entries {
		if i % 64 == 0 { strings.write_string(sb, "\n\t") }
		fmt.sbprintf(sb, "%d, ", e.form_idx)
	}
	strings.write_string(sb, "\n}\n\n")
}

emit_bucket_list :: proc(sb: ^strings.Builder, items: []u16) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintf(sb, "DECODE_BUCKET_LIST := [%d]u16{{", len(items))
	for v, i in items {
		if i % 64 == 0 { strings.write_string(sb, "\n\t") }
		fmt.sbprintf(sb, "% 4d, ", v)
	}
	strings.write_string(sb, "\n}\n\n")
}
