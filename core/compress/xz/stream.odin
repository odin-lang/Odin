package compress_xz

import "core:compress"
import "core:compress/filters"
import "core:compress/lzma"
import "core:crypto/sha2"
import "core:encoding/endian"
import "core:hash"
import "core:io"

decompress_to_writer :: proc(w: io.Writer, z: ^compress.Context, flags := Decode_Flags{}, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	reader_init(&r, z, flags, expected_output_size, options, allocator) or_return
	buf: [64 * 1024]u8
	for {
		n, read_err := reader_read(&r, buf[:])
		if n > 0 {
			if _, write_err := io.write_full(w, buf[:n]); write_err != nil {
				return write_err
			}
		}
		if read_err != nil {
			if io_err, is_io := read_err.(io.Error); is_io && io_err == .EOF {
				return nil
			}
			return read_err
		}
	}
}

reader_init :: proc(r: ^Reader, z: ^compress.Context, flags := Decode_Flags{}, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r^ = {}
	r.z         = z
	r.flags     = flags
	r.options   = options
	r.allocator = allocator
	r.size      = compress.declared_size(expected_output_size)
	r.total_in  = -1
	defer r.err = err
	_check_options(options) or_return
	if options.max_output_size > 0 && r.size > options.max_output_size {
		return General_Error.Output_Too_Short
	}
	if options.progress != nil {
		r.total_in = i64(compress.input_size(z))
	}
	return _stream_header(r)
}

reader_read :: proc(r: ^Reader, p: []u8) -> (n: int, err: Error) {
	was_done := r.done
	limit    := i64(r.options.max_output_size) if r.options.max_output_size > 0 else -1
	overflow := Error(General_Error.Output_Too_Short)
	if r.size >= 0 {
		limit    = i64(r.size)
		overflow = General_Error.Size_Mismatch
	}
	for n < len(p) && r.err == nil && !r.done {
		if !r.in_block {
			r.err = _next(r)
			continue
		}
		dst := p[n:]
		if limit >= 0 {
			dst = dst[:min(i64(len(dst)), max(limit - r.produced, 0) + 1)]
		}
		got:      int
		read_err: Error
		if r.chain_count > 0 {
			got, read_err = filters.reader_read(&r.chain[0], dst)
		} else {
			got, read_err = lzma.reader_read(&r.lzma, dst)
		}
		if got > 0 {
			if limit >= 0 && r.produced + i64(got) > limit {
				got   = int(limit - r.produced)
				r.err = overflow
			}
			_block_output(r, dst[:got])
			n += got
			if r.err != nil {
				break
			}
			if r.has_uncompressed && r.block_out > r.uncompressed {
				r.err = General_Error.Size_Mismatch
				break
			}
		}
		if read_err != nil {
			if io_err, is_io := read_err.(io.Error); is_io && io_err == .EOF {
				r.err = _finish_block(r)
			} else {
				r.err = _block_error(r, read_err)
			}
		}
	}
	if r.done && !was_done && r.err == nil && r.size >= 0 && r.produced != i64(r.size) {
		r.err = General_Error.Size_Mismatch
	}
	if (n > 0 || (r.done && !was_done)) && r.err == nil {
		r.err = compress.report_progress(r.options, _consumed(r), r.produced, r.total_in, i64(r.size))
	}
	if n > 0 {
		return n, nil
	}
	if r.err != nil {
		return 0, r.err
	}
	if len(p) > 0 && r.done {
		return 0, io.Error.EOF
	}
	return 0, nil
}

reader_to_stream :: proc(r: ^Reader) -> (s: io.Stream) {
	s.data      = r
	s.procedure = _reader_stream_proc
	return
}

reader_destroy :: proc(r: ^Reader) {
	_end_block(r)
	sha2.reset(&r.index_hash)
	sha2.reset(&r.sha256)
	delete(r.block_backing, r.allocator)
	r.block_backing = nil
	r.done = true
}

