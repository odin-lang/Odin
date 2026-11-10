package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/deflate"
import "core:hash"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:testing"

D64_Format :: enum {
	Deflate,
	Deflate64,
}

D64_TEST_LEVELS :: [?]deflate.Deflate_Level{.Stored, .Level_1, .Level_2, .Level_5, .Level_6, .Level_9, .Level_10}

D64_FUZZ_CRAFTED :: #config(D64_FUZZ_CRAFTED, 2000)
D64_FUZZ_PACKED  :: #config(D64_FUZZ_PACKED, 30)

@(rodata)
D64_LENGTH_BASE := [29]int{3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258}

@(rodata)
D64_LENGTH_EXTRA := [29]uint{0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0}

@(rodata)
D64_DISTANCE_BASE := [32]int{1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577, 32769, 49153}

@(rodata)
D64_DISTANCE_EXTRA := [32]uint{0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14}

@(rodata)
D64_PRECODE_ORDER := [19]int{16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15}

D64_Bits :: struct {
	buf: [dynamic]byte,
	acc: u64,
	n:   uint,
}

D64_Code :: struct {
	lit_len:   [288]u8,
	lit_code:  [288]u32,
	dist_len:  [32]u8,
	dist_code: [32]u32,
}

d64_put :: proc(b: ^D64_Bits, v: u64, n: uint) {
	if n == 0 {
		return
	}
	b.acc |= (v & ((u64(1) << n) - 1)) << b.n
	b.n += n
	for b.n >= 8 {
		append(&b.buf, u8(b.acc))
		b.acc >>= 8
		b.n -= 8
	}
}

d64_put_code :: proc(b: ^D64_Bits, code: u32, length: u8) {
	reversed: u64
	for i in 0..<uint(length) {
		reversed = reversed << 1 | u64((code >> i) & 1)
	}
	d64_put(b, reversed, uint(length))
}

d64_align :: proc(b: ^D64_Bits) {
	if b.n > 0 {
		d64_put(b, 0, 8 - b.n)
	}
}

d64_canonical :: proc(lengths: []u8, codes: []u32) {
	count: [16]u32
	for l in lengths {
		count[l] += 1
	}
	count[0] = 0
	next_code: [16]u32
	code: u32
	for bits in 1..<16 {
		code = (code + count[bits - 1]) << 1
		next_code[bits] = code
	}
	for l, i in lengths {
		if l != 0 {
			codes[i] = next_code[l]
			next_code[l] += 1
		}
	}
}

d64_fixed_code :: proc(c: ^D64_Code) {
	for i in 0..<288 {
		switch {
		case i < 144: c.lit_len[i] = 8
		case i < 256: c.lit_len[i] = 9
		case i < 280: c.lit_len[i] = 7
		case:         c.lit_len[i] = 8
		}
	}
	for i in 0..<32 {
		c.dist_len[i] = 5
	}
	d64_canonical(c.lit_len[:], c.lit_code[:])
	d64_canonical(c.dist_len[:], c.dist_code[:])
}

d64_put_literal :: proc(b: ^D64_Bits, c: ^D64_Code, symbol: int) {
	d64_put_code(b, c.lit_code[symbol], c.lit_len[symbol])
}

d64_put_match :: proc(b: ^D64_Bits, c: ^D64_Code, length_symbol: int, length_extra: u64, distance_symbol: int, distance_extra: u64, format: D64_Format) {
	d64_put_code(b, c.lit_code[length_symbol], c.lit_len[length_symbol])
	if format == .Deflate64 && length_symbol == 285 {
		d64_put(b, length_extra, 16)
	} else {
		d64_put(b, length_extra, D64_LENGTH_EXTRA[length_symbol - 257])
	}
	d64_put_code(b, c.dist_code[distance_symbol], c.dist_len[distance_symbol])
	d64_put(b, distance_extra, D64_DISTANCE_EXTRA[distance_symbol])
}

d64_put_stored :: proc(b: ^D64_Bits, final: bool, data: []byte) {
	d64_put(b, 1 if final else 0, 1)
	d64_put(b, 0, 2)
	d64_align(b)
	d64_put(b, u64(len(data)), 16)
	d64_put(b, u64(~u16(len(data))), 16)
	for c in data {
		d64_put(b, u64(c), 8)
	}
}

D64_Ref_Reader :: struct {
	data: []byte,
	bit:  int,
}

D64_Ref_Huffman :: struct {
	count:  [16]int,
	symbol: [320]int,
	codes:  int,
	left:   int,
}

d64_ref_bits :: proc(r: ^D64_Ref_Reader, n: int) -> (v: int, ok: bool) {
	if r.bit + n > len(r.data) * 8 {
		return 0, false
	}
	for i in 0..<n {
		v |= int((r.data[(r.bit + i) >> 3] >> uint((r.bit + i) & 7)) & 1) << uint(i)
	}
	r.bit += n
	return v, true
}

d64_ref_build :: proc(h: ^D64_Ref_Huffman, lengths: []u8) {
	h.count = {}
	for l in lengths {
		h.count[l] += 1
	}
	h.codes = len(lengths) - h.count[0]
	h.left  = 1
	for length in 1..=15 {
		h.left <<= 1
		h.left -= h.count[length]
		if h.left < 0 {
			return
		}
	}
	offsets: [16]int
	for length in 1..<15 {
		offsets[length + 1] = offsets[length] + h.count[length]
	}
	for l, symbol in lengths {
		if l != 0 {
			h.symbol[offsets[l]] = symbol
			offsets[l] += 1
		}
	}
}

d64_ref_usable :: proc(h: ^D64_Ref_Huffman, allow_empty: bool) -> bool {
	switch {
	case h.left < 0:   return false
	case h.left == 0:  return true
	case h.codes == 0: return allow_empty
	}
	return h.codes == 1 && h.count[1] == 1
}

