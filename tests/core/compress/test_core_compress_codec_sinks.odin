package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/lz4"
import "core:io"
import "core:math/rand"
import "core:testing"

CODEC_SINKS_FUZZ :: #config(CODEC_SINKS_FUZZ, 100)

Codec :: enum {
	BZip2,
	LZ4,
}

@(test)
codec_sinks_round_trip :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)
	g := Lz4_Test_Lcg{state = 0x5ee1}
	text := lz4_test_lcg_text(&g, 1_500_000 if !SLIM_TESTS else 200_000)
	defer delete(text)

	for input in ([][]byte{data, text}) {
		for level in ([]bzip2.Level{.Level_1, .Level_9}) {
			packed: [dynamic]byte
			defer delete(packed)
			testing.expect_value(t, bzip2.compress(&packed, input, level), nil)
			trailer := DEFLATE_TEST_TRAILER
			append(&packed, ..trailer[:])
			for kind in Stream_Kind {
				if kind == .One_Byte_No_Seek && len(input) > 400_000 {
					continue
				}
				for chunk in ([]int{0, 300, 32 * 1024, 1 << 20}) {
					codec_sinks_check(t, "bzip2 round trip", .BZip2, kind, packed[:], options = {chunk_size = chunk})
				}
			}
		}

		for block in ([]lz4.Block_Max_Size{.Max_64KiB, .Max_256KiB, .Max_4MiB}) {
			for flags in ([]lz4.Frame_Flags{{}, lz4.DEFAULT_FRAME_FLAGS, {.Independent_Blocks, .Block_Checksum}, {.Content_Checksum, .Block_Checksum, .Content_Size}}) {
				for level in ([]lz4.Level{.Level_1, .Level_4}) {
					packed: [dynamic]byte
					defer delete(packed)
					testing.expect_value(t, lz4.compress_frame(&packed, input, level, {block_max_size = block, flags = flags}), nil)
					trailer := DEFLATE_TEST_TRAILER
					append(&packed, ..trailer[:])
					for kind in Stream_Kind {
						if kind == .One_Byte_No_Seek && len(input) > 400_000 {
							continue
						}
						for chunk in ([]int{0, 300, 100_000}) {
							codec_sinks_check(t, "lz4 round trip", .LZ4, kind, packed[:], options = {chunk_size = chunk})
						}
					}
				}
			}
		}
	}
}

