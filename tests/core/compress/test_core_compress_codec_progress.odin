package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/lz4"
import "core:fmt"
import "core:io"
import "core:testing"

CODEC_PROGRESS_BZIP2_BLOCK :: 100_000 - 19
CODEC_PROGRESS_BZIP2_SIZE  :: 950_000
CODEC_PROGRESS_LZ4_SIZE    :: 300_000

@(test)
bzip2_progress_encode :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xb21b}
	text := lz4_test_lcg_text(&g, CODEC_PROGRESS_BZIP2_SIZE)
	defer delete(text)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, bzip2.compress(&packed, text, .Level_1), nil)
	blocks := (len(text) + CODEC_PROGRESS_BZIP2_BLOCK - 1) / CODEC_PROGRESS_BZIP2_BLOCK
	log: Ppmd_Progress_Log
	defer delete(log.calls)

	{
		got: [dynamic]byte
		defer delete(got)
		testing.expect_value(t, bzip2.compress(&got, text, .Level_1, ppmd_progress_options(&log, {progress_interval = 1})), nil)
		testing.expect(t, bytes.equal(got[:], packed[:]))
		testing.expect_value(t, len(log.calls), blocks)
		ppmd_progress_expect(t, "bzip2 memory encode", log.calls[:], i64(len(text)), -1, i64(len(text)), i64(len(packed)))
		for c, i in log.calls[:max(len(log.calls) - 1, 0)] {
			low := i64(i + 1) * CODEC_PROGRESS_BZIP2_BLOCK
			testing.expectf(t, c.bytes_in >= low && c.bytes_in <= low + i64(3 * (i + 2)), "bzip2 memory encode call %v: %v bytes in", i, c.bytes_in)
		}
		codec_progress_expect_last(t, "bzip2 memory encode", log.calls[:], i64(len(text)), i64(len(packed)))

		testing.expect_value(t, bzip2.compress(&got, text, .Level_1, ppmd_progress_options(&log)), nil)
		testing.expect_value(t, len(log.calls), 1)

		state := new(bzip2.BZip2)
		defer free(state)
		slice := make([]byte, bzip2.compress_bound(len(text)))
		defer delete(slice)
		n, slice_err := bzip2.compress(state, slice, text, .Level_1, ppmd_progress_options(&log, {progress_interval = 1}))
		testing.expectf(t, slice_err == nil && n == len(packed) && bytes.equal(slice[:n], packed[:]), "bzip2 slice encode: %v, %v", slice_err, n)
		testing.expect_value(t, len(log.calls), blocks)

		log.cancel_at = 2
		testing.expect_value(t, bzip2.compress(&got, text, .Level_1, ppmd_progress_options(&log, {progress_interval = 1})), compress.General_Error.Canceled)
		testing.expect_value(t, len(got), 0)
		testing.expect_value(t, len(log.calls), 2)
		_, slice_err = bzip2.compress(state, slice, text, .Level_1, ppmd_progress_options(&log, {progress_interval = 1}))
		testing.expect_value(t, slice_err, compress.General_Error.Canceled)
		log.cancel_at = 0

		testing.expect_value(t, bzip2.compress(&got, text, .Level_1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		testing.expect_value(t, bzip2.compress(&got, text, .Level_1, {max_output_size = len(packed) - 1}), compress.General_Error.Output_Too_Short)
		testing.expect_value(t, bzip2.compress(&got, text, .Level_1, ppmd_progress_options(&log, {max_output_size = len(packed), progress_interval = 1})), nil)
		testing.expect(t, bytes.equal(got[:], packed[:]))
		testing.expect_value(t, len(log.calls), blocks)
		testing.expect_value(t, bzip2.compress(&got, text, .Level_1, {max_memory = size_of(bzip2.BZip2) - 1}), compress.General_Error.Memory_Limit_Exceeded)
		_, slice_err = bzip2.compress(state, slice, text, .Level_1, {max_output_size = len(packed) - 1})
		testing.expect_value(t, slice_err, compress.General_Error.Output_Too_Short)
		_, slice_err = bzip2.compress(state, slice, text, .Level_1, {progress_interval = -1})
		testing.expect_value(t, slice_err, compress.General_Error.Incompatible_Options)
	}

	{
		got: [dynamic]byte
		defer delete(got)
		testing.expect_value(t, codec_progress_bzip2_pack(text, ppmd_progress_options(&log), &got), nil)
		testing.expect(t, bytes.equal(got[:], packed[:]))
		testing.expect_value(t, len(log.calls), blocks)
		ppmd_progress_expect(t, "bzip2 writer encode", log.calls[:], -1, -1, i64(len(text)), i64(len(packed)))
		codec_progress_expect_last(t, "bzip2 writer encode", log.calls[:], i64(len(text)), i64(len(packed)))

		clear(&got)
		log.cancel_at = 2
		testing.expect_value(t, codec_progress_bzip2_pack(text, ppmd_progress_options(&log), &got), compress.General_Error.Canceled)
		testing.expect_value(t, len(log.calls), 2)
		if len(log.calls) == 2 {
			testing.expect_value(t, i64(len(got)), log.calls[1].bytes_out)
		}
		log.cancel_at = 0

		bw: bzip2.Writer
		aw := Append_Writer{out = &got, fail_at = -1}
		testing.expect_value(t, bzip2.writer_init(&bw, append_writer(&aw), .Level_1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		bzip2.writer_destroy(&bw)
	}
}

@(test)
bzip2_progress_decode :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xb21c}
	text := lz4_test_lcg_text(&g, CODEC_PROGRESS_BZIP2_SIZE)
	defer delete(text)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, bzip2.compress(&packed, text, .Level_1), nil)
	twice: [dynamic]byte
	defer delete(twice)
	append(&twice, ..packed[:])
	append(&twice, ..packed[:])
	log: Ppmd_Progress_Log
	defer delete(log.calls)
	first: [dynamic]compress.Progress
	defer delete(first)

	for kind in Stream_Kind {
		input := packed[:]
		output: [dynamic]byte
		defer delete(output)
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		err := bzip2.decompress(&ctx, len(text), ppmd_progress_options(&log, {progress_interval = 1}))
		compress.destroy_context(&ctx)
		label := fmt.tprintf("bzip2 memory decode %v", kind)
		testing.expectf(t, err == nil && bytes.equal(output[:], text), "%v: %v", label, err)
		testing.expectf(t, len(log.calls) == 3, "%v: %v calls", label, len(log.calls))
		ppmd_progress_expect(t, label, log.calls[:], codec_progress_input_total(kind, len(packed)), i64(len(text)), i64(len(packed)), i64(len(text)))
		testing.expectf(t, len(log.calls) == 0 || log.calls[len(log.calls) - 1].bytes_out == i64(len(text)), "%v: last call %v", label, log.calls)
		codec_progress_same(t, label, &first, log.calls[:])
	}
	free_all(context.temp_allocator)

	{
		output: [dynamic]byte
		defer delete(output)
		testing.expect_value(t, bzip2.decompress(&output, packed[:], len(text), ppmd_progress_options(&log)), nil)
		testing.expect_value(t, len(log.calls), 0)

		log.cancel_at = 2
		testing.expect_value(t, bzip2.decompress(&output, packed[:], len(text), ppmd_progress_options(&log, {progress_interval = 1})), compress.General_Error.Canceled)
		testing.expect_value(t, len(log.calls), 2)
		if len(log.calls) == 2 {
			testing.expect_value(t, i64(len(output)), log.calls[1].bytes_out)
			testing.expect(t, bytes.equal(output[:], text[:len(output)]))
		}
		log.cancel_at = 0

		testing.expect_value(t, bzip2.decompress(&output, packed[:], len(text), {progress_interval = -1}), compress.General_Error.Incompatible_Options)
	}

	clear(&first)
	for kind in Stream_Kind {
		input := twice[:]
		output: [dynamic]byte
		defer delete(output)
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		aw  := Append_Writer{out = &output, fail_at = -1}
		err := bzip2.decompress_to_writer(append_writer(&aw), &ctx, -1, ppmd_progress_options(&log, {chunk_size = 65536}))
		compress.destroy_context(&ctx)
		label := fmt.tprintf("bzip2 writer decode %v", kind)
		testing.expectf(t, err == nil && len(output) == 2 * len(text) && bytes.equal(output[:len(text)], text) && bytes.equal(output[len(text):], text), "%v: %v", label, err)
		testing.expectf(t, len(log.calls) >= 2 * len(text) / 65536, "%v: %v calls", label, len(log.calls))
		ppmd_progress_expect(t, label, log.calls[:], codec_progress_input_total(kind, len(twice)), -1, i64(len(twice)), i64(2 * len(text)))
		codec_progress_expect_steps(t, label, log.calls[:], 65536)
		testing.expectf(t, len(log.calls) == 0 || log.calls[len(log.calls) - 1].bytes_out == i64(2 * len(text)), "%v: last call %v", label, log.calls)
		codec_progress_same(t, label, &first, log.calls[:])
	}
	free_all(context.temp_allocator)

	{
		output: [dynamic]byte
		defer delete(output)
		data := packed[:]
		ctx  := compress.init_context(&data)
		aw   := Append_Writer{out = &output, fail_at = -1}
		log.cancel_at = 2
		testing.expect_value(t, bzip2.decompress_to_writer(append_writer(&aw), &ctx, len(text), ppmd_progress_options(&log, {chunk_size = 65536})), compress.General_Error.Canceled)
		testing.expect_value(t, len(log.calls), 2)
		if len(log.calls) == 2 {
			testing.expect_value(t, i64(len(output)), log.calls[1].bytes_out)
			testing.expectf(t, log.calls[1].total_out == i64(len(text)), "bzip2 writer decode total out: %v", log.calls[1])
		}
		log.cancel_at = 0
	}

	{
		data := packed[:]
		ctx  := compress.init_context(&data)
		r: bzip2.Reader
		defer bzip2.reader_destroy(&r)
		testing.expect_value(t, bzip2.reader_init(&r, &ctx, -1, ppmd_progress_options(&log)), nil)
		total := codec_progress_drain(t, bzip2.reader_to_stream(&r))
		testing.expect_value(t, total, len(text))
		testing.expect_value(t, len(log.calls), (len(text) + 2999) / 3000)
		ppmd_progress_expect(t, "bzip2 reader", log.calls[:], i64(len(packed)), -1, i64(len(packed)), i64(len(text)))
		for c, i in log.calls {
			testing.expectf(t, c.bytes_out == min(i64(i + 1) * 3000, i64(len(text))), "bzip2 reader call %v: %v bytes out", i, c.bytes_out)
		}

		bzip2.reader_destroy(&r)
		log.cancel_at = 2
		data = packed[:]
		ctx  = compress.init_context(&data)
		testing.expect_value(t, bzip2.reader_init(&r, &ctx, -1, ppmd_progress_options(&log)), nil)
		buffer: [3000]byte
		n1, err1 := bzip2.reader_read(&r, buffer[:])
		n2, err2 := bzip2.reader_read(&r, buffer[:])
		n3, err3 := bzip2.reader_read(&r, buffer[:])
		testing.expectf(t, n1 == 3000 && err1 == nil && n2 == 3000 && err2 == nil && n3 == 0 && err3 == compress.General_Error.Canceled, "bzip2 reader cancel: %v %v, %v %v, %v %v", n1, err1, n2, err2, n3, err3)
		log.cancel_at = 0

		bzip2.reader_destroy(&r)
		data = packed[:]
		ctx  = compress.init_context(&data)
		testing.expect_value(t, bzip2.reader_init(&r, &ctx, -1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
	}
}

@(test)
lz4_progress_block :: proc(t: ^testing.T) {
	INTERVAL :: 50_000
	g := Lz4_Test_Lcg{state = 0x1a4b}
	text := lz4_test_lcg_text(&g, CODEC_PROGRESS_LZ4_SIZE)
	defer delete(text)
	dictionary := lz4_test_lcg_text(&g, 20_000)
	defer delete(dictionary)
	log: Ppmd_Progress_Log
	defer delete(log.calls)
	s := new(lz4.LZ4)
	defer free(s)
	bound  := lz4.compress_block_bound(len(text))
	packed := make([]byte, bound)
	defer delete(packed)
	plain := make([]byte, bound)
	defer delete(plain)

	for i in 1..=12 {
		level := lz4.Level(i)
		for dict in ([][]byte{nil, dictionary}) {
			label := fmt.tprintf("lz4 block encode level %v, dictionary %v", i, len(dict))
			want, want_err := lz4.compress_block(s, plain, text, level, dictionary = dict)
			n, err := lz4.compress_block(s, packed, text, level, ppmd_progress_options(&log, {progress_interval = INTERVAL}), dict)
			testing.expectf(t, want_err == nil && err == nil && n == want && bytes.equal(packed[:n], plain[:want]), "%v: %v, %v, %v bytes, want %v", label, want_err, err, n, want)
			testing.expectf(t, len(log.calls) >= 4, "%v: %v calls", label, len(log.calls))
			ppmd_progress_expect(t, label, log.calls[:], i64(len(text)), -1, i64(len(text)), i64(n))
			codec_progress_expect_last(t, label, log.calls[:], i64(len(text)), i64(n))
			codec_progress_expect_spacing(t, label, log.calls[:max(len(log.calls) - 1, 0)], INTERVAL, true)
		}
	}
	free_all(context.temp_allocator)

	{
		got: [dynamic]byte
		defer delete(got)
		testing.expect_value(t, lz4.compress_block(&got, text, .Level_12, ppmd_progress_options(&log)), nil)
		testing.expect_value(t, len(log.calls), 1)

		log.cancel_at = 2
		testing.expect_value(t, lz4.compress_block(&got, text, .Level_12, ppmd_progress_options(&log, {progress_interval = INTERVAL})), compress.General_Error.Canceled)
		testing.expect_value(t, len(got), 0)
		testing.expect_value(t, len(log.calls), 2)
		n, err := lz4.compress_block(s, packed, text, .Level_1, ppmd_progress_options(&log, {progress_interval = INTERVAL}))
		testing.expectf(t, n == 0 && err == compress.General_Error.Canceled, "lz4 block encode cancel: %v, %v", n, err)
		log.cancel_at = 0

		want, _ := lz4.compress_block(s, plain, text, .Level_1)
		testing.expect_value(t, lz4.compress_block(&got, text, .Level_1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		testing.expect_value(t, lz4.compress_block(&got, text, .Level_1, {max_output_size = want - 1}), compress.General_Error.Output_Too_Short)
		testing.expect_value(t, lz4.compress_block(&got, text, .Level_1, {max_output_size = want}), nil)
		testing.expect(t, bytes.equal(got[:], plain[:want]))
		testing.expect_value(t, lz4.compress_block(&got, text, .Level_1, {max_memory = size_of(lz4.LZ4) - 1}), compress.General_Error.Memory_Limit_Exceeded)
		_, err = lz4.compress_block(s, packed, text, .Level_1, {max_output_size = want - 1})
		testing.expect_value(t, err, compress.General_Error.Output_Too_Short)
	}

	n, _ := lz4.compress_block(s, packed, text, .Level_1)
	{
		output: [dynamic]byte
		defer delete(output)
		testing.expect_value(t, lz4.decompress_block(&output, packed[:n], len(text), ppmd_progress_options(&log, {progress_interval = INTERVAL})), nil)
		testing.expect(t, bytes.equal(output[:], text))
		testing.expectf(t, len(log.calls) >= 4, "lz4 block decode: %v calls", len(log.calls))
		ppmd_progress_expect(t, "lz4 block decode", log.calls[:], i64(n), i64(len(text)), i64(n), i64(len(text)))
		codec_progress_expect_spacing(t, "lz4 block decode", log.calls[:], INTERVAL, false)
		first: [dynamic]compress.Progress
		defer delete(first)
		codec_progress_same(t, "lz4 block decode", &first, log.calls[:])

		slice := make([]byte, len(text))
		defer delete(slice)
		w, slice_err := lz4.decompress_block(slice, packed[:n], ppmd_progress_options(&log, {progress_interval = INTERVAL}))
		testing.expectf(t, slice_err == nil && w == len(text) && bytes.equal(slice, text), "lz4 block decode to slice: %v, %v", slice_err, w)
		codec_progress_same(t, "lz4 block decode to slice", &first, log.calls[:])

		data := packed[:n]
		ctx  := compress.init_context(&data, &output)
		testing.expect_value(t, lz4.decompress_block(&ctx, len(text), ppmd_progress_options(&log, {progress_interval = INTERVAL})), nil)
		testing.expect(t, bytes.equal(output[:], text))
		codec_progress_same(t, "lz4 block decode from context", &first, log.calls[:])

		testing.expect_value(t, lz4.decompress_block(&output, packed[:n], len(text), ppmd_progress_options(&log)), nil)
		testing.expect_value(t, len(log.calls), 0)

		log.cancel_at = 2
		testing.expect_value(t, lz4.decompress_block(&output, packed[:n], len(text), ppmd_progress_options(&log, {progress_interval = INTERVAL})), compress.General_Error.Canceled)
		testing.expect_value(t, len(log.calls), 2)
		if len(log.calls) == 2 {
			testing.expect_value(t, i64(len(output)), log.calls[1].bytes_out)
			testing.expect(t, bytes.equal(output[:], text[:len(output)]))
		}
		w, slice_err = lz4.decompress_block(slice, packed[:n], ppmd_progress_options(&log, {progress_interval = INTERVAL}))
		testing.expect_value(t, slice_err, compress.General_Error.Canceled)
		log.cancel_at = 0

		testing.expect_value(t, lz4.decompress_block(&output, packed[:n], len(text), {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		testing.expect_value(t, lz4.decompress_block(&output, packed[:n], len(text), {max_output_size = len(text) - 1}), compress.General_Error.Output_Too_Short)
		_, slice_err = lz4.decompress_block(slice, packed[:n], {max_output_size = len(text) - 1})
		testing.expect_value(t, slice_err, compress.General_Error.Output_Too_Short)
	}
}

@(test)
lz4_progress_frame :: proc(t: ^testing.T) {
	INTERVAL :: 100_000
	g := Lz4_Test_Lcg{state = 0xf4a3}
	text := lz4_test_lcg_text(&g, CODEC_PROGRESS_LZ4_SIZE)
	defer delete(text)
	frame_options := lz4.Frame_Options{block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS}
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, lz4.compress_frame(&packed, text, .Level_1, frame_options), nil)
	log: Ppmd_Progress_Log
	defer delete(log.calls)
	first: [dynamic]compress.Progress
	defer delete(first)

	{
		got: [dynamic]byte
		defer delete(got)
		testing.expect_value(t, lz4.compress_frame(&got, text, .Level_1, frame_options, ppmd_progress_options(&log, {progress_interval = INTERVAL})), nil)
		testing.expect(t, bytes.equal(got[:], packed[:]))
		testing.expect_value(t, len(log.calls), 3)
		ppmd_progress_expect(t, "lz4 frame encode", log.calls[:], i64(len(text)), -1, i64(len(text)), i64(len(packed)))
		want_in := [?]i64{2 * 65536, 4 * 65536, i64(len(text))}
		for c, i in log.calls[:min(len(log.calls), len(want_in))] {
			testing.expectf(t, c.bytes_in == want_in[i], "lz4 frame encode call %v: %v bytes in, want %v", i, c.bytes_in, want_in[i])
		}
		codec_progress_expect_last(t, "lz4 frame encode", log.calls[:], i64(len(text)), i64(len(packed)))

		testing.expect_value(t, lz4.compress_frame(&got, text, .Level_1, frame_options, ppmd_progress_options(&log)), nil)
		testing.expect_value(t, len(log.calls), 1)

		log.cancel_at = 2
		testing.expect_value(t, lz4.compress_frame(&got, text, .Level_1, frame_options, ppmd_progress_options(&log, {progress_interval = INTERVAL})), compress.General_Error.Canceled)
		testing.expect_value(t, len(got), 0)
		log.cancel_at = 0

		testing.expect_value(t, lz4.compress_frame(&got, text, .Level_1, frame_options, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		testing.expect_value(t, lz4.compress_frame(&got, text, .Level_1, frame_options, {max_output_size = len(packed) - 1}), compress.General_Error.Output_Too_Short)
		testing.expect_value(t, lz4.compress_frame(&got, text, .Level_1, frame_options, ppmd_progress_options(&log, {max_output_size = len(packed), progress_interval = INTERVAL})), nil)
		testing.expect(t, bytes.equal(got[:], packed[:]))
		testing.expect_value(t, len(log.calls), 3)
	}

	for kind in Stream_Kind {
		input := packed[:]
		output: [dynamic]byte
		defer delete(output)
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		err := lz4.decompress_frame(&ctx, len(text), ppmd_progress_options(&log, {progress_interval = INTERVAL}))
		compress.destroy_context(&ctx)
		label := fmt.tprintf("lz4 frame decode %v", kind)
		testing.expectf(t, err == nil && bytes.equal(output[:], text), "%v: %v", label, err)
		testing.expectf(t, len(log.calls) == 2, "%v: %v calls", label, len(log.calls))
		ppmd_progress_expect(t, label, log.calls[:], codec_progress_input_total(kind, len(packed)), i64(len(text)), i64(len(packed)), i64(len(text)))
		want_out := [?]i64{2 * 65536, 4 * 65536}
		for c, i in log.calls[:min(len(log.calls), len(want_out))] {
			testing.expectf(t, c.bytes_out == want_out[i], "%v call %v: %v bytes out, want %v", label, i, c.bytes_out, want_out[i])
		}
		codec_progress_same(t, label, &first, log.calls[:])
	}
	free_all(context.temp_allocator)

	{
		output: [dynamic]byte
		defer delete(output)
		log.cancel_at = 2
		testing.expect_value(t, lz4.decompress_frame(&output, packed[:], len(text), ppmd_progress_options(&log, {progress_interval = INTERVAL})), compress.General_Error.Canceled)
		testing.expect_value(t, len(output), 4 * 65536)
		log.cancel_at = 0
		testing.expect_value(t, lz4.decompress_frame(&output, packed[:], len(text), {progress_interval = -1}), compress.General_Error.Incompatible_Options)
	}

	clear(&first)
	for kind in Stream_Kind {
		input := packed[:]
		output: [dynamic]byte
		defer delete(output)
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		aw  := Append_Writer{out = &output, fail_at = -1}
		err := lz4.decompress_frame_to_writer(append_writer(&aw), &ctx, -1, ppmd_progress_options(&log, {chunk_size = 70_000}))
		compress.destroy_context(&ctx)
		label := fmt.tprintf("lz4 writer decode %v", kind)
		testing.expectf(t, err == nil && bytes.equal(output[:], text), "%v: %v", label, err)
		testing.expectf(t, len(log.calls) >= 2, "%v: %v calls", label, len(log.calls))
		ppmd_progress_expect(t, label, log.calls[:], codec_progress_input_total(kind, len(packed)), -1, i64(len(packed)), i64(len(text)))
		codec_progress_expect_last(t, label, log.calls[:], i64(len(packed)), i64(len(text)))
		codec_progress_same(t, label, &first, log.calls[:])
	}
	free_all(context.temp_allocator)

	{
		output: [dynamic]byte
		defer delete(output)
		data := packed[:]
		ctx  := compress.init_context(&data)
		aw   := Append_Writer{out = &output, fail_at = -1}
		log.cancel_at = 2
		testing.expect_value(t, lz4.decompress_frame_to_writer(append_writer(&aw), &ctx, -1, ppmd_progress_options(&log, {chunk_size = 70_000})), compress.General_Error.Canceled)
		testing.expect_value(t, len(log.calls), 2)
		if len(log.calls) == 2 {
			testing.expect_value(t, i64(len(output)), log.calls[1].bytes_out)
		}
		log.cancel_at = 0
	}

	{
		data := packed[:]
		ctx  := compress.init_context(&data)
		r: lz4.Frame_Reader
		defer lz4.frame_reader_destroy(&r)
		testing.expect_value(t, lz4.frame_reader_init(&r, &ctx, len(text), ppmd_progress_options(&log)), nil)
		total := codec_progress_drain(t, lz4.frame_reader_to_stream(&r))
		testing.expect_value(t, total, len(text))
		testing.expect_value(t, len(log.calls), (len(text) + 2999) / 3000)
		ppmd_progress_expect(t, "lz4 reader", log.calls[:], i64(len(packed)), i64(len(text)), i64(len(packed)), i64(len(text)))
		for c, i in log.calls {
			testing.expectf(t, c.bytes_out == min(i64(i + 1) * 3000, i64(len(text))), "lz4 reader call %v: %v bytes out", i, c.bytes_out)
		}
		codec_progress_expect_last(t, "lz4 reader", log.calls[:], i64(len(packed)), i64(len(text)))

		lz4.frame_reader_destroy(&r)
		log.cancel_at = 2
		data = packed[:]
		ctx  = compress.init_context(&data)
		testing.expect_value(t, lz4.frame_reader_init(&r, &ctx, -1, ppmd_progress_options(&log)), nil)
		buffer: [3000]byte
		n1, err1 := lz4.frame_reader_read(&r, buffer[:])
		n2, err2 := lz4.frame_reader_read(&r, buffer[:])
		n3, err3 := lz4.frame_reader_read(&r, buffer[:])
		testing.expectf(t, n1 == 3000 && err1 == nil && n2 == 3000 && err2 == nil && n3 == 0 && err3 == compress.General_Error.Canceled, "lz4 reader cancel: %v %v, %v %v, %v %v", n1, err1, n2, err2, n3, err3)
		log.cancel_at = 0

		lz4.frame_reader_destroy(&r)
		data = packed[:]
		ctx  = compress.init_context(&data)
		testing.expect_value(t, lz4.frame_reader_init(&r, &ctx, -1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
	}

	{
		got: [dynamic]byte
		defer delete(got)
		testing.expect_value(t, codec_progress_lz4_pack(text, frame_options, ppmd_progress_options(&log), &got), nil)
		round: [dynamic]byte
		defer delete(round)
		testing.expect_value(t, lz4.decompress_frame(&round, got[:]), nil)
		testing.expect(t, bytes.equal(round[:], text))
		testing.expect_value(t, len(log.calls), 5)
		ppmd_progress_expect(t, "lz4 frame writer", log.calls[:], i64(len(text)), -1, i64(len(text)), i64(len(got)))
		codec_progress_expect_last(t, "lz4 frame writer", log.calls[:], i64(len(text)), i64(len(got)))

		clear(&got)
		log.cancel_at = 2
		testing.expect_value(t, codec_progress_lz4_pack(text, frame_options, ppmd_progress_options(&log), &got), compress.General_Error.Canceled)
		testing.expect_value(t, len(log.calls), 2)
		if len(log.calls) == 2 {
			testing.expect_value(t, i64(len(got)), log.calls[1].bytes_out)
		}
		log.cancel_at = 0

		fw: lz4.Frame_Writer
		aw := Append_Writer{out = &got, fail_at = -1}
		testing.expect_value(t, lz4.frame_writer_init(&fw, append_writer(&aw), .Level_1, frame_options, -1, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		lz4.frame_writer_destroy(&fw)
	}
}

@(test)
bzip2_output_limit :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xb2f1}
	text := lz4_test_lcg_text(&g, 150_000)
	defer delete(text)
	random := lz4_test_lcg_bytes(&g, 280_000)
	defer delete(random)
	state := new(bzip2.BZip2)
	defer free(state)

	for input, i in ([][]byte{text, random, text[:10], nil}) {
		codec_limit_bzip2(t, state, fmt.tprintf("bzip2 input %v", i), input)
	}
	got: [dynamic]byte
	defer delete(got)
	testing.expect_value(t, bzip2.compress(&got, text, .Level_1, {max_output_size = len(text) - 1}), nil)
	testing.expect_value(t, bzip2.compress(&got, random, .Level_1, {max_output_size = len(random) - 1}), compress.General_Error.Output_Too_Short)
	testing.expect_value(t, len(got), 0)
}

@(test)
lz4_output_limit :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0x41a7}
	text := lz4_test_lcg_text(&g, 120_000)
	defer delete(text)
	random := lz4_test_lcg_bytes(&g, 70_000)
	defer delete(random)
	mixed := make([]byte, len(random) + len(text))
	defer delete(mixed)
	copy(mixed, random)
	copy(mixed[len(random):], text)
	s := new(lz4.LZ4)
	defer free(s)

	linked      := lz4.Frame_Options{block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS}
	independent := lz4.Frame_Options{block_max_size = .Max_64KiB, flags = {.Independent_Blocks, .Block_Checksum, .Content_Checksum}}
	for input, i in ([][]byte{text, random, mixed, text[:20], nil}) {
		for level in ([]lz4.Level{.Level_1, .Level_2, .Level_3, .Level_10}) {
			codec_limit_lz4(t, s, fmt.tprintf("lz4 block input %v, level %v", i, level), input, level, nil, nil)
			codec_limit_lz4(t, s, fmt.tprintf("lz4 linked frame input %v, level %v", i, level), input, level, linked, nil)
			codec_limit_lz4(t, s, fmt.tprintf("lz4 independent frame input %v, level %v", i, level), input, level, independent, nil)
		}
		codec_limit_lz4(t, s, fmt.tprintf("lz4 block input %v, dictionary", i), input, .Level_9, nil, text[:30_000])
		codec_limit_lz4(t, s, fmt.tprintf("lz4 independent frame input %v, dictionary", i), input, .Level_9, independent, text[:30_000])
	}
	free_all(context.temp_allocator)

	got: [dynamic]byte
	defer delete(got)
	testing.expect_value(t, lz4.compress_block(&got, text, .Level_12, {max_output_size = len(text) - 1}), nil)
	testing.expect_value(t, lz4.compress_block(&got, random, .Level_1, {max_output_size = len(random) - 1}), compress.General_Error.Output_Too_Short)
	testing.expect_value(t, lz4.compress_frame(&got, text, .Level_1, linked, {max_output_size = len(text) - 1}), nil)
	testing.expect_value(t, lz4.compress_frame(&got, random, .Level_1, linked, {max_output_size = len(random) - 1}), compress.General_Error.Output_Too_Short)
	testing.expect_value(t, len(got), 0)
}

CODEC_LIMIT_STEPS :: [?]int{1000, 34, 21, 13, 8, 5, 3, 2, 1, 0}

codec_limit_bzip2 :: proc(t: ^testing.T, state: ^bzip2.BZip2, label: string, input: []byte) {
	packed: [dynamic]byte
	defer delete(packed)
	if !testing.expect_value(t, bzip2.compress(&packed, input, .Level_1), nil) {
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
		written, err := bzip2.compress(state, buffer, input, .Level_1, {max_output_size = limit})
		codec_limit_check(t, label, packed[:], buffer, limit, written, err)
	}
	written, err := bzip2.compress(state, buffer[:n], input, .Level_1)
	codec_limit_check(t, label, packed[:], buffer[:n], n, written, err)
	written, err = bzip2.compress(state, buffer[:n - 1], input, .Level_1)
	codec_limit_check(t, label, packed[:], buffer[:n - 1], n - 1, written, err)

	got: [dynamic]byte
	defer delete(got)
	err = bzip2.compress(&got, input, .Level_1, {max_output_size = n})
	testing.expectf(t, err == nil && bytes.equal(got[:], packed[:]), "%v: dynamic at the limit: %v", label, err)
	err = bzip2.compress(&got, input, .Level_1, {max_output_size = n - 1})
	testing.expectf(t, err == compress.General_Error.Output_Too_Short && len(got) == 0, "%v: dynamic below the limit: %v", label, err)
}

codec_limit_lz4 :: proc(t: ^testing.T, s: ^lz4.LZ4, label: string, input: []byte, level: lz4.Level, frame_options: Maybe(lz4.Frame_Options), dictionary: []byte) {
	frame, is_frame := frame_options.?
	pack_dynamic :: proc(output: ^[dynamic]byte, input: []byte, level: lz4.Level, frame: lz4.Frame_Options, is_frame: bool, options: compress.Options, dictionary: []byte) -> compress.Error {
		if is_frame {
			return lz4.compress_frame(output, input, level, frame, options, dictionary)
		}
		return lz4.compress_block(output, input, level, options, dictionary)
	}
	pack_slice :: proc(s: ^lz4.LZ4, output, input: []byte, level: lz4.Level, frame: lz4.Frame_Options, is_frame: bool, options: compress.Options, dictionary: []byte) -> (int, compress.Error) {
		if is_frame {
			return lz4.compress_frame(s, output, input, level, frame, options, dictionary)
		}
		return lz4.compress_block(s, output, input, level, options, dictionary)
	}

	packed: [dynamic]byte
	defer delete(packed)
	if !testing.expect_value(t, pack_dynamic(&packed, input, level, frame, is_frame, {}, dictionary), nil) {
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
		written, err := pack_slice(s, buffer, input, level, frame, is_frame, {max_output_size = limit}, dictionary)
		codec_limit_check(t, label, packed[:], buffer, limit, written, err)
	}
	written, err := pack_slice(s, buffer[:n], input, level, frame, is_frame, {}, dictionary)
	codec_limit_check(t, label, packed[:], buffer[:n], n, written, err)
	written, err = pack_slice(s, buffer[:n - 1], input, level, frame, is_frame, {}, dictionary)
	codec_limit_check(t, label, packed[:], buffer[:n - 1], n - 1, written, err)

	log: Ppmd_Progress_Log
	defer delete(log.calls)
	codec_limit_fill(buffer)
	written, err = pack_slice(s, buffer, input, level, frame, is_frame, ppmd_progress_options(&log, {max_output_size = n, progress_interval = 4096}), dictionary)
	codec_limit_check(t, label, packed[:], buffer, n, written, err)
	codec_progress_expect_last(t, label, log.calls[:], i64(len(input)), i64(n))

	got: [dynamic]byte
	defer delete(got)
	err = pack_dynamic(&got, input, level, frame, is_frame, {max_output_size = n}, dictionary)
	testing.expectf(t, err == nil && bytes.equal(got[:], packed[:]), "%v: dynamic at the limit: %v", label, err)
	if n > 1 {
		err = pack_dynamic(&got, input, level, frame, is_frame, {max_output_size = n - 1}, dictionary)
		testing.expectf(t, err == compress.General_Error.Output_Too_Short && len(got) == 0, "%v: dynamic below the limit: %v", label, err)
	}
}

codec_limit_fill :: proc(buffer: []byte) {
	for &b in buffer {
		b = 0xa5
	}
}

codec_limit_check :: proc(t: ^testing.T, label: string, packed, buffer: []byte, limit, written: int, err: compress.Error) {
	n := len(packed)
	if limit < n {
		testing.expectf(t, written == 0 && err == compress.General_Error.Output_Too_Short, "%v, limit %v of %v: %v, %v", label, limit, n, written, err)
	} else {
		testing.expectf(t, err == nil && written == n && bytes.equal(buffer[:written], packed), "%v, limit %v of %v: %v, %v", label, limit, n, written, err)
	}
	for b in buffer[min(limit, len(buffer)):] {
		if b != 0xa5 {
			testing.expectf(t, false, "%v, limit %v of %v: wrote past the limit", label, limit, n)
			break
		}
	}
}

codec_progress_input_total :: proc(kind: Stream_Kind, size: int) -> i64 {
	return -1 if kind == .One_Byte_No_Seek else i64(size)
}

codec_progress_expect_last :: proc(t: ^testing.T, label: string, calls: []compress.Progress, bytes_in, bytes_out: i64) {
	if !testing.expectf(t, len(calls) > 0, "%v: no calls", label) {
		return
	}
	last := calls[len(calls) - 1]
	testing.expectf(t, last.bytes_in == bytes_in && last.bytes_out == bytes_out, "%v: last call %v, want %v in, %v out", label, last, bytes_in, bytes_out)
}

codec_progress_expect_spacing :: proc(t: ^testing.T, label: string, calls: []compress.Progress, interval: i64, by_input: bool) {
	prev := i64(0)
	for c, i in calls {
		at := c.bytes_in if by_input else c.bytes_out
		testing.expectf(t, at - prev >= interval, "%v call %v: %v after %v, want %v apart", label, i, at, prev, interval)
		prev = at
	}
}

codec_progress_expect_steps :: proc(t: ^testing.T, label: string, calls: []compress.Progress, step: i64) {
	prev := i64(0)
	for c, i in calls {
		testing.expectf(t, c.bytes_out > prev && c.bytes_out - prev <= step, "%v call %v: %v after %v, want at most %v apart", label, i, c.bytes_out, prev, step)
		prev = c.bytes_out
	}
}

codec_progress_same :: proc(t: ^testing.T, label: string, first: ^[dynamic]compress.Progress, calls: []compress.Progress) {
	if len(first) == 0 {
		append(first, ..calls)
		return
	}
	testing.expectf(t, len(calls) == len(first), "%v: %v calls, want %v", label, len(calls), len(first))
	for c, i in calls[:min(len(calls), len(first))] {
		testing.expectf(t, c.bytes_in == first[i].bytes_in && c.bytes_out == first[i].bytes_out, "%v call %v: %v, want %v", label, i, c, first[i])
	}
}

codec_progress_drain :: proc(t: ^testing.T, s: io.Stream) -> (total: int) {
	buffer: [3000]byte
	for {
		n, err := io.read(s, buffer[:])
		total += n
		if err != nil {
			testing.expect_value(t, err, io.Error.EOF)
			return
		}
	}
}

codec_progress_bzip2_pack :: proc(input: []byte, options: compress.Options, output: ^[dynamic]byte) -> (err: compress.Error) {
	aw := Append_Writer{out = output, fail_at = -1}
	bw: bzip2.Writer
	defer bzip2.writer_destroy(&bw)
	bzip2.writer_init(&bw, append_writer(&aw), .Level_1, options) or_return
	for pos := 0; pos < len(input); pos += 3000 {
		bzip2.writer_write(&bw, input[pos:min(pos + 3000, len(input))]) or_return
	}
	return bzip2.writer_finish(&bw)
}

codec_progress_lz4_pack :: proc(input: []byte, frame_options: lz4.Frame_Options, options: compress.Options, output: ^[dynamic]byte) -> (err: compress.Error) {
	aw := Append_Writer{out = output, fail_at = -1}
	fw: lz4.Frame_Writer
	defer lz4.frame_writer_destroy(&fw)
	lz4.frame_writer_init(&fw, append_writer(&aw), .Level_1, frame_options, i64(len(input)), options) or_return
	for pos := 0; pos < len(input); pos += 3000 {
		lz4.frame_writer_write(&fw, input[pos:min(pos + 3000, len(input))]) or_return
	}
	return lz4.frame_writer_finish(&fw)
}
