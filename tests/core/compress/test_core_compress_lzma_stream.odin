package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/lzma"
import "core:io"
import "core:math/rand"
import "core:testing"

Lzma_Stream_Kind :: enum u8 {
	Alone,
	Raw,
	LZMA2,
}

Lzma_Stream_Case :: struct {
	kind:   Lzma_Stream_Kind,
	packed: []u8,
	props:  lzma.Properties,
	plain:  []u8,
}

Lzma_Stream_Calls :: struct {
	calls:     int,
	last_out:  i64,
	last_in:   i64,
	monotonic: bool,
	cancel_at: int,
}

@(test)
test_lzma_stream_differential :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	sources := [?][]u8{{}, {'A'}, inputs.text, inputs.random, inputs.repeat, inputs.mixed, inputs.chunks}

	for source in sources {
		for dict in ([?]u32{4096, 1 << 16, 1 << 20}) {
			for kind in Lzma_Stream_Kind {
				c, ok := lzma_stream_case(t, kind, source, dict)
				if !ok {
					continue
				}
				defer delete(c.packed)
				for chunk_size in ([?]int{0, 1, 4096}) {
					options := compress.Options{chunk_size = chunk_size}
					for streamed in ([?]bool{false, true}) {
						lzma_check_push(t, c, options, streamed)
						for read_size in ([?]int{1, 7, 4096, -1}) {
							lzma_check_pull(t, c, options, streamed, read_size)
						}
					}
				}
			}
		}
	}
}

@(test)
test_lzma_stream_window_bounded :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	big: [dynamic]u8
	defer delete(big)
	for _ in 0..<12 {
		append(&big, ..inputs.mixed)
	}
	c, ok := lzma_stream_case(t, .LZMA2, big[:], 4096)
	if !ok {
		return
	}
	defer delete(c.packed)

	data := c.packed
	z    := compress.init_context_from_slice(&data)
	r: lzma.Reader
	testing.expect_value(t, lzma.reader_init_lzma2(&r, &z, 4096, -1, {chunk_size = 1024}), nil)
	defer lzma.reader_destroy(&r)
	out: [dynamic]u8
	defer delete(out)
	largest := 0
	buf: [3000]u8
	for {
		n, err := lzma.reader_read(&r, buf[:])
		append(&out, ..buf[:n])
		largest = max(largest, cap(r.window))
		if err == io.Error.EOF {
			break
		}
		if !testing.expect_value(t, err, nil) {
			return
		}
	}
	testing.expect(t, bytes.equal(out[:], big[:]), "window-bounded decode differs")
	testing.expectf(t, largest <= 4096 + 1024, "window grew to %d", largest)
}

@(test)
test_lzma_stream_memory_limit :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	c, ok := lzma_stream_case(t, .LZMA2, inputs.text, 1 << 20)
	if !ok {
		return
	}
	defer delete(c.packed)

	sink: bytes.Buffer
	defer bytes.buffer_destroy(&sink)
	data := c.packed
	z    := compress.init_context_from_slice(&data)
	err  := lzma.decompress_lzma2_to_writer(bytes.buffer_to_stream(&sink), &z, 1 << 30, -1, {max_memory = 1 << 20})
	testing.expect_value(t, err, compress.Error(compress.General_Error.Memory_Limit_Exceeded))
	testing.expect_value(t, bytes.buffer_length(&sink), 0)

	data = c.packed
	z    = compress.init_context_from_slice(&data)
	err  = lzma.decompress_lzma2_to_writer(bytes.buffer_to_stream(&sink), &z, 1 << 30, len(inputs.text), {max_memory = 1 << 20})
	testing.expect_value(t, err, nil)
	testing.expect(t, bytes.equal(bytes.buffer_to_bytes(&sink), inputs.text), "known size, huge dict")

	alone: [dynamic]u8
	defer delete(alone)
	testing.expect_value(t, lzma.compress(&alone, inputs.text), nil)
	alone[1], alone[2], alone[3], alone[4] = 0xFF, 0xFF, 0xFF, 0xFF
	bytes.buffer_reset(&sink)
	data = alone[:]
	z    = compress.init_context_from_slice(&data)
	testing.expect_value(t, lzma.decompress_to_writer(bytes.buffer_to_stream(&sink), &z, -1, {max_memory = 1 << 20}), nil)
	testing.expect(t, bytes.equal(bytes.buffer_to_bytes(&sink), inputs.text), ".lzma with a 4 GiB dict and a known size")

	small := make([]u8, 1000)
	defer delete(small)
	data = c.packed
	z    = compress.init_context_from_slice(&data)
	r: lzma.Reader
	testing.expect_value(t, lzma.reader_init_lzma2(&r, &z, 1 << 20, -1, {buffer = small}), compress.Error(compress.General_Error.Memory_Limit_Exceeded))
	lzma.reader_destroy(&r)

	window := make([]u8, (1 << 20) + 4096)
	defer delete(window)
	data = c.packed
	z    = compress.init_context_from_slice(&data)
	bytes.buffer_reset(&sink)
	testing.expect_value(t, lzma.decompress_lzma2_to_writer(bytes.buffer_to_stream(&sink), &z, 1 << 20, -1, {buffer = window}), nil)
	testing.expect(t, bytes.equal(bytes.buffer_to_bytes(&sink), inputs.text), "caller's buffer")
}

