package test_core_compress

import "core:bytes"
import "core:compress"
import pkzip_legacy "core:compress/pkzip-legacy"
import "core:hash"
import "core:log"
import "core:os"
import "core:testing"
import "core:time"

Reduce_Writer :: struct {
	buffer:    [dynamic]u8,
	bits:      u64,
	count:     uint,
	followers: [256][32]u8,
	counts:    [256]int,
	last:      int,
}

Reduce_Followers :: struct {
	value:     u8,
	followers: string,
}

Reduce_Case :: struct {
	name:     string,
	factor:   int,
	sets:     []Reduce_Followers,
	symbols:  []int,
	size:     int,
	expected: string,
	err:      compress.Error,
}

REDUCE_DLE :: pkzip_legacy.REDUCE_DLE

@test
reduce_test_reference :: proc(t: ^testing.T) {
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
		if m.method < .Reduced_1 || m.method > .Reduced_4 {
			continue
		}
		found += 1
		factor := int(m.method) - 1

		for mode in 0..<3 {
			output: [dynamic]u8
			defer delete(output)

			err: compress.Error
			switch mode {
			case 0:
				err = pkzip_legacy.expand(&output, m.data, factor, m.unpacked)
			case 1:
				r   := Trickle_Reader{data = m.data, chunk = 1}
				ctx := compress.init_context(trickle_stream(&r), &output, i64(m.unpacked))
				err  = pkzip_legacy.expand(&ctx, factor)
				compress.destroy_context(&ctx)
			case 2:
				br: bytes.Reader
				ctx := compress.init_context(bytes.reader_init(&br, m.data), &output)
				err  = pkzip_legacy.expand(&ctx, factor, m.unpacked)
				compress.destroy_context(&ctx)
			}
			testing.expectf(t, err == nil, "%v (mode %v): %v", m.name, mode, err)
			testing.expectf(t, len(output) == m.unpacked, "%v (mode %v): size %v, expected %v", m.name, mode, len(output), m.unpacked)
			testing.expectf(t, hash.crc32(output[:]) == m.crc, "%v (mode %v): CRC mismatch", m.name, mode)
		}

		{
			output: [dynamic]u8
			defer delete(output)
			err := pkzip_legacy.expand(&output, m.data, factor)
			testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v (unsized): %v", m.name, err)
			testing.expectf(t, cap(output) == 0, "%v (unsized): reserved %v bytes", m.name, cap(output))
		}

		for cut in ([]int{1, 100, len(m.data) / 2, len(m.data) - 1}) {
			if cut <= 0 || cut >= len(m.data) {
				continue
			}
			output: [dynamic]u8
			defer delete(output)
			err := pkzip_legacy.expand(&output, m.data[:cut], factor, m.unpacked)
			testing.expectf(t, err != nil, "%v: truncated to %v bytes didn't fail", m.name, cut)
			testing.expectf(t, len(output) <= m.unpacked, "%v: truncated wrote %v bytes", m.name, len(output))
		}
	}
	testing.expectf(t, found >= 20, "expected at least 20 Reduced members, found %v", found)
}

@test
reduce_test_handcrafted :: proc(t: ^testing.T) {
	cases := []Reduce_Case{
		{"literals",        1, {},                               {'A', 'B', 'C'},                    3,  "ABC",                nil},
		{"followers",       1, {{'A', "B"}, {'B', "XC"}},        {'A', 'B', 'C'},                    3,  "ABC",                nil},
		{"escaped",         1, {{'A', "B"}},                     {'A', 'Z'},                         2,  "AZ",                 nil},
		{"dle literal",     2, {},                               {REDUCE_DLE, 0, 'x'},               2,  "\x90x",              nil},
		{"match",           1, {},                               {'a', 'b', 'c', REDUCE_DLE, 1, 2},  7,  "abcabca",            nil},
		{"overlap",         1, {},                               {'a', REDUCE_DLE, 7, 0},            11, "aaaaaaaaaaa",        nil},
		{"factor 4",        4, {},                               {'x', 'y', 'z', REDUCE_DLE, 1, 2},  7,  "xyzxyzx",            nil},
		{"before start",    4, {},                               {'q', REDUCE_DLE, 0xf1, 0xff},      5,  "q\x00\x00\x00\x00",  nil},
		{"unsized end",     1, {},                               {'a', REDUCE_DLE},                  -1, "",                   compress.General_Error.Incompatible_Options},
		{"empty",           1, {},                               {},                                 0,  "",                   nil},
		{"too short",       1, {},                               {'A', 'B', 'C'},                    10, "",                   compress.General_Error.Stream_Too_Short},
		{"match too long",  1, {},                               {'a', REDUCE_DLE, 7, 0},            5,  "",                   compress.General_Error.Output_Too_Short},
		{"literal too long",1, {},                               {'A', 'B', 'C'},                    2,  "AB",                 nil},
		{"factor 0",        0, {},                               {'A'},                              1,  "",                   compress.General_Error.Incompatible_Options},
		{"factor 5",        5, {},                               {'A'},                              1,  "",                   compress.General_Error.Incompatible_Options},
	}

	for c in cases {
		w: Reduce_Writer
		defer delete(w.buffer)
		if c.name != "empty" {
			reduce_writer_init(&w, c.sets)
		}
		for symbol in c.symbols {
			reduce_put_symbol(&w, symbol)
		}
		data := reduce_finish(&w)

		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.expand(&output, data, c.factor, c.size)
		testing.expectf(t, err == c.err, "%v: error %v, expected %v", c.name, err, c.err)
		if c.err == nil {
			testing.expectf(t, string(output[:]) == c.expected, "%v: %q, expected %q", c.name, string(output[:]), c.expected)
		} else if c.size >= 0 {
			testing.expectf(t, len(output) <= c.size, "%v: wrote %v bytes", c.name, len(output))
		}
	}
}

