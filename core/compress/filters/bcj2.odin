package compress_filters

import "base:intrinsics"
import "base:runtime"
import "core:compress"
import "core:io"

bcj2_decode :: proc{bcj2_decode_to_slice, bcj2_decode_to_dynamic}

bcj2_decode_to_slice :: proc(output: []u8, main, call, jump, rc: []u8) -> (err: Error) {
	rest := len(output) - len(main)
	if rest < 0 || len(call) > rest || len(jump) != rest - len(call) {
		return General_Error.Size_Mismatch
	}
	return bcj2_decode_streams(output, main, call, jump, rc)
}

bcj2_decode_to_dynamic :: proc(output: ^[dynamic]u8, main, call, jump, rc: []u8, allocator := context.allocator) -> (err: Error) {
	if output == nil {
		return General_Error.Incompatible_Options
	}
	if len(call) > max(int) - len(main) || len(jump) > max(int) - len(main) - len(call) {
		return General_Error.Size_Mismatch
	}
	context.allocator = allocator
	non_zero_resize(output, len(main) + len(call) + len(jump)) or_return
	if err = bcj2_decode_streams(output[:], main, call, jump, rc); err != nil {
		non_zero_resize(output, 0)
	}
	return
}

bcj2_encode :: proc(streams: ^Bcj2_Streams, input: []u8, relat_limit := BCJ2_RELAT_LIMIT_DEFAULT, file_size := i64(-1), allocator := context.allocator) -> (err: Error) {
	if streams == nil || relat_limit > BCJ2_RELAT_LIMIT_MAX {
		return General_Error.Incompatible_Options
	}
	context.allocator = allocator
	non_zero_resize(&streams.main, len(input)) or_return
	clear(&streams.call)
	clear(&streams.jump)
	clear(&streams.rc)
	reserve(&streams.rc, len(input) / 64 + 16) or_return
	if err = bcj2_encode_streams(streams, input, relat_limit, file_size); err != nil {
		non_zero_resize(&streams.main, 0)
		clear(&streams.call)
		clear(&streams.jump)
		clear(&streams.rc)
	}
	return
}

bcj2_reader_init :: proc(r: ^Bcj2_Reader, main, call, jump, rc: io.Reader, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r^ = {}
	r.allocator = allocator
	defer r.err = err
	chunk := max(_chunk_size(options), FILTER_BUFFER_MIN)
	side  := min(BCJ2_SIDE_BUFFER_SIZE, max(chunk / 8, 8))
	if chunk > max(int) - 3 * side {
		return General_Error.Memory_Limit_Exceeded
	}
	r.storage, r.owns_storage = _stream_buffer(options, BCJ2_BUFFER_MIN, chunk + 3 * side, allocator) or_return
	if !r.owns_storage {
		side = min(BCJ2_SIDE_BUFFER_SIZE, len(r.storage) / 8)
	}
	readers := [Bcj2_Stream]io.Reader{.Main = main, .Call = call, .Jump = jump, .RC = rc}
	offset  := 0
	for &input, s in r.inputs {
		size  := len(r.storage) - 3 * side if s == .Main else side
		input  = {reader = readers[s], buffer = r.storage[offset:][:size]}
		offset += size
	}
	for &p in r.probs {
		p = BCJ2_PROB_INIT
	}
	r.step = .Header
	return nil
}

bcj2_reader_read :: proc(r: ^Bcj2_Reader, p: []u8) -> (n: int, err: Error) {
	for n < len(p) && r.err == nil && r.step != .Done {
		switch r.step {
		case .Header:
			r.err = _bcj2_header(r)
		case .Normalize:
			r.err = _bcj2_normalize(r)
		case .Scan:
			got: int
			got, r.err = _bcj2_run(r, p[n:])
			n += got
		case .Address:
			r.err = _bcj2_address(r)
		case .Output:
			copied := copy(p[n:], r.pending[r.pending_pos:])
			r.pending_pos += copied
			n             += copied
			if r.pending_pos == len(r.pending) {
				r.step = .Normalize
			}
		case .Verify:
			r.err = _bcj2_verify(r)
		case .Done:
		}
	}
	if n > 0 {
		return n, nil
	}
	if r.err != nil {
		return 0, r.err
	}
	if len(p) > 0 && r.step == .Done {
		return 0, io.Error.EOF
	}
	return 0, nil
}

