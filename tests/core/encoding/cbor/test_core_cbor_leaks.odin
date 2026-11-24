package test_encoding_cbor

import "base:runtime"
import "core:encoding/cbor"
import "core:encoding/json"
import "core:math/big"
import "core:mem"
import "core:strings"
import "core:testing"

@(private="file")
Failing_Allocator :: struct {
	backing:   runtime.Allocator,
	count:     int,
	fail_at:   int,
	failed_at: runtime.Source_Code_Location,
	err:       runtime.Allocator_Error,
}

@(private="file")
failing_allocator_proc :: proc(
	data: rawptr, mode: runtime.Allocator_Mode,
	size, alignment: int, old_memory: rawptr, old_size: int,
	loc := #caller_location,
) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.count == fa.fail_at {
			fa.count += 1
			fa.failed_at = loc
			if fa.err != nil {
				return nil, fa.err
			}
			return nil, .Out_Of_Memory
		}
		fa.count += 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
failing_allocator :: proc(fa: ^Failing_Allocator) -> runtime.Allocator {
	return {procedure = failing_allocator_proc, data = fa}
}

@(private="file")
track_init :: proc(track: ^mem.Tracking_Allocator) {
	mem.tracking_allocator_init(track, context.allocator)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
}

@(private="file")
expect_clean :: proc(t: ^testing.T, track: ^mem.Tracking_Allocator, what: string, k, total: int, loc := #caller_location) {
	testing.expectf(t, len(track.allocation_map) == 0, "%s k=%d of %d: %d leaked", what, k, total, len(track.allocation_map), loc = loc)
	testing.expectf(t, len(track.bad_free_array) == 0, "%s k=%d of %d: %d bad frees", what, k, total, len(track.bad_free_array), loc = loc)
}

@(private="file")
Leak_Inner :: struct {
	name:  string,
	tags:  []string,
	nums:  [dynamic]int,
	attrs: map[string]string,
}

@(private="file")
Leak_Union :: union {
	string,
	[]int,
	Leak_Inner,
}

@(private="file")
Leak_Source :: struct {
	title:   string,
	cname:   string,
	blob:    []byte,
	b64:     string `cbor_tag:"base64"`,
	b64c:    string `cbor_tag:"base64"`,
	inner:   Leak_Inner,
	list:    []Leak_Inner,
	lookup:  map[string][]string,
	nested:  map[int]Leak_Inner,
	choices: [3]Leak_Union,
	value:   map[string][]string,
	fixed:   [2]string,
	opt:     Maybe(string),
	extra:   []string,
	num:     big.Int,
}

@(private="file")
Leak_Target :: struct {
	title:   string,
	cname:   cstring,
	blob:    []byte,
	b64:     string,
	b64c:    cstring,
	inner:   Leak_Inner,
	list:    [dynamic]Leak_Inner,
	lookup:  map[string][]string,
	nested:  map[int]Leak_Inner,
	choices: [3]Leak_Union,
	value:   cbor.Value,
	fixed:   [2]string,
	opt:     Maybe(string),
	num:     big.Int,
}

@(private="file")
inner_destroy :: proc(i: ^Leak_Inner, allocator: runtime.Allocator) {
	delete(i.name, allocator)
	for s in i.tags {
		delete(s, allocator)
	}
	delete(i.tags, allocator)
	delete(i.nums)
	for k, v in i.attrs {
		delete(k, allocator)
		delete(v, allocator)
	}
	delete(i.attrs)
	i^ = {}
}

