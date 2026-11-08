package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/lzma"
import "core:hash"
import "core:math/rand"
import "core:testing"

LZMA_TEST_TRAILER :: [5]byte{'O', 'd', 'i', 'n', '!'}

LZMA_VECTOR_XZ           :: #load("lzma_vector_xz.lzma")
LZMA_VECTOR_SDK          :: #load("lzma_vector_sdk.lzma")
LZMA_VECTOR_EMPTY        :: #load("lzma_vector_empty.lzma")
LZMA_VECTOR_RAW_LC0LP2   :: #load("lzma_vector_raw_lc0lp2pb0.bin")
LZMA_VECTOR_LZMA2        :: #load("lzma_vector_lzma2.bin")
LZMA_VECTOR_LZMA2_CHUNKS :: #load("lzma_vector_lzma2_chunks.bin")

Lzma_Test_Inputs :: struct {
	text:   []byte,
	random: []byte,
	repeat: []byte,
	mixed:  []byte,
	chunks: []byte,
}

lzma_test_inputs :: proc() -> (inputs: Lzma_Test_Inputs) {
	g := Lz4_Test_Lcg{state = 0x4c5a4d41}
	inputs.text   = lz4_test_lcg_text(&g, 20_000)
	inputs.random = lz4_test_lcg_bytes(&g, 4096)
	inputs.repeat = lz4_test_lcg_repeat(&g, 70_000)

	mixed: [dynamic]byte
	append(&mixed, ..inputs.text)
	append(&mixed, ..inputs.random)
	append(&mixed, ..inputs.repeat)
	inputs.mixed = mixed[:]

	chunks: [dynamic]byte
	append(&chunks, ..inputs.random[:300])
	append(&chunks, ..inputs.text)
	append(&chunks, ..inputs.random[300:600])
	append(&chunks, ..inputs.text)
	inputs.chunks = chunks[:]
	return
}

lzma_test_inputs_destroy :: proc(inputs: Lzma_Test_Inputs) {
	delete(inputs.text)
	delete(inputs.random)
	delete(inputs.repeat)
	delete(inputs.mixed)
	delete(inputs.chunks)
}

Lzma_Test_Format :: enum {
	Lzma,
	Raw,
	Lzma2,
}

lzma_test_decode :: proc(ctx: ^compress.Context, format: Lzma_Test_Format, props: lzma.Properties, expected := -1, max_output := compress.COMPRESS_OUTPUT_ALLOCATE_MAX) -> lzma.Error {
	switch format {
	case .Lzma:  return lzma.decompress(ctx, expected, max_output)
	case .Raw:   return lzma.decompress_raw(ctx, props, expected, max_output)
	case .Lzma2: return lzma.decompress_lzma2(ctx, props.dict_size, expected, max_output)
	}
	return nil
}

lzma_test_decode_bytes :: proc(output: ^[dynamic]byte, input: []byte, format: Lzma_Test_Format, props: lzma.Properties, expected := -1, max_output := compress.COMPRESS_OUTPUT_ALLOCATE_MAX) -> lzma.Error {
	switch format {
	case .Lzma:  return lzma.decompress(output, input, expected, max_output)
	case .Raw:   return lzma.decompress_raw(output, input, props, expected, max_output)
	case .Lzma2: return lzma.decompress_lzma2(output, input, props.dict_size, expected, max_output)
	}
	return nil
}

