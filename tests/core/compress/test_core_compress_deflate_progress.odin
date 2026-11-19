package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/deflate"
import "core:fmt"
import "core:io"
import "core:testing"

DEFLATE_PROGRESS_SIZE  :: 300_000
DEFLATE_PROGRESS_CHUNK :: 65536

@(test)
deflate_progress_encode :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xdef1}
	text := lz4_test_lcg_text(&g, DEFLATE_PROGRESS_SIZE)
	defer delete(text)
	blocks := (len(text) + deflate.DEFLATE_BLOCK_MAX - 1) / deflate.DEFLATE_BLOCK_MAX
	log: Ppmd_Progress_Log
	defer delete(log.calls)
	s := new(deflate.Deflate)
	defer free(s)
	s64 := new(deflate.Deflate64)
	defer free(s64)

	for format in deflate.Format {
		for level in ([]deflate.Deflate_Level{.Stored, .Level_1, .Level_6, .Level_10}) {
			label := fmt.tprintf("deflate %v %v memory encode", format, level)
			packed: [dynamic]byte
			defer delete(packed)
			testing.expect_value(t, deflate_progress_pack(&packed, text, format, level, {}), nil)

			got: [dynamic]byte
			defer delete(got)
			testing.expect_value(t, deflate_progress_pack(&got, text, format, level, ppmd_progress_options(&log, {progress_interval = 1})), nil)
			testing.expectf(t, bytes.equal(got[:], packed[:]), "%v: output differs", label)
			testing.expectf(t, len(log.calls) == blocks, "%v: %v calls, want %v", label, len(log.calls), blocks)
			ppmd_progress_expect(t, label, log.calls[:], i64(len(text)), -1, i64(len(text)), i64(len(packed)))
			for c, i in log.calls[:max(len(log.calls) - 1, 0)] {
				testing.expectf(t, c.bytes_in == i64(i + 1) * deflate.DEFLATE_BLOCK_MAX, "%v call %v: %v bytes in", label, i, c.bytes_in)
			}
			codec_progress_expect_last(t, label, log.calls[:], i64(len(text)), i64(len(packed)))

			testing.expect_value(t, deflate_progress_pack(&got, text, format, level, ppmd_progress_options(&log)), nil)
			testing.expectf(t, len(log.calls) == 1, "%v, default interval: %v calls", label, len(log.calls))

			slice := make([]byte, len(packed))
			defer delete(slice)
			n, slice_err := deflate_progress_pack_slice(s, s64, slice, text, format, level, ppmd_progress_options(&log, {progress_interval = 1}))
			testing.expectf(t, slice_err == nil && n == len(packed) && bytes.equal(slice[:n], packed[:]), "%v, slice: %v, %v", label, slice_err, n)
			testing.expectf(t, len(log.calls) == blocks, "%v, slice: %v calls, want %v", label, len(log.calls), blocks)

			log.cancel_at = 2
			testing.expect_value(t, deflate_progress_pack(&got, text, format, level, ppmd_progress_options(&log, {progress_interval = 1})), compress.General_Error.Canceled)
			testing.expect_value(t, len(got), 0)
			testing.expect_value(t, len(log.calls), 2)
			_, slice_err = deflate_progress_pack_slice(s, s64, slice, text, format, level, ppmd_progress_options(&log, {progress_interval = 1}))
			testing.expect_value(t, slice_err, compress.General_Error.Canceled)
			log.cancel_at = 0
		}

		got: [dynamic]byte
		defer delete(got)
		buffer := make([]byte, 1 << 20)
		defer delete(buffer)
		testing.expect_value(t, deflate_progress_pack(&got, text, format, .Level_1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		testing.expect_value(t, deflate_progress_pack(&got, text, format, .Level_1, {max_output_size = -1}), compress.General_Error.Incompatible_Options)
		testing.expect_value(t, deflate_progress_pack(&got, text, format, .Level_1, {max_memory = 1000}), compress.General_Error.Memory_Limit_Exceeded)
		_, slice_err := deflate_progress_pack_slice(s, s64, buffer, text, format, .Level_1, {progress_interval = -1})
		testing.expect_value(t, slice_err, compress.General_Error.Incompatible_Options)
		_, slice_err = deflate_progress_pack_slice(s, s64, buffer, text, format, .Level_1, {max_memory = -1})
		testing.expect_value(t, slice_err, compress.General_Error.Incompatible_Options)
	}

	for format in deflate.Format {
		label := fmt.tprintf("deflate %v writer encode", format)
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, deflate_progress_pack(&packed, text, format, .Level_6, {}), nil)

		got: [dynamic]byte
		defer delete(got)
		testing.expect_value(t, deflate_progress_writer_pack(text, format, ppmd_progress_options(&log), &got), nil)
		testing.expectf(t, bytes.equal(got[:], packed[:]), "%v: output differs", label)
		testing.expectf(t, len(log.calls) == blocks, "%v: %v calls, want %v", label, len(log.calls), blocks)
		ppmd_progress_expect(t, label, log.calls[:], -1, -1, i64(len(text)), i64(len(packed)))
		for c, i in log.calls[:max(len(log.calls) - 1, 0)] {
			testing.expectf(t, c.bytes_in == i64(i + 1) * deflate.DEFLATE_BLOCK_MAX, "%v call %v: %v bytes in", label, i, c.bytes_in)
		}
		codec_progress_expect_last(t, label, log.calls[:], i64(len(text)), i64(len(packed)))

		clear(&got)
		log.cancel_at = 2
		testing.expect_value(t, deflate_progress_writer_pack(text, format, ppmd_progress_options(&log), &got), compress.General_Error.Canceled)
		testing.expect_value(t, len(log.calls), 2)
		if len(log.calls) == 2 {
			testing.expect_value(t, i64(len(got)), log.calls[1].bytes_out)
		}
		log.cancel_at = 0

		dw: deflate.Writer
		aw := Append_Writer{out = &got, fail_at = -1}
		testing.expect_value(t, deflate.writer_init(&dw, append_writer(&aw), format, .Level_1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		deflate.writer_destroy(&dw)
	}
}

@(test)
deflate_progress_decode :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xdef2}
	text := lz4_test_lcg_text(&g, DEFLATE_PROGRESS_SIZE)
	defer delete(text)
	blocks := (len(text) + deflate.DEFLATE_BLOCK_MAX - 1) / deflate.DEFLATE_BLOCK_MAX
	log: Ppmd_Progress_Log
	defer delete(log.calls)
	first: [dynamic]compress.Progress
	defer delete(first)

	for format in deflate.Format {
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, deflate_progress_pack(&packed, text, format, .Level_6, {}), nil)

		clear(&first)
		for kind in Stream_Kind {
			input := packed[:]
			output: [dynamic]byte
			defer delete(output)
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr, &output)
			err := deflate_progress_unpack(&ctx, format, len(text), ppmd_progress_options(&log, {progress_interval = 1}))
			compress.destroy_context(&ctx)
			label := fmt.tprintf("inflate %v memory decode %v", format, kind)
			testing.expectf(t, err == nil && bytes.equal(output[:], text), "%v: %v", label, err)
			testing.expectf(t, len(log.calls) == blocks, "%v: %v calls, want %v", label, len(log.calls), blocks)
			ppmd_progress_expect(t, label, log.calls[:], codec_progress_input_total(kind, len(packed)), i64(len(text)), i64(len(packed)), i64(len(text)))
			codec_progress_expect_last(t, label, log.calls[:], i64(len(packed)), i64(len(text)))
			codec_progress_same(t, label, &first, log.calls[:])
		}

		{
			label := fmt.tprintf("inflate %v memory decode", format)
			output: [dynamic]byte
			defer delete(output)
			input := packed[:]
			ctx := compress.init_context(&input, &output)
			testing.expect_value(t, deflate_progress_unpack(&ctx, format, len(text), ppmd_progress_options(&log)), nil)
			testing.expectf(t, len(log.calls) == 0, "%v, default interval: %v calls", label, len(log.calls))

			log.cancel_at = 2
			input = packed[:]
			ctx   = compress.init_context(&input, &output)
			testing.expect_value(t, deflate_progress_unpack(&ctx, format, len(text), ppmd_progress_options(&log, {progress_interval = 1})), compress.General_Error.Canceled)
			testing.expect_value(t, len(log.calls), 2)
			if len(log.calls) == 2 {
				testing.expect_value(t, i64(len(output)), log.calls[1].bytes_out)
				testing.expect(t, bytes.equal(output[:], text[:len(output)]))
			}
			log.cancel_at = 0

			input = packed[:]
			ctx   = compress.init_context(&input, &output)
			testing.expect_value(t, deflate_progress_unpack(&ctx, format, len(text), {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		}
		free_all(context.temp_allocator)
	}
}

@(test)
deflate_progress_stream_decode :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xdef3}
	text := lz4_test_lcg_text(&g, DEFLATE_PROGRESS_SIZE)
	defer delete(text)
	log: Ppmd_Progress_Log
	defer delete(log.calls)
	first: [dynamic]compress.Progress
	defer delete(first)
	step := i64(DEFLATE_PROGRESS_CHUNK + deflate.DEFLATE64_WINDOW_SIZE + deflate.DEFLATE64_MATCH_MAX + deflate.INFLATE_COPY_MARGIN)

	for format in deflate.Format {
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, deflate_progress_pack(&packed, text, format, .Level_6, {}), nil)
		source: [dynamic]byte
		defer delete(source)
		want: [dynamic]byte
		defer delete(want)
		copies := 2 if format == .Gzip else 1
		for _ in 0..<copies {
			append(&source, ..packed[:])
			append(&want, ..text)
		}

		clear(&first)
		for kind in Stream_Kind {
			input := source[:]
			output: [dynamic]byte
			defer delete(output)
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr)
			aw  := Append_Writer{out = &output, fail_at = -1}
			err := deflate_progress_to_writer(append_writer(&aw), &ctx, format, -1, ppmd_progress_options(&log, {chunk_size = DEFLATE_PROGRESS_CHUNK}))
			compress.destroy_context(&ctx)
			label := fmt.tprintf("inflate %v writer decode %v", format, kind)
			testing.expectf(t, err == nil && bytes.equal(output[:], want[:]), "%v: %v", label, err)
			testing.expectf(t, i64(len(log.calls)) >= i64(len(want)) / step, "%v: %v calls", label, len(log.calls))
			ppmd_progress_expect(t, label, log.calls[:], codec_progress_input_total(kind, len(source)), -1, i64(len(source)), i64(len(want)))
			codec_progress_expect_steps(t, label, log.calls[:], step)
			codec_progress_expect_last(t, label, log.calls[:], i64(len(source)), i64(len(want)))
			codec_progress_same(t, label, &first, log.calls[:])
		}
		free_all(context.temp_allocator)

		{
			label := fmt.tprintf("inflate %v writer decode", format)
			output: [dynamic]byte
			defer delete(output)
			data := packed[:]
			ctx  := compress.init_context(&data)
			aw   := Append_Writer{out = &output, fail_at = -1}
			log.cancel_at = 2
			testing.expect_value(t, deflate_progress_to_writer(append_writer(&aw), &ctx, format, len(text), ppmd_progress_options(&log, {chunk_size = DEFLATE_PROGRESS_CHUNK})), compress.General_Error.Canceled)
			testing.expect_value(t, len(log.calls), 2)
			if len(log.calls) == 2 {
				testing.expect_value(t, i64(len(output)), log.calls[1].bytes_out)
				testing.expectf(t, log.calls[1].total_out == i64(len(text)), "%v, total out: %v", label, log.calls[1])
			}
			log.cancel_at = 0

			data = packed[:]
			ctx  = compress.init_context(&data)
			testing.expect_value(t, deflate_progress_to_writer(append_writer(&aw), &ctx, format, -1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		}

		{
			label := fmt.tprintf("inflate %v reader", format)
			data := packed[:]
			ctx  := compress.init_context(&data)
			r: deflate.Reader
			defer deflate.reader_destroy(&r)
			testing.expect_value(t, deflate.reader_init(&r, &ctx, format, -1, ppmd_progress_options(&log)), nil)
			total := codec_progress_drain(t, deflate.reader_to_stream(&r))
			testing.expect_value(t, total, len(text))
			testing.expect_value(t, len(log.calls), (len(text) + 2999) / 3000)
			ppmd_progress_expect(t, label, log.calls[:], i64(len(packed)), -1, i64(len(packed)), i64(len(text)))
			for c, i in log.calls {
				testing.expectf(t, c.bytes_out == min(i64(i + 1) * 3000, i64(len(text))), "%v call %v: %v bytes out", label, i, c.bytes_out)
			}
			codec_progress_expect_last(t, label, log.calls[:], i64(len(packed)), i64(len(text)))

			deflate.reader_destroy(&r)
			log.cancel_at = 2
			data = packed[:]
			ctx  = compress.init_context(&data)
			testing.expect_value(t, deflate.reader_init(&r, &ctx, format, -1, ppmd_progress_options(&log)), nil)
			buffer: [3000]byte
			n1, err1 := deflate.reader_read(&r, buffer[:])
			n2, err2 := deflate.reader_read(&r, buffer[:])
			n3, err3 := deflate.reader_read(&r, buffer[:])
			testing.expectf(t, n1 == 3000 && err1 == nil && n2 == 3000 && err2 == nil && n3 == 0 && err3 == compress.General_Error.Canceled, "%v, cancel: %v %v, %v %v, %v %v", label, n1, err1, n2, err2, n3, err3)
			log.cancel_at = 0

			deflate.reader_destroy(&r)
			data = packed[:]
			ctx  = compress.init_context(&data)
			testing.expect_value(t, deflate.reader_init(&r, &ctx, format, -1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		}
	}
}

@(test)
deflate_output_limit :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xdef4}
	text := lz4_test_lcg_text(&g, 150_000)
	defer delete(text)
	random := lz4_test_lcg_bytes(&g, 140_000)
	defer delete(random)
	mixed := make([]byte, 70_000 + 80_000)
	defer delete(mixed)
	copy(mixed, random[:70_000])
	copy(mixed[70_000:], text[:80_000])
	s := new(deflate.Deflate)
	defer free(s)
	s64 := new(deflate.Deflate64)
	defer free(s64)

	all_levels := []deflate.Deflate_Level{.Stored, .Level_1, .Level_6, .Level_10}
	some_levels := []deflate.Deflate_Level{.Level_1, .Level_6}
	for input, i in ([][]byte{text, random, mixed, text[:20], nil}) {
		for format in deflate.Format {
			levels := all_levels if format == .Raw || format == .Raw64 else some_levels
			for level in levels {
				codec_limit_deflate(t, s, s64, fmt.tprintf("deflate %v input %v, level %v", format, i, level), input, format, level)
			}
		}
	}
	free_all(context.temp_allocator)

	got: [dynamic]byte
	defer delete(got)
	testing.expect_value(t, deflate.compress_raw(&got, text, .Level_6, {max_output_size = len(text) - 1}), nil)
	testing.expect_value(t, deflate.compress_raw(&got, random, .Level_6, {max_output_size = len(random) - 1}), compress.General_Error.Output_Too_Short)
	testing.expect_value(t, len(got), 0)
	testing.expect_value(t, deflate.compress_raw(&got, text, .Level_6, {max_output_size = 100, max_memory = size_of(deflate.Deflate) + 1000}), compress.General_Error.Memory_Limit_Exceeded)
	testing.expect_value(t, deflate.compress_raw(&got, text, .Level_6, {max_memory = size_of(deflate.Deflate) - 1}), compress.General_Error.Memory_Limit_Exceeded)
	buffer := make([]byte, 100)
	defer delete(buffer)
	_, slice_err := deflate.compress_raw(s, buffer, text, .Level_6, {max_memory = 1000})
	testing.expect_value(t, slice_err, compress.General_Error.Memory_Limit_Exceeded)
}

