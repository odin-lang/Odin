package test_core_compress

import "core:bytes"
import "core:compress"
import pkzip_legacy "core:compress/pkzip-legacy"
import "core:encoding/endian"
import "core:hash"
import "core:log"
import "core:os"
import "core:testing"
import "core:time"

TEST_SUITE_PATH_ZIP :: ODIN_ROOT + "tests/core/assets/ZIP"

Shrink_Writer :: struct {
	buffer:    [dynamic]u8,
	bits:      u64,
	count:     uint,
	code_size: uint,
}

Legacy_Method_Id :: enum u16 {
	Stored    = 0,
	Shrunk    = 1,
	Reduced_1 = 2,
	Reduced_2 = 3,
	Reduced_3 = 4,
	Reduced_4 = 5,
	Imploded  = 6,
}

Legacy_Member :: struct {
	name:     string,
	method:   Legacy_Method_Id,
	flags:    u16,
	data:     []u8,
	unpacked: int,
	crc:      u32,
}

SHRINK_INCREASE :: -1
SHRINK_CLEAR    :: -2

@test
shrink_test_reference :: proc(t: ^testing.T) {
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
		if m.method != .Shrunk {
			continue
		}
		found += 1
		for mode in 0..<4 {
			output: [dynamic]u8
			defer delete(output)

			err: compress.Error
			switch mode {
			case 0:
				err = pkzip_legacy.unshrink(&output, m.data, m.unpacked)
			case 1:
				err = pkzip_legacy.unshrink(&output, m.data, m.unpacked, m.unpacked)
			case 2:
				r   := Trickle_Reader{data = m.data, chunk = 1}
				ctx := compress.init_context(trickle_stream(&r), &output, i64(m.unpacked))
				err  = pkzip_legacy.unshrink(&ctx)
				compress.destroy_context(&ctx)
			case 3:
				br: bytes.Reader
				ctx := compress.init_context(bytes.reader_init(&br, m.data), &output)
				err  = pkzip_legacy.unshrink(&ctx, m.unpacked)
				compress.destroy_context(&ctx)
			}
			testing.expectf(t, err == nil, "%v (mode %v): %v", m.name, mode, err)
			testing.expectf(t, len(output) == m.unpacked, "%v (mode %v): size %v, expected %v", m.name, mode, len(output), m.unpacked)
			testing.expectf(t, hash.crc32(output[:]) == m.crc, "%v (mode %v): CRC mismatch", m.name, mode)
		}

		{
			output: [dynamic]u8
			defer delete(output)
			err := pkzip_legacy.unshrink(&output, m.data)
			testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v (unsized): %v", m.name, err)
			testing.expectf(t, cap(output) == 0, "%v (unsized): reserved %v bytes", m.name, cap(output))
		}

		for cut in ([]int{1, len(m.data) / 2, len(m.data) - 1}) {
			if cut <= 0 || cut >= len(m.data) {
				continue
			}
			output: [dynamic]u8
			defer delete(output)
			err := pkzip_legacy.unshrink(&output, m.data[:cut], m.unpacked)
			testing.expectf(t, err != nil, "%v: truncated to %v bytes didn't fail", m.name, cut)
			testing.expectf(t, len(output) <= m.unpacked, "%v: truncated wrote %v bytes", m.name, len(output))
		}
	}
	testing.expectf(t, found >= 5, "expected at least 5 Shrunk members, found %v", found)
}

