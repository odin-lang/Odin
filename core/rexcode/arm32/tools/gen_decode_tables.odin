package main

// =============================================================================
// AArch32 DECODE-TABLE GENERATOR
// =============================================================================
//
// Three primary dispatch tables (one per Mode/size):
//
//   A32 (4-byte instructions):
//     key = bits[27:20] of the 32-bit word (256 buckets).
//     This is the natural major-opcode + S-bit + sub-op field.
//
//   T32 32-bit (Thumb-2 wide):
//     key = bits[31:25] of the packed u32 (high halfword top 7 bits;
//     128 buckets). Top 5 bits of the first halfword are 11101, 11110,
//     or 11111 -- T32 32-bit identifier.
//
//   T16 (Thumb-1, 16-bit):
//     key = bits[15:10] of the halfword (64 buckets). Adequate spread for
//     the ~120 T16 forms.
//
// Within each bucket, entries are sorted by mask-popcount descending so
// the most-specific encoding wins on first match. Linear scan inside the
// bucket is fine (worst-case ~50 entries on A32 data-proc, ~30 on T32).
//
// Run with:  cd arm32 && odin run tools/gen_decode_tables.odin -file
// Output:    ./decoding_tables.odin

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"
import "core:math/bits"

import a "../"

Entry :: struct {
	mnemonic: a.Mnemonic,
	ops:      [4]a.Operand_Type,
	enc:      [4]a.Operand_Encoding,
	bits:     u32,
	mask:     u32,
	feature:  a.Feature,
	mode:     a.Mode,
	flags:    a.Encoding_Flags,
	is_thumb32: bool,
	key:      u16,    // primary dispatch key (8 bits A32, 7 bits T32, 6 bits T16)
	ilen:     u8,
	form_idx: u16,   // index of this form within ENCODING_TABLE[mnemonic]
}

Range :: struct {
	start: u16,
	count: u16,
}

A32_BUCKETS :: 256   // bits[27:20]
T32_BUCKETS :: 128   // bits[31:25]
T16_BUCKETS :: 64    // bits[15:10]

// T32 wide instructions cluster around top-bit patterns 11101/11110/11111
// (bits[31:27] in {0x1D, 0x1E, 0x1F}). The primary bucket can hit ~100
// entries; we sub-bucket the densest primary buckets on bits[24:20] (32
// values) to bring per-bucket scan to <= 10.
T32_SUB_BUCKETS :: 32  // bits[24:20] of u32

