package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/ppmd"
import "core:io"
import "core:math/rand"
import "core:testing"

PPMD_STREAM_FUZZ :: #config(PPMD_STREAM_FUZZ, 100)

PPMD_STREAM_PROPS :: [?]ppmd.Properties{
	{variant = .H, order = 6,  mem_size = 1 << 20},
	{variant = .H, order = 32, mem_size = 1 << 16},
	{variant = .I, order = 8,  mem_size = 1 << 20, restore = .Restart},
	{variant = .I, order = 16, mem_size = 1 << 16, restore = .Cut_Off},
	{variant = .I, order = 4,  mem_size = 1 << 11, restore = .Restart},
}

Ppmd_Progress_Log :: struct {
	calls:     [dynamic]compress.Progress,
	cancel_at: int,
}

ppmd_progress_log :: proc(progress: compress.Progress, user_data: rawptr) -> (cancel: bool) {
	log := (^Ppmd_Progress_Log)(user_data)
	append(&log.calls, progress)
	return log.cancel_at > 0 && len(log.calls) >= log.cancel_at
}

ppmd_progress_options :: proc(log: ^Ppmd_Progress_Log, options := compress.Options{}) -> compress.Options {
	clear(&log.calls)
	opts := options
	opts.progress      = ppmd_progress_log
	opts.progress_data = log
	return opts
}

@(test)
ppmd_stream_round_trip :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)
	g := Lz4_Test_Lcg{state = 0x5ee2}
	text := lz4_test_lcg_text(&g, 40_000 if !SLIM_TESTS else 20_000)
	defer delete(text)
	trailer := PPMD_TEST_TRAILER

	for data in ([][]byte{text, inputs.mixed}) {
		for props in PPMD_STREAM_PROPS {
			input := data if props.mem_size >= 1 << 20 else data[:min(len(data), 12_000)]
			for end_marker in ([]bool{false, true}) {
				packed: [dynamic]byte
				defer delete(packed)
				testing.expect_value(t, ppmd.compress(&packed, input, props, end_marker), nil)
				append(&packed, ..trailer[:])
				for kind in Stream_Kind {
					chunk := 777 if int(kind) & 1 == 0 else 0
					ppmd_stream_check(t, "round trip", kind, packed[:], props, len(input), {chunk_size = chunk})
					if end_marker {
						ppmd_stream_check(t, "round trip unsized", kind, packed[:], props, -1, {chunk_size = 0 if chunk > 0 else 777})
					}
				}
				if props.order == 6 {
					ppmd_stream_check(t, "round trip, chunk 1", .Memory, packed[:], props, len(input), {chunk_size = 1})
				}
			}
		}
	}
}

@(test)
ppmd_stream_vectors :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)
	trailer := PPMD_TEST_TRAILER

	Vector :: struct {
		name:     string,
		packed:   []byte,
		props:    ppmd.Properties,
		expected: int,
	}
	zip5 := PPMD_VECTOR_ZIP5
	zip9 := PPMD_VECTOR_ZIP9
	vectors := [?]Vector{
		{"7z",              PPMD_VECTOR_7Z,                  PPMD_VECTOR_7Z_PROPS,   len(inputs.text)},
		{"zip mx5",         zip5[ppmd.PROPERTIES_ZIP_SIZE:], PPMD_VECTOR_ZIP5_PROPS, len(inputs.text)},
		{"zip mx5 unsized", zip5[ppmd.PROPERTIES_ZIP_SIZE:], PPMD_VECTOR_ZIP5_PROPS, -1},
		{"zip mx9 unsized", zip9[ppmd.PROPERTIES_ZIP_SIZE:], PPMD_VECTOR_ZIP9_PROPS, -1},
		{"restart unsized", PPMD_VECTOR_I_RESTART, {variant = .I, order = 16, mem_size = 1 << 16, restore = .Restart}, -1},
		{"cut off",         PPMD_VECTOR_I_CUT_OFF, {variant = .I, order = 16, mem_size = 1 << 16, restore = .Cut_Off}, len(inputs.text)},
	}
	for v in vectors {
		packed: [dynamic]byte
		defer delete(packed)
		append(&packed, ..v.packed)
		append(&packed, ..trailer[:])
		for kind in Stream_Kind {
			for chunk in ([]int{0, 1, 4096}) {
				ppmd_stream_check(t, v.name, kind, packed[:], v.props, v.expected, {chunk_size = chunk})
			}
		}

		output: [dynamic]byte
		defer delete(output)
		data := packed[:]
		ctx  := compress.init_context(&data)
		aw   := Append_Writer{out = &output, fail_at = -1}
		testing.expect_value(t, ppmd.decompress_to_writer(append_writer(&aw), &ctx, v.props, v.expected), nil)
		testing.expectf(t, bytes.equal(output[:], inputs.text), "%v: writer output differs, %v bytes", v.name, len(output))
		testing.expectf(t, bytes.equal(ctx.window, trailer[:]), "%v: input after the stream is %v", v.name, ctx.window)
		testing.expect_value(t, ctx.bytes_written, i64(len(inputs.text)))
	}
}