@test
reduce_test_length_extension :: proc(t: ^testing.T) {
	w: Reduce_Writer
	defer delete(w.buffer)
	reduce_writer_init(&w, {})
	reduce_put_symbol(&w, 'a')
	reduce_put_symbol(&w, REDUCE_DLE)
	reduce_put_symbol(&w, 127)
	reduce_put_symbol(&w, 10)
	reduce_put_symbol(&w, 0)
	data := reduce_finish(&w)

	output: [dynamic]u8
	defer delete(output)
	err := pkzip_legacy.expand(&output, data, 1, 1 + 127 + 10 + 3)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(output), 1 + 127 + 10 + 3)
	for b in output {
		testing.expect_value(t, b, 'a')
	}
}

@test
reduce_test_prefix :: proc(t: ^testing.T) {
	w: Reduce_Writer
	defer delete(w.buffer)
	reduce_writer_init(&w, {})
	for symbol in ([]int{'q', REDUCE_DLE, 0xf1, 0xff}) {
		reduce_put_symbol(&w, symbol)
	}
	data := reduce_finish(&w)

	output: [dynamic]u8
	defer delete(output)
	append(&output, "PREFIX")
	err := pkzip_legacy.expand(&output, data, 4, 5)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(output[:]), "PREFIXq\x00\x00\x00\x00")
}

@test
reduce_test_malformed :: proc(t: ^testing.T) {
	{
		w: Reduce_Writer
		defer delete(w.buffer)
		reduce_put_bits(&w, 33, 6)
		for _ in 0..<33 {
			reduce_put_bits(&w, 'A', 8)
		}
		for _ in 0..<255 {
			reduce_put_bits(&w, 0, 6)
		}
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.expand(&output, reduce_finish(&w), 1, 100)
		testing.expect_value(t, err, pkzip_legacy.PKZIP_Legacy_Error.Invalid_Follower_Set)
	}
	{
		w: Reduce_Writer
		defer delete(w.buffer)
		reduce_writer_init(&w, {{'A', "BCD"}})
		reduce_put_symbol(&w, 'A')
		reduce_put_bits(&w, 0, 1)
		reduce_put_bits(&w, 3, 2)
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.expand(&output, reduce_finish(&w), 1, 100)
		testing.expect_value(t, err, pkzip_legacy.PKZIP_Legacy_Error.Invalid_Follower_Index)
		testing.expect_value(t, string(output[:]), "A")
	}
	{
		header: [100]u8
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.expand(&output, header[:], 1, 100)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
	}
	{
		w: Reduce_Writer
		defer delete(w.buffer)
		reduce_put_bits(&w, 32, 6)
		for _ in 0..<10 {
			reduce_put_bits(&w, 'A', 8)
		}
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.expand(&output, reduce_finish(&w), 1, 100)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
	}
}

@test
reduce_test_output_limit :: proc(t: ^testing.T) {
	w: Reduce_Writer
	defer delete(w.buffer)
	reduce_bomb(&w, 3_000)
	data := reduce_finish(&w)

	full: [dynamic]u8
	defer delete(full)
	err := pkzip_legacy.expand(&full, data, 1, 1 + 3_000 * (127 + 255 + 3))
	testing.expect_value(t, err, nil)
	log.infof("bomb: %v bytes in, %v bytes out", len(data), len(full))
	testing.expect(t, len(full) > 300 * len(data))

	{
		output: [dynamic]u8
		defer delete(output)
		limit_err := pkzip_legacy.expand(&output, data, 1, len(full), len(full) - 1)
		testing.expect_value(t, limit_err, compress.General_Error.Output_Too_Short)
		testing.expect_value(t, cap(output), 0)
	}

	for limit in ([]int{100, 385, 4096, len(full) - 1}) {
		output: [dynamic]u8
		defer delete(output)
		limit_err := pkzip_legacy.expand(&output, data, 1, limit)
		testing.expectf(t, limit_err == compress.General_Error.Output_Too_Short, "limit %v: %v", limit, limit_err)
		testing.expectf(t, len(output) <= limit, "limit %v: wrote %v bytes", limit, len(output))
	}

	{
		output: [dynamic]u8
		defer delete(output)
		exact_err := pkzip_legacy.expand(&output, data, 1, len(full))
		testing.expect_value(t, exact_err, nil)
		testing.expect(t, bytes.equal(output[:], full[:]))
	}
}

