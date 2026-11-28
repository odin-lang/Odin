package test_core_container

import "base:runtime"
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

@(private="file")
Bit_Array_Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
}

@(private="file")
bit_array_failing_allocator_proc :: proc(
	data: rawptr, mode: runtime.Allocator_Mode,
	size, alignment: int, old_memory: rawptr, old_size: int,
	loc := #caller_location,
) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Bit_Array_Failing_Allocator)(data)
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

@test
test_bit_array_create_oom :: proc(t: ^testing.T) {
	for k in 0..<2 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

		fa := Bit_Array_Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		allocator := runtime.Allocator{bit_array_failing_allocator_proc, &fa}

		ba, ok := bit_array.create(200, -10, allocator)
		testing.expectf(t, !ok && ba == nil, "k=%d: %p %v", k, ba, ok)
		testing.expect_value(t, fa.count, k + 1)
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
	}
}

@test
test_bit_array_init_oom :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	fa := Bit_Array_Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = 0}
	allocator := runtime.Allocator{bit_array_failing_allocator_proc, &fa}

	ba: bit_array.Bit_Array
	testing.expect(t, !bit_array.init(&ba, 200, -10, allocator))
	testing.expect_value(t, bit_array.len(&ba), 0)
	testing.expect_value(t, ba.bias, -10)
	testing.expect_value(t, len(ba.bits), 0)

	res, ok := bit_array.get(&ba, 100)
	testing.expect(t, !res && ok)

	it := bit_array.make_iterator(&ba)
	_, _, all_ok := bit_array.iterate_by_all(&it)
	testing.expect(t, !all_ok)
	it = bit_array.make_iterator(&ba)
	_, set_ok := bit_array.iterate_by_set(&it)
	testing.expect(t, !set_ok)
	it = bit_array.make_iterator(&ba)
	_, unset_ok := bit_array.iterate_by_unset(&it)
	testing.expect(t, !unset_ok)

	fa.fail_at = fa.count
	testing.expect(t, !bit_array.set(&ba, 100))
	testing.expect_value(t, bit_array.len(&ba), 0)
	testing.expect_value(t, len(ba.bits), 0)

	testing.expect(t, bit_array.set(&ba, 100))
	testing.expect_value(t, bit_array.len(&ba), 111)
	testing.expect(t, bit_array.get(&ba, 100))
	testing.expect(t, !bit_array.get(&ba, 99))

	bit_array.destroy(&ba)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@test
test_bit_array_nil :: proc(t: ^testing.T) {
	res, ok := bit_array.get(nil, 3)
	testing.expect(t, !res && !ok)
	testing.expect(t, !bit_array.set(nil, 3))
	testing.expect(t, !bit_array.unset(nil, 3))
}