lzma_test_unpack :: proc(t: ^testing.T, name: string, packed: []byte, want: []byte, format: Lzma_Test_Format, props := lzma.Properties{}) {
	data: [dynamic]byte
	defer delete(data)
	append(&data, ..packed)
	tail := LZMA_TEST_TRAILER
	append(&data, ..tail[:])

	for i in 0..=len(Stream_Kind) {
		input := data[:]
		br: bytes.Reader
		tr: Trickle_Reader
		output: [dynamic]byte
		defer delete(output)
		ctx: compress.Context
		if i < len(Stream_Kind) {
			ctx = stream_test_context(Stream_Kind(i), &input, &br, &tr, &output)
		} else {
			tr = {data = input, chunk = 1 + rand.int_max(8192), seekable = rand.int_max(2) == 0}
			ctx = compress.init_context(trickle_stream(&tr), &output)
		}
		defer compress.destroy_context(&ctx)

		err := lzma_test_decode(&ctx, format, props)
		testing.expectf(t, err == nil, "%v, kind %v, chunk %v: decompress returned %v", name, i, tr.chunk, err)
		testing.expectf(t, bytes.equal(output[:], want), "%v, kind %v, chunk %v: output differs (%v vs %v bytes)", name, i, tr.chunk, len(output), len(want))

		rest: [5]byte
		rest_err := compress.read_slice(&ctx, rest[:])
		testing.expectf(t, rest_err == nil && rest == LZMA_TEST_TRAILER, "%v, kind %v, chunk %v: bytes after the stream were %v, %v", name, i, tr.chunk, rest, rest_err)
	}
}

@(test)
lzma_vectors :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)

	lzma_test_unpack(t, "xz .lzma", LZMA_VECTOR_XZ, inputs.repeat, .Lzma)
	lzma_test_unpack(t, "sdk .lzma", LZMA_VECTOR_SDK, inputs.text, .Lzma)
	lzma_test_unpack(t, "empty .lzma", LZMA_VECTOR_EMPTY, nil, .Lzma)
	lzma_test_unpack(t, "raw lc0 lp2 pb0", LZMA_VECTOR_RAW_LC0LP2, inputs.text, .Raw, {lc = 0, lp = 2, pb = 0, dict_size = 8 << 20})
	lzma_test_unpack(t, "lzma2", LZMA_VECTOR_LZMA2, inputs.mixed, .Lzma2, {dict_size = 64 << 10})
	lzma_test_unpack(t, "lzma2 chunks", LZMA_VECTOR_LZMA2_CHUNKS, inputs.chunks, .Lzma2, {dict_size = 64 << 10})
	lzma_test_unpack(t, "lzma2 empty", {0}, nil, .Lzma2, {dict_size = 64 << 10})
	lzma_test_unpack(t, "lzma2 4 GiB dict", LZMA_VECTOR_LZMA2, inputs.mixed, .Lzma2, {dict_size = max(u32)})
	lzma_test_unpack(t, "raw 3 GiB dict", LZMA_VECTOR_RAW_LC0LP2, inputs.text, .Raw, {lc = 0, lp = 2, pb = 0, dict_size = 3 << 30})

	sdk     := LZMA_VECTOR_SDK
	sdk_raw := sdk[lzma.HEADER_SIZE:]
	props, props_err := lzma.decode_properties(sdk)
	testing.expect_value(t, props_err, nil)
	output: [dynamic]byte
	defer delete(output)
	testing.expect_value(t, lzma.decompress_raw(&output, sdk_raw, props, len(inputs.text)), nil)
	testing.expect(t, bytes.equal(output[:], inputs.text))

	testing.expect_value(t, lzma.decompress(&output, LZMA_VECTOR_XZ, len(inputs.repeat)), nil)
	testing.expect(t, bytes.equal(output[:], inputs.repeat))
}

@(test)
lzma_truncated :: proc(t: ^testing.T) {
	Case :: struct {
		name:   string,
		packed: []byte,
		format: Lzma_Test_Format,
		props:  lzma.Properties,
	}
	cases := [?]Case{
		{"xz .lzma",        LZMA_VECTOR_XZ,           .Lzma,  {}},
		{"sdk .lzma",       LZMA_VECTOR_SDK,          .Lzma,  {}},
		{"empty .lzma",     LZMA_VECTOR_EMPTY,        .Lzma,  {}},
		{"raw lc0 lp2 pb0", LZMA_VECTOR_RAW_LC0LP2,   .Raw,   {lc = 0, lp = 2, pb = 0, dict_size = 8 << 20}},
		{"lzma2 chunks",    LZMA_VECTOR_LZMA2_CHUNKS, .Lzma2, {dict_size = 64 << 10}},
	}
	for c in cases {
		for n in 0..<len(c.packed) {
			output: [dynamic]byte
			err := lzma_test_decode_bytes(&output, c.packed[:n], c.format, c.props)
			delete(output)
			testing.expectf(t, err != nil, "%v: %v of %v bytes decoded without error", c.name, n, len(c.packed))
		}
	}
}