@(test)
test_lzma_stream_errors :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	for kind in Lzma_Stream_Kind {
		c, ok := lzma_stream_case(t, kind, inputs.mixed, 1 << 16)
		if !ok {
			continue
		}
		defer delete(c.packed)
		for n := 0; n < len(c.packed); n += max(1, len(c.packed) / 97) {
			cut := c
			cut.packed = c.packed[:n]
			memory_err, memory_out := lzma_decode_memory(cut)
			stream_err, stream_out := lzma_decode_push(cut, {chunk_size = 1}, n % 2 == 0)
			delete(memory_out)
			delete(stream_out)
			testing.expectf(t, (memory_err == nil) == (stream_err == nil), "%v cut at %d: memory %v, stream %v", kind, n, memory_err, stream_err)
		}
		mutated := make([]u8, len(c.packed))
		defer delete(mutated)
		for i in 0..<200 {
			copy(mutated, c.packed)
			at := rand.int_max(len(mutated))
			mutated[at] ~= u8(1 << uint(rand.int_max(8)))
			m := c
			m.packed = mutated
			memory_err, memory_out := lzma_decode_memory(m)
			stream_err, stream_out := lzma_decode_push(m, {chunk_size = 1}, i % 2 == 0)
			testing.expectf(t, (memory_err == nil) == (stream_err == nil), "%v flip at %d: memory %v, stream %v", kind, at, memory_err, stream_err)
			if memory_err == nil && stream_err == nil {
				testing.expectf(t, bytes.equal(memory_out[:], stream_out[:]), "%v flip at %d: outputs differ", kind, at)
			}
			delete(memory_out)
			delete(stream_out)
		}
	}
}

@(test)
test_lzma_stream_progress :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	c, ok := lzma_stream_case(t, .LZMA2, inputs.mixed, 4096)
	if !ok {
		return
	}
	defer delete(c.packed)
	for cancel in ([2]int{0, 3}) {
		calls := Lzma_Stream_Calls{monotonic = true, cancel_at = cancel}
		options := compress.Options{chunk_size = 4096, progress = lzma_stream_progress, progress_data = &calls}
		err, out := lzma_decode_push(c, options, false)
		delete(out)
		if cancel == 0 {
			testing.expect_value(t, err, nil)
			testing.expectf(t, calls.calls > 3, "%d calls", calls.calls)
			testing.expect_value(t, calls.last_out, i64(len(inputs.mixed)))
			testing.expect_value(t, calls.last_in, i64(len(c.packed)))
		} else {
			testing.expect_value(t, err, compress.Error(compress.General_Error.Canceled))
			testing.expect_value(t, calls.calls, cancel)
		}
		testing.expect(t, calls.monotonic, "progress went backwards")
	}
}

lzma_stream_case :: proc(t: ^testing.T, kind: Lzma_Stream_Kind, plain: []u8, dict: u32) -> (c: Lzma_Stream_Case, ok: bool) {
	options := lzma.level_options(.Level_5)
	options.dict_size = dict
	c.kind  = kind
	c.plain = plain
	packed: [dynamic]u8
	err: compress.Error
	switch kind {
	case .Alone:
		err = lzma.compress(&packed, plain)
	case .Raw:
		options.end_marker = true
		c.props, err = lzma.compress_raw(&packed, plain, options)
	case .LZMA2:
		c.props, err = lzma.compress_lzma2(&packed, plain, options)
	}
	if !testing.expectf(t, err == nil, "%v encode: %v", kind, err) {
		delete(packed)
		return
	}
	c.packed = packed[:]
	return c, true
}

