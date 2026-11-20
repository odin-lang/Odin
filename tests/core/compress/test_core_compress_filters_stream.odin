package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/filters"
import "core:compress/lzma"
import "core:io"
import "core:math/rand"
import "core:testing"

Filters_Stall_Reader :: struct {
	calls: int,
	err:   io.Error,
}

filters_stall_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Filters_Stall_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		r.calls += 1
		return 0, r.err
	case .Query:
		return io.query_utility({.Read, .Query})
	}
	return 0, .Unsupported
}

filters_test_configs :: proc() -> (configs: [dynamic]filters.Filter) {
	for arch in filters.Branch_Arch {
		append(&configs, filters.Branch_Filter{arch = arch, start_offset = FILTERS_TEST_PC})
		append(&configs, filters.Branch_Filter{arch = arch, start_offset = u32(0) - u32(filters.BRANCH_ALIGNMENT[arch] * 16)})
	}
	for distance in ([?]int{1, 2, 7, 16, 255, 256}) {
		append(&configs, filters.Delta_Filter{distance = distance})
	}
	append(&configs, filters.Swap_Filter.Swap2, filters.Swap_Filter.Swap4)
	return
}

filters_test_one_shot :: proc(data: []byte, filter: filters.Filter, direction: filters.Direction) {
	switch f in filter {
	case filters.Branch_Filter:
		st: filters.Branch_State
		filters.branch_init(&st, f.arch, f.start_offset)
		if direction == .Encode {
			filters.branch_encode(&st, data)
		} else {
			filters.branch_decode(&st, data)
		}
	case filters.Delta_Filter:
		st: filters.Delta_State
		filters.delta_init(&st, f.distance)
		if direction == .Encode {
			filters.delta_encode(&st, data)
		} else {
			filters.delta_decode(&st, data)
		}
	case filters.Swap_Filter:
		if f == .Swap2 {
			filters.swap2(data)
		} else {
			filters.swap4(data)
		}
	}
}

filters_test_options :: proc(scratch: []byte, minimum: int) -> (options: compress.Options) {
	switch rand.int_max(4) {
	case 0:
	case 1:
		options.chunk_size = minimum + rand.int_max(64)
	case 2:
		options.chunk_size = 1 + rand.int_max(10_000)
	case 3:
		options.buffer = scratch[:minimum + rand.int_max(len(scratch) - minimum + 1)]
	}
	return
}

filters_test_read_all :: proc(r: io.Reader, out: ^[dynamic]byte) -> (err: io.Error) {
	buf: [3000]byte
	for {
		n, read_err := io.read(r, buf[:1 + rand.int_max(len(buf))])
		append(out, ..buf[:n])
		if read_err == .EOF {
			return nil
		}
		if read_err != nil {
			return read_err
		}
	}
}

@(test)
filters_stream_split :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)
	configs := filters_test_configs()
	defer delete(configs)
	scratch: [4096]byte

	for input in ([?][]byte{inputs.mixed, inputs.calls[:777], nil}) {
		for filter in configs {
			for direction in filters.Direction {
				want := make([]byte, len(input))
				defer delete(want)
				copy(want, input)
				filters_test_one_shot(want, filter, direction)

				source := Trickle_Reader{data = input, chunk = 1 + rand.int_max(5000)}
				r: filters.Reader
				if !testing.expect_value(t, filters.reader_init(&r, trickle_stream(&source), filter, direction, filters_test_options(scratch[:], filters.FILTER_BUFFER_MIN)), nil) {
					continue
				}
				got: [dynamic]byte
				defer delete(got)
				read_err := filters_test_read_all(filters.reader_to_stream(&r), &got)
				filters.reader_destroy(&r)
				testing.expectf(t, read_err == nil && bytes.equal(got[:], want), "reader %v %v: %v, %v of %v bytes", filter, direction, read_err, len(got), len(want))

				sink: [dynamic]byte
				defer delete(sink)
				aw := Append_Writer{out = &sink, fail_at = -1}
				w: filters.Writer
				if !testing.expect_value(t, filters.writer_init(&w, append_writer(&aw), filter, direction, filters_test_options(scratch[:], filters.FILTER_BUFFER_MIN)), nil) {
					continue
				}
				ws  := filters.writer_to_stream(&w)
				pos := 0
				for pos < len(input) {
					step := min(len(input) - pos, rand.int_max(3000))
					n, write_err := io.write(ws, input[pos:][:step])
					testing.expect(t, write_err == nil && n == step)
					pos += step
				}
				testing.expect_value(t, io.close(ws), nil)
				testing.expect_value(t, filters.writer_finish(&w), nil)
				_, closed := filters.writer_write(&w, input)
				testing.expect_value(t, closed, io.Error.Closed)
				filters.writer_destroy(&w)
				testing.expectf(t, bytes.equal(sink[:], want), "writer %v %v: %v of %v bytes", filter, direction, len(sink), len(want))
			}
		}
	}
}