bcj2_reader_to_stream :: proc(r: ^Bcj2_Reader) -> (s: io.Stream) {
	s.data      = r
	s.procedure = _bcj2_reader_stream_proc
	return
}

bcj2_reader_destroy :: proc(r: ^Bcj2_Reader) {
	if r.owns_storage {
		delete(r.storage, r.allocator)
	}
	r.storage      = nil
	r.owns_storage = false
	r.inputs       = {}
}

bcj2_writer_init :: proc(bw: ^Bcj2_Writer, main, call, jump, rc: io.Writer, relat_limit := BCJ2_RELAT_LIMIT_DEFAULT, file_size := i64(-1), options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	bw^ = {}
	bw.allocator = allocator
	defer bw.err = err
	if relat_limit > BCJ2_RELAT_LIMIT_MAX {
		return General_Error.Incompatible_Options
	}
	chunk := max(_chunk_size(options), FILTER_BUFFER_MIN)
	side  := min(BCJ2_SIDE_BUFFER_SIZE, chunk)
	if chunk > (max(int) - 3 * side) / 2 {
		return General_Error.Memory_Limit_Exceeded
	}
	bw.storage, bw.owns_storage = _stream_buffer(options, BCJ2_BUFFER_MIN, 2 * chunk + 3 * side, allocator) or_return
	staging := chunk
	if !bw.owns_storage {
		side    = min(BCJ2_SIDE_BUFFER_SIZE, len(bw.storage) / 8)
		staging = (len(bw.storage) - 3 * side) / 2
	}
	bw.input = bw.storage[:staging]
	rest    := bw.storage[staging:]
	bw.buffers[.Main] = rest[:len(rest) - 3 * side]
	rest = rest[len(bw.buffers[.Main]):]
	for s in ([?]Bcj2_Stream{.Call, .Jump, .RC}) {
		bw.buffers[s] = rest[:side]
		rest = rest[side:]
	}
	bw.outputs = {.Main = main, .Call = call, .Jump = jump, .RC = rc}
	for &p in bw.probs {
		p = BCJ2_PROB_INIT
	}
	bw.range_      = 0xFFFF_FFFF
	bw.cache_size  = 1
	bw.size_limit  = max(u64) if file_size < 0 else u64(file_size) - 1
	bw.relat_limit = relat_limit
	return nil
}

bcj2_writer_write :: proc(bw: ^Bcj2_Writer, p: []u8) -> (n: int, err: Error) {
	if bw.err != nil {
		return 0, bw.err
	}
	if bw.finished {
		return 0, io.Error.Closed
	}
	defer if err != nil {
		bw.err = err
	}
	for n < len(p) {
		copied := copy(bw.input[bw.pending:], p[n:])
		bw.pending += copied
		n          += copied
		if bw.pending < len(bw.input) {
			break
		}
		_bcj2_encode_chunk(bw, false) or_return
	}
	return
}

bcj2_writer_finish :: proc(bw: ^Bcj2_Writer) -> (err: Error) {
	if bw.err != nil {
		return bw.err
	}
	if bw.finished {
		return nil
	}
	defer if err != nil {
		bw.err = err
	}
	_bcj2_encode_chunk(bw, true) or_return
	for _ in 0..<5 {
		_bcj2_shift_low(bw) or_return
	}
	for s in Bcj2_Stream {
		_bcj2_flush(bw, s) or_return
	}
	bw.finished = true
	return nil
}

bcj2_writer_to_stream :: proc(bw: ^Bcj2_Writer) -> (s: io.Stream) {
	s.data      = bw
	s.procedure = _bcj2_writer_stream_proc
	return
}

bcj2_writer_destroy :: proc(bw: ^Bcj2_Writer) {
	if bw.owns_storage {
		delete(bw.storage, bw.allocator)
	}
	bw.storage      = nil
	bw.owns_storage = false
	bw.input        = nil
	bw.buffers      = {}
	bw.filled       = {}
	bw.pending      = 0
}