@(private="file")
target_destroy :: proc(o: ^Leak_Target, allocator: runtime.Allocator) {
	delete(o.title, allocator)
	delete(o.cname, allocator)
	delete(o.blob, allocator)
	delete(o.b64, allocator)
	delete(o.b64c, allocator)
	inner_destroy(&o.inner, allocator)
	for &i in o.list {
		inner_destroy(&i, allocator)
	}
	delete(o.list)
	for k, v in o.lookup {
		delete(k, allocator)
		for s in v {
			delete(s, allocator)
		}
		delete(v, allocator)
	}
	delete(o.lookup)
	for _, &v in o.nested {
		inner_destroy(&v, allocator)
	}
	delete(o.nested)
	for &c in o.choices {
		switch &v in c {
		case string:     delete(v, allocator)
		case []int:      delete(v, allocator)
		case Leak_Inner: inner_destroy(&v, allocator)
		}
	}
	cbor.destroy(o.value, allocator)
	for s in o.fixed {
		delete(s, allocator)
	}
	if s, ok := o.opt.?; ok {
		delete(s, allocator)
	}
	big.destroy(&o.num)
	o^ = {}
}

@(private="file")
sample_bytes :: proc(t: ^testing.T) -> []byte {
	tags := [?]string{"red", "green", "blue"}
	ints := [?]int{7, 8, 9}
	blob := [?]byte{0, 1, 2, 3, 254, 255}

	inner := Leak_Inner{name = "inner", tags = tags[:]}
	append(&inner.nums, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
	defer delete(inner.nums)
	inner.attrs["k1"] = "v1"
	inner.attrs["k2"] = "v2"
	defer delete(inner.attrs)

	list := [?]Leak_Inner{inner, inner, inner}

	src := Leak_Source{
		title   = "title",
		cname   = "cname",
		blob    = blob[:],
		b64     = "base64 text",
		b64c    = "base64 cstring",
		inner   = inner,
		list    = list[:],
		choices = {"str", ints[:], inner},
		fixed   = {"one", "two"},
		opt     = "optional",
		extra   = tags[:],
	}
	src.lookup["a"] = tags[:]
	src.lookup["b"] = tags[:1]
	defer delete(src.lookup)
	src.nested[1] = inner
	src.nested[2] = inner
	defer delete(src.nested)
	src.value["x"] = tags[:]
	src.value["y"] = tags[1:]
	defer delete(src.value)
	testing.expect_value(t, big.atoi(&src.num, "-98765432109876543210987654321"), big.Error.None)
	defer big.destroy(&src.num)

	data, err := cbor.marshal(src, cbor.ENCODE_FULLY_DETERMINISTIC)
	testing.expect_value(t, err, nil)
	return data
}

@(private="file")
check_target :: proc(t: ^testing.T, o: ^Leak_Target, loc := #caller_location) {
	testing.expect_value(t, o.title, "title", loc)
	testing.expect_value(t, string(o.cname), "cname", loc)
	testing.expect_value(t, len(o.blob), 6, loc)
	testing.expect_value(t, o.b64, "base64 text", loc)
	testing.expect_value(t, string(o.b64c), "base64 cstring", loc)
	testing.expect_value(t, len(o.list), 3, loc)
	if len(o.list) == 3 {
		testing.expect_value(t, len(o.list[2].nums), 10, loc)
		testing.expect_value(t, o.list[2].attrs["k2"], "v2", loc)
	}
	testing.expect_value(t, len(o.lookup["b"]), 1, loc)
	testing.expect_value(t, o.nested[2].tags[2] if len(o.nested[2].tags) == 3 else "", "blue", loc)
	testing.expect_value(t, o.choices[0].(string) or_else "", "str", loc)
	testing.expect_value(t, len(o.choices[1].([]int) or_else nil), 3, loc)
	third, is_inner := o.choices[2].(Leak_Inner)
	testing.expect(t, is_inner && third.name == "inner", loc = loc)
	m, is_map := o.value.(^cbor.Map)
	testing.expect(t, is_map && len(m^) == 2, loc = loc)
	testing.expect_value(t, o.opt.? or_else "", "optional", loc)
	negative, _ := big.is_negative(&o.num)
	testing.expect(t, negative, loc = loc)
}

@(test)
test_unmarshal_roundtrip_no_leaks :: proc(t: ^testing.T) {
	data := sample_bytes(t)
	defer delete(data)

	track: mem.Tracking_Allocator
	track_init(&track)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	out: Leak_Target
	err := cbor.unmarshal(data, &out, allocator = allocator, temp_allocator = allocator)
	testing.expect_value(t, err, nil)
	check_target(t, &out)
	target_destroy(&out, allocator)
	expect_clean(t, &track, "roundtrip", 0, 0)
}

@(private="file")
decode_long_string :: proc(data: []byte, target: int, allocator: runtime.Allocator) -> (alloc_err: runtime.Allocator_Error, failed: bool, n: int) {
	switch target {
	case 0:
		v, err := cbor.decode(string(data), allocator = allocator)
		defer cbor.destroy(v, allocator)
		if err != nil {
			alloc_err, _ = err.(runtime.Allocator_Error)
			return alloc_err, true, 0
		}
		b, is_bytes := v.(^cbor.Bytes)
		return nil, false, len(b^) if is_bytes else -1
	case 1:
		out: []byte
		defer delete(out, allocator)
		if err := cbor.unmarshal(data, &out, allocator = allocator, temp_allocator = allocator); err != nil {
			alloc_err, _ = err.(runtime.Allocator_Error)
			return alloc_err, true, 0
		}
		return nil, false, len(out)
	case:
		out: string
		defer delete(out, allocator)
		if err := cbor.unmarshal(data, &out, allocator = allocator, temp_allocator = allocator); err != nil {
			alloc_err, _ = err.(runtime.Allocator_Error)
			return alloc_err, true, 0
		}
		return nil, false, len(out)
	}
}

@(test)
test_decode_long_string_oom :: proc(t: ^testing.T) {
	LONG :: 4096
	bytes_data, text_data: [dynamic]byte
	defer delete(bytes_data)
	defer delete(text_data)
	append(&bytes_data, 0x59, u8(LONG >> 8), u8(LONG & 0xff))
	append(&text_data, 0x79, u8(LONG >> 8), u8(LONG & 0xff))
	for i in 0..<LONG {
		append(&bytes_data, u8(i))
		append(&text_data, 'a' + u8(i % 26))
	}

	for target in 0..<3 {
		data := text_data[:] if target == 2 else bytes_data[:]

		total: int
		{
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}

			alloc_err, failed, n := decode_long_string(data, target, failing_allocator(&fa))
			total = fa.count
			testing.expectf(t, !failed && n == LONG, "target %d: %v %v %d", target, alloc_err, failed, n)
			expect_clean(t, &track, "long string", -1, total)
		}
		testing.expectf(t, total >= 2, "target %d: %d allocations", target, total)

		for k in 0..<total {
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}

			alloc_err, failed, _ := decode_long_string(data, target, failing_allocator(&fa))
			testing.expectf(t, failed && alloc_err == .Out_Of_Memory, "target %d k=%d of %d: %v, failed at %v", target, k, total, alloc_err, fa.failed_at)
			expect_clean(t, &track, "long string", k, total)
		}
	}
}

