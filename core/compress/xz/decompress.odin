package compress_xz

import "core:compress"
import "core:compress/filters"
import "core:compress/lzma"
import "core:crypto/sha2"
import "core:encoding/endian"
import "core:hash"
import "core:io"

decompress :: proc{decompress_from_bytes, decompress_from_context}

decompress_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, flags := Decode_Flags{}, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if output == nil {
		return General_Error.Incompatible_Options
	}
	_check_options(options) or_return
	max_output_size := compress.output_limit(options)
	expected := compress.declared_size(expected_output_size)
	if expected > max_output_size {
		return General_Error.Output_Too_Short
	}
	d := Decoder{
		input           = input,
		output          = output,
		flags           = flags,
		max_output_size = expected if expected >= 0 else max_output_size,
		max_memory      = compress.memory_limit(options),
		total_out       = expected,
		options         = options,
	}
	lzma.lzma2_decoder_init(&d.lzma2, allocator)
	defer lzma.lzma2_decoder_destroy(&d.lzma2)
	clear(output)
	if expected > 0 {
		reserve(output, min(expected, compress.COMPRESS_INITIAL_RESERVATION))
	}
	err = _decode(&d)
	if expected >= 0 && (err == General_Error.Output_Too_Short || (err == nil && len(output^) != expected)) {
		err = General_Error.Size_Mismatch
	}
	return
}

decompress_from_context :: proc(z: ^compress.Context, flags := Decode_Flags{}, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	if z.output == nil {
		return General_Error.Incompatible_Options
	}
	if compress.is_memory_context(z) {
		input := z.window
		err = decompress_from_bytes(z.output, input, flags, expected_output_size, options, allocator)
		z.window        = z.window[len(z.window):]
		z.bytes_written = i64(len(z.output^))
		return
	}
	_check_options(options) or_return
	if compress.declared_size(expected_output_size) > compress.output_limit(options) {
		return General_Error.Output_Too_Short
	}
	limit := compress.memory_limit(options)
	if len(z.window) > limit {
		return General_Error.Memory_Limit_Exceeded
	}
	buffer := make([dynamic]u8, 0, len(z.window), allocator) or_return
	defer delete(buffer)
	append(&buffer, ..z.window) or_return
	z.window = z.window[len(z.window):]
	chunk: [64 * 1024]u8
	for {
		n, read_err := io.read(z.input, chunk[:])
		if n > limit - len(buffer) {
			return General_Error.Memory_Limit_Exceeded
		}
		if len(buffer) + n > cap(buffer) {
			grow := min(cap(buffer), limit - cap(buffer))
			reserve(&buffer, min(max(len(buffer) + n, len(chunk), cap(buffer) + grow), limit)) or_return
		}
		append(&buffer, ..chunk[:n]) or_return
		if read_err == .EOF {
			break
		}
		if read_err != nil {
			return read_err
		}
	}
	inner := options
	inner.max_memory = max(limit - len(buffer), 1)
	err = decompress_from_bytes(z.output, buffer[:], flags, expected_output_size, inner, allocator)
	z.bytes_written = i64(len(z.output^))
	return
}

@(private)
Decoder :: struct {
	input:            []u8,
	pos:              int,
	output:           ^[dynamic]u8,
	flags:            Decode_Flags,
	max_output_size:  int,
	max_memory:       int,
	total_out:        int,
	options:          compress.Options,
	data_start:       int,
	lzma2:            lzma.LZMA2_Decoder,
	check_id:         u8,
	stream_flags:     [2]u8,
	records:          u64,
	unpadded_sum:     u64,
	uncompressed_sum: u64,
	index_hash:       sha2.Context_256,
}

@(private)
_decode :: proc(d: ^Decoder) -> (err: Error) {
	if len(d.input) == 0 {
		return General_Error.Stream_Too_Short
	}
	_decode_stream(d) or_return
	for d.pos < len(d.input) {
		padding_start := d.pos
		for d.pos < len(d.input) && d.input[d.pos] == 0 {
			d.pos += 1
		}
		padding := d.pos - padding_start
		if d.pos == len(d.input) {
			if padding % 4 != 0 {
				return XZ_Error.Invalid_Padding
			}
			break
		}
		if len(d.input) - d.pos < len(HEADER_MAGIC) || string(d.input[d.pos:][:len(HEADER_MAGIC)]) != string(HEADER_MAGIC[:]) {
			if len(d.input) - d.pos < len(HEADER_MAGIC) && string(d.input[d.pos:]) == string(HEADER_MAGIC[:len(d.input) - d.pos]) {
				return General_Error.Stream_Too_Short
			}
			return XZ_Error.Data_After_End
		}
		if padding % 4 != 0 {
			return XZ_Error.Invalid_Padding
		}
		_decode_stream(d) or_return
	}
	return nil
}