@(test)
ppmd_stream_truncated :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)
	input := inputs.text[:3000]

	props_list := [?]ppmd.Properties{
		{variant = .H, order = 8,  mem_size = 1 << 16},
		{variant = .I, order = 16, mem_size = 1 << 16, restore = .Cut_Off},
	}
	for props in props_list {
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, ppmd.compress(&packed, input, props, true), nil)
		for n in 0..=len(packed) {
			kind := Stream_Kind.Memory if n % 7 != 0 else Stream_Kind(rand.int_max(len(Stream_Kind)))
			ppmd_stream_check(t, "truncated", kind, packed[:n], props, len(input))
			ppmd_stream_check(t, "truncated unsized", kind, packed[:n], props, -1, {max_output_size = 2 * len(input)})
		}

		mutated := make([]byte, len(packed))
		defer delete(mutated)
		for _ in 0..<200 {
			copy(mutated, packed[:])
			mutated[rand.int_max(len(mutated))] ~= u8(1 + rand.int_max(255))
			kind := Stream_Kind(rand.int_max(len(Stream_Kind)))
			ppmd_stream_check(t, "corrupt", kind, mutated, props, len(input))
			ppmd_stream_check(t, "corrupt unsized", kind, mutated, props, -1, {max_output_size = 2 * len(input)})
		}
	}
}

@(test)
ppmd_stream_options :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)
	input := inputs.mixed
	props := ppmd.Properties{variant = .H, order = 6, mem_size = 1 << 20}
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, ppmd.compress(&packed, input, props, true), nil)

	for limit in ([]int{1, 1000, len(input) - 1, len(input), len(input) + 1}) {
		for kind in Stream_Kind {
			ppmd_stream_check(t, "max_output_size", kind, packed[:], props, -1, {max_output_size = limit})
		}
	}
	ppmd_stream_check(t, "expected over the limit", .Memory, packed[:], props, len(input), {max_output_size = len(input) - 1})

	Bad :: struct {
		name:    string,
		options: compress.Options,
	}
	empty: [0]byte
	bad := [?]Bad{
		{"max_output_size",   {max_output_size = -1}},
		{"max_memory",        {max_memory = -1}},
		{"chunk_size",        {chunk_size = -1}},
		{"progress_interval", {progress_interval = -1}},
	}
	for b in bad {
		data := packed[:]
		ctx  := compress.init_context(&data)
		testing.expectf(t, ppmd.decompress_to_writer(io.Writer{}, &ctx, props, -1, b.options) == compress.General_Error.Incompatible_Options, "writer, %v", b.name)
		r: ppmd.Reader
		testing.expectf(t, ppmd.reader_init(&r, &ctx, props, -1, b.options) == compress.General_Error.Incompatible_Options, "reader, %v", b.name)
		n, read_err := ppmd.reader_read(&r, make([]byte, 16, context.temp_allocator))
		testing.expectf(t, n == 0 && read_err == compress.General_Error.Incompatible_Options, "reader, %v: read gave %v, %v", b.name, n, read_err)
		ppmd.reader_destroy(&r)
	}
	data := packed[:]
	ctx  := compress.init_context(&data)
	testing.expect_value(t, ppmd.decompress_to_writer(io.Writer{}, &ctx, props, -1, {buffer = empty[:]}), compress.General_Error.Incompatible_Options)

	Memory_Case :: struct {
		options: compress.Options,
		want:    compress.Error,
	}
	buffer: [100]byte
	memory_cases := [?]Memory_Case{
		{{max_memory = int(props.mem_size) + ppmd.CHUNK_SIZE - 1},                    compress.General_Error.Memory_Limit_Exceeded},
		{{max_memory = int(props.mem_size) + ppmd.CHUNK_SIZE},                        nil},
		{{max_memory = int(props.mem_size) + 99, chunk_size = 100},                   compress.General_Error.Memory_Limit_Exceeded},
		{{max_memory = int(props.mem_size) + 100, chunk_size = 100},                  nil},
		{{max_memory = int(props.mem_size), buffer = buffer[:]},                      nil},
		{{max_memory = int(props.mem_size) - 1, buffer = buffer[:]},                  compress.General_Error.Memory_Limit_Exceeded},
	}
	for c in memory_cases {
		output: [dynamic]byte
		defer delete(output)
		data = packed[:]
		ctx  = compress.init_context(&data)
		aw  := Append_Writer{out = &output, fail_at = -1}
		err := ppmd.decompress_to_writer(append_writer(&aw), &ctx, props, -1, c.options)
		testing.expectf(t, err == c.want, "writer, %v: %v", c.options.max_memory, err)
		if c.want == nil {
			testing.expectf(t, bytes.equal(output[:], input), "writer, %v: output differs", c.options.max_memory)
		}
	}
	for limit in ([]int{int(props.mem_size) - 1, int(props.mem_size)}) {
		data = packed[:]
		ctx  = compress.init_context(&data)
		r: ppmd.Reader
		err := ppmd.reader_init(&r, &ctx, props, -1, {max_memory = limit})
		ppmd.reader_destroy(&r)
		want := compress.General_Error.Memory_Limit_Exceeded if limit < int(props.mem_size) else nil
		testing.expectf(t, err == want, "reader, max_memory %v: %v", limit, err)
	}

	output: [dynamic]byte
	defer delete(output)
	data = packed[:]
	ctx  = compress.init_context(&data)
	aw  := Append_Writer{out = &output, fail_at = 1000}
	testing.expect_value(t, ppmd.decompress_to_writer(append_writer(&aw), &ctx, props, -1, {chunk_size = 300}), io.Error.Short_Write)
	testing.expectf(t, len(output) == 1000 && bytes.equal(output[:], input[:1000]), "failing writer: %v bytes", len(output))

	freeze := ppmd.Properties{variant = .I, order = 8, mem_size = 1 << 20, restore = .Freeze}
	data = packed[:]
	ctx  = compress.init_context(&data)
	testing.expect_value(t, ppmd.decompress_to_writer(io.Writer{}, &ctx, freeze), compress.PPMd_Error.Unsupported_Restore_Method)
}