d64_ref_decode :: proc(r: ^D64_Ref_Reader, h: ^D64_Ref_Huffman) -> (symbol: int, ok: bool) {
	code, first, index: int
	for length in 1..=15 {
		bit := d64_ref_bits(r, 1) or_return
		code |= bit
		count := h.count[length]
		if code - count < first {
			return h.symbol[index + (code - first)], true
		}
		index += count
		first += count
		first <<= 1
		code  <<= 1
	}
	return -1, false
}

d64_ref_inflate :: proc(data: []byte, format: D64_Format, out: ^[dynamic]byte, strict := false) -> (ok: bool) {
	r := D64_Ref_Reader{data = data}
	distance_symbols := 32 if format == .Deflate64 else 30
	for {
		last  := d64_ref_bits(&r, 1) or_return
		btype := d64_ref_bits(&r, 2) or_return
		lit, dist: D64_Ref_Huffman
		switch btype {
		case 0:
			r.bit = (r.bit + 7) &~ 7
			length  := d64_ref_bits(&r, 16) or_return
			nlength := d64_ref_bits(&r, 16) or_return
			if length != ~nlength & 0xffff || r.bit / 8 + length > len(data) {
				return false
			}
			append(out, ..data[r.bit / 8:][:length])
			r.bit += 8 * length
			if last != 0 {
				return true
			}
			continue
		case 1:
			c: D64_Code
			d64_fixed_code(&c)
			d64_ref_build(&lit, c.lit_len[:])
			d64_ref_build(&dist, c.dist_len[:])
		case 2:
			hlit  := 257 + (d64_ref_bits(&r, 5) or_return)
			hdist := 1 + (d64_ref_bits(&r, 5) or_return)
			hclen := 4 + (d64_ref_bits(&r, 4) or_return)
			if hlit > 286 || hdist > distance_symbols {
				return false
			}
			precode_lengths: [19]u8
			for i in 0..<hclen {
				precode_lengths[D64_PRECODE_ORDER[i]] = u8(d64_ref_bits(&r, 3) or_return)
			}
			precode: D64_Ref_Huffman
			d64_ref_build(&precode, precode_lengths[:])
			if precode.left != 0 {
				return false
			}
			lengths: [320]u8
			total := hlit + hdist
			for n := 0; n < total; {
				symbol := d64_ref_decode(&r, &precode) or_return
				value: u8
				repeat: int
				switch symbol {
				case 16:
					if n == 0 {
						return false
					}
					value  = lengths[n - 1]
					repeat = 3 + (d64_ref_bits(&r, 2) or_return)
				case 17:
					repeat = 3 + (d64_ref_bits(&r, 3) or_return)
				case 18:
					repeat = 11 + (d64_ref_bits(&r, 7) or_return)
				case:
					lengths[n] = u8(symbol)
					n += 1
					continue
				}
				if n + repeat > total {
					return false
				}
				for _ in 0..<repeat {
					lengths[n] = value
					n += 1
				}
			}
			if lengths[256] == 0 {
				return false
			}
			d64_ref_build(&lit, lengths[:hlit])
			d64_ref_build(&dist, lengths[hlit:][:hdist])
			if !d64_ref_usable(&lit, false) || !d64_ref_usable(&dist, !strict) {
				return false
			}
		case:
			return false
		}
		for {
			symbol := d64_ref_decode(&r, &lit) or_return
			if symbol < 256 {
				append(out, u8(symbol))
				continue
			}
			if symbol == 256 {
				break
			}
			if symbol >= 286 {
				return false
			}
			length: int
			if format == .Deflate64 && symbol == 285 {
				length = 3 + (d64_ref_bits(&r, 16) or_return)
			} else {
				length = D64_LENGTH_BASE[symbol - 257] + (d64_ref_bits(&r, int(D64_LENGTH_EXTRA[symbol - 257])) or_return)
			}
			distance_symbol := d64_ref_decode(&r, &dist) or_return
			if distance_symbol >= distance_symbols {
				return false
			}
			distance := D64_DISTANCE_BASE[distance_symbol] + (d64_ref_bits(&r, int(D64_DISTANCE_EXTRA[distance_symbol])) or_return)
			if distance > len(out) {
				return false
			}
			for _ in 0..<length {
				append(out, out[len(out) - distance])
			}
		}
		if last != 0 {
			return true
		}
	}
}

d64_unpack :: proc(format: D64_Format, kind: Stream_Kind, input: []byte, output: ^[dynamic]byte, expected := -1, limit := compress.COMPRESS_OUTPUT_ALLOCATE_MAX) -> compress.Error {
	input := input
	br: bytes.Reader
	tr: Trickle_Reader
	ctx := stream_test_context(kind, &input, &br, &tr, output)
	defer compress.destroy_context(&ctx)
	switch format {
	case .Deflate:   return deflate.inflate_raw(&ctx, expected, limit)
	case .Deflate64: return deflate.inflate64_raw(&ctx, expected, limit)
	}
	return nil
}

d64_test_data :: proc(kind: int, size: int, data: ^[dynamic]byte) {
	switch kind {
	case 0:
		for _ in 0..<size {
			append(data, u8(rand.uint32()))
		}
	case 1:
		resize(data, size)
	case 2:
		period := 1 + rand.int_max(70000)
		for i in 0..<size {
			if i < period {
				append(data, u8(rand.uint32()))
			} else {
				append(data, data[i - period])
			}
		}
	case:
		for len(data) < size {
			switch rand.int_max(4) {
			case 0:
				for _ in 0..<rand.int_max(2000) {
					append(data, 'a' + u8(rand.int_max(6)))
				}
			case 1:
				for _ in 0..<rand.int_max(80000) {
					append(data, 0)
				}
			case:
				if len(data) > 0 {
					distance := 1 + rand.int_max(min(len(data), 65536))
					for _ in 0..<rand.int_max(70000) {
						append(data, data[len(data) - distance])
					}
				}
			}
		}
		resize(data, size)
	}
}

