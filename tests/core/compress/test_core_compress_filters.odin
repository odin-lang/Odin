package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/filters"
import "core:hash"
import "core:math/rand"
import "core:testing"

FILTERS_TEST_BYTES := [?]u8{0x00, 0xFF, 0xE8, 0xE9, 0x0F, 0x80, 0x48, 0x4B, 0xEB, 0xF0, 0xF8, 0x94, 0x97, 0x90, 0x40, 0x7F, 0x01, 0x03, 0x17, 0x6F, 0xEF, 0x10, 0x12, 0x16}

FILTERS_TEST_PC :: u32(0x1000)

Filters_Branch_Reference :: struct {
	arch:       filters.Branch_Arch,
	encoded:    int,
	encode_crc: u32,
	decoded:    int,
	decode_crc: u32,
}

FILTERS_BRANCH_REFERENCES := []Filters_Branch_Reference{
	{.X86,       65545, 0xea388d35, 65545, 0x9a9de3ed},
	{.PowerPC,   65548, 0x14d0e4bf, 65548, 0xab2aa8e8},
	{.IA64,      65536, 0x68f84c1e, 65536, 0xc3334c39},
	{.ARM,       65548, 0xe03d6863, 65548, 0x53522070},
	{.ARM_Thumb, 65546, 0x4028de1f, 65546, 0x623ddcf8},
	{.SPARC,     65548, 0x1134dd5e, 65548, 0x3fa01707},
	{.ARM64,     65548, 0xff3f1ba2, 65548, 0x33de1863},
	{.RISCV,     65544, 0xba2f4292, 65544, 0x7e269795},
}

Filters_Bcj2_Reference :: struct {
	calls:       bool,
	relat_limit: u32,
	file_size:   i64,
	streams:     [4]struct {
		size: int,
		crc:  u32,
	},
}

FILTERS_BCJ2_REFERENCES := []Filters_Bcj2_Reference{
	{false, 0x0f000000, -1,    {{63057, 0x2e729b58}, {1232, 0xfb59bf2a}, {1260, 0xcfb525b8}, {341, 0xb6e17321}}},
	{false, 0x80000000, -1,    {{53749, 0xea412e5b}, {5832, 0xf0ecb56b}, {5968, 0x213c01f7}, {131, 0x94ae1cec}}},
	{true,  0x0f000000, -1,    {{20773, 0x7f129a42}, {9568, 0xa5994f33}, {9660, 0x34e9c63a}, {261, 0xfc87a21e}}},
	{true,  0x80000000, -1,    {{20637, 0x636374f5}, {9588, 0x3b82c4ab}, {9776, 0x5801bb6e}, {215, 0x471c165f}}},
	{true,  0x00001000, -1,    {{38169, 0x993a3f5d}, {820, 0x74ea9197}, {1012, 0x94f509d4}, {402, 0xc57e2ccc}}},
	{true,  0x00000000, -1,    {{40001, 0x1b9ddbeb}, {0, 0x00000000}, {0, 0x00000000}, {222, 0x128868f3}}},
	{true,  0x0f000000, 20000, {{35161, 0xe2d63f21}, {2388, 0x95e719cb}, {2452, 0x066ffaad}, {545, 0xef2962ab}}},
	{true,  0x0f000000, 0,     {{20773, 0x7f129a42}, {9568, 0xa5994f33}, {9660, 0x34e9c63a}, {261, 0xfc87a21e}}},
}

Filters_Test_Inputs :: struct {
	mixed: []byte,
	calls: []byte,
}

