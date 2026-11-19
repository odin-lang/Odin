package compress_xz

import "core:compress"
import "core:compress/lzma"
import "core:encoding/endian"
import "core:hash"
import "core:io"

read_index :: proc{read_index_from_bytes, read_index_from_stream}

decompress_block :: proc{decompress_block_from_bytes, decompress_block_from_stream}

read_index_from_bytes :: proc(input: []u8, allocator := context.allocator) -> (index: Index, err: Error) {
	context.allocator = allocator
	src := Index_Source{bytes = input, size = i64(len(input))}
	if err = _read_index(&src, &index); err != nil {
		index_destroy(&index)
	}
	return
}

read_index_from_stream :: proc(input: io.Stream, allocator := context.allocator) -> (index: Index, err: Error) {
	context.allocator = allocator
	size := io.size(input) or_return
	src := Index_Source{stream = input, is_stream = true, size = size}
	defer delete(src.buffer)
	if err = _read_index(&src, &index); err != nil {
		index_destroy(&index)
	}
	return
}

index_destroy :: proc(index: ^Index) {
	if index == nil {
		return
	}
	delete(index.streams)
	delete(index.blocks)
	index^ = {}
}

find_block :: proc(index: ^Index, uncompressed_offset: i64) -> (block: int, ok: bool) {
	if index == nil || uncompressed_offset < 0 || uncompressed_offset >= index.uncompressed_size {
		return
	}
	lo, hi := 0, len(index.blocks)
	for lo < hi {
		mid := lo + (hi - lo) / 2
		if index.blocks[mid].uncompressed_offset <= uncompressed_offset {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	if lo == 0 {
		return
	}
	return lo - 1, true
}

decompress_block_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, index: ^Index, block: int, flags := Decode_Flags{}, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	b, check_id := _index_block(output, index, block, options) or_return
	padded := _padded_size(b.unpadded_size)
	if b.compressed_offset > i64(len(input)) || padded > i64(len(input)) - b.compressed_offset {
		return General_Error.Stream_Too_Short
	}
	return _decode_indexed_block(output, input[int(b.compressed_offset):][:int(padded)], b, check_id, flags, options, compress.memory_limit(options))
}

decompress_block_from_stream :: proc(output: ^[dynamic]u8, input: io.Stream, index: ^Index, block: int, flags := Decode_Flags{}, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	b, check_id := _index_block(output, index, block, options) or_return
	padded := _padded_size(b.unpadded_size)
	size := io.size(input) or_return
	if b.compressed_offset > size || padded > size - b.compressed_offset {
		return General_Error.Stream_Too_Short
	}
	if padded > i64(max(int)) {
		return XZ_Error.Input_Too_Large
	}
	limit := compress.memory_limit(options)
	if padded > i64(limit) {
		return General_Error.Memory_Limit_Exceeded
	}
	data := make([]u8, int(padded)) or_return
	defer delete(data)
	_, read_err := io.read_full_at(input, data, b.compressed_offset)
	if read_err == .EOF || read_err == .Unexpected_EOF {
		return General_Error.Stream_Too_Short
	}
	if read_err != nil {
		return read_err
	}
	return _decode_indexed_block(output, data, b, check_id, flags, options, max(limit - int(padded), 1))
}

@(private)
_read_index :: proc(src: ^Index_Source, index: ^Index) -> (err: Error) {
	index.streams = make([dynamic]Stream_Info)
	index.blocks  = make([dynamic]Block_Info)
	locations    := make([dynamic]Index_Location)
	defer delete(locations)

	if src.size <= 0 {
		return General_Error.Stream_Too_Short
	}
	pos := src.size
	for pos > 0 {
		end := pos
		pos = _skip_padding(src, end) or_return
		if (end - pos) % 4 != 0 {
			return XZ_Error.Invalid_Padding
		}
		if pos == 0 {
			return XZ_Error.Invalid_Magic
		}
		if pos < FOOTER_SIZE {
			return General_Error.Stream_Too_Short
		}

		footer := _source_read(src, pos - FOOTER_SIZE, FOOTER_SIZE) or_return
		if string(footer[10:12]) != string(FOOTER_MAGIC[:]) {
			return XZ_Error.Invalid_Magic
		}
		if hash.crc32(footer[4:10]) != endian.unchecked_get_u32le(footer[0:4]) {
			return XZ_Error.Header_Checksum_Failed
		}
		flags := [2]u8{footer[8], footer[9]}
		if flags[0] != 0 || flags[1] & 0xF0 != 0 {
			return XZ_Error.Reserved_Bit_Set
		}
		index_size := (i64(endian.unchecked_get_u32le(footer[4:8])) + 1) * 4
		index_end  := pos - FOOTER_SIZE
		if index_size > index_end - HEADER_SIZE {
			return XZ_Error.Invalid_Index
		}
		if index_size > i64(max(int)) {
			return XZ_Error.Input_Too_Large
		}
		index_start := index_end - index_size

		data    := _source_read(src, index_start, int(index_size)) or_return
		summary := _parse_index(data, nil) or_return
		if summary.padded > index_start - HEADER_SIZE {
			return XZ_Error.Invalid_Index
		}
		if summary.count > u64(max(int)) {
			return XZ_Error.Input_Too_Large
		}
		stream_start := index_start - summary.padded - HEADER_SIZE

		header := _source_read(src, stream_start, HEADER_SIZE) or_return
		if string(header[:len(HEADER_MAGIC)]) != string(HEADER_MAGIC[:]) {
			return XZ_Error.Invalid_Magic
		}
		if hash.crc32(header[6:8]) != endian.unchecked_get_u32le(header[8:12]) {
			return XZ_Error.Header_Checksum_Failed
		}
		if header[6] != 0 || header[7] & 0xF0 != 0 {
			return XZ_Error.Reserved_Bit_Set
		}
		if header[6] != flags[0] || header[7] != flags[1] {
			return XZ_Error.Footer_Mismatch
		}

		append(&index.streams, Stream_Info{
			check_id          = flags[1] & 0x0F,
			compressed_offset = stream_start,
			compressed_size   = pos - stream_start,
			uncompressed_size = summary.uncompressed,
			padding           = end - pos,
			block_count       = int(summary.count),
		}) or_return
		append(&locations, Index_Location{offset = index_start, size = index_size, padded = summary.padded}) or_return
		pos = stream_start
	}

	stream_count := len(index.streams)
	for i in 0..<stream_count / 2 {
		j := stream_count - 1 - i
		index.streams[i], index.streams[j] = index.streams[j], index.streams[i]
		locations[i], locations[j] = locations[j], locations[i]
	}

	block_count  := 0
	uncompressed := i64(0)
	for &s in index.streams {
		if s.uncompressed_size > i64(VLI_MAX) - uncompressed || s.block_count > max(int) - block_count {
			return XZ_Error.Input_Too_Large
		}
		s.uncompressed_offset = uncompressed
		s.first_block         = block_count
		uncompressed += s.uncompressed_size
		block_count  += s.block_count
	}
	resize(&index.blocks, block_count) or_return

	for s, i in index.streams {
		loc     := locations[i]
		data    := _source_read(src, loc.offset, int(loc.size)) or_return
		blocks  := index.blocks[s.first_block:][:s.block_count]
		summary := _parse_index(data, blocks) or_return
		if summary.count != u64(s.block_count) || summary.padded != loc.padded || summary.uncompressed != s.uncompressed_size {
			return XZ_Error.Index_Mismatch
		}
		compressed := s.compressed_offset + HEADER_SIZE
		offset     := s.uncompressed_offset
		for &b in blocks {
			b.stream              = i
			b.compressed_offset   = compressed
			b.uncompressed_offset = offset
			compressed += _padded_size(b.unpadded_size)
			offset     += b.uncompressed_size
		}
	}
	index.compressed_size   = src.size
	index.uncompressed_size = uncompressed
	return nil
}

@(private)
_parse_index :: proc(data: []u8, blocks: []Block_Info) -> (summary: Index_Summary, err: Error) {
	if len(data) < 8 || data[0] != 0 {
		return {}, XZ_Error.Invalid_Index
	}
	body := data[:len(data) - 4]
	if hash.crc32(body) != endian.unchecked_get_u32le(data[len(data) - 4:]) {
		return {}, XZ_Error.Header_Checksum_Failed
	}
	p := 1
	count, count_ok := _read_vli(body, &p)
	if !count_ok || count > u64(len(body) - p) / 2 {
		return {}, XZ_Error.Invalid_Index
	}
	if blocks != nil && u64(len(blocks)) != count {
		return {}, XZ_Error.Index_Mismatch
	}
	padded, uncompressed: u64
	for i in 0..<int(count) {
		unpadded, unpadded_ok := _read_vli(body, &p)
		size, size_ok := _read_vli(body, &p)
		if !unpadded_ok || !size_ok || unpadded < UNPADDED_SIZE_MIN || unpadded > UNPADDED_SIZE_MAX {
			return {}, XZ_Error.Invalid_Index
		}
		block_padded := (unpadded + 3) &~ 3
		if block_padded > VLI_MAX - padded || size > VLI_MAX - uncompressed {
			return {}, XZ_Error.Invalid_Index
		}
		padded       += block_padded
		uncompressed += size
		if blocks != nil {
			blocks[i].unpadded_size     = i64(unpadded)
			blocks[i].uncompressed_size = i64(size)
		}
	}
	if len(body) - p >= 4 {
		return {}, XZ_Error.Invalid_Index
	}
	for b in body[p:] {
		if b != 0 {
			return {}, XZ_Error.Invalid_Index
		}
	}
	return {count = count, padded = i64(padded), uncompressed = i64(uncompressed)}, nil
}

@(private)
_index_block :: proc(output: ^[dynamic]u8, index: ^Index, block: int, options: compress.Options) -> (b: Block_Info, check_id: u8, err: Error) {
	if output == nil || index == nil || block < 0 || block >= len(index.blocks) {
		return {}, 0, General_Error.Incompatible_Options
	}
	_check_options(options) or_return
	b = index.blocks[block]
	if b.stream < 0 || b.stream >= len(index.streams) || b.compressed_offset < 0 || b.uncompressed_size < 0 ||
	   b.unpadded_size < UNPADDED_SIZE_MIN || u64(b.unpadded_size) > UNPADDED_SIZE_MAX {
		return {}, 0, XZ_Error.Invalid_Index
	}
	if b.uncompressed_size > i64(compress.output_limit(options)) {
		return {}, 0, General_Error.Output_Too_Short
	}
	return b, index.streams[b.stream].check_id & 0x0F, nil
}

@(private)
_decode_indexed_block :: proc(output: ^[dynamic]u8, data: []u8, b: Block_Info, check_id: u8, flags: Decode_Flags, options: compress.Options, max_memory: int) -> (err: Error) {
	clear(output)
	if data[0] == 0 {
		return XZ_Error.Index_Mismatch
	}
	d := Decoder{
		input           = data,
		output          = output,
		flags           = flags,
		max_output_size = int(b.uncompressed_size),
		max_memory      = max_memory,
		total_out       = int(b.uncompressed_size),
		options         = options,
		check_id        = check_id,
	}
	lzma.lzma2_decoder_init(&d.lzma2)
	defer lzma.lzma2_decoder_destroy(&d.lzma2)
	unpadded, uncompressed, block_err := _decode_block(&d)
	if block_err == General_Error.Output_Too_Short || block_err == General_Error.Stream_Too_Short {
		return XZ_Error.Index_Mismatch
	}
	if block_err != nil {
		return block_err
	}
	if unpadded != u64(b.unpadded_size) || uncompressed != u64(b.uncompressed_size) {
		return XZ_Error.Index_Mismatch
	}
	return nil
}

@(private)
_skip_padding :: proc(src: ^Index_Source, end: i64) -> (pos: i64, err: Error) {
	pos = end
	for pos > 0 {
		chunk := min(pos, INDEX_SCAN_CHUNK)
		data  := _source_read(src, pos - chunk, int(chunk)) or_return
		i := len(data)
		for i > 0 && data[i - 1] == 0 {
			i -= 1
		}
		pos -= i64(len(data) - i)
		if i > 0 {
			break
		}
	}
	return
}

@(private)
_source_read :: proc(src: ^Index_Source, offset: i64, n: int) -> (data: []u8, err: Error) {
	if !src.is_stream {
		return src.bytes[int(offset):][:n], nil
	}
	non_zero_resize(&src.buffer, n) or_return
	_, read_err := io.read_full_at(src.stream, src.buffer[:], offset)
	if read_err == .EOF || read_err == .Unexpected_EOF {
		return nil, General_Error.Stream_Too_Short
	}
	if read_err != nil {
		return nil, read_err
	}
	return src.buffer[:], nil
}

@(private)
_padded_size :: proc "contextless" (unpadded: i64) -> i64 {
	return (unpadded + 3) &~ 3
}