@(private)
_decode_stream :: proc(d: ^Decoder) -> (err: Error) {
	header := _take(d, HEADER_SIZE) or_return
	if string(header[:len(HEADER_MAGIC)]) != string(HEADER_MAGIC[:]) {
		return XZ_Error.Invalid_Magic
	}
	if hash.crc32(header[6:8]) != endian.unchecked_get_u32le(header[8:12]) {
		return XZ_Error.Header_Checksum_Failed
	}
	if header[6] != 0 || header[7] & 0xF0 != 0 {
		return XZ_Error.Reserved_Bit_Set
	}
	d.stream_flags     = {header[6], header[7]}
	d.check_id         = header[7] & 0x0F
	d.records          = 0
	d.unpadded_sum     = 0
	d.uncompressed_sum = 0
	sha2.init_256(&d.index_hash)
	defer sha2.reset(&d.index_hash)

	for {
		if d.pos >= len(d.input) {
			return General_Error.Stream_Too_Short
		}
		if d.input[d.pos] == 0 {
			break
		}
		unpadded, uncompressed := _decode_block(d) or_return
		_index_add(d, unpadded, uncompressed) or_return
	}
	index_size := _decode_index(d) or_return

	footer := _take(d, FOOTER_SIZE) or_return
	if hash.crc32(footer[4:10]) != endian.unchecked_get_u32le(footer[0:4]) {
		return XZ_Error.Header_Checksum_Failed
	}
	if string(footer[10:12]) != string(FOOTER_MAGIC[:]) {
		return XZ_Error.Invalid_Magic
	}
	if footer[8] != d.stream_flags[0] || footer[9] != d.stream_flags[1] {
		return XZ_Error.Footer_Mismatch
	}
	backward := (u64(endian.unchecked_get_u32le(footer[4:8])) + 1) * 4
	if backward != u64(index_size) {
		return XZ_Error.Index_Mismatch
	}
	return nil
}