filters_test_inputs :: proc() -> (inputs: Filters_Test_Inputs) {
	g := Lz4_Test_Lcg{state = 0x46494c54}
	inputs.mixed = make([]byte, 65_549)
	for &b in inputs.mixed {
		x := lz4_test_lcg_next(&g)
		b = FILTERS_TEST_BYTES[(x >> 8) % len(FILTERS_TEST_BYTES)] if x & 0xFF < 160 else u8(x >> 24)
	}

	size := 40_001
	inputs.calls = make([]byte, size)
	data := inputs.calls
	i := 0
	for i < size {
		x := lz4_test_lcg_next(&g)
		kind := x & 15
		if kind > 3 || i + 6 > size {
			data[i] = u8(x >> 24)
			i += 1
			continue
		}
		switch kind {
		case 0, 1:
			data[i] = 0xE8
			i += 1
		case 2:
			data[i] = 0xE9
			i += 1
		case 3:
			data[i]     = 0x0F
			data[i + 1] = 0x80 | u8((x >> 8) & 0xF)
			i += 2
		}
		rel := u32(i32(lz4_test_lcg_next(&g) % u32(2 * size)) - i32(size))
		data[i]     = u8(rel)
		data[i + 1] = u8(rel >> 8)
		data[i + 2] = u8(rel >> 16)
		data[i + 3] = u8(rel >> 24)
		i += 4
	}
	return
}

filters_test_inputs_destroy :: proc(inputs: Filters_Test_Inputs) {
	delete(inputs.mixed)
	delete(inputs.calls)
}

filters_test_branch_chunked :: proc(arch: filters.Branch_Arch, data: []byte, pc: u32, encoding: bool) -> (ok: bool) {
	st: filters.Branch_State
	filters.branch_init(&st, arch, pc) or_return
	pos, end := 0, 0
	for end < len(data) {
		step := 1 + rand.int_max(37) if rand.int_max(2) == 0 else 1 + rand.int_max(4096)
		end = min(len(data), end + step)
		if encoding {
			pos += filters.branch_encode(&st, data[pos:end])
		} else {
			pos += filters.branch_decode(&st, data[pos:end])
		}
	}
	return st.pc == pc + u32(pos)
}

@(test)
filters_branch_references :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)
	testing.expect_value(t, hash.crc32(inputs.mixed), 0x55381a8c)
	testing.expect_value(t, hash.crc32(inputs.calls), 0x1b9ddbeb)

	data := make([]byte, len(inputs.mixed))
	defer delete(data)
	for r in FILTERS_BRANCH_REFERENCES {
		st: filters.Branch_State
		copy(data, inputs.mixed)
		testing.expect(t, filters.branch_init(&st, r.arch, FILTERS_TEST_PC))
		n := filters.branch_encode(&st, data)
		testing.expectf(t, n == r.encoded && hash.crc32(data) == r.encode_crc, "%v encode: %v bytes, crc %x", r.arch, n, hash.crc32(data))
		testing.expect_value(t, st.pc, FILTERS_TEST_PC + u32(n))

		filters.branch_init(&st, r.arch, FILTERS_TEST_PC)
		filters.branch_decode(&st, data)
		testing.expectf(t, bytes.equal(data, inputs.mixed), "%v: round trip failed", r.arch)

		copy(data, inputs.mixed)
		filters.branch_init(&st, r.arch, FILTERS_TEST_PC)
		n = filters.branch_decode(&st, data)
		testing.expectf(t, n == r.decoded && hash.crc32(data) == r.decode_crc, "%v decode: %v bytes, crc %x", r.arch, n, hash.crc32(data))
	}

	calls := make([]byte, len(inputs.calls))
	defer delete(calls)
	st: filters.Branch_State
	copy(calls, inputs.calls)
	filters.branch_init(&st, .X86)
	filters.branch_encode(&st, calls)
	testing.expect_value(t, hash.crc32(calls), 0xd423bc0e)
	copy(calls, inputs.calls)
	filters.branch_init(&st, .X86)
	filters.branch_decode(&st, calls)
	testing.expect_value(t, hash.crc32(calls), 0x3da18db7)
}

