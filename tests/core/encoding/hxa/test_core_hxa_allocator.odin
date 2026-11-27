package test_core_hxa

import "core:encoding/hxa"
import "core:mem"
import "core:testing"

@test
test_destroy_nested_meta_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	arg := mem.tracking_allocator(&arg_track)

	inner := make([]hxa.Meta, 1, arg)
	outer := make([]hxa.Meta, 1, arg)
	outer[0] = hxa.Meta{name = "inner", value = inner}
	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		hxa.meta_destroy(hxa.Meta{name = "outer", value = outer}, arg)
	}

	nested := make([]hxa.Meta, 1, arg)
	nodes := make([]hxa.Node, 1, arg)
	nodes[0].meta_data = make([]hxa.Meta, 1, arg)
	nodes[0].meta_data[0] = hxa.Meta{name = "nested", value = nested}
	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		hxa.nodes_destroy(nodes, arg)
	}

	testing.expect_value(t, len(ctx_track.bad_free_array), 0)
	testing.expect_value(t, len(arg_track.allocation_map), 0)
}