d64_round_trip :: proc(t: ^testing.T, name: string, data: []byte) {
	for level in D64_TEST_LEVELS {
		packed: [dynamic]byte
		defer delete(packed)
		err := deflate.deflate64_raw(&packed, data, level)
		testing.expectf(t, err == nil, "%v, %v: deflate64 returned %v", name, level, err)
		if err != nil {
			continue
		}
		testing.expectf(t, len(packed) <= deflate.deflate64_bound(len(data)), "%v, %v: %v bytes over the bound", name, level, len(packed))
		for kind in Stream_Kind {
			output: [dynamic]byte
			defer delete(output)
			unpack_err := d64_unpack(.Deflate64, kind, packed[:], &output)
			testing.expectf(t, unpack_err == nil, "%v, %v, %v: inflate64 returned %v", name, level, kind, unpack_err)
			testing.expectf(t, bytes.equal(output[:], data), "%v, %v, %v: output differs", name, level, kind)
		}
		reference: [dynamic]byte
		defer delete(reference)
		ok := d64_ref_inflate(packed[:], .Deflate64, &reference, strict = true)
		testing.expectf(t, ok && bytes.equal(reference[:], data), "%v, %v: reference decoder disagrees", name, level)
	}
}

@(test)
deflate64_round_trip :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	shapes := [?]string{"random", "zeros", "periodic", "mixed"}
	sizes  := [?]int{0, 1, 10, 100, 70000, 300000}
	for shape, kind in shapes {
		for size in sizes {
			data: [dynamic]byte
			defer delete(data)
			d64_test_data(kind, size, &data)
			d64_round_trip(t, shape, data[:])
		}
	}
}

@(test)
deflate64_far_distances :: proc(t: ^testing.T) {
	for period in ([]int{32768, 32769, 40000, 49152, 49153, 65535, 65536}) {
		data := make([]byte, 3 * period)
		defer delete(data)
		for i in 0..<period {
			data[i] = u8(rand.uint32())
		}
		for i in period..<len(data) {
			data[i] = data[i - period]
		}
		for level in ([]deflate.Deflate_Level{.Level_1, .Level_6, .Level_10}) {
			packed: [dynamic]byte
			defer delete(packed)
			testing.expect_value(t, deflate.deflate64_raw(&packed, data, level), nil)
			slack := period / 2 if level == .Level_1 else period / 8
			testing.expectf(t, len(packed) < period + slack, "period %v, %v: %v bytes", period, level, len(packed))
			output: [dynamic]byte
			defer delete(output)
			testing.expect_value(t, deflate.inflate64_raw(&output, packed[:]), nil)
			testing.expectf(t, bytes.equal(output[:], data), "period %v, %v: output differs", period, level)
		}
	}
}

@(test)
deflate64_long_matches :: proc(t: ^testing.T) {
	data := make([]byte, 1 << 20)
	defer delete(data)
	for level in D64_TEST_LEVELS {
		if level == .Stored {
			continue
		}
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, deflate.deflate64_raw(&packed, data, level), nil)
		testing.expectf(t, len(packed) < 400, "%v: %v bytes for 1 MiB of zeros", level, len(packed))
		output: [dynamic]byte
		defer delete(output)
		testing.expect_value(t, deflate.inflate64_raw(&output, packed[:]), nil)
		testing.expectf(t, bytes.equal(output[:], data), "%v: output differs", level)
	}
}

@(test)
deflate64_slice_api :: proc(t: ^testing.T) {
	data: [dynamic]byte
	defer delete(data)
	d64_test_data(3, 200000, &data)

	s := new(deflate.Deflate64)
	defer free(s)
	bound := deflate.deflate64_bound(len(data))
	testing.expect_value(t, bound, deflate.deflate_bound(len(data)))
	out := make([]byte, bound)
	defer delete(out)

	written, err := deflate.deflate64_raw(s, out, data[:], .Level_9)
	testing.expect_value(t, err, nil)
	output: [dynamic]byte
	defer delete(output)
	testing.expect_value(t, deflate.inflate64_raw(&output, out[:written]), nil)
	testing.expect(t, bytes.equal(output[:], data[:]))

	_, short_err := deflate.deflate64_raw(s, out[:bound - 1], data[:], .Level_9)
	testing.expect_value(t, short_err, compress.General_Error.Output_Too_Short)
	_, nil_err := deflate.deflate64_raw((^deflate.Deflate64)(nil), out, data[:], .Level_9)
	testing.expect_value(t, nil_err, compress.General_Error.Incompatible_Options)
}

d64_check_both :: proc(t: ^testing.T, name: string, stream: []byte, expected_64: []byte, err_64: compress.Error, err_8: compress.Error, check_8 := true) {
	for kind in Stream_Kind {
		output: [dynamic]byte
		defer delete(output)
		err := d64_unpack(.Deflate64, kind, stream, &output)
		testing.expectf(t, err == err_64, "%v, %v: inflate64 returned %v, expected %v", name, kind, err, err_64)
		if err_64 == nil {
			testing.expectf(t, bytes.equal(output[:], expected_64), "%v, %v: inflate64 output differs, %v bytes", name, kind, len(output))
		}
		if check_8 {
			output_8: [dynamic]byte
			defer delete(output_8)
			err8 := d64_unpack(.Deflate, kind, stream, &output_8)
			testing.expectf(t, err8 == err_8, "%v, %v: inflate returned %v, expected %v", name, kind, err8, err_8)
		}
	}
	reference: [dynamic]byte
	defer delete(reference)
	ok := d64_ref_inflate(stream, .Deflate64, &reference)
	testing.expectf(t, ok == (err_64 == nil), "%v: reference decoder ok %v", name, ok)
	if ok && err_64 == nil {
		testing.expectf(t, bytes.equal(reference[:], expected_64), "%v: reference output differs", name)
	}
}

