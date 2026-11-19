package test_core_compress

import "core:bytes"
import "core:compress"
import pkzip_legacy "core:compress/pkzip-legacy"
import "core:hash"
import "core:io"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:testing"

Legacy_Stream_Case :: struct {
	name:     string,
	method:   Legacy_Method_Id,
	flags:    u16,
	data:     []u8,
	unpacked: int,
}

Legacy_Crc_Sink :: struct {
	crc:   u32,
	count: int,
}

Legacy_Progress_Log :: struct {
	calls:     int,
	cancel_at: int,
	last:      compress.Progress,
}

@test
legacy_stream_test_reference :: proc(t: ^testing.T) {
	path := TEST_SUITE_PATH_ZIP + "/pkzip-legacy.zip"
	file, file_err := os.read_entire_file(path, context.allocator)
	testing.expectf(t, file_err == nil, "couldn't read %v: %v", path, file_err)
	if file_err != nil {
		return
	}
	defer delete(file)

	members, ok := legacy_members(file)
	testing.expect(t, ok, "malformed pkzip-legacy.zip")
	found := 0
	for m in members {
		if m.method == .Stored {
			continue
		}
		found += 1
		legacy_stream_expect_agreement(t, {m.name, m.method, m.flags, m.data, m.unpacked}, true)
	}
	testing.expectf(t, found >= 30, "expected at least 30 legacy members, found %v", found)
}

@test
legacy_stream_test_generated :: proc(t: ^testing.T) {
	for seed in u64(1)..=3 {
		for flags in ([]u16{0, 2, 4, 6}) {
			w := legacy_stream_implode(seed, flags, 200_000)
			legacy_stream_expect_agreement(t, {"implode", .Imploded, flags, implode_finish(&w), 200_000}, true)
			delete(w.buffer)
		}
		for factor in 1..=4 {
			w := legacy_stream_reduce(seed, factor, 200_000)
			legacy_stream_expect_agreement(t, {"reduce", Legacy_Method_Id(factor + 1), 0, reduce_finish(&w), 200_000}, true)
			delete(w.buffer)
		}
	}
}

@test
legacy_stream_test_damaged :: proc(t: ^testing.T) {
	path := TEST_SUITE_PATH_ZIP + "/pkzip-legacy.zip"
	file, file_err := os.read_entire_file(path, context.allocator)
	testing.expectf(t, file_err == nil, "couldn't read %v: %v", path, file_err)
	if file_err != nil {
		return
	}
	defer delete(file)
	members, _ := legacy_members(file)

	cases := make([dynamic]Legacy_Stream_Case, context.temp_allocator)
	for m in members {
		if m.method != .Stored && m.unpacked > 0 {
			append(&cases, Legacy_Stream_Case{m.name, m.method, m.flags, m.data, m.unpacked})
		}
	}
	implode := legacy_stream_implode(9, 6, 100_000)
	defer delete(implode.buffer)
	append(&cases, Legacy_Stream_Case{"implode", .Imploded, 6, implode_finish(&implode), 100_000})
	reduce := legacy_stream_reduce(9, 4, 100_000)
	defer delete(reduce.buffer)
	append(&cases, Legacy_Stream_Case{"reduce", .Reduced_4, 0, reduce_finish(&reduce), 100_000})

	state := rand.create(77)
	gen   := rand.default_random_generator(&state)
	for c in cases {
		for cut in ([]int{0, 1, len(c.data) / 3, len(c.data) / 2, len(c.data) - 1}) {
			if cut < 0 || cut >= len(c.data) {
				continue
			}
			damaged := c
			damaged.data = c.data[:cut]
			legacy_stream_expect_agreement(t, damaged, false)
		}
		for delta in ([]int{-1, 1, 1000}) {
			damaged := c
			damaged.unpacked += delta
			legacy_stream_expect_agreement(t, damaged, false)
		}
		flipped := make([]u8, len(c.data))
		defer delete(flipped)
		for _ in 0..<8 {
			copy(flipped, c.data)
			for _ in 0..=rand.int_max(3, gen) {
				flipped[rand.int_max(len(flipped), gen)] ~= u8(1 + rand.int_max(255, gen))
			}
			damaged := c
			damaged.data = flipped
			legacy_stream_expect_agreement(t, damaged, false)
		}
	}
}

