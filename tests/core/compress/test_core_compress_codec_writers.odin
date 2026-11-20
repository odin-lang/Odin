package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/lz4"
import "core:io"
import "core:math/rand"
import "core:mem"
import "core:testing"

CODEC_WRITERS_FUZZ :: #config(CODEC_WRITERS_FUZZ, 60)

Write_Pattern :: enum {
	Whole,
	Bytes,
	Random,
	Edges,
}

Codec_Writer_Setup :: struct {
	bzip2_level:   bzip2.Level,
	lz4_level:     lz4.Level,
	frame_options: lz4.Frame_Options,
	input_size:    i64,
	options:       compress.Options,
	dictionary:    []byte,
}

@(test)
codec_writer_bzip2_identity :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	g := Lz4_Test_Lcg{state = 0xb21b}
	random := lz4_test_lcg_bytes(&g, 150_000)
	defer delete(random)
	runs := codec_runs_data(400_000)
	defer delete(runs)

	inputs := [][]byte{data, random, runs, {}, {7}, data[:5]}
	for input in inputs {
		for l in 1..=9 {
			level := bzip2.Level(l)
			if len(input) > 200_000 && level != .Level_1 && level != .Level_2 && level != .Level_9 {
				continue
			}
			for pattern in Write_Pattern {
				if pattern == .Bytes && len(input) > 200_000 {
					continue
				}
				codec_writer_check(t, "bzip2", .BZip2, input, pattern, {bzip2_level = level})
			}
		}
	}

	for extra in ([]int{-3, -1, 0, 1, 2, 3, 4, 5, 6, 300}) {
		for run in ([]int{0, 4, 300, 600}) {
			edge := codec_block_edge(99_981, extra, run)
			defer delete(edge)
			for pattern in ([]Write_Pattern{.Whole, .Random, .Edges}) {
				codec_writer_check(t, "bzip2 block edge", .BZip2, edge, pattern, {bzip2_level = .Level_1})
			}
		}
	}
}

@(test)
codec_writer_lz4_identity :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	g := Lz4_Test_Lcg{state = 0x41f}
	text := lz4_test_lcg_text(&g, 900_000 if !SLIM_TESTS else 200_000)
	defer delete(text)
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	sources := [][]byte{data, text, inputs.random, {}, {1, 2, 3}, data[:13]}
	flag_sets := []lz4.Frame_Flags{{}, lz4.DEFAULT_FRAME_FLAGS, {.Independent_Blocks, .Block_Checksum}, {.Content_Checksum, .Block_Checksum, .Content_Size, .Independent_Blocks}}
	for input in sources {
		for l in 1..=12 {
			level := lz4.Level(l)
			if len(input) > 300_000 && level != .Level_1 && level != .Level_2 && level != .Level_4 && level != .Level_10 {
				continue
			}
			for block in ([]lz4.Block_Max_Size{.Max_64KiB, .Max_256KiB}) {
				for flags in flag_sets {
					setup := Codec_Writer_Setup{lz4_level = level, frame_options = {block_max_size = block, flags = flags}, input_size = -1, options = {chunk_size = 1}}
					if .Content_Size in flags {
						setup.input_size = i64(len(input))
					}
					codec_writer_check(t, "lz4", .LZ4, input, .Random, setup)
					codec_writer_check(t, "lz4", .LZ4, input, .Edges, setup)
					if len(input) < 100 {
						codec_writer_check(t, "lz4", .LZ4, input, .Bytes, setup)
					}
				}
			}
		}
	}

	for level in ([]lz4.Level{.Level_1, .Level_2, .Level_4, .Level_8, .Level_11}) {
		for flags in flag_sets {
			for dictionary_id in ([]Maybe(u32){nil, 0xdeadbeef}) {
				setup := Codec_Writer_Setup{lz4_level = level, frame_options = {block_max_size = .Max_64KiB, flags = flags, dictionary_id = dictionary_id}, input_size = -1, options = {chunk_size = 1}, dictionary = inputs.dictionary}
				codec_writer_check(t, "lz4 dictionary", .LZ4, data, .Random, setup)
				codec_writer_check(t, "lz4 dictionary", .LZ4, data[:20], .Edges, setup)
				codec_writer_check(t, "lz4 dictionary", .LZ4, {}, .Whole, setup)
			}
		}
	}

	big := lz4_test_lcg_text(&g, 9 << 20 if !SLIM_TESTS else 5 << 20)
	defer delete(big)
	for level in ([]lz4.Level{.Level_1, .Level_2}) {
		for flags in flag_sets {
			setup := Codec_Writer_Setup{lz4_level = level, frame_options = {block_max_size = .Max_4MiB, flags = flags}, input_size = -1}
			codec_writer_check(t, "lz4 4 MiB blocks", .LZ4, big, .Random, setup)
			setup.options.chunk_size = 1
			codec_writer_check(t, "lz4 4 MiB blocks", .LZ4, big, .Edges, setup)
		}
	}
	for chunk in ([]int{0, 1, 70_000}) {
		setup := Codec_Writer_Setup{lz4_level = .Level_4, frame_options = {block_max_size = .Max_1MiB, flags = lz4.DEFAULT_FRAME_FLAGS}, input_size = 3 << 20, options = {chunk_size = chunk}}
		codec_writer_check(t, "lz4 1 MiB blocks", .LZ4, big[:3 << 20], .Random, setup)
	}
}