@(test)
filters_branch_chunked :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)

	SIZE :: 20_000
	whole_buffer := make([]byte, SIZE)
	defer delete(whole_buffer)
	chunked_buffer := make([]byte, SIZE)
	defer delete(chunked_buffer)

	for input in ([2][]byte{inputs.mixed, inputs.calls}) {
		size    := rand.int_max(SIZE + 1)
		start   := rand.int_max(len(input) - size + 1)
		source  := input[start:][:size]
		whole   := whole_buffer[:size]
		chunked := chunked_buffer[:size]
		for arch in filters.Branch_Arch {
			pcs := [?]u32{0, 0x1000, 0x7FFF_FFF0, 0xFFFF_FFE0, rand.uint32() &~ u32(filters.BRANCH_ALIGNMENT[arch] - 1)}
			for pc in pcs {
				for encoding in ([]bool{true, false}) {
					st: filters.Branch_State
					copy(whole, source)
					filters.branch_init(&st, arch, pc)
					if encoding {
						filters.branch_encode(&st, whole)
					} else {
						filters.branch_decode(&st, whole)
					}

					copy(chunked, source)
					ok := filters_test_branch_chunked(arch, chunked, pc, encoding)
					testing.expectf(t, ok, "%v pc %x size %v encode %v: state pc mismatch", arch, pc, size, encoding)
					testing.expectf(t, bytes.equal(chunked, whole), "%v pc %x size %v encode %v: chunked output differs", arch, pc, size, encoding)

					if encoding {
						filters_test_branch_chunked(arch, chunked, pc, false)
						testing.expectf(t, bytes.equal(chunked, source), "%v pc %x size %v: chunked round trip failed", arch, pc, size)
					}
				}
			}
		}
	}
}

@(test)
filters_branch_alignment :: proc(t: ^testing.T) {
	data := [32]byte{}
	for arch in filters.Branch_Arch {
		align := u32(filters.BRANCH_ALIGNMENT[arch])
		for offset in u32(0)..<32 {
			st: filters.Branch_State
			ok := filters.branch_init(&st, arch, offset)
			testing.expectf(t, ok == (offset % align == 0), "%v: start offset %v accepted %v", arch, offset, ok)
		}
		st: filters.Branch_State
		filters.branch_init(&st, arch)
		testing.expect_value(t, filters.branch_encode(&st, data[:0]), 0)
		testing.expect_value(t, filters.branch_encode(&st, data[:1]), 0)
	}
}

filters_test_delta_reference :: proc(data: []byte, distance: int, encoding: bool) {
	if encoding {
		for i := len(data) - 1; i >= distance; i -= 1 {
			data[i] -= data[i - distance]
		}
	} else {
		for i in distance..<len(data) {
			data[i] += data[i - distance]
		}
	}
}

@(test)
filters_delta :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)

	size   := 1000 + rand.int_max(4001)
	start  := rand.int_max(len(inputs.mixed) - size + 1)
	source := inputs.mixed[start:][:size]
	want   := make([]byte, len(source))
	defer delete(want)
	got    := make([]byte, len(source))
	defer delete(got)

	for distance in ([]int{1, 2, 3, 4, 7, 15, 16, 17, 31, 100, 255, 256}) {
		for encoding in ([]bool{true, false}) {
			copy(want, source)
			filters_test_delta_reference(want, distance, encoding)

			copy(got, source)
			st: filters.Delta_State
			testing.expect(t, filters.delta_init(&st, distance))
			pos := 0
			for pos < len(got) {
				step := 1 + rand.int_max(distance + 2) if rand.int_max(2) == 0 else 1 + rand.int_max(1500)
				end  := min(len(got), pos + step)
				if encoding {
					filters.delta_encode(&st, got[pos:end])
				} else {
					filters.delta_decode(&st, got[pos:end])
				}
				pos = end
			}
			testing.expectf(t, bytes.equal(got, want), "distance %v size %v encode %v: output differs", distance, size, encoding)
		}

		copy(got, source)
		st: filters.Delta_State
		filters.delta_init(&st, distance)
		filters.delta_encode(&st, got)
		filters.delta_init(&st, distance)
		filters.delta_decode(&st, got)
		testing.expectf(t, bytes.equal(got, source), "distance %v: round trip failed", distance)
	}

	st: filters.Delta_State
	testing.expect(t, !filters.delta_init(&st, 0))
	testing.expect(t, !filters.delta_init(&st, filters.DELTA_DISTANCE_MAX + 1))
}

