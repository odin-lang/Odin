package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/ppmd"
import "core:fmt"
import "core:hash"
import "core:math/rand"
import "core:testing"

PPMD_TEST_TRAILER :: [5]byte{'O', 'd', 'i', 'n', '!'}

PPMD_VECTOR_7Z        :: #load("ppmd_vector_7z.bin")
PPMD_VECTOR_ZIP5      :: #load("ppmd_vector_zip5.bin")
PPMD_VECTOR_ZIP9      :: #load("ppmd_vector_zip9.bin")
PPMD_VECTOR_I_RESTART :: #load("ppmd_vector_i_restart.bin")
PPMD_VECTOR_I_CUT_OFF :: #load("ppmd_vector_i_cut_off.bin")
PPMD_VECTOR_I_FREEZE  :: #load("ppmd_vector_i_freeze.bin")

PPMD_VECTOR_7Z_PROPS   :: ppmd.Properties{variant = .H, order = 8, mem_size = 1 << 18}
PPMD_VECTOR_ZIP5_PROPS :: ppmd.Properties{variant = .I, order = 8, mem_size = 1 << 20, restore = .Restart}
PPMD_VECTOR_ZIP9_PROPS :: ppmd.Properties{variant = .I, order = 12, mem_size = 1 << 20, restore = .Cut_Off}

Ppmd_Test_Inputs :: struct {
	text:   []byte,
	random: []byte,
	repeat: []byte,
	mixed:  []byte,
}

ppmd_test_inputs :: proc() -> (inputs: Ppmd_Test_Inputs) {
	g := Lz4_Test_Lcg{state = 0x50504d64}
	inputs.text   = lz4_test_lcg_text(&g, 20_000)
	inputs.random = lz4_test_lcg_bytes(&g, 4096)
	inputs.repeat = lz4_test_lcg_repeat(&g, 70_000)

	mixed: [dynamic]byte
	append(&mixed, ..inputs.text)
	append(&mixed, ..inputs.random)
	append(&mixed, ..inputs.repeat)
	inputs.mixed = mixed[:]
	return
}

ppmd_test_inputs_destroy :: proc(inputs: Ppmd_Test_Inputs) {
	delete(inputs.text)
	delete(inputs.random)
	delete(inputs.repeat)
	delete(inputs.mixed)
}

ppmd_test_input_by_name :: proc(inputs: Ppmd_Test_Inputs, name: string) -> []byte {
	switch name {
	case "text":   return inputs.text
	case "random": return inputs.random
	case "repeat": return inputs.repeat
	case "mixed":  return inputs.mixed
	}
	return nil
}

ppmd_test_unpack :: proc(t: ^testing.T, name: string, packed: []byte, props: ppmd.Properties, want: []byte, expected: int) {
	data: [dynamic]byte
	defer delete(data)
	append(&data, ..packed)
	tail := PPMD_TEST_TRAILER
	append(&data, ..tail[:])

	for kind in Stream_Kind {
		input := data[:]
		br: bytes.Reader
		tr: Trickle_Reader
		output: [dynamic]byte
		defer delete(output)
		ctx := stream_test_context(kind, &input, &br, &tr, &output)
		defer compress.destroy_context(&ctx)
		ppmd_test_unpack_context(t, &ctx, &output, fmt.tprint(name, kind, sep = ", "), props, want, expected)
	}

	tr := Trickle_Reader{data = data[:], chunk = 1 + rand.int_max(8192), seekable = rand.int_max(2) == 0}
	output: [dynamic]byte
	defer delete(output)
	ctx := compress.init_context(trickle_stream(&tr), &output)
	defer compress.destroy_context(&ctx)
	ppmd_test_unpack_context(t, &ctx, &output, fmt.tprintf("%v, chunks of %v, seekable %v", name, tr.chunk, tr.seekable), props, want, expected)
}

