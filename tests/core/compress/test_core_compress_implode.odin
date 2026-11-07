package test_core_compress

import "core:bytes"
import "core:compress"
import pkzip_legacy "core:compress/pkzip-legacy"
import "core:hash"
import "core:log"
import "core:os"
import "core:strings"
import "core:testing"
import "core:time"

Implode_Code_Table :: struct {
	lengths: [256]u8,
	codes:   [256]int,
	count:   int,
}

Implode_Writer :: struct {
	buffer:    [dynamic]u8,
	bits:      u64,
	count:     uint,
	options:   pkzip_legacy.Implode_Options,
	literals:  Implode_Code_Table,
	lengths:   Implode_Code_Table,
	distances: Implode_Code_Table,
}

@test
implode_test_reference :: proc(t: ^testing.T) {
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
		if m.method != .Imploded {
			continue
		}
		found += 1
		options: pkzip_legacy.Implode_Options
		if m.flags & 2 != 0 {
			options += {.Large_Window}
		}
		if m.flags & 4 != 0 {
			options += {.Literal_Tree}
		}

		for mode in 0..<3 {
			output: [dynamic]u8
			defer delete(output)

			err: compress.Error
			switch mode {
			case 0:
				err = pkzip_legacy.explode(&output, m.data, options, m.unpacked)
			case 1:
				r   := Trickle_Reader{data = m.data, chunk = 1}
				ctx := compress.init_context(trickle_stream(&r), &output, i64(m.unpacked))
				err  = pkzip_legacy.explode(&ctx, options)
				compress.destroy_context(&ctx)
			case 2:
				br: bytes.Reader
				ctx := compress.init_context(bytes.reader_init(&br, m.data), &output)
				err  = pkzip_legacy.explode(&ctx, options, m.unpacked)
				compress.destroy_context(&ctx)
			}
			testing.expectf(t, err == nil, "%v (mode %v): %v", m.name, mode, err)
			testing.expectf(t, len(output) == m.unpacked, "%v (mode %v): size %v, expected %v", m.name, mode, len(output), m.unpacked)
			testing.expectf(t, hash.crc32(output[:]) == m.crc, "%v (mode %v): CRC mismatch", m.name, mode)
		}

		{
			output: [dynamic]u8
			defer delete(output)
			err := pkzip_legacy.explode(&output, m.data, options)
			testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v (unsized): %v", m.name, err)
			testing.expectf(t, cap(output) == 0, "%v (unsized): reserved %v bytes", m.name, cap(output))
		}

		for cut in ([]int{1, 50, len(m.data) / 2, len(m.data) - 1}) {
			if cut <= 0 || cut >= len(m.data) {
				continue
			}
			output: [dynamic]u8
			defer delete(output)
			err := pkzip_legacy.explode(&output, m.data[:cut], options, m.unpacked)
			testing.expectf(t, err != nil, "%v: truncated to %v bytes didn't fail", m.name, cut)
			testing.expectf(t, len(output) <= m.unpacked, "%v: truncated wrote %v bytes", m.name, len(output))
		}
	}
	testing.expectf(t, found >= 9, "expected at least 9 Imploded members, found %v", found)
}

@test
implode_test_handcrafted :: proc(t: ^testing.T) {
	all_options := []pkzip_legacy.Implode_Options{{}, {.Large_Window}, {.Literal_Tree}, {.Large_Window, .Literal_Tree}}
	for options in all_options {
		window := 8192 if .Large_Window in options else 4096

		w: Implode_Writer
		defer delete(w.buffer)
		implode_writer_init(&w, options)
		implode_literal(&w, 'a')
		implode_literal(&w, 'b')
		implode_literal(&w, 'c')
		implode_match(&w, 3, 4)
		implode_match(&w, 1, 70)
		implode_match(&w, window, 5)
		implode_literal(&w, 'z')
		data := implode_finish(&w)

		expected := strings.concatenate({"abcabca", strings.repeat("a", 70, context.temp_allocator), "\x00\x00\x00\x00\x00", "z"}, context.temp_allocator)

		for mode in 0..<2 {
			output: [dynamic]u8
			defer delete(output)
			err: compress.Error
			if mode == 0 {
				err = pkzip_legacy.explode(&output, data, options, len(expected))
			} else {
				r   := Trickle_Reader{data = data, chunk = 1}
				ctx := compress.init_context(trickle_stream(&r), &output, i64(len(expected)))
				err  = pkzip_legacy.explode(&ctx, options)
				compress.destroy_context(&ctx)
			}
			testing.expectf(t, err == nil, "%v (mode %v): %v", options, mode, err)
			testing.expectf(t, string(output[:]) == expected, "%v (mode %v): %q", options, mode, string(output[:]))
		}

		{
			output: [dynamic]u8
			defer delete(output)
			append(&output, "PREFIX")
			err := pkzip_legacy.explode(&output, data, options, len(expected))
			testing.expectf(t, err == nil, "%v (prefix): %v", options, err)
			testing.expectf(t, string(output[6:]) == expected, "%v (prefix): %q", options, string(output[6:]))
		}

		{
			output: [dynamic]u8
			defer delete(output)
			err := pkzip_legacy.explode(&output, data, options, len(expected) + 1)
			testing.expectf(t, err == compress.General_Error.Stream_Too_Short, "%v (too short): %v", options, err)
		}

		{
			output: [dynamic]u8
			defer delete(output)
			err := pkzip_legacy.explode(&output, data, options, 10)
			testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v (match too long): %v", options, err)
			testing.expectf(t, len(output) <= 10, "%v (match too long): wrote %v bytes", options, len(output))
		}
	}

	{
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.explode(&output, {}, {}, 0)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, len(output), 0)
	}
}