@(test)
codec_writer_lz4_reset :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	g := Lz4_Test_Lcg{state = 0x52e}
	text := lz4_test_lcg_text(&g, 150_000 if !SLIM_TESTS else 80_000)
	defer delete(text)
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	sources := [][]byte{text, {}, data[:13], inputs.random[:min(len(inputs.random), 20_000)], data[:min(len(data), 30_000)], {1, 2, 3}, text[:70_000], text}
	flag_sets := []lz4.Frame_Flags{{}, lz4.DEFAULT_FRAME_FLAGS, {.Independent_Blocks, .Block_Checksum}, {.Content_Checksum, .Block_Checksum, .Content_Size, .Independent_Blocks}}
	for level in ([]lz4.Level{.Level_1, .Level_2, .Level_4, .Level_9, .Level_12}) {
		for flags, f in flag_sets {
			if (level == .Level_9 || level == .Level_12) && f % 2 == 0 {
				continue
			}
			for dictionary in ([][]byte{nil, inputs.dictionary}) {
				block := lz4.Block_Max_Size.Max_256KiB if f == 1 && dictionary == nil else .Max_64KiB
				setup := Codec_Writer_Setup{lz4_level = level, frame_options = {block_max_size = block, flags = flags}, options = {chunk_size = 1}, dictionary = dictionary}
				codec_writer_reset_check(t, sources, setup)
			}
		}
	}

	big := lz4_test_lcg_text(&g, 5 << 20 if !SLIM_TESTS else 3 << 20)
	defer delete(big)
	setup := Codec_Writer_Setup{lz4_level = .Level_1, frame_options = {block_max_size = .Max_4MiB, flags = lz4.DEFAULT_FRAME_FLAGS}}
	codec_writer_reset_check(t, {big, data, big[:70_000], big}, setup)

	{
		fw: lz4.Frame_Writer
		sink: [dynamic]byte
		defer delete(sink)
		aw := Append_Writer{out = &sink, fail_at = -1}
		testing.expect_value(t, lz4.frame_writer_reset(&fw, append_writer(&aw)), compress.Error(compress.General_Error.Incompatible_Options))

		testing.expect_value(t, lz4.frame_writer_init(&fw, append_writer(&aw), .Level_1, input_size = 100), nil)
		defer lz4.frame_writer_destroy(&fw)
		_, err := lz4.frame_writer_write(&fw, data[:101])
		testing.expect_value(t, err, compress.Error(compress.General_Error.Size_Mismatch))
		testing.expect_value(t, lz4.frame_writer_reset(&fw, append_writer(&aw), -2), compress.Error(compress.General_Error.Incompatible_Options))
		_, err = lz4.frame_writer_write(&fw, data[:1])
		testing.expect_value(t, err, compress.Error(compress.General_Error.Incompatible_Options))

		got: [dynamic]byte
		defer delete(got)
		gw := Append_Writer{out = &got, fail_at = -1}
		testing.expect_value(t, lz4.frame_writer_reset(&fw, append_writer(&gw)), nil)
		n: int
		n, err = lz4.frame_writer_write(&fw, data[:5000])
		testing.expect_value(t, n, 5000)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, lz4.frame_writer_finish(&fw), nil)
		want: [dynamic]byte
		defer delete(want)
		codec_writer_oneshot(.LZ4, data[:5000], {lz4_level = .Level_1, frame_options = {flags = lz4.DEFAULT_FRAME_FLAGS}, input_size = -1}, &want)
		testing.expectf(t, bytes.equal(got[:], want[:]), "lz4 reset after error: output differs, %v vs %v bytes", len(got), len(want))
	}
}

