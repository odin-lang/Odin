package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/deflate"
import "core:hash"
import "core:io"
import "core:log"
import "core:math/rand"
import "core:testing"

context_test_data := ```
Hellope, World!
```

@(test)
compress_memory_context :: proc(t: ^testing.T) {
	log.infof("context_test_data: (%v)\n%v", len(context_test_data), context_test_data)

	data := transmute([]byte)context_test_data
	ctx  := compress.init_context(&data)

	fully_in_memory := compress.is_memory_context(&ctx)
	assert(fully_in_memory, "Expected a `compress.Context` initialized with `^[]byte`")

	test_compress_context(t, &ctx)
}

@(test)
compress_stream_context :: proc(t: ^testing.T) {
	log.infof("context_test_data: (%v)\n%v", len(context_test_data), context_test_data)

	r: bytes.Reader
	data := transmute([]byte)context_test_data
	ctx  := compress.init_context(bytes.reader_init(&r, data))
	defer compress.destroy_context(&ctx)

	fully_in_memory := compress.is_memory_context(&ctx)
	assert(!fully_in_memory, "Expected a `compress.Context` initialized with `io.Stream`")

	testing.expect(t, test_compress_context(t, &ctx) == nil)
}

test_compress_context :: proc(t: ^testing.T, ctx: ^compress.Context) -> (err: io.Error) {
	size := compress.size(ctx) or_return
	testing.expect_value(t, size, i64(len(context_test_data)))

	hell := compress.read_data(ctx, u32le) or_return
	testing.expect_value(t, hell, 1819043144)

	compress.read_ptr(ctx, &hell) or_return
	testing.expect_value(t, hell, 744845423)

	buf: [7]byte
	compress.read_slice(ctx, buf[:]) or_return
	testing.expect_value(t, string(buf[:]), " World!")

	return nil
}
Trickle_Reader :: struct {
	data:     []byte,
	position: int,
	chunk:    int,
	seekable: bool,
}

trickle_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Trickle_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		if r.position >= len(r.data) {
			return 0, .EOF
		}
		count := min(r.chunk, len(p), len(r.data) - r.position)
		copy(p, r.data[r.position:][:count])
		r.position += count
		return i64(count), nil
	case .Seek:
		if !r.seekable {
			return 0, .Unsupported
		}
		target: i64
		switch whence {
		case .Start:   target = offset
		case .Current: target = i64(r.position) + offset
		case .End:     target = i64(len(r.data)) + offset
		}
		if target < 0 {
			return 0, .Invalid_Offset
		}
		r.position = int(min(target, i64(len(r.data))))
		return target, nil
	case .Size:
		if !r.seekable {
			return 0, .Unsupported
		}
		return i64(len(r.data)), nil
	case .Query:
		if r.seekable {
			return io.query_utility({.Read, .Seek, .Size, .Query})
		}
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

trickle_stream :: proc(r: ^Trickle_Reader) -> io.Stream {
	return io.Stream{procedure = trickle_proc, data = r}
}

STREAM_TEST_SIZE :: 200_000

stream_test_data :: proc() -> []byte {
	data := make([]byte, STREAM_TEST_SIZE)
	_ = rand.read(data)
	return data
}

Stream_Kind :: enum {
	Memory,
	Bytes_Reader,
	One_Byte_No_Seek,
	Odd_Chunks_Seekable,
}

stream_test_context :: proc(kind: Stream_Kind, data: ^[]byte, br: ^bytes.Reader, tr: ^Trickle_Reader, output: ^[dynamic]byte = nil) -> compress.Context {
	switch kind {
	case .Memory:
		return compress.init_context(data, output)
	case .Bytes_Reader:
		return compress.init_context(bytes.reader_init(br, data^), output)
	case .One_Byte_No_Seek:
		tr^ = {data = data^, chunk = 1}
		return compress.init_context(trickle_stream(tr), output)
	case .Odd_Chunks_Seekable:
		tr^ = {data = data^, chunk = 4097, seekable = true}
		return compress.init_context(trickle_stream(tr), output)
	}
	return {}
}