@test
implode_test_malformed :: proc(t: ^testing.T) {
	Case :: struct {
		name: string,
		tree: []u8,
		err:  compress.Error,
	}
	cases := []Case{
		{"too many symbols", {4, 0xf5, 0xf5, 0xf5, 0xf5, 0xf5}, pkzip_legacy.PKZIP_Legacy_Error.Invalid_Tree},
		{"too few symbols",  {2, 0xf5, 0xf5, 0xf5},             pkzip_legacy.PKZIP_Legacy_Error.Invalid_Tree},
		{"oversubscribed",   {3, 0xf0, 0xf0, 0xf0, 0xf0},       pkzip_legacy.PKZIP_Legacy_Error.Invalid_Tree},
		{"truncated",        {3, 0xf5, 0xf5},                   compress.General_Error.Stream_Too_Short},
		{"empty",            {},                                compress.General_Error.Stream_Too_Short},
	}
	for c in cases {
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.explode(&output, c.tree, {}, 100)
		testing.expectf(t, err == c.err, "%v: %v, expected %v", c.name, err, c.err)
	}

	{
		w: Implode_Writer
		defer delete(w.buffer)
		sevens: [64]u8
		for &length in sevens {
			length = 7
		}
		implode_writer_init(&w, {}, distances = sevens[:])
		implode_literal(&w, 'a')
		implode_put_bits(&w, 0, 1)
		implode_put_bits(&w, 0, 6)
		implode_put_bits(&w, 0xffff, 16)
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.explode(&output, implode_finish(&w), {}, 100)
		testing.expect_value(t, err, pkzip_legacy.PKZIP_Legacy_Error.Invalid_Code)
		testing.expect_value(t, string(output[:]), "a")
	}
}

@test
implode_test_output_limit :: proc(t: ^testing.T) {
	w: Implode_Writer
	defer delete(w.buffer)
	implode_bomb(&w, 3_000)
	data := implode_finish(&w)

	full: [dynamic]u8
	defer delete(full)
	err := pkzip_legacy.explode(&full, data, {}, 1 + 3_000 * (63 + 255 + 2))
	testing.expect_value(t, err, nil)
	log.infof("bomb: %v bytes in, %v bytes out", len(data), len(full))
	testing.expect(t, len(full) > 100 * len(data))

	{
		output: [dynamic]u8
		defer delete(output)
		limit_err := pkzip_legacy.explode(&output, data, {}, len(full), len(full) - 1)
		testing.expect_value(t, limit_err, compress.General_Error.Output_Too_Short)
		testing.expect_value(t, cap(output), 0)
	}

	for limit in ([]int{100, 320, 4096, len(full) - 1}) {
		output: [dynamic]u8
		defer delete(output)
		limit_err := pkzip_legacy.explode(&output, data, {}, limit)
		testing.expectf(t, limit_err == compress.General_Error.Output_Too_Short, "limit %v: %v", limit, limit_err)
		testing.expectf(t, len(output) <= limit, "limit %v: wrote %v bytes", limit, len(output))
	}

	{
		output: [dynamic]u8
		defer delete(output)
		exact_err := pkzip_legacy.explode(&output, data, {}, len(full))
		testing.expect_value(t, exact_err, nil)
		testing.expect(t, bytes.equal(output[:], full[:]))
	}
}

@test
implode_test_reservation :: proc(t: ^testing.T) {
	w: Implode_Writer
	defer delete(w.buffer)
	implode_writer_init(&w, {})
	implode_literal(&w, 'A')
	data := implode_finish(&w)

	{
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.explode(&output, data, {}, compress.COMPRESS_OUTPUT_ALLOCATE_MAX + 1)
		testing.expect_value(t, err, compress.General_Error.Output_Too_Short)
		testing.expect_value(t, cap(output), 0)
	}
	{
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.explode(&output, data, {}, compress.COMPRESS_OUTPUT_ALLOCATE_MAX)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
		testing.expectf(t, cap(output) <= 1 << 20, "reserved %v bytes for a %v byte input", cap(output), len(data))
	}
	{
		output: [dynamic]u8
		defer delete(output)
		r   := Trickle_Reader{data = data, chunk = 1}
		ctx := compress.init_context(trickle_stream(&r), &output, i64(compress.COMPRESS_OUTPUT_ALLOCATE_MAX))
		err := pkzip_legacy.explode(&ctx, {})
		compress.destroy_context(&ctx)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
		testing.expectf(t, cap(output) <= 1 << 20, "reserved %v bytes for an unsized stream", cap(output))
	}
}

