package test_core_unicode

import "core:mem"
import "core:testing"
import "core:unicode/tools/ucd"

UCD_PATH :: ODIN_ROOT + "tests/core/assets/UCD/"

@test
test_ucd_load_and_destroy_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	arg := mem.tracking_allocator(&arg_track)

	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		data, err := ucd.load_unicode_data(UCD_PATH + "UnicodeData.txt", arg)
		testing.expect_value(t, err, nil)
		testing.expect(t, len(data) > 0)
		ucd.destroy_unicode_data(data)

		props, props_err := ucd.load_property_list(UCD_PATH + "PropList.txt", arg)
		testing.expect_value(t, props_err, nil)
		ucd.destroy_property_list(props)
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)
	testing.expect_value(t, len(ctx_track.bad_free_array), 0)
	testing.expect_value(t, len(arg_track.allocation_map), 0)
}
