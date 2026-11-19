package test_core_compress

import "core:bytes"
import "core:compress"
import "core:io"
import "core:testing"

pattern_data :: proc(n: int) -> []byte {
	data := make([]byte, n)
	for &b, i in data {
		b = u8((i * 131 + i / 251) & 0xff)
	}
	return data
}

Stall_Reader :: struct {
	data:     []byte,
	position: int,
	fail:     io.Error,
	chunk:    int,
	hiccups:  int,
	pending:  int,
}

stall_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Stall_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if r.position < len(r.data) {
			if r.pending < r.hiccups {
				r.pending += 1
				return 0, nil
			}
			r.pending = 0
			limit := len(r.data) - r.position
			if r.chunk > 0 {
				limit = min(limit, r.chunk)
			}
			count := copy(p, r.data[r.position:][:limit])
			r.position += count
			return i64(count), nil
		}
		return 0, r.fail
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

stall_stream :: proc(r: ^Stall_Reader) -> io.Stream {
	return io.Stream{procedure = stall_proc, data = r}
}

Progress_Capture :: struct {
	calls:  int,
	last:   compress.Progress,
	cancel: bool,
}

capture_progress :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	c := (^Progress_Capture)(user_data)
	c.calls += 1
	c.last   = progress
	return c.cancel
}

@(test)
compress_context_init_from_slice :: proc(t: ^testing.T) {
	data := []byte{1, 2, 3, 4, 5}
	output: [dynamic]byte
	ctx := compress.init_context_from_slice(&data, &output)

	testing.expect(t, compress.is_memory_context(&ctx))
	testing.expect(t, ctx.output == &output)
	testing.expect(t, !bool(ctx.owns_backing))
	testing.expect_value(t, len(ctx.window), 5)
	testing.expect(t, raw_data(ctx.window) == raw_data(data))

	size, size_err := compress.size(&ctx)
	testing.expect(t, size_err == nil && size == 5)

	compress.destroy_context(&ctx)
	testing.expect(t, ctx.window == nil && ctx.buffer == nil && ctx.backing == nil)
	testing.expect_value(t, data[0], 1)
	compress.destroy_context(&ctx)

	empty: []byte
	ectx := compress.init_context(&empty)
	testing.expect(t, compress.is_memory_context(&ectx))
	esize, esize_err := compress.size(&ectx)
	testing.expect(t, esize_err == nil && esize == 0)
	_, eof := compress.read_u8(&ectx)
	testing.expect_value(t, eof, io.Error.EOF)
}

@(test)
compress_context_init_from_stream :: proc(t: ^testing.T) {
	data := pattern_data(100)
	defer delete(data)

	r: bytes.Reader
	output: [dynamic]byte
	ctx := compress.init_context_from_stream(bytes.reader_init(&r, data), &output)
	testing.expect(t, !compress.is_memory_context(&ctx))
	testing.expect(t, ctx.output == &output)
	testing.expect(t, bool(ctx.owns_backing))
	testing.expect_value(t, len(ctx.backing), compress.CONTEXT_WINDOW_SIZE)
	testing.expect_value(t, len(ctx.window), 0)

	b, b_err := compress.read_u8(&ctx)
	testing.expect(t, b_err == nil && b == data[0])

	compress.destroy_context(&ctx)
	testing.expect(t, ctx.backing == nil && ctx.window == nil && ctx.buffer == nil && !bool(ctx.owns_backing))
	compress.destroy_context(&ctx)

	buffer: [256]byte
	cctx := compress.init_context(bytes.reader_init(&r, data), nil, buffer[:])
	testing.expect(t, !bool(cctx.owns_backing))
	testing.expect(t, raw_data(cctx.backing) == raw_data(buffer[:]) && len(cctx.backing) == len(buffer))

	got: [100]byte
	testing.expect(t, compress.read_slice(&cctx, got[:]) == nil && bytes.equal(got[:], data))
	compress.destroy_context(&cctx)
	testing.expect(t, cctx.backing == nil)
}