@(test)
ppmd_reader_stream :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)
	props := ppmd.Properties{variant = .I, order = 8, mem_size = 1 << 20, restore = .Restart}
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, ppmd.compress(&packed, inputs.text, props, true), nil)

	data := packed[:]
	ctx  := compress.init_context(&data)
	r    := new(ppmd.Reader)
	defer free(r)
	testing.expect_value(t, ppmd.reader_init(r, &ctx, props), nil)
	s := ppmd.reader_to_stream(r)
	testing.expect_value(t, io.query(s), io.Stream_Mode_Set{.Read, .Destroy, .Query})
	output: [dynamic]byte
	defer delete(output)
	chunk: [1000]byte
	read_err: io.Error
	for read_err == nil {
		got: int
		got, read_err = io.read(s, chunk[:])
		append(&output, ..chunk[:got])
	}
	testing.expectf(t, read_err == .EOF && bytes.equal(output[:], inputs.text), "stream read gave %v, %v bytes", read_err, len(output))
	n, err := ppmd.reader_read(r, make([]byte, 10, context.temp_allocator))
	testing.expectf(t, n == 0 && err == io.Error.EOF, "read after the end gave %v, %v", n, err)
	n, err = ppmd.reader_read(r, nil)
	testing.expectf(t, n == 0 && err == nil, "empty read after the end gave %v, %v", n, err)
	testing.expect_value(t, ctx.bytes_written, i64(len(inputs.text)))
	testing.expect_value(t, len(ctx.window), 0)
	testing.expect_value(t, io.destroy(s), nil)
	testing.expect(t, r.decoder.model_i == nil)
}

@(test)
ppmd_writer_identity :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)
	g := Lz4_Test_Lcg{state = 0x5ee3}
	text := lz4_test_lcg_text(&g, 100_000 if !SLIM_TESTS else 30_000)
	defer delete(text)

	Writer_Case :: struct {
		options:   compress.Options,
		split:     int,
		as_stream: bool,
	}
	buffer_1: [1]byte
	buffer_7: [7]byte
	cases := [?]Writer_Case{
		{{},                      1 << 20, false},
		{{},                      16,      true},
		{{chunk_size = 1},        5000,    false},
		{{buffer = buffer_7[:]},  300,     true},
		{{buffer = buffer_1[:]},  70_000,  false},
	}
	for input in ([][]byte{text, inputs.mixed, {}, {'x'}}) {
		for props in PPMD_STREAM_PROPS {
			for end_marker in ([]bool{false, true}) {
				want: [dynamic]byte
				defer delete(want)
				testing.expect_value(t, ppmd.compress(&want, input, props, end_marker), nil)
				for c in cases {
					got: [dynamic]byte
					defer delete(got)
					err := ppmd_writer_pack(input, props, end_marker, c.options, &got, c.split, c.as_stream)
					testing.expectf(t, err == nil && bytes.equal(got[:], want[:]), "%v, end marker %v, %v bytes, split %v, stream %v, buffer %v: %v, %v vs %v bytes", props, end_marker, len(input), c.split, c.as_stream, len(c.options.buffer), err, len(got), len(want))
				}
			}
		}
	}
}