codec_limit_deflate :: proc(t: ^testing.T, s: ^deflate.Deflate, s64: ^deflate.Deflate64, label: string, input: []byte, format: deflate.Format, level: deflate.Deflate_Level) {
	packed: [dynamic]byte
	defer delete(packed)
	if !testing.expect_value(t, deflate_progress_pack(&packed, input, format, level, {}), nil) {
		return
	}
	n := len(packed)
	buffer := make([]byte, n + 64)
	defer delete(buffer)
	for step in CODEC_LIMIT_STEPS {
		limit := n - step
		if limit < 1 {
			continue
		}
		codec_limit_fill(buffer)
		written, err := deflate_progress_pack_slice(s, s64, buffer, input, format, level, {max_output_size = limit})
		codec_limit_check(t, label, packed[:], buffer, limit, written, err)
	}
	written, err := deflate_progress_pack_slice(s, s64, buffer[:n], input, format, level, {})
	codec_limit_check(t, label, packed[:], buffer[:n], n, written, err)
	written, err = deflate_progress_pack_slice(s, s64, buffer[:n - 1], input, format, level, {})
	codec_limit_check(t, label, packed[:], buffer[:n - 1], n - 1, written, err)

	log: Ppmd_Progress_Log
	defer delete(log.calls)
	codec_limit_fill(buffer)
	written, err = deflate_progress_pack_slice(s, s64, buffer, input, format, level, ppmd_progress_options(&log, {max_output_size = n, progress_interval = 4096}))
	codec_limit_check(t, label, packed[:], buffer, n, written, err)
	codec_progress_expect_last(t, label, log.calls[:], i64(len(input)), i64(n))

	got: [dynamic]byte
	defer delete(got)
	err = deflate_progress_pack(&got, input, format, level, {max_output_size = n})
	testing.expectf(t, err == nil && bytes.equal(got[:], packed[:]), "%v: dynamic at the limit: %v", label, err)
	err = deflate_progress_pack(&got, input, format, level, {max_output_size = n - 1})
	testing.expectf(t, err == compress.General_Error.Output_Too_Short && len(got) == 0, "%v: dynamic below the limit: %v", label, err)
}