@(test)
filters_stream_options :: proc(t: ^testing.T) {
	data := [64]byte{}
	source := Trickle_Reader{data = data[:], chunk = 64}
	r: filters.Reader
	w: filters.Writer
	sink: [dynamic]byte
	defer delete(sink)
	aw := Append_Writer{out = &sink, fail_at = -1}
	Bad :: struct {
		filter:    filters.Filter,
		direction: filters.Direction,
		options:   compress.Options,
		err:       compress.Error,
	}
	small: [filters.FILTER_BUFFER_MIN - 1]byte
	cases := [?]Bad{
		{nil, .Decode, {}, compress.General_Error.Incompatible_Options},
		{filters.Branch_Filter{arch = filters.Branch_Arch(8)}, .Decode, {}, compress.General_Error.Incompatible_Options},
		{filters.Branch_Filter{arch = .ARM, start_offset = 2}, .Decode, {}, compress.General_Error.Incompatible_Options},
		{filters.Delta_Filter{distance = 0}, .Decode, {}, compress.General_Error.Incompatible_Options},
		{filters.Delta_Filter{distance = 257}, .Decode, {}, compress.General_Error.Incompatible_Options},
		{filters.Swap_Filter(2), .Decode, {}, compress.General_Error.Incompatible_Options},
		{filters.Swap_Filter.Swap2, filters.Direction(2), {}, compress.General_Error.Incompatible_Options},
		{filters.Swap_Filter.Swap2, .Decode, {chunk_size = -1}, compress.General_Error.Incompatible_Options},
		{filters.Swap_Filter.Swap2, .Decode, {max_memory = -1}, compress.General_Error.Incompatible_Options},
		{filters.Swap_Filter.Swap2, .Decode, {buffer = small[:]}, compress.General_Error.Incompatible_Options},
		{filters.Swap_Filter.Swap2, .Decode, {chunk_size = 1 << 20, max_memory = 1 << 10}, compress.General_Error.Memory_Limit_Exceeded},
	}
	for c in cases {
		testing.expectf(t, filters.reader_init(&r, trickle_stream(&source), c.filter, c.direction, c.options) == c.err, "reader %v %v %v", c.filter, c.direction, c.options)
		testing.expect_value(t, r.err, c.err)
		filters.reader_destroy(&r)
		testing.expectf(t, filters.writer_init(&w, append_writer(&aw), c.filter, c.direction, c.options) == c.err, "writer %v %v %v", c.filter, c.direction, c.options)
		_, err := filters.writer_write(&w, data[:])
		testing.expect_value(t, err, c.err)
		filters.writer_destroy(&w)
	}

	stall := Filters_Stall_Reader{}
	testing.expect_value(t, filters.reader_init(&r, io.Stream{procedure = filters_stall_proc, data = &stall}, filters.Swap_Filter.Swap4), nil)
	buf: [8]byte
	n, err := filters.reader_read(&r, buf[:])
	testing.expect(t, n == 0 && err == io.Error.No_Progress, "stalled source gives No_Progress")
	n, err = filters.reader_read(&r, buf[:])
	testing.expect(t, n == 0 && err == io.Error.No_Progress, "the error sticks")
	filters.reader_destroy(&r)

	broken := Filters_Stall_Reader{err = .Unknown}
	testing.expect_value(t, filters.reader_init(&r, io.Stream{procedure = filters_stall_proc, data = &broken}, filters.Swap_Filter.Swap4), nil)
	n, err = filters.reader_read(&r, buf[:])
	testing.expect(t, n == 0 && err == io.Error.Unknown && broken.calls == 1, "source errors pass through")
	filters.reader_destroy(&r)

	source = {data = data[:5], chunk = 64}
	testing.expect_value(t, filters.reader_init(&r, trickle_stream(&source), filters.Swap_Filter.Swap4), nil)
	n, err = filters.reader_read(&r, buf[:0])
	testing.expect(t, n == 0 && err == nil, "empty read")
	n, err = filters.reader_read(&r, buf[:])
	testing.expect(t, n == 5 && err == nil, "short tail passes through")
	n, err = filters.reader_read(&r, buf[:])
	testing.expect(t, n == 0 && err == io.Error.EOF, "then EOF")
	filters.reader_destroy(&r)

	clear(&sink)
	failing := Append_Writer{out = &sink, fail_at = 10}
	testing.expect_value(t, filters.writer_init(&w, append_writer(&failing), filters.Swap_Filter.Swap2, .Encode, {chunk_size = 1}), nil)
	_, err = filters.writer_write(&w, data[:])
	testing.expect_value(t, err, io.Error.Short_Write)
	testing.expect_value(t, filters.writer_finish(&w), io.Error.Short_Write)
	filters.writer_destroy(&w)
}

