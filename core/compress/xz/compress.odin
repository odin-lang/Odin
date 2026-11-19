package compress_xz

import "core:compress"
import "core:compress/filters"
import "core:compress/lzma"
import "core:crypto/sha2"
import "core:encoding/endian"
import "core:hash"

compress :: proc{compress_to_slice, compress_to_dynamic}

level_options :: proc(level := Level.Default) -> (options: Options) {
	options.lzma2 = lzma.level_options(level)
	options.check = .CRC64
	return
}

compress_bound :: proc(length: int, level := Level.Default, xz_options := Options{}) -> int {
	if length < 0 {
		return -1
	}
	opts, err := _resolve(level, xz_options)
	if err != nil {
		return -1
	}
	block := length
	if opts.block_size > 0 && opts.block_size < length {
		block = opts.block_size
	}
	blocks := 0
	if length > 0 {
		blocks = (length - 1) / block + 1
	}
	per_block := lzma.compress_lzma2_bound(block)
	if per_block < 0 {
		return -1
	}
	per_block += BLOCK_HEADER_GAP + 3 + 64 + INDEX_RECORD_MAX
	overhead := HEADER_SIZE + FOOTER_SIZE + 1 + VLI_BYTES_MAX + 3 + 4
	if blocks > 0 && per_block > (max(int) - overhead) / blocks {
		return -1
	}
	return blocks * per_block + overhead
}

compress_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Level.Default, xz_options := Options{}, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	if output == nil {
		return General_Error.Incompatible_Options
	}
	context.allocator = allocator
	_check_options(options) or_return
	opts := _resolve(level, xz_options) or_return
	clear(output)
	s := Sink{dynamic_output = output, limit = compress.output_limit(options)}
	if err = _encode(&s, input, opts, options); err != nil {
		clear(output)
	}
	return
}

compress_to_slice :: proc(output, input: []u8, level := Level.Default, xz_options := Options{}, options: compress.Options = {}, allocator := context.allocator) -> (written: int, err: Error) {
	context.allocator = allocator
	_check_options(options) or_return
	opts := _resolve(level, xz_options) or_return
	limited := output
	if options.max_output_size > 0 && options.max_output_size < len(output) {
		limited = output[:options.max_output_size]
	}
	s := Sink{slice_output = limited, limit = len(limited)}
	_encode(&s, input, opts, options) or_return
	return s.pos, nil
}

@(private)
BLOCK_HEADER_GAP :: 64

@(private)
Sink :: struct {
	dynamic_output: ^[dynamic]u8,
	slice_output:   []u8,
	pos:            int,
	limit:          int,
}

@(private)
_sink_bytes :: proc(s: ^Sink) -> []u8 {
	if s.dynamic_output != nil {
		return s.dynamic_output[:]
	}
	return s.slice_output
}

@(private)
_sink_take :: proc(s: ^Sink, n: int) -> (region: []u8, err: Error) {
	if n > s.limit - s.pos {
		return nil, General_Error.Output_Too_Short
	}
	if s.dynamic_output != nil {
		non_zero_resize(s.dynamic_output, s.pos + n) or_return
	}
	region = _sink_bytes(s)[s.pos:][:n]
	s.pos += n
	return
}

@(private)
_sink_put :: proc(s: ^Sink, data: []u8) -> (err: Error) {
	region := _sink_take(s, len(data)) or_return
	copy(region, data)
	return nil
}

@(private)
_resolve :: proc(level: Level, options: Options) -> (opts: Options, err: Error) {
	opts = options
	if opts.lzma2.dict_size == 0 {
		opts.lzma2 = lzma.level_options(level)
	}
	check := opts.check.? or_else .CRC64
	switch check {
	case .None, .CRC32, .CRC64, .SHA256:
	case:
		return {}, General_Error.Incompatible_Options
	}
	opts.check = check
	switch {
	case opts.block_size == 0:
		block := max(3 * i64(opts.lzma2.dict_size), BLOCK_SIZE_MIN)
		opts.block_size = int(min(block, i64(max(int))))
	case opts.block_size < 0:
		opts.block_size = -1
	}
	if opts.filter_count < 0 || opts.filter_count > FILTERS_MAX - 1 {
		return {}, XZ_Error.Invalid_Filter_Chain
	}
	for f in opts.filters[:opts.filter_count] {
		#partial switch f.id {
		case .Delta:
			state: filters.Delta_State
			if !filters.delta_init(&state, f.delta_distance) {
				return {}, XZ_Error.Invalid_Filter_Chain
			}
		case .X86, .PowerPC, .IA64, .ARM, .ARM_Thumb, .SPARC, .ARM64, .RISCV:
			state: filters.Branch_State
			if !filters.branch_init(&state, _branch_arch(f.id), f.start_offset) {
				return {}, XZ_Error.Invalid_Filter_Chain
			}
		case:
			return {}, XZ_Error.Invalid_Filter_Chain
		}
	}
	return opts, nil
}

