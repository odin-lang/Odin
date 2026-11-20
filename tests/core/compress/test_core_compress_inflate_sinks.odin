package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/deflate"
import "core:io"
import "core:math/rand"
import "core:testing"

INFLATE_SINKS_FUZZ :: #config(INFLATE_SINKS_FUZZ, 150)

Sink :: enum {
	Writer,
	Reader,
	Reader_Stream,
}

Append_Writer :: struct {
	out:     ^[dynamic]byte,
	fail_at: int,
}

append_writer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	w := (^Append_Writer)(stream_data)
	#partial switch mode {
	case .Write:
		if w.fail_at >= 0 && len(w.out) + len(p) > w.fail_at {
			room := max(w.fail_at - len(w.out), 0)
			append(w.out, ..p[:room])
			return i64(room), .Short_Write
		}
		append(w.out, ..p)
		return i64(len(p)), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

append_writer :: proc(w: ^Append_Writer) -> io.Writer {
	return io.Writer{procedure = append_writer_proc, data = w}
}

@(test)
inflate_sinks_round_trip :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for format in deflate.Format {
		for level in ([]deflate.Deflate_Level{.Stored, .Level_1, .Level_6}) {
			packed: [dynamic]byte
			defer delete(packed)
			testing.expect_value(t, sinks_pack(format, data, &packed, level), nil)
			trailer := DEFLATE_TEST_TRAILER
			append(&packed, ..trailer[:])

			for kind in Stream_Kind {
				for chunk in ([]int{0, 300, 32 * 1024, 1 << 20}) {
					sinks_check(t, "round trip", format, kind, packed[:], options = {chunk_size = chunk})
				}
			}
		}
	}
}

@(test)
inflate_reader_random_reads :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for format in deflate.Format {
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, sinks_pack(format, data, &packed, .Level_6), nil)

		for round in 0..<8 {
			input := packed[:]
			br: bytes.Reader
			tr: Trickle_Reader
			kind := Stream_Kind(round % len(Stream_Kind))
			ctx := stream_test_context(kind, &input, &br, &tr)
			defer compress.destroy_context(&ctx)

			r := new(deflate.Reader)
			defer free(r)
			defer deflate.reader_destroy(r)
			testing.expect_value(t, deflate.reader_init(r, &ctx, format, options = {chunk_size = 1 + rand.int_max(100_000)}), nil)

			output: [dynamic]byte
			defer delete(output)
			buffer := make([]byte, 100_000)
			defer delete(buffer)
			err: compress.Error
			for err == nil {
				size := 1 + rand.int_max(len(buffer))
				if rand.int_max(2) == 0 {
					size = 1 + rand.int_max(16)
				}
				n: int
				n, err = deflate.reader_read(r, buffer[:size])
				testing.expectf(t, n > 0 || err != nil, "%v, %v: empty read without an error", format, kind)
				append(&output, ..buffer[:n])
			}
			testing.expectf(t, err == io.Error.EOF, "%v, %v: %v", format, kind, err)
			testing.expectf(t, bytes.equal(output[:], data), "%v, %v: output differs, %v vs %v bytes", format, kind, len(output), len(data))

			n, again := deflate.reader_read(r, buffer[:])
			testing.expectf(t, n == 0 && again == io.Error.EOF, "%v, %v: read after EOF gave %v, %v", format, kind, n, again)
			n, again = deflate.reader_read(r, nil)
			testing.expectf(t, n == 0 && again == nil, "%v, %v: empty read after EOF gave %v, %v", format, kind, n, again)
		}
	}
}