ppmd_test_unpack_context :: proc(t: ^testing.T, ctx: ^compress.Context, output: ^[dynamic]byte, name: string, props: ppmd.Properties, want: []byte, expected: int) {
	err := ppmd.decompress(ctx, props, expected)
	testing.expectf(t, err == nil, "%v, size %v: decompress returned %v", name, expected, err)
	testing.expectf(t, bytes.equal(output[:], want), "%v, size %v: output differs (%v vs %v bytes)", name, expected, len(output), len(want))

	rest: [5]byte
	rest_err := compress.read_slice(ctx, rest[:])
	testing.expectf(t, rest_err == nil && rest == PPMD_TEST_TRAILER, "%v, size %v: bytes after the stream were %v, %v", name, expected, rest, rest_err)
}

ppmd_test_pack :: proc(t: ^testing.T, name: string, input: []byte, props: ppmd.Properties, end_marker: bool, want: []byte) {
	packed: [dynamic]byte
	defer delete(packed)
	err := ppmd.compress(&packed, input, props, end_marker)
	testing.expectf(t, err == nil && bytes.equal(packed[:], want), "%v: compress returned %v, %v vs %v bytes", name, err, len(packed), len(want))
}

ppmd_test_round_trip :: proc(t: ^testing.T, input: []byte, props: ppmd.Properties, end_marker: bool) {
	packed: [dynamic]byte
	defer delete(packed)
	err := ppmd.compress(&packed, input, props, end_marker)
	testing.expectf(t, err == nil, "%v, end marker %v, %v bytes: compress returned %v", props, end_marker, len(input), err)

	slice := make([]byte, len(packed))
	defer delete(slice)
	n, slice_err := ppmd.compress(slice, input, props, end_marker)
	testing.expectf(t, slice_err == nil && n == len(packed) && bytes.equal(slice, packed[:]), "%v, end marker %v, %v bytes: slice compress returned %v, %v bytes", props, end_marker, len(input), slice_err, n)
	if len(slice) > 0 {
		_, short_err := ppmd.compress(slice[:len(slice) - 1], input, props, end_marker)
		testing.expectf(t, short_err == compress.General_Error.Output_Too_Short, "%v, end marker %v, %v bytes: short slice returned %v", props, end_marker, len(input), short_err)
	}

	output: [dynamic]byte
	defer delete(output)
	err = ppmd.decompress(&output, packed[:], props, len(input))
	testing.expectf(t, err == nil && bytes.equal(output[:], input), "%v, end marker %v, %v bytes: decompress returned %v, %v bytes", props, end_marker, len(input), err, len(output))
	if end_marker {
		err = ppmd.decompress(&output, packed[:], props)
		testing.expectf(t, err == nil && bytes.equal(output[:], input), "%v, %v bytes: unknown size decompress returned %v, %v bytes", props, len(input), err, len(output))
	}
}

@(test)
ppmd_vectors :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)

	ppmd_test_unpack(t, "7z", PPMD_VECTOR_7Z, PPMD_VECTOR_7Z_PROPS, inputs.text, len(inputs.text))
	ppmd_test_pack(t, "7z", inputs.text, PPMD_VECTOR_7Z_PROPS, false, PPMD_VECTOR_7Z)

	Zip_Case :: struct {
		name:  string,
		body:  []byte,
		props: ppmd.Properties,
	}
	zips := [?]Zip_Case{
		{"zip mx5", PPMD_VECTOR_ZIP5, PPMD_VECTOR_ZIP5_PROPS},
		{"zip mx9", PPMD_VECTOR_ZIP9, PPMD_VECTOR_ZIP9_PROPS},
	}
	for z in zips {
		props, props_err := ppmd.decode_properties_zip(z.body)
		testing.expectf(t, props_err == nil && props == z.props, "%v: decode_properties_zip returned %v, %v", z.name, props, props_err)
		encoded, encode_err := ppmd.encode_properties_zip(z.props)
		testing.expectf(t, encode_err == nil && bytes.equal(encoded[:], z.body[:ppmd.PROPERTIES_ZIP_SIZE]), "%v: encode_properties_zip returned %v, %v", z.name, encoded, encode_err)

		stream := z.body[ppmd.PROPERTIES_ZIP_SIZE:]
		ppmd_test_unpack(t, z.name, stream, z.props, inputs.text, len(inputs.text))
		ppmd_test_unpack(t, z.name, stream, z.props, inputs.text, -1)
		ppmd_test_pack(t, z.name, inputs.text, z.props, true, stream)
	}

	Restore_Case :: struct {
		name:    string,
		packed:  []byte,
		restore: ppmd.Restore_Method,
	}
	restores := [?]Restore_Case{
		{"restart", PPMD_VECTOR_I_RESTART, .Restart},
		{"cut off", PPMD_VECTOR_I_CUT_OFF, .Cut_Off},
		{"freeze",  PPMD_VECTOR_I_FREEZE,  .Freeze},
	}
	for r in restores {
		props := ppmd.Properties{variant = .I, order = 16, mem_size = 1 << 16, restore = r.restore}
		ppmd_test_unpack(t, r.name, r.packed, props, inputs.text, len(inputs.text))
		ppmd_test_unpack(t, r.name, r.packed, props, inputs.text, -1)
		ppmd_test_pack(t, r.name, inputs.text, props, true, r.packed)
	}
}