@(test)
compress_context_refill_window :: proc(t: ^testing.T) {
	data := pattern_data(1000)
	defer delete(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		testing.expectf(t, compress.refill_window(&ctx, 0) == nil, "%v: refill 0", kind)
		testing.expectf(t, compress.refill_window(&ctx, 1000) == nil, "%v: refill to exactly EOF", kind)
		testing.expectf(t, len(ctx.window) == 1000 && bytes.equal(ctx.window, data), "%v: window after refill to EOF", kind)

		err := compress.refill_window(&ctx, 1001)
		testing.expectf(t, err == .Short_Buffer, "%v: refill past EOF gave %v", kind, err)
		testing.expectf(t, bytes.equal(ctx.window, data), "%v: window after a failed refill", kind)

		testing.expectf(t, compress.skip(&ctx, 1000) == nil, "%v: skip to EOF", kind)
		err = compress.refill_window(&ctx, 1)
		testing.expectf(t, err == .EOF, "%v: refill at EOF gave %v", kind, err)
	}
}

@(test)
compress_context_refill_keeps_history :: proc(t: ^testing.T) {
	data := pattern_data(STREAM_TEST_SIZE)
	defer delete(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		head: [100]byte
		testing.expectf(t, compress.read_slice(&ctx, head[:]) == nil && bytes.equal(head[:], data[:100]), "%v: read 100", kind)

		if kind == .Memory {
			testing.expectf(t, compress.rewind(&ctx, 100), "%v: rewind over all input", kind)
			testing.expectf(t, compress.skip(&ctx, 100) == nil, "%v: skip back", kind)
			continue
		}

		need := len(ctx.window) + 1
		testing.expectf(t, compress.refill_window(&ctx, need) == nil && len(ctx.window) >= need, "%v: forced refill", kind)
		testing.expectf(t, !compress.rewind(&ctx, compress.CONTEXT_HISTORY + 1), "%v: rewind past the kept history", kind)
		testing.expectf(t, compress.rewind(&ctx, compress.CONTEXT_HISTORY), "%v: rewind over the kept history", kind)

		kept: [compress.CONTEXT_HISTORY]byte
		testing.expectf(t, compress.read_slice(&ctx, kept[:]) == nil && bytes.equal(kept[:], data[100 - compress.CONTEXT_HISTORY:100]), "%v: kept history", kind)
		b, b_err := compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[100], "%v: read after history", kind)
	}
}

@(test)
compress_context_refill_window_limit :: proc(t: ^testing.T) {
	data := pattern_data(1000)
	defer delete(data)

	r: bytes.Reader
	buffer: [64]byte
	ctx := compress.init_context(bytes.reader_init(&r, data), nil, buffer[:])
	defer compress.destroy_context(&ctx)

	limit := len(buffer) - compress.CONTEXT_HISTORY
	head: [20]byte
	testing.expect(t, compress.read_slice(&ctx, head[:]) == nil && bytes.equal(head[:], data[:20]))
	testing.expect_value(t, compress.refill_window(&ctx, limit + 1), io.Error.Short_Buffer)
	testing.expect(t, bytes.equal(ctx.window, data[20:len(buffer)]))
	testing.expect(t, compress.refill_window(&ctx, limit) == nil)
	testing.expect(t, bytes.equal(ctx.window[:limit], data[20:20 + limit]))

	r2: bytes.Reader
	dctx := compress.init_context(bytes.reader_init(&r2, data))
	defer compress.destroy_context(&dctx)
	_, _ = compress.read_u8(&dctx)
	testing.expect_value(t, compress.refill_window(&dctx, compress.CONTEXT_WINDOW_SIZE - compress.CONTEXT_HISTORY + 1), io.Error.Short_Buffer)
}

@(test)
compress_context_refill_stall_and_error :: proc(t: ^testing.T) {
	data := pattern_data(10)
	defer delete(data)

	stall := Stall_Reader{data = data}
	sctx := compress.init_context(stall_stream(&stall))
	defer compress.destroy_context(&sctx)
	testing.expect(t, compress.refill_window(&sctx, 10) == nil)
	testing.expect_value(t, compress.refill_window(&sctx, 11), io.Error.No_Progress)

	broken := Stall_Reader{data = data, fail = .Unknown}
	ectx := compress.init_context(stall_stream(&broken))
	defer compress.destroy_context(&ectx)
	testing.expect_value(t, compress.refill_window(&ectx, 11), io.Error.Unknown)
	testing.expect(t, bytes.equal(ectx.window, data))
}

