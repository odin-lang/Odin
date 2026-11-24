package test_core_strings

import "base:runtime"
import "core:io"
import "core:mem"
import "core:strings"
import "core:testing"

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

@(test)
test_intern_get_oom_leaves_no_entry :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}

	m: strings.Intern
	testing.expect_value(t, strings.intern_init(&m, failing_allocator(&fa), mem.tracking_allocator(&track)), nil)

	text := strings.clone("hellope")

	fa.fail_at = fa.count
	s, err := strings.intern_get(&m, text)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, s, "")
	testing.expect_value(t, len(m.entries), 0)

	fa.fail_at = fa.count
	cs, cerr := strings.intern_get_cstring(&m, text)
	testing.expect_value(t, cerr, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect(t, cs == nil)
	testing.expect_value(t, len(m.entries), 0)

	delete(text)

	s, err = strings.intern_get(&m, "hellope")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, s, "hellope")

	cs, cerr = strings.intern_get_cstring(&m, "hellope")
	testing.expect_value(t, cerr, nil)
	testing.expect_value(t, string(cs), "hellope")
	testing.expect_value(t, len(m.entries), 1)

	strings.intern_destroy(&m)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_builder_stream_oom_is_short_write :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = 0}

	b := strings.builder_make(failing_allocator(&fa))
	n, err := io.write_string(strings.to_writer(&b), "hellope")
	testing.expect_value(t, n, 0)
	testing.expect_value(t, err, io.Error.Short_Write)
	testing.expect_value(t, strings.builder_len(b), 0)

	sn, serr := io.write(strings.to_stream(&b), transmute([]byte)string("hellope"))
	testing.expect_value(t, sn, 7)
	testing.expect_value(t, serr, nil)
	testing.expect_value(t, strings.to_string(b), "hellope")

	strings.builder_destroy(&b)
	testing.expect_value(t, len(track.allocation_map), 0)
}

@(private="file")
space_only :: proc(r: rune) -> bool {
	return r == ' '
}

@(test)
test_leak_strings_fields_proc_oom :: proc(t: ^testing.T) {
	check_fields_proc_oom(t, "a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N", 40)
	check_fields_proc_oom(t, "a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G", 33)
}

@(private="file")
check_fields_proc_oom :: proc(t: ^testing.T, input: string, fields: int, loc := #caller_location) {
	want, want_err := strings.fields_proc(input, space_only)
	defer delete(want)
	testing.expect_value(t, want_err, nil, loc = loc)
	testing.expect_value(t, len(want), fields, loc = loc)

	for k in 0..<4 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		got, err := strings.fields_proc(input, space_only, failing_allocator(&fa))
		if err != nil {
			testing.expectf(t, err == .Out_Of_Memory, "fail at %d: %v", k, err)
			testing.expectf(t, got == nil, "fail at %d: %d fields returned with an error", k, len(got))
		} else {
			same := len(got) == len(want)
			for w, i in want {
				if !same {
					break
				}
				same = got[i] == w
			}
			testing.expectf(t, same, "fail at %d: got %v", k, got)
			delete(got, failing_allocator(&fa))
		}
		injected := fa.count > k
		leaked := len(track.allocation_map)
		mem.tracking_allocator_destroy(&track)
		testing.expectf(t, leaked == 0, "fail at %d: %d block(s) leaked", k, leaked)
		testing.expectf(t, injected == (err != nil), "fail at %d: injected %v, error %v", k, injected, err)
	}
}

@(test)
test_leak_strings_size_overflow :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	alloc := mem.tracking_allocator(&track)

	buf: [16]byte
	huge := transmute(string)runtime.Raw_String{raw_data(buf[:]), max(int)}
	half := transmute(string)runtime.Raw_String{raw_data(buf[:]), max(int)/2 + 1}

	res, err := strings.join([]string{huge, "abcd"}, "ab", alloc)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(res), 0)
	res, err = strings.join([]string{half, half}, "", alloc)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(res), 0)
	res, err = strings.join([]string{"a", "b", "c"}, half, alloc)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(res), 0)
	res, err = strings.concatenate([]string{huge, "a"}, alloc)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(res), 0)
	res, err = strings.concatenate([]string{half, half, "a"}, alloc)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(res), 0)

	replaced, allocated := strings.replace_all("aaaa", "a", half, alloc)
	testing.expect_value(t, len(replaced), 0)
	testing.expect(t, !allocated)
	replaced, allocated = strings.replace("a,b", ",", huge, 1, alloc)
	testing.expect_value(t, len(replaced), 0)
	testing.expect(t, !allocated)

	res, err = strings.left_justify("x", max(int), "ab", alloc)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(res), 0)
	res, err = strings.right_justify("x", max(int), "ab", alloc)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(res), 0)
	res, err = strings.centre_justify("x", max(int), "a", alloc)
	testing.expect_value(t, err, runtime.Allocator_Error.Out_Of_Memory)
	testing.expect_value(t, len(res), 0)

	testing.expect_value(t, track.total_allocation_count, 0)
	testing.expect_value(t, len(track.allocation_map), 0)
}