@(test)
compress_context_window :: proc(t: ^testing.T) {
	data := stream_test_data()
	defer delete(data)

	for kind in Stream_Kind {
		br: bytes.Reader
		tr: Trickle_Reader
		ctx := stream_test_context(kind, &data, &br, &tr)
		defer compress.destroy_context(&ctx)

		if kind != .One_Byte_No_Seek {
			size, size_err := compress.size(&ctx)
			testing.expectf(t, size_err == nil && size == STREAM_TEST_SIZE, "%v: size %v, %v", kind, size, size_err)
		}

		first, first_err := compress.read_data(&ctx, u32le)
		testing.expectf(t, first_err == nil && first == (^u32le)(&data[0])^, "%v: read_data", kind)

		peeked, peek_err := compress.peek_data(&ctx, u16le, 100)
		testing.expectf(t, peek_err == nil && peeked == (^u16le)(&data[104])^, "%v: peek_data at offset", kind)

		big := make([]byte, 100_000)
		defer delete(big)
		testing.expectf(t, compress.read_slice(&ctx, big) == nil && bytes.equal(big, data[4:100_004]), "%v: large read_slice", kind)

		testing.expectf(t, compress.skip(&ctx, 70_000) == nil, "%v: skip", kind)

		b, b_err := compress.read_u8(&ctx)
		testing.expectf(t, b_err == nil && b == data[170_004], "%v: read_u8 after skip", kind)

		rest := make([]byte, STREAM_TEST_SIZE - 170_005)
		defer delete(rest)
		testing.expectf(t, compress.read_slice(&ctx, rest) == nil && bytes.equal(rest, data[170_005:]), "%v: read to end", kind)

		_, end_err := compress.read_u8(&ctx)
		testing.expectf(t, end_err == .EOF, "%v: expected .EOF at the end, got %v", kind, end_err)
	}
}

@(test)
compress_context_zlib_stored :: proc(t: ^testing.T) {
	data := stream_test_data()
	defer delete(data)

	packed: [dynamic]byte
	defer delete(packed)
	append(&packed, 0x78, 0x01)
	for offset := 0; offset < len(data); offset += 65535 {
		block := data[offset:][:min(65535, len(data) - offset)]
		final := u8(1) if offset + len(block) == len(data) else 0
		n := u16(len(block))
		append(&packed, final, u8(n), u8(n >> 8), u8(~n), u8(~n >> 8))
		append(&packed, ..block)
	}
	adler := hash.adler32(data)
	append(&packed, u8(adler >> 24), u8(adler >> 16), u8(adler >> 8), u8(adler))

	for kind in Stream_Kind {
		input := packed[:]
		br: bytes.Reader
		tr: Trickle_Reader
		output: [dynamic]byte
		defer delete(output)
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		defer compress.destroy_context(&ctx)

		err := deflate.inflate_zlib(&ctx)
		testing.expectf(t, err == nil, "%v: inflate_zlib returned %v", kind, err)
		testing.expectf(t, bytes.equal(output[:], data), "%v: inflate_zlib output differs", kind)
	}
}

Fixed_Writer :: struct {
	out:   ^[dynamic]byte,
	bits:  u64,
	count: uint,
}

fixed_put :: proc(w: ^Fixed_Writer, value: u32, count: uint) {
	w.bits |= u64(value) << w.count
	w.count += count
	for w.count >= 8 {
		append(w.out, u8(w.bits))
		w.bits >>= 8
		w.count -= 8
	}
}

fixed_put_code :: proc(w: ^Fixed_Writer, code: u32, count: uint) {
	reversed: u32
	for i in 0..<count {
		reversed |= ((code >> i) & 1) << (count - 1 - i)
	}
	fixed_put(w, reversed, count)
}

fixed_put_symbol :: proc(w: ^Fixed_Writer, symbol: u32) {
	switch symbol {
	case 0..=143:   fixed_put_code(w, 0x30 + symbol, 8)
	case 144..=255: fixed_put_code(w, 0x190 + symbol - 144, 9)
	case 256..=279: fixed_put_code(w, symbol - 256, 7)
	case:           fixed_put_code(w, 0xc0 + symbol - 280, 8)
	}
}

FIXED_LENGTH_BASE   := [29]u32{3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258}
FIXED_LENGTH_EXTRA  := [29]uint{0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0}
FIXED_DISTANCE_BASE := [30]u32{1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577}
FIXED_DISTANCE_EXTRA := [30]uint{0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13}