@(test)
ppmd_round_trip :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)

	one := [1]byte{42}
	cases := [?][]byte{nil, one[:], inputs.text, inputs.random, inputs.repeat, inputs.mixed}
	for input in cases {
		for variant in ppmd.Variant {
			for level in ([]ppmd.Level{.Level_0, .Level_5, .Level_9}) {
				props := ppmd.level_properties(variant, level, len(input))
				ppmd_test_round_trip(t, input, props, false)
				ppmd_test_round_trip(t, input, props, true)
			}
		}
	}

	for _ in 0..<8 {
		start := rand.int_max(len(inputs.mixed))
		input := inputs.mixed[start:][:rand.int_max(len(inputs.mixed) - start + 1)]
		props := ppmd.level_properties(rand.choice_enum(ppmd.Variant), ppmd.Level(rand.int_max(10)), len(input))
		ppmd_test_round_trip(t, input, props, rand.int_max(2) == 0)
	}
}

@(test)
ppmd_restore_methods :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)

	input := inputs.mixed[len(inputs.text) - 8000:][:12_000]
	for mem in ([]u32{ppmd.MEM_SIZE_MIN, ppmd.CUT_OFF_MEM_SIZE_MIN, 3001, 1 << 14, u32(ppmd.MEM_SIZE_MIN + rand.int_max(1 << 15))}) {
		for order in ([]u8{2, 6, 16, u8(ppmd.ORDER_MIN + rand.int_max(ppmd.I_ORDER_MAX - ppmd.ORDER_MIN + 1))}) {
			for restore in ppmd.Restore_Method {
				if restore == .Cut_Off && mem < ppmd.CUT_OFF_MEM_SIZE_MIN {
					continue
				}
				ppmd_test_round_trip(t, input, {variant = .I, order = order, mem_size = mem, restore = restore}, true)
			}
		}
		for order in ([]u8{2, 6, 16, 64, u8(ppmd.ORDER_MIN + rand.int_max(ppmd.H_ORDER_MAX - ppmd.ORDER_MIN + 1))}) {
			ppmd_test_round_trip(t, input, {variant = .H, order = order, mem_size = mem}, false)
		}
	}
}

Ppmd_Reference :: struct {
	name:    string,
	variant: ppmd.Variant,
	level:   ppmd.Level,
	size:    int,
	crc:     u32,
}