@(test)
codec_writer_round_trip :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for codec in Codec {
		packed: [dynamic]byte
		defer delete(packed)
		aw := Append_Writer{out = &packed, fail_at = -1}
		testing.expect_value(t, codec_writer_pack(codec, append_writer(&aw), data, .Random, {bzip2_level = .Level_9, lz4_level = .Level_9, frame_options = {flags = lz4.DEFAULT_FRAME_FLAGS}, input_size = i64(len(data))}), nil)

		input := packed[:]
		ctx := compress.init_context(&input)
		output: [dynamic]byte
		defer delete(output)
		ow := Append_Writer{out = &output, fail_at = -1}
		err: compress.Error
		switch codec {
		case .BZip2: err = bzip2.decompress_to_writer(append_writer(&ow), &ctx)
		case .LZ4:   err = lz4.decompress_frame_to_writer(append_writer(&ow), &ctx)
		}
		testing.expectf(t, err == nil && bytes.equal(output[:], data), "%v: %v, %v of %v bytes", codec, err, len(output), len(data))
	}
}

@(test)
codec_writer_failures :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for codec in Codec {
		want: [dynamic]byte
		defer delete(want)
		codec_writer_oneshot(codec, data, {bzip2_level = .Level_1, lz4_level = .Level_1, frame_options = {block_max_size = .Max_64KiB}, input_size = -1}, &want)

		for fail_at in ([]int{0, 1, 3, 10_000, len(want) - 1}) {
			output: [dynamic]byte
			defer delete(output)
			aw := Append_Writer{out = &output, fail_at = fail_at}
			err := codec_writer_pack(codec, append_writer(&aw), data, .Random, {bzip2_level = .Level_1, lz4_level = .Level_1, frame_options = {block_max_size = .Max_64KiB}, input_size = -1})
			testing.expectf(t, err == io.Error.Short_Write, "%v, fail at %v: %v", codec, fail_at, err)
			testing.expectf(t, bytes.equal(output[:], want[:fail_at]), "%v, fail at %v: %v bytes", codec, fail_at, len(output))
		}

		for options in ([]compress.Options{{max_memory = -1}, {chunk_size = -1}, {max_output_size = -1}, {buffer = make([]byte, 1000, context.temp_allocator)}}) {
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			err: compress.Error
			switch codec {
			case .BZip2:
				bw: bzip2.Writer
				err = bzip2.writer_init(&bw, append_writer(&aw), .Level_1, options)
				bzip2.writer_destroy(&bw)
			case .LZ4:
				fw: lz4.Frame_Writer
				err = lz4.frame_writer_init(&fw, append_writer(&aw), .Level_1, options = options)
				lz4.frame_writer_destroy(&fw)
			}
			testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v, %v: %v", codec, options.max_memory, err)
		}

		{
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			err: compress.Error
			switch codec {
			case .BZip2:
				bw: bzip2.Writer
				err = bzip2.writer_init(&bw, append_writer(&aw), .Level_1, {max_memory = 1 << 20})
				bzip2.writer_destroy(&bw)
				testing.expect_value(t, bzip2.writer_init(&bw, append_writer(&aw), bzip2.Level(10)), compress.Error(compress.General_Error.Incompatible_Options))
				bzip2.writer_destroy(&bw)
			case .LZ4:
				fw: lz4.Frame_Writer
				err = lz4.frame_writer_init(&fw, append_writer(&aw), .Level_1, {block_max_size = .Max_64KiB}, options = {max_memory = 600_000})
				lz4.frame_writer_destroy(&fw)
				testing.expect_value(t, lz4.frame_writer_init(&fw, append_writer(&aw), input_size = -2), compress.Error(compress.General_Error.Incompatible_Options))
				lz4.frame_writer_destroy(&fw)
			}
			testing.expectf(t, err == compress.General_Error.Memory_Limit_Exceeded, "%v: %v", codec, err)
		}

		{
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			switch codec {
			case .BZip2:
				bw: bzip2.Writer
				defer bzip2.writer_destroy(&bw)
				testing.expect_value(t, bzip2.writer_init(&bw, append_writer(&aw), .Level_1), nil)
				_, err := bzip2.writer_write(&bw, data[:100])
				testing.expect_value(t, err, nil)
				testing.expect_value(t, bzip2.writer_finish(&bw), nil)
				testing.expect_value(t, bzip2.writer_finish(&bw), nil)
				n, again := bzip2.writer_write(&bw, data[:1])
				testing.expectf(t, n == 0 && again == io.Error.Closed, "%v: write after finish gave %v, %v", codec, n, again)
			case .LZ4:
				fw: lz4.Frame_Writer
				defer lz4.frame_writer_destroy(&fw)
				testing.expect_value(t, lz4.frame_writer_init(&fw, append_writer(&aw), input_size = 100), nil)
				n, err := lz4.frame_writer_write(&fw, data[:101])
				testing.expectf(t, n == 0 && err == compress.General_Error.Size_Mismatch, "%v: too much data gave %v, %v", codec, n, err)
				testing.expect_value(t, lz4.frame_writer_finish(&fw), compress.Error(compress.General_Error.Size_Mismatch))
				lz4.frame_writer_destroy(&fw)

				testing.expect_value(t, lz4.frame_writer_init(&fw, append_writer(&aw), input_size = 100), nil)
				_, err = lz4.frame_writer_write(&fw, data[:99])
				testing.expect_value(t, err, nil)
				testing.expect_value(t, lz4.frame_writer_finish(&fw), compress.Error(compress.General_Error.Size_Mismatch))
				lz4.frame_writer_destroy(&fw)

				testing.expect_value(t, lz4.frame_writer_init(&fw, append_writer(&aw), input_size = 100), nil)
				_, err = lz4.frame_writer_write(&fw, data[:100])
				testing.expect_value(t, err, nil)
				testing.expect_value(t, lz4.frame_writer_finish(&fw), nil)
				n, err = lz4.frame_writer_write(&fw, data[:1])
				testing.expectf(t, n == 0 && err == io.Error.Closed, "%v: write after finish gave %v, %v", codec, n, err)
			}
		}
	}

	{
		want: [dynamic]byte
		defer delete(want)
		testing.expect_value(t, lz4.compress_frame(&want, data, .Level_1, {block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS}), nil)
		buffer := make([]byte, 2 * 65536 + 65536 + 4)
		defer delete(buffer)
		output: [dynamic]byte
		defer delete(output)
		aw := Append_Writer{out = &output, fail_at = -1}
		fw: lz4.Frame_Writer
		testing.expect_value(t, lz4.frame_writer_init(&fw, append_writer(&aw), .Level_1, {block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS}, i64(len(data)), {buffer = buffer}), nil)
		testing.expect_value(t, raw_data(fw.window), raw_data(buffer))
		_, err := lz4.frame_writer_write(&fw, data)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, lz4.frame_writer_finish(&fw), nil)
		lz4.frame_writer_destroy(&fw)
		testing.expect(t, bytes.equal(output[:], want[:]))
		testing.expect_value(t, len(buffer), 2 * 65536 + 65536 + 4)
	}
	free_all(context.temp_allocator)
}

