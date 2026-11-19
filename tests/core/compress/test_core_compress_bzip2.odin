#+build !riscv64
#+build !freebsd
#+build !netbsd
#+build !openbsd
package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/bzip2"
import "core:hash"
import "core:math/rand"
import "core:strings"
import "core:testing"
import "core:time"

BZ_Reference :: struct {
	name:   string,
	size:   int,
	level:  bzip2.Level,
	packed: int,
	crc:    u32,
}

@(rodata)
BZ_REFERENCES := []BZ_Reference{
	{"hello",     600,       .Level_9, 65,     0x9d12fcec},
	{"empty",     0,         .Level_9, 14,     0x039e0d3a},
	{"lcg20k_1",  20_000,    .Level_1, 7856,   0x529653f9},
	{"lcg20k_9",  20_000,    .Level_9, 7856,   0xd9722b1e},
	{"lcg250k_1", 250_000,   .Level_1, 149569, 0x8b46b29b},
	{"zeros1m_9", 1_000_000, .Level_9, 48,     0xa7f9d496},
}

bz_reference_input :: proc(name: string) -> []u8 {
	switch name {
	case "hello":     return transmute([]u8)strings.repeat("hello bzip2 ", 50)
	case "empty":     return make([]u8, 0)
	case "lcg20k_1":  return bz_lcg(20_000, 8)
	case "lcg20k_9":  return bz_lcg(20_000, 8)
	case "lcg250k_1": return bz_lcg(250_000, 26)
	case "zeros1m_9": return make([]u8, 1_000_000)
	}
	return nil
}

@(test)
bzip2_matches_reference :: proc(t: ^testing.T) {
	for r in BZ_REFERENCES {
		input := bz_reference_input(r.name)
		defer delete(input)
		testing.expect_value(t, len(input), r.size)

		packed: [dynamic]u8
		defer delete(packed)
		err := bzip2.compress(&packed, input, r.level)
		testing.expectf(t, err == nil, "%v: compress %v", r.name, err)
		testing.expectf(t, len(packed) == r.packed && hash.crc32(packed[:]) == r.crc, "%v: %v bytes, crc %x, want %v bytes, crc %x", r.name, len(packed), hash.crc32(packed[:]), r.packed, r.crc)

		output: [dynamic]u8
		defer delete(output)
		err = bzip2.decompress(&output, packed[:])
		testing.expectf(t, err == nil, "%v: decompress %v", r.name, err)
		testing.expectf(t, bytes.equal(output[:], input), "%v: round trip differs", r.name)
	}

	output: [dynamic]u8
	defer delete(output)
	testing.expect_value(t, bzip2.decompress(&output, transmute([]u8)string(BZ_HELLO_PACKED)), nil)
	testing.expect_value(t, string(output[:]), strings.repeat("hello bzip2 ", 50, context.temp_allocator))
}

@(test)
bzip2_round_trip :: proc(t: ^testing.T) {
	inputs: [dynamic][]u8
	defer {
		for input in inputs {
			delete(input)
		}
		delete(inputs)
	}
	for n in ([]int{1, 2, 3, 4, 5, 6, 254, 255, 256, 257, 258, 259, 260, 1000, 70_000}) {
		run := make([]u8, n)
		for &b in run {
			b = 'x'
		}
		append(&inputs, run)
	}
	{
		mixed: [dynamic]u8
		for i in 0..<5000 {
			for _ in 0..<i % 300 {
				append(&mixed, u8(i))
			}
		}
		append(&inputs, mixed[:])
	}
	{
		noise := make([]u8, 150_000)
		r := rand.create(42)
		for &b in noise {
			b = u8(rand.uint32(rand.default_random_generator(&r)))
		}
		append(&inputs, noise)
	}

	for input, i in inputs {
		for level in ([]bzip2.Level{.Level_1, .Level_9}) {
			packed: [dynamic]u8
			defer delete(packed)
			testing.expectf(t, bzip2.compress(&packed, input, level) == nil, "input %v level %v: compress failed", i, level)
			testing.expectf(t, len(packed) <= bzip2.compress_bound(len(input)), "input %v level %v: %v bytes over bound", i, level, len(packed))

			output: [dynamic]u8
			defer delete(output)
			err := bzip2.decompress(&output, packed[:])
			testing.expectf(t, err == nil, "input %v level %v: decompress %v", i, level, err)
			testing.expectf(t, bytes.equal(output[:], input), "input %v level %v: round trip differs", i, level)
		}
	}
}