@(test)
lzma_corrupt :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)

	Case :: struct {
		name:   string,
		packed: []byte,
		format: Lzma_Test_Format,
		props:  lzma.Properties,
		want:   []byte,
	}
	cases := [?]Case{
		{"sdk .lzma",    LZMA_VECTOR_SDK,          .Lzma,  {}, inputs.text},
		{"lzma2 chunks", LZMA_VECTOR_LZMA2_CHUNKS, .Lzma2, {dict_size = 64 << 10}, inputs.chunks},
	}
	for c in cases {
		data := make([]byte, len(c.packed))
		defer delete(data)
		limit := len(c.want) + 1000
		accepted := 0
		for i in 0..<len(c.packed) {
			for mask in ([]byte{0x01, 0x80, 0xff}) {
				copy(data, c.packed)
				data[i] ~= mask
				output: [dynamic]byte
				err := lzma_test_decode_bytes(&output, data, c.format, c.props, max_output = limit)
				testing.expectf(t, len(output) <= limit, "%v: flip %x at %v wrote %v bytes", c.name, mask, i, len(output))
				if err == nil {
					accepted += 1
				}
				delete(output)
			}
		}
		testing.expectf(t, accepted < len(c.packed), "%v: %v of %v corruptions accepted", c.name, accepted, 3 * len(c.packed))

		for _ in 0..<300 {
			mutated: [dynamic]byte
			defer delete(mutated)
			append(&mutated, ..c.packed)
			for _ in 0..<1 + rand.int_max(4) {
				n := len(mutated)
				if n == 0 {
					break
				}
				switch rand.int_max(4) {
				case 0:
					mutated[rand.int_max(n)] ~= 1 << uint(rand.int_max(8))
				case 1:
					mutated[rand.int_max(n)] = u8(rand.uint32())
				case 2:
					resize(&mutated, rand.int_max(n))
				case 3:
					resize(&mutated, rand.int_max(n))
					append(&mutated, ..c.packed[rand.int_max(len(c.packed)):])
				}
			}

			kind := Stream_Kind(1 + rand.int_max(len(Stream_Kind) - 1))
			outputs: [2][dynamic]byte
			errs: [2]lzma.Error
			for k in 0..<2 {
				input := mutated[:]
				br: bytes.Reader
				tr: Trickle_Reader
				ctx := stream_test_context(.Memory if k == 0 else kind, &input, &br, &tr, &outputs[k])
				errs[k] = lzma_test_decode(&ctx, c.format, c.props, max_output = limit)
				compress.destroy_context(&ctx)
				testing.expectf(t, len(outputs[k]) <= limit, "%v, %v: random corruption wrote %v bytes", c.name, kind, len(outputs[k]))
			}
			same := (errs[0] == nil) == (errs[1] == nil) && (errs[0] != nil || bytes.equal(outputs[0][:], outputs[1][:]))
			testing.expectf(t, same, "%v: random corruption, memory %v, %v %v", c.name, errs[0], kind, errs[1])
			delete(outputs[0])
			delete(outputs[1])
		}
	}
}

