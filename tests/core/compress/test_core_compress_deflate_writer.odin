package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/deflate"
import "core:io"
import "core:math/rand"
import "core:testing"

DEFLATE_WRITER_FORMATS :: [?]deflate.Format{.Raw, .Zlib, .Gzip, .Raw64}
DEFLATE_WRITER_SYNC    :: [4]byte{0x00, 0x00, 0xff, 0xff}

@(test)
deflate_writer_identity :: proc(t: ^testing.T) {
	match := stream_match_data()
	defer delete(match)
	g := Lz4_Test_Lcg{state = 0xdef1}
	text := lz4_test_lcg_text(&g, 300_000)
	defer delete(text)
	random := lz4_test_lcg_bytes(&g, 150_000)
	defer delete(random)
	runs := codec_runs_data(400_000)
	defer delete(runs)

	inputs: [dynamic][]byte
	defer delete(inputs)
	append(&inputs, []byte{}, []byte{7}, transmute([]byte)context_test_data, match, text, random, runs)
	for n in ([]int{4, 5, 65534, 65535, 65536, 65539, 65540, 65541, 131070, 131075, 131080, 196605}) {
		append(&inputs, match[:n])
	}
	for input in inputs {
		for format in DEFLATE_WRITER_FORMATS {
			framed := format == .Zlib || format == .Gzip
			if framed && len(input) > 70_000 {
				continue
			}
			for l in 0..=10 {
				level := deflate.Deflate_Level(l)
				if framed && level != .Stored && level != .Level_1 && level != .Level_6 && level != .Level_10 {
					continue
				}
				if len(input) > 200_000 {
					if level == .Stored || level == .Level_1 || level == .Level_2 || level == .Level_6 {
						deflate_writer_check(t, "identity", format, input, level, .Random, {chunk_size = 1})
					}
					continue
				}
				if len(input) > 70_000 {
					if level != .Level_4 && level != .Level_5 && level != .Level_7 && level != .Level_8 {
						deflate_writer_check(t, "identity", format, input, level, .Random, {chunk_size = 1})
						deflate_writer_check(t, "identity", format, input, level, .Edges, {chunk_size = 1})
					}
					continue
				}
				deflate_writer_check(t, "identity", format, input, level, .Random, {})
				deflate_writer_check(t, "identity", format, input, level, .Edges, {chunk_size = 1})
				deflate_writer_check(t, "identity", format, input, level, .Bytes, {})
				if len(input) < 1000 {
					deflate_writer_check(t, "identity", format, input, level, .Whole, {})
				}
			}
		}
	}
	free_all(context.temp_allocator)
}

@(test)
deflate_writer_large :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xb16}
	text := lz4_test_lcg_text(&g, 3 << 20 if !SLIM_TESTS else 1 << 20)
	defer delete(text)
	mixed: [dynamic]byte
	defer delete(mixed)
	d64_test_data(3, 2 << 20 if !SLIM_TESTS else 600_000, &mixed)

	for input in ([][]byte{text, mixed[:]}) {
		for format in ([]deflate.Format{.Raw, .Raw64}) {
			for level in ([]deflate.Deflate_Level{.Stored, .Level_1, .Level_2, .Level_6}) {
				deflate_writer_check(t, "large", format, input, level, .Random, {chunk_size = 1})
				deflate_writer_check(t, "large", format, input, level, .Edges, {chunk_size = 70_000})
			}
			deflate_writer_check(t, "large", format, input[:min(len(input), 600_000)], .Level_10, .Random, {chunk_size = 1})
		}
	}
}