main :: proc() {
	fmt.println("Generating AArch32 decoder tables from ENCODING_TABLE...")

	all: [dynamic]Entry
	defer delete(all)

	for mn in a.Mnemonic {
		for f, fi in a.ENCODING_TABLE[mn] {
			ilen := a.inst_size_from_bits(f.bits, f.mode)
			e := Entry{
				mnemonic   = mn,
				ops        = f.ops,
				enc        = f.enc,
				bits       = f.bits,
				mask       = f.mask,
				feature    = f.feature,
				mode       = f.mode,
				flags      = f.flags,
				is_thumb32 = f.flags.thumb32,
				ilen       = ilen,
				form_idx   = u16(fi),
			}
			// Compute dispatch key per mode/size.
			if e.mode == .A32 {
				e.key = u16((f.bits >> 20) & 0xFF)
			} else if e.is_thumb32 || ilen == 4 {
				// T32 32-bit: bits[31:25] of packed u32 (i.e. top 7 bits of
				// the high halfword)
				e.key = u16((f.bits >> 25) & 0x7F)
			} else {
				// T16: bits[15:10] of the halfword (stored in low 16 of u32)
				e.key = u16((f.bits >> 10) & 0x3F)
			}
			append(&all, e)
		}
	}

	// Sort: by mode group (A32 first, then T32-wide, then T16), then by key,
	// then by mask popcount descending so more-specific forms match first.
	slice.sort_by(all[:], proc(x, y: Entry) -> bool {
		mx := mode_rank(x)
		my := mode_rank(y)
		if mx != my { return mx < my }
		if x.key != y.key { return x.key < y.key }
		xc := bits.count_ones(x.mask)
		yc := bits.count_ones(y.mask)
		if xc != yc { return xc > yc }
		return u16(x.mnemonic) < u16(y.mnemonic)
	})

	// First pass: collect (entry_idx, bucket_key) pairs across modes, expanding
	// variable bits within the bucket-key range. Then group by bucket.
	// Secondary T32 index keyed on bits 24:20 of u32 (the densest primary
	// T32 bucket has > 100 entries; this brings the inner scan to ~10).
	A32_Pair :: struct { bucket: u16, entry_idx: u16 }
	a32_pairs: [dynamic]A32_Pair
	t32_pairs: [dynamic]A32_Pair
	t16_pairs: [dynamic]A32_Pair
	t32_sub_pairs: [dynamic]A32_Pair
	defer delete(a32_pairs); defer delete(t32_pairs)
	defer delete(t16_pairs); defer delete(t32_sub_pairs)

	enumerate_keys :: proc(bits, mask: u32, key_shift: u32, key_bits: u32, out: ^[dynamic]u16) {
		clear(out)
		// Variable bits within the bucket-key range. For each combination of
		// those variable bits we emit a separate bucket key, so a single entry
		// is reachable via every word that can match its mask. fixed_key must
		// be sanitized via `bits & mask` — entry bits often carry a default
		// value at variable positions (e.g. U=1 in LDR's base 0x05900000), and
		// those defaults must not pre-set bits in the key or we'd skip the
		// zero-side bucket during enumeration.
		key_mask := (u32(1) << key_bits) - 1
		fixed_key := ((bits & mask) >> key_shift) & key_mask
		var_bits := (~mask >> key_shift) & key_mask
		// Enumerate submasks of var_bits via the classic Gosper-style walk.
		sub: u32 = 0
		for {
			append(out, u16(fixed_key | sub))
			if var_bits == 0 { break }
			if sub == var_bits { break }
			sub = (sub - var_bits) & var_bits  // next non-zero submask
		}
	}

	keys: [dynamic]u16
	defer delete(keys)

	for e, i in all {
		if e.mode == .A32 {
			enumerate_keys(e.bits, e.mask, 20, 8, &keys)
			for k in keys { append(&a32_pairs, A32_Pair{bucket = k, entry_idx = u16(i)}) }
		} else if e.is_thumb32 || e.ilen == 4 {
			enumerate_keys(e.bits, e.mask, 25, 7, &keys)
			for k in keys { append(&t32_pairs, A32_Pair{bucket = k, entry_idx = u16(i)}) }
			// Sub-bucket: bits 24:20 of word
			sub_keys: [dynamic]u16
			defer delete(sub_keys)
			enumerate_keys(e.bits, e.mask, 20, 5, &sub_keys)
			for k in keys {
				for sk in sub_keys {
					append(&t32_sub_pairs, A32_Pair{
						bucket = k * T32_SUB_BUCKETS + sk,
						entry_idx = u16(i),
					})
				}
			}
		} else {
			enumerate_keys(e.bits, e.mask, 10, 6, &keys)
			for k in keys { append(&t16_pairs, A32_Pair{bucket = k, entry_idx = u16(i)}) }
		}
	}

	// The original entry array `all` is already sorted by (mode, key, popcount,
	// mnemonic). We need to emit a single linear DECODE_ENTRIES array where
	// each bucket points to a contiguous slice. Because an entry can appear in
	// multiple buckets, we duplicate entries in the emitted array — bucket
	// (start, count) addresses the duplicated region.

	// Within each bucket we want most-specific (highest mask popcount) first,
	// tiebreak by mnemonic, so the decoder's linear scan picks the most
	// specific encoding before falling through to a more general one. Encode
	// (bucket, -popcount, mnemonic) into a single u64 sort key so we don't
	// need a closure-capturing comparator.
	Sort_Pair :: struct { sort_key: u64, entry_idx: u16, bucket: u16 }
	rebuild :: proc(pairs: ^[dynamic]A32_Pair, all: []Entry) {
		sortable := make([dynamic]Sort_Pair, 0, len(pairs))
		defer delete(sortable)
		for p in pairs^ {
			e := all[p.entry_idx]
			pop := u64(bits.count_ones(e.mask))
			// bucket << 48 | (255 - pop) << 32 | mnemonic
			key := (u64(p.bucket) << 48) | ((255 - pop) << 32) | u64(e.mnemonic)
			append(&sortable, Sort_Pair{
				sort_key = key, entry_idx = p.entry_idx, bucket = p.bucket,
			})
		}
		slice.sort_by_key(sortable[:], proc(s: Sort_Pair) -> u64 { return s.sort_key })
		clear(pairs)
		for s in sortable { append(pairs, A32_Pair{bucket = s.bucket, entry_idx = s.entry_idx}) }
	}
	rebuild(&a32_pairs,     all[:])
	rebuild(&t32_pairs,     all[:])
	rebuild(&t16_pairs,     all[:])
	rebuild(&t32_sub_pairs, all[:])

	// Build a flat u16 dispatch list (DECODE_BUCKET_LIST). Each bucket
	// points to a contiguous run of entry indices in that list. Duplicating
	// small u16 indices instead of full 21-byte entries keeps the LLVM
	// initializer manageable (the previous "duplicate full entries" approach
	// produced ~108KB of initializer and broke codegen).
	a32_idx: [A32_BUCKETS]Range
	t32_idx: [T32_BUCKETS]Range
	t16_idx: [T16_BUCKETS]Range
	t32_sub_idx: [T32_BUCKETS * T32_SUB_BUCKETS]Range

	bucket_list: [dynamic]u16
	defer delete(bucket_list)

	emit_pairs :: proc(
		pairs: []A32_Pair, idx: []Range, list: ^[dynamic]u16,
	) {
		prev_bucket: i32 = -1
		for p in pairs {
			cur_bucket := i32(p.bucket)
			if cur_bucket != prev_bucket {
				idx[cur_bucket].start = u16(len(list))
				idx[cur_bucket].count = 0
				prev_bucket = cur_bucket
			}
			append(list, p.entry_idx)
			idx[cur_bucket].count += 1
		}
	}
	emit_pairs(a32_pairs[:],     a32_idx[:],     &bucket_list)
	emit_pairs(t32_pairs[:],     t32_idx[:],     &bucket_list)
	emit_pairs(t16_pairs[:],     t16_idx[:],     &bucket_list)
	emit_pairs(t32_sub_pairs[:], t32_sub_idx[:], &bucket_list)

	sb: strings.Builder
	strings.builder_init(&sb)
	defer strings.builder_destroy(&sb)

	emit_header(&sb)
	emit_entries(&sb, all[:])
	emit_form_idx(&sb, all[:])
	emit_bucket_list(&sb, bucket_list[:])
	emit_range_table(&sb, "DECODE_INDEX_A32", a32_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_T32", t32_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_T16", t16_idx[:])
	emit_range_table(&sb, "DECODE_INDEX_T32_SUB", t32_sub_idx[:])

	err := os.write_entire_file("decoding_tables.odin", transmute([]u8)strings.to_string(sb))
	if err != nil {
		fmt.eprintfln("FAILED to write decoding_tables.odin: %v", err)
		os.exit(1)
	}

	max_a32, max_t32, max_t16: u16
	pop_a32, pop_t32, pop_t16: int
	for r in a32_idx { if r.count > max_a32 { max_a32 = r.count }; if r.count > 0 { pop_a32 += 1 } }
	for r in t32_idx { if r.count > max_t32 { max_t32 = r.count }; if r.count > 0 { pop_t32 += 1 } }
	for r in t16_idx { if r.count > max_t16 { max_t16 = r.count }; if r.count > 0 { pop_t16 += 1 } }
	fmt.printfln("OK -- %d entries: A32 %d buckets (max=%d); T32 %d buckets (max=%d); T16 %d buckets (max=%d)",
				 len(all), pop_a32, max_a32, pop_t32, max_t32, pop_t16, max_t16)
}

