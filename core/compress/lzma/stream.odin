package compress_lzma

import "base:intrinsics"
import "base:runtime"
import "core:compress"
import "core:io"

decompress_to_writer :: proc(w: io.Writer, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	stream_init(&r, z, .Alone, {}, expected_output_size, options, allocator) or_return
	return stream_to_writer(&r, w)
}

decompress_raw_to_writer :: proc(w: io.Writer, z: ^compress.Context, props: Properties, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	stream_init(&r, z, .Raw, props, expected_output_size, options, allocator) or_return
	return stream_to_writer(&r, w)
}

decompress_lzma2_to_writer :: proc(w: io.Writer, z: ^compress.Context, dict_size: u32, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	stream_init(&r, z, .LZMA2, {dict_size = dict_size}, expected_output_size, options, allocator) or_return
	return stream_to_writer(&r, w)
}

reader_init :: proc(r: ^Reader, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = stream_init(r, z, .Alone, {}, expected_output_size, options, allocator)
	r.err = err
	return
}

reader_init_raw :: proc(r: ^Reader, z: ^compress.Context, props: Properties, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = stream_init(r, z, .Raw, props, expected_output_size, options, allocator)
	r.err = err
	return
}

reader_init_lzma2 :: proc(r: ^Reader, z: ^compress.Context, dict_size: u32, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = stream_init(r, z, .LZMA2, {dict_size = dict_size}, expected_output_size, options, allocator)
	r.err = err
	return
}

