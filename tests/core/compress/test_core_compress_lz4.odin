package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/lz4"
import "core:hash/xxhash"
import "core:testing"

LZ4_TEST_TRAILER :: [5]byte{'O', 'd', 'i', 'n', '!'}

LZ4_VECTOR_B4_LINKED   :: #load("lz4_vector_b4_linked.bin")
LZ4_VECTOR_B4_CHECKSUM :: #load("lz4_vector_b4_checksum.bin")
LZ4_VECTOR_B4_NOCRC    :: #load("lz4_vector_b4_nocrc.bin")
LZ4_VECTOR_B5          :: #load("lz4_vector_b5.bin")
LZ4_VECTOR_B6          :: #load("lz4_vector_b6.bin")
LZ4_VECTOR_B7_HC       :: #load("lz4_vector_b7_hc.bin")
LZ4_VECTOR_LEGACY      :: #load("lz4_vector_legacy.bin")
LZ4_VECTOR_STORED      :: #load("lz4_vector_stored.bin")
LZ4_VECTOR_DICT        :: #load("lz4_vector_dict.bin")
LZ4_VECTOR_EMPTY       :: #load("lz4_vector_empty.bin")

Lz4_Test_Lcg :: struct {
	state: u64,
}

lz4_test_lcg_next :: proc(g: ^Lz4_Test_Lcg) -> u32 {
	g.state = g.state * 6364136223846793005 + 1442695040888963407
	return u32(g.state >> 32)
}

lz4_test_lcg_text :: proc(g: ^Lz4_Test_Lcg, size: int) -> []byte {
	words := [?]string{"odin ", "block ", "frame ", "match ", "literal ", "token ", "offset ", "window\n"}
	data := make([]byte, size)
	i := 0
	for i < size {
		w := words[lz4_test_lcg_next(g) % len(words)]
		for c in transmute([]byte)w {
			if i == size {
				break
			}
			data[i] = c
			i += 1
		}
	}
	return data
}

lz4_test_lcg_bytes :: proc(g: ^Lz4_Test_Lcg, size: int) -> []byte {
	data := make([]byte, size)
	for &b in data {
		b = u8(lz4_test_lcg_next(g) >> 24)
	}
	return data
}

lz4_test_lcg_repeat :: proc(g: ^Lz4_Test_Lcg, size: int) -> []byte {
	chunk := lz4_test_lcg_bytes(g, 1000)
	defer delete(chunk)
	data := make([]byte, size)
	for i := 0; i < size; i += 1000 {
		n := copy(data[i:], chunk)
		for _ in 0..<3 {
			data[i + int(lz4_test_lcg_next(g) % u32(n))] = u8(lz4_test_lcg_next(g))
		}
	}
	return data
}

Lz4_Test_Inputs :: struct {
	repeat:     []byte,
	text:       []byte,
	random:     []byte,
	dictionary: []byte,
}

lz4_test_inputs :: proc() -> (inputs: Lz4_Test_Inputs) {
	g := Lz4_Test_Lcg{state = 0x4c5a34}
	inputs.repeat     = lz4_test_lcg_repeat(&g, 70_000)
	inputs.text       = lz4_test_lcg_text(&g, 1500)
	inputs.random     = lz4_test_lcg_bytes(&g, 300)
	inputs.dictionary = lz4_test_lcg_text(&g, 3000)
	return
}

lz4_test_inputs_destroy :: proc(inputs: Lz4_Test_Inputs) {
	delete(inputs.repeat)
	delete(inputs.text)
	delete(inputs.random)
	delete(inputs.dictionary)
}