@(test)
filters_stream_lzma2_chain :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)
	input  := inputs.calls
	filter := filters.Branch_Filter{arch = .X86, start_offset = FILTERS_TEST_PC}

	encoded: [dynamic]byte
	defer delete(encoded)
	lw: lzma.Writer
	props, init_err := lzma.writer_init_lzma2(&lw, append_writer(&Append_Writer{out = &encoded, fail_at = -1}), lzma.level_options(.Default))
	if !testing.expect_value(t, init_err, nil) {
		return
	}
	fw: filters.Writer
	testing.expect_value(t, filters.writer_init(&fw, lzma.writer_to_stream(&lw), filter), nil)
	pos := 0
	for pos < len(input) {
		step := min(len(input) - pos, 1 + rand.int_max(4000))
		_, err := filters.writer_write(&fw, input[pos:][:step])
		testing.expect_value(t, err, nil)
		pos += step
	}
	testing.expect_value(t, filters.writer_finish(&fw), nil)
	testing.expect_value(t, lzma.writer_finish(&lw), nil)
	filters.writer_destroy(&fw)
	lzma.writer_destroy(&lw)

	filtered := make([]byte, len(input))
	defer delete(filtered)
	copy(filtered, input)
	filters_test_one_shot(filtered, filter, .Encode)
	plain: [dynamic]byte
	defer delete(plain)
	testing.expect_value(t, lzma.decompress_lzma2_from_bytes(&plain, encoded[:], props.dict_size), nil)
	testing.expect(t, bytes.equal(plain[:], filtered), "the filter writer feeds the LZMA2 writer")

	packed := encoded[:]
	ctx    := compress.init_context_from_slice(&packed)
	lr: lzma.Reader
	testing.expect_value(t, lzma.reader_init_lzma2(&lr, &ctx, props.dict_size), nil)
	fr: filters.Reader
	testing.expect_value(t, filters.reader_init(&fr, lzma.reader_to_stream(&lr), filter, .Decode, {chunk_size = 999}), nil)
	pulled: [dynamic]byte
	defer delete(pulled)
	testing.expect_value(t, filters_test_read_all(filters.reader_to_stream(&fr), &pulled), nil)
	filters.reader_destroy(&fr)
	lzma.reader_destroy(&lr)
	testing.expect(t, bytes.equal(pulled[:], input), "the filter reader pulls from the LZMA2 reader")

	pushed: [dynamic]byte
	defer delete(pushed)
	pw: filters.Writer
	testing.expect_value(t, filters.writer_init(&pw, append_writer(&Append_Writer{out = &pushed, fail_at = -1}), filter, .Decode), nil)
	push_ctx := compress.init_context_from_slice(&packed)
	testing.expect_value(t, lzma.decompress_lzma2_to_writer(filters.writer_to_stream(&pw), &push_ctx, props.dict_size, -1, {chunk_size = 1000}), nil)
	testing.expect_value(t, filters.writer_finish(&pw), nil)
	filters.writer_destroy(&pw)
	testing.expect(t, bytes.equal(pushed[:], input), "the LZMA2 decoder pushes into a decoding filter writer")
}