@test
shrink_test_handcrafted :: proc(t: ^testing.T) {
	Case :: struct {
		name:     string,
		codes:    []int,
		expected: string,
		err:      compress.Error,
	}
	cases := []Case{
		{"empty",           {},                                                        "",       nil},
		{"literal",         {'A'},                                                     "A",      nil},
		{"literals",        {'A', 'B', 'C'},                                           "ABC",    nil},
		{"kwkwk",           {'a', 257},                                                "aaa",    nil},
		{"stops at size",   {'A', 'B', 'C'},                                           "AB",     nil},
		{"kwkwk chain",     {'a', 257, 258},                                           "aaaaaa", nil},
		{"reuse",           {'a', 'b', 257, 258},                                      "ababba", nil},
		{"increase",        {'A', SHRINK_INCREASE, 'B'},                               "AB",     nil},
		{"leading control", {SHRINK_INCREASE, 'A'},                                    "A",      nil},
		{"clear",           {'a', 'b', SHRINK_CLEAR, 'c', 257},                        "abcbc",  nil},
		{"max code size",   {'A', SHRINK_INCREASE, SHRINK_INCREASE, SHRINK_INCREASE, SHRINK_INCREASE, 'B'}, "AB", nil},
		{"first code high", {300},                                                     "",       pkzip_legacy.PKZIP_Legacy_Error.Invalid_First_Code},
		{"code too large",  {'A', SHRINK_INCREASE, SHRINK_INCREASE, SHRINK_INCREASE, SHRINK_INCREASE, SHRINK_INCREASE}, "", pkzip_legacy.PKZIP_Legacy_Error.Code_Size_Too_Large},
		{"unused code",     {'a', 300},                                                "",       pkzip_legacy.PKZIP_Legacy_Error.Invalid_Code},
		{"kwkwk skip",      {'a', 258},                                                "",       pkzip_legacy.PKZIP_Legacy_Error.Invalid_Code},
		{"self reference",  {'a', 257, SHRINK_CLEAR, 'b', 257},                        "",       pkzip_legacy.PKZIP_Legacy_Error.Invalid_Code},
	}

	for c in cases {
		w: Shrink_Writer
		shrink_writer_init(&w)
		defer delete(w.buffer)
		for code in c.codes {
			shrink_put(&w, code)
		}
		data := shrink_finish(&w)

		output: [dynamic]u8
		defer delete(output)
		size := len(c.expected) if c.err == nil else 100
		err  := pkzip_legacy.unshrink(&output, data, size)
		testing.expectf(t, err == c.err, "%v: error %v, expected %v", c.name, err, c.err)
		if c.err == nil {
			testing.expectf(t, string(output[:]) == c.expected, "%v: %q, expected %q", c.name, string(output[:]), c.expected)
		}
	}
}

@test
shrink_test_control_errors :: proc(t: ^testing.T) {
	{
		w: Shrink_Writer
		shrink_writer_init(&w)
		defer delete(w.buffer)
		shrink_put(&w, 'A')
		shrink_put(&w, pkzip_legacy.SHRINK_CONTROL_CODE)
		shrink_put(&w, 3)

		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.unshrink(&output, shrink_finish(&w), 100)
		testing.expect_value(t, err, pkzip_legacy.PKZIP_Legacy_Error.Invalid_Control_Code)
	}
	{
		w: Shrink_Writer
		shrink_writer_init(&w)
		defer delete(w.buffer)
		shrink_put(&w, 'A')
		shrink_put(&w, 'B')
		shrink_put(&w, 'C')
		shrink_put(&w, pkzip_legacy.SHRINK_CONTROL_CODE)

		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.unshrink(&output, shrink_finish(&w), 100)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
	}
}

