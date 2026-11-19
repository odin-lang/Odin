package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/lzma"
import "core:io"
import "core:math/rand"
import "core:mem"
import "core:testing"

LZMA_WRITER_FUZZ  :: #config(LZMA_WRITER_FUZZ, 16)
LZMA_WRITER_STEP  :: (1 << 17) + 4 * 2048
LZMA2_WRITER_STEP :: (1 << 21) + 4 * 2048

Lzma_Writer_Setup :: struct {
	kind:       Lzma_Stream_Kind,
	level:      lzma.Level,
	options:    lzma.Options,
	input_size: i64,
	stream:     compress.Options,
}

@(test)
lzma_writer_identity :: proc(t: ^testing.T) {
	match := stream_match_data()
	defer delete(match)
	g := Lz4_Test_Lcg{state = 0x57524954}
	random := lz4_test_lcg_bytes(&g, 150_000)
	defer delete(random)
	runs := codec_runs_data(700_000)
	defer delete(runs)
	text := lz4_test_lcg_text(&g, 300_000)
	defer delete(text)

	inputs := [][]byte{match, random, runs, text, {}, {7}, text[:5], runs[:LZMA_WRITER_STEP], runs[:LZMA_WRITER_STEP + 1]}
	for input in inputs {
		for kind in Lzma_Stream_Kind {
			for level in ([]lzma.Level{.Level_0, .Level_3, .Level_5}) {
				options := lzma.level_options(level)
				options.dict_size = 4096 if level == .Level_0 else 64 << 10
				for pattern in Write_Pattern {
					if pattern == .Bytes && len(input) > 200_000 {
						continue
					}
					lzma_writer_check(t, "identity", {kind = kind, level = level, options = options, input_size = i64(len(input))}, input, pattern)
				}
			}
		}
	}

	big: [dynamic]byte
	defer delete(big)
	for len(big) < 5 << 20 {
		append(&big, ..text)
		append(&big, ..random)
		append(&big, ..runs)
	}
	for kind in Lzma_Stream_Kind {
		options := lzma.level_options(.Level_1)
		options.dict_size = 4096
		lzma_writer_check(t, "big", {kind = kind, level = .Level_1, options = options, input_size = i64(len(big))}, big[:], .Random)
		lzma_writer_check(t, "big", {kind = kind, level = .Level_1, options = options, input_size = -1}, big[:], .Edges)
	}
}

@(test)
lzma_writer_unknown_size :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	for input in ([][]byte{inputs.mixed, inputs.text, inputs.random[:100], {}}) {
		for kind in Lzma_Stream_Kind {
			for dict in ([]u32{4096, 1 << 20}) {
				options := lzma.level_options(.Level_4)
				options.dict_size = dict
				lzma_writer_check(t, "unknown", {kind = kind, level = .Level_4, options = options, input_size = -1}, input, .Random)
			}
		}
	}

	packed: [dynamic]byte
	defer delete(packed)
	aw := Append_Writer{out = &packed, fail_at = -1}
	_, err := lzma_writer_pack({kind = .Alone, level = .Level_2, input_size = -1}, append_writer(&aw), inputs.text, .Whole)
	testing.expect_value(t, err, nil)
	if testing.expect(t, len(packed) > 13) {
		testing.expect(t, bytes.equal(packed[5:13], []byte{0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff}))
	}
}