@(rodata)
PPMD_REFERENCES := []Ppmd_Reference{
	{"text",   .H, .Level_0, 1306, 0x7c61b3f6},
	{"text",   .H, .Level_5, 1324, 0xc0423905},
	{"text",   .H, .Level_9, 1670, 0x5b209f26},
	{"text",   .I, .Level_0, 1298, 0x0adabe43},
	{"text",   .I, .Level_5, 1351, 0xd4ba660a},
	{"text",   .I, .Level_9, 1402, 0x6180b39d},
	{"random", .H, .Level_5, 4266, 0x14f86258},
	{"random", .I, .Level_5, 4274, 0xfda452da},
	{"repeat", .H, .Level_0, 2065, 0x1bad7ef0},
	{"repeat", .H, .Level_5, 2100, 0x4ed2eedc},
	{"repeat", .H, .Level_9, 2258, 0xd87375cc},
	{"repeat", .I, .Level_0, 2042, 0x2e19c9a0},
	{"repeat", .I, .Level_5, 2082, 0xa29266bf},
	{"repeat", .I, .Level_9, 2105, 0xb9a7a2f5},
	{"mixed",  .H, .Level_0, 7682, 0x3ee2dd42},
	{"mixed",  .H, .Level_5, 7700, 0x7090427a},
	{"mixed",  .H, .Level_9, 8114, 0x0794aaf4},
	{"mixed",  .I, .Level_0, 7656, 0x4ede987d},
	{"mixed",  .I, .Level_5, 7728, 0x288c4fc8},
	{"mixed",  .I, .Level_9, 7806, 0x223ce75d},
}

@(test)
ppmd_compress_matches_reference :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)

	for r in PPMD_REFERENCES {
		input := ppmd_test_input_by_name(inputs, r.name)
		props := ppmd.level_properties(r.variant, r.level, len(input))

		packed: [dynamic]byte
		defer delete(packed)
		err := ppmd.compress(&packed, input, props, r.variant == .I)
		testing.expectf(t, err == nil, "%v %v %v: compress returned %v", r.name, r.variant, r.level, err)
		testing.expectf(t, len(packed) == r.size && hash.crc32(packed[:]) == r.crc, "%v %v %v: %v bytes, crc %x, want %v bytes, crc %x", r.name, r.variant, r.level, len(packed), hash.crc32(packed[:]), r.size, r.crc)

		output: [dynamic]byte
		defer delete(output)
		err = ppmd.decompress(&output, packed[:], props, len(input))
		testing.expectf(t, err == nil && bytes.equal(output[:], input), "%v %v %v: round trip returned %v", r.name, r.variant, r.level, err)
	}
}

@(test)
ppmd_truncated :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)

	Case :: struct {
		name:     string,
		packed:   []byte,
		props:    ppmd.Properties,
		expected: int,
	}
	zip5 := PPMD_VECTOR_ZIP5
	cases := [?]Case{
		{"7z",              PPMD_VECTOR_7Z,                         PPMD_VECTOR_7Z_PROPS,   len(inputs.text)},
		{"zip mx5",         zip5[ppmd.PROPERTIES_ZIP_SIZE:],        PPMD_VECTOR_ZIP5_PROPS, len(inputs.text)},
		{"zip mx5 unsized", zip5[ppmd.PROPERTIES_ZIP_SIZE:],        PPMD_VECTOR_ZIP5_PROPS, -1},
		{"freeze unsized",  PPMD_VECTOR_I_FREEZE, {variant = .I, order = 16, mem_size = 1 << 16, restore = .Freeze}, -1},
	}
	for c in cases {
		for k in 0..<24 + len(c.packed) / 23 {
			n: int
			switch {
			case k < 16: n = k
			case k < 24: n = len(c.packed) - 24 + k
			case:        n = 16 + rand.int_max(len(c.packed) - 24)
			}
			output: [dynamic]byte
			err := ppmd.decompress(&output, c.packed[:n], c.props, c.expected, len(inputs.text) + 1000)
			delete(output)
			testing.expectf(t, err != nil, "%v: %v of %v bytes decoded without error", c.name, n, len(c.packed))
		}
	}
}