@(test)
compress_context_refill_hiccups :: proc(t: ^testing.T) {
	data := pattern_data(1000)
	defer delete(data)

	hiccup := Stall_Reader{data = data, fail = .EOF, chunk = 1, hiccups = 3}
	ctx := compress.init_context(stall_stream(&hiccup))
	defer compress.destroy_context(&ctx)
	testing.expect(t, compress.refill_window(&ctx, 500) == nil)
	testing.expect(t, len(ctx.window) >= 500 && bytes.equal(ctx.window[:500], data[:500]))

	rest, err := compress.read_remaining(&ctx)
	testing.expect_value(t, err, nil)
	testing.expect(t, bytes.equal(rest[:], data))
	delete(rest)

	stuck := Stall_Reader{data = data, fail = .EOF, chunk = 1, hiccups = 101}
	sctx := compress.init_context(stall_stream(&stuck))
	defer compress.destroy_context(&sctx)
	testing.expect_value(t, compress.refill_window(&sctx, 1), io.Error.No_Progress)

	srest, serr := compress.read_remaining(&sctx)
	testing.expect_value(t, serr, io.Error.No_Progress)
	testing.expect(t, bytes.equal(srest[:], data[:1]))
	delete(srest)
}

@(test)
compress_context_rewind :: proc(t: ^testing.T) {
	data := pattern_data(1000)
	defer delete(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		testing.expectf(t, compress.rewind(&ctx, 0), "%v: rewind 0 at the start", kind)
		testing.expectf(t, !compress.rewind(&ctx, 1), "%v: rewind 1 at the start", kind)

		head: [10]byte
		testing.expectf(t, compress.read_slice(&ctx, head[:]) == nil, "%v: read 10", kind)
		testing.expectf(t, !compress.rewind(&ctx, -1), "%v: rewind -1", kind)
		testing.expectf(t, !compress.rewind(&ctx, 11), "%v: rewind past the start", kind)
		testing.expectf(t, compress.rewind(&ctx, 0), "%v: rewind 0", kind)
		testing.expectf(t, compress.rewind(&ctx, 4), "%v: rewind 4", kind)

		again: [4]byte
		testing.expectf(t, compress.read_slice(&ctx, again[:]) == nil && bytes.equal(again[:], data[6:10]), "%v: read after rewind 4", kind)
		testing.expectf(t, compress.rewind(&ctx, 10), "%v: rewind 10", kind)
		testing.expectf(t, compress.read_slice(&ctx, head[:]) == nil && bytes.equal(head[:], data[:10]), "%v: read after rewind 10", kind)
	}
}

@(test)
compress_context_size :: proc(t: ^testing.T) {
	data := pattern_data(STREAM_TEST_SIZE)
	defer delete(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		if kind == .One_Byte_No_Seek {
			_, size_err := compress.size(&ctx)
			testing.expectf(t, size_err != nil, "%v: size without seek or size", kind)
			testing.expectf(t, compress.input_size(&ctx) == -1, "%v: input_size without seek or size", kind)
			continue
		}

		size, size_err := compress.size(&ctx)
		testing.expectf(t, size_err == nil && size == STREAM_TEST_SIZE, "%v: size %v, %v", kind, size, size_err)
		testing.expectf(t, compress.input_size(&ctx) == STREAM_TEST_SIZE, "%v: input_size", kind)

		_, _ = compress.read_u8(&ctx)
		size, size_err = compress.size(&ctx)
		testing.expectf(t, size_err == nil && size == STREAM_TEST_SIZE - 1, "%v: size after read_u8: %v, %v", kind, size, size_err)

		testing.expectf(t, compress.skip(&ctx, 100_000) == nil, "%v: skip", kind)
		size, size_err = compress.size(&ctx)
		testing.expectf(t, size_err == nil && size == STREAM_TEST_SIZE - 100_001, "%v: size after skip: %v, %v", kind, size, size_err)
		testing.expectf(t, compress.input_size(&ctx) == STREAM_TEST_SIZE - 100_001, "%v: input_size after skip", kind)
	}
}

