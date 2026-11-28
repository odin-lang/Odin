package test_core_text_regex

import "base:runtime"
import "core:mem"
import "core:strings"
import "core:testing"
import "core:text/regex"
import "core:text/regex/parser"
import "core:time"

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

@test
test_tokenizer_error_inside_scan_terminates :: proc(t: ^testing.T) {
	testing.set_fail_timeout(t, time.Minute)

	patterns := [?]string{
		"#\x00",
		"#\xff",
		"a#\x00b",
		"a{\x00",
		"a{1\x00}",
		"a{1,\x00}",
		"a{1\xff}",
		"a{\xef\xbb\xbf}",
		"\\p{\x00\x00\x00",
	}
	flag_sets := [?]regex.Flags{{}, {.Ignore_Whitespace}, {.Unicode}, {.Ignore_Whitespace, .Unicode, .No_Optimization}}

	for pattern in patterns {
		for flags in flag_sets {
			rex, err := regex.create(pattern, flags)
			testing.expectf(t, err != nil, "%q %v: expected an error", pattern, flags)
			regex.destroy(rex)
		}
	}
}

@test
test_write_node_frees_its_alternation_list :: proc(t: ^testing.T) {
	node: parser.Node
	err: parser.Error
	{
		context.allocator = context.temp_allocator
		node, err = parser.parse("a|b|c", {})
	}
	testing.expect_value(t, err, nil)

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	parser.write_node(strings.to_writer(&sb), node)
	testing.expect_value(t, strings.to_string(sb), "《《a|b》|c》")
}

@test
test_repetition_at_the_limit_still_compiles :: proc(t: ^testing.T) {
	check_expression(t, "^a{3}$",   "aaa",   "aaa")
	check_expression(t, "^a{,3}$",  "aa",    "aa")
	check_expression(t, "^a{2,}$",  "aaaa",  "aaaa")
	check_expression(t, "^a{1,3}$", "aaa",   "aaa")

	rex, err := regex.create("a{1000}")
	defer regex.destroy(rex)
	testing.expect_value(t, err, nil)
}

@test
test_preallocate_capture_oom :: proc(t: ^testing.T) {
	for k in 0 ..< 2 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		capture := regex.preallocate_capture(failing_allocator(&fa))
		testing.expectf(t, len(capture.groups) == 0 && len(capture.pos) == 0, "k=%d: partial capture", k)
		regex.destroy(capture, mem.tracking_allocator(&track))
		testing.expectf(t, len(track.allocation_map) == 0, "k=%d: %d leaked", k, len(track.allocation_map))
	}
}