@(test)
lzma_writer_memory :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0x4d454d}
	text := lz4_test_lcg_text(&g, 200_000)
	defer delete(text)
	data: [dynamic]byte
	defer delete(data)
	for len(data) < 6 << 20 {
		append(&data, ..text)
		append(&data, u8(len(data)), u8(len(data) >> 8), u8(len(data) >> 16))
	}

	options := lzma.level_options(.Level_1)
	options.dict_size = 64 << 10
	for kind in Lzma_Stream_Kind {
		setup := Lzma_Writer_Setup{kind = kind, level = .Level_1, options = options, input_size = 3 << 20}
		lo, hi := 1, 64 << 20
		for hi - lo > 1 {
			mid := lo + (hi - lo) / 2
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			probe := setup
			probe.input_size = -1
			probe.stream     = {max_memory = mid}
			if _, err := lzma_writer_pack(probe, append_writer(&aw), nil, .Whole); err == nil {
				hi = mid
			} else {
				testing.expect_value(t, err, compress.Error(compress.General_Error.Memory_Limit_Exceeded))
				lo = mid
			}
		}

		peaks: [2]int
		for size, i in ([2]int{3 << 20, len(data)}) {
			track: mem.Tracking_Allocator
			mem.tracking_allocator_init(&track, context.allocator)
			defer mem.tracking_allocator_destroy(&track)

			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			lw: lzma.Writer
			err: compress.Error
			stream := compress.Options{max_memory = hi}
			switch kind {
			case .Alone: err = lzma.writer_init(&lw, append_writer(&aw), .Level_1, i64(size), stream, mem.tracking_allocator(&track))
			case .Raw:   _, err = lzma.writer_init_raw(&lw, append_writer(&aw), options, i64(size), stream, mem.tracking_allocator(&track))
			case .LZMA2: _, err = lzma.writer_init_lzma2(&lw, append_writer(&aw), options, i64(size), stream, mem.tracking_allocator(&track))
			}
			if testing.expectf(t, err == nil, "%v init: %v", kind, err) {
				rest := data[:size]
				for len(rest) > 0 && err == nil {
					k := min(len(rest), 1 + rand.int_max(100_000))
					_, err = lzma.writer_write(&lw, rest[:k])
					rest = rest[k:]
				}
				if err == nil {
					err = lzma.writer_finish(&lw)
				}
				testing.expectf(t, err == nil, "%v, %v bytes: %v", kind, size, err)
			}
			lzma.writer_destroy(&lw)
			peaks[i] = int(track.peak_memory_allocated)
			testing.expectf(t, len(track.allocation_map) == 0, "%v: %v allocations leaked", kind, len(track.allocation_map))
		}
		testing.expectf(t, peaks[0] == peaks[1] && peaks[1] <= hi, "%v: peak %v bytes for 3 MiB, %v bytes for %v, limit %v", kind, peaks[0], peaks[1], len(data), hi)
	}

	sink: [dynamic]byte
	defer delete(sink)
	aw := Append_Writer{out = &sink, fail_at = -1}
	lw: lzma.Writer
	testing.expect_value(t, lzma.writer_init(&lw, append_writer(&aw), .Level_6, -1, {max_memory = 1 << 20}), compress.Error(compress.General_Error.Memory_Limit_Exceeded))
	lzma.writer_destroy(&lw)
}

@(test)
lzma_writer_shrink :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0x5348524b}
	text := lz4_test_lcg_text(&g, 100_000)
	defer delete(text)
	data: [dynamic]byte
	defer delete(data)
	for len(data) < (3 << 19 if !SLIM_TESTS else 1 << 18) {
		append(&data, ..text)
		append(&data, u8(len(data)), u8(len(data) >> 8), u8(len(data) >> 16))
	}

	for kind in Lzma_Stream_Kind {
		for use_buffer in ([]bool{false, true}) {
			level   := lzma.Level.Level_9 if !use_buffer else lzma.Level.Level_6
			options := lzma.level_options(level)
			setup   := Lzma_Writer_Setup{kind = kind, level = level, options = options, input_size = -1, stream = {max_memory = 8 << 20}}
			if use_buffer {
				setup.stream = {buffer = make([]byte, 3 << 20, context.temp_allocator)}
			}

			track: mem.Tracking_Allocator
			mem.tracking_allocator_init(&track, context.allocator)
			defer mem.tracking_allocator_destroy(&track)
			got: [dynamic]byte
			defer delete(got)
			aw := Append_Writer{out = &got, fail_at = -1}
			props: lzma.Properties
			err: compress.Error
			{
				context.allocator = mem.tracking_allocator(&track)
				props, err = lzma_writer_pack(setup, append_writer(&aw), data[:], .Random)
			}
			if !testing.expectf(t, err == nil, "%v, buffer %v: %v", kind, use_buffer, err) {
				continue
			}
			if kind == .Alone && testing.expect(t, len(got) >= lzma.HEADER_SIZE) {
				props.dict_size = u32(got[1]) | u32(got[2]) << 8 | u32(got[3]) << 16 | u32(got[4]) << 24
			}
			series, _ := lzma.lzma2_dict_size(lzma.lzma2_dict_prop(props.dict_size))
			testing.expectf(t, props.dict_size >= lzma.DICT_SIZE_MIN && props.dict_size < options.dict_size && series == props.dict_size, "%v, buffer %v: dictionary %v, level %v", kind, use_buffer, props.dict_size, options.dict_size)
			if !use_buffer {
				testing.expectf(t, int(track.peak_memory_allocated) <= setup.stream.max_memory, "%v: peak %v, limit %v", kind, track.peak_memory_allocated, setup.stream.max_memory)
			}

			out: [dynamic]byte
			defer delete(out)
			switch kind {
			case .Alone: err = lzma.decompress(&out, got[:])
			case .Raw:   err = lzma.decompress_raw(&out, got[:], props, len(data))
			case .LZMA2: err = lzma.decompress_lzma2(&out, got[:], props.dict_size)
			}
			testing.expectf(t, err == nil && bytes.equal(out[:], data[:]), "%v, buffer %v: round trip %v, %v bytes", kind, use_buffer, err, len(out))
		}
	}
}