@test
legacy_stream_test_memory :: proc(t: ^testing.T) {
	for method in Legacy_Method {
		data, buffer := legacy_test_bomb(method, 130_000)
		defer delete(buffer)
		size := legacy_test_bomb_size(method, 130_000)

		want: [dynamic]u8
		testing.expect_value(t, legacy_test_unpack(method, &want, data, size), nil)
		want_crc := hash.crc32(want[:])
		delete(want)

		c := Legacy_Stream_Case{name = "bomb", data = data, unpacked = size}
		switch method {
		case .Shrink:  c.method = .Shrunk
		case .Reduce:  c.method = .Reduced_1
		case .Implode: c.method = .Imploded
		}
		for kind in ([]Stream_Kind{.Memory, .Bytes_Reader}) {
			input := data
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr)
			defer compress.destroy_context(&ctx)

			tracking: mem.Tracking_Allocator
			mem.tracking_allocator_init(&tracking, context.allocator)
			defer mem.tracking_allocator_destroy(&tracking)

			sink: Legacy_Crc_Sink
			err := legacy_stream_to_writer(io.Writer{procedure = legacy_crc_sink_proc, data = &sink}, c, &ctx, {}, mem.tracking_allocator(&tracking))
			testing.expectf(t, err == nil, "%v %v: %v", method, kind, err)
			testing.expectf(t, sink.count == size, "%v %v: %v bytes, want %v", method, kind, sink.count, size)
			testing.expectf(t, sink.crc == want_crc, "%v %v: CRC mismatch", method, kind)
			testing.expectf(t, tracking.peak_memory_allocated <= 256 * 1024, "%v %v: peak %v", method, kind, tracking.peak_memory_allocated)
			testing.expectf(t, len(tracking.allocation_map) == 0, "%v %v: %v allocations leaked", method, kind, len(tracking.allocation_map))
		}
	}
}