@(test)
compress_context_declared_size :: proc(t: ^testing.T) {
	testing.expect_value(t, compress.declared_size(10), 10)
	testing.expect_value(t, compress.declared_size(0, 99), 0)
	testing.expect_value(t, compress.declared_size(10, 99), 10)
	testing.expect_value(t, compress.declared_size(-1, 99), 99)
	testing.expect_value(t, compress.declared_size(-1, 0), 0)
	testing.expect_value(t, compress.declared_size(-1), -1)
	testing.expect_value(t, compress.declared_size(-1, -5), -1)
	testing.expect_value(t, compress.declared_size(-1, i64(max(int))), max(int))
	testing.expect_value(t, compress.declared_size(-1, max(i64)), -1 when size_of(int) < size_of(i64) else max(int))
}

@(test)
compress_context_output_reservation :: proc(t: ^testing.T) {
	INITIAL :: compress.COMPRESS_INITIAL_RESERVATION
	RATIO   :: compress.COMPRESS_INITIAL_RESERVATION_RATIO

	testing.expect_value(t, compress.output_reservation(100, -1, -1), 100)
	testing.expect_value(t, compress.output_reservation(0, -1, 1000), 0)
	testing.expect_value(t, compress.output_reservation(INITIAL * 2, -1, -1), INITIAL)
	testing.expect_value(t, compress.output_reservation(100, 50, -1), 50)
	testing.expect_value(t, compress.output_reservation(100, 0, -1), 0)
	testing.expect_value(t, compress.output_reservation(-1, -1, -1), min(compress.COMPRESS_RESERVE_DEFAULT, INITIAL))
	testing.expect_value(t, compress.output_reservation(-1, 10, -1), 10)
	testing.expect_value(t, compress.output_reservation(-1, -1, 0), 0)
	testing.expect_value(t, compress.output_reservation(-1, -1, 1000), 1000 * RATIO)
	testing.expect_value(t, compress.output_reservation(-1, -1, INITIAL / RATIO), INITIAL / RATIO * RATIO)
	testing.expect_value(t, compress.output_reservation(-1, -1, INITIAL / RATIO + 1), INITIAL)
	testing.expect_value(t, compress.output_reservation(-1, -1, max(int)), INITIAL)
	testing.expect_value(t, compress.output_reservation(-1, 10, 1000), 10)
}

@(test)
compress_context_output_grow_capacity :: proc(t: ^testing.T) {
	MIN  :: compress.COMPRESS_GROWTH_MIN
	STEP :: compress.COMPRESS_GROWTH_STEP
	BIG  :: 8 * STEP

	testing.expect_value(t, compress.output_grow_capacity(0, 1, max(int)), MIN)
	testing.expect_value(t, compress.output_grow_capacity(0, MIN + 1, max(int)), MIN + 1)
	testing.expect_value(t, compress.output_grow_capacity(MIN / 2, MIN / 2 + 1, max(int)), MIN + MIN / 2)
	testing.expect_value(t, compress.output_grow_capacity(2 * MIN, 2 * MIN + 1, max(int)), 4 * MIN)
	testing.expect_value(t, compress.output_grow_capacity(STEP - 1, STEP, max(int)), 2 * STEP - 2)
	testing.expect_value(t, compress.output_grow_capacity(STEP, STEP + 1, max(int)), 2 * STEP)
	testing.expect_value(t, compress.output_grow_capacity(BIG, BIG + 1, max(int)), BIG + BIG / 4)
	testing.expect_value(t, compress.output_grow_capacity(BIG, 3 * BIG, max(int)), 3 * BIG)
	testing.expect_value(t, compress.output_grow_capacity(2 * MIN, 2 * MIN + 1, 3 * MIN), 3 * MIN)
	testing.expect_value(t, compress.output_grow_capacity(0, 100, 50), 50)
}

