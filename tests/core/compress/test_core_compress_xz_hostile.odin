package test_core_compress

import "core:compress"
import "core:compress/filters"
import "core:compress/lzma"
import "core:compress/xz"
import "core:crypto/sha2"
import "core:encoding/endian"
import "core:hash"
import "core:slice"
import "core:testing"

Xz_Size_Mode :: enum u8 {
	Absent,
	Correct,
	Value,
	Raw,
}

Xz_Size :: struct {
	mode:  Xz_Size_Mode,
	value: u64,
	raw:   []u8,
}

Xz_Craft_Block :: struct {
	size_byte:      Maybe(u8),
	flags_extra:    u8,
	compressed:     Xz_Size,
	uncompressed:   Xz_Size,
	filter_count:   int,
	filters:        []u8,
	header_padding: u8,
	header_crc_xor: u32,
	plain:          []u8,
	lzma2:          []u8,
	extra_data:     []u8,
	block_padding:  u8,
	check_xor:      u8,
}

Xz_Craft :: struct {
	bad_magic:          bool,
	stream_flags:       [2]u8,
	header_crc_xor:     u32,
	blocks:             []Xz_Craft_Block,
	index_count_delta:  int,
	index_count_raw:    []u8,
	unpadded_delta:     i64,
	uncompressed_delta: i64,
	unpadded_value:     Maybe(u64),
	index_padding:      u8,
	index_crc_xor:      u32,
	backward_delta:     int,
	footer_flags:       Maybe([2]u8),
	footer_crc_xor:     u32,
	bad_footer_magic:   bool,
	truncate:           int,
	tail:               []u8,
}

Xz_Hostile :: struct {
	label: string,
	craft: Xz_Craft,
	err:   compress.Error,
	limit: int,
}

XZ_CRAFT_PLAIN :: "Odin xz"