@(private)
_encode :: proc(s: ^Sink, input: []u8, opts: Options, options: compress.Options) -> (err: Error) {
	opts := opts
	check      := opts.check.? or_else .CRC64
	check_size := CHECK_SIZES[u8(check)]
	flags      := [2]u8{0, u8(check)}

	block := len(input)
	if opts.block_size > 0 && opts.block_size < len(input) {
		block = opts.block_size
	}
	scratch_size := block if opts.filter_count > 0 && len(input) > 0 else 0
	memory       := compress.memory_limit(options)
	if scratch_size > memory {
		return General_Error.Memory_Limit_Exceeded
	}
	p     := Encode_Progress{options = options, total_in = i64(len(input)), mark = max(i64)}
	inner := compress.Options{max_memory = max(memory - scratch_size, 1)}
	if s.dynamic_output != nil {
		inner.max_output_size = s.limit
	}
	if options.progress != nil {
		p.mark                  = i64(compress.progress_interval(options))
		inner.progress          = _encode_progress
		inner.progress_data     = &p
		inner.progress_interval = options.progress_interval
	}

	header: [HEADER_SIZE]u8
	copy(header[:], HEADER_MAGIC[:])
	header[6], header[7] = flags[0], flags[1]
	endian.unchecked_put_u32le(header[8:12], hash.crc32(flags[:]))
	_sink_put(s, header[:]) or_return

	scratch: []u8
	if scratch_size > 0 {
		scratch = make([]u8, scratch_size) or_return
	}
	defer delete(scratch)
	records: [dynamic][2]u64
	defer delete(records)

	for offset := 0; offset < len(input); offset += block {
		plain := input[offset:][:min(block, len(input) - offset)]
		data  := plain
		if opts.filter_count > 0 {
			data = scratch[:len(plain)]
			copy(data, plain)
			for f in opts.filters[:opts.filter_count] {
				if f.id == .Delta {
					state: filters.Delta_State
					filters.delta_init(&state, f.delta_distance)
					filters.delta_encode(&state, data)
				} else {
					state: filters.Branch_State
					filters.branch_init(&state, _branch_arch(f.id), f.start_offset)
					filters.branch_encode(&state, data)
				}
			}
		}

		block_header: [BLOCK_HEADER_GAP]u8
		gap := _block_header(block_header[:], opts, {dict_size = opts.lzma2.dict_size}, u64(lzma.compress_lzma2_bound(len(data))), u64(len(plain)))
		header_pos := s.pos
		_sink_take(s, gap) or_return
		props: lzma.Properties
		packed: int
		p.base_in = i64(offset)
		if s.dynamic_output != nil {
			p.base_out = -i64(gap)
			props = lzma.compress_lzma2_append(s.dynamic_output, data, opts.lzma2, inner) or_return
			packed = len(s.dynamic_output) - s.pos
		} else {
			p.base_out = i64(header_pos)
			packed, props = lzma.compress_lzma2_to_slice(s.slice_output[s.pos:], data, opts.lzma2, inner) or_return
		}

		size := _block_header(block_header[:], opts, props, u64(packed), u64(len(plain)))
		buf  := _sink_bytes(s)
		copy(buf[header_pos + size:], buf[header_pos + gap:][:packed])
		copy(buf[header_pos:], block_header[:size])
		s.pos = header_pos + size + packed
		if s.dynamic_output != nil {
			non_zero_resize(s.dynamic_output, s.pos)
		}

		zero: [4]u8
		if rest := (s.pos - header_pos) % 4; rest != 0 {
			_sink_put(s, zero[:4 - rest]) or_return
		}
		region := _sink_take(s, check_size) or_return
		switch check {
		case .None:
		case .CRC32:
			endian.unchecked_put_u32le(region, hash.crc32(plain))
		case .CRC64:
			endian.unchecked_put_u64le(region, hash.crc64_xz(plain))
		case .SHA256:
			ctx: sha2.Context_256
			sha2.init_256(&ctx)
			sha2.update(&ctx, plain)
			sha2.final(&ctx, region)
		}
		append(&records, [2]u64{u64(size + packed + check_size), u64(len(plain))}) or_return
		if end := i64(offset + len(plain)); end < p.total_in && end >= p.mark {
			_encode_report(&p, end, i64(s.pos)) or_return
		}
	}

	index_start := s.pos
	vli: [VLI_BYTES_MAX]u8
	_sink_put(s, {0x00}) or_return
	_sink_put(s, vli[:_write_vli(vli[:], u64(len(records)))]) or_return
	for r in records {
		_sink_put(s, vli[:_write_vli(vli[:], r[0])]) or_return
		_sink_put(s, vli[:_write_vli(vli[:], r[1])]) or_return
	}
	zero: [4]u8
	if rest := (s.pos - index_start) % 4; rest != 0 {
		_sink_put(s, zero[:4 - rest]) or_return
	}
	crc: [4]u8
	endian.unchecked_put_u32le(crc[:], hash.crc32(_sink_bytes(s)[index_start:s.pos]))
	_sink_put(s, crc[:]) or_return
	index_size := s.pos - index_start

	footer: [FOOTER_SIZE]u8
	endian.unchecked_put_u32le(footer[4:8], u32(index_size / 4 - 1))
	footer[8], footer[9] = flags[0], flags[1]
	copy(footer[10:], FOOTER_MAGIC[:])
	endian.unchecked_put_u32le(footer[0:4], hash.crc32(footer[4:10]))
	_sink_put(s, footer[:]) or_return
	return compress.report_progress(options, i64(len(input)), i64(s.pos), i64(len(input)), -1)
}