@(test)
bzip2_compress_arguments :: proc(t: ^testing.T) {
	input := bz_lcg(1000, 4)
	defer delete(input)

	state := new(bzip2.BZip2)
	defer free(state)

	small := make([]u8, 16)
	defer delete(small)
	_, err := bzip2.compress(state, small, input)
	testing.expect_value(t, err, compress.General_Error.Output_Too_Short)

	big := make([]u8, bzip2.compress_bound(len(input)))
	defer delete(big)
	_, err = bzip2.compress(nil, big, input)
	testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
	_, err = bzip2.compress(state, big, input, bzip2.Level(0))
	testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
	_, err = bzip2.compress(state, big, input, bzip2.Level(10))
	testing.expect_value(t, err, compress.General_Error.Incompatible_Options)

	dynamic_output: [dynamic]u8
	defer delete(dynamic_output)
	testing.expect_value(t, bzip2.compress(&dynamic_output, input), nil)
	for level in bzip2.Level.Level_1..=bzip2.Level.Level_9 {
		written: int
		written, err = bzip2.compress(state, big, input, level)
		testing.expect_value(t, err, nil)
		if level == .Default {
			testing.expect(t, string(big[:written]) == string(dynamic_output[:]))
		}
		decoded: [dynamic]u8
		testing.expect_value(t, bzip2.decompress(&decoded, big[:written]), nil)
		testing.expect(t, string(decoded[:]) == string(input))
		delete(decoded)
	}

	testing.expect_value(t, bzip2.compress_bound(-1), -1)
	testing.expect_value(t, bzip2.compress_bound(max(int)), -1)
	testing.expect_value(t, bzip2.compress_bound(0), 600)
}

@(test)
bzip2_interleave :: proc(t: ^testing.T) {
	input: [dynamic]u8
	defer delete(input)
	noise := bz_lcg(500_000, 7)
	defer delete(noise)
	for i in 0..<len(noise) {
		c := noise[i]
		append(&input, c)
		if c < 16 {
			for _ in 0..<int(c) * 17 {
				append(&input, c)
			}
		}
	}

	packed: [dynamic]u8
	defer delete(packed)
	testing.expect_value(t, bzip2.compress(&packed, input[:], .Level_1), nil)

	for blocks in 1..=bzip2.BZIP2_INTERLEAVE + 1 {
		part: [dynamic]u8
		testing.expect_value(t, bzip2.compress(&part, noise[:blocks * 99_000], .Level_1), nil)
		output: [dynamic]u8
		err := bzip2.decompress(&output, part[:], blocks * 99_000)
		testing.expectf(t, err == nil, "%v blocks: %v", blocks, err)
		testing.expectf(t, bytes.equal(output[:], noise[:blocks * 99_000]), "%v blocks: output differs", blocks)
		delete(output)
		delete(part)
	}

	output: [dynamic]u8
	defer delete(output)
	testing.expect_value(t, bzip2.decompress(&output, packed[:], len(input)), nil)
	testing.expect(t, bytes.equal(output[:], input[:]))
}

@(test)
bzip2_concatenated_streams :: proc(t: ^testing.T) {
	a := bz_lcg(30_000, 5)
	b := transmute([]u8)strings.repeat("concatenated ", 1000)
	defer delete(a)
	defer delete(b)

	packed: [dynamic]u8
	defer delete(packed)
	part: [dynamic]u8
	defer delete(part)
	testing.expect_value(t, bzip2.compress(&part, a, .Level_1), nil)
	append(&packed, ..part[:])
	testing.expect_value(t, bzip2.compress(&part, b, .Level_5), nil)
	append(&packed, ..part[:])
	append(&packed, "trailing")

	for kind in Stream_Kind {
		input := packed[:]
		output: [dynamic]u8
		defer delete(output)
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		err := bzip2.decompress(&ctx)
		rest, rest_err := compress.read_remaining(&ctx)
		testing.expectf(t, rest_err == nil && string(rest[:]) == "trailing", "%v: remaining %q, %v", kind, string(rest[:]), rest_err)
		delete(rest)
		compress.destroy_context(&ctx)
		testing.expectf(t, err == nil, "%v: %v", kind, err)
		testing.expectf(t, len(output) == len(a) + len(b) && bytes.equal(output[:len(a)], a) && bytes.equal(output[len(a):], b), "%v: output differs", kind)
	}
}