@(test)
codec_writer_as_stream :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for codec in Codec {
		want: [dynamic]byte
		defer delete(want)
		setup := Codec_Writer_Setup{bzip2_level = .Level_5, lz4_level = .Level_3, frame_options = {flags = lz4.DEFAULT_FRAME_FLAGS}, input_size = i64(len(data))}
		codec_writer_oneshot(codec, data, setup, &want)

		output: [dynamic]byte
		defer delete(output)
		aw := Append_Writer{out = &output, fail_at = -1}
		bw := new(bzip2.Writer)
		defer free(bw)
		fw := new(lz4.Frame_Writer)
		defer free(fw)
		stream: io.Stream
		switch codec {
		case .BZip2:
			testing.expect_value(t, bzip2.writer_init(bw, append_writer(&aw), .Level_5), nil)
			stream = bzip2.writer_to_stream(bw)
		case .LZ4:
			testing.expect_value(t, lz4.frame_writer_init(fw, append_writer(&aw), .Level_3, input_size = i64(len(data))), nil)
			stream = lz4.frame_writer_to_stream(fw)
		}
		testing.expect_value(t, io.query(stream), io.Stream_Mode_Set{.Write, .Close, .Destroy, .Query})
		rest := data
		for len(rest) > 0 {
			k := min(len(rest), 1 + rand.int_max(50_000))
			n, err := io.write(stream, rest[:k])
			testing.expectf(t, n == k && err == nil, "%v: write gave %v, %v", codec, n, err)
			rest = rest[k:]
		}
		testing.expect_value(t, io.close(stream), nil)
		testing.expectf(t, bytes.equal(output[:], want[:]), "%v: %v vs %v bytes", codec, len(output), len(want))
		io.destroy(stream)
	}
}