filters_test_bcj2_stream_decode :: proc(streams: [4][]byte, scratch: []byte, out: ^[dynamic]byte) -> (err: compress.Error) {
	sources: [4]Trickle_Reader
	readers: [4]io.Reader
	for &s, i in sources {
		s = {data = streams[i], chunk = 1 + rand.int_max(3000)}
		readers[i] = trickle_stream(&s)
	}
	r: filters.Bcj2_Reader
	filters.bcj2_reader_init(&r, readers[0], readers[1], readers[2], readers[3], filters_test_options(scratch, filters.BCJ2_BUFFER_MIN)) or_return
	defer filters.bcj2_reader_destroy(&r)
	if read_err := filters_test_read_all(filters.bcj2_reader_to_stream(&r), out); read_err != nil {
		return r.err
	}
	return nil
}

@(test)
filters_bcj2_stream_split :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)
	scratch: [4096]byte
	edge := [12]byte{0xE8, 0x10, 0, 0, 0, 0x0F, 0x85, 0x20, 0, 0, 0, 0xE9}

	cases: [dynamic][]byte
	defer delete(cases)
	append(&cases, inputs.mixed, inputs.calls)
	for n in 0..=len(edge) {
		append(&cases, edge[:n])
	}
	for input in cases {
		for ref in FILTERS_BCJ2_REFERENCES {
			want: filters.Bcj2_Streams
			defer filters_test_bcj2_destroy(&want)
			testing.expect_value(t, filters.bcj2_encode(&want, input, ref.relat_limit, ref.file_size), nil)
			wants := [4][]byte{want.main[:], want.call[:], want.jump[:], want.rc[:]}

			sinks: [4][dynamic]byte
			defer for s in sinks {
				delete(s)
			}
			writers: [4]Append_Writer
			for &w, i in writers {
				w = {out = &sinks[i], fail_at = -1}
			}
			bw: filters.Bcj2_Writer
			testing.expect_value(t, filters.bcj2_writer_init(&bw, append_writer(&writers[0]), append_writer(&writers[1]), append_writer(&writers[2]), append_writer(&writers[3]), ref.relat_limit, ref.file_size, filters_test_options(scratch[:], filters.BCJ2_BUFFER_MIN)), nil)
			ws  := filters.bcj2_writer_to_stream(&bw)
			pos := 0
			for pos < len(input) {
				step := min(len(input) - pos, rand.int_max(3000))
				n, write_err := io.write(ws, input[pos:][:step])
				testing.expect(t, write_err == nil && n == step)
				pos += step
			}
			testing.expect_value(t, io.close(ws), nil)
			testing.expect_value(t, filters.bcj2_writer_finish(&bw), nil)
			_, closed := filters.bcj2_writer_write(&bw, input)
			testing.expect_value(t, closed, io.Error.Closed)
			for s in filters.Bcj2_Stream {
				i := int(s)
				testing.expectf(t, bytes.equal(sinks[i][:], wants[i]) && bw.written[s] == i64(len(wants[i])), "%v bytes, limit %x, size %v: stream %v is %v bytes, want %v", len(input), ref.relat_limit, ref.file_size, s, len(sinks[i]), len(wants[i]))
			}
			filters.bcj2_writer_destroy(&bw)

			got: [dynamic]byte
			defer delete(got)
			err := filters_test_bcj2_stream_decode(wants, scratch[:], &got)
			testing.expectf(t, err == nil && bytes.equal(got[:], input), "%v bytes, limit %x, size %v: decode returned %v, %v bytes", len(input), ref.relat_limit, ref.file_size, err, len(got))
		}
	}
}