@(test)
deflate_writer_flush_round_trip :: proc(t: ^testing.T) {
	match := stream_match_data()
	defer delete(match)
	g := Lz4_Test_Lcg{state = 0xf105}
	text := lz4_test_lcg_text(&g, 400_000 if !SLIM_TESTS else 150_000)
	defer delete(text)

	for input in ([][]byte{{}, {1, 2, 3}, match, text}) {
		for format in DEFLATE_WRITER_FORMATS {
			for level in ([]deflate.Deflate_Level{.Stored, .Level_1, .Level_2, .Level_6, .Level_9, .Level_10}) {
				for chunk in ([]int{0, 1}) {
					packed: [dynamic]byte
					defer delete(packed)
					aw := Append_Writer{out = &packed, fail_at = -1}
					err := deflate_writer_pack(append_writer(&aw), format, input, level, .Random, {chunk_size = chunk}, true)
					testing.expectf(t, err == nil, "%v, level %v, %v bytes: pack gave %v", format, level, len(input), err)

					output: [dynamic]byte
					defer delete(output)
					unpack_err := deflate_writer_unpack(format, packed[:], &output)
					testing.expectf(t, unpack_err == nil && bytes.equal(output[:], input), "%v, level %v, %v bytes: %v, %v of %v bytes", format, level, len(input), unpack_err, len(output), len(input))
				}
			}
		}
	}

	for format in DEFLATE_WRITER_FORMATS {
		packed: [dynamic]byte
		defer delete(packed)
		aw := Append_Writer{out = &packed, fail_at = -1}
		dw: deflate.Writer
		defer deflate.writer_destroy(&dw)
		testing.expect_value(t, deflate.writer_init(&dw, append_writer(&aw), format), nil)
		testing.expect_value(t, deflate.writer_flush(&dw), nil)
		testing.expectf(t, deflate_writer_synced(packed[:]), "%v: empty flush gave %v", format, packed[:])
		_, err := deflate.writer_write(&dw, match[:1000])
		testing.expect_value(t, err, nil)
		testing.expect_value(t, deflate.writer_flush(&dw), nil)
		testing.expectf(t, deflate_writer_synced(packed[:]), "%v: flush did not end on a sync marker", format)
		_, err = deflate.writer_write(&dw, match[1000:])
		testing.expect_value(t, err, nil)
		testing.expect_value(t, deflate.writer_flush(&dw), nil)
		testing.expect_value(t, deflate.writer_finish(&dw), nil)

		output: [dynamic]byte
		defer delete(output)
		unpack_err := deflate_writer_unpack(format, packed[:], &output)
		testing.expectf(t, unpack_err == nil && bytes.equal(output[:], match), "%v: %v, %v of %v bytes", format, unpack_err, len(output), len(match))
	}
}

@(test)
deflate_writer_failures :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for format in DEFLATE_WRITER_FORMATS {
		want: [dynamic]byte
		defer delete(want)
		testing.expect_value(t, deflate_writer_oneshot(format, data, .Level_1, &want), nil)

		for fail_at in ([]int{0, 1, 3, 10_000, len(want) - 1}) {
			output: [dynamic]byte
			defer delete(output)
			aw := Append_Writer{out = &output, fail_at = fail_at}
			err := deflate_writer_pack(append_writer(&aw), format, data, .Level_1, .Random, {})
			testing.expectf(t, err == io.Error.Short_Write, "%v, fail at %v: %v", format, fail_at, err)
			testing.expectf(t, bytes.equal(output[:], want[:fail_at]), "%v, fail at %v: %v bytes", format, fail_at, len(output))
		}

		for options in ([]compress.Options{{max_memory = -1}, {chunk_size = -1}, {max_output_size = -1}, {buffer = make([]byte, 1000, context.temp_allocator)}}) {
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			dw: deflate.Writer
			err := deflate.writer_init(&dw, append_writer(&aw), format, .Level_1, options)
			deflate.writer_destroy(&dw)
			testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v, %v: %v", format, options, err)
		}

		{
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			dw: deflate.Writer
			err := deflate.writer_init(&dw, append_writer(&aw), format, .Level_1, {max_memory = 500_000})
			deflate.writer_destroy(&dw)
			testing.expectf(t, err == compress.General_Error.Memory_Limit_Exceeded, "%v: %v", format, err)
		}

		{
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			dw: deflate.Writer
			defer deflate.writer_destroy(&dw)
			testing.expect_value(t, deflate.writer_init(&dw, append_writer(&aw), format, .Level_6), nil)
			_, err := deflate.writer_write(&dw, data[:100])
			testing.expect_value(t, err, nil)
			testing.expect_value(t, deflate.writer_finish(&dw), nil)
			testing.expect_value(t, deflate.writer_finish(&dw), nil)
			n, again := deflate.writer_write(&dw, data[:1])
			testing.expectf(t, n == 0 && again == io.Error.Closed, "%v: write after finish gave %v, %v", format, n, again)
			testing.expect_value(t, deflate.writer_flush(&dw), compress.Error(io.Error.Closed))
		}
	}

	{
		sink: [dynamic]byte
		defer delete(sink)
		aw := Append_Writer{out = &sink, fail_at = -1}
		dw: deflate.Writer
		testing.expect_value(t, deflate.writer_init(&dw, append_writer(&aw), deflate.Format(9)), compress.Error(compress.General_Error.Incompatible_Options))
		deflate.writer_destroy(&dw)
	}
	free_all(context.temp_allocator)
}