@(test)
codec_sinks_vectors :: proc(t: ^testing.T) {
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	vectors := [][]byte{LZ4_VECTOR_B4_LINKED, LZ4_VECTOR_B4_CHECKSUM, LZ4_VECTOR_B4_NOCRC, LZ4_VECTOR_B5, LZ4_VECTOR_B6, LZ4_VECTOR_B7_HC, LZ4_VECTOR_LEGACY, LZ4_VECTOR_STORED, LZ4_VECTOR_EMPTY}
	for v in vectors {
		for kind in Stream_Kind {
			codec_sinks_check(t, "lz4 vector", .LZ4, kind, v)
		}
	}
	for kind in Stream_Kind {
		codec_sinks_check(t, "lz4 dictionary", .LZ4, kind, LZ4_VECTOR_DICT, dictionary = inputs.dictionary)
		codec_sinks_check(t, "lz4 dictionary missing", .LZ4, kind, LZ4_VECTOR_DICT)
	}

	skippable := [?]byte{0x5a, 0x2a, 0x4d, 0x18, 3, 0, 0, 0, 'x', 'y', 'z'}
	packed: [dynamic]byte
	defer delete(packed)
	append(&packed, ..LZ4_VECTOR_B5)
	append(&packed, ..skippable[:])
	append(&packed, ..LZ4_VECTOR_EMPTY)
	append(&packed, ..LZ4_VECTOR_B4_LINKED)
	append(&packed, ..LZ4_VECTOR_LEGACY)
	append(&packed, ..LZ4_VECTOR_STORED)
	append(&packed, ..skippable[:])
	trailer := DEFLATE_TEST_TRAILER
	append(&packed, ..trailer[:])
	for kind in Stream_Kind {
		for chunk in ([]int{0, 1, 1000, 70_000}) {
			codec_sinks_check(t, "lz4 concatenated", .LZ4, kind, packed[:], options = {chunk_size = chunk})
		}
	}

	streams: [dynamic]byte
	defer delete(streams)
	for level in ([]bzip2.Level{.Level_1, .Level_5, .Level_2}) {
		part := bz_lcg(120_000 * int(level), int(level) + 3)
		defer delete(part)
		for size in ([]int{len(part), 777}) {
			testing.expect_value(t, bzip2.compress(&packed, part[:size], level), nil)
			append(&streams, ..packed[:])
		}
	}
	append(&streams, ..trailer[:])
	for kind in Stream_Kind {
		for chunk in ([]int{0, 1, 1000, 70_000}) {
			codec_sinks_check(t, "bzip2 concatenated", .BZip2, kind, streams[:], options = {chunk_size = chunk})
		}
	}

	hello := transmute([]u8)string(BZ_HELLO_PACKED)
	empty := transmute([]u8)string("BZh9\x17\x72\x45\x38\x50\x90\x00\x00\x00\x00")
	for kind in Stream_Kind {
		codec_sinks_check(t, "bzip2 hello", .BZip2, kind, hello)
		codec_sinks_check(t, "bzip2 empty", .BZip2, kind, empty)
		codec_sinks_check(t, "bzip2 empty, expected", .BZip2, kind, empty, 1 << 20)
	}

	bomb := bz_bomb(40_000)
	defer delete(bomb)
	for chunk in ([]int{0, 1, 300, 4096}) {
		codec_sinks_check(t, "bzip2 bomb", .BZip2, .Memory, bomb[:], options = {chunk_size = chunk})
		codec_sinks_check(t, "bzip2 bomb", .BZip2, .Odd_Chunks_Seekable, bomb[:], options = {chunk_size = chunk})
	}
	for limit in ([]int{1, 3, 259 * 1000 + 100, 259 * 40_000 - 1}) {
		codec_sinks_check(t, "bzip2 bomb limit", .BZip2, .Memory, bomb[:], options = {max_output_size = limit})
		codec_sinks_check(t, "bzip2 bomb limit", .BZip2, .Bytes_Reader, bomb[:], options = {max_output_size = limit, chunk_size = 777})
	}

	random := codec_bzip2_randomised(5000)
	defer delete(random)
	for kind in Stream_Kind {
		for chunk in ([]int{0, 1, 999}) {
			codec_sinks_check(t, "bzip2 randomised", .BZip2, kind, random[:], options = {chunk_size = chunk})
		}
	}
}

@(test)
codec_reader_random_reads :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for codec in Codec {
		packed: [dynamic]byte
		defer delete(packed)
		codec_pack(codec, data, &packed)

		for round in 0..<8 {
			kind := Stream_Kind(round % len(Stream_Kind))
			output: [dynamic]byte
			defer delete(output)
			err, _, _ := codec_unpack(.Reader, codec, kind, packed[:], &output, -1, {chunk_size = 1 + rand.int_max(100_000)}, nil, nil)
			testing.expectf(t, err == nil, "%v, %v: %v", codec, kind, err)
			testing.expectf(t, bytes.equal(output[:], data), "%v, %v: output differs, %v vs %v bytes", codec, kind, len(output), len(data))
		}

		input := packed[:]
		ctx := compress.init_context(&input)
		buffer: [100]byte
		switch codec {
		case .BZip2:
			r: bzip2.Reader
			defer bzip2.reader_destroy(&r)
			testing.expect_value(t, bzip2.reader_init(&r, &ctx), nil)
			total := 0
			for {
				n, err := bzip2.reader_read(&r, buffer[:])
				total += n
				if err != nil {
					testing.expect_value(t, err, io.Error.EOF)
					break
				}
				testing.expect(t, n > 0)
			}
			testing.expect_value(t, total, len(data))
			n, again := bzip2.reader_read(&r, buffer[:])
			testing.expectf(t, n == 0 && again == io.Error.EOF, "%v: read after EOF gave %v, %v", codec, n, again)
			n, again = bzip2.reader_read(&r, nil)
			testing.expectf(t, n == 0 && again == nil, "%v: empty read after EOF gave %v, %v", codec, n, again)
		case .LZ4:
			r: lz4.Frame_Reader
			defer lz4.frame_reader_destroy(&r)
			testing.expect_value(t, lz4.frame_reader_init(&r, &ctx), nil)
			total := 0
			for {
				n, err := lz4.frame_reader_read(&r, buffer[:])
				total += n
				if err != nil {
					testing.expect_value(t, err, io.Error.EOF)
					break
				}
				testing.expect(t, n > 0)
			}
			testing.expect_value(t, total, len(data))
			n, again := lz4.frame_reader_read(&r, buffer[:])
			testing.expectf(t, n == 0 && again == io.Error.EOF, "%v: read after EOF gave %v, %v", codec, n, again)
			n, again = lz4.frame_reader_read(&r, nil)
			testing.expectf(t, n == 0 && again == nil, "%v: empty read after EOF gave %v, %v", codec, n, again)
		}
	}
}

