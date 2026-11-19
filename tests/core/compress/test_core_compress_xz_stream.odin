package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/xz"
import "core:fmt"
import "core:io"
import "core:math/rand"
import "core:os"
import "core:strings"
import "core:testing"

@(test)
test_xz_stream_differential :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	sources := [?][]u8{{}, {'A'}, inputs.text, inputs.random, inputs.repeat, inputs.mixed, inputs.chunks}
	option_sets := xz_stream_option_sets()
	for source in sources {
		for options, i in option_sets {
			packed: [dynamic]u8
			defer delete(packed)
			if !testing.expectf(t, xz.compress(&packed, source, .Level_1, options) == nil, "options %d: compress", i) {
				continue
			}
			xz_stream_expect_all(t, packed[:], source, fmt.tprintf("options %d, %d bytes", i, len(source)))
		}
	}
}

@(test)
test_xz_stream_blocks_and_streams :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	big: [dynamic]u8
	defer delete(big)
	for len(big) < (5 << 20) / 2 {
		append(&big, ..inputs.mixed)
	}
	packed: [dynamic]u8
	defer delete(packed)
	if testing.expect_value(t, xz.compress(&packed, big[:], .Level_1, {block_size = 1 << 20, check = .CRC32}), nil) {
		xz_stream_expect_all(t, packed[:], big[:], "three blocks")
	}

	option_sets := xz_stream_option_sets()
	concat, want: [dynamic]u8
	defer delete(concat)
	defer delete(want)
	for source, i in ([?][]u8{inputs.text, {}, inputs.mixed, inputs.chunks}) {
		part: [dynamic]u8
		defer delete(part)
		if !testing.expect_value(t, xz.compress(&part, source, .Level_1, option_sets[i + 2]), nil) {
			return
		}
		append(&concat, ..part[:])
		for _ in 0..<4 * i {
			append(&concat, 0)
		}
		append(&want, ..source)
	}
	xz_stream_expect_all(t, concat[:], want[:], "four streams, padded")
}

@(test)
test_xz_stream_corpus :: proc(t: ^testing.T) {
	for dir in ([?]string{"", "xz-utils/"}) {
		entries, dir_err := os.read_all_directory_by_path(xz_asset(dir), context.temp_allocator)
		if !testing.expectf(t, dir_err == nil, "%s: %v", dir, dir_err) {
			continue
		}
		for e in entries {
			if !strings.has_suffix(e.name, ".xz") {
				continue
			}
			data, read_err := os.read_entire_file(e.fullpath, context.allocator)
			if !testing.expectf(t, read_err == nil, "%s: %v", e.name, read_err) {
				continue
			}
			defer delete(data)
			want: [dynamic]u8
			defer delete(want)
			want_err := xz.decompress(&want, data)
			for streamed in ([2]bool{false, true}) {
				for read_size in ([?]int{0, 1, 4096, -1}) {
					if read_size == 1 && len(want) > 1 << 18 {
						continue
					}
					out, err := xz_stream_decode(data, {}, -1, {}, streamed, read_size)
					if err == compress.General_Error.Memory_Limit_Exceeded && strings.contains(e.name, "dict-") {
						delete(out)
						continue
					}
					testing.expectf(t, err == want_err, "%s, read %d, streamed %v: %v, want %v", e.name, read_size, streamed, err, want_err)
					if err == nil && want_err == nil {
						testing.expectf(t, bytes.equal(out[:], want[:]), "%s, read %d, streamed %v: %d of %d bytes", e.name, read_size, streamed, len(out), len(want))
					} else {
						testing.expectf(t, len(out) <= len(want) || want_err != nil, "%s: %d bytes out", e.name, len(out))
					}
					delete(out)
				}
			}
		}
	}
}

@(test)
test_xz_stream_errors :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	option_sets := xz_stream_option_sets()
	for options, i in option_sets {
		packed: [dynamic]u8
		defer delete(packed)
		if !testing.expect_value(t, xz.compress(&packed, inputs.mixed, .Level_1, options), nil) {
			continue
		}
		for n := 0; n < len(packed); n += max(1, len(packed) / 151) {
			xz_stream_expect_parity(t, packed[:n], i, n, -1)
		}
		for n in len(packed) - 64 ..< len(packed) {
			xz_stream_expect_parity(t, packed[:n], i, n, -1)
		}
		mutated := make([]u8, len(packed))
		defer delete(mutated)
		for _ in 0..<300 {
			copy(mutated, packed[:])
			at := rand.int_max(len(mutated))
			if rand.int_max(2) == 0 {
				at = len(mutated) - 1 - rand.int_max(min(len(mutated), 96))
			}
			mutated[at] ~= u8(1 << uint(rand.int_max(8)))
			xz_stream_expect_parity(t, mutated, i, -1, at)
		}
		for _ in 0..<300 {
			copy(mutated, packed[:])
			at := rand.int_max(len(mutated))
			mutated[at] ~= u8(1 << uint(rand.int_max(8)))
			cut := at + rand.int_max(len(mutated) - at)
			xz_stream_expect_agreement(t, mutated[:cut], i, cut, at)
		}
	}
}