@test
shrink_test_output_limit :: proc(t: ^testing.T) {
	w: Shrink_Writer
	defer delete(w.buffer)
	shrink_bomb(&w, 3_000)
	data := shrink_finish(&w)

	full: [dynamic]u8
	defer delete(full)
	err := pkzip_legacy.unshrink(&full, data, shrink_bomb_size(3_000))
	testing.expect_value(t, err, nil)
	log.infof("bomb: %v bytes in, %v bytes out", len(data), len(full))
	testing.expect(t, len(full) > 500 * len(data))

	{
		output: [dynamic]u8
		defer delete(output)
		limit_err := pkzip_legacy.unshrink(&output, data, len(full), len(full) - 1)
		testing.expect_value(t, limit_err, compress.General_Error.Output_Too_Short)
		testing.expect_value(t, cap(output), 0)
	}

	for limit in ([]int{2, 100, 4096, len(full) - 1}) {
		output: [dynamic]u8
		defer delete(output)
		limit_err := pkzip_legacy.unshrink(&output, data, limit)
		testing.expectf(t, limit_err == compress.General_Error.Output_Too_Short, "limit %v: %v", limit, limit_err)
		testing.expectf(t, len(output) <= limit, "limit %v: wrote %v bytes", limit, len(output))
	}

	{
		output: [dynamic]u8
		defer delete(output)
		append(&output, "prefix")
		limit_err := pkzip_legacy.unshrink(&output, data, 11)
		testing.expect_value(t, limit_err, compress.General_Error.Output_Too_Short)
		testing.expect(t, len(output) <= 17)
		testing.expect_value(t, string(output[:6]), "prefix")
	}

	{
		output: [dynamic]u8
		defer delete(output)
		exact_err := pkzip_legacy.unshrink(&output, data, len(full))
		testing.expect_value(t, exact_err, nil)
		testing.expect(t, bytes.equal(output[:], full[:]))
	}
}

@test
shrink_test_reservation :: proc(t: ^testing.T) {
	data := []u8{'A', 0}

	{
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.unshrink(&output, data, compress.COMPRESS_OUTPUT_ALLOCATE_MAX + 1)
		testing.expect_value(t, err, compress.General_Error.Output_Too_Short)
		testing.expect_value(t, cap(output), 0)
	}
	{
		output: [dynamic]u8
		defer delete(output)
		err := pkzip_legacy.unshrink(&output, data, compress.COMPRESS_OUTPUT_ALLOCATE_MAX)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
		testing.expectf(t, cap(output) <= 1 << 20, "reserved %v bytes for a %v byte input", cap(output), len(data))
	}
	{
		output: [dynamic]u8
		defer delete(output)
		r   := Trickle_Reader{data = data, chunk = 1}
		ctx := compress.init_context(trickle_stream(&r), &output, i64(compress.COMPRESS_OUTPUT_ALLOCATE_MAX))
		err := pkzip_legacy.unshrink(&ctx)
		compress.destroy_context(&ctx)
		testing.expect_value(t, err, compress.General_Error.Stream_Too_Short)
		testing.expectf(t, cap(output) <= 1 << 20, "reserved %v bytes for an unsized stream", cap(output))
	}
}

@test
shrink_test_clear_flood :: proc(t: ^testing.T) {
	w: Shrink_Writer
	shrink_writer_init(&w)
	defer delete(w.buffer)
	for _ in pkzip_legacy.SHRINK_FIRST_FREE_CODE..=pkzip_legacy.SHRINK_TABLE_SIZE {
		shrink_put(&w, 'a')
	}
	for _ in 0..<200_000 {
		shrink_put(&w, 'b')
		shrink_put(&w, SHRINK_CLEAR)
	}
	data := shrink_finish(&w)

	output: [dynamic]u8
	defer delete(output)
	start   := time.tick_now()
	size    := pkzip_legacy.SHRINK_TABLE_SIZE - pkzip_legacy.SHRINK_FIRST_FREE_CODE + 1 + 200_000
	err     := pkzip_legacy.unshrink(&output, data, size)
	elapsed := time.tick_since(start)
	testing.expect_value(t, err, nil)
	log.infof("clear flood: %v bytes in, %v bytes out, %v", len(data), len(output), elapsed)
	testing.expectf(t, elapsed < 2 * time.Second, "clear flood took %v", elapsed)
}

shrink_writer_init :: proc(w: ^Shrink_Writer) {
	w.code_size = pkzip_legacy.SHRINK_MIN_CODE_SIZE
}