@(test)
lzma_limits :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)

	output: [dynamic]byte
	defer delete(output)

	testing.expect_value(t, lzma.decompress(&output, LZMA_VECTOR_SDK, max_output_size = len(inputs.text) - 1), compress.General_Error.Output_Too_Short)
	testing.expect_value(t, lzma.decompress(&output, LZMA_VECTOR_SDK, len(inputs.text) + 1), compress.LZMA_Error.Size_Mismatch)
	testing.expect_value(t, lzma.decompress(&output, LZMA_VECTOR_XZ, max_output_size = len(inputs.repeat) - 1), compress.General_Error.Output_Too_Short)
	testing.expect(t, len(output) <= len(inputs.repeat) - 1)
	testing.expect_value(t, lzma.decompress(&output, LZMA_VECTOR_XZ, len(inputs.repeat), len(inputs.repeat) - 1), compress.General_Error.Output_Too_Short)
	testing.expect(t, len(output) <= len(inputs.repeat) - 1)
	testing.expect_value(t, lzma.decompress(&output, LZMA_VECTOR_XZ, len(inputs.repeat) + 1), compress.LZMA_Error.Unexpected_End_Marker)
	testing.expect(t, lzma.decompress(&output, LZMA_VECTOR_XZ, len(inputs.repeat) - 1) != nil)
	testing.expect_value(t, lzma.decompress(&output, LZMA_VECTOR_XZ, max_output_size = len(inputs.repeat)), nil)
	testing.expect(t, bytes.equal(output[:], inputs.repeat))

	testing.expect_value(t, lzma.decompress_lzma2(&output, LZMA_VECTOR_LZMA2, 64 << 10, max_output_size = len(inputs.mixed) - 1), compress.General_Error.Output_Too_Short)
	testing.expect_value(t, lzma.decompress_lzma2(&output, LZMA_VECTOR_LZMA2, 64 << 10, len(inputs.mixed) + 1), compress.LZMA_Error.Size_Mismatch)
	testing.expect_value(t, lzma.decompress_lzma2(&output, LZMA_VECTOR_LZMA2, 64 << 10, len(inputs.mixed)), nil)
	testing.expect(t, bytes.equal(output[:], inputs.mixed))

	testing.expect_value(t, lzma.decompress(&output, LZMA_VECTOR_SDK, max_output_size = -1), compress.General_Error.Incompatible_Options)
	testing.expect_value(t, lzma.decompress((^[dynamic]byte)(nil), LZMA_VECTOR_SDK), compress.General_Error.Incompatible_Options)
}

@(test)
lzma_invalid :: proc(t: ^testing.T) {
	output: [dynamic]byte
	defer delete(output)

	header := [lzma.HEADER_SIZE + 5]byte{9 * 5 * 5, 0, 0, 1, 0, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0, 0}
	testing.expect_value(t, lzma.decompress(&output, header[:]), compress.LZMA_Error.Invalid_Properties)
	header[0] = 0x5d
	header[lzma.HEADER_SIZE] = 1
	testing.expect_value(t, lzma.decompress(&output, header[:]), compress.LZMA_Error.Corrupt_Range_Coder)
	testing.expect_value(t, lzma.decompress(&output, header[:lzma.HEADER_SIZE - 1]), compress.General_Error.Stream_Too_Short)
	testing.expect_value(t, lzma.decompress_raw(&output, header[lzma.HEADER_SIZE:], {lc = 9}), compress.LZMA_Error.Invalid_Properties)
	testing.expect_value(t, lzma.decompress_raw(&output, header[lzma.HEADER_SIZE:], {lp = 5}), compress.LZMA_Error.Invalid_Properties)
	testing.expect_value(t, lzma.decompress_raw(&output, header[lzma.HEADER_SIZE:], {pb = 5}), compress.LZMA_Error.Invalid_Properties)

	_, props_err := lzma.decode_properties(header[:4])
	testing.expect_value(t, props_err, compress.General_Error.Stream_Too_Short)
	_, dict_err := lzma.lzma2_dict_size(lzma.LZMA2_DICT_PROP_MAX + 1)
	testing.expect_value(t, dict_err, compress.LZMA_Error.Invalid_Properties)
	size, _ := lzma.lzma2_dict_size(lzma.LZMA2_DICT_PROP_MAX)
	testing.expect_value(t, size, max(u32))
	for prop in u8(0)..<lzma.LZMA2_DICT_PROP_MAX {
		size, _ = lzma.lzma2_dict_size(prop)
		testing.expect_value(t, lzma.lzma2_dict_prop(size), prop)
		testing.expect_value(t, lzma.lzma2_dict_prop(size - 1), prop)
	}

	props := lzma.Properties{lc = 1, lp = 3, pb = 4, dict_size = 1 << 20}
	encoded := lzma.encode_properties(props)
	decoded, _ := lzma.decode_properties(encoded[:])
	testing.expect_value(t, decoded, props)

	chunks := LZMA_VECTOR_LZMA2_CHUNKS
	testing.expect_value(t, lzma.decompress_lzma2(&output, {3, 0, 0, 0}, 1 << 20), compress.LZMA_Error.Invalid_Chunk)
	testing.expect_value(t, lzma.decompress_lzma2(&output, {2, 0, 0, 'x', 0}, 1 << 20), compress.LZMA_Error.Invalid_Chunk)
	testing.expect_value(t, lzma.decompress_lzma2(&output, {0x80, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0}, 1 << 20), compress.LZMA_Error.Invalid_Chunk)
	testing.expect_value(t, lzma.decompress_lzma2(&output, {0xe0, 0, 0, 0, 4, 9 * 5 * 5, 0, 0, 0, 0, 0, 0}, 1 << 20), compress.LZMA_Error.Invalid_Properties)
	testing.expect_value(t, lzma.decompress_lzma2(&output, {0xe0, 0, 0, 0, 4, 13, 0, 0, 0, 0, 0, 0}, 1 << 20), compress.LZMA_Error.Invalid_Properties)
	testing.expect_value(t, lzma.decompress_lzma2(&output, {0xe0, 0, 0, 0, 3, 0x00, 0, 0, 0, 0, 0}, 1 << 20), compress.LZMA_Error.Invalid_Chunk)
	testing.expect_value(t, lzma.decompress_lzma2(&output, {1, 0, 0, 'x', 0x80, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0}, 1 << 20), compress.LZMA_Error.Invalid_Chunk)
	testing.expect_value(t, lzma.decompress_lzma2(&output, {1, 0, 0, 'x'}, 1 << 20), compress.General_Error.Stream_Too_Short)
	testing.expect_value(t, lzma.decompress_lzma2(&output, {1, 0, 0, 'x', 2, 0, 0, 'y', 0}, 1 << 20), nil)
	testing.expect_value(t, string(output[:]), "xy")

	pieces := make([]byte, len(chunks))
	defer delete(pieces)
	copy(pieces, chunks)
	pieces[3 + 300] = 0x80 | (pieces[3 + 300] & 0x1f)
	testing.expect_value(t, lzma.decompress_lzma2(&output, pieces, 64 << 10), compress.LZMA_Error.Invalid_Chunk)
}