@(test)
test_xz_stream_short_chunk_truncated :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	options := xz.level_options(.Level_1)
	options.check = .None
	packed: [dynamic]u8
	defer delete(packed)
	if !testing.expect_value(t, xz.compress(&packed, inputs.mixed, .Level_1, options), nil) {
		return
	}
	at := xz.HEADER_SIZE + (int(packed[xz.HEADER_SIZE]) + 1) * 4
	if !testing.expectf(t, packed[at] >= 0xE0, "first chunk control %x", packed[at]) {
		return
	}
	packed[at + 3], packed[at + 4] = 0, 15
	for cut in ([?]int{at + 64, at + 1024, len(packed) - 64, len(packed)}) {
		xz_stream_expect_agreement(t, packed[:cut], 0, cut, at)
		out, err := xz_stream_decode(packed[:cut], {}, -1, {}, true, 4096)
		testing.expectf(t, err == compress.Error(compress.General_Error.Size_Mismatch), "cut %d: %v", cut, err)
		delete(out)
	}
}

@(test)
test_xz_stream_limits :: proc(t: ^testing.T) {
	data, read_err := os.read_entire_file(xz_asset("text.check-crc64.xz"), context.allocator)
	if !testing.expect_value(t, read_err, nil) {
		return
	}
	defer delete(data)
	GE  :: compress.General_Error
	XZE :: compress.XZ_Error
	for streamed in ([2]bool{false, true}) {
		for read_size in ([?]int{0, 4096}) {
			out, err := xz_stream_decode(data, {}, -1, {max_output_size = 80_000}, streamed, read_size)
			testing.expect_value(t, err, nil)
			testing.expect_value(t, len(out), 80_000)
			delete(out)

			out, err = xz_stream_decode(data, {}, -1, {max_output_size = 79_999}, streamed, read_size)
			testing.expect_value(t, err, compress.Error(GE.Output_Too_Short))
			testing.expectf(t, len(out) <= 79_999, "%d bytes past the limit", len(out))
			delete(out)

			out, err = xz_stream_decode(data, {}, 80_001, {}, streamed, read_size)
			testing.expect_value(t, err, compress.Error(GE.Size_Mismatch))
			delete(out)

			out, err = xz_stream_decode(data, {}, 79_999, {}, streamed, read_size)
			testing.expect_value(t, err, compress.Error(GE.Size_Mismatch))
			delete(out)

			out, err = xz_stream_decode(data, {}, 80_001, {max_output_size = 80_000}, streamed, read_size)
			testing.expect_value(t, err, compress.Error(GE.Output_Too_Short))
			delete(out)

			out, err = xz_stream_decode(data, {}, -1, {max_output_size = -1}, streamed, read_size)
			testing.expect_value(t, err, compress.Error(GE.Incompatible_Options))
			delete(out)
		}
	}

	check_at := xz_check_offset(data)
	if !testing.expect(t, check_at > 0, "no check found") {
		return
	}
	data[check_at] ~= 0x01
	defer data[check_at] ~= 0x01
	out, err := xz_stream_decode(data, {}, -1, {}, true, 4096)
	testing.expect_value(t, err, compress.Error(XZE.Block_Checksum_Failed))
	testing.expect_value(t, len(out), 80_000)
	delete(out)
	out, err = xz_stream_decode(data, {.Ignore_Check}, -1, {}, true, 4096)
	testing.expect_value(t, err, nil)
	testing.expect(t, len(out) == 80_000, "ignored check")
	delete(out)
}

