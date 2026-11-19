package test_core_compress

import "core:bytes"
import "core:compress"
import pkzip_legacy "core:compress/pkzip-legacy"
import "core:fmt"
import "core:testing"

Legacy_Method :: enum {
	Shrink,
	Reduce,
	Implode,
}

@test
legacy_test_exact_size :: proc(t: ^testing.T) {
	for method in Legacy_Method {
		data, buffer := legacy_test_bomb(method, 1_000)
		defer delete(buffer)
		full: [dynamic]u8
		defer delete(full)
		testing.expect_value(t, legacy_test_unpack(method, &full, data, legacy_test_bomb_size(method, 1_000)), nil)

		for kind in Stream_Kind {
			input := data
			output: [dynamic]u8
			defer delete(output)
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr, &output)
			err := legacy_test_unpack_context(method, &ctx, len(full))
			compress.destroy_context(&ctx)
			testing.expectf(t, err == nil, "%v %v: %v", method, kind, err)
			testing.expectf(t, bytes.equal(output[:], full[:]), "%v %v: output differs", method, kind)
			if kind != .One_Byte_No_Seek {
				testing.expectf(t, cap(output) == len(full), "%v %v: capacity %v for an exact size of %v", method, kind, cap(output), len(full))
			}
		}
	}
}

@test
legacy_test_max_output_size :: proc(t: ^testing.T) {
	for method in Legacy_Method {
		data, buffer := legacy_test_bomb(method, 1_000)
		defer delete(buffer)
		full: [dynamic]u8
		defer delete(full)
		testing.expect_value(t, legacy_test_unpack(method, &full, data, legacy_test_bomb_size(method, 1_000)), nil)

		Case :: struct {
			expected, limit: int,
			want:            compress.Error,
		}
		cases := []Case{
			{len(full), len(full),     nil},
			{len(full), len(full) / 2, compress.General_Error.Output_Too_Short},
			{len(full), len(full) - 1, compress.General_Error.Output_Too_Short},
			{-1,        len(full),     compress.General_Error.Incompatible_Options},
			{len(full), -1,            compress.General_Error.Incompatible_Options},
		}
		for c in cases {
			output: [dynamic]u8
			defer delete(output)
			err := legacy_test_unpack(method, &output, data, c.expected, {max_output_size = c.limit})
			testing.expectf(t, err == c.want, "%v %v: %v, want %v", method, c, err, c.want)
			testing.expectf(t, cap(output) <= max(c.limit, 0), "%v %v: capacity %v", method, c, cap(output))
		}
	}
}

@test
legacy_test_oneshot_options :: proc(t: ^testing.T) {
	GE :: compress.General_Error
	for method in Legacy_Method {
		data, buffer := legacy_test_bomb(method, 1_000)
		defer delete(buffer)
		size := legacy_test_bomb_size(method, 1_000)

		Case :: struct {
			options: compress.Options,
			size:    int,
			want:    compress.Error,
		}
		cases := []Case{
			{{max_output_size = -1},   size, GE.Incompatible_Options},
			{{max_memory = -1},        size, GE.Incompatible_Options},
			{{chunk_size = -1},        size, GE.Incompatible_Options},
			{{progress_interval = -1}, size, GE.Incompatible_Options},
			{{progress_interval = -1}, 0,    GE.Incompatible_Options},
			{{max_output_size = size}, size, nil},
			{{max_memory = 1000},      size, compress.Error(GE.Memory_Limit_Exceeded) if method == .Shrink else nil},
			{{max_memory = 1000},      0,    nil},
			{{max_memory = 1 << 20},   size, nil},
		}
		for c in cases {
			for kind in ([]Stream_Kind{.Memory, .One_Byte_No_Seek}) {
				input := data
				output: [dynamic]u8
				defer delete(output)
				br: bytes.Reader
				tr: Trickle_Reader
				ctx := stream_test_context(kind, &input, &br, &tr, &output)
				err := legacy_test_unpack_context(method, &ctx, c.size, c.options)
				compress.destroy_context(&ctx)
				testing.expectf(t, err == c.want, "%v %v %v: %v, want %v", method, kind, c, err, c.want)
				if c.want != nil {
					testing.expectf(t, cap(output) == 0, "%v %v %v: capacity %v", method, kind, c, cap(output))
				} else {
					testing.expectf(t, len(output) == c.size, "%v %v %v: %v bytes", method, kind, c, len(output))
				}
			}
		}
	}
}