@(test)
filters_swap :: proc(t: ^testing.T) {
	data := [9]byte{0, 1, 2, 3, 4, 5, 6, 7, 8}
	testing.expect_value(t, filters.swap2(data[:]), 8)
	testing.expect_value(t, data, [9]byte{1, 0, 3, 2, 5, 4, 7, 6, 8})
	testing.expect_value(t, filters.swap2(data[:]), 8)
	testing.expect_value(t, filters.swap4(data[:]), 8)
	testing.expect_value(t, data, [9]byte{3, 2, 1, 0, 7, 6, 5, 4, 8})
	testing.expect_value(t, filters.swap4(data[:3]), 0)
	testing.expect_value(t, filters.swap2(data[:1]), 0)
	testing.expect_value(t, data, [9]byte{3, 2, 1, 0, 7, 6, 5, 4, 8})
}

filters_test_bcj2_destroy :: proc(streams: ^filters.Bcj2_Streams) {
	delete(streams.main)
	delete(streams.call)
	delete(streams.jump)
	delete(streams.rc)
}

@(test)
filters_bcj2_references :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)

	streams: filters.Bcj2_Streams
	defer filters_test_bcj2_destroy(&streams)
	for r in FILTERS_BCJ2_REFERENCES {
		input := inputs.calls if r.calls else inputs.mixed
		err := filters.bcj2_encode(&streams, input, r.relat_limit, r.file_size)
		testing.expectf(t, err == nil, "calls %v limit %x size %v: encode returned %v", r.calls, r.relat_limit, r.file_size, err)
		got := [4][]byte{streams.main[:], streams.call[:], streams.jump[:], streams.rc[:]}
		for s, i in got {
			testing.expectf(t, len(s) == r.streams[i].size && hash.crc32(s) == r.streams[i].crc, "calls %v limit %x size %v: stream %v is %v bytes, crc %x", r.calls, r.relat_limit, r.file_size, i, len(s), hash.crc32(s))
		}

		output: [dynamic]byte
		err = filters.bcj2_decode(&output, got[0], got[1], got[2], got[3])
		testing.expectf(t, err == nil && bytes.equal(output[:], input), "calls %v limit %x size %v: decode returned %v", r.calls, r.relat_limit, r.file_size, err)
		delete(output)
	}
}

@(test)
filters_bcj2_edges :: proc(t: ^testing.T) {
	streams: filters.Bcj2_Streams
	defer filters_test_bcj2_destroy(&streams)

	testing.expect_value(t, filters.bcj2_encode(&streams, nil), nil)
	testing.expect_value(t, len(streams.main), 0)
	testing.expect_value(t, len(streams.rc), 5)
	empty: [0]byte
	testing.expect_value(t, filters.bcj2_decode(empty[:], streams.main[:], streams.call[:], streams.jump[:], streams.rc[:]), nil)

	for n in 0..<12 {
		input := [12]byte{0xE8, 0x10, 0, 0, 0, 0x0F, 0x85, 0x20, 0, 0, 0, 0xE9}
		testing.expect_value(t, filters.bcj2_encode(&streams, input[:n]), nil)
		output: [12]byte
		err := filters.bcj2_decode(output[:n], streams.main[:], streams.call[:], streams.jump[:], streams.rc[:])
		testing.expectf(t, err == nil && bytes.equal(output[:n], input[:n]), "length %v: decode returned %v", n, err)
	}

	err := filters.bcj2_encode(&streams, nil, filters.BCJ2_RELAT_LIMIT_MAX + 1)
	testing.expect_value(t, err, compress.General_Error.Incompatible_Options)
	testing.expect_value(t, filters.bcj2_encode(nil, nil), compress.General_Error.Incompatible_Options)
	testing.expect_value(t, filters.bcj2_decode((^[dynamic]byte)(nil), nil, nil, nil, nil), compress.General_Error.Incompatible_Options)
}

