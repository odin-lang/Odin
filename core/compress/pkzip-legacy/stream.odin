package compress_pkzip_legacy

import "base:runtime"
import "core:compress"
import "core:io"

unshrink_to_writer :: proc(w: io.Writer, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	_reader_begin(&r, z, .Shrink, 0, {}, expected_output_size, options, allocator) or_return
	return _reader_drain(&r, w)
}

expand_to_writer :: proc(w: io.Writer, z: ^compress.Context, factor: int, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	_reader_begin(&r, z, .Reduce, factor, {}, expected_output_size, options, allocator) or_return
	return _reader_drain(&r, w)
}

explode_to_writer :: proc(w: io.Writer, z: ^compress.Context, implode_options: Implode_Options, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	_reader_begin(&r, z, .Implode, 0, implode_options, expected_output_size, options, allocator) or_return
	return _reader_drain(&r, w)
}

reader_init_unshrink :: proc(r: ^Reader, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = _reader_begin(r, z, .Shrink, 0, {}, expected_output_size, options, allocator)
	r.err = err
	return
}

reader_init_expand :: proc(r: ^Reader, z: ^compress.Context, factor: int, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = _reader_begin(r, z, .Reduce, factor, {}, expected_output_size, options, allocator)
	r.err = err
	return
}

reader_init_explode :: proc(r: ^Reader, z: ^compress.Context, implode_options: Implode_Options, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = _reader_begin(r, z, .Implode, 0, implode_options, expected_output_size, options, allocator)
	r.err = err
	return
}