@(test)
test_xz_stream_index_vli_at_end :: proc(t: ^testing.T) {
	empty: [dynamic]u8
	defer delete(empty)
	if !testing.expect_value(t, xz.compress(&empty, nil), nil) {
		return
	}
	GE  :: compress.General_Error
	XZE :: compress.XZ_Error
	Case :: struct {
		tail: []u8,
		err:  compress.Error,
	}
	cases := [?]Case{
		{{0x00}, GE.Stream_Too_Short},
		{{0x00, 0x80}, GE.Stream_Too_Short},
		{{0x00, 0x80, 0x00}, XZE.Invalid_Index},
		{{0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80}, XZE.Invalid_Index},
		{{0x00, 0x01}, XZE.Index_Mismatch},
	}
	for c in cases {
		input: [dynamic]u8
		defer delete(input)
		append(&input, ..empty[:xz.HEADER_SIZE])
		append(&input, ..c.tail)
		out: [dynamic]u8
		err := xz.decompress(&out, input[:])
		delete(out)
		testing.expectf(t, err == c.err, "% x: one-shot %v, want %v", c.tail, err, c.err)
		for streamed in ([2]bool{false, true}) {
			stream_out, stream_err := xz_stream_decode(input[:], {}, -1, {}, streamed, 4096)
			delete(stream_out)
			testing.expectf(t, stream_err == c.err, "% x: stream %v, want %v", c.tail, stream_err, c.err)
		}
	}
}

@(test)
test_xz_stream_window_bounded :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	big: [dynamic]u8
	defer delete(big)
	for len(big) < 3 << 20 {
		append(&big, ..inputs.mixed)
	}
	packed: [dynamic]u8
	defer delete(packed)
	level := xz.level_options(.Level_1)
	level.lzma2.dict_size = 64 * 1024
	level.block_size      = 1 << 20
	level.check           = .SHA256
	level.filter_count    = 1
	level.filters[0]      = {id = .Delta, delta_distance = 4}
	if !testing.expect_value(t, xz.compress(&packed, big[:], .Level_1, level), nil) {
		return
	}

	data := packed[:]
	reader: bytes.Reader
	z := compress.init_context_from_stream(bytes.reader_init(&reader, data))
	defer compress.destroy_context(&z)
	r: xz.Reader
	defer xz.reader_destroy(&r)
	if !testing.expect_value(t, xz.reader_init(&r, &z, {}, -1, {chunk_size = 4096}), nil) {
		return
	}
	largest  := 0
	produced := 0
	same     := true
	buf: [5000]u8
	for {
		n, err := xz.reader_read(&r, buf[:])
		if !bytes.equal(buf[:n], big[produced:][:n]) {
			same = false
		}
		produced += n
		if r.in_block {
			largest = max(largest, cap(r.lzma.window))
		}
		if err == io.Error.EOF {
			break
		}
		if !testing.expect_value(t, err, nil) {
			return
		}
	}
	testing.expect(t, same && produced == len(big), "bounded decode differs")
	testing.expectf(t, largest <= 64 * 1024 + 16 * 1024, "window grew to %d", largest)
}

@(test)
test_xz_writer_round_trip :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	big: [dynamic]u8
	defer delete(big)
	for len(big) < 3 << 20 {
		append(&big, ..inputs.mixed)
	}
	sources := [?][]u8{{}, {'A'}, inputs.random, inputs.mixed}
	option_sets := xz_stream_option_sets()
	for options, i in option_sets {
		for source in sources {
			for block_size in ([?]int{0, 16 * 1024, 4096 + 1, -1}) {
				for write_size in ([?]int{0, 1000, -1}) {
					opts := options
					opts.block_size = block_size
					label := fmt.tprintf("options %d, %d bytes, block %d, write %d", i, len(source), block_size, write_size)
					xz_writer_expect_round_trip(t, source, opts, write_size, label)
				}
			}
		}
	}
	xz_writer_expect_round_trip(t, big[:], {}, -1, "big")
}

