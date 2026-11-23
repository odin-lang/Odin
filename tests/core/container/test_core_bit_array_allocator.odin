package test_core_container

import "core:container/bit_array"
import "core:mem"
import "core:testing"

@test
test_bit_array_destroy_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		ba, ok := bit_array.create(200, 0, mem.tracking_allocator(&arg_track))
		testing.expect(t, ok)
		bit_array.set(ba, 150)
		testing.expect(t, bit_array.get(ba, 150))
		bit_array.destroy(ba)
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)
	testing.expect_value(t, len(ctx_track.bad_free_array), 0)
	testing.expect_value(t, len(arg_track.allocation_map), 0)
}