@(test)
deflate64_fixed_far_distances :: proc(t: ^testing.T) {
	prefix := make([]byte, 65536)
	defer delete(prefix)
	for &c in prefix {
		c = u8(rand.uint32())
	}
	c: D64_Code
	d64_fixed_code(&c)

	for distance in ([]int{32769, 40000, 49152, 49153, 65536}) {
		b: D64_Bits
		defer delete(b.buf)
		d64_put_stored(&b, false, prefix[:65535])
		d64_put_stored(&b, false, prefix[65535:])
		d64_put(&b, 1, 1)
		d64_put(&b, 1, 2)
		symbol := 31 if distance > 49152 else 30
		d64_put_match(&b, &c, 284, 31, symbol, u64(distance - D64_DISTANCE_BASE[symbol]), .Deflate64)
		d64_put_literal(&b, &c, 256)
		d64_align(&b)

		expected: [dynamic]byte
		defer delete(expected)
		append(&expected, ..prefix)
		for _ in 0..<258 {
			append(&expected, expected[len(expected) - distance])
		}
		d64_check_both(t, "fixed far distance", b.buf[:], expected[:], nil, compress.Deflate_Error.Bad_Huffman_Code)
	}

	{
		b: D64_Bits
		defer delete(b.buf)
		d64_put_stored(&b, false, prefix[:40000])
		d64_put(&b, 1, 1)
		d64_put(&b, 1, 2)
		d64_put_match(&b, &c, 257, 0, 30, u64(40001 - 32769), .Deflate64)
		d64_put_literal(&b, &c, 256)
		d64_align(&b)
		d64_check_both(t, "distance past the start", b.buf[:], nil, compress.Deflate_Error.Bad_Distance, compress.Deflate_Error.Bad_Huffman_Code)
	}
}

@(test)
deflate64_length_285 :: proc(t: ^testing.T) {
	c: D64_Code
	d64_fixed_code(&c)
	for extra in ([]u64{0, 1, 255, 256, 65534, 65535}) {
		b: D64_Bits
		defer delete(b.buf)
		d64_put(&b, 1, 1)
		d64_put(&b, 1, 2)
		d64_put_literal(&b, &c, 'a')
		d64_put_literal(&b, &c, 'b')
		d64_put_match(&b, &c, 285, extra, 1, 0, .Deflate64)
		d64_put_match(&b, &c, 285, extra, 0, 0, .Deflate64)
		d64_put_literal(&b, &c, 256)
		d64_align(&b)

		expected: [dynamic]byte
		defer delete(expected)
		append(&expected, 'a', 'b')
		for _ in 0..<3 + int(extra) {
			append(&expected, expected[len(expected) - 2])
		}
		for _ in 0..<3 + int(extra) {
			append(&expected, expected[len(expected) - 1])
		}

		d64_check_both(t, "length 285", b.buf[:], expected[:], nil, nil, false)

		output_8: [dynamic]byte
		defer delete(output_8)
		if deflate.inflate_raw(&output_8, b.buf[:]) == nil {
			testing.expectf(t, !bytes.equal(output_8[:], expected[:]), "extra %v: method 8 decoded code 285 like Deflate64", extra)
		}
	}

	{
		b: D64_Bits
		defer delete(b.buf)
		d64_put(&b, 1, 1)
		d64_put(&b, 1, 2)
		d64_put_literal(&b, &c, 'z')
		d64_put_match(&b, &c, 284, 31, 0, 0, .Deflate64)
		d64_put_literal(&b, &c, 256)
		d64_align(&b)
		expected := make([]byte, 259)
		defer delete(expected)
		for &e in expected {
			e = 'z'
		}
		d64_check_both(t, "length 258 as 284", b.buf[:], expected, nil, nil)
	}
}

d64_dynamic_header :: proc(b: ^D64_Bits, c: ^D64_Code, hdist: int, distance_lengths: []u8) {
	lit_len: [286]u8
	for i in 0..<254 {
		lit_len[i] = 8
	}
	lit_len[254] = 9
	lit_len[255] = 9
	lit_len[256] = 9
	lit_len[285] = 9

	c^ = {}
	copy(c.lit_len[:], lit_len[:])
	copy(c.dist_len[:], distance_lengths)
	d64_canonical(c.lit_len[:], c.lit_code[:])
	d64_canonical(c.dist_len[:hdist], c.dist_code[:hdist])

	pre_len: [19]u8
	for symbol in ([]int{0, 1, 2, 5, 8, 9, 17, 18}) {
		pre_len[symbol] = 3
	}
	pre_code: [19]u32
	d64_canonical(pre_len[:], pre_code[:])

	d64_put(b, 2, 2)
	d64_put(b, 286 - 257, 5)
	d64_put(b, u64(hdist - 1), 5)
	d64_put(b, 19 - 4, 4)
	for i in 0..<19 {
		d64_put(b, u64(pre_len[D64_PRECODE_ORDER[i]]), 3)
	}
	for _ in 0..<254 {
		d64_put_code(b, pre_code[8], 3)
	}
	for _ in 0..<3 {
		d64_put_code(b, pre_code[9], 3)
	}
	d64_put_code(b, pre_code[18], 3)
	d64_put(b, 28 - 11, 7)
	d64_put_code(b, pre_code[9], 3)
	for l in distance_lengths[:hdist] {
		d64_put_code(b, pre_code[l], 3)
	}
}