@(test)
test_xz_writer_errors :: proc(t: ^testing.T) {
	GE  :: compress.General_Error
	XZE :: compress.XZ_Error
	sink: bytes.Buffer
	defer bytes.buffer_destroy(&sink)
	s := bytes.buffer_to_stream(&sink)
	xw: xz.Writer
	testing.expect_value(t, xz.writer_init(&xw, s, .Level_1, {filter_count = 4}), compress.Error(XZE.Invalid_Filter_Chain))
	testing.expect_value(t, xz.writer_init(&xw, s, .Level_1, {filter_count = 1, filters = {0 = {id = .LZMA2}}}), compress.Error(XZE.Invalid_Filter_Chain))
	testing.expect_value(t, xz.writer_init(&xw, s, .Level_1, {check = xz.Check(2)}), compress.Error(GE.Incompatible_Options))
	testing.expect_value(t, xz.writer_init(&xw, s, .Level_1, {}, {chunk_size = -1}), compress.Error(GE.Incompatible_Options))
	testing.expect_value(t, xz.writer_init(&xw, s, .Level_1, {}, {max_memory = 1024}), compress.Error(GE.Memory_Limit_Exceeded))
	testing.expect_value(t, bytes.buffer_length(&sink), 0)

	if testing.expect_value(t, xz.writer_init(&xw, s, .Level_1), nil) {
		n, err := xz.writer_write(&xw, transmute([]u8)string("abc"))
		testing.expect_value(t, n, 3)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, xz.writer_finish(&xw), nil)
		testing.expect_value(t, xz.writer_finish(&xw), nil)
		n, err = xz.writer_write(&xw, transmute([]u8)string("d"))
		testing.expect_value(t, err, compress.Error(io.Error.Closed))
		xz.writer_destroy(&xw)
		out, decode_err := xz_stream_decode(bytes.buffer_to_bytes(&sink), {}, -1, {}, true, 0)
		testing.expect_value(t, decode_err, nil)
		testing.expect_value(t, string(out[:]), "abc")
		delete(out)
	}

	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	for limit in ([?]int{0, 5, 12, 13, 40, 200}) {
		fail := Xz_Fail_Sink{limit = limit}
		err := xz.writer_init(&xw, {data = &fail, procedure = xz_fail_sink_proc}, .Level_1)
		if err == nil {
			_, err = xz.writer_write(&xw, inputs.mixed)
			if err == nil {
				err = xz.writer_finish(&xw)
			}
			testing.expectf(t, xz.writer_finish(&xw) == err, "limit %d: error not kept", limit)
			xz.writer_destroy(&xw)
		}
		testing.expectf(t, err == compress.Error(io.Error.Short_Write), "limit %d: %v", limit, err)
	}

	cancel := proc(progress: compress.Progress, data: rawptr) -> bool {
		return progress.bytes_in >= 50_000
	}
	bytes.buffer_reset(&sink)
	if testing.expect_value(t, xz.writer_init(&xw, s, .Level_1, {}, {progress = cancel, progress_interval = 1}), nil) {
		_, err := xz.writer_write(&xw, inputs.mixed)
		for err == nil {
			_, err = xz.writer_write(&xw, inputs.mixed)
		}
		testing.expect_value(t, err, compress.Error(GE.Canceled))
		xz.writer_destroy(&xw)
	}
}

Xz_Fail_Sink :: struct {
	limit:   int,
	written: int,
}

xz_fail_sink_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f := (^Xz_Fail_Sink)(stream_data)
	#partial switch mode {
	case .Write:
		k := min(len(p), f.limit - f.written)
		f.written += k
		if k < len(p) {
			return i64(k), .Short_Write
		}
		return i64(k), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

xz_writer_expect_round_trip :: proc(t: ^testing.T, source: []u8, options: xz.Options, write_size: int, label: string, loc := #caller_location) {
	sink: bytes.Buffer
	defer bytes.buffer_destroy(&sink)
	xw: xz.Writer
	defer xz.writer_destroy(&xw)
	if !testing.expectf(t, xz.writer_init(&xw, bytes.buffer_to_stream(&sink), .Level_1, options) == nil, "%s: init", label, loc = loc) {
		return
	}
	for n := 0; n < len(source); {
		size := len(source) - n
		if write_size > 0 {
			size = min(size, write_size)
		} else if write_size < 0 {
			size = min(size, 1 + rand.int_max(70_000))
		}
		_, err := xz.writer_write(&xw, source[n:][:size])
		if !testing.expectf(t, err == nil, "%s: write at %d: %v", label, n, err, loc = loc) {
			return
		}
		n += size
	}
	if !testing.expectf(t, xz.writer_finish(&xw) == nil, "%s: finish", label, loc = loc) {
		return
	}
	block := options.block_size
	if block == 0 {
		block = max(3 * int(xz.level_options(.Level_1).lzma2.dict_size), xz.BLOCK_SIZE_MIN)
	}
	blocks := 0
	if len(source) > 0 {
		blocks = 1 if block < 0 else (len(source) + block - 1) / block
	}
	testing.expectf(t, len(xw.records) == blocks, "%s: %d blocks, want %d", label, len(xw.records), blocks, loc = loc)
	packed := bytes.buffer_to_bytes(&sink)
	if len(source) > 0 {
		testing.expectf(t, packed[xz.HEADER_SIZE + 1] & 0xC0 == 0, "%s: block header has sizes", label, loc = loc)
	}
	want: [dynamic]u8
	defer delete(want)
	one_err := xz.decompress(&want, packed)
	testing.expectf(t, one_err == nil && bytes.equal(want[:], source), "%s: one-shot %v, %d of %d bytes", label, one_err, len(want), len(source), loc = loc)
	out, err := xz_stream_decode(packed, {}, -1, {}, true, -1)
	testing.expectf(t, err == nil && bytes.equal(out[:], source), "%s: stream %v, %d of %d bytes", label, err, len(out), len(source), loc = loc)
	delete(out)
}