@(test)
ppmd_writer_lifecycle :: proc(t: ^testing.T) {
	inputs := ppmd_test_inputs()
	defer ppmd_test_inputs_destroy(inputs)
	props := ppmd.Properties{variant = .H, order = 6, mem_size = 1 << 20}
	want: [dynamic]byte
	defer delete(want)
	testing.expect_value(t, ppmd.compress(&want, inputs.mixed, props), nil)

	{
		got: [dynamic]byte
		defer delete(got)
		aw := Append_Writer{out = &got, fail_at = -1}
		pw: ppmd.Writer
		defer ppmd.writer_destroy(&pw)
		testing.expect_value(t, ppmd.writer_init(&pw, append_writer(&aw), props), nil)
		s := ppmd.writer_to_stream(&pw)
		testing.expect_value(t, io.query(s), io.Stream_Mode_Set{.Write, .Close, .Destroy, .Query})
		n, err := io.write(s, inputs.mixed)
		testing.expectf(t, n == len(inputs.mixed) && err == nil, "stream write gave %v, %v", n, err)
		testing.expect_value(t, io.close(s), nil)
		testing.expect(t, bytes.equal(got[:], want[:]))
		testing.expect_value(t, ppmd.writer_finish(&pw), nil)
		wn, write_err := ppmd.writer_write(&pw, {1})
		testing.expectf(t, wn == 0 && write_err == io.Error.Closed, "write after finish gave %v, %v", wn, write_err)
		testing.expect_value(t, io.destroy(s), nil)
		testing.expect(t, pw.model_h == nil && pw.window == nil)
	}

	{
		got: [dynamic]byte
		defer delete(got)
		aw := Append_Writer{out = &got, fail_at = 100}
		pw: ppmd.Writer
		defer ppmd.writer_destroy(&pw)
		testing.expect_value(t, ppmd.writer_init(&pw, append_writer(&aw), props, options = {chunk_size = 64}), nil)
		err: compress.Error
		for i := 0; i < len(inputs.mixed) && err == nil; i += 1000 {
			_, err = ppmd.writer_write(&pw, inputs.mixed[i:min(i + 1000, len(inputs.mixed))])
		}
		testing.expect_value(t, err, io.Error.Short_Write)
		_, again := ppmd.writer_write(&pw, {1})
		testing.expect_value(t, again, io.Error.Short_Write)
		testing.expect_value(t, ppmd.writer_finish(&pw), io.Error.Short_Write)
		testing.expectf(t, len(got) == 100 && bytes.equal(got[:], want[:100]), "failing writer: %v bytes", len(got))
	}

	Init_Case :: struct {
		props:   ppmd.Properties,
		options: compress.Options,
		want:    compress.Error,
	}
	empty: [0]byte
	buffer: [10]byte
	init_cases := [?]Init_Case{
		{props, {max_output_size = -1},   compress.General_Error.Incompatible_Options},
		{props, {max_memory = -1},        compress.General_Error.Incompatible_Options},
		{props, {chunk_size = -1},        compress.General_Error.Incompatible_Options},
		{props, {progress_interval = -1}, compress.General_Error.Incompatible_Options},
		{props, {buffer = empty[:]},      compress.General_Error.Incompatible_Options},
		{props, {max_memory = int(props.mem_size) + ppmd.CHUNK_SIZE - 1}, compress.General_Error.Memory_Limit_Exceeded},
		{props, {max_memory = int(props.mem_size) + ppmd.CHUNK_SIZE},     nil},
		{props, {max_memory = int(props.mem_size), buffer = buffer[:]},   nil},
		{props, {max_memory = int(props.mem_size) - 1, buffer = buffer[:]}, compress.General_Error.Memory_Limit_Exceeded},
		{{variant = .I, order = 8, mem_size = 1 << 20, restore = .Freeze}, {}, compress.PPMd_Error.Unsupported_Restore_Method},
		{{variant = .H, order = 1, mem_size = 1 << 20}, {}, compress.PPMd_Error.Invalid_Properties},
	}
	for c in init_cases {
		pw: ppmd.Writer
		err := ppmd.writer_init(&pw, io.Writer{}, c.props, false, c.options)
		testing.expectf(t, err == c.want, "%v, %v: %v", c.props, c.options.max_memory, err)
		if c.want != nil {
			_, write_err := ppmd.writer_write(&pw, {1})
			testing.expectf(t, write_err == c.want, "%v: write after a failed init gave %v", c.props, write_err)
		}
		ppmd.writer_destroy(&pw)
	}
}