writer_init :: proc(xw: ^Writer, w: io.Writer, level := Level.Default, xz_options := Options{}, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	xw^ = {}
	xw.w                 = w
	xw.options           = options
	xw.allocator         = allocator
	xw.records.allocator = allocator
	defer xw.err = err
	defer if err != nil {
		writer_destroy(xw)
	}
	_check_options(options) or_return
	xw.opts        = _resolve(level, xz_options) or_return
	xw.check       = xw.opts.check.? or_else .CRC64
	xw.next_report = i64(compress.progress_interval(options))
	_writer_open_block(xw) or_return
	header: [HEADER_SIZE]u8
	copy(header[:], HEADER_MAGIC[:])
	header[7] = u8(xw.check)
	endian.unchecked_put_u32le(header[8:12], hash.crc32(header[6:8]))
	return _writer_put(xw, header[:])
}

writer_write :: proc(xw: ^Writer, p: []u8) -> (n: int, err: Error) {
	if xw.err != nil {
		return 0, xw.err
	}
	if xw.finished {
		return 0, io.Error.Closed
	}
	defer xw.err = err
	for n < len(p) {
		if !xw.open {
			_writer_open_block(xw) or_return
		}
		if !xw.in_block {
			_writer_begin_block(xw) or_return
		}
		k := len(p) - n
		if xw.opts.block_size > 0 {
			k = int(min(u64(k), u64(xw.opts.block_size) - xw.block_in))
		}
		chunk := p[n:][:k]
		write_err: Error
		if xw.chain_count > 0 {
			_, write_err = filters.writer_write(&xw.chain[0], chunk)
		} else {
			_, write_err = lzma.writer_write(&xw.lzma, chunk)
		}
		if write_err != nil {
			return n, write_err
		}
		switch xw.check {
		case .None:
		case .CRC32:
			xw.crc32 = hash.crc32(chunk, xw.crc32)
		case .CRC64:
			xw.crc64 = hash.crc64_xz(chunk, xw.crc64)
		case .SHA256:
			sha2.update(&xw.sha256, chunk)
		}
		xw.block_in += u64(k)
		xw.total_in += i64(k)
		n           += k
		if xw.opts.block_size > 0 && xw.block_in == u64(xw.opts.block_size) {
			_writer_end_block(xw) or_return
		}
		if xw.total_in >= xw.next_report {
			xw.next_report = xw.total_in + i64(compress.progress_interval(xw.options))
			compress.report_progress(xw.options, xw.total_in, xw.total_out, -1, -1) or_return
		}
	}
	return
}

writer_finish :: proc(xw: ^Writer) -> (err: Error) {
	if xw.err != nil {
		return xw.err
	}
	if xw.finished {
		return nil
	}
	defer xw.err = err
	if xw.in_block {
		_writer_end_block(xw) or_return
	}
	_writer_drop_block(xw)

	crc:  u32
	size: i64
	vli:  [VLI_BYTES_MAX]u8
	_writer_index_put(xw, {0x00}, &crc, &size) or_return
	_writer_index_put(xw, vli[:_write_vli(vli[:], u64(len(xw.records)))], &crc, &size) or_return
	for record in xw.records {
		_writer_index_put(xw, vli[:_write_vli(vli[:], record[0])], &crc, &size) or_return
		_writer_index_put(xw, vli[:_write_vli(vli[:], record[1])], &crc, &size) or_return
	}
	zero: [4]u8
	if rest := size % 4; rest != 0 {
		_writer_index_put(xw, zero[:4 - rest], &crc, &size) or_return
	}
	stored: [4]u8
	endian.unchecked_put_u32le(stored[:], crc)
	_writer_put(xw, stored[:]) or_return
	size += 4

	footer: [FOOTER_SIZE]u8
	endian.unchecked_put_u32le(footer[4:8], u32(size / 4 - 1))
	footer[9] = u8(xw.check)
	copy(footer[10:], FOOTER_MAGIC[:])
	endian.unchecked_put_u32le(footer[0:4], hash.crc32(footer[4:10]))
	_writer_put(xw, footer[:]) or_return
	xw.finished = true
	return compress.report_progress(xw.options, xw.total_in, xw.total_out, xw.total_in, xw.total_out)
}

writer_to_stream :: proc(xw: ^Writer) -> (s: io.Stream) {
	s.data      = xw
	s.procedure = _writer_stream_proc
	return
}

writer_destroy :: proc(xw: ^Writer) {
	_writer_drop_block(xw)
	delete(xw.records)
	xw.records = nil
	sha2.reset(&xw.sha256)
	xw.in_block = false
}