xz_stream_option_sets :: proc() -> (sets: [6]xz.Options) {
	sets[1].check        = .None
	sets[2].check        = .CRC32
	sets[3].check        = .SHA256
	sets[4].filter_count = 1
	sets[4].filters[0]   = {id = .Delta, delta_distance = 3}
	sets[5].filter_count = 3
	sets[5].filters[0]   = {id = .Delta, delta_distance = 2}
	sets[5].filters[1]   = {id = .X86}
	sets[5].filters[2]   = {id = .ARM64, start_offset = 4096}
	return
}

xz_stream_decode :: proc(input: []u8, flags: xz.Decode_Flags, expected: int, options: compress.Options, streamed: bool, read_size: int) -> (out: [dynamic]u8, err: compress.Error) {
	data := input
	reader: bytes.Reader
	z := lzma_stream_context(&data, &reader, streamed)
	defer compress.destroy_context(&z)
	if read_size == 0 {
		sink: bytes.Buffer
		defer bytes.buffer_destroy(&sink)
		err = xz.decompress_to_writer(bytes.buffer_to_stream(&sink), &z, flags, expected, options)
		append(&out, ..bytes.buffer_to_bytes(&sink))
		return
	}
	r: xz.Reader
	defer xz.reader_destroy(&r)
	xz.reader_init(&r, &z, flags, expected, options) or_return
	buf: [4096]u8
	for {
		size := read_size if read_size > 0 else 1 + rand.int_max(len(buf))
		n, read_err := xz.reader_read(&r, buf[:size])
		append(&out, ..buf[:n])
		if read_err == io.Error.EOF {
			return out, nil
		}
		if read_err != nil {
			return out, read_err
		}
	}
}

xz_stream_expect_all :: proc(t: ^testing.T, packed, want: []u8, label: string, loc := #caller_location) {
	for streamed in ([2]bool{false, true}) {
		for chunk_size in ([?]int{0, 1, 4096}) {
			out, err := xz_stream_decode(packed, {}, -1, {chunk_size = chunk_size}, streamed, 0)
			testing.expectf(t, err == nil && bytes.equal(out[:], want), "%s: push, chunk %d, streamed %v: %v, %d of %d bytes", label, chunk_size, streamed, err, len(out), len(want), loc = loc)
			delete(out)
		}
		for read_size in ([?]int{1, 7, 4096, -1}) {
			if read_size == 1 && len(want) > 1 << 18 {
				continue
			}
			expected := len(want) if read_size == 7 else -1
			out, err := xz_stream_decode(packed, {}, expected, {}, streamed, read_size)
			testing.expectf(t, err == nil && bytes.equal(out[:], want), "%s: pull %d, streamed %v: %v, %d of %d bytes", label, read_size, streamed, err, len(out), len(want), loc = loc)
			delete(out)
		}
	}
}

xz_stream_expect_agreement :: proc(t: ^testing.T, input: []u8, options, cut, flip: int, loc := #caller_location) {
	want, want_err := xz_stream_decode(input, {}, -1, {}, false, -1)
	defer delete(want)
	for read_size in ([2]int{0, -1}) {
		out, err := xz_stream_decode(input, {}, -1, {}, true, read_size)
		testing.expectf(t, err == want_err, "options %d, cut %d, flip %d, read %d: streamed %v, memory %v", options, cut, flip, read_size, err, want_err, loc = loc)
		if err == nil && want_err == nil {
			testing.expectf(t, bytes.equal(out[:], want[:]), "options %d, cut %d, flip %d, read %d: outputs differ", options, cut, flip, read_size, loc = loc)
		}
		delete(out)
	}
}

xz_stream_expect_parity :: proc(t: ^testing.T, input: []u8, options, cut, flip: int, loc := #caller_location) {
	want: [dynamic]u8
	defer delete(want)
	want_err := xz.decompress(&want, input)
	for streamed in ([2]bool{false, true}) {
		read_size := 0 if streamed else -1
		out, err := xz_stream_decode(input, {}, -1, {chunk_size = 1 if cut >= 0 else 0}, streamed, read_size)
		testing.expectf(t, err == want_err, "options %d, cut %d, flip %d, streamed %v: %v, want %v", options, cut, flip, streamed, err, want_err, loc = loc)
		if err == nil && want_err == nil {
			testing.expectf(t, bytes.equal(out[:], want[:]), "options %d, cut %d, flip %d: outputs differ", options, cut, flip, loc = loc)
		}
		delete(out)
	}
}
