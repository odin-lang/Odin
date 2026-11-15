package test_core_compress

import "core:bytes"
import "core:compress"
import pkzip_legacy "core:compress/pkzip-legacy"
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
		testing.expect_value(t, legacy_test_unpack(method, &full, data, legacy_test_bomb_size(method, 1_000), compress.COMPRESS_OUTPUT_ALLOCATE_MAX), nil)

		for kind in Stream_Kind {
			input := data
			output: [dynamic]u8
			defer delete(output)
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr, &output)
			err := legacy_test_unpack_context(method, &ctx, len(full), compress.COMPRESS_OUTPUT_ALLOCATE_MAX)
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
		testing.expect_value(t, legacy_test_unpack(method, &full, data, legacy_test_bomb_size(method, 1_000), compress.COMPRESS_OUTPUT_ALLOCATE_MAX), nil)

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
			err := legacy_test_unpack(method, &output, data, c.expected, c.limit)
			testing.expectf(t, err == c.want, "%v %v: %v, want %v", method, c, err, c.want)
			testing.expectf(t, cap(output) <= max(c.limit, 0), "%v %v: capacity %v", method, c, cap(output))
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
		testing.expect_value(t, legacy_test_unpack(method, &output, data, legacy_test_bomb_size(method, 130_000), compress.COMPRESS_OUTPUT_ALLOCATE_MAX), nil)
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

legacy_test_bomb_size :: proc(method: Legacy_Method, units: int) -> int {
	switch method {
	case .Shrink:  return shrink_bomb_size(units / 10)
	case .Reduce:  return 1 + units * (127 + 255 + 3)
	case .Implode: return 1 + units * (63 + 255 + 2)
	}
	return 0
}

legacy_test_unpack :: proc(method: Legacy_Method, output: ^[dynamic]u8, data: []u8, expected, limit: int) -> compress.Error {
	switch method {
	case .Shrink:  return pkzip_legacy.unshrink(output, data, expected, limit)
	case .Reduce:  return pkzip_legacy.expand(output, data, 1, expected, limit)
	case .Implode: return pkzip_legacy.explode(output, data, {}, expected, limit)
	}
	return nil
}

legacy_test_unpack_context :: proc(method: Legacy_Method, ctx: ^compress.Context, expected, limit: int) -> compress.Error {
	switch method {
	case .Shrink:  return pkzip_legacy.unshrink(ctx, expected, limit)
	case .Reduce:  return pkzip_legacy.expand(ctx, 1, expected, limit)
	case .Implode: return pkzip_legacy.explode(ctx, {}, expected, limit)
	}
	return nil
}