@(test)
codec_reader_as_stream :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for codec in Codec {
		packed: [dynamic]byte
		defer delete(packed)
		codec_pack(codec, data, &packed)

		for corrupt in ([]bool{false, true}) {
			if corrupt {
				switch codec {
				case .BZip2: packed[len(packed) - 3] ~= 0x55
				case .LZ4:   packed[len(packed) - 2] ~= 0x55
				}
			}
			input := packed[:]
			ctx := compress.init_context(&input)
			stream: io.Stream
			reader_err: ^compress.Error
			br: bzip2.Reader
			lr: lz4.Frame_Reader
			switch codec {
			case .BZip2:
				testing.expect_value(t, bzip2.reader_init(&br, &ctx), nil)
				stream     = bzip2.reader_to_stream(&br)
				reader_err = &br.err
			case .LZ4:
				testing.expect_value(t, lz4.frame_reader_init(&lr, &ctx), nil)
				stream     = lz4.frame_reader_to_stream(&lr)
				reader_err = &lr.err
			}
			testing.expect_value(t, io.query(stream), io.Stream_Mode_Set{.Read, .Destroy, .Query})

			output := make([]byte, len(data))
			defer delete(output)
			n, err := io.read_full(stream, output)
			testing.expectf(t, err == nil && n == len(data), "%v, corrupt %v: %v, %v bytes", codec, corrupt, err, n)
			testing.expectf(t, bytes.equal(output, data), "%v, corrupt %v: output differs", codec, corrupt)
			extra: [1]byte
			n, err = io.read(stream, extra[:])
			testing.expect_value(t, n, 0)
			if corrupt {
				testing.expect_value(t, err, io.Error.Unknown)
				want := compress.Error(compress.BZip2_Error.Stream_Checksum_Failed) if codec == .BZip2 else compress.Error(compress.LZ4_Error.Content_Checksum_Failed)
				testing.expect_value(t, reader_err^, want)
			} else {
				testing.expect_value(t, err, io.Error.EOF)
			}
			io.destroy(stream)
		}
	}
}

@(test)
codec_truncated :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	cuts := 8 if SLIM_TESTS else 40
	for codec in Codec {
		for variant in 0..<3 {
			packed: [dynamic]byte
			defer delete(packed)
			switch codec {
			case .BZip2:
				testing.expect_value(t, bzip2.compress(&packed, data, bzip2.Level(1 + 4 * variant)), nil)
			case .LZ4:
				flags := []lz4.Frame_Flags{lz4.DEFAULT_FRAME_FLAGS, {.Independent_Blocks}, {.Block_Checksum}}
				testing.expect_value(t, lz4.compress_frame(&packed, data, .Level_1, {block_max_size = .Max_64KiB, flags = flags[variant]}), nil)
			}

			for step in 0..<cuts + 8 {
				cut := len(packed) * step / cuts if step < cuts else len(packed) - 1 - (step - cuts)
				for kind in Stream_Kind {
					if kind == .One_Byte_No_Seek && step % 8 != 3 {
						continue
					}
					want_err := codec_sinks_check(t, "truncated", codec, kind, packed[:cut])
					testing.expectf(t, want_err != nil, "%v, %v, cut %v of %v: no error", codec, kind, cut, len(packed))

					want: [dynamic]byte
					defer delete(want)
					codec_memory_unpack(codec, kind, packed[:cut], &want, -1, {}, nil, nil)
					testing.expectf(t, len(want) <= len(data) && bytes.equal(want[:], data[:len(want)]), "%v, %v, cut %v of %v: output is not a prefix", codec, kind, cut, len(packed))
				}
			}
		}
	}
}