@(test)
codec_writer_fuzz :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)
	for _ in 0..<CODEC_WRITERS_FUZZ {
		data: [dynamic]byte
		defer delete(data)
		d64_test_data(rand.int_max(4), rand.int_max(400_000), &data)
		codec := Codec(rand.int_max(len(Codec)))
		setup := Codec_Writer_Setup{
			bzip2_level   = bzip2.Level(1 + rand.int_max(9)),
			lz4_level     = lz4.Level(1 + rand.int_max(12)),
			frame_options = {block_max_size = lz4.Block_Max_Size(2 + rand.int_max(2))},
			input_size    = -1,
		}
		for flag in lz4.Frame_Flag {
			if rand.int_max(2) == 0 {
				setup.frame_options.flags += {flag}
			}
		}
		if .Content_Size in setup.frame_options.flags && rand.int_max(3) != 0 {
			setup.input_size = i64(len(data))
		}
		if rand.int_max(4) == 0 {
			setup.dictionary = inputs.dictionary
		}
		if rand.int_max(2) == 0 {
			setup.options.chunk_size = 1 + rand.int_max(200_000)
		}
		pattern := Write_Pattern(rand.int_max(len(Write_Pattern)))
		if pattern == .Bytes && len(data) > 50_000 {
			pattern = .Random
		}
		codec_writer_check(t, "fuzz", codec, data[:], pattern, setup)
		free_all(context.temp_allocator)
	}
}

codec_runs_data :: proc(size: int) -> []byte {
	data := make([]byte, size)
	x := u32(5)
	i := 0
	for i < size {
		x = x * 1103515245 + 12345
		run := 1 + int(x >> 16) % 600
		if x & 0x8000_0000 != 0 {
			run = 1 + int(x >> 20) % 6
		}
		b := u8(x >> 8)
		for k in 0..<min(run, size - i) {
			data[i + k] = b
		}
		i += run
	}
	return data
}

codec_block_edge :: proc(nblock_max, extra, run: int) -> []byte {
	data := make([]byte, nblock_max + extra)
	for &b, i in data {
		b = u8(i * 7 + i / 251)
	}
	for &b in data[max(0, len(data) - run):] {
		b = 0xaa
	}
	return data
}

codec_pattern_sizes :: proc(pattern: Write_Pattern, n: int) -> int {
	switch pattern {
	case .Whole:  return n
	case .Bytes:  return 1
	case .Random:
		switch rand.int_max(4) {
		case 0: return rand.int_max(8)
		case 1: return rand.int_max(300)
		}
		return rand.int_max(200_000)
	case .Edges:
		edges := [?]int{65536 + 3, 1, 0, 65536 + 4, 65535, 2, 131072, 99_981, 4, 262_144 + 3}
		return edges[rand.int_max(len(edges))]
	}
	return n
}

codec_writer_oneshot :: proc(codec: Codec, data: []byte, setup: Codec_Writer_Setup, output: ^[dynamic]byte) {
	switch codec {
	case .BZip2:
		bzip2.compress(output, data, setup.bzip2_level)
	case .LZ4:
		frame_options := setup.frame_options
		if setup.input_size < 0 {
			frame_options.flags -= {.Content_Size}
		}
		lz4.compress_frame(output, data, setup.lz4_level, frame_options, dictionary = setup.dictionary)
	}
}

codec_writer_pack :: proc(codec: Codec, w: io.Writer, data: []byte, pattern: Write_Pattern, setup: Codec_Writer_Setup) -> (err: compress.Error) {
	bw := new(bzip2.Writer)
	defer free(bw)
	fw := new(lz4.Frame_Writer)
	defer free(fw)
	switch codec {
	case .BZip2: err = bzip2.writer_init(bw, w, setup.bzip2_level, setup.options)
	case .LZ4:   err = lz4.frame_writer_init(fw, w, setup.lz4_level, setup.frame_options, setup.input_size, setup.options, setup.dictionary)
	}
	defer {
		switch codec {
		case .BZip2: bzip2.writer_destroy(bw)
		case .LZ4:   lz4.frame_writer_destroy(fw)
		}
	}
	if err != nil {
		return
	}
	rest := data
	for len(rest) > 0 {
		k := min(codec_pattern_sizes(pattern, len(rest)), len(rest))
		n: int
		switch codec {
		case .BZip2: n, err = bzip2.writer_write(bw, rest[:k])
		case .LZ4:   n, err = lz4.frame_writer_write(fw, rest[:k])
		}
		if err != nil {
			return
		}
		if n != k {
			return compress.General_Error.Output_Too_Short
		}
		rest = rest[k:]
	}
	switch codec {
	case .BZip2: err = bzip2.writer_finish(bw)
	case .LZ4:   err = lz4.frame_writer_finish(fw)
	}
	return
}