@(test)
deflate_writer_buffer :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xb0f}
	text := lz4_test_lcg_text(&g, 700_000)
	defer delete(text)

	for format in DEFLATE_WRITER_FORMATS {
		history := deflate.DEFLATE64_WINDOW_SIZE if format == .Raw64 else deflate.DEFLATE_WINDOW_SIZE
		size    := 2 * history + deflate.DEFLATE_BLOCK_MAX + deflate.DEFLATE_LOOKAHEAD
		buffer  := make([]byte, size)
		defer delete(buffer)
		for level in ([]deflate.Deflate_Level{.Stored, .Level_1, .Level_6, .Level_10}) {
			want: [dynamic]byte
			defer delete(want)
			testing.expect_value(t, deflate_writer_oneshot(format, text, level, &want), nil)

			output: [dynamic]byte
			defer delete(output)
			aw := Append_Writer{out = &output, fail_at = -1}
			dw: deflate.Writer
			testing.expect_value(t, deflate.writer_init(&dw, append_writer(&aw), format, level, {buffer = buffer}), nil)
			testing.expect_value(t, raw_data(dw.window), raw_data(buffer))
			testing.expect_value(t, len(dw.window), size)
			rest := text
			for len(rest) > 0 {
				k := min(len(rest), 1 + rand.int_max(100_000))
				_, err := deflate.writer_write(&dw, rest[:k])
				testing.expect_value(t, err, nil)
				rest = rest[k:]
			}
			testing.expect_value(t, deflate.writer_finish(&dw), nil)
			deflate.writer_destroy(&dw)
			testing.expectf(t, bytes.equal(output[:], want[:]), "%v, level %v: %v vs %v bytes", format, level, len(output), len(want))
		}
	}
}

@(test)
deflate_writer_as_stream :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for format in DEFLATE_WRITER_FORMATS {
		want: [dynamic]byte
		defer delete(want)
		testing.expect_value(t, deflate_writer_oneshot(format, data, .Level_5, &want), nil)

		output: [dynamic]byte
		defer delete(output)
		aw := Append_Writer{out = &output, fail_at = -1}
		dw := new(deflate.Writer)
		defer free(dw)
		testing.expect_value(t, deflate.writer_init(dw, append_writer(&aw), format, .Level_5), nil)
		stream := deflate.writer_to_stream(dw)
		testing.expect_value(t, io.query(stream), io.Stream_Mode_Set{.Write, .Flush, .Close, .Destroy, .Query})
		rest := data
		for len(rest) > 0 {
			k := min(len(rest), 1 + rand.int_max(50_000))
			n, err := io.write(stream, rest[:k])
			testing.expectf(t, n == k && err == nil, "%v: write gave %v, %v", format, n, err)
			rest = rest[k:]
		}
		testing.expect_value(t, io.close(stream), nil)
		testing.expectf(t, bytes.equal(output[:], want[:]), "%v: %v vs %v bytes", format, len(output), len(want))
		io.destroy(stream)

		flushed: [dynamic]byte
		defer delete(flushed)
		fw := Append_Writer{out = &flushed, fail_at = -1}
		testing.expect_value(t, deflate.writer_init(dw, append_writer(&fw), format, .Level_5), nil)
		stream = deflate.writer_to_stream(dw)
		_, err := io.write(stream, data[:5000])
		testing.expect_value(t, err, nil)
		testing.expect_value(t, io.flush(stream), nil)
		testing.expectf(t, deflate_writer_synced(flushed[:]), "%v: stream flush did not end on a sync marker", format)
		_, err = io.write(stream, data[5000:])
		testing.expect_value(t, err, nil)
		testing.expect_value(t, io.close(stream), nil)
		io.destroy(stream)

		unpacked: [dynamic]byte
		defer delete(unpacked)
		unpack_err := deflate_writer_unpack(format, flushed[:], &unpacked)
		testing.expectf(t, unpack_err == nil && bytes.equal(unpacked[:], data), "%v: %v, %v of %v bytes", format, unpack_err, len(unpacked), len(data))
	}
}