@(test)
test_unmarshal_big_allocator_error :: proc(t: ^testing.T) {
	for text in ([]string{"98765432109876543210987654321", "-98765432109876543210987654321"}) {
		src: big.Int
		defer big.destroy(&src)
		testing.expect_value(t, big.atoi(&src, text), big.Error.None)
		data, merr := cbor.marshal(src)
		defer delete(data)
		testing.expect_value(t, merr, nil)

		total: int
		{
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
			allocator := failing_allocator(&fa)

			out: big.Int
			err := cbor.unmarshal(data, &out, allocator = allocator, temp_allocator = allocator)
			total = fa.count
			testing.expect_value(t, err, nil)
			equal, _ := big.equals(&out, &src)
			testing.expectf(t, equal, "%s: round trip differs", text)
			big.destroy(&out)
			expect_clean(t, &track, "big", -1, total)
		}
		testing.expectf(t, total >= 2, "%s: %d allocations", text, total)

		for want in ([]runtime.Allocator_Error{.Out_Of_Memory, .Invalid_Argument}) {
			for k in 0..<total {
				track: mem.Tracking_Allocator
				track_init(&track)
				defer mem.tracking_allocator_destroy(&track)
				fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k, err = want}
				allocator := failing_allocator(&fa)

				out: big.Int
				err := cbor.unmarshal(data, &out, allocator = allocator, temp_allocator = allocator)
				alloc_err, is_alloc := err.(runtime.Allocator_Error)
				testing.expectf(t, is_alloc && (alloc_err == want || alloc_err == .Out_Of_Memory), "%s %v k=%d of %d: %v, failed at %v", text, want, k, total, err, fa.failed_at)
				big.destroy(&out)
				expect_clean(t, &track, "big", k, total)
			}
		}
	}
}