reader_read :: proc(r: ^Reader, p: []u8) -> (n: int, err: Error) {
	was_done := r.done
	for n < len(p) {
		if r.start < r.ready {
			copied  := copy(p[n:], r.window[r.start:r.ready])
			r.start += copied
			n       += copied
		} else if r.done || r.err != nil {
			break
		} else {
			r.err = _reader_fill(r)
		}
	}
	if (n > 0 || (r.done && !was_done)) && r.err == nil {
		if r.err = _reader_progress(r); r.err != nil {
			r.start = r.ready
		}
	}
	if n > 0 || r.start < r.ready {
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
	if r.shrink != nil {
		free(r.shrink, r.allocator)
	}
	if r.expand != nil {
		free(r.expand, r.allocator)
	}
	if r.trees != nil {
		free(r.trees, r.allocator)
	}
	if r.owns_window {
		delete(r.window, r.allocator)
	}
	if r.streamed {
		compress.destroy_context(&r.source)
	}
	r.shrink      = nil
	r.expand      = nil
	r.trees       = nil
	r.window      = nil
	r.start       = 0
	r.ready       = 0
	r.owns_window = false
	r.streamed    = false
}

@(private)
_reader_begin :: proc(r: ^Reader, z: ^compress.Context, method: Reader_Method, factor: int, implode_options: Implode_Options, expected_output_size: int, options: compress.Options, allocator: runtime.Allocator) -> (err: Error) {
	context.allocator = allocator
	r^ = {}
	r.z         = z
	r.src       = z
	r.method    = method
	r.options   = options
	r.allocator = allocator
	r.total_in  = -1
	r.base      = i64(len(z.window)) + i64(z.num_bits / 8)
	check_options(options) or_return
	if method == .Reduce && (factor < 1 || factor > 4) {
		return General_Error.Incompatible_Options
	}
	size := compress.declared_size(expected_output_size)
	if size < 0 {
		return General_Error.Incompatible_Options
	}
	if options.max_output_size > 0 && size > options.max_output_size {
		return General_Error.Output_Too_Short
	}
	r.size = i64(size)
	if options.progress != nil {
		r.total_in = i64(compress.input_size(z))
	}
	if size == 0 {
		r.done = true
		return nil
	}

	state_size := 0
	switch method {
	case .Shrink:  state_size = size_of(Unshrink)
	case .Reduce:  state_size = size_of(Expand)
	case .Implode: state_size = size_of([3]Implode_Tree)
	}
	step := options.chunk_size if options.chunk_size > 0 else READER_WINDOW_SIZE - READER_HISTORY
	step  = min(max(step, READER_STEP_MAX), max(int) - READER_HISTORY)
	capacity := min(READER_HISTORY + step, size)
	memory   := state_size
	streamed := !compress.is_memory_context(z)
	if streamed {
		memory += compress.CONTEXT_WINDOW_SIZE
	}
	if options.buffer != nil {
		if len(options.buffer) < capacity && len(options.buffer) < READER_HISTORY + READER_STEP_MAX {
			return General_Error.Memory_Limit_Exceeded
		}
		capacity = min(capacity, len(options.buffer))
	} else {
		memory += capacity
	}
	if memory > compress.memory_limit(options) {
		return General_Error.Memory_Limit_Exceeded
	}

	switch method {
	case .Shrink:
		raw := runtime.mem_alloc_non_zeroed(size_of(Unshrink), align_of(Unshrink)) or_return
		r.shrink    = (^Unshrink)(raw_data(raw))
		r.code_size = SHRINK_MIN_CODE_SIZE
		r.next_free = SHRINK_FIRST_FREE_CODE
		unshrink_init(r.shrink)
	case .Reduce:
		raw := runtime.mem_alloc_non_zeroed(size_of(Expand), align_of(Expand)) or_return
		r.expand        = (^Expand)(raw_data(raw))
		r.length_bits   = uint(8 - factor)
		r.length_max    = 1 << r.length_bits - 1
		r.distance_mask = 1 << uint(factor) - 1
	case .Implode:
		r.trees         = new([3]Implode_Tree) or_return
		r.literal_tree  = .Literal_Tree in implode_options
		r.distance_bits = uint(IMPLODE_DISTANCE_BITS_MAX if .Large_Window in implode_options else IMPLODE_DISTANCE_BITS_MAX - 1)
		r.min_match     = 3 if r.literal_tree else 2
	}

	if options.buffer != nil {
		r.window = options.buffer[:capacity]
	} else {
		r.window      = non_zero_make([]u8, capacity) or_return
		r.owns_window = true
	}

	if streamed {
		r.source = compress.init_context_from_stream(io.Stream{data = r, procedure = _source_proc}, nil, nil, allocator)
		r.streamed = true
		if r.source.backing == nil {
			return runtime.Allocator_Error.Out_Of_Memory
		}
		r.source.code_buffer = z.code_buffer
		r.source.num_bits    = z.num_bits
		z.code_buffer = 0
		z.num_bits    = 0
		r.base = i64(r.source.num_bits / 8)
		r.src  = &r.source
	}
	return nil
}

@(private)
_reader_fill :: proc(r: ^Reader) -> (err: Error) {
	if r.done {
		return nil
	}
	if i64(len(r.window) - r.ready) < min(i64(READER_STEP_MAX), r.size - r.produced) {
		keep := 0 if r.method == .Shrink else min(r.ready, READER_HISTORY)
		copy(r.window[:keep], r.window[r.ready - keep:r.ready])
		r.start = keep
		r.ready = keep
	}
	end := len(r.window) - READER_STEP_MAX
	if i64(len(r.window) - r.ready) >= r.size - r.produced {
		end = len(r.window)
	}
	switch r.method {
	case .Shrink:  err = _unshrink_fill(r, end)
	case .Reduce:  err = _expand_fill(r, end)
	case .Implode: err = _explode_fill(r, end)
	}
	if err == nil && r.produced == r.size {
		r.done = true
	}
	return
}

@(private)
_reader_drain :: proc(r: ^Reader, w: io.Writer) -> (err: Error) {
	for !r.done {
		fill_err := _reader_fill(r)
		produced := r.ready > r.start
		if produced {
			if _, write_err := io.write_full(w, r.window[r.start:r.ready]); write_err != nil {
				return write_err
			}
			r.start = r.ready
		}
		if fill_err != nil {
			return fill_err
		}
		if produced || r.done {
			_reader_progress(r) or_return
		}
	}
	return nil
}

@(private)
_reader_progress :: proc(r: ^Reader) -> (err: Error) {
	if r.options.progress == nil {
		return nil
	}
	consumed := r.base + r.pulled - i64(len(r.src.window)) - i64(r.src.num_bits / 8)
	return compress.report_progress(r.options, consumed, r.produced - i64(r.ready - r.start), r.total_in, r.size)
}

@(private)
_unshrink_fill :: proc(r: ^Reader, end: int) -> (err: Error) #no_bounds_check {
	z := r.src
	s := r.shrink
	if !r.started {
		r.started = true
		first, available := unshrink_read_code(z, &r.pulled, s, &r.code_size, &r.next_free) or_return
		if !available {
			return General_Error.Stream_Too_Short
		}
		if first > 255 {
			return PKZIP_Legacy_Error.Invalid_First_Code
		}
		r.previous   = first
		r.first_byte = u8(first)
		r.window[r.ready] = u8(first)
		r.ready    += 1
		r.produced += 1
	}

	window      := r.window
	ready       := r.ready
	start_ready := ready
	out_end     := ready + int(min(r.size - r.produced, i64(len(window))))
	stop        := min(end + 1, out_end)
	code_size   := r.code_size
	next_free   := r.next_free
	previous    := r.previous
	first_byte  := r.first_byte
	defer {
		r.produced  += i64(ready - start_ready)
		r.ready      = ready
		r.code_size  = code_size
		r.next_free  = next_free
		r.previous   = previous
		r.first_byte = first_byte
	}
	for ready < stop {
		code, available := unshrink_read_code(z, &r.pulled, s, &code_size, &next_free) or_return
		if !available {
			return General_Error.Stream_Too_Short
		}

		sp          := len(s.stack)
		current     := code
		substituted := false
		for current > 255 {
			if current == SHRINK_CONTROL_CODE {
				return PKZIP_Legacy_Error.Invalid_Code
			}
			if !s.used[current] {
				if current != next_free || substituted || sp <= 1 {
					return PKZIP_Legacy_Error.Invalid_Code
				}
				substituted = true
				sp -= 1
				s.stack[sp] = first_byte
				current = previous
				continue
			}
			if sp <= 1 || int(s.parent[current]) == current {
				return PKZIP_Legacy_Error.Invalid_Code
			}
			sp -= 1
			s.stack[sp] = s.value[current]
			current = int(s.parent[current])
		}
		sp -= 1
		s.stack[sp] = u8(current)
		first_byte  = u8(current)

		if next_free < SHRINK_TABLE_SIZE {
			unshrink_add(s, next_free, previous, first_byte)
			next_free = unshrink_next_free(s, next_free + 1)
		}
		previous = code

		n := len(s.stack) - sp
		if ready + n > out_end {
			return General_Error.Size_Mismatch
		}
		copy(window[ready:], s.stack[sp:])
		ready += n
	}
	return nil
}