@test
legacy_test_oneshot_progress :: proc(t: ^testing.T) {
	INTERVAL :: 50_000
	SIZE     :: 300_000
	for method in Legacy_Method {
		data, buffer := legacy_test_generated(method, SIZE)
		defer delete(buffer)
		want: [dynamic]u8
		defer delete(want)
		testing.expect_value(t, legacy_test_unpack(method, &want, data, SIZE), nil)

		log: Ppmd_Progress_Log
		defer delete(log.calls)
		first: [dynamic]compress.Progress
		defer delete(first)

		{
			output: [dynamic]u8
			defer delete(output)
			err := legacy_test_unpack(method, &output, data, SIZE, ppmd_progress_options(&log, {progress_interval = INTERVAL}))
			label := fmt.tprintf("%v one-shot bytes", method)
			testing.expectf(t, err == nil && bytes.equal(output[:], want[:]), "%v: %v", label, err)
			testing.expectf(t, len(log.calls) >= SIZE / INTERVAL - 1, "%v: %v calls", label, len(log.calls))
			ppmd_progress_expect(t, label, log.calls[:], i64(len(data)), SIZE, i64(len(data)), SIZE)
			codec_progress_expect_spacing(t, label, log.calls[:], INTERVAL, false)
			codec_progress_same(t, label, &first, log.calls[:])
		}

		for kind in Stream_Kind {
			input := data
			output: [dynamic]u8
			defer delete(output)
			br: bytes.Reader
			tr: Trickle_Reader
			ctx    := stream_test_context(kind, &input, &br, &tr, &output)
			before := ctx.input
			err    := legacy_test_unpack_context(method, &ctx, SIZE, ppmd_progress_options(&log, {progress_interval = INTERVAL}))
			after  := ctx.input
			compress.destroy_context(&ctx)
			label := fmt.tprintf("%v one-shot %v", method, kind)
			testing.expectf(t, err == nil && bytes.equal(output[:], want[:]), "%v: %v", label, err)
			testing.expectf(t, after == before, "%v: input stream not restored", label)
			ppmd_progress_expect(t, label, log.calls[:], codec_progress_input_total(kind, len(data)), SIZE, i64(len(data)), SIZE)
			codec_progress_same(t, label, &first, log.calls[:])
		}

		{
			output: [dynamic]u8
			defer delete(output)
			testing.expect_value(t, legacy_test_unpack(method, &output, data, SIZE, ppmd_progress_options(&log)), nil)
			testing.expectf(t, len(log.calls) == 0, "%v: %v calls at the default interval", method, len(log.calls))
		}

		for kind in ([]Stream_Kind{.Memory, .One_Byte_No_Seek}) {
			input := data
			output: [dynamic]u8
			defer delete(output)
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr, &output)
			log.cancel_at = 2
			err := legacy_test_unpack_context(method, &ctx, SIZE, ppmd_progress_options(&log, {progress_interval = INTERVAL}))
			log.cancel_at = 0
			compress.destroy_context(&ctx)
			label := fmt.tprintf("%v one-shot cancel %v", method, kind)
			testing.expectf(t, err == compress.General_Error.Canceled, "%v: %v", label, err)
			testing.expectf(t, len(log.calls) == 2, "%v: %v calls", label, len(log.calls))
			if len(log.calls) == 2 {
				testing.expectf(t, i64(len(output)) == log.calls[1].bytes_out, "%v: %v bytes, last call %v", label, len(output), log.calls[1])
				testing.expectf(t, bytes.equal(output[:], want[:len(output)]), "%v: output differs", label)
			}
		}
	}
}

@test
legacy_test_growth_overshoot :: proc(t: ^testing.T) {
	for method in Legacy_Method {
		data, buffer := legacy_test_bomb(method, 130_000)
		defer delete(buffer)
		output: [dynamic]u8
		defer delete(output)
		testing.expect_value(t, legacy_test_unpack(method, &output, data, legacy_test_bomb_size(method, 130_000)), nil)
		testing.expectf(t, len(output) >= 40_000_000, "%v: only %v bytes", method, len(output))
		testing.expectf(t, cap(output) - len(output) <= 16 << 20, "%v: capacity %v for %v bytes", method, cap(output), len(output))
	}
}

legacy_test_bomb :: proc(method: Legacy_Method, units: int) -> (data: []u8, buffer: [dynamic]u8) {
	switch method {
	case .Shrink:
		w: Shrink_Writer
		shrink_bomb(&w, units / 10)
		data   = shrink_finish(&w)
		buffer = w.buffer
	case .Reduce:
		w: Reduce_Writer
		reduce_bomb(&w, units)
		data   = reduce_finish(&w)
		buffer = w.buffer
	case .Implode:
		w: Implode_Writer
		implode_bomb(&w, units)
		data   = implode_finish(&w)
		buffer = w.buffer
	}
	return
}

legacy_test_generated :: proc(method: Legacy_Method, size: int) -> (data: []u8, buffer: [dynamic]u8) {
	switch method {
	case .Shrink:
		g := Lz4_Test_Lcg{state = 0x5a1d}
		literals := lz4_test_lcg_bytes(&g, size)
		defer delete(literals)
		w: Shrink_Writer
		shrink_writer_init(&w)
		for b in literals {
			shrink_put(&w, int(b))
		}
		data   = shrink_finish(&w)
		buffer = w.buffer
	case .Reduce:
		w := legacy_stream_reduce(7, 1, size)
		data   = reduce_finish(&w)
		buffer = w.buffer
	case .Implode:
		w := legacy_stream_implode(7, 0, size)
		data   = implode_finish(&w)
		buffer = w.buffer
	}
	return
}

legacy_test_bomb_size :: proc(method: Legacy_Method, units: int) -> int {
	switch method {
	case .Shrink:  return shrink_bomb_size(units / 10)
	case .Reduce:  return 1 + units * (127 + 255 + 3)
	case .Implode: return 1 + units * (63 + 255 + 2)
	}
	return 0
}

legacy_test_unpack :: proc(method: Legacy_Method, output: ^[dynamic]u8, data: []u8, expected: int, options: compress.Options = {}) -> compress.Error {
	switch method {
	case .Shrink:  return pkzip_legacy.unshrink(output, data, expected, options)
	case .Reduce:  return pkzip_legacy.expand(output, data, 1, expected, options)
	case .Implode: return pkzip_legacy.explode(output, data, {}, expected, options)
	}
	return nil
}

legacy_test_unpack_context :: proc(method: Legacy_Method, ctx: ^compress.Context, expected: int, options: compress.Options = {}) -> compress.Error {
	switch method {
	case .Shrink:  return pkzip_legacy.unshrink(ctx, expected, options)
	case .Reduce:  return pkzip_legacy.expand(ctx, 1, expected, options)
	case .Implode: return pkzip_legacy.explode(ctx, {}, expected, options)
	}
	return nil
}