@(test)
test_encode_and_marshal_oom :: proc(t: ^testing.T) {
	data := sample_bytes(t)
	defer delete(data)

	value, derr := cbor.decode(string(data))
	testing.expect_value(t, derr, nil)
	defer cbor.destroy(value)

	target: Leak_Target
	testing.expect_value(t, cbor.unmarshal(data, &target), nil)
	defer target_destroy(&target, context.allocator)

	total: int
	{
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		allocator := failing_allocator(&fa)

		out, err := cbor.encode(value, cbor.ENCODE_FULLY_DETERMINISTIC, allocator, allocator)
		total = fa.count
		testing.expect_value(t, err, nil)
		testing.expect_value(t, string(out), string(data))
		delete(out, allocator)
		expect_clean(t, &track, "encode", -1, total)
	}
	testing.expect(t, total >= 2)

	for k in 0..<total {
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		allocator := failing_allocator(&fa)

		out, err := cbor.encode(value, cbor.ENCODE_FULLY_DETERMINISTIC, allocator, allocator)
		testing.expectf(t, err == cbor.Encode_Error(runtime.Allocator_Error.Out_Of_Memory), "encode k=%d of %d: %v, failed at %v", k, total, err, fa.failed_at)
		testing.expectf(t, out == nil, "encode k=%d of %d: output not nil", k, total)
		delete(out, allocator)
		expect_clean(t, &track, "encode", k, total)
	}

	{
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		allocator := failing_allocator(&fa)

		out, err := cbor.marshal(target, cbor.ENCODE_FULLY_DETERMINISTIC, allocator, allocator)
		total = fa.count
		testing.expect_value(t, err, nil)
		delete(out, allocator)
		expect_clean(t, &track, "marshal", -1, total)
	}
	testing.expect(t, total >= 2)

	for k in 0..<total {
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		allocator := failing_allocator(&fa)

		out, err := cbor.marshal(target, cbor.ENCODE_FULLY_DETERMINISTIC, allocator, allocator)
		testing.expectf(t, err == cbor.Marshal_Error(runtime.Allocator_Error.Out_Of_Memory), "marshal k=%d of %d: %v, failed at %v", k, total, err, fa.failed_at)
		testing.expectf(t, out == nil, "marshal k=%d of %d: output not nil", k, total)
		delete(out, allocator)
		expect_clean(t, &track, "marshal", k, total)
	}
}