@test
reduce_test_reservation :: proc(t: ^testing.T) {
	w: Reduce_Writer
	defer delete(w.buffer)
	reduce_writer_init(&w, {})
	reduce_put_symbol(&w, 'A')
	data := reduce_finish(&w)

	{
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.expand(&output, data, 1, compress.COMPRESS_OUTPUT_ALLOCATE_MAX + 1)
		testing.expect_value(t, err, compress.General_Error.Output_Too_Short)
		testing.expect_value(t, cap(output), 0)
	}
	{
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.expand(&output, data, 1, compress.COMPRESS_OUTPUT_ALLOCATE_MAX)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
		testing.expectf(t, cap(output) <= 1 << 20, "reserved %v bytes for a %v byte input", cap(output), len(data))
	}
	{
		output: [dynamic]u8
		defer delete(output)
		r   := Trickle_Reader{data = data, chunk = 1}
		ctx := compress.init_context(trickle_stream(&r), &output, i64(compress.COMPRESS_OUTPUT_ALLOCATE_MAX))
		err := pkzip_legacy.expand(&ctx, 1)
		compress.destroy_context(&ctx)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
		testing.expectf(t, cap(output) <= compress.INITIAL_RESERVATION, "reserved %v bytes for an unsized stream", cap(output))
	}
}

@test
reduce_test_large_output :: proc(t: ^testing.T) {
	w: Reduce_Writer
	defer delete(w.buffer)
	reduce_bomb(&w, 100_000)
	data := reduce_finish(&w)

	output: [dynamic]u8
	defer delete(output)
	start   := time.tick_now()
	err     := pkzip_legacy.expand(&output, data, 1, 1 + 100_000 * (127 + 255 + 3))
	elapsed := time.tick_since(start)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(output), 1 + 100_000 * (127 + 255 + 3))
	log.infof("large output: %v bytes in, %v bytes out, %v", len(data), len(output), elapsed)
	if !SLIM_TESTS {
		testing.expectf(t, elapsed < 2 * time.Second, "large output took %v", elapsed)
	}
}

reduce_writer_init :: proc(w: ^Reduce_Writer, sets: []Reduce_Followers) {
	for set in sets {
		w.counts[set.value] = len(set.followers)
		copy(w.followers[set.value][:], set.followers)
	}
	for i := 255; i >= 0; i -= 1 {
		reduce_put_bits(w, w.counts[i], 6)
		for j in 0..<w.counts[i] {
			reduce_put_bits(w, int(w.followers[i][j]), 8)
		}
	}
}

reduce_put_symbol :: proc(w: ^Reduce_Writer, symbol: int) {
	count := w.counts[w.last]
	if count == 0 {
		reduce_put_bits(w, symbol, 8)
	} else {
		index := -1
		for j in 0..<count {
			if int(w.followers[w.last][j]) == symbol {
				index = j
				break
			}
		}
		if index < 0 {
			reduce_put_bits(w, 1, 1)
			reduce_put_bits(w, symbol, 8)
		} else {
			bits := uint(1)
			for 1 << bits < count {
				bits += 1
			}
			reduce_put_bits(w, 0, 1)
			reduce_put_bits(w, index, bits)
		}
	}
	w.last = symbol
}

reduce_put_bits :: proc(w: ^Reduce_Writer, value: int, bits: uint) {
	w.bits  |= u64(value) << w.count
	w.count += bits
	for w.count >= 8 {
		append(&w.buffer, u8(w.bits))
		w.bits  >>= 8
		w.count  -= 8
	}
}

reduce_finish :: proc(w: ^Reduce_Writer) -> []u8 {
	if w.count > 0 {
		append(&w.buffer, u8(w.bits))
		w.bits, w.count = 0, 0
	}
	return w.buffer[:]
}

reduce_bomb :: proc(w: ^Reduce_Writer, matches: int) {
	reduce_writer_init(w, {{'a', "\x90"}, {REDUCE_DLE, "\x7f"}, {0x7f, "\xff"}, {0xff, "\x00"}, {0x00, "\x90"}})
	reduce_put_symbol(w, 'a')
	for _ in 0..<matches {
		reduce_put_symbol(w, REDUCE_DLE)
		reduce_put_symbol(w, 0x7f)
		reduce_put_symbol(w, 0xff)
		reduce_put_symbol(w, 0x00)
	}
}