@(test)
filters_bcj2_stream_corrupt :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)
	scratch: [4096]byte

	streams: filters.Bcj2_Streams
	defer filters_test_bcj2_destroy(&streams)
	testing.expect_value(t, filters.bcj2_encode(&streams, inputs.calls[:4000]), nil)
	originals := [4][]byte{streams.main[:], streams.call[:], streams.jump[:], streams.rc[:]}

	extra: [4][dynamic]byte
	defer for e in extra {
		delete(e)
	}
	for &e, i in extra {
		append(&e, ..originals[i])
		append(&e, 0)
	}
	Case :: struct {
		streams: [4][]byte,
		err:     compress.Error,
	}
	rc := originals[3]
	bad_header := [5]byte{1, 0, 0, 0, 0}
	all_ones   := [5]byte{0, 0xFF, 0xFF, 0xFF, 0xFF}
	cases := [?]Case{
		{{originals[0], originals[1], originals[2], rc[:4]}, compress.General_Error.Stream_Too_Short},
		{{originals[0], originals[1], originals[2], bad_header[:]}, compress.BCJ2_Error.Corrupt_Data},
		{{originals[0], originals[1], originals[2], all_ones[:]}, compress.BCJ2_Error.Corrupt_Data},
		{{originals[0], originals[1][:len(originals[1]) - 1], originals[2], rc}, compress.BCJ2_Error.Corrupt_Data},
		{{originals[0], originals[1], originals[2][:len(originals[2]) - 4], rc}, compress.BCJ2_Error.Corrupt_Data},
		{{originals[0], extra[1][:], originals[2], rc}, compress.BCJ2_Error.Corrupt_Data},
		{{originals[0], originals[1], extra[2][:], rc}, compress.BCJ2_Error.Corrupt_Data},
		{{originals[0], originals[1], originals[2], extra[3][:]}, compress.BCJ2_Error.Corrupt_Data},
		{{originals[0], originals[1], originals[2], rc[:len(rc) - 1]}, nil},
	}
	for c, index in cases {
		one_shot: [dynamic]byte
		defer delete(one_shot)
		want := c.err
		if want == nil {
			want = filters.bcj2_decode(&one_shot, c.streams[0], c.streams[1], c.streams[2], c.streams[3])
			testing.expectf(t, want != nil, "case %v: one-shot accepts", index)
		}
		got: [dynamic]byte
		defer delete(got)
		testing.expectf(t, filters_test_bcj2_stream_decode(c.streams, scratch[:], &got) == want, "case %v: want %v", index, want)
	}

	copies := [4][]byte{make([]byte, len(originals[0])), make([]byte, len(originals[1])), make([]byte, len(originals[2])), make([]byte, len(originals[3]))}
	defer for c in copies {
		delete(c)
	}
	for _ in 0..<200 {
		mutated: [4][]byte
		for c, i in copies {
			copy(c, originals[i])
			mutated[i] = c
		}
		which := rand.int_max(4)
		c := copies[which]
		if len(c) == 0 {
			continue
		}
		if rand.int_max(4) == 0 {
			mutated[which] = c[:rand.int_max(len(c))]
		} else {
			c[rand.int_max(len(c))] ~= u8(1) << uint(rand.int_max(8))
		}
		want: [dynamic]byte
		defer delete(want)
		want_err := filters.bcj2_decode(&want, mutated[0], mutated[1], mutated[2], mutated[3])
		got: [dynamic]byte
		defer delete(got)
		got_err := filters_test_bcj2_stream_decode(mutated, scratch[:], &got)
		testing.expectf(t, got_err == want_err, "stream %v: one-shot %v, streamed %v", which, want_err, got_err)
		if want_err == nil {
			testing.expect(t, bytes.equal(got[:], want[:]))
		}
	}
}