@(private)
_encode_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	p := (^Encode_Progress)(user_data)
	bytes_in := p.base_in + progress.bytes_in
	if bytes_in < p.mark || bytes_in >= p.total_in {
		return false
	}
	return _encode_report(p, bytes_in, p.base_out + progress.bytes_out) != nil
}

@(private)
_encode_report :: proc(p: ^Encode_Progress, bytes_in, bytes_out: i64) -> (err: Error) {
	interval := i64(compress.progress_interval(p.options))
	p.mark = bytes_in + interval if interval <= max(i64) - bytes_in else max(i64)
	return compress.report_progress(p.options, bytes_in, bytes_out, p.total_in, -1)
}

@(private)
_block_header :: proc(b: []u8, opts: Options, props: lzma.Properties, packed, size: u64, sizes := true) -> (n: int) {
	opts := opts
	b[1] = u8(opts.filter_count)
	n = 2
	if sizes {
		b[1] |= 0x40 | 0x80
		n += _write_vli(b[n:], packed)
		n += _write_vli(b[n:], size)
	}
	for f in opts.filters[:opts.filter_count] {
		n += _write_vli(b[n:], u64(f.id))
		switch {
		case f.id == .Delta:
			b[n], b[n + 1] = 1, u8(f.delta_distance - 1)
			n += 2
		case f.start_offset != 0:
			b[n] = 4
			endian.unchecked_put_u32le(b[n + 1:][:4], f.start_offset)
			n += 5
		case:
			b[n] = 0
			n += 1
		}
	}
	b[n], b[n + 1], b[n + 2] = u8(Filter_ID.LZMA2), 1, lzma.lzma2_dict_prop(props.dict_size)
	n += 3
	for (n + 4) % 4 != 0 {
		b[n] = 0
		n += 1
	}
	b[0] = u8((n + 4) / 4 - 1)
	endian.unchecked_put_u32le(b[n:][:4], hash.crc32(b[:n]))
	return n + 4
}

