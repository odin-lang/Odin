package test_core_text_i18n

import "core:mem"
import "core:testing"
import "core:text/i18n"

@(test)
test_parse_mo_file_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	arg := mem.tracking_allocator(&arg_track)

	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		catalog, err := i18n.parse_mo_file(TEST_SUITE_PATH + "contextual_plurals.mo", allocator = arg)
		testing.expect_value(t, err, nil)
		i18n.destroy(catalog, arg)
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)
	testing.expect_value(t, len(ctx_track.bad_free_array), 0)
	testing.expect_value(t, len(arg_track.allocation_map), 0)
}