@(private)
_expand_fill :: proc(r: ^Reader, end: int) -> (err: Error) #no_bounds_check {
	z := r.src
	e := r.expand
	if !r.started {
		r.started = true
		expand_read_followers(z, &r.pulled, e) or_return
	}

	window        := r.window
	ready         := r.ready
	start_ready   := ready
	base          := r.produced - i64(ready)
	out_end       := ready + int(min(r.size - r.produced, i64(len(window))))
	stop          := min(end + 1, out_end)
	length_bits   := r.length_bits
	length_max    := r.length_max
	distance_mask := r.distance_mask
	state         := r.state
	last          := r.last
	v             := r.v
	length        := r.length
	defer {
		r.produced += i64(ready - start_ready)
		r.ready     = ready
		r.state     = state
		r.last      = last
		r.v         = v
		r.length    = length
	}
	for ready < stop {
		symbol, available := expand_symbol(z, &r.pulled, e, last) or_return
		if !available {
			return General_Error.Stream_Too_Short
		}

		switch state {
		case .Literal:
			if symbol == REDUCE_DLE {
				state = .DLE
			} else {
				window[ready] = u8(symbol)
				ready += 1
			}
		case .DLE:
			if symbol == 0 {
				window[ready] = REDUCE_DLE
				ready += 1
				state  = .Literal
			} else {
				v      = symbol
				length = v & length_max
				state  = .Length if length == length_max else .Distance
			}
		case .Length:
			length += symbol
			state   = .Distance
		case .Distance:
			distance := (v >> length_bits & distance_mask) << 8 + symbol + 1
			n        := length + REDUCE_MIN_MATCH
			if ready + n > out_end {
				return General_Error.Size_Mismatch
			}
			_copy_match(window, ready, distance, n, base)
			ready += n
			state  = .Literal
		}
		last = symbol
	}
	return nil
}