@(private)
bcj2_copy_scan :: #force_inline proc "contextless" (dst: []u8, o: int, src: []u8, start: int, prev: u32) -> int #no_bounds_check {
	LO :: 0x0101_0101_0101_0101
	HI :: 0x8080_8080_8080_8080
	k := start
	p := u64(prev)
	for k <= len(src) - 8 {
		v := u64(intrinsics.unaligned_load((^u64le)(&src[k])))
		intrinsics.unaligned_store((^u64le)(&dst[o + k - start]), u64le(v))
		a := (v & 0xFEFE_FEFE_FEFE_FEFE) ~ 0xE8E8_E8E8_E8E8_E8E8
		b := ((v & 0xF0F0_F0F0_F0F0_F0F0) ~ HI) | ((v << 8 | p) ~ 0x0F0F_0F0F_0F0F_0F0F)
		z := ((a - LO) & ~a | (b - LO) & ~b) & HI
		if z != 0 {
			return k + int(intrinsics.count_trailing_zeros(z) >> 3)
		}
		p  = v >> 56
		k += 8
	}
	for k < len(src) {
		c := u64(src[k])
		dst[o + k - start] = u8(c)
		if c & 0xFE == 0xE8 || (p == 0x0F && c & 0xF0 == 0x80) {
			return k
		}
		p  = c
		k += 1
	}
	return k
}

@(private)
bcj2_decode_streams :: proc(output: []u8, main, call, jump, rc: []u8) -> (err: Error) #no_bounds_check {
	if len(rc) < 5 {
		return General_Error.Stream_Too_Short
	}
	if rc[0] != 0 {
		return BCJ2_Error.Corrupt_Data
	}
	code := get_be32(rc, 1)
	if code == 0xFFFF_FFFF {
		return BCJ2_Error.Corrupt_Data
	}
	range_ := u32(0xFFFF_FFFF)
	r := 5

	probs: [2 + 256]u16 = ---
	for &p in probs {
		p = BCJ2_PROB_INIT
	}

	ip, prev := u32(0), u32(0)
	o, m, c, j := 0, 0, 0, 0
	for {
		if range_ < BCJ2_TOP {
			if r == len(rc) {
				return General_Error.Stream_Too_Short
			}
			range_ <<= 8
			code = code << 8 | u32(rc[r])
			r += 1
		}

		k := bcj2_copy_scan(output, o, main, m, prev)
		o  += k - m
		ip += u32(k - m)
		if k == len(main) {
			m = k
			break
		}
		marker := u32(main[k])
		before := prev if k == m else u32(main[k - 1])
		prev    = marker
		o  += 1
		ip += 1
		m   = k + 1

		index := 2 + int(before) if marker == 0xE8 else (1 if marker == 0xE9 else 0)
		ttt   := u32(probs[index])
		bound := (range_ >> BCJ2_PROB_BITS) * ttt
		if code < bound {
			range_ = bound
			probs[index] = u16(ttt + ((1 << BCJ2_PROB_BITS - ttt) >> BCJ2_MOVE_BITS))
			continue
		}
		range_ -= bound
		code   -= bound
		probs[index] = u16(ttt - (ttt >> BCJ2_MOVE_BITS))

		absolute: u32
		if marker == 0xE8 {
			if c > len(call) - 4 {
				return BCJ2_Error.Corrupt_Data
			}
			absolute = get_be32(call, c)
			c += 4
		} else {
			if j > len(jump) - 4 {
				return BCJ2_Error.Corrupt_Data
			}
			absolute = get_be32(jump, j)
			j += 4
		}
		ip += 4
		relative := absolute - ip
		put_le32(output, o, relative)
		o += 4
		prev = relative >> 24
	}

	if o != len(output) || c != len(call) || j != len(jump) || r != len(rc) || code != 0 {
		return BCJ2_Error.Corrupt_Data
	}
	return nil
}

@(private)
Bcj2_Range_Encoder :: struct {
	low:        u64,
	range_:     u32,
	cache:      u8,
	cache_size: u64,
	out:        ^[dynamic]u8,
}

@(private)
bcj2_shift_low :: proc(e: ^Bcj2_Range_Encoder) -> (err: runtime.Allocator_Error) {
	low  := u32(e.low)
	high := u8(e.low >> 32)
	if low < 0xFF00_0000 || high != 0 {
		temp := e.cache
		for {
			append(e.out, temp + high) or_return
			temp = 0xFF
			e.cache_size -= 1
			if e.cache_size == 0 {
				break
			}
		}
		e.cache = u8(low >> 24)
	}
	e.cache_size += 1
	e.low = u64(low << 8)
	return nil
}