codec_writer_reset_check :: proc(t: ^testing.T, sources: [][]byte, setup: Codec_Writer_Setup) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	got: [dynamic]byte
	defer delete(got)
	want: [dynamic]byte
	defer delete(want)
	abandoned: [dynamic]byte
	defer delete(abandoned)
	aw := Append_Writer{out = &got, fail_at = -1}
	dw := Append_Writer{out = &abandoned, fail_at = -1}

	fw: lz4.Frame_Writer
	frame := setup
	frame.input_size = i64(len(sources[0])) if .Content_Size in setup.frame_options.flags else -1
	err := lz4.frame_writer_init(&fw, append_writer(&aw), setup.lz4_level, setup.frame_options, frame.input_size, setup.options, setup.dictionary, mem.tracking_allocator(&track))
	testing.expectf(t, err == nil, "lz4 reset, level %v, %v: init failed: %v", int(setup.lz4_level), setup.frame_options, err)
	if err != nil {
		lz4.frame_writer_destroy(&fw)
		return
	}
	allocations := track.total_allocation_count

	for input, i in sources {
		if i > 0 {
			frame.input_size = i64(len(input)) if .Content_Size in setup.frame_options.flags && i % 3 != 2 else -1
			if i % 4 == 3 && len(input) > 1 {
				testing.expect_value(t, lz4.frame_writer_reset(&fw, append_writer(&dw), -1), nil)
				_, _ = lz4.frame_writer_write(&fw, input[:len(input) / 2])
			}
			clear(&got)
			testing.expect_value(t, lz4.frame_writer_reset(&fw, append_writer(&aw), frame.input_size), nil)
		}
		rest := input
		for len(rest) > 0 && err == nil {
			k := min(codec_pattern_sizes(.Random, len(rest)), len(rest))
			n: int
			n, err = lz4.frame_writer_write(&fw, rest[:k])
			if err == nil && n != k {
				err = compress.General_Error.Output_Too_Short
			}
			rest = rest[k:]
		}
		if err == nil {
			err = lz4.frame_writer_finish(&fw)
		}
		clear(&want)
		codec_writer_oneshot(.LZ4, input, frame, &want)
		testing.expectf(t, err == nil, "lz4 reset, frame %v, %v bytes, level %v, %v: %v", i, len(input), int(setup.lz4_level), setup.frame_options, err)
		testing.expectf(t, bytes.equal(got[:], want[:]), "lz4 reset, frame %v, %v bytes, level %v, %v, dictionary %v: output differs, %v vs %v bytes", i, len(input), int(setup.lz4_level), setup.frame_options, len(setup.dictionary) > 0, len(got), len(want))
		err = nil
	}
	testing.expectf(t, track.total_allocation_count == allocations, "lz4 reset, level %v, %v: %v allocations after init, %v after %v frames", int(setup.lz4_level), setup.frame_options, allocations, track.total_allocation_count, len(sources))
	lz4.frame_writer_destroy(&fw)
	testing.expectf(t, len(track.allocation_map) == 0, "lz4 reset, level %v: %v allocations leaked", int(setup.lz4_level), len(track.allocation_map))
}

codec_writer_check :: proc(t: ^testing.T, label: string, codec: Codec, data: []byte, pattern: Write_Pattern, setup: Codec_Writer_Setup) {
	want: [dynamic]byte
	defer delete(want)
	codec_writer_oneshot(codec, data, setup, &want)

	got: [dynamic]byte
	defer delete(got)
	aw := Append_Writer{out = &got, fail_at = -1}
	err := codec_writer_pack(codec, append_writer(&aw), data, pattern, setup)
	testing.expectf(t, err == nil, "%v, %v, %v bytes, %v, %v: %v", label, codec, len(data), pattern, int(setup.lz4_level) if codec == .LZ4 else int(setup.bzip2_level), err)
	testing.expectf(t, bytes.equal(got[:], want[:]), "%v, %v, %v bytes, %v, level %v, %v: output differs, %v vs %v bytes", label, codec, len(data), pattern, int(setup.lz4_level) if codec == .LZ4 else int(setup.bzip2_level), setup.frame_options, len(got), len(want))
}