deflate_progress_pack :: proc(output: ^[dynamic]byte, input: []byte, format: deflate.Format, level: deflate.Deflate_Level, options: compress.Options) -> (err: compress.Error) {
	switch format {
	case .Raw:   return deflate.compress_raw(output, input, level, options)
	case .Zlib:  return deflate.compress_zlib(output, input, level, options)
	case .Gzip:  return deflate.compress_gzip(output, input, level, options)
	case .Raw64: return deflate.compress_raw64(output, input, level, options)
	}
	return nil
}

deflate_progress_pack_slice :: proc(s: ^deflate.Deflate, s64: ^deflate.Deflate64, output, input: []byte, format: deflate.Format, level: deflate.Deflate_Level, options: compress.Options) -> (written: int, err: compress.Error) {
	switch format {
	case .Raw:   return deflate.compress_raw(s, output, input, level, options)
	case .Zlib:  return deflate.compress_zlib(s, output, input, level, options)
	case .Gzip:  return deflate.compress_gzip(s, output, input, level, options)
	case .Raw64: return deflate.compress_raw64(s64, output, input, level, options)
	}
	return
}

deflate_progress_unpack :: proc(ctx: ^compress.Context, format: deflate.Format, expected: int, options: compress.Options) -> (err: compress.Error) {
	switch format {
	case .Raw:   return deflate.decompress_raw(ctx, expected, options)
	case .Zlib:  return deflate.decompress_zlib(ctx, expected, options)
	case .Gzip:  return deflate.decompress_gzip(ctx, expected, options)
	case .Raw64: return deflate.decompress_raw64(ctx, expected, options)
	}
	return nil
}

deflate_progress_to_writer :: proc(w: io.Writer, ctx: ^compress.Context, format: deflate.Format, expected: int, options: compress.Options) -> (err: compress.Error) {
	switch format {
	case .Raw:   return deflate.decompress_raw_to_writer(w, ctx, expected, options)
	case .Zlib:  return deflate.decompress_zlib_to_writer(w, ctx, expected, options)
	case .Gzip:  return deflate.decompress_gzip_to_writer(w, ctx, expected, options)
	case .Raw64: return deflate.decompress_raw64_to_writer(w, ctx, expected, options)
	}
	return nil
}

deflate_progress_writer_pack :: proc(input: []byte, format: deflate.Format, options: compress.Options, output: ^[dynamic]byte) -> (err: compress.Error) {
	aw := Append_Writer{out = output, fail_at = -1}
	dw: deflate.Writer
	defer deflate.writer_destroy(&dw)
	deflate.writer_init(&dw, append_writer(&aw), format, .Level_6, options) or_return
	for pos := 0; pos < len(input); pos += 3000 {
		_ = deflate.writer_write(&dw, input[pos:min(pos + 3000, len(input))]) or_return
	}
	return deflate.writer_finish(&dw)
}