@(private)
_reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Reader)(stream_data)
	#partial switch mode {
	case .Read:
		read, read_err := reader_read(r, p)
		n = i64(read)
		if read_err != nil {
			io_err, is_io := read_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Destroy:
		reader_destroy(r)
		return 0, nil
	case .Query:
		return io.query_utility({.Read, .Destroy, .Query})
	}
	return 0, .Unsupported
}

@(private)
_writer_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	xw := (^Writer)(stream_data)
	#partial switch mode {
	case .Write:
		written, write_err := writer_write(xw, p)
		n = i64(written)
		if write_err != nil {
			io_err, is_io := write_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Close:
		if finish_err := writer_finish(xw); finish_err != nil {
			io_err, is_io := finish_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Destroy:
		writer_destroy(xw)
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Close, .Destroy, .Query})
	}
	return 0, .Unsupported
}

@(private)
_writer_sink_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	xw := (^Writer)(stream_data)
	#partial switch mode {
	case .Write:
		written, write_err := io.write(xw.w, p)
		xw.total_out += i64(written)
		return i64(written), write_err
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

@(private)
_writer_put :: proc(xw: ^Writer, data: []u8) -> (err: Error) {
	written, write_err := io.write_full(xw.w, data)
	xw.total_out += i64(written)
	if write_err != nil {
		return write_err
	}
	return nil
}

@(private)
_writer_index_put :: proc(xw: ^Writer, data: []u8, crc: ^u32, size: ^i64) -> (err: Error) {
	crc^   = hash.crc32(data, crc^)
	size^ += i64(len(data))
	return _writer_put(xw, data)
}

@(private)
_writer_open_block :: proc(xw: ^Writer) -> (err: Error) {
	inner := xw.options
	inner.max_output_size   = 0
	inner.buffer            = nil
	inner.progress          = nil
	inner.progress_data     = nil
	inner.progress_interval = 0
	xw.props = lzma.writer_init_lzma2(&xw.lzma, {data = xw, procedure = _writer_sink_proc}, xw.opts.lzma2, -1, inner, xw.allocator) or_return
	xw.open        = true
	xw.chain       = {}
	xw.chain_count = xw.opts.filter_count
	for i := xw.chain_count - 1; i >= 0; i -= 1 {
		next := lzma.writer_to_stream(&xw.lzma) if i == xw.chain_count - 1 else filters.writer_to_stream(&xw.chain[i + 1])
		if err = filters.writer_init(&xw.chain[i], next, _stream_filter(xw.opts.filters[i]), .Encode, inner, xw.allocator); err != nil {
			_writer_drop_block(xw)
			return
		}
	}
	return nil
}

@(private)
_writer_begin_block :: proc(xw: ^Writer) -> (err: Error) {
	header: [BLOCK_HEADER_GAP]u8
	xw.header_size = _block_header(header[:], xw.opts, xw.props, 0, 0, false)
	_writer_put(xw, header[:xw.header_size]) or_return
	xw.block_start = xw.total_out
	xw.block_in    = 0
	xw.crc32       = 0
	xw.crc64       = 0
	if xw.check == .SHA256 {
		sha2.reset(&xw.sha256)
		sha2.init_256(&xw.sha256)
	}
	xw.in_block = true
	return nil
}

@(private)
_writer_end_block :: proc(xw: ^Writer) -> (err: Error) {
	for i in 0 ..< xw.chain_count {
		filters.writer_finish(&xw.chain[i]) or_return
	}
	lzma.writer_finish(&xw.lzma) or_return
	compressed := xw.total_out - xw.block_start
	_writer_drop_block(xw)
	xw.in_block = false
	zero: [4]u8
	if rest := (i64(xw.header_size) + compressed) % 4; rest != 0 {
		_writer_put(xw, zero[:4 - rest]) or_return
	}
	check: [sha2.DIGEST_SIZE_256]u8
	check_size := CHECK_SIZES[u8(xw.check)]
	switch xw.check {
	case .None:
	case .CRC32:
		endian.unchecked_put_u32le(check[:], xw.crc32)
	case .CRC64:
		endian.unchecked_put_u64le(check[:], xw.crc64)
	case .SHA256:
		sha2.final(&xw.sha256, check[:])
	}
	_writer_put(xw, check[:check_size]) or_return
	append(&xw.records, [2]u64{u64(xw.header_size) + u64(compressed) + u64(check_size), xw.block_in}) or_return
	return nil
}