LZMA_Reference :: struct {
	name:       string,
	level:      lzma.Level,
	size:       int,
	crc:        u32,
	lzma2_size: int,
	lzma2_crc:  u32,
}

@(rodata)
LZMA_REFERENCES := []LZMA_Reference{
	{"text",   .Level_0, 3241, 0xd4c42903, 3235, 0x84235a1a},
	{"text",   .Level_1, 2984, 0x81ec898e, 2978, 0x222cc9be},
	{"text",   .Level_3, 2457, 0x18ea653c, 2451, 0xb9621026},
	{"text",   .Level_4, 2348, 0x23b24c61, 2342, 0xd48b15f1},
	{"text",   .Level_6, 2147, 0x85865b47, 2141, 0x916fe62f},
	{"text",   .Level_9, 2147, 0x85865b47, 2141, 0x916fe62f},
	{"random", .Level_0, 4176, 0xaf22c1b8, 4100, 0x28e65fd7},
	{"random", .Level_6, 4169, 0xe46cbb3d, 4100, 0x28e65fd7},
	{"repeat", .Level_0, 1819, 0xff6b0793, 1813, 0x7c4a6f2d},
	{"repeat", .Level_1, 1824, 0xaccb1d74, 1818, 0xad5163f1},
	{"repeat", .Level_3, 1795, 0xe37d892d, 1789, 0xaeb04a3d},
	{"repeat", .Level_4, 1778, 0xbf928da1, 1772, 0x5b229c29},
	{"repeat", .Level_6, 1759, 0x53af1b34, 1753, 0x238e27a6},
	{"mixed",  .Level_0, 9224, 0x6570d1fe, 9218, 0xa5a05dc9},
	{"mixed",  .Level_1, 8965, 0xba3178a2, 8959, 0xca22cf42},
	{"mixed",  .Level_3, 8401, 0x10a42580, 8395, 0xf2b1d81a},
	{"mixed",  .Level_4, 8255, 0xeb562178, 8249, 0x3cb5045e},
	{"mixed",  .Level_6, 8035, 0xe07a353e, 8029, 0x8441864e},
	{"mixed",  .Level_9, 8035, 0xe07a353e, 8029, 0x8441864e},
}