@(test)
inflate_reader_as_stream :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.compress_gzip(&packed, data), nil)

	input := packed[:]
	ctx := compress.init_context(&input)
	r: deflate.Reader
	testing.expect_value(t, deflate.reader_init(&r, &ctx, .Gzip), nil)
	stream := deflate.reader_to_stream(&r)
	defer io.destroy(stream)

	testing.expect_value(t, io.query(stream), io.Stream_Mode_Set{.Read, .Destroy, .Query})
	output := make([]byte, len(data))
	defer delete(output)
	n, err := io.read_full(stream, output)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n, len(data))
	testing.expect(t, bytes.equal(output, data), "output differs")
	extra: [1]byte
	n, err = io.read(stream, extra[:])
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.EOF)

	packed[len(packed) - 8] ~= 0x55
	input = packed[:]
	bad := compress.init_context(&input)
	broken: deflate.Reader
	defer deflate.reader_destroy(&broken)
	testing.expect_value(t, deflate.reader_init(&broken, &bad, .Gzip), nil)
	n, err = io.read_full(deflate.reader_to_stream(&broken), output)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, n, len(data))
	n, err = io.read(deflate.reader_to_stream(&broken), extra[:])
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.Unknown)
	testing.expect_value(t, broken.err, compress.Error(compress.GZIP_Error.Payload_CRC_Invalid))
}

@(test)
inflate_truncated_prefix :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	cuts := 8 if SLIM_TESTS else 48
	for format in deflate.Format {
		slack := 2 + (65_538 if format == .Raw64 else 258)
		for level in ([]deflate.Deflate_Level{.Stored, .Level_1, .Level_6}) {
			packed: [dynamic]byte
			defer delete(packed)
			testing.expect_value(t, sinks_pack(format, data, &packed, level), nil)

			for step in 0..<cuts + 8 {
				cut := len(packed) * step / cuts if step < cuts else len(packed) - 1 - (step - cuts)
				for kind in Stream_Kind {
					if kind == .One_Byte_No_Seek && step % 16 != 3 {
						continue
					}
					want: [dynamic]byte
					defer delete(want)
					rest: [5]byte
					want_err, _ := sinks_memory_unpack(format, kind, packed[:cut], &want, -1, {}, &rest)
					testing.expectf(t, want_err != nil, "%v, %v, %v, cut %v of %v: no error", format, level, kind, cut, len(packed))
					testing.expectf(t, len(want) <= len(data) && bytes.equal(want[:], data[:len(want)]), "%v, %v, %v, cut %v of %v: one-shot output is not a prefix", format, level, kind, cut, len(packed))
					if cut >= len(packed) / 2 {
						testing.expectf(t, len(want) >= len(data) / 4, "%v, %v, %v, cut %v of %v: only %v bytes", format, level, kind, cut, len(packed), len(want))
					}
					for sink in Sink {
						got: [dynamic]byte
						defer delete(got)
						err, _, _ := sinks_unpack(sink, format, kind, packed[:cut], &got, -1, {chunk_size = sinks_chunk(len(data))}, &rest)
						testing.expectf(t, err == want_err, "%v, %v, %v, %v, cut %v of %v: %v, one-shot gave %v", format, level, kind, sink, cut, len(packed), err, want_err)
						testing.expectf(t, len(got) <= len(data) && bytes.equal(got[:], data[:len(got)]), "%v, %v, %v, %v, cut %v of %v: output is not a prefix", format, level, kind, sink, cut, len(packed))
						testing.expectf(t, abs(len(got) - len(want)) <= slack, "%v, %v, %v, %v, cut %v of %v: %v bytes, one-shot gave %v", format, level, kind, sink, cut, len(packed), len(got), len(want))
					}
				}
			}
		}
	}
}