@(test)
filters_bcj2_stream_options :: proc(t: ^testing.T) {
	sink: [dynamic]byte
	defer delete(sink)
	aw := Append_Writer{out = &sink, fail_at = -1}
	sw := append_writer(&aw)
	small: [filters.BCJ2_BUFFER_MIN - 1]byte

	bw: filters.Bcj2_Writer
	testing.expect_value(t, filters.bcj2_writer_init(&bw, sw, sw, sw, sw, filters.BCJ2_RELAT_LIMIT_MAX + 1), compress.General_Error.Incompatible_Options)
	filters.bcj2_writer_destroy(&bw)
	testing.expect_value(t, filters.bcj2_writer_init(&bw, sw, sw, sw, sw, options = {buffer = small[:]}), compress.General_Error.Incompatible_Options)
	_, err := filters.bcj2_writer_write(&bw, small[:])
	testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
	testing.expect_value(t, filters.bcj2_writer_finish(&bw), compress.General_Error.Incompatible_Options)
	filters.bcj2_writer_destroy(&bw)
	testing.expect_value(t, filters.bcj2_writer_init(&bw, sw, sw, sw, sw, options = {chunk_size = -1}), compress.General_Error.Incompatible_Options)
	filters.bcj2_writer_destroy(&bw)
	testing.expect_value(t, filters.bcj2_writer_init(&bw, sw, sw, sw, sw, options = {chunk_size = 1 << 20, max_memory = 1 << 10}), compress.General_Error.Memory_Limit_Exceeded)
	filters.bcj2_writer_destroy(&bw)
	testing.expect_value(t, filters.bcj2_writer_init(&bw, sw, sw, sw, sw, options = {chunk_size = max(int)}), compress.General_Error.Memory_Limit_Exceeded)
	filters.bcj2_writer_destroy(&bw)

	failing := Append_Writer{out = &sink, fail_at = 3}
	testing.expect_value(t, filters.bcj2_writer_init(&bw, sw, sw, sw, append_writer(&failing)), nil)
	testing.expect_value(t, filters.bcj2_writer_finish(&bw), io.Error.Short_Write)
	testing.expect_value(t, filters.bcj2_writer_finish(&bw), io.Error.Short_Write)
	filters.bcj2_writer_destroy(&bw)

	source := Trickle_Reader{chunk = 1}
	rs := trickle_stream(&source)
	r: filters.Bcj2_Reader
	testing.expect_value(t, filters.bcj2_reader_init(&r, rs, rs, rs, rs, {buffer = small[:]}), compress.General_Error.Incompatible_Options)
	buf: [4]byte
	n, read_err := filters.bcj2_reader_read(&r, buf[:])
	testing.expect(t, n == 0 && read_err == compress.General_Error.Incompatible_Options)
	filters.bcj2_reader_destroy(&r)
	testing.expect_value(t, filters.bcj2_reader_init(&r, rs, rs, rs, rs, {chunk_size = max(int)}), compress.General_Error.Memory_Limit_Exceeded)
	filters.bcj2_reader_destroy(&r)

	stall := Filters_Stall_Reader{}
	ss := io.Stream{procedure = filters_stall_proc, data = &stall}
	testing.expect_value(t, filters.bcj2_reader_init(&r, ss, ss, ss, ss), nil)
	n, read_err = filters.bcj2_reader_read(&r, buf[:0])
	testing.expect(t, n == 0 && read_err == nil && stall.calls == 0, "an empty read does nothing")
	n, read_err = filters.bcj2_reader_read(&r, buf[:])
	testing.expect(t, n == 0 && read_err == io.Error.No_Progress, "stalled rc stream gives No_Progress")
	filters.bcj2_reader_destroy(&r)

	streams: filters.Bcj2_Streams
	defer filters_test_bcj2_destroy(&streams)
	testing.expect_value(t, filters.bcj2_encode(&streams, nil), nil)
	sources := [4]Trickle_Reader{{data = streams.main[:], chunk = 1}, {data = streams.call[:], chunk = 1}, {data = streams.jump[:], chunk = 1}, {data = streams.rc[:], chunk = 1}}
	testing.expect_value(t, filters.bcj2_reader_init(&r, trickle_stream(&sources[0]), trickle_stream(&sources[1]), trickle_stream(&sources[2]), trickle_stream(&sources[3])), nil)
	n, read_err = filters.bcj2_reader_read(&r, buf[:])
	testing.expect(t, n == 0 && read_err == io.Error.EOF, "empty streams decode to EOF")
	n, read_err = filters.bcj2_reader_read(&r, buf[:])
	testing.expect(t, n == 0 && read_err == io.Error.EOF, "EOF repeats")
	filters.bcj2_reader_destroy(&r)
}