@(private)
_decode_block :: proc(d: ^Decoder) -> (unpadded, uncompressed_size: u64, err: Error) {
	block_start := d.pos
	header_size := (int(d.input[d.pos]) + 1) * 4
	header      := _take(d, header_size) or_return
	if hash.crc32(header[:header_size - 4]) != endian.unchecked_get_u32le(header[header_size - 4:]) {
		return 0, 0, XZ_Error.Header_Checksum_Failed
	}
	block_flags := header[1]
	if block_flags & 0x3C != 0 {
		return 0, 0, XZ_Error.Reserved_Bit_Set
	}
	body := header[:header_size - 4]
	p    := 2

	compressed   := u64(0)
	uncompressed := u64(0)
	has_compressed   := block_flags & 0x40 != 0
	has_uncompressed := block_flags & 0x80 != 0
	if has_compressed {
		value, ok := _read_vli(body, &p)
		if !ok || value == 0 {
			return 0, 0, XZ_Error.Invalid_Block_Header
		}
		compressed = value
	}
	if has_uncompressed {
		value, ok := _read_vli(body, &p)
		if !ok {
			return 0, 0, XZ_Error.Invalid_Block_Header
		}
		uncompressed = value
	}

	chain: [FILTERS_MAX]Block_Filter
	count     := int(block_flags & 0x03) + 1
	dict_size := u32(0)
	for i in 0..<count {
		id, id_ok := _read_vli(body, &p)
		props_size, props_ok := _read_vli(body, &p)
		if !id_ok || !props_ok || props_size > u64(len(body) - p) {
			return 0, 0, XZ_Error.Invalid_Block_Header
		}
		props := body[p:][:int(props_size)]
		p += int(props_size)
		last := i == count - 1
		switch id {
		case u64(Filter_ID.LZMA2):
			if !last || len(props) != 1 {
				return 0, 0, XZ_Error.Invalid_Filter_Chain
			}
			size, size_err := lzma.lzma2_dict_size(props[0])
			if size_err != nil {
				return 0, 0, XZ_Error.Invalid_Filter_Chain
			}
			dict_size = size
		case u64(Filter_ID.Delta):
			if last || len(props) != 1 || !filters.delta_init(&chain[i].delta, int(props[0]) + 1) {
				return 0, 0, XZ_Error.Invalid_Filter_Chain
			}
		case u64(Filter_ID.X86) ..= u64(Filter_ID.RISCV):
			if last || (len(props) != 0 && len(props) != 4) {
				return 0, 0, XZ_Error.Invalid_Filter_Chain
			}
			start := u32(0)
			if len(props) == 4 {
				start = endian.unchecked_get_u32le(props)
			}
			if !filters.branch_init(&chain[i].branch, _branch_arch(Filter_ID(id)), start) {
				return 0, 0, XZ_Error.Invalid_Filter_Chain
			}
		case:
			return 0, 0, XZ_Error.Unsupported_Filter
		}
		chain[i].id = Filter_ID(id)
	}
	for b in body[p:] {
		if b != 0 {
			return 0, 0, XZ_Error.Reserved_Bit_Set
		}
	}

	data_start := d.pos
	available  := len(d.input) - data_start
	data       := d.input[data_start:]
	if has_compressed {
		if compressed > u64(available) {
			return 0, 0, General_Error.Stream_Too_Short
		}
		data = data[:int(compressed)]
	}
	start    := len(d.output^)
	room     := d.max_output_size - start
	expected := -1
	if has_uncompressed {
		if uncompressed > u64(room) {
			return 0, 0, General_Error.Output_Too_Short
		}
		expected = int(uncompressed)
	} else if room == 0 {
		expected = 0
	}
	inner := compress.Options{max_output_size = d.max_output_size, max_memory = d.max_memory}
	if d.options.progress != nil {
		inner.progress          = _decode_progress
		inner.progress_data     = d
		inner.progress_interval = d.options.progress_interval
		d.data_start            = data_start
	}
	consumed, lzma_err := lzma.decompress_lzma2_append(&d.lzma2, d.output, data, dict_size, expected, inner)
	if lzma_err != nil {
		if has_uncompressed && lzma_err == General_Error.Output_Too_Short {
			return 0, 0, General_Error.Size_Mismatch
		}
		if !has_uncompressed && expected == 0 && lzma_err == General_Error.Size_Mismatch {
			return 0, 0, General_Error.Output_Too_Short
		}
		if has_compressed && lzma_err == General_Error.Stream_Too_Short {
			return 0, 0, General_Error.Size_Mismatch
		}
		return 0, 0, lzma_err
	}
	if has_compressed && u64(consumed) != compressed {
		return 0, 0, General_Error.Size_Mismatch
	}
	d.pos = data_start + consumed

	out := d.output^[start:]
	for i := count - 2; i >= 0; i -= 1 {
		if chain[i].id == .Delta {
			filters.delta_decode(&chain[i].delta, out)
		} else {
			filters.branch_decode(&chain[i].branch, out)
		}
	}

	for (d.pos - block_start) % 4 != 0 {
		pad := _take(d, 1) or_return
		if pad[0] != 0 {
			return 0, 0, XZ_Error.Invalid_Padding
		}
	}
	check_size := CHECK_SIZES[d.check_id]
	check      := _take(d, check_size) or_return
	if .Ignore_Check not_in d.flags {
		_verify_check(d.check_id, out, check) or_return
	}

	return u64(header_size + consumed + check_size), u64(len(out)), nil
}

@(private)
_decode_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	d := (^Decoder)(user_data)
	return compress.report_progress(d.options, i64(d.data_start) + progress.bytes_in, progress.bytes_out, i64(len(d.input)), i64(d.total_out)) != nil
}

@(private)
_verify_check :: proc(check_id: u8, data, check: []u8) -> (err: Error) {
	switch Check(check_id) {
	case .None:
	case .CRC32:
		if hash.crc32(data) != endian.unchecked_get_u32le(check) {
			return XZ_Error.Block_Checksum_Failed
		}
	case .CRC64:
		if hash.crc64_xz(data) != endian.unchecked_get_u64le(check) {
			return XZ_Error.Block_Checksum_Failed
		}
	case .SHA256:
		ctx: sha2.Context_256
		sha2.init_256(&ctx)
		sha2.update(&ctx, data)
		digest: [sha2.DIGEST_SIZE_256]u8
		sha2.final(&ctx, digest[:])
		if string(digest[:]) != string(check) {
			return XZ_Error.Block_Checksum_Failed
		}
	}
	return nil
}

@(private)
_index_add :: proc(d: ^Decoder, unpadded, uncompressed: u64) -> (err: Error) {
	if unpadded > VLI_MAX - d.unpadded_sum || uncompressed > VLI_MAX - d.uncompressed_sum {
		return XZ_Error.Input_Too_Large
	}
	d.records          += 1
	d.unpadded_sum     += unpadded
	d.uncompressed_sum += uncompressed
	_hash_record(&d.index_hash, unpadded, uncompressed)
	return nil
}