@(test)
codec_sinks_options :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for codec in Codec {
		packed: [dynamic]byte
		defer delete(packed)
		codec_pack(codec, data, &packed)

		for size in ([]int{1, 5000, 1 << 20}) {
			buffer := make([]byte, size)
			defer delete(buffer)
			ok := codec == .BZip2 || size == 1 << 20
			for kind in ([]Stream_Kind{.Memory, .Odd_Chunks_Seekable}) {
				output: [dynamic]byte
				defer delete(output)
				err, _, _ := codec_unpack(.Writer, codec, kind, packed[:], &output, -1, {buffer = buffer}, nil, nil)
				if ok {
					testing.expectf(t, err == nil && bytes.equal(output[:], data), "%v, buffer %v: %v, %v bytes", codec, size, err, len(output))
				} else {
					testing.expectf(t, err == compress.General_Error.Incompatible_Options, "%v, buffer %v: %v", codec, size, err)
				}
			}
			testing.expect_value(t, len(buffer), size)
		}

		{
			input := packed[:]
			ctx := compress.init_context(&input)
			buffer := make([]byte, 1 << 20)
			defer delete(buffer)
			switch codec {
			case .BZip2:
				r: bzip2.Reader
				testing.expect_value(t, bzip2.reader_init(&r, &ctx, options = {buffer = buffer}), nil)
				testing.expect_value(t, raw_data(r.window), raw_data(buffer))
				bzip2.reader_destroy(&r)
			case .LZ4:
				r: lz4.Frame_Reader
				testing.expect_value(t, lz4.frame_reader_init(&r, &ctx, options = {buffer = buffer}), nil)
				out: [10]byte
				lz4.frame_reader_read(&r, out[:])
				testing.expect_value(t, raw_data(r.window), raw_data(buffer))
				lz4.frame_reader_destroy(&r)
			}
		}

		for expected in ([]int{1, 1000, len(data) - 1, len(data), len(data) + 1}) {
			for kind in Stream_Kind {
				codec_sinks_check(t, "expected size", codec, kind, packed[:], expected)
			}
		}
		for limit in ([]int{1, 70_000, len(data) - 1, len(data)}) {
			codec_sinks_check(t, "max_output_size", codec, .Memory, packed[:], options = {max_output_size = limit})
			codec_sinks_check(t, "max_output_size", codec, .Bytes_Reader, packed[:], options = {max_output_size = limit, chunk_size = 5000})
		}
		codec_sinks_check(t, "expected over max_output_size", codec, .Memory, packed[:], 2 * len(data), {max_output_size = len(data)})

		for options in ([]compress.Options{{max_memory = -1}, {chunk_size = -1}, {max_output_size = -1}}) {
			output: [dynamic]byte
			defer delete(output)
			err, _, _ := codec_unpack(.Writer, codec, .Memory, packed[:], &output, -1, options, nil, nil)
			want := compress.Error(compress.General_Error.Incompatible_Options)
			if codec == .LZ4 && options.max_output_size < 0 {
				want = compress.General_Error.Output_Too_Short
			}
			testing.expectf(t, err == want, "%v, %v: %v", codec, options, err)
		}
	}

	lz4_packed: [dynamic]byte
	defer delete(lz4_packed)
	testing.expect_value(t, lz4.compress_frame(&lz4_packed, data, .Level_1, {block_max_size = .Max_64KiB}), nil)
	for memory in ([]int{64 * 1024, 128 * 1024 - 1, 128 * 1024, 300_000}) {
		output: [dynamic]byte
		defer delete(output)
		err, _, _ := codec_unpack(.Writer, .LZ4, .Memory, lz4_packed[:], &output, -1, {max_memory = memory}, nil, nil)
		if memory < 128 * 1024 {
			testing.expectf(t, err == compress.General_Error.Memory_Limit_Exceeded, "lz4, max_memory %v: %v", memory, err)
		} else {
			testing.expectf(t, err == nil && bytes.equal(output[:], data), "lz4, max_memory %v: %v, %v bytes", memory, err, len(output))
		}
	}

	bz_packed: [dynamic]byte
	defer delete(bz_packed)
	testing.expect_value(t, bzip2.compress(&bz_packed, data, .Level_1), nil)
	for memory in ([]int{400_000, 600_000, 1_200_000, 3_000_000}) {
		output: [dynamic]byte
		defer delete(output)
		err, _, _ := codec_unpack(.Writer, .BZip2, .Memory, bz_packed[:], &output, -1, {max_memory = memory, chunk_size = 4096}, nil, nil)
		if memory < 600_000 {
			testing.expectf(t, err == compress.General_Error.Memory_Limit_Exceeded, "bzip2, max_memory %v: %v", memory, err)
		} else {
			testing.expectf(t, err == nil && bytes.equal(output[:], data), "bzip2, max_memory %v: %v, %v bytes", memory, err, len(output))
		}
	}
}