fixed_put_match :: proc(w: ^Fixed_Writer, length, distance: u32) {
	l := 28
	for FIXED_LENGTH_BASE[l] > length { l -= 1 }
	fixed_put_symbol(w, 257 + u32(l))
	fixed_put(w, length - FIXED_LENGTH_BASE[l], FIXED_LENGTH_EXTRA[l])
	d := 29
	for FIXED_DISTANCE_BASE[d] > distance { d -= 1 }
	fixed_put_code(w, u32(d), 5)
	fixed_put(w, distance - FIXED_DISTANCE_BASE[d], FIXED_DISTANCE_EXTRA[d])
}

STREAM_MATCH_DISTANCE :: 777

stream_match_data :: proc() -> []byte {
	data := stream_test_data()
	for i in STREAM_MATCH_DISTANCE..<len(data) {
		if (i / 1000) % 3 != 0 {
			data[i] = data[i - STREAM_MATCH_DISTANCE]
		}
	}
	return data
}

fixed_zlib_pack :: proc(data: []byte, out: ^[dynamic]byte, stored_tail: []byte = nil) {
	append(out, 0x78, 0x01)
	w := Fixed_Writer{out = out}
	fixed_put(&w, 0b010 if len(stored_tail) > 0 else 0b011, 3)
	for i := 0; i < len(data); {
		length := 0
		if i >= STREAM_MATCH_DISTANCE {
			for length < 258 && i + length < len(data) && data[i + length] == data[i + length - STREAM_MATCH_DISTANCE] {
				length += 1
			}
		}
		if length >= 3 {
			fixed_put_match(&w, u32(length), STREAM_MATCH_DISTANCE)
			i += length
		} else {
			fixed_put_symbol(&w, u32(data[i]))
			i += 1
		}
	}
	fixed_put_symbol(&w, 256)
	if len(stored_tail) > 0 {
		fixed_put(&w, 0b001, 3)
		fixed_put(&w, 0, (8 - w.count) & 7)
		n := u16(len(stored_tail))
		append(out, u8(n), u8(n >> 8), u8(~n), u8(~n >> 8))
		append(out, ..stored_tail)
	} else {
		fixed_put(&w, 0, 7)
	}
	adler := hash.adler32(data)
	if len(stored_tail) > 0 {
		adler = hash.adler32(stored_tail, adler)
	}
	append(out, u8(adler >> 24), u8(adler >> 16), u8(adler >> 8), u8(adler))
}

@(test)
compress_context_zlib_fixed :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	TRAILER     :: [5]byte{'O', 'd', 'i', 'n', '!'}
	STORED_TAIL :: "Hellope, stored block!"

	expected: [dynamic]byte
	defer delete(expected)
	append(&expected, ..data)
	append(&expected, STORED_TAIL)

	for tail in ([]string{"", STORED_TAIL}) {
		packed: [dynamic]byte
		defer delete(packed)
		fixed_zlib_pack(data, &packed, transmute([]byte)tail)
		testing.expectf(t, len(packed) < len(data), "fixed packing didn't compress: %v -> %v", len(data), len(packed))
		trailer := TRAILER
		append(&packed, ..trailer[:])
		want := expected[:len(data) + len(tail)]

		for kind in Stream_Kind {
			input := packed[:]
			br: bytes.Reader
			tr: Trickle_Reader
			output: [dynamic]byte
			defer delete(output)
			ctx := stream_test_context(kind, &input, &br, &tr, &output)
			defer compress.destroy_context(&ctx)

			err := deflate.inflate_zlib(&ctx)
			testing.expectf(t, err == nil, "%v, tail %q: inflate_zlib returned %v", kind, tail, err)
			testing.expectf(t, bytes.equal(output[:], want), "%v, tail %q: inflate_zlib output differs", kind, tail)

			rest: [5]byte
			rest_err := compress.read_slice(&ctx, rest[:])
			testing.expectf(t, rest_err == nil && rest == TRAILER, "%v, tail %q: bytes after the stream were %v, %v", kind, tail, rest, rest_err)
		}
	}
}