reader_read :: proc(r: ^Reader, p: []u8) -> (n: int, err: Error) {
	was_done := r.done
	for n < len(p) {
		if r.flushed < r.out.written {
			copied   := copy(p[n:], r.window[r.flushed:r.out.written])
			r.flushed += copied
			n         += copied
		} else if r.done || r.err != nil {
			break
		} else {
			r.err = stream_fill(r)
		}
	}
	if (n > 0 || (r.done && !was_done)) && r.err == nil {
		if r.err = stream_progress(r); r.err != nil {
			r.flushed = r.out.written
		}
	}
	if n > 0 || r.flushed < r.out.written {
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
	s.procedure = reader_stream_proc
	return
}

reader_destroy :: proc(r: ^Reader) {
	delete(r.decoder.probs, r.allocator)
	if r.owns_window {
		delete(r.window)
	}
	r.decoder.probs = nil
	r.window        = {}
	r.out           = {}
	r.flushed       = 0
	r.owns_window   = false
}

writer_init :: proc(lw: ^Writer, w: io.Writer, level := Level.Default, input_size: i64 = -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	_, err = writer_create(lw, w, .Alone, level_options(level), input_size, options, allocator)
	return
}

writer_init_raw :: proc(lw: ^Writer, w: io.Writer, lzma_options: Options, input_size: i64 = -1, options: compress.Options = {}, allocator := context.allocator) -> (props: Properties, err: Error) {
	return writer_create(lw, w, .Raw, lzma_options, input_size, options, allocator)
}

writer_init_lzma2 :: proc(lw: ^Writer, w: io.Writer, lzma_options: Options, input_size: i64 = -1, options: compress.Options = {}, allocator := context.allocator) -> (props: Properties, err: Error) {
	return writer_create(lw, w, .LZMA2, lzma_options, input_size, options, allocator)
}

writer_write :: proc(lw: ^Writer, p: []u8) -> (n: int, err: Error) {
	if lw.err != nil {
		return 0, lw.err
	}
	if lw.finished {
		return 0, io.Error.Closed
	}
	defer lw.err = err
	if lw.input_size >= 0 && i64(len(p)) > lw.input_size - lw.total_in {
		return 0, General_Error.Size_Mismatch
	}
	mf := &lw.state.encoder.mf
	for n < len(p) {
		if mf_room(mf) == 0 {
			mf_move_block(mf)
		}
		k := min(mf_room(mf), len(p) - n)
		intrinsics.mem_copy_non_overlapping(&mf.buffer[mf_avail(mf)], &p[n], k)
		mf.stream_pos += u32(k)
		lw.total_in   += i64(k)
		n             += k
		for mf_avail(mf) >= lw.threshold {
			writer_step(lw) or_return
		}
	}
	return
}

writer_finish :: proc(lw: ^Writer) -> (err: Error) {
	if lw.err != nil {
		return lw.err
	}
	if lw.finished {
		return nil
	}
	defer lw.err = err
	if lw.input_size >= 0 && lw.total_in != lw.input_size {
		return General_Error.Size_Mismatch
	}
	e := &lw.state.encoder
	if lw.kind == .LZMA2 {
		for lw.chunker.src_pos < lw.total_in {
			writer_step(lw) or_return
		}
		end := [1]u8{0}
		if _, write_err := io.write_full(lw.w, end[:]); write_err != nil {
			return write_err
		}
		lw.flushed += 1
	} else {
		for !e.finished {
			writer_step(lw) or_return
		}
	}
	lw.finished = true
	return compress.report_progress(lw.options, lw.total_in, lw.flushed, lw.total_in, lw.flushed)
}

writer_to_stream :: proc(lw: ^Writer) -> (s: io.Stream) {
	s.data      = lw
	s.procedure = writer_stream_proc
	return
}

writer_destroy :: proc(lw: ^Writer) {
	context.allocator = lw.allocator
	if lw.state != nil {
		encoder_destroy(&lw.state.encoder)
		delete(lw.state.out)
		free(lw.state)
	}
	if lw.owns_block {
		delete(lw.block)
	}
	lw.state      = nil
	lw.block      = nil
	lw.owns_block = false
}

@(private)
stream_init :: proc(r: ^Reader, z: ^compress.Context, kind: Stream_Kind, props: Properties, expected_output_size: int, options: compress.Options, allocator: runtime.Allocator) -> (err: Error) {
	context.allocator = allocator
	r^ = {}
	r.z         = z
	r.kind      = kind
	r.options   = options
	r.allocator = allocator
	r.total_in  = -1
	check_options(options) or_return
	if options.progress != nil {
		r.total_in = i64(compress.input_size(z))
	}

	size  := compress.declared_size(expected_output_size)
	props := props
	if options.max_output_size > 0 && size > options.max_output_size {
		return General_Error.Output_Too_Short
	}
	switch kind {
	case .Alone:
		header: [HEADER_SIZE]u8
		if compress.read_slice(z, header[:]) != nil {
			return General_Error.Stream_Too_Short
		}
		r.decoder.consumed = HEADER_SIZE
		props = decode_properties(header[:PROPERTIES_SIZE]) or_return
		declared := u64(0)
		for i in 0..<8 {
			declared |= u64(header[PROPERTIES_SIZE + i]) << (8 * uint(i))
		}
		if declared != UNKNOWN_SIZE {
			if size >= 0 && u64(size) != declared {
				return General_Error.Size_Mismatch
			}
			if declared > u64(max(int)) {
				return General_Error.Output_Too_Short
			}
			size = int(declared)
		}
	case .Raw:
		if !valid_properties(props) {
			return LZMA_Error.Invalid_Properties
		}
	case .LZMA2:
	}
	if options.max_output_size > 0 && size > options.max_output_size {
		return General_Error.Output_Too_Short
	}
	r.size = size

	dict := int(min(u64(max(props.dict_size, DICT_SIZE_MIN)), u64(max(int) / 2)))
	keep, capacity := dict, 0
	if size >= 0 && size <= dict {
		keep, capacity = size, size
	} else {
		step := options.chunk_size if options.chunk_size > 0 else CHUNK_SIZE
		step  = min(max(step, dict / 4), max(int) - dict)
		capacity = dict + step
	}
	if options.buffer != nil {
		if len(options.buffer) < capacity && (capacity == keep || len(options.buffer) <= keep) {
			return General_Error.Memory_Limit_Exceeded
		}
		capacity = min(capacity, len(options.buffer))
		raw := runtime.Raw_Dynamic_Array{data = raw_data(options.buffer), len = 0, cap = len(options.buffer), allocator = runtime.nil_allocator()}
		r.window = transmute([dynamic]u8)raw
	} else {
		if capacity > compress.memory_limit(options) {
			return General_Error.Memory_Limit_Exceeded
		}
		r.window.allocator = allocator
		r.owns_window      = true
	}
	r.keep = keep

	end := max(int)
	switch {
	case size >= 0:                  end = size
	case options.max_output_size > 0: end = options.max_output_size
	}
	r.out = Output{buf = &r.window, limit = capacity, end = end}

	input_size := compress.input_size(z)
	bound      := -1
	if input_size >= 0 && input_size < max(int) / compress.LZMA_EXPANSION_MAX {
		bound = input_size * compress.LZMA_EXPANSION_MAX
	}
	reservation := min(compress.output_reservation(size, bound, input_size), capacity)
	if non_zero_resize(&r.window, reservation) != nil {
		non_zero_resize(&r.window, 0)
	}

	switch kind {
	case .Alone, .Raw:
		rc_init(&r.decoder, z) or_return
		decoder_init(&r.decoder, props, int(props.lc) + int(props.lp)) or_return
		decoder_reset_state(&r.decoder)
	case .LZMA2:
		decoder_init(&r.decoder, Properties{lc = LZMA2_LCLP_MAX, dict_size = props.dict_size}) or_return
		r.lzma2.need_init = LZMA2_CONTROL_RESET_DICT
	}
	return nil
}

@(private)
stream_fill :: proc(r: ^Reader) -> (err: Error) {
	o := &r.out
	if o.written >= o.limit && r.flushed == o.written && o.written > r.keep {
		shift := o.written - r.keep
		copy(r.window[:r.keep], r.window[shift:o.written])
		o.written  = r.keep
		r.flushed  = r.keep
		o.base    += shift
	}
	out_pos  := o.base + o.written
	consumed := r.decoder.consumed
	switch r.kind {
	case .LZMA2:
		lzma2_fill(&r.decoder, r.z, o, &r.lzma2, r.size) or_return
		r.done = r.lzma2.done
		if !r.done && (o.written < o.limit || (o.base + o.written == out_pos && r.decoder.consumed == consumed)) {
			return General_Error.Size_Mismatch if r.size >= 0 else General_Error.Output_Too_Short
		}
	case .Alone, .Raw:
		target := r.size if r.size >= 0 else o.end
		packed := -1
		eos    := decode_segment(&r.decoder, r.z, o, target, &packed) or_return
		if !eos && o.base + o.written < target && o.written >= o.limit {
			if o.base + o.written == out_pos && r.decoder.consumed == consumed {
				return General_Error.Size_Mismatch if r.size >= 0 else General_Error.Output_Too_Short
			}
			return nil
		}
		r.done = true
		return lzma_finish(&r.decoder, r.z, o, r.size, eos)
	}
	return nil
}

@(private)
stream_to_writer :: proc(r: ^Reader, w: io.Writer) -> (err: Error) {
	for !r.done {
		fill_err := stream_fill(r)
		produced := r.out.written > r.flushed
		if produced {
			if _, write_err := io.write_full(w, r.window[r.flushed:r.out.written]); write_err != nil {
				return write_err
			}
			r.flushed = r.out.written
		}
		if fill_err != nil {
			return fill_err
		}
		if produced || r.done {
			stream_progress(r) or_return
		}
	}
	return nil
}

@(private)
stream_progress :: proc(r: ^Reader) -> (err: Error) {
	return compress.report_progress(r.options, r.decoder.consumed, i64(r.out.base + r.flushed), r.total_in, i64(r.size))
}

@(private)
writer_create :: proc(lw: ^Writer, w: io.Writer, kind: Stream_Kind, lzma_options: Options, input_size: i64, options: compress.Options, allocator: runtime.Allocator) -> (props: Properties, err: Error) {
	context.allocator = allocator
	lw^ = {}
	lw.w          = w
	lw.kind       = kind
	lw.input_size = max(input_size, -1)
	lw.options    = options
	lw.allocator  = allocator
	defer lw.err = err
	defer if err != nil {
		writer_destroy(lw)
	}

	check_options(options) or_return
	lzma2    := kind == .LZMA2
	size     := -1
	expected := UNKNOWN_SIZE
	if input_size >= 0 {
		size     = int(min(input_size, i64(max(int))))
		expected = u64(input_size)
	}
	opts := normalize_options(lzma_options, size, lzma2) or_return
	if kind == .Alone && input_size < 0 {
		opts.end_marker = true
	}
	threshold := u64(LZMA2_UNPACK_CHUNK_MAX if lzma2 else CODE_BLOCK_UNPACK) + WRITER_LOOKAHEAD
	out_size  := compress_lzma2_bound(int(threshold)) + HEADER_SIZE
	limit     := u64(compress.memory_limit(options))
	keep_before, block_size: u64
	for {
		keep_before = u64(encoder_history(opts.dict_size)) + NUM_OPTS + 1
		need       := keep_before + threshold + BLOCK_MOVE_ALIGN
		block_size  = min((need + (need >> (1 if need < 1 << 30 else 2)) + BLOCK_SIZE_ALIGN - 1) &~ u64(BLOCK_SIZE_ALIGN - 1), BLOCK_SIZE_MAX)
		memory     := u64(size_of(Writer_State)) + encoder_memory(opts, expected, lzma2) + u64(out_size)
		short      := false
		if options.buffer != nil {
			short = u64(len(options.buffer)) < need
		} else {
			memory += block_size
		}
		if need <= BLOCK_SIZE_MAX && !short && memory <= limit {
			break
		}
		if opts.dict_size <= DICT_SIZE_MIN {
			if short {
				return {}, General_Error.Incompatible_Options
			}
			return {}, General_Error.Memory_Limit_Exceeded
		}
		opts.dict_size, _ = lzma2_dict_size(lzma2_dict_prop(opts.dict_size) - 1)
	}
	props = options_properties(opts)
	if options.buffer != nil {
		lw.block = options.buffer[:min(u64(len(options.buffer)), BLOCK_SIZE_MAX)]
	}
	if lw.block == nil {
		lw.block      = non_zero_make([]u8, int(block_size)) or_return
		lw.owns_block = true
	}
	state := new(Writer_State) or_return
	lw.state = state
	state.out.allocator = allocator
	non_zero_resize(&state.out, out_size) or_return

	e := &state.encoder
	e.rc = Range_Encoder{buf = raw_data(state.out), cap = len(state.out), grow = &state.out, limit = max(int)}
	if kind == .Alone {
		write_header(state.out[:], props, expected)
		e.rc.pos = HEADER_SIZE
	}
	encoder_create(e, opts, expected, lzma2) or_return

	mf := &e.mf
	mf.streaming   = true
	mf.buf_base    = raw_data(lw.block)
	mf.block_size  = len(lw.block)
	mf.keep_before = u32(keep_before)
	mf.buffer      = mf.buf_base
	mf.pos         = 1
	mf.stream_pos  = 1
	lw.threshold   = u32(threshold)
	if lzma2 {
		lw.chunker = lzma2_chunker_init(opts)
	}
	return props, nil
}

@(private)
writer_step :: proc(lw: ^Writer) -> (err: Error) {
	e := &lw.state.encoder
	now_pos := e.now_pos64
	if lw.kind == .LZMA2 {
		_, chunk_err := lzma2_chunk(e, &lw.chunker)
		if chunk_err != nil {
			return chunk_err
		}
	} else {
		code_one_block(e, 0, 0)
		if e.rc.grow_err != nil {
			return e.rc.grow_err
		}
	}
	if e.now_pos64 == now_pos && mf_avail(&e.mf) > 0 {
		return General_Error.Output_Too_Short
	}
	rc := &e.rc
	if rc.pos > 0 {
		if _, write_err := io.write_full(lw.w, rc.buf[:rc.pos]); write_err != nil {
			return write_err
		}
		lw.flushed += i64(rc.pos)
		rc.pos      = 0
		rc.start    = 0
	}
	return compress.report_progress(lw.options, i64(e.now_pos64), lw.flushed, lw.input_size, -1)
}

@(private)
writer_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	lw := (^Writer)(stream_data)
	#partial switch mode {
	case .Write:
		written, write_err := writer_write(lw, p)
		n = i64(written)
		if write_err != nil {
			io_err, is_io := write_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Close:
		if finish_err := writer_finish(lw); finish_err != nil {
			io_err, is_io := finish_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Destroy:
		writer_destroy(lw)
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Close, .Destroy, .Query})
	}
	return 0, .Unsupported
}

@(private)
reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
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