@(test)
lzma_writer_buffer :: proc(t: ^testing.T) {
	runs := codec_runs_data(900_000)
	defer delete(runs)
	options := lzma.level_options(.Level_3)
	options.dict_size = 4096

	for kind in ([]Lzma_Stream_Kind{.Raw, .LZMA2}) {
		step := LZMA2_WRITER_STEP if kind == .LZMA2 else LZMA_WRITER_STEP
		need := 4096 + 2048 + 1 + step + 128
		for size in ([]int{need - 1, need, need + 5000, 3 * need}) {
			buffer := make([]byte, size)
			defer delete(buffer)
			setup := Lzma_Writer_Setup{kind = kind, level = .Level_3, options = options, input_size = i64(len(runs)), stream = {buffer = buffer}}
			if size < need {
				sink: [dynamic]byte
				defer delete(sink)
				aw := Append_Writer{out = &sink, fail_at = -1}
				_, err := lzma_writer_pack(setup, append_writer(&aw), runs, .Whole)
				testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v, buffer %v: %v", kind, size, err)
				continue
			}
			lzma_writer_check(t, "buffer", setup, runs, .Random)
			lzma_writer_check(t, "buffer", setup, runs, .Edges)
		}
	}
}

@(test)
lzma_writer_failures :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	data := inputs.mixed
	options := lzma.level_options(.Level_2)

	for kind in Lzma_Stream_Kind {
		setup := Lzma_Writer_Setup{kind = kind, level = .Level_2, options = options, input_size = i64(len(data))}
		want: [dynamic]byte
		defer delete(want)
		lzma_writer_oneshot(setup, data, &want)

		for fail_at in ([]int{0, 1, 13, len(want) / 2, len(want) - 1}) {
			output: [dynamic]byte
			defer delete(output)
			aw := Append_Writer{out = &output, fail_at = fail_at}
			_, err := lzma_writer_pack(setup, append_writer(&aw), data, .Random)
			testing.expectf(t, err == io.Error.Short_Write, "%v, fail at %v: %v", kind, fail_at, err)
			testing.expectf(t, bytes.equal(output[:], want[:fail_at]), "%v, fail at %v: %v bytes", kind, fail_at, len(output))
		}

		for stream in ([]compress.Options{{max_memory = -1}, {chunk_size = -1}, {max_output_size = -1}, {progress_interval = -1}, {buffer = make([]byte, 1000, context.temp_allocator)}}) {
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			bad := setup
			bad.stream = stream
			_, err := lzma_writer_pack(bad, append_writer(&aw), data, .Whole)
			testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v, %v: %v", kind, stream.max_memory, err)
			testing.expectf(t, len(sink) == 0, "%v: %v bytes written by a failed init", kind, len(sink))
		}

		if kind != .Alone {
			for bad_options in ([]lzma.Options{{lc = 9}, {lp = 5}, {pb = 5}, {lc = 3, lp = 2}}) {
				if kind == .Raw && bad_options.lc + bad_options.lp == 5 {
					continue
				}
				sink: [dynamic]byte
				defer delete(sink)
				aw := Append_Writer{out = &sink, fail_at = -1}
				bad := setup
				bad.options = bad_options
				_, err := lzma_writer_pack(bad, append_writer(&aw), data, .Whole)
				testing.expectf(t, err == compress.LZMA_Error.Invalid_Properties, "%v, %v: %v", kind, bad_options, err)
			}
		}

		{
			sink: [dynamic]byte
			defer delete(sink)
			aw := Append_Writer{out = &sink, fail_at = -1}
			lw: lzma.Writer
			defer lzma.writer_destroy(&lw)
			lzma_writer_init(t, &lw, append_writer(&aw), {kind = kind, level = .Level_2, options = options, input_size = 100})
			n, err := lzma.writer_write(&lw, data[:101])
			testing.expectf(t, n == 0 && err == compress.General_Error.Size_Mismatch, "%v: too much data gave %v, %v", kind, n, err)
			testing.expect_value(t, lzma.writer_finish(&lw), compress.Error(compress.General_Error.Size_Mismatch))
			n, err = lzma.writer_write(&lw, data[:1])
			testing.expectf(t, n == 0 && err == compress.General_Error.Size_Mismatch, "%v: write after an error gave %v, %v", kind, n, err)
			lzma.writer_destroy(&lw)

			lzma_writer_init(t, &lw, append_writer(&aw), {kind = kind, level = .Level_2, options = options, input_size = 100})
			_, err = lzma.writer_write(&lw, data[:99])
			testing.expect_value(t, err, nil)
			testing.expect_value(t, lzma.writer_finish(&lw), compress.Error(compress.General_Error.Size_Mismatch))
			lzma.writer_destroy(&lw)

			lzma_writer_init(t, &lw, append_writer(&aw), {kind = kind, level = .Level_2, options = options, input_size = 100})
			_, err = lzma.writer_write(&lw, data[:60])
			testing.expect_value(t, err, nil)
			_, err = lzma.writer_write(&lw, data[60:100])
			testing.expect_value(t, err, nil)
			testing.expect_value(t, lzma.writer_finish(&lw), nil)
			testing.expect_value(t, lzma.writer_finish(&lw), nil)
			n, err = lzma.writer_write(&lw, data[:1])
			testing.expectf(t, n == 0 && err == io.Error.Closed, "%v: write after finish gave %v, %v", kind, n, err)
		}
	}
	free_all(context.temp_allocator)
}