lz4_test_unpack_frame :: proc(t: ^testing.T, name: string, packed: []byte, want: []byte, dictionary: []byte = nil, trailer := true) {
	data: [dynamic]byte
	defer delete(data)
	append(&data, ..packed)
	if trailer {
		tail := LZ4_TEST_TRAILER
		append(&data, ..tail[:])
	}

	for kind in Stream_Kind {
		input := data[:]
		br: bytes.Reader
		tr: Trickle_Reader
		output: [dynamic]byte
		defer delete(output)
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		defer compress.destroy_context(&ctx)

		err := lz4.decompress_frame(&ctx, dictionary = dictionary)
		testing.expectf(t, err == nil, "%v, %v: decompress_frame returned %v", name, kind, err)
		testing.expectf(t, bytes.equal(output[:], want), "%v, %v: output differs (%v vs %v bytes)", name, kind, len(output), len(want))

		if trailer {
			rest: [5]byte
			rest_err := compress.read_slice(&ctx, rest[:])
			testing.expectf(t, rest_err == nil && rest == LZ4_TEST_TRAILER, "%v, %v: bytes after the frame were %v, %v", name, kind, rest, rest_err)
		}
	}
}

@(test)
compress_lz4_frame_vectors :: proc(t: ^testing.T) {
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	lz4_test_unpack_frame(t, "B4 linked", LZ4_VECTOR_B4_LINKED, inputs.repeat)
	lz4_test_unpack_frame(t, "B4 checksum", LZ4_VECTOR_B4_CHECKSUM, inputs.repeat)
	lz4_test_unpack_frame(t, "B4 no frame crc", LZ4_VECTOR_B4_NOCRC, inputs.repeat)
	lz4_test_unpack_frame(t, "B5", LZ4_VECTOR_B5, inputs.text)
	lz4_test_unpack_frame(t, "B6", LZ4_VECTOR_B6, inputs.text)
	lz4_test_unpack_frame(t, "B7 HC", LZ4_VECTOR_B7_HC, inputs.text)
	lz4_test_unpack_frame(t, "stored", LZ4_VECTOR_STORED, inputs.random)
	lz4_test_unpack_frame(t, "empty", LZ4_VECTOR_EMPTY, nil)
	lz4_test_unpack_frame(t, "dictionary", LZ4_VECTOR_DICT, inputs.text, inputs.dictionary)
	lz4_test_unpack_frame(t, "legacy", LZ4_VECTOR_LEGACY, inputs.repeat, trailer = false)
}

@(test)
compress_lz4_concatenated_frames :: proc(t: ^testing.T) {
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	skippable := [?]byte{0x5a, 0x2a, 0x4d, 0x18, 3, 0, 0, 0, 'x', 'y', 'z'}

	packed: [dynamic]byte
	defer delete(packed)
	append(&packed, ..LZ4_VECTOR_B5)
	append(&packed, ..skippable[:])
	append(&packed, ..LZ4_VECTOR_EMPTY)
	append(&packed, ..LZ4_VECTOR_B4_LINKED)
	append(&packed, ..LZ4_VECTOR_LEGACY)
	append(&packed, ..LZ4_VECTOR_STORED)

	want: [dynamic]byte
	defer delete(want)
	append(&want, ..inputs.text)
	append(&want, ..inputs.repeat)
	append(&want, ..inputs.repeat)
	append(&want, ..inputs.random)

	lz4_test_unpack_frame(t, "concatenated", packed[:], want[:])

	only_skippable: [dynamic]byte
	defer delete(only_skippable)
	append(&only_skippable, ..skippable[:])
	lz4_test_unpack_frame(t, "skippable only", only_skippable[:], nil)
}