@(test)
ppmd_progress :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0x5ee4}
	text := lz4_test_lcg_text(&g, 50_000)
	defer delete(text)
	props := ppmd.Properties{variant = .I, order = 8, mem_size = 1 << 20, restore = .Restart}
	packed: [dynamic]byte
	defer delete(packed)
	testing.expect_value(t, ppmd.compress(&packed, text, props, true), nil)
	log: Ppmd_Progress_Log
	defer delete(log.calls)

	{
		output: [dynamic]byte
		defer delete(output)
		testing.expect_value(t, ppmd.decompress(&output, packed[:], props, len(text), ppmd_progress_options(&log, {progress_interval = 4096})), nil)
		testing.expect(t, bytes.equal(output[:], text))
		testing.expect_value(t, len(log.calls), len(text) / 4096)
		ppmd_progress_expect(t, "memory decode", log.calls[:], i64(len(packed)), i64(len(text)), i64(len(packed)), -1)
		for c, i in log.calls {
			testing.expectf(t, c.bytes_out == i64(i + 1) * 4096, "memory decode call %v: %v bytes out", i, c.bytes_out)
		}

		testing.expect_value(t, ppmd.decompress(&output, packed[:], props, -1, ppmd_progress_options(&log)), nil)
		testing.expect_value(t, len(log.calls), 0)
		testing.expect_value(t, ppmd.decompress(&output, packed[:], props, -1, ppmd_progress_options(&log, {progress_interval = 1})), nil)
		testing.expect_value(t, len(log.calls), len(text))
		ppmd_progress_expect(t, "memory decode unsized", log.calls[:], i64(len(packed)), -1, i64(len(packed)), -1)

		log.cancel_at = 3
		testing.expect_value(t, ppmd.decompress(&output, packed[:], props, len(text), ppmd_progress_options(&log, {progress_interval = 4096})), compress.General_Error.Canceled)
		testing.expect_value(t, len(output), 3 * 4096)
		testing.expect(t, bytes.equal(output[:], text[:3 * 4096]))
		log.cancel_at = 0
	}

	{
		output: [dynamic]byte
		defer delete(output)
		data := packed[:]
		ctx  := compress.init_context(&data)
		aw   := Append_Writer{out = &output, fail_at = -1}
		testing.expect_value(t, ppmd.decompress_to_writer(append_writer(&aw), &ctx, props, len(text), ppmd_progress_options(&log, {chunk_size = 5000})), nil)
		testing.expect(t, bytes.equal(output[:], text))
		testing.expect_value(t, len(log.calls), (len(text) + 4999) / 5000)
		ppmd_progress_expect(t, "writer decode", log.calls[:], i64(len(packed)), i64(len(text)), i64(len(packed)), -1)
		for c, i in log.calls {
			testing.expectf(t, c.bytes_out == min(i64(i + 1) * 5000, i64(len(text))), "writer decode call %v: %v bytes out", i, c.bytes_out)
		}

		clear(&output)
		log.cancel_at = 2
		data = packed[:]
		ctx  = compress.init_context(&data)
		testing.expect_value(t, ppmd.decompress_to_writer(append_writer(&aw), &ctx, props, len(text), ppmd_progress_options(&log, {chunk_size = 5000})), compress.General_Error.Canceled)
		testing.expect_value(t, len(output), 10_000)
		log.cancel_at = 0
	}

	{
		data := packed[:]
		ctx  := compress.init_context(&data)
		r: ppmd.Reader
		defer ppmd.reader_destroy(&r)
		testing.expect_value(t, ppmd.reader_init(&r, &ctx, props, -1, ppmd_progress_options(&log)), nil)
		buffer: [3000]byte
		total := 0
		for {
			n, err := ppmd.reader_read(&r, buffer[:])
			total += n
			if err != nil {
				testing.expect_value(t, err, io.Error.EOF)
				break
			}
		}
		testing.expect_value(t, total, len(text))
		testing.expect_value(t, len(log.calls), (len(text) + 2999) / 3000)
		ppmd_progress_expect(t, "reader", log.calls[:], i64(len(packed)), -1, i64(len(packed)), -1)
		for c, i in log.calls {
			testing.expectf(t, c.bytes_out == min(i64(i + 1) * 3000, i64(len(text))), "reader call %v: %v bytes out", i, c.bytes_out)
		}

		ppmd.reader_destroy(&r)
		log.cancel_at = 2
		data = packed[:]
		ctx  = compress.init_context(&data)
		testing.expect_value(t, ppmd.reader_init(&r, &ctx, props, -1, ppmd_progress_options(&log)), nil)
		n1, err1 := ppmd.reader_read(&r, buffer[:])
		n2, err2 := ppmd.reader_read(&r, buffer[:])
		n3, err3 := ppmd.reader_read(&r, buffer[:])
		testing.expectf(t, n1 == 3000 && err1 == nil && n2 == 3000 && err2 == nil && n3 == 0 && err3 == compress.General_Error.Canceled, "reader cancel: %v %v, %v %v, %v %v", n1, err1, n2, err2, n3, err3)
		log.cancel_at = 0
	}

	{
		got: [dynamic]byte
		defer delete(got)
		testing.expect_value(t, ppmd.compress(&got, text, props, true, ppmd_progress_options(&log, {progress_interval = 7000})), nil)
		testing.expect(t, bytes.equal(got[:], packed[:]))
		testing.expect_value(t, len(log.calls), (len(text) + 6999) / 7000)
		ppmd_progress_expect(t, "memory encode", log.calls[:], i64(len(text)), -1, i64(len(text)), i64(len(packed)))
		for c, i in log.calls {
			testing.expectf(t, c.bytes_in == min(i64(i + 1) * 7000, i64(len(text))), "memory encode call %v: %v bytes in", i, c.bytes_in)
		}

		slice := make([]byte, len(packed))
		defer delete(slice)
		n, slice_err := ppmd.compress(slice, text, props, true, ppmd_progress_options(&log))
		testing.expectf(t, slice_err == nil && n == len(packed) && bytes.equal(slice, packed[:]), "slice encode: %v, %v", slice_err, n)
		testing.expect_value(t, len(log.calls), 1)

		log.cancel_at = 2
		testing.expect_value(t, ppmd.compress(&got, text, props, true, ppmd_progress_options(&log, {progress_interval = 7000})), compress.General_Error.Canceled)
		testing.expect_value(t, len(got), 0)
		_, slice_err = ppmd.compress(slice, text, props, true, ppmd_progress_options(&log, {progress_interval = 7000}))
		testing.expect_value(t, slice_err, compress.General_Error.Canceled)
		log.cancel_at = 0

		testing.expect_value(t, ppmd.compress(&got, text, props, true, {progress_interval = -1}), compress.General_Error.Incompatible_Options)
		testing.expect_value(t, ppmd.compress(&got, text, props, true, {max_memory = int(props.mem_size) - 1}), compress.General_Error.Memory_Limit_Exceeded)
		testing.expect_value(t, ppmd.compress(&got, text, props, true, {max_output_size = len(packed) - 1}), compress.General_Error.Output_Too_Short)
		testing.expect_value(t, ppmd.compress(&got, text, props, true, {max_output_size = len(packed)}), nil)
		_, slice_err = ppmd.compress(slice, text, props, true, {max_output_size = len(packed) - 1})
		testing.expect_value(t, slice_err, compress.General_Error.Output_Too_Short)
	}

	{
		got: [dynamic]byte
		defer delete(got)
		err := ppmd_writer_pack(text, props, true, ppmd_progress_options(&log, {chunk_size = 1000}), &got, 3000, false)
		testing.expect_value(t, err, nil)
		testing.expect(t, bytes.equal(got[:], packed[:]))
		flushes := (len(packed) + 999) / 1000
		testing.expectf(t, len(log.calls) == flushes || len(log.calls) == flushes - 1, "writer encode: %v calls for %v bytes", len(log.calls), len(packed))
		ppmd_progress_expect(t, "writer encode", log.calls[:], -1, -1, i64(len(text)), i64(len(packed)))
		last := log.calls[len(log.calls) - 1]
		testing.expectf(t, last.bytes_in == i64(len(text)) && last.bytes_out == i64(len(packed)), "writer encode last call: %v", last)
		for c in log.calls[:len(log.calls) - 1] {
			testing.expectf(t, c.bytes_out % 1000 == 0, "writer encode: %v bytes out", c.bytes_out)
		}

		clear(&got)
		log.cancel_at = 2
		err = ppmd_writer_pack(text, props, true, ppmd_progress_options(&log, {chunk_size = 1000}), &got, 3000, false)
		testing.expect_value(t, err, compress.General_Error.Canceled)
		testing.expect_value(t, len(got), 2000)
		log.cancel_at = 0
	}
}