@(test)
filters_bcj2_corrupt :: proc(t: ^testing.T) {
	inputs := filters_test_inputs()
	defer filters_test_inputs_destroy(inputs)
	input := inputs.calls[:4000]

	streams: filters.Bcj2_Streams
	defer filters_test_bcj2_destroy(&streams)
	testing.expect_value(t, filters.bcj2_encode(&streams, input), nil)
	main, call, jump, rc := streams.main[:], streams.call[:], streams.jump[:], streams.rc[:]

	short := make([]byte, len(input) - 1)
	defer delete(short)
	testing.expect_value(t, filters.bcj2_decode(short, main, call, jump, rc), compress.BCJ2_Error.Size_Mismatch)
	full := make([]byte, len(input))
	defer delete(full)
	testing.expect_value(t, filters.bcj2_decode(full, main[:len(main) - 1], call, jump, rc), compress.BCJ2_Error.Size_Mismatch)

	output: [dynamic]byte
	defer delete(output)
	testing.expect(t, filters.bcj2_decode(&output, main, call, jump, rc[:len(rc) - 1]) != nil)
	testing.expect_value(t, len(output), 0)
	testing.expect(t, filters.bcj2_decode(&output, main, call, jump, rc[:4]) != nil)
	testing.expect(t, filters.bcj2_decode(&output, main, call[:len(call) - 4], jump, rc) != nil)
	testing.expect(t, filters.bcj2_decode(&output, main, call, jump[:len(jump) - 4], rc) != nil)

	bad := make([]byte, len(rc))
	defer delete(bad)
	copy(bad, rc)
	bad[0] = 1
	testing.expect_value(t, filters.bcj2_decode(&output, main, call, jump, bad), compress.BCJ2_Error.Corrupt_Data)
	bad[0] = 0
	bad[1], bad[2], bad[3], bad[4] = 0xFF, 0xFF, 0xFF, 0xFF
	testing.expect_value(t, filters.bcj2_decode(&output, main, call, jump, bad), compress.BCJ2_Error.Corrupt_Data)

	copies := [4][]byte{make([]byte, len(main)), make([]byte, len(call)), make([]byte, len(jump)), make([]byte, len(rc))}
	defer for c in copies {
		delete(c)
	}
	originals := [4][]byte{main, call, jump, rc}
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
		err := filters.bcj2_decode(&output, mutated[0], mutated[1], mutated[2], mutated[3])
		if err != nil {
			testing.expect_value(t, len(output), 0)
		} else {
			testing.expect_value(t, len(output), len(mutated[0]) + len(mutated[1]) + len(mutated[2]))
		}
	}
}

@(test)
filters_bcj2_sizes :: proc(t: ^testing.T) {
	buffer: [8]byte
	huge := ([^]byte)(&buffer[0])[:max(int)]
	output: [dynamic]byte
	defer delete(output)

	testing.expect_value(t, filters.bcj2_decode(buffer[:1], huge, huge, buffer[:3], nil), compress.BCJ2_Error.Size_Mismatch)
	testing.expect_value(t, filters.bcj2_decode(buffer[:1], buffer[:1], huge, huge, nil), compress.BCJ2_Error.Size_Mismatch)
	testing.expect_value(t, filters.bcj2_decode(&output, huge, huge, buffer[:3], nil), compress.BCJ2_Error.Size_Mismatch)
	testing.expect_value(t, filters.bcj2_decode(&output, buffer[:1], huge[:max(int) - 1], buffer[:1], nil), compress.BCJ2_Error.Size_Mismatch)
	testing.expect_value(t, len(output), 0)

	streams: filters.Bcj2_Streams
	defer filters_test_bcj2_destroy(&streams)
	input := [5]byte{0xE8, 0xF0, 0xFF, 0xFF, 0x7F}
	Case :: struct {
		file_size: i64,
		converted: bool,
	}
	for c in ([]Case{{0x7FFF_FFF5, false}, {0x7FFF_FFF6, true}, {i64(1) << 32, true}, {1, false}, {0, true}, {-1, true}}) {
		err := filters.bcj2_encode(&streams, input[:], filters.BCJ2_RELAT_LIMIT_MAX, c.file_size)
		testing.expectf(t, err == nil && len(streams.call) == (4 if c.converted else 0), "file size %x: encode returned %v, call stream %v bytes", c.file_size, err, len(streams.call))
		decoded: [5]byte
		err = filters.bcj2_decode(decoded[:], streams.main[:], streams.call[:], streams.jump[:], streams.rc[:])
		testing.expectf(t, err == nil && decoded == input, "file size %x: decode returned %v", c.file_size, err)
	}
}