@(test)
compress_context_option_limits :: proc(t: ^testing.T) {
	testing.expect_value(t, compress.output_limit({}), compress.COMPRESS_OUTPUT_ALLOCATE_MAX)
	testing.expect_value(t, compress.output_limit({max_output_size = 5}), 5)
	testing.expect_value(t, compress.memory_limit({}), compress.COMPRESS_MEMORY_MAX)
	testing.expect_value(t, compress.memory_limit({max_memory = 7}), 7)
	testing.expect_value(t, compress.progress_interval({}), compress.PROGRESS_INTERVAL_DEFAULT)
	testing.expect_value(t, compress.progress_interval({progress_interval = 9}), 9)
}

@(test)
compress_context_report_progress :: proc(t: ^testing.T) {
	testing.expect(t, compress.report_progress({}, 1, 2, 3, 4) == nil)

	capture: Progress_Capture
	options := compress.Options{progress = capture_progress, progress_data = &capture}
	testing.expect(t, compress.report_progress(options, 1, 2, 3, 4) == nil)
	testing.expect_value(t, capture.calls, 1)
	p := capture.last
	testing.expect(t, p.bytes_in == 1 && p.bytes_out == 2 && p.total_in == 3 && p.total_out == 4)
	testing.expect(t, p.member == "" && p.member_index == -1 && p.member_count == -1)
	testing.expect(t, p.archive_in == 0 && p.archive_total_in == -1)

	capture.cancel = true
	err := compress.report_progress(options, 5, 6, -1, -1)
	testing.expectf(t, err == compress.General_Error.Canceled, "cancel gave %v", err)
	testing.expect_value(t, capture.calls, 2)
	testing.expect(t, capture.last.total_in == -1 && capture.last.total_out == -1)
}

@(test)
compress_context_reads :: proc(t: ^testing.T) {
	data := pattern_data(STREAM_TEST_SIZE)
	defer delete(data)
	n := len(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		v32, v32_err := compress.read_data(&ctx, u32le)
		testing.expectf(t, v32_err == nil && v32 == (^u32le)(&data[0])^, "%v: read_data", kind)

		v16: u16le
		testing.expectf(t, compress.read_ptr(&ctx, &v16) == nil && v16 == (^u16le)(&data[4])^, "%v: read_ptr", kind)

		b, b_err := compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[6], "%v: read_u8", kind)

		testing.expectf(t, compress.read_slice(&ctx, nil) == nil, "%v: zero-length read_slice", kind)
		b, b_err = compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[7], "%v: read_u8 after a zero-length read", kind)

		big := make([]byte, 100_000)
		defer delete(big)
		testing.expectf(t, compress.read_slice(&ctx, big) == nil && bytes.equal(big, data[8:100_008]), "%v: read_slice past the window", kind)

		mid: [1000]byte
		testing.expectf(t, compress.read_slice(&ctx, mid[:]) == nil && bytes.equal(mid[:], data[100_008:101_008]), "%v: read_slice after a large one", kind)

		testing.expectf(t, compress.skip(&ctx, i64(n - 101_008 - 5)) == nil, "%v: skip to 5 bytes before EOF", kind)
		v32, v32_err = compress.read_data(&ctx, u32le)
		testing.expectf(t, v32_err == nil && v32 == (^u32le)(&data[n - 5])^, "%v: read_data before EOF", kind)

		_, v32_err = compress.read_data(&ctx, u32le)
		testing.expectf(t, v32_err == .Short_Buffer, "%v: read_data past EOF gave %v", kind, v32_err)

		b, b_err = compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[n - 1], "%v: last byte after a failed read_data", kind)
		testing.expectf(t, compress.read_ptr(&ctx, &v16) == .Short_Buffer, "%v: read_ptr at EOF", kind)

		_, b_err = compress.read_u8(&ctx)
		testing.expectf(t, b_err == .EOF, "%v: read_u8 at EOF gave %v", kind, b_err)
		_, v32_err = compress.read_data(&ctx, u32le)
		testing.expectf(t, v32_err == .EOF, "%v: read_data at EOF gave %v", kind, v32_err)
		testing.expectf(t, compress.read_slice(&ctx, nil) == nil, "%v: zero-length read_slice at EOF", kind)
		one: [1]byte
		err := compress.read_slice(&ctx, one[:])
		testing.expectf(t, err == .Short_Buffer, "%v: read_slice at EOF gave %v", kind, err)
	}
}