@(test)
deflate64_dynamic_32_distance_codes :: proc(t: ^testing.T) {
	prefix := make([]byte, 50000)
	defer delete(prefix)
	for &p in prefix {
		p = u8(rand.uint32())
	}

	distance_lengths: [32]u8
	for &l in distance_lengths {
		l = 5
	}
	c: D64_Code
	b: D64_Bits
	defer delete(b.buf)
	d64_put_stored(&b, false, prefix)
	d64_put(&b, 1, 1)
	d64_dynamic_header(&b, &c, 32, distance_lengths[:])
	d64_put_match(&b, &c, 285, 1000, 31, 50000 - 49153, .Deflate64)
	d64_put_literal(&b, &c, 'q')
	d64_put_literal(&b, &c, 256)
	d64_align(&b)

	expected: [dynamic]byte
	defer delete(expected)
	append(&expected, ..prefix)
	for _ in 0..<1003 {
		append(&expected, expected[len(expected) - 50000])
	}
	append(&expected, 'q')
	d64_check_both(t, "HDIST 32", b.buf[:], expected[:], nil, compress.Deflate_Error.Huffman_Bad_Sizes)
}

@(test)
deflate64_single_distance_code :: proc(t: ^testing.T) {
	prefix := make([]byte, 60000)
	defer delete(prefix)
	for &p in prefix {
		p = u8(rand.uint32())
	}

	distance_lengths: [32]u8
	distance_lengths[31] = 1
	for bad in ([]bool{false, true}) {
		c: D64_Code
		b: D64_Bits
		defer delete(b.buf)
		d64_put_stored(&b, false, prefix)
		d64_put(&b, 1, 1)
		d64_dynamic_header(&b, &c, 32, distance_lengths[:])
		if bad {
			d64_put_code(&b, c.lit_code[285], c.lit_len[285])
			d64_put(&b, 0, 16)
			d64_put(&b, 1, 1)
		} else {
			d64_put_match(&b, &c, 285, 0, 31, 60000 - 49153, .Deflate64)
		}
		d64_put_literal(&b, &c, 256)
		d64_align(&b)

		expected: [dynamic]byte
		defer delete(expected)
		append(&expected, ..prefix)
		for _ in 0..<3 {
			append(&expected, expected[len(expected) - 60000])
		}
		err_64: compress.Error = compress.Deflate_Error.Bad_Huffman_Code if bad else nil
		d64_check_both(t, "single distance code", b.buf[:], expected[:], err_64, compress.Deflate_Error.Huffman_Bad_Sizes)
	}
}

@(test)
deflate64_truncated :: proc(t: ^testing.T) {
	data: [dynamic]byte
	defer delete(data)
	d64_test_data(3, 150000, &data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.deflate64_raw(&packed, data[:], .Level_6), nil)

	step := max(len(packed) / 97, 1)
	for n := 0; n < len(packed); n += step {
		for kind in ([]Stream_Kind{.Memory, .Bytes_Reader}) {
			output: [dynamic]byte
			defer delete(output)
			err := d64_unpack(.Deflate64, kind, packed[:n], &output)
			testing.expectf(t, err != nil, "%v bytes of %v, %v: truncated stream accepted", n, len(packed), kind)
		}
	}
}

@(test)
deflate64_limits :: proc(t: ^testing.T) {
	data := make([]byte, 1 << 20)
	defer delete(data)
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, deflate.deflate64_raw(&packed, data, .Level_6), nil)

	for kind in Stream_Kind {
		for expected in ([]int{len(data), 100, 65537}) {
			output: [dynamic]byte
			defer delete(output)
			err := d64_unpack(.Deflate64, kind, packed[:], &output, expected)
			if expected == len(data) {
				testing.expectf(t, err == nil, "%v: %v", kind, err)
				testing.expectf(t, len(output) == len(data), "%v: %v bytes", kind, len(output))
				if kind == .Memory {
					testing.expectf(t, cap(output) == len(data), "%v: capacity %v for an exact size", kind, cap(output))
				}
			} else {
				testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v, expected %v: %v", kind, expected, err)
				testing.expectf(t, cap(output) <= expected, "%v: capacity %v for a limit of %v", kind, cap(output), expected)
			}
		}
		for limit in ([]int{64 * 1024, 64 * 1024 + 1}) {
			output: [dynamic]byte
			defer delete(output)
			err := d64_unpack(.Deflate64, kind, packed[:], &output, -1, limit)
			testing.expectf(t, err == compress.General_Error.Output_Too_Short, "%v, limit %v: %v", kind, limit, err)
			testing.expectf(t, cap(output) <= limit, "%v: capacity %v for a maximum of %v", kind, cap(output), limit)
		}
	}

	{
		output: [dynamic]byte
		defer delete(output)
		err_64 := d64_unpack(.Deflate64, .Memory, packed[:], &output, -1, -1)
		output_8: [dynamic]byte
		defer delete(output_8)
		err_8 := d64_unpack(.Deflate, .Memory, packed[:], &output_8, -1, -1)
		testing.expectf(t, err_64 == err_8 && err_64 != nil, "negative limit gave %v and %v", err_64, err_8)
	}
}

@(test)
deflate64_expansion_reservation :: proc(t: ^testing.T) {
	c: D64_Code
	d64_fixed_code(&c)
	b: D64_Bits
	defer delete(b.buf)
	d64_put(&b, 1, 1)
	d64_put(&b, 1, 2)
	d64_put_literal(&b, &c, 'x')
	matches := 200
	for _ in 0..<matches {
		d64_put_match(&b, &c, 285, 65535, 0, 0, .Deflate64)
	}
	d64_put_literal(&b, &c, 256)
	d64_align(&b)
	size := 1 + matches * 65538

	testing.expectf(t, size <= 29128 * len(b.buf), "%v bytes from %v exceeds the expansion bound", size, len(b.buf))
	for hint in ([]int{size, 1 << 28}) {
		tracking: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking, context.allocator)
		defer mem.tracking_allocator_destroy(&tracking)

		output: [dynamic]byte
		err := deflate.inflate64_raw(&output, b.buf[:], hint, allocator = mem.tracking_allocator(&tracking))
		testing.expectf(t, err == nil, "hint %v: %v", hint, err)
		testing.expectf(t, len(output) == size, "hint %v: %v bytes", hint, len(output))
		if hint == size {
			testing.expectf(t, cap(output) == size, "hint %v: capacity %v", hint, cap(output))
		}
		testing.expectf(t, tracking.peak_memory_allocated <= i64(29128 * len(b.buf)), "hint %v: peak %v above the expansion bound %v", hint, tracking.peak_memory_allocated, 29128 * len(b.buf))
		delete(output)
	}
}