@(test)
codec_writer_errors :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	for codec in Codec {
		packed: [dynamic]byte
		defer delete(packed)
		codec_pack(codec, data, &packed)

		for fail_at in ([]int{0, 1, 100_000, len(data) - 1}) {
			input := packed[:]
			ctx := compress.init_context(&input)
			output: [dynamic]byte
			defer delete(output)
			aw := Append_Writer{out = &output, fail_at = fail_at}
			err: compress.Error
			switch codec {
			case .BZip2: err = bzip2.decompress_to_writer(append_writer(&aw), &ctx, options = {chunk_size = 4096})
			case .LZ4:   err = lz4.decompress_frame_to_writer(append_writer(&aw), &ctx, options = {chunk_size = 4096})
			}
			testing.expectf(t, err == io.Error.Short_Write, "%v, fail at %v: %v", codec, fail_at, err)
			testing.expectf(t, bytes.equal(output[:], data[:fail_at]), "%v, fail at %v: %v bytes written", codec, fail_at, len(output))
		}
	}
}

@(test)
codec_sinks_fuzz :: proc(t: ^testing.T) {
	when SLIM_TESTS {
		return
	}
	for _ in 0..<CODEC_SINKS_FUZZ {
		data: [dynamic]byte
		defer delete(data)
		d64_test_data(rand.int_max(4), rand.int_max(250_000), &data)
		codec := Codec(rand.int_max(len(Codec)))
		packed: [dynamic]byte
		defer delete(packed)
		switch codec {
		case .BZip2:
			testing.expect_value(t, bzip2.compress(&packed, data[:], bzip2.Level(1 + rand.int_max(9))), nil)
		case .LZ4:
			options := lz4.Frame_Options{block_max_size = lz4.Block_Max_Size(rand.int_max(4))}
			for flag in lz4.Frame_Flag {
				if rand.int_max(2) == 0 {
					options.flags += {flag}
				}
			}
			testing.expect_value(t, lz4.compress_frame(&packed, data[:], lz4.Level(1 + rand.int_max(12)), options), nil)
		}
		if rand.int_max(3) == 0 {
			second: [dynamic]byte
			defer delete(second)
			codec_pack(codec, data[:len(data) / 3], &second)
			append(&packed, ..second[:])
		}
		kind := Stream_Kind(rand.int_max(len(Stream_Kind)))
		if kind == .One_Byte_No_Seek && len(packed) > 20_000 {
			kind = .Bytes_Reader
		}
		codec_sinks_check(t, "fuzz", codec, kind, packed[:])

		for _ in 0..<4 {
			mutated: [dynamic]byte
			defer delete(mutated)
			append(&mutated, ..packed[:])
			d64_mutate(&mutated)
			expected := -1
			if rand.int_max(4) == 0 {
				expected = rand.int_max(len(data) + 2)
			}
			codec_sinks_check(t, "fuzz mutated", codec, kind, mutated[:], expected, {max_output_size = 64 << 20})
		}
		free_all(context.temp_allocator)
	}
}

codec_pack :: proc(codec: Codec, input: []byte, output: ^[dynamic]byte) {
	switch codec {
	case .BZip2: bzip2.compress(output, input, .Level_1)
	case .LZ4:   lz4.compress_frame(output, input, .Level_1, {block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS})
	}
}

codec_bzip2_randomised :: proc(size: int) -> [dynamic]u8 {
	data := make([]u8, size)
	defer delete(data)
	x := u32(11)
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
	packed: [dynamic]u8
	bzip2.compress(&packed, masked, .Level_1)
	crc := bz_crc(data)
	bz_set_bits(packed[:], 80, 32, crc)
	bz_set_bits(packed[:], 112, 1, 1)
	end := bz_find_end(packed[:])
	bz_set_bits(packed[:], end + 48, 32, crc)
	return packed
}

codec_memory_unpack :: proc(codec: Codec, kind: Stream_Kind, input: []byte, output: ^[dynamic]byte, expected: int, options: compress.Options, dictionary: []byte, rest: ^[5]byte) -> (err: compress.Error, rest_err: io.Error) {
	input := input
	br: bytes.Reader
	tr: Trickle_Reader
	ctx := stream_test_context(kind, &input, &br, &tr, output)
	defer compress.destroy_context(&ctx)
	switch codec {
	case .BZip2: err = bzip2.decompress(&ctx, expected, options)
	case .LZ4:   err = lz4.decompress_frame(&ctx, expected, options, dictionary)
	}
	if err == nil && rest != nil {
		rest_err = compress.read_slice(&ctx, rest[:])
	}
	return
}