@(test)
compress_lz4_block_vectors :: proc(t: ^testing.T) {
	Vector :: struct {
		block: []byte,
		want:  string,
	}
	for v in ([]Vector{
		{{0x00}, ""},
		{{0x50, 'h', 'e', 'l', 'l', 'o'}, "hello"},
		{{0x1f, 'a', 1, 0, 1, 0x50, 'b', 'c', 'd', 'e', 'f'}, "aaaaaaaaaaaaaaaaaaaaabcdef"},
		{{0x10, 'a', 1, 0, 0x00}, "aaaaa"},
		{{0x30, 'a', 'b', 'c', 3, 0, 0x10, 'x'}, "abcabcax"},
		{{0xf0, 0x00, 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o'}, "abcdefghijklmno"},
	}) {
		output: [dynamic]byte
		defer delete(output)
		err := lz4.decompress_block(&output, v.block, len(v.want))
		testing.expectf(t, err == nil, "%v: decompress_block returned %v", v.block, err)
		testing.expectf(t, string(output[:]) == v.want, "%v: got %q, want %q", v.block, string(output[:]), v.want)
	}
}

@(test)
compress_lz4_block_errors :: proc(t: ^testing.T) {
	Vector :: struct {
		block:    []byte,
		capacity: int,
		want:     compress.Error,
	}
	for v in ([]Vector{
		{{0x10, 'a', 0, 0, 0x00}, 64, lz4.LZ4_Error.Invalid_Offset},
		{{0x10, 'a', 2, 0, 0x00}, 64, lz4.LZ4_Error.Offset_Out_Of_Range},
		{{0x50, 'a', 'b'}, 64, lz4.LZ4_Error.Literal_Overrun},
		{{0xf0}, 64, compress.General_Error.Stream_Too_Short},
		{{0x50, 'h', 'e', 'l', 'l', 'o'}, 4, compress.General_Error.Output_Too_Short},
		{{0x1f, 'a', 1, 0, 1, 0x00}, 10, compress.General_Error.Output_Too_Short},
		{{0x10}, 64, lz4.LZ4_Error.Literal_Overrun},
		{{0x10, 'a', 1}, 64, compress.General_Error.Stream_Too_Short},
		{{0x1f, 'a', 1, 0}, 64, compress.General_Error.Stream_Too_Short},
		{{}, 64, compress.General_Error.Stream_Too_Short},
	}) {
		output := make([]byte, v.capacity)
		defer delete(output)
		_, err := lz4.decompress_block_to_slice(output, v.block)
		testing.expectf(t, err == v.want, "%v: decompress_block_to_slice returned %v, want %v", v.block, err, v.want)
	}
}

@(test)
compress_lz4_block_round_trip :: proc(t: ^testing.T) {
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	s := new(lz4.LZ4)
	defer free(s)

	short := []byte{'a', 'b', 'c', 'd', 'a', 'b', 'c', 'd', 'a', 'b', 'c', 'd', 'a'}
	Case :: struct {
		name: string,
		data: []byte,
	}
	for c in ([]Case{{"empty", nil}, {"one", short[:1]}, {"twelve", short[:12]}, {"thirteen", short}, {"text", inputs.text}, {"random", inputs.random}, {"repeat", inputs.repeat}}) {
		for level in lz4.Level.Level_1..=lz4.Level.Level_12 {
			packed := make([]byte, lz4.compress_block_bound(len(c.data)))
			defer delete(packed)
			n, err := lz4.compress_block(s, packed, c.data, level)
			testing.expectf(t, err == nil, "%v, %v: compress_block returned %v", c.name, level, err)

			dynamic_packed: [dynamic]byte
			defer delete(dynamic_packed)
			dynamic_err := lz4.compress_block(&dynamic_packed, c.data, level)
			testing.expectf(t, dynamic_err == nil && bytes.equal(dynamic_packed[:], packed[:n]), "%v, %v: compress_block_to_dynamic differs (%v)", c.name, level, dynamic_err)

			output := make([]byte, len(c.data))
			defer delete(output)
			w, unpack_err := lz4.decompress_block_to_slice(output, packed[:n])
			testing.expectf(t, unpack_err == nil && w == len(c.data) && bytes.equal(output, c.data), "%v, %v: round trip failed (%v)", c.name, level, unpack_err)

			for kind in Stream_Kind {
				input := packed[:n]
				br: bytes.Reader
				tr: Trickle_Reader
				unpacked: [dynamic]byte
				defer delete(unpacked)
				ctx := stream_test_context(kind, &input, &br, &tr, &unpacked)
				defer compress.destroy_context(&ctx)
				ctx_err := lz4.decompress_block(&ctx, len(c.data))
				testing.expectf(t, ctx_err == nil && bytes.equal(unpacked[:], c.data), "%v, %v, %v: context round trip failed (%v)", c.name, level, kind, ctx_err)
			}
		}
	}
}

@(test)
compress_lz4_block_output_too_short :: proc(t: ^testing.T) {
	s := new(lz4.LZ4)
	defer free(s)
	input  := transmute([]byte)context_test_data
	output := make([]byte, lz4.compress_block_bound(len(input)) - 1)
	defer delete(output)

	_, err := lz4.compress_block(s, output, input)
	testing.expect_value(t, err, compress.Error(compress.General_Error.Output_Too_Short))
}

@(test)
compress_lz4_frame_round_trip :: proc(t: ^testing.T) {
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	data: [dynamic]byte
	defer delete(data)
	for len(data) < 200_000 {
		append(&data, ..inputs.repeat)
		append(&data, ..inputs.text)
	}

	for options in ([]lz4.Frame_Options{
		{flags = lz4.DEFAULT_FRAME_FLAGS},
		{block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS},
		{block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS + {.Independent_Blocks, .Block_Checksum}},
		{block_max_size = .Max_256KiB},
		{block_max_size = .Max_1MiB, flags = lz4.DEFAULT_FRAME_FLAGS + {.Block_Checksum}, dictionary_id = 0},
	}) {
		for level in ([]lz4.Level{.Level_1, .Level_2, .Level_5, .Level_10}) {
			for input in ([][]byte{nil, inputs.random, data[:]}) {
				packed: [dynamic]byte
				defer delete(packed)
				err := lz4.compress_frame(&packed, input, level, options)
				testing.expectf(t, err == nil, "%v, %v: compress_frame returned %v", options, level, err)
				if err != nil {
					continue
				}
				if _, has_id := options.dictionary_id.?; has_id {
					output: [dynamic]byte
					defer delete(output)
					testing.expect_value(t, lz4.decompress_frame(&output, packed[:]), compress.Error(lz4.LZ4_Error.Dictionary_Required))
					lz4_test_unpack_frame(t, "frame", packed[:], input, []byte{0})
				} else {
					lz4_test_unpack_frame(t, "frame", packed[:], input)
				}
			}
		}
	}
}

@(test)
compress_lz4_dictionary_round_trip :: proc(t: ^testing.T) {
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	s := new(lz4.LZ4)
	defer free(s)

	for level in lz4.Level.Level_1..=lz4.Level.Level_12 {
		plain  := make([]byte, lz4.compress_block_bound(len(inputs.text)))
		packed := make([]byte, lz4.compress_block_bound(len(inputs.text)))
		defer delete(plain)
		defer delete(packed)
		plain_n, _ := lz4.compress_block(s, plain, inputs.text, level)
		n, err := lz4.compress_block(s, packed, inputs.text, level, inputs.dictionary)
		testing.expectf(t, err == nil, "%v: compress_block with dictionary returned %v", level, err)
		testing.expectf(t, n < plain_n, "%v: dictionary did not help (%v vs %v)", level, n, plain_n)

		output := make([]byte, len(inputs.text))
		defer delete(output)
		w, unpack_err := lz4.decompress_block_to_slice(output, packed[:n], inputs.dictionary)
		testing.expectf(t, unpack_err == nil && w == len(output) && bytes.equal(output, inputs.text), "%v: dictionary round trip failed (%v)", level, unpack_err)

		_, missing_err := lz4.decompress_block_to_slice(output, packed[:n])
		testing.expectf(t, missing_err == lz4.LZ4_Error.Offset_Out_Of_Range, "%v: decoding without the dictionary returned %v", level, missing_err)
	}

	data: [dynamic]byte
	defer delete(data)
	for len(data) < 150_000 {
		append(&data, ..inputs.text)
		append(&data, ..inputs.random)
	}
	for independent in ([]bool{false, true}) {
		for level in ([]lz4.Level{.Level_1, .Level_4, .Level_11}) {
			packed: [dynamic]byte
			defer delete(packed)
			options := lz4.Frame_Options{block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS + ({.Independent_Blocks} if independent else {}), dictionary_id = 0x12345678}
			err := lz4.compress_frame(&packed, data[:], level, options, inputs.dictionary)
			testing.expectf(t, err == nil, "%v, %v: compress_frame with dictionary returned %v", independent, level, err)
			lz4_test_unpack_frame(t, "dictionary frame", packed[:], data[:], inputs.dictionary)
		}
	}
}

@(test)
compress_lz4_frame_errors :: proc(t: ^testing.T) {
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	Corruption :: struct {
		offset: int,
		value:  u8,
		want:   compress.Error,
	}
	frame   := LZ4_VECTOR_B5
	corrupt := make([]byte, len(frame))
	defer delete(corrupt)
	for c in ([]Corruption{
		{0, 0x05, lz4.LZ4_Error.Invalid_Magic},
		{4, 0x24, lz4.LZ4_Error.Unsupported_Version},
		{4, 0x66, lz4.LZ4_Error.Reserved_Bit_Set},
		{5, 0x30, lz4.LZ4_Error.Invalid_Block_Max_Size},
		{5, 0x51, lz4.LZ4_Error.Reserved_Bit_Set},
		{6, 0x00, lz4.LZ4_Error.Header_Checksum_Failed},
		{len(frame) - 1, 0x00, lz4.LZ4_Error.Content_Checksum_Failed},
	}) {
		copy(corrupt, frame)
		corrupt[c.offset] = c.value
		output: [dynamic]byte
		defer delete(output)
		err := lz4.decompress_frame(&output, corrupt)
		testing.expectf(t, err == c.want, "corrupt byte %v: decompress_frame returned %v, want %v", c.offset, err, c.want)
	}

	checksummed := bytes.clone(LZ4_VECTOR_B4_CHECKSUM)
	defer delete(checksummed)
	checksummed[len(checksummed) - 12] ~= 0x01
	output: [dynamic]byte
	defer delete(output)
	testing.expect_value(t, lz4.decompress_frame(&output, checksummed), compress.Error(lz4.LZ4_Error.Block_Checksum_Failed))

	s := new(lz4.LZ4)
	defer free(s)
	sized := make([]byte, lz4.compress_frame_bound(len(inputs.text)))
	defer delete(sized)
	n, _ := lz4.compress_frame(s, sized, inputs.text)
	sized[6] += 1
	sized[14] = u8(xxhash.XXH32(sized[4:14]) >> 8)
	clear(&output)
	testing.expect_value(t, lz4.decompress_frame(&output, sized[:n]), compress.Error(lz4.LZ4_Error.Content_Size_Mismatch))

	oversized := []byte{0x04, 0x22, 0x4d, 0x18, 0x40, 0x40, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00}
	oversized[6] = u8(xxhash.XXH32(oversized[4:6]) >> 8)
	clear(&output)
	testing.expect_value(t, lz4.decompress_frame(&output, oversized), compress.Error(lz4.LZ4_Error.Block_Too_Large))
}

@(test)
compress_lz4_frame_truncation :: proc(t: ^testing.T) {
	b4_checksum := LZ4_VECTOR_B4_CHECKSUM
	for frame in ([][]byte{LZ4_VECTOR_B5, LZ4_VECTOR_STORED, LZ4_VECTOR_EMPTY, b4_checksum[:200]}) {
		for cut in 0..<len(frame) {
			output: [dynamic]byte
			defer delete(output)
			err := lz4.decompress_frame(&output, frame[:cut])
			testing.expectf(t, err != nil, "frame of %v bytes cut at %v: decompress_frame succeeded", len(frame), cut)
		}
	}
}

@(test)
compress_lz4_frame_bit_flips :: proc(t: ^testing.T) {
	inputs := lz4_test_inputs()
	defer lz4_test_inputs_destroy(inputs)

	frame   := LZ4_VECTOR_B5
	corrupt := make([]byte, len(frame))
	defer delete(corrupt)
	for i in 0..<len(frame) {
		for bit in 0..<8 {
			copy(corrupt, frame)
			corrupt[i] ~= 1 << uint(bit)
			output: [dynamic]byte
			defer delete(output)
			err := lz4.decompress_frame(&output, corrupt)
			testing.expectf(t, err != nil || bytes.equal(output[:], inputs.text), "flipped bit %v of byte %v: decompress_frame returned wrong output", bit, i)
		}
	}
}