deflate_writer_synced :: proc(packed: []byte) -> bool {
	marker := DEFLATE_WRITER_SYNC
	return len(packed) >= 4 && bytes.equal(packed[len(packed) - 4:], marker[:])
}

deflate_writer_sizes :: proc(pattern: Write_Pattern, n: int) -> int {
	if pattern == .Edges {
		edges := [?]int{65535, 65539, 65540, 65541, 1, 0, 4, 5, 131070, 32768, 65536, 3, 196605}
		return edges[rand.int_max(len(edges))]
	}
	return codec_pattern_sizes(pattern, n)
}

deflate_writer_oneshot :: proc(format: deflate.Format, data: []byte, level: deflate.Deflate_Level, output: ^[dynamic]byte) -> compress.Error {
	switch format {
	case .Raw:   return deflate.compress_raw(output, data, level)
	case .Zlib:  return deflate.compress_zlib(output, data, level)
	case .Gzip:  return deflate.compress_gzip(output, data, level)
	case .Raw64: return deflate.compress_raw64(output, data, level)
	}
	return nil
}

deflate_writer_unpack :: proc(format: deflate.Format, input: []byte, output: ^[dynamic]byte) -> compress.Error {
	switch format {
	case .Raw:   return deflate.decompress_raw_from_bytes(output, input)
	case .Zlib:  return deflate.decompress_zlib_from_bytes(output, input)
	case .Gzip:  return deflate.decompress_gzip_from_bytes(output, input)
	case .Raw64: return deflate.decompress_raw64_from_bytes(output, input)
	}
	return nil
}

deflate_writer_pack :: proc(w: io.Writer, format: deflate.Format, data: []byte, level: deflate.Deflate_Level, pattern: Write_Pattern, options: compress.Options, flushes := false) -> (err: compress.Error) {
	dw := new(deflate.Writer)
	defer free(dw)
	err = deflate.writer_init(dw, w, format, level, options)
	defer deflate.writer_destroy(dw)
	if err != nil {
		return
	}
	rest := data
	for len(rest) > 0 {
		k := min(deflate_writer_sizes(pattern, len(rest)), len(rest))
		n: int
		n, err = deflate.writer_write(dw, rest[:k])
		if err != nil {
			return
		}
		if n != k {
			return compress.General_Error.Output_Too_Short
		}
		rest = rest[k:]
		if flushes && rand.int_max(4) == 0 {
			deflate.writer_flush(dw) or_return
		}
	}
	return deflate.writer_finish(dw)
}

deflate_writer_check :: proc(t: ^testing.T, label: string, format: deflate.Format, data: []byte, level: deflate.Deflate_Level, pattern: Write_Pattern, options: compress.Options) {
	want: [dynamic]byte
	defer delete(want)
	testing.expect_value(t, deflate_writer_oneshot(format, data, level, &want), nil)

	got: [dynamic]byte
	defer delete(got)
	aw := Append_Writer{out = &got, fail_at = -1}
	err := deflate_writer_pack(append_writer(&aw), format, data, level, pattern, options)
	testing.expectf(t, err == nil, "%v, %v, %v bytes, %v, level %v, chunk %v: %v", label, format, len(data), pattern, level, options.chunk_size, err)
	testing.expectf(t, bytes.equal(got[:], want[:]), "%v, %v, %v bytes, %v, level %v, chunk %v: output differs, %v vs %v bytes", label, format, len(data), pattern, level, options.chunk_size, len(got), len(want))
}