lzma_test_input_by_name :: proc(inputs: Lzma_Test_Inputs, name: string) -> []byte {
	switch name {
	case "text":   return inputs.text
	case "random": return inputs.random
	case "repeat": return inputs.repeat
	case "mixed":  return inputs.mixed
	}
	return nil
}

@(test)
lzma_compress_matches_reference :: proc(t: ^testing.T) {
	inputs := lzma_test_inputs()
	defer lzma_test_inputs_destroy(inputs)

	for r in LZMA_REFERENCES {
		input := lzma_test_input_by_name(inputs, r.name)

		packed: [dynamic]byte
		defer delete(packed)
		err := lzma.compress(&packed, input, r.level)
		testing.expectf(t, err == nil, "%v %v: compress %v", r.name, r.level, err)
		testing.expectf(t, len(packed) == r.size && hash.crc32(packed[:]) == r.crc, "%v %v: %v bytes, crc %x, want %v bytes, crc %x", r.name, r.level, len(packed), hash.crc32(packed[:]), r.size, r.crc)

		output: [dynamic]byte
		defer delete(output)
		err = lzma.decompress(&output, packed[:])
		testing.expectf(t, err == nil && bytes.equal(output[:], input), "%v %v: round trip %v", r.name, r.level, err)

		options := lzma.level_options(r.level)
		packed2: [dynamic]byte
		defer delete(packed2)
		props: lzma.Properties
		props, err = lzma.compress_lzma2(&packed2, input, options)
		testing.expectf(t, err == nil, "%v %v: compress_lzma2 %v", r.name, r.level, err)
		testing.expectf(t, len(packed2) == r.lzma2_size && hash.crc32(packed2[:]) == r.lzma2_crc, "%v %v: lzma2 %v bytes, crc %x, want %v bytes, crc %x", r.name, r.level, len(packed2), hash.crc32(packed2[:]), r.lzma2_size, r.lzma2_crc)

		clear(&output)
		err = lzma.decompress_lzma2(&output, packed2[:], props.dict_size)
		testing.expectf(t, err == nil && bytes.equal(output[:], input), "%v %v: lzma2 round trip %v", r.name, r.level, err)

		slice := make([]byte, r.size)
		defer delete(slice)
		written, serr := lzma.compress(slice, input, r.level)
		testing.expectf(t, serr == nil && written == r.size && bytes.equal(slice, packed[:]), "%v %v: exact slice %v", r.name, r.level, serr)
		_, serr = lzma.compress(slice[:r.size - 1], input, r.level)
		testing.expectf(t, serr == compress.General_Error.Output_Too_Short, "%v %v: short slice %v", r.name, r.level, serr)

		slice2 := make([]byte, r.lzma2_size)
		defer delete(slice2)
		written, _, serr = lzma.compress_lzma2(slice2, input, options)
		testing.expectf(t, serr == nil && written == r.lzma2_size && bytes.equal(slice2, packed2[:]), "%v %v: exact lzma2 slice %v", r.name, r.level, serr)
		_, _, serr = lzma.compress_lzma2(slice2[:r.lzma2_size - 1], input, options)
		testing.expectf(t, serr == compress.General_Error.Output_Too_Short, "%v %v: short lzma2 slice %v", r.name, r.level, serr)
	}
}