@(test)
ppmd_corrupt :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)

	Case :: struct {
		name:     string,
		packed:   []byte,
		props:    ppmd.Properties,
		expected: int,
	}
	cases := [?]Case{
		{"7z",             PPMD_VECTOR_7Z,       PPMD_VECTOR_7Z_PROPS, len(inputs.text)},
		{"freeze unsized", PPMD_VECTOR_I_FREEZE, {variant = .I, order = 16, mem_size = 1 << 16, restore = .Freeze}, -1},
	}
	for c in cases {
		data := make([]byte, len(c.packed))
		defer delete(data)
		limit      := len(inputs.text) + 1000
		edge       := 16
		edge_masks := [3]byte{0x01, 0x80, 0xff}
		interior   := len(c.packed) - 2 * edge
		accepted   := 0
		tried      := 0
		for k in 0..<2 * edge * 3 + interior / 7 * 3 {
			copy(data, c.packed)
			i:    int
			mask: byte
			if k < 2 * edge * 3 {
				i    = k / 3 if k < edge * 3 else interior + k / 3
				mask = edge_masks[k % 3]
			} else {
				i    = edge + rand.int_max(interior)
				mask = u8(1 + rand.int_max(255))
				if rand.int_max(4) == 0 {
					data[edge + rand.int_max(interior)] ~= u8(1 + rand.int_max(255))
				}
			}
			data[i] ~= mask
			output: [dynamic]byte
			err := ppmd.decompress(&output, data, c.props, c.expected, limit)
			testing.expectf(t, len(output) <= limit, "%v: flip %x at %v wrote %v bytes", c.name, mask, i, len(output))
			if err == nil {
				accepted += 1
			}
			tried += 1
			delete(output)
		}
		testing.expectf(t, accepted < tried / 4, "%v: %v of %v corruptions accepted", c.name, accepted, tried)
	}
}

@(test)
ppmd_limits :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)

	output: [dynamic]byte
	defer delete(output)

	zip5   := PPMD_VECTOR_ZIP5
	stream := zip5[ppmd.PROPERTIES_ZIP_SIZE:]
	size   := len(inputs.text)

	testing.expect_value(t, ppmd.decompress(&output, PPMD_VECTOR_7Z, PPMD_VECTOR_7Z_PROPS, size, size - 1), compress.General_Error.Output_Too_Short)
	testing.expect(t, ppmd.decompress(&output, PPMD_VECTOR_7Z, PPMD_VECTOR_7Z_PROPS, size - 1) != nil)

	testing.expect_value(t, ppmd.decompress(&output, stream, PPMD_VECTOR_ZIP5_PROPS, max_output_size = size - 1), compress.General_Error.Output_Too_Short)
	testing.expect(t, len(output) <= size - 1)
	testing.expect_value(t, ppmd.decompress(&output, stream, PPMD_VECTOR_ZIP5_PROPS, size + 1), compress.PPMd_Error.Unexpected_End_Marker)
	testing.expect_value(t, ppmd.decompress(&output, stream, PPMD_VECTOR_ZIP5_PROPS, size - 1), compress.PPMd_Error.Corrupt_Data)
	testing.expect_value(t, ppmd.decompress(&output, stream, PPMD_VECTOR_ZIP5_PROPS, max_output_size = size), nil)
	testing.expect(t, bytes.equal(output[:], inputs.text))

	testing.expect_value(t, ppmd.decompress(&output, stream, PPMD_VECTOR_ZIP5_PROPS, max_output_size = -1), compress.General_Error.Incompatible_Options)
	testing.expect_value(t, ppmd.decompress((^[dynamic]byte)(nil), stream, PPMD_VECTOR_ZIP5_PROPS), compress.General_Error.Incompatible_Options)
	testing.expect_value(t, ppmd.compress((^[dynamic]byte)(nil), inputs.text, PPMD_VECTOR_ZIP5_PROPS), compress.General_Error.Incompatible_Options)
}