@(test)
lzma_writer_progress :: proc(t: ^testing.T) {
	runs := codec_runs_data(5_000_000)
	defer delete(runs)
	options := lzma.level_options(.Level_1)
	options.dict_size = 64 << 10

	for kind in Lzma_Stream_Kind {
		for cancel in ([2]int{0, 2}) {
			calls := Lzma_Stream_Calls{monotonic = true, cancel_at = cancel}
			setup := Lzma_Writer_Setup{kind = kind, level = .Level_1, options = options, input_size = i64(len(runs)), stream = {progress = lzma_stream_progress, progress_data = &calls}}
			packed: [dynamic]byte
			defer delete(packed)
			aw := Append_Writer{out = &packed, fail_at = -1}
			lw: lzma.Writer
			defer lzma.writer_destroy(&lw)
			lzma_writer_init(t, &lw, append_writer(&aw), setup)
			err: compress.Error
			rest := runs[:]
			for len(rest) > 0 && err == nil {
				k := min(len(rest), 1 + rand.int_max(300_000))
				_, err = lzma.writer_write(&lw, rest[:k])
				rest = rest[k:]
			}
			if err == nil {
				err = lzma.writer_finish(&lw)
			}
			if cancel == 0 {
				testing.expectf(t, err == nil, "%v: %v", kind, err)
				testing.expectf(t, calls.calls > 2, "%v: %d calls", kind, calls.calls)
				testing.expect_value(t, calls.last_in, i64(len(runs)))
				testing.expect_value(t, calls.last_out, i64(len(packed)))
			} else {
				testing.expectf(t, err == compress.General_Error.Canceled, "%v: %v", kind, err)
				testing.expect_value(t, calls.calls, cancel)
				testing.expect_value(t, lzma.writer_finish(&lw), compress.Error(compress.General_Error.Canceled))
			}
			testing.expectf(t, calls.monotonic, "%v: progress went backwards", kind)
		}
	}
}