mode_rank :: proc(e: Entry) -> int {
	if e.mode == .A32 { return 0 }
	if e.is_thumb32 || e.ilen == 4 { return 1 }
	return 2
}

push_range :: proc(r: ^Range, i: u16) {
	if r.count == 0 { r.start = i }
	r.count += 1
}

emit_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_arm32

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_decode_tables.odin from ENCODING_TABLE.
// Regenerate with:  cd arm32 && odin run tools/gen_decode_tables.odin -file
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
#assert(size_of(Decode_Entry) == 21)

Decode_Index :: struct #packed {
	start: u16,
	count: u16,
}
#assert(size_of(Decode_Index) == 4)

DECODE_T32_SUB_BUCKETS :: 32
`)
}

emit_entries :: proc(sb: ^strings.Builder, entries: []Entry) {
	fmt.sbprintfln(sb, "")
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintfln(sb, "DECODE_ENTRIES := [%d]Decode_Entry{{", len(entries))
	for e in entries {
		flags_str := encode_flags_literal(e.flags)
		fmt.sbprintfln(sb,
			"\t{{.%v, {{.%v, .%v, .%v, .%v}}, {{.%v, .%v, .%v, .%v}}, 0x%08X, 0x%08X, .%v, .%v, {{%s}}}},",
			e.mnemonic,
			e.ops[0], e.ops[1], e.ops[2], e.ops[3],
			e.enc[0], e.enc[1], e.enc[2], e.enc[3],
			e.bits, e.mask, e.feature, e.mode, flags_str)
	}
	strings.write_string(sb, "}\n\n")
}

encode_flags_literal :: proc(f: a.Encoding_Flags) -> string {
	sb: strings.Builder
	strings.builder_init(&sb)
	first := true
	write := proc(sb: ^strings.Builder, first: ^bool, s: string) {
		if !first^ { strings.write_string(sb, ", ") }
		strings.write_string(sb, s)
		first^ = false
	}
	if f.sets_flags     { write(&sb, &first, "sets_flags=true")     }
	if f.cond_in_28   { write(&sb, &first, "cond_in_28=true")   }
	if f.branch       { write(&sb, &first, "branch=true")       }
	if f.cond_branch  { write(&sb, &first, "cond_branch=true")  }
	if f.writes_pc    { write(&sb, &first, "writes_pc=true")    }
	if f.thumb32      { write(&sb, &first, "thumb32=true")      }
	if f.deprecated   { write(&sb, &first, "deprecated=true")   }
	return strings.to_string(sb)
}

emit_range_table :: proc(sb: ^strings.Builder, name: string, ranges: []Range) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintf(sb, "%s := [%d]Decode_Index{{\n", name, len(ranges))
	for r, i in ranges {
		if r.count != 0 {
			fmt.sbprintf(sb, "\t0x%02X = {{%d, %d}},\n", i, r.start, r.count)
		}
	}
	strings.write_string(sb, "}\n\n")
}

emit_form_idx :: proc(sb: ^strings.Builder, entries: []Entry) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintf(sb, "DECODE_FORM_IDX := [%d]u16{{\n", len(entries))
	for e, i in entries {
		if i > 0 && i % 16 == 0 { strings.write_string(sb, "\n") }
		fmt.sbprintf(sb, " %d,", e.form_idx)
	}
	strings.write_string(sb, "\n}\n\n")
}

emit_bucket_list :: proc(sb: ^strings.Builder, items: []u16) {
	fmt.sbprintfln(sb, "@(rodata)")
	fmt.sbprintf(sb, "DECODE_BUCKET_LIST := [%d]u16{{\n", len(items))
	for v, i in items {
		if i > 0 && i % 16 == 0 { strings.write_string(sb, "\n") }
		fmt.sbprintf(sb, " %d,", v)
	}
	strings.write_string(sb, "\n}\n\n")
}