@(test)
inflate_sinks_options :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.compress_raw(&packed, data), nil)

	{
		buffer := make([]byte, 40_000)
		defer delete(buffer)
		sinks_check(t, "caller buffer", .Raw, .Memory, packed[:], options = {buffer = buffer})
		sinks_check(t, "caller buffer", .Raw, .Odd_Chunks_Seekable, packed[:], options = {buffer = buffer})

		input := packed[:]
		ctx := compress.init_context(&input)
		output: [dynamic]byte
		defer delete(output)
		aw := Append_Writer{out = &output, fail_at = -1}
		err := deflate.decompress_raw_to_writer(append_writer(&aw), &ctx, options = {buffer = buffer[:32 * 1024 + 306]})
		testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
		testing.expect_value(t, len(output), 0)

		r: deflate.Reader
		input = packed[:]
		ctx = compress.init_context(&input)
		testing.expect_value(t, deflate.reader_init(&r, &ctx, .Raw, len(data), {buffer = buffer}), nil)
		testing.expect_value(t, raw_data(r.window), raw_data(buffer))
		deflate.reader_destroy(&r)
		testing.expect_value(t, len(buffer), 40_000)
	}

	for memory in ([]int{32 * 1024 + 306, 32 * 1024 + 306 + 4096, 40_000, 1 << 20}) {
		input := packed[:]
		ctx := compress.init_context(&input)
		output: [dynamic]byte
		defer delete(output)
		aw := Append_Writer{out = &output, fail_at = -1}
		err := deflate.decompress_raw_to_writer(append_writer(&aw), &ctx, options = {max_memory = memory})
		if memory == 32 * 1024 + 306 {
			testing.expectf(t, err == compress.General_Error.Memory_Limit_Exceeded, "max_memory %v: %v", memory, err)
		} else {
			testing.expectf(t, err == nil && bytes.equal(output[:], data), "max_memory %v: %v, %v bytes", memory, err, len(output))
		}

		r: deflate.Reader
		input = packed[:]
		ctx = compress.init_context(&input)
		if deflate.reader_init(&r, &ctx, .Raw, options = {max_memory = memory}) == nil {
			testing.expectf(t, len(r.window) <= memory, "max_memory %v: window of %v bytes", memory, len(r.window))
		}
		deflate.reader_destroy(&r)
	}

	for expected in ([]int{1, 1000, len(data) - 1, len(data), len(data) + 1}) {
		for kind in Stream_Kind {
			sinks_check(t, "expected size", .Raw, kind, packed[:], expected)
		}
		r: deflate.Reader
		input := packed[:]
		ctx := compress.init_context(&input)
		testing.expect_value(t, deflate.reader_init(&r, &ctx, .Raw, expected), nil)
		testing.expectf(t, len(r.window) <= max(expected, 300_000), "expected %v: window of %v bytes", expected, len(r.window))
		deflate.reader_destroy(&r)
	}

	for limit in ([]int{-1, 1, 70_000, len(data) - 1, len(data)}) {
		sinks_check(t, "max_output_size", .Raw, .Memory, packed[:], options = {max_output_size = limit})
		sinks_check(t, "max_output_size", .Raw, .Bytes_Reader, packed[:], options = {max_output_size = limit, chunk_size = 5000})
	}
	sinks_check(t, "expected over max_output_size", .Raw, .Memory, packed[:], 2 * len(data), {max_output_size = len(data)})
	sinks_check(t, "expected over max_output_size", .Gzip, .Memory, packed[:], 2 * len(data), {max_output_size = len(data)})

	{
		input := packed[:]
		ctx := compress.init_context(&input)
		output: [dynamic]byte
		defer delete(output)
		aw := Append_Writer{out = &output, fail_at = 1}
		err := deflate.decompress_raw_to_writer(append_writer(&aw), &ctx, options = {max_memory = -1})
		testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
		err = deflate.decompress_raw_to_writer(append_writer(&aw), &ctx, options = {chunk_size = -1})
		testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
	}
}

@(test)
inflate_writer_errors :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.compress_zlib(&packed, data), nil)

	for fail_at in ([]int{0, 1, 100_000, len(data) - 1}) {
		input := packed[:]
		ctx := compress.init_context(&input)
		output: [dynamic]byte
		defer delete(output)
		aw := Append_Writer{out = &output, fail_at = fail_at}
		err := deflate.decompress_zlib_to_writer(append_writer(&aw), &ctx, options = {chunk_size = 4096})
		testing.expectf(t, err == io.Error.Short_Write, "fail at %v: %v", fail_at, err)
		testing.expectf(t, bytes.equal(output[:], data[:fail_at]), "fail at %v: %v bytes written", fail_at, len(output))
	}
}