@(test)
bzip2_randomised_block :: proc(t: ^testing.T) {
	data := make([]u8, 5000)
	defer delete(data)
	x := u32(7)
	for &b, i in data {
		x = x * 1103515245 + 12345
		b = u8(x >> 16) & 0xfe
		if i >= 3 && data[i - 1] == b && data[i - 2] == b && data[i - 3] == b {
			b += 2
		}
	}

	masked := make([]u8, len(data))
	defer delete(masked)
	to_go, pos := 0, 0
	for b, i in data {
		if to_go == 0 {
			to_go = int(BZ_RAND_TABLE[pos])
			pos   = (pos + 1) & 511
		}
		to_go -= 1
		masked[i] = b ~ 1 if to_go == 1 else b
	}
	testing.expect(t, !bytes.equal(masked, data))

	packed: [dynamic]u8
	defer delete(packed)
	testing.expect_value(t, bzip2.compress(&packed, masked, .Level_1), nil)

	crc := bz_crc(data)
	bz_set_bits(packed[:], 80, 32, crc)
	bz_set_bits(packed[:], 112, 1, 1)
	end := bz_find_end(packed[:])
	testing.expect(t, end > 0)
	bz_set_bits(packed[:], end + 48, 32, crc)

	output: [dynamic]u8
	defer delete(output)
	err := bzip2.decompress(&output, packed[:])
	testing.expectf(t, err == nil, "%v", err)
	testing.expect(t, bytes.equal(output[:], data))
}

@(test)
bzip2_exact_size :: proc(t: ^testing.T) {
	data := bz_lcg(300_000, 3)
	defer delete(data)
	packed: [dynamic]u8
	defer delete(packed)
	testing.expect_value(t, bzip2.compress(&packed, data, .Level_1), nil)

	for kind in Stream_Kind {
		for expected in ([]int{len(data), 100}) {
			input := packed[:]
			output: [dynamic]u8
			defer delete(output)
			br: bytes.Reader
			tr: Trickle_Reader
			ctx := stream_test_context(kind, &input, &br, &tr, &output)
			err := bzip2.decompress(&ctx, expected)
			compress.destroy_context(&ctx)

			if expected == len(data) {
				testing.expectf(t, err == nil, "%v: %v", kind, err)
				testing.expectf(t, bytes.equal(output[:], data), "%v: output differs", kind)
				testing.expectf(t, cap(output) == len(data), "%v: capacity %v for an exact size", kind, cap(output))
			} else {
				testing.expectf(t, err == compress.General_Error.Size_Mismatch, "%v: %v", kind, err)
				testing.expectf(t, cap(output) <= expected, "%v: capacity %v for a declared %v", kind, cap(output), expected)
			}
		}
	}
}

@(test)
bzip2_max_output_size :: proc(t: ^testing.T) {
	data := bz_lcg(300_000, 3)
	defer delete(data)
	packed: [dynamic]u8
	defer delete(packed)
	testing.expect_value(t, bzip2.compress(&packed, data, .Level_1), nil)

	Case :: struct {
		expected, limit: int,
		want:            compress.Error,
	}
	cases := []Case{
		{-1,        len(data),     nil},
		{-1,        len(data) / 2, compress.General_Error.Output_Too_Short},
		{len(data), len(data) - 1, compress.General_Error.Output_Too_Short},
		{-1,        -1,            compress.General_Error.Incompatible_Options},
	}
	for c in cases {
		output: [dynamic]u8
		defer delete(output)
		err := bzip2.decompress(&output, packed[:], c.expected, {max_output_size = c.limit})
		testing.expectf(t, err == c.want, "%v: %v, want %v", c, err, c.want)
		testing.expectf(t, cap(output) <= max(c.limit, 0), "%v: capacity %v", c, cap(output))
	}
}