@(test)
lzma_writer_as_stream :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	options := lzma.level_options(.Level_4)

	for kind in Lzma_Stream_Kind {
		setup := Lzma_Writer_Setup{kind = kind, level = .Level_4, options = options, input_size = i64(len(data))}
		want: [dynamic]byte
		defer delete(want)
		lzma_writer_oneshot(setup, data, &want)

		output: [dynamic]byte
		defer delete(output)
		aw := Append_Writer{out = &output, fail_at = -1}
		lw := new(lzma.Writer)
		defer free(lw)
		lzma_writer_init(t, lw, append_writer(&aw), setup)
		stream := lzma.writer_to_stream(lw)
		testing.expect_value(t, io.query(stream), io.Stream_Mode_Set{.Write, .Close, .Destroy, .Query})
		rest := data
		for len(rest) > 0 {
			k := min(len(rest), 1 + rand.int_max(50_000))
			n, err := io.write(stream, rest[:k])
			testing.expectf(t, n == k && err == nil, "%v: write gave %v, %v", kind, n, err)
			rest = rest[k:]
		}
		testing.expect_value(t, io.close(stream), nil)
		testing.expectf(t, bytes.equal(output[:], want[:]), "%v: %v vs %v bytes", kind, len(output), len(want))
		io.destroy(stream)
	}
}

@(test)
lzma_writer_fuzz :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	for _ in 0..<LZMA_WRITER_FUZZ {
		data: [dynamic]byte
		defer delete(data)
		d64_test_data(rand.int_max(4), rand.int_max(1_500_000), &data)

		dicts   := [4]u32{4096, 5000, 64 << 10, 1 << 20}
		level   := lzma.Level(rand.int_max(10))
		options := lzma.level_options(level)
		options.lc = u8(rand.int_max(5))
		options.lp = u8(rand.int_max(5 - int(options.lc)))
		options.pb = u8(rand.int_max(5))
		options.dict_size    = dicts[rand.int_max(len(dicts))]
		options.match_finder = lzma.Match_Finder_Kind(rand.int_max(len(lzma.Match_Finder_Kind)))
		options.nice_len     = u32(5 + rand.int_max(269))
		options.fast         = rand.int_max(3) == 0
		options.depth        = u32(rand.int_max(64))
		options.end_marker   = rand.int_max(2) == 0

		setup := Lzma_Writer_Setup{
			kind       = Lzma_Stream_Kind(rand.int_max(len(Lzma_Stream_Kind))),
			level      = level if level <= .Level_5 else .Level_5,
			options    = options,
			input_size = i64(len(data)) if rand.int_max(4) != 0 else -1,
		}
		pattern := Write_Pattern(rand.int_max(len(Write_Pattern)))
		if pattern == .Bytes && len(data) > 50_000 {
			pattern = .Random
		}
		lzma_writer_check(t, "fuzz", setup, data[:], pattern)
	}
}

lzma_writer_sizes :: proc(pattern: Write_Pattern, n: int) -> int {
	if pattern != .Edges {
		return codec_pattern_sizes(pattern, n)
	}
	edges := [?]int{LZMA_WRITER_STEP - 1, LZMA_WRITER_STEP, LZMA_WRITER_STEP + 1, LZMA2_WRITER_STEP - 1, LZMA2_WRITER_STEP + 1, 1, 0, 2048, 65536, 300_001}
	return edges[rand.int_max(len(edges))]
}