@(test)
test_into_builder_oom :: proc(t: ^testing.T) {
	data := sample_bytes(t)
	defer delete(data)

	value, derr := cbor.decode(string(data))
	testing.expect_value(t, derr, nil)
	defer cbor.destroy(value)

	target: Leak_Target
	testing.expect_value(t, cbor.unmarshal(data, &target), nil)
	defer target_destroy(&target, context.allocator)

	marshalled, merr := cbor.marshal(target, cbor.ENCODE_FULLY_DETERMINISTIC)
	testing.expect_value(t, merr, nil)
	defer delete(marshalled)

	for which in 0..<2 {
		want := data if which == 0 else marshalled
		total: int
		{
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
			allocator := failing_allocator(&fa)

			b := strings.builder_make(allocator)
			err: cbor.Marshal_Error
			if which == 0 {
				err = cbor.err_conv(cbor.encode_into_builder(&b, value, cbor.ENCODE_FULLY_DETERMINISTIC, allocator))
			} else {
				err = cbor.marshal_into_builder(&b, target, cbor.ENCODE_FULLY_DETERMINISTIC, allocator)
			}
			total = fa.count
			testing.expect_value(t, err, nil)
			testing.expect_value(t, string(b.buf[:]), string(want))
			strings.builder_destroy(&b)
			expect_clean(t, &track, "into builder", -1, total)
		}
		testing.expectf(t, total >= 2, "builder %d: %d allocations", which, total)

		for k in 0..<total {
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
			allocator := failing_allocator(&fa)

			b := strings.builder_make(allocator)
			err: cbor.Marshal_Error
			if which == 0 {
				err = cbor.err_conv(cbor.encode_into_builder(&b, value, cbor.ENCODE_FULLY_DETERMINISTIC, allocator))
			} else {
				err = cbor.marshal_into_builder(&b, target, cbor.ENCODE_FULLY_DETERMINISTIC, allocator)
			}
			testing.expectf(t, err == cbor.Marshal_Error(runtime.Allocator_Error.Out_Of_Memory), "builder %d k=%d of %d: %v, failed at %v", which, k, total, err, fa.failed_at)
			strings.builder_destroy(&b)
			expect_clean(t, &track, "into builder", k, total)
		}
	}
}

@(test)
test_diagnostic_and_json_oom :: proc(t: ^testing.T) {
	CBOR := [?]byte{
		0xA4,
		0x01, 0xC6, 0x61, 'x',
		0x61, 'k', 0x82, 0x01, 0x02,
		0x61, 'a', 0x01,
		0x61, 'a', 0xA2, 0x61, 'b', 0x41, 0xFF, 0x61, 'b', 0x22,
	}
	value, derr := cbor.decode(string(CBOR[:]))
	testing.expect_value(t, derr, nil)
	defer cbor.destroy(value)

	DUP_KEYS := [?]byte{0xA3, 0x61, 'a', 0x01, 0x61, 'a', 0x82, 0x61, 'x', 0xC6, 0x02, 0x61, 'c', 0xF6}
	dup_value, dup_err := cbor.decode(string(DUP_KEYS[:]))
	testing.expect_value(t, dup_err, nil)
	defer cbor.destroy(dup_value)

	for v in ([]cbor.Value{value, dup_value}) {
		total: int
		{
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
			allocator := failing_allocator(&fa)

			out, err := cbor.to_json(v, allocator)
			total = fa.count
			testing.expect_value(t, err, nil)
			json.destroy_value(out, allocator)
			expect_clean(t, &track, "to_json", -1, total)
		}
		for k in 0..<total {
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}

			out, err := cbor.to_json(v, failing_allocator(&fa))
			testing.expectf(t, err == .Out_Of_Memory, "to_json k=%d of %d: got %v", k, total, err)
			testing.expectf(t, out == nil, "to_json k=%d of %d: output not nil", k, total)
			expect_clean(t, &track, "to_json", k, total)
		}

		{
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
			allocator := failing_allocator(&fa)

			out, err := cbor.to_diagnostic_format_string(v, allocator = allocator)
			total = fa.count
			testing.expect_value(t, err, nil)
			delete(out, allocator)
			expect_clean(t, &track, "diagnostic", -1, total)
		}
		for k in 0..<total {
			track: mem.Tracking_Allocator
			track_init(&track)
			defer mem.tracking_allocator_destroy(&track)
			fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}

			out, err := cbor.to_diagnostic_format_string(v, allocator = failing_allocator(&fa))
			testing.expectf(t, err == .Out_Of_Memory, "diagnostic k=%d of %d: got %v", k, total, err)
			testing.expectf(t, out == "", "diagnostic k=%d of %d: output not empty", k, total)
			expect_clean(t, &track, "diagnostic", k, total)
		}
	}

	JSON :: `{"a": [1, -2, 3.5, true, null, "text"], "b": {"c": "d", "e": [{"f": "g"}]}, "h": "i"}`
	jv, jerr := json.parse_string(JSON, parse_integers = true)
	testing.expect_value(t, jerr, nil)
	defer json.destroy_value(jv)

	total: int
	{
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		allocator := failing_allocator(&fa)

		out, err := cbor.from_json(jv, allocator)
		total = fa.count
		testing.expect_value(t, err, nil)
		cbor.destroy(out, allocator)
		expect_clean(t, &track, "from_json", -1, total)
	}
	testing.expect(t, total >= 10)

	for k in 0..<total {
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}

		out, err := cbor.from_json(jv, failing_allocator(&fa))
		testing.expectf(t, err == .Out_Of_Memory, "from_json k=%d of %d: got %v", k, total, err)
		testing.expectf(t, out == nil, "from_json k=%d of %d: output not nil", k, total)
		expect_clean(t, &track, "from_json", k, total)
	}
}