@(private)
_decode_index :: proc(d: ^Decoder) -> (size: int, err: Error) {
	index_start := d.pos
	d.pos += 1
	rest := d.input[:index_start + int(min(u64(len(d.input) - index_start), INDEX_SIZE_MAX))]

	count_start := d.pos
	count, count_ok := _read_vli(rest, &d.pos)
	if !count_ok {
		return 0, _short_or(d, rest, count_start, XZ_Error.Invalid_Index)
	}
	if count != d.records {
		return 0, XZ_Error.Index_Mismatch
	}
	verify: sha2.Context_256
	sha2.init_256(&verify)
	defer sha2.reset(&verify)
	unpadded_sum, uncompressed_sum: u64
	for _ in 0..<count {
		unpadded_start := d.pos
		unpadded, unpadded_ok := _read_vli(rest, &d.pos)
		if !unpadded_ok {
			return 0, _short_or(d, rest, unpadded_start, XZ_Error.Invalid_Index)
		}
		uncompressed_start := d.pos
		uncompressed, uncompressed_ok := _read_vli(rest, &d.pos)
		if !uncompressed_ok {
			return 0, _short_or(d, rest, uncompressed_start, XZ_Error.Invalid_Index)
		}
		if unpadded < UNPADDED_SIZE_MIN || unpadded > VLI_MAX - unpadded_sum || uncompressed > VLI_MAX - uncompressed_sum {
			return 0, XZ_Error.Invalid_Index
		}
		unpadded_sum     += unpadded
		uncompressed_sum += uncompressed
		_hash_record(&verify, unpadded, uncompressed)
	}
	for (d.pos - index_start) % 4 != 0 {
		pad := _take(d, 1) or_return
		if pad[0] != 0 {
			return 0, XZ_Error.Invalid_Index
		}
	}
	crc := _take(d, 4) or_return
	if hash.crc32(d.input[index_start:d.pos - 4]) != endian.unchecked_get_u32le(crc) {
		return 0, XZ_Error.Header_Checksum_Failed
	}
	if unpadded_sum != d.unpadded_sum || uncompressed_sum != d.uncompressed_sum {
		return 0, XZ_Error.Index_Mismatch
	}
	want, got: [sha2.DIGEST_SIZE_256]u8
	sha2.final(&d.index_hash, want[:])
	sha2.final(&verify, got[:])
	if want != got {
		return 0, XZ_Error.Index_Mismatch
	}
	return d.pos - index_start, nil
}

@(private)
_hash_record :: proc(ctx: ^sha2.Context_256, unpadded, uncompressed: u64) {
	buf: [2 * VLI_BYTES_MAX]u8
	n := _write_vli(buf[:], unpadded)
	n += _write_vli(buf[n:], uncompressed)
	sha2.update(ctx, buf[:n])
}

@(private)
_short_or :: proc(d: ^Decoder, rest: []u8, start: int, err: Error) -> Error {
	read := d.pos - start
	if d.pos >= len(rest) && len(rest) == len(d.input) && read < VLI_BYTES_MAX && (read == 0 || rest[d.pos - 1] & 0x80 != 0) {
		return General_Error.Stream_Too_Short
	}
	return err
}

@(private)
_take :: proc(d: ^Decoder, n: int) -> (data: []u8, err: Error) {
	if n > len(d.input) - d.pos {
		return nil, General_Error.Stream_Too_Short
	}
	data = d.input[d.pos:][:n]
	d.pos += n
	return data, nil
}

@(private)
_read_vli :: proc "contextless" (data: []u8, pos: ^int) -> (value: u64, ok: bool) {
	for i in 0..<VLI_BYTES_MAX {
		if pos^ >= len(data) {
			return 0, false
		}
		b := data[pos^]
		pos^ += 1
		value |= u64(b & 0x7F) << uint(7 * i)
		if b & 0x80 == 0 {
			if i > 0 && b == 0 {
				return 0, false
			}
			return value, true
		}
	}
	return 0, false
}

@(private)
_write_vli :: proc "contextless" (buf: []u8, value: u64) -> (n: int) {
	v := value
	for v >= 0x80 {
		buf[n] = u8(v) | 0x80
		v >>= 7
		n += 1
	}
	buf[n] = u8(v)
	return n + 1
}

@(private)
_branch_arch :: proc "contextless" (id: Filter_ID) -> filters.Branch_Arch {
	#partial switch id {
	case .PowerPC:   return .PowerPC
	case .IA64:      return .IA64
	case .ARM:       return .ARM
	case .ARM_Thumb: return .ARM_Thumb
	case .SPARC:     return .SPARC
	case .ARM64:     return .ARM64
	case .RISCV:     return .RISCV
	}
	return .X86
}