lzma_writer_oneshot :: proc(setup: Lzma_Writer_Setup, data: []byte, output: ^[dynamic]byte) -> (props: lzma.Properties, err: compress.Error) {
	switch setup.kind {
	case .Alone: err = lzma.compress(output, data, setup.level)
	case .Raw:   props, err = lzma.compress_raw(output, data, setup.options)
	case .LZMA2: props, err = lzma.compress_lzma2(output, data, setup.options)
	}
	return
}

lzma_writer_init :: proc(t: ^testing.T, lw: ^lzma.Writer, w: io.Writer, setup: Lzma_Writer_Setup, loc := #caller_location) -> (props: lzma.Properties) {
	err: compress.Error
	switch setup.kind {
	case .Alone: err = lzma.writer_init(lw, w, setup.level, setup.input_size, setup.stream)
	case .Raw:   props, err = lzma.writer_init_raw(lw, w, setup.options, setup.input_size, setup.stream)
	case .LZMA2: props, err = lzma.writer_init_lzma2(lw, w, setup.options, setup.input_size, setup.stream)
	}
	testing.expectf(t, err == nil, "%v init: %v", setup.kind, err, loc = loc)
	return
}

lzma_writer_pack :: proc(setup: Lzma_Writer_Setup, w: io.Writer, data: []byte, pattern: Write_Pattern) -> (props: lzma.Properties, err: compress.Error) {
	lw := new(lzma.Writer)
	defer free(lw)
	switch setup.kind {
	case .Alone: err = lzma.writer_init(lw, w, setup.level, setup.input_size, setup.stream)
	case .Raw:   props, err = lzma.writer_init_raw(lw, w, setup.options, setup.input_size, setup.stream)
	case .LZMA2: props, err = lzma.writer_init_lzma2(lw, w, setup.options, setup.input_size, setup.stream)
	}
	defer lzma.writer_destroy(lw)
	if err != nil {
		return
	}
	rest := data
	for len(rest) > 0 {
		k := min(lzma_writer_sizes(pattern, len(rest)), len(rest))
		n: int
		n, err = lzma.writer_write(lw, rest[:k])
		if err != nil {
			return
		}
		if n != k {
			return props, compress.General_Error.Output_Too_Short
		}
		rest = rest[k:]
	}
	err = lzma.writer_finish(lw)
	return
}

lzma_writer_check :: proc(t: ^testing.T, label: string, setup: Lzma_Writer_Setup, data: []byte, pattern: Write_Pattern, loc := #caller_location) {
	got: [dynamic]byte
	defer delete(got)
	aw := Append_Writer{out = &got, fail_at = -1}
	props, err := lzma_writer_pack(setup, append_writer(&aw), data, pattern)
	if !testing.expectf(t, err == nil, "%v, %v, %v bytes, size %v, %v, %v: %v", label, setup.kind, len(data), setup.input_size, pattern, setup.options, err, loc = loc) {
		return
	}

	dict := lzma.level_options(setup.level).dict_size if setup.kind == .Alone else setup.options.dict_size
	if setup.input_size >= 0 || (setup.kind != .Alone && u64(len(data)) >= u64(dict)) {
		want: [dynamic]byte
		defer delete(want)
		want_props, want_err := lzma_writer_oneshot(setup, data, &want)
		testing.expectf(t, want_err == nil && props == want_props && bytes.equal(got[:], want[:]), "%v, %v, %v bytes, size %v, %v, %v: output differs, %v vs %v bytes", label, setup.kind, len(data), setup.input_size, pattern, setup.options, len(got), len(want), loc = loc)
	}

	out: [dynamic]byte
	defer delete(out)
	switch setup.kind {
	case .Alone: err = lzma.decompress(&out, got[:])
	case .Raw:   err = lzma.decompress_raw(&out, got[:], props, len(data))
	case .LZMA2: err = lzma.decompress_lzma2(&out, got[:], props.dict_size)
	}
	testing.expectf(t, err == nil && bytes.equal(out[:], data), "%v, %v, %v bytes, size %v, %v: round trip %v, %v bytes", label, setup.kind, len(data), setup.input_size, pattern, err, len(out), loc = loc)
}