@(private="file")
huge_header :: proc(buf: []byte, major: byte, n: u64) -> []byte {
	buf[0] = major | 27
	for i in 0..<8 {
		buf[1 + i] = byte(n >> uint(56 - 8 * i))
	}
	return buf[:9]
}

@(test)
test_trusted_input_huge_lengths :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, runtime.heap_allocator())
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	buf: [32]byte
	for major in ([]byte{0x80, 0xa0}) {
		v, err := cbor.decode(string(huge_header(buf[:], major, u64(max(int)))), {.Trusted_Input}, allocator)
		testing.expectf(t, err == cbor.Decode_Error(runtime.Allocator_Error.Out_Of_Memory), "major %x: %v", major, err)
		testing.expect(t, v == nil)

		v, err = cbor.decode(string(huge_header(buf[:], major, u64(max(int)) + 1)), {.Trusted_Input}, allocator)
		testing.expectf(t, err == cbor.Decode_Error(cbor.Decode_Data_Error.Length_Too_Big), "major %x: %v", major, err)
		testing.expect(t, v == nil)
	}
	for major in ([]byte{0x40, 0x60}) {
		v, err := cbor.decode(string(huge_header(buf[:], major, u64(max(int)))), {.Trusted_Input}, allocator)
		testing.expectf(t, err != nil, "major %x: no error", major)
		testing.expect(t, v == nil)
	}
	expect_clean(t, &track, "trusted decode", 0, 0)

	{
		m: map[string]string
		err := cbor.unmarshal(huge_header(buf[:], 0xa0, u64(max(int))), &m, {.Trusted_Input}, allocator, allocator)
		testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
		testing.expect_value(t, len(m), 0)
		delete(m)
	}
	{
		inner: Leak_Inner
		huge_header(buf[:], 0xa0, 1)
		copy(buf[9:], []byte{0x65, 'a', 't', 't', 'r', 's'})
		huge_header(buf[15:], 0xa0, u64(max(int)))
		err := cbor.unmarshal(buf[:24], &inner, {.Trusted_Input}, allocator, allocator)
		testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
		inner_destroy(&inner, allocator)
	}
	expect_clean(t, &track, "trusted unmarshal", 0, 0)
}