@(private)
_writer_drop_block :: proc(xw: ^Writer) {
	if !xw.open {
		return
	}
	for i in 0 ..< xw.chain_count {
		filters.writer_destroy(&xw.chain[i])
	}
	lzma.writer_destroy(&xw.lzma)
	xw.chain_count = 0
	xw.open        = false
}

@(private)
_stream_filter :: proc "contextless" (f: Filter) -> (filter: filters.Filter) {
	if f.id == .Delta {
		return filters.Delta_Filter{distance = f.delta_distance}
	}
	return filters.Branch_Filter{arch = _branch_arch(f.id), start_offset = f.start_offset}
}

@(private)
_bounded_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Reader)(stream_data)
	#partial switch mode {
	case .Read:
		got, eof, read_err := _bounded_read(r, p)
		if read_err != nil {
			io_err, is_io := read_err.(io.Error)
			return i64(got), io_err if is_io else .Unknown
		}
		if eof {
			return 0, .EOF
		}
		return i64(got), nil
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

@(private)
_bounded_read :: proc(r: ^Reader, p: []u8) -> (n: int, eof: bool, err: Error) {
	if r.block_left == 0 || len(p) == 0 {
		return 0, r.block_left == 0, nil
	}
	if len(r.z.window) == 0 {
		refill_err := compress.refill_window(r.z, 1)
		if len(r.z.window) == 0 {
			if refill_err != nil && refill_err != .EOF && refill_err != .Short_Buffer {
				return 0, false, refill_err
			}
			r.block_eof = true
			return 0, true, nil
		}
	}
	n = copy(p[:min(u64(len(p)), r.block_left)], r.z.window)
	r.z.window    = r.z.window[n:]
	r.block_left -= u64(n)
	return n, false, nil
}

@(private)
_consumed :: proc "contextless" (r: ^Reader) -> i64 {
	if r.in_block {
		return r.consumed + r.lzma.decoder.consumed
	}
	return r.consumed
}

@(private)
_pull :: proc(r: ^Reader, buf: []u8) -> (err: Error) {
	if read_err := compress.read_slice(r.z, buf); read_err != nil {
		if read_err == .EOF || read_err == .Short_Buffer || read_err == .Unexpected_EOF {
			return General_Error.Stream_Too_Short
		}
		return read_err
	}
	r.consumed += i64(len(buf))
	return nil
}

@(private)
_stream_header :: proc(r: ^Reader) -> (err: Error) {
	header: [HEADER_SIZE]u8
	_pull(r, header[:]) or_return
	if string(header[:len(HEADER_MAGIC)]) != string(HEADER_MAGIC[:]) {
		return XZ_Error.Invalid_Magic
	}
	if hash.crc32(header[6:8]) != endian.unchecked_get_u32le(header[8:12]) {
		return XZ_Error.Header_Checksum_Failed
	}
	if header[6] != 0 || header[7] & 0xF0 != 0 {
		return XZ_Error.Reserved_Bit_Set
	}
	r.stream_flags     = {header[6], header[7]}
	r.check_id         = header[7] & 0x0F
	r.records          = 0
	r.unpadded_sum     = 0
	r.uncompressed_sum = 0
	sha2.reset(&r.index_hash)
	sha2.init_256(&r.index_hash)
	return nil
}

@(private)
_next :: proc(r: ^Reader) -> (err: Error) {
	first: [1]u8
	_pull(r, first[:]) or_return
	if first[0] != 0 {
		return _start_block(r, first[0])
	}
	index_size := _index(r) or_return
	footer: [FOOTER_SIZE]u8
	_pull(r, footer[:]) or_return
	if hash.crc32(footer[4:10]) != endian.unchecked_get_u32le(footer[0:4]) {
		return XZ_Error.Header_Checksum_Failed
	}
	if string(footer[10:12]) != string(FOOTER_MAGIC[:]) {
		return XZ_Error.Invalid_Magic
	}
	if footer[8] != r.stream_flags[0] || footer[9] != r.stream_flags[1] {
		return XZ_Error.Footer_Mismatch
	}
	backward := (u64(endian.unchecked_get_u32le(footer[4:8])) + 1) * 4
	if backward != u64(index_size) {
		return XZ_Error.Index_Mismatch
	}
	return _stream_padding(r)
}