@(test)
deflate64_7zip_vector :: proc(t: ^testing.T) {
	packed, err := os.read_entire_file(ODIN_ROOT + "tests/core/assets/ZIP/deflate64_vector_7zip.bin", context.allocator)
	testing.expectf(t, err == nil, "cannot read vector: %v", err)
	if err != nil {
		return
	}
	defer delete(packed)

	data: [dynamic]byte
	defer delete(data)
	d64_vector_data(&data)
	for kind in Stream_Kind {
		output: [dynamic]byte
		defer delete(output)
		unpack_err := d64_unpack(.Deflate64, kind, packed, &output)
		testing.expectf(t, unpack_err == nil, "%v: %v", kind, unpack_err)
		testing.expectf(t, len(output) == len(data) && hash.crc32(output[:]) == hash.crc32(data[:]), "%v: output differs, %v bytes", kind, len(output))
	}
	reference: [dynamic]byte
	defer delete(reference)
	testing.expect(t, d64_ref_inflate(packed, .Deflate64, &reference) && bytes.equal(reference[:], data[:]))
}

d64_vector_data :: proc(data: ^[dynamic]byte) {
	x := u64(0x0123456789abcdef)
	next :: proc(x: ^u64) -> byte {
		x^ = x^ * 6364136223846793005 + 1442695040888963407
		return byte(x^ >> 56)
	}
	for _ in 0..<50000 {
		r := next(&x)
		append(data, ' ' if r < 40 else 'a' + r % 26)
	}
	for i in 0..<50000 {
		append(data, data[i])
	}
	for _ in 0..<70000 {
		append(data, 0)
	}
	start := len(data)
	for _ in 0..<40000 {
		append(data, next(&x))
	}
	for i in 0..<40000 {
		append(data, data[start + i])
	}
}

d64_random_code :: proc(lengths: []u8, candidates: []int, k: int, max_depth: u8, must := -1) {
	for &l in lengths {
		l = 0
	}
	if k <= 0 || len(candidates) == 0 {
		return
	}
	depths := make([dynamic]u8, context.temp_allocator)
	if k == 1 {
		append(&depths, 1)
	} else {
		append(&depths, 1, 1)
		for len(depths) < k {
			start := rand.int_max(len(depths))
			found := false
			for j in 0..<len(depths) {
				idx := (start + j) % len(depths)
				if depths[idx] < max_depth {
					d := depths[idx] + 1
					depths[idx] = d
					append(&depths, d)
					found = true
					break
				}
			}
			if !found {
				break
			}
		}
	}
	if rand.int_max(12) == 0 && len(depths) > 1 {
		unordered_remove(&depths, rand.int_max(len(depths)))
	}
	if rand.int_max(16) == 0 {
		append(&depths, u8(1 + rand.int_max(int(max_depth))))
	}
	symbols := make([dynamic]int, context.temp_allocator)
	append(&symbols, ..candidates)
	rand.shuffle(symbols[:])
	if must >= 0 && rand.int_max(20) != 0 {
		for s, i in symbols {
			if s == must {
				symbols[0], symbols[i] = symbols[i], symbols[0]
				break
			}
		}
	}
	for d, i in depths {
		if i >= len(symbols) {
			break
		}
		lengths[symbols[i]] = d
	}
}

d64_emit_symbols :: proc(b: ^D64_Bits, c: ^D64_Code, count: int, produced: ^int, format: D64_Format) {
	lits  := make([dynamic]int, context.temp_allocator)
	lens  := make([dynamic]int, context.temp_allocator)
	dists := make([dynamic]int, context.temp_allocator)
	for l, i in c.lit_len {
		if l == 0 {
			continue
		}
		switch {
		case i < 256: append(&lits, i)
		case i > 256: append(&lens, i)
		}
	}
	for l, i in c.dist_len {
		if l != 0 {
			append(&dists, i)
		}
	}
	for _ in 0..<count {
		if rand.int_max(10) < 5 && len(lits) > 0 {
			d64_put_literal(b, c, lits[rand.int_max(len(lits))])
			produced^ += 1
			continue
		}
		if len(lens) == 0 {
			continue
		}
		s := lens[rand.int_max(len(lens))]
		if format == .Deflate64 && c.lit_len[285] != 0 && rand.int_max(3) == 0 {
			s = 285
		}
		d64_put_code(b, c.lit_code[s], c.lit_len[s])
		length: int
		if format == .Deflate64 && s == 285 {
			extra: u64
			switch rand.int_max(4) {
			case 0: extra = 65535
			case 1: extra = u64(rand.int_max(256))
			case:   extra = u64(rand.int_max(65536))
			}
			if rand.int_max(8) == 0 {
				extra = u64(rand.int_max(4096))
			}
			d64_put(b, extra, 16)
			length = 3 + int(extra)
		} else if s < 286 {
			extra := u64(rand.uint32())
			n := D64_LENGTH_EXTRA[s - 257]
			d64_put(b, extra, n)
			length = D64_LENGTH_BASE[s - 257] + int(extra & ((u64(1) << n) - 1))
		}
		if len(dists) == 0 {
			continue
		}
		d := dists[rand.int_max(len(dists))]
		if rand.int_max(5) != 0 {
			best := -1
			for candidate in dists {
				if D64_DISTANCE_BASE[candidate] <= produced^ && (best < 0 || rand.int_max(3) == 0 || candidate >= 30) {
					best = candidate
				}
			}
			if best >= 0 {
				d = best
			}
		}
		d64_put_code(b, c.dist_code[d], c.dist_len[d])
		room  := produced^ - D64_DISTANCE_BASE[d]
		span  := (1 << D64_DISTANCE_EXTRA[d]) - 1
		extra := rand.int_max(span + 1)
		if room >= 0 && rand.int_max(6) != 0 {
			extra = min(extra, room)
		}
		d64_put(b, u64(extra), D64_DISTANCE_EXTRA[d])
		produced^ += length
	}
	if c.lit_len[256] != 0 && rand.int_max(30) != 0 {
		d64_put_literal(b, c, 256)
	}
}