@(test)
ppmd_memory_limit :: proc(t: ^testing.T) {
	if u64(ppmd.MEMORY_MAX) >= u64(ppmd.MEM_SIZE_MAX) {
		return
	}
	output: [dynamic]byte
	defer delete(output)
	packed: [dynamic]byte
	defer delete(packed)

	input := [?]byte{1, 2, 3}
	for mem in ([]u32{u32(ppmd.MEMORY_MAX) + 1, 1 << 31, ppmd.MEM_SIZE_MAX}) {
		for props in ([]ppmd.Properties{{variant = .H, order = 6, mem_size = mem}, {variant = .I, order = 6, mem_size = mem, restore = .Cut_Off}}) {
			testing.expect_value(t, ppmd.decompress(&output, PPMD_VECTOR_7Z, props, 100), compress.PPMd_Error.Memory_Limit_Exceeded)
			testing.expect_value(t, ppmd.compress(&packed, input[:], props), compress.PPMd_Error.Memory_Limit_Exceeded)
		}
	}

	props, props_err := ppmd.decode_properties_7z({6, 0xdb, 0xff, 0xff, 0xff})
	testing.expect_value(t, props_err, nil)
	testing.expect_value(t, props.mem_size, ppmd.MEM_SIZE_MAX)
	testing.expect_value(t, ppmd.decompress(&output, PPMD_VECTOR_7Z, props, 100), compress.PPMd_Error.Memory_Limit_Exceeded)
}

@(test)
ppmd_invalid :: proc(t: ^testing.T) {
	output: [dynamic]byte
	defer delete(output)
	packed: [dynamic]byte
	defer delete(packed)

	invalid := [?]ppmd.Properties{
		{variant = .H, order = 1,  mem_size = 1 << 20},
		{variant = .H, order = 65, mem_size = 1 << 20},
		{variant = .I, order = 17, mem_size = 1 << 20},
		{variant = .H, order = 6,  mem_size = ppmd.MEM_SIZE_MIN - 1},
		{variant = .I, order = 6,  mem_size = ppmd.MEM_SIZE_MAX + 1},
		{variant = .H, order = 6,  mem_size = 1 << 20, restore = .Cut_Off},
		{variant = .I, order = 6,  mem_size = 1 << 20, restore = ppmd.Restore_Method(3)},
		{variant = .I, order = 6,  mem_size = ppmd.CUT_OFF_MEM_SIZE_MIN - 1, restore = .Cut_Off},
	}
	for props in invalid {
		testing.expect_value(t, ppmd.decompress(&output, PPMD_VECTOR_7Z, props, 100), compress.PPMd_Error.Invalid_Properties)
		testing.expect_value(t, ppmd.compress(&packed, {1, 2, 3}, props), compress.PPMd_Error.Invalid_Properties)
	}

	h := ppmd.Properties{variant = .H, order = 6, mem_size = 1 << 20}
	i := ppmd.Properties{variant = .I, order = 6, mem_size = 1 << 20}
	testing.expect_value(t, ppmd.decompress(&output, {1, 0, 0, 0, 0}, h, 10), compress.PPMd_Error.Corrupt_Data)
	testing.expect_value(t, ppmd.decompress(&output, {0, 0xff, 0xff, 0xff, 0xff}, h, 10), compress.PPMd_Error.Corrupt_Data)
	testing.expect_value(t, ppmd.decompress(&output, {0xff, 0xff, 0xff, 0xff}, i, 10), compress.PPMd_Error.Corrupt_Data)
	testing.expect_value(t, ppmd.decompress(&output, {0, 0, 0}, h, 10), compress.General_Error.Stream_Too_Short)
	testing.expect_value(t, ppmd.decompress(&output, {}, i, 10), compress.General_Error.Stream_Too_Short)
	testing.expect_value(t, ppmd.decompress(&output, {}, i, 0), compress.General_Error.Stream_Too_Short)
}