@(test)
compress_context_skip :: proc(t: ^testing.T) {
	data := pattern_data(STREAM_TEST_SIZE)
	defer delete(data)
	n := len(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		testing.expectf(t, compress.skip(&ctx, -1) == .Short_Buffer, "%v: negative skip", kind)
		testing.expectf(t, compress.skip(&ctx, 0) == nil, "%v: zero skip", kind)
		b, b_err := compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[0], "%v: read after zero skip", kind)

		testing.expectf(t, compress.skip(&ctx, 10) == nil, "%v: short skip", kind)
		b, b_err = compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[11], "%v: read after short skip", kind)

		testing.expectf(t, compress.skip(&ctx, 99_988) == nil, "%v: long skip", kind)
		b, b_err = compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[100_000], "%v: read after long skip", kind)

		testing.expectf(t, compress.skip(&ctx, i64(n - 100_001)) == nil, "%v: skip to exactly EOF", kind)
		_, b_err = compress.read_u8(&ctx)
		testing.expectf(t, b_err == .EOF, "%v: read after skip to EOF gave %v", kind, b_err)
	}

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		err := compress.skip(&ctx, i64(n + 1))
		b, b_err := compress.read_u8(&ctx)
		if kind == .Memory {
			testing.expectf(t, err == .Short_Buffer, "%v: skip past EOF gave %v", kind, err)
			testing.expectf(t, b_err == nil && b == data[0], "%v: failed skip moved the cursor", kind)
			continue
		}
		if kind == .One_Byte_No_Seek {
			testing.expectf(t, err != nil, "%v: skip past EOF succeeded", kind)
			continue
		}
		testing.expectf(t, b_err != nil, "%v: read after skip past EOF succeeded", kind)
	}
}

@(test)
compress_context_peek :: proc(t: ^testing.T) {
	data := pattern_data(STREAM_TEST_SIZE)
	defer delete(data)
	n := len(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		v32, err := compress.peek_data(&ctx, u32le)
		testing.expectf(t, err == nil && v32 == (^u32le)(&data[0])^, "%v: peek at cursor", kind)
		b, b_err := compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[0], "%v: peek moved the cursor", kind)

		v16: u16le
		v16, err = compress.peek_data(&ctx, u16le, 100)
		testing.expectf(t, err == nil && v16 == (^u16le)(&data[101])^, "%v: peek at offset", kind)
		_, err = compress.peek_data(&ctx, u16le, -1)
		testing.expectf(t, err == .Short_Buffer, "%v: peek at a negative offset gave %v", kind, err)

		cursor := 65_530
		testing.expectf(t, compress.skip(&ctx, i64(cursor - 1)) == nil, "%v: skip near the window end", kind)
		v16, err = compress.peek_data(&ctx, u16le, 20)
		testing.expectf(t, err == nil && v16 == (^u16le)(&data[cursor + 20])^, "%v: peek across a refill", kind)
		v32, err = compress.read_data(&ctx, u32le)
		testing.expectf(t, err == nil && v32 == (^u32le)(&data[cursor])^, "%v: read after a peek across a refill", kind)
		cursor += 4

		v32, err = compress.peek_data(&ctx, u32le, 100_000)
		if kind == .One_Byte_No_Seek {
			testing.expectf(t, err != nil, "%v: far peek without seek succeeded", kind)
		} else {
			testing.expectf(t, err == nil && v32 == (^u32le)(&data[cursor + 100_000])^, "%v: far peek gave %v", kind, err)
		}
		b, b_err = compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[cursor], "%v: far peek moved the cursor", kind)
		cursor += 1

		testing.expectf(t, compress.skip(&ctx, i64(n - 10 - cursor)) == nil, "%v: skip to 10 bytes before EOF", kind)
		v16, err = compress.peek_data(&ctx, u16le, 8)
		testing.expectf(t, err == nil && v16 == (^u16le)(&data[n - 2])^, "%v: peek ending at EOF", kind)
		_, err = compress.peek_data(&ctx, u16le, 9)
		testing.expectf(t, err == .Short_Buffer, "%v: peek past EOF gave %v", kind, err)

		testing.expectf(t, compress.skip(&ctx, 8) == nil, "%v: skip to 2 bytes before EOF", kind)
		_, err = compress.peek_data(&ctx, u32le)
		testing.expectf(t, err == .Short_Buffer, "%v: peek at cursor past EOF gave %v", kind, err)
		v16, err = compress.peek_data(&ctx, u16le)
		testing.expectf(t, err == nil && v16 == (^u16le)(&data[n - 2])^, "%v: peek of the last bytes", kind)

		testing.expectf(t, compress.skip(&ctx, 2) == nil, "%v: skip to EOF", kind)
		_, err = compress.peek_data(&ctx, u8)
		testing.expectf(t, err == .EOF, "%v: peek at EOF gave %v", kind, err)
	}
}