@(test)
ppmd_stream_fuzz :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = rand.uint64()}
	text := lz4_test_lcg_text(&g, 40_000)
	defer delete(text)
	trailer := PPMD_TEST_TRAILER

	for _ in 0..<PPMD_STREAM_FUZZ {
		props: ppmd.Properties
		props.variant = ppmd.Variant(rand.int_max(2))
		props.order   = u8(2 + rand.int_max(23 if props.variant == .H else 15))
		props.mem_size = u32(1) << uint(11 + rand.int_max(10))
		if props.variant == .I && rand.int_max(2) == 0 && props.mem_size >= ppmd.CUT_OFF_MEM_SIZE_MIN {
			props.restore = .Cut_Off
		}

		input: [dynamic]byte
		defer delete(input)
		for len(input) < 30_000 && rand.int_max(4) != 0 {
			switch rand.int_max(3) {
			case 0:
				start := rand.int_max(len(text))
				append(&input, ..text[start:][:rand.int_max(len(text) - start + 1)])
			case 1:
				for _ in 0..<rand.int_max(3000) {
					append(&input, u8(rand.uint32()))
				}
			case 2:
				b := u8(rand.uint32())
				for _ in 0..<rand.int_max(5000) {
					append(&input, b)
				}
			}
		}
		end_marker := rand.int_max(2) == 0

		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, ppmd.compress(&packed, input[:], props, end_marker), nil)

		split_options := compress.Options{chunk_size = 1 + rand.int_max(5000) if rand.int_max(2) == 0 else 0}
		written: [dynamic]byte
		defer delete(written)
		err := ppmd_writer_pack(input[:], props, end_marker, split_options, &written, 1 + rand.int_max(20_000), rand.int_max(2) == 0)
		testing.expectf(t, err == nil && bytes.equal(written[:], packed[:]), "fuzz writer, %v, end marker %v, %v bytes: %v, %v vs %v bytes", props, end_marker, len(input), err, len(written), len(packed))

		append(&packed, ..trailer[:])
		kind  := Stream_Kind(rand.int_max(len(Stream_Kind)))
		limit := compress.Options{max_output_size = 2 * len(input) + 1000}
		ppmd_stream_check(t, "fuzz", kind, packed[:], props, len(input), limit)
		if end_marker {
			ppmd_stream_check(t, "fuzz unsized", kind, packed[:], props, -1, limit)
		}

		mutated: [dynamic]byte
		defer delete(mutated)
		append(&mutated, ..packed[:])
		switch rand.int_max(3) {
		case 0:
			resize(&mutated, rand.int_max(len(mutated) + 1))
		case:
			for _ in 0..<1 + rand.int_max(3) {
				mutated[rand.int_max(len(mutated))] ~= u8(1 + rand.int_max(255))
			}
		}
		expected := -1
		switch rand.int_max(3) {
		case 0: expected = len(input)
		case 1: expected = rand.int_max(len(input) + 2)
		}
		ppmd_stream_check(t, "fuzz mutated", kind, mutated[:], props, expected, limit)
		free_all(context.temp_allocator)
	}
}