@test
legacy_stream_test_options :: proc(t: ^testing.T) {
	GE :: compress.General_Error
	w := legacy_stream_implode(5, 2, 100_000)
	defer delete(w.buffer)
	data := implode_finish(&w)
	c    := Legacy_Stream_Case{"options", .Imploded, 2, data, 100_000}

	want: [dynamic]u8
	defer delete(want)
	testing.expect_value(t, legacy_stream_oneshot(&want, c), nil)

	{
		input := data
		ctx   := compress.init_context(&input)
		r: pkzip_legacy.Reader
		Case :: struct {
			options: compress.Options,
			size:    int,
			want:    compress.Error,
		}
		small: [100]u8
		cases := []Case{
			{{max_output_size = -1},     100_000, GE.Incompatible_Options},
			{{max_memory = -1},          100_000, GE.Incompatible_Options},
			{{chunk_size = -1},          100_000, GE.Incompatible_Options},
			{{progress_interval = -1},   100_000, GE.Incompatible_Options},
			{{},                         -1,      GE.Incompatible_Options},
			{{max_output_size = 99_999}, 100_000, GE.Output_Too_Short},
			{{max_output_size = 100_000}, 100_000, nil},
			{{max_memory = 1000},        100_000, GE.Memory_Limit_Exceeded},
			{{max_memory = 1 << 20},     100_000, nil},
			{{buffer = small[:]},        100_000, GE.Memory_Limit_Exceeded},
			{{buffer = small[:]},        100,     nil},
		}
		for k in cases {
			err := pkzip_legacy.reader_init_explode(&r, &ctx, {.Large_Window}, k.size, k.options)
			testing.expectf(t, err == k.want, "%v: %v, want %v", k, err, k.want)
			if err != nil {
				p: [16]u8
				n, read_err := pkzip_legacy.reader_read(&r, p[:])
				testing.expectf(t, n == 0 && read_err == k.want, "%v: read gave %v, %v", k, n, read_err)
			}
			pkzip_legacy.reader_destroy(&r)
		}
		for factor in ([]int{0, 5}) {
			err := pkzip_legacy.reader_init_expand(&r, &ctx, factor, 10)
			testing.expectf(t, err == GE.Incompatible_Options, "factor %v: %v", factor, err)
			pkzip_legacy.reader_destroy(&r)
		}
		err := pkzip_legacy.reader_init_unshrink(&r, &ctx, -1)
		testing.expectf(t, err == GE.Incompatible_Options, "unshrink unsized: %v", err)
		pkzip_legacy.reader_destroy(&r)
		testing.expect_value(t, len(ctx.window), len(data))
	}

	{
		input := data
		ctx   := compress.init_context(&input)
		r: pkzip_legacy.Reader
		testing.expect_value(t, pkzip_legacy.reader_init_explode(&r, &ctx, {.Large_Window}, 0), nil)
		p: [16]u8
		n, err := pkzip_legacy.reader_read(&r, p[:])
		testing.expectf(t, n == 0 && err == io.Error.EOF, "empty: %v, %v", n, err)
		n, err = pkzip_legacy.reader_read(&r, p[:])
		testing.expectf(t, n == 0 && err == io.Error.EOF, "empty again: %v, %v", n, err)
		testing.expect_value(t, len(ctx.window), len(data))
		pkzip_legacy.reader_destroy(&r)
	}

	for size in ([]int{pkzip_legacy.READER_HISTORY + pkzip_legacy.READER_STEP_MAX, 1 << 20}) {
		window := make([]u8, size)
		defer delete(window)
		tracking: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking, context.allocator)
		defer mem.tracking_allocator_destroy(&tracking)
		input := data
		ctx   := compress.init_context(&input)
		got: [dynamic]u8
		defer delete(got)
		err := legacy_stream_decode(&got, c, &ctx, {buffer = window}, 7, mem.tracking_allocator(&tracking))
		testing.expectf(t, err == nil, "buffer %v: %v", size, err)
		testing.expectf(t, bytes.equal(got[:], want[:]), "buffer %v: output differs", size)
		testing.expectf(t, tracking.peak_memory_allocated < 16 * 1024, "buffer %v: peak %v", size, tracking.peak_memory_allocated)
	}

	for kind in ([]Stream_Kind{.Memory, .One_Byte_No_Seek}) {
		for read_size in ([]int{0, 4096}) {
			input := data
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr)
			defer compress.destroy_context(&ctx)
			log: Legacy_Progress_Log
			got: [dynamic]u8
			defer delete(got)
			err := legacy_stream_decode(&got, c, &ctx, {progress = legacy_progress_proc, progress_data = &log}, read_size)
			testing.expectf(t, err == nil, "%v %v: %v", kind, read_size, err)
			testing.expectf(t, log.calls > 1, "%v %v: %v progress calls", kind, read_size, log.calls)
			testing.expectf(t, log.last.bytes_out == 100_000 && log.last.total_out == 100_000, "%v %v: %v", kind, read_size, log.last)
			testing.expectf(t, log.last.bytes_in <= i64(len(data)) && log.last.bytes_in >= i64(len(data)) - 8, "%v %v: bytes_in %v of %v", kind, read_size, log.last.bytes_in, len(data))
			if kind == .Memory {
				testing.expectf(t, log.last.total_in == i64(len(data)), "%v %v: total_in %v", kind, read_size, log.last.total_in)
			}
		}
	}

	for read_size in ([]int{0, 4096}) {
		input := data
		ctx   := compress.init_context(&input)
		log := Legacy_Progress_Log{cancel_at = 1}
		got: [dynamic]u8
		defer delete(got)
		err := legacy_stream_decode(&got, c, &ctx, {progress = legacy_progress_proc, progress_data = &log}, read_size)
		testing.expectf(t, err == GE.Canceled, "cancel %v: %v", read_size, err)
	}

	{
		tracking: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking, context.allocator)
		defer mem.tracking_allocator_destroy(&tracking)
		br: bytes.Reader
		ctx := compress.init_context(bytes.reader_init(&br, data), nil, nil, mem.tracking_allocator(&tracking))
		defer compress.destroy_context(&ctx)
		r: pkzip_legacy.Reader
		testing.expect_value(t, pkzip_legacy.reader_init_explode(&r, &ctx, {.Large_Window}, 100_000, {}, mem.tracking_allocator(&tracking)), nil)
		s := pkzip_legacy.reader_to_stream(&r)
		got := make([]u8, 100_000)
		defer delete(got)
		n, err := io.read_full(s, got)
		testing.expectf(t, n == 100_000 && err == nil, "stream: %v, %v", n, err)
		testing.expect(t, bytes.equal(got[:n], want[:]), "stream: output differs")
		n, err = io.read(s, got)
		testing.expectf(t, n == 0 && err == .EOF, "stream end: %v, %v", n, err)
		testing.expect_value(t, io.destroy(s), nil)
		compress.destroy_context(&ctx)
		testing.expectf(t, len(tracking.allocation_map) == 0, "stream: %v allocations leaked", len(tracking.allocation_map))
	}
}