@(private)
bcj2_encode_streams :: proc(streams: ^Bcj2_Streams, input: []u8, relat_limit: u32, file_size: i64) -> (err: Error) #no_bounds_check {
	probs: [2 + 256]u16 = ---
	for &p in probs {
		p = BCJ2_PROB_INIT
	}
	e := Bcj2_Range_Encoder{range_ = 0xFFFF_FFFF, cache_size = 1, out = &streams.rc}
	size_limit := max(u64) if file_size < 0 else u64(file_size) - 1

	main := streams.main[:]
	n    := len(input)
	ip   := u64(0)
	prev := u32(0)
	i, o := 0, 0
	for {
		if e.range_ < BCJ2_TOP {
			bcj2_shift_low(&e) or_return
			e.range_ <<= 8
		}

		k := bcj2_copy_scan(main, o, input, i, prev)
		o  += k - i
		ip += u64(k - i)
		if k == n {
			i = k
			break
		}
		marker := u32(input[k])
		before := prev if k == i else u32(input[k - 1])
		prev    = marker
		o  += 1
		ip += 1
		i   = k + 1

		convert  := false
		relative := u32(0)
		if n - i >= 4 {
			relative = get_le32(input, i)
			first    := u64(1) if marker & 0xF0 == 0x80 else 0
			if ip > first && u64(i64(ip) + 4 + i64(i32(relative))) <= size_limit && (relative + relat_limit) >> 1 < relat_limit {
				convert = true
			}
		}

		index := 2 + int(before) if marker == 0xE8 else (1 if marker == 0xE9 else 0)
		ttt   := u32(probs[index])
		bound := (e.range_ >> BCJ2_PROB_BITS) * ttt
		if !convert {
			e.range_ = bound
			probs[index] = u16(ttt + ((1 << BCJ2_PROB_BITS - ttt) >> BCJ2_MOVE_BITS))
			continue
		}
		e.low    += u64(bound)
		e.range_ -= bound
		probs[index] = u16(ttt - (ttt >> BCJ2_MOVE_BITS))

		ip += 4
		absolute := u32(ip) + relative
		target   := &streams.call if marker == 0xE8 else &streams.jump
		bytes    := [4]u8{u8(absolute >> 24), u8(absolute >> 16), u8(absolute >> 8), u8(absolute)}
		append(target, ..bytes[:]) or_return
		i += 4
		prev = relative >> 24
	}
	for _ in 0..<5 {
		bcj2_shift_low(&e) or_return
	}
	return non_zero_resize(&streams.main, o)
}

@(private)
_bcj2_fill :: proc(input: ^Bcj2_Input) -> (err: Error) {
	input.pos = 0
	input.end = 0
	stalls := 0
	for !input.eof {
		got, read_err := io.read(input.reader, input.buffer)
		if read_err == .EOF {
			input.end = got
			input.eof = true
			return nil
		}
		if read_err != nil {
			return read_err
		}
		if got > 0 {
			input.end = got
			return nil
		}
		stalls += 1
		if stalls > READ_STALLS_MAX {
			return io.Error.No_Progress
		}
	}
	return nil
}

@(private)
_bcj2_byte :: proc(input: ^Bcj2_Input, short: Error) -> (b: u8, err: Error) {
	if input.pos == input.end {
		_bcj2_fill(input) or_return
		if input.pos == input.end {
			return 0, short
		}
	}
	b = input.buffer[input.pos]
	input.pos += 1
	return
}

@(private)
_bcj2_header :: proc(r: ^Bcj2_Reader) -> (err: Error) {
	header: [5]u8
	for &b in header {
		b = _bcj2_byte(&r.inputs[.RC], General_Error.Stream_Too_Short) or_return
	}
	if header[0] != 0 {
		return BCJ2_Error.Corrupt_Data
	}
	r.code = get_be32(header[:], 1)
	if r.code == 0xFFFF_FFFF {
		return BCJ2_Error.Corrupt_Data
	}
	r.range_ = 0xFFFF_FFFF
	r.step   = .Normalize
	return nil
}