@(test)
lzma_round_trip :: proc(t: ^testing.T) {
	inputs: [dynamic][]byte
	defer {
		for input in inputs {
			delete(input)
		}
		delete(inputs)
	}
	for n in ([]int{0, 1, 2, 3, 4, 5, 15, 16, 17, 272, 273, 274, 275, 1000, 70_000}) {
		run := make([]byte, n)
		for &b in run {
			b = 'x'
		}
		append(&inputs, run)
	}
	{
		mixed: [dynamic]byte
		for i in 0..<3000 {
			for _ in 0..<i % 300 {
				append(&mixed, u8(i))
			}
		}
		append(&inputs, mixed[:])
	}
	{
		g := Lz4_Test_Lcg{state = rand.uint64()}
		append(&inputs, lz4_test_lcg_bytes(&g, 100_000 + rand.int_max(100_000)))
		append(&inputs, lz4_test_lcg_text(&g, 50_000 + rand.int_max(100_000)))
		append(&inputs, lz4_test_lcg_text(&g, rand.int_max(5000)))
	}

	Variant :: struct {
		name:    string,
		options: lzma.Options,
	}
	variants: [dynamic]Variant
	defer delete(variants)
	for level in ([]lzma.Level{.Level_0, .Level_2, .Level_5, .Level_9}) {
		append(&variants, Variant{"level", lzma.level_options(level)})
	}
	{
		o := lzma.level_options(.Level_6)
		o.end_marker = true
		append(&variants, Variant{"end marker", o})
		o = lzma.level_options(.Level_6)
		o.dict_size = 4096
		append(&variants, Variant{"dict 4k", o})
		o = lzma.level_options(.Level_1)
		o.dict_size = 4096
		append(&variants, Variant{"fast dict 4k", o})
		for mf in lzma.Match_Finder_Kind {
			o = lzma.level_options(.Level_5)
			o.match_finder = mf
			append(&variants, Variant{"normal", o})
			o = lzma.level_options(.Level_1)
			o.match_finder = mf
			append(&variants, Variant{"fast", o})
		}
		o = lzma.level_options(.Level_6)
		o.lc, o.lp, o.pb = 0, 4, 4
		append(&variants, Variant{"lc0 lp4 pb4", o})
	}

	for input, i in inputs {
		for v in variants {
			packed: [dynamic]byte
			props, err := lzma.compress_raw(&packed, input, v.options)
			testing.expectf(t, err == nil, "input %v %v %v: compress_raw %v", i, v.name, v.options.match_finder, err)
			testing.expectf(t, len(packed) <= lzma.compress_bound(len(input)), "input %v %v: %v bytes over bound", i, v.name, len(packed))
			output: [dynamic]byte
			expected := -1 if v.options.end_marker else len(input)
			err = lzma.decompress_raw(&output, packed[:], props, expected)
			testing.expectf(t, err == nil && bytes.equal(output[:], input), "input %v %v %v: raw round trip %v", i, v.name, v.options.match_finder, err)
			delete(packed)
			delete(output)

			if int(v.options.lc) + int(v.options.lp) > lzma.LZMA2_LCLP_MAX {
				continue
			}
			packed2: [dynamic]byte
			props, err = lzma.compress_lzma2(&packed2, input, v.options)
			testing.expectf(t, err == nil, "input %v %v: compress_lzma2 %v", i, v.name, err)
			testing.expectf(t, len(packed2) <= lzma.compress_lzma2_bound(len(input)), "input %v %v: lzma2 %v bytes over bound", i, v.name, len(packed2))
			output2: [dynamic]byte
			err = lzma.decompress_lzma2(&output2, packed2[:], props.dict_size)
			testing.expectf(t, err == nil && bytes.equal(output2[:], input), "input %v %v %v: lzma2 round trip %v", i, v.name, v.options.match_finder, err)
			delete(packed2)
			delete(output2)
		}
	}
}

@(test)
lzma2_chunks :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = rand.uint64()}
	input: [dynamic]byte
	defer delete(input)
	text := lz4_test_lcg_text(&g, 3 << 20)
	defer delete(text)
	noise := lz4_test_lcg_bytes(&g, 150_000 + rand.int_max(100_000))
	defer delete(noise)
	split := (1 << 19) + rand.int_max(2 << 20)
	append(&input, ..text[:split])
	append(&input, ..noise)
	append(&input, ..text[split:])

	options := lzma.level_options(.Level_1)
	packed: [dynamic]byte
	defer delete(packed)
	props, err := lzma.compress_lzma2(&packed, input[:], options)
	testing.expect_value(t, err, nil)

	copies, continued := 0, 0
	for i := 0; i < len(packed); {
		control := packed[i]
		if control == 0 {
			testing.expect_value(t, i, len(packed) - 1)
			break
		}
		if control < 0x80 {
			copies += 1
			i += 3 + (int(packed[i + 1]) << 8 | int(packed[i + 2])) + 1
			continue
		}
		if control < 0xa0 {
			continued += 1
		}
		i += 5 + (1 if control >= 0xc0 else 0) + (int(packed[i + 3]) << 8 | int(packed[i + 4])) + 1
	}
	testing.expectf(t, copies > 0 && continued > 0, "%v copy chunks, %v continued chunks", copies, continued)

	output: [dynamic]byte
	defer delete(output)
	testing.expect_value(t, lzma.decompress_lzma2(&output, packed[:], props.dict_size), nil)
	testing.expect(t, bytes.equal(output[:], input[:]))
}