shrink_put :: proc(w: ^Shrink_Writer, code: int) {
	switch code {
	case SHRINK_INCREASE:
		shrink_put_bits(w, pkzip_legacy.SHRINK_CONTROL_CODE)
		shrink_put_bits(w, pkzip_legacy.SHRINK_INCREASE_CODE_SIZE)
		w.code_size += 1
	case SHRINK_CLEAR:
		shrink_put_bits(w, pkzip_legacy.SHRINK_CONTROL_CODE)
		shrink_put_bits(w, pkzip_legacy.SHRINK_PARTIAL_CLEAR)
	case:
		shrink_put_bits(w, code)
	}
}

shrink_put_bits :: proc(w: ^Shrink_Writer, code: int) {
	w.bits  |= u64(code) << w.count
	w.count += w.code_size
	for w.count >= 8 {
		append(&w.buffer, u8(w.bits))
		w.bits  >>= 8
		w.count  -= 8
	}
}

shrink_finish :: proc(w: ^Shrink_Writer) -> []u8 {
	if w.count > 0 {
		append(&w.buffer, u8(w.bits))
		w.bits, w.count = 0, 0
	}
	return w.buffer[:]
}

shrink_bomb :: proc(w: ^Shrink_Writer, codes: int) {
	shrink_writer_init(w)
	shrink_put(w, 'a')
	next := pkzip_legacy.SHRINK_FIRST_FREE_CODE
	for _ in 0..<codes {
		if next >= pkzip_legacy.SHRINK_TABLE_SIZE {
			shrink_put(w, pkzip_legacy.SHRINK_TABLE_SIZE - 1)
			continue
		}
		if next == 1 << w.code_size {
			shrink_put(w, SHRINK_INCREASE)
		}
		shrink_put(w, next)
		next += 1
	}
}

shrink_bomb_size :: proc(codes: int) -> int {
	size := 1
	next := pkzip_legacy.SHRINK_FIRST_FREE_CODE
	for _ in 0..<codes {
		if next >= pkzip_legacy.SHRINK_TABLE_SIZE {
			size += pkzip_legacy.SHRINK_TABLE_SIZE - 1 - 255
			continue
		}
		size += next - 255
		next += 1
	}
	return size
}

legacy_members :: proc(file: []u8, allocator := context.temp_allocator) -> (members: [dynamic]Legacy_Member, ok: bool) {
	members = make([dynamic]Legacy_Member, allocator)
	end := -1
	for i := len(file) - 22; i >= 0; i -= 1 {
		if endian.unchecked_get_u32le(file[i:]) == 0x06054b50 {
			end = i
			break
		}
	}
	if end < 0 {
		return
	}
	count := int(endian.unchecked_get_u16le(file[end + 10:]))
	p     := int(endian.unchecked_get_u32le(file[end + 16:]))
	for _ in 0..<count {
		if p + 46 > len(file) || endian.unchecked_get_u32le(file[p:]) != 0x02014b50 {
			return
		}
		flags    := endian.unchecked_get_u16le(file[p + 8:])
		method   := endian.unchecked_get_u16le(file[p + 10:])
		crc      := endian.unchecked_get_u32le(file[p + 16:])
		packed   := int(endian.unchecked_get_u32le(file[p + 20:]))
		unpacked := int(endian.unchecked_get_u32le(file[p + 24:]))
		name_len := int(endian.unchecked_get_u16le(file[p + 28:]))
		extra    := int(endian.unchecked_get_u16le(file[p + 30:]))
		comment  := int(endian.unchecked_get_u16le(file[p + 32:]))
		local    := int(endian.unchecked_get_u32le(file[p + 42:]))
		if p + 46 + name_len > len(file) {
			return
		}
		name := string(file[p + 46:][:name_len])
		p += 46 + name_len + extra + comment

		if local + 30 > len(file) {
			return
		}
		start := local + 30 + int(endian.unchecked_get_u16le(file[local + 26:])) + int(endian.unchecked_get_u16le(file[local + 28:]))
		if start + packed > len(file) {
			return
		}
		append(&members, Legacy_Member{name, Legacy_Method_Id(method), flags, file[start:][:packed], unpacked, crc})
	}
	return members, true
}