ppmd_progress_expect :: proc(t: ^testing.T, label: string, calls: []compress.Progress, total_in, total_out, max_in, max_out: i64) {
	prev: compress.Progress
	for c, i in calls {
		testing.expectf(t, c.total_in == total_in && c.total_out == total_out, "%v call %v: totals %v, %v, want %v, %v", label, i, c.total_in, c.total_out, total_in, total_out)
		testing.expectf(t, c.member == "" && c.member_index == -1 && c.member_count == -1 && c.archive_in == 0 && c.archive_total_in == -1, "%v call %v: archive fields %v", label, i, c)
		testing.expectf(t, c.bytes_in >= prev.bytes_in && c.bytes_out >= prev.bytes_out, "%v call %v: not monotonic, %v after %v", label, i, c, prev)
		testing.expectf(t, c.bytes_in <= max_in && (max_out < 0 || c.bytes_out <= max_out), "%v call %v: past the end, %v", label, i, c)
		prev = c
	}
}

ppmd_writer_pack :: proc(input: []byte, props: ppmd.Properties, end_marker: bool, options: compress.Options, output: ^[dynamic]byte, split_max: int, as_stream: bool) -> (err: compress.Error) {
	aw := Append_Writer{out = output, fail_at = -1}
	pw := new(ppmd.Writer)
	defer free(pw)
	defer ppmd.writer_destroy(pw)
	ppmd.writer_init(pw, append_writer(&aw), props, end_marker, options) or_return
	s := ppmd.writer_to_stream(pw)
	pos := 0
	for pos < len(input) {
		size := min(len(input) - pos, 1 + rand.int_max(split_max))
		n: int
		if as_stream {
			io_err: io.Error
			n, io_err = io.write(s, input[pos:][:size])
			if io_err != nil {
				return pw.err
			}
		} else {
			n = ppmd.writer_write(pw, input[pos:][:size]) or_return
		}
		pos += n
	}
	if as_stream {
		if io.close(s) != nil {
			return pw.err
		}
		return nil
	}
	return ppmd.writer_finish(pw)
}