d64_craft_dynamic :: proc(b: ^D64_Bits, produced: ^int, format: D64_Format) {
	hlit  := 257 + (rand.int_max(32) if rand.int_max(20) == 0 else rand.int_max(30))
	hdist := 1 + rand.int_max(32)
	if rand.int_max(3) == 0 {
		hlit = 286
		hdist = 32
	}
	lengths := make([]u8, hlit + hdist, context.temp_allocator)
	candidates := make([dynamic]int, context.temp_allocator)
	for i in 0..<hlit {
		append(&candidates, i)
	}
	k := 2 + rand.int_max(hlit - 1)
	if rand.int_max(4) == 0 {
		k = 2 + rand.int_max(20)
	}
	d64_random_code(lengths[:hlit], candidates[:], k, 15, 256)
	if hlit == 286 && lengths[285] == 0 && rand.int_max(2) == 0 {
		for i in 257..<285 {
			if lengths[i] != 0 {
				lengths[285], lengths[i] = lengths[i], 0
				break
			}
		}
	}
	clear(&candidates)
	for i in 0..<hdist {
		append(&candidates, i)
	}
	dk := rand.int_max(hdist + 1)
	if rand.int_max(3) == 0 {
		dk = 1 + rand.int_max(3)
	}
	d64_random_code(lengths[hlit:], candidates[:], dk, 15, hdist - 1 if hdist > 30 else -1)
	if rand.int_max(25) == 0 {
		for _ in 0..<1 + rand.int_max(4) {
			lengths[rand.int_max(len(lengths))] = u8(rand.int_max(16))
		}
	}

	Run :: struct {
		symbol: int,
		extra:  u64,
		bits:   uint,
	}
	runs := make([dynamic]Run, context.temp_allocator)
	i := 0
	for i < len(lengths) {
		v := lengths[i]
		j := i + 1
		for j < len(lengths) && lengths[j] == v {
			j += 1
		}
		run := j - i
		switch {
		case rand.int_max(6) == 0:
			append(&runs, Run{int(v), 0, 0})
			i += 1
		case v == 0 && run >= 11:
			n := min(run, 138)
			append(&runs, Run{18, u64(n - 11), 7})
			i += n
		case v == 0 && run >= 3:
			n := min(run, 10)
			append(&runs, Run{17, u64(n - 3), 3})
			i += n
		case v != 0 && run >= 4:
			n := min(run - 1, 6)
			append(&runs, Run{int(v), 0, 0}, Run{16, u64(n - 3), 2})
			i += 1 + n
		case:
			append(&runs, Run{int(v), 0, 0})
			i += 1
		}
	}
	if rand.int_max(40) == 0 {
		append(&runs, Run{18, 127, 7})
	}

	pre_len:  [19]u8
	pre_code: [19]u32
	used:     [19]bool
	for run in runs {
		used[run.symbol] = true
	}
	clear(&candidates)
	for s in 0..<19 {
		if used[s] {
			append(&candidates, s)
		}
	}
	if len(candidates) == 1 {
		append(&candidates, (candidates[0] + 1) % 19)
	}
	d64_random_code(pre_len[:], candidates[:], len(candidates), 7)
	if rand.int_max(30) == 0 {
		pre_len[rand.int_max(19)] = u8(rand.int_max(8))
	}
	d64_canonical(pre_len[:], pre_code[:])
	hclen := 4
	for idx in 0..<19 {
		if pre_len[D64_PRECODE_ORDER[idx]] != 0 {
			hclen = max(hclen, idx + 1)
		}
	}

	d64_put(b, 2, 2)
	d64_put(b, u64(hlit - 257), 5)
	d64_put(b, u64(hdist - 1), 5)
	d64_put(b, u64(hclen - 4), 4)
	for idx in 0..<hclen {
		d64_put(b, u64(pre_len[D64_PRECODE_ORDER[idx]]), 3)
	}
	for run in runs {
		d64_put_code(b, pre_code[run.symbol], pre_len[run.symbol])
		d64_put(b, run.extra, run.bits)
	}

	c: D64_Code
	copy(c.lit_len[:], lengths[:hlit])
	copy(c.dist_len[:], lengths[hlit:])
	d64_canonical(c.lit_len[:], c.lit_code[:])
	d64_canonical(c.dist_len[:], c.dist_code[:])
	d64_emit_symbols(b, &c, rand.int_max(300), produced, format)
}