@test
implode_test_large_output :: proc(t: ^testing.T) {
	w: Implode_Writer
	defer delete(w.buffer)
	implode_bomb(&w, 100_000)
	data := implode_finish(&w)

	output: [dynamic]u8
	defer delete(output)
	start   := time.tick_now()
	err     := pkzip_legacy.explode(&output, data, {}, 1 + 100_000 * (63 + 255 + 2))
	elapsed := time.tick_since(start)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(output), 1 + 100_000 * (63 + 255 + 2))
	log.infof("large output: %v bytes in, %v bytes out, %v", len(data), len(output), elapsed)
	testing.expectf(t, elapsed < 2 * time.Second, "large output took %v", elapsed)
}

implode_table :: proc(lengths: []u8) -> (t: Implode_Code_Table) {
	t.count = len(lengths)
	copy(t.lengths[:], lengths)
	code := 0
	for length := 16; length >= 1; length -= 1 {
		value := code >> uint(16 - length)
		for symbol := t.count - 1; symbol >= 0; symbol -= 1 {
			if int(t.lengths[symbol]) == length {
				t.codes[symbol] = value
				value += 1
				code  += 1 << uint(16 - length)
			}
		}
	}
	return
}

implode_uniform :: proc(count: int, length: u8) -> []u8 {
	lengths := make([]u8, count, context.temp_allocator)
	for &l in lengths {
		l = length
	}
	return lengths
}

implode_writer_init :: proc(w: ^Implode_Writer, options: pkzip_legacy.Implode_Options, literals: []u8 = nil, lengths: []u8 = nil, distances: []u8 = nil) {
	w.options   = options
	w.literals  = implode_table(literals  if literals  != nil else implode_uniform(256, 8))
	w.lengths   = implode_table(lengths   if lengths   != nil else implode_uniform(64, 6))
	w.distances = implode_table(distances if distances != nil else implode_uniform(64, 6))
	if .Literal_Tree in options {
		implode_put_tree(w, &w.literals)
	}
	implode_put_tree(w, &w.lengths)
	implode_put_tree(w, &w.distances)
}

implode_put_tree :: proc(w: ^Implode_Writer, t: ^Implode_Code_Table) {
	runs := make([dynamic]u8, context.temp_allocator)
	for i := 0; i < t.count; {
		run := 1
		for i + run < t.count && t.lengths[i + run] == t.lengths[i] && run < 16 {
			run += 1
		}
		append(&runs, (t.lengths[i] - 1) | u8(run - 1) << 4)
		i += run
	}
	implode_put_bits(w, len(runs) - 1, 8)
	for b in runs {
		implode_put_bits(w, int(b), 8)
	}
}

implode_put_code :: proc(w: ^Implode_Writer, t: ^Implode_Code_Table, symbol: int) {
	for bit := int(t.lengths[symbol]) - 1; bit >= 0; bit -= 1 {
		implode_put_bits(w, t.codes[symbol] >> uint(bit) & 1, 1)
	}
}

implode_literal :: proc(w: ^Implode_Writer, value: u8) {
	implode_put_bits(w, 1, 1)
	if .Literal_Tree in w.options {
		implode_put_code(w, &w.literals, int(value))
	} else {
		implode_put_bits(w, int(value), 8)
	}
}

implode_match :: proc(w: ^Implode_Writer, distance, length: int) {
	low_bits  := uint(7 if .Large_Window in w.options else 6)
	min_match := 3 if .Literal_Tree in w.options else 2
	implode_put_bits(w, 0, 1)
	implode_put_bits(w, (distance - 1) & (1 << low_bits - 1), low_bits)
	implode_put_code(w, &w.distances, (distance - 1) >> low_bits)
	symbol := length - min_match
	if symbol >= 63 {
		implode_put_code(w, &w.lengths, 63)
		implode_put_bits(w, symbol - 63, 8)
	} else {
		implode_put_code(w, &w.lengths, symbol)
	}
}

implode_put_bits :: proc(w: ^Implode_Writer, value: int, bits: uint) {
	w.bits  |= u64(value) << w.count
	w.count += bits
	for w.count >= 8 {
		append(&w.buffer, u8(w.bits))
		w.bits  >>= 8
		w.count  -= 8
	}
}

implode_finish :: proc(w: ^Implode_Writer) -> []u8 {
	if w.count > 0 {
		append(&w.buffer, u8(w.bits))
		w.bits, w.count = 0, 0
	}
	return w.buffer[:]
}

implode_bomb :: proc(w: ^Implode_Writer, matches: int) {
	lengths   := implode_uniform(64, 7)
	distances := implode_uniform(64, 7)
	lengths[63]  = 1
	distances[0] = 1
	implode_writer_init(w, {}, lengths = lengths, distances = distances)
	implode_literal(w, 'a')
	for _ in 0..<matches {
		implode_match(w, 1, 63 + 255 + 2)
	}
}