@(private)
_bcj2_normalize :: proc(r: ^Bcj2_Reader) -> (err: Error) {
	if r.range_ < BCJ2_TOP {
		b := _bcj2_byte(&r.inputs[.RC], General_Error.Stream_Too_Short) or_return
		r.range_ <<= 8
		r.code     = r.code << 8 | u32(b)
	}
	r.step = .Scan
	return nil
}

@(private)
_bcj2_run :: proc(r: ^Bcj2_Reader, dst: []u8) -> (n: int, err: Error) #no_bounds_check {
	main := &r.inputs[.Main]
	rc   := &r.inputs[.RC]
	for n < len(dst) {
		if main.pos == main.end {
			_bcj2_fill(main) or_return
			if main.pos == main.end {
				r.step = .Verify
				return
			}
		}
		src := main.buffer[main.pos:main.end]
		lim := min(len(src), len(dst) - n)
		k   := bcj2_copy_scan(dst, n, src[:lim], 0, r.prev)
		if k == lim {
			r.prev    = u32(src[lim - 1])
			r.ip     += u32(lim)
			main.pos += lim
			n        += lim
			continue
		}
		marker := u32(src[k])
		before := r.prev if k == 0 else u32(src[k - 1])
		r.prev    = marker
		r.ip     += u32(k + 1)
		main.pos += k + 1
		n        += k + 1

		index := 2 + int(before) if marker == 0xE8 else (1 if marker == 0xE9 else 0)
		ttt   := u32(r.probs[index])
		bound := (r.range_ >> BCJ2_PROB_BITS) * ttt
		if r.code < bound {
			r.range_ = bound
			r.probs[index] = u16(ttt + ((1 << BCJ2_PROB_BITS - ttt) >> BCJ2_MOVE_BITS))
		} else {
			r.range_ -= bound
			r.code   -= bound
			r.probs[index] = u16(ttt - (ttt >> BCJ2_MOVE_BITS))
			side := &r.inputs[.Call if marker == 0xE8 else .Jump]
			if side.end - side.pos < 4 || len(dst) - n < 4 {
				r.marker = marker
				r.step   = .Address
				return
			}
			absolute := get_be32(side.buffer, side.pos)
			side.pos += 4
			r.ip     += 4
			relative := absolute - r.ip
			put_le32(dst, n, relative)
			n     += 4
			r.prev = relative >> 24
		}
		if r.range_ < BCJ2_TOP {
			if rc.pos == rc.end {
				r.step = .Normalize
				return
			}
			r.range_ <<= 8
			r.code     = r.code << 8 | u32(rc.buffer[rc.pos])
			rc.pos    += 1
		}
	}
	return
}

@(private)
_bcj2_address :: proc(r: ^Bcj2_Reader) -> (err: Error) {
	side := &r.inputs[.Call if r.marker == 0xE8 else .Jump]
	bytes: [4]u8
	for &b in bytes {
		b = _bcj2_byte(side, BCJ2_Error.Corrupt_Data) or_return
	}
	r.ip += 4
	relative := get_be32(bytes[:], 0) - r.ip
	put_le32(r.pending[:], 0, relative)
	r.pending_pos = 0
	r.prev        = relative >> 24
	r.step        = .Output
	return nil
}

@(private)
_bcj2_verify :: proc(r: ^Bcj2_Reader) -> (err: Error) {
	for s in ([?]Bcj2_Stream{.Call, .Jump, .RC}) {
		input := &r.inputs[s]
		if input.pos == input.end {
			_bcj2_fill(input) or_return
		}
		if input.pos < input.end {
			return BCJ2_Error.Corrupt_Data
		}
	}
	if r.code != 0 {
		return BCJ2_Error.Corrupt_Data
	}
	r.step = .Done
	return nil
}

@(private)
_bcj2_flush :: proc(bw: ^Bcj2_Writer, s: Bcj2_Stream) -> (err: Error) {
	if bw.filled[s] == 0 {
		return nil
	}
	written, write_err := io.write_full(bw.outputs[s], bw.buffers[s][:bw.filled[s]])
	bw.written[s] += i64(written)
	bw.filled[s]   = 0
	if write_err != nil {
		return write_err
	}
	return nil
}

