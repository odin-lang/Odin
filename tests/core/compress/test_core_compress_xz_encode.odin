package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/lzma"
import "core:compress/xz"
import "core:os"
import "core:testing"

@(test)
test_xz_round_trip :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)
	sources := [?][]u8{{}, {'A'}, inputs.text, inputs.random, inputs.mixed, inputs.chunks}

	chains := [?][]xz.Filter{
		{},
		{{id = .Delta, delta_distance = 4}},
		{{id = .X86}},
		{{id = .PowerPC, start_offset = 4096}},
		{{id = .Delta, delta_distance = 1}, {id = .X86}, {id = .ARM64}},
	}
	checks := [?]xz.Check{.None, .CRC32, .CRC64, .SHA256}

	for source in sources {
		block_sizes := [?]int{-1, 0, 16 * 1024, max(len(source) / 2, 1), max(len(source) / 2, 1) + 1}
		for chain in chains {
			for check in checks {
				for block_size in block_sizes {
					options := xz.Options{check = check, block_size = block_size, filter_count = len(chain)}
					copy(options.filters[:], chain)
					xz_round_trip(t, source, .Level_1, options)
				}
			}
		}
		for level in ([?]lzma.Level{.Level_0, .Level_5, .Level_9}) {
			xz_round_trip(t, source, level, {})
		}
	}
}

@(test)
test_xz_encode_empty_matches_xz :: proc(t: ^testing.T) {
	want, read_err := os.read_entire_file(xz_asset("empty.xz"), context.allocator)
	if !testing.expect_value(t, read_err, nil) {
		return
	}
	defer delete(want)
	got: [dynamic]u8
	defer delete(got)
	testing.expect_value(t, xz.compress(&got, nil), nil)
	testing.expectf(t, bytes.equal(got[:], want), "empty stream: % x", got[:])
}

@(test)
test_xz_encode_options :: proc(t: ^testing.T) {
	out: [dynamic]u8
	defer delete(out)
	data := []u8{1, 2, 3}

	bad_check := xz.Options{check = xz.Check(2)}
	testing.expect_value(t, xz.compress(&out, data, .Level_1, bad_check), compress.Error(compress.General_Error.Incompatible_Options))

	lzma2_filter := xz.Options{filter_count = 1}
	lzma2_filter.filters[0] = {id = .LZMA2}
	testing.expect_value(t, xz.compress(&out, data, .Level_1, lzma2_filter), compress.Error(compress.XZ_Error.Invalid_Filter_Chain))

	misaligned := xz.Options{filter_count = 1}
	misaligned.filters[0] = {id = .PowerPC, start_offset = 2}
	testing.expect_value(t, xz.compress(&out, data, .Level_1, misaligned), compress.Error(compress.XZ_Error.Invalid_Filter_Chain))

	delta := xz.Options{filter_count = 1}
	delta.filters[0] = {id = .Delta, delta_distance = 257}
	testing.expect_value(t, xz.compress(&out, data, .Level_1, delta), compress.Error(compress.XZ_Error.Invalid_Filter_Chain))

	too_many := xz.Options{filter_count = 4}
	testing.expect_value(t, xz.compress(&out, data, .Level_1, too_many), compress.Error(compress.XZ_Error.Invalid_Filter_Chain))

	testing.expect_value(t, xz.compress(&out, data, .Level_1, {check = .CRC32}), nil)
	testing.expect_value(t, out[7], 0x01)
	default_check: [dynamic]u8
	defer delete(default_check)
	testing.expect_value(t, xz.compress(&default_check, data), nil)
	testing.expect_value(t, default_check[7], 0x04)
}

xz_round_trip :: proc(t: ^testing.T, source: []u8, level: lzma.Level, options: xz.Options, loc := #caller_location) {
	packed: [dynamic]u8
	defer delete(packed)
	err := xz.compress(&packed, source, level, options)
	if !testing.expectf(t, err == nil, "%d bytes, %v: compress %v", len(source), options, err, loc = loc) {
		return
	}
	bound := xz.compress_bound(len(source), level, options)
	testing.expectf(t, bound >= len(packed), "%d bytes: bound %d < %d", len(source), bound, len(packed), loc = loc)

	plain: [dynamic]u8
	defer delete(plain)
	decode_err := xz.decompress(&plain, packed[:], {}, len(source))
	testing.expectf(t, decode_err == nil && bytes.equal(plain[:], source), "%d bytes, %v: decode %v", len(source), options, decode_err, loc = loc)

	exact := make([]u8, len(packed))
	defer delete(exact)
	written, slice_err := xz.compress(exact, source, level, options)
	testing.expectf(t, slice_err == nil && written == len(packed) && bytes.equal(exact, packed[:]), "%d bytes: slice %v, %d", len(source), slice_err, written, loc = loc)
	if len(packed) > 0 {
		_, short_err := xz.compress(exact[:len(exact) - 1], source, level, options)
		testing.expectf(t, short_err == compress.General_Error.Output_Too_Short, "%d bytes: one short %v", len(source), short_err, loc = loc)
	}
}