@(test)
test_decode_nested_tag_frees_the_inner_tag :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	track_init(&track)
	defer mem.tracking_allocator_destroy(&track)

	v, err := cbor.decode("\xC6\xC6\x61x", allocator = mem.tracking_allocator(&track))
	testing.expect_value(t, err, cbor.Decode_Error(cbor.Decode_Data_Error.Nested_Tag))
	testing.expect(t, v == nil)
	expect_clean(t, &track, "nested tag", 0, 0)
}

@(private="file")
Marshal_Run :: #type proc(data: rawptr, allocator: runtime.Allocator) -> ([]byte, cbor.Marshal_Error)

@(private="file")
sweep_marshal :: proc(t: ^testing.T, what: string, data: rawptr, run: Marshal_Run, loc := #caller_location) {
	total: int
	{
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		out, err := run(data, failing_allocator(&fa))
		total = fa.count
		testing.expectf(t, err == nil && len(out) > 0, "%s: %v", what, err, loc = loc)
		delete(out, failing_allocator(&fa))
		expect_clean(t, &track, what, -1, total, loc)
	}
	for k in 0..<total {
		track: mem.Tracking_Allocator
		track_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		out, err := run(data, failing_allocator(&fa))
		testing.expectf(t, err == cbor.Marshal_Error(runtime.Allocator_Error.Out_Of_Memory) && out == nil, "%s k=%d of %d: %v", what, k, total, err, loc = loc)
		delete(out, failing_allocator(&fa))
		expect_clean(t, &track, what, k, total, loc)
	}
}

@(private="file")
Leak_Long_Names :: struct {
	a_field_name_longer_than_a_builder_start: int,
	b: int,
}

@(test)
test_deterministic_long_keys_oom :: proc(t: ^testing.T) {
	value, derr := cbor.decode("\xA2\x77a_key_longer_than_eight\x01\x61b\x02")
	testing.expect_value(t, derr, nil)
	defer cbor.destroy(value)
	sweep_marshal(t, "encode", &value, proc(data: rawptr, a: runtime.Allocator) -> ([]byte, cbor.Marshal_Error) {
		out, err := cbor.encode((^cbor.Value)(data)^, cbor.ENCODE_FULLY_DETERMINISTIC, a, a)
		return out, cbor.err_conv(err)
	})

	names := Leak_Long_Names{1, 2}
	sweep_marshal(t, "struct", &names, proc(data: rawptr, a: runtime.Allocator) -> ([]byte, cbor.Marshal_Error) {
		return cbor.marshal((^Leak_Long_Names)(data)^, cbor.ENCODE_FULLY_DETERMINISTIC, a, a)
	})

	wide: map[i64]int
	defer delete(wide)
	wide[1 << 40] = 1
	wide[2 << 40] = 2
	sweep_marshal(t, "wide keys", &wide, proc(data: rawptr, a: runtime.Allocator) -> ([]byte, cbor.Marshal_Error) {
		return cbor.marshal((^map[i64]int)(data)^, cbor.ENCODE_FULLY_DETERMINISTIC, a, a)
	})
}

@(private="file")
Leak_B64_Cstring :: struct {
	c: cstring,
}

@(private="file")
Leak_B64_Array :: struct {
	a: [4]byte,
}

@(test)
test_unmarshal_base64_frees_its_buffers :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	track_init(&track)
	defer mem.tracking_allocator_destroy(&track)
	allocator := mem.tracking_allocator(&track)

	{
		out: Leak_B64_Cstring
		err := cbor.unmarshal("\xA1\x61c\xD8\x22\x64!!!!", &out, allocator = allocator, temp_allocator = allocator)
		testing.expect(t, err != nil)
		testing.expect(t, out.c == nil)
	}
	expect_clean(t, &track, "invalid base64 cstring", 0, 0)

	{
		out: Leak_B64_Array
		err := cbor.unmarshal("\xA1\x61a\xD8\x22\x64AQID", &out, allocator = allocator, temp_allocator = allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, out.a, [4]byte{1, 2, 3, 0})
	}
	expect_clean(t, &track, "base64 array", 0, 0)
}