@(test)
lzma_compress_arguments :: proc(t: ^testing.T) {
	input := transmute([]byte)string("hello hello hello lzma")
	output: [dynamic]byte
	defer delete(output)

	o := lzma.level_options()
	o.lc = 9
	_, err := lzma.compress_raw(&output, input, o)
	testing.expect_value(t, err, compress.LZMA_Error.Invalid_Properties)
	o = lzma.level_options()
	o.lc, o.lp = 3, 2
	_, err = lzma.compress_lzma2(&output, input, o)
	testing.expect_value(t, err, compress.LZMA_Error.Invalid_Properties)
	_, err = lzma.compress_raw(&output, input, o)
	testing.expect_value(t, err, nil)
	o = lzma.level_options()
	o.match_finder = lzma.Match_Finder_Kind(9)
	_, err = lzma.compress_raw(&output, input, o)
	testing.expect_value(t, err, compress.LZMA_Error.Invalid_Properties)

	testing.expect_value(t, lzma.compress((^[dynamic]byte)(nil), input), compress.General_Error.Incompatible_Options)
	_, err = lzma.compress_raw((^[dynamic]byte)(nil), input, lzma.level_options())
	testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
	_, err = lzma.compress_lzma2((^[dynamic]byte)(nil), input, lzma.level_options())
	testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
	small: [lzma.HEADER_SIZE - 1]byte
	_, err = lzma.compress(small[:], input)
	testing.expect_value(t, err, compress.General_Error.Output_Too_Short)

	testing.expect_value(t, lzma.compress_bound(-1), -1)
	testing.expect_value(t, lzma.compress_bound(max(int)), -1)
	testing.expect_value(t, lzma.compress_lzma2_bound(-1), -1)
	testing.expect_value(t, lzma.compress_lzma2_bound(max(int)), -1)

	for c in ([][2]u32{{1 << 20, 1 << 20}, {(1 << 20) + 1, 3 << 19}, {(2 << 20) + 1, 3 << 20}, {5000, 6 << 10}, {10192446, 12 << 20}, {3 << 30, 3 << 30}, {(3 << 30) + 1, max(u32)}, {max(u32), max(u32)}}) {
		size, _ := lzma.lzma2_dict_size(lzma.lzma2_dict_prop(c[0]))
		testing.expectf(t, size == c[1], "dict %v: rounded to %v, want %v", c[0], size, c[1])
	}

	testing.expect_value(t, lzma.compress(&output, input, .Level_9), nil)
	header, _ := lzma.decode_properties(output[:])
	testing.expect_value(t, header.dict_size, 4096)
	decoded: [dynamic]byte
	defer delete(decoded)
	testing.expect_value(t, lzma.decompress(&decoded, output[:]), nil)
	testing.expect_value(t, string(decoded[:]), string(input))

	zeros := make([]byte, 5000)
	defer delete(zeros)
	o9 := lzma.level_options(.Level_9)
	props: lzma.Properties
	props, err = lzma.compress_raw(&output, zeros, o9)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, props, lzma.Properties{lc = o9.lc, lp = o9.lp, pb = o9.pb, dict_size = 6 << 10})
	slice := make([]byte, lzma.compress_bound(len(zeros)))
	defer delete(slice)
	other: lzma.Properties
	_, other, err = lzma.compress_raw(slice, zeros, o9)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, other, props)
	other, err = lzma.compress_lzma2(&output, zeros, o9)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, other.dict_size, props.dict_size)
	testing.expect_value(t, lzma.compress(&output, zeros, .Level_9), nil)
	header, _ = lzma.decode_properties(output[:])
	testing.expect_value(t, header, props)
}