@(private)
_stream_padding :: proc(r: ^Reader) -> (err: Error) {
	padding := 0
	for {
		if len(r.z.window) == 0 {
			refill_err := compress.refill_window(r.z, 1)
			if len(r.z.window) == 0 {
				if refill_err != nil && refill_err != .EOF && refill_err != .Short_Buffer {
					return refill_err
				}
				if padding % 4 != 0 {
					return XZ_Error.Invalid_Padding
				}
				r.done = true
				return nil
			}
		}
		if r.z.window[0] != 0 {
			break
		}
		r.z.window  = r.z.window[1:]
		r.consumed += 1
		padding    += 1
	}
	_ = compress.refill_window(r.z, len(HEADER_MAGIC))
	avail := r.z.window
	if len(avail) < len(HEADER_MAGIC) || string(avail[:len(HEADER_MAGIC)]) != string(HEADER_MAGIC[:]) {
		if len(avail) < len(HEADER_MAGIC) && string(avail) == string(HEADER_MAGIC[:len(avail)]) {
			return General_Error.Stream_Too_Short
		}
		return XZ_Error.Data_After_End
	}
	if padding % 4 != 0 {
		return XZ_Error.Invalid_Padding
	}
	return _stream_header(r)
}

@(private)
_start_block :: proc(r: ^Reader, first: u8) -> (err: Error) {
	header_size := (int(first) + 1) * 4
	buf: [BLOCK_HEADER_SIZE_MAX]u8
	buf[0] = first
	_pull(r, buf[1:header_size]) or_return
	header := buf[:header_size]
	if hash.crc32(header[:header_size - 4]) != endian.unchecked_get_u32le(header[header_size - 4:]) {
		return XZ_Error.Header_Checksum_Failed
	}
	block_flags := header[1]
	if block_flags & 0x3C != 0 {
		return XZ_Error.Reserved_Bit_Set
	}
	body := header[:header_size - 4]
	p    := 2

	r.header_size      = header_size
	r.compressed       = 0
	r.uncompressed     = 0
	r.has_compressed   = block_flags & 0x40 != 0
	r.has_uncompressed = block_flags & 0x80 != 0
	if r.has_compressed {
		value, ok := _read_vli(body, &p)
		if !ok || value == 0 {
			return XZ_Error.Invalid_Block_Header
		}
		r.compressed = value
	}
	if r.has_uncompressed {
		value, ok := _read_vli(body, &p)
		if !ok {
			return XZ_Error.Invalid_Block_Header
		}
		r.uncompressed = value
	}

	chain: [FILTERS_MAX]filters.Filter
	count     := int(block_flags & 0x03) + 1
	dict_size := u32(0)
	for i in 0..<count {
		id, id_ok := _read_vli(body, &p)
		props_size, props_ok := _read_vli(body, &p)
		if !id_ok || !props_ok || props_size > u64(len(body) - p) {
			return XZ_Error.Invalid_Block_Header
		}
		props := body[p:][:int(props_size)]
		p += int(props_size)
		last := i == count - 1
		switch id {
		case u64(Filter_ID.LZMA2):
			if !last || len(props) != 1 {
				return XZ_Error.Invalid_Filter_Chain
			}
			size, size_err := lzma.lzma2_dict_size(props[0])
			if size_err != nil {
				return XZ_Error.Invalid_Filter_Chain
			}
			dict_size = size
		case u64(Filter_ID.Delta):
			if last || len(props) != 1 {
				return XZ_Error.Invalid_Filter_Chain
			}
			chain[i] = filters.Delta_Filter{distance = int(props[0]) + 1}
		case u64(Filter_ID.X86) ..= u64(Filter_ID.RISCV):
			if last || (len(props) != 0 && len(props) != 4) {
				return XZ_Error.Invalid_Filter_Chain
			}
			start := u32(0)
			if len(props) == 4 {
				start = endian.unchecked_get_u32le(props)
			}
			branch: filters.Branch_State
			if !filters.branch_init(&branch, _branch_arch(Filter_ID(id)), start) {
				return XZ_Error.Invalid_Filter_Chain
			}
			chain[i] = filters.Branch_Filter{arch = _branch_arch(Filter_ID(id)), start_offset = start}
		case:
			return XZ_Error.Unsupported_Filter
		}
	}
	for b in body[p:] {
		if b != 0 {
			return XZ_Error.Reserved_Bit_Set
		}
	}

	expected := -1
	if r.has_uncompressed {
		if r.size >= 0 && r.uncompressed > u64(max(i64(r.size) - r.produced, 0)) {
			return General_Error.Size_Mismatch
		}
		if limit := r.options.max_output_size; limit > 0 && r.uncompressed > u64(max(i64(limit) - r.produced, 0)) {
			return General_Error.Output_Too_Short
		}
		if r.uncompressed <= u64(max(int)) {
			expected = int(r.uncompressed)
		}
	}
	inner := r.options
	inner.max_output_size   = 0
	inner.buffer            = nil
	inner.progress          = nil
	inner.progress_data     = nil
	inner.progress_interval = 0
	r.in_block  = true
	r.block_out = 0
	r.crc32     = 0
	r.crc64     = 0
	if Check(r.check_id) == .SHA256 {
		sha2.reset(&r.sha256)
		sha2.init_256(&r.sha256)
	}
	source_z := r.z
	if r.has_compressed {
		r.bounded    = true
		r.block_left = r.compressed
		r.block_eof  = false
		if compress.is_memory_context(r.z) && r.compressed <= u64(len(r.z.window)) {
			r.block_view = true
			r.block_data = r.z.window[:int(r.compressed)]
			r.block_z    = compress.init_context_from_slice(&r.block_data)
		} else {
			if r.block_backing == nil {
				r.block_backing = make([]u8, compress.CONTEXT_WINDOW_SIZE, r.allocator) or_return
			}
			r.block_z = compress.init_context_from_stream({data = r, procedure = _bounded_stream_proc}, nil, r.block_backing, r.allocator)
		}
		source_z = &r.block_z
	}
	lzma.reader_init_lzma2(&r.lzma, source_z, dict_size, expected, inner, r.allocator) or_return
	r.chain_count = count - 1
	for i := count - 2; i >= 0; i -= 1 {
		source := lzma.reader_to_stream(&r.lzma) if i == count - 2 else filters.reader_to_stream(&r.chain[i + 1])
		filters.reader_init(&r.chain[i], source, chain[i], .Decode, inner, r.allocator) or_return
	}
	return nil
}