lzma_decode_memory :: proc(c: Lzma_Stream_Case) -> (err: compress.Error, out: [dynamic]u8) {
	switch c.kind {
	case .Alone: err = lzma.decompress(&out, c.packed)
	case .Raw:   err = lzma.decompress_raw(&out, c.packed, c.props)
	case .LZMA2: err = lzma.decompress_lzma2(&out, c.packed, c.props.dict_size)
	}
	return
}

lzma_stream_context :: proc(data: ^[]u8, reader: ^bytes.Reader, streamed: bool) -> compress.Context {
	if streamed {
		return compress.init_context_from_stream(bytes.reader_init(reader, data^))
	}
	return compress.init_context_from_slice(data)
}

lzma_decode_push :: proc(c: Lzma_Stream_Case, options: compress.Options, streamed: bool) -> (err: compress.Error, out: [dynamic]u8) {
	sink: bytes.Buffer
	data := c.packed
	reader: bytes.Reader
	z := lzma_stream_context(&data, &reader, streamed)
	defer compress.destroy_context(&z)
	w := bytes.buffer_to_stream(&sink)
	switch c.kind {
	case .Alone: err = lzma.decompress_to_writer(w, &z, -1, options)
	case .Raw:   err = lzma.decompress_raw_to_writer(w, &z, c.props, -1, options)
	case .LZMA2: err = lzma.decompress_lzma2_to_writer(w, &z, c.props.dict_size, -1, options)
	}
	append(&out, ..bytes.buffer_to_bytes(&sink))
	bytes.buffer_destroy(&sink)
	return
}

lzma_check_push :: proc(t: ^testing.T, c: Lzma_Stream_Case, options: compress.Options, streamed: bool, loc := #caller_location) {
	err, out := lzma_decode_push(c, options, streamed)
	defer delete(out)
	testing.expectf(t, err == nil && bytes.equal(out[:], c.plain), "%v push, %d bytes, chunk %d, streamed %v: %v, %d bytes out", c.kind, len(c.plain), options.chunk_size, streamed, err, len(out), loc = loc)
}

lzma_check_pull :: proc(t: ^testing.T, c: Lzma_Stream_Case, options: compress.Options, streamed: bool, read_size: int, loc := #caller_location) {
	data := c.packed
	reader: bytes.Reader
	z := lzma_stream_context(&data, &reader, streamed)
	defer compress.destroy_context(&z)
	r: lzma.Reader
	err: compress.Error
	switch c.kind {
	case .Alone: err = lzma.reader_init(&r, &z, -1, options)
	case .Raw:   err = lzma.reader_init_raw(&r, &z, c.props, -1, options)
	case .LZMA2: err = lzma.reader_init_lzma2(&r, &z, c.props.dict_size, -1, options)
	}
	defer lzma.reader_destroy(&r)
	if !testing.expectf(t, err == nil, "%v pull init: %v", c.kind, err, loc = loc) {
		return
	}
	s := lzma.reader_to_stream(&r)
	out: [dynamic]u8
	defer delete(out)
	buf: [4096]u8
	for {
		size := read_size if read_size > 0 else 1 + rand.int_max(len(buf))
		n, read_err := io.read(s, buf[:size])
		append(&out, ..buf[:n])
		if read_err == .EOF {
			break
		}
		if !testing.expectf(t, read_err == nil, "%v pull, read %d: %v", c.kind, read_size, read_err, loc = loc) {
			return
		}
	}
	testing.expectf(t, bytes.equal(out[:], c.plain), "%v pull, %d bytes, read %d, chunk %d, streamed %v: %d bytes out", c.kind, len(c.plain), read_size, options.chunk_size, streamed, len(out), loc = loc)
}

lzma_stream_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	calls := (^Lzma_Stream_Calls)(user_data)
	calls.calls += 1
	if progress.bytes_out < calls.last_out || progress.bytes_in < calls.last_in {
		calls.monotonic = false
	}
	calls.last_out = progress.bytes_out
	calls.last_in  = progress.bytes_in
	return calls.cancel_at != 0 && calls.calls >= calls.cancel_at
}