@(private)
_bcj2_shift_low :: proc(bw: ^Bcj2_Writer) -> (err: Error) {
	low  := u32(bw.low)
	high := u8(bw.low >> 32)
	if low < 0xFF00_0000 || high != 0 {
		temp := bw.cache
		for {
			if bw.filled[.RC] == len(bw.buffers[.RC]) {
				_bcj2_flush(bw, .RC) or_return
			}
			bw.buffers[.RC][bw.filled[.RC]] = temp + high
			bw.filled[.RC] += 1
			temp = 0xFF
			bw.cache_size -= 1
			if bw.cache_size == 0 {
				break
			}
		}
		bw.cache = u8(low >> 24)
	}
	bw.cache_size += 1
	bw.low = u64(low << 8)
	return nil
}

@(private)
_bcj2_encode_chunk :: proc(bw: ^Bcj2_Writer, final: bool) -> (err: Error) {
	data := bw.input[:bw.pending]
	used := _bcj2_encode_run(bw, data, final) or_return
	_bcj2_flush(bw, .Main) or_return
	bw.pending = copy(bw.input, data[used:])
	return nil
}

@(private)
_bcj2_encode_run :: proc(bw: ^Bcj2_Writer, data: []u8, final: bool) -> (i: int, err: Error) #no_bounds_check {
	main := bw.buffers[.Main]
	n    := len(data)
	o    := bw.filled[.Main]
	defer bw.filled[.Main] = o
	for {
		if !bw.scanning {
			if bw.range_ < BCJ2_TOP {
				_bcj2_shift_low(bw) or_return
				bw.range_ <<= 8
			}
			bw.scanning = true
		}

		k := bcj2_copy_scan(main, o, data, i, bw.prev)
		if k == n || (!final && n - k <= 4) {
			o     += k - i
			bw.ip += u64(k - i)
			if k > i {
				bw.prev = u32(data[k - 1])
			}
			i = k
			return
		}
		marker := u32(data[k])
		before := bw.prev if k == i else u32(data[k - 1])
		bw.prev     = marker
		o          += k - i + 1
		bw.ip      += u64(k - i + 1)
		i           = k + 1
		bw.scanning = false

		convert  := false
		relative := u32(0)
		if n - i >= 4 {
			relative = get_le32(data, i)
			first    := u64(1) if marker & 0xF0 == 0x80 else 0
			if bw.ip > first && u64(i64(bw.ip) + 4 + i64(i32(relative))) <= bw.size_limit && (relative + bw.relat_limit) >> 1 < bw.relat_limit {
				convert = true
			}
		}

		index := 2 + int(before) if marker == 0xE8 else (1 if marker == 0xE9 else 0)
		ttt   := u32(bw.probs[index])
		bound := (bw.range_ >> BCJ2_PROB_BITS) * ttt
		if !convert {
			bw.range_ = bound
			bw.probs[index] = u16(ttt + ((1 << BCJ2_PROB_BITS - ttt) >> BCJ2_MOVE_BITS))
			continue
		}
		bw.low    += u64(bound)
		bw.range_ -= bound
		bw.probs[index] = u16(ttt - (ttt >> BCJ2_MOVE_BITS))

		bw.ip += 4
		absolute := u32(bw.ip) + relative
		target   := Bcj2_Stream.Call if marker == 0xE8 else .Jump
		if len(bw.buffers[target]) - bw.filled[target] < 4 {
			_bcj2_flush(bw, target) or_return
		}
		put_be32(bw.buffers[target], bw.filled[target], absolute)
		bw.filled[target] += 4
		i      += 4
		bw.prev = relative >> 24
	}
}

@(private)
_bcj2_reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Bcj2_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		read, read_err := bcj2_reader_read(r, p)
		return i64(read), _io_error(read_err)
	case .Destroy:
		bcj2_reader_destroy(r)
		return 0, nil
	case .Query:
		return io.query_utility({.Read, .Destroy, .Query})
	}
	return 0, .Unsupported
}

@(private)
_bcj2_writer_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	bw := (^Bcj2_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		written, write_err := bcj2_writer_write(bw, p)
		return i64(written), _io_error(write_err)
	case .Close:
		return 0, _io_error(bcj2_writer_finish(bw))
	case .Destroy:
		bcj2_writer_destroy(bw)
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Close, .Destroy, .Query})
	}
	return 0, .Unsupported
}