@(test)
ppmd_properties :: proc(t: ^testing.T) {
	props_7z, err_7z := ppmd.decode_properties_7z({6, 0, 0, 0, 1})
	testing.expect_value(t, err_7z, nil)
	testing.expect_value(t, props_7z, ppmd.Properties{variant = .H, order = 6, mem_size = 1 << 24})
	encoded_7z, encode_7z_err := ppmd.encode_properties_7z(props_7z)
	testing.expect_value(t, encode_7z_err, nil)
	testing.expect_value(t, encoded_7z, [ppmd.PROPERTIES_7Z_SIZE]byte{6, 0, 0, 0, 1})

	_, err_7z = ppmd.decode_properties_7z({6, 0, 0, 0})
	testing.expect_value(t, err_7z, compress.PPMd_Error.Invalid_Properties)
	_, err_7z = ppmd.decode_properties_7z({1, 0, 0, 0, 1})
	testing.expect_value(t, err_7z, compress.PPMd_Error.Invalid_Properties)
	_, err_7z = ppmd.decode_properties_7z({6, 0, 4, 0, 0})
	testing.expect_value(t, err_7z, compress.PPMd_Error.Invalid_Properties)
	_, encode_7z_err = ppmd.encode_properties_7z(PPMD_VECTOR_ZIP5_PROPS)
	testing.expect_value(t, encode_7z_err, compress.PPMd_Error.Invalid_Properties)

	props_zip, err_zip := ppmd.decode_properties_zip({0x07, 0x20})
	testing.expect_value(t, err_zip, nil)
	testing.expect_value(t, props_zip, ppmd.Properties{variant = .I, order = 8, mem_size = 1 << 20, restore = .Freeze})
	props_zip, err_zip = ppmd.decode_properties_zip({0xff, 0x1f})
	testing.expect_value(t, err_zip, nil)
	testing.expect_value(t, props_zip, ppmd.Properties{variant = .I, order = 16, mem_size = ppmd.ZIP_MEM_SIZE_MAX, restore = .Cut_Off})
	encoded_zip, encode_zip_err := ppmd.encode_properties_zip(props_zip)
	testing.expect_value(t, encode_zip_err, nil)
	testing.expect_value(t, encoded_zip, [ppmd.PROPERTIES_ZIP_SIZE]byte{0xff, 0x1f})

	_, err_zip = ppmd.decode_properties_zip({0x07})
	testing.expect_value(t, err_zip, compress.PPMd_Error.Invalid_Properties)
	_, err_zip = ppmd.decode_properties_zip({0x00, 0x00})
	testing.expect_value(t, err_zip, compress.PPMd_Error.Invalid_Properties)
	_, err_zip = ppmd.decode_properties_zip({0x07, 0x30})
	testing.expect_value(t, err_zip, compress.PPMd_Error.Invalid_Properties)
	_, encode_zip_err = ppmd.encode_properties_zip({variant = .I, order = 8, mem_size = 3 << 19})
	testing.expect_value(t, encode_zip_err, compress.PPMd_Error.Invalid_Properties)
	_, encode_zip_err = ppmd.encode_properties_zip({variant = .I, order = 8, mem_size = 512 << 20})
	testing.expect_value(t, encode_zip_err, compress.PPMd_Error.Invalid_Properties)
	_, encode_zip_err = ppmd.encode_properties_zip(PPMD_VECTOR_7Z_PROPS)
	testing.expect_value(t, encode_zip_err, compress.PPMd_Error.Invalid_Properties)

	testing.expect_value(t, ppmd.level_properties(.H), ppmd.Properties{variant = .H, order = 6, mem_size = 1 << 24})
	testing.expect_value(t, ppmd.level_properties(.I), ppmd.Properties{variant = .I, order = 8, mem_size = 1 << 24})
	testing.expect_value(t, ppmd.level_properties(.H, .Fastest), ppmd.Properties{variant = .H, order = 3, mem_size = 1 << 19})
	testing.expect_value(t, ppmd.level_properties(.I, .Fastest), ppmd.Properties{variant = .I, order = 3, mem_size = 1 << 20})
	testing.expect_value(t, ppmd.level_properties(.H, .Best), ppmd.Properties{variant = .H, order = 32, mem_size = 1 << 28})
	testing.expect_value(t, ppmd.level_properties(.I, .Best), ppmd.Properties{variant = .I, order = 12, mem_size = 1 << 28, restore = .Cut_Off})
	testing.expect_value(t, ppmd.level_properties(.H, .Default, 1000).mem_size, 1 << 16)
	testing.expect_value(t, ppmd.level_properties(.I, .Default, 1000).mem_size, 1 << 20)
	testing.expect_value(t, ppmd.level_properties(.H, .Default, 100_000).mem_size, 1 << 21)
	testing.expect_value(t, ppmd.level_properties(.H, .Fastest, 1 << 30).mem_size, 1 << 19)
}