@(test)
bzip2_bomb_growth :: proc(t: ^testing.T) {
	k := 180_000
	stream := bz_bomb(k)
	defer delete(stream)
	want := k * 259

	output: [dynamic]u8
	defer delete(output)
	err := bzip2.decompress(&output, stream[:])
	testing.expectf(t, err == nil, "%v", err)
	testing.expect_value(t, len(output), want)
	testing.expectf(t, cap(output) - len(output) <= 16 << 20, "capacity %v for %v bytes", cap(output), len(output))

	bound := (len(stream) - 14) * (900_000 / 5 * 259 / 20)
	for expected in ([]int{want, max(int)}) {
		claimed: [dynamic]u8
		defer delete(claimed)
		err = bzip2.decompress(&claimed, stream[:], expected, {max_output_size = max(int)})
		want_err: compress.Error = nil if expected == want else compress.General_Error.Size_Mismatch
		testing.expectf(t, err == want_err, "expected %v: %v", expected, err)
		testing.expectf(t, cap(claimed) <= max(want, min(expected, bound)), "expected %v: capacity %v, bound %v", expected, cap(claimed), bound)
	}

	empty: [dynamic]u8
	defer delete(empty)
	testing.expect_value(t, bzip2.decompress(&empty, transmute([]u8)string("BZh9\x17\x72\x45\x38\x50\x90\x00\x00\x00\x00"), 1 << 30, {max_output_size = max(int)}), compress.General_Error.Size_Mismatch)
	testing.expect_value(t, len(empty), 0)
	testing.expect_value(t, cap(empty), 0)
}

@(test)
bzip2_truncated :: proc(t: ^testing.T) {
	data := bz_lcg(150_000, 20)
	defer delete(data)
	packed: [dynamic]u8
	defer delete(packed)
	testing.expect_value(t, bzip2.compress(&packed, data, .Level_1), nil)

	for cut := 0; cut < len(packed); cut += 1 if cut < 64 || cut > len(packed) - 64 else 997 {
		output: [dynamic]u8
		defer delete(output)
		err := bzip2.decompress(&output, packed[:cut])
		testing.expectf(t, err != nil, "cut %v of %v decoded", cut, len(packed))
	}
}

@(test)
bzip2_bit_flips :: proc(t: ^testing.T) {
	data := bz_lcg(20_000, 6)
	defer delete(data)
	packed: [dynamic]u8
	defer delete(packed)
	testing.expect_value(t, bzip2.compress(&packed, data, .Level_1), nil)

	r := rand.create(1234)
	gen := rand.default_random_generator(&r)
	corrupt := make([]u8, len(packed))
	defer delete(corrupt)
	for _ in 0..<500 {
		copy(corrupt, packed[:])
		for _ in 0..<1 + rand.int_max(3, gen) {
			bit := rand.int_max(len(corrupt) * 8, gen)
			corrupt[bit >> 3] ~= 0x80 >> uint(bit & 7)
		}
		output: [dynamic]u8
		defer delete(output)
		err := bzip2.decompress(&output, corrupt, -1, {max_output_size = 1 << 20})
		testing.expectf(t, cap(output) <= 1 << 20, "capacity %v", cap(output))
		if err == nil {
			testing.expect(t, bytes.equal(output[:], data))
		}
	}
}