@(private)
_block_output :: proc(r: ^Reader, data: []u8) {
	r.block_out += u64(len(data))
	r.produced  += i64(len(data))
	if .Ignore_Check in r.flags {
		return
	}
	switch Check(r.check_id) {
	case .None:
	case .CRC32:
		r.crc32 = hash.crc32(data, r.crc32)
	case .CRC64:
		r.crc64 = hash.crc64_xz(data, r.crc64)
	case .SHA256:
		sha2.update(&r.sha256, data)
	}
}

@(private)
_block_error :: proc(r: ^Reader, err: Error) -> Error {
	cause := err
	if r.lzma.err != nil {
		cause = r.lzma.err
	}
	if r.has_uncompressed && cause == General_Error.Output_Too_Short {
		return General_Error.Size_Mismatch
	}
	if r.bounded && cause == General_Error.Stream_Too_Short && !r.block_eof {
		return General_Error.Size_Mismatch
	}
	return cause
}

@(private)
_end_block :: proc(r: ^Reader) {
	if !r.in_block {
		return
	}
	for i in 0..<r.chain_count {
		filters.reader_destroy(&r.chain[i])
	}
	lzma.reader_destroy(&r.lzma)
	if r.bounded {
		compress.destroy_context(&r.block_z)
		r.block_data = nil
		r.block_view = false
		r.bounded    = false
	}
	r.chain_count = 0
	r.in_block    = false
}

