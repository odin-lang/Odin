package compress_filters

import "core:compress"
import "core:io"

reader_init :: proc(r: ^Reader, source: io.Reader, filter: Filter, direction := Direction.Decode, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r^ = {}
	r.source    = source
	r.allocator = allocator
	defer r.err = err
	r.converter = _converter_init(filter, direction) or_return
	r.buffer, r.owns_buffer = _stream_buffer(options, FILTER_BUFFER_MIN, max(_chunk_size(options), FILTER_BUFFER_MIN), allocator) or_return
	return nil
}

reader_read :: proc(r: ^Reader, p: []u8) -> (n: int, err: Error) {
	for n < len(p) {
		if r.start < r.ready {
			copied  := copy(p[n:], r.buffer[r.start:r.ready])
			r.start += copied
			n       += copied
			continue
		}
		if r.err != nil || (r.eof && r.ready == r.end) {
			break
		}
		r.err = _reader_fill(r)
	}
	if n > 0 {
		return n, nil
	}
	if r.err != nil {
		return 0, r.err
	}
	if len(p) > 0 && r.eof && r.ready == r.end {
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
	if r.owns_buffer {
		delete(r.buffer, r.allocator)
	}
	r.buffer      = nil
	r.owns_buffer = false
	r.start       = 0
	r.ready       = 0
	r.end         = 0
}

writer_init :: proc(fw: ^Writer, w: io.Writer, filter: Filter, direction := Direction.Encode, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	fw^ = {}
	fw.w         = w
	fw.allocator = allocator
	defer fw.err = err
	fw.converter = _converter_init(filter, direction) or_return
	fw.buffer, fw.owns_buffer = _stream_buffer(options, FILTER_BUFFER_MIN, max(_chunk_size(options), FILTER_BUFFER_MIN), allocator) or_return
	return nil
}

writer_write :: proc(fw: ^Writer, p: []u8) -> (n: int, err: Error) {
	if fw.err != nil {
		return 0, fw.err
	}
	if fw.finished {
		return 0, io.Error.Closed
	}
	defer if err != nil {
		fw.err = err
	}
	for n < len(p) {
		copied := copy(fw.buffer[fw.pending:], p[n:])
		fw.pending += copied
		n          += copied
		if fw.pending < len(fw.buffer) {
			break
		}
		done := _convert(&fw.converter, fw.buffer)
		if _, write_err := io.write_full(fw.w, fw.buffer[:done]); write_err != nil {
			return n, write_err
		}
		fw.pending = copy(fw.buffer, fw.buffer[done:])
	}
	return
}

writer_finish :: proc(fw: ^Writer) -> (err: Error) {
	if fw.err != nil {
		return fw.err
	}
	if fw.finished {
		return nil
	}
	defer if err != nil {
		fw.err = err
	}
	_convert(&fw.converter, fw.buffer[:fw.pending])
	if _, write_err := io.write_full(fw.w, fw.buffer[:fw.pending]); write_err != nil {
		return write_err
	}
	fw.pending  = 0
	fw.finished = true
	return nil
}

writer_to_stream :: proc(fw: ^Writer) -> (s: io.Stream) {
	s.data      = fw
	s.procedure = _writer_stream_proc
	return
}

writer_destroy :: proc(fw: ^Writer) {
	if fw.owns_buffer {
		delete(fw.buffer, fw.allocator)
	}
	fw.buffer      = nil
	fw.owns_buffer = false
	fw.pending     = 0
}

@(private)
_converter_init :: proc "contextless" (filter: Filter, direction: Direction) -> (c: Converter, err: Error) {
	if direction != .Decode && direction != .Encode {
		return {}, General_Error.Incompatible_Options
	}
	c.direction = direction
	switch f in filter {
	case Branch_Filter:
		if f.arch > .RISCV || !branch_init(&c.branch, f.arch, f.start_offset) {
			return {}, General_Error.Incompatible_Options
		}
		c.kind = .Branch
	case Delta_Filter:
		if !delta_init(&c.delta, f.distance) {
			return {}, General_Error.Incompatible_Options
		}
		c.kind = .Delta
	case Swap_Filter:
		switch f {
		case .Swap2: c.kind = .Swap2
		case .Swap4: c.kind = .Swap4
		case:        return {}, General_Error.Incompatible_Options
		}
	case:
		return {}, General_Error.Incompatible_Options
	}
	return
}

@(private)
_convert :: proc "contextless" (c: ^Converter, data: []u8) -> (processed: int) {
	switch c.kind {
	case .Branch:
		if c.direction == .Encode {
			return branch_encode(&c.branch, data)
		}
		return branch_decode(&c.branch, data)
	case .Delta:
		if c.direction == .Encode {
			delta_encode(&c.delta, data)
		} else {
			delta_decode(&c.delta, data)
		}
		return len(data)
	case .Swap2:
		return swap2(data)
	case .Swap4:
		return swap4(data)
	case .None:
	}
	return 0
}

@(private)
_reader_fill :: proc(r: ^Reader) -> (err: Error) {
	if r.ready > 0 {
		r.end   = copy(r.buffer, r.buffer[r.ready:r.end])
		r.start = 0
		r.ready = 0
	}
	stalls := 0
	for !r.eof && r.end < len(r.buffer) {
		got, read_err := io.read(r.source, r.buffer[r.end:])
		r.end += got
		if read_err == .EOF {
			r.eof = true
			break
		}
		if read_err != nil {
			return read_err
		}
		if got > 0 {
			stalls = 0
			continue
		}
		stalls += 1
		if stalls > READ_STALLS_MAX {
			return io.Error.No_Progress
		}
	}
	r.ready = _convert(&r.converter, r.buffer[:r.end])
	if r.eof {
		r.ready = r.end
	}
	return nil
}

@(private)
_reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Reader)(stream_data)
	#partial switch mode {
	case .Read:
		read, read_err := reader_read(r, p)
		return i64(read), _io_error(read_err)
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
	fw := (^Writer)(stream_data)
	#partial switch mode {
	case .Write:
		written, write_err := writer_write(fw, p)
		return i64(written), _io_error(write_err)
	case .Close:
		return 0, _io_error(writer_finish(fw))
	case .Destroy:
		writer_destroy(fw)
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Close, .Destroy, .Query})
	}
	return 0, .Unsupported
}