@(test)
inflate_sinks_empty_and_tiny :: proc(t: ^testing.T) {
	for format in deflate.Format {
		for size in ([]int{0, 1, 2, 257, 32 * 1024, 32 * 1024 + 1, 64 * 1024 + 7}) {
			data := make([]byte, size)
			defer delete(data)
			for i in 0..<size {
				data[i] = byte(i * 31 + i / 7)
			}
			for level in ([]deflate.Deflate_Level{.Stored, .Level_6}) {
				packed: [dynamic]byte
				defer delete(packed)
				testing.expect_value(t, sinks_pack(format, data, &packed, level), nil)
				for kind in Stream_Kind {
					sinks_check(t, "tiny", format, kind, packed[:], options = {chunk_size = max(1 + rand.int_max(3), size / 256)})
					sinks_check(t, "tiny", format, kind, packed[:], size)
				}
			}
		}
	}
}

@(test)
inflate_sinks_fuzz :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	for _ in 0..<INFLATE_SINKS_FUZZ {
		data: [dynamic]byte
		defer delete(data)
		d64_test_data(rand.int_max(4), rand.int_max(150_000), &data)
		format := deflate.Format(rand.int_max(len(deflate.Format)))
		level  := deflate.Deflate_Level(rand.int_max(11))
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, sinks_pack(format, data[:], &packed, level), nil)
		if rand.int_max(3) == 0 && format == .Gzip {
			second: [dynamic]byte
			defer delete(second)
			testing.expect_value(t, sinks_pack(format, data[:len(data) / 3], &second, level), nil)
			append(&packed, ..second[:])
		}
		kind := Stream_Kind(rand.int_max(len(Stream_Kind)))
		if kind == .One_Byte_No_Seek && len(packed) > 20_000 {
			kind = .Bytes_Reader
		}
		sinks_check(t, "fuzz", format, kind, packed[:])

		for _ in 0..<4 {
			mutated: [dynamic]byte
			defer delete(mutated)
			append(&mutated, ..packed[:])
			d64_mutate(&mutated)
			expected := -1
			if rand.int_max(4) == 0 {
				expected = rand.int_max(len(data) + 2)
			}
			sinks_check(t, "fuzz mutated", format, kind, mutated[:], expected)
		}
		free_all(context.temp_allocator)
	}
}

sinks_pack :: proc(format: deflate.Format, input: []byte, output: ^[dynamic]byte, level: deflate.Deflate_Level) -> compress.Error {
	switch format {
	case .Raw:   return deflate.compress_raw(output, input, level)
	case .Zlib:  return deflate.compress_zlib(output, input, level)
	case .Gzip:  return deflate.compress_gzip(output, input, level)
	case .Raw64: return deflate.compress_raw64(output, input, level)
	}
	return nil
}

sinks_format :: proc(format: Deflate_Format) -> deflate.Format {
	switch format {
	case .Raw:  return .Raw
	case .ZLIB: return .Zlib
	case .GZIP: return .Gzip
	}
	return .Raw
}

sinks_chunk :: proc(output_size: int) -> int {
	floor := output_size / 512
	switch rand.int_max(3) {
	case 0: return 0
	case 1: return max(1 + rand.int_max(64), floor)
	}
	return max(1 + rand.int_max(64 * 1024), floor)
}

sinks_memory_unpack :: proc(format: deflate.Format, kind: Stream_Kind, input: []byte, output: ^[dynamic]byte, expected: int, options: compress.Options, rest: ^[5]byte) -> (err: compress.Error, rest_err: io.Error) {
	input := input
	br: bytes.Reader
	tr: Trickle_Reader
	ctx := stream_test_context(kind, &input, &br, &tr, output)
	defer compress.destroy_context(&ctx)
	switch format {
	case .Raw:   err = deflate.decompress_raw(&ctx, expected, options)
	case .Zlib:  err = deflate.decompress_zlib(&ctx, expected, options)
	case .Gzip:  err = deflate.decompress_gzip(&ctx, expected, options)
	case .Raw64: err = deflate.decompress_raw64(&ctx, expected, options)
	}
	if err == nil {
		rest_err = compress.read_slice(&ctx, rest[:])
	}
	return
}