d64_craft_stream :: proc(format: D64_Format, out: ^[dynamic]byte) {
	b: D64_Bits
	b.buf = make([dynamic]byte, context.temp_allocator)
	produced := 0
	if rand.int_max(2) == 0 {
		n := 32769 + rand.int_max(65535 - 32769)
		prefix := make([]byte, n, context.temp_allocator)
		for &p in prefix {
			p = u8(rand.uint32())
		}
		d64_put_stored(&b, false, prefix)
		produced = n
	}
	blocks := 1 + rand.int_max(4)
	for block in 0..<blocks {
		final := block == blocks - 1
		if rand.int_max(20) == 0 {
			final = !final
		}
		d64_put(&b, 1 if final else 0, 1)
		switch rand.int_max(10) {
		case 0:
			n := rand.int_max(300)
			d64_put(&b, 0, 2)
			d64_align(&b)
			nlen := ~u16(n)
			if rand.int_max(10) == 0 {
				nlen = u16(rand.uint32())
			}
			d64_put(&b, u64(n), 16)
			d64_put(&b, u64(nlen), 16)
			for _ in 0..<n {
				d64_put(&b, u64(rand.uint32()), 8)
			}
			produced += n
		case 1, 2, 3:
			c: D64_Code
			d64_fixed_code(&c)
			if rand.int_max(8) != 0 {
				c.lit_len[286] = 0
				c.lit_len[287] = 0
			}
			if format == .Deflate && rand.int_max(8) != 0 {
				c.dist_len[30] = 0
				c.dist_len[31] = 0
			}
			d64_put(&b, 1, 2)
			d64_emit_symbols(&b, &c, rand.int_max(300), &produced, format)
		case 4:
			d64_put(&b, 3, 2)
		case:
			d64_craft_dynamic(&b, &produced, format)
		}
		if final && rand.int_max(10) != 0 {
			break
		}
	}
	d64_align(&b)
	for _ in 0..<rand.int_max(4) * rand.int_max(3) {
		append(&b.buf, u8(rand.uint32()))
	}
	append(out, ..b.buf[:])
}

d64_mutate :: proc(data: ^[dynamic]byte) {
	if len(data) == 0 {
		return
	}
	for _ in 0..<1 + rand.int_max(4) {
		switch rand.int_max(4) {
		case 0:
			i := rand.int_max(len(data))
			data[i] ~= 1 << uint(rand.int_max(8))
		case 1:
			data[rand.int_max(len(data))] = u8(rand.uint32())
		case 2:
			resize(data, rand.int_max(len(data) + 1))
			if len(data) == 0 {
				return
			}
		case 3:
			i := rand.int_max(len(data))
			n := min(1 + rand.int_max(16), len(data) - i)
			for j in 0..<n {
				data[i + j] = 0xff if rand.int_max(2) == 0 else 0
			}
		}
	}
}

d64_differential :: proc(t: ^testing.T, format: D64_Format, stream: []byte, label: string) -> (ok: bool) {
	reference: [dynamic]byte
	defer delete(reference)
	ok = d64_ref_inflate(stream, format, &reference)

	kind := Stream_Kind(rand.int_max(len(Stream_Kind)))
	for k in ([]Stream_Kind{.Memory, kind}) {
		output: [dynamic]byte
		defer delete(output)
		err := d64_unpack(format, k, stream, &output)
		if ok != (err == nil) {
			testing.expectf(t, false, "%v %v %v: reference ok %v, ours %v (%v bytes in, %v out)", label, format, k, ok, err, len(stream), len(reference))
			return
		}
		if ok && !bytes.equal(output[:], reference[:]) {
			testing.expectf(t, false, "%v %v %v: output differs, %v vs %v bytes", label, format, k, len(output), len(reference))
			return
		}
	}

	if ok && len(reference) > 1 {
		expected := 1 + rand.int_max(len(reference) - 1) if rand.int_max(2) == 0 else len(reference)
		output: [dynamic]byte
		defer delete(output)
		err := d64_unpack(format, .Memory, stream, &output, expected)
		if expected == len(reference) {
			testing.expectf(t, err == nil && cap(output) == expected, "%v %v: exact size %v gave %v, capacity %v", label, format, expected, err, cap(output))
		} else {
			testing.expectf(t, err == compress.General_Error.Output_Too_Short && cap(output) <= expected, "%v %v: limit %v below %v gave %v, capacity %v", label, format, expected, len(reference), err, cap(output))
		}
	}
	return
}

@(test)
deflate64_fuzz_crafted :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	ok_count: [D64_Format]int
	for i in 0..<D64_FUZZ_CRAFTED {
		format := D64_Format.Deflate64 if i % 4 != 3 else D64_Format.Deflate
		stream: [dynamic]byte
		defer delete(stream)
		d64_craft_stream(format, &stream)
		if rand.int_max(4) == 0 {
			d64_mutate(&stream)
		}
		if d64_differential(t, format, stream[:], "crafted") {
			ok_count[format] += 1
		}
		if format == .Deflate64 {
			d64_differential(t, .Deflate, stream[:], "crafted as method 8")
		}
		free_all(context.temp_allocator)
	}
	testing.expectf(t, ok_count[.Deflate64] > D64_FUZZ_CRAFTED / 10, "only %v valid Deflate64 streams", ok_count[.Deflate64])
	testing.expectf(t, ok_count[.Deflate] > D64_FUZZ_CRAFTED / 80, "only %v valid Deflate streams", ok_count[.Deflate])
}

@(test)
deflate64_fuzz_packed :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	for _ in 0..<D64_FUZZ_PACKED {
		data: [dynamic]byte
		defer delete(data)
		d64_test_data(rand.int_max(4), rand.int_max(200000), &data)
		level := deflate.Deflate_Level(rand.int_max(11))
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, deflate.deflate64_raw(&packed, data[:], level), nil)

		reference: [dynamic]byte
		defer delete(reference)
		testing.expectf(t, d64_ref_inflate(packed[:], .Deflate64, &reference, strict = true) && bytes.equal(reference[:], data[:]), "%v: reference decoder rejects our output", level)
		d64_differential(t, .Deflate64, packed[:], "packed")

		for _ in 0..<8 {
			mutated: [dynamic]byte
			defer delete(mutated)
			append(&mutated, ..packed[:])
			d64_mutate(&mutated)
			d64_differential(t, .Deflate64, mutated[:], "mutated")
		}
		free_all(context.temp_allocator)
	}
}