@(private)
_explode_fill :: proc(r: ^Reader, end: int) -> (err: Error) #no_bounds_check {
	z := r.src
	t := r.trees
	if !r.started {
		r.started = true
		if r.literal_tree {
			explode_read_tree(z, &r.pulled, &t[0], IMPLODE_LITERAL_SYMBOLS) or_return
		}
		explode_read_tree(z, &r.pulled, &t[1], IMPLODE_LENGTH_SYMBOLS)   or_return
		explode_read_tree(z, &r.pulled, &t[2], IMPLODE_DISTANCE_SYMBOLS) or_return
	}

	window        := r.window
	ready         := r.ready
	start_ready   := ready
	base          := r.produced - i64(ready)
	out_end       := ready + int(min(r.size - r.produced, i64(len(window))))
	stop          := min(end + 1, out_end)
	literal_tree  := r.literal_tree
	distance_bits := r.distance_bits
	min_match     := r.min_match
	defer {
		r.produced += i64(ready - start_ready)
		r.ready     = ready
	}
	for ready < stop {
		flag, available := read_bits(z, &r.pulled, 1) or_return
		if !available {
			return General_Error.Stream_Too_Short
		}

		if flag == 1 {
			symbol: int
			if literal_tree {
				symbol, available = explode_decode(z, &r.pulled, &t[0]) or_return
			} else {
				symbol, available = read_bits(z, &r.pulled, 8) or_return
			}
			if !available {
				return General_Error.Stream_Too_Short
			}
			window[ready] = u8(symbol)
			ready += 1
			continue
		}

		low, high, length, extra: int
		low, available = read_bits(z, &r.pulled, distance_bits) or_return
		if !available {
			return General_Error.Stream_Too_Short
		}
		high, available = explode_decode(z, &r.pulled, &t[2]) or_return
		if !available {
			return General_Error.Stream_Too_Short
		}
		length, available = explode_decode(z, &r.pulled, &t[1]) or_return
		if !available {
			return General_Error.Stream_Too_Short
		}
		if length == IMPLODE_EXTRA_LENGTH {
			extra, available = read_bits(z, &r.pulled, 8) or_return
			if !available {
				return General_Error.Stream_Too_Short
			}
		}
		n := length + extra + min_match
		if ready + n > out_end {
			return General_Error.Size_Mismatch
		}
		_copy_match(window, ready, high << distance_bits + low + 1, n, base)
		ready += n
	}
	return nil
}

@(private)
_copy_match :: #force_inline proc(window: []u8, at, distance, length: int, base: i64) #no_bounds_check {
	from := at - distance
	i    := 0
	if i64(distance) > i64(at) + base {
		i = int(min(i64(distance) - i64(at) - base, i64(length)))
		for k in 0..<i {
			window[at + k] = 0
		}
	}
	if distance >= length - i {
		copy(window[at + i:at + length], window[from + i:from + length])
	} else {
		for ; i < length; i += 1 {
			window[at + i] = window[from + i]
		}
	}
}

@(private)
_source_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if len(r.z.window) > 0 {
			k := copy(p, r.z.window)
			r.z.window = r.z.window[k:]
			return i64(k), nil
		}
		k, read_err := io.read(r.z.input, p)
		return i64(k), read_err
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

@(private)
_reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Reader)(stream_data)
	#partial switch mode {
	case .Read:
		k, read_err := reader_read(r, p)
		if read_err != nil {
			if io_err, is_io := read_err.(io.Error); is_io {
				return i64(k), io_err
			}
			return i64(k), .Unknown
		}
		return i64(k), nil
	case .Destroy:
		reader_destroy(r)
		return 0, nil
	case .Query:
		return io.query_utility({.Read, .Destroy, .Query})
	}
	return 0, .Unsupported
}