sinks_unpack :: proc(sink: Sink, format: deflate.Format, kind: Stream_Kind, input: []byte, output: ^[dynamic]byte, expected: int, options: compress.Options, rest: ^[5]byte) -> (err: compress.Error, rest_err: io.Error, bytes_written: i64) {
	input := input
	br: bytes.Reader
	tr: Trickle_Reader
	ctx := stream_test_context(kind, &input, &br, &tr)
	defer compress.destroy_context(&ctx)

	switch sink {
	case .Writer:
		aw := Append_Writer{out = output, fail_at = -1}
		w  := append_writer(&aw)
		switch format {
		case .Raw:   err = deflate.decompress_raw_to_writer(w, &ctx, expected, options)
		case .Zlib:  err = deflate.decompress_zlib_to_writer(w, &ctx, expected, options)
		case .Gzip:  err = deflate.decompress_gzip_to_writer(w, &ctx, expected, options)
		case .Raw64: err = deflate.decompress_raw64_to_writer(w, &ctx, expected, options)
		}

	case .Reader, .Reader_Stream:
		r := new(deflate.Reader)
		defer free(r)
		defer deflate.reader_destroy(r)
		buffer := make([]byte, 70_000)
		defer delete(buffer)
		err = deflate.reader_init(r, &ctx, format, expected, options)
		stream := deflate.reader_to_stream(r)
		for err == nil {
			size := 1 + rand.int_max(16 if rand.int_max(2) == 0 else len(buffer))
			n: int
			if sink == .Reader {
				n, err = deflate.reader_read(r, buffer[:size])
			} else {
				io_err: io.Error
				n, io_err = io.read(stream, buffer[:size])
				err = io_err if io_err == .EOF || io_err == nil else r.err
			}
			append(output, ..buffer[:n])
		}
		if err == io.Error.EOF {
			err = nil
		}
	}
	bytes_written = ctx.bytes_written
	if err == nil {
		rest_err = compress.read_slice(&ctx, rest[:])
	}
	return
}

sinks_check :: proc(t: ^testing.T, label: string, format: deflate.Format, kind: Stream_Kind, input: []byte, expected := -1, options := compress.Options{}) -> (memory_err: compress.Error) {
	want: [dynamic]byte
	defer delete(want)
	want_rest: [5]byte
	want_rest_err: io.Error
	memory_err, want_rest_err = sinks_memory_unpack(format, kind, input, &want, expected, options, &want_rest)

	for sink in Sink {
		opts := options
		if opts.chunk_size == 0 && opts.buffer == nil {
			opts.chunk_size = sinks_chunk(len(want))
		}
		got: [dynamic]byte
		defer delete(got)
		rest: [5]byte
		err, rest_err, bytes_written := sinks_unpack(sink, format, kind, input, &got, expected, opts, &rest)
		if !testing.expectf(t, err == memory_err, "%v, %v, %v, %v, chunk %v: %v, memory gave %v", label, format, kind, sink, opts.chunk_size, err, memory_err) {
			continue
		}
		if err == nil {
			testing.expectf(t, bytes.equal(got[:], want[:]), "%v, %v, %v, %v, chunk %v: output differs, %v vs %v bytes", label, format, kind, sink, opts.chunk_size, len(got), len(want))
			testing.expectf(t, bytes_written == i64(len(got)), "%v, %v, %v, %v, chunk %v: bytes_written %v for %v bytes", label, format, kind, sink, opts.chunk_size, bytes_written, len(got))
			testing.expectf(t, rest == want_rest && rest_err == want_rest_err, "%v, %v, %v, %v, chunk %v: input after the stream %v, %v vs %v, %v", label, format, kind, sink, opts.chunk_size, rest, rest_err, want_rest, want_rest_err)
		}
	}
	return
}