@(test)
compress_context_peek_input_at :: proc(t: ^testing.T) {
	data := pattern_data(STREAM_TEST_SIZE)
	defer delete(data)
	n := len(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		_, _ = compress.read_u8(&ctx)
		buf: [8]byte
		err := compress.peek_input_at(&ctx, buf[:], 50)
		if kind == .Memory || kind == .One_Byte_No_Seek {
			testing.expectf(t, err != nil, "%v: peek_input_at without seek succeeded", kind)
			continue
		}
		testing.expectf(t, err == nil && bytes.equal(buf[:], data[51:59]), "%v: peek_input_at gave %v", kind, err)

		err = compress.peek_input_at(&ctx, buf[:], 150_000)
		testing.expectf(t, err == nil && bytes.equal(buf[:], data[150_001:150_009]), "%v: peek_input_at past the window gave %v", kind, err)

		err = compress.peek_input_at(&ctx, buf[:], i64(n - 4))
		testing.expectf(t, err != nil, "%v: peek_input_at past EOF succeeded", kind)

		b, b_err := compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[1], "%v: peek_input_at moved the cursor", kind)
		v32, v32_err := compress.read_data(&ctx, u32le)
		testing.expectf(t, v32_err == nil && v32 == (^u32le)(&data[2])^, "%v: read after peek_input_at", kind)
	}
}

@(test)
compress_context_read_remaining :: proc(t: ^testing.T) {
	data := pattern_data(STREAM_TEST_SIZE)
	defer delete(data)

	for kind in Stream_Kind {
		input := data
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr)
		defer compress.destroy_context(&ctx)

		head: [1000]byte
		testing.expectf(t, compress.read_slice(&ctx, head[:]) == nil, "%v: read 1000", kind)

		rest, err := compress.read_remaining(&ctx, context.allocator)
		testing.expectf(t, err == nil && bytes.equal(rest[:], data[1000:]), "%v: read_remaining gave %v, %v bytes", kind, err, len(rest))
		delete(rest)

		_, b_err := compress.read_u8(&ctx)
		testing.expectf(t, b_err == .EOF, "%v: read after read_remaining gave %v", kind, b_err)

		empty, empty_err := compress.read_remaining(&ctx)
		testing.expectf(t, empty_err == nil && len(empty) == 0, "%v: read_remaining at EOF gave %v, %v bytes", kind, empty_err, len(empty))
		delete(empty)
	}

	short := pattern_data(10)
	defer delete(short)

	stall := Stall_Reader{data = short}
	sctx := compress.init_context(stall_stream(&stall))
	defer compress.destroy_context(&sctx)
	srest, serr := compress.read_remaining(&sctx)
	testing.expect_value(t, serr, io.Error.No_Progress)
	testing.expect(t, bytes.equal(srest[:], short))
	delete(srest)

	broken := Stall_Reader{data = short, fail = .Unknown}
	ectx := compress.init_context(stall_stream(&broken))
	defer compress.destroy_context(&ectx)
	erest, eerr := compress.read_remaining(&ectx)
	testing.expect_value(t, eerr, io.Error.Unknown)
	testing.expect(t, bytes.equal(erest[:], short))
	delete(erest)
}