ppmd_stream_memory_unpack :: proc(kind: Stream_Kind, input: []byte, output: ^[dynamic]byte, props: ppmd.Properties, expected: int, options: compress.Options, rest: ^[5]byte) -> (err: compress.Error, rest_err: io.Error, bytes_written: i64) {
	input := input
	br: bytes.Reader
	tr: Trickle_Reader
	ctx := stream_test_context(kind, &input, &br, &tr, output)
	defer compress.destroy_context(&ctx)
	err = ppmd.decompress(&ctx, props, expected, options)
	bytes_written = ctx.bytes_written
	if err == nil {
		rest_err = compress.read_slice(&ctx, rest[:])
	}
	return
}

ppmd_stream_unpack :: proc(sink: Sink, kind: Stream_Kind, input: []byte, output: ^[dynamic]byte, props: ppmd.Properties, expected: int, options: compress.Options, rest: ^[5]byte) -> (err: compress.Error, rest_err: io.Error, bytes_written: i64) {
	input := input
	br: bytes.Reader
	tr: Trickle_Reader
	ctx := stream_test_context(kind, &input, &br, &tr)
	defer compress.destroy_context(&ctx)

	switch sink {
	case .Writer:
		aw := Append_Writer{out = output, fail_at = -1}
		err = ppmd.decompress_to_writer(append_writer(&aw), &ctx, props, expected, options)

	case .Reader, .Reader_Stream:
		buffer := make([]byte, 70_000)
		defer delete(buffer)
		r := new(ppmd.Reader)
		defer free(r)
		err = ppmd.reader_init(r, &ctx, props, expected, options)
		stream := ppmd.reader_to_stream(r)
		for err == nil {
			size := 1 + rand.int_max(16 if rand.int_max(2) == 0 else len(buffer))
			n: int
			if sink == .Reader {
				n, err = ppmd.reader_read(r, buffer[:size])
			} else {
				io_err: io.Error
				n, io_err = io.read(stream, buffer[:size])
				err = io_err if io_err == .EOF || io_err == nil else r.err
			}
			append(output, ..buffer[:n])
		}
		if err == io.Error.EOF {
			err = nil
		}
		if sink == .Reader_Stream {
			io.destroy(stream)
		} else {
			ppmd.reader_destroy(r)
		}
	}
	bytes_written = ctx.bytes_written
	if err == nil {
		rest_err = compress.read_slice(&ctx, rest[:])
	}
	return
}

ppmd_stream_check :: proc(t: ^testing.T, label: string, kind: Stream_Kind, input: []byte, props: ppmd.Properties, expected := -1, options := compress.Options{}) {
	want: [dynamic]byte
	defer delete(want)
	want_rest: [5]byte
	memory_err, want_rest_err, want_written := ppmd_stream_memory_unpack(kind, input, &want, props, expected, options, &want_rest)
	testing.expectf(t, want_written == i64(len(want)), "%v, %v, memory: bytes_written %v for %v bytes", label, kind, want_written, len(want))

	for sink in Sink {
		opts := options
		if opts.chunk_size == 0 && opts.buffer == nil {
			opts.chunk_size = sinks_chunk(len(want))
		}
		got: [dynamic]byte
		defer delete(got)
		rest: [5]byte
		err, rest_err, bytes_written := ppmd_stream_unpack(sink, kind, input, &got, props, expected, opts, &rest)
		testing.expectf(t, err == memory_err, "%v, %v, %v, %v, chunk %v: %v, memory gave %v", label, props, kind, sink, opts.chunk_size, err, memory_err)
		testing.expectf(t, bytes.equal(got[:], want[:]), "%v, %v, %v, %v, chunk %v: output differs, %v vs %v bytes (%v)", label, props, kind, sink, opts.chunk_size, len(got), len(want), err)
		testing.expectf(t, bytes_written == i64(len(got)), "%v, %v, %v, %v, chunk %v: bytes_written %v for %v bytes", label, props, kind, sink, opts.chunk_size, bytes_written, len(got))
		if err == nil {
			testing.expectf(t, rest == want_rest && rest_err == want_rest_err, "%v, %v, %v, %v, chunk %v: input after the stream %v, %v vs %v, %v", label, props, kind, sink, opts.chunk_size, rest, rest_err, want_rest, want_rest_err)
		}
	}
}