@(test)
test_xz_hostile :: proc(t: ^testing.T) {
	big_plain := make([]u8, 1 << 20)
	defer delete(big_plain)
	bomb: [dynamic]u8
	defer delete(bomb)
	_, bomb_err := lzma.compress_lzma2(&bomb, big_plain, lzma.level_options(.Level_6))
	if !testing.expect_value(t, bomb_err, nil) {
		return
	}
	lclp := []u8{0xE0, 0x00, 0x06, 0x00, 0x05, 13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	no_reset_copy  := []u8{0x02, 0x00, 0x06, 'O', 'd', 'i', 'n', ' ', 'x', 'z', 0x00}
	no_reset_lzma  := []u8{0xA0, 0x00, 0x06, 0x00, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	filtered := transmute([]u8)string(XZ_CRAFT_PLAIN)
	filtered  = slice.clone(filtered)
	defer delete(filtered)
	delta: filters.Delta_State
	filters.delta_init(&delta, 4)
	filters.delta_encode(&delta, filtered)
	branch: filters.Branch_State
	filters.branch_init(&branch, .X86)
	filters.branch_encode(&branch, filtered)
	filtered_lzma2: [dynamic]u8
	defer delete(filtered_lzma2)
	append(&filtered_lzma2, 0x01, 0x00, u8(len(filtered) - 1))
	append(&filtered_lzma2, ..filtered)
	append(&filtered_lzma2, 0x00)
	two_blocks     := []Xz_Craft_Block{{}, {}}
	second_copy    := []Xz_Craft_Block{{}, {lzma2 = no_reset_copy}}
	second_lzma    := []Xz_Craft_Block{{}, {lzma2 = no_reset_lzma}}
	tiny_blocks    := make([]Xz_Craft_Block, 2000)
	defer delete(tiny_blocks)

	LZMA2  :: []u8{0x21, 0x01, 0x00}
	DELTA  :: []u8{0x03, 0x01, 0x00}

	XZE :: compress.XZ_Error
	GE  :: compress.General_Error
	LE  :: compress.LZMA_Error

	cases := [?]Xz_Hostile{
		{"valid, CRC32", {stream_flags = {0, 1}}, nil, 0},
		{"valid, no check", {stream_flags = {0, 0}}, nil, 0},
		{"valid, CRC64", {stream_flags = {0, 4}}, nil, 0},
		{"valid, SHA-256", {stream_flags = {0, 10}}, nil, 0},
		{"valid, reserved check 2", {stream_flags = {0, 2}}, nil, 0},
		{"valid, reserved check 15", {stream_flags = {0, 15}}, nil, 0},
		{"valid, both sizes", {stream_flags = {0, 1}, blocks = {{compressed = {mode = .Correct}, uncompressed = {mode = .Correct}}}}, nil, 0},
		{"valid, two blocks", {stream_flags = {0, 1}, blocks = two_blocks}, nil, 0},
		{"valid, dict prop 40", {stream_flags = {0, 1}, blocks = {{filters = {0x21, 0x01, 40}}}}, nil, 0},
		{"valid, delta and x86", {stream_flags = {0, 1}, blocks = {{filter_count = 3, filters = {0x03, 0x01, 0x03, 0x04, 0x00, 0x21, 0x01, 0x00}, lzma2 = filtered_lzma2[:]}}}, nil, 0},
		{"valid, 2000 one-chunk blocks", {stream_flags = {0, 1}, blocks = tiny_blocks}, nil, 0},

		{"header: wrong magic", {stream_flags = {0, 1}, bad_magic = true}, XZE.Invalid_Magic, 0},
		{"header: CRC", {stream_flags = {0, 1}, header_crc_xor = 1}, XZE.Header_Checksum_Failed, 0},
		{"header: reserved first flag byte", {stream_flags = {1, 1}}, XZE.Reserved_Bit_Set, 0},
		{"header: reserved flag bits", {stream_flags = {0, 0x11}}, XZE.Reserved_Bit_Set, 0},
		{"header: empty input", {stream_flags = {0, 1}, truncate = 1}, GE.Stream_Too_Short, 0},

		{"block: header size past the end", {stream_flags = {0, 1}, blocks = {{size_byte = 0xFF}}}, GE.Stream_Too_Short, 0},
		{"block: header CRC", {stream_flags = {0, 1}, blocks = {{header_crc_xor = 1}}}, XZE.Header_Checksum_Failed, 0},
		{"block: reserved flag bits", {stream_flags = {0, 1}, blocks = {{flags_extra = 0x04}}}, XZE.Reserved_Bit_Set, 0},
		{"block: reserved flag bit 0x20", {stream_flags = {0, 1}, blocks = {{flags_extra = 0x20}}}, XZE.Reserved_Bit_Set, 0},
		{"block: 10-byte varint", {stream_flags = {0, 1}, blocks = {{compressed = {mode = .Raw, raw = {0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01}}}}}, XZE.Invalid_Block_Header, 0},
		{"block: non-minimal varint", {stream_flags = {0, 1}, blocks = {{compressed = {mode = .Raw, raw = {0x8C, 0x00}}}}}, XZE.Invalid_Block_Header, 0},
		{"block: varint over 63 bits", {stream_flags = {0, 1}, blocks = {{compressed = {mode = .Raw, raw = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}}}}}, XZE.Invalid_Block_Header, 0},
		{"block: compressed size 0", {stream_flags = {0, 1}, blocks = {{compressed = {mode = .Value, value = 0}}}}, XZE.Invalid_Block_Header, 0},
		{"block: compressed size 2^62", {stream_flags = {0, 1}, blocks = {{compressed = {mode = .Value, value = 1 << 62}}}}, GE.Stream_Too_Short, 0},
		{"block: props size past the header", {stream_flags = {0, 1}, blocks = {{filters = {0x21, 0x7F, 0x00}}}}, XZE.Invalid_Block_Header, 0},
		{"block: non-zero header padding", {stream_flags = {0, 1}, blocks = {{header_padding = 1}}}, XZE.Reserved_Bit_Set, 0},
		{"index: padding present", {stream_flags = {0, 1}, blocks = {{plain = big_plain[:200]}}}, nil, 0},

		{"chain: LZMA2 not last", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x21, 0x01, 0x00, 0x03, 0x01, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: no LZMA2, Delta last", {stream_flags = {0, 1}, blocks = {{filters = DELTA}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: BCJ last", {stream_flags = {0, 1}, blocks = {{filters = {0x04, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: four filters, LZMA2 first", {stream_flags = {0, 1}, blocks = {{filter_count = 4, filters = {0x21, 0x01, 0x00, 0x03, 0x01, 0x00, 0x04, 0x00, 0x05, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: unknown ID", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x22, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Unsupported_Filter, 0},
		{"chain: Subblock", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x01, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Unsupported_Filter, 0},
		{"chain: ID 2^62", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x40, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Unsupported_Filter, 0},
		{"chain: BCJ props 1 byte", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x04, 0x01, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: BCJ props 2 bytes", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x04, 0x02, 0x00, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: BCJ props 3 bytes", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x04, 0x03, 0x00, 0x00, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: BCJ props 5 bytes", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: PowerPC start offset 2", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x05, 0x04, 0x02, 0x00, 0x00, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: Delta props 2 bytes", {stream_flags = {0, 1}, blocks = {{filter_count = 2, filters = {0x03, 0x02, 0x00, 0x00, 0x21, 0x01, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: LZMA2 props 2 bytes", {stream_flags = {0, 1}, blocks = {{filters = {0x21, 0x02, 0x00, 0x00}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: LZMA2 dict prop 41", {stream_flags = {0, 1}, blocks = {{filters = {0x21, 0x01, 41}}}}, XZE.Invalid_Filter_Chain, 0},
		{"chain: LZMA2 reserved prop bits", {stream_flags = {0, 1}, blocks = {{filters = {0x21, 0x01, 0x40}}}}, XZE.Invalid_Filter_Chain, 0},

		{"data: LZMA2 ends before the compressed size", {stream_flags = {0, 1}, blocks = {{compressed = {mode = .Correct}, extra_data = {0x00, 0x00, 0x00, 0x00}}}}, GE.Size_Mismatch, 0},
		{"data: LZMA2 runs past the compressed size", {stream_flags = {0, 1}, blocks = {{compressed = {mode = .Value, value = 9}}}}, GE.Size_Mismatch, 0},
		{"data: first chunk without a dict reset", {stream_flags = {0, 1}, blocks = {{lzma2 = no_reset_copy}}}, LE.Invalid_Chunk, 0},
		{"data: second block without a dict reset, copy", {stream_flags = {0, 1}, blocks = second_copy}, LE.Invalid_Chunk, 0},
		{"data: second block without a dict reset, LZMA", {stream_flags = {0, 1}, blocks = second_lzma}, LE.Invalid_Chunk, 0},
		{"data: lc + lp > 4", {stream_flags = {0, 1}, blocks = {{lzma2 = lclp}}}, LE.Invalid_Properties, 0},
		{"data: uncompressed size too small", {stream_flags = {0, 1}, blocks = {{uncompressed = {mode = .Value, value = 6}}}}, GE.Size_Mismatch, 0},
		{"data: uncompressed size too large", {stream_flags = {0, 1}, blocks = {{uncompressed = {mode = .Value, value = 8}}}}, GE.Size_Mismatch, 0},

		{"trailer: non-zero block padding", {stream_flags = {0, 1}, blocks = {{block_padding = 1}}}, XZE.Invalid_Padding, 0},
		{"trailer: CRC32 check", {stream_flags = {0, 1}, blocks = {{check_xor = 1}}}, XZE.Block_Checksum_Failed, 0},
		{"trailer: CRC64 check", {stream_flags = {0, 4}, blocks = {{check_xor = 1}}}, XZE.Block_Checksum_Failed, 0},
		{"trailer: SHA-256 check", {stream_flags = {0, 10}, blocks = {{check_xor = 1}}}, XZE.Block_Checksum_Failed, 0},
		{"trailer: reserved check not verified", {stream_flags = {0, 2}, blocks = {{check_xor = 1}}}, nil, 0},
		{"trailer: truncated check", {stream_flags = {0, 4}, truncate = 12 + 12 + 11 + 1 + 4}, GE.Stream_Too_Short, 0},

		{"index: one record too many", {stream_flags = {0, 1}, index_count_delta = 1}, XZE.Index_Mismatch, 0},
		{"index: one record too few", {stream_flags = {0, 1}, blocks = two_blocks, index_count_delta = -1}, XZE.Index_Mismatch, 0},
		{"index: huge record count", {stream_flags = {0, 1}, index_count_raw = {0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01}}, XZE.Index_Mismatch, 0},
		{"index: unpadded size 0", {stream_flags = {0, 1}, unpadded_value = 0}, XZE.Invalid_Index, 0},
		{"index: unpadded size 4", {stream_flags = {0, 1}, unpadded_value = 4}, XZE.Invalid_Index, 0},
		{"index: unpadded size off", {stream_flags = {0, 1}, unpadded_delta = 1}, XZE.Index_Mismatch, 0},
		{"index: uncompressed size off", {stream_flags = {0, 1}, uncompressed_delta = 1}, XZE.Index_Mismatch, 0},
		{"index: sizes swapped between blocks", {stream_flags = {0, 1}, blocks = {{}, {plain = transmute([]u8)string("Odin xz, longer")}}, unpadded_delta = 8, uncompressed_delta = 8}, XZE.Index_Mismatch, 0},
		{"index: non-zero padding", {stream_flags = {0, 1}, blocks = {{plain = big_plain[:200]}}, index_padding = 1}, XZE.Invalid_Index, 0},
		{"index: CRC", {stream_flags = {0, 1}, index_crc_xor = 1}, XZE.Header_Checksum_Failed, 0},
		{"index: backward size off", {stream_flags = {0, 1}, backward_delta = 1}, XZE.Index_Mismatch, 0},

		{"footer: CRC", {stream_flags = {0, 1}, footer_crc_xor = 1}, XZE.Header_Checksum_Failed, 0},
		{"footer: flags differ", {stream_flags = {0, 1}, footer_flags = [2]u8{0, 4}}, XZE.Footer_Mismatch, 0},
		{"footer: missing YZ", {stream_flags = {0, 1}, bad_footer_magic = true}, XZE.Invalid_Magic, 0},

		{"padding: garbage after the stream", {stream_flags = {0, 1}, tail = {0, 0, 0, 0, 0x42}}, XZE.Data_After_End, 0},
		{"padding: 2 bytes", {stream_flags = {0, 1}, tail = {0, 0}}, XZE.Invalid_Padding, 0},
		{"padding: then a cut header", {stream_flags = {0, 1}, tail = {0, 0, 0, 0, 0xFD, '7', 'z', 'X', 'Z', 0x00, 0x00}}, GE.Stream_Too_Short, 0},

		{"bomb: 1 MiB of zeros over a 64 KiB limit", {stream_flags = {0, 1}, blocks = {{filters = {0x21, 0x01, 16}, plain = big_plain, lzma2 = bomb[:]}}}, GE.Output_Too_Short, 64 * 1024},
		{"bomb: three filters, same limit", {stream_flags = {0, 1}, blocks = {{filter_count = 4, filters = {0x03, 0x01, 0x00, 0x04, 0x00, 0x07, 0x00, 0x21, 0x01, 16}, plain = big_plain, lzma2 = bomb[:]}}}, GE.Output_Too_Short, 64 * 1024},
		{"bomb: declared 2^40 bytes", {stream_flags = {0, 1}, blocks = {{uncompressed = {mode = .Value, value = 1 << 40}}}}, GE.Output_Too_Short, 0},
	}

	for c in cases {
		input := xz_craft(c.craft)
		defer delete(input)
		limit := c.limit if c.limit > 0 else compress.COMPRESS_OUTPUT_ALLOCATE_MAX
		out: [dynamic]u8
		err := xz.decompress(&out, input[:], {}, -1, {max_output_size = limit})
		testing.expectf(t, err == c.err, "%s: %v, want %v", c.label, err, c.err)
		if c.err == nil && err == nil {
			want := 0
			blocks := c.craft.blocks if len(c.craft.blocks) > 0 else []Xz_Craft_Block{{}}
			for b in blocks {
				want += len(b.plain) if b.plain != nil else len(XZ_CRAFT_PLAIN)
			}
			testing.expectf(t, len(out) == want, "%s: %d bytes, want %d", c.label, len(out), want)
		}
		stream_want := c.err
		if c.label == "valid, dict prop 40" {
			stream_want = GE.Memory_Limit_Exceeded
		}
		for streamed in ([2]bool{false, true}) {
			stream_out, stream_err := xz_stream_decode(input[:], {}, -1, {max_output_size = limit, chunk_size = 1}, streamed, 0 if streamed else 4096)
			testing.expectf(t, stream_err == stream_want, "%s (stream, streamed %v): %v, want %v", c.label, streamed, stream_err, stream_want)
			if c.err == nil && stream_err == nil {
				testing.expectf(t, len(stream_out) == len(out), "%s (stream): %d bytes, want %d", c.label, len(stream_out), len(out))
			}
			delete(stream_out)
		}
		delete(out)
	}
}

xz_craft :: proc(c: Xz_Craft) -> (out: [dynamic]u8) {
	check_id := c.stream_flags[1] & 0x0F
	sizes := [16]int{0, 4, 4, 4, 8, 8, 8, 16, 16, 16, 32, 32, 32, 64, 64, 64}
	check_size := sizes[check_id]

	append(&out, 0xFD, '7', 'z', 'X', 'Z', 0x00)
	if c.bad_magic {
		out[1] = '8'
	}
	append(&out, c.stream_flags[0], c.stream_flags[1])
	stream_flags := c.stream_flags
	xz_put_u32(&out, hash.crc32(stream_flags[:]) ~ c.header_crc_xor)

	blocks := c.blocks if len(c.blocks) > 0 else []Xz_Craft_Block{{}}
	records: [dynamic][2]u64
	defer delete(records)
	for b in blocks {
		plain := b.plain if b.plain != nil else transmute([]u8)string(XZ_CRAFT_PLAIN)
		lzma2: [dynamic]u8
		defer delete(lzma2)
		if b.lzma2 != nil {
			append(&lzma2, ..b.lzma2)
		} else {
			for done := 0; done < len(plain); {
				n := min(len(plain) - done, 1 << 16)
				append(&lzma2, 0x01 if done == 0 else 0x02, u8((n - 1) >> 8), u8(n - 1))
				append(&lzma2, ..plain[done:][:n])
				done += n
			}
			append(&lzma2, 0x00)
		}
		data_size := len(lzma2) + len(b.extra_data)

		header: [dynamic]u8
		defer delete(header)
		count := max(b.filter_count, 1)
		flags := u8(count - 1) | b.flags_extra
		if b.compressed.mode != .Absent {
			flags |= 0x40
		}
		if b.uncompressed.mode != .Absent {
			flags |= 0x80
		}
		append(&header, 0, flags)
		xz_put_size(&header, b.compressed, u64(data_size))
		xz_put_size(&header, b.uncompressed, u64(len(plain)))
		append(&header, ..(b.filters if b.filters != nil else []u8{0x21, 0x01, 0x00}))
		for (len(header) + 4) % 4 != 0 {
			append(&header, b.header_padding)
		}
		header[0] = b.size_byte.? or_else u8((len(header) + 4) / 4 - 1)
		xz_put_u32(&header, hash.crc32(header[:]) ~ b.header_crc_xor)

		block_start := len(out)
		append(&out, ..header[:])
		append(&out, ..lzma2[:])
		append(&out, ..b.extra_data)
		for (len(out) - block_start) % 4 != 0 {
			append(&out, b.block_padding)
		}
		check_start := len(out)
		switch check_id {
		case 0:
		case 1:
			xz_put_u32(&out, hash.crc32(plain))
		case 4:
			xz_put_u64(&out, hash.crc64_xz(plain))
		case 10:
			ctx: sha2.Context_256
			sha2.init_256(&ctx)
			sha2.update(&ctx, plain)
			digest: [32]u8
			sha2.final(&ctx, digest[:])
			append(&out, ..digest[:])
		case:
			for _ in 0..<check_size {
				append(&out, 0)
			}
		}
		if check_size > 0 {
			out[check_start] ~= b.check_xor
		}
		append(&records, [2]u64{u64(len(header) + data_size + check_size), u64(len(plain))})
	}

	index_start := len(out)
	append(&out, 0)
	if c.index_count_raw != nil {
		append(&out, ..c.index_count_raw)
	} else {
		xz_put_vli(&out, u64(len(records) + c.index_count_delta))
	}
	for r, i in records {
		unpadded, uncompressed := r[0], r[1]
		if i == 0 {
			unpadded     = u64(i64(unpadded) + c.unpadded_delta)
			uncompressed = u64(i64(uncompressed) + c.uncompressed_delta)
			unpadded     = c.unpadded_value.? or_else unpadded
		}
		if i == 1 && c.unpadded_delta != 0 && len(records) == 2 {
			unpadded     = u64(i64(unpadded) - c.unpadded_delta)
			uncompressed = u64(i64(uncompressed) - c.uncompressed_delta)
		}
		xz_put_vli(&out, unpadded)
		xz_put_vli(&out, uncompressed)
	}
	for (len(out) - index_start) % 4 != 0 {
		append(&out, c.index_padding)
	}
	xz_put_u32(&out, hash.crc32(out[index_start:]) ~ c.index_crc_xor)
	index_size := len(out) - index_start

	footer: [12]u8
	flags := c.footer_flags.? or_else c.stream_flags
	endian.unchecked_put_u32le(footer[4:8], u32(index_size / 4 - 1 + c.backward_delta))
	footer[8], footer[9] = flags[0], flags[1]
	footer[10], footer[11] = 'Y', 'Z'
	if c.bad_footer_magic {
		footer[11] = 'Q'
	}
	endian.unchecked_put_u32le(footer[0:4], hash.crc32(footer[4:10]) ~ c.footer_crc_xor)
	append(&out, ..footer[:])
	append(&out, ..c.tail)
	if c.truncate > 0 {
		resize(&out, c.truncate - 1)
	}
	return
}

xz_put_size :: proc(out: ^[dynamic]u8, s: Xz_Size, correct: u64) {
	switch s.mode {
	case .Absent:
	case .Correct:
		xz_put_vli(out, correct)
	case .Value:
		xz_put_vli(out, s.value)
	case .Raw:
		append(out, ..s.raw)
	}
}

xz_put_vli :: proc(out: ^[dynamic]u8, value: u64) {
	v := value
	for v >= 0x80 {
		append(out, u8(v) | 0x80)
		v >>= 7
	}
	append(out, u8(v))
}

xz_put_u32 :: proc(out: ^[dynamic]u8, v: u32) {
	append(out, u8(v), u8(v >> 8), u8(v >> 16), u8(v >> 24))
}

xz_put_u64 :: proc(out: ^[dynamic]u8, v: u64) {
	xz_put_u32(out, u32(v))
	xz_put_u32(out, u32(v >> 32))
}