codec_unpack :: proc(sink: Sink, codec: Codec, kind: Stream_Kind, input: []byte, output: ^[dynamic]byte, expected: int, options: compress.Options, dictionary: []byte, rest: ^[5]byte) -> (err: compress.Error, rest_err: io.Error, bytes_written: i64) {
	input := input
	br: bytes.Reader
	tr: Trickle_Reader
	ctx := stream_test_context(kind, &input, &br, &tr)
	defer compress.destroy_context(&ctx)

	switch sink {
	case .Writer:
		aw := Append_Writer{out = output, fail_at = -1}
		w  := append_writer(&aw)
		switch codec {
		case .BZip2: err = bzip2.decompress_to_writer(w, &ctx, expected, options)
		case .LZ4:   err = lz4.decompress_frame_to_writer(w, &ctx, expected, options, dictionary)
		}

	case .Reader, .Reader_Stream:
		buffer := make([]byte, 70_000)
		defer delete(buffer)
		stream: io.Stream
		reader_err: ^compress.Error
		bz := new(bzip2.Reader)
		defer free(bz)
		lr := new(lz4.Frame_Reader)
		defer free(lr)
		switch codec {
		case .BZip2:
			err        = bzip2.reader_init(bz, &ctx, expected, options)
			stream     = bzip2.reader_to_stream(bz)
			reader_err = &bz.err
		case .LZ4:
			err        = lz4.frame_reader_init(lr, &ctx, expected, options, dictionary)
			stream     = lz4.frame_reader_to_stream(lr)
			reader_err = &lr.err
		}
		for err == nil {
			size := 1 + rand.int_max(16 if rand.int_max(2) == 0 else len(buffer))
			n: int
			if sink == .Reader {
				switch codec {
				case .BZip2: n, err = bzip2.reader_read(bz, buffer[:size])
				case .LZ4:   n, err = lz4.frame_reader_read(lr, buffer[:size])
				}
			} else {
				io_err: io.Error
				n, io_err = io.read(stream, buffer[:size])
				err = io_err if io_err == .EOF || io_err == nil else reader_err^
			}
			append(output, ..buffer[:n])
		}
		if err == io.Error.EOF {
			err = nil
		}
		switch codec {
		case .BZip2: bzip2.reader_destroy(bz)
		case .LZ4:   lz4.frame_reader_destroy(lr)
		}
	}
	bytes_written = ctx.bytes_written
	if err == nil && rest != nil {
		rest_err = compress.read_slice(&ctx, rest[:])
	}
	return
}

codec_sinks_check :: proc(t: ^testing.T, label: string, codec: Codec, kind: Stream_Kind, input: []byte, expected := -1, options := compress.Options{}, dictionary: []byte = nil) -> (memory_err: compress.Error) {
	want: [dynamic]byte
	defer delete(want)
	want_rest: [5]byte
	want_rest_err: io.Error
	memory_err, want_rest_err = codec_memory_unpack(codec, kind, input, &want, expected, options, dictionary, &want_rest)

	for sink in Sink {
		opts := options
		if opts.chunk_size == 0 && opts.buffer == nil {
			opts.chunk_size = sinks_chunk(len(want))
		}
		got: [dynamic]byte
		defer delete(got)
		rest: [5]byte
		err, rest_err, bytes_written := codec_unpack(sink, codec, kind, input, &got, expected, opts, dictionary, &rest)
		testing.expectf(t, err == memory_err, "%v, %v, %v, %v, chunk %v: %v, memory gave %v", label, codec, kind, sink, opts.chunk_size, err, memory_err)
		testing.expectf(t, bytes.equal(got[:], want[:]), "%v, %v, %v, %v, chunk %v: output differs, %v vs %v bytes (%v)", label, codec, kind, sink, opts.chunk_size, len(got), len(want), err)
		testing.expectf(t, bytes_written == i64(len(got)), "%v, %v, %v, %v, chunk %v: bytes_written %v for %v bytes", label, codec, kind, sink, opts.chunk_size, bytes_written, len(got))
		if err == nil {
			testing.expectf(t, rest == want_rest && rest_err == want_rest_err, "%v, %v, %v, %v, chunk %v: input after the stream %v, %v vs %v, %v", label, codec, kind, sink, opts.chunk_size, rest, rest_err, want_rest, want_rest_err)
		}
	}
	return
}