@(private)
_finish_block :: proc(r: ^Reader) -> (err: Error) {
	compressed := u64(r.lzma.decoder.consumed)
	if r.block_view {
		r.z.window = r.z.window[compressed:]
		r.block_left = r.compressed - compressed
	}
	_end_block(r)
	r.consumed += i64(compressed)
	if r.has_compressed && compressed != r.compressed {
		for r.block_left > 0 {
			skip: [512]u8
			_, eof := _bounded_read(r, skip[:]) or_return
			if eof {
				return General_Error.Stream_Too_Short
			}
		}
		return General_Error.Size_Mismatch
	}
	if r.has_uncompressed && r.block_out != r.uncompressed {
		return General_Error.Size_Mismatch
	}
	for pos := u64(r.header_size) + compressed; pos % 4 != 0; pos += 1 {
		pad: [1]u8
		_pull(r, pad[:]) or_return
		if pad[0] != 0 {
			return XZ_Error.Invalid_Padding
		}
	}
	check_size := CHECK_SIZES[r.check_id]
	check: [64]u8
	_pull(r, check[:check_size]) or_return
	if .Ignore_Check not_in r.flags {
		switch Check(r.check_id) {
		case .None:
		case .CRC32:
			if r.crc32 != endian.unchecked_get_u32le(check[:4]) {
				return XZ_Error.Block_Checksum_Failed
			}
		case .CRC64:
			if r.crc64 != endian.unchecked_get_u64le(check[:8]) {
				return XZ_Error.Block_Checksum_Failed
			}
		case .SHA256:
			digest: [sha2.DIGEST_SIZE_256]u8
			sha2.final(&r.sha256, digest[:])
			if string(digest[:]) != string(check[:sha2.DIGEST_SIZE_256]) {
				return XZ_Error.Block_Checksum_Failed
			}
		}
	}
	unpadded := u64(r.header_size) + compressed + u64(check_size)
	if unpadded > VLI_MAX - r.unpadded_sum || r.block_out > VLI_MAX - r.uncompressed_sum {
		return XZ_Error.Input_Too_Large
	}
	r.records          += 1
	r.unpadded_sum     += unpadded
	r.uncompressed_sum += r.block_out
	_hash_record(&r.index_hash, unpadded, r.block_out)
	return nil
}

@(private)
_index_byte :: proc(r: ^Reader, crc: ^u32, size: ^u64) -> (b: u8, err: Error) {
	if size^ >= INDEX_SIZE_MAX {
		return 0, XZ_Error.Invalid_Index
	}
	buf: [1]u8
	_pull(r, buf[:]) or_return
	crc^   = hash.crc32(buf[:], crc^)
	size^ += 1
	return buf[0], nil
}

@(private)
_index_vli :: proc(r: ^Reader, crc: ^u32, size: ^u64) -> (value: u64, err: Error) {
	for i in 0..<VLI_BYTES_MAX {
		b := _index_byte(r, crc, size) or_return
		value |= u64(b & 0x7F) << uint(7 * i)
		if b & 0x80 == 0 {
			if i > 0 && b == 0 {
				return 0, XZ_Error.Invalid_Index
			}
			return value, nil
		}
	}
	return 0, XZ_Error.Invalid_Index
}

@(private)
_index :: proc(r: ^Reader) -> (size: u64, err: Error) {
	zero := [1]u8{0}
	crc  := hash.crc32(zero[:])
	size  = 1
	count := _index_vli(r, &crc, &size) or_return
	if count != r.records {
		return 0, XZ_Error.Index_Mismatch
	}
	verify: sha2.Context_256
	sha2.init_256(&verify)
	defer sha2.reset(&verify)
	unpadded_sum, uncompressed_sum: u64
	for _ in 0..<count {
		unpadded     := _index_vli(r, &crc, &size) or_return
		uncompressed := _index_vli(r, &crc, &size) or_return
		if unpadded < UNPADDED_SIZE_MIN || unpadded > VLI_MAX - unpadded_sum || uncompressed > VLI_MAX - uncompressed_sum {
			return 0, XZ_Error.Invalid_Index
		}
		unpadded_sum     += unpadded
		uncompressed_sum += uncompressed
		_hash_record(&verify, unpadded, uncompressed)
	}
	for size % 4 != 0 {
		pad := _index_byte(r, &crc, &size) or_return
		if pad != 0 {
			return 0, XZ_Error.Invalid_Index
		}
	}
	stored: [4]u8
	_pull(r, stored[:]) or_return
	size += 4
	if crc != endian.unchecked_get_u32le(stored[:]) {
		return 0, XZ_Error.Header_Checksum_Failed
	}
	if unpadded_sum != r.unpadded_sum || uncompressed_sum != r.uncompressed_sum {
		return 0, XZ_Error.Index_Mismatch
	}
	want, got: [sha2.DIGEST_SIZE_256]u8
	sha2.final(&r.index_hash, want[:])
	sha2.final(&verify, got[:])
	if want != got {
		return 0, XZ_Error.Index_Mismatch
	}
	return size, nil
}
