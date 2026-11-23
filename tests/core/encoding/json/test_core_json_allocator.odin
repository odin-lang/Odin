package test_core_json

import "core:encoding/json"
import "core:mem"
import "core:testing"

@test
test_parse_value_error_frees_on_parser_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	inputs := []string{
		`["abc", ["def"], {"k": "v"} x`,
		`{"a": "x", "b": ["y"], "a": "z"}`,
	}
	for input in inputs {
		p := json.make_parser(input, allocator = mem.tracking_allocator(&arg_track))
		value: json.Value
		err: json.Error
		{
			context.allocator = mem.tracking_allocator(&ctx_track)
			value, err = json.parse_value(&p)
		}
		testing.expectf(t, err != nil, "%v: parsed without error", input)
		testing.expectf(t, value == nil, "%v: returned %v", input, value)
		testing.expectf(t, len(ctx_track.bad_free_array) == 0, "%v: %v frees went through the context allocator", input, len(ctx_track.bad_free_array))
		testing.expectf(t, len(arg_track.allocation_map) == 0, "%v: %v allocations left on the parser's allocator", input, len(arg_track.allocation_map))
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)
}