legacy_stream_expect_agreement :: proc(t: ^testing.T, c: Legacy_Stream_Case, thorough: bool, loc := #caller_location) {
	want: [dynamic]u8
	defer delete(want)
	want_err := legacy_stream_oneshot(&want, c)
	if thorough {
		testing.expectf(t, want_err == nil, "%v: one shot: %v", c.name, want_err, loc = loc)
	}

	for kind in Stream_Kind {
		if !thorough && kind != .Memory && kind != .One_Byte_No_Seek {
			continue
		}
		for chunk in ([]int{0, 1, 20_000}) {
			if !thorough && chunk == 20_000 {
				continue
			}
			for read_size in ([]int{0, 7, 65_536}) {
				if !thorough && read_size == 65_536 {
					continue
				}
				input := c.data
				br: bytes.Reader
				tr: Trickle_Reader
				ctx := stream_test_context(kind, &input, &br, &tr)
				got: [dynamic]u8
				err := legacy_stream_decode(&got, c, &ctx, {chunk_size = chunk}, read_size)
				compress.destroy_context(&ctx)
				testing.expectf(t, err == want_err, "%v (%v, %v bytes, chunk %v, read %v): %v, one shot %v", c.name, kind, len(c.data), chunk, read_size, err, want_err, loc = loc)
				testing.expectf(t, bytes.equal(got[:], want[:]), "%v (%v, %v bytes, chunk %v, read %v): %v bytes differ from one shot's %v", c.name, kind, len(c.data), chunk, read_size, len(got), len(want), loc = loc)
				delete(got)
			}
		}
	}
}

legacy_stream_oneshot :: proc(out: ^[dynamic]u8, c: Legacy_Stream_Case) -> compress.Error {
	#partial switch c.method {
	case .Shrunk:
		return pkzip_legacy.unshrink(out, c.data, c.unpacked)
	case .Reduced_1, .Reduced_2, .Reduced_3, .Reduced_4:
		return pkzip_legacy.expand(out, c.data, int(c.method) - 1, c.unpacked)
	case .Imploded:
		return pkzip_legacy.explode(out, c.data, legacy_stream_implode_options(c.flags), c.unpacked)
	}
	return compress.General_Error.Unknown_Compression_Method
}

legacy_stream_to_writer :: proc(w: io.Writer, c: Legacy_Stream_Case, ctx: ^compress.Context, options: compress.Options, allocator := context.allocator) -> compress.Error {
	#partial switch c.method {
	case .Shrunk:
		return pkzip_legacy.unshrink_to_writer(w, ctx, c.unpacked, options, allocator)
	case .Reduced_1, .Reduced_2, .Reduced_3, .Reduced_4:
		return pkzip_legacy.expand_to_writer(w, ctx, int(c.method) - 1, c.unpacked, options, allocator)
	case .Imploded:
		return pkzip_legacy.explode_to_writer(w, ctx, legacy_stream_implode_options(c.flags), c.unpacked, options, allocator)
	}
	return compress.General_Error.Unknown_Compression_Method
}

