package test_core_unicode

import "base:runtime"
import "core:mem"
import "core:os"
import "core:strings"
import "core:testing"
import "core:unicode/tools/ucd"

@(private="file")
Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
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
UNICODE_DATA_GOOD ::
	"0041;LATIN CAPITAL LETTER A;Lu;0;L;;;;;N;;;;0061;\n" +
	"0061;LATIN SMALL LETTER A;Ll;0;L;;;;;N;;;0041;;0041\n" +
	"0031;DIGIT ONE;Nd;0;EN;;1;1;1;N;;;;;\n" +
	"3400;<CJK Ideograph Extension A, First>;Lo;0;L;;;;;N;;;;;\n" +
	"4DBF;<CJK Ideograph Extension A, Last>;Lo;0;L;;;;;N;;;;;\n"

@(private="file")
write_temp :: proc(t: ^testing.T, data: string) -> string {
	f, err := os.create_temp_file("", "test_core_unicode_ucd_*")
	if !testing.expect_value(t, err, nil) {
		return ""
	}
	path := strings.clone(os.name(f), context.temp_allocator)
	_, werr := os.write_string(f, data)
	testing.expect_value(t, werr, nil)
	os.close(f)
	return path
}

@test
test_ucd_unicode_data_errors_free_partial :: proc(t: ^testing.T) {
	cases := [?]struct {
		data: string,
		err:  ucd.UCD_Error,
	}{
		{UNICODE_DATA_GOOD + "0042;LATIN CAPITAL LETTER B;Lu;0;L;;;;;N;;;;ZZZZ;\n",       .Invalid_Hex_Number},
		{UNICODE_DATA_GOOD + "0042;LATIN CAPITAL LETTER B;Lu;0;L;;;;;N;;;ZZZZ;;\n",       .Invalid_Hex_Number},
		{UNICODE_DATA_GOOD + "0042;LATIN CAPITAL LETTER B;Lu;0;L;;;;;N;;;;;ZZZZ\n",       .Invalid_Hex_Number},
		{UNICODE_DATA_GOOD + "0043;LATIN CAPITAL LETTER C;Lu;0;L;;;;;N;;;;0063;;extra\n", .Extra_Fields},
		{"ZZZZ;BAD;Lu;0;L;;;;;N;;;;;\n",                                                  .Invalid_Hex_Number},
	}

	for c in cases {
		path := write_temp(t, c.data)
		if path == "" {
			return
		}
		defer os.remove(path)

		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

		data, err := ucd.load_unicode_data(path, mem.tracking_allocator(&track))
		testing.expect_value(t, err, ucd.Error(c.err))
		testing.expect(t, data == nil)
		ucd.destroy_unicode_data(data)
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
	}
}

@test
test_ucd_unicode_data_keeps_callers_temp_allocations :: proc(t: ^testing.T) {
	path := write_temp(t, UNICODE_DATA_GOOD)
	if path == "" {
		return
	}
	defer os.remove(path)

	before := strings.clone("caller's temp data", context.temp_allocator)
	data, err := ucd.load_unicode_data(path)
	defer ucd.destroy_unicode_data(data)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(data), 4)

	scribble := make([]u8, 4096, context.temp_allocator)
	for &b in scribble {
		b = 'x'
	}
	testing.expect_value(t, before, "caller's temp data")
}

@test
test_ucd_unicode_data_oom_sweep :: proc(t: ^testing.T) {
	path := write_temp(t, UNICODE_DATA_GOOD)
	if path == "" {
		return
	}
	defer os.remove(path)

	total: int
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		data, err := ucd.load_unicode_data(path, failing_allocator(&fa))
		total = fa.count
		testing.expect_value(t, err, nil)
		testing.expect_value(t, len(data), 4)
		ucd.destroy_unicode_data(data)
		testing.expect(t, total >= 1)
		testing.expect_value(t, len(track.allocation_map), 0)
	}

	for k in 0 ..< total {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		data, err := ucd.load_unicode_data(path, failing_allocator(&fa))
		testing.expectf(t, err != nil && data == nil, "k=%d of %d: err=%v len=%d", k, total, err, len(data))
		ucd.destroy_unicode_data(data)
		testing.expectf(t, len(track.allocation_map) == 0, "k=%d of %d: %d leaked", k, total, len(track.allocation_map))
		testing.expectf(t, len(track.bad_free_array) == 0, "k=%d of %d: %d bad frees", k, total, len(track.bad_free_array))
	}
}