@(test)
bzip2_format_errors :: proc(t: ^testing.T) {
	Case :: struct {
		name:  string,
		block: BZ_Block,
		want:  compress.Error,
	}
	valid := BZ_Block{
		in_use   = {'a'},
		n_groups = 2,
		lengths  = {1, 2, 2},
		symbols  = {0, 2},
	}

	cases: [dynamic]Case
	defer delete(cases)
	append(&cases, Case{"valid", valid, nil})
	{
		b := valid
		b.n_groups = 1
		append(&cases, Case{"one group", b, compress.BZip2_Error.Invalid_Group_Count})
		b.n_groups = 7
		append(&cases, Case{"seven groups", b, compress.BZip2_Error.Invalid_Group_Count})
	}
	{
		b := valid
		b.n_selectors = -1
		append(&cases, Case{"no selectors", b, compress.BZip2_Error.Invalid_Selector_Count})
	}
	{
		b := valid
		b.selector_mtf = {2}
		append(&cases, Case{"selector past groups", b, compress.BZip2_Error.Invalid_Selector})
	}
	{
		b := valid
		b.in_use = {}
		append(&cases, Case{"no symbols", b, compress.BZip2_Error.No_Symbols_In_Use})
	}
	{
		b := valid
		b.lengths = {1, 1, 1}
		append(&cases, Case{"oversubscribed", b, compress.BZip2_Error.Invalid_Huffman_Code})
	}
	{
		b := valid
		b.lengths = {2, 2, 2}
		b.symbols = {0, 3}
		append(&cases, Case{"unused code", b, compress.BZip2_Error.Invalid_Huffman_Code})
	}
	{
		b := valid
		b.lengths = {21, 21, 21}
		append(&cases, Case{"length 21", b, compress.BZip2_Error.Invalid_Code_Length})
		b.lengths = {0, 1, 1}
		append(&cases, Case{"length 0", b, compress.BZip2_Error.Invalid_Code_Length})
	}
	{
		b := valid
		b.orig_ptr = 1
		append(&cases, Case{"orig_ptr past block", b, compress.BZip2_Error.Invalid_Original_Pointer})
	}
	{
		b := valid
		b.symbols = make([]u16, 23)
		b.symbols[22] = 2
		append(&cases, Case{"run too long", b, compress.BZip2_Error.Run_Too_Long})
	}
	{
		b := valid
		b.symbols = make([]u16, 18)
		for &s in b.symbols {
			s = 1
		}
		b.symbols[17] = 2
		append(&cases, Case{"run past block", b, compress.BZip2_Error.Block_Too_Large})
	}
	{
		b := valid
		b.in_use  = {'a', 'b'}
		b.lengths = {2, 2, 2, 2}
		b.symbols = make([]u16, 100_002)
		for &s in b.symbols {
			s = 2
		}
		b.symbols[100_001] = 3
		append(&cases, Case{"symbols past block", b, compress.BZip2_Error.Block_Too_Large})
	}
	{
		b := valid
		b.n_selectors = 1
		b.in_use  = {'a', 'b'}
		b.lengths = {2, 2, 2, 2}
		b.symbols = make([]u16, 52)
		for &s in b.symbols {
			s = 2
		}
		b.symbols[51] = 3
		append(&cases, Case{"selectors exhausted", b, compress.BZip2_Error.Selectors_Exhausted})
	}
	{
		b := valid
		b.crc = 1
		append(&cases, Case{"block crc", b, compress.BZip2_Error.Block_Checksum_Failed})
	}
	{
		b := valid
		b.magic = 0x314159265358
		append(&cases, Case{"block magic", b, compress.BZip2_Error.Invalid_Block_Magic})
	}
	{
		b := valid
		b.bad_combined = true
		append(&cases, Case{"stream crc", b, compress.BZip2_Error.Stream_Checksum_Failed})
	}

	for c in cases {
		stream := bz_stream('1', {c.block})
		defer delete(stream)
		output: [dynamic]u8
		defer delete(output)
		err := bzip2.decompress(&output, stream[:])
		testing.expectf(t, err == c.want, "%v: %v, want %v", c.name, err, c.want)
		if c.want == nil {
			testing.expect_value(t, string(output[:]), "a")
		}
	}
	for c in cases {
		if len(c.block.symbols) > 2 {
			delete(c.block.symbols)
		}
	}

	headers := []struct{ data: string, want: compress.Error }{
		{"",                 compress.General_Error.Stream_Too_Short},
		{"BZh",              compress.General_Error.Stream_Too_Short},
		{"BZh0",             compress.BZip2_Error.Invalid_Magic},
		{"BZx9",             compress.BZip2_Error.Invalid_Magic},
		{"BZh9",             compress.General_Error.Stream_Too_Short},
		{"BZh9\x17\x72\x45", compress.General_Error.Stream_Too_Short},
	}
	for h in headers {
		output: [dynamic]u8
		defer delete(output)
		err := bzip2.decompress(&output, transmute([]u8)h.data)
		testing.expectf(t, err == h.want, "%q: %v, want %v", h.data, err, h.want)
	}
}

@(test)
bzip2_tiny_block_flood :: proc(t: ^testing.T) {
	block := BZ_Block{
		in_use   = {'a'},
		n_groups = 6,
		lengths  = {1, 2, 2},
		symbols  = {0, 2},
	}
	blocks := make([]BZ_Block, 20_000)
	defer delete(blocks)
	for &b in blocks {
		b = block
	}
	stream := bz_stream('1', blocks)
	defer delete(stream)

	output: [dynamic]u8
	defer delete(output)
	start := time.tick_now()
	err := bzip2.decompress(&output, stream[:])
	elapsed := time.tick_since(start)
	testing.expectf(t, err == nil, "%v", err)
	testing.expect_value(t, len(output), len(blocks))
	testing.expectf(t, elapsed < 2 * time.Second, "%v tiny blocks (%v bytes) took %v", len(blocks), len(stream), elapsed)
}