legacy_stream_decode :: proc(out: ^[dynamic]u8, c: Legacy_Stream_Case, ctx: ^compress.Context, options: compress.Options, read_size: int, allocator := context.allocator) -> compress.Error {
	if read_size == 0 {
		aw := Append_Writer{out = out, fail_at = -1}
		return legacy_stream_to_writer(append_writer(&aw), c, ctx, options, allocator)
	}

	r: pkzip_legacy.Reader
	defer pkzip_legacy.reader_destroy(&r)
	init_err: compress.Error
	#partial switch c.method {
	case .Shrunk:
		init_err = pkzip_legacy.reader_init_unshrink(&r, ctx, c.unpacked, options, allocator)
	case .Reduced_1, .Reduced_2, .Reduced_3, .Reduced_4:
		init_err = pkzip_legacy.reader_init_expand(&r, ctx, int(c.method) - 1, c.unpacked, options, allocator)
	case .Imploded:
		init_err = pkzip_legacy.reader_init_explode(&r, ctx, legacy_stream_implode_options(c.flags), c.unpacked, options, allocator)
	case:
		return compress.General_Error.Unknown_Compression_Method
	}
	if init_err != nil {
		return init_err
	}

	buf := make([]u8, read_size)
	defer delete(buf)
	for {
		n, err := pkzip_legacy.reader_read(&r, buf)
		append(out, ..buf[:n])
		if err == io.Error.EOF {
			return nil
		}
		if err != nil {
			return err
		}
		if n == 0 {
			return io.Error.No_Progress
		}
	}
}

legacy_stream_implode_options :: proc(flags: u16) -> (options: pkzip_legacy.Implode_Options) {
	if flags & 2 != 0 {
		options += {.Large_Window}
	}
	if flags & 4 != 0 {
		options += {.Literal_Tree}
	}
	return
}

legacy_stream_implode :: proc(seed: u64, flags: u16, size: int) -> (w: Implode_Writer) {
	state := rand.create(seed)
	context.random_generator = rand.default_random_generator(&state)
	options   := legacy_stream_implode_options(flags)
	window    := 8192 if .Large_Window in options else 4096
	min_match := 3 if .Literal_Tree in options else 2
	implode_writer_init(&w, options)
	for produced := 0; produced < size; {
		if rand.int_max(3) == 0 || size - produced < min_match {
			implode_literal(&w, u8(rand.int_max(256)))
			produced += 1
			continue
		}
		length := min_match + (rand.int_max(64 + 255) if rand.int_max(4) == 0 else rand.int_max(20))
		length  = min(length, size - produced)
		implode_match(&w, 1 + rand.int_max(window), length)
		produced += length
	}
	return
}

legacy_stream_reduce :: proc(seed: u64, factor, size: int) -> (w: Reduce_Writer) {
	state := rand.create(seed)
	context.random_generator = rand.default_random_generator(&state)
	sets := make([]Reduce_Followers, 32, context.temp_allocator)
	for &set in sets {
		set.value = u8(rand.int_max(256))
		followers := make([]u8, 1 + rand.int_max(32), context.temp_allocator)
		for &b in followers {
			b = u8(rand.int_max(256))
		}
		set.followers = string(followers)
	}
	reduce_writer_init(&w, sets)

	length_bits  := uint(8 - factor)
	length_max   := 1 << length_bits - 1
	distance_max := (1 << uint(factor) - 1) << 8 + 256
	for produced := 0; produced < size; {
		if rand.int_max(3) == 0 || size - produced < 3 {
			b := rand.int_max(256)
			reduce_put_symbol(&w, b)
			if b == REDUCE_DLE {
				reduce_put_symbol(&w, 0)
			}
			produced += 1
			continue
		}
		distance := 1 + rand.int_max(distance_max)
		length   := min(3 + rand.int_max(length_max + 256), size - produced)
		high     := (distance - 1) >> 8
		field    := length - 3
		if field < length_max {
			v := high << length_bits | field
			if v == 0 {
				continue
			}
			reduce_put_symbol(&w, REDUCE_DLE)
			reduce_put_symbol(&w, v)
		} else {
			reduce_put_symbol(&w, REDUCE_DLE)
			reduce_put_symbol(&w, high << length_bits | length_max)
			reduce_put_symbol(&w, field - length_max)
		}
		reduce_put_symbol(&w, (distance - 1) & 0xff)
		produced += length
	}
	return
}

legacy_crc_sink_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	s := (^Legacy_Crc_Sink)(stream_data)
	#partial switch mode {
	case .Write:
		s.crc    = hash.crc32(p, s.crc)
		s.count += len(p)
		return i64(len(p)), nil
	case .Query:
		return io.query_utility({.Write, .Query})
	}
	return 0, .Unsupported
}

legacy_progress_proc :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	log := (^Legacy_Progress_Log)(user_data)
	log.calls += 1
	log.last   = progress
	return log.cancel_at > 0 && log.calls >= log.cancel_at
}
