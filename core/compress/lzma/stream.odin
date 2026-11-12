package compress_lzma

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
	if n > 0 && r.err == nil {
		if r.err = stream_progress(r); r.err != nil {
			r.flushed = r.out.written
		}
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

@(private)
stream_init :: proc(r: ^Reader, z: ^compress.Context, kind: Stream_Kind, props: Properties, expected_output_size: int, options: compress.Options, allocator: runtime.Allocator) -> (err: Error) {
	context.allocator = allocator
	r^ = {}
	r.z         = z
	r.kind      = kind
	r.options   = options
	r.allocator = allocator
	r.total_in  = -1
	if options.max_output_size < 0 || options.max_memory < 0 || options.chunk_size < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	if options.progress != nil {
		r.total_in = i64(compress.input_size(z))
	}

	size := expected_output_size
	if size < 0 && z.size_unpacked >= 0 && z.size_unpacked <= i64(max(int)) {
		size = int(z.size_unpacked)
	}
	props := props
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
			if declared > u64(max(int)) {
				return General_Error.Output_Too_Short
			}
			if size >= 0 && size != int(declared) {
				return LZMA_Error.Size_Mismatch
			}
			size          = int(declared)
			r.from_format = true
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
	switch r.kind {
	case .LZMA2:
		lzma2_fill(&r.decoder, r.z, o, &r.lzma2, r.size) or_return
		r.done = r.lzma2.done
		if !r.done && o.written < o.limit {
			return General_Error.Output_Too_Short
		}
	case .Alone, .Raw:
		target := r.size if r.size >= 0 else o.end
		packed := -1
		eos    := decode_segment(&r.decoder, r.z, o, target, &packed) or_return
		if !eos && o.base + o.written < target && o.written >= o.limit {
			return nil
		}
		r.done = true
		return lzma_finish(&r.decoder, r.z, o, r.size, eos, r.from_format)
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
		if produced {
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
